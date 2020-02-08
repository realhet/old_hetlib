unit UHetSlider;

interface

uses
  Windows, Messages, Types, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, DIrectInput, ExtCtrls, ComCtrls, math, zlib;


type
  TSlider=class;

  TOnCustomDrawRuler=procedure(ASlider:TSlider;ACanvas:TCanvas;ARect:TRect)of object;

  TSlider=class(TCustomControl)
  private
    FValue: single;
    FLastValue: single;
    FPValue: PSingle;{ha nil akkor value van hasznalva}
    FMiddleStop: boolean;
    FTickMarksTopLeft: boolean;
    FShowCaption: boolean;
    FTickMarksBottomRight: boolean;
    FShowValue: boolean;
    FTickMarksCount: integer;
    FMax: single;
    FMin: single;
    FValueName: string;
    FCaption: string;
    FMidiCC: integer;
    FKnobColor: integer;
    FEndless: boolean;
    FGroupName: string;
    FOnChange: TNotifyEvent;
    FOnChangeDisabled: boolean;
    FOnCustomDrawRuler: TOnCustomDrawRuler;
    function GetValue: single;
    procedure SetMiddleStop(const Value: boolean);
    procedure SetShowCaption(const Value: boolean);
    procedure SetShowValue(const Value: boolean);
    procedure SetTickMarksBottomRight(const Value: boolean);
    procedure SetTickMarksCount(const Value: integer);
    procedure SetTickMarksTopLeft(const Value: boolean);
    procedure SetValue(const Value: single);
    procedure SetValueSilent(const Value: single);
    procedure SetCaption(const Value: string);
    procedure SetMax(const Value: single);
    procedure SetMin(const Value: single);
    procedure SetValueName(const Value: string);
    procedure SetPValue(const Value: PSingle);
    procedure SetKnobColor(const Value: integer);
    procedure SetEndless(const Value: boolean);
    procedure UpdateValue;
  private
    RLine,RKnob:trect;
    PKnob,PKnobOffset:TPoint;
    KnobSize:integer;
    Orientation:char;
    Moving,justClicked:boolean;
    InternalValueChange:boolean;//eger vagy midi altal, nem kulsoleg, tehat komolyan kell venni. setvalue falsezza'
    FSpeed:single;
    Background:TBitmap;

    procedure PaintBackground;
    function CalcOrientation: char;
    procedure ValueToXY(val: single; var x, y: integer);
    function xytoValue(x, y: integer): single;
    procedure UpdateIfValueChanged;
    procedure InvalidateDisplay;
  public

    constructor Create(AOwner:TComponent);override;
    destructor Destroy;override;
    procedure Paint;override;
    property PValue:PSingle read FPValue write SetPValue;

    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer);override;
  published
    property Visible;
    property Align;
    property BevelWidth;
    property BevelInner;
    property BevelOuter;
    property Anchors;
    property TabStop;
    property TabOrder;
    property Hint;
    property ShowHint;
    property ParentShowHint;
    property Color;
    property ParentColor;
    property Font;
    property ParentFont;

    property Caption:string read FCaption write SetCaption;
    property Min:single read FMin write SetMin stored true;
    property Max:single read FMax write SetMax stored true;
    property Endless:boolean read FEndless write SetEndless default false;
    property TickMarksTopLeft:boolean read FTickMarksTopLeft write SetTickMarksTopLeft default true;
    property TickMarksBottomRight:boolean read FTickMarksBottomRight write SetTickMarksBottomRight default true;
    property TickMarksCount:integer read FTickMarksCount write SetTickMarksCount default 11;
    property MiddleStop:boolean read FMiddleStop write SetMiddleStop default false;
    property ShowCaption:boolean read FShowCaption write SetShowCaption default true;
    property ShowValue:boolean read FShowValue write SetShowValue default false;
    property KnobColor:integer read FKnobColor write SetKnobColor default 2;
    property MidiCC:integer read FMidiCC write FMidiCC default -1;
    property GroupName:string read FGroupName write FGroupName;

    property Value:single read GetValue write SetValue;
    property ValueSilent:single read GetValue write SetValueSilent;
    property ValueName:string read FValueName write SetValueName;

    property OnChange:TNotifyEvent read FOnChange write FOnChange;
    property OnCustomDrawRuler:TOnCustomDrawRuler read FOnCustomDrawRuler write FOnCustomDrawRuler;
  end;

procedure Register;

implementation

