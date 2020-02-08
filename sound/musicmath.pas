unit MusicMath;

interface

uses SysUtils, Windows, het.Utils, Math, classes, graphics;//snd

const
  C4Note=60;
  A4Note=C4Note+9;
  A4Freq=440;
  HalfToneMult=1.0594630943593;

function NoteToFreq(const note:single):single;
function FreqToNote(const freq:single):single;

procedure DecodeNote(const Note:single;out Octave,Key:integer;out Fractional:single);overload;
procedure DecodeNote(const Note:single;out Octave,Key:integer);overload;

function NoteToStr(const Note:single;const up:boolean=true):ansistring;
function NoteOctaveToStr(const Note:single;const up:boolean=true):ansistring;
function StrToNote(const S:ansistring):integer;

type
  TKeyboardRange=record
  private
    FRect:TRect;
    FNoteMin,FNoteMax:integer;
    FNoteToXMul,FNoteToXAdd:single;
    FXToNoteMul,FXToNoteAdd:single;
    FYMid:integer;
  public
    procedure Setup(const ARect:TRect;const ANoteMin,ANoteMax:integer);
    function NoteToX(const ANote:single):integer;
    function XToNote(const X:integer):single;
    procedure NoteToRects(const ANote:integer;out UpperRect,LowerRect:TRect);//lower is 0,0,0,0 on black keys
    function PointToNote(const APoint:TPoint):integer;
    function YToVelocity(const Y:integer):integer;

    procedure Draw(const canvas:TCanvas;const GetVelocity:TFunc<byte,byte>;const pressedColor:TColor=clRed;const CustomBitmap:TBitmap=nil);
  end;

//chords

const
  MinorSecond=1;
  MajorSecond=2;
  MinorThird=3;
  MajorThird=4;
  PerfectFourth=5;     AugmentedFourth=6;   DiminishedFourth=4;
  PerfectFifth=7;      AugmentedFifth=8;    DiminishedFifth=6;
  PerfectSixth=9;      AugmentedSixth=10;   DiminishedSixth=8;
  PerfectSeventh=11;   AugmentedSeventh=12; DiminishedSeventh=10;

type
  TChordWeights=array[0..11]of single;
  TChord=class
    Category:ansistring;
    Names:array of ansistring;
    NoteStr:ansistring;
    Notes:array of record offset:integer;isOptional:boolean end;
    NoteWeights:TChordWeights;
    {0:not in chord;
     0.5:optional;
     1:in chord;
     -1,-0.5:near a note}
    function CalcWeightSum(const AWeights:TChordWeights;const ABase:integer):single;
    procedure SetWeights(const w:TChordWeights);
  end;

var
  Chords:array of TChord;

function FindChord(const AWeights:TChordWeights):ansistring;

type
  TTopChords=array[0..2]of record
    sum:single;
    base,chordIdx:integer;
  end;
var
  TopChordHistory:array[0..100]of TTopChords;

procedure DrawKeyboard(const canvas:TCanvas;const ARect:TRect;const ANoteMin,ANoteMax:integer;const GetVelocity:TFunc<byte,byte>;const pressedColor:TColor=clRed;const CustomBitmap:TBitmap=nil);deprecated;
function KeyOnKeyboard(const APoint:TPoint;const ARect:TRect;const ANoteMin,ANoteMax:integer;out AVelocity:byte):Integer;deprecated;

function KeyToNote(k:word):integer;//FT2 szeruseg

implementation

function KeyToNote(k:word):integer;
const keys:array[0..3,0..12]of byte=(
  ($e2,$5a,$58,$43,$56,$42,$4e,$4d,$bc,$be,$bf,  0,  0),
  (  0,$41,$53,$44,$46,$47,$48,$4a,$4b,$4c,$ba,$de,  0),
  (  0,$51,$57,$45,$52,$54,$59,$55,$49,$4f,$50,$db,$dd),
  ($c0,$31,$32,$33,$34,$35,$36,$37,$38,$39,$30,$bd,$bb));

