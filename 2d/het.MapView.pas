unit Het.MapView;//het.objects

interface

uses
  Windows, SysUtils, Classes, Controls, Graphics, SyncObjs, math, het.Utils,
  hetJpeg2, het.Http, het.Gfx, het.Arrays, het.CoordSys, UVector, UMatrix;

const
  MapCacheSize=256;
  MapQueueSize=4;

const
  mlBingRoad=0;
  mlBingAerial=1;
  mlOpenStreet=2;
  mlMandelbrot=3;

type
  TMapTileState=
    (stEmpty,     //alapallapot
     stLoading,   //thread eppen tolti
     stLoaded    //thread betoltotte
    );

  TMapTileId=packed record
    FId:int64;
    function MaxZoom:integer;inline;
    function X:integer;inline;
    function Y:integer;inline;
    function Zoom:integer;inline;
    function Layer:integer;inline;
    procedure Encode(const AX,AY,AZoom,ALayer:integer);
    function ZoomOutId:TMapTileId;
    function HierarchyId:ansistring;
    function ServerId:integer;
    function URL:ansistring;

    function Dump:AnsiString;
  end;

  TMapTile=record
    Id:TMapTileId;
    TileIndex:integer;
    Bitmap:TBitmap;//autoFree
    Texture:TObject;//autoFree
    State:TMapTileState;
    Notify:THetArray<TControl>;
    Accessed:integer;
    function Dump:ansistring;
    procedure FreeTile;
  end;

  PMapTile=^TMapTile;

  TDrawMapTileProc=procedure(const Tile:PMapTile;const RSrc,RDst:TRect)of object;

type
  TMapTileCache=class;

  TMapTileDownloader=class(TThread)
  private
    FOwner:TMapTileCache;
    FQueue:THetArray<TMapTileId>;
    FCritSec:TCriticalSection;
    FQueueLength:integer;//threadsafe
  public
    function AddQueue(const ATileId:TMapTileId):boolean;//ha false, akkor queue is full
    procedure MoveUp(const ATileId:TMapTileId);
    procedure Execute;override;
    constructor Create(AOwner:TMapTileCache);
    destructor Destroy;override;
  public
    _body:ansistring;
    _ABitmap:TBitmap;
    _FileName:ansistring;
    _FileData:RawByteString;
    procedure DecodeTJpegImage;
  end;

  TMapTileRect=record bmp:TBitmap;rect:TRect end;
  TMapTileCache=class(TComponent)
  private
    FTiles:array[0..MapCacheSize-1]of TMapTile;
    FCritSec:TCriticalSection;
    FCachePath:ansistring;
    FDownloaders:array[0..7]of TMapTileDownloader;
    procedure TileDownloaded(const AId:TMapTileId;var ABitmap:TBitmap);//thread calls it
  public
    constructor Create(AOwner:TComponent);override;
    destructor Destroy;override;
    function GetTile(const AId:TMapTileId;const AControl:TControl=nil;const ARect:PRect=nil):PMapTile;
    function GetTileBmp(const AId:TMapTileId;const AControl:TControl=nil;const ARect:PRect=nil):TBitmap;
    property CachePath:ansistring read FCachePath write FCachePath;
    function Dump:ansistring;
  end;

  TMapView=class(TComponent)
  private
    FMapTileCache:TMapTileCache;//reference only, not owned
    FMapLayer:integer;
    FCenter:TCoordinate;
    FTurn,FZoom:double;
    FSmoothCenter:TCoordinate;
    FSmoothTurn,FSmoothZoom:double;
    FMatrix,FInvMatrix:TM44D;
    lastTime:int64;
    FClientRect:TRect;
    FCoordSys:TCoordSys;

    FOnIdle:TOnIdle;

    procedure SetMapTileCache(const Value:TMapTileCache);
    procedure SetMapLayer(const Value:integer);
    procedure SetCenter(const Value: TCoordinate);
    procedure SetTurn(const Value: double);
    procedure SetZoom(const Value: double);
    function GetSmooth:boolean;
    procedure SetSmooth(const Value:Boolean);
    procedure SetCoordSys(const Value:TCoordSys);

    procedure Changed;

  protected
    procedure DoDraw(const DrawMapTileProc:TDrawMapTileProc);
  private
    _Canvas:TCanvas;
    procedure DrawGDITile(const Tile:PMapTile;const RSrc,RDst:TRect);
  public
    procedure GDIDraw(const ACanvas:TCanvas);
    constructor Create(AOwner:TComponent);override;
    property MapLayer:integer read FMapLayer write SetMapLayer;
    property MapTileCache:TMapTileCache read FMapTileCache write SetMapTileCache;
    property Center:TCoordinate read FCenter write SetCenter;
    property Zoom:double read FZoom write SetZoom;
    property Turn:double read FTurn write SetTurn;
    property ClientRect:TRect read FClientRect;
    property Smooth:Boolean read GetSmooth write SetSmooth;
    property CoordSys:TCoordSys read FCoordSys write SetCoordSys;
    function Update:boolean;

    function ScreenToWorld(const s:TPoint):TCoordinate;
    function ScreenToWorldD(const s:TPoint):TV2D;
    function WorldToScreen(const w:TCoordinate):TPoint;overload;
    function WorldToScreenF(const w:TCoordinate):TV2f;overload;
    function WorldToScreen(const w:TV2D):TPoint;overload;
    function WorldToScreenF(const w:TV2D):TV2f;overload;

    procedure AdjustZoom(const amount:single);
    procedure AdjustTurn(const amount:single);
    procedure AdjustCenter(const c:TCoordinate);overload;
    procedure AdjustCenter(const p:TPoint);overload;
    procedure Scroll(const c:TCoordinate);overload;
    procedure Scroll(const p:TPoint);overload;

    procedure SetClientRect(const Value: TRect);
  end;

