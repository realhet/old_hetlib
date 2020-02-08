unit unsSystem; //variants het.arrays
interface

uses windows, types, sysutils, variants, classes, math, het.Utils, het.Objects,
  het.Parser, het.Variants, dialogs;

var
  nsSystem:TNameSpace;

implementation

{ TNameSpaceResult }

type TInt=class(TNameSpaceEntry)procedure Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;end;
procedure TInt.Eval;
begin
  if(AParams<>nil)and(AParams.SubNodeCount>0)then
    AResult:=integer(AParams.SubNode(0).Eval(AContext))
  else AResult:=Null;
end;

type TOrd=class(TNameSpaceEntry)procedure Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;end;
procedure TOrd.Eval;
begin
  if(AParams<>nil)and(AParams.SubNodeCount>0)then begin
    AResult:=AParams.SubNode(0).Eval(AContext);
    if VarIsStr(AResult)then
      if (length(AResult)=1)then
        AResult:=Ord(ansistring(AResult)[1])
      else
        raise Exception.Create('Cannot get Ord value of a non_one length string')
    else
      AResult:=integer(AResult)
  end else
    AResult:=Null;
end;

type TChar=class(TNameSpaceEntry)procedure Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;
                                 procedure Let(const AValue:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;end;
procedure TChar.Eval;
begin
  if(AParams<>nil)and(AParams.SubNodeCount>0)then
    AResult:=ansichar(integer(AParams.SubNode(0).Eval(AContext)))
  else AResult:=Null;
end;

procedure TChar.Let;
begin
  if(AParams<>nil)and(AParams.SubNodeCount>0)then
    AParams.SubNode(0).Let(AContext,ord(ansistring(AValue)[1]));
end;

type TInt64=class(TNameSpaceEntry)procedure Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;end;
procedure TInt64.Eval;var i:int64;
begin
  if(AParams<>nil)and(AParams.SubNodeCount>0)then begin
    i:=AParams.SubNode(0).Eval(AContext);
    AResult:=i;
  end else
    AResult:=Null;
end;

type TBool=class(TNameSpaceEntry)procedure Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;end;
procedure TBool.Eval;
begin
  if(AParams<>nil)and(AParams.SubNodeCount>0)then
    AResult:=boolean(AParams.SubNode(0).Eval(AContext))
  else AResult:=Null;
end;

type TFloat=class(TNameSpaceEntry)procedure Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;end;
procedure TFloat.Eval;
begin
  if(AParams<>nil)and(AParams.SubNodeCount>0)then
    AResult:=double(AParams.SubNode(0).Eval(AContext))
  else AResult:=Null;
end;

type TStr=class(TNameSpaceEntry)procedure Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;end;
procedure TStr.Eval;
begin
  if(AParams<>nil)and(AParams.SubNodeCount>0)then
    AResult:=ToStr(AParams.SubNode(0).Eval(AContext))
  else AResult:=Null;
end;

type TInc=class(TNameSpaceEntry)procedure Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;end;
procedure TInc.Eval;var sn:TNodeBase;
begin
  if(AParams<>nil)then begin
    sn:=AParams.SubNode(0);
    sn.Eval(AContext,AResult);
    if AParams.SubNodeCount=1 then varInc(AResult)
                              else varInc(AResult,AParams.SubNode(1).Eval(AContext));
    sn.Let(AContext,AResult);
  end else AResult:=Null;
end;

type TDec=class(TNameSpaceEntry)procedure Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;end;
procedure TDec.Eval;var sn:TNodeBase;
begin
  if(AParams<>nil)then begin
    sn:=AParams.SubNode(0);
    sn.Eval(AContext,AResult);
    if AParams.SubNodeCount=1 then varDec(AResult)
                              else varDec(AResult,AParams.SubNode(1).Eval(AContext));
    sn.Let(AContext,AResult);
  end else AResult:=Null;
end;

type TLength=class(TNameSpaceEntry)procedure Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;end;
procedure TLength.Eval;
begin with AParams do begin
  AResult:=varLength(SubNode(0).RefPtr(AContext,AResult)^);
end;end;

type TSetLength=class(TNameSpaceEntry)procedure Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;end;
procedure TSetLength.Eval;
var i:integer;
    p:TIntegerArray;
    arr:PVariant;
begin with AParams do begin
  arr:=SubNode(0).RefPtr(AContext,AResult);
  if SubNodeCount=2 then
    varSetLength(arr^,SubNode(1).Eval(AContext))
  else begin
    setlength(p,SubNodeCount-1);
    for i:=0 to SubNodeCount-2 do
      p[i]:=SubNode(i+1).Eval(AContext);
    varSetLength(arr^,p);
  end;
  if arr=@AResult then
    SubNode(0).Let(AContext,AResult);
  AResult:=Unassigned;
end;end;

type TLow=class(TNameSpaceEntry)procedure Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;end;
procedure TLow.Eval;
begin with AParams do begin
  AResult:=VarLow(SubNode(0).RefPtr(AContext,AResult)^);
end;end;

type THigh=class(TNameSpaceEntry)procedure Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;end;
procedure THigh.Eval;
begin with AParams do begin
  AResult:=VarHigh(SubNode(0).RefPtr(AContext,AResult)^);
end;end;

type TArray=class(TNameSpaceEntry)procedure Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;end;
procedure TArray.Eval;
var i:integer;
begin with AParams do begin
  AResult:=VarArrayCreate([0,AParams.ParamCount-1],varVariant);
  for i:=0 to AParams.ParamCount-1 do
    AResult[i]:=AParams.SubNode(i).Eval(AContext);
end;end;

type TDelete=class(TNameSpaceEntry)procedure Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;end;
procedure TDelete.Eval;
begin with AParams do begin
  SubNode(0).Ref(AContext,false,AResult);
  VarDelete(VarDereference(AResult)^,SubNode(1).Eval(AContext),SubNode(2).Eval(AContext));
  if not VarIsReference(AResult)then
    SubNode(0).Let(AContext,AResult);
  AResult:=Unassigned;
end;end;

type TCopy=class(TNameSpaceEntry)procedure Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;end;
procedure TCopy.Eval;
begin with AParams do begin
  SubNode(0).Ref(AContext,false,AResult);
  VarCopy(VarDereference(AResult)^,SubNode(1).Eval(AContext),SubNode(2).Eval(AContext));
end;end;

type TPos=class(TNameSpaceEntry)procedure Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;end;
procedure TPos.Eval;var sub:variant;opts:TPosOptions;from:integer;
begin with AParams do begin
  SubNode(0).Ref(AContext,false,sub);
  SubNode(1).Ref(AContext,false,AResult);
  opts:=[];
  if SubNodeCount>2 then pbyte(@opts)^:=integer(SubNode(2).Eval(AContext));
  if SubNodeCount>3 then from:=SubNode(3).Eval(AContext)
                    else from:=-1;
  AResult:=VarPos(varDereference(sub)^,varDereference(AResult)^,opts,from);
end;end;

type TInsert=class(TNameSpaceEntry)procedure Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;end;
procedure TInsert.Eval;var sub:variant;idx:integer;
begin with AParams do begin
  SubNode(0).Ref(AContext,false,sub);
  SubNode(1).Ref(AContext,false,AResult);
  idx:=SubNode(2).Eval(AContext);
  VarInsert(sub,AResult,idx);
  if not VarIsReference(AResult)then
    SubNode(1).Let(AContext,AResult);
  AResult:=Unassigned;
end;end;

type TDecodeDate=class(TNameSpaceEntry)procedure Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;end;
procedure TDecodeDate.Eval;
var y,m,d:word;
begin
  AResult:=null;
  if(AParams<>nil)and(AParams.SubNodeCount>1)then begin
    DecodeDate(AParams.SubNode(0).Eval(AContext),y,m,d);
    if AParams.SubNodeCount>1 then AParams.SubNode(1).Let(AContext,y);
    if AParams.SubNodeCount>2 then AParams.SubNode(2).Let(AContext,m);
    if AParams.SubNodeCount>3 then AParams.SubNode(3).Let(AContext,d);
  end;
end;

type TDecodeTime=class(TNameSpaceEntry)procedure Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;end;
procedure TDecodeTime.Eval;
var h,m,s,ms:word;
begin
  AResult:=null;
  if(AParams<>nil)and(AParams.SubNodeCount>1)then begin
    DecodeTime(AParams.SubNode(0).Eval(AContext),h,m,s,ms);
    if AParams.SubNodeCount>1 then AParams.SubNode(1).Let(AContext,h);
    if AParams.SubNodeCount>2 then AParams.SubNode(2).Let(AContext,m);
    if AParams.SubNodeCount>3 then AParams.SubNode(3).Let(AContext,s);
    if AParams.SubNodeCount>4 then AParams.SubNode(4).Let(AContext,ms);
  end;
end;

type
  TDateToStr=class(TNameSpaceEntry)procedure Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;
                                   procedure Let(const AValue:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;end;
procedure TDateToStr.Eval;
begin
  if(AParams<>nil)and(AParams.SubNodeCount>=1)then
    AResult:=MyDateToStr(AParams.SubNode(0).Eval(AContext))
  else
    AResult:=null;
end;

procedure TDateToStr.Let(const AValue:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);
begin
  if(AParams<>nil)and(AParams.SubNodeCount>=1)then
    AParams.SubNode(0).Let(AContext,MyStrToDate(AValue));
end;

type
  TTimeToStr=class(TNameSpaceEntry)procedure Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;
                                   procedure Let(const AValue:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;end;
procedure TTimeToStr.Eval;
begin
  if(AParams<>nil)and(AParams.SubNodeCount>=1)then
    AResult:=MyTimeToStr(AParams.SubNode(0).Eval(AContext))
  else
    AResult:=null;
end;

procedure TTimeToStr.Let(const AValue:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);
begin
  if(AParams<>nil)and(AParams.SubNodeCount>=1)then
    AParams.SubNode(0).Let(AContext,MyStrToTime(AValue));
end;

type TWrite=class(TNameSpaceEntry)procedure Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;end;
procedure TWrite.Eval;var i:integer;s:ansistring;
begin
  s:='';
  if AParams<>nil then for i:=0 to AParams.SubNodeCount-1 do
    s:=s+ToStr(AParams.SubNode(i).Eval(AContext));
  AContext.StdOutWrite(s);
end;

type TWriteLn=class(TNameSpaceEntry)procedure Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;end;
procedure TWriteLn.Eval;var i:integer;s:ansistring;
begin
  s:='';
  if AParams<>nil then for i:=0 to AParams.SubNodeCount-1 do
    s:=s+ToStr(AParams.SubNode(i).Eval(AContext));
  Acontext.StdOutWrite(s+#13#10);
end;

type TReadLn=class(TNameSpaceEntry)procedure Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;end;
procedure TReadLn.Eval;var sn:TNodeBase;
var s:string;
begin
  if(AParams<>nil)then begin
    sn:=AParams.SubNode(0);
    sn.Eval(AContext,AResult);
    if AParams.SubNodeCount=1 then begin
      InputQuery('ReadLn()', '>', s);
      AResult:=s;
    end;
    sn.Let(AContext,AResult);
  end else AResult:=Null;
end;


type T__Context=class(TNameSpaceEntry)procedure Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;end;
procedure T__Context.Eval;
begin
  AResult:=VObject(AContext);
end;

type TSwap=class(TNameSpaceEntry)procedure Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;end;
procedure TSwap.Eval;
var a:variant;
begin
  AParams.SubNode(0).Eval(AContext,a);
  AParams.SubNode(0).Let(AContext,AParams.SubNode(1).Eval(AContext));
  AParams.SubNode(1).Let(AContext,a);
end;

type TVA=array[0..0]of variant;PVA=^TVA;

procedure qs(va:PVA;L,R:integer);
var i,j:integer;
    pivot:Variant;
begin
  repeat
    I:=L;J:=R;
    pivot:=va[L+(R-L)shr 1];
    repeat
      while va^[I]<pivot do Inc(I);
      while va^[J]>pivot do Dec(J);
      if I<=J then begin
        if I<>J then Swap(va^[i],va^[j]);
        Inc(I);Dec(J);
      end;
    until I>J;
    if L<J then
      qs(va,L,J);
    L:=I;
  until I>=R;
end;

type TSort=class(TNameSpaceEntry)procedure Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;end;
procedure TSort.Eval;
var v:PVariant;
begin
  v:=AParams.SubNode(0).RefPtr(AContext);
  if VarType(V^)=varArray or varVariant then with VarArrayAsPSafeArray(V^)^do if DimCount=1 then begin
    qs(PVA(data),0,Bounds[0].ElementCount-1);
    exit;
  end;
  raise Exception.Create('Can''t sort this type of variant.');
end;

function Aggregate(const op:TVarOp;const p:TVariantArray):Variant;
var pa:PVariant;
    i,plen:integer;
begin
  case length(p) of
    0:plen:=0;
    1:begin _vArrayOp_Access(p[0],pa,plen)end;
  else plen:=length(p);pa:=@p[0]; end;

  if plen=0 then begin  //nothing to aggregate
    case op of
      opAdd,opSubtract,opMultiply,opDivide,opAnd,opOr,opXor:result:=0;
      opConcat:result:='';
    else result:=null;end;
  end else begin
    result:=pa^;inc(pa); //first element
    for i:=1 to plen-1 do begin
      case op of
        opAdd,opSubtract,opMultiply,opDivide,opAnd,opOr,opXor:vOp(op,result,pa^);
        opConcat:result:=ansistring(result)+ansistring(pa^);
      else
        raise Exception.Create('Unknown Aggregate() operation:'+tostr(op));
      end;
      inc(pa);
    end;
  end;
end;

type TPropQueryFunct=class(TNameSpaceEntry)procedure Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;end;
procedure TPropQueryFunct.Eval;
begin
  AContext.PropQuery:=AParams.SubNode(0).Eval(AContext);
  try
    AParams.SubNode(1).Eval(AContext,AResult);
  finally
    AContext.PropQuery:=pqNone;
  end;
end;


function MakeNameSpace:TNameSpace;
begin
  result:=TNameSpace.Create('System');
  with result do begin
    //constants
    AddConstant('True',True);
    AddConstant('False',False);
    AddConstant('Null',Null);
    AddConstant('Unassigned',Unassigned);
    AddConstant('Nil',VReference(nil));

    AddClass(Exception);
    AddObjectConstructor(Exception,'Create(msg)',
      function(const AParams:TVariantArray):TObject begin result:=Exception.Create(Aparams[0])end);

    //Type conversion
    Add(TChar.Create('Char(Value)'));
    Add(TInt.Create('Int(Value)'));
    Add(TOrd.Create('Ord(Value)'));//{charcode}
    Add(TInt64.Create('Int64(Value)'));
    Add(TFloat.Create('Float(Value)'));
    Add(TBool.Create('Bool(Value)'));
    Add(TStr.Create('Str(Value)'));
    AddFunction('DateTime(Value)',function(const p:TVariantArray):variant
      begin result:=TDateTime(p[0])end);

    AddFunction('IsNull(Value)',function(const p:TVariantArray):variant
      begin result:=varIsNull(p[0])end);
    AddFunction('IsEmpty(Value)',function(const p:TVariantArray):variant
      begin result:=varIsEmpty(p[0])end);

    AddFunction('Assigned(x)',function(const p:TVariantArray):variant
      begin result:=not VarIsNil(p[0]) end);

    //inc/dec
    Add(TInc.Create('Inc(X,N=1)'));
    Add(TDec.Create('Dec(X,N=1)'));
    AddFunction('Succ(X,N=1)',function(const p:TVariantArray):variant
      begin
        result:=VarSucc(p[0],p[1]);
      end);
    AddFunction('Pred(X,N=1)',function(const p:TVariantArray):variant
      begin
        result:=VarPred(p[0],p[1]);
      end);

    //length/high/low
    Add(TLength.Create('Length(S)'));
    Add(TSetLength.Create('SetLength(S,NewLength,...)'));
    Add(TLow.Create('Low(X)'));
    Add(THigh.Create('High(X)'));
    Add(TArray.Create('Array(...)'));

    //insert/delete/copy/pos
    Add(TInsert.Create('Insert(SubStr,Dest,Index)'));
    Add(TDelete.Create('Delete(S,Index,Count)'));
    Add(TCopy.Create('Copy(S,Index,Count)'));

{    AddSet(TypeInfo(TPosOptions));
    Add(TPos.Create('Pos(SubStr,Str,PosOptions=0,From=-1)'));}

    //date/time
    AddFunction('Now',function(const p:TVariantArray):variant
      begin result:=now end);
    AddFunction('Today',function(const p:TVariantArray):variant
      begin result:=Date end);
    AddFunction('Time',function(const p:TVariantArray):variant
      begin result:=GetTime end);

    Add(TDecodeDate.Create('DecodeDate(DateTime,...)'));
    Add(TDecodeDate.Create('DecodeTime(DateTime,...)'));
    Add(TDateToStr.Create('DateToStr(x)'));
    Add(TTimeToStr.Create('TimeToStr(x)'));

    AddFunction('YearOf(DateTime)',function(const p:TVariantArray):variant
      var y,m,d:word;begin DecodeDate(p[0],y,m,d);result:=y end);
    AddFunction('MonthOf(DateTime)',function(const p:TVariantArray):variant
      var y,m,d:word;begin DecodeDate(p[0],y,m,d);result:=m end);
    AddFunction('DayOf(DateTime)',function(const p:TVariantArray):variant
      var y,m,d:word;begin DecodeDate(p[0],y,m,d);result:=d end);

    AddFunction('HourOf(DateTime)',function(const p:TVariantArray):variant
      var h,m,s,z:word;begin DecodeTime(p[0],h,m,s,z);result:=h end);
    AddFunction('MinOf(DateTime)',function(const p:TVariantArray):variant
      var h,m,s,z:word;begin DecodeTime(p[0],h,m,s,z);result:=m end);
    AddFunction('SecOf(DateTime)',function(const p:TVariantArray):variant
      var h,m,s,z:word;begin DecodeTime(p[0],h,m,s,z);result:=s end);
    AddFunction('MSecOf(DateTime)',function(const p:TVariantArray):variant
      var h,m,s,z:word;begin DecodeTime(p[0],h,m,s,z);result:=z end);

    AddFunction('DayOfWeek(DateTime)',function(const p:TVariantArray):variant
      begin result:=DayOfWeek(p[0])end);
    AddFunction('IncMonth(DateTime,NumberOfMonths=1)',function(const p:TVariantArray):variant
      begin
        result:=IncMonth(p[0],p[1]);
      end);

    //math
    AddFunction('Trunc(X)',function(const p:TVariantArray):variant begin result:=Trunc(p[0])end);
    AddFunction('Floor(X)',function(const p:TVariantArray):variant begin result:=Floor(p[0])end);
    AddFunction('Ceil(X)',function(const p:TVariantArray):variant begin result:=Ceil(p[0])end);
    AddFunction('Round(X)',function(const p:TVariantArray):variant begin result:=Round(p[0])end);
    AddFunction('Frac(X)',function(const p:TVariantArray):variant begin result:=Frac(p[0])end);
    AddFunction('InRange(X,Min,Max)',function(const p:TVariantArray):variant begin result:=(p[0]>=p[1])and(p[0]<=p[2])end);
    AddFunction('EnsureRange(X,Min,Max)',function(const p:TVariantArray):variant begin if p[0]<p[1] then result:=p[1] else if p[0]>p[2] then result:=p[2]end);

    AddConstant('Pi',Pi);
    AddFunction('ArcSin(X)',function(const p:TVariantArray):variant begin result:=ArcSin(p[0])end);
    AddFunction('ArcCos(X)',function(const p:TVariantArray):variant begin result:=ArcCos(p[0])end);
    AddFunction('ArcTan2(X,Y)',function(const p:TVariantArray):variant begin result:=ArcTan2(p[0],p[1])end);
    AddFunction('Tan(X)',function(const p:TVariantArray):variant begin result:=Tan(p[0])end);

    AddFunction('Cotan(X)',function(const p:TVariantArray):variant begin result:=Cotan(p[0])end);
    AddFunction('Secant(X)',function(const p:TVariantArray):variant begin result:=Secant(p[0])end);
    AddFunction('Cosecant(X)',function(const p:TVariantArray):variant begin result:=Cosecant(p[0])end);
    AddFunction('Hypot(X,Y)',function(const p:TVariantArray):variant begin result:=Hypot(p[0],p[1])end);

    AddFunction('RadToDeg(R)',function(const p:TVariantArray):variant begin result:=p[0]*(180/pi)end);
    AddFunction('DegToRad(D)',function(const p:TVariantArray):variant begin result:=p[0]*(pi/180)end);

    AddFunction('Cot(X)',function(const p:TVariantArray):variant begin result:=Cot(p[0])end);
    AddFunction('Sec(X)',function(const p:TVariantArray):variant begin result:=Sec(p[0])end);
    AddFunction('Csc(X)',function(const p:TVariantArray):variant begin result:=Csc(p[0])end);
    AddFunction('CosH(X)',function(const p:TVariantArray):variant begin result:=CosH(p[0])end);
    AddFunction('SinH(X)',function(const p:TVariantArray):variant begin result:=SinH(p[0])end);
    AddFunction('TanH(X)',function(const p:TVariantArray):variant begin result:=TanH(p[0])end);
    AddFunction('CotH(X)',function(const p:TVariantArray):variant begin result:=CotH(p[0])end);
    AddFunction('SecH(X)',function(const p:TVariantArray):variant begin result:=SecH(p[0])end);
    AddFunction('CscH(X)',function(const p:TVariantArray):variant begin result:=CscH(p[0])end);
    AddFunction('ArcCot(X)',function(const p:TVariantArray):variant begin result:=ArcCot(p[0])end);
    AddFunction('ArcSec(X)',function(const p:TVariantArray):variant begin result:=ArcSec(p[0])end);
    AddFunction('ArcCsc(X)',function(const p:TVariantArray):variant begin result:=ArcCsc(p[0])end);
    AddFunction('ArcCosH(X)',function(const p:TVariantArray):variant begin result:=ArcCosH(p[0])end);
    AddFunction('ArcSinH(X)',function(const p:TVariantArray):variant begin result:=ArcSinH(p[0])end);
    AddFunction('ArcTanH(X)',function(const p:TVariantArray):variant begin result:=ArcTanH(p[0])end);
    AddFunction('ArcCotH(X)',function(const p:TVariantArray):variant begin result:=ArcCotH(p[0])end);
    AddFunction('ArcSecH(X)',function(const p:TVariantArray):variant begin result:=ArcSecH(p[0])end);
    AddFunction('ArcCscH(X)',function(const p:TVariantArray):variant begin result:=ArcCscH(p[0])end);

    AddFunction('Ln(X)',function(const p:TVariantArray):variant begin result:=Ln(p[0])end);
    AddFunction('LnXP1(X)',function(const p:TVariantArray):variant begin result:=LnXP1(p[0])end);
    AddFunction('Log10(X)',function(const p:TVariantArray):variant begin result:=Log10(p[0])end);
    AddFunction('Log2(X)',function(const p:TVariantArray):variant begin result:=Log2(p[0])end);
    AddFunction('LogN(X,Y)',function(const p:TVariantArray):variant begin result:=LogN(p[0],p[1])end);

    AddFunction('Sin(X)',function(const p:TVariantArray):variant begin result:=sin(p[0])end);
    AddFunction('Cos(X)',function(const p:TVariantArray):variant begin result:=cos(p[0])end);
    AddFunction('Sqr(X)',function(const p:TVariantArray):variant begin result:=p[0]*p[0]end);
    AddFunction('Sqrt(X)',function(const p:TVariantArray):variant begin result:=sqrt(p[0])end);
    AddFunction('Power(Base,Exp)',function(const p:TVariantArray):variant begin result:=Power(p[0],p[1])end);
    AddFunction('Exp(X)',function(const p:TVariantArray):variant begin result:=Exp(p[0])end);

    AddFunction('Max(A,B)',function(const p:TVariantArray):variant begin if p[0]>=p[1]then result:=p[0] else result:=p[1]end);
    AddFunction('Min(A,B)',function(const p:TVariantArray):variant begin if p[0]<=p[1]then result:=p[0] else result:=p[1]end);

    AddFunction('RandSeed',function(const p:TVariantArray):variant begin result:=RandSeed end,
                           procedure(const p:TVariantArray;const v:variant)begin RandSeed:=v end);
    AddFunction('Random(X)',function(const p:TVariantArray):variant begin result:=Random(p[0])end);
    AddFunction('RandomRange(X,Y)',function(const p:TVariantArray):variant begin result:=RandomRange(p[0],p[1])end);
    AddFunction('Randomize',function(const p:TVariantArray):variant begin Randomize end);

    AddFunction('Point(X,Y)',function(const p:TVariantArray):variant begin result:=VPoint(point(p[0],p[1]))end);
    AddFunction('Rect(Left,Top,Right,Bottom)',function(const p:TVariantArray):variant begin result:=VRect(rect(p[0],p[1],p[2],p[3]))end);

    //New things, optimize later...
    AddFunction('ByteOrderSwap(X)',function(const p:TVariantArray):variant var ii:int64;begin
      ii:=p[0];
      result:=ByteOrderSwap(ii);
    end);
    AddFunction('IntToHex(X,digits=8)',function(const p:TVariantArray):variant var i64:int64;begin
      i64:=p[0];
      result:=Inttohex(i64,p[1]);
    end);
    AddFunction('Format(fmt,...)',function(const p:TVariantArray):variant
    var va:array of TVarRec;
        i:integer;v:PVariant;
        ext:array of Extended;
        str:array of ansistring;
    begin
      setlength(va,length(p)-1);
      SetLength(ext,length(p)-1);
      SetLength(str,length(p)-1);
      for i:=0 to high(va)do with va[i]do begin
        v:=VarDereference(p[i+1]);
        if VarIsType(v^,varInt64)then begin vtype:=vtInt64;VInt64:=@TVarData(v^).VInt64;end else
        if VarIsOrdinal(v^)then begin VType:=vtInteger;VInteger:=TVarData(v^).VInteger end else
        if VarIsFloat(v^)then begin ext[i]:=v^;VType:=vtExtended;VExtended:=@ext[i]; end else begin
          str[i]:=ansistring(v^);VType:=vtAnsiString;VAnsiString:=pointer(str[i]);end;
      end;
      result:=ansistring(Format(ansistring(p[0]),va));
    end);

    AddVectorFunction('ROR(x,y)',function(const p:TVariantArray):variant
    var i:int64;
    begin
      i:=p[0];
      result:=ROR(i,p[1]);
    end);
    AddVectorFunction('ROL(x,y)',function(const p:TVariantArray):variant
    var i:int64;
    begin
      i:=p[0];
      result:=ROL(i,p[1]);
    end);

    AddFunction('FileRead(fn)',
    function(const p:TVariantArray):variant
    begin
      with TFile(p[0])do begin
        if not Exists then
          raise exception.Create('File not found: '+ansistring(p[0]));
        Result:=Read;;
      end;
    end);

    AddFunction('FileWrite(fn,s)',
    function(const p:TVariantArray):variant
    begin
      TFile(p[0]).Write(p[1]);
    end);

    AddFunction('ExpandFileName(fn)',
    function(const p:TVariantArray):variant
    begin
      Result:=ExpandFileName(p[0]);
    end);


    AddFunction('Beep',
    function(const p:TVariantArray):variant
    begin
      Beep;
    end);

    Add(TWrite.Create('Write(...)'));
    Add(TWriteLn.Create('WriteLn(...)'));
    Add(TReadLn.Create('ReadLn(var s)'));

    Add(T__Context.Create('__Context'));
    AddObjectFunction(TContext,'Param[Idx]',
      function(const o:TObject;const p:TVariantArray):variant begin result:=TContext(o).Param[p[0]]end,
      procedure(const o:TObject;const p:TVariantArray;const AValue:variant)begin TContext(o).Param[p[0]]:=AValue end);

    AddFunction('VarTypeAsText(v)',function(const p:TVariantArray):variant
      begin result:=VarTypeAsText(p[0])end);

    //some array properties
    AddDefaultObjectFunction(THetObjectList,'ByIndex[idx]',function(const o:TObject;const p:TVariantArray):variant
      begin result:=VObject(THetObjectList(o).ByIndex[p[0]])end);
    AddObjectFunction(THetObjectList,'ByID[idx]',function(const o:TObject;const p:TVariantArray):variant
      begin result:=VObject(THetObjectList(o).ByID[p[0]])end);
    AddObjectFunction(THetObjectList,'ByName[name]',function(const o:TObject;const p:TVariantArray):variant
      begin result:=VObject(THetObjectList(o).ByName[p[0]])end);

    AddFunction('Assert(b,msg)',
    function(const p:TVariantArray):variant
    begin
      Assert(boolean(p[0]),p[1]);
    end);

    AddSet(TypeInfo(TPosOptions));
    AddFunction('pos(SubStr,Str,Options,From=0)',
    function(const p:TVariantArray):variant
    var i:byte;
    begin
      i:=integer(p[2]);
      result:=pos(p[0],p[1],TPosOptions(i),p[3]);
    end);

    AddSet(TypeInfo(TReplaceOptions));
    AddFunction('ReplaceF(SubStr,ReplaceWith,Str,Options,From=0)',
    function(const p:TVariantArray):variant
    var i:byte;
    begin
      i:=integer(p[3]);
      result:=ReplaceF(p[0],p[1],p[2],TReplaceOptions(i),p[4]);
    end);

    AddFunction('Crc32(s)',function(const p:TVariantArray):variant begin
      result:=Crc32(p[0]); end);
    AddFunction('Crc32UC(s)',function(const p:TVariantArray):variant begin
      result:=Crc32UC(p[0]); end);

    AddFunction('StrToFloat(x)',function(const p:TVariantArray):variant begin
      result:=StrToFloat(p[0]); end);
    AddFunction('StrToInt(x)',function(const p:TVariantArray):variant begin
      result:=StrToInt(p[0]); end);
    AddFunction('StrToFloatDef(x,default=0)',function(const p:TVariantArray):variant begin
      result:=StrToFloatDef(p[0],p[1]); end);
    AddFunction('StrToIntDef(x,default=0)',function(const p:TVariantArray):variant begin
      result:=StrToIntDef(p[0],p[1]); end);
    AddFunction('BinToHex(s)',function(const p:TVariantArray):variant begin
      result:=BinToHex(p[0]); end);
    AddFunction('HexToBin(s)',function(const p:TVariantArray):variant begin
      result:=HexToBin(p[0]); end);

    AddFunction('ListSplit(list,separ,trim=true)',function(const p:TVariantArray):variant
      var L:TArray<ansistring>;
          i:integer;
      begin
        L:=ListSplit(p[0],charn(p[1],1),p[2]);
        result:=VarArrayCreate([0,high(L)],varVariant);
        for i:=0 to high(L)do result[i]:=L[i];
      end);


    AddFunction('VarIsEmpty(v)',function(const p:TVariantArray):variant begin
      result:=VarIsEmpty(p[0]);
    end);

    AddFunction('Sum(...)',     function(const p:TVariantArray):variant begin result:=Aggregate(opAdd         ,p); end);
    AddFunction('StrSum(...)',  function(const p:TVariantArray):variant begin result:=Aggregate(opConcat      ,p); end);
    AddFunction('Prod(...)',    function(const p:TVariantArray):variant begin result:=Aggregate(opMultiply    ,p); end);
    AddFunction('AndSum(...)',  function(const p:TVariantArray):variant begin result:=Aggregate(opAnd         ,p); end);
    AddFunction('OrSum(...)',   function(const p:TVariantArray):variant begin result:=Aggregate(opOr          ,p); end);
    AddFunction('XorSum(...)',  function(const p:TVariantArray):variant begin result:=Aggregate(opXor         ,p); end);

    AddFunction('Exit(...)',    function(const c:TContext;const p:TVariantArray):variant begin
      case length(p) of
        0:c.ExitContext;
        1:c.ExitContext(p[0]);
      else raise Exception.Create('Too many parameters in Exit()')end;
    end);
    AddFunction('Break(cnt=1)', function(const c:TContext;const p:TVariantArray):variant begin
      c.BreakContext(p[0]);
    end);
    AddFunction('Continue',     function(const c:TContext;const p:TVariantArray):variant begin c.ContinueContext;end);

    Add(TSwap.Create('Swap(var x,y)'));
    Add(TSort.Create('Sort(var x)'));

    AddEnum(TypeInfo(TPropQuery));
    Add(TPropQueryFunct.Create('PropQuery(pqType,PropValue)'));
  end;
end;

initialization
  nsSystem:=MakeNameSpace;
  RegisterNameSpace(nsSystem);
  _SystemNamespace:=nsSystem;
finalization
end.



