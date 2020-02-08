unit DSPLayer;//sse//het.http             het.utils

interface

uses Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DSPack, DirectShow9, het.Utils, dsutil, activex, mmsystem,
  math, het.Gfx, ExtCtrls, DXSUtil;

const DefaultCaptureWidth:integer=800;
      DefaultCaptureHeight:integer=600;

type
  TTunerFlag=(tfLineIn,tfPause);
  TTunerFlags=set of TTunerFlag;

  _TMyBuffer=record
    width,height,bitcount:integer;
    p:pointer;
    SampleTimeSec:Double;
  end;

type
  TAMControlType=(ProcAmp,CamCtrl);
  TAMControls=class;
  TAMControl=class
  private
    FOwner:TAMControls;
    FName:ansistring;
    FHash:integer;

    FType:TAMControlType;
    FId:integer;//-1:none

    FSupported,FAutoSupported:boolean;FMin,FMax,FStep,FDefault,FRangeFlags:integer; //getRange kimenete
    FLastSetValue:Single;
    function _GetRange:boolean;
    function _Get(out AValue,AFlags:integer):boolean;
    function _Set(const AValue,AFlags:integer):boolean;

    function GetSupported:boolean;
    function GetAutoSupported:boolean;
    function GetDefaultValue:single;
    function GetValue:single;
    function GetAuto:boolean;
    procedure SetValue(const AValue:single);
    procedure SetAuto(const AValue:boolean);
    function GetDebug:ansistring;
  public
    constructor Create(const AOwner:TAMControls;const AName:ansistring;const AType:TAMControlType;const AId:integer);
    property Name:AnsiString read FName;
    property Supported:boolean read GetSupported;
    property Value:single read GetValue write SetValue;
    property DefaultValue:single read GetDefaultValue;
    property AutoSupported:boolean read GetAutoSupported;
    property Auto:boolean read GetAuto write SetAuto;
    property Debug:ansistring read GetDebug;
  end;

  TAMControls=class//IAMVideoProcAmp es IAMCameraControls osszevonasa, gyartospecifikus takolasokkal
  private
    FProcAmp:IAMVideoProcAmp;
    FCamCtrl:IAMCameraControl;
    FHardware:(Standard,Logitech,Conexant);
    FControls:array of TAMControl;
    procedure Clear;
    procedure SetDevice(const ADevice:IUnknown;const ADeviceName:AnsiString);

    function GetByName(const AName:AnsiString):TAMControl;
    function GetByHash(const AHash:integer):TAMControl;
    function GetByIndex(const AIndex:integer):TAMControl;
    function GetByNameOrIndex(const ANameOrIndex:variant):TAMControl;
    function GetCount:integer;
  public
    constructor Create;
    destructor Destroy;override;
    property ByName[const AName:ansistring]:TAMControl read GetByName;
    property ByHash[const AHash:integer]:TAMControl read GetByHash;
    property ByIndex[const AIndex:integer]:TAMControl read GetByIndex;
    property ByNameOrIntex[const ANameOrIndex:variant]:TAMControl read GetByNameOrIndex;default;
    property Count:integer read GetCount;
  end;

  TDSPlayer=class;
  TDSPlayer=class(TComponent)
  private
    FFileName:AnsiString;
    FGraphROTID:integer;
    FGraph:TFilterGraph;
    source,nullfilter,audfilter:IBaseFilter;
    FTuner,crossbar,audioLofasz:TFilter;
    FGrabber:TSampleGrabber;
    FOnBuffer:TNotifyEvent;

    capture:tfilter;
    opin:ipin;
    FThrdOwnerHandle:THandle;

    MTList:array of TMediaType;
    FCapWidth: integer;
    FCapHeight: integer;
    FCapBitCount:integer;
    FLoop: boolean;
    FDuration:double;//-1:recalc needed
//    FPosition:double;//last SampleTime
    FNeedRestart:boolean;

    FOnComplete:TNotifyEvent;

    TunerFlags:TTunerFlags;

    FAudioDeviceName:ansistring;

    FFormats:TStrings;
    FActFormat:string;

    FAMControls:TAMControls;

    FBitmapBuffer:RawByteString;

    function GetFileName: AnsiString;
    procedure SetFileName(const Value: AnsiString);
    procedure RecreateGraph;
    procedure DestroyGraph;
    procedure MyOnBuffer(sender: TObject; SampleTime: Double; pBuffer: Pointer; BufferLen: longint);
    function GetPosition: double;
    procedure SetPosition(const Value: double);
    function GetRate: double;
    procedure SetRate(const Value: double);
    procedure GetMTList(pin:IPin);
    procedure Gcomplete(sender: TObject; Result: HRESULT; Renderer: IBaseFilter);
    function GetDuration:double;
    function getPlaying: boolean;
    procedure SetPlaying(const Value: boolean);
    function GetTuner:IAmTVTuner;
    function GetTunerChannel:integer;
    procedure SetTunerChannel(const Value:integer);
    function GetTunerChannelCount: integer;
    function GetSetTunerFrequency(ASetFreq:integer=0):integer;
    function GetTunerFrequency:integer;
    procedure SetTunerFrequency(const AFreq:integer);
    function GetInputSelect: integer;
    procedure SetInputSelect(const Value: integer);
    function OwnerHandle: THandle;
  public
    Buffer:_TMyBuffer;
    constructor Create(o:TComponent);override;
    destructor Destroy;override;
    function GetVideoAttributes(out w,h,bc:integer):boolean;
    procedure Stop;
    procedure Play;
    procedure Pause;
    property Graph:TFilterGraph read FGraph;
    property Grabber:TSampleGrabber read FGrabber;
    function CopyBitmap(var Dst:TBitmap):boolean;
    function StretchDIBits(const DC:THandle;const RDst:TRect):boolean;overload;
    function StretchDIBits(const DC:THandle;const RDst,RSrc:TRect):boolean;overload;

    property Tuner:IAMTVTuner read GetTuner;
    property TunerChannel:integer read GetTunerChannel write SetTunerChannel;
    procedure TunerChannelDelta(const delta:integer);
    procedure TunerChannelNext;
    procedure TunerChannelPrev;
    property TunerChannelCount:integer read GetTunerChannelCount;
    property TunerFrequency:integer read getTunerFrequency write SetTunerFrequency;

    function Formats:TStrings;
    function GetActFormat:string;
    procedure SetActFormat(const AFormat:string);
    property ActFormat:string read GetActFormat write SetActFormat;

    procedure LoopUpdate;//Ez a fos inditja ujra, ha loop van

    procedure ShowFilterPros;
    procedure ShowPinProps;
  published
    property FileName:AnsiString read GetFileName write SetFileName;
    property Position:double read GetPosition write SetPosition;
    property Duration:double read GetDuration;
    property Rate:double read GetRate write SetRate;
    property Playing:boolean read getPlaying write SetPlaying;
    property Loop:boolean read FLoop write FLoop;
    property CaptureWidth:integer read FCapWidth write FCapWidth;
    property CaptureHeight:integer read FCapHeight write FCapHeight;
    property CaptureBitcount:integer read FCapBitCount write FCapBitCount;
    property OnBuffer:TNotifyEvent read FOnBuffer write FOnBuffer;
    property OnComplete:TNotifyEvent read FOnComplete write FOnComplete;
    property AudioDeviceName:ansistring read FAudioDeviceName write FAudioDeviceName;
    property InputSelect:integer read GetInputSelect write SetInputSelect;

    property AMControls:TAMControls read FAMControls;
  public
    FSeekAfterOpenTakolas:double;//ha>0, akkor egy open utan seekelni fog (0..1)
  public
    TLastFrame,TActFrame,TFreq:int64;
    const MaxFrameTimeGraphLength=100;
    var FrameTimeGraph:TArray<Single>;
  end;

  TDsPlayerProperty=(pFileName,pPosition,pRate,pPlaying,pLoop,pAudioDeviceName,pInputSelect,pTunerChannel);
  TDsPlayerProperties=set of TDsPlayerProperty;

  TDSPlayer2=class;

  TDSThread=class(TThread)
  private
    FPlayer:TDSPlayer;
    FPlayer2:TDSPlayer2;
    procedure ThrdOnBuffer(Sender:TObject);
    procedure ThrdOnComplete(Sender:TObject);
    procedure CallOnBuffer;
    procedure CallOnComplete;
  protected
    procedure Execute;override;
  public
    constructor Create(APlayer:TDSPlayer2);
  end;

  TDSPlayer2=class(TComponent)
  private
    FThread:TDSThread;
    FChangedProps:TDsPlayerProperties;
    FNewFileName:ansistring;
    FNewAudioDeviceName:ansistring;
    FThrdPosition,FNewPosition:double;
    FThrdRate,FNewRate:double;
    FThrdPlaying,FNewPlaying,
    FThrdLoop,FNewLoop:boolean;
    FThrdInputSelect,FNewInputSelect:integer;
    FThrdTunerChannel,FNewTunerChannel:integer;
    FThrdDuration:double;
    FThrdShowFilterProps:boolean;
    FThrdShowPinProps:boolean;
    FOnBuffer: TNotifyEvent;
    FOnComplete: TNotifyEvent;
    FBitmap:TBitmap;
    FActFrameEnabled:boolean;
    procedure SetFileName(const Value: AnsiString);
    procedure SetAudioDeviceName(const Value: AnsiString);
    procedure SetLoop(const Value: boolean);
    procedure SetPlaying(const Value: boolean);
    procedure SetPosition(const Value: double);
    procedure SetRate(const Value: double);
    procedure SetInputSelect(const Value: integer);
    procedure SetTunerChannel(const Value: integer);
    function GetAsyncPlayer: TDSPlayer;
  public
    constructor Create(AOwner:TComponent);override;
    destructor Destroy;override;

    property ActFrame:TBitmap read FBitmap;
    property ActFrameEnabled:boolean read FActFrameEnabled write FActFrameEnabled;

    procedure SeekAfterOpenTakolas(const s:double);//tákolas

    procedure ShowFilterProps;
    procedure ShowPinProps;
  published
    property FileName:AnsiString read FNewFileName write SetFileName;
    property Position:double read FThrdPosition write SetPosition;
    property Rate:double read FThrdRate write SetRate;
    property Playing:boolean read FThrdPlaying write SetPlaying;
    property Loop:boolean read FThrdLoop write SetLoop;
    property Duration:double read FThrdDuration;
    property InputSelect:integer read FThrdInputSelect write SetInputSelect;
    property TunerChannel:integer read FThrdTunerChannel write SetTunerChannel;

    property OnBuffer:TNotifyEvent read FOnBuffer write FOnBuffer;
    property OnComplete:TNotifyEvent read FOnComplete write FOnComplete;

    property AudioDeviceName:ansistring read FNewAudioDeviceName write SetAudioDeviceName;

    property AsyncPlayer:TDSPlayer read GetAsyncPlayer;
  end;

