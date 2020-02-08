unit het.Midi;                    //URMidi

interface

uses
  windows, sysutils, classes, controls, stdctrls, extctrls, mmsystem, math,
  het.Utils, het.Objects, het.Arrays, dialogs{, UObj};

type
  TMidiEvent=record
    chn,cmd,data1,data2:byte;
  end;

  TMidiEventArray=THetArray<integer>;

//Usage: Create a TMidiConnectionInstance;

function DecodeMidiEvent(const m:integer):TMidiEvent;
function EncodeMidiEvent(const m:TMidiEvent):integer;overload;
function EncodeMidiEvent(const chn,cmd,data1:byte;const data2:byte=0):integer;overload;

type
  TMidiTimedEvent=record
    time_s:single;
    event:Integer;
  end;
  TMidiTrk=TArray<TMidiTimedEvent>;

function LoadMidiTrk(const AData:ansistring):TMidiTrk;
function MidiTrkDuration(const trk:TMidiTrk):single;
function FindMidiTrkPos(const trk:TMidiTrk;const APos_s:single):integer;

type
  PMidiState=^TMidiState;
  TMidiState=record
    Events:TMidiEventArray;
    RawKey,Key{Sustained},KeyPressCnt{to detect presses}:array[0..127]of byte;
    CC7:array[0..127]of byte;
    CC14:array[0..$1F]of word;
    Precision:array[0..$1F]of boolean;
    Prg:byte;
    ChnPressure:byte;
    Pitch:word;
    procedure ReceiveEvent(AEvent:integer);

    procedure SetCC7(const id,value:byte);
    procedure SetCC14(const id:byte;const value:word);
    procedure SetPrg(const value:byte);
    procedure SetChnPressure(const value:byte);
    procedure SetPitch(const value:word);
    procedure SetNoteOn(const AKey,AVolume:byte);
    procedure SetNoteOff(const AKey:byte);
    procedure SetAfterTouch(const AKey:byte;const AVolume:byte);

    function SustainPedal:byte;

    //procedure ReceiveMidiTrk(const Trk:TMidiTrk;const actTime_s:single;var firstEventIdx:integer;const silent:boolean=false);
    procedure clear;
    function ReceiveMidiTrk(const Trk:TMidiTrk;var actTime_s:single;var firstEventIdx:integer;const silent:boolean=false;const stPractice:PMidiState=nil):boolean;
  end;

  TMidiConnection=class;

  TMidiDevice=class(THetObject)
  private
    FName:ansistring;
    FHandle:THandle;
    FIsInput:Boolean;
    FExists:Boolean;
    FOpened:Boolean;
    FState:ansistring;
    _Found:boolean;//for device enumeration
    _LastPoll:TDateTime;//utolso beavatkozas ideje
    procedure WriteEvents(const ev:TMidiEventArray);
    procedure SetExists(const Value: boolean);
    procedure SetName(const Value: ansistring);
    procedure SetState(const Value: ansistring);

    function Open:boolean;
    procedure Close;
    procedure ProcessMidiIn(const msg:integer);
  public
    constructor Create(const AOwner:THetObject);override;
    Destructor Destroy;override;
    function OwnerConnection:TMidiConnection;
  published
    property Name:ansistring read FName write SetName;
    property Exists:boolean read FExists write SetExists;
    property isInput:boolean read FIsInput;
    property Opened:boolean read FOpened;
    property State:ansistring read FState write SetState;
  end;
  TMidiDevices=class(THetList<TMidiDevice>)
  end;

  TMidiConnection=class(THetObject)
  private
    FEnabled:boolean;
    FInputs,FOutputs:ansistring;
    FReceivedEvents:TMidiEventArray;
    procedure SetEnabled(const Value: boolean);
    procedure SetInputs(const Value: ansistring);
    procedure SetOutputs(const Value: ansistring);
  public
    State:TMidiState;
    constructor Create(const AOwner:THetObject);override;
    destructor Destroy;override;

    function ReadEvents:boolean;
    procedure WriteEvents;
    //use
    function InputDevices:TArray<TMidiDevice>;
    function OutputDevices:TArray<TMidiDevice>;
    //setup
    function AllInputDevices:TMidiDevices;
    function AllOutputDevices:TMidiDevices;
    //simulate event
    procedure SimulateInputEvent(ev:integer);

    procedure Silence;
  published
    property Enabled:boolean read FEnabled write SetEnabled;
    property Inputs:ansistring read FInputs write SetInputs;
    property Outputs:ansistring read FOutputs write SetOutputs;
  end;
  TMidiConnections=class(THetList<TMidiConnection>)
  end;

  TMidi=class(THetList<TMidiConnection>)
  private
    FInputDevices:TMidiDevices;
    FOutputDevices:TMidiDevices;
    FTimer:TTimer;
    procedure UpdateDevices(Sender:TObject=nil);
  public
    constructor Create(const AOwner:THetObject);override;
    destructor Destroy;override;
  published
    property InputDevices:TMidiDevices read FInputDevices;
    property OutputDevices:TMidiDevices read FOutputDevices;
  end;

