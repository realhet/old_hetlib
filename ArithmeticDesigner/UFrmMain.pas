unit UFrmMain; //new standalone version het.objects

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, het.utils, het.objects, het.Stream, het.FileSys, het.Arrays,
  math, opengl1x, het.glviewer, UVector, UMatrix, het.textures, het.Gfx,
  gltImage, ExtCtrls, UCircuitArithmetic, het.Parser, USHA1, Menus,
  het.OpenSave;

type
  TFrmMain = class(TForm)
    Timer1: TTimer;
    MainMenu1: TMainMenu;
    OpenSave1: TOpenSave;
    N1: TMenuItem;
    New1: TMenuItem;
    Open1: TMenuItem;
    Save1: TMenuItem;
    SaveAs1: TMenuItem;
    N2: TMenuItem;
    Exit1: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure New1Click(Sender: TObject);
    procedure Open1Click(Sender: TObject);
    procedure Save1Click(Sender: TObject);
    procedure SaveAs1Click(Sender: TObject);
    procedure Exit1Click(Sender: TObject);
    procedure OpenSave1New(fname: string);
    procedure OpenSave1Open(fname: string);
    procedure OpenSave1Save(fname: string);
  private
    { Private declarations }
  public
    { Public declarations }
    Viewer:TGlViewer;
    MouseState:TMouseState;
    Cam,Cam2:TM44f;
    Circuit:TCircuit;
    Mode:(moNone,moSelectRect,moTranslate,moTranslateClone,moDrawWire);
    WireStart:TGatePos;
    list:GLenum;

    procedure OnMouse(Sender:TObject);
    procedure OnGlPaint(Sender:TObject);

    function ScreenToWorld(const p:TPoint):TV2f;
    function CursorPos:TGatePos;
    function HoverRect:TRect;
    function HoverDelta:TV2f;

    procedure Startup;
  end;

var
  FrmMain: TFrmMain;

implementation

uses
  UFrmConstProperties;

{$R *.dfm}

////////////////////////////////////////////////////////////////////////////////
/// TFrmMain  CREATE                                                         ///
////////////////////////////////////////////////////////////////////////////////

procedure TFrmMain.FormCreate(Sender: TObject);
begin
  Viewer:=TGLViewer.Create(self);
  with Viewer do begin
    Parent:=Self;
    Align:=alClient;
    VSynch:=true;
    AutoInvalidate:=false;
    OnPaint:=OnGlPaint;
  end;

  MouseState:=TMouseState.Create(Viewer);
  MouseState.OnChange:=OnMouse;

  cam:=M44fIdentity;MScale(Cam,16);Cam2:=Cam;

  Circuit:=TCircuit.Create(nil);
end;

procedure TFrmMain.Startup;
begin
//  Make;
//  Circuit.LoadFromStr(TFile('c:\circuit.dat'));
end;

procedure TFrmMain.FormDestroy(Sender: TObject);
begin
  with Circuit do TFile(Name+'.circuit').Write(ZCompress(SaveToStr(stBin)));
end;

procedure MakeGridTexture;
var b:TBitmap;
begin
  b:=TBitmap.CreateNew(pf24bit,8,8);
  with b,Canvas do begin
    SetBrush(bsSolid,clBlack);FillRect(Rect(0,0,width,height));
    SetPen(psSolid,clGray);
    Line(0,0,1,0);
  end;
  b.Components:=2;
  TextureCache['grid'].LoadFromBitmap(b,mtColor_LA,atGradient,true,false);

  b.Free;
end;

////////////////////////////////////////////////////////////////////////////////
/// TFrmMain  UTILS                                                          ///
////////////////////////////////////////////////////////////////////////////////

function TFrmMain.ScreenToWorld(const p: TPoint): TV2f;
begin
  with viewer.ScreenToWorld(p)do result:=v2f(v[0],v[1]);
end;

function TFrmMain.CursorPos: TV2i;
begin
  result:=round(ScreenToWorld(MouseState.Act.Screen));
end;

function TFrmMain.HoverRect: TRect;
var mi,ma:TV2f;
begin with result do begin
  with viewer.ScreenToWorld(MouseState.Act.Screen)do mi:=v2f(v[0],v[1]);
  with viewer.ScreenToWorld(MouseState.Pressed.Screen)do ma:=v2f(v[0],v[1]);
  Sort(mi.V[0],ma.V[0]);
  Sort(mi.V[1],ma.V[1]);
  result:=Rect(ceil(mi.V[0]),ceil(mi.V[1]),floor(ma.V[0]),floor(ma.V[1]))
end;end;

function TFrmMain.HoverDelta: TV2f;
begin
  with viewer.ScreenToWorld(MouseState.Act.Screen)do result:=v2f(v[0],v[1]);
  with viewer.ScreenToWorld(MouseState.Pressed.Screen)do result:=result-v2f(v[0],v[1]);
end;

////////////////////////////////////////////////////////////////////////////////
/// TFrmMain  DRAW                                                           ///
////////////////////////////////////////////////////////////////////////////////

