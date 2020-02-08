unit UFrmIdeBase;

////////////////////////////////////////////////////////////////////////////////
/// Base IDE for any language                                                ///
/// inherited only!!!!                                                       ///
////////////////////////////////////////////////////////////////////////////////

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Menus, ExtCtrls, StdCtrls, math, clipbrd, ImgList, ComCtrls,
  het.utils, het.Objects, het.Variants, het.arrays, het.Parser, het.codeeditor,
  unsSystem;

type
  TEditorSheet=class(TTabSheet)
  public
    Editor:TCodeEditor;
    destructor Destroy;override;
    function Changed:boolean;
    function IsNewAndUnchanged:boolean;
    procedure UpdateUI;
  end;

  TFrmIdeBase = class(TForm)
    pLeft: TPanel;
    Splitter2: TSplitter;
    pcRight: TPageControl;
    pcEditor: TPageControl;
    tUpdateUI: TTimer;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    ilIcons: TImageList;
    StatusBar: TStatusBar;
    pFindReplace: TPanel;
    cbFind: TComboBoxEx;
    chWholeWords: TCheckBox;
    chBackwards: TCheckBox;
    bFindNext: TButton;
    cbReplace: TComboBoxEx;
    bReplace: TButton;
    bReplaceAll: TButton;
    chPromptOnReplace: TCheckBox;
    bFindClose: TButton;
    tsOutput: TTabSheet;
    MainMenu1: TMainMenu;
    mFile: TMenuItem;
    mFileNew: TMenuItem;
    mFileOpen: TMenuItem;
    mFileReopen: TMenuItem;
    N1: TMenuItem;
    mFileSave: TMenuItem;
    mFileSaveAs: TMenuItem;
    mFileSaveAll: TMenuItem;
    mFileClose: TMenuItem;
    mFileCloseAll: TMenuItem;
    N2: TMenuItem;
    mFileExit: TMenuItem;
    mEdit: TMenuItem;
    mEditUndo: TMenuItem;
    mEditRedo: TMenuItem;
    N3: TMenuItem;
    mEditCut: TMenuItem;
    mEditCopy: TMenuItem;
    mEditPaste: TMenuItem;
    mEditDelete: TMenuItem;
    mEditSelectAll: TMenuItem;
    mSearch: TMenuItem;
    mCompile: TMenuItem;
    mHelp: TMenuItem;
    mSearchFind: TMenuItem;
    mSearchReplace: TMenuItem;
    mSearchSearchAgain: TMenuItem;
    mSearchGotoLineNumber: TMenuItem;
    mCompileCompile: TMenuItem;
    mCompileRun: TMenuItem;
    mHelpHelpatCursor: TMenuItem;
    mFileReopenClear: TMenuItem;
    N4: TMenuItem;
    chCaseSensitive: TCheckBox;
    N6: TMenuItem;
    mEditCopyHtml: TMenuItem;
    procedure mFileNewClick(Sender: TObject);
    procedure tUpdateUITimer(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure mFileExitClick(Sender: TObject);
    procedure mFileSaveClick(Sender: TObject);
    procedure mFileOpenClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure mFileSaveAsClick(Sender: TObject);
    procedure mFileSaveAllClick(Sender: TObject);
    procedure mFileCloseClick(Sender: TObject);
    procedure mFileCloseAllClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure mFileReopenClearClick(Sender: TObject);
    procedure mEditUndoClick(Sender: TObject);
    procedure mEditRedoClick(Sender: TObject);
    procedure mEditCutClick(Sender: TObject);
    procedure mEditCopyClick(Sender: TObject);
    procedure mEditPasteClick(Sender: TObject);
    procedure mEditDeleteClick(Sender: TObject);
    procedure mEditSelectAllClick(Sender: TObject);
    procedure mHelpHelpAtCursorClick(Sender: TObject);
    procedure mSearchFindClick(Sender: TObject);
    procedure mSearchReplaceClick(Sender: TObject);
    procedure cbFindKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure bFindNextClick(Sender: TObject);
    procedure cFindCloseClick(Sender: TObject);
    procedure bReplaceClick(Sender: TObject);
    procedure bReplaceAllClick(Sender: TObject);
    procedure mSearchSearchAgainClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure mCompileCompileClick(Sender: TObject);
    procedure mCompileRunClick(Sender: TObject);
    procedure mEditCopyHtmlClick(Sender: TObject);
  private
    { Private declarations }
    running:boolean;
    OriginalCaption:string;
    procedure mFileReopenItemClick(Sender: TObject);
  private
  type
    TFindOperation=(opNone,opFind,opReplace,opReplaceAll);
    TFindCommand=record
      Operation:TFindOperation;
      FindText,ReplaceWith:ansistring;
      CaseSensitive,WholeWords,Backwards,PromptOnReplace:boolean;
    end;
  private
    LastFindCommand:TFindCommand;
    procedure FindCommandPrepareFromUi(var fc:TFindCommand;const op:TFindOperation);
    procedure FindCommandExecute(const fc:TFindCommand);
  public
    { Public declarations }
    function EditorCount:integer;
    function GetEditor(const n:variant):TEditorSheet;
    property Editor[const n:Variant]:TEditorSheet read GetEditor;
    function GetActEditor:TEditorSheet;
    function ActCodeEditor:TCodeEditor;
    procedure SetActEditor(const Value:TEditorSheet);
    property ActEditor:TEditorSheet read GetActEditor write SetActEditor;

    function NewEditor: TEditorSheet;
    procedure NewFile;
    procedure OpenFile(const fn: AnsiString);

    function GetOpenedFiles:string;procedure SetOpenedFiles(const Value:string);

    function GetReopenHistory:string;procedure SetReopenHistory(const Value:string);
    procedure AddReopenHistory(const fn:string);

    function GetDesktopConfig:AnsiString;
    procedure SetDesktopConfig(const Value:ansistring);
    property DesktopConfig:ansistring read GetDesktopConfig write SetDesktopConfig;

    function GetFindWindowState:integer;procedure SetFindWindowState(const Value:integer);
    property FindWindowState:integer{0..2} read GetFindWindowState write SetFindWindowState;

    procedure UpdateMenuItems;
    procedure UpdateStatusbar;

    function GetStatus:ansistring;
    procedure SetStatus(const Value:ansistring);
    property Status:ansistring read GetStatus write SetStatus;
  public //output
    mConsole:TCodeEditor;
  published //streamed properties
    {!!!! property WindowPlacement; !!!Ez XE-n F2084 Internal Error-t dob, ha van debugInfo
     !!!! tilos ClassHelper propertyt published-e tenni
     !!!! megoldas: manualisan rakotni a propertyt a Get/Set WindowPlacement helper finctokra}
    property WindowPlacement:ansistring read GetWindowPlacement write SetWindowPlacement;
    property OpenedFiles:string read GetOpenedFiles write SetOpenedFiles;
    property ReopenHistory:string read GetReopenHistory write SetReopenHistory;
//    property pcRightActivePageIdx:integer read getpcRightActivePageIdx write setpcRightActivePageIdx;
  public
    function OnGetFileExt:ansistring;virtual;
    //Syntax highight support
    procedure OnSyntax(const Sender:TCodeEditor;const ASrc:ansistring;var ASyntaxHighlight, ATokenHighlight:ansistring; bigComments:PAnsiChar; bigCommentsLen:integer; const AFrom:integer=1;const ATo:integer=$7fffffff);virtual;
    //Code insight
    function OnGetWordList(const Editor:TCodeEditor):TArray<ansistring>;virtual;
    //compile/run
    procedure DoCompile;virtual;
    function DoRun:boolean{again?};virtual;
  end;

var FrmIdeBase: TFrmIdeBase; //inherited form!!!

implementation

uses UFrmHelp, UFrmCodeInsight, het.FileSys;

{$R *.dfm}

////////////////////////////////////////////////////////////////////////////////
/// TEditorSheet                                                             ///
////////////////////////////////////////////////////////////////////////////////

function TEditorSheet.Changed:boolean;
begin
  result:=Editor.FileOps.ischanged;
end;

function TEditorSheet.IsNewAndUnchanged:boolean;
begin
  Result:=Editor.FileOps.IsNew and not Changed;
end;

procedure TEditorSheet.UpdateUI;
var s:string;
begin
  if not Editor.CanUndo then Editor.FileOps.isChanged:=false;//full undonal nincs chg

  s:=ExtractFileName(Editor.FileOps.FileName);
  if  Changed then s:='*'+s;
  Caption:=s;
end;

destructor TEditorSheet.Destroy;
begin
  if not Editor.FileOps.IsNew then
    TFrmIdeBase(Owner).AddReopenHistory(Editor.FileOps.FileName);

  inherited;
end;

////////////////////////////////////////////////////////////////////////////////
/// TFrmMain

procedure TFrmIdeBase.FormCreate(Sender: TObject);
begin
  OpenDialog1.Filter:=OnGetFileExt+' files|*.'+OnGetFileExt+';*.inc';
  SaveDialog1.Filter:=OpenDialog1.Filter;
  SaveDialog1.DefaultExt:=OnGetFileExt;

  mConsole:=TCodeEditor.Create(self);
  with mConsole do begin
    Parent:=tsOutput;
    Align:=alClient;
    ConsoleMode:=true;
  end;
end;

procedure TFrmIdeBase.FormShow(Sender: TObject);
var fn:string;
begin
  if CheckAndSet(running)then begin//STARTUP
    FrmHelp.LoadFromStr(TFile(apppath+'help.txt'));
    FrmHelp.ManualDock(pcRight);

    DesktopConfig:=TFile(ChangeFileExt(ParamStr(0),'.ini'));

    fn:=ParamStr(1);
    if(fn<>'')then OpenFile(fn);
  end;
end;

procedure TFrmIdeBase.mFileExitClick(Sender: TObject);
begin
  Close;
end;

procedure TFrmIdeBase.FormDestroy(Sender: TObject);
begin
  TFile(ChangeFileExt(ParamStr(0),'.ini')).Write(DesktopConfig);
end;

function TFrmIdeBase.EditorCount: integer;
begin
  result:=pcEditor.PageCount;
end;

function TFrmIdeBase.GetEditor(const n: variant): TEditorSheet;
var i:integer;
begin
  if VarIsOrdinal(n) then
    result:=TEditorSheet(pcEditor.Pages[n])
  else begin
    for i:=0 to EditorCount-1 do begin
      result:=Editor[i];
      if IsWild2(Result.Editor.FileOps.FileName,n) then exit;
    end;
    result:=nil;
  end;
end;

function TFrmIdeBase.GetActEditor:TEditorSheet;
begin
  result:=TEditorSheet(pcEditor.ActivePage);
end;

function TFrmIdeBase.ActCodeEditor: TCodeEditor;
begin
  result:=nil;
  if(ActiveControl<>nil)and(ActiveControl is TCodeEditor)then
    result:=TCodeEditor(ActiveControl);
  if(result=nil)and(GetActEditor<>nil)then
    result:=GetActEditor.Editor;
end;

procedure TFrmIdeBase.SetActEditor(const Value:TEditorSheet);
begin
  if(Value=nil)then exit;
  pcEditor.ActivePage:=Value;
  Value.Editor.SetFocus;
end;

function TFrmIdeBase.GetOpenedFiles:string;var i:integer;
begin
  result:='';for i:=0 to EditorCount-1 do result:=result+
    switch(result='','','|')+switch(pcEditor.ActivePage=Editor[i],'*','')+Editor[i].Editor.FileOps.FileName;
end;

procedure TFrmIdeBase.SetOpenedFiles(const Value:string);var i:integer;
var s,fn:AnsiString;
    isact:boolean;
    act:TEditorSheet;
begin
  for i:=EditorCount-1 downto 0 do Editor[i].Free;

  act:=nil;
  for s in ListSplit(Value,'|')do begin
    isact:=charn(s,1)='*';
    if isact then fn:=Copy(s,2)else fn:=s;
    OpenFile(fn);
    if isact then act:=ActEditor;
  end;

  ActEditor:=act;
end;

function TFrmIdeBase.GetReopenHistory:string;
var i:integer;
    Items:TMenuItem;
begin
  result:='';
  Items:=mFileReopen;
  for i:=0 to Items.Count-3 do result:=result+
    switch(i=0,'','|')+copy(Items[i].Caption,4);
end;

procedure TFrmIdeBase.SetReopenHistory(const Value:string);
const maxcnt=24;
var Items:TMenuItem;s:ansistring;i:integer;mi:TMenuItem;
begin
  Items:=mFileReopen;
  while Items.Count<maxCnt+2 do begin
    mi:=TMenuItem.Create(self);
    Items.Insert(0,mi);
    mi.OnClick:=mFileReopenItemClick;
    mi.Visible:=false;
  end;

  for i:=0 to maxCnt-1 do with Items[i]do begin
    s:=ListItem(Value,i,'|');
    Visible:=s<>'';
    Caption:='&'+ansichar(ord('A')+i)+' '+s;//delphis takolas, de ha naluk is jo....
  end;
end;

procedure TFrmIdeBase.mFileReopenItemClick(Sender:TObject);
begin
  OpenFile(copy(TMenuItem(Sender).Caption,4));
end;

procedure TFrmIdeBase.AddReopenHistory(const fn:string);
var h:ansistring;
    n:integer;
begin
  h:=GetReopenHistory;
  n:=ListFind(h,fn,'|');if n>0 then DelListItem(h,n,'|');
  ReopenHistory:=fn+'|'+h;
end;

function TFrmIdeBase.GetDesktopConfig:ansistring;
begin
  result:='{HetIDE Desktop Config}'#13#10+
    DumpProperties(self,'WindowPlacement,OpenedFiles,ReopenHistory,pcRight.width,pcRight.ActivePageIndex');
end;

procedure TFrmIdeBase.SetDesktopConfig(const Value: ansistring);
begin
  Eval(Value,self);
end;

procedure TFrmIdeBase.tUpdateUITimer(Sender: TObject);var i:integer;
var s:string;
begin
  for i:=0 to EditorCount-1 do Editor[i].UpdateUI;

  if OriginalCaption='' then OriginalCaption:=Caption;
  if ActEditor=nil then s:='' else s:=' ['+ExtractFileName(ActEditor.Editor.FileOps.FileName)+']';
  Caption:=OriginalCaption+s;

  UpdateMenuItems;
  UpdateStatusBar;
end;

procedure TFrmIdeBase.FormCloseQuery(Sender: TObject; var CanClose: Boolean);var i:integer;
begin
  for i:=0 to EditorCount-1 do Editor[i].Editor.FileOps.CloseQuery(CanClose);
end;

procedure TFrmIdeBase.UpdateMenuItems;

  function ClipboardCanPasted:boolean;
  begin
    try
      result:=Clipboard.HasFormat(CF_TEXT);
    except
      result:=false;
    end;
  end;

  function AnyEditorChanged:boolean;var i:integer;
  begin
    for i:=0 to EditorCount-1 do if Editor[i].Editor.FileOps.ischanged then exit(true);
    result:=false;
  end;

var e,ec:boolean;
begin
  e:=ActEditor<>nil;
  ec:=ActCodeEditor<>nil;
  with ActEditor do begin

    mFileSave.Enabled:=e and Editor.FileOps.ischanged;
    mFileSaveAs.Enabled:=e;
    mFileSaveAll.Enabled:=e and AnyEditorChanged;
    mFileReopenClear.Enabled:=mFileReopen.Count>2;

    mFileClose.Enabled:=e;
    mFileCloseAll.Enabled:=EditorCount>0;

    mEditUndo.Enabled:=ec and ActCodeEditor.CanUndo;
    mEditRedo.Enabled:=ec and ActCodeEditor.CanRedo;

    mEditCut.Enabled:=ec and ActCodeEditor.HasSelection;
    mEditCopy.Enabled:=ec and ActCodeEditor.HasSelection;
    mEditCopyHtml.Enabled:=ec and ActCodeEditor.HasSelection;
    mEditPaste.Enabled:=ec and ClipboardCanPasted;
    mEditDelete.Enabled:=ec and not ActCodeEditor.ConsoleMode and ActCodeEditor.HasSelection;
    mEditSelectAll.Enabled:=ec;

    mSearchFind.Enabled:=e;
    mSearchReplace.Enabled:=e;
    mSearchSearchAgain.Enabled:=e and(LastFindCommand.Operation<>opNone); //based on lastsearch
    mSearchGoToLineNumber.Enabled:=e;

    bFindNext.Enabled:=e and(cbFind.Text<>'');
    bReplace.Enabled:=bFindNext.Enabled;
    bReplaceAll.Enabled:=bFindNext.Enabled;

    mCompileCompile.Enabled:=e;
    mCompileRun.Enabled:=e;

    mHelpHelpAtCursor.Enabled:=e and
      ((ActiveControl is TCodeEditor)or(ActiveControl is TRichEdit));
  end;
end;

const
  sbInsOvr=0;
  sbLineCol=1;
  sbStatus=2;

procedure TFrmIdeBase.UpdateStatusbar;
begin
  if ActEditor=nil then begin
    StatusBar.Panels[sbLineCol].Text:='';
    StatusBar.Panels[sbInsOvr].Text:='';
  end else with ActEditor.Editor do begin
    with CursorPos do StatusBar.Panels[sbLineCol].Text:=format('%d:%d',[Y+1,X+1]);
    StatusBar.Panels[sbInsOvr].Text:=switch(Overwrite,'Ovr','Ins');
  end;
end;

function TFrmIdeBase.GetStatus: ansistring;
begin
  result:=StatusBar.Panels[sbStatus].Text;
end;

procedure TFrmIdeBase.SetStatus(const Value: ansistring);
begin
  StatusBar.Panels[sbStatus].Text:=Value;
end;

function TFrmIdeBase.NewEditor:TEditorSheet;
var ts:TEditorSheet;
    ed:TCodeEditor;
begin
  ts:=TEditorSheet.Create(Self);result:=ts;
  ts.PageControl:=pcEditor;
  ed:=TCodeEditor.Create(ts);
  ed.SyntaxEnabled:=true;
  ts.Editor:=ed;
  ed.Parent:=ts;
  ed.Align:=alClient;

  ed.OnSyntax:=OnSyntax;

  ts.Editor.FileOps.ExternalOpenDialog:=OpenDialog1;
  ts.Editor.FileOps.ExternalSaveDialog:=SaveDialog1;
end;

procedure TFrmIdeBase.NewFile;
  function NewName:string;
  var i,n:integer;
  begin
    n:=-1;
    for i:=0 to EditorCount-1 do if iswild2('noname??.'+OnGetFileExt,Editor[i].Editor.FileOps.FileName)then
      n:=max(n,strtointdef(copy(Editor[i].Editor.FileOps.FileName,7,2),-1));
    inc(n);
    result:=format('noname%.2d.'+OnGetFileExt,[n]);
  end;
begin
  ActEditor:=NewEditor;
  ActEditor.Editor.FileOps.New(NewName);
end;

procedure TFrmIdeBase.mFileNewClick(Sender: TObject);
begin
  NewFile;
end;

procedure TFrmIdeBase.OpenFile(const fn:AnsiString);//fn='' -> noname
var ed:TEditorSheet;
begin
  if not FileExists(fn) then exit;

  //already open?
  ed:=Editor[fn];

  //unchanged noname
  if ed=nil then begin
    if(ActEditor<>nil)and(ActEditor.IsNewAndUnchanged)then ed:=ActEditor else ed:=NewEditor;
    ed.Editor.FileOps.DoOpen(fn);
  end;

  ActEditor:=ed;
end;

procedure TFrmIdeBase.mFileOpenClick(Sender: TObject);
var fn:string;
begin
  OpenDialog1.Options:=OpenDialog1.Options+[ofAllowMultiSelect];
  if OpenDialog1.Execute then
    for fn in OpenDialog1.Files do
      OpenFile(fn);
end;

procedure TFrmIdeBase.mFileReopenClearClick(Sender: TObject);
begin
  ReopenHistory:='';
end;

procedure TFrmIdeBase.mFileSaveClick(Sender: TObject);
begin
  ActEditor.Editor.FileOps.Save;
end;

procedure TFrmIdeBase.mFileSaveAsClick(Sender: TObject);
begin
  ActEditor.Editor.FileOps.SaveAs;
end;

procedure TFrmIdeBase.mFileSaveAllClick(Sender: TObject);
var i:integer;
begin
  for i:=0 to EditorCount-1 do with Editor[i].Editor.FileOps do
    if ischanged and not Save then break;
end;

procedure TFrmIdeBase.mFileCloseClick(Sender: TObject);
begin
  ActEditor.Free;
end;

procedure TFrmIdeBase.mFileCloseAllClick(Sender: TObject);
var i:integer;
begin
  for i:=EditorCount-1 downto 0 do with Editor[i] do begin
    with Editor.FileOps do if ischanged and not Save then break;
    Free;
  end;
end;

procedure TFrmIdeBase.mEditUndoClick(Sender: TObject);
begin
  ActCodeEditor.Undo;
end;

procedure TFrmIdeBase.mEditRedoClick(Sender: TObject);
begin
  ActCodeEditor.Redo;
end;

procedure TFrmIdeBase.mEditCutClick(Sender: TObject);
begin
  ActCodeEditor.ExecuteCommand(ecCut);
end;

procedure TFrmIdeBase.mEditCopyClick(Sender: TObject);
begin
  ActCodeEditor.ExecuteCommand(ecCopy);
end;

procedure TFrmIdeBase.mEditCopyHtmlClick(Sender: TObject);
begin
  ActCodeEditor.ExecuteCommand(ecCopyHtml);
end;

procedure TFrmIdeBase.mEditPasteClick(Sender: TObject);
begin
  ActCodeEditor.ExecuteCommand(ecPaste);
end;

procedure TFrmIdeBase.mEditDeleteClick(Sender: TObject);
begin
  ActCodeEditor.ExecuteCommand(ecDelete);
end;

procedure TFrmIdeBase.mEditSelectAllClick(Sender: TObject);
begin
  ActCodeEditor.ExecuteCommand(ecSelectAll);
end;

type TFakeRichEdit=class(TRichEdit);
procedure TFrmIdeBase.mHelpHelpAtCursorClick(Sender: TObject);
var keyword:ansistring;
begin
  if ActiveControl is TCodeEditor then with TCodeEditor(ActiveControl)do begin
    KeyWord:=WordAt(Code,xy2pos(CursorPos,true)+1);
  end else if ActiveControl is TRichEdit then with TFakeRichEdit(ActiveControl) do begin
    KeyWord:=WordAt(ReplaceF(#13#10,#10,Text,[roAll]),GetSelStart+1);
  end;
  if KeyWord<>'' then begin
    pcRight.ActivePage:=pcRight.Pages[pcRight.PageCount-1];
    FrmHelp.ShowTopic(KeyWord);
  end;
end;

////////////////////////////////////////////////////////////////////////////////
/// Find/Replace                                                             ///
////////////////////////////////////////////////////////////////////////////////

function TFrmIdeBase.GetFindWindowState: integer;
begin
  if pFindReplace.Visible then
    if cbReplace.Visible then result:=2
                         else result:=1
  else result:=0;
end;

procedure TFrmIdeBase.SetFindWindowState(const Value: integer);
var v:integer;
    cb:TComboBoxEx;
    b:Boolean;
begin
  v:=EnsureRange(Value,0,2);
  if v=FindWindowState then exit;

  case v of
    1:cb:=cbFind;
    2:cb:=cbReplace;
  else cb:=nil end;

  if cb<>nil then with cb do pFindReplace.Height:=cb.Top+cb.Height+3;

  b:=v=2; //hide replace stuff
  cbReplace.Visible:=b;
  bReplace.Visible:=b;
  bReplaceAll.Visible:=b;
  chPromptOnReplace.Visible:=b;

  pFindReplace.Visible:=cb<>nil;
end;

procedure TFrmIdeBase.mSearchFindClick(Sender: TObject);
begin
  FindWindowState:=1;cbFind.SetFocus;
end;

procedure TFrmIdeBase.mSearchReplaceClick(Sender: TObject);
begin
  FindWindowState:=2;cbFind.SetFocus;
end;

procedure TFrmIdeBase.cbFindKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if(Key=VK_ESCAPE)and(Shift=[])then begin Key:=0;bFindClose.Click;exit end;
  if(Key=VK_RETURN)and(Shift=[])then begin
    if(Sender=cbFind)or(Sender=chCaseSensitive)or(Sender=chWholeWords)or(Sender=chBackwards)then begin
      Key:=0;bFindNext.Click;
    end else if(Sender=cbReplace)or(Sender=chPromptOnReplace)then begin
      Key:=0;bReplace.Click;
    end;
  end;
end;

procedure TFrmIdeBase.cFindCloseClick(Sender: TObject);
begin
  FindWindowState:=0;
  if ActEditor<>nil then begin
    ActEditor.Editor.ResetFoundText;
    ActEditor.Editor.SetFocus;
  end;
end;

procedure TFrmIdeBase.FindCommandPrepareFromUi(var fc: TFindCommand;const op: TFindOperation);
begin with fc do begin
  Operation:=op;
  FindText:=cbFind.Text;
  ReplaceWith:=cbReplace.Text;
  CaseSensitive:=chCaseSensitive.Checked;
  WholeWords:=chWholeWords.Checked;
  Backwards:=chBackwards.Checked;
  PromptOnReplace:=chPromptOnReplace.Checked;
end;end;

procedure TFrmIdeBase.FindCommandExecute(const fc: TFindCommand);
var e:TCodeEditor;

  function GoNext:boolean;//moves cursor if can

    function GoForwards:boolean;
    var i,cr:integer;
    begin
      cr:=e.xy2pos(e.CursorPos,false);
      for i:=0 to length(e.FFoundTextPositions)-1 do
        if cr<=e.FFoundTextPositions[i]-1 then begin
          e.CursorPos:=e.pos2xy(e.FFoundTextPositions[i]+e.FFoundTextLen-1);
          exit(true);
        end;
      result:=false;
    end;

    function GoBackwards:boolean;
    var i,cr:integer;
    begin
      cr:=e.xy2pos(e.CursorPos,false);
      for i:=length(e.FFoundTextPositions)-1 downto 0 do
        if cr>=e.FFoundTextPositions[i]+e.FFoundTextLen-1 then begin
          e.CursorPos:=e.pos2xy(e.FFoundTextPositions[i]-1);
          exit(true);
        end;
      result:=false;
    end;

  begin
    if fc.Backwards then result:=GoBackwards
                    else result:=GoForwards;
  end;


  function FindOccurences:boolean;//talalt-e valamit
  var st,en,i:integer;
      Options:TPosOptions;
      tmp:TArray<integer>;
      r:trect;
  begin
    Options:=[];
    if not fc.CaseSensitive then Options:=Options+[poIgnoreCase];
    if fc.WholeWords then Options:=Options+[poWholeWords];

    if e.HasSelection then begin
      st:=e.xy2pos(e.SelStart,true)+1;    //1 based
      en:=e.xy2pos(e.SelEnd,true);        //1 based, inclusive
    end else begin
      st:=1;
      en:=Length(e.Code);
    end;

    e.FFoundTextPositions:=PosMulti(fc.FindText,e.Code,Options,st,en);
    e.FFoundTextLen:=length(fc.FindText);
    e.FFoundTextBackwards:=fc.Backwards;
    e.Invalidate;

    //restrict selection if blockselect
    if e.HasSelection and e.BlockSelect then begin
      r:=e.BlockSelectionRect;r.Right:=r.Right-e.FFoundTextLen+2;
      for i:=0 to length(e.FFoundTextPositions)-1 do
        if PtInRect(r,e.pos2xy(e.FFoundTextPositions[i]-1))then begin
          SetLength(tmp,length(tmp)+1);
          tmp[length(tmp)-1]:=e.FFoundTextPositions[i];
        end;
      e.FFoundTextPositions:=tmp;
    end;

    result:=e.FFoundTextPositions<>nil;
    if not result then e.ResetFoundText;
  end;

  function DoWarpedFind(const AllowWarp:boolean=false):Boolean;
  begin
    result:=GoNext;
    if not result and(AllowWarp or(MessageBox('Restart search from the '+switch(fc.Backwards,'end','begining')+' of '+switch(e.HasSelection,'selection','file')+'?','Search match not found',MB_ICONQUESTION+MB_YESNO)=IDYES))then begin
      e.CursorPos:=e.pos2xy(switch(fc.Backwards,length(e.Code),0));
      result:=GoNext;
    end;
  end;

  function DoReplace(const AskQuestions:boolean=false):boolean;//kurzor pozicio alapjan
  var cr,diff,i,j:Integer;
      ignoreThis:boolean;
  begin
    cr:=e.xy2pos(e.CursorPos,false);
    diff:=length(fc.ReplaceWith)-e.FFoundTextLen;

    ignoreThis:=false;
    if AskQuestions then begin
      case MessageBox('Replace this occurrence of '''+fc.FindText+'''?','Confirm',MB_YESNOCANCEL+MB_ICONQUESTION)of
        ID_NO:ignoreThis:=true;
        IDCANCEL:exit(false);
      end;
    end;

    if not ignoreThis then begin
      if not fc.Backwards then cr:=cr-e.FFoundTextLen;//kurzor az elejere

      e.ModifyCode(cr,e.FFoundTextLen,fc.ReplaceWith);//replace text

//      TODO: XY messagebox pozicionalas, find/replace comboboxok historyja+config
      //adjust FFoundTextPositions buffer
      i:=0;while i<length(e.FFoundTextPositions)do case cmp(e.FFoundTextPositions[i],cr+1)of
        0:{del}begin for j:=i to length(e.FFoundTextPositions)-2 do e.FFoundTextPositions[j]:=e.FFoundTextPositions[j+1];setlength(e.FFoundTextPositions,length(e.FFoundTextPositions)-1) end;
        1:{diff}begin inc(e.FFoundTextPositions[i],diff);inc(i);end;
      else inc(i);end;

      if not fc.Backwards then cr:=cr+length(fc.ReplaceWith);//kurzor a vegere

      e.CursorPos:=e.pos2xy(cr);
    end;

    result:=true;
  end;

begin
  if fc.FindText='' then exit;
  if ActEditor=nil then exit;
  e:=ActEditor.Editor;if e=nil then exit;
  if fc.Operation=opNone then exit;

  if not FindOccurences then begin
    MessageBox('Search string '''+String(fc.FindText)+''' not found.','Information',MB_ICONINFORMATION+MB_OK);
    exit;
  end;

  case fc.Operation of
    opFind:DoWarpedFind;
    opReplace:begin
      if DoWarpedFind then
        DoReplace;
    end;
    opReplaceAll:begin
      while(e.FFoundTextPositions<>nil)and DoWarpedFind(not fc.PromptOnReplace)and DoReplace(fc.PromptOnReplace) do;
    end;
  end;
end;

procedure TFrmIdeBase.bFindNextClick(Sender: TObject);
begin
  if(ActEditor=nil)or(cbFind.Text='')then exit;
  FindCommandPrepareFromUi(LastFindCommand,opFind);
  FindCommandExecute(LastFindCommand);
end;

procedure TFrmIdeBase.bReplaceClick(Sender: TObject);
begin
  FindCommandPrepareFromUi(LastFindCommand,opReplace);
  FindCommandExecute(LastFindCommand);
end;

procedure TFrmIdeBase.bReplaceAllClick(Sender: TObject);
begin
  FindCommandPrepareFromUi(LastFindCommand,opReplaceAll);
  FindCommandExecute(LastFindCommand);
end;

procedure TFrmIdeBase.mSearchSearchAgainClick(Sender: TObject);
begin
  FindCommandExecute(LastFindCommand);
end;

////////////////////////////////////////////////////////////////////////////////
/// Syntax/CodeInsight                                                       ///
////////////////////////////////////////////////////////////////////////////////

procedure TFrmIdeBase.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var e:TCodeEditor;
begin
  if(Key=VK_SPACE)and(Shift=[ssCtrl])then
    if(ActiveControl<>nil)and(ActiveControl is TCodeEditor)then begin
      e:=ActiveControl as TCodeEditor;
      Key:=0;

      FrmCodeInsight.StartInsight(e,OnGetWordList(e));
    end;
end;

////////////////////////////////////////////////////////////////////////////////
/// Compile/Run                                                              ///
////////////////////////////////////////////////////////////////////////////////

procedure TFrmIdeBase.mCompileCompileClick(Sender: TObject);
var dt:TDeltaTime;
begin
  try
    Status:='Compiling...';
    dt.Start;
    DoCompile;
    dt.Update;
    Status:='Compiled OK ('+dt.SecStr+' sec)';
  except
    on e:exception do begin beep;Status:='Compile error: '+e.Message;end;
  end;
end;

procedure TFrmIdeBase.mCompileRunClick(Sender: TObject);
var dt:TDeltaTime;
begin
  Status:='Compiling...';
  try
    DoCompile;
  except
    on e:exception do begin
      beep;
      Status:=e.Message;
      exit;
    end;
  end;
  try
    Status:='Running...';
    dt.Start;
    while DoRun do;
    dt.Update;
    Status:='Terminated (time='+dt.SecStr+' sec)';
  except
    on e:exception do begin beep;Status:='Runtime Error: '+e.Message;end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
/// Virtual functions                                                       ///
////////////////////////////////////////////////////////////////////////////////

function TFrmIdeBase.OnGetFileExt: ansistring;
begin
  result:='unknown';
end;

function TFrmIdeBase.OnGetWordList(const Editor: TCodeEditor): TArray<ansistring>;
begin
  setlength(result,0);
end;

procedure TFrmIdeBase.OnSyntax;
begin
  SetLength(ASyntaxHighlight,length(ASrc));
  FillChar(ASyntaxHighlight[AFrom],ATo-AFrom,0);
end;

procedure TFrmIdeBase.DoCompile;
begin
end;

function TFrmIdeBase.DoRun;
begin
  result:=false;
end;

initialization
finalization
end.




