unit het.BigNum;

interface

uses SysUtils, het.Utils, math;

type
  BigDecException=class(Exception);
  TBigDec=record
    isNeg:boolean;
    digits:TArray<byte>;//LSB fist
    exponent:integer;
    procedure Clear;
    procedure Simplify;
    function getDigit(n:integer):integer;
    procedure FromStr(const s:ansistring);
    function ToStr:ansistring;
    function Truncated:int64;

    function GetAsFloat:extended;
    procedure SetAsFloat(const a:extended);
    property AsFloat:extended read GetAsFloat write SetAsFloat;

    function isZero:boolean;
    class operator Negative(const a:TBigDec):TBigDec;
    class operator Add(const a,b:TBigDec):TBigDec;
    class operator Subtract(const a,b:TBigDec):TBigDec;
    class operator Multiply(const a,b:TBigDec):TBigDec;
    class operator implicit(const a:integer):TBigDec;
    class operator implicit(const a:int64):TBigDec;
    class operator implicit(const a:extended):TBigDec;
    class operator explicit(const a:ansistring):TBigDec;
    class operator explicit(const a:string):TBigDec;
  end;

  TBigFrac=record  //32bit whole part + variable length fractional part
    limbs:TArray<cardinal>;//LSB first
    function getLimb(n:integer):cardinal;
    procedure Simplify;
    procedure SetLimbCount(n:integer);
    procedure FromBigDec(const a:TBigDec;const ALimbCnt:integer=0);
    function ToBigDec:TBigDec;
    function ToStr:ansistring;
    procedure FromStr(const a:ansistring);

    function GetAsFloat:extended;
    procedure SetAsFloat(const a:extended);
    property AsFloat:extended read GetAsFloat write SetAsFloat;

    function Truncated:integer;
    function isNeg:boolean;
    function isZero:boolean;
    class operator Negative(const a:TBigFrac):TBigFrac;
    class operator Add(const a,b:TBigFrac):TBigFrac;
    class operator Subtract(const a,b:TBigFrac):TBigFrac;
    class operator Multiply(const a,b:TBigFrac):TBigFrac;
    class operator implicit(const a:integer):TBigFrac;
    class operator implicit(const a:extended):TBigFrac;
    class operator explicit(const a:ansistring):TBigFrac;
    class operator explicit(const a:string):TBigFrac;
    class operator explicit(const a:TBigFrac):extended;

    class operator Equal(const a:TBigFrac;const b:extended):boolean;
    class operator NotEqual(const a:TBigFrac;const b:extended):boolean;
    class operator LessThan(const a:TBigFrac;const b:extended):boolean;
    class operator GreaterThan(const a:TBigFrac;const b:extended):boolean;
    class operator LessThanOrEqual(const a:TBigFrac;const b:extended):boolean;
    class operator GreaterThanOrEqual(const a:TBigFrac;const b:extended):boolean;

    class operator Equal(const a,b:TBigFrac):boolean;
    class operator NotEqual(const a,b:TBigFrac):boolean;
    class operator LessThan(const a,b:TBigFrac):boolean;
    class operator GreaterThan(const a,b:TBigFrac):boolean;
    class operator LessThanOrEqual(const a,b:TBigFrac):boolean;
    class operator GreaterThanOrEqual(const a,b:TBigFrac):boolean;
  end;

function Cmp(const a,b:TBigFrac):integer;overload;

implementation

////////////////////////////////////////////////////////////////////////////////
///  TBigDec                                                                 ///
////////////////////////////////////////////////////////////////////////////////

procedure TBigDec.Simplify;
var i:integer;
begin
  while(digits<>nil)and(digits[high(digits)]=0)do setlength(digits,high(digits));
  while(digits<>nil)and(digits[0]=0)do begin
    for i:=0 to high(digits)-1do digits[i]:=digits[i+1];
    setlength(digits,high(digits));
    inc(exponent);
  end;
end;

procedure TBigDec.Clear;
begin
  isNeg:=false;
  digits:=nil;
  exponent:=0;
end;

procedure TBigDec.FromStr(const s:ansistring);
var e2,n,i:integer;
    ch:pansichar;
    negE2:boolean;
