unit Mp3Decoder;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  mp3st, Snd, Het.Utils, FStream, math, syncobjs, mmsystem;

type TDecoderState=(Stopped,Playing,CueTuning);
type
  TMp3Decoder = class(TComponent)
  private
    { Private declarations }
{    fDecCached:longbool;}
    fname:ansistring;
    Fnextfname:ansistring;
    FStr,NextFStr:PFileStream;
    AStr:PAudioStream;
    FNextSongTrigger:integer;{ms}
    FCritSec:TCriticalSection;
    Function QueryFile:ansistring;Procedure OpenDecFile(name:ansistring);Procedure OpenDecMemory(const AData:rawbytestring);
    function GetDecState: TDecoderState;procedure SetDecState(const Value: TDecoderState);
    function GetTimePosition: single;procedure SetTimePosition(const Value: single);
    function GetSamplePosition: single;procedure SetSamplePosition(const Value: single);
    function GetTimeLength: single;function GetSampleLength: single;
    procedure SetPitch(const val:single);function GetPitch:single;
    procedure SetPitchAdd(const val:single);function GetPitchAdd:single;
    Function Getlastgrfail:integer;
{    procedure SetCached(const Value: longbool);}
  protected
    { Protected declarations }
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    { Published declarations }
    property CurFileName:ansistring read QueryFile write OpenDecFile;
    property NextFName:ansistring read FNextFName write FNextFName;
    property DecState:TDecoderState read GetDecState write SetDecState;
    property Pos_Sec:single read GetTimePosition write SetTimePosition;
    property Pos_Smp:single read GetSamplePosition write SetSamplePosition;
    property Length_Sec:single read GetTimeLength;
    property Length_Smp:single read GetSampleLength;
    property Pitch:single read GetPitch write SetPitch;
    property PitchAdd:single read GetPitchAdd write SetPitchAdd;
    property NextSongTrigger:integer read FNextSongTrigger write FNextSongTrigger;
    function PitchPercent:single;
{    procedure SetGain(g:single);
    procedure SetEqu(n:integer;v:single);
    procedure SetFilt(l,h:single);}
    procedure FileUpdate;
    procedure SndRead(var snd:TSnd;siz:integer);
    function Opened:boolean;
    procedure SetFilespec(s:ansistring);
    function FStream:PFileStream;
    function AStream:PAudioStream;
{    property DecCached:longbool read fDecCached write SetCached;}
    procedure SetCue(c:single);
    procedure SetLoop(l1,l2:single;act:boolean);
    property lastgrfail:integer read Getlastgrfail;
  end;

procedure Register;

function Mp3ToWav16M(const ASrc:rawbytestring):rawbytestring;

implementation

procedure Register;
begin
  RegisterComponents('MP3', [TMp3Decoder]);
end;

function Mp3ToWav16M(const ASrc:rawbytestring):rawbytestring;
type
  THdr=packed record
    riffId,riffLen,riffType:cardinal;
    fmtId,fmtSize:cardinal;fmt:TPCMWaveFormat;
    dataId,dataSize:cardinal;
  end;PHdr=^THdr;

const bufsize=256;
var d:TMp3Decoder;
    buf:TSnd;
    temp:RawByteString;
    i:integer;
begin
  setlength(result,sizeof(TPCMWaveFormat));
  with PHdr(result)^ do begin
    riffId:=$46464952;
    riffType:=$45564157;
    fmtId:=$20746D66;
    fmtSize:=SizeOf(TPCMWaveFormat);
    with fmt,wf do begin
      wFormatTag:=WAVE_FORMAT_PCM;
      nChannels:=1;
      nSamplesPerSec:=22050;
      wBitsPerSample:=16;
      nBlockAlign:=(wBitsPerSample shr 3)*wf.nChannels;
      nAvgBytesPerSec:=wf.nSamplesPerSec*nBlockAlign;
    end;
    dataId:=$61746164;
  end;

  d:=TMp3Decoder.Create(nil);
  try
    d.OpenDecMemory(ASrc);
    d.FileUpdate;
    d.DecState:=Playing;
    for i:=1 to 1000 do begin
