unit UFrmHelp;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ExtCtrls,
  het.utils, het.Arrays;

{DEFINE EXPORTIDENTIFIERS}

type
  THelpEntry=record
    NamePath:ansistring;
    Rtf:ansistring;
    function Category:ansistring;
    function Name:ansistring;
  end;
  PHelpEntry=^THelpEntry;
  THelpKeyword=record
    KeyWord:ansistring;
    EntryIdx:integer;
    isTopic:boolean;
  end;
  THelpSys=record
    Entries:TArray<THelpEntry>;
    Categories:THetArray<ansistring>;
    Keywords:THetArray<THelpKeyword>;
  {$IFDEF EXPORTIDENTIFIERS}
    Identifiers:THetArray<ansistring>;
  {$ENDIF}
    procedure LoadFromStr(const Src:ansistring);
  end;

type
  TFrmHelp = class(TForm)
    cbCategory: TComboBoxEx;
    RichEdit1: TRichEdit;
    lvEntries: TListView;
    Splitter1: TSplitter;
    Timer1: TTimer;
    Panel1: TPanel;
    procedure cbCategoryChange(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
    HelpSys:THelpSys;
    LoadedKeyword:ansistring;
  public
    { Public declarations }
    procedure LoadFromStr(const ASrc:ansistring);
    procedure ShowTopic(const AKeyWord:ansistring);
  end;

var
  FrmHelp: TFrmHelp;

implementation

uses
  het.filesys;

{$R *.dfm}

{ THelpEntry }

function THelpEntry.Category: ansistring;
var i:integer;
begin
  i:=Pos('/',NamePath,[poBackwards]);
  if i=0 then result:='' else result:=copy(NamePath,1,i-1);
end;

function THelpEntry.Name: ansistring;
var i:integer;
begin
  i:=Pos('/',NamePath,[poBackwards]);
  if i=0 then result:=NamePath else result:=copy(NamePath,i+1);
end;

{ THelpSys }

procedure THelpSys.LoadFromStr(const Src:ansistring);

{$IFDEF EXPORTIDENTIFIERS}
  procedure ExportIdentifiers;
  var i,j:integer;
      s1,cat,inst:ansistring;
  begin
    with AnsiStringBuilder(s1,true),Identifiers do begin
      for i:=0 to Count-1 do begin
        inst:=FItems[i];
        for j:=0 to Keywords.Count-1 do if cmp(Keywords.FItems[j].KeyWord,inst)=0 then begin
          cat:=Entries[Keywords.FItems[j].EntryIdx].Category;
          if Pos('dcl',inst)=1 then cat:='3' else
          if pos('Declarat',cat)>0 then cat:='3' else
          if pos('Flow Control',cat)>0 then cat:='2' else
          if pos('Register',cat)>0 then cat:='1' else
            cat:='0';
          AddStr(cat+inst+#13#10);
          break;
        end;
      end;
      Finalize;
    end;
    TFile('extracted_identifiers.txt').Write(s1);
  end;
{$ENDIF}

var actline:ansistring;
    e:PHelpEntry;

  procedure closeLast;
  begin
    if e<>nil then with e^ do begin
      Rtf:=Rtf+'}';
    end;
  end;

  function escape(const s:ansistring):ansistring;
  begin
    result:=s;
    replace('{','\{',result,[roAll]);
    replace('}','\}',result,[roAll]);
  end;

  procedure AddKeyword(const s:ansistring;isCode:boolean=false);
  var kw:THelpKeyword;
      idx:integer;
  begin
    if s='' then exit;
    kw.KeyWord:=s;
    kw.EntryIdx:=Length(Entries)-1;
    kw.isTopic:=not isCode;

    if not Keywords.FindBinary(kw,function(const a,b:THelpKeyword):integer begin result:=cmp(a.KeyWord,b.KeyWord)end,idx)then
      Keywords.Insert(kw,idx)
    else if kw.isTopic then
      Keywords.FItems[idx]:=kw;

    {$IFDEF EXPORTIDENTIFIERS}
    if isCode then begin
      Identifiers.InsertBinary(s,function(const a,b:ansistring):integer begin result:=cmp(a,b)end,false);
    end;
    {$ENDIF}
  end;

var s1,s3:ansistring;
    i,idx:integer;
    countNonCodeText:integer;
const
  rtfHeader='{\rtf\ansi\deff0{\fonttbl{\f0\fswiss Arial;}{\f1\fmodern Courier New;}}{\colortbl;\red0\green0\blue255;\red130\green130\blue130;\red80\green110\blue30;}';
  fmtHeading='\plain\f0\fs20\b';
  fmtNormal='\plain\f0\fs16';
  fmtValid='\plain\f0\fs16\cf3';
  fmtCode='\plain\f1\fs16\cf1';
  fmtComment='\plain\f1\fs16\cf2';
begin
  countNonCodeText:=0;//nowarn
  e:=nil;
  for actLine in ListSplit(Src,#10,true)do begin
    if CharN(actLine,1)='/' then begin
      CloseLast;
      SetLength(Entries,length(Entries)+1);
      e:=@Entries[length(Entries)-1];
      e.NamePath:=actLine;

//      Categories.InsertBinary(e.Category,function(const a,b:ansistring):integer begin result:=cmp(a,b)end,false);
      if not Categories.Find(function(const a:ansistring):boolean begin result:=cmp(e.Category,a)=0 end,idx)then
        Categories.Insert(e.Category,Categories.Count);

      AddKeyword(e.Name);
      e.Rtf:=rtfHeader+fmtHeading+' '+e.Category+'/'+fmtHeading+' '+e.Name+'\par\plain\fs20\par ';

      countNonCodeText:=0;
    end else if e<>nil then with e^ do begin
      if charn(actLine,1)='>' then begin

        i:=pos('//',actLine);if i<=0 then i:=length(actLine)+1;
        s1:=copy(actLine,2,i-2);//code
        s3:=Copy(actLine,i);//comment

        if countNonCodeText<=2 then
          AddKeyword(WordAt(s1,1),true);

        Rtf:=Rtf+fmtCode+' '+escape(s1);
        if s3<>'' then
          Rtf:=Rtf+fmtComment+' '+escape(s3);

        Rtf:=Rtf+'\par ';
      end else begin
        inc(countNonCodeText);

        if(Pos('Valid for',actline)>0)then Rtf:=Rtf+fmtValid else Rtf:=Rtf+fmtNormal;
        Rtf:=Rtf+' '+escape(actLine)+'\par ';
      end;
    end;
  end;
  CloseLast;

{$IFDEF EXPORTIDENTIFIERS}
  ExportIdentifiers;
{$ENDIF}
end;

{ TFrmHelp }

procedure TFrmHelp.LoadFromStr(const ASrc: ansistring);
var i:integer;
begin
  HelpSys.LoadFromStr(ASrc);
  with cbCategory, Items do begin BeginUpdate;Clear;
    for i:=0 to HelpSys.Categories.Count-1 do begin
      Add(HelpSys.Categories.FItems[i]);
    end;
    EndUpdate;
    ItemIndex:=0;
  end;
end;

procedure TFrmHelp.cbCategoryChange(Sender: TObject);
var sl:TStringList;
    i,j:integer;
    s,sOld,ename:ansistring;
begin
  sl:=TStringList.Create;
  s:=cbCategory.Text;
  if cbCategory.Items.IndexOf(s)>=0 then begin
    for i:=0 to length(HelpSys.Entries)-1 do with HelpSys.Entries[i]do
      if cmp(Category,s)=0 then sl.add(name);
  end else begin
    with HelpSys.Keywords do for i:=0 to Count-1 do with FItems[i]do
      if cmp(copy(KeyWord,1,length(s)),s)=0 then begin
        ename:=HelpSys.Entries[EntryIdx].Name;
        if sl.IndexOf(ename)<0 then
          sl.add(ename);
      end;
  end;
  sl.sort;

  with lvEntries,Items do begin
    j:=-1;
    if ItemIndex>=0 then sOld:=Items[ItemIndex].Caption else sOld:='';
    BeginUpdate;Clear;
    for i:=0 to sl.Count-1 do begin
      Add.Caption:=sl[i];
      if sl[i]=sOld then
        j:=i;
    end;
    EndUpdate;
    if j>=0 then ItemIndex:=j else if Count>0 then ItemIndex:=0;
  end;
  sl.Free;
end;

procedure TFrmHelp.Timer1Timer(Sender: TObject);
var selected,s:AnsiString;
    st:TRawStream;
    i:integer;
begin
  if lvEntries.ItemIndex<0 then selected:=''
                           else selected:=lvEntries.Items[lvEntries.ItemIndex].Caption;
  if selected=LoadedKeyword then exit;
  LoadedKeyword:=selected;

  s:='';
  if(selected<>'')and HelpSys.Keywords.FindBinary(function(const e:THelpKeyword):integer begin result:=cmp(selected,e.KeyWord)end,i)then
    s:=HelpSys.Entries[HelpSys.Keywords.FItems[i].EntryIdx].rtf;

  st:=TRawStream.Create(s);
  RichEdit1.Lines.LoadFromStream(st);
  st.Free;
end;

procedure TFrmHelp.ShowTopic(const AKeyWord: ansistring);
var kw:ansistring;
begin
  kw:=AKeyWord;
  while true do begin
    cbCategory.Text:=kw;
    if(kw='')or(lvEntries.Items.Count>0)then break;
    setlength(kw,length(kw)-1);
  end;
end;

end.
