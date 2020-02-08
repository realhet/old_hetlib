unit het.MacroParser; //het.cl

interface

uses
  Windows, SysUtils, classes, het.Utils, het.Arrays, het.Objects, math, AnsiStrings,
  variants, VarUtils, het.Variants, het.Parser, unsSystem;

//het.cal connects to this from the outside
type TGCN_MacroGen=function (const what:ansistring; const params:TArray<ansistring>):ansistring;
var  GCN_MacroGen: TGCN_MacroGen=nil;

type
  TMacroParserFunc=reference to function(const s:ansistring):ansistring;

  IMacroPlugin=interface ['{a5d52394-956e-491b-990d-0d6f86eab4f5}']
    //called before every file, all plugins must initialize state
    procedure Reset;
    //called when a directive found, returns optional code replacement
    function OnDirective(const ADirective,AContent:ansistring;out AReplacement:ansistring;const AParserFunc:TMacroParserFunc):boolean;
    //called on every identifier, returns an index or -1
    function OnIdentifier(const ANameHash:integer):integer;
    //called when the parameter list is acquired, immed after OnIdentifier
    procedure OnReplace(const AIndex:integer;const AParams:TAnsiStringArray;const AParserFunc:TMacroParserFunc;out AReplacement:ansistring);
  end;

  TTextModification=record
    idx,pos,del:integer;
    ins:ansistring;
  end;

  TTextModificationArray=array of TTextModification;
  TPrecompiledFileRec=record
    FileName:ansistring;
    Changes:TTextModificationArray;
    cre,acc,wri:Int64;
    attr:cardinal;
  end;

  TPrecompiledFiles=array of TPrecompiledFileRec;

  TWarningRec=record
    Msg,FileName:ansistring;
    Line,Column:integer;
  end;

var
  MacroWarnings:array of TWarningRec;
  MacroError:TWarningRec;

procedure RegisterMacroPlugin(const APlugin:IMacroPlugin);
function MacroPrecompileProject(const AFileName,APaths:ansistring;const ABuild:boolean;out Msg:ansistring;out PrecompiledFiles:TPrecompiledFiles;const AMaxCharsPerLine:integer):boolean;
procedure MacroWarning(const AMsg:ansistring;const localPos:integer);

const
  precompiledExt='.ppas';
  backupFileExt='.bpas';

function MacroPrecompiledFileNameOf(const fn:ansistring):ansistring;
function MacroBackupFileNameOf(const fn:ansistring):ansistring;

function MacroPrecompile(const ASrc:ansistring;const AMaxCharsPerLine:integer):ansistring;overload;

procedure MacroSetCurrentFile(const fn:string);

implementation

//uses {UPrecompExpert, }UMacroAdvanced{ebben vannak azok a pluginok, amihez már kell a full interpreter is};
//uses UMacroAdvanced;

function MacroPrecompiledFileNameOf(const fn:ansistring):ansistring;
begin result:=changeFileExt(fn,precompiledExt)end;

function MacroBackupFileNameOf(const fn:ansistring):ansistring;
begin result:=changeFileExt(fn,backupFileExt)end;

////////////////////////////////////////////////////////////////////////////////
//                      TextModifier                                          //
////////////////////////////////////////////////////////////////////////////////

type
  TTextModifier=class
    FText:ansistring;
    FModifications:THetArray<TTextModification>;
    procedure Replace(const APos:integer;const ADel:integer;const AIns:ansistring);
    procedure Insert(const APos:integer;const AIns:ansistring);
    function Apply:boolean;//true if changed
    procedure DuplicateChanges(var AChanges:TTextModificationArray);//Apply utan kell hivni
  end;

{ TTextModifier }

procedure TTextModifier.Replace(const APos:integer;const ADel:integer;const AIns:ansistring);
var tm:TTextModification;
begin
  tm.idx:=FModifications.FCount;
  tm.pos:=APos;
  tm.del:=ADel;
  tm.ins:=AIns;
  FModifications.Append(tm);
end;

procedure TTextModifier.Insert(const APos:integer;const AIns:ansistring);
begin
  Replace(APos,0,AIns);
end;

function TTextModifier.Apply:boolean;
var res:AnsiString;
    i,lastPos,srcPos,skipLen:integer;
begin
  result:=FModifications.FCount>0;
  if not result then exit;

  FModifications.QuickSort(function(const a,b:TTextModification):integer begin
    result:=a.pos-b.pos;
    if result=0 then
      result:=a.idx-b.idx;
  end);

  lastPos:=0;srcPos:=1;
  with FModifications,AnsiStringBuilder(res)do begin
    for i:=0 to FCount-1 do with FItems[i]do begin
      //copy unmodified text
      skipLen:=pos-lastPos;
      AddBlock(FText[srcPos],skipLen);
      inc(srcPos,skipLen);
      //delete
      inc(srcPos,del);
      //insert
      AddStr(ins);

      lastPos:=pos+del;
    end;
    //remaining text
    AddStr(copy(FText,srcPos,$ffffff));
    Finalize;
    FText:=res;
  end;
end;

procedure TTextModifier.DuplicateChanges(var AChanges:TTextModificationArray);
var i:integer;
begin
  SetLength(AChanges,FModifications.FCount);
  for i:=0 to high(AChanges)do begin
    AChanges[i]:=FModifications.FItems[i];
  end;
end;

////////////////////////////////////////////////////////////////////////////////
//                      Parser                                                //
////////////////////////////////////////////////////////////////////////////////

var
  hUses:integer;

  CurrentFile:string;
  CurrentLine:integer;
  CurrentColumn:integer;
  CurrentLineStart:PAnsiChar;

procedure MacroSetCurrentFile(const fn:string);
begin
  CurrentFile:=fn;
end;

procedure MacroWarning(const AMsg:ansistring;const localPos:integer);
begin
  setlength(MacroWarnings,length(MacroWarnings)+1);
  with MacroWarnings[high(MacroWarnings)]do begin
    Msg:=AMsg;
    FileName:=CurrentFile;
    Line:=CurrentLine;
    Column:=CurrentColumn;
  end;
end;

procedure ProcessUses(const AList:ansistring;var AUnits:TAnsiStringArray);
var params:TAnsiStringArray;
    i:integer;
    s:ansistring;
