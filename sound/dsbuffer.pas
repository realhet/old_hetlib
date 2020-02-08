unit DSBuffer;//musicmath

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  MMSystem, DirectSound, Snd, het.utils, syncobjs;

type tNotifyDSProcess=procedure(Sender:TObject;dst:pointer;Samples,Rate,Channels,BitsPerSample:integer)of Object;
     tNotifySndRead=procedure(Sender:TObject;Var Sn:TSnd;siz:integer)of Object;

type
  TDSBuffer=class;

  TDSUpdateThread=class(TThread)
  public
    working:boolean;
    DSBuffer:TDSBuffer;
    procedure Execute; override;
  end;

  TDSBuffer = class(TComponent)
  private
    { Private declarations }
    ds:IDirectSound8;
    dsb:IDirectSoundBuffer;
    BufMax,NextWriteOffset,MinBufSize,BlkSize:integer;{smp-ben}
    _OnProcess:tNotifyDSProcess;
    SndRead:tNotifySndRead;
    smpShl:integer;
    synch:TDSBuffer;

    CS:TCriticalSection;
    procedure SetPrior(p:tthreadPriority);
    Function GetPrior:tthreadPriority;
    function GetOpened: boolean;
  protected
    { Protected declarations }
  public
    { Public declarations }
    hz,bps,chn:integer;
    LastMsg:string;
    BufferOverrun:integer;
    SmpWritten:integer;{smp}
    SynchDistance:integer;{smpben}
    UpdateThread:TDSUpdateThread;
    constructor Create(o:tcomponent);override;
    destructor Destroy;override;
    property Opened:boolean read GetOpened;
  published
    { Published declarations }
    Function Open(g:pguid;hnd:hwnd;_khz, _chn, _bps: integer): boolean;
    Function UpdateBuffer:integer;{bytes written}
    Procedure Close;
    property MinBufferSize:integer read MinBufSize write MinBufSize;
    property BlockSize:integer read BlkSize write BlkSize;
    property OnProcess:tNotifyDSProcess read _OnProcess write _OnProcess;
    property SynchTo:TDSBuffer read synch write synch;
    property UpdatePriority:TThreadPriority read GetPrior write SetPrior;
    property OnSndRead:TNotifySndRead read SndRead write SndRead;
  end;

  TDSCapture=class;

  TDSCaptureUpdateThread=class(TThread)
  public
    working:boolean;
  protected
    DSCapture:TDSCapture;
    procedure Execute; override;
  end;

  TDSCapture=class(TComponent)
  private
    ds:IDirectSoundCapture8;
    dsb:IDirectSoundCaptureBuffer;
    BlkSize,MinBufSize:integer;
    SmpRead,smpShl,bufMax:integer;
    FOnSnd:tNotifySndRead;
    CS:TCriticalSection;
    Function UpdateBuffer:integer;
  public
    { Public declarations }
    UpdateThread:TDSCaptureUpdateThread;
    hz,bps,chn:integer;
    LastMsg:string;
    constructor Create(o:tcomponent);override;
    Function Open(g:pguid;hnd:hwnd;_khz, _chn, _bps: integer): boolean;
    procedure Close;
    destructor Destroy;override;
  published
    property BlockSize:integer read BlkSize write BlkSize;
    property MinBufferSize:integer read MinBufSize write MinBufSize;
    property OnSnd:tNotifySndRead read FOnSnd write FOnSnd;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Het', [TDSBuffer,TDSCapture]);
end;

{ TDSBuffer }

procedure TDSBuffer.Close;
begin
  CS.Enter;
  try
    UpdateThread.Working:=false;
    if Assigned(DSB)then begin
      DSB.Stop;
      DSB:=nil;
    end;
  finally
    CS.Leave;
  end;
end;

constructor TDSBuffer.Create(o: tcomponent);
begin
  inherited Create(o);
  CS:=TCriticalSection.Create;
  BlkSize:=2048;
  MinBufSize:=2048;
  UpdateThread:=TDSUpdateThread.Create(true);
  UpdateThread.DSBuffer:=self;
  UpdateThread.working:=false;
  UpdateThread.Start;
end;

destructor TDSBuffer.Destroy;
begin
  Close;
  UpdateThread.Terminate;
  UpdateThread.WaitFor;
  UpdateThread.Free;
  FreeAndNil(CS);
  inherited Destroy;
