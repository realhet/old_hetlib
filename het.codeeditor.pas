unit het.CodeEditor;//ucal het.parser het.cl het.glviewer

interface

uses Windows, SysUtils, Types, math, Classes, Graphics, Controls,
  Forms, Messages, ExtCtrls, ClipBrd, dialogs, ShellApi,
  het.Utils, het.Arrays, het.OpenSave, het.gfx;

var BookmarkSaveRequest:integer = -1; //ha ez 0..9, akkor a kulso IDE-nek kezelnie kell es elmenteni a bookmarkot az act editorbol.
var BookmarkRecallRequest:integer = -1; //ugyanez csak Q-ra.

{DEFINE DEBUGLINE}

type
  TErrorType = (etError, etWarning, etDeprecation, etVGC, etTodo, etOpt, etException);

const
  ErrorTitle:array[TErrorType]of ansistring= ('Error', 'Warning', 'Deprecation', 'VGC',    'Todo',    'Opt',       'Exception');
  clErrorBk  :array[TErrorType]of TColor=    (clRed   , clYellow, clAqua ,       clSilver, clWowBlue, clWowPurple, clRed  );
  clErrorFont:array[TErrorType]of TColor=    (clYellow, clBlack , clBlack,       clBlack , clWhite  , clWhite    , clWhite);

type
  TCodeEditor = class;

  TMarker = record
    editor: TCodeEditor;
    selStart, selEnd: integer;
    name:ansistring;
    isBreak:boolean;
    function selLen:integer;
    function text:ansistring;
    procedure remove;
    procedure update(APos, ADel, AIns: integer);
    function color:integer;
  private
    function enlarge: integer;
  end;
  PMarker = ^TMarker;

  TTokenHighlight=record
    _data:word;
    function nestingLevel:integer;
    function operatorLevel:integer;
    function isToken:boolean;
    function isTokenBegin:boolean;
    function isTokenEnd:boolean;
    function isTokenBegin_MinLevel(lvl:integer):boolean;
    function isTokenEnd_MinLevel(lvl:integer):boolean;
  end;

  TCodeEditor=class(TCustomControl)
  private
  type
    TOnSyntax=procedure(const Sender:TCodeEditor;const ASrc:ansistring;var ASyntaxHighlight, ATokenHighlight:ansistring; bigComments:PAnsiChar; bigCommentsLen:integer; const AFrom:integer=1;const ATo:integer=$7fffffff)of object;
    TOnFileDrop=procedure(files:TArray<string>)of object;

    TEditorCommand=(
      ecMoveRel,ecMoveWord,ecHome,ecEnd,ecTop,ecBottom,
      ecSelect,ecBlockSelect,//a kov kurzormozgas kijeloles lesz
      ecSelectWord,ecSelectAll, {}
      ecOverwrite,

      ecType,ecTab,
      ecBackSpace,ecDelete,
      ecCopy,ecCopyHtml,ecPaste,ecCut,ecDeleteSelection,
      ecUndo,ecRedo,

      ecIndentAdjust, //Ctrl+K UI
      ecDuplicateLine
    );

    TUndoEvent=record
      Pos,Del:integer;
      Ins:ansistring;
    end;
    TEditorEvent=record
      Command:TEditorCommand;
      X,Y:integer;
      S:ansistring;
    end;

  const
    TModifierCommands=[ecType,ecTab,ecBackSpace,ecDelete,ecPaste,ecCut,ecDeleteSelection,ecUndo];
  private
    FCode:ansistring;
    FSyntax, FTokenHighlight:ansistring;
    FSyntaxEnabled, FSyntaxValid:boolean;
    FCursorPos:TPoint;
    FMouseIsInside:boolean;

    FScrollTimer:TTimer;
    FAuxTimer:TTimer;
    FWasDoubleClick:boolean;//Kikuszoboli a dblClick utani MouseDown-t

    FOverwrite:boolean;
    FSelecting,FBlockSelect:boolean;
    FSelStart,FSelEnd:TPoint;//len=end-start

    FLastLineIdx,FLastLinePos:integer;
    FLineCount:integer;

    FCtrlKWasPressed:boolean;
    FCtrlQWasPressed:boolean;

    procedure CodeChanged;
    procedure SelectionChanged;

    procedure SetCode(const Value: ansistring);
    function GetCursorPos: TPoint;
    procedure SetCursorPos(const Value: TPoint);
    procedure SetScrollRanges(const Redraw:boolean);
    function GetScrollPos: TPoint;
    procedure SetScrollPos(const p: TPoint);
    procedure UpdateSyntax;
    function GetFullLine(idx: integer): ansistring;
    function GetLine(idx:integer):ansistring;
    procedure ScrollTimerProc(sender:TObject);
    procedure AuxTimerProc(sender:TObject);
    procedure SetOverwrite(const Value: boolean);
    function ClientToXY(const c: TPoint; const clamp: boolean): TPoint;
    function GetCharN(idx: integer): ansichar;inline;
    procedure SetCharN(idx: integer; const Value: ansichar);inline;
    procedure WMScroll(var M: TWMScroll; const Bar:integer);
  public
    procedure ModifyCode(APos, ADel: integer; const AIns: ansistring);
  private
    FUndoBuffer:TArray<TUndoEvent>;
    FUndoing:boolean;
    procedure AddUndoEvent(const APos,ADel:integer;const AIns:ansistring);
  public
    procedure Undo;
    function CanUndo:boolean;
  private
    FRedoBuffer:TArray<TUndoEvent>;
    FRedoing:boolean;
    procedure AddRedoEvent(const APos,ADel:integer;const AIns:ansistring);
  public
    procedure Redo;
    function CanRedo:boolean;

    procedure ClearUndoRedo;
  private
    procedure SetSelEnd(const Value: TPoint);
    procedure SetSelStart(const Value: TPoint);
  protected
    procedure WMHScroll(var Message: TWMHScroll); message WM_HSCROLL;
    procedure WMVScroll(var Message: TWMVScroll); message WM_VSCROLL;
    procedure WMEraseBkgnd(var Message: TMessage); message WM_ERASEBKGND;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure WMDropFiles(var Msg: TMessage); message WM_DROPFILES;
    procedure DoEnter;override;
    procedure DoExit;override;
    procedure KeyDown(var Key: Word; Shift: TShiftState);override;
    procedure KeyUp(var Key: Word; Shift: TShiftState);override;
    procedure KeyPress(var Key: Char); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer);override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean; override;
    procedure DblClick;override;
  public
    constructor Create(AOwner:TComponent);override;
    destructor Destroy;override;
    procedure CreateParams(var Params: TCreateParams);override;
    procedure Paint;override;

    property CursorPos:TPoint read GetCursorPos write SetCursorPos;
    property ScrollPos:TPoint read GetScrollPos write SetScrollPos;

    var HoverPos:TPoint;

    function LineCount:integer;
    function VisibleLineCount:integer;
    function VisibleColumnCount: integer;

    function pos2xy(const APos:integer):TPoint;
    function xy2pos(const AXy:TPoint;const ATrim:boolean):integer;

