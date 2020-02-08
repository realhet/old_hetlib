unit het.Controls;

interface

uses Windows, SysUtils, Classes, Controls, StdCtrls, het.Utils, het.Variants,
  het.Objects, het.Parser, het.Bind;

type
  TExprStr=type ansistring;

  THEdit=class(TEdit)
  private
    FExprObj,
    FExprData:TExprStr;
    procedure SetExprData(const Value: TExprStr);
    procedure SetExprObj(const Value: TExprStr);
  public
    procedure CreateWnd; override;
    procedure DestroyWnd; override;
    procedure UpdateBinding;
  published
    property ExprObj:TExprStr read FExprObj write SetExprObj;
    property ExprData:TExprStr read FExprData write SetExprData;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Het',[THEdit]);
end;

{ THEdit }

procedure THEdit.CreateWnd;
begin
  inherited;
end;

procedure THEdit.DestroyWnd;
begin
  inherited;
end;

procedure THEdit.UpdateBinding;
var o:TObject;
    v:Variant;
begin
  if trimf(FExprData)=''then
    UnBind(Self)
  else begin
    if trimf(FExprObj)='' then
      o:=owner
    else begin
      o:=nil;
      try
        v:=Eval(FExprObj,owner);
        if VarIsObject(v)then o:=VarAsObject(v);
      except end;
    end;

    Bind(self,o,FExprData);
  end;
end;

procedure THEdit.SetExprData(const Value: TExprStr);
begin
  FExprData := Value;
  UpdateBinding;
end;

procedure THEdit.SetExprObj(const Value: TExprStr);
begin
  FExprObj:=Value;
  UpdateBinding;
end;

end.