procedure midiLock;
procedure midiUnLock;

implementation

var
  g_MidiConnections:THetArray<TMidiConnection>;
  g_Midi:TMidi=nil;

function Midi:TMidi;
begin
  if g_Midi=nil then g_Midi:=TMidi.Create(nil);
  result:=g_Midi;
end;

procedure midiLock;
begin
  MonitorEnter(Midi);
end;

procedure midiUnLock;
begin
  MonitorExit(Midi);
end;


function DecodeMidiEvent(const m:integer):TMidiEvent;
begin with result do begin
  chn:=m and $f;
  cmd:=m shr 4 and $f;
  data1:=pbyte(psucc(@m,1))^;
  data2:=pbyte(psucc(@m,2))^;
end;end;

function EncodeMidiEvent(const m:TMidiEvent):integer;inline;
begin with m do begin
  result:=chn+cmd shl 4+data1 shl 8+data2 shl 16;
end;end;

function EncodeMidiEvent(const chn,cmd,data1:byte;const data2:byte=0):integer;inline;
begin
  result:=chn+cmd shl 4+data1 shl 8+data2 shl 16;
end;

//debug stuff
var SysExData:TArray<byte>;
    SysExHex:ansistring;
    DebugOfs:integer;

function LoadMidiTrk(const AData:ansistring):TMidiTrk;
  procedure Error(s:string);begin raise Exception.Create('LoadMidiTrk() '+s)end;

  procedure merge(const src:TArray<TMidiTimedEvent>);
  var a,b:integer;
      tmp:TArray<TMidiTimedEvent>;
      res:THetArray<TMidiTimedEvent>;
  begin
    if src=nil then exit;
    if Result=nil then begin result:=src;exit end;

    tmp:=result;

    a:=0;b:=0;
    while(a<length(src))or(b<length(tmp))do begin
      if a>=length(src) then res.Append(tmp[postinc(b)])else
      if b>=length(tmp) then res.Append(src[postinc(a)])else
      if src[a].time_s<=tmp[b].time_s then res.Append(src[postinc(a)])
                                      else res.Append(tmp[postinc(b)]);
    end;

    res.Compact;
    result:=res.FItems;
  end;


var res:THetArray<TMidiTimedEvent>;
    p,pend,pOld:pbyte;
    acttime,deltaUnit:single;
    tick,ev,i:integer;
    ticksPerQuarter:integer;
    lastCmd:integer;

label MTrk;
begin
  result:=nil;

  if(Copy(AData,1,4)<>'MThd')or(Copy(AData,14+1,4)<>'MTrk')then
    Error('Invalid midi data');

  p:=@AData[22+1];
  pend:=psucc(p,min(ByteOrderSwap(pinteger(@AData[18+1])^),length(AData)-22));

  ticksPerQuarter:=ByteOrderSwap(PWord(@AData[12+1])^);
  deltaUnit:=120{bpm rossz}/60{minute}/4{quarter}/ticksPerQuarter{ticks/quarter};  //ez is rossz

//  deltaUnit:=deltaUnit/150*120;

