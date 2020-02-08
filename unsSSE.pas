unit unsSSE;
rewqre
interface

uses windows, sysutils, classes, math, het.Utils, het.Parser, variants,
  het.Variants, TypInfo, het.Objects, het.Assembler, het.Arrays, Het.FileSys;

var
  nsSSE:TNameSpace;

implementation

type
  TSSEBytes     =array[0..$f]of Byte;
  TSSEShortInts =array[0..$f]of ShortInt;
  TSSEWords     =array[0..$7]of Word;
  TSSESmallInts =array[0..$7]of SmallInt;
  TSSECardinals =array[0..$3]of Cardinal;
  TSSEIntegers  =array[0..$3]of Integer;
  TSSEInt64s    =array[0..$1]of Int64;
  TSSECar64s    =array[0..$1]of Int64;{!!!}
  TSSESingles   =array[0..$3]of Single;
  TSSEDoubles   =array[0..$1]of Double;

  TSSEData=record case integer of
    0:(Bytes:TSSEBytes);
    1:(ShortInts:TSSEShortInts);
    2:(Words:TSSEWords);
    3:(SmallInts:TSSESmallInts);
    4:(Cardinals:TSSECardinals);
    5:(Integers:TSSEIntegers);
    6:(Int64s:TSSEInt64s);
    7:(Car64s:TSSEInt64s);
    8:(Singles:TSSESingles);
    9:(Doubles:TSSEDoubles);
   10:(Immediate:byte);
  end;
  PSSEData=^TSSEData;

  TSSEDataType=(dtBytes,dtShortInts,dtWords,dtSmallInts,dtCardinals,dtIntegers,dtInt64s,dtCar64s,dtSingles,dtDoubles,dtImmediate,dtUnknown);

const
  SSEDataSize:array[TSSEDataType]of integer=
               (1      ,1          ,2      ,2          ,4          ,4         ,8       ,8      ,4        ,8        ,0           ,0);
  SSEDataCount:array[TSSEDataType]of integer=
               (16     ,16         ,8      ,8          ,4          ,4         ,2       ,2      ,4        ,2        ,0           ,0);
  SSEDataSigned:array[TSSEDataType]of boolean=
               (false  ,true       ,false  ,true       ,false      ,true      ,true    ,false  ,true     ,true     ,false       ,false);
  SSEDataIsFloat:array[TSSEDataType]of boolean=
               (false  ,false      ,false  ,false      ,false      ,false     ,false   ,false  ,true     ,true     ,false       ,false);

type TSSEOp=(soNone,
  soConst,soLoad,soStore,soMove,
  soAdd,soSub,
  soMulH,soMulHR,soMulL,soMul,
  soOr,soAnd,soXor,soShr,soShl,
  soPackSat,soUnpackLow,soUnpackHigh,
  soCmpEq,soCmpNE,soCmpGT,soCmpGE,soCmpLT,soCmpLE,
  soShuffle,
  soMax,soMin);

const
  varSSE:word=0;

type
  TSSEVariantType=class(TCustomVariantTypeSpecialRelation)
    procedure Clear(var V: TVarData); override;
    procedure Copy(var Dest: TVarData; const Source: TVarData; const Indirect: Boolean); override;
    procedure CastTo(var Dest: TVarData; const Source: TVarData; const AVarType: TVarType);override;
    procedure Cast(var Dest: TVarData; const Source: TVarData); override;
{    procedure Compare(const Left, Right: TVarData; var Relationship: TVarCompareResult);override;}
    procedure BinaryOp(var Left: TVarData; const Right: TVarData; const Operator: TVarOp);override;
    function RightPromotion(const V: TVarData; const Operator: TVarOp; out RequiredVarType: TVarType): Boolean;override;
    procedure RelationOp(var L:variant;const R:variant;const op:TVarOp);override;
  end;

type
  TSSEOperation=class(THetObject)
  private
    FSrc0,FSrc1:TSSEOperation;
    FConstValue:variant;
    FLoadStoreName:ansistring;
    FOp:TSSEOp;
    FInstr:ansistring;

    FOpHash,FAccumHash:integer;
    FUsed:boolean;

    function GetOpHash:integer;
    function GetAccumHash:integer;
  private//Core2 emu
    FAllowedRegs:integer;//bit mask
    FFullUPrg:ansistring;
    FActUPrg:ansistring;
    FRegId:integer;//-1:none,0..7:xmm,8..n:temp
    procedure CalcFullUPrg;
  public
    constructor Create(const AOwner:THetObject);override;
    procedure SwapSources;
    function GetDescription:ansistring;
    function GetAsmInstr:ansistring;
    function IsConst:boolean;
    function IsLoad:boolean;
    function IsStore:boolean;
    function IsOperation:boolean;
    function IsCommutative:boolean;
    function IsMove:boolean;
    function SrcCount:integer;
    property Operation:TSSEOp read FOp write FOp;
    property Src0:TSSEOperation read FSrc0;
    property Src1:TSSEOperation read FSrc1;
  published
    property OpHash:integer read GetOpHash;
    property AccumHash:integer read GetAccumHash;
    property Description:ansistring read GetDescription;
    property AsmInstr:AnsiString read GetAsmInstr;
    property Instr:ansistring read FInstr;
    property RegId:integer read FRegId write FRegId default -1;
    property AllowedRegs:integer read FAllowedRegs write FAllowedRegs default -1;
  end;

  TSSEOperations=class(TGenericHetObjectList<TSSEOperation>)
  private
    FCurrentAllowedRegs:integer;
    procedure CalcFullUPrg;
  public
    function AddConst(const AConst:variant):TSSEOperation;
    function AddLoad(const AName:ansistring):TSSEOperation;
    function AddStore(const AName:ansistring;const L:variant):TSSEOperation;
    function AddOperation(const op:TSSEOp;const AInstr:ansistring;const L:variant):TSSEOperation;overload;
    function AddOperation(const op:TSSEOp;const AInstr:ansistring;const L,R:variant):TSSEOperation;overload;
    function CanMove(AFrom,ATo:integer):boolean;
    procedure Optimize;
    function MakeHeader:ansistring;
    function MakeConsts:ansistring;
    function MakeCode:ansistring;
    procedure Init;
  published
    property Header:AnsiString read MakeHeader;
    property Consts:AnsiString read MakeConsts;
    property Code:AnsiString read MakeCode;
    property CurrentAllowedRegs:integer read FCurrentAllowedRegs write FCurrentAllowedRegs default -1;
  end;

constructor TSSEOperation.Create(const AOwner:THetObject);
begin
  Inherited;
  if(AOwner<>nil)and(AOwner is TSSEOperations)then
    FAllowedRegs:=TSSEOperations(AOwner).FCurrentAllowedRegs;
end;

function TSSEOperation.IsConst:boolean;begin result:=FOp=soConst end;
function TSSEOperation.IsLoad:boolean;begin result:=FOp=soLoad end;
function TSSEOperation.IsStore:boolean;begin result:=FOp=soStore end;
function TSSEOperation.IsOperation:boolean;begin result:=not(FOp in[soConst,soLoad,soStore])end;

function VarSSEAccessData(const V:variant):PSSEData;forward;

function VarSSEDataHash(const V:variant):integer;
begin
  result:=Crc32(VarSSEAccessData(V),16);
end;

function TSSEOperation.GetOpHash:integer;
begin
  if FOpHash<>0 then exit(FOpHash);

  if IsConst then FOpHash:=19779121+VarSSEDataHash(FConstValue)else
  if IsLoad  then FOpHash:={19771013+Crc32UC(FLoadStoreName)}integer(self)else //a loadot es store-t nem optimizaljuk.
  if IsStore then FOpHash:={19771014+Crc32UC(FLoadStoreName)}integer(self)else
                  FOpHash:=19777831+Crc32UC(FInstr);

  result:=FOpHash;
end;

function TSSEOperation.SrcCount:integer;
begin
  result:=ord(FSrc0<>nil)+ord(FSrc1<>nil);
end;

function TSSEOperation.IsCommutative:boolean;
begin
  result:=(SrcCount=2)and(FOp in[soAdd,soAnd,soOr,soXor,soMul,soMulL,soMulH,soMulHR,soCmpEQ,soCmpNE,soMax,soMin]);
end;

procedure TSSEOperation.SwapSources;
var tmp:TSSEOperation;
begin
  if not IsCommutative then raise Exception.Create('TSSEOperation.SwapSources cannot swap sources, operation is not commutative');
  tmp:=FSrc0;FSRc0:=FSrc1;FSrc1:=tmp;
end;

function TSSEOperation.IsMove:boolean;
begin
  result:=FOp=soMove;
end;

function TSSEOperation.GetAccumHash:integer;
begin
  if self=nil then exit(0);

  Result:=FAccumHash;
  if result<>0 then exit;
  if IsMove then
    FAccumHash:=Src0.AccumHash
  else begin
    FAccumHash:=OpHash;
    case SrcCount of
      1:FAccumHash:=Crc32Combine(FAccumHash,Src0.AccumHash);
      2:if IsCommutative then FAccumHash:=Crc32Combine(FAccumHash,Crc32Combine(min(Src0.AccumHash,Src1.AccumHash),max(Src0.AccumHash,Src1.AccumHash)))
                         else FAccumHash:=Crc32Combine(FAccumHash,Crc32Combine(Src0.AccumHash,Src1.AccumHash));
    end;
  end;

  result:=FAccumHash;
