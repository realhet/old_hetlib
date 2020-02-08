unit GLTImage;//het.filesys
interface
uses Windows, sysutils, classes, graphics, het.Utils, het.Gfx, udxtc, typinfo,
  OpenGL1x, het.Stream, math;//tga

var UseCompressedTextures:boolean=false;//BUG van még az nonsquare texturaknal

type
  TGLTHeader=packed record
    magic:TMagic;
    width,height,depth:word;
    MapType:TGLTMapType;
    AlphaType:TGltAlphaType;
    GenerateMipMaps:Boolean;
    function Validate:string;
  end;

  TGLTFile=record
    hdr:TGLTHeader;
    preview:RawByteString;
    raw:array of RawByteString;
    procedure IO(const st:TIO);
    function getJpegData(const n:integer):RawByteString;
    procedure addJpegData(const b:RawByteString);
    function Validate:string;
    function getBitmap(const index:integer):TBitmap;
    function getBitmaps:TBitmapArray;
    procedure Upload;
  end;

const
  GLTMagicJpeg:TMagic='GLTJ';

function GltSaveStr(const bmp:TBitmapArray;const AMapType:TGLTMapType;const AAlphaType:TGltAlphaType;const AGenerateMipmaps:boolean;const AQuality:integer;const APreviewOptions:TGltPreviewOptions):RawByteString;
function GltPreview(const AFileName:string):TGraphic;
function BitmapArrayMakePreview(const bmp:TBitmapArray;const APreviewOptions:TGltPreviewOptions):RawByteString;
function BitmapArrayLoad(const AFileName:string;out MapType:TGLTMapType;out AlphaType:TGltAlphaType;out GenerateMipmaps:Boolean;out Preview:RawByteString):TBitmapArray;overload;
procedure BitmapArrayUpload(const BitmapArray:TBitmapArray;const MapType:TGLTMapType;const AlphaType:TGltAlphaType;const GenerateMipmaps:Boolean);

procedure GltConvert(const SrcFileName,DstFileName:string;const AMapType:TGLTMapType;const AAlphaType:TGltAlphaType;const AGenerateMipmaps:boolean;const AQuality:integer;const APreviewOptions:TGltPreviewOptions);overload;
procedure GltConvert(const SrcFileName,DstFileName:string;const AQuality:integer;const APreviewOptions:TGltPreviewOptions);overload;

implementation

type
  GLTException=class(Exception);

procedure GLTError(const s:string);
begin
  Raise GLTException.Create(s);
end;

type
  TGLTMapTypeInfo=record components:integer;jpgList:ansistring;fmtRaw,fmtRawBGR,fmtDXT,fmt3DC:GLenum;end;