const sKnobGfx:RawByteString='ZLIBx'#156#165#148'K/'#3'Q'#20#199'k'#231#19'H'#205't'#140'!'#18#159#192#7#240#168'G'#217'{'#172't(6'#136#5#18'!'#130#4#11#146#182#137'x'#4'!R'#11#143#134'D'#177#169#133#182#17'M%tb'#173#11#177#16#11'['#155#250'OG'#155#14'='#247'N'#227#228#220#197#180+
  'w~9w'#238#239#156#250#142#175'R[&'#234#176'j'#177#202#176#20#172#18#155'='#243'{'#228#231'F'#172#204#143#249#151'''}K'#19#220#196'6l'#254#3'X'#154#25#238'^h/'#247#11#145#208'%;'#203#215'DaS'#236'Y'#236'0c'#0#232#154's'#217#189': '#149#212#158'b1F:'+
  #14'+'#196'='#9#24'TC'#0'>'#222'^'#217#12#249'J'#145'NdaK'#196#161#8#192#139#166#177'Sg'#156#202#168'#'#195#216#241#205#14#174'w'#162'6'#188#141'L'#167#211#198'.'#227#145'J3'#3'q'#30#240#246'=x'#144#191'0'#150#235#176#17#152'OfT_'#215'HAY'#216'v'#228+
  '1'#10'b'#24#209#28'm'#173#12'W9'#142'*6V'#167#205'~'#24#152#214#168#139#253'1'#144#253#15#3#141#247#206#241#160#26#216'\'#252#163'Y'#248'|'#247#238'&'#152#136'\p'#19#219#176'9'#251#30'X('#233#31'~'#131'5~'#172':'#14'$'#232#203'W'#220'/'#160#25#224#147+
  #153#129#146#26'n'#155#228'K'#5#138#176#221#196'g'#0#6'*BH3'#6''''#235'M'#184'u'#204#149#194'f'#192'_'#2#3#6#238#194#25'i'#6#131#171#22#129#201'g'#176#239#211#192'@'#14#227'Q'#220#151#208'$h'#149'"'#235#200#1#228#144#130#155#128'O'#217': '#12#188#131+
  #190'l'#191#9#128#206#136#134#134#31'G'#220#9#21#24#182#223#185#142'5'#3#16#201'x'#248#236'1'#0#12#170#225'*'#142'6'#152':'#27'2'#3'r'#24'TS'#188#223#249'a'#221'u'#194'{'#221#245#160#138'.'#182#226':1'#215'Q'#30#186'X'#31#6'<'#215#233#185#142'S'#186+
  #147'*0\'#215#233#185#174#251#161'y'#156#241#22'+'#142#17#243'4'#159#193#189'[b'#174#255#170#227'='#149#226'f'#161':<'#218'@K'#188#141#235':='#215'a'#215#200#243#168';'#217#199'u'#157#158#235#186#235'O'#1'`'#172#184'N'#207'u'#235#174#19#222''#3',Y`'#10;

procedure Register;
begin
  RegisterComponents('Het',[TSlider]);
end;

procedure swap(var a,b:integer);var c:integer;
begin c:=a;a:=b;b:=c;end;

function switch(q:integer;t,f:integer):integer;
begin if q<>0 then result:=t else result:=f end;

function Range(a,b,c:Integer):Integer;overload;begin {if a>c then swap(a,c);}if b<a then result:=-1 else if b>c then result:=1 else result:=0;end;
function Rangerf(a:Integer;b:Integer;c:Integer):Integer;overload;begin {if a>c then swap(a,c);}case Range(a,b,c)of 0:result:=b;1:begin result:=c;end;else begin result:=a;end;end;end;

function Range(a,b,c:single):Integer;overload;begin {if a>c then swap(a,c);}if b<a then result:=-1 else if b>c then result:=1 else result:=0;end;
function Ranger(a:single;var b:single;c:single):single;overload;begin {if a>c then swap(a,c);}case Range(a,b,c)of 0:result:=0;1:begin result:=c-b;b:=c;end;else begin result:=a-b;b:=a;end;end;end;

function Alpha(a,b:tcolor;HexPercent:integer):tcolor;
var cr,cg,cb:integer;hexpercent1:integer;
begin
  a:=colortorgb(a);b:=colortorgb(b);
  hexpercent1:=256-hexpercent;
  cr:=((a and $ff)*hexpercent1+(b and $ff)*hexpercent)shr 8;
  cg:=(((a shr 8)and $ff)*hexpercent1+((b shr 8)and $ff)*hexpercent)shr 8;
  cb:=(((a shr 16)and $ff)*hexpercent1+((b shr 16)and $ff)*hexpercent)shr 8;
  result:=cr or cg shl 8 or cb shl 16;