const ofs:array[0..1,0..12]of shortint=(
  ( -1,  0,  2,  4,  5,  7,  9, 11, 12, 14, 16, 17, 19),
(  0,  0,  1,  3,  0,  6,  8, 10,  0, 13, 15,  0, 18));

var x,y,base:integer;
    white,top:boolean;
begin
  result:=-1;
  if k=0 then exit;

  for y:=0 to high(keys)do for x:=0 to high(keys[y])do if keys[y,x]=k then begin
    white:=y and 1=0;
    top:=y>=2;
    base:=c4Note;if not top then dec(base,12);
    if white then begin
      exit(base+ofs[0,x]);
    end else begin
      if ofs[1,x]<>0 then
        result:=base+ofs[1,x];
      exit;
    end;
  end;
end;

function NoteToFreq(const note:single):single;
begin
  result:=A4Freq*power(HalfToneMult,note-A4Note);
end;

function FreqToNote(const freq:single):single;
begin
  result:=LogN(HalfToneMult,freq*(1/A4Freq))+A4Note;
end;

procedure DecodeNote(const Note:single;out Octave,Key:integer;out Fractional:single);overload;
var iNote:integer;
begin
  iNote:=round(Note);
  Fractional:=Note-iNote;

  octave:=(inote+12*1000)div 12-1000;
  key:=inote-octave*12;

  dec(Octave);
end;

procedure DecodeNote(const Note:single;out Octave,Key:integer);overload;
var dummy:single;
begin
  DecodeNote(Note,Octave,Key,dummy);
end;

const _KeyNames:array[boolean,0..11]of ansistring=(
  ('C','Db','D','Eb','E','F','Gb','G','Ab','A','Bb','B'),
  ('C','C#','D','D#','E','F','F#','G','G#','A','A#','B'));

function NoteToStr(const Note:single;const up:boolean=true):ansistring;
var k,o:integer;
begin
  DecodeNote(Note,o,k);
  result:=_KeyNames[up,k];
  Result:=result+tostr(o);
end;

function NoteOctaveToStr(const Note:single;const up:boolean=true):ansistring;
var k,o:integer;
begin
  DecodeNote(Note,o,k);
  result:=_KeyNames[up,k]+inttostr(o);
end;

function StrToNote(const S:ansistring):integer;
var ch:PAnsiChar;
begin
  result:=-10000;
  if s='' then exit;
  ch:=pointer(s);

  case upcase(ch^) of
    'C':result:=0;
    'D':result:=2;
    'E':result:=4;
    'F':result:=5;
    'G':result:=7;
    'A':result:=9;
    'B':result:=11;
  end;
  if result<0 then exit;

  inc(ch);
  case ch^ of
    '#':inc(result);
    'b','B':dec(result);
  else dec(ch);end;

  inc(ch);
  if ch^ in['0'..'9'] then inc(result,(ord(ch^)-ord('0'))*12+12) else dec(ch);

  inc(ch);
  if ch^<>#0 then
    result:=-10000;
end;