//  deltaUnit:=ticksPerQuarter/1000000; faszsag!

MTrk:
  res.Clear;
  acttime:=0; lastCmd:=0;
  while integer(p)<integer(pend)do begin
    //read delta ticks
    tick:=0;
    for i:=0 to 3 do begin
      tick:=tick shl 7+(p^ and $7F);
      if(p^ and $80)=0 then begin inc(p);break end;
      inc(p);
    end;

    //advance acttime
    acttime:=acttime+tick*deltaUnit;

    //read midi event
    if(p^ and $80)=0 then begin //prev cmd
      ev:=lastCmd;
      dec(p);
    end else begin
      ev:=p^;
      lastCmd:=ev;
    end;

    DebugOfs:=integer(p)-integer(@Adata[1]);

    if(ev and $80)=0 then begin
      ev:=lastCmd; dec(p);
    end;

    case ev shr 4 of
      $8..$B,$E:begin inc(p); ev:=ev+p^ shl 8;inc(p); ev:=ev+p^ shl 16; inc(p);end;
      $C,$D:    begin inc(p); ev:=ev+p^ shl 8;inc(p); end;
      $F:       begin
        inc(p); ev:=ev+p^ shl 8;inc(p); ev:=ev+p^ shl 16; inc(p); pOld:=p;  inc(p,ev shr 16{len});
        setlength(SysExData,(ev shr 16)and $ff);
        if SysExData<>nil then begin
          Move(pOld^,SysExData[0],length(SysExData));

          SysExHex:=BinToHex(DataToStr(SysExData[0],length(SysExData)));
        end else
          SysExHex:='';

        //sysex cuccok
        if(ev and $ff)=$ff then case ev shr 8 and $FF of
          1:{author};
          2:{copyright};
          3:{title};
          $59:{chord sign};
          $51:begin {tempo}

          end;
          $58:begin {time sign}

          end;
        end;
      end;
    else
      error('invalid command byte: $'+inttohex(p^,2));
    end;

    if(ev shr 4 and $F)in[8..$E]then with res.FItems[res.Append]do begin
      time_s:=acttime;
      event:=ev;
    end;

  end;

  res.Compact;
  Merge(res.FItems);

  if(integer(@AData[length(AData)])>integer(p))and(StrMake(p,4)='MTrk')then begin
    i:=ByteOrderSwap(pinteger(psucc(p,4))^); //size
    p:=psucc(p,8); //seek to next data
    pend:=psucc(p,i); //calculate end

    goto MTrk;
  end;
end;

function MidiTrkDuration(const Trk:TMidiTrk):single;
begin
  if Length(Trk)=0 then exit(0);
  result:=Trk[high(Trk)].time_s;
end;

function FindMidiTrkPos(const trk:TMidiTrk;const APos_s:single):integer;
var i:integer;
begin
  for i:=0 to high(trk)do if trk[i].time_s>=APos_s then exit(i);
  result:=-1;
end;

{ TMidiState }

procedure TMidiState.clear;
begin
  Events.Clear;
  FillChar(self,sizeof(self),0);
end;

procedure TMidiState.ReceiveEvent(AEvent:integer);

  procedure SetKeyVelo(k,v:byte);
  begin
    RawKey[k]:=v;
    if v>0 then begin
      inc(keyPressCnt[k]);
      Key[k]:=v;
    end else begin
      if SustainPedal<64 then
        Key[k]:=0;
    end;
  end;

var lastEvent,i:integer;
begin
  if AEvent=$FE {active sens} then exit;
  AEvent:=AEvent and $7F7FFF;

  if Events.Count>0 then lastEvent:=Events.FItems[Events.FCount-1]else LastEvent:=-1;
  Events.Append(AEvent);
  with DecodeMidiEvent(AEvent)do case cmd of
    $8:SetKeyVelo(data1,0);
    $9:SetKeyVelo(data1,data2);
    $A:begin RawKey[data1]:=data2;Key[data1]:=data2 end;//aftertouch
    $B:begin
      CC7[data1]:=data2;
      if(data1 in[$20..$3F])and((lastEvent and $FFFF)=(AEvent and $FFFF-$2000))then begin
        CC14[data1-$20]:=CC7[data1-$20]shl 7 or CC7[data1];
        Precision[data1-$20]:=true;
      end else
        if (data1 in[$0..$1F])then
          Precision[data1]:=false;

      if(data1=$40)and(Data2<64)then begin //sustain released
        for i:=0 to high(Key)do if RawKey[i]=0 then Key[i]:=0;
      end;
    end;
    $C:Prg:=data1;
    $D:ChnPressure:=data1;
    $E:Pitch:=data1 or data2 shl 7;
  end;
