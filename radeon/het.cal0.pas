unit het.cal0;

interface

{ DEFINE RECREATECONTEXT}
{ DEFINE UAV}

//2011.09.06: RECREATECONTEXT=OFF UAV=OFF }
//2011.09.07: mostantol atnevezve het.cal0 -nak, mert lesz egy uj, hetobject alapú

uses Windows, Sysutils, cal, calcl, math, het.utils;

const UAVBlockWidth=64;
      RecreateContext={$IFDEF RECREATECONTEXT}true{$ELSE}false{$ENDIF};
type
  TLiteralConst=record
    id:integer;
    value:array[0..3]of integer;
  end;
  TLiteralConstArray=array of TLiteralConst;

  TGPUDevice=class
  public
    FDeviceId:integer;
    dev:CALdevice;

    devInfo:CALdeviceinfo;
    devAttr:CALdeviceattribs;
    devStat:CALdevicestatus;

    constructor Create(const ADeviceId:integer);
    destructor Destroy;override;
  end;

  TGPUContext=class
  public
    dev:TGPUDevice;
    ctx:CALcontext;

    constructor Create(const ADeviceId:integer);
    destructor Destroy;override;
  end;

  TGPUProgram=class
  private
    FDeviceId:integer;
    FContext:TGPUContext;
    FProgram:ansistring;
    FConstLen,FGlobalLen:integer;
    FConstLen128,FGlobalLen128:integer;

    FPrepared:boolean;
    FDisasm:ansistring;

    module:CALmodule;
    constRes,globalRes:CALresource;
    constMem,globalMem:CALMem;
    constName,globalName:CALname;
    func:CALfunc;
    event:CALevent;

    FTarget:CALtarget;

    FConstPool,FGlobalPool:array of byte;//unaligned const mem
    FLiteralConsts:TLiteralConstArray;
    function ConstMemPtr:pointer;
    function GlobalMemPtr:pointer;
  public
    constructor create;
    destructor Destroy;override;
    procedure Cleanup;
    procedure Prepare(const ADeviceId:integer;const AProgram:ansistring;
                      const AConstLen:integer;const AGlobalLen:integer);
    procedure Run(const xs,ys:integer;var AConst;var AGlobal);
    function Finished:boolean;
    procedure ReadGlobal(var AGlobal);

    property Target:CALtarget read FTarget;
    property ProgramSource:AnsiString read FProgram;
    property Disasm:AnsiString read FDisasm;
  end;

type
  TIsaMetrics=record
    VLIWSize,Clauses,Groups,Instructions,PReads,PWrites,VECs,Reads,Literals:integer;
    BYTE_ALIGN_INT_cnt,BFI_INT_cnt:integer;
    function AsString:ansistring;
  end;

function ISAMetrics(const ISACode:ansistring):TIsaMetrics;

function _ISADisasm(const ILSrc:ansistring;const ATarget:calTarget):ansistring;

procedure calFreeAllContexts;

function CompileKernel(ILkernel:AnsiString;out literalConsts:TLiteralConstArray;const ctx:CALcontext;const ATarget:CALtarget):RawByteString;

implementation

uses
  het.filesys;

////////////////////////////////////////////////////////////////////////////////
///  CAL utility functions                                                   ///
////////////////////////////////////////////////////////////////////////////////

function TIsaMetrics.AsString:ansistring;
  function p(a,b:integer):single;//percent
  begin
    if b=0 then result:=0 else result:=a/b*100;
  end;

begin
  result:=format('Clauses: %d  Groups: %d  Util: %.2f%%  VECs: %.2f%%  PW: %.2f%%  PR: %.2f%%  Ltr: %.2f%%  ByteAlignCnt: %d  BFIcnt: %d',
    [Clauses,
     Groups,
     p(Instructions,(Groups*VLIWSize)),
     p(VECs,Instructions),
     p(PWrites,Instructions),
     p(PReads,Reads),
     p(Literals,Reads),
     BYTE_ALIGN_INT_cnt,
     BFI_INT_cnt]);
end;

function ISAMetrics(const ISACode:ansistring):TIsaMetrics;
var line:ansistring;
    i:integer;
    isClause,isInstr,isSlot:Boolean;
