// This unit is part of the GLScene Project, http://glscene.org
// Additional SSE optimization based on Quake
unit uDXTC;

interface

uses
   SysUtils, classes, math, graphics;

procedure DecodeDXT1toBitmap32(encData, decData : PByteArray; w,h : Integer; var trans : Boolean);
procedure DecodeDXT3toBitmap32(encData, decData : PByteArray; w,h : Integer);
procedure DecodeDXT5toBitmap32(encData, decData : PByteArray; w,h : Integer);

type
   TDXTVersion=(dxt1,dxt3,dxt5,dxt3dc);

function DXTCompressedSize(const version:TDXTVersion;const width,height:integer):integer;
function DXTEncode(const version:TDXTVersion;const bmp:TBitmap):TBytes;
function DXTDecode(const version:TDXTVersion;const data:TBytes;const width,height:integer):TBitmap;

implementation

uses het.Utils, het.Gfx;

//constants
type
  TCnst=record
  end;
  PCnst=^TCnst;

//var cnst:

// DecodeColor565
procedure DecodeColor565(col : Word; var r,g,b : Byte);
begin
   r:=col and $1F;
   g:=(col shr 5) and $3F;
   b:=(col shr 11) and $1F;
end;

// DecodeDXT1toBitmap32
//
procedure DecodeDXT1toBitmap32(encData, decData : PByteArray; w,h : Integer; var trans : Boolean);
var
   x,y,i,j,k,select : Integer;
   col0, col1 : Word;
   colors : array[0..3] of array[0..3] of Byte;
   bitmask : Cardinal;
   temp : PByte;
   r0,g0,b0,r1,g1,b1 : Byte;
   canTrans:boolean;
begin
   trans:=False;

   if not (Assigned(encData) and Assigned(decData)) then exit;

   temp:=PByte(encData);
   for y:=0 to ((h+3) div 4)-1 do begin
      for x:=0 to (w div 4)-1 do begin
         col0:=PWord(temp)^;        Inc(temp, 2);
         col1:=PWord(temp)^;        Inc(temp, 2);
         bitmask:=PCardinal(temp)^; Inc(temp, 4);

         DecodeColor565(col0,r0,g0,b0);
         DecodeColor565(col1,r1,g1,b1);

         colors[0][0]:=r0 shl 3;
         colors[0][1]:=g0 shl 2;
         colors[0][2]:=b0 shl 3;
         colors[0][3]:=$FF;
         colors[1][0]:=r1 shl 3;
         colors[1][1]:=g1 shl 2;
         colors[1][2]:=b1 shl 3;
         colors[1][3]:=$FF;

         if col0>col1 then begin
            canTrans:=false;
            colors[2][0]:=(2*colors[0][0]+colors[1][0]+1) div 3;
            colors[2][1]:=(2*colors[0][1]+colors[1][1]+1) div 3;
            colors[2][2]:=(2*colors[0][2]+colors[1][2]+1) div 3;
            colors[2][3]:=$FF;
            colors[3][0]:=(colors[0][0]+2*colors[1][0]+1) div 3;
            colors[3][1]:=(colors[0][1]+2*colors[1][1]+1) div 3;
            colors[3][2]:=(colors[0][2]+2*colors[1][2]+1) div 3;
            colors[3][3]:=$FF;
         end else begin
            canTrans:=true;
            colors[2][0]:=(colors[0][0]+colors[1][0]) div 2;
            colors[2][1]:=(colors[0][1]+colors[1][1]) div 2;
            colors[2][2]:=(colors[0][2]+colors[1][2]) div 2;
            colors[2][3]:=$FF;
            colors[3][0]:=(colors[0][0]+colors[1][0]) div 2;
            colors[3][1]:=(colors[0][1]+colors[1][1]) div 2;
            colors[3][2]:=(colors[0][2]+colors[1][2]) div 2;
            colors[3][3]:=0;
         end;

         k:=0;
         for j:=0 to 3 do begin
            for i:=0 to 3 do begin
               select:=(bitmask and (3 shl (k*2))) shr (k*2);
               if not trans and canTrans and(select=3)then trans:=true;
               if ((4*x+i)<w) and ((4*y+j)<h) then
                  PCardinal(@decData[((4*y+j)*w+(4*x+i))*4])^:=Cardinal(colors[select]);
               Inc(k);
            end;
         end;

      end;
   end;
end;

// DecodeDXT3toBitmap32
//
procedure DecodeDXT3toBitmap32(encData, decData : PByteArray; w,h : Integer);
var
   x,y,i,j,k,select : Integer;
   col0, col1, wrd : Word;
   colors : array[0..3] of array[0..3] of Byte;
   bitmask, offset : Cardinal;
   temp : PByte;
   r0,g0,b0,r1,g1,b1 : Byte;
   alpha : array[0..3] of Word;
begin
   if not (Assigned(encData) and Assigned(decData)) then exit;

   temp:=PByte(encData);
   for y:=0 to ((h+3) div 4)-1 do begin
      for x:=0 to (w div 4)-1 do begin
         alpha[0]:=PWord(temp)^;    Inc(temp, 2);
         alpha[1]:=PWord(temp)^;    Inc(temp, 2);
         alpha[2]:=PWord(temp)^;    Inc(temp, 2);
         alpha[3]:=PWord(temp)^;    Inc(temp, 2);
         col0:=PWord(temp)^;        Inc(temp, 2);
         col1:=PWord(temp)^;        Inc(temp, 2);
         bitmask:=PCardinal(temp)^; Inc(temp, 4);

         DecodeColor565(col0,r0,g0,b0);
         DecodeColor565(col1,r1,g1,b1);

         colors[0][0]:=r0 shl 3;
         colors[0][1]:=g0 shl 2;
         colors[0][2]:=b0 shl 3;
         colors[0][3]:=$FF;
         colors[1][0]:=r1 shl 3;
         colors[1][1]:=g1 shl 2;
         colors[1][2]:=b1 shl 3;
         colors[1][3]:=$FF;
         colors[2][0]:=(2*colors[0][0]+colors[1][0]+1) div 3;
         colors[2][1]:=(2*colors[0][1]+colors[1][1]+1) div 3;
         colors[2][2]:=(2*colors[0][2]+colors[1][2]+1) div 3;
         colors[2][3]:=$FF;
         colors[3][0]:=(colors[0][0]+2*colors[1][0]+1) div 3;
         colors[3][1]:=(colors[0][1]+2*colors[1][1]+1) div 3;
         colors[3][2]:=(colors[0][2]+2*colors[1][2]+1) div 3;
         colors[3][3]:=$FF;

         k:=0;
         for j:=0 to 3 do begin
            for i:=0 to 3 do begin
               select:=(bitmask and (3 shl (k*2))) shr (k*2);
               if ((4*x+i)<w) and ((4*y+j)<h) then
                  PCardinal(@decData[((4*y+j)*w+(4*x+i))*4])^:=Cardinal(colors[select]);
               Inc(k);
            end;
         end;

         for j:=0 to 3 do begin
            wrd:=alpha[j];
            for i:=0 to 3 do begin
               if (((4*x+i)<w) and ((4*y+j)<h)) then begin
                  offset:=((4*y+j)*w+(4*x+i))*4+3;
                  decData[offset]:=wrd and $0F;
                  decData[offset]:=decData[offset] or (decData[offset] shl 4);
               end;
               wrd:=wrd shr 4;
            end;
         end;

      end;
   end;
