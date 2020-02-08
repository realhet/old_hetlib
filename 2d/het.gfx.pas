unit het.Gfx;
interface

uses windows, types, sysutils,math, classes, graphics, forms,
  het.utils, het.Arrays, UMatrix, udxtc, UVector;

{TODO: .tif files}
const
  BitmapArrayLoadImageExtensions:AnsiString='.tga;.bmp;.dds;.png;.hjp;.jpg;.ace;.gif';

type
  TBitmapArray=array of TBitmap;

type
  TResizeFilter=(rfNearest,rfLinear,rfNearestMipmapLinear,rfLinearMipmapLinear);

  TPixelOpFunct1=reference to function(a:cardinal):cardinal;
  TPixelOpFunct2=reference to function(a,b:cardinal):cardinal;

const
  _DefaultResizeFilter=rfNearest;
  _DefaultQuality=85;
  _DefaultYUV=true;

type
  THetBitmap=class helper for TBitmap
  private
//    function MotionEstimate(const ATarget: TBitmap): TArray<TSmallPoint>;
  public
    constructor CreateFromFile(const AFileName:string);
    constructor CreateNew(const APixelFormat:TPixelFormat;const AWidth,AHeight:integer);
    constructor CreateProcedural(const APixelFormat:TPixelFormat;const AWidth,AHeight:integer;const funct:TPixelOpFunct2);
    constructor CreateClone(const ASrc:TBitmap);
    constructor CreateFromStr(const data:RawByteString);
    constructor CreateFromPicture(const APicture:TPicture);
    constructor CreateFromData(const AData; const AWidth, AHeight, ABitCount: integer);

    procedure LoadFromData(const AData; const AWidth, AHeight, ABitCount: integer);
    procedure SaveToData(var AData);

    procedure LoadFromStream2(const st:TStream);
    procedure SaveToStream2(const st:TStream;const Extension:ansistring;const Quality:integer=_DefaultQuality;const YUV:boolean=_DefaultYUV);

    procedure LoadFromFile2(const fn:string);
    procedure SaveToFile2(const fn:string;const Quality:integer=_DefaultQuality;const YUV:boolean=_DefaultYUV);

    procedure LoadFromStr(const data:RawByteString);
    function SaveToStr(const Extension:ansistring;const Quality:integer=_DefaultQuality;const YUV:boolean=_DefaultYUV):RawByteString;

    function ImageRect:TRect;
    function Center:TPoint;
    function PixelSizeBits:integer;
    function PixelSize:integer;
    function ScanLineSize:integer;
    function Image:Pointer;
    function ImageSize:integer;
    function Empty:boolean;

    function CopyF:TBitmap;

    function ExpandF(const AWidth,AHeight:integer):TBitmap;
    procedure Expand(const AWidth,AHeight:integer);
    function Expand2NF:TBitmap;
    procedure Expand2N;
    function ExpandAlignedF(const Align:integer):TBitmap;
    procedure ExpandAligned(const Align:integer);

{    function ExpandBottomF(const AWidth,AHeight:integer):TBitmap;
    procedure ExpandBottom(const AWidth,AHeight:integer);
    function ExpandBottom2NF:TBitmap;
    procedure ExpandBottom2N;}

    function ResizeF(const AWidth,AHeight:integer;const ResizeFilter:TResizeFilter=_DefaultResizeFilter):TBitmap;
    procedure Resize(const AWidth,AHeight:integer;const ResizeFilter:TResizeFilter=_DefaultResizeFilter);
    function Resize2NF(const ResizeFilter:TResizeFilter=_DefaultResizeFilter):TBitmap;
    procedure Resize2N(const ResizeFilter:TResizeFilter=_DefaultResizeFilter);
    function ResizeHalveF(const ResizeFilter:TResizeFilter=_DefaultResizeFilter):TBitmap;
    procedure ResizeHalve(const ResizeFilter:TResizeFilter=_DefaultResizeFilter);
    function ResizeDoubleF(const ResizeFilter:TResizeFilter=_DefaultResizeFilter):TBitmap;
    procedure ResizeDouble(const ResizeFilter:TResizeFilter=_DefaultResizeFilter);
    function ResizeScaleF(const AScale:single;const ResizeFilter:TResizeFilter=_DefaultResizeFilter):TBitmap;
    procedure ResizeScale(const AScale:single;const ResizeFilter:TResizeFilter=_DefaultResizeFilter);
    function ResizeFitF(const AMaxWidth,AMaxHeight:integer;const AEnlarge:boolean;const ResizeFilter:TResizeFilter=_DefaultResizeFilter):TBitmap;
    procedure ResizeFit(const AMaxWidth,AMaxHeight:integer;const AEnlarge:boolean;const ResizeFilter:TResizeFilter=_DefaultResizeFilter);

    procedure LerpWith(const bmp:tbitmap;const t:single);
    function LerpWithF(const bmp:tbitmap;const t:single):TBitmap;

    function GrayScaleF:TBitmap;
    procedure GrayScale;

    function GrayScaleAlphaF:TBitmap;
    procedure GrayScaleAlpha;

    procedure PixelOp1(const Funct:TPixelOpFunct1;const range:TRect);overload;
    procedure PixelOp1(const Funct:TPixelOpFunct1);overload;
    procedure PixelOp2(const Src:TBitmap;const Funct:TPixelOpFunct2;const range:TRect);overload;
    procedure PixelOp2(const Src:TBitmap;const Funct:TPixelOpFunct2);overload;

    procedure SetAlphaChannel(const src: TBitmap);
    function GetAlphaChannel:TBitmap;

    procedure ColorTransform(const m: TM44f; const range: TRect);

    function getAsRaw:RawByteString;
    procedure setAsRaw(const raw:RawByteString);
    property AsRaw:RawByteString read getAsRaw write setAsRaw;

    procedure SwapRedBlue;

    procedure ChannelExtract(const ACfg: ansistring);
    function ChannelExtractF(const ACfg:ansistring):TBitmap;

    function AbsError(const other:TBitmap):single;
    function MSE(const other:TBitmap):single;
    function PSNR(const other:TBitmap):single;

  public
    function GetComponents:integer;
    procedure SetComponents(const value:integer);
    property Components:integer read GetComponents write SetComponents;

  public
    procedure DeinterlaceBobWeave(var Dst:tbitmap;const Frame:integer{0 or 1});
    procedure Diff8(var Ref,Diff:TBitmap);
    procedure Diff8Add(var Ref:TBitmap);
    procedure CopyTo(var Dst:TBitmap);
  public
    procedure HBlurAvg(const WindowSize:integer);
    procedure VBlurAvg(const WindowSize:integer);
    procedure BlurAvg(const WindowSize:integer);
  public
    function EqualDimensions(const b:TBitmap):boolean;

  public
    function GetPix(const x,y:integer):integer;
    procedure SetPix(const x,y,c:integer);
    property Pix[const x,y:integer]:integer read GetPix write SetPix;
    function GetPixClamped(const x,y:integer):integer;
    procedure SetPixClamped(const x,y,c:integer);
    property PixClamped[const x,y:integer]:integer read GetPixClamped write SetPixClamped;

    procedure PixelOpMin(const b:TBitmap);overload;
    procedure PixelOpMin(const b:TBitmap;const r:TRect);overload;
    procedure PixelOpMax(const b:TBitmap);overload;
    procedure PixelOpMax(const b:TBitmap;const r:TRect);overload;
    procedure PixelOpAvg(const b:TBitmap);overload;
    procedure PixelOpAvg(const b:TBitmap;const r:TRect);overload;
    procedure PixelOpAdd(const b:TBitmap);overload;
    procedure PixelOpAdd(const b:TBitmap;const r:TRect);overload;
    procedure PixelOpSub(const b:TBitmap);overload;
    procedure PixelOpSub(const b:TBitmap;const r:TRect);overload;

    function PixelSumX(const r:TRect):TArray<integer>;overload;
    function PixelSumX:TArray<integer>;overload;
    function PixelSumY(const r:TRect):TArray<integer>;overload;
    function PixelSumY:TArray<integer>;overload;
    function PixelSumXY(const r:TRect;out horz,vert:TArray<integer>):integer;overload;
    function PixelSumXY(out horz,vert:TArray<integer>):integer;overload;
    function PixelSum(const r:TRect):integer;overload;
    function PixelSum:integer;overload;

    function AlphaIsOne:boolean;

    function CropF(const r:TRect):TBitmap;
    procedure Crop(const r:TRect);

    function PixelOffset(const ATarget:TBitmap):tpoint;

    function MotionEstimate8x8(const ATarget:TBitmap):TArray<TSmallPoint>;

    procedure CalcBlueboxAlpha(const clrBGR,tolHue,tolSat,tolVal:integer);
    procedure VisualizeAlpha(const gradient:boolean=true);

    procedure Clear(const AColor:TColor);
    function CloneF:TBitmap;

    function BrightestPixelPos:TPoint;

    procedure FlipV;
    procedure FlipH;
  end;

function ErrorBitmap:TBitmap;
procedure BitmapArrayNormalize(var b:TBitmapArray);
function BitmapArrayDimensions(const b:TBitmapArray):integer;
function BitmapArrayValidate(const bmp:TBitmapArray):string;
function BitmapArrayLoad(const name:string;const normalize:boolean):TBitmapArray;
function BitmapArrayCalculateMipmap(var b:TBitmapArray;const PreserveOldBitmaps:boolean):boolean;
function BitmapArrayDxtEncode(const version:TDXTVersion;const b:TBitmapArray;const index:integer=0):TBytes;
function BitmapArrayConcatBytes(const b:TBitmapArray):TBytes;
procedure BitmapArrayFree(var b:TBitmapArray);

procedure ScreenShot(var Dst:TBitmap;const MonitorNum:integer=0);

function BGR2HSV(c:integer):integer;

//Glt stuff

type
  TGLTMapType=(         //no compression        compression enabled     storage jpegs
    mtColor_L,          //L                     DXT1_RGB                g
    mtColor_LA,         //LA                    DXTn_RGBA               gg
    mtColor_RGB,        //RGB                   DXT1_RGB                c
    mtColor_RGBA,       //RGBA                  DXTn_RGBA               cg
    mtExact_X,          //L                     L                       g
    mtExact_XW,         //LA                    LA                      gg
    mtExact_XYZ,        //RGB                   RGB                     ggg
    mtExact_XYZW,       //RGBA                  RGBA                    gggg
    mtNormal_UV,        //LA                    3dc vagy DXT5           gg
    mtNormal_UVH        //RGB                   RGB                     ggg
  );

  TGltAlphaType=(atBinary,atSharp,atGradient);

  TGltPreviewOptions=record
    width,height:integer;
    quality:byte;
  end;

const
  MapTypeComponents:array[TGLTMapType]of integer=(1,2,3,4,1,2,3,4,2,3);
  poNoPreview:TGltPreviewOptions=(width:0;height:0;quality:1);
  po64x64Preview:TGltPreviewOptions=(width:64;height:64;quality:35);

type
  TTextHAlign=(haAuto,haLeft,haCenter,haRight);
  TTextVAlign=(vaTop,vaCenter,vaBottom);
  TTextColors=record Bkg,Text,Shadow,Outline:TColor;procedure Clear;end;
  TDrawTextParams=record
    HAlign:TTextHAlign;
    VAlign:TTextVAlign;
    cText,
    cSelected:TTextColors;
    WordWrap:boolean;
    SelStart,SelLength:integer;
    procedure Clear;
  end;

  TBlurBuf=record
    inbuf:array of byte;
    bufp:integer;
    sum:integer;
    outbuf:array of byte;
    outbufp:integer;
    invInbufLength:single;
    procedure Reset(Size,ClearValue:byte);
    function Feed(value:integer):integer;
  end;

  TCanvasHelper=class helper for TCanvas
  public
    procedure SetBrush(const AStyle:TBrushStyle;const AColor:TColor=clWhite);inline;
    procedure SetPen(const AStyle:TPenStyle;const AColor:TColor=clBlack);inline;
    procedure TextOut(const P:TPoint;const Text:string);overload;inline;
    procedure MoveTo(const p:TPoint);overload;inline;
    procedure LineTo(const p:TPoint);overload;inline;
    procedure MoveTo(const p:TV2f);overload;inline;
    procedure LineTo(const p:TV2f);overload;inline;
    procedure Line(const x0,y0,x1,y1:integer);overload;inline;
    procedure Line(const p0,p1:TPoint);overload;inline;
    procedure Line(const p0,p1:TV2f);overload;inline;
    procedure FillRectOutside(const rInside,rOutside:TRect);
    procedure DrawRect(r:trect);
    procedure DrawTiled(const g: TGraphic; const r: TRect; const ofs: TPoint);
    procedure DotLine(x1,y1,x2,y2:integer;co:tcolor);//horizontal or vertical
    procedure DrawText(const AParams:TDrawTextParams;const ARect:TRect;const AText:ansistring;const ASyntax:ansistring='');
    procedure DrawGraph(const AOrigin,ADirection:TPoint;const AScale:single;const ASeries:TArray<integer>;const ARangeStart,ARangeEnd:integer);overload;
    procedure DrawGraph(const AOrigin,ADirection:TPoint;const AScale:single;const ASeries:TArray<integer>);overload;
  end;

  TGraphicHelper=class helper for TGraphic
  public
    function ToBitmap(const APixelFormat:TPixelFormat):TBitmap;
  end;

implementation

uses
  jpeg, dds, tga, mwace, pngImage, gltimage, hetjpeg2, gifimg;

function BGR2HSV(c:integer):integer;
var d,r,g,b:integer;ma,mi,hue,sat,val:integer;
begin
  r:=c shr 16 and $ff;
  g:=c shr 8 and $ff;
  b:=c and $ff;

  if g>b then begin
    ma:=g;mi:=b
  end else begin
    ma:=b;mi:=g;
  end;
  if r>ma then ma:=r else if r<mi then mi:=r;  //17.78

  if ma=mi then begin
    hue:=0;
  end else begin
    d:=ma-mi;
    if ma=r then begin    hue:=42*(g-b)div d;if hue<0 then hue:=hue+256
    end else if ma=g then hue:=42*(b-r)div d+84
                     else hue:=42*(r-g)div d+168;
  end;

  sat:=(ma-mi);//faster than original
  val:=ma;

  result:=cardinal(hue or sat shl 8 or val shl 16) or cardinal(c) and $FF000000;
end;


////////////////////////////////////////////////////////////////////////////////
// BitmapArray                                                                //
////////////////////////////////////////////////////////////////////////////////

function ErrorBitmap:TBitmap;
var p:pcardinal;
    x,y:integer;
begin
  Result:=TBitmap.Create;
  Result.PixelFormat:=pf32bit;
  result.Width:=64;
  result.Height:=64;
  for y:=0 to result.Height-1 do begin
    p:=Result.ScanLine[y];
    for x:=0 to Result.Width-1 do begin
      if((x xor y)and 8)=0 then p^:=$00ffffff
                           else p^:=$ffff00ff;
      inc(p);
    end;
  end;
  Result.PixelFormat:=pf24bit;
end;

function BitmapArrayDimensions(const b:TBitmapArray):integer;
begin
  case length(b) of
    0:result:=0;
    1:if b[0].Height=1 then result:=1
                       else result:=2;
    6:result:=6;
    else result:=3;
  end;
end;

function BitmapArrayValidate(const bmp:TBitmapArray):string;
var i:integer;
begin
  if length(bmp)=0 then exit('no bitmaps');
  for i:=0 to high(bmp)do if bmp[i]=nil then exit('nil bitmap');
  if bmp[0].Empty then exit('empty bitmap');
  if bmp[0].Width<>Nearest2NSize(bmp[0].Width)then exit('invalid width (2^n)');
  if bmp[0].Height<>Nearest2NSize(bmp[0].Height)then exit('invalid height (2^n)');
  if BitmapArrayDimensions(bmp)=0 then exit('invalid depth (2^n or 6)');

  for i:=1 to high(bmp)do begin
    if bmp[i].PixelFormat<>bmp[0].PixelFormat then exit('various pixelformats');
    if bmp[i].Width<>bmp[0].Width then exit('various widths');
    if bmp[i].Height<>bmp[0].Height then exit('various heights');
  end;
