unit het.Stream;

interface

uses sysutils, het.Utils, typinfo, het.typeinfo;

type
  TObjStorageFormat=(sfBin,sfDfm,sfTabTxt,sfFixTxt,sfCSV,sfDSV,sfXML,sfXMLa,sfMSSQL,sfPasScr);

  TIO=class //base read/write thing
  private
    FDataStr:RawByteString;
    FSize,FPos:cardinal;
    //some properties
    FWriting:boolean;
    FWriteIndent:ansistring;
  public
    FObjStorageFormat:TObjStorageFormat;
    FDecimalSeparator:ansichar;
    FColSeparator:ansichar;
    FDontWriteClassInfo:boolean;
  private
    function GetSize:integer;
    procedure SetSize(const n:integer);
    function GetPos:integer;
    procedure SetPos(const n:integer);
    procedure wr(var a;const len:cardinal);inline;
    procedure re(var a;const len:cardinal);inline;
    procedure wrComprCardinal(len:cardinal);
    function reComprCardinal:cardinal;
    function getReading:boolean;
  private
    function GetData:RawByteString;
    procedure SetData(const Value: RawByteString);
  private//classinfocache and importer stuff
  type
    TClassInfoCacheRec=record
      ClassType:TClass;
      ClassNameHash:integer;
      ci:pointer;//THetClassInfo
      ExternalFieldDefs:TArray < THetFieldDef >;
    end;PClassInfoCacheRec=^TClassInfoCacheRec;
  var
    FClassInfoCache:TArray<TClassInfoCacheRec>;
    function FindClassInfoRec(const AClassNameHash:integer):PClassInfoCacheRec;overload;
    function FindClassInfoRec(const AClassType:TClass):PClassInfoCacheRec;overload;
    function AddClassInfoRec(const AClassType:TClass;const ACreateCI:boolean):PClassInfoCacheRec;
  public
    FBitCount:cardinal;
    FBitBuffer:cardinal;
    procedure wrBits(var a;count:cardinal);
    function reBits(count:cardinal):integer;
    procedure wrFlushBits;
    procedure reFlushBits;

  public
    procedure WriteText(const s:ansistring);
    procedure WriteLine(const s:ansistring);
    procedure WriteIndentInc;
    procedure WriteIndentDec;
    procedure WriteIndent;
    function EOF:boolean;
  public
    procedure FlushBits;
    property Data:RawByteString read GetData write SetData;
    procedure IOComprCardinal(var a:cardinal);virtual;abstract;
    procedure IOBlock(var a;const len:integer);virtual;abstract;
    procedure IO(var a:byte);overload;virtual;abstract;
    procedure IO(var a:shortint);overload;virtual;abstract;
    procedure IO(var a:word);overload;virtual;abstract;
    procedure IO(var a:smallint);overload;virtual;abstract;
    procedure IO(var a:integer);overload;virtual;abstract;
    procedure IO(var a:cardinal);overload;virtual;abstract;
    procedure IO(var a:int64);overload;virtual;abstract;
    procedure IO(var a:boolean);overload;virtual;abstract;
    procedure IO(var a:single);overload;virtual;abstract;
    procedure IO(var a:double);overload;virtual;abstract;
    procedure IO(var a:extended);overload;virtual;abstract;
    procedure IO(var a:ansistring);overload;virtual;abstract;
    procedure IO(var a:TArray<ansistring>);overload;virtual;abstract;
    procedure IO(var a:rawbytestring);overload;virtual;abstract;
    procedure IO(var a:widestring);overload;virtual;abstract;
    procedure IO(var a:TBytes);overload;virtual;abstract;
    procedure IO(var a:TObject);overload;virtual;abstract;
    property IOWriting:boolean read FWriting;
    property IOReading:boolean read getReading;
  public
    property IOSize:integer read GetSize write SetSize;
    property IOPos:integer read GetPos write SetPos;
    procedure IOSeek(n:integer);
    procedure IOTrunc;
    procedure IOPeek(var a;const len:cardinal);inline;
    function IOPeekChr:ansichar;

    procedure Clear;
  end;

  TIOBinWriter=class(TIO)
  public
    constructor Create;
    procedure IOBlock(var a;const len:integer);override;
    procedure IOComprCardinal(var a:cardinal);override;
    procedure IO(var a:byte);override;
    procedure IO(var a:shortint);override;
    procedure IO(var a:word);override;
    procedure IO(var a:smallint);override;
    procedure IO(var a:integer);override;
    procedure IO(var a:cardinal);override;
    procedure IO(var a:int64);override;
    procedure IO(var a:boolean);override;
    procedure IO(var a:single);override;
    procedure IO(var a:double);override;
    procedure IO(var a:extended);override;
    procedure IO(var a:TArray<ansistring>);override;
    procedure IO(var a:ansistring);override;
    procedure IO(var a:rawbytestring);override;
    procedure IO(var a:TBytes);override;
    procedure IO(var a:widestring);override;
    procedure IO(var a:TObject);override;
  end;

  TIOBinReader=class(TIO)
  private
  public
    procedure IOBlock(var a;const len:integer);override;
    procedure IOComprCardinal(var a:cardinal);override;
    procedure IO(var a:byte);override;
    procedure IO(var a:shortint);override;
    procedure IO(var a:word);override;
    procedure IO(var a:smallint);override;
    procedure IO(var a:integer);override;
    procedure IO(var a:cardinal);override;
    procedure IO(var a:int64);override;
    procedure IO(var a:boolean);override;
    procedure IO(var a:single);override;
    procedure IO(var a:double);override;
    procedure IO(var a:extended);override;
    procedure IO(var a:ansistring);override;
    procedure IO(var a:TArray<ansistring>);override;
    procedure IO(var a:RawByteString);override;
    procedure IO(var a:TBytes);override;
    procedure IO(var a:widestring);override;
    procedure IO(var a:TObject);override;
  end;