procedure dschk(i:integer);
function GetSysdevMoniker(const g:tguid;const n:variant):IMoniker;
function GetVideoCaptureMoniker(n:integer=0):IMoniker;

function GetSysdevName(const g:tguid;n:integer=0):ansistring;
function GetSysDevGuid(const ACategory:TGUID;const ADeviceName:variant):TGUID;
function GetSysDevBaseFilter(const ACategory:TGUID;const ADeviceName:variant):IBaseFilter;

function GetVideoCaptureName(n:integer=0):ansistring;

procedure Register;

function SetLineInMute(bMute: Boolean): Boolean;

implementation

uses ComObj, Typinfo, het.FileSys;

procedure Register;
begin
  RegisterComponents('HetGfx',[TDSPlayer]);
end;

function SetLineInMute(bMute: Boolean): Boolean;
var
  hMix: HMIXER;
  mxlc: MIXERLINECONTROLS;
  mxcd: TMIXERCONTROLDETAILS;
//  vol: TMIXERCONTROLDETAILS_UNSIGNED;
  mxc: MIXERCONTROL;
  mxl: TMixerLine;
  intRet: Integer;
  nMixerDevs: Integer;
  mcdMute: MIXERCONTROLDETAILS_BOOLEAN;
begin
  result:=false;
  // Check if Mixer is available
  // Überprüfen, ob ein Mixer vorhanden ist
  nMixerDevs := mixerGetNumDevs();
  if (nMixerDevs < 1) then
  begin
    Exit;
  end;

  // open the mixer
  // Mixer öffnen
  intRet := mixerOpen(@hMix, 0, 0, 0, 0);
  if intRet = MMSYSERR_NOERROR then
  begin
    mxl.dwComponentType := MIXERLINE_COMPONENTTYPE_SRC_LINE;
    mxl.cbStruct        := SizeOf(mxl);

    // mixerline info
    intRet := mixerGetLineInfo(hMix, @mxl, MIXER_GETLINEINFOF_COMPONENTTYPE);

    if intRet = MMSYSERR_NOERROR then
    begin
      ZeroMemory(@mxlc, SizeOf(mxlc));
      mxlc.cbStruct := SizeOf(mxlc);
      mxlc.dwLineID := mxl.dwLineID;
      mxlc.dwControlType := MIXERCONTROL_CONTROLTYPE_MUTE;
      mxlc.cControls := 1;
      mxlc.cbmxctrl := SizeOf(mxc);
      mxlc.pamxctrl := @mxc;

      // Get the mute control
      // Mute control ermitteln
      intRet := mixerGetLineControls(hMix, @mxlc, MIXER_GETLINECONTROLSF_ONEBYTYPE);

      if intRet = MMSYSERR_NOERROR then
      begin
        ZeroMemory(@mxcd, SizeOf(mxcd));
        mxcd.cbStruct := SizeOf(TMIXERCONTROLDETAILS);
        mxcd.dwControlID := mxc.dwControlID;
        mxcd.cChannels := 1;
        mxcd.cbDetails := SizeOf(MIXERCONTROLDETAILS_BOOLEAN);
        mxcd.paDetails := @mcdMute;

        mcdMute.fValue := Ord(bMute);

        // set, unset mute
        // Stumsschalten ein/aus
        intRet := mixerSetControlDetails(hMix, @mxcd,
          MIXER_SETCONTROLDETAILSF_VALUE);
          {
          mixerGetControlDetails(hMix, @mxcd,
                                 MIXER_GETCONTROLDETAILSF_VALUE);
          Result := Boolean(mcdMute.fValue);
          }
        Result := intRet = MMSYSERR_NOERROR;

        if intRet <> MMSYSERR_NOERROR then
          ShowMessage('SetControlDetails Error');
      end
      else
        ShowMessage('GetLineInfo Error');
    end;

    {intRet := }mixerClose(hMix);
  end;
end;

var lastdserror:array[0..1000]of AnsiChar;
procedure dschk(i:integer);
begin
  if i=s_ok then exit
  else begin
    AMGetErrorTextA(i,lastdserror,length(lastdserror));
//    showmessage(lastdserror);
  end;
end;

(*function GetPin(I:IUnknown;name:AnsiString):IPin;overload;
var ep:IEnumPins;
    pi:_pininfo;
    n:integer;
procedure error;begin ShowMessage('pin not found : '+name);end;
begin
  result:=nil;
  if Supports(I,IID_IBaseFilter)then begin
    with I as IBaseFilter do if s_ok=EnumPins(ep)then begin
      ep.Reset;
      repeat
        ep.Next(1,result,@n);
        if n=0 then begin error;result:=nil;exit end;
        result.QueryPinInfo(pi);
        if pi.achName=name then begin
          ep:=nil;
          exit;
        end;
      until false;
      ep:=nil;
      result:=nil;
    end;
  end else error;
end;

function GetPin(I:IUnknown;input:boolean;nth:integer):IPin;overload;
var ep:IEnumPins;
    pi:_pininfo;
    n:integer;
procedure error;
begin
  if input then ShowMessage('input pin not found : '+inttostr(nth))
           else ShowMessage('output pin not found : '+inttostr(nth));
end;
begin
  result:=nil;
  if Supports(I,IID_IBaseFilter)then begin
    with I as IBaseFilter do if s_ok=EnumPins(ep)then begin
      ep.Reset;
      repeat
        ep.Next(1,result,@n);
        if n=0 then begin error;result:=nil;exit end;
        result.QueryPinInfo(pi);
        if (pi.dir=PINDIR_INPUT)=input then begin
          if nth=0 then begin ep:=nil;exit end;
          dec(nth);
        end;
      until false;
      result:=nil;
      ep:=nil;
    end;
  end else error;
  result:=nil;
end;*)


function GetSysdevMoniker(const g:tguid;const n:variant):IMoniker;
var sysdev:tsysdevenum;
    i:integer;
begin
  result:=nil;
  SysDev:= TSysDevEnum.Create(g);
  try
    if VarIsOrdinal(n) then begin
      i:=n;
      if i>=sysdev.CountFilters then i:=sysdev.CountFilters-1;
      if(i>=0)then result:=sysdev.GetMoniker(i);
    end else begin
      for i:=0 to sysdev.CountFilters-1 do begin
        if IsWild2(n,sysdev.Filters[i].FriendlyName)then
          exit(sysdev.GetMoniker(i));
      end;
    end;
  finally
    Sysdev.Free;
  end;
end;

function GetSysdevName(const g:tguid;n:integer=0):ansistring;
var sysdev:tsysdevenum;
begin
  result:='';
  SysDev:= TSysDevEnum.Create(g);
  try
    if n>=sysdev.CountFilters then exit('');//n:=sysdev.CountFilters-1;
    if(n>=0)then result:=sysdev.Filters[n].FriendlyName;
  finally
    Sysdev.Free;
  end;
end;

function GetSysDevGuid(const ACategory:TGUID;const ADeviceName:variant):TGUID;
var sde:tsysdevenum;
    i,n:integer;
