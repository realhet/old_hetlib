unit UMotionDetector;

interface

uses
  windows, sysutils, math, het.Objects, graphics, het.gfx, het.Utils, UVector, U2dPhysics;

type
  TMotionDetector=class(THetObject)
  private
    FResolutionX: integer;
    FResolutionY: integer;
    FSensitivity: integer;
    FEdgeBlur: integer;
    FMovementBlur: integer;

    bAct,bReference,bPrev:TBitmap;
  public
    function Process(const b:TBitmap;const AWorldMin,AWorldMax:TV2f;const CopyReference,MaskInAlpha:boolean):TBodyArray;
    destructor Destroy;override;
  published
    property ResolutionX:integer read FResolutionX write FResolutionX default 32;
    property ResolutionY:integer read FResolutionY write FResolutionY default 24;
    property Sensitivity:integer read FSensitivity write FSensitivity default 8;
    property EdgeBlur:integer read FEdgeBlur write FEdgeBlur default 7;
    property MovementBlur:integer read FMovementBlur write FMovementBlur default 21;
  end;

implementation

{ TMotionDetector }

const SmallEdges:array[0..15,0..3]of byte=(
  (4,4,4,4),(3,0,4,4),(0,1,4,4),(3,1,4,4),
  (2,3,4,4),(2,0,4,4),(2,3,0,1),(2,1,4,4),
  (1,2,4,4),(1,2,3,0),(0,2,4,4),(3,2,4,4),
  (1,3,4,4),(1,0,4,4),(0,3,4,4),(0,0,4,4));

{ bits: 0 1   edges:   0    4=none|
        2 3          3   1        |
                       2          }

destructor TMotionDetector.Destroy;
begin
  FreeAndNil(bAct);
  FreeAndNil(bPrev);
  FreeAndNil(bReference);
  inherited;
end;