var _GraphicKeyRanges:array[0..11]of record lo,hi:array[0..1]of single end=( //note-hez relative, 12.0 = octave (after premult)
{  (lo:(-1,2.33);        hi:(-1,1)),      //C
  (lo:(0,0);            hi:(1,3.2)),       //C#
  (lo:(2.33,5.76);      hi:(3.2,5.2)),   //D
  (lo:(0,0);            hi:(5.2,7.3)),     //D#
  (lo:(5.76,9.2);       hi:(7.3,9.2)),   //E
  (lo:(9.2,12.6);       hi:(9.2,11.2)),  //F
  (lo:(0,0);            hi:(11.2,13.4)),   //F#
  (lo:(12.6,16);        hi:(13.4,15)),   //G
  (lo:(0,0);            hi:(15,17.2)),     //G#
  (lo:(16,19.5);        hi:(17.2,18.8)), //A
  (lo:(0,0);            hi:(18.8,21)),     //A#
  (lo:(19.5,23);        hi:(21,23)));    //B }

  (lo:(  0, 20);        hi:(  0, 12)), //C
  (lo:(  0,  0);        hi:( 12, 24)),   //C#
  (lo:( 20, 40);        hi:( 24, 36)), //D
  (lo:(  0,  0);        hi:( 36, 48)),   //D#
  (lo:( 40, 60);        hi:( 48, 60)), //E
  (lo:( 60, 80);        hi:( 60, 72)), //F
  (lo:(  0,  0);        hi:( 72, 84)),   //F#
  (lo:( 80,100);        hi:( 84, 94)), //G
  (lo:(  0,  0);        hi:( 94,106)),   //G#
  (lo:(100,120);        hi:(106,116)), //A
  (lo:(  0,  0);        hi:(116,128)),   //A#
  (lo:(120,140);        hi:(128,140)));//B

//!!!! al values are premultiplied to the range 0..12, and shifted to key position

procedure _PremultGraphicKeyRanges;
var p:psingle;
    i,j:integer;
begin
  p:=PSingle(@_GraphicKeyRanges[0]);
  for i:=0 to 11 do for j:=0 to 3 do begin
    p^:=p^*(12/140)-i-0.5{ezt tudnam, minek, ja 0!!!};
    inc(p);
  end;
end;

procedure TKeyboardRange.Setup(const ARect:TRect;const ANoteMin,ANoteMax:integer);

  function getX(note:integer;side:integer{0,1}):single;
  var i:integer;
  begin
    i:=cardinal(note)mod 12;
    with _GraphicKeyRanges[i]do
      result:=note+switch(lo[0]<lo[1], lo[side], hi[side]);
  end;

  function safediv(const a,b:single):single;
  begin
    if b<>0 then result:=a/b else result:=0;
  end;
var nMax,nMin,nWidth:single;
begin
  FRect:=ARect;
  FNoteMin:=ANoteMin;
  FNoteMax:=ANoteMax;

  //Adjust graphic range to actual key positions
  nMin:=GetX(FNoteMin,0);
  nMax:=GetX(FNoteMax,1);
  nWidth:=nMax-nMin;

  FNoteToXMul:=safeDiv(FRect.Right-FRect.Left,nWidth);
  FNoteToXAdd:=FRect.Left-nMin*FNoteToXMul;

  FXToNoteMul:=safediv(nWidth,FRect.Right-FRect.Left);
  FXToNoteAdd:=nMin-FRect.Left*FXToNoteMul;

  FYMid:=trunc(lerp(FRect.Top,FRect.Bottom,0.608));
end;

function TKeyboardRange.NoteToX(const ANote:single):integer;
begin
  result:=round(ANote*FNoteToXMul+FNoteToXAdd);
end;

function TKeyboardRange.XToNote(const X:integer):single;
begin
  result:=X*FXToNoteMul+FXToNoteAdd;
end;

function TKeyboardRange.YToVelocity(const Y:integer):integer;
begin
  result:=EnsureRange(round(Remap(Y,FRect.Top,FYMid,1,127)),1,127);
end;

function Rect(const l,t,r,b:integer):TRect;
begin with result do begin Left:=l;Top:=t;Right:=r;Bottom:=b end;end;

procedure TKeyBoardRange.NoteToRects(const ANote:integer;out UpperRect,LowerRect:TRect);
var octave,key:integer;
begin
  octave:=(ANote+12*1000)div 12-1000;
  key:=ANote-octave*12;

  with _GraphicKeyRanges[key]do begin
    UpperRect:=Rect(NoteToX(ANote+hi[0]),FRect.Top,NoteToX(ANote+hi[1]),FYMid);
    if lo[0]<>0 then
      LowerRect:=Rect(NoteToX(ANote+lo[0]),FYMid,NoteToX(ANote+lo[1]),FRect.Bottom)
    else
      LowerRect:=rect(UpperRect.Left,UpperRect.Left,0,0);
  end;