end;

procedure BitmapArrayNormalize(var b:TBitmapArray);
var i:integer;
    maxWidth,maxHeight:integer;
    maxPixelFormat:TPixelFormat;

    AllAlphasAreOne:boolean;
begin
  if length(b)=0 then exit;
  if(length(b)>1)and(length(b)<>6)then begin
    while length(b)<Nearest2NSize(length(b))do begin
      setlength(b,length(b)+1);b[high(b)]:=nil;
    end;
  end;

  for i:=0 to high(b)do begin
    if b[i]=nil then b[i]:=ErrorBitmap;
    if b[i].Empty then begin b[i].Free;b[i]:=ErrorBitmap end;
  end;

  MaxWidth:=b[0].Width;
  MaxHeight:=b[0].height;
  MaxPixelFormat:=b[0].PixelFormat;
  AllAlphasAreOne:=b[0].AlphaIsOne;
  for i:=1 to high(b)do begin
    MaxWidth:=Max(MaxWidth,b[i].Width);
    MaxHeight:=Max(MaxHeight,b[i].Height);
    if MaxPixelFormat<b[i].PixelFormat then
      MaxPixelFormat:=b[i].PixelFormat;
    if AllAlphasAreOne and not b[i].AlphaIsOne then
      AllAlphasAreOne:=false;
  end;
  MaxWidth:=Nearest2NSize(MaxWidth);
  MaxHeight:=Nearest2NSize(MaxHeight);
  if(maxPixelFormat=pf32bit)and AllAlphasAreOne then
    maxPixelFormat:=pf24bit;

  for i:=0 to high(b)do begin
    b[i].Resize(MaxWidth,MaxHeight,rfLinearMipmapLinear);
    b[i].PixelFormat:=MaxPixelFormat;
  end;
end;

function BitmapArrayLoad(const name:string;const normalize:boolean):TBitmapArray;

  function AddInFix(const fn:string;const infix:string):string;
  begin
    result:=ChangeFileExt(fn,'')+'$a'+ExtractFileExt(fn);
  end;

  function setPlane(const idx:integer;const base:ansistring;var res:TBitmapArray):boolean;
  var b,b2:tbitmap;fn:ansistring;
  begin
    fn:=FindFileExt(base,BitmapArrayLoadImageExtensions);
    if fn<>'' then begin
      b:=TBitmap.CreateFromFile(fn);
      result:=not b.Empty;
      if result then begin
        if(b.PixelFormat<>pf32bit)then begin
          fn:=FindFileExt(AddInFix(base,'$a'),BitmapArrayLoadImageExtensions);
          if fn<>'' then begin
            b2:=TBitmap.CreateFromFile(fn);
            if not b2.Empty then
              b.SetAlphaChannel(b2);
            b2.Free;
          end;
        end;

        while idx>=length(res)do begin
          setlength(res,length(res)+1);
          res[high(res)]:=nil;
        end;
        res[idx]:=b;

      end else
        b.Free;
    end else
      result:=false;
  end;

  var i:integer;
begin
  setlength(result,0);
  if SetPlane(0,name,result)then begin
    if normalize then BitmapArrayNormalize(result);
    exit;
  end;
  if SetPlane(0,AddInFix(name,'$0'),result)then begin
    for i:=1 to 255 do if not SetPlane(i,AddInfix(name,'$'+ansistring(inttostr(i))),result)then break;
    if normalize then BitmapArrayNormalize(result);
    exit;
  end;
  if SetPlane(0,AddInfix(name,'$px'),result)then begin
    SetPlane(1, AddInfix(name,'$nx'),result);
    SetPlane(2, AddInfix(name,'$py'),result);
    SetPlane(3, AddInfix(name,'$ny'),result);
    SetPlane(4, AddInfix(name,'$pz'),result);
    SetPlane(5, AddInfix(name,'$nz'),result);
    while length(result)<6 do begin
      SetLength(result,length(result)+1);
      result[high(result)]:=nil;
    end;
    if normalize then BitmapArrayNormalize(result);
    exit;
  end;
end;

function BitmapArrayCalculateMipmap(var b:TBitmapArray;const PreserveOldBitmaps:boolean):boolean;
var i:integer;
begin
  result:=not((b[0].Width=1)and(b[0].Height=1)and(Length(b)in[1,6]));
  if not result then exit;

  if PreserveOldBitmaps then begin
    if not(length(b)in[1,6])then begin//3d mipmap
      for i:=0 to high(b)shr 1 do
        b[i]:=b[i shl 1].LerpWithF(b[i shl 1+1],0.5);
      setlength(b,length(b)shr 1);
    end;
    for i:=0 to High(b)do//2d mipmaps
      b[i]:=b[i].ResizeHalveF(rfLinearMipmapLinear);
  end else begin
    if not(length(b)in[1,6])then begin//3d mipmap
      for i:=0 to high(b)shr 1 do begin
        b[i shl 1].LerpWith(b[i shl 1+1],0.5);
        b[i shl 1+1].Free;
        b[i]:=b[i shl 1];
      end;
      setlength(b,length(b)shr 1);
    end;
    for i:=0 to High(b)do//2d mipmaps
      b[i].ResizeHalve(rfLinearMipmapLinear);
  end;
end;

function BitmapArrayDxtEncode(const version:TDXTVersion;const b:TBitmapArray;const index:integer=0):TBytes;
var tmp:TBytes;i:integer;
begin
  SetLength(result,0);
  if length(b)in[1,2,6] then begin //1d,2d,6d
    Result:=DXTEncode(version,b[index]);
  end else begin//3d
    for i:=0 to high(b)do begin
      tmp:=DXTEncode(version,b[i]);
      if length(result)=0 then
        setlength(result,length(tmp)*length(b));
      move(tmp[0],result[length(tmp)*i],length(tmp));
    end;
  end;
end;

function BitmapArrayConcatBytes(const b:TBitmapArray):TBytes;
var i:integer;
begin
  setlength(result,b[0].ImageSize*length(b));
  for i:=0 to high(b)do
    move(b[i].ScanLine[b[i].Height-1]^,result[i*b[0].ImageSize],b[0].ImageSize);
end;

procedure BitmapArrayFree(var b:TBitmapArray);
var i:integer;
begin
  for i:=0 to high(b)do b[i].Free;
  setlength(b,0);
end;


////////////////////////////////////////////////////////////////////////////////
// HetBitmap                                                                  //
////////////////////////////////////////////////////////////////////////////////

function GrayPalette:THandle;
var pal:^TLogPalette;
    i:integer;
begin
  pal:=GetMemory(1028);
  try
    pal.palVersion:=$300;
    pal.palNumEntries:=$100;
    for i:=0 to pal.palNumEntries-1 do with pal.palPalEntry[i]do begin
      peRed:=i;peGreen:=i;peBlue:=i;peFlags:=0;end;
    result:=CreatePalette(pal^);
  finally
    FreeMemory(pal);
  end;
end;

procedure RaiseBmpSizeMismatch(const b1,b2:tbitmap;const callername:string);
begin
  if(b1.Width<>b2.Width)or(b1.Height<>b2.Height)then
    raise Exception.Create(callername+' - same size bitmaps required');
end;

function AdjustBmpSize2N(const Bmp:TBitmap;out newWidth,newHeight:integer):boolean;
begin
  if bmp=nil then Exit(false);
  newWidth:=Nearest2NSize(Bmp.Width);
  newHeight:=Nearest2NSize(Bmp.Height);
  result:=(newWidth<>bmp.Width)or(newHeight<>Bmp.Height);
end;

procedure _AdjustPixelFormat(const Bmp:TBitmap);
begin
  case Bmp.PixelFormat of
    pf1bit,pf4bit:Bmp.PixelFormat:=pf8bit;
    pf15bit,pfDevice,pfCustom:Bmp.PixelFormat:=pf24bit;
    pf16bit:;
  end;
end;

procedure _ExpandBmp(const src,dst:TBitmap);
  procedure do8bit;type t=byte;
  var p:^t;c:t;x,y:integer;
  begin
    for y:=0 to src.Height-1 do begin
      p:=dst.ScanLine[y];inc(p,src.Width-1);
      c:=p^;inc(p);
      for x:=src.Width to dst.Width-1 do begin p^:=c;inc(p);end;
    end;
    for y:=src.Height to dst.Height-1 do
      Move(dst.ScanLine[src.Height-1]^,dst.ScanLine[y]^,dst.Width*sizeof(t));
  end;

  procedure do16bit;type t=array[0..1]of byte;
  var p:^t;c:t;x,y:integer;
  begin
    for y:=0 to src.Height-1 do begin
      p:=dst.ScanLine[y];inc(p,src.Width-1);
      c:=p^;inc(p);
      for x:=src.Width to dst.Width-1 do begin p^:=c;inc(p);end;
    end;
    for y:=src.Height to dst.Height-1 do
      Move(dst.ScanLine[src.Height-1]^,dst.ScanLine[y]^,dst.Width*sizeof(t));
  end;

  procedure do24bit;type t=TRGBTriple;
  var p:^t;c:t;x,y:integer;
  begin
    for y:=0 to src.Height-1 do begin
      p:=dst.ScanLine[y];inc(p,src.Width-1);
      c:=p^;inc(p);
      for x:=src.Width to dst.Width-1 do begin p^:=c;inc(p);end;
    end;
    for y:=src.Height to dst.Height-1 do
      Move(dst.ScanLine[src.Height-1]^,dst.ScanLine[y]^,dst.Width*sizeof(t));
  end;

  procedure do32bit;type t=TRGBQuad;
  var p:^t;c:t;x,y:integer;
  begin
    for y:=0 to src.Height-1 do begin
      p:=dst.ScanLine[y];inc(p,src.Width-1);
      c:=p^;inc(p);
      for x:=src.Width to dst.Width-1 do begin p^:=c;inc(p);end;
    end;
    for y:=src.Height to dst.Height-1 do
      Move(dst.ScanLine[src.Height-1]^,dst.ScanLine[y]^,dst.Width*sizeof(t));
  end;

var y,i:integer;
begin
  if(src.Width<=0)or(src.Height<=0)then exit;
  _AdjustPixelFormat(src);
  dst.PixelFormat:=src.PixelFormat;

  i:=src.ScanLineSize;
  for y:=0 to src.Height-1 do
    Move(src.ScanLine[y]^,dst.ScanLine[y]^,i);

  case src.PixelFormat of
    pf8bit:do8bit;
    pf16bit:do16bit;
    pf24bit:do24bit;
    pf32bit:do32bit;
  end;
end;

procedure _StretchBmp(const src,dst:TBitmap;const Bilinear:boolean);
  const fixp=16;
        fixpMask=1 shl fixp-1;

  procedure do8bit;type t=byte;
    procedure lerp(var src0,src1,dst:t;const t:integer);inline;
    begin
      dst:=src0+sar(integer(src1-src0)*t,fixp);
    end;
  var psrc0,psrc1,psrc0next,psrc1next,pdst:^t;
      x,y,xadd,yadd,xofs,yofs,xt,yt,i:integer;
      t0,t1:t;
  begin
    if Bilinear then begin
      xadd:=((src.Width -1)shl fixp-1) div max((dst.Width -1),1);
      yadd:=((src.Height-1)shl fixp-1) div max((dst.height-1),1);
      yofs:=0;
      for y:=0 to dst.Height-1 do begin
        pdst:=dst.ScanLine[y];
        psrc0:=src.ScanLine[yofs shr fixp];
        yt:=yofs and fixpMask;
        psrc1:=src.ScanLine[min(yofs shr fixp+1,src.Height-1)];
        psrc0next:=psrc0;inc(psrc0next);
        psrc1next:=psrc1;inc(psrc1next);
        xofs:=0;
        if src.Width=1 then
          lerp(psrc0^,psrc1^,pdst^,yt)
        else for x:=0 to dst.Width-1 do begin
          xt:=xofs and fixpMask;
          lerp(psrc0^,psrc0next^,t0,xt);
          lerp(psrc1^,psrc1next^,t1,xt);
          lerp(t0,t1,pdst^,yt);
          i:=xofs shr fixp;xofs:=xofs+xadd;i:=xofs shr fixp-i;
          if i>0 then begin
            inc(psrc0,i);Inc(psrc0Next,i);
            inc(psrc1,i);Inc(psrc1Next,i);
          end;
          inc(pdst);
        end;
        yofs:=yofs+yadd;
      end
    end else begin
      xadd:=((src.Width )shl fixp-1) div max((dst.Width -1),1);
      yadd:=((src.Height)shl fixp-1) div max((dst.Height-1),1);
      yofs:=0;
      for y:=0 to dst.Height-1 do begin
        pdst:=dst.ScanLine[y];
        psrc0:=src.ScanLine[yofs shr fixp];
        xofs:=0;
        for x:=0 to dst.Width-1 do begin
          pdst^:=psrc0^;
          i:=xofs shr fixp;xofs:=xofs+xadd;i:=xofs shr fixp-i;
          if i>0 then inc(psrc0,i);
          inc(pdst);
        end;
        yofs:=yofs+yadd;
      end;
    end;
  end;

  procedure do16bit;type t=array[0..1]of byte;
    procedure lerp(var src0,src1,dst:t;const t:integer);inline;
    begin
      dst[0]:=src0[0]+sar(integer(src1[0]-src0[0])*t,fixp);
      dst[1]:=src0[1]+sar(integer(src1[1]-src0[1])*t,fixp);
    end;
  var psrc0,psrc1,psrc0next,psrc1next,pdst:^t;
      x,y,xadd,yadd,xofs,yofs,xt,yt,i:integer;
      t0,t1:t;
  begin
    if Bilinear then begin
      xadd:=((src.Width -1)shl fixp-1) div max((dst.Width -1),1);
      yadd:=((src.Height-1)shl fixp-1) div max((dst.height-1),1);
      yofs:=0;
      for y:=0 to dst.Height-1 do begin
        pdst:=dst.ScanLine[y];
        psrc0:=src.ScanLine[yofs shr fixp];
        yt:=yofs and fixpMask;
        psrc1:=src.ScanLine[min(yofs shr fixp+1,src.Height-1)];
        psrc0next:=psrc0;inc(psrc0next);
        psrc1next:=psrc1;inc(psrc1next);
        xofs:=0;
        if src.Width=1 then
          lerp(psrc0^,psrc1^,pdst^,yt)
        else for x:=0 to dst.Width-1 do begin
          xt:=xofs and fixpMask;
          lerp(psrc0^,psrc0next^,t0,xt);
          lerp(psrc1^,psrc1next^,t1,xt);
          lerp(t0,t1,pdst^,yt);
          i:=xofs shr fixp;xofs:=xofs+xadd;i:=xofs shr fixp-i;
          if i>0 then begin
            inc(psrc0,i);Inc(psrc0Next,i);
            inc(psrc1,i);Inc(psrc1Next,i);
          end;
          inc(pdst);
        end;
        yofs:=yofs+yadd;
      end
    end else begin
      xadd:=((src.Width )shl fixp-1) div max((dst.Width -1),1);
      yadd:=((src.Height)shl fixp-1) div max((dst.Height-1),1);
      yofs:=0;
      for y:=0 to dst.Height-1 do begin
        pdst:=dst.ScanLine[y];
        psrc0:=src.ScanLine[yofs shr fixp];
        xofs:=0;
        for x:=0 to dst.Width-1 do begin
          pdst^:=psrc0^;
          i:=xofs shr fixp;xofs:=xofs+xadd;i:=xofs shr fixp-i;
          if i>0 then inc(psrc0,i);
          inc(pdst);
        end;
        yofs:=yofs+yadd;
      end;
    end;
  end;

  procedure do24bit;type t=TRGBTriple;
    procedure lerp(var src0,src1,dst:t;const t:integer);inline;
    begin
      dst.rgbtBlue :=src0.rgbtBlue +sar(integer(src1.rgbtBlue -src0.rgbtBlue )*t,fixp);
      dst.rgbtGreen:=src0.rgbtGreen+sar(integer(src1.rgbtGreen-src0.rgbtGreen)*t,fixp);
      dst.rgbtRed  :=src0.rgbtRed  +sar(integer(src1.rgbtRed  -src0.rgbtRed  )*t,fixp);
    end;
  var psrc0,psrc1,psrc0next,psrc1next,pdst:^t;
      x,y,xadd,yadd,xofs,yofs,xt,yt,i:integer;
      t0,t1:t;
  begin
    if Bilinear then begin
      xadd:=((src.Width -1)shl fixp-1) div max((dst.Width -1),1);
      yadd:=((src.Height-1)shl fixp-1) div max((dst.height-1),1);
      yofs:=0;
      for y:=0 to dst.Height-1 do begin
        pdst:=dst.ScanLine[y];
        psrc0:=src.ScanLine[yofs shr fixp];
        yt:=yofs and fixpMask;
        psrc1:=src.ScanLine[min(yofs shr fixp+1,src.Height-1)];
        psrc0next:=psrc0;inc(psrc0next);
        psrc1next:=psrc1;inc(psrc1next);
        xofs:=0;
        if src.Width=1 then
          lerp(psrc0^,psrc1^,pdst^,yt)
        else for x:=0 to dst.Width-1 do begin
          xt:=xofs and fixpMask;
          lerp(psrc0^,psrc0next^,t0,xt);
          lerp(psrc1^,psrc1next^,t1,xt);
          lerp(t0,t1,pdst^,yt);
          i:=xofs shr fixp;xofs:=xofs+xadd;i:=xofs shr fixp-i;
          if i>0 then begin
            inc(psrc0,i);Inc(psrc0Next,i);
            inc(psrc1,i);Inc(psrc1Next,i);
          end;
          inc(pdst);
        end;
        yofs:=yofs+yadd;
      end
    end else begin
      xadd:=((src.Width )shl fixp-1) div max((dst.Width -1),1);
      yadd:=((src.Height)shl fixp-1) div max((dst.Height-1),1);
      yofs:=0;
      for y:=0 to dst.Height-1 do begin
        pdst:=dst.ScanLine[y];
        psrc0:=src.ScanLine[yofs shr fixp];
        xofs:=0;
        for x:=0 to dst.Width-1 do begin
          pdst^:=psrc0^;
          i:=xofs shr fixp;xofs:=xofs+xadd;i:=xofs shr fixp-i;
          if i>0 then inc(psrc0,i);
          inc(pdst);
        end;
        yofs:=yofs+yadd;
      end;
    end;
  end;

  procedure do32bit;type t=TRGBQuad;
    procedure lerp(var src0,src1,dst:t;const t:integer);inline;
    begin
      dst.rgbBlue    :=src0.rgbBlue    +sar(integer(src1.rgbBlue    -src0.rgbBlue    )*t,fixp);
      dst.rgbGreen   :=src0.rgbGreen   +sar(integer(src1.rgbGreen   -src0.rgbGreen   )*t,fixp);
      dst.rgbRed     :=src0.rgbRed     +sar(integer(src1.rgbRed     -src0.rgbRed     )*t,fixp);
      dst.rgbReserved:=src0.rgbReserved+sar(integer(src1.rgbReserved-src0.rgbReserved)*t,fixp);
    end;
  var psrc0,psrc1,psrc0next,psrc1next,pdst:^t;
      x,y,xadd,yadd,xofs,yofs,xt,yt,i:integer;
      t0,t1:t;
  begin
    if Bilinear then begin
      xadd:=((src.Width -1)shl fixp-1) div max((dst.Width -1),1);
      yadd:=((src.Height-1)shl fixp-1) div max((dst.height-1),1);
      yofs:=0;
      for y:=0 to dst.Height-1 do begin
        pdst:=dst.ScanLine[y];
        psrc0:=src.ScanLine[yofs shr fixp];
        yt:=yofs and fixpMask;
        psrc1:=src.ScanLine[min(yofs shr fixp+1,src.Height-1)];
        psrc0next:=psrc0;inc(psrc0next);
        psrc1next:=psrc1;inc(psrc1next);
        xofs:=0;
        if src.Width=1 then
          lerp(psrc0^,psrc1^,pdst^,yt)
        else for x:=0 to dst.Width-1 do begin
          xt:=xofs and fixpMask;
          lerp(psrc0^,psrc0next^,t0,xt);
          lerp(psrc1^,psrc1next^,t1,xt);
          lerp(t0,t1,pdst^,yt);
          i:=xofs shr fixp;xofs:=xofs+xadd;i:=xofs shr fixp-i;
          if i>0 then begin
            inc(psrc0,i);Inc(psrc0Next,i);
            inc(psrc1,i);Inc(psrc1Next,i);
          end;
          inc(pdst);
        end;
        yofs:=yofs+yadd;
      end
    end else begin
      xadd:=((src.Width )shl fixp-1) div max((dst.Width -1),1);
      yadd:=((src.Height)shl fixp-1) div max((dst.Height-1),1);
      yofs:=0;
      for y:=0 to dst.Height-1 do begin
        pdst:=dst.ScanLine[y];
        psrc0:=src.ScanLine[yofs shr fixp];
        xofs:=0;
        for x:=0 to dst.Width-1 do begin
          pdst^:=psrc0^;
          i:=xofs shr fixp;xofs:=xofs+xadd;i:=xofs shr fixp-i;
          if i>0 then inc(psrc0,i);
          inc(pdst);
        end;
        yofs:=yofs+yadd;
      end;
    end;
  end;