//debug stuff


implementation

uses
  het.FileSys;

var _tick:integer=0;

function GetTick:integer;inline;
begin
  result:=_tick;
  inc(_tick);
end;

var mandelpal:array of integer;

function CalcMandelbrotTile(const AId:TMapTileId):TBitmap;
type MandelFloat=double;

  function calc2d(const x0,y0:MandelFloat):integer;
  var x,y,xx,yy,xy:MandelFloat;
      iteration:integer;
  const max_iteration=1000;
  begin
    iteration:=0;
    xx:=0;yy:=0;xy:=0;
    repeat
      x:=xx-yy+x0;
      y:=xy+xy+y0;
      xx:=x*x;yy:=y*y;xy:=x*y;
      inc(iteration);
    until (xx+yy>4)or(iteration>=max_iteration);

    if iteration=max_iteration then result:=0
                               else result:=mandelPal[iteration];
  end;

  function calc3d(const x0,y0,z0:MandelFloat):integer;

    procedure SinCos(const Theta: double; var Sin, Cos: double);
    asm
            FLD     Theta
            FSINCOS
            FSTP    qword ptr [edx]    // Cos
            FSTP    qword ptr [eax]    // Sin
            FWAIT
    end;

  var r,thetaN,phiN,x,y,z,rn,xx,yy,zz:MandelFloat;
      SinThetaN,SinPhiN,CosThetaN,CosPhiN:MandelFloat;
      i:integer;
  const maxIter=100;
        n=8;
  begin
    x:=0;y:=0;z:=0;r:=0;xx:=0;yy:=0;
    i:=0;
    repeat
      thetaN:= arctan2(sqrt(xx + yy) , z)*n;
      phiN := arctan2(y,x)*n;

      rn:=power(r,n*0.5);

      SinCos(ThetaN,SinThetaN,CosThetaN);
      SinCos(PhiN,SinPhiN,CosPhiN);

      x := rn * sinthetaN * cosphiN + x0;
      y := rn * sinthetaN * sinphiN + y0;
      z := rn * costhetaN + z0;

      xx:=x*x;yy:=y*y;zz:=z*z;
      r:=xx + yy + zz;
      inc(i);
    until (r>8) or(i>=maxiter);
    if i=maxiter then result:=0
                    else result:=mandelPal[i];
  end;


var x0,y0,xx,yy,step:MandelFloat;
    x,y,i:integer;
    p:pinteger;