end;

function TKeyBoardRange.PointToNote(const APoint:TPoint):integer;
const ofs:array[0..2]of integer=(0,-1,+1);
var i,n0,n:integer;
    upper,lower:TRect;
begin
  n0:=round(XToNote(APoint.X));

  for i:=0 to high(ofs)do begin
    n:=n0+ofs[i];
    NoteToRects(n,upper,lower);
    if APoint.Y<FYMid then begin
      if(upper.Left<=APoint.x)and(APoint.X<Upper.Right)then exit(n);
    end else begin
      if(lower.Left<=APoint.x)and(APoint.X<lower.Right)then exit(n);
    end;
  end;

  result:=-1000;//shit happens
end;

procedure TKeyboardRange.Draw(const canvas:TCanvas;const GetVelocity:TFunc<byte,byte>;const pressedColor:TColor=clRed;const CustomBitmap:TBitmap=nil);
//custombitmap: keys in the range A0..C2

  procedure SetBrushColor(n:integer;clr:TColor);
  var v:byte;
  begin
    if Assigned(GetVelocity) then begin
      v:=GetVelocity(n);
      if v>0 then clr:=RGBLerp(clr,PressedColor,Lerp(128,255,v*(1/127)));
    end;
    Canvas.Brush.Color:=clr;
  end;

  function GetNoteRangeBounds(n0,n1:integer):TRect;
  var upper,lower:TRect;
  begin
    result.Top:=FRect.Top; Result.Bottom:=FRect.Bottom;
    NoteToRects(n0,upper,lower); result.Left :=switch(lower.Left<lower.Right,lower.Left ,Upper.Left );
    NoteToRects(n1,upper,lower); result.Right:=switch(lower.Left<lower.Right,lower.Right,Upper.Right);
  end;

  procedure BlendRect(const r:TRect;const clr:TColor;const amount:byte);
  var b:TBitmap;
      bf:_BLENDFUNCTION;
  begin
    b:=TBitmap.Create;
    b.PixelFormat:=pf32bit;
    b.Width:=1;
    b.Height:=1;
    b.Canvas.Pixels[0,0]:=clr;

    bf.BlendOp:=AC_SRC_OVER;
    bf.BlendFlags:=0;
    bf.SourceConstantAlpha:=amount;
    bf.AlphaFormat:=0;

    AlphaBlend(canvas.Handle,r.Left,r.Top,r.Right-r.Left,r.Bottom-r.Top,
               b.Canvas.Handle,0,0,1,1,bf);

    b.Free;
  end;


var n:integer;
    upper,lower:TRect;
    rOct,rOctLeftA,rOctRightC:TRect;
    a,st,en,v:integer;
    autoColor:boolean;
    clr:TColor;