procedure BlockWriteCompressedCardinal(var f:file;len:cardinal);
function BlockReadCompressedCardinal(var f:file):cardinal;

type
  TIOTestEnum=(Hetfo,Kedd,Szerda,Csutortok,Pentek,Szombat,Vasarnap);
  TIOTestSet=set of TIOTestEnum;

implementation

uses het.Objects, het.Parser;

{ TIO }

procedure TIO.IOSeek(n:integer);begin SetPos(n)end;
procedure TIO.IOTrunc;begin SetSize(GetPos)end;

function TIO.getReading: boolean;
begin
  result:=not FWriting;
end;

function TIO.GetSize:integer;
begin result:=FSize end;

procedure TIO.SetSize(const n:integer);
begin
  FSize:=n;
  if cardinal(length(FDataStr))<FSize then
    SetLength(FDataStr,FSize*3 shr 1);
end;

procedure TIO.Clear;
begin
  FSize:=0;
  FPos:=0;
  FBitCount:=0;
  setlength(FDataStr,0);
  SetLength(FClassInfoCache,0);
end;

function TIO.GetPos:integer;
begin result:=FPos end;

function TIO.EOF: boolean;
begin
  result:=FPos>=FSize;
end;

procedure TIO.FlushBits;
begin
  if FBitCount>0 then
    if FWriting then wrFlushBits
                else reFlushBits;
end;

function TIO.GetData: RawByteString;
begin
  FlushBits;
  SetLength(FDataStr,FSize);
  result:=FDataStr;
end;

procedure TIO.SetData(const Value: RawByteString);
begin
  FDataStr:=Value;
  FSize:=length(FDataStr);
  FPos:=0;
  FBitCount:=0;
end;

procedure TIO.SetPos(const n:integer);
begin FPos:=n end;

procedure TIO.wr(var a;const len:cardinal);
var newPos:cardinal;
begin
  newPos:=FPos+len;
  if newPos>FSize then
    SetSize(newPos);
  Move(a,FDataStr[FPos+1],len);
  FPos:=newPos;
end;

procedure TIO.re(var a;const len:cardinal);
var newPos:cardinal;
begin
  newPos:=FPos+len;
  if newPos<=cardinal(length(FDataStr))then Move(FDataStr[FPos+1],a,len)
                                       else fillchar(a,len,0);
  FPos:=newPos;