begin
  result:=TBitmap.CreateNew(pf32bit,256,256);

  if length(mandelPal)=0 then begin
    setlength(mandelPal,2000);
    for i:=0 to high(mandelpal)do mandelpal[i]:=rgb(
                               round(cos(i*0.0612567+1)*127+127),
                               round(sin(i*0.072321)*127+127),
                               round(cos(i*0.0839894+2)*127+127));
  end;

  step:=1/power(2,AId.Zoom);
  x0:=AId.X*step;
  y0:=AId.Y*step;
  step:=step*(1/256);

{  x0:=(x0-0.7)*3;
  y0:=(y0-0.5)*3;
  step:=step*3;}

  yy:=y0;
  for y:=0 to 255 do begin
    p:=result.scanline[y];
    xx:=x0;
    for x:=0 to 255 do begin
      p^:=calc2d(xx,yy);
      xx:=xx+step;
      inc(p);
    end;
    yy:=yy+step;
  end;

  result.PixelFormat:=pf24bit;
//  result.Canvas.TextOut(0,0,tostr(AId.Zoom)+', '+tostr(AId.X)+', '+tostr(AId.Y));
end;

{ TMapTileId }

function TMapTileId.MaxZoom:integer;
begin result:=28;end;

function TMapTileId.X:integer;     begin result:=FId        and $FFFFFFF end;
function TMapTileId.Y:integer;     begin result:=FId shr 28 and $FFFFFFF end;
function TMapTileId.Zoom:integer;  begin result:=PByte   (psucc(@FId,7))^and 31             end;
function TMapTileId.Layer:integer; begin result:=PByte   (psucc(@FId,7))^shr 5              end;

procedure TMapTileId.Encode(const AX,AY,AZoom,ALayer:integer);
var mask:integer;
begin
  mask:=1 shl EnsureRange(AZoom,0,MaxZoom)-1;;
  FId:=(ax and mask)+int64(ay and mask)shl 28;
  PByte   (psucc(@FId,7))^:=AZoom and 31+ALayer shl 5;
end;

function TMapTileId.ZoomOutId:TMapTileId;
begin
  result.Encode(X shr 1,Y shr 1,max(0,Zoom-1),Layer);
end;

function TMapTileId.HierarchyId:ansistring;
var i,lx,ly,lz:integer;
begin
  lx:=x;ly:=y;lz:=EnsureRange(zoom,0,MaxZoom);
  setlength(result,lz);
  for i:=1 to length(result)do begin
    dec(lz);
    result[i]:=ansichar(ord('0')+(lx shr lz)and 1+(ly shr lz)and 1 shl 1);
  end;
end;

function TMapTileId.ServerId:integer;
begin
  //result:=x and 3 xor y and 3 shl 1;
//  result:=x and 1+y and 3 shl 1;//old veartrh

  result:=x and 1+y and 1 shl 1;
end;

function TMapTileId.URL:ansistring;
var sid,hid:ansistring;
begin
  sid:=ansichar(ord('0')+ServerId);
  hid:=HierarchyId;
  case Layer of
{    mlBingRoad          :result:='http://ecn.t'++'.tiles.virtualearth.net/tiles/r'+HierarchyId+'.jpeg?g=426&mkt=en-us&shading=hill&n=z';
    mlBingAerial        :result:='http://ecn.t'+ansichar(ord('0')+ServerId)+'.tiles.virtualearth.net/tiles/h'+HierarchyId+'.jpeg?g=426&mkt=en-us&n=z';
    mlBingAerialNoLabels:result:='http://ecn.t'+ansichar(ord('0')+ServerId)+'.tiles.virtualearth.net/tiles/a'+HierarchyId+'.jpeg?g=426&mkt=en-us&n=z';}
    mlBingRoad:            result:='http://r'+sid+'.ortho.tiles.virtualearth.net/tiles/r'+hid+'.png?g=203';
    mlBingAerial:          result:='http://h'+sid+'.ortho.tiles.virtualearth.net/tiles/h'+hid+'.jpeg?g=203';
    mlOpenStreet:          result:='http://tile.openstreetmap.org/'+tostr(Zoom)+'/'+tostr(x)+'/'+tostr(y)+'.png';
  else
    result:='';
  end;
