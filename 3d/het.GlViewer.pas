unit het.GlViewer; //het.textures

interface

uses
  Windows, Types, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, extctrls, opengl1x, het.Utils, UVector, UMatrix, math;

type
  TGLViewer=class;

  TGlConsole=class
  private
    FScreen:array[0..24,0..79]of packed record Chr:ansichar;Clr:byte;end;
    FCursorPos:TPoint;
    FClr:byte;
    FChanged:boolean;
    constructor Create;
  public
    procedure Write(const s:ansistring);
    procedure WriteLn(const s:ansistring='');
    procedure ClrScr;
    function GetTextColor:byte;
    procedure SetTextColor(const clr:byte);
    property TextColor:Byte read GetTextColor write SetTextColor;
    procedure SetCursorPos(const p:TPoint);
    property CursorPos:TPoint read FCursorPos write SetCursorPos;
  end;

  TGLViewer=class(TWinControl)
  private
    FDC:integer;
    FRC:integer;
    FVSynch:boolean;
    FOnPaint:TNotifyEvent;
    FBeforeFirstPaint:TNotifyEvent;
    FAfterPaint:TNotifyEvent;
    FAutoInvalidate:boolean;
    TPrev:int64;
    _LastVendor:PAnsiChar;
    _LastPixelFormat:integer;
    _LastForegroundWindowHandle:HWND;
    Timer:TTimer;
    started:boolean;
    procedure CreateRenderingContext;
    procedure DestroyRenderingContext;
    function GetActive: boolean;
    procedure SetActive(const Value: boolean);
    procedure SetVSynch(const Value: boolean);
