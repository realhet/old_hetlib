unit DSEnumComboBox;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, DirectSound;

type
  TDSEnumComboBox = class(TComboBox)
  private
    { Private declarations }
    guids:array[0..31]of pguid;
    Function GetDevName:ansistring;
    Procedure SetDevName(s:ansistring);
  protected
    { Protected declarations }
    procedure CreateWnd;override;
  public
    { Public declarations }
  published
    { Published declarations }
    Procedure Enumerate;
    Function DeviceGuid:PGuid;
    property DeviceName:ansistring read GetDevName write setdevname;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Het', [TDSEnumComboBox]);
end;

function DSEnumProc(guid:PGUID;lpszDesc,lpszDrvName:PAnsiChar;self:pointer):longbool;stdcall;
var temp:pguid;
begin
//  if guid=nil then temp:=nil else begin new(temp);temp^:=guid^ end;
  temp:=guid;
  if Temp<>nil then begin
    with TDSEnumComboBox(self^) do begin
      Items.Add(lpszDesc);
      Guids[Items.Count-1]:=temp;
    end;
  end;
  Result:=true;
end;

Procedure TDSEnumComboBox.Enumerate;
var last:string;
begin
  last:=DeviceName;
  Items.Clear;
  DirectSoundEnumerateA(DSEnumProc, @Self);
  DeviceName:=Last;
  Change;
end;

Function TDSEnumComboBox.DeviceGuid;
begin
  if itemindex<0 then result:=nil
                 else result:=Guids[ItemIndex];
end;

Function TDSEnumComboBox.GetDevName;
begin
  if itemindex=-1 then result:=''
                  else result:=Items.Strings[itemindex];
end;

Procedure TDSEnumComboBox.SetDevName;
begin
  ItemIndex:=Items.IndexOf(s);
end;

procedure TDSEnumComboBox.CreateWnd;
begin
  inherited CreateWnd;
  Enumerate;
end;

end.