end;

procedure TIO.IOPeek(var a;const len:cardinal);
var newPos:cardinal;
begin
  newPos:=FPos+len;
  if newPos<=cardinal(length(FDataStr))then Move(FDataStr[FPos+1],a,len)
                                       else fillchar(a,len,0);
end;

function TIO.IOPeekChr:ansichar;
begin
  iopeek(result,1);
end;

procedure BlockWriteCompressedCardinal(var f:file;len:cardinal);
begin
  if len<  $80 then begin{X0} len:=len shl 1;     blockwrite(f,len,1) end else
  if len<$4000 then begin{01} len:=len shl 2 or 1;blockwrite(f,len,2) end else
                    begin{11} len:=len shl 2 or 3;blockwrite(f,len,4) end;
end;

function BlockReadCompressedCardinal(var f:file):cardinal;
var b:byte;c:cardinal;
begin
  b:=0;
  blockread(f,b,1);
  if(b and 1)=0 then begin
    result:=b shr 1;
  end else begin
    result:=b shr 2;
    if (b and 2)=0 then begin
      blockread(f,b,1);result:=result or b shl 6;
    end else begin
      c:=0;blockread(f,c,3);result:=result or c shl 6;
    end;
  end;
end;

procedure TIO.wrComprCardinal(len:cardinal);
begin//copy+paste
  if len<  $80 then begin{X0} len:=len shl 1;     wr(len,1) end else
  if len<$4000 then begin{01} len:=len shl 2 or 1;wr(len,2) end else
                    begin{11} len:=len shl 2 or 3;wr(len,4) end;
end;

function TIO.reComprCardinal:cardinal;
var b:byte;c:cardinal;
begin//copy+paste
  re(b,1);
  if(b and 1)=0 then begin
    result:=b shr 1;
  end else begin
    result:=b shr 2;
    if (b and 2)=0 then begin
      re(b,1);result:=result or b shl 6;
    end else begin
      c:=0;re(c,3);result:=result or c shl 6;
    end;
  end;
end;

procedure TIO.wrBits(var a;count:cardinal);
var len:cardinal;
begin
  FBitBuffer:=FBitBuffer or cardinal(a)and(1 shl count-1)shl FBitCount;
  FBitCount:=FBitCount+count;
  if FBitCount>=8 then begin
    len:=FBitCount shr 3;
    wr(FBitBuffer,len);
    len:=len shl 3;
    FBitBuffer:=FBitBuffer shr len;
    FBitCount:=FBitCount-len;
  end;
end;

procedure TIO.wrFlushBits;
begin
  if FBitCount>0 then begin
    wr(FBitBuffer,(FBitCount+7)shr 3);
    FBitCount:=0;
  end;
end;

function TIO.reBits(count:cardinal):integer;
var len,c:cardinal;
begin
  if FBitCount<count then begin
    c:=0;
    len:=(count-FBitCount+7)shr 3;
    re(c,len);
    FBitBuffer:=FBitBuffer or c shl FBitCount;
    FBitCount:=FBitCount+len shl 3;
  end;
  result:=FBitBuffer and(1 shl count-1);
  FBitBuffer:=FBitBuffer shr count;
  FBitCount:=FBitCount-count;
end;

procedure TIO.reFlushBits;
begin
  FBitCount:=0;
end;

procedure TIO.WriteIndent;
begin
  WriteText(FWriteIndent);
end;

procedure TIO.WriteIndentDec;
begin
  delete(FWriteIndent,1,2);
end;

procedure TIO.WriteIndentInc;
begin
  FWriteIndent:=FWriteIndent+'  ';
end;

