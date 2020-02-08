unit ULameEnc;
//source: google bladeenc delphi torry

interface

uses SysUtils, Snd, het.Utils;

type
//type definitions
  THBE_STREAM = cardinal;
  PHBE_STREAM = ^THBE_STREAM;
  BE_ERR =(
    BE_ERR_SUCCESSFUL,
    BE_ERR_INVALID_FORMAT,
    BE_ERR_INVALID_FORMAT_PARAMETERS,
    BE_ERR_NO_MORE_HANDLES,
    BE_ERR_INVALID_HANDLE);

const
// encoding formats
  BE_CONFIG_MP3	= 0;
  BE_CONFIG_LAME = 256;

// other constants
  BE_MAX_HOMEPAGE	= 256;

// format specific variables
  BE_MP3_MODE_STEREO = 0;
  BE_MP3_MODE_DUALCHANNEL = 2;
  BE_MP3_MODE_MONO = 3;

type
  TBE_MP3 = packed record
           dwSampleRate     : LongWord;
           byMode           : Byte;
           wBitRate         : Word;
           bPrivate         : LongWord;
           bCRC             : LongWord;
           bCopyright       : LongWord;
           bOriginal        : LongWord;
           end;

  TBE_Config = packed record
                 dwConfig   : LongWord;
                 format     : TBE_MP3;
               end;

  PBE_Config = ^TBE_Config;

  TBE_Version = record
                  byDLLMajorVersion : Byte;
                  byDLLMinorVersion : Byte;

                  byMajorVersion    : Byte;
                  byMinorVersion    : Byte;

                  byDay             : Byte;
                  byMonth           : Byte;
                  wYear             : Word;

                  zHomePage         : Array[0..BE_MAX_HOMEPAGE + 1] of Char;
                  end;

  PBE_Version = ^TBE_Version;

Function beInitStream(var pbeConfig: TBE_CONFIG; var dwSample: LongWord; var dwBufferSize: LongWord; var phbeStream: THBE_STREAM ): BE_Err; cdecl; external 'Lame_enc.dll';
Function beEncodeChunk(hbeStream: THBE_STREAM; nSamples: LongWord; var pSample;var pOutput; var pdwOutput: LongWord): BE_Err; cdecl; external 'Lame_enc.dll';
Function beDeinitStream(hbeStream: THBE_STREAM; var pOutput; var pdwOutput: LongWord): BE_Err; cdecl; external 'Lame_enc.dll';
Function beCloseStream(hbeStream: THBE_STREAM): BE_Err; cdecl; external 'Lame_enc.dll';
Procedure beVersion(var pbeVersion: TBE_VERSION); cdecl; external 'Lame_enc.dll';

type
  TLameEnc=class
  private
    cfg:TBE_Config;
    SamplesPerChunk,MinOutBufSize,HBeStream:Cardinal;
    InBuf,OutBuf,OutStream:AnsiString;
    sbuilder:TAnsiStringBuilder;
    function GetData:RawByteString;
    procedure ErrorChk(err:BE_ERR;const s:string);
  public
    constructor Create(ABitrate:integer);
    destructor Destroy;override;
    procedure Append(const Sn:TSnd);
    property Data:RawByteString read GetData;
  end;

implementation

constructor TLameEnc.Create(ABitrate: integer);
begin
  sbuilder:=TAnsiStringBuilder.Create(OutStream);

  cfg.dwConfig:=BE_CONFIG_MP3;
  with cfg.format do begin
    dwSampleRate:=44100;
    byMode:=BE_MP3_MODE_STEREO;
    wBitRate:=128;
    bPrivate:=0;
    bCopyright:=0;
    bOriginal:=0;
  end;

  ErrorChk(beInitStream(cfg,SamplesPerChunk,MinOutBufSize,HBeStream),'beInitStream()');
  setlength(OutBuf,MinOutBufSize);
end;

destructor TLameEnc.Destroy;
begin
  inherited;
  beCloseStream(HBeStream);HBeStream:=0;
  FreeAndNil(sbuilder);
end;

procedure TLameEnc.ErrorChk(err: BE_ERR;const s: string);
var e:string;
begin
  case err of
    //BE_ERR_SUCCESSFUL:
    BE_ERR_INVALID_FORMAT:e:='Invalid format';
    BE_ERR_INVALID_FORMAT_PARAMETERS:e:='Invalid format parameters';
    BE_ERR_NO_MORE_HANDLES:e:='no moar handles';
    BE_ERR_INVALID_HANDLE:e:='invalid handle';
  else e:='' end;
  if e<>'' then
    raise Exception.Create('LameEnc error: '+e+' at '+s);
end;

procedure TLameEnc.Append(const Sn: TSnd);
var cnt:cardinal;
begin
  setlength(InBuf,length(Sn)shl 2);
  SndWriteS16(Sn,pointer(Inbuf)^);
  ErrorChk(beEncodeChunk(HBeStream,Length(Sn)shl 1{stereo=2sample},pointer(Inbuf)^,pointer(outBuf)^,cnt),'beEncodeChunk()');
  sbuilder.AddBlock(pointer(OutBuf)^,cnt);
end;

function TLameEnc.GetData: RawByteString;
var cnt:cardinal;
begin
  ErrorChk(beDeinitStream(HBeStream,pointer(outBuf)^,cnt),'beDeinitStream()');
  sbuilder.AddBlock(pointer(OutBuf)^,cnt);
  sbuilder.Finalize;
  result:=OutStream;
end;

end.

