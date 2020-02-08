Unit Snd;interface uses sysutils, het.utils, math, mmsystem;

CONST VUCONST=140;{vu erteket szorozza szazalek-ra}
      CueTuningTime:integer=44100 div 10;{smp}

Type
  TSample=array[0..1]of Single;
  TSnd=array of TSample;

(*  TMonoSample=single;
  TStereoSample=array[0..1]of TMonoSample;
  TSound=record
    Chn:array[0..1]of array of TMonoSample;

    function GetLength:integer;inline;
    procedure SetLength(const ANewLength:integer);
    function GetChns:integer;inline;
    procedure SetChns(const ANewChns:integer);

    property Length:integer read GetLength write SetLength;
    property Chns:integer read GetChns write SetChns;

    function Clone:TSound;
{   function Sample(const pos:single):single;
    function SampleX86(const pos:single):single;
    procedure Stretch(const NewLength:integer);}

    class operator Negative(const a:TSound):TSound;
    class operator Add(const a:TSound;const b:TMonoSample):TSound;
    class operator Add(const a:TSound;const b:TStereoSample):TSound;
    class operator Add(const a,b:TSound):TSound;
{    class operator Subtract(const a:TMonoSnd;const b:Single):TMonoSnd;
    class operator Subtract(const a,b:TMonoSnd):TMonoSnd;
    class operator Multiply(const a:TMonoSnd;const b:Single):TMonoSnd;
    class operator Multiply(const a,b:TMonoSnd):TMonoSnd;
    class operator Divide(const a:TMonoSnd;const b:Single):TMonoSnd;
    class operator Divide(const a,b:TMonoSnd):TMonoSnd;}
  end;*)

{vol,pan <->Lvol,Rvol}
Function VPLeft(V,P:single):single;
Function VPRight(V,P:single):single;
Function LRVol(L,R:single):single;
Function LRPan(L,R:single):single;

Procedure SndGetVU(var snd:TSnd;var vol:TSample);
Function  SndGetVUMono(var snd:TSnd):single;

Procedure SndGetAbsAvg(var snd:TSnd;var vol:TSample);
Function  SndGetAbsAvgMono(var snd:TSnd):single;

Procedure SndAmplify(var snd:TSnd;vol:TSample);overload;
Procedure SndAmplify(var snd:TSnd;vol:single);overload;
Procedure SndSilence(var snd:TSnd);
Procedure SndHalve(var snd:TSnd);

Procedure SndWriteS16(const snd:TSnd;var dst);
Procedure SndWriteM16(var snd:TSnd;var dst);
Procedure SndWriteS8(var snd:TSnd;var dst);
Procedure SndWriteM8(var snd:TSnd;var dst);
Procedure SndWriteS16U(var snd:TSnd;var dst);
Procedure SndWriteM16U(var snd:TSnd;var dst);
Procedure SndWriteS8U(var snd:TSnd;var dst);
Procedure SndWriteM8U(var snd:TSnd;var dst);
Procedure SndWrite(var snd:TSnd;var dst;chn,bps:integer;signed:boolean);

Procedure SndReadS16(const snd:TSnd;var src);

function updatevu(var vuval:single;var s:tsnd;mu:single):single;
function updatevu2(var vuval:single;var s:tsnd;mu:single):single;

procedure sndAppend(var a:TSnd; const b:TSnd);

Type PAudioStream=^TAudioStream;
     TAudioStream=Object{ez csak prototipus}
       pos,len:double;{sampleban,44khz}
       pitch{log2 0.5=1/2x 0=1x 1=2x 2=4x},pitchadd{step}:single;
       LoopStart,LoopEnd,{}LoopLen{},CuePos:single;
       playing,LoopOn,Cue:boolean;
       apitch:single;
       {fx}
{       equ:array[0..4]of single;
       Gain,lowpass,highpass:single;}{0..1}
       Eof:boolean;
       retrigPos,RetrigLen:integer;{ha pos<>0, akkor loop=loopend-retrigpos..+retriglen}
       SeekPrebuffer:Integer;
       LastPos:double;
       EOFReached:boolean;
       Constructor Init;
       Function Process(var ou;siz:integer;var newpos:double):boolean;virtual;
       Procedure Read(var buf:TSnd;siz:integer);
       Procedure Update;virtual;
       Destructor Done;virtual;
     end;

type
  TSndBuf=record  //deprecated
  type
    TDelayProcessFunct=reference to function(const buf:TSndBuf;const Input:TSample;out Feed:TSample):TSample;
  var
    Buf:TSnd;
    BufPos:integer;
    SampleRate:integer;
    procedure DelayProcess(var Snd:TSnd;const funct:TDelayProcessFunct);
    function GetSmp(const idx:single;const extend:boolean=false):TSample;
    procedure Clear;
    procedure LoadWav(const AData:RawByteString);
  end;

  TDelayBuf=record
    Buf:TArray<single>;
    BufPos:integer;
    procedure PushSmp(const s:single);
    function GetSmp(const idx:single):single;
  end;

  TResonantFilter=record
    //http://www.kvraudio.com/forum/viewtopic.php?t=144625
    //Paul Kellet version of the classic Stilson/Smith "Moog" filter
    q,p,f:single;
    b0,b1,b2,b3,b4:single;
    procedure Setup(frequency,resonance:single);
    function Iter(_in:single):single;
  end;

type
  TConvolution=record
    SegmentSize,FFTSize:integer;
    H,Delay:array of record re,im:TArray<single>;end;
    Ovl,re,im,re2,im2,re3,im3:TArray<single>;
    dp:integer;//delay ptr
    procedure Setup(const ASegmentSize:integer;const AIR:TArray<single>);
    procedure ProcessSegment(const AIn,AOut:PSingle;const ADry,AWet:single);//inplace
    procedure Process(const AIn:TArray<single>;out AOut:TArray<single>;const ADry,AWet:single);
  end;

function LoadSingleArrayWav(const fn:string):TArray<single>;
procedure KillSilence(var a:TArray<single>);

