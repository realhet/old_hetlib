//many functions here are from GLSCENE
unit UMatrix;
interface
uses UVector, math;

type
  TEulerOrder=(XYZ,XZY,YXZ,YZX,ZXY,ZYX);
  TM44f=array[0..3,0..3]of single;
  TM44d=array[0..3,0..3]of double;

const
  M44fIdentity:TM44f=((1,0,0,0),(0,1,0,0),(0,0,1,0),(0,0,0,1));
  M44dIdentity:TM44d=((1,0,0,0),(0,1,0,0),(0,0,1,0),(0,0,0,1));

const //nem itt a helye
  Null4F:TV4f=(x:0;y:0;z:0;w:0);
  Null3F:TV3f=(x:0;y:0;z:0);
  NullV2i:TV2i=(x:0;y:0);
  NullV2f:TV2f=(x:0;y:0);


type
  TQuaternion=packed record
    Imag:TV3f;
    Real:Single;

    class operator Equal(a,b:TQuaternion):boolean;inline;
    class operator NotEqual(a,b:TQuaternion):boolean;inline;
  end;

const
  QIdentity:TQuaternion=(Imag:(x:0;y:0;z:0);Real:1);

function MTranspose(const a:TM44f):TM44f;

procedure MMultiply(var a:TM44f;const b:single);overload;
function MMultiply(const a,b:TM44f):TM44f;overload;
  function MMultiply(const a,b:TM44d):TM44d;overload;

function MInverse(const a:TM44f):TM44f;overload;
  function MInverse(const a:TM44d):TM44d;overload;
function MNormalize(const a:TM44f):TM44f;

function VTransform(const m:TM44f;const v:TV3f):TV3f;overload;
  function VTransform(const m:TM44d;const v:TV3d):TV3d;overload;
function VTransform(const m:TM44f;const v:TV2f):TV2f;overload;
function VTransformNormal(const m:TM44f;const v:TV3f):TV3f;
function VTransformNoProj(const m:TM44f;const v:TV3f):TV3f;


function MTranslation(const x,y,z:single):TM44f;overload;
function MTranslation(const v:TV3f):TM44f;overload;
  function MTranslationD(const v:TV3d):TM44d;overload;
function MTranslation(const v:TV2f):TM44f;overload;

function MScaling(const s:single):TM44f;overload;
  function MScalingD(const s:double):TM44d;overload;
function MScaling(const x,y,z:single):TM44f;overload;
function MScaling(const v:TV2f):TM44f;overload;
function MScaling(const v:TV3f):TM44f;overload;

function MRotationX(const angle:single):TM44f;
function MRotationY(const angle:single):TM44f;
function MRotationZ(const angle:single):TM44f;
function MRotation(const Axis:TV3f;const angle:Double):TM44f;overload;
function MRotation(const EulerOrder:TEulerOrder;const a,b,c:Double):TM44f;overload;
function MRotation(const EulerOrder:TEulerOrder;const v:TV3d):TM44f;overload;
function MRotation(const q:TQuaternion):TM44f;overload;

procedure MTranslate(var m:TM44f;const x,y,z:single);overload;
procedure MTranslate(var m:TM44f;const v:TV3f);overload;
  procedure MTranslate(var m:TM44d;const v:TV3d);overload;
procedure MTranslate(var m:TM44f;const v:TV2f);overload;

procedure MScale(var m:TM44f;const s:single);overload;
  procedure MScale(var m:TM44d;const s:double);overload;
procedure MScale(var m:TM44f;const x,y,z:single);overload;
procedure MScale(var m:TM44f;const v:TV2f);overload;
procedure MScale(var m:TM44f;const v:TV3f);overload;

procedure MRotateX(var m:TM44f;const angle:single);overload;
procedure MRotateY(var m:TM44f;const angle:single);overload;
procedure MRotateZ(var m:TM44f;const angle:single);overload;
  procedure MRotateZ(var m:TM44d;const angle:double);overload;
procedure MRotate(var m:TM44f;const Axis:TV3f;const angle:single);overload;
procedure MRotate(var m:TM44f;const EulerOrder:TEulerOrder;const a,b,c:Single);overload;
procedure MRotate(var m:TM44f;const q:TQuaternion);overload;

procedure MSetRow(var m:TM44f;const r:integer;const v:TV3f);
procedure MSetCol(var m:TM44f;const c:integer;const v:TV3f);

function MLookAt(const eye,target,up:TV3f):TM44f;

function Quaternion(const v1,v2:TV3f):TQuaternion;overload;
function Quaternion(const m:TM44f):TQuaternion;overload;
function Quaternion(const axis:TV3f;const angle:single):TQuaternion;overload;
function Quaternion(const EulerOrder:TEulerOrder;const a,b,c:Single):TQuaternion;overload;

function QSLerp(const q1,q2:TQuaternion;const t:single):TQuaternion;

function MSLerp(const m1,m2:TM44f;const t:single):TM44f;
function MLerp(const m1,m2:TM44f;const t:single):TM44f;

function MMultiply(const a,b,c:TM44f):TM44f;overload;
function MMultiply(const a,b,c,d:TM44f):TM44f;overload;
function MMultiply(const a,b,c,d,e:TM44f):TM44f;overload;
function MMultiply(const a,b,c,d,e,f:TM44f):TM44f;overload;

function MColorAdjustBGR(const Brightness,Contrast,Saturation:single;const HUE:single=0):TM44f;
function MColorAdjustRGB(const Brightness,Contrast,Saturation:single;const HUE:single=0):TM44f;

function MFrustum(const Left,Right,Bottom,Top, zNear,zFar:single):TM44f;
function MProjection(const FOVy,Aspect,zNear,zFar:single):TM44f;
function MOrtho(const Left,Right,Bottom,Top,zNear,zFar:single):TM44f;overload;
function MOrtho(const YSize,Aspect,zNear,zFar:single):TM44f;overload;

//some utility stuff
function PointSegmentClosestPoint(const point,segmentStart,segmentStop:TV3f):TV3f;
function PointSegmentDistance(const point, segmentStart, segmentStop : TV3f):Single;
procedure SegmentSegmentClosestPoint(const SA0,SA1,SB0,SB1:TV3f;out SAClosest,SBClosest:TV3f);
function SegmentSegmentDistance(const SA0,SA1,SB0,SB1:TV3f):single;
function RayCastTriangleIntersect(const rayStart,rayVector,p1,p2,p3:TV3f;out intersectPoint:TV3f):boolean;

function M44d(const a:TM44f):TM44d;

function MFromQuaternion(const q:TQuaternion):TM44f;



type //from glscene
  TPlane=record
    v:TV4f;
    function EvalPoint(const APoint:TV3f):single;
  end;

  TFrustum=record
    pLeft,pRight,pTop,pBottom,pNear,pFar:TPlane;
    function IsVolumeClipped(const APos:TV3f;const ARadius:Single):boolean;overload;
    function IsVolumeClipped(const AMin,AMax:TV3f):boolean;overload;
  end;

  TClippingInfo = record
    origin:TV3f;
    clippingDirection:TV3f;
    viewPortRadius:Single; // viewport bounding radius per distance unit
    farClippingDistance:Single;
    frustum:TFrustum;
  end;

function ExtractFrustumFromModelViewProjection(const mvp:TM44f):TFrustum;

type
  TQuad2f=record //project/unproject a quad
    TopLeft,TopRight,BottomLeft,BottomRight:TV2f;
    hr,vr:Single;//ratioes
    procedure _Prepare;
    function Project(const p:TV2f):TV2f;
    function _invBiLerp(const p:TV2f;out res1,res2:TV2f;out valid1,valid2:boolean):boolean;overload;
    function _invBiLerp(const p:TV2f):TV2f;overload;//returns the 1st valid; returns (-1,-1) when fails
    function UnProject(const p:TV2f):TV2f;
  end;

  TRect2f=record
    TopLeft,BottomRight:TV2f;
    function Size:TV2f;
    function TopRight:TV2f;
    function BottomLeft:TV2f;
    procedure Offset(const v:TV2f);
    procedure Inflate(const v:TV2f);overload;
    procedure Inflate(const s:single);overload;
    function PointInside(const p:TV2f):boolean;
    procedure Expand(const p:TV2f);
    function LineClip(var A,B:TV2f):boolean;{visible or not}
    function CheckIntersection(const r: TRect2f): boolean;
  end;

function CalcBounds(var data:TV2f;const count:integer;const AInflate:Single=0):TRect2f;overload;
function CalcBounds(const A,B:TV2f;const AInflate:Single=0):TRect2f;overload;

function Quad2f(const ATopLeft,ATopRight,ABottomLeft,ABottomRight:TV2f):TQuad2f;

function VRoundDir(const v:TV3f):TV3i;
function MRoundDir(const m:TM44f):TM44f;

function MRow(const m:TM44f;const n:integer):TV3f;
function MCol(const m:TM44f;const n:integer):TV3f;

function MSetRotation(const m,rot:TM44f):TM44f;
function MSetScale(const m:TM44f;const scale:TV3f):TM44f;
function MSetTranslation(const m:TM44f;const trans:TV3f):TM44f;

function VRot90(const v:TV2f):TV2f;
function VRot(const v:TV2f;const rad:single):TV2f;

function AngleNormalize(const a:single):single;
function VAngleAbs(const a,b:TV2f):single;

function MEqual(const a,b:TM44f):boolean;overload;

function Floor(const v:TV2f):TV2i;overload;
function Floor(const v:TV3f):TV3i;overload;

function Ceil(const v:TV2f):TV2i;overload;
function Ceil(const v:TV3f):TV3i;overload;

procedure Swap(var a,b:TV3f);overload;
procedure Swap(var a,b:TV2f);overload;

implementation

uses
  het.Utils;

{ TRect2f }

function TRect2f.TopRight: TV2f;
begin
  result.x:=BottomRight.x; result.y:=TopLeft.y;
end;

function TRect2f.BottomLeft: TV2f;
begin
  result.x:=TopLeft.x; result.y:=BottomRight.y;
end;

procedure TRect2f.Inflate(const v: TV2f);
begin
  TopLeft:=TopLeft-v;
  BottomRight:=BottomRight+v;
end;

procedure TRect2f.Expand(const p: TV2f);
asm
  movq xmm1,[eax]    //TopLeft
  movq xmm2,[eax+8]  //BottomRight
  movq xmm0,[edx]    //p
  minps xmm1,xmm0
  maxps xmm2,xmm0
  movq [eax],xmm1
  movq [eax+8],xmm2
