unit UserPort;

interface
uses windows, sysutils, winsvc, classes;

function UserPortInit:boolean;
function UserPortInitPoll:boolean;

procedure outportw(portid : integer; value : integer);
procedure outportb(portid : integer; value : BYTE);
function inportb(portid : integer) : byte;
function inportw(portid : integer) : integer;

implementation

var DriverInitialized:boolean=false;

const DriverName:PAnsiChar='UserPort';

type EUserPort=class(Exception);

function OldWindows:boolean;
var osvi:OSVERSIONINFO;
begin
  GetVersionEx(osvi);
  result:=((osvi.dwPlatformId=VER_PLATFORM_WIN32_WINDOWS)or(osvi.dwPlatformId=VER_PLATFORM_WIN32s))
end;

function StopDriver:boolean;
var
  schService,schSCManager:SC_HANDLE;
  serviceStatus:SERVICE_STATUS;
begin
  DriverInitialized:=false;
  if OldWindows then begin DriverInitialized:=true;result:=true;exit end;

  result:=false;

  schSCManager:=OpenSCManager (nil,                 // machine (NULL == local)
                               nil,                 // database (NULL == default)
                               SC_MANAGER_ALL_ACCESS // access required
                               );
  if schSCManager=0 then exit;

  schService:=OpenServiceA(schSCManager,
                           DriverName,
                           SERVICE_ALL_ACCESS
                           );

  if schService=0 then begin
    CloseServiceHandle(schSCManager);
    exit;
  end;

  ControlService(schService, SERVICE_CONTROL_STOP, serviceStatus);

  DeleteService(schService);

  CloseServiceHandle(schService);
  CloseServiceHandle(schSCManager);
  result:=true;
end;

function StartUpIoPorts(PortToAccess : integer) : boolean;
const maxTries=25;
Var {hUserPort : THandle;}
    tries:integer;
Begin
  {hUserPort := }CreateFile('\\.\UserPort', GENERIC_READ, 0, nil,OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
//  CloseHandle(hUserPort); // Activate the driver

  tries:=maxTries;
  while tries>0 do begin
    try inportb(PortToAccess);  // Try to access the given port address
      exit(true);
    except
      dec(tries);
    end;
    Sleep(200); // We must make a process switch
  end;
//  raise EUserPort.Create('Cannot start UserPort.sys. ('+inttostr(MaxTries)+'x times failed to read port $61)');
  result:=false;
end;

function StartDriver:boolean;
var schSCManager,schService:SC_HANDLE;
    DriverFileName,args:PAnsiChar;
    Err:integer;

    key:HKEY;
    wType:DWORD;
    allPort,throughPort:array[0..$80-1]of byte;
begin
  if OldWindows then begin result:=true;exit end;
//  result:=false;

  fillchar(allPort,sizeof(allPort),0);
  fillchar(throughPort,sizeof(throughPort),0);
  if RegCreateKeyEx(HKEY_LOCAL_MACHINE,'Software\UserPort',0,'',REG_OPTION_NON_VOLATILE,KEY_ALL_ACCESS,nil,Key,@wType)=ERROR_SUCCESS then begin
    RegSetValueEx(Key,'AllProcessesIOPM',0,REG_BINARY,@allPort,sizeof(allPort));
    RegSetValueEx(Key,'ThroughCreateFileIOPM',0,REG_BINARY,@ThroughPort,sizeof(ThroughPort));
    RegCloseKey(Key);
//    sleep(200);
  end else
    raise EUserPort.Create('Unable to write into registry "HKEY_LOCAL_MACHINE,Software\UserPort\"');

  DriverFileName:=PAnsiChar(AnsiString(ExtractFilePath(ParamStr(0))+'UserPort.sys'));

  if not FileExists(DriverFileName)then
    EUserPort.Create('File not found "'+DriverFileName+'"');

  schSCManager:=OpenSCManager (Nil,                 // machine (NULL == local)
                               Nil,                 // database (NULL == default)
                               SC_MANAGER_ALL_ACCESS // access required
                               );

  if schSCManager=0 then begin
    if GetLastError=ERROR_ACCESS_DENIED then
      raise EUserPort.Create('You are not authorized to install drivers.')
    else
      raise EUserPort.Create('Unable to start service manager. (win2k or higher needed)');
  end;

  schService:=CreateServiceA (schSCManager,          // SCManager database
                              DriverName,            // name of service
                              DriverName,            // name to display
                              SERVICE_START,         //SERVICE_ALL_ACCESS,    // desired access
                              SERVICE_KERNEL_DRIVER, // service type
                              SERVICE_SYSTEM_START,  // start type
                              SERVICE_ERROR_NORMAL,  // error control type
                              DriverFileName,        // service's binary
                              nil,                   // no load ordering group
                              nil,                   // no tag identifier
                              nil,                   // no dependencies
                              nil,                   // LocalSystem account
                              nil                    // no password
                              );

  if schService=0 then begin
    Err:=GetLastError;
    CloseServiceHandle(schSCManager);
    case Err of
      ERROR_SERVICE_EXISTS:begin result:=StartUpIoPorts($61);DriverInitialized:=result;exit;end;
      ERROR_ACCESS_DENIED:raise EUserPort.Create('You are not authorized to install drivers.');
      else raise EUserPort.Create('Unable to start driver.');
    end;
  end;

  args:='';
  StartServiceA(schService,    // service identifier
               0,             // number of arguments
               args           // pointer to arguments
               );

  CloseServiceHandle(schService);
  CloseServiceHandle(schSCManager);

  result:=StartUpIoPorts($61);
  DriverInitialized:=result;
end;

procedure StartIfNeeded;
begin
  if not DriverInitialized then
end;

procedure outportw(portid : integer; value : integer);
Begin
  asm
    mov edx,portid;
    mov eax,value;
    out dx,ax;
  end;
end;

procedure outportb(portid : integer; value : BYTE);
Begin
  asm
    mov edx,portid
    mov al,value
    out dx,al
  end;
end;

function inportb(portid : integer) : byte;
Var value : byte;
Begin
  asm
    mov edx,portid
    in al,dx
    mov value,al
  end;
  inportb := value;
end;

function inportw(portid : integer) : integer;
Var value : integer;
Begin
  value := 0;
  asm
    mov edx,portid
    in ax,dx
    mov value,eax
  end;
  inportw := value;
end;


function UserPortInit:boolean;
begin
{  if DriverInitialized then begin result:=true;exit;end;
  StopDriver;
  result:=StartDriver;}

  result:=StartUpIoPorts($61);
end;

function UserPortInitPoll:boolean;
Var hUserPort : THandle;
Begin
  try inportb($61);  // Try to access the given port address
    exit(true);
  except
    result:=false;
  end;

  hUserPort := CreateFile('\\.\UserPort', GENERIC_READ, 0, nil,OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  CloseHandle(hUserPort); // Activate the driver
end;


initialization
finalization
{  if DriverInitialized then
    StopDriver;}
end.