end;

function TMidiState.ReceiveMidiTrk(const Trk:TMidiTrk;var actTime_s:single;var firstEventIdx:integer;const silent:boolean=false;const stPractice:PMidiState=nil):boolean;
var i:integer;
begin
  i:=EnsureRange(firstEventIdx,0,length(Trk));

  while(i<length(Trk))and(Trk[i].time_s<=actTime_s)do begin

    if(stPractice<>nil)then with DecodeMidiEvent(trk[i].event)do if(cmd=9)and(data2>0)then begin
      if stPractice.RawKey[data1]=0 then begin
        actTime_s:=trk[i].time_s;
        exit(false);
      end;
    end;

    if not silent then ReceiveEvent(Trk[i].event);
    inc(i);
    firstEventIdx:=i;
  end;
  result:=true;
end;

procedure TMidiState.SetNoteOff(const AKey: byte);
begin
  ReceiveEvent(EncodeMidiEvent(0,$8,AKey,0));
end;

procedure TMidiState.SetNoteOn(const AKey, AVolume: byte);
begin
  ReceiveEvent(EncodeMidiEvent(0,$9,AKey,AVolume));
end;

procedure TMidiState.SetAfterTouch(const AKey, AVolume: byte);
begin
  ReceiveEvent(EncodeMidiEvent(0,$A,AKey,AVolume));
end;

procedure TMidiState.SetCC7(const id, value: byte);
begin
  ReceiveEvent(EncodeMidiEvent(0,$B,id,value));
end;

procedure TMidiState.SetCC14(const id: byte; const value: word);
begin
  ReceiveEvent(EncodeMidiEvent(0,$B,id,value shr 7));
  ReceiveEvent(EncodeMidiEvent(0,$B,id+$20,value and $7f));
end;

procedure TMidiState.SetPrg(const value: byte);
begin
  ReceiveEvent(EncodeMidiEvent(0,$C,value,0));
end;

procedure TMidiState.SetChnPressure(const value: byte);
begin
  ReceiveEvent(EncodeMidiEvent(0,$D,value,0));
end;

procedure TMidiState.SetPitch(const value: word);
begin
  ReceiveEvent(EncodeMidiEvent(0,$E,value shr 7,Value and $7f));
end;

function TMidiState.SustainPedal:byte;
begin
  result:=CC7[$40];
end;

{ TMidiDevice }

{$O-}
procedure TMidiDevice.SetExists(const Value: boolean);begin end;
procedure TMidiDevice.SetName(const Value: ansistring);begin end;
procedure TMidiDevice.SetState(const Value: ansistring);begin end;
{$O+}

constructor TMidiDevice.Create(const AOwner: THetObject);
begin
  inherited;
  State:='closed';
end;

destructor TMidiDevice.Destroy;
begin
  close;
  inherited;
end;

procedure inCallBack(hMidiIn:THandle;msg,instance,p1,p2:integer);stdcall;
begin
  if msg=MIM_DATA then begin
    midiLock;
    try
      TMidiDevice(instance).ProcessMidiIn(p1);
    finally
      midiUnLock;
    end;
  end;
end;

function TMidiDevice.Open: boolean;
var inCaps:TMidiInCapsA;
    outCaps:TMidiOutCapsA;
    i,devId:integer;
    found:boolean;
    devName:ansistring;
