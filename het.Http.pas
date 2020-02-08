unit het.Http;
interface
uses windows, sysutils, classes, winsock, math, het.Utils, het.Arrays, syncobjs,
  typinfo;

const
  _httpDefaultTimeout=5000;
  _ftpDefaultTimeout=5000;

//procedure httpFtpCallback(sender:TObject;const state:AnsiString;const act,max:integer;var abort:boolean);

type
  THttpFtpCallback=procedure(sender:TObject;const state:AnsiString;const act,max:integer;var abort:boolean)of object;

  THttpFtpCallback2=reference to procedure(st:AnsiString;act,max:integer;var abort:boolean);

  THttpHeader=ansistring;

  THttpPacketParam=(ppHost,ppAccept,ppAccept_Language,ppDate,ppServer,
    ppLast_Modified,ppAccept_Ranges,ppContent_Length,ppConnection,ppContent_Type,
    ppConnect,ppUpgrade,ppUser_Agent,ppAccept_Encoding,
    ppAccept_Charset,ppKeep_Alive,ppReferer,
    ppPragma,ppCache_Control,ppCookie,ppSet_Cookie,ppCookie_Length,
    ppTransfer_Encoding,ppAge,ppExpires);

  THttpPacket=record
  private
    FHeader:THetArray<ansistring>;
    FBody:ansistring;
    function GetHeader:ansistring;
    procedure SetHeader(const value:ansistring);
    function GetAll:ansistring;
    procedure SetAll(const value:ansistring);
    function FindParam(const name:ansistring):integer;
    function GetParamName(const p:THttpPacketParam):ansistring;

    function GetParam(const name:ansistring):ansistring;
    procedure SetParam(const name,value:ansistring);
    function GetParamAsInt(const name:ansistring):integer;
    procedure SetParamAsInt(const name:ansistring;const value:integer);
    function GetParamAsDate(const name:ansistring):TDateTime;
    procedure SetParamAsDate(const name:ansistring;const value:TDateTime);

    function GetParamIdx(const name:THttpPacketParam):ansistring;
    procedure SetParamIdx(const name:THttpPacketParam;const value:ansistring);
    function GetParamAsDateIdx(const name:THttpPacketParam):TDateTime;
    procedure SetParamAsDateIdx(const name:THttpPacketParam;const value:TDateTime);
    function GetParamAsIntIdx(const name:THttpPacketParam):integer;
    procedure SetParamAsIntIdx(const name:THttpPacketParam;const value:integer);

    function GetResponseCode:integer;
    procedure SetResponseCode(const value:integer);
    function GetResponseStr:ansistring;
    function GetCommand:ansistring;
    procedure SetCommand(const value:ansistring);
    function GetPath:ansistring;
    procedure SetPath(const value:ansistring);
    function GetURL:ansistring;
    procedure SetURL(const value:ansistring);
  public
    requestHOST:ansistring;
    procedure Clear;
    property Header:ansistring read GetHeader write SetHeader;
    property Body:ansistring read FBody write FBody;
    property All:ansistring read GetAll write SetAll;
    property Param[const name:ansistring]:ansistring read GetParam write SetParam;
    property ParamAsInt[const name:ansistring]:integer read GetParamAsInt write SetParamAsInt;
    property ParamAsDate[const name:ansistring]:TDateTime read GetParamAsDate write SetParamAsDate;
    procedure DeleteParam(const name:ansistring);

    function IsResponse:boolean;
    function IsRequest:boolean;

    property ResponseCode:integer read GetResponseCode write SetResponseCode;
    property ResponseStr:ansistring read GetResponseStr;
    property Command:ansistring read GetCommand write SetCommand;
    property Path:ansistring read GetPath write SetPath;
    property Url:ansistring read GetUrl write SetUrl;

    property Host:ansistring index ppHost read GetParamIdx write SetParamIdx;
    property Accept:ansistring index ppAccept read GetParamIdx write SetParamIdx;
    property Accept_Language:ansistring index ppAccept_Language read GetParamIdx write SetParamIdx;
    property Date:TDateTime index ppDate read GetParamAsDateIdx write SetParamAsDateIdx;
    property Server:ansistring index ppServer read GetParamIdx write SetParamIdx;
    property Last_Modified:TDateTime index ppLast_Modified read GetParamAsDateIdx write SetParamAsDateIdx;
    property Accept_Ranges:ansistring index ppAccept_Ranges read GetParamIdx write SetParamIdx;
    property Content_Length:integer index ppContent_Length read GetParamAsIntIdx write SetParamAsIntIdx;
    property Connection:ansistring index ppConnection read GetParamIdx write SetParamIdx;
    property Content_Type:ansistring index ppContent_Type read GetParamIdx write SetParamIdx;
    property Connect:ansistring index ppConnect read GetParamIdx write SetParamIdx;
    property Upgrade:ansistring index ppUpgrade read GetParamIdx write SetParamIdx;
    property User_Agent:ansistring index ppUser_Agent read GetParamIdx write SetParamIdx;
    property Accept_Encoding:ansistring index ppAccept_Encoding read GetParamIdx write SetParamIdx;
    property Accept_Charset:ansistring index ppAccept_Charset read GetParamIdx write SetParamIdx;
    property Keep_Alive:ansistring index ppKeep_Alive read GetParamIdx write SetParamIdx;
    property Referer:ansistring index ppReferer read GetParamIdx write SetParamIdx;
    property Pragma:ansistring index ppPragma read GetParamIdx write SetParamIdx;
    property Cache_Control:ansistring index ppCache_Control read GetParamIdx write SetParamIdx;
    property Cookie:ansistring index ppCookie read GetParamIdx write SetParamIdx;
    property Set_Cookie:ansistring index ppSet_Cookie read GetParamIdx write SetParamIdx;
    property Cookie_Length:integer index ppCookie_Length read GetParamAsIntIdx write SetParamAsIntIdx;
    property Transfer_Encoding:ansistring index ppTransfer_Encoding read GetParamIdx write SetParamIdx;
    property Age:ansistring index ppAge read GetParamIdx write SetParamIdx;
    property Expires:TDateTime index ppExpires read GetParamAsDateIdx write SetParamAsDateIdx;
  end;

