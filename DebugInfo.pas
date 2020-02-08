unit DebugInfo; //system

interface

uses Windows, SysUtils, Math, het.utils;

var lastExceptionDebugInfo:ansistring;

implementation

uses Classes, Forms, Messages;

////////////////////////////////////////////////////////////////////////////////
///  TD32 Debug Info handling                                                ///
////////////////////////////////////////////////////////////////////////////////

Type
 TD32AddressToLine = Record
   Address: Cardinal;
   Line: Cardinal;
  End;

 PD32AddressesArray = ^TD32AddressesArray;
 TD32AddressesArray = Array[0..MaxInt div 16 - 1] Of TD32AddressToLine;

 TD32UnitDebugInfos = Record
   Name: AnsiString;
   Addresses: Array Of TD32AddressToLine;
  End;

 TD32RoutineDebugInfos = Record
   Name: AnsiString;
   StartAddress: Cardinal;
   EndAddress: Cardinal;
  End;

Var
  D32Routines: Array Of TD32RoutineDebugInfos;
  D32Units: Array Of TD32UnitDebugInfos;

//type TMyExceptionCallBack=procedure(ExcContext: PContext; ExcRecord: PExceptionRecord);

// http://webster.cs.ucr.edu/Page_TechDocs/bc32.txt  alapjan