begin
  result:=GUID_NULL;
  sde:=TSysDevEnum.Create(ACategory);
  try
    if VarIsOrdinal(ADeviceName)then begin
      n:=ADeviceName;
      if n>=sde.CountFilters then n:=sde.CountFilters-1;
      if n>=0 then result:=sde.Filters[n].CLSID;
    end else begin
      for i:=0 to sde.CountFilters-1 do begin
        if IsWild2(ADeviceName,sde.Filters[i].FriendlyName)then
          exit(sde.Filters[i].CLSID);
      end;
    end;
  finally
    FreeAndNil(sde);
  end;
end;

function GetSysDevBaseFilter(const ACategory:TGUID;const ADeviceName:variant):IBaseFilter;
var sde:tsysdevenum;
    i,n:integer;
begin
  sde:=TSysDevEnum.Create(ACategory);
  try
    if VarIsOrdinal(ADeviceName)then begin
      n:=ADeviceName;
      if n>=sde.CountFilters then n:=sde.CountFilters-1;
      if n>=0 then result:=sde.GetBaseFilter(n);
    end else begin
      for i:=0 to sde.CountFilters-1 do begin
        if IsWild2(ADeviceName,sde.Filters[i].FriendlyName)then
          exit(sde.GetBaseFilter(i));
      end;
    end;
  finally
    FreeAndNil(sde);
  end;
end;

function GetVideoCaptureMoniker(n:integer=0):IMoniker;
begin result:=GetSysdevMoniker(CLSID_VideoInputDeviceCategory,n);end;

function GetVideoCaptureName(n:integer=0):ansistring;
begin result:=GetSysdevName(CLSID_VideoInputDeviceCategory,n);end;

function GetTvTunerMoniker(n:integer=0):IMoniker;
begin result:=GetSysdevMoniker(KSCATEGORY_TVTUNER,n);end;

function GetPin(const AFilter:IBaseFilter;const isOut:boolean;const AName:Variant):IPin;
var en:IEnumPins;
    pi:TPinInfo;
    idx:integer;
    Fetched:ULong;
begin
  result:=nil;
  if AFilter=nil then exit;
  if Failed(AFilter.EnumPins(en))then exit;

  en.Reset;idx:=0;
  while Succeeded(en.Next(1,result,@Fetched))and(Fetched=1) do begin
    Result.QueryPinInfo(pi);
    if(pi.dir=PINDIR_OUTPUT)=isOut then begin
      if VarIsOrdinal(AName)then begin
        if idx=AName then exit;
      end else begin
        if IsWild2(AName,pi.achName)then exit;
      end;
      inc(idx);
    end;
  end;
  result:=nil;
end;

function GetInPin(const AFilter:IBaseFilter;const AName:variant):IPin;overload;
begin result:=GetPin(AFilter,false,AName)end;
function GetOutPin(const AFilter:IBaseFilter;const AName:variant):IPin;overload;
begin result:=GetPin(AFilter,true,AName)end;

function GetInPin(const AFilter:TFilter;const AName:variant):IPin;overload;
begin result:=GetPin(AFilter as IBaseFilter,false,AName)end;
function GetOutPin(const AFilter:TFilter;const AName:variant):IPin;overload;
begin result:=GetPin(AFilter as IBaseFilter,true,AName)end;

{ TDSPlayer }

constructor TDSPlayer.Create;
begin
  inherited create(o);
  FCapWidth:=720;
  FCapHeight:=576;
//  FCapWidth:=800;
//  FCapHeight:=600;
  FCapBitCount:=24;
  FLoop:=True;

  FFormats:=TStringList.Create;
  FAMControls:=TAMControls.Create;
end;

procedure TDSPlayer.RecreateGraph;

  function isBitmapFile(const filename:ansistring):boolean;
  begin
    result:=ListFind(BitmapArrayLoadImageExtensions,ExtractFileExt(filename),';')>=0;
  end;

  procedure EnumFormats(opin:ipin);
  var sc:IAMStreamConfig;
      i,cnt,siz:integer;
      ssc:array of byte;
      mt:PAMMediaType;
      s:string;
  begin
    if not Supports(opin,IID_IAMStreamConfig,sc)then exit;
    if sc.GetNumberOfCapabilities(cnt,siz)<>S_OK then exit;
    setlength(ssc,siz);
    for i:=0 to cnt-1 do begin
      if sc.GetStreamCaps(i,mt,ssc[0])=S_OK then begin
        s:='';
        if isequalguid(mt^.formattype,FORMAT_VideoInfo)then begin
          with PVideoInfoHeader(mt.pbFormat).bmiHeader do begin
            if(biCompression=0)and(biBitCount in[32,24])then
              s:=format('%dx%d,%d',[biWidth,biHeight,biBitCount]);
          end;
        end else if isequalguid(mt^.formattype,FORMAT_VideoInfo2)then begin
          with PVideoInfoHeader2(mt.pbFormat).bmiHeader do begin
            if(biCompression=0)and(biBitCount in[32,24])then
              s:=format('%dx%d,%d',[biWidth,biHeight,biBitCount]);
          end;
        end;
        DeleteMediaType(mt);

        if(s<>'')and(FFormats.IndexOf(s)<0) then
          FFormats.Append(s);
      end;
    end;

    if sc.GetFormat(mt)=s_ok then begin
      s:='';
      if isequalguid(mt^.formattype,FORMAT_VideoInfo)then begin
        with PVideoInfoHeader(mt.pbFormat).bmiHeader do begin
          if(biCompression=0)and(biBitCount in[32,24])then
            s:=format('%dx%d,%d',[biWidth,biHeight,biBitCount]);
        end;
      end else if isequalguid(mt^.formattype,FORMAT_VideoInfo2)then begin
        with PVideoInfoHeader2(mt.pbFormat).bmiHeader do begin
          if(biCompression=0)and(biBitCount in[32,24])then
            s:=format('%dx%d,%d',[biWidth,biHeight,biBitCount]);
        end;
      end;
      DeleteMediaType(mt);

      FActFormat:=s;

      if(s<>'')and(FFormats.IndexOf(s)<0) then
        FFormats.Append(s);
    end;

    TStringList(FFormats).Sort;
  end;

(*  function GetNextFilter(outPin:IPin):IBaseFilter;
  var p:IPin;pininfo:_pininfo;
  begin
    result:=nil;
    if outPin.ConnectedTo(p)=S_OK then begin
      if p.QueryPinInfo(pininfo)=S_OK then begin
        result:=pininfo.pFilter;
      end;
      p:=nil;
    end;
  end;

  function FindFreeOutPin(Filter:IBaseFilter):IPin;
  var e:IEnumPins;
      f:integer;
      p,p2:IPin;
      pi:TPinInfo;
  begin
    result:=nil;
    if Filter.EnumPins(e)=S_OK then while(e.Next(1,p,@f)=S_OK)and(f=1)and(p<>nil)do begin
      if(p.ConnectedTo(p2)=S_OK)and(p2<>nil)then begin p:=nil;p2:=nil;continue end;
      if p.QueryPinInfo(pi)<>S_OK then break;
      if pi.dir=PINDIR_INPUT then begin p:=nil;Continue;end;
      result:=p;
      break;
    end;
    e:=nil;
  end;*)

  procedure SetTunerPAL_B;
  var ps:IKsPropertySet;
      ksTunerStandard:KSPROPERTY_TUNER_STANDARD_S;
//      returned:cardinal;
  begin
    if Tuner=nil then exit;
    ps:=Tuner as IKsPropertySet;if ps=nil then exit;

    fillchar(ksTunerStandard,sizeof(ksTunerStandard),0);
{    if S_OK<>ps.Get(PROPSETID_TUNER,AMPROPERTY_PIN(KSPROPERTY_TUNER_STANDARD),
      @ksTunerStandard,sizeof(ksTunerStandard),ksTunerStandard,sizeof(ksTunerStandard),returned)then exit;}


    {bruteforce cause driver suxx}
    ksTunerStandard.Standard:=AnalogVideo_PAL_B;
    if ps.Set_(PROPSETID_TUNER,ord(KSPROPERTY_TUNER_STANDARD),
      @ksTunerStandard,sizeof(ksTunerStandard),@ksTunerStandard,sizeof(ksTunerStandard))<>s_ok then {beep};
  end;


var wc:array[0..1000]of widechar;
    drivern,pinn:integer;
    actformat,mt:pAMMediaType;
    sc:IAMStreamConfig;
    fi:TFilterInfo;
//    pi:TPinInfo;
//    p:IPin;
//    splitter:IBaseFilter;
    i:integer;
//    ep:IEnumPins;
//    ul:ULONGLONG;
    capCount,capSize:integer;
    vsccaps:VIDEO_STREAM_CONFIG_CAPS;

//    mmt:TMediaType;
    linesize:integer;