end;

procedure TRect2f.Inflate(const s: single);
var v:TV2f;
begin
  v:=v2f(s,s);
  TopLeft:=TopLeft-v;
  BottomRight:=BottomRight+v;
end;

procedure TRect2f.Offset(const v: TV2f);
begin
  TopLeft:=TopLeft+v;
  BottomRight:=BottomRight+v;
end;

function TRect2f.PointInside(const p: TV2f): boolean;
begin
  result:=(p.x>=topleft.x)and(p.y>=topleft.y)and(p.x<=bottomright.x)and(p.y<=bottomright.y)
end;

function TRect2f.Size: TV2f;
begin
  result:=BottomRight-TopLeft;
end;

function TRect2f.LineClip(var A, B: TV2f): boolean;
// CohenSutherlandClipping: Ported to Delphi from wikipedia C code by Omar Reis - 2012
const
  INSIDE = 0; // 0000
  LEFT   = 1; // 0001
  RIGHT  = 2; // 0010
  BOTTOM = 4; // 0100
  TOP    = 8; // 1000

  // Compute the bit code for a point (x, y) using the clip rectangle
  function ComputeOutCode(const v:TV2f):Integer;
  begin with v do begin
    result := INSIDE; // initialised as being inside of clip window

    if (x < TopLeft.x) then result := result or  LEFT            // to the left of clip window
    else if (x > BottomRight.x) then result := result or  RIGHT; // to the right of clip window

    if (y < TopLeft.y) then result := result or  BOTTOM          // below the clip window
    else if (y > BottomRight.y) then result := result or  TOP;   // above the clip window
  end;end;