begin with canvas do begin
  SetStretchBltMode(Handle,COLORONCOLOR);

  if CustomBitmap<>nil then begin
    rOct:=rect(CustomBitmap.Width*2 div 10, 0, CustomBitmap.Width*9 div 10, CustomBitmap.Height);

    st:=FNoteMin div 12*12;
    en:=FNoteMax div 12*12;
    if FNoteMin mod 12=9 then begin //leftmost A
      rOctLeftA:=rect(0,0,rOct.Left,rOct.Bottom{what a fucking bug?});
      CopyRect(GetNoteRangeBounds(FNoteMin,FNoteMin+2),CustomBitmap.Canvas,rOctLeftA);
      inc(st,12);
    end;
    if FNoteMax mod 12=0 then begin //rightmost C
      rOctRightC:=rect(rOct.Right,0,CustomBitmap.Width,rOct.Bottom);
      CopyRect(GetNoteRangeBounds(FNoteMax,FNoteMax),CustomBitmap.Canvas,rOctRightC);
      dec(en,12);
    end;

    for n:=st to en do if n mod 12=0 then begin
      CopyRect(GetNoteRangeBounds(n,n+11),CustomBitmap.Canvas,rOct);
    end;

    //highlight presseds
    autoColor:=pressedColor=clNone;
    if Assigned(GetVelocity)then for n:=trunc(FNoteMin)to trunc(FNoteMax)do begin
      v:=GetVelocity(n);

      if v=0 then Continue;

      if autoColor then begin
        if v<=63 then clr:=RGBLerp($40C080,$40C0C0,v shl 2)
                 else clr:=RGBLerp($40C0C0,$4040F0,(v-64) shl 2);
        a:=trunc(Remap(v,0,127,96,204));
      end else begin
        clr:=pressedColor;
        a:=trunc(Remap(v,0,127,64,204));
      end;

      NoteToRects(n,upper,lower);
      BlendRect(upper,clr,a);
      if lower.Left<lower.Right then BlendRect(lower,clr,a);
    end;

  end else begin //no CustomBitmap

    for n:=trunc(FNoteMin)to trunc(FNoteMax)do begin
      NoteToRects(n,upper,lower);
      if lower.Left=lower.Right then begin//black
        setBrushColor(n,clBlack);
        FillRect(upper);
        Pen.Color:=clGray;
        with upper do begin
          moveto(Left,top);
          lineto(Left,Bottom-1);
          LineTo(right-1,Bottom-1);
          LineTo(right-1,top);
        end;
      end else begin
        setBrushColor(n,clWhite);
        FillRect(Upper);
        FillRect(lower);
        pen.Color:=clGray;
        with lower do begin
          moveto(right-1,top);
          lineto(right-1,bottom);
        end;
        if upper.Right=lower.Right then begin
          moveto(upper.Right-1,upper.Top);
          lineto(upper.Right-1,upper.Bottom);
        end;
      end;
    end;

  end;

end;end;


procedure _PrepareChords;

  function chord(const ACat,AName,AAlso,ANoteStr:ansistring):TChord;
  const relativemap:array[1..13]of integer=(
    0,2,4, 5,7,9,11, 12,14,16, 17,19,21);
  var i,k:integer;
      w:single;
      n:TAnsiStringArray;
      s:ansistring;
      isOpt:boolean;
      sum,a:single;
  begin
    result:=TChord.Create;
    setlength(Chords,length(Chords)+1);
    Chords[high(Chords)]:=result;

    with result do begin
      setlength(Names,ListCount(AAlso,',')+1);
      Names[0]:=replacef('R','',AName,[]);
      for i:=0 to High(Names)-1 do
        Names[i+1]:=replacef('<R>','',listitem(AAlso,i,','),[]);
      NoteStr:=ANoteStr;

      //process notestr
      n:=ListSplit(ANoteStr,',');
      for i:=0 to high(n)do begin
        s:=n[i];
        isOpt:=charn(s,1)='(';
        if isOpt then s:=copy(s,2,length(s)-2);

        k:=0;
        while charn(s,1)in['b','#']do begin
          if charn(s,1)='b' then dec(k) else inc(k);
          delete(s,1,1);
        end;

        k:=k+relativemap[strtoint(s)];

        SetLength(Notes,length(Notes)+1);
        with Notes[high(Notes)]do begin
          offset:=k;
          isOptional:=isOpt;
        end;
      end;

      //calculate weights
      for i:=0 to high(NoteWeights)do NoteWeights[i]:=0;
      for i:=0 to high(Notes)do with notes[i]do begin
        if isOptional then w:=0.5 else w:=1;
//        k:=(offset+11)mod 12;if NoteWeights[k]<=0 then NoteWeights[k]:=NoteWeights[k]-0.5*w;
        k:=(offset+12)mod 12;NoteWeights[k]:=NoteWeights[k]+w;
