unit het.Variants; //forms classes hetObject variants het.Parser unssse
interface
uses Windows, sysutils, variants, het.Utils, het.Arrays, math, typinfo;

type
  TCustomVariantTypeSpecialRelation=class(TCustomVariantType)
  public
    procedure RelationOp(var L:variant;const R:variant;const op:TVarOp);virtual;abstract;
    function AsObject(const V:TVarData):TObject;virtual;
  end;

function VarArrayEqual(const a,b:Variant):boolean;

procedure VarInc(var v:variant;const amount:integer=1);
procedure VarDec(var v:variant;const amount:integer=1);
function VarSucc(const v:variant;const amount:integer=1):variant;
function VarPred(const v:variant;const amount:integer=1):variant;

function VarAsAnsiChar(const v:variant):ansichar;
function VarAsUnicodeChar(const v:variant):char;

function VarArrayAccess(const v:Variant;const idx:integer):PVariant;overload;
function VarArrayAccess(const v:Variant;const idx:TIntegerArray;const ActIdx:integer=0):PVariant;overload;

function VarArrayGetDyn(const V:variant;const idx:integer):variant;overload;
function VarArrayGetDyn(const V:variant;const idx:TIntegerArray):variant;overload;

procedure VarArraySetDyn(var V:variant;const idx:integer;const newValue:variant);overload;
procedure VarArraySetDyn(var V:variant;const idx:TIntegerArray;const newValue:variant);overload;

function VarArrayAccessNamed(const v:Variant;const AName:ansistring):PVariant;overload;

function VarLength(const v:variant):integer;
procedure VarSetLength(var v:variant;newLen:integer);overload;
procedure VarSetLength(var v:variant;const newLen:TIntegerArray;const ActLevel:integer=0);overload;
function VarLow(const V:variant):integer;
function VarHigh(const V:variant):integer;

procedure VarDelete(var v:variant;idx,len:Integer);
procedure VarCopy(var v:variant;idx,len:integer);
procedure VarInsert(const SubV:variant;Var V:Variant;idx:integer);
function VarPos(const substr,str:variant;const Options:TPosOptions;from:integer=-1):integer;
procedure VarArrayConcat(var Left:variant;const right:variant);

const varEnum:TVarType=0;

function VEnum(const OrdValue:integer;const TypeInfo:PTypeInfo):variant;
function VarIsEnum(const V:variant):boolean;
function VarEnumType(const V:Variant):PTypeInfo;
function VarEnumTypeName(const V:Variant):ansistring;

type
  TSetElementType=(stSingle,stRange);
  TSetElement=record
    typ:TSetElementType;
    e1,e2:variant;
    function Contains(const v:variant):boolean;
    function Min:variant;
    function Max:variant;
  end;

  TSetArray=class(TObject)
  public
    Elements:THetArray<TSetElement>;
    function Contains(const v:variant):boolean;
    procedure Assign(const src:TSetArray);overload;
    procedure AddSingle(const v:variant);
    procedure AddRange(const v1,v2:variant);
    procedure AddElement(const e:TSetElement);
    procedure AddSet(const a:TSetArray);
    procedure RemoveSingle(const v:Variant);
    procedure RemoveRange(const v1,v2:Variant);
    procedure RemoveElement(const e:TSetElement);
    procedure RemoveSet(const a:TSetArray);
    procedure XorSet(const a:TSetArray);
    procedure AndSet(const a:TSetArray);
    function ToStr:AnsiString;
    function ToInt:integer;
    function IsWild(const s:AnsiString):boolean;
    function Min:variant;
    function Max:variant;
  end;

const varSet:TVarType=0;

function VSet:Variant;overload;
function VSet(const ASetArray:TSetArray):Variant;overload;
function VSet(const AElement:Variant):Variant;overload;
function VSetOrdinal(const AOrdinal:integer):Variant;overload;
function VSetOrdinal(const AOrdinal:integer;ATypeInfo:PTypeInfo):Variant;overload;
function VSetRange(const mi,ma:variant):Variant;
function VarIsSet(const V:variant):boolean;
function VarSetIsEmpty(const V:Variant):boolean;
function VarAsSetArray(const V:Variant):TSetArray;
function VarSetType(const V:Variant):PTypeInfo;
function VarSetTypeName(const V:Variant):ansistring;

const varReference:TVarType=0; //combined TObject or PVariant

function VReference(const P:PVariant):Variant;overload;
function VReference(var V:Variant):Variant;overload;
function VarIsReference(const V:variant):boolean;
function VarDereference(const V:Variant):PVariant;

//varObject is a special type of Reference
function VObject(const AObject:TObject):Variant;
function VarIsObject(const V:variant):boolean;overload;
function VarIsObject(const V:variant;AClass:TClass):boolean;overload;
function VarIsNil(const V:variant):boolean;
function VarAsObject(const V:Variant):TObject;overload;
function VarAsObject(const V:Variant;AClass:TClass):TObject;overload;

type
  TClassReference=class
  private
    FClass:TClass;
  public
    constructor Create(const AClass:TClass);
    property ReferencedClass:TClass read FClass;
    function ToString:string;override;
  end;

function VClass(const AClass:TClass):variant;
function VarIsClass(const V:Variant):boolean;
function VarAsClass(const V:Variant;const ABaseClass:TClass=nil):TClass;

const varNamed:TVarType=0; //named variant

function VNamed(const AName:ansistring;const V:variant):Variant;
function VarIsNamed(const V:variant):boolean;
function VarNamedGetName(const V:variant):ansistring;
procedure VarNamedSetName(const V:variant;const AName:ansistring);
function VarNamedGetValue(const V:variant):variant;
procedure VarNamedSetValue(const V:variant;const AValue:variant);
function VarNamedRefValue(const V:variant):PVariant;


function VPoint(const P:TPoint):Variant;
function VarAsPoint(const V:Variant):TPoint;

function VRect(const R:TRect):Variant;
function VarAsRect(const V:Variant):TRect;

implementation

uses VarUtils, Het.Patch;

function TCustomVariantTypeSpecialRelation.AsObject(const V:TVarData):TObject;
begin
  raise EVariantInvalidOpError.Create('cast to TObject not implemented');
end;

{*******************************************************}
{                 Utility functions                     }
{*******************************************************}

function VarArrayEqual(const a,b:Variant):boolean;
var i:integer;
begin
  if not VarIsArray(A)or not VarIsArray(B)or
    (VarArrayDimCount(A)<>1)or(VarArrayDimCount(B)<>1)or  //fack multidim atm.
    (VarArrayLowBound(A,1)<>VarArrayLowBound(B,1))or
    (VarArrayHighBound(A,1)<>VarArrayHighBound(B,1))then exit(false);
  for i:=VarArrayLowBound(A,1)to VarArrayHighBound(A,1)do
    if VarIsArray(a[i])then begin
      if not VarArrayEqual(a[i],b[i])then exit(false);    //only nested arrays are working
    end else
      if a[i]<>b[i] then exit(false);
  result:=true;
end;

procedure VarInc(var v:variant;const amount:integer=1);
begin
  if VarIsStr(v)and(length(v)=1)then
    v:=ansichar(ord(AnsiString(v)[1])+amount)
  else
    inc(v,amount);
end;

procedure VarDec(var v:variant;const amount:integer=1);
begin
  if VarIsStr(v)and(length(v)=1)then
    v:=ansichar(ord(AnsiString(v)[1])-amount)
  else
    dec(v,amount);
end;

function VarSucc(const v:variant;const amount:integer=1):variant;
begin
  if VarIsStr(v)and(length(v)=1)then
    result:=ansichar(ord(AnsiString(v)[1])+amount)
  else begin
    result:=v;inc(result,amount);
  end;
end;

function VarPred(const v:variant;const amount:integer=1):variant;
begin
  if VarIsStr(v)and(length(v)=1)then
    result:=ansichar(ord(AnsiString(v)[1])-amount)
  else begin
    result:=v;dec(result,amount);
  end;
end;

function VarLength(const v:variant):integer;
begin
  if varIsArray(v)then Result:=VarArrayHighBound(v,1)-VarArrayLowBound(v,1)+1
                  else Result:=Length(v);
end;

function VarArrayAccess(const v:Variant;const idx:integer):PVariant;
begin
  if VarType(V)=varArray or varVariant then begin
    with VarArrayAsPSafeArray(V)^do
      result:=PVariant(integer(Data)+(idx-Bounds[0].LowBound)*ElementSize);
  end else
    raise EVariantInvalidArgError.Create('varArrayAccess() invalid type '+VarTypeAsText(VarType(v)));
end;

function VarArrayAccess(const v:Variant;const idx:TIntegerArray;const ActIdx:integer=0):PVariant;
begin
  if(ActIdx<0)or(ActIdx>high(idx))then
    raise EVariantInvalidArgError.Create('varArrayAccess() invalid indexing parameters');
  if VarType(V)=varArray or varVariant then begin
    with VarArrayAsPSafeArray(V)^do begin
      result:=PVariant(integer(Data)+(idx[ActIdx]-Bounds[0].LowBound)*ElementSize);
      if actidx<high(idx) then
        result:=VarArrayAccess(result^,idx,ActIdx+1); //nem rekurziv!!!
    end;
  end else
    raise EVariantInvalidArgError.Create('varArrayAccess() invalid type '+VarTypeAsText(VarType(v)));
end;

function VarAsAnsiChar(const v:variant):ansichar;
var s:ansistring;
begin
  if VarIsStr(V)then begin
    s:=ansistring(v);
    if length(s)<>1 then
      raise EVariantTypeCastError.Create('Cannot convert string variant to ansichar where length<>1');
    result:=s[1]
  end else
    raise EVariantTypeCastError.Create('Cannot convert variant to ansichar');
end;

function VarAsUnicodeChar(const v:variant):Char;
var s:string;
begin
  if VarIsStr(V)then begin
    s:=string(v);
    if length(s)<>1 then
      raise EVariantTypeCastError.Create('Cannot convert string variant to ansichar where length<>1');
    result:=s[1]
  end else
    raise EVariantTypeCastError.Create('Cannot convert variant to ansichar');