Procedure GetTD32Info;
 Const
  sstModule=       $0120;
  sstTypes=        $0121;
  sstSymbols=      $0124;
  sstAlignSym=     $0125;
  sstSrcModule=    $0127;
  sstGlobalSym=    $0129;
  sstGlobalTypes=  $012b;
  sstNames=        $0130;

  MaxListSize=$FFFFFF;

 Type
  PArrayOfByte = ^TArrayOfByte;
  TArrayOfByte = Array[0..MaxListSize] Of Byte;

  PArrayOfWord = ^TArrayOfWord;
  TArrayOfWord = Array[0..MaxListSize] Of Word;

  PArrayOfPAnsiChar = ^TArrayOfPAnsiChar;
  TArrayOfPAnsiChar = array[0..MaxListSize] Of PAnsiChar;

  PNames= ^TNames;
  TNames= Record
    Count: Integer;
    Data: TArrayOfByte;
   End;

  PSSHeader= ^TSSHeader; //SubSectionHeader
  TSSHeader= Packed Record
    SubSectionType: Word;
    iModuleIndex: Word; //1 based index, $FFFF=not module based
    lfoBase: Integer;
    cbSSSize: Integer;
   End;

  PEnumBuffer= ^TEnumBuffer;
  TEnumBUffer= Packed Record
    Len: Word;
    Sym: Word;
    Dummy1: Array[4..15] Of Byte;
    ProcLen: Integer;
    Dummy2: Array[20..27] Of Byte;
    ProcAddress: cardinal;
    Dummy3: Array[32..39] Of Byte;
    NameIndex: Integer;
   End;

  PSrcLines = ^TSrcLines;
  TSrcLines = Packed Record
    SegIdx: Word; //Melyik szegmensre vonatkozik
    cPair: Word;  //Hany a Sorszam-Address paros
    Offset: Array[0..MaxListSize] Of Cardinal;
   End; //Offsettek arrayje, ezutan jon egy WordArray, ahol a sorszamok vannak

  PSrcModuleHeader = ^TSrcModuleHeader;
  TSrcModuleHeader = Packed Record
    cFile: Word; //Hany a modul?
    cSeg: Word;  //Hany a Code Segment?
    baseSrcFile: Array[0..MaxListSize] Of Cardinal;
   End; //offsetek modulonkent, ez utan meg jon egy struktura a CS-ekkel...

  PSrcFile = ^TSrcFile; //Code Segment tar
  TSrcFile = Packed Record
    cSeg: Word; //Hany a CS?
    nName: Integer; //ID
    baseSrcLn: Array[0..MaxListSize] Of Integer;
   End; //Forraskodban a sorszamok

 Var
  DebugInfoHeader: Packed Record
    Signature: Array[0..3] Of AnsiChar;
    lfoBase: Integer; //Long File Offset
   End;

  DirHeader: Packed Record
    cbDirHeader: Word; //Size of this structure (=16)
    cbDirEntry: Word;
    cDir: Integer;
    lfoNextDir: Integer;
    flags: Integer;
   End;

  SSHeader: PSSHeader;

  OldFileMode: Integer;
  ExeFile: File;
  SstFrame: PArrayOfByte;

  ifaBase: Integer; // Debug info base
  lfodir: Integer;  // SubSection Directory base
  DirItem: Integer;
  SstFrameSize: Integer;
  Current: Integer;
  NameItem: Integer;
  ModuleItem: Integer;
  LineItem: Integer;

  Names: PNames;
  NameTbl: PArrayOfPAnsiChar;
  Buffer: PArrayOfByte;

  RoutineStoreSize: Integer;   //lepegetos tekknologias enumeralas
  RoutineBuffer: PEnumBuffer;

  SrcFile: PSrcFile;
  SrcLines: PSrcLines;

  RoutinesCount: integer;
  UnitsCount: integer;

  ExeBase: Cardinal;

  NTHeader: PImageFileHeader;
  NTOptHeader: PImageOptionalHeader;
 Begin
  RoutinesCount := 0;
  UnitsCount := 0;
  OldFileMode := FileMode;
  FileMode := 0;
  Names := nil;
  NameTbl := nil;

  NTHeader:= PImageFileHeader(Cardinal(PImageDosHeader(HInstance)._lfanew) + HInstance + 4); {SizeOf(IMAGE_NT_SIGNATURE) = 4}
  NTOptHeader:= PImageOptionalHeader(Cardinal(NTHeader) + IMAGE_SIZEOF_FILE_HEADER);
  ExeBase:= HInstance + NTOptHeader.BaseOfCode;

  AssignFile(ExeFile, ParamStr(0));
  Reset(ExeFile, 1);
  Seek(ExeFile, FileSize(ExeFile) - SizeOf(DebugInfoHeader)); //A file utolso 8 byteja tartalmazza a debug signituret, es hogy hol kezdodik a debug info
  BlockRead(ExeFile, DebugInfoHeader, SizeOf(DebugInfoHeader));
  If (DebugInfoHeader.Signature = 'FB09') or (DebugInfoHeader.Signature = 'FB0A') Then
   Begin
    ifabase:= FileSize(ExeFile) - DebugInfoHeader.lfoBase;
    Seek(ExeFile, ifabase);
    BlockRead(ExeFile, DebugInfoHeader, SizeOf(DebugInfoHeader));
    If (DebugInfoHeader.Signature = 'FB09') Or (DebugInfoHeader.Signature = 'FB0A') Then
     Begin
      lfoDir:= ifaBase + DebugInfoHeader.lfoBase;
      If lfodir >= ifabase Then
       Begin
        Seek(ExeFile, lfoDir);
        BlockRead(ExeFile, DirHeader, SizeOf(DirHeader));
        Seek(ExeFile, lfodir + DirHeader.cbDirHeader);
        SstFrameSize:= DirHeader.cdir * DirHeader.cbdirentry;

        GetMem(SstFrame, SstFrameSize); //SubSection Frame
        BlockRead(ExeFile, SstFrame^, SstFrameSize);

        //1. pass: csak a neveket olvassa be
        For DirItem:= 0 To DirHeader.cdir-1 Do
         Begin
          SSHeader:= @SstFrame^[DirItem * DirHeader.cbdirentry];
           Case SSHeader.SubSectionType Of
            sstNames:
             Begin
              GetMem(Names, SSHeader.cbSSSize);
              Seek(ExeFile, ifaBase+SSHeader.lfoBase);
              BlockRead(ExeFile, Names^, SSHeader.cbSSSize);
              GetMem(NameTbl, sizeof(Pointer) * Names.Count);
              Current:= 0;
              For NameItem:= 0 To Names.Count-1 Do
               Begin NameTbl^[NameItem]:= @Names.Data[Current + 1];
                     Inc(Current, Names.Data[Current]+2);  End;
             End;
           End;
         End;
        //2. pass:
        For DirItem:= 0 To DirHeader.cdir-1 Do
         Begin
          SSHeader:= @SstFrame^[DirItem * DirHeader.cbdirentry];
          GetMem(Buffer, SSHeader.cbSSSize);
          Seek(ExeFile, ifaBase+SSHeader.lfoBase);
          BlockRead(ExeFile, Buffer^, SSHeader.cbSSSize);
           Case SSHeader.SubSectionType Of
            sstAlignSym:
             Begin
              RoutineStoreSize:= SSHeader.cbSSSize - 4;
              RoutineBuffer:= @Buffer^[4];
              While RoutineStoreSize>0 Do
               Begin
                If ((RoutineBuffer.Sym = $205) Or (RoutineBuffer.Sym = $204)) And (RoutineBuffer.NameIndex > 0) Then
                 Begin
                  If Length(D32Routines)<=RoutinesCount Then SetLength(D32Routines, Max(RoutinesCount * 2, 1000));
                  With D32Routines[RoutinesCount] Do
                   Begin
                    Name:= PAnsiChar(NameTbl[RoutineBuffer.NameIndex - 1]);
                    StartAddress:= RoutineBuffer.ProcAddress+EXEBase;
                    EndAddress:= StartAddress + Cardinal(RoutineBuffer.ProcLen)-1;
                   End;
                  Inc(RoutinesCount);
                 End;
                If (RoutineBuffer.Len = 0) Then RoutineStoreSize:= 0
                Else
                 Begin Dec(RoutineStoreSize, RoutineBuffer.Len+2);
                       RoutineBuffer:= Pointer(Integer(RoutineBuffer)+RoutineBuffer.len+2);  End;
               End;
             End;
            sstSrcModule:
             Begin
              If SSHeader.cbSSSize > 0 Then
               Begin
                For ModuleItem:= 0 To PSrcModuleHeader(Buffer).cFile-1 Do
                 Begin
                  srcfile:= PSRCFILE(@Buffer^[PSrcModuleHeader(Buffer).baseSrcFile[ModuleItem]]);
                  If SrcFile.nName > 0 Then //note: I assume that the code is always in segment #1. If this is not the case, Houston !  - VM
                   Begin
                    SrcLines:= @Buffer^[srcfile.baseSrcLn[0]];
                    If Length(D32Units)<=UnitsCount Then SetLength(D32Units, Max(UnitsCount * 2, 1000));
                    UnitsCount := UnitsCount + 1;
                    With D32Units[UnitsCount-1] Do
                     Begin Name := PAnsiChar(NameTbl^[srcfile.nName - 1]);
                           SetLength(Addresses, SrcLines.cPair);
                           For LineItem:= 0 to SrcLines^.cPair-1 Do
                             With Addresses[LineItem] Do
                              Begin Address:= SrcLines.Offset[LineItem] + EXEBase;
                                    Line:=    PArrayOfWord(@SrcLines.Offset[SrcLines.cPair{elozo lista vegetol kezdve}])^[LineItem];  End;   End;
                   End;
                 End;
               End;
             End;
            Else Asm Nop End; //! Lehet, hogy a atobbi debugtipusban is van meg csemege
           End;
          FreeMem(Buffer);
         End;
        FreeMem(Names);
        FreeMem(NameTbl);
        FreeMem(SstFrame);
       End;
     End;
   End;
  CloseFile(ExeFile);
  SetLength(D32Units, UnitsCount);
  SetLength(D32Routines, RoutinesCount);
  FileMode:= OldFileMode;
 End;