begin


  destroygraph;
  TunerFlags:=[];
  if cmp(listitem(ExtractFileName(filename),0,','),'WDMcap')=0then begin
    drivern:=strtointdef(listitem(filename,1,','),0);
    pinn:=strtointdef(listitem(filename,2,','),0);

    fgraph:=TFilterGraph.Create(self);
    fgraph.Active:=false;
    capture:=tfilter.Create(self);
    capture.FilterGraph:=fgraph;
    capture.BaseFilter.Moniker:=GetVideoCaptureMoniker(drivern);
    fgraph.Active:=true;
    AddGraphToRot(fGraph as IFilterGraph,FGraphROTID);

    if IsWild2('AF9035 Analog Capture Filter',GetVideoCaptureName(drivern))then begin
      opin:=getOutPin(capture as IBaseFilter,pinn);
      GetMTList(opin);
      FGrabber:=TSampleGrabber.Create(self);
      FGrabber.FilterGraph:=fgraph;
      FGrabber.OnBuffer:=MyonBuffer;

      Cocreateinstance(CLSID_NullRenderer, nil, CLSCTX_INPROC ,IID_IBASEFilter, NullFilter);
      with fgraph as IGraphBuilder do AddFilter(NullFilter,'null');
      Cocreateinstance(CLSID_AudioRender , nil, CLSCTX_INPROC ,IID_IBASEFilter, AudFilter);
      with fgraph as IGraphBuilder do AddFilter(AudFilter,'aud');

      FTuner:=TFilter.Create(Graph);
      FTuner.BaseFilter.Moniker:=GetSysdevMoniker(KSCATEGORY_TVTUNER,'AF*');
      FTuner.FilterGraph:=Graph;

      audioLofasz:=TFilter.Create(Graph);
      audioLofasz.BaseFilter.Moniker:=GetSysdevMoniker(KSCATEGORY_TVAUDIO,'AF*');
      audioLofasz.FilterGraph:=Graph;

      crossbar:=TFilter.Create(Graph);
      crossbar.BaseFilter.Moniker:=GetSysdevMoniker(KSCATEGORY_CROSSBAR,'AF*');
      crossbar.FilterGraph:=Graph;

      TunerChannel:=0;//be kell inditani ezt a szart eloszor

      {bruteforce cause driver suxx big time}
      setTunerPal_B;
      with Capture as IAMAnalogVideoDecoder do put_TVFormat(AnalogVideo_PAL_B);

      with fgraph as igraphbuilder do begin
        dschk(Connect(GetOutPin(FTuner,'*Analog Video'),GetInPin(crossbar,'*Video Tuner In')));
        dschk(Connect(GetOutPin(FTuner,'*Analog Audio'),GetInPin(crossbar,'*Audio Tuner In')));

        dschk(Connect(GetOutPin(crossbar,'*Video Decoder Out'),GetInPin(capture,'*Analog Video In')));
        dschk(Connect(GetOutPin(crossbar,'*Audio Decoder Out'),GetInPin(capture,'*Volume')));

        dschk(Connect(GetOutPin(capture as IBasefilter,'Volume'),GetInPin(AudFilter,0)));
      end;

      //video standard utan szabad csak basszameg
      with opin as IAMStreamConfig do begin
        GetNumberOfCapabilities(capCount,capSize);
        if Succeeded(GetStreamCaps(1,mt,vsccaps))then begin
          if Succeeded(SetFormat(mt^))then {annyira fosszar ez, itt errort ad vissza, de megcsinalja :@};
          FreeMediaType(mt);
        end;
      end;

      with fgraph as igraphbuilder do begin
        dschk(Connect(GetOutPin(capture as IBasefilter,pinn),FGrabber.InPutPin));
        dschk(Connect(FGrabber.OutPutPin,GetInPin(NullFilter,pinn)));
      end;

      TunerFlags:=[];
    end else if IsWild2('Analog TV',GetVideoCaptureName(drivern))then begin //<-- remek neve van bhazzzzzz
      opin:=getOutPin(capture as IBaseFilter,pinn);
      GetMTList(opin);
      FGrabber:=TSampleGrabber.Create(self);
      FGrabber.FilterGraph:=fgraph;
      FGrabber.OnBuffer:=MyonBuffer;

      Cocreateinstance(CLSID_NullRenderer, nil, CLSCTX_INPROC ,IID_IBASEFilter, NullFilter);
      with fgraph as IGraphBuilder do AddFilter(NullFilter,'null');
      Cocreateinstance(CLSID_AudioRender , nil, CLSCTX_INPROC ,IID_IBASEFilter, AudFilter);
      with fgraph as IGraphBuilder do AddFilter(AudFilter,'aud');

      FTuner:=TFilter.Create(Graph);
      FTuner.BaseFilter.Moniker:=GetSysdevMoniker(KSCATEGORY_TVTUNER,'Conexant 2388x Tuner');
      FTuner.FilterGraph:=Graph;

      audioLofasz:=TFilter.Create(Graph);
      audioLofasz.BaseFilter.Moniker:=GetSysdevMoniker(KSCATEGORY_TVAUDIO,'Conexant 2388x TvAudio');
      audioLofasz.FilterGraph:=Graph;

      crossbar:=TFilter.Create(Graph);
      crossbar.BaseFilter.Moniker:=GetSysdevMoniker(KSCATEGORY_CROSSBAR,'Conexant 2388x Crossbar');
      crossbar.FilterGraph:=Graph;

      TunerChannel:=0;//be kell inditani ezt a szart eloszor

      {bruteforce cause driver suxx big time}
      setTunerPal_B;
      with Capture as IAMAnalogVideoDecoder do put_TVFormat(AnalogVideo_PAL_B);

      with fgraph as igraphbuilder do begin
        dschk(Connect(GetOutPin(FTuner,'*Analog Video'),GetInPin(crossbar,'*Video Tuner In')));
        dschk(Connect(GetOutPin(FTuner,'*Analog Audio'),GetInPin(crossbar,'*Audio Tuner In')));

        dschk(Connect(GetOutPin(crossbar,'*Video Decoder Out'),GetInPin(capture,'*Video*')));
        dschk(Connect(GetOutPin(crossbar,'*Audio Decoder Out'),GetInPin(capture,'*Audio*')));

        dschk(Connect(GetOutPin(capture as IBasefilter,'Audio Out'),GetInPin(AudFilter,0)));
      end;

      //video standard utan szabad csak basszameg
      with opin as IAMStreamConfig do begin
        GetNumberOfCapabilities(capCount,capSize);
        if Succeeded(GetStreamCaps(1,mt,vsccaps))then begin
          if Succeeded(SetFormat(mt^))then {annyira fosszar ez, itt errort ad vissza, de megcsinalja :@};
          FreeMediaType(mt);
        end;
      end;

      with fgraph as igraphbuilder do begin
        dschk(Connect(GetOutPin(capture as IBasefilter,pinn),FGrabber.InPutPin));
        dschk(Connect(FGrabber.OutPutPin,GetInPin(NullFilter,pinn)));
      end;

      EnumFormats(opin);

      TunerFlags:=[];
      InputSelect:=0;//routing szar az elejen
    end else if IsWild2('Conexant''s BtPCI Capture',GetVideoCaptureName(drivern))then begin //Conexant's
      with capture as IBaseFilter do begin
        QueryFilterInfo(fi);
      end;

      with Capture as IAMAnalogVideoDecoder do put_TVFormat(AnalogVideo_PAL_B);

      opin:=getOutPin(capture as IBaseFilter,pinn);
      GetMTList(opin);
      FGrabber:=TSampleGrabber.Create(self);
      FGrabber.FilterGraph:=fgraph;
      FGrabber.OnBuffer:=MyonBuffer;
      Cocreateinstance(CLSID_NullRenderer, nil, CLSCTX_INPROC ,IID_IBASEFilter, NullFilter);
      with fgraph as IGraphBuilder do AddFilter(NullFilter,'null');

      FTuner:=TFilter.Create(Graph);
      FTuner.BaseFilter.Moniker:=GetSysdevMoniker(KSCATEGORY_TVTUNER,'Conex*');
      FTuner.FilterGraph:=Graph;

      with fgraph as igraphbuilder do begin
        dschk(Connect(GetOutPin(capture as IBasefilter,pinn),FGrabber.InPutPin));
        dschk(Connect(FGrabber.OutPutPin,GetInPin(NullFilter,pinn)));
      end;

      if Supports(opin,IID_IAMStreamConfig,sc)then begin
        sc.GetFormat(actformat);
        if isequalguid(actformat^.formattype,FORMAT_VideoInfo)then begin
          with PVideoInfoHeader(actformat.pbFormat).bmiHeader do begin
            biWidth:=fcapWidth;
            biHeight:=fcapHeight;
            biBitCount:=fcapBitCount;
          end;
        end else if isequalguid(actformat^.formattype,FORMAT_VideoInfo2)then begin
          with PVideoInfoHeader2(actformat.pbFormat).bmiHeader do begin
            biWidth:=fcapWidth;
            biHeight:=fcapHeight;
            biBitCount:=fcapBitCount;
          end;
        end;
        sc.SetFormat(actformat^);
        FreeMediaType(actformat);
        sc:=nil;
      end;

      EnumFormats(opin);

      TunerFlags:=[tfLineIn,tfPause];
    end else begin //other crap
