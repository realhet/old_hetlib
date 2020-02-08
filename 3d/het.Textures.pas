unit het.textures;//het.db

interface

uses windows, sysutils, math, classes, graphics, het.utils, het.objects,
  het.stream, opengl1x, het.Gfx, typinfo,
  forms,dialogs, gltImage, UMatrix;

type
  TTexture=class(THetObject)
  private
    FName:TName;
    FHandle:GLenum;
    FTarget:GLenum;
    FHeader:TGLTHeader;
    FPreview:RawByteString;
    FInvalid:Boolean;
    FLastBindTime:cardinal;
    procedure SetLastBindTime(const Value: cardinal);
  public
    destructor Destroy;override;
    procedure Clear;
    procedure LoadFromFile(const AFileName:AnsiString='');
    procedure LoadFromBitmap(const ABitmap:TBitmap;const AMapType:TGLTMapType;const AAlphaType:TGltAlphaType;const AGenerateMipmaps:boolean;const ANormalize:boolean);
    procedure LoadFromBitmapArray(const ABitmapArray:TBitmapArray;const AMapType:TGLTMapType;const AAlphaType:TGltAlphaType;const AGenerateMipmaps:boolean);
    procedure LoadNew(const AWidth,AHeight,ADepth:integer;const AMapType:TGLTMapType;const AAlphaType:TGltAlphaType;const AGenerateMipmaps:boolean;const AGrayBackround:boolean=true);
    function Handle:GLenum;
    procedure Bind(const Slot:integer;const ResizeFilter:TResizeFilter;const clamp:boolean);
    procedure UnBind(const Slot:integer);
    function Allocated:boolean;
    procedure Upload(const b:TBitmap);
    procedure CopyTexSubImage(x, y, w, h, components: integer);
    function Empty:boolean;
    procedure SetupTextureMatrix(const HFlip:boolean=false;const VFlip:boolean=false);
    function SizeMB:single;
  published
    property Name:TName read FName write SetName;

    property Width:word read FHeader.width write FHeader.width;
    property Height:word read FHeader.height write FHeader.height;
    property Depth:word read FHeader.depth;
    property MapType:TGLTMapType read FHeader.MapType;
    property AlphaType:TGLTAlphaType read FHeader.AlphaType;
    property Mipmapped:boolean read FHeader.GenerateMipMaps;
    property LastBindTime:cardinal read FLastBindTime write SetLastBindTime;
  end;

  TTextureCache=class(THetList<TTexture>)
  public
    constructor Create(const AOwner:THetObject);override;
    function GetByNameCached(const AName:ansistring):THetObject;override;
    property ByName;default;
    procedure glRestrictCount(cnt:integer);//csak ennyi marad benne, azok amelyeket a legkesobb bindeltek
    procedure glRestrictSize(MBytes: single);
    function SizeMB:single;
  end;

  TARBProgram=class(THetObject)
  private
    FName:ansistring;
    FCode:ansistring;
    FHandle:TGLEnum;
    procedure SetCode(const Value:ansistring);
    function GetTarget:TGLEnum;virtual;abstract;
    procedure FreeHandle;
  public
    destructor Destroy;override;
    property Target:TGLEnum read GetTarget;
    procedure Bind;
    procedure UnBind;
    function Handle:TGLEnum;
  published
    property Name:ansistring read FName;
    property Code:ansistring read FCode write SetCode;
  end;

  TFragmentProgram=class(TARBProgram)
  private
    function GetTarget:TGLEnum;override;
  end;

  TVertexProgram=class(TARBProgram)
  private
    function GetTarget:TGLEnum;override;
  end;

  TFragmentProgramCache=class(THetList<TFragmentProgram>)
  private
  public
    function GetByNameCached(const AName:ansistring):THetObject;override;
    property ByName;default;
  end;

  TVertexProgramCache=class(THetList<TVertexProgram>)
  private
  public
    function GetByNameCached(const AName:ansistring):THetObject;override;
    property ByName;default;
  end;

const
  TextureCache:TTextureCache=nil;
  FPCache:TFragmentProgramCache=nil;
  VPCache:TFragmentProgramCache=nil;

function BitmapArrayTarget(const ba:TBitmapArray):GLenum;

function LoadARBProgram(target : GLenum; const programText : AnsiString):TGLEnum;