end;

function remap(src,srcfrom,srcto,dstfrom,dstto:single):single;
begin
  if srcFrom=srcTo then result:=0
                   else result:=(src-srcfrom)/(srcto-srcfrom);
  result:=result*(dstto-dstfrom)+dstfrom;
end;

function remapI(src,srcfrom,srcto:double;dstfrom,dstto:integer):integer;
begin
  result:=trunc(remap(src,srcfrom,srcto,dstfrom,dstto));
end;

function Rangerf(a:single;b:single;c:single):single;overload;
begin case Range(a,b,c)of 0:result:=b;1:begin result:=c;end;else begin result:=a;end;end;end;

procedure drawStraightRuler(canvas:tcanvas;const r:trect;cnt:integer;topleft:boolean);
var i,c,b,t,j,ja,jj:integer;ori:char;
begin
  dec(cnt);
  if cnt<=0 then exit;
  if r.Bottom-r.top>r.Right-r.Left then ori:='V' else ori:='H';
  canvas.pen.color:=clGray;
  if ori='H'then begin
    c:=(r.Top+r.Bottom) div 2;
    b:=r.top;t:=r.bottom;
    if not topleft then swap(b,t);
    j:=r.Left shl 8;ja:=(r.right-r.left)shl 8 div cnt;
    for i:=0 to cnt do begin
      jj:=j shr 8;
      canvas.MoveTo(jj,b);
      if(i=0)or(i=cnt)then canvas.LineTo(jj,t)
                      else canvas.LineTo(jj,c);
      j:=j+ja;
    end;
  end else if ori='V'then begin
    c:=(r.Left+r.Right) div 2;
    b:=r.Left;t:=r.Right;
    if not Topleft then swap(b,t);
    j:=r.top shl 8;
    ja:=(r.bottom-r.top)shl 8 div cnt;
    for i:=0 to cnt do begin
      jj:=j shr 8;
      canvas.MoveTo(b,jj);
      if(i=0)or(i=cnt)then canvas.LineTo(t,jj)
                      else canvas.LineTo(c,jj);
      j:=j+ja;
    end;
  end;
end;

procedure drawRoundRuler(canvas:tcanvas;const center:tpoint;size,cnt:integer;endless:boolean);
var i:integer;a,size1,size2,co,si:single;
begin
  dec(cnt);
  if cnt<=0 then exit;
  canvas.pen.color:=clGray;
  size1:=size;
  for i:=0 to cnt do begin
    if endless then a:=(2*i/cnt)*pi
               else a:=(-0.25+1.5*i/cnt)*pi;
    co:=-cos(a); si:=-sin(a);
    canvas.moveto(round(center.x+co*size1),round(center.y+si*size1));
    if not endless and((i=0)or(i=cnt))then size2:=size1*1.30
                                      else size2:=size1*1.15;
    canvas.lineto(round(center.x+co*size2),round(center.y+si*size2));
  end;
end;

var bmKnob:array[0..2,false..true,0..7]of tbitmap;

procedure InitKnobs;
var bmBig,bm,bm2,bm3:tbitmap;
    i,k,x,y,c,r,g,b:integer;
    j:boolean;
    stIn,stOut:TMemoryStream;