//      showmessage('other crap');
      with capture as IBaseFilter do begin
        QueryFilterInfo(fi);
      end;
  //    with Crossbar as IAMCrossbar do Route(0,0{0=tuner,1=SVideo});
  //    with Capture as IAMAnalogVideoDecoder do put_TVFormat(AnalogVideo_PAL_B);
      opin:=getOutPin(capture as IBaseFilter,pinn);
      GetMTList(opin);
      FGrabber:=TSampleGrabber.Create(self);
      FGrabber.FilterGraph:=fgraph;
      FGrabber.OnBuffer:=MyonBuffer;

      Cocreateinstance(CLSID_NullRenderer, nil, CLSCTX_INPROC ,IID_IBASEFilter, NullFilter);
      with fgraph as IGraphBuilder do AddFilter(NullFilter,'null');
      AddGraphToRot(fGraph as IFilterGraph,FGraphROTID);
{      with fgraph as igraphbuilder do begin
        dschk(Connect(GetOutPin(capture as IBasefilter,pinn),FGrabber.InPutPin));
        dschk(Connect(FGrabber.OutPutPin,GetInPin(NullFilter,pinn)));
      end;}

      if Supports(opin,IID_IAMStreamConfig,sc)then begin
        sc.GetFormat(actformat);
        if isequalguid(actformat^.formattype,FORMAT_VideoInfo)then begin
          with PVideoInfoHeader(actformat.pbFormat).bmiHeader do begin
            biWidth:=fcapWidth;
            biHeight:=fcapHeight;
            biBitCount:=fcapBitCount;
          end;
        end else if isequalguid(actformat^.formattype,FORMAT_VideoInfo2)then begin
          with PVideoInfoHeader2(actformat.pbFormat).bmiHeader do begin
            biWidth:=fcapWidth;
            biHeight:=fcapHeight;
            biBitCount:=fcapBitCount;
          end;
        end;
        sc.SetFormat(actformat^);
        FreeMediaType(actformat);
        sc:=nil;
      end;

      with fgraph as igraphbuilder do begin
        dschk(Connect(GetOutPin(capture as IBasefilter,pinn),FGrabber.InPutPin));
        dschk(Connect(FGrabber.OutPutPin,GetInPin(NullFilter,pinn)));
      end;

      EnumFormats(opin);

    end;
    fgraph.Pause;

    FAMControls.SetDevice(capture,GetVideoCaptureName(drivern));
  end else if(FileName<>'')and fileexists(filename)and isBitmapFile(filename)then begin
    fgraph:=TFilterGraph.Create(self);
    FGraph.Mode:=gmCapture;
    fgraph.OnGraphComplete:=Gcomplete;
    fgraph.Active:=true;
    AddGraphToRot(fGraph as IFilterGraph,FGraphROTID);
    fgraph.Pause;

    with TBitmap.CreateFromFile(FileName)do try
      Buffer.width:=Width;
      Buffer.height:=Height;
      Buffer.bitcount:=Components*8;
      linesize:=Width*Components;
      SetLength(FBitmapBuffer,Height*linesize);
      for i:=0 to height-1 do
        move(ScanLine[height-i-1]^,PSucc(pointer(FBitmapBuffer),i*linesize)^,linesize);
      Buffer.p:=pointer(FBitmapBuffer);
    finally
      free;
    end;
    if assigned(FOnBuffer)then
      OnBuffer(self);
  end else if(FileName<>'')and TFile(FileName).Exists then begin
    fgraph:=TFilterGraph.Create(self);
    FGraph.Mode:=gmCapture;
    fgraph.OnGraphComplete:=Gcomplete;
    fgraph.Active:=true;
    FGrabber:=TSampleGrabber.Create(self);
    FGrabber.FilterGraph:=fgraph;
    FGrabber.OnBuffer:=MyonBuffer;
    FGrabber.SetBMPCompatible(nil,CaptureBitcount);

    //ezt a nagykalap szart!, de mukodik...
    AddGraphToRot(fGraph as IFilterGraph,FGraphROTID);
    with fgraph as IFilterGraph2 do begin
      StringToWideChar(TFile(FileName).FullName,wc,length(wc));
      AddSourceFilter(@wc,'',source);
      Cocreateinstance(CLSID_NullRenderer, nil, CLSCTX_INPROC ,IID_IBASEFilter, NullFilter);AddFilter(NullFilter,'null');
      if FAudioDeviceName='' then begin
        Cocreateinstance(CLSID_AudioRender , nil, CLSCTX_INPROC ,IID_IBASEFilter, AudFilter);
        AddFilter(AudFilter,'aud');
      end else begin
//        CoCreateInstance(GetSysDevGuid(CLSID_AudioRendererCategory,FAudioDeviceName), nil, CLSCTX_INPROC ,IID_IBASEFilter, AudFilter);
        audfilter:=GetSysDevBaseFilter(CLSID_AudioRendererCategory,FAudioDeviceName);
        AddFilter(AudFilter,pWideChar(WideString(FAudioDeviceName)));
      end;
    end;
    with fgraph as ICaptureGraphBuilder2 do begin
      if((cmp(ExtractFileExt(FileName),'.mkv')=0)or(cmp(ExtractFileExt(FileName),'.mp4')=0))and(GetOutPin(source,1)<>nil)then begin//matroska, videovan kezdunk
        RenderStream(nil,nil,source as IBaseFilter,grabber as IBaseFilter,nullfilter);
        RenderStream(nil,nil,source as IBaseFilter,nil,audfilter);
      end else begin //egyebkent viszont hanggal
        RenderStream(nil,nil,source as IBaseFilter,nil,audfilter);
        RenderStream(nil,nil,source as IBaseFilter,grabber as IBaseFilter,nullfilter);
      end;
    end;
    with fgraph as IFilterGraph2 do begin
      Connect(FGrabber.OutPutPin,GetInPin(NullFilter,0));
    end;

    fgraph.Pause;

  end;

  FDuration:=-1;//mark for recalc

  if FSeekAfterOpenTakolas>0 then begin
    Position:=Duration*FSeekAfterOpenTakolas;
    FSeekAfterOpenTakolas:=0;
  end;
end;

procedure TDSPlayer.GetMTList(pin: IPin);
var i,cnt,siz:integer;
    scc:array of byte;
    pmt:PAMMediaType;
    SC:IAMStreamConfig;
begin
  for i:=0 to high(mtlist)do mtlist[i].Free;setlength(mtlist,0);
  if Supports(pin,IID_IAMStreamConfig,SC)then with sc do begin
    GetNumberOfCapabilities(cnt,siz);
    SetLength(mtlist,cnt);SetLength(scc,siz);
    for i:=0 to cnt-1 do begin
      GetStreamCaps(i,pmt,scc[0]);
      mtlist[i]:=TMediaType.Create(pmt);
(*        if sameguid(pmt^.subtype,MEDIASUBTYPE_RGB24)and(sameguid(pmt.formattype,FORMAT_VideoInfo)or sameguid(pmt.formattype,FORMAT_VideoInfo2))then begin
{          setlength(mt,length(mt)+1);
        mt[high(mt)]:=pmt;}
        if sameguid(pmt.formattype,FORMAT_VideoInfo2)then
          if(PVideoInfoHeader2(pmt.pbFormat).bmiHeader.biHeight=480)and(PVideoInfoHeader2(pmt.pbFormat).bmiHeader.biWidth=752)then begin
            SetFormat(pmt^);break;
          end;
      end;*)
      DeleteMediaType(pmt);
    end;
    SC:=nil;
  end;
end;

destructor TDSPlayer.Destroy;
begin
  DestroyGraph;
  FreeAndNil(FFormats);
  FreeAndNil(FAMControls);
  inherited;
end;

procedure TDSPlayer.DestroyGraph;
var i:integer;
begin
  if fgraph<>nil then begin
    RemoveGraphFromRot(FGraphROTID);
    fgraph.Stop;
    if tfLineIn in TunerFlags then
      SetLineInMute(true);
    FreeAndNil(FGrabber);
    source:=nil;{!!}
    nullfilter:=nil;{!!}
    audfilter:=nil;
    opin:=nil;
    crossbar:=nil;
    audioLofasz:=nil;
    for i:=0 to high(mtlist)do mtlist[i].Free;setlength(mtlist,0);
    FreeAndNil(capture);
    FreeAndNil(fgraph);

    FFormats.Clear;
    FActFormat:='';

    FAMControls.SetDevice(nil,'');

    FBitmapBuffer:='';

    FDuration:=0;
//    FPosition:=0;
  end;
end;

function TDSPlayer.GetFileName: AnsiString;
begin result:=FFileName;end;

function TDSPlayer.GetInputSelect: integer;
var i,i2{antiwarning}:integer;
begin
  if Graph=nil then exit(0);

  if assigned(CrossBar)then begin
    with Crossbar as IAMCrossbar do
      for i:=0 to 3 do begin
        i2:=i;
        if get_IsRoutedTo(0,i2)=S_OK then exit(i2)
      end;
  end;
  result:=0;
end;