begin
  if(src.Width<=0)or(src.Height<=0)or(dst.Width<=0)or(dst.Height<=0)then exit;
  _AdjustPixelFormat(src);
  dst.PixelFormat:=src.PixelFormat;
  case dst.PixelFormat of
    pf8bit:do8bit;
    pf16bit:do16bit;
    pf24bit:do24bit;
    pf32bit:do32bit;
  end;
end;

procedure _HalveBitmap(const src,dst:TBitmap;const Bilinear:boolean);
  var dstWidth,dstHeight:integer;
      srcWidth,srcHeight:integer;

  procedure do8bit;type t=byte;
  var x,y,b:integer;
      pdst,psrc0,psrc1:^t;
  begin
    if Bilinear then
      for y:=0 to dstHeight-1 do begin
        pdst:=dst.ScanLine[y];
        psrc0:=src.ScanLine[y shl 1];
        if srcHeight>1 then psrc1:=src.ScanLine[y shl 1+1]
                       else psrc1:=psrc0;
        if srcWidth=1 then begin
          pdst^:=(psrc0^+psrc1^+1)shr 1;
        end else for x:=0 to dstWidth-1 do begin
          b:=psrc0^+psrc1^;
          inc(psrc0);inc(psrc1);
          pdst^:=(b+psrc0^+psrc1^+2)shr 2;
          inc(psrc0);inc(psrc1);
          inc(pdst);
        end;
      end
    else
      for y:=0 to dstHeight-1 do begin
        pdst:=dst.ScanLine[y];
        psrc0:=src.ScanLine[y shl 1];
        for x:=0 to dstWidth-1 do begin
          pdst^:=psrc0^;
          inc(psrc0,2);
          inc(pdst);
        end;
      end
  end;

  procedure do16bit;type t=array[0..1]of byte;
  var x,y,b,g:integer;
      pdst,psrc0,psrc1:^t;
  begin
    if Bilinear then
      for y:=0 to dstHeight-1 do begin
        pdst:=dst.ScanLine[y];
        psrc0:=src.ScanLine[y shl 1];
        if srcHeight>1 then psrc1:=src.ScanLine[y shl 1+1]
                       else psrc1:=psrc0;
        if srcWidth=1 then begin
          pdst^[0]:=(psrc0^[0]+psrc1^[0]+1)shr 1;
          pdst^[1]:=(psrc0^[1]+psrc1^[1]+1)shr 1;
        end else for x:=0 to dstWidth-1 do begin
          b:=psrc0^[0]+psrc1^[0] ;
          g:=psrc0^[1]+psrc1^[1];
          inc(psrc0);inc(psrc1);
          pdst^[0]:=(b+psrc0^[0]+psrc1^[0]+2)shr 2;
          pdst^[1]:=(g+psrc0^[1]+psrc1^[1]+2)shr 2;
          inc(psrc0);inc(psrc1);
          inc(pdst);
        end;
      end
    else
      for y:=0 to dstHeight-1 do begin
        pdst:=dst.ScanLine[y];
        psrc0:=src.ScanLine[y shl 1];
        for x:=0 to dstWidth-1 do begin
          pdst^:=psrc0^;
          inc(psrc0,2);
          inc(pdst);
        end;
      end
  end;

  procedure do24bit;type t=TRGBTriple;
  var x,y,r,g,b:integer;
      pdst,psrc0,psrc1:^t;
  begin
    if Bilinear then
      for y:=0 to dstHeight-1 do begin
        pdst:=dst.ScanLine[y];
        psrc0:=src.ScanLine[y shl 1];
        if srcHeight>1 then psrc1:=src.ScanLine[y shl 1+1]
                       else psrc1:=psrc0;
        if srcWidth=1 then begin
          pdst^.rgbtBlue :=(psrc0^.rgbtBlue +psrc1^.rgbtBlue +1)shr 1;
          pdst^.rgbtGreen:=(psrc0^.rgbtGreen+psrc1^.rgbtGreen+1)shr 1;
          pdst^.rgbtRed  :=(psrc0^.rgbtRed  +psrc1^.rgbtRed  +1)shr 1;
        end else for x:=0 to dstWidth-1 do begin
          b:=psrc0^.rgbtBlue +psrc1^.rgbtBlue ;
          g:=psrc0^.rgbtGreen+psrc1^.rgbtGreen;
          r:=psrc0^.rgbtRed  +psrc1^.rgbtRed  ;
          inc(psrc0);inc(psrc1);
          pdst^.rgbtBlue :=(b+psrc0^.rgbtBlue +psrc1^.rgbtBlue +2)shr 2;
          pdst^.rgbtGreen:=(g+psrc0^.rgbtGreen+psrc1^.rgbtGreen+2)shr 2;
          pdst^.rgbtRed  :=(r+psrc0^.rgbtRed  +psrc1^.rgbtRed  +2)shr 2;
          inc(psrc0);inc(psrc1);
          inc(pdst);
        end;
      end
    else
      for y:=0 to dstHeight-1 do begin
        pdst:=dst.ScanLine[y];
        psrc0:=src.ScanLine[y shl 1];
        for x:=0 to dstWidth-1 do begin
          pdst^:=psrc0^;
          inc(psrc0,2);
          inc(pdst);
        end;
      end
  end;

  procedure do32bit;type t=TRGBQuad;
  var x,y,r,g,b,a:integer;
      pdst,psrc0,psrc1:^t;
  begin
    if Bilinear then
      for y:=0 to dstHeight-1 do begin
        pdst:=dst.ScanLine[y];
        psrc0:=src.ScanLine[y shl 1];
        if srcHeight>1 then psrc1:=src.ScanLine[y shl 1+1]
                       else psrc1:=psrc0;
        if srcWidth=1 then begin
          pdst^.rgbBlue    :=(psrc0^.rgbBlue    +psrc1^.rgbBlue    +1)shr 1;
          pdst^.rgbGreen   :=(psrc0^.rgbGreen   +psrc1^.rgbGreen   +1)shr 1;
          pdst^.rgbRed     :=(psrc0^.rgbRed     +psrc1^.rgbRed     +1)shr 1;
          pdst^.rgbReserved:=(psrc0^.rgbReserved+psrc1^.rgbReserved+1)shr 1;
        end else for x:=0 to dstWidth-1 do begin
          b:=psrc0^.rgbBlue    +psrc1^.rgbBlue    ;
          g:=psrc0^.rgbGreen   +psrc1^.rgbGreen   ;
          r:=psrc0^.rgbRed     +psrc1^.rgbRed     ;
          a:=psrc0^.rgbReserved+psrc1^.rgbReserved;
          inc(psrc0);inc(psrc1);
          pdst^.rgbBlue    :=(b+psrc0^.rgbBlue    +psrc1^.rgbBlue    +2)shr 2;
          pdst^.rgbGreen   :=(g+psrc0^.rgbGreen   +psrc1^.rgbGreen   +2)shr 2;
          pdst^.rgbRed     :=(r+psrc0^.rgbRed     +psrc1^.rgbRed     +2)shr 2;
          pdst^.rgbReserved:=(a+psrc0^.rgbReserved+psrc1^.rgbReserved+2)shr 2;
          inc(psrc0);inc(psrc1);
          inc(pdst);
        end;
      end
    else
      for y:=0 to dstHeight-1 do begin
        pdst:=dst.ScanLine[y];
        psrc0:=src.ScanLine[y shl 1];
        for x:=0 to dstWidth-1 do begin
          pdst^:=psrc0^;
          inc(psrc0,2);
          inc(pdst);
        end;
      end
  end;
begin
  if(src.Width<=0)or(src.Height<=0)then exit;
  _AdjustPixelFormat(src);
  dst.PixelFormat:=src.PixelFormat;
  if dst.PixelFormat=pf8bit then
    dst.Palette:=GrayPalette;
  srcWidth:=src.Width;
  srcHeight:=src.Height;
  dstWidth:=max(src.Width shr 1,1);
  dstHeight:=max(src.Height shr 1,1);
  if dst.width<dstWidth then dst.Width:=dstWidth;
  if dst.height<dstheight then dst.height:=dstheight;
  case dst.PixelFormat of
    pf8bit:do8bit;
    pf16bit:do16bit;
    pf24bit:do24bit;
    pf32bit:do32bit;
  end;
  dst.Width:=dstWidth;
  dst.Height:=dstHeight;
end;