end;

function VarArrayGetDyn(const V:variant;const idx:integer):variant;
  procedure CheckBounds(lo,hi:integer);
  begin
    if(idx<lo)or(idx>hi)then
      raise EVariantRangeCheckError.Create('VarArrayGetDyn() string index out of bounds');
  end;
var s:ansistring;
begin
  if VarIsStr(V) then begin
    case VarType(V)of
      varString:begin
        CheckBounds(1,length(ansistring(TVarData(V).VString)));
        result:=ansistring(TVarData(V).VString)[idx];
      end;
      varUString:begin
        CheckBounds(1,length(string(TVarData(V).VString)));
        result:=string(TVarData(V).VString)[idx];
      end;
    else
      s:=ansistring(V);
      CheckBounds(1,length(s));
      result:=s[idx];
    end;
  end else if VarIsArray(V)then begin
    result:=V[idx];
  end else
    raise EVariantInvalidArgError.Create('varArrayGetDyn() invalid type '+VarTypeAsText(VarType(v)));
end;

function VarArrayGetDyn(const V:variant;const idx:TIntegerArray):variant;
var i:integer;p:PVariant;
begin
  if length(idx)=0 then
    raise EVariantInvalidArgError.Create('varArrayGetDyn() invalid indexing parameters');
  p:=@V;
  for i:=0 to high(idx)-1 do p:=VarArrayAccess(p^,idx[i]);
  result:=VarArrayGetDyn(P^,idx[high(idx)]);
end;

procedure VarArraySetDyn(var V:variant;const idx:integer;const newValue:variant);
  procedure CheckBounds(lo,hi:integer);
  begin
    if(idx<lo)or(idx>hi)then
      raise EVariantRangeCheckError.Create('VarArraySetDyn() string index out of bounds');
  end;

var s:ansistring;
begin
  if VarIsStr(V) then begin
    case VarType(V)of
      varString:begin
        CheckBounds(1,length(ansistring(TVarData(V).VString)));
        PAnsiChar(TVarData(V).VString)[idx-1]:=VarAsAnsiChar(newValue);
      end;
      varUString:begin
        CheckBounds(1,length(string(TVarData(V).VUString)));
        PChar(TVarData(V).VUString)[idx-1]:=VarAsUnicodeChar(newValue);
      end;
    else
      s:=ansistring(V);
      CheckBounds(1,length(s));
      s[idx]:=VarAsAnsiChar(newValue);
      V:=s;
    end;
  end else if VarIsArray(V)then begin
    VarArrayAccess(V,idx)^:=newValue;
  end else
    raise EVariantInvalidArgError.Create('varArraySetDyn() invalid type '+VarTypeAsText(VarType(v)));
end;

procedure VarArraySetDyn(var V:variant;const idx:TIntegerArray;const newValue:variant);
var i:integer;p:PVariant;
begin
  if length(idx)=0 then
    raise EVariantInvalidArgError.Create('varArrayGetDyn() invalid indexing parameters');
  p:=@V;
  for i:=0 to high(idx)-1 do p:=VarArrayAccess(p^,idx[i]);
  VarArraySetDyn(P^,idx[high(idx)],newValue);
end;

function VarArrayAccessNamed(const v:Variant;const AName:ansistring):PVariant;overload;
var i:integer;
begin
  if VarType(V)=varArray or varVariant then begin
    with VarArrayAsPSafeArray(V)^do begin
      for i:=0 to Bounds[0].ElementCount-1 do begin
        result:=PVariant(integer(Data)+i shl 4{variant});
        if VarIsNamed(result^)and(cmp(VarNamedGetName(result^),AName)=0)then
          exit;
      end;
      result:=nil;
    end;
  end else
    raise EVariantInvalidArgError.Create('varArrayAccessNamed() invalid type '+VarTypeAsText(VarType(v)));
end;

function VarArrayGetNamedValue(const v:Variant;const AName:ansistring):Variant;overload;
var p:PVariant;
begin
  p:=VarArrayAccessNamed(v,AName);
  if p=nil then result:=Unassigned
           else result:=VarNamedGetValue(p^);
end;

{ DONE : VarSetLength legyen multidimensional }
procedure varSetLength(var v:variant;newLen:integer);
var s:ansistring;oldLen:integer;
begin
  if newLen<0 then newLen:=0;
  if varIsArray(v)then begin
    VarArrayRedim(v,newLen-1);
  end else if VarIsStr(v) then begin
    s:=ansistring(v);
    oldLen:=length(s);
    setlength(s,newLen);
    if newLen>oldLen then FillChar(s[oldLen+1],newLen-oldLen,0);
    v:=s;
  end else
    raise EVariantInvalidArgError.Create('varSetLength() invalid type '+VarTypeAsText(VarType(v)));
end;

procedure varSetLength(var v:variant;const newLen:TIntegerArray;const ActLevel:integer=0);
var i:integer;
begin
  if(ActLevel<0)or(ActLevel>high(newLen))then
    raise EVariantInvalidArgError.Create('varSetLength() invalid indexing parameters');
  if VarIsArray(V) then begin
    VarSetLength(v,newLen[ActLevel]);
    if ActLevel<high(newLen)then
      for i:=varLow(v)to varHigh(v)do
        VarSetLength(VarArrayAccess(v,i)^,newLen,ActLevel+1);
  end else if VarIsStr(V) then begin
    if ActLevel<>high(newLen)then raise EVariantInvalidArgError.Create('varSetLength() too many parameters');
    VarSetLength(v,newLen[ActLevel]);
  end else if ActLevel>0 then begin
    v:=VarArrayCreate([0,newLen[ActLevel]-1],varVariant);
  end else
    raise EVariantInvalidArgError.Create('varSetLength() invalid type '+VarTypeAsText(VarType(v)));
end;

function VarLow(const V:variant):integer;
begin
  if varIsArray(V)then result:=VarArrayLowBound(V,1)else
  if VarIsStr(V)  then result:=1
                  else raise EVariantInvalidArgError.Create('Low() array type required');
end;

function VarHigh(const V:variant):integer;
begin
  if varIsArray(V)then result:=VarArrayHighBound(V,1)else
  if VarIsStr(V)  then result:=1
                  else raise EVariantInvalidArgError.Create('Higs() array type required');
end;

procedure VarDelete(var v:variant;idx,len:Integer);
var s:ansistring;i,aLen,lBound:integer;
begin
  if idx<0 then begin
//    len:=len+idx;  //system.delete compatibility
    idx:=0;
  end;
  if len<=0 then exit;

  if VarIsArray(v)then begin
    aLen:=VarLength(v);
    if idx+len>aLen then begin
      len:=aLen-idx;
      if len<=0 then exit;
    end;
    lBound:=VarArrayLowBound(v,1);
    for i:=idx+len+lBound to aLen-1+lBound do
      VarArrayPut(v,VarArrayGet(v,[i]),[i-len]);
    VarArrayRedim(v,aLen-len+lBound-1);
  end else if VarIsStr(v) then begin
    s:=ansistring(v);
    Delete(s,idx,len);
    v:=s;
  end else
    Raise EVariantInvalidArgError.Create('VarDelete() invalid type '+VarTypeAsText(VarType(v)));
end;

procedure VarCopy(var v:Variant;idx,len:integer);
var s:AnsiString;aLen:Integer;
begin
  if VarIsArray(v) then begin
    if idx<0 then begin
//      len:=len+idx; //system.copy compatibility
      idx:=0;
    end;
    aLen:=varLength(v);
    if idx+len>aLen then
      len:=aLen-idx;
    if len<=0 then begin
      VarArrayRedim(V,VarArrayLowBound(V,1)-1);
      exit;
    end;

    VarArrayRedim(V,VarArrayLowBound(V,1)+idx+len-1);
    VarDelete(V,0,idx);
  end else begin
    s:=ansistring(v);
    v:=ansistring(copy(s,idx,len));
  end;
end;

procedure VarInsert(const SubV:variant;Var V:Variant;idx:integer);
var s:ansistring;VLen,SubVLen,i:integer;
begin
  if VarIsArray(V) then begin
    if idx<0 then idx:=0;
    vLen:=varLength(V);
    if idx>VLen then idx:=VLen;
    if VarIsArray(SubV)then begin
      SubVLen:=VarLength(SubV);
      if SubVLen<=0 then exit;

      VarArrayRedim(V,VLen+SubVLen-1);
      for i:=VLen+SubVLen-1 downto idx+SubVLen do
        VarArrayPut(V,VarArrayGet(V,[i-SubVLen]),[i]);

      for i:=0 to SubVLen-1 do
        VarArrayPut(V,VarArrayGet(SubV,[i]),[i+idx]);
    end else begin
      SubVLen:=1;

      VarArrayRedim(V,VLen+SubVLen-1);
      for i:=VLen+1{SubVLen}-1 downto idx+1{SubVLen} do
        VarArrayPut(V,VarArrayGet(V,[i-1{SubVLen}]),[i]);

      VarArrayPut(V,SubV,[idx]);
    end;
  end else if VarIsStr(V) then begin
    s:=ansistring(V);
    Insert(ansistring(SubV),s,idx);
    V:=s;
  end else
    raise EVariantInvalidArgError('VarInsert() invalid type '+VarTypeAsText(VarType(V)));
end;

function VarPos(const substr,str:variant;const Options:TPosOptions;from:integer=-1):integer;
var i,j:integer;
    SubStrLen,StrLen:integer;
