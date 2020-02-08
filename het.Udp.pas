unit het.UDP; //hetutils/         het.opensave

interface
uses
  windows, messages, SysUtils, Variants, Classes, winsock, extctrls, het.Utils;

const HetUDPdefaultport=14569;

type
  THetUDPClient=class
    Name:ansistring;
    Ip:u_long;
    LastReceiveTime:TDateTime;
  end;

  THetUDP=class;
  TOnHetUDPConnectionChanged=procedure(sender:THetUDP)of object;
  TOnHetUDPReceive=procedure(sender:THetUDP;const client:THetUdpClient;const data:rawByteString)of object;

  THetUDP=class(TComponent)
  private
    FActive: boolean;
    FWnd:hwnd;
    addrIn:TSockAddrIn;
    sock:TSocket;
    FPort: integer;
    FServer: boolean;
    FServerIP,FLastIP:u_long;
    FMsg:rawByteString;
    FMsgLen:integer;
    FOnReceive:TOnHetUDPReceive;
    FOnConnectionChanged: TOnHetUDPConnectionChanged;
    FClients:TArray<THetUDPClient>;
    FMultiBlock:RawByteString;
    FForcedServerHostName: ansistring;
    FPeerName:ansistring;
    LastSrvReceiveTime:TDateTime;
    function CreateHWND:hwnd;
    procedure SetActive(const Value: boolean);
    procedure SetPort(const Value: integer);
    procedure DoReceive;
    procedure SetServer(const Value: boolean);
    procedure StdClientReceive;
    procedure StdServerReceive;
    procedure DoConnectionChanged;
    procedure OnTimer;
    function SendSingle(addr: u_long; const data: rawByteString; timeoutMs: integer=0): boolean;
    procedure SetForcedServerHostName(const Value: ansistring);
    function GetPeerName: ansistring;
    procedure SetPeerName(const Value: ansistring);
  public
    LastError:integer;
    recvCnt,recvBytes:integer;
    sentCnt,sentBytes,sendErrors:integer;
    BroadcastSucks:boolean;//true if cannot send to inet addr 255.255.255.255.
                           //Server will send packets one after each to clients
    constructor Create(AOwner:TComponent);override;
    destructor Destroy;override;
    function Open:boolean;
    procedure Close;
    function ServerIP:cardinal;
    function Broadcast(const data:rawByteString;timeoutMs:integer=0):boolean;
    function Send(addr: u_long; const data:ansistring;timeoutMs:integer=0):boolean;
    function SendByName(const name:ansistring;const data: ansistring;timeoutMs:integer=0):boolean;
    function SendToServer(const data: ansistring;timeoutMs:integer=0):boolean;
    function GetStatistics:ansistring;

    Function ClientByIp(const AIp:u_long):THetUDPClient;
    function ClientByName(const AName: ansistring): THetUDPClient;
    Function AddClient(const AName:ansistring;const AIp:u_long):THetUdpClient;
    procedure DeleteClient(const AClient:THetUdpClient);
    procedure DeleteAllClients;

    function ClientCount:integer;
    function ClientNameList:ansistring;
    property PeerName:ansistring read GetPeerName write SetPeerName;
  published
    property Port:integer read FPort write SetPort default hetudpdefaultport;
    property Server:boolean read FServer write SetServer default false;
    property OnReceive:TOnHetUDPReceive read FOnReceive write FOnReceive;
    property OnConnectionChanged:TOnHetUDPConnectionChanged read FOnConnectionChanged write FOnConnectionChanged;
    property Active:boolean read FActive write SetActive default false;
    property ForcedServerHostName:ansistring read FForcedServerHostName write SetForcedServerHostName;
  end;

function IPAddr2Str(ip:u_long):ansistring;

function GetIPFromHost(var HostName, IPaddr, WSAErr: string): Boolean;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Het',[THetUDP]);
end;

function GetIPFromHost(var HostName, IPaddr, WSAErr: string): Boolean;
var
  HEnt: pHostEnt;
  Name: array[0..100] of AnsiChar;
  WSAData: TWSAData;
  i: Integer;