end;

function TDSBuffer.GetOpened: boolean;
begin
  result:=(UpdateThread<>nil)and UpdateThread.Working;
end;

function TDSBuffer.GetPrior: tthreadPriority;
begin
  result:=UpdateThread.Priority;
end;

function TDSBuffer.Open(g:pguid;hnd:hwnd;_khz, _chn, _bps: integer): boolean;

  procedure Close;
  begin
    UpdateThread.Working:=false;
    if Assigned(DSB)then begin
      DSB.Stop;
      DSB:=nil;
    end;
  end;

var fmt:TWaveFormatEx;
    dsbd:TDSBufferDesc;
    caps:TDSBCAPS;
    dscaps:TDSCaps;
    temp:dword;
begin
  result:=false;

  CS.Enter;
  try
    Close;
    case _khz of 48:hz:=48000;44:hz:=44100;22:hz:=22050;11:hz:=11025;else begin LastMsg:='Invalid samplerate';exit;end;end;
    if(_chn<>1)and(_chn<>2)and(_chn<>4)then begin LastMsg:='Invalid number of channels';exit;end;chn:=_chn;
    if(_bps<>8)and(_bps<>16)then begin LastMsg:='Invalid bits per sample';exit;end;bps:=_bps;
    if ds=nil then if DirectSoundCreate8(g,ds,nil)<>0 then raise exception.Create('DirectSoundCreate() failed');
    ds.SetSpeakerConfig(0);
    {check capabilities}
    dscaps.dwSize:=sizeof(dscaps);
    ds.GetCaps(dscaps);
    if dscaps.dwFlags and DSCAPS_EMULDRIVER<>0 then begin LastMsg:='DirectSound driver required';CLose;exit;end;
    if dsCaps.dwFlags and  DSCAPS_PRIMARYSTEREO=0 then chn:=1;
    if dsCaps.dwFlags and DSCAPS_PRIMARY16BIT=0 then begin bps:=8;{hz:=22050;}end;
    ds.SetCooperativeLevel(hnd,DSSCL_WRITEPRIMARY);
    {creating dsb}
    fillchar(dsbd,sizeof(dsbd),0);
    dsbd.dwSize := sizeof( dsbd );
    dsbd.dwFlags:= DSBCAPS_LOCSOFTWARE or
                   DSBCAPS_STICKYFOCUS or
