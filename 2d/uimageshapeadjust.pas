unit UImageShapeAdjust;//hello

interface

uses Windows, Sysutils, Classes, Controls, Graphics, Math, syncObjs,
  UVector, UMatrix, Het.Arrays, het.Utils;

type
  TImageShapeAdjustParams=array[0..40]of single;

  _TGridVertex=record p,t:TV2f;{0..1 minden}end;
  _PGridVertex=^_TGridVertex;

  TImageShapeAdjust=class(TComponent) //minden 0 based
  private
    FProjectorFOV:single;//kiveve ezt, mert ez 30fok alapbol
    FProjectorHeading:TV3f;{euler angles}
    FOffset:TV2f;
    FSize:TV2f;
    FBow:TV2f;
    FAsymmetricBow:TV2f;
    FFinetune:array[0..8]of TV3f;{sarkok, abbol jon a kozepe, meg az oldala}
    FResolution:integer;
    FDstAspect:single;
    FSrcAspect:single;
    function GetFinetune(i: integer): TV3f;
    procedure SetFinetune(i: integer; const Value: TV3f);
    procedure Changed;
    procedure SetAsymmetricBow0(const Value: single);
    procedure SetBow0(const Value: single);
    procedure SetBow1(const Value: single);
    procedure SetFineTune00(const Value: single);
    procedure SetFineTune01(const Value: single);
    procedure SetFineTune02(const Value: single);
    procedure SetFineTune10(const Value: single);
    procedure SetFineTune11(const Value: single);
    procedure SetFineTune12(const Value: single);
    procedure SetFineTune20(const Value: single);
    procedure SetFineTune21(const Value: single);
    procedure SetFineTune22(const Value: single);
    procedure SetFineTune30(const Value: single);
    procedure SetFineTune31(const Value: single);
    procedure SetFineTune32(const Value: single);
    procedure SetFineTune40(const Value: single);
    procedure SetFineTune41(const Value: single);
    procedure SetFineTune42(const Value: single);
    procedure SetFineTune50(const Value: single);
    procedure SetFineTune51(const Value: single);
    procedure SetFineTune52(const Value: single);
    procedure SetFineTune60(const Value: single);
    procedure SetFineTune61(const Value: single);
    procedure SetFineTune62(const Value: single);
    procedure SetFineTune70(const Value: single);
    procedure SetFineTune71(const Value: single);
    procedure SetFineTune72(const Value: single);
    procedure SetFineTune80(const Value: single);
    procedure SetFineTune81(const Value: single);
    procedure SetFineTune82(const Value: single);
    procedure SetOffset0(const Value: single);
    procedure SetOffset1(const Value: single);
    procedure SetProjectorFOV(const Value: single);
    procedure SetProjectorHeading0(const Value: single);
    procedure SetProjectorHeading1(const Value: single);
    procedure SetProjectorHeading2(const Value: single);
    procedure SetResolution(const Value: integer);
    procedure SetSize0(const Value: single);
    procedure SetSize1(const Value: single);
    procedure SetAsymmetricBow1(const Value: single);
    procedure SetDstAspect(const Value: single);
    procedure SetSrcAspect(const Value: single);
  private
    FUpVec,FRightVec:TV2f;
    function GetAsymmetricBow0: single;
    function GetAsymmetricBow1: single;
    function GetBow0: single;
    function GetBow1: single;
    function GetDstAspect: single;
    function GetFineTune00: single;
    function GetFineTune01: single;
    function GetFineTune02: single;
    function GetFineTune10: single;
    function GetFineTune11: single;
    function GetFineTune12: single;
    function GetFineTune20: single;
    function GetFineTune21: single;
    function GetFineTune22: single;
    function GetFineTune30: single;
    function GetFineTune31: single;
    function GetFineTune32: single;
    function GetFineTune40: single;
    function GetFineTune41: single;
    function GetFineTune42: single;
    function GetFineTune50: single;
    function GetFineTune51: single;
    function GetFineTune52: single;
    function GetFineTune60: single;
    function GetFineTune61: single;
    function GetFineTune62: single;
    function GetFineTune70: single;
    function GetFineTune71: single;
    function GetFineTune72: single;
    function GetFineTune80: single;
    function GetFineTune81: single;
    function GetFineTune82: single;
    function GetOffset0: single;
    function GetOffset1: single;
    function GetProjectorFOV: single;
    function GetProjectorHeading0: single;
    function GetProjectorHeading1: single;
    function GetProjectorHeading2: single;
    function GetSize0: single;
    function GetSize1: single;
    function GetSrcAspect: single;
    function GetResolution: integer;
  public
    Valid:boolean;
    ChangeIdx:integer;
    Grid:array of array of _TGridVertex;
    constructor Create(AOwner:TComponent);override;
    destructor Destroy;override;
    procedure Assign(src:TPersistent);override;
    procedure Reset;
    property FineTune[i:integer]:TV3f read GetFinetune write SetFinetune;
    procedure CalculateGrid;
    procedure CalculateGridIfNeeded;
    function GetProjectedControlPoint(i: integer): TV2f;
    function GetNearestProjectedControlPoint(ax,ay:single{0..1}):integer;
    procedure TransformBitmap32(src,dst:TBitmap);
    procedure CheckRanges;
    procedure Setup(const AHostControl:tcontrol;const formPos:tpoint);overload;
    procedure Setup(const AHostControl:tcontrol);overload;

    property RightVec:TV2f read FRightVec;

    property UpVec:TV2f read FUpVec;

    procedure UpdateIfNeeded;

    function GetParametersAsArray:TImageShapeAdjustParams;
    procedure SetParametersAsArray(const value:TImageShapeAdjustParams);
    procedure SetParametersAsArrayLerp(const value1,value2:TImageShapeAdjustParams;const t:single);
  published
    property DstAspect:single read GetDstAspect write SetDstAspect;
    property SrcAspect:single read GetSrcAspect write SetSrcAspect;
    property Resolution:integer read GetResolution write SetResolution;
    property ProjectorFOV:single read GetProjectorFOV write SetProjectorFOV;
    property ProjectorHeadingAlpha :single read GetProjectorHeading0 write SetProjectorHeading0;
    property ProjectorHeadingBeta  :single read GetProjectorHeading1 write SetProjectorHeading1;
    property ProjectorHeadingGamma :single read GetProjectorHeading2 write SetProjectorHeading2;
    property OffsetX:single read GetOffset0 write SetOffset0;
    property OffsetY:single read GetOffset1 write SetOffset1;
    property SizeX:single read GetSize0 write SetSize0;
    property SizeY:single read GetSize1 write SetSize1;
    property BowX:single read GetBow0 write SetBow0;
    property BowY:single read GetBow1 write SetBow1;
    property AsymmetricBowX:single read GetAsymmetricBow0 write SetAsymmetricBow0;
    property AsymmetricBowY:single read GetAsymmetricBow1 write SetAsymmetricBow1;
    property FineTune0X:single read GetFineTune00 write SetFineTune00;
    property FineTune0Y:single read GetFineTune01 write SetFineTune01;
    property FineTune0Z:single read GetFineTune02 write SetFineTune02;
    property FineTune1X:single read GetFineTune10 write SetFineTune10;
    property FineTune1Y:single read GetFineTune11 write SetFineTune11;
    property FineTune1Z:single read GetFineTune12 write SetFineTune12;
    property FineTune2X:single read GetFineTune20 write SetFineTune20;
    property FineTune2Y:single read GetFineTune21 write SetFineTune21;
    property FineTune2Z:single read GetFineTune22 write SetFineTune22;
    property FineTune3X:single read GetFineTune30 write SetFineTune30;
    property FineTune3Y:single read GetFineTune31 write SetFineTune31;
    property FineTune3Z:single read GetFineTune32 write SetFineTune32;
    property FineTune4X:single read GetFineTune40 write SetFineTune40;
    property FineTune4Y:single read GetFineTune41 write SetFineTune41;
    property FineTune4Z:single read GetFineTune42 write SetFineTune42;
    property FineTune5X:single read GetFineTune50 write SetFineTune50;
    property FineTune5Y:single read GetFineTune51 write SetFineTune51;
    property FineTune5Z:single read GetFineTune52 write SetFineTune52;
    property FineTune6X:single read GetFineTune60 write SetFineTune60;
    property FineTune6Y:single read GetFineTune61 write SetFineTune61;
    property FineTune6Z:single read GetFineTune62 write SetFineTune62;
    property FineTune7X:single read GetFineTune70 write SetFineTune70;
    property FineTune7Y:single read GetFineTune71 write SetFineTune71;
    property FineTune7Z:single read GetFineTune72 write SetFineTune72;
    property FineTune8X:single read GetFineTune80 write SetFineTune80;
    property FineTune8Y:single read GetFineTune81 write SetFineTune81;
    property FineTune8Z:single read GetFineTune82 write SetFineTune82;
  public
    FFade:single;

    function SaveToStr:rawbytestring;
    procedure LoadFromStr(const s:rawbytestring);
  end;