procedure _LerpBmp(const src0,src1,dst:TBitmap;const t:single);
  procedure do8bit(mul:integer);type t=byte;
  var x,y:integer;
      pSrc0,pSrc1,pDst:^t;
  begin
    for y:=0 to dst.Height-1 do begin
      pSrc0:=src0.ScanLine[y];
      pSrc1:=src1.ScanLine[y];
      pDst:=dst.ScanLine[y];
      if mul=128 then for x:=0 to dst.Width-1 do begin
        pDst^:=(pSrc0^+pSrc1^)shr 1;
        inc(pSrc0);inc(pSrc1);Inc(pDst);
      end else for x:=0 to dst.Width-1 do begin
        pDst^:=pSrc0^+sar((pSrc1^-pSrc0^)*mul,8);
        inc(pSrc0);inc(pSrc1);Inc(pDst);
      end;
    end;
  end;
  procedure do16bit(mul:integer);type t=array[0..1]of byte;
  var x,y:integer;
      pSrc0,pSrc1,pDst:^t;
  begin
    for y:=0 to dst.Height-1 do begin
      pSrc0:=src0.ScanLine[y];
      pSrc1:=src1.ScanLine[y];
      pDst:=dst.ScanLine[y];
      if mul=128 then for x:=0 to dst.Width-1 do begin
        pDst^[0]:=(pSrc0^[0]+pSrc1^[0])shr 1;
        pDst^[1]:=(pSrc0^[1]+pSrc1^[1])shr 1;
        inc(pSrc0);inc(pSrc1);Inc(pDst);
      end else for x:=0 to dst.Width-1 do begin
        pDst^[0]:=pSrc0^[0]+sar((pSrc1^[0]-pSrc0^[0])*mul,8);
        pDst^[1]:=pSrc0^[1]+sar((pSrc1^[1]-pSrc0^[1])*mul,8);
        inc(pSrc0);inc(pSrc1);Inc(pDst);
      end;
    end;
  end;
  procedure do24bit(mul:integer);type t=TRGBTriple;
  var x,y:integer;
      pSrc0,pSrc1,pDst:^t;
  begin
    for y:=0 to dst.Height-1 do begin
      pSrc0:=src0.ScanLine[y];
      pSrc1:=src1.ScanLine[y];
      pDst:=dst.ScanLine[y];
      if mul=128 then for x:=0 to dst.Width-1 do begin
        pDst^.rgbtBlue :=(pSrc0^.rgbtBlue +pSrc1^.rgbtBlue )shr 1;
        pDst^.rgbtGreen:=(pSrc0^.rgbtGreen+pSrc1^.rgbtGreen)shr 1;
        pDst^.rgbtRed  :=(pSrc0^.rgbtRed  +pSrc1^.rgbtRed  )shr 1;
        inc(pSrc0);inc(pSrc1);Inc(pDst);
      end else for x:=0 to dst.Width-1 do begin
        pDst^.rgbtBlue :=pSrc0^.rgbtBlue +sar((pSrc1^.rgbtBlue -pSrc0^.rgbtBlue )*mul,8);
        pDst^.rgbtGreen:=pSrc0^.rgbtGreen+sar((pSrc1^.rgbtGreen-pSrc0^.rgbtGreen)*mul,8);
        pDst^.rgbtRed  :=pSrc0^.rgbtRed  +sar((pSrc1^.rgbtRed  -pSrc0^.rgbtRed  )*mul,8);
        inc(pSrc0);inc(pSrc1);Inc(pDst);
      end;
    end;
  end;
  procedure do32bit(mul:integer);type t=TRGBQuad;
  var x,y:integer;
      pSrc0,pSrc1,pDst:^t;
  begin
    for y:=0 to dst.Height-1 do begin
      pSrc0:=src0.ScanLine[y];
      pSrc1:=src1.ScanLine[y];
      pDst:=dst.ScanLine[y];
      if mul=128 then for x:=0 to dst.Width-1 do begin
        pDst^.rgbBlue    :=(pSrc0^.rgbBlue    +pSrc1^.rgbBlue    )shr 1;
        pDst^.rgbGreen   :=(pSrc0^.rgbGreen   +pSrc1^.rgbGreen   )shr 1;
        pDst^.rgbRed     :=(pSrc0^.rgbRed     +pSrc1^.rgbRed     )shr 1;
        pDst^.rgbReserved:=(pSrc0^.rgbReserved+pSrc1^.rgbReserved)shr 1;
        inc(pSrc0);inc(pSrc1);Inc(pDst);
      end else for x:=0 to dst.Width-1 do begin
        pDst^.rgbBlue    :=pSrc0^.rgbBlue    +sar((pSrc1^.rgbBlue    -pSrc0^.rgbBlue    )*mul,8);
        pDst^.rgbGreen   :=pSrc0^.rgbGreen   +sar((pSrc1^.rgbGreen   -pSrc0^.rgbGreen   )*mul,8);
        pDst^.rgbRed     :=pSrc0^.rgbRed     +sar((pSrc1^.rgbRed     -pSrc0^.rgbRed     )*mul,8);
        pDst^.rgbReserved:=pSrc0^.rgbReserved+sar((pSrc1^.rgbReserved-pSrc0^.rgbReserved)*mul,8);
        inc(pSrc0);inc(pSrc1);Inc(pDst);
      end;
    end;
  end;
var mul:integer;
begin
  if src0.Empty or src1.empty then exit;
  RaiseBmpSizeMismatch(dst,src0,'_LerpBmp()');
  RaiseBmpSizeMismatch(dst,src1,'_LerpBmp()');

  _AdjustPixelFormat(src0);
  _AdjustPixelFormat(src1);
  if(src0.PixelFormat=pf32bit)or(src1.PixelFormat=pf32bit)then dst.PixelFormat:=pf32bit
  else if(src0.PixelFormat=pf24bit)or(src1.PixelFormat=pf24bit)then dst.PixelFormat:=pf24bit
  else if(src0.PixelFormat=pf16bit)or(src1.PixelFormat=pf16bit)then dst.PixelFormat:=pf16bit
  else dst.PixelFormat:=pf8bit;
  src0.PixelFormat:=dst.PixelFormat;
  src1.PixelFormat:=dst.PixelFormat;

  mul:=Rangerf(0,round(t*256),256);
  if mul=0 then
    dst.Assign(src0)
  else if mul=256 then
    dst.Assign(src1)
  else case dst.PixelFormat of
    pf8bit:do8bit(mul);
    pf16bit:do16bit(mul);
    pf24bit:do24bit(mul);
    pf32bit:do32bit(mul);
  end;
end;

function THetBitmap.Center: TPoint;
begin
  result:=point(width shr 1,height shr 1);
end;

function THetBitmap.PixelSizeBits: integer;
begin
  case PixelFormat of
    pf1bit:result:=1;
    pf4bit:result:=4;
    pf8bit:result:=8;
    pf15bit:result:=16;
    pf16bit:result:=16;
    pf24bit:result:=24;
    pf32bit:result:=32;
    else result:=0;
  end;
end;

function THetBitmap.PixelSum(const r: TRect): integer;
var x,y:integer;p:PByte;
begin
  if Components<>1 then raise Exception.Create('NotImpl');

  result:=0;
  for y:=r.Top to r.Bottom-1 do begin
    p:=ScanLine[y];inc(p,r.Left);
    for x:=r.Left to r.Right-1 do begin
      inc(result,p^);
      inc(p);
    end;
  end;
end;

function THetBitmap.PixelSum: integer;
begin
  result:=PixelSum(ImageRect);
end;

function THetBitmap.PixelSumX(const r: TRect): TArray<integer>;
var x,y:integer;p:PByte;c:PInteger;
begin
  if Components<>1 then raise Exception.Create('NotImpl');

  setlength(result,r.Right-r.Left);fillchar(result[0],length(result)*sizeof(result[0]),0);
  for y:=r.Top to r.Bottom-1 do begin
    p:=ScanLine[y];inc(p,r.Left);c:=@result[0];
    for x:=r.Left to r.Right-1 do begin
      inc(c^,p^);
      inc(p);inc(c);
    end;
  end;
end;

function THetBitmap.PixelSumX: TArray<integer>;
begin
  result:=PixelSumX(ImageRect)
end;

function THetBitmap.PixelSumY(const r: TRect): TArray<integer>;
var x,y:integer;p:PByte;c:PInteger;
begin
  if Components<>1 then raise Exception.Create('NotImpl');

  setlength(result,r.Bottom-r.Top);fillchar(result[0],length(result)*sizeof(result[0]),0);
  c:=@result[0];
  for y:=r.Top to r.Bottom-1 do begin
    p:=ScanLine[y];inc(p,r.Left);
    for x:=r.Left to r.Right-1 do begin
      inc(c^,p^);
      inc(p);
    end;
    inc(c);
  end;
end;

function THetBitmap.PixelSumY: TArray<integer>;
begin
  result:=PixelSumY(ImageRect)
end;

function THetBitmap.PixelSumXY(const r: TRect; out horz, vert: TArray<integer>): integer;
var x,y:integer;p:PByte;ch,cv:PInteger;
begin
  if Components<>1 then raise Exception.Create('NotImpl');

  setlength(horz,r.Right-r.Left);fillchar(horz[0],length(horz)*sizeof(horz[0]),0);
  setlength(vert,r.Bottom-r.Top);fillchar(vert[0],length(vert)*sizeof(vert[0]),0);
  result:=0;
  cv:=@vert[0];
  for y:=r.Top to r.Bottom-1 do begin
    p:=ScanLine[y];inc(p,r.Left);ch:=@horz[0];
    for x:=r.Left to r.Right-1 do begin
      inc(cv^,p^);inc(ch^,p^);inc(result,p^);
      inc(p);inc(ch);
    end;
    inc(cv);
  end;
end;

function THetBitmap.PixelSumXY(out horz, vert: TArray<integer>): integer;
begin
  result:=PixelSumXY(ImageRect,horz,vert);
end;

function THetBitmap.PixelSize: integer;
begin
  result:=(PixelSizeBits+7)shr 3;
end;

function THetBitmap.ScanLineSize: integer;
begin
  result:=(width*PixelSize+3)and not 3;
end;

function THetBitmap.ImageSize: integer;
begin
  result:=ScanLineSize*Height;
end;

procedure THetBitmap.LerpWith(const bmp: tbitmap; const t: single);
begin
  if(Bmp.Width<>Width)or(bmp.Height<>Height)then Raise Exception.Create('THetBitmap.LerpWith() size differs, use resize!');
  _LerpBmp(Self,bmp,self,t);
end;

function THetBitmap.LerpWithF(const bmp: tbitmap; const t: single): TBitmap;
begin
  if(Bmp.Width<>Width)or(bmp.Height<>Height)then Raise Exception.Create('THetBitmap.LerpWithF() size differs, use resize!');
  result:=TBitmap.CreateNew(PixelFormat,Width,Height);
  _LerpBmp(Self,bmp,result,t);
end;

function THetBitmap.Image: Pointer;
begin
  result:=Scanline[Height-1];
end;

function THetBitmap.ImageRect: TRect;
begin
  result:=classes.rect(0,0,width,height);
end;

function THetBitmap.CopyF: TBitmap;
begin
  result:=TBitmap.CreateClone(self);
end;

constructor THetBitmap.CreateFromFile(const AFileName: string);
var f:TFile;
begin
  Create;
  f:=TFile(AFileName);
  if f.Exists then LoadFromStr(f)
              else raise Exception.Create('File not found: '+AFileName);
end;

constructor THetBitmap.CreateFromData;
begin
  Create;
  LoadFromData(AData,AWidth,AHeight,ABitCount);
end;

constructor THetBitmap.CreateFromStr(const data: RawByteString);
begin
  Create;
  LoadFromStr(data);
end;

constructor THetBitmap.CreateNew(const APixelFormat: TPixelFormat; const AWidth, AHeight: integer);
begin
  Create;
  PixelFormat:=APixelFormat;
  if APixelFormat=pf8bit then
    Palette:=GrayPalette;
  Width:=AWidth;
  Height:=AHeight;
end;

constructor THetBitmap.CreateProcedural(const APixelFormat:TPixelFormat;const AWidth,AHeight:integer;const funct:TPixelOpFunct2);
var x,y:integer;
begin
  CreateNew(APixelFormat,AWidth,AHeight);
  for y:=0 to AHeight-1 do
    for x:=0 to AWidth-1 do
      pix[x,y]:=funct(x,y);
end;

constructor THetBitmap.CreateFromPicture(const APicture:TPicture);
begin
  Create;
  if APicture=nil then exit;
  with APicture do if APicture.Graphic<>nil then begin
    PixelFormat:=pf32bit;
    SetSize(Graphic.Width,Graphic.Height);
    canvas.Draw(0,0,Graphic);
  end else if Bitmap<>nil then
    Assign(APicture.Bitmap);
end;


function THetBitmap.CropF(const r: TRect): TBitmap;
begin
  result:=TBitmap.CreateNew(PixelFormat,abs(r.Right-r.Left),abs(r.Bottom-r.Top));
  result.Canvas.CopyRect(Rect(0,0,Result.Width,Result.Height),canvas,r);
end;

procedure THetBitmap.Crop(const r: TRect);
var b:TBitmap;
begin
  b:=CropF(r);
  Assign(b);
  b.Free;
end;

constructor THetBitmap.CreateClone(const ASrc:TBitmap);
begin
  CreateNew(ASrc.PixelFormat,ASrc.Width,ASrc.Height);
  Canvas.Draw(0,0,ASrc);
end;

function THetBitmap.Empty: boolean;
begin
  result:=(self=nil)or(Width<=0)or(height<=0);
end;

function THetBitmap.EqualDimensions(const b:TBitmap):boolean;
begin
  result:=(b<>nil)and(self<>nil)and(b.Components=Components)and(b.Width=Width)and(b.Height=Height)
end;

procedure THetBitmap.Expand(const AWidth, AHeight: integer);
var b:TBitmap;
begin
  if(AWidth=Width)and(AHeight=Height)then exit;
  if(AWidth<Width)or(AHeight<Height)then exit;
  b:=TBitmap.CreateClone(Self);
  Width:=AWidth;Height:=AHeight;
  _ExpandBmp(b,self);
  b.Free;
end;

function THetBitmap.ExpandF(const AWidth, AHeight: integer): TBitmap;
begin
  if(AWidth=Width)and(AHeight=Height)then begin
    result:=TBitmap.CreateClone(self);
    exit;
  end;
  if(AWidth<Width)or(AHeight<Height)then exit(nil);
  result:=TBitmap.CreateNew(PixelFormat,AWidth,AHeight);
  _ExpandBmp(self,result);
end;

procedure THetBitmap.FlipH;
begin
  Canvas.StretchDraw(rect(Width-1,0,-1,Height),self);
end;

procedure THetBitmap.FlipV;
begin
  Canvas.StretchDraw(rect(0,Height-1,Width,-1),self);
end;

procedure THetBitmap.SwapRedBlue;

  procedure sse(p:pointer);
  asm
    movdqu xmm0,[eax]
    movdqa xmm1,xmm0
    prefetchnta [eax+16]
    psrlw xmm1,8
    movdqa xmm2,xmm0
    psllw xmm1,8
    pslld xmm2,8
    pslld xmm0,24
    psrld xmm2,24
    psrld xmm0,8
    por xmm2,xmm1
    por xmm0,xmm2
    movdqu [eax],xmm0
  end;


var temp:array[0..7]of cardinal;
    p,pend:integer;

  procedure doOne(p:pcardinal);
  var n:integer;
  begin
    n:=0;while(cardinal(@temp[n])and $f)<>0 do inc(n);
    temp[n]:=p^;
    sse(@temp);
    p^:=temp[n];
  end;

begin
  if not empty and(PixelFormat=pf32bit)then begin
    p:=cardinal(ScanLine[height-1]);
    pend:=p+ImageSize;
    while(p<pend)and((p and $f)<>0)do begin doone(pcardinal(p));inc(p,4) end;
    while(p<pend)and((pend and $f)<>0)do begin doone(pcardinal(pend-4));dec(pend,4) end;
    while(p<pend)do begin sse(pointer(p));inc(p,16)end;
  end
  else PixelOp1(function(a:cardinal):cardinal begin result:=a and $ff00ff00 or a and $ff shl 16 or a and $ff0000 shr 16 end);
end;

procedure THetBitmap.Expand2N;
begin
  Expand(Nearest2NSize(Width),Nearest2NSize(Height));
end;

function THetBitmap.Expand2NF: TBitmap;
begin
  result:=ExpandF(Nearest2NSize(Width),Nearest2NSize(Height));
end;

procedure THetBitmap.ExpandAligned(const Align:integer);
var a1:integer;
begin
  if Align<=1 then exit;
  a1:=Align-1;
  if Align xor a1<>a1 shl 1 or 1 then raise Exception.Create('THetBitmap.ExpandAligned() Align non power of 2');
  Expand((Width+a1)and a1,(height+a1)and a1);
end;

function THetBitmap.ExpandAlignedF(const Align:integer):TBitmap;//qrva ismetles, ezzel vmit csinalni kell
var a1:integer;
begin
  if Align<=1 then exit(nil);
  a1:=Align-1;
  if Align xor a1<>a1 shl 1 or 1 then raise Exception.Create('THetBitmap.ExpandAlignedF() Align non power of 2');
  result:=ExpandF((Width+a1)and a1,(height+a1)and a1);
end;

function THetBitmap.ResizeF(const AWidth, AHeight: integer;const ResizeFilter: TResizeFilter): TBitmap;
  procedure Simple;
  begin
    Result:=TBitmap.CreateNew(PixelFormat,AWidth,AHeight);
    _StretchBmp(self,result,ResizeFilter<>rfNearest);
  end;

  function getMip(const n:cardinal):TBitmap;
  var i:cardinal;
  begin
    case n of
      0:result:=self;
      1:result:=ResizeHalveF(rfLinear);
      else begin
        result:=ResizeHalveF(rfLinear);
        for i:=2 to n do result.ResizeHalve(rfLinear);
      end;
    end;
  end;

const cSimple=0.125;
var ratio,t:Single;
    isSimple:boolean;
    bHigh,bLow:TBitmap;