const
  MapTypeInfo:array[TGLTMapType]of TGLTMapTypeInfo=(
//mtColor_L
    (components:1;jpgList:'g';
     fmtRaw:GL_LUMINANCE;
     fmtRawBGR:GL_LUMINANCE;
     fmtDXT:GL_COMPRESSED_RGB_S3TC_DXT1_EXT;
     fmt3DC:0;),
//mtColor_LA
    (components:2;jpgList:'gg';
     fmtRaw:GL_LUMINANCE_ALPHA;
     fmtRawBGR:GL_LUMINANCE_ALPHA;
     fmtDXT:GL_COMPRESSED_RGBA_S3TC_DXT1_EXT;
     fmt3DC:GL_COMPRESSED_LUMINANCE_ALPHA_3DC_ATI),
//mtColor_RGB    }
    (components:3;jpgList:'c';
     fmtRaw:GL_RGB;
     fmtRawBGR:GL_BGR;
     fmtDXT:GL_COMPRESSED_RGB_S3TC_DXT1_EXT;
     fmt3DC:0),
{mtColor_RGBA   }
    (components:4;jpgList:'cg';
     fmtRaw:GL_RGBA;
     fmtRawBGR:GL_BGRA;
     fmtDXT:GL_COMPRESSED_RGBA_S3TC_DXT1_EXT;
     fmt3DC:0),
{mtExact_X      }
    (components:1;jpgList:'g';
     fmtRaw:GL_LUMINANCE;
     fmtRawBGR:GL_LUMINANCE;
     fmtDXT:0;
     fmt3DC:0),
{mtExact_XW     }
    (components:2;jpgList:'gg';
     fmtRaw:GL_LUMINANCE_ALPHA;
     fmtRawBGR:GL_LUMINANCE_ALPHA;
     fmtDXT:0;
     fmt3DC:0),
{mtExact_XYZ    }
    (components:3;jpgList:'ggg';
     fmtRaw:GL_RGB;
     fmtRawBGR:GL_RGB;
     fmtDXT:0;
     fmt3DC:0),
{mtExact_XYZW   }
    (components:4;jpgList:'gggg';
     fmtRaw:GL_RGBA;
     fmtRawBGR:GL_RGBA;
     fmtDXT:0;
     fmt3DC:0),
{mtNormal_UV   }
    (components:3;jpgList:'gg';
     fmtRaw:GL_LUMINANCE_ALPHA;
     fmtRawBGR:GL_LUMINANCE_ALPHA;
     fmtDXT:GL_COMPRESSED_RGBA_S3TC_DXT5_EXT;
     fmt3DC:GL_COMPRESSED_LUMINANCE_ALPHA_3DC_ATI),
{mtNormal_UVH  }
    (components:3;jpgList:'ggg';
     fmtRaw:GL_RGB;
     fmtRawBGR:GL_RGB;
     fmtDXT:0;
     fmt3DC:0)
  );

