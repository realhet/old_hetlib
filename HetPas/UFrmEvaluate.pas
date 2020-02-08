unit UFrmEvaluate;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, het.utils, het.Objects, het.Parser;

type
  TFrmEvaluate = class(TForm)
    Label1: TLabel;
    cbExpression: TComboBoxEx;
    mResult: TMemo;
    Label2: TLabel;
    procedure cbExpressionKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure Execute;
  end;

var
  FrmEvaluate: TFrmEvaluate;

implementation

{$R *.dfm}

procedure TFrmEvaluate.cbExpressionKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var e:ansistring;
    i:integer;
    found:boolean;
begin
  if Key=VK_RETURN then begin
    e:=cbExpression.Text;
    found:=false;
    if(e<>'')then for i:=0 to cbExpression.Items.Count-1 do
      if cmp(cbExpression.Items[i],e)=0 then found:=true;
    if not found then cbExpression.Items.Append(e);

    if e<>'' then mResult.Text:=Eval(e,nil)
             else mResult.Text:='';
  end;
end;

procedure TFrmEvaluate.Execute;
begin
  cbExpression.SetFocus;
  cbExpression.SelectAll;
  ShowModal;
end;

procedure TFrmEvaluate.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key=VK_ESCAPE then ModalResult:=mrCancel;
end;

end.