begin
  if(AWidth=0)or(AHeight=0)then begin
    result:=TBitmap.CreateNew(PixelFormat,AWidth,AHeight);
    exit;
  end;

  if(AWidth=Width)and(AHeight=Height)then begin
    result:=TBitmap.CreateClone(self);
    exit;
  end;

  ratio:=minf(log2(Width/AWidth),log2(Height/AHeight));

  if ratio<cSimple then begin
    Simple;
    exit
  end;

  if ResizeFilter=rfLinearMipmapLinear then begin
    isSimple:=(Abs(round(ratio)-ratio)<=cSimple);

    if isSimple then begin
      bHigh:=getMip(round(ratio));
      if bHigh=self then begin
        result:=bHigh.ResizeF(AWidth,AHeight,rfLinear)
      end else begin
        result:=bHigh;result.Resize(AWidth,AHeight,rfLinear);
      end;
    end else begin
      bHigh:=getMip(floor(ratio));
      bLow:=bHigh.ResizeHalveF(rfLinear);
      if bHigh=self then bHigh:=bHigh.Resizef(AWidth,AHeight,rfLinear)
                    else bHigh.Resize(AWidth,AHeight,rfLinear);
      result:=bLow.ResizeF(AWidth,AHeight,rfLinear);
      t:=(frac(ratio)-cSimple)/(1-2*cSimple);
      Result.LerpWith(bHigh,1-t);
      bLow.Free;
      bHigh.Free;
    end;
  end else if ResizeFilter=rfNearestMipmapLinear then begin
    bHigh:=getMip(round(ratio));
    if bHigh=self then result:=bHigh.ResizeF(AWidth,AHeight,rfLinear)
                  else begin result:=bHigh;bHigh.Resize(AWidth,AHeight,rfLinear)end;
  end else begin
    Simple;
  end;
end;

procedure ProportionalResize(const AWidth,AHeight,AMaxWidth,AMaxHeight:integer;const AEnlarge:boolean;out ANewWidth,ANewHeight:integer);
begin
  ANewWidth:=AMaxWidth;
  ANewHeight:=AHeight*AMaxWidth div AWidth;
  if ANewHeight>AMaxHeight then begin
    ANewWidth:=AWidth*AMaxHeight div AHeight;
    ANewHeight:=AMaxHeight;
  end;
  if not AEnlarge and((ANewWidth>AWidth)or(ANewHeight>AHeight))then begin
    ANewWidth:=AWidth;
    ANewHeight:=AHeight;
  end;
end;

procedure THetBitmap.ResizeFit(const AMaxWidth, AMaxHeight:integer;const AEnlarge: boolean; const ResizeFilter: TResizeFilter);
var NewWidth,NewHeight:Integer;
begin
  ProportionalResize(Width,Height,AMaxWidth,AMaxHeight,AEnlarge,NewWidth,NewHeight);
  Resize(NewWidth,NewHeight,ResizeFilter);
end;

function THetBitmap.ResizeFitF(const AMaxWidth, AMaxHeight:integer;const AEnlarge: boolean; const ResizeFilter: TResizeFilter): TBitmap;
var NewWidth,NewHeight:integer;
begin
  ProportionalResize(Width,Height,AMaxWidth,AMaxHeight,AEnlarge,NewWidth,NewHeight);
  result:=ResizeF(NewWidth,NewHeight,ResizeFilter);
end;

procedure THetBitmap.Resize(const AWidth, AHeight: integer;const ResizeFilter: TResizeFilter);
var b:TBitmap;
begin
  if(AWidth=Width)and(AHeight=Height)then exit;
  b:=nil;
  try
    b:=ResizeF(AWidth,AHeight,ResizeFilter);
    Assign(b);
  finally
    b.Free;
  end;
end;

procedure THetBitmap.ResizeDouble(const ResizeFilter: TResizeFilter);
begin
  Resize(Width shl 1,Height shl 1,ResizeFilter);
end;

function THetBitmap.ResizeDoubleF(const ResizeFilter: TResizeFilter): TBitmap;
begin
  Result:=ResizeF(Width shl 1,Height shl 1,ResizeFilter);
end;

procedure THetBitmap.ResizeHalve(const ResizeFilter: TResizeFilter);
begin
  _HalveBitmap(self,self,ResizeFilter<>rfNearest);
end;

function THetBitmap.ResizeHalveF(const ResizeFilter: TResizeFilter): TBitmap;
begin
  result:=TBitmap.Create;
  _HalveBitmap(self,result,ResizeFilter<>rfNearest);
end;

procedure THetBitmap.ResizeScale(const AScale:single;const ResizeFilter: TResizeFilter);
begin
  Resize(round(Width*AScale),round(Height*AScale),ResizeFilter);
end;

function THetBitmap.ResizeScaleF(const AScale:single;const ResizeFilter: TResizeFilter): TBitmap;
begin
  result:=ResizeF(round(Width*AScale),round(Height*AScale),ResizeFilter);
end;

procedure THetBitmap.Resize2N(const ResizeFilter: TResizeFilter);
begin
  Resize(Nearest2NSize(Width),Nearest2NSize(Height),ResizeFilter);
end;

function THetBitmap.Resize2NF(const ResizeFilter: TResizeFilter): TBitmap;
begin
  result:=ResizeF(Nearest2NSize(Width),Nearest2NSize(Height),ResizeFilter);
end;

function THetBitmap.GrayscaleF: TBitmap;
  //30% of the red value, 59% of the green value, and 11% of the blue value
  const
    cRed=77;      // 76.8
    cGreen=151;   //151.04
    cBlue=28;     // 28.16

  procedure do16Bit;type t=array[0..1]of byte;
  var src:^t;dst:^byte;x,y:integer;
  begin
    if(Width<=0)or(Height<=0)then exit;
    for y:=0 to Height-1 do begin
      src:=ScanLine[y];
      dst:=Result.ScanLine[y];
      for x:=0 to Width-1 do begin
        dst^:=src^[0];
        inc(src);inc(dst);
      end;
    end;
  end;

  procedure do24Bit;type t=TRgbTriple;
  var src:^t;dst:^byte;x,y:integer;
  begin
    if(Width<=0)or(Height<=0)then exit;
    for y:=0 to Height-1 do begin
      src:=ScanLine[y];
      dst:=Result.ScanLine[y];
      for x:=0 to Width-1 do begin
        dst^:=(src^.rgbtRed*cRed+src^.rgbtGreen*cGreen+src^.rgbtBlue*cBlue+128)shr 8;
        inc(src);inc(dst);
      end;
    end;
  end;

  procedure do32Bit;type t=TRGBQuad;
  var src:^t;dst:^byte;x,y:integer;
  begin
    if(Width<=0)or(Height<=0)then exit;
    for y:=0 to Height-1 do begin
      src:=ScanLine[y];
      dst:=Result.ScanLine[y];
      for x:=0 to Width-1 do begin
        dst^:=(src^.rgbRed*cRed+src^.rgbGreen*cGreen+src^.rgbBlue*cBlue+128)shr 8;
        inc(src);inc(dst);
      end;
    end;
  end;

begin
  _AdjustPixelFormat(self);
  if PixelFormat=pf8Bit then
    result:=CopyF
  else begin
    result:=TBitmap.CreateNew(pf8bit,Width,Height);
    case PixelFormat of
      pf16bit:do16Bit;
      pf24bit:do24Bit;
      pf32bit:do32Bit;
    end;
  end;
end;

procedure THetBitmap.Grayscale;
var tmp:TBitmap;
begin
  if PixelFormat<>pf8Bit then begin
    tmp:=grayscaleF;
    try
      Assign(tmp);
    finally
      tmp.Free;
    end;
  end;
end;

function THetBitmap.GrayscaleAlphaF: TBitmap;
  //30% of the red value, 59% of the green value, and 11% of the blue value
  const
    cRed=77;      // 76.8
    cGreen=151;   //151.04
    cBlue=28;     // 28.16

  procedure do8Bit;type t=byte;
  var src:^t;dst:^word;x,y:integer;
  begin
    if(Width<=0)or(Height<=0)then exit;
    for y:=0 to Height-1 do begin
      src:=ScanLine[y];
      dst:=Result.ScanLine[y];
      for x:=0 to Width-1 do begin
        dst^:=src^ or $FF00;
        inc(src);inc(dst);
      end;
    end;
  end;

  procedure do24Bit;type t=TRgbTriple;
  var src:^t;dst:^word;x,y:integer;
  begin
    if(Width<=0)or(Height<=0)then exit;
    for y:=0 to Height-1 do begin
      src:=ScanLine[y];
      dst:=Result.ScanLine[y];
      for x:=0 to Width-1 do begin
        dst^:=(src^.rgbtRed*cRed+src^.rgbtGreen*cGreen+src^.rgbtBlue*cBlue+128)shr 8 or $FF00;
        inc(src);inc(dst);
      end;
    end;
  end;

  procedure do32Bit;type t=TRGBQuad;
  var src:^t;dst:^word;x,y:integer;
  begin
    if(Width<=0)or(Height<=0)then exit;
    for y:=0 to Height-1 do begin
      src:=ScanLine[y];
      dst:=Result.ScanLine[y];
      for x:=0 to Width-1 do begin
        dst^:=(src^.rgbRed*cRed+src^.rgbGreen*cGreen+src^.rgbBlue*cBlue+128)shr 8 or src^.rgbReserved shl 8;
        inc(src);inc(dst);
      end;
    end;
  end;

begin
  _AdjustPixelFormat(self);
  if PixelFormat=pf16Bit then
    result:=CopyF
  else begin
    result:=TBitmap.CreateNew(pf16bit,Width,Height);
    case PixelFormat of
      pf8bit:do8Bit;
      pf24bit:do24Bit;
      pf32bit:do32Bit;
    end;
  end;
end;

procedure THetBitmap.GrayScaleAlpha;
var tmp:TBitmap;
begin
  if PixelFormat<>pf16Bit then begin
    tmp:=GrayscaleAlphaF;
    try
      Assign(tmp);
    finally
      tmp.Free;
    end;
  end;
  Palette:=0;
end;


function AdjustRect(const r:trect;bounds:trect):trect;
begin
  result.Left:=max(r.Left,bounds.Left);
  result.Top:=max(r.Top,bounds.Top);
  result.Right:=min(r.Right,bounds.Right);
  result.Bottom:=min(r.Bottom,bounds.Bottom);
end;

procedure THetBitmap.PixelOp1(const Funct: TPixelOpFunct1; const range: TRect);
var r:trect;

  procedure do8Bit;type t=byte;
  var x,y:integer;p:^t;
  begin
    for y:=r.Top to r.Bottom-1 do begin
      p:=ScanLine[y];inc(p,r.Left);
      for x:=r.Left to r.Right-1 do begin
        p^:=Funct(p^);
        inc(p);
      end;
    end;
  end;

  procedure do16Bit;type t=word;
  var x,y:integer;p:^t;
  begin
    for y:=r.Top to r.Bottom-1 do begin
      p:=ScanLine[y];inc(p,r.Left);
      for x:=r.Left to r.Right-1 do begin
        p^:=Funct(p^);
        inc(p);
      end;
    end;
  end;

  procedure do24Bit;type t=TRGBTriple;
  var x,y:integer;p:^t;tmp:cardinal;
  begin
    for y:=r.Top to r.Bottom-1 do begin
      p:=ScanLine[y];inc(p,r.Left);
      for x:=r.Left to r.Right-2 do begin
        tmp:=Funct(PCardinal(p)^ and $ffffff);//laza
        pword(p)^:=tmp;
        p^.rgbtRed:=tmp shr 16;
        inc(p);
      end;
      //last pixel
      if r.Left<r.Right then begin
        tmp:=Funct(PWord(p)^ or p^.rgbtRed shl 16);//3byte
        pword(p)^:=tmp;
        p^.rgbtRed:=tmp shr 16;
      end;
    end;
  end;

  procedure do32Bit;type t=cardinal;
  var x,y:integer;p:^t;
  begin
    for y:=r.Top to r.Bottom-1 do begin
      p:=ScanLine[y];inc(p,r.Left);
      for x:=r.Left to r.Right-1 do begin
        p^:=Funct(p^);
        inc(p);
      end;
    end;
  end;

begin
  r:=AdjustRect(range,ImageRect);
  _AdjustPixelFormat(self);
  case Pixelformat of
    pf8bit:do8Bit;
    pf16bit:do16Bit;
    pf24bit:do24Bit;
    pf32bit:do32Bit;
  end;
end;

procedure THetBitmap.PixelOp1(const Funct: TPixelOpFunct1);
begin
  PixelOp1(Funct,ImageRect);
end;

procedure THetBitmap.PixelOp2(const src:TBitmap;const Funct: TPixelOpFunct2; const range: TRect);
var r:trect;

  procedure do8Bit;type t=byte;
  var x,y:integer;p,s:^t;
  begin
    for y:=r.Top to r.Bottom-1 do begin
      p:=ScanLine[y];
      s:=src.ScanLine[y];
      inc(p,r.Left);
      inc(s,r.Left);
      for x:=r.Left to r.Right-1 do begin
        p^:=Funct(p^,s^);
        inc(p);inc(s);
      end;
    end;
  end;

  procedure do16Bit;type t=word;
  var x,y:integer;p,s:^t;
  begin
    for y:=r.Top to r.Bottom-1 do begin
      p:=ScanLine[y];
      s:=src.ScanLine[y];
      inc(p,r.Left);
      inc(s,r.Left);
      for x:=r.Left to r.Right-1 do begin
        p^:=Funct(p^,s^);
        inc(p);inc(s);
      end;
    end;
  end;

  procedure do24Bit;type t=TRGBTriple;
  var x,y:integer;p,s:^t;tmp:cardinal;
  begin
    for y:=r.Top to r.Bottom-1 do begin
      p:=ScanLine[y];
      s:=src.ScanLine[y];
      inc(p,r.Left);
      inc(s,r.Left);
      for x:=r.Left to r.Right-2 do begin
        tmp:=Funct(PCardinal(p)^ and $ffffff,PCardinal(s)^ and $ffffff);//laza
        pword(p)^:=tmp;p^.rgbtRed:=tmp shr 16;
        inc(p);inc(s);
      end;
      //last pixel
      if r.Left<r.Right then begin
        tmp:=Funct(PWord(p)^ or p^.rgbtRed shl 16,PWord(s)^ or s^.rgbtRed shl 16);//3byte
        pword(p)^:=tmp;p^.rgbtRed:=tmp shr 16;
      end;
    end;
  end;

  procedure do32Bit;type t=cardinal;
  var x,y:integer;p,s:^t;
  begin
    for y:=r.Top to r.Bottom-1 do begin
      p:=ScanLine[y];
      s:=src.ScanLine[y];
      inc(p,r.Left);
      inc(s,r.Left);
      for x:=r.Left to r.Right-1 do begin
        p^:=Funct(p^,s^);
        inc(p);inc(s);
      end;
    end;
  end;

  procedure doAny;
  var psrc,pdst:pByte;
      csrc,cdst:Cardinal;
      srcPixelSize,dstPixelSize:integer;
      x,y:integer;
  begin
    dstPixelSize:=PixelSize;
    srcPixelSize:=src.PixelSize;
    for y:=r.Top to r.Bottom-1 do begin
      pdst:=ScanLine[y];
      psrc:=src.ScanLine[y];
      inc(pdst,r.Left*dstPixelSize);
      inc(psrc,r.Left*srcPixelSize);
      for x:=r.Left to r.Right-2 do begin
        case srcPixelSize of
          4:csrc:=pcardinal(psrc)^;
          3:csrc:=pcardinal(psrc)^ and $FFFFFF;//laza
          2:csrc:=pword(psrc)^;
          else csrc:=pbyte(psrc)^;
        end;
        case dstpixelsize of
          4:pcardinal(pdst)^:=Funct(pcardinal(pdst)^,csrc);
          3:begin
            cdst:=Funct(PCardinal(pdst)^ and $ffffff,csrc);//laza
            pword(pdst)^:=cdst;prgbtriple(pdst)^.rgbtRed:=cdst shr 16;
          end;
          2:pword(pdst)^:=Funct(pword(pdst)^,csrc);
          else pbyte(pdst)^:=Funct(pbyte(pdst)^,csrc);
        end;
        inc(psrc,srcPixelSize);
        inc(pdst,dstPixelSize);
      end;
      if r.Left<r.Right then begin
        case srcPixelSize of
          4:csrc:=pcardinal(psrc)^;
          3:csrc:=pword(psrc)^or PRgbTriple(psrc)^.rgbtRed shl 16;//3byte
          2:csrc:=pword(psrc)^;
          else csrc:=pbyte(psrc)^;
        end;
        case dstpixelsize of
          4:pcardinal(pdst)^:=Funct(pcardinal(pdst)^,csrc);
          3:begin
            cdst:=Funct(PWord(pdst)^or PRGBTriple(pdst)^.rgbtRed shl 16,csrc);//3byte
            pword(pdst)^:=cdst;prgbtriple(pdst)^.rgbtRed:=cdst shr 16;
          end;
          2:pword(pdst)^:=Funct(pword(pdst)^,csrc);
          else pbyte(pdst)^:=Funct(pbyte(pdst)^,csrc);
        end;
      end;
    end;
  end;