implementation

uses
  het.filesys;

type GlException=Exception;

procedure glRaiseError(const caller:ansistring);inline;
const Errors:array[$500..$505]of ansistring=('GL_INVALID_ENUM','GL_INVALID_VALUE',
  'GL_INVALID_OPERATION','GL_STACK_OVERFLOW','GL_STACK_UNDERFLOW','GL_OUT_OF_MEMORY');
var err:GLenum;
begin
  err:=glGetError;
  if err=GL_NO_ERROR then exit;
  Raise GlException.Create(caller+' '+Errors[err]);
end;

function BitmapArrayTarget(const ba:TBitmapArray):GLenum;
begin
  case BitmapArrayDimensions(ba) of
    1:result:=GL_TEXTURE_1D;
    2:result:=GL_TEXTURE_2D;
    3:result:=GL_TEXTURE_3D;
    6:result:=GL_TEXTURE_CUBE_MAP_ARB;
    else result:=0;
  end;
end;

{ TTexture }

{constructor TTexture.Create(const AOwner: THetObject; const AName: ansistring);
begin
  inherited Create(AOwner);
  FName:=AName;NotifyChange;
end;}

{$O-}
procedure TTexture.SetLastBindTime(const Value: cardinal);begin end;
{$O+}

procedure TTexture.SetupTextureMatrix(const HFlip:boolean=false;const VFlip:boolean=false);
var m:TM44f;
    sw,sh:single;
begin
  glMatrixMode(GL_TEXTURE);
  glLoadIdentity;
  m:=M44fIdentity;
  m[0,0]:=Width/Nearest2NSize(Width);
  m[1,1]:=Height/Nearest2NSize(Height);

  //Tiled-re nem jo!!!!
  sw:=m[0,0]/Width*0.5;
  sh:=m[1,1]/Height*0.5;

  if HFlip then begin
    m[3,0]:=m[0,0]-sw;
    m[0,0]:=-m[0,0];
  end else
    m[3,0]:=sw;

  if VFlip then begin
    m[3,1]:=m[1,1]-sh;
    m[1,1]:=-m[1,1];
  end else
    m[3,1]:=sh;

  m[0,0]:=m[0,0]*(Width -1)/Width ;
  m[1,1]:=m[1,1]*(Height-1)/Height;

  glMultMatrixf(@m);
  glMatrixMode(GL_MODELVIEW);
end;

function TTexture.SizeMB: single;
begin
  result:=Nearest2NSize(Width)*Nearest2NSize(Height)*(1/1024/1024);
end;

procedure TTexture.Clear;
begin
  if FHandle<>0 then begin
    glDeleteTextures(1,@FHandle);
    FHandle:=0;
    FTarget:=0;
//    FillChar(FHeader,sizeof(FHeader),0); ne itt
    setlength(FPreview,0);
    FInvalid:=False;
  end;
end;

destructor TTexture.Destroy;
begin
  Clear;
  inherited;
end;

procedure TTexture.LoadFromBitmapArray(const ABitmapArray:TBitmapArray;const AMapType:TGLTMapType;const AAlphaType:TGltAlphaType;const AGenerateMipmaps:boolean);
var error:ansistring;
begin
  error:=BitmapArrayValidate(ABitmapArray);
  if error<>'' then
    raise Exception.Create('TTexture.LoadFromBitmapArray : '+error);
  Clear;

  FTarget:=BitmapArrayTarget(ABitmapArray);
  glGenTextures(1,@FHandle);
  glBindTexture(FTarget,FHandle);

  BitmapArrayUpload(ABitmapArray,AMapType,AAlphaType,AGenerateMipmaps);

  //unbind kellene ide
end;

procedure TTexture.LoadFromBitmap(const ABitmap:TBitmap;const AMapType:TGLTMapType;const AAlphaType:TGltAlphaType;const AGenerateMipmaps:boolean;const ANormalize:boolean);
var ba:TBitmapArray;
begin
  setlength(ba,1);ba[0]:=ABitmap;

  FHeader.width:=ABitmap.Width;
  FHeader.height:=ABitmap.Height;
  FHeader.depth:=1;
  FHeader.MapType:=AMapType;
  FHeader.AlphaType:=AAlphaType;
  FHeader.GenerateMipMaps:=AGenerateMipmaps;

  if ANormalize then
    BitmapArrayNormalize(ba);

  LoadFromBitmapArray(ba,AMapType,AAlphaType,AGenerateMipmaps);