procedure TFrmMain.OnGlPaint(Sender: TObject);
var v:TV2f;
begin
  if Tag=0 then begin//startup
    Tag:=1;
    Startup;
    Viewer.selectFontOutline('Tahoma',[fsBold]);
    MakeGateTexture;
    MakeGridTexture;
  end;

  glMatrixMode(GL_PROJECTION);glLoadIdentity;glOrtho(0,ClientWidth,ClientHeight,0,-1,1);
  glMatrixMode(GL_MODELVIEW);glLoadMatrixf(@cam2);

  glEnable(GL_COLOR_MATERIAL);glDisable(GL_CULL_FACE);glDisable(GL_DEPTH_TEST);glDepthMask(GL_FALSE);

//  glClearColor(0,0,0,0);glClear(GL_COLOR_BUFFER_BIT);
  with TextureCache['grid']do begin
    Bind(0,rfLinearMipmapLinear,false);
    glTexGeni(GL_S,GL_TEXTURE_GEN_MODE,GL_OBJECT_LINEAR);glEnable(GL_TEXTURE_GEN_S);
    glTexGeni(GL_T,GL_TEXTURE_GEN_MODE,GL_OBJECT_LINEAR);glEnable(GL_TEXTURE_GEN_T);
    glColor3f(1,1,1);
    glRectf(-2048,-2048,4096,4096);
    glDisable(GL_TEXTURE_GEN_S);
    glDisable(GL_TEXTURE_GEN_T);
    glDisable(GL_TEXTURE_2D);
  end;

  MakeWireTexture(-frac(now*24*60*60));

  Viewer.selectFontOutline('Tahoma',[]);

  if(MouseState.Act.Shift*[ssLeft,ssRight])<>[]then begin
    Circuit.GlDraw(Viewer,HoverDelta*ord(Mode in[moTranslate,moTranslateClone]),Mode=moTranslateClone);
  end else begin
    if list=0 then list:=glGenLists(1);
    if CheckAndClear(Circuit.Changed)then begin
      glNewList(list,GL_COMPILE);
      Circuit.GlDraw(Viewer,HoverDelta*ord(Mode in[moTranslate,moTranslateClone]),Mode=moTranslateClone);
      glEndList;
    end;

    glCallList(list);
  end;

  Circuit.GlDrawTexts(Viewer);

  if Mode=moSelectRect then begin//selectRect
    with MouseState.Act do case ord(ssShift in MouseState.Act.Shift)+ord(ssCtrl in MouseState.Act.Shift)shl 1 of
      0:glColor4f(1,1,1,0.33);
      1:glColor4f(0.6,0.6,1,0.33);
      2:glColor4f(1,0.6,0.6,0.33);
      3:glColor4f(1,0.6,1,0.33);
    end;

    glEnable(GL_BLEND);glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
    glPushMatrix;
    glLoadIdentity;
    with MouseState do glRecti(Pressed.Screen.X,Pressed.Screen.Y,Act.Screen.X,Act.Screen.Y);
    glPopMatrix;
    glDisable(GL_BLEND);
  end else if Mode=moDrawWire then begin
    glColor3f(1,1,1);
    v:=ScreenToWorld(Mousestate.Act.Screen);

    glBegin(GL_LINES);
    with WireStart do glVertex2f(v[0],v[1]);
    with v do glVertex2f(V[0],V[1]);
    glEnd;
  end;

end;

////////////////////////////////////////////////////////////////////////////////
/// User Interactction                                                       ///
////////////////////////////////////////////////////////////////////////////////

procedure TFrmMain.OnMouse(Sender: TObject);
var c,t:TV3f;
    z:Single;
    GateAtCursor:TGate;

  procedure SelectAtCursorIfNot;
  begin
    if(GateAtCursor<>nil)and(not GateAtCursor.sel)then begin
      Circuit.SelectNone;
      Circuit.UpdateSelection(CursorPos,soAdd);
    end;
  end;