//        k:=(offset+13)mod 12;if NoteWeights[k]<=0 then NoteWeights[k]:=NoteWeights[k]-0.5*w;
      end;
      for i:=0 to high(NoteWeights)do if NoteWeights[i]<=0 then NoteWeights[i]:=-0.5;

      //balance
//      NoteWeights[0]:=NoteWeights[0]+1;
      sum:=0;for a in NoteWeights do sum:=sum+abs(a);
      sum:=1/sum;
      for i:=0 to high(NoteWeights)do NoteWeights[i]:=NoteWeights[i]*sum;
    end;
  end;

const
  pcp_maj:TChordWeights=(1.0, 0.00, 0.05, 0.05, 0.24, 0.15, 0.01, 0.39, 0.02, 0.16, 0.00, 0.02);
  pcp_min:TChordWeights=(1.0, 0.00, 0.05, 0.30, 0.03, 0.14, 0.04, 0.26, 0.25, 0.00, 0.00, 0.02);
  pcp_maj7:TChordWeights= (1.0, 0.00, 0.05, 0.05, 0.24, 0.15, 0.01, 0.39, 0.02, 0.16, 0.46, 0.02);
  pcp_min7:TChordWeights= (1.0, 0.00, 0.05, 0.30, 0.03, 0.14, 0.04, 0.26, 0.25, 0.00, 0.46, 0.02);
  pcp_maj_key:TChordWeights= (1.0, 0.0, 0.6, 0.0, 0.7, 0.6, 0.0, 0.9, 0.0, 0.6, 0.0, 0.6);
  pcp_min_key:TChordWeights= (1.0, 0.0, 0.6, 0.8, 0.0, 0.5, 0.0, 0.9, 0.6, 0.0, 0.7, 0.3);
begin

{  chord('Major','R','','').SetWeights(pcp_maj);
  chord('Minor','Rm','','').SetWeights(pcp_min);
  chord('Major7','R7','','').SetWeights(pcp_maj7);
  chord('Minor7','Rm7','','').SetWeights(pcp_min7);
  exit;}

  chord('Major','R','','1,3,5');
  chord('Minor','Rm','','1,b3,5');
{  chord('Diminished','Rdim','<R>m-5, <R>m(b5), <R>Ø','1,b3,b5');
  chord('Major','R7','<R> Dominant 7','1,3,5,b7');
  chord('Major','Rmaj7','<R>Maj7, <R>M7','1,3,5,7');}
  exit;


//  chord('Major','R Single Tone','','1');
  chord('Major','R','<R> Major, <R>Maj, <R>M','1,3,5');
//  chord('Major','R5','<R> power chord','1,5');
//  chord('Major','R-5','<R>(b5), <R> flattened 5th','1,3,b5');
//  chord('Major','R6','<R>Maj6, <R>M6','1,3,5,6');
//  chord('Major','R6/9','<R>6add9, <R>6(add9), <R>Maj6(add9), <R>M6(add9)','1,3,(5),6,9');
  chord('Major','R7','<R> Dominant 7','1,3,(5),b7');
//  chord('Major','Radd9','<R> added 9','1,3,5,9');
  chord('Major','Rmaj7','<R>Maj7, <R>M7','1,3,5,7');
//  chord('Major','Rmaj7+5','<R>Maj7#5, <R>M7+5','1,3,#5,7');
//  chord('Major','Rmaj9','<R>Maj7(add9), <R>M7(add9)','1,3,(5),7,9');
//  chord('Major','Rmaj11','<R>Maj7(add11), <R>M7(add11)','1,(3),5,7,(9),11');
//  chord('Major','Rmaj13','<R>Maj7(add13), <R>M7(add13)','1,3,(5),7,(9),(11),13');
//  chord('Major','R2','on guitar equivalent to: <R>add9','1,2,3,5');
  chord('Minor','Rm','<R>minor, <R>min, <R>-','1,b3,5');