end;

// DecodeDXT5toBitmap32
//
procedure DecodeDXT5toBitmap32(encData, decData : PByteArray; w,h : Integer);
var
   x,y,i,j,k,select : Integer;
   col0, col1 : Word;
   colors : array[0..3] of array[0..3] of Byte;
   bits, bitmask, offset : Cardinal;
   temp, alphamask : PByte;
   r0,g0,b0,r1,g1,b1 : Byte;
   alphas : array[0..7] of Byte;
begin
   if not (Assigned(encData) and Assigned(decData)) then exit;

   temp:=PByte(encData);
   for y:=0 to ((h+3) div 4)-1 do begin
      for x:=0 to (w div 4)-1 do begin
         alphas[0]:=temp^; Inc(temp);
         alphas[1]:=temp^; Inc(temp);
         alphamask:=temp; Inc(temp, 6);
         col0:=PWord(temp)^;        Inc(temp, 2);
         col1:=PWord(temp)^;        Inc(temp, 2);
         bitmask:=PCardinal(temp)^; Inc(temp, 4);

         DecodeColor565(col0,r0,g0,b0);
         DecodeColor565(col1,r1,g1,b1);

         colors[0][0]:=r0 shl 3;
         colors[0][1]:=g0 shl 2;
         colors[0][2]:=b0 shl 3;
         colors[0][3]:=$FF;
         colors[1][0]:=r1 shl 3;
         colors[1][1]:=g1 shl 2;
         colors[1][2]:=b1 shl 3;
         colors[1][3]:=$FF;
         colors[2][0]:=(2*colors[0][0]+colors[1][0]+1) div 3;
         colors[2][1]:=(2*colors[0][1]+colors[1][1]+1) div 3;
         colors[2][2]:=(2*colors[0][2]+colors[1][2]+1) div 3;
         colors[2][3]:=$FF;
         colors[3][0]:=(colors[0][0]+2*colors[1][0]+1) div 3;
         colors[3][1]:=(colors[0][1]+2*colors[1][1]+1) div 3;
         colors[3][2]:=(colors[0][2]+2*colors[1][2]+1) div 3;
         colors[3][3]:=$FF;

         k:=0;
         for j:=0 to 3 do begin
            for i:=0 to 3 do begin
               select:=(bitmask and (3 shl (k*2))) shr (k*2);
               if ((4*x+i)<w) and ((4*y+j)<h) then
                  PCardinal(@decData[((4*y+j)*w+(4*x+i))*4])^:=Cardinal(colors[select]);
               Inc(k);
            end;
         end;

         if (alphas[0] > alphas[1]) then begin
            alphas[2]:=(6*alphas[0]+1*alphas[1]+3) div 7;
            alphas[3]:=(5*alphas[0]+2*alphas[1]+3) div 7;
            alphas[4]:=(4*alphas[0]+3*alphas[1]+3) div 7;
            alphas[5]:=(3*alphas[0]+4*alphas[1]+3) div 7;
            alphas[6]:=(2*alphas[0]+5*alphas[1]+3) div 7;
            alphas[7]:=(1*alphas[0]+6*alphas[1]+3) div 7;
         end else begin
            alphas[2]:=(4*alphas[0]+1*alphas[1]+2) div 5;
            alphas[3]:=(3*alphas[0]+2*alphas[1]+2) div 5;
            alphas[4]:=(2*alphas[0]+3*alphas[1]+2) div 5;
            alphas[5]:=(1*alphas[0]+4*alphas[1]+2) div 5;
            alphas[6]:=0;
            alphas[7]:=$FF;
         end;

         bits:=PCardinal(alphamask)^;
         for j:=0 to 1 do begin
            for i:=0 to 3 do begin
               if (((4*x+i)<w) and ((4*y+j)<h)) then begin
                  offset:=((4*y+j)*w+(4*x+i))*4+3;
                  decData[Offset]:=alphas[bits and 7];
               end;
               bits:=bits shr 3;
            end;
         end;

         Inc(alphamask, 3);
         bits:=PCardinal(alphamask)^;
         for j:=2 to 3 do begin
            for i:=0 to 3 do begin
               if (((4*x+i)<w) and ((4*y+j)<h)) then begin
                  offset:=((4*y+j)*w+(4*x+i))*4+3;
                  decData[offset]:=alphas[bits and 7];
               end;
               bits:=bits shr 3;
            end;
         end;

      end;
   end;
end;