begin
  Result := False;
  if WSAStartup($0101, WSAData) <> 0 then begin
    WSAErr := 'Winsock is not responding."';
    Exit;
  end;
  IPaddr := '';
  if GetHostName(@Name, SizeOf(Name)) = 0 then
  begin
    HostName := Name;
    HEnt := GetHostByName(@Name);
    for i := 0 to HEnt^.h_length - 1 do
     IPaddr :=
      Concat(IPaddr,
      IntToStr(Ord(HEnt^.h_addr_list^[i])) + '.');
    SetLength(IPaddr, Length(IPaddr) - 1);
    Result := True;
  end
  else begin
   case WSAGetLastError of
    WSANOTINITIALISED:WSAErr:='WSANotInitialised';
    WSAENETDOWN      :WSAErr:='WSAENetDown';
    WSAEINPROGRESS   :WSAErr:='WSAEInProgress';
   end;
  end;
end;


const
  WM_sock=WM_User+$101;
  UDPmaxMsgLength=1500;
  UDPsysTimeOut=1000;
  UDPTimerInterval=1000;     //Clients pinging the server
  UDPClientMaxIdleTime=5000;  //Servers kick the clients if no messages received

Function UdpMessageProc(WindowHandle: HWND; Msg: Cardinal; wParam, lParam: Integer): Integer; StdCall;
var udp:THetUDP;
Begin
  if msg=WM_sock then begin
    result:=1;//nem mintha szamitana
    udp:=THetUdp(GetWindowLongA(WindowHandle,0));
    udp.DoReceive;
  end else if msg=WM_TIMER then begin
    result:=1;//nem mintha szamitana
    udp:=THetUdp(GetWindowLongA(WindowHandle,0));
    udp.OnTimer;
  end else
    result:=DefWindowProcA(WindowHandle, Msg, wParam, lParam);
End;

function THetUDP.SendToServer(const data: ansistring; timeoutMs: integer): boolean;
begin
  if FServerIP=0 then result:=false
                 else result:=send(FServerIP,data,timeoutMs);
end;

function THetUDP.BroadCast(const data: rawByteString;timeoutMs:integer=0):boolean;
var i:integer;
begin
  if BroadcastSucks then begin
    result:=true;
    for i:=0 to High(FClients)do
      result:=Send(FClients[i].Ip,data,timeoutMs);//what if not all succeeded?...
  end else begin
    result:=Send(integer(INADDR_BROADCAST),data,timeoutMs);
    //if broadcast suxx, try it manually
    if not result and(LastError=10065)and not BroadcastSucks then begin
      BroadcastSucks:=true;
      Broadcast(data,timeoutMs);
      BroadcastSucks:=false;//!!!!!!!!! ez nem vegleges!!!!!
    end;
  end;
end;

function THetUDP.SendSingle(addr:u_long;const data:rawByteString;timeoutMs:integer=0):boolean;
var addrOut:TSockAddrIn;
    addrOutlen:integer;
    sockOPT: LongBool;
    res:integer;
    p:pbyte;
    len:integer;
begin
  fillchar(addrOut,sizeof(addrOut),0);
  result:=false;
  if not Active then exit;

  if FServer then addrOut.sin_port:=htons(port)
             else addrOut.sin_port:=htons(port+1);
  sockOpt:=addr=u_long(INADDR_BROADCAST);
  SetSockOpt(sock, SOL_SOCKET, SO_BROADCAST, pAnsiChar(@SockOpt), SizeOf(SockOpt));

  addrOut.sin_family:=AF_INET;
  addrOut.sin_addr.S_addr:=addr;
  fillchar(addrOut.sin_zero,sizeof(addrOut.sin_zero),0);
  addrOutLen:=sizeof(addrOut);

  len:=length(data);
  if len>0 then p:=@data[1]
           else p:=nil;
  repeat
    res:=sendto(sock, p^, length(data), 0, addrOut, addrOutLen);
    if res<0 then begin//error
      res:=WSAGetLastError;
      //raise Exception.Create(inttostr(res));
      if res<>10035 then break;//nonfatalra varunk csak}
    end else begin
      len:=len-res;//ez 64k folott szamit csak elvieg
      if len<=0 then begin
        result:=true;
        break;
      end else
        inc(p,res);
    end;
    if timeoutMs>0 then sleep(15);
    dec(timeoutMS,15);
  until(timeoutMs<0);

  if not result then begin
    inc(sendErrors);
    lastError:=res;
  end else begin
    inc(sentCnt);
    inc(sentBytes,length(data));
  end;
end;

const cHelloImTheServer=#255;
      cHelloImAClient=#254;
      cBye=#253;
      cPing=#252;
      cMultiBlockStart=#251;
      cMultiBlockMiddle=#250;
      cMultiBlockEnd=#249;

const maxDatagramSize=1280-28;

function THetUDP.Send(addr:u_long;const data:ansistring;timeoutMs:integer=0):boolean;
var pos:integer;
    act:ansistring;
    first,last:boolean;
