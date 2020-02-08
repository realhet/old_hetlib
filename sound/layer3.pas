unit layer3; //het.utils
interface
uses het.utils,l3table,fstream,bit_res,header,huffman,inv_mdct, synfilt, math;

type TMP3Bands=TArray<TArray<SmallInt>>;

//get the bands out of mp3's
var saveMP3Bands:boolean=false;
var saveMP3Bands_result:TMP3Bands;
//format: scale:shortint =ceil(log2(max));
//  RLECnt: lo:zerocnt, hi:datacnt
//  RLEData: smallint[]*scale

procedure MP3Bands_StartRecording;
function MP3Bands_Finish_GetData:RawByteString;

type
  TMP3WorkArea=record
    out_1d:array[0..1,0..1,0..575]of single;
    prevblck:array[0..1,0..575]of single;
    sy:array[0..1]of TSynthesisFilter;
    procedure reset;
  end;

function MP3Bands_LoadFromData(const data:RawByteString):TMP3Bands;
procedure MP3Bands_Play(var WA:TMP3WorkArea; const data:TArray<smallint>; out grOut:integer);


type e_channels=(both, left, right, downmix );

type txr=array[0..575]of single;
     tout_1d=array[0..1,0..1,0..SBLIMIT*SSLIMIT-1]of single;
     PSingleArray=^txr;

type PLayerIII_Decoder=^TLayerIII_Decoder;TLayerIII_Decoder=object(TBit_Reserve)
       out_1d:tout_1d;{a kimenet}
       numframes:integer;
       first_channel,last_channel,max_gr,channels:integer;
       which_channels:e_channels;dummy:string[2];

       realframesize:double;
       lastframe:longint;
       grdecoded:integer;
       framedecoded,headerdecoded:boolean;

       Constructor Init(var stream0:TFileStream);
       Destructor Done;
       Function DecodeFrame(n:longint):boolean;
       Function DecodeGr(gr:integer):boolean;
       Procedure SetChannels;
       Procedure seek_notify;
      private
       is_1d:array[0..SBLIMIT*SSLIMIT-1]of integer;
       ro:array[0..1,0..SBLIMIT-1,0..SSLIMIT-1]of single;
       prevblck,k:array[0..1,0..SBLIMIT*SSLIMIT-1]of single;
       nonzero:array[0..1]of integer;
       scalefac:array[0..1]of tscalefac;
       si:tsideinfo;

       stream:PFileStream;
       header:THeader;

       frame_start,
       part2_start:word;
       sfreq:integer;
       bytes_to_discard:integer;
       allzero,halted:boolean;

       function get_side_info:boolean;{out_:sideinfo}
       procedure get_scale_factors(ch,gr:integer);{in:sideinfo  out_:scaledata}
       procedure get_LSF_scale_data(ch,gr:integer);{in:sideinfo  out_:scaledata}
       procedure get_LSF_scale_factors(ch,gr:integer);{in:sideinfo  out_:scaledata}
       procedure huffman_decode(ch,gr:integer);{in:scideinfo  out_:is_1d}
       procedure dequantize_sample(var xr;ch, gr:integer);{in:is_1d  out_:ro}
       procedure i_stereo_k_values(is_pos, io_type, i:integer);
       procedure stereo(gr:integer);{in:ro  out_:ro}
       procedure reorder(var xr; ch, gr:integer);{in:ro  out_:out1d}
       procedure antialias(ch,gr:integer);{in/out_:out_1d}
       procedure hybrid(ch,gr:integer);{in/out_:out_1d}
       procedure do_downmix;

       procedure doSaveBands(ch, gr, mixed, blockType:integer);
     end;

implementation

Constructor TLayerIII_Decoder.init;
Begin
  halted:=true;
  stream:= @stream0;
  header.Init;

  lastframe:=-1;realframesize:=0;numframes:=0;max_gr:=0;channels:=0;
  which_channels:= both;

  frame_start:= 0;
  headerdecoded:=false;
  framedecoded:=false;

  nonzero[0]:= 0;nonzero[1]:= 0;
  allzero:=false;
  fillchar(prevblck,sizeof(prevblck),0);
  fillchar(is_1d,sizeof(is_1d),0);
  fillchar(out_1d,sizeof(out_1d),0);
  fillchar(ro,sizeof(ro),0);

  TBit_Reserve.Init;
  halted:=false;
End;

Destructor TLayerIII_Decoder.Done;
Begin
  halted:=true;
  TBit_Reserve.done;
  Header.Done;
End;

Procedure TLayerIII_Decoder.seek_notify;
Begin
   if allzero then exit;
   halted:=true;
   frame_start:= 0;
   fillchar(prevblck,sizeof(prevblck),0);
   TBit_Reserve.Reset;
   allzero:=true;
   halted:=false;
End;


function TLayerIII_Decoder.get_side_info;
{ Reads the side info from the stream, assuming the entire}
{ frame has been read already.}
{ Mono: 136 bits(= 17 bytes)}
{ Stereo: 256 bits(= 32 bytes)}
var ch, gr:integer;
Begin with stream^ do begin
  if(header.h_version= MPEG1)then Begin
    si.main_data_begin:= getbits(9);
    if(channels= 1)then
      si.private_bits:= getbits(5)
    else
      si.private_bits:= getbits(3);

    for ch:=0 to channels-1 do for gr:=0 to 3 do
      si.ch[ch].scfsi[gr]:= get1bit;

    for gr:=0 to 1 do for ch:=0 to channels-1 do with si.ch[ch].gr[gr] do Begin
      part2_3_length:=        getbits(12);
      big_values:=            getbits(9);
      global_gain:=           getbits(8);
      scalefac_compress:=     getbits(4);
      window_switching_flag:= get1bit;
      if(window_switching_flag)<>0then Begin
        block_type:=       getbits(2);
        mixed_block_flag:= get1bit;
        table_select[0]:=  getbits(5);
        table_select[1]:=  getbits(5);
        subblock_gain[0]:= getbits(3)shl 2;
        subblock_gain[1]:= getbits(3)shl 2;
        subblock_gain[2]:= getbits(3)shl 2;
        if(block_type= 0)then Begin
          get_side_info:=false;exit;
        End else if(block_type= 2)AND(mixed_block_flag= 0)then
          region0_count:= 8
        else
          region0_count:= 7;

        region1_count:= 20-region0_count;
      End else Begin
        table_select[0]:= getbits(5);
        table_select[1]:= getbits(5);
        table_select[2]:= getbits(5);
        region0_count:=   getbits(4);
        region1_count:=   getbits(3);
        block_type:= 0;
      End;

      preflag:=            get1bit;
      scalefac_scale:=     get1bit;
      count1table_select:= get1bit;
    End;
  End else Begin{ MPEG-2 LSF}
    si.main_data_begin:= getbits(8);
    if(channels= 1)then
      si.private_bits:= get1bit
    else
      si.private_bits:= getbits(2);

    for ch:=0 to channels-1 do with si.ch[ch].gr[0]do Begin
      part2_3_length:=        getbits(12);
      big_values:=            getbits(9);
      global_gain:=           getbits(8);
      scalefac_compress:=     getbits(9);
      window_switching_flag:= get1bit;

      if(window_switching_flag)<>0then Begin
        block_type:=       getbits(2);
        mixed_block_flag:= get1bit;
        table_select[0]:=  getbits(5);
        table_select[1]:=  getbits(5);
        subblock_gain[0]:= getbits(3)shl 2;
        subblock_gain[1]:= getbits(3)shl 2;
        subblock_gain[2]:= getbits(3)shl 2;

        if(block_type= 0)then Begin
          { Side info bad: block_type== 0 in split block}
          get_side_info:=false;exit;
        End else if(block_type= 2)AND(mixed_block_flag= 0)then Begin
          region0_count:= 8;
        End else Begin
          region0_count:= 7;
          region1_count:= 20-region0_count;
        End
      End else Begin
        table_select[0]:= getbits(5);
        table_select[1]:= getbits(5);
        table_select[2]:= getbits(5);
        region0_count:=   getbits(4);
        region1_count:=   getbits(3);
        block_type:= 0;
      End;
      scalefac_scale:=     get1bit;
      count1table_select:= get1bit;
    End
  End;{MPEG1)}
  get_side_info:=true;