begin
  if VarIsArray(str)then begin
    if VarIsArray(subStr)then begin//arr,arr
      result:=-1;
      StrLen:=varlength(Str);
      SubStrLen:=varLength(SubStr);
      if(strlen=0)or(SubStrLen=0)then exit;
      if not(poBackwards in Options)then begin//forwards
        if From>=0 then i:=From else i:=0;
        j:=0;
        for i:=i to StrLen-1 do begin
          if VarArrayGet(str,[i])=VarArrayGet(SubStr,[j]) then begin
            inc(j);if j>=SubStrLen then
              begin result:=i-subStrLen+1;break end;
          end else j:=0;
        end
      end else begin//backwards
        if From>=0 then i:=From else i:=$7fffffff;
        if i>=StrLen then i:=StrLen-1;
        j:=SubStrLen-1;
        for i:=i downto 0 do begin
          if VarArrayGet(str,[i])=VarArrayGet(SubStr,[j]) then begin
            dec(j);if j<0 then
              begin result:=i;break end;
          end else j:=SubStrLen-1;
        end;
      end;
      if(result>=0)and(poReturnEnd in Options)then
        inc(result,SubStrLen);
    end else begin//var,arr
      result:=-1;
      StrLen:=varlength(Str);
      if(strlen=0)then exit;
      if not(poBackwards in Options)then begin//forwards
        if From>=0 then i:=From else i:=0;
        for i:=i to StrLen-1 do
          if VarArrayGet(str,[i])=SubStr then begin result:=i;break end;
      end else begin//backwards
        if From>=0 then i:=From else i:=$7fffffff;
        if i>=StrLen then i:=StrLen-1;
        for i:=i downto 0 do
          if VarArrayGet(str,[i])=SubStr then begin result:=i;break end;
      end;
      if(result>=0)and(poReturnEnd in Options)then
        inc(result,1);
    end;
  end else if VarIsStr(str)then begin
    result:=het.Utils.Pos(ansistring(substr),ansistring(str),Options,from);
    if result=0 then dec(result);//-1 compatibility
  end else
    raise EVariantInvalidArgError('VarPos() invalid type '+VarTypeAsText(VarType(str)));
end;

procedure VarArrayConcat(var Left:variant;const right:variant);
var i,hb,len:integer;
begin
  if not VarIsArray(left)then
    raise EVariantInvalidArgError('VarArrayConcat() invalid type '+VarTypeAsText(VarType(Left)));
  hb:=VarArrayHighBound(Left,1);
  if VarIsArray(right)then begin
    len:=VarLength(right);
    VarArrayRedim(Left,hb+len);
    inc(hb);
    for i:=0 to len-1 do
      VarArraySetDyn(left,hb+i,VarArrayGetDyn(Right,i));
  end else begin
    VarArrayRedim(Left,hb+1);
    VarArraySetDyn(left,hb+1,Right);
  end;
end;

{*******************************************************}
{                   Enum Variant Type                   }
{*******************************************************}

type
  TEnumVariantType=class(TCustomVariantType)
  private
  protected
  public
    procedure Clear(var V: TVarData); override;
    procedure Copy(var Dest: TVarData; const Source: TVarData; const Indirect: Boolean); override;
    procedure CastTo(var Dest: TVarData; const Source: TVarData; const AVarType: TVarType);override;
    procedure Cast(var Dest: TVarData; const Source: TVarData); override;
    procedure Compare(const Left, Right: TVarData; var Relationship: TVarCompareResult);override;
    procedure BinaryOp(var Left: TVarData; const Right: TVarData; const Operator: TVarOp);override;
    function RightPromotion(const V: TVarData; const Operator: TVarOp; out RequiredVarType: TVarType): Boolean; override;
  end;

function VEnum(const OrdValue:integer;const TypeInfo:PTypeInfo):variant;
begin
  VarClear(Result);
  with TVarData(Result)do begin
    VType:=varEnum;
    VInteger:=OrdValue;
    VLongs[2]:=integer(TypeInfo);
  end;
end;

function VarIsEnum(const V:variant):boolean;
begin
  result:=VarIsType(V,varEnum);
end;

function VarEnumType(const V:Variant):PTypeInfo;
begin
  if VarIsEnum(V) then result:=PTypeInfo(TVarData(V).VLongs[2])
                  else result:=nil;
end;

function VarEnumTypeName(const V:Variant):ansistring;
var ti:PTypeInfo;
begin
  ti:=VarEnumType(V);
  if ti<>nil then result:=ti.Name
             else result:='nil';
end;

procedure TEnumVariantType.Clear(var V: TVarData);
begin
  SimplisticClear(V);
end;

procedure TEnumVariantType.Copy(var Dest: TVarData; const Source: TVarData; const Indirect: Boolean);
begin
  SimplisticCopy(Dest,Source,Indirect);
end;

procedure TEnumVariantType.CastTo(var Dest: TVarData; const Source: TVarData; const AVarType: TVarType);
var ti:PTypeInfo;
begin
  if(Source.VType=VarType)then begin
    if(AVarType=varString)or(AVarType=varUString)or(AVarType=varStrArg)then begin
      ti:=PTypeInfo(Source.VLongs[2]);
      if ti<>nil then variant(Dest):=GetEnumName(ti,Source.VInteger)
                 else variant(Dest):=ToStr(Source.VInteger);
    end else if(AVarType in[varInteger,varLongWord,varSmallint,varWord,varByte,varShortInt])then begin
      variant(Dest):=Source.VInteger;
    end;
  end else
    inherited;
end;

procedure TEnumVariantType.Compare(const Left, Right: TVarData; var Relationship: TVarCompareResult);
begin
  if left.VInteger<right.VInteger then
    Relationship:=crLessThan
  else if left.VInteger>right.VInteger then
    Relationship:=crGreaterThan
  else
    Relationship:=crEqual;
end;

function TEnumVariantType.RightPromotion(const V: TVarData; const Operator: TVarOp; out RequiredVarType: TVarType): Boolean;
begin
  if(Operator in[opAdd,opSubtract])and VarIsOrdinal(variant(V))then begin
    RequiredVarType:=VarType;
    result:=true;
  end else
    result:=false;
end;

procedure TEnumVariantType.Cast(var Dest: TVarData; const Source: TVarData);
begin
  if VarIsOrdinal(variant(Source))then begin
    VarDataInit(Dest);
    Variant(Dest):=VEnum(integer(variant(Source)),nil);
  end else
    inherited;
end;

procedure TEnumVariantType.BinaryOp(var Left: TVarData; const Right: TVarData; const Operator: TVarOp);
begin
  if(left.VType=VarType)and((right.vType=VarType)or VarIsOrdinal(variant(Right)))then case Operator of
    opAdd:left.VInteger:=left.VInteger+integer(variant(right));
    opSubtract:left.VInteger:=left.VInteger-integer(variant(right));
  else inherited end else inherited;
end;

{*******************************************************}
{                    Set Variant Type                   }
{*******************************************************}

function TSetElement.Contains(const v:variant):boolean;
begin
  try
    case typ of
      stRange:result:=(v>=e1)and(v<=e2);
      else result:=(v=e1);
    end;
  except
    result:=false;
  end;
end;

procedure TSetArray.Assign(const src:TSetArray);
var i:integer;
begin
  if src=nil then
    Elements.Clear
  else with Elements do begin
    FCount:=src.Elements.FCount;
    SetLength(FItems,FCount);
    for i:=0 to high(FItems)do
      FItems[i]:=src.Elements.FItems[i];
  end;
end;

function TSetArray.Contains(const v: Variant):boolean;
var i:integer;
begin
  for i:=0 to Elements.FCount-1 do if Elements.FItems[i].Contains(v) then exit(true);
  result:=false;
end;

procedure TSetArray.AddSingle(const v:variant);
var tmp:TSetElement;
begin
  if not Contains(v)then begin
    tmp.typ:=stSingle;
    tmp.e1:=v;
    tmp.e2:=null;
    Elements.Append(tmp);
  end;
end;

procedure TSetArray.AddRange(const v1,v2:variant);
var tmp:TSetElement;
    i:integer;
begin
  if v1=v2 then begin
    AddSingle(v1)
  end else begin
    tmp.typ:=stRange;
    if v2>v1 then begin tmp.e1:=v1;tmp.e2:=v2 end
             else begin exit;{csokkeno set=empty range, nem sorted!!!! tmp.e1:=v2;tmp.e2:=v1} end;
    for i:=Elements.FCount-1 downto 0 do with Elements.FItems[i]do begin
      if typ=stSingle then begin
        if tmp.Contains(e1)then begin
          e1:=null;e2:=null;Elements.Remove(i);
        end;
      end else begin
        if not((e2<tmp.e1)or(e1>tmp.e2))then begin
          if e1<tmp.e1 then tmp.e1:=e1;
          if e2>tmp.e2 then tmp.e2:=e2;
          e1:=null;e2:=null;Elements.Remove(i);
        end;
      end;
    end;
    Elements.Append(tmp);
  end;
end;

procedure TSetArray.AddElement(const e:TSetElement);
begin
  if e.typ=stSingle then AddSingle(e.e1)
                    else AddRange(e.e1,e.e2);
end;

procedure TSetArray.AddSet(const a:TSetArray);
var i:integer;
begin
  for i:=0 to a.Elements.FCount-1 do
    AddElement(a.Elements.FItems[i]);
end;

procedure TSetArray.RemoveSingle;
var i:integer;
    tmp:TSetElement;
begin
  for i:=Elements.FCount-1 downto 0 do with Elements.FItems[i]do begin
    if contains(v)then begin
      if typ=stSingle then begin
        e1:=null;e2:=null;Elements.Remove(i);
        exit;
      end else begin
        if v=e1 then begin
          VarInc(e1);
          if e1=e2 then typ:=stSingle;
          exit;
        end else if v=e2 then begin
          VarDec(e2);
          if e2=e1 then typ:=stSingle;
          exit;
        end else begin//plit
          tmp.e1:=e1;
          tmp.e2:=v;VarDec(tmp.e2);
          if tmp.e1=tmp.e2 then tmp.typ:=stSingle else tmp.typ:=stRange;

          e1:=v;VarInc(e1);
          if e1=e2 then typ:=stSingle;

          Elements.Append(tmp);
          exit;
        end;
      end;
    end;
  end;
end;