begin
  params:=ListSplit(AList,',');
  for i:=0 to high(params)do begin
    s:=params[i];
    if s='' then Continue;
    if s[1]='{' then s:=TrimF(copy(s,pos('}',s)+1,$ff));if s='' then Continue;
    if s[length(s)]='}' then s:=TrimF(copy(s,1,pos('{',s)-1));if s='' then Continue;
    if s[length(s)]='''' then s:=replacef('''','',copy(s,pos('''',s)+1,$ff),[roAll]);

    SetLength(AUnits,length(AUnits)+1);
    AUnits[high(AUnits)]:=s;
  end;
end;

function StripComments(const s:ansistring):ansistring;
var at:ansichar;
    i:integer;
    closeit:boolean;
begin
  if s='' then exit('');
  result:=s;at:=#0;
  for i:=1 to length(result)do begin
    closeit:=false;
    case at of
      '''','"','}':if result[i]=at then closeit:=true;
      ')':if(i>1)and(Result[i]=')')and(Result[i-1]='*')then closeit:=true;
      '/':if(i>1)and(Result[i]='/')and(Result[i-1]='*')then closeit:=true;
      '\':if(i>1)and(Result[i] in [#10,#13])then at:=#0;
    else
      case result[i] of
        '''','"':at:=result[i];
        '{':at:='}';
        '(':if(i<length(result))and(result[i+1]='*')then at:='(';
        '/':if(i<length(result))then case result[i+1]of
                                       '*':at:='/';
                                       '/':at:='\';
        end;
      end;
    end;

    if not(at in[#0,'''','"'])then
      result[i]:=' ';

    if closeit then at:=#0;
  end;
end;