procedure Register;

implementation

uses UFrmImageShapeAdjust;

procedure Register;
begin
  RegisterComponents('HetGfx',[TImageShapeAdjust]);
end;

////////////////////////////////////////////////////////////////////////////////
// OPENGL TRANSFORMATION EMU                                                  //
////////////////////////////////////////////////////////////////////////////////

var ProjectionMatrix:TM44f;
  procedure _Perspective(fovy,aspect,znear,zfar:single);
  var f:single;
      m:TM44f;
  begin
    fillchar(m,sizeof(m),0);
    f:=cotan((fovy/180*pi)/2);
    m[0,0]:=f/aspect;
    m[1,1]:=f;
    m[2,2]:=(zfar+znear)/(znear-zfar);
    m[3,2]:=(2*zfar*znear)/(znear-zfar);
    m[2,3]:=-1;
    ProjectionMatrix:=m;
  end;

  procedure _translate(x,y,z:single);
  var m:TM44f;
  begin
    m:=M44fIdentity;
    m[3,0]:=x;
    m[3,1]:=y;
    m[3,2]:=z;
    ProjectionMatrix:=MMultiply(m,ProjectionMatrix);
  end;

  procedure _scale(x,y,z:single);
  var m:TM44f;
  begin
    m:=M44fIdentity;
    m[0,0]:=x;
    m[1,1]:=y;
    m[2,2]:=z;
    ProjectionMatrix:=MMultiply(m,ProjectionMatrix);
  end;

  procedure _rotate(angle,x,y,z:single);
  var m:TM44f;
  begin
    m:=MRotation(V3f(x,y,z),angle*pi/180);
    ProjectionMatrix:=MMultiply(m,ProjectionMatrix);
  end;

////////////////////////////////////////////////////////////////////////////////
// QUADFILLER                                                                 //
////////////////////////////////////////////////////////////////////////////////

const
  fixSh=16;
  fixsh8=fixSh-8;
  fixOne=1 shl fixSh;
  fixMask=fixOne-1;

type
  TYbufRec32=packed record
    x,tx,ty,dummy:integer;
  end;
  TYBuf=array[0..2047]of record left,right:TYbufRec32 end;
  PYbuf=^TYbuf;

function sar(a,b:integer):integer;
asm mov ecx,edx;sar eax,cl end;