procedure TSetArray.RemoveRange;
var a1,a2:variant;
    i:integer;
begin
  if v1=v2 then begin RemoveSingle(v1);exit end;
  if v2>v1 then begin a1:=v1;a2:=v2;end
           else begin a1:=v2;a2:=v1;end;
  //split
  RemoveSingle(v1);
  RemoveSingle(v2);

  for i:=Elements.FCount-1 downto 0 do with Elements.FItems[i]do begin
    if((typ=stSingle)and(a1<=e1)and(a2>=e1))or((typ=stRange)and(a1<=e1)and(a2>=e2))then begin
      e1:=null;e2:=null;Elements.Remove(i);
    end;
  end;
end;

procedure TSetArray.RemoveElement(const e:TSetElement);
begin
  if e.typ=stSingle then RemoveSingle(e.e1)
                    else RemoveRange(e.e1,e.e2);
end;

procedure TSetArray.RemoveSet(const a:TSetArray);
var i:integer;
begin
  for i:=0 to a.Elements.FCount-1 do
    RemoveElement(a.Elements.FItems[i]);
end;

procedure TSetArray.XorSet(const a:TSetArray);
var tmp:TSetArray;
begin
  tmp:=TSetArray.Create;
  try
    //(self-a)+(a-self)
    {a-self}tmp.Assign(a);tmp.RemoveSet(self);
    {self-a}RemoveSet(a);
    {+}AddSet(tmp);
  finally
    tmp.Free
  end;
end;

procedure TSetArray.AndSet(const a:TSetArray);
var tmp:TSetArray;
begin
  tmp:=TSetArray.Create;
  try
    //(self+a)-((self-a)+(a-self))
    {xor}tmp.Assign(self);tmp.XorSet(a);
    {self+a}AddSet(a);
    {-}RemoveSet(tmp);
  finally
    tmp.Free;
  end;
end;

function TSetArray.ToInt: Integer;
var i:integer;
begin
  result:=0;
  for i:=0 to 31 do
    if Contains(i)then
      result:=result or(1 shl i);
end;

function TSetArray.ToStr: AnsiString;
var i:integer;
begin
  result:='';
  with AnsiStringBuilder(result)do begin
    AddChar('[');
    for i:=0 to Elements.FCount-1 do with Elements.FItems[i]do begin
      if i>0 then AddChar(',');
      case typ of
        stSingle:AddStr(het.Utils.ToStr(e1));
        stRange:AddStr(het.Utils.ToStr(e1)+'..'+het.Utils.ToStr(e2));
      end;
    end;
    AddChar(']');
  end;
end;

function TSetArray.IsWild(const s:AnsiString):boolean;
var i:integer;
begin with Elements do begin
  if FCount=0 then exit(false);
  for i:=0 to FCount-1 do with FItems[i] do begin
    if typ=stRange then begin
      if(s>=e1)and(s<=e2)then exit(true);
    end else begin
      if het.Utils.IsWild2(ansistring(e1),s)then exit(true);
    end;
  end;
  result:=false;
end;end;

function TSetArray.Max: variant;
var i:integer;
begin with Elements do begin       //untested
  if Count=0 then exit(Null);
  result:=FItems[0].Max;
  for i:=1 to Count-1 do with FItems[i]do if Max>result then result:=Max;
end;end;

function TSetArray.Min: variant;
var i:integer;
begin with Elements do begin       //untested
  if Count=0 then exit(Null);
  result:=FItems[0].Min;
  for i:=1 to Count-1 do with FItems[i]do if Min<result then result:=Min;
end;end;

type
  TSetVarData=packed record
    VType: TVarType;
    Reserved1, Reserved2, Reserved3: Word;
    VSetArray:TSetArray;
    Dummy:integer;
  end;

  TSetVariantType=class(TCustomVariantType)
  private
  public
    function IsClear(const V: TVarData): Boolean;override;
    procedure Clear(var V: TVarData); override;
    procedure Copy(var Dest: TVarData; const Source: TVarData; const Indirect: Boolean); override;
    procedure CastTo(var Dest: TVarData; const Source: TVarData; const AVarType: TVarType); override;
    procedure BinaryOp(var Left: TVarData;const Right: TVarData;const Operator: TVarOp); override;
    function CompareOp(const Left, Right: TVarData; const Operator: TVarOp): Boolean;override;
    procedure Compare(const Left, Right: TVarData; var Relationship: TVarCompareResult); override;
  end;

function VSet:Variant;overload;
begin
  VarClear(result);
  with TSetVarData(result)do begin
    VType:=VarSet;
    VSetArray:=TSetArray.Create;
  end;
end;

function VSet(const ASetArray:TSetArray):Variant;overload;
begin
  VarClear(result);
  with TSetVarData(result)do begin
    VType:=VarSet;
    VSetArray:=TSetArray.Create;
    VSetArray.Assign(ASetArray);
  end;
end;

function VSet(const AElement:Variant):Variant;overload;
begin
  VarClear(result);
  with TSetVarData(result)do begin
    VType:=VarSet;
    VSetArray:=TSetArray.Create;
    VSetArray.AddSingle(AElement);
  end;
end;

function VSetOrdinal(const AOrdinal:integer):Variant;overload;
var i:integer;
begin
  VarClear(result);
  with TSetVarData(result)do begin
    VType:=VarSet;
    VSetArray:=TSetArray.Create;
    with VSetArray do
      for i:=0 to 31 do
        if(AOrdinal and(1 shl i))<>0 then
          AddSingle(i);
  end;
end;

function VSetOrdinal(const AOrdinal:integer;ATypeInfo:PTypeInfo):Variant;overload;
var i:integer;
begin
  if ATypeInfo.Kind=tkSet then
    ATypeInfo:=GetTypeData(ATypeInfo).CompType^;
  if ATypeInfo.Kind<>tkEnumeration then
    raise EVariantTypeCastError.Create('VSetOrdinal() tkSet or tkEnumeration type needed');

  VarClear(result);
  with TSetVarData(result)do begin
    VType:=VarSet;
    VSetArray:=TSetArray.Create;
    with VSetArray do
      for i:=0 to 31 do
        if(AOrdinal and(1 shl i))<>0 then
          AddSingle(VEnum(i,ATypeInfo));
  end;
end;

function VSetRange(const mi,ma:variant):Variant;
begin
  VarClear(result);
  with TSetVarData(result)do begin
    VType:=VarSet;
    VSetArray:=TSetArray.Create;
    VSetArray.AddRange(mi,ma);
  end;
end;

function VarIsSet(const V:variant):boolean;
begin
  result:=TVarData(V).VType=varSet;
end;

function VarSetIsEmpty(const V:Variant):boolean;
begin with TSetVarData(V)do begin
  if not(VType=varSet)then EVariantInvalidOpError.Create('VarSetIsEmpty() SetVariant type needed');
  result:=(VSetArray=nil)or(VSetArray.Elements.FCount=0);
end;end;

function VarAsSetArray(const V:Variant):TSetArray;
begin with TSetVarData(V)do begin
  if VType<>varSet then EVariantInvalidOpError.Create('VSetAsSetArray() SetVariant type needed');
  result:=VSetArray;
end;end;

 { TODO : 
VarSet megcsinalni, hogy TypeInfoval is mukodjon
plusz ez a Get/SetPropValue-ben is! }
function VarSetType(const V:Variant):PTypeInfo;
begin
  if VarIsSet(V) then result:=PTypeInfo(TVarData(V).VLongs[2])
                 else result:=nil;
end;

function VarSetTypeName(const V:Variant):ansistring;
var ti:PTypeInfo;
begin
  ti:=VarSetType(V);
  if ti<>nil then result:=ti.Name
             else result:='nil';
end;


{ TSetVariantType }

procedure TSetVariantType.Clear(var V: TVarData);
begin
  FreeAndNil(TSetVarData(V).VSetArray);
  SimplisticClear(V);
end;

function TSetVariantType.IsClear(const V: TVarData): Boolean;
begin
  Result := (TSetVarData(V).VSetArray = nil);
end;

procedure TSetVariantType.Copy(var Dest: TVarData; const Source: TVarData; const Indirect: Boolean);
begin
  if Indirect and VarDataIsByRef(Source) then
    VarDataCopyNoInd(Dest, Source)
  else
    with TSetVarData(Dest) do
    begin
      VType:=VarType;
      VSetArray:=TSetArray.Create;
      VSetArray.Assign(TSetVarData(Source).VSetArray);
    end;
end;

procedure TSetVariantType.CastTo(var Dest: TVarData; const Source: TVarData; const AVarType: TVarType);
var VDest:Variant absolute Dest;
begin
  if(Source.VType=VarType)then begin
    if(AVarType=varString)or(AVarType=varUString)or(AVarType=varStrArg)then begin
      VDest:=TSetVarData(Source).VSetArray.ToStr;
    end else if(AVarType in[varInteger,varLongWord,varSmallint,varWord,varByte,varShortInt])then begin
      VDest:=TSetVarData(Source).VSetArray.ToInt;
    end;
  end else
    inherited;
end;

procedure TSetVariantType.BinaryOp(var Left: TVarData; const Right: TVarData; const Operator: TVarOp);
begin
  if(TVarData(left).VType=VarType)and(TVarData(right).vType=VarType) then case Operator of
    opAdd,opOr:TSetVarData(Left).VSetArray.AddSet(TSetVarData(Right).VSetArray);
    opSubtract:TSetVarData(Left).VSetArray.RemoveSet(TSetVarData(Right).VSetArray);
    opAnd,opMultiply:TSetVarData(Left).VSetArray.AndSet(TSetVarData(Right).VSetArray);
    opXor:TSetVarData(Left).VSetArray.XorSet(TSetVarData(Right).VSetArray);
  else inherited end else inherited;
end;

