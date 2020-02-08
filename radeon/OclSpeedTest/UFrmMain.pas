unit UFrmMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, math,
  het.Utils, het.Arrays, het.Cal, het.Cl, ExtCtrls;

const
  WorkCount=4000000;
  waveforntsize=64; //based on .elf files

  KernelTeraOps=WorkCount*1e-12{tera}*25{loop}*4400{instr/loop}*2{MAD};

  RunCount=32;
  BatchCount=2;

type
  TKernel=class
  private
    FGPUIdx:integer;
    FSecret:integer;
    FRunning:boolean;
    FT0:double;
  protected
    procedure _Init;virtual;abstract;
    procedure _Start;virtual;abstract;
    procedure _Check;virtual;abstract;//sets FRunning false when kernel done
  public
    constructor Create(AGPUIdx:integer);
    function Ready(const twin:TKernel=nil;const minTime:single=0):boolean;
    procedure Start;
    function Running:boolean;
    function ElapsedTime_sec:single;
  end;
  TKernelClass=class of TKernel;

  TCalKernel=class(TKernel)
  private
    dev:TCalDevice;
    module:TCalModule;
    uav,cb:TCalResource;
    ev:TCalEvent;
  protected
    procedure _Init;override;
    procedure _Start;override;
    procedure _Check;override;
  public
    destructor Destroy;override;
  end;

  TClKernel=class(TKernel)
  private
    dev:TClDevice;
    kernel:het.Cl.TClKernel;
    uav,cb:TClBuffer;
    ev:TClEvent;
  protected
    procedure _Init;override;
    procedure _Start;override;
    procedure _Check;override;
  public
    destructor Destroy;override;
  end;

type
  TFrmMain = class(TForm)
    Memo1: TMemo;
    tStartup: TTimer;
    tTwinUpdate: TTimer;
    procedure tStartupTimer(Sender: TObject);
    procedure tTwinUpdateTimer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    _T0,_T1:double;
    _minDt:double;
    Summary:TStringList;
    procedure BeginTest;
    procedure EndTest(AIsCal:boolean;const AMethod:ansistring; ABatch, ANumGpu :integer);
    procedure Log(const s:ansistring);
    procedure TestDumb(kclass:TKernelClass; numGpu:integer; asleep:boolean=false);
    procedure TestQueue(kclass:TKernelClass; numGpu:integer; asleep:boolean=false);
  public
    twin:array of TKernel;
    twinQueue,twinBatch:integer;
    OnTwinComplete:TProc;
    procedure TestTwin(kclass:TKernelClass; numGpu:integer; AOnComplete:TProc=nil);
    procedure TwinComplete;
  end;

var
  FrmMain: TFrmMain;

implementation

{$R *.dfm}

type TLogRec=record t:double;s:ansistring;end;
var _Log:THetArray<TLogRec>;

procedure TimeLog(const s:ansistring);
var r:TLogRec;
begin
  r.t:=QPS;
  r.s:=s;
  _Log.Append(r);
end;

procedure SaveLog(const name:ansistring);
var s:ansistring;
    i:integer;