procedure FillYBuf(var YBuf:TYBuf;x0,y0,tx0,ty0:integer;x1,y1,tx1,ty1:integer);
var y,ydabs,xd,txd,tyd:integer;
begin
  ydabs:=abs(y1-y0)+1;
  if y1>y0 then begin //lefele, left side side
    xd:=(x1-x0)div ydabs;
    txd:=(tx1-tx0)div ydabs;
    tyd:=(ty1-ty0)div ydabs;
    for y:=y0 to y1 do begin
      if(y>0)and(y<high(YBuf))then with YBuf[y].left do begin
        x:=x0;
        tx:=tx0;
        ty:=ty0;
      end;
      x0:=x0+xd;
      tx0:=tx0+txd;
      ty0:=ty0+tyd;
    end;
  end else begin //felfele, right side
    xd:=-(x1-x0)div ydabs;
    txd:=-(tx1-tx0)div ydabs;
    tyd:=-(ty1-ty0)div ydabs;
{    xd:=(x0-x1)div ydabs;
    txd:=(tx0-tx1)div ydabs;
    tyd:=(ty0-ty1)div ydabs;}
    for y:=y1 to y0 do begin
    //exact copy/////////////////////
      if(y>0)and(y<high(YBuf))then with YBuf[y].right do begin
        x:=x1;
        tx:=tx1;
        ty:=ty1;
      end;
      x1:=x1+xd;
      tx1:=tx1+txd;
      ty1:=ty1+tyd;
    //end of exact copy//////////////
    end;
  end;
end;

procedure SwapYBufRange(var YBuf:TYBuf;y0,y1:integer);
var tmp:TYbufRec32;
    y:integer;
begin
  if y1<y0 then begin
    y:=y0;y0:=y1;y1:=y;
  end;
  if y0<0 then y0:=0;
  if y1>high(YBuf)then y1:=high(YBuf);
  for y:=y0 to y1 do begin
    tmp:=           ybuf[y].left;
    ybuf[y].left:=  ybuf[y].right;
    ybuf[y].right:=  tmp;
  end;
end;

const
  _RBMask:array[0..3]of integer=($ff00ff,$ff00ff,$ff00ff,$ff00ff);
  _GMask:array[0..3]of integer=($ff00,$ff00,$ff00,$ff00);

procedure FillScanline32(var left,right:TYbufRec32;dst:pinteger;dstWidth:integer;texture:TBitmap);
var x,xd,xmin,xmax:integer;
    tx,ty,txadd,tyadd:integer;
    txx,tyy:integer;
    txf,tyf:integer;
    ptxt:pointer;
    txtw,txth:integer;
    txtw1,txth1:integer;
    p,lastp:pinteger;
    c,q:array[0..3]of cardinal;
begin
  asm
    movups xmm6,_RBMask
    movups xmm7,_GMask
  end;

  xmin:=left.x div fixOne;{sar!!!!!}
  xmax:=math.min(right.x div fixOne+1{bug miatt},dstWidth);{sar!!!!!}

  tx:=left.tx;
  ty:=left.ty;
  xd:=math.max((right.x-left.x)div fixOne,1);
  txadd:=(right.tx-tx)div xd;
  tyadd:=(right.ty-ty)div xd;
  inc(dst,xmin);
  txtw:=texture.Width;txtw1:=txtw-2;
  txth:=texture.Height;txth1:=txth-2;
  ptxt:=texture.ScanLine[txth-1];
  lastp:=nil;
  for x:=xmin to xmax-1 do begin
    if x>=0 then begin
      txf:=tx and fixMask shr 8;
      tyf:=ty and fixMask shr 8;
      txx:=(tx shr fixsh);
      tyy:=(ty shr fixsh);
      if txx>txtw1 then txx:=txtw1;
      if tyy>txth1 then tyy:=txth1;
      p:=pinteger(integer(ptxt)+(tyy*txtw+txx) shl 2);
{$DEFINE x86}
//ennek az algoritmusnak alapbol akkora a memoriamozgatasa, hogy az
//sse nem huz rajta szinte semmit, tehat hogy kompatibilisebb legyen,
//nyugodtan maradhat x86-on
{$IFDEF x86}
      if p<>lastp then begin
        lastp:=p;
        c[0]:=p^;inc(p);c[1]:=p^;
        inc(p,txtw-1);
        c[2]:=p^;inc(p);c[3]:=p^;
      end;

      q[0]:=(txf xor 255)*(tyf xor 255)shr 8;
      q[1]:=txf*(tyf xor 255) shr 8;
      q[2]:=(txf xor 255)*tyf shr 8;
      q[3]:=txf*tyf shr 8;
      dst^:=((c[0] and $ff00ff*q[0]+c[1] and $ff00ff*q[1]+c[2] and $ff00ff*q[2]+c[3] and $ff00ff*q[3])and $ff00ff00+
             (c[0] and $00ff00*q[0]+c[1] and $00ff00*q[1]+c[2] and $00ff00*q[2]+c[3] and $00ff00*q[3])and $00ff0000)shr 8;

{$ELSE}
      q[0]:=(txf xor $ff)*(tyf xor $ff);
      q[1]:=txf*(tyf xor $ff);
      q[2]:=(txf xor $ff)*tyf;
      q[3]:=txf*tyf;

      asm
        mov eax,p
        mov edx,txtw
        movlps xmm0,[eax]
        lea eax,eax+edx*4
        movhps xmm0,[eax] //xmm0 = c0..3
        movups xmm1,q
        movaps xmm2,xmm1
        pslld xmm2,16
        por xmm1,xmm2 //xmm1 = q0..3
        //red/blue
        movaps xmm3,xmm0
        pand xmm3,xmm6
        pmulhuw xmm3,xmm1
        pand xmm3,xmm6
        //green
        pand xmm0,xmm7
        pmulhuw xmm0,xmm1
        pand xmm0,xmm7
        por xmm0,xmm3