begin
  r:=AdjustRect(range,ImageRect);
  if(src.Width<range.Right)or(src.Height<range.Bottom)then
    raise Exception.Create('THetBitmap.PixelOp2() src image is smaller than the selected region.');
  _AdjustPixelFormat(self);
  _AdjustPixelFormat(src);
  if Src.PixelFormat=PixelFormat then case Pixelformat of
    pf8bit:do8Bit;
    pf16bit:do16Bit;
    pf24bit:do24Bit;
    pf32bit:do32Bit;
  end else
    doAny;
end;

procedure THetBitmap.PixelOp2(const Src: TBitmap; const Funct: TPixelOpFunct2);
begin
  PixelOp2(Src,Funct,ImageRect);
end;

procedure THetBitmap.PixelOpMax(const b: TBitmap; const r: TRect);
begin
  case Components of
    1:PixelOp2(b,function(a,b:cardinal):cardinal begin if b>a then result:=b else result:=a;end);
  else raise Exception.Create('NotImpl');
  end;
end;

procedure THetBitmap.PixelOpMax(const b: TBitmap);
begin
  PixelOpMax(b,ImageRect);
end;

procedure THetBitmap.PixelOpMin(const b: TBitmap; const r: TRect);
begin
  case Components of
    1:PixelOp2(b,function(a,b:cardinal):cardinal begin if b<a then result:=b else result:=a;end);
  else raise Exception.Create('NotImpl');
  end;
end;

procedure THetBitmap.PixelOpMin(const b: TBitmap);
begin
  PixelOpMin(b,ImageRect);
end;

procedure THetBitmap.PixelOpAvg(const b: TBitmap; const r: TRect);
begin
  case Components of
    1:PixelOp2(b,function(a,b:cardinal):cardinal begin result:=(a+b)shr 1 end);
  else raise Exception.Create('NotImpl');
  end;
end;

procedure THetBitmap.PixelOpAvg(const b: TBitmap);
begin
  PixelOpAvg(b,ImageRect);
end;

procedure THetBitmap.PixelOpAdd(const b: TBitmap; const r: TRect);
begin
  case Components of
    1:PixelOp2(b,function(a,b:cardinal):cardinal begin result:=(a+b);if result>255 then result:=255;end);
  else raise Exception.Create('NotImpl');
  end;
end;

procedure THetBitmap.PixelOpAdd(const b: TBitmap);
begin
  PixelOpAdd(b,ImageRect);
end;

procedure THetBitmap.PixelOpSub(const b: TBitmap; const r: TRect);
begin
  case Components of
    1:PixelOp2(b,function(a,b:cardinal):cardinal begin result:=a-b;if result>255 then result:=0;end);
  else raise Exception.Create('NotImpl');
  end;
end;

procedure THetBitmap.PixelOpSub(const b: TBitmap);
begin
  PixelOpSub(b,ImageRect);
end;

procedure THetBitmap.SetAlphaChannel(const src:TBitmap);
begin
  RaiseBmpSizeMismatch(self,src,'THetBitmap.SetAlphaChannel()');
  PixelFormat:=pf32bit;
  PixelOp2(src,function(a,b:cardinal):cardinal begin result:=a and $ffffff or b shl 24 end);
end;

function THetBitmap.GetAlphaChannel:TBitmap;
begin
  result:=TBitmap.CreateNew(pf8bit,Width,Height);
  if PixelFormat=pf32bit then result.PixelOp2(self,function(a,b:cardinal):cardinal begin result:=b shr 24 end)else
  if PixelFormat=pf16bit then result.PixelOp2(self,function(a,b:cardinal):cardinal begin result:=b shr 8 end);
end;

var
  _cm:array[0..3,0..2]of integer;

procedure prepareColorTransform(const m:TM44f);
var i,j:Integer;
begin
  for i:=0 to 2 do for j:=0 to 2 do
    _cm[i,j]:=round(m[i,j]*$10000);
  for j:=0 to 2 do
    _cm[3,j]:=round(m[3,j]*$1000000);
end;

function doColorTransform(const a:cardinal):cardinal;

  function sar_sat(c:integer):cardinal;
  asm
    sar eax,16
    jl @@zero
    cmp eax,$ff
    ja @@one
    ret
  @@zero:
    xor eax,eax
    ret
  @@one:
    mov eax,$ff
  end;
var c:array[0..2]of integer;
begin
  c[0]:=a and $ff;
  c[1]:=a shr 8 and $ff;
  c[2]:=a shr 16 and $ff;
  result:=  sar_sat(c[0]*_cm[0,0]+c[1]*_cm[1,0]+c[2]*_cm[2,0]+_cm[3,0])+
            sar_sat(c[0]*_cm[0,1]+c[1]*_cm[1,1]+c[2]*_cm[2,1]+_cm[3,1])shl 8+
            sar_sat(c[0]*_cm[0,2]+c[1]*_cm[1,2]+c[2]*_cm[2,2]+_cm[3,2])shl 16+
            a and $ff000000;
end;

procedure THetBitmap.ColorTransform(const m:TM44f;const range:TRect);
begin
  _AdjustPixelFormat(self);
  prepareColorTransform(m);
  PixelOp1(function(a:cardinal):cardinal begin result:=doColorTransform(a)end);
end;

function THetBitmap.getAsRaw: RawByteString;
var y,linesize:Integer;
    p:pbyte;
begin
  _AdjustPixelFormat(self);
  linesize:=(PixelSizeBits shr 3)*Width;
  SetLength(Result,linesize*height);
  if not empty then begin
    p:=@result[1];
    for y:=0 to Height-1 do begin
      move(ScanLine[y]^,p^,linesize);
      inc(p,linesize);
    end;
  end;
end;

procedure THetBitmap.setAsRaw(const raw: RawByteString);
var y,linesize:Integer;
    p:pbyte;
begin
  _AdjustPixelFormat(self);
  linesize:=(PixelSizeBits shr 3)*Width;
  if length(raw)<>linesize*height then
    raise Exception.Create('THetBitmap.setAsRaw() raw.lenght<>image.size');
  if not empty then begin
    p:=@raw[1];
    for y:=0 to Height-1 do begin
      move(p^,ScanLine[y]^,linesize);
      inc(p,linesize);
    end;
  end;
end;

procedure THetBitmap.ChannelExtract(const ACfg: ansistring);
var temp:TBitmap;
begin
  temp:=ChannelExtractF(ACfg);
  if temp<>nil then begin
    Self.Assign(temp);
    FreeAndNil(temp);
  end;
end;

function THetBitmap.ChannelExtractF(const ACfg: ansistring): TBitmap;
  procedure Error(const s:string);
  begin
    freeandnil(result);
    raise Exception.CreateFmt('THetBitmap.ChannelExtractF(''%s'') ',[s]);
  end;

  var done:boolean;

  type tba=array[0..3]of byte;
       pba=^tba;
  type TDoItProc=reference to procedure(src,dst:pba);
  procedure DoIt(const proc:TDoItProc);
  var x,y:integer;
      psrc,pdst:pointer;
      srcPixelSize,dstPixelSize:cardinal;
  begin
    done:=true;
    srcPixelSize:=PixelSizeBits shr 3;
    dstPixelSize:=result.PixelSizeBits shr 3;
    for y:=0 to height-1 do begin
      psrc:=pointer(scanline[y]);
      pdst:=pointer(result.scanline[y]);
      for x:=0 to Width-1 do begin
        proc(psrc,pdst);
        pInc(psrc,srcPixelSize);
        pInc(pdst,dstPixelSize);
      end;
    end;
  end;

var cfg:ansistring;
begin
  result:=nil;
  done:=false;
  cfg:=UC(ACfg);

  if cfg='Y' then exit(GrayScaleF);

  if cfg='BGR' then begin
    Result:=TBitmap.CreateClone(self);
    Assert(PixelFormat<>pf16bit,'THetBitmap.ChannelExtractF(BGR) 16bit not supported');
    Result.PixelFormat:=pf24bit;
    exit;
  end;

  if cfg='RGB' then begin
    Result:=TBitmap.CreateClone(self);
    Assert(PixelFormat<>pf16bit,'THetBitmap.ChannelExtractF(RGB) 16bit not supported');
    Result.PixelFormat:=pf24bit;
    Result.SwapRedBlue;
    exit;
  end;

  case length(cfg)of
    1:Result:=TBitmap.CreateNew(pf8bit,Width,Height);
    2:Result:=TBitmap.CreateNew(pf16bit,Width,Height);
    3:Result:=TBitmap.CreateNew(pf24bit,Width,Height);
    4:Result:=TBitmap.CreateNew(pf32bit,Width,Height);
    else Error('invalid componentcount');
  end;

  case length(cfg) of
    1:case cfg[1]of
        'R':case PixelFormat of
              pf8bit ,pf16bit:DoIt(procedure(s,d:pba)begin d[0]:=s[0] end);
              pf24bit,pf32bit:DoIt(procedure(s,d:pba)begin d[0]:=s[2] end);
            end;
        'G':case PixelFormat of
              pf8bit ,pf16bit:DoIt(procedure(s,d:pba)begin d[0]:=s[0] end);
              pf24bit,pf32bit:DoIt(procedure(s,d:pba)begin d[0]:=s[1] end);
            end;
        'B':DoIt(procedure(s,d:pba)begin d[0]:=s[0] end);
        'A':case PixelFormat of
              pf8bit ,pf24bit:DoIt(procedure(s,d:pba)begin d[0]:=255 end);
              pf16bit:DoIt(procedure(s,d:pba)begin d[0]:=s[1] end);
              pf32bit:DoIt(procedure(s,d:pba)begin d[0]:=s[3] end);
            end;
        '0':DoIt(procedure(s,d:pba)begin d[0]:=0 end);
        '1':DoIt(procedure(s,d:pba)begin d[0]:=255 end);
      end;
    2:if(cfg='RG')then if Components>=3 then
      DoIt(procedure(s,d:pba)begin d[0]:=s[2];d[1]:=s[1];end);
    3:if(cfg='RGA')then if Components>=4 then DoIt(procedure(s,d:pba)begin d[0]:=s[2];d[1]:=s[1];d[2]:=s[3] end)
                   else if Components>=3 then DoIt(procedure(s,d:pba)begin d[0]:=s[2];d[1]:=s[1];d[2]:=255 end) ;
  end;

  if not done then Error('Invalid combination');
end;

procedure THetBitmap.Clear(const AColor: TColor);
begin
  Canvas.SetBrush(bsSolid,AColor);
  Canvas.FillRect(Rect(0,0,Width,Height));
end;

function THetBitmap.CloneF: TBitmap;
begin
  result:=TBitmap.CreateClone(self);
end;

function THetBitmap.GetComponents: integer;
begin
  case PixelFormat of
    pf8bit:result:=1;
    pf16bit:result:=2;
    pf24bit:Result:=3;
    pf32bit:result:=4;
    else result:=0;
  end;
end;

procedure THetBitmap.SetComponents(const value: integer);
  procedure do24bit;
  begin
    if Components=2 then begin
      GrayScale;
      PixelFormat:=pf24bit;
    end else begin
      PixelFormat:=pf24bit;
    end;
  end;

  procedure do32bit;
  var alpha:TBitmap;
  begin
    if Components=2 then begin
      Alpha:=GetAlphaChannel;
      try
        GrayScale;
        PixelFormat:=pf32bit;
        SetAlphaChannel(Alpha);
      finally
        Alpha.Free;
      end;
    end else begin
      PixelFormat:=pf32bit;
    end;
  end;

begin
  Assert(value in [1..4],'THetBitmap.SetComponents() value not in range [1..4]');
  if Components=Value then exit;
  case Value of
    1:GrayScale;
    2:GrayScaleAlpha;
    3:do24Bit;
    4:do32bit;
  end;
  if value<>1 then Palette:=0;
end;

function THetBitmap.AbsError(const other:TBitmap):single;
var sum:double;
begin
  if(other.PixelFormat<>PixelFormat)or(other.Width<>Width)or(other.Height<>Height)then
    raise Exception.Create('THetBitmap.SNR() different sizes or pixelformats');

  sum:=0;
  PixelOp2(other,
    function(a,b:cardinal):cardinal
    begin
      result:=a;
      sum:=sum+abs((a shr  0 and $ff)-(b shr  0 and $ff))
              +abs((a shr  8 and $ff)-(b shr  8 and $ff))
              +abs((a shr 16 and $ff)-(b shr 16 and $ff))
              +abs((a shr 24 and $ff)-(b shr 24 and $ff))
    end
  );
  result:=sum/(width*height*Components);
end;

function THetBitmap.MSE(const other:TBitmap):single;
var sum:double;
begin
  if(other.PixelFormat<>PixelFormat)or(other.Width<>Width)or(other.Height<>Height)then
    raise Exception.Create('THetBitmap.MSE() different sizes or pixelformats');

  sum:=0;
  PixelOp2(other,
    function(a,b:cardinal):cardinal
    begin
      result:=a;
      sum:=sum+sqr((a shr  0 and $ff)-(b shr  0 and $ff))
              +sqr((a shr  8 and $ff)-(b shr  8 and $ff))
              +sqr((a shr 16 and $ff)-(b shr 16 and $ff))
              +sqr((a shr 24 and $ff)-(b shr 24 and $ff))
    end
  );
  result:=sum/(width*height*Components);
end;

function THetBitmap.PSNR(const other:TBitmap):single;
var e:single;
begin
  e:=mse(other);
  if e=0 then result:=100
         else result:=10*Log10(sqr($100)/e);
end;

////////////////////////////////////////////////////////////////////////////////
// Save/Load                                                                  //
////////////////////////////////////////////////////////////////////////////////

procedure THetBitmap.LoadFromData(const AData; const AWidth, AHeight, ABitCount: integer);
var p:pbyte;y,ls:integer;
begin
  if not(ABitCount in[8,16,24,32])then
    raise Exception.Create('TBitmap.FromRaw() invalid bitcount:'+het.utils.tostr(ABitCount)+' (8,16,24,32 are valid)');

  Components:=ABitCount shr 3;
  Width:=AWidth;
  Height:=AHeight;

  ls:=AWidth*Components;
  p:=@AData;
  for y:=0 to Height-1 do begin
    move(p^,ScanLine[Height-1-y]^,ls);
    inc(p,ls);
  end;
end;

procedure THetBitmap.SaveToData(var AData);
var p:pbyte;y,ls:integer;
begin
  p:=@AData;
  ls:=Width*Components;
  for y:=0 to Height-1 do begin
    move(ScanLine[Height-1-y]^,p^,ls);
    inc(p,ls);
  end;
end;

procedure JPGLoadFromStream(const bmp:TBitmap;const stream:TStream);
var jp:TJPEGImage;
begin
  jp:=TJPEGImage.Create;
  try
    jp.LoadFromStream(stream);
    bmp.Width:=0;bmp.Height:=0;

    if jp.Grayscale then begin
      bmp.PixelFormat:=pf8bit;
      bmp.Palette:=GrayPalette;
    end else
      bmp.PixelFormat:=pf24bit;

    bmp.Width:=jp.Width;bmp.Height:=jp.Height;
    bmp.Canvas.Draw(0,0,jp);
  finally
    jp.Free;
  end;
end;

procedure JPGSaveToStream(const bmp:TBitmap;const stream:TStream;const quality:integer);
var jp:TJPEGImage;
begin
  jp:=TJPEGImage.Create;
  try
    jp.Grayscale:=bmp.PixelFormat=pf8bit;
    jp.CompressionQuality:=EnsureRange(quality, low(TJpegQualityRange), high(TJpegQualityRange));
    jp.Assign(bmp);
    jp.Compress;
    jp.SaveToStream(stream);
  finally
    jp.Free;
  end;
