unit het.Patch; //het.variants

interface
uses windows, sysutils, classes, typinfo, het.Utils;

procedure PatchPropertySetter(pi:PPropInfo;ChangeMethod:integer;const AClassname:string);
procedure PatchRaw(const Addr:pointer;const code:rawbytestring);overload;
procedure PatchRaw(const Addr,Data:pointer;const len:integer);overload;
procedure PatchVMT(AObject:TObject;vmtold,vmtnew:cardinal);

function PatchVirtualQuery(const p:pointer;const len:integer):boolean;
function PatchGetCallAbsoluteAddress(const BaseCallAddr:pointer;const Displacement:integer=0):pointer;

function PatchFindCallAddressChain(const StartCallOffset:pointer;const RelCallOffsets:array of Const):pointer;
function PatchRelativeAddress(OffsetLocation,NewAddr:pointer;CheckOldAddr:pointer=nil):pointer;//old absolute addr
procedure PatchFunction(OldOffset,NewOffset:pointer);

function VMTIndex(const AObject:TObject;const ProcAddr:pointer):integer;overload;
function VMTIndex(const AClass:TClass;const ProcAddr:pointer):integer;overload;

type
  TCallInstr=packed record instruction:byte;offset:integer end;
  PCallInstr=^TCallInstr;

procedure PatchInitPropertySetterFunctions(HetObject_AddRef,HetObject_RemoveRef:pointer);//called from het.objects

implementation

const
  codeByte='3A90[Field]740B8890[Field]8B10FF52[Changed]C3';
  codeWord='663B90[Field]740C668990[Field]8B10FF52[Changed]C38BC0';
  codeInt='3B90[Field]740B8990[Field]8B10FF52[Changed]C3';
  codeInt64='558BEC8BC88B81[Field]8B91[Field4]3B550C75033B450874198B45088981[Field]8B450C8981[Field4]8BC18B10FF52[Changed]5DC20800';
  codeSingle='558BEC8BD0D982[Field]D85D089BDFE09E74108B45088982[Field]8BC28B10FF52[Changed]5DC20400';
  codeDouble='558BEC8BD0DD82[Field]DC5D089BDFE09E74198B45088982[Field]8B450C8982[Field4]8BC28B10FF52[Changed]5DC208008D4000';
  codeExtended='558BEC8BD0DBAA[Field]DB6D08DED99BDFE09E74248B45088982[Field]8B450C8982[Field4]668B4510668982[Field8]8BC28B10FF52[Changed]5DC20C008BC0';
  codeComp='558BEC8BD0DFAA[Field]DF6D08DED99BDFE09E74198B45088982[Field]8B450C8982[Field4]8BC28B10FF52[Changed]5DC2080090';
  codeShortString='53568BF28BD88D83[Field]8BD60FB60841E8[AStrCmp]74168D83[Field]8BD6B1[MaxLen]E8[PStrNCpy]8BC38B10FF52[Changed]5E5BC38BC0';
  codeAnsiString='53568BF28BD88B83[Field]8BD6E8[LStrEqual]74148D83[Field]8BD6E8[LStrAsg]8BC38B10FF52[Changed]5E5BC3';
  codeWideString='53568BF28BD88B83[Field]8BD6E8[WStrEqual]74148D83[Field]8BD6E8[WStrAsg]8BC38B10FF52[Changed]5E5BC3';
  codeString='53568BF28BD88B83[Field]8BD6E8[UStrEqual]74148D83[Field]8BD6E8[UStrAsg]8BC38B10FF52[Changed]5E5BC3';
  codeLinkedObj='53568BF28BD88B83[Field]3BF0742585C074078BD3E8[RemoveRef]8BC68983[Field]85C074078BD3E8[AddRef]8BC38B10FF52[Changed]5E5BC3';

var FunctionAddr:array[0..9]of cardinal;
const FunctionToken:array[0..9]of string=
  ('AStrCmp','PStrNCpy','LStrEqual','LStrAsg','WStrEqual','WStrAsg','UStrEqual','UStrAsg','AddRef','RemoveRef');