//    procedure MyIdle(sender:TObject;var done:boolean);
    procedure SetAutoInvalidate(const Value: boolean);
    procedure WMGetDlgCode(var M: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure Win7WindowMaskingBugfix;
    procedure TimerOnTimer(sender:TObject);
  //font functions
  private
    fonts:array of record
      listBase:integer;
      name:string;style:TFontStyles;
    end;
    selectedFont:integer;
    FontCanvas:TCanvas;
  public
    procedure selectFontOutline(const AName:string;const AStyle:TFontStyles; const APrecision:single=0.005);
    procedure DrawText(const s:ansistring;const alignemt:ansistring='');

    function GetPixelDepth(const p:tpoint):single;
    function ScreenToWorld(const p:tpoint):TV3f;overload;
    function ScreenToWorld(const p:TV3F):TV3f;overload;
  //window functions
  public
    DeltaTime:single;
    constructor Create(AOwner:TComponent);override;
    destructor Destroy;override;
    procedure WMEraseBkgnd(var m:TMessage);message WM_EraseBkgnd;
    procedure CreateParams(var Params: TCreateParams);override;
    property Active:boolean read GetActive write SetActive;
    property DC:integer read FDC;
    property RC:integer read FRC;

  private
    FConsole:TGlConsole;
  public
    property Console:TGlConsole read FConsole;
    procedure DrawConsole;

    function SnapShot(const r:TRect;const alpha:boolean=false):TBitmap;overload;
    function SnapShot(const alpha:boolean=false):TBitmap;overload;
  protected
    procedure WMPaint(var m:TMessage);message WM_PAINT;
  published
    property AutoInvalidate:boolean read FAutoInvalidate write SetAutoInvalidate default false;
    property OnPaint:TNotifyEvent read FOnPaint write FOnPaint;
    property BeforeFirstPaint:TNotifyEvent read FBeforeFirstPaint write FBeforeFirstPaint;
    property AfterPaint:TNotifyEvent read FAfterPaint write FAfterPaint;
    property VSynch:boolean read FVSynch write SetVSynch default true;
    property Align;
    property Visible;

    property OnMouseMove;
    property OnMouseDown;
    property OnMouseUp;
    property OnMouseWheel;
    property OnMouseWheelDown;
    property OnMouseWheelUp;
    property OnDblClick;

    property OnEnter;
    property OnExit;
  protected  //                         mouse handling                          //

  public
    ClippingInfo:TClippingInfo;
  end;

procedure glDrawPlane(const width,height,tw,th:single);overload;
procedure glDrawPlane(const width,height:single);overload;
procedure glDrawPlane2TexCoord(const width,height,tw,th:single);overload;
procedure glDrawPlane2TexCoord(const width,height:single);overload;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Het',[TGLViewer]);
end;

var
  _ActiveGLViewer:TGLViewer;

function SetGLPixelFormat(dc:integer;doublebuffered:boolean;color,alpha,accum,depth,stencil:integer):boolean;
var pf:TPixelFormatDescriptor;
begin
  FillChar(pf,sizeof(pf),0);with pf do begin
    nSize:=sizeof(pf);
    nVersion:=1;
    dwFlags:=PFD_SUPPORT_OPENGL or PFD_SWAP_EXCHANGE or PFD_DRAW_TO_WINDOW;
    if doublebuffered then dwFlags:=dwFlags or PFD_DOUBLEBUFFER;
    iPixelType:=PFD_TYPE_RGBA;

    cColorBits:=color;
    cAlphaBits:=alpha;
    cAccumBits:=accum;
    cDepthBits:=depth;
    cStencilBits:=stencil;
    iLayerType:=PFD_MAIN_PLANE;
  end;

  result:=SetPixelFormat(dc,ChoosePixelFormat(dc,@pf),@pf);
  if not result then RaiseLastError('SetGLPixelFormat(');
end;

{ TGLViewer }

constructor TGLViewer.Create(AOwner: TComponent);
begin
  inherited;
  FVSynch:=true;
  controlStyle:=[csAcceptsControls,csOpaque,csCaptureMouse,csClickEvents,csReflector,csDoubleClicks];
  TabStop:=true;

  FConsole:=TGlConsole.Create;

  if not(csDesigning in ComponentState) then
    OnIdle(self,procedure (var done:boolean)
    begin
      if AutoInvalidate then Invalidate;
      done:=not AutoInvalidate;
    end);

  Timer:=TTimer.Create(self);
  Timer.Interval:=15;
  Timer.OnTimer:=TimerOnTimer;
end;

procedure TGLViewer.TimerOnTimer(sender:TObject);
begin
  if AutoInvalidate then Invalidate;
  Win7WindowMaskingBugfix;
end;

procedure TGLViewer.CreateParams(var Params: TCreateParams);
begin
  inherited;
  with Params do begin
    Style:=Style or WS_CLIPCHILDREN or WS_CLIPSIBLINGS;
    WindowClass.Style:=WindowClass.Style or CS_OWNDC;
  end;
end;

procedure TGLViewer.WMGetDlgCode(var M: TWMGetDlgCode);
begin
  M.Result:=DLGC_WANTTAB or DLGC_WANTARROWS or DLGC_WANTALLKEYS;
end;

procedure TGLViewer.CreateRenderingContext;
begin
  if FRC=0 then begin
    if FDC=0 then FDC:=GetDC(handle);
    SetGLPixelFormat(FDC,true,32,8,0,24,8);
    FRC:=wglCreateContext(FDC);
    if FRC=0 then RaiseLastError('TGLViewer.CreateRenderingContext');

    selectedFont:=-1;
    FontCanvas:=TCanvas.Create;
    FontCanvas.Handle:=FDC;
  end;
end;

procedure TGLViewer.DestroyRenderingContext;
begin
  if FRC<>0 then begin
    wglDeleteContext(FRC);FRC:=0;

    SetLength(fonts,0);selectedFont:=-1;
    FreeAndNil(FontCanvas);
  end;
end;

destructor TGLViewer.Destroy;
begin
  FreeAndNil(FConsole);
  DestroyRenderingContext;
  inherited;
end;

function TGLViewer.GetActive: boolean;
begin
  result:=_ActiveGLViewer=self;
end;

procedure TGLViewer.SetActive(const Value: boolean);

  procedure ReadExtras;
  var pixelFormat:integer;
  begin
    pixelFormat:=GetPixelFormat(Cardinal(FDC));
    if PixelFormat<>_LastPixelFormat then begin
      if glGetString(GL_VENDOR)<>_LastVendor then begin
        ReadExtensions;
        ReadImplementationProperties;
        _LastVendor:=glGetString(GL_VENDOR);
      end else begin
        ReadWGLExtensions;
        ReadWGLImplementationProperties;
      end;
      _LastPixelFormat:=pixelFormat;
    end
  end;

begin
  if Value<>GetActive then
    if Value then begin
      if FDC=0 then FDC:=GetDC(handle);
      if FRC=0 then begin
        CreateRenderingContext;
        wglMakeCurrent(FDC,FRC);
      end else
        wglMakeCurrent(FDC,FRC);
      ReadExtras;
      _ActiveGLViewer:=self;
    end else begin
      if GetActive then begin
        wglMakeCurrent(0,0);
        _ActiveGLViewer:=nil;
        if FDC<>0 then begin releaseDC(handle,FDC);FDC:=0;end; //nem kell deaktivalni. 20131107: de kell
      end;
    end;
end;

procedure TGLViewer.SetVSynch(const Value: boolean);
begin
  FVSynch := Value;
end;

procedure TGLViewer.WMEraseBkgnd(var m: TMessage);
begin
  m.Result:=1;
end;

procedure TGLViewer.WmPaint;

  procedure Drawtext(const s:ansistring);
  begin
    glClear(GL_COLOR_BUFFER_BIT);
    glMatrixMode(GL_PROJECTION);glLoadIdentity;glOrtho(0,320,0,240,-10,10);
    glMatrixMode(GL_MODELVIEW);glLoadIdentity;

    glTranslatef(10,240-40,0);
    glScalef(12,12,1);
    selectFontOutline('Arial',[]);

    Self.DrawText(s);
  end;

var TAct,Freq:int64;
    ps:TPaintStruct;
    err:GLenum;
begin
  m.Result:=0;
  QueryPerformanceCounter(TAct);
  QueryPerformanceFrequency(Freq);

  DeltaTime:=Rangerf(0.0000001,int64(TAct-TPrev)/Freq,1);
  TPrev:=TAct;

  BeginPaint(handle,ps);
  try
    Active:=true;
    glViewport(0,0,ClientWidth,ClientHeight);

    if csDesigning in Componentstate then
      glClear(GL_COLOR_BUFFER_BIT);

    if CheckAndSet(started)then if Assigned(BeforeFirstPaint)then
      BeforeFirstPaint(self);

    if Assigned(OnPaint)then
      OnPaint(self)
    else
      DrawText(Name);

    err:=glGetError;
    if err<>0 then
      DrawText('Unhandled error: '+glEnumToStr(err));

    if assigned(wglSwapIntervalEXT)then
      wglSwapIntervalEXT(ord(FVSynch));

    SwapBuffers(FDC);
  finally
    Active:=false;
    EndPaint(handle,ps);
    if Assigned(AfterPaint)then
      AfterPaint(self);
  end;
end;

{procedure TGLViewer.MyIdle(sender: TObject; var done: boolean);
begin
  Invalidate;
  done:=false;
end;}

procedure TGLViewer.SetAutoInvalidate(const Value: boolean);
begin
  FAutoInvalidate:=Value;
{  if csDesigning in ComponentState then exit;

  if Value then Application.OnIdle:=MyIdle //bazmeg ez csak 1-re jo
           else Application.OnIdle:=nil;}
end;

procedure TGLViewer.selectFontOutline(const AName: string; const AStyle: TFontStyles; const APrecision:single=0.005);
var lb,i,j:integer;
begin
  Active:=true;
  with FontCanvas.Font do begin
    if(Style=AStyle)and(cmp(Name,AName)=0)then exit;

    Name:=AName;
    Style:=AStyle;
    Height:=24;
  end;

  j:=-1;for i:=0 to high(fonts)do with fonts[i]do if(style=AStyle)and(CompareText(name,AName)=0)then begin j:=i;break end;
  if j<0 then begin
    lb:=glGenLists(256);
    if not wglUseFontOutlinesA(FontCanvas.Handle, 0,256,lb,APrecision,0,WGL_FONT_POLYGONS,nil)then begin
      //RaiseLastError('selectFontOutline() error');
      GetLastError;
      glDeleteLists(lb,256);
      selectFontOutline('Arial',AStyle);
      exit;  //silent error
    end;

    SetLength(fonts,length(fonts)+1);
    j:=high(fonts);
    fonts[j].name:=AName;
    fonts[j].style:=AStyle;
    fonts[j].listBase:=lb;
  end;

  if selectedFont<>j then begin
    selectedFont:=j;
  end;
end;

procedure TGLViewer.DrawText(const s:ansistring;const alignemt:ansistring='');
var t:TV2f;
begin
  if s='' then exit;
  if not InRange(selectedFont,0,high(fonts))then raise Exception.Create('THetGLViewer.glDrawText() no font was selected');

  with t do case uc(CharN(alignemt,2)) of
    'C':x:=0.5;
    'R':x:=1;
  else x:=0;end;
  with t do case uc(CharN(alignemt,1)) of
    'C':y:=0.5;
    'B':y:=1;
  else y:=0;end;

  if t<>V2f(0,0)then with FontCanvas do begin
    t:=t/-Font.Height;
    with TextExtent(s),t do
      glTranslatef(x*cx,y*cy,0);
  end;

  glListBase(fonts[selectedfont].listBase);
  glCallLists(length(s),GL_UNSIGNED_BYTE,@s[1]);
end;

function TGLViewer.GetPixelDepth(const p: tpoint): single;
begin
  Active:=true;
  glReadPixels(p.x,ClientHeight-p.y,1,1,GL_DEPTH_COMPONENT,GL_FLOAT,@result);
end;

function TGLViewer.ScreenToWorld(const p: TV3F): TV3f;
var mv,pr:TM44d;vp:TV4i;
    x,y,z:double;
begin
  Active:=true;
  glGetDoublev(GL_MODELVIEW_MATRIX,@mv);
  glGetDoublev(GL_PROJECTION_MATRIX,@pr);
  glGetIntegerv(GL_VIEWPORT,@vp);
  gluUnProject(p.x,ClientHeight-p.y,p.z,mv,pr,vp,@x,@y,@z);
  Result:=V3f(x,y,z);
end;

function TGLViewer.ScreenToWorld(const p: tpoint): TV3f;
begin
  result:=ScreenToWorld(v3f(p.x,p.y,GetPixelDepth(p)));
end;

procedure glDrawPlane(const width,height:single);
begin
  glDrawPlane(width,height,1,1);
end;

procedure glDrawPlane(const width,height,tw,th:single);
var x0,y0,x1,y1:single;
begin
  x1:=width*0.5;y1:=height*0.5;
  x0:=-x1;y0:=-y1;
  glBegin(GL_QUADS);
  glNormal3f(0,0,1);
  glTexCoord2f(0,0);  glVertex2f(x0,y0);
  glTexCoord2f(tw,0);  glVertex2f(x1,y0);
  glTexCoord2f(tw,th);  glVertex2f(x1,y1);
  glTexCoord2f(0,th);  glVertex2f(x0,y1);
  glEnd;
end;

procedure glDrawPlane2texcoord(const width,height:single);
begin
  glDrawPlane2texcoord(width,height,1,1);
end;

procedure glDrawPlane2texcoord(const width,height,tw,th:single);
var x0,y0,x1,y1:single;
begin
  x1:=width*0.5;y1:=height*0.5;
  x0:=-x1;y0:=-y1;
  glBegin(GL_QUADS);
  glNormal3f(0,0,1);
  glTexCoord2f(0,0);   glMultiTexCoord2fARB(GL_TEXTURE1_ARB,0,0);     glVertex2f(x0,y0);
  glTexCoord2f(tw,0);  glMultiTexCoord2fARB(GL_TEXTURE1_ARB,tw,0);    glVertex2f(x1,y0);
  glTexCoord2f(tw,th); glMultiTexCoord2fARB(GL_TEXTURE1_ARB,tw,th);   glVertex2f(x1,y1);
  glTexCoord2f(0,th);  glMultiTexCoord2fARB(GL_TEXTURE1_ARB,0,th);    glVertex2f(x0,y1);
  glEnd;
end;

{ TGlViewer.TConsole }

procedure TGlConsole.Write(const s:ansistring);

  procedure ScrollUp;
  var i:integer;
  begin
    move(FScreen[1],FScreen[0],SizeOf(FScreen[0])*high(FScreen));
    for i:=0 to high(FScreen[0])do with FScreen[high(FScreen),i]do begin
      chr:=' ';Clr:=FClr;
    end;
  end;

  procedure LineFeed;
  begin
    inc(FCursorPos.Y);if FCursorPos.Y>high(FScreen)then begin
      FCursorPos.Y:=high(FScreen);
      ScrollUp;
    end;
  end;

var ch:ansichar;
begin
  if s='' then exit;
  FChanged:=true;

  for ch in s do case ch of
    #13:FCursorPos.X:=0;
    #10:LineFeed;
    #8:begin
      if FCursorPos.X<=0 then begin
        if FCursorPos.Y>0 then begin
          FCursorPos.X:=High(FScreen[0]);
          dec(FCursorPos.Y);
        end;
      end else
        dec(FCursorPos.X);

      with FCursorPos do if(x>=0)and(y>=0)and(x<=high(FScreen[0]))and(y<=high(FScreen))then with FScreen[y,x]do begin
        Chr:=' ';Clr:=FClr;
      end;
    end;
  else
    with FCursorPos do if(x>=0)and(y>=0)and(x<=high(FScreen[0]))and(y<=high(FScreen))then with FScreen[y,x]do begin
      Chr:=ch;Clr:=FClr;
    end;
    inc(FCursorPos.X);if FCursorPos.X>high(FScreen[0])then begin
      FCursorPos.X:=0;
      LineFeed;
    end;
  end;
end;

procedure TGlConsole.WriteLn(const s:ansistring='');
begin
  Write(s+#13#10);
end;

function TGlConsole.GetTextColor:byte;
begin
  result:=FClr;
end;

procedure TGlConsole.SetTextColor(const clr:byte);
begin
  FClr:=clr;
end;

procedure TGlConsole.SetCursorPos(const p:TPoint);
begin
  if PointsEqual(p,FCursorPos)then exit;
  FChanged:=true;
  FCursorPos:=p;
end;

procedure TGlConsole.ClrScr;
var x,y:integer;
begin
  for y:=0 to high(FScreen)do for x:=0 to high(FScreen[0])do with FScreen[y,x] do begin
    Chr:=' ';Clr:=FClr;end;
  FCursorPos:=point(0,0);
end;

constructor TGlConsole.Create;
begin
  FClr:=7;
  ClrScr;
  WriteLn('    ****  HET SCRIPT PASCAL V2  ****');
  WriteLn(' 64K SYSTEM   38911 EXPRESSION BYTES FREE');
  WriteLn('READY.');
  Write('>');

{  for i:=0 to 15 do begin
    FClr:=i;
    Write('Clr'+inttohex(i,1));
  end;
  WriteLn;
  for i:=0 to 79 do Write(inttostr(i mod 10));}

end;

procedure TGLViewer.DrawConsole;
var x,y,c:integer;blink:boolean;
begin with Console do begin
  blink:=(trunc(frac(Now)*24*60*60*3)and 1)=0;

  glPushAttrib(GL_VIEWPORT_BIT+GL_CURRENT_BIT+GL_ENABLE_BIT);
  glViewport(0,0,ClientWidth*2 div 3,ClientHeight*2 div 3);

  glMatrixMode(GL_PROJECTION);glLoadIdentity;
  glMatrixMode(GL_MODELVIEW);glLoadIdentity;

  glBlendFunc(GL_CONSTANT_ALPHA,GL_ONE_MINUS_CONSTANT_ALPHA);
  glBlendColor(0,0,0,0.66);
  glColor3f(0,0,0);
  glEnable(GL_BLEND);
  glDrawPlane(2,2);
  glDisable(GL_BLEND);

  glOrtho(0,length(FScreen[0]),0,length(FScreen),-1,1);

  selectFontOutline('Courier New',[fsBold]);
  glColor3f(1,1,1);
  glScalef(1.884,1,1);//fontsize
  gltranslatef(0,high(FScreen)+0.25,0);
  for y:=0 to High(FScreen)do begin
    glPushMatrix;
    for x:=0 to high(FScreen[y])do with FScreen[y,x]do begin
      c:=clVGA[Clr and $f];
      glColor3ub(c shr 16,c shr 8 and $ff,c and $ff);
      DrawText(Chr);

      if blink and(x=FCursorPos.X)and(y=FCursorPos.Y)then begin
        glTranslatef(-1/1.884,-0.1,0);
        DrawText('_');
        glTranslatef(0,0.1,0);
      end;
    end;
    glPopMatrix;
    glTranslatef(0,-1,0);
  end;

  glPopAttrib;
end;end;

function TGLViewer.SnapShot(const r:TRect;const alpha:boolean=false):TBitmap;
var w,h:integer;
begin
  result:=TBitmap.Create;with Result do begin
    if alpha then PixelFormat:=pf32bit
             else PixelFormat:=pf24bit;
    w:=r.Right-r.Left;
    h:=r.Bottom-r.Top;
    if(w<=0)or(h<=0)then exit;
    Width:=w;
    Height:=h;

    glReadPixels(r.Left,ClientHeight-(r.Top+h),w,h,switch(alpha,GL_BGRA,GL_BGR),GL_UNSIGNED_BYTE,ScanLine[Height-1]);
  end;
end;

function TGLViewer.SnapShot(const alpha:boolean=false):TBitmap;
begin
  result:=Snapshot(rect(0,0,ClientWidth,ClientHeight),alpha);
end;

procedure TGLViewer.Win7WindowMaskingBugfix;
  function isOwnerForm(h:HWND):boolean;
  begin result:=(Owner<>nil)and(Owner is TWinControl)and(TWinControl(Owner).Handle=h) end;
var h:HWND;
begin
  if windows.GetVersion and $FF<=5 then exit; //only vista and up

  h:=GetForegroundWindow;
  if not isOwnerForm(_LastForegroundWindowHandle)and isOwnerForm(h)then begin Hide;Show end;
  _LastForegroundWindowHandle:=h;
end;

end.