end;

function TSSEOperation.GetDescription:ansistring;
begin
  case FOp of
    soConst:result:='const '+ansistring(FConstValue);
    soLoad:result:='load '+FloadStoreName;
    soStore:result:='store '+FloadStoreName;
  else
    result:=FInstr;
    Replace('xmm0','',result,[roIgnoreCase]);
    Replace('xmm1','',result,[roIgnoreCase]);
    Replace(',','',result,[roIgnoreCase]);
  end;
  //pointers, hashes
  result:=inttohex(FAllowedRegs and $ff,2)+' '+inttohex(integer(self),8)+' '+inttohex(integer(Src0),8)+' '+inttohex(integer(src1),8)+' '+
          inttohex(AccumHash,8)+' '+inttohex(FSrc0.AccumHash,8)+' '+inttohex(FSrc1.AccumHash,8)+' '+result;

end;

function TSSEOperation.GetAsmInstr:ansistring;

  function DstAsText(const op:TSSEOperation):ansistring;
  begin
    if op.IsConst then result:=format('[esi+$%x]',[op.index*16]) else
    if op.IsLoad then result:=op.FLoadStoreName else
    if op.IsOperation then begin
      if op.FRegId<8 then result:=format('xmm%d',[op.FRegId])
                     else result:=format('[esi-$%x]',[(op.FRegId-7)*16]);
    end else
      result:='?';
  end;

var ins:ansistring;
begin
  case FOp of
    soConst:ins:='const '+ansistring(FConstValue);
    soLoad:ins:='load '+FloadStoreName;
    soStore:ins:='store '+FloadStoreName;
  else
    ins:=FInstr;
    Replace('xmm0','',ins,[roIgnoreCase]);
    Replace('xmm1','',ins,[roIgnoreCase]);
    Replace(',','',ins,[roIgnoreCase]);
  end;

  if IsOperation then begin
    Result:=ListItem(ins,0,' ')+' ';
    if Operation=soMove then
      Result:=Result+DstAsText(self)+','+DstAsText(Src0)
    else begin
      result:=result+DstAsText(self);
      if FSrc1<>nil then result:=result+','+DstAsText(FSrc1);
      if ListItem(ins,1,' ')<>'' then result:=result+','+ListItem(ins,1,' ');
    end;
  end else if IsStore then begin
    result:='movaps '+FLoadStoreName+','+DstAsText(FSrc0);
  end else
    result:='';
end;

var _instrInfoList:TStringList=nil;

function instrInfoList:TStringList;
begin
  if _instrInfoList=nil then begin
    _instrInfoList:=TStringList.Create;
    _instrInfoList.LoadFromFile('c:\sseinstr.txt');
  end;
  result:=_instrInfoList;
end;

function InstructionInfo(const AInstr:ansistring):ansistring;

  function SimplifyAsmInstr(const s:ansistring):ansistring;
  var i,j:integer;
      ins:ansistring;
      par:TAnsiStringArray;
  begin
    ins:=ListItem(s,0,' ');
    par:=ListSplit(ListItem(s,1,' '),',');

    for i:=0 to high(Par)do
      if IsWild2('xmm?',Par[i]) then Par[i]:='x' else
      if IsWild2('[*]',Par[i]) then Par[i]:='m' else
      if IsWild2('e??',Par[i]) then Par[i]:='r' else
      if TryStrToInt(Par[i],j) then Par[i]:='i' else
        raise Exception.Create('InstrInfo.SimplifyAsmInstr() unknown parameter "'+s+'"');

    result:=ins+' '+ListMake(par,',');
  end;