procedure ResampleArray(var a:TArray<single>;newSize:integer);

function ToWav16M(const data:PSingle;const dataLen:integer):rawbytestring;overload;
function ToWav16M(const data:TArray<Single>):rawbytestring;overload;

implementation

uses fft;

function ToWav16M(const data:PSingle;const dataLen:integer):rawbytestring;overload;
type
  THdr=packed record
    riffId,riffLen,riffType:cardinal;
    fmtId,fmtSize:cardinal;fmt:TPCMWaveFormat;
    dataId,dataSize:cardinal;
  end;PHdr=^THdr;

const bufsize=256;
var temp:RawByteString;
    i:integer;
    d:PSingle;
    s:PSmallInt;
begin
  setlength(result,sizeof(THdr));
  with PHdr(result)^ do begin
    riffId:=$46464952;
    riffType:=$45564157;
    fmtId:=$20746D66;
    fmtSize:=SizeOf(TPCMWaveFormat);
    with fmt,wf do begin
      wFormatTag:=WAVE_FORMAT_PCM;
      nChannels:=1;
      nSamplesPerSec:=22050;
      wBitsPerSample:=16;
      nBlockAlign:=(wBitsPerSample shr 3)*wf.nChannels;
      nAvgBytesPerSec:=wf.nSamplesPerSec*nBlockAlign;
    end;
    dataId:=$61746164;
  end;

  d:=data;
  setLength(temp, dataLen*2);
  s:=PSmallInt(temp);
  for i:=0 to dataLen-1 do begin
    s^:=EnsureRange(round(d^*32767), -32768, 32767);
    inc(s); inc(d);
  end;

  result:=result+temp;

  with PHdr(result)^ do begin
    riffLen:=Length(Result)-8;
    dataSize:=Length(Result)-sizeof(THdr);
  end;
end;

function ToWav16M(const data:TArray<Single>):rawbytestring;overload;
begin
  result:=ToWav16M(PSingle(data), length(data));
end;


procedure ResampleArray(var a:TArray<single>;newSize:integer);

  procedure halve;
  var i:integer;
  begin
    for i:=0 to length(a)shr 1-1 do
      a[i]:=(a[i shl 1]+a[i shl 1+1])*0.5;
    SetLength(a,length(a)shr 1);
  end;

var b:TArray<single>;
    pos,step,fr:single;
    i,tr:integer;
begin
  if length(a)=newSize then exit;
  step:=0;//nowarn
  while true do begin
    step:=length(a)/newSize;
    if step<1.75 then break;
    Halve;
    if length(a)=newSize then exit;
  end;

  setlength(b,newSize);
  pos:=0;
  setlength(a,length(a)+1);a[high(a)]:=a[high(a)-1];
  for i:=0 to high(b)do begin
    tr:=trunc(pos);
    fr:=frac(pos);
    b[i]:=lerp(a[tr],a[tr+1],fr);
    pos:=pos+step;
  end;
  a:=b;
end;

