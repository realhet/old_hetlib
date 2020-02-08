{MP3}
unit header;
interface
uses het.utils,FStream;

type e_version=( MPEG2_LSF, MPEG1 );
     e_mode=( stereo, joint_stereo, dual_channel, single_channel );
     e_sample_frequency=( fourtyfour_point_one, fourtyeight, thirtytwo );

type pHeader=^Theader;
     tHeader=object
       OldH:longword;
       realframesize:double;
       h_layer, h_protection_bit, h_bitrate_index,h_padding_bit, h_mode_extension:integer;
       h_version:e_version;
       h_mode	:e_mode;
       h_sample_frequency:e_sample_frequency;
       h_number_of_subbands, h_intensity_stereo_bound:longint;
       h_copyright, h_original,
       initial_sync:boolean;
     {  Crc16		*crc;}
       offset:pinteger;
       checksum:longint;
       framesize,
       nSlots:longint;

       Constructor Init;
       Destructor Done;

       function read_header(var stream:TFileStream):boolean;
       function calculate_framesize:integer;
     end;

implementation

const frequencies:array[0..2-1,0..4-1]of longint=
((22050, 24000, 16000, 1),
(44100, 48000, 32000, 1));

const bitrates:array[0..1,0..2,0..15]of longint=(
((0{freeformat}, 32000, 48000, 56000, 64000, 80000, 96000, 112000, 128000, 144000, 160000, 176000, 192000,224000, 256000, 0),
(0{freeformat}, 8000, 16000, 24000, 32000, 40000, 48000, 56000, 64000, 80000, 96000, 112000, 128000, 144000, 160000, 0),
(0{freeformat}, 8000, 16000, 24000, 32000, 40000, 48000, 56000, 64000, 80000, 96000, 112000, 128000, 144000, 160000, 0)),
((0{freeformat}, 32000, 64000, 96000, 128000, 160000, 192000, 224000, 256000, 288000, 320000, 352000, 384000, 416000, 448000, 0),
(0{freeformat}, 32000, 48000, 56000, 64000, 80000, 96000, 112000, 128000, 160000, 192000, 224000, 256000, 320000, 384000, 0),
(0{freeformat}, 32000, 40000, 48000, 56000, 64000, 80000, 96000, 112000, 128000, 160000, 192000, 224000, 256000, 320000, 0))
);

Constructor THeader.init;
Begin
  OldH:= 0;
  framesize:= 0;
  nSlots:= 0;
  offset:= Nil;
  initial_sync:= false;
End;

Destructor THeader.Done;
Begin
End;

const     SYNC_WORD         =$fff;
          SYNC_WORD_LNGTH   =12;

{         HDRCMPMASK= $fffffddf;}
//          HDRCMPMASK= $fffffddf;
          HDRCMPMASK= $ffff0000;//VDA miatt

Function tHeader.read_header;
(*
  function seek_sync(var bs:TFileStream; sync:longint; N:integer):boolean;
  var maxi,val,aligning:longint;try:integer;
  begin
    seek_sync:=false;
    maxi := 1 shl N - 1;
    aligning := bs.sstell mod 8;
    if (aligning<>0)then
      bs.getbits(8-aligning);
    val := bs.getbits(N);
    try:=0;{if not stream.success then exit;}
    while (((val and maxi) <> sync) and (try<1000))do begin
      val :=val shl 8;
      val :=val or  bs.getbits(8);
      if not stream.success then exit;
      inc(try);
    end;
    seek_sync:= (val and maxi) =sync;
  end;*)

var channel_bitrate:longint;
    hbuf:array[0..3]of byte;
    NewH:integer;try_:integer;
    pos:integer;