{        movups xmm1,xmm0
        shufps xmm0,xmm0,14
        paddd xmm0,xmm1}
        movups q,xmm0
       end;
      dst^:=q[0]+q[1]+q[2]+q[3];
{$ENDIF}
    end;
    tx:=tx+txadd;
    ty:=ty+tyadd;
    inc(dst);
  end;
  asm emms end;
end;

var lastX0,lastY0,lastTx0,lastTy0:integer;
    lastX1,lastY1,lastTx1,lastTy1:integer;
procedure FillQuadStrip(first:boolean;var YBuf:TYBuf;x0,y0,tx0,ty0:integer;x1,y1,tx1,ty1:integer;dst,texture:tbitmap);
var ymin,ymax,y:integer;
begin
  if not first then begin
    FillYBuf(YBuf,lastx0,lasty0,lasttx0,lastty0,lastx1,lasty1,lasttx1,lastty1);
    FillYBuf(YBuf,x1,y1,tx1,ty1,x0,y0,tx0,ty0);
    FillYBuf(YBuf,x0,y0,tx0,ty0,lastx0,lasty0,lasttx0,lastty0);
    FillYBuf(YBuf,lastx1,lasty1,lasttx1,lastty1,x1,y1,tx1,ty1);

    ymin:=math.max(math.min(math.min(y0,y1),math.min(lasty0,lasty1)),0);
    ymax:=math.min(math.max(math.max(y0,y1),math.max(lasty0,lasty1)),dst.Height-1);
    for y:=ymin to ymax do
      FillScanline32(ybuf[y].left,ybuf[y].right,dst.ScanLine[y],dst.Width,texture);
  end;
  lastX0:=x0;lastY0:=y0;lastTx0:=tx0;lastTy0:=ty0;
  lastX1:=x1;lastY1:=y1;lastTx1:=tx1;lastTy1:=ty1;
end;

procedure FillQuadStripF(first:boolean;var YBuf:TYBuf;x0,y0,tx0,ty0:single;x1,y1,tx1,ty1:single;dst,texture:tbitmap);
begin
  FillQuadStrip(first,YBuf,trunc(x0*fixOne),trunc(y0),trunc(tx0*fixOne),trunc(ty0*fixOne),
                           trunc(x1*fixOne),trunc(y1),trunc(tx1*fixOne),trunc(ty1*fixOne),
                           dst,texture);
end;

var defaultYBuf:TYBuf;

{ TImageShapeAdjust }