begin
  bmBig:=TBitmap.Create;

  stIn:=TMemoryStream.Create;
  stIn.Write(sKnobGfx[5],length(sKnobGfx)-4);
  stIn.Seek(0,soFromBeginning);
  stOut:=TMemoryStream.Create;
  ZDecompressStream(stIn,stOut);
  stOut.Seek(0,soFromBeginning);
  bmBig.LoadFromStream(stOut);
  stIn.Free;stOut.Free;

  bm:=TBitmap.Create;bm.PixelFormat:=pf32bit;
  bm.Width:=bmBig.Width;
  bm.Height:=bmBig.Height div 3;
  bm2:=TBitmap.Create;bm2.PixelFormat:=pf32bit;
  for i:=0 to 2 do begin
    bm.Canvas.Draw(0,bm.height*-i,bmbig);
    for j:=false to true do begin
      if j then begin
        bm2.Height:=bm.Width;bm2.Width:=bm.Height;
        for y:=0 to bm.height do for x:=0 to bm.Width do
          bm2.Canvas.Pixels[y,x]:=bm.canvas.pixels[x,y];
      end else
        bm2.Assign(bm);
      for k:=0 to 7 do begin
        bmKnob[i,j,k]:=TBitmap.Create;
        bm3:=bmKnob[i,j,k];
        bm3.PixelFormat:=pf32bit;
        bm3.Width:=bm2.Width;
        bm3.Height:=bm2.Height;
        for y:=0 to bm2.height do for x:=0 to bm2.Width do begin
          c:=bm2.canvas.pixels[x,y];
          r:=c shr 16 and $ff;
          g:=c shr  8 and $ff;
          b:=c shr  0 and $ff;
          r:=(r+b) shr 1;
          bm3.canvas.pixels[x,y]:=rgb(switch(k and 1,g,r),switch(k and 2,g,r),switch(k and 4,g,r));
        end;
      end;
    end;
  end;
  bm.free;
  bm2.Free;
  bmBig.Free;
end;

procedure drawRoundKnob(canvas:tcanvas;const pos:tpoint;size,color:integer);
var bm,tmp:tbitmap;
    x,y,i:integer;
    xx,yy,r2,a,r:single;
    c,c1,c2:cardinal;
    rdst:trect;
    line:PCardinal;
begin
  color:=color and 1 shl 2 or color and 2 or color and 4 shr 2;
  bm:=bmKnob[0,false,rangerf(0,color,7)];
  tmp:=TBitmap.Create;
  tmp.PixelFormat:=pf32bit;
  rdst:=rect(pos.x-size,pos.Y-size,pos.x+size,pos.Y+size);
  tmp.Width:=rdst.Right-rdst.Left;
  tmp.Height:=rdst.Bottom-rdst.Top;
  for y:=0 to tmp.Height-1 do begin
    line:=tmp.ScanLine[y];
    for x:=0 to tmp.Width-1 do begin
      xx:=x-(size-0.5);yy:=y-(size-0.5);
      r:=sqr(xx)+sqr(yy);
      if r=0 then begin
        xx:=0;yy:=0;
      end else begin
        r:=sqrt(r);
        r2:=1/r;
        xx:=xx*r2;
        yy:=yy*r2;
      end;
      a:=(xx*-0.707106781+yy*-0.707106781);
      //if a<0 then a:=0.5+a else a:=0.5+a;
      a:=(a+1)*0.5;
      //a ban a szog {1 vilagos, 0 sotet}
      r:=size-r;
      if r>bm.Width shr 1 then r:=bm.Width shr 1;
      i:=round(r);
      if i<0 then c:=$0 else begin
        c1:=bm.Canvas.Pixels[i,bm.Height shr 1+i div 3];
        c2:=bm.Canvas.Pixels[bm.width-i-1,bm.Height shr 1-i div 3];
        c:=Alpha(c1,c2,trunc((1-a)*255));
      end;

      line^:=c;
      inc(line);
    end;
  end;
  canvas.Brush.Style:=bsClear;
  canvas.BrushCopy(rdst,tmp,rect(0,0,tmp.Width,tmp.Height),0);
  tmp.Free;
end;

procedure FreeKnobs;
var j:boolean;
    i,k:integer;
begin
  for i:=0 to 2 do
    for j:=false to true do
      for k:=0 to 7 do
        freeandnil(bmKnob[i,j,k]);
end;

var
  lpdi:IDirectInput8a=nil;
  m_mouse:IDirectInputDevice8a=nil;

procedure InitDXMouse;
var df:TDIDataFormat;
begin
  DirectInput8Create(GetModuleHandle(nil),DIRECTINPUT_VERSION,IID_IDirectInput8A,lpdi,nil);
  lpdi.CreateDevice(GUID_SysMouse,m_mouse,nil);
  m_mouse.SetCooperativeLevel(Application.handle, DISCL_BACKGROUND or DISCL_NONEXCLUSIVE);
  df:=c_dfDIMouse;
  m_mouse.SetDataFormat(df);
  m_mouse.Acquire;
end;

procedure FreeDXMouse;
begin
  if m_mouse=nil then exit;
  m_mouse.Unacquire;
  m_mouse:=nil;
  lpdi:=nil;
end;