begin
  if s='' then begin clear;exit end;{raise BigDecException.Create('FromStr() empty string');}
  ch:=pointer(s);

  if ch[0]in['+','-']then begin isNeg:=ch[0]='-';inc(ch);end;
  exponent:=0;

  SetLength(digits,length(s));n:=0;

  while ch[0]in['0'..'9']do begin digits[postinc(n)]:=ord(ch[0])-ord('0');inc(ch)end;
  if ch[0]='.' then begin
    inc(ch);
    while ch[0]in['0'..'9']do begin digits[postinc(n)]:=ord(ch[0])-ord('0');inc(ch);dec(exponent)end;
  end;

  negE2:=false;//nowarn
  if ch[0]in['e','E']then begin
    e2:=0;
    inc(ch);
    if ch[0]in['+','-']then begin negE2:=ch[0]='-';inc(ch);end;
    while ch[0]in['0'..'9']do begin e2:=e2*10+ord(ch[0])-ord('0');inc(ch);end;
    if negE2 then e2:=-e2;
    Inc(exponent,e2);
  end;

  setlength(digits,n);
  for i:=0 to n div 2-1 do swap(digits[i],digits[high(digits)-i]);//LSD first

  Simplify;
end;

function TBigDec.getDigit(n:integer): integer;
begin
  if inrange(n,0,high(digits))then result:=digits[n]
                              else result:=0;
end;

function TBigDec.ToStr:ansistring;
var i:integer;
begin
  if digits=nil then exit('0');
  setlength(result,length(digits));
  for i:=0 to high(digits)do result[length(result)-i]:=ansichar(digits[i]+48);
  if isNeg then result:='-'+result;
  if exponent<>0 then result:=result+'E'+inttostr(exponent);
end;

class operator TBigDec.Negative(const a:TBigDec):TBigDec;
begin
  result:=a;
  result.isNeg:=not result.isNeg;
end;

class operator TBigDec.Add(const a,b:TBigDec):TBigDec;
var i,lowE,highE,c,sa,sb,sum:integer;
begin
  lowE:=min(a.exponent,b.exponent);
  highE:=max(a.exponent+high(a.digits),b.exponent+high(b.digits))+1{carry};

  result.exponent:=lowE;

  setlength(Result.digits,HighE-LowE+1);
  sa:=switch(a.isNeg,-1,1);
  sb:=switch(b.isNeg,-1,1);
  c:=0;
  for i:=lowE to highE do begin
    sum:=sa*integer(a.getDigit(i-a.exponent))+sb*integer(b.getDigit(i-b.exponent))+c;
    if sum>=10 then begin dec(sum,10);c:=1;end else
    if sum<0 then begin inc(sum,10);c:=-1;end else c:=0;
    Result.digits[i-lowE]:=sum;
  end;

  Result.Simplify;
end;

class operator TBigDec.Subtract(const a,b:TBigDec):TBigDec;
begin
  result:=a+-b;
end;

class operator TBigDec.Multiply(const a,b:TBigDec):TBigDec;
var i,j,c:integer;
    sum:TIA;
begin
  result.Clear;
  if(a.digits=nil)or(b.digits=nil)then begin result.Clear;exit end;

  setlength(sum,length(a.digits)+length(b.digits)+1);
  fillchar(sum[0],length(sum)shl 2,0);
  //sum up digit products
  for i:=0 to high(a.digits)do if a.digits[i]>0 then for j:=0 to high(b.digits)do
    inc(sum[i+j],a.digits[i]*b.digits[j]);
  //do carry/write result
  result.isNeg:=a.isNeg xor b.isNeg;
  result.exponent:=a.exponent+b.exponent;
  setlength(result.digits,length(sum));
  c:=0;
  for i:=0 to high(sum)do begin
    inc(sum[i],c);
    result.digits[i]:=sum[i]mod 10;
    c:=sum[i]div 10;
  end;
  if c<>0 then raise Exception.Create('TBigDec.Multiply() FATAL CARRY ERROR');
  result.Simplify;
end;

