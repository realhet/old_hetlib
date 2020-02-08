unit UAdl;
interface
uses Windows, SysUtils, classes, het.Utils, Generics.Collections;

////////////////////////////////////////////////////////////////////////////////
///  AMD Display Library imports                               2011/rea_het  ///
////////////////////////////////////////////////////////////////////////////////

const
  ADL_MAX_PATH=256;

type
  int=integer;
  TADLStr=array[0..ADL_MAX_PATH-1]of ansichar;
  ADL_MAIN_MALLOC_CALLBACK=function(size:integer):integer;stdcall;

  TADLDisplayPos=record
    X,Y,XDefault,YDefault,MinX,MinY,MaxX,MaxY,StepX,StepY:int;
    function dump:ansistring;
  end;

  TADLAdapterInfo=packed record
    iSize:int;
    iAdapterIndex:int;
    strUDID:TADLStr;/// The unique device ID associated with this adapter.
    iBusNumber:int;/// The BUS number associated with this adapter.
    iDeviceNumber:int;/// The driver number associated with this adapter.
    iFunctionNumber:int ;/// The function number.
    iVendorID:int ;/// The vendor ID associated with this adapter.
    strAdapterName:TADLStr;/// Adapter name.
    strDisplayName:TADLStr;/// Display name. For example, "\\Display0" for Windows or ":0:0" for Linux.
    iPresent:int;/// Present or not; 1 if present and 0 if not present.It the logical adapter is present, the display name such as \\.\Display1 can be found from OS
    /////win specific
    iExist:int;  /// Exist or not; 1 is exist and 0 is not present.
    strDriverPath:TADLStr;/// Driver registry path.
    strDriverPathExt:TADLStr;/// Driver registry path Ext for.
    strPNPString:TADLStr;/// PNP string from Windows.
    iOSDisplayIndex:int ;/// It is generated from EnumDisplayDevices.
    function Dump:ansistring;
  end;PADLAdapterInfo=^TADLAdapterInfo;

  TADLDisplayID=packed record
    iDisplayLogicalIndex:int;/// The logical display index belonging to this adapter.
    iDisplayPhysicalIndex:int;///\brief The physical display index.
    /// For example, display index 2 from adapter 2 can be used by current adapter 1.\n
    /// So current adapter may enumerate this adapter as logical display 7 but the physical display
    /// index is still 2.
    iDisplayLogicalAdapterIndex:int;/// The persistent logical adapter index for the display.
    iDisplayPhysicalAdapterIndex:int;///\brief The persistent physical adapter index for the display.
    /// It can be the current adapter or a non-local adapter. \n
    /// If this adapter index is different than the current adapter,
    /// the Display Non Local flag is set inside DisplayInfoValue.
    function Dump:ansistring;
  end;

  TADLMode=packed record
    iAdapterIndex:int;
    displayID:TADLDisplayID;
    iXPos,iYPos,iXRes,iYRes:int;
    iColourDepth:int;
    fRefreshRate:single;
    iOrientation:int;/// Screen orientation. E.g., 0, 90, 180, 270.
    iModeFlag:int;/// Vista mode flag indicating Progressive or Interlaced mode.
    iModeMask:int;/// The bit mask identifying the number of bits this Mode is currently using. It is the sum of all the bit definitions defined in \ref define_displaymode
    iModeValue:int;/// The bit mask identifying the display status. The detailed definition is in  \ref define_displaymode
    function Dump:ansistring;
  end;PADLMode=^TADLMode;

  TADLDisplayInfo=packed record
    displayID:TADLDisplayID;
    iDisplayControllerIndex:int; ///\deprecated The controller index to which the display is mapped.\n Will not be used in the future\n
    strDisplayName:TADLStr;/// The display's EDID name.
    strDisplayManufacturerName:TADLStr;/// The display's manufacturer name.
    iDisplayType:int;/// The Display type. For example: CRT, TV, CV, DFP.
    iDisplayOutputType:int;/// The display output type. For example: HDMI, SVIDEO, COMPONMNET VIDEO.
    iDisplayConnector:int;/// The connector type for the device.
    iDisplayInfoMask:int;///\brief The bit mask identifies the number of bits ADLDisplayInfo is currently using. \n
      /// It will be the sum all the bit definitions in ADL_DISPLAY_DISPLAYINFO_xxx.
    iDisplayInfoValue:int;/// The bit mask identifies the display status. \ref define_displayinfomask
    function dump:ansistring;
  end;PADLDisplayInfo=^TADLDisplayInfo;

  TADLPMActivity=record
    iSize,/// Must be set to the size of the structure
    iEngineClock,
    iMemoryClock,
    iVddc,/// Current core voltage.
    iActivityPercent,/// GPU utilization.
    iCurrentPerformanceLevel,/// Performance level index.
    iCurrentBusSpeed,/// Current PCIE bus speed.
    iCurrentBusLanes,/// Number of PCIE bus lanes.
    iMaximumBusLanes,/// Maximum number of PCIE bus lanes.
    iReserved:int;
  end;

  TADLTemperature=record
    iSize,
    iTemperature:int; //in 0.001 degrees
  end;

  TADLFanSpeedValue=record
    iSize,
    iSpeedType, /// Possible valies: \ref ADL_DL_FANCTRL_SPEED_TYPE_PERCENT or \ref ADL_DL_FANCTRL_SPEED_TYPE_RPM
    iFanSpeed,  /// Fan speed value
    iFlags:int; /// The only flag for now is: \ref ADL_DL_FANCTRL_FLAG_USER_DEFINED_SPEED
  end;

  TADLODParameterRange=packed record
    iMin, iMax, iStep: int;
  end;
  TADLODParameters=packed record
    iSize,   /// Must be set to the size of the structure
    iNumberOfPerformanceLevels,
    iActivityReportingSupported,
    iDiscretePerformanceLevels,  /// Indicates whether the GPU supports discrete performance levels or performance range.
    iReserved:int;
    sEngineClock,
    sMemoryClock,
    sVddc:TADLODParameterRange;
  end;

  TADLODPerformanceLevel=packed record
    iEngineClock,
    iMemoryClock,
    iVddc: int;
  end;

  TADLODPerformanceLevels=packed record
    iSize, /// Must be set to sizeof( \ADLODPerformanceLevels ) + sizeof( \ref ADLODPerformanceLevel ) * (ADLODParameters.iNumberOfPerformanceLevels - 1)
    iReserved:int;
    aLevels:array[0..7]of TADLODPerformanceLevel; /// Array of performance state descriptors. Must have ADLODParameters.iNumberOfPerformanceLevels elements.
  end;

