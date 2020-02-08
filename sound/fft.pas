unit FFT;
(*============================================================================
    fourierf.c  -  Don Cross <dcross@intersrv.com>

    http://www.intersrv.com/~dcross/fft.html

    Contains definitions for doing Fourier transforms
    and inverse Fourier transforms.

    This module performs operations on arrays of 'float'.

    Revision history:

1998 September 19 [Don Cross]
    Updated coding standards.
    Improved efficiency of trig calculations.
2000 April 17 [HeT]
    translated and optimized to delphi
============================================================================*)

interface
uses snd, het.Utils;

function Do_FFT(InverseTransform:boolean;var RealIn,ImagIn,RealOut,ImagOut:TSnd):boolean;overload;
function Do_FFT(InverseTransform:boolean;var RealIn,ImagIn,RealOut,ImagOut:TSingleArray):boolean;overload;
function FFT_Index_to_frequency (index,NumSamples:integer):single;

implementation

function FFT_Index_to_frequency (index,NumSamples:integer):single;
begin
  if Index <= NumSamples shr 1 then
    result:=Index / NumSamples else
    result:= -(NumSamples-Index) / NumSamples;
end;

function Do_fft(InverseTransform:boolean;var RealIn,ImagIn,RealOut,ImagOut:TSnd):boolean;
  function reversebits(index,numbits:integer):integer;var i:integer;
  begin
    result:=0;
    for i:=0 to NumBits-1 do begin
      result := (result shl 1) or (index and 1);
      index:=index shr 1;
    end;
  end;

var NumBits, i, j, k, n, NumSamples,BlockSize, BlockEnd:integer;    //* Number of bits needed to store indices */
    angle_numerator, tr, ti:single;     //* temp real, temp imaginary */
        delta_angle, sm2, sm1, cm2, cm1, w,denom1:single;
        ar,ai:array[0..2]of single;
    ch:integer;

begin
  result:=false;
  NumSamples:=length(realIn);
  if NumSamples and (NumSamples-1)<>0 then exit;
  angle_numerator:= 2 * PI;if InverseTransform then angle_numerator := -angle_numerator;

  NumBits:=0;while(1 shl NumBits)<NumSamples do
    inc(NumBits);
  //   Do simultaneous data copy and bit-reversal ordering into outputs...

  setlength(imagout,numsamples);
  setlength(realout,numsamples);
  for i:=0 to NumSamples-1 do begin
    j:=ReverseBits( i, NumBits );
    RealOut[j] := RealIn[i];
    ImagOut[j] := ImagIn[i];
  end;

  //**   Do the FFT itself...

  for ch:=0 to 1 do begin
    BlockEnd := 1;
    BlockSize:=2;
    while BlockSize <= NumSamples do begin
      delta_angle := angle_numerator / BlockSize;
      sm2 := sin ( -2 * delta_angle );
      sm1 := sin ( -delta_angle );
      cm2 := cos ( -2 * delta_angle );
      cm1 := cos ( -delta_angle );
      w := 2 * cm1;

      i:=0;while i < NumSamples do begin
        ar[2] := cm2;
        ar[1] := cm1;
        ai[2] := sm2;
        ai[1] := sm1;

        j:=i;n:=0;while n < BlockEnd do begin
          ar[0] := w*ar[1] - ar[2];
          ar[2] := ar[1];
          ar[1] := ar[0];

          ai[0] := w*ai[1] - ai[2];
          ai[2] := ai[1];
          ai[1] := ai[0];

          k := j + BlockEnd;
          tr := ar[0]*RealOut[k][ch] - ai[0]*ImagOut[k][ch];
          ti := ar[0]*ImagOut[k][ch] + ai[0]*RealOut[k][ch];

          RealOut[k][ch] := RealOut[j][ch] - tr;
          ImagOut[k][ch] := ImagOut[j][ch] - ti;

          RealOut[j][ch]:=RealOut[j][ch] + tr;
          ImagOut[j][ch]:=ImagOut[j][ch] + ti;
          j:=j+1;n:=n+1;
        end;
        i:=i + BlockSize;
      end;
      BlockEnd := BlockSize;
      BlockSize :=BlockSize shl 1;
    end;
  end;

  //**   Need to normalize if inverse transform...

  if InverseTransform then begin
    denom1 := 1/NumSamples;
    for i:=0 to NumSamples-1 do for ch:=0 to 1 do begin
      RealOut[i][ch] := RealOut[i][ch] *denom1;
      ImagOut[i][ch] := ImagOut[i][ch] *denom1;
    end;
  end;
  result:=true;
