unit UFrmHetPasMain; //het.objects  unscal het.cal umacroparser het.cal

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, UFrmIdeBase, Menus, ImgList, ExtCtrls, StdCtrls, ComCtrls,
  het.Utils, het.Objects, het.CodeEditor, het.Parser, het.Variants, unsSystem,
  Clipbrd,
  {cal/cl} het.cal, unsCal, het.cl, unsCl, uCalTables,
  DebugInfo;

type
  TFrmMain = class(TFrmIdeBase)
    N5: TMenuItem;
    Evaluate1: TMenuItem;
    mPasteandRun: TMenuItem;
    procedure Evaluate1Click(Sender: TObject);
    procedure mPasteandRunClick(Sender: TObject);
    procedure tUpdateUITimer(Sender: TObject);
  private
    { Private declarations }
  public//override stuff
    Expr:IExpr;
    function OnGetFileExt:ansistring;override;
    //Syntax highight support
    procedure OnSyntax(const Sender:TCodeEditor;const ASrc:ansistring;var ASyntaxHighlight, ATokenHighlight:ansistring; bigComments:PAnsiChar; bigCommentsLen:integer; const AFrom:integer=1;const ATo:integer=$7fffffff);override;
    //Code insight
    function OnGetWordList(const Editor:TCodeEditor):TArray<ansistring>;override;
    //compile/run
    procedure DoCompile;override;
    function DoRun:boolean;override;
  public
    { Public declarations }
  end;

var
  FrmMain: TFrmMain;

implementation

uses UFrmEvaluate, het.MacroParser;

{$R *.dfm}

{ TFrmMain }

function TFrmMain.OnGetFileExt: ansistring;
begin
  result:='hpas';
end;

procedure TFrmMain.OnSyntax;
begin
  ParseHighlightPascalSyntax(ASrc,ASyntaxHighlight,AFrom,ATo);
end;

procedure TFrmMain.tUpdateUITimer(Sender: TObject);
begin
  inherited;
  mPasteAndRun.Enabled:=(ActCodeEditor<>nil)and(Clipboard.HasFormat(CF_TEXT));
end;

function TFrmMain.OnGetWordList(const Editor: TCodeEditor): TArray<ansistring>;
begin
  //itt fel kell deriteni a unitokat
  case ParseAsmModeAt(Editor.Code,Editor.xy2pos(Editor.CursorPos,true)+1)of
    asmISA:result:=ISAKeywordList;
    asmIL:result:=ILKeywordList;
  else result:=nsSystem.WordList;end;
end;

procedure TFrmMain.DoCompile;
var oldDir,newDir:string;
var src:ansistring;
begin
  Expr:=nil;
  try
    oldDir:=GetCurrentDir;
    newdir:=ExtractFileDir(ActEditor.Editor.FileOps.FileName);
    if newdir<>'' then SetCurrentDir(newdir);

    MacroSetCurrentFile(extractfilename(ActEditor.Editor.FileOps.FileName));
    src:=MacroPrecompile(ActEditor.Editor.Code,MaxInt); //#define macroes
    if TFile('c:\het').Exists then TFile('c:\after_precompile.hpas').Write(src);
    Expr:=CompileExpr(src,[nsSystem,nsCal,nsCl],ActEditor.Editor.FileOps.FileName);
    Expr._NameSpace.AddConstant('Application',VObject(Application));
  except
    on e:EScriptError do begin
      if not e.Position.empty then with ActEditor.Editor do CursorPos:=pos2xy(e.Position.ofs);
      raise
    end;
  end;
  SetCurrentDir(oldDir);
end;

function TFrmMain.DoRun:boolean;
var oldDir,newDir:string;
begin
  result:=false;
  if Assigned(Expr)then begin
    mConsole.Code:='';

    oldDir:=GetCurrentDir;
    newdir:=ExtractFileDir(ActEditor.Editor.FileOps.FileName);
    if newdir<>'' then SetCurrentDir(newdir);

    try
      Expr.Eval;
    finally
      SetCurrentDir(oldDir);
      if Assigned(Expr._Context)then begin
//        TFile('c:\a.txt').Write(Expr._Context.StdOut);
        mConsole.Code:=Expr._Context.StdOut;
      end;
    end;
  end;
  pcRight.ActivePage:=tsOutput;
end;

procedure TFrmMain.Evaluate1Click(Sender: TObject);
begin
  inherited;
  FrmEvaluate.ShowModal;
end;

procedure TFrmMain.mPasteandRunClick(Sender: TObject);
begin
  if ActEditor<>nil then begin
    ActEditor.Editor.Code:=Clipboard.AsText;
    mCompileRun.Click;
  end;
end;

end.