begin
  result:=false;
  if data='' then exit;
  if Length(data)<=maxDataGramSize then
    result:=sendSingle(addr,data,timeoutMs)
  else begin
    pos:=1;
    while pos<=length(data)do begin
      first:=pos=1;
      act:=copy(data,pos,maxDatagramSize);
      pos:=pos+length(act);
      last:=pos>length(data);

      if first then act:=cMultiBlockStart+act else
      if last  then act:=cMultiBlockEnd+act else
                    act:=cMultiBlockMiddle+act;
      result:=sendSingle(addr,act,timeoutMs);

      if not result then
        exit;
    end;
  end;
end;

procedure THetUDP.Close;
begin
  if not FActive then exit;
  if csDesigning in ComponentState then begin FActive:=false; exit end;
  if Server then Broadcast(cBye,UDPsysTimeOut)
            else Send(FServerIP,cBye,UDPsysTimeOut);
  FServerIP:=0;DeleteAllClients;
  closesocket(sock);
  FActive:=false;
end;

constructor THetUDP.Create(AOwner: TComponent);
begin
  inherited;
  /////////// DEBUG
  //BroadcastSucks:=true;

  Port:=hetudpdefaultport;
  setlength(FMsg,UDPmaxMsgLength);
end;

function THetUDP.CreateHWND:hwnd;
Var C: TWndClassA;
    ClassName: pansichar;
Begin
  result:=0;
  ClassName:= 'udpwindow';
  if not GetClassInfoA(HInstance, PAnsiChar(ClassName), C) Then begin
    fillchar(c,sizeof(c),0);
    c.hInstance:=HInstance;
    C.cbWndExtra:=4;
    C.lpfnWndProc:=@UdpMessageProc;
    C.lpszClassName:=ClassName;
    If Windows.RegisterClassA(C)=0 Then exit;
  end;
  result:=CreateWindowA(ClassName,'udpwindow',0,0,0,100,100,0,0,HInstance,nil);
  If result=0 Then exit;
  SetWindowLongA(Result,0,integer(self));
  ShowWindow(result, SW_Hide);

  SetTimer(result,1,UDPTimerInterval,nil);
End;

procedure THetUdp.StdServerReceive;
var ch:ansichar;
    clname:ansistring;
    client:THetUDPClient;
begin
  if fmsgLen>0 then ch:=fmsg[1] else ch:=#0;
  client:=ClientByIp(FLastIP);
  if client<>nil then
    client.LastReceiveTime:=Now;
  case ch of
    cHelloImAClient:begin
      if Client=nil then begin
        clname:=copy(fmsg,2,FMsgLen-1);
        {client:=}AddClient(clname,FLastIp);
        Send(FLastIP,cHelloImTheServer,UDPsysTimeOut);
        DoConnectionChanged;
      end;
    end;
    cBye:begin
      DeleteClient(client);
      DoConnectionChanged;
    end;
    cPing:;
    cHelloImTheServer:;
    cMultiBlockStart:FMultiBlock:=copy(FMsg,2,FMsgLen-1);
    cMultiBlockMiddle:FMultiBlock:=FMultiBlock+copy(FMsg,2,FMsgLen-1);
    cMultiBlockEnd:begin
      FMultiBlock:=FMultiBlock+copy(FMsg,2,FMsgLen-1);
      OnReceive(self,client,FMultiBlock);
      FMultiBlock:='';
    end;
  else if Assigned(OnReceive)then
    OnReceive(self,client,copy(FMsg,1,FMsgLen));
  end;
end;

procedure THetUdp.StdClientReceive;
var ch:ansichar;
begin
  if FMsgLen>0 then ch:=fmsg[1] else ch:=#0;
  if FLastIP=FServerIP then
    LastSrvReceiveTime:=now;

  case ch of
    cHelloImTheServer:begin
      FServerIP:=FLastIP;
      Send(FServerIP,cHelloImAClient+PeerName,UDPsysTimeOut);
      DoConnectionChanged;
    end;
    cHelloImAClient:;
    cBye:if FLastIP=FServerIP then begin
      FServerIP:=0;
      DoConnectionChanged;
    end;
    cPing:;
    cMultiBlockStart:FMultiBlock:=copy(FMsg,2,FMsgLen-1);
    cMultiBlockMiddle:FMultiBlock:=FMultiBlock+copy(FMsg,2,FMsgLen-1);
    cMultiBlockEnd:begin
      FMultiBlock:=FMultiBlock+copy(FMsg,2,FMsgLen-1);
      OnReceive(self,nil,FMultiBlock);;
    end;
    else if Assigned(OnReceive)then OnReceive(self,nil,copy(FMsg,1,FMsgLen));
  end;
