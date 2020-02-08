unit UModel;

interface

uses HetObject, UVector, UMatrix;

type

  TDrawOption=(doNoTextures,doPushNames);
  TDrawOptions=set of TDrawOption;

  TVertex=class(THetObject)
  public
    FV,FN:TV3F;
    FT:TV2F;
    procedure glDraw;
  public
    property Vx:single read FV.v[0] write FV.v[0];
    property Vy:single read FV.v[1] write FV.v[1];
    property Vz:single read FV.v[2] write FV.v[2];

{    property Nx:single read N.v[0] write N.v[0];
    property Ny:single read N.v[1] write N.v[1];
    property Nz:single read N.v[2] write N.v[2];  //calculated shadegroup alapjan

    property Tx:single read T.v[0] write T.v[0];
    property Ty:single read T.v[1] write T.v[1];}
  end;


implementation

{ TVertex }

procedure TVertex.glDraw;
begin
{  glNormal3fv(@N);
  glTexCoord2fv(@T);
  glVertex3fv(@V);}
end;

end.