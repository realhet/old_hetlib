unit UFrmBitmapViewer;       //unsCal

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, het.Utils, het.Gfx, unsSystem, het.Parser, het.Variants;

type
  TFrmBitmapViewer = class(TForm)
    procedure FormPaint(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    bmp:TBitmap;
    procedure Execute(const ABmp:TBitmap);
  end;

var
  FrmBitmapViewer: TFrmBitmapViewer;

implementation

{$R *.dfm}

{ TFrmBitmapViewer }

procedure TFrmBitmapViewer.FormCreate(Sender: TObject);
begin
  nsSystem.AddClass(TBitmap);
  nsSystem.AddFunction('DisplayBitmap(bmp)',function(const p:TVariantArray):variant
    begin
      if FrmBitmapViewer<>nil then
        FrmBitmapViewer.Execute(TBitmap(VarAsObject(p[0],TBitmap)))
      else
        MessageBox('DisplayBitmap failed because there is no active bitmapViewer.','DisplayBitmap',0);
    end);
end;

procedure TFrmBitmapViewer.FormDestroy(Sender: TObject);
begin
  //remove function from namespace
end;

procedure TFrmBitmapViewer.Execute(const ABmp:TBitmap);
begin
  bmp:=TBitmap.CreateClone(ABmp);

  ClientWidth:=bmp.Width;
  ClientHeight:=bmp.Height;

  ShowModal;
  FreeAndNil(bmp);
end;

procedure TFrmBitmapViewer.FormPaint(Sender: TObject);
begin
  if bmp<>nil then
    Canvas.Draw(0,0,bmp);
end;

end.