function httpStatusToStr(const status:integer):AnsiString;

function httpRequest(const ARequest:THttpPacket;const ACallBack:THttpFtpCallback2=nil;const ATimeOut:integer=_httpDefaultTimeout):THttpPacket;
function httpGet(const AUrl:AnsiString;const ACallback:THttpFtpCallback2=nil;const ATimeOut:integer=_httpDefaultTimeout):THttpPacket;

//function httpGet(const AUrl:AnsiString;out AResponseHeader,AResponseBody:AnsiString;ACallback:THttpFtpCallback2;ATimeOut:integer=_httpDefaultTimeout):integer;overload;

//function httpPost(const AUrl:AnsiString;const ARequestBody:AnsiString;out AResponseHeader,AResponseBody:AnsiString;ACallback:THttpFtpCallback=nil;ATimeOut:integer=_httpDefaultTimeout):integer;
function ftpUpload(const AUrl,AUserName,APassword:AnsiString;const Passive:boolean;const ASource:TStream;ADestination:AnsiString;ACallback:ThttpFtpCallback=nil;const ATimeout:integer=_ftpDefaultTimeout):integer;

var
  httpFtpState:record
    state:AnsiString;
    max,act:integer;
  end;

implementation

uses StdConvs;

//Sat, 20 Mar 2010 20:41:54 GMT

const
  httpMonths:array[1..12]of ansistring=('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec');
  httpDays:array[1..7]of ansistring=('Sun','Mon','Tue','Wed','Thu','Fri','Sat');

function HttpDateEncode(const date:TDateTime):ansistring;
var y,m,d,dow:word;
begin
  if DecodeDateFully(date,y,m,d,dow)then
    result:=httpDays[dow]+', '+format('%.2d',[d])+' '+httpMonths[m]+' '+toStr(y)+' '+FormatDateTime('HH:NN:SS',date)+' GMT'
  else
    result:='';
end;

function HttpDateDecode(const str:ansistring):TDateTime;
var sl:TAnsiStringArray;
    y,m,d,i:integer;
begin
  try
    sl:=ListSplit(str,' ');
    d:=StrToInt(sl[1]);
    m:=0;for i:=1 to 12 do if cmp(sl[2],httpMonths[i])=0 then begin m:=i;break end;
    y:=StrToInt(sl[3]);

    sl:=listSplit(sl[4],':');
    result:=EncodeDate(y,m,d)+EncodeTime(StrToInt(sl[0]),StrToInt(sl[1]),StrToInt(sl[2]),0);
  except
    result:=0;
  end;
end;

function httpStatusToStr(const status:integer):AnsiString;
begin
  case status of
    100:result:='Continue';
    101:result:='Switching Protocols';

    200:result:='OK';
    201:result:='Created';
    202:result:='Accepted';
    203:result:='Non-Authoritative Information';
    204:result:='No Content';
    205:result:='Reset Content';
    206:result:='Partial Content';

    300:result:='Multiple Choices';
    301:result:='Moved Permanently';
    302:result:='Found';
    303:result:='See Other';
    304:result:='Not Modified';
    305:result:='Use Proxy';
    306:result:='Switch Proxy';
    307:result:='Temporary Redirect';

    400:result:='Bad Request';
    401:result:='Unauthorized';
    402:result:='Payment Required';
    403:result:='Forbidden';
    404:result:='Not Found';
    405:result:='Method Not Allowed';
    406:result:='Not Acceptable';
    407:result:='Proxy Authentication Required';
    408:result:='Request Timeout';
    409:result:='Conflict';
    410:result:='Gone';
    411:result:='Length Required';
    412:result:='Precondition Failed';
    413:result:='Request Entity Too Large';
    414:result:='Request-URI Too Long';
    415:result:='Unsupported Media Type';
    416:result:='Requested Range Not Satisfiable';
    417:result:='Expectation Failed';

    500:result:='Internal Server Error';
    501:result:='Not Implemented';
    502:result:='Bad Gateway';
    503:result:='Service Unavailable';
    504:result:='Gateway Timeout';
    505:result:='HTTP Version Not Supported';

    //het
    600:result:='Host not found';
    601:result:='Failed to Create Socket';
    602:result:='Failed to Connect';
    603:result:='Socket Write Error';
    604:result:='Socket Read Error';
    605:result:='Bad URL';
    606:result:='HTTP Header Error';
    607:result:='DataChannel Error';
    608:result:='User Abort';
    609:result:='Socket Read 0 bytes';
    610:result:='Http chunk error';
    611:result:='Http unknown error';
    612:result:='Http contentLen<dataLen';

    else result:='Unknown';
  end;
  result:=tostr(status)+' '+result;
end;

{ THttpPacket }

procedure THttpPacket.Clear;
begin
  FHeader.Clear;FBody:='';
  Referer
end;

function THttpPacket.FindParam(const name: ansistring): integer;
var filt:ansistring;
begin
  filt:=name+':*';
  FHeader.Find(function(const a:ansistring):boolean begin result:=IsWild2(filt,a,True)end,result);
end;

procedure THttpPacket.DeleteParam(const name: ansistring);
var i:integer;
begin
  i:=FindParam(name);
  if i>=0 then FHeader.Remove(i);