// DecodeDXT3DCtoBitmap32
//
procedure DecodeDXT3DCtoBitmap32(encData, decData : PByteArray; w,h : Integer);
var
   x,y,i,j : Integer;
   bits, offset : Cardinal;
   temp, alphamask : PByte;
   alphas : array[0..7] of Byte;
  procedure prepare;
  begin
     alphas[0]:=temp^; Inc(temp);
     alphas[1]:=temp^; Inc(temp);
     alphamask:=temp; Inc(temp, 6);

     if (alphas[0] > alphas[1]) then begin
        alphas[2]:=(6*alphas[0]+1*alphas[1]+3) div 7;
        alphas[3]:=(5*alphas[0]+2*alphas[1]+3) div 7;
        alphas[4]:=(4*alphas[0]+3*alphas[1]+3) div 7;
        alphas[5]:=(3*alphas[0]+4*alphas[1]+3) div 7;
        alphas[6]:=(2*alphas[0]+5*alphas[1]+3) div 7;
        alphas[7]:=(1*alphas[0]+6*alphas[1]+3) div 7;
     end else begin
        alphas[2]:=(4*alphas[0]+1*alphas[1]+2) div 5;
        alphas[3]:=(3*alphas[0]+2*alphas[1]+2) div 5;
        alphas[4]:=(2*alphas[0]+3*alphas[1]+2) div 5;
        alphas[5]:=(1*alphas[0]+4*alphas[1]+2) div 5;
        alphas[6]:=0;
        alphas[7]:=$FF;
     end;
  end;

begin
   if not (Assigned(encData) and Assigned(decData)) then exit;

   temp:=PByte(encData);
   for y:=0 to ((h+3) div 4)-1 do begin
      for x:=0 to (w div 4)-1 do begin
         prepare;

         bits:=PCardinal(alphamask)^;
         for j:=0 to 1 do begin
            for i:=0 to 3 do begin
               if (((4*x+i)<w) and ((4*y+j)<h)) then begin
                  offset:=((4*y+j)*w+(4*x+i))*4;
                  decData[Offset]:=alphas[bits and 7];
                  decData[Offset+1]:=decData[Offset];
                  decData[Offset+2]:=decData[Offset];
               end;
               bits:=bits shr 3;
            end;
         end;

         Inc(alphamask, 3);
         bits:=PCardinal(alphamask)^;
         for j:=2 to 3 do begin
            for i:=0 to 3 do begin
               if (((4*x+i)<w) and ((4*y+j)<h)) then begin
                  offset:=((4*y+j)*w+(4*x+i))*4;
                  decData[offset]:=alphas[bits and 7];
                  decData[Offset+1]:=decData[Offset];
                  decData[Offset+2]:=decData[Offset];
               end;
               bits:=bits shr 3;
            end;
         end;

         prepare;

         bits:=PCardinal(alphamask)^;
         for j:=0 to 1 do begin
            for i:=0 to 3 do begin
               if (((4*x+i)<w) and ((4*y+j)<h)) then begin
                  offset:=((4*y+j)*w+(4*x+i))*4;
                  decData[Offset+3]:=alphas[bits and 7];
               end;
               bits:=bits shr 3;
            end;
         end;

         Inc(alphamask, 3);
         bits:=PCardinal(alphamask)^;
         for j:=2 to 3 do begin
            for i:=0 to 3 do begin
               if (((4*x+i)<w) and ((4*y+j)<h)) then begin
                  offset:=((4*y+j)*w+(4*x+i))*4;
                  decData[offset+3]:=alphas[bits and 7];
               end;
               bits:=bits shr 3;
            end;
         end;
      end;
   end;
end;


////////////////////////////////////////////////////////////////////////////////
//      ENCODER

type
  TSSEData=packed record
  //DXTC
    Zero,
    b_1,
    b_2,
    b_7,
    w_1,
    w_2,
    w_div_2,
    w_div_3,
    w_div_7,
    w_div_14,
    qw_565mask,

    dw_0000000f,
    dw_000000f0,
    dw_00000f00,
    dw_0000f000,

    w_66554400,
    w_11223300,

    d_alpha_m0,
    d_alpha_m1,
    d_alpha_m2,
    d_alpha_m3,
    d_alpha_m4,
    d_alpha_m5,
    d_alpha_m6,
    d_alpha_m7,

    ColorBlock0,
    ColorBlock1,
    ColorBlock2,
    ColorBlock3,
    Color0,
    Color1,
    Color2,
    Color3,
    Result:TSSEReg;
    procedure Init;
  end;
  PSSEData=^TSSEData;

procedure TSSEData.Init;
begin
  zero.SetDw(0);

  b_1.SetB(1);
  b_2.SetB(2);
  b_7.SetB(7);

  w_1.SetW(1);
  w_2.SetW(2);

  w_div_2.SetW($10000 div 2+1);
  w_div_3.SetW($10000 div 3+1);
  w_div_7.SetW($10000 div 7+1);
  w_div_14.SetW($10000 div 14+1);

  qw_565mask.SetQW($f8fcf8);

  dw_0000000f.SetDW($0000000f);
  dw_000000f0.SetDW($000000f0);
  dw_00000f00.SetDW($00000f00);
  dw_0000f000.SetDW($0000f000);

  w_66554400.SetW(6,6,5,5,4,4,0,0);
  w_11223300.SetW(1,1,2,2,3,3,0,0);

  d_alpha_m0.SetQW(7 shl (0*3));
  d_alpha_m1.SetQW(7 shl (1*3));
  d_alpha_m2.SetQW(7 shl (2*3));
  d_alpha_m3.SetQW(7 shl (3*3));
  d_alpha_m4.SetQW(7 shl (4*3));
  d_alpha_m5.SetQW(7 shl (5*3));
  d_alpha_m6.SetQW(7 shl (6*3));
  d_alpha_m7.SetQW(7 shl (7*3));
end;

var SSEData:PSSEData;
    SSEDataBuffer:TAlignedBuffer;

function ChechSSEAligned(inPtr:pointer;scanLineSizeBytes:integer):boolean;
begin
  result:=((cardinal(inPtr)and $f)=0)and((scanLineSizeBytes and $f)=0);
end;

type
  TExtractProc=procedure(colorBlock,inPtr:pointer;scanLineSizeBytes:integer);

procedure ExtractBlock32bitAligned(colorBlock,inPtr:pointer;scanLineSizeBytes:integer);//inPtr es width oszthato 16-al
asm                  //eax   edx                ecx
  movdqa xmm0, [edx]
  movdqa [eax+ 0], xmm0
  movdqa xmm1, [edx+ecx] // + 4 * width
  movdqa [eax+16], xmm1
  movdqa xmm2, [edx+ecx*2] // + 8 * width
  add edx, ecx
  movdqa [eax+32], xmm2
  movdqa xmm3, [edx+ecx*2] // + 12 * width
  movdqa [eax+48], xmm3
end;