End;end;

{const sfbtable:record l:array[0..4]of integer;s:array[0..2]of integer;end=(l:(0, 6, 11, 16, 21);s:(0, 6, 12));}

procedure TLayerIII_Decoder.get_scale_factors;
var sfb,window,i,scale_comp,length0,length1:integer;
    gr_info:^tgrinfo;
    sch:^tscalefac;
Begin
  sch:=@(scalefac[ch]);
  gr_info:= addr(si.ch[ch].gr[gr]);
  scale_comp:= gr_info^.scalefac_compress;
  length0:= slen[0][scale_comp];
  length1:= slen[1][scale_comp];

  with sch^ do
  if(gr_info^.window_switching_flag<>0) AND (gr_info^.block_type= 2)then Begin
    if(gr_info^.mixed_block_flag<>0)then Begin{ MIXED}
      for sfb:= 0 to 7  do                       l[sfb]:= hgetbits(slen[0][gr_info^.scalefac_compress]);
      for sfb:= 3 to 5  do for window:=0 to 2 do s[window][sfb]:= hgetbits(slen[0][gr_info^.scalefac_compress]);
      for sfb:= 6 to 11 do for window:=0 to 2 do s[window][sfb]:= hgetbits(slen[1][gr_info^.scalefac_compress]);
      sfb:=12;for window:=0 to 2 do              s[window][sfb]:= 0;
    End else Begin{ SHORT}
      for sfb:=0 to 5  do for window:= 0 to 2 do s[window][sfb]:= hgetbits(length0);
      for sfb:=6 to 11 do for window:= 0 to 2 do s[window][sfb]:= hgetbits(length1);
      sfb:=12;for window:= 0 to 2 do             s[window][sfb]:= 0;
    End{ SHORT}
  End else Begin{ LONG types 0,1,3}
    if((si.ch[ch].scfsi[0]= 0) OR (gr= 0))then for i:=0  to 5  do l[i]:= hgetbits(length0);
    if((si.ch[ch].scfsi[1]= 0) OR (gr= 0))then for i:=6  to 10 do l[i]:= hgetbits(length0);
    if((si.ch[ch].scfsi[2]= 0) OR (gr= 0))then for i:=11 to 15 do l[i]:= hgetbits(length1);
    if((si.ch[ch].scfsi[3]= 0) OR (gr= 0))then for i:=16 to 20 do l[i]:= hgetbits(length1);
    l[21]:= 0;
    l[22]:= 0;
  End
End;

const nr_of_sfb_block:array[0..5,0..2,0..3]of integer=
((( 6, 5, 5, 5),( 9, 9, 9, 9),( 6, 9, 9, 9)),
(( 6, 5, 7, 3),( 9, 9,12, 6),( 6, 9,12, 6)),
((11,10, 0, 0),(18,18, 0, 0),(15,18, 0, 0)),
(( 7, 7, 7, 0),(12,12,12, 0),( 6,15,12, 0)),
(( 6, 6, 6, 3),(12, 9, 9, 6),( 6,12, 9, 6)),
(( 8, 8, 5, 0),(15,12, 9, 0),( 6,18, 9, 0)));

var scalefac_buffer:array[0..53]of integer;

procedure TLayerIII_Decoder.get_LSF_scale_data;
var new_slen:array[0..3]of integer;
    i,j,scalefac_comp, int_scalefac_comp,mode_ext,m,blocktypenumber, blocknumber:integer;
    gr_info:^tgrinfo;
Begin
  gr_info:= addr(si.ch[ch].gr[gr]);
  mode_ext:= header.h_mode_extension;
  scalefac_comp:=  gr_info^.scalefac_compress;

  if(gr_info^.block_type= 2)then Begin
    if(gr_info^.mixed_block_flag= 0)then
      blocktypenumber:= 1
    else
      if(gr_info^.mixed_block_flag= 1)then
        blocktypenumber:= 2
      else
        blocktypenumber:= 0;
  End else
    blocktypenumber:= 0;

  if( not (((mode_ext= 1) OR (mode_ext= 3)) AND (ch= 1)))then Begin
    if(scalefac_comp < 400)then Begin
      new_slen[0]:=(scalefac_comp shr  4) div  5;
      new_slen[1]:=(scalefac_comp shr  4) mod  5;
      new_slen[2]:=(scalefac_comp and $F) shr  2;
      new_slen[3]:=(scalefac_comp and  3);
      si.ch[ch].gr[gr].preflag:= 0;
      blocknumber:= 0;
    End else if(scalefac_comp  < 500)then Begin
      new_slen[0]:=((scalefac_comp- 400) shr  2) div  5;
      new_slen[1]:=((scalefac_comp- 400) shr  2) mod  5;
      new_slen[2]:=(scalefac_comp- 400) and  3;
      new_slen[3]:= 0;
      si.ch[ch].gr[gr].preflag:= 0;
      blocknumber:= 1;
    End else if(scalefac_comp < 512)then Begin
      new_slen[0]:=(scalefac_comp- 500) div  3;
      new_slen[1]:=(scalefac_comp- 500) mod  3;
      new_slen[2]:= 0;
      new_slen[3]:= 0;
      si.ch[ch].gr[gr].preflag:= 1;
      blocknumber:= 2;
    End else blocknumber:=0;
  End else{ if((((mode_ext= 1) OR (mode_ext= 3)) AND (ch= 1)))then }Begin
    int_scalefac_comp:= scalefac_comp shr  1;
    if(int_scalefac_comp < 180)then Begin
      new_slen[0]:= int_scalefac_comp div  36;
      new_slen[1]:=(int_scalefac_comp mod  36) div  6;
      new_slen[2]:=(int_scalefac_comp mod  36) mod  6;
      new_slen[3]:= 0;
      si.ch[ch].gr[gr].preflag:= 0;
      blocknumber:= 3;
    End else if(int_scalefac_comp < 244)Then Begin
      new_slen[0]:=((int_scalefac_comp- 180) and $3F) shr  4;
      new_slen[1]:=((int_scalefac_comp- 180) and $F) shr  2;
      new_slen[2]:=(int_scalefac_comp- 180) and  3;
      new_slen[3]:= 0;
      si.ch[ch].gr[gr].preflag:= 0;
      blocknumber:= 4;
    End Else If(int_scalefac_comp < 255)Then Begin
      new_slen[0]:=(int_scalefac_comp- 244) div  3;
      new_slen[1]:=(int_scalefac_comp- 244) mod  3;
      new_slen[2]:= 0;
      new_slen[3]:= 0;
      si.ch[ch].gr[gr].preflag:= 0;
      blocknumber:= 5;
    End else blocknumber:=0;
  End;

  m:= 0;for i:=0 to 4 do for j:= 0 to nr_of_sfb_block[blocknumber][blocktypenumber][i]-1 do Begin
    scalefac_buffer[m]:=switch(new_slen[i]= 0, 0, hgetbits(new_slen[i]));
    m:=m+1;
  End;
  for m:=m+1 to 45 do scalefac_buffer[m]:=0;