const
  ADL_DL_FANCTRL_FLAG_USER_DEFINED_SPEED=1;
  ADL_DL_FANCTRL_SPEED_TYPE_PERCENT=1;
  ADL_DL_FANCTRL_SPEED_TYPE_RPM=2;

////////////////////////////////////////////////////////////////////////////////
/// Imported functions

type
  T_ADL_Main_Control_Create=function(const memCallback:ADL_MAIN_MALLOC_CALLBACK;iEnumConnectedAdapters:int):int;cdecl;
  T_ADL_Main_Control_Destroy=function:int;cdecl;
  TADL_Main_Control_Refresh=function :int;cdecl;
  TADL_Adapter_NumberOfAdapters_Get=function (out NumAdapters:int):int;cdecl;
  TADL_Adapter_AdapterInfo_Get=function (lpInfo:PADLAdapterInfo;iInputSize:int):int;cdecl;
  TADL_Adapter_Active_Get=function (iAdapterIndex:int;out Status:int):int;cdecl;
  TADL_Adapter_Active_Set=function (iAdapterIndex:int;Status:int):int;cdecl;
  TADL_Adapter_Primary_Get=function (out iPrimaryAdapterIndex:int):int;cdecl;
  TADL_Adapter_Primary_Set=function (iPrimaryAdapterIndex:int):int;cdecl;
  TADL_Adapter_Speed_Set=function (iAdapterIndex:int; iSpeed:int):int;cdecl;
  TADL_Adapter_ID_Get=function (iAdapterIndex:int;out AdapterID:int):int;cdecl;
  TADL_Display_NumberOfDisplays_Get=function (iAdapterIndex:int;out NumDisplays:int):int;cdecl;
  TADL_Display_DisplayInfo_Get=function (iAdapterIndex:int;out NumDisplays:int;out Info:PADLDisplayInfo;iForceDetect:int):int;cdecl;
  TADL_Display_Position_Get=function (iAdapterIndex,iDisplayIndex:int;out X,Y,XDefault,YDefault,MinX,MinY,MaxX,MaxY,StepX,StepY:int):int;cdecl;
  TADL_Display_Size_Get    =function (iAdapterIndex,iDisplayIndex:int;out X,Y,XDefault,YDefault,MinX,MinY,MaxX,MaxY,StepX,StepY:int):int;cdecl;
  TADL_Display_Position_Set=function (iAdapterIndex,iDisplayIndex,X,Y:int):int;cdecl;
  TADL_Display_Size_Set=function (iAdapterIndex,iDisplayIndex,W,H:int):int;cdecl;
  TADL_Display_Modes_Get=function (iAdapterIndex,iDisplayIndex:int;out NumModes;out Modes:PADLMode):int;cdecl;
  TADL_Display_Modes_Set=function (iAdapterIndex,iDisplayIndex,iNumModes:integer;Modes:PADLMode):int;cdecl;
  TADL_Overdrive5_CurrentActivity_Get=function (iAdapterIndex:int;var Activity:TADLPMActivity):int;cdecl;
  TADL_Overdrive5_Temperature_Get=function (iAdapterIndex,iThermalControllerIndex:int;var Temperature:TADLTemperature):int;cdecl;
  TADL_Overdrive5_FanSpeed_Get=function (iAdapterIndex,iThermalControllerIndex:int;var FanSpeedValue:TADLFanSpeedValue):int;cdecl;
  TADL_Overdrive5_ODParameters_Get=function(iAdapterIndex:int;out OdParameters:TADLODParameters):int;cdecl;
  TADL_Overdrive5_ODPerformanceLevels_Get=function(iAdapterIndex:int; iDefault:int; var lpOdPerformanceLevels:TADLODPerformanceLevels):int;cdecl;
  TADL_Overdrive5_ODPerformanceLevels_Set=function (iAdapterIndex:int; const lpOdPerformanceLevels:TADLODPerformanceLevels):int;cdecl;

