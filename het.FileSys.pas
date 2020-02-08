unit het.FileSys;
//111202 !!!!!!! ebbol het.PakFile lesz, mint egy beepulo az het.utils
interface

uses windows, sysutils, classes, syncobjs, het.Utils, het.Objects, het.Stream;

type
  _TMagic=array[0..3]of ansichar;

const
  HetPakExtension:ansistring='hpk';
  HetPakMAGIC:_TMagic='HPAK';

type
  TPakFileRecord=class(THetObject)
  private
    FName:ansistring;
    FSize,FOffset:cardinal;
    procedure SetName(const Value: ansistring);
    procedure SetSize(const Value: cardinal);
    procedure SetOffset(const Value: cardinal);
  public
    procedure Serialize(const st:TIO;const SerType:TSerializeType=stBin);override;
    function Read(const AData:pointer;const ALen:integer):boolean;
    function ReadBytes:TBytes;
    function ReadStr:rawbytestring;
    procedure Write(const AData:pointer;const ALen:integer);
    procedure WriteBytes(const data:TBytes);
    procedure WriteStr(const data:rawbytestring);
  published
    property Name:ansistring read FName write SetName;
    property Size:cardinal read FSize write SetSize stored false;
    property Offset:cardinal read FOffset write SetOffset stored false;
  end;

  TPakFile=class(THetList<TPakFileRecord>)
  private
    FFile:file;
    FBaseOffset:integer;//ha exe-re van rarakva, ez az exe merete lesz
    FFilesChanged:boolean;
    FOpened:boolean;
    FName:ansistring;
    procedure Seek(const AOfs:integer);
    procedure ReadDir;
    procedure WriteDir;
    function DoOpen(createNew:boolean):boolean;
    procedure DoClose;
    function GetTailPos:integer;
  public
    constructor Create(AOwner:THetObject;const AName:ansistring);reintroduce;
    destructor Destroy;override;
    procedure Flush;
    procedure Write(const AFileName: ansistring;const AData:pointer;const ALen:cardinal);overload;
    procedure WriteBytes(const AFileName:ansistring;const AData:TBytes);overload;
    procedure WriteStr(const AFileName:ansistring;const AData:RawByteString);overload;
    function Read(const AFileName:ansistring;const AData:pointer;const ALen:cardinal):boolean;overload;
    function ReadBytes(const AFileName:ansistring):TBytes;overload;
    function ReadStr(const AFileName:ansistring):RawByteString;overload;
    procedure Delete(const AFileName:ansistring);
    function Exists(const AFileName:ansistring):boolean;
    procedure Compact;
    property FilesChanged:boolean read FFilesChanged;
    function PakFileSize:integer;
  published
    property Name:ansistring read FName stored false;//full filename
  end;

  TPakFileCache=class(THetList<TPakFile>)
  private
    FCritSec:TCriticalSection;
  public
    constructor Create(const AOwner:THetObject);override;
    destructor Destroy;override;

    function GetByNameCached(const AName:ansistring):THetObject;override;
    procedure Flush;

    procedure Lock;
    procedure Unlock;

    property ByName;default;
  end;

var
  PakFileCache:TPakFileCache;

//111202: ezek mar kiszedodnek, helyette TFile(filemane)....

{function FileRead(const AFileName:ansistring;const AData:pointer;const ALen:integer):boolean;
function FileReadStr(const AFileName:ansistring):RawByteString;

procedure FileWrite(const AFileName:ansistring;const AData:pointer;const ALen:integer);
procedure FileWriteStr(const AFileName:ansistring;const AData:RawByteString);

function FileExistsName(const AFileName:ansistring;const AExtensionList:AnsiString=''):ansistring;

function FileExists(const AFileName:ansistring;const AExtensionList:AnsiString=''):boolean;}

{type
  THetObjectLoadSave=class helper for THetObject
  public
    procedure SaveToFile(const AFileName:ansistring);
    procedure LoadFromFile(const AFileName:ansistring);
  end;}