procedure ReadDxMouse(var dx,dy:integer);
var ms:TDIMouseState;
begin
  if m_mouse=nil then InitDXMouse;
  m_mouse.GetDeviceState(sizeof(ms),@ms);
  dx:=ms.lx;dy:=ms.lY;
end;

function DrawKnob(canvas:tcanvas;x,y:integer;vert:boolean;style:integer;color:integer):trect;
var bm:tbitmap;rs,rd:trect;
begin
  bm:=bmKnob[rangerf(0,style,2),vert,rangerf(0,color,7)];
  rs:=rect(0,0,bm.Width,bm.Height);
  rd:=rs;OffsetRect(rd,x-(rs.Right shr 1),y-(rs.Bottom shr 1));
  canvas.Brush.Color:=0;
  canvas.Brush.Style:=bsClear;
  canvas.BrushCopy(rd,bm,rs,0);
  result:=rd;
end;

type
  THetSliderList=class(TList)
  public
    Tick:integer;
    Timer:TTimer;
    procedure OnTimer(sender:TObject);
  end;

procedure THetSliderList.OnTimer(Sender:TObject);
var i:integer;
begin
  inc(Tick);
  for i:=0 to Count-1 do
    TSlider(Items[i]).UpdateValue;
end;

var HetSliders:THetSliderList;


{ THetSlider }

procedure TSlider.UpdateValue;
begin
  if moving then exit;
  if FSpeed<>0 then begin
    Value:=Value+FSpeed;
    if(Value=Max)or(Value=Min)then FSpeed:=0;
  end else
    if PValue<>nil then
      UpdateIfValueChanged;
end;

function TSlider.GetValue: single;
begin
  if FPValue<>nil then result:=FPValue^
                  else result:=FValue;
end;

var FStartValue:single;
    FStartTick:integer;

procedure TSlider.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var d:single;
begin
  inherited;
  FSpeed:=0;
  FStartValue:=Value;
  FStartTick:=HetSliders.Tick;

  JustClicked:=true;
  if Button=mbLeft then begin
    if Orientation='O' then begin
      d:=sqrt(sqr(x-RLine.Left)+sqr(y-RLine.top));
      if d<=KnobSize then begin//porget
        moving:=true;
        PKnobOffset.x:=x;
        PKnobOffset.y:=y;
      end else if d<=KnobSize*2 then begin //arccos
        moving:=true;
        PKnobOffset.x:=-1000;//ez a jel!!!
        MouseMove(Shift,x,y);
      end;
    end else begin
      if PtInRect(RKnob,point(x,y))then begin
        moving:=true;
        PKnobOffset.x:=x-PKnob.x;
        PKnobOffset.y:=y-PKnob.y;
      end else if PtInRect(clientrect,point(x,y))then begin
        moving:=true;
        PKnobOffset.x:=0;
        PKnobOffset.y:=0;
        MouseMove(Shift,x,y);
      end;
    end;
    ReadDxMouse(x,y);
  end;
  JustClicked:=false;
end;

procedure TSlider.MouseMove(Shift: TShiftState; X, Y: Integer);
const ShiftSensitivity=0.01;
var dx,dy,xx,yy:integer;
    p,p2:tpoint;
    freq:single;
    sx,sy,d:single;