var
  _ADL_Main_Control_Create:T_ADL_Main_Control_Create;
  _ADL_Main_Control_Destroy:T_ADL_Main_Control_Destroy;
  ADL_Main_Control_Refresh:TADL_Main_Control_Refresh;
  ADL_Adapter_NumberOfAdapters_Get:TADL_Adapter_NumberOfAdapters_Get;
  ADL_Adapter_AdapterInfo_Get:TADL_Adapter_AdapterInfo_Get;
  ADL_Adapter_Active_Get:TADL_Adapter_Active_Get;
  ADL_Adapter_Active_Set:TADL_Adapter_Active_Set;
  ADL_Adapter_Primary_Get:TADL_Adapter_Primary_Get;
  ADL_Adapter_Primary_Set:TADL_Adapter_Primary_Set;
  ADL_Adapter_Speed_Set:TADL_Adapter_Speed_Set;
  ADL_Adapter_ID_Get:TADL_Adapter_ID_Get;
  ADL_Display_NumberOfDisplays_Get:TADL_Display_NumberOfDisplays_Get;
  ADL_Display_DisplayInfo_Get:TADL_Display_DisplayInfo_Get;
  ADL_Display_Position_Get:TADL_Display_Position_Get;
  ADL_Display_Size_Get    :TADL_Display_Size_Get    ;
  ADL_Display_Position_Set:TADL_Display_Position_Set;
  ADL_Display_Size_Set:TADL_Display_Size_Set;
  ADL_Display_Modes_Get:TADL_Display_Modes_Get;
  ADL_Display_Modes_Set:TADL_Display_Modes_Set;
  ADL_Overdrive5_CurrentActivity_Get:TADL_Overdrive5_CurrentActivity_Get;
  ADL_Overdrive5_Temperature_Get:TADL_Overdrive5_Temperature_Get;
  ADL_Overdrive5_FanSpeed_Get:TADL_Overdrive5_FanSpeed_Get;
  ADL_Overdrive5_ODParameters_Get:TADL_Overdrive5_ODParameters_Get;
  ADL_Overdrive5_ODPerformanceLevels_Get:TADL_Overdrive5_ODPerformanceLevels_Get;
  ADL_Overdrive5_ODPerformanceLevels_Set:TADL_Overdrive5_ODPerformanceLevels_Set;

////////////////////////////////////////////////////////////////////////////////
/// Own stuff

function ADL_ErrorStr(res:int):ansistring;
function ADL_Main_Control_Create(iEnumConnectedAdapters:int):int;
function ADL_Main_Control_Destroy:int;

function ADL_Overdrive5_Stats:ansistring;//own

////////////////////////////////////////////////////////////////////////////////
///  TDisplays                                                               ///
////////////////////////////////////////////////////////////////////////////////

type
  TDisplays=class;

  TDisplay=class
  private
    FDisplays:TDisplays;
    FAdapterInfo:TADLAdapterInfo;
    FDisplayInfo:TADLDisplayInfo;
    FMode:TADLMode;
    FActive,FPrimary:boolean;
    FIdx:integer;
    FChanged:boolean;
    function GetName:ansistring;
    function GetId:ansistring;
    procedure SetActive(v:boolean);
    procedure SetPrimary(v:boolean);
    procedure SetWidth(v:integer);
    procedure SetHeight(v:integer);
    procedure SetLeft(v:integer);
    procedure SetTop(v:integer);
    procedure SetRefreshRate(v:single);
    procedure SetOrientation(v:integer);
    procedure SetColorDepth(v:integer);

    function GetBounds:TRect;procedure SetBounds(const v:trect);
    function GetPos:TPoint;procedure SetPos(const v:TPoint);
    function GetSize:TSize;procedure SetSize(const v:tsize);
    procedure chg;
    function GetConfig: AnsiString;
    procedure SetConfig(const Value: AnsiString);//notify
  public
    constructor Create(ADisplays:TDisplays);
    function Dump:ansistring;
    property DisplayIdx:integer read FDisplayInfo.DisplayID.iDisplayLogicalIndex;
    property AdapterIdx:integer read FDisplayInfo.DisplayID.iDisplayLogicalAdapterIndex;
    property OSIdx:integer read FAdapterInfo.iOSDisplayIndex;
    property BusNumber:integer read FAdapterInfo.iBusNumber;
    property Name:ansistring read GetName;
    property Id:ansistring read GetId;
    property Idx:integer read FIdx;
    property Active:boolean read FActive write SetActive;
    property Primary:boolean read FPrimary write SetPrimary;
    property Width:integer read FMode.iXRes write SetWidth;
    property Height:integer read FMode.iYRes write SetHeight;
    property Top:integer read FMode.iYPos write SetTop;
    property Left:integer read FMode.iXPos write SetLeft;
    property RefreshRate:single read FMode.fRefreshRate write SetRefreshRate;
    property Orientation:integer read FMode.iOrientation write SetOrientation;
    property ColorDepth:integer read FMode.iColourDepth write SetColorDepth;
    //calculated stuff
    property Bounds:TRect read GetBounds write SetBounds;
    property Pos:TPoint read GetPos write SetPos;
    property Size:TSize read GetSize write SetSize;
    property Changed:Boolean read FChanged;
    property Config:AnsiString read GetConfig write SetConfig;
  end;

  TDisplays=class
  private
    FDisplays:array of TDisplay;
    procedure ReallocDisplays(const ALength:integer);
    function GetByIdx(i:integer):TDisplay;
    function GetById(AId:ansistring):TDisplay;
    function GetByName(AName:ansistring):TDisplay;
    function GetByPos(const APos:TPoint):TDisplay;
    function GetPrimary:TDisplay;
    procedure SetPrimary(p:TDisplay);
    function GetConfig:ansistring;
    procedure SetConfig(const Value:ansistring);
  public
    constructor Create;
    destructor Destroy;override;
    function Dump:ansistring;

    procedure Refresh;
    procedure Apply;
    function Changed:boolean;
    function Count:integer;
    function CountActive:integer;
    property ByIdx[i:integer]:TDisplay read GetByIdx;default;
    property ById[AId:ansistring]:TDisplay read GetById;
    property ByName[AName:ansistring]:TDisplay read GetByName;
    property ByPos[const APos:TPoint]:TDisplay read GetByPos;
    property Primary:TDisplay read GetPrimary write SetPrimary;
    property Config:ansistring read GetConfig write SetConfig;
  public
    type
      TEnumerator = class(TEnumerator<TDisplay>)
      private
        FList:TDisplays;
        FIndex:Integer;
      protected
        function DoGetCurrent:TDisplay; override;
        function DoMoveNext:Boolean;override;
      public
        constructor Create(AList:TDisplays);
      end;
    function GetEnumerator:TEnumerator;reintroduce;
  end;