(***************************************************/
realtime warped filter
(realtime input is not supported so far)

This project is based on the wfilter.c of WarpTB, a warping toolbox for Matlab
For more details, refer to http://www.acoustics.hut.fi/software/warp/

filename: rtwfilter.cpp
last modified: 4/14/2007 10:19PM

developed by: Shi Yong
Music Technology, McGill University
email: yong.shi2@mail.mcgill.ca


type TDA=array[0..0]of double;
     PDA=^TDA;

( ***************************************************************//
// Alpha -> Sigma mapping   (copied from the same function of WarpTB)
//************************************************************** )
procedure alphas2sigmas(const alp,sigm:PDA;const lam:double;const dim:integer);
var q:integer;
    S,Sp:double;
begin
  sigm[dim]:=lam*alp[dim]/alp[0];
  Sp:=alp[dim]/alp[0];
  S:=0;//nohint
  for q:=dim downto 2 do begin
    S:=alp[q-1]/alp[0]-lam*Sp;
    sigm[q-1]:=lam*S+Sp;
    Sp:=S;
  end;
  sigm[0]:=S;
  sigm[dim+1]:=1-lam*S;
end;

//**************************************************************//
//warped FIR/IIR filter
// (developed based on the same function of WarpTB)
// yn: output
// xn: input
// *Ar: feedforward coefficients
// adim: dimension of feedforward coefficients
// *Br: feedbackward coefficients
// bdim: dimension of feedbackward coefficients
// lam: lambda
// rmem: states memory
//**************************************************************//
function wfilter(const xn:double;
		const Ar:PDA;const adim:integer;
		const Br:PDA;const bdim:integer;
		const lam:double;const rmem:PDA):double;
var
  q, mlen:integer;
  xr, x, ffr, tmpr, Bb:double;
  sigma:array[0..2]of double;//bdim mindig 1
begin
//  sigma=NFArray(bdim+2);

  alphas2sigmas(Br,PDA(@sigma),lam,bdim-1);

  if(adim>=bdim)then mlen:=adim else mlen:=bdim+1;

  Bb:=1/Br[0];

  xr:=xn*Bb;

  //* update feedbackward sum*/
  for q:=0 to bdim-1 do
    xr:=xr-sigma[q]*rmem[q];
  xr:=xr/sigma[bdim];

  x:=xr*Ar[0];
  //* update inner states*/
  for q:=0 to mlen-1 do begin
     tmpr:=rmem[q]+ lam*(rmem[q+1]-xr);
     rmem[q]:=xr;
     xr:=tmpr;
  end;

  //* update feedforward sum*/
  ffr:=0;
  for q:=0 to adim-2 do
    ffr:=ffr+Ar[q+1]*rmem[q+1];

  //* update output*/
  result:=x+ffr;
end;

const
  NIIR=100;
  // feedbackward coefficients (note: the all-poles coefficients are estimated from the body impulse response of my own classical guitar, refer to GtrBodyWarp.m)
  adim = NIIR + 1;
{  aw:array[0..adim-2]of double=(	1.0000,   -0.8081,    0.1190,   -0.0355,    0.5031,   -0.2222,    0.1629,   -0.2028,    0.2640,   -0.1448,    0.3848,   -0.2552,    0.2459,   -0.2112,    0.2960,					-0.1806,   -0.0658,    0.0382,    0.2307,   -0.1123,    0.1143,    0.0052,    0.2291,   -0.1621,    0.0377,   -0.0919,    0.1412,    0.0122,   -0.0184,   -0.1063,					-0.0237,    0.0046 ,    0.0554 ,   -0.2321,   -0.0627,   -0.0643,   -0.1228,   -0.1229,    0.0791 ,   -0.0694,    0.0263 ,   -0.0107,   -0.0697,   -0.0972,   -0.0222,					-0.0234,    0.0770 ,   -0.1175,   -0.0706,   -0.0422,    0.0692 ,   -0.0213,    0.0175 ,   -0.1196,   -0.0184,   -0.0137,    0.0230 ,   -0.1002,   -0.0290,    0.0575 ,					0.1911 ,    0.0004 ,   -0.0507 ,    0.0306 ,    0.0754 ,   -0.0374 ,   -0.0232 ,    0.0684 ,    0.0493 ,    0.0072 ,    0.0460 ,   -0.0447 ,   -0.0838 ,    0.1188 ,    0.0764 ,
					-0.1574 ,   -0.0985 ,    0.0378 ,    0.1380 ,   -0.0088 ,   -0.0760 ,    0.0581 ,    0.0435 ,   -0.0345 ,    0.0184 ,   -0.0272 ,   -0.0464 ,    0.0368 ,    0.0440 ,   -0.0919 ,					0.0009 ,    0.0583 ,   -0.0007 ,   -0.0715 ,   -0.0717 ,    0.0035 ,   -0.0043 ,   -0.0595 ,    0.0167 ,   -0.0129);}
  aw:array[0..adim-2]of double= (1.000000, -0.772871, 0.200817, 0.080918, 0.178927, -0.065639, 0.002258, 0.004542, 0.059645, 0.031110, 0.208813, 0.009050, 0.024450, -0.108872, 0.038756, 0.098909, -0.146418, -0.041520, 0.042065, 0.034685, 0.055011, 0.084795, 0.083593, -0.046975, 0.031350, 0.039558, -0.031068, 0.101853, 0.033556, -0.045485, 0.079454, 0.092039, -0.051499, -0.065264, -0.027083, -0.058003, -0.109065, 0.018331, 0.027721, -0.047446, 0.047852, -0.036161, 0.020110, -0.038712, -0.035768, -0.006707, -0.119622, 0.054214, 0.045043, -0.005919, 0.033076, 0.029750, 0.037372, 0.050647, 0.051790, -0.070015, -0.047518, -0.012475, 0.018389, 0.055704, -0.012832, 0.061482, -0.047826, -0.042307, 0.044605, -0.002763, -0.067544, -0.045583, 0.004126, 0.052529, 0.029752, -0.022692, 0.022723,
  -0.045383, 0.023965, 0.022401, 0.010942, -0.087773, 0.040983, 0.105974, -0.010893, -0.000766, 0.032061, 0.009536, 0.003583, -0.031246, -0.035166, 0.035264, 0.015639, -0.009338, 0.029847, 0.014434, -0.018193, -0.007327, 0.038094, -0.050303, -0.023781, 0.001438, 0.046157, -0.007981 );

  // feedforward coefficients
  bdim = 1;
  bw:array[0..bdim-1]of double = (1.0);
*)

////////////////////////////////////////////////////////////////////////////////

(*
// first set the coefficients based on the kind of filter and its parameters:
// m_fgain = gain in dB
// m_freq = freq of interest
// m_fq = Q
// m_ type is the filter type
amp = float(pow(10.0,(double)m_fgain/40.0));
w = 2.0 * PI * ((double)m_freq/(double)m_SampleRate);
sinw = float(sin(w));
cosw = float(cos(w));
alpha = sinw/(2.0F*m_fq);
beta = float(sqrt(amp)/m_fq);
m_xfmlk1 = fkap = (float) exp(-w);
switch (m_type)
{
case PK: // peak
b0 = 1.0F + (alpha * amp);
b1 = -2.0F * cosw;
b2 = 1.0F - (alpha * amp);
a0 = 1.0F + (alpha / amp);
a1 = 2.0F * cosw;
a2 = -1.0F + (alpha / amp);
break;
case AP1: // single pole allpass
b0 = fkap;
b1 = -1.0F;
b2 = 0.0F;
a0 = 1.0F;
a1 = fkap;
a2 = 0.0F;
break;
case AP2: // two pole allpass
b0 = 1.0F - sinw;
b1 = -2.0F * cosw;
b2 = 1.0F + sinw;
a0 = 1.0F + sinw;
a1 = 2.0F * cosw;
a2 = sinw - 1.0F;
break;
case BP: // bandpass
b0 = alpha;
b1 = 0.0F;
b2 = -alpha;
a0 = 1.0F + alpha;
a1 = 2.0F * cosw;
a2 = alpha - 1.0F;
break;
case LP: // lowpass
b0 = (1.0F - cosw) * 0.5F;
b1 = 1.0F - cosw;
b2 = (1.0F - cosw) * 0.5F;
a0 = 1.0F + alpha;
a1 = 2.0F * cosw;
a2 = alpha - 1.0F;
break;
case HP: // highpass
b0 = (1.0F + cosw) * 0.5F;
b1 = -(cosw + 1.0F);
b2 = (1.0F + cosw) * 0.5F;
a0 = 1.0F + alpha;
a1 = 2.0F * cosw;
a2 = alpha - 1.0F;
break;
case LS: // low shelf
b0 = amp * ((amp+1.0F) - ((amp-1.0F)*cosw) + (beta*sinw));
b1 = 2.0F * amp * ((amp-1.0F) - ((amp+1.0F)*cosw));
b2 = amp * ((amp+1.0F) - ((amp-1.0F)*cosw) - (beta*sinw));
a0 = (amp+1.0F) + ((amp-1.0F)*cosw) + (beta*sinw);
a1 = 2.0F * ((amp-1.0F) + ((amp+1.0F)*cosw));
a2 = -((amp+1.0F) + ((amp-1.0F)*cosw) - (beta*sinw));
break;case HS: // high shelf
b0 = amp * ((amp+1.0F) + ((amp-1.0F)*cosw) + (beta*sinw));
b1 = -2.0F * amp * ((amp-1.0F) + ((amp+1.0F)*cosw));
b2 = amp * ((amp+1.0F) + ((amp-1.0F)*cosw) - (beta*sinw));
a0 = (amp+1.0F) - ((amp-1.0F)*cosw) + (beta*sinw);
a1 = -2.0F * ((amp-1.0F) - ((amp+1.0F)*cosw));
a2 = -((amp+1.0F) - ((amp-1.0F)*cosw) - (beta*sinw));
break;
}
m_fa = m_foverallgain * b0/a0;
m_fb = m_foverallgain * b1/a0;
m_fc = m_foverallgain * b2/a0;
m_fd = a1/a0;
m_fe = a2/a0;
// now the realtime loop:
// fin = input sample
// fout = output sample
for (I = 0; I<buffersize; I++)
{
fin = input_buffer[I];
fout = (m_fa*fin) + (m_fb*m_a1) + (m_fc*m_a2) + (m_fd*m_b1) + (m_fe*m_b2);
m_a2 = m_a1;
m_a1 = r_inr;
m_b2 = m_b1;
m_b1 = fout;
output_buffer[I] = fout;
}
*)


procedure KillSilence(var a:TArray<single>);
var i,j:integer;
begin
  i:=0;while(abs(a[i])<(1/256))and(i<length(a))do inc(i);
  for j:=i to high(a)do a[j-i]:=a[j];
  setlength(a,length(a)-i);
end;

procedure TConvolution.Setup(const ASegmentSize:integer;const AIR:TArray<single>);
var i,j,k:integer;
begin
  if Nearest2NSize(ASegmentSize)<>ASegmentSize then
    raise Exception.Create('TConvolution.SegmentSize must be power of 2');

  SegmentSize:=ASegmentSize;
  FFTSize:=SegmentSize shl 1;

  //make H
  re:=SingleArrayZeroes(FFTSize);
  im:=SingleArrayZeroes(FFTSize);
  SetLength(H,(length(AIR)+ASegmentSize-1)div ASegmentSize);
  k:=0;
  for i:=0 to high(H)do begin
    for j:=0 to SegmentSize-1 do begin
      if k<=high(AIR)then re[j]:=AIR[k]
                     else re[j]:=0;
      inc(k);
    end;
    Do_FFT(false,re,im,H[i].re,H[i].im);
  end;

  //init Delay
  SetLength(Delay,length(H));
  for i:=0 to high(Delay)do with delay[i]do begin
    im:=SingleArrayZeroes(FFTSize);
    re:=SingleArrayZeroes(FFTSize);
  end;

  dp:=0;
  re:=SingleArrayZeroes(FFTSize);
  im:=SingleArrayZeroes(FFTSize);
  re2:=SingleArrayZeroes(FFTSize);
  im2:=SingleArrayZeroes(FFTSize);
  ovl:=SingleArrayZeroes(FFTSize-SegmentSize);
end;

procedure TConvolution.ProcessSegment(const AIn,AOut:PSingle;const ADry,AWet:single);
type tsa=array[0..$FFFFFFF]of single;
var j,k,L:integer;
    pin:^tsa absolute AIn;
    pout:^tsa absolute AOut;
begin
  dec(dp);if dp<0 then dp:=high(delay);

  for j:=0 to SegmentSize-1 do re[j]:=pin[j];  //im=0
  Do_FFT(false,re,im,Delay[dp].re,Delay[dp].im);

  //sum related FFT blocks
  for j:=0 to FFTSize-1 do begin re2[j]:=0;im2[j]:=0;end; //clear accum
  k:=dp;
  for j:=0 to high(h)do begin
    for L:=0 to FFTSize-1 do ComplexMAD(H[j].re[L], H[j].im[L], Delay[k].re[L], Delay[k].im[L], re2[L], im2[L]);
    inc(k);if k>high(delay)then k:=0;
  end;

  //inv FFT
  Do_FFT(true,re2,im2,re3,im3);

  //add to result
  for j:=0          to high(ovl)     do pout[j]:=re3[j]+ovl[j];
  for j:=length(ovl)to SegmentSize-1 do pout[j]:=re3[j];

  //mix
  for j:=0 to SegmentSize-1 do pout[j]:=pin[j]*ADry+ pout[j]*AWet;

  for j:=SegmentSize to FFTSize-1 do ovl[j-SegmentSize]:=re3[j]; //save overlap
end;

procedure TConvolution.Process(const AIn:TArray<single>;out AOut:TArray<single>;const ADry,AWet:single);
type tsa=array[0..$FFFFFFF]of single;
var i,scnt,lastSize:integer;
    tmp:TArray<single>;
    pin,pout:^tsa;
begin
  setlength(AOut,length(AIn));
  if AIn=nil then exit;
  scnt:=(Length(AIn)+SegmentSize-1)div segmentsize;
  lastSize:=Length(AIn)-SegmentSize*(scnt-1);

  pin:=pointer(AIn);
  pout:=pointer(AOut);
  for i:=0 to scnt-1 do begin
    if(i=scnt-1)and(lastSize<SegmentSize)then begin
      tmp:=SingleArrayZeroes(SegmentSize);
      move(pin[0],tmp[0],lastSize*4);
      ProcessSegment(@tmp[0],@tmp[0],ADry,AWet);
      move(tmp[0],pout[0],lastSize*4);
    end else begin
      ProcessSegment(@pin[0],@pout[0],ADry,AWet);
    end;
    pin:=@pin[SegmentSize];
    pout:=@pout[SegmentSize];
  end;
end;

function LoadSingleArrayWav(const fn:string):TArray<single>;
var buf:TSndBuf;
    i:integer;
begin
  buf.LoadWav(TFile(fn).Read(true));
  setlength(result,length(buf.Buf));
  for i:=0 to high(result)do
    result[i]:=buf.Buf[i,0];
end;

procedure TSndBuf.DelayProcess(var Snd:TSnd;const funct:TDelayProcessFunct);
var i:integer;
begin
  if Length(Snd)>Length(Buf) then begin
    setlength(Buf,Length(Snd));
    BufPos:=abs(BufPos) mod length(buf);
  end;
  for i:=0 to high(Snd)do begin
    inc(BufPos);if BufPos>high(Buf)then BufPos:=0;
    Snd[i]:=funct(self,Snd[i],Buf[Bufpos]);
  end;
end;

procedure TSndBuf.Clear;
begin
  BufPos:=0;
  Buf:=nil;
end;

function TSndBuf.GetSmp(const idx:single;const extend:boolean=false):TSample;
var fr:single;tr,tr1,oldlen,i:integer;
begin
  if idx<0 then begin result[0]:=0;result[1]:=0;exit end;

  fr:=frac(idx);
  tr:=round(idx-fr);
  if(tr+1>high(buf))then begin
    if extend  then begin
      oldlen:=length(buf);
      SetLength(buf,tr+1);
      for i:=oldlen to High(buf)do begin buf[i,0]:=0;buf[i,1]:=0;end;
    end else begin
      result[0]:=0;result[1]:=0;exit
    end;
  end;

  tr:=BufPos-tr;
  if tr<0 then tr:=tr+length(buf);
  tr1:=tr-1;if tr1<0 then tr1:=high(buf);
  result[0]:=lerp(Buf[tr,0],Buf[tr1,0],fr);
  result[1]:=lerp(Buf[tr,1],Buf[tr1,1],fr);
end;

procedure TSndBuf.LoadWav(const AData:RawByteString);
  procedure error(s:string);begin raise Exception.Create('TSndBuf.LoadWav() error: '+s)end;
type
  thdr=record
    riff:array[0..3]of ansichar; {RIFF}
    rsize:integer;
    wave:array[0..3]of ansichar; {WAVE}
    fmt:array[0..3]of ansichar;  {fmt }
    fmtSize:integer;         {16}
    format:word;             {1 pcm}
    channels:word;
    samplerate:integer;
    byterate:integer;
    blockalign:word;
    bitspersample:word;
    data:array[0..3]of ansichar; {data}
    datasize:integer;
  case byte of
    0:(shortints:array[0..0]of shortint);
    1:(smallints:array[0..0]of shortint);
  end;
  phdr=^thdr;

var h:PHdr;
    i:integer;
    pdata:pointer;

function get8:single;   begin result:=PShortInt(pdata)^*(1/128);  pInc(pdata);end;
function get16:single;  begin result:=PSmallInt(pdata)^*(1/32768);pInc(pdata,2);end;
function get24:single;  begin result:=sar(PInteger(pdata)^ shl 8,8)*(1/8388608);pInc(pdata,3);end;
function get32:single;  begin result:=PInteger(pdata)^*(1/2147483648);pInc(pdata,4);end;

begin
  if length(AData)<sizeof(thdr)then error('data too small');

  h:=pointer(AData);
  if h.riff<>'RIFF' then error('RIFF expected');
  if h.wave<>'WAVE' then error('WAVE expected');
  if h.fmt <>'fmt ' then error('fmt  expected');
  if h.format<>1    then error('PCM format expected');
  if h.data<>'data' then error('data expected');
  if not(h.bitspersample in[8,16,24,32])then error('unsupported bitspersample '+tostr(h.bitspersample));
  if not(h.channels in[1,2])then error('unsupported number of channels '+tostr(h.channels));

  pdata:=@h^.shortints[0];
  SetLength(Buf,h.datasize div h.channels div (h.bitspersample shr 3));

  case h.bitspersample of
    8:case h.channels of
      1:for i:=0 to high(Buf)do begin Buf[i,0]:=get8;  Buf[i,1]:=buf[i,0] end;
      2:for i:=0 to high(Buf)do begin Buf[i,0]:=get8;  Buf[i,1]:=get8;    end;
    end;
    16:case h.channels of
      1:for i:=0 to high(Buf)do begin Buf[i,0]:=get16; Buf[i,1]:=buf[i,0] end;
      2:for i:=0 to high(Buf)do begin Buf[i,0]:=get16; Buf[i,1]:=get16;   end;
    end;
    24:case h.channels of
      1:for i:=0 to high(Buf)do begin Buf[i,0]:=get24; Buf[i,1]:=buf[i,0] end;
      2:for i:=0 to high(Buf)do begin Buf[i,0]:=get24; Buf[i,1]:=get24;   end;
    end;
    32:case h.channels of
      1:for i:=0 to high(Buf)do begin Buf[i,0]:=get32; Buf[i,1]:=buf[i,0] end;
      2:for i:=0 to high(Buf)do begin Buf[i,0]:=get32; Buf[i,1]:=get32;   end;
    end;
  end;

  SampleRate:=h.samplerate;

end;

procedure TDelayBuf.PushSmp(const s:single);
begin
  inc(BufPos);if BufPos>high(Buf)then BufPos:=0;
  if Buf<>nil then buf[BufPos]:=s;
end;

function TDelayBuf.GetSmp(const idx:single):single;
var fr:single;tr,tr1,oldlen,i:integer;
begin
  if idx<0 then exit(0);

  fr:=frac(idx);
  tr:=round(idx-fr);
  if(tr+1>high(buf))then begin
    if true{extend} then begin
      oldlen:=length(buf);
      SetLength(buf,tr+1);
      for i:=oldlen to High(buf)do buf[i]:=0;
    end else begin
      exit(0);
    end;
  end;

  tr:=BufPos-tr;
  if tr<0 then tr:=tr+length(buf);
  tr1:=tr-1;if tr1<0 then tr1:=high(buf);
  result:=lerp(Buf[tr],Buf[tr1],fr);
end;

procedure TResonantFilter.Setup(frequency: Single; resonance: Single);
begin
  q := 1 - frequency;
  p := frequency + 0.8 * frequency * q;
  f := p + p - 1;
  q := resonance * (1.0 + 0.5 * q * (1.0 - q + 5.6 * q * q));
end;

function TResonantFilter.Iter(_in: Single):single;
var t1,t2:single;
begin
  _in:= _in - q * b4;                    //feedback
  t1 := b1;  b1 := (_in+ b0) * p - b1 * f;
  t2 := b2;  b2 := (b1 + t1) * p - b2 * f;
  t1 := b3;  b3 := (b2 + t2) * p - b3 * f;
             b4 := (b3 + t1) * p - b4 * f;
  b4 := b4 - b4 * b4 * b4 * 0.166667;    //clipping
  b0 := _in;

// Lowpass  output:  b4
// Highpass output:  in - b4;
// Bandpass output:  3.0f * (b3 - b4);
  result:=b4;
end;

  function updatevu(var vuval:single;var s:tsnd;mu:single):single;var vu:tsample;vx:single;
  begin
    SndGetVu(S,vu);
    vx:=({vu[0]+}vu[1]){*0.5}*mu;
    if true{vuval<=vx} then vuval:=vx else vuval:=vuval-0.02;
    result:=vx;
  end;

  function updatevu2(var vuval:single;var s:tsnd;mu:single):single;var vu:tsample;vx:single;
  begin
    SndGetVu(S,vu);
    vx:=({vu[0]+}vu[1]){*0.5}*mu;
    if vuval<=vx then vuval:=vx else vuval:=vuval-0.04;
    result:=vx;
  end;

Procedure SndGetVU(var snd:TSnd;var vol:TSample);
const step=3;var r,l:single;s:^Tsample;i:integer;
begin
  l:=0;r:=0;
  for i:=0 to length(Snd)shr step-1 do begin
    s:=@snd[i shl step];
    {a:=abs(s^[0]);b:=abs(s^[1]);}
    if s^[0]>l then l:=s^[0];
    if s^[1]>r then r:=s^[1];
  end;
  vol[0]:=l;vol[1]:=r;
end;

Procedure SndGetAbsAvg(var snd:TSnd;var vol:TSample);
var r,l,inv:single;s:^Tsample;i:integer;
begin
  l:=0;r:=0;
  for i:=0 to length(Snd)-1 do begin
    s:=@snd[i];
    l:=l+abs(s[0]);
    r:=r+abs(s[1]);
  end;
  inv:=1/length(snd);
  vol[0]:=l*inv;vol[1]:=r*inv;
end;

function SndGetVuMono;var s:tsample;
begin SndGetVu(Snd,s);result:=max(s[0],s[1]);end;

function SndGetAbsAvgMono;var s:tsample;
begin SndGetAbsAvg(Snd,s);result:=(s[0]+s[1])*0.5;end;


Procedure SndAmplify(var snd:TSnd;vol:TSample);var i:integer;l,r:single;
begin
  l:=vol[0];r:=vol[1];
  if(l=0)and(r=0)then SndSilence(Snd)else
  if(l<>1)or(r<>1)then for i:=0 to High(Snd)do
    begin Snd[i,0]:=Snd[i,0]*l;Snd[i,1]:=Snd[i,1]*r;end;
end;

Procedure SndAmplify(var snd:TSnd;vol:single);
var v:TSample;
begin
  v[0]:=vol;v[1]:=vol;
  SndAmplify(snd,v);
end;

Procedure SndSilence(var snd:tsnd);
begin
  if length(snd)>0 then
    fillchar(snd[0],length(snd)*sizeof(TSample),0);
end;
{*********************************** Snd Writerek **********************************}

function Clip2Smallint(s:single):smallint;const mul=32767;begin if s>1 then result:=mul else if s<-1 then result:=-mul else result:=trunc(s*mul);end;
function Clip2Shortint(s:single):shortint;const mul=127;begin if s>1 then result:=mul else if s<-1 then result:=-mul else result:=trunc(s*mul);end;

type a16s=array[0..0,0..1]of smallint;
     a16m=array[0..0,0..0]of smallint;
     a8s=array[0..0,0..1]of shortint;
     a8m=array[0..0,0..0]of shortint;

Procedure SndWriteS16(const snd:TSnd;var dst);var i:integer;begin for i:=0 to high(Snd)do begin
  a16s(Dst)[i,0]:=Clip2SmallInt(Snd[i,0]);
  a16s(Dst)[i,1]:=Clip2SmallInt(Snd[i,1]);end;end;
Procedure SndWriteM16(var snd:TSnd;var dst);var i:integer;begin for i:=0 to high(Snd)do begin
  a16m(Dst)[i,0]:=Clip2SmallInt(Snd[i,0]);end;end;
Procedure SndWriteS8(var snd:TSnd;var dst);var i:integer;begin for i:=0 to high(Snd)do begin
  a8s(Dst)[i,0]:=Clip2ShortInt(Snd[i,0]);
  a8s(Dst)[i,1]:=Clip2ShortInt(Snd[i,1]);end;end;
Procedure SndWriteM8(var snd:TSnd;var dst);var i:integer;begin for i:=0 to high(Snd)do begin
  a8m(Dst)[i,0]:=Clip2ShortInt(Snd[i,0]);end;end;

Procedure SndWriteS16U(var snd:TSnd;var dst);var i:integer;begin for i:=0 to high(Snd)do begin
  a16s(Dst)[i,0]:=word(Clip2SmallInt(Snd[i,0]))xor $8000;
  a16s(Dst)[i,1]:=word(Clip2SmallInt(Snd[i,1]))xor $8000;end;end;
Procedure SndWriteM16U(var snd:TSnd;var dst);var i:integer;begin for i:=0 to high(Snd)do begin
  a16m(Dst)[i,0]:=word(Clip2SmallInt(Snd[i,0]))xor $8000;end;end;
Procedure SndWriteS8U(var snd:TSnd;var dst);var i:integer;begin for i:=0 to high(Snd)do begin
  a8s(Dst)[i,0]:=byte(Clip2ShortInt(Snd[i,0]))xor $80;
  a8s(Dst)[i,1]:=byte(Clip2ShortInt(Snd[i,1]))xor $80;end;end;
Procedure SndWriteM8U(var snd:TSnd;var dst);var i:integer;begin for i:=0 to high(Snd)do begin
  a8m(Dst)[i,0]:=byte(Clip2ShortInt(Snd[i,0]))xor $80;end;end;

Procedure SndHalve;var i:integer;
begin for i:=0 to High(snd)shr 1 do snd[i]:=snd[i shl 1];SetLength(Snd,Length(Snd)shr 1);end;

Procedure SndWrite(var snd:TSnd;var dst;chn,bps:integer;signed:boolean);
begin
  if signed then
    if chn=2 then
      if bps=16 then
        SndWriteS16(snd,dst)
      else
        SndWriteS8(snd,dst)
    else
      if bps=16 then
        SndWriteM16(snd,dst)
      else
        SndWriteM8(snd,dst)
  else
    if chn=2 then
      if bps=16 then
        SndWriteS16U(snd,dst)
      else
        SndWriteS8U(snd,dst)
    else
      if bps=16 then
        SndWriteM16U(snd,dst)
      else
        SndWriteM8U(snd,dst);
end;

Function VPLeft(V,P:single):single;begin if P>0 then VPLeft:=V*(1-P)else VPLeft:=V;end;
Function VPRight(V,P:single):single;begin if P<0 then VPRight:=V*(P-1)else VPRight:=V;end;
Function LRVol(L,R:single):single;begin if L>R then LRVol:=L else LRVol:=R;end;
Function LRPan(L,R:single):single;
begin if L>R then if L=0 then LRPan:=0 else LRPan:=1-R/L else if R=0 then LRPan:=0 else LRPan:=L/R-1;end;


const mulconv16:single=1/32768;
Procedure SndReadS16(const snd:TSnd;var src);var i:integer;begin for i:=0 to high(Snd)do begin
  Snd[i,0]:=a16s(Src)[i,0]*mulConv16;
  Snd[i,1]:=a16s(Src)[i,1]*mulConv16;end;end;

{**************************** AudioStream ***************************}

Constructor TAudioStream.Init;
{var i:integer;}
begin
  pos:=0;Len:=0;Pitch:=0;PitchAdd:=0;playing:=false;
  cuepos:=0;cue:=false;
  loopOn:=false;LoopStart:=0;LoopEnd:=0;
{  for i:=0 to 4 do Equ[i]:=1;Gain:=1;LowPass:=1;HighPass:=0;}
  EOF:=False;retrigpos:=0;retriglen:=0;
  SeekPrebuffer:=0;LastPos:=0;

  EOFReached:=false;//amikor a dekoder mar nem tud tovabb menni
end;

Procedure TAudioStream.Read;
var np,NextPos:double;oldPitch:single;n,exitcnt:integer;po:integer;label l0;
var PreBuf:TSnd;
begin
  setlength(buf,siz);
  if not playing then begin
    if siz>0 then
      SndSilence(buf);
    exit;
  end;
  po:=0;
  exitcnt:=0;
l0:
  if siz<=0 then exit;
  apitch:=power(2,pitch);apitch:=apitch+pitchAdd;
  if LoopOn then begin LoopLen:=LoopEnd-LoopStart;LoopOn:=(LoopLen>0)and(LoopStart>=0);end;

  if Cue then begin
    if(Pos>CuePos+CueTuningTime-CueTuningTime)or(Pos<CuePos-CueTuningTime) then
      Pos:=CuePos-CueTuningTime;
    if Pos<0 then pos:=0;
  end else if loopOn then begin
    while pos>=loopEnd do pos:=pos-(loopLen);
    while pos<loopStart do pos:=pos+(loopLen);
    if(retrigpos<0)and(retriglen>0) then begin
      while pos>=loopEnd+retrigpos+retriglen do pos:=pos-retriglen;
      while pos<loopEnd+retrigpos do pos:=pos+retriglen;
    end;
  end;
  if Pos>len then Pos:=len else if Pos<0 then Pos:=0;

  if(SeekPrebuffer>0)and(abs(lastPos-Pos)>500){and(Pos>SeekPrebuffer)}then begin
    Pos:=Pos-SeekPrebuffer;if pos<0 then pos:=0;NextPos:=Pos+SeekPrebuffer;
    oldPitch:=aPitch;aPitch:=4;
    PreBuf:=nil;
    SetLength(PreBuf,SeekPrebuffer shr 2);
    if Process(PreBuf[0],SeekPrebuffer shr 2,np)then NextPos:=np;
    Pos:=NextPos;aPitch:=oldPitch;
    SetLength(PreBuf,0);
  end;

  NextPos:=Pos+siz*apitch;
  n:=siz;
  if NextPos>=Len then begin
    n:=siz-trunc((NextPos-Len)/apitch)+2;NextPos:=Len;playing:=false end
  else if Cue then begin
    if(NextPos>=CuePos)then begin
      n:=siz-trunc((NextPos-(CuePos+CueTuningTime-CueTuningTime))/apitch)+2;
      NextPos:=CuePos+CueTuningTime-CueTuningTime;
    end
  end else if LoopOn and(NextPos>=LoopEnd)then begin
    n:=siz-trunc((NextPos-LoopEnd)/apitch)+2;NextPos:=LoopEnd end;
  if n>siz+po then n:=siz+po;
  if n<0 then n:=0;

  if n>0 then
    if not Process(Buf[po],n,np) then begin fillchar(Buf[po],n*sizeof(TSample),0)end
                                 else nextpos:=np;
  po:=po+n;
  siz:=siz-n;
  Pos:=NextPos;Eof:=(Pos>=Len)and(Len>0);if EOF then Pos:=Len;

  LastPos:=Pos;
  inc(exitcnt);
  if(siz>0)and(exitcnt<2)then goto l0;
end;

Function TAudioStream.Process;
begin
  result:=false;
end;

Procedure TAudioStream.Update;
begin
end;

Destructor TAudioStream.Done;
begin
end;

////////////////////////////////////////////////////////////////////////////////
//  TMonoSnd                                                                  //
////////////////////////////////////////////////////////////////////////////////
(*

function TMonoSnd.Length:integer;
begin
  result:=system.length(FData);
end;

procedure TMonoSnd.SetLength(const NewLength:integer);
begin
  system.setlength(FData,NewLength);
end;

function TMonoSnd.Clone:TMonoSnd;
begin
  system.Setlength(result.FData,system.length(FData));
  move(FData[0],result.FData[0],system.length(FData)*sizeof(FData[0]));
end;

function TMonoSnd.SampleX86(const pos: single): single;
var tr,tr2:integer;
    fr:single;
begin
  if FData=nil then exit(0);
  tr:=trunc(pos);
  if cardinal(tr)>cardinal(high(FData))then tr:=High(FData);
  fr:=pos-tr;
  tr2:=tr+1;
  if tr2>High(FData) then tr2:=high(FData);
  result:=FData[tr]*(1-fr)+FData[tr2]*fr;
end;

function TMonoSnd.Sample(const pos: single): single;
asm
  //nem baszkódunk a float control worddel, inkabb sse
  db 2eh{hint not taken}               pcmpeqd xmm7,xmm7
  movd xmm0,pos                        psrld xmm7,31     {const 1}
  cvttss2si edx,xmm0{edx: trunc}       mov ecx,[eax]
  cvtsi2ss xmm3,edx                    jecxz @@invalid   {fdata=nil}
  subss xmm0,xmm3   {xmm0: frac}       movd xmm2,[ecx-4]
  movd xmm1,edx     {xmm1: trunc}      pshufd xmm2,xmm2,0
  pshufd xmm1,xmm1,0                   psubd xmm2,xmm7   {xmm2: high}
  psrldq xmm7,12                       paddd xmm1,xmm7
                                       pminud xmm1,xmm2  {xmm1: n+1,n,n,n bound checked offsets}
  //indirect read, lin interp.
  movd eax,xmm1                        psrldq xmm1,4
  movd xmm3,[ecx+eax*4]                movd eax,xmm1
  movd xmm4,[ecx+eax*4]                subss xmm3,xmm4   {s(n+1)-s(n)}
                                       mulss xmm3,xmm0
                                       addss xmm3,xmm4
  //vegul a qrva FPU-ba beleszenvedni a stackbol
  movss [ebp-4],xmm3
  fld dword[ebp-4]
  pop ebp ret 4

@@invalid:
  fldz
end;

procedure TMonoSnd.ResizeDouble;
var l1,l2:integer;
begin
  if FData=nil then exit;
  l1:=Length;

  setlength(
end;

procedure TMonoSnd.Stretch(const NewLength:integer);

{  procedure _double( );
  begin

  end;

  function _lin(}


begin
{  if NewLength=Length*2 then _double else
  if NewLength*2=Length then _halve else
  if NewLength<>Length then begin
    _lin;
  end;}
end;

class operator TMonoSnd.Negative(const a:TMonoSnd):TMonoSnd;
begin
end;

class operator TMonoSnd.Add(const a:TMonoSnd;const b:Single):TMonoSnd;
begin
end;

class operator TMonoSnd.Add(const a,b:TMonoSnd):TMonoSnd;
begin
end;

class operator TMonoSnd.Subtract(const a:TMonoSnd;const b:Single):TMonoSnd;
begin
end;

class operator TMonoSnd.Subtract(const a,b:TMonoSnd):TMonoSnd;
begin
end;

class operator TMonoSnd.Multiply(const a:TMonoSnd;const b:Single):TMonoSnd;
begin
end;

class operator TMonoSnd.Multiply(const a,b:TMonoSnd):TMonoSnd;
begin
end;

class operator TMonoSnd.Divide(const a:TMonoSnd;const b:Single):TMonoSnd;
begin
end;

class operator TMonoSnd.Divide(const a,b:TMonoSnd):TMonoSnd;
begin
end;

var sss:single;
procedure _MonoSndTest;
var m:TMonoSnd;i:integer;
    fl:single;
begin
  //interpolate
  m.SetLength(1000000);
  m.FData[0]:=0;
  m.FData[1]:=1;
  m.FData[2]:=0;
  m.FData[3]:=-1;

  perfStopStart('s');
  for i:=0 to high(m.FData)do sss:=m.Sample(i);
  perfStopStart('x');
  for i:=0 to high(m.FData)do sss:=m.SampleX86(i);
  perfStopStart('s');
  for i:=0 to high(m.FData)do sss:=m.Sample(i);
  raise Exception.Create(perfReport);


  sss:=m.Sample(0.1);
  sss:=m.Sample(0.5);
  sss:=m.Sample(1);
  sss:=m.Sample(1.3);
  sss:=m.Sample(3.5);
end;
*)

////////////////////////////////////////////////////////////////////////////////
//  TSound                                                                    //
////////////////////////////////////////////////////////////////////////////////


procedure sndAppend(var a:TSnd; const b:TSnd);
var i,o:Integer;
begin
  if b=nil then exit;
  o:=length(a);
  setlength(a, o+length(b));
  for i:=0 to high(b)do a[o+i]:=b[i];
end;


begin
//  _MonoSndTest;
end.