class operator TBigDec.implicit(const a:integer):TBigDec;
begin result.FromStr(inttostr(a))end;

class operator TBigDec.implicit(const a:int64):TBigDec;
begin result.FromStr(inttostr(a))end;

class operator TBigDec.implicit(const a:extended):TBigDec;
begin result.FromStr(floattostr(a))end;

class operator TBigDec.explicit(const a:ansistring):TBigDec;
begin Result.FromStr(a)end;

class operator TBigDec.explicit(const a:string):TBigDec;
begin result.FromStr(a);end;

function TBigDec.Truncated:int64;
var i:integer;
begin
  result:=0;
  for i:=high(digits)downto -exponent do
    result:=result*10+getDigit(i);
  if isNeg then
    result:=-result;
end;

function TBigDec.GetAsFloat:extended;
var i:integer;
begin
  result:=0;
  for i:=high(digits)downto 0 do
    result:=result*10+digits[i];
  result:=result*Power(10,exponent);
  if isNeg then
    result:=-result;
end;

procedure TBigDec.SetAsFloat(const a: Extended);
begin
  Self:=a;
end;

function TBigDec.isZero: boolean;
var d:byte;
begin
  for d in digits do if d<>0 then exit(false);
  result:=true;
end;

////////////////////////////////////////////////////////////////////////////////
///  TBigFrac                                                                ///
////////////////////////////////////////////////////////////////////////////////

function TBigFrac.isNeg:boolean;
begin
  if limbs=nil then result:=false
               else result:=limbs[high(limbs)]>=$80000000;
end;

function TBigFrac.isZero: boolean;
var d:cardinal;
begin
  for d in limbs do if d<>0 then exit(false);
  result:=true;
end;

function TBigFrac.getLimb(n:integer):cardinal;
begin
  if InRange(n,0,high(limbs))then result:=limbs[n]
                             else result:=0;
{                             else if isNeg then result:=$FFFFFFFF
                                           else result:=0;}
end;

function addc(const a,b:cardinal;var c:cardinal):cardinal;//ki/bemeno carry
asm
  push ebx
  xor ebx,ebx //carry
  add eax,edx    adc ebx,0
  add eax,[ecx]  adc ebx,0
  mov [ecx],ebx
  pop ebx
end;

class operator TBigFrac.Negative(const a:TBigFrac):TBigFrac;
var i:integer;
    c:cardinal;
begin with result do begin
  setlength(limbs,length(a.limbs));if limbs=nil then exit;

  c:=1;for i:=0 to high(limbs)do limbs[i]:=addc(not a.limbs[i],0,c);
end;end;

procedure TBigFrac.Simplify;
var z:cardinal;
begin
  if isNeg then z:=$FFFFFFFF else z:=0;
  while(length(limbs)>1)and(limbs[0]=z)do DelIntArray(TIntegerArray(limbs),0);
end;

procedure TBigFrac.SetLimbCount(n:integer);
var z:integer;
begin
{  if isNeg then z:=-1 else baszki LSB iranyaba NINCS sign extent}z:=0;
  while(length(limbs)<n)do InsIntArray(TIntegerArray(limbs),0,z);
  while(length(limbs)>n)do DelIntArray(TIntegerArray(limbs),0);
end;

class operator TBigFrac.Add(const a,b:TBigFrac):TBigFrac;
var i:integer;
    c:cardinal;
    a0,b0:integer;
begin with result do begin
  setlength(limbs,max(length(a.limbs),length(b.limbs)));if limbs=nil then exit;
  c:=0;
  a0:=length(a.limbs)-length(limbs);
  b0:=length(b.limbs)-length(limbs);
  for i:=0 to high(limbs)do
    limbs[i]:=addc(a.getlimb(a0+i),
                   b.getlimb(b0+i),c);
end;end;

class operator TBigFrac.Subtract(const a,b:TBigFrac):TBigFrac;
begin
  result:=a+-b;
end;

function full_mul32(a,b:cardinal;out hi:cardinal):cardinal;
asm
  mul edx
  mov [ecx],edx
end;