end;

procedure PNGLoadFromStream(const bmp:TBitmap;const stream:TStream);
begin
  with TPngImage.Create do try
    LoadFromStream(stream);
    AssignTo(bmp);
    case bmp.PixelFormat of
      pf1bit,
      pf4bit,
      pf8bit,
      pf15bit,
      pf16bit,
      pf24bit:bmp.Components:=3;
      pf32bit:bmp.Components:=4;
    else raise Exception.Create('het.bitmap.PNGLoadFromFile() unknown pixel format');
    end;
  finally
    free;
  end;
end;

procedure PNGSaveToStream(const bmp:TBitmap;const stream:TStream;const quality:integer);
var png:TPNGImage;
begin
  png:=TPNGImage.Create;
  try
    png.Assign(bmp);
    png.CompressionLevel:=EnsureRange(Quality div 10,0,9);
    png.SaveToStream(stream);
  finally
    png.Free;
  end;
end;

procedure GIFLoadFromStream(const bmp:TBitmap;const stream:TStream);
begin
  with TGifImage.Create do try
    LoadFromStream(stream);
    bmp.Components:=3;
    bmp.Width:=Images[0].Bitmap.Width;
    bmp.Height:=Images[0].Bitmap.Height;
//    bmp.Clear($808080);
    Images[0].Draw(bmp.Canvas,rect(0,0,bmp.Width,bmp.Height),false,false);
  finally
    free;
  end;
end;

procedure GIFSaveToStream(const bmp:TBitmap;const stream:TStream);
begin
  raise Exception.Create('GIFSaveToStream() not implemented yet');
end;

procedure THetBitmap.LoadFromStream2(const st:TStream);
var sign:RawByteString;
  function Check(const s:RawByteString):boolean;
  begin result:=LeftStr(sign,length(s))=s;end;