procedure TGltFile.IO(const st:TIO);
var i:cardinal;
begin
  if st.IOWriting then
    hdr.magic:=GLTMagicJpeg;
  st.IOBlock(hdr,sizeof(hdr));
  if st.IOReading and(hdr.magic<>GLTMagicJpeg)then
    GLTError('TGltFile.IO() infalid magic '''+hdr.magic+'''');

  st.IO(Preview);

  if st.IOWriting then i:=Length(raw);
  st.IOComprCardinal(i);
  if st.IOReading then setlength(raw,i);

  for i:=0 to high(raw)do
    st.IO(raw[i]);
end;

function TGltFile.getJpegData(const n:integer):RawByteString;
begin
  if(n>=0)and(n<=high(Raw))then result:=raw[n]
                           else result:='';
end;

procedure TGLTFile.addJpegData(const b:RawByteString);
begin
  SetLength(raw,length(raw)+1);
  raw[high(raw)]:=b;
end;

function BitmapArrayMakePreview(const bmp:TBitmapArray;const APreviewOptions:TGltPreviewOptions):RawByteString;

  function Make2DPreview(const src:tbitmap;const AWidth,AHeight:integer):TBitmap;
  var b2:tbitmap;
  begin
    result:=TBitmap.CreateClone(src);
    //bake alpha
    if result.PixelFormat=pf32bit then
      result.PixelOp1(function(a:cardinal):cardinal begin result:=RGBLerp(a,$ff00ff,a shr 24)end);
    //resize
    result.ResizeFit(Awidth,Aheight,false,rfLinearMipmapLinear);
    //inverse crop
    if(result.Width<AWidth)or(result.Height<AHeight)then begin
      b2:=TBitmap.CreateNew(pf24bit,AWidth,AHeight);
      b2.Canvas.Draw((b2.Width-result.Width)shr 1,(b2.Height-result.Height)shr 1,result);
      result.free;
      result:=b2;
    end;
  end;

var b:TBitmap;
    bcube:TBitmapArray;
    i:integer;

  procedure drawCubePlane(const bplane:tbitmap;const x,y:integer);
  begin
    b.Canvas.Draw(b.width*x shr 2,b.Height*(y shl 1+1)shr 3,bplane);
  end;

  const ratio3d=192;//0..256

  procedure draw3DPlane(const bplane:tbitmap;const n:integer);
  var xrange,yrange,max:integer;
  begin
    xrange:=b.Width -APreviewOptions.width *ratio3d shr 8;
    yrange:=b.Height-APreviewOptions.height*ratio3d shr 8;
    max:=length(bmp)-1;
    b.Canvas.Draw(APreviewOptions.width-bplane.Width-xrange*n div max,yrange*n div max,bplane);
  end;

begin with APreviewOptions do begin
  if(width>0)and(height>0) then begin
    case BitmapArrayDimensions(bmp)of
      1,2:begin
        b:=Make2DPreview(bmp[0],width,height);
        SetLength(bcube,0);
      end;
      3:begin
        setlength(bcube,length(bmp));
        for i:=0 to high(bcube)do bcube[i]:=Make2DPreview(bmp[i],width*ratio3d shr 8,height*ratio3d shr 8);
        b:=TBitmap.CreateNew(pf24bit,width,height);
        for i:=0 to high(bcube)do draw3DPlane(bcube[high(bcube)-i],high(bcube)-i);
      end;
      6:begin
        setlength(bcube,6);
        for i:=0 to high(bcube)do bcube[i]:=Make2DPreview(bmp[i],width*64 shr 8,height*64 shr 8);
        b:=TBitmap.CreateNew(pf24bit,width,height);
        drawCubePlane(bcube[0],2,1);//px
        drawCubePlane(bcube[1],0,1);//nx
        drawCubePlane(bcube[2],1,0);//py
        drawCubePlane(bcube[3],1,2);//ny
        drawCubePlane(bcube[4],3,1);//pz
        drawCubePlane(bcube[5],1,1);//nz
      end;
    end;

    result:=b.SaveToStr('hjp',APreviewOptions.quality,true);
    BitmapArrayFree(bcube);
    b.Free;
  end;
end;end;

function GltSaveStr(const bmp:TBitmapArray;const AMapType:TGLTMapType;const AAlphaType:TGltAlphaType;const AGenerateMipmaps:boolean;const AQuality:integer;const APreviewOptions:TGltPreviewOptions):RawByteString;
var bmpIndex:integer;
    glt:TGLTFile;

    s:string;
    st:TIO;
begin
  setlength(result,0);
  s:=BitmapArrayValidate(bmp);
  if s<>'' then GLTError('MakeGltFile() invalid bmp array : '+s);

  with glt.hdr do begin
    magic:=GLTMagicJPeg;
    width:=bmp[0].Width;
    height:=bmp[0].Height;
    depth:=length(bmp);
    MapType:=AMapType;
    AlphaType:=AAlphaType;
    GenerateMipMaps:=AGenerateMipmaps;
  end;

  glt.preview:=BitmapArrayMakePreview(bmp,APreviewOptions);

  for bmpIndex:=0 to high(bmp)do begin
    glt.addJpegData(bmp[bmpIndex].SaveToStr('hjp',AQuality,AMapType in [mtColor_RGB,mtColor_RGBA]));
  end;

  st:=TIOBinWriter.Create;
  glt.IO(st);
  result:=st.Data;
  st.Free;
end;

////////////////////////////////////////////////////////////////////////////////
//  uncompress                                                                //
////////////////////////////////////////////////////////////////////////////////

function GltPreview(const AFileName:string):TGraphic;

var gltHdr:TGLTHeader;
    f:file;
    c:Cardinal;
    data:RawByteString;
    fn:string;
begin
  result:=nil;
  fn:=FindFileExt(AFileName);
  if fn<>'' then begin
    AssignFile(f,fn);
    {$I-}reset(f,1);{$I-}
    if IOResult<>0 then exit;
    if FileSize(f)>sizeof(TGltHeader)+4 then begin
      fillchar(gltHdr,sizeof(gltHdr),0);
      BlockRead(f,gltHdr,sizeof(gltHdr));
      if gltHdr.magic=GLTMagicJpeg then begin
        c:=BlockReadCompressedCardinal(f);
        if(c>0)and(c<=16384)then begin
          setlength(data,c);
          BlockRead(f,data[1],length(data));
          try
            result:=TBitmap.CreateFromStr(data);
          finally
          end;
        end;
      end;
      CloseFile(f);
    end;
  end else
    result:=nil;
end;

function TGltFile.getBitmap(const index:integer):TBitmap;
begin
  if(index<0)or(index>hdr.depth)then exit(nil);
  result:=TBitmap.CreateFromStr(getJpegData(index));
end;

function TGLTFile.getBitmaps: TBitmapArray;
var i:integer;
begin
  setlength(result,hdr.depth);
  for i:=0 to high(result)do
    result[i]:=getBitmap(i);
end;

function TGltHeader.Validate:string;
  function checkDim(dim:integer):boolean;
  begin result:=(dim>0)and(dim=Nearest2NSize(dim))and(dim<=8192)end;
begin
  if magic<>GLTMagicJpeg then exit('invalid magic '''+magic+'''');
  if not checkDim(width)then exit('invalid width '+inttostr(width));
  if not checkDim(height)then exit('invalid width '+inttostr(height));
  if(depth<>6)and not checkDim(depth) then exit('invalid width '+inttostr(height));
  if(MapType<low(TGltMapType))or(MapType>high(TGltMapType))then exit('invalid maptype '+inttostr(integer(MapType)));
  if(AlphaType<low(TGltAlphaType))or(AlphaType>high(TGltAlphaType))then exit('invalid maptype '+inttostr(integer(AlphaType)));
end;

function TGltFile.Validate:string;
begin
  result:=hdr.Validate;
  if result<>'' then exit('corrupt header : '+result);

  if length(raw)<>{length(MapTypeInfo[hdr.MapType].jpgList)* it's deprecated, since hjp can handle anything} hdr.depth then exit('invalid number of raw planes');
end;

function InternalFormatDXTVersion(const intFmt:GLenum):TDXTVersion;
begin
  case intFmt of
    GL_COMPRESSED_RGB_S3TC_DXT1_EXT,
    GL_COMPRESSED_RGBA_S3TC_DXT1_EXT:result:=dxt1;
    GL_COMPRESSED_RGBA_S3TC_DXT3_EXT:result:=dxt3;
    GL_COMPRESSED_RGBA_S3TC_DXT5_EXT:result:=dxt5;
    GL_COMPRESSED_LUMINANCE_ALPHA_3DC_ATI:result:=dxt3dc;
    else result:=dxt1;
  end;
end;

function InternalFormatIsCompressed(const intFmt:GLenum):boolean;
begin
  case intFmt of
    GL_COMPRESSED_RGB_S3TC_DXT1_EXT,
    GL_COMPRESSED_RGBA_S3TC_DXT1_EXT,
    GL_COMPRESSED_RGBA_S3TC_DXT3_EXT,
    GL_COMPRESSED_RGBA_S3TC_DXT5_EXT,
    GL_COMPRESSED_LUMINANCE_ALPHA_3DC_ATI:result:=true;
    else result:=false;
  end;
end;

function GetHardwareInternalFormat(const MapType:TGLTMapType;const AlphaType:TGltAlphaType;const HasAlpha,CanCompress:boolean):GLEnum;
begin
  result:=0;
  with MapTypeInfo[MapType]do begin
    if CanCompress then begin
      if(result=0)and GL_ATI_texture_compression_3dc then Result:=fmt3DC;
      if(result=0)and GL_ARB_texture_compression then result:=fmtDXT;
    end;
    if(result=0)then result:=fmtRaw;
  end;

  if(result=GL_COMPRESSED_RGBA_S3TC_DXT1_EXT)and HasAlpha then case AlphaType of
    atSharp:Result:=GL_COMPRESSED_RGBA_S3TC_DXT3_EXT;
    atGradient:result:=GL_COMPRESSED_RGBA_S3TC_DXT5_EXT;
  end;
end;

procedure BitmapArrayUpload(const BitmapArray:TBitmapArray;const MapType:TGLTMapType;const AlphaType:TGltAlphaType;const GenerateMipmaps:Boolean);

  procedure CheckError(const s:string);
  var err:GLenum;
  begin
    err:=glGetError;
    if err<>0 then
      GLTError('GltUpload() '+s+' '+glEnumToStr(err));
  end;

var InternalFormat,UncompressedUploadFmt:GLenum;
    Compressed:boolean;
    DXTVersion:TDXTVersion;
    Dimensions:integer;
    buf:TBytes;
    Level,i:integer;
    s:string;
    b:TBitmapArray;
begin
  CheckError('before BitmapArrayUpload()');

  setlength(b,length(BitmapArray));
  for i:=0 to high(b)do b[i]:=BitmapArray[i];

  s:=BitmapArrayValidate(b);
  if s<>'' then GLTError('BitmapArrayUpload() '+s);
  Dimensions:=BitmapArrayDimensions(b);
  InternalFormat:=GetHardwareInternalFormat(MapType,AlphaType,b[0].PixelSize in[2,4],UseCompressedTextures and (Dimensions>1));
  Compressed:=InternalFormatIsCompressed(InternalFormat);
  DXTVersion:=InternalFormatDXTVersion(InternalFormat);
  UncompressedUploadFmt:=MapTypeInfo[MapType].fmtRawBGR;

  Level:=-1;
  try
    repeat
      inc(Level);//elol van a mipmap miatt (a mipmap level=0-nal cloneozik, kulonben selfmodifyozik

      if Dimensions=1 then begin
        if compressed then begin
          buf:=BitmapArrayDXTEncode(dxtVersion,b);
          glCompressedTexImage1DARB(GL_TEXTURE_1D,Level,InternalFormat,b[0].Width,0,length(buf),@buf[0]);
          checkerror('glCompressedTexImage1DARB()');
        end else begin
          glTexImage1D(GL_TEXTURE_1D,Level,InternalFormat,b[0].width,0,UncompressedUploadFmt,GL_UNSIGNED_BYTE,b[0].scanline[b[0].height-1]);
          checkerror('glTexImage1D()');
        end;
      end else if Dimensions=2 then begin
        if compressed then begin
          buf:=BitmapArrayDXTEncode(dxtVersion,b);
          glCompressedTexImage2DARB(GL_TEXTURE_2D,Level,InternalFormat,b[0].Width,b[0].Height,0,length(buf),@buf[0]);
          checkerror('glCompressedTexImage2DARB()');
        end else begin
          glTexImage2D(GL_TEXTURE_2D,Level,InternalFormat,b[0].width,b[0].height,0,UncompressedUploadFmt,GL_UNSIGNED_BYTE,b[0].scanline[b[0].height-1]);
          checkerror('glTexImage2D() intfmt: '+glEnumToStr(InternalFormat)+' srcfmt:'+glEnumToStr(UncompressedUploadFmt));
        end;
      end else if Dimensions=6 then begin
        for i:=0 to 5 do if compressed then begin
          buf:=BitmapArrayDXTEncode(dxtVersion,b,i);
          glCompressedTexImage2DARB(GL_TEXTURE_CUBE_MAP_POSITIVE_X_ARB+i,Level,InternalFormat,b[0].Width,b[0].Height,0,length(buf),@buf[0]);
          checkerror('glCompressedTexImage2DARB(cube)');
        end else begin
          glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X_ARB+i,Level,InternalFormat,b[0].width,b[0].height,0,UncompressedUploadFmt,GL_UNSIGNED_BYTE,b[i].scanline[b[i].height-1]);
          checkerror('glTexImage2D(cube)');
        end;
      end else begin
        if compressed then begin
          buf:=BitmapArrayDXTEncode(dxtVersion,b);
          glCompressedTexImage3DARB(GL_TEXTURE_3D,Level,InternalFormat,b[0].Width,b[0].Height,length(b),0,length(buf),@buf[0]);
          checkerror('glCompressedTexImage3DARB()');
        end else begin
          buf:=BitmapArrayConcatBytes(b);
          glTexImage3D(GL_TEXTURE_3D,Level,InternalFormat,b[0].width,b[0].height,length(b),0,UncompressedUploadFmt,GL_UNSIGNED_BYTE,@buf[0]);
          checkerror('glTexImage3D()');
        end;
      end;
    until not GenerateMipmaps or not BitmapArrayCalculateMipmap(b,false  {before 130508 it was 'level=0'}{copy});
  finally
    BitmapArrayFree(b);
  end;

  CheckError('after BitmapArrayUpload()');
end;

procedure TGLTFile.Upload;
var b:TBitmapArray;
begin
  b:=getBitmaps;
  try
    BitmapArrayUpload(getBitmaps,hdr.MapType,hdr.AlphaType,hdr.GenerateMipMaps);
  finally
    BitmapArrayFree(b);
  end;
end;

function BitmapArrayLoad(const AFileName:string;out MapType:TGLTMapType;out AlphaType:TGltAlphaType;out GenerateMipmaps:Boolean;out Preview:RawByteString):TBitmapArray;overload;
var glt:TGLTFile;io:TIO;err:string;fn:string;
begin
  setlength(result,0);
  fn:=FindFileExt(AFileName,'.glt');
  if fn<>'' then begin
    io:=TIOBinReader.Create;
    try
      io.Data:=TFile(fn);
      glt.IO(io);
      err:=glt.Validate;
      if err<>'' then
        GLTError('GltImage.BitmapArrayLoad() '+err);
      result:=glt.getBitmaps;
      MapType:=glt.hdr.MapType;
      AlphaType:=glt.hdr.AlphaType;
      GenerateMipmaps:=glt.hdr.GenerateMipMaps;
      Preview:=glt.preview;
    finally
      io.Free;
    end;
  end else begin
    result:=het.Gfx.BitmapArrayLoad(AFileName,true);
    if length(result)<>0 then begin
      case result[0].PixelSize of
        1:MapType:=mtColor_L;
        2:MapType:=mtColor_LA;
        3:MapType:=mtColor_RGB;
        else MapType:=mtColor_RGBA;
      end;
      AlphaType:=atGradient;
      GenerateMipmaps:=Length(result)=1;
      setlength(Preview,0);
    end;
  end;
end;

procedure GltConvert(const SrcFileName,DstFileName:string;const AMapType:TGLTMapType;const AAlphaType:TGltAlphaType;const AGenerateMipmaps:boolean;const AQuality:integer;const APreviewOptions:TGltPreviewOptions);
var ba:TBitmapArray;
    by:RawByteString;
    mt:TGLTMapType;
    at:TGltAlphaType;
    gm:boolean;
    pre:RawByteString;
begin
  ba:=BitmapArrayLoad(SrcFileName,mt,at,gm,pre);
  try
    by:=GltSaveStr(ba,AMapType,AAlphaType,AGenerateMipmaps,AQuality,APreviewOptions);
    TFile(DstFileName).Write(by);
  finally
    BitmapArrayFree(ba);
  end;
end;


procedure GltConvert(const SrcFileName,DstFileName:string;const AQuality:integer;const APreviewOptions:TGltPreviewOptions);overload;
var ba:TBitmapArray;
    by:RawByteString;
    mt:TGLTMapType;
    at:TGltAlphaType;
    gm:boolean;
    pre:RawByteString;
begin
  ba:=BitmapArrayLoad(SrcFileName,mt,at,gm,pre);
  try
    by:=GltSaveStr(ba,mt,at,gm,AQuality,APreviewOptions);
    TFile(DstFileName).Write(by);
  finally
    BitmapArrayFree(ba);
  end;
end;

end.