begin
  if FOpened then exit(true);
  found:=false;
  if FIsInput then begin
    //find device and open
    for devId:=0 to midiInGetNumDevs-1 do begin
      if(midiInGetDevCapsA(devId,@inCaps,sizeof(inCaps))=0)and(Cmp(FName,inCaps.szPname)=0)then begin
        found:=true;
        case midiInOpen(PHMIDIIN(@FHandle),devId,cardinal(@inCallBack),cardinal(self),CALLBACK_FUNCTION)of
          MMSYSERR_NOERROR:begin midiInStart(FHandle);FOpened:=true;State:='working';end;
          MMSYSERR_ALLOCATED:State:='error: allocated already';
        else State:='error';end;
        break;
      end;
    end;
  end else begin
    //find devId
    devName:=FName;
    if cmp(FName,'Default')=0 then begin
      devId:=integer(MIDI_MAPPER);found:=true;
    end else begin
      devId:=-1;
      for i:=0 to midiOutGetNumDevs-1 do
        if(midiOutGetDevCapsA(i,@outCaps,sizeof(outCaps))=0)and(Cmp(devName,outCaps.szPname)=0)then begin
          found:=true;devId:=i;break;end;
    end;
    //open
    if found then
      case midiOutOpen(PHMIDIOut(@FHandle),devId,0,0,CALLBACK_NULL)of
        MMSYSERR_NOERROR:begin FOpened:=true;State:='working';end;
        MMSYSERR_ALLOCATED:State:='error: allocated already';
      else State:='error';end;
  end;

  Exists:=found;
  if not Found then
    State:='unplugged';

  result:=FOpened;
end;

function TMidiDevice.OwnerConnection: TMidiConnection;
begin
  result:=TMidiConnection(FOwner.FOwner);
  Assert(result.ClassType=TMidiConnection,'TMidiDevice.OwnerConnection fail: result.ClassType=TMidiConnection');
end;

procedure TMidiDevice.Close;
begin
  if FOpened then begin
    FOpened:=false;
    State:='closed';
    if isInput then midiInClose(FHandle)
               else midiOutClose(Fhandle);
  end;
end;

procedure TMidiDevice.WriteEvents(const ev: TMidiEventArray);
var i:integer;
begin
  if IsInput then exit;
  if not Opened then Open;
  if not Opened then exit;

  for i:=0 to ev.Count-1 do
    midiOutShortMsg(FHandle,ev.FItems[i]);
end;

procedure TMidiDevice.ProcessMidiIn(const msg:integer);
var c:TMidiConnection;
    i:integer;
begin
  if msg=$FE then exit;
  for i:=0 to g_MidiConnections.Count-1 do begin
    c:=g_MidiConnections.FItems[i];
    if ListFind(c.FInputs,FName,',')>=0 then
      c.FReceivedEvents.Append(msg);
  end;
end;

{ TMidiConnection }

{$O-}
procedure TMidiConnection.SetEnabled(const Value: boolean);begin end;
procedure TMidiConnection.SetInputs(const Value: ansistring);begin end;
procedure TMidiConnection.SetOutputs(const Value: ansistring);begin end;
{$O+}

procedure TMidiConnection.Silence;
var i:integer;
begin
  midiLock;
  try
    if State.SustainPedal>0 then
      FReceivedEvents.Append(EncodeMidiEvent(0,$B,$40));
    for i:=0 to 127 do if State.Key[i]>0 then
      FReceivedEvents.Append(EncodeMidiEvent(0,$9,i,0));
  finally
    MidiUnLock;
  end;
end;

procedure TMidiConnection.SimulateInputEvent(ev: integer);
begin
  midiLock;
  try
    FReceivedEvents.Append(ev);
  finally
    MidiUnLock;
  end;
end;

function TMidiConnection.AllInputDevices: TMidiDevices;
begin
  result:=Midi.InputDevices;
end;

function TMidiConnection.AllOutputDevices: TMidiDevices;
begin
  result:=Midi.OutputDevices;
end;

constructor TMidiConnection.Create(const AOwner: THetObject);
begin
  inherited;
  Midi;//timer indul
  g_MidiConnections.Append(self);

  Enabled:=true;
end;

destructor TMidiConnection.Destroy;
var i:integer;
begin
  with g_MidiConnections do for i:=Count-1 downto 0 do if FItems[i]=self then Remove(i);
  inherited;
