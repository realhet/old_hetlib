unit UVectorObjects;

interface

uses sysutils, hetutils, uvector, umatrix, hetobject;

type
  TVector3f=class(THetObject)
  private
    FV:TV3f;
    function GetX: single;
    function GetY: single;
    function GetZ: single;
    procedure SetX(const Value: single);
    procedure SetY(const Value: single);
    procedure SetZ(const Value: single);
    procedure SetV(const Value: TV3f);
  public
    property V:TV3f read FV write SetV;
  public
    property X:single read GetX write SetX;
    property Y:single read GetY write SetY;
    property Z:single read GetZ write SetZ;
  end;

  TVector3d=class(THetObject)
  private
    FV:TV3d;
    function GetX: double;
    function GetY: double;
    function GetZ: double;
    procedure SetX(const Value: double);
    procedure SetY(const Value: double);
    procedure SetZ(const Value: double);
    procedure SetV(const Value: TV3d);
  public
    property V:TV3d read FV write SetV;
  public
    property X:double read GetX write SetX;
    property Y:double read GetY write SetY;
    property Z:double read GetZ write SetZ;
  end;

  TRotation=class(THetObject)
  private
    FQ:TQuaternion;
    function GetImagX:single;
    function GetImagY:single;
    function GetImagZ:single;
    function GetReal:single;
    procedure SetImagX(const Value:single);
    procedure SetImagY(const Value:single);
    procedure SetImagZ(const Value:single);
    procedure SetReal(const Value:single);
    procedure SetQ(const Value:TQuaternion);
  public
    property Q:TQuaternion read FQ write SetQ;
  published
    property ImagX:single read GetImagX write SetImagX;
    property ImagY:single read GetImagY write SetImagY;
    property ImagZ:single read GetImagZ write SetImagZ;
    property Real:single read GetReal write SetReal;
  end;

  TTransformationF=class(THetObject)
  private
    FRotation:TRotation;
    FScale:single;
    FPosition:TVector3f;
    procedure SetScale(const Value:single);
  private
    FValid:boolean;
    FMatrix:TM44f;
    procedure Update;
    function GetMatrix: TM44f;
    procedure SetMatrix(const Value: TM44f);
  public
    procedure NotifyChange;override;
    property Matrix:TM44f read GetMatrix write SetMatrix;
  published
    property Rotation:TRotation read FRotation;
    property Position:TVector3f read FPosition;
    property Scale:single read FScale write SetScale;
  end;

  TProjectionType=(ptPerspective,ptOrtho);

  TProjection=class(THetObject)
  private
    FType:TProjectionType;
    FAspect:single;
    FFOVY:single;
    FzNear,FzFar:single;
    FOrthoYScale:single;
    procedure SetAspect(const Value: single);
    procedure SetFOVY(const Value: single);
    procedure SetType(const Value: TProjectionType);
    procedure SetzFar(const Value: single);
    procedure SetzNear(const Value: single);
    procedure SetOrthoYScale(const Value: single);
  private
    FValid:boolean;
    FMatrix:TM44f;
    procedure Update;
  public
    procedure NotifyChange;override;
  published
    property Typ:TProjectionType read FType write SetType;
    property Aspect:single read FAspect write SetAspect;
    property FOVY:single read FFOVY write SetFOVY;
    property zNear:single read FzNear write SetzNear;
    property zFar:single read FzFar write SetzFar;
    property OrthoYScale:single read FOrthoYScale write SetOrthoYScale;
  end;

  TSceneObject=class(THetObject)
  private
  public
  published
    Transformation:TTransformationD;
  end;

  TCamera=class(TSceneObject)
  private
  public
  published
    property Projection:TProjection read FProjection;
    property Transformation:TTransformationD;
    property Target:TPositionD;
  end;

  TLight=class(TSceneObject)

  end;

implementation

{ TVector3f }

function TVector3f.GetX: single;begin result:=FV.V[0] end;
function TVector3f.GetY: single;begin result:=FV.V[1] end;
function TVector3f.GetZ: single;begin result:=FV.V[2] end;