{type
  IFile=interface
    function Name:string;
    function Path:string;
    function Ext:string;
    function FullName:string;
    function Exists:boolean;
    function Read:rawbytestring;
    procedure Write(const Value:rawbytestring);
//    procedure Append(const Value:rawbytestring);
    property AsStr:rawbytestring read Read write Write;
  end;deprecated;

  TFileObj=class(TInterfacedObject,IFile)
  private
    FFileName:string;
  public
    constructor Create(const AFileName:string);
    function Name:string;
    function Path:string;
    function Ext:string;
    function FullName:string;
    function Exists:boolean;
    function Read:rawbytestring;
    procedure Write(const Value:rawbytestring);
  end;deprecated;

function File_(const AFileName:string):IFile;deprecated;}

implementation

function min(const a,b:integer):integer;begin if a<b then result:=a else result:=b;end;

procedure SplitAtHPak(const AFileName:ansistring;out APackFileName,APackedFileName:ansistring);
var i:integer;
begin
  i:=Pos('.'+HetPakExtension+'\',AFileName,[poIgnoreCase]);
  if i<=0 then i:=Pos('.exe\',AFileName,[poIgnoreCase]);
  if i>0 then begin
    APackFileName:=copy(AFileName,1,i+3);
    APackedFileName:=copy(AFileName,i+5,$ffff);
  end else begin
    APackFileName:='';
    APackedFileName:=AFileName;
  end;
end;

{function FileExistsFullName(const AFileName:ansistring):boolean;
var PakFileName,PackedFileName:ansistring;
begin
//  Assert(IsFullPath(AFileName),'FileExistsFullName() not a full path '+AFileName);
  SplitAtHPak(AFileName,PakFileName,PackedFileName);
  if PakFileName<>'' then
    result:=sysutils.FileExists(PakFileName) and PakFileCache.ByName[PakFileName].Exists(PackedFileName)
  else
    result:=sysutils.fileexists(AFileName);
end;      }

function AddFileExt(const fn,ext:String):String;
begin
  if(ext='')or(charn(ext,1)='.')then Result:=fn+ext
                                else Result:=fn+'.'+ext;
end;

function FileExistsName(const AFileName:ansistring;const AExtensionList:AnsiString=''):ansistring;

  function DoFind(const AFileName:ansistring):ansistring;
  var PakFileName,PackedFileName:ansistring;
  begin
    result:=ExpandFileNameForRead(AFileName);
    SplitAtHPak(result,PakFileName,PackedFileName);
    if PakFileName<>'' then begin
      PakFileCache.Lock;
      try
        if not PakFileCache.ByName[PakFileName].Exists(PackedFileName)then
          result:='';
      finally
        PakFileCache.UnLock;
      end;
    end else begin
      if not sysutils.FileExists(result)then
        result:='';
    end;
  end;

var i:integer;
begin
  if AExtensionList='' then
    result:=DoFind(AFileName)
  else
    for i:=0 to ListCount(AExtensionList,';')-1 do begin
      result:=DoFind(ChangeFileExt(AFileName,ListItem(AExtensionList,i,';')));
      if result<>'' then exit;
    end;
end;

function FileExists(const AFileName:ansistring;const AExtensionList:AnsiString=''):boolean;
begin
  result:=FileExistsName(AFileName,AExtensionList)<>'';
end;

procedure FileWrite(const AFileName:ansistring;const AData:pointer;const ALen:integer);
var PakFileName,PackedFileName,fn:ansistring;
    f:file;
begin
  fn:=ExpandFileNameForWrite(AFileName);
  SplitAtHPak(fn,PakFileName,PackedFileName);
  if PakFileName<>'' then begin
    PakFileCache.Lock;
    try
      PakFileCache.ByName[PakFileName].Write(PackedFileName,AData,ALen);
    finally
      PakFileCache.UnLock;
    end;
  end else begin
    CreateDirForFile(fn);
    AssignFile(f,fn);
    rewrite(f,1);
    try
      if ALen>0 then
        BlockWrite(f,AData^,ALen);
    finally
      closefile(f);
    end;
  end;
end;

procedure FileWriteStr(const AFileName:ansistring;const AData:rawbytestring);
begin
  FileWrite(AFileName,pointer(AData),length(AData));
end;

function FileRead(const AFileName:ansistring;const AData:pointer;const ALen:integer):boolean;
var PakFileName,PackedFileName,fn:ansistring;
    f:file;
begin
  fn:=ExpandFileNameForRead(AFileName);
  SplitAtHPak(fn,PakFileName,PackedFileName);
  if PakFileName<>'' then begin
    PakFileCache.Lock;
    try
      result:=PakFileCache.ByName[PakFileName].Read(PackedFileName,AData,ALen);
    finally
      PakFileCache.UnLock;
    end;
  end else begin
    if sysutils.fileexists(fn)then begin
      AssignFile(f,fn);
      reset(f,1);
      result:=true;
      try
        if ALen>0 then
          BlockRead(f,AData^,min(ALen,FileSize(F)));
      finally
        closefile(f);
      end;
    end else
      result:=false;
  end;
end;

function FileReadStr(const AFileName:ansistring):rawbytestring;
var PakFileName,PackedFileName,fn:ansistring;
    f:file;
begin
  fn:=ExpandFileNameForRead(AFileName);
  SplitAtHPak(fn,PakFileName,PackedFileName);
  if PakFileName<>'' then begin
    PakFileCache.Lock;
    try
      result:=ZDecompress(PakFileCache.ByName[PakFileName].ReadStr(PackedFileName));
    finally
      PakFileCache.UnLock;
    end;
  end else begin
    if sysutils.fileexists(fn)then begin
      AssignFile(f,fn);
      FileMode:=0;reset(f,1);FileMode:=2;
      setlength(result,FileSize(F));
      try
        if length(Result)>0 then
          BlockRead(f,result[1],length(result));
        result:=ZDecompress(result);
      finally
        closefile(f);
      end;
    end else
      setlength(result,0);
  end;
end;

{ TPakFileCache }

constructor TPakFileCache.Create(const AOwner: THetObject);
begin
  inherited;
  FCritSec:=TCriticalSection.Create;
end;

destructor TPakFileCache.Destroy;
begin
  Flush;
  FreeAndNil(FCritSec);
  inherited;
end;

procedure TPakFileCache.Flush;
var //pf:TPakFile;
    i:integer;
begin
  for i:=0 to Count-1 do ByIndex[i].Flush;
//  for pf in self do pf.Flush;
end;

function TPakFileCache.GetByNameCached(const AName: ansistring): THetObject;
begin
  result:=TPakFile.Create(self,AName);
end;

procedure TPakFileCache.Lock;
begin
  FCritSec.Enter;
end;

procedure TPakFileCache.Unlock;
begin
  FCritSec.Leave;
end;

type
  TPakHdr=packed record
    magic:_TMagic;
    dirPos,dirSize:integer;
  end;

{ TPakFile }

procedure TPakFile.Seek(const AOfs: integer);
begin
  system.Seek(FFile,FBaseOffset+AOfs);
end;

procedure TPakFile.Compact;
var i:integer;
    newOffset:cardinal;
    data:tbytes;
begin
  DoOpen(true);

  for i:=0 to count-1 do with ByIndex[i]do begin
    if i=0 then newOffset:=0
           else with ByIndex[i-1]do newOffset:=Offset+Size;
    if newOffset<>Offset then begin
      data:=ReadBytes;
      Offset:=newOffset;
      WriteBytes(data);
    end;
  end;

  WriteDir;
  FFilesChanged:=false;

  DoClose;
end;

constructor TPakFile.Create(AOwner: THetObject; const AName: ansistring);
begin
  Inherited Create(AOwner);
  ViewDefinition:='Offset';
  FName:=AName;
  ReadDir;
end;

procedure TPakFile.Delete(const AFileName: ansistring);
var pr:TPakFileRecord;
begin
  pr:=ByName[AFileName];
  if pr<>nil then begin
    FFilesChanged:=true;
    pr.Free;
  end;
end;

destructor TPakFile.Destroy;
begin
  DoClose;
  inherited;
end;

procedure TPakFile.DoClose;
begin
  if FOpened then begin
    Flush;
    FOpened:=false;
    CloseFile(FFile);
  end;
end;

function TPakFile.DoOpen(createNew:boolean):boolean;
var isExe:boolean;
begin
  if not FOpened then begin
    isExe:=cmp(ExtractFileExt(Name),'.exe')=0;

    if isExe then FileMode:=fmOpenRead
             else FileMode:=fmOpenReadWrite;

    AssignFile(FFile,Name);
    if sysutils.FileExists(Name)then begin
      system.Reset(FFile,1);
      FOpened:=true;
    end else if createNew then begin
      CreateDirForFile(Name);
      Rewrite(FFile,1);
      FOpened:=true;
    end;

    if isExe then FileMode:=fmOpenReadWrite;
  end;
  result:=FOpened;
end;

function TPakFile.Exists(const AFileName: ansistring): boolean;
begin
  result:=ByName[AFileName]<>nil;
end;

procedure TPakFile.Flush;
begin
  if FFilesChanged then begin
    FFilesChanged:=false;
    WriteDir;
  end;
end;

procedure TPakFile.ReadDir;
var hdr:TPakHdr;

  function readHdr(const pos:cardinal):boolean;
  begin
    seek(pos);BlockRead(FFile,hdr,sizeof(hdr));
    result:=(hdr.Magic=hetpakMagic)and(hdr.dirPos+hdr.dirSize<=FileSize(FFile));

    if result then FBaseOffset:=FileSize(FFile)-hdr.dirPos-hdr.dirSize-SizeOf(hdr)
              else FBaseOffset:=0;
  end;

var dirData:RawByteString;
begin
  Clear;
  if DoOpen(false)and(FileSize(FFile)>sizeof(hdr))then begin
    if readhdr(FileSize(FFile)-sizeof(hdr))then begin
      setlength(dirData,hdr.dirSize);
      Seek(hdr.dirPos);
      BlockRead(FFile,dirData[1],length(dirData));

      LoadFromStr(ZDecompress(dirData));
    end;
  end;
end;

procedure TPakFile.WriteDir;
var st:TIO;
    dirdata:RawByteString;
    hdr:TPakHdr;
begin
  if doOpen(true)then begin
    st:=TIOBinWriter.Create;
    try
      dirData:=ZCompress(SaveToStr(stBin));
      hdr.dirPos:=GetTailPos;
      hdr.dirSize:=length(dirdata);
      hdr.magic:=HetPakMAGIC;
      Seek(hdr.dirPos);
      BlockWrite(FFile,dirData[1],length(dirdata));
      BlockWrite(FFile,hdr,sizeof(hdr));
      Truncate(FFile);
    finally
      st.Free;
    end;
  end else
    raise Exception.Create('TPakFile.WriteDir() unable to open file '+Name);
end;

function TPakFile.Read(const AFileName: ansistring;const AData:pointer;const ALen:cardinal):boolean;
var pr:TPakFileRecord;
begin
  result:=false;
  pr:=ByName[AFileName];
  if pr=nil then exit;

  if DoOpen(false)then begin
    Seek(pr.Offset);
    if ALen>0 then
      BlockRead(FFile,AData^,min(ALen,pr.Size));
    result:=true;
  end
end;

function TPakFile.ReadBytes(const AFileName: ansistring): TBytes;
var pr:TPakFileRecord;
begin
  setlength(result,0);
  pr:=ByName[AFileName];
  if pr=nil then exit;

  if DoOpen(false)then begin
    SetLength(result,pr.Size);
    Seek(pr.Offset);
    if length(result)>0 then
      BlockRead(FFile,result[0],length(result));
  end;
end;

function TPakFile.ReadStr(const AFileName: ansistring): RawByteString;
var pr:TPakFileRecord;
begin
  setlength(result,0);
  pr:=ByName[AFileName];
  if pr=nil then exit;

  if DoOpen(false)then begin
    SetLength(result,pr.Size);
    Seek(pr.Offset);
    if length(result)>0 then
      BlockRead(FFile,result[1],length(result));
  end;
end;

function TPakFile.GetTailPos:integer;
var i,o:integer;
begin
//  if Count=0 then exit(0);
//  with ByIndex[Count-1]do result:=Offset+Size;
  result:=0;
  for i:=0 to Count-1 do with ByIndex[i] do begin
    o:=Offset+Size;
    if result<o then result:=o;
  end;
end;

function TPakFile.PakFileSize: integer;
begin
  if FOpened then result:=system.FileSize(FFile)
             else result:=0;
end;

procedure TPakFile.Write(const AFileName: ansistring;const AData:pointer;const ALen:cardinal);
var pr:TPakFileRecord;

  procedure WriteData;
  begin
    FFilesChanged:=true;
    Seek(pr.Offset);
    if ALen>0 then
      BlockWrite(FFile,AData^,ALen);
  end;
var NewPos:integer;
begin
  if not DoOpen(true)then
    raise Exception.Create('TPakFile.WriteFile doOpen failed '+Name);

  newPos:=GetTailPos;
  pr:=ByName[AFileName];
  if pr=nil then begin//uj file
    pr:=TPakFileRecord.Create(self);//Viola itt
    pr.Name:=AFileName;
    pr.Offset:=NewPos;
    pr.Size:=ALen;
    WriteData;
  end else begin//mar letezik
    if ALen<=pr.Size then begin//kisebb meret
      pr.Size:=ALen;
      WriteData;
    end else begin//nagyobb meret, file vegere megy
      pr.setIndex(Count-1);
      pr.Offset:=NewPos;
      pr.Size:=ALen;
      WriteData;
    end;
  end;
end;

procedure TPakFile.WriteBytes(const AFileName: ansistring; const AData: TBytes);
begin
  if Length(AData)>0 then Write(AFileName,@AData[0],length(AData))
                     else Write(AFileName,nil,0);
end;

procedure TPakFile.WriteStr(const AFileName: ansistring;
  const AData: RawByteString);
begin
  if Length(AData)>0 then Write(AFileName,@AData[1],length(AData))
                     else Write(AFileName,nil,0);
end;

{ TPakFileRecord }

function TPakFileRecord.Read(const AData:pointer;const ALen:integer):boolean;
begin
  result:=TPakFile(FOwner).Read(Name,AData,ALen);
end;

function TPakFileRecord.ReadBytes: TBytes;
begin
  result:=TPakFile(FOwner).ReadBytes(Name);
end;

function TPakFileRecord.ReadStr: rawbytestring;
begin
  result:=TPakFile(FOwner).ReadStr(Name);
end;

procedure TPakFileRecord.Serialize;
begin
  inherited Serialize(st,stBin);
  //no dfm support
  Assert(SerType=stBin,'%^&!@*#^&*!@');
  st.IOComprCardinal(FOffset);
  st.IOComprCardinal(FSize);
end;

{$O-}
procedure TPakFileRecord.SetName(const Value: ansistring);begin end;
procedure TPakFileRecord.SetSize(const Value: cardinal);begin end;
procedure TPakFileRecord.SetOffset(const Value: cardinal);begin end;

procedure TPakFileRecord.Write(const AData:pointer;const ALen:integer);
begin
  TPakFile(FOwner).Write(Name,AData,ALen);
end;

procedure TPakFileRecord.WriteBytes(const data: TBytes);
begin
  TPakFile(FOwner).WriteBytes(Name,data);
end;

procedure TPakFileRecord.WriteStr(const data: rawbytestring);
begin
  TPakFile(FOwner).WriteStr(Name,data);
end;

{ TFile }

{function File_(const AFileName:string):IFile;
begin
  result:=TFileObj.Create(AFileName);
end;

constructor TFileObj.Create(const AFileName: string);
begin
  inherited Create;;
  FFileName:=AFileName;
end;

function TFileObj.Read: rawbytestring;
begin
  result:=FileReadStr(FFileName);
end;

function TFileObj.Name: string;
begin
  result:=FFileName;
end;

function TFileObj.Path: string;
begin
  result:=ExtractFilePath(FullName);
end;

function TFileObj.Ext: string;
begin
  result:=ExtractFileExt(FFileName);
end;

function TFileObj.FullName: string;
begin
  result:=FileExistsName(FFileName);
end;

function TFileObj.Exists:boolean;
begin
  result:=FileExists(FFileName);
end;

procedure TFileObj.Write(const Value: rawbytestring);
begin
  FileWriteStr(FFileName,Value);
end;}

initialization
//!!!!!!!  QRVANAGY BUG, valami miatt ez a hetobj.PAS elott hivodik meg
  if Root=nil then raise Exception.Create('Unit initialization order screwed up...');

{  RegisterHetClass(TPakFile);
  RegisterHetClass(TPakFileRecord);
  RegisterHetClass(TPakFileCache);}

  PakFileCache:=TPakFileCache.Create(nil);
finalization
  FreeAndNil(PakFileCache);
end.