begin
  inherited;

  if moving then begin
    ReadDxMouse(dx,dy);
    if orientation='O' then begin
      if PKnobOffset.x=-1000 then begin//arccos/sin
        sx:=x-RLine.Left;
        sy:=y-RLine.top;
        d:=sqr(sx)+sqr(sy);
        if d>0 then begin
          d:=1/sqrt(d);
          sx:=sx*d;sy:=sy*d;
          d:=ArcCos(sx);
          d:=d/(pi*2);
          if sy<0 then d:=1-d;
          if Endless then begin
            d:=d-0.25;
            if d<0 then d:=d+1 else
            if d>1 then d:=d-1;
          end else begin
            d:=d-0.375;
            if d<-0.125 then d:=d+1 else
            if d>0.875 then d:=d-1;
            d:=d*(1/0.75);
            ranger(0,d,1);
          end;

          d:=d*(Max-Min)+Min;
          if Endless then begin
            InternalValueChange:=true;Value:=d;
          end else begin
            if JustClicked or(abs(Value-d)<abs(max-min)*0.5)then
              InternalValueChange:=true;Value:=d;
          end;

        end;
      end else begin//adjust
        if(dx<>0)or(dy<>0)then begin
          freq:=(Max-Min)/120;
          if GetKeyState(VK_SHIFT)<0 then freq:=freq*ShiftSensitivity;
          p:=ClientToScreen(PKnob);

          InternalValueChange:=true;
          Value:=Value-Freq*dy;
          p:=ClientToScreen(PKnobOffset);
          if(Mouse.CursorPos.x<>p.x)or(Mouse.CursorPos.y<>p.y)then
            Mouse.CursorPos:=p;
        end;
      end;
    end else begin
      if GetKeyState(VK_SHIFT)<0 then begin
        if(dx<>0)or(dy<>0)then begin
          freq:=ShiftSensitivity*(Max-Min)/((RLine.Right-RLine.Left)+(RLine.Bottom-RLine.Top));
          p:=ClientToScreen(PKnob);
          if Orientation='H' then begin
            InternalValueChange:=true;
            Value:=Value+Freq*dx;
            ValueToXY(Value,xx,yy);p2:=ClientToScreen(point(xx,yy));
            p:=point(p2.x-PKnobOffset.x,p.y);
          end else begin
            InternalValueChange:=true;
            Value:=Value-Freq*dy;
            ValueToXY(Value,xx,yy);p2:=ClientToScreen(point(xx,yy));
            p:=point(p.x,p2.y+PKnobOffset.y);
          end;
          if(Mouse.CursorPos.x<>p.x)or(Mouse.CursorPos.y<>p.y)then
            Mouse.CursorPos:=p;
        end;
      end else begin
        InternalValueChange:=true;
        Value:=xytoValue(x-PKnobOffset.x,y-PKnobOffset.y);
      end;
    end;
  end;
end;

procedure TSlider.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if button=mbLeft then begin
    moving:=false;
    if GetKeyState(VK_CONTROL)<0 then begin
      if HetSliders.Tick>FStartTick then
        FSpeed:=(Value-FStartValue)/(HetSliders.Tick-FStartTick);
    end;
  end;
end;

function TSlider.CalcOrientation:char;
var a:single;
const treshold=1.5;
begin
  a:=clientwidth/clientheight;
  if a>=treshold   then result:='H'else
  if a<=1/treshold then result:='V'else
                        result:='O';
end;

procedure TSlider.ValueToXY(val:single;var x,y:integer);
begin
  x:=remapI(Val,Min,Max,RLine.left,RLine.right);
  y:=remapI(Val,Min,Max,RLine.Bottom,RLine.Top);
end;

function TSlider.xytoValue(x,y:integer):single;
begin
  if orientation='H' then Result:=remap(x,rline.Left,RLine.Right,Min,Max)else
  if orientation='V' then Result:=remap(y,rline.Bottom,RLine.Top,Min,Max)else result:=0;
end;

const transparentbkgcolor=clFuchsia;

procedure TSlider.PaintBackground;
const knobStyleMap:array[false..true,false..true]of integer=((0,1),(2,0));
var canvas:tcanvas;
var RPath,{RCaption,RValue,}R1,R2:trect;
    RTopLeftRuler,RBottomRightRuler:TRect;
    i:integer;