end;

procedure TTexture.LoadFromFile(const AFileName: AnsiString = '');
var ba:TBitmapArray;
begin
  Clear;
  try
    ba:=BitmapArrayLoad(AFileName,FHeader.MapType,FHeader.AlphaType,FHeader.GenerateMipMaps,FPreview);
  except
    on e:exception do raise Exception.Create(e.message+' File:"'+AFileName+'"');
  end;
  if ba=nil then raise Exception.Create('Cannot load texture "'+AFileName+'"');

  LoadFromBitmapArray(ba,FHeader.MapType,FHeader.AlphaType,FHeader.GenerateMipMaps);
end;

procedure TTexture.LoadNew(const AWidth,AHeight,ADepth:integer;const AMapType:TGLTMapType;const AAlphaType:TGltAlphaType;const AGenerateMipmaps:boolean;const AGrayBackround:boolean=true);
var ba:TBitmapArray;
    i:integer;
begin
  Clear;
  setlength(ba,ADepth);
  for i:=0 to high(ba)do begin
    ba[i]:=TBitmap.Create;
    case AMapType of
      mtColor_L,mtExact_X:ba[i].PixelFormat:=pf8bit;
      mtColor_LA,mtExact_XW,mtNormal_UV:ba[i].PixelFormat:=pf16bit;
      mtColor_RGB,mtExact_XYZ,mtNormal_UVH:ba[i].PixelFormat:=pf24bit;
    else ba[i].PixelFormat:=pf32bit;end;
    ba[i].width:=AWidth;
    ba[i].Height:=AHeight;
    FillChar(ba[i].ScanLine[ba[i].Height-1]^,ba[i].ImageSize,$80*ord(AGrayBackround));
  end;

  FHeader.width:=AWidth;
  FHeader.height:=AHeight;
  FHeader.depth:=ADepth;
  FHeader.MapType:=AMapType;
  FHeader.AlphaType:=AAlphaType;
  FHeader.GenerateMipMaps:=AGenerateMipmaps;

  try
    LoadFromBitmapArray(ba,AMapType,AAlphaType,AGenerateMipMaps);
  finally
//    BitmapArrayFree(ba);  ez freezodik a LoadFromBitmapArray-bol {ami nemmellesleg qrvanagy faszsag}
  end;
end;

function TTexture.Empty: boolean;
begin
  result:=FHandle=0;
end;

function TTexture.Handle:GLenum;
var berror:TBitmap;
//    sl:ansistring;
//    h,w:integer;
begin
  result:=FHandle;
  if result<>0 then exit;
  try
    LoadFromFile(Name);
    result:=FHandle;
  except
    FInvalid:=True;
    berror:=ErrorBitmap.Create;
    try
      LoadFromBitmap(berror,mtColor_RGBA,atGradient,true,false);
    finally
      berror.Free;
    end;
  end;
end;

function TTexture.Allocated: boolean;
begin
  result:=FHandle<>0;
end;

var _ActTextureBindTime:cardinal;//global

procedure TTexture.Bind(const Slot:Integer;const ResizeFilter:TResizeFilter;const clamp:boolean);
const
  Filters:array[TResizeFilter]of record mag,min:GLenum end=(
    (mag:GL_NEAREST;min:GL_NEAREST                 ),
    (mag:GL_LINEAR ;min:GL_LINEAR                  ),
    (mag:GL_LINEAR ;min:GL_LINEAR_MIPMAP_NEAREST   ),
    (mag:GL_LINEAR ;min:GL_LINEAR_MIPMAP_LINEAR    )
  );