//  chord('Minor','Rm6','<R>minor6, <R>min6','1,b3,5,6');
//  chord('Minor','Rm6/9','','1,b3,(5),6,9');
//    chord('Minor','Rmmaj7','<R>min/maj7, <R>mM7, <R>m(addM7), <R>m(+7), <R>-(M7)','1,b3,5,7');
//  chord('Minor','Rmmaj9','<R>min/maj9, <R>mM9, <R>m(addM9), <R>m(+9), <R>-(M9)','1,b3,(5),7,9');
//  chord('Minor','Rmadd9','<R>minor(add9), <R>-(add9)','1,b3,(5),9');
  chord('Minor Seventh','Rm7','<R>minor7, <R>min7, <R>-7','1,b3,5,b7');
//  chord('Minor Seventh','Rm9','<R>minor9, <R>min9, <R>-9','1,b3,(5),b7,9');
//  chord('Minor Seventh','Rm11','<R>minor11, <R>min11, <R>-11','1,b3,(5),b7,(9),11');
//  chord('Minor Seventh','Rm13','<R>minor13, <R>min13, <R>-13','1,b3,(5),b7,(9),(11),13');
//  chord('Diminished','Rdim','<R>m-5, <R>m(b5), <R>Ø','1,b3,b5');
//  chord('Diminished','Rdim7','<R>Ø7','1,b3,b5,bb7');
//  chord('Half Diminished','Rm7-5','<R>°7, <R>½dim, <R>½dim7, <R>m(b7), <R>minor7b5','1,b3,b5,b7');
  //  chord('Dominant','R7','<R> dominant seventh, <R>dom','1,3,5,b7');
//  chord('Dominant','R7-9','<R>7b9, <R>7(addb9)','1,3,(5),b7,b9');
//  chord('Dominant','R7+9','<R>7(add#9)','1,3,(5),b7,#9');
//  chord('Dominant','R7-5','<R>7b5','1,3,b5,b7');
//  chord('Dominant','R7+5','<R>7+, <R>7#5','1,3,#5,b7');
//  chord('Dominant','R7/6','<R>7 added 6th','1,3,(5),6,b7');
//  chord('Dominant','R9','<R>7(add9)','1,3,(5),b7,9');
//  chord('Dominant','R9-5','<R>9b5, <R> ninth flattened 5th','1,(3),b5,b7,9');
//  chord('Dominant','R9+5','<R>9#5, <R> ninth augmented 5th','1,(3),#5,b7,9');
//  chord('Dominant','Radd9','<R> added 9th, on guitar also: <R>2','1,3,5,9');
//  chord('Dominant','R9/6','<R>9 added 6th','1,(3),(5),6,b7,9');
//  chord('Dominant','R9+11','<R>9aug11, <R> ninth augmented11th','1,3,(5),b7,9,#11');
//  chord('Dominant','R11','<R>7(add11)','1,(3),5,b7,(9),11');
//  chord('Dominant','R11-9','<R>11(b9), <R>11(flattened9th)','1,(3),(5),b7,b9,11');
//  chord('Dominant','R13','<R>7(add13)','1,(3),5,b7,(9),(11),13');
//  chord('Dominant','R13-9','<R>13b9','1,(3),(5),b7,b9,(11),13');
//  chord('Dominant','R13-9-5','<R>13b9b5','(1),(3),b5,b7,b9,(11),13');
//  chord('Dominant','R13-9+11','<R>13b9#11','(1),(3),(5),b7,b9,#11,13');
//  chord('Dominant','R13+11','<R>13 augmented 11th','1,(3),(5),b7,(9),#11,13');
//  chord('Dominant','R7/13','<R>7/6','1,3,(5),b7,13');
//  chord('Augmented','Raug','<R>+, <R>+5, <R>(#5), <R>augmented','1,3,#5');
    chord('Ambiguous','Rsus2','','1,2,5');
    chord('Ambiguous','Rsus4','<R>sus, <R>(sus4)','1,4,5');