procedure TSetVariantType.Compare(const Left, Right: TVarData; var Relationship: TVarCompareResult);
var tmp:Variant;
begin
  if(TVarData(left).VType=VarType)and(TVarData(right).vType=VarType) then begin
{   //fast check but only for ordinals
    if cardinal(variant(left))=cardinal(variant(right))then Relationship:=crEqual
                                                       else Relationship:=crLessThan;}
    //more efficient but slower check
    tmp:=variant(Left) xor variant(Right);
    if VarSetIsEmpty(tmp) then Relationship:=crEqual
                          else Relationship:=crLessThan;
  end else inherited;
end;

function TSetVariantType.CompareOp(const Left, Right: TVarData; const Operator: TVarOp): Boolean;
var
  LRelationship: TVarCompareResult;
begin
  Compare(Left, Right, LRelationship);
  if Operator=opCmpEQ then result:=LRelationship=crEqual else
  if Operator=opCmpNE then result:=LRelationship<>crEqual else begin
    VarInvalidOp;result:=false{antiwarning} end;
end;


{*******************************************************}
{                 Reference Variant Type                }
{*******************************************************}

const
  flTObject=1;

type
  TReferenceVariantType=class(TPublishableVariantType)
  private
  protected
    function GetInstance(const V: TVarData): TObject;override;
  public
    function IsClear(const V: TVarData): Boolean;override;
    procedure Clear(var V: TVarData); override;
    procedure Copy(var Dest: TVarData; const Source: TVarData; const Indirect: Boolean); override;
    procedure CastTo(var Dest: TVarData; const Source: TVarData; const AVarType: TVarType);override;
    function CompareOp(const Left, Right: TVarData; const Operator: TVarOp): Boolean; override;
    function LeftPromotion(const V: TVarData; const Operator: TVarOp; out RequiredVarType: TVarType): Boolean; override;
    function RightPromotion(const V: TVarData; const Operator: TVarOp; out RequiredVarType: TVarType): Boolean; override;
    procedure BinaryOp(var Left: TVarData; const Right: TVarData; const Operator: TVarOp);override;
  end;

function VarRefIsTObject(const V:variant):boolean;inline;
begin
  result:=(TVarData(V).VLongs[2]and flTObject)<>0;
end;

function VReference(const P:PVariant):Variant;
begin
  VarClear(result);
  with TVarData(result)do begin
    VType:=varReference;
    VPointer:=P;
//    VLongs[2]:=0;
  end;
end;

function VReference(var V:Variant):Variant;
begin
  VarClear(result);
  with TVarData(result)do begin
    VType:=varReference;
    VPointer:=@V;
//    VLongs[2]:=0;
  end;
end;

function VObject(const AObject:TObject):Variant;
begin
  VarClear(result);
  with TVarData(result)do begin
    VType:=varReference;
    VPointer:=pointer(AObject);
    VLongs[2]:=flTObject;
  end;
end;

function VarIsReference(const V:variant):boolean;
begin
  result:=(TVarData(V).VType=varReference)and((TVarData(V).VPointer=nil)or not VarRefIsTObject(V));
end;

function VarIsObject(const V:variant):boolean;overload;
begin
  result:=(TVarData(V).VType=varReference)and((TVarData(V).VPointer=nil)or VarRefIsTObject(V));
end;

function VarIsNil(const V:variant):boolean;
begin
  with TVarData(V)do result:=(VType<>varReference)or(VPointer=nil);
end;

function VarIsObject(const V:variant;AClass:TClass):boolean;overload;
var o:TObject;
begin
  result:=(TVarData(V).VType=varReference)and VarRefIsTObject(V);
  if result and(AClass<>nil)then begin
    o:=TVarData(V).VPointer;
    if o<>nil then result:=o is AClass
              else result:=true;//nis is anyclass
  end;
end;

function VarAsObject(const V:Variant):TObject;overload;
begin
  if not VarIsObject(V)then Raise EVariantInvalidArgError.Create('varObject type expected');
  result:=TVarData(V).VPointer;
end;

function VarAsObject(const V:Variant;AClass:TClass):TObject;overload;
begin
  if not VarIsObject(V)then Raise EVariantInvalidArgError.Create('varObject type expected');
  result:=TVarData(V).VPointer;
  if result=nil then exit;
  if AClass=nil then exit;
  if not(Result is AClass)then raise EVariantInvalidArgError.Create('varObject is not '+AClass.ClassName);
end;

function VarDereference(const V:Variant):PVariant;
begin
  if VarIsReference(V) then
    result:=TVarData(V).VPointer
  else
    result:=@V;
end;

procedure TReferenceVariantType.Clear(var V: TVarData);
begin
  SimplisticClear(V);
end;

function TReferenceVariantType.IsClear(const V: TVarData): Boolean;
begin
  result:=(V.VPointer=nil);
end;

procedure TReferenceVariantType.Copy(var Dest: TVarData; const Source: TVarData; const Indirect: Boolean);
begin
  if Indirect then raise EVariantInvalidOpError.Create('Cannot copy a ByRef Reference');
  SimplisticCopy(Dest,Source);
end;

function TReferenceVariantType.CompareOp(const Left, Right: TVarData; const Operator: TVarOp): Boolean;
var L,R:PVariant;
begin
  if(Left.VType=VarType)and(Right.VType=VarType)then
    case Operator of
      opCmpEQ:result:=Left.VPointer=Right.VPointer;
      opCmpNE:result:=Left.VPointer<>Right.VPointer;
      else RaiseInvalidOp;result:=false;
    end
  else begin
    L:=VarDereference(variant(Left));
    R:=VarDereference(variant(Right));
    case Operator of
      opCmpEQ:result:=L^=R^;
      opCmpNE:result:=L^<>R^;
      opCmpGT:result:=L^>R^;
      opCmpLT:result:=L^<R^;
      opCmpGE:result:=L^>=R^;
      opCmpLE:result:=L^<=R^;
      else result:=false//no warning
    end;
  end
end;

procedure TReferenceVariantType.CastTo(var Dest: TVarData; const Source: TVarData; const AVarType: TVarType);
var VDest:variant absolute Dest;
    s:string;
begin
  if VarIsObject(variant(Source))then begin
    if(AVarType=varString)or(AVarType=varStrArg)or(AVarType=varUString)then begin
      if Source.VPointer=nil then s:='nil'
                             else s:=TObject(Source.VPointer).ToString;
      if AVarType=varUString then VDest:=s
                             else VDest:=ansistring(s);
    end else
      raise EVariantTypeCastError.Create('Invalid typecast: varReference -> '+VarTypeAsText(AVarType));
  end else if VarIsReference(variant(Source))then begin
    if Source.VPointer=nil then raise EVariantTypeCastError.Create('ReferenceVariantType: Cannot dereference nil');
    if Source.VPointer=@Source then raise EVariantTypeCastError.Create('ReferenceVariantType: Cannot dereference self');
    VarCast(VDest,pvariant(Source.VPointer)^,AVarType);
  end else
    raise EVariantTypeCastError.Create('Invalid typecast: varReference -> '+VarTypeAsText(AVarType));
end;

function TReferenceVariantType.LeftPromotion(const V: TVarData; const Operator: TVarOp; out RequiredVarType: TVarType): Boolean;
begin
  if VarIsReference(variant(V))then begin
    RequiredVarType:=V.VType;
    result:=true;
  end else
    result:=false;
end;

function TReferenceVariantType.RightPromotion(const V: TVarData; const Operator: TVarOp; out RequiredVarType: TVarType): Boolean;
begin
  RequiredVarType:=V.VType;
  result:=true;
end;

procedure TReferenceVariantType.BinaryOp(var Left: TVarData; const Right: TVarData; const Operator: TVarOp);
var L,R:PVariant;
begin
  L:=VarDereference(variant(Left));
  R:=VarDereference(variant(Right));
  case Operator of
    opAdd:variant(Left):=L^+R^;
    opSubtract:variant(Left):=L^-R^;
    opMultiply:variant(Left):=L^*R^;
    opDivide:variant(Left):=L^/R^;
    opIntDivide:variant(Left):=L^ div R^;
    opModulus:variant(Left):=L^ mod R^;
    opShiftLeft:variant(Left):=L^ shl R^;
    opShiftRight:variant(Left):=L^ shr R^;
    opAnd:variant(Left):=L^ and R^;
    opOr:variant(Left):=L^ or R^;
    opXor:variant(Left):=L^ xor R^;
  else
    raise EVariantInvalidOpError.Create('TReferenceVariantType: Invalid operation');
  end;
end;

function TReferenceVariantType.GetInstance(const V: TVarData): TObject;
begin
  if VarRefIsTObject(variant(V))then result:=TObject(V.VPointer)
                                else result:=nil;
end;

{*******************************************************}
{            Reference Variant Class Support            }
{*******************************************************}

constructor TClassReference.Create(const AClass:TClass);
begin
  FClass:=AClass;
end;

function TClassReference.ToString: string;
begin
  result:='class '+FClass.ClassName;
end;


var
  ClassArray:THetArray<TClassReference>;

function GetClassReference(const AClass:TClass):TClassReference;
var idx:Integer;
begin
  if not ClassArray.FindBinary(
    function (const a:TClassReference):integer
    begin
      result:=integer(AClass)-integer(a.FClass);
    end,idx)
  then
    ClassArray.Insert(TClassReference.Create(AClass),idx);
  result:=ClassArray.FItems[idx];
end;

procedure freeClassReferences;
var i:integer;
begin
  for i:=ClassArray.FCount-1 downto 0 do ClassArray.FItems[i].Free;
end;

function VClass(const AClass:TClass):variant;
begin
  result:=VObject(GetClassReference(AClass));
end;

function VarIsClass(const V:Variant):boolean;
begin
  result:=VarIsObject(V,TClassReference);
end;

function VarAsClass(const V:Variant;const ABaseClass:TClass):TClass;
var o:TClassReference;
begin
  o:=TClassReference(VarAsObject(V,TClassReference));
  if o=nil then result:=nil
  else begin
    result:=o.FClass;
    if ABaseClass<>nil then
      if not Result.InheritsFrom(ABaseClass) then
        raise EVariantInvalidOpError('VarAsClass() "'+ABaseClass.ClassName+'" type required');
  end;
