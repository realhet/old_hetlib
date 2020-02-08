unit ULogoDetector;//het.objects

interface

uses windows, sysutils, math, classes, graphics, het.Utils, het.Gfx;

const
  LogoRectOffset:TPoint=(x:24;y:24);
  LogoRectSize:Tpoint=(x:192;y:128);
  MarkerCount=4;
  MinSignalStrength=2;
  LogoHashEnter=6;
  LogoHashExit=10;

type
  TLogoDetector=class;

  TLogoFilter=class(TComponent)
  private
    FRegionIndex:integer;
    bMin,bMax,bEdge,bMin2,bAct:TBitmap;
    FLogoRect:TRect;
  public
    Hash,LastHash,StoredHash:int64;
    SignalStrength:integer;
    function SteadyHash:boolean;
    property LogoRect:TRect read FLogoRect;
    procedure Process(const b:TBitmap);
    function HasSignal:boolean;
    Destructor Destroy;override;
  end;

  TLogoDetector=class(TComponent)
  private
    FRegions:array[0..3]of TLogoFilter;
    FResetCounter:integer;
  public
    LastSignalLostTime0:TDateTime;
    LastSignalLostTime1:TDateTime;
    Debug:boolean;
    RegionMask:integer;
    constructor Create(AOwner:TComponent);
    procedure Process(const b: TBitmap);
    procedure Reset;
    procedure HardReset;
    destructor Destroy;override;
    function HasSignal:boolean;
    function IsAdvertistment:boolean;
  end;

implementation

function CompareLogoHash(const a,b:int64):integer;
begin
  if(a=0)or(b=0)or(((a xor b)and 3)<>0)then exit(64);
  result:=CountBits(a xor b);
end;

function clamp(i:integer):integer;
begin if i<0 then exit(0)else if i>255 then exit(255)else exit(i)end;

function ArrayDerivate(const a:TArray<integer>):TArray<integer>;overload;
var i:integer;
begin
  setlength(result,length(a));
  if length(a)=0 then exit;
  for i:=0 to length(a)-2 do result[i]:=a[i+1]-a[i];
  result[length(result)-1]:=0;
end;

function ArrayDerivate(const a:TArray<integer>;const level:integer):TArray<integer>;overload;
var i:integer;
begin
  if level<=0 then
    result:=a
  else begin
    result:=ArrayDerivate(a);
    for i:=2 to level do
      result:=ArrayDerivate(result);
  end;
end;

{#define _ArrayClear(t)
procedure ArrayClear(var a:TArray<t>);overload;
begin
  if Length(a)>0 then fillchar(a[0],length(a)*sizeof(a[0]),0);
end}

{_ArrayClear(integer);
_ArrayClear(byte);
_ArrayClear(double);
_ArrayClear(single);
_ArrayClear(word);}

procedure ArraySort(var a:TArray<integer>);
var i,j:integer;t:integer;
begin
  for i:=0 to length(a)-2 do for j:=i+1 to length(a)-1 do if a[i]>a[j]then begin
    t:=a[i];a[i]:=a[j];a[j]:=t;
  end;
end;

function ArrayClone(const a:TArray<integer>):TArray<integer>;
begin
  setlength(result,length(a));
  if length(a)>0 then move(a[0],result[0],length(a)*sizeof(a[0]));
end;

function ArraySortF(var a:TArray<integer>):TArray<integer>;
var i,j:integer;t:integer;
begin
  result:=ArrayClone(a);
  ArraySort(result);
end;

function ArrayCopy(const a:TArray<integer>;AFrom,ALen:integer):TArray<integer>;
begin
  if AFrom<0 then begin AFrom:=0;ALen:=ALen+AFrom end;
  if ALen>Length(a)-AFrom then ALen:=Length(a)-AFrom;
  if ALen<=0 then
    setlength(result,0)
  else begin
    setlength(result,ALen);
    move(a[AFrom],result[0],ALen*sizeof(a[0]));
  end;
end;

procedure ArrayAppend(var a:TArray<integer>;const v:integer);
begin
  setlength(a,length(a)+1);
  a[length(a)-1]:=v;
end;

{ TLogoFilter }

destructor TLogoFilter.Destroy;
begin
  FreeAndNil(bMin);
  FreeAndNil(bMax);
  FreeAndNil(bEdge);
  FreeAndNil(bMin2);
  FreeAndNil(bAct);
  inherited;