end;

procedure THetUDP.DoReceive;
var from:sockaddr_in;
    fromLen:integer;
begin
  fromLen:=SizeOf(from);
  FmsgLen:=recvfrom(sock, Fmsg[1], length(FMsg), 0, from,fromLen);
  if FmsgLen<0 then exit;

  FLastIP:=from.sin_addr.S_addr;

  inc(recvCnt);
  inc(recvBytes,FMsgLen);

  if FServer then StdServerReceive
             else StdClientReceive;
end;

function _getHostByName(AHost:ansistring):integer;
var hostEnt:PHostEnt;
begin
  Replace('http://','',AHost,[roIgnoreCase]);
  Replace('ftp://','',AHost,[roIgnoreCase]);
  Replace('udp://','',AHost,[roIgnoreCase]);

  if AHost='' then
    result:=0
  else if charn(AHost,1)in['0'..'9']then begin
    result:=inet_addr(PAnsiChar(AHost));
  end else begin
    hostEnt:=gethostbyname(pansichar(AHost));
    if hostEnt=nil then result:=0
                   else result:=pinteger(hostEnt.h_addr^)^;
  end;
end;

function THetUDP.Open: boolean;
begin
  if csDesigning in componentstate then begin FActive:=true;result:=true;exit end;
  if FActive then close;
  FServerIP:=0;DeleteAllClients;

  result:=false;
  if FWnd=0 then FWnd:=CreateHWND;
  if FWnd=0 then exit;

  sock:= Socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
  if sock=INVALID_SOCKET then exit;

  with addrIn do begin
    sin_family:=AF_INET;
    if FServer then sin_port:=htons(Port+1)
               else sin_port:=htons(Port);
    sin_addr.S_addr:=htonl(INADDR_ANY);
  end;

  if(Bind(sock, addrin, SizeOf(addrin))<>0)or
    (WSAAsyncSelect(sock, FWnd, WM_sock, FD_READ + FD_WRITE)<>0)then begin
    closesocket(sock);exit;
  end;

  FActive:=true;result:=true;

  if Server then
    Broadcast(cHelloImTheServer,UDPsysTimeOut)
  else {client} begin
    if BroadcastSucks then
      Send(_gethostbyname(ForcedServerHostName),cHelloImAClient+PeerName,UDPsysTimeOut)
    else
      Broadcast(cHelloImAClient+PeerName,UDPsysTimeOut);
  end;
end;

procedure THetUDP.OnTimer;
var i:integer;
    MinTime:TDateTime;
const msToDay=1/24/60/60/1000;
begin
  MinTime:=now-UDPClientMaxIdleTime*msToDay;
  if FActive and not FServer then begin
    SendToServer(cPing);
    if(FServerIP<>0)and(LastSrvReceiveTime<MinTime)then begin
      FServerIP:=0;
      DoConnectionChanged;
    end;
  end else if FActive and FServer then  begin
    Broadcast(cHelloImTheServer,UDPsysTimeOut);
    for i:=high(FClients)downto 0 do begin
      if FClients[i].LastReceiveTime<MinTime then begin
        DeleteClient(FClients[i]);
        DoConnectionChanged;
      end;
    end;
  end;
end;

procedure THetUDP.SetActive(const Value: boolean);
begin
  if FActive = Value then exit;
  if Value then Open else Close;
end;

procedure THetUDP.SetForcedServerHostName(const Value: ansistring);
begin
  if FForcedServerHostName=Value then exit;
  FForcedServerHostName:=Value;
  if Active then Open;
end;

var awsadata:WSAData;
procedure THetUDP.SetPeerName(const Value: ansistring);
begin
  if FPeerName=Value then exit;
  FPeerName:=Value;
  if Active then Open;
end;

procedure THetUDP.SetPort(const Value: integer);
begin
  if FPort = Value then exit;
  FPort := Value;
  if Active then Open;
end;

procedure THetUDP.SetServer(const Value: boolean);
begin
  if FServer = Value then exit;
  if Active then begin
    Close;
    FServer := Value;
    Open;
  end else
    FServer := Value;
end;

function IPAddr2Str(ip:u_long):ansistring;
begin
  result:=format('%d.%d.%d.%d',[IP and 255,IP shr 8 and 255,IP shr 16 and 255,IP shr 24])