function Displays:TDisplays;//global

implementation

var ADLDLLExists:integer;//-1:does not exist 1:exists 0:have to check
    ADLInitialized:boolean;
    HADLModule:HMODULE;

function ADL_Malloc(size:integer):pointer;stdcall;
begin
  getmem(result,size);
end;

procedure LoadADLProcs(const h:hmodule);

  function a(const name:PAnsiChar):pointer;
  begin
    result:=GetProcAddress(h,name);
    if Result=nil then raise Exception.Create('ADL Exception: Unable to get address of "'+name+'"');
  end;

begin
  _ADL_Main_Control_Create:=a('ADL_Main_Control_Create');
  _ADL_Main_Control_Destroy:=a('ADL_Main_Control_Destroy');
  ADL_Main_Control_Refresh:=a('ADL_Main_Control_Refresh');
  ADL_Adapter_NumberOfAdapters_Get:=a('ADL_Adapter_NumberOfAdapters_Get');
  ADL_Adapter_AdapterInfo_Get:=a('ADL_Adapter_AdapterInfo_Get');
  ADL_Adapter_Active_Get:=a('ADL_Adapter_Active_Get');
  ADL_Adapter_Active_Set:=a('ADL_Adapter_Active_Set');
  ADL_Adapter_Primary_Get:=a('ADL_Adapter_Primary_Get');
  ADL_Adapter_Primary_Set:=a('ADL_Adapter_Primary_Set');
  ADL_Adapter_Speed_Set:=a('ADL_Adapter_Speed_Set');
  ADL_Adapter_ID_Get:=a('ADL_Adapter_ID_Get');
  ADL_Display_NumberOfDisplays_Get:=a('ADL_Display_NumberOfDisplays_Get');
  ADL_Display_DisplayInfo_Get:=a('ADL_Display_DisplayInfo_Get');
  ADL_Display_Position_Get:=a('ADL_Display_Position_Get');
  ADL_Display_Size_Get:=a('ADL_Display_Size_Get');
  ADL_Display_Position_Set:=a('ADL_Display_Position_Set');
  ADL_Display_Size_Set:=a('ADL_Display_Size_Set');
  ADL_Display_Modes_Get:=a('ADL_Display_Modes_Get');
  ADL_Display_Modes_Set:=a('ADL_Display_Modes_Set');
  ADL_Overdrive5_CurrentActivity_Get:=a('ADL_Overdrive5_CurrentActivity_Get');
  ADL_Overdrive5_Temperature_Get:=a('ADL_Overdrive5_Temperature_Get');
  ADL_Overdrive5_FanSpeed_Get:=a('ADL_Overdrive5_FanSpeed_Get');
  ADL_Overdrive5_ODParameters_Get:=a('ADL_Overdrive5_ODParameters_Get');
  ADL_Overdrive5_ODPerformanceLevels_Get:=a('ADL_Overdrive5_ODPerformanceLevels_Get');
  ADL_Overdrive5_ODPerformanceLevels_Set:=a('ADL_Overdrive5_ODPerformanceLevels_Set');
end;

function IsWin64Bit:boolean;
var h:HMODULE;
begin
  h:=LoadLibrary('kernel32.dll');
  result:=GetProcAddress(h,'GetCurrentProcessorNumber')<>nil;
  FreeLibrary(h);
end;

function ADL_Main_Control_Create(iEnumConnectedAdapters:int):int;
begin
  if AdlInitialized then exit(0);
  if AdlDLLExists=0 then begin
    HADLModule:=LoadLibrary('atiadlxx.dll');
    if HADLModule=0 then HADLModule:=LoadLibrary('atiadlxy.dll');

    if HADLModule=0 then begin
      ADLDLLExists:=-1;
      result:=-8;//not supported
    end else begin
      ADLDLLExists:=1;
      LoadADLProcs(HADLModule);
      result:=_ADL_Main_Control_Create(@ADL_MALLOC,iEnumConnectedAdapters);
    end;
  end else if AdlDLLExists=1 then begin
    result:=_ADL_Main_Control_Create(@ADL_MALLOC,iEnumConnectedAdapters);
    if Result=0 then
      AdlInitialized:=true;
  end else
    result:=-8;//not supported
end;

function ADL_Main_Control_Destroy:int;
begin
  if AdlInitialized then begin
    AdlInitialized:=false;
    result:=_ADL_Main_Control_Destroy;
    FreeModule(HADLModule);
    HADLModule:=0;
  end else
    Result:=0;
end;

function ADL_ErrorStr(res:integer):ansistring;
begin case res of
  4:result:='OK_WAIT';
  3:result:='OK_RESTART';
  2:result:='OK_MODE_CHANGE';
  1:result:='OK_WARNING';
  0:result:='OK';
  -1:result:='ERR';
  -2:result:='ERR_NOT_INIT';
  -3:result:='ERR_INVALID_PARAM';
  -4:result:='ERR_INVALID_PARAM_SIZE';
  -5:result:='ERR_INVALID_ADL_IDX';
  -6:result:='ERR_INVALID_CONTROLLER_IDX';
  -7:result:='ERR_INVALID_DIPLAY_IDX';
  -8:result:='ERR_NOT_SUPPORTED';
  -9:result:='ERR_NULL_POINTER';
  -10:result:='ADL_ERR_DISABLED_ADAPTER';
  -11:result:='ERR_INVALID_CALLBACK';
  -12:result:='ERR_RESOURCE_CONFLICT';
  else result:='ERR_UNKNOWN_'+tostr(res);end;