End;

procedure TLayerIII_Decoder.get_LSF_scale_factors;
var m,sfb,window:integer;
    gr_info:^tgrinfo;
    scale:^TScalefac;
Begin
  gr_info:= addr(si.ch[ch].gr[gr]);
  scale:=@(scalefac[ch]);
  m:= 0;
  get_LSF_scale_data(ch, gr);
  if(gr_info^.window_switching_flag<>0) AND (gr_info^.block_type= 2)Then Begin
    if(gr_info^.mixed_block_flag<>0)Then Begin{ MIXED}
      for sfb:= 0 to 7 do Begin
        scale^.l[sfb]:= scalefac_buffer[m];
        m:=m+1;
      End;
      for sfb:= 3 to 11 do for window:=0 to 2 do Begin
        scale^.s[window][sfb]:= scalefac_buffer[m];
        m:=m+1;
      End;
      for window:=0 to 2 do scale^.s[window][12]:= 0;
    End Else Begin{ SHORT}
      for sfb:= 0 to 11 do for window:=0 to 2 do Begin
        scale^.s[window][sfb]:= scalefac_buffer[m];
        m:=m+1;
      End;
      for window:=0 to 2 do scale^.s[window][12]:= 0;
    End
  End Else Begin{ LONG types 0,1,3}
    for sfb:= 0 to 20 do Begin
      scale^.l[sfb]:= scalefac_buffer[m];
      m:=m+1;
    End;
    scale^.l[21]:= 0;{ Jeff} {and Het}
    scale^.l[22]:= 0;
  End
End;

procedure tLayerIII_Decoder.huffman_decode;
{var y,x,w,v,h:integer;}var h:integer;
  type b2a=array[0..511,0..1]of byte;
       ia=array[0..3]of integer;
var out_:^ia;
var tlen,_0,i,_1,limit,_2,linb,_3,xlen1,_4:integer;
    part2_3_end,_5,region1Start,_6,region2Start,_7,index,_8,bv,_9:integer;
    hh:^huffcodetab;
    va:^b2a;vap:integer;
    g:^tgrinfo;
    yy:array[0..3]of integer;

Begin
  g:=@(si.ch[ch].gr[gr]);
  part2_3_end:= part2_start+ g^.part2_3_length;
  { Find region boundaryfor short blockcase}
  if((g^.window_switching_flag<>0) AND(g^.block_type= 2))Then Begin
    { Region2.}
    region1Start:= 36;{ sfb[9/3]*3=36}
    region2Start:= 576;{ No Region2for short blockcase}
  End Else Begin{ Find region boundaryfor long blockcase}
    region1Start:= sfBandIndex[sfreq].l[g^.region0_count+ 1];
    region2Start:= sfBandIndex[sfreq].l[g^.region0_count+ g^.region1_count+ 2];{ MI}
  End;

  index:= 0;
  out_:=addr(is_1d);
  { Read bigvalues area}
  bv:=g^.big_values shl 1;
  if region2Start>bv then region2Start:=bv;
  if region1Start>region2Start then region1Start:=region2Start;
  for i:=0 to 3 do begin
    case i of
      0:begin h:= g^.table_select[0];limit:=region1start;end;
      1:begin h:= g^.table_select[1];limit:=region2start;end;
      2:begin h:= g^.table_select[2];limit:=bv;end;
      3:begin h:= g^.count1table_select+32;limit:=576;end;
      else begin h:=0;limit:=576 end;
    end;
    hh:=@(ht[h]);tlen:=hh^.treelen;
    if tlen=0 then begin
      fillchar(out_^,(limit-index)shl 2,0);
      index:=limit;if index<576 then out_:=addr(is_1d[index]);
    end else begin
      linb:=hh^.linbits;xlen1:=hh^.xlen-1;
      while index<limit do Begin
        if totbit>=part2_3_end then break;
        if(tlen=0)then Begin
          out_^[0]:=0;out_:=addr(out_^[1]);
          out_^[0]:=0;out_:=addr(out_^[1]);
          index:=index+2;{ez biztos...}
        End else begin
          va:=addr(hh^.val^);vap:=0;
          repeat
            if va^[vap,0]=0 then begin
              yy[3]:=va^[vap,1];yy[2]:=yy[3]shr 4;yy[3]:=yy[3]and $F;break;
            end else begin
              if hget1bit<>0 then begin while va^[vap,1]>=MXOff do vap:=vap+va^[vap,1];vap:=vap+va^[vap,1]end
                             else begin while va^[vap,0]>=MXOff do vap:=vap+va^[vap,0];vap:=vap+va^[vap,0]end;
            end;
          until vap>=tlen;
          if(h>=32)then begin
            if(yy[3]and 8<>0)then if(hget1bit<>0)then out_^[0]:=-1 else out_^[0]:=1 else out_^[0]:=0;out_:=addr(out_^[1]);
            if(yy[3]and 4<>0)then if(hget1bit<>0)then out_^[0]:=-1 else out_^[0]:=1 else out_^[0]:=0;out_:=addr(out_^[1]);
            if(yy[3]and 2<>0)then if(hget1bit<>0)then out_^[0]:=-1 else out_^[0]:=1 else out_^[0]:=0;out_:=addr(out_^[1]);
            if(yy[3]and 1<>0)then if(hget1bit<>0)then out_^[0]:=-1 else out_^[0]:=1 else out_^[0]:=0;out_:=addr(out_^[1]);
            index:=index+4;
          End else Begin
            if linb<>0 then begin
              if(xlen1=yy[2])then yy[2]:=yy[2]+ hgetbits(linb);
              if(yy[2]<>0)then if(hget1bit<>0)then out_^[0]:=-yy[2] else out_^[0]:=yy[2]else out_^[0]:=0;out_:=addr(out_^[1]);
              if(xlen1=yy[3])then yy[3]:=yy[3]+ hgetbits(linb);
              if(yy[3]<>0)then if(hget1bit<>0)then out_^[0]:=-yy[3] else out_^[0]:=yy[3]else out_^[0]:=0;out_:=addr(out_^[1]);
            end else begin
              if(yy[2]<>0)then if(hget1bit<>0)then out_^[0]:=-yy[2] else out_^[0]:=yy[2]else out_^[0]:=0;out_:=addr(out_^[1]);
              if(yy[3]<>0)then if(hget1bit<>0)then out_^[0]:=-yy[3] else out_^[0]:=yy[3]else out_^[0]:=0;out_:=addr(out_^[1]);
            end;
            index:=index+2;
          End;
        end;
      End;
    end;
  end;

  if(totbit > part2_3_end)Then Begin
    rewindNbits(totbit- part2_3_end);
    index:=index-4;
  End;

  { Dismiss stuffing bits}
  if(totbit < part2_3_end)then
    hgetbits(part2_3_end- totbit);

  { Zero out_ rest}

  if(index < 576)then
    nonzero[ch]:= index
  else
    nonzero[ch]:= 576;

  { may not be necessary}
  {while(index<576) do begin
        is_1d[index]:= 0;inc(index);end;}