var h,w:GLenum;
begin
  if assigned(glActiveTextureARB)then glActiveTextureARB(GL_TEXTURE0_ARB+Slot);

  h:=Handle;
  glBindTexture(FTarget,h);

  glEnable(FTarget);

  glTexParameterf(FTarget,GL_TEXTURE_MIN_FILTER,Filters[ResizeFilter].min);
  glTexParameterf(FTarget,GL_TEXTURE_MAG_FILTER,Filters[ResizeFilter].mag);

  if clamp then w:=GL_CLAMP_TO_EDGE
           else w:=GL_REPEAT;

  glTexParameterf(FTarget,GL_TEXTURE_WRAP_S,w);
  glTexParameterf(FTarget,GL_TEXTURE_WRAP_T,w);
  if FHeader.depth>1 then
    glTexParameterf(FTarget,GL_TEXTURE_WRAP_R,w);

  LastBindTime:=PostInc(_ActTextureBindTime);
end;

procedure TTexture.UnBind(const Slot:Integer);
begin
  if assigned(glActiveTextureARB)then glActiveTextureARB(GL_TEXTURE0_ARB+Slot);
  glDisable(FTarget);
end;

procedure TTexture.Upload(const b: TBitmap);
const mt:array[1..4]of TGLTMapType=(mtExact_X,mtExact_XW,mtExact_XYZ,mtExact_XYZW);
      fm:array[1..4]of GLenum=(GL_LUMINANCE,GL_LUMINANCE_ALPHA,GL_BGR,GL_BGRA);
var lastBinding:integer;
begin
  if b.Empty then LoadNew(2,2,1,mtColor_RGB,atGradient,false)else begin

    glGetIntegerv(GL_TEXTURE_BINDING_2D,@lastBinding);

    if(Nearest2NSize(b.Width)<>Nearest2NSize(Width))
    or(Nearest2NSize(b.Height)<>Nearest2NSize(Height))
    or(MapTypeComponents[MapType]<>b.Components)then
      LoadNew(Nearest2NSize(b.Width),Nearest2NSize(b.Height),1,mt[b.Components],atGradient,false);

    glBindTexture(GL_TEXTURE_2D,Handle);

    glTexSubImage2D(FTarget,0,0,0,b.Width,b.Height,fm[b.Components],GL_UNSIGNED_BYTE,b.Scanline[b.Height-1]);

    glBindTexture(GL_TEXTURE_2D,lastBinding);

    with FHeader do begin
      width:=b.Width;
      height:=b.Height;
      MapType:=mt[b.Components];
    end;

  end;
end;

procedure TTexture.CopyTexSubImage(x,y,w,h,components:integer);
const mt:array[1..4]of TGLTMapType=(mtExact_X,mtExact_XW,mtExact_XYZ,mtExact_XYZW);
      fm:array[1..4]of GLenum=(GL_LUMINANCE,GL_LUMINANCE_ALPHA,GL_BGR,GL_BGRA);
var lastBinding:integer;
begin
  if(w<=0)or(h<=0)then LoadNew(2,2,1,mtColor_RGB,atGradient,false)else begin

    glGetIntegerv(GL_TEXTURE_BINDING_2D,@lastBinding);

    if(Nearest2NSize(w)<>Nearest2NSize(Width))
    or(Nearest2NSize(h)<>Nearest2NSize(Height))
    or(MapTypeComponents[MapType]<>Components)then
      LoadNew(Nearest2NSize(W),Nearest2NSize(H),1,mt[Components],atGradient,false);

    glBindTexture(GL_TEXTURE_2D,Handle);

    glCopyTexSubImage2D(FTarget,0,0,0,x,y,w,h);

    glBindTexture(GL_TEXTURE_2D,lastBinding);

    with FHeader do begin
      width:=W;
      height:=H;
      MapType:=mt[Components];
    end;
  end;
end;


{ TTextureCache }

constructor TTextureCache.Create(const AOwner: THetObject);
begin
  inherited;
  ViewDefinition:='Name';
end;

function TTextureCache.GetByNameCached(const AName: ansistring): THetObject;
begin
  result:=TTexture.Create(self);
  TTexture(Result).FName:=AName;
  TTexture(Result).NotifyChange;
end;

procedure TTextureCache.glRestrictCount(cnt: integer);
var old:TArray<TTexture>;
    i:integer;
    t:TTexture;
begin
  with View['-LastBindTime']do for i:=0 to count-1 do begin
    if cnt<=0 then begin
      SetLength(old,length(old)+1);
      old[high(old)]:=TTexture(ByIndex[i]);
    end;
    dec(cnt);
  end;

  for t in old do t.Free;
end;