end;


{*******************************************************}
{                   Named Variant Type                  }
{*******************************************************}

type
  TNamedVariantType=class(TCustomVariantType)
  public
    function IsClear(const V: TVarData): Boolean;override;
    procedure Clear(var V: TVarData); override;
    procedure Copy(var Dest: TVarData; const Source: TVarData; const Indirect: Boolean); override;
    procedure CastTo(var Dest: TVarData; const Source: TVarData; const AVarType: TVarType);override;
    function CompareOp(const Left, Right: TVarData; const Operator: TVarOp): Boolean; override;
    function LeftPromotion(const V: TVarData; const Operator: TVarOp; out RequiredVarType: TVarType): Boolean; override;
    function RightPromotion(const V: TVarData; const Operator: TVarOp; out RequiredVarType: TVarType): Boolean; override;
    procedure BinaryOp(var Left: TVarData; const Right: TVarData; const Operator: TVarOp);override;
  end;

procedure VNamedAlloc(const Src:Variant;var Dst:Variant);
begin
  with TVarData(Dst)do begin
    VPointer:=getmemory(16);
    FillChar(VPointer^,16,0);
    PVariant(VPointer)^:=src;
  end;
end;

procedure VNamedFree(const V:variant);
begin
  with TVarData(V)do begin
    VarClear(PVariant(VPointer)^);
    FreeMem(VPointer);
  end;
end;

function VNamedAccess(const V:Variant):PVariant;
begin
  if TVarData(V).VType=varNamed then result:=PVariant(TVarData(V).VPointer)
                                else result:=@V;
end;

function VNamed(const AName:ansistring;const V:variant):Variant;
begin
  VarClear(Result);
  with TVarData(Result)do begin
    VType:=varNamed;
    ansistring(VLongs[2]):=AName;
    VNamedAlloc(V,result);
  end;
end;

function VarIsNamed(const V:variant):boolean;inline;
begin
  result:=(TVarData(V).VType=varNamed);
end;

function VarNamedGetName(const V:variant):ansistring;
begin
  with TVarData(V)do if VType=varNamed then
    result:=ansistring(VLongs[2])
  else
    result:='';
end;

procedure VarNamedSetName(const V:variant;const AName:ansistring);
begin
  with TVarData(V)do if VType=varNamed then
    pansistring(VLongs[2])^:=AName
  else
    raise EVariantInvalidArgError.Create('VarNamedSetName() varReference type needed');
end;

function VarNamedGetValue(const V:variant):variant;
begin
  if not VarIsNamed(V) then result:=V
                       else result:=PVariant(TVarData(V).VPointer)^;
end;

procedure VarNamedSetValue(const V:variant;const AValue:variant);
begin
  if not VarIsNamed(V) then Raise EVariantInvalidArgError.Create('VarNamedSetValue() varNamed type needed')
                       else PVariant(TVarData(V).VPointer)^:=AValue;
end;

function VarNamedRefValue(const V:variant):PVariant;
begin
  if not VarIsNamed(V) then Raise EVariantInvalidArgError.Create('VarNamedRefValue() varNamed type needed')
                       else result:=PVariant(TVarData(V).VPointer);
end;

procedure TNamedVariantType.Clear(var V: TVarData);
begin
  VNamedFree(variant(V));
  ansistring(V.VLongs[2]):='';
  SimplisticClear(V);
end;

function TNamedVariantType.IsClear(const V: TVarData): Boolean;
begin
  result:=(V.VPointer=nil)and(V.VLongs[2]=0);
end;

procedure TNamedVariantType.Copy(var Dest: TVarData; const Source: TVarData; const Indirect: Boolean);
begin
  if Indirect then raise EVariantInvalidOpError.Create('Cannot copy a ByRef Reference');
  SimplisticCopy(Dest,Source);
  VNamedAlloc(VNamedAccess(variant(Source))^,variant(Dest));
  {name}Dest.VLongs[2]:=0;ansistring(Dest.VLongs[2]):=ansistring(Source.VLongs[2]);
end;

function TNamedVariantType.CompareOp(const Left, Right: TVarData; const Operator: TVarOp): Boolean;
var L,R:PVariant;
begin
  L:=VNamedAccess(variant(Left));
  R:=VNamedAccess(variant(Right));
  case Operator of
    opCmpEQ:result:=L^=R^;
    opCmpNE:result:=L^<>R^;
    opCmpGT:result:=L^>R^;
    opCmpLT:result:=L^<R^;
    opCmpGE:result:=L^>=R^;
    opCmpLE:result:=L^<=R^;
    else result:=false;//no warn
  end;
end;

procedure TNamedVariantType.CastTo(var Dest: TVarData; const Source: TVarData; const AVarType: TVarType);
var VDest:variant absolute Dest;
begin
  if(AVarType=varStrArg)or(AVarType=varString)or(AVarType=varUString)then
    VDest:=ToStr(VNamedAccess(variant(Source))^)
  else
    VarCast(VDest,VNamedAccess(variant(Source))^,AVarType);
end;

function TNamedVariantType.LeftPromotion(const V: TVarData; const Operator: TVarOp; out RequiredVarType: TVarType): Boolean;
begin
  if VarIsNamed(variant(V))then begin
    RequiredVarType:=V.VType;
    result:=true;
  end else
    result:=false;
end;

function TNamedVariantType.RightPromotion(const V: TVarData; const Operator: TVarOp; out RequiredVarType: TVarType): Boolean;
begin
  RequiredVarType:=V.VType;
  result:=true;
end;

procedure TNamedVariantType.BinaryOp(var Left: TVarData; const Right: TVarData; const Operator: TVarOp);
var L,R:PVariant;
begin
  L:=VNamedAccess(variant(Left));
  R:=VNamedAccess(variant(Right));
  case Operator of
    opAdd:variant(Left):=L^+R^;
    opSubtract:variant(Left):=L^-R^;
    opMultiply:variant(Left):=L^*R^;
    opDivide:variant(Left):=L^/R^;
    opIntDivide:variant(Left):=L^ div R^;
    opModulus:variant(Left):=L^ mod R^;
    opShiftLeft:variant(Left):=L^ shl R^;
    opShiftRight:variant(Left):=L^ shr R^;
    opAnd:variant(Left):=L^ and R^;
    opOr:variant(Left):=L^ or R^;
    opXor:variant(Left):=L^ xor R^;
  else
    raise EVariantInvalidOpError.Create('TNamedVariantType: Invalid operation');
  end;
end;

{***************************************************************************}
{                                Points, rects                              }
{***************************************************************************}

function VPoint(const P:TPoint):Variant;
begin
  result:=VarArrayCreate([0,1],varVariant);
  result[0]:=VNamed('X',p.x);
  result[1]:=VNamed('Y',p.y);
end;

function VarAsPoint(const V:Variant):TPoint;
begin
  result.x:=VarArrayGetNamedValue(v,'X');
  result.y:=VarArrayGetNamedValue(v,'Y');
end;

function VRect(const R:TRect):Variant;
begin
  result:=VarArrayCreate([0,3],varVariant);
  result[0]:=VNamed('Left',r.left);
  result[1]:=VNamed('Top',r.top);
  result[2]:=VNamed('Right',r.right);
  result[3]:=VNamed('Bottom',r.bottom);
end;

function VarAsRect(const V:Variant):TRect;
begin
  result.Left:=VarArrayGetNamedValue(V,'Left');
  result.Top:=VarArrayGetNamedValue(V,'Top');
  result.Right:=VarArrayGetNamedValue(V,'Right');
  result.Bottom:=VarArrayGetNamedValue(V,'Bottom');
end;

{***************************************************************************}
{                                Patches                                    }
{***************************************************************************}

{$O+}
{$R-}
{$B-}

procedure PatchVariantStringCompare;
var a,b:Variant;p:pointer;
begin
  a:=a>b;
  asm  //hack out addr(_VarCmpGT)
    call @@1
  @@1: pop eax
    mov p,eax;
  end;
  //patching _VarCmpGT > VarCompare > VarCompareSimple > StringCompare > CompareStr
  PatchRelativeAddress(PatchFindCallAddressChain(p,[-21,5,22,366,50]),@StringCmpUpperSort,@sysutils.CompareStr);
end;

//                  Var To AnsiString                    //

procedure VarArrayToLStr(var S:ansistring; const V:variant);
var i,j:integer;
    temp:AnsiString;
begin
  with AnsiStringBuilder(temp) do begin
    AddChar('(');
    i:=VarArrayLowBound(V,1);
    j:=VarArrayHighBound(V,1);
    if i<=j then begin
      AddStr(ansistring(V[i]));
      for i:=i+1 to j do begin
        AddChar(',');
        AddStr(ansistring(V[i]));
      end;
    end;
    AddChar(')');
    Finalize;
  end;
  S:=temp;
end;

var _OldVarToLstr:pointer;

procedure OldVarToLStr(var S: AnsiString; const V: TVarData);
asm
  DQ 0
  jmp _OldVarToLstr
end;