End;

procedure tLayerIII_Decoder.dequantize_sample;
type tx=array[0..SBLIMIT-1,0..SSLIMIT-1]of single;
     txr1d=array[0..SBLIMIT*SSLIMIT-1]of single;
var idx,abv,cb,next_cb_boundary,cb_begin,cb_width,index,t_index,j,g_gain:integer;
    xr_1d:^txr1d;
    gr_info:^tgrinfo;
    bi:^SBI;
    scale:^tscalefac;
    gain:single;
Begin
  gr_info:= addr(si.ch[ch].gr[gr]);
  cb:=0;index:=0;
  xr_1d:= addr( tx(xr)[0][0]);
  bi:=@(sfbandindex[sfreq]);
  scale:=@(scalefac[ch]);
  cb_begin:= 0;cb_width:=0;

  { choose correct scalefactor band per block type, initalize boundary}
  if(gr_info^.window_switching_flag<>0) AND (gr_info^.block_type= 2)Then Begin
    if(gr_info^.mixed_block_flag<>0)then
      next_cb_boundary:=bi^.l[1]{ LONG blocks: 0,1,3}
    else Begin
      cb_width:= bi^.s[1];
      next_cb_boundary:=(cb_width shl  2)- cb_width;
      cb_begin:= 0;
    End
  End Else Begin
    next_cb_boundary:=bi^.l[1];{ LONG blocks: 0,1,3}
  End;

{ Compute overall(global) scaling.}

  g_gain:=gr_info^.global_gain;

{ applyformula per block type}
  if(gr_info^.window_switching_flag<>0) AND (gr_info^.block_type= 2)Then Begin
    if(gr_info^.mixed_block_flag<>0)Then Begin
      for j:=0 to nonzero[ch]-1 do Begin
        if(index= next_cb_boundary)Then Begin{ Adjust critical band boundary}
          if(index= bi^.l[8])Then Begin
            next_cb_boundary:= bi^.s[4];
            next_cb_boundary:=(next_cb_boundary shl  2)-next_cb_boundary;
            cb:= 3;
            cb_width:= bi^.s[4]-bi^.s[3];
            cb_begin:= bi^.s[3];
            cb_begin:=(cb_begin shl  2)- cb_begin;
          End Else If(index < bi^.l[8])Then Begin
            cb:=cb+1;next_cb_boundary:= bi^.l[(cb)+1];
          End Else Begin
            cb:=cb+1;next_cb_boundary:= bi^.s[(cb)+1];
            next_cb_boundary:=(next_cb_boundary shl  2)-next_cb_boundary;
            cb_begin:= bi^.s[cb];
            cb_width:= bi^.s[cb+1]-cb_begin;
            cb_begin:=(cb_begin shl  2)- cb_begin;
          End
        End;
        { Do long/short dependent scaling operations}
        if j>= 36 then Begin
          abv:=is_1d[j];if abv=0 then xr_1d^[j]:=0 else begin
            t_index:=(index- cb_begin) div  cb_width;
            idx:= scale^.s[t_index][cb] shl gr_info^.scalefac_scale + (gr_info^.subblock_gain[t_index]);
            if abv>0 then xr_1d^[j]:=t_43[abv]* gaintab[g_gain-(idx shl 1)]
            else xr_1d^[j]:=-t_43[-abv]* gaintab[g_gain-(idx shl 1)];
          end;
        End Else Begin{ LONG block types 0,1,3& 1st 2 subbands ofswitched blocks}
          abv:=is_1d[j];if abv=0 then xr_1d^[j]:=0 else begin
            if(gr_info^.preflag<>0)then
              idx:=scale^.l[cb]+ pretab[cb] else idx:=scale^.l[cb];
            idx:= idx shl (gr_info^.scalefac_scale+1);
            if abv>0 then xr_1d^[j]:=t_43[abv]* gaintab[g_gain-idx]
            else xr_1d^[j]:=-t_43[-abv]* gaintab[g_gain-idx];
          end;
        End;
        index:=index+1;
      End;
    end else begin{(gr_info^.window_switching_flag<>0) AND (gr_info^.block_type= 2)}
      for j:=0 to nonzero[ch]-1 do Begin
        if(index= next_cb_boundary)Then Begin{ Adjust critical band boundary}
          cb:=cb+1;next_cb_boundary:= bi^.s[(cb)+1];
          next_cb_boundary:=(next_cb_boundary shl  2)-
          next_cb_boundary;
          cb_begin:= bi^.s[cb];
          cb_width:= bi^.s[cb+1]-cb_begin;
          cb_begin:=(cb_begin shl  2)- cb_begin;
        End;
        { Do long/short dependent scaling operations}
        abv:=is_1d[j];if abv=0 then xr_1d^[j]:=0 else begin
          t_index:=(index- cb_begin) div  cb_width;
          idx:= scale^.s[t_index][cb] shl gr_info^.scalefac_scale+(gr_info^.subblock_gain[t_index]);
          if abv>0 then xr_1d^[j]:=t_43[abv]* gaintab[g_gain-(idx shl 1)]
          else xr_1d^[j]:=-t_43[-abv]* gaintab[g_gain-(idx shl 1)];
        end;
        index:=index+1;
      End;
    end;
  end else begin {(gr_info^.mixed_block_flag<>0)}
    { Do long/short dependent scaling operations}
    if(gr_info^.preflag<>0)then gain:=gaintab[g_gain-(scale^.l[cb]+pretab[cb])shl(gr_info^.scalefac_scale+1)]
    else gain:=gaintab[g_gain-(scale^.l[cb])shl(gr_info^.scalefac_scale+1)];
    for j:=0 to nonzero[ch]-1 do Begin
      if(index= next_cb_boundary)Then Begin{ Adjust critical band boundary}
        cb:=cb+1;next_cb_boundary:= bi^.l[(cb)+1];

        { Do long/short dependent scaling operations}
        if(gr_info^.preflag<>0)then gain:=gaintab[g_gain-(scale^.l[cb]+pretab[cb])shl(gr_info^.scalefac_scale+1)]
        else gain:=gaintab[g_gain-(scale^.l[cb])shl(gr_info^.scalefac_scale+1)];
      End;
      abv:=is_1d[j];if abv=0 then xr_1d^[j]:=0
      else if abv>0 then xr_1d^[j]:=t_43[abv]* gain
      else xr_1d^[j]:=-t_43[-abv]* gain;

      index:=index+1;
    End;
  end;{mixed<>0}
  if nonzero[ch]<576 then fillchar(xr_1d^[nonzero[ch]],(576-nonzero[ch])shl 2,0);
{  for j:=nonzero[ch] to 575 do
    xr_1d^[j]:= 0.0;}
