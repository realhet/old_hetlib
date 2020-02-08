unit het.Engine;

interface

uses
  Windows, SysUtils, het.Utils, het.Objects, math, UVector, UMatrix, OpenGl1x;

type
  TVector=class(THetObject)
  private
    FV:TV3f;
    procedure SetX(const Value: single);
    procedure SetY(const Value: single);
    procedure SetZ(const Value: single);
    function GetX: single;
    function GetY: single;
    function GetZ: single;
    procedure SetV(const Value: TV3f);
  public
    property V:TV3f read FV write SetV;
  published
    property X:single read GetX write SetX;
    property Y:single read GetY write SetY;
    property Z:single read GetZ write SetZ;
  end;

  TMatrix=class(THetObject)
  private
    FM:TM44f;
    procedure SetM(const Value:TM44f);
    function GetData:RawByteString;
    procedure SetData(const Value:RawByteString);
  public
    constructor Create(const AOwner:THetObject);override;
    property M:TM44f read FM write SetM;
  published
    property Data:RawByteString read GetData write SetData stored true;
  end;

  TCamera=class(THetObject)
  private
    FTarget:TVector;
    FTargetDist,FHeading,FPitch,FFOVy,FAspect,FZNear,FZFar:single;
    procedure SetFOVy(const Value: single);
    procedure SetHeading(const Value: single);
    procedure SetPitch(const Value: single);
    procedure SetTargetDist(const Value: single);
    procedure SetAspect(const Value: single);
    procedure SetZFar(const Value: single);
    procedure SetZNear(const Value: single);
  public
    function MProj:TM44f;
    function MRot:TM44f;
    function VUp:TV3f;
    function VForward:TV3f;
    function VLeft:TV3f;
    function VEye: TV3f;
    function MView:TM44f;
    function MEye:TM44f;
    procedure glLoadMatrices;
    procedure GoUp(s:single);
    procedure GoDown(s:single);
    procedure GoLeft(s:single);
    procedure GoRight(s:single);
    procedure GoForward(s:single);
    procedure GoBack(s:single);
    procedure Turn(tx,ty:single);
  published
    property Target:TVector read FTarget;
    property TargetDist:single read FTargetDist write SetTargetDist;
    property Pitch:single read FPitch write SetPitch;
    property Heading:single read FHeading write SetHeading;

    property FOVy:single read FFOVy write SetFOVy;
    property Aspect:single read FAspect write SetAspect;
    property ZNear:single read FZNear write SetZNear;
    property ZFar:single read FZFar write SetZFar;
  end;

implementation

{ TVector }

procedure TVector.SetX(const Value: single);begin if FV.V[0]=Value then exit;FV.V[0]:=Value;notifychange end;
procedure TVector.SetY(const Value: single);begin if FV.V[1]=Value then exit;FV.V[1]:=Value;notifychange end;
procedure TVector.SetZ(const Value: single);begin if FV.V[2]=Value then exit;FV.V[2]:=Value;notifychange end;

function TVector.GetX: single;begin result:=V.V[0];end;
function TVector.GetY: single;begin result:=V.V[1];end;
function TVector.GetZ: single;begin result:=V.V[2];end;

procedure TVector.SetV(const Value: TV3f);
begin
  if FV=Value then exit;
  FV:=Value;
  NotifyChange;
end;

{ TCamera }

{$O-}
procedure TCamera.SetAspect(const Value: single);begin end;
procedure TCamera.SetFOVy(const Value: single);begin end;
procedure TCamera.SetHeading(const Value: single);begin end;
procedure TCamera.SetPitch(const Value: single);begin end;
procedure TCamera.SetTargetDist(const Value: single);begin end;
procedure TCamera.SetZFar(const Value: single);begin end;
procedure TCamera.SetZNear(const Value: single);begin end;
{$O+}

function TCamera.MProj: TM44f;
begin
  result:=MProjection(FOVy,Aspect,ZNear,ZFar);
end;

function TCamera.MRot: TM44f;
begin
  result:=MRotation(XYZ,Pitch,Heading,0);
end;

function TCamera.VForward:TV3f;
var r:TM44f;
begin
  r:=MRot;
  result:=v3f(r[2,0],r[2,1],r[2,2]);
end;

function TCamera.VUp:TV3f;
var r:TM44f;
begin
  r:=MRot;
  result:=v3f(r[1,0],r[1,1],r[1,2]);
end;

function TCamera.VLeft:TV3f;
var r:TM44f;
begin
  r:=MRot;
  result:=v3f(r[0,0],r[0,1],r[0,2]);
end;

function TCamera.VEye:TV3f;
var r:TM44f;
begin
  r:=MRot;
  result:=Target.V-VForward*TargetDist;
end;

function TCamera.MView: TM44f;
begin
  result:=MLookAt(VEye,VEye+VForward,VUp);
end;

function TCamera.MEye: TM44f;
begin
  result:=MRot;
  MTranslate(result,VEye);
end;

procedure TCamera.glLoadMatrices;
var m:TM44f;
begin
  m:=MProj;glMatrixMode(GL_PROJECTION);glLoadIdentity;glLoadMatrixf(@m);
  m:=MView;glMatrixMode(GL_MODELVIEW );glLoadIdentity;glLoadMatrixf(@m);
end;

procedure TCamera.GoUp(s:single);
begin
  with Target do V:=V+VUp*s;
end;

procedure TCamera.GoDown(s:single);
begin
  GoUp(-s);
end;

procedure TCamera.GoLeft(s:single);
begin
  with Target do V:=V+VLeft*s;
end;

procedure TCamera.GoRight(s:single);
begin
  GoLeft(-s);
end;

procedure TCamera.GoForward(s:single);
begin
  with Target do V:=V+VForward*s;
end;

procedure TCamera.GoBack(s:single);
begin
  GoForward(-s);
end;

procedure TCamera.Turn(tx, ty: single);
begin
  Heading:=Heading+tx;
  Pitch:=Pitch+ty;
end;

{ TMatrix }

constructor TMatrix.Create(const AOwner: THetObject);
begin
  inherited;
  FM:=M44fIdentity;
end;

function TMatrix.GetData: RawByteString;
begin
  result:=Data2Str(FM,sizeof(FM));
end;

procedure TMatrix.SetData(const Value: RawByteString);
begin
  if Length(Value)<>sizeof(FM) then Raise Exception.Create('TMatrix.SetData() corrupted data');
  if Value=GetData then exit;
  Str2Data(Value,FM);
  NotifyChange;
end;

procedure TMatrix.SetM(const Value: TM44f);
begin
  if CompareMem(@Fm,@Value,sizeof(FM))then exit;
  FM:=Value;
  NotifyChange;
end;

initialization
  RegisterHetClass([TVector,TMatrix]);
finalization
end.