procedure TVector3f.SetX(const Value: single);begin if Value=FV.V[0]then exit;FV.V[0]:=Value;NotifyChange end;
procedure TVector3f.SetY(const Value: single);begin if Value=FV.V[1]then exit;FV.V[1]:=Value;NotifyChange end;
procedure TVector3f.SetZ(const Value: single);begin if Value=FV.V[2]then exit;FV.V[2]:=Value;NotifyChange end;

procedure TVector3f.SetV(const Value: TV3f);
begin
  if FV=Value then exit;
  FV:=Value;
  NotifyChange;
end;

{ TVector3d }

function TVector3d.GetX: double;begin result:=FV.V[0] end;
function TVector3d.GetY: double;begin result:=FV.V[1] end;
function TVector3d.GetZ: double;begin result:=FV.V[2] end;

procedure TVector3d.SetX(const Value: double);begin if Value=FV.V[0]then exit;FV.V[0]:=Value;NotifyChange end;
procedure TVector3d.SetY(const Value: double);begin if Value=FV.V[1]then exit;FV.V[1]:=Value;NotifyChange end;
procedure TVector3d.SetZ(const Value: double);begin if Value=FV.V[2]then exit;FV.V[2]:=Value;NotifyChange end;

procedure TVector3d.SetV(const Value: TV3d);
begin
  if FV=Value then exit;
  FV:=Value;
  NotifyChange;
end;

{ TRotation }

function TRotation.GetImagX: single;begin result:=FQ.Imag.V[0] end;
function TRotation.GetImagY: single;begin result:=FQ.Imag.V[1] end;
function TRotation.GetImagZ: single;begin result:=FQ.Imag.V[2] end;
function TRotation.GetReal: single;begin result:=FQ.Real end;

procedure TRotation.SetImagX(const Value: single);begin if FQ.Imag.V[0]=Value then exit;FQ.Imag.V[0]:=Value;NotifyChange end;
procedure TRotation.SetImagY(const Value: single);begin if FQ.Imag.V[1]=Value then exit;FQ.Imag.V[1]:=Value;NotifyChange end;
procedure TRotation.SetImagZ(const Value: single);begin if FQ.Imag.V[2]=Value then exit;FQ.Imag.V[2]:=Value;NotifyChange end;
procedure TRotation.SetReal(const Value: single);begin if FQ.Real=Value then exit;FQ.Real:=Value;NotifyChange end;

procedure TRotation.SetQ(const Value: TQuaternion);
begin
  if FQ<>Value then exit;
  FQ:=Value;
  NotifyChange;
end;

{ TTransformationF }

{$O-}
procedure TTransformationF.SetScale(const Value: single);begin end;
{$O+}

procedure TTransformationF.NotifyChange;
begin
  inherited;
  FValid:=false;
end;

procedure TTransformationF.Update;
begin
  FMatrix:=MRotation(FRotation.FQ);
  if FScale<>1 then MScale(FMatrix,FScale);
  MTranslate(FMatrix,FPosition.FV);

  FValid:=true;
end;

function TTransformationF.GetMatrix: TM44f;
begin
  if not FValid then Update;
  result:=FMatrix;
end;

procedure TTransformationF.SetMatrix(const Value: TM44f);
begin
  Scale:=VLength(V3f(Value[0,0],Value[0,1],Value[0,2]));
  Rotation.Q:=Quaternion(MNormalize(Value));
  Position.V:=V3f(Value[3,0],Value[3,1],Value[3,2]);
end;

{ TProjection }

{$O-}
procedure TProjection.SetAspect(const Value: single);begin end;
procedure TProjection.SetFOVY(const Value: single);begin end;
procedure TProjection.SetOrthoYScale(const Value: single);begin end;
procedure TProjection.SetType(const Value: TProjectionType);begin end;
procedure TProjection.SetzFar(const Value: single);begin end;
procedure TProjection.SetzNear(const Value: single);begin end;
{$O+}

procedure TProjection.NotifyChange;
begin
  inherited;
  FValid:=false;
end;

procedure TProjection.Update;
begin
  case FType of
    ptPerspective:FMatrix:=MProjection(FOVY,Aspect,zNear,zFar);
    ptOrtho:FMatrix:=MOrtho(OrthoYScale,Aspect,zNear,zFar);
    else FMatrix:=M44fIdentity;
  end;
  FValid:=true;
end;

end.