end;

  procedure ListAppend(var slist:ansistring;const str,separ:ansistring);
  begin
    if slist<>'' then slist:=slist+separ+str
                 else slist:=str;
  end;

  function switch(const b:boolean;const st,sf:ansistring):ansistring;
  begin
    if b then result:=st else result:=sf;
  end;

function THetUDP.GetPeerName: ansistring;
begin
  if FPeerName='' then result:=ComputerName
                  else result:=FPeerName;
end;

function THetUDP.GetStatistics: ansistring;
var separ:ansistring;
    i:integer;
begin
  result:='';
  separ:=#13#10;
  ListAppend(result,'Active: '+switch(FActive,'1','0'),separ);
  ListAppend(result,'IsServer: '+switch(FServer,'1','0'),separ);
  ListAppend(result,'PeerName: '+PeerName,separ);
  ListAppend(result,'Port: '+IntToStr(Port),separ);
  ListAppend(result,'SentCnt: '+inttostr(sentCnt),separ);
  ListAppend(result,'RecvCnt: '+inttostr(recvCnt),separ);
  ListAppend(result,'SentBytes: '+inttostr(sentBytes),separ);
  ListAppend(result,'RecvBytes: '+inttostr(recvBytes),separ);
  ListAppend(result,'SendErrors: '+inttostr(sendErrors),separ);
  ListAppend(result,'LastErrorCode: '+inttostr(LastError),separ);
  ListAppend(result,'Broadcast Suxx: '+BoolToStr(BroadcastSucks),separ);
  if Active then if server then begin
    ListAppend(result,'ClientCnt: '+inttostr(length(fclients)),separ);
    for i:=0 to high(FClients) do begin
      ListAppend(result,format('#%.2d %s %s',[i+1,IPAddr2Str(cardinal(fclients[i].ip)),fclients[i].name]),separ);
    end;
  end else begin
    ListAppend(result,'ServerAddr: '+IPAddr2Str(FServerIP),separ);
  end;
end;

destructor THetUDP.Destroy;
begin
  if FWnd<>0 then DestroyWindow(Fwnd);
  Close;
  DeleteAllClients;
  inherited;
end;

function THetUDP.ServerIP: cardinal;
begin
  result:=FServerIP;
end;

procedure THetUDP.DoConnectionChanged;
begin
  if Assigned(OnConnectionChanged)then
    OnConnectionChanged(self);
end;

function THetUDP.SendByName(const name:ansistring; const data: ansistring; timeoutMs: integer): boolean;
var cl:THetUDPClient;
begin
  cl:=ClientByName(name);
  if cl<>nil then result:=send(cl.Ip,data,timeoutMs)
             else result:=false;
end;

function THetUDP.AddClient(const AName: ansistring; const AIp: u_long): THetUdpClient;
begin
  result:=ClientByIp(AIp);
  if result=nil then begin
    result:=THetUDPClient.Create;
    result.Ip:=AIp;
    setlength(FClients,length(FClients)+1);
    FClients[high(FClients)]:=result;
  end;
  result.Name:=AName;
  result.LastReceiveTime:=now;
end;

procedure THetUDP.DeleteClient(const AClient: THetUdpClient);
var i,j:integer;
begin
  for i:=high(FClients)downto 0 do if FClients[i]=AClient then begin
    AClient.Free;
    for j:=i to high(FClients)-1 do FClients[j]:=FClients[j+1];
    setlength(FClients,high(FClients));
    exit;
  end;
end;

procedure THetUDP.DeleteAllClients;
var i:integer;
begin
  for i:=high(FClients)downto 0 do FClients[i].Free;
  setlength(FClients,0);
end;

function THetUDP.ClientByIp(const AIp: u_long): THetUDPClient;
var i:integer;
begin
  for i:=0 to high(FClients)do if FClients[i].Ip=AIp then exit(FClients[i]);
  result:=nil;
end;

function THetUDP.ClientByName(const AName: ansistring): THetUDPClient;
var i:integer;
begin
  for i:=0 to high(FClients)do if FClients[i].Name=AName then exit(FClients[i]);
  result:=nil;
end;

function THetUDP.ClientCount: integer;
begin
  result:=Length(FClients)
end;

function THetUDP.ClientNameList: ansistring;
var i:integer;
begin
  result:='';
  for i:=0 to high(FClients)do
    ListAppend(result,FClients[i].Name,',');
end;

initialization
  WSAStartup(MakeWord(2,0),awsaData);
finalization
  WSACleanup;
end.