procedure TDSPlayer.SetInputSelect(const Value: integer);
var oldPlaying:boolean;
begin
  if Graph=nil then exit;

  if assigned(CrossBar)then with Crossbar as IAMCrossbar do begin
    oldPlaying:=Playing;
    fgraph.Pause;//nem stop baz+
    try
      Route(0,Value);

      if value<>0 then
        Route(1,4)
      else
        Route(1,3);
    finally
      if oldPlaying then Graph.Play
                    else Graph.Pause;
    end;
  end;
end;

procedure TDSPlayer.SetFileName(const Value: AnsiString);
var oldPlaying:boolean;
begin
  if cmp(FFileName,Value)=0 then begin
    exit;
  end else begin
    FFileName:=value;
    oldPlaying:=Playing;
    RecreateGraph;
    Playing:=oldPlaying;
  end;
end;

procedure TDSPlayer.myonBuffer(sender: TObject; SampleTime: Double; pBuffer: Pointer; BufferLen: Integer);
//var w,h,bc:integer;
var s:Single;
begin
  if csDestroying in ComponentState then Exit;
  try
    //timing Statistics
    if TFreq=0 then QueryPerformanceFrequency(TFreq);
    TLastFrame:=TActFrame;
    QueryPerformanceCounter(TActFrame);
    if TLastFrame<>0 then begin
      s:=(TActFrame-TLastFrame)/TFreq;
      if Length(FrameTimeGraph)<MaxFrameTimeGraphLength then
        SetLength(FrameTimeGraph,length(FrameTimeGraph)+1)
      else
        move(FrameTimeGraph[1],FrameTimeGraph[0],SizeOf(FrameTimeGraph[0])*(Length(FrameTimeGraph)-1));

      FrameTimeGraph[Length(FrameTimeGraph)-1]:=s;
    end;

    with Buffer do begin
      GetVideoAttributes(width,height,bitcount);
      SampleTimeSec:=SampleTime;
      p:=pBuffer;
    end;

//    FPosition:=SampleTime;

    if assigned(FOnBuffer)then
      OnBuffer(self);

    if Loop then begin
      if(Duration>0)and(SampleTime>=Duration-1/15)then begin
        FNeedRestart:=true;
      end;
    end;
  except
  end;
end;

function TDSPlayer.GetDuration: double;
var i:int64;
    s:IMediaSeeking;
begin
  if FDuration<0 then begin
    FDuration:=0;
    if(fgraph<>nil)and Supports(FGraph,IID_IMediaSeeking,s)then try
      s.SetTimeFormat(TIME_FORMAT_MEDIA_TIME);
      i:=0;s.GetDuration(i);
      FDuration:=i/10000000;
    finally s:=nil end;
  end;
  result:=FDuration;
end;

function TDSPlayer.GetPosition: double;
begin
//  result:=FPosition;
  result:=0;if fgraph=nil then exit;
  with fgraph as IMediaPosition do
    if get_CurrentPosition(Result)<>s_ok then result:=0;
end;

procedure TDSPlayer.SetPosition(const Value: double);
var oldPlaying:Boolean;
    s:IMediaPosition;
begin
  if fgraph=nil then exit;
  if capture<>nil then{ fgraph.Play ne csinaljon semmit ilyenkor}
  else begin
    oldPlaying:=Playing;
    fgraph.Pause;//nem stop baz+

    if Supports(FGraph,IID_IMediaPosition,s)then try
      s.put_CurrentPosition(Value);
    finally
      s:=nil;
    end;

    if oldPlaying then FGraph.Play
                  else fgraph.Pause;
  end;
end;

function TDSPlayer.GetRate:double;
begin
  result:=1;if fgraph=nil then exit;
  with fgraph as IMediaSeeking do
    GetRate(result);
end;

procedure TDSPlayer.SetRate(const Value:double);
begin
  if fgraph=nil then exit;
  if Playing then begin
    Stop;{Pause;}  //mekkora xar ez
    with fgraph as IMediaSeeking do
      SetRate(Value);
    Play;
  end else
    with fgraph as IMediaSeeking do
      SetRate(Value);
end;

function TDSPlayer.getVideoAttributes(out w, h, bc: integer): boolean;
var hr:hresult;MediaType: TAMMediaType;
begin
  result:=false;w:=0;h:=0;bc:=0;
  hr := FGrabber.SampleGrabber.GetConnectedMediaType(MediaType);
  try
  if hr<>s_ok then exit;
  w:=0;h:=0;bc:=0;
  if IsEqualGUID(MediaType.formattype, FORMAT_VideoInfo) then
  with PVideoInfoHeader(MediaType.pbFormat)^.bmiHeader do begin
    w:=biWidth;h:=biHeight;bc:=biBitCount;
  end else if IsEqualGUID(MediaType.formattype, FORMAT_VideoInfo2) then
  with PVideoInfoHeader2(MediaType.pbFormat)^.bmiHeader do begin
    w:=biWidth;h:=biHeight;bc:=biBitCount;end;
  if(w<=0)or(h<=0)then exit;
  result:=true;
  finally
    FreeMediaType(@MediaType);
  end;
end;

procedure TDSPlayer.LoopUpdate;
begin
  if CheckAndClear(FNeedRestart) then begin
    Position:=0;
    Play;
  end;
end;

procedure TDSPlayer.Stop;
begin
  if fgraph<>nil then fgraph.Stop;
  if tfLineIn in TunerFlags then SetLineInMute(true);
end;

procedure TDSPlayer.Play;
begin
  if fgraph<>nil then fgraph.Play;
  if tfLineIn in TunerFlags then SetLineInMute(false);
end;

procedure TDSPlayer.Gcomplete(sender: TObject; Result: HRESULT; Renderer: IBaseFilter);
begin
  fgraph.Stop;
  if loop then begin
    with fgraph as IMediaPosition do
      put_CurrentPosition(0);
    fgraph.Play;
  end else
    if Assigned(OnComplete)then
      OnComplete(self);
end;

function TDSPlayer.getPlaying: boolean;
begin
  result:=(fgraph<>nil)and(fgraph.state=gsPlaying);
end;

procedure TDSPlayer.SetPlaying(const Value: boolean);
begin
  if getPlaying<>value then begin
    if Value then Play
             else Pause;
  end;
end;

procedure TDSPlayer.Pause;
begin
  if graph<>nil then graph.Pause;
  if tfLineIn in TunerFlags then
    SetLineInMute(true);
end;

function TDSPlayer.CopyBitmap(var Dst:TBitmap):boolean;
begin
  result:=false;
  try
    if Dst=nil then
      Dst:=TBitmap.Create;

    with Buffer do begin
      if p=nil then exit;
      case bitcount of
        8:Dst.PixelFormat:=pf8bit;
        16:Dst.PixelFormat:=pf16bit;
        24:Dst.PixelFormat:=pf24bit;
        32:Dst.PixelFormat:=pf32bit;
      else exit end;
      Dst.Width:=width;
      Dst.Height:=height;

      if(width>0)and(height>0)then
        move(p^,Dst.ScanLine[Dst.Height-1]^,width*height*bitcount shr 3);

    end;
    result:=true;
  except
  end;
end;

function TDSPlayer.StretchDIBits(const DC:THandle;const RDst,RSrc:TRect):boolean;
var bi:TBitmapInfoHeader;
begin
  result:=false;
  try
    with Buffer do begin
      if(p=nil)or(width=0)or(height=0)then exit;

      fillchar(bi,sizeof(bi),0);
      bi.biSize:=SizeOf(bi);
      bi.biWidth:=width;
      bi.biHeight:=height;
      bi.biPlanes:=1;
      bi.biBitCount:=bitcount;
      bi.biCompression:=BI_RGB;

      SetStretchBltMode(DC,COLORONCOLOR);
      Windows.StretchDIBits(DC,RDst.Left,RDst.Top,RDst.Right-RDst.Left,RDst.Bottom-RDst.Top,
                               RSrc.Left,RSrc.Top,RSrc.Right-RSrc.Left,RSrc.Bottom-RSrc.Top,
                               p,PBitmapInfo(@bi)^,DIB_RGB_COLORS,SRCCOPY);
    end;
    result:=true;
  except
  end;
end;

function TDSPlayer.StretchDIBits(const DC:THandle;const RDst:TRect):boolean;
begin
  with Buffer do result:=StretchDIBits(DC,RDst,rect(0,0,Width,Height));
end;

function TDSPlayer.GetTuner:IAMTVTuner;
begin
  if FTuner<>nil then result:=FTuner as IAMTVTuner;