end;

function TMidiConnection.OutputDevices:TArray<TMidiDevice>;
var names:TAnsiStringArray;d:TMidiDevice;i,n:integer;
begin
  names:=ListSplit(Outputs,',');
  setlength(result,length(names));n:=0;
  with Midi do for i:=0 to high(names)do begin
    d:=OutputDevices.ByName[names[i]];
    if d<>nil then begin
      result[n]:=d;
      inc(n);
    end;
  end;
  setlength(result,n);
end;

function TMidiConnection.InputDevices:TArray<TMidiDevice>;
var names:TAnsiStringArray;d:TMidiDevice;i,n:integer;
begin
  names:=ListSplit(Inputs,',');
  setlength(result,length(names));n:=0;
  with Midi do for i:=0 to high(names)do begin
    d:=InputDevices.ByName[names[i]];
    if d<>nil then begin
      result[n]:=d;
      inc(n);
    end;
  end;
  setlength(result,n);
end;

function TMidiConnection.ReadEvents;
var i:integer;
    d:TMidiDevice;
begin
  result:=false;
  midiLock;
  try

    if Enabled then begin
      for d in InputDevices do begin
        d.Open;
        d._LastPoll:=now;
      end;
      State.Events.Clear;
      result:=FReceivedEvents.Count>0;
      for i:=0 to FReceivedEvents.Count-1 do
        State.ReceiveEvent(FReceivedEvents.FItems[i]);
    end;
    FReceivedEvents.Clear;

  finally
    midiUnLock;
  end;
end;

procedure TMidiConnection.WriteEvents;
var d:TMidiDevice;
begin
  midiLock;
  try

    if Enabled then
      for d in OutputDevices do begin
        d._LastPoll:=now;
        d.WriteEvents(State.Events);
      end;
    State.Events.Clear;

  finally
    midiUnLock;
  end;
end;

{ TMidi }

constructor TMidi.Create(const AOwner: THetObject);
begin
  inherited;

  FTimer:=TTimer.Create(nil);
  with FTimer do begin
    Interval:=500;
    OnTimer:=UpdateDevices;
    Enabled:=true;
  end;

  OutputDevices._dump;//ez minek? o.O

  UpdateDevices;
end;

destructor TMidi.Destroy;
begin
  FreeAndNil(FTimer);
  inherited;
end;

procedure TMidi.UpdateDevices(Sender:TObject=nil);

  procedure Doit(const AIsInput:boolean;const list:TMidiDevices;const cnt:integer;const getname:TFunc<integer,ansistring>);
  var i:integer;
      n:ansistring;
      d:TMidiDevice;
  begin
    for i:=0 to List.Count-1 do List.ByIndex[i]._Found:=false;
    for i:=0 to cnt-1 do begin
      n:=getname(i);
      d:=List.ByName[n];
      if d=nil then begin
        d:=TMidiDevice.Create(List);
        d.FisInput:=AIsInput;
        d.Name:=n;
      end;
      d._Found:=true;
    end;
    for i:=0 to List.Count-1 do with List.ByIndex[i] do begin
      Exists:=_Found;
      if FOpened and(not Exists or(Now-_LastPoll>1/24/60/60))then begin
        Close;
      end;
    end;
  end;

var numDevs:integer;
begin
  Doit(true,InputDevices,midiInGetNumDevs,
    function(id:integer):ansistring var Caps:TMidiInCapsA;
    begin midiInGetDevCapsA(id,@Caps,sizeof(Caps));result:=Caps.szPname end);

  numDevs:=midiOutGetNumDevs;if numDevs>0 then inc(numDevs);//+default midi mapper
  Doit(false,OutputDevices,numDevs,
    function(id:integer):ansistring var Caps:TMidiOutCapsA;
    begin
      if id=0 then exit('Default')
              else if midiOutGetDevCapsA(id-1,@Caps,sizeof(Caps))=0 then exit(Caps.szPname);
      result:='';
    end);
end;

initialization
finalization
  FreeAndNil(g_Midi);
end.
