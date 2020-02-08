unit het.cal;  //unsSystem unsCal het.cl het.parser
//!!!!!!!!!!!!!-ekre figyelni!

//new hetObject based cal wrapper
//previous version -> het.cal0
//usage: 'Cal.'+Ctrl+Space
interface

uses
  Windows, sysutils, math, het.Utils, het.Arrays, het.Objects, het.Parser, ucal,
  ucalcl, variants, het.Variants, typinfo,

  graphics, het.Gfx;  //bitmap import/export in TCalResource

{$DEFINE DEBUGFILES}
const _debugFilePath='c:\';

{ $DEFINE MODULECACHE}

type
  CALTarget=ucal.CALtarget;

  TCalObject=class(THetObject)
  private
    FHandle:CalUInt;
    function GetActive:boolean;
    procedure SetActive(const Value:boolean);
    function GetHandle: CALuint;
    procedure _Activate;virtual;abstract;
    procedure _Deactivate;virtual;abstract;
  public
    destructor Destroy;override;
    property Active:boolean read GetActive write SetActive;
    property Handle:CalUint read GetHandle;
    procedure Activate;inline;
    procedure Deactivate;inline;
  end;

  TCalResourceLocation=(rlLocal,rlRemote,rlRemoteCached,rlPinned);

  TI4=array[0..3]of integer;
  TLiteralConst=record
    id:integer;
    value:TI4;
  end;
  TLiteralConsts=TArray<TLiteralConst>;

  TCalContext=class;
  TCalContexts=class;
  TCalResource=class;
  TCalResources=class;
  TCalModule=class;
  TCalModules=class;
  TCalEvent=class;

(*  ICalEvent=dispinterface    //ez mÈg a hetpasban nem megy, kell valami dispatch factory
    ['{A7383F88-FF45-4549-94F5-7A5BAC4DD94B}']
    function Context:TCalContext;dispid 1; //na az egeszet nem kene idispatch-nak megcsinalni
    function Module:TCalModule;            //viszont ezeket a classokat meg manualisan kene VObject-kent visszaadni
    function ResSrc:TCalResource;
    function ResDst:TCalResource;
    function UserData:integer;

    function Running:boolean;
    function Finished:boolean;
    function Success:boolean;
    function ElapsedTime_sec:single;

    procedure WaitFor(ASleep:boolean=true);
  end;*)

  TCalDevice=class(TCalObject)
  private
    FDeviceId:integer;
    FContexts:TCalContexts;
    FResources:TCalResources;
    procedure _Activate;override;
    procedure _Deactivate;override;
  strict private
    FDevAttr:CALdeviceattribs;//cached
    FDevInfo:CALdeviceinfo;//cached
  public
    constructor Create(AOwner:THetObject;AId:integer);reintroduce;
    destructor Destroy;override;
  public
    function DevInfo:PCALdeviceinfo;
    function DevAttr:PCALdeviceattribs;
    function DevStat:CALdevicestatus;
    function Target:CalTarget;
    property DeviceId:integer read FDeviceId;
    function dump:ansistring;
    function Description:ansistring;
    function NewContext:TCalContext;
    function Context:TCalContext;
    function NewResource(ALocation:TCalResourceLocation;AComponents,AWidth:integer;AHeight:integer=0{linear}):TCalResource;
  published
    property Contexts:TCalContexts read FContexts;
    property Resources:TCalResources read FResources;
  end;

  TCalDevices=class(THetList<TCalDevice>)
  public property ByIndex;default;end;

  TCalContext=class(TCalObject)
  private
    type TCtxMemRec=record
      Resource:TCalResource;
      CtxMemHandle:calMem;
    end;
  private
    FModules:TCalModules;
    FCtxMems:array of TCtxMemRec;
    procedure _ResourceDeactivated(const AResource:TCalResource);
    procedure _Activate;override;
    procedure _Deactivate;override;
    function GetCtxMemHandle(const AResource:TCalResource):CALmem;
  private
    type TCachedModule=record hash:integer;handle:CALmodule end;
    var FModuleCache:THetArray<TCachedModule>;
    procedure FreeModuleCache;
  protected
    function CachedModule(const FImage:rawbytestring):CALmodule;
  public
    constructor Create(const AOwner:THetObject);override;
    function OwnerDevice:TCalDevice;
    function NewModule(const AProgram:ansistring):TCalModule;
    function MemCopy(const ASrc,ADst:Tcalresource;const AUserData:integer=0):TCalEvent;
  published
    property Modules:TCalModules read FModules;
  end;

  TCalContexts=class(THetList<TCalContext>)
  public property ByIndex;default;end;

  TCalResource=class(TCalObject)
  private
    FLocation:TCalResourceLocation;
    FComponents:integer;
    FWidth,FHeight:integer;
    FPinnedData:TArray<byte>;
    FPinnedPtr:pointer;
    FMapPtr:pointer;
    FMapPitch:cardinal;
    FSizeBytes:integer;
    procedure _Activate;override;
    procedure _Deactivate;override;
    procedure SetupLiteralConsts(const LC:TLiteralConsts);
  public
    const ComponentSize=4;
    constructor Create(AOwner:THetObject;ALocation:TCalResourceLocation;AComponents,AWidth:integer;AHeight:integer=0);reintroduce;
    destructor Destroy;override;
    function OwnerDevice:TCalDevice;
    function Map:pointer;
    property Pitch:cardinal read FMapPitch;
    procedure UnMap;//nem kotelezo, runprogram/memcopy automatikusan hivja majd
  public
    property Location:TCalResourceLocation read FLocation;
    property Components:integer read FComponents;
    property Width:integer read FWidth;
    property Height:integer read FHeight;//0:linear
    property Size:integer read FSizeBytes;
  public//data access
    type TElementType=(etInt,etFloat);
    function ReadVArray(const AElementType:TElementType):Variant;

    procedure WriteVArray(const Src:variant);

    function ReadIntVArray:variant;
    property IntVArray:variant read ReadIntVArray write WriteVArray;

    function ReadFloatVArray:variant;
    property FloatVArray:variant read ReadFloatVArray write WriteVArray;

    function AccessData(Elementsize,x: integer):pointer;

    function AccessByte(x:integer):PByte;
    function AccessInt(x:integer):PInteger;
    function AccessFloat(x:integer):PSingle;
    function AccessDouble(x:integer):PDouble;

    function GetByte(x:integer):Byte;
    function GetInt(x:integer):Integer;
    function GetFloat(x:integer):Single;
    function GetDouble(x:integer):Double;

    procedure SetByte(x:integer;v:Byte);
    procedure SetInt(x:integer;v:integer);
    procedure SetFloat(x:integer;v:single);
    procedure SetDouble(x:integer;v:double);

    property Ints[x:integer]:integer read GetInt write SetInt;
    property Floats[x:integer]:single read GetFloat write SetFloat;
    property Doubles[x:integer]:double read GetDouble write SetDouble;
    property Bytes[x:integer]:Byte read GetByte write SetByte;

    procedure ImportBitmap(const bmp: TBitmap; const ofs: integer);
    function ExportBitmap(const ofs,w,h,bpp:integer):TBitmap;

    procedure ImportStr(const s:ansistring;const ofs:integer);
    function ExportStr(const ofs,size:integer):ansistring;

    procedure Clear;
  end;

  TCalResources=class(THetList<TCalResource>)
  public property ByIndex;default;end;

  TCalModule=class(TCalObject)
  private
    type TSymbolResourceRec=record
      Symbol:ansistring;
      Resource:TCalResource;
      name:CALname;
    end;
  private
    FProgram:ansistring;
    FImage:RawByteString;//without literals
    FLiteralConsts:TLiteralConsts;
    FSymbols:TArray<TSymbolResourceRec>;//symbols with linked resources
    FEntry:CALfunc;
    FCB0SymbolIdx,FCB2SymbolIdx:integer;
    procedure _ResourceDestroyed(const AResource:TCalResource);
    procedure _Activate;override;
    procedure _Deactivate;override;
    procedure PrepareImage;
    function GetSymbolName(const AIdx:integer):ansistring;
    function FindSymbolIdx(const AWich: variant):integer;
    function GetSymbolResource(const AWich: variant):TCalResource;
    procedure SetSymbolResource(const AWich: variant; const ARes: TCalResource);
    function _Run(const AWidth, AHeight, AUserData:integer; ARunGrid:boolean): TCalEvent;
  public
    constructor Create(AOwner:THetObject;const AProgram:ansistring);reintroduce;
    function OwnerContext:TCalContext;

    function SymbolCount:integer;
    property SymbolName[const AIdx:integer]:ansistring read GetSymbolName;
    property Symbol[const AWich:variant]:TCalResource read GetSymbolResource write SetSymbolResource;default;

    function Run(const AWidth,AHeight:integer;const AUserData:integer=0):TCalEvent;
    function RunGrid(const AWidth,AHeight:integer;const AUserData:integer=0):TCalEvent;

    function Disasm:ansistring;
    property Image:rawbytestring read FImage write FImage;//for custom patches
    property LiteralConsts:TLiteralConsts read FLiteralConsts;
    function GetWaveFrontSize:integer;
  end;

  TCalModules=class(THetList<TCalModule>)
  public property ByIndex;default;end;

  TCalEvent=class({TInterfacedObject,ICalEvent}THetObject)
  private
    FContext:TCalContext;
    FModule:TCalModule;//kernel
    FResSrc,FResDst:TCalResource;//memcopy
    FUserData:integer;

    FEvent:CALevent;
    FCtx:CALcontext;

    FRunning,FSuccess:boolean;
    T0,T1:Int64;
    invFR:double;

    procedure CheckEvent;//polls calCtxIsEventDone
  public
    constructor create(AContext:TCalContext; AModule:TCalModule; AResSrc, AResDst:TCalResource; AEvent:CALevent; AUserData:integer);reintroduce;
    property Context:TCalContext read FContext;
    property Module:TCalModule read FModule;
    property ResSrc:TCalResource read FResSrc;
    property ResDst:TCalResource read FResDst;

  published
    property UserData:integer read FUserData;

    function Running:boolean;
    function Finished:boolean;
    function Success:boolean;
    function ElapsedTime_sec:single;

    procedure WaitFor;
  end;

  TCalEvents=class(THetList<TCalEvent>)
  end;

  Cal=class //Entry point to the whole thing
  private
    class var FDevices:TCalDevices;
    class var FEvents:TCalEvents;
  public
    class function Devices:TCalDevices;
    class function Events:TCalEvents;
    class function BuildIL(const AKernel:AnsiString;ATarget:CALtarget;const ADoPreCompile:boolean=true):RawByteString;
    class function BuildISA79xx(const AKernel:AnsiString;const isGCN3:boolean):RawByteString;//ISA->ELF
  public
    type TIsaMetrics=record
      VLIWSize,Clauses,Groups,Instructions,PReads,PWrites,VECs,Reads,Literals:integer;
      BYTE_ALIGN_INT_cnt,BFI_INT_cnt:integer;

      _7xxxV_Cnt,_7xxxS_Cnt:integer;
      function AsString:ansistring;
    end;
    class function ISAMetrics(const ISACode:ansistring):TIsaMetrics;
  end;


const
  _ElfMagic:ansistring=#$7F'ELF';
  _ElfCB0Magic:ansistring=#$7F'CB0';

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

  TElfProg=packed record
    type_,
    offset,
    vaddr,
    paddr,
    filesiz,
    memsiz,
    flags,
    align:integer;
    function Dump:ansistring;
  end;PElfProg=^TElfProg;

  TElfNotes=record
    NumThreadPerGroup:integer;
    cbsize:array[0..7]of integer;
  end;

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
    function Dump(const fileprefix:ansistring=''):ansistring;
    function shdr(const idx:integer):PElfSect;
    function phdr(const idx:integer):PElfProg;
    function phdrContents(const idx:integer):ansistring;
    function shdrName(const idx:integer):ansistring;
    function PatchInstrOp3(oldInstr,newInstr:byte):integer;//returns no of occurrences
    function GetNotes:TElfNotes;
    function SectionContents(const idx:integer):ansistring;
    function SectionData(const idx:integer):pointer;
    function ProgramData(const idx:integer):pointer;
    procedure SetSectionContents(const Idx:integer;const value:ansistring;out _res:ansistring);
    function FullSize:integer;
    function SectionIdxByName(const AName:ansistring;const ErrorIfNotFound:boolean=false):integer;
  end;PElfHdr=^TElfHdr;

  TElfSym=packed record
    name,value,size:integer;
    info,other:byte;
    shndx:word;
  end;PElfSym=^TElfSym;

procedure ReplaceElfSection(var Elf:ansistring;const secIdx:integer;const newContents:ansistring);overload;
procedure ReplaceElfSection(var Elf:ansistring;const secName:ansistring;const newContents:ansistring);overload;

function LiteralConstsToStr(const ALiteralConsts:TLiteralConsts):rawbytestring;
function StripLiteralConsts(const APrg:ansistring;out ALiteralConsts:TLiteralConsts):ansistring;//remaining program
procedure ApplyLiteralConsts(const ADst:pointer;const ALiteralConsts:TLiteralConsts);

// ISA79xx compiler export to het.cl

type
  TIsa79xxOptions=record
    numvgprs,
    numsgprs,
    cb0sizeDQWords,  //cal only
    ldsSizeBytes:integer;
    NumThreadPerGroup:record x,y,z:integer end;
    OclBuffers:record uavCount,cbCount:integer end;
    OclSkeleton:ansistring; //OpenCL function header and body without __kernel, overrides OclBuffers setting.
    procedure Reset;
  end;


function CompileISA79xx(const AKernel:ansistring; const isGCN3:boolean; out ALiteralConsts:TLiteralConsts;out AOptions:TIsa79xxOptions; out ARawWithoutData:RawByteString):RawByteString;

type TLiteralMode=(lmLiteral, lmCB0, lmCB2);
function PreCompileIL(const AKernel:ansistring;const ATarget:CALtarget;Out ALiteralConsts:TLiteralConsts;const ALiteralMode:TLiteralMode;const AOclUavTranslation:boolean):ansistring;

implementation

uses
  unsCal, UCalTables, het.MacroParser;

////////////////////////////////////////////////////////////////////////////////
///  Common Stuff                                                            ///
////////////////////////////////////////////////////////////////////////////////

function StripLiteralConsts(const APrg:ansistring;out ALiteralConsts:TLiteralConsts):ansistring;//remaining program
var fcc:AnsiString;
    sizeB:integer;
begin
  result:=APrg;
  ALiteralConsts:=nil;
  fcc:=FourCC(APrg);
  if(fcc=_ElfCB0Magic)and(Length(Result)>8)then begin
    SetLength(ALiteralConsts,pinteger(psucc(pointer(Result),4))^);
    sizeB:=Length(ALiteralConsts)*sizeof(TLiteralConst);
    if Length(result)>=8+sizeB then
      move(psucc(pointer(result),8)^,ALiteralConsts[0],sizeB)
    else
      raise Exception.Create('StripCB0Literals() Corrupt CB0 LiteralConsts data');
    result:=copy(result,8+sizeB+1);
  end;
end;

procedure ApplyLiteralConsts(const ADst:pointer;const ALiteralConsts:TLiteralConsts);
var i:integer;
begin
  for i:=0 to high(ALiteralConsts)do with ALiteralConsts[i]do
    system.move(value,psucc(ADst,id shl 4)^,16);
end;

procedure DebugFileWrite(const fn:string;const data:rawbytestring);
begin
  {$IFDEF DEBUGFILES}
    TFile(_DebugFilePath+fn).Write(data);
  {$ENDIF}
end;

type
  TRegType=(regAlias,regR,regV,regS);
  TAliasRec=record
    regType:TRegType;
    name,nameprefix,value:ansistring;

    //when regType<>regAlias
    ScopeLevel:integer;
    regIndex:integer;
  end;

  TAliases=class
  strict private
    ActScope:integer;
    Items:TArray<TAliasRec>;
    FreeTemps:array[TRegType]of set of byte;
    procedure AddAlias(const AName,AValue:ansistring);
    procedure AddTemp(const AName,AValue:ansistring;const ARegType:TRegType;const ARegIndex:integer);
    procedure DeleteByIdx(const idx:integer);
    procedure DeleteByName(const AName:ansistring);
    procedure Error(const s:ansistring);
    function IdxByName(const name:ansistring):integer;
  public
    typ:(isa,il);//must be initialized
    procedure DeclareAlias(const decl:ansistring);
    procedure DeclareTempRange(const rt:TRegType; const ARng:TArray<AnsiString>);
    procedure DeclareTemp(const rt:TRegType; const AName:ansistring; const AAlign:integer=1);
    procedure EnterTempScope;
    procedure LeaveTempScope;
    function Resolve(const s:ansistring;const excludelevel:integer=maxint):ansistring;
    procedure CheckFinalScope;
  end;

procedure TAliases.Error;begin raise Exception.Create(s)end;

function TAliases.IdxByName(const name:ansistring):integer;
var i:integer;
begin
  for i:=high(Items)downto 0 do if cmp(Items[i].name,name)=0 then exit(i);
  result:=-1;
end;

function IsArrayDecl(const decl:ansistring;out name:ansistring;out st,en:integer):boolean;
var s0,s1,s2:ansistring;
begin
  result:=true;
  if iswild2('*[*..*]',decl,s2,s0,s1)then begin   //x[0..3]
    name:=s2;
    st:=StrToIntDef(s0,-1);
    en:=StrToIntDef(s1,-1);
  end else if iswild2('*[*]',decl,s2,s0)then begin         //x[4]  //c style
    name:=s2;
    st:=0;
    en:=StrToIntDef(s0,-1)-1;
  end else if iswild2('*..*',decl,s0,s1)then begin               //x0..3  //kinda lame
    s2:='';
    while charn(s0,length(s0))in['0'..'9']do begin
      s2:=s0[length(s0)]+s2;
      setlength(s0,length(s0)-1);
    end;
    name:=s0;
    st:=StrToIntDef(s2,-1);
    en:=StrToIntDef(s1,-1);
  end else
    result:=false;

  if result then begin
    if not IsIdentifier(name)or(st<0)or(en<0)or(st>en)then raise Exception.Create('Invalid array declaration "'+decl+'"');
  end else begin
    if not IsIdentifier(decl)then raise Exception.Create('Invalid declaration "'+decl+'"');
  end;
end;

procedure TAliases.AddAlias(const AName,AValue:ansistring);
var s:ansistring;
begin
  DeleteByName(AName);

  SetLength(Items,length(Items)+1);
  with Items[high(Items)]do begin
    regType:=regAlias;
    name:=AName;
    value:=AValue;
    regIndex:=-1;
    ScopeLevel:=-1;

    s:=AName; while charn(s,length(s))in['0'..'9']do setlength(s,length(s)-1); nameprefix:=s;
  end;
end;

procedure TAliases.AddTemp(const AName,AValue:ansistring;const ARegType:TRegType;const ARegIndex:integer);
var i:integer;
    s:ansistring;
begin
  for i:=0 to high(Items)do with Items[i]do
    if(regType=ARegType)and(ActScope=ScopeLevel)and(Cmp(name,AName)=0)then
      Error('TAliases.AddTemp(), name "'+AName+'" is alreade allocated');

  SetLength(Items,length(Items)+1);
  with Items[high(Items)]do begin
    regType:=ARegType;
    name:=AName;
    value:=AValue;
    regIndex:=ARegIndex;
    ScopeLevel:=ActScope;

    s:=AName; while charn(s,length(s))in['0'..'9']do setlength(s,length(s)-1); nameprefix:=s;
  end;
end;

procedure TAliases.DeleteByIdx(const idx:integer);
var i:integer;
begin
  if(idx>=0)and(idx<=high(items))then begin
    for i:=idx to high(Items)-1 do Items[i]:=Items[i+1];
    setlength(Items,high(Items));
  end;
end;

procedure TAliases.DeleteByName(const AName:ansistring);
begin
  DeleteByIdx(IdxByName(AName));
end;

procedure TAliases.DeclareAlias(const decl:ansistring);
var name,left,value:ansistring;
    i,st,en,j,k:integer;
    s0,s1:ansistring;

  procedure ErrorInvalidArrayReg;begin Error('Invalid register in array alias declaration "'+value+'"');end;

begin
  if listcount(decl,'=')<>2 then Error('(1)Invalid alias declaration "'+decl+'"');
  left:=lc(ListItem(decl,0,'='));
  value:=ListItem(decl,1,'=');
  if(left='')then Error('(2)Invalid alias declaration "'+decl+'"');

  if IsArrayDecl(left,name,st,en)then begin //alias array
    for i:=st to en do begin
      DeclareAlias(name+tostr(i)+'='+value);
      //advance value
      if value=''{delete} then begin
      end else if(typ=isa)and iswild2('s[*:*]',value,s0,s1)or iswild2('v[*:*]',value,s0,s1)then begin
        j:=strtointdef(s0,-1);if(j<0)or(j>255)then ErrorInvalidArrayReg;
        k:=strtointdef(s1,-1);if(k<j)or(k>255)then ErrorInvalidArrayReg;
        value:=format('%s[%d:%d]',[value[1],k+1,k+(k-j)+1]);
      end else if((typ=isa)and iswild2('s*',value,s0)or iswild2('v*',value,s0))
               or((typ=il) and iswild2('r*',value,s0))then begin
        j:=strtointdef(s0,-1);
        if(j<0)or(j>255)then ErrorInvalidArrayReg;
        value:=value[1]+tostr(j+1);
      end else
        ErrorInvalidArrayReg;
    end;
  end else begin
    name:=left;
    if value='' then DeleteByName(name)
                else AddAlias(name,value);
  end;