//dumb setters
procedure TImageShapeAdjust.SetAsymmetricBow0(const Value: single);
begin if FAsymmetricBow.x<>Value then begin FAsymmetricBow.x:=Value;Changed;end;end;
procedure TImageShapeAdjust.SetAsymmetricBow1(const Value: single);
begin if FAsymmetricBow.y<>Value then begin FAsymmetricBow.y:=Value;changed;end;end;
procedure TImageShapeAdjust.SetBow0(const Value: single);
begin if FBow.x<>Value then begin FBow.x:=Value;changed end;end;
procedure TImageShapeAdjust.SetBow1(const Value: single);
begin if FBow.y<>Value then begin FBow.y:=Value;changed end;end;
procedure TImageShapeAdjust.SetFineTune00(const Value: single);
begin if FFineTune[0].x<>Value then begin FFineTune[0].x:=Value;changed end;end;
procedure TImageShapeAdjust.SetFineTune01(const Value: single);
begin if FFineTune[0].y<>Value then begin FFineTune[0].y:=Value;changed end;end;
procedure TImageShapeAdjust.SetFineTune02(const Value: single);
begin if FFineTune[0].z<>Value then begin FFineTune[0].z:=Value;changed end;end;
procedure TImageShapeAdjust.SetFineTune10(const Value: single);
begin if FFineTune[1].x<>Value then begin FFineTune[1].x:=Value;changed end;end;
procedure TImageShapeAdjust.SetFineTune11(const Value: single);
begin if FFineTune[1].y<>Value then begin FFineTune[1].y:=Value;changed end;end;
procedure TImageShapeAdjust.SetFineTune12(const Value: single);
begin if FFineTune[1].z<>Value then begin FFineTune[1].z:=Value;changed end;end;
procedure TImageShapeAdjust.SetFineTune20(const Value: single);
begin if FFineTune[2].x<>Value then begin FFineTune[2].x:=Value;changed end;end;
procedure TImageShapeAdjust.SetFineTune21(const Value: single);
begin if FFineTune[2].y<>Value then begin FFineTune[2].y:=Value;changed end;end;
procedure TImageShapeAdjust.SetFineTune22(const Value: single);
begin if FFineTune[2].z<>Value then begin FFineTune[2].z:=Value;changed end;end;
procedure TImageShapeAdjust.SetFineTune30(const Value: single);
begin if FFineTune[3].x<>Value then begin FFineTune[3].x:=Value;changed end;end;
procedure TImageShapeAdjust.SetFineTune31(const Value: single);
begin if FFineTune[3].y<>Value then begin FFineTune[3].y:=Value;changed end;end;
procedure TImageShapeAdjust.SetFineTune32(const Value: single);
begin if FFineTune[3].z<>Value then begin FFineTune[3].z:=Value;changed end;end;
procedure TImageShapeAdjust.SetFineTune40(const Value: single);
begin if FFineTune[4].x<>Value then begin FFineTune[4].x:=Value;changed end;end;
procedure TImageShapeAdjust.SetFineTune41(const Value: single);
begin if FFineTune[4].y<>Value then begin FFineTune[4].y:=Value;changed end;end;
procedure TImageShapeAdjust.SetFineTune42(const Value: single);
begin if FFineTune[4].z<>Value then begin FFineTune[4].z:=Value;changed end;end;
procedure TImageShapeAdjust.SetFineTune50(const Value: single);
begin if FFineTune[5].x<>Value then begin FFineTune[5].x:=Value;changed end;end;
procedure TImageShapeAdjust.SetFineTune51(const Value: single);
begin if FFineTune[5].y<>Value then begin FFineTune[5].y:=Value;changed end;end;
procedure TImageShapeAdjust.SetFineTune52(const Value: single);
begin if FFineTune[5].z<>Value then begin FFineTune[5].z:=Value;changed end;end;
procedure TImageShapeAdjust.SetFineTune60(const Value: single);
begin if FFineTune[6].x<>Value then begin FFineTune[6].x:=Value;changed end;end;
procedure TImageShapeAdjust.SetFineTune61(const Value: single);
begin if FFineTune[6].y<>Value then begin FFineTune[6].y:=Value;changed end;end;
procedure TImageShapeAdjust.SetFineTune62(const Value: single);
begin if FFineTune[6].z<>Value then begin FFineTune[6].z:=Value;changed end;end;
procedure TImageShapeAdjust.SetFineTune70(const Value: single);
begin if FFineTune[7].x<>Value then begin FFineTune[7].x:=Value;changed end;end;
procedure TImageShapeAdjust.SetFineTune71(const Value: single);
begin if FFineTune[7].y<>Value then begin FFineTune[7].y:=Value;changed end;end;
procedure TImageShapeAdjust.SetFineTune72(const Value: single);
begin if FFineTune[7].z<>Value then begin FFineTune[7].z:=Value;changed end;end;
procedure TImageShapeAdjust.SetFineTune80(const Value: single);
begin if FFineTune[8].x<>Value then begin FFineTune[8].x:=Value;changed end;end;
procedure TImageShapeAdjust.SetFineTune81(const Value: single);
begin if FFineTune[8].y<>Value then begin FFineTune[8].y:=Value;changed end;end;
procedure TImageShapeAdjust.SetFineTune82(const Value: single);
begin if FFineTune[8].z<>Value then begin FFineTune[8].z:=Value;changed end;end;
procedure TImageShapeAdjust.SetOffset0(const Value: single);
begin if FOffset.x<>Value then begin FOffset.x:=Value;changed end;end;
procedure TImageShapeAdjust.SetOffset1(const Value: single);
begin if FOffset.y<>Value then begin FOffset.y:=Value;changed end;end;
procedure TImageShapeAdjust.SetProjectorFOV(const Value: single);
begin if FProjectorFOV<>Value then begin FProjectorFOV:=Value;changed end;end;
procedure TImageShapeAdjust.SetProjectorHeading0(const Value: single);
begin if FProjectorHeading.x<>Value then begin FProjectorHeading.x:=Value;changed end;end;
procedure TImageShapeAdjust.SetProjectorHeading1(const Value: single);
begin if FProjectorHeading.y<>Value then begin FProjectorHeading.y:=Value;changed end;end;
procedure TImageShapeAdjust.SetProjectorHeading2(const Value: single);
begin if FProjectorHeading.z<>Value then begin FProjectorHeading.z:=Value;changed end;end;
procedure TImageShapeAdjust.SetResolution(const Value: integer);
begin if FResolution<>Value then begin FResolution:=Value;changed end;end;
procedure TImageShapeAdjust.SetSize0(const Value: single);
begin if FSize.x<>Value then begin FSize.x:=Value;changed end;end;
procedure TImageShapeAdjust.SetSize1(const Value: single);
begin if FSize.y<>Value then begin FSize.y:=Value;changed end;end;
procedure TImageShapeAdjust.SetDstAspect(const Value: single);
begin if FDstAspect<>Value then begin FDstAspect:=Value;changed end;end;
procedure TImageShapeAdjust.SetSrcAspect(const Value: single);
begin if FSrcAspect<>Value then begin FSrcAspect:=Value;changed end;end;