procedure DumpTD32Info;
var s:ansistring;
    i,j:integer;
begin
  with AnsiStringBuilder(s)do begin
    for i:=0 to high(D32Routines)do with D32Routines[i]do
      addline(format('%x %x %s',[StartAddress,EndAddress,Name]));
    AddLine('');
    for i:=0 to high(D32Units)do with D32Units[i]do begin
      addline(#13#10+Name);
      for j:=0 to high(Addresses)do with Addresses[j]do begin
        AddStr(format('%6d:%x',[Line,Address]));
        if j mod 8=7 then AddLine('');
      end;
      AddLine('');
    end;
    Finalize;
  end;

  TFile('c:\a.a').Write(s);
end;

procedure ExtractTD32Name(const name:ansistring;var sUnit,sClass,sProc:ansistring);
var kukac:array of integer;
    s:array of ansistring;
    i,j:integer;
    n:ansistring;
begin
  n:=name+'@';
  for i:=1 to length(n)do if n[i]='@' then begin
    setlength(kukac,length(kukac)+1);kukac[high(kukac)]:=i;end;
  setlength(s,high(kukac));
  for i:=0 to high(kukac)-1do s[i]:=copy(n,kukac[i]+1,(kukac[i+1]+1)-(kukac[i]+1)-1);
  i:=0;while i<high(s)do begin
    if s[i]='' then begin
      for j:=i to high(s)-1 do s[j]:=s[j+1];
      setlength(s,length(s)-1);
      s[i]:='@'+s[i];
    end;
    i:=i+1;
  end;
  case length(s)of
    0:begin sUnit:='';sClass:='';sProc:='';end;
    1:begin sUnit:='';sClass:='';sProc:=s[0];end;
    2:begin sUnit:=s[0];sClass:='';sProc:=s[1];end;
    else begin sUnit:=s[0];sClass:=s[1];sProc:=s[2];end;
  end;
end;

function FindRet(st,en:cardinal):ansistring;
var i:cardinal;
begin
  result:='';
  if(en<st)or(en-st>32768) then exit;
  for i:=en-2 downto st do if(pbyte(i)^=$c2)and(pbyte(i+2)^=0)then begin
    result:='($'+inttohex(pbyte(i+1)^,2)+')';
  end;
end;

function TD32FindLine(addr:cardinal;out sUnit,sProc:ansistring;out Line:integer):boolean;
var i,uid,j:integer;sClass:ansistring;
begin
  result:=false;
  sUnit:='';sClass:='';Line:=-1;
  for i:=0 to high(D32Routines)do with D32Routines[i]do if(StartAddress<=addr)and(EndAddress>=addr)then begin
    ExtractTD32Name(D32Routines[i].Name,sUnit,sClass,sProc);
{    if((pbyte(EndAddress-2)^ and $f0)=$c0)and(pbyte(EndAddress)^=0)then
      sProc:=sProc+'('+inttostr(pbyte(EndAddress-1)^)+')';}
    sproc:=sproc+findret(StartAddress,EndAddress);
    uid:=-1;for j:=0 to high(D32Units)do if cmp(D32Units[j].Name,sUnit+'.pas')=0 then begin uid:=j;break end;
    line:=-1;
    if uid>=0 then for j:=0 to high(D32Units[uid].Addresses)-1do
    if(addr>=D32Units[uid].Addresses[j].Address)and(addr<D32Units[uid].Addresses[j+1].Address)then begin
      Line:=D32Units[uid].Addresses[j].Line;break;end;
    result:=true;
    if sClass<>'' then sProc:=sClass+'.'+sProc;
    exit;
  end;
end;

function TD32FindProc(addr:cardinal;out sUnit,sProc:ansistring):boolean;
var i:integer;sClass:ansistring;
begin
  result:=false;
  sUnit:='';sClass:='';
  for i:=0 to high(D32Routines)do with D32Routines[i]do if(StartAddress<=addr)and(EndAddress>=addr)then begin
    ExtractTD32Name(D32Routines[i].Name,sUnit,sClass,sProc);
    result:=true;
    if sClass<>'' then sProc:=sClass+'.'+sProc;
    exit;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
///  Exception hook                                                          ///
////////////////////////////////////////////////////////////////////////////////

type
  TEventHolderObj=class
    procedure MyOnException(S:TObject; E: Exception);
  end;

var
  EventHolderObj:TEventHolderObj;
  OldOnException:TExceptionEvent;

procedure TEventHolderObj.MyOnException(S:TObject; E: Exception);
begin
  if GetCapture <> 0 then SendMessage(GetCapture, WM_CANCELMODE, 0, 0);
  E.Message:=e.Message+#13#10+e.StackTrace;
  ShowException(E,nil);
end;

procedure InstallExceptHandler;
var m:TExceptionEvent;
begin
  if EventHolderObj=nil then
    EventHolderObj:=TEventHolderObj.Create;
  m:=EventHolderObj.MyOnException;
  if TMethod(m).Code<>TMethod(Application.OnException).Code then begin
    //save old
    if TMethod(OldOnException).Code=nil then
      OldOnException:=Application.OnException;
    //install new
    Application.OnException:=m;
  end;
end;

procedure UninstallExceptHandler;
var m:TExceptionEvent;
begin
  if(EventHolderObj<>nil)then begin
    m:=EventHolderObj.MyOnException;
    if(TMethod(m).Code=TMethod(Application.OnException).Code)then begin
      Application.OnException:=OldOnException;
      OldOnException:=nil;
    end;
  end;
  FreeAndNil(EventHolderObj);
end;

function MyGetExceptionStackInfo(P: PExceptionRecord): Pointer;

  function AddressDetail(addr:cardinal):ansistring;
  var sUnit,sProc:ansistring;
      line:integer;
  begin
    if TD32FindLine(addr,sUnit,sProc,Line)then begin
      result:=sUnit;
      if line>0 then result:=result+'('+IntToStr(line)+')';
      result:=result+'.'+sProc;
    end else
      result:='';
  end;


const cDelphiException = $0EEDFADE;
var Addr:pointer;
    s,det,lastdet:ansistring;
    i:integer;
    sPtr,sBottom,sTop:pointer;
begin
{  if P.ExceptionCode=cDelphiException then Addr:=P.ExceptAddr
                                      else Addr:=P.ExceptionAddress;
  A delphi es az OS exception egyforman kitolti a P.ExceptionAddress-t }
  //get exception address
  addr:=p.ExceptionAddress;

  //get stack ptrs
  asm
    mov eax,fs:4;mov sTop,eax
    mov eax,fs:8;mov sBottom,eax
  end;
  if P.ExceptionCode=cDelphiException then sPtr:=pointer(P.ExceptionInformation[5])
                                      else asm {mov eax,fs:0;mov sPtr,eax}mov sPtr,ebp end;

  s:=AddressDetail(cardinal(Addr));
  if s<>'' then s:='At '+s+#13#10;

  i:=32;//max lines
  if integer(sPtr)>integer(sBottom)then while(i>0)and(integer(sPtr)<integer(sTop))do begin
    det:=AddressDetail(pcardinal(sPtr)^);
    if(det<>'')and(det<>lastdet) then begin
      lastdet:=det;
      s:=s+format('%s',[det])+#13#10;
      dec(i);
    end;
    inc(pinteger(@sPtr)^,4);
  end;

  while CharN(s,Length(s))in[#13,#10]do setlength(s,length(s)-1);

  //raw exception info
{  s:=s+#13#10+format('ExceptionFlags:%.8x  ExceptionAddress:%.8x  ExceptAddr:%.8x  NumberOfParameters:%d',
   [P.ExceptionFlags,integer(P.ExceptionAddress),integer(P.ExceptAddr),p.NumberParameters]);
  s:=s+#13#10;
  for i:=0 to high(p.ExceptionInformation)do begin
    s:=s+format('  i[%x]:%.8x',[i,p.ExceptionInformation[i]]);
    if i and 3=3 then s:=s+#13#10;
  end;

  //stackptrs
  s:=s+#13#10+format('sPtr:%p  sBottom:%p  sTop:%p',[sPtr,sBottom,sTop]);}

  lastExceptionDebugInfo:=s;

  GetMem(Result,(length(s)+1)*2);
  StrCopy(PWideChar(result),PWideChar(String(s)));

  //install excepthandler
  InstallExceptHandler;
end;

function MyGetStackInfoString(Info: Pointer): string;
begin
  Result :=PWideChar(Info);
end;

procedure MyCleanUpStackInfo(Info: Pointer);
begin
  FreeMem(Info);
end;

procedure HookExceptionStackInfo;
begin
  Exception.GetExceptionStackInfoProc := MyGetExceptionStackInfo;
  Exception.GetStackInfoStringProc := MyGetStackInfoString;
  Exception.CleanUpStackInfoProc := MyCleanUpStackInfo;
end;

procedure UnHookExceptionStackInfo;
begin
  Exception.GetExceptionStackInfoProc := nil;
  Exception.GetStackInfoStringProc := nil;
  Exception.CleanUpStackInfoProc := nil;
end;

{$IFDEF DEBUG}
initialization
  GetTD32Info;     //DumpTD32Info;
  HookExceptionStackInfo;  //this hooks exceptions showning too
finalization
  UninstallExceptHandler;
  UnHookExceptionStackInfo;
{$ENDIF}
end.