begin
  Background:=TBitmap.Create;
  Background.PixelFormat:=pf32bit;
  Background.Width:=ClientWidth;
  Background.Height:=ClientHeight;
  Canvas:=Background.Canvas;

  R1:=rect(0,0,clientwidth,clientheight);
  canvas.Brush.Style:=bsSolid;
  canvas.Brush.color:=transparentbkgcolor;
  canvas.FillRect(R1);

  if csDesigning in componentstate then DrawEdge(canvas.Handle,r1,BDR_RAISEDInner,BF_RECT);
  orientation:=CalcOrientation;
  if orientation='O' then begin
    r2:=r1;
    if ShowCaption then
      r2.top:=r2.top+Font.Size;
    if ShowValue then
      r2.Bottom:=r2.Bottom-Font.Size;

    RTopLeftRuler:=R2;
    RPath:=R2;
    RLine.Left:=(r2.Left+r2.Right)div 2;
    RLine.Top:=(r2.Top+r2.Bottom)div 2;
    RLine.BottomRight:=RLine.TopLeft;
    KnobSize:=trunc((R2.Bottom-R2.Top)*0.39);
    drawRoundKnob(canvas,rLine.TopLeft,KnobSize,KnobColor);

    if TickMarksTopLeft or TickMarksBottomRight then
      drawRoundRuler(canvas,rLine.TopLeft,KnobSize+3,TickMarksCount, Endless);

  end else begin
    if orientation='H' then begin
      i:=(R1.Top+R1.Bottom)div 2;
      RLine:=Rect(R1.Left+10,i,R1.Right-10,i);
      RTopLeftRuler:=RLine;
      dec(RTopLeftRuler.Top,3);inc(RTopLeftRuler.Bottom,3);
      RBottomRightRuler:=RTopLeftRuler;
      OffsetRect(RTopLeftRuler,0,-14);
      OffsetRect(RBottomRightRuler,0,14);
    end else begin
      r2:=r1;
      if ShowCaption then
        r2.top:=r2.top+Font.Size;
      if ShowValue then
        r2.Bottom:=r2.Bottom-Font.Size;

      i:=(R2.Left+R2.Right)div 2;
      RLine:=Rect(i,R2.Top+10,i,R2.Bottom-10);
      RTopLeftRuler:=RLine;
      dec(RTopLeftRuler.Left,3);inc(RTopLeftRuler.Right,3);
      RBottomRightRuler:=RTopLeftRuler;
      OffsetRect(RTopLeftRuler,-14,0);
      OffsetRect(RBottomRightRuler,14,0);
    end;
    RPath:=RLine;InflateRect(RPath,2,2);

  if Assigned(OnCustomDrawRuler)then
    OnCustomDrawRuler(self,canvas,rect(RTopLeftRuler.TopLeft,RBottomRightRuler.BottomRight));

    Canvas.DrawFocusRect(RPath);

    DrawEdge(Canvas.Handle,RPath,BDR_SUNKENOUTER or BDR_SUNKENINNER,BF_RECT);
    if TickMarksTopLeft     then DrawStraightRuler(canvas,RTopLeftRuler    ,TickMarksCount,false);
    if TickMarksBottomRight then DrawStraightRuler(canvas,RBottomRightRuler,TickMarksCount,true );

  end;
end;

procedure TSlider.Paint;
const knobStyleMap:array[false..true,false..true]of integer=((0,1),(2,0));
var R1:trect;a,co,si,size1:single;center:tpoint;s:string;
begin
  if assigned(OnCustomDrawRuler) then FreeAndNil(Background);
  
  if(Background=nil)or(Background.Width<>ClientWidth)or(Background.Height<>ClientHeight)then PaintBackground;

  canvas.Brush.Style:=bsClear;
  canvas.BrushCopy(clientrect,BackGround,rect(0,0,background.width,background.height),transparentbkgcolor);

  if ShowCaption and (Caption<>'') then begin
    canvas.Brush.Style:=bsClear;
    canvas.Font.Assign(font);
    r1:=clientrect;
    canvas.TextOut((r1.Left+r1.Right-Canvas.TextWidth(Caption))div 2,0,Caption);
  end;

  if ShowValue then begin
    canvas.Brush.Style:=bsClear;
    canvas.Font.Assign(font);
    r1:=clientrect;
    s:=format('%.3g',[Value]);
    canvas.TextOut((r1.Left+r1.Right-Canvas.TextWidth(s))div 2,r1.Bottom-canvas.Font.size-4,s);
  end;

  if orientation='O' then begin
    canvas.Pen.Color:=rgb((KnobColor shr 0 and 1)*128,(KnobColor shr 1 and 1)*128,(KnobColor shr 2 and 1)*128);

    center:=rline.TopLeft;
    if max<>min then a:=(value-min)/(max-min)
                else a:=0;
    if endless then a:=(2*a-0.5)*pi
               else a:=(-0.25+1.5*a)*pi;
    co:=-cos(a); si:=-sin(a);
    size1:=KnobSize*0.8;
    canvas.Pen.Width:=2;
    canvas.moveto(round(center.x+co*size1),round(center.y+si*size1));
    size1:=KnobSize*0;
    canvas.lineto(round(center.x+co*size1),round(center.y+si*size1));
    canvas.Pen.Width:=1;

  end else begin
    ValueToXY(Value,PKnob.x,PKnob.y);
    RKnob:=DrawKnob(canvas,PKnob.x,PKnob.y,orientation='H',knobStyleMap[TickMarksTopLeft,TickMarksBottomRight],KnobColor);
  end;
end;

procedure TSlider.SetKnobColor(const Value: integer);
begin
  if FKnobColor = Value then exit;
  FKnobColor := Value;
  invalidateDisplay;
end;