end;

function TADLAdapterInfo.Dump:ansistring;
  procedure a(d,s:ansistring);overload;begin result:=result+'  '+s+' : '+d+#13#10 end;
  procedure a(i:integer;s:ansistring);overload;begin a(tostr(i),s)end;
begin
  result:='';
  a(iSize,'iSize');
  a(iAdapterIndex,'iAdapterIndex');
  a(strUDID,'strUDID');
  a(iBusNumber,'iBusNumber');
  a(iDeviceNumber,'iDeviceNumber');
  a(iFunctionNumber,'iFunctionNumber');
  a(inttohex(iVendorID,8),'iVendorID');
  a(strAdapterName,'strAdapterName');
  a(strDisplayName,'strDisplayName');
  a(iPresent,'iPresent');
  a(iExist,'iExist');
  a(strDriverPath,'strDriverPath');
  a(strDriverPathExt,'strDriverPathExt');
  a(strPNPString,'strPNPString');
  a(iOSDisplayIndex,'iOSDisplayIndex');
end;

function TADLDisplayID.Dump:ansistring;
begin
  result:=format('DisplayID log:%d phys:%d AdapterID log:%d phys:%d',
    [iDisplayLogicalIndex,iDisplayPhysicalIndex,iDisplayLogicalAdapterIndex,iDisplayPhysicalAdapterIndex]);
end;

function TADLDisplayInfo.Dump:ansistring;
  procedure a(d,s:ansistring);overload;begin result:=result+'    '+s+' : '+d+#13#10 end;
  procedure a(i:integer;s:ansistring);overload;begin a(tostr(i),s)end;
begin
  result:='';
  a(displayID.dump,'displayID');
  a(iDisplayControllerIndex,'iDisplayControllerIndex');
  a(strDisplayName,'strDisplayName');
  a(strDisplayManufacturerName,'strDisplayManufacturerName');
  a(iDisplayType,'iDisplayType');
  a(iDisplayOutputType,'iDisplayOutputType');
  a(iDisplayConnector,'iDisplayConnector');
  a(inttohex(iDisplayInfoMask,8),'iDisplayInfoMask');
  a(inttohex(iDisplayInfoValue,8),'iDisplayInfoValue');
  a(iDisplayInfoValue and 3,'Connected&Mapped');
end;

function TADLDisplayPos.Dump;
begin
  result:=format('[Act(%d,%d),Default(%d,%d),Min(%d,%d),Max(%d,%d),Step(%d,%d)]',
    [X,Y,XDefault,YDefault,MinX,MinY,MaxX,MaxY,StepX,StepY]);
end;

function ADL_Display_Position_Get2(iAdapterIndex,iDisplayIndex:int):TADLDisplayPos;
begin
  FillChar(result,sizeof(result),-1);
  with result do ADL_Display_Position_Get(iAdapterIndex,iDisplayIndex,X,Y,XDefault,YDefault,MinX,MinY,MaxX,MaxY,StepX,StepY);
end;

function ADL_Display_Size_Get2(iAdapterIndex,iDisplayIndex:int):TADLDisplayPos;
begin
  FillChar(result,sizeof(result),-1);
  with result do ADL_Display_Size_Get(iAdapterIndex,iDisplayIndex,X,Y,XDefault,YDefault,MinX,MinY,MaxX,MaxY,StepX,StepY);
end;

function TADLMode.Dump:ansistring;
  procedure a(d,s:ansistring);overload;begin result:=result+'      '+s+' : '+d+#13#10 end;
  procedure a(i:integer;s:ansistring);overload;begin a(tostr(i),s)end;
begin
  result:='';
  a(iAdapterIndex,'iAdapterIndex');
  a(displayID.Dump,'displayID');
  a(iXPos,'iXPos');
  a(iYPos,'iYPos');
  a(iXRes,'iXRes');
  a(iYRes,'iYRes');
  a(iColourDepth,'iColourDepth');
  a(format('%.2n',[fRefreshRate]),'fRefreshRate');
  a(iOrientation,'iOrientation');
  a(inttohex(iModeFlag,8),'iModeFlag');
  a(inttohex(iModeMask,8),'iModeMask');
  a(inttohex(iModeValue,8),'iModeValue');
end;


////////////////////////////////////////////////////////////////////////////////
///  TDisplay                                                                ///
////////////////////////////////////////////////////////////////////////////////

constructor TDisplay.Create(ADisplays:TDisplays);
begin
  inherited create;
  FDisplays:=ADisplays;
end;

procedure TDisplay.chg;
begin
  FChanged:=true;
end;

function TDisplay.GetId: ansistring;
begin
  result:=FAdapterInfo.strUDID;
end;

function TDisplay.GetName: ansistring;
begin
  result:=FAdapterInfo.strAdapterName;
end;

procedure TDisplay.SetActive(v:boolean);
begin
  if v=Active then exit;
  FActive:=v;
  chg;
end;

procedure TDisplay.SetPrimary(v:boolean);
var d:TDisplay;
begin
  if v and not self.FPrimary then begin
    for d in FDisplays do d.FPrimary:=d=self;
    chg;
  end;
end;

procedure TDisplay.SetWidth(v:integer);
begin
  if v=Width then exit;
  FMode.iXRes:=v;
  chg;