end;

function THttpPacket.GetParam(const name: ansistring): ansistring;
var i:integer;
begin
  i:=FindParam(name);
  if i>=0 then begin
    if CharN(FHeader.FItems[i],length(name)+2)=' ' then
      result:=copy(FHeader.FItems[i],length(name)+3,$7fffffff)
    else
      result:=copy(FHeader.FItems[i],length(name)+2,$7fffffff)
  end else result:='';
end;

procedure THttpPacket.SetParam(const name, value: ansistring);
var i:integer;
begin
  i:=FindParam(name);
  if i>=0 then
    FHeader.FItems[i]:=name+': '+value
  else begin
    if FHeader.Count=0 then
      FHeader.Append('');
    FHeader.Append(name+': '+value);
  end;
end;

function THttpPacket.GetParamAsInt(const name: ansistring): integer;
begin
  result:=StrToIntDef(GetParam(name),0);
end;

procedure THttpPacket.SetParamAsInt(const name:ansistring;const value: integer);
begin
  SetParam(name,toStr(value));
end;

function THttpPacket.GetParamAsDate(const name: ansistring): TDateTime;
begin
  result:=HttpDateDecode(GetParam(name));
end;

procedure THttpPacket.SetParamAsDate(const name:ansistring;const value: TDateTime);
begin
  SetParam(name,HttpDateEncode(value));
end;

function THttpPacket.GetAll: ansistring;
begin
  result:=GetHeader+FBody;
end;