end;

procedure TAliases.DeclareTempRange(const rt:TRegType; const ARng:TArray<AnsiString>);

  function CheckRange(a,mi,ma:integer):integer;
  begin
    if not InRange(a,mi,ma)then
      raise Exception.Create('TAliases.DeclareTempRange() reg index out of range');
    result:=a;
  end;

var s,a,b:ansistring;
    i:integer;
begin
  FreeTemps[rt]:=[];
  try
    for s in ARng do begin
      if IsWild2('*..*',s,a,b)then begin
        for i:=CheckRange(StrToInt(a),0,255)to CheckRange(StrToInt(b),0,255)do
          Include(FreeTemps[rt],i);
      end else begin
        i:=CheckRange(StrToInt(s),0,255);
        Include(FreeTemps[rt],i);
      end;
    end;
  except
    on e:exception do raise Exception.Create('TAliases.DeclareTempRange() '+e.ClassName+' '+e.message);
  end;
end;

procedure TAliases.DeclareTemp(const rt:TRegType; const AName:ansistring; const AAlign:integer=1);

  procedure Error(s:ansistring);begin raise Exception.Create('TAliases.DeclareTemp('+GetEnumName(typeinfo(TRegType),ord(rt))+',"'+AName+'"): '+s);end;

  function AllocateReg(const rt:TRegType;const ASize,AAlign:integer):integer;
  var i,j:integer;
      found:boolean;
  begin
    if(AAlign and(AAlign-1))<>0 then Error(' Align must be power of 2 instead of ('+tostr(AAlign)+')');
    for i:=0 to 255 do if((i and(AAlign-1))=0)then begin
      found:=true;
      for j:=0 to ASize-1 do if not((i+j)in FreeTemps[rt])then begin found:=false;break end;
      if found then begin
        for j:=0 to ASize-1 do Exclude(FreeTemps[rt],i+j);
        exit(i);
      end;
    end;
    result:=-1;
    Error('Out of temp range, cannot allocate.');
  end;

var i,rid,st,en:integer;
    n,rn:AnsiString;
begin
  case rt of regR:rn:='r';regS:rn:='s';regV:rn:='v';else rn:='?' end;
  if IsArrayDecl(AName,n,st,en)then begin
    rid:=AllocateReg(rt,1*(en-st+1),AAlign);
    for i:=st to en do begin
      AddTemp(n+tostr(i),rn+tostr(rid),rt,rid);
      inc(rid,1);
    end;
  end else begin
    rid:=AllocateReg(rt,1,AAlign);
    AddTemp(AName,rn+tostr(rid),rt,rid);
  end;
end;

procedure TAliases.EnterTempScope;
begin
  inc(ActScope);
end;

procedure TAliases.LeaveTempScope;
var i:integer;
begin
  if ActScope<=0 then
    raise Exception.Create('No temp scope to leave from. (There must be more "leave" than "enter" instructions.)');

  for i:=high(Items)downto 0 do with Items[i]do if(regType<>regAlias)and(ScopeLevel=ActScope)then begin
    if regIndex in FreeTemps[regType]then raise Exception.Create('TAliases.LeaveTempScope() Temp consistency error');
    include(FreeTemps[regType],regIndex);
    DeleteByIdx(i);
  end;

  dec(ActScope);
end;


function TAliases.Resolve(const s:ansistring;const excludelevel:integer=maxint):ansistring;//ha tudja, csinalja, ha nem, akkor visszaadja
var i:integer;
    s1,s2:ansistring;
begin
  // x[12+3] -> x15
  //!!!!!!todo: az indexedet belsoleg kezelni, hogy lehessen x0[0] is.
  if IsWild2('*[*]',s,s1,s2)then begin
    for i:=high(Items) downto 0 do if cmp(Items[i].nameprefix,s1)=0 then begin
      try s1:=s1+tostr(Eval(s2));except exit(s);end;
      exit(Resolve(s1,excludelevel));
    end;
    result:=s;
  end else begin
    i:=IdxByName(s);
    if i>=0 then result:=Items[i].value
            else result:=s;
  end;
end;

procedure TAliases.CheckFinalScope;
begin
  if ActScope<>0 then
    Error('TempReg scope consistency error: ActScope was '+tostr(ActScope)+' at end.');
end;

////////////////////////////////////////////////////////////////////////////////
///  AMD_IL Precompiler                                                      ///
////////////////////////////////////////////////////////////////////////////////

function IsConstantInitialization(const line:ansistring):boolean;
begin
  result:=(copy(line,1,5)=';cb0[')and(pos(']:=(',line)>0);
end;

procedure AddConstantInitialization(var ALiteralConsts:TLiteralConsts;const line:ansistring);
var c:TLiteralConst;i:integer;s:ansistring;
begin
  if not TryStrToInt(FindBetween(line,'[',']'),c.id) then exit;

  s:=FindBetween(line,'(',')');
  for i:=0 to high(c.value) do
    if not TryStrToInt(listitem(s,i,','),c.value[i])then exit;

  setlength(ALiteralConsts,length(ALiteralConsts)+1);
  ALiteralConsts[high(ALiteralConsts)]:=c;
end;

function LiteralConstsToStr(const ALiteralConsts:TLiteralConsts):rawbytestring;
begin
  if ALiteralConsts<>nil then begin
    result:=_ElfCB0Magic+FourCC(length(ALiteralConsts))
           +DataToStr(ALiteralConsts[0],length(ALiteralConsts)*sizeof(TLiteralConst));
  end else
    result:='';
end;

function ValidILSwizzle(const swz:ansistring):boolean;
var a,b:boolean;
    i:integer;
begin
  result:=false;
  if(length(swz)in[2..5])and(swz[1]='.')then begin
    a:=true;b:=true;
    for i:=2 to length(swz)do begin
      a:=a and(swz[i]in['x','y','z','w','X','Y','Z','W','0','1','_']);
      b:=b and(swz[i]in['r','g','b','a','R','G','B','A','0','1','_']);
    end;
    if a or b then result:=true;{all ok}
  end;
end;

function ValidILReg(const reg:ansistring;const isarray:boolean):boolean;
var indexed:boolean;
    r:ansistring;
    i:integer;
begin
  result:=false;

  if(Cmp(reg,'a0')=0)and not isArray then exit(true);//address reg 'a0'

  r:=reg;
  indexed:=false;
  while CharN(r,length(r))in['0'..'9']do begin
    indexed:=true;
    while r[length(r)]in['0'..'9']do
      setlength(r,length(r)-1);
  end;
  if indexed then r:=r+'#';
  if isarray then r:=r+'[]';

  for i:=0 to high(ILRegisterList)do if cmp(r,ILRegisterList[i].name)=0 then exit(true);

  r:=reg;
  if charn(r,length(r))='0' then begin //vAbsTid0 (with 0 index)
    setlength(r,length(r)-1);
    for i:=0 to high(ILRegisterList)do if cmp(r,ILRegisterList[i].name)=0 then exit(true);
  end;
end;

function IL_Syntax(const AIdentifier:ansistring):TSyntaxKind;
var s,m:ansistring;
    instr:PILInstrRec;
    i:integer;
begin
  if ValidILSwizzle(AIdentifier)then exit(skIdentifier3); //swz begins with .
  if ValidILReg(AIdentifier,false)or ValidILReg(AIdentifier,true)then exit(skIdentifier3);
  if FindBinStrArray(ILOptionNameList,AIdentifier)>=0 then exit(skIdentifier2);//option

  s:=AIdentifier;
  while s<>'' do begin
    instr:=ILInstrByName(s);
    if instr<>nil then exit(skIdentifier4);//it's an instruction
    //get last modifier
    i:=pos('_',s,[poBackwards],length(s));
    if i=0 then break;
    m:=copy(s,i+1);setlength(s,i-1);
    if FindBinStrArray(ILModifierNameList,m)<0 then exit(skError);//wrong modifier
  end;
  result:=skIdentifier1;
end;

function PreCompileIL(const AKernel:ansistring;const ATarget:CALtarget;Out ALiteralConsts:TLiteralConsts;const ALiteralMode:TLiteralMode;const AOclUavTranslation:boolean):ansistring;
//replaces some instructions according to current hardware (especially vect_sel)
//LiteralConst -> auto replace literals with constants in cb0