End;


  procedure tLayerIII_Decoder.i_stereo_k_values;
  Begin
    if(is_pos= 0)Then Begin
      k[0][i]:= 1.0;
      k[1][i]:= 1.0;
    End Else If(is_pos and  1<>0)Then Begin
      k[0][i]:= io[io_type][(is_pos+ 1) shr  1];
      k[1][i]:= 1.0;
    End Else Begin
      k[0][i]:= 1.0;
      k[1][i]:= io[io_type][is_pos shr  1];
    End
  End;

{type txr=array[0..575]of single;}
var is_pos:array[0..575]of integer;is_ratio:txr;

procedure tLayerIII_Decoder.stereo;
var    {l0,l1,}r0,r1,k0,k1:^txr;e,f:single;
    sb,ss,sfbcnt,mode_ext,sfb,i,j,max_sfb,lines,temp,temp2,io_type:integer;
    gr_info:^tgrinfo;
    ms_stereo,i_stereo,lsf:boolean;
const nn:single=0.707106781;
Begin
  if (channels= 1)Then Begin{ mono, bypass xr[0][][] to lr[0][][]}
{    move(ro[0],lr[0],sizeof(ro[0]));}
  End Else Begin
    gr_info:= addr(si.ch[0].gr[gr]);
    mode_ext:= header.h_mode_extension;
    ms_stereo:=(header.h_mode= joint_stereo) AND (mode_ext and $2<>0);
    i_stereo:=(header.h_mode= joint_stereo) AND (mode_ext and $1<>0);
    lsf:=(header.h_version= MPEG2_LSF);
    io_type:=(gr_info^.scalefac_compress and  1);
    { initialization}
    if(i_stereo)Then Begin
      for i:=0 to 575 do is_pos[i]:=7;
      if((gr_info^.window_switching_flag<>0) AND (gr_info^.block_type= 2))Then Begin
        if(gr_info^.mixed_block_flag<>0)Then Begin
          max_sfb:= 0;
          for j:=0 to 2 do Begin
            sfbcnt:= 2;
            {for sfb:=12 downto 3 do Begin}sfb:=12;while sfb>=3 do begin
              i:= sfBandIndex[sfreq].s[sfb];
              lines:= sfBandIndex[sfreq].s[sfb+1]- i;
              i:=(i shl  2)- i+(j+1)* lines- 1;
              while(lines > 0)do Begin
                if(txr(ro[1])[i] <> 0.0)Then Begin
                  sfbcnt:= sfb;
                  sfb:=-10;
                  lines:=-10;
                End;
                lines:=lines-1;
                i:=i-1;
              End;
              sfb:=sfb-1;
            End;
            sfb:= sfbcnt+ 1;
            if(sfb > max_sfb)then max_sfb:= sfb;
            while(sfb < 12)do Begin
              temp:= sfBandIndex[sfreq].s[sfb];
              sb:= sfBandIndex[sfreq].s[sfb+1]- temp;
              i:=(temp shl  2)- temp+ j* sb;
              while sb > 0 do  Begin
                is_pos[i]:= scalefac[1].s[j][sfb];
                if(is_pos[i] <> 7)then
                  if(lsf)then
                    i_stereo_k_values(is_pos[i], io_type, i)
                  else
                    is_ratio[i]:= TAN12[is_pos[i]];
                i:=i+1;
                sb:=sb-1;
              End;
              sfb:=sfb+1;
            End;
            sfb:= sfBandIndex[sfreq].s[10];
            sb:= sfBandIndex[sfreq].s[11]- sfb;
            sfb:=(sfb shl  2)- sfb+ j* sb;
            temp:= sfBandIndex[sfreq].s[11];
            sb:= sfBandIndex[sfreq].s[12]- temp;
            i:=(temp shl  2)- temp+ j* sb;
            while sb > 0 do Begin
              is_pos[i]:= is_pos[sfb];
              if(lsf)Then Begin
                k[0][i]:= k[0][sfb];
                k[1][i]:= k[1][sfb];
              End Else Begin
                is_ratio[i]:= is_ratio[sfb];
              End;
              i:=i+1;
              sb:=sb-1;
            End;
          End;
          if(max_sfb<= 3)Then Begin
            i:= 2;
            ss:= 17;
            sb:=-1;
            while(i>= 0)do Begin
              if(ro[1][i][ss] <> 0.0)Then Begin
                sb:=(i shl 4)+(i shl 1)+ ss;
                i:=-1;
              End Else Begin
                ss:=ss-1;
                if(ss < 0)Then Begin
                  i:=i-1;
                  ss:= 17;
                End
              End
            End;
            i:= 0;
            while(sfBandIndex[sfreq].l[i]<= sb)do i:=i+1;
            sfb:= i;
            i:= sfBandIndex[sfreq].l[i];
            for sfb:=sfb to 7 do Begin
              sb:= sfBandIndex[sfreq].l[sfb+1]-sfBandIndex[sfreq].l[sfb];
              for sb:=sb downto 1{!!!! 0?} do Begin
                is_pos[i]:= scalefac[1].l[sfb];
                if(is_pos[i] <> 7)then
                  if(lsf)then
                    i_stereo_k_values(is_pos[i], io_type, i)
                  else
                    is_ratio[i]:= TAN12[is_pos[i]];
                i:=i+1;
              End
            End
          End
        End Else Begin{if(gr_info->mixed_block_flag)}
          for j:=0 to 2 do Begin
            sfbcnt:=-1;
            {for sfb:=12 downto 0 do Begin}sfb:=12;while sfb>=0 do begin
              temp:= sfBandIndex[sfreq].s[sfb];
              lines:= sfBandIndex[sfreq].s[sfb+1]- temp;
              i:=(temp shl  2)- temp+(j+1)* lines- 1;
              while(lines > 0)do Begin
                if(txr(ro[1])[i] <> 0.0)Then Begin
                  sfbcnt:= sfb;
                  sfb:=-10;
                  lines:=-10;
                End;
                lines:=lines-1;
                i:=i-1;
              End;
              sfb:=sfb-1;
            End;
            sfb:= sfbcnt+ 1;
            while(sfb<12)do Begin
              temp:= sfBandIndex[sfreq].s[sfb];
              sb:= sfBandIndex[sfreq].s[sfb+1]- temp;
              i:=(temp shl  2)- temp+ j* sb;
              for sb:=sb downto 1 do Begin
                is_pos[i]:= scalefac[1].s[j][sfb];
                if(is_pos[i] <> 7)then
                  if(lsf)then
                    i_stereo_k_values(is_pos[i], io_type, i)
                  else
                    is_ratio[i]:= TAN12[is_pos[i]];
                i:=i+1;
              End;
              sfb:=sfb+1;
            End;
            temp:= sfBandIndex[sfreq].s[10];
            temp2:= sfBandIndex[sfreq].s[11];
            sb:= temp2- temp;
            sfb:=(temp shl  2)- temp+ j* sb;
            sb:= sfBandIndex[sfreq].s[12]- temp2;
            i:=(temp2 shl  2)- temp2+ j* sb;
            for sb:=sb downto 1 do Begin
              is_pos[i]:= is_pos[sfb];
              if(lsf)Then Begin
                k[0][i]:= k[0][sfb];
                k[1][i]:= k[1][sfb];
              End Else Begin
                is_ratio[i]:= is_ratio[sfb];
              End;
              i:=i+1;
            End
          End
        End
      End Else Begin{if(gr_info->window_switching_flag ...}
        i:= 31;
        ss:= 17;
        sb:= 0;
        while(i>= 0)do Begin
          if(ro[1][i][ss] <> 0.0)Then Begin
            sb:=(i shl 4)+(i shl 1)+ ss;
            i:=-1;
          End Else Begin
            ss:=ss-1;
            if(ss < 0)Then Begin
              i:=i-1;
              ss:= 17;
            End
          End
        End;
        i:= 0;
        while(sfBandIndex[sfreq].l[i]<= sb)do i:=i+1;
        sfb:= i;
        i:= sfBandIndex[sfreq].l[i];
        for sfb:=sfb to 20 do Begin
          sb:= sfBandIndex[sfreq].l[sfb+1]- sfBandIndex[sfreq].l[sfb];
          for sb:=sb downto 1 do Begin
            is_pos[i]:= scalefac[1].l[sfb];
            if(is_pos[i] <>7)then
              if(lsf)then
                i_stereo_k_values(is_pos[i], io_type, i)
              else
                is_ratio[i]:= TAN12[is_pos[i]];
            i:=i+1;
          End
        End;
        sfb:= sfBandIndex[sfreq].l[20];
        sb:= 576- sfBandIndex[sfreq].l[21];
        while(sb > 0) AND (i<576) do Begin
          is_pos[i]:= is_pos[sfb];{ error here: i>=576}
          if(lsf)Then Begin
            k[0][i]:= k[0][sfb];
            k[1][i]:= k[1][sfb];
          End Else Begin
            is_ratio[i]:= is_ratio[sfb];
          End;
          i:=i+1;
          sb:=sb-1;
        End{if(gr_info->mixed_block_flag)}
      End;{if(gr_info->window_switching_flag ...}
      r0:=addr(ro[0]);r1:=addr(ro[1]);
      k0:=addr(k[0]);k1:=addr(k[1]);

      if lsf then begin
        if ms_stereo Then for i:=0 to 575 do if(is_pos[i]= 7)Then Begin
          e:=r0^[i];f:=r1^[i];
          r0^[i]:=(e+f)* nn;
          r1^[i]:=(e-f)* nn;
        End else Begin
          e:=r0^[i];
          r0^[i]:= e* k0^[i];
          r1^[i]:= e* k1^[i];
        End
        else for i:=0 to 575 do if(is_pos[i]<>7)Then Begin
          e:=r0^[i];
          r0^[i]:= e* k0^[i];
          r1^[i]:= e* k1^[i];
        End
      end else begin
        if ms_stereo Then for i:=0 to 575 do if(is_pos[i]= 7)Then Begin
          e:=r0^[i];f:=r1^[i];
          r0^[i]:=(e+f)* nn;
          r1^[i]:=(e-f)* nn;
        End else Begin
          e:=is_ratio[i];
          f:= r0^[i] /(1+ e);
          r0^[i]:= f* e;
          r1^[i]:= f;
        End
        else for i:=0 to 575 do if(is_pos[i]<>7)Then Begin
          e:=is_ratio[i];
          f:= r0^[i] /(1+ e);
          r0^[i]:= f* e;
          r1^[i]:= f;
        End;
      end;
    End else begin{if(i_stereo)}
      r0:=addr(ro[0]);r1:=addr(ro[1]);
      if ms_stereo Then for i:=0 to 575 do Begin
        e:=r0^[i];f:=r1^[i];
        r0^[i]:=(e+f)* nn;
        r1^[i]:=(e-f)* nn;
      end
    end;

  End{ channels== 2}
End;



procedure tLayerIII_Decoder.reorder;
type tx=array[0..SBLIMIT-1,0..SSLIMIT-1]of single;
     txr1d=array[0..SBLIMIT*SSLIMIT-1]of single;
     ia=array[0..575]of integer;
var freq,freq3,index,sfb,sfb_start,sfb_start3,sfb_lines,src_line,des_line,idx2:integer;
    xr_1d,out_1:^txr1d;retab:^ia;
    gr_info:^tgrinfo;
Begin
  gr_info:= addr(si.ch[ch].gr[gr]);
  xr_1d:= addr( tx(xr)[0][0]);
  out_1:=addr(out_1d[ch][gr]);
  if((gr_info^.window_switching_flag<>0) AND (gr_info^.block_type= 2))Then Begin
    if(gr_info^.mixed_block_flag<>0)Then Begin
      { NO REORDER FOR LOW 2 SUBBANDS}
      fillchar(out_1^[36],sizeof(out_1^)-36*sizeof(out_1^[0]),0);
      move(xr_1d^,out_1^,36*sizeof(out_1^[0]));
{      for index:=0 to 575 do out_1^[index]:=0;}
{      for index:= 0 to 35 do
        out_1^[index]:= xr_1d^[index];}
      { REORDERING FOR REST SWITCHED SHORT}
      sfb:=3;sfb_start:=sfBandIndex[sfreq].s[3];sfb_lines:=sfBandIndex[sfreq].s[4]- sfb_start;
      while sfb < 13 do Begin
        sfb_start3:=(sfb_start shl 2)- sfb_start;
        freq:=0;freq3:=0;
        while freq<sfb_lines do begin
          src_line:= sfb_start3+ freq;
          des_line:= sfb_start3+ freq3;
          out_1^[des_line]:= xr_1d^[src_line];
          src_line:=src_line+ sfb_lines;
          des_line:=des_line+1;
          out_1^[des_line]:= xr_1d^[src_line];
          src_line:=src_line+ sfb_lines;
          des_line:=des_line+1;
          out_1^[des_line]:= xr_1d^[src_line];
          freq:=freq+1;freq3:= freq3+3;
        End;
        sfb:=sfb+1;sfb_start:= sfBandIndex[sfreq].s[sfb];
        sfb_lines:=sfBandIndex[sfreq].s[sfb+1]- sfb_start;
      End
    End Else Begin{ pure short}
      retab:=addr(reorder_table[sfreq]);
      idx2:=0;
      for index:=0 to 576-1 do begin
        idx2:=idx2+retab^[index];
        out_1^[index]:= xr_1d^[idx2 shr 2];
      end;
    End
  End else Begin{ long blocks}
    move(xr_1d^,out_1^,sizeof(out_1^));
  End
End;


procedure TLayerIII_Decoder.antialias;
var bu,bd:single;
    gr_info:^tgrinfo;
    out_1:^txr;
    sb18,ss,sb18lim,src_idx1,src_idx2:integer;
Begin
  gr_info:= addr(si.ch[ch].gr[gr]);
  { 31 alias-reduction operations between each pair of sub-bands}
  { with 8 butterflies between each pair}
  with gr_info^ do
  if((window_switching_flag<>0)AND(block_type= 2)AND(mixed_block_flag=0))then exit;
  with gr_info^ do
  if((window_switching_flag<>0)AND(mixed_block_flag<>0)AND(block_type= 2))Then
    sb18lim:= 18
  Else
    sb18lim:= 558;

  out_1:=addr(out_1d[ch][gr]);
  sb18:=0;while sb18 < sb18lim do Begin
    src_idx1:= sb18+ 17;
    src_idx2:= sb18+ 18;
    for ss:=0 to 7 do begin
      bu:=out_1^[src_idx1];
      bd:=out_1^[src_idx2];
      out_1^[src_idx1]:=bu*cs[ss]-bd*ca[ss];
      out_1^[src_idx2]:=bd*cs[ss]+bu*ca[ss];
      src_idx1:=src_idx1-1;
      src_idx2:=src_idx2+1;
    end;
    sb18:= sb18+18;
  End
End;

procedure TLayerIII_Decoder.hybrid;
type tra=array[0..575]of single;
var rawout:array[0..35]of single;
    i,bt,sb18:integer;
    tsOut,prvblk:^Tra;
    gr_info:^tgrinfo;
    b,mixed:boolean;
    c:integer;
Begin
  gr_info:= addr(si.ch[ch].gr[gr]);
  b:=false;
  mixed:=(gr_info^.window_switching_flag<>0) AND  (gr_info^.mixed_block_flag<>0);

  if saveMP3Bands then
    doSaveBands(ch, gr, switch(mixed, 1, 0), gr_info^.block_type);

  sb18:=0;while sb18<576 do begin
    bt:=switch((mixed AND(sb18 < 36)),0, gr_info^.block_type);

    tsOut:= addr(out_1d[ch][gr][sb18]);
    inv_mdct_(tsOut^, rawout, bt);
    { overlap addition}
    prvblk:= addr( prevblck[ch][sb18]);
    i:=0;b:=not b;
    if b then while i<18 do begin
      tsOut^[i]:= rawout[i]+ prvblk^[i];
      prvblk^[i]:= rawout[i+18];
      i:=i+1;
    end else while i<18 do begin
      tsOut^[i]:= rawout[i]+ prvblk^[i];
      prvblk^[i]:= rawout[i+18];
      i:=i+1;
      tsOut^[i]:= -(rawout[i]+ prvblk^[i]);
      prvblk^[i]:= rawout[i+18];
      i:=i+1;
    end;
    sb18:=sb18+18;
  End
End;


procedure tLayerIII_Decoder.do_downmix;
type txr=array[0..SSLIMIT*SBLIMIT-1]of single;
var i:integer;
    r0,r1:^txr;
Begin
  r0:=addr(ro[0]);r1:=addr(ro[1]);
  for i:=0 to SBLIMIT*SSLIMIT-1 do
    r0^[i]:=(r0^[i]+ r1^[i])* 0.5;
End;

var fbuf:array[0..4095]of byte;
Function tLayerIII_Decoder.decodeFrame;
var nSlots:integer;
    flush_main:integer;
    main_data_end:integer;
Begin
  if framedecoded and(lastframe=n)then begin decodeframe:=true;exit end;
  decodeframe:=false;if halted then exit;
  frameDecoded:=false;grdecoded:=-1;
  if(n<0)then exit;

  if not headerdecoded then begin
    {Stream^.Seek(0);}n:=0
  end else
    if n>=numframes then exit;

  if(lastframe<>n-1)then begin
    Stream^.Seek(trunc(n*realframesize)-1);
    LastFrame:=-2;
  end else
    LastFrame:=-3;
  if not header.read_header(Stream^)then
    exit;
//  if not headerdecoded then begin           VBR miatt kikomment!!!

    channels:=switch(header.h_mode= single_channel , 1, 2);
    max_gr:=switch(header.h_version= MPEG1 , 2, 1);
    sfreq:=  ord(header.h_sample_frequency)+switch((header.h_version= MPEG1) , 3, 0);
    setchannels;
    realframesize:=header.realframesize;
    if realframesize>0 then numframes:=trunc(Stream^.Size/realframesize);
    headerdecoded:=true;

//  end;
  nSlots:= header.nslots;
  get_side_info;
  stream^.blockread(fbuf[0],nSlots);if not stream^.success then exit;

  allzero:=false;

  hputbuf(fbuf[0],nSlots);

  main_data_end:= hsstell shr  3;{ of previous frame}
  flush_main:=(hsstell and  7);
  if(flush_main<>0)Then Begin
    hgetbits(8- flush_main);
    main_data_end:=main_data_end+1;
  End;

  bytes_to_discard:= frame_start- main_data_end - si.main_data_begin;
  frame_start:=  frame_start+ nSlots;

  if(main_data_end > 4096)Then Begin
    frame_start:=frame_start- 4096;
    rewindNbytes(4096);
  End;
{  if(bytes_to_discard < 0)then exit;}
  while bytes_to_discard > 0 do begin
    hgetbits(8);
    bytes_to_discard:=bytes_to_discard-1;
  end;
  decodeframe:=true;
  framedecoded:=true;
  lastframe:=n;
End;

Function tLayerIII_Decoder.DecodeGr(gr:integer):boolean;
var ch:integer;
begin
  DecodeGr:=false;if halted then exit;
  if not framedecoded then exit;
  if(gr=1)and(max_gr=2)and(grDecoded=-1)then DecodeGr(0);
  if((gr=0)and(grdecoded=-1))or((gr=1)and(max_gr=2)and(grdecoded=0))then begin
    if bytes_to_discard>=0 then begin
      for ch:=0 to channels-1 do Begin
        part2_start:= hsstell;
        if(header.h_version= MPEG1)then
          get_scale_factors(ch, gr)
        else{ MPEG-2 LSF}
          get_LSF_scale_factors(ch, gr);
        huffman_decode(ch, gr);
        dequantize_sample(ro[ch], ch, gr);
      End;
      stereo(gr);
      if((which_channels=downmix) AND (channels > 1))then do_downmix;
      for ch:=first_channel to last_channel do Begin
        reorder(ro[ch], ch, gr);
        antialias(ch, gr);
        hybrid(ch, gr);
      End;{ channels}
    end else begin
      fillchar(out_1d[gr],sizeof(out_1d[gr]),0); //something's wrong here
    end;
    grdecoded:=gr;
    DecodeGr:=true;
  end else DecodeGr:=gr=grDecoded;
end;

Procedure TLayerIII_Decoder.SetChannels;
begin
  if(channels= 2)then case which_channels of
    downmix,left:  begin first_channel:=0; last_channel:= 0;end;
    right: begin first_channel:= 1;last_channel:= 1;end;
    both:  begin first_channel:= 0;last_channel:= 1;end;
  End else Begin first_channel:= 0;last_channel:= 0;End;
end;


////////////////////////////////////////////////////////////////////////////////
///  Hybrid player/recorder                                                  ///
////////////////////////////////////////////////////////////////////////////////

{$R+}

procedure MP3Bands_StartRecording;
begin
  saveMP3Bands:=true;
  saveMP3Bands_result:=nil;
end;

function MP3Bands_Finish_GetData:RawByteString;
var i,cnt,c2:integer;
    str:ansistring;
begin
  saveMP3Bands:=false;
  with AnsiStringBuilder(str, true)do begin
    cnt:=length(saveMP3Bands_result); AddStr(DataToStr(cnt, 4)); //total size
    for i:=0 to cnt-1 do begin
      c2:=length(saveMP3Bands_result[i]);
      AddStr(DataToStr(c2, 2)); //bands size (words)
      if c2>0 then AddStr(DataToStr(saveMP3Bands_result[i,0], c2 shl 1));
    end;
    Finalize;
  end;
  result:=str;
end;


function MP3Bands_LoadFromData(const data:RawByteString):TMP3Bands;
var ptr:psmallint;
    i:integer;
begin
  result:=nil;
  if length(data)<4 then exit;
  ptr:=pointer(data);

  setlength(result, pinteger(ptr)^); inc(ptr, 2);
  for i:=0 to high(result)do begin
    setlength(result[i], ptr^); inc(ptr);
    if result[i]<>nil then move(ptr^, result[i][0], length(result[i])*2);
    inc(ptr, length(result[i]));
  end;
end;


procedure TMP3WorkArea.reset;
begin
  FillChar(prevblck, sizeof(prevblck), 0);
end;

procedure MP3Bands_decode(const data:TArray<smallint>;var dst; out ch,gr,blocktype:Integer; out mixed:boolean; const extraScale:single=1);
type TDst=array[0..1,0..1,0..575]of single;
var out_1d:^TDst;

var i,j,k,ex,zeroCnt,dataCnt:integer;
    scale:single;
    tsOut:PSingleArray;
begin
  out_1d:=Addr(dst);

  if data=nil then exit;//raise Exception.Create('MP3Bands_decode() empty data');

  //decode header: ch+gr shl 1+mixed shl 2+blockType shl 3+(ex+$80) shl 8;
  i:=data[0];
  ch:=i       and 1;
  gr:=i shr 1 and 1;
  mixed:=boolean(i shr 2 and 1);
  blocktype:=i shr 3 and 3;
  ex:=i and $ff00 shr 8-$80;
  scale:=power(2,ex)/32767*extraScale;

  //decode
  tsOut:= addr(out_1d[ch][gr][0]);
  i:=1; j:=0; while i<=high(data)do begin
    zeroCnt:=data[i]and $ff;
    dataCnt:=word(data[i])shr 8;
    inc(i);

    FillChar(tsOut[j], zeroCnt shl 2, 0);
    inc(j, zeroCnt);

    for k:=0 to dataCnt-1 do begin
      tsOut[j]:=data[i]*scale;
      inc(j); inc(i);
    end;
  end;
  FillChar(tsOut[j], (576-j)shl 2, 0);
end;


procedure TLayerIII_Decoder.doSaveBands(ch, gr, mixed, blockType:integer);
var smp:array[0..575]of smallint;
    hdr:SmallInt;
    ma,s,scale:single;
    i,j,ex,zeroCnt,dataCnt,activeLength:integer;
    strm:TArray<smallint>;
    bands:PSingleArray;

    mixd:boolean;
begin
  bands:=addr(out_1d[ch][gr]);

  //select max
  ma:=1e-10; for i:=0 to 575 do begin
    s:=bands[i];
    if  s>ma then ma:= s else
    if -s>ma then ma:=-s;
  end;

  //convert to 16bit
  ex:=ceil(log2(max(ma,1))); //exponent
  scale:=32767/power(2,ex);
  for i:=0 to 575 do smp[i]:=round(bands[i]*scale);

  //header
  setlength(strm, 1); strm[0]:=smallint(ch+gr shl 1+mixed shl 2+blockType shl 3+(ex+$80) shl 8);

  //RLE encode
  i:=0; activeLength:=1;
  while i<576 do begin
    zeroCnt:=0;
    dataCnt:=0;
    for j:=1 to 255 do begin if i>=576 then break; if smp[i]<>0 then break; inc(i); inc(zeroCnt); end;
    for j:=1 to 255 do begin if i>=576 then break; if smp[i]= 0 then break; inc(i); inc(dataCnt); end;

    SetLength(strm, length(strm)+1);  strm[high(strm)]:=smallint(zeroCnt+dataCnt shl 8);
    for j:=0 to dataCnt-1 do begin
      SetLength(strm, length(strm)+1);  strm[high(strm)]:=smp[i-dataCnt+j];
    end;
    if dataCnt>0 then
      activeLength:=length(strm);
  end;
  setlength(strm, activeLength);

  setlength(saveMP3Bands_result, length(saveMP3Bands_result)+1);
  saveMP3Bands_result[high(saveMP3Bands_result)]:=strm;
end;


procedure MP3Bands_Play(var WA:TMP3WorkArea; const data:TArray<smallint>; out grOut:integer);
var b:boolean;
    bt,sb18:integer;
    tsOut,prvblk:PSingleArray;
    rawout:array[0..35]of single;

    i,ch,gr,blocktype:Integer;
    mixed:boolean;
Begin
  gr:=0; //todo: egy gr-nek kellene csak lennie!!!
  MP3Bands_decode(data, wa.out_1d, ch, gr, blocktype, mixed);
  grOut:=gr;

  //do imdct
  b:=false;
  sb18:=0;while sb18<576 do begin
    tsOut:= addr(wa.out_1d[ch][gr][sb18]);
    bt:=switch((mixed AND(sb18 < 36)),0, blocktype);

    inv_mdct_(tsOut^, rawout, bt);
    { overlap addition}
    prvblk:= addr(wa.prevblck[ch][sb18]);
    i:=0;b:=not b;
    if b then while i<18 do begin
      tsOut^[i]:= rawout[i]+ prvblk^[i];
      prvblk^[i]:= rawout[i+18];
      i:=i+1;
    end else while i<18 do begin
      tsOut^[i]:= rawout[i]+ prvblk^[i];
      prvblk^[i]:= rawout[i+18];
      i:=i+1;
      tsOut^[i]:= -(rawout[i]+ prvblk^[i]);
      prvblk^[i]:= rawout[i+18];
      i:=i+1;
    end;
    sb18:=sb18+18;
  End
End;





end.