procedure ExtractBlock32bitUnaligned(colorBlock,inPtr:pointer;scanLineSizeBytes:integer);
asm                  //eax   edx                ecx
  movdqu xmm0, [edx]
  movdqa [eax+ 0], xmm0
  movdqu xmm1, [edx+ecx] // + 4 * width
  movdqa [eax+16], xmm1
  movdqu xmm2, [edx+ecx*2] // + 8 * width
  add edx, ecx
  movdqa [eax+32], xmm2
  movdqu xmm3, [edx+ecx*2] // + 12 * width
  movdqa [eax+48], xmm3
end;

procedure ExtractBlock24bit(colorBlock,inPtr:pointer;scanLineSizeBytes:integer);
var y:integer;
begin
  for y:=0 to 3 do begin
    PCardinal(cardinal(colorBlock)+ 0)^:=pword(integer(inPtr)+0)^+pbyte(integer(inPtr)+0+2)^shl 16 or $FF000000;
    PCardinal(cardinal(colorBlock)+ 4)^:=pword(integer(inPtr)+3)^+pbyte(integer(inPtr)+3+2)^shl 16 or $FF000000;
    PCardinal(cardinal(colorBlock)+ 8)^:=pword(integer(inPtr)+6)^+pbyte(integer(inPtr)+6+2)^shl 16 or $FF000000;
    PCardinal(cardinal(colorBlock)+12)^:=pword(integer(inPtr)+9)^+pbyte(integer(inPtr)+9+2)^shl 16 or $FF000000;
    inPtr:=pointer(integer(inPtr)+scanLineSizeBytes);
    colorBlock:=pointer(integer(colorBlock)+16);
  end;
end;

procedure ExtractBlock16bit(colorBlock,inPtr:pointer;scanLineSizeBytes:integer);
var y:integer;tff,tLine:cardinal;
begin
  for y:=0 to 3 do begin
    tLine:=pcardinal(integer(inPtr)+0)^;
    tff:=tLine and $ff;PCardinal(cardinal(colorBlock)+ 0)^:=tLine shl 16 or tff or tff shl 8;tLine:=tLine shr 16;
    tff:=tLine and $ff;PCardinal(cardinal(colorBlock)+ 4)^:=tLine shl 16 or tff or tff shl 8;
    tLine:=pcardinal(integer(inPtr)+4)^;
    tff:=tLine and $ff;PCardinal(cardinal(colorBlock)+ 8)^:=tLine shl 16 or tff or tff shl 8;tLine:=tLine shr 16;
    tff:=tLine and $ff;PCardinal(cardinal(colorBlock)+12)^:=tLine shl 16 or tff or tff shl 8;
    inPtr:=pointer(integer(inPtr)+scanLineSizeBytes);
    colorBlock:=pointer(integer(colorBlock)+16);
  end;
end;

procedure ExtractBlock8bit(colorBlock,inPtr:pointer;scanLineSizeBytes:integer);
var y:integer;tLine,t:cardinal;
begin
  for y:=0 to 3 do begin
    tLine:=pCardinal(integer(inPtr)+0)^;
    t:=tLine and $ff;PCardinal(cardinal(colorBlock)+ 0)^:=t or t shl 8 or t shl 16 or $FF000000;tLine:=tLine shr 8;
    t:=tLine and $ff;PCardinal(cardinal(colorBlock)+ 0)^:=t or t shl 8 or t shl 16 or $FF000000;tLine:=tLine shr 8;
    t:=tLine and $ff;PCardinal(cardinal(colorBlock)+ 0)^:=t or t shl 8 or t shl 16 or $FF000000;tLine:=tLine shr 8;
    t:=tLine and $ff;PCardinal(cardinal(colorBlock)+ 0)^:=t or t shl 8 or t shl 16 or $FF000000;
    inPtr:=pointer(integer(inPtr)+scanLineSizeBytes);
    colorBlock:=pointer(integer(colorBlock)+16);
  end;
end;

procedure ExtractBlockUnsafe(colorBlock,inPtr:pointer;scanLineSizeBytes:integer;pixelSizeBytes,Width,Height:integer);
type tb3=array[0..2]of byte;pb3=^tb3;
var buf:array[0..16*4-1]of byte;
    blockWidthMax,blockHeightMax:integer;

  procedure doit(x,y:integer);
  var s,d:pointer;
  begin
    if x>BlockWidthMax then x:=BlockWidthMax;
    if y>BlockHeightMax then y:=BlockHeightMax;
    s:=pointer(integer(inPtr)+y*scanLineSizeBytes+x*pixelSizeBytes);
    d:=@buf[(y shl 2+x)*pixelSizeBytes];
    case pixelSizeBytes of
      4:PCardinal(d)^:=pcardinal(s)^;
      3:pb3(d)^:=pb3(s)^;
      2:PWord(d)^:=pword(s)^;
      else PByte(d)^:=PByte(s)^;
    end;
  end;

var y,x:integer;
begin
  blockWidthMax:=(Width-1)and 3;
  blockHeightMax:=(Height-1)and 3;

  for y:=0 to 3 do for x:=0 to 3 do
    doit(x,y);

  case pixelSizeBytes of
    4:ExtractBlock32bitUnaligned(colorBlock,@buf,pixelSizeBytes shl 2);
    3:ExtractBlock24bit(colorBlock,@buf,pixelSizeBytes shl 2);
    2:ExtractBlock16bit(colorBlock,@buf,pixelSizeBytes shl 2);
    else ExtractBlock8bit(colorBlock,@buf,pixelSizeBytes shl 2);
  end;
end;


const
  INSET_SHIFT=4;

procedure GetMinMaxColors(colorBlock:pointer;var minColor,maxColor:cardinal);
asm                     //eax                edx          ecx
  // get bounding box
  movdqa xmm0, [eax+ 0]
  movdqa xmm1, [eax+ 0]
  pminub xmm0, [eax+16]
  pmaxub xmm1, [eax+16]
  pminub xmm0, [eax+32]
  pmaxub xmm1, [eax+32]
  pminub xmm0, [eax+48]
  pmaxub xmm1, [eax+48]
  pshufd xmm3, xmm0, SHUFFLE_2323
  pshufd xmm4, xmm1, SHUFFLE_2323
  pminub xmm0, xmm3                      mov eax,SSEData  //load consts
  pmaxub xmm1, xmm4
  pshuflw xmm6, xmm0, SHUFFLE_2323
  pshuflw xmm7, xmm1, SHUFFLE_2323
  pminub xmm0, xmm6
  pmaxub xmm1, xmm7
  // inset the bounding box
  punpcklbw xmm0, TSSEData(eax).Zero
  punpcklbw xmm1, TSSEData(eax).Zero
  movdqa xmm2, xmm1
  psubw xmm2, xmm0
  psrlw xmm2, INSET_SHIFT
  paddw xmm0, xmm2
  psubw xmm1, xmm2
  packuswb xmm0, xmm0
  packuswb xmm1, xmm1
  // store bounding box extents
  movd [edx], xmm0
  movd [ecx], xmm1