//      if d.AStr.EOFReached then break;
      if d.Pos_Smp>=d.Length_Smp then break;
      d.SndRead(buf,bufsize);
      setlength(temp,bufsize*2);
//      Snd.SndAmplify(buf,100);
      SndWriteM16(buf,temp[1]);
      Result:=Result+temp;
    end;
  finally
    d.Free;
  end;

  with PHdr(result)^ do begin
    riffLen:=Length(Result)-8;
    dataSize:=Length(Result)-sizeof(THdr);
  end;
end;

{ TMp3Decoder }
Constructor TMp3Decoder.Create;
begin
  Inherited Create(AOwner);
{  DecCached:=true;}
  FCritSec:=TCriticalSection.Create;
  NextSongTrigger:=3000;
  New(FStr,Init(false));
  New(NextFStr,Init(false));
end;

Destructor TMp3Decoder.Destroy;
begin
  OpenDecFile('');
  Dispose(FStr,Done);
  Dispose(NextFstr,Done);
  freeandnil(FCritSec);
  inherited Destroy;
end;

procedure TMp3Decoder.FileUpdate;
var s:Single;
begin
  FCritSec.Enter;
  try
    FStr.Update;
    s:=Self.Length_Sec-Self.Pos_Sec;
    if(NextFName<>'')and(DecState=Playing)and(s>0)and(s<NextSongTrigger*0.001)then begin
      if NextFstr.fname<>NextFName then NextFStr.open(NextFName);
      NextFstr.Update;
    end;
    if AStr<>nil then
      AStr^.Update;
  finally
    FCritSec.Leave;
  end;
end;

function TMp3Decoder.GetPitch: single;
begin if AStr<>nil then result:=AStr^.pitch else result:=0;end;

function TMp3Decoder.GetPitchAdd: single;
begin if AStr<>nil then result:=AStr^.pitchAdd else result:=0;end;

function TMp3Decoder.GetSampleLength: single;
begin if AStr<>nil then result:=AStr^.len else result:=0;end;

function TMp3Decoder.GetSamplePosition;
begin if AStr<>nil then if AStr^.cue then result:=AStr^.CuePos else result:=AStr^.pos else result:=0 end;

function TMp3Decoder.GetDecState: TDecoderState;
begin
  result:=stopped;
  if AStr<>nil then
    if AStr^.Cue then result:=CueTuning
    else if AStr^.playing then result:=Playing;
end;

function TMp3Decoder.GetTimeLength: single;
begin result:=GetSampleLength*(1/44100)end;

function TMp3Decoder.GetTimePosition;
begin result:=GetSamplePosition*(1/44100)end;

procedure TMp3Decoder.OpenDecFile(name: ansistring);
  procedure CloseDec;
  var a:paudiostream;
  begin
    if AStr=nil then exit;
    Decstate:=stopped;
    a:=AStr;AStr:=nil;Dispose(A,Done);
    FCritSec.Enter;
    FStr.Close;{FStr.cached:=DecCached;}
    fname:='';
  end;
var ext:ansistring;A:PAudioStream;f1:pfilestream;
begin
  FCritSec.Enter;
  try
    CloseDec;
    fname:=name;
    if fname<>'' then begin
      ext:=uc(copy(fname,length(fname)-2,3));
      if fname=NextFStr.fname then begin
        f1:=NextFstr;NextFstr:=Fstr;Fstr:=f1;
      end else FStr.Open(fname);
      A:=nil;
      if ext='MP3'then A:=New(PMP3Stream,Init(FStr^)){else
      if ext='WAV'then A:=New(PRawStream,Init(FStr^))};
      if A=nil then Begin FStr.Close;{FStr.cached:=DecCached;}exit end;
      Astr:=A;
      Decstate:=stopped;
    end;
  finally
    FCritSec.Leave;
  end;