end;


function Do_fft(InverseTransform:boolean;var RealIn,ImagIn,RealOut,ImagOut:TSingleArray):boolean;
  function reversebits(index,numbits:integer):integer;var i:integer;
  begin
    result:=0;
    for i:=0 to NumBits-1 do begin
      result := (result shl 1) or (index and 1);
      index:=index shr 1;
    end;
  end;

var NumBits, i, j, k, n, NumSamples,BlockSize, BlockEnd:integer;    //* Number of bits needed to store indices */
    angle_numerator, tr, ti:single;     //* temp real, temp imaginary */
        delta_angle, sm2, sm1, cm2, cm1, w,denom1:single;
        ar,ai:array[0..2]of single;

begin
  result:=false;
  NumSamples:=length(realIn);
  if NumSamples and (NumSamples-1)<>0 then exit;
  angle_numerator:= 2 * PI;if InverseTransform then angle_numerator := -angle_numerator;

  NumBits:=0;while(1 shl NumBits)<NumSamples do
    inc(NumBits);
  //   Do simultaneous data copy and bit-reversal ordering into outputs...

  setlength(imagout,numsamples);
  setlength(realout,numsamples);
  for i:=0 to NumSamples-1 do begin
    j:=ReverseBits( i, NumBits );
    RealOut[j] := RealIn[i];
    ImagOut[j] := ImagIn[i];
  end;

  //**   Do the FFT itself...

  BlockEnd := 1;
  BlockSize:=2;
  while BlockSize <= NumSamples do begin
    delta_angle := angle_numerator / BlockSize;
    sm2 := sin ( -2 * delta_angle );
    sm1 := sin ( -delta_angle );
    cm2 := cos ( -2 * delta_angle );
    cm1 := cos ( -delta_angle );
    w := 2 * cm1;

    i:=0;while i < NumSamples do begin
      ar[2] := cm2;
      ar[1] := cm1;
      ai[2] := sm2;
      ai[1] := sm1;

      j:=i;n:=0;while n < BlockEnd do begin
        ar[0] := w*ar[1] - ar[2];
        ar[2] := ar[1];
        ar[1] := ar[0];

        ai[0] := w*ai[1] - ai[2];
        ai[2] := ai[1];
        ai[1] := ai[0];

        k := j + BlockEnd;
        tr := ar[0]*RealOut[k] - ai[0]*ImagOut[k];
        ti := ar[0]*ImagOut[k] + ai[0]*RealOut[k];

        RealOut[k] := RealOut[j] - tr;
        ImagOut[k] := ImagOut[j] - ti;

        RealOut[j]:=RealOut[j] + tr;
        ImagOut[j]:=ImagOut[j] + ti;
        j:=j+1;n:=n+1;
      end;
      i:=i + BlockSize;
    end;
    BlockEnd := BlockSize;
    BlockSize :=BlockSize shl 1;
  end;

  //**   Need to normalize if inverse transform...

  if InverseTransform then begin
    denom1 := 1/NumSamples;
    for i:=0 to NumSamples-1 do begin
      RealOut[i] := RealOut[i] *denom1;
      ImagOut[i] := ImagOut[i] *denom1;
    end;
  end;
  result:=true;
end;


end.