Begin
  read_header:=false;
  Pos:=Stream.Pos;
  if oldh=0 then begin
    stream.seek(pos);
    while stream.GetBits(12)<>$FFF do begin
      if not stream.success then exit;
      inc(pos);
      stream.seek(pos);
    end;
    stream.seek(pos);
  end;
  if not stream.blockread(hbuf,4)then exit;
  NewH:=integer(hbuf[0])shl 24 or integer(hbuf[1])shl 16 or integer(hbuf[2])shl 8 or integer(hbuf[3]);
  try_:=$500000;
  if (Oldh<>0)then while(Oldh<>NewH and HDRCMPMask)do begin
    inc(Pos);
    Stream.Seek(Pos);
    if Not Stream.Blockread(hbuf,4)then exit;
    NewH:=integer(hbuf[0])shl 24 or integer(hbuf[1])shl 16 or integer(hbuf[2])shl 8 or integer(hbuf[3]);
    dec(try_);if try_=0 then {errorhalt('try_')}exit;
  end else OldH:=NewH and HDRCMPMASK;
  {if not seek_sync(stream,SYNC_WORD,SYNC_WORD_LNGTH)then exit;}
  Stream.seek(Pos);stream.getBits(12);
  h_version := e_version(stream.get1bit);
  h_layer := 4-stream.getbits(2);
  h_protection_bit := stream.get1bit;
  h_bitrate_index := stream.getbits(4);
  h_sample_frequency := e_sample_frequency(stream.getbits(2));
  h_padding_bit := stream.get1bit;
  {h_extension := }stream.get1bit;
  h_mode := e_mode(stream.getbits(2));
  h_mode_extension := stream.getbits(2);
  h_copyright := boolean(stream.get1bit);
  h_original := boolean(stream.get1bit);
  {h_emphasis := }stream.getbits(2);

  if(ord(h_sample_frequency) =3)or(h_layer<>3)or(h_bitrate_index= 15)or
    (h_bitrate_index=0)then exit;

  if(h_mode= joint_stereo)then
    h_intensity_stereo_bound:=(h_mode_extension shl  2)+ 4
  else
    h_intensity_stereo_bound:= 0;{ should never be used}

{ calculate number of subbands:}
  channel_bitrate:= h_bitrate_index;

  { calculate bitrate per channel:}
  if(h_mode <> single_channel)then
    if(channel_bitrate= 4)then
      channel_bitrate:= 1
    else
      channel_bitrate:=channel_bitrate- 4;

  if((channel_bitrate= 1) OR (channel_bitrate= 2))then
    if(h_sample_frequency= thirtytwo)then
      h_number_of_subbands:= 12
    else
      h_number_of_subbands:= 8
  else
    if((h_sample_frequency= fourtyeight) OR ((channel_bitrate>= 3) AND
    (channel_bitrate<= 5)))then
      h_number_of_subbands:= 27
    else
      h_number_of_subbands:= 30;

  if(h_intensity_stereo_bound > h_number_of_subbands)then
     h_intensity_stereo_bound:= h_number_of_subbands;


  { calculate framesize and nSlots}
  calculate_framesize;

  if(h_protection_bit=0)then stream.getbits(16);

  read_header:=stream.success;
End;

function THeader.calculate_framesize:integer;
{ calculates framesize in bytes excluding header size}
begin
  realframesize:=(144* bitrates[ord(h_version)][h_layer- 1][h_bitrate_index]) /
  frequencies[ord(h_version)][ord(h_sample_frequency)];
  framesize:=trunc(realframesize);
  if(h_version= MPEG2_LSF)then begin
    framesize:= framesize shr  1;
    realframesize:=realframesize*0.5;
  end;
  if(h_padding_bit<>0) then inc(framesize);
  { Layer III slots}
  if(h_version= MPEG1)then Begin
    nSlots:= framesize-switch((h_mode= single_channel) , 17, 32){ side info size}
            -switch(boolean(h_protection_bit), 0, 2){ CRC size}- 4;{ header size}
  End else Begin{ MPEG-2 LSF}
    nSlots:= framesize-switch((h_mode= single_channel) ,  9, 17){ side info size}
            -switch(boolean(h_protection_bit), 0, 2){ CRC size}- 4;{ header size}
  End;
  framesize:=  framesize- 4;{ subtract header size}
  calculate_framesize:=framesize;
End;
end.