var _SStr:array[0..1]of string[5];
    _LStr:array[0..1]of ansistring;
    _WStr:array[0..1]of widestring;
    _UStr:array[0..1]of unicodestring;

{$OPTIMIZATION ON}
{$STACKFRAMES OFF}
procedure PatchInitPropertySetterFunctions(HetObject_AddRef,HetObject_RemoveRef:pointer);
  procedure test;
  begin
    if _SStr[0]<>_SStr[1] then _SStr[0]:=_SStr[1];
    if _LStr[0]<>_LStr[1] then _LStr[0]:=_LStr[1];
    if _WStr[0]<>_WStr[1] then _WStr[0]:=_WStr[1];
    if _UStr[0]<>_UStr[1] then _UStr[0]:=_UStr[1];
  end;
var i:integer;
    rel:integer;
    ofs:cardinal;
begin
  test;
  FunctionAddr[0]:=$DAA;
  FunctionAddr[1]:=$DBD;
  FunctionAddr[2]:=$DCD;
  FunctionAddr[3]:=$DDF;
  FunctionAddr[4]:=$DEF;
  FunctionAddr[5]:=$E01;
  FunctionAddr[6]:=$E11;
  FunctionAddr[7]:=$E23;
  for i:=0 to 7 do begin
    ofs:=cardinal(@test)+FunctionAddr[i]-$D9B;
    rel:=pcardinal(ofs)^;
    FunctionAddr[i]:=integer(ofs)+rel+4;
  end;
  FunctionAddr[8]:=cardinal(HetObject_AddRef);
  FunctionAddr[9]:=cardinal(HetObject_RemoveRef);
end;

{$OPTIMIZATION ON}
{$STACKFRAMES OFF}

procedure PatchVMT(AObject:TObject;vmtold,vmtnew:cardinal);
var pold,pnew:ppointer;bw:NativeUInt;
begin
  pold:=ppointer(pcardinal(AObject)^+vmtold);
  pnew:=ppointer(pcardinal(AObject)^+vmtnew);
  if pold^<>pnew^ then
    try WriteProcessMemory(GetCurrentProcess,pold,pnew,4,DWORD(bw));except on EAccessViolation do;end;
end;

function VMTIndex(const AClass:TClass;const ProcAddr:pointer):integer;
var vmt:PPointer;i:integer;
begin
  vmt:=pointer(AClass);
  for i:=0 to 999 do begin
    if ProcAddr=vmt^ then exit(i*4);
    inc(vmt);
  end;
  Assert(false,'VMTIndex() not found');
  result:=-1;
end;

function VMTIndex(const AObject:TObject;const ProcAddr:pointer):integer;
begin
  result:=VMTIndex(AObject.ClassType,ProcAddr);
end;

{var
  PatchHistory:array of record
    addr:pointer;
    data:rawbytestring;
  end;}

procedure PatchRaw(const Addr,Data:pointer;const len:integer);
var BytesWritten:NativeUInt;
    old:RawByteString;
begin
  try
    //undo
    setlength(old,len);
    try ReadProcessMemory(GetCurrentProcess,addr,pointer(old),len,DWORD(BytesWritten))except end;

    if WriteProcessMemory(GetCurrentProcess, Addr, data, len, DWORD(BytesWritten))
    and(integer(BytesWritten)=len) then begin
      //undo
{      SetLength(PatchHistory,length(PatchHistory)+1);
      PatchHistory[high(PatchHistory)].addr:=Addr;
      PatchHistory[high(PatchHistory)].data:=old;}

      FlushInstructionCache(GetCurrentProcess, Addr, len)
    end else
      raise Exception.Create('hetPropertyRig.PatchRaw() error writing code');
  except
    on EAccessViolation do ;
    else raise;
  end;
end;

procedure PatchRaw(const Addr:pointer;const code:rawbytestring);
begin
  PatchRaw(Addr,@code[1],length(code));
end;

{procedure UndoPatches;
var i:integer;
begin
  for i:=high(PatchHistory)downto 0 do with PatchHistory[i]do try PatchRaw(addr,data)except end;
  setlength(PatchHistory,0);
end;}

var codes:array of rawbytestring;

