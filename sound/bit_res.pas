unit bit_res;
interface
uses het.utils;

const brBUFSIZE=4096;

type TBit_Reserve=object
{       private}
	offse, totbit, buf_byte_idx,buf_bit_idx:integer;
	buf:array[0..brBufSize-1]of byte;
       public
	Constructor Init;
        Procedure Reset;
        Destructor Done;
        Function hsstell:integer;
	Function hgetbits(number_of_bits:integer):integer;
	Function hget1bit:integer;
	Procedure hputbuf(var val;len:integer);

	Procedure rewindNbits(N:integer);
	Procedure rewindNbytes(N:integer);
      end;

implementation

Constructor TBit_Reserve.init;
begin
  reset;
end;

Procedure TBit_Reserve.Reset;
begin
  offse       := 0;
  totbit	:= 0;
  buf_byte_idx := 0;
  buf_bit_idx  := 0;
  Fillchar(buf,brBufSize,$ff);
end;

Destructor TBit_Reserve.Done;
begin
end;

Function TBit_Reserve.hsstell;begin result:=totbit end;

function TBit_Reserve.hgetbits(number_of_bits:integer):integer;var n:integer;
begin
  if number_of_bits<=0 then begin result:=0;exit;end;
  result:=(integer(buf[buf_byte_idx])shl 8)or
          buf[(buf_byte_idx+1)and(brbufsize-1)];
  if number_of_bits<=8 then
    result:=((result shl buf_bit_idx)and $FFFF) shr(16-number_of_bits)
  else
    result:=((((result shl 8) or buf[(buf_byte_idx+2)and(brbufsize-1)])
            shl buf_bit_idx)and $FFFFFF) shr(24-number_of_bits);
  totbit:=totbit+number_of_bits;
  buf_bit_idx:=buf_bit_idx+number_of_bits;
  n:=buf_bit_idx shr 3;
  if n<>0 then begin
    buf_byte_idx:=(buf_byte_idx+n)and(brBufSize-1);
    buf_bit_idx:=buf_bit_idx and 7;
  end;
end;

function TBit_Reserve.hget1bit:integer;var n:integer;
begin
  result:=(integer(buf[buf_byte_idx])shl buf_bit_idx shr 7)and 1;
  totbit:=totbit+1;
  buf_bit_idx:=buf_bit_idx+1;
  n:=buf_bit_idx shr 3;
  if n<>0 then begin
    buf_byte_idx:=(buf_byte_idx+1)and(brBufSize-1);
    buf_bit_idx:=0;
  end;
end;

type ba=array[0..1]of byte;

Procedure TBit_Reserve.hputbuf;{assembler;}
var l:integer;
begin
  l:=brbufsize-offse;{ennyi mehet a vegere}
  if l>=len then begin
    move(val,buf[offse],len);
  end else begin
    move(val,buf[offse],l);
    move(ba(val)[l],buf,len-l);
  end;
  offse:=(offse+len)and(brbufsize-1);
end;

Procedure TBit_Reserve.rewindNbits;
begin
  for n:=1 to n do begin
    dec(totbit);
    if buf_bit_idx=0 then begin
      dec(buf_byte_idx);
      buf_bit_idx:=7;
    end else
      dec(buf_bit_idx);
  end;
  totbit:=totbit and (brbufsize shl 3-1);
  buf_byte_idx:=buf_byte_idx and (brbufsize-1);
end;

procedure TBit_Reserve.rewindNbytes;
begin
  totbit:=(totbit-(longint(N) shl 3))and (brbufsize shl 3-1);
  buf_byte_idx:=(longint(buf_byte_idx)-N)and (brbufsize-1);
end;

end.