procedure TIO.WriteLine(const s: ansistring);
begin
  if s<>'' then
    WriteText(FWriteIndent+s+#13#10);
end;

procedure TIO.WriteText(const s: ansistring);
begin
  if s<>'' then
    wr(pointer(@s[1])^,length(s));
end;

function TIO.FindClassInfoRec(const AClassNameHash:integer):PClassInfoCacheRec;
var i:Integer;
begin
  for i:=high(FClassInfoCache)downto 0 do if FClassInfoCache[i].ClassNameHash=AClassNameHash then
    exit(@FClassInfoCache[i]);
  result:=nil;
end;

function TIO.FindClassInfoRec(const AClassType:TClass):PClassInfoCacheRec;
var i:Integer;
begin
  for i:=high(FClassInfoCache)downto 0 do if FClassInfoCache[i].ClassType=AClassType then
    exit(@FClassInfoCache[i]);
  result:=nil;
end;

function TIO.AddClassInfoRec(const AClassType:TClass;const ACreateCI:boolean):PClassInfoCacheRec;
begin
  setlength(FClassInfoCache,length(FClassInfoCache)+1);
  result:=@FClassInfoCache[high(FClassInfoCache)];
  with result^ do begin
    ClassType:=AClassType;
    ClassNameHash:=Crc32UC(ClassType.ClassName);
    ci:=HetClassInfo(ClassType);
  end;
end;

{ TIOBinWriter }

procedure TIOBinWriter.IOBlock(var a;const len:integer);  begin wr(a,len)end;
procedure TIOBinWriter.IO(var a:byte);                    begin wr(a,sizeof(a))end;
procedure TIOBinWriter.IO(var a:shortint);                begin wr(a,sizeof(a))end;
procedure TIOBinWriter.IO(var a:word);                    begin wr(a,sizeof(a))end;
procedure TIOBinWriter.IO(var a:smallint);                begin wr(a,sizeof(a))end;
procedure TIOBinWriter.IO(var a:integer);                 begin wr(a,sizeof(a))end;
procedure TIOBinWriter.IO(var a:cardinal);                begin wr(a,sizeof(a))end;
procedure TIOBinWriter.IO(var a:int64);                   begin wr(a,sizeof(a))end;
procedure TIOBinWriter.IO(var a:boolean);                 begin wr(a,sizeof(a))end;
procedure TIOBinWriter.IO(var a:single);                  begin wr(a,sizeof(a))end;
procedure TIOBinWriter.IO(var a:double);                  begin wr(a,sizeof(a))end;
procedure TIOBinWriter.IO(var a:extended);                begin wr(a,sizeof(a))end;

procedure TIOBinWriter.IO(var a:ansistring);
begin wrComprCardinal(length(a));if length(a)>0 then wr(a[1],length(a))end;

procedure TIOBinWriter.IO(var a:TArray<ansistring>);var i:integer;
begin wrComprCardinal(length(a));for i:=0 to high(a)do io(a[i]);end;

procedure TIOBinWriter.IO(var a:RawByteString);
begin wrComprCardinal(length(a));if length(a)>0 then wr(a[1],length(a))end;

procedure TIOBinWriter.IO(var a:TBytes);
begin wrComprCardinal(length(a));if length(a)>0 then wr(a[0],length(a))end;

procedure TIOBinWriter.IOComprCardinal(var a: cardinal);
begin wrComprCardinal(a)end;

constructor TIOBinWriter.Create;
begin
  inherited;
  FWriting:=true;
end;

procedure TIOBinWriter.IO(var a:widestring);
begin wrComprCardinal(length(a));if length(a)>0 then wr(a[1],length(a)shl 1)end;

function GetClassHash(const cl:TClass):integer;
begin
  if cl=nil then result:=0 else result:=Crc32UC(cl.ClassName);
end;

const HetClassInfoHash=$03106919;

procedure TIOBinWriter.IO(var a:TObject);

  procedure wrBin;//////////////////////////////////////////////////////////////

    function wrBinClassInfo(const ct:TClass;const AWriteClassNameHash:boolean):THetClassInfo;
    //writes HetClassInfo if needed
    //writes 4byte ClassNameHash, and manages the io.ClassInfoChache
    //returns hetClassInfo
    var ciRec:PClassInfoCacheRec;
        _int:integer;
        hp:THetPropInfo;
    begin
      ciRec:=FindClassInfoRec(ct);
      if ciRec=nil then begin
        ciRec:=AddClassInfoRec(ct,true);//create & initialize new cache entry
        result:=THetClassInfo(ciRec.ci);

        if not FDontWriteClassInfo then begin
          //main class
          IO(TObject(result));

          //subObjs
          for hp in result.StoredProps do if hp.Typ=htSubObj then
            wrBinClassInfo(hp.ObjClass,false);
        end;
      end else
        result:=THetClassInfo(ciRec.ci);

      if AWriteClassNameHash then begin
        _int:=ciRec.ClassNameHash; wr(_int,4);
      end;
    end;

    procedure wrBinObjFields(const a:TObject;ci:THetClassInfo);
    var hp:THetPropInfo;
        pi:PPropInfo;
        _astr:ansistring; _u8str:UTF8String; _obj:TObject;
        _int:integer; _int64:int64;
        _single:single; _double:double; _extended:extended;
    begin
      //write fields
      for hp in ci.StoredProps do begin
        pi:=hp.PropInfo;
        //stored?
        if not(flAlwaysStored in hp.Flags)then
          if not IsStoredProp(a,pi)then Continue;
        //raw field?
        if (flField in hp.Flags)and(hp.RawSize>0)then begin
          wr(pointer(cardinal(a)+cardinal(pi.GetProc)and $ffffff)^,hp.RawSize);
        end else case hp.Typ of
          htId:wrComprCardinal(GetOrdProp(a,pi));
          htShortInt,htByte,htSmallInt,htWord,htInteger,htCardinal,htSet,htEnum:begin
            _int:=GetOrdProp(a,pi);
            wr(_int,hp.RawSize);
          end;
          htInt64,htUInt64:begin _int64:=GetInt64Prop(a,pi); wr(_int64,8);end;

          htSingle:  begin _single  :=GetFloatProp(a,pi);    wr(_single,4);end;
          htDouble:  begin _double  :=GetFloatProp(a,pi);    wr(_double,8);end;
          htExtended:begin _extended:=GetFloatProp(a,pi);    wr(_extended,10);end;

          htDate:    begin _int:=GetOrdProp(a,pi);           wr(_int,3   );end;
          htTime:    begin _single:=GetFloatProp(a,pi);      wr(_single,4);end;
          htDateTime:begin _double:=GetFloatProp(a,pi);      wr(_double,8);end;

          htAnsiString,htName:begin _astr:=GetAnsiStrProp(a,pi);self.IO(_astr);end;
          htUnicodeString:    begin _u8str:=GetStrProp(a,pi);self.io(RawByteString(_u8str));end;

          htSubObj:begin _obj:=GetObjectProp(a,pi); IO(_obj); end;

          htObjId  :wrComprCardinal(THetObject(GetObjectProp(a,pi)).GetId);
          htObjIdx :wrComprCardinal(THetObject(GetObjectProp(a,pi)).GetIndex+1);
          htObjName:begin _astr:=THetObject(GetObjectProp(a,pi)).GetName;self.IO(_astr);end;
        else
          raise Exception.Create('wrBin() unknown fieldtype');
        end;
      end;
    end;

    procedure wrBinList;
    var ct:TClass;
        i,j:integer;
        ci:THetClassInfo;
    begin with THetObjectList(a)do begin
      wrComprCardinal(Count);
      i:=0;
      while i<Count do begin
        //look ahead for uniform classes
        ct:=ByIndex[i].ClassType;
        j:=i+1; while(j<Count)and(ByIndex[j].ClassType=ct)do inc(j);
        wrComprCardinal(j-i);//count
        ci:=wrBinClassInfo(ct,true);//classInfo, classNameHash
        while(i<j)do begin
          wrBinObjFields(ByIndex[i],ci);
          inc(i);
        end;
      end;
    end;end;

  var ci:THetClassInfo;
  begin
    ci:=wrBinClassInfo(a.ClassType,true);
    wrBinObjFields(a,ci);
    if a is THetObjectList then
      wrBinList;
  end;


  procedure wrDfm;//////////////////////////////////////////////////////////////

    function wrDfmClassInfo(const ct:TClass;const ClassInfoObj:TObject;const AWriteClassName:boolean):THetClassInfo;
    //writes HetClassInfo, subobj.classinfo if needed
    //writes 4byte ClassNameHash, and manages the io.ClassInfoChache
    //returns hetClassInfo
    var ciRec:PClassInfoCacheRec;
        hp:THetPropInfo;
        s:ansistring;
    begin
      ciRec:=FindClassInfoRec(ct);
      if ciRec=nil then begin
        ciRec:=AddClassInfoRec(ct,true);//create & initialize new cache entry
        result:=THetClassInfo(ciRec.ci);

        if not FDontWriteClassInfo then begin
          //main class
          IO(TObject(result));

          //subObjs
          for hp in result.StoredProps do if hp.Typ=htSubObj then
            wrDfmClassInfo(hp.ObjClass,nil,false);
        end;
      end else
        result:=THetClassInfo(ciRec.ci);

      if AWriteClassName then begin
        if(ClassInfoObj<>nil)and(ClassInfoObj is THetClassInfo)then s:='type '+THetClassInfo(ClassInfoObj).Name
                                                               else s:='object '+Result.Name;
        if(FPos=0)or(FDataStr[FPos]=#10)then WriteLine(s)
                                        else WriteText(s+#13#10);
      end;
    end;

    procedure wrDfmObjFields(const a:TObject;ci:THetClassInfo);
    var hp:THetPropInfo; pi:PPropInfo;
        _astr:ansistring; _u8str:UTF8String; _obj:TObject;
        _int64:int64;
        _single:single; _double:double; _extended:extended;

      procedure wr(s:ansistring); begin WriteLine(hp.Name+' = '+s);end;

    begin
      //write fields
      for hp in ci.StoredProps do begin
        pi:=hp.PropInfo;
        //stored?
        if not(flAlwaysStored in hp.Flags)then
          if not IsStoredProp(a,pi)then Continue;

        case hp.Typ of
          htId,htShortInt,htByte,htSmallInt,htWord,htInteger:wr(ToPas(GetOrdProp(a,pi)));
          htCardinal      :begin _int64:=GetOrdProp  (a,pi); wr(ToPas(_int64));end;
          htInt64,htUInt64:begin _int64:=GetInt64Prop(a,pi); wr(ToPas(_int64));end;

          htEnum:wr(GetEnumProp(a,pi));
          htSet :wr(GetSetProp(a,pi,True));
          htBoolean:wr(switch(getOrdProp(a,pi)<>0,'True','False'));

          htSingle:  begin _single  :=GetFloatProp(a,pi); wr(ToPas(_single  ));end;
          htDouble:  begin _double  :=GetFloatProp(a,pi); wr(ToPas(_double  ));end;
          htExtended:begin _extended:=GetFloatProp(a,pi); wr(ToPas(_extended));end;

          htDate:     wr(DateToPas(GetOrdProp(a,pi)));
          htTime:     wr(TimeToPas(GetFloatProp(a,pi),false));
          htDateTime: wr(DateTimeToPas(GetFloatProp(a,pi),false));

          htAnsiString:begin _astr:=GetAnsiStrProp(a,pi); wr(toPas(_astr));end;
          htName:if a.ClassType<>THetClassInfo then begin _astr:=GetAnsiStrProp(a,pi); wr(toPas(_astr));end;
          htUnicodeString:    begin _u8str:=GetStrProp(a,pi);    wr(toPas(_u8str));end;

          htSubObj:begin
            _obj:=GetObjectProp(a,pi);
            wrDfmClassInfo(_obj.ClassType,nil,false);//optionally write typeinfo
            WriteIndent; WriteText(hp.Name+' = ');
            IO(_obj);
          end;

          htObjId  :wr(ToPas(THetObject(GetObjectProp(a,pi)).GetId   ));
          htObjIdx :wr(ToPas(THetObject(GetObjectProp(a,pi)).GetIndex));
          htObjName:wr(ToPas(THetObject(GetObjectProp(a,pi)).GetName ));
        else
          raise Exception.Create('wrDfm() unknown fieldtype:'+GetEnumProp(hp,'Typ'));
        end;
      end;
    end;

  var ci:THetClassInfo;
      i:integer;
      o:TObject;
  begin
    ci:=wrDfmClassInfo(a.ClassType,a,true);
    WriteIndentInc;

    wrDfmObjFields(a,ci);

    if a is THetObjectList then with THetObjectList(a)do
      for i:=0 to Count-1 do begin
        o:=ByIndex[i];
        IO(o);
      end;

    WriteIndentDec;
    WriteLine('end');
  end;

begin
  if a=nil then exit;
  case FObjStorageFormat of
    sfBin:wrBin;
    sfDfm:wrDfm;
    sfFixTxt:;
    sfCSV,sfDSV,sfTabTxt: ;
    sfXML: ;
    sfXMLa: ;
    sfMSSQL: ;
    sfPasScr: ;
  end;
end;

{ TIOBinReader }

procedure TIOBinReader.IOBlock(var a;const len:integer);  begin re(a,len)end;
procedure TIOBinReader.IO(var a:byte);                    begin re(a,sizeof(a))end;
procedure TIOBinReader.IO(var a:shortint);                begin re(a,sizeof(a))end;
procedure TIOBinReader.IO(var a:word);                    begin re(a,sizeof(a))end;
procedure TIOBinReader.IO(var a:smallint);                begin re(a,sizeof(a))end;
procedure TIOBinReader.IO(var a:integer);                 begin re(a,sizeof(a))end;
procedure TIOBinReader.IO(var a:cardinal);                begin re(a,sizeof(a))end;
procedure TIOBinReader.IO(var a:int64);                   begin re(a,sizeof(a))end;
procedure TIOBinReader.IO(var a:boolean);                 begin re(a,sizeof(a))end;
procedure TIOBinReader.IO(var a:single);                  begin re(a,sizeof(a))end;
procedure TIOBinReader.IO(var a:double);                  begin re(a,sizeof(a))end;
procedure TIOBinReader.IO(var a:extended);                begin re(a,sizeof(a))end;

procedure TIOBinReader.IO(var a:ansistring);
begin setlength(a,reComprCardinal);if length(a)>0 then re(a[1],length(a))end;

procedure TIOBinReader.IO(var a:TArray<ansistring>);var i:integer;
begin setlength(a,reComprCardinal);for i:=0 to high(a)do io(a[i]);end;

procedure TIOBinReader.IO(var a:RawByteString);
begin setlength(a,reComprCardinal);if length(a)>0 then re(a[1],length(a))end;

procedure TIOBinReader.IO(var a:TBytes);
begin setlength(a,reComprCardinal);if length(a)>0 then re(a[0],length(a))end;

procedure TIOBinReader.IOComprCardinal(var a: cardinal);
begin a:=reComprCardinal end;

procedure TIOBinReader.IO(var a:widestring) ;
begin setlength(a,reComprCardinal);;if length(a)>0 then re(a[1],length(a)shl 1)end;

procedure TIOBinReader.IO(var a:TObject);

  procedure Error(const s:ansistring);
  begin raise Exception.Create('IO(var a:TObject) Error: '+s);end;

  function DetectFormat:TObjStorageFormat;
  var i:integer;
  begin
    IOPeek(i,4);
    if ClassByHash(i)<>nil then exit(sfBin);
    exit(sfDfm);
  end;

  procedure reBin;
  begin

  end;

  procedure reDfm;
  var ch:PAnsiChar;
//      v:Variant;
//      tk:TToken;
      id,s:ansistring;
//      o:TObject;
//      cirec:PClassInfoCacheRec;
  begin
    if EOF then error('Unexpected EOF');
    ch:=@FDataStr[FPos+1];

    ParseSkipWhiteSpace(ch); ParseIdentifier(ch,id);
    if Cmp(id,'object')=0 then begin

    end else if Cmp(id,'type')=0 then begin
      ParseSkipWhiteSpace(ch); ParseIdentifier(ch,s);
//      cirec:=FindClassInfoRec(crc32uc(s));
//      if cirec=nil then AddClassInfoRec(agyfasz)



//      o:=THetClassInfo.Create();
    end;


{    if id=nil then error('"type" or "object" expected');




    if ParsePascalConstant(ch,)}

  end;

begin
  case DetectFormat of
    sfBin:reBin;
    sfDfm:reDfm;
  end;
end;


end.