end;

var
  globalOutData:pointer;

procedure EmitColor(minColor:cardinal);
asm
  movzx edx,al
  shr edx,3
  movzx ecx,ax
  shr ecx,8+2
  shl ecx,5
  or edx,ecx
  shr eax,19
  shl eax,11
  or eax,edx
  mov ecx,globalOutData
  mov [ecx],ax
  add ecx,2
  mov globalOutData,ecx
end;

procedure EmitColorIndices4(colorBlock:pointer;minColor,maxColor:cardinal);
asm                      //eax                edx      ecx
  push esi mov esi, SSEData //constants

  pxor xmm7, xmm7
  movdqa TSSEData(esi).result, xmm7
  movd xmm0, ecx //maxColor
  pand xmm0, TSSEData(esi).qw_565Mask
  punpcklbw xmm0, xmm7
  pshuflw xmm4, xmm0, SHUFFLE_0323
  pshuflw xmm5, xmm0, SHUFFLE_3133
  psrlw xmm4, 5
  psrlw xmm5, 6
  por xmm0, xmm4
  por xmm0, xmm5
  movd xmm1, edx //minColor
  pand xmm1, TSSEData(esi).qw_565Mask
  punpcklbw xmm1, xmm7
  pshuflw xmm4, xmm1, SHUFFLE_0323
  pshuflw xmm5, xmm1, SHUFFLE_3133
  psrlw xmm4, 5
  psrlw xmm5, 6
  por xmm1, xmm4
  por xmm1, xmm5
  movdqa xmm2, xmm0
  packuswb xmm2, xmm7
  pshufd xmm2, xmm2, SHUFFLE_0101
  movdqa TSSEData(esi).color0, xmm2
  movdqa xmm6, xmm0
  paddw xmm6, xmm0
  paddw xmm6, xmm1
  pmulhw xmm6, TSSEData(esi).w_div_3
  packuswb xmm6, xmm7
  pshufd xmm6, xmm6, SHUFFLE_0101
  movdqa TSSEData(esi).color2, xmm6
  movdqa xmm3, xmm1
  packuswb xmm3, xmm7
  pshufd xmm3, xmm3, SHUFFLE_0101
  movdqa TSSEData(esi).color1, xmm3
  paddw xmm1, xmm1
  paddw xmm0, xmm1
  pmulhw xmm0, TSSEData(esi).w_div_3
  packuswb xmm0, xmm7
  pshufd xmm0, xmm0, SHUFFLE_0101
  movdqa TSSEData(esi).color3, xmm0
  mov ecx, 32
@@loop1: // iterates 2 times
  movq xmm3, qword ptr [eax+ecx+0]
  pshufd xmm3, xmm3, SHUFFLE_0213
  movq xmm5, qword ptr [eax+ecx+8]
  pshufd xmm5, xmm5, SHUFFLE_0213
  movdqa xmm0, xmm3
  movdqa xmm6, xmm5
  psadbw xmm0, TSSEData(esi).color0
  psadbw xmm6, TSSEData(esi).color0
  packssdw xmm0, xmm6
  movdqa xmm1, xmm3
  movdqa xmm6, xmm5
  psadbw xmm1, TSSEData(esi).color1
  psadbw xmm6, TSSEData(esi).color1
  packssdw xmm1, xmm6
  movdqa xmm2, xmm3
  movdqa xmm6, xmm5
  psadbw xmm2, TSSEData(esi).color2
  psadbw xmm6, TSSEData(esi).color2
  packssdw xmm2, xmm6
  psadbw xmm3, TSSEData(esi).color3
  psadbw xmm5, TSSEData(esi).color3
  packssdw xmm3, xmm5
  movq xmm4, qword ptr [eax+ecx+16]
  pshufd xmm4, xmm4, SHUFFLE_0213
  movq xmm5, qword ptr [eax+ecx+24]
  pshufd xmm5, xmm5, SHUFFLE_0213
  movdqa xmm6, xmm4
  movdqa xmm7, xmm5
  psadbw xmm6, TSSEData(esi).color0
  psadbw xmm7, TSSEData(esi).color0
  packssdw xmm6, xmm7
  packssdw xmm0, xmm6 // d0
  movdqa xmm6, xmm4
  movdqa xmm7, xmm5
  psadbw xmm6, TSSEData(esi).color1
  psadbw xmm7, TSSEData(esi).color1
  packssdw xmm6, xmm7
  packssdw xmm1, xmm6 // d1
  movdqa xmm6, xmm4
  movdqa xmm7, xmm5
  psadbw xmm6, TSSEData(esi).color2
  psadbw xmm7, TSSEData(esi).color2
  packssdw xmm6, xmm7
  packssdw xmm2, xmm6 // d2
  psadbw xmm4, TSSEData(esi).color3
  psadbw xmm5, TSSEData(esi).color3
  packssdw xmm4, xmm5
  packssdw xmm3, xmm4 // d3
  movdqa xmm7, TSSEData(esi).result
  pslld xmm7, 16
  movdqa xmm4, xmm0
  movdqa xmm5, xmm1
  pcmpgtw xmm0, xmm3 // b0
  pcmpgtw xmm1, xmm2 // b1
  pcmpgtw xmm4, xmm2 // b2
  pcmpgtw xmm5, xmm3 // b3
  pcmpgtw xmm2, xmm3 // b4
  pand xmm4, xmm1 // x0
  pand xmm5, xmm0 // x1
  pand xmm2, xmm0 // x2
  por xmm4, xmm5
  pand xmm2, TSSEData(esi).w_1
  pand xmm4, TSSEData(esi).w_2
  por xmm2, xmm4
  pshufd xmm5, xmm2, SHUFFLE_2301
  punpcklwd xmm2, TSSEData(esi).zero
  punpcklwd xmm5, TSSEData(esi).zero
  pslld xmm5, 8
  por xmm7, xmm5
  por xmm7, xmm2
  movdqa TSSEData(esi).result, xmm7
  sub ecx, 32
  jge @@loop1
  mov eax, globalOutData
  pshufd xmm4, xmm7, SHUFFLE_1230
  pshufd xmm5, xmm7, SHUFFLE_2301
  pshufd xmm6, xmm7, SHUFFLE_3012
  pslld xmm4, 2
  pslld xmm5, 4
  pslld xmm6, 6
  por xmm7, xmm4
  por xmm7, xmm5
  por xmm7, xmm6
  movd dword ptr [eax], xmm7
  add eax,4
  mov globalOutData,eax

  pop esi