begin with _Log do begin
  if Count>0 then for i:=0 to Count-1 do
    s:=s+Format('%10.3f %s'#13#10,[(FItems[i].t-FItems[0].t)*1000,FItems[i].s]);
  TFile('ocltest_'+name+'.log').Write(s);
  Clear;
end;end;

{ TKernel }

constructor TKernel.Create(AGPUIdx: integer);
begin
  FGPUIdx:=AGPUIdx;
  _init;
end;

procedure TKernel.Start;
begin
  if Running then raise Exception.Create('TKernel.Start() already running');
  FT0:=QPS;
  FSecret:=random($1000000);
  FRunning:=true;
  _Start;
end;

function TKernel.Running:boolean;
begin
  if FRunning then begin
    _Check;
  end;
  result:=FRunning;
end;

function TKernel.ElapsedTime_sec:single;
begin
  result:=QPS-FT0;
end;

function TKernel.Ready(const twin:TKernel=nil;const minTime:single=0):boolean;
begin
  result:=not FRunning and
    ((Twin=nil)or(not Twin.FRunning)or
     (Twin.ElapsedTime_sec>minTime));
end;

{ TCalKernel }

procedure TCalKernel._Init;
begin
  dev:=cal.devices[FGPUIdx];
  module:=dev.Context.NewModule(TFile('SpeedTest_cal.elf'));
  uav:=dev.NewResource(rlPinned,1,64 shl 10 shr 2,0);
  cb :=dev.NewResource(rlLocal ,4, 4 shl 10 shr 4,0);
end;

destructor TCalKernel.Destroy;
begin
  uav.Free; cb.Free; module.Free;
  inherited;
end;

procedure TCalKernel._Start;
begin
  module['cb0' ]:=cb;
  module['uav0']:=uav;

  cb.Ints[0]:=FSecret;
  ev:=module.runGrid(WorkCount,1,0);
end;

procedure TCalKernel._Check;
begin
  if ev.Finished then begin
    ev.Free;
    FRunning:=false;
    if uav.Ints[0]<>FSecret then raise Exception.Create('CALCULATION ERROR');
  end;
end;

{ TClKernel }

procedure TClKernel._Init;
begin
  dev:=cl.devices[FGPUIdx];
  kernel:=dev.NewKernel(TFile('SpeedTest_ocl.elf'));
  uav:=dev.NewBuffer('rw',64 shl 10);
  cb :=dev.NewBuffer('r' , 4 shl 10);
end;

destructor TClKernel.Destroy;
begin
  uav.Free; cb.Free; kernel.Free;
  inherited;
end;

procedure TClKernel._Start;
begin
  cb.Ints[0]:=FSecret;
  ev:=kernel.Run(WorkCount,uav,cb);
end;

procedure TClKernel._Check;
begin
  if ev.Finished then begin
    ev.Free;
    FRunning:=false;
    if uav.Ints[0]<>FSecret then raise Exception.Create('CALCULATION ERROR');
  end;
end;

{ TFrmMain }

procedure TFrmMain.Log(const s:ansistring);
begin
  FrmMain.Memo1.Lines.Add(s);
end;

procedure TFrmMain.BeginTest;
begin
  _T0:=QPS;
end;

procedure TFrmMain.EndTest(AIsCal:boolean;const AMethod:ansistring;ABatch, ANumGpu:integer);
const relBase=925{1125}*2048*2*1e-6; //hd7970 base tflops
var dt,tflopsps,percent:double;
    col:integer;
    s:ansistring;
begin
  _T1:=QPS;
  dt:=_T1-_T0;
  if ABatch=0 then _minDt:=dt
              else _minDt:=min(_minDt,dt);
  if ABatch=BatchCount-1 then begin
    dt:=_minDt;
    tflopsps:=KernelTeraOps*RunCount/dt;
    percent:=100*tflopsps/relBase;
    log(format('%dgpu  %-18s %-3s %dbatches  %8.3f sec  %8.3f TFlops/sec  %8.2f%% rel.',
      [ANumGPU, AMethod,switch(AIsCal,'CAL','CL'),BatchCount,dt,tflopsps,percent]));

    //summary table
    if Summary=nil then begin
      Summary:=TStringList.Create;
      Summary.Add('relPref'#9'CLx1'#9'CALx1'#9'CLx2'#9'CALx2')
    end;
    col:=(ANumGpu-1)*2+ord(AIsCal);
    s:=Summary.Values[AMethod];if s='' then s:=#9#9#9;
    SetListItem(s,col,format('%8.2f%',[percent]),#9);
    Summary.Values[AMethod]:=s;
  end;
end;

procedure TFrmMain.TestDumb(kclass:TKernelClass; numGpu:integer;asleep:boolean=false);
var i,j,b:integer;k:TArray<TKernel>;
    allDone:boolean;
begin
  setlength(k,numGpu);
  for j:=0 to high(k)do k[j]:=kclass.Create(j);

  for b:=0 to BatchCount-1 do begin
    BeginTest;
    for i:=0 to RunCount-1 do begin
      for j:=0 to high(k)do k[j].Start;
      if asleep then sleep(150);
      repeat
        allDone:=true;
        for j:=0 to high(k)do if k[j].Running then allDone:=false;
      until allDone;
    end;
    EndTest(kclass=TCalKernel,'Dumb'+switch(asleep,'Sleep'),b,numgpu);
  end;

  for j:=0 to high(k)do k[j].Free;
end;

procedure TFrmMain.TestQueue(kclass:TKernelClass; numGpu:integer;asleep:boolean=false);
var k:TArray<TKernel>;
    i,b:integer;
    allDone:boolean;
begin
  setlength(k,numGpu*RunCount);
  for i:=0 to high(k)do k[i]:=kclass.Create(i mod NumGpu);

  for b:=0 to BatchCount-1 do begin
    BeginTest;
    for i:=0 to high(k)do k[i].Start;
    repeat
      if asleep then sleep(20);
      allDone:=true;
      for i:=0 to high(k)do if k[i].Running then allDone:=false;
    until allDone;

    EndTest(kclass=TCalKernel,'Queue'+switch(asleep,'Sleep'),b,numgpu);
  end;

  for i:=0 to high(k)do k[i].Free;
end;

procedure TFrmMain.TestTwin(kclass:TKernelClass; numGpu:integer; AOnComplete:TProc=nil);
var i:integer;
begin
  OnTwinComplete:=AOnComplete;
  SetLength(twin,numGpu*2);
  for i:=0 to high(twin) do twin[i]:=kclass.Create(i shr 1);
  twinBatch:=0;
  twinQueue:=RunCount*Length(twin)shr 1; BeginTest; tTwinUpdate.Enabled:=true; tTwinUpdate.OnTimer(nil);
end;

procedure TFrmMain.TwinComplete;
var i:integer;
begin
  EndTest(twin[0].ClassType=TCalKernel,'Twin',twinBatch,Length(twin)shr 1);
  inc(twinBatch);

  if twinBatch<BatchCount then begin
    twinQueue:=RunCount*Length(twin)shr 1; BeginTest; tTwinUpdate.Enabled:=true; tTwinUpdate.OnTimer(nil);
  end else begin
    for i:=0 to high(twin)do freeandnil(twin[i]);

    if assigned(OnTwinComplete)then
      OnTwinComplete;
  end;
end;

procedure TFrmMain.tTwinUpdateTimer(Sender: TObject);
var i:integer;
    r,any:boolean;
begin
  timeLog('-------- TwinUpdateTimer begin');
  for i:=0 to high(twin) do begin
    if(twinQueue>0) and twin[i].Ready(twin[i xor 1],0.12)then begin
      timeLog('twin['+tostr(i)+'].start begin');
      twin[i].Start;
      dec(twinQueue);
      timeLog('twin['+tostr(i)+'].start done');
    end;
  end;

  //checkout
  any:=false;
  for i:=0 to high(twin)do begin
    timeLog('twin['+tostr(i)+'].running begin');
    r:=twin[i].Running;
    timeLog('twin['+tostr(i)+'].running end');
    if r then any:=true;
  end;

  //queue finished
  if(twinQueue=0)and not any then begin
    tTwinUpdate.Enabled:=false;

    timeLog('batch finished'); SaveLog('twin');

    TwinComplete;
  end;
  timeLog('-------- TwinUpdateTimer end');
end;

procedure TFrmMain.tStartupTimer(Sender: TObject);
var s:ansistring;
begin
  SetPriorityClass(GetCurrentProcess,REALTIME_PRIORITY_CLASS);

  tStartup.Enabled:=false;
  Memo1.Text:='Running tests...';
//  TestDumb(TCalKernel,1);
//  TestDumb(TClKernel ,1);
//  TestDumb(TCalKernel,2);
//  TestDumb(TClKernel ,2);

//  TestDumb(TCalKernel,1,true); //proves that sleep blocks
//  TestDumb(TClKernel ,1,true); //proves that sleep blocks

//  TestQueue(TCalKernel,1);
//  TestQueue(TClKernel ,1);
//  TestQueue(TCalKernel,2);
//  TestQueue(TClKernel ,2);

//  TestQueue(TCalKernel,1,true); //proves that sleep blocks
//  TestQueue(TClKernel ,1,true); //proves that sleep blocks

//  TestTwin(TCalKernel,1,procedure begin
//  TestTwin(TClKernel ,1,procedure begin
//  TestTwin(TCalKernel,2,procedure begin
  TestTwin(TClKernel ,1,procedure begin
    //final summary
    s:=ReplaceF('=',#9,Summary.Text,[roAll]);Log(s);
  end){end)end)end)};
end;

end.