end;

function TLogoFilter.HasSignal: boolean;
begin
  if(SignalStrength)=0 then exit(false);
  if(SignalStrength>=MinSignalStrength)then exit(true);
  result:=(CompareLogoHash(LastHash,Hash)<LogoHashExit);
end;

function TLogoFilter.SteadyHash:boolean;
begin
  result:=CompareLogoHash(LastHash,Hash)<=LogoHashEnter;
end;

procedure TLogoFilter.Process(const b: TBitmap);
var reset:boolean;
    PixelSumX,PixelSumY:TArray<integer>;
    i,j,LimitX,LimitY:integer;
begin
  b.CopyTo(bAct);
(*  if GetKeyState(VK_SHIFT)<0 then b.PixelOp1(function(a:cardinal):cardinal var r,g,b:integer;begin
    r:=(a and $ff);
    g:=(a shr 8 and $ff);
    b:=(a shr 16 and $ff);
//    g:=clamp((g+(r+b)shr 1-abs(r-g)*abs(b-g)shr 4)div 2);
    g:=min(min(g,r),b);
    result:=g or g shl 8 or g shl 16;;
  end);*)
  bAct.Components:=1;

  bAct.PixelOp1(function(a:cardinal):cardinal begin
    result:=a-64;if result>255 then result:=0;
  end);

  bAct.Components:=1;
  reset:=(bMin=nil)or(GetKeyState(VK_CONTROL)<0)or(TLogoDetector(Owner).FResetCounter>0);
  if reset then begin
    bAct.CopyTo(bMin);
    bAct.CopyTo(bMax);
  end;
  bMin.PixelOpMin(bAct);
  bMax.PixelOpMax(bAct);
{DEFINE FASTER1}
{$IFDEF FASTER1}
  bMax.CopyTo(bAct);
  bAct.PixelOp2(bMin,function(a,b:cardinal):cardinal begin result:=clamp(b shl 1-a) end);
{$ELSE}
  bAct.Assign(bMin);
{$ENDIF}

  bAct.CopyTo(bEdge);
  bEdge.BlurAvg(7);
  bAct.PixelOp2(bEdge,function(a,b:cardinal):cardinal begin result:=clamp((b-a)*(b-a)) end);

{DEFINE FASTER2}
{$IFDEF FASTER2}
  if reset then bAct.CopyTo(bMin2);
  bMin2.PixelOpMin(bAct);
  bAct.Assign(bMin2);
{$ENDIF}

  bAct.PixelSumXY(PixelSumX,PixelSumY);
  PixelSumX:=ArrayDerivate(PixelSumX,1);
  PixelSumY:=ArrayDerivate(PixelSumY,1);


  LimitX:=-ArraySortF(PixelSumX)[MarkerCount-1];
  LimitY:=-ArraySortF(PixelSumY)[MarkerCount-1];

  //signal rect
  FLogoRect:=rect(0,0,bAct.Width,bAct.Height);
  for i:=0 to high(PixelSumX)do     if abs(PixelSumX[i])>=LimitX shr 2 then begin FLogoRect.Left:=i;     break end;
  for i:=high(PixelSumX)downto 0 do if abs(PixelSumX[i])>=LimitX shr 2 then begin FLogoRect.Right:=i+1;  break end;
  for i:=0 to high(PixelSumY)do     if abs(PixelSumY[i])>=LimitY shr 2 then begin FLogoRect.Top:=i;      break end;
  for i:=high(PixelSumY)downto 0 do if abs(PixelSumY[i])>=LimitY shr 2 then begin FLogoRect.Bottom:=i+1; break end;

  //clip to rect
  SignalStrength:=bAct.PixelSumXY(FLogoRect,PixelSumX,PixelSumY)shr 14;//bugos
  PixelSumX:=ArrayDerivate(PixelSumX,1);
  PixelSumY:=ArrayDerivate(PixelSumY,1);

  LimitX:=-ArraySortF(PixelSumX)[min(length(PixelSumX),MarkerCount)-1];
  LimitY:=-ArraySortF(PixelSumY)[min(length(PixelSumX),MarkerCount)-1];

  LastHash:=Hash;
  Hash:=FRegionIndex and 3;
  for i:=0 to High(PixelSumX)do if abs(PixelSumX[i])<LimitX then PixelSumX[i]:=0 else Hash:=Hash or(1 shl((i+FLogoRect.Left) mod 31+2 ));
  for i:=0 to High(PixelSumY)do if abs(PixelSumY[i])<LimitY then PixelSumY[i]:=0 else Hash:=Hash or(1 shl((i+FLogoRect.Top)  mod 31+33));
  if SignalStrength<MinSignalStrength then Hash:=0;

  bAct.Canvas.Brush.Style:=bsClear;
  with FLogoRect do bAct.Canvas.Rectangle(Left,Top,Right,Bottom);
  bAct.Canvas.Brush.Style:=bsSolid;

  bAct.Canvas.Pen.Color:=clSilver;
  bAct.DrawGraph(point(0,bAct.Height shr 1),point(1,0),0.003,PixelSumX);
  bAct.DrawGraph(point(bAct.Width shr 1,0),point(0,1),0.003,PixelSumY);

  if GetKeyState(VK_SHIFT)<0 then StoredHash:=Hash;

  bAct.Canvas.TextOut(0,0,'str '+tostr(SignalStrength));
  bAct.Canvas.TextOut(0,16,'storedCmp '+tostr(CompareLogoHash(Hash,StoredHash)));
  bAct.Canvas.TextOut(0,32,'lastCmp '+tostr(CompareLogoHash(Hash,LastHash)));

  b.Assign(bAct);
  if HasSignal then with b.canvas do begin
    Pen.Color:=clFuchsia;
    Brush.Style:=bsClear;
    with FLogoRect do Rectangle(Left,Top,Right,Bottom);
  end;