//    function pos2xy_old(const APos:integer):TPoint;

    procedure ExecuteCommand(const Cmd:TEditorCommand;const X:integer=0;const Y:integer=0;const S:ansistring='');

    property CharN[idx:integer]:ansichar read GetCharN write SetCharN;
    property Line[idx:integer]:ansistring read GetLine;
    function LineAtCursor: ansistring;

    function CharExtent:TPoint;
    function CharWidth:integer;
    function CharHeight:integer;

    function BlockSelectionRect:TRect;

    property Overwrite:boolean read FOverwrite write SetOverwrite;

    function HasSelection:boolean;
    property BlockSelect:boolean read FBlockSelect;
    property SelStart:TPoint read FSelStart write SetSelStart;
    property SelEnd:TPoint read FSelEnd write SetSelEnd;
    function SelText:ansistring;
    procedure ScrollIn(const APos: TPoint);
  published
    property Code:ansistring read FCode write SetCode;
    property SyntaxEnabled:boolean read FSyntaxEnabled write FSyntaxEnabled default true;
    property Font;
    property Align;
    property Visible;
    property Enabled;

    property OnKeyDown;
    property OnKeyUp;
    property OnKeyPress;

    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
  private
    FConsoleBuff:ansistring;
    procedure UpdateConsoleSyntax(const ASyntax:ansichar);
  public
    ConsoleMode:boolean;
    procedure ConsoleWrite(const s:ansistring;const ASyntax:ansichar=#0);
    procedure ConsoleWriteBin(const s:ansistring);
    procedure ConsoleWriteHex(const s:ansistring);
    function ConsoleRead:ansistring;//poll
  private
    FFileOps:TOpenSave;
    procedure FFileOpsOnNew(fn:string);
    procedure FFileOpsOnOpen(fn:string);
    procedure FFileOpsOnSave(fn:string);
  public //save/load
    function FileOps:TOpenSave;
  public //Find/replace
    FFoundTextPositions:TArray<integer>;
    FFoundTextLen:integer;
    FFoundTextBackwards:boolean;//a kurzorhoz legkozelebbinek a kijelolesehez
    procedure ResetFoundText;
  published
  private
    FOnSyntax:TOnSyntax;
    FOnChange, FOnSelectionChange:TNotifyEvent;
    FOnFileDrop:TOnFileDrop;
  published
    property OnSyntax:TOnSyntax read FOnSyntax write FOnSyntax;
    property OnChange:TNotifyEvent read FOnChange write FOnChange;
    property OnSelectionChange:TNotifyEvent read FOnSelectionChange write FOnSelectionChange;
    property OnFileDrop:TOnFileDrop read FOnFileDrop write FOnFileDrop;
  private
    function FormatHTML(const src,syn:ansistring):ansistring;
  private //LineCache
    type TNewLineCacheRec=record ofs,size,newLineCnt:integer; end;
    const NewLineCacheBlockSize=1 shl 18; //256K blocks
  private
    NewLineCache:TArray<TNewLineCacheRec>;
    procedure ResetNewLineCache;
    function SeekLine(const Ay: integer): integer;
    function FastCountNewLine(const idx, len: integer): integer;
    procedure CalcNewLineCacheIfNeeded;
//    function SeekLine_old(const y: integer): integer;

  private
    ErrorLine:integer; //Highlight the line with the error. -1 = no error. Disappear after any actions.
    ErrorLineType:TErrorType;
  public
    procedure SetErrorLine(line:integer; column:integer; et:TErrorType; overLines:integer);
    procedure ClearErrorLine;
  var
    CtrlLMBClicked:boolean; //Control+LeftMouse click detection. (for code navigation);
  public
    function PreviewBitmap:TBitmap;
  public //markers
    markers:TArray<TMarker>;
    procedure removeMarker(const idx:integer);overload;
    procedure removeMarker(const marker:PMarker);overload;
    function removeMarkers(const filter:ansistring):boolean;overload;
    procedure addMarker(selStart_, selEnd_:integer; name_:ansistring; isBreak_:boolean);
  private
    procedure updateMarkers(APos, ADel, AIns: integer);
  private
    running:boolean;

  protected //debug mode
    FDebugMode:boolean;
    function hideSelection:boolean;
    procedure setDebugMode(b:boolean);
    function seekNextToken(var n: integer): boolean;
    function seekPrevToken(var n: integer): boolean;
    procedure UpdateHoverMarker(enabled, pressed: boolean);
    function logCodeInsert(src: ansistring): ansistring;
    function logCodeExtract(src: ansistring; addMarkers:boolean): ansistring;
    function findMarkers(filter: ansistring): TArray<TMarker>;overload;
    function findMarkers(pos:integer): TArray<TMarker>;overload;
    function findMarker(pos:integer):PMarker;overload;
    function findMarker(name_:ansistring):PMarker;overload;
    function findMarker(ss, se: integer): PMarker; overload;
    procedure sortMarkersBySelStart(var m: TArray<TMarker>);
    procedure sortMarkersBySelLen(var m: TArray<TMarker>);
    function countMarkers(ss, se: integer): integer;
    procedure removeMarkers(ss, se: integer);overload;
    function getHoverMarkerRange(pressed: boolean; out ss,
      se: integer): boolean;
    procedure findAddMarker(visible: boolean; ss, se: integer; name: ansistring; isBreak:boolean);
    function logCodeRemoveall(src: ansistring): ansistring;
  public
    procedure removeAllDebugMarkers;
    property DebugMode:boolean read FDebugMode write setDebugMode;

    function getSyntaxAt(n:integer):TSyntaxKind; //slow&safe
    function getTokenHighlightAt(n:integer):TTokenHighLight; //slow&safe
    function getTokenAt(n:integer):ansistring; //slow&safe
    function extendTokenRange(var ss, se: integer): boolean;
    function extendTokenRangeStr(ss, se: integer): ansistring;

    procedure ShowLine(line, column, overlines: integer);

  private
  type TBigComment=record
      line, level:integer;
      comment:ansistring;

      hovered:boolean;
      cRect:TRect;

      lineP0, lineP1: TPoint;
    end;
  var
    bigComments:TArray<TBigComment>;
    procedure BigComments_draw(canvas:TCanvas; r: TRect; yoffs, yscale: single; mousePos: TPoint; scrollY, scrollYRange:integer);
    function BigComments_focusedLine:integer;
    procedure BigComments_showLine(line:integer);
  end;

implementation

function TTokenHighlight.nestingLevel;        begin result:=_data and $ff; end;
function TTokenHighlight.operatorLevel;       begin result:=_data shr 8 and $1f; end;
function TTokenHighlight.isToken;             begin result:=(_data and $2000)<>0; end;
function TTokenHighlight.isTokenBegin;        begin result:=(_data and $4000)<>0; end;
function TTokenHighlight.isTokenEnd;          begin result:=(_data and $8000)<>0; end;
function TTokenHighlight.isTokenBegin_MinLevel;  begin result:=isTokenBegin and(nestingLevel<=lvl); end;
function TTokenHighlight.isTokenEnd_MinLevel;    begin result:=isTokenEnd   and(nestingLevel<=lvl); end;

////////////////////////////////////////////////////////////////////////////////
///  CountChar                                                               ///
////////////////////////////////////////////////////////////////////////////////

function _FastCountChar(const s:PAnsiChar;const len:integer;const ch:ansichar):integer;

  function _CountCharOld(p:pointer;cnt:integer;ch:ansichar):integer;
  asm
    push edi push esi push ebx
    xor esi,esi //reult
    cmp cnt,0 jle @@exit
    movzx ecx,cl   imul ecx,ecx,$01010101
    movd xmm7,ecx  pshufd xmm7,xmm7,0 //mask
    pcmpeqb xmm6,xmm6 //$ffff
    movaps xmm0,xmm6 //accum //-1 initial value
  @@loop:
    mov edi,252
    cmp cnt,edi jbe @@small
    nop; nop; nop
    @@big:
      movaps xmm1,[eax]
      movaps xmm2,[eax+$10]
      prefetchT0 [eax+$200]
      movaps xmm3,[eax+$20]
      movaps xmm4,[eax+$30]
      pcmpeqb xmm1,xmm7
      pcmpeqb xmm2,xmm7
      paddb xmm1,xmm2
      pcmpeqb xmm3,xmm7
      pcmpeqb xmm4,xmm7
      paddb xmm0,xmm1
      paddb xmm3,xmm4
      add eax,$40
      paddb xmm0,xmm3
      sub edi,4
    ja @@big
    sub cnt,252
    jmp @@sum
    @@small:
      movaps xmm1,[p]
      pcmpeqb xmm1,xmm7  add p,$10
      paddb xmm0,xmm1
    dec cnt jnz @@small
    @@sum:
      //sum 16bytes
      movaps xmm1,xmm0
      punpcklbw xmm0,xmm6  punpckhbw xmm1,xmm6  paddw xmm0,xmm1 //8w
      pshufd xmm1,xmm0,2+3*4                    paddw xmm0,xmm1 //4w
      pshufd xmm1,xmm0,1                        paddw xmm0,xmm1 //2w
      movaps xmm1,xmm0  psrld xmm1,16           paddw xmm0,xmm1 //1w
      movd ebx,xmm0
      movsx ebx,bx;
      sub esi,ebx
      movaps xmm0,xmm6 //reset accum
      sub esi,16 //sub 16*-1
    or cnt,cnt ja @@loop
  @@exit:
    mov eax,esi
    pop ebx pop esi pop edi
  end;

  function _CountChar(p:pointer;cnt:integer;ch:ansichar):integer;

    procedure SumUp;//input:xmm0 destroys:xmm1,xmm2
    asm
      pcmpeqb xmm2,xmm2//-1
      movaps xmm1,xmm0
      punpcklbw xmm0,xmm2  punpckhbw xmm1,xmm2  paddw xmm0,xmm1 //8w
      pshufd xmm1,xmm0,2+3*4                    paddw xmm0,xmm1 //4w
      pshufd xmm1,xmm0,1                        paddw xmm0,xmm1 //2w
      movaps xmm1,xmm0  psrld xmm1,16           paddw xmm0,xmm1 //1w
      movd ebx,xmm0
      movsx ebx,bx;
      sub esi,ebx
      sub esi,16 //sub 16*-1 (initial -1)
    end;

  asm
    push edi push esi push ebx
    xor esi,esi //reult
    cmp cnt,0 jle @@exit
    movzx ecx,cl   imul ecx,ecx,$01010101
    movd xmm7,ecx  pshufd xmm7,xmm7,0 //mask
  @@loop:
    mov edi,252*4
    cmp cnt,edi jbe @@small
    pcmpeqb xmm0,xmm0;movaps xmm3,xmm0;movaps xmm4,xmm0;movaps xmm5,xmm0; //reset accums
    @@big://xmm0,xmm
    //0 1 2 3
      movaps xmm1,xmm7
        movaps xmm2,xmm7
          movaps xmm6,xmm7
      pcmpeqb xmm1,[eax]
        pcmpeqb xmm2,[eax+$10]
      paddb xmm0,xmm1
prefetchT0 [eax+$200]
          pcmpeqb xmm6,[eax+$20]
            movaps xmm1,xmm7
          paddb xmm4,xmm6
        paddb xmm3,xmm2
            pcmpeqb xmm1,[eax+$30]
add eax,$40
sub edi,4
            paddb xmm5,xmm1
    ja @@big
    sub cnt,252*4
    //Sum
    call sumup;
    movaps xmm0,xmm3;call sumup
    movaps xmm0,xmm4;call sumup
    movaps xmm0,xmm5;call sumup
    or cnt,cnt ja @@loop

    @@small:
    pcmpeqb xmm0,xmm0 //reset accum
    @@smallLoop:
      movaps xmm1,[eax]
      pcmpeqb xmm1,xmm7  add p,$10
      paddb xmm0,xmm1
    dec cnt jnz @@smallLoop
    call sumup;
    or cnt,cnt ja @@loop
  @@exit:
    mov eax,esi
    pop ebx pop esi pop edi
  end;

var st,en:pansichar;
    cnt:integer;
begin
  result:=0;
  if(s=nil)or(len<=0)then exit;

  st:=s;
  en:=psucc(st,len);

  while((cardinal(st)and $f)<>0)and(cardinal(st)<cardinal(en))do begin
    if st^=ch then inc(result);
    inc(st);
  end;

  cnt:=(cardinal(en)-cardinal(st))shr 4;
  inc(result,_CountChar(st,cnt,ch));
  pinc(st,cnt shl 4);

  while(cardinal(st)<cardinal(en))do begin
    if st^=ch then inc(result);
    inc(st);
  end;

//  TFile('c:\a.txt').Write(DataToStr(s^,len));
//  if result<>CountChar(s,len,ch)then raise Exception.Create('fuck '+tostr(result)+' '+tostr(CountChar(s,len,ch)));
end;


const
  ClipboardBlockSelectionMaxLen=1 shl 20;  //mert qrvalassu a crc32

type
  TClipboardBlockSelection=record
    len,hash:integer;
    procedure Update(const s:ansistring);
    function Check(const s:ansistring):boolean;
  end;
  //Beillesztesnel ha a Clipboard tartalma egyezik a fenti hash-al, akkor block insert van.

procedure TClipboardBlockSelection.Update(const s:ansistring);
begin
  len:=Length(s);
  if len<=ClipboardBlockSelectionMaxLen then
    hash:=Crc32(s);
end;

function TClipboardBlockSelection.Check(const s:ansistring):boolean;
begin
  if length(s)>ClipboardBlockSelectionMaxLen then exit(false);
  result:=(len=Length(s))and(hash=Crc32(s));
end;

var
  ClipboardBlockSelection:TClipboardBlockSelection;

{ TCodeEditor }

function CountLeadingSpaces(const s:ansistring):integer;
begin
  result:=0;
  while(result<length(s))and(s[result+1]=' ')do
    inc(result);
end;

constructor TCodeEditor.Create(AOwner: TComponent);
begin
  inherited;
//  Font.Name:='Courier New';
  Font.Name:='Consolas';
//  Font.Name:='Lucida Console'; //nem jo, mert a bold szelesebb
  ControlStyle:=[csReplicatable,csOpaque,csReflector,csClickEvents,csDoubleClicks,csCaptureMouse];
  TabStop:=True;
  Enabled:=True;
  Cursor:=crIBeam;
  Font.Size:=11;

  ErrorLine:=-1;

  FScrollTimer:=TTimer.Create(self);
  with FScrollTimer do begin
    Interval:=15;
    Enabled:=false;
    OnTimer:=ScrollTimerProc;
  end;

  FAuxTimer:=TTimer.Create(self);
  with FAuxTimer do begin
    Interval:=15;
    Enabled:=true;
    OnTimer:=AuxTimerProc;
  end;
end;

destructor TCodeEditor.Destroy;
begin
  inherited
end;

procedure TCodeEditor.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  ControlStyle:=ControlStyle+[csOpaque];
end;

procedure TCodeEditor.WMDropFiles(var Msg: TMessage);
var i:integer;
    fnc:array[0..256]of char;
    fn:TArray<string>;
begin
  i:=DragQueryFile(Msg.WParam,$FFFFFFFF,nil,0);

  fn:=nil;
  for i:=0 to i-1 do begin
    DragQueryFile(Msg.WParam,i,@fnc,256);
    setlength(fn, length(fn)+1);
    fn[high(fn)]:=fnc;
  end;

  if(fn<>nil)and assigned(FOnFileDrop)then FOnFileDrop(fn);
end;

function TCodeEditor.BlockSelectionRect: TRect;
begin
  with result do begin
    TopLeft:=FSelStart;
    BottomRight:=FSelEnd;
    sort(Left,Right);
    sort(Top,Bottom);
  end;
end;

function TCodeEditor.CharExtent: TPoint;
begin
  Canvas.Font.Assign(Font);
  with Canvas.TextExtent('W')do result:=Point(cx,cy);
end;

function TCodeEditor.CharHeight: integer;
begin
  result:=CharExtent.y;
end;

function TCodeEditor.CharWidth: integer;
begin
  result:=CharExtent.x;
end;

procedure TCodeEditor.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  message.Result:=DLGC_WANTCHARS or DLGC_WANTARROWS or DLGC_WANTTAB;
end;

function TCodeEditor.GetFullLine(idx: integer): ansistring;
var p0,p1:integer;
begin
  result:='';
  p0:=xy2pos(point(0,idx),false);
  if p0>=length(FCode)then exit;

  p1:=p0;
  while not(FCode[p1+1]in[#13,#10,#0])do inc(p1);
  result:=copy(FCode,p0+1,p1-p0);
end;

function TCodeEditor.GetLine(idx: integer): ansistring;
var i:integer;
begin
  result:=GetFullLine(idx);

  //trim ending spaces, report count
  if ConsoleMode then exit; //no trim on console

  i:=length(Result);
  while(i>0)and(result[i]=' ')do dec(i);
  setlength(Result,i);
end;

function TCodeEditor.LineAtCursor:ansistring;
begin
  result:=Line[FCursorPos.Y];
end;

procedure TCodeEditor.DoEnter;
begin
  inherited;
  ShowCaret(Handle);
  Invalidate;
end;

procedure TCodeEditor.DoExit;
begin
  inherited;
  DestroyCaret;
  FScrollTimer.Enabled:=false;
  Invalidate;
end;

procedure TCodeEditor.AddUndoEvent(const APos, ADel: integer;const AIns: ansistring);
begin
  if FUndoing or ConsoleMode then exit;

  setlength(FUndoBuffer,length(FUndoBuffer)+1);
  with FUndoBuffer[high(FUndoBuffer)]do begin
    Pos:=APos;Del:=ADel;Ins:=AIns;
  end;
end;

procedure TCodeEditor.AddRedoEvent(const APos, ADel: integer;const AIns: ansistring);
begin
  if FRedoing or ConsoleMode then exit;

  setlength(FRedoBuffer,length(FRedoBuffer)+1);
  with FRedoBuffer[high(FRedoBuffer)]do begin
    Pos:=APos;Del:=ADel;Ins:=AIns;
  end;
end;

procedure TCodeEditor.Undo;
begin
  if Length(FUndoBuffer)=0 then exit;

  FUndoing:=true;
  try
    with FUndoBuffer[high(FUndoBuffer)]do begin
      ModifyCode(Pos,Del,Ins);
      SetCursorPos(pos2xy(Pos));
    end;
    setlength(FUndoBuffer,high(FUndoBuffer));
  finally
    FUndoing:=false;
  end;
end;

function TCodeEditor.CanUndo:boolean;
begin
  result:=Length(FUndoBuffer)>0;
  result:=result and not ConsoleMode;
end;

procedure TCodeEditor.Redo;
begin
  if Length(FRedoBuffer)=0 then exit;

  FRedoing:=true;
  try
    with FRedoBuffer[high(FRedoBuffer)]do begin
      ModifyCode(Pos,Del,Ins);
      SetCursorPos(pos2xy(Pos));
    end;
    setlength(FRedoBuffer,high(FRedoBuffer));
  finally
    FRedoing:=false;
  end;
end;

procedure TCodeEditor.ResetFoundText;
begin
  if length(FFoundTextPositions)>0 then begin
    setlength(FFoundTextPositions,0);
    FFoundTextLen:=0;
    Invalidate;
  end;
end;

procedure TCodeEditor.ResetNewLineCache;
begin
  NewLineCache:=nil;
end;

function TCodeEditor.CanRedo:boolean;
begin
  result:=Length(FRedoBuffer)>0;
  result:=result and not ConsoleMode;
end;

procedure TCodeEditor.ClearUndoRedo;
begin
  SetLength(FUndoBuffer,0);
  SetLength(FRedoBuffer,0);
end;

procedure TCodeEditor.ModifyCode(APos,ADel:integer;const AIns:ansistring);

  procedure AddEvent(const APos,ADel:integer;const AIns:ansistring);
  begin
    if FUndoing then AddRedoEvent(APos,ADel,AIns)
                else AddUndoEvent(APos,ADel,AIns);

    FileOps.chg; //isChanged:=Length(FUndoBuffer)>0; conflict with Log/Brk markers.
  end;

begin
  APos:=EnsureRange(APos,0,Length(FCode));
  ADel:=EnsureRange(ADel,0,Length(FCode)-APos);

  if(ADel<=0)and(AIns='')then exit;//nothing
  if length(AIns)=ADel then begin//overwrite
    AddEvent(APos,ADel,Copy(FCode,APos+1,ADel));
    setlength(FCode,max(length(FCode),APos+1+length(AIns)));
    move(pointer(AIns)^,FCode[APos+1],length(AIns));
  end else begin
    if ADel>0 then begin//delete
      AddEvent(APos,0,Copy(FCode,APos+1,ADel));
      Delete(FCode,APos+1,ADel);
    end;
    if AIns<>'' then begin//insert
      AddEvent(APos,length(AIns),'');
      Insert(AIns,FCode,APos+1);
    end;
  end;

  UpdateMarkers(APos, ADel, length(AIns));
  ResetNewLineCache;
  CodeChanged;
end;

procedure TCodeEditor.ExecuteCommand(const Cmd: TEditorCommand; const X,Y: integer; const S: ansistring);

  const WordSet=['a'..'z','A'..'Z','_','0'..'9',#128..#255];

  procedure _MoveWord(amount:integer);

  var cp:TPoint;
      s:ansistring;

    function CharN(x:integer):ansichar;
    begin if(x<0)or(x>=length(s))then result:=' ' else result:=s[x+1];end;

    procedure _WordLeft;
    begin
      s:=Line[cp.Y];
      with cp do repeat
        dec(X);
        if X<0 then begin
          if Y>0 then begin
            dec(y);X:=Length(Line[Y]);
          end else begin
            X:=0;Y:=0;
          end;
          break;
        end;
      until (CharN(X)in WordSet)and not(CharN(X-1)in WordSet);
    end;

    procedure _WordRight;
    begin with cp do begin
      s:=Line[Y];
      if x>=length(s)then begin//next line
        if Y>=LineCount then exit;
        cp:=point(0,Y+1);
        s:=Line[Y];
      end else
        inc(x);
      while(x<Length(s))and not((CharN(X)in WordSet)and not(CharN(X-1)in WordSet))do
        inc(x);
    end;end;

  var i:integer;
  begin
    cp:=CursorPos;
    for i:=1 to amount do _WordRight;
    for i:=-1 downto amount do _WordLeft;
    CursorPos:=cp;
  end;

  procedure AdjustSpecialChars(var s:ansistring);
  var src:ansistring;
      ch,st:PAnsiChar;
  begin
    //{Adjust EOL}  replace(#13,'',s,[roAll]);   replace(#10,#13#10,s,[roAll]);  {Adjust Tab}  replace(#9,'  ',s,[roAll]);
    if s='' then exit;

    src:=s;
    ch:=pointer(src);
    with AnsiStringBuilder(s,true)do while true do begin
      //get normal charachert in batch
      st:=ch;
      while not(ch[0]in[#0,#9,#10,#13])do inc(ch);
      AddStr(StrMake(st,ch));

      //deal with special chars
      case ch[0]of
        #0:exit;
        #10:if ch[1]=#13 then begin AddStr(#13#10);inc(ch,2);end
                         else begin AddStr(#13#10);inc(ch  );end;
        #13:if ch[1]=#10 then begin AddStr(#13#10);inc(ch,2);end
                         else begin AddStr(#13#10);inc(ch  );end;
        #9:begin AddStr('  ');inc(ch);end;
      end;
    end;
  end;

  procedure DeleteText(st,en:TPoint);forward;

  function NextCharPos(const p:TPoint):TPoint;
  begin
    if p.x>=length(Line[p.Y])then result:=point(0,p.Y+1)
                             else result:=point(p.X+1,p.Y);
  end;

  function PrevCharPos(const p:TPoint):TPoint;
  begin
    if p.X>0 then result:=point(p.X-1,p.Y)
    else if p.Y>0 then result:=point(length(Line[p.Y-1]),p.Y-1)
    else result:=point(0,0);
  end;

  procedure InsertText(s:ansistring;const DoSelect:boolean=false);{nem paste!}

    procedure PadActLineToCursor;
    var fl:ansistring;
        n:integer;
    begin
      fl:=GetFullLine(CursorPos.Y);
      n:=CursorPos.X-length(Fl);
      if n>=0 then begin
        ModifyCode(xy2pos(CursorPos,true),0,Indent(' ',n));
      end;
    end;

    function CalcNewSpacesAtNewLine:integer;
    var s:ansistring;
        y,i:integer;
    begin
      result:=0;
      for y:=CursorPos.Y downto 0 do begin
        s:=Line[y];
        if s='' then Continue
                else begin result:=CountLeadingSpaces(s);break;end;
      end;

      i:=CountLeadingSpaces(LineAtCursor);
      if CursorPos.X<i then
        dec(result,i-CursorPos.X);
    end;

  var cp,ss,se:integer;
      isNewLine:boolean;
      ActLine:ansistring;
  begin
    AdjustSpecialChars(s);
    isNewLine:=s=#13#10;
    ActLine:=LineAtCursor;

    if Overwrite and(Length(ActLine)>CursorPos.X)and not isNewLine then begin//overwrite
      cp:=xy2pos(FCursorPos,true);
      if DoSelect then FSelStart:=CursorPos;

      ModifyCode(cp,length(s),s);

      inc(cp,length(s));
      CursorPos:=pos2xy(cp);
      if DoSelect then FSelEnd:=CursorPos;

    end else begin//insert mode
      if not ConsoleMode and(Length(ActLine)<CursorPos.X)and not isNewLine then
        PadActLineToCursor;//sor vegen ures helyre beszurasnal kiegesziti megfelelo szamu spaceval

      if not ConsoleMode and isNewLine then
        s:=s+Indent(' ',CalcNewSpacesAtNewLine);

      cp:=xy2pos(FCursorPos,false);{!!! itt mar gondoskodva lett rola, hogy nem kell trimmelni}
      if DoSelect then begin
        FSelStart:=CursorPos;
        ss:=0;se:=0;//nowarn
      end else begin
        ss:=xy2pos(FSelStart ,true);
        se:=xy2pos(FSelEnd   ,true);
      end;

      ModifyCode(cp,0,s);

      if not DoSelect and not FBlockSelect then begin
        if ss>=cp then begin inc(ss,length(s));  FSelStart :=pos2xy(ss);end;
        if se> cp then begin inc(se,length(s));  FSelEnd   :=pos2xy(se);end;
        if (FSelStart.Y=FSelEnd.Y)and(FSelStart.X>FSelEnd.X)then FSelEnd.X:=FSelStart.X;
      end;
      inc(cp,length(s));                        CursorPos:=pos2xy(cp);
      if DoSelect and not FBlockSelect then FSelEnd:=CursorPos;

    end;
  end;

  procedure DeleteText(st,en:TPoint);
  var len,cp,ss,se,stp,enp:integer;
  begin
    InsertText('');//spaces after EOL

    cp:=xy2pos(FCursorPos,false);
    ss:=xy2pos(FSelStart ,false);
    se:=xy2pos(FSelEnd   ,false);

    stp:=xy2pos(st,false);
    enp:=xy2pos(en,false);

    len:=enp-stp;
    ModifyCode(stp,len,'');

    if not FBlockSelect then begin
      if ss>stp then begin ss:=max(stp,ss-len);FSelStart :=pos2xy(ss);end;
      if se>stp then begin se:=max(stp,se-len);FSelEnd   :=pos2xy(se);end;
    end;
    if cp>stp then begin cp:=max(stp,cp-len); CursorPos:=pos2xy(cp);end;
  end;

  function CopyToClipBrd(AHtml:boolean=false):boolean;
  var ss,se:integer;
      r:TRect;
      y:integer;
      s,s2:ansistring;
      len:integer;
      txt,syn:ansistring;
  begin
    result:=false;
    if FBlockSelect then begin
      r:=BlockSelectionRect;
      len:=r.Right-r.Left+1;
      with AnsiStringBuilder(s2,true)do begin
        for y:=r.Top to r.Bottom do begin
          s:=copy(Line[y],r.Left+1,len);
          s:=s+Indent(' ',len-length(s));
          if y<>r.Bottom then s:=s+#13#10;
          AddStr(s);
        end;
        Finalize;
      end;
      Clipboard.AsText:=s2;
      ClipboardBlockSelection.Update(s2);
      result:=true;
    end else begin
      ss:=xy2pos(FSelStart,true);
      se:=xy2pos(FSelEnd,true);
      if ss<se then begin
        txt:=copy(FCode,ss+1,se-ss);
        if AHtml then begin
          UpdateSyntax;
          syn:=copy(FSyntax,ss+1,se-ss);
          Clipboard.AsText:=FormatHTML(txt,syn);
        end else
          Clipboard.AsText:=txt;

        ClipboardBlockSelection.Update('');
        result:=true;
      end;
    end;
  end;

  procedure _BackSpace;
  var p:TPoint;
      i,sc:integer;
  begin
    if(CursorPos.X>1)and(trimf(copy(Line[CursorPos.Y],1,CursorPos.X))='')then begin
      //specialis delete, a felette levo oszlopok alapjan hatarozza meg hogy mennyit torol
      p:=CursorPos;
      for i:=p.Y-1 downto -1 do begin
        if i<0 then begin
          p.X:=0;break end;
        sc:=CountLeadingSpaces(Line[i]);
        if sc<p.x then begin
          p.x:=sc;break;end;
      end;
      DeleteText(p,CursorPos);
    end else
      DeleteText(PrevCharPos(CursorPos),CursorPos);
  end;

  procedure _SelectWord;
  var s:ansistring;
      i:integer;
  begin
    s:=Line[CursorPos.Y];

    FSelStart:=point(-1,CursorPos.Y);
    for i:=CursorPos.X downto 0 do if het.Utils.CharN(s,i+1)in WordSet then begin
      FSelStart.X:=i;break end;
    if FSelStart.X<0 then
      for i:=0 to length(s)-1 do if het.Utils.CharN(s,i+1)in WordSet then begin
        FSelStart.X:=i;break end;

    with FSelStart do while(x>0)and(het.Utils.CharN(s,x)in WordSet)do
      dec(x);
    FSelEnd:=FSelStart;
    with FSelEnd do while(x<Length(s))and(het.Utils.CharN(s,x+1)in WordSet)do
      inc(x);

    CursorPos:=FSelEnd;
    Invalidate;
  end;

  procedure Paste;
  var s:ansistring;oldOW:boolean;
      cp:TPoint;
      sl:TAnsiStringArray;
      i:integer;
      len:integer;
  begin
    s:=Clipboard.AsText;
    if s='' then exit;
    if ClipboardBlockSelection.Check(s)then begin //block selection
      cp:=CursorPos;
      sl:=ListSplit(s,#10,false);
      len:=0;
      for i:=0 to high(sl)do begin
        s:=sl[i];if het.Utils.charn(s,length(s))=#13 then delete(s,length(s),1);
        len:=length(s);
        CursorPos:=point(cp.X,cp.Y+i);
        if CursorPos.Y=LineCount-1 then s:=s+#13#10;
        InsertText(s,false);
      end;
      FSelStart:=cp;
      FSelEnd:=point(cp.X+len-1,cp.Y+high(sl));
      FBlockSelect:=true;
    end else begin
      oldOW:=Overwrite;Overwrite:=false;
      InsertText(s,true);
      Overwrite:=oldOW;
    end;
  end;

  procedure DeleteSelection;
  var r:TRect;s:ansistring;y:integer;
  begin
    if FBlockSelect then begin
      r:=BlockSelectionRect;
      s:=Indent(' ',r.Right-r.Left+1);
      for y:=r.Top to r.Bottom do begin
        if Overwrite and(r.Right<length(Line[y]))then begin
          CursorPos:=point(r.Left,y);
          InsertText(s);
        end else
          DeleteText(point(r.Left,y),point(r.Right+1,y));
      end;
      CursorPos:=r.TopLeft;
    end else begin
      DeleteText(FSelStart,FSelEnd);
    end;
    FSelStart:=FCursorPos;
    FSelEnd:=FCursorPos;
    FBlockSelect:=false;
  end;

  procedure IndentAdjust;//x:amount  (ctrl+K,I)
  var y,y0,y1:integer;
      s:ansistring;
  begin
    if x=0 then exit;

    if HasSelection then begin
      y0:=FSelStart.Y;
      y1:=FSelEnd.Y;if FSelEnd.X=0 then dec(y1);
    end else begin
      y0:=FCursorPos.Y;
      y1:=y0;
    end;

    if x<0 then begin
      //check if unable to shift left
      for y:=y0 to y1 do begin
        s:=Line[y];
        if(s<>'')and(CountLeadingSpaces(s)<-x)then exit;
      end;
      for y:=y0 to y1 do if Line[y]<>'' then
        ModifyCode(xy2pos(point(0,y),true),2,'');
    end else if x>0 then begin
      s:=Indent(' ',x);
      for y:=y0 to y1 do if Line[y]<>'' then
        ModifyCode(xy2pos(point(0,y),true),0,s);
    end;
    Invalidate;
  end;

  procedure DuplicateLine;
  var s:ansistring;
      cp:TPoint;
  begin
    cp:=CursorPos;
    s:=line[cp.y];
    if CursorPos.y+1>=LineCount then begin //append it beyond file end
      ModifyCode(length(FCode), 0, #13#10+s);
    end else begin
      ModifyCode(xy2pos(point(0, cp.y+1), false), 0, s+#13#10);
    end;
    CursorPos:=point(cp.x, cp.y+1);
    Invalidate;
  end;

var cp:TPoint;
    lastSS,lastSE:TPoint;
begin
  cp:=CursorPos;

  lastSS:=SelStart; lastSE:=SelEnd;

  ResetFoundText;
  ClearErrorLine;
  case Cmd of
    ecMoveRel:CursorPos:=point(cp.x+x,cp.Y+y);
    ecHome:CursorPos:=Point(0,cp.Y);
    ecEnd:CursorPos:=Point(Length(LineAtCursor),cp.y);
    ecTop:CursorPos:=Point(0,0);
    ecBottom:CursorPos:=Point(0,LineCount);
    ecMoveWord:_MoveWord(X);

    ecSelect:begin FSelecting:=true;FBlockSelect:=false;end;
    ecBlockSelect:begin FSelecting:=true;FBlockSelect:=true;end;

    ecSelectWord:_SelectWord;
    ecSelectAll:begin FSelStart:=point(0,0);FSelEnd:=pos2xy(Length(FCode));FCursorPos:=FSelEnd;Invalidate end;

    ecOverwrite:Overwrite:=X<>0;

    ecType:InsertText(s);
    ecTab:if Overwrite then CursorPos:=point((CursorPos.X+8)and not 7,CursorPos.Y)
                       else InsertText(Indent(' ',(CursorPos.X+8)and not 7-CursorPos.X));
    ecBackSpace:begin
      //while console mode: no backspace on the beginning of a line
      if not ConsoleMode or not(CharN[length(FCode)-1]in[#13,#10])then
        _BackSpace;
    end;
    ecDelete:DeleteText(CursorPos,NextCharPos(CursorPos));

    ecCopy:CopyToClipBrd;
    ecCopyHtml:CopyToClipBrd(true);
    ecPaste:Paste;
    ecCut:if CopyToClipBrd then DeleteSelection;
    ecDeleteSelection:DeleteSelection;

    ecUndo:Undo;
    ecRedo:Redo;

    ecIndentAdjust:IndentAdjust;
    ecDuplicateLine:DuplicateLine;
  end;

  if(pt(SelStart)<>lastSS)or(pt(SelEnd)<>lastSE)then
    SelectionChanged;
end;

function TCodeEditor.GetCharN(idx: integer): ansichar;
begin
  if(idx>=0)and(idx<length(FCode))then result:=FCode[idx+1]
                                  else result:=#0;
end;

function TCodeEditor.GetCursorPos: TPoint;
begin
  result:=FCursorPos;
end;

procedure TCodeEditor.ScrollIn(const APos: TPoint);
var sp:TPoint;
begin
  sp:=ScrollPos;
  sp.X:=EnsureRange(sp.X,APos.X-(VisibleColumnCount-1),APos.X);
  sp.Y:=EnsureRange(sp.Y,APos.Y-(VisibleLineCount  -2),APos.Y);
  SetScrollPos(sp);
end;

procedure TCodeEditor.SetCursorPos(const Value: TPoint);
var oldCp:TPoint;isSel:boolean;
begin
  if not PointsEqual(Value,FCursorPos)then begin
    oldCp:=FCursorPos;

    FCursorPos.X:=EnsureRange(Value.X,0,1023);
    FCursorPos.Y:=EnsureRange(Value.Y,0,max(LineCount-1,0));

    if FSelecting then begin
      isSel:=not PointsEqual(FSelStart,FSelEnd);
      if isSel and PointsEqual(oldCp,FSelStart)then FSelStart:=FCursorPos else
      if isSel and PointsEqual(oldCp,FSelEnd)then FSelEnd:=FCursorPos
        else begin FSelStart:=oldCp;FSelEnd:=FCursorPos;end;
      if(FSelStart.Y>FSelEnd.Y)or(FSelStart.Y=FSelEnd.Y)and(FSelStart.X>FSelEnd.X)then
        Swap(FSelStart,FSelEnd);
    end;

    //scroll in view
    if not ConsoleMode or inrange(CursorPos.Y,ScrollPos.Y,ScrollPos.Y+VisibleLineCount)then begin
      ScrollIn(CursorPos);
    end;

    SelectionChanged;
    invalidate;
  end;

  FSelecting:=false;
end;

procedure TCodeEditor.setDebugMode(b: boolean);
begin
  if b=FDebugMode then exit;
  FDebugMode:=b;
  invalidate;
end;

procedure TCodeEditor.ShowLine(line, column, overlines:integer);
begin
  overLines:=min(overLines, VisibleLineCount div 2);
  if overlines>0 then begin
    CursorPos:=Point(column, line-overlines);
    CursorPos:=Point(column, line+overlines);
  end;
  CursorPos:=Point(column, line);
end;

procedure TCodeEditor.SetErrorLine(line:integer; column:integer; et:TErrorType; overLines:integer);
begin
  ShowLine(line, column, overlines);
  ErrorLine:=line;
  ErrorLineType:=et;
  Repaint; //because of caret
end;

procedure TCodeEditor.ClearErrorLine;
begin
  if ErrorLine>=0 then begin
    ErrorLine:=-1;
    invalidate;
  end;
end;

procedure TCodeEditor.SetOverwrite(const Value: boolean);
begin
  if FOverwrite=Value then exit;
  FOverwrite := Value;
  Invalidate;
end;

function TCodeEditor.LineCount: integer;
begin
  if FLineCount=0 then begin
    FLineCount:=pos2xy(Length(FCode)).Y+1;
  end;

  result:=FLineCount;
end;

procedure TCodeEditor.KeyDown(var Key: Word; Shift: TShiftState);
var hk:integer;

  function chk(const k:ansistring):boolean;
  begin result:=ToHotVKey(k)=hk;end;

  function chkMove(const k:ansistring):boolean;
  begin
    result:=chk(k);if result then exit;
    result:=chk('Shift+Alt+'+k);if result then begin ExecuteCommand(ecBlockSelect);exit end;
    result:=chk('Shift+'+k);if result then ExecuteCommand(ecSelect);
  end;

  function chkCtrl(const k:ansistring):boolean;
  begin
    result:=chk(k)or chk('ctrl+'+k);
  end;

var sp:TPoint;
    i:integer;
begin
  hk:=ToHotVkey(Key,Shift);
  sp:=ScrollPos;

  if checkAndClear(FCtrlKWasPressed) then begin

    if chkCtrl('U')then ExecuteCommand(ecIndentAdjust,-2)else
    if chkCtrl('I')then ExecuteCommand(ecIndentAdjust,+2)else begin
      for i:=0 to 9 do begin
        if chkCtrl(toStr(i))then BookmarkSaveRequest:=i;
      end;

    end;

    Key:=0;
    exit;
  end;

  if checkAndClear(FCtrlQWasPressed) then begin //igy Pistikesen

    for i:=0 to 9 do begin
      if chkCtrl(toStr(i))then BookmarkRecallRequest:=i;
    end;

    Key:=0;
    exit;
  end;

  inherited;

  if chkMove('Up')then ExecuteCommand(ecMoveRel,0,-1)else
  if chkMove('Down')then ExecuteCommand(ecMoveRel,0,1)else
  if chkMove('Ctrl+Up')then begin ScrollPos:=point(sp.X,sp.Y-1);ExecuteCommand(ecMoveRel,0,-1);end else
  if chkMove('Ctrl+Down')then begin ScrollPos:=point(sp.X,sp.Y+1);ExecuteCommand(ecMoveRel,0,1);end else
  if chkMove('Right')then ExecuteCommand(ecMoveRel,1,0)else
  if chkMove('Left')then ExecuteCommand(ecMoveRel,-1,0)else
  if chkMove('Ctrl+Right')then ExecuteCommand(ecMoveWord,1,0)else
  if chkMove('Ctrl+Left')then ExecuteCommand(ecMoveWord,-1,0)else
  if chkMove('Home')then ExecuteCommand(ecHome)else
  if chkMove('End')then ExecuteCommand(ecEnd)else
  if chkMove('Ctrl+Home')then ExecuteCommand(ecMoveRel,0,ScrollPos.Y-CursorPos.Y)else
  if chkMove('Ctrl+End')then ExecuteCommand(ecMoveRel,0,ScrollPos.Y+VisibleLineCount-2-CursorPos.Y)else
  if chkMove('Page Up')then begin ScrollPos:=point(sp.x,sp.y-(VisibleLineCount-1));ExecuteCommand(ecMoveRel,0,-(VisibleLineCount-1));end else
  if chkMove('Page Down')then begin ScrollPos:=point(sp.x,sp.y+(VisibleLineCount-1));ExecuteCommand(ecMoveRel,0,+(VisibleLineCount-1));end else
  if chkMove('Ctrl+Page up')then ExecuteCommand(ecTop)else
  if chkMove('Ctrl+Page down')then ExecuteCommand(ecBottom)else

  if chk('Ctrl+Numpad +')then begin Font.Size:=Font.Size+1;; invalidate; end;
  if chk('Ctrl+Numpad -')then if Font.Size>5 then begin Font.Size:=Font.Size-1;; invalidate; end;

  if consoleMode then begin
    if chk('Ctrl+Ins')or chk('Ctrl+C')then ExecuteCommand(ecCopy)else
    if chk('Shift+Ctrl+Ins')or chk('Shift+Ctrl+C')then ExecuteCommand(ecCopyHtml)else
    if chk('Shift+Ins')or chk('Ctrl+V')then FConsoleBuff:=FConsoleBuff+Clipboard.AsText;
  end else begin
    if chk('Ins')then ExecuteCommand(ecOverwrite,Ord(not Overwrite))else
    if chk('Enter')then ExecuteCommand(ecType,0,0,#13#10)else
    if chk('Del')then ExecuteCommand(ecDelete)else
    if chk('Backspace')then ExecuteCommand(ecBackSpace)else
    if chk('Tab')then ExecuteCommand(ecTab)else

    if chk('Ctrl+Z') or chk('Alt+Backspace')then ExecuteCommand(ecUndo)else
    if chk('Ctrl+Y') or chk('Shift+Alt+Backspace')then ExecuteCommand(ecRedo)else
    if chk('Ctrl+Ins')or chk('Ctrl+C')then ExecuteCommand(ecCopy)else
    if chk('Shift+Ctrl+Ins')or chk('Shift+Ctrl+C')then ExecuteCommand(ecCopyHtml)else
    if chk('Shift+Ins')or chk('Ctrl+V')then ExecuteCommand(ecPaste)else
    if chk('Shift+Del')or chk('Ctrl+X')then ExecuteCommand(ecCut)else
    if chk('Ctrl+Del')then ExecuteCommand(ecDeleteSelection);
    if chk('Ctrl+A')then ExecuteCommand(ecSelectAll)else
    if chk('Ctrl+D')then ExecuteCommand(ecDuplicateLine)else

    if chk('Ctrl+K')then FCtrlKWasPressed:=true;
    if chk('Ctrl+Q')then FCtrlQWasPressed:=true;
  end;

//  if key=VK_CONTROL then Invalidate; //navLink It's BAD <-> conflict with ctrl+space
end;

procedure TCodeEditor.KeyPress(var Key: Char);
begin
  inherited;
  if GetKeyState(VK_CONTROL)<0 then exit;
  if GetKeyState(VK_MENU)<0 then exit;

  if ConsoleMode then begin
    if Key=#13 then Key:=#10;  //unix style enter
    FConsoleBuff:=FConsoleBuff+AnsiChar(Key);
  end else begin
    if not(ansichar(Key) in[#0,#8,#9,#13,#27])then //ezek kezelve vannak fent
      ExecuteCommand(ecType,0,0,Key);
  end;
end;

procedure TCodeEditor.KeyUp(var Key: Word; Shift: TShiftState);
begin
  inherited;

  if key=VK_CONTROL then Invalidate; //navLink
end;

function TCodeEditor.ClientToXY(const c:TPoint;const clamp:boolean):TPoint;
var sp:TPoint;
begin
  result:=c;
  if not Overwrite then inc(result.x,CharWidth shr 1);
  result.x:=result.x div CharWidth;result.y:=result.Y div CharHeight;
  if clamp then begin
    result.x:=EnsureRange(result.x,0,VisibleColumnCount-1);
    result.y:=EnsureRange(result.y,0,VisibleLineCount-2);
  end;
  sp:=ScrollPos;
  result.X:=result.X+sp.X;
  result.Y:=result.Y+sp.Y;
end;

procedure TCodeEditor.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var bfl:integer;
begin
  inherited;
  if FWasDoubleClick then begin FWasDoubleClick:=false;exit end;

  SetFocus;

  if(Button=mbLeft)then begin

    //bigComments focus
    bfl:=BigComments_focusedLine;
    if bfl>=0 then begin
      BigComments_showLine(bfl);
      exit;
    end;

    ResetFoundText;
    CursorPos:=ClientToXY(point(x,y),true);
    FSelStart:=CursorPos;
    FSelStart:=FSelEnd;
    FBlockSelect:=GetKeyState(VK_MENU)<0;
    FScrollTimer.Enabled:=true;
    if Shift=[ssCtrl,ssLeft]then
      CtrlLMBClicked:=true;
  end;
end;

procedure TCodeEditor.MouseMove(Shift: TShiftState; X, Y: Integer);
var lhp:TPoint;
begin
  inherited;

  //update hoverpos, check if changes while pressing ctrl
  lhp:=HoverPos;
  HoverPos:=ClientToXY(point(x,y),true);
  if(ssCtrl in Shift)and not pointsEqual(lhp, HoverPos)then Invalidate;

  if Application.Active and Focused and (ssLeft in Shift) and (FScrollTimer.Enabled) then begin
    FSelecting:=true;
    FBlockSelect:=GetKeyState(VK_MENU)<0;
    CursorPos:=HoverPos;
  end;

  UpdateHoverMarker(Application.Active and Focused and DebugMode, GetKeyState(VK_LBUTTON)<0);
end;

procedure TCodeEditor.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var m, hm:PMarker;
begin
  inherited;
  FScrollTimer.Enabled:=false;

  if DebugMode then begin

    if button=mbLeft then begin

      hm:=findMarker('hover');
      if hm<>nil then begin
        m:=findMarker(hm.selStart, hm.selEnd);
        if m=hm then m:=nil;
        

        if m=nil then begin //create new marker
          hm.name:='log';
          hm.isBreak:=ssShift in Shift;
        end else begin
          m.isBreak:=not m.isBreak; //toggle log/break
        end;
        fileops.Chg;
        invalidate;
      end;
    end else if button=mbRight then begin
      hm:=findMarker('hover');
      if hm<>nil then begin
        m:=findMarker(hm.selStart, hm.selEnd);

        if m<>nil then begin
          m.remove;
        end;
        FileOps.Chg;
      end;
      hm.remove;
      invalidate;
    end;

  end;
end;

procedure  TCodeEditor.removeAllDebugMarkers;
begin
  if removeMarkers('log') then begin
    FileOps.Chg;
    invalidate;
  end;
end;

function TCodeEditor.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean;
begin
  ScrollPos:=TMyPoint(ScrollPos)+point(0,-WheelDelta div CharHeight);
  result:=true;
end;

procedure TCodeEditor.ScrollTimerProc;
begin
  if Application.Active and Focused then begin
    FSelecting:=true;
    FBlockSelect:=GetKeyState(VK_MENU)<0;
    CursorPos:=ClientToXY(ScreenToClient(Mouse.CursorPos),false);
  end;
end;

procedure TCodeEditor.AuxTimerProc;
var b:boolean;
begin
  if not running then begin //initialization after stupid form is created and has a fucking parent
    running:=true;
    DragAcceptFiles(Handle, true);
  end;

  b:=FMouseIsInside;
  FMouseIsInside:=PtInRect(ClientRect, ScreenToClient(Mouse.CursorPos));
  if(b<>FMouseIsInside)and(GetKeyState(VK_CONTROL)<0)then
    invalidate; //update navlink when entering/exiting client area
end;

procedure TCodeEditor.DblClick;
begin
  FWasDoubleClick:=true;
  inherited;
  ExecuteCommand(ecSelectWord);
end;

(*function TCodeEditor.SeekLine_old(const y:integer):integer{0based pos};
var i:integer;
begin
  result:=0;
  if FCode='' then exit;

  for i:=1 to y do begin
    while true do case FCode[result+1]of
      #0:begin inc(result);exit;end; //eof
      #10:begin inc(result);break end;
    else
      inc(result);
    end;
  end;
end;*)

procedure TCodeEditor.CalcNewLineCacheIfNeeded;
var i,clen,en:integer;
begin
  if NewLineCache<>nil then exit;

  clen:=length(FCode);
  if (clen=0)then exit;

  setlength(NewLineCache, (clen+NewLineCacheBlockSize-1) div NewLineCacheBlockSize);
  for i:=0 to high(NewLineCache)do with NewLineCache[i]do begin
    ofs:=i*NewLineCacheBlockSize;
    en:=min(ofs+NewLineCacheBlockSize, clen);
    size:=en-ofs;
    newLineCnt:=_FastCountChar(psucc(pointer(FCode),ofs), size, #10);
  end;
end;

function TCodeEditor.FastCountNewLine(const idx, len:integer):integer;
var clen:integer;
begin
  clen:=length(FCode);
  if (clen=0)or(len=0) then exit(0);

  //it's only a link to the asm function, optimization is outside
  result:=_FastCountChar(psucc(pointer(FCode),idx), len, #10);
end;

function TCodeEditor.SeekLine(const Ay:integer):integer{0based pos};
const blocksize=$1000;
var i,k,len,y:integer;
begin
  result:=0;
  if FCode='' then exit;
  y:=Ay;

  //skip cached large blocks if can
  CalcNewLineCacheIfNeeded;
  for k:=0 to high(NewLineCache)do with NewLineCache[k]do begin
    i:=newLineCnt;
    if i>=y-1 then break;
    inc(result, size);
    dec(y, i);
  end;

  //eat out big parts with sse at the start   Fucking good speedup!
  while true do begin
    len:=min(Length(FCode)-result,blocksize);
    if len<=0 then break;
    i:=FastCountNewLine(result,len);
    if i>=y-1 then break;
    result:=result+len;
    y:=y-i;
  end;

  for i:=1 to y do begin
    while true do case FCode[result+1]of
      #0:begin inc(result);exit;end; //eof
      #10:begin inc(result);break end;
    else
      inc(result);
    end;
  end;

//  {compare}if result<>SeekLine_old(s,ay)then raise Exception.Create('SeekLine fail: old:'+tostr(SeekLine_old(s,ay))+' new:'+tostr(result));
end;

function TCodeEditor.xy2pos(const AXy: TPoint;const ATrim:boolean): integer;
var i,j:integer;
begin
  result:=0;if AXy.y<0 then exit;
  if FCode='' then exit;
  //skip lines
  result:=SeekLine(AXy.y);
  if Result>=Length(FCode)then exit;

  //adjust column
  for i:=1 to AXy.X do begin
    case FCode[result+1]of
      #0:begin inc(result);exit end;
      #10,#13:break;
    else inc(result);end;
  end;
  //step back on ending spaces
  if ATrim then begin
    j:=result;while(FCode[j+1]=' ') do inc(j);
    if FCode[j+1]in[#0,#10,#13]then begin
      while(result>0)and(FCode[result]=' ')do
        dec(result);
    end;
  end;
end;

(*function TCodeEditor.pos2xy_Old(const APos: integer): TPoint;   //original, works but slow
var i:integer;
begin with result do begin
  x:=0;y:=0;
  for i:=1 to min(APos,Length(FCode))do
    case FCode[i] of
      #13:;
      #10:begin
        x:=0;
        inc(y);
      end;
    else inc(x)end;
end;end;*)

function TCodeEditor.pos2xy(const APos: integer): TPoint;
var i,j,base:integer;
begin
  j:=min(APos,Length(FCode)); //actual range

  result.Y:=0;

  //skip large blocks
  CalcNewLineCacheIfNeeded;
  base:=0;
  for i:=0 to high(NewLineCache)do with NewLineCache[i]do begin
    if ofs+size>j then break;

    inc(result.Y, newLineCnt);
    base:=ofs+size;
  end;

  //search the rest manually
  if j-base>0 then
    inc(result.y, FastCountNewLine(base, j-base));

  //calculate X
  result.X:=0;
  for i:=j downto 1 do case FCode[i]of
    #10:break;
    #13:;
  else
    inc(result.x);
  end;

//  {compare}if pt(result)<>pos2xy_old(APos)then raise Exception.Create('Fuck ols:'+tostr(pos2xy_old(APos))+' new:'+tostr(result));
end;


function TCodeEditor.VisibleLineCount: integer;
var th:Integer;
begin
  th:=CharHeight;
  result:=(ClientHeight+th-1) div th;
end;

function TCodeEditor.VisibleColumnCount: integer;
var tw:Integer;
begin
  tw:=CharWidth;
  result:=(ClientWidth+tw-1) div tw;
end;

procedure TCodeEditor.CodeChanged;
begin
  FLastLineIdx:=0;FLastLinePos:=0;FLineCount:=0;
  FSyntaxValid:=false;
  if Assigned(OnChange)then OnChange(self);
  Invalidate;
end;

procedure TCodeEditor.SelectionChanged;
begin
  if Assigned(OnSelectionChange)then
    OnSelectionChange(self);

  //note: invalidate is johetne ide, vagy a fax tudja...
end;

function TCodeEditor.SelText: ansistring;
var ss,se:integer;
begin
  ss:=xy2pos(SelStart,true);
  se:=xy2pos(SelEnd,true);
  result:=copy(FCode,ss+1,se-ss);
end;

function TCodeEditor.ConsoleRead: ansistring;
begin
  result:=FConsoleBuff;
  FConsoleBuff:='';
end;

procedure TCodeEditor.UpdateConsoleSyntax(const ASyntax:ansichar);
var olen,nlen:integer;
begin
  nlen:=length(FCode);

  olen:=length(FSyntax);
  setlength(FSyntax,nlen);
  for olen:=olen+1 to nlen do
    FSyntax[olen]:=ASyntax;
end;

procedure TCodeEditor.ConsoleWrite(const s:ansistring;const ASyntax:ansichar=#0);
var i:integer;
    cp,ss,se:TPoint;
begin
  //save cursor
  cp:=CursorPos;
  ss:=SelStart;
  se:=SelEnd;

  CursorPos:=Point(length(Line[LineCount-1]),LineCount);
  for i:=1 to length(s)do begin
    case s[i]of
      #13:if het.Utils.charn(s,i+1)=#10 then continue else ExecuteCommand(ecType,0,0,#13#10);
      #10:begin ExecuteCommand(ecType,0,0,#13#10);end;
      #8:ExecuteCommand(ecBackSpace);
    else ExecuteCommand(ecType,0,0,s[i]);
    end;
  end;

  CursorPos:=cp;
  SelStart:=ss;
  SelEnd:=se;

  UpdateConsoleSyntax(ASyntax);
end;

procedure TCodeEditor.ConsoleWriteBin(const s: ansistring);
var i:integer;
    po:integer;
    ch:ansichar;
begin
  if s='' then exit;

  CursorPos:=Point(length(Line[LineCount-1]),LineCount);
  po:=CursorPos.x;
  if po>=80 then begin ExecuteCommand(ecType,0,0,#13#10);po:=0;end;

  for i:=1 to length(s)do begin
    ch:=s[i];
    if ch<' ' then ch:='.';
    ExecuteCommand(ecType,0,0,ch);
    if(po+i)mod 80=0 then ExecuteCommand(ecType,0,0,#13#10);
  end;

end;

procedure TCodeEditor.ConsoleWriteHex(const s: ansistring);
var i:integer;
    po:integer;
begin
  if s='' then exit;

  CursorPos:=Point(length(Line[LineCount-1]),LineCount);
  po:=CursorPos.x;
  if po div 3>=16 then begin ExecuteCommand(ecType,0,0,#13#10);po:=0;end;

  for i:=1 to length(s)do begin
    ExecuteCommand(ecType,0,0,' '+IntToHex(ord(s[i]),2));
    if(po div 3+i)mod 16=0 then ExecuteCommand(ecType,0,0,#13#10);
  end;

end;

procedure TCodeEditor.WMEraseBkgnd(var Message: TMessage);
begin
  Message.Result:=1;
end;

procedure TCodeEditor.WMScroll(var M:TWMScroll;const Bar:integer);
var p:TPoint;si:TScrollInfo;i:integer;
begin
  p:=ScrollPos;
  if Bar=SB_HORZ then i:=p.X else i:=p.Y;
  si.cbSize:=sizeof(si);si.fMask:=SIF_ALL;GetScrollInfo(Handle,Bar,si);
  case M.ScrollCode of
    SB_BOTTOM:i:=si.nMax;
    SB_TOP:i:=0;
    SB_LINELEFT:dec(i);
    SB_LINERIGHT:inc(i);
    SB_PAGELEFT:dec(i,si.nPage);
    SB_PAGERIGHT:inc(i,si.nPage);
    SB_THUMBPOSITION,SB_THUMBTRACK:i:=si.nTrackPos;
  end;
  if Bar=SB_HORZ then p.X:=i else p.Y:=i;
  ScrollPos:=p;
end;

procedure TCodeEditor.WMHScroll(var Message: TWMHScroll);
begin
  WMScroll(Message,SB_HORZ);
end;

procedure TCodeEditor.WMVScroll(var Message: TWMVScroll);
begin
  WMScroll(Message,SB_VERT);
end;

procedure TCodeEditor.SetScrollRanges;
var si:TScrollInfo;
begin
  with si do begin
    cbSize:=SizeOf(si);
    fMask:=SIF_RANGE+SIF_PAGE;
    nPage:=VisibleLineCount;
    nMin:=0;nMax:=LineCount{+1};
  end;
  SetScrollInfo(Handle,SB_VERT,si,Redraw);

  with si do begin
    cbSize:=SizeOf(si);
    fMask:=SIF_RANGE+SIF_PAGE;
    nMin:=0;nMax:=1023;
    nPage:=VisibleLineCount;
  end;
  SetScrollInfo(Handle,SB_HORZ,si,Redraw);
end;

procedure TCodeEditor.SetSelEnd(const Value: TPoint);
begin
  if pt(FSelEnd)<>Value then begin
    FSelEnd:=Value;
    invalidate;
  end;
end;

procedure TCodeEditor.SetSelStart(const Value: TPoint);
begin
  if pt(FSelStart)<>Value then begin
    FSelStart:=Value;
    invalidate;
  end;
end;

function TCodeEditor.GetScrollPos:TPoint;
begin
  result.X:=windows.GetScrollPos(handle,SB_HORZ);
  result.Y:=windows.GetScrollPos(handle,SB_VERT);
end;

function TCodeEditor.HasSelection: boolean;
begin
  result:=(FSelStart.X<>FSelEnd.X)or(FSelStart.Y<>FSelEnd.Y);
end;

function TCodeEditor.hideSelection: boolean;
begin
  result:=DebugMode;
end;

procedure TCodeEditor.SetScrollPos(const p:TPoint);
begin
  if PointsEqual(p,GetScrollPos) then exit;
  SetScrollRanges(false);
  windows.SetScrollPos(handle,SB_HORZ,p.X,false);
  windows.SetScrollPos(handle,SB_VERT,p.Y,false);
  Invalidate;
end;

procedure TCodeEditor.UpdateSyntax;
var oldLen:integer;
    sBigComments:array[0..8191]of ansichar;
    s, sAll, sLine, sComment:ansistring;
begin
  if not SyntaxEnabled then begin FSyntax:=''; FTokenHighlight:=''; exit; end;

  //if(GetKeyState(VK_CONTROL)>=0) and FSyntaxValid and (length(FSyntax)=length(FCode)) and (length(FTokenHighlight)=length(FCode)*2)then exit;
  //bug: NavLink ottmarad az FSyntax Valid miatt. A navlinknak is egy markernek kene lennie.

  FSyntaxValid := false;

  //copy len
  oldLen:=Length(FSyntax);
  if oldLen<>length(FCode)then begin
    SetLength(FSyntax,length(FCode));
    SetLength(FTokenHighlight,length(FCode)*2);

    if length(FCode)>oldLen then begin
      FillChar(FSyntax[oldLen+1],length(FSyntax)-oldLen,0);
      FillChar(FTokenHighlight[oldLen*2+1],(length(FSyntax)-oldLen)*2,0);
    end;
  end;

  setlength(bigComments, 0);
  fillchar(sBigComments, sizeof(sBigComments), 0);
  if Assigned(FOnSyntax)then begin
    FOnSyntax(self,FCode,FSyntax,FTokenHighlight, sBigComments, high(sBigComments));

    sAll:=ansistring(sBigComments);

    for s in listSplit(sAll, #10)do if isWild2('*:*', s, sLine, sComment)then begin
      setlength(bigComments, length(bigComments)+1);
      with bigComments[high(bigComments)]do begin
        line:=strToIntDef(sLine, 0)-1;
        comment:=sComment;
        level:=0;
        if beginsWith(comment, '!')then begin
          level:=1;
          delete(comment, 1, 1);
        end;
      end;
    end;

    FSyntaxValid := true;
  end;
end;

type
  TTextFormat=record
    FontColor,BackColor:TColor;
    Style:TFontStyles;
  end;
  TTextFormats=array[0..21] of TTextFormat;
  PTextFormats=^TTextFormats;

var
  hlDefault:TTextFormats=(
{skWhitespace}  (FontColor:clBlack    ;BackColor:clWhite      ;Style:[]             ),
{skSelected}    (FontColor:clWhite    ;BackColor:10841427     ;Style:[]             ),
{skFoundAct}    (FontColor:$FCFDCD    ;BackColor:clBlack      ;Style:[]             ),
{skFoundAlso}   (FontColor:clBlack    ;BackColor:$78AAFF      ;Style:[]             ),
{skNavLink}     (FontColor:clBlue     ;BackColor:clWhite      ;Style:[fsUnderline]  ),
{skNumber}      (FontColor:clBlue     ;BackColor:clWhite      ;Style:[]             ),
{skString}      (FontColor:clBlue     ;BackColor:clSkyBlue    ;Style:[]             ),
{skKeyword}     (FontColor:clNavy     ;BackColor:clWhite      ;Style:[fsBold]       ),
{skSymbol}      (FontColor:clBlack    ;BackColor:clWhite      ;Style:[]             ),
{skComment}     (FontColor:clNavy     ;BackColor:clYellow     ;Style:[fsItalic]     ),
{skDirective}   (FontColor:clTeal     ;BackColor:clWhite      ;Style:[]             ),
{skIdentifier1} (FontColor:clBlack    ;BackColor:clWhite      ;Style:[]             ),
{skIdentifier2} (FontColor:clGreen    ;BackColor:clWhite      ;Style:[]             ),
{skIdentifier3} (FontColor:clTeal     ;BackColor:clWhite      ;Style:[]             ),
{skIdentifier4} (FontColor:clPurple   ;BackColor:clWhite      ;Style:[]             ),
{skIdentifier5} (FontColor:$0040b0    ;BackColor:clWhite      ;Style:[]             ),
{skIdentifier6} (FontColor:$b04000    ;BackColor:clWhite      ;Style:[]             ),
{skLabel}       (FontColor:clBlack    ;BackColor:$DDFFEE      ;Style:[fsUnderline]  ),
{skAttribute}   (FontColor:clPurple   ;BackColor:clWhite      ;Style:[fsBold]       ),
{skBasicType}   (FontColor:clTeal     ;BackColor:clWhite      ;Style:[fsBold]       ),
{skError}       (FontColor:clRed      ;BackColor:clWhite      ;Style:[fsUnderline]  ),
{skBinary1}     (FontColor:clWhite    ;BackColor:clBlue       ;Style:[]             )
);

  hlClassic:TTextFormats=(
{skWhitespace}  (FontColor:clVgaYellow      ;BackColor:clVgaLowBlue        ;Style:[]             ),
{skSelected}    (FontColor:clVgaLowBlue     ;BackColor:clVgaLightGray      ;Style:[]             ),
{skFoundAct}    (FontColor:clVgaLightGray   ;BackColor:clVgaBlack          ;Style:[]             ),
{skFoundAlso}   (FontColor:clVgaLightGray   ;BackColor:clVgaBrown          ;Style:[]             ),
{skNavLink}     (FontColor:clVgaHighRed     ;BackColor:clVgaLowBlue        ;Style:[fsUnderline]  ),
{skNumber}      (FontColor:clVgaYellow      ;BackColor:clVgaLowBlue        ;Style:[]             ),
{skString}      (FontColor:clVgaHighCyan    ;BackColor:clVgaLowBlue        ;Style:[]             ),
{skKeyword}     (FontColor:clVgaWhite       ;BackColor:clVgaLowBlue        ;Style:[fsBold]       ),
{skSymbol}      (FontColor:clVgaYellow      ;BackColor:clVgaLowBlue        ;Style:[]             ),
{skComment}     (FontColor:clVgaLightGray   ;BackColor:clVgaLowBlue        ;Style:[fsItalic]     ),
{skDirective}   (FontColor:clVgaHighGreen   ;BackColor:clVgaLowBlue        ;Style:[]             ),
{skIdentifier1} (FontColor:clVgaYellow      ;BackColor:clVgaLowBlue        ;Style:[]             ),
{skIdentifier2} (FontColor:clVgaHighGreen   ;BackColor:clVgaLowBlue        ;Style:[]             ),
{skIdentifier3} (FontColor:clVgaHighCyan    ;BackColor:clVgaLowBlue        ;Style:[]             ),
{skIdentifier4} (FontColor:clVgaHighMagenta ;BackColor:clVgaLowBlue        ;Style:[]             ),
{skIdentifier5} (FontColor:clVgaBrown       ;BackColor:clVgaLowBlue        ;Style:[]             ),
{skIdentifier6} (FontColor:clVgaHighBlue    ;BackColor:clVgaLowBlue        ;Style:[]             ),
{skLabel}       (FontColor:clBlack          ;BackColor:clVgaHighCyan       ;Style:[]             ),
{skAttribute}   (FontColor:clVgaHighMagenta ;BackColor:clVgaLowBlue        ;Style:[fsBold]       ),
{skBasictype}   (FontColor:clVgaHighCyan    ;BackColor:clVgaLowBlue        ;Style:[fsBold]       ),
{skError}       (FontColor:clVgaHighRed     ;BackColor:clVgaLowBlue        ;Style:[fsUnderline]  ),
{skBinary1}     (FontColor:clVgaLowBlue     ;BackColor:clVgaYellow         ;Style:[]             )
  );

  hlC64    :TTextFormats=(
{skWhitespace}  (FontColor:clC64LBlue       ;BackColor:clC64Blue           ;Style:[]             ),
{skSelected}    (FontColor:clC64Blue        ;BackColor:clC64LBlue          ;Style:[]             ),
{skFoundAct}    (FontColor:clC64LGrey       ;BackColor:clC64Black          ;Style:[]             ),
{skFoundAlso}   (FontColor:clC64LGrey       ;BackColor:clC64DGrey          ;Style:[]             ),
{skNavLink}     (FontColor:clC64Red         ;BackColor:clC64Blue           ;Style:[]             ),
{skNumber}      (FontColor:clC64Yellow      ;BackColor:clC64Blue           ;Style:[]             ),
{skString}      (FontColor:clC64Cyan        ;BackColor:clC64Blue           ;Style:[]             ),
{skKeyword}     (FontColor:clC64White       ;BackColor:clC64Blue           ;Style:[]             ),
{skSymbol}      (FontColor:clC64Yellow      ;BackColor:clC64Blue           ;Style:[]             ),
{skComment}     (FontColor:clC64LGrey       ;BackColor:clC64Blue           ;Style:[]             ),
{skDirective}   (FontColor:clC64Green       ;BackColor:clC64Blue           ;Style:[]             ),
{skIdentifier1} (FontColor:clC64Yellow      ;BackColor:clC64Blue           ;Style:[]             ),
{skIdentifier2} (FontColor:clC64LGreen      ;BackColor:clC64Blue           ;Style:[]             ),
{skIdentifier3} (FontColor:clC64Cyan        ;BackColor:clC64Blue           ;Style:[]             ),
{skIdentifier4} (FontColor:clC64Purple      ;BackColor:clC64Blue           ;Style:[]             ),
{skIdentifier5} (FontColor:clC64Orange      ;BackColor:clC64Blue           ;Style:[]             ),
{skIdentifier6} (FontColor:clC64LBlue       ;BackColor:clC64Blue           ;Style:[]             ),
{skLabel}       (FontColor:clBlack          ;BackColor:clC64Cyan           ;Style:[]             ),
{skAttribute}   (FontColor:clC64Purple      ;BackColor:clC64Blue           ;Style:[fsBold]       ),
{skBasicType}   (FontColor:clC64Cyan        ;BackColor:clC64Blue           ;Style:[fsBold]       ),
{skError}       (FontColor:clC64Red         ;BackColor:clC64Blue           ;Style:[]             ),
{skBinary1}     (FontColor:clC64Blue        ;BackColor:clC64Yellow         ;Style:[]             )
  );

  hlDark:TTextFormats=(
{skWhitespace}  (FontColor:$c7c5c5    ;BackColor:$2d2d2d      ;Style:[]             ),
{skSelected}    (FontColor:clBlack    ;BackColor:$c7c5c5      ;Style:[]             ),
{skFoundAct}    (FontColor:clBlack    ;BackColor:$ffffff      ;Style:[]             ),
{skFoundAlso}   (FontColor:clBlack    ;BackColor:$a7a5a5      ;Style:[]             ),
{skNavLink}     (FontColor:$FF8888    ;BackColor:$2d2d2d      ;Style:[fsUnderline]  ),
{skNumber}      (FontColor:$008CFA    ;BackColor:$2d2d2d      ;Style:[]             ),
{skString}      (FontColor:$64E000    ;BackColor:$283f28      ;Style:[]             ),
{skKeyword}     (FontColor:$5C00F6    ;BackColor:$2d2d2d      ;Style:[fsBold]       ),
{skSymbol}      (FontColor:$00E2E1    ;BackColor:$2d2d2d      ;Style:[]             ),
{skComment}     (FontColor:$e64Db5    ;BackColor:$442d44      ;Style:[fsItalic]     ),
{skDirective}   (FontColor:$4Db5e6    ;BackColor:$2d4444      ;Style:[]             ),  //@compiler directives
{skIdentifier1} (FontColor:$c7c5c5    ;BackColor:$2d2d2d      ;Style:[]             ),
{skIdentifier2} (FontColor:clGreen    ;BackColor:$2d2d2d      ;Style:[]             ),
{skIdentifier3} (FontColor:clTeal     ;BackColor:$2d2d2d      ;Style:[]             ),
{skIdentifier4} (FontColor:$f040e0    ;BackColor:$2d2d2d      ;Style:[]             ),
{skIdentifier5} (FontColor:$0060f0    ;BackColor:$2d2d2d      ;Style:[]             ),
{skIdentifier6} (FontColor:$f06000    ;BackColor:$2d2d2d      ;Style:[]             ),
{skLabel}       (FontColor:clBlack    ;BackColor:$2d2d2d      ;Style:[fsUnderline]  ),
{skAttribute}   (FontColor:$AAB42B    ;BackColor:$2d2d2d      ;Style:[fsBold]       ),
{skBasicType}   (FontColor:clWhite    ;BackColor:$2d2d2d      ;Style:[fsBold]       ),
{skError}       (FontColor:$00FFEF    ;BackColor:$2d2dFF      ;Style:[]             ),
{skBinary1}     (FontColor:$2d2d2d    ;BackColor:$20bCFA      ;Style:[]             )
);


procedure TCodeEditor.Paint;

  var x,y,tw,th:integer;
      lastFmt:ansichar;lastMod:byte;
      TextBuf:ansistring;
      Formats:PTextFormats;

  procedure wrSelectFmt(const Fmt:ansichar;const Modifier:byte);
  begin with Canvas, Formats^[ord(fmt)]do begin
    if(Modifier and 8)<>0then begin//Error (special ganyolas)
      Font.Color:=clErrorFont[TErrorType(Modifier and 7)];
      Font.Style:=Style;
      Brush.Color:=clErrorBk[TErrorType(Modifier and 7)];
    end else if(Modifier and 4)<>0then begin//Found
      Font.Color:=Formats^[2].FontColor;
      Font.Style:=Style;
      Brush.Color:=Formats^[2].BackColor;
    end else if(Modifier and 2)<>0then begin//Found2
      Font.Color:=Formats^[3].FontColor;
      Font.Style:=Style;
      Brush.Color:=Formats^[3].BackColor;
    end else if(Modifier and 1)<>0then begin//Selected
      Font.Color:=Formats^[1].FontColor;
      Font.Style:=Style;
      Brush.Color:=Formats^[1].BackColor;
    end else begin
      Font.Color:=FontColor;
      Font.Style:=Style;
      Brush.Color:=BackColor;
    end;
  end;end;

  procedure wrReset;
  begin
    x:=0;y:=0;
    Canvas.Font.Style:=[];
    with CharExtent do begin tw:=x;th:=y;end;
    Canvas.Brush.Style:=bsSolid;
    TextBuf:='';
  end;

  procedure wrFlush;
  var r:TRect;
      w:integer;
      ital:boolean;
  begin
    if TextBuf='' then exit;
    w:=tw*length(textBuf);
    r:=rect(x,y,x+w,y+th);
    ital:=fsItalic in Canvas.Font.Style;//1 pix shift, ha italic
    canvas.TextRect(r,x,y-ord(ital),TextBuf);
    x:=x+w;
    TextBuf:='';
  end;

  var previewWidth:integer;

  procedure wrNewLine(modifier:byte);
  var oc:TColor;

  begin
    wrFlush;
    if hideSelection then modifier:=modifier and not 1;
    oc:=Canvas.Brush.Color;
    Canvas.Brush.Color:=Formats^[modifier and 1].BackColor;
    canvas.FillRect(Rect(x,y,max(x,ClientRect.Right-switch(modifier<>0, 0, previewWidth)),y+th));
    Canvas.Brush.Color:=oc;
    x:=0;
    inc(y,th);
  end;

  procedure wrChar(const ch,fmt:ansichar;Modifier:byte);
  begin
    if hideSelection then Modifier:=modifier and not 1;

    if ch=#13 then exit;
    if ch=#10 then begin wrNewLine(Modifier);exit end;

    if(Fmt<>lastFmt)or(Modifier<>lastMod)then begin
      wrFlush;
      wrSelectFmt(Fmt,Modifier);
      lastFmt:=Fmt;lastMod:=Modifier;
    end;
    TextBuf:=TextBuf+ch;
  end;

  function InRange2(v,a,b:integer):Boolean;
  begin
    result:=(v>=a)and(v<=b)or(v>=b)and(v<=a);
  end;

var ActFoundTextPosition:integer;
    ActCursorPos:integer;

  function checkFoundText(po:integer):integer;//modifiert ad vissza, osszefesulve keres
  begin
    result:=0;
    if FFoundTextLen<=0 then exit;
    if ActFoundTextPosition>=Length(FFoundTextPositions)then exit;

    inc(po);
    while po>FFoundTextPositions[ActFoundTextPosition]+FFoundTextLen-1 do begin
      inc(ActFoundTextPosition);
      if ActFoundTextPosition>=Length(FFoundTextPositions)then exit;
    end;

    if po>=FFoundTextPositions[ActFoundTextPosition]then begin
      result:=2;
      if InRange(ActCursorPos+ord(FFoundTextBackwards),FFoundTextPositions[ActFoundTextPosition],FFoundTextPositions[ActFoundTextPosition]+FFoundTextLen-1)then
        Result:=4;
    end;
  end;

var spStart,spEnd:TPoint; //ScrollPos, aka visiblePos

  procedure DrawHighlightsAtCursor;
  type THighLightRec=record at,len:integer end;
  var highLights:THetArray<THighLightRec>;

    procedure AddHighlight(AAt,ALen:integer);
    var hl:THighLightRec;
    begin
      hl.at:=AAt;hl.len:=ALen; highLights.Append(hl);
    end;

    function posStart:integer;begin result:=xy2pos(point(0,spStart.Y),True);end;
    function posEnd:integer;begin result:=xy2pos(point(spEnd.X+1000,spEnd.Y),True);end;

    function doWords:boolean;
    var i:integer;
        w:ansistring;
    begin
      result:=false;

      if length(code)>1 shl 20 then exit; //too big -> too slow

      w:=wordat(Code,ActCursorPos+1,true);
      if(length(w)>=1{minimum wordlen})and(charmapEnglishUpper[w[1]]in['A'..'Z','_'])then
        result:=true;

      if not result then exit;

      //find all words on screen  (this one does on the whole document: it's good for coding)
      for i in PosMulti(w,Code,[poIgnoreCase,poWholeWords,poExtendedChars],posStart,posEnd)do
        AddHighlight(i-1,length(w));

      if highLights.Count=1 then highLights.Clear;
    end;

    function doClosures:boolean;
    const closures:array[0..4,0..1]of ansistring=
      (('(*','*)'),('/*','*/'),('(',')'),('[',']'),('{','}'));
    var i,j:integer;w:ansistring;
        cW1,cW2:ansistring;//closure1-en allunk, closure2-t keressuk
        cDir:integer;
        st,en:integer;
    begin
      cDir:=0;//nowarn
      result:=false;
      w:=copy(code,ActCursorPos+1,2);
      for i:=0 to high(closures)do begin
        for j:=0 to 1 do begin
          cW1:=closures[i,j];
          if cW1=copy(w,1,length(cW1))then begin
            cW2:=closures[i,1-j];
            cDir:=switch(j=0,1,-1);
            result:=true;
            break;
          end;
        end;
        if result then break;
      end;

      if not result then exit;

      AddHighlight(ActCursorPos,Length(cW1));

      j:=0;//closure nested level
      i:=ActCursorPos;//pos (0based)
      st:=posStart;en:=posEnd;
      while(i>=st)and(i<=en)do begin
        if copy(Code,i+1,length(cW1))=cW1 then inc(j) else
        if copy(Code,i+1,length(cW2))=cW2 then begin
          dec(j);
          if j=0 then begin AddHighlight(i,length(cW2));break;end;
        end;
        inc(i,cDir);
      end;

      //if highLights.Count=1 then highLights.Clear;
    end;

  var i:integer;
      sp:tpoint;
      r:trect;
      extent:TPoint;
  begin
    if not doClosures then if not doWords then exit;

    sp:=ScrollPos;  extent:=CharExtent;

    with Canvas.Pen do begin Style:=psSolid; Color:=clFuchsia; end;
    Canvas.Brush.Style:=bsClear;
    for i:=0 to HighLights.Count-1 do with HighLights.FItems[i]do begin
      r.TopLeft:=(TMyPoint(pos2xy(at))-sp)*extent;
      r.BottomRight:=r.TopLeft+tmypoint(point(len,1))*extent+point(1,1);
      Canvas.Rectangle(r);
    end;
  end;


  procedure DrawMarkers;
  var i:integer;
      sp:tpoint;
      r:trect;
      extent:TPoint;
      m:^TMarker;
      p0, p1:TPoint;
      x0, x1:integer;

    function LeftSpaceSize(y0, y1:integer):integer;
    var i,n,y:integer;
        s:ansistring;
    begin
      result:=99999;
      for y:=y0 to y1 do begin
        s:=Line[y];
        if trimf(s)='' then begin
          n:=99999;
        end else begin
          n:=0;
          for i:=1 to min(length(s), result+1) do begin
            if s[i]=' ' then n:=i
                        else break;
          end;
        end;
        result:=min(result, n);
      end;
    end;

    function MaxLineSize(y0, y1:integer):integer;
    var n,y:integer;
        s:ansistring;
    begin
      result:=0;
      for y:=y0 to y1 do begin
        s:=Line[y];
        n:=length(s);
        while(n>0)and(s[n]in[' ',#13,#10,#9])do dec(n);
        result:=max(result, n);
      end;
    end;

    procedure DrawBlock(r:TRect; xs0, xs1, siz, clr, enlarge:integer); //in pixels
    //r is the outermost rect.
    //xs0: topleft adjustment to the right
    //xs1: boottom right adjustment to the left
    //siz: the size of the rounded feature
    var p,q:array of TPoint;
    procedure add(x, y:integer); begin setlength(p, length(p)+1); p[high(p)]:=Point(x,y); end;
    procedure addq(const a:TPoint); begin setlength(q, length(q)+1); q[high(q)]:=a end;

    function adir(const a,b:TPoint):TPoint;
    begin
      result.x:=b.x-a.x;
      result.y:=b.y-a.y;
      if result.x>0 then result.x:=a.x+siz else if result.x<0 then result.x:=a.x-siz else result.x:=a.x;
      if result.y>0 then result.y:=a.y+siz else if result.y<0 then result.y:=a.y-siz else result.y:=a.y;
    end;

    function avg(const p0, p1:TPoint):TPoint;
    begin
      result.x:=(p0.X+p1.x)div 2;
      result.y:=(p0.y+p1.y)div 2;
    end;

    var i, pi, ni:integer;
        d0, d1:TMyPoint;
    begin
      Canvas.Pen.Color:=clr;
      Canvas.Pen.Width:=enlarge;

      if r.Left=r.Right then begin
        Canvas.Line(r.Left, r.Top, r.Left, r.Bottom);
        exit;
      end;

      //adjust width/height -1
      dec(r.Right);  dec(r.Bottom);

      //create points
      if xs0=0 then begin
        add(r.Left, r.Top);
      end else begin
        add(r.Left    , r.Top+Extent.y);
        add(r.Left+xs0, r.Top+Extent.y);
        add(r.Left+xs0, r.Top         );
      end;
      add(r.Right, r.Top);
      if xs1=0 then begin
        add(r.Right, r.Bottom);
      end else begin
        add(r.Right    , r.Bottom-Extent.y);
        add(r.Right-xs1, r.Bottom-Extent.y);
        add(r.Right-xs1, r.Bottom         );
      end;
      add(r.Left, r.Bottom);

      //round points
      for i:=0 to high(p)do begin
        pi:=i-1; if pi<0 then pi:=high(p);
        ni:=i+1; if ni>high(p) then ni:=0;

        d0:=adir(p[i], p[pi]);
        d1:=adir(p[i], p[ni]);

        addq(d0);
        addq(avg(avg(d0, d1), p[i]));
        addq(d1);
      end;

      canvas.moveto(q[high(q)]); for i:=0 to high(q)do canvas.lineto(q[i]);
    end;

  begin
    sp:=ScrollPos;  extent:=CharExtent;

    Canvas.Pen.Style:=psSolid;
    Canvas.Brush.Style:=bsClear;

    for i:=high(Markers) downto 0 do begin
      m:=@Markers[i];

      p0:=pos2xy(m.selStart);
      p1:=pos2xy(m.selEnd);

      if p0.Y=p1.Y then begin
        x0:=p0.X;  x1:=p1.X;
      end else begin
        x0:=min(p0.X, LeftSpaceSize(p0.Y+1, p1.y));
        x1:=max(p1.X, MaxLineSize(p0.Y, p1.Y-1));
      end;

      r.TopLeft    :=(TMyPoint(Point(x0, p0.Y  ))-sp)*extent;
      r.BottomRight:=(TMyPoint(Point(x1, p1.Y+1))-sp)*extent;
      DrawBlock(r, (p0.X-x0)*extent.X, (x1-p1.X)*extent.X, extent.X shr 1, m.color, m.enlarge);
    end;

    canvas.Pen.Width:=1;
  end;

var i,j,p0,p1,s0,s1,mo,vcc:integer;
    ActPos,cp:TPoint;
    wat:ansistring;
    pbmp:tbitmap;
    previewYOfs:integer;
begin
//  Formats:=@hlDefault;
//  Formats:=@hlClassic;
//  Formats:=@hlC64;
  Formats:=@hlDark;

  SetScrollRanges(true);
  canvas.Font.Assign(Font);
  Canvas.Font.Style:=[];

  spStart:=ScrollPos;
  spEnd:=ScrollPos+pt(VisibleColumnCount,VisibleLineCount);
  p0:=xy2pos(spStart,true);

  s0:=xy2pos(FSelStart,true);
  s1:=xy2pos(FSelEnd,true);

  //calculate screen end position
  p1:=p0;if p0<length(FCode)then for i:=0 to VisibleLineCount do
    while true do case FCode[p1+1]of
      #0:break;
      #10:begin inc(p1);break;end;
    else inc(p1)end;

  UpdateSyntax; //syntax needed from p0 to p1 only, but ewwwwww...

  //modify syntax to reftlect ctrl+mouse to draw navlinks
  if FMouseIsInside and(GetKeyState(VK_CONTROL)<0)then begin
    i:=xy2pos(HoverPos, false);
    if PointsEqual(pos2xy(i), HoverPos) then begin
      wat:=WordAt(FCode, i+1);
      if(wat<>'')then begin
        for i:=WordStart to WordStart+WordLen-1 do if(FSyntax[i]=#11)or(FCode[i]in['.','#','@']) then FSyntax[i]:=#4;
      end;
    end;
  end;

  //FoundText-hez
  ActFoundTextPosition:=0;
  ActCursorPos:=xy2pos(CursorPos,False);

  //preview image
  previewWidth:=0;

  pbmp:=PreviewBitmap;
  previewWidth:=pbmp.Width;
  if pbmp.Height<ClientHeight then begin
    canvas.SetBrush(bsSolid, Formats[0].BackColor);
    canvas.FillRect(rect(ClientWidth-pbmp.Width, 0, ClientWidth, ClientHeight));
  end;
  previewYOfs := -trunc(remap(ScrollPos.Y,0,LineCount,0,max(0,LineCount-(ClientHeight-15))));
  canvas.Draw(ClientWidth-pbmp.Width, previewYOfs, pbmp);
  freeAndNil(pbmp);

  wrReset;
  for i:=1 to VisibleLineCount do begin
    if ErrorLine=spStart.Y+i-1 then begin //error highlight
      vcc:=VisibleColumnCount;
      mo:=Ord(ErrorLineType)+8; //the special modifier
      j:=0; //count drawn chars
      while(p0<length(FCode))and not(FCode[p0+1]in[#13,#10,#0])do begin
        wrChar(FCode[p0+1], het.Utils.CharN(FSyntax, p0+1),mo);
        inc(p0);
        inc(j);
      end;
      for j:=j to vcc do wrChar(' ',#0, mo); //fill the end of the line
      wrNewLine(mo);
    end else if FBlockSelect then begin //block select
      ActPos:=point(spStart.X,spStart.Y+i-1);
      while(p0<length(FCode))and not(FCode[p0+1]in[#13,#10,#0])do begin
        wrChar(FCode[p0+1],het.Utils.CharN(FSyntax,p0+1),checkFoundText(p0)+ord(InRange2(ActPos.X,FSelStart.X,FSelEnd.X)and InRange2(ActPos.Y,FSelStart.Y,FSelEnd.Y)));
        inc(p0);inc(ActPos.X);
      end;
      if InRange2(ActPos.Y,FSelStart.Y,FSelEnd.Y)then while ActPos.X<=spEnd.X do begin
        wrChar(' ',#0,ord(InRange2(ActPos.X,FSelStart.X,FSelEnd.X)));
        inc(ActPos.X);
      end;
      wrNewLine(0);
    end else begin                       //normal select
      while(p0<length(FCode))and not(FCode[p0+1]in[#13,#10,#0])do begin
        wrChar(FCode[p0+1], het.Utils.CharN(FSyntax, p0+1),checkFoundText(p0)+ord(InRange(p0,s0,s1-1)));
        inc(p0);
      end;
      wrNewLine(ord(InRange(p0,s0,s1-1)));
    end;
    //seek next line
    if p0<length(FCode)then begin
      if FCode[p0+1]=#13 then inc(p0);
      if FCode[p0+1]=#10 then inc(p0);
      for j:=1 to spStart.x do if not(FCode[p0+1]in[#13,#10,#0])then inc(p0)else break;
    end else begin//eof
      wrFlush;wrNewLine(0);

      Canvas.Brush.Color:=Formats^[0].BackColor;
      Canvas.FillRect(rect(0,y,ClientWidth,ClientHeight));

      break;
    end;
  end;
  wrFlush;

  if not DebugMode then DrawHighlightsAtCursor;

  if DebugMode then DrawMarkers;

  BigComments_draw(canvas, rect(0,0,clientWidth-previewWidth, clientHeight), previewYOfs, 1, screenToClient(Mouse.CursorPos),
    spStart.Y, LineCount-VisibleLineCount);

  //caret
  if(Focused or(Screen.ActiveForm.Name='FrmCodeInsight'))then begin
    CreateCaret(Handle,0,switch(Overwrite,tw,2),th);

    if ConsoleMode then cp:=pos2xy(Length(FCode))
                   else cp:=CursorPos;

    with(Pt(cp)-spStart)*pt(tw,th)do SetCaretPos(x,y);
  end else begin
    HideCaret(Handle);
  end;

  //debug things
  {$IFDEF DEBUGLINE}
  if GetKeyState(VK_SCROLL)=1 then with canvas do begin
    debugstr:=ToPas(GetFullLine(CursorPos.Y));
    if debugstr<>'' then begin
      Font.Color:=clVGAYellow;
      SetBrush(bsSolid,clVgaLowRed);
      TextOut(0,0,debugstr);
    end;
  end;
  {$ENDIF}
end;

function TCodeEditor.getSyntaxAt(n:integer):TSyntaxKind; //slow&safe
begin
  if not FSyntaxValid then UpdateSyntax;
  if(n<0)or(n>=length(FCode))then exit(skWhitespace);
  result:=TSyntaxKind(FSyntax[n+1]);
end;

function TCodeEditor.getTokenHighlightAt(n:integer):TTokenHighLight; //slow&safe
begin
  if not FSyntaxValid then UpdateSyntax;
  if(n<0)or(n>=length(FCode))then begin result._data:=0; exit; end;
  result._data:=PWord(@FTokenHighLight[n*2+1])^;
end;

function TCodeEditor.getTokenAt(n:integer):ansistring; //slow&safe
var s0, s1:integer;
begin
  if not FSyntaxValid then UpdateSyntax;
  if(n<0)or(n>=length(FCode))then exit('');
  if not getTokenHighlightAt(n).isToken then exit('');

  s0:=n; while not getTokenHighlightAt(s0).isTokenBegin do dec(s0);
  s1:=n; while not getTokenHighlightAt(s1).isTokenEnd   do inc(s1);

  result:=copy(FCode, s0+1, s1-s0+1); //s1 is inclusive, it needs the +1
end;

function TCodeEditor.seekNextToken(var n:integer):boolean; //slow&safe
var len:integer;
begin
  len:=length(FCode);
  if n>=len then exit(false);
  if getTokenHighlightAt(n).isTokenEnd then inc(n);
  while(n<len)and not getTokenHighlightAt(n).isTokenEnd do inc(n);
  result:=getTokenHighlightAt(n).isTokenEnd;
end;

function TCodeEditor.seekPrevToken(var n:integer):boolean; //slow&safe
begin
  if n<=0 then exit(false);
  if getTokenHighlightAt(n).isTokenBegin then dec(n);
  while(n>0)and not getTokenHighlightAt(n).isTokenBegin do dec(n);
  result:=getTokenHighlightAt(n).isTokenBegin;
end;

function TCodeEditor.extendTokenRange(var ss, se:integer):boolean;

  procedure extendBrackets(var ss, se:integer);

    function bracketIdxOf(const s:ansistring):integer;
    begin
      if length(s)=1 then begin
        case s[1] of
          '{':exit(1);  '}':exit(-1);
          '(':exit(2);  ')':exit(-2);
          '[':exit(3);  ']':exit(-3);
        end;
      end else if s='q{' then exit(1);
      result:=0;
    end;

  var lst:array of integer;
  function empty:boolean; begin result:=length(lst)=0; end;
  function peek:integer; begin if empty then result:=0 else result:=lst[high(lst)]; end;
  function pop:integer; begin result:=peek; if not empty then setlength(lst, high(lst)); end;
  procedure push(i:integer); begin setlength(lst, length(lst)+1); lst[high(lst)]:=i; end;

  function processToken(const token:ansistring; inverse:boolean):boolean;
  var code:integer;
  begin
    if token='' then exit(false);//eof
    code:=bracketIdxOf(token);
    if inverse then code:=-code;
    
    if code>0 then begin //opening
      push(code);
    end else if code<0 then begin //closing
      if code=-peek then pop;
//                    else exit(false); //error //no report
    end;
    exit(true);
  end;

  var i:integer;
      token:ansistring;
  begin
    //1. extend to the right
    setlength(lst, 0);  i:=ss;
    while true do begin
      token:=getTokenAt(i);

      if not processToken(token, false) then break;

      if(i>=se-1)and empty then break; //exiting contidion: all selection is processed and bracket list is empty

      seekNextToken(i);
    end;
    se:=min(i+1, length(FCode));


    //2. extend to the right
    setlength(lst, 0);  i:=se-1;
    while true do begin
      token:=getTokenAt(i);

      if not processToken(token, true) then break;

      if(i<=ss)and empty then break; //exiting contidion: all selection is processed and bracket list is empty

      seekPrevToken(i);
    end;
    ss:=max(0, i);

  end;

begin
  if not FSyntaxValid then UpdateSyntax;
  result:=false;

  if ss=se then begin //one cursor
    //if no token, try it on char one the left
    if not getTokenHighlightAt(ss).isToken and getTokenHighlightAt(ss-1).isToken then begin dec(ss); dec(se); end;
    if not getTokenHighlightAt(ss).isToken then exit;

    //extend outward to whole tokens
    while not getTokenHighlightAt(ss).isTokenBegin do dec(ss);
    while not getTokenHighlightAt(se).isTokenEnd   do inc(se);
    inc(se);

  end else begin
    //extend inwart to find tokens at both ends
    while (ss<se) and not getTokenHighlightAt(ss  ).isToken do inc(ss);
    while (ss<se) and not getTokenHighlightAt(se-1).isToken do dec(se);

    //not found at all
    if(ss=se) or not getTokenHighlightAt(ss).isToken or not getTokenHighlightAt(se-1).isToken then exit;

    //extend outward to whole tokens
    while not getTokenHighlightAt(ss  ).isTokenBegin do dec(ss);
    while not getTokenHighlightAt(se-1).isTokenEnd   do inc(se);
  end;

  extendBrackets(ss, se);
  result:=true;
end;

function TCodeEditor.extendTokenRangeStr(ss, se:integer):ansistring;
begin
  if extendTokenRange(ss, se) then result:=copy(FCode, ss+1, se-ss)
                              else result:='';
end;



function TCodeEditor.FormatHTML(const src,syn:ansistring):ansistring;
var sb:IAnsiStringBuilder;
    Formats:PTextFormats;

procedure changeSyn(const sy:ansichar;open:boolean);
begin
  if ord(sy)>High(Formats^) then exit;
  with Formats[ord(sy)], sb do begin

    if open then begin
      AddStr('<code>');
      if(BackColor<>clNone)and(BackColor<>clWhite)then
        AddStr('<span style="background-color: #'+inttohex(SwapRB(ColorToRGB(BackColor)),6)+'">');

      AddStr('<font color="#'+inttohex(SwapRB(ColorToRGB(FontColor)),6)+'">');

//      if fsBold in Style then AddStr('<b>');    //wordpress nem birja
      if fsItalic in Style then AddStr('<i>');
      if fsUnderline in Style then AddStr('<u>');
    end else begin
      if fsUnderline in Style then AddStr('</u>');
      if fsItalic in Style then AddStr('</i>');
//      if fsBold in Style then AddStr('</b>');
      AddStr('</font>');
      if(BackColor<>clNone)and(BackColor<>clWhite)then AddStr('</span>');
      AddStr('</code>');
    end;
  end;
end;

var ActSyn:ansichar;
    i:integer;
begin sb:=AnsiStringBuilder(result, true); with sb do begin
  Formats:=@hlDefault;

  ActSyn:=#255;
  for i:=1 to length(src)do begin
    if ActSyn<>het.utils.charn(syn,i)then begin changeSyn(ActSyn,false); ActSyn:=het.utils.charn(syn,i); changeSyn(ActSyn,true);end;
    case src[i] of
      ' ':addstr('&nbsp;');  // wordpress elbaszodik
      '<':addstr('&lt;');
      '>':addstr('&gt;');
      #13:;
      #10:addstr('<br>');
    else
      addchar(src[i]);
    end;
  end;

  changeSyn(ActSyn,false);
end;end;

procedure TCodeEditor.SetCharN(idx: integer; const Value: ansichar);
begin
  if(idx>0)and(idx<=length(FCode))then begin
    FCode[idx+1]:=Value;
    Invalidate;
  end;
end;

procedure TCodeEditor.SetCode(const Value: ansistring);
begin
  FCode:=Value;

  ResetNewLineCache;
  CodeChanged;
end;


var bmpPreviewFonts:TBitmap; //this should be global

function TCodeEditor.PreviewBitmap:TBitmap;
var Formats:PTextFormats;
    cw,ch,w:integer;
    i,j,k,fcnt:integer;
    src,dst:PIntegerArray;
begin
  Formats:=@hlDark;
//  Formats:=@hlDefault;
  fcnt:=high(TTextFormats)+1;

  cw:=8; ch:=16;
  if bmpPreviewFonts=nil then begin
    bmpPreviewFonts:=TBitmap.CreateNew(pf32bit, cw*256, ch*fcnt);
    with bmpPreviewFonts, canvas do begin
      Font.Name:=self.Canvas.Font.Name;
      Font.Size:=11;//self.Canvas.Font.Size;
      Brush.Style:=bsSolid;
      for i:=0 to fcnt-1 do begin
        Font.Color:=Formats[i].FontColor;
        Font.Style:=Formats[i].Style;
        Brush.Color:=Formats[i].BackColor;
        for j:=0 to 255 do TextRect(rect(j*cw, ch*i, (j+1)*cw, (i+1)*ch),cw*j, ch*i, char(j));
      end;
    end;

    bmpPreviewFonts.Resize(256, 2*(high(TTextFormats)+1), rfLinearMipmapLinear);
    bmpPreviewFonts.Resize(256, 1*(high(TTextFormats)+1), rfLinear);
//    bmpPreviewFonts.SaveToFile2('c:\dl\bmpPreviewFonts.png');
  end;

  result:=TBitmap.CreateNew(pf32bit, 120, min(LineCount, 32768));

  with result, canvas do begin
    brush.Color:=Formats[0].BackColor;
    FillRect(rect(0,0,width,height));

    src:=bmpPreviewFonts.ScanLine[bmpPreviewFonts.Height-1];
    k:=1; w:=width;
    if(FCode<>'')and(length(FCode)=length(FSyntax))then for i:=0 to height-1 do begin
      dst:=ScanLine[i];
      j:=0;
      while true do begin
        if fcode[k] in[#0,#10,#13]then break;
        if j<w then dst[j]:=src[(fcnt-1-ensureRange(ord(FSyntax[k]),0,fcnt-1))shl 8+ord(FCode[k])];
        inc(j); inc(k);
      end;
      if fcode[k]=#0 then break;
      if fcode[k]=#10 then begin
        inc(k);
        if fcode[k]=#13 then inc(k);
      end else if fcode[k]=#13 then begin
        inc(k);
        if fcode[k]=#10 then inc(k);
      end;
    end;
    result.Resize(width shr 1, height, rfLinear);
    //result.Resize(width, height shl 1, rfNearest);

    SetPen(psSolid, RGBLerp(Formats[0].BackColor, Formats[1].BackColor, 128) );
    DrawRect(rect(0, ScrollPos.Y, Width, ScrollPos.Y+VisibleLineCount-1));
  end;
end;

////////////////////////////////////////////////////////////////////////////////
///  Files open/save

procedure TCodeEditor.FFileOpsOnNew(fn:string);
begin
  code:='';
  ClearUndoRedo;
  FileOps.Chg;
end;

procedure TCodeEditor.FFileOpsOnOpen(fn:string);
begin
  code:=logCodeExtract(TFile(fn), true);

  ClearUndoRedo;
end;

procedure TCodeEditor.FFileOpsOnSave(fn:string);
begin
  TFile(fn).Write(logCodeInsert(RTrimLines(Code)));

//  ClearUndoRedo; Not anymore. Undo is preserved after save, but the changed flag is cleared
  FileOps.isChanged:=false;
end;

function TCodeEditor.FileOps: TOpenSave;
begin
  if FFileOps=nil then begin
    FFileOps:=TOpenSave.Create(self);
    FFileOps.OnNew:=FFileOpsOnNew;
    FFileOps.OnOpen:=FFileOpsOnOpen;
    FFileOps.OnSave:=FFileOpsOnSave;
  end;
  result:=FFileOps;
end;

////////////////////////////////////////////////////////////////////////////////
///  Markers                                                                 ///
////////////////////////////////////////////////////////////////////////////////

procedure TCodeEditor.removeMarker(const idx:integer);
var j:integer;
begin
  if not inRange(idx, 0, high(markers)) then exit;

  for j:=idx to high(markers)-1 do markers[j]:=markers[j+1];
  setlength(markers,length(markers)-1);
end;

procedure TCodeEditor.removeMarker(const marker:PMarker);
var i:integer;
begin
  for i:=high(markers) downto 0 do if marker = @markers[i] then begin
    removeMarker(i);
    exit;
  end;
end;

function TCodeEditor.removeMarkers(const filter:ansistring):boolean;
var i:integer;
begin
  result:=false;
  for i:=high(markers) downto 0 do if IsWild2(filter, markers[i].name)then begin
    removeMarker(i);
    result:=true;
  end;
end;

procedure TCodeEditor.removeMarkers(ss, se:integer);
var i:integer;
begin
  for i:=high(markers) downto 0 do if(markers[i].selStart=ss)and(markers[i].selend=se)then begin
    removeMarker(i);
  end;
end;

procedure TCodeEditor.addMarker(selStart_, selEnd_: integer; name_:ansistring; isBreak_:boolean);
begin
  setlength(markers, length(markers)+1);
  with markers[high(markers)]do begin
    selStart:=selStart_;
    selEnd:=selEnd_;
    name:=name_;
    editor:=self;
    isBreak:=isBreak_;
  end;
end;

function TMarker.color: integer;
begin
  if name='hover' then exit(clWhite);
  if name='log' then exit(switch(isBreak, clRed, clLime));
  exit(0);
end;

function TMarker.enlarge: integer;
begin
  if name='hover' then result:=2 else result:=0;
end;


procedure TMarker.remove;
begin
  editor.removeMarker(@self);
end;

function TMarker.selLen:integer;
begin
  result:=selEnd-selStart+1;
end;

function TMarker.text:ansistring;
begin
  result:=copy(editor.Code, selStart+1, selLen);
end;

procedure TMarker.update(APos, ADel, AIns: integer);
var i:integer;
begin
  if(ADel=0)and(AIns=0)then exit;

  if ADel>0 then begin

    if APos+ADel<=selStart then begin //all the deletion is before the marker
      dec(selStart, ADel); dec(selEnd, ADel);
    end else if APos<selEnd then begin //deletion intersects marker
      for i:=0 to ADel-1 do begin //do it one by one. Dumb, but easy.
        if APos<selStart then begin
          dec(selStart); dec(selEnd);
        end else if APos<selEnd then begin
          dec(selEnd);
        end;
      end;
    end;
  end;
  if AIns>0 then begin
    if APos<=selStart then begin //the insertion is before the marker
      inc(selStart, AIns); inc(selEnd, AIns);
    end else if APos<selEnd then begin //insertion is inside the marker
      inc(selEnd, AIns);
    end;
  end;
end;

procedure TCodeEditor.updateMarkers(APos, ADel, AIns: integer);
var i:integer;
begin
  for i:=high(markers) downto 0 do
    markers[i].update(APos, ADel, AIns);
end;

function TCodeEditor.findMarkers(filter:ansistring):TArray<TMarker>;
var i:integer;
begin
  setLength(result, 0);
  for i:=0 to high(markers) do if IsWild2(filter, markers[i].name)then begin
    setlength(result, length(result)+1);
    result[high(result)]:=markers[i];
  end;
end;

function TCodeEditor.findMarkers(pos:integer):TArray<TMarker>;
var i:integer;
begin
  setLength(result, 0);
  for i:=0 to high(markers) do if inRange(pos, markers[i].selStart, markers[i].selEnd)then begin
    setlength(result, length(result)+1);
    result[high(result)]:=markers[i];
  end;
end;

function TCodeEditor.findMarker(pos:integer):PMarker;
var i:integer;
begin
  for i:=0 to high(markers) do
    if inRange(pos, markers[i].selStart, markers[i].selEnd)then
      exit(@markers[i]);
  result:=nil;
end;

function TCodeEditor.findMarker(ss, se:integer):PMarker;
var i:integer;
begin
  for i:=0 to high(markers) do
    if(markers[i].selStart=ss)and(markers[i].selEnd=se)then
      exit(@markers[i]);
  result:=nil;
end;

function TCodeEditor.findMarker(name_:ansistring):PMarker;
var i:integer;
begin
  for i:=0 to high(markers) do
    if markers[i].name=name_ then
      exit(@markers[i]);
  result:=nil;
end;

function TCodeEditor.countMarkers(ss,se:integer):integer;
var i:integer;
begin
  result:=0;
  for i:=0 to high(markers) do if(markers[i].selStart=ss)and(markers[i].selEnd=se)then inc(result);
end;

procedure TCodeEditor.sortMarkersBySelStart(var m:TArray<TMarker>);
var i,j:integer;
    t:TMarker;
begin
  for i:=0 to high(m)-1 do for j:=i+1 to high(m)do if m[i].selStart>m[j].selStart then begin
    t:=m[i]; m[i]:=m[j]; m[j]:=t;
  end;
end;

procedure TCodeEditor.sortMarkersBySelLen(var m:TArray<TMarker>);
var i,j:integer;
    t:TMarker;
begin
  for i:=0 to high(m)-1 do for j:=i+1 to high(m)do if m[i].selLen>m[j].selLen then begin
    t:=m[i]; m[i]:=m[j]; m[j]:=t;
  end;
end;



const logCodePrefixLog=' mixin(_DATALOGMIXIN(q{'; //MUST BE SAME strLENGTH
      logCodePrefixBrk=' mixin(_DATABRKMIXIN(q{'; //MUST BE SAME strLENGTH
      logCodeSuffix='} /+DATAMIXINEND+/)) ';

function pos2(const what0, what1, text:ansistring; from:integer; out position:integer):integer; //0 vagy 1 vagy 2
var i,j:integer;
begin
  i:=pos(what0, text, [], from);
  j:=pos(what1, text, [], from);

  case ord(i>0)+ord(j>0)*2 of
    1:begin position:=i; result:=1; end;
    2:begin position:=j; result:=2; end;
    3:begin
      if(i<j)then begin position:=i; result:=1; end
             else begin position:=j; result:=2; end;
    end;
  else
    result:=0;
  end;
end;

function TCodeEditor.logCodeInsert(src:ansistring):ansistring;
var m:TArray<TMarker>;
    i:integer;
    s0,s1,s2:ansistring;
begin
  m:=findMarkers('log');
  sortMarkersBySelStart(m);

  for i:=high(m)downto 0 do begin
    s0:=copy(src, 1, m[i].selStart);
    s1:=copy(src, m[i].selStart+1, m[i].selEnd-m[i].selStart);
    s2:=copy(src, m[i].selEnd+1, maxint);
    src:=s0+switch(m[i].isBreak, logCodePrefixBrk, logCodePrefixLog)+s1+logCodeSuffix+s2;
  end;

  result:=src;
end;

function TCodeEditor.logCodeExtract(src:ansistring; addMarkers:boolean):ansistring;
var i,j,k:integer;
begin
  removeMarkers('log');
  i:=1; //first search position
  while true do begin
    k:=pos2(logCodePrefixLog, logCodePrefixBrk, src, i, i);
    if k=0 then break;

    j:=pos(logCodeSuffix, src, [], i); if (j=0)or(j<i) then break;
    delete(src, j, length(logCodeSuffix));
    delete(src, i, length(logCodePrefixLog));

    if addMarkers then addMarker(i-1, j-1-length(logCodePrefixLog), 'log', k=2);
  end;
  result:=src;
end;

function TCodeEditor.logCodeRemoveAll(src:ansistring):ansistring;
begin
  replace(logCodePrefixLog, '', src, [roAll]);
  replace(logCodePrefixBrk, '', src, [roAll]);
  replace(logCodeSuffix, '', src, [roAll]);
  result:=src;
end;


function TCodeEditor.getHoverMarkerRange(pressed:boolean; out ss, se:integer):boolean;
var cp, hp:integer;
    m:PMarker;
begin
  result:=false;
  if pressed then begin //it is when dragging
    ss:=xy2pos(SelStart , false);
    se:=xy2pos(SelEnd   , false);
    if ss=se then begin
      if(CursorPos.Y>=LineCount)or(CursorPos.X>length(Line[CursorPos.Y])) then exit;
      cp:=xy2pos(CursorPos, false);
      ss:=cp; se:=cp;
    end;
  end else begin
    if(HoverPos.Y>=LineCount)or(HoverPos.X>length(Line[HoverPos.Y])) then exit;
    hp:=xy2pos(HoverPos, false);
    ss:=hp; se:=hp;

    m:=findMarker(hp);
    if m<>nil then begin //check if there is an existing marker
      ss:=m.selStart; se:=m.selEnd;
    end;
  end;
  result:=extendTokenRange(ss, se);
end;

procedure TCodeEditor.findAddMarker(visible:boolean; ss, se:integer; name:ansistring; isBreak:boolean);
begin
  removeMarkers(name);
  if visible then
    addMarker(ss, se, name, isBreak);
end;

procedure TCodeEditor.UpdateHoverMarker(enabled, pressed:boolean);
var ss, se:integer;
    visible:boolean;
begin
  visible:=enabled and getHoverMarkerRange(pressed, ss, se);

  findAddMarker(visible, ss, se, 'hover', false);

  invalidate;
end;


const BigComments_lineAreaWidth = 24;

function TCodeEditor.BigComments_focusedLine: integer;
var i:integer;
begin
  for i:=0 to high(bigComments)do with bigComments[i] do if hovered then exit(line);
  result:=-1;
end;

procedure TCodeEditor.BigComments_draw(canvas:TCanvas; r: TRect; yoffs, yscale: single; mousePos: TPoint; scrollY, scrollYRange:integer);

  procedure setupFont(const bigComment:TBigComment);
  begin with bigComment, canvas do begin
    if hovered then begin
      font.Color:=$ff6060;
      font.Style:=[fsUnderline];
    end else begin
      font.Color:=clSilver;
      font.Style:=[];
    end;
    if level>0 then begin
      font.Style:=font.Style+[fsBold];
      font.size:=11;
      if not hovered then font.Color:=clWhite;
    end else begin
      font.size:=9;
    end;
  end;end;

  procedure sort;
  var i, j: integer;
      tmp:TBigComment;
  begin
    for i:=0 to high(bigComments)-1 do for j:=i+1 to high(bigComments)do if bigComments[i].line>bigComments[j].line then begin
      tmp:=bigComments[i]; bigComments[i]:=bigComments[j]; bigComments[j]:=tmp;
    end;
  end;

  procedure align;
  var i, h, diff:integer;

    procedure setTop   (i,y:integer); var h:integer; begin with bigComments[i].crect do begin h:=bottom-top; top:=y; bottom:=y+h; end;end;
    procedure setBottom(i,y:integer); var h:integer; begin with bigComments[i].crect do begin h:=bottom-top; bottom:=y; top:=y-h; end;end;

  begin
    sort;
    h:=high(bigComments);
    if h<0 then exit;

    if bigComments[h].crect.bottom>r.Bottom then setBottom(h, r.Bottom);
    for i:=h-1 downto 0 do
      if bigComments[i].cRect.bottom>bigComments[i+1].cRect.top then
        setBottom(i, bigComments[i+1].cRect.top);

    if bigComments[0].crect.top<r.Top then setTop(0, r.Top);
    for i:=1 to h do
      if bigComments[i].cRect.Top<bigComments[i-1].cRect.bottom then
        setTop(i, bigComments[i-1].cRect.bottom);

    //overhang -> make it scrollable!
    diff:=bigComments[h].cRect.bottom-r.bottom;
    if(diff>0)and(ScrollYRange>0)then begin
      diff:=diff*ScrollY div ScrollYRange;
      for i:=0 to h do begin
        dec(bigComments[i].cRect.Top   , diff);
        dec(bigComments[i].cRect.Bottom, diff);
      end;
    end;
  end;


var i,th,y:integer;
    oldFont:TFont;
    pts:array[0..3]of TPoint;

begin with canvas do begin
  oldFont:=TFont.Create;
  oldFont.Assign(Font);
  font.Name:='Arial';
  setBrush(bsClear);

  dec(r.right, BigComments_lineAreaWidth);

  //organize
  for i:=0 to high(bigComments)do with bigComments[i]do begin
    //calculate ideal rect
    setupFont(bigComments[i]);
    crect.Right:=r.Right;
    crect.Left:=r.Right-textWidth(comment);
    th:=textHeight('W');
    y:=round(bigComments[i].line*yscale+yoffs);
    crect.Top:=y-th shr 1;
    crect.Bottom:=crect.top+th;

    lineP1:=Point(crect.Right+BigComments_lineAreaWidth, y);
  end;

  align;

  //draw
  pen.Style:=psSolid;
  pen.color:=font.Color;
  pen.width:=1;
  for i:=0 to high(bigComments)do with bigComments[i], canvas do begin
    hovered:=PtInRect(crect, mousePos); //mouse hover

    setupFont(bigComments[i]);

    lineP0:=Point(crect.Right+3, (crect.Top+crect.Bottom)div 2);
    textOut(crect.Left, crect.Top, comment);

    pts[0]:=lineP0; pts[3]:=lineP1;
    pts[1]:=Point((pts[0].X+pts[3].X)div 2, pts[0].Y);
    pts[2]:=Point(pts[1].X, pts[3].Y);
    PolyBezier(pts);
  end;

  Font.Assign(oldFont);
  freeAndNil(oldFont);
end;end;

procedure TCodeEditor.BigComments_showLine(line: integer);
begin
  if inRange(line, 0, LineCount-1)then begin
    CursorPos:=Point(0, LineCount-1);
    ShowLine(line+3, 0, 3);
  end;
end;

initialization
finalization
  FREEaNDnIL(bmpPreviewFonts);
end.