end;

procedure TMp3Decoder.OpenDecMemory(const AData:rawbytestring);
  procedure CloseDec;
  var a:paudiostream;
  begin
    if AStr=nil then exit;
    Decstate:=stopped;
    a:=AStr;AStr:=nil;Dispose(A,Done);
    FCritSec.Enter;
    FStr.Close;{FStr.cached:=DecCached;}
    fname:='';
  end;
//var ext:ansistring;f1:pfilestream;
begin
  FCritSec.Enter;
  try
    CloseDec;
    fname:='@memory';
    FStr.OpenMemory(AData);
    Astr:=New(PMP3Stream,Init(FStr^));
    Decstate:=stopped;
  finally
    FCritSec.Leave;
  end;
end;


function TMp3Decoder.QueryFile: ansistring;
begin result:=fname;end;

{procedure TMp3Decoder.SetEqu(n: integer; v: single);
begin if AStr<>nil then if range(1,n,5)=0then AStr^.equ[n-1]:=v;end;}

{procedure TMp3Decoder.SetGain(g: single);
begin if AStr<>nil then AStr^.Gain:=g end;}

procedure TMp3Decoder.SetPitch(const val: single);
begin if AStr<>nil then AStr^.pitch:=val end;

procedure TMp3Decoder.SetPitchAdd(const val: single);
begin if AStr<>nil then AStr^.pitchadd:=val end;

procedure TMp3Decoder.SetSamplePosition(const Value: Single);
begin if AStr<>nil then begin AStr^.Pos:=Value;Astr^.CuePos:=Value;end;end;

procedure TMp3Decoder.SetDecState(const Value: TDecoderState);
begin
  if AStr<>nil then case value of
    stopped:with AStr^do begin playing:=false;cue:=false;end;
    playing:with AStr^do begin playing:=true;cue:=false;end;
    cuetuning:with AStr^do begin playing:=true;cue:=true;end;
  end;
end;

procedure TMp3Decoder.SetTimePosition;
begin SetSamplePosition(Value*44100)end;

{procedure TMp3Decoder.SetFilt;
begin
  if Astr<>nil then begin
    Astr^.highpass:=h;
    Astr^.lowpass:=l;
  end;
end;}

procedure TMp3Decoder.SndRead;
begin
  if(AStr=nil)then begin
    SetLength(snd,siz);
    SndSilence(snd);
  end else begin
{    SetState(GetState);}
    FCritSec.Enter;
    try
      AStr^.Read(snd,siz);
    finally
      FCritSec.Leave;
    end;
  end;
end;

function TMp3Decoder.PitchPercent;
begin
  if Astr<>nil then begin
    result:=(power(2,Astr^.pitch){+Astr^.pitchAdd})*100-100;
  end else result:=0;
end;

function TMp3Decoder.Opened;
begin result:=(astr=nil)or(fstr.opened);end;

procedure TMp3Decoder.SetFileSpec;
begin
  FCritSec.Enter;
  try
    Fstr.fname:=s
  finally
    FCritSec.Leave;
  end;
end;

function TMp3Decoder.FStream: PFileStream;
begin
  result:=FStr;
end;

function TMp3Decoder.AStream: PAudioStream;
begin
  result:=AStr;
end;

{procedure TMp3Decoder.SetCached(const Value: longbool);
begin
  fDecCached := Value;
end;}

procedure TMp3Decoder.SetCue(c: single);
begin
  if c<0 then c:=0;
  if astr<>nil then Astr^.CuePos:=c;
end;

procedure TMp3Decoder.SetLoop(l1, l2: single; act: boolean);
begin
  if astr=nil then exit;
  astr^.LoopStart:=l1;
  astr^.LoopEnd:=l2;
  astr^.LoopOn:=act;
end;

function TMp3Decoder.Getlastgrfail: integer;
begin
  result:=0;
  if astr=nil then exit;
  result:=PMp3Stream(astr)^.nextgrfail;
end;

end.