begin
  setlength(sign,32);
  if st.Size-st.Position>=length(sign)then begin
    st.ReadBuffer(sign[1],length(sign));
    st.Seek(-length(sign),soCurrent);
  end else
    sign:='';

  if check('BM')then begin
    LoadFromStream(st);
  end else if Check(#$FF#$D8)then begin
    JPGLoadFromStream(self,st);
  end else if Check('DDS ')then begin
    DDSLoadFromStream(self,st);
  end else if copy(sign,2,3)='PNG' then begin
    PNGLoadFromStream(self,st);
  end else if Check('HJP ')then begin
    HJPLoadFromStream(self,st);
  end else if Check('SIMI')then begin
    AceLoadFromStream(self,st);
  end else if Check('GIF8')then begin
    GIFLoadFromStream(self,st);
{  end else if Check('GLT ')then begin
    GLTLoadFromStream(self,st,0);}
  end else if(Copy(sign,2,1)=#0)or(Copy(sign,2,1)=#1)and(charn(sign,17)in[#8,#16,#24,#32])then begin//tga nopalette/palette, bitcount
    TGALoadFromStream(self,st);
  end else begin
    width:=0;height:=0;PixelFormat:=pf24bit;
  end;
end;

{function THetBitmap.MotionEstimate(const ATarget: TBitmap): TArray<TSmallPoint>;
begin

end;}

procedure THetBitmap.SaveToStream2(const st:TStream;const Extension:ansistring;const Quality:integer;const YUV:boolean);
var ext:AnsiString;
begin
  ext:=uc(Extension);if charn(ext,1)='.' then delete(ext,1,1);
  if ext='BMP'then begin
    SaveToStream(st)
  end else if ext='JPG'then begin
    JPGSaveToStream(self,st,Quality);
  end else if ext='TGA'then begin
    TGASaveToStream(self,st);
  end else if ext='PNG'then begin
    PNGSaveToStream(self,st,Quality);
  end else if ext='DDS'then begin
    DDSSaveToStream(self,st);
  end else if ext='ACE'then begin
    ACESaveToStream(self,st);
  end else if ext='HJP'then begin
    HjpSaveToStream(Self,st,Quality,YUV);
  end else if ext='GIF'then begin
    GIFSaveToStream(Self,st);
{  end else if ext='GLT'then begin
    GLTSaveToStream(self,st);}
  end else
    raise Exception.Create('THetBitmap.SaveToStream2() unknown file format '''+extension+'''');
end;


procedure THetBitmap.LoadFromStr(const data: RawByteString);
var st:TRawStream;
begin
  st:=TRawStream.Create(data);
  try
    LoadFromStream2(st);
  finally
    st.Free;
  end;
end;

function THetBitmap.SaveToStr(const Extension:ansistring;const Quality:integer;const YUV:boolean): RawByteString;
var st:TRawStream;
begin
  st:=TRawStream.Create('');
  try
    SaveToStream2(st,Extension,Quality,YUV);
    result:=st.DataString;
  finally
    st.Free;
  end;
end;

procedure THetBitmap.LoadFromFile2(const fn:string);
begin
  LoadFromStr(TFile(fn));
end;

procedure THetBitmap.SaveToFile2(const fn:string;const Quality:integer=_DefaultQuality;const YUV:boolean=_DefaultYUV);
begin
  TFile(fn).Write(SaveToStr(ExtractFileExt(fn),Quality,YUV));
end;

function grayDelta(a,b:Pointer):integer;inline;
begin
  result:=PCardinal(a)^ shr  2 and $3f-PCardinal(b)^ shr  2 and $3f+
          PCardinal(a)^ shr  9 and $7f-PCardinal(b)^ shr  9 and $7f+
          PCardinal(a)^ shr 18 and $3f-PCardinal(b)^ shr 18 and $3f;
  if result<0 then result:=-result;
end;

procedure THetBitmap.DeinterlaceBobWeave(var Dst:tbitmap;const Frame:integer);

  procedure BobWeave(const Src,Dst:TBitmap;const frame:integer);
  var x,y,delta,Pair:integer;
      pSrc,pDst,pDst2,pSrc2:pcardinal;
      linesize:integer;
      w:integer;
  begin
    linesize:=Src.Width shl 2;
    w:=Src.Width;
    for y:=1 to Src.Height shr 1-2 do begin
//      pSrc:=Src.ScanLine[y+Frame*h2];
      pSrc:=Src.ScanLine[y shl 1+Frame];
      pDst:=Dst.ScanLine[y shl 1+Frame];

      pDst2:=pDst;
      if Frame=0 then pinc(pDst2,linesize)
                 else pdec(pDst2,linesize);

      pSrc2:=pSrc;
      if Frame=0 then pinc(pSrc2,linesize)
                 else pdec(pSrc2,linesize);

      if Frame=0 then Pair:=linesize
                 else Pair:=-linesize;
      for x:=0 to w-1 do begin
        delta:=grayDelta(pDst,pSrc)+grayDelta(pDst2,pSrc2);

        if(delta>=24)then begin//bob
          pDst^:=pSrc^;
          pDst2^:=pSrc^shr 1 and $7f7f7f+pCardinal(pSucc(pSrc,Pair shl 1))^shr 1 and $7f7f7f;
        end else begin//weave
          pDst^:=pSrc^ shr 1 and $7f7f7f+pDst^ shr 1 and $7f7f7f;//weave blur
{         pDst^:=(pSrc^ and $ff00ff+pDst^ and $ff00ff*7+$3003)shr 3 and $ff00ff+
                 (pSrc^ and $00ff00+pDst^ and $00ff00*7+ $300)shr 3 and $ff00;}
//          pDst^:=pSrc^;
        end;

        inc(pDst);
        inc(pDst2);
        inc(pSrc);
        inc(pSrc2);
      end;
    end;
  end;

begin
  PixelFormat:=pf32bit;
  if Dst=nil then
    Dst:=TBitmap.Create;
  Dst.PixelFormat:=PixelFormat;
  Dst.Width:=Width;
  Dst.Height:=Height;
  BobWeave(Self,Dst,Frame);
end;

procedure THetBitmap.Diff8(var Ref,Diff:TBitmap);
var i:integer;
    pSrc,pRef,pDiff:PByte;
begin
  if Ref=nil then Ref:=TBitmap.Create;
  Ref.Components:=Components;
  Ref.Width:=Width;
  Ref.Height:=Height;

  if Diff=nil then Diff:=TBitmap.Create;
  Diff.Components:=Components;
  Diff.Width:=Width;
  Diff.Height:=Height;

  pSrc:=ScanLine[Height-1];
  pDiff:=Diff.ScanLine[Height-1];
  pRef:=Ref.ScanLine[Height-1];
  for i:=0 to ImageSize-1 do begin
    pDiff^:=(pSrc^-pRef^+$100)shr 1;
    inc(pSrc);inc(pRef);inc(pDiff);
  end;
end;

procedure THetBitmap.Diff8Add(var Ref:TBitmap);
var i:integer;
    pDiff,pRef:PByte;
begin
  if Ref=nil then Ref:=TBitmap.Create;
  Ref.PixelFormat:=PixelFormat;
  Ref.Width:=Width;
  Ref.Height:=Height;

  pDiff:=ScanLine[Height-1];
  pRef:=Ref.ScanLine[Height-1];
  for i:=0 to ImageSize-1 do begin
    pDiff^:=EnsureRange((pRef^+pDiff^shl 1-$100),0,255);
    inc(pDiff);inc(pRef);
  end;

end;

procedure THetBitmap.CopyTo(var Dst:TBitmap);
begin
  if Dst=nil then Dst:=TBitmap.Create;
  Dst.Components:=Components;
  Dst.Width:=Width;
  Dst.Height:=Height;
  Dst.Canvas.Draw(0,0,self);
end;

procedure ScreenShot(var Dst:TBitmap;const MonitorNum:integer=0);
var dc:integer;
begin
  with Screen.Monitors[monitorNum]do begin
    if Dst=nil then
      Dst:=TBitmap.Create;
    Dst.PixelFormat:=pf24bit;
    Dst.Width:=Width;
    Dst.Height:=Height;
    dc:=GetWindowDC(GetDesktopWindow);
    BitBlt(Dst.canvas.handle,0,0,Dst.Width,Dst.Height,dc,Left,Top,srccopy);
    DeleteObject(dc);
  end;
end;

procedure TBlurBuf.Reset(Size,ClearValue:byte);
var i:integer;
begin
  setlength(inbuf,Size);
  invInbufLength:=1/size;
  for i:=0 to High(inbuf)do inbuf[i]:=ClearValue;
  bufp:=0;
  sum:=Size*ClearValue;

  setlength(outbuf,{Size shr }1);
  for i:=0 to High(inbuf)do inbuf[i]:=0;
end;

function TBlurBuf.Feed(value:integer):integer;
begin
  inc(bufp);if bufp>high(inbuf)then bufp:=0;
  sum:=sum-inbuf[bufp]+value;
  inbuf[bufp]:=value;

  inc(outbufp);if outbufp>high(outbuf)then outbufp:=0;
  outbuf[outbufp]:=round(sum*invInbufLength);
  result:=outbuf[outbufp];
end;

procedure THetBitmap.HBlurAvg(const WindowSize: integer);

  procedure _8bit;
  var buf:TBlurBuf;
      i,x,y:integer;
      p:PByte;
      Half:integer;
  begin
    Half:=(WindowSize-1) shr 1;
    for y:=0 to Height-1 do begin
      buf.Reset(WindowSize,0);
      p:=ScanLine[y];
      for x:=0 to Half-1 do buf.Feed(p^);
      for x:=0 to Half-1 do begin buf.Feed(p^);inc(p)end;
      for x:=0 to width-1-half-1 do begin pbyte(ppred(p,Half))^:=buf.Feed(p^);inc(p)end;
      dec(p);i:=p^;for x:=0 to Half-1 do begin pbyte(ppred(p,Half))^:=buf.Feed(i);inc(p)end;
    end;
  end;

begin
  _AdjustPixelFormat(self);
  if WindowSize<=1 then exit;
  case Components of
    1:_8bit;
    else raise Exception.Create('Not implemented');
  end;
end;

procedure THetBitmap.VBlurAvg(const WindowSize: integer);

  procedure _8bit;
  var buf:TBlurBuf;
      i,x,y,ls:integer;
      p:PByte;
      Half,HalfLs:integer;
  begin
    Half:=(WindowSize-1) shr 1;
    ls:=ScanLineSize;
    HalfLs:=Half*ls;
    for x:=0 to Width-1 do begin
      buf.Reset(WindowSize,0);
      p:=ScanLine[Height-1];inc(p,x);
      for y:=0 to Half-1 do buf.Feed(p^);
      for y:=0 to Half-1 do begin buf.Feed(p^);inc(p,ls)end;
      for y:=0 to Height-1-half-1 do begin pbyte(ppred(p,HalfLs))^:=buf.Feed(p^);inc(p,ls)end;
      dec(p,ls);i:=p^;for y:=0 to Half-1 do begin pbyte(ppred(p,HalfLs))^:=buf.Feed(i);inc(p,ls)end;
    end;
  end;

begin
  _AdjustPixelFormat(self);
  if WindowSize<=1 then exit;
  case Components of
    1:_8bit;
    else raise Exception.Create('Not implemented');
  end;
end;

function THetBitmap.AlphaIsOne: boolean;
var x,y:integer;
    p:pbyte;
begin
  if components<4 then exit(true);
  for y:=0 to Height-1 do begin
    p:=pSucc(ScanLine[y],3);
    for x:=0 to Width-1 do begin
      if p^<>$ff then exit(false);
      inc(p,4);
    end;
  end;
  result:=true;
end;

procedure THetBitmap.BlurAvg(const WindowSize: integer);
begin
  HBlurAvg(WindowSize);
  VBlurAvg(WindowSize);
end;


function THetBitmap.BrightestPixelPos: TPoint;
var tmp:TBitmap;
    y,x:integer;
    p:pbyte;
    maxval:integer;
begin
  if Components=1 then begin
    maxval:=-1;
    result:=point(-1,-1);
    for y:=0 to Height-1 do begin
      p:=scanline[y];
      for x:=0 to Width-1 do begin
        if p^>maxVal then begin
          maxval:=p^;
          Result.X:=x;Result.Y:=y;
          if maxval=$FF then exit;
        end;
        inc(p);
      end;
    end;
  end else begin
    tmp:=GrayScaleF;
    result:=tmp.BrightestPixelPos;
    FreeAndNil(tmp);
  end;
end;

function THetBitmap.GetPix(const x, y: integer): integer;
begin
  case Components of
    1:result:=pbyte(psucc(ScanLine[y],x))^;
    4:result:=pinteger(psucc(ScanLine[y],x shl 2))^;
    2:result:=pword(psucc(ScanLine[y],x shl 1))^;
  else
    result:=pword(psucc(ScanLine[y],x*3))^+pbyte(psucc(ScanLine[y],x*3+2))^shl 16;
  end;
end;

procedure THetBitmap.SetPix(const x, y, c: integer);
begin
  case Components of
    1:pbyte(psucc(ScanLine[y],x))^:=c;
    4:pinteger(psucc(ScanLine[y],x shl 2))^:=c;
    2:pword(psucc(ScanLine[y],x shl 1))^:=c;
  else
    pword(psucc(ScanLine[y],x*3))^:=c;
    pbyte(psucc(ScanLine[y],x*3+2))^:=c shr 16;
  end;
end;

function THetBitmap.GetPixClamped(const x, y: integer): integer;
begin
  result:=GetPix(EnsureRange(x,0,Width-1),EnsureRange(y,0,Height-1));
end;

procedure THetBitmap.SetPixClamped(const x, y, c: integer);
begin
  SetPix(EnsureRange(x,0,Width-1),EnsureRange(y,0,Height-1),c);
end;

function THetBitmap.PixelOffset(const ATarget:TBitmap):tpoint;

  function calcDelta(src,dst:TArray<integer>):integer;
  type TRec=record pos:integer;diff:single end;
  var st,en,st2,en2:integer;
      i,j,k,diff:integer;
      res:THetArray<TRec>;
      tmp:TRec;
  begin
    st:=-(length(dst)div 2);
    en:=length(src)-length(dst)div 2-1;
    for i:=st to en do begin
      tmp.pos:=i;
      st2:=EnsureRange(i,0,Length(src)-1);
      en2:=EnsureRange(i+length(dst)-1,0,Length(src)-1);
      diff:=0;
      for j:=st2 to en2-1 do begin //src pos
        k:=j-i;//dst pos
        diff:=diff+abs(src[j]-dst[k])
      end;
      tmp.diff:=(diff/(en2-st2))+abs(i);
      res.Append(tmp);
    end;

    tmp:=res.FItems[0];
    for i:=1 to res.FCount-1 do begin
      if tmp.diff>res.FItems[i].diff then tmp:=res.fitems[i];
    end;
    result:=tmp.pos;
  end;

  procedure Derive(const arr:TArray<integer>);
  var i:integer;
  begin
    for i:=1 to length(arr)-1 do
      arr[i-1]:=arr[i]-arr[i-1];
    arr[Length(arr)-1]:=0;
  end;

var SrcH,SrcV,DstH,DstV:TArray<Integer>;
begin
  if Components=1 then begin
    SrcH:=PixelSumX;SrcV:=PixelSumY;
  end else with GrayScaleF do begin
    SrcH:=PixelSumX;SrcV:=PixelSumY;
    Free;
  end;

  with ATarget do if Components=1 then begin
    DstH:=PixelSumX;DstV:=PixelSumY;
  end else with GrayScaleF do begin
    DstH:=PixelSumX;DstV:=PixelSumY;
    Free;
  end;

  Derive(SrcH);
  Derive(DstH);
  Derive(SrcV);
  Derive(DstV);

  result.X:=calcDelta(SrcH,DstH);
  result.Y:=calcDelta(SrcV,DstV);
end;

function THetBitmap.MotionEstimate8x8(const ATarget: TBitmap): TArray<TSmallPoint>;

  function SumAbsDiff(src,dst:pointer;bytes:integer):integer;
  var i:integer;
  begin
    result:=0;
    for i:=0 to bytes-1 do begin
      result:=result+abs(PByte(src)^-PByte(dst)^);
      pinc(src);pinc(dst);
    end;
  end;

var xBlocks,yBlocks:integer;
    PixelSize,LineSize,HBlockSize:integer;
    H,W,xo,yo,xb,yb,xd,yd,resX,resY,n,y:integer;
    pSrc,pDst:Pointer;
    minDiff,diff:integer;

const range=50;
begin
  PixelSize:=Components;LineSize:=ScanLineSize;
  HBlockSize:=PixelSize shl 3;
  xBlocks:=ATarget.Width shr 3;yBlocks:=ATarget.Height shr 3;
  W:=xBlocks shl 3;H:=yBlocks shl 3;

  resX:=0;resY:=0;

  setlength(result,xBlocks*yBlocks);n:=0;
  for yb:=0 to yBlocks-1 do begin
    yo:=yb shl 3;
    for xb:=0 to xBlocks-1 do begin
      xo:=xb shl 3;
      pSrc:=pointer(integer(ScanLine[0])-yo*LineSize+xo*PixelSize);
      minDiff:=high(integer);
      for yd:=EnsureRange(yo-range,0,H-8) to EnsureRange(yo+range,0,H-8)do begin
        for xd:=EnsureRange(xo-range,0,W-8) to EnsureRange(xo+range,0,W-8)do begin
          diff:=0;
          pSrc:=pointer(integer(ScanLine[0])-yd*LineSize+xd*PixelSize);
          for y:=0 to 7 do begin
            diff:=diff+SumAbsDiff(pSrc,pDst,HBlockSize);
            if diff>mindiff then break;
            pDec(pSrc,ScanLineSize);
            pDec(pDst,ScanLineSize);
          end;
          if(diff<minDiff)or((diff=minDiff)and(abs(xd)+abs(yd)<abs(resX)+abs(resY)))then begin
            minDiff:=diff;
            resX:=xd;
            resY:=yd;
          end;
        end;
      end;
      result[n]:=SmallPoint(resX,-resY);
      inc(n);

      //debug
      Canvas.Font.Color:=clWhite;
      Canvas.Line(xo+4,yo+4,xo+resX+4,yo+resY+4);
    end;
  end;

end;

procedure THetBitmap.CalcBlueboxAlpha(const clrBGR, tolHue, tolSat,tolVal: integer);
var i,c:integer;
    refHue,refSat,refVal:integer;
    p:pinteger;
begin
  Components:=4;
  if empty then exit;

  with TRGBQuad(BGR2HSV(clrBGR))do begin
    refHue:=rgbBlue;
    refSat:=rgbGreen;
    refVal:=rgbRed;
  end;

  p:=ScanLine[Height-1];
  for i:=0 to Width*Height-1 do begin
    c:=p^;
    with TRGBQuad(BGR2HSV(c))do begin
      if(abs(refHue-rgbBlue)<tolHue)and
        (abs(refSat-rgbGreen)<tolSat)and
        (abs(refVal-rgbRed)<tolVal)then
          PRGBQuad(p).rgbReserved:=0
        else
          PRGBQuad(p).rgbReserved:=$ff;
    end;
    inc(p);
  end;
end;

procedure THetBitmap.VisualizeAlpha(const gradient:boolean=true);
var p:PInteger;
    i:integer;
begin
  if empty then exit;
  components:=4;
  p:=ScanLine[Height-1];
  for i:=0 to Width*Height-1 do begin
    if gradient then
      p^:=RGBLerp($FF00FF,p^,p^ shr 24)
    else
      if p^shr 24<$80 then p^:=$ff00ff;
    inc(p);
  end;
end;


////////////////////////////////////////////////////////////////////////////////
// CanvasHelper                                                               //
////////////////////////////////////////////////////////////////////////////////

procedure TCanvasHelper.SetBrush(const AStyle:TBrushStyle;const AColor:TColor=clWhite);
begin
  with Brush do begin
    Color:=AColor;
    Style:=AStyle;
  end;
end;

procedure TCanvasHelper.SetPen(const AStyle:TPenStyle;const AColor:TColor=clBlack);
begin
  with Pen do begin
    Color:=AColor;
    Style:=AStyle;
  end;
end;

procedure TCanvasHelper.TextOut(const P:TPoint;const Text:string);
begin
  TextOut(p.X,p.Y,Text);
end;

procedure TCanvasHelper.MoveTo(const p:TPoint);
begin
  MoveTo(p.X,p.Y);
end;

procedure TCanvasHelper.LineTo(const p:TPoint);
begin
  LineTo(p.X,p.Y);
end;

procedure TCanvasHelper.Line(const x0,y0,x1,y1:integer);
begin
  MoveTo(x0,y0);
  LineTo(x1,y1);
end;

procedure TCanvasHelper.Line(const p0,p1:TPoint);
begin
  MoveTo(p0.X,p0.Y);
  LineTo(p1.X,p1.Y);
end;


procedure TCanvasHelper.MoveTo(const p:TV2f);
begin
  with round(p)do MoveTo(X,Y);
end;

procedure TCanvasHelper.LineTo(const p:TV2f);
begin
  with round(p)do LineTo(X,Y);
end;

procedure TCanvasHelper.Line(const p0,p1:TV2f);
begin
  with round(p0)do MoveTo(X,Y);
  with round(p1)do LineTo(X,Y);
end;

procedure TCanvasHelper.FillRectOutside(const rInside,rOutside:TRect);
begin
  FillRect(rect(rOutside.Left,rOutside.Top  ,rOutside.Right,rInside.Top    ));
  FillRect(rect(rOutside.Left,rInside.Bottom,rOutside.Right,rOutside.Bottom));
  FillRect(rect(rOutside.Left,rInside.Top   ,rInside.Left  ,rInside.Bottom ));
  FillRect(rect(rInside.Right,rInside.Top   ,rOutside.Right,rInside.Bottom ));
end;

procedure TCanvasHelper.DrawTiled(const g: TGraphic; const r: TRect; const ofs: TPoint);
var r2:TRect;
begin
  if(g.Width<=0)or(g.Height<=0)then exit;
  r2.TopLeft:=ofs;
  r2.Left:=r2.Left-ofs.x div g.Width *g.Width ;r2.Left:=r2.Left-g.Width ;if r2.Left<=-g.Width  then r2.Left:=r2.Left+g.Width ;
  r2.Top :=r2.Top -ofs.y div g.Height*g.Height;r2.Top :=r2.Top -g.Height;if r2.Top <=-g.Height then r2.Top :=r2.Top +g.Height;

  Draw(r2.Left,r2.Top,g);
  {...}
end;

procedure TCanvasHelper.DrawRect(r:trect);
begin
  dec(r.Right);dec(r.Bottom);
  if(r.Right<r.Left)or(r.Bottom<r.Top)then exit;
  MoveTo(r.TopLeft);
  LineTo(r.Right,r.Top);
  LineTo(r.BottomRight);
  LineTo(r.Left,r.Bottom);
  LineTo(r.TopLeft);
end;

procedure TCanvasHelper.DotLine(x1,y1,x2,y2:integer;co:tcolor);
var i:integer;
begin
  if x1=x2 then begin
    if y1>y2 then swap(y1,y2);
    for i:=y1 to y2 do if((i+x1) and 1)=0 then Pixels[x1,i]:=co;
  end else if y1=y2 then begin
    if x1>x2 then swap(x1,x2);
    for i:=x1 to x2 do if((i+y1) and 1)=0 then Pixels[i,y1]:=co;
  end else
    raise Exception.Create('DotLine must be either horizontal or vertical.');
end;

procedure TCanvasHelper.DrawGraph(const AOrigin, ADirection: TPoint;
  const AScale: single; const ASeries: TArray<integer>);
begin
  DrawGraph(AOrigin,ADirection,AScale,ASeries,0,Length(ASeries)-1);
end;

procedure TCanvasHelper.DrawGraph(const AOrigin,ADirection:TPoint;
  const AScale: single; const ASeries: TArray<integer>; const ARangeStart,
  ARangeEnd: integer);
var Up,Base:TPoint;
    i,v:integer;
    first:boolean;
begin
  if length(ASeries)=0 then exit;

  with ADirection do Up:=point(y,-x);
  Base:=AOrigin;
  first:=true;
  for i:=ARangeStart to ARangeEnd do begin
    if(i>=0)and(i<length(ASeries))then begin
      v:=ASeries[i];
      with point(Base.x+round(Up.X*v*AScale),Base.Y+round(Up.Y*v*AScale))do
        if not first then
          LineTo(x,y)
        else begin
          MoveTo(x,y);
          first:=false;
        end;
    end;
    with ADirection do Base:=Point(Base.X+X,Base.Y+Y);
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// CanvasHelper.HetDrawText                                                   //
////////////////////////////////////////////////////////////////////////////////

procedure TTextColors.Clear;
begin
  Bkg:=clNone;
  Text:=clWindowText;
  Shadow:=clNone;
  Outline:=clNone;
end;

procedure TDrawTextParams.Clear;
begin
  HAlign:=haLeft;
  VAlign:=vaTop;
  cText.Clear;
  cSelected.Clear;
  cSelected.Bkg:=clHighlight;
  cSelected.Text:=clHighlightText;
  WordWrap:=false;
  SelStart:=0;
  SelLength:=0;
end;

procedure TCanvasHelper.DrawText(const AParams:TDrawTextParams;const ARect:TRect;const AText:ansistring;const ASyntax:ansistring='');

type TLineRec=record st,len,wi:integer;end;
var Lines:THetArray<TLineRec>;

  procedure SplitLines;
  var NextPos,sp,en,numFit,width,i:integer;
      lr,lr2:TLineRec;
      ww:boolean;
      dx:array[0..4095]of integer;{!!!!}
      size:TSize;
  begin
    ww:=AParams.WordWrap;
    Width:=ARect.Right-ARect.Left;
    lr.st:=1;
    lr.wi:=-1;
    while lr.st<=Length(AText)do begin
      //find next newline
      nextPos:=pos(#10,AText,[],lr.st);
      if nextPos<=0 then begin
        nextPos:=Length(AText)+1;
        lr.len:=nextPos-lr.st;
      end else begin
        lr.len:=NextPos-lr.st;
        if CharN(Atext,NextPos-1)=#13 then Dec(lr.len);
        inc(nextPos);
      end;
      //act line is at actPos:Len
      if ww and(lr.len>0)then begin
        sp:=lr.st;
        en:=sp+lr.len;
        while sp<en do begin
          GetTextExtentExPointA(Handle, PAnsiChar(@AText[sp]), en-sp, Width, @numFit, @dx, size);

          //word_break
          if charmapEnglish[charn(AText,sp+numFit)]in wordsetSimple then begin
            i:=numFit;
            while charmapEnglish[charn(AText,sp+numFit-1)]in wordsetSimple do begin
              dec(numFit);
              if numFit<=0 then begin
                numFit:=i;
                break;
              end;
            end;
          end;

          //no space at beginning (after a split)
          if(sp>1)and(CharN(AText,sp)=' ')then begin inc(sp);dec(numFit);end;

          //take away last space (Editnel veszelyes!!!!)
          i:=numFit;if CharN(AText,sp+i-1)=' ' then dec(i);
          //add line
          lr2.st:=sp; lr2.len:=i; lr2.wi:=dx[i-1]; Lines.Append(lr2);

          //advance
          inc(sp,numFit);
        end;

      end else
        Lines.Append(lr);

      lr.st:=nextPos;
    end;
  end;

  function isNumber:boolean;
  var val:Extended;
  begin
    result:=TryStrToFloat(AText,val);
  end;

  function GetLineWidth(idx:integer):integer;
  var size:TSize;
  begin with Lines.FItems[idx]do begin
    if wi<0 then begin
      GetTextExtentPointA(Handle,@AText[st],len,size);
      wi:=size.cx;
    end;
    result:=wi;
  end;end;

var i,x,y,th,shadowDist,xx,yy:integer;
begin with AParams do begin
  SplitLines;

  th:=TextHeight('W');
  shadowDist:=Max(1,th div 16);

  //Align Vertical
  case VAlign of
    vaCenter: y:=(ARect.Top+ARect.Bottom-Lines.Count*th)div 2;
    vaBottom: y:=ARect.Bottom-Lines.Count*th;
  else y:=ARect.Top;end;

  for i:=0 to Lines.Count-1 do with lines.FItems[i]do begin

    if(y<ARect.top-th)then begin inc(y,th);Continue end else
    if(y>=ARect.bottom)then Break;

    //Align Horizontal
    if(HAlign=haRight)or((HAlign=haAuto)and isNumber)then begin
      x:=ARect.Right-GetLineWidth(i);
    end else if HAlign=haCenter then begin
      x:=(ARect.Left+ARect.Right-GetLineWidth(i))div 2;
    end else
      x:=ARect.Left;

    //Draw Shadow
    if(cText.Shadow<>clNone)then begin
      Brush.Style:=bsClear;
      Font.Color:=cText.Shadow;
      Windows.ExtTextOutA(Handle, X+shadowDist, Y+shadowDist, ETO_CLIPPED, @ARect, @AText[st], len, nil);
    end;

    //Draw outline
    if cText.Outline<>clNone then begin
      Brush.Style:=bsClear;
      Font.Color:=cText.Outline;
      for xx:=-1 to 1 do for yy:=-1 to 1 do if(xx<>0)or(yy<>0)then
        Windows.ExtTextOutA(Handle, X+xx*shadowDist, Y+yy*shadowDist, ETO_CLIPPED, @ARect, @AText[st], len, nil);
    end;

    //Draw text
    Font.Color:=cText.Text;
    if cText.Bkg<>clNone then SetBrush(bsSolid,cText.Bkg)
                         else Brush.Style:=bsClear;

    Windows.ExtTextOutA(Handle, X, Y, ETO_CLIPPED, @ARect, @AText[st], len, nil);

    inc(y,th)
  end;
end;end;

{ TGraphicHelper }

function TGraphicHelper.ToBitmap(const APixelFormat:TPixelFormat):TBitmap;
begin
  if Self=nil then exit(nil);
  result:=TBitmap.CreateNew(APixelFormat,Width,Height);
  result.Canvas.Draw(0,0,self);
end;

initialization
finalization
end.