end;

{procedure Finalize1BitAlpha(colorblock:PCardinal);
var newcode,code,i:Cardinal;
begin
  newcode:=0;
  code:=pcardinal(cardinal(globalOutData)-4)^;
  for i:=0 to 15 do begin
    newcode:=newcode shr 2;
    if colorblock^>=$80000000 then
      case code and 3 of
        1:newcode:=newcode or   $40000000;
        2,3:newcode:=newcode or $80000000;
      end else
        newcode:=newcode or     $C0000000;
    code:=code shr 2;
    inc(colorblock)
  end;
  pcardinal(cardinal(globalOutData)-4)^:=newcode;
end;}

procedure Finalize1BitAlpha(colorblock:PCardinal);
asm
  pxor xmm7, xmm7
  movdqa xmm0,[eax+  0]
  movdqa xmm1,[eax+ 16]
  movdqa xmm2,[eax+ 32]
  movdqa xmm3,[eax+ 48]
  psrld xmm0, 24
  psrld xmm1, 24
  psrld xmm2, 24
  psrld xmm3, 24
  packusdw xmm0,xmm1
  packusdw xmm2,xmm3
  pmovmskb eax,xmm0
  pmovmskb edx,xmm2
  shl edx,16
    ;mov ecx,globalOutData
  or eax,edx
    ;sub ecx,4
  xor eax,$55555555

  mov edx,[ecx]
  not edx
  and edx,$AAAAAAAA
  shr edx,1
  or edx,$AAAAAAAA
  and [ecx],edx //and mask

  or [ecx],eax
  shl eax,1
  or [ecx],eax

end;

procedure Emit4BitAlpha(colorblock:PCardinal);
asm
  movdqa xmm0,[eax+ 0]
  movdqa xmm1,[eax+16]
  movdqa xmm2,[eax+32]
  movdqa xmm3,[eax+48]
  psrld xmm0,28
  psrld xmm1,28
  psrld xmm2,28
  psrld xmm3,28
  packssdw xmm0,xmm1
  packssdw xmm2,xmm3
  packuswb xmm0,xmm2

  movdqa xmm1,xmm0
  movdqa xmm2,xmm0
  movdqa xmm3,xmm0

  psrld xmm1,4
  psrld xmm2,8          mov edx, SSEData //constants
  psrld xmm3,12

  pand xmm0, TSSEData(edx).dw_0000000f
  pand xmm1, TSSEData(edx).dw_000000f0
  pand xmm2, TSSEData(edx).dw_00000f00
  pand xmm3, TSSEData(edx).dw_0000f000

  mov eax,globalOutData

  por xmm0,xmm1
  por xmm2,xmm3
  por xmm0,xmm2

  packusdw xmm0,xmm1

  movq qword ptr [eax], xmm0
  add eax,8
  mov globalOutData,eax

end;

procedure EmitByte(a:cardinal);
asm
  mov ecx,globalOutData
  mov [ecx],al
  inc globalOutData
end;

procedure _Emit8bitIndices(colorBlock{unused}:pointer;minAlpha,maxAlpha:cardinal);//bemeno xmm0,xmm6,4,5
asm                      //eax                edx      ecx
//  movzx ecx, maxAlpha
  movd xmm5, ecx
  pshuflw xmm5, xmm5, SHUFFLE_0000       mov eax, SSEData
  pshufd xmm5, xmm5, SHUFFLE_0000
  movdqa xmm7, xmm5
