const
  HID_USAGE_PAGE_GENERIC=1;
  HID_USAGE_GENERIC_MOUSE=2;
  RID_HEADER=$10000005;
  RID_INPUT =$10000003;

  RIM_TYPEMOUSE=0;
  RIM_TYPEKEYBOARD=1;
  RIM_TYPEHID=2;

  RIDEV_INPUTSINK=$0000100;

type
  TRAWINPUTDEVICE=record
    usUsagePage,
    usUsage:USHORT;
    dwFlags:DWORD;
    hwndTarget:HWND;
  end;
  PRAWINPUTDEVICE=^TRAWINPUTDEVICE;

  TRAWINPUTHEADER=record
    dwType:DWORD;
    dwSize:DWORD;
    hDevice:THandle;
    wParam:integer;
  end;
  PRAWINPUTHEADER=^TRAWINPUTHEADER;

  TRAWMOUSE=record
    usFlags:USHORT;
    usButtonFlags:USHORT;
    usButtonData:USHORT;
    ulRawButtons:ULONG;
    lLastX:integer;
    lLastY:integer;
    ulExtraInformation:ULONG;
  end;

  TRAWINPUT=record
    header:TRAWINPUTHEADER;
  case byte of
    RIM_TYPEMOUSE:(mouse:TRAWMOUSE);
  end;

function RegisterRawInputDevices(RawInputDevices:PRAWINPUTDEVICE;NumDevices,cbSize:integer):boolean;stdcall;external 'user32.dll';
function GetRawInputData(hRawInput:integer;uiCommand:UINT;pData:pointer;var pcbSize:integer;cbSizeHeader:integer):integer;stdcall;external 'user32.dll';

procedure TFrmMain.initFpsMouse;
var rid:TRAWINPUTDEVICE;
begin
  with rid do begin
    usUsage:=HID_USAGE_GENERIC_MOUSE;
    usUsagePage:=HID_USAGE_PAGE_GENERIC;
    dwFlags:=RIDEV_INPUTSINK;
    hwndTarget:=Handle;
  end;
  if not RegisterRawInputDevices(@rid,1,sizeof(rid))then
    raise Exception.Create('RegisterRawInputDevices() failed');
end;

procedure TFrmMain.OnMouse(sender: TObject);
begin
{  if ssRight in ms.Act.Shift then
    with ms.Delta.Screen do cam.Turn(-x*0.003,y*0.003);}
end;

procedure TFrmMain.WMINPUT(var m: TMessage);
  function filter(n:integer):single;
  begin
    if n<0 then exit(-filter(-n));
    if n>2 then n:=n*2;
    if n>8 then n:=n*2;
    result:=n*0.001;
  end;

var buf:array[0..39]of byte;
    rawinput:TRAWINPUT absolute buf;
    siz:integer;
begin
  siz:=sizeof(buf);
  if GetRawInputData(m.LParam,RID_INPUT,@buf,siz,sizeof(TRAWINPUTHEADER))>0 then begin
    if rawinput.header.dwType=RIM_TYPEMOUSE then begin
      if FPSMouseMode then begin
        with rawinput.mouse do cam.Turn(-filter(lLastX),filter(lLastY));
{        with ClientToScreen(point(clientwidth div 2,ClientHeight div 2))do
          SetCursorPos(x,y);}
      end;
    end;
  end;
end;