end;

function TMapTileId.Dump:AnsiString;
begin
  result:=format('L:%d X:%d Y:%d Z:%d',[layer,x,y,zoom]);
end;

procedure TMapTile.FreeTile;
begin
  FreeAndNil(Bitmap);
  FreeAndNil(Texture);
end;

function TMapTile.Dump:ansistring;
begin
  result:=tostr(ord(State))+' '+tostr(id.Dump)+' '+switch(Bitmap=nil,'b:nil','b:ok');
end;

{ TMapTileDownloader }

function TMapTileDownloader.AddQueue(const ATileId: TMapTileId):boolean;
begin
  result:=FQueueLength<MapQueueSize;
  if not Result then exit;

  FCritSec.Enter;
  try
    FQueue.Append(ATileId);
    FQueueLength:=FQueue.Count;
  finally
    FCritSec.Leave;
  end;
end;

procedure TMapTileDownloader.MoveUp(const ATileId: TMapTileId);
var i:integer;
begin
  FCritSec.Enter;
  try
    with FQueue do for i:=Count-1 downto 0 do
      if FItems[i].FId=ATileId.FId then begin
        Move(i,FCount-1);
        break;
      end;
  finally
    FCritSec.Leave;
  end;
end;

constructor TMapTileDownloader.Create(AOwner: TMapTileCache);
begin
  FOwner:=AOwner;
  FCritSec:=TCriticalSection.Create;
  inherited Create(false);
end;

destructor TMapTileDownloader.Destroy;
begin
  FreeAndNil(FCritSec);
  inherited;
end;

procedure TMapTileDownloader.Execute;

  function GetId:TMapTileId;
  var FileName:ansistring;
      i,idx:integer;
  begin
    FCritSec.Enter;
    try
      idx:=FQueue.Count-1;
      for i:=FQueue.Count-1 downto 0 do begin
        FileName:=FOwner.CachePath+IntToHex(FQueue.FItems[i].FId,16);
        if FileExists(FileName)then begin idx:=i;break end;
      end;

      if idx>=0 then begin
        result:=FQueue.FItems[idx];
        FQueue.Remove(idx);
        FQueueLength:=FQueue.Count;
      end else
        result.FId:=-1;

    finally
      FCritSec.Leave;
    end;
  end;

var ActId:TMapTileId;
    FileName,ActUrl:ansistring;
    ActBitmap:TBitmap;

//    mask,sysmask:cardinal;
begin
  inherited;

  //1st core is free
{  GetProcessAffinityMask(GetCurrentProcess,mask,SysMask);
  mask:=sysmask and not 1;
  if mask<>0 then
    SetThreadAffinityMask(GetCurrentThread,mask);}

  while not Terminated do begin
    ActId:=GetId;ActBitmap:=nil;
    if ActId.FId<>-1 then begin
      FileName:=FOwner.CachePath+IntToHex(ActId.FId,16);

      if (FOwner.CachePath<>'')and FileExists(FileName)then begin
        try
          ActBitmap:=TBitmap.CreateNew(pf24bit,256,256);
          hjpDecode(ActBitmap,TFile(FileName));
          FOwner.TileDownloaded(ActId,ActBitmap);
          ActBitmap:=nil;
        except
          FreeAndNil(ActBitmap);
        end;
      end else begin
        case ActId.Layer of
          mlBingRoad,mlBingAerial,mlOpenStreet:begin
            ActUrl:=ActId.URL;
            with httpGet(ActUrl,
              procedure(st:ansistring;act,max:integer;var abort:boolean)
              begin
                if Terminated then Abort:=true;
              end)
            do if(ResponseCode=200)and(body<>'')then begin
              ActBitmap:=TBitmap.Create;

              _body:=body;_ABitmap:=ActBitmap;
              Synchronize(DecodeTJpegImage);//gahh TJpegImage is not thrd safe

              ActBitmap:=_ABitmap;
            end else begin
              if ResponseCode=400 then begin
{                ActBitmap:=TBitmap.CreateNew(pf24bit,256,256);
                ActBitmap.Canvas.TextRect(rect(0,0,256,256),0,0,Body);}
              end;
              safelogEnabled:=true;
              safelog(acturl+' -> '+body+' '+tostr(responsecode));
            end;
          end;
          mlMandelbrot:begin
            ActBitmap:=CalcMandelbrotTile(ActId);
          end;
        end;

        if(ActBitmap<>nil)and(ActBitmap.Width=256)and(ActBitmap.Height=256)then begin
          ActBitmap.PixelFormat:=pf24bit;

          FOwner.TileDownloaded(ActId,ActBitmap);

          if(ActBitmap<>nil)and(FOwner.CachePath<>'')then begin
            try TFile(FileName).Write(hjpEncode(ActBitmap,85,true,false));except end;
          end;

        end else begin
          FreeAndNil(ActBitmap);
          FOwner.TileDownloaded(ActId,ActBitmap);
        end;

      end;

    end else
      sleep(15);
  end;