procedure TSlider.SetMiddleStop(const Value: boolean);
begin
  if FMiddleStop = Value then exit;
  FMiddleStop := Value;
  InvalidateDisplay;
end;

procedure TSlider.SetPValue(const Value: PSingle);
begin
  if FPValue = Value then exit;
  FPValue := Value;
  UpdateIfValueChanged;
end;

procedure TSlider.SetShowCaption(const Value: boolean);
begin
  if FShowCaption = Value then exit;
  FShowCaption := Value;
  invalidateDisplay;
end;

procedure TSlider.SetShowValue(const Value: boolean);
begin
  if FShowValue = Value then exit;
  FShowValue := Value;
  invalidateDisplay;
end;

procedure TSlider.SetTickMarksBottomRight(const Value: boolean);
begin
  if FTickMarksBottomRight = Value then exit;
  FTickMarksBottomRight := Value;
  invalidateDisplay;
end;

procedure TSlider.SetTickMarksCount(const Value: integer);
begin
  if FTickMarksCount = Value then exit;
  FTickMarksCount := Value;
  invalidateDisplay;
end;

procedure TSlider.SetTickMarksTopLeft(const Value: boolean);
begin
  if FTickMarksTopLeft = Value then exit;
  FTickMarksTopLeft := Value;
  invalidateDisplay;
end;

procedure TSlider.SetEndless(const Value: boolean);
begin
  if FEndless = Value then exit;
  FEndless := Value;
  InvalidateDisplay;
end;

procedure TSlider.SetValue(const Value: single);
var newValue:single;
    mmax,mmin:single;
begin
  if not InternalValueChange and moving then begin
    InternalValueChange:=false;exit end;
  InternalValueChange:=false;

  if max>min then begin mmax:=max;mmin:=min end
             else begin mmax:=min;mmin:=max end;

  if Endless then begin
{    if(Value>=mMin)and(Value<=mMax)then newValue:=Value
    else begin
      a:=mMax-mMin;
      if a<>0 then newValue:=mMin+frac((Value-mMin)/a)*a
              else newValue:=mMin;
    end;}
    newValue:=Value; //no min/max check with endless
  end else
    newValue:=rangerf(mMin,Value,mMax);

  if FPValue<>nil then FPValue^:=newValue
                  else FValue:=newValue;
  UpdateIfValueChanged;
end;

procedure TSlider.SetValueSilent(const Value: single);
begin
  FOnChangeDisabled:=true;
  try
    SetValue(Value);
  finally
    FOnChangeDisabled:=false;
  end;
end;

procedure TSlider.SetCaption(const Value: string);
begin
  if FCaption = Value then exit;
  FCaption := Value;
  invalidate;
end;

procedure TSlider.SetMax(const Value: single);
begin
  if FMax=Value then exit;
  FMax:=Value;
  SetValue(GetValue);
  Invalidate;
end;

procedure TSlider.SetMin(const Value: single);
begin
  if FMin=Value then exit;
  FMin:=Value;
  SetValue(GetValue);
  Invalidate;
end;

procedure TSlider.SetValueName(const Value: string);
begin
  {!!}
  FValueName := Value;
end;

procedure TSlider.UpdateIfValueChanged;
begin
  if Value<>FLastValue then begin
    FLastValue:=Value;
    if Assigned(OnChange)and not FOnChangeDisabled then OnChange(self);
    invalidate;
  end;
end;

constructor TSlider.Create(AOwner: TComponent);
begin
  inherited;
  width:=120;height:=40;
  FTickMarksTopLeft:=true;
  FTickMarksBottomRight:=true;
  FTickMarksCount:=11;
  FKnobColor:=2;
  FMidiCC:=-1;
  FShowCaption:=true;
  DoubleBuffered:=true;

  HetSliders.Add(self);
end;

procedure TSlider.InvalidateDisplay;
begin
  freeAndNil(background);
  invalidate;
end;

destructor TSlider.Destroy;
begin
  HetSliders.Remove(self);
  FreeAndNil(Background);
  inherited;
end;

initialization
  InitKnobs;
  HetSliders:=THetSliderList.Create;
  HetSliders.Timer:=TTimer.Create(nil);
  with TTimer.Create(Application)do begin
    Interval:=20;
    OnTimer:=HetSliders.OnTimer;
  end;
finalization
  freeandnil(HetSliders.Timer);
  freeandnil(HetSliders);
  FreeDXMouse;
  FreeKnobs;
end.