procedure THttpPacket.SetAll(const value: ansistring);
var i:integer;
begin
  i:=pos(#13#10#13#10,value,[]);
  if i<0 then raise Exception.Create('THttpPacket.SetAll() no header in packet');
  Header:=copy(value,1,i-1);
  Body:=copy(value,i+4,$7fffffff);
end;

function THttpPacket.GetHeader: ansistring;
var i:integer;
begin with AnsiStringBuilder(result,true),FHeader do begin
  for i:=0 to Count-1 do if FItems[i]<>'' then AddStr(FItems[i]+#13#10);
  AddStr(#13#10);
end;end;

procedure THttpPacket.SetHeader(const value: ansistring);
var s:ansistring;
    continued:boolean;
begin
  FHeader.Clear;
  continued:=false;
  with FHeader do for s in ListSplit(value,#10,true)do if s<>'' then begin
    if continued then FItems[FCount-1]:=FItems[FCount-1]+#13#10+s
                 else Append(s);
    continued:=s[length(s)]=';';//lehet, hogy kell még masmilyen check is
  end;
end;

function THttpPacket.GetParamName(const p:THttpPacketParam):ansistring;
begin
  result:=replacef('_','-',copy(GetEnumName(TypeInfo(THttpPacketParam),ord(p)),3,$ff),[roAll]);
end;

function THttpPacket.GetParamIdx(const name:THttpPacketParam):ansistring;
begin
  result:=GetParam(GetParamName(name));
end;

procedure THttpPacket.SetParamIdx(const name:THttpPacketParam;const value:ansistring);
begin
  SetParam(GetParamName(name),value);
end;

function THttpPacket.GetParamAsIntIdx(const name:THttpPacketParam):integer;
begin
  result:=GetParamAsInt(GetParamName(name));
end;

procedure THttpPacket.SetParamAsIntIdx(const name:THttpPacketParam;const value:integer);
begin
  SetParamAsInt(GetParamName(name),value);
end;

function THttpPacket.GetParamAsDateIdx(const name:THttpPacketParam):TDateTime;
begin
  result:=GetParamAsDate(GetParamName(name));
end;

procedure THttpPacket.SetParamAsDateIdx(const name:THttpPacketParam;const value:TDateTime);
begin
  SetParamAsDate(GetParamName(name),value);
end;



function THttpPacket.IsResponse:boolean;
begin
  if FHeader.count=0 then exit(false);
  result:=IsWild2('HTTP/1.?',ListItem(FHeader.FItems[0],0,' '));
end;

function THttpPacket.IsRequest:boolean;
begin
  if FHeader.count=0 then exit(false);
  result:=IsWild2('HTTP/1.?',ListItem(FHeader.FItems[0],2,' '));
end;

function THttpPacket.GetResponseCode: integer;
begin
  if not IsResponse then exit(0);
  result:=StrToIntDef(ListItem(FHeader.FItems[0],1,' '),0);
end;

function THttpPacket.GetResponseStr: ansistring;
begin
  if not IsResponse then exit('');
  result:=httpStatusToStr(GetResponseCode);
end;

procedure THttpPacket.SetResponseCode(const value: integer);
begin
  if FHeader.Count=0 then FHeader.Append('');
  FHeader.FItems[0]:='HTTP/1.1 '+httpStatusToStr(value);
end;

function THttpPacket.GetURL: ansistring;
begin
  if not IsRequest then exit('');
  result:=Param['Host'];
  result:='http://'+result+listItem(FHeader.FItems[0],1,' ');
end;

procedure THttpPacket.SetURL(const value: ansistring);
var lHost,lPath:ansistring;
    i:integer;
begin
  lHost:=replacef('http://','',value,[roIgnoreCase]);
  i:=pos('/',lHost,[]);
  if i>0 then begin
    lPath:=copy(lHost,i,$ffff);
    setlength(lHost,i-1);
  end else
    lPath:='/';

  Path:=lPath;
  Host:=lHost;
end;

function THttpPacket.GetCommand: ansistring;
begin
  if IsRequest then exit(listItem(FHeader.FItems[0],0,' '))
               else exit('');
end;

procedure THttpPacket.SetCommand(const value: ansistring);
var lPath,lCommand:ansistring;
begin
  if FHeader.Count=0 then FHeader.Append('');
  lCommand:=value;if lCommand='' then lCommand:='GET';
  lPath:=Path;if lPath='' then lPath:='/';
  FHeader.FItems[0]:=lCommand+' '+lPath+' HTTP/1.1';
end;

function THttpPacket.GetPath: ansistring;
begin
  if IsRequest then exit(listItem(FHeader.FItems[0],1,' '))
               else exit('');
end;

procedure THttpPacket.SetPath(const value: ansistring);
var lPath,lCommand:ansistring;
begin
  if FHeader.Count=0 then FHeader.Append('');
  lCommand:=Command;if lCommand='' then lCommand:='GET';
  lPath:=value;if lPath='' then lPath:='/';
  FHeader.FItems[0]:=lCommand+' '+lPath+' HTTP/1.1';
end;

////////////////////////////////////////////////////////////////////////////////
///  SOCKET FUNCTIONS

function _ExtractUrl(const AUrl:AnsiString;out host:AnsiString;out port:integer;out path:AnsiString;const ADefaultPort:integer):boolean;
var i:integer;
begin
  result:=true;

  host:=AUrl;
  replace('http://','',host,[roIgnoreCase]);
  replace('ftp://','',host,[roIgnoreCase]);

  i:=pos('/',host);
  if i>0 then begin
    path:=copy(host,i,$ffff);
    setlength(host,i-1)
  end else
    path:='/';

  i:=pos(':',host);
  if i>0 then begin
    port:=strtointdef(copy(host,i+1,10),80);
    setlength(host,i-1);
    if host='' then
      result:=false;
  end else
    port:=ADefaultPort;
end;

type
  TSocketType=(stTCP,stUDP);

function _createSocket(const ASocketType:TSocketType;const ATimeOut:integer):TSocket;
begin
  result:=SOCKET_ERROR;
  case ASocketType of
    stTCP:Result:=socket(AF_INET,SOCK_STREAM,IPPROTO_TCP);
    stUDP:Result:=socket(AF_INET,SOCK_DGRAM ,IPPROTO_UDP);
    else exit;
  end;
  if Result=SOCKET_ERROR then exit;
  if setsockopt(Result,SOL_SOCKET,SO_RCVTIMEO,@ATimeout,sizeof(ATimeout))=SOCKET_ERROR then
    begin closesocket(Result);result:=SOCKET_ERROR;exit end;
  if setsockopt(Result,SOL_SOCKET,SO_SNDTIMEO,@ATimeout,sizeof(ATimeout))=SOCKET_ERROR then
    begin closesocket(Result);result:=SOCKET_ERROR;exit end;
end;

function _connect(const ASocket,AIPAddr,APort:integer):boolean;
var sin:sockaddr_in;
begin
  FillChar(sin,sizeof(sin),0);
  with sin do begin
    sin_family:=AF_INET;
    sin_addr.S_addr:=AIPAddr;
    sin_port:=htons(APort);
  end;
  result:=connect(ASocket,sin,sizeof(sin))<>SOCKET_ERROR;
end;

function _bind(const ASocket,AIPAddr,APort:integer):boolean;
var sin:sockaddr_in;
begin
  FillChar(sin,sizeof(sin),0);
  with sin do begin
    sin_family:=AF_INET;
    sin_addr.S_addr:=AIPAddr;
    sin_port:=htons(APort);
  end;
  result:=bind(ASocket,sin,sizeof(sin))<>SOCKET_ERROR;
end;

function getSocketIp(s:tsocket):integer;
var sin:sockaddr_in;len:integer;
begin
  fillchar(sin,sizeof(sin),0);len:=sizeof(sin);
  if getsockname(s,sin,len)=SOCKET_ERROR then result:=0
                                                            else result:=sin.sin_addr.S_addr;
end;

function getSocketPort(s:tsocket):integer;
var sin:sockaddr_in;len:integer;
begin
  fillchar(sin,sizeof(sin),0);len:=sizeof(sin);
  if getsockname(s,sin,len)=SOCKET_ERROR then result:=0
                                                            else result:=ntohs(sin.sin_port);
end;

function GetLocalIP:integer;
type
  TArrayPInAddr = array [0..10] of PInteger;
  PArrayPInAddr = ^ TArrayPInAddr;
  var
  phe      : PHostEnt;
  pptr     : PArrayPInAddr;
  Buffer   : array [0..63] of AnsiChar;
  i        : integer;
begin
  result:=0;;
  GetHostName(Buffer, sizeof(Buffer));
  phe := GetHostByName(Buffer);
  if phe=nil then
  begin
    exit
  end;
  pptr := PArrayPInAddr(phe^.h_addr_list);
  i := 0;
  while pptr^[i]<>nil do
  begin
    result:=pptr^[i]^;
    Inc(i);
  end;
  WSACleanup;
end;


function _getHostByName(const AHost:AnsiString):integer;
var hostEnt:PHostEnt;
begin
  hostEnt:=gethostbyname(PAnsiChar(AHost));
  if hostEnt=nil then result:=0
                 else result:=pinteger(hostEnt.h_addr^)^;
end;

function _httpHeaderGetParam(const AHeader,AParamName:AnsiString):AnsiString;
begin
  if cmp(AParamName,'status')=0 then begin
    result:=FindBetween(copy(AHeader,1,pos(#13#10,AHeader)-1),' ',' ');
  end else
    result:=trimf(FindBetween(AHeader,#13#10+AParamName+':',#13#10));
end;

type TTestChunkedResult=(tcComplete,tcIncomplete,tcError);
function _HttpDecodeChunked(const AData:AnsiString;out res:AnsiString;testOnly:boolean):TTestChunkedResult;
var ActPos,ActSize,NextPos:integer;s:AnsiString;
begin
  ActPos:=1;res:='';
  result:=tcIncomplete;
  while ActPos<=length(AData)do begin
    NextPos:=pos(#13#10,AData,[poIgnoreCase],ActPos);
    if nextPos<0 then exit;//incomplete
    s:=trimf(copy(AData,Actpos,NextPos-ActPos));
    if s='' then
      begin result:=tcComplete;exit;end; //prog.hu szerint ez is a vege
    if(length(s)>8)then begin result:=tcError;exit end;
    ActSize:=StrToIntDef('$'+s,-1);
    if ActSize<0 then begin result:=tcError;exit;end;//bad hex format
    if ActSize=0 then begin result:=tcComplete;exit;end;//success
    if NextPos+2+ActSize>length(AData) then exit;//incomplete 55 954
    if not testOnly then res:=res+copy(AData,NextPos+2,ActSize);
    ActPos:=NextPos+2{after data}+ActSize+2{after data};
    if copy(AData,ActPos-2,2)<>#13#10 then begin result:=tcError;exit;end;//error
  end;
end;

////////////////////////////////////////////////////////////////////////////////
///  TCP CONNECTIONS

type
  TConnection=record
    host:ansistring;
    port:integer;
    IPAddr:integer;
    Client:TSocket;
    lastAccess:TDateTime;
    used:boolean;
  end;

var
  TCPConnections:array of TConnection;
  TCPConnectionsLock:TCriticalSection;

function GetTcpConnection(const AHost:ansistring;const APort:integer;out AIPAddr:integer;out AClient:TSocket):integer;//error number, 0:ok
var i:integer;
begin
  TCPConnectionsLock.Enter;
  try
    for i:=high(TCPConnections)downto 0 do with TCPConnections[i]do if not used and(cmp(Host,AHost)=0)and(Port=APort)then begin
      AIPAddr:=IPAddr;
      AClient:=Client;
      lastAccess:=now;
      used:=true;
      exit(0);
    end;
  finally
    TCPConnectionsLock.Leave;
  end;

  AIPAddr:=_getHostByName(AHost);if AIPAddr=0 then exit(600);

  AClient:=_createSocket(stTCP,_httpDefaultTimeout);if AClient=SOCKET_ERROR then exit(601);

  if not _connect(AClient,AIPAddr,APort)then
    begin closesocket(AClient);exit(602);end;

  result:=0;//success

  TCPConnectionsLock.Enter;
  try
    SetLength(TCPConnections,length(TCPConnections)+1);
    with TCPConnections[high(TCPConnections)]do begin
      host:=AHost;
      port:=APort;
      IPAddr:=AIPAddr;
      Client:=AClient;
      lastAccess:=Now;
      used:=true;
    end;
  finally
    TCPConnectionsLock.Leave;
  end;
end;

procedure DeleteTCPConnection(const AClient:TSocket);
var i,j:integer;
begin
  TCPConnectionsLock.Enter;
  try
    for i:=high(TCPConnections)downto 0 do with TCPConnections[i]do if Client=AClient then begin
      closeSocket(Client);
      for j:=i to high(TCPConnections)-1 do TCPConnections[j]:=TCPConnections[j+1];
      setlength(TCPConnections,high(TCPConnections));
      exit;
    end;
  finally
    TCPConnectionsLock.Leave;
  end;
end;

procedure ReleaseTCPSocket(const AClient:TSocket);
var i:integer;
begin
  TCPConnectionsLock.Enter;
  try
    for i:=high(TCPConnections)downto 0 do with TCPConnections[i]do if Client=AClient then begin
      used:=false;exit
    end;
  finally
    TCPConnectionsLock.Leave;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
///  HTTP

function httpRequest(const ARequest:THttpPacket;const ACallBack:THttpFtpCallback2=nil;const ATimeOut:integer=_httpDefaultTimeout):THttpPacket;

  function Callback(const AState:AnsiString;const AAct:integer=0;const AMax:integer=0):boolean;
  var abort:boolean;
  begin
    abort:=false;
    if Assigned(ACallBack)then
      ACallBack(AState,AAct,AMax,abort);
    result:=abort;
  end;

var Client:TSocket;
    host,requestStr:AnsiString;
    port,IPAddr:integer;

  function DoItOnce(var AResponse:THttpPacket):integer;
  var i,ActPos:integer;
      buf:AnsiString;
      bufSize,ContentLength:integer;
      gotHeader,isChunked:boolean;
      s:ansistring;
  begin
    AResponse.Clear;

    Callback('HTTP Connecting');
    result:=GetTCPConnection(host,port,IPAddr,Client);
    if result<>0 then begin AResponse.ResponseCode:=result;exit;end;

    Callback('HTTP Connected');
    try
      ActPos:=1;
      while ActPos<=Length(requestStr)do begin
        i:=send(client,requestStr[ActPos],length(requestStr)-ActPos+1,0);
        if i=0 then exit(603);
        if i<0 then begin
          if WSAGetLastError=10035 then begin
            continue end
          else exit(603);
        end;
        ActPos:=ActPos+i;
        if CallBack('HTTP Upload',ActPos-1,length(requestStr))then exit(608);
      end;

      //  shutdown(client,SD_SEND);
    //retry when
      setlength(buf,$1000);
      gotHeader:=false;isChunked:=false;ContentLength:=-1;
      result:=611;
      s:='';
      while true do begin
        bufSize:=recv(client,buf[1],length(buf),0);if bufSize<0 then exit(604);
        if bufSize=0 then exit(609);
        if not GotHeader then begin
          s:=s+copy(buf,1,bufSize);
          i:=pos(#13#10#13#10,s);
          if i>0 then begin
            gotHeader:=true;
            //body 1st part
            AResponse.FBody:=copy(s,i+4,$7fffffff);

            //process header
            SetLength(s,i-1);
            If copy(s,1,5)<>'HTTP/'then
              exit(606);
            AResponse.Header:=s;
            result:=AResponse.ResponseCode;
            if result=0 then
              exit(606);
            if not InRange(result,100,599)then exit;//stop on errors

            isChunked:=cmp(AResponse.Transfer_Encoding,'chunked')=0;
            contentLength:=AResponse.Content_Length;
          end;
        end else begin
          AResponse.FBody:=AResponse.FBody+copy(buf,1,bufSize);
        end;

        if Callback('HTTP Download',length(AResponse.FBody),max(ContentLength,length(AResponse.FBody)))then exit(608);

        //check completion
        s:='';
        if gotHeader then begin
          If isChunked then begin
            case _HttpDecodeChunked(AResponse.FBody,s,true)of
              tcComplete:begin
                _HttpDecodeChunked(AResponse.FBody,s,false);
                AResponse.FBody:=s;
                exit;
              end;
              tcError:exit(610);
              tcIncomplete:{nothing};
            end;
          end else if contentLength>=0 then begin
            if length(AResponse.FBody)>=contentLength then
              exit;//got it
          end;
        end;
      end;
    finally
      ReleaseTCPSocket(Client);
      if AResponse.ResponseCode<>result then
        AResponse.ResponseCode:=result;
    end;
  end;

var path:ansistring;
begin
  result.Clear;
  result.requestHost:=ARequest.Host;
  if not _ExtractUrl(ARequest.Host,host,port,path,80)then
    begin result.ResponseCode:=605;exit end;

  requestStr:=ARequest.All;
  case DoItOnce(result)of
    603,604,609,610,611:begin//retry
      DeleteTCPConnection(Client);
      DoItOnce(Result);
    end;
  end;
end;

(*fdsa
  if ACommand='POST' then begin
    request:=ACommand+' '+{Escape}(path)+' HTTP/1.1'#13#10+
             'Connection: keep-alive'#13#10+
             'Content-Type: text/xml'#13#10+
             'Content-Length: '+inttostr(length(ARequestBody))+#13#10+
             'Cache-control: no-cache'#13#10+
             'Host: '+host+#13#10+
             'Accept: text/xml, */*'#13#10+
             'Content-Encoding: identity'#13#10+
             'User-Agent: Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9.0.3) Gecko/2008092417 Firefox/3.0.3'#13#10#13#10+ARequestBody;
  end else begin
    request:=ACommand+' '+{Escape}(path)+' HTTP/1.1'#13#10+
             'Connection: keep-alive'#13#10+
             'Host: '+host+#13#10+
             'Accept: */*'#13#10+
             'User-Agent: Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9.0.3) Gecko/2008092417 Firefox/3.0.3'#13#10#13#10+ARequestBody;
  end;*)

function httpGet(const AUrl:AnsiString;const ACallback:THttpFtpCallback2=nil;const ATimeOut:integer=_httpDefaultTimeout):THttpPacket;
var request:THttpPacket;
begin
  with request do begin
    Command:='GET';
    Url:=AUrl;
    Connection:='keep-alive';
    Accept:='*/*';
    User_Agent:='User-Agent: Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9.0.3) Gecko/2008092417 Firefox/3.0.3';
  end;
  result:=httpRequest(Request,ACallBack,ATimeOut);
end;

(*function httpGet(const AUrl:AnsiString;ATimeOut:integer=_httpDefaultTimeout):ansistring;
var res:integer;hdr,body:ansistring;
begin
  res:=httpGet(AUrl,hdr,body,procedure(st:ansistring;act,max:integer;var done:boolean)begin end,ATimeOut);
  if res div 100=2 then result:=body
                   else raise Exception.Create('http result='+inttostr(res));
end;

function httpPost(const AUrl:AnsiString;const ARequestBody:AnsiString;out AResponseHeader,AResponseBody:AnsiString;ACallback:THttpFtpCallback=nil;ATimeOut:integer=_httpDefaultTimeout):integer;
begin
//  result:=httpRequest(AUrl,'POST',ARequestBody,AResponseHeader,AResponseBody,ACallback,ATimeOut);
end;
*)
(*

function httpRequest(const AUrl:AnsiString;const ACommand,ARequestBody:AnsiString;out AResponseHeader,AResponseBody:AnsiString;ACallBack:THttpFtpCallback2;ATimeOut:integer=_httpDefaultTimeout):integer;

  function CB(const AState:AnsiString;const AAct,AMax:integer):boolean;
  var abort:boolean;
  begin
    abort:=false;
    if Assigned(ACallBack)then
      ACallBack(AState,AAct,AMax,abort);
    result:=abort;
  end;

var Client:TSocket;
    host,path,request:AnsiString;
    port,IPAddr:integer;

  function DoIt:integer;
  var i,ActPos:integer;
      buf:AnsiString;
      bufSize,ContentLength:integer;
      gotHeader,isChunked:boolean;
      s:ansistring;
  begin
    AResponseHeader:='';
    AResponseBody:='';

    cb('HTTP Connect',0,0);
    result:=GetTCPConnection(host,port,IPAddr,Client);
    if result<>0 then exit;

    try
      ActPos:=1;
      while ActPos<=Length(request)do begin
        i:=send(client,request[ActPos],length(request)-ActPos+1,0);
        if i=0 then exit(603);
        if i<0 then begin
          if WSAGetLastError=10035 then begin
            i:=0;continue end
          else exit(603);
        end;
        ActPos:=ActPos+i;
        if CB('HTTP Upload',ActPos-1,length(request))then exit(608);
      end;

      //  shutdown(client,SD_SEND);
    //retry when
      setlength(buf,$1000);
      gotHeader:=false;
      isChunked:=false;
      ContentLength:=-1;
      result:=611;
      while true do begin
        bufSize:=recv(client,buf[1],length(buf),0);if bufSize<0 then exit(604);
        if bufSize=0 then exit(609);
        if not GotHeader then begin
          AResponseHeader:=AResponseHeader+copy(buf,1,bufSize);
          i:=pos(#13#10#13#10,AResponseHeader);
          if i>0 then begin
            gotHeader:=true;
            AResponseBody:=copy(AResponseHeader,i+4,$7fffffff);
            SetLength(AResponseHeader,i+3);

            //process header
            If copy(AResponseHeader,1,5)<>'HTTP/'then exit(606);
            result:=strtointdef(_httpHeaderGetParam(AResponseHeader,'status'),606);
            if result div 100 in [4,6]then exit;//stop on errors

            isChunked:=cmp(_httpHeaderGetParam(AResponseHeader,'Transfer-Encoding'),'chunked')=0;
            contentLength:=strtointdef(_httpHeaderGetParam(AResponseHeader,'Content-Length'),-1);
          end;
        end else begin
          AResponseBody:=AResponseBody+copy(buf,1,bufSize);
        end;

        if CB('HTTP Download',length(AResponseBody),max(ContentLength,length(AResponseBody)))then exit(608);

        //check completion
        if gotHeader then begin
          If isChunked then begin
            case _HttpDecodeChunked(AResponseBody,s,true)of
              tcComplete:begin
                _HttpDecodeChunked(AResponseBody,s,false);
                AResponseBody:=s;
                exit;
              end;
              tcError:exit(610);
              tcIncomplete:{nothing};
            end;
          end else if contentLength>=0 then begin
            if length(AResponseBody)>=contentLength then
              exit;
          end;
        end;
      end;
    finally
      ReleaseTCPSocket(Client);
    end;
  end;


begin

  if not _ExtractUrl(AUrl,host,port,path,80)then
    begin result:=605;exit end;

  if ACommand='POST' then begin
    request:=ACommand+' '+{Escape}(path)+' HTTP/1.1'#13#10+
             'Connection: keep-alive'#13#10+
             'Content-Type: text/xml'#13#10+
             'Content-Length: '+inttostr(length(ARequestBody))+#13#10+
             'Cache-control: no-cache'#13#10+
             'Host: '+host+#13#10+
             'Accept: text/xml, */*'#13#10+
             'Content-Encoding: identity'#13#10+
             'User-Agent: Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9.0.3) Gecko/2008092417 Firefox/3.0.3'#13#10#13#10+ARequestBody;
  end else begin
    request:=ACommand+' '+{Escape}(path)+' HTTP/1.1'#13#10+
             'Connection: keep-alive'#13#10+
             'Host: '+host+#13#10+
             'Accept: */*'#13#10+
             'User-Agent: Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9.0.3) Gecko/2008092417 Firefox/3.0.3'#13#10#13#10+ARequestBody;
  end;

  Client:=0;
  result:=DoIt;
  case result of
    603,604,609,610,611:begin//retry
      DeleteTCPConnection(Client);
      result:=DoIt;
    end;
  end;
end;

function httpGet(const AUrl:AnsiString;out AResponseHeader,AResponseBody:AnsiString;ACallback:THttpFtpCallback2;ATimeOut:integer=_httpDefaultTimeout):integer;
begin
  result:=httpRequest(AUrl,'GET','',AResponseHeader,AResponseBody,ACallback,ATimeOut);
end;

function httpGet(const AUrl:AnsiString;ATimeOut:integer=_httpDefaultTimeout):ansistring;
var res:integer;hdr,body:ansistring;
begin
  res:=httpGet(AUrl,hdr,body,procedure(st:ansistring;act,max:integer;var done:boolean)begin end,ATimeOut);
  if res div 100=2 then result:=body
                   else raise Exception.Create('http result='+inttostr(res));
end;

function httpPost(const AUrl:AnsiString;const ARequestBody:AnsiString;out AResponseHeader,AResponseBody:AnsiString;ACallback:THttpFtpCallback=nil;ATimeOut:integer=_httpDefaultTimeout):integer;
begin
//  result:=httpRequest(AUrl,'POST',ARequestBody,AResponseHeader,AResponseBody,ACallback,ATimeOut);
end;

*)


//************************************************************************** FTP

function FTPUpload(const AUrl,AUserName,APassword:AnsiString;const Passive:boolean;const ASource:TStream;ADestination:AnsiString;ACallBack:THttpFtpCallback=nil;const ATimeout:integer=_ftpDefaultTimeout):integer;
var controlSocket,dataSocket,listenSocket:TSocket;

  function CB(const AState:AnsiString;const AAct,AMax:integer):boolean;
  var abort:boolean;
  begin
    abort:=false;
    if Assigned(ACallBack)then
      ACallBack(nil,AState,AAct,AMax,abort);
    result:=abort;
  end;

  function Control(const ACommand:AnsiString;out AResponse:AnsiString):boolean;
  var buf:AnsiString;
      numRead,i:integer;
  begin
    FTPUpload:=123;
    result:=true;AResponse:='';

    if ACommand<>'' then begin
      buf:=ACommand+#13#10;
      if send(controlSocket,buf[1],length(buf),0)<0 then begin
        FTPUpload:=603;
        result:=false;
      end;
    end;

    if result then begin
      setlength(buf,$1000);
      numRead:=recv(controlSocket,buf[1],length(Buf),0);if numRead<0 then begin
        FtpUpload:=604;
        result:=false;
      end else begin
        setlength(buf,numRead);
        AResponse:=buf;

        i:=StrToIntDef(copy(AResponse,1,3),604);
        FTPUpload:=i;
        result:=i div 100 in[1,2,3];

        if not result then
          CB('FTP Hiba '+replacef(#13#10,'',AResponse,[roAll]),0,0);
      end;
    end;
  end;

var host,path,dstPath,dstFile:AnsiString;
    IPAddr,port:integer;

    buf,s:AnsiString;
    i:integer;

label cleanup;
//var wsadata:TWSAData;
begin
//  WSAStartup($101,wsadata);

  controlSocket:=0;
  dataSocket:=0;
  listenSocket:=0;

  i:=Pos('/',ADestination,[poBackwards]);
  if i=0 then begin
    dstPath:='';
    dstFile:=ADestination;
  end else begin
    dstPath:=copy(ADestination,1,i);
    dstFile:=copy(ADestination,i+1,$ffff);
  end;

  CB('FTP Kapcsolódás',0,0);

  if not _ExtractUrl(AUrl,host,port,path,21)then
    begin result:=605;exit end;

  IPAddr:=_getHostByName(host);if IPAddr=0 then
    begin result:=600;exit end;

  controlSocket:=_createSocket(stTCP,ATimeOut);if controlSocket=SOCKET_ERROR then
    begin result:=601;exit;end;

  if not _connect(controlSocket,IPAddr,Port)then
    begin result:=602;closesocket(controlSocket);exit;end;

  if not Control('',buf)then goto cleanup;
  if not Control('USER '+AUserName,buf)then begin goto cleanup;end;
  if not Control('PASS '+APassword,buf)then begin goto cleanup;end;
  //logged in
  if not Control('TYPE I',buf)then goto cleanup;

  if Passive then begin

    if not Control('PASV',buf)then goto cleanup;
    s:=FindBetween(buf,'(',')');
    IPAddr:=strtointdef(listitem(s,0,','),0)shl 0+
            strtointdef(listitem(s,1,','),0)shl 8+
            strtointdef(listitem(s,2,','),0)shl 16+
            strtointdef(listitem(s,3,','),0)shl 24;
    port:=  strtointdef(listitem(s,4,','),0)shl 8+
            strtointdef(listitem(s,5,','),0)shl 0;

    buf:='STOR '+dstfile+#13#10;
    if send(controlSocket,buf[1],length(buf),0)=SOCKET_ERROR then
      begin result:=603;goto cleanup end;

    dataSocket:=_createSocket(stTCP,ATimeout);if dataSocket=SOCKET_ERROR then
      begin result:=601;goto cleanup;end;

    if not _connect(dataSocket,IPAddr,Port)then
      begin result:=602;goto cleanup;end;

    if not Control('',buf)then goto cleanup;

  end else begin//active

    listenSocket:=_createSocket(stTCP,ATimeout);if listenSocket=SOCKET_ERROR then
      begin result:=601;goto cleanup end;

    if not _bind(listenSocket,INADDR_ANY,0)then
      begin result:=602;goto cleanup end;

    if listen(listenSocket,SOMAXCONN)=SOCKET_ERROR then
      begin result:=602;goto cleanup end;

    IPAddr:=GetLocalIP;
    port:=getSocketPort(listenSocket);

    s:=format('PORT %d,%d,%d,%d,%d,%d',[
      cardinal(IPAddr)shr  0 and $ff,
      cardinal(IPAddr)shr  8 and $ff,
      cardinal(IPAddr)shr 16 and $ff,
      cardinal(IPAddr)shr 24 and $ff,
      port shr 8 and $ff,
      port shr 0 and $ff]);
    if not control(s,buf)then goto cleanup;

    buf:='STOR '+dstfile+#13#10;
    if send(controlSocket,buf[1],length(buf),0)=SOCKET_ERROR then
      begin result:=603;goto cleanup end;

    i:=1;ioctlsocket(listenSocket,FIONBIO,i);

    i:=1000;while true do begin
      dataSocket:=accept(listenSocket,nil,nil);
      if dataSocket<>SOCKET_ERROR then break;
      if(dataSocket=SOCKET_ERROR)and(WSAGetLastError<>10035)then
        begin result:=607;goto cleanup;end;
      sleep(100);
      dec(i,100);
      if i<=0 then
        begin result:=602;goto cleanup;end;
    end;

    i:=0;ioctlsocket(listenSocket,FIONBIO,i);
    closesocket(listenSocket);listenSocket:=0;

    if not Control('',buf)then goto cleanup;

  end;
  //upload
  while ASource.Position<ASource.Size do begin
    setlength(buf,$1000);
    i:=ASource.Read(buf[1],length(buf));
    setlength(buf,i);
    repeat
      i:=send(dataSocket,buf[1],length(buf),0);
      if i=SOCKET_ERROR then begin
        if WSAGetLastError=10035 then begin i:=0;sleep(100);end else
          begin result:=604;goto cleanup end;
      end;
      if i>0 then delete(buf,1,i);
    until buf='';
    if CB('FTP Felküldés',ASource.Position,ASource.Size)then
      begin result:=608;goto cleanup end;
  end;
  closesocket(dataSocket);dataSocket:=0;

  if not Control('',buf)then goto cleanup;
  //Control('QUIT',buf);

  cleanup:
  if dataSocket<>0 then closesocket(dataSocket);
  if listenSocket<>0 then closesocket(listenSocket);
  if controlSocket<>0 then closesocket(controlSocket);
end;

var wsaData:TWSAData;

initialization
  WSAStartup($101,wsadata);
  TCPConnectionsLock:=TCriticalSection.Create;
finalization
  FreeAndNil(TCPConnectionsLock);
end.