//  chord('Ambiguous','R7sus4','<R>7sus, <R>7sus11','1,4,5,b7');
//  chord('Misc','R-9','<R>b9, <R> flattened 9th','1,3,(5),b7,b9');
//  chord('Misc','R-9+5','<R>b9#5, <R> flattened 9th augmented 5th','1,(3),#5,b7,b9');
//  chord('Misc','R-9+11','<R>b9#11, <R> flattened 9th augmented 11th','1,(3),(5),b7,b9,#11');
//  chord('Misc','R-9-5','<R>b9b5, <R> flattened 9th flattened 5th','1,(3),b5,b7,b9');
//  chord('Misc','R+5','<R>aug5, <R> augmented 5th','1,3,#5');
//  chord('Misc','R+9','<R>aug9, <R> augmented 9th','1,3,(5),b7,#9');
//  chord('Misc','R+11','<R>aug11, <R> augmented 11th','1,(3),(5),b7,9,#11');
end;

procedure _freeChords;
var i:integer;
begin
  for i:=0 to high(Chords)do
    FreeAndNil(Chords[i]);
  setlength(Chords,0);
end;

procedure TChord.SetWeights(const w: TChordWeights);
var i:integer;
begin
  for i:=0 to high(w)do
    NoteWeights[i]:=w[i];
end;

function TChord.CalcWeightSum(const AWeights:TChordWeights;const ABase:integer):single;
var i:integer;
begin
  result:=0;
  for i:=0 to high(AWeights)do
    Result:=Result+AWeights[(i+ABase)mod 12]*NoteWeights[i];
end;

var
  TopChords:TTopChords;

procedure _InsertChordFinderResult(const ASum:single;const ABase,AChordIdx:integer);
  procedure SetIt(n:integer);begin with TopChords[n]do begin sum:=ASum;base:=ABase;chordIdx:=AChordIdx;end;end;
begin
  if ASum<TopChords[2].sum then exit;
  if ASum<TopChords[1].sum then begin
    setit(2);exit;
  end;
  if ASum<TopChords[0].sum then begin
    TopChords[2]:=TopChords[1];setit(1);exit;
  end;
  begin
    TopChords[2]:=TopChords[1];TopChords[1]:=TopChords[0];setit(0);exit;
  end;
end;

function FindChord(const AWeights:TChordWeights):ansistring;
var i,b,c:integer;
begin
  for i:=0 to high(TopChords)do with TopChords[i] do begin
    sum:=-100000000;base:=0;chordIdx:=-1;
  end;

  for c:=0 to high(chords)do for b:=0 to 11 do
    _InsertChordFinderResult(chords[c].CalcWeightSum(AWeights,b),b,c);

  result:='';
  for i:=0 to 2 do with TopChords[i]do begin
    if result<>'' then result:=result+'  ';
    result:=result+NoteToStr(base)+chords[chordIdx].Names[0];
  end;

  for i:=high(topChordHistory)downto 0 do topChordHistory[i]:=topChordHistory[i-1];
  topChordHistory[0]:=topChords;
end;

procedure DrawKeyboard(const canvas:TCanvas;const ARect:TRect;const ANoteMin,ANoteMax:integer;const GetVelocity:TFunc<byte,byte>;const pressedColor:TColor=clRed;const CustomBitmap:TBitmap=nil);
var kr:TKeyboardRange;
begin
  kr.Setup(ARect,ANoteMin,ANoteMax);
  kr.Draw(canvas,GetVelocity,pressedColor,CustomBitmap);
end;

function KeyOnKeyboard(const APoint:TPoint;const ARect:TRect;const ANoteMin,ANoteMax:integer;out AVelocity:byte):Integer;
var kr:TKeyboardRange;
begin
  kr.Setup(ARect,ANoteMin,ANoteMax);
  result:=kr.PointToNote(APoint);
end;

initialization
  _PremultGraphicKeyRanges;
  _PrepareChords;
finalization
  _FreeChords;
end.