procedure PatchSetter(Addr:pointer;const FarCode:string;Field,ChangeMethod,MaxLen:integer);

var newcode:RawByteString;
  procedure AddBytes(data,len:integer);
  begin
    SetLength(newcode,length(NewCode)+len);
    move(data,newcode[length(newcode)-len+1],len);
  end;

var Field4,Field8:integer;
    code,token,s,jumpcode:RawByteString;
    inBracket:boolean;
    i,j,k:integer;
    FieldAddrBytes:integer;

    offsets:array of cardinal;
    pc:pcardinal;
begin
  Field4:=Field+4;
  Field8:=Field+8;

  FieldAddrBytes:=4;
  code:=FarCode;

  inBracket:=false;newcode:='';token:='';
  i:=1;while i<length(code)do begin
    if inBracket then begin
      if code[i]=']' then begin
        inBracket:=false;
        //processtoken
        if CompareText(token,'MaxLen')=0 then AddBytes(MaxLen,1)else
        if CompareText(token,'Field')=0 then AddBytes(Field,FieldAddrBytes)else
        if CompareText(token,'Field4')=0 then AddBytes(Field4,FieldAddrBytes)else
        if CompareText(token,'Field8')=0 then AddBytes(Field8,FieldAddrBytes)else
        if CompareText(token,'Changed')=0 then AddBytes(ChangeMethod,1)else begin
          k:=-1;for j:=0 to high(FunctionAddr) do if CompareText(token,FunctionToken[j])=0 then begin k:=j;break;end;
          Assert(k>=0,'hetPropertyRig.PatchSetter() invalid token '+token);
          setlength(offsets,length(offsets)+1);
          offsets[high(offsets)]:=length(newcode)+1;
          AddBytes(FunctionAddr[k],4);
        end;
      end else token:=token+code[i];
      inc(i);
    end else begin
      if code[i]='[' then begin
        inBracket:=true;
        token:='';
        inc(i);
      end else begin
        s:='$'+copy(code,i,2);
        j:=strtoint(s);
        AddBytes(j,1);
        inc(i,2);
      end;
    end;
  end;

  SetLength(codes,length(codes)+1);
  codes[high(codes)]:=newcode;

  for i:=0 to high(offsets)do begin
    pc:=PCardinal(@codes[high(codes)][offsets[i]]);
    pc^:=pc^-(cardinal(pc)+4);
  end;

  setlength(jumpcode,5);
  jumpcode[1]:=#$E9;
  i:=(integer(@codes[high(codes)][1]))-(integer(addr)+5);
  move(i,jumpcode[2],4);

  PatchRaw(Addr,jumpcode);
end;

procedure PatchPropertySetter(pi:PPropInfo;ChangeMethod:integer;const AClassname:string);
var td:PTypeData;
    Field:integer;
    Proc:pointer;

  procedure DoPatch(const farcode:string;MaxLen:integer=0);
  begin PatchSetter(Proc,farcode,Field,ChangeMethod,MaxLen);end;

  procedure checkUnopt;
  begin
    Assert(PByte(Proc)^=$55,'hetPropertyRig.Patch Turn off optimizations at '+AClassName+'.'+pi.name);
  end;

begin
  if(cardinal(pi.GetProc)>=$FF000000)//field get
  and(Cardinal(pi.SetProc)<$FE000000)//static setproc
  and(pi.SetProc<>nil)//has setproc
  and(cardinal(pi.Index)=  $80000000)//nonindexed
  then begin
//    if FunctionAddr[0]=0 then InitFunctions;init from het.Objects

    td:=GetTypeData(pi.PropType^);
    Field:=cardinal(pi.GetProc)and $FFFFFF;
    Proc:=pi.SetProc;

    if PByte(proc)^=$E9 then
      exit;{riggelve van eleve}

    case pi.PropType^.Kind of
      tkInteger, tkChar, tkEnumeration, tkSet, tkWChar:
        case td.OrdType of
          otSByte,otUByte:begin CheckUnopt;DoPatch(codeByte);end;
          otSWord,otUWord:DoPatch(codeWord);
          otSLong,otULong:begin CheckUnopt;DoPatch(codeInt);end;
        end;
      tkInt64:DoPatch(codeInt64);
      tkFloat:
        case td.FloatType of
          ftSingle:DoPatch(codeSingle);
          ftDouble:DoPatch(codeDouble);
          ftExtended:DoPatch(codeExtended);
          ftComp,ftCurr:DoPatch(codeComp);
        end;
      tkString:DoPatch(codeShortString,td.MaxLength);
      tkLString:DoPatch(codeAnsiString);
      tkWString:DoPatch(codeWideString);
      tkUString:DoPatch(codeString);
      tkClass:begin checkUnopt;DoPatch(codeLinkedObj);end;
    end;
  end;