//  movzx edx, minAlpha
  movd xmm2, edx
  pshuflw xmm2, xmm2, SHUFFLE_0000
  pshufd xmm2, xmm2, SHUFFLE_0000
  movdqa xmm3, xmm2
  movdqa xmm4, xmm5
  psubw xmm4, xmm2
  pmulhw xmm4, TSSEData(eax).w_div_14
  movdqa xmm1, xmm2
  paddw xmm1, xmm4
  packuswb xmm1, xmm1 // ab1
  pmullw xmm5, TSSEData(eax).w_66554400
  pmullw xmm7, TSSEData(eax).w_11223300
  pmullw xmm2, TSSEData(eax).w_11223300
  pmullw xmm3, TSSEData(eax).w_66554400
  paddw xmm5, xmm2
  paddw xmm7, xmm3
  pmulhw xmm5, TSSEData(eax).w_div_7
  pmulhw xmm7, TSSEData(eax).w_div_7
  paddw xmm5, xmm4
  paddw xmm7, xmm4
  pshufd xmm2, xmm5, SHUFFLE_0000
  pshufd xmm3, xmm5, SHUFFLE_1111
  pshufd xmm4, xmm5, SHUFFLE_2222
  packuswb xmm2, xmm2 // ab2
  packuswb xmm3, xmm3 // ab3
  packuswb xmm4, xmm4 // ab4
  packuswb xmm0, xmm6 // alpha values
  pshufd xmm5, xmm7, SHUFFLE_2222
  pshufd xmm6, xmm7, SHUFFLE_1111
  pshufd xmm7, xmm7, SHUFFLE_0000
  packuswb xmm5, xmm5 // ab5
  packuswb xmm6, xmm6 // ab6
  packuswb xmm7, xmm7 // ab7
  pminub xmm1, xmm0
  pminub xmm2, xmm0
  pminub xmm3, xmm0
  pcmpeqb xmm1, xmm0
  pcmpeqb xmm2, xmm0
  pcmpeqb xmm3, xmm0
  pminub xmm4, xmm0
  pminub xmm5, xmm0
  pminub xmm6, xmm0
  pminub xmm7, xmm0
  pcmpeqb xmm4, xmm0
  pcmpeqb xmm5, xmm0
  pcmpeqb xmm6, xmm0
  pcmpeqb xmm7, xmm0
  pand xmm1, TSSEData(eax).b_1
  pand xmm2, TSSEData(eax).b_1
  pand xmm3, TSSEData(eax).b_1
  pand xmm4, TSSEData(eax).b_1
  pand xmm5, TSSEData(eax).b_1
  pand xmm6, TSSEData(eax).b_1
  pand xmm7, TSSEData(eax).b_1
  movdqa xmm0, TSSEData(eax).b_1
  paddusb xmm0, xmm1
  paddusb xmm2, xmm3
  paddusb xmm4, xmm5
  paddusb xmm6, xmm7
  paddusb xmm0, xmm2
  paddusb xmm4, xmm6
  paddusb xmm0, xmm4
  pand xmm0, TSSEData(eax).b_7
  movdqa xmm1, TSSEData(eax).b_2
  pcmpgtb xmm1, xmm0
  pand xmm1, TSSEData(eax).b_1
  pxor xmm0, xmm1
  movdqa xmm1, xmm0
  movdqa xmm2, xmm0
  movdqa xmm3, xmm0
  movdqa xmm4, xmm0
  movdqa xmm5, xmm0
  movdqa xmm6, xmm0
  movdqa xmm7, xmm0
  psrlq xmm1, 8- 3
  psrlq xmm2, 16- 6
  psrlq xmm3, 24- 9
  psrlq xmm4, 32-12
  psrlq xmm5, 40-15
  psrlq xmm6, 48-18
  psrlq xmm7, 56-21
  pand xmm0, TSSEData(eax).d_alpha_m0
  pand xmm1, TSSEData(eax).d_alpha_m1
  pand xmm2, TSSEData(eax).d_alpha_m2
  pand xmm3, TSSEData(eax).d_alpha_m3
  pand xmm4, TSSEData(eax).d_alpha_m4
  pand xmm5, TSSEData(eax).d_alpha_m5
  pand xmm6, TSSEData(eax).d_alpha_m6
  pand xmm7, TSSEData(eax).d_alpha_m7
  por xmm0, xmm1
  por xmm2, xmm3
  por xmm4, xmm5
  por xmm6, xmm7
  por xmm0, xmm2
  por xmm4, xmm6
  por xmm0, xmm4
  mov ecx, globalOutData
  movd [ecx+0], xmm0
  pshufd xmm1, xmm0, SHUFFLE_2301
  movd [ecx+3], xmm1
  add globalOutData,6
end;


procedure EmitAlphaIndices(colorBlock:pointer;minAlpha,maxAlpha:cardinal);
asm                     //eax                edx      ecx
  movdqa xmm0, [eax+ 0]
  movdqa xmm5, [eax+16]
  psrld xmm0, 24
  psrld xmm5, 24
  packuswb xmm0, xmm5
  movdqa xmm6, [eax+32]
  movdqa xmm4, [eax+48]
  psrld xmm6, 24
  psrld xmm4, 24
  packuswb xmm6, xmm4
  jmp _Emit8bitIndices
end;

procedure EmitClr0Indices(colorBlock:pointer;minAlpha,maxAlpha:cardinal);
asm                     //eax                edx      ecx
  movdqa xmm0, [eax+ 0]
  movdqa xmm5, [eax+16]
  pslld xmm0, 24
  pslld xmm5, 24
  psrld xmm0, 24
  psrld xmm5, 24
  packuswb xmm0, xmm5
  movdqa xmm6, [eax+32]
  movdqa xmm4, [eax+48]
  pslld xmm6, 24
  pslld xmm4, 24
  psrld xmm6, 24
  psrld xmm4, 24
  packuswb xmm6, xmm4
  jmp _Emit8bitIndices
end;

procedure EmitClr1Indices(colorBlock:pointer;minAlpha,maxAlpha:cardinal);
asm                     //eax                edx      ecx
  movdqa xmm0, [eax+ 0]
  movdqa xmm5, [eax+16]
  pslld xmm0, 16
  pslld xmm5, 16
  psrld xmm0, 24
  psrld xmm5, 24
  packuswb xmm0, xmm5
  movdqa xmm6, [eax+32]
  movdqa xmm4, [eax+48]
  pslld xmm6, 16
  pslld xmm4, 16
  psrld xmm6, 24
  psrld xmm4, 24
  packuswb xmm6, xmm4
  jmp _Emit8bitIndices
end;

procedure EmitClr2Indices(colorBlock:pointer;minAlpha,maxAlpha:cardinal);
asm                     //eax                edx      ecx
  movdqa xmm0, [eax+ 0]
  movdqa xmm5, [eax+16]
  pslld xmm0, 8
  pslld xmm5, 8
  psrld xmm0, 24
  psrld xmm5, 24
  packuswb xmm0, xmm5
  movdqa xmm6, [eax+32]
  movdqa xmm4, [eax+48]
  pslld xmm6, 8
  pslld xmm4, 8
  psrld xmm6, 24
  psrld xmm4, 24
  packuswb xmm6, xmm4
  jmp _Emit8bitIndices
end;

////////////////////////////////////////////////////////////////////////////////
//      INTERFACE

function DXTNearest(const size:integer):integer;
begin
  result:=(size+3)and not 3;
end;

function DXTBlockCount(const size:integer):integer;
begin
  result:=DXTNearest(size)shr 2;
end;

function DXTBlockSize(const Version:TDxtVersion):integer;
begin
  case version of
    dxt1:result:=8;
    else result:=16;
  end;
end;

function DXTCompressedSize(const Version:TDXTVersion;const width,height:integer):integer;
begin
  result:=DXTBlockSize(Version)*DXTBlockCount(width)*DXTBlockCount(height);
end;

