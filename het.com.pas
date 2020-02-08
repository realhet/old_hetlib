unit het.Com;

interface

uses windows, sysutils, variants, classes, ExtCtrls, math, het.Utils,
  het.Objects, syncobjs, registry;

(*
{#define Field(name,type) private F##name:type;procedure Set##name(const Value:type);published property name:type read F##name write Set##name }
{#define FieldReadOnly(name,type) private F##name:type;published property name:type read F##name }
{#define FieldCalculated(name,type) private function Get##name:type;procedure Set##name(const Value:type);published property name:type read Get##name write Set##name }
*)
type
  TComPort=class;
  TComThread=class(TThread)protected FOwner:TComPort;procedure Execute;override;end;

  TCustomCOMHandler=procedure(Port:TComPort)of object;

  TParity=(paNone,paOdd,paEven,paMark,paSpace);
  TStopBits=(sbOne,sbOnePointFive,sbTwo);
  TComPortState=(psOffline,psOnline,psCreateError,psWriteError);
  TComPort=class(THetObject)
{    fieldReadOnly(Id,integer);
    fieldReadOnly(Exists,boolean);
    fieldReadOnly(Description,ansistring);
    fieldReadOnly(IconIndex,integer);
    field(Baud,integer) default 9600;
    field(Bits,byte) default 8;
    field(Parity,TParity);
    field(StopBits,TStopBits);
    fieldCalculated(Config,ansistring) stored false;
    field(Active,boolean);}
    private FId:integer;published property Id:integer read FId;
    private FExists:boolean;published property Exists:boolean read FExists;
    private FDescription:ansistring;published property Description:ansistring read FDescription;
    private FIconIndex:integer;published property IconIndex:integer read FIconIndex;
    private FBaud:integer;procedure SetBaud(const Value:integer);published property Baud:integer read FBaud write SetBaud default 9600;
    private FBits:byte;procedure SetBits(const Value:byte);published property Bits:byte read FBits write SetBits default 8;
    private FParity:TParity;procedure SetParity(const Value:TParity);published property Parity:TParity read FParity write SetParity;
    private FStopBits:TStopBits;procedure SetStopBits(const Value:TStopBits);published property StopBits:TStopBits read FStopBits write SetStopBits;
    private function GetConfig:ansistring;procedure SetConfig(const Value:ansistring);published property Config:ansistring read GetConfig write SetConfig stored false;
    private FActive:boolean;procedure SetActive(const Value:boolean);published property Active:boolean read FActive write SetActive;
  private
    FHandle:integer;
    FBuff:RawByteString;
    FOutBuff,FInBuff:ansistring;
    FCritSec:TCriticalSection;
    FChanged:boolean;
    FThrd:TComThread;
    FState:TComPortState;
    function CritSec:TCriticalSection;
    procedure thrdStart;
    procedure thrdStop;
    procedure thrdUpdate;
    procedure ReadConfigFromRegistry;
    procedure WriteConfigToRegistry;
    function GetInBuff:ansistring;
    procedure SetOutBuff(const Value:ansistring);
  public
    procedure AppendToInBuff(const s: ansistring);
    function FetchOutBuff(const MaxSize: integer=1024): ansistring;
    function TryRead: ansistring;
    procedure SetState(const st:TComPortState);
    property Handle:integer read FHandle;
  public
    CustomCOMHandler:TCustomCOMHandler;
    constructor Create(const AOwner:THetObject);override;
    destructor Destroy;override;
    procedure ObjectChanged(const AObj:THetObject;const AChangeType:TChangeType);override;
    property InBuff:ansistring read GetInBuff;
    property OutBuff:ansistring write SetOutBuff;
    property State:TComPortState read FState;
  public //extensibility
    property Changed:boolean read FChanged;
  end;

  TComPorts=class(THetList<TComPort>)
  private
    FTimer:TTimer;
    procedure OnTimer(sender:TObject);
    procedure UpdateDeviceInfo;
    procedure Initialize;
    function FindByWildcard(const Value:variant):TComPort;
  public
    destructor Destroy;override;
    property ByWildCard[const Value:variant]:TComPort read FindByWildCard;default;
  end;

const ComPorts:TComPorts=nil;
const MaxComPort=64;

implementation

uses
  het.FileSys;

procedure TComThread.Execute;
begin
  while not Terminated do begin
    FOwner.thrdUpdate;
  end;
end;

constructor TComPort.Create(const AOwner:THetObject);
begin
  inherited;
end;

destructor TComPort.Destroy;
begin
  Active:=false;
  FreeAndNil(FCritSec);
  WriteConfigToRegistry;
  inherited;
end;

function TComPort.CritSec:TCriticalSection;
begin
  if FCritSec=nil then FCritSec:=TCriticalSection.Create;
  result:=FCritSec;
end;

procedure TComPort.thrdStart;
begin
  if FThrd<>nil then exit;
  FThrd:=TComThread.Create(true);
  FThrd.FOwner:=self;
  FThrd.Start;
end;

procedure TComPort.thrdStop;
begin
  if FThrd=nil then exit;
  FThrd.Terminate;
  FThrd.WaitFor;
  FreeAndNil(FThrd);
end;

{$O-}
procedure TComPort.SetBaud;begin end;
procedure TComPort.SetBits;begin end;
procedure TComPort.SetParity;begin end;
procedure TComPort.SetStopBits;begin end;
procedure TComPort.SetActive;begin end;
{$O+}

procedure TComPort.SetState(const st: TComPortState);
begin
  FState:=st;
end;

const
  ParityStr  :ansistring='N,O,E,M,S';
  ParityStrLC:ansistring='n,o,e,m,s';
  StopBitsStr:ansistring='1,1.5,2';

function TComPort.GetConfig:ansistring;
var s:ansistring;
begin
  result:=tostr(Baud)+' '+tostr(Bits);

  s:=ListItem(ParityStr,ord(Parity),',');
  if s='' then s:='?';
  result:=result+s;

  s:=ListItem(StopBitsStr,ord(StopBits),',');
  if s='' then s:='?';
  result:=result+s;
end;

procedure TComPort.SetConfig;
var s:ansistring;
begin
  Baud:=StrToIntDef(listitem(Value,0,' '),0);

  s:=listitem(Value,1,' ');
  Bits:=EnsureRange(StrToIntDef(CharN(s,1),8),5,8);
  Parity:=TParity(EnsureRange(FindListItem(CharN(s,2),ParityStr,','),0,4));
  StopBits:=TStopBits(EnsureRange(FindListItem(copy(s,3,$ff),StopBitsStr,','),0,2));
end;

const regkeyPorts='SOFTWARE\Microsoft\Windows NT\CurrentVersion\Ports';

procedure TComPort.ReadConfigFromRegistry;
var r:TRegIniFile;
    s:ansistring;
begin
  r:=TRegIniFile.Create('');
  try
    r.RootKey:=HKEY_LOCAL_MACHINE;
    if r.OpenKeyReadOnly(regkeyPorts)then begin
      s:=r.ReadString('','COM'+IntToStr(FID)+':','');
      if s<>'' then begin
        Baud:=StrToIntDef(ListItem(s,0,','),9600);
        Parity:=TParity(EnsureRange(FindListItem(listitem(s,1,','),ParityStr,','),0,4));
        Bits:=EnsureRange(StrToIntDef(ListItem(s,2,','),8),5,8);
        StopBits:=TStopBits(EnsureRange(FindListItem(ListItem(s,3,','),StopBitsStr,','),0,2));
      end;
    end;
  finally
    r.Free;
  end;
end;

procedure TComPort.WriteConfigToRegistry;
var r:TRegIniFile;
    s:string;
begin
  r:=TRegIniFile.Create('');
  try
    r.RootKey:=HKEY_LOCAL_MACHINE;
    if r.OpenKey(regkeyPorts,true)then begin
      s:=format('%d,%s,%d,%s',[Baud,ListItem(ParityStrLC,ord(Parity),','),Bits,ListItem(StopBitsStr,ord(StopBits),',')]);
      r.WriteString('','COM'+IntToStr(FID)+':',s);
    end;
  finally
    r.Free;
  end;
end;

procedure TComPort.ObjectChanged(const AObj:THetObject;const AChangeType:TChangeType);
begin
  FChanged:=true;

  if Active then thrdStart
            else thrdStop;
end;

procedure TComPort.AppendToInBuff(const s:ansistring);
begin
  if s='' then exit;
  CritSec.Enter;
  try
    FInBuff:=FInBuff+s;
  finally
    CritSec.Leave;
  end;
end;

function TComPort.FetchOutBuff(const MaxSize:integer=1024):ansistring;
begin
  if maxsize<0 then exit('');
  CritSec.Enter;
  try
    Result:=Copy(FOutBuff,1,MaxSize);
    Delete(FOutBuff,1,MaxSize);
  finally
    CritSec.Leave;
  end;
end;

function TComPort.TryRead:ansistring;
var br:cardinal;
begin
  setlength(FBuff,1024*1024);
  if ReadFile(FHandle,FBuff[1],length(FBuff),br,nil)and(br>0)then result:=copy(FBuff,1,br)
                                                             else result:='';
end;

procedure DefaultComHandler(port:TComPort);
var s:ansistring;
    pos,len:integer;
    bw:cardinal;
begin with Port do begin
  AppendToInBuff(TryRead);

  //input latch
  s:=FetchOutBuff(1024);

  pos:=1;
  while(pos<=length(s))do begin
    len:=length(s)-pos+1;
    if WriteFile(Handle,s[pos],len,bw,nil)then begin
      pos:=pos+integer(bw);
      SetState(psOnline);
    end else begin
      SetState(psWriteError);
    end;
    if not active or Changed then exit;

    AppendToInBuff(TryRead);
  end;
end;end;


procedure TComPort.thrdUpdate;
var wDCB:DCB;
    wCT:COMMTIMEOUTS;
begin
  if Active and not FChanged then begin
    if(FHandle=0){and Exists} then begin
      FHandle:=CreateFile(pchar('\\.\COM'+inttostr(Id)),GENERIC_READ or GENERIC_WRITE,0,nil,OPEN_EXISTING,0,0);
      if integer(FHandle)=-1 then begin
        FHandle:=0;
        FState:=psCreateError;
        sleep(100);
      end else begin
        GetCommState(FHandle,wDCB);
        wDCB.BaudRate:=Baud;
        wDCB.Parity:=Ord(Parity);
        wDCB.StopBits:=Ord(StopBits);
        wDCB.ByteSize:=Bits;
        wDCB.Flags:=0;
        SetCommState(FHandle,wDCB);

        wCT.ReadIntervalTimeout:=$FFFFFFFF;
        wCT.ReadTotalTimeoutMultiplier:=0;
        wCT.ReadTotalTimeoutConstant:=0;
        wCT.WriteTotalTimeoutMultiplier:=1;
        wCT.WriteTotalTimeoutConstant:=500;
        SetCommTimeouts(FHandle,wCT);

        WriteConfigToRegistry;//sikeres open

        FState:=psOnline;
      end;
    end;
  end else begin
    if FHandle<>0 then begin
      CloseHandle(FHandle);
      FHandle:=0;
      FState:=psOffline;
    end;
  end;
  FChanged:=false;

  if FHandle<>0 then begin

    if Assigned(CustomCOMHandler)then begin
      CustomCOMHandler(self);
    end else begin
      DefaultComHandler(self);
    end;

  end;
  sleep(20);
end;

function TComPort.GetInBuff:ansistring;
begin
  CritSec.Enter;
  try
    result:=FInBuff;
    FInBuff:='';
  finally
    CritSec.Leave;
  end;
end;

procedure TComPort.SetOutBuff(const Value:ansistring);
begin
  if Value='' then exit;

  CritSec.Enter;
  try
    FOutBuff:=FOutBuff+Value;
  finally
    CritSec.Leave;
  end;
end;

procedure TComPorts.Initialize;
var i:integer;
begin
  Clear;
  for i:=1 to MaxComPort do with TComPort.Create(self) do begin
    FID:=i;
    ReadConfigFromRegistry;
  end;

  FTimer:=TTimer.Create(nil);
  FTimer.Interval:=1000;
  FTimer.Enabled:=true;
  FTimer.OnTimer:=OnTimer;

  OnTimer(nil);
//  FileWriteBytes('c:\a.a',SaveToBytes(stDfm));
end;

destructor TComPorts.Destroy;
begin
  FreeAndNil(FTimer);
  inherited;
end;

procedure TComPorts.UpdateDeviceInfo;

  function DecodePortName(const name:string;out com:integer):boolean;
  begin
    result:=false;
    if copy(name,1,3)='COM'then begin
      com:=strtointdef(copy(name,4,3),0);
      result:=InRange(com,1,Count);
    end;
  end;

  var r:TRegIniFile;
      sl:TStringList;
      ports:array of record
        DevName,Desc:ansistring;
        icon:integer;
        ex:boolean;
      end;

  function FindExistingPorts:boolean;
  var s:string;
      i,p:integer;
  begin
    result:=false;

    r.RootKey:=HKEY_LOCAL_MACHINE;
    if not r.OpenKeyReadOnly('HARDWARE\DEVICEMAP\SERIALCOMM')then exit;
    r.ReadSection('',sl);
    for s in sl do if DecodePortName(r.ReadString('',s,''),p)then with ports[p-1]do begin
      ex:=true;
      DevName:=replacef('\Device\','',s,[roIgnoreCase]);
    end;
    r.CloseKey;

    for i:=0 to high(ports)do
      if(ByIndex[i].Exists<>ports[i].ex)then begin result:=true;break end;
  end;

  procedure FindDeviceNames(const path:string;AIcon:integer);
  var sect:string;
      p:integer;
  begin
    r.RootKey:=HKEY_LOCAL_MACHINE;
    if not r.OpenKeyReadOnly(path)then exit;
    r.ReadSections(sl);
    for sect in sl do if DecodePortName(r.ReadString(sect,'AssignedPortForQCDevice',''),p)then begin
      ports[p-1].Desc:=r.ReadString(sect,'DriverDesc','');
      ports[p-1].Icon:=AIcon;
    end;
    r.CloseKey;
  end;
var i:integer;
    s:ansistring;
begin
  if Count=0 then exit;

  setlength(ports,Count);
  fillchar(ports[0],length(ports)*sizeof(ports[0]),0);

  r:=TRegIniFile.Create('');
  sl:=TStringList.Create;
  try
    if FindExistingPorts then begin
      FindDeviceNames('SYSTEM\CurrentControlSet\Control\Class\{4D36E978-E325-11CE-BFC1-08002BE10318}',2);
      FindDeviceNames('SYSTEM\CurrentControlSet\Control\Class\{4D36E96D-E325-11CE-BFC1-08002BE10318}',1);

      for i:=0 to high(ports)do with ByIndex[i],ports[i] do begin
        if(Exists<>ex)then begin
          FExists:=ex;
          NotifyChange;
        end;
        if ex then begin
          if Desc<>'' then s:=Desc else begin
            if IsWild2('serial*',DevName) then s:='Communications Port' else
            if IsWild2('vserial*',DevName) then begin s:='Virtual Serial Port';Icon:=3;end else
              s:=DevName;
          end;
          if(Description<>s)or(IconIndex<>Icon)then begin
            FDescription:=s;
            FIconIndex:=Icon;
            NotifyChange;
          end;
        end;
      end;
    end;
  finally
    sl.Free;
    r.Free;
  end;
end;

procedure TComPorts.OnTimer(sender:TObject);
begin
  UpdateDeviceInfo;
end;

function TComPorts.FindByWildcard(const Value:variant):TComPort;
  function FullDesc(const o:TComPort):ansistring;
  begin result:=o.Description+' (COM'+toStr(o.Id)+')';end;

var s:ansistring;
    i:integer;
begin
  if VarIsStr(Value)then begin
    s:=ansistring(Value);
    for i:=0 to count-1 do if Pos(s,FullDesc(ByIndex[i]),[poIgnoreCase,poWholeWords])>0 then exit(ByIndex[i]);
    for i:=0 to count-1 do if Pos(s,FullDesc(ByIndex[i]),[poIgnoreCase])>0 then exit(ByIndex[i]);
  end else if VarIsOrdinal(Value) then begin
    i:=Value;
    if InRange(i,1,Count)then
      exit(ByIndex[i-1]);
  end;
  result:=nil;
end;

initialization
  TComPorts(pointer(@ComPorts)^):=TComPorts.Create(nil);
  ComPorts.Initialize;
finalization
  FreeAndNil(pointer(@ComPorts)^);
end.