end;

function PatchVirtualQuery(const p:pointer;const len:integer):boolean;
var mbi:MEMORY_BASIC_INFORMATION;
begin
  result:=(VirtualQuery(p,mbi,sizeof(mbi))>0)
       and(mbi.baseAddress<>nil)
       and(cardinal(pSucc(p,len))<=cardinal(pSucc(mbi.BaseAddress,mbi.RegionSize)));
end;

function PatchGetCallAbsoluteAddress(const BaseCallAddr:pointer;const Displacement:integer=0):pointer;
var c:PCallInstr;
begin
  c:=PCallInstr(integer(BaseCallAddr)+displacement);
  if not(c.instruction in[$E8,$E9])then raise exception.Create('PatchGetAbsoluteAddress() invalid instruction (not $E8 or $E9)');
  result:=pointer(integer(c)+1+4+c.offset);
end;

function PatchFindCallAddressChain(const StartCallOffset:pointer;const RelCallOffsets:array of Const):pointer;

  function chk(p:pointer):boolean;
  begin
    result:=PatchVirtualQuery(p,$5);
  end;

  procedure SolveJumpTable(var p:pointer);
  begin
    if chk(p)and(pword(p)^=$25FF)then //ff25 jmp [x]
      p:=ppointer(cardinal(p)+2)^;
  end;

  procedure Error(const s:string);
  begin
    Raise Exception.Create('PatchFindCallAddress() '+s);
  end;

var c:PCallInstr;
    i:integer;
begin
  if not chk(StartCallOffset) then error('invalid StartOffset');
  if length(RelCallOffsets)=0 then error('RelCallOffsets is empty');

  c:=StartCallOffset;
  for i:=0 to high(RelCallOffsets)do begin
    pInc(c,RelCallOffsets[i].VInteger);

    //when used as a .bpl, then 2nd call is an indirect jmp
    if chk(c)and(pword(c)^=$25FF)then //ff25 jmp [x]
      c:=ppointer(cardinal(c)+2)^;

    if not chk(c)then error('invalid address (rco='+tostr(i)+')');
    if not(c.instruction in[$E8,$E9])then error('invalid instruction (not $E8 or $E9) (rco='+tostr(i)+')');
    if i<high(RelCallOffsets)then c:=pointer(integer(c)+1+4+c.offset);//funct ptr
  end;

  result:=c;pInc(result);
end;

function PatchRelativeAddress(OffsetLocation,NewAddr:pointer;CheckOldAddr:pointer=nil):pointer;//kicserel egy cimet es reallokalja
var i:integer;
begin
  result:=pointer(pinteger(OffsetLocation)^+(Integer(OffsetLocation)+4));
  if(CheckOldAddr<>nil)and(CheckOldAddr<>result)then
    raise Exception.Create('PatchRelativeAddress() OldAddr check failed');

  i:=integer(NewAddr)-(Integer(OffsetLocation)+4);
  PatchRaw(OffsetLocation,@i,4);
end;

procedure PatchFunction(OldOffset,NewOffset:pointer);//eltéríti a funkciot egy jumppal
var b:byte;
begin
  if not PatchVirtualQuery(OldOffset,5)then raise Exception.Create('PatchFunction() virtual query failed');
  b:=$E9;
  PatchRaw(OldOffset,@b,1);
  PatchRelativeAddress(pSucc(OldOffset),NewOffset);
end;

initialization
  //InitFunctions; from het.Objects
finalization
  //UndoPatches; //no patch history a getmem patch miatt!!!
end.