var s,line,wilds,actwild,ins,ops:ansistring;
    i,j:integer;

  function cell(n:integer):ansistring;
  begin
    result:=ListItem(line,n,#9);
  end;

begin
  result:='';

  s:=SimplifyAsmInstr(AInstr);
  ins:=listitem(s,0,' ');
  ops:=listitem(s,1,' ');

  for i:=1 to instrInfoList.Count - 1 do begin
    line:=instrInfoList[i];
    if cmp(ops,cell(1))=0 then begin
      wilds:=cell(0);
      for j:=0 to ListCount(wilds,',')-1 do begin
        actwild:=ListItem(wilds,j,',');
        if IsWild2(actwild,Ins)then
          exit(line);
      end;
    end;
  end;

  Raise Exception.Create('InstructionInfo() Invalid parameter types: '+AInstr);
end;

procedure TSSEOperation.CalcFullUPrg;
begin
  FFullUPrg:=AsmInstr;if FFullUPrg='' then exit;

  FFullUPrg:=ListItem(InstructionInfo(FFullUPrg),12,#9);
  if FFullUPrg='' then raise Exception.Create('TSSEOperation.GetFullUPrg() no uprog info for "'+AsmInstr+'"');
end;

function TSSEOperations.AddConst(const AConst:variant):TSSEOperation;
begin
  result:=TSSEOperation.Create(self);
  result.FOp:=soConst;
  result.FConstValue:=AConst;
end;

function TSSEOperations.AddLoad(const AName:ansistring):TSSEOperation;
begin
  result:=TSSEOperation.Create(self);
  result.FOp:=soLoad;
  result.FLoadStoreName:=replacef(' ','',AName,[]);
end;

function VarSSEGetOperation(const V:variant):TSSEOperation;forward;

function TSSEOperations.AddStore(const AName:ansistring;const L:Variant):TSSEOperation;
begin
  result:=AddLoad(AName);
  result.FOp:=soStore;
  result.FSrc0:=VarSSEGetOperation(L);
end;

function TSSEOperations.AddOperation(const op:TSSEOp;const AInstr:ansistring;const L:variant):TSSEOperation;
begin
  result:=TSSEOperation.Create(self);
  result.FOp:=op;
  result.FInstr:=AInstr;
  result.FSrc0:=VarSSEGetOperation(L);
end;

function TSSEOperations.AddOperation(const op:TSSEOp;const AInstr:ansistring;const L,R:variant):TSSEOperation;
begin
  result:=AddOperation(op,AInstr,L);
  result.FSrc1:=VarSSEGetOperation(R);
end;

function TSSEOperations.CanMove(AFrom,ATo:integer):boolean;

  function FindSourceUp(const ASrc:TSSEOperation):boolean;
  var i:integer;
  begin
    if ASrc=nil then exit(false);
    for i:=AFrom-1 downto ATo do
      if ByIndex[i].AccumHash=ASrc.AccumHash then exit(true);
    result:=false;
  end;

  function FindSinkDown(const ASrc:TSSEOperation):boolean;
  var i:integer;
  begin
    for i:=AFrom+1 to ATo do
      if(ByIndex[i].Src0.AccumHash=ASrc.AccumHash)or(ByIndex[i].Src1.AccumHash=ASrc.AccumHash)then exit(true);
    result:=false;
  end;

  function FindStoreUp(const ALoadStoreName:ansistring):boolean;
  var i:integer;
  begin
    for i:=AFrom-1 downto ATo do with ByIndex[i]do begin
      if IsStore and(cmp(FLoadStoreName,ALoadStoreName)=0)then exit(true);
    end;
    result:=false;
  end;

  function FindStoreOrLoadUp(const ALoadStoreName:ansistring):boolean;
  var i:integer;
  begin
    for i:=AFrom-1 downto ATo do with ByIndex[i]do begin
      if(IsStore or IsLoad)and(cmp(FLoadStoreName,ALoadStoreName)=0)then exit(true);
      if(IsOperation)and(cmp(FSrc0.FLoadStoreName,ALoadStoreName)=0)then exit(true);
      if(IsOperation)and(FSrc1<>nil)and(cmp(FSrc1.FLoadStoreName,ALoadStoreName)=0)then exit(true);
    end;
    result:=false;
  end;

  function FindRegReadUp(const ARegId:integer):boolean;
  var i:integer;
  begin
    for i:=AFrom-1 downto ATo do with ByIndex[i]do begin
      if(FRegId=ARegId)or
        (FSrc0<>nil)and(FSrc0.FRegId=ARegId)or
        (FSrc1<>nil)and(FSrc1.FRegId=ARegId)then exit(true);
    end;
    result:=false;
  end;

  function FindStoreDown(const ALoadStoreName:ansistring):boolean;
  var i:integer;
  begin
    for i:=AFrom+1 to ATo do with ByIndex[i]do
      if IsStore and(cmp(FLoadStoreName,ALoadStoreName)=0)then exit(true);
    result:=false;
  end;

  function FindStoreOrLoadDown(const ALoadStoreName:ansistring):boolean;
  var i:integer;
  begin
    for i:=AFrom+1 to ATo do with ByIndex[i]do begin
      if(IsStore or IsLoad)and(cmp(FLoadStoreName,ALoadStoreName)=0)then exit(true);
      if(IsOperation)and(cmp(FSrc0.FLoadStoreName,ALoadStoreName)=0)then exit(true);
      if(IsOperation)and(FSrc1<>nil)and(cmp(FSrc1.FLoadStoreName,ALoadStoreName)=0)then exit(true);
    end;
    result:=false;
  end;

  function FindRegWriteDown(const ARegId:integer):boolean;
  var i:integer;
  begin
    for i:=AFrom+1 to ATo do with ByIndex[i]do
      if(FRegId=ARegId)then exit(true);
    result:=false;
  end;



var OFrom:TSSEOperation;
begin
  if(AFrom<0)or(AFrom>=Count)or(ATo<0)or(ATo>=Count)then raise ERangeError.Create('TSSEOperations.CanMove()');
  if AFrom=ATo then exit(true);

  OFrom:=ByIndex[AFrom];
  result:=true;
  if AFrom>ATo then begin //up
    if FindSourceUp(OFrom.Src0)or FindSourceUp(OFrom.Src1)then exit(false);
    if OFrom.IsLoad and FindStoreUp(OFrom.FLoadStoreName)then exit(false);
    if OFrom.IsStore and FindStoreOrLoadUp(OFrom.FLoadStoreName)then exit(false);
    if (OFrom.FRegId>=0)and FindRegReadUp(OFrom.FRegId)then exit(false);
  end else begin //down
    if FindSinkDown(OFrom)then exit(false);
    if OFrom.IsLoad and FindStoreDown(OFrom.FLoadStoreName)then exit(false);
    if OFrom.IsStore and FindStoreOrLoadDown(OFrom.FLoadStoreName)then exit(false);
    if(OFrom.Fsrc1<>nil)and(OFrom.Fsrc1.FRegId>=0)and FindRegWriteDown(OFrom.FSrc1.FRegId)then exit(false);
    if(OFrom.Fsrc0<>nil)and(OFrom.Fsrc0.FRegId>=0)and FindRegWriteDown(OFrom.FSrc0.FRegId)then exit(false);
  end;
end;

type
  TCore2=class
    Clock:integer;
//    History:AnsiString;
    Port:array[0..5]of TSSEOperation;
    Pending:THetArray<TSSEOperation>;
    constructor Create;
    function TryAssignPort(const op:TSSEOperation):boolean;
    procedure Step;
    procedure Reset;
    procedure Flush;
    Procedure AddOp(const Op:TSSEOperation);
  end;

constructor TCore2.Create;
begin
  Reset;
end;

function TCore2.TryAssignPort(const op:TSSEOperation):boolean;
  procedure Error;
  begin raise Exception.Create('TCore2.TryAssignPort(): Invalid microProgram syntax"'+op.FActUprg+'"');end;
var i,j,po,cnt:integer;
    s:ansistring;
    p:TAnsiStringArray;
    found:boolean;
    assignedPorts:THetArray<integer>;
begin
  result:=false;
  s:=ListItem(op.FActUPrg,0,',');
  p:=ListSplit(s,'&');
  if length(p)=0 then error;
  if uc(charn(s,1))='L' then begin
    if Length(s)=1 then cnt:=1
                   else cnt:=StrToIntDef(copy(s,2,$ff),0);
    dec(cnt);
    if cnt=0 then DelListItem(op.FActUPrg,0,',')
             else SetListItem(op.FActUPrg,0,'L'+inttostr(cnt),',');
    result:=true;
  end else begin
    assignedPorts.Clear;
    for i:=0 to High(p)do begin
      s:=p[i];
      if s='' then error;
      found:=false;
      for j:=1 to length(s)do begin
        po:=Ord(s[j])-Ord('0');
        if not(po in[0..5])then error;
        if Port[po]=nil then begin
          assignedPorts.Append(po);
          found:=true;
          break;
        end;
      end;
      if not found then exit;
    end;
    for i:=0 to assignedPorts.FCount-1 do begin
      Port[assignedPorts.FItems[i]]:=op;
    end;
    DelListItem(op.FActUPrg,0,',');
    result:=true;
  end;
end;

procedure TCore2.Step;
const pmap:array[0..5]of integer=(0,1,5,2,3,4);
var i:integer;
//    sInfo:ansistring;
begin
//  sInfo:='';
//  //port stats out
//  for i:=0 to high(Port)do if port[pmap[i]]=nil then sInfo:=sInfo+'.|'
//                                                else sInfo:=sInfo+listitem(FItems[i].FInstr,0,' ')+'|';
//  sInfo:=sInfo+' ';
  //retire
  i:=0;with Pending do while i<FCount do
    if FItems[i].FActUPrg='' then begin
//      sInfo:=sInfo+listitem(FItems[i].FInstr,0,' ')+' ';
      Remove(i);
    end else
      inc(i);

  for i:=0 to high(port)do port[i]:=nil;
  for i:=0 to pending.FCount-1 do TryAssignPort(Pending.FItems[i]);

{  sInfo:=Format('%.4d ',[clock])+sInfo;
  History:=History+#13#10+sInfo;}

  inc(Clock);
end;

procedure TCore2.Reset;
begin
  clock:=0;
{  History:='clk  015234 rets';}
  Pending.Clear;
end;

procedure TCore2.Flush;
begin
  while Pending.FCount>0 do Step;
end;

procedure TCore2.AddOp(const Op:TSSEOperation);

  function SourcesInUse(const Op:TSSEOperation):boolean;

    function Chk(const op2:TSSEOperation):boolean;
    begin
      result:=(op2<>nil)and((op2=Op.FSrc0)or(op2=Op.FSrc1));
    end;

  var i:integer;
  begin
    for i:=0 to High(Port)do if Chk(Port[i])then exit(true);
    with Pending do for i:=0 to Pending.FCount-1 do if Chk(FItems[i])then exit(true);
    result:=false;
  end;

begin
  while SourcesInUse(Op)or(Pending.FCount>=3)or not TryAssignPort(Op) do Step;
  Pending.Append(Op);
end;

procedure TSSEOperations.CalcFullUPrg;
var o:TSSEOperation;
begin
  for o in self do o.CalcFullUPrg;
end;

procedure TSSEOperations.Init;
begin
  reset;
end;

procedure TSSEOperations.Optimize;

  procedure MoveConstsUp;
  var i:integer;
  begin
    for i:=0 to Count-1 do if ByIndex[i].IsConst then Move(i,0);
  end;

  procedure DropUnusedOps;

    procedure MarkAsUsed(const o:TSSEOperation);
    begin
      if o.FUsed then exit;
      o.FUsed:=true;
      if o.Src0<>nil then MarkAsUsed(o.Src0);
      if o.Src1<>nil then MarkAsUsed(o.Src1);
    end;

  var o:TSSEOperation;
      i:integer;
  begin
    for o in self do o.FUsed:=false;
    for o in self do if o.IsStore then MarkAsUsed(o);
    for i:=Count-1 downto 0 do with ByIndex[i] do if not FUsed then Free;
  end;

  procedure RerouteRedundants;

    function FindFirstSrc(const src:TSSEOperation):TSSEOperation;
    var o:TSSEOperation;
        h:integer;
    begin
      if src=nil then exit(nil);
      h:=src.AccumHash;
      for o in self do if o.AccumHash=h then exit(o);
      Assert(false,'Shit happens in TSSEOperations.Optimize.RerouteRedundants.FindFirstSrc()');
    end;

  var o:TSSEOperation;
  begin
    for o in self do with o do begin
      FSrc0:=FindFirstSrc(FSrc0);
      FSrc1:=FindFirstSrc(FSrc1);
    end;
  end;

{  procedure ReorderASAP;
  var ActIdx:integer;
      FromIdx:integer;
  begin
    for ActIdx:=0 to Count-1 do if not ByIndex[ActIdx].IsConst then begin
      for FromIdx:=ActIdx+1 to Count-1 do
        if CanMove(FromIdx,ActIdx)then
          Move(FromIdx,ActIdx);
    end;
  end;}

  procedure MakeProgram;
  var Regs:THetArray<TSSEOperation>;//0..7:xmm 8..:temp

    function ValueIsNeeded(const ActOp:TSSEOperation;const hash:Integer;includeAct:boolean):boolean;
    var i:integer;
    begin
      for i:=ActOp.Index+ord(not includeAct) to Count-1 do with ByIndex[i]do
        if(FSrc0.AccumHash=hash)or(FSrc1.AccumHash=hash)then exit(true);
      result:=false;
    end;

    function NeedToSaveSrc0(const ActOp:TSSEOperation):boolean;
    var h,i,cnt:Integer;
        op:TSSEOperation;
    begin
      h:=ActOp.FSrc0.AccumHash;
      if not ValueIsNeeded(ActOp,h,false)then exit(false);
      //load or const
      for i:=ActOp.Index-1 downto 0 do
        if(ByIndex[i].IsConst or ByIndex[i].IsLoad)and(ByIndex[i].AccumHash=H)then begin
          exit(false);
        end;
      //2x inside RM
      cnt:=0;
      with Regs do for i:=0 to FCount-1 do if FItems[i].AccumHash=h then begin
        inc(cnt);if cnt>=2 then exit(false);
      end;
      result:=true;
    end;

    function FindInR(const Hash:Integer):TSSEOperation;
    var i:integer;
    begin
      with Regs do for i:=0 to 7 do if FItems[i].AccumHash=Hash then exit(FItems[i]);
      result:=nil;
    end;

    var ActOp:TSSEOperation;

    function FindInRM(const Hash:Integer):TSSEOperation;
    var i:integer;
    begin
      with Regs do for i:=0 to FCount-1 do if FItems[i].AccumHash=Hash then exit(FItems[i]);
      for i:=ActOp.Index-1 downto 0 do
        if(ByIndex[i].IsConst or ByIndex[i].IsLoad)and(ByIndex[i].AccumHash=Hash)then exit(ByIndex[i]);
      result:=nil;
    end;


    function RegIsAllowed(const RegId:integer):boolean;
    begin
      result:=(CurrentAllowedRegs<=0)or(((1 shl RegId)and CurrentAllowedRegs)<>0);
    end;

    function FreeRegCount:integer;
    var i:integer;
    begin
      result:=0;
      with regs do for i:=0 to 7 do if RegIsAllowed(i)then if FItems[i]=nil then inc(Result);
    end;

    procedure FreeUnusedRegs;
    var i:integer;
    begin
      with regs do for i:=0 to FCount-1 do
        if(FItems[i]<>nil)and not ValueIsNeeded(ActOp,FItems[i].AccumHash,true)then
          FItems[i]:=nil;
    end;

{    var lastFreeReg:integer;
    function GetFreeR:integer;
    var i:integer;
    begin
      with regs do for i:=0 to 7 do begin
        lastFreeReg:=(lastFreeReg+1)and 7;
        if FItems[lastFreeReg]=nil then exit(lastFreeReg);
      end;
      result:=-1;
    end;}

    var FreeRegCounters:array[0..7]of integer;
    procedure InitFreeRegCounters;
    begin
      fillchar(FreeRegCounters,sizeof(FreeRegCounters),0);
    end;

    procedure UpdateFreeRegCounters;
    var i:integer;
    begin
      with regs do for i:=0 to 7 do if FItems[i]=nil then inc(FreeRegCounters[i])
                                                     else FreeRegCounters[i]:=0;
    end;

    function GetFreeR:integer;
    var i,j,ma:integer;
    begin
      result:=-1;ma:=0;
      with regs do for i:=0 to 7 do if RegIsAllowed(i)then if FItems[i]=nil then
        if(result<0)or(FreeRegCounters[i]>ma)then begin
          result:=i;
          ma:=FreeRegCounters[i];
        end;
    end;

    function GetFreeM:integer;
    var i:integer;
    begin
      with regs do for i:=8 to FCount-1 do if FItems[i]=nil then exit(i);
      Regs.Append(nil);
      result:=regs.FCount-1;
    end;

    function GetFreeRM:integer;
    var i:integer;
    begin
      result:=GetFreeR;
      if result<0 then Result:=getFreeM;
    end;

    procedure SetReg(const regId:integer;const op:TSSEOperation);
    begin
      op.FRegId:=regId;
      Regs.FItems[regId]:=op;
    end;

    procedure CopyRtoRM(const Hash:integer);
    var op:TSSEOperation;
        reg:integer;
        mov:TSSEOperation;
    begin
      op:=FindInR(Hash);
      if op=nil then raise Exception.Create('CopyRtoRM() hash not found');
      mov:=TSSEOperation.Create(Self);
      mov.FAllowedRegs:=self.CurrentAllowedRegs;
      Move(Count-1,ActOp.Index);
      mov.FSrc0:=op;
      mov.FOp:=soMove;
      mov.FInstr:='movaps xmm0,xmm1';
      SetReg(GetFreeRM,mov);
    end;

    procedure CopyRtoM(const Hash:integer);
    var op:TSSEOperation;
        reg:integer;
        mov:TSSEOperation;
    begin
      op:=FindInR(Hash);
      if op=nil then raise Exception.Create('CopyRtoM() hash not found');
      mov:=TSSEOperation.Create(Self);
      mov.AllowedRegs:=-1;
      Move(Count-1,ActOp.Index);
      mov.FSrc0:=op;
      mov.FOp:=soMove;
      mov.FInstr:='movaps xmm0,xmm1';
      SetReg(GetFreeM,mov);
    end;

    procedure SaveAReg;
    var i,j,k,sc,maxsc:integer;
        o:TSSEOperation;
    begin
      k:=-1;maxsc:=0;
      with Regs do for i:=0 to 7 do if RegIsAllowed(i)then begin
        o:=FItems[i];
        if o=nil then continue;
        sc:=self.Count;
        for j:=o.Index+1 to self.Count-1 do with ByIndex[j] do
          if(FSrc0.AccumHash=o.AccumHash)or(FSrc1.AccumHash=o.AccumHash)then begin sc:=j;break;end;
        if(i=0)or(sc>=maxsc)then begin
          maxsc:=sc;
          k:=i;
        end;
      end;
      if k<0 then raise Exception.Create('TSSEOperations.Optimize.MakeProgram.SaveAReg() no discardable reg found');
      CopyRtoM(Regs.FItems[k].AccumHash);
      Regs.FItems[k]:=nil;
    end;

    procedure MoveRMtoR(const Hash:integer);
    var op:TSSEOperation;
        reg:integer;
        mov:TSSEOperation;
    begin
      op:=FindInR(Hash);if op<>nil then exit;
      op:=FindInRM(Hash);if op=nil then raise Exception.Create('CopyMoveRMtoR hash not found');
      if FreeRegCount=0 then SaveAReg;
      mov:=TSSEOperation.Create(Self);
      mov.FAllowedRegs:=self.CurrentAllowedRegs;
      Move(Count-1,ActOp.Index);
      mov.FSrc0:=op;
      mov.FOp:=soMove;
      mov.FInstr:='movaps xmm0,xmm1';
      SetReg(GetFreeRM,mov);
    end;

  function CalcInstructionCount(const actOp:TSSEOperation;const EnableCommutativeSwap:boolean=true):integer;
  var r2:integer;
  begin
    if actOp.IsStore then begin
      if FindInR(ActOp.FSrc0.AccumHash)<>nil then result:=0
                                             else result:=1;
    end else if actOp.IsOperation and not actOp.IsMove then begin
      result:=0;
      if FindInR(actOp.FSrc0.AccumHash)=nil then inc(result);//load
      if NeedToSaveSrc0(actOp)then inc(result,2);//save for later use
      result:=result+EnsureRange(result-FreeRegCount,0,2);//reg saves

      if EnableCommutativeSwap and ActOp.IsCommutative then begin
        ActOp.SwapSources;
        r2:=CalcInstructionCount(ActOp,false);
        if r2<result then exit(r2)
                     else ActOp.SwapSources;
      end;
    end else
      result:=0;
  end;

  var i,minScore,Score:integer;
      r0,r1:integer;
      ActPos:integer;
      o:TSSEOperation;
      ActOps:THetArray<TSSEOperation>;

  begin
//    lastFreeReg:=0;
    InitFreeRegCounters;
    Regs.Clear;for i:=0 to 7 do Regs.Append(nil);
    for i:=0 to Count-1 do ByIndex[i].FRegId:=-1;
    ActPos:=0;
    while(ActPos<Count)and(ByIndex[ActPos].IsConst)do inc(ActPos);
    while true do begin
      //get possible instructions
      if ActPos>=Count then break;
      ActOps.Clear;
      o:=ByIndex[ActPos];
      ActOps.Append(o);
      for i:=o.Index+1 to Count-1 do if canmove(i,ActPos)then
        ActOps.Append(ByIndex[i]);
      //select fastest
      ActOp:=nil;minScore:=0;
      with actOps do for i:=0 to FCount-1 do begin
        Score:=CalcInstructionCount(FItems[i]);
        if(ActOp=nil)or(minScore>Score)then begin
          ActOp:=FItems[i];
          minScore:=Score;
        end;
      end;
      if ActOp=nil then break;//done
      Move(ActOp.Index,ActPos);
//      ActOp:=o;

      //compile
      CurrentAllowedRegs:=ActOp.AllowedRegs;
      if actOp.IsStore then begin
        if FindInR(ActOp.FSrc0.AccumHash)=nil then
          MoveRMtoR(ActOp.FSrc0.AccumHash);
        ActOp.FSrc0:=FindInR(ActOp.FSrc0.AccumHash);
      end else if actOp.IsOperation and not actOp.IsMove then begin
        if FindInR(actOp.FSrc0.AccumHash)<>nil then begin
          if NeedToSaveSrc0(ActOp) then
            CopyRtoRM(ActOp.Src0.AccumHash);
        end else begin
          MoveRMtoR(ActOp.FSrc0.AccumHash);
        end;
        actOp.FSrc0:=FindInR(actOp.FSrc0.AccumHash);
        if actOp.FSrc1<>nil then
          actOp.FSrc1:=FindInRM(actOp.FSrc1.AccumHash);
        SetReg(actOp.FSrc0.FRegId,ActOp);
      end;

      FreeUnusedRegs;
      UpdateFreeRegCounters;
      ActPos:=Succ(ActOp.Index)
    end;
  end;

  procedure ReorderRandom;
  var i,j,k,l:integer;
  begin
    for i:=0 to 1000000 do begin
      j:=random(Count);k:=random(count);
      if ByIndex[j].IsConst or ByIndex[k].IsConst then continue;
      if canMove(j,k) then Move(j,k);
    end;
  end;

  procedure ReorderCore2;
  var Core2:TCore2;

    procedure AddToCore2(const Op:TSSEOperation);
    begin
      if op.FFullUPrg='' then exit;
      op.FActUPrg:=Op.FFullUPrg;
      Core2.AddOp(op);
    end;

    function Simulate(const AUntil:integer;const ATestOp:TSSEOperation;const GoOver:integer=0):integer;
    var i:integer;
    begin
      Core2.Reset;
      for i:=0 to AUntil-1 do
        AddToCore2(ByIndex[i]);
      AddToCore2(ATestOp);
      result:=Core2.Clock;
    end;

    function SimulateAll:integer;
    var i:integer;
    begin
      Core2.Reset;
      for i:=0 to Count-1 do
        AddToCore2(ByIndex[i]);
      Core2.Flush;
      result:=Core2.Clock;
    end;

    function EmulateAll:integer;
    var code:rawbytestring;
        temp:array[0..1023]of byte;
        i,a,d,c,s:integer;
        t0,t1:int64;
    begin
      fillchar(temp,sizeof(temp),0);
      code:=AsmCompile(MakeCode)+#$C3;
      a:=(integer(@temp)+15)and(not 15);
      d:=a+8*16;
      c:=a+16*16;
      s:=a+32*16;

      SetPriorityClass(GetCurrentProcess,REALTIME_PRIORITY_CLASS);
      result:=0;
      for i:=0 to 10 do begin
        QueryPerformanceCounter(t0);
        asm
          push ebx push esi
          mov eax,a
          mov edx,d
          mov ecx,c
          mov esi,s
          call [code]
          pop esi pop ebx
        end;
        QueryPerformanceCounter(t1);
        t1:=t1-t0;
        if(i=0)or(t1<result)then result:=t1;
      end;
    end;

  var ActPos,i,j,OpId,clock,minClock:integer;
      o:TSSEOperation;
      s:ansistring;
      ActOps:THetArray<TSSEOperation>;
  begin
    CalcFullUPrg;
    Core2:=TCore2.Create;AutoFree(Core2);

    //long range reorder
    for ActPos:=0 to Count-1 do begin
      o:=ByIndex[ActPos];
      if o.FFullUPrg='' then Continue;//consts

      ActOps.Clear;
      ActOps.Append(o);
      for i:=ActPos+1 to Count-1 do if canmove(i,ActPos)then
        ActOps.Append(ByIndex[i]);

      OpId:=-1;minClock:=0;
      for i:=0 to ActOps.FCount-1 do begin
        clock:=Simulate(ActPos,ActOps.FItems[i]);
        if(minClock>=clock)or(OpId<0)then begin
          minClock:=clock;OpId:=i;
        end;
      end;

      Move(ActOps.FItems[OpId].Index,ActPos);
    end;

    //short range reorder
    minClock:=SimulateAll;
    if Count>2 then for i:=1 to Count*20{empirikus} do begin
      ActPos:=i mod(count-1);
      o:=ByIndex[ActPos];
      if o.FFullUPrg='' then continue;
      if ByIndex[ActPos+1].FFullUPrg='' then continue;

      if not CanMove(ActPos+1,ActPos)then continue;
      Move(ActPos+1,ActPos);

      clock:=SimulateAll;
      if minClock>=clock-2{empirikus} then minClock:=min(clock,minClock)
                                      else Move(ActPos+1,ActPos);
    end;
  end;

begin
  MoveConstsUp;
  RerouteRedundants;
  DropUnusedOps;
  MakeProgram;
  ReorderCore2;
end;

function TSSEOperations.MakeHeader:AnsiString;

  function SimpleName(s:ansistring):ansistring;
  var reg,ofs:ansistring;
      iofs:integer;
  begin
    if not IsWild2('[*]',s)then raise Exception.Create('TSSEOperations.MakeHeader.SimpleName() [*] expected, "'+s+'"');
    s:=copy(s,2,length(s)-2);
    replace('-','+-',s,[]);
    case ListCount(s,'+')of
      1:begin reg:=s;ofs:='';end;
      2:begin reg:=ListItem(s,0,'+');ofs:=ListItem(s,1,'+');end;
    else
      raise Exception.Create('TSSEOperations.MakeHeader.SimpleName() invalid format "'+s+'"');
    end;

    if cmp(reg,'eax')=0 then reg:='a' else
    if cmp(reg,'ebx')=0 then reg:='b' else
    if cmp(reg,'ecx')=0 then reg:='c' else
    if cmp(reg,'edx')=0 then reg:='d' else
    if cmp(reg,'esi')=0 then reg:='s' else
    if cmp(reg,'edi')=0 then reg:='t' else
      raise Exception.Create('TSSEOperations.MakeHeader.SimpleName() invalid reg "'+s+'"');

    try
      if ofs='' then iofs:=0 else
        if charn(ofs,1)='-' then iofs:=-StrToInt(copy(ofs,2,$ff))
                            else iofs:=StrToInt(ofs);
    except
      raise Exception.Create('TSSEOperations.MakeHeader.SimpleName() invalid ofs "'+s+'"');
    end;

    if(iofs mod 16)<>0 then
      raise Exception.Create('TSSEOperations.MakeHeader.SimpleName() invalid ofs "'+s+'"');

    result:=reg+inttostr(iofs div 16);
  end;

var o:TSSEOperation;
    s,sIn,sOut,sConst,sTemp:ansistring;
begin
  sTemp:='x0,x1,x2,x3,x4,x5,x6,x7';
  for o in self do begin
    if o.IsConst then ListAppend(sConst,'s'+inttostr(o.Index),',')else
    if o.IsLoad then ListAppend(sIn,SimpleName(o.FLoadStoreName),',')else
    if o.IsStore then ListAppend(sOut,SimpleName(o.FLoadStoreName),',')else begin
      if(o.FRegId>7)then ListAppendNewOnly(sTemp,'s-'+inttostr(o.FRegId-7),',');
    end;
  end;
  result:='{$Define in '+sIn+';out '+sOut+';temp '+sTemp+';const '+sConst+';}'#13#10;
end;

function TSSEOperations.MakeCode:AnsiString;
var o:TSSEOperation;
    s:ansistring;
begin
  result:='';
  with AnsiStringBuilder(result)do begin
    for o in self do begin
      s:=o.GetAsmInstr;
      if s<>'' then
        AddStr(s+#13#10);
    end;
    Finalize;
  end;

//  FileWriteStr('c:\sample.sse',MakeHeader+#13#10+result);
  TFile('c:\sample.sse').Write(AsmDump(AsmCompile(result)));
  TFile('c:\sample.const').Write(MakeConsts);
end;

function TSSEOperations.MakeConsts:AnsiString;

  function Dump(const v:variant):AnsiString;
  var i:integer;
      sd:PSSEData;
  begin
    sd:=VarSSEAccessData(v);
    result:='dd ';
    for i:=0 to 3 do begin
      if i>0 then result:=result+',';
      result:=result+'$'+IntToHex(sd.Cardinals[i],8);
    end;
  end;

var o:TSSEOperation;
    cnt:integer;

begin
  result:='  procedure CreateConsts;asm push eax;call @@0'#13#10;
  cnt:=0;
  for o in self do if o.IsConst then begin
    result:=result+'    '+Dump(o.FConstValue)+#13#10;
    inc(cnt);
  end;
  result:=result+'    @@0:pop eax;mov esi,esp;sub esi,16;and esi,not 15;sub esi,'+inttostr(cnt*16)+#13#10;
  for cnt:=0 to cnt-1 do result:=result+'    movups xmm0,[eax+'+tostr(16*cnt)+'];movaps [esi+'+tostr(16*cnt)+'],xmm0;'#13#10;
  result:=result+'    pop eax;'#13#10'  end;'#13#10;
end;

var
  SSEOperations:TSSEOperations;

function VarIsSSE(const V:variant):boolean;
begin
  result:=TVarData(V).VType=varSSE;
end;

procedure CheckVarIsSSE(const V:Variant;const msg:string='');
begin
  if not VarIsSSE(V)then raise EVariantInvalidArgError.Create('varSSE type expected '+msg);
end;

function VarSSEGetOperation(const V:variant):TSSEOperation;
begin
  CheckVarIsSSE(V);
  result:=TSSEOperation(TVarData(V).VLongs[0]);
end;

procedure VarSSESetOperation(var V:variant;const Oper:TSSEOperation);
begin
  CheckVarIsSSE(V);
  TSSEOperation(TVarData(V).VLongs[0]):=Oper;
end;

function VSSE(const ADataType:TSSEDataType;const AData:TSSEData;const ASource:ansistring{const or [eax+$30]}):Variant;
begin
  VarClear(Result);
  with TVarData(Result)do begin
    VType:=varSSE;
    VPointer:=GetMemory(16);
    PSSEData(VPointer)^:=AData;
    VLongs[2]:=ord(ADataType);
    if ADataType<>dtImmediate then begin
      if cmp(ASource,'const')=0 then VarSSESetOperation(result,SSEOperations.AddConst(result))
                                else VarSSESetOperation(result,SSEOperations.AddLoad(ASource));
    end;
  end;
end;

function VSSEImmed(const AImmediate:byte):Variant;
var tmp:TSSEData;
begin
  FillChar(tmp,sizeof(tmp),0);
  tmp.Immediate:=AImmediate;
  result:=VSSE(dtImmediate,tmp,'');
end;

function VarSSEType(const V:variant):TSSEDataType;
begin
  CheckVarIsSSE(V);
  result:=TSSEDataType(TVarData(V).VLongs[2]);
end;

function VarIsSSEImmed(const V:variant):boolean;
begin
  result:=VarSSEType(V)=dtImmediate;
end;

procedure VarSSESetType(var V:variant;const ANewType:TSSEDataType);
begin
  CheckVarIsSSE(V);
  TVarData(V).VLongs[2]:=ord(ANewType);
end;

function VarSSEData(const V:variant):TSSEData;
begin
  CheckVarIsSSE(V);
  result:=PSSEData(TVarData(V).VPointer)^;
end;

procedure VarSSESetData(var V:variant;const ANewData:TSSEData);
begin
  CheckVarIsSSE(V);
  PSSEData(TVarData(V).VPointer)^:=ANewData;
end;

function VarSSEAccessData(const V:variant):PSSEData;
begin
  CheckVarIsSSE(V);
  result:=PSSEData(TVarData(V).VPointer);
end;

function SSECast(const AType:TSSEDataType;const AParams:TVariantArray;const ASource:AnsiString):Variant;overload;
var i,cnt,pcnt:integer;
    tmp:TSSEData;
    tmpParams:TVariantArray;
begin
  cnt:=SSEDataCount[AType];
  pcnt:=Length(AParams);
  if(pcnt<>1)and(pcnt<>cnt)then
    raise EVariantInvalidArgError.Create('SSECast('+GetEnumName(TypeInfo(TSSEDataType),ord(AType))+') '+inttostr(cnt)+' or 1 parameters expected ('+inttostr(pcnt)+' params found)');

  if VarIsArray(AParams[0])then begin
    setlength(tmpParams,VarLength(AParams[0]));
    for i:=0 to VarHigh(AParams[0])do tmpParams[i]:=AParams[0][i];
    result:=SSECast(AType,tmpParams,ASource);
  end else if VarIsSSE(AParams[0])then begin
    Result:=AParams[0];
    VarSSESetType(Result,AType)
  end else with tmp do begin
    case AType of
      dtBytes    :for i:=0 to cnt-1 do Bytes    [i]:=AParams[min(pcnt-1,i)];
      dtShortInts:for i:=0 to cnt-1 do ShortInts[i]:=AParams[min(pcnt-1,i)];
      dtWords    :for i:=0 to cnt-1 do Words    [i]:=AParams[min(pcnt-1,i)];
      dtSmallInts:for i:=0 to cnt-1 do SmallInts[i]:=AParams[min(pcnt-1,i)];
      dtCardinals:for i:=0 to cnt-1 do Cardinals[i]:=AParams[min(pcnt-1,i)];
      dtIntegers :for i:=0 to cnt-1 do Integers [i]:=AParams[min(pcnt-1,i)];
      dtInt64s   :for i:=0 to cnt-1 do Int64s   [i]:=AParams[min(pcnt-1,i)];
      dtCar64s   :for i:=0 to cnt-1 do Car64s   [i]:=AParams[min(pcnt-1,i)];
      dtSingles  :for i:=0 to cnt-1 do Singles  [i]:=AParams[min(pcnt-1,i)];
      dtDoubles  :for i:=0 to cnt-1 do Doubles  [i]:=AParams[min(pcnt-1,i)];
    else
      raise EVariantInvalidArgError.Create('SSECast() invalid destination ssetype');
    end;
    result:=VSSE(AType,tmp,ASource)
  end;
end;

function SSECast(const AType:TSSEDataType;const AParam:Variant;const ASource:AnsiString):Variant;overload;
var p:TVariantArray;
begin
  setlength(p,1);p[0]:=AParam;
  result:=SSECast(AType,p,ASource);
end;

procedure TSSEVariantType.Clear(var V: TVarData);
begin
  if V.VPointer<>nil then FreeMemory(V.VPointer);
  SimplisticClear(V);
end;

procedure TSSEVariantType.Copy(var Dest: TVarData; const Source: TVarData; const Indirect: Boolean);
begin
  if Indirect then raise EVariantInvalidOpError.Create('TSSEVariantType.Copy() Cannot copy indirectly');
  SimplisticCopy(Dest,Source);
  SetMinimumBlockAlignment(mba16Byte);
  Dest.VPointer:=getmemory(16);
  PSSEData(Dest.VPointer)^:=PSSEData(Source.VPointer)^;
end;

////////////////////////////////////////////////////////////////////////////////
// SSE operations                                                             //
////////////////////////////////////////////////////////////////////////////////

function VarOpToSSEOp(const op:TVarOp):TSSEOp;
begin
  case op of
    opAdd:result:=soAdd;
    opSubtract:result:=soSub;
    opMultiply:result:=soMul;
    opOr:result:=soOr;
    opAnd:result:=soAnd;
    opXor:result:=soXor;
    opShiftLeft:result:=soShl;
    opShiftRight:result:=soShr;
    opCmpEQ:result:=soCmpEq;
    opCmpNE:result:=soCmpNE;
    opCmpGT:result:=soCmpGT;
    opCmpGE:result:=soCmpGE;
    opCmpLT:result:=soCmpLT;
    opCmpLE:result:=soCmpLE;
  else raise EVariantInvalidOpError.Create('Unsupported SSE operation: '+GetEnumName(TypeInfo(TVarOp),ord(op)));
  end;
end;

//byte size, float/ord stimmel,
function SSETypeCheckSimpleOp(const v1,v2:variant):boolean;
var t1,t2:TSSEDataType;
begin
  t1:=VarSSEType(v1);t2:=VarSSEType(v2);
  if not(SSEDataSize[t1]=SSEDataSize[t2])or not(SSEDataIsFloat[t1]=SSEDataIsFloat[t2])then
    raise EVariantInvalidOpError.Create('Incompatible SSE types for simple operation ('+GetEnumName(TypeInfo(TSSEDataType),ord(t1))+','+GetEnumName(TypeInfo(TSSEDataType),ord(t2)));
end;

function SSETypeAsSigned(const t:TSSEDataType):TSSEDataType;
begin
  result:=t;
  case result of
    dtBytes     :result:=dtShortInts;
    dtWords     :result:=dtSmallInts;
    dtCardinals :result:=dtIntegers;
    dtCar64s    :result:=dtInt64s;
  end;
end;

procedure SSELoad0(const a:variant);
var p0:PSSEData;
begin
  p0:=VarSSEAccessData(a);
  asm mov eax,p0;movaps xmm0,[eax]end;
end;

procedure SSELoad1(const a:variant);
var p0:PSSEData;
begin
  p0:=VarSSEAccessData(a);
  asm mov eax,p0;movaps xmm1,[eax]end;
end;

procedure SSELoad1DW(const a:integer);
asm movd xmm1,eax end;

procedure SSEStore0(const a:variant);
var p:PSSEData;
begin
  p:=VarSSEAccessData(a);
  asm
    mov eax,p
    movaps [eax],xmm0
  end;
end;

function CompileAsm(const code:ansistring):rawbytestring;
var ch:PAnsiChar;tk:TToken;val:variant;
  procedure Parse;begin tk:=ParsePascalToken(ch,val)end;
  procedure Error(const s:string);begin raise Exception.Create('CompileAsm() '+s)end;
begin
  result:='';
  if code='' then exit;

  ch:=pointer(code);
  parse;
  while true do case tk of
    tkEof:exit;
    tkSemiColon:begin parse;continue;end;
    tkIdentifier:begin
      parse;

    end;
  else
    error('asm instruction expected.');
  end;
end;

procedure SSEOp(var L:Variant;const R:Variant;const op:TSSEOp);
var simpleType,exactType:TSSEDataType;
  procedure error;
  begin
    raise EVariantInvalidOpError.Create('Invalid SSE operation '
      +GetEnumName(TypeInfo(TSSEOp),ord(op))+' '
      +GetEnumName(TypeInfo(TSSEDataType),ord(simpletype)));
  end;

  function DoIt(const instr:ansistring;const ANewType:TSSEDataType=dtUnknown):variant;
  var fullInstr:ansistring;
  begin
    SSELoad0(L);
    if VarIsSSEImmed(R)then begin
      fullInstr:=instr+' xmm0,'+inttostr(VarSSEAccessData(R).Bytes[0]);
      AsmExecute(fullInstr);
      VarSSESetOperation(L,SSEOperations.AddOperation(op,FullInstr,L));
    end else begin
      SSELoad1(R);
      fullInstr:=instr+' xmm0,xmm1';
      AsmExecute(fullInstr);
      VarSSESetOperation(L,SSEOperations.AddOperation(op,FullInstr,L,R));
    end;
    SSEStore0(L);
    if ANewType<>dtUnknown then
      VarSSESetType(L,ANewType);
  end;

var ImmType:TSSEDataType;
    temp1,temp2:Variant;
begin
  exactType:=VarSSEType(L);
  simpleType:=SSETypeAsSigned(exactType);
  if VarIsNull(R) then begin //reg,auto
    case op of
      soUnpackLow,soUnpackHigh:begin
        if SSEDataSigned[exactType]and not SSEDataIsFloat[exactType] then begin
          temp1:=L;
          SSEOp(temp1,SSECast(exactType,0,'const'),soCmpLT);
          SSEOp(L,temp1,op);
        end else begin
          SSEOp(L,SSECast(exactType,0,'const'),op);
        end;
      end;
    else
      error;
    end;
  end else if VarIsSSEImmed(R) then begin //reg,immed
    case op of
      soShr:case exactType of
        dtWords    :DoIt('psrlw');
        dtSmallInts:DoIt('psraw');
        dtCardinals:DoIt('psrld');
        dtIntegers :DoIt('psrad');
        dtCar64s   :DoIt('psrlq');
        dtInt64s   :DoIt('psrlq');
        else error end;
      soShl:case exactType of
        dtWords,dtSmallInts   :DoIt('psllw');
        dtCardinals,dtIntegers:DoIt('pslld');
        dtInt64s,dtCar64s     :DoIt('psllq');
        else error end;
    else
      error
    end;
  end else begin                 //reg,reg
    case op of
      soAdd:case simpleType of
        dtShortInts:DoIt('paddb');
        dtSmallInts:DoIt('paddw');
        dtIntegers :DoIt('paddd');
        dtInt64s   :DoIt('paddq');
        dtSingles  :DoIt('addps');
        dtDoubles  :DoIt('addpd');
        else error;end;
      soSub:case simpleType of
        dtShortInts:DoIt('psubb');
        dtSmallInts:DoIt('psubw');
        dtIntegers :DoIt('psubd');
        dtInt64s   :DoIt('subpq');
        dtSingles  :DoIt('subps');
        dtDoubles  :DoIt('subpd');
        else error;end;
      soMulH:case exactType of
        dtSmallInts:DoIt('pmulhw');
        dtWords    :DoIt('pmulhuw');
      else error end;
      soMulL:case simpleType of
        dtSmallInts:DoIt('pmullw');
        dtIntegers :DoIt('pmulld');
      else error end;
      soMulHR:case simpleType of
        dtSmallInts:DoIt('pmulhrsw');
      else error end;
      soMul:case exactType of
        dtIntegers :DoIt('pmuldq',dtInt64s);
        dtCardinals:DoIt('pmuludq',dtCar64s);
        dtSingles:DoIt('mulps');
        dtDoubles:DoIt('mulpd');
      else error end;
      soOr:case simpleType of
        dtShortInts,dtSmallInts,dtIntegers,dtInt64s:DoIt('por');
        dtSingles  :DoIt('orps');
        dtDoubles  :DoIt('orpd');
        else error;end;
      soAnd:case simpleType of
        dtShortInts,dtSmallInts,dtIntegers,dtInt64s:DoIt('pand');
        dtSingles  :DoIt('andps');
        dtDoubles  :DoIt('andpd');
        else error;end;
      soXor:case simpleType of
        dtShortInts,dtSmallInts,dtIntegers,dtInt64s:DoIt('pxor');
        dtSingles  :DoIt('xorps');
        dtDoubles  :DoIt('xorpd');
        else error;end;
      soShr:case exactType of
        dtWords    :DoIt('psrlw');
        dtSmallInts:DoIt('psraw');
        dtCardinals:DoIt('psrld');
        dtIntegers :DoIt('psrad');
        dtCar64s   :DoIt('psrlq');
        dtInt64s   :DoIt('psrlq');
        else error;end;
      soShl:case exactType of
        dtWords,dtShortInts   :DoIt('psllw');
        dtCardinals,dtIntegers:DoIt('pslld');
        dtCar64s,dtInt64s     :DoIt('psllq');
        else error;end;
      soPackSat:case exactType of
        dtSmallInts           :DoIt('packsswb',dtShortInts);
        dtWords               :DoIt('packuswb',dtBytes);
        dtIntegers            :DoIt('packssdw',dtSmallInts);
        dtCardinals           :DoIt('packusdw',dtSmallInts);
        else error;end;
      soUnpackLow:case exactType of
        dtShortInts           :DoIt('punpcklbw',dtSmallInts);
        dtBytes               :DoIt('punpcklbw',dtWords);
        dtSmallInts           :DoIt('punpcklwd',dtIntegers);
        dtWords               :DoIt('punpcklwd',dtCardinals);
        dtIntegers            :DoIt('punpckldq',dtInt64s);
        dtCardinals           :DoIt('punpckldq',dtCar64s);
        dtInt64s,dtCar64s     :DoIt('punpcklqdq');
        dtSingles             :DoIt('unpcklps');
        dtDoubles             :DoIt('unpcklpd');
        else error;end;
      soUnpackHigh:case exactType of
        dtShortInts           :DoIt('punpckhbw',dtSmallInts);
        dtBytes               :DoIt('punpckhbw',dtWords);
        dtSmallInts           :DoIt('punpckhwd',dtIntegers);
        dtWords               :DoIt('punpckhwd',dtCardinals);
        dtIntegers            :DoIt('punpckhdq',dtInt64s);
        dtCardinals           :DoIt('punpckhdq',dtCar64s);
        dtInt64s,dtCar64s     :DoIt('punpckhqdq');
        dtSingles             :DoIt('unpckhps');
        dtDoubles             :DoIt('unpckhpd');
        else error;end;
      soCmpEq:case simpleType of
        dtShortInts:DoIt('cmpeqb');
        dtSmallInts:DoIt('pcmpeqw');
        dtIntegers :DoIt('pcmpeqd');
        dtInt64s   :DoIt('pcmpeqq');
        dtSingles  :DoIt('cmpeqps');
        dtDoubles  :DoIt('cmpeqpd');
        else error;end;
      soCmpNe:case simpleType of
        dtShortInts,dtSmallInts,dtIntegers,dtInt64s:begin
          SSEOp(L,R,soCmpEq);
          SSEOp(L,SSECast(simpleType,-1,'const'),soXor);
        end;
        dtSingles  :DoIt('cmpneqps');
        dtDoubles  :DoIt('cmpneqpd');
        else error;end;
      soCmpGt:case simpleType of
        dtShortInts:DoIt('pcmpgtb');
        dtSmallInts:DoIt('pcmpgtw');
        dtIntegers :DoIt('pcmpgtd');
        dtInt64s   :DoIt('pcmpgtq');
        dtSingles  :DoIt('cmpnleps');
        dtDoubles  :DoIt('cmpnlepd');
        else error;end;
      soCmpLt:case simpleType of
        dtShortInts,dtSmallInts,dtIntegers,dtInt64s:begin
          temp1:=R;
          SSEOp(temp1,L,soCmpGT);
          L:=temp1;
        end;
        dtSingles  :DoIt('cmpltps');
        dtDoubles  :DoIt('cmpltpd');
        else error;end;
      soCmpGe:case simpleType of
        dtShortInts,dtSmallInts,dtIntegers,dtInt64s:begin
          SSEOp(L,R,soCmpLt);
          SSEOp(L,SSECast(simpleType,-1,'const'),soXor);
        end;
        dtSingles  :DoIt('cmpnltps');
        dtDoubles  :DoIt('cmpnltpd');
        else error;end;
      soCmpLe:case simpleType of
        dtShortInts,dtSmallInts,dtIntegers,dtInt64s:begin
          SSEOp(L,R,soCmpGt);
          SSEOp(L,SSECast(simpleType,-1,'const'),soXor);
        end;
        dtSingles  :DoIt('cmpleps');
        dtDoubles  :DoIt('cmplepd');
        else error;end;
      soMax:case exactType of
        dtShortInts:DoIt('pmaxsb');
        dtBytes    :DoIt('pmaxub');
        dtSmallInts:DoIt('pmaxsw');
        dtWords    :DoIt('pmaxuw');
        dtIntegers :DoIt('pmaxsd');
        dtCardinals:DoIt('pmaxud');
        dtSingles  :DoIt('maxps');
        dtDoubles  :DoIt('maxpd');
      else error;end;
      soMin:case exactType of
        dtShortInts:DoIt('pminsb');
        dtBytes    :DoIt('pminub');
        dtSmallInts:DoIt('pminsw');
        dtWords    :DoIt('pminuw');
        dtIntegers :DoIt('pminsd');
        dtCardinals:DoIt('pminud');
        dtSingles  :DoIt('minps');
        dtDoubles  :DoIt('minpd');
      else error;end;
    else
      error
    end;
  end;
end;

procedure TSSEVariantType.BinaryOp(var Left: TVarData; const Right: TVarData; const Operator: TVarOp);
var dtLeft,dtRight:TSSEDataType;
begin
  SSEOp(variant(Left),variant(Right),VarOpToSSEOp(Operator));
end;

procedure TSSEVariantType.RelationOp(var L:variant;const R:variant;const op:TVarOp);
var typ:TVarType;
    R2:Variant;
begin
  if not VarIsSSE(R)and RightPromotion(TVarData(R),op,typ)then begin
    CastTo(TVarData(R2),TVarData(R),typ);
    BinaryOp(TVarData(L),TVarData(R2),Op);
  end else begin
    BinaryOp(TVarData(L),TVarData(R),Op);
  end;
end;

function SSEDataToStr(const ADataType:TSSEDataType;const AData:TSSEData):ansistring;
var sb:IAnsiStringBuilder;
    first:boolean;

  procedure Add(const s:ansistring);
  begin
    if first then first:=false else sb.AddStr(',');
    sb.AddStr(s);
  end;

var i,cnt:integer;
begin
  result:='';first:=true;
  sb:=AnsiStringBuilder(result);
  sb.AddChar('(');
  cnt:=SSEDataCount[ADataType];
  with AData do case ADataType of
    dtBytes     :for i:=0 to cnt-1 do Add(ToStr(Bytes[i]));
    dtShortInts :for i:=0 to cnt-1 do Add(ToStr(ShortInts[i]));
    dtWords     :for i:=0 to cnt-1 do Add(ToStr(Words[i]));
    dtSmallInts :for i:=0 to cnt-1 do Add(ToStr(SmallInts[i]));
    dtCardinals :for i:=0 to cnt-1 do Add(ToStr(Cardinals[i]));
    dtIntegers  :for i:=0 to cnt-1 do Add(ToStr(Integers[i]));
    dtInt64s    :for i:=0 to cnt-1 do Add(ToStr(Int64s[i]));
    dtCar64s    :for i:=0 to cnt-1 do Add(ToStr(Car64s[i]));
    dtSingles   :for i:=0 to cnt-1 do Add(ToStr(Singles[i]));
    dtDoubles   :for i:=0 to cnt-1 do Add(ToStr(Doubles[i]));
  else
    Add('unknown');
  end;
  sb.AddChar(')');
end;

function SSEDataToHex(const ADataType:TSSEDataType;const AData:TSSEData):ansistring;
var sb:IAnsiStringBuilder;
    first:boolean;

  procedure Add(const s:ansistring);
  begin
    if first then first:=false else sb.AddStr(',');
    sb.AddStr(s);
  end;

var i,cnt:integer;
begin
  result:='';first:=true;
  sb:=AnsiStringBuilder(result);
  sb.AddChar('(');
  cnt:=SSEDataCount[ADataType];
  with AData do case SSEDataSize[ADataType]of
    1:for i:=0 to cnt-1 do Add(IntToHex(Bytes[i],2));
    2:for i:=0 to cnt-1 do Add(IntToHex(Words[i],4));
    4:for i:=0 to cnt-1 do Add(IntToHex(Cardinals[i],8));
    8:for i:=0 to cnt-1 do Add(IntToHex(Int64s[i],16));
  else
    Add('unknown');
  end;
  sb.AddChar(')');
end;

procedure TSSEVariantType.CastTo(var Dest: TVarData; const Source: TVarData; const AVarType: TVarType);
var VDest:Variant absolute Dest;
begin
  if(Source.VType=VarType)then begin
    if(AVarType=varString)or(AVarType=varUString)or(AVarType=varStrArg)then begin
      VDest:=SSEDataToStr(TSSEDataType(Source.VLongs[2]),PSSEData(Source.VPointer)^);
    end else
      RaiseCastError;
  end else
    inherited;
end;

procedure TSSEVariantType.Cast(var Dest: TVarData; const Source: TVarData);
begin
  if VarIsOrdinal(variant(Source))then begin
    VarDataInit(Dest);
    Variant(Dest):=VSSEImmed(variant(Source));
  end else
    inherited;
end;

function TSSEVariantType.RightPromotion(const V: TVarData; const Operator: TVarOp; out RequiredVarType: TVarType): Boolean;
begin
  if(Operator in[opShiftLeft,opShiftRight])and VarIsOrdinal(variant(V))then begin
    RequiredVarType:=VarType;
    result:=true;
  end else
    result:=false;
end;

function MakeNameSpace:TNameSpace;
begin
  Result:=TNameSpace.Create('SSE');
  with Result do begin
    AddFunction('SSECompilerInit' ,function(const p:TVariantArray):variant begin SSEOperations.Init;end);
    AddFunction('SSEOperations'   ,function(const p:TVariantArray):variant begin result:=VObject(SSEOperations)end);
    AddClass(TSSEOperation);
    AddClass(TSSEOperations);
    AddObjectFunction(TSSEOperations,'Optimize',function(const o:TObject;const p:TVariantArray):variant
      begin TSSEOperations(o).Optimize end);

    AddFunction('UseRegs(regs)'  ,function(const p:TVariantArray):variant begin SSEOperations.CurrentAllowedRegs:=p[0] end);

    AddFunction('Bytes(x,...)'    ,function(const p:TVariantArray):variant begin result:=SSECast(dtBytes    ,p,'const')end);
    AddFunction('ShortInts(x,...)',function(const p:TVariantArray):variant begin result:=SSECast(dtShortInts,p,'const')end);
    AddFunction('Words(x,...)'    ,function(const p:TVariantArray):variant begin result:=SSECast(dtWords    ,p,'const')end);
    AddFunction('SmallInts(x,...)',function(const p:TVariantArray):variant begin result:=SSECast(dtSmallInts,p,'const')end);
    AddFunction('Cardinals(x,...)',function(const p:TVariantArray):variant begin result:=SSECast(dtCardinals,p,'const')end);
    AddFunction('Integers(x,...)' ,function(const p:TVariantArray):variant begin result:=SSECast(dtIntegers ,p,'const')end);
    AddFunction('Int64s(x,...)'   ,function(const p:TVariantArray):variant begin result:=SSECast(dtInt64s   ,p,'const')end);
    AddFunction('Car64s(x,...)'   ,function(const p:TVariantArray):variant begin result:=SSECast(dtCar64s   ,p,'const')end);
    AddFunction('Singles(x,...)'  ,function(const p:TVariantArray):variant begin result:=SSECast(dtSingles  ,p,'const')end);
    AddFunction('Doubles(x,...)'  ,function(const p:TVariantArray):variant begin result:=SSECast(dtDoubles  ,p,'const')end);

    AddFunction('PackSat(a,b)'    ,function(const p:TVariantArray):variant begin SSEOp(p[0],p[1],soPackSat);result:=p[0] end);
    AddFunction('UnpackLow(a,b=Null)'  ,function(const p:TVariantArray):variant begin SSEOp(p[0],p[1],soUnpackLow);result:=p[0] end);
    AddFunction('UnpackHigh(a,b=Null)' ,function(const p:TVariantArray):variant begin SSEOp(p[0],p[1],soUnpackHigh);result:=p[0] end);

    AddFunction('Min(a,b)'    ,function(const p:TVariantArray):variant begin SSEOp(p[0],p[1],soMin);result:=p[0] end);
    AddFunction('Max(a,b)'    ,function(const p:TVariantArray):variant begin SSEOp(p[0],p[1],soMax);result:=p[0] end);
    AddFunction('Mul(a,b)'    ,function(const p:TVariantArray):variant begin SSEOp(p[0],p[1],soMul);result:=p[0] end);
    AddFunction('MulL(a,b)'   ,function(const p:TVariantArray):variant begin SSEOp(p[0],p[1],soMulL);result:=p[0] end);
    AddFunction('MulH(a,b)'   ,function(const p:TVariantArray):variant begin SSEOp(p[0],p[1],soMulH);result:=p[0] end);
    AddFunction('MulHR(a,b)'  ,function(const p:TVariantArray):variant begin SSEOp(p[0],p[1],soMulHR);result:=p[0] end);

    AddFunction('LoadBytes(name)'    ,function(const p:TVariantArray):variant begin result:=SSECast(dtBytes    ,0,p[0])end);
    AddFunction('LoadShortInts(name)',function(const p:TVariantArray):variant begin result:=SSECast(dtShortInts,0,p[0])end);
    AddFunction('LoadWords(name)'    ,function(const p:TVariantArray):variant begin result:=SSECast(dtWords    ,0,p[0])end);
    AddFunction('LoadSmallInts(name)',function(const p:TVariantArray):variant begin result:=SSECast(dtSmallInts,0,p[0])end);
    AddFunction('LoadCardinals(name)',function(const p:TVariantArray):variant begin result:=SSECast(dtCardinals,0,p[0])end);
    AddFunction('LoadIntegers(name)' ,function(const p:TVariantArray):variant begin result:=SSECast(dtIntegers ,0,p[0])end);
    AddFunction('LoadInt64s(name)'   ,function(const p:TVariantArray):variant begin result:=SSECast(dtInt64s   ,0,p[0])end);
    AddFunction('LoadCar64s(name)'   ,function(const p:TVariantArray):variant begin result:=SSECast(dtCar64s   ,0,p[0])end);
    AddFunction('LoadSingles(name)'  ,function(const p:TVariantArray):variant begin result:=SSECast(dtSingles  ,0,p[0])end);
    AddFunction('LoadDoubles(name)'  ,function(const p:TVariantArray):variant begin result:=SSECast(dtDoubles  ,0,p[0])end);

    AddFunction('Store(name,SSEvalue)'  ,function(const p:TVariantArray):variant begin SSEOperations.AddStore(p[0],p[1]) end);

    AddFunction('Hex(x)',function(const p:TVariantArray):variant begin result:=SSEDataToHex(VarSSEType(p[0]),VarSSEAccessData(p[0])^)end);
  end;
end;

var
  SSEVariantType:TSSEVariantType;

initialization
//  asmtest;

  SSEVariantType:=TSSEVariantType.Create;
  pword(@varSSE)^:=SSEVariantType.VarType;

  nsSSE:=MakeNameSpace;
  RegisterNameSpace(nsSSE);

  SSEOperations:=TSSEOperations.Create(nil);
finalization
  FreeAndNil(SSEOperations);
  FreeAndNil(SSEVariantType);
  FreeAndNil(_instrInfoList);
end.