procedure MyVarToLStr(var S: AnsiString; const V: TVarData);
begin                                                             //hetutils
  case V.VType of
    varEmpty:    S := '';
    varNull:
      begin
        if NullStrictConvert then
          VarCastError(varNull, varString);
        S := ansistring(NullAsStringValue);
      end;
    varSmallInt: S := ToStr(V.VSmallInt);
    varInteger:  S := ToStr(V.VInteger);
    varSingle:   S := ansistring(FloatToStr(V.VSingle));
    varDouble:   S := ansistring(FloatToStr(V.VDouble));
    varCurrency: OldVarToLstr(S,V);
    varDate:     OldVarToLstr(S,V);
    varOleStr:   S := ansistring(Copy(WideString(Pointer(V.VOleStr)), 1, MaxInt));
    varBoolean:  OldVarToLstr(S,V);
    varShortInt: S := ToStr(V.VShortInt);
    varByte:     S := ToStr(V.VByte);
    varWord:     S := ToStr(V.VWord);
    varLongWord: S := ToStr(V.VLongWord);
    varInt64:    S := ToStr(V.VInt64);
    varUInt64:   S := ToStr(V.VUInt64);

    varVariant:  MyVarToLStr(S, PVarData(V.VPointer)^);

    varDispatch,
    varUnknown:  OldVarToLstr(S,V);
  else
    case V.VType of
      varString:  S := AnsiString(V.VString);
      varUString: S := AnsiString(UnicodeString(V.VUString));
      varAny:     OldVarToLstr(S,V);
    else
      if V.VType and varByRef <> 0 then
        case V.VType and not varByRef of
          varSmallInt: S := ToStr(PSmallInt(V.VPointer)^);
          varInteger:  S := ToStr(PInteger(V.VPointer)^);
          varSingle:   S := ansistring(FloatToStr(PSingle(V.VPointer)^));
          varDouble:   S := ansistring(FloatToStr(PDouble(V.VPointer)^));
          varCurrency: OldVarToLstr(S,V);
          varDate:     OldVarToLstr(S,V);
          varOleStr:   S := ansistring(PWideChar(V.VPointer^));
          varBoolean:  OldVarToLstr(S,V);
          varShortInt: S := ToStr(PShortInt(V.VPointer)^);
          varByte:     S := ToStr(PByte(V.VPointer)^);
          varWord:     S := ToStr(PWord(V.VPointer)^);
          varLongWord: S := ToStr(PLongWord(V.VPointer)^);
          varInt64:    S := ToStr(PInt64(V.VPointer)^);
          varUInt64:   S := ansistring(UIntToStr(PUInt64(V.VPointer)^));

          varVariant:  MyVarToLStr(S, PVarData(V.VPointer)^);
        else if(V.VType and varArray)<>0 then
          VarArrayToLStr(S,PVariant(V.VPointer)^)
        else
          OldVarToLStr(S,V)
        end
      else if(V.VType and varArray)<>0 then
        VarArrayToLStr(S,variant(V))
      else
        OldVarToLStr(S,V)
    end;
  end;
end;

procedure PatchVarToLStr;
var a,b:Variant;p:pointer;
begin
  a:='';
  b:=ansistring(a);
  asm
    call @@1
  @@1: pop eax
    mov p,eax;
  end;
  p:=PatchGetCallAbsoluteAddress(pointer(integer(p)-21));
  PatchRaw(@OldVarToLStr,p,8);
  PatchFunction(p,@MyVarToLStr);
  _OldVarToLstr:=psucc(p,8);
end;

//                  Var To UnicodeString                    //

procedure VarArrayToUStr(var S:unicodestring; const V:variant);
var i,j:integer;
    temp:UnicodeString;
begin
  with UnicodeStringBuilder(temp)do begin
    AddChar('(');
    i:=VarArrayLowBound(V,1);
    j:=VarArrayHighBound(V,1);
    if i<=j then begin
      AddStr(V[i]);
      for i:=i+1 to j do begin
        AddChar(',');
        AddStr(V[i]);
      end;
    end;
    AddChar(')');
    finalize;
  end;
  S:=temp;
end;

var _OldVarToUStr:pointer=nil;

procedure OldVarToUStr(var S: UnicodeString; const V: TVarData);
asm
  DQ 0
  jmp _OldVarToUstr
end;

procedure MyVarToUStr(var S: UnicodeString; const V: TVarData);
begin
  case V.VType of
    varEmpty:    S := '';
    varNull:
      begin
        if NullStrictConvert then
          VarCastError(varNull, varOleStr);
        S := NullAsStringValue;
      end;
    varSmallInt: S := IntToStr(V.VSmallInt);
    varInteger:  S := IntToStr(V.VInteger);
    varSingle:   S := FloatToStr(V.VSingle);
    varDouble:   S := FloatToStr(V.VDouble);
    varCurrency: OldVarToUStr(S,V);
    varDate:     OldVarToUStr(S,V);
    varOleStr:   S := Copy(WideString(Pointer(V.VOleStr)), 1, MaxInt);
    varBoolean:  OldVarToUStr(S,V);
    varShortInt: S := IntToStr(V.VShortInt);
    varByte:     S := IntToStr(V.VByte);
    varWord:     S := IntToStr(V.VWord);
    varLongWord: S := IntToStr(V.VLongWord);
    varInt64:    S := IntToStr(V.VInt64);
    varUInt64:   S := UIntToStr(V.VUInt64);

    varVariant:  MyVarToUStr(S, PVarData(V.VPointer)^);

    varDispatch,
    varUnknown:  OldVarToUStr(S,V);
  else
    case V.VType of
      varString:  S := UnicodeString(AnsiString(V.VString));
      varUString: S := UnicodeString(V.VUString);
      varAny:     OldVarToUStr(S,V);
    else
      if V.VType and varByRef <> 0 then
        case V.VType and not varByRef of
          varSmallInt: S := IntToStr(PSmallInt(V.VPointer)^);
          varInteger:  S := IntToStr(PInteger(V.VPointer)^);
          varSingle:   S := FloatToStr(PSingle(V.VPointer)^);
          varDouble:   S := FloatToStr(PDouble(V.VPointer)^);
          varCurrency: OldVarToUStr(S,V);
          varDate:     OldVarToUStr(S,V);
          varOleStr:   S := PWideChar(V.VPointer^);
          varBoolean:  OldVarToUStr(S,V);
          varShortInt: S := IntToStr(PShortInt(V.VPointer)^);
          varByte:     S := IntToStr(PByte(V.VPointer)^);
          varWord:     S := IntToStr(PWord(V.VPointer)^);
          varLongWord: S := IntToStr(PLongWord(V.VPointer)^);
          varInt64:    S := IntToStr(PInt64(V.VPointer)^);
          varUInt64:   S := UIntToStr(PUInt64(V.VPointer)^);

          varVariant:  MyVarToUStr(S, PVarData(V.VPointer)^);
        else if(V.VType and varArray)<>0 then
          VarArrayToUStr(S,PVariant(V.VPointer)^)
        else
          OldVarToUStr(S,V)
        end
      else if(V.VType and varArray)<>0 then
        VarArrayToUStr(S,variant(V))
      else
        OldVarToUStr(S,V);
    end;
  end;
end;

procedure PatchVarToUStr;
var a,b:Variant;p:pointer;
begin
  a:='';
  b:=unicodestring(a);
  asm
    call @@1
  @@1: pop eax
    mov p,eax;
  end;
  p:=PatchGetCallAbsoluteAddress(pointer(integer(p)-21));
  PatchRaw(@OldVarToUStr,p,8);
  PatchFunction(p,@MyVarToUStr);
  _OldVarToUStr:=pSucc(p,8);
end;

//                  VarTo WideString                    //

procedure VarArrayToWStr(var S:WideString; const V:variant);
var US:UnicodeString;
begin
  VarArrayToUStr(US,V);
  S:=US;
end;

var _OldVarToWStr:pointer=nil;

procedure OldVarToWStr(var S: WideString; const V: TVarData);
asm
  DQ 0
  jmp _OldVarToWstr
end;

procedure MyVarToWStr(var S: WideString; const V: TVarData);
begin
  case V.VType of
    varEmpty:    S := '';
    varNull:
      begin
        if NullStrictConvert then
          VarCastError(varNull, varOleStr);
        S := NullAsStringValue;
      end;
    varSmallInt: S := IntToStr(V.VSmallInt);
    varInteger:  S := IntToStr(V.VInteger);
    varSingle:   S := FloatToStr(V.VSingle);
    varDouble:   S := FloatToStr(V.VDouble);
    varCurrency: OldVarToWStr(S,V);
    varDate:     OldVarToWStr(S,V);
    varOleStr:   S := Copy(WideString(Pointer(V.VOleStr)), 1, MaxInt);
    varBoolean:  OldVarToWStr(S,V);
    varShortInt: S := IntToStr(V.VShortInt);
    varByte:     S := IntToStr(V.VByte);
    varWord:     S := IntToStr(V.VWord);
    varLongWord: S := IntToStr(V.VLongWord);
    varInt64:    S := IntToStr(V.VInt64);
    varUInt64:   S := UIntToStr(V.VUInt64);

    varVariant:  MyVarToWStr(S,PVarData(V.VPointer)^);

    varDispatch,
    varUnknown:  OldVarToWStr(S,V);
  else
    case V.VType of
      varString:  S := UnicodeString(AnsiString(V.VString));
      varUString: S := UnicodeString(V.VUString);
      varAny:     OldVarToWStr(S,V);
    else
      if V.VType and varByRef <> 0 then
        case V.VType and not varByRef of
          varSmallInt: S := IntToStr(PSmallInt(V.VPointer)^);
          varInteger:  S := IntToStr(PInteger(V.VPointer)^);
          varSingle:   S := FloatToStr(PSingle(V.VPointer)^);
          varDouble:   S := FloatToStr(PDouble(V.VPointer)^);
          varCurrency: OldVarToWStr(S,V);
          varDate:     OldVarToWStr(S,V);
          varOleStr:   S := PWideChar(V.VPointer^);
          varBoolean:  OldVarToWStr(S,V);
          varShortInt: S := IntToStr(PShortInt(V.VPointer)^);
          varByte:     S := IntToStr(PByte(V.VPointer)^);
          varWord:     S := IntToStr(PWord(V.VPointer)^);
          varLongWord: S := IntToStr(PLongWord(V.VPointer)^);
          varInt64:    S := IntToStr(PInt64(V.VPointer)^);
          varUInt64:   S := UIntToStr(PUInt64(V.VPointer)^);

          varVariant:  MyVarToWStr(S,PVarData(V.VPointer)^);
        else if(V.VType and varArray)<>0 then
          VarArrayToWStr(S,PVariant(V.VPointer)^)
        else
          OldVarToWStr(S,V)
        end
      else if(V.VType and varArray)<>0 then
        VarArrayToWStr(S,variant(V))
      else
        OldVarToWStr(S,V);
    end;
  end;