class operator TBigFrac.Multiply(const a,b:TBigFrac):TBigFrac;
var ta,tb:TBigFrac;
    res:TArray<int64>;
    i,j,k,discard:integer;
    c,_a,lo,hi:cardinal;
    sum:int64;
begin
  if a.isNeg then ta:=-a else ta:=a;
  if b.isNeg then tb:=-b else tb:=b;

  setlength(res,max(length(ta.limbs),length(tb.limbs))+1);//precision=bigger one
  discard:=(high(ta.limbs)+high(tb.limbs)+1+1)-length(res);
  fillchar(res[0],length(res)*sizeof(res[0]),0);
  for i:=0 to high(ta.limbs)do {if ta.limbs[i]<>0 then} begin
    _a:=ta.limbs[i];
    for j:=0 to high(tb.limbs)do {if tb.limbs[j]<>0 then} begin
      k:=i+j-discard;
      if k<-1 then continue;
      lo:=full_mul32(_a,tb.limbs[j],hi);
      if k>=0 then res[k]:=res[k]+lo;
      if k>=-1 then res[k+1]:=res[k+1]+hi;
    end;
  end;

  setlength(result.limbs,length(res)-1);
  c:=0;
  for i:=0 to high(result.limbs)do begin
    sum:=res[i]+c;
    result.limbs[i]:=sum;
    c:=sum shr 32;
  end;

 //ez egy biztosabb, de lassabb verzio
(*  setlength(res,length(ta.limbs)+length(tb.limbs));{incl high}
  for i:=0 to high(res)do res[i]:=0;
  for i:=0 to high(ta.limbs)do for j:=0 to high(tb.limbs)do begin
    lo:=full_mul32(ta.limbs[i],tb.limbs[j],hi);
    inc(res[i+j],lo);
    inc(res[i+j+1],hi);
  end;

  //carry
  for i:=0 to high(res)-1do begin
    inc(res[i+1],res[i]shr 32);
    res[i]:=res[i] and $FFFFFFFF;
  end;

  setlength(result.limbs,max(length(a.limbs),length(b.limbs)));
  for i:=0 to high(result.limbs)do
    result.limbs[i]:=res[high(res)+i-high(result.limbs)-1];*)

  if a.isNeg xor b.isNeg then result:=-result;
end;

function TBigFrac.Truncated:integer;
begin
  result:=integer(getLimb(high(limbs)));
end;

procedure TBigFrac.FromBigDec(const a:TBigDec;const ALimbCnt:integer);
var i,bitpos:integer;
    tmp:TBigDec;
    _neg:boolean;
    lcnt:integer;
begin
  tmp:=a;
  tmp.Simplify;
  _neg:=tmp.isNeg;
  if _neg then tmp:=-tmp;//abs, deal with sign later

  lcnt:=ALimbCnt;
  if lcnt<=1 then lcnt:=max(ceil(2+max(0,-tmp.exponent)*3.32192809{1/log10(2)}/32),2);

  //whole part
  SetLength(limbs,1);
  limbs[0]:=tmp.Truncated;
  tmp:=tmp-limbs[0];

  //fractional part
  bitpos:=0;
  while not tmp.isZero do begin
    if bitpos=0 then begin
      if Length(limbs)=lcnt then break;
      InsIntArray(TIntegerArray(Limbs),0,0);
      bitpos:=31;
    end else dec(bitpos);

    tmp:=tmp+tmp;// *2
    i:=tmp.Truncated;

    if i<>0 then begin
      tmp:=tmp-i;
      limbs[0]:=limbs[0] or(1 shl bitpos);
    end;
  end;

  if _neg then
    self:=-self;

  SetLimbCount(lcnt);
end;

function TBigFrac.ToBigDec:TBigDec;
var tmp:TBigFrac;
    _neg:boolean;
    whole:integer;
    i:integer;
    ia:TIntegerArray;
begin
  result.Clear;
  tmp:=self;
  _neg:=tmp.isNeg;if _neg then tmp:=-tmp;

  //whole part
  whole:=tmp.Truncated;
  tmp:=tmp-whole;

  //fractional part
  while not tmp.isZero do begin
    tmp:=tmp*10;// *10