begin with MouseState do begin
  if Delta.Wheel<>0 then begin
    z:=1+MouseState.Delta.Wheel/1500;
    with Viewer.ScreenToClient(Mouse.CursorPos)do c:=v3f(x,y,0);
    t:=v3f(cam[3,0],cam[3,1],0);
    MTranslate(cam,c+(t-c)*z-t);
    MScale(cam,z,z,1);
  end;

  if ssMiddle in Act.Shift then begin
    with Delta.Screen do MTranslate(cam,v3f(X,Y,0));
  end;

  if justPressed then begin
    GateAtCursor:=Circuit.GateAt(CursorPos);
    if GateAtCursor<>nil then begin//gate at cursor
      //select gate, if not sedlected already
      if Pressed.Shift=[ssLeft] then begin//Left
        SelectAtCursorIfNot;
        if GetKeyState(ord('C'))<0 then Mode:=moTranslateClone
                                   else Mode:=moTranslate;
      end else if(Pressed.Shift=[ssCtrl,ssLeft])or(Pressed.Shift=[ssShift,ssLeft])then begin
        Circuit.UpdateSelection(CursorPos,soToggle)
      end;
    end else begin//no gate at cursor
      if ssLeft in Pressed.Shift then
        Mode:=moSelectRect;
    end;

    if Pressed.Shift=[ssRight]then begin//Right on anything {DrawWire}
      WireStart:=cursorpos;
      Mode:=moDrawWire;
    end;
  end;

  if JustReleased then begin
    if Mode=moSelectRect then begin
      if Act.Shift=[] then begin Circuit.SelectNone;Circuit.UpdateSelection(HoverRect,soAdd);end else
      if Act.Shift=[ssShift] then Circuit.UpdateSelection(HoverRect,soAdd)else
      if Act.Shift=[ssCtrl] then Circuit.UpdateSelection(HoverRect,soRemove)else
      if Act.Shift=[ssCtrl,ssShift] then Circuit.UpdateSelection(HoverRect,soToggle);
    end else if mode=moTranslate then begin
      Circuit.TranslateSelected(round(HoverDelta),false);
    end else if mode=moTranslateClone then begin
      Circuit.TranslateSelected(round(HoverDelta),true);
    end else if mode=moDrawWire then begin
      Circuit.AddWire(WireStart,CursorPos);
    end;
    Mode:=moNone;
  end;

  Viewer.Invalidate;
end;end;

procedure TFrmMain.FormKeyDown(Sender: TObject; var Key: Word;Shift: TShiftState);

  procedure g(const t:TGateType);
  begin
    Circuit.AddGate(CursorPos,t);
  end;

  procedure AddConst;
  begin
    SetConstGateProperties(Circuit.AddGate(CursorPos,gtInput));
  end;

  procedure cycleRols;
  var a:TGate;
  begin
    a:=Circuit.GateAt(CursorPos);
    if a=nil then g(gtRol1)else case a.Typ of
      gtRol1:g(gtRol2);
      gtRol2:g(gtRol4);
      gtRol4:g(gtRol5);
      gtRol5:g(gtRol30);
    else g(gtRol1);end;
  end;

begin
  if true{Shift=[]} then case Key of
    VK_F1:addConst;
    VK_F2:g(gtINot);
    VK_F3:g(gtIAnd);
    VK_F4:g(gtIOr);

    VK_F5:g(gtIXor);
    VK_F6:g(gtIEq);
    VK_F7:g(gtIAdd);
    VK_F8:cycleRols;

    VK_DELETE:Circuit.DeleteSelected;

    VK_F9:begin
      Circuit.Simulate;
    end;

    ord('S'):Circuit.SelectSourcePath(not(ssShift in Shift));
    ord('O'):if not(ssShift in Shift)then Circuit.OptimizeRedundancy else Circuit.OptimizeCommutative;
    ord('P'):Circuit.OptimizeConstantCalculations;
    ord('A'):Circuit.SelectAll;
    ord('C'):Circuit.CropSelected;
  else exit;end;
end;

procedure TFrmMain.New1Click(Sender: TObject);begin OpenSave1.New;end;
procedure TFrmMain.Open1Click(Sender: TObject);begin OpenSave1.Open end;
procedure TFrmMain.Save1Click(Sender: TObject);begin OpenSave1.Save end;
procedure TFrmMain.SaveAs1Click(Sender: TObject);begin OpenSave1.SaveAs;end;
procedure TFrmMain.Exit1Click(Sender: TObject);begin Close end;

procedure TFrmMain.OpenSave1New(fname: string);
begin
  FreeAndNil(Circuit);
  Circuit:=TCircuit.Create(nil);
end;

procedure TFrmMain.OpenSave1Open(fname: string);
begin
  FreeAndNil(Circuit);
  Circuit:=TCircuit.Create(nil);
  Circuit.LoadFromFile(fname);
end;

procedure TFrmMain.OpenSave1Save(fname: string);
begin
  Circuit.SaveToFile(stDfm,fname);
end;

////////////////////////////////////////////////////////////////////////////////
/// TFrmMain  UPDATE                                                         ///
////////////////////////////////////////////////////////////////////////////////

procedure TFrmMain.Timer1Timer(Sender: TObject);
begin

//  Circuit.Calculate2(Mem[0],Mem[1]);
//  Circuit.Calculate(Mem);
  Cam2:=MLerp(Cam2,Cam,0.5);
  if(MouseState.Act.Shift*[ssLeft,ssRight])<>[]then Circuit.Changed:=true;
  Viewer.Invalidate;

  Circuit.UpdateStats;
  with circuit, stats, CursorPos do Caption:=
    format('AD 1.00 [%s] [%.3d %.3d] Selected gates: %d  Sel.Active gates: %d  Selected constants: %d  Sel.ActiveConstants: %d  TempRegCnt: %d',
           [OpenSave1.FileName,v[0],v[1],SelectedGateCount,SelectedActiveGateCount,SelectedConstCount,SelectedActiveConstCount,TempRegCnt]);
end;

initialization
end.