begin with result do begin
  VLIWSize:=4;Clauses:=0;Groups:=0;Instructions:=0;PReads:=0;PWrites:=0;VECs:=0;Reads:=0;Literals:=0;
  BYTE_ALIGN_INT_cnt:=0;BFI_INT_cnt:=0;
  for line in ListSplit(ISACode,#10,true)do begin
    isInstr:=(pos('x:',line,[poWholeWords])>0)or
             (pos('y:',line,[poWholeWords])>0)or
             (pos('z:',line,[poWholeWords])>0)or
             (pos('w:',line,[poWholeWords])>0)or
             (pos('t:',line,[poWholeWords])>0);
    if(VLIWSize=4)and(pos('t:',line,[poWholeWords])>0)then VLIWSize:=5;
    isClause:=false;
    isSlot:=false;
    if TryStrToInt(listitem(trimf(line),0,' '),i)then if isInstr then isSlot:=true else isClause:=true;

    if isInstr then begin
      inc(Reads,CountPos(',',line)-CountPos('(0x',line));
      if pos('(0x',line)>0 then inc(Literals);
      if Pos(' VEC',line)>0 then inc(VECs);
      if Pos('____',line)>0 then inc(PWrites);

      inc(PReads,CountPos(' PV',line));
      inc(PReads,CountPos(' PS',line));

      if pos('BYTE_ALIGN_INT',line)>0 then
        inc(BYTE_ALIGN_INT_cnt)else
      if pos('BFI_INT',line)>0 then
        inc(BFI_INT_cnt);
    end;

    Inc(Instructions,ord(isInstr));
    Inc(Groups,ord(isSlot));
    Inc(Clauses,ord(isClause));
  end;
end;end;

threadvar calDisassembledText:ansistring;

procedure _calDisasmLogger(const s:PAnsiChar);cdecl;
begin
  calDisassembledText:=calDisassembledText+s;
end;

threadvar calDisassembledObjectText:ansistring;

procedure _calDisasmObjLogger(const s:PAnsiChar);cdecl;
begin
  calDisassembledObjectText:=calDisassembledObjectText+s;
end;

////////////////////////////////////////////////////////////////////////////////
///  Compiler Pre-pass                                                       ///
////////////////////////////////////////////////////////////////////////////////

function ILCompilePrePass(const AKernel:ansistring;const ATarget:CALtarget;Out A5xxxVecSelCount:integer;Out ALiteralConsts:TLiteralConstArray):ansistring;
//A5xxxVecSelCount: 0 by default. Used when vec_sel instructions emulated with bytealign
//LiteralConst -> auto replace literals with constants in cb0

  function getInstr(const line:ansistring):ansistring;
  var i,st,en,len,delta:integer;
  begin
    //unoptimized version:
    result:=lc(listitem(listitem(line,0,';'),0,' '));
    exit;
    //1. find st,en
    len:=length(line);
    st:=1;
    while(st<len)and(line[st]in[' ',#9])do inc(st);
    en:=st;
    if(en<len)and(line[en+1]in['a'..'z','A'..'Z'])then begin
      inc(en);//first char ok
      while(en<=len)and(line[en]in['a'..'z','A'..'Z','_','0'..'9'])do inc(en);
    end;
    //2. get lc str
    setlength(result,en-st);
    delta:=st-1;for i:=1 to en-st do result[i]:=charmapLower[line[i+delta]];
  end;

  function isthere(const s:ansistring):boolean;
  begin
    result:=pos(s,AKernel,[poIgnoreCase,poWholeWords])>0;
  end;

  function SwizzleOf(const s:ansistring):ansistring;
  var i:integer;
  begin
    result:='';
    i:=ListCount(s,'.');
    if(i>1)then begin
      result:='.'+ListItem(s,i-1,'.');
      if pos(']',result,[])>0 then result:='';
    end;
  end;

  procedure AddConstantInit(const line:ansistring);
  var c:TLiteralConst;i:integer;s:ansistring;
  begin
    if not TryStrToInt(FindBetween(line,'[',']'),c.id) then exit;

    s:=FindBetween(line,'(',')');
    for i:=0 to high(c.value) do
      if not TryStrToInt(listitem(s,i,','),c.value[i])then exit;

    setlength(ALiteralConsts,length(ALiteralConsts)+1);
    ALiteralConsts[high(ALiteralConsts)]:=c;
  end;

  const
    LiteralDefs='dcl_literal l1001,0,8,16,24';

    //target szerint csokkeno sorrendben,
    //minden lowercase!!!!
    //tempek swizzleje a d-bol jon

    //bit,byte align is not compatible with 5xxx when emulated on 4xxx
    Patches:array[0..11]of record target:byte;instr:ansistring;expand:ansistring end=(
      (target:5;instr:'irol'     ;expand:'inegate t1,s1;bitalign d,s0,s0,t1'),
      (target:5;instr:'iror'     ;expand:'bitalign d,s0,s0,s1'),
      (target:5;instr:'vec_sel'  ;expand:'bytealign d,s2,s1,s0'),
      (target:5;instr:'bytealign'{vec_sel_only};expand:'iadd t2,s2,s2;iadd t2,t2,t2;iadd t2,t2,t2;bitalign d,s0,s1,t2'),
      (target:3;instr:'bytealign' ;expand:'iadd t2,s2,s2;iadd t2,t2,t2;iadd t2,t2,t2;ushr t1,s1,t2;inegate t2,t2;ishl t0,s0,t2;ior d,t1,t0'),
      (target:3;instr:'bitalign' ;expand:'ushr t1,s1,s2;inegate t2,s2;ishl t0,s0,t2;ior d,t1,t0'),
      (target:3;instr:'irol'     ;expand:'ishl t0,s0,s1;inegate t2,s1;ushr t1,s0,t2;ior d,t1,t0'),
      (target:3;instr:'iror'     ;expand:'ushr t0,s0,s1;inegate t2,s1;ishl t1,s0,t2;ior d,t1,t0'),
      (target:3;instr:'vec_sel'  ;expand:'iand t1,s1,s2;inot t2,s2;iand t0,s0,t2;ior d,t0,t1'),
      (target:3;instr:'vec_sel_unopt';expand:'iand t1,s1,s2;inot t2,s2;iand t0,s0,t2;ior d,t0,t1'),
      (target:5;instr:'vec_sel_unopt';expand:'iand t1,s1,s2;inot t2,s2;iand t0,s0,t2;ior d,t0,t1'),
      (target:3;instr:'f_2_u4';expand:'ftoi r1000,s0;ishl r1000,r1000,l1001;ior r1000.xy,r1000.xy,r1000.zw;ior d,r1000.x,r1000.y')
    );
    ParamNames:array[0..3]of ansistring=('d','s0','s1','s2');
    TempNames :array[0..2]of ansistring=(    't0','t1','t2');

    TempBase=1000;
    TempCount=8;

var {doPatch:boolean;}
    s,line,ins,swz,tempreg:ansistring;
    params:TArray<ansistring>;
    t,i,j,TempOffset:integer;
    do5xxxVecSel,LiteralsAdded:boolean;

begin
  LiteralsAdded:=false;
  A5xxxVecSelCount:=0;
  setlength(ALiteralConsts,0);
  if Akernel='' then exit(AKernel);

  //major card version
  if ATarget>=CAL_TARGET_WRESTLER then t:=6 else
  if ATarget>=CAL_TARGET_CYPRESS  then t:=5 else
  if ATarget>=CAL_TARGET_7XX      then t:=4 else
                                       t:=3;

  if t>=5 then t:=5 else t:=3;//redukalt cucc kell, kesobb atgondolni ezt majd!!!

{ //Kilepes, ha nincs mit patcholni. Torolve, mert a literalok miatt mar mindig kell valamit patcholni.
  doPatch:=false;
  for i:=0 to high(Patches)do with Patches[i] do if(t=target)and isthere(instr)then begin
    doPatch:=true;break end;
  if not doPatch then exit(AKernel);}

  do5xxxVecSel:=isthere('vec_sel')and(t>=5);

  TempOffset:=0;
  for i:=TempOffset to TempOffset+TempCount-1 do
    if isthere('r'+tostr(TempBase+i))then
      raise Exception.Create('CAL compiler pre-pass: Temp register range already used (r'+toStr(TempBase)+'..r'+tostr(TempBase+TempCount-1)+')');

  with AnsiStringBuilder(result,true)do for line in ListSplit(AKernel,#10)do begin
    ins:=getInstr(line);

{    s:=lc(ListItem(line,0,';'));//old version
    if ins<>listitem(s,0,' ')then
      beep;}

    j:=-1;for i:=0 to high(Patches)do with Patches[i]do if(t=target)and(ins=instr)then begin
      j:=i;break end;

    if do5xxxVecSel then begin
      if ins='vec_sel' then inc(A5xxxVecSelCount);
    end else begin
      if(t>=5)and(ins='bytealign')then j:=-1;//don't touch bytealign on 5xxx
    end;

    if j>=0 then with Patches[j]do begin//expand
      s:=lc(listitem(line,0,';'));//instr with params

      if checkAndSet(LiteralsAdded)then
        AddLine(replacef(';',#13#10,LiteralDefs,[roAll]));

      params:=ListSplit(copy(s,length(ins)+1),',');

      if(length(params)>0)then swz:=SwizzleOf(Params[0])else swz:='';

      s:=expand;
      for i:=0 to min(Length(Params),Length(ParamNames))-1 do
        Replace(ParamNames[i],params[i],s,[roAll,roWholeWords]);
      for i:=0 to length(TempNames)-1 do begin
        tempreg:='r'+toStr(TempBase+TempOffset);
        inc(TempOffset);if TempOffset>=TempCount then TempOffset:=0;
        Replace(TempNames[i],tempreg+swz,s,[roAll,roWholeWords]);
      end;

      replace(';',#13#10,s,[roAll]);
      AddLine(s);
    end else if(ins='')and(copy(line,1,5)=';cb0[')and(pos(']:=(',line)>0)then begin//const buff initialization
      //format: ;cb0[n]:=(a,b,c,d);
      AddConstantInit(line);
    end else begin
      AddLine(line);
    end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
///  ELF patcher functions                                                   ///
////////////////////////////////////////////////////////////////////////////////

type
  TElfSect=packed record
    name, {nameId}
    type_,
    flags,
    addr,
    offset,size,
    link,info,align,
    entsize:integer;
    function Dump:ansistring;
  end;PElfSect=^TElfSect;

  TElfHdr=packed record
    magic:integer;
    class_,//1:32bit 2:64bit
    byteorder, //1:LE  2:BE
    hversion:byte; //always 1
    _pad:array[0..8]of byte;
    filetype,
    archtype:word;
    fversion,  //always 1
    entry,     //exec entry point
    phdrpos,   //ofs
    shdrpos,   //ofs
    flags:integer;
    hdrsize,  //size of elf header
    phdrent,  //program header entry size
    phdrcnt,  //program header entry count
    shdrent,  //section header entry size
    shdrcnt,  //section header entry count
    strsec    //section that holds section name strings
    :word;
    function Dump:ansistring;
    function shdr(const idx:integer):PElfSect;
    function shdrData(const idx:integer):ansistring;
    function shdrName(const idx:integer):ansistring;
    function PatchInstrOp3(oldInstr,newInstr:byte):integer;//returns no of occurrences
  end;PElfHdr=^TElfHdr;

function TElfSect.Dump:ansistring;
  procedure w(const s:ansistring);begin result:=result+s end;procedure wln(const s:ansistring);begin w(s+#13#10)end;
begin result:='';
  wln('  name:'+inttostr(name));
  wln('  type_:'+inttostr(type_));
  wln('  flags:'+inttostr(flags));
  wln('  addr:'+inttostr(addr));
  wln('  offset:'+inttostr(offset));
  wln('  size:'+inttostr(size));
  wln('  link:'+inttostr(link));
  wln('  info:'+inttostr(info));
  wln('  align:'+inttostr(align));
  wln('  entsize:'+inttostr(entsize));
end;

function TElfHdr.shdrData(const idx:integer):ansistring;
var h:PElfSect;
begin
  h:=shdr(idx);if h=nil then exit('');
  setlength(result,h.size);
  move(pointer(integer(@self)+h.offset)^,pointer(result)^,h.size);
end;

function TElfHdr.shdrName(const idx:integer):ansistring;
var h:PElfSect;
    names:ansistring;
    idx2,i,st,en:integer;
begin
  h:=shdr(idx);if h=nil then exit('');

  idx2:=h.name;

  names:=shdrData(strsec);
  st:=idx2+1;
  for i:=st to length(names)do if names[i]=#0 then begin
    en:=i;
    exit(copy(names,st,en-st));
  end;
  result:='';
end;

function TElfHdr.Dump;
  procedure w(const s:ansistring);begin result:=result+s end;procedure wln(const s:ansistring);begin w(s+#13#10)end;

var i:integer;
begin result:='';
  wln('hdrsize'+': '+inttostr(hdrsize));
  wln('phdrent'+': '+inttostr(phdrent));
  wln('phdrcnt'+': '+inttostr(phdrcnt));
  wln('shdrent'+': '+inttostr(shdrent));
  wln('shdrcnt'+': '+inttostr(shdrcnt));
  wln('strsec'+': '+inttostr(strsec));

  //dump sections
  for i:=0 to shdrcnt-1 do with shdr(i)^ do begin
    wln('sec'+inttostr(i)+' '+shdrname(i)+' '+inttostr(size)+' bytes');
    w(dump);
//    FileWriteStr('c:\sec'+inttostr(i),shdrData(i));
  end;
end;

const ISA_INSTR_OP2_list:array[0..177]of record code:integer;name:ansistring end=(
(code:0 ;name:'OP2_INST_ADD'),
(code:1 ;name:'OP2_INST_MUL'),
(code:2 ;name:'OP2_INST_MUL_IEEE'),
(code:3 ;name:'OP2_INST_MAX'),
(code:4 ;name:'OP2_INST_MIN'),
(code:5 ;name:'OP2_INST_MAX_DX10'),
(code:6 ;name:'OP2_INST_MIN_DX10'),
(code:7 ;name:'Reserved.'),
(code:8 ;name:'OP2_INST_SETE'),
(code:9 ;name:'OP2_INST_SETGT'),
(code:10 ;name:'OP2_INST_SETGE'),
(code:11 ;name:'OP2_INST_SETNE'),
(code:12 ;name:'OP2_INST_SETE_DX10'),
(code:13 ;name:'OP2_INST_SETGT_DX10'),
(code:14 ;name:'OP2_INST_SETGE_DX10'),
(code:15 ;name:'OP2_INST_SETNE_DX10'),
(code:16 ;name:'OP2_INST_FRACT'),
(code:17 ;name:'OP2_INST_TRUNC'),
(code:18 ;name:'OP2_INST_CEIL'),
(code:19 ;name:'OP2_INST_RNDNE'),
(code:20 ;name:'OP2_INST_FLOOR'),
(code:21 ;name:'OP2_INST_ASHR_INT'),
(code:22 ;name:'OP2_INST_LSHR_INT'),
(code:23 ;name:'OP2_INST_LSHL_INT'),
(code:24 ;name:'Reserved'),
(code:25 ;name:'OP2_INST_MOV'),
(code:26 ;name:'OP2_INST_NOP'),
(code:27 ;name:'OP2_INST_MUL_64'),
(code:28 ;name:'OP2_INST_FLT64_TO_FLT32'),
(code:29 ;name:'OP2_INST_FLT32_TO_FLT64'),
(code:30 ;name:'OP2_INST_PRED_SETGT_UINT'),
(code:31 ;name:'OP2_INST_PRED_SETGE_UINT'),
(code:32 ;name:'OP2_INST_PRED_SETE'),
(code:33 ;name:'OP2_INST_PRED_SETGT'),
(code:34 ;name:'OP2_INST_PRED_SETGE'),
(code:35 ;name:'OP2_INST_PRED_SETNE'),
(code:36 ;name:'OP2_INST_PRED_SET_INV'),
(code:37 ;name:'OP2_INST_PRED_SET_POP'),
(code:38 ;name:'OP2_INST_PRED_SET_CLR'),
(code:39 ;name:'OP2_INST_PRED_SET_RESTORE'),
(code:40 ;name:'OP2_INST_PRED_SETE_PUSH'),
(code:41 ;name:'OP2_INST_PRED_SETGT_PUSH'),
(code:42 ;name:'OP2_INST_PRED_SETGE_PUSH'),
(code:43 ;name:'OP2_INST_PRED_SETNE_PUSH'),
(code:44 ;name:'OP2_INST_KILLE'),
(code:45 ;name:'OP2_INST_KILLGT'),
(code:46 ;name:'OP2_INST_KILLGE'),
(code:47 ;name:'OP2_INST_KILLNE'),
(code:48 ;name:'OP2_INST_AND_INT'),
(code:49 ;name:'OP2_INST_OR_INT'),
(code:50 ;name:'OP2_INST_XOR_INT'),
(code:51 ;name:'OP2_INST_NOT_INT'),
(code:52 ;name:'OP2_INST_ADD_INT'),
(code:53 ;name:'OP2_INST_SUB_INT'),
(code:54 ;name:'OP2_INST_MAX_INT'),
(code:55 ;name:'OP2_INST_MIN_INT'),
(code:56 ;name:'OP2_INST_MAX_UINT'),
(code:57 ;name:'OP2_INST_MIN_UINT'),
(code:58 ;name:'OP2_INST_SETE_INT'),
(code:59 ;name:'OP2_INST_SETGT_INT'),
(code:60 ;name:'OP2_INST_SETGE_INT'),
(code:61 ;name:'OP2_INST_SETNE_INT'),
(code:62 ;name:'OP2_INST_SETGT_UINT'),
(code:63 ;name:'OP2_INST_SETGE_UINT'),
(code:64 ;name:'OP2_INST_KILLGT_UINT'),
(code:65 ;name:'OP2_INST_KILLGE_UINT'),
(code:66 ;name:'OP2_INST_PREDE_INT'),
(code:67 ;name:'OP2_INST_PRED_SETGT_INT'),
(code:68 ;name:'OP2_INST_PRED_SETGE_INT'),
(code:69 ;name:'OP2_INST_PRED_SETNE_INT'),
(code:70 ;name:'OP2_INST_KILLE_INT'),
(code:71 ;name:'OP2_INST_KILLGT_INT'),
(code:72 ;name:'OP2_INST_KILLGE_INT'),
(code:73 ;name:'OP2_INST_KILLNE_INT'),
(code:74 ;name:'OP2_INST_PRED_SETE_PUSH_INT'),
(code:75 ;name:'OP2_INST_PRED_SETGT_PUSH_INT'),
(code:76 ;name:'OP2_INST_PRED_SETGE_PUSH_INT'),
(code:77 ;name:'OP2_INST_PRED_SETNE_PUSH_INT'),
(code:78 ;name:'OP2_INST_PRED_SETLT_PUSH_INT'),
(code:79 ;name:'OP2_INST_PRED_SETLE_PUSH_INT'),
(code:80 ;name:'OP2_INST_FLT_TO_INT'),
(code:81 ;name:'OP2_INST_BFREV_INT'),
(code:82 ;name:'OP2_INST_ADDC_UINT'),
(code:83 ;name:'OP2_INST_SUBB_UINT'),
(code:84 ;name:'OP2_INST_GROUP_BARRIER'),
(code:85 ;name:'OP2_INST_GROUP_SEQ_BEGIN'),
(code:86 ;name:'OP2_INST_GROUP_SEQ_END'),
(code:87 ;name:'OP2_INST_SET_MODE'),
(code:88 ;name:'OP2_INST_SET_CF_IDX0'),
(code:89 ;name:'OP2_INST_SET_CF_IDX1'),
(code:90 ;name:'OP2_INST_SET_LDS_SIZE'),
(code:129 ;name:'OP2_INST_EXP_IEEE'),
(code:130 ;name:'OP2_INST_LOG_CLAMPED'),
(code:131 ;name:'OP2_INST_LOG_IEEE'),
(code:132 ;name:'OP2_INST_RECIP_CLAMPED'),
(code:133 ;name:'OP2_INST_RECIP_FF'),
(code:134 ;name:'OP2_INST_RECIP_IEEE'),
(code:135 ;name:'OP2_INST_RECIPSQRT_CLAMPED'),
(code:136 ;name:'OP2_INST_RECIPSQRT_FF'),
(code:137 ;name:'OP2_INST_RECIPSQRT_IEEE'),
(code:138 ;name:'OP2_INST_SQRT_IEEE'),
(code:141 ;name:'OP2_INST_SIN'),
(code:142 ;name:'OP2_INST_COS'),
(code:143 ;name:'OP2_INST_MULLO_INT'),
(code:144 ;name:'OP2_INST_MULHI_INT'),
(code:145 ;name:'OP2_INST_MULLO_UINT'),
(code:146 ;name:'OP2_INST_MULHI_UINT'),
(code:147 ;name:'OP2_INST_RECIP_INT'),
(code:148 ;name:'OP2_INST_RECIP_UINT'),
(code:149 ;name:'OP2_INST_RECIP_64'),
(code:150 ;name:'OP2_INST_RECIP_CLAMPED_64'),
(code:151 ;name:'OP2_INST_RECIPSQRT_64'),
(code:152 ;name:'OP2_INST_RECIPSQRT_CLAMPED_64'),
(code:153 ;name:'OP2_INST_SQRT_64'),
(code:154 ;name:'OP2_INST_FLT_TO_UINT'),
(code:155 ;name:'OP2_INST_INT_TO_FLT'),
(code:156 ;name:'OP2_INST_UINT_TO_FLT'),
(code:160 ;name:'OP2_INST_BFM_INT'),
(code:162 ;name:'OP2_INST_FLT32_TO_FLT16'),
(code:163 ;name:'OP2_INST_FLT16_TO_FLT32'),
(code:164 ;name:'OP2_INST_UBYTE0_FLT'),
(code:165 ;name:'OP2_INST_UBYTE1_FLT'),
(code:166 ;name:'OP2_INST_UBYTE2_FLT'),
(code:167 ;name:'OP2_INST_UBYTE3_FLT'),
(code:170 ;name:'OP2_INST_BCNT_INT'),
(code:171 ;name:'OP2_INST_FFBH_UINT'),
(code:172 ;name:'OP2_INST_FFBL_INT'),
(code:173 ;name:'OP2_INST_FFBH_INT'),
(code:174 ;name:'OP2_INST_FLT_TO_UINT4'),
(code:175 ;name:'OP2_INST_DOT_IEEE'),
(code:176 ;name:'OP2_INST_FLT_TO_INT_RPI'),
(code:177 ;name:'OP2_INST_FLT_TO_INT_FLOOR'),
(code:178 ;name:'OP2_INST_MULHI_UINT24'),
(code:179 ;name:'OP2_INST_MBCNT_32HI_INT'),
(code:180 ;name:'OP2_INST_OFFSET_TO_FLT'),
(code:181 ;name:'OP2_INST_MUL_UINT24'),
(code:182 ;name:'OP2_INST_BCNT_ACCUM_PREV_INT'),
(code:183 ;name:'OP2_INST_MBCNT_32LO_ACCUM_PREV_INT'),
(code:184 ;name:'OP2_INST_SETE_64'),
(code:185 ;name:'OP2_INST_SETNE_64'),
(code:186 ;name:'OP2_INST_SETGT_64'),
(code:187 ;name:'OP2_INST_SETGE_64'),
(code:188 ;name:'OP2_INST_MIN_64'),
(code:189 ;name:'OP2_INST_MAX_64'),
(code:190 ;name:'OP2_INST_DOT4'),
(code:191 ;name:'OP2_INST_DOT4_IEEE'),
(code:192 ;name:'OP2_INST_CUBE'),
(code:193 ;name:'OP2_INST_MAX4'),
(code:196 ;name:'OP2_INST_FREXP_64'),
(code:197 ;name:'OP2_INST_LDEXP_64'),
(code:198 ;name:'OP2_INST_FRACT_64'),
(code:199 ;name:'OP2_INST_PRED_SETGT_64'),
(code:200 ;name:'OP2_INST_PRED_SETE_64'),
(code:201 ;name:'OP2_INST_PRED_SETGE_64'),
(code:202 ;name:'OP2_INST_MUL_64'),
(code:203 ;name:'OP2_INST_ADD_64'),
(code:204 ;name:'OP2_INST_MOVA_INT'),
(code:205 ;name:'OP2_INST_FLT64_TO_FLT32'),
(code:206 ;name:'OP2_INST_FLT32_TO_FLT64'),
(code:207 ;name:'OP2_INST_SAD_ACCUM_PREV_UINT'),
(code:208 ;name:'OP2_INST_DOT'),
(code:209 ;name:'OP2_INST_MUL_PREV'),
(code:210 ;name:'OP2_INST_MUL_IEEE_PREV'),
(code:211 ;name:'OP2_INST_ADD_PREV'),
(code:212 ;name:'OP2_INST_MULADD_PREV'),
(code:213 ;name:'OP2_INST_MULADD_IEEE_PREV'),
(code:214 ;name:'OP2_INST_INTERP_XY'),
(code:215 ;name:'OP2_INST_INTERP_ZW'),
(code:216 ;name:'OP2_INST_INTERP_X'),
(code:217 ;name:'OP2_INST_INTERP_Z'),
(code:218 ;name:'OP2_INST_STORE_FLAGS'),
(code:219 ;name:'OP2_INST_LOAD_STORE_FLAGS'),
(code:220 ;name:'OP2_INST_LDS_1A: DO NOT USE.'),
(code:221 ;name:'OP2_INST_LDS_1A1D: DO NOT USE.'),
(code:223 ;name:'OP2_INST_LDS_2A: DO NOT USE.'),
(code:224 ;name:'OP2_INST_INTERP_LOAD_P0'),
(code:225 ;name:'OP2_INST_INTERP_LOAD_P10'),
(code:226 ;name:'OP2_INST_INTERP_LOAD_P20'));

function ISA_INSTR_OP2_name(const ACode:integer):ansistring;
var i:integer;
begin
  for i:=0 to high(ISA_INSTR_OP2_list)do with ISA_INSTR_OP2_list[i]do
    if ACode=Code then exit(copy(Name,10));
  result:='unknown OP2';
end;

const ISA_INSTR_OP3_list:array[0..24]of record code:integer;name:ansistring end=(
(code:4 ;name:'OP3_INST_BFE_UINT'),
(code:5 ;name:'OP3_INST_BFE_INT'),
(code:6 ;name:'OP3_INST_BFI_INT'),
(code:7 ;name:'OP3_INST_FMA'),
(code:9 ;name:'OP3_INST_CNDNE_64'),
(code:10 ;name:'OP3_INST_FMA_64'),
(code:11 ;name:'OP3_INST_LERP_UINT'),
(code:12 ;name:'OP3_INST_BIT_ALIGN_INT'),
(code:13 ;name:'OP3_INST_BYTE_ALIGN_INT'),
(code:14 ;name:'OP3_INST_SAD_ACCUM_UINT'),
(code:15 ;name:'OP3_INST_SAD_ACCUM_HI_UINT'),
(code:16 ;name:'OP3_INST_MULADD_UINT24'),
(code:17 ;name:'OP3_INST_LDS_IDX_OP: This opcodes implies ALU_WORD*_LDS_IDX_OP encoding.'),
(code:20 ;name:'OP3_INST_MULADD'),
(code:21 ;name:'OP3_INST_MULADD_M2'),
(code:22 ;name:'OP3_INST_MULADD_M4'),
(code:23 ;name:'OP3_INST_MULADD_D2'),
(code:24 ;name:'OP3_INST_MULADD_IEEE'),
(code:25 ;name:'OP3_INST_CNDE'),
(code:26 ;name:'OP3_INST_CNDGT'),
(code:27 ;name:'OP3_INST_CNDGE'),
(code:28 ;name:'OP3_INST_CNDE_INT'),
(code:29 ;name:'OP3_INST_CMNDGT_INT'),
(code:30 ;name:'OP3_INST_CMNDGE_INT'),
(code:31 ;name:'OP3_INST_MUL_LIT'));

function ISA_INSTR_OP3_name(const ACode:integer):ansistring;
var i:integer;
begin
  for i:=0 to high(ISA_INSTR_OP3_list)do with ISA_INSTR_OP3_list[i]do
    if ACode=Code then exit(copy(Name,10));
  result:='unknown OP3';
end;

//var      debug:ansistring;
//      linecnt:integer;

function TElfHdr.PatchInstrOp3(oldInstr,newInstr:byte):integer;

  procedure DoIt(const p:pbyte;const siz:integer);
  type
    trow=record case byte of
      0:(b:array[0..7]of byte);
      1:(dw:array[0..1]of integer);
      2:(qw:int64);
    end;
    trows=array[0..0]of trow;
    prows=^trows;

  var rows:prows;
      instr,r,rowcount:integer;
      literalCount:integer;
      LiteralBytes:integer;
  begin
    rows:=prows(p);
    rowcount:=siz div 8;
    r:=0;
    while(r<rowcount)and(rows[r].qw<>0)do inc(r);//skip padding
//experimental EOP
//    rows[r-3].dw[1]:=rows[r-3].dw[1]or 1 shl 21; //big fail ->
    while(r<rowcount)and(rows[r].qw= 0)do inc(r);//skip padding

//debug:='';linecnt:=0;debug:=debug+tostr(linecnt)+' ';

    LiteralBytes:=0;
    literalCount:=0;
    while(r<rowcount)do with rows[r]do begin
      if(dw[0]shr 0 and $1ff)=253 then//src0 literal?
        literalCount:=max(literalCount,(dw[0]shr (10+1) and 1){src0 chn high bit}+1);
      if(dw[0]shr 13 and $1ff)=253 then//src1 literal?
        literalCount:=max(literalCount,(dw[0]shr (23+1) and 1){src1 chn high bit}+1);

      instr:=dw[1]shr 7 and $7ff;
      if instr shr 8=0 then begin //op2
//        debug:=debug+' '+ISA_INSTR_OP2_name(instr);
      end else begin//op3
        instr:=instr shr 6;
//        debug:=debug+' '+ISA_INSTR_OP3_name(instr);

        if(dw[1]shr 0 and $1ff)=253 then//src2 literal?
          literalCount:=max(literalCount,(dw[1]shr (10+1) and 1){src2 chn high bit}+1);

        if((dw[1]shr 13 and $1f)=oldInstr)then begin//instr replace
          dw[1]:=dw[1]and not($1f shl 13)+(newInstr shl 13);
          inc(result);
        end;
      end;

      if(dw[0]shr 31)<>0 then begin//last instr in a grp
//        debug:=debug+#13#10;inc(linecnt);debug:=debug+tostr(linecnt)+' ';
        LiteralBytes:=LiteralBytes+literalCount*8;

        r:=r+literalCount; //skip literals
        literalCount:=0;
      end;

      inc(r);
    end;

//    FileWriteStr('c:\debug.txt',debug);

{ old   for r:=0 to rowcount-1 do with rows[r] do if initialseek then begin//béna seek, az align-ra hagyatkozva
      if dw[0]=0 then initialseek:=false;
    end else begin
      if(qw<>0)and((dw[1]shr 13 and $1f)=oldInstr)then begin
        dw[1]:=dw[1]and not(bitmask shl bitofs)+newInstr shl bitofs;
        inc(result);
      end;
    end;}

//    raise Exception.Create('LiteralBytes='+tostr(LiteralBytes));
  end;

var i:integer;
    f:file;
begin
  result:=0;
  for i:=shdrcnt-1 downto 0 do if shdrName(i)='.text' then begin
    {debug}assignfile(f,'c:\isa.bin');Rewrite(f,1);BlockWrite(f,pointer(integer(@self)+shdr(i).offset)^,shdr(i).size);CloseFile(f);
    DoIt(pointer(integer(@self)+shdr(i).offset),shdr(i).size);
    break;
  end;
end;

function TElfHdr.shdr(const idx:integer):PElfSect;
begin
  if not InRange(idx,0,shdrcnt-1)then exit(nil);
  result:=PElfSect(integer(@self)+shdrpos+shdrent*idx);
end;

procedure SetupKernel(ILkernel:AnsiString;out module:CALmodule;out literalConsts:TLiteralConstArray;const ctx:CALcontext;const disassemble:boolean;const ATarget:CALtarget);
var
  i:integer;
  image:CALimage;
  obj:CALobject;
  _5xxVecSelCount:integer;//patch bytealign -> bfi_int
//  attribs:CALdeviceattribs;
  siz:cardinal;
  buf:TBytes;
begin
  // Get device specific information
{  attribs.struct_size:=sizeof(attribs);
  calCheck(calDeviceGetAttribs(attribs,devIdx),'calDeviceGetAttribs');}

  // Compile IL kernel into object
//  showmessage(inttostr(ord(ATarget)));

  ILKernel:=ILCompilePrePass(ILKernel,ATarget,_5xxVecSelCount,literalConsts);
//  FileWriteStr('c:\ilPrecompiled.cal',ILKernel);

  calclCheck(calclCompile(obj, CAL_LANGUAGE_IL, PAnsiChar(ILKernel), ATarget),'calclCompile');//{ CAL_TARGET_CYPRESS{ ATarget}}//CALtarget(15))
  try

{    calDisassembledObjectText:='';
    calclDisassembleObject(obj,_calDisasmObjLogger);//Szar, Accessviola in .dll
    FileWriteStr('c:\obj.bin',calDisassembledObjectText);}

    // Link object into an image
    calclCheck(calclLink(image,obj,1),'calclLink');

    //optional patch bytealign -> BFI_INT
    if _5xxVecSelCount>0 then begin
      calclImageGetSize(siz,image);
      setlength(buf,siz);
      calclImageWrite(pointer(buf),siz,image);
//FileWriteBytes('c:\isa.bin',buf);

      i:=PElfHdr(buf)^.PatchInstrOp3(13{bytealign},6{BFI_INT});
      if _5xxVecSelCount<>i then
        raise Exception.Create('CAL compiler pre-pass: '+
          ' BFI_INT patcher error:  vec_sel='+tostr(_5xxVecSelCount)+'  patched='+toStr(i)+'  (use vec_sel_unopt to avoid optimizer related errors!)');

//FileWriteStr('c:\elf.dump',PElfHdr(buf)^.Dump);

      calclFreeImage(image);
      calImageRead(image,pointer(buf),siz);
    end;

    try
      if disassemble then begin
        calDisassembledText:='';
        calclDisassembleImage(image,_calDisasmLogger);
//        FileWriteStr('c:\isa.asm',calDisassembledText);
      end;

      // Load module into the context
      if ctx<>0 then
        calCheck(calModuleLoad(module,ctx,image),'calModuleLoad');
    finally
      calImageFree(image);
    end;
  finally
    calclFreeObject(obj);
  end;
end;

//compile from hetcal to bfi patched elf
function CompileKernel(ILkernel:AnsiString;out literalConsts:TLiteralConstArray;const ctx:CALcontext;const ATarget:CALtarget):RawByteString;
var
  i:integer;
  image:CALimage;
  obj:CALobject;
  _5xxVecSelCount:integer;//patch bytealign -> bfi_int
  siz:cardinal;
begin
  result:='';
  ILKernel:=ILCompilePrePass(ILKernel,ATarget,_5xxVecSelCount,literalConsts);
  calclCheck(calclCompile(obj, CAL_LANGUAGE_IL, PAnsiChar(ILKernel), ATarget),'calclCompile');
  try
    calclCheck(calclLink(image,obj,1),'calclLink');
    calclImageGetSize(siz,image);
    setlength(result,siz);
    calclImageWrite(pointer(result),siz,image);
    calImageFree(image);

    //patch if needed
    if _5xxVecSelCount>0 then begin
      i:=PElfHdr(result)^.PatchInstrOp3(13{bytealign},6{BFI_INT});
      if _5xxVecSelCount<>i then
        raise Exception.Create('CAL compiler pre-pass: '+
          ' BFI_INT patcher error:  vec_sel='+tostr(_5xxVecSelCount)+'  patched='+toStr(i)+'  (use vec_sel_unopt to avoid optimizer related errors!)');
    end;
  finally
    calclFreeObject(obj);
  end;
end;

////////////////////////////////////////////////////////////////////////////////
///  TGPUDevice                                                              ///
////////////////////////////////////////////////////////////////////////////////

constructor TGPUDevice.Create(const ADeviceId: integer);

  procedure Cleanup;
  begin
    calDeviceClose(dev);
  end;

var devCnt:CALuint;
begin
  FDeviceId:=ADeviceId;

  try
    calInit;

    calDeviceGetCount(devCnt);
    if devCnt=0 then raise Exception.Create('No CAL device found.');

    if cardinal(ADeviceId)>=devCnt then raise Exception.Create('CAL device index out of range');

    calCheck(calDeviceGetInfo(devInfo,FDeviceId),'calDeviceGetInfo');

    devAttr.struct_size:=sizeof(devAttr);
    calCheck(calDeviceGetAttribs(devAttr,FDeviceId),'calDeviceGetAttribs');

    calCheck(calDeviceOpen(dev,FDeviceId),'calDeviceOpen');

    devStat.struct_size:=sizeof(devStat);
    calCheck(calDeviceGetStatus(devStat,dev),'calDeviceGetStatus');

  except
    on e:exception do begin Cleanup;raise end;
  end;

end;

destructor TGPUDevice.Destroy;
begin
  calDeviceClose(dev);
end;

var GPUDeviceCache:array[0..15]of TGpuDevice;

procedure FreeGPUDeviceCache;
var i:integer;
begin
  for i:=0 to high(GPUDeviceCache)do FreeAndNil(GPUDeviceCache[i]);
end;

function GetGpuDevice(const ADeviceId:integer):TGPUDevice;
begin
  if InRange(ADeviceId,0,High(GPUDeviceCache))then begin
    if GPUDeviceCache[ADeviceId]=nil then
      GPUDeviceCache[ADeviceId]:=TGPUDevice.Create(ADeviceId);

    result:=GPUDeviceCache[ADeviceId];
  end else
    raise Exception.Create('GpuDeviceId out of range');
end;

////////////////////////////////////////////////////////////////////////////////
///  TGPUContext                                                             ///
////////////////////////////////////////////////////////////////////////////////

constructor TGPUContext.Create(const ADeviceId: integer);
begin
{$IFDEF RECREATECONTEXT}
  dev:=TGPUDevice.Create(ADeviceId);
{$ELSE}
  dev:=GetGpuDevice(ADeviceId);//from cache
{$ENDIF}
  calCheck(calCtxCreate(ctx,dev.dev),'calCtxCreate');
end;

destructor TGPUContext.Destroy;
begin
  calCtxDestroy(ctx);
{$IFDEF RECREATECONTEXT}
  FreeAndNil(dev);
{$ENDIF}
end;

var GPUContextCache:array[0..15]of TGpuContext;

procedure FreeGPUContextCache;
var i:integer;
begin
  for i:=0 to high(GPUContextCache)do FreeAndNil(GPUContextCache[i]);
end;

function GetGpuContext(const ADeviceId:integer):TGPUContext;
begin
  if InRange(ADeviceId,0,High(GPUContextCache))then begin
    if GPUContextCache[ADeviceId]=nil then
      GPUContextCache[ADeviceId]:=TGPUContext.Create(ADeviceId);
    result:=GPUContextCache[ADeviceId];
  end else
    raise Exception.Create('GpuDeviceId out of range');
end;

////////////////////////////////////////////////////////////////////////////////
///  TGPUProgram                                                             ///
////////////////////////////////////////////////////////////////////////////////

procedure TGPUProgram.Cleanup;
begin
  if FPrepared then begin
    FPrepared:=false;

    calCtxReleaseMem(FContext.ctx,globalMem);
    calResFree(globalRes);
    calCtxReleaseMem(FContext.ctx,constMem);
    calResFree(constRes);
    calModuleUnload(FContext.ctx,module);

{$IFDEF RECREATECONTEXT}
    FreeAndNil(FContext);
{$ENDIF}
 end;
end;

procedure TGPUProgram.Prepare(const ADeviceId:integer;const AProgram:ansistring;const AConstLen:integer;const AGlobalLen:integer);
var s,hdr:ansistring;
    globalXs,globalYs:integer;
begin
  if not FPrepared or(FProgram<>AProgram)or(FDeviceId<>ADeviceId)or(AConstLen<>FConstLen)or(AGlobalLen<>FGlobalLen)then begin
    Cleanup;

    FDeviceId:=ADeviceId;
    FProgram:=AProgram;
    FConstLen:=AConstLen;
    FGlobalLen:=AGlobalLen;

    FPrepared:=true;

{$IFDEF RECREATECONTEXT}
    FContext:=TGPUContext.Create(ADeviceId);
{$ELSE}
    FContext:=GetGpuContext(ADeviceId);//from cache
{$ENDIF}

    FTarget:=FContext.dev.devAttr.target;
    try

      if FConstLen and $f<>0 then raise Exception.Create('CAL Error, constant len must be 16byte aligned');
      if FGlobalLen and $f<>0 then raise Exception.Create('CAL Error, global len must be 16byte aligned');

      FConstLen128:=max(1,FConstLen shr 4);   FConstLen128:=(FConstLen128+63)and not 63;//pinned memory pitch
      FGlobalLen128:=max(1,FGlobalLen shr 4); FGlobalLen128:=(FGlobalLen128+63)and not 63;

{$IFDEF UAV}
      hdr:='il_cs_2_0'#13#10+
         'dcl_num_thread_per_group '+tostr(uavblockwidth)+',1,1'#13#10+
         'dcl_raw_uav_id(0)'#13#10+
         'dcl_cb cb0['+intToStr(FConstLen128)+']'#13#10+
         'mov r0.x, vAbsTidFlat.x'#13#10;
{$ELSE}
      hdr:='il_ps_2_0'#13#10+
         'dcl_input_position_interp(linear_noperspective) vWinCoord0.xy__'#13#10+
         'dcl_cb cb0['+intToStr(FConstLen128)+']'#13#10+
         'dcl_literal l1000, 8192, 0, 0, 0'#13#10+
         'ftoi r0, vWinCoord0'#13#10+
         'imad r0.x, r0.y, l1000.x, r0.x'#13#10;
{$ENDIF}
      if(pos('il_ps_2_0',FProgram)>0)or(pos('il_cs_2_0',FProgram)>0)then
        s:=FProgram
      else
        s:=hdr+FProgram+#13#10'end'#13#10;
//      showMessage(GetEnumName(typeinfo(CALTarget),ord(devattr.target)));
      calDisassembledText:='';
      try
        SetupKernel(s,module,FLiteralConsts,FContext.ctx,true,FContext.dev.devattr.target);
      except
        FDisasm:=calDisassembledText;
        raise;
      end;
      FDisasm:=calDisassembledText;
      //const
//      calCheck(calResAllocLocal1D(constRes,dev,FConstLen128,CAL_FORMAT_UNORM_INT32_4),'calResAllocLocal1D');

      SetLength(FConstPool,FConstLen128*16+$1000);
      calCheck(CalResCreate1D(constRes,FContext.dev.dev,ConstMemPtr,FConstLen128,CAL_FORMAT_UNORM_INT32_4,FConstLen128*16),'CalResCreate1D const');

      calCheck(calCtxGetMem(constMem,FContext.ctx,constRes),'calCtxGetMem');
      calCheck(calModuleGetName(constName,FContext.ctx,module,'cb0'),'calModuleGetName');
      calCheck(calCtxSetMem(FContext.ctx,constName,constMem),'calCtxSetMem');

      //global //UAV -> 32bit element size only!!!
//      calCheck(calResAllocLocal1D(globalRes,dev,FGlobalLen128*4,CAL_FORMAT_UNSIGNED_INT32_1,CAL_RESALLOC_GLOBAL_BUFFER),'calResAllocLocal1D');

      globalYs:=(FGlobalLen128*4+$1fff) shr 13;
      if globalYs<=1 then globalxs:=FGlobalLen128*4
                     else globalXs:=$2000;

      SetLength(FGlobalPool, globalXs*globalYs*4+$1000{align});

      if globalYs<=1 then calCheck(CalResCreate1D(globalRes,FContext.dev.dev,GlobalMemPtr,globalXs,         CAL_FORMAT_UNORM_INT32_1,0),'CalResCreate1D global('+inttostr(FGlobalLen128)+' B)')
                     else calCheck(CalResCreate2D(globalRes,FContext.dev.dev,GlobalMemPtr,globalXs,globalYs,CAL_FORMAT_UNORM_INT32_1,0),'CalResCreate2D global('+inttostr(FGlobalLen128)+' B)');
                                                                                                                                   //^size kotelezoen 0!!!
      calCheck(calCtxGetMem(globalMem,FContext.ctx,globalRes),'calCtxGetMem');

{$IFDEF UAV}
      calCheck(calModuleGetName(globalName,FContext.ctx,module,'uav0'),'calModuleGetName');
{$ELSE}
      calCheck(calModuleGetName(globalName,FContext.ctx,module,'g[]'),'calModuleGetName');
{$ENDIF}

      calCheck(calCtxSetMem(FContext.ctx,globalName,globalMem),'calCtxSetMem');

      calCheck(calModuleGetEntry(func,FContext.ctx,module,'main'),'calModuleGetEntry main');

      FPrepared:=true;
    except
      on e:exception do begin Cleanup;raise end;
    end;
  end;
end;

procedure TGPUProgram.Run(const xs,ys:integer;var AConst;var AGlobal);

  procedure SetupLiteralConstants;
  var i:integer;
  begin
    for i:=0 to high(FLiteralConsts)do with FLiteralConsts[i]do begin
      if(id<0)or((id+1)shl 4>FConstLen)then
        raise Exception.Create('TGPUProgram.Rin() Initial LiteralConst index out of range (id:'+tostr(id)+'; max:'+ToStr(FConstLen shr 4-1));
      move(value,psucc(@AConst,id shl 4)^,16);
    end;
  end;

var //p:pointer;
    //pitch:CALuint;
    domain:CALdomain;
    {$IFDEF UAV}gr:CALprogramGrid;{$ENDIF}
    inf:CALdeviceinfo;
begin
  if not FPrepared then raise Exception.Create('CAL Error: not prepared');

{  calCheck(calResMap(p,pitch,ConstRes),'calResMap');
  system.move(AConst,p^,FConstLen);
  calCheck(calResUnmap(ConstRes),'calResUnmap');}
  SetupLiteralConstants;
  move(AConst,ConstMemPtr^,FConstLen);//pinned

{  calCheck(calResMap(p,pitch,GlobalRes),'calResMap');
  system.move(AGlobal,p^,FGlobalLen);
  calCheck(calResUnmap(GlobalRes),'calResUnmap');}
  move(AGlobal,GlobalMemPtr^,FGlobalLen);//pinned

{$IFDEF UAV}
  fillchar(gr,sizeof(gr),0);
  gr.func:=func;
  gr.gridBlock.width:=uavblockwidth;
  gr.gridBlock.height:=1;
  gr.gridBlock.depth:=1;
  gr.gridSize.width:=xs*ys div gr.gridBlock.width;
  gr.gridSize.height:=1;
  gr.gridSize.depth:=1;
  gr.flags:=0;
  calCheck(calCtxRunProgramGrid(event,FContext.ctx,gr),'calCtxRunProgram');
{$ELSE}
  calDeviceGetInfo(inf,FDeviceId);
  if(cardinal(xs)>inf.maxResource2DWidth)then raise Exception.Create('CAL: domain width out of range ('+toStr(xs)+'>'+ToStr(inf.maxResource2DWidth)+')');
  if(cardinal(ys)>inf.maxResource2DHeight)then raise Exception.Create('CAL: domain height out of range ('+toStr(ys)+'>'+ToStr(inf.maxResource2DHeight)+')');
  domain.setup(0,0,xs,ys);
  calCheck(calCtxRunProgram(event,FContext.ctx,func,domain),'calCtxRunProgram');
{$ENDIF}
end;

constructor TGPUProgram.create;
begin
end;

function TGPUProgram.ConstMemPtr:pointer;
begin
  result:=pointer((integer(FConstPool)+$fff)and not $fff);
end;

function TGPUProgram.GlobalMemPtr:pointer;
begin
  result:=pointer((integer(FGlobalPool)+$fff)and not $fff);
end;

destructor TGPUProgram.Destroy;
begin
  Cleanup;
  inherited;
end;

function TGPUProgram.Finished:boolean;
begin
  result:=calCtxIsEventDone(FContext.ctx,event)<>CAL_RESULT_PENDING;
end;

procedure TGPUProgram.ReadGlobal(var AGlobal);
//var p:pointer;
//    pitch:CALuint;
begin
{  calCheck(calResMap(p,pitch,GlobalRes),'calResMap');
  system.move(p^,AGlobal,FGlobalLen);
  calCheck(calResUnmap(GlobalRes),'calResUnmap');}

  move(GlobalMemPtr^,AGlobal,FGlobalLen);
end;


function _ISADisasm(const ILSrc:ansistring;const ATarget:CALtarget):ansistring;
var m:CALmodule;lits:TLiteralConstArray;
begin
  result:='';
  SetupKernel(ILSrc,m,lits,0,true,ATarget);
  result:=calDisassembledText;
end;


procedure calFreeAllContexts;
begin
  FreeGPUContextCache;
  FreeGPUDeviceCache;
end;


initialization
finalization
  calFreeAllContexts;
end.
