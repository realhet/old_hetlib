unit UFrmConstProperties;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, UCircuitArithmetic;

type
  TFrmConstProperties = class(TForm)
    eConst: TEdit;
    Value: TLabel;
    eDirty: TEdit;
    Label1: TLabel;
    bOk: TBitBtn;
    bCancel: TBitBtn;
    procedure eDirtyChange(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FrmConstProperties: TFrmConstProperties;

function SetConstGateProperties(var AConstant,ADirtyMask:Cardinal):boolean;overload;
function SetConstGateProperties(const g:TGate):boolean;overload;

implementation

{$R *.dfm}

function SetConstGateProperties(var AConstant,ADirtyMask:Cardinal):boolean;overload;
begin with FrmConstProperties do begin
  eConst.Text:='$'+IntToHex(AConstant,8);
  eDirty.Text:='$'+IntToHex(ADirtyMask,8);
  eConst.SelectAll;
  ActiveControl:=eConst;
  result:=ShowModal=mrOk;
  if result then begin
    AConstant:=StrToInt(eConst.Text);
    ADirtyMask:=StrToInt(eDirty.Text);
  end;
end;end;

function SetConstGateProperties(const g:TGate):boolean;overload;
var c,d:cardinal;
begin
  c:=g.Constant;
  d:=g.DirtyMask;
  result:=SetConstGateProperties(c,d);
  if result then begin
    g.Constant:=c;
    g.DirtyMask:=d;
  end;
end;

procedure TFrmConstProperties.eDirtyChange(Sender: TObject);

  function chk(e:TEdit):boolean;var i:integer;
  begin
    result:=tryStrToInt(e.Text,i);
    with e.Font do if result then Color:=clWindowText else Color:=clRed;
  end;

begin
  bOk.Enabled:=chk(eConst)and chk(eDirty)
end;

end.