end;

procedure TDisplay.SetHeight(v:integer);
begin
  if v=Height then exit;
  FMode.iYRes:=v;
  chg;
end;

procedure TDisplay.SetLeft(v:integer);
begin
  if v=Left then exit;
  FMode.iXPos:=v;
  chg;
end;

procedure TDisplay.SetTop(v:integer);
begin
  if v=Top then exit;
  FMode.iYPos:=v;
  chg;
end;

procedure TDisplay.SetRefreshRate(v:single);
begin
  if v=RefreshRate then exit;
  FMode.fRefreshRate:=v;
  chg;
end;

procedure TDisplay.SetOrientation(v:integer);
begin
  if v=Orientation then exit;
  FMode.iOrientation:=v;
  chg;
end;

procedure TDisplay.SetColorDepth(v:integer);
begin
  if v=ColorDepth then exit;
  FMode.iColourDepth:=v;
  chg;
end;

function TDisplay.GetBounds:TRect;
begin
  if Orientation in [0,180] then result:=rect(Left,Top,Left+Width,Top+Height)
                            else result:=rect(Left,Top,Left+Height,Top+Width)
end;

procedure TDisplay.SetBounds(const v:trect);
begin
  Left:=v.Left;
  Top:=v.Top;
  if Orientation in[0,180]then begin
    Width:=v.Right-v.Left;
    Height:=v.Bottom-v.Top;
  end else begin
    Height:=v.Right-v.Left;
    Width:=v.Bottom-v.Top;
  end;
end;

function TDisplay.GetPos:TPoint;
begin
  result:=point(Left,Top);
end;

procedure TDisplay.SetPos(const v:TPoint);
begin
  Left:=v.X;
  Top:=v.Y;
end;

function TDisplay.GetSize:TSize;
begin
  result.cx:=Width;
  result.cy:=Height;
end;

procedure TDisplay.SetSize(const v:tsize);
begin
  Width:=v.cx;
  Height:=v.cy;
end;

function TDisplay.Dump: ansistring;
begin
  result:='----------------------------------------------'#13#10+
    'AdapterIdx/DisplayIdx: '+ToStr(AdapterIdx)+'/'+ToStr(DisplayIdx)+#13#10+
    'Active: '+ToStr(ord(FActive))+#13#10+
    'Primary: '+ToStr(ord(FPrimary))+#13#10+
    'Changed: '+ToStr(ord(FChanged))+#13#10+
    FAdapterInfo.Dump+FDisplayInfo.dump+FMode.Dump;
end;

function TDisplay.GetConfig: AnsiString;
var sl:TStrings;
  procedure a(n,v:ansistring);overload;begin sl.Values[n]:=v end;
  procedure a(n:ansistring;v:integer);overload;begin a(n,toStr(v))end;
begin
  sl:=TStringList.Create;sl.Delimiter:=';';
  a('Id',Id);
  a('Active',Ord(Active));
  a('Primary',Ord(Primary));
  a('Left',Left);
  a('Top',Top);
  a('Width',Width);
  a('Height',Height);
  a('Orientation',Orientation);
  a('RefreshRate',replacef(FormatSettings.DecimalSeparator,'.',format('%f',[RefreshRate]),[]));
  a('ColorDepth',ColorDepth);
  result:=sl.DelimitedText;
  sl.Free;
end;

procedure TDisplay.SetConfig(const Value: AnsiString);
var sl:TStrings;
    s:ansistring;
    i:integer;
    f:single;
  function a(n:ansistring):boolean;
  begin
    s:=sl.Values[n];
    i:=StrToIntDef(s,0);
    f:=StrToFloatDef(replacef('.',FormatSettings.DecimalSeparator,s,[]),0);
    result:=s<>'';
  end;

begin
  sl:=TStringList.Create;sl.Delimiter:=';';sl.DelimitedText:=Value;
  if a('Active')then Active:=i<>0;
  if a('Primary')then Primary:=i<>0;
  if a('Left')then Left:=i;
  if a('Top')then Top:=i;
  if a('Width')then Width:=i;
  if a('Height')then Height:=i;
  if a('Orientation')then Orientation:=i;
  if a('RefreshRate')then RefreshRate:=f;
  if a('ColorDepth')then ColorDepth:=i;
  sl.Free;
end;


////////////////////////////////////////////////////////////////////////////////
///  TDisplays                                                               ///
////////////////////////////////////////////////////////////////////////////////

constructor TDisplays.Create;
begin
  inherited;
  Refresh;
end;

destructor TDisplays.Destroy;
begin
  inherited;
  ReallocDisplays(0);
end;

function TDisplays.Dump: ansistring;
var d:TDisplay;
begin
  result:='ADL Display dump'#13#10;
  for d in Displays do
    result:=result+d.Dump;
end;

procedure TDisplays.ReallocDisplays(const ALength:integer);
var i,oldLength:integer;
begin
  oldLength:=length(FDisplays);
  for i:=High(FDisplays)downto ALength do FreeAndNil(FDisplays[i]);
  setLength(FDisplays,ALength);
  for i:=oldLength to high(FDisplays)do FDisplays[i]:=TDisplay.Create(self);
end;

function TDisplays.Count:integer;
begin
  result:=length(FDisplays);
end;

function TDisplays.CountActive:integer;
var d:TDisplay;
begin
  result:=0;
  for d in self do if d.Active then inc(result);
end;

function TDisplays.GetByIdx(i:integer):TDisplay;
begin
  if(i>=0)and(i<Count)then result:=FDisplays[i]
                      else result:=nil;
end;