//dumb getters
function TImageShapeAdjust.GetAsymmetricBow0:single;
begin result:=FAsymmetricBow.x end;
function TImageShapeAdjust.GetAsymmetricBow1:single;
begin result:=FAsymmetricBow.y end;
function TImageShapeAdjust.GetBow0:single;
begin result:=FBow.x end;
function TImageShapeAdjust.GetBow1:single;
begin result:=FBow.y end;
function TImageShapeAdjust.GetFineTune00:single;
begin result:=FFineTune[0].x end;
function TImageShapeAdjust.GetFineTune01:single;
begin result:=FFineTune[0].y end;
function TImageShapeAdjust.GetFineTune02:single;
begin result:=FFineTune[0].z end;
function TImageShapeAdjust.GetFineTune10:single;
begin result:=FFineTune[1].x end;
function TImageShapeAdjust.GetFineTune11:single;
begin result:=FFineTune[1].y end;
function TImageShapeAdjust.GetFineTune12:single;
begin result:=FFineTune[1].z end;
function TImageShapeAdjust.GetFineTune20:single;
begin result:=FFineTune[2].x end;
function TImageShapeAdjust.GetFineTune21:single;
begin result:=FFineTune[2].y end;
function TImageShapeAdjust.GetFineTune22:single;
begin result:=FFineTune[2].z end;
function TImageShapeAdjust.GetFineTune30:single;
begin result:=FFineTune[3].x end;
function TImageShapeAdjust.GetFineTune31:single;
begin result:=FFineTune[3].y end;
function TImageShapeAdjust.GetFineTune32:single;
begin result:=FFineTune[3].z end;
function TImageShapeAdjust.GetFineTune40:single;
begin result:=FFineTune[4].x end;
function TImageShapeAdjust.GetFineTune41:single;
begin result:=FFineTune[4].y end;
function TImageShapeAdjust.GetFineTune42:single;
begin result:=FFineTune[4].z end;
function TImageShapeAdjust.GetFineTune50:single;
begin result:=FFineTune[5].x end;
function TImageShapeAdjust.GetFineTune51:single;
begin result:=FFineTune[5].y end;
function TImageShapeAdjust.GetFineTune52:single;
begin result:=FFineTune[5].z end;
function TImageShapeAdjust.GetFineTune60:single;
begin result:=FFineTune[6].x end;
function TImageShapeAdjust.GetFineTune61:single;
begin result:=FFineTune[6].y end;
function TImageShapeAdjust.GetFineTune62:single;
begin result:=FFineTune[6].z end;
function TImageShapeAdjust.GetFineTune70:single;
begin result:=FFineTune[7].x end;
function TImageShapeAdjust.GetFineTune71:single;
begin result:=FFineTune[7].y end;
function TImageShapeAdjust.GetFineTune72:single;
begin result:=FFineTune[7].z end;
function TImageShapeAdjust.GetFineTune80:single;
begin result:=FFineTune[8].x end;
function TImageShapeAdjust.GetFineTune81:single;
begin result:=FFineTune[8].y end;
function TImageShapeAdjust.GetFineTune82:single;
begin result:=FFineTune[8].z end;
function TImageShapeAdjust.GetOffset0:single;
begin result:=FOffset.x end;
function TImageShapeAdjust.GetOffset1:single;
begin result:=FOffset.y end;
function TImageShapeAdjust.GetProjectorFOV:single;
begin result:=FProjectorFOV end;
function TImageShapeAdjust.GetProjectorHeading0:single;
begin result:=FProjectorHeading.x end;
function TImageShapeAdjust.GetProjectorHeading1:single;
begin result:=FProjectorHeading.y end;
function TImageShapeAdjust.GetProjectorHeading2:single;
begin result:=FProjectorHeading.z end;
function TImageShapeAdjust.GetResolution:integer;
begin result:=FResolution end;
function TImageShapeAdjust.GetSize0:single;
begin result:=FSize.x end;
function TImageShapeAdjust.GetSize1:single;
begin result:=FSize.y end;
function TImageShapeAdjust.GetDstAspect:single;
begin result:=FDstAspect end;
function TImageShapeAdjust.GetSrcAspect:single;
begin result:=FSrcAspect end;

function TImageShapeAdjust.SaveToStr: rawbytestring;
var p:TImageShapeAdjustParams;
begin
  p:=GetParametersAsArray;
  setlength(result,sizeof(p));
  move(p,result[1],sizeof(p));
end;

procedure TImageShapeAdjust.LoadFromStr(const s: rawbytestring);
var p:TImageShapeAdjustParams;
begin
  if length(s)=SizeOf(p)then begin
    move(s[1],p,sizeof(p));
    SetParametersAsArray(p);
  end;
end;

procedure TImageShapeAdjust.SetFinetune(i: integer; const Value: TV3f);
begin
  if FFinetune[i]<>Value then begin
    FFinetune[i]:=Value;changed;
  end;
end;

function TImageShapeAdjust.GetFinetune(i: integer): TV3f;
begin
  result:=FFinetune[i];
end;

procedure TImageShapeAdjust.CheckRanges;
  procedure ranger(const a:single;var b:single;const c:single);
  begin if b<a then b:=a else if b>c then b:=c;end;
var i:integer;
begin
  ranger(8,FProjectorFOV,90);
  for i:=0 to 2 do FProjectorHeading.Coord[i]:=rangerf(-360,FProjectorHeading.Coord[i],360);
  for i:=0 to 1 do begin
    FOffset.coord[i]:=rangerf(-6,FOffset.coord[i],6);
    FSize.coord[i]:=rangerf(-8,FSize.coord[i],8);
    FBow.coord[i]:=rangerf(-1,FBow.coord[i],1);
    FAsymmetricBow.coord[i]:=rangerf(-1,FAsymmetricBow.coord[i],1);
  end;
  for i:=0 to 8 do begin
    ranger(-1,FFinetune[i].x,1);
    ranger(-1,FFinetune[i].y,1);
    ranger(-4,FFinetune[i].z,4);
  end;
  if FResolution<3 then FResolution:=3;
  if (FResolution and 1)=0 then inc(FResolution);
  ranger(0.01,FSrcAspect,100);
  ranger(0.01,FDstAspect,100);
end;

procedure TImageShapeAdjust.Changed;
begin
  Valid:=false;
  inc(ChangeIdx);
end;

constructor TImageShapeAdjust.Create(AOwner: TComponent);
begin
  inherited;
  Reset;
end;

procedure TImageShapeAdjust.Reset;
var i:integer;
begin
  FProjectorFOV:=30;
  FProjectorHeading:=V3f(0,0,0);
  FOffset:=v2f(0,0);
  FSize:=v2f(0,0);
  FBow:=v2f(0,0);
  FAsymmetricBow:=v2f(0,0);
  for i:=0 to 8 do FFinetune[i]:=v3f(0,0,0);
  FResolution:=11;
  FDstAspect:=4/3;
  FSrcAspect:=4/3;
  Changed;
end;

type
  TV3fArray=THetArray<TV3f>;