function TMotionDetector.Process(const b:TBitmap;const AWorldMin,AWorldMax:TV2f;const CopyReference,MaskInAlpha:boolean):TBodyArray;

  var transScale,transAdd:TV2f;
      points:TV2fArray;
      velocityScale:Single;

  function AddPoint(const v:TV2f):TV2f;
  begin
    SetLength(points,length(points)+1);
    points[high(points)]:=v*transScale+transAdd;
  end;

  procedure AddBody(const vel:TV2f);
  begin
    SetLength(result,length(Result)+1);
    Result[high(result)]:=TBody.CreatePoly(vel*transScale,0,Points,0);
    SetLength(points,0);
  end;

  procedure FindBlocks(const b,bPrev:TBitmap;const xSize,ySize,Threshold:integer);
    var xSteps,ySteps:array of integer;
        pb,pprev:pByte;

    function Value(x,y:integer):integer;
    begin result:=pByte(pSucc(pb,xSteps[x]+ySteps[y]))^;end;
    function PrevValue(x,y:integer):integer;
    begin result:=pByte(pSucc(pprev,xSteps[x]+ySteps[y]))^;end;

    var win,win2:array[0..1,0..1]of integer;
        x,y:integer;
        velocity:TV2f;

    function EdgePoint(e:integer):TV2f;
    begin
      case e of
        0:result:=V2f(x+(Threshold-win[0,0])/(win[0,1]-win[0,0]),y  );
        2:result:=V2f(x+(Threshold-win[1,0])/(win[1,1]-win[1,0]),y+1);
        3:result:=V2f(x  ,y+(Threshold-win[0,0])/(win[1,0]-win[0,0]));
        1:result:=V2f(x+1,y+(Threshold-win[0,1])/(win[1,1]-win[0,1]));
      end;
    end;

    procedure DoEdge(st,en:integer);
    var p0,p1:TV2f;
    begin
      if st=4 then exit;
      p0:=EdgePoint(st);
      p1:=EdgePoint(en);

      AddPoint(p0);
      AddPoint(p1);

      while en<>st do begin
        case en of
          0:AddPoint(V2f(x,y));
          1:AddPoint(V2f(x+1,y));
          2:AddPoint(V2f(x+1,y+1));
          3:AddPoint(V2f(x,y+1));
        end;
        dec(en);if en<0 then en:=3;
      end;

      AddBody(velocity);
    end;

  var i,code,dx,dy,spd:integer;
  begin
    bPrev.Width:=b.Width;
    bPrev.Height:=b.Height;
    pb:=b.ScanLine[b.Height-1];
    pprev:=bPrev.ScanLine[bPrev.Height-1];
    setlength(xSteps,xSize+1);for i:=0 to xSize do xSteps[i]:=i*(b.Width -1)div xSize;
    setlength(ySteps,ySize+1);for i:=0 to ySize do ySteps[ySize-i]:=(i*(b.Height-1)div ySize)*b.ScanLineSize;

    for y:=0 to ySize-1 do for x:=0 to xSize-1 do begin
      win[0,0]:=Value(x  ,y);
      win[0,1]:=Value(x+1,y);
      win[1,0]:=Value(x  ,y+1);
      win[1,1]:=Value(x+1,y+1);

      code:=ord(win[0,0]>threshold)shl 0+
            ord(win[0,1]>threshold)shl 1+
            ord(win[1,0]>threshold)shl 2+
            ord(win[1,1]>threshold)shl 3;

      if code=0 then continue;

      //movement
      spd:=win[0,0]+win[0,1]+win[1,0]+win[1,1];
      spd:=EnsureRange(spd-(PrevValue(x  ,y)+PrevValue(x+1,y)+PrevValue(x  ,y+1)+PrevValue(x+1,y+1)),0,1024);
      win2[0,0]:=win[0,0]-PrevValue(x  ,y);
      win2[0,1]:=win[0,1]-PrevValue(x+1,y);
      win2[1,0]:=win[1,0]-PrevValue(x  ,y+1);
      win2[1,1]:=win[1,1]-PrevValue(x+1,y+1);
      dy:=(win2[0,0]-win2[1,0])+(win2[0,1]-win2[1,1]);
      dx:=(win2[0,0]-win2[0,1])+(win2[1,0]-win2[1,1]);
      velocity:=VNormalize(V2f(dx+0.001,dy+0.001))*(spd*velocityScale);

      //bodies
      if code=15 then begin
        AddPoint(v2f(x,y));AddPoint(v2f(x,y+1));AddPoint(v2f(x+1,y+1));AddPoint(v2f(x+1,y));
        AddBody(velocity);
      end else begin
        DoEdge(SmallEdges[code,0],SmallEdges[code,1]);
        DoEdge(SmallEdges[code,2],SmallEdges[code,3]);
      end;
    end;
  end;

begin
  setlength(result,0);
  if(b=nil)or(b.Empty)then exit;


  if not MaskInAlpha then begin
    if bAct=nil then bAct:=TBitmap.Create;
    bAct.Assign(b);

    if bReference=nil then bReference:=TBitmap.Create;
    if CopyReference or not b.EqualDimensions(bReference)then bReference.Assign(bAct);

    //abs diff
    bAct.PixelOp2(bReference,function(a,b:cardinal):cardinal begin
      result:=(abs(a        and $ff-b        and $ff)+
               abs(a shr  8 and $ff-b shr  8 and $ff)shl 1+
               abs(a shr 16        -b shr 16        ))shr 2;
      result:=result or result shl 8 or result shl 16;
    end);
    bAct.Components:=1;
  end else begin//mask in alpha
    bAct.Free;
    bAct:=b.GetAlphaChannel;
  end;

  bAct.BlurAvg(FEdgeBlur);

  bAct.PixelOp1(function(a:cardinal):cardinal begin
    result:=ord(a>cardinal(FSensitivity))*255;
  end);

  bAct.BlurAvg(FMovementBlur);

  if bPrev=nil then bPrev:=TBitmap.Create;
  if not bPrev.EqualDimensions(bAct) then bPrev.Assign(bAct);

  transScale:=(AWorldMax-AWorldMin)*V2f(1/FResolutionX,1/FResolutionY);
  transAdd:=AWorldMin;
  velocityScale:=(1/1024/21)*MovementBlur;
  FindBlocks(bAct,bPrev,FResolutionX,FResolutionY,128);

  bPrev.Assign(bAct);
end;

end.