function MacroPrecompile(const APlugin:IMacroPlugin;const ASrc:ansistring;var AUnits:TAnsiStringArray;const ALevel:integer;out AChanges:TTextModificationArray;const AMaxCharsPerLine:integer=1000):ansistring;overload;

  function CheckBackForPoint(ch:PAnsiChar):boolean;
  begin
    while ch[-1]in[' ',#13,#10]do dec(ch);
    result:=ch[-1]='.'
  end;

var tm:TTextModifier;
    SrcLineCount:integer;
    ch,chStart,chBegin:PAnsiChar;
    dummyChg:TTextModificationArray;

  procedure IncCurrentLine;
  begin
    if ALevel=0 then begin
      inc(CurrentLine);
      CurrentColumn:=0;
      CurrentLineStart:=pointer(ch);
    end;
    inc(SrcLineCount);
  end;

  procedure ProcessDefinition(const lineEndBackslash:boolean=false;const removedef:boolean=false;const delLastChar:boolean=false);
  var i,j:integer;
      s,sCmd,sContent,s2:ansistring;
      atEOL:boolean;
      newlinecount:integer;
  begin
    if ch<>#0 then begin
      if chStart[0]='#'then begin
        s:=strMake(chStart, ch);

        if EndsWith(s,'#endm')then setlength(s,length(s)-5);
        if dellastChar then setlength(s,length(s)-1);

        newlinecount:=0;
        for i:=1 to length(s)do if s[i]=#10 then inc(newlinecount);

        if lineEndBackslash then begin
          atEOL:=true;
          for i:=length(s)downto 1 do begin
            if s[i]=#10 then atEOL:=true else
            if(s[i]='\')and atEOL then begin atEOL:=false;s[i]:=' ';end else
            if not (s[i] in[' ',#13,#9])then atEOL:=false;
          end;
        end;

        i:=pos(' ',s);
        j:=pos(#10,s);
        if(j>0)and(j<i)then i:=j;
        if i<=0 then begin
          sCmd:=s;
          sContent:='';
        end else begin
          sCmd:=Trim(Copy(s,1,i-1));
          sContent:=copy(s,i+1,$ffffff);
        end;

        sContent:=StripComments(sContent);
//              log('Finding directive '+scmd+' content:'+sContent);

        if ALevel=0 then CurrentColumn:=integer(chStart)-integer(CurrentLineStart);
        if APlugin.OnDirective(sCmd,sContent,s,function(const s:ansistring):ansistring var AUnits:TAnsiStringArray;begin result:=MacroPrecompile(APlugin,s,AUnits,ALevel+1,dummyChg,AMaxCharsPerLine)end)then begin
          if(s='')and(removeDef)then begin
            s:=StrMul(#13#10,newlinecount);
          end;
          if (s<>'')or removeDef then begin
  //                log('Found directive '+scmd);
            s2:=MacroPrecompile(APlugin,s,AUnits,ALevel+1,dummyChg,AMaxCharsPerLine);//recusrive
            if s2<>'' then s:=s2;//!!!!!!!!!takolas
            if ALevel=0 then s:=ParseRealignLines(s,AMaxCharsPerLine,CurrentColumn,SrcLineCount);
            tm.Replace(integer(chStart)-integer(chBegin)-1, integer(ch)-integer(chStart)+1, s);
          end;
        end;
      end;
    end;
  end;

var ch2,chStart2:PAnsiChar;
    s,s2,id:ansistring;
    i,hash,BracketCnt:integer;
    params:TAnsiStringArray;
    PluginSubIdx:integer;

begin
  result:='';
  if ASrc='' then exit;
  if ALevel>32 then raise Exception.Create('Too many recursive calls');

  if ALevel=0 then begin
    APlugin.Reset;
    CurrentLine:=1; CurrentColumn:=0; CurrentLineStart:=pointer(ASrc);
    SetLength(AChanges,0);
  end;
  tm:=TTextModifier.Create;
  tm.FText:=ASrc;SrcLineCount:=1;
  try
    chBegin:=pointer(ASrc);
    ch:=pointer(ASrc);
    if ch<>nil then while true do begin
      case ch[0] of
        #0:break;
        #13:inc(ch);
        #10:begin IncCurrentLine;inc(ch)end;
        '''':begin
          inc(ch);while not(ch[0] in[#0,''''])do inc(ch);
          if ch<>#0 then inc(ch);
        end;
        '"':begin
          inc(ch);while not(ch[0] in[#0,'"'])do inc(ch);
          if ch<>#0 then inc(ch);
        end;
        '#':begin  //#define rewqrewq\
          inc(ch);chStart:=@ch[-1];SrcLineCount:=1;
          ch2:=ch;if ParseIdentifier(ch2,id)then begin
            if(cmp(id,'define')=0)or(cmp(id,'assign')=0)or(cmp(id,'include')=0)or(cmp(id,'undef')=0) then begin
              while ch[0]<>#0 do begin
                if(ch[0]=#10)then begin
                  ch2:=@ch[-1];while ch2[0] in [' ',#13,#9] do dec(ch2);
                  if(ch2[0]<>'\')or(cmp(id,'define')<>0)then begin dec(ch);break;end;
                end;
                if ch[0]=#10 then IncCurrentLine;inc(ch);
              end;
              ProcessDefinition(true,true);
            end else if cmp(id,'macro')=0 then begin
              while True do begin
                ParseSkipWhitespaceAndComments(ch);
                if ch[0]='#' then begin
                  inc(ch);
                  if ParseIdentifier(ch,id)and(cmp(id,'endm')=0)then
                    break;
                end else if ch[0]=#0 then
                  raise Exception.Create('Error parsing #macro: #endm expected but not found')
                else
                  inc(ch);
              end;
              ProcessDefinition(false,true);
            end else if(cmp(id,'ifdef')=0)or(cmp(id,'if')=0)then begin
              raise Exception.Create('MacroParser() #'+id+' not implemented yet');
            end else
              ProcessDefinition(false,true);//ez az ag asszem nem teljesul soha
          end;
        end;
        '{':begin  //{#define fdsaferwq}
          inc(ch);chStart:=ch;SrcLineCount:=1;
          while not(ch[0] in[#0,'}'])do begin if ch[0]=#10 then IncCurrentLine;inc(ch);end;
          if ch[0]='}' then inc(ch);

          ProcessDefinition(false,true,true);
        end;
        '(':begin
          if ch[1]='*' then begin
            inc(ch,2);
            while(ch[0]<>#0)and not((ch[0]='*')and(ch[1]=')'))do begin
              if ch[0]=#10 then IncCurrentLine;
              inc(ch);
            end;
            if ch[0]<>#0 then inc(ch,2);
          end else
            inc(ch);
        end;
        '/':begin
          if ch[1]='/' then begin
            while not(ch[0] in[#13,#10,#0])do inc(ch);
            IncCurrentLine;
          end else if ch[1]='*' then begin
            inc(ch,2);
            while(ch[0]<>#0)and not((ch[0]='*')and(ch[1]='/'))do begin
              if ch[0]=#10 then IncCurrentLine;
              inc(ch);
            end;
            if ch[0]<>#0 then inc(ch,2);
          end else
            inc(ch);
        end;
        'a'..'z','A'..'Z','_':begin
          if CheckBackForPoint(ch)then begin
            while ch[0] in['a'..'z','A'..'Z','_','0'..'9']do inc(ch);
            continue;
          end;

          chStart:=ch;SrcLineCount:=1;Crc32UCInit(hash);
          while ch[0] in['a'..'z','A'..'Z','_','0'..'9']do begin
            Crc32UCNextChar(hash,ch[0]);
            inc(ch);
          end;
          Crc32UCFinalize(hash);

          PluginSubIdx:=APlugin.OnIdentifier(hash);
          if PluginSubIdx>=0 then begin
            //getting until paramlist
            setlength(Params,0);
            if ch[0]='(' then begin
              setlength(Params,0);
              BracketCnt:=1;inc(ch);chStart2:=pointer(ch);
              while true do case ch[0] of
                #0:break;//unexpected eof
                #10:begin IncCurrentLine;inc(ch)end;
                '''':begin
                  inc(ch);while not(ch[0] in[#0,''''])do inc(ch);
                  if ch<>#0 then inc(ch);
                end;
                '[':begin inc(ch);inc(bracketCnt);end;
                ']':begin inc(ch);dec(bracketCnt);end;
                '(':begin inc(ch);inc(bracketCnt);end;
                ')':begin
                  inc(ch);dec(bracketCnt);if bracketCnt=0 then begin
                    setlength(params,length(params)+1);
                    setlength(params[high(params)],integer(ch)-integer(chStart2)-1);
                    if length(params[high(params)])>0 then
                      move(chStart2^,params[high(params)][1],length(params[high(params)]));
                    break;
                  end;
                end;
                ',':begin
                  inc(ch);if bracketCnt=1 then begin
                    setlength(params,length(params)+1);
                    setlength(params[high(params)],integer(ch)-integer(chStart2)-1);
                    if length(params[high(params)])>0 then
                      move(chStart2^,params[high(params)][1],length(params[high(params)]));
                    chStart2:=pointer(ch);
                  end;
                end;
              else
                inc(ch);
              end;
              for i:=0 to high(params)do trim(params[i]);
            end;
            //calling macroreplace

            if ALevel=0 then CurrentColumn:=integer(chStart)-integer(CurrentLineStart);

            APlugin.OnReplace(PluginSubIdx,params,
              function(const s:ansistring):ansistring
              var AUnits:TAnsiStringArray;
              begin
                result:=MacroPrecompile(APlugin,s,AUnits,ALevel+1,dummyChg,AMaxCharsPerLine)
              end,
            s);

            s2:=MacroPrecompile(APlugin,s,AUnits,ALevel+1,dummyChg,AMaxCharsPerLine);//recusrive

            if s2<>'' then s:=s2;//!!!!!!!!!takolas

            if ALevel=0 then begin
              s:=ParseRealignLines(s,AMaxCharsPerLine,CurrentColumn,SrcLineCount);
//              log('-------->realigning:'+s+' col:'+inttostr(CurrentColumn)+' lc:'+inttostr(SrcLineCount));
            end;
            tm.Replace(integer(chStart)-integer(chBegin),integer(ch)-integer(chStart),s);

          end else if hash=hUses then begin//USES
            s:='';while not(ch[0]in[';',#0])do begin s:=s+ch[0];inc(ch);end;if ch[0]<>#0 then inc(ch);
            ProcessUses(s,AUnits);
          end;
        end;
      else
        inc(ch);
      end;
    end;
    //hetUtils
    if tm.Apply then result:=tm.FText
                else result:=ASrc;
    if ALevel=0 then
      tm.DuplicateChanges(AChanges);
  finally
    tm.Free;
  end;
end;

procedure PrecompileFindUnitsOnly(const ASrc:ansistring;var AUnits:TAnsiStringArray);
  function CheckBackForPoint(ch:PAnsiChar):boolean;
  begin
    while ch[-1]in[' ',#13,#10]do dec(ch);
    result:=ch[-1]='.'
  end;

var ch:PAnsiChar;
    s:ansistring;
    hash:integer;
begin
  if ASrc='' then exit;

  ch:=pointer(ASrc);
  if ch<>nil then while true do begin
    case ch[0] of
      #0:break;
      #13,#10:inc(ch);
      '''':begin
        inc(ch);while not(ch[0] in[#0,''''])do inc(ch);
        if ch<>#0 then inc(ch);
      end;
      '{':begin
        inc(ch);
        while not(ch[0] in[#0,'}'])do inc(ch);
        if ch<>#0 then inc(ch);
      end;
      '(':begin
        if ch[1]='*' then begin
          inc(ch,2);
          while(ch[0]<>#0)and not((ch[0]='*')and(ch[1]=')'))do inc(ch);
          if ch[0]<>#0 then inc(ch,2);
        end else
          inc(ch);
      end;
      '/':begin
        if ch[1]='/' then begin
          while not(ch[0] in[#13,#10,#0])do inc(ch);
        end else if ch[1]='*' then begin
          inc(ch,2);
          while(ch[0]<>#0)and not((ch[0]='*')and(ch[1]='/'))do inc(ch);
          if ch[0]<>#0 then inc(ch,2);
        end else
          inc(ch);
      end;
      'a'..'z','A'..'Z','_':begin
        if CheckBackForPoint(ch)or not(ch[0]in['U','u'])then begin//optimized skip for uses
          while ch[0] in['a'..'z','A'..'Z','_','0'..'9']do inc(ch);
          continue;
        end;

        Crc32UCInit(hash);
        while ch[0] in['a'..'z','A'..'Z','_','0'..'9']do begin
          Crc32UCNextChar(hash,ch[0]);
          inc(ch);
        end;
        Crc32UCFinalize(hash);

        if hash=hUses then begin//USES
          s:='';while not(ch[0]in[';',#0])do begin s:=s+ch[0];inc(ch);end;if ch[0]<>#0 then inc(ch);

          ProcessUses(s,AUnits);

        end;
      end;
    else
      inc(ch);
    end;
  end;
end;


////////////////////////////////////////////////////////////////////////////////
//                      Unit uses cache                                       //
////////////////////////////////////////////////////////////////////////////////

type
  TUnitInfo=record
    Hash:integer;
    FileName:ansistring;
    FileDate:int64;
    UsesList:TAnsiStringArray;
  end;

  TUsesCache=class
    FUnits:THetArray<TUnitInfo>;
    procedure Clear;
    Function Find(const AFileName:ansistring):integer;
    Function GetUsesList(const AFileName:ansistring;var AList:TAnsiStringArray):boolean;
    Procedure AddUsesList(const AFileName:ansistring;const AList:TAnsiStringArray);
  end;

procedure TUsesCache.Clear;
begin
  FUnits.Clear;
end;

Function TUsesCache.Find(const AFileName:ansistring):integer;
var h:integer;
begin
  h:=crc32UC(AFileName);
  if not FUnits.FindBinary(function(const a:TUnitInfo):integer begin result:=a.Hash-h end,result)then result:=-1;
end;

Function TUsesCache.GetUsesList(const AFileName:ansistring;var AList:TAnsiStringArray):boolean;
var i:integer;
begin
  i:=Find(AFileName);
  if(i>=0)then with FUnits.FItems[i]do
    if FileDate<GetFileLastWriteTime(FileName)then i:=-1;

  result:=i>=0;
  if result then AList:=FUnits.FItems[i].UsesList
            else SetLength(AList,0);
end;

Procedure TUsesCache.AddUsesList(const AFileName:ansistring;const AList:TAnsiStringArray);
var i:integer;
    ui:TUnitInfo;
begin
  with ui do begin
    FileName:=AFileName;
    Hash:=crc32UC(FileName);
    FileDate:=GetFileLastWriteTime(FileName);
    UsesList:=AList;
  end;

  i:=Find(AFileName);
  if i>=0 then FUnits.FItems[i]:=ui
          else FUnits.InsertBinary(ui,function(const a:TUnitInfo):integer begin result:=a.Hash-ui.Hash end,false);
end;

////////////////////////////////////////////////////////////////////////////////
//                      Project precompiler                                   //
////////////////////////////////////////////////////////////////////////////////

var
  UsesCache:TUsesCache;
  Plugins:IMacroPlugin;

function MacroPrecompile(const ASrc:ansistring;const AMaxCharsPerLine:integer):ansistring;overload;
var units:TAnsiStringArray;
    tma:TTextModificationArray;
begin
  result:=MacroPrecompile(Plugins,ASrc,Units,0,tma,AMaxCharsPerLine);
//  TFile('c:\dl\a.a').Write(result);
end;

function MacroPrecompileProject(const AFileName,APaths:ansistring;const ABuild:boolean;out Msg:ansistring;out PrecompiledFiles:TPrecompiledFiles;const AMaxCharsPerLine:integer):boolean;
var processedFiles:array of integer;
    paths:TAnsiStringArray;

  function FindFile(const AName,AParent:ansistring):ansistring;
  var i:integer;
  begin
    if pos(':',AName)>0 then begin//absolute
      if FileExists(AName)then exit(AName)
                          else exit('');
    end;
    if pos('\',AName)>0 then begin//relative
      result:=ExpandFileName(ExtractFilePath(AParent)+AName);
      if FileExists(result)then exit else exit('');
    end;
    //only name
    if AParent<>'' then begin
      result:=ChangeFileExt(ExtractFilePath(AParent)+AName,'.pas');
      if FileExists(result)then exit;
    end;
    for i:=0 to high(paths)do begin
      Result:=Paths[i]+'\'+AName+'.pas';
      if FileExists(result)then exit;
    end;
    result:='';
  end;

  function MustCompile(const AFileName:ansistring):boolean;
  begin
    result:=GetFileLastWriteTime(AFileName)>GetFileLastWriteTime(ChangeFileExt(AFileName,'.dcu'));
  end;

  procedure AddPrecompiledFile(const AFileName:ansistring;const AChanges:TTextModificationArray);
  begin
    setlength(PrecompiledFiles,length(PrecompiledFiles)+1);
    with PrecompiledFiles[high(PrecompiledFiles)]do begin
      FileName:=AFileName;
      Changes:=AChanges;
    end;
  end;

  procedure doIt(const AFileName,APrevFileName:ansistring);
  var s,sOriginal,sPrecompiled:ansistring;
      i,j,h:integer;
      units:TAnsiStringArray;
      L:integer;
      FromCache:boolean;
      chg:TTextModificationArray;
  begin
    h:=Crc32UC(AFileName);
    for i:=0 to high(processedFiles)do if processedFiles[i]=h then exit;
    setlength(processedFiles,length(processedFiles)+1);processedFiles[high(processedFiles)]:=h;

    CurrentFile:=AFileName;

    //check ppas
    //rebuild
    sOriginal:=TFile(AFileName);
    L:=0;
    sPrecompiled:=MacroPrecompile(Plugins,sOriginal,units,L,chg,AMaxCharsPerLine);
    if sPrecompiled='' then begin//no changed
      DeleteFile(MacroPrecompiledFileNameOf(AFileName));
      FromCache:=false;
    end else begin
      TFile(MacroPrecompiledFileNameOf(AFileName)).Write(sPrecompiled);
      AddPrecompiledFile(AFileName,chg);
      FromCache:=false;
    end;

(*    if ABuild or MustCompile(AFileName) or true{!!!!! sajnos csak igy megy, cacheolni kellene} then begin
      //precomp
      s1:=FileReadStr(AFileName);
      s2:=Precompile(Plugins,s1,units,L,chg);
      //when changed
      if s2<>'' then
        AddPrecompiledFile(AFileName,s1,s2,chg);
      FromCache:=false;
    end else begin
      FromCache:=UsesCache.GetUsesList(AFileName,units);
      if not FromCache then
        PrecompileFindUnitsOnly(FileReadStr(AFileName),units);
    end;*)

    //find units
    if not FromCache then begin
      for i:=high(units)downto 0 do begin
        s:=FindFile(units[i],AFileName);
        if s<>'' then begin
          units[i]:=s;
        end else begin
          for j:=i to high(units)-1do units[j]:=units[j+1];
          setlength(units,high(units));
        end;
      end;
      UsesCache.AddUsesList(AFileName,units);
    end;

    //recursive calls
    for i:=0 to high(units)do
      doIt(units[i],AFileName);
  end;

  procedure MakeSuccessMessage;
  var i,j:integer;
      List:TAnsiStringArray;
  begin
    //make message
    msg:='';
    setlength(list,length(PrecompiledFiles));
    for i:=0 to high(List)do List[i]:=PrecompiledFiles[i].FileName;
    //sort
    for i:=0 to high(List)-1 do for j:=i+1 to high(List)do
      if cmp(List[i],List[j])>0 then swap(List[i],List[j]);
    //concat
    for i:=0 to high(List)do
      ListAppend(msg,ChangeFileExt(ExtractFileName(List[i]),''),', ');
    msg:='All units procompiled successfully: '+msg;
  end;

  procedure SetError(const AMsg:ansistring);
  begin
    with MacroError do begin
      Msg:=AMsg;
      FileName:=CurrentFile;
      Line:=CurrentLine;
      Column:=CurrentColumn
    end;
  end;

var i:integer;
    s:ansistring;
begin
  setlength(MacroWarnings,0);setlength(PrecompiledFiles,0);msg:='';result:=false;
  MacroError.Msg:='';

  CurrentFile:='';
  CurrentLine:=1;
  CurrentColumn:=0;

  //drop unused paths
  for i:=0 to ListCount(APaths,';')-1 do begin
    s:=ListItem(APaths,i,';');
    if DirectoryExists(s)then begin
      setlength(Paths,length(Paths)+1);
      paths[high(paths)]:=s;
    end;
  end;

  if FileExists(AFileName)then begin
    try
      doIt(AFileName,'');
      MakeSuccessMessage;
      result:=true;
      SetError('Success');
    except
      on e:Exception do SetError(e.ToString);
    end;
  end else begin
    SetError('File not found: '+AFileName);
  end;

  if MacroError.Msg<>'' then begin
    MSG:='ERROR:'+MacroError.Msg+' File:'+MacroError.FileName+'('+inttostr(MacroError.Line)+')';
  end;
end;

////////////////////////////////////////////////////////////////////////////////
//                      Standard plugins                                      //
////////////////////////////////////////////////////////////////////////////////


//                      Plugin list                                           //

type
  TMacroPlugins=class(TInterfacedObject,IMacroPlugin)
  private
    FPlugins:THetArray<IMacroPlugin>;
    FPluginIndex:integer;
  public
    constructor Create;
    procedure Reset;
    function OnDirective(const ADirective,AContent:ansistring;out AReplacement:ansistring;const AParserFunc:TMacroParserFunc):boolean;
    function OnIdentifier(const ANameHash:integer):integer;
    procedure OnReplace(const AIndex:integer;const AParams:TAnsiStringArray;const AParserFunct:TMacroParserFunc;out AReplacement:ansistring);
  end;

constructor TMacroPlugins.Create;
begin
  FPluginIndex:=-1;
end;

procedure TMacroPlugins.Reset;
var i:integer;
begin
  with FPlugins do for i:=0 to FCount-1 do FItems[i].Reset;
end;

function TMacroPlugins.OnDirective(const ADirective,AContent:ansistring;out AReplacement:ansistring;const AParserFunc:TMacroParserFunc):boolean;
var i:integer;
begin
  with FPlugins do for i:=0 to FCount-1 do begin
    result:=FItems[i].OnDirective(ADirective,AContent,AReplacement,AParserFunc);
    if result then exit;
  end;
  result:=false;//no warn
  AReplacement:='';
end;

function TMacroPlugins.OnIdentifier(const ANameHash:integer):integer;
var i:integer;
begin
  with FPlugins do for i:=0 to FCount-1 do begin
    result:=FItems[i].OnIdentifier(ANameHash);
    FPluginIndex:=i;
    if result>=0 then exit;
  end;
  result:=-1;
  FPluginIndex:=-1;
end;

procedure TMacroPlugins.OnReplace(const AIndex:integer;const AParams:TAnsiStringArray;const AParserFunct:TMacroParserFunc;out AReplacement:ansistring);
begin
  if InRange(FPluginIndex,0,FPlugins.FCount-1) then
    FPlugins.FItems[FPluginIndex].OnReplace(AIndex,AParams,AParserFunct,AReplacement)
  else
    AReplacement:='';
end;

procedure RegisterMacroPlugin(const APlugin:IMacroPlugin);
begin
  if Plugins=nil then
    Plugins:=TMacroPlugins.Create;

  TMacroPlugins(Plugins).FPlugins.Append(APlugin);
end;


////////////////////////////////////////////////////////////////////////////////
//                      Script macro                                          //
////////////////////////////////////////////////////////////////////////////////

//usage: {#script hetpas script  writeln(hello world)}

type
  TPlugin_Script=class(TInterfacedObject,IMacroPlugin)
  private
    nsGlobal:TNameSpace;
    ctx:TContext;
//    procedure log(const s:ansistring);
  public
    procedure Reset;
    function OnDirective(const ADirective,AContent:ansistring;out AReplacement:ansistring;const AParserFunc:TMacroParserFunc):boolean;
    function OnIdentifier(const ANameHash:integer):integer;
    procedure OnReplace(const AIndex:integer;const AParams:TAnsiStringArray;const AParserFunc:TMacroParserFunc;out AReplacement:ansistring);
    destructor Destroy;override;
  end;

var
  _WriteBuffer:AnsiString;
  _WriteBuilder:IAnsiStringBuilder;

procedure _WriteBuilderInit;
begin
  _WriteBuffer:='';
  _WriteBuilder:=AnsiStringBuilder(_WriteBuffer);
end;

function _WriteBuilderFinish:ansistring;
begin
  _WriteBuilder.Finalize;
  result:=_WriteBuffer;
  _WriteBuilder:=nil;
  _WriteBuffer:='';
end;

{procedure TPlugin_Script.log(const s:ansistring);
begin
  //nothing
end;}

procedure TPlugin_Script.Reset;
begin
  FreeAndNil(ctx);
  FreeAndNil(nsGlobal);
  nsGlobal:=TNameSpace.Create('global');
  nsGlobal.nsUses.Append(nsSystem);
  with nsGlobal do begin
    AddFunction('write(...)',
      function(const p:TVariantArray):variant
      var i:integer;
      begin
        for i:=0 to high(p)do _WriteBuilder.AddStr(ToStr(p[i]));
      end
    );
    AddFunction('writeln(...)',
      function(const p:TVariantArray):variant
      var i:integer;
      begin
        for i:=0 to high(p)do _WriteBuilder.AddStr(ToStr(p[i]));
        _WriteBuilder.AddStr(#13#10);
      end
    );
    AddFunction('GCN_MacroGen(what, ...)',
      function(const p:TVariantArray):variant
      var i:integer;
          params:TArray<AnsiString>;
      begin
        if addr(GCN_MacroGen)=nil then raise Exception.Create('Unable to call GCN_MacroGen from macro preprocessor.');
        setlength(params, length(p)-1);
        for i:=1 to high(p)do params[i-1]:=p[i];
        _WriteBuilder.AddStr(GCN_MacroGen(p[0], params));
      end
    );
  end;
  ctx:=TContext.Create(nil,nsGlobal,nil);

  GCN_MacroGen('reset',nil);
end;

function TPlugin_Script.OnDirective(const ADirective,AContent:ansistring;out AReplacement:ansistring;const AParserFunc:TMacroParserFunc):boolean;
var n:TNodeBase;
begin
//  log('TPlugin_Script.OnDirective '+ADirective);
  result:=false;
  if cmp(ADirective,'#script')=0 then begin
//    log('TPlugin_Script.OnDirective '+ADirective+' FOUND');

    result:=true;
    _WriteBuffer:='';_WriteBuilder:=AnsiStringBuilder(_WriteBuffer); //clear

    try
      n:=CompilePascalProgram(AContent,nsGlobal); //compile
    except
      on e:Exception do raise Exception.Create('Error compiling #Script macro: '+e.ClassName+' '+e.Message);
    end;

    try
      if Assigned(n)then n.Eval(ctx); //running
    except
      on e:Exception do begin
        FreeAndNil(n);
        raise Exception.Create('Error running #Script macro: '+e.ClassName+' '+e.Message);
      end;
    end;

    AReplacement:=_WriteBuilderFinish;
//    log('TPlugin_Script.OnDirective Replacement is '+AReplacement);

    FreeAndNil(n); //cleanup
  end;
end;

function TPlugin_Script.OnIdentifier(const ANameHash:integer):integer;
begin
  result:=-1;
end;

procedure TPlugin_Script.OnReplace(const AIndex:integer;const AParams:TAnsiStringArray;const AParserFunc:TMacroParserFunc;out AReplacement:ansistring);
begin
  //nothing
end;

destructor TPlugin_Script.Destroy;
begin
  FreeAndNil(ctx);
  FreeAndNil(nsGlobal);
  _WriteBuilder:=nil;
end;


////////////////////////////////////////////////////////////////////////////////
//                      C like #DEFINE macro                                  //
////////////////////////////////////////////////////////////////////////////////

//syntax: {#DEFINE m_add(a,b) ((a)+(b))}   //{} are optional
//multiline syntax: #define nfjdsa fewq \ <- new line
//other syntax: #macro add(a,b) ((a)+(b)) #endm
//    #undef macroname
//    #macroParam : stringize
//    a##b : concatenate
//    __line__
//    __file__
//    __date__
//    __time__
//    __for__(i in [1..10], writeln(i); )
//    __if__(true, bla, bla, bla)
//    __ifdef__(identifier, bla, bla, bla)
//    __ifndef__(identifier, bla, bla, bla)

var Plugin_script:TPlugin_Script; //Plugin_define will use it.

function ScriptNs:TNameSpace; begin result:=Plugin_script.nsGlobal; end;
function ScriptCtx:TContext; begin result:=Plugin_script.ctx; end;

type
  TDefineMacroDefinition=record
    ParamCnt:integer;
    ParamNames:TAnsiStringArray;
    Content:ansistring;
    ScriptFunctName:ansistring;
  end;
  PDefineMacroDefinition=^TDefineMacroDefinition;

  TPlugin_Define=class;

  TDefineMacro=class
    FOwner:TPlugin_Define;
    FName:ansistring;
    FNameHash:Integer;

    FDefinitions:array of TDefineMacroDefinition;
    constructor Create(const AOwner:TPlugin_Define; const AName:ansistring);
    function Compile(const AParams:TAnsiStringArray;const AParserFunc:TMacroParserFunc):ansistring;
    function ByParamCnt(AParamCnt:integer;const AAlloc:boolean=false):PDefineMacroDefinition;
  end;

  TPlugin_Define=class(TInterfacedObject,IMacroPlugin)
  private
    FList:THetArray<TDefineMacro>;
    function ByName(const AName:ansistring;const CreateNew:boolean=false):TDefineMacro;
    function ByNameHashIdx(const ANameHash:integer):integer;
    function ByNameHash(const ANameHash:integer):TDefineMacro;
    procedure AddMacro(const ADefinition:ansistring);
    procedure RemoveMacro(const AName: ansistring);
    destructor Destroy;override;
    procedure ClearDefineList;
  public
    procedure Reset;
    function OnDirective(const ADirective,AContent:ansistring;out AReplacement:ansistring;const AParserFunc:TMacroParserFunc):boolean;
    function OnIdentifier(const ANameHash:integer):integer;
    procedure OnReplace(const AIndex:integer;const AParams:TAnsiStringArray;const AParserFunct:TMacroParserFunc;out AReplacement:ansistring);
  end;

{ TDefineMacro }

constructor TDefineMacro.Create(const AOwner:TPlugin_Define; const AName:ansistring);
begin
  FOwner:=AOwner;
  FName:=AName;
  FNameHash:=Crc32UC(FName);
end;

function TDefineMacro.ByParamCnt(AParamCnt:integer;const AAlloc:boolean=false):PDefineMacroDefinition;
var i:integer;
begin
  for i:=0 to high(FDefinitions)do if FDefinitions[i].ParamCnt=AParamCnt then
    exit(@FDefinitions[i]);
  if AAlloc then begin
    SetLength(FDefinitions,length(FDefinitions)+1);
    result:=@FDefinitions[high(FDefinitions)];
    Result^.ParamCnt:=AParamCnt;
  end else
    result:=nil;
end;


type
  TReplaceIdentifiersFunct = reference to function(var s:ansistring):boolean;

function ReplaceIdentifiers(const ASrc:ansistring; const funct:TReplaceIdentifiersFunct):ansistring;

  function CheckBackForPoint(ch:PAnsiChar):boolean;
  begin
    while ch[-1]in[' ',#13,#10]do dec(ch);
    result:=ch[-1]='.'
  end;

var ch,chBegin,chSt, chLast:PAnsiChar;
    s:ansistring;
    hashCnt:integer;
    sb:IAnsiStringBuilder;
begin
  if ASrc='' then exit;

  sb:=AnsiStringBuilder(Result,True);

  ch:=pointer(ASrc);
  chBegin:=ch;
  chLast:=ch;

  while true do begin
    case ch[0] of
      #0:break;
      #13,#10:inc(ch);
      '''':begin
        inc(ch);while not(ch[0] in[#0,''''])do inc(ch);
        if ch<>#0 then inc(ch);
      end;
      '"':begin
        inc(ch);while not(ch[0] in[#0,'"'])do inc(ch);
        if ch<>#0 then inc(ch);
      end;
      '{':begin
        inc(ch);
        while not(ch[0] in[#0,'}'])do inc(ch);
        if ch<>#0 then inc(ch);
      end;
      '(':begin
        if ch[1]='*' then begin
          inc(ch,2);
          while(ch[0]<>#0)and not((ch[0]='*')and(ch[1]=')'))do inc(ch);
          if ch[0]<>#0 then inc(ch,2);
        end else
          inc(ch);
      end;
      '/':begin
        if ch[1]='/' then begin
          while not(ch[0] in[#13,#10,#0])do inc(ch);
        end else if ch[1]='*' then begin
          inc(ch,2);
          while(ch[0]<>#0)and not((ch[0]='*')and(ch[1]='/'))do inc(ch);
          if ch[0]<>#0 then inc(ch,2);
        end else
          inc(ch);
      end;
      'a'..'z','A'..'Z','_':begin
        chSt:=ch; inc(ch);
        while ch[0] in['a'..'z','A'..'Z','_','0'..'9'] do inc(ch);
        s:=StrMake(chSt, ch);

        // #x: stringize parameter value   x##y: concatenate identifiers

        //check # before identifier
        hashCnt:=0;
        while(hashCnt<2)and(integer(chSt)>integer(chBegin))and(chSt[-1]='#')do begin inc(hashCnt); dec(chSt); end;

        //check # after identifier
        if(ch[1]='#')and(ch[2]='#')then inc(ch,2);

        if funct(s)or(hashCnt=2)then begin

          if hashCnt=1 then s:=ToPas(s); //stringize

          sb.AddStr(StrMake(chLast,chSt));
          sb.AddStr(s);

          chLast:=ch;
        end;

      end;
    else
      inc(ch);
    end;
  end;

  sb.AddStr(StrMake(chLast,ch));
end;


function TDefineMacro.Compile(const AParams:TAnsiStringArray;const AParserFunc:TMacroParserFunc):ansistring;

(*  procedure rep(var s:ansistring;const AFrom,ATo:ansistring);
  begin
    //it's a bit slow and also bogus
    Replace('##'+AFrom+'##',ATo,s,[roIgnoreCase,roWholeWords,roAll]);
    Replace('##'+AFrom,ATo,s,[roIgnoreCase,roWholeWords,roAll]);
    Replace(AFrom+'##',ATo,s,[roIgnoreCase,roWholeWords,roAll]);
    Replace('#'+AFrom,''''+replacef('''','''''',ATo,[roAll])+'''',s,[roIgnoreCase,roWholeWords,roAll]);
    Replace(AFrom,ATo,s,[roIgnoreCase,roWholeWords,roAll]);
  end; *)

  function DoExtra(const p:TArray<AnsiString>):ansistring;
    procedure error(s:ansistring);begin raise Exception.Create('preprocessor error: '+FName+' :'+s);end;
  var id:AnsiString;
      v:Variant;
      line,s:ansistring;
      i:integer;
      interval:ansistring;
  begin
    result:='';
    if Length(p)<2 then error('invalid number of params ');
    id:=WordAt(trimf(p[0]),1);
    line:='';for i:=1 to high(p)do ListAppend(line,p[i],',');//haldle ','
    try

      if FName='__for__' then begin
        //get element list (no identifiers yet)
        interval:=AParserFunc(p[0]);
        v:=Eval('var __forvariable1__:=();for var '+interval+' do __forvariable1__:=__forvariable1__&str('+id+');__forvariable1__');

        for i:=0 to VarArrayAsPSafeArray(v)^.Bounds[0].ElementCount-1 do begin
          //old shit: s:=line; rep(s,id,tostr(v[i]));

          s:=ReplaceIdentifiers(line,
            function(var s:ansistring):boolean
            begin
              result:=cmp(s,id)=0;
              if result then s:=tostr(v[i]);
            end
          );

          result:=result+s+' ';
        end;
      end else if FName='__if__' then begin
        if Eval(AParserFunc(p[0])) then result:=line;
      end else if FName='__ifdef__' then begin
        if FOwner.ByName(id)<>nil then result:=line;
      end else if FName='__ifndef__' then begin
        if FOwner.ByName(id)=nil then result:=line;
      end else
        raise Exception.Create('unknown FName: '+FName);
    except
      on e:Exception do error(e.ClassName+' '+e.Message);
    end;

  end;

var def:PDefineMacroDefinition;
    s,p:ansistring;
    n:TNodeBase;
begin
  def:=ByParamCnt(Length(AParams));
  if def=nil then
    raise Exception.Create('preprocessor: #Define '+FName+' : invalid parameter count ('+tostr(length(AParams))+')');

  if def.Content=#1 then begin
    if FName='__line__' then result:=''''+inttostr(CurrentLine)+'''' else
    if FName='__file__' then result:=''''+CurrentFile+'''' else
    if FName='__date__' then result:=''''+FormatDateTime('YYYY.MM.DD',now)+'''' else
    if FName='__time__' then result:=''''+FormatDateTime('HH:NN:SS',now)+'''' else
    if(FName='__for__')or(FName='__if__')or(FName='__ifdef__')or(FName='__ifndef__')then result:=DoExtra(AParams)
    else
      raise Exception.Create('preprocessor: unhandles special macro identifier "'+FName+'"');
  end else if def.scriptFunctName<>'' then begin //scriptFunction
    p:=''; for s in AParams do ListAppend(p,ToPas(AParserFunc(s)),', ');
    s:=def.ScriptFunctName+'('+p+');';
    n:=CompilePascalProgram(s, ScriptNs);
    _WriteBuilderInit;
    if n<>nil then try
      n.Eval(ScriptCtx);
    finally n.Free end;
    result:=_WriteBuilderFinish;
  end else begin
    result:={ParserFunc}(def.Content);  //a rekurzio a definition nagyon elcseszi a dolgokat!

// old shit: for i:=0 to min(high(AParams),high(def.ParamNames))do rep(result,def.ParamNames[i],AParams[i]);

    result:=ReplaceIdentifiers(result,
      function(var s:ansistring):boolean
      var i:integer;
      begin
        for i:=0 to min(high(AParams),high(def.ParamNames))do if cmp(s,def.ParamNames[i])=0 then begin
          s:=AParams[i];
          exit(true);
        end;
        result:=false;
      end
    );

  end;
end;

{ TPlugin_Define}

function TPlugin_Define.ByName(const AName:ansistring;const CreateNew:boolean=false):TDefineMacro;
var m:TDefineMacro;
begin
  result:=ByNameHash(crc32UC(AName));

  if(result=nil)and CreateNew then begin
    m:=TDefineMacro.Create(self, AName);
    result:=m;
    FList.InsertBinary(result,function(const a:TDefineMacro):integer begin result:=cmp(a.FNameHash,m.FNameHash) end,false);
    {kell a cmp(), mert tejles integer range-t lefedi a hash!!}
  end;
end;

function TPlugin_Define.ByNameHashIdx(const ANameHash:integer):integer;
begin
  if not FList.FindBinary(function(const a:TDefineMacro):integer begin result:=cmp(a.FNameHash,ANameHash) end,result)then result:=-1;
end;

function TPlugin_Define.ByNameHash(const ANameHash:integer):TDefineMacro;
var i:integer;
begin
  i:=ByNameHashIdx(ANameHash);
  if i>=0 then result:=FList.FItems[i]
          else result:=nil;
end;

procedure TPlugin_Define.AddMacro(const ADefinition:ansistring);
var i,j:integer;
    s,Name,Params,Content:AnsiString;
    m:TDefineMacro;
    pn:TAnsiStringArray;
    def:PDefineMacroDefinition;
    ch:PAnsiChar;
begin
  s:=trimf(ADefinition);
  i:=1;while(i<=length(s))and(s[i]in['a'..'z','A'..'Z','_','0'..'9'])do inc(i);
  Name:=copy(s,1,i-1);
  if name='' then exit;

  if CharN(s,i)='(' then begin
    j:=PosEx(')',s,i);
    if j<0 then exit;
    Params:=copy(s,i+1,j-i-1);
    inc(j);
    if charn(s,j)=' ' then inc(j);
    Content:=copy(s,j);
  end else{ if CharN(s,i)=' 'then }begin
    Content:=copy(s,i);
  end;

  m:=ByName(Name,true);

  pn:=ListSplit(Params,',');
  def:=m.ByParamCnt(length(pn),true);
  def.ParamNames:=pn;

  //script?
  if content<>'' then begin
    ch:=pointer(content);
    ParseSkipWhiteSpace(ch);
    if ParseIdentifier(ch,s)and(cmp(s,'script')=0)then begin
      def.ScriptFunctName:='script_'+Name+'_'+tostr(length(pn))+'param';
      s:='procedure '+def.ScriptFunctName+'('+params+');begin'#13#10+StrMake(ch,length(content)-(integer(ch)-integer(content)))+#13#10'end;';

      ScriptNs.Delete(def.ScriptFunctName);
      CompilePascalProgram(s, ScriptNs).Free;
    end;
  end;

  def.Content:=het.Utils.TrimF(Content);
end;

procedure TPlugin_Define.RemoveMacro(const AName:ansistring);
var i:integer;
begin
  i:=ByNameHashIdx(Crc32UC(AName));
  if i>=0 then
    FList.Remove(i);
end;

destructor TPlugin_Define.Destroy;
begin
  ClearDefineList;
  inherited;
end;

procedure TPlugin_Define.ClearDefineList;
var i:integer;
begin
  with FList do for i:=FCount-1 downto 0 do FItems[i].Free;
  FList.Clear;
end;

procedure TPlugin_Define.Reset;

  procedure Add(AName:ansistring;AParamCount:integer);
  var m:TDefineMacro;
      def:PDefineMacroDefinition;
      pn:TArray<AnsiString>;
      i:integer;
  begin
    m:=ByName(AName,true);

    setlength(pn,AParamCount);
    for i:=0 to high(pn)do pn[i]:='param'+tostr(i);

    def:=m.ByParamCnt(length(pn),true);
    def.ParamNames:=pn;
    def.Content:=#1;//special macro
  end;

var i:integer;
begin
  ClearDefineList;

  add('__line__',0);
  add('__file__',0);
  add('__date__',0);
  add('__time__',0);
  for i:=2 to 64 do begin //lame but works
    add('__for__',i);
    add('__if__',i);
    add('__ifdef__',i);
    add('__ifndef__',i);
  end;
end;

function TPlugin_Define.OnDirective(const ADirective,AContent:ansistring;out AReplacement:ansistring;const AParserFunc:TMacroParserFunc):boolean;
  function DirectiveIs(const s:ansistring):boolean;begin result:=cmp(ADirective,s)=0;OnDirective:=result;end;
var code,name:ansistring;
    i:integer;
    f:TFile;
    oldcf:string;
begin
  result:=false;
  if DirectiveIs('#define')or DirectiveIs('#macro')then begin
    AReplacement:='';
    AddMacro(AContent);
  end else if DirectiveIs('#assign')then begin
    AReplacement:='';
    try
      i:=pos(' ',AContent,[]);
      if i<0 then i:=length(AContent)+1;
      code:=copy(AContent,i+1);
      code:=AParserFunc(code);
      name:=copy(AContent,1,i-1);
      AddMacro(name+' '+ansistring(Eval(code)));
    except
      on e:exception do raise Exception.Create('Exception occured evaluating "#assign '+AContent+'" '+e.ClassName+' '+e.Message);
    end;
  end else if DirectiveIs('#undef')then begin
    AReplacement:='';
    RemoveMacro(TrimF(AContent));
  end else if DirectiveIs('#include')then begin
    oldcf:=CurrentFile;
    try
      f:=TFile(AContent);
      if not f.exists then begin
        f:=TFile(AppPath+'include\'+AContent); //try in default include path
        if not f.exists then raise Exception.Create('Include file not found: '+AContent);
      end;

      CurrentFile:=AContent;
      code:=f;

      //strip source format specifier (asm_il, asm_isa)
      trim(code);
      name:=lc(WordAt(code,1,false));
      if(name='asm_il')or(name='asm_isa')then begin
        code:=TrimF(copy(code,length(name)+1));
        if BeginsWith(code,'(')and EndsWith(code,')')then begin
          code:=copy(code,2,length(code)-2);
        end else raise Exception.Create('Missing "(" and/or ")" at '+name+' directive.');
      end;

      AReplacement:=AParserFunc(code);

    except
      on e:Exception do raise Exception.Create('#include error: '+e.ClassName+' '+e.Message);
    end;
    CurrentFile:=oldcf;
  end;
end;

function TPlugin_Define.OnIdentifier(const ANameHash:integer):integer;
begin
  result:=ByNameHashIdx(ANameHash);
end;

procedure TPlugin_Define.OnReplace(const AIndex:integer;const AParams:TAnsiStringArray;const AParserFunct:TMacroParserFunc;out AReplacement:ansistring);
begin
  AReplacement:=FList.FItems[AIndex].Compile(AParams,AParserFunct);
end;

initialization
  hUses:=crc32UC('uses');
  UsesCache:=TUsesCache.Create;
  if Plugins=nil then
    Plugins:=TMacroPlugins.Create;

  RegisterMacroPlugin(TPlugin_Define.create as IMacroPlugin);

  Plugin_script:=TPlugin_Script.Create;
  RegisterMacroPlugin(Plugin_script as IMacroPlugin);
finalization
  FreeAndNil(UsesCache);
end.