procedure TTextureCache.glRestrictSize(MBytes:single);
var old:TArray<TTexture>;
    i:integer;
    t:TTexture;
    actSize:single;
begin
  actSize:=0;
  with View['-LastBindTime']do for i:=0 to count-1 do begin
    actSize:=actSize+ByIndex[i].SizeMB;
    if actSize>MBytes then begin
      SetLength(old,length(old)+1);
      old[high(old)]:=ByIndex[i];
    end;
  end;

  for t in old do t.Free;
end;


function TTextureCache.SizeMB: single;
var t:TTexture;
begin
  result:=0;
  for t in self do result:=result+t.SizeMB;
end;

{ TARBProgram }

function LoadARBProgram(target : GLenum; const programText : AnsiString):TGLEnum;
  procedure Fuck(s:string);
  begin
    if s<>'' then
      raise Exception.Create(s);
  end;

var
   errPos : Integer;
   errString : AnsiString;
   info:array[0..3]of integer;
begin
  if (target = GL_VERTEX_PROGRAM_ARB) and not GL_ARB_vertex_program then
    raise Exception.Create('GL_ARB_vertex_program required!');
  if (target = GL_FRAGMENT_PROGRAM_ARB) and not GL_ARB_fragment_program then
    raise Exception.Create('GL_ARB_fragment_program required!');
  glGenProgramsARB(1, @result);
  glGetProgramivARB(target,GL_PROGRAM_BINDING_ARB,@info);

  try
    glBindProgramARB(target, result);
    glProgramStringARB(target, GL_PROGRAM_FORMAT_ASCII_ARB,Length(programText),PAnsiChar(programText));
    glGetIntegerv(GL_PROGRAM_ERROR_POSITION_ARB, @errPos);
    if errPos>-1 then begin
      errString:=glGetString(GL_PROGRAM_ERROR_STRING_ARB);
      glDeleteProgramsARB(1, @result);
      raise Exception.CreateFmt('ARB Program Error - [Handle: %d][Pos: %d][Error %s]', [result, errPos, errString]);
    end;
  finally
    glBindProgramARB(target,info[2]);//restore prev. binding
    glGetError; //ez eleg bugos
  end;
end;

procedure TARBProgram.Bind;
begin
  if Code='' then begin
    glDisable(Target);
  end else begin
    glEnable(Target);
    glBindProgramARB(Target,Handle);
  end;
end;

procedure TARBProgram.UnBind;
begin
  glDisable(Target);
end;

procedure TARBProgram.FreeHandle;
begin
  if FHandle<>0 then begin
    glDeleteProgramsARB(1,@FHandle);
    FHandle:=0;
  end;
end;

destructor TARBProgram.Destroy;
begin
  FreeHandle;
  inherited;
end;

function TARBProgram.Handle: TGLEnum;
begin
  if(FHandle=0)and(Code<>'')then
    FHandle:=LoadARBProgram(Target,Code);
  result:=FHandle;
end;

procedure TARBProgram.SetCode(const Value: ansistring);
begin
  if FCode<>Value then begin
    FreeHandle;
    FCode:=Value;
    NotifyChange;
  end;
end;

{ TFragmentProgram }

function TFragmentProgram.GetTarget: TGLEnum;
begin
  result:=GL_FRAGMENT_PROGRAM_ARB;
end;

{ TVertexProgram }

function TVertexProgram.GetTarget: TGLEnum;
begin
  result:=GL_VERTEX_PROGRAM_ARB;
end;

{ TFragmentProgramCache }

function TFragmentProgramCache.GetByNameCached(const AName: ansistring): THetObject;
begin
  result:=TFragmentProgram.Create(self);
  TFragmentProgram(result).FName:=AName;
  NotifyChange;
end;

{ TVertexProgramCache }

function TVertexProgramCache.GetByNameCached(const AName: ansistring): THetObject;
begin
  result:=TVertexProgram.Create(self);
  TVertexProgram(result).FName:=AName;
  NotifyChange;
end;

initialization
  ppointer(@TextureCache)^:=TTextureCache.Create(nil);
  ppointer(@FPCache)^:=TFragmentProgramCache.Create(nil);
  ppointer(@VPCache)^:=TVertexProgramCache.Create(nil);
finalization
  FPCache.Free;
  VPCache.Free;
  TextureCache.Free;
end.