end;

procedure PatchVarToWStr;
var a,b:Variant;p:pointer;
begin
  a:='';
  b:=widestring(a);
  asm
    call @@1
  @@1: pop eax
    mov p,eax;
  end;
  p:=PatchGetCallAbsoluteAddress(pointer(integer(p)-21));
  PatchRaw(@OldVarToWStr,p,8);
  PatchFunction(p,@MyVarToWStr);
  _OldVarToWStr:=pSucc(p,8);
end;

//                  GetPropValue                    //

function MyGetPropValue(Instance: TObject; PropInfo: PPropInfo; PreferStrings: Boolean): Variant;overload;
var
  DynArray: Pointer;
begin
  // assume failure
  Result := Null;

  // return the right type
  case PropInfo^.PropType^^.Kind of
    tkInteger:Result := GetOrdProp(Instance, PropInfo);
    tkChar:Result := ansichar(GetOrdProp(Instance, PropInfo));
    tkWChar:Result := widechar(GetOrdProp(Instance, PropInfo));
    tkClass:Result := VObject(TObject(GetOrdProp(Instance, PropInfo)));
    tkEnumeration:
      if PreferStrings then
        Result := GetEnumProp(Instance, PropInfo)
      else if GetTypeData(PropInfo^.PropType^)^.BaseType^ = TypeInfo(Boolean) then
        Result := Boolean(GetOrdProp(Instance, PropInfo))
      else
        Result := VEnum(GetOrdProp(Instance, PropInfo),GetTypeData(PropInfo^.PropType^)^.BaseType^);
    tkSet:
      if PreferStrings then
        Result := GetSetProp(Instance, PropInfo)
      else
        Result := VSetOrdinal(GetOrdProp(Instance, PropInfo),GetTypeData(PropInfo^.PropType^)^.CompType^);
    tkFloat:
      Result := GetFloatProp(Instance, PropInfo);
    tkMethod:
      Result := GetTypeName(PropInfo^.PropType^);
    tkString:
      Result := GetAnsiStrProp(Instance, PropInfo);
    tkLString:
      Result := GetAnsiStrProp(Instance, PropInfo);
    tkWString:
      Result := GetWideStrProp(Instance, PropInfo);
    tkUString:
      Result := GetUnicodeStrProp(Instance, PropInfo);
    tkVariant:
      Result := GetVariantProp(Instance, PropInfo);
    tkInt64:
      Result := GetInt64Prop(Instance, PropInfo);
    tkDynArray:
      begin
        DynArray := GetDynArrayProp(Instance, PropInfo);
        DynArrayToVariant(Result, DynArray, PropInfo^.PropType^);
      end;
  else
    raise EPropertyConvertError.Create('Invalid Property Type '+GetTypeName(PropInfo.PropType^));
  end;
end;

procedure PatchGetPropValue;
label l1;
var p:pointer;
begin
  goto l1;
  GetPropValue(nil,nil);
  l1:
  asm  //hack out addr
    call @@1
  @@1: pop eax
    mov p,eax;
  end;
  p:=PatchGetCallAbsoluteAddress(pointer(integer(p)-10));
  PatchFunction(p,@MyGetPropValue);
end;

//                  SetPropValue                    //

procedure MySetPropValue(Instance: TObject; PropInfo: PPropInfo; const Value: Variant);

  function RangedValue(const AMin, AMax: Int64): Int64;
  begin
    Result := Trunc(Value);
    if (Result < AMin) or (Result > AMax) then
      raise ERangeError.Create('Property range check error');
  end;

  function RangedCharValue(const AMin, AMax: Int64): Int64;
  var
    ans: string;
    s: string;
    ws: string;
  begin
    case VarType(Value) of
      varString:
        begin
          ans := Value;
          if Length(ans) = 1 then
            Result := Ord(ans[1])
          else
            Result := AMin-1;
       end;

      varUString:
        begin
          s := Value;
          if Length(s) = 1 then
            Result := Ord(s[1])
          else
            Result := AMin-1;
       end;

      varOleStr:
        begin
          ws := Value;
          if Length(ws) = 1 then
            Result := Ord(ws[1])
          else
            Result := AMin-1;
        end;
    else
      Result := Trunc(Value);
    end;

    if (Result < AMin) or (Result > AMax) then
      raise ERangeError.Create('Property range check error');
  end;

var
  TypeData: PTypeData;
  DynArray: Pointer;
begin
  TypeData := GetTypeData(PropInfo^.PropType^);

  // set the right type
  case PropInfo.PropType^^.Kind of
    tkChar, tkWChar:
      SetOrdProp(Instance, PropInfo, RangedCharValue(TypeData^.MinValue,
        TypeData^.MaxValue));
    tkInteger:
      if TypeData^.MinValue < TypeData^.MaxValue then begin
        try
          SetOrdProp(Instance, PropInfo, RangedValue(TypeData^.MinValue,
            TypeData^.MaxValue))
        except end;//ihomeui baszás miatt
      end else
        // Unsigned type
        SetOrdProp(Instance, PropInfo,
          RangedValue(LongWord(TypeData^.MinValue),
          LongWord(TypeData^.MaxValue)));
    tkEnumeration:
      if (VarType(Value) = varString) or (VarType(Value) = varOleStr) or (VarType(Value) = varUString) then
        SetEnumProp(Instance, PropInfo, VarToStr(Value))
      else if VarType(Value) = varBoolean then
        // Need to map variant boolean values -1,0 to 1,0
        SetOrdProp(Instance, PropInfo, Abs(Trunc(Value)))
      else if VarIsEnum(Value) then begin
        if VarEnumType(Value)<>GetTypeData(PropInfo^.PropType^)^.BaseType^ then
          raise EConvertError.Create('Invalid enum type in SetPropValue: got '+VarEnumTypeName(Value)+' instead of '+GetTypeData(PropInfo^.PropType^)^.BaseType^.Name);
        SetOrdProp(Instance, PropInfo, RangedValue(TypeData^.MinValue,
          TypeData^.MaxValue));
      end else    
        SetOrdProp(Instance, PropInfo, RangedValue(TypeData^.MinValue,
          TypeData^.MaxValue));
    tkSet:
      if VarType(Value) = varInteger then
        SetOrdProp(Instance, PropInfo, Value)
      else if VarIsSet(Value) then begin
{        if VarSetType(Value)<>GetTypeData(PropInfo^.PropType^)^.CompType^ then
          raise EConvertError.Create('Invalid set type in SetPropValue: got '+VarEnumTypeName(Value)+' instead of '+GetTypeData(PropInfo^.PropType^)^.CompType^.Name);}
        SetOrdProp(Instance, PropInfo, Value)
      end else
        SetSetProp(Instance, PropInfo, unicodestring(Value));
    tkFloat:begin
      if VarIsNull(value) then SetFloatProp(Instance, PropInfo, 0)//TDateTime null
                          else SetFloatProp(Instance, PropInfo, Value);
    end;
    tkString, tkLString:
      SetAnsiStrProp(Instance, PropInfo, ansistring(Value));
    tkWString:
      SetWideStrProp(Instance, PropInfo, widestring(Value));
    tkUString:
      SetUnicodeStrProp(Instance, PropInfo, unicodestring(Value)); //SB: ??
    tkVariant:
      SetVariantProp(Instance, PropInfo, Value);
    tkInt64:
      SetInt64Prop(Instance, PropInfo, RangedValue(TypeData^.MinInt64Value,
        TypeData^.MaxInt64Value));
    tkDynArray:
      begin
        DynArray := nil; // "nil array"
        DynArrayFromVariant(DynArray, Value, PropInfo^.PropType^);
        SetDynArrayProp(Instance, PropInfo, DynArray);
      end;
    tkClass:
      SetOrdProp(Instance,PropInfo,integer(VarAsObject(Value)));
  else
    raise EPropertyConvertError.Create('Invalid property type at SetPropValue: '+GetTypeName(PropInfo.PropType^));
  end;
end;

procedure PatchSetPropValue;
label l1;
var p:pointer;
begin
  goto l1;
  SetPropValue(nil,nil,Null);
  l1:
  asm  //hack out addr
    call @@1
  @@1: pop eax
    mov p,eax;
  end;
  p:=PatchGetCallAbsoluteAddress(pointer(integer(p)-10));
  PatchFunction(p,@MySetPropValue);
end;

var
  SetVariantType:TSetVariantType=nil;
  ReferenceVariantType:TReferenceVariantType=nil;
  EnumVariantType:TEnumVariantType=nil;
  NamedVariantType:TNamedVariantType=nil;

function TSetElement.Max: variant;
begin
  if typ=stSingle then result:=e2
                  else result:=e1;
end;

function TSetElement.Min: variant;
begin
  result:=e1;
end;

initialization
{!!!!!!!!!!!! A BDS.EXE-nel NEM MUKODIK, ott tilos!!!!!!!!!!!!!!}


  if not SameText(extractfilename(ParamStr(0)),'bds.exe') then begin
//    PatchVariantStringCompare;  XE3-nal NEM MUKODIK
    PatchVarToLStr;
    PatchVarToUStr;
    PatchVarToWStr;

    PatchGetPropValue;
    PatchSetPropValue;
  end;

  ClassArray.FCount:=0;

  SetVariantType:=TSetVariantType.Create;
  pword(@varSet)^:=SetVariantType.VarType;

  ReferenceVariantType:=TReferenceVariantType.Create;
  pword(@varReference)^:=ReferenceVariantType.VarType;

  EnumVariantType:=TEnumVariantType.Create;
  pword(@varEnum)^:=EnumVariantType.VarType;

  NamedVariantType:=TNamedVariantType.Create;
  pword(@varNamed)^:=NamedVariantType.VarType;

finalization
  FreeAndNil(NamedVariantType);
  FreeAndNil(EnumVariantType);
  FreeAndNil(ReferenceVariantType);
  FreeAndNil(SetVariantType);
  freeClassReferences;
end.