function DXTDecode(const version:TDXTVersion;const data:TBytes;const width,height:integer):TBitmap;
var trans:boolean;
begin
  result:=nil;
  if length(data)<DXTCompressedSize(version,width,height) then exit;

  result:=TBitmap.Create;
  result.PixelFormat:=pf32bit;
  result.Width:=DXTNearest(width);
  result.Height:=height;

  trans:=false;
  case version of
    dxt1:begin
      DecodeDXT1toBitmap32(@data[0],Result.ScanLine[Result.Height-1],Result.Width,Result.Height,trans);
      if not trans then
        result.PixelFormat:=pf24bit;
    end;
    dxt3:DecodeDXT3toBitmap32(@data[0],result.ScanLine[Result.Height-1],Result.Width,Result.Height);
    dxt5:DecodeDXT5toBitmap32(@data[0],result.ScanLine[Result.Height-1],Result.Width,Result.Height);
    dxt3dc:DecodeDXT3DCtoBitmap32(@data[0],result.ScanLine[Result.Height-1],Result.Width,Result.Height);
  end;

  result.Width:=width;
end;

var
  globalColorMin,
  globalColorMax:cardinal;

procedure ProcessDXT1;
begin
  GetMinMaxColors(@SSEData.ColorBlock0,globalColorMin,globalColorMax);
  if(globalColorMin<$80000000)then begin
    EmitColor(globalColorMin);EmitColor(globalColorMax);
    EmitColorIndices4(@SSEData.ColorBlock0,globalColorMax,globalColorMin);
    Finalize1BitAlpha(@SSEData.ColorBlock0);
  end else begin
    EmitColor(globalColorMax);EmitColor(globalColorMin);
    EmitColorIndices4(@SSEData.ColorBlock0,globalColorMin,globalColorMax);
  end;
end;

procedure ProcessDXT3;
begin
  GetMinMaxColors(@SSEData.ColorBlock0,globalColorMin,globalColorMax);
  Emit4bitAlpha(@SSEData.ColorBlock0);
  EmitColor(globalColorMax);EmitColor(globalColorMin);
  EmitColorIndices4(@SSEData.ColorBlock0,globalColorMin,globalColorMax);
end;

procedure ProcessDXT5;
begin
  GetMinMaxColors(@SSEData.ColorBlock0,globalColorMin,globalColorMax);
  EmitByte(globalColorMax shr 24);EmitByte(globalColorMin shr 24);
  EmitAlphaIndices(@SSEData.ColorBlock0,globalColorMin shr 24,globalColorMax shr 24);
  EmitColor(globalColorMax);EmitColor(globalColorMin);
  EmitColorIndices4(@SSEData.ColorBlock0,globalColorMin,globalColorMax);
end;

procedure ProcessDXT3DC;
begin
  GetMinMaxColors(@SSEData.ColorBlock0,globalColorMin,globalColorMax);
  EmitByte(globalColorMax and $ff);EmitByte(globalColorMin and $ff);
  EmitClr0Indices(@SSEData.ColorBlock0,globalColorMin and $ff,globalColorMax and $ff);
  EmitByte(globalColorMax shr 24);EmitByte(globalColorMin shr 24);
  EmitAlphaIndices(@SSEData.ColorBlock0,globalColorMin shr 24,globalColorMax shr 24);
end;

function DXTEncode(const version:TDXTVersion;const bmp:TBitmap):TBytes;
var x,y,xc,yc:integer;
    dWidth,dHeight,Width,Height:integer;
    srcLine,src:Pointer;
    lineSizeBytes,lineSizeBytes4,
    pixelSizeBytes,pixelSizeBytes4:integer;
    unsafeX,unsafeY:boolean;

    ExtractProc:TExtractProc;
    ProcessProc:TProcedure;

    bSmall:TBitmap;
begin
  setlength(result,0);
  if bmp.Empty then exit;

  if(bmp.Width<4)or(bmp.Height<4)then begin
    bSmall:=bmp.ResizeF(Max(4,bmp.width),Max(4,bmp.height),rfLinear);
    Result:=DXTEncode(version,bSmall);
    bSmall.Free;
    exit;
  end;

  case version of
    dxt1:ProcessProc:=ProcessDXT1;
    dxt3:ProcessProc:=ProcessDXT3;
    dxt5:ProcessProc:=ProcessDXT5;
    dxt3dc:ProcessProc:=ProcessDXT3DC;
    else ProcessProc:=nil;
  end;

  width:=bmp.Width;
  height:=bmp.Height;
  dWidth:=DXTNearest(width);
  dHeight:=DXTNearest(height);

  unsafeX:=bmp.Width<>dWidth;
  unsafeY:=bmp.Height<>dHeight;
  xc:=Width shr 2;
  yc:=Height shr 2;

  pixelSizeBytes:=bmp.PixelSize;
  pixelSizeBytes4:=pixelSizeBytes shl 2;
  lineSizeBytes:=bmp.ScanLineSize;
  lineSizeBytes4:=lineSizeBytes shl 2;
  srcLine:=bmp.ScanLine[bmp.Height-1];

  case pixelSizeBytes of
    1:ExtractProc:=ExtractBlock8bit;
    2:ExtractProc:=ExtractBlock16bit;
    3:ExtractProc:=ExtractBlock24bit;
    4:if ChechSSEAligned(srcLine,lineSizeBytes)then ExtractProc:=ExtractBlock32bitAligned
                                               else ExtractProc:=ExtractBlock32bitUnaligned;
    else ExtractProc:=nil;
  end;

  SetLength(Result,DXTCompressedSize(version,Width,Height));
  globalOutData:=@Result[0];

  for y:=0 to yc-1 do begin
    src:=srcLine;
    for x:=0 to xc-1 do begin
      ExtractProc(@SSEData.ColorBlock0,src,lineSizeBytes);ProcessProc;
      src:=pointer(integer(src)+pixelSizeBytes4);
    end;
    if unsafeX then begin
      ExtractBlockUnsafe(@SSEData.ColorBlock0,src,lineSizeBytes,pixelSizeBytes,Width,Height);ProcessProc;
    end;
    srcLine:=pointer(integer(srcLine)+lineSizeBytes4);
  end;
  if unsafeY then begin
    src:=srcLine;
    for x:=0 to xc do begin
      ExtractBlockUnsafe(@SSEData.ColorBlock0,src,lineSizeBytes,pixelSizeBytes,Width,Height);ProcessProc;
      src:=pointer(integer(src)+pixelSizeBytes4);
    end;
  end;
end;

initialization
  //allocate sse constants
  SSEDataBuffer.Alloc(SizeOf(TSSEData),16);
  SSEData:=SSEDataBuffer.Address;
  SSEData.Init;
finalization
end.
