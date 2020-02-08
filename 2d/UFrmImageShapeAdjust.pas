unit UFrmImageShapeAdjust;//sse

interface

uses
  Windows, Messages, SysUtils, Controls, StdCtrls, Classes, Forms,
  UImageShapeAdjust, ExtCtrls, graphics, jpeg, UVector;

type
  TFrmImageShapeAdjust = class(TForm)
    Panel1: TPanel;
    lbOperation: TListBox;
    Label1: TLabel;
    GroupBox1: TGroupBox;
    lInfo: TLabel;
    bReset: TButton;
    PaintBox1: TPaintBox;
    Image1: TImage;
    procedure lbOperationClick(Sender: TObject);
    procedure MyMouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: Integer);
    procedure PaintBox1Paint(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure PaintBox1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure PaintBox1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure bResetClick(Sender: TObject);
  private
    { Private declarations }
    localState:TImageShapeAdjust;
    bTest:TBitmap;
    procedure UpdateInfo;
    procedure UpdateCursor;
    procedure DoAdjust(dx, dy: integer);
  public
    { Public declarations }
    State:TImageShapeAdjust;//ezt setupoljuk
    HostControl:TControl;//ezt invalidateoljuk, ha valtozas volt
    lx,ly:integer;
    finetuneActPoint:integer;

    valueschanged:boolean;
    floatResolution:single;
  end;

var
  FrmImageShapeAdjust: TFrmImageShapeAdjust;

procedure ImageShapeAdjustSetup(const AImageShapeAdjust:TImageShapeAdjust;const AHostControl:TControl;const formPosX:integer=-1;formPosY:integer=-1);

implementation

uses Math;

{$R *.dfm}

procedure ImageShapeAdjustSetup;
begin
  if FrmImageShapeAdjust=nil then
    Application.CreateForm(TFrmImageShapeAdjust,FrmImageShapeAdjust);
  FrmImageShapeAdjust.State:=AImageShapeAdjust;
  FrmImageShapeAdjust.HostControl:=AHostControl;
  if(formPosX<>-1)or(formPosY<>-1)then begin
    FrmImageShapeAdjust.Left:=formPosX;
    FrmImageShapeAdjust.Top:=formPosY;
  end else begin
    if AHostControl<>nil then begin
      FrmImageShapeAdjust.Left:=AHostControl.Left+(AHostControl.Width -FrmImageShapeAdjust.Width )div 2;
      FrmImageShapeAdjust.Top:=AHostControl.Top  +(AHostControl.Height-FrmImageShapeAdjust.Height)div 2;
    end;
  end;
  if FrmImageShapeAdjust.State<>nil then FrmImageShapeAdjust.Show
                                    else FrmImageShapeAdjust.Hide;
end;

procedure TFrmImageShapeAdjust.FormCreate(Sender: TObject);
begin
  DoubleBuffered:=true;
  
  localState:=TImageShapeAdjust.Create(self);
  bTest:=TBitmap.Create;bTest.PixelFormat:=pf32bit;
  bTest.Width:=Image1.Picture.Width;
  bTest.Height:=Image1.Picture.Height;
  bTest.Canvas.Draw(0,0,Image1.Picture.Graphic);
end;

procedure TFrmImageShapeAdjust.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
  if Operation=opRemove then begin
    if(State=AComponent)then begin
      State:=nil;
      Hide;
    end else
    if(HostControl=AComponent)then begin
      HostControl:=nil;
    end;
  end;
end;

procedure TFrmImageShapeAdjust.lbOperationClick(Sender: TObject);
begin
  UpdateInfo;
  updateCursor;
  PaintBox1.Invalidate;
end;

procedure TFrmImageShapeAdjust.UpdateInfo;
var s:string;
begin
  if assigned(state)then with state do case lbOperation.ItemIndex of
    0:lInfo.Caption:=format('Projector vertical field of view: %6.2n(deg)',[ProjectorFOV]);
    1:lInfo.Caption:=format('Projector horizontal heading: %6.2n(deg)'#13#10'Projector vertical heading: %6.2n(deg)',[ProjectorHeadingAlpha,ProjectorHeadingBeta]);
    2:lInfo.Caption:=format('Projector horizontal heading: %6.2n(deg)',[ProjectorHeadingAlpha]);
    3:lInfo.Caption:=format('Projector vertical heading: %6.2n(deg)',[ProjectorHeadingBeta]);
    4:lInfo.Caption:=format('Projector roll around eye vector: %6.2n(deg)',[ProjectorHeadingGamma]);
    5:lInfo.Caption:=format('Head horizontal offset: %6.3n'#13#10'Head vertical offset: %6.3n',[OffsetX,OffsetY]);
    6:lInfo.Caption:=format('Head horizontal offset: %6.3n',[OffsetX]);
    7:lInfo.Caption:=format('Head vertical offset: %6.3n',[OffsetY]);
    8:lInfo.Caption:=format('Head horizontal size: %6.3n'#13#10'Head vertical size: %6.3n',[sizeX,sizeY]);
    9:lInfo.Caption:=format('Head horizontal size: %6.3n',[sizeX]);
   10:lInfo.Caption:=format('Head vertical size: %6.3n',[sizeY]);
   11:lInfo.Caption:=format('Head horizontal bow: %6.3n',[BowX]);
   12:lInfo.Caption:=format('Head vertical bow: %6.3n',[BowY]);
   13:lInfo.Caption:=format('Head horizontal asymmetric bow: %6.3n',[asymmetricBowX]);
   14:lInfo.Caption:=format('Head vertical asymmetric bow: %6.3n',[asymmetricBowY]);
   15,16:begin
     s:=lbOperation.Items[lbOperation.ItemIndex]+#13#10;
     lInfo.Caption:=s+format('Selected point: %d'#13#10'X: %6.3n Y: %6.3n Z: %6.3n',[finetuneActPoint,Finetune[finetuneActPoint].x,Finetune[finetuneActPoint].y,Finetune[finetuneActPoint].z]);
   end;
   17:lInfo.Caption:=format('Resolution: %d',[Resolution]);
  end else
    lInfo.Caption:='Idle';
end;

procedure TFrmImageShapeAdjust.DoAdjust(dx,dy:integer);
var p:TV3f;
  procedure doit(var s:Single;d:single);
  begin s:=s+d end;

var degx,degy:single;
    ofsx,ofsy,scale:single;
    xen,yen:single;
const degscale=0.1;
      ofsscale=0.0016;
begin
  UpdateCursor;

  if assigned(state)then begin
    xen:=1;yen:=-1;
    case PaintBox1.Cursor of
      crSizeWE:yen:=0;
      crSizeNS:xen:=0;
    end;
    scale:=1;
    if GetKeyState(VK_SHIFT)<0 then scale:=scale/8;
    if GetKeyState(VK_CONTROL)<0 then scale:=scale*8;
    xen:=xen*scale;yen:=yen*scale;

    degx:=-dx*degscale*xen;degy:=dy*degscale*yen;
    ofsx:=dx*ofsscale*xen;ofsy:=-dy*ofsscale*yen;

    with State do case lbOperation.ItemIndex of
      0:ProjectorFOV:=ProjectorFOV+degy;
      1:begin ProjectorHeadingAlpha:=ProjectorHeadingAlpha+degx;ProjectorHeadingBeta:=ProjectorHeadingBeta-degy end;
      2:ProjectorHeadingAlpha:=ProjectorHeadingAlpha+degx;
      3:ProjectorHeadingBeta:=ProjectorHeadingBeta-degy;
      4:ProjectorHeadingGamma:=ProjectorHeadingGamma-degx;
      5:begin OffsetX:=OffsetX+ofsx;OffsetY:=OffsetY+ofsy end;
      6:OffsetX:=OffsetX+ofsx;
      7:OffsetY:=OffsetY+ofsy;
      8:begin SizeX:=SizeX-ofsy*14;SizeY:=SizeY-ofsy*14 end;
      9:SizeX:=SizeX+ofsx*14;
     10:SizeY:=SizeY-ofsy*14;
     11:BowX:=BowX-ofsx;
     12:BowY:=BowY+ofsy;
     13:AsymmetricBowX:=AsymmetricBowX+ofsx;
     14:AsymmetricBowY:=AsymmetricBowY+ofsy;
     15:begin
          p:=FineTune[FinetuneActPoint];
          p.x :=p.x +localState.rightVec.x *ofsx*0.3+localState.upVec.x *ofsy*0.3;
          p.y :=p.y +localState.rightVec.y *ofsx*0.3+localState.upVec.y *ofsy*0.3;
          FineTune[FinetuneActPoint]:=p;
        end;
     16:begin
          p:=FineTune[FinetuneActPoint];
          p.z :=p.z +ofsy*0.3;
          FineTune[FinetuneActPoint]:=p;
        end;
     17:begin
       FloatResolution:=FloatResolution-ofsy*50;
       Resolution:=round(FloatResolution);
     end;
    end;

    state.CheckRanges;
  end;
  UpdateInfo;
  PaintBox1.Invalidate;
  if Assigned(HostControl)then
    HostControl.Invalidate;
  valueschanged:=true;
end;

procedure TFrmImageShapeAdjust.UpdateCursor;
begin
  case lbOperation.ItemIndex of
    2,4,6,9,11,13:PaintBox1.Cursor:=crSizeWE;
    0,3,7,10,12,14,16,8,17:PaintBox1.Cursor:=crSizeNS;
    1,5,15:PaintBox1.Cursor:=crSizeAll;
    else PaintBox1.Cursor:=crDefault;
  end;
end;

procedure TFrmImageShapeAdjust.MyMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
var dx,dy:integer;
begin
  dx:=x-lx;dy:=y-ly;
  lx:=x;ly:=y;
  if ssLeft in Shift then begin
    doAdjust(dx,dy);
  end else begin
    if lbOperation.ItemIndex in[15,16]then begin
      PaintBox1.Invalidate;
      finetuneActPoint:=localState.GetNearestProjectedControlPoint(x/PaintBox1.Width,y/PaintBox1.Height)
    end;
  end;
end;

procedure TFrmImageShapeAdjust.PaintBox1Paint(Sender: TObject);
var b:tbitmap;
    p:TV2f;
    i:integer;
begin
  if State=nil then exit;
  localState.Assign(State);
  b:=TBitmap.Create;b.pixelformat:=pf32bit;
  b.Width:=PaintBox1.Width;b.height:=PaintBox1.height;
  localState.TransformBitmap32(bTest,b);
  PaintBox1.Canvas.Draw(0,0,B);
  b.Free;

  if lbOperation.ItemIndex in [15,16]then for i:=0 to 8 do begin
    p:=localState.GetProjectedControlPoint(i);
    p.x :=p.x *PaintBox1.Width;
    p.y :=p.y *PaintBox1.Height;
    PaintBox1.Canvas.Ellipse(trunc(p.x )-4,trunc(p.y )-4,trunc(p.x )+5,trunc(p.y )+5);
  end;
end;

procedure TFrmImageShapeAdjust.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  State:=nil;
  HostControl:=nil;
end;

procedure TFrmImageShapeAdjust.FormDestroy(Sender: TObject);
begin
  FreeAndNil(bTest);
end;

procedure TFrmImageShapeAdjust.PaintBox1MouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if state<>nil then FloatResolution:=State.Resolution;
  MyMouseMove(Sender,Shift,x,y);
end;

procedure TFrmImageShapeAdjust.PaintBox1MouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  MyMouseMove(Sender,Shift,x,y);
end;

procedure TFrmImageShapeAdjust.bResetClick(Sender: TObject);
begin
  if Assigned(State)then begin
    State.Reset;
    PaintBox1.Invalidate;
    UpdateInfo;
    UpdateCursor;
  end;
end;

end.
