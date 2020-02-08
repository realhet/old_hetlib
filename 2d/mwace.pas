unit mwace;
// This file was adapted from the mwgfx.pas by Holger Maaﬂ
//
// Copyright © 1999-2003 by Martin Wright MW Graphics

// TAceImage class and dynamic dll loader by realhet 2009

interface
uses windows, sysutils, classes, graphics, tga;

type
  TAceImage=class(TBitmap)
  private
  public
    procedure LoadFromStream(stream : TStream); override;
    procedure SaveToStream(stream : TStream); override;
  end;

  EAceException=class(Exception);

procedure AceLoadFromStream(const bmp:TBitmap;const st:TStream);
procedure AceSaveToStream(const bmp:TBitmap;const st:TStream);

implementation

const
  dllName = 'mwace.dll';

type
  PByte = ^Byte;

  TProgressFunc = procedure (i1, i2: Integer);

  PPic = ^TPic;
  TPic = Packed Record
    width: Integer;
    height: Integer;
    depth: Integer;
    numcols: Integer;
    fin: Pointer;
    comment: Array [0..79] of AnsiChar;
    cmap: Array [0..767] of Byte;
    jlib: Pointer;
    tlib: Pointer;
    plib: Pointer;
    buff: PByte;
    fout: Pointer;
    ptr: Pointer;
    progress: TProgressFunc;
    ilib: Pointer;
    stype: Integer;
    spare: Array [0..119] of Byte;
  end;

//access to mwace.dll functions
type
  TAceToBmps=function(p1, p2, p3: PAnsiChar):Integer; cdecl;
  TAceToBmp=function(p1, p2: PAnsiChar):Integer; cdecl;
  TAceToTga=function(p1, p2: PAnsiChar):Integer; cdecl;
  TAceToTgaSquare=function(p1, p2: PAnsiChar):Integer; cdecl;
  TBmpsToTga=function(p1, p2, p3: PAnsiChar):Integer; cdecl;
  TBmpsToTgaSquare=function(p1, p2, p3: PAnsiChar):Integer; cdecl;
  TCheckAce=function(p: PAnsiChar; lpPic: PPic): Integer; cdecl;
  TAceInitLoad=function(p: PAnsiChar): Integer; cdecl;
  TAceLoadBitmap=function(p: PAnsiChar; pp: Pointer): Integer; cdecl;
  TAceCompress=function(p1, p2: PAnsiChar):Integer; cdecl;
  TAceDecompress=function(p1, p2: PAnsiChar):Integer; cdecl;

var
  AceToBmps:TAceToBmps;
  AceToBmp:TAceToBmp;
  AceToTga:TAceToTga;
  AceToTgaSquare:TAceToTgaSquare;
  BmpsToTga:TBmpsToTga;
  BmpsToTgaSquare:TBmpsToTgaSquare;
  CheckAce:TCheckAce;
  AceInitLoad:TAceInitLoad;
  AceLoadBitmap:TAceLoadBitmap;
  AceCompress:TAceCompress;
  AceDecompress:TAceDecompress;

procedure Load;
var h:HMODULE;
begin
  h:=LoadLibrary(dllName);
  if h<>0 then begin
    AceToBmps:=GetProcAddress(h,'_AceToBmps');
    AceToBmp:=GetProcAddress(h,'_AceToBmp');
    AceToTga:=GetProcAddress(h,'_AceToTga');
    AceToTgaSquare:=GetProcAddress(h,'_AceToTgaSquare');
    BmpsToTga:=GetProcAddress(h,'_BmpsToTga');
    BmpsToTgaSquare:=GetProcAddress(h,'_BmpsToTgaSquare');
    CheckAce:=GetProcAddress(h,'_CheckAce');
    AceInitLoad:=GetProcAddress(h,'_AceInitLoad');
    AceLoadBitmap:=GetProcAddress(h,'_AceLoadBitmap');
    AceCompress:=GetProcAddress(h,'_AceCompress');
    AceDecompress:=GetProcAddress(h,'_AceDecompress');
  end;
end;

procedure AceLoadFromStream(const bmp:TBitmap;const st:TStream);
var stFile:TFileStream;
    buf:TBytes;
    AceTemp,TgaTemp:AnsiString;

    temppath:array[0..511]of AnsiChar;
begin
  if not assigned(AceToBmp) then
    raise EAceException.Create('Failed to load mwace.dll');

  windows.GetTempPathA(sizeof(tempPath),@temppath);

  AceTemp:=temppath+'AceTmp'+AnsiString(IntToHex(integer(bmp),8));
  TgaTemp:=AceTemp+'.tga';
  AceTemp:=AceTemp+'.ace';

  setlength(buf,st.Size-st.Position);
  if length(buf)>0 then
    st.Read(buf[0],length(buf));

  stFile:=TFileStream.Create(AceTemp,fmCreate);
  try
    if length(buf)>0 then
      stFile.Write(buf[0],length(buf));
    freeAndNil(stFile);

    if AceToTga(PAnsiChar(AceTemp),PAnsiChar(TgaTemp))<>0 then begin
      stFile:=TFileStream.Create(TgaTemp,fmOpenRead);
      TGALoadFromStream(bmp,stFile);
    end else
      raise EAceException.Create('Error loading ace file');
  finally
    stFile.free;
    DeleteFile(acetemp);
    DeleteFile(tgatemp);
  end;
end;

procedure AceSaveToStream(const bmp:TBitmap;const st:TStream);
begin
  raise EAceException.Create('Ace file saving not supported');
end;

{ TAceImage }

procedure TAceImage.LoadFromStream(stream: TStream);
begin
  AceLoadFromStream(self,stream);
end;

procedure TAceImage.SaveToStream(stream: TStream);
begin
  AceSaveToStream(self,stream);
end;

initialization
  load;
finalization
end.