//120213: LiteralConst: ez generalja is azokat a beagyazott konstansokbol
//   beagyazott konstans:  mov r0,(1,2.4,0.5L) ->
//   mov r0,cb0[34]   ;cb0[34]:=(1,2.4,0x43243,0x432432) (double const a vegen)

  var targetSeries:integer;

  const LiteralBase=9900;
  var   LiteralsAsCB:boolean;

  type TLiteral=array[0..3]of cardinal;

  var literals:array of array of cardinal;

      LiteralCBName:ansistring;
      LiteralCBLength:integer;
      ProgramType:ansistring;  //ebbol a kettobol all ossze a header

  function LiteralFromStr(const list:ansistring):TLiteral;
  var i:integer;
      s:ansistring;
      f:single;
      d:cardinal;
  begin
    fillchar(result,sizeof(result),0);
    i:=0;for s in listsplit(list,',')do begin
      if(pos('.',s,[])>0)or(pos('e-',s,[poIgnoreCase])>0)then begin
        f:=strtofloat(s);
        d:=PCardinal(@f)^;
      end else begin
        d:=cardinal(StrToInt64(s));
      end;

      result[i]:=d;

      inc(i);if i>=4 then break;
    end;
  end;

  function getLiteralReg(const len:integer;const L:TLiteral):ansistring;
  const aswz:array[0..3]of ansichar='xyzw';
  var i,j,k,newLen:integer;
      swz:ansistring;
  begin
    result:='';
    //find
    for i:=0 to high(literals)do begin
      swz:='';
      for k:=0 to len-1 do begin
        for j:=0 to high(literals[i])do if literals[i,j]=L[k]then begin
          swz:=swz+aswz[j];break
        end;
      end;
      if length(swz)=len then begin//gotcha
        if literalsAsCB then result:=LiteralCBName+'['+tostr(i+LiteralCBLength)+'].'+swz
                        else result:='l'+tostr(literalBase-i)+'.'+swz;
        exit;
      end;
    end;

    //append   lame version
    for i:=0 to high(literals)do begin
      newLen:=Length(literals[i])+len;
      if newLen<=4 then begin
        for j:=0 to len-1 do begin
          SetLength(literals[i],length(literals[i])+1);
          literals[i,high(literals[i])]:=L[j];
        end;
        exit(getLiteralReg(len,L));
      end;
    end;

    i:=Length(literals);
    setlength(literals,i+1);
    setlength(Literals[i],len);
    for j:=0 to len-1 do Literals[i,j]:=L[j];
    exit(getLiteralReg(len,L));
  end;

  var LineIdx:integer;
      Aliases:TAliases;

  function ProcessLine(const line:ansistring):ansistring;

    procedure Error(const s:ansistring);
    begin
      raise Exception.Create('IL_Precompile Error (line:'+tostr(LineIdx+1)+'): '+s);
    end;

    function FindMultiMod(var ch:pansichar;var modName:ansistring):TILModifierEnum;

      function check(ch:pansichar;const s:ansistring):boolean;
      var c2:ansichar;
      begin
        for c2 in s do begin
          if ch[0]=#0 then exit(false);
          if c2<>LC(ch[0]) then exit(false) else inc(ch);
        end;
        result:=not(ch[0] in['a'..'z','A'..'Z','0'..'9']);
      end;

    var m:TILModifierEnum;
        mop:ansistring;
    begin
      //not in list
      for m in[low(ILModifierList)..high(ILModifierList)]do with ILModifierList[m]do
        if multiMod<>'' then for mop in ListSplit(multiMod,',')do
          if check(ch,mop)then begin
            inc(ch,length(mop)); //got multiModifier
            modName:=mop;
            exit(m);
          end;
      result:=TILModifierEnum(-1);
    end;

    function ParseEncapsulation(var ch:pansichar;const cBegin,cEnd:ansichar):ansistring;
    var bcnt:integer;
        chStart:PAnsiChar;
    begin
      result:='';
      if ch[0]<>cBegin then exit;
      inc(ch);bcnt:=1;
      chStart:=ch;
      while true do begin
        if ch[0]=#0     then break else
        if ch[0]=cBegin then inc(bcnt)else
        if ch[0]=cEnd   then dec(bcnt);
        inc(ch);
        if bcnt=0 then exit(StrMake(chStart,ppred(ch)));//gotcha
      end;
      raise Exception.Create('"'+cEnd+'" expected');
    end;

    procedure CheckOperand(const o:AnsiString;const IntegerAllowed:boolean);

      procedure Error(s:string);begin raise Exception.Create('Operand syntax error: '+s);end;

      procedure CheckILSwizzle(const swz:ansistring);
      begin
        if not ValidILSwizzle(swz)then
          Error('Invalid swizzle "'+swz+'"');
      end;

      procedure CheckILReg(const reg:ansistring;isarray:boolean);
      begin
        if not ValidILReg(reg,isarray)then
          Error('invalid register name "'+Reg+'"');
      end;

    var r,oidx,swz:ansistring;
    begin
      if IntegerAllowed and(charn(o,1)in['0'..'9','+','-','$'])then exit;//for declarations

      if IsWild2('*[*]*',o,r,oidx,swz)then begin
        if swz<>'' then CheckILSwizzle(swz);
        CheckOperand(oidx,true{index can be numeric});
        CheckILReg(r,true);
      end else if isWild2('*.*',o,r,swz)then begin
        CheckILSwizzle('.'+swz);
        CheckILReg(r,false);
      end else begin
        checkILReg(o,false);
      end;
    end;

    procedure CheckIntOperand(const o:AnsiString);
    var i:integer;
    begin
      if not TryStrToInt(o,i)then
        Error('Invalid integer constant "'+o+'"');
    end;

  var ch,chSt:PAnsiChar;
      s,s2,modName,wholeinstr:ansistring;
      Instr:PILInstrRec;
      Mods:TILModifierSet;
      m:TILModifierEnum;
      valid:boolean;
      ops:TArray<ansistring>;
      i,j:integer;
      fl:single;
      bracketcnt:integer;

    procedure OptionError(const err:ansistring);
    begin error(format('Invalid modifier option %s_%s #%d. %s',[instr.name,modname,i,err]));end;

    procedure AppendOperand;
    begin setlength(ops,length(ops)+1);ops[high(ops)]:=trimf(StrMake(chSt,ch));chSt:=psucc(ch);end;

  begin
    if line='' then exit('');//empty line
    ch:=pointer(line);
    result:='';

    //skip white
    ParseSkipWhiteSpace(ch);
    if ParseIdentifier(ch,s)then begin
      //search for instr
      s2:=s;
      repeat
        Instr:=ILInstrByName(s2);
        if Instr<>nil then begin//found the instruction
          pDec(ch,length(s)-length(s2));
          break;
        end;
        setlength(s2,pos('_',s2,[poBackwards])-1);
      until s2='';
      if Instr=nil then error('unknown instruction "'+s+'"');

      //alias declaration
      if(Instr.cat=icDcl)and(Instr.name='alias')then begin
        for s in listsplit(copy(line,7),',')do aliases.DeclareAlias(s);
        exit;
      end;

      //todo: get instruction parameter (mcall(n))
      if ch[0]='(' then begin
        inc(ch);
        if not(opIdx in Instr.flags)then
          Error('Instruction index (eg. mdef(123)) is not allowed for "'+s+'"');

        ParsePascalConstant(ch);//skip the index
        ParseSkipWhiteSpace(ch);

        if ch[0]<>')' then
          error('Instruction index (eg. mdef(123)) has wrong syntax');
        inc(ch);
      end;

      //get modifiers
      mods:=[];
      while ch[0]='_' do begin
        //extract modifier without _
        inc(ch);chSt:=ch;
        while ch[0]in['a'..'z','A'..'Z','0'..'9']do inc(ch);
        s:=StrMake(chst,ch);

        //find modifier in table
        m:=ILModifierByName(s);        modName:=s;
        if ord(m)<0 then begin ch:=chst;m:=FindmultiMod(ch,modName);end; //not in list, find as multiMod
        if ord(m)<0 then Error('Unknown modifier ('+Instr.name+')_'+modName);

        //used already?
        if m in Mods then Error('Modifier already used ('+Instr.name+')_'+modName);

        //check instruction+modifier validity
        valid:=(m in Instr.mods);
        valid:=valid or((Instr.cat in[icFloat,icDouble])and(dstmod in ILModifierList[m].flags));
        if not valid then Error('Invalid instruction modifier '+Instr.name+'_'+modName);

        //check options
        with ILModifierList[m]do begin
          ops:=ListSplit(ParseEncapsulation(ch,'(',')'),',');
          //check optionCount
          if optionCnt<>length(ops)then error(format('Option count mismatch. %s_%s requires:%d got:%d',
                                                    [Instr.name,modName,length(ops),optionCnt]));
          //check each optionformat
          s:=ILModifierList[m].optionFmt;
          for i:=0 to high(ops)do begin
            if s='#' then begin
              if not TryStrToInt(ops[i],j)then
                optionError('Integer value required.');
            end else if s='#.#' then begin
              if not TryStrToFloat(ops[i],fl)then
                optionError('Float value required.');
            end else begin//option list
              valid:=false;
              for s2 in ListSplit(s,',')do
                if cmp(s2,ops[i])=0 then begin valid:=true;break end;
              if not valid then
                optionError('Invalid modifier option "'+ops[i]+'". Valid options are ('+optionFmt+')');
            end;
          end;
        end;

        //insert into Mods
        Include(Mods,m);
      end;

      //check required modifiers
      s:='';
      for m in Instr.mods do
        if not(m in Mods)and(req in ILModifierList[m].flags)then
          ListAppend(s,ILModifierList[m].name,', ');
      if s<>'' then
        Error('Insufficient instruction modifiers: '+Instr.name+' requires '+s);

      wholeinstr:=trimF(StrMake(pointer(line),ch));

      //get operands -----------------------------------------------------------
      SetLength(ops,0);
      ParseSkipWhiteSpace(ch);
      chSt:=ch;bracketcnt:=0;
      while true do begin
        case ch[0] of
          '(':inc(bracketcnt);
          ')':dec(bracketcnt);
          ',':if bracketcnt=0 then AppendOperand;
          #0,';':begin
            AppendOperand;
            break;
          end;
        end;
        inc(ch);
      end;
      if(length(ops)=1)and(ops[0]='')then setlength(ops,0);//only whitespace

      if(Instr.ops>=0)and(Instr.ops<>Length(ops))then
        Error(format('Operand count mismatch. Required:%d got:%d',[Instr.ops,Length(ops)]));

      //////////////////////////////////////////////////////////////////////////
      /// custom preprocessing                                               ///
      //////////////////////////////////////////////////////////////////////////

      //resolve aliases
      for i:=0 to high(ops)do ops[i]:=Aliases.Resolve(ops[i]);

      //get program type
      if(Instr.cat=icDcl)and IsWild2('il_?s_?_?',wholeinstr)then begin
        programType:=wholeinstr;
        wholeinstr:=wholeinstr+#1{mark it};ops:=nil;
      end;

      //get cb0 size
      if LiteralsAsCB and(cmp(wholeinstr,'dcl_cb')=0)then
        if IsWild2(LiteralCBName+'[*]',ops[0],s)then begin
          LiteralCBLength:=StrToInt(s);
          wholeinstr:='';ops:=nil;
        end;

      //replace immediate consts with lit or cb
      if Instr.cat in[icFlow,icFloat,icDouble,icInt,icI64]then begin
        for i:=1 to high(ops)do begin
          if CharN(ops[i],1)in['0'..'9','+','-','$']then
            ops[i]:=getLiteralReg(1,LiteralFromStr(ops[i]));
        end;
      end;

      //check all operands
      if[op1int,op2int]>=Instr.flags then begin
        for i:=0 to high(ops)do
          if((i=0)and(op1int in Instr.flags))
          or((i=1)and(op2int in Instr.flags))then
            CheckIntOperand(ops[i])
          else
            CheckOperand(ops[i],Instr.cat in[icDcl]);
      end else
        for s in ops do CheckOperand(s,Instr.cat in[icDcl]);//fogjuk r·... igazan nagy baromsagokat azert kivÈd

      //OpenCL UAV id translation
      if AOclUavTranslation then begin
        if(_id in Instr.mods) then
        if(Instr.cat=icUAV)or((Instr.cat=icDcl)and(Pos('uav',Instr.name,[poIgnoreCase])>0))then
        if strtointdef(FindBetween(wholeinstr,'_id(',')'),0)=0 then
          case targetSeries of
            5,6:ReplaceBetween(wholeinstr,'_id(',')','11'); //5xxx,6xxx -> uav_id(11)
            7  :ReplaceBetween(wholeinstr,'_id(',')','10'); //7xxx      -> uav_id(10)
          end;
      end;

    end;//instruction parser ///////////////////////////////////////////////////

    ParseSkipWhiteSpace(ch);
    if not(ch[0]in[';'{comment},#0])then
      error('Unexpected additional garbage "'+ch+'"');

    //assembre final instr
    result:=wholeinstr;
    for i:=0 to high(ops)do begin
      if i>0 then result:=result+',';
      result:=result+' '+ops[i];
    end;
  end;

  function getInstr(const line:ansistring):ansistring;
  begin result:=ListItem(ListItem(line,0,';'),0,' ')end;

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

  function GenerateLiterals:ansistring;
  var i,j:integer;
      s:ansistring;
      buf:ansistring;
  begin with AnsiStringBuilder(result,true)do begin
    for i:=0 to high(literals)do begin
      if literalsAsCB then begin
        s:=';'+LiteralCBName+'['+tostr(i+LiteralCBLength)+']:=(';
        for j:=0 to 3 do begin
          if j>0 then s:=s+',';
          s:=s+'$'+inttohex(literals[i,min(j,high(literals[i]))],1);
        end;
        s:=s+');';
        buf:=buf+s+#13#10;
        AddConstantInitialization(ALiteralConsts,s);
      end else begin
        s:='dcl_literal l'+tostr(literalBase-i);
        for j:=0 to 3 do s:=s+',0x'+inttohex(literals[i,min(j,high(literals[i]))],1);
        AddLine(s);
      end;
    end;

    DebugFileWrite('cbLiterals.txt',buf);
    DebugFileWrite('cbLiterals.dat',LiteralConstsToStr(ALiteralConsts));
  end;end;

  const
    LiteralDefs='dcl_literal l9999,0,8,16,24';

    //target szerint csokkeno sorrendben,
    //minden lowercase!!!!
    //tempek swizzleje a d-bol jon

    //bit,byte align is not compatible with 5xxx when emulated on 4xxx
    Patches:array[0..33]of record target:byte;instr:ansistring;expand:ansistring end=(
{az uj driver szarsagai:
  - f_2_u4 szar
  - umin3 szinten rosszul szamol, vagy nem ugy, ahogy a nevebol kovetkeztetnem :S}
      (target:7;instr:'vec_sel'  ;expand:'bfi d,s2,s1,s0'),

      (target:7;instr:'umax3';expand:'umax t0,s0,s1;umax d,t0,s2'),//7xxx-en is... vagy en neztem be ezeket nagyon
      (target:7;instr:'umin3';expand:'umin t0,s0,s1;umin d,t0,s2'),
      (target:7;instr:'imax3';expand:'imax t0,s0,s1;imax d,t0,s2'),
      (target:7;instr:'imin3';expand:'imin t0,s0,s1;imin d,t0,s2'),

      (target:7;instr:'f_2_u4';expand:'ftoi r9999,s0;ishl r9999,r9999,l9999;ior r9999.xy,r9999.xy,r9999.zw;ior d,r9999.x,r9999.y'),

      (target:6;instr:'vec_sel'  ;expand:'bfi d,s2,s1,s0'),
      (target:6;instr:'f_2_u4';expand:'ftoi r9999,s0;ishl r9999,r9999,l9999;ior r9999.xy,r9999.xy,r9999.zw;ior d,r9999.x,r9999.y'),

      (target:6;instr:'umax3';expand:'umax t0,s0,s1;umax d,t0,s2'),//ezek 5xxx-en bugzanak
      (target:6;instr:'umin3';expand:'umin t0,s0,s1;umin d,t0,s2'),
      (target:6;instr:'imax3';expand:'imax t0,s0,s1;imax d,t0,s2'),
      (target:6;instr:'imin3';expand:'imin t0,s0,s1;imin d,t0,s2'),

      (target:5;instr:'vec_sel'  ;expand:'bfi d,s2,s1,s0'),
      (target:5;instr:'f_2_u4';expand:'ftoi r9999,s0;ishl r9999,r9999,l9999;ior r9999.xy,r9999.xy,r9999.zw;ior d,r9999.x,r9999.y'),

      (target:5;instr:'umax3';expand:'umax t0,s0,s1;umax d,t0,s2'),//ezek 5xxx-en bugzanak
      (target:5;instr:'umin3';expand:'umin t0,s0,s1;umin d,t0,s2'),
      (target:5;instr:'imax3';expand:'imax t0,s0,s1;imax d,t0,s2'),
      (target:5;instr:'imin3';expand:'imin t0,s0,s1;imin d,t0,s2'),

      (target:5;instr:'imad24';expand:'imul t0,s0,s1;iadd d,t0,s2'),

      (target:4;instr:'bytealign' ;expand:'iadd t2,s2,s2;iadd t2,t2,t2;iadd t2,t2,t2;ushr t1,s1,t2;inegate t2,t2;ishl t0,s0,t2;ior d,t1,t0'),
      (target:4;instr:'bitalign' ;expand:'ushr t1,s1,s2;inegate t2,s2;ishl t0,s0,t2;ior d,t1,t0'),
      (target:4;instr:'vec_sel'  ;expand:'iand t1,s1,s2;inot t2,s2;iand t0,s0,t2;ior d,t0,t1'),
      (target:4;instr:'f_2_u4';expand:'ftoi r9999,s0;ishl r9999,r9999,l9999;ior r9999.xy,r9999.xy,r9999.zw;ior d,r9999.x,r9999.y'),
      (target:4;instr:'umax3';expand:'umax t0,s0,s1;umax d,t0,s2'),
      (target:4;instr:'umin3';expand:'umin t0,s0,s1;umin d,t0,s2'),
      (target:4;instr:'imax3';expand:'imax t0,s0,s1;imax d,t0,s2'),
      (target:4;instr:'imin3';expand:'imin t0,s0,s1;imin d,t0,s2'),

      //nonexact 4xxx simulated things
      (target:4;instr:'umul24';expand:'umul d,s0,s1'),
      (target:4;instr:'imul24';expand:'imul d,s0,s1'),
      (target:4;instr:'umul24_high';expand:'umul_high d,s0,s1'),
      (target:4;instr:'imul24_high';expand:'imul_high d,s0,s1'),
      (target:4;instr:'umad24';expand:'umul t0,s0,s1;iadd d,t0,s2'),
      (target:4;instr:'imad24';expand:'imul t0,s0,s1;iadd d,t0,s2'),

      //non atomic!!! //fence_memory if-ben nem lehet  //d:dest s0: addr of idx, s1:increment
      (target:4;instr:'uav_read_add_id(0)';expand:'uav_raw_load_id(0) d, s0;iadd t0, d, s1;uav_raw_store_id(0) mem.x, s0, t0')

    );
    ParamNames:array[0..3]of ansistring=('d','s0','s1','s2');
    TempNames :array[0..2]of ansistring=(    't0','t1','t2');

    TempBase=9900;
    TempCount=8;

var {doPatch:boolean;}
    s,s2,line,ins,swz,tempreg:ansistring;
    params:TArray<ansistring>;
    i,j,TempOffset:integer;
    LiteralsAdded:boolean;
    sb:IAnsiStringBuilder;

begin
  DebugFileWrite('before_Precomp.il',AKernel);

  LiteralsAsCB:=ALiteralMode in [lmCB0, lmCB2];
  case ALiteralMode of
    lmCB0:LiteralCBName:='cb0';
    lmCB2:LiteralCBName:='cb2';
  end;
  LiteralsAdded:=false;
  LiteralCBlength:=0;

  programType:='';
  Aliases:=TAliases.Create; AutoFree(Aliases); Aliases.typ:=il;
  setlength(ALiteralConsts,0);
  if Akernel='' then exit(AKernel);

  //major card version
  targetSeries:=CALTargetSeries[ATarget];

  TempOffset:=0;
  for i:=TempOffset to TempOffset+TempCount-1 do
    if isthere('r'+tostr(TempBase+i))then
      raise Exception.Create('CAL compiler pre-pass: Temp register range already used (r'+toStr(TempBase)+'..r'+tostr(TempBase+TempCount-1)+')');

  LineIdx:=0;
  sb:=AnsiStringBuilder(result,true);
  with sb do for line in ListSplit(AKernel,#10)do begin
    inc(LineIdx);

    ins:=lc(getInstr(line));

    j:=-1;for i:=0 to high(Patches)do with Patches[i]do if(targetSeries=target)and(ins=instr)then begin
      j:=i;break end;

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

      for s2 in ListSplit(s,';')do
        AddLine(ProcessLine(s2));
    end else if(ins='')and IsConstantInitialization(line)then begin
      AddConstantInitialization(ALiteralConsts,line);
    end else begin
      AddLine(ProcessLine(line));
    end;
  end;
  sb:=nil;//finalize stringbuilder

  Aliases.CheckFinalScope;

  if ProgramType='' then
    raise Exception.Create('CAL compiler pre-pass: "il_?s_?_?" not found in kernel.');

  //create initialization stuff
  s:='';
  if LiteralsAsCB then begin
    i:=LiteralCBLength+length(literals);
    s:=s+'dcl_cb '+LiteralCBName+'['+tostr(i)+'] ; OriginalLength='+tostr(LiteralCBLength)+#13#10;
  end;
  s:=s+GenerateLiterals;

  //insert initialization right after il_cs_2_0
  if s<>'' then
    replace(#1,#13#10+s,result,[]);

  DebugFileWrite('after_Precomp.il',result);
end;

////////////////////////////////////////////////////////////////////////////////
///  ELF functions                                                           ///
////////////////////////////////////////////////////////////////////////////////

function TElfProg.Dump:ansistring;
begin
  result:=Format('%9x%9x%9x%9x%9x%9x%9x%3x%3x',[type_,offset,vaddr,paddr,filesiz,offset+filesiz,memsiz,flags,align]);
end;

function TElfSect.Dump:ansistring;
begin
  result:=Format('%3x%3x%3x%9x%9x%9x%9x%3x%3x%3x%5x',[name,type_,flags,addr,offset,size,offset+size,link,info,align,entsize]);
end;

function TElfHdr.shdr(const idx:integer):PElfSect;
begin
  if not InRange(idx,0,shdrcnt-1)then exit(nil);
  result:=PElfSect(integer(@self)+shdrpos+shdrent*idx);
end;

function TElfHdr.SectionIdxByName(const AName:ansistring;const ErrorIfNotFound:boolean=false):integer;
var i:integer;
begin
  for i:=0 to shdrcnt-1 do
    if cmp(shdrName(i),AName)=0 then exit(i);
  result:=-1;
  if ErrorIfNotFound then
    raise Exception.Create('Section "'+AName+'" not found in ELF image.');
end;

function TElfHdr.SectionContents(const idx:integer):ansistring;
var h:PElfSect;
begin
  h:=shdr(idx);if h=nil then exit('');
  setlength(result,h.size);
  move(pointer(integer(@self)+h.offset)^,pointer(result)^,h.size);
end;

function TElfHdr.SectionData(const idx:integer):pointer;
var h:PElfSect;
begin
  h:=shdr(idx);if h=nil then exit(nil);
  result:=psucc(@self,h.offset);
end;

function TElfHdr.ProgramData(const idx:integer):pointer;
var h:PElfProg;
begin
  h:=phdr(idx);if h=nil then exit(nil);
  result:=psucc(@self,h.offset);
end;

procedure TElfHdr.SetSectionContents(const Idx:integer;const value:ansistring;out _res:ansistring);
var i,j,delta,st,en,siz:integer;
    src,dst:pointer;
    found:boolean;
    res:ansistring;
begin
  delta:=length(value)-length(SectionContents(idx));
  with shdr(idx)^do begin
    st:=offset;
    en:=offset+size;
  end;

  SetLength(res,FullSize+delta); fillchar(res[1],length(res),#0);

  //copy header
  move(Self,res[1],SizeOf(self));
  with PElfHdr(res)^ do begin  //adjust shdr, phdr positions
    if shdrpos>=en then inc(shdrpos,delta);
    if phdrpos>=en then inc(phdrpos,delta);
  end;

  //copy programs
  for i:=0 to phdrcnt-1 do begin
    move(phdr(i)^,PElfHdr(res).phdr(i)^,phdrent);
    j:=phdr(i)^.offset;
    if en<=j then inc(PElfHdr(res).phdr(i)^.offset,delta) else
    if InRange(st,j,j+phdr(i)^.filesiz-1)then begin
      inc(PElfHdr(res).phdr(i)^.filesiz,delta);
      if PElfHdr(res).phdr(i)^.memsiz>0 then
        inc(PElfHdr(res).phdr(i)^.memsiz,delta);
    end;

    src:=psucc(@self,phdr(i).offset);
    dst:=psucc(pointer(res),PElfHdr(res).phdr(i)^.offset);
    siz:=min(PElfHdr(res).phdr(i)^.filesiz,phdr(i)^.filesiz);
    move(src^,dst^,siz);
  end;

  //copy sections
  for i:=0 to shdrcnt-1 do begin
    //copy header
    move(shdr(i)^,PElfHdr(res).shdr(i)^,shdrent);
    if shdr(i)^.offset>=en then inc(PElfHdr(res).shdr(i)^.offset,delta) else
    if shdr(i)^.offset>=st then inc(PElfHdr(res).shdr(i)^.size,delta);
    //copy data
    if i=idx then src:=pointer(value)
             else src:=psucc(@self,shdr(i).offset);
    dst:=psucc(pointer(res),PElfHdr(res).shdr(i)^.offset);
    move(src^,dst^,PElfHdr(res).shdr(i)^.size);
  end;

  _res:=res;
end;

function TElfHdr.phdr(const idx:integer):PElfProg;
begin
  if not InRange(idx,0,phdrcnt-1)then exit(nil);
  result:=PElfProg(integer(@self)+phdrpos+phdrent*idx);
end;

function TElfHdr.phdrContents(const idx:integer):ansistring;
var h:PElfProg;
begin
  h:=phdr(idx);if h=nil then exit('');
  setlength(result,h.filesiz);
  move(pointer(integer(@self)+h.offset)^,pointer(result)^,h.filesiz);
end;

function TElfHdr.shdrName(const idx:integer):ansistring;
var h:PElfSect;
    names:ansistring;
    idx2,i,st,en:integer;
begin
  h:=shdr(idx);if h=nil then exit('');

  idx2:=h.name;

  names:=SectionContents(strsec);
  st:=idx2+1;
  for i:=st to length(names)do if names[i]=#0 then begin
    en:=i;
    exit(copy(names,st,en-st));
  end;
  result:='';
end;

const ElfIsaNotes:array[0..11]of record k:cardinal;n:string end=(
(k:$00002E13;n:'COMPUTE_PGM_RSRC2'),
(k:$80001041;n:'NumVgprs'),
(k:$80001042;n:'NumSgprs'),
(k:$80001043;n:'FloatMode'),
(k:$80001000;n:'userElementCount'),
{(k:$80001001;n:'userElement[0].type'),
(k:$80001002;n:'userElement[0].index'),
(k:$80001003;n:'userElement[0].SReg'),
(k:$80001004;n:'userElement[0].size'),//...}
(k:$80000081;n:'LDS Max bytes'),
(k:$80000082;n:'LDS Alloc bytes'),
(k:$80001045;n:'???'),
(k:$80000006;n:'NumThreadPerGroup'),
(k:$8000001C;n:'NumThreadPerGroup.X'),
(k:$8000001D;n:'NumThreadPerGroup.Y'),
(k:$8000001E;n:'NumThreadPerGroup.Z')
);

(*
typedef enum _E_SC_USER_DATA_CLASS
{

    IMM_RESOURCE,               // immediate resource descriptor
    IMM_SAMPLER,                // immediate sampler descriptor
    IMM_CONST_BUFFER,           // immediate const buffer descriptor
    IMM_VERTEX_BUFFER,          // immediate vertex buffer descriptor
    IMM_UAV,                    // immediate UAV descriptor
    IMM_ALU_FLOAT_CONST,        // immediate float const (scalar or vector)
    IMM_ALU_BOOL32_CONST,       // 32 immediate bools packed into a single UINT
    IMM_GDS_COUNTER_RANGE,      // immediate UINT with GDS address range for counters
    IMM_GDS_MEMORY_RANGE,       // immediate UINT with GDS address range for storage
    IMM_GWS_BASE,               // immediate UINT with GWS resource base offset
    IMM_WORK_ITEM_RANGE,        // immediate HSAIL work item range
    IMM_WORK_GROUP_RANGE,       // immediate HSAIL work group range
    IMM_DISPATCH_ID,            // immediate HSAIL dispatch ID
    IMM_SCRATCH_BUFFER,         // immediate HSAIL scratch buffer descriptor
    IMM_HEAP_BUFFER,            // immediate HSAIL heap buffer descriptor
    IMM_KERNEL_ARG,             // immediate HSAIL kernel argument
    IMM_CONTEXT_BASE,           // immediate HSAIL context base-address
    IMM_LDS_ESGS_SIZE,          // immediate LDS ESGS size used in on-chip GS
    SUB_PTR_FETCH_SHADER,       // fetch shader subroutine pointer
    PTR_RESOURCE_TABLE,         // flat/chunked resource table pointer

    /* PTR_CONST_BUFFER_TABLE Moved to position 20 */
    PTR_CONST_BUFFER_TABLE,     // flat/chunked const buffer table pointer

    PTR_INTERNAL_RESOURCE_TABLE,// flat/chunked internal resource table pointer
    PTR_SAMPLER_TABLE,          // flat/chunked sampler table pointer

    /* PTR_CONST_BUFFER_TABLE Was originally here at position 22 */

    /* PTR_UAV_TABLE Moved to position 23 */
    PTR_UAV_TABLE,              // flat/chunked UAV resource table pointer

    PTR_VERTEX_BUFFER_TABLE,    // flat/chunked vertex buffer table pointer
    PTR_SO_BUFFER_TABLE,        // flat/chunked stream-out buffer table pointer

    /* PTR_UAV_TABLE Was originally here at position 25 */

    PTR_INTERNAL_GLOBAL_TABLE,  // internal driver table pointer
    PTR_EXTENDED_USER_DATA,     // extended user data in video memory
    PTR_INDIRECT_RESOURCE,      // pointer to resource indirection table
    PTR_INDIRECT_INTERNAL_RESOURCE,// pointer to internal resource indirection table
    PTR_INDIRECT_UAV,           // pointer to UAV indirection table
    E_SC_USER_DATA_CLASS_LAST

} E_SC_USER_DATA_CLASS;

/* User Element entry */
struct si_bin_enc_user_element_t
{
	unsigned int dataClass;
	unsigned int apiSlot;
	unsigned int startUserReg;
	unsigned int userRegCount;
};

/* COMPUTE_PGM_RSRC2 */
struct si_bin_compute_pgm_rsrc2_t
{
	unsigned int scrach_en 		: 1;
	unsigned int user_sgpr 		: 5;
	unsigned int trap_present 	: 1;
	unsigned int tgid_x_en 		: 1;  [7]
	unsigned int tgid_y_en 		: 1;
	unsigned int tgid_z_en 		: 1;
	unsigned int tg_size_en 	: 1;
	unsigned int tidig_comp_cnt     : 2;
	unsigned int excp_en_msb 	: 2;
	unsigned int lds_size 		: 9;  [15:23]
	unsigned int excp_en 		: 7;
	unsigned int 		        : 1;
};
*)

const UserDataClassNames:array[0..30]of ansistring=(
    'IMM_RESOURCE',
    'IMM_SAMPLER',
    'IMM_CONST_BUFFER',
    'IMM_VERTEX_BUFFER',
    'IMM_UAV',
    'IMM_ALU_FLOAT_CONST',
    'IMM_ALU_BOOL32_CONST',
    'IMM_GDS_COUNTER_RANGE',
    'IMM_GDS_MEMORY_RANGE',
    'IMM_GWS_BASE',
    'IMM_WORK_ITEM_RANGE',
    'IMM_WORK_GROUP_RANGE',
    'IMM_DISPATCH_ID',
    'IMM_SCRATCH_BUFFER',
    'IMM_HEAP_BUFFER',
    'IMM_KERNEL_ARG',
    'IMM_CONTEXT_BASE',
    'IMM_LDS_ESGS_SIZE',
    'SUB_PTR_FETCH_SHADER',
    'PTR_RESOURCE_TABLE',
    'PTR_CONST_BUFFER_TABLE',
    'PTR_INTERNAL_RESOURCE_TABLE',
    'PTR_SAMPLER_TABLE',
    'PTR_UAV_TABLE',
    'PTR_VERTEX_BUFFER_TABLE',
    'PTR_SO_BUFFER_TABLE',
    'PTR_INTERNAL_GLOBAL_TABLE',
    'PTR_EXTENDED_USER_DATA',
    'PTR_INDIRECT_RESOURCE',
    'PTR_INDIRECT_INTERNAL_RESOURCE',
    'PTR_INDIRECT_UAV');

function TElfHdr.Dump;

  procedure DebugFileWrite(fn,s:ansistring);
  begin
    if fileprefix='' then exit;
    TFile(fileprefix+fn).Write(s);
  end;

  procedure w(const s:ansistring);begin result:=result+s end;procedure wln(const s:ansistring);begin w(s+#13#10)end;

  procedure DumpNotes(const data:ansistring);

    function notedump(const typ:integer;const data:ansistring):ansistring;
    var i,j,k:integer;
        key:cardinal;
        ElementCount:integer;
    begin
      ElementCount:=16;
      result:='';key:=0;
      for i:=0 to length(data)div 4-1do begin
        if(i>0)and((i and 1)=0)then
          result:=result+#13#10'                      ';
        j:=PInteger(psucc(pointer(data),i*4))^;
        result:=result+inttohex(j,8)+' ';
        if(i and 1)<>0 then result:=result+format('(%4d) ',[j]);

        //interpret notes
        if(i and 1)=0then key:=cardinal(j) else case typ of
          //isa notes
          $1:begin
            if key=$80001000 then
              ElementCount:=j;
            if(key>=$80001001)and(key<$80001001+cardinal(ElementCount)*4)then begin
              k:=key-$80001001;
              case k and 3 of
                0:begin
                    result:=result+'UserElement['+tostr(k div 4)+'] ';

                    case j of//user data class   //NOT HERE!!!!!!
                      2:result:=result+'IMM_CONST_BUFFER';
                      4:result:=result+'IMM_UAV';
                      20:result:=result+'PTR_CONST_BUFFER_TABLE';
                      23:result:=result+'PTR_UAV_TABLE';
                      else result:=result+'???';
                    end;

                    if Inrange(j,0,high(UserDataClassNames))then
                      result:=result+UserDataClassNames[j]
                    else
                      result:=result+'?'+tostr(j);
                  end;
                1:result:=result+'  apiSliot';
                2:result:=result+'  startUserReg';
                3:result:=result+'  userRegCount';
              end;
            end;
            for j:=0 to high(ElfIsaNotes)do with ElfIsaNotes[j]do
              if k=cardinal(key)then Result:=result+n;
          end;
          //CB sizes
          $A:result:=result+'dcl cb'+tostr(key)+'['+tostr(j)+']';
        end;
        //key name
      end;
    end;

  var p:pinteger;
      nameSize,descrSize,typ:integer;
      name,descr:ansistring;
  begin
    wln('  NoteName        typ NoteDescr');
    if data='' then exit;

    p:=pointer(data);
    while true do begin
      nameSize:=p^;inc(p);
      descrSize:=p^;inc(p);
      typ:=p^;inc(p);

      name:=StrMake(p,nameSize-1{w/out trailing zero});
      descr:=StrMake(psucc(p,nameSize),descrSize);

      wln(format('  %-16s%3x %s',[name,typ,notedump(typ,descr)]));

      inc(p,(namesize+descrsize+3)shr 2);
      if integer(p)>=integer(@data[length(data)+1])then break;
    end;
  end;

var i,j:integer;
    sym:PElfSym;
    s,contents:ansistring;
begin result:='';
  wln('-------ELF dump--------');
  wln(format('magic: %x class: %x filetype: %x archtype: %x fversion: %x entry:%x flags: %x',
             [magic,class_,filetype,archtype,fversion,entry,flags]));
  wln('elfhdrsize'+': '+inttohex(hdrsize,1));
  wln(Format('shdr pos:%4x cnt:%4x ent:%4x size:%4x end:%4x',[shdrpos,shdrcnt,shdrent,shdrcnt*shdrent,shdrcnt*shdrent+shdrpos]));
  wln(Format('phdr pos:%4x cnt:%4x ent:%4x size:%4x end:%4x',[phdrpos,phdrcnt,phdrent,phdrcnt*phdrent,phdrcnt*phdrent+phdrpos]));
  wln('strsec'+': '+inttohex(strsec,1));
  //dump sections
  wln('---- ELF Section header ----');
  wln(' # namestr     na ty fl     addr      ofs      siz      end li in al esiz');
  for i:=0 to shdrcnt-1 do with shdr(i)^ do begin
    wln(format('%2x%-12s%s',[i,shdrname(i),dump]));
    contents:=SectionContents(i);
    DebugFileWrite('sec'+inttostr(i),Contents);

    if type_=2 then begin//symtab
      wln('  Symbol                            value     size in ot shndx');
      for j:=0 to size div entsize-1 do begin
        Sym:=psucc(@Self,offset+entsize*j);
        s:=PAnsiChar(psucc(@self,shdr(link).offset+sym.name));
        wln(Format('  %-30s%9x%9x%3x%3x%5x',[s,sym.value,sym.size,sym.info,sym.other,sym.shndx]));
      end;
    end;

    if BeginsWith(contents,_ElfMagic)and(fileprefix<>'')then begin
      PElfHdr(contents).Dump(fileprefix+'sec'+inttostr(i)+'_');
    end;
  end;
  wln('----ELF Program header----');
  wln(' #        ty      ofs     vaddr    paddr  filesiz      end   memsiz fl al');
  for i:=0 to phdrcnt-1 do with phdr(i)^ do begin
    wln(format('%2x %s',[i,dump]));
    if type_=$70000002 then begin //special ati header
      w('  ');
      for j:=0 to filesiz div 4-1 do begin
        w(inttohex(pinteger(pSucc(@self,offset+j*4))^,8)+' ');
        if(j mod 5)=4 then w(#13#10'  ');
      end;
      wln('');
    end else if type_=4 then begin
      dumpNotes(phdrContents(i));
    end;

    DebugFileWrite('prog'+inttostr(i),phdrContents(i));
  end;
  wln('----End of ELF dump----');

  DebugFileWrite('elfdump.txt',result);
end;

function TElfHdr.FullSize: integer;
begin
  result:=SizeOf(Self);
  result:=max(result,shdrpos+shdrent*shdrcnt);
  result:=max(result,phdrpos+phdrent*phdrcnt);
  if shdrcnt>0 then with shdr(shdrcnt-1)^do result:=max(result,offset+size);
  if phdrcnt>0 then with shdr(phdrcnt-1)^do result:=max(result,offset+size);
end;

function TElfHDR.GetNotes:TElfNotes;

  procedure DumpNotes(const data:ansistring);

    procedure notedump(const typ:integer;const data:ansistring);
    var i,j,key:integer;
    begin
      key:=0;
      for i:=0 to length(data)div 4-1do begin
        j:=PInteger(psucc(pointer(data),i*4))^;
        //interpret notes
        if(i and 1)=0then key:=j else case typ of
          //isa options
          $1:case cardinal(key)of
            $80000006:result.NumThreadPerGroup:=j;
            $8000001C:result.NumThreadPerGroup:=j;//tahiti note
          end;
          //CB sizes
          $A:Result.cbsize[key]:=j;
        end;
        //key name
      end;
    end;

  var p:pinteger;
      nameSize,descrSize,typ:integer;
      name,descr:ansistring;
  begin
    p:=pointer(data);
    while true do begin
      nameSize:=p^;inc(p);
      descrSize:=p^;inc(p);
      typ:=p^;inc(p);

      name:=StrMake(p,nameSize-1{w/out trailing zero});
      descr:=StrMake(psucc(p,nameSize),descrSize);

      notedump(typ,descr);

      inc(p,(namesize+descrsize+3)shr 2);
      if integer(p)>=integer(@data[length(data)+1])then break;
    end;
  end;

var i:integer;
begin
  fillchar(result,sizeof(result),0);
  for i:=0 to phdrcnt-1 do with phdr(i)^ do begin
    if type_=4 then begin
      dumpNotes(phdrContents(i));
    end;
  end;

end;

procedure ReplaceElfSection(var Elf:ansistring;const secIdx:integer;const newContents:ansistring);
var s:ansistring;
begin
  PElfHdr(Elf).SetSectionContents(secIdx,newContents,s);
  Elf:=s;
end;

procedure ReplaceElfSection(var Elf:ansistring;const secName:ansistring;const newContents:ansistring);
var idx:integer;
begin
  idx:=PElfHdr(Elf).SectionIdxByName(secName,true);
  ReplaceElfSection(Elf,idx,NewContents);
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
//      LiteralBytes:integer;
  begin
    rows:=prows(p);
    rowcount:=siz div 8;
    r:=0;
    while(r<rowcount)and(rows[r].qw<>0)do inc(r);//skip padding
//experimental EOP
//    rows[r-3].dw[1]:=rows[r-3].dw[1]or 1 shl 21; //big fail ->
    while(r<rowcount)and(rows[r].qw= 0)do inc(r);//skip padding

//debug:='';linecnt:=0;debug:=debug+tostr(linecnt)+' ';

//    LiteralBytes:=0;
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
//        debug:=debug+' '+ISA_INSTR_OP3_name(instr shr 6);

        if(dw[1]shr 0 and $1ff)=253 then//src2 literal?
          literalCount:=max(literalCount,(dw[1]shr (10+1) and 1){src2 chn high bit}+1);

        if((dw[1]shr 13 and $1f)=oldInstr)then begin//instr replace
          dw[1]:=dw[1]and not($1f shl 13)+(newInstr shl 13);
          inc(result);
        end;
      end;

      if(dw[0]shr 31)<>0 then begin//last instr in a grp
//        debug:=debug+#13#10;inc(linecnt);debug:=debug+tostr(linecnt)+' ';
//        LiteralBytes:=LiteralBytes+literalCount*8;

        r:=r+literalCount; //skip literals
        literalCount:=0;
      end;

      inc(r);
    end;

//    DebugFileWrite('debug.txt',debug);
  end;

var i:integer;
begin
  result:=0;
  for i:=shdrcnt-1 downto 0 do if shdrName(i)='.text' then begin
    DebugFileWrite('isa.bin',DataToStr(pointer(integer(@self)+shdr(i).offset)^,shdr(i).size));
    DoIt(pointer(integer(@self)+shdr(i).offset),shdr(i).size);
    break;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
///  ISA79xx compiler                                                        ///
////////////////////////////////////////////////////////////////////////////////

procedure TIsa79xxOptions.Reset;
begin//defaults
  numvgprs:=3;
  numsgprs:=20;
  cb0sizeDQWords:=0;
  ldsSizeBytes:=0;
  with NumThreadPerGroup do begin
    x:=64;
    y:=1;
    z:=1;
  end;
  with OclBuffers do begin
    uavCount:=1;
    cbCount:=1;
  end;
  OclSkeleton:='';
end;

type
  TISALine=record  //one IAS79xx instruction
    instr:ansistring;
    params:TArray<ansistring>;
    optNames:TArray<ansistring>;
    optValues:TArray<ansistring>;
    optUsed:TArray<boolean>;
    procedure Clear;
    function optIdx(const AName:ansistring):integer;
    function hasOpt(const AName:ansistring):boolean;
  end;

procedure TISALine.Clear;
begin
  instr:='';
  params:=nil;
  optNames:=nil;
  optValues:=nil;
  optUsed:=nil
end;

function TIsaLine.optIdx(const AName:ansistring):integer;
var i:integer;
begin
  for i:=0 to high(optNames)do if cmp(OptNames[i],AName)=0 then exit(i);
  result:=-1;
end;

function TISALine.hasOpt(const AName: ansistring): boolean;
begin
  result:=optIdx(AName)>=0;
end;

function SplitISALine(ALine:ansistring):TISALine;

  function SplitISAParams(const s:ansistring;const separ:ansichar=','):TArray<ansistring>;
  var i:integer;
      splitAt:THetArray<integer>;
      inQuot:ansichar;
      s2:ansistring;
  begin
    result:=nil;
    //get ',' positions outside [] option values
    inQuot:=#0;
    for i:=1 to length(s)do case s[i] of
//      '"','''':if inQuot=s[i] then inQuot:=#0 else inQuot:=s[i];
      '(','[':inQuot:=s[i];
      ']':if inQuot='[' then inQuot:=#0;
      ')':if inQuot='(' then inQuot:=#0;
    else
      if s[i]=separ then if inQuot=#0 then splitAt.Append(i);
    end;
    //split the string
    if splitAt.Count=0 then begin//one or zero(trimmed) elements
      s2:=Trimf(s);
      if s2<>'' then begin
        setlength(result,1);
        result[0]:=s2;
      end;
    end else begin //more elements
      splitAt.Insert(0,0);
      splitAt.Append(Length(s)+1);
      setlength(result,splitAt.Count-1);
      for i:=0 to high(result)do with splitAt do
        result[i]:=TrimF(copy(s,FItems[i]+1,FItems[i+1]-FItems[i]-1));
    end;
  end;

  function SplitOptions(const s:ansistring):TArray<ansistring>;
  begin
    result:=SplitISAParams(s,' ');
  end;

  procedure removeComment(var s:ansistring;const c:ansistring);
  var i:integer;
  begin
    i:=pos(c,s);
    if i>0 then setlength(s,i-1);
  end;

var s:ansistring;
    i:integer;
    first:boolean;
begin with result do begin
  clear;
  //remove comments
  removecomment(ALine,';');
  removecomment(ALine,'//');
  Trim(ALine);
  if ALine='' then exit;

  //split line to instr, params, options
  instr:=lc(WordAt(ALine,1));
  //params
  params:=SplitISAParams(copy(ALine,length(instr)+1));
  //options
  if(params<>nil)and(pos('=',params[high(params)])<=0){no alias a = b}
  and(pos('(',params[high(params)])<=0){no hwreg()}then begin
    first:=true;
    for s in splitOptions(params[high(params)])do if s<>''then begin
      if CheckAndClear(first)then
        params[high(params)]:=s
      else begin
        i:=length(optNames);
        setlength(optNames,i+1);
        setlength(optValues,i+1);
        setlength(optUsed,i+1);
        optNames[i]:=ListItem(s,0,':');
        optValues[i]:=ListItem(s,1,':');
        optUsed[i]:=false;
      end;
    end;
  end;
end;end;

function ValidISAReg(r:ansistring):boolean;
var r2,idx,idx2:ansistring;
    i:integer;
begin
  result:=true;
  if r='' then exit(false);
  if(cmp(r,'s')=0)or(cmp(r,'v')=0)then exit;// [ miatt

  //split index
  if IsWild2('*[*:*]',r,r2,idx,idx2)then begin//felesleges, nem jut ide
    r:=r2;
    i:=StrToInt(idx);
  end else begin
    i:=length(r)+1;
    while(i>1)and(r[i-1]in['0'..'9'])do dec(i);
    idx:=copy(r,i);
    setlength(r,i-1);r:=lc(r);
    i:=StrToIntDef(idx,-1);
  end;

  if(r='s')and(i in[0..$69,$7D,$D1..$EF,$F8..$FA])then exit;
  if(r='v')and(i in[0..$FF])then exit;
  if r='vcc_lo' then exit;
  if r='vcc_hi' then exit;
  if r='tba_lo' then exit;
  if r='tba_hi' then exit;
  if r='tma_lo' then exit;
  if r='tma_hi' then exit;
  if(r='ttmp')and(i in[0..11])then exit;
  if(r='m')and(i=0)then exit;
  if r='exec_lo' then exit;
  if r='exec_hi' then exit;

  if(r='src_vccz'      )then exit;
  if(r='src_execz'     )then exit;
  if(r='src_scc'       )then exit;
  if(r='src_lds_direct')then exit;

  //64bit regs
  if r='vcc' then exit;
  if r='tba' then exit;
  if r='tma' then exit;
  if r='exec' then exit;

  result:=false;
end;

function ISA_Syntax(const AIdentifier:ansistring):TSyntaxKind;
begin
  if ValidISAReg(AIdentifier)then exit(skIdentifier3);
  if ISAInstrByName(AIdentifier)<>nil then begin
    if IsWild2('?_temp*',AIdentifier)then exit(skIdentifier4)else
    if BeginsWith(AIdentifier,'s_')then exit(skIdentifier5)else
    if BeginsWith(AIdentifier,'v_')then exit(skIdentifier6)else
                                        exit(skIdentifier4);
  end;
  if FindBinStrArray(ISAOptionNames,AIdentifier)>=0 then exit(skIdentifier4);
  result:=skIdentifier1;
end;

function IsaHWRegIdx(const s:ansistring):integer;
var i:integer;
begin
  for i:=low(ISAHWRegNames)to high(ISAHWRegNames)do
    if cmp(s,ISAHWRegNames[i])=0 then exit(i);
  result:=StrToInt(s)and $3f;
end;

//var alignSignature:array[0..1]of integer = (1963488625, 421361003);
var alignSignature:array[0..1]of integer = (1963488625, 421361003);

function CompileISA79xx(const AKernel:ansistring; const isGCN3:boolean; out ALiteralConsts:TLiteralConsts;out AOptions:TIsa79xxOptions; out ARawWithoutData:RawByteString):RawByteString;
var actLine:integer;

  function swGCN3(a,b:integer):integer; begin if isGCN3 then result:=a else result:=b; end;

  procedure Error(const s:string);
  begin
    raise Exception.Create(s);
  end;

//// parse line ////////////////////////////////////////////////////////////////

  function InnerSplit(s:ansistring):TArray<AnsiString>;
  //splittel minden labelnÈl es letezo utasitasnal
  const wordStartChars=['a'..'z','A'..'Z','_','@'];
        wordChars=['a'..'z','A'..'Z','0'..'9','_'];
  var i,j,st:integer;
      inWord:boolean;
      clipAt:THetArray<integer>;
      s2:ansistring;
      firstCh:ansichar;
  begin
    Result:=nil;

    i:=pos(';',s); //strip asm comments
    if i>0 then begin
      for j:=i+1 to length(s)do if s[j]in['''','"']then
        Error('Don''t use string delimiters ('', ") in asm ;comments! Outer precompiler can threat them az an endless string constants.');
      s:=copy(s,1,i-1);
    end;

    if s='' then exit;
    inWord:=false;
    st:=1;{nowarn}
    firstCh:=#0;
    for i:=1 to length(s)+1 do begin
      if not inWord and(s[i]in wordStartChars)then begin
        inWord:=true;
        st:=i;
        firstCh:=s[i];
      end else if inWord and not(s[i]in wordChars)then begin
        inWord:=false;
        if(s[i]=':')and((st=1)or(firstCh='@'))then begin //label(only at beginning of a line vagy @-al kezdodjon) -> split at beginning and end
          if st>1 then clipAt.Append(st);
          clipAt.Append(i+1);
        end else begin
          if ISAInstrExists(Crc32UC(@s[st],i-st))then
            if st>1 then clipAt.Append(st);
        end;
      end;
    end;

    if clipAt.Count=0 then begin
      setlength(result,1);
      result[0]:=s;
    end else begin
      clipAt.Insert(1,0);
      clipAt.Append(Length(s)+1);
      for i:=0 to clipAt.Count-2 do begin
        s2:=TrimF(copy(s,clipAt.FItems[i],clipAt.FItems[i+1]-clipAt.FItems[i]));
        if s2<>'' then begin
          SetLength(Result,length(result)+1);
          result[high(Result)]:=s2;
        end;
      end;
    end;
  end;

var line:TISALine;

  function paramCount:integer;
  begin result:=length(line.params);end;

  function paramStr(n:integer):ansistring;
  begin
    if n>high(line.params)then error('not enough parameters');
    result:=line.params[n];
  end;

  function paramConst(n:integer):variant;
  var s:AnsiString;
      ch:PAnsiChar;
  begin
    s:=paramStr(n);
    ch:=pointer(s);
    result:=ParsePascalConstant(ch);
    if ch^<>#0 then
      raise Exception.Create('invalid chars in constant "'+s+'"');
  end;

var
  ParamAbs,ParamNeg:integer; //abs(), neg(), - parameterek

  procedure Preprocess_Neg_Abs;//neg, abs
  var i:integer;
      s,w:ansistring;
  begin
    paramAbs:=0;paramNeg:=0;

    for i:=0 to high(line.params)do begin
      s:=line.params[i];
      while true do begin//addig csinalja, amig van mit
        w:=WordAt(s,1);
        if((charn(s,1)='-')and not(charn(s,2)in['0'..'9','$']))
        or(cmp(w,'neg')=0)then begin
          //ha - jellel kezdodik, de nem szammal folytatodik, vagy ha neg(x)
          if(ParamAbs shr i and 1)=0 then//abs utan mar nem szamit a neg
            ParamNeg:=ParamNeg xor 1 shl i;
          s:=trimf(copy(s,2));
        end else if cmp(w,'abs')=0 then begin
          //ha abs(x)
          ParamAbs:=ParamAbs or 1 shl i;
          s:=trimf(copy(s,4));
        end else if(charn(s,1)='(')and(CharN(s,length(s))=')')then begin
          //ha () kozott van, akkor azt leszedi rola
          s:=trimf(copy(s,2,length(s)-2));
        end else
          break;
      end;
      line.params[i]:=s;
    end;
  end;

  function v8check(n:integer):boolean;//it it v0..v255?
  var s:ansistring;i:integer;
  begin
    result:=IsWild2('v*',paramStr(n),s)and TryStrToInt(s,i);
  end;

  function MustDoWithVOP3:boolean; //for line
  const vop3mods:array[0..2]of ansistring=('mul','div','clamp');
  var s:ansistring;
  begin
    if line.hasOpt('vop3')then exit(true);
    if ParamAbs or ParamNeg>0 then exit(true);
    for s in vop3mods do if line.hasOpt(s)then exit(true);
    result:=false;
  end;

  function CanDoWithVOP2:boolean; //for line
  var ir2:PISAInstrRec;
  begin
    if MustDoWithVOP3 then exit(false);

    for ir2 in ISAInstrByName(line.instr)do if ir2.enc=VOP2 then begin
      if ir2.pfmt='v0, s0, v0' then exit(v8check(0)and v8check(2))
      else if ir2.pfmt='v0, vcc, s0, v0' then exit(v8check(0)and v8check(3));
    end;
    result:=false;
  end;

  function SelectBestInstrRec:PISAInstrRec;

    function ScoreOf(const AIr:PISAInstrRec):integer;
    var iline:TISALine;
        i,j:integer;
        found:boolean;
    begin//minel tobb kotelezo parameter letezik, annal nagyobb a score. -1, ha error
      result:=0;
      iline:=SplitISALine(AIr.name+' '+AIr.pfmt);

      if AIr.enc<>XOP then begin//xop-nal nincs check, az csak specialis
        //check for paramcount
        if length(line.params)<>length(iline.params)then exit(-1);

        //check vcc params
        found:=false;
        for j:=0 to high(line.params)do if(iline.params[j]='vcc')then
          if(line.params[j]='vcc')then found:=true else exit(-1);
        if found then inc(result,2);//vcc match = highrer priority (v_add_i32 VOP3 vs. VOP2)
      end;

      //check if all required ops present
      for i:=0 to high(iline.optNames)do if iline.optValues[i]='' then begin
        //ha a parameterek miatt kotelezo a vop3 encoding, akkor nem kotelezo a 'vop3' option hasznalata
        if(AIr.enc=VOP3)and(cmp(iline.optNames[i],'VOP3')=0)and MustDoWithVOP3 then
          continue;

        inc(result,$100);
        found:=false;
        for j:=0 to high(line.optNames)do if line.optNames[j]=iline.optNames[i] then begin
          found:=true;
          break;
        end;
        if not found then exit(-1);
      end;

      if(AIr.enc=VOP3)and not line.hasOpt('vop3')and CanDoWithVOP2 then exit(-1);
      if(AIr.enc=VOP2)and MustDoWithVOP3 then exit(-1);
    end;

  var bestScore,score:integer;
      ir:PISAInstrRec;
  begin
    bestScore:=-1;result:=nil;
    for ir in ISAInstrByName(line.instr)do begin
      score:=ScoreOf(ir);
      if(Score>bestScore)then begin
        bestScore:=score;
        result:=ir;
      end;
    end;
  end;

  function FindOption(const AName:ansistring):integer;
  var i:integer;
  begin
    for i:=0 to high(line.optNames)do if cmp(line.optNames[i],AName)=0 then begin
      line.optUsed[i]:=true;
      exit(i);
    end;
    result:=-1;
  end;

  function hasOption(const o:ansistring):boolean;
  begin
    result:=FindOption(o)>=0;
  end;

  function OptionBit(const o:ansistring):integer;//0 or 1
  begin result:=ord(hasOption(o));end;

  function OptionStr(const o:ansistring):ansistring;
  var i:integer;
  begin
    i:=FindOption(o);
    if i>=0 then result:=line.optValues[i]
            else result:='';
  end;

  function OptionInt(const o:ansistring;const AMin:integer=0;const AMax:integer=0;const ADefault:integer=0):integer;//0 or 1
  var s:ansistring;
  begin
    s:=OptionStr(o);
    if s='' then exit(ADefault)
            else result:=CompileExpr(s).Eval;
    if(AMax>AMin)and not InRange(result,AMin,AMax)then
      Error(format('Option "%s" out of range [%d..%d]',[o,AMin,AMax]));
  end;

  function OptionDFmt(const o:ansistring):integer;//0 or 1
  var s:ansistring;i:integer;
  begin
    result:=0;s:=OptionStr(o);
    for i:=0 to high(ISA_BUF_DATA_FORMATS)do if ISA_BUF_DATA_FORMATS[i]<>'' then
      if pos(ISA_BUF_DATA_FORMATS[i],s,[poIgnoreCase,poWholeWords])>0 then
        exit(i);
  end;

  function OptionNFmt(const o:ansistring):integer;//0 or 1
  var s:ansistring;i:integer;
  begin
    result:=0;s:=OptionStr(o);
    for i:=0 to high(ISA_BUF_NUM_FORMATS)do if ISA_BUF_NUM_FORMATS[i]<>'' then
      if pos(ISA_BUF_NUM_FORMATS[i],s,[poIgnoreCase,poWholeWords])>0 then
        exit(i);
  end;

  function OptionOMOD:integer;
  begin
    if hasOption('div')then begin
      result:=OptionInt('div');
      case result of
        1:exit(0);
        2:exit(3);
      else Error('Invalid option value "div:'+tostr(result)+'"')end;
    end else if hasOption('mul')then begin
      result:=OptionInt('mul');
      case result of
        1:exit(0);
        2:exit(1);
        4:exit(2);
      else Error('Invalid option value "mul:'+tostr(result)+'"')end;
    end else
     result:=0;
  end;

//// code writer ///////////////////////////////////////////////////////////////

var
  ISACode:THetArray<cardinal>;
  handled:boolean;

  procedure Emit(dd:cardinal);
  begin
    ISACode.Append(dd);
    handled:=true;
  end;

var
  Immeds:TArray<integer>; //ebbe ir az svk9, az emit utan kell kiirni a stream-be

//// Jump Labels ///////////////////////////////////////////////////////////////

type
  TLabel=record
    name:ansistring;
    addr:integer;//-1=undefined;
    relative_refs:TArray<integer>; //simm16
    abs_refs:TArray<integer>;
  end;
  PLabel=^TLabel;

var
  Labels:TArray<TLabel>;

  function LabelByName(const AName:ansistring):PLabel;
  var i:integer;
  begin
    if AName='' then Error('No label name');

    for i:=0 to high(Labels)do if cmp(AName,Labels[i].name)=0 then exit(@Labels[i]);
    //add new
    setlength(Labels,length(Labels)+1);
    result:=@Labels[high(Labels)];
    //clear
    result.name:=AName;
    result.addr:=-1;
  end;

  procedure AddLabel_RelativeRef_beforeEmit(const AName:ansistring);
  begin
    AddIntArrayNoCheck(LabelByName(AName).relative_refs,ISACode.Count);
  end;

  procedure AddLabel_AbsOffset_beforeEmit(const AName:ansistring);
  begin
    AddIntArrayNoCheck(LabelByName(AName).abs_refs,ISACode.Count+1);
  end;

  procedure AddLabelDefinition(const AName:ansistring);
  begin
    with LabelByName(AName)^do begin
      if Addr<>-1 then Error('Label "'+AName+'" already defined');
      Addr:=ISACode.Count;
    end;
  end;

  procedure RelocateLabelReferences;
  var i,ref,delta:integer;
  begin
    for i:=0 to high(Labels)do with Labels[i]do begin
      if addr=-1 then Error('Undefined label "'+name+'"');
      for ref in relative_refs do begin
        delta:=addr-ref-1;
        if delta<>smallint(delta) then Error('Relative jump out of range (abs('+toStr(delta*4)+')>128K)');
        psmallint(@ISACode.FItems[ref])^:=delta;
      end;
      for ref in abs_refs do
        pinteger(@ISACode.FItems[ref])^:=addr*4;
    end;
  end;

  function isLabel(const s:ansistring):boolean;
  var i:integer;
  begin
    result:=false;
    if not(uc(CharN(s,1))in['A'..'Z','@','_'])then exit;
    for i:=2 to length(s)do if not(uc(s[i])in['A'..'Z','0'..'9','_'])then exit;
    if s='@' then exit;

    result:=true;
  end;


//// Decode parameters /////////////////////////////////////////////////////////

  type TSvk9Mode = (Default,
                    VisImm8,        //V(100..1ff) is immediate dword offset 0..255
                    VisImm8_sar2,   //V(100..1ff) is immediate byte  offset 0..1023 returned as dword offset(0..255)
                    SMEMOffset);    //return $80000000 | SMEM loteral Offset if found one.
                    //0..ff is always S8

  function svk9(n:integer; const mode:TSvk9Mode=Default):integer; //S or V or K 9bit
  //VisImm8= s_buffer src2 addressing
 {  $00..$69   s0..s105
    $6A        vcc_lo
    $6B        vcc_hi
    $6C        tba_lo
    $6D        tba_hi
    $6E        tma_lo
    $6F        tma_hi
    $70..$7B   ttmp0..ttmp11
    $7C        m0
    $7D        s125       //????
    $7E        exec_lo
    $7F        exec_hi

    //if not VisImm8
    $80..$C0   0..64
    $C1..$D0   -1..-16
    $D1..$EF   s209..s239 //ez mi???
    $F0, $F1   0.5, -0.5
    $F2, $F3   1.0, -1.0
    $F4, $F5   2.0, -2.0
    $F6, $F7   4.0, -4.0
    $F8..$FA   s248..s250 //meg ez is mi???
    $FB        src_vccz
    $FC        src_execz
    $FD        src_scc
    $FE        src_lds_direct
    $FF        [IMMEDIATE DWORD]
    $100..$1FF  v0..v255}
  const floats:array[$F0..$F7]of single=(0.5,-0.5,1,-1,2,-2,4,-4);
  var r,r2,idx,idx2:ansistring;
      i:integer;
      s:single;
      cnst:variant;
      i64:int64;
  begin
    result:=0;//nowarn
    r:=lc(ParamStr(n));
    if r='' then Error('Empty parameter');

    //numerics
    if r[1]in['0'..'9','$','+','-']then begin
      cnst:=CompileExpr(r).Eval;
      if VarIsOrdinal(cnst)then begin//integer const
        i64:=cnst;i:=i64;
        if mode=VisImm8_sar2 then i:=sar(i, 2);
        if mode<>Default then begin
          if mode=SMEMOffset then exit(cardinal(i) or $80000000);
          if not InRange(i,0,255) then Error('sk8_smrd offset out of range');
          exit($100+byte(i));
        end else begin
          if inrange(i,0,64)then exit($80+i);
          if inrange(i,-16,-1)then exit($C0-i);
          AddIntArrayNoCheck(immeds,i);exit($FF);
        end;
      end else if VarIsFloat(cnst)and(mode=Default)then begin//float const
        s:=cnst;
        for i:=low(floats)to high(floats)do if floats[i]=s then exit(i);
        AddIntArrayNoCheck(immeds,pinteger(@s)^);exit($FF);
      end else if not VarIsEmpty(cnst)then
        error('invalid constant "'+r+'"');
    end;

    //split index
    if IsWild2('*[*:*]',r,r2,idx,idx2)then begin
      r:=r2;
      i:=StrToInt(idx);
    end else begin
      if IsWild2('[*,*]',r,idx,idx2)then r:=idx; //[ttmp0,ttmp1]
      i:=length(r)+1;
      while(i>1)and(r[i-1]in['0'..'9'])do dec(i);
      idx:=copy(r,i);
      setlength(r,i-1);r:=lc(r);
      i:=StrToIntDef(idx,-1);
    end;

    if mode<>Default then begin
      if(r='s')and(i in[0..$69,$7D,$80..$FF])then exit(i);
    end else begin
      if(r='s')and(i in[0..$69,$7D,$D1..$EF,$F8..$FA])then exit(i);
      if(r='v')and(i in[0..$FF])then exit($100+i);
    end;
    if r='vcc_lo' then exit($6A);
    if r='vcc_hi' then exit($6B);
    if r='tba_lo' then exit($6C);
    if r='tba_hi' then exit($6D);
    if r='tma_lo' then exit($6E);
    if r='tma_hi' then exit($6F);
    if(r='ttmp')and(i in[0..11])then exit($70+i);
    if(r='m')and(i=0)then exit($7C);
    if r='exec_lo' then exit($7E);
    if r='exec_hi' then exit($7F);

    if(r='src_vccz'      )then exit($FB);
    if(r='src_execz'     )then exit($FC);
    if(r='src_scc'       )then exit($FD);
    if(r='src_lds_direct')then exit($FE);

    //64bit regs
    if r='vcc' then exit($6A);
    if r='tba' then exit($6C);
    if r='tma' then exit($6E);
    if r='exec' then exit($7E);

    //label address
    r:=lc(ParamStr(n));
    if r[1]in ['@','a'..'z','0'..'9'] then begin
      AddLabel_AbsOffset_beforeEmit(r);
      AddIntArrayNoCheck(immeds,$12345678);//<-felul lesz irva
      exit($FF);
    end;

    Error('invalid parameter "'+ParamStr(n)+'"');
  end;

  function v8(n:integer):integer; //V 8bit
  begin result:=svk9(n)-$100;if not inrange(result,0,$FF)then Error('vgprs expected');end;

  function sk8(n:integer):integer;//S or K 8bit (s_ source parameters)
  begin
    result:=svk9(n);
    if not inrange(result,0,$FF)then Error('sgprs/literal expected');
  end;

  function sk9(n:integer; byteOfsExpected:boolean):integer; //S 6bit (smrd buffer addressing)
  var m:TSvk9Mode;
  begin
    if byteOfsExpected then m:=VisImm8_sar2
                       else m:=VisImm8;
    result:=svk9(n, m);
  end;

  function s8(n:integer):integer;
  begin
    result:=svk9(n, VisImm8);
    if not inrange(result,0,$FF)then Error('sgprs expected');
  end;

  function s7(n:integer):integer; //S 7bit
  begin result:=svk9(n);if not inrange(result,0,$7F)then Error('sgprs expected');end;

  function simm16(n:integer):integer;
  var r:ansistring;
      i:integer;
      cnst:variant;
      i64:int64;
      s0,s1,s2:ansistring;
  begin
    result:=0;//nowarn
    r:=ParamStr(n);
    if r='' then Error('Empty parameter');

    //numerics
    if r[1]in['0'..'9','$','+','-']then begin
      cnst:=CompileExpr(r).Eval;
      if VarIsOrdinal(cnst)then begin//integer const
        i64:=cnst;i:=i64;
        if inrange(word(i),0,$FFFF)then exit(i)
                                   else error('16bit int expected');
      end else if not VarIsEmpty(cnst)then
        error('invalid constant "'+r+'"');
    end;

    //s_wait counters         //todo
    if r='lgkmcnt(0)' then exit($7F); //s_buffer_load
    if r='vmcnt(0)' then exit($1F70); //tbuffer_load
    if r='expcnt(0)' then exit($1F0F);//tbuffer_store

    //hwreg access
    if IsWild2('hwreg(*,*,*)',r,s0,s1,s2)then begin
      result:=ISAHWRegIdx(s0) shl 0+       //regId
              StrToInt(s1)and $1f shl 6+       //bitOffs
              (StrToInt(s2)-1)and $1f shl 11;  //bitCnt+1
      exit;
    end;

    //!!!! todo: and so on

    Error('invalid simm16 parameter "'+ParamStr(n)+'"');
  end;

  function VOP3Mods0(idx,cnt:integer):integer;//VOP3 0. dword modifiers
  var m:integer;
  begin
    m:=(1 shl cnt-1)shl idx;
    if ParamAbs and not m<>0 then Error('Invalid use of ABS() source modifier');
    result:=ParamAbs shr idx shl 8+OptionBit('clamp')shl swGCN3(15 ,11);
  end;

  function VOP3Mods1(idx,cnt:integer):integer;//VOP3 1. dword modifiers
  var m:integer;
  begin
    m:=(1 shl cnt-1)shl idx;
    if ParamNeg and not m<>0 then Error('Invalid use of NEG() source modifier');
    result:=OptionOMOD shl 27+ParamNeg shr idx shl 29;
  end;

//// Automatic parameter reordering ////////////////////////////////////////////

  function getCommutativePair(var ir:PISAInstrRec):boolean;
  const relPairs:array[0..4,0..1]of ansistring=(('eq','eq'),('ne','ne'),('lg','lg'),('gt','lt'),('ge','le'));
  var s0,s1,s2:ansistring;
      i,j,k:integer;
      res:TArray<PISAInstrRec>;
  begin
    result:=false;
    if IsWild2('s_cmpk_*_*', ir.name, s1, s2)then begin
      for i:=0 to high(relPairs)do for j:=0 to 1 do
        if s1=relPairs[i,j] then begin
          res:=ISAInstrByName('s_cmpk_'+relPairs[i,1-j]+'_'+s2);
          if length(res)<>1 then Error('getCommutativePair() Internal error1!');
          ir:=res[0];
          exit(true);
        end;
    end else
    if IsWild2('v_cmp*_*_*', ir.name, s0, s1, s2)then begin
      for i:=0 to high(relPairs)do for j:=0 to 1 do
        if s1=relPairs[i,j] then begin
          res:=ISAInstrByName('v_cmp'+s0+'_'+relPairs[i,1-j]+'_'+s2);
          for k:=0 to high(res)do if res[k].enc=VOPC then begin
            ir:=res[k];
            exit(true);
          end;
          Error('getCommutativePair() Internal error2!');
        end;
    end;
  end;

  function isInt(const s:ansistring):boolean;
  var i:integer;
  begin
    result:=TryStrToInt(s,i);
  end;

  procedure alignFill(bytes:integer);
  begin
    if bytes=0 then exit;
    if(bytes and 3)<>0 then Error('invalid align: minimum alignment is 4 bytes');
    if(bytes<0) then Error('invalid align: must be not less than 0');

    while(ISACode.Count*4 mod bytes)>0 do
      emit(alignSignature[ISACode.Count and 1]{xor 426315779});
  end;

//// Data hiding for disassembler //////////////////////////////////////////////

var dataBeginPos:integer;
    dataRanges:THetArray<integer>;

procedure dataBegin;
begin
  if dataBeginPos>=0 then Error('DataHiding: [dataBegin] already specified.');
  dataBeginPos := ISACode.Count;
end;

procedure dataEnd;
begin
  if dataBeginPos<0 then Error('DataHiding: [dataBegin] haven''t specified.');

  dataRanges.Append(dataBeginPos);
  dataRanges.Append(ISACode.Count);
end;

function applyDataRanges(const src:RawByteString):RawByteString;
var i, j, st, en:integer;
    p:PIntegerArray;
    nop:integer;
begin
  if dataRanges.Empty then exit(src);

  setlength(result, length(src)); //hard copy
  p:=pointer(result);
  move(pointer(src)^, p^, length(src));

  nop:=integer($BF800000); //s_nop

  for i:=0 to dataRanges.Count div 2-1 do begin
    st:=dataRanges.FItems[i*2];
    en:=dataRanges.FItems[i*2+1];
    for j:=st to en-1 do begin
      p[j]:=nop;
    end;
  end;
end;


//// Main //////////////////////////////////////////////////////////////////////

var ir:PISAInstrRec;
    Aliases:TAliases;

  procedure emitCode(c:integer);
  var code:integer;
  begin
    if isGCN3 then code:=ir.code3
              else code:=ir.code;
    if code=0 then error('FATAL: Can''t emit 0 as encoded opcode.');
    emit(code+c);
  end;

  procedure encodeXOP;
  var i,j:integer;
  begin
    handled:=true;
    if line.instr='isa79xx' then//nothing yet
    else if line.instr='numvgprs'then AOptions.numvgprs:=paramConst(0)
    else if line.instr='numsgprs'then AOptions.numsgprs:=paramConst(0)
    else if line.instr='cb0size'then AOptions.cb0sizeDQWords:=paramConst(0)
    else if line.instr='ldssize'then AOptions.ldsSizeBytes:=paramConst(0)
    else if line.instr='dd' then for i:=0 to paramCount-1 do emit(paramConst(i))
    else if line.instr='alias' then for i:=0 to paramCount-1 do Aliases.DeclareAlias(paramStr(i))
    else if line.instr='v_temp_range' then Aliases.DeclareTempRange(regV,line.params)
    else if line.instr='s_temp_range' then Aliases.DeclareTempRange(regS,line.params)
    else if line.instr='v_temp' then begin j:=OptionInt('align',1,32,1); for i:=0 to paramCount-1 do Aliases.DeclareTemp(regV,paramStr(i),j)end
    else if line.instr='s_temp' then begin j:=OptionInt('align',1,32,1); for i:=0 to paramCount-1 do Aliases.DeclareTemp(regS,paramStr(i),j)end
    else if line.instr='enter' then Aliases.EnterTempScope
    else if line.instr='leave' then Aliases.LeaveTempScope
    else if line.instr='eof' then emit(0)
    else if line.instr='aligncode' then alignFill(paramConst(0))
    else if line.instr='numthreadpergroup'then with AOptions.NumThreadPerGroup do begin
      x:=paramConst(0);
      if paramCount>1 then y:=paramConst(1) else y:=1;
      if paramCount>2 then z:=paramConst(2) else z:=1;
    end else if line.instr='oclbuffers'then with AOptions.OclBuffers do begin
      uavCount:=paramConst(0);
      cbCount:=paramConst(1);
    end else if line.instr='oclskeleton'then AOptions.OclSkeleton:=paramConst(0) //it does not works. Because string constants versus asm_isa. Must inject with cl.dev.NewKernel()
    else if line.instr='databegin' then dataBegin
    else if line.instr='dataend' then dataEnd
    else if line.instr='inline' then begin
      beep; //todo
    end else handled:=false;
  end;


  procedure encodeSMRD;
  var offset:integer;
      isMemOp, ofsByte, ofsDWord, imm:boolean;
  begin
    if ir.pfmt='s[0:1]'then begin
      if isGCN3 then begin
        error('GCN3 SMEM encoder not impl');
      end else begin
        emitcode(s7(0)shl 15);//s_memtime
      end;
    end else if{ir.pfmt='s[0:1], s[0:3], s0'}true{same params for all}then begin

      //fetch byte/dword ofs specifier
      isMemOp:=BeginsWith(ir.name, 's_load')or BeginsWith(ir.name, 's_buffer')or BeginsWith(ir.name, 's_store');
      ofsDWord:=hasOption('ofsdword');
      ofsByte:=hasOption('ofsbyte');
      if isMemOp then begin
        if not ofsByte and not ofsDWord then error('SMEM: Must specify ofsByte of ofsDWord!');
      end else begin
        if ofsByte then error('SMEM: invalid use of ofsByte.');
        if ofsDWord then error('SMEM: invalid use of ofsDWord.');
      end;
      if ofsByte and ofsDWord then error('Can''t specify both: ofsByte and ofsDWord.');

      //do the encoding
      if isGCN3 then begin
        offset:=svk9(2, SMEMOffset);

        imm:=offset<0;
        if imm then begin //immediate= MSB set
          offset:=offset and $7fffffff;
          if ofsDWord then offset:=offset shl 2; //convert to byte ofs overflow not handled...
        end else begin //sreg
          if ofsDWord then error('SMEM: invalid use of ofsDWord. SGPR is always byte offset.');
        end;
        if cardinal(offset)>=1 shl 20 then error('SMEM offset out of range');

        emitCode(s7(0)shl 6+s7(1)shr 1 shl 0
                +ord(imm)shl 17
                +OptionBit('glc')shl 16);
        emit(offset);
      end else begin//GCN1
        offset:=sk9(2, ofsByte and isMemOp);
        if(offset<$100)and ofsDWord then error('SMEM: invalid use of ofsDWord. SGPR is always byte offset.');
        emitcode(s7(0)shl 15+s7(1)shr 1 shl 9+offset);
      end;
    end;
  end;


var sOuter,s,sl:ansistring;
    i,j:integer;
begin
  result:='';
  ALiteralConsts:=nil;
  actLine:=-1;
  AOptions.reset;
  Aliases:=TAliases.Create; AutoFree(Aliases);
  Aliases.typ:=isa;
  dataBeginPos:=-1;
  try
    for sOuter in ListSplit(AKernel,#10)do for s in InnerSplit(sOuter)do begin
      inc(actLine);

      //literaldef?
      if IsConstantInitialization(s) then begin
        AddConstantInitialization(ALiteralConsts,s);
        Continue;
      end;

      //label definition?
      if IsWild2('*:',s,sl)then begin
        for i:=1 to length(sl)do if not(sl[i]in['a'..'z','A'..'Z','0'..'9','_','@'])then
          Error('invalid char in label "'+sl+'"');

        AddLabelDefinition(sl);
        Continue;
      end;

      //split line
      Line:=SplitISALine(s);
      if line.instr='' then Continue;

      //VOP3 modifiers
      Preprocess_Neg_Abs;

      //process aliases
      if(line.instr<>'v_temp')and(line.instr<>'s_temp')then //no alias resolve in declarations (alias is on, because a=b format
        for i:=0 to high(line.params)do line.params[i]:=Aliases.Resolve(line.params[i]);

      //find instruction
      ir:=SelectBestInstrRec;
      if ir=nil then Error('unknown instruction/no matching options"'+line.instr+'"');

      //Check if opcode exists: GCN12 or GCN3
      case switch(isGCN3, ir.code3, ir.code)of
        0: Error('Instruction NOT IMPLEMENTED on '+switch(isGCN3,'GCN3', 'GCN12 architecture.'));
      end;

      //encode
      handled:=false;
      case ir.enc of
        SOP1:if(ir.pfmt='s0, s0')or(ir.pfmt='s[0:1], s[0:1]')or(ir.pfmt='s0, s[0:1]')then begin
            emitcode(s7(0)shl 16+sk8(1));
          end else if(ir.pfmt='s0')then begin //s_cbranch_join
            emitcode(sk8(0));
          end else if(ir.pfmt='s[0:1]')then begin //s_setpc, s_getpc
            emitcode(s7(0)+s7(0)shl 16);
          end;
        SOP2:if(ir.pfmt='s0, s0, s0')or(ir.pfmt='s[0:1], s[0:1], s[0:1]')or(ir.pfmt='s[0:1], s[0:1], s0') then begin
            emitcode(s7(0)shl 16+sk8(1)+sk8(2)shl 8);
          end;
        SOPK:if(ir.pfmt='s0, 0x0000')or(ir.pfmt='s0, hwreg(0, 0, 1)'{s_getreg})then begin
            if isInt(ParamStr(0))and getCommutativePair(ir)then
              emitcode(s7(1)shl 16+simm16(0)and $FFFF)
            else
              emitcode(s7(0)shl 16+simm16(1)and $FFFF);
          end else if ir.pfmt='hwreg(0, 0, 1), s0' then begin //s_setreg
            emitcode(s7(1)shl 16+simm16(0)and $FFFF)
          end else if ir.pfmt='s[0:1], label_0027'then begin //s_cbranch_fork
            if isLabel(paramStr(1))then begin
              AddLabel_RelativeRef_beforeEmit(paramStr(1));
              emitcode(s7(0)shl 16)
            end else
              emitcode(s7(0)shl 16+simm16(1)and $FFFF);
          end;
        SOPC:if ir.pfmt='s0, s0' then begin
            emitcode(sk8(0)+sk8(1)shl 8);
          end;
        SMRD:encodeSMRD;
        SOPP:if ir.pfmt='0x0000' then begin
            emitcode(simm16(0)and $FFFF);
          end else if ir.pfmt='' then begin
            emitcode(0);
          end else if ir.pfmt='label' then begin
            if isLabel(paramStr(0))then begin
              AddLabel_RelativeRef_beforeEmit(paramStr(0));
              emitcode(0);
            end else
              emitcode(simm16(0)and $FFFF);
          end;
        VOP1:if ir.pfmt='v0, s0' then begin
            emitcode(v8(0)shl 17+svk9(1))
          end else if ir.pfmt='s0, s0' then begin
            emitcode(s7(0)shl 17+(v8(1)+$100))//v_readfirstlane
          end;
        VOP2:if ir.pfmt='v0, s0, v0' then begin
            emitcode(v8(0)shl 17+svk9(1)+v8(2)shl 9)
          end else if(ir.pfmt='v0, vcc, s0, v0')or(ir.pfmt='v0, vcc, s0, v0, vcc')then begin
            emitcode(v8(0)shl 17+svk9(2)+v8(3)shl 9)
          end else if ir.pfmt='s0, s0, s0' then begin
            emitcode(s8(0)shl 17+(v8(1)+$100)+sk8(2)shl 9)//v_readlane
          end else if ir.pfmt='v0, s0, s0' then begin
            emitcode(v8(0)shl 17+(sk8(1))+sk8(2)shl 9)//v_writelane
          end;
        VOP3:if(ir.pfmt='v0, s0, s0, s0')or(ir.pfmt='v0, s0, s0, s[0:1]')then begin
            emitcode(v8(0)                              +VOP3Mods0(1,3));
            emit(svk9(1)+svk9(2)shl 9+svk9(3)shl 18     +VOP3Mods1(1,3));
          end else if(ir.pfmt='v0, s0, s0')or(ir.pfmt='v0, s0, s0 vop3')or(ir.pfmt='v[0:1], s[0:1], s[0:1]')then begin
            emitcode(v8(0)                              +VOP3Mods0(1,2));
            emit(svk9(1)                                +VOP3Mods1(1,2)
                +svk9(2)shl 9
                +switch(IsWild2('v_mul*32',ir.name),$2000000));//mul-nal az scr2 parameter valamiert 2 (a calcl-altal), de megy ugy is, ha 0
          end else if(ir.pfmt='v0, s[0:1], s0, s0')then begin
            emitcode(v8(0)+s7(1)shl 8); if VOP3Mods0(2,2)<>0 then error('No abs()/Clamp allowed when dst S reg is specified (GCN3:todo)');
            emit(svk9(2)                                +VOP3Mods1(2,2)
                +svk9(3)shl 9);
          end else if(ir.pfmt='v0, s[0:1], s0, s0, s[0:1]')then begin
            emitcode(v8(0)+s7(1)shl 8); if VOP3Mods0(2,2)<>0 then error('No abs()/Clamp allowed when dst S reg is specified (GCN3:todo)');
            emit(svk9(2)                                +VOP3Mods1(2,2)
                +svk9(3)shl 9+ s7(4)shl 18);
          end else if ir.pfmt='s[0:1], s0, s0' then begin
            emitcode(s8(0)                              +VOP3Mods0(1,2));
            emit(svk9(1)+svk9(2)shl 9                   +VOP3Mods1(1,2));
          end else if ir.pfmt='v0, s0 vop3' then begin
            emitcode(v8(0)                              +VOP3Mods0(1,2));
            emit(svk9(1)                                +VOP3Mods1(1,2));
          end else if ir.pfmt='v[0:1], s[0:1], s0' then begin //64 bit shift
            emitcode(v8(0)                              );
            emit(svk9(1)+svk9(2)shl 9                   );
          end;
        VOPC:if(ir.pfmt='vcc, s0, v0')or(ir.pfmt='vcc, s[0:1], v[0:1]')then begin
            if not beginsWith(lc(ParamStr(2)),'v')and getCommutativePair(ir)then
              emitCode(svk9(2)+v8(1)shl 9)
            else
              emitCode(svk9(1)+v8(2)shl 9);
          end;
        DS:if(ir.pfmt='v0, v0, v2')then begin  //az offset az valojaban 2 offset (lo,hi)
            emitcode(OptionInt('offset0',0,$FF)
                  or OptionInt('offset1',0,$FF)shl 8
                  or OptionBit('gds')shl 17);
            emit(v8(1)  +v8(2)shl 8  +v8(0)shl 24);
          end else if(ir.pfmt='v0, v[2:3], v[0:1]')or(ir.pfmt='v0, v2, v0')then begin  //ds_writex2_b??
            emitcode(OptionInt('offset0',0,$FF)
                  or OptionInt('offset1',0,$FF)shl 8
                  or OptionBit('gds')shl 17);
             emit(v8(0)  +v8(1)shl 8  +v8(2)shl 16)
          end else if ir.pfmt='v0, v2'then begin
            emitcode(OptionInt('offset',0,$FFFF)
                    +OptionBit('gds')shl 17);
            emit(v8(0)  +v8(1)shl 8);
          end else if ir.pfmt='v0, v[2:3]'then begin //_b64
            emitcode(OptionInt('offset',0,$FFFF)
                    +OptionBit('gds')shl 17);
            emit(v8(0)  +v8(1)shl 8);
          end else if ir.pfmt='v0, v0'{masmilyen paramlista}then begin
            emitcode(OptionInt('offset',0,$FFFF)
                    +OptionBit('gds')shl 17);
            emit(v8(1)  +v8(0)shl 24);
          end else if(ir.pfmt='v[0:1], v0')or(ir.pfmt='v[0:3], v0')then begin //x2, _b64
            emitcode(OptionInt('offset0',0,$FF)
                  or OptionInt('offset1',0,$FF)shl 8
                  or OptionBit('gds')shl 17);
            emit(v8(1)  +v8(0)shl 24);
          end else if ir.pfmt='v0' then begin //ds_gws_barrier
            emitcode(OptionInt('offset',0,$FFFF)
                  or OptionInt('offset0',0,$FF)
                  or OptionBit('gds')shl 17);
            emit(v8(0));
          end;
        MTBUF:if{v0, v0, s[0:3], s0 format:[BUF_DATA_FORMAT_INVALID]}true{same params for all} then begin
            emitcode(optionInt('offset',0,$FFF){12bit}
                    +optionBit('offen')shl 12
                    +optionBit('idxen')shl 13
                    +optionBit('glc')shl 14
                    +optionBit('adr64')shl 15
                    +optionDFmt('format')shl 19
                    +optionNFmt('format')shl 23);
            emit(v8(1)+
                 v8(0)shl 8+
                 s7(2)shr 2 shl 16+
                 sk8(3)shl 24+
                 optionBit('slc')shl 22+  //bit21: unknown
                 optionBit('tfe')shl 23);
            if immeds<>nil then error('imm32 not allowed in MTBUF');
          end;
        MUBUF:if {ir.pfmt='v0, v0, s[0:3], s0'}true{almost all MUBUF is the same, except 1 graphics thing} then begin
            emitcode(optionInt('offset') {12bit}
                    +optionBit('offen')shl 12
                    +optionBit('idxen')shl 13
                    +optionBit('glc')shl 14              //[UNTESTED]
                    +swGCN3(0, optionBit('adr64')shl 15) //[UNTESTED]
                    +optionBit('lds')shl 16              //[UNTESTED]
                    +swGCN3(optionBit('slc'), optionBit('ls')) shl 17);    //[UNTESTED]
            emit(v8(1)+
                 v8(0)shl 8+
                 s7(2)shr 2 shl 16+
                 sk8(3)shl 24+
                 swGCN3(optionBit('slc'), 0)shl 22+  //bit21: unknown [UNTESTED]
                 optionBit('tfe')shl 23);            //[UNTESTED]
            if immeds<>nil then error('imm32 not allowed in MUBUF');
          end;
        XOP:encodeXOP;
      end;

      if not handled then
        error('unhandled instr encoding: '+GetEnumName(TypeInfo(TIsaInstrEncoding),ord(ir.enc))+' pfmt "'+ir.pfmt+'"');

      //VOP3:no immeds
      if(immeds<>nil)and(ir.enc=VOP3)then error('VOP3: no immed32 allowed');

      //VOP3only options
      if(ir.enc<>VOP3)then begin
        if ParamNeg<>0 then error('neg() source modifier is VOP3 exclusive');
        if ParamAbs<>0 then error('abs() source modifier is VOP3 exclusive');
        if hasOption('clamp') then error('CLAMP is VOP3 exclusive');
        if hasOption('mul')or hasOption('div')then error('OMOD is VOP3 exclusive');
      end;

      //VOP limit S reads to one
      if ir.enc in[VOP2,VOP3,VOPC]then begin
        j:=0;
        for i:=1 to min(paramCount,4{v_addc-nel ne anyazzon})-1 do if charn(ParamStr(i),1)in['s','S'] then inc(j);
        if j>1 then Error('VOP: only one S reads allowed');  //!!!! Megj: ez igy nem teljesen ok, lehet 2 s-read is, de csak egy reg-bol.
      end;

      //check for invalid options
      if(ir.enc=VOP3)then hasOption('vop3'); //mark that vop3 option is legal
      for i:=0 to high(line.optUsed)do if not line.optUsed[i]then
        Error('Invalid option "'+line.optNames[i]+'"');

      //emit immeds
      for i in immeds do Emit(i);
      immeds:=nil;

    end;
    RelocateLabelReferences;
  except
    on e:exception do raise Exception.Create('CompileISA79xx error (line:'+tostr(actline)+'): '+e.ClassName+' '+e.Message+' "'+s+'"');
  end;

  Aliases.CheckFinalScope;

  result:=DataToStr(pointer(ISACode.FItems)^,ISACode.Count*4);

  //produce data for disassembler
  ARawWithoutData:=applyDataRanges(result);
end;


////////////////////////////////////////////////////////////////////////////////
///  GCN macro generator (_if, _while, etc.)                                 ///
////////////////////////////////////////////////////////////////////////////////

type TMGStackRec=record what, s1, s2, s3:ansistring; id:integer end;
     PMGStackRec=^TMGStackRec;
var MGStack:array of TMGStackRec;
var MGId:integer;

procedure MGStackAppend(const AWhat:ansistring; const AS1:ansistring=''; const AS2:ansistring=''; const AS3:ansistring='');
begin
  setlength(mgStack, length(mgStack)+1);
  with mgStack[high(mgStack)]do begin
    what:=AWhat;
    s1:=AS1;
    s2:=AS2;
    s3:=AS3;
    id:=mgId;
  end;
  inc(mgId);
end;

function MGStackPeek:PMGStackRec;
begin
  if MGStack=nil then raise Exception.Create('MGStackPeek(): stack is empty');
  result:=@MGStack[high(MGStack)];
end;

procedure MGStackPop;
begin
  setlength(MGStack, length(MGStack)-1);
end;

function GCN_MacroGen(const what:ansistring; const params:TArray<ansistring>):ansistring;

  function paramStr(n:cardinal):ansistring;
  begin
    if n<cardinal(length(params))then result:=params[n]
                                 else result:='';
  end;

  const ValidTypes:array[0..8]of ansistring=('','si32','su32','vi32','vu32','vi64','vu64','vf32','vf64');

  procedure CheckValidType(const t:ansistring);
  var s:ansistring;
  begin
    for s in ValidTypes do if cmp(t,s)=0 then exit;
    raise Exception.Create('Invalid type: "'+t+'"');
  end;

  const        CondFlags:array[0..5]of ansistring=('vccz','vccnz','execz','execnz','scc0','scc1');
  const inverseCondFlags:array[0..5]of ansistring=('vccnz','vccz','execnz','execz','scc1','scc0');

  procedure CheckValidCondFlag(const f:ansistring);
  var s:ansistring;
  begin
    for s in CondFlags do if cmp(f,s)=0 then exit;
    raise Exception.Create('Invalid conditional flag: "'+f+'"');
  end;

  function InverseCondFlag(const f:ansistring):ansistring;
  var i:integer;
  begin
    for i:=0 to high(CondFlags)do if cmp(f,condFlags[i])=0 then exit(inverseCondFlags[i]);
    raise Exception.Create('Invalid conditional flag: "'+f+'"');
  end;


var
  expr:TExpr;
  smallconstants:boolean;

  function nodeToStr(const n:TNodeBase;const isFloat:boolean):ansistring;
  var v:variant;
  begin
    if(n is TNode_Index)and(n.SubNode(0)is TNodeIdentifier)and(n.SubNode(1).SubNodeCount=1)then begin  { x[n] }
      v:=n.SubNode(1).SubNode(0).Eval(expr._Context);
      result:=TNodeIdentifier(n.SubNode(0)).IdName+'['+toStr(v)+']';
    end else if(n is TNodeIdentifier)and(n.SubNodeCount=0)then  { x }
      result:=TNodeIdentifier(n).IdName
    else begin { n }
      v:=n.Eval(expr._Context);
      result:=v;

      if isFloat then begin
        if pos('.',result)<=0 then result:=result+'.0'; //floatify
      end else begin
        if pos('.',result)>0 then raise Exception.Create('integer constant expected, not float ('+result+')');
      end;

      if not(VarIsOrdinal(v)and(v>=Low(SmallInt))and(v<=High(SmallInt)))then smallconstants:=false;
    end;
  end;

  function getRelCode(const n:TNodeBase):ansistring;
  const names:array[0..5,0..1]of ansistring=(
    ('TNodeEqual'         ,'eq'),
    ('TNodeNotEqual'      ,'lg'),
    ('TNodeGreater'       ,'gt'),
    ('TNodeGreaterEqual'  ,'ge'),
    ('TNodeLess'          ,'lt'),
    ('TNodeLessEqual'     ,'le'));
  var s:ansistring;
      i:integer;
  begin
    if n<>nil then s:=n.className;
    for i:=0 to high(names)do if names[i,0]=s then exit(names[i,1]);
    raise Exception.Create('getRelCode() unknown relation class: "'+s+'"');
  end;

var labelPrefix:ansistring;
    left, right:TNodeBase;
    sleft,sright:ansistring;
    typ,rel,schk:ansistring;
    isFloat:boolean;

  procedure PrepareRelation;
  begin
    if typ='' then raise Exception.Create('Fatal error: PrepareRelation() nothing to prepare');

    expr:=TExpr.Create(rel, [], 'GCN_MacroGen');
    if not((expr._Node<>nil)and(expr._Node is TNodeRelation))then raise Exception.Create('relation expression expected');
    left:=expr._Node.SubNode(0);
    right:=expr._Node.SubNode(1);
    if typ[1]='s' then begin //s_cmp
      smallconstants:=true; //nodeToStr updates it
      sleft:=nodeToStr(left,false);
      sright:=nodeToStr(right,false);
    end else begin //v_cmp
      isFloat:=typ[2]='f';
      sleft:=nodeToStr(left,isFloat);
      sright:=nodeToStr(right,isFloat);
    end;
  end;


begin
  result:='';
  expr:=nil;
  try
    labelPrefix:='@_macrogen'+tostr(mgId);

    if what='reset' then begin
      mgStack:=nil;
      mgId:=0;
    end else if what='if' then begin
      typ:=paramstr(0); CheckValidType(typ);  //vf64, su32, ...
      rel:=paramstr(1);

      if typ='' then begin
        CheckValidCondFlag(rel);
        result:='s_cbranch_'+InverseCondFlag(rel)+' '+labelPrefix+'a ';
        mgStackAppend('if',
          's_branch '+labelPrefix+'b '+labelPrefix+'a:', //else
          labelPrefix+'b:', //endif
          labelPrefix+'a:') //endif without else
      end else begin
        prepareRelation;
        if typ[1]='s' then begin //s_cmp
          result:='s_cmp'+switch(smallConstants,'k')+'_'+getRelCode(expr._node)+'_'+copy(typ,2)+' '+sleft+','+sright+' '+
                  's_cbranch_scc0 '+labelPrefix+'a ';
          mgStackAppend('if',
            's_branch '+labelPrefix+'b '+labelPrefix+'a:', //else
            labelPrefix+'b:', //endif
            labelPrefix+'a:') //endif without else
        end else begin //v_cmp
          result:='enter  s_temp _macroGenSavedExec align:2'+
                  'v_cmp_'+getRelCode(expr._node)+'_'+copy(typ,2)+' vcc,'+sleft+','+sright+' '+
                  's_and_saveexec_b64 _macroGenSavedExec, vcc '+
                  's_cbranch_scc0 '+labelPrefix+'a ';
          mgStackAppend('if',
          labelPrefix+'a:  s_xor_b64 exec, exec, _macroGenSavedExec  s_cbranch_scc0 '+labelPrefix+'b ', //else
          labelPrefix+'b:  s_mov_b64 exec, _macroGenSavedExec  leave', //endif
          labelPrefix+'a:  s_mov_b64 exec, _macroGenSavedExec  leave') //endif without else
        end;
      end;
    end else if what='else' then with MGStackPeek^ do begin
      if what<>'if' then raise Exception.Create('Invalid use of "_else"');
      if s1='' then raise Exception.Create('"_else" already used.');
      result:=s1;
      s1:='';
      s3:='';
    end else if what='endif' then with MGStackPeek^ do begin
      if what<>'if' then raise Exception.Create('Invalid use of "_else"');
      if(s3='')then result:=s2 else result:=s3;
      MGStackPop;
    end else if what='repeat' then begin
      typ:=paramstr(0);
      result:=switch(typ='v','enter  s_temp _macroGenSavedExec align:2  s_mov_b64 _macroGenSavedExec, exec  ')+labelPrefix+'a: ';
      mgStackAppend('repeat', labelPrefix+'a', paramstr(0));
    end else if what='until' then with MGStackPeek^ do begin
      if what<>'repeat' then raise Exception.Create('Invalid use of "_until"');
      typ:=paramstr(0); CheckValidType(typ);  //vf64, su32, ...
      rel:=paramstr(1);
      if typ='' then begin
        CheckValidCondFlag(rel);
        result:='s_cbranch_'+InverseCondFlag(rel)+' '+s1;
      end else begin
        prepareRelation;
        if typ[1]<>s2 then raise Exception.Create('repeat-until vertex/scalar mismatch.');
        if typ[1]='s' then begin //s_cmp
          result:='s_cmp'+switch(smallConstants,'k')+'_'+getRelCode(expr._node)+'_'+copy(typ,2)+' '+sleft+','+sright+' '+
                  's_cbranch_scc0 '+s1+' ';
        end else begin //v_cmp
          result:='v_cmp_'+getRelCode(expr._node)+'_'+copy(typ,2)+' vcc,'+sleft+','+sright+' '+
                  's_andn2_b64 exec, exec, vcc '+
                  's_cbranch_execnz '+s1+' '+
                  's_mov_b64 exec, _macroGenSavedExec '+
                  'leave ';
        end;
      end;
      MGStackPop;
    end else if what='while' then begin
      typ:=paramstr(0); CheckValidType(typ);  //vf64, su32, ...
      rel:=paramstr(1);
      if typ='' then begin
        CheckValidCondFlag(rel);
        result:='s_cbranch_'+InverseCondFlag(rel)+' '+labelPrefix+'b '+
                labelPrefix+'a: ';
        mgStackAppend('while',
          's_cbranch_'+rel+' '+labelPrefix+'a  '+labelPrefix+'b: ');
      end else begin
        prepareRelation;
        if typ[1]='s' then begin //s_cmp
          schk:='s_cmp'+switch(smallConstants,'k')+'_'+getRelCode(expr._node)+'_'+copy(typ,2)+' '+sleft+','+sright+' ';
          result:=schk+
                  's_cbranch_scc0 '+labelPrefix+'b '+
                  labelPrefix+'a: ';
          mgStackAppend('while',
            schk+
            's_cbranch_scc1 '+labelPrefix+'a '+
            labelPrefix+'b: ');
        end else begin //v_cmp
          result:='v_cmp_'+getRelCode(expr._node)+'_'+copy(typ,2)+' vcc,'+sleft+','+sright+' '+
                  's_cbranch_vccz '+labelPrefix+'b '+
                  'enter  s_temp _macroGenSavedExec align:2 '+
                  's_and_saveexec_b64 _macroGenSavedExec, vcc '+
                  labelPrefix+'a: ';
          mgStackAppend('while',
            'v_cmp_'+getRelCode(expr._node)+'_'+copy(typ,2)+' vcc,'+sleft+','+sright+' '+
            's_and_b64 exec, exec, vcc '+
            's_cbranch_execnz '+labelPrefix+'a '+
            's_mov_b64 exec, _macroGenSavedExec '+
            'leave '+
            labelPrefix+'b: ');
        end;
      end;
    end else if what='endw' then with MGStackPeek^ do begin
      if what<>'while' then raise Exception.Create('Invalid use of "_else"');
      result:=s1;
      MGStackPop;
    end else
      raise Exception.Create('unknown command:"'+what+'"');
  except on e:exception do raise Exception.Create('GCN_MacroGen error: '+e.ClassName+' '+e.Message); end;

  //cleanup
  FreeAndNil(Expr);
end;

////////////////////////////////////////////////////////////////////////////////
///  ISA79xx make/build  DEPRECATED, 11.12 exclusive 7970 driver only        ///
////////////////////////////////////////////////////////////////////////////////

var
  _Isa79xxCalPrototype:RawByteString;
const
  _Isa79xxCalPrototypeCompressed:RawByteString=
'Y\ [xúÌôKO'#19'Q'#20'«œLß<'#10'H° E'#5'™¢¢`≠X≈'#23#10'ÚÆ(*>'#9'Â!ê('#26'©'#4#23'∆¬ÇƒÑƒ'#7#27#23'&òË'#7'pa‚'#18'„G0¨uc¢â_ÅÖÁŒ¸Kßeå'#24'£.<ˇ‰ˆ7Á‹sOœúπô≈ù'#7'-ù≠ö¶'#13'jdIß˚î∏'#14'Û®dC3Ø'#3'‰¶*Ú∞•'#19'›^§§™(U'#6'è7z“^“RÁï˘⁄H⁄/}÷∞ØÔˆ'#39'ÌY˜ ı'+
'ü í∂œgçÑJm5Ã'#23'[æu∂ºÛâ‹¡ÒëÒÿùX¥üÇ±°…'#24#5#7'£±({Ô›4}ò[µT].õΩD+{£îÉÿÑT/æ:ƒ'#21'§≈=„>ƒ'#11'Scî]BÍπ%ÂÁ˚'#11'1›∂ı^'#30#21'iıµ˚≠Z~VüÍuœ*Í´+_]}oCV}Ÿ?©ÔK»πæ,PÂl<€'#17'hjÏ\ˆπ“|^åÑœ.7r'#25#24'ˆò,[L˙d8¯2”|'#6'r8ÂÃNãU√ì'#22'´€‚s'#28'rÁ˝ wÆCmöÉoçCŒ'+
'|áúq≤û≥Sˇ˛ôt'#23'Mò'#23#21'ÜÍì™[=ß@◊ù—·—±ËçŒ°±·ÿH}m'#30'=]‰'#29'—@V'#15'‘¯»£Õ\€åΩWC˜ÃπÄi€˜Èsƒ'#25' ôq}T¿'#13'y®Ÿs4cEØA¯ü'#39'¥r^≠U˙l˛ﬁZûS˘'#18'1’‰¸Œ'#16'âD"ëH$'#18'âD"ëH$'#18'â˛§RèΩÊ'#25'hR'#30'¢ª—â'#16#13'Ùá‰xˆWég'#31'ªRègπ'#25'q’#ç©ÚË^Û'#4+
'ñ\∞'#13'–ÕT5d`>ìi÷ä˘lÃ{º÷â|'#14'S˝w.ÊÛ∞n'#13'ò'#15'z¡'#2'∞'#16'ÙÅE`1∏'#22','#1'˝`)∏'#14'\'#15'n'#0'À¿r∞'#2#12'Ä'#27'¡M‡f∞'#18'‹'#2'n'#5'∑ÅU‡vp'#7'X'#13'÷Ä;¡ ∏'#11#12'Åª¡Zp'#15#24#6'˜Ç˚¿:p?x'#0'<'#8#30#2#15'Éı‡'#17'(ÿ'#0'6b'#31#28'c'#22'1'#7+
'¸'#20'øŒ'#28'd™'#13'”ƒ˛wl7#æ%ÒúÇD/|‹g¢xÉÍ3SÌØr∞—è~√nÚ[lÜø'#5'l'#5'€¿v∞'#3'åÄ«¡N'#4'x'#18'Ï'#2'OÅß¡3`7x'#22'<'#7'û'#7'/Ä=‡E'#18'x'#25'º'#2'^'#5'ØÅΩ`'#31#24#5'˚A'#15'˙0â~M©/'#30'<3m}˘¯Ìœ%i_>ˇ∫f'#12'#<£Îa›•G¯Â'#27'°ºÜ˜'#15'hv°êÙ9]”Ê∏÷9Æq ´n}'+
'Ü'#30'Òí»4Èa#õÃ8~'#3'|P7¡}âê˜’7ç¥8['#11'ˇ¯∂D"ëH$'#18'âD"ëH$'#18'âDˇô~·ÛƒwaçÈ˘';

function MakeIsa79xxCalELF(const ACode:rawbytestring;const ALiteralConsts:TLiteralConsts;const AOptions:TIsa79xxOptions):RawByteString;
var incrValue:integer;

  procedure incr(ofs:integer);
  begin inc(PInteger(psucc(pointer(result),ofs))^,incrValue);end;

  procedure setv(ofs,val:integer);
  begin PInteger(psucc(pointer(result),ofs))^:=val;end;

  procedure addv(ofs,val:integer);
  begin inc(PInteger(psucc(pointer(result),ofs))^,val);end;

begin
  if _Isa79xxCalPrototype='' then begin
    {//writer
    _Isa79xxPrototype:=TFile('c:\HetLib\hardware\isa79xx_prototype\compiled_isa.elf');
    TFile('c:\a.crc').Write(ToStr(crc32(_Isa79xxPrototype)));
    TFile('c:\a.a').Write(ToPas(ZCompress(_Isa79xxPrototype),240));}

    _Isa79xxCalPrototype:=ZDecompress(_Isa79xxCalPrototypeCompressed);
    TFile('c:\a.a').Write(_Isa79xxCalPrototype);
    if crc32(_Isa79xxCalPrototype)<>1719248204 then
      raise Exception.Create('FATAL ERROR: MakeIsa79xxELF() crc check failed');
  end;

  result:=copy(_Isa79xxCalPrototype,1,$1DDF)+ACode
         +copy(_Isa79xxCalPrototype,1+$1DDF+$58{prototype code len});
  incrValue:=length(ACode)-$58;

  incr(  $C4);//prog4.filesize
  incr(  $C8);//prog4.memsize
  incr(  $F4);//prog0 typ70000002 isa block size
  incr( $228);//sec6.data size
  incr( $24C);//sec7.data ofs
  incr( $274);//sec8.symtab ofs
  incr( $29C);//sec9.strtab ofs
  with AOptions do begin
    setv( $398,cb0sizeDQWords);
    setv($1937,cb0sizeDQWords);
    setv($1B9B,NumVgprs);
    setv($1BA3,NumSgprs);
    setv($1BDB,NumThreadPerGroup.x);
    setv($1BE3,NumThreadPerGroup.y);
    setv($1BEB,NumThreadPerGroup.z);
    addv($1BD3,(ldsSizeBytes+255)shr 8{256byte granularity} shl 15);
  end;

  result:=Result+LiteralConstsToStr(ALiteralConsts);

  DebugFileWrite('makeisa79xx.elf',result);
end;

function BuildIsa79xxCalElf(const AISASource:ansistring; const isGCN3:boolean):RawByteString;
var lits:TLiteralConsts;
    opts:TIsa79xxOptions;
    raw, rawDisasm:RawByteString;
begin
  raw:=CompileISA79xx(AISASource,isGCN3,lits,opts,rawDisasm);
  result:=MakeIsa79xxCalELF(raw,lits,opts);
end;

////////////////////////////////////////////////////////////////////////////////
///  hetCAL wrapper classes                                                  ///
////////////////////////////////////////////////////////////////////////////////

{ TCalObject }

procedure TCalObject.Activate;
begin
  if not Active then _Activate;
end;

procedure TCalObject.Deactivate;
begin
  if Active then begin
    _Deactivate;
    FHandle:=0;
  end;
end;

function TCalObject.GetActive: boolean;
begin
  result:=FHandle<>0;
end;

function TCalObject.GetHandle: CALuint;
begin
  if FHandle=0 then
    _Activate;
  result:=FHandle;
end;

procedure TCalObject.SetActive(const Value: boolean);
begin
  if Value=Active then exit;
  if Value then _Activate
           else _Deactivate;
end;

destructor TCalObject.Destroy;
begin
  Deactivate;
  inherited;
end;

{ TCalDevice }

constructor TCalDevice.Create(AOwner:THetObject;AId:integer);
begin
  inherited Create(AOwner);
  FDeviceId:=AId;
end;

procedure TCalDevice._Activate;
begin
  calCheck(calDeviceOpen(FHandle,FDeviceId),'calDeviceOpen');
end;

procedure TCalDevice._Deactivate;
var c:TCalContext;
    r:TCalResource;
begin
  for r in Resources do r.Deactivate;
  for c in Contexts do c.Deactivate;
  calCheck(calDeviceClose(FHandle),'calDeviceClose');
end;

function TCalDevice.Description: ansistring;
begin
  result:=DevAttr.description;
end;

destructor TCalDevice.Destroy;
begin
  inherited;
end;

function TCalDevice.DevAttr: PCALdeviceattribs;
begin
  if FDevAttr.struct_size=0 then begin
    FDevAttr.struct_size:=SizeOf(FDevAttr);
    calDeviceGetAttribs(FDevAttr,FDeviceId);
  end;
  result:=@FDevAttr;
end;

function TCalDevice.DevInfo: PCALdeviceinfo;
begin
  if FDevInfo.maxResource1DWidth=0 then
    calDeviceGetInfo(FDevInfo,FDeviceId);
  result:=@FDevInfo;
end;

function TCalDevice.DevStat: CALdevicestatus;
begin
  Result.struct_size:=SizeOf(Result);
  calDeviceGetStatus(Result,Handle);
end;

function TCalDevice.dump: ansistring;
begin
  result:='CALDevice #'+tostr(FDeviceId)+' DevHandle:$'+IntToHex(FHandle,8)+#13#10+DevInfo.dump+DevAttr.dump;
  if Active then
    Result:=Result+DevStat.dump;
end;

function TCalDevice.NewContext: TCalContext;
begin
  result:=TCalContext.Create(Contexts);
end;

function TCalDevice.Context: TCalContext;
begin
  if Contexts.Count=0 then result:=NewContext
                      else result:=Contexts[0];
end;

function TCalDevice.NewResource(ALocation: TCalResourceLocation;
  AComponents, AWidth:integer;AHeight: integer=0{linear}): TCalResource;
begin
  result:=TCalResource.Create(Resources,ALocation,AComponents,AWidth,AHeight);
end;

function TCalDevice.Target: CalTarget;
begin
  result:=devattr.target;
end;

{ TCalContext }

constructor TCalContext.Create(const AOwner: THetObject);
begin
  if not(AOwner is TCalContexts)then
    raise Exception.Create('TCalContext.Create: Owner is not TCalContexts');

  inherited;
end;

function TCalContext.OwnerDevice: TCalDevice;
begin
  Result:=TCalDevice(FOwner.FOwner);
end;

procedure TCalContext._Activate;
begin
  calCheck(calCtxCreate(FHandle,OwnerDevice.Handle),'calCtxCreate');
end;

procedure TCalContext._Deactivate;
var m:TCalModule;
    i:integer;
begin
  //release allocated memory on ctx's surface
  for i:=0 to high(FCtxMems)do with FCtxMems[i] do
    try calCheck(calCtxReleaseMem(FHandle,CtxMemHandle),'calCtxReleaseMem');except end;//azert, hogy fejlesztes kozben jelezzen
  SetLength(FCtxMems,0);

  for m in Modules do m.Deactivate;
  FreeModuleCache;

  calCheck(calCtxDestroy(FHandle),'calCtxDestroy');
end;

procedure TCalContext._ResourceDeactivated(const AResource:TCalResource);
var i,j:integer;
begin
  //release getmems
  for i:=0 to high(FCtxMems)do if FCtxMems[i].Resource=AResource then begin
    try
      calCheck(calCtxReleaseMem(FHandle,FCtxMems[i].CtxMemHandle),'calCtxReleaseMem');
    finally
      for j:=i to high(FCtxMems)-1 do FCtxMems[j]:=FCtxMems[j+1];
      setlength(FCtxMems,high(FCtxMems));
    end;
  end;
end;

function TCalContext.GetCtxMemHandle(const AResource:TCalResource): CALmem;
var i:integer;
begin
  for i:=0 to high(FCtxMems)do with FCtxMems[i]do if Resource=AResource then
    Exit(CtxMemHandle);

  calCheck(calCtxGetMem(Result,Handle,AResource.Handle),'calCtxGetMem');

  setlength(FCtxMems,length(FCtxMems)+1);
  with FCtxMems[high(FCtxMems)]do begin
    Resource:=AResource;
    CtxMemHandle:=result;
  end;
end;

function TCalContext.NewModule(const AProgram: ansistring): TCalModule;
begin
  result:=TCalModule.Create(Modules,AProgram);
end;

function TCalContext.MemCopy(const ASrc, ADst: Tcalresource;const AUserData:integer=0): TCalEvent;
var Event:CALevent;
begin
  if(ASrc=nil)or(ADst=nil)then raise Exception.Create('TCalContext.MemCopy() Src or Dst is nil.');
  ASrc.UnMap;
  ADst.UnMap;
  calCheck(calMemCopy(Event,Handle,GetCtxMemHandle(ASrc),GetCtxMemHandle(ADst),0),'calMemCopy');
  result:=TCalEvent.create(self,nil,ASrc,ADst,Event,AUserData);
end;

function TCalContext.CachedModule(const FImage:RawByteString):CALmodule;
var i,h:integer;
    rec:TCachedModule;
    image:CALimage;
begin
  h:=Crc32(FImage);
  with FModuleCache do for i:=0 to Count-1 do with FItems[i]do if hash=h then exit(Handle);

  rec.hash:=h;

  calCheck(calImageRead(image,pointer(FImage),length(FImage)),'calImageRead');
  try
    calCheck(calModuleLoad(rec.handle,Handle,image),'calModuleLoad');
  finally
    calCheck(calImageFree(image),'calImageFree');
  end;

  FModuleCache.Append(rec);
  result:=rec.handle;
end;

procedure TCalContext.FreeModuleCache;
var i:integer;
begin
  with FModuleCache do for i:=0 to Count-1 do
    calCheck(calModuleUnload(Handle,FItems[i].Handle),'calModuleUnload');

  FModuleCache.Clear;
end;


{ TCalResource }

constructor TCalResource.Create(AOwner: THetObject;
  ALocation: TCalResourceLocation; AComponents, AWidth, AHeight: integer);
begin
  if not(AOwner is TCalResources)then
    raise Exception.Create('TCalResource.Create: Owner is not TCalResources');

  inherited Create(AOwner);

  FLocation:=ALocation;
  FComponents:=AComponents;
  FWidth:=AWidth;
  FHeight:=AHeight;
end;

destructor TCalResource.Destroy;
var c:TCalContext;
    m:TCalModule;
begin
  for c in OwnerDevice.Contexts do for m in c.Modules do m._ResourceDestroyed(self);
  inherited;
end;

function TCalResource.OwnerDevice: TCalDevice;
begin
  result:=TCalDevice(FOwner.FOwner);
end;

procedure TCalResource._Activate;

  procedure Error(s:ansistring);
  begin
    raise Exception.Create('TCalResource._Activate: '+s);
  end;

var is2d,isLinear:boolean;
    flags:CALuint;
    dev:CALdevice;
    format:CALformat;
    w,h:integer;
begin
  if Height<0 then Error('Invalid Height '+tostr(Height));

  is2d:=Height>1; //Linear is also 2D
  isLinear:=Height=0;

  flags:=switch(isLinear                ,CAL_RESALLOC_GLOBAL_BUFFER)
        +switch(Location=rlRemoteCached ,CAL_RESALLOC_CACHEABLE    );

  format:=CAL_FORMAT_UNORM_INT8_1;//anti hint
  case Components of
    1:format:=CAL_FORMAT_UNORM_INT32_1;
    2:format:=CAL_FORMAT_UNORM_INT32_2;
    4:format:=CAL_FORMAT_UNORM_INT32_4;
  else
    Error('Invalid componentcount '+tostr(Components));
  end;

  dev:=OwnerDevice.Handle;

  if isLinear then begin
    w:=(Width+63)and not 63;//64 elements padding
    h:=1;
  end else begin
    w:=Width;
    h:=Height;
  end;

  FSizeBytes:=w*h*Components*ComponentSize;

  if Location=rlPinned then begin
    SetLength(FPinnedData,Size+$1000);
    FPinnedPtr:=pAlignUp(pointer(FPinnedData),$1000); //4k ptr align
  end else begin
    SetLength(FPinnedData,0);
    FPinnedPtr:=nil;
  end;

  case Location of
    rlLocal:
      if is2D then calcheck(calResAllocLocal2D(FHandle,dev,Width,Height,format,flags),'calResAllocLocal2D()')
              else calcheck(calResAllocLocal1D(FHandle,dev,Width,       format,flags),'calResAllocLocal1D()');
    rlRemote,rlRemoteCached:
      if is2D then calcheck(calResAllocRemote2D(FHandle,dev,1,Width,Height,format,flags),'calResAllocRemote2D()')
              else calcheck(calResAllocRemote1D(FHandle,dev,1,Width,       format,flags),'calResAllocRemote1D()');
    rlPinned:begin
      if is2D then calcheck(calResCreate2D(FHandle,dev,FPinnedPtr,Width,Height,format,0,flags),'calResCreate2D()')
              else calcheck(calResCreate1D(FHandle,dev,FPinnedPtr,Width,       format,0,flags),'calResCreate1D()');
    end;                                 // ide nem meretet, hanem 0-t kell irni!!!!  ^
  end;

end;

procedure TCalResource._Deactivate;
var c:TCalContext;
begin
  UnMap;

  //release mem on ctx's surface
  for c in OwnerDevice.Contexts do
    c._ResourceDeactivated(self);

  calCheck(calResFree(FHandle),'calResFree');
  SetLength(FPinnedData,0);
end;

function TCalResource.Map: pointer;
begin
  Activate;
  if Location=rlPinned then exit(FPinnedPtr);

  if FMapPtr=nil then
    calCheck(calResMap(FMapPtr,FMapPitch,Handle,0),'calResMap()');

  result:=FMapPtr;
end;

procedure TCalResource.UnMap;
begin
  if FMapPtr<>nil then begin
    calResUnmap(FHandle);
    FMapPtr:=nil;
  end;
end;

procedure TCalResource.SetupLiteralConsts(const LC: TLiteralConsts);
type
  TConstArray=array[0..$FFFF]of TI4;

var i,ma:integer;
    p:^TConstArray;
begin
  if length(LC)=0 then exit;

  //check size
  ma:=0;for i:=0 to high(LC)do ma:=max(ma,LC[i].id+1);
  if ma>ComponentSize*Components*Width{*Height no cause pitch} shr 4 then
    raise Exception.Create('TCalResource.SetupLiteralConsts() cb0 buffer too small, should be '+tostr(ma)+'*16 bytes');

  p:=Map;
  for i:=0 to high(LC)do with LC[i]do
    p^[id]:=value;
end;

procedure TCalResource.WriteVArray(const Src:variant);
var P:Pointer;
    PMax:Pointer;

  procedure Advance(const size:integer);
  begin
    if cardinal(p)>=cardinal(pmax)then
      raise Exception.Create('TCalResource.WriteVar out of range');
    pinc(p,size);
  end;

  procedure Append(const V:variant);
  var i:integer;
  begin
    if VarIsArray(V)   then begin
      with VarArrayAsPSafeArray(V)^ do for i:=0 to Bounds[0].ElementCount-1 do
        Append(VarArrayAccess(v,i)^);
    end else if VarIsOrdinal(V) then begin pinteger(p)^:=TVarData(V).VInteger;Advance(4)end else
    if VarIsFloat(V)   then begin psingle(p)^ :=single(V) ;Advance(4)end else
      raise Exception.Create('TCalResource.WriteVar unhandled vartype');
  end;

begin
  P:=Map;
  PMax:=pSucc(P,Size);
  Append(Src);
end;

function TCalResource.ReadVArray(const AElementType:TElementType):variant;
var bounds:array of integer;
    src:pointer;
    dst:pvariant;
    i:integer;
begin
  src:=Map;
  SetLength(bounds,1);
  bounds[0]:=Size div ComponentSize;
  result:=VarArrayCreate(bounds,varVariant);
  with VarArrayAsPSafeArray(result)^ do begin
    dst:=Data;
    case AElementType of
      etInt:  for i:=0 to Bounds[0].ElementCount do begin dst^:=PInteger(src)^;pinc(src,4);inc(dst);end;
      etFloat:for i:=0 to Bounds[0].ElementCount do begin dst^:=PSingle (src)^;pinc(src,4);inc(dst);end;
    end;
  end;
end;

function TCalResource.ReadIntVArray:variant;
begin
  result:=ReadVArray(etInt);
end;

function TCalResource.ReadFloatVArray:variant;
begin
  result:=ReadVArray(etFloat);
end;

function TCalResource.AccessData(Elementsize,x: integer):pointer;
begin
  Activate;
  x:=x*ElementSize;
  if not InRange(x,0,Size-elementSize)then
    raise Exception.Create('TCalResourceData.AccessData() out of range '+tostr(x));
  result:=psucc(Map,x);
end;

function TCalResource.AccessDouble(x: integer): PDouble;begin result:=AccessData(8,x);end;
function TCalResource.AccessFloat(x: integer): PSingle;begin result:=AccessData(4,x);end;
function TCalResource.AccessInt(x: integer): PInteger;begin result:=AccessData(4,x);end;
function TCalResource.AccessByte(x: integer): PByte;begin result:=AccessData(1,x);end;

procedure TCalResource.SetDouble(x: integer; v: double);begin AccessDouble(x)^:=v;end;
procedure TCalResource.SetFloat(x: integer; v: single);begin AccessFloat(x)^:=v;end;
procedure TCalResource.SetInt(x, v: integer);begin AccessInt(x)^:=v;end;
procedure TCalResource.SetByte(x:integer; v: byte);begin AccessByte(x)^:=v;end;

function TCalResource.GetDouble(x: integer): Double;begin result:=AccessDouble(x)^ end;
function TCalResource.GetFloat(x: integer): Single;begin result:=AccessFloat(x)^ end;
function TCalResource.GetInt(x: integer): Integer;begin result:=AccessInt(x)^ end;
function TCalResource.GetByte(x: integer): byte;begin result:=AccessByte(x)^ end;

procedure TCalResource.ImportBitmap(const bmp: TBitmap; const ofs: integer);
begin
  if bmp<>nil then
    bmp.SaveToData(psucc(Map,ofs)^);
end;

function TCalResource.ExportBitmap(const ofs, w, h, bpp: integer): TBitmap;
begin
  result:=TBitmap.CreateFromData(psucc(Map,ofs)^,w,h,bpp);
end;

procedure TCalResource.ImportStr(const s:ansistring;const ofs:integer);
begin
  move(pointer(s)^, psucc(map,ofs)^, length(s));
end;

function TCalResource.ExportStr(const ofs,size:integer):ansistring;
begin
  setlength(result,size);
  move(psucc(map,ofs)^, pointer(result)^, size);
end;

procedure TCalResource.Clear;
begin
  FillChar(map^,Size,0);
end;


{ TCalModule }

constructor TCalModule.Create(AOwner: THetObject; const AProgram: ansistring);
begin
  if not(AOwner is TCalModules)then
    raise Exception.Create('TCalModule.Create: Owner is not TCalModules');

  inherited Create(AOwner);
  FProgram:=AProgram;
  PrepareImage;
end;

function TCalModule.OwnerContext: TCalContext;
begin
  result:=TCalContext(FOwner.FOwner);
end;

procedure TCalModule.PrepareImage;
var prg,fcc,s,firstword:AnsiString;
    i,j:integer;
    symtab_names:TArray<integer>;
    n:pansichar;
begin
  prg:=FProgram;

  //get firstword
  firstword:='';
  for i:=0 to 1000 do begin
    s:=WordAt(ListItem(prg,i,#10,true),1);
    if s<>'' then begin firstword:=s;break end;
  end;

  //if it isn't an ELF
  if iswild2('isa79??',firstword)then begin//compile ISA79xx -> ELF if needed
    prg:=Cal.BuildISA79xx(prg,false);//no GCN3 support
  end else if IsWild2('il_?s_?_?',firstword)then begin//compile HetIL -> ELF if needed
    prg:=Cal.BuildIL(prg,OwnerContext.OwnerDevice.DevInfo.target,true);
  end else if IsWild2('mdef',firstword)then begin//OpenCL's il
    prg:=Cal.BuildIL(prg,OwnerContext.OwnerDevice.DevInfo.target,false);
  end;

  //get LiteralConsts if any
  prg:=StripLiteralConsts(prg,FLiteralConsts);

  //check valid ELF
  fcc:=FourCC(prg);
  if(length(prg)<SizeOf(TElfHdr))or(fcc<>_ElfMagic) then
    raise Exception.Create('TCalModule.PrepareImage() invalid ELF image');

  //get symbol name indices
  setlength(symtab_names,0);
  with PElfHdr(pointer(prg))^ do for i:=shdrcnt-1 downto 0 do if shdrname(i)='.symtab' then begin
    s:=SectionContents(i);
    setlength(symtab_names,length(s)div 16{symtab_recSize});
    for j:=0 to high(symtab_names)do
      symtab_names[j]:=pinteger(psucc(pointer(s),16*j))^;
    break;
  end;

  //get symbol names form .strtab
  setlength(FSymbols,0);
  with PElfHdr(pointer(prg))^ do for i:=shdrcnt-1 downto 0 do if shdrname(i)='.strtab' then begin
    s:=SectionContents(i);
    if pointer(s)<>nil then for j:=0 to high(symtab_names)do begin
      n:=psucc(pointer(s),symtab_names[j]);
      if n<>'' then begin
        SetLength(FSymbols,length(FSymbols)+1);
        with FSymbols[High(FSymbols)]do begin
          Symbol:=n;
          Resource:=nil;
          name:=0;
        end;
      end;
    end;
    break;
  end;

  FCB0SymbolIdx:=FindSymbolIdx('cb0');
  FCB2SymbolIdx:=FindSymbolIdx('cb2');

  FImage:=prg;

  DebugFileWrite('ISA_Disasm.txt',Disasm);
end;

procedure TCalModule._Activate;
var image:CALimage;
    i:integer;
begin
{$IFNDEF MODULECACHE}
  calCheck(calImageRead(image,pointer(FImage),length(FImage)),'calImageRead');
  try
    calCheck(calModuleLoad(FHandle,OwnerContext.Handle,image),'calModuleLoad');
  finally
    calCheck(calImageFree(image),'calImageFree');
  end;
{$ELSE}
  FHandle:=OwnerContext.CachedModule(FImage);
{$ENDIF}
  //get symbolnames, entry
  for i:=0 to High(FSymbols)do
    calCheck(calModuleGetName(FSymbols[i].name,OwnerContext.Handle,Handle,PAnsiChar(FSymbols[i].Symbol)),'calModuleGetName');
  calCheck(calModuleGetEntry(FEntry,OwnerContext.Handle,Handle,'main'),'calModuleGetEntry');
end;

procedure TCalModule._Deactivate;
var i:integer;
begin
{$IFNDEF MODULECACHE}
  if OwnerContext.Active then
    calCheck(calModuleUnload(OwnerContext.Handle,FHandle),'calModuleUnload');
{$ENDIF}
  for i:=0 to High(FSymbols)do
    FSymbols[i].name:=0;
  FEntry:=0;
end;

procedure TCalModule._ResourceDestroyed(const AResource: TCalResource);
var i:integer;
begin
  for i:=0 to high(FSymbols)do
    if FSymbols[i].Resource=AResource then
      FSymbols[i].Resource:=nil;
end;

function TCalModule.SymbolCount: integer;
begin
  result:=length(FSymbols);
end;

var _Disasm:ansistring;
procedure _DisasmLogFunc(const msg:PAnsiChar);cdecl;
begin
  _Disasm:=_Disasm+msg;
end;

function TCalModule.Disasm: ansistring;
var image:CALimage;
begin
  result:='';
  if FImage='' then exit;
  calCheck(calImageRead(image,pointer(FImage),length(FImage)),'calImageRead');
  try
    _Disasm:='';
    calclDisassembleImage(image,@_DisasmLogFunc);
    result:=_Disasm+#13#10';-------- Metrics ---------'#13#10';'
           +Cal.ISAMetrics(_Disasm).AsString+#13#10+PElfHdr(pointer(FImage)).Dump;
    _Disasm:='';
  finally
    calCheck(calImageFree(image),'calImageFree');
  end;
end;

function TCalModule.FindSymbolIdx(const AWich: variant): integer;
var i:integer;
begin
  if VarIsStr(AWich)then for i:=0 to high(FSymbols)do
    if cmp(FSymbols[i].Symbol,AnsiString(AWich))=0 then
      exit(i);
  if VarIsOrdinal(AWich)then if inrange(integer(AWich),0,high(FSymbols))then
    exit(integer(AWich));
  result:=-1;
end;

function TCalModule.GetSymbolName(const AIdx: integer): ansistring;
var i:integer;
begin
  i:=FindSymbolIdx(AIdx);
  if i>=0 then result:=FSymbols[i].Symbol
          else result:='';
end;

function TCalModule.GetSymbolResource(const AWich: variant): TCalResource;
var i:integer;
begin
  i:=FindSymbolIdx(AWich);
  if i>=0 then result:=FSymbols[i].Resource
          else result:=nil;
end;

function TCalModule.GetWaveFrontSize: integer;
begin
  if FImage='' then raise exception.Create('TCalModule.GetWaveFrontSize() no Image loaded.');
  result:=PElfHdr(pointer(FImage)).GetNotes.NumThreadPerGroup;
end;

procedure TCalModule.SetSymbolResource(const AWich: variant; const ARes: TCalResource);

  function syms:ansistring;
  var i:integer;
  begin
    result:='';
    for i:=0 to SymbolCount-1 do
      ListAppend(result,SymbolName[i],', ');
  end;

var i:integer;
begin
  i:=FindSymbolIdx(AWich);
  if i<0 then raise Exception.Create('TCalModule.SetSymbolResource() Cannot access symbol '+ansistring(AWich)+' (there are: '+syms+')');
{ resource on another device: majd szol a cal inkabb
  if ARes.OwnerDevice<>OwnerContext.OwnerDevice then
    raise Exception.Create('TCalModule.SetSymbolResource() Cannot link resouce located on another device.');}

  //uav componentcount check (5xxx-en valami bug* miatt csak 1 dword komponens lehet
     //bug*: 4 komponensnel csak 1/4 ramot foglal
  if(ARes<>nil)and(IsWild2('uav*',FSymbols[i].Symbol))and(ARes.Components<>1)then
    raise Exception.Create('TCalModule.SetSymbolResource() UAV resource.componentcount must be 1');

  FSymbols[i].Resource:=ARes;
end;

function TCalModule._Run(const AWidth, AHeight, AUserData:integer; ARunGrid:boolean): TCalEvent;
var i:integer;
    Domain:CALdomain;
    Event:CALevent;
    gr:CALprogramGrid;
begin
  //check errors
  for i:=0 to high(FSymbols)do with FSymbols[i]do
    if Resource=nil then raise Exception.Create('TCalModule.Run() Symbol "'+Symbol+'" has no resource linked to');

  if not ARunGrid then
    with OwnerContext.OwnerDevice.DevInfo^ do begin
      if not InRange(AWidth,0,maxResource2DWidth)then
        raise Exception.Create('TCalModule.Run() Width out of range');
      if not InRange(AHeight,0,maxResource2DHeight)then
        raise Exception.Create('TCalModule.Run() Height out of range');
    end;

  //upload module
  Activate;

  //setup cb0 literalConsts if any
  if FLiteralConsts<>nil then begin
    i:=FCB2SymbolIdx;//CL compatible kernel
    if i<0 then i:=FCB0SymbolIdx;
    if i>=0 then FSymbols[i].Resource.SetupLiteralConsts(FLiteralConsts)
  end;

  //unmap all resources
  for i:=0 to high(FSymbols)do with FSymbols[i]do Resource.UnMap;

  //link symbols
  for i:=0 to high(FSymbols)do with FSymbols[i]do
    calCheck(calCtxSetMem(OwnerContext.Handle,Name,OwnerContext.GetCtxMemHandle(Resource)),'calCtxSetMem()');

  Event:=0;
  if ARunGrid then begin
    fillchar(gr,sizeof(gr),0);
    gr.func:=FEntry;
    gr.gridBlock.width:=GetWaveFrontSize{from kernel}; {OwnerContext.OwnerDevice.DevAttr.wavefrontSize}
    gr.gridBlock.height:=1;
    gr.gridBlock.depth:=1;
    gr.gridSize.width:=(cardinal(AWidth*AHeight)+(gr.gridBlock.width-1))div gr.gridBlock.width;
    gr.gridSize.height:=1;                     //CEIL!!!!!!
    gr.gridSize.depth:=1;
    gr.flags:=0;
    calCheck(calCtxRunProgramGrid(Event,OwnerContext.Handle,gr),'calCtxRunProgramGrid()');
  end else begin
    Domain.setup(0,0,AWidth,AHeight);
    calCheck(calCtxRunProgram(Event,OwnerContext.Handle,FEntry,Domain),'calCtxRunProgram()');
  end;

  Result:=TCalEvent.create(OwnerContext,Self,nil,nil,Event,AUserData);
end;

function TCalModule.Run(const AWidth, AHeight:integer;const AUserData:integer=0): TCalEvent;
begin
  result:=_Run(AWidth,AHeight,AUserData,false);
end;

function TCalModule.RunGrid(const AWidth, AHeight:integer;const AUserData:integer=0): TCalEvent;
begin
  result:=_Run(AWidth,AHeight,AUserData,True);
end;

{ TCalEvent }

constructor TCalEvent.create(AContext:TCalContext; AModule:TCalModule; AResSrc, AResDst:TCalResource; AEvent:CALevent; AUserData:integer);
var FR:Int64;
begin
  inherited create(Cal.Events);
  FContext:=AContext;
  FModule:=AModule;
  FResSrc:=AResSrc;
  FResDst:=AResDst;
  FUserData:=AUserData;

  FEvent:=AEvent;
  FCtx:=FContext.Handle;

  QueryPerformanceFrequency(FR);invFR:=1/FR;
  QueryPerformanceCounter(T0);T1:=T0;
  FRunning:=true;
end;

procedure TCalEvent.CheckEvent;
var res:CALresult;
begin
  if FRunning then begin
    res:=calCtxIsEventDone(FCtx,FEvent);
    if res<>CAL_RESULT_PENDING then begin
      FRunning:=false;
      FSuccess:=res=CAL_RESULT_OK;
      QueryPerformanceCounter(T1);
    end;
  end;
end;

function TCalEvent.ElapsedTime_sec: single;
begin
  CheckEvent;
  if FRunning then
    QueryPerformanceCounter(T1);

  result:=(T1-T0)*invFR;
end;

function TCalEvent.Running: boolean;
begin
  CheckEvent;
  result:=FRunning;
end;

function TCalEvent.Finished: boolean;
begin
  CheckEvent;
  result:=not Running;
end;

procedure TCalEvent.WaitFor;
begin
  while Running do;
end;

function TCalEvent.Success: boolean;
begin
  WaitFor;
  result:=FSuccess;
end;

////////////////////////////////////////////////////////////////////////////////
///  CAL wrapper base object                                                 ///
////////////////////////////////////////////////////////////////////////////////

class function Cal.Devices:TCalDevices;
var i:integer;
    cnt:CALuint;
begin
  result:=FDevices;
  if Result=nil then begin
    result:=TCalDevices.Create(nil);
    FDevices:=result;

    //collect all devices
    if calInit in[CAL_RESULT_OK,CAL_RESULT_ALREADY]then begin
      calDeviceGetCount(cnt);
      for i:=0 to integer(cnt)-1 do
        TCalDevice.Create(FDevices,i);
    end;

  end;
end;

class function Cal.Events:TCalEvents;
begin
  if FEvents=nil then
    FEvents:=TCalEvents.Create(nil);
  result:=FEvents;
end;

class function Cal.BuildIL(const AKernel:AnsiString;ATarget:CALtarget;const ADoPreCompile:boolean=true):RawByteString;
var IL:ansistring;
//    _5xxVecSelCount:integer;//patch bytealign -> bfi_int
    LiteralConsts:TArray<TLiteralConst>;
begin
  result:='';
  calCheck(calInit,'Cal.Compile() No CAL present in system');

  //precompile
  if ADoPreCompile then begin
    IL:=PreCompileIL(AKernel,ATarget,literalConsts,lmCB0,false);
  end else begin
    IL:=AKernel;
    //_5xxVecSelCount:=0;
  end;

  result:=calclBuild(IL,ATarget);

  //patch Vec_Sel if needed
(*    if _5xxVecSelCount>0 then begin
    i:=PElfHdr(result)^.PatchInstrOp3(13{bytealign},6{BFI_INT});
    if _5xxVecSelCount<>i then
      raise Exception.Create('CAL compiler pre-pass: '+
        ' BFI_INT patcher error:  vec_sel='+tostr(_5xxVecSelCount)+'  patched='+toStr(i)+'  (use vec_sel_unopt to avoid optimizer related errors!)');
  end;*)

  //Insert Literals at start of image //damaging ELF, but without lits it is useless anyways
  result:=LiteralConstsToStr(LiteralConsts)+result;

  DebugFileWrite('compiled_isa.elf',result);
end;

function Cal.TIsaMetrics.AsString:ansistring;
  function p(a,b:integer):single;//percent
  begin
    if b=0 then result:=0 else result:=a/b*100;
  end;
var sum:integer;
begin
  if Clauses>0 then begin
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
  end else begin
    sum:=_7xxxV_Cnt+_7xxxS_Cnt;
    result:=format('V,S,,All: (%5d,%5d,%5d) (%5.2f,%5.2f)%%',
      [_7xxxV_Cnt,_7xxxS_Cnt,sum,
       p(_7xxxV_Cnt,sum),p(_7xxxS_Cnt,sum)]);
  end;
end;

class function cal.ISAMetrics(const ISACode:ansistring):TIsaMetrics;
var line:ansistring;
    i:integer;
    isClause,isInstr,isSlot:Boolean;
begin with result do begin
  VLIWSize:=4;Clauses:=0;Groups:=0;Instructions:=0;PReads:=0;PWrites:=0;VECs:=0;Reads:=0;Literals:=0;
  BYTE_ALIGN_INT_cnt:=0;BFI_INT_cnt:=0;

  _7xxxV_Cnt:=0;_7xxxS_Cnt:=0;
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

      if pos('BYTE_ALIGN_INT',line)>0 then inc(BYTE_ALIGN_INT_cnt)else
      if pos('BFI_INT',line)>0 then inc(BFI_INT_cnt)else
    end else begin
      if IsWild2('?_*',line)then case charn(line,1)of
        'v':inc(_7xxxV_Cnt);
        's':inc(_7xxxS_Cnt);
      end;
    end;

    Inc(Instructions,ord(isInstr));
    Inc(Groups,ord(isSlot));
    Inc(Clauses,ord(isClause));
  end;
end;end;

class function Cal.BuildISA79xx(const AKernel:AnsiString; const isGCN3:boolean):RawByteString;
begin
  result:=het.cal.BuildIsa79xxCalElf(Akernel, isGCN3);
end;

initialization
  het.Parser._Asm_il_syntax:=@IL_Syntax;
  het.Parser._Asm_isa_syntax:=@ISA_Syntax;
  het.MacroParser.GCN_MacroGen:=@GCN_MacroGen;
finalization
end.