//                   DSBCAPS_GLOBALFOCUS or
                   DSBCAPS_GETCURRENTPOSITION2
                   or DSBCAPS_PRIMARYBUFFER;

    if ds.CreateSoundBuffer(dsbd,dsb,nil)<>0 then begin LastMsg:='CreateSoundBuffer() failed';CLose;exit;end;
    {set format}
    fillchar(fmt,sizeof(fmt),0);

    with fmt do begin
      wFormatTag:=WAVE_FORMAT_PCM;
      nChannels:=chn;
      nSamplesPerSec:=hz;
      wBitsPerSample:=bps;
      nBlockAlign:=nChannels*(wBitsPerSample shr 3);
      nAvgBytesPerSec:=nSamplesPerSec*nBlockAlign;
    end;
    dsb.SetFormat(@fmt);
    {check format}
    dsb.GetFormat(@fmt,sizeof(fmt),@temp);
    hz:=fmt.nSamplesPerSec;
    chn:=fmt.nchannels;
    bps:=fmt.wBitsPerSample;
    fmt.nBlockAlign:=chn*bps shr 3;
    case fmt.nBlockAlign of
      1:SmpShl:=0;
      2:SmpShl:=1;
      4:SmpShl:=2;
      8:SmpShl:=3;
    end;
  {  bps:=fmt.wBitsPerSample;}
    {get buffersize}
    caps.dwSize:=sizeof(caps);
    dsb.GetCaps(caps);
    bufMax:=caps.dwBufferBytes shr SmpShl;
    {start playin'}
    SmpWritten:=0;dsb.Play(0,0,DSBPLAY_LOOPING);
    result:=true;
    UpdateThread.working:=true;
  finally
    CS.Leave;
  end;
end;

procedure TDSBuffer.SetPrior(p: tthreadPriority);
begin
  UpdateThread.Priority:=p;
end;

Function TDSBuffer.UpdateBuffer;

  function Distance(play,write:integer):integer;
  begin result:=write-play;if result<0 then result:=result+bufmax;end;

  procedure TruncForward(var value:integer);
  begin if value>=bufmax then dec(value,bufmax)end;

var Play, FakeWrite:integer;
    dwStatus:DWORD       ;
    r:hresult;
    ValidData,WriteLength:integer;

  Procedure Overrun;
  begin
    inc(BufferOverrun);
    NextWriteOffset:=Play+MinBufSize;TruncForward(NextWriteOffset);
    WriteLength:=BlockSize;
    LastMsg:='Overrun ('+inttostr(bufferoverrun)+')';
  end;

  Function WriteIt:boolean;
  var lpWrite1, lpWrite2:pointer;
      dwLen1, dwLen2:DWord;
      bpos,badd:integer;
      StretchBuffer:array[0..16383]of byte;

    procedure StretchOne(s,p:pointer;len:integer);var i:integer;
    type a1=array[0..$10000]of shortint;
         a2=array[0..$8000]of smallint;
         a4=array[0..$4000]of dword;
    begin
      case SmpShl of
        0:for i:=0 to len-1 do begin
            a1(p^)[i]:=a1(s^)[bpos shr 10];
            bpos:=bpos+badd;
          end;
        1:for i:=0 to len-1 do begin
            a2(p^)[i]:=a2(s^)[bpos shr 10];
            bpos:=bpos+badd;
          end;
        2:for i:=0 to len-1 do begin
            a4(p^)[i]:=a4(s^)[bpos shr 10];
            bpos:=bpos+badd;
          end;
      end;
    end;

    procedure Reader(var dst;samples:integer);
    var Sn:TSnd;
    begin
      if Assigned(OnSndRead)then begin
        case hz of
          48000:OnSndRead(self,Sn,samples);{no convert!!!}
          44100:OnSndRead(self,Sn,samples);
          22050:begin OnSndRead(self,Sn,samples*2);SndHalve(Sn);end;
          11025:begin OnSndRead(self,Sn,samples*4);SndHalve(Sn);SndHalve(Sn);end;
          else exit;
        end;
        SetLength(sn,samples);
        SndWrite(sn,dst,chn,bps,bps=16);
      end else if Assigned(OnProcess)then
        OnProcess(self,@dst,samples,hz,chn,bps)
      else fillchar(dst,samples shl SmpShl,0);
    end;

  begin
    result:=false;
    if dsb.Lock(NextWriteOffset shl SmpShl,WriteLength shl SmpShl,@lpWrite1, @dwLen1,@lpWrite2, @dwLen2,0 )<>0 then begin LastMsg:='Lock() failed ';exit end;
    if(WriteLength=BlkSize)and(dwLen2=0) then begin
      if(dwLen1<>0)then Reader(lpWrite1^,dwLen1 shr SmpShl);
    end else begin {Stretchin'}
      Reader(StretchBuffer,BlkSize);
      bpos:=0;badd:=BlkSize shl 10 div WriteLength;
      if dwLen1<>0 then stretchOne(@Stretchbuffer,lpwrite1,dwLen1 shr SmpShl);
      if dwLen2<>0 then stretchOne(@Stretchbuffer,lpwrite2,dwLen2 shr SmpShl);
    end;
    dsb.Unlock( lpWrite1, dwLen1,lpWrite2, dwLen2 );
    NextWriteOffset := NextWriteOffset+WriteLength;TruncForward(NextWriteOffset);
    inc(SmpWritten,BlkSize);
    result:=true;
  end;

begin
  result:=-1;

  CS.Enter;
  try
    if not assigned(ds)then begin LastMsg:='Not assigned DirectSound';exit;end;
    if not assigned(dsb)then begin LastMsg:='Not assigned DirectSoundBuffer';exit;end;
  {maintenance}
    dsb.GetStatus(dwStatus);
    if (DSBSTATUS_BUFFERLOST and dwStatus)<>0then begin
      r := dsb.Restore;
      dsb.Play(0, 0, DSBPLAY_LOOPING );
      if r<>0 then begin LastMsg:='Restore() failed';exit;end;
      NextWriteOffset := 0;SmpWritten:=0;
    end;
    if(synch=nil)or(synch=self)then begin
      {check}
      dsb.GetCurrentPosition( @Play, @FakeWrite );Play:=Play shr SmpShl;
      ValidData:=Distance(Play,NextWriteOffset);
      if ValidData>MinBufSize+BlkSize then Overrun
      else if ValidData>MinBufSize then begin
        result:=0;exit
      end else WriteLength:=BlkSize;
      if not WriteIt then exit;
    end else begin
      synch.CS.Enter;
      try
        BlkSize:=synch.BlkSize;
        if Synch.SmpWritten-SmpWritten<>BlkSize then begin
          SmpWritten:=Synch.SmpWritten;exit;
        end;
        {synch kiirt egy blockot...}
        {check}
        if synch.hz>hz then BlkSize:=BlkSize shr 1 else
        if synch.hz<hz then BlkSize:=BlkSize shl 1;
        dsb.GetCurrentPosition( @Play, @FakeWrite );Play:=Play shr SmpShl;
        ValidData:=Distance(Play,NextWriteOffset);
        if(ValidData<MinBufSize+MinBufSize+BlkSize)or(ValidData>BufMax-MinBufSize) then begin
          if validdata>BufMax-MinBufSize then ValidData:=ValidData-bufmax;
          SynchDistance:=(((MinBufSize+BlkSize shr 1)-ValidData)*16)div BlkSize;
        end else begin
          overrun;inc(NextWriteOffset,BlkSize);
          TruncForward(NextWriteOffset);SynchDistance:=0;
        end;
        if SynchDistance>BlkSize shr 4 then SynchDistance:=BlkSize shr 4 else if SynchDistance<-(BlkSize shr 2) then SynchDistance:=-(BlkSize shr 4);
        WriteLength:=BlkSize+SynchDistance;
        if not WriteIt then begin
          exit;
        end;
        SmpWritten:=SmpWritten-BlkSize;
        BlkSize:=synch.BlkSize;
        SmpWritten:=SmpWritten+BlkSize;
      finally
        synch.CS.Leave;
      end;
    end;
    result:=BlkSize;
  finally
    CS.Leave;
  end;
end;

{ TDSUpdateThread }

procedure TDSUpdateThread.Execute;
begin
  while not terminated do begin
    if working then
      if Assigned(DSBuffer)then with DSBuffer do
        UpdateBuffer;
    sleep(1);
  end;
end;

{ TDSCapture }

procedure TDSCapture.Close;
begin
  CS.Enter;
  try
    UpdateThread.Working:=false;
    if Assigned(DSB)then begin
      DSB.Stop;
      DSB:=nil;
    end;
  finally
    CS.Leave;
  end;
end;

constructor TDSCapture.Create(o: tcomponent);
begin
  inherited;
  CS:=TCriticalSection.Create;

  MinBufSize:=2048;
  BlkSize:=2048;

  UpdateThread:=TDSCaptureUpdateThread.Create(true);
  UpdateThread.DSCapture:=self;
  UpdateThread.working:=false;
  UpdateThread.Start;
end;

destructor TDSCapture.Destroy;
begin
  Close;
  UpdateThread.Terminate;
  UpdateThread.WaitFor;
  FreeAndNil(UpdateThread);
  FreeAndNil(CS);
  inherited;
end;

function TDSCapture.Open(g: pguid; hnd: hwnd; _khz, _chn,_bps: integer): boolean;

  procedure Close;
  begin
    UpdateThread.Working:=false;
    if Assigned(DSB)then begin
      DSB.Stop;
      DSB:=nil;
    end;
  end;

var fmt:TWaveFormatEx;
    dsbd:TDSCBufferDesc;
    caps:TDSCBCAPS;
    dscaps:TDSCCaps;
    i:integer;
begin
  result:=false;

  CS.Enter;
  try
    Close;
    case _khz of 48:hz:=48000;44:hz:=44100;22:hz:=22050;11:hz:=11025;else begin LastMsg:='Invalid samplerate';exit;end;end;
    if(_chn<>1)and(_chn<>2)and(_chn<>4)then begin LastMsg:='Invalid number of channels';exit;end;chn:=_chn;
    if(_bps<>8)and(_bps<>16)then begin LastMsg:='Invalid bits per sample';exit;end;bps:=_bps;
    if ds=nil then if DirectSoundCaptureCreate8(g,ds,nil)<>0 then raise exception.Create('DirectSoundCreate() failed');
    {check capabilities}
    dscaps.dwSize:=sizeof(dscaps);
    ds.GetCaps(dscaps);
    if dscaps.dwFlags and DSCCAPS_EMULDRIVER<>0 then begin LastMsg:='DirectSound driver required';Close;exit;end;
  {  if dsCaps.dwFlags and DSCAPS_PRIMARYSTEREO=0 then chn:=1; old SB2.0 stuff
    if dsCaps.dwFlags and DSCAPS_PRIMARY16BIT=0 then begin bps:=8;end; old SB2.0 stuff}

    {set format}
    fillchar(fmt,sizeof(fmt),0);
    with fmt do begin
      wFormatTag:=WAVE_FORMAT_PCM;
      nChannels:=chn;
      nSamplesPerSec:=hz;
      wBitsPerSample:=bps;
      nBlockAlign:=nChannels*(wBitsPerSample shr 3);
      nAvgBytesPerSec:=nSamplesPerSec*nBlockAlign;
    end;
    {creating dsb}
    fillchar(dsbd,sizeof(dsbd),0);
    dsbd.dwSize := sizeof( dsbd );
    dsbd.dwFlags:= 0;
    dsbd.dwBufferBytes:=(BlkSize*2)*fmt.nBlockAlign;
    dsbd.lpwfxFormat:=@fmt;
    if ds.CreateCaptureBuffer(dsbd,dsb,nil)<>0 then begin LastMsg:='CreateSoundBuffer() failed';Close;exit;end;
    {check format}
    dsb.GetFormat(@fmt,SizeOf(fmt),PDWORD(@i));
    hz:=fmt.nSamplesPerSec;
    chn:=fmt.nchannels;
    bps:=fmt.wBitsPerSample;
    fmt.nBlockAlign:=chn*bps shr 3;
    case fmt.nBlockAlign of
      1:SmpShl:=0;
      2:SmpShl:=1;
      4:SmpShl:=2;
      8:SmpShl:=3;
    end;
    {get buffersize}
    caps.dwSize:=sizeof(caps);
    dsb.GetCaps(caps);
    bufMax:=caps.dwBufferBytes shr SmpShl;
    {start playin'}
    SmpRead:=0;dsb.Start(DSCBSTART_LOOPING);
    result:=true;
    UpdateThread.working:=true;
  finally
    CS.Leave;
  end;
end;

Function TDSCapture.UpdateBuffer;

function Distance(cap,read:integer):integer;
begin result:=read-cap;if result<0 then result:=result+bufmax;end;

var
  CapturePos:integer;

  p,p1,p2:PSmallInt;
  c1,c2:cardinal;
  sn:TSnd;
  i:integer;
begin
  result:=-1;

  CS.Enter;
  try
    if not assigned(ds)then begin LastMsg:='Not assigned DirectSound';exit;end;
    if not assigned(dsb)then begin LastMsg:='Not assigned DirectSoundBuffer';exit;end;
    {maintenance}

    {check}
    dsb.GetCurrentPosition(PDWORD(@CapturePos),nil);CapturePos:=CapturePos shr smpShl;
    if(SmpRead=0)<>(CapturePos<BlockSize)then begin
      dsb.Lock((BlkSize-SmpRead) shl smpShl,BlockSize shl smpShl,@p1,@c1,@p2,@c2,0);

      i:=length(sn);
      setlength(sn,blocksize);
      for i:=i to high(sn)do begin sn[i,0]:=0;sn[i,1]:=0;end;

      p:=p1;
      if(p<>nil)and(integer(c1)=blocksize shl smpshl)then begin
        for i:=0 to high(sn)do begin
          sn[i,0]:=p^*(1/32768);inc(p);
          sn[i,1]:=p^*(1/32768);inc(p);
        end;
      end;

      dsb.Unlock(p1,c1,p2,c2);
      if Assigned(OnSnd)then
        try OnSnd(self,sn,length(sn));except end;

      SmpRead:=switch(SmpRead=0,BlkSize,0);
    end;

    result:=BlkSize;
  finally
    CS.Leave;
  end;
end;


{ TDSCaptureUpdateThread }

procedure TDSCaptureUpdateThread.Execute;
begin
  while not terminated do begin
    if working then begin
      if Assigned(DSCapture)then with DSCapture do begin
        UpdateBuffer;
      end;
    end;
    sleep(1);
  end;
end;

end.