end;

{ TLogoDetector }

constructor TLogoDetector.Create;
var i:integer;
begin
  inherited;
  for i:=0 to high(FRegions)do begin
    FRegions[i]:=TLogoFilter.Create(self);
    FRegions[i].FRegionIndex:=i;
  end;
  RegionMask:=$f;
end;

destructor TLogoDetector.Destroy;
begin
  inherited;
end;

function TLogoDetector.HasSignal: boolean;
var lf:TLogoFilter;
begin
  for lf in FRegions do if lf.HasSignal then exit(true);
  result:=false;
end;

function TLogoDetector.IsAdvertistment: boolean;
begin
  result:=(Now-LastSignalLostTime0<15/24/60/60)
       and(Now-LastSignalLostTime1<15/24/60/60);
end;

procedure TLogoDetector.Process(const b: TBitmap);
var i:Integer;
    r:trect;
    bTmp:TBitmap;
    lf:TLogoFilter;

begin
  for i:=0 to high(FRegions)do if((1 shl i)and RegionMask)<>0 then begin
    r:=rect(        LogoRectOffset.X,          LogoRectOffset.Y,
            b.Width-LogoRectOffset.X, b.Height-LogoRectOffset.Y);
    if (i and 1)=0 then r.Right:=r.Left +LogoRectSize.X
                   else r.Left :=r.Right-LogoRectSize.X;
    if (i and 2)=0 then r.Bottom:=r.Top   +LogoRectSize.Y
                   else r.Top   :=r.Bottom-LogoRectSize.Y;

    bTmp:=TBitmap.CreateNew(pf32bit,r.Right-r.Left,r.Bottom-r.Top);
    try
      bTmp.Canvas.CopyRect(rect(0,0,bTmp.Width,bTmp.Height),b.Canvas,r);
      FRegions[i].Process(bTmp);
      if Debug then begin
        b.Canvas.Draw(r.Left,r.Top,bTmp);
      end;
    finally
      FreeandNil(bTmp);
    end;
  end;

  //Logo detector logic
  if FResetCounter>0 then begin dec(FResetCounter);exit end;

  if not HasSignal then begin
    if LastSignalLostTime0<LastSignalLostTime1 then LastSignalLostTime0:=now
                                               else LastSignalLostTime1:=now;
    Reset;
    exit
  end;
end;

procedure TLogoDetector.Reset;
begin
  FResetCounter:=5;
end;

procedure TLogoDetector.HardReset;
begin
  Reset;
  LastSignalLostTime0:=0;
  LastSignalLostTime1:=0;
end;

end.