function TDisplays.GetById(AId:ansistring):TDisplay;
var d:TDisplay;
begin
  for d in self do if cmp(d.Id,AId)=0 then exit(d);
  result:=nil;
end;

function TDisplays.GetByName(AName:ansistring):TDisplay;
var d:TDisplay;
begin
  for d in self do if cmp(d.Name,AName)=0 then exit(d);
  result:=nil;
end;

function TDisplays.GetByPos(const APos:TPoint):TDisplay;
var d:TDisplay;
begin
  for d in self do if PtInRect(d.Bounds,APos)then exit(d);
  result:=nil;
end;

function TDisplays.Changed:boolean;
var d:TDisplay;
begin
  for d in self do if d.Changed then exit(true);
  result:=false;
end;

function TDisplays.GetPrimary:TDisplay;
var d:TDisplay;
begin
  for d in self do if d.Primary then exit(d);
  result:=nil;
end;

procedure TDisplays.SetPrimary(p:TDisplay);
begin
  if p<>nil then p.Primary:=true;
end;

//enum
constructor TDisplays.TEnumerator.Create(AList: TDisplays);
begin
  FList:=AList;
  FIndex:=-1;
end;

function TDisplays.TEnumerator.DoGetCurrent: TDisplay;
begin
  result:=FList.ByIdx[FIndex];
end;

function TDisplays.TEnumerator.DoMoveNext: Boolean;
begin
  inc(FIndex);
  result:=(FIndex<FList.Count);
end;

function TDisplays.GetEnumerator: TEnumerator;
begin
  result:=TEnumerator.Create(self);
end;
//end of enum

procedure TDisplays.Refresh;

type
  TData=record
    _Active,_Primary:boolean;
    _AdapterInfo:TADLAdapterInfo;
    _DisplayInfo:TADLDisplayInfo;
    _Mode:TADLMode;
  end;

var
  data:array of TData;

  procedure GatherInfo;
  var AdapterInfo:array of TADLAdapterInfo;
      DisplayInfo:array of array of TADLDisplayInfo;
      i,j,k,AdapterCnt,AdapterIdx,DisplayIdx,ModeCnt,PrimaryAdapterIdx:int;
      tmpDI:PADLDisplayInfo;
      tmpM,p:PADLMode;
      duplicated:boolean;
  const ActiveOnly:boolean=false;
  begin
    if ADL_Main_Control_Create(1)<>0 then exit;
    ADL_Main_Control_Refresh;

    if ADL_Adapter_NumberOfAdapters_Get(AdapterCnt)<>0 then exit;
    setlength(AdapterInfo,AdapterCnt);
    if ADL_Adapter_AdapterInfo_Get(@AdapterInfo[0],SizeOf(AdapterInfo[0])*Length(AdapterInfo))<>0 then exit;

    ADL_Adapter_Primary_Get(PrimaryAdapterIdx);

    SetLength(DisplayInfo,length(AdapterInfo));
    for i:=0 to AdapterCnt-1 do begin
      AdapterIdx:=AdapterInfo[i].iAdapterIndex;

      tmpDI:=nil;
      ADL_Display_DisplayInfo_Get(AdapterIdx,j,tmpDI,0{forceDetect});
      setlength(DisplayInfo[i],j);
      if j>0 then begin
        move(tmpDI^,DisplayInfo[i,0],j*sizeof(DisplayInfo[i,0]));
        FreeMem(tmpDI);
        for j:=0 to j-1 do begin
          DisplayIdx:=DisplayInfo[i,j].displayID.iDisplayLogicalIndex;

          if DisplayInfo[i,j].displayID.iDisplayLogicalAdapterIndex<>AdapterIdx then Continue;
//          if(DisplayInfo[i,j].iDisplayInfoValue and 3)<>3 then Continue;//mapped&connected

          duplicated:=false;
          for k:=0 to high(data)do with data[k]._DisplayInfo.displayID do
            if{(iDisplayLogicalIndex=DisplayIdx)or}(iDisplayLogicalAdapterIndex=AdapterIdx)then begin
              duplicated:=true;
              break;
            end;
          if Duplicated then Continue;

          ADL_Display_Modes_Get(AdapterIdx,DisplayIdx,ModeCnt,tmpM);
          p:=tmpM;

          if ModeCnt>=1 then begin
            SetLength(data,length(data)+1);
            with data[high(data)]do begin
              _AdapterInfo:=AdapterInfo[i];
              _DisplayInfo:=DisplayInfo[i,j];
              _Mode:=tmpM^;
              ADL_Adapter_Active_Get(AdapterIdx,k);_Active:=k<>0;
              _Primary:=AdapterIdx=PrimaryAdapterIdx;
            end;
          end;
          FreeMem(p);
        end;
      end;
    end;
  end;

  procedure Sort;
  var i,j:integer;
      tmp:TData;
  begin
    for i:=0 to high(data)-1 do for j:=i+1 to high(Data)do
      if data[i]._AdapterInfo.iOSDisplayIndex>data[j]._AdapterInfo.iOSDisplayIndex then begin
        tmp:=data[i];data[i]:=data[j];data[j]:=tmp;
      end;
  end;

  procedure GenerateUniqueNames;
  var i,j,cnt,first:integer;
      names:array of ansistring;
  begin
    setlength(names,length(data));
    for i:=0 to high(data)do begin
      cnt:=0;first:=-1;
      for j:=0 to i-1 do if Cmp(data[i]._AdapterInfo.strAdapterName,data[j]._AdapterInfo.strAdapterName)=0 then begin
        inc(cnt);
        if first<0 then
          first:=j;
      end;
      names[i]:=trimf(data[i]._AdapterInfo.strAdapterName);
      if cnt>0 then names[i]:=names[i]+' ('+tostr(cnt+1)+')';
      if cnt=1 then names[first]:=names[first]+' (1)';
    end;

    for i:=0 to high(data)do
      StrCopy(@data[i]._AdapterInfo.strAdapterName[0],PAnsiChar(names[i]));
  end;