end;

procedure TMapTileDownloader.DecodeTJpegImage;
begin
  try _ABitmap.LoadFromStr(_body);except FreeAndNil(_ABitmap)end;
end;

{ TMapTileCache }

constructor TMapTileCache.Create(AOwner: TComponent);
var i:integer;
begin
  inherited;
  FCritSec:=TCriticalSection.Create;

  for i:=0 to high(FTiles)do
    FTiles[i].TileIndex:=i;

  for i:=0 to high(FDownloaders)do
    FDownloaders[i]:=TMapTileDownloader.Create(self);
end;

destructor TMapTileCache.Destroy;
var i:integer;
begin
  for i:=0 to high(FDownloaders)do
    FDownloaders[i].Terminate;
  for i:=0 to high(FDownloaders)do begin
    FDownloaders[i].Waitfor;
    FreeAndNil(FDownloaders[i]);
  end;

  for i:=0 to high(FTiles)do
    FTiles[i].FreeTile;

  FreeAndNil(FCritSec);
  inherited;
end;

function TMapTileCache.GetTile(const AId:TMapTileId;const AControl:TControl=nil;const ARect:PRect=nil):PMapTile;
var i,idx,newIdx,x,y:integer;
    minTime:integer;
    Id2:TMapTileId;
begin
  result:=nil;
  if AId.Zoom<=AId.MaxZoom then begin
    FCritSec.Enter;
    try
      idx:=-1;newIdx:=-1;minTime:=low(integer);
      for i:=0 to high(FTiles)do with FTiles[i]do begin
        //if found then break
        if Id.FId=AId.FId then begin
          idx:=i;
          break;
        end;
        //otherwise select oldest accessed
        if(State<>stLoading)and((Accessed<minTime)or(newIdx<0))then begin
          newIdx:=i;
          minTime:=Accessed;
        end;
      end;

      if(idx<0)and(newIdx>=0)and(FDownloaders[AId.ServerId].AddQueue(AId))then begin//if not found
        idx:=newIdx;
        with FTiles[idx]do begin
          FreeTile;
          State:=stLoading;
          Id:=AId;
        end;
      end;

      if idx>=0 then with FTiles[idx]do begin
        Accessed:=GetTick;
        FDownloaders[Id.ServerId].MoveUp(Id);
        if(state=stLoading)and(AControl<>nil)then begin
          Notify.InsertBinary(AControl,function(const a,b:TControl):integer begin result:=integer(a)-integer(b)end,false);
        end;
        result:=@FTiles[idx];
      end;

    finally
      FCritSec.Leave;
    end;
  end;

  if ARect<>nil then begin
    ARect^:=rect(0,0,256,256);

    Id2:=AId;
    while((result=nil)or(result.Bitmap=nil))and(Id2.Zoom>0)do begin
      x:=Id2.X and 1 shl 7;
      y:=Id2.Y and 1 shl 7;
      with ARect^ do begin
        Left:=Left shr 1+x;Right:=Right shr 1+x;
        Top:=Top shr 1+y;Bottom:=Bottom shr 1+y;
      end;
      Id2:=Id2.ZoomOutId;
      result:=GetTile(Id2,AControl);
    end;
  end;
end;