(*  result:=FTuner;
//  try
    if(FTuner=nil)and(Graph<>nil)and (cmp(copy(FileName,1,6),'wdmcap')=0)and(GetTvTunerMoniker(0)<>nil)then begin
      Pause;
      FTuner:=tfilter.Create(self);
      FTuner.BaseFilter.Moniker:=GetTvTunerMoniker(0);
      FTuner.FilterGraph:=fgraph;
      Play;
      SetLineInMute(false);
    end;
    if FTuner<>nil then
      result:=FTuner as IAMTVTuner;
//  except end;*)
end;

function TDSPlayer.GetTunerChannel:integer;
var tun:IAMTVTuner;
    vsub,asub,ma,mi:integer;
begin
  result:=-1;
  if graph=nil then exit;
  tun:=Tuner;
  if tun<>nil then begin
    tun.ChannelMinMax(mi,ma);
    tun.get_Channel(result,vsub,asub);
    result:=result-mi;
  end;
end;

procedure TDSPlayer.SetTunerChannel(const value:integer);
var tun:IAMTVTuner;
    mi,ma,ch:integer;
    oldpl:boolean;
begin
  tun:=Tuner;
  if graph=nil then exit;
  if(tun<>nil)and(GetTunerChannel<>value)then begin
    tun.ChannelMinMax(mi,ma);
    ch:=value+mi;
    if ch<=ma then begin
      if tfLineIn in TunerFlags then SetLineInMute(true);

      oldpl:=Playing;
      if(tfPause in TunerFlags)and oldPl then Pause;
      try
        tun.put_Channel(ch,-1,-1);
      finally
        if(tfPause in TunerFlags)and oldPl then Play;
        if tfLineIn in TunerFlags then SetLineInMute(false);
      end;
    end;
  end;
end;

function TDSPlayer.GetTunerChannelCount:integer;
var tun:IAMTVTuner;
    ma,mi:integer;
begin
  result:=0;
  tun:=Tuner;
  if tun<>nil then begin
    tun.ChannelMinMax(mi,ma);
    result:=ma-mi+1;
  end;
end;

procedure TDSPlayer.TunerChannelDelta(const delta: integer);
var ch,cnt:integer;
begin
  if delta=0 then exit;
  cnt:=TunerChannelCount;
  if cnt<=0 then exit;
  ch:=TunerChannel+delta;
  ch:=ch mod cnt;
  if ch<0 then ch:=ch+cnt;
  TunerChannel:=ch;
end;

procedure TDSPlayer.TunerChannelNext;
begin
  TunerChannelDelta(1);
end;

procedure TDSPlayer.TunerChannelPrev;
begin
  TunerChannelDelta(-1);
end;

function TDSPlayer.GetSetTunerFrequency(ASetFreq:integer=0):integer;
var ps:IKsPropertySet;
    ksFrequency:KSPROPERTY_TUNER_FREQUENCY_S;
    returned:cardinal;
begin
  result:=-1;
  if Tuner=nil then exit;
  ps:=Tuner as IKsPropertySet;if ps=nil then exit;

  fillchar(ksFrequency,sizeof(ksFrequency),0);
  ksFrequency.TuningFlags:=2;

  if ASetFreq=0 then begin
    if S_OK<>ps.Get(PROPSETID_TUNER,ord(KSPROPERTY_TUNER_FREQUENCY),
      @ksFrequency.Frequency,  sizeof(ksFrequency)-SizeOf(ksproperty), ksFrequency, sizeof(ksFrequency),returned)then exit;
  end else begin
    ksFrequency.Frequency:=cardinal(ASetFreq);
    ksFrequency.TuningFlags:=1;//exact
    if S_OK<>ps.Set_(PROPSETID_TUNER,ord(KSPROPERTY_TUNER_FREQUENCY),
      @ksFrequency.Frequency,  sizeof(ksFrequency)-SizeOf(ksproperty), @ksFrequency, sizeof(ksFrequency))then exit;
  end;
  Result:=ksFrequency.Frequency;
end;

function TDSPlayer.GetTunerFrequency:integer;
begin
  result:=GetSetTunerFrequency;
end;

procedure TDSPlayer.SetTunerFrequency(const AFreq:integer);
begin
  GetSetTunerFrequency(AFreq);
end;

function TDSPlayer.OwnerHandle:THandle;
begin
  if FThrdOwnerHandle<>0 then exit(FThrdOwnerHandle);
  if(Owner<>nil)and(Owner is TWinControl)then result:=TWinControl(Owner).Handle
                                         else result:=0;
end;

procedure TDSPlayer.ShowFilterPros;
begin
  if capture<>nil then
    ShowFilterPropertyPage(OwnerHandle,capture as IBaseFilter);
end;

procedure TDSPlayer.ShowPinProps;
begin
  if opin<>nil then
    ShowPinPropertyPage(OwnerHandle,opin);
end;

function TDSPlayer.Formats:TStrings;
begin
  result:=FFormats;
end;

function TDSPlayer.GetActFormat:string;
begin
  result:=FActFormat;
end;

procedure TDSPlayer.SetActFormat(const AFormat:string);
var w,h,bpp:integer;
    s,old:ansistring;
    oldst:boolean;
begin
  s:=AFormat;
  w:=strtointdef(listitem(s,0,'x'),0);if w<=0 then exit;
  s:=ListItem(s,1,'x');
  h:=strtointdef(listitem(s,0,','),0);if h<=0 then exit;
  bpp:=strtointdef(listitem(s,1,','),0);if not(bpp in[24,32])then exit;

  CaptureWidth:=w;
  CaptureHeight:=h;
  CaptureBitcount:=bpp;

  //recreate all
  old:=FileName;oldst:=Playing;
  FileName:='';
  FileName:=old;Playing:=oldst;
end;

////////////////////////////////////////////////////////////////////////////////
// TDSPlayer2                                                                 //
////////////////////////////////////////////////////////////////////////////////

{ TDSThread }

constructor TDSThread.Create(APlayer: TDSPlayer2);
begin
  FPlayer2:=APlayer;
  inherited Create(false);
end;

procedure TDSThread.ThrdOnBuffer(Sender: TObject);
begin
  if FPlayer2.ActFrameEnabled then begin
    if FPlayer.CopyBitmap(FPlayer2.FBitmap)then
      Synchronize(CallOnBuffer);
  end else
    Synchronize(CallOnBuffer);
end;

procedure TDSThread.ThrdOnComplete(Sender: TObject);
begin
  Synchronize(CallOnComplete);
end;

procedure TDSThread.CallOnBuffer;
begin
  if not Terminated and Assigned(FPlayer2.OnBuffer)then
    FPlayer2.OnBuffer(FPlayer2);
end;

procedure TDSThread.CallOnComplete;
begin
  if Assigned(FPlayer2.OnComplete)then
    FPlayer2.OnComplete(FPlayer2);
end;

procedure TDSThread.Execute;
begin
  CoInitializeEx(nil,0);
  FPlayer:=TDSPlayer.Create(nil);
  FPlayer.OnBuffer:=ThrdOnBuffer;
  FPlayer.OnComplete:=ThrdOnComplete;

  while not terminated do with FPlayer2 do try
    if pAudioDeviceName in FChangedProps then
      FPlayer.AudioDeviceName:=FNewAudioDeviceName;
    if pFileName in FChangedProps then
      FPlayer.FileName:=FNewFileName;
    if pPosition in FChangedProps then
      FPlayer.Position:=FNewPosition;
    if pRate in FChangedProps then
      FPlayer.Rate:=FNewRate;
    if pPlaying in FChangedProps then
      FPlayer.Playing:=FNewPlaying;
    if pLoop in FChangedProps then
      FPlayer.Loop:=FNewLoop;
    if pInputSelect in FChangedProps then
      FPlayer.InputSelect:=FNewInputSelect;
    if pTunerChannel in FChangedProps then begin
      FChangedProps:=FChangedProps-[pTunerChannel];
      FPlayer.TunerChannel:=FNewTunerChannel;
    end;
    if CheckAndClear(FThrdShowFilterProps)then
      FPlayer.ShowFilterPros;
    if CheckAndClear(FThrdShowPinProps)then
      FPlayer.ShowPinProps;

    FChangedProps:=[];
    //property synch <-
    FThrdPosition:=FPlayer.Position;
    FThrdRate:=FPlayer.Rate;
    FThrdPlaying:=FPlayer.Playing;
    FThrdDuration:=FPlayer.Duration;
    FThrdLoop:=FPlayer.Loop;
    FThrdInputSelect:=FPlayer.InputSelect;
    sleep(5);

    FPlayer.LoopUpdate;
  except
  end;

  FreeAndNil(FPlayer);
end;

{ TDSPlayer2 }

//property synch
constructor TDSPlayer2.Create(AOwner: TComponent);
begin
  inherited;
  FThread:=TDSThread.Create(self);
end;

destructor TDSPlayer2.Destroy;
begin
  FThread.Terminate;
  FThread.WaitFor;
  FreeAndNil(FThread);

  FreeAndNil(FBitmap);
  inherited;
end;

function TDSPlayer2.GetAsyncPlayer: TDSPlayer;
begin
  result:=FThread.FPlayer;
end;

procedure TDSPlayer2.SeekAfterOpenTakolas(const s: double);
begin
  FThread.FPlayer.FSeekAfterOpenTakolas:=s+0.0000001;
end;

procedure TDSPlayer2.SetAudioDeviceName(const Value: AnsiString);
begin
  FNewAudioDeviceName := Value;
  Include(FChangedProps,pAudioDeviceName);
end;

procedure TDSPlayer2.SetFileName(const Value: AnsiString);
begin
  if(Owner<>nil)and(Owner is TWinControl)and TWinControl(Owner).HandleAllocated then
    FThread.FPlayer.FThrdOwnerHandle:=TWinControl(Owner).Handle;

  FNewFileName := Value;
  Include(FChangedProps,pFileName);
end;

procedure TDSPlayer2.SetInputSelect(const Value: integer);
begin
  FNewInputSelect := Value;
  Include(FChangedProps,pInputSelect);
end;

procedure TDSPlayer2.SetLoop(const Value: boolean);
begin
  FNewLoop := Value;
  Include(FChangedProps,pLoop);
end;

procedure TDSPlayer2.SetPlaying(const Value: boolean);
begin
  FNewPlaying := Value;
  Include(FChangedProps,pPlaying);
end;

procedure TDSPlayer2.SetPosition(const Value: double);
begin
  FNewPosition := Value;
  Include(FChangedProps,pPosition);
end;

procedure TDSPlayer2.SetRate(const Value: double);
begin
  FNewRate := Value;
  Include(FChangedProps,pRate);
end;

procedure TDSPlayer2.SetTunerChannel(const Value: integer);
begin
  FNewTunerChannel := Value;
  Include(FChangedProps,pTunerChannel);
end;


procedure TDSPlayer2.ShowFilterProps;
begin
  FThrdShowFilterProps:=true;
end;

procedure TDSPlayer2.ShowPinProps;
begin
  FThrdShowPinProps:=true;
end;

{ TAMControl }

function nozero(a:integer):integer;begin if a=0 then exit(1) else exit(a)end;

function TAMControl._GetRange;
begin
  if(FType=ProcAmp)and(FOwner.FProcAmp<>nil)then FSupported:=S_OK=FOwner.FProcAmp.GetRange(tagVideoProcAmpProperty(FId),FMin,FMax,FStep,FDefault,tagVideoProcAmpFlags(FRangeFlags))else
  if(FType=CamCtrl)and(FOwner.FCamCtrl<>nil)then FSupported:=S_OK=FOwner.FCamCtrl.GetRange(tagCameraControlProperty(FId),FMin,FMax,FStep,FDefault,FRangeFlags)
                                            else begin FSupported:=false;FMin:=0;FMax:=0;FDefault:=0;FStep:=0;FRangeFlags:=0;end;

  FAutoSupported:=(FRangeFlags and 1)<>0;//logitech, conexantnal is

  result:=FSupported;

  FAutoSupported:=FAutoSupported and FSupported;
end;

function TAMControl._Get(out AValue,AFlags:integer):boolean;
begin
  if(FType=ProcAmp)and(FOwner.FProcAmp<>nil)then result:=S_OK=FOwner.FProcAmp.Get(tagVideoProcAmpProperty(FId),AValue,tagVideoProcAmpFlags(AFlags))else
  if(FType=CamCtrl)and(FOwner.FCamCtrl<>nil)then result:=S_OK=FOwner.FCamCtrl.Get(tagCameraControlProperty(FId),AValue,tagCameraControlFlags(AFlags))
                                            else begin result:=false;AValue:=0;AFlags:=0; end;
end;

function TAMControl._Set(const AValue,AFlags:integer):boolean;
begin
  if(FType=ProcAmp)and(FOwner.FProcAmp<>nil)then result:=S_OK=FOwner.FProcAmp.Set_(tagVideoProcAmpProperty(FId),AValue,tagVideoProcAmpFlags(AFlags))else
  if(FType=CamCtrl)and(FOwner.FCamCtrl<>nil)then result:=S_OK=FOwner.FCamCtrl.Set_(tagCameraControlProperty(FId),AValue,tagCameraControlFlags(AFlags))
                                            else result:=false;
end;

function TAMControl.GetDebug: ansistring;
var g,r:ansistring;
    v,f:integer;
begin
  r:='';if _GetRange then r:=format('mi:%d ma:%d st:%d d:%d rfl:%d',[FMin,FMax,FStep,FDefault,FRangeFlags]);
  g:='';if _Get(v,f)then g:=format(' v:%d fl:%d',[v,f]);
  result:=r+g;
end;

function TAMControl.GetSupported: boolean;
begin
  _GetRange;result:=FSupported;
end;

function TAMControl.GetDefaultValue: single;
begin
  _GetRange;result:=EnsureRange((FDefault-FMin)/nozero(FMax-FMin),0,1);
end;

function TAMControl.GetAutoSupported: boolean;
begin
  _getrange;result:=FAutoSupported;
end;

function TAMControl.GetValue: single;
var val,flags:integer;
begin
  _GetRange;if not FSupported then exit(0);
  if not _Get(val,flags)then exit(0);
  result:=EnsureRange((val-FMin)/nozero(FMax-FMin),0,1);
end;

procedure TAMControl.SetValue(const AValue: single);
var val,flags:integer;
begin
  FLastSetValue:=AValue;
  _GetRange;if not FSupported then exit;
  if not _Get(val,flags)then exit;

  //standard
  val:=round(EnsureRange(AValue,0,1)*(FMax-FMin)+FMin);

  _Set(val,flags);
end;

constructor TAMControl.Create(const AOwner: TAMControls; const AName: ansistring; const AType: TAMControlType; const AId: integer);
begin
  inherited Create;
  FOwner:=AOwner;
  FName:=AName;
  FHash:=Crc32UC(AName);
  FType:=AType;
  FId:=AId;
end;

function TAMControl.GetAuto: boolean;
var val,flags:integer;
begin
  if not(_GetRange and FAutoSupported)then exit(false);
  if not _Get(val,flags)then exit(false);

  //nonstandard
  case FOwner.FHardware of
    Conexant:flags:=3-flags;
    Logitech:begin
      if(FType=ProcAmp)or(FType=CamCtrl)and(FId=ord(CameraControl_Focus))then flags:=flags-1
                                                                         else flags:=3-flags;
    end;
  end;

  //standard
  result:=flags=2;
end;

procedure TAMControl.SetAuto(const AValue: boolean);
var flags:integer;
    val:integer;
begin
  if not(_GetRange and FAutoSupported)then exit;
  if not _Get(val,flags)then exit;

  //standard
  if AValue then flags:=2 else flags:=1;

  //nonstandard
  case FOwner.FHardware of
    Conexant:flags:=3-flags;
    Logitech:begin
      if(FType=ProcAmp)or(FType=CamCtrl)and(FId=ord(CameraControl_Focus))then flags:=flags+1
                                                                         else flags:=3-flags;
    end;
  end;

  _Set(Val,Flags);
end;

{ TAMControls }

procedure TAMControls.Clear;
var i:integer;
begin
  for i:=0 to high(FControls)do FreeAndNil(FControls[i]);
  SetLength(FControls,0);
end;

constructor TAMControls.Create;
  procedure Add(const AName:ansistring;AType:TAMControlType;AId:integer);
  begin
    setlength(FControls,length(FControls)+1);
    FControls[high(FControls)]:=TAMControl.Create(Self,AName,AType,AId);
  end;

var i:integer;
begin
  inherited;

  for i:=0 to ord(high(tagVideoProcAmpProperty))do
    Add(copy(GetEnumName(TypeInfo(tagVideoProcAmpProperty),i),14),ProcAmp,i);
  for i:=0 to ord(high(tagCameraControlProperty))do
    Add(copy(GetEnumName(TypeInfo(tagCameraControlProperty),i),15),CamCtrl,i);
end;

destructor TAMControls.Destroy;
begin
  Clear;
  inherited;
end;

function TAMControls.GetByHash(const AHash: integer): TAMControl;
var c:TAMControl;
begin
  for c in FControls do if c.FHash=AHash then exit(c);
  result:=nil;
end;

function TAMControls.GetByIndex(const AIndex: integer): TAMControl;
begin
  if InRange(AIndex,0,high(FControls))then result:=FControls[AIndex]
                                      else result:=nil;
end;

function TAMControls.GetByName(const AName: AnsiString): TAMControl;
begin
  result:=ByHash[Crc32UC(AName)];
end;

function TAMControls.GetByNameOrIndex(const ANameOrIndex: variant): TAMControl;
begin
  if VarIsOrdinal(ANameOrIndex)then result:=ByIndex[ANameOrIndex]
                               else result:=ByName[ANameOrIndex];
end;

function TAMControls.GetCount: integer;
begin
  result:=length(FControls);
end;

procedure TAMControls.SetDevice(const ADevice: IInterface;const ADeviceName: AnsiString);
begin
  if Pos('Logitech',ADeviceName,[poIgnoreCase])>0 then FHardware:=Logitech else
  if Pos('Conexant',ADeviceName,[poIgnoreCase])>0 then FHardware:=Conexant else
    FHardware:=Standard;

  FProcAmp:=nil;Supports(ADevice,IID_IAMVideoProcAmp,FProcAmp);
  FCamCtrl:=nil;Supports(ADevice,IID_IAMCameraControl,FCamCtrl);
end;

initialization
//  CoInitializeEx(nil,0);
finalization
end.