function GenerateBezierSurface(const Steps,Width,Height:Integer;const control:TV3fArray):TV3fArray;

  function BezierSurfacePoint(s,t : single; m,n : integer; cp : TV3fArray) : TV3f;

    function BernsteinBasis(n,i : Integer; t : Single) : Single;
    const Factorial:array[0..7]of single=(1,1,2,6,24,120,720,5040);
    var
      ti, tni : Single;
    begin
      if (t=0) and (i=0) then ti:=1 else ti:=Power(t,i);
      if (n=i) and (t=1) then tni:=1 else tni:=Power(1-t,n-i);
      Result:=(Factorial[n]/(Factorial[i]*Factorial[n-i]))*ti*tni;
    end;

  var
    i,j : integer;
    b1,b2 : Single;
  begin
    Result:=V3f(0,0,0);
    for j:=0 to n-1 do
      for i:=0 to m-1 do begin
        b1:=BernsteinBasis(m-1,i,s);
        b2:=BernsteinBasis(n-1,j,t);
        Result:=Result+cp.FItems[j*m+i]*(b1*b2);
      end;
  end;

var i,j:Integer;
    sr:single;
begin
  result.FCount:=Steps*Steps;
  setlength(result.FItems,result.FCount);
  sr:=1/(steps-1);
  for j:=0 to Steps-1 do for i:=0 to Steps-1 do
    Result.FItems[i+j*Steps]:=BezierSurfacePoint(i*sr,j*sr,Width,Height,Control);
end;

procedure TImageShapeAdjust.CalculateGrid;
  Function Pow(a,b:single):single;
  begin if a=0 then Pow:=0 else Pow:=Exp(Ln(a)*b)end;
  function V2Make(const v:TV3f):TV2f;
  begin result.x:=v.x;result.y:=v.y end;

var controlPoints,vertices:THetArray<TV3f>;
    x,y,i:integer;
    v:TV3f;
    invRes,invZ:single;
begin
  CheckRanges;

  for y:=0 to 2 do for x:=0 to 2 do
    controlPoints.Append(V3f((x-1)*0.5,(y-1)*0.5/srcAspect,0));

  //XABow
  for x:=0 to 2 do
    controlPoints.FItems[x+3]:=controlPoints.FItems[x+3]+V3f(AsymmetricbowX,0,0);
  //YABow
  for y:=0 to 2 do
    controlPoints.FItems[1+y*3]:=controlPoints.FItems[1+y*3]+V3f(0,AsymmetricbowY,0);

  //XBow
  controlPoints.FItems[3]:=controlPoints.FItems[3]+V3f( BowX,0,0);
  controlPoints.FItems[5]:=controlPoints.FItems[5]+V3f(-BowX,0,0);
  //YBow
  controlPoints.FItems[1]:=controlPoints.FItems[1]+V3f(0, BowY,0);
  controlPoints.FItems[7]:=controlPoints.FItems[7]+V3f(0,-BowY,0);

  //finetune
  for i:=0 to 8 do controlPoints.FItems[i]:=controlPoints.FItems[i]+ffinetune[i];

  vertices:=GenerateBezierSurface(resolution,3,3,controlPoints);

  _Perspective(ProjectorFOV,dstAspect,0.0001,20);
  _translate(0,0,-cotan((ProjectorFOV/180*pi)/2)/dstAspect);
  _translate(foffset.x,foffset.y,0);
  _rotate(fProjectorheading.x,0,1,0);//rotate
  _rotate(fProjectorheading.y,1,0,0);//rotate
  _rotate(fProjectorheading.z,0,0,1);//rotate
  _scale(pow(2,fsize.x /3),pow(2,fsize.y /3),1);//size

  setlength(Grid,resolution,resolution);
  invRes:=1/(resolution-1);
  i:=0;for y:=0 to resolution-1 do for x:=0 to resolution-1 do with Grid[y,x]do begin
    t.x :=x*invRes;
    t.y :=1-y*invRes;
    v:=VTransform(ProjectionMatrix,vertices.FItems[i]);
    invZ:=1/v.z ;
    p.x :=(v.x *invZ)+0.5;
    p.y :=(v.y *invZ)+0.5;
    inc(i);
  end;

  v:=VTransform(ProjectionMatrix,V3f(0,0,0));
  FRightVec:=V2Make(VTransform(ProjectionMatrix,V3f(1,0,0))-v);
  FUpVec:=   V2Make(VTransform(ProjectionMatrix,V3f(0,1,0))-v);

  valid:=true;
end;

procedure TImageShapeAdjust.CalculateGridIfNeeded;
begin
  if not valid then
    CalculateGrid;
end;

function TImageShapeAdjust.GetProjectedControlPoint(i:integer):TV2f;
var xx,yy:integer;
begin
  if not valid then
    CalculateGrid;
  if(i>=0)and(i<9)then begin
    yy:=(i div 3)*high(Grid)div 2;
    xx:=(i mod 3)*high(Grid[yy])div 2;
    Result:=Grid[yy,xx].p;
  end else begin
    result:=V2f(0,0);
  end;
end;

function TImageShapeAdjust.GetNearestProjectedControlPoint(ax, ay: single): integer;
var x,y,xx,yy:integer;
    d,mind:single;
begin
  if not valid then
    CalculateGrid;
  result:=-1;mind:=0;
  if length(Grid)=0 then exit;
  for y:=0 to 2 do begin
    yy:=y*high(Grid)div 2;
    for x:=0 to 2 do begin
      xx:=x*high(Grid[yy])div 2;
      with Grid[yy,xx]do begin
        d:=sqr(p.x-ax)+sqr(p.y-ay);
        if(result<0)or(d<mind)then begin
          result:=x+y*3;
          mind:=d;
        end;
      end;
    end;
  end;
end;

procedure TImageShapeAdjust.TransformBitmap32(src, dst: TBitmap);
var y,x,dw,dh,sw,sh:integer;
    v1,v2:_PGridVertex;