var outcode0,outcode1,outcodeOut:Integer; x,y:single;
begin
  // compute outcodes for P0, P1, and whatever point lies outside the clip rectangle
  outcode0 := ComputeOutCode(a);
  outcode1 := ComputeOutCode(b);
  result   := false;
  x:=0; y:=0;
  while (true) do
    begin
      if (outcode0 or outcode1 = 0 ) then // Bitwise OR is 0. Trivially result and get out of loop
        begin
          result := true;
          break;
        end
        else if (outcode0 and outcode1<>0) then // Bitwise AND is not 0. Trivially reject and get out of loop
        begin
          break;
        end
        else begin
          // failed both tests, so calculate the line segment to clip
          // from an outside point to an intersection with clip edge
          // At least one endpoint is outside the clip rectangle; pick it.
          if (outcode0 <> 0) then outcodeOut:=outcode0
            else outcodeOut:=outcode1;     //outcodeOut = outcode0 ? outcode0 : outcode1;
          // Now find the intersection point;
          // use formulas y = a.y + slope * (x - a.x), x = a.x + (1 / slope) * (y - a.y)
          if (outcodeOut and TOP <>0 ) then           // point is above the clip rectangle
            begin
              x := a.x + (b.x - a.x) * (BottomRight.y - a.y) / (b.y - a.y);
              y := BottomRight.y;
            end
          else if (outcodeOut and BOTTOM <>0) then  // point is below the clip rectangle
            begin
              x := a.x + (b.x - a.x) * (TopLeft.y - a.y) / (b.y - a.y);
              y := TopLeft.y;
            end
          else if (outcodeOut and RIGHT <>0) then  // point is to the right of clip rectangle
            begin
              y := a.y + (b.y - a.y) * (BottomRight.x - a.x) / (b.x - a.x);
              x := BottomRight.x;
            end
          else if (outcodeOut and LEFT <>0) then   // point is to the left of clip rectangle
            begin
              y := a.y + (b.y - a.y) * (TopLeft.x - a.x) / (b.x - a.x);
              x := TopLeft.x;
            end;

          (* NOTE:if you follow this algorithm exactly(at least for c#), then you will fall into an infinite loop
          in case a line crosses more than two segments. to avoid that problem, leave out the last else
          if(outcodeOut & LEFT) and just make it else *)

          // Now we move outside point to intersection point to clip
          // and get ready for next pass.
          if (outcodeOut = outcode0) then
            begin
              a.x := x;
              a.y := y;
              outcode0 := ComputeOutCode(a);
            end
            else begin
              b.x := x;
              b.y := y;
              outcode1 := ComputeOutCode(b);
            end;
        end;
    end;
end;


function CalcBounds(var data:TV2f;const count:integer;const AInflate:Single=0):TRect2f;overload;
var p,pend:^TV2f;
begin with Result do begin
  if count<=0 then begin TopLeft:=NullV2f;BottomRight:=NullV2f;exit end;
  p:=@data;
  pend:=p; inc(pend,count);

  TopLeft:=p^; BottomRight:=p^;//first value
  while integer(p)<integer(pend) do with p^ do begin
    Expand(p^);
    inc(p);
  end;

  if AInflate<>0 then
    Inflate(AInflate);
end;end;

function CalcBounds(const A,B:TV2f;const AInflate:Single=0):TRect2f;overload;
begin with result do begin
  if A.x<B.x then begin Topleft.x:=A.x;BottomRight.x:=B.x;end
             else begin Topleft.x:=B.x;BottomRight.x:=A.x;end;
  if A.y<B.y then begin Topleft.y:=A.y;BottomRight.y:=B.y;end
             else begin Topleft.y:=B.y;BottomRight.y:=A.y;end;
  if AInflate<>0 then
    Inflate(AInflate);
end;end;

function TRect2f.CheckIntersection(const r:TRect2f):boolean;
begin
  result:=not(   (r.BottomRight.x<  TopLeft.x)
               or(  BottomRight.x<r.TopLeft.x)
               or(r.BottomRight.y<  TopLeft.y)
               or(  BottomRight.y<r.TopLeft.y) );
end;


procedure Swap(var a,b:TV3f);
var c:TV3f;
begin
  c:=a; a:=b; b:=c;
end;

procedure Swap(var a,b:TV2f);
var c:TV2f;
begin
  c:=a; a:=b; b:=c;
end;

function Floor(const v:TV2f):TV2i;
begin
  result.x:=floor(v.x);
  result.y:=floor(v.y);
end;

function Floor(const v:TV3f):TV3i;
begin
  result.x:=floor(v.x);
  result.y:=floor(v.y);
  result.z:=floor(v.z);
end;

function Ceil(const v:TV2f):TV2i;
begin
  result.x:=Ceil(v.x);
  result.y:=Ceil(v.y);
end;

function Ceil(const v:TV3f):TV3i;
begin
  result.x:=Ceil(v.x);
  result.y:=Ceil(v.y);
  result.z:=Ceil(v.z);
end;

function MEqual(const a,b:TM44f):boolean;
var i,j:integer;
begin
  for i:=0 to 3 do for j:=0 to 3 do if a[i,j]<>b[i,j] then exit(false);
  result:=true;
end;

function AngleNormalize(const a:single):single;
begin
  result:=a;
  while result<-pi do result:=result+pi*2;
  while result>pi do result:=result-pi*2;
end;

function VAngleAbs(const a,b:TV2f):single;
begin
  result:=AngleNormalize(ArcTan2(b.y,b.x)-ArcTan2(a.y,a.x));
end;

function VRot90(const v:TV2f):TV2f;  //orajarassal ellentetes
begin
  result.x:=-v.y;
  result.y:= v.x;
end;

function VRot(const v:TV2f;const rad:single):TV2f;
var s,c:single;
begin
  SinCos(rad,s,c);
  result.x:= c*v.x -s*v.y;
  result.y:= s*v.x +c*v.y;
end;

function MSetRotation(const m,rot:TM44f):TM44f;
var i:integer;
begin
  result:=m;
  for i:=0 to 2 do MSetRow(result,i, VNormalize(MRow(rot,i))*VLength(MRow(m,i)) );
end;

function MSetScale(const m:TM44f;const scale:TV3f):TM44f;
begin
  result:=m;
  MSetRow(result,0, VNormalize(MRow(m,0))*scale.x );
  MSetRow(result,1, VNormalize(MRow(m,1))*scale.y );
  MSetRow(result,2, VNormalize(MRow(m,2))*scale.z );
end;

function MSetTranslation(const m:TM44f;const trans:TV3f):TM44f;
begin
  result:=m;
  MSetRow(result,3,trans);
end;

function MRow(const m:TM44f;const n:integer):TV3f;
begin
  result.x:=m[n,0];
  result.y:=m[n,1];
  result.z:=m[n,2];
end;

function MCol(const m:TM44f;const n:integer):TV3f;
begin
  result.x:=m[0,n];
  result.y:=m[1,n];
  result.z:=m[2,n];
end;

function VRoundDir(const v:TV3f):TV3i;
var i:integer;
begin
  if abs(v.y )>abs(v.x )then i:=1 else i:=0;
  if abs(v.z )>abs(v.Coord[i])then i:=2;
  result:=v3i(0,0,0);
  result.Coord[i]:=sign(v.Coord[i]);
end;

function MRoundDir(const m:TM44f):TM44f;
var i,j:integer;
    v:TV3f;
begin //!!!! ez még nem tuti
  result:=m;
  for i:=0 to 2 do begin
    for j:=0 to 2 do v.Coord[j]:=result[i,j];
    v:=VRoundDir(v);
    for j:=0 to 2 do result[i,j]:=v.Coord[j];
  end;
end;

function Quad2f(const ATopLeft,ATopRight,ABottomLeft,ABottomRight:TV2f):TQuad2f;
begin
  with result do begin
    TopLeft:=ATopLeft;       TopRight:=ATopRight;
    BottomLeft:=ABottomLeft; BottomRight:=ABottomRight;
    _Prepare;
  end;
end;

procedure TQuad2f._Prepare;
begin
  hr:=VDist(TopLeft,BottomLeft)/VDist(TopRight,BottomRight);
  vr:=VDist(TopLeft,TopRight)/VDist(BottomLeft,BottomRight);
end;

function TQuad2f.Project(const p:TV2f):TV2f;
var tx,ty:single;
begin
  tx:=1-power(1-p.x ,hr);
  ty:=1-power(1-p.y ,vr);
  Result:=VLerp(VLerp(TopLeft   ,TopRight   ,tx),
                VLerp(BottomLeft,BottomRight,tx),ty);
end;

function TQuad2f._invBiLerp(const p:TV2f;out res1,res2:TV2f;out valid1,valid2:boolean):boolean;
//inverse bilerp source: http://stackoverflow.com/questions/808441/inverse-bilinear-interpolation
  function cross2(const x0,y0,x1,y1:single):single;begin result:=x0*y1 - y0*x1;end;
  function equals(const a,b,tol:single):boolean;begin result:=abs(a-b)<=tol end;
  function in_range(const val,range_min,range_max,tol:single):Boolean;
  begin result:=((val+tol)>=range_min)and((val-tol)<=range_max) end;

var x,y,x0,y0,x1,y1,x2,y2,x3,y3:single;
    a,b1,b2,c,b,am2bpc:single;
    s,s2,t,t2:single;
    num_valid_s:integer;
    sqrtbsqmac,tdenom_x,tdenom_y:single;
begin
  s2:=0;t:=0;t2:=0;//nowarn

  x:=p.x ;                 y:=p.y ;
  x0:=TopLeft.x ;          y0:=TopLeft.y ;
  x1:=TopRight.x ;         y1:=TopRight.y ;
  x2:=BottomLeft.x ;       y2:=BottomLeft.y ;
  x3:=BottomRight.x ;      y3:=BottomRight.y ;

  a :=cross2(x0-x,y0-y,x0-x2,y0-y2 );
  b1:=cross2(x0-x,y0-y,x1-x3,y1-y3 );
  b2:=cross2(x1-x,y1-y,x0-x2,y0-y2 );
  c :=cross2(x1-x,y1-y,x1-x3,y1-y3 );
  b :=0.5*(b1+b2);

  am2bpc:=a-2*b+c;
  //* this is how many valid s values we have */
  num_valid_s:=0;

  if equals(am2bpc,0,1e-10)then begin
    if equals(a,c,1e-10)then exit(false);
      //* Looks like the input is a line */
      //* You could set s=0.5 and solve for t if you wanted to */
      s:=a/(a-c);
      if in_range(s,0,1,1e-10)then
        num_valid_s:=1;
  end else begin
    sqrtbsqmac:=sqrt(b*b-a*c);
    s :=((a-b)-sqrtbsqmac)/am2bpc;
    s2:=((a-b)+sqrtbsqmac)/am2bpc;
    num_valid_s:=0;
    if in_range(s,0,1,1e-10)then begin
      inc(num_valid_s);
      if in_range(s2,0,1,1e-10)then
        inc(num_valid_s);
    end else begin
      if in_range(s2,0,1,1e-10)then begin
        inc(num_valid_s);
        s:=s2;
      end;
    end;
  end;

  if num_valid_s=0 then
    exit(false);

  valid1:=false;
  if num_valid_s>=1 then begin
    tdenom_x:=(1-s)*(x0-x2)+s*(x1-x3);
    tdenom_y:=(1-s)*(y0-y2)+s*(y1-y3);
    valid1:=true;
    if equals(tdenom_x,0,1e-10)and equals(tdenom_y,0,1e-10)then begin
      valid1:=false;
    end else begin
      //* Choose the more robust denominator */
      if abs(tdenom_x)>abs(tdenom_y)then t:=((1-s)*(x0-x)+s*(x1-x))/tdenom_x
                                    else t:=((1-s)*(y0-y)+s*(y1-y))/tdenom_y;
      if not in_range(t,0,1,1e-10)then
        valid1:=false;
    end;
  end;

  //* Same thing for s2 and t2 */
  valid2:=false;
  if num_valid_s=2 then begin
    tdenom_x:=(1-s2)*(x0-x2)+s2*(x1-x3);
    tdenom_y:=(1-s2)*(y0-y2)+s2*(y1-y3);
    valid2:=true;
    if equals(tdenom_x,0,1e-10)and equals(tdenom_y,0,1e-10)then begin
      valid2:=false;
    end else begin
      //* Choose the more robust denominator */
      if abs(tdenom_x)>abs(tdenom_y)then t2:=((1-s2)*(x0-x)+s2*(x1-x))/tdenom_x
                                    else t2:=((1-s2)*(y0-y)+s2*(y1-y))/tdenom_y;
      if not in_range(t2,0,1,1e-10)then
        valid2:=false;
    end;
  end;

  //* Output */
  if valid1 then
    res1:=V2f(s,t);
  if valid2 then
    res2:=V2f(s2,t2);

  result:=valid1 or valid2;
end;

function TQuad2f._invBiLerp(const p:TV2f):TV2f;
var r2:TV2f;v1,v2:boolean;
begin
  if not _invBiLerp(p,result,r2,v1,v2)then
    result:=V2f(-1,-1)
  else if not v1 then
    result:=r2;
end;

function TQuad2f.UnProject(const p:TV2f):TV2f;
begin
  result:=_invBiLerp(p);

  with result do begin
    if(x =-1)and(y =-1)then exit;

    x :=1-power(1-x ,1/hr);
    y :=1-power(1-y ,1/vr);
  end;
end;


function TPlane.EvalPoint(const APoint:TV3f):single;
begin
  Result:=v.x *APoint.x
         +v.y *APoint.y
         +v.z *APoint.z
         +v.w ;
end;

procedure NormalizePlane(var plane : TPlane);
begin
  with plane do v:=v*(1/Sqrt(v.x *v.x +v.y *v.y +v.z *v.z ));
end;

function TFrustum.IsVolumeClipped(const APos:TV3f;const ARadius:Single):Boolean;
var negRadius : Single;
begin
  negRadius:=-ARadius;
  Result:=(pTop   .EvalPoint(APos)<negRadius) //top/bottom clip first in a horiz. world
        or(pBottom.EvalPoint(APos)<negRadius)
        or(pNear  .EvalPoint(APos)<negRadius)
        or(pLeft  .EvalPoint(APos)<negRadius)
        or(pRight .EvalPoint(APos)<negRadius)
        or(pFar   .EvalPoint(APos)<negRadius);
end;

function TFrustum.IsVolumeClipped(const AMin,AMax:TV3f):Boolean;
begin
  Result:=IsVolumeClipped((AMin+AMax)*0.5,VDist(AMin,AMax)*0.5);
end;

function ExtractFrustumFromModelViewProjection(const mvp:TM44f):TFrustum;
begin
  with Result do begin
    // extract left plane
    pLeft.v:=  v4f(mvp[0][3]+mvp[0][0],
                   mvp[1][3]+mvp[1][0],
                   mvp[2][3]+mvp[2][0],
                   mvp[3][3]+mvp[3][0]);
    NormalizePlane(pLeft);
    // extract top plane
    pTop.v:=   v4f(mvp[0][3]-mvp[0][1],
                   mvp[1][3]-mvp[1][1],
                   mvp[2][3]-mvp[2][1],
                   mvp[3][3]-mvp[3][1]);
    NormalizePlane(pTop);
    // extract right plane
    pRight.v:= v4f(mvp[0][3]-mvp[0][0],
                   mvp[1][3]-mvp[1][0],
                   mvp[2][3]-mvp[2][0],
                   mvp[3][3]-mvp[3][0]);
    NormalizePlane(pRight);
    // extract bottom plane
    pBottom.v:=v4f(mvp[0][3]+mvp[0][1],
                   mvp[1][3]+mvp[1][1],
                   mvp[2][3]+mvp[2][1],
                   mvp[3][3]+mvp[3][1]);
    NormalizePlane(pBottom);
    // extract far plane
    pFar.v:=   v4f(mvp[0][3]-mvp[0][2],
                   mvp[1][3]-mvp[1][2],
                   mvp[2][3]-mvp[2][2],
                   mvp[3][3]-mvp[3][2]);
    NormalizePlane(pFar);
    // extract near plane
    pNear.v:=  v4f(mvp[0][3]+mvp[0][2],
                   mvp[1][3]+mvp[1][2],
                   mvp[2][3]+mvp[2][2],
                   mvp[3][3]+mvp[3][2]);
    NormalizePlane(pNear);
  end;
end;



function M44d(const a:TM44f):TM44d;
var i,j:integer;
begin
  for i:=0 to 3 do for j:=0 to 3 do result[i,j]:=a[i,j];
end;

const
  EPSILON  : Single = 1e-40;
  EPSILON2 : Single = 1e-30;
  cOne:Single=1;

function PointSegmentClosestPoint(const point,segmentStart,segmentStop:TV3f):TV3f;
var w,lineDirection:TV3f;
    c1,c2,b:Single;
begin
   lineDirection:=segmentStop-segmentStart;
   w:=point-segmentStart;

   c1:=VDot(w,lineDirection);
   c2:=VDot(lineDirection,lineDirection);
   b:=EnsureRange(c1/c2,0,1);

   Result:=segmentStart+lineDirection*b;
end;

function PointSegmentDistance(const point, segmentStart, segmentStop : TV3f):Single;
var pb:TV3f;
begin
  pb:=PointSegmentClosestPoint(point,segmentStart,segmentStop);
  Result:=VDist(point,pb);
end;

// http://geometryalgorithms.com/Archive/algorithm_0104/algorithm_0104B.htm
procedure SegmentSegmentClosestPoint(const SA0,SA1,SB0,SB1:TV3f;out SAClosest,SBClosest:TV3f);
const cSMALL_NUM = 0.000000001;
var u,v,w:TV3f;
    a,b,c,smalld,e,largeD,sc,sn,sD,tc,tN,tD:single;
begin
  u:=SA1-SA0;
  v:=SB1-SB0;
  w:=SA0-SB0;

  a:=VDot(u,u);
  b:=VDot(u,v);
  c:=VDot(v,v);
  smalld:=VDot(u,w);
  e:=VDot(v,w);
  largeD:=a*c-b*b;

  sD:=largeD;
  tD:=largeD;

  if LargeD<cSMALL_NUM then begin
    sN:=0;
    sD:=1;
    tN:=e;
    tD:=c;
  end else begin
    sN:=(b*e-c*smallD);
    tN:=(a*e-b*smallD);
    if sN<0 then begin
      sN:=0;
      tN:=e;
      tD:=c;
    end else if sN>sD then begin
      sN:=sD;
      tN:=e+b;
      tD:=c;
    end;
  end;

  if tN<0 then begin
    tN:=0;
    // recompute sc for this edge
    if -smalld<0 then sN:=0
    else if -smalld>a then sN:=sD
    else begin
      sN:=-smalld;
      sD:=a;
    end;
  end else if tN>tD then begin
    tN:=tD;
    // recompute sc for this edge
    if (-smallD+b)<0 then sN:=0
    else if (-smallD+b)>a then sN := sD
    else begin
      sN:=-smallD + b;
      sD:=a;
    end;
  end;

  // finally do the division to get sc and tc
  //sc := (abs(sN) < SMALL_NUM ? 0.0 : sN / sD);
  if abs(sN)<cSMALL_NUM then sc:=0
                        else sc:=sN/sD;

  //tc := (abs(tN) < SMALL_NUM ? 0.0 : tN / tD);
  if abs(tN) < cSMALL_NUM then tc:=0
                          else tc:=tN/tD;

  // get the difference of the two closest points
  //Vector   dP = w + (sc * u) - (tc * v);  // = S0(sc) - S1(tc)

  SAClosest:=SA0+u*sc;
  SBClosest:=SB0+v*tc;
end;

function SegmentSegmentDistance(const SA0,SA1,SB0,SB1:TV3f):single;
var A,B:TV3f;
begin
  SegmentSegmentClosestPoint(SA0,SA1,SB0,SB1,A,B);
  result:=VDist(A,B);
end;


function RayCastTriangleIntersect(const rayStart,rayVector,p1,p2,p3:TV3f;out intersectPoint:TV3f):boolean;
var pvec,v1,v2,qvec,tvec:TV3f;
    t,u,v,det,invDet:Single;
begin
  v1:=p2-p1;
  v2:=p3-p1;
  pvec:=VCross(rayVector,v2);
  det:=VDot(v1,pvec);
  if(det<EPSILON2)and(det>-EPSILON2)then exit(false); // vector is parallel to triangle's plane
  invDet:=cOne/det;
  tvec:=rayStart-p1;
  u:=VDot(tvec,pvec)*invDet;
  if (u<0) or (u>1) then
    Result:=False
  else begin
    qvec:=VCross(tvec,v1);
    v:=VDot(rayVector,qvec)*invDet;
    Result:=(v>=0) and (u+v<=1);
    if Result then begin
      t:=VDot(v2,qvec)*invDet;
      if t>0 then begin
        intersectPoint:=rayStart+rayVector*t;
      end else Result:=False;
    end;
  end;
end;



function MTranspose(const a:TM44f):TM44f;var i,j:integer;
begin
  for i:=0 to high(a) do for j:=0 to high(a) do result[i,j]:=a[j,i];
end;

function MIsProjection(const a:TM44f):boolean;overload;
begin
  result:=(a[0,3]<>0)or(a[1,3]<>0)or(a[2,3]<>0)or(a[3,3]<>1);
end;

function MIsProjection(const a:TM44d):boolean;overload;
begin
  result:=(a[0,3]<>0)or(a[1,3]<>0)or(a[2,3]<>0)or(a[3,3]<>1);
end;

function MMultiply(const a,b:TM44f):TM44f;
begin
  result[0,0]:=a[0,0]*b[0,0]+a[0,1]*b[1,0]+a[0,2]*b[2,0]+a[0,3]*b[3,0];
  result[0,1]:=a[0,0]*b[0,1]+a[0,1]*b[1,1]+a[0,2]*b[2,1]+a[0,3]*b[3,1];
  result[0,2]:=a[0,0]*b[0,2]+a[0,1]*b[1,2]+a[0,2]*b[2,2]+a[0,3]*b[3,2];
  result[0,3]:=a[0,0]*b[0,3]+a[0,1]*b[1,3]+a[0,2]*b[2,3]+a[0,3]*b[3,3];
  result[1,0]:=a[1,0]*b[0,0]+a[1,1]*b[1,0]+a[1,2]*b[2,0]+a[1,3]*b[3,0];
  result[1,1]:=a[1,0]*b[0,1]+a[1,1]*b[1,1]+a[1,2]*b[2,1]+a[1,3]*b[3,1];
  result[1,2]:=a[1,0]*b[0,2]+a[1,1]*b[1,2]+a[1,2]*b[2,2]+a[1,3]*b[3,2];
  result[1,3]:=a[1,0]*b[0,3]+a[1,1]*b[1,3]+a[1,2]*b[2,3]+a[1,3]*b[3,3];
  result[2,0]:=a[2,0]*b[0,0]+a[2,1]*b[1,0]+a[2,2]*b[2,0]+a[2,3]*b[3,0];
  result[2,1]:=a[2,0]*b[0,1]+a[2,1]*b[1,1]+a[2,2]*b[2,1]+a[2,3]*b[3,1];
  result[2,2]:=a[2,0]*b[0,2]+a[2,1]*b[1,2]+a[2,2]*b[2,2]+a[2,3]*b[3,2];
  result[2,3]:=a[2,0]*b[0,3]+a[2,1]*b[1,3]+a[2,2]*b[2,3]+a[2,3]*b[3,3];
  result[3,0]:=a[3,0]*b[0,0]+a[3,1]*b[1,0]+a[3,2]*b[2,0]+a[3,3]*b[3,0];
  result[3,1]:=a[3,0]*b[0,1]+a[3,1]*b[1,1]+a[3,2]*b[2,1]+a[3,3]*b[3,1];
  result[3,2]:=a[3,0]*b[0,2]+a[3,1]*b[1,2]+a[3,2]*b[2,2]+a[3,3]*b[3,2];
  result[3,3]:=a[3,0]*b[0,3]+a[3,1]*b[1,3]+a[3,2]*b[2,3]+a[3,3]*b[3,3];
end;

function MMultiply(const a,b:TM44d):TM44d;
begin
  result[0,0]:=a[0,0]*b[0,0]+a[0,1]*b[1,0]+a[0,2]*b[2,0]+a[0,3]*b[3,0];
  result[0,1]:=a[0,0]*b[0,1]+a[0,1]*b[1,1]+a[0,2]*b[2,1]+a[0,3]*b[3,1];
  result[0,2]:=a[0,0]*b[0,2]+a[0,1]*b[1,2]+a[0,2]*b[2,2]+a[0,3]*b[3,2];
  result[0,3]:=a[0,0]*b[0,3]+a[0,1]*b[1,3]+a[0,2]*b[2,3]+a[0,3]*b[3,3];
  result[1,0]:=a[1,0]*b[0,0]+a[1,1]*b[1,0]+a[1,2]*b[2,0]+a[1,3]*b[3,0];
  result[1,1]:=a[1,0]*b[0,1]+a[1,1]*b[1,1]+a[1,2]*b[2,1]+a[1,3]*b[3,1];
  result[1,2]:=a[1,0]*b[0,2]+a[1,1]*b[1,2]+a[1,2]*b[2,2]+a[1,3]*b[3,2];
  result[1,3]:=a[1,0]*b[0,3]+a[1,1]*b[1,3]+a[1,2]*b[2,3]+a[1,3]*b[3,3];
  result[2,0]:=a[2,0]*b[0,0]+a[2,1]*b[1,0]+a[2,2]*b[2,0]+a[2,3]*b[3,0];
  result[2,1]:=a[2,0]*b[0,1]+a[2,1]*b[1,1]+a[2,2]*b[2,1]+a[2,3]*b[3,1];
  result[2,2]:=a[2,0]*b[0,2]+a[2,1]*b[1,2]+a[2,2]*b[2,2]+a[2,3]*b[3,2];
  result[2,3]:=a[2,0]*b[0,3]+a[2,1]*b[1,3]+a[2,2]*b[2,3]+a[2,3]*b[3,3];
  result[3,0]:=a[3,0]*b[0,0]+a[3,1]*b[1,0]+a[3,2]*b[2,0]+a[3,3]*b[3,0];
  result[3,1]:=a[3,0]*b[0,1]+a[3,1]*b[1,1]+a[3,2]*b[2,1]+a[3,3]*b[3,1];
  result[3,2]:=a[3,0]*b[0,2]+a[3,1]*b[1,2]+a[3,2]*b[2,2]+a[3,3]*b[3,2];
  result[3,3]:=a[3,0]*b[0,3]+a[3,1]*b[1,3]+a[3,2]*b[2,3]+a[3,3]*b[3,3];
end;

function MMultiply(const a,b,c:TM44f):TM44f;
begin
  result:=MMultiply(MMultiply(a,b),c);
end;

function MMultiply(const a,b,c,d:TM44f):TM44f;
begin
  result:=MMultiply(MMultiply(a,b,c),d);
end;

function MMultiply(const a,b,c,d,e:TM44f):TM44f;
begin
  result:=MMultiply(MMultiply(a,b,c,d),e);
end;

function MMultiply(const a,b,c,d,e,f:TM44f):TM44f;
begin
  result:=MMultiply(MMultiply(a,b,c,d,e),f);
end;

procedure MMultiply(var a:TM44f;const b:single);overload;
var i,j:integer;
begin
  for i:=0 to high(a)do for j:=0 to high(a[i])do a[i,j]:=a[i,j]*b;
end;


function det3(const a1,a2,a3,b1,b2,b3,c1,c2,c3:single):Single;overload;
begin
  result:= a1*(b2*c3-b3*c2)
          -b1*(a2*c3-a3*c2)
          +c1*(a2*b3-a3*b2);
end;

function det3(const a1,a2,a3,b1,b2,b3,c1,c2,c3:double):double;overload;
begin
  result:= a1*(b2*c3-b3*c2)
          -b1*(a2*c3-a3*c2)
          +c1*(a2*b3-a3*b2);
end;

function MDeterminant(const a:TM44f):Single;overload;
begin
  Result:= a[0,0]*det3(a[1,1],a[2,1],a[3,1],a[1,2],a[2,2],a[3,2],a[1,3],a[2,3],a[3,3])
          -a[0,1]*det3(a[1,0],a[2,0],a[3,0],a[1,2],a[2,2],a[3,2],a[1,3],a[2,3],a[3,3])
          +a[0,2]*det3(a[1,0],a[2,0],a[3,0],a[1,1],a[2,1],a[3,1],a[1,3],a[2,3],a[3,3])
          -a[0,3]*det3(a[1,0],a[2,0],a[3,0],a[1,1],a[2,1],a[3,1],a[1,2],a[2,2],a[3,2]);
end;

function MDeterminant(const a:TM44d):double;overload;
begin
  Result:= a[0,0]*det3(a[1,1],a[2,1],a[3,1],a[1,2],a[2,2],a[3,2],a[1,3],a[2,3],a[3,3])
          -a[0,1]*det3(a[1,0],a[2,0],a[3,0],a[1,2],a[2,2],a[3,2],a[1,3],a[2,3],a[3,3])
          +a[0,2]*det3(a[1,0],a[2,0],a[3,0],a[1,1],a[2,1],a[3,1],a[1,3],a[2,3],a[3,3])
          -a[0,3]*det3(a[1,0],a[2,0],a[3,0],a[1,1],a[2,1],a[3,1],a[1,2],a[2,2],a[3,2]);
end;

function MInverse(const a:TM44f):TM44f;
var d:single;
begin
  d:=1/MDeterminant(a);

{  result[0,0]:= det3(a[1,1],a[1,2],a[1,3],a[2,1],a[2,2],a[2,3],a[3,1],a[3,2],a[3,3])*d;
  result[1,0]:=-det3(a[0,1],a[0,2],a[0,3],a[2,1],a[2,2],a[2,3],a[3,1],a[3,2],a[3,3])*d;
  result[2,0]:= det3(a[0,1],a[0,2],a[0,3],a[1,1],a[1,2],a[1,3],a[3,1],a[3,2],a[3,3])*d;
  result[3,0]:=-det3(a[0,1],a[0,2],a[0,3],a[1,1],a[1,2],a[1,3],a[2,1],a[2,2],a[2,3])*d;

  result[0,1]:=-det3(a[1,0],a[1,2],a[1,3],a[2,0],a[2,2],a[2,3],a[3,0],a[3,2],a[3,3])*d;
  result[1,1]:= det3(a[0,0],a[0,2],a[0,3],a[2,0],a[2,2],a[2,3],a[3,0],a[3,2],a[3,3])*d;
  result[2,1]:=-det3(a[0,0],a[0,2],a[0,3],a[1,0],a[1,2],a[1,3],a[3,0],a[3,2],a[3,3])*d;
  result[3,1]:= det3(a[0,0],a[0,2],a[0,3],a[1,0],a[1,2],a[1,3],a[2,0],a[2,2],a[2,3])*d;

  result[0,2]:= det3(a[1,0],a[1,1],a[1,3],a[2,0],a[2,1],a[2,3],a[3,0],a[3,1],a[3,3])*d;
  result[1,2]:=-det3(a[0,0],a[0,1],a[0,3],a[2,0],a[2,1],a[2,3],a[3,0],a[3,1],a[3,3])*d;
  result[2,2]:= det3(a[0,0],a[0,1],a[0,3],a[1,0],a[1,1],a[1,3],a[3,0],a[3,1],a[3,3])*d;
  result[3,2]:=-det3(a[0,0],a[0,1],a[0,3],a[1,0],a[1,1],a[1,3],a[2,0],a[2,1],a[2,3])*d;

  result[0,3]:=-det3(a[1,0],a[1,1],a[1,2],a[2,0],a[2,1],a[2,2],a[3,0],a[3,1],a[3,2])*d;
  result[1,3]:= det3(a[0,0],a[0,1],a[0,2],a[2,0],a[2,1],a[2,2],a[3,0],a[3,1],a[3,2])*d;
  result[2,3]:=-det3(a[0,0],a[0,1],a[0,2],a[1,0],a[1,1],a[1,2],a[3,0],a[3,1],a[3,2])*d;
  result[3,3]:= det3(a[0,0],a[0,1],a[0,2],a[1,0],a[1,1],a[1,2],a[2,0],a[2,1],a[2,2])*d;  //ez fel volt cserelve}

  result[0,0]:= det3(a[1,1],a[1,2],a[1,3],a[2,1],a[2,2],a[2,3],a[3,1],a[3,2],a[3,3])*d;
  result[0,1]:=-det3(a[0,1],a[0,2],a[0,3],a[2,1],a[2,2],a[2,3],a[3,1],a[3,2],a[3,3])*d;
  result[0,2]:= det3(a[0,1],a[0,2],a[0,3],a[1,1],a[1,2],a[1,3],a[3,1],a[3,2],a[3,3])*d;
  result[0,3]:=-det3(a[0,1],a[0,2],a[0,3],a[1,1],a[1,2],a[1,3],a[2,1],a[2,2],a[2,3])*d;

  result[1,0]:=-det3(a[1,0],a[1,2],a[1,3],a[2,0],a[2,2],a[2,3],a[3,0],a[3,2],a[3,3])*d;
  result[1,1]:= det3(a[0,0],a[0,2],a[0,3],a[2,0],a[2,2],a[2,3],a[3,0],a[3,2],a[3,3])*d;
  result[1,2]:=-det3(a[0,0],a[0,2],a[0,3],a[1,0],a[1,2],a[1,3],a[3,0],a[3,2],a[3,3])*d;
  result[1,3]:= det3(a[0,0],a[0,2],a[0,3],a[1,0],a[1,2],a[1,3],a[2,0],a[2,2],a[2,3])*d;

  result[2,0]:= det3(a[1,0],a[1,1],a[1,3],a[2,0],a[2,1],a[2,3],a[3,0],a[3,1],a[3,3])*d;
  result[2,1]:=-det3(a[0,0],a[0,1],a[0,3],a[2,0],a[2,1],a[2,3],a[3,0],a[3,1],a[3,3])*d;
  result[2,2]:= det3(a[0,0],a[0,1],a[0,3],a[1,0],a[1,1],a[1,3],a[3,0],a[3,1],a[3,3])*d;
  result[2,3]:=-det3(a[0,0],a[0,1],a[0,3],a[1,0],a[1,1],a[1,3],a[2,0],a[2,1],a[2,3])*d;

  result[3,0]:=-det3(a[1,0],a[1,1],a[1,2],a[2,0],a[2,1],a[2,2],a[3,0],a[3,1],a[3,2])*d;
  result[3,1]:= det3(a[0,0],a[0,1],a[0,2],a[2,0],a[2,1],a[2,2],a[3,0],a[3,1],a[3,2])*d;
  result[3,2]:=-det3(a[0,0],a[0,1],a[0,2],a[1,0],a[1,1],a[1,2],a[3,0],a[3,1],a[3,2])*d;
  result[3,3]:= det3(a[0,0],a[0,1],a[0,2],a[1,0],a[1,1],a[1,2],a[2,0],a[2,1],a[2,2])*d;

end;

{function MInverse(const a:TM44d):TM44d;
var d:double;
begin
  d:=1/MDeterminant(a);

  result[0,0]:= det3(a[1,1],a[1,2],a[1,3],a[2,1],a[2,2],a[2,3],a[3,1],a[3,2],a[3,3])*d;
  result[1,0]:=-det3(a[0,1],a[0,2],a[0,3],a[2,1],a[2,2],a[2,3],a[3,1],a[3,2],a[3,3])*d;
  result[2,0]:= det3(a[0,1],a[0,2],a[0,3],a[1,1],a[1,2],a[1,3],a[3,1],a[3,2],a[3,3])*d;
  result[3,0]:=-det3(a[0,1],a[0,2],a[0,3],a[1,1],a[1,2],a[1,3],a[2,1],a[2,2],a[2,3])*d;

  result[0,1]:=-det3(a[1,0],a[1,2],a[1,3],a[2,0],a[2,2],a[2,3],a[3,0],a[3,2],a[3,3])*d;
  result[1,1]:= det3(a[0,0],a[0,2],a[0,3],a[2,0],a[2,2],a[2,3],a[3,0],a[3,2],a[3,3])*d;
  result[2,1]:=-det3(a[0,0],a[0,2],a[0,3],a[1,0],a[1,2],a[1,3],a[3,0],a[3,2],a[3,3])*d;
  result[3,1]:= det3(a[0,0],a[0,2],a[0,3],a[1,0],a[1,2],a[1,3],a[2,0],a[2,2],a[2,3])*d;

  result[0,2]:= det3(a[1,0],a[1,1],a[1,3],a[2,0],a[2,1],a[2,3],a[3,0],a[3,1],a[3,3])*d;
  result[1,2]:=-det3(a[0,0],a[0,1],a[0,3],a[2,0],a[2,1],a[2,3],a[3,0],a[3,1],a[3,3])*d;
  result[2,2]:= det3(a[0,0],a[0,1],a[0,3],a[1,0],a[1,1],a[1,3],a[3,0],a[3,1],a[3,3])*d;
  result[3,2]:=-det3(a[0,0],a[0,1],a[0,3],a[1,0],a[1,1],a[1,3],a[2,0],a[2,1],a[2,3])*d;

  result[0,3]:=-det3(a[1,0],a[1,1],a[1,2],a[2,0],a[2,1],a[2,2],a[3,0],a[3,1],a[3,2])*d;
  result[1,3]:= det3(a[0,0],a[0,1],a[0,2],a[2,0],a[2,1],a[2,2],a[3,0],a[3,1],a[3,2])*d;
  result[2,3]:=-det3(a[0,0],a[0,1],a[0,2],a[1,0],a[1,1],a[1,2],a[3,0],a[3,1],a[3,2])*d;
  result[3,3]:= det3(a[0,0],a[0,1],a[0,2],a[1,0],a[1,1],a[1,2],a[2,0],a[2,1],a[2,2])*d;
end;}

procedure AdjointMatrix(var M : TM44d);
  function MatrixDetInternal(const a1, a2, a3, b1, b2, b3, c1, c2, c3: double): double;
  begin
    Result:=  a1 * (b2 * c3 - b3 * c2)
            - b1 * (a2 * c3 - a3 * c2)
            + c1 * (a2 * b3 - a3 * b2);
  end;
const x=0;y=1;z=2;w=3;
var
   a1, a2, a3, a4,
   b1, b2, b3, b4,
   c1, c2, c3, c4,
   d1, d2, d3, d4: double;
begin
    a1:= M[X, X]; b1:= M[X, Y];
    c1:= M[X, Z]; d1:= M[X, W];
    a2:= M[Y, X]; b2:= M[Y, Y];
    c2:= M[Y, Z]; d2:= M[Y, W];
    a3:= M[Z, X]; b3:= M[Z, Y];
    c3:= M[Z, Z]; d3:= M[Z, W];
    a4:= M[W, X]; b4:= M[W, Y];
    c4:= M[W, Z]; d4:= M[W, W];

    // row column labeling reversed since we transpose rows & columns
    M[X, X]:= MatrixDetInternal(b2, b3, b4, c2, c3, c4, d2, d3, d4);
    M[Y, X]:=-MatrixDetInternal(a2, a3, a4, c2, c3, c4, d2, d3, d4);
    M[Z, X]:= MatrixDetInternal(a2, a3, a4, b2, b3, b4, d2, d3, d4);
    M[W, X]:=-MatrixDetInternal(a2, a3, a4, b2, b3, b4, c2, c3, c4);

    M[X, Y]:=-MatrixDetInternal(b1, b3, b4, c1, c3, c4, d1, d3, d4);
    M[Y, Y]:= MatrixDetInternal(a1, a3, a4, c1, c3, c4, d1, d3, d4);
    M[Z, Y]:=-MatrixDetInternal(a1, a3, a4, b1, b3, b4, d1, d3, d4);
    M[W, Y]:= MatrixDetInternal(a1, a3, a4, b1, b3, b4, c1, c3, c4);

    M[X, Z]:= MatrixDetInternal(b1, b2, b4, c1, c2, c4, d1, d2, d4);
    M[Y, Z]:=-MatrixDetInternal(a1, a2, a4, c1, c2, c4, d1, d2, d4);
    M[Z, Z]:= MatrixDetInternal(a1, a2, a4, b1, b2, b4, d1, d2, d4);
    M[W, Z]:=-MatrixDetInternal(a1, a2, a4, b1, b2, b4, c1, c2, c4);

    M[X, W]:=-MatrixDetInternal(b1, b2, b3, c1, c2, c3, d1, d2, d3);
    M[Y, W]:= MatrixDetInternal(a1, a2, a3, c1, c2, c3, d1, d2, d3);
    M[Z, W]:=-MatrixDetInternal(a1, a2, a3, b1, b2, b3, d1, d2, d3);
    M[W, W]:= MatrixDetInternal(a1, a2, a3, b1, b2, b3, c1, c2, c3);
end;

function MInverse(const a:TM44d):TM44d;
var d:double;
    i,j:integer;
begin
  result:=a;
  d:=1/MDeterminant(result);
  AdjointMatrix(result);
  for i:=0 to 3 do for j:=0 to 3 do result[i,j]:=result[i,j]*d;
end;


function MNormalize(const a:TM44f):TM44f;
var r:array[0..2]of TV3f;
begin
  r[0]:=VNormalize(V3f(a[0,0],a[0,1],a[0,2]));
  r[1]:=VNormalize(V3f(a[1,0],a[1,1],a[1,2]));
  r[2]:=VCross(r[0],r[1]);
  r[0]:=VCross(r[1],r[2]);

  MSetRow(Result,0,r[0]);Result[0,3]:=0;
  MSetRow(Result,1,r[1]);Result[1,3]:=0;
  MSetRow(Result,2,r[2]);Result[2,3]:=0;
  result[3,0]:=a[3,0];
  result[3,1]:=a[3,1];
  result[3,2]:=a[3,2];
  result[3,3]:=1;
end;

function VTransform(const m:TM44f;const v:TV3f):TV3f;
var v3:single;
begin
  if MIsProjection(m)then begin
    result.x :=v.x *m[0,0]+v.y *m[1,0]+v.z *m[2,0]+m[3,0];
    result.y :=v.x *m[0,1]+v.y *m[1,1]+v.z *m[2,1]+m[3,1];
    result.z :=v.x *m[0,2]+v.y *m[1,2]+v.z *m[2,2]+m[3,2];
    v3:=         v.x *m[0,3]+v.y *m[1,3]+v.z *m[2,3]+m[3,3];
    if v3<>1 then Result:=Result/v3;
  end else begin
    result.x :=v.x *m[0,0]+v.y *m[1,0]+v.z *m[2,0]+m[3,0];
    result.y :=v.x *m[0,1]+v.y *m[1,1]+v.z *m[2,1]+m[3,1];
    result.z :=v.x *m[0,2]+v.y *m[1,2]+v.z *m[2,2]+m[3,2];
  end;
end;

function VTransformNoProj(const m:TM44f;const v:TV3f):TV3f;
begin
  result.x :=v.x *m[0,0]+v.y *m[1,0]+v.z *m[2,0]+m[3,0];
  result.y :=v.x *m[0,1]+v.y *m[1,1]+v.z *m[2,1]+m[3,1];
  result.z :=v.x *m[0,2]+v.y *m[1,2]+v.z *m[2,2]+m[3,2];
end;

function VTransformNormal(const m:TM44f;const v:TV3f):TV3f;
begin
  result.x :=v.x *m[0,0]+v.y *m[1,0]+v.z *m[2,0];
  result.y :=v.x *m[0,1]+v.y *m[1,1]+v.z *m[2,1];
  result.z :=v.x *m[0,2]+v.y *m[1,2]+v.z *m[2,2];
end;

function VTransform(const m:TM44d;const v:TV3d):TV3d;
//var v3:double;
begin
  if MIsProjection(m)then begin
    result.x :=v.x *m[0,0]+v.y *m[1,0]+v.z *m[2,0]+m[3,0];
    result.y :=v.x *m[0,1]+v.y *m[1,1]+v.z *m[2,1]+m[3,1];
    result.z :=v.x *m[0,2]+v.y *m[1,2]+v.z *m[2,2]+m[3,2];
//    v3:=         v.x *m[0,3]+v.y *m[1,3]+v.z *m[2,3]+m[3,3];
//    if v3<>1 then Result:=Result/v3;  <- FASZSaaaaag!!!!
  end else begin
    result.x :=v.x *m[0,0]+v.y *m[1,0]+v.z *m[2,0]+m[3,0];
    result.y :=v.x *m[0,1]+v.y *m[1,1]+v.z *m[2,1]+m[3,1];
    result.z :=v.x *m[0,2]+v.y *m[1,2]+v.z *m[2,2]+m[3,2];
  end;
end;

function VTransform(const m:TM44f;const v:TV2f):TV2f;
begin
  result.x :=v.x *m[0,0]+v.y *m[1,0]+m[3,0];
  result.y :=v.x *m[0,1]+v.y *m[1,1]+m[3,1];
end;

function MTranslation(const x,y,z:single):TM44f;overload;
begin
  Result:=M44fIdentity;
  Result[3,0]:=x;
  Result[3,1]:=y;
  Result[3,2]:=z;
end;

function MTranslation(const v:TV3f):TM44f;overload;
begin
  Result:=M44fIdentity;
  Result[3,0]:=v.x ;
  Result[3,1]:=v.y ;
  Result[3,2]:=v.z ;
end;

function MTranslationD(const v:TV3d):TM44d;overload;
begin
  Result:=M44dIdentity;
  Result[3,0]:=v.x ;
  Result[3,1]:=v.y ;
  Result[3,2]:=v.z ;
end;

function MTranslation(const v:TV2f):TM44f;overload;
begin
  Result:=M44fIdentity;
  Result[3,0]:=v.x ;
  Result[3,1]:=v.y ;
end;

function MScaling(const s:single):TM44f;overload;
begin
  Result[0,0]:=s;Result[0,1]:=0;Result[0,2]:=0;Result[0,3]:=0;
  Result[1,0]:=0;Result[1,1]:=s;Result[1,2]:=0;Result[1,3]:=0;
  Result[2,0]:=0;Result[2,1]:=0;Result[2,2]:=s;Result[2,3]:=0;
  Result[3,0]:=0;Result[3,1]:=0;Result[3,2]:=0;Result[3,3]:=1;
end;

function MScalingD(const s:double):TM44d;overload;
begin
  Result[0,0]:=s;Result[0,1]:=0;Result[0,2]:=0;Result[0,3]:=0;
  Result[1,0]:=0;Result[1,1]:=s;Result[1,2]:=0;Result[1,3]:=0;
  Result[2,0]:=0;Result[2,1]:=0;Result[2,2]:=s;Result[2,3]:=0;
  Result[3,0]:=0;Result[3,1]:=0;Result[3,2]:=0;Result[3,3]:=1;
end;

function MScaling(const x,y,z:single):TM44f;overload;
begin
  Result[0,0]:=x;Result[0,1]:=0;Result[0,2]:=0;Result[0,3]:=0;
  Result[1,0]:=0;Result[1,1]:=y;Result[1,2]:=0;Result[1,3]:=0;
  Result[2,0]:=0;Result[2,1]:=0;Result[2,2]:=z;Result[2,3]:=0;
  Result[3,0]:=0;Result[3,1]:=0;Result[3,2]:=0;Result[3,3]:=1;
end;

function MScaling(const v:TV2f):TM44f;overload;
begin
  Result[0,0]:=v.x ;Result[0,1]:=0;Result[0,2]:=0;Result[0,3]:=0;
  Result[1,0]:=0;Result[1,1]:=v.y ;Result[1,2]:=0;Result[1,3]:=0;
  Result[2,0]:=0;Result[2,1]:=0;Result[2,2]:=1;Result[2,3]:=0;
  Result[3,0]:=0;Result[3,1]:=0;Result[3,2]:=0;Result[3,3]:=1;
end;
function MScaling(const v:TV3f):TM44f;overload;
begin
  Result[0,0]:=v.x ;Result[0,1]:=0;Result[0,2]:=0;Result[0,3]:=0;
  Result[1,0]:=0;Result[1,1]:=v.y ;Result[1,2]:=0;Result[1,3]:=0;
  Result[2,0]:=0;Result[2,1]:=0;Result[2,2]:=v.z ;Result[2,3]:=0;
  Result[3,0]:=0;Result[3,1]:=0;Result[3,2]:=0;Result[3,3]:=1;
end;

function MRotationZ(const angle:single):TM44f;overload;
var s,c:single;
begin
  Result:=M44fIdentity;
  if angle=0 then exit;
  SinCos(angle,s,c);
  result[0,0]:=c;  result[0,1]:=s;
  result[1,0]:=-s; result[1,1]:=c;
end;

function MRotationY(const angle:single):TM44f;overload;
var s,c:single;
begin
  Result:=M44fIdentity;
  if angle=0 then exit;
  SinCos(angle,s,c);
  result[0,0]:=c;  result[0,2]:=s;
  result[2,0]:=-s; result[2,2]:=c;
end;

function MRotationX(const angle:single):TM44f;overload;
var s,c:single;
begin
  Result:=M44fIdentity;
  if angle=0 then exit;
  SinCos(angle,s,c);
  result[1,1]:=c;  result[1,2]:=s;
  result[2,1]:=-s; result[2,2]:=c;
end;

function MRotation(const EulerOrder:TEulerOrder;const a,b,c:Double):TM44f;

  procedure Mul(const n:integer;const angle:Double);
  begin
    if angle=0 then exit;
    case n of
      0:Result:=MMultiply(result,MRotationX(angle));
      1:Result:=MMultiply(result,MRotationY(angle));
      2:Result:=MMultiply(result,MRotationZ(angle));
    end;
  end;

begin
  Result:=M44fIdentity;
  case EulerOrder of
    XYZ:begin Mul(0,a);Mul(1,b);Mul(2,c);end;
    XZY:begin Mul(0,a);Mul(2,b);Mul(1,c);end;
    YXZ:begin Mul(1,a);Mul(0,b);Mul(2,c);end;
    YZX:begin Mul(1,a);Mul(2,b);Mul(0,c);end;
    ZXY:begin Mul(2,a);Mul(0,b);Mul(1,c);end;
    ZYX:begin Mul(2,a);Mul(1,b);Mul(0,c);end;
  end;
end;

function MRotation(const EulerOrder:TEulerOrder;const v:TV3d):TM44f;
begin
  result:=MRotation(EulerOrder,v.x,v.y,v.z);
end;

function MRotation(const axis: TV3f;const angle:double):TM44f;
var c,s,one_minus_c:{Single}double;
    a:TV3f;
begin
  SinCos(angle,s,c);
  one_minus_c:=1-c;
  a:=VNormalize(axis);
  result[0,0]:=(one_minus_c*sqr(a.x ))+c;
  result[0,1]:=(one_minus_c*a.x *a.y )-(a.z *s);
  result[0,2]:=(one_minus_c*a.z *a.x )+(a.y *s);
  result[0,3]:=0;
  result[1,0]:=(one_minus_c*a.x *a.y )+(a.z *s);
  result[1,1]:=(one_minus_c*sqr(a.y ))+c;
  result[1,2]:=(one_minus_c*a.y *a.z )-(a.x *s);
  result[1,3]:=0;
  result[2,0]:=(one_minus_c*a.z *a.x )-(a.y *s);
  result[2,1]:=(one_minus_c*a.y *a.z )+(a.x *s);
  result[2,2]:=(one_minus_c*sqr(a.z ))+c;
  result[2,3]:=0;
  result[3,0]:=0;
  result[3,1]:=0;
  result[3,2]:=0;
  result[3,3]:=1;
end;

procedure MTranslate(var m:TM44f;const x,y,z:single);
begin
  m[3,0]:=m[3,0]+x;
  m[3,1]:=m[3,1]+y;
  m[3,2]:=m[3,2]+z;
end;

procedure MTranslate(var m:TM44f;const v:TV3f);
begin
  m[3,0]:=m[3,0]+v.x ;
  m[3,1]:=m[3,1]+v.y ;
  m[3,2]:=m[3,2]+v.z ;
end;

procedure MTranslate(var m:TM44d;const v:TV3d);
begin
  m:=MMultiply(m,MTranslationD(v));
end;

procedure MTranslate(var m:TM44f;const v:TV2f);
begin
  m[3,0]:=m[3,0]+v.x ;
  m[3,1]:=m[3,1]+v.y ;
end;

procedure MScale(var m:TM44f;const s:single);
begin
  m[0,0]:=m[0,0]*s;m[0,1]:=m[0,1]*s;m[0,2]:=m[0,2]*s;
  m[1,0]:=m[1,0]*s;m[1,1]:=m[1,1]*s;m[1,2]:=m[1,2]*s;
  m[2,0]:=m[2,0]*s;m[2,1]:=m[2,1]*s;m[2,2]:=m[2,2]*s;
end;

procedure MScale(var m:TM44d;const s:double);
begin
{ m[0,0]:=m[0,0]*s;m[0,1]:=m[0,1]*s;m[0,2]:=m[0,2]*s;
  m[1,0]:=m[1,0]*s;m[1,1]:=m[1,1]*s;m[1,2]:=m[1,2]*s;
  m[2,0]:=m[2,0]*s;m[2,1]:=m[2,1]*s;m[2,2]:=m[2,2]*s;}
  m:=MMultiply(m,MScalingD(s));
end;

procedure MScale(var m:TM44f;const x,y,z:single);
begin
  m[0,0]:=m[0,0]*x;m[0,1]:=m[0,1]*x;m[0,2]:=m[0,2]*x;
  m[1,0]:=m[1,0]*y;m[1,1]:=m[1,1]*y;m[1,2]:=m[1,2]*y;
  m[2,0]:=m[2,0]*z;m[2,1]:=m[2,1]*z;m[2,2]:=m[2,2]*z;
end;

procedure MScale(var m:TM44f;const v:TV2f);
begin
  m[0,0]:=m[0,0]*v.x ;m[0,1]:=m[0,1]*v.x ;m[0,2]:=m[0,2]*v.x ;
  m[1,0]:=m[1,0]*v.y ;m[1,1]:=m[1,1]*v.y ;m[1,2]:=m[1,2]*v.y ;
end;

procedure MScale(var m:TM44f;const v:TV3f);
begin
  m[0,0]:=m[0,0]*v.x ;m[0,1]:=m[0,1]*v.x ;m[0,2]:=m[0,2]*v.x ;
  m[1,0]:=m[1,0]*v.y ;m[1,1]:=m[1,1]*v.y ;m[1,2]:=m[1,2]*v.y ;
  m[2,0]:=m[2,0]*v.z ;m[2,1]:=m[2,1]*v.z ;m[2,2]:=m[2,2]*v.z ;
end;

procedure MRotateX(var m:TM44f;const angle:single);
begin m:=MMultiply(m,MRotationX(angle));end;

procedure MRotateY(var m:TM44f;const angle:single);
begin m:=MMultiply(m,MRotationY(angle));end;

procedure MRotateZ(var m:TM44f;const angle:single);
begin m:=MMultiply(m,MRotationZ(angle));end;

  procedure MRotateZ(var m:TM44d;const angle:double);
  begin m:=MMultiply(m,M44d(MRotationZ(angle)));end;

procedure MRotate(var m:TM44f;const Axis:TV3f;const angle:single);
begin m:=MMultiply(m,MRotation(Axis,angle));end;

procedure MRotate(var m:TM44f;const EulerOrder:TEulerOrder;const a,b,c:Single);
begin m:=MMultiply(m,MRotation(EulerOrder,a,b,c));end;

procedure MRotate(var m:TM44f;const q:TQuaternion);
begin m:=MMultiply(m,MRotation(q));end;

procedure MSetRow(var m:TM44f;const r:integer;const v:TV3f);
begin
  m[r,0]:=v.x ;m[r,1]:=v.y ;m[r,2]:=v.z ;
end;

procedure MSetCol(var m:TM44f;const c:integer;const v:TV3f);
begin
  m[0,c]:=v.x ;m[1,c]:=v.y ;m[2,c]:=v.z ;
end;

function MLookAt(const eye,target,up:TV3f):TM44f;
var dir,right,up2:TV3f;
begin
  result:=M44fIdentity;
  dir:=VNormalize(target-eye);
  right:=VNormalize(VCross(dir,up));
  up2:=VNormalize(VCross(right,dir));
  result:=M44fIdentity;
  MSetCol(Result,0,right);
  MSetCol(Result,1,up2);
  MSetCol(Result,2,-dir);
  result:=MMultiply(MTranslation(-eye),result);
end;//exactly same as gluLookAt

function MLookEuler(const target:TV3f;const dist:single;const order:TEulerOrder;const a,b,c:single):TM44f;
begin
  result:=MRotation(order,a,b,c);
  MTranslate(result,0,0,-dist);
end;

function QMagnitude(const q:TQuaternion):single;
begin
  with q do result:=sqrt(VLengthSqr(imag)+sqr(real));
end;

function QNormalize(const q:TQuaternion):TQuaternion;
var d:Single;
begin
  d:=VLengthSqr(q.imag)+sqr(q.real);
  if d<EPSILON2 then exit(QIdentity);
  if d<>1 then begin
    d:=1/sqrt(d);
    result.Imag:=result.Imag*d;
    result.Real:=result.Real*d;
  end else result:=q;
end;

function MaxFloat(const a,b:single):single;
begin if a>=b then result:=a else result:=b;end;

function Quaternion(const v1,v2:TV3f):TQuaternion;overload;
begin
  result.Imag:=VCross(v1,v2);
  result.Real:=Sqrt((VDot(V1,V2)+1)*0.5);
end;

function Quaternion(const m:TM44f):TQuaternion;overload;
var traceMat,s,invS:single;
begin
  traceMat:=1+m[0,0]+m[1,1]+m[2,2];
  if traceMat>EPSILON2 then begin
    s:=Sqrt(traceMat)*2;
    invS:=1/s;
    Result.Imag.x :=(m[1,2]-m[2,1])*invS;
    Result.Imag.y :=(m[2,0]-m[0,2])*invS;
    Result.Imag.z :=(m[0,1]-m[1,0])*invS;
    Result.Real   :=0.25*s;
  end else if (m[0,0]>m[1,1]) and (m[0,0]>m[2,2]) then begin  // Row 0:
    s:=Sqrt(MaxFloat(EPSILON2, 1+m[0,0]-m[1,1]-m[2,2]))*2;
    invS:=1/s;
    Result.Imag.x :=0.25*s;
    Result.Imag.y :=(m[0,1]+m[1,0])*invS;
    Result.Imag.z :=(m[2,0]+m[0,2])*invS;
    Result.Real   :=(m[1,2]-m[2,1])*invS;
  end else if (m[1,1]>m[2,2]) then begin  // Row 1:
    s:=Sqrt(MaxFloat(EPSILON2, 1+m[1,1]-m[0,0]-m[2,2]))*2;
    invS:=1/s;
    Result.Imag.x :=(m[0,1]+m[1,0])*invS;
    Result.Imag.y :=0.25*s;
    Result.Imag.z :=(m[1,2]+m[2,1])*invS;
    Result.Real   :=(m[2,0]-m[0,2])*invS;
  end else begin  // Row 2:
    s:=Sqrt(MaxFloat(EPSILON2, 1+m[2,2]-m[0,0]-m[1,1]))*2;
    invS:=1/s;
    Result.Imag.x :=(m[2,0]+m[0,2])*invS;
    Result.Imag.y :=(m[1,2]+m[2,1])*invS;
    Result.Imag.z :=0.25*s;
    Result.Real   :=(m[0,1]-m[1,0])*invS;
  end;
  result:=QNormalize(Result);
end;

function Quaternion(const axis:TV3f;const angle:single):TQuaternion;overload;
var s,c:single;
begin
  SinCos(angle*1.5,s,c);
  Result.Real:=c;
  Result.Imag:=axis*(s/VLength(axis));
end;

function MFromQuaternion(const q:TQuaternion):TM44f;
var w,x,y,z,xx,xy,xz,xw,yy,yz,yw,zz,zw:Single;
begin
  QNormalize(q);
  x:=q.imag.x ;
  y:=q.imag.y ;
  z:=q.imag.z ;
  w:=q.real;
  xx:=x*x;xy:=x*y;xz:=x*z;xw:=x*w;
  yy:=y*y;yz:=y*z;yw:=y*w;
  zz:=z*z;zw:=z*w;
  result[0,0]:=1-2*(yy+zz);
  result[1,0]:=  2*(xy-zw);
  result[2,0]:=  2*(xz+yw);
  result[0,1]:=  2*(xy+zw);
  result[1,1]:=1-2*(xx+zz);
  result[2,1]:=  2*(yz-xw);
  result[0,2]:=  2*(xz-yw);
  result[1,2]:=  2*(yz+xw);
  result[2,2]:=1-2*(xx+yy);

  result[0,3]:=0;result[3,0]:=0;
  result[1,3]:=0;result[3,1]:=0;
  result[2,3]:=0;result[3,2]:=0;
  result[3,3]:=1;
end;

function MRotation(const q:TQuaternion):TM44f;overload;
begin
  result:=MFromQuaternion(q);
end;

function Quaternion(const EulerOrder:TEulerOrder;const a,b,c:Single):TQuaternion;overload;
begin
  result:=Quaternion(MRotation(EulerOrder,a,b,c));
end;

class operator TQuaternion.Equal(a,b:TQuaternion):boolean;
begin
  result:=(a.Real=b.Real)and(a.Imag=b.Imag);
end;

class operator TQuaternion.NotEqual(a,b:TQuaternion):boolean;
begin
  result:=(a.Real<>b.Real)or(a.Imag<>b.Imag);
end;


function ArcCos(const x : Single): Single;
asm
      FLD   X
      FMUL  ST, ST
      FSUBR cOne
      FSQRT
      FLD   X
      FPATAN
end;

function QSLerp(const q1,q2:TQuaternion;const t:single):TQuaternion;
var to1:array[0..3]of Single;
    omega,cosom,sinom,scale0,scale1: single;
begin
   // calc cosine
   cosom:= q1.Imag.x *q2.Imag.x
          +q1.Imag.y *q2.Imag.y
          +q1.Imag.z *q2.Imag.z
	       +q1.Real   *q2.Real;
   // adjust signs (if necessary)
   if cosom<0 then begin
      cosom := -cosom;
      to1[0] := - q2.Imag.x ;
      to1[1] := - q2.Imag.y ;
      to1[2] := - q2.Imag.z ;
      to1[3] := - q2.Real;
   end else begin
      to1[0] := q2.Imag.x ;
      to1[1] := q2.Imag.y ;
      to1[2] := q2.Imag.z ;
      to1[3] := q2.Real;
   end;
   // calculate coefficients
   if ((1.0-cosom)>EPSILON2) then begin // standard case (slerp)
      omega:=ArcCos(cosom);
      sinom:=1/Sin(omega);
      scale0:=Sin((1.0-t)*omega)*sinom;
      scale1:=Sin(t*omega)*sinom;
   end else begin // "from" and "to" quaternions are very close
	          //  ... so we can do a linear interpolation
      scale0:=1.0-t;
      scale1:=t;
   end;
   // calculate final values
   Result.Imag.x  := scale0 * q1.Imag.x  + scale1 * to1[0];
   Result.Imag.y  := scale0 * q1.Imag.y  + scale1 * to1[1];
   Result.Imag.z  := scale0 * q1.Imag.z  + scale1 * to1[2];
   Result.Real := scale0 * q1.Real + scale1 * to1[3];
   result:=QNormalize(Result);
end;

function MSLerp(const m1,m2:TM44f;const t:single):TM44f;
begin
  result:=MFromQuaternion(QSLerp(Quaternion(m1),Quaternion(m2),t));
  result[3,0]:=m1[3,0]+t*(m2[3,0]-m1[3,0]);
  result[3,1]:=m1[3,1]+t*(m2[3,1]-m1[3,1]);
  result[3,2]:=m1[3,2]+t*(m2[3,2]-m1[3,2]);
end;

function MLerp(const m1,m2:TM44f;const t:single):TM44f;
var i,j:integer;
begin
  for i:=0 to high(m1)do for j:=0 to high(m1[i])do
    result[i,j]:=m1[i,j]+t*(m2[i,j]-m1[i,j]);
end;




////////////////////////////////////////////////////////////////////////////////
///  Color adjust

function MBrightness(const Brightness:single):TM44f;
begin
  if Brightness<>1 then result:=MScaling(Brightness)
                   else result:=M44fIdentity;
end;

function MContrast(const Contrast:single):TM44f;
begin
  if Contrast<>1 then begin
    result:=
      MMultiply(MTranslation(-0.5,-0.5,-0.5),
                MScaling(Contrast),
                MTranslation(0.5,0.5,0.5));
  end else
    result:=M44fIdentity;
end;

const
  MGrayScaleBGR:TM44f=( //30% of the red value, 59% of the green value, and 11% of the blue value
    (0.11,0.11,0.11,0),
    (0.59,0.59,0.59,0),
    (0.30,0.30,0.30,0),
    (0   ,0   ,0   ,1)
  );

const
  MGrayScaleRGB:TM44f=( //30% of the red value, 59% of the green value, and 11% of the blue value
    (0.30,0.30,0.30,0),
    (0.59,0.59,0.59,0),
    (0.11,0.11,0.11,0),
    (0   ,0   ,0   ,1)
  );

function MSaturation(const MGray:TM44f;const Saturation:single):TM44f;
begin
  if Saturation<>1 then result:=MLerp(MGray,M44fIdentity,Saturation)
                   else result:=M44fIdentity;
end;

function MHue(const Hue:Single):TM44f;
begin
  if HUE<>0 then result:=MRotation(V3f(1,1,1),Hue*pi)
            else result:=M44fIdentity;
end;

function MColorAdjust(const MGray:TM44f;const Brightness,Contrast,Saturation:single;const HUE:single=0):TM44f;
var first:boolean;
  procedure mul(const m:TM44f);
  begin
    if first then result:=m
             else result:=MMultiply(result,m);
    first:=false;
  end;
begin
  first:=true;
  if Saturation<>1    then mul(MSaturation(MGray,Saturation));
  if HUE<>0           then mul(MHue(HUE));
  if Contrast<>1      then mul(MContrast(Contrast));
  if Brightness<>1    then mul(MBrightness(Brightness));
  if first then result:=M44fIdentity;
end;

function MColorAdjustRGB(const Brightness,Contrast,Saturation:single;const HUE:single=0):TM44f;
begin
  result:=MColorAdjust(MGrayScaleRGB,Brightness,Contrast,Saturation,HUE);
end;

function MColorAdjustBGR(const Brightness,Contrast,Saturation:single;const HUE:single=0):TM44f;
begin
  result:=MColorAdjust(MGrayScaleBGR,Brightness,Contrast,Saturation,HUE);
end;

function safeRCP(const a:single):single;
begin
  if a<>0 then result:=1/a
          else result:=0;
end;

function MFrustum(const Left,Right,Bottom,Top,zNear,zFar:single):TM44f;
var RsubL,TsubB,FsubN:single;
begin
  RsubL:=safeRCP(Right-Left);
  TsubB:=safeRCP(Top-Bottom);
  FsubN:=safeRCP(zFar-zNear);

  result[0,0]:=(2*zNear)   *RsubL;
  result[1,0]:=0;
  result[2,0]:=(Right+Left)*RsubL;
  result[3,0]:=0;

  result[0,1]:=0;
  result[1,1]:=(2*zNear)   *TsubB;
  result[2,1]:=(Top+Bottom)*TsubB;
  result[3,1]:=0;

  result[0,2]:=0;
  result[1,2]:=0;
  result[2,2]:=-(zFar+zNear)  *FsubN;
  result[3,2]:=-(2*zFar*zNear)*FsubN;

  result[0,3]:=0;
  result[1,3]:=0;
  result[2,3]:=-1;
  result[3,3]:=0;
end;

function MProjection(const FOVy,Aspect,zNear,zFar:single):TM44f;
var ymin,ymax:single;
begin
  ymax:=zNear*tan(fovy*(pi/360));
  ymin:=-ymax;
  result:=MFrustum(ymin*aspect,ymax*aspect,ymin,ymax,zNear,zFar);
end;

function MOrtho(const Left,Right,Bottom,Top,zNear,zFar:single):TM44f;
var RsubL,TsubB,FsubN:single;
begin
  RsubL:=safeRCP(Right-Left);
  TsubB:=safeRCP(Top-Bottom);
  FsubN:=safeRCP(zFar-zNear);

  result[0,0]:=2            *RsubL;
  result[0,1]:=0;
  result[0,2]:=0;
  result[0,3]:=-(Right+Left)*RsubL;

  result[1,0]:=0;
  result[1,1]:=2            *TsubB;
  result[1,2]:=0;
  result[1,3]:=-(Top+Bottom)*TsubB;

  result[2,0]:=0;
  result[2,1]:=0;
  result[2,2]:=-2           *FsubN;
  result[2,3]:=-(zFar+zNear)*FsubN;

  result[3,0]:=0;
  result[3,1]:=0;
  result[3,2]:=0;
  result[3,3]:=1;
end;

function MOrtho(const YSize,Aspect,zNear,zFar:single):TM44f;
var ymin,ymax:single;
begin
  ymax:=YSize*0.5;
  ymin:=-ymax;
  result:=MOrtho(ymin*aspect,ymax*aspect,ymin,ymax,zNear,zFar);
end;

end.
