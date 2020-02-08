unit MP3St;interface
uses Het.Utils,FStream,Snd,layer3,synfilt,l3table;

Type PMP3Stream=^TMP3Stream;
     TMP3Stream=Object(TAudioStream)
{       equband:array[0..31]of single;equsum:single;}
       pcm:array[0..32]of TSample;
       sy:array[0..1]of TSynthesisFilter;
       FSt:PFileStream;
       Dec:TLayerIII_Decoder;
       LastGr:Integer;
       GrInOut1d,LastBndInGr:integer;
       halted:boolean;
       {debug}
       decodegrfail,nextgrfail,lastgrfail:integer;

       Constructor Init(var fstream:TFileStream);
       Function Process(var ou{:TSampleArray};siz:integer;var newpos:double):boolean;virtual;
       procedure Update;virtual;
       Destructor done;virtual;
     end;

implementation

Constructor TMP3Stream.Init;
begin
  Halted:=true;
  inherited Init;
  FSt:=@FSTREAM;
  Dec.Init(Fst^);Len:=0;
  sy[0].Reset;sy[1].Reset;
  LastGr:=-2;LastBndInGr:=-2;
  fillchar(Pcm,Sizeof(Pcm),0);
  {EquSum:=0;}SeekPrebuffer:=1152;
end;

Destructor TMP3Stream.Done;
begin
  Dec.Done;
  inherited done;
end;

Function TMP3Stream.Process;

  Function DecodeGr(n:integer):boolean;{gr}
  var frame:integer;
  begin
    DecodeGr:=false;
    case Dec.Max_Gr of
      1:begin frame:=n;grInOut1d:=0 end;
      2:begin frame:=n shr 1;grInOut1d:=n and 1 end;
      else exit;
    end;
    if not Dec.DecodeFrame(Frame)then exit;
    if Not Dec.DecodeGr(grInOut1d)then exit;
    DecodeGr:=true;
  end;

  type tsa=array[0..8191]of tsample;
  var {m,lpf,hpf,}bPitch{,b1Pitch}:single;
    SmpInBnd,SmpFrac,SmpFrac1:single;
    out1,Bandp{,EquBandp}:^SiA;pcmp:^tsa;
    band:array[0..31]of single;
    BndInGr,SmpTrunc:Integer;
    Bnd,Gr:integer;
{    nextBound:integer;}
    i,j,ch,{lpi,hpi,}fch,lch:integer;

  Function RoundUp(s:single):integer;
  var i:integer;
  begin
    i:=trunc(s);if i=s then RoundUp:=i else RoundUp:=i+1;
  end;

var first:boolean;
begin
  first:=true;
  Process:=false;if halted then exit;
  if not Dec.headerdecoded or(apitch<0){or(apitch*siz>=PcmBufSize)}then exit;
{  pos:=pos;}
  dec.which_channels:=both;Dec.SetChannels;
  fch:=Dec.First_Channel;lch:=Dec.Last_Channel;

  pcmp:=addr(pcm);bandp:=addr(Band);{EquBandP:=addr(EquBand);}
  {egysegek:
Smp   =   1 Smp
Bnd   =  32 Smp
Gr    =  18 Bnd = 576 Smp
Fr    =   1 v 2 Gr}
  {feltelelek: SmpPos>=0; aPitch>=0; aPitch<32}
  if APitch<0.01 then bPitch:=0.01 else if aPitch>4 then bPitch:=4 else bPitch:=aPitch;
{  b1Pitch:=1/bPitch;}
  Pos:=Pos-bPitch;if Pos<0 then Pos:=0;
  Bnd     := trunc(Pos)shr 5;
  SmpInBnd:= Pos-Bnd shl 5;
  Gr      := Bnd div 18;
  BndInGr := Bnd mod 18;
  if(gr-LastGr>1)or(Gr-LastGr<0) then begin
    inc(nextgrfail);
    FillChar(Pcm,sizeof(Pcm),0);
    LastBndInGr:=-2;
    Dec.Seek_notify;
    Sy[fch].Reset;if fch<>lch then Sy[lch].Reset;
  end;
  i:=0;
  SmpInBnd:=SmpInBnd+bPitch;
  while i<siz do begin
    if SmpInBnd>=32 then begin
      SmpInBnd:=SmpInBnd-32;
      if BndInGr=17 then begin
        BndInGr:=0;
        Gr:=Gr+1;
        if DecodeGr(Gr)then LastGr:=Gr else
          begin
            LastGr:=-2;
            inc(decodegrfail);
            EOFReached:=true;//idiota LAME footer miatt
          end;
      end else BndInGr:=BndInGr+1;
{takolas}
      if first then if(lastgr<>gr)and(lastGr<>-2)then
        begin
          if DecodeGr(Gr)then LastGr:=Gr else
            begin
              LastGr:=-2;
              inc(decodegrfail);
              EOFReached:=true;//idiota LAME footer miatt
            end;
          first:=false;
        end;
{takolas vege}
      Pcmp^[0]:=Pcmp^[32];
      if(LastGr=Gr)then begin
        LastBndInGr:=BndInGr;
        for ch:=fch to lch do begin
          out1:=addr(Dec.out_1d[ch,GrInOut1d,BndInGr]);
          for j:=0 to 31 do Bandp^[j]:={EquBandp^[j]*}out1^[j*18];
          sy[ch].calculate_pcm_samples(Bandp^,Pcmp^[1,ch]); //<-------------!!!!!!!!!!!!!!!!
        end;
        if lch=fch then begin{mono->stereo (lassu)}
          if lch=0 then sy[1].calculate_pcm_samples(Bandp^,Pcmp^[1,1]);
          if fch=1 then sy[0].calculate_pcm_samples(Bandp^,Pcmp^[1,0]);
        end;
      end else begin
        inc(lastgrfail);
        LastBndInGr:=-2;
        for ch:=fch to lch do
          sy[ch].calculate_pcm_samples(Band0,Pcmp^[1,ch]);  //<-------------!!!!!!!!!!!!!!!!
      end;
    end;
    while (i<siz)do begin
      SmpTrunc:=trunc(SmpInBnd);
      if SmpTrunc>=32 then break;
      SmpFrac:=Frac(SmpInBnd);SmpFrac1:=1-SmpFrac;
      tsa(ou)[i,0]:=pcmp^[SmpTrunc,0]*SmpFrac1+pcmp^[SmpTrunc+1,0]*SmpFrac;
      tsa(ou)[i,1]:=pcmp^[SmpTrunc,1]*SmpFrac1+pcmp^[SmpTrunc+1,1]*SmpFrac;
      SmpInBnd:=SmpInBnd+bPitch;
      i:=i+1;
    end;
  end;
  NewPos:=SmpInBnd+(BndInGr+Gr*18)shl 5;
  Process:=true;
end;

Procedure TMp3Stream.Update;
begin
  if not dec.headerdecoded then begin
    halted:=true;
    dec.Decodeframe(0);
    if dec.headerdecoded then
      len:=dec.numframes*dec.max_gr*576;
    halted:=false;
  end;
end;
end.