begin
  if(dst=nil)or(src=nil)then exit;
  if(dst.Width<1)or(dst.Height<1)or(src.Width<2)or(src.Height<2)then exit;
  if src.PixelFormat<>pf32bit then exit;
  if dst.PixelFormat<>pf32bit then exit;
  DstAspect:=dst.Width/dst.Height;
  SrcAspect:=src.Width/src.Height;
  if not Valid then
    CalculateGrid;
  dw:=dst.Width;dh:=dst.Height;
  sw:=src.Width;sh:=src.Height;
  for y:=0 to FResolution-2 do begin
    for x:=0 to FResolution-1 do begin
      v1:=@Grid[y,x];
      v2:=@Grid[y+1,x];
      FillQuadStripF(x=0,defaultYBuf,
        v1.p.x*dw,v1.p.y *dh,v1.t.x *sw,v1.t.y *sh,
        v2.p.x*dw,v2.p.y *dh,v2.t.x *sw,v2.t.y *sh,
        dst,src);
    end;
  end;

  for y:=0 to FResolution-2 do begin
    for x:=0 to FResolution-1 do begin
      v1:=@Grid[y+1,x];
      v2:=@Grid[y,x];
      FillQuadStripF(x=0,defaultYBuf,
        v1.p.x *dw,v1.p.y *dh,v1.t.x *sw,v1.t.y *sh,
        v2.p.x *dw,v2.p.y *dh,v2.t.x *sw,v2.t.y *sh,
        dst,src);
    end;
  end;
end;

procedure TImageShapeAdjust.Setup(const AHostControl: tcontrol;
  const formPos: tpoint);
begin
  ImageShapeAdjustSetup(self,AHostControl,formPos.X,formPos.Y);
end;

procedure TImageShapeAdjust.Setup(const AHostControl: tcontrol);
begin
  ImageShapeAdjustSetup(self,AHostControl);
end;

procedure TImageShapeAdjust.Assign(src: TPersistent);
var s:TImageShapeAdjust;
    i:integer;
begin
  if src=nil then reset
  else if src is TImageShapeAdjust then begin
    s:=src as TImageShapeAdjust;
    FProjectorFOV:=s.FProjectorFOV;
    FProjectorHeading:=s.FProjectorHeading;
    FOffset:=s.FOffset;
    FSize:=s.FSize;
    FBow:=s.FBow;
    FAsymmetricBow:=s.FAsymmetricBow;
    for i:=0 to 8 do FFinetune[i]:=s.FFinetune[i];
    FResolution:=s.FResolution;
    FDstAspect:=s.FDstAspect;
    FSrcAspect:=s.FSrcAspect;
    Changed;
  end else inherited;
end;

destructor TImageShapeAdjust.Destroy;
begin
  inherited;
end;

procedure TImageShapeAdjust.UpdateIfNeeded;
begin
  if not Valid then
    CalculateGrid;
end;

function TImageShapeAdjust.GetParametersAsArray:TImageShapeAdjustParams;
  var pos:integer;
  procedure doit(const s:single);overload;
  begin result[pos]:=s;inc(pos);end;
  procedure doit(const s:integer);overload;
  begin result[pos]:=s;inc(pos);end;
  procedure doit(const s:tv2f);overload;
  begin doit(s.x );doit(s.y );end;
  procedure doit(const s:tv3f);overload;
  begin doit(s.x );doit(s.y );doit(s.z );end;

  var i:integer;
begin
{   FProjectorFOV:single;               1
    FProjectorHeading:TVector3f;        3
    FOffset:TVector2f;                  2
    FSize:TVector2f;                    2
    FBow:TVector2f;                     2
    FAsymmetricBow:TVector2f;           2
    FFinetune:array[0..8]of TVector3f; 27
    -----------------------------sum = 39}
  pos:=0;
  doit(FProjectorFOV);
  doit(FProjectorHeading);
  doit(FOffset);
  doit(FSize);
  doit(FBow);
  doit(FAsymmetricBow);
  for i:=0 to 8 do doit(FFineTune[i]);
  doit(FFade);
  doit(FResolution);
end;

procedure TImageShapeAdjust.SetParametersAsArray(const value:TImageShapeAdjustParams);
  var pos:integer;
  procedure doit(var s:single);overload;
  begin s:=value[pos];inc(pos);end;
  procedure doit(var s:integer);overload;
  begin s:=round(value[pos]);inc(pos);end;
  procedure doit(var s:tv2f);overload;
  begin doit(s.x );doit(s.y );end;
  procedure doit(var s:tv3f);overload;
  begin doit(s.x );doit(s.y );doit(s.z );end;

  var i:integer;
begin
  pos:=0;
  doit(FProjectorFOV);
  doit(FProjectorHeading);
  doit(FOffset);
  doit(FSize);
  doit(FBow);
  doit(FAsymmetricBow);
  for i:=0 to 8 do doit(FFineTune[i]);
  doit(FFade);
  doit(FResolution);
end;

procedure TImageShapeAdjust.SetParametersAsArrayLerp(const value1,value2:TImageShapeAdjustParams;const t:single);
  function lerp(const a,b:single):single;
  begin result:=a+(b-a)*t end;

  var pos:integer;
  procedure doit(var s:single);overload;
  begin
    s:=lerp(value1[pos],value2[pos]);inc(pos);
  end;
  procedure doit(var s:tv2f);overload;
  begin
    doit(s.x );doit(s.y );
  end;
  procedure doit(var s:tv3f);overload;
  begin
    doit(s.x );doit(s.y );doit(s.z );
  end;

  var i:integer;
begin
  pos:=0;
  doit(FProjectorFOV);
  doit(FProjectorHeading);
  doit(FOffset);
  doit(FSize);
  doit(FBow);
  doit(FAsymmetricBow);
  for i:=0 to 8 do doit(FFineTune[i]);
  doit(FFade);
end;


end.