//    tmp:=tmp+tmp+tmp+tmp+tmp+tmp+tmp+tmp+tmp+tmp;
    i:=tmp.Truncated;
    tmp:=tmp-i;
    AddIntArrayNoCheck(ia,i);
  end;
  setlength(Result.digits,length(ia));
  for i:=0 to high(ia)do result.digits[high(ia)-i]:=ia[i];
  Result.exponent:=-length(result.digits);

  //put together
  result:=result+whole;
  if _neg then result:=-result;
  result.Simplify;
end;

function TBigFrac.ToStr: ansistring;
begin result:=ToBigDec.ToStr;end;

class operator TBigFrac.implicit(const a:integer):TBigFrac;
begin setlength(result.limbs,1);result.limbs[0]:=a;end;

class operator TBigFrac.implicit(const a:extended):TBigFrac;
begin result.FromBigDec(TBigDec(FloatToStr(a)));end;

procedure TBigFrac.FromStr;
begin
  FromBigDec(TBigDec(a));
end;

class operator TBigFrac.explicit(const a:ansistring):TBigFrac;
begin Result.FromStr(a);end;

class operator TBigFrac.explicit(const a:string):TBigFrac;
begin Result.FromStr(a);end;

class operator TBigFrac.explicit(const a:TBigFrac):extended;
begin Result:=a.ToBigDec.AsFloat end;

class operator TBigFrac.Equal(const a:TBigFrac;const b:extended):boolean;begin Result:=extended(a)=b end;
class operator TBigFrac.NotEqual(const a:TBigFrac;const b:extended):boolean;begin Result:=extended(a)<>b end;
class operator TBigFrac.LessThan(const a:TBigFrac;const b:extended):boolean;begin Result:=extended(a)<b end;
class operator TBigFrac.GreaterThan(const a:TBigFrac;const b:extended):boolean;begin Result:=extended(a)>b end;
class operator TBigFrac.LessThanOrEqual(const a:TBigFrac;const b:extended):boolean;begin Result:=extended(a)<=b end;
class operator TBigFrac.GreaterThanOrEqual(const a:TBigFrac;const b:extended):boolean;begin Result:=extended(a)>=b end;

function Cmp(const a,b:TBigFrac):integer;
var i,cnt,a0,b0:integer;
begin
  cnt:=max(length(a.limbs),length(b.limbs));
  a0:=length(a.limbs)-cnt;
  b0:=length(b.limbs)-cnt;
  for i:=cnt-1 downto 0 do begin
    result:=het.Utils.Cmp(a.getLimb(a0+i),b.getLimb(b0+i));
    if result<>0 then exit;
  end;
  result:=0;
end;

class operator TBigFrac.Equal(const a,b:TBigFrac):boolean;begin result:=cmp(a,b)=0 end;
class operator TBigFrac.NotEqual(const a,b:TBigFrac):boolean;begin result:=cmp(a,b)<>0 end;
class operator TBigFrac.LessThan(const a,b:TBigFrac):boolean;begin Result:=cmp(a,b)<0 end;
class operator TBigFrac.GreaterThan(const a,b:TBigFrac):boolean;begin Result:=cmp(a,b)>0 end;
class operator TBigFrac.LessThanOrEqual(const a,b:TBigFrac):boolean;begin Result:=cmp(a,b)<=0 end;
class operator TBigFrac.GreaterThanOrEqual(const a,b:TBigFrac):boolean;begin Result:=cmp(a,b)>=0 end;

procedure TBigFrac.SetAsFloat(const a: extended);
begin
  FromBigDec(TBigDec(a));
end;

function TBigFrac.GetAsFloat: extended;
begin
  result:=ToBigDec.AsFloat;
end;

procedure testBigFrac;
var a,b:TBigFrac;
    s:ansistring;
    i:integer;
begin
  s:='1.';
  for i:=1 to 2000 do s:=s+toStr(random(10));

  a.FromStr(s);
  b.FromStr(s);

  perfStart('mul');
  for i:=0 to 1000 do begin
    a:=a*b;
  end;
  raise Exception.Create(perfReport);
end;

begin
//  testBigFrac;
end.