var i:integer;
begin
  GatherInfo;
  Sort;
  GenerateUniqueNames;

  ReallocDisplays(length(data));
  for i:=0 to high(data)do with data[i],FDisplays[i]do begin
    FAdapterInfo:=_AdapterInfo;
    FDisplayInfo:=_DisplayInfo;
    FMode:=_Mode;
    FActive:=_Active;
    FPrimary:=_Primary;
    FIdx:=i;
  end;
end;

procedure TDisplays.Apply;
var d:TDisplay;
    tmp:array of TADLMode;
    i:integer;
begin
  //1. Turn on Actives/Turn off inactives
  for d in Self do if d.Active then ADL_Adapter_Active_Set(d.AdapterIdx,1);
  for d in Self do if not d.Active then ADL_Adapter_Active_Set(d.AdapterIdx,0);
  //2. Set primary
  if(Primary<>nil)then with Primary do if Active then ADL_Adapter_Primary_Set(AdapterIdx);
  //3. Set Modes (Actives only)
  setlength(tmp,CountActive);
  i:=0;for d in Self do if d.Active then tmp[postInc(i)]:=d.FMode;
  ADL_Display_Modes_Set(-1,-1,length(tmp),pointer(tmp));
  //4. reread info
  Refresh;
end;

function TDisplays.GetConfig: ansistring;
var d:TDisplay;
begin
  result:='';
  for d in self do begin
    if result<>'' then Result:=Result+#13#10;
    result:=result+d.Config;
  end;
end;

procedure TDisplays.SetConfig(const Value: ansistring);
var s:ansistring;
    sl:TStringList;
    d:TDisplay;
begin
  sl:=TStringList.Create;sl.Delimiter:=';';
  for s in ListSplit(Value,#10)do begin
    sl.DelimitedText:=s;
    d:=ById[sl.Values['Id']];
    if d<>nil then
      d.Config:=s;
  end;
  sl.Free;
end;

var _Displays:TDisplays;
function Displays:TDisplays;
begin
  if _Displays=nil then _Displays:=TDisplays.Create;
  result:=_Displays;
end;


////////////////////////////////////////////////////////////////////////////////
///  Overdrive5 status report                                                ///
////////////////////////////////////////////////////////////////////////////////

function ADL_Overdrive5_Stats:ansistring;
  function simplifyname(s:ansistring):ansistring;
  begin
    s:=ReplaceF('radeon','',s,[roIgnoreCase]);
    s:=ReplaceF('ati','',s,[roIgnoreCase]);
    s:=ReplaceF('amd','',s,[roIgnoreCase]);
    s:=ReplaceF('series','',s,[roIgnoreCase]);
    result:=LeftJ(TrimF(s),10);
  end;

var act:TADLPMActivity;
    temp:TADLTemperature;
    fan:TADLFanSpeedValue;
    AdapterCnt:integer;
    AdapterInfo:TArray<TADLAdapterInfo>;
    a,i:integer;
    s,s2:string;

begin
  if ADL_Main_Control_Create(1)<>0 then exit;
  ADL_Main_Control_Refresh;

  if ADL_Adapter_NumberOfAdapters_Get(AdapterCnt)<>0 then exit;
  setlength(AdapterInfo,AdapterCnt);
  if ADL_Adapter_AdapterInfo_Get(@AdapterInfo[0],SizeOf(AdapterInfo[0])*Length(AdapterInfo))<>0 then exit;

  s:='';
  for a:=0 to high(AdapterInfo)do with AdapterInfo[a]do begin
    s2:=strPNPString;
    if charn(s2,length(s2)-2)='&' then Continue;//secondary adapter

    //from here: only active gpu's
//    ADL_Adapter_ID_Get(iAdapterIndex,i);
    s:=s+format('%2d',[iAdapterIndex])+':';
    s:=s+simplifyName(strAdapterName)+' ';

    //get activity
    FillChar(act,sizeof(act),0);act.iSize:=sizeof(act);
    if ADL_Overdrive5_CurrentActivity_Get(iAdapterIndex,act)=0then
      s:=s+format('%4d/%4d',[act.iEngineClock div 100,act.iMemoryClock div 100])+'MHz '+format('%3d',[act.iActivityPercent])+'% ';


    //get temps
    FillChar(temp,sizeof(temp),0);temp.iSize:=sizeof(temp);
    for i:=0 to 3 do if ADL_Overdrive5_Temperature_Get(iAdapterIndex,i,temp)=0then
      s:=s+format('%3d',[temp.iTemperature div 1000])+'''C ';

    //get fan
    FillChar(fan,sizeof(fan),0);fan.iSize:=sizeof(fan);
//    fan.iSpeedType:=ADL_DL_FANCTRL_SPEED_TYPE_PERCENT;
//{ettol a percent speed-tol 4xxx-es beszarik es tobbet nem mukodik az adl, ezt a szart bazz+ o.o}
    if ADL_Overdrive5_FanSpeed_Get(iAdapterIndex,0,fan)=0then
      s:=s+format('%2drpm ',[fan.iFanSpeed]);

    s:=s+#13#10;
  end;
  result:=copy(s,1,length(s)-2);
end;

initialization
finalization
  FReeAndNil(_Displays);
  ADL_Main_Control_Destroy;
end.