function TMapTileCache.GetTileBmp(const AId:TMapTileId;const AControl:TControl=nil;const ARect:PRect=nil):TBitmap;
var tile:PMapTile;
begin
  tile:=GetTile(AId,AControl,ARect);
  if tile<>nil then result:=tile.Bitmap
               else result:=nil;
end;

function TMapTileCache.Dump:ansistring;
var i,loading:integer;
begin
  loading:=0;for i:=0 to high(FTiles)do if FTiles[i].State=stLoading then inc(loading);
  result:='MTC: '+Format('%4d/%4d ',[loading,length(FTiles)]);
  for i:=0 to high(FDownloaders)do
    result:=result+Format('%3d',[FDownloaders[i].FQueueLength]);

{  for i:=0 to high(FTiles)do
    result:=result+#13#10+FTiles[i].Dump;}
end;

procedure TMapTileCache.TileDownloaded(const AId: TMapTileId; var ABitmap: TBitmap);
var i:integer;
begin
  FCritSec.Enter;
  try
    for i:=0 to high(FTiles)do with FTiles[i] do if Id.FId=AId.FId then begin
      Accessed:=GetTick;
      Bitmap:=ABitmap;
      if Bitmap=nil then State:=stEmpty
                    else State:=stLoaded;
      Notify.ForEach(procedure(const a:TControl)begin a.Invalidate end);
      Notify.Clear;
      exit;
    end;
    //not found, just free the bimtap
    FreeAndNil(ABitmap);
  finally
    FCritSec.Leave;
  end;
end;

{ TMapViewTransform }

constructor TMapView.create(AOwner:TComponent);
begin
  inherited Create(AOwner);
  FCoordSys:=csMRCtile;
  FCenter:=coord(FCoordSys,V2D(0,0));
end;

procedure TMapView.SetMapLayer(const Value: integer);
begin
  if FMapLayer=Value then exit;
  FMapLayer:=Value;
  Changed;
end;

procedure TMapView.SetMapTileCache(const Value: TMapTileCache);
begin
  if FMapTileCache=Value then exit;
  FMapTileCache:=Value;
  Changed;
end;

procedure TMapView.SetCenter(const Value: TCoordinate);
begin
  if FCenter=Value then exit;
  FCenter:=Value.Convert(CoordSys);
  Changed;
end;

procedure TMapView.SetClientRect(const Value: TRect);
begin
  if EqualRect(FClientRect,Value) then exit;
  FClientRect := Value;Changed;
end;

function TMapView.GetSmooth: boolean;
begin
  result:=Assigned(FOnIdle);
end;

procedure TMapView.SetCoordSys(const value:TCoordSys);
begin
  if CoordSys=Value then exit;
  FCoordSys:=Value;
  FCenter.System:=Value;
  FSmoothCenter.System:=Value;
  changed;
end;

procedure TMapView.SetSmooth(const Value: Boolean);
begin
  if Value=GetSmooth then exit;
  if Value then FOnIdle:=OnIdle(self,procedure(var done:boolean) begin done:=not Update end)
           else FreeAndNil(FOnIdle);
end;

procedure TMapView.SetTurn(const Value: double);
begin
  if FTurn=Value then exit;
  FTurn:=Value;Changed;
end;

procedure TMapView.SetZoom(const Value: double);
begin
  if FZoom=Value then exit;
  FZoom:=Value;Changed;
end;

function TMapView.Update:boolean;
var acttime,freq:int64;
    dt:double;

  procedure MakeMatrices;
  var Scale:double;
  begin
    Scale:=256*power(2,FSmoothZoom);

    FMatrix:=M44dIdentity;
    MTranslate(FMatrix,V3D(-FSmoothCenter.Coord.V[0],-FSmoothCenter.Coord.V[1],0));
    MScale(FMatrix,Scale);
    MRotateZ(FMatrix,FSmoothTurn);

    with FClientRect do MTranslate(FMatrix,V3D((Right+Left)*0.5,(Bottom+Top)*0.5,0));

    FInvMatrix:=MInverse(FMatrix);

  end;

var r:trect;
    rectChanged:boolean;
begin
  if Assigned(Owner)and(Owner is TControl)then r:=TControl(Owner).ClientRect
                                          else r:=FClientRect;
  rectChanged:=not EqualRect(FClientRect,r);
  if rectChanged then FClientRect:=r;

  FCenter.System:=CoordSys;
  FSmoothCenter.System:=CoordSys;

  QueryPerformanceCounter(actTime);
  QueryPerformanceFrequency(freq);
  if lastTime=0 then dt:=1 else dt:=(acttime-lasttime)/freq;

  if Smooth then begin
    lastTime:=acttime;
    dt:=sqrt(dt){+0.05};
    if dt>1 then dt:=1;
    FSmoothZoom:=lerp(FZoom,FSmoothZoom,1-dt);
    FSmoothTurn:=lerp(FTurn,FSmoothTurn,1-dt);
    FSmoothCenter.Coord:=VLerp(FSmoothCenter.Coord,FCenter.Coord,dt);
  end else begin
    FSmoothCenter:=FCenter;
    FSmoothZoom:=FZoom;
    FSmoothTurn:=FTurn;
  end;

  MakeMatrices;

  result:=(abs(FSmoothZoom-FZoom)>0.001)or(abs(FSmoothTurn-FTurn)>0.001)or(VDist(FSmoothCenter.Coord,FCenter.Coord)>0.001/Power(2,FSmoothZoom));

  result:=result or not smooth or rectChanged;
  if result then begin
    if Assigned(Owner)and(Owner is TControl)then
      try TControl(Owner).Invalidate;except end;
  end;
end;

procedure TMapView.AdjustCenter(const c: TCoordinate);
begin
  Center:=Center+c;
end;

procedure TMapView.AdjustCenter(const p: TPoint);
begin
  if(p.X=0)and(p.Y=0)then exit;
  AdjustCenter(Coord(CoordSys,V2D(FInvMatrix[0,0],FInvMatrix[0,1])*p.x+
                              V2D(FInvMatrix[1,0],FInvMatrix[1,1])*p.y));
end;

procedure TMapView.Scroll(const c: TCoordinate);
begin
  Center:=Center-c;
end;

procedure TMapView.Scroll(const p: TPoint);
begin
  if(p.X=0)and(p.Y=0)then exit;
  Scroll(Coord(CoordSys,V2D(FInvMatrix[0,0],FInvMatrix[0,1])*p.x+
                        V2D(FInvMatrix[1,0],FInvMatrix[1,1])*p.y));
end;

procedure TMapView.AdjustTurn(const amount: single);
begin
  Turn:=Turn+amount;
end;

procedure TMapView.AdjustZoom(const amount: single);
begin
  Zoom:=Zoom+amount;
end;

procedure TMapView.Changed;
begin
  Update;
end;

function TMapView.ScreenToWorld(const s:TPoint):TCoordinate;
var v:TV3D;
begin
  v:=VTransform(FInvMatrix,V3D(s.X,s.Y,0));
  result:=Coord(CoordSys,V2D(v.V[0],v.V[1]));
end;

function TMapView.ScreenToWorldD(const s:TPoint):TV2D;
var v:TV3D;
begin
  v:=VTransform(FInvMatrix,V3D(s.X,s.Y,0));
  result.V[0]:=v.V[0];
  result.V[1]:=v.V[1];
end;

function TMapView.WorldToScreen(const w: TCoordinate): TPoint;
var s:TV3D;
begin
  if w.System=CoordSys then with w.coord do s:=VTransform(FMatrix,V3D(v[0],v[1],0))
                       else with w.Convert(CoordSys).Coord do s:=VTransform(FMatrix,V3D(v[0],v[1],0));
  result.x:=round(s.v[0]);
  result.y:=round(s.v[1]);
end;

function TMapView.WorldToScreenF(const w: TCoordinate): TV2F;
var s:TV3D;
begin
  if w.System=CoordSys then with w.coord do s:=VTransform(FMatrix,V3D(v[0],v[1],0))
                       else with w.Convert(CoordSys).Coord do s:=VTransform(FMatrix,V3D(v[0],v[1],0));
  result.v[0]:=s.v[0];
  result.v[1]:=s.V[1];
end;

function TMapView.WorldToScreen(const w: TV2D): TPoint;
var s:TV3D;
begin
  with w do s:=VTransform(FMatrix,V3D(v[0],v[1],0));
  result.x:=round(s.v[0]);
  result.y:=round(s.v[1]);
end;

function TMapView.WorldToScreenF(const w: TV2D): TV2F;
var s:TV3D;
begin
  with w do s:=VTransform(FMatrix,V3D(v[0],v[1],0));
  result.v[0]:=s.v[0];
  result.v[1]:=s.V[1];
end;

procedure TMapView.DoDraw(const DrawMapTileProc:TDrawMapTileProc);
var x,y:integer;
    gzoom:integer;
    gzoomscale,invgzoomScale:double;
    corner:array[0..3]of TV2d;
    v:array[0..3]of TV2f;
    wTopLeft,wBottomRight:TV2d;
    rTile,rSrc,rDst:TRect;
    Id:TMapTileId;
    ctrl:TControl;
    tile:PMapTile;
begin
  gzoom:=EnsureRange(round(FSmoothZoom),1,28);

  gzoomscale:=power(2,gzoom);
  invgzoomScale:=1/gzoomScale;

  with FClientRect do begin
    corner[0]:=ScreenToWorld(FClientRect.TopLeft);
    corner[1]:=ScreenToWorld(point(Right,Top));
    corner[2]:=ScreenToWorld(point(Left,Bottom));
    corner[3]:=ScreenToWorld(FClientRect.BottomRight);
  end;

  wTopLeft    :=VMin(VMin(corner[0],corner[1]),VMin(corner[2],corner[3]));
  wBottomRight:=VMax(VMax(corner[0],corner[1]),VMax(corner[2],corner[3]));

  rtile:=rect({max(}floor(gzoomscale*wtopleft.v[0]){,0)},
              {max(}floor(gzoomscale*wtopleft.v[1]){,0)},
              {min(}floor(gzoomscale*wbottomright.v[0]){,round(gzoomscale-1))},
              {min(}floor(gzoomscale*wbottomright.v[1]){,round(gzoomscale-1))});

  if Assigned(Owner)and(Owner is TControl)then ctrl:=TControl(Owner)else ctrl:=nil;
  for y:=rtile.top to rtile.bottom do begin
    for x:=rtile.left to rtile.right do begin
      Id.Encode(x,y,gzoom,ord(MapLayer));

      if(MapTileCache<>nil)and((x>=0)and(y>=0)and(x<gzoomscale)and(y<gzoomscale))then
        tile:=MapTileCache.GetTile(id,ctrl,@rSrc)
      else
        tile:=nil;

      v[0]:=WorldToScreenF(V2D(x*invgzoomScale,y*invgzoomScale));
      v[1]:=WorldToScreenF(V2D(x*invgzoomScale,(y+1)*invgzoomScale));
      v[2]:=WorldToScreenF(V2D((x+1)*invgzoomScale,y*invgzoomScale));
      v[3]:=WorldToScreenF(V2D((x+1)*invgzoomScale,(y+1)*invgzoomScale));

      rdst.TopLeft:=WorldToScreen(V2D(x*invgzoomScale,y*invgzoomScale));
      rdst.BottomRight:=WorldToScreen(V2D((x+1)*invgzoomScale,(y+1)*invgzoomScale));

      DrawMapTileProc(tile,rSrc,rDst);
    end;
  end;
end;

procedure TMapView.DrawGDITile(const Tile:PMapTile;const RSrc,RDst:TRect);
begin with _Canvas do begin
  if(Tile<>nil)and(Tile.Bitmap<>nil)then begin
    SetStretchBltMode(_Canvas.Handle,{HALFTONE}COLORONCOLOR);
    CopyRect(rdst,Tile.Bitmap.canvas,rsrc);
  end else
    FillRect(rdst);

{  DrawFocusRect(rdst);
  if tile<>nil then s:=tile.dump else s:='nil';
  TextOut(rdst.Left,RDst.Top,s);}
end;end;

procedure TMapView.GDIDraw(const ACanvas: TCanvas);
begin
  _Canvas:=ACanvas;
  _Canvas.SetBrush(bsSolid,RGB(20,15,50));
  DoDraw(DrawGDITile);
end;

initialization
finalization
end.
