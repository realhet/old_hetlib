unit het.mpeg;

interface

uses
  Windows, SysUtils, classes, graphics, het.Bitmaps, het.Utils, het.Objects, cal,
  het.cal;

type
  THetMpegCodec=class
  public
//    FContext:TGPUContext;

    FGlobalBasePtr,FGlobalPtr:pointer;
    FGlobalRes:CALresource;
  public
    constructor Create(const ADeviceId:integer=0);
    destructor Destroy;override;

    //Upload a bitmap to the gpu
    procedure Upload(const Source:TBitmap);
  end;

implementation

{ THetMpegCodec }

constructor THetMpegCodec.Create(const ADeviceId: integer=0);
var len,len128:integer;
begin
  FContext:=TGPUContext.Create(ADeviceId);//ez recreate! Ez nem jóú, mert 1 device=1 context kell threadenkent

  len:=8 shl 20;
  len128:=len shr 4;
  len128:=(len128+63)and not 63;

  calCheck(CalResCreate1D(FGlobalRes,FContext.dev.dev,FGlobalPtr,len,
    CAL_FORMAT_UNORM_INT32_4,CAL_RESALLOC_GLOBAL_BUFFER),'CalResCreate1D global');
end;

destructor THetMpegCodec.Destroy;
begin
  SysFreeMem(FGlobalPtr);
  FreeAndNil(FContext);
  inherited;

end;

procedure THetMpegCodec.Upload(const Source: TBitmap);
begin


end;

end.