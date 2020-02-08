unit HetJpeg2;//hetpropertyrig het.stream het.bitmap
interface
uses windows, sysutils, classes, graphics, math,het.Utils, het.Stream, typinfo,
  het.arrays, dialogs;

{$DEFINE EXPORTTESTDATA}

{$IFDEF EXPORTTESTDATA}
const TESTDATAPath='c:\work9\gpjp\';
{$ENDIF}

// !!!!!! Important: SSE unit must be the 1st in project.dpr uses list (16byte align)!!!!!!

//var DCAbsMax,ACAbsMax:integer;

{ $DEFINE hjpProfiling}  //measuring execution times

////////////////////////////////////////////////////////////////////////////////
///
///  usage improvements
///  - 1..4 color components, and normalmap support using only Y components
///  - alpha channel for YUV420 data coded as Y component
///
///  speed optimizations
///  - sse2 (+badly unoptimized x86 for compatibility)
///  - minimal sse register waste (pixel data in sseBytes, coeffs in sseWords)
///  - all the operations done using a single cache way (at least on core2+)
///     (except image access, compressed data access)
///  - yuv<->rgb using RTC with 8bit accuracy (2 bit rounding error on UV, but fast)
///  - yuv420 stretching for 16x16 block (not the whole image) {better memory locality}
///  - half-quantization near zero is ignored, using trunc instead
///  - all in one DCT+Flip+DCT+Quant sse routines to minimize memory access
///      (slow instruction decoding but ram access is the bottleneck)
///  - (I)DCT table flip using only sse2
///  - only 1 flip per (i)dct, result matrix is transposed at the huffman pass.
///  - reduced resolution in IDCT based on the nonzero value count in the coeff matrix
///      (using 4x4, 2x2, 1x1 transform when possible. no quality loss, a bit more redundacy
///      caused by nonstandard zigzag table)
///  - zigzag coding located inside the huffman pass to reduce memory access
///  - huffman decoding is done by 3 lookup tables, not with slow 1bit reads.
///  - the number of leading zeroes in the huff code selects the corresponding table
///    (therefore all huff codes are inverted to get codes like -> 000000000001101101)
///  - buffer allocation and range checking done only once per huffman pass,
///      not on every single huffman codes

const
  HJPMagic:TMagic='HJP ';

type
  PHJPFrameHeader=^THJPFrameHeader;
  THJPFrameHeader=packed record
    Magic:TMagic;
    Width,Height:word;
    Components_delta:Byte;//0..2:Components 7:delta
    Quality_YUV:byte;{0..6.bit: qual 7.bit : YUV}
    datalen,crc{csak a header crc-je}:integer;

    procedure Setup(const AWidth,AHeight,AComponents:integer;const AQuality:byte;const AYUVMode:boolean;const ADelta:boolean);overload;
    procedure Setup(const ABmp:TBitmap;const AQuality:byte;const AYUVMode:boolean;const ADelta:boolean);overload;

    function GetYUV:boolean;procedure SetYUV(const Value:boolean);property YUV:boolean read getYUV write SetYUV;
    function GetDelta:boolean;procedure SetDelta(const Value:boolean);property Delta:boolean read getDelta write SetDelta;
    function GetQuality:byte;procedure SetQuality(const Value:byte);property Quality:byte read getQuality write SetQuality;
    function GetComponents:byte;procedure SetComponents(const Value:byte);property Components:byte read getComponents write SetComponents;

    procedure CalcCRC;
    function CheckCRC:boolean;
    function Valid:boolean;
    function FrameLen:integer;
  end;

procedure _Convert_BGRtoYUV(var color);
procedure _Convert_YUVtoBGR(var color);

function HJPTest(const bmp:TBitmap;const Quality:integer;const YUVmode:boolean):RawByteString;

function hjpEncode(const bmp:TBitmap;const Quality:integer;const YUVmode,IsDelta:boolean;var Buffer:RawByteString;var BufferPos:integer):boolean;overload;
function hjpEncode(const bmp:TBitmap;const Quality:integer;const YUVmode,IsDelta:boolean):RawByteString;overload;

function hjpDecode(var bmp:TBitmap;out Quality:integer;out YUVMode,IsDelta:boolean;const Buffer:RawByteString;var BufferPos:integer):boolean;overload
function hjpDecode(var bmp:TBitmap;out Quality:integer;out YUVMode,IsDelta:boolean;const Buffer:RawByteString):boolean;overload
function hjpDecode(var bmp:TBitmap;const Buffer:RawByteString):boolean;overload;


procedure HjpLoadFromStream(var bmp:TBitmap;const Stream:TStream);
procedure HjpSaveToStream(const bmp:TBitmap;const Stream:TStream;qual:integer;yuv:boolean);

procedure HjpLoadFromStr(var bmp:TBitmap;const Str:rawbytestring);
function HjpSaveToStr(const bmp:TBitmap;const qual:integer;yuv:boolean):RawByteString;

type
  TKeyFrameOption=(kfForced,kfAuto,kfDeltaIfPossible);
  TEncoderOptions=packed record
    Quality:byte;
    YUVMode:boolean;
    KeyFrameInterval:integer;
    AutomaticDeltaFrames:boolean;//only when keyframe is smaller than deltaframe
  end;
  PEncoderOptions=^TEncoderOptions;

  THJPCodec=class(TComponent)
  private
    FEncoderOptions:TEncoderOptions;
    FEncoderKeyFrame:TBitmap;
    FEncoderDiffFrame:TBitmap;
    FEncoderKeyFrameIndex:integer;
    FEncoderActFrameIndex:integer;

    FDecoderKeyFrame:TBitmap;
  public
    FDecoderActFrame:TBitmap;
  public
    destructor Destroy;override;
    function GetEncoderOptions:PEncoderOptions;
    property EncoderOptions:PEncoderOptions read GetEncoderOptions;
    procedure Encode(const ABmp:TBitmap;var ABuffer:RawByteString;var ABufferPos:integer);overload;
    function Encode(const ABmp:TBitmap):RawByteString;overload;
    procedure Encode(const IO:TIO;const ABmp:TBitmap);overload;

    function Decode(const ABuffer:RawByteString;var ABufferPos:integer):TBitmap;overload;
    function Decode(const ABuffer:RawByteString):TBitmap;overload;
{    function Decode(const IO:THetStream):TBitmap;overload;
    function DecodeFrameSize(const IO:THetStream):integer;
    function DecodeSkip(const IO:THetStream):boolean;}
  end;

  THJPFrames=class(TObject)
  private
    FData:RawByteString;
    FIndex:THetArray<integer>;
    FCodec:THJPCodec;
    lastFrame:Integer;
    FDecodedFrameChanged:boolean;
    function GetFrameCount: integer;
    function GetFrame(n:integer):rawbytestring;
  public
    Name:ansistring;
    constructor Create;
    destructor Destroy;override;
    procedure Clear;
    property Count:integer read GetFrameCount;
    procedure Append(const fr:RawByteString);overload;
    procedure Append(const b:TBitmap);overload;
    procedure LoadFromStr(const stream:RawByteString);
    function SaveToStr:RawByteString;
    procedure SaveToFile(const fn:string);
    function Decode(const n:integer):TBitmap;
    property Codec:THJPCodec read FCodec;
    property DecodedFrameChanged:boolean read FDecodedFrameChanged;
  end;

type
  TBlockW=array[0..7,0..7]of smallint;          TBlockB=array[0..7,0..7]of byte;
  PBlockW=^TBlockW;                             PBlockB=^TBlockB;
  TLinearBlockW=array[0..63]of smallint;        TLinearBlockB=array[0..63]of byte;
  PLinearBlockW=^TLinearBlockW;                 PLinearBlockB=^TLinearBlockW;

//Huffman types
type
  TBaseMaskTable=array[0..31{sign+cat shl 1}]of packed record base:smallint;mask:word end;

  THuffCodeRecord=packed record
    Code:word;
    Len,fullLen:byte;
  end;//4byte

  THuffCodeRecordArray=array[0..1023]of THuffCodeRecord;
  PHuffCodeRecordArray=^THuffCodeRecordArray;

  THuffLookupRecord=packed record
    basemaskID:byte;
    zcnt:byte;
    shift:byte;
    skip:byte;
  end;//4byte

  THuffLookupRecordArray=array[0..1023]of THuffLookupRecord;
  PHuffLookupRecordArray=^THuffLookupRecordArray;

  THuffDCLookup=record
    small:array[0..127]of THuffLookupRecord;
    medium:array[0..63]of THuffLookupRecord;//6bits 0
  end;//192 records, 768bytes

  THuffACLookup=record
    small:array[0..127]of THuffLookupRecord;
    medium:array[0..511]of THuffLookupRecord;
    big:array[0..255]of THuffLookupRecord;
  end;//896 records, 3584 bytes

  THuffDCCodes=array[0..11]of THuffCodeRecord;//48 bytes
  THuffACCodes=array[0..255]of THuffCodeRecord;//1024 byte

  THuffDecTable=packed record
    ACLookup:THuffACLookup;//768 bytes
    DCLookup:THuffDCLookup;//3584 bytes
  end; //full dec: 4352bytes

  THuffEncTable=packed record
    ACCodes:THuffACCodes;
    DCCodes:THuffDCCodes;//48 bytes
    //full enc: 1024+48
  end;

  THuffGlobal=packed record
    BaseMaskTable:TBaseMaskTable;
    zigzag,invzigzag:TLinearBlockB;
    Category:array[-1023..1023]of byte;
    Bitcode:array[-1023..1023]of word;
  end;

  THuffTables=packed record
    YDec,UVDec:THuffDecTable;
    Global:THuffGlobal;
    YEnc,UVEnc:THuffEncTable;
  end;

  TWorkArea=record
    Y:array[0..3]of TBlockW;//512
    UV:array[0..1]of TBlockW;//256
    A:array[0..3]of TBlockW;//512
    vars:packed record
      w256,
      w0_707106781,
      w0_382683433,
      w0_541196100,
      w1_306562965,
      w1_414213562,
      w1_847759065,
      w1_082392200,
      w_2_613125930:TSSEReg;
    end;
    QTEncY,QTEncU,QTEncV:TBlockW;//384
    QTDecY,QTDecU,QTDecV:TBlockW;//384
    HuffDiff:array[0..7]of smallint;
    HuffTables:THuffTables;

end;
  PWorkArea=^TWorkArea;

type
  T4x2RGBQuadArray=array[0..1,0..3]of TRgbQuad;

function HjpProfilingReport:string;

//shell

{type
  THJPImage=class(TBitmap)
  private
    FQuality:integer;
    FYUVMode:boolean;
    procedure SetQuality(const value:integer);
  public
    procedure LoadFromStream(stream : TStream); override;
    procedure SaveToStream(stream : TStream); override;
    property Quality:integer read FQuality write SetQuality;
    property YUVMode:boolean read FYUVMode write FYUVMode;
  end;                                                     }

implementation

uses het.Gfx;

////////////////////////////////////////////////////////////////////////////////
/// Legacy sse constants

type
  TSSEData=packed record //exactly 16 byte align
    Zero,
  //DCT
    w0_707106781,
    w0_382683433,
    w0_541196100,
    w1_306562965,
    w256,
    w1_414213562,
    w1_847759065,
    w_2_613125930,
    w1_082392200,
  //convert
    w_BtoY,w_GtoY,w_RtoY,
    w_BGRtoUU,w_BGRtoVV,
    w_007f,
    w_807f,
    b_80,
    b_7f,
    dw_80000000,
    w_lineAvgLastScale,
    w_00ff:TSSEReg;
    procedure init;
  end;
  PSSEData=^TSSEData;

var SSEData:PSSEData;
    SSEDataBuffer:TAlignedBuffer;

procedure TSSEData.Init;
begin
  zero.SetDw(0);
//DCT_PW
  w0_707106781.SetW(trunc(0.707106781*(1 shl 14)));
  w0_382683433.SetW(trunc(0.382683433*(1 shl 14)));
  w0_541196100.SetW(trunc(0.541196100*(1 shl 14)));
  w1_306562965.SetW(trunc(1.306562965*(1 shl 14)));
  w256.SetW(256);
//IDCT_PW
  w1_414213562.SetW(trunc(1.414213562*(1 shl 14)));
  w1_847759065.setW(trunc(1.847759065*(1 shl 14)));
  w_2_613125930.setW(trunc(-2.613125930*(1 shl 13{!!})));
  w1_082392200.setW(trunc(1.082392200*(1 shl 14)));

  //BGR <-> YUV
  //fast table
  w_BtoY.SetW( 37);
  w_GtoY.SetW(146);
  w_RtoY.SetW( 73);
  w_BGRtoUU.SetW(110, -73,-37,0,110, -73,-37,0);
  w_BGRtoVV.SetW(-18, -73, 91,0,-18, -73, 91,0);

  dw_80000000.SetDW(integer($80000000));
  w_lineAvgLastScale.setW(1,1,1,1,1,1,1,$101);
  w_007f.SetW($007F);
  w_807f.SetW($807F);
  w_00ff.SetW($00FF);
  b_80.SetB($80);
  b_7f.SetB($7f);
end;

////////////////////////////////////////////////////////////////////////////////
/// Utility stuff

{$IFDEF hjpProfiling}
type
  TProfile=record
    _LastTime:int64;
    count,time:Int64;
    procedure Start;
    procedure Stop;
    function report:string;
  end;

procedure TProfile.Start;
begin
  QueryPerformanceCounter(_LastTime);
end;

procedure TProfile.Stop;
var t,d:int64;
begin
  QueryPerformanceCounter(t);
  d:=t-_LastTime;
  inc(count);
  time:=time+d;
end;

function TProfile.report:string;
var f:Int64;
  function t2s(t:int64):string;
  begin result:=string(RightJ(' '+ansistring(inttostr(time*1000000 div f)),6));end;
begin
  QueryPerformanceFrequency(f);
  result:=string(rightj(' '+ansistring(inttostr(count)),6))+' '+t2s(time);
end;

type
  THjpProfile=class
    Encode,Decode,
    LoadPixels,StorePixels,
    DCT,IDCT,
    HuffEnc,HuffDec:TProfile;
    procedure Reset;
    function Report:string;
  end;

procedure THjpProfile.Reset;
begin
  InitInstance(self);
end;

function THjpProfile.Report:string;
begin
  result:='Encode  '+Encode.report+#13#10+
          'Load    '+LoadPixels.report+#13#10+
          'DCT     '+DCT.report+#13#10+
          'HuffEnc '+HuffEnc.report+#13#10+
          'HuffDec '+HuffDec.report+#13#10+
          'IDCT    '+Idct.report+#13#10+
          'Store   '+StorePixels.report+#13#10+
          'Decode  '+Decode.report+#13#10;
end;

var
  HjpProfile:THjpProfile;

function HjpProfilingReport:string;
begin
  result:=HjpProfile.Report;
end;

{$ELSE}

function HjpProfilingReport:string;
begin
  result:='Enable $hjpProfiling in source!';
end;

{$ENDIF}

procedure SetupConstants(var WA:TWorkArea);
begin with WA.vars do begin
  //dct
  w256.SetW(256);
  w0_707106781.SetW(trunc(0.707106781*(1 shl 14)));
  w0_382683433.SetW(trunc(0.382683433*(1 shl 14)));
  w0_541196100.SetW(trunc(0.541196100*(1 shl 14)));
  w1_306562965.SetW(trunc(1.306562965*(1 shl 14)));
  //idct
  w1_414213562.SetW(trunc(1.414213562*(1 shl 14)));
  w1_847759065.SetW(trunc(1.847759065*(1 shl 14)));
  w1_082392200.SetW(trunc(1.082392200*(1 shl 14)));
  w_2_613125930.SetW(trunc(-2.613125930*(1 shl 13{!!})));
end;end;

////////////////////////////////////////////////////////////////////////////////
/// Step1                Load/Store
///
/// Description:         Conversion between raw image and Step2 DCT/IDCT routines.
/// Supported formats:   Y, YA, BGR, YUV, BGRA, YUVA

//8bit -> Y[0]
procedure LoadPixels8x8_Y(WorkArea:PWorkArea;src:pointer;linesize:integer);var x,y:integer;p:PByte;
begin
  for y:=0 to 7 do begin
    p:=src;pInc(src,linesize);
    for x:=0 to 7 do begin WorkArea.Y[0,y,x]:=p^;pInc(p);end;
  end;
end;

procedure LoadPixels8x8_Y_SSE(WorkArea:PWorkArea;src:pointer;linesize:integer);
asm
  push esi
  sub eax,16            //destination
  mov esi,4             //loop counter
@@1:
  movlps xmm0,[edx]
  add edx,ecx
  movhps xmm0,[edx]
  add eax,16
  add edx,ecx
  sub esi,1
  movaps [eax],xmm0;
ja @@1
  pop esi
end;

procedure StorePixels8x8_Y(WorkArea:PWorkArea;dst:pointer;linesize:integer);var x,y:integer;p:PByte;
begin
  for y:=0 to 7 do begin
    p:=dst;pInc(dst,linesize);
    for x:=0 to 7 do begin p^:=WorkArea.Y[0,y,x];pInc(p);end;
  end;
end;

procedure StorePixels8x8_Y_SSE(WorkArea:PWorkArea;dst:pointer;linesize:integer);
asm
  push esi
  mov esi,4             //loop counter
@@1:
  movaps xmm0,[eax];
  add eax,16
  movlps [edx],xmm0
  add edx,ecx
  movhps [edx],xmm0
  add edx,ecx
  sub esi,1
ja @@1
  pop esi
end;

//16bit ->Y[0], Y[1]
procedure LoadPixels8x8_YA(WorkArea:PWorkArea;src:pointer;linesize:integer);var x,y:integer;p:pbyte;
begin
  for y:=0 to 7 do begin
    p:=src;pInc(src,linesize);
    for x:=0 to 7 do begin
      WorkArea.Y[0,y,x]:=p^;pInc(p);
      WorkArea.Y[1,y,x]:=p^;pInc(p);
    end;
  end;
end;

procedure LoadPixels8x8_YA_SSE(WorkArea:PWorkArea;src:pointer;linesize:integer);
asm
  push esi
  pcmpeqw xmm7,xmm7;
  sub eax,16            //destination
  psrlw xmm7,8; //$00ff
  mov esi,4             //loop counter
@@1:
  test edx,$f
  jz @@2
    movups xmm0,[edx];jmp @@3
@@2:movaps xmm0,[edx];
@@3:add edx,ecx
  test edx,$f
  jz @@2b
    movups xmm1,[edx];jmp @@3b
@@2b:movaps xmm1,[edx];
@@3b:
  //luma              //alpha
  movaps xmm2,xmm1;   movaps xmm3,xmm0
  pand xmm0,xmm7;     psrlw xmm3,8              ;add edx,ecx
  pand xmm2,xmm7;     psrlw xmm1,8              ;add eax,16
  packuswb xmm0,xmm2; packuswb xmm3,xmm1
  sub esi,1
  movaps [eax],xmm0;  movaps [eax+$80],xmm3;
ja @@1
  pop esi
end;

procedure StorePixels8x8_YA(WorkArea:PWorkArea;src:pointer;linesize:integer);var x,y:integer;p:pbyte;
begin
  for y:=0 to 7 do begin
    p:=src;pInc(src,linesize);
    for x:=0 to 7 do begin
      p^:=WorkArea.Y[0,y,x];pInc(p);
      p^:=WorkArea.Y[1,y,x];pInc(p);
    end;
  end;
end;

procedure StorePixels8x8_YA_SSE(WorkArea:PWorkArea;dst:pointer;linesize:integer);
asm
  push esi
  mov esi,4             //loop counter
@@1:
  movaps xmm0,[eax]    //luma
  movaps xmm1,[eax+$80]//alpha
  movaps xmm2,xmm0;
  add eax,16
  punpcklbw xmm0,xmm1
  punpckhbw xmm2,xmm1
  test edx,$f
  jnz @@un
     movaps [edx],xmm0;jmp @@done
@@un:movups [edx],xmm0;
@@done:add edx,ecx
  test edx,$f
  jnz @@un2
     movaps [edx],xmm2;jmp @@done2
@@un2:movups [edx],xmm2;
@@done2:add edx,ecx
  sub esi,1
ja @@1
  pop esi
end;

//24bit ->Y[0], Y[1], Y[2]
procedure LoadPixels8x8_BGR(WorkArea:PWorkArea;src:pointer;linesize:integer);var x,y:integer;p:PByte;
begin
  for y:=0 to 7 do begin
    p:=src;pInc(src,linesize);
    for x:=0 to 7 do begin
      WorkArea.Y[0,y,x]:=p^;pInc(p);
      WorkArea.Y[1,y,x]:=p^;pInc(p);
      WorkArea.Y[2,y,x]:=p^;pInc(p);
    end;
  end;
end;

procedure LoadPixels8x8_BGR_SSE(WorkArea:PWorkArea;src:pointer;linesize:integer);
asm
  push esi;push edi;push ebx;push ebp
  pcmpeqw xmm3,xmm3;
  mov ebp,esp
  sub eax,16            //destination
  sub ebp,4*16
  psrlw xmm3,8; //$00ff
  and ebp,$FFFFFFF0
  mov esi,4             //loop counter
@@1:
  add eax,16

  mov edi,[edx];                 ;mov ebx,[edx+12]
  mov dword([ebp+$00]),edi       ;mov dword([ebp+$10]),ebx
  mov edi,[edx+3];               ;mov ebx,[edx+12+3]
  mov dword([ebp+$04]),edi       ;mov dword([ebp+$14]),ebx
  mov edi,[edx+6];               ;mov ebx,[edx+12+6]
  mov dword([ebp+$08]),edi       ;mov dword([ebp+$18]),ebx
  mov edi,[edx+8];               ;mov ebx,[edx+12+8]
  shr edi,8;                     ;shr ebx,8
  mov dword([ebp+$0C]),edi       ;mov dword([ebp+$1C]),ebx
  movaps xmm4,[ebp+$00]          ;movaps xmm5,[ebp+$10];
  add edx,ecx

  mov edi,[edx];                 ;mov ebx,[edx+12]
  mov dword([ebp+$20]),edi       ;mov dword([ebp+$30]),ebx
  mov edi,[edx+3];               ;mov ebx,[edx+12+3]
  mov dword([ebp+$24]),edi       ;mov dword([ebp+$34]),ebx
  mov edi,[edx+6];               ;mov ebx,[edx+12+6]
  mov dword([ebp+$28]),edi       ;mov dword([ebp+$38]),ebx
  mov edi,[edx+8];               ;mov ebx,[edx+12+8]
  shr edi,8;                     ;shr ebx,8
  mov dword([ebp+$2C]),edi       ;mov dword([ebp+$3C]),ebx
  movaps xmm6,[ebp+$20]          ;movaps xmm7,[ebp+$30];
  add edx,ecx

  //xmm4,5,6,7 2 lines of ?rgb?rgb?rgb?rgb*2
  movaps xmm0,xmm4;     movaps xmm2,xmm5;
  pand xmm0,xmm3;       pand xmm2,xmm3;
  packuswb xmm0,xmm2  //rbrbrbrbrbrbrbrb

  movaps xmm1,xmm6;     movaps xmm2,xmm7;
  pand xmm1,xmm3;       pand xmm2,xmm3;
  packuswb xmm1,xmm2  //rbrbrbrbrbrbrbrb

  //xmm0,1 :2 lines of rbrbrbrb
  movaps xmm4,xmm0;     movaps xmm2,xmm1;
  pand xmm4,xmm3;       pand xmm2,xmm3;
  packuswb xmm4,xmm2;  //bbbbbbbbbbbbbbbbb
  psrlw xmm0,8          psrlw xmm1,8
  packuswb xmm0,xmm1   //rrrrrrrrrrrrrrrrr

  movaps [eax+ $00],xmm4;//blue
  movaps [eax+$100],xmm0;//red

  movaps xmm4,[ebp+$00]
  //xmm4,5,6,7 2 lines of ?rgb?rgb?rgb?rgb*2
  movaps xmm0,xmm4;     movaps xmm2,xmm5;
  psrlw xmm0,8;         psrlw xmm2,8;
  packuswb xmm0,xmm2  //?g?g?g?g?g?g?g?g

  movaps xmm1,xmm6;     movaps xmm2,xmm7;
  psrlw xmm1,8;         psrlw xmm2,8;
  packuswb xmm1,xmm2  //?g?g?g?g?g?g?g?g

  //xmm0,1 :2 lines of ?g?g?g?g?g?g?g?g
  pand xmm0,xmm3;       pand xmm1,xmm3
  packuswb xmm0,xmm1

  sub esi,1
  movaps [eax+$80],xmm0//green

  ja @@1
  pop ebp;pop ebx;pop edi;pop esi
end;

procedure StorePixels8x8_BGR(WorkArea:PWorkArea;src:pointer;linesize:integer);var x,y:integer;p:PByte;
begin
  for y:=0 to 7 do begin
    p:=src;pInc(src,linesize);
    for x:=0 to 7 do begin
      p^:=WorkArea.Y[0,y,x];pInc(p);
      p^:=WorkArea.Y[1,y,x];pInc(p);
      p^:=WorkArea.Y[2,y,x];pInc(p);
    end;
  end;
end;

procedure StorePixels8x8_BGR_SSE(WorkArea:PWorkArea;dst:pointer;linesize:integer);
asm
  push esi; push edi; push ebx; push ebp
  mov ebp,esp;
  mov esi,4  //loop counter
  sub ebp,4*16 //temp
  and ebp,$FFFFFFF0
@@1:
  movaps xmm0,[eax]     //b
  movaps xmm1,[eax+$80] //g
  movaps xmm2,[eax+$100]//r

  movaps xmm3,xmm0;                                       add eax,16
  punpcklbw xmm3,xmm1;//0. blue,green
  punpckhbw xmm0,xmm1;//1. blue,green
  movaps xmm1,xmm2;
  punpcklbw xmm2,xmm2;//0. alpha,alpha
  punpckhbw xmm1,xmm1;//1. alpha,alpha

  //line 0                   //line1
  movaps xmm4,xmm3;          movaps xmm6,xmm0;
  movaps xmm5,xmm3;          movaps xmm7,xmm0;
  punpcklwd xmm4,xmm2;       punpcklwd xmm6,xmm1
  punpckhwd xmm5,xmm2;       punpckhwd xmm7,xmm1
  movaps [ebp+$00],xmm4;     movaps [ebp+$20],xmm6;
  movaps [ebp+$10],xmm5;     movaps [ebp+$30],xmm7;

  mov ebx,dword([ebp+$00]);              mov edi,dword([ebp+$10]);
  mov [edx],ebx;                         mov [edx+12],edi;
  mov ebx,dword([ebp+$04]);              mov edi,dword([ebp+$14]);
  mov [edx+3],ebx;                       mov [edx+12+3],edi;
  mov ebx,dword([ebp+$08]);              mov edi,dword([ebp+$18]);
  mov [edx+6],ebx;                       mov [edx+12+6],edi;
  mov ebx,dword([ebp+$0C]);              mov edi,dword([ebp+$1C]);
  mov [edx+9],bl;                        mov [edx+12+9],di;
  shr ebx,8;                             shr edi,8;
  mov [edx+10],bx;                       mov [edx+12+10],di;
  add edx,ecx

  mov ebx,dword([ebp+$20]);              mov edi,dword([ebp+$30]);
  mov [edx],ebx;                         mov [edx+12],edi;
  mov ebx,dword([ebp+$24]);              mov edi,dword([ebp+$34]);
  mov [edx+3],ebx;                       mov [edx+12+3],edi;
  mov ebx,dword([ebp+$28]);              mov edi,dword([ebp+$38]);
  mov [edx+6],ebx;                       mov [edx+12+6],edi;
  mov ebx,dword([ebp+$2C]);              mov edi,dword([ebp+$3C]);
  mov [edx+9],bl;                        mov [edx+12+9],di;
  shr ebx,8;                             shr edi,8;
  mov [edx+10],bx;                       mov [edx+12+10],di;
  add edx,ecx

  sub esi,1
  ja @@1
  pop ebp; pop ebx; pop edi; pop esi
end;

//32bit ->Y[0], Y[1], Y[2], Y[3]
procedure LoadPixels8x8_BGRA(WorkArea:PWorkArea;src:pointer;linesize:integer);var x,y:integer;p:PByte;
begin
  for y:=0 to 7 do begin
    p:=src;pInc(src,linesize);
    for x:=0 to 7 do begin
      WorkArea.Y[0,y,x]:=p^;pInc(p);
      WorkArea.Y[1,y,x]:=p^;pInc(p);
      WorkArea.Y[2,y,x]:=p^;pInc(p);
      WorkArea.Y[3,y,x]:=p^;pInc(p);
    end;
  end;
end;

procedure LoadPixels8x8_BGRA_SSE(WorkArea:PWorkArea;src:pointer;linesize:integer);
asm
  push esi;push ebp
  pcmpeqw xmm3,xmm3;
  mov ebp,esp
  sub eax,16            //destination
  sub ebp,16
  psrlw xmm3,8; //$00ff
  and ebp,$FFFFFFF0  //temp
  mov esi,4             //loop counter
@@1:
  test edx,$f
  jz @@al
    movups xmm4,[edx];    movups xmm5,[edx+16];jmp @@done
@@al:movaps xmm4,[edx];    movaps xmm5,[edx+16]
@@done:add edx,ecx
  test edx,$f
  jz @@al2
    movups xmm6,[edx];    movups xmm7,[edx+16];jmp @@done2
@@al2:movaps xmm6,[edx];    movaps xmm7,[edx+16]
@@done2:add edx,ecx

  movaps [ebp+$00],xmm4                      ;add eax,16

  //xmm4,5,6,7 2 lines of ?rgb?rgb?rgb?rgb*2
  movaps xmm0,xmm4;     movaps xmm2,xmm5;
  pand xmm0,xmm3;       pand xmm2,xmm3;
  packuswb xmm0,xmm2  //rbrbrbrbrbrbrbrb

  movaps xmm1,xmm6;     movaps xmm2,xmm7;
  pand xmm1,xmm3;       pand xmm2,xmm3;
  packuswb xmm1,xmm2  //rbrbrbrbrbrbrbrb

  //xmm0,1 :2 lines of rbrbrbrb
  movaps xmm4,xmm0;     movaps xmm2,xmm1;
  pand xmm4,xmm3;       pand xmm2,xmm3;
  packuswb xmm4,xmm2;  //bbbbbbbbbbbbbbbbb
  psrlw xmm0,8          psrlw xmm1,8
  packuswb xmm0,xmm1   //rrrrrrrrrrrrrrrrr

  movaps [eax+ $00],xmm4;//blue
  movaps [eax+$100],xmm0;//red

  movaps xmm4,[ebp+$00]
  //xmm4,5,6,7 2 lines of ?rgb?rgb?rgb?rgb*2
  movaps xmm0,xmm4;     movaps xmm2,xmm5;
  psrlw xmm0,8;         psrlw xmm2,8;
  packuswb xmm0,xmm2  //agagagagagagagag

  movaps xmm1,xmm6;     movaps xmm2,xmm7;
  psrlw xmm1,8;         psrlw xmm2,8;
  packuswb xmm1,xmm2  //agagagagagagagag

  //xmm0,1 :2 lines of agagagagagagagag
  movaps xmm4,xmm0;     movaps xmm5,xmm1;
  psrlw xmm4,8;         psrlw xmm5,8
  packuswb xmm4,xmm5    //aaaaaaaaaaaaa
  pand xmm0,xmm3;       pand xmm1,xmm3
  packuswb xmm0,xmm1    //ggggggggggggg

  movaps [eax+$180],xmm4;//alpha
  sub esi,1
  movaps [eax+ $80],xmm0;//green

ja @@1
  pop ebp;pop esi
end;

procedure StorePixels8x8_BGRA(WorkArea:PWorkArea;dst:pointer;linesize:integer);var x,y:integer;p:PByte;
begin
  for y:=0 to 7 do begin
    p:=dst;pInc(dst,linesize);
    for x:=0 to 7 do begin
      p^:=WorkArea.Y[0,y,x];pInc(p);
      p^:=WorkArea.Y[1,y,x];pInc(p);
      p^:=WorkArea.Y[2,y,x];pInc(p);
      p^:=WorkArea.Y[3,y,x];pInc(p);
    end;
  end;
end;

procedure StorePixels8x8_BGRA_SSE(WorkArea:PWorkArea;dst:pointer;linesize:integer);
asm
  push esi
  mov esi,4 //loop counter
  sub edx,ecx//dst
@@1:
  movaps xmm0,[eax]      //bbbbbbbbbbbbbbbb
  movaps xmm2,[eax+$80]  //gggggggggggggggg
  movaps xmm1,xmm0;
  punpcklbw xmm0,xmm2 //0. gbgbgbgbgbgbgbgb
  punpckhbw xmm1,xmm2 //1. gbgbgbgbgbgbgbgb

  movaps xmm4,[eax+$100] //rrrrrrrrrrrrrrrr
  movaps xmm6,[eax+$180] //aaaaaaaaaaaaaaaa
  movaps xmm5,xmm4;     add eax,16
  punpcklbw xmm4,xmm6 //0. arararararararar
  punpckhbw xmm5,xmm6 //1. arararararararar

  add edx,ecx
  movaps xmm2,xmm0;
  test edx,$f
  punpcklwd xmm2,xmm4;    punpckhwd xmm0,xmm4;
  jnz @@un1
      movaps [edx+$00],xmm2;  movaps [edx+$10],xmm0; jmp @@done1
@@un1:movups [edx+$00],xmm2;  movups [edx+$10],xmm0
@@done1:
  add edx,ecx

  movaps xmm6,xmm1;
  test edx,$f
  punpcklwd xmm6,xmm5;    punpckhwd xmm1,xmm5;
  jnz @@un2
      movaps [edx+$00],xmm6;  movaps [edx+$10],xmm1; jmp @@done2
@@un2:movups [edx+$00],xmm6;  movups [edx+$10],xmm1
@@done2:

  sub esi,1
  ja @@1
  pop esi
end;

////////////////////////////////////////////////////////////////////////////////
{ YUV conversion
float matrices
   R      G      B            Y      U      V
Y  0.286  0.571  0.143     R  1.000  0.000  1.000
U -0.143 -0.286  0.429     G  1.000 -0.500 -0.500
V  0.714 -0.571 -0.143     B  1.000  2.000  0.000}

type
  TColorMatrix=array[0..2,0..2]of integer;
const
  MBGRtoYUV:TColorMatrix=(
     {   B    G    R  ofs}
  {Y}(  37, 146,  73), //sum 256
  {U}( 110, -73, -37), //sum 0  7bit
  {V}( -18, -73,  91));//sum 0  7bit
//  {V}( -37,-146, 183));//sum 0


  MYUVtoBGR:TColorMatrix=(
     {   Y    U    V}
  {B}( 256, 512,   0),
  {G}( 256,-128,-256),
  {R}( 256,   0, 512));

  function _sat16(a:integer):integer;begin if a<0 then result:=0 else if a>65535 then result:=65535 else result:=a;end;
  function _sat8(a:integer):integer;begin if a<0 then result:=0 else if a>255 then result:=255 else result:=a;end;
  function _add(a,b:byte):byte;begin result:=a+b;end;
  function _addss(a,b:shortint):shortint;var i:integer;
  begin i:=a+b;if i<-128 then i:=-128 else if i>127 then i:=127;result:=i;end;
  function _subss(a,b:shortint):shortint;var i:integer;
  begin i:=a-b;if i<-128 then i:=-128 else if i>127 then i:=127;result:=i;end;
  function _subus(a,b:shortint):shortint;var i:integer;
  begin i:=a-b;if i<0 then i:=0 else if i>255 then i:=255;result:=i;end;
  function _avg(a,b:byte):byte;
  begin result:=(a+1+b)shr 1 end;
  function _cmp(a,b:byte):byte;
  begin if a>b then result:=$ff else result:=00;end;

procedure _Convert_BGRtoYUV(var color);
var r,g,b:integer;
begin
  b:=TRgbTriple(color).rgbtBlue;
  g:=TRgbTriple(color).rgbtGreen;
  r:=TRgbTriple(color).rgbtRed;
{  TRgbTriple(color).rgbtBlue :=(b*MBGRtoYUV[0,0]+g*MBGRtoYUV[0,1]+r*MBGRtoYUV[0,2]+$7f)shr 8;
  TRgbTriple(color).rgbtGreen:=(b*MBGRtoYUV[1,0]+g*MBGRtoYUV[1,1]+r*MBGRtoYUV[1,2]+$807f)shr 8;
  TRgbTriple(color).rgbtRed  :=(b*MBGRtoYUV[2,0]+g*MBGRtoYUV[2,1]+r*MBGRtoYUV[2,2]+$807f)shr 8;}

  TRgbTriple(color).rgbtBlue :=_avg(g,_avg(r,b));
  TRgbTriple(color).rgbtGreen:=_avg(b,255)-(g shr 1);
  TRgbTriple(color).rgbtRed  :=_avg(r,255)-(g shr 1);
end;

procedure _Convert_YUVtoBGR(var color);
var r,g,b:integer;
begin
  b:=TRgbTriple(color).rgbtBlue;
  g:=TRgbTriple(color).rgbtGreen;
  r:=TRgbTriple(color).rgbtRed;
//  TRgbTriple(color).rgbtBlue :=sat16(b*MYUVtoBGR[0,0]+g*MYUVtoBGR[0,1]+r*MYUVtoBGR[0,2])shr 8;
//  TRgbTriple(color).rgbtGreen:=sat16(b*MYUVtoBGR[1,0]+g*MYUVtoBGR[1,1]+r*MYUVtoBGR[1,2])shr 8;
//  TRgbTriple(color).rgbtRed  :=sat16(b*MYUVtoBGR[2,0]+g*MYUVtoBGR[2,1]+r*MYUVtoBGR[2,2])shr 8;

  //optimized version
{  u2:=avg(TRgbTriple(color).rgbtGreen,128)-128;
  b:=TRgbTriple(color).rgbtBlue-128;
  g:=TRgbTriple(color).rgbtGreen-128;
  r:=TRgbTriple(color).rgbtRed-128;
  TRgbTriple(color).rgbtBlue :=addss(addss(b,g),g)+128;
  TRgbTriple(color).rgbtGreen:=subss(b,addss(u2,r))+128;
  TRgbTriple(color).rgbtRed  :=addss(addss(b,r),r)+128;}

  TRgbTriple(color).rgbtGreen:=_subss(b-128,_avg(g,r)-128);
  TRgbTriple(color).rgbtBlue:= _addss(_addss(TRgbTriple(color).rgbtGreen,(g-128)),(g-128))+128;
  TRgbTriple(color).rgbtRed:=  _addss(_addss(TRgbTriple(color).rgbtGreen,(r-128)),(r-128))+128;
  TRgbTriple(color).rgbtGreen:=TRgbTriple(color).rgbtGreen+128;
end;

procedure _Load_4x2BGR(psrc:pointer;linesize:integer;var dst:T4x2RGBQuadArray);
// psrc^          BGRBGRBGRBGR -> dst[0] BGR?BGR?BGR?BGR0
// psrc+linesize^ BGRBGRBGRBGR -> dst[1] BGR?BGR?BGR?BGR0
var x,y:integer;p:PRGBTriple;
begin
  for y:=0 to 1 do begin
    p:=psrc;pInc(pSrc,linesize);
    for x:=0 to 3 do with dst[y,x]do begin
      rgbBlue :=P.rgbtBlue;
      rgbGreen:=P.rgbtGreen;
      rgbRed  :=P.rgbtRed;
      pinc(p,3);
    end;
  end;
end;

procedure _Load_4x2BGR_SSE_XMM67(psrc:pointer;linesize:integer);
// psrc^          BGRBGRBGRBGR -> xmm6 BGR?BGR?BGR?BGR0
// psrc+linesize^ BGRBGRBGRBGR -> xmm7 BGR?BGR?BGR?BGR0
asm
  push ebp;push ebx;
  mov ebp,esp;sub ebp,2*16;and ebp,$FFFFFFF0//temp
  mov ecx,[eax];           ;mov ebx,[eax+edx]
  mov dword([ebp+$00]),ecx ;mov dword([ebp+$10]),ebx
  mov ecx,[eax+3];         ;mov ebx,[eax+edx+3]
  mov dword([ebp+$04]),ecx ;mov dword([ebp+$14]),ebx
  mov ecx,[eax+6];         ;mov ebx,[eax+edx+6]
  mov dword(ebp+$08),ecx   ;mov dword([ebp+$18]),ebx
  mov ecx,[eax+8];         ;mov ebx,[eax+edx+8]
  shr ecx,8;               ;shr ebx,8
  mov dword([ebp+$0C]),ecx ;mov dword([ebp+$1C]),ebx
  movaps xmm6,[ebp+$00]    ;movaps xmm7,[ebp+$10];
  pop ebx;pop ebp
end;

procedure _Load_4x2BGRA(psrc:pointer;linesize:integer;var dst:T4x2RGBQuadArray);
var x,y:integer;p:PRGBQuad;
begin
  for y:=0 to 1 do begin
    p:=psrc;pInc(pSrc,linesize);
    for x:=0 to 3 do begin dst[y,x]:=p^;inc(p);end;
  end;
end;

procedure _Load_4x2BGRA_SSE_XMM67(psrc:pointer;linesize:integer);
asm
  test edx,$f
  jnz @@un
    movaps xmm6,[eax];
  test ecx,$f
  jnz @@un2
    movaps xmm7,[eax+edx];
  ret
@@un:
  movups xmm6,[eax];
@@un2:
  movups xmm7,[eax+edx];
end;

procedure _Convert_4x2BGRA_YUV420(pY,pUV,pA:pointer;var src:T4x2RGBQuadArray);//pA can be nil
var x,y:integer;
begin
  for y:=0 to 1 do for x:=0 to 3 do begin
    _Convert_BGRtoYUV(src[y,x]);
    pWord(pSucc(pY,y*16+x*2))^:=src[y,x].rgbBlue;
    if pa<>nil then
      pWord(pSucc(pA,y*16+x*2))^:=src[y,x].rgbReserved;
  end;
  pword(pSucc(pUV,  0))^:=(src[0,0].rgbGreen+src[0,1].rgbGreen+src[1,0].rgbGreen+src[1,1].rgbGreen+2)shr 2;
  pword(pSucc(pUV,  2))^:=(src[0,2].rgbGreen+src[0,3].rgbGreen+src[1,2].rgbGreen+src[1,3].rgbGreen+2)shr 2;
  pword(pSucc(pUV,$80))^:=(src[0,0].rgbRed  +src[0,1].rgbRed  +src[1,0].rgbRed  +src[1,1].rgbRed  +2)shr 2;
  pword(pSucc(pUV,$82))^:=(src[0,2].rgbRed  +src[0,3].rgbRed  +src[1,2].rgbRed  +src[1,3].rgbRed  +2)shr 2;
end;

procedure _Convert_4x2BGRA_YUV420_SSE(pY,pUV,pA:pointer);//pA can be nil
// xmm6 BGRABGRABGRABGRA -> pY0^    YYYY  pUV^ UVUV
// xmm7 BGRABGRABGRABGRA -> pY0+16^ YYYY
asm
  pxor xmm5,xmm5
  pcmpeqw xmm4,xmm4{<- ffff}
  psrlw xmm4,8{<- 00ff}
//extract b,g,r -> word xmm012
  movaps xmm0,xmm6   //b,r ->xmm0,xmm1
  movaps xmm2,xmm7
  pand xmm0,xmm4{00ff}
  pand xmm2,xmm4{00ff}
  packuswb xmm0,xmm2
  movaps xmm2,xmm0
  pand xmm0,xmm4 {blue} {00ff}
  psrlw xmm2,8   {red}

  movaps xmm1,xmm6  //g -> xmm1
  movaps xmm3,xmm7
  psrlw xmm1,8
  psrlw xmm3,8
  packuswb xmm1,xmm3

  movaps xmm3,xmm1
test ecx,ecx
  pand xmm1,xmm4 {green... goes through} {00ff}
jz @@noalpha
  psrlw xmm3,8 {alpha}  //eddig ok xmm0,1,2,3 feltoltve
  packuswb xmm3,xmm5
  movd [ecx],xmm3
  psrldq xmm3,4
  movd [ecx+$8],xmm3

@@noalpha:
  //y -> mmx0
{  pmullw xmm0,SSERegs.w_BtoY;
  pmullw xmm1,SSERegs.w_GtoY;
  pmullw xmm2,SSERegs.w_RtoY;
  paddw xmm0,xmm1
  paddw xmm0,xmm2
  paddw xmm0,SSERegs.w_007f;
  psrlw xmm0,8}

  {  TRgbTriple(color).rgbtBlue :=_avg(g,_avg(r,b));}
  pavgw xmm0,xmm2
  pavgw xmm0,xmm1

  packuswb xmm0,xmm5
  movd [eax],xmm0
  psrldq xmm0,4
  movd [eax+$8],xmm0
  //uv
  pavgb xmm7,xmm6               //bgrabgrabgrabgra

  pshufd xmm6,xmm7,SHUFFLE_0202
  pshufd xmm7,xmm7,SHUFFLE_1313
  pavgb xmm7,xmm6               //bgrabgra
//  punpcklbw xmm7,xmm5           //b g r a b g r a

{  TRgbTriple(color).rgbtGreen:=_avg(b,255)-(g shr 1);
  TRgbTriple(color).rgbtRed  :=_avg(r,255)-(g shr 1);}
  pcmpeqb xmm4,xmm4
  movaps xmm0,xmm7
  pavgb xmm7,xmm4; //avg(x,255)
  movaps xmm6,xmm7

  //xmm0 := g shr 1   //xmm6 := b     //xmm7 := r
  pslld xmm0,16;      pslld xmm6,24;  pslld xmm7,8
  psrld xmm0,25;      psrld xmm6,24;  psrld xmm7,24

  packuswb xmm0,xmm0
  packuswb xmm6,xmm7
  psubw xmm6,xmm0  // u u v v

  packuswb xmm6,xmm5

  push esi

  movd esi,xmm6
  mov [edx],si
  psrldq xmm6,4
  movd esi,xmm6
  mov [edx+$80],si

  pop esi


{  pmullw xmm7,SSERegs.w_BGRtoVV //v v v a v v v a
  pmullw xmm6,SSERegs.w_BGRtoUU //u u u a u u u a

  movaps xmm0,xmm7;
  movaps xmm1,xmm7;
  psrlq xmm0,16;                movaps xmm2,xmm6;
  psrlq xmm1,32;                movaps xmm3,xmm6;
  paddw xmm7,xmm0;              psrlq xmm2,16;
  paddw xmm7,xmm1;              psrlq xmm3,32;
  paddw xmm7,SSERegs.w_807f;    paddw xmm6,xmm2;
  psllq xmm7,48;                paddw xmm6,xmm3;
  psrlq xmm7,48+8;              paddw xmm6,SSERegs.w_807f;
                                psllq xmm6,48
                                psrlq xmm6,48+8

  packuswb xmm6,xmm7;           //u   u   v   v
  packusdw xmm6,xmm5            //u u v v
  push esi

  packuswb xmm6,xmm5
  movd esi,xmm6
  mov [edx],si
  shr esi,16
  mov [edx+$80],si

  pop esi
  }
end;

procedure _Convert_YUV420_16x1BGRA_SSE_XMM0123(pY,pUV,pA:pointer;odd:boolean);//pA can be nil
asm
  //fetch UV, interpolate if needed
  movlps xmm1,[edx];
  test odd,1
  movhps xmm1,[edx+$80]; {vvvvvvvvuuuuuuuu}
  jz @@noInterp
  movlps xmm2,[edx+$08]
  movhps xmm2,[edx+$88];                      //edx es free
  pavgb xmm1,xmm2;
@@noInterp:
  pxor xmm7,xmm7
  movaps xmm2,xmm1
  punpcklbw xmm1,xmm7    { u u u u u u u u}
  punpckhbw xmm2,xmm7    { v v v v v v v v}
  //smoothen UV line, read Y
  movaps xmm0,xmm1;                           mov edx, SSEData //load consts
  pslldq xmm0,2;         { u u u u u u u  }
  pavgb xmm0,xmm1;                            movaps xmm3,xmm2;
  psrldq xmm0,1;         {  u u u u u u u }   pslldq xmm3,2;         { v v v v v v v  }
  por xmm1,xmm0;         { uuuuuuuuuuuuuuu}   pavgb xmm3,xmm2;
  pmullw xmm1, TSSEData(edx).w_lineAvgLastScale; psrldq xmm3,1;         {  v v v v v v v }
  movlps xmm0,[eax];     {yyyyyyyy}           por xmm2,xmm3;         { vvvvvvvvvvvvvvv}
  movhps xmm0,[eax+$100];{yyyyyyyy}           pmullw xmm2,TSSEData(edx).w_lineAvgLastScale;

  //duplicate last pixel
    test ecx,ecx
//packuswb xmm0,xmm4     {yyyyyyyyyyyyyyyy}
  //read A
  jz @@skipAlpha
    movlps xmm3,[ecx+0];
    movhps xmm3,[ecx+$100];
@@skipAlpha:

//  YUV->RGB  ///////  YUV->RGB  ///////  YUV->RGB  ///////  YUV->RGB  ///////
//  state: xmm0:y, xmm1:u, xmm2:v, xmm3:a
//  TRgbTriple(color).rgbtGreen:=_subss(y-128,_avg(u,v)-128);
//  TRgbTriple(color).rgbtBlue:= _addss(_addss(TRgbTriple(color).rgbtGreen,(u-128)),(u-128))+128;
//  TRgbTriple(color).rgbtRed:=  _addss(_addss(TRgbTriple(color).rgbtGreen,(v-128)),(v-128))+128;
//  TRgbTriple(color).rgbtGreen:=TRgbTriple(color).rgbtGreen+128;
//  xmm5,xmm6{128},xmm7{0}:temp
  pcmpeqb xmm6,xmm6;
  //green              //uv -128
  movaps xmm5,xmm1;    pavgb xmm6,xmm7 //128
  pavgb xmm5,xmm2;     psubb xmm2,xmm6
  psubb xmm0,xmm6;     psubb xmm1,xmm6
  psubb xmm5,xmm6;
  psubsb xmm0,xmm5;
  movaps xmm4,xmm0;    movaps xmm5,xmm0
  //blue               //red
  paddsb xmm0,xmm1;    paddsb xmm5,xmm2
  paddsb xmm0,xmm1;    paddsb xmm5,xmm2
  movaps xmm1,xmm0;    movaps xmm2,xmm5

  paddb xmm4,xmm6
  paddb xmm1,xmm6
  paddb xmm2,xmm6

  //state: xmm1:blue, xmm4:green, xmm2:red, xmm3:alpha, the rest are free
  //interleave into words
  //blue,green          //red,alpha
  movaps xmm6,xmm1;
  punpcklbw xmm6,xmm4;  movaps xmm7,xmm2;
  punpckhbw xmm1,xmm4;  punpcklbw xmm7,xmm3;
  movaps xmm5,xmm1      punpckhbw xmm2,xmm3;
                        movaps xmm4,xmm2;

  //state: xmm6:bg_lo, xmm5:bg_hi, xmm7:ra_lo, xmm4:ra_hi
  //interleave into Dwords
  movaps xmm0,xmm6;
  movaps xmm1,xmm6;
  punpcklwd xmm0,xmm7;  movaps xmm2,xmm5;
  punpckhwd xmm1,xmm7;  movaps xmm3,xmm5;
                        punpcklwd xmm2,xmm4;
                        punpckhwd xmm3,xmm4;
end;

procedure _StorePixel_16x1BGRA_BGR_SSE_XMM0123(dst:pointer);
asm
  mov edx,$ffffff

  movaps xmm4,xmm0;    movd xmm7,edx;   movaps xmm5,xmm1
  pshufd xmm7,xmm7,SHUFFLE_0101
  pand xmm0,xmm7;         pand xmm1,xmm7
  pshufd xmm6,xmm7,SHUFFLE_1010
  pand xmm4,xmm6;         pand xmm5,xmm6
  psrldq xmm4,1;          psrldq xmm5,1
  por xmm0,xmm4;          por xmm1,xmm5;
  movlps [eax],xmm0;          movaps xmm4,xmm2;
  movhps [eax+6],xmm0;        pand xmm2,xmm7;
  movlps [eax+12],xmm1;       pand xmm4,xmm6;         movaps xmm5,xmm3
  movhps [eax+18],xmm1;       psrldq xmm4,1;          pand xmm3,xmm7
                              por xmm2,xmm4;          pand xmm5,xmm6
                              movlps [eax+24],xmm2;   psrldq xmm5,1
                              movhps [eax+30],xmm2;   por xmm3,xmm5;
                              movlps [eax+36],xmm3
                              psrldq xmm3,8; movd [eax+42],xmm3; psrldq xmm3,2; movd [eax+44],xmm3;
end;


procedure _StorePixel_16x1BGRA_BGRA_SSE_XMM0123(dst:pointer);
asm
  test eax,$F
  jnz @@un
    movaps [eax+$00],xmm0;
    movaps [eax+$10],xmm1;
    movaps [eax+$20],xmm2;
    movaps [eax+$30],xmm3;
  ret
@@un:
    movlpd [eax+$00],xmm0;
    movhpd [eax+$08],xmm0;
    movlpd [eax+$10],xmm1;
    movhpd [eax+$18],xmm1;
    movlpd [eax+$20],xmm2;
    movhpd [eax+$28],xmm2;
    movlpd [eax+$30],xmm3;
    movhpd [eax+$38],xmm3;
end;

procedure _StorePixel_YUV420_color(var WorkArea:TWorkArea;var dst:TRGBTriple;x,y:integer);
var x2,y2,blockId:integer;avgType:integer;
begin
  blockId:=y shr 3+x shr 3 shl 1;
  x2:=x and 7;y2:=y and 7;
  dst.rgbtBlue :=WorkArea.Y[blockId,y2,x2];

  x2:=x shr 1;y2:=y shr 1;
  avgType:=ord(((x and 1)<>0)and(x2<7))+ord(((y and 1)<>0)and(y2<7))shl 1;
  case avgType of
    0:begin
      dst.rgbtGreen:=WorkArea.UV[0,y2,x2];
      dst.rgbtRed  :=WorkArea.UV[1,y2,x2];
    end;
    1:begin//horizontal avg
      dst.rgbtGreen:=(WorkArea.UV[0,y2,x2]+WorkArea.UV[0,y2,x2+1]+1)shr 1;
      dst.rgbtRed  :=(WorkArea.UV[1,y2,x2]+WorkArea.UV[1,y2,x2+1]+1)shr 1;
    end;
    2:begin//vertical avg
      dst.rgbtGreen:=(WorkArea.UV[0,y2,x2]+WorkArea.UV[0,y2+1,x2]+1)shr 1;
      dst.rgbtRed  :=(WorkArea.UV[1,y2,x2]+WorkArea.UV[1,y2+1,x2]+1)shr 1;
    end;
    else begin //h,v average
      dst.rgbtGreen:=(WorkArea.UV[0,y2  ,x2  ]+WorkArea.UV[0,y2  ,x2+1]+
                         WorkArea.UV[0,y2+1,x2  ]+WorkArea.UV[0,y2+1,x2+1]+2)shr 2;
      dst.rgbtRed:=  (WorkArea.UV[1,y2  ,x2  ]+WorkArea.UV[1,y2  ,x2+1]+
                         WorkArea.UV[1,y2+1,x2  ]+WorkArea.UV[1,y2+1,x2+1]+2)shr 2;
    end;
  end;
  _Convert_YUVtoBGR(dst);
end;

procedure _StorePixel_YUV420_alpha(var WorkArea:TWorkArea;var dst:TRGBQuad;x,y:integer);
begin
  dst.rgbReserved:=WorkArea.A[y shr 3+x shr 3 shl 1,y and 7,x and 7];
end;

//24bit -> Y[0..3], U, V
procedure LoadPixels16x16_YUV(WorkArea:PWorkArea;src:pointer;linesize:integer);
var tmp:T4x2RGBQuadArray;
    pY,pUV:pointer;
    y:integer;
begin
  pY:=@WorkArea.Y[0];
  pUV:=@WorkArea.UV[0];
  for y:=0 to 7 do begin
    _Load_4x2BGR(      src    ,lineSize,tmp);_Convert_4x2BGRA_YUV420(      pY      ,      pUV    ,nil,tmp);
    _Load_4x2BGR(pSucc(src,12),lineSize,tmp);_Convert_4x2BGRA_YUV420(pSucc(pY,   8),pSucc(pUV, 4),nil,tmp);
    _Load_4x2BGR(pSucc(src,24),lineSize,tmp);_Convert_4x2BGRA_YUV420(pSucc(pY,$100),pSucc(pUV, 8),nil,tmp);
    _Load_4x2BGR(pSucc(src,36),lineSize,tmp);_Convert_4x2BGRA_YUV420(pSucc(pY,$108),pSucc(pUV,12),nil,tmp);
    pInc(src,linesize*2);pInc(pY,32);pInc(pUV,16);
  end;
end;

procedure LoadPixels16x16_YUV_SSE(WorkArea:PWorkArea;src:pointer;linesize:integer);
var pY,pUV:pointer;
    y:integer;
begin
  pY:=@WorkArea.Y[0];
  pUV:=@WorkArea.UV[0];
  for y:=0 to 7 do begin
    _Load_4x2BGR_SSE_XMM67(      src    ,lineSize);_Convert_4x2BGRA_YUV420_SSE(      pY      ,      pUV    ,nil);
    _Load_4x2BGR_SSE_XMM67(pSucc(src,12),lineSize);_Convert_4x2BGRA_YUV420_SSE(pSucc(pY,   4),pSucc(pUV, 2),nil);
    _Load_4x2BGR_SSE_XMM67(pSucc(src,24),lineSize);_Convert_4x2BGRA_YUV420_SSE(pSucc(pY,$100),pSucc(pUV, 4),nil);
    _Load_4x2BGR_SSE_XMM67(pSucc(src,36),lineSize);_Convert_4x2BGRA_YUV420_SSE(pSucc(pY,$104),pSucc(pUV, 6),nil);
    if y=3 then pInc(pY,$50)else pInc(pY,16);
    pInc(src,linesize*2);pInc(pUV,8);
  end;
end;

procedure StorePixels16x16_YUV(WorkArea:PWorkArea;dst:pointer;linesize:integer);
var p:PRGBTriple;
    x,y:integer;
begin
  for y:=0 to 15 do begin
    p:=dst;
    for x:=0 to 15 do begin
      _StorePixel_YUV420_color(WorkArea^,p^,x,y);
      pInc(p,3);
    end;
    dst:=pSucc(dst,linesize);
  end;
end;

procedure StorePixels16x16_YUV_SSE(WorkArea:PWorkArea;dst:pointer;linesize:integer);
var pY,pUV:pointer;
    y:integer;
begin
  pY:=@WorkArea.Y[0];
  pUV:=@WorkArea.UV;
  for y:=0 to 15 do begin
    _Convert_YUV420_16x1BGRA_SSE_XMM0123(pY,pUV,nil,boolean(ord(Y<15)and y));
    _StorePixel_16x1BGRA_BGR_SSE_XMM0123(dst);
    if y=7 then pInc(pY,$48) else pInc(pY,8);
    if(y and 1)<>0 then pInc(pUV,8);
    pInc(dst,linesize);
  end;
end;

//32bit -> Y[0..3], U, V, A[0..3]
procedure LoadPixels16x16_YUVA(WorkArea:PWorkArea;src:pointer;linesize:integer);
var tmp:T4x2RGBQuadArray;
    pY,pUV,pA:pointer;
    y:integer;
begin
  pY:=@WorkArea.Y[0];
  pA:=@WorkArea.A[0];
  pUV:=@WorkArea.UV[0];
  for y:=0 to 7 do begin
    _Load_4x2BGRA(      src    ,lineSize,tmp);_Convert_4x2BGRA_YUV420(      pY      ,      pUV    ,      pA      ,tmp);
    _Load_4x2BGRA(pSucc(src,16),lineSize,tmp);_Convert_4x2BGRA_YUV420(pSucc(pY,   8),pSucc(pUV, 4),pSucc(pA,   8),tmp);
    _Load_4x2BGRA(pSucc(src,32),lineSize,tmp);_Convert_4x2BGRA_YUV420(pSucc(pY,$100),pSucc(pUV, 8),pSucc(pA,$100),tmp);
    _Load_4x2BGRA(pSucc(src,48),lineSize,tmp);_Convert_4x2BGRA_YUV420(pSucc(pY,$108),pSucc(pUV,12),pSucc(pA,$108),tmp);
    pInc(src,linesize*2);pInc(pY,32);pInc(pUV,16);pInc(pA,32);
  end;
end;

procedure LoadPixels16x16_YUVA_SSE(WorkArea:PWorkArea;src:pointer;linesize:integer);
var pY,pUV,pA:pointer;
    y:integer;
begin
  pY:=@WorkArea.Y[0];
  pA:=@WorkArea.A[0];
  pUV:=@WorkArea.UV[0];
  for y:=0 to 7 do begin
    _Load_4x2BGRA_SSE_XMM67(      src    ,lineSize);_Convert_4x2BGRA_YUV420_SSE(      pY      ,      pUV    ,      pA      );
    _Load_4x2BGRA_SSE_XMM67(pSucc(src,16),lineSize);_Convert_4x2BGRA_YUV420_SSE(pSucc(pY,   4),pSucc(pUV, 2),pSucc(pA,   4));
    _Load_4x2BGRA_SSE_XMM67(pSucc(src,32),lineSize);_Convert_4x2BGRA_YUV420_SSE(pSucc(pY,$100),pSucc(pUV, 4),pSucc(pA,$100));
    _Load_4x2BGRA_SSE_XMM67(pSucc(src,48),lineSize);_Convert_4x2BGRA_YUV420_SSE(pSucc(pY,$104),pSucc(pUV, 6),pSucc(pA,$104));
    if y=3 then begin pInc(pY,$50);pInc(pA,$50)end else begin pInc(pY,16);pInc(pA,16);end;
    pInc(src,linesize*2);pInc(pUV,8);
  end;
end;

procedure StorePixels16x16_YUVA(WorkArea:PWorkArea;dst:pointer;linesize:integer);
var p:PRGBTriple;
    x,y:integer;
begin
  for y:=0 to 15 do begin
    p:=dst;
    for x:=0 to 15 do begin
      _StorePixel_YUV420_color(WorkArea^,p^,x,y);
      _StorePixel_YUV420_alpha(WorkArea^,PRGBQUAD(p)^,x,y);
      pInc(p,4);
    end;
    dst:=pSucc(dst,linesize);
  end;
end;

procedure StorePixels16x16_YUVA_SSE(WorkArea:PWorkArea;dst:pointer;linesize:integer);
var pY,pUV,pA:pointer;
    y:integer;
begin
  pY:=@WorkArea.Y[0];
  pA:=@WorkArea.A[0];
  pUV:=@WorkArea.UV;
  for y:=0 to 15 do begin
    _Convert_YUV420_16x1BGRA_SSE_XMM0123(pY,pUV,pA,boolean(ord(Y<15)and y));
    _StorePixel_16x1BGRA_BGRA_SSE_XMM0123(dst);
    if y=7 then begin pInc(pY,$48);pInc(pA,$48)end else begin pInc(pY,$8);pInc(pA,8);end;
    if(y and 1)<>0 then pInc(pUV,8);
    pInc(dst,linesize);
  end;
end;

////////////////////////////////////////////////////////////////////////////////
/// Proc Selector

type
  TLoadPixelsProc=procedure(WorkArea:PWorkArea;dst:pointer;linesize:integer);
  TStorePixelsProc=procedure(WorkArea:PWorkArea;dst:pointer;linesize:integer);

function SelectLoadPixelsProc(const components:integer;const YUVMode:boolean):TLoadPixelsProc;
begin
  result:=nil;
  if SSEVersion>=SSE2 then case components of
    1:result:=@LoadPixels8x8_Y_SSE;
    2:result:=@LoadPixels8x8_YA_SSE;
    3:if YUVMode then result:=@LoadPixels16x16_YUV_SSE
                 else result:=@LoadPixels8x8_BGR_SSE;
    4:if YUVMode then result:=@LoadPixels16x16_YUVA_SSE
                 else result:=@LoadPixels8x8_BGRA_SSE;
  end else case Components of
    1:result:=@LoadPixels8x8_Y;
    2:result:=@LoadPixels8x8_YA;
    3:if YUVMode then result:=@LoadPixels16x16_YUV
                 else result:=@LoadPixels8x8_BGR;
    4:if YUVMode then result:=@LoadPixels16x16_YUVA
                 else result:=@LoadPixels8x8_BGRA;
  end;
  Assert(assigned(result),'HetJpeg: SelectLoadPixelsProc() failed.');
end;

function SelectStorePixelsProc(const components:integer;const YUVMode:boolean):TStorePixelsProc;
begin
  result:=nil;
  if SSEVersion>=SSE2 then case components of
    1:result:=@StorePixels8x8_Y_SSE;
    2:result:=@StorePixels8x8_YA_SSE;
    3:if YUVMode then result:=@StorePixels16x16_YUV_SSE
                 else result:=@StorePixels8x8_BGR_SSE;
    4:if YUVMode then result:=@StorePixels16x16_YUVA_SSE
                 else result:=@StorePixels8x8_BGRA_SSE;
  end else case Components of
    1:result:=@StorePixels8x8_Y;
    2:result:=@StorePixels8x8_YA;
    3:if YUVMode then result:=@StorePixels16x16_YUV
                 else result:=@StorePixels8x8_BGR;
    4:if YUVMode then result:=@StorePixels16x16_YUVA
                 else result:=@StorePixels8x8_BGRA;
  end;
  Assert(assigned(result),'HetJpeg: SelectStorePixelsProc() failed.');
end;

////////////////////////////////////////////////////////////////////////////////
/// Step2                DCT+Quantize / Dequantize+IDCT
///
///                      The U and V qtables are different because V is downscaled
///                      by 2 in the yuv->rgb process to be in -128..127 range.

type
  TQuantPlane=(qY,qU,qV);

const
  std_luminance_qt:TBlockB=(
	(16,  11,  10,  16,  24,  40,  51,  61),
	(12,  12,  14,  19,  26,  58,  60,  55),
	(14,  13,  16,  24,  40,  57,  69,  56),
	(14,  17,  22,  29,  51,  87,  80,  62),
	(18,  22,  37,  56,  68, 109, 103,  77),
	(24,  35,  55,  64,  81, 104, 113,  92),
	(49,  64,  78,  87, 103, 121, 120, 101),
	(72,  92,  95,  98, 112, 100, 103,  99));
  std_chrominance_qt:TBlockB=(
	(17,  18,  24,  47,  99,  99,  99,  99),
	(18,  21,  26,  66,  99,  99,  99,  99),
	(24,  26,  56,  99,  99,  99,  99,  99),
	(47,  66,  99,  99,  99,  99,  99,  99),
	(99,  99,  99,  99,  99,  99,  99,  99),
	(99,  99,  99,  99,  99,  99,  99,  99),
	(99,  99,  99,  99,  99,  99,  99,  99),
	(99,  99,  99,  99,  99,  99,  99,  99));

  procedure _SetupQT(const Quality:integer;const plane:TQuantPlane;EncT,DecT:PBlockW);
    const scalefactor:array[0..7]of single=
      (1.0, 1.387039845, 1.306562965, 1.175875602,1.0, 0.785694958, 0.541196100, 0.275899379);

  var y,x,dec:integer;
      q,s,VScale:single;
      basicTable:PBlockB;
  begin
    if plane=qY then basicTable:=@std_luminance_qt
                else basicTable:=@std_chrominance_qt;
    if Plane=qV then VScale:=1
                else VScale:=1;
    q:=EnsureRange(Quality,1,100);
//    q:=50;
    if(q<50)then q:=5000/q
            else q:=200-q*2;

    for y:=0 to 7 do for x:=0 to 7 do begin
      s:=(basictable[x,y{filp}]*q+50)*0.01*scalefactor[y]*scalefactor[x]*VScale;
      dec:=EnsureRange(round(s),1{huffman ac nem kap 11-es category-t},1024);
      if DecT<>nil then
        DecT[y,x]:=dec;
      if EncT<>nil then
        EncT[y,x]:=((1 shl 13)div(dec));
    end;
  end;

procedure SetupEncoderQuantTables(var WorkArea:TWorkArea;Quality:integer);
begin
  _SetupQT(Quality,qY,@WorkArea.QTEncY,nil);
  _SetupQT(Quality,qU,@WorkArea.QTEncU,nil);
  _SetupQT(Quality,qV,@WorkArea.QTEncV,nil);
end;

procedure SetupDecoderQuantTables(var WorkArea:TWorkArea;Quality:integer);
begin
  _SetupQT(Quality,qY,nil,@WorkArea.QTDecY);
  _SetupQT(Quality,qU,nil,@WorkArea.QTDecU);
  _SetupQT(Quality,qV,nil,@WorkArea.QTDecV);
end;

////////////////////////////////////////////////////////////////////////////////
/// Step2b              DCT/IDCT
///
/// Description:        ...

const FlipIndex:array[0..63]of byte=(
  0, 8,16,24,32,40,48,56,
  1, 9,17,25,33,41,49,57,
  2,10,18,26,34,42,50,58,
  3,11,19,27,35,43,51,59,
  4,12,20,28,36,44,52,60,
  5,13,21,29,37,45,53,61,
  6,14,22,30,38,46,54,62,
  7,15,23,31,39,47,55,63);

var
  FlipProgram:array[0..27]of record swap0,swap1:byte end;

procedure _PrepareFlipProgram;//in initialize section
var i,j,n:integer;
begin
  n:=0;for i:=1 to 7 do for j:=i to 7 do with flipProgram[n]do begin
    swap0:=j+(i-1)*8;
    swap1:=j*8+(i-1);
    inc(n);
  end;
end;

procedure _Flip(table:PLinearBlockW);
var i:integer;tmp:smallint;
begin
  for i:=0 to high(FlipProgram)do with FlipProgram[i]do begin
    tmp         :=table[swap0];
    table[swap0]:=table[swap1];
    table[swap1]:=tmp;
  end;
end;

procedure _DCT8_vertical(dIn,dOut:PLinearBlockW);
{  function mul(a:smallint;const b:TSSEReg):smallint;
  begin
    result:=sar(a*smallint(b.W[0]),13);
  end;}
  function mul(a:smallint;const b:TSSEReg):smallint;
  asm
    mov dx,word ptr[edx]
    sal ax,2
    imul dx
    mov ax,dx
  end;
var i:integer;
    tmp0, tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7,
    tmp10, tmp11, tmp12, tmp13,
    z1, z2, z3, z4, z5, z11, z13:smallint;
begin
  for i := 0 to 7 do begin
    tmp4 := dIn[24] - dIn[32];
    tmp5 := dIn[16] - dIn[40];
    tmp6 := dIn[ 8] - dIn[48];
    tmp7 := dIn[ 0] - dIn[56];
    tmp0 := dIn[ 0] + dIn[56];
    tmp1 := dIn[ 8] + dIn[48];
    tmp2 := dIn[16] + dIn[40];
    tmp3 := dIn[24] + dIn[32];

    (* Even part *)
    tmp10 := tmp0 + tmp3;
    tmp13 := tmp0 - tmp3;

    tmp11 := tmp1 + tmp2;
    tmp12 := tmp1 - tmp2;

    dOut[0] := tmp10 + tmp11;
    dOut[32] := tmp10 - tmp11;

    z1 := mul(tmp12 + tmp13,SSEData.w0_707106781); (* c4 *)
    dOut[16] := tmp13 + z1;
    dOut[48] := tmp13 - z1;

    (* Odd part *)

    tmp10 := tmp4 + tmp5;	(* phase 2 *)
    tmp11 := tmp5 + tmp6;
    tmp12 := tmp6 + tmp7;

    z5 := mul(tmp10 - tmp12,SSEData.w0_382683433); (* c6 *)
    z2 := mul(tmp10,SSEData.w0_541196100)+z5; (* c2-c6 *)
    z4 := mul(tmp12,SSEData.w1_306562965)+z5; (* c2+c6 *)
    z3 := mul(tmp11,SSEData.w0_707106781); (* c4 *)

    z11 := tmp7 + z3;		(* phase 5 *)
    z13 := tmp7 - z3;

    dOut[40] := z13 + z2; (* phase 6 *)
    dOut[24] := z13 - z2;
    dOut[ 8] := z11 + z4;
    dOut[56] := z11 - z4;

    pInc(dIn,2);pInc(dOut,2);			(* advance pointer to next column *)
  end;
end;

procedure _IDCT8_vertical(dIn,dOut:PLinearBlockW);
  function mul2(a:smallint;const b:TSSEReg):smallint;
  asm
    mov dx,word ptr[edx]
    sal ax,2
    imul dx
    mov ax,dx
  end;
  function mul3(a:smallint;const b:TSSEReg):smallint;
  asm
    mov dx,word ptr[edx]
    sal ax,3
    imul dx
    mov ax,dx
  end;
var
 i:integer;
 tmp0,tmp1,tmp2,tmp3,tmp4,tmp5,tmp6,tmp7,
 tmp10,tmp11,tmp12,tmp13,
 z5,z10,z11,z12,z13:smallint;
begin
  for i:=0 to 7 do begin
//load                                                                      //
    tmp0 := dIn[0] ;
    tmp1 := dIn[16];
    tmp2 := dIn[32];
    tmp3 := dIn[48];
//process                                                                   //
    tmp10 := tmp0 + tmp2;
    tmp11 := tmp0 - tmp2;

    tmp13 := tmp1 + tmp3;
    tmp12 :=mul2((tmp1 - tmp3),SSEData.w1_414213562) - tmp13;

    tmp0 := tmp10 + tmp13;
    tmp3 := tmp10 - tmp13;
    tmp1 := tmp11 + tmp12;
    tmp2 := tmp11 - tmp12;
//read2                                                                         //
    tmp4 := dIn[8] ;
    tmp5 := dIn[24];
    tmp6 := dIn[40];
    tmp7 := dIn[56];
//process2                                                                      //
    z13 := tmp6 + tmp5;
    z10 := tmp6 - tmp5;
    z11 := tmp4 + tmp7;
    z12 := tmp4 - tmp7;

    tmp7 := z11 + z13;
    tmp11:= mul2((z11 - z13),SSEData.w1_414213562);

    z5 :=mul2((z10 + z12),SSEData.w1_847759065);
    tmp12 := mul3(z10,SSEData.w_2_613125930) + z5;
    tmp10 := mul2(z12,SSEData.w1_082392200) - z5;

    tmp6 := tmp12 - tmp7;
    tmp5 := tmp11 - tmp6;
    tmp4 := tmp10 + tmp5;
//write                                                                         //
    dOut[0]  := tmp0 + tmp7;
    dOut[56] := tmp0 - tmp7;
    dOut[8]  := tmp1 + tmp6;
    dOut[48] := tmp1 - tmp6;
    dOut[16] := tmp2 + tmp5;
    dOut[40] := tmp2 - tmp5;
    dOut[32] := tmp3 + tmp4;
    dOut[24] := tmp3 - tmp4;

    pInc(dIn,2);pInc(dOut,2);			(* advance pointer to next column *)
  end;
end;


procedure _DCT8(block,quant:PLinearBlockW);
  //imul, round high part based on low pard
  function iMul(a,b:smallint):smallint;asm imul dx;mov ax,dx;shr dx,15;add ax,dx end;
var i:integer;
begin
  for i:=0 to 63 do block[i]:=block[i]-128;
  _DCT8_vertical(block,block);
  _Flip(block);
  _DCT8_vertical(block,block);
  for i:=0 to 63 do block[i]:=iMul(block[i],quant[i]); //range: +-2047
end;

procedure _DCT8_SSE(block,quant,constants:PLinearBlockW);
//w256          [ecx+$00]
//w0_707106781  [ecx+$10]
//w0_382683433  [ecx+$20]
//w0_541196100  [ecx+$30]
//w1_306562965  [ecx+$40]
asm
  movaps xmm5,[eax+0]; pxor xmm0,xmm0; movaps xmm1,[eax+16]; movaps xmm7,xmm5; punpcklbw xmm7,xmm0; punpckhbw xmm5,xmm0; movaps [eax+80],xmm5; movaps xmm2,xmm1; movaps xmm5,[eax+32]; punpcklbw xmm2,xmm0; punpckhbw xmm1,xmm0; movaps xmm4,xmm5; punpcklbw xmm4,xmm0; movaps xmm6,[eax+48]; punpckhbw xmm5,xmm0; movaps xmm3,xmm6; punpcklbw xmm3,xmm0; punpckhbw xmm6,xmm0; movaps xmm0,xmm7; paddw xmm0,xmm6; psubw xmm0,[ecx+$00]; psubw xmm7,xmm6; movaps xmm6,xmm2; psubw xmm6,xmm5; movaps [eax+112],xmm6; paddw xmm2,xmm5; psubw xmm2,[ecx+$00]; movaps xmm6,xmm1; psubw xmm6,xmm4; movaps [eax+96],xmm6; paddw xmm4,xmm1; psubw xmm4,[ecx+$00]; movaps xmm1,[eax+80]; paddw xmm1,xmm3; movaps xmm6,[eax+80]; psubw xmm6,xmm3; psubw xmm1,[ecx+$00]; movaps xmm3,xmm4; movaps xmm4,xmm0; paddw xmm4,xmm3; movaps xmm5,xmm1; paddw xmm5,xmm2; psubw xmm0,xmm3; psubw xmm1,xmm2; movaps xmm2,xmm4; paddw xmm2,xmm5; movaps [eax+80],xmm2; psubw xmm4,xmm5; movaps [eax+64],xmm4; movaps xmm2,xmm0; paddw xmm2,xmm1
  psllw xmm2,2; pmulhw xmm2,[ecx+$10]; movaps xmm1,xmm0; paddw xmm0,xmm2; psubw xmm1,xmm2; movaps [eax+32], xmm1; movaps xmm2, xmm0; movaps xmm4,[eax+96]; movaps xmm5,[eax+112]; paddw xmm4,xmm5; paddw xmm5,xmm6; paddw xmm6,xmm7; psllw xmm4,2; psllw xmm5,2; psllw xmm6,2; movaps xmm0,xmm4; psubw xmm0,xmm6; pmulhw xmm0,[ecx+$20]; pmulhw xmm4,[ecx+$30]; paddw xmm4,xmm0; pmulhw xmm6,[ecx+$40]; paddw xmm6,xmm0; pmulhw xmm5,[ecx+$10]; movaps xmm0,xmm7; paddw xmm7,xmm5; psubw xmm0,xmm5; movaps xmm1,xmm7; paddw xmm7,xmm6; psubw xmm1,xmm6; movaps [eax+0],xmm1; movaps xmm3,xmm0; paddw xmm0,xmm4; movaps xmm6,xmm0; psubw xmm3,xmm4; movaps xmm0,[eax+80]; movaps xmm1,xmm0; punpcklwd xmm0,xmm7; punpckhwd xmm1,xmm7; movaps xmm5, xmm2; punpcklwd xmm2, xmm3; punpckhwd xmm5,xmm3; movaps xmm4, xmm0; movaps xmm3,xmm1; punpckldq xmm0, xmm2; punpckhdq xmm4, xmm2; movaps [eax+48], xmm4; punpckldq xmm1,xmm5; punpckhdq xmm3,xmm5; movaps xmm4,[eax+64]
  movaps [eax+16],xmm3; movaps xmm5,xmm4; punpcklwd xmm4,xmm6; punpckhwd xmm5,xmm6; movaps xmm2, [eax+32]; movaps xmm3,xmm2; punpcklwd xmm2,[eax+0]; punpckhwd xmm3,[eax+0]; movaps xmm6,xmm4; movaps xmm7,xmm5; punpckldq xmm4,xmm2; punpckhdq xmm6,xmm2; punpckldq xmm5,xmm3; punpckhdq xmm7,xmm3; movaps xmm2,xmm0; unpcklpd xmm0,xmm4; unpckhpd xmm2,xmm4; movaps [eax+80],xmm0; movaps [eax+64],xmm2; movaps xmm3,xmm1; unpcklpd xmm1,xmm5; movaps [eax+32],xmm1; unpckhpd xmm3,xmm5; movaps [eax+0],xmm3; movaps xmm0,[eax+48]; movaps xmm2,xmm0; unpcklpd xmm0,xmm6; unpckhpd xmm2,xmm6; movaps xmm4,xmm2; movaps xmm1,[eax+16]; movaps xmm3,xmm1; unpcklpd xmm1,xmm7; unpckhpd xmm3,xmm7; movaps xmm7,[eax+80]; psubw xmm7,xmm3; movaps xmm6,[eax+64]; psubw xmm6,xmm1; movaps xmm5,xmm0; psubw xmm5,[eax+0]; movaps [eax+48],xmm5; movaps xmm5,xmm4; psubw xmm5,[eax+32]; movaps [eax+16],xmm5; movaps xmm2,xmm0; paddw xmm2,[eax+0]; movaps xmm0,[eax+80]; paddw xmm0,xmm3; paddw xmm1,[eax+64]; movaps xmm3,xmm4
  paddw xmm3,[eax+32]; movaps xmm4,xmm0; paddw xmm4,xmm3; movaps xmm5,xmm1; paddw xmm5,xmm2; psubw xmm0,xmm3; psubw xmm1,xmm2; movaps xmm2,xmm4; paddw xmm2,xmm5; pmulhw xmm2,[edx+0]; movaps xmm3,xmm2; psrlw xmm3,15; paddw xmm2,xmm3; movaps [eax+0],xmm2; psubw xmm4,xmm5; pmulhw xmm4,[edx+64]; movaps xmm3,xmm4; psrlw xmm3,15; paddw xmm4,xmm3; movaps [eax+64],xmm4; movaps xmm2,xmm0; paddw xmm2,xmm1; psllw xmm2,2; pmulhw xmm2,[ecx+$10]; movaps xmm1,xmm0; paddw xmm0,xmm2; pmulhw xmm0,[edx+32]; movaps xmm3,xmm0; psrlw xmm3,15; paddw xmm0,xmm3; movaps [eax+32],xmm0; psubw xmm1,xmm2; pmulhw xmm1,[edx+96]; movaps xmm3,xmm1; psrlw xmm3,15; paddw xmm1,xmm3; movaps [eax+96],xmm1; movaps xmm4,[eax+16]; movaps xmm5,[eax+48]; paddw xmm4,xmm5; paddw xmm5,xmm6; paddw xmm6,xmm7; psllw xmm4,2; psllw xmm5,2; psllw xmm6,2; movaps xmm0,xmm4; psubw xmm0,xmm6; pmulhw xmm0,[ecx+$20]; pmulhw xmm4,[ecx+$30]; paddw xmm4,xmm0; pmulhw xmm6,[ecx+$40]; paddw xmm6,xmm0
  pmulhw xmm5,[ecx+$10]; movaps xmm0,xmm7; paddw xmm7,xmm5; psubw xmm0,xmm5; movaps xmm1,xmm0; paddw xmm0,xmm4; pmulhw xmm0,[edx+80]; movaps xmm3,xmm0; psrlw xmm3,15; paddw xmm0,xmm3; movaps [eax+80],xmm0; psubw xmm1,xmm4; pmulhw xmm1,[edx+48]; movaps xmm3,xmm1; psrlw xmm3,15; paddw xmm1,xmm3; movaps [eax+48],xmm1; movaps xmm1,xmm7; paddw xmm7,xmm6; pmulhw xmm7,[edx+16]; movaps xmm3,xmm7; psrlw xmm3,15; paddw xmm7,xmm3; movaps [eax+16],xmm7; psubw xmm1,xmm6; pmulhw xmm1,[edx+112]; movaps xmm3,xmm1; psrlw xmm3,15; paddw xmm1,xmm3; movaps [eax+112],xmm1

(*  ret

  //time:1000
  mov ecx,edx;{quant,result}mov edx,eax;
  movaps xmm4,[eax+$00];
  movaps xmm5,[eax+$10];
  movaps xmm6,[eax+$20];
  movaps xmm7,[eax+$30];
  pxor xmm3,xmm3

  movaps xmm0,xmm4;punpcklbw xmm0,xmm3;movaps [eax+$00],xmm0;punpckhbw xmm4,xmm3;movaps [eax+$10],xmm4;
  movaps xmm0,xmm5;punpcklbw xmm0,xmm3;movaps [eax+$20],xmm0;punpckhbw xmm5,xmm3;movaps [eax+$30],xmm5;
  movaps xmm0,xmm6;punpcklbw xmm0,xmm3;movaps [eax+$40],xmm0;punpckhbw xmm6,xmm3;movaps [eax+$50],xmm6;
  movaps xmm0,xmm7;punpcklbw xmm0,xmm3;movaps [eax+$60],xmm0;punpckhbw xmm7,xmm3;movaps [eax+$70],xmm7;

  movaps xmm0,[eax+$00]; paddw xmm0,[eax+$70]; psubw xmm0,SSERegs.w256;
  movaps xmm1,[eax+$10]; paddw xmm1,[eax+$60]; psubw xmm1,SSERegs.w256;
  movaps xmm2,[eax+$20]; paddw xmm2,[eax+$50]; psubw xmm2,SSERegs.w256;
  movaps xmm3,[eax+$30]; paddw xmm3,[eax+$40]; psubw xmm3,SSERegs.w256;

  movaps xmm7,[eax+$00]; psubw xmm7,[eax+$70]; //movaps SSERegs.tmp7,xmm7
  movaps xmm6,[eax+$10]; psubw xmm6,[eax+$60]; //movaps SSERegs.tmp6,xmm6
  movaps xmm5,[eax+$20]; psubw xmm5,[eax+$50]; movaps SSERegs.tmp5,xmm5
  movaps xmm4,[eax+$30]; psubw xmm4,[eax+$40]; movaps SSERegs.tmp4,xmm4

  //Even part
  movaps xmm4,xmm0; paddw xmm4,xmm3 //tmp10:=tmp0+tmp3;
  movaps xmm5,xmm1; paddw xmm5,xmm2 //tmp11:=tmp1+tmp2;
  psubw xmm0,xmm3                   //tmp13:=tmp0-tmp3;
  psubw xmm1,xmm2                   //tmp12:=tmp1-tmp2;

  movaps xmm2,xmm4; paddw xmm2,xmm5; movaps [eax+$00],xmm2; //data[0]:=tmp10+tmp11
                    psubw xmm4,xmm5; movaps [eax+$40],xmm4; //data[4]:=tmp10-tmp11

  movaps xmm2,xmm0; paddw xmm2,xmm1; psllw xmm2,2; pmulhw xmm2,SSERegs.w0_707106781; //z1:=(tmp12+tmp13)*0.707106781
  movaps xmm1,xmm0; paddw xmm0,xmm2; movaps [eax+$20],xmm0; //data[1]:=tmp13+z1;
                    psubw xmm1,xmm2; movaps [eax+$60],xmm1; //data[6]:=tmp13-z1;


  //Odd part
  movaps xmm4,SSERegs.tmp4; movaps xmm5,SSERegs.tmp5;

  paddw xmm4,xmm5; //tmp10:=tmp4+tmp5;
  paddw xmm5,xmm6; //tmp11:=tmp5+tmp6;
  paddw xmm6,xmm7; //tmp12:=tmp6+tmp7;

  psllw xmm4,2;
  psllw xmm5,2;
  psllw xmm6,2;

  movaps xmm0,xmm4; psubw xmm0,xmm6; {psllw xmm0,2;} pmulhw xmm0,SSERegs.w0_382683433; //z5:=(tmp10-tmp12)*0.382683433;
  {psllw xmm4,2;} pmulhw xmm4,SSERegs.w0_541196100; paddw xmm4,xmm0; //z2:=tmp10*0.541196100+z5;
  {psllw xmm6,2;} pmulhw xmm6,SSERegs.w1_306562965; paddw xmm6,xmm0; //z4:=tmp12*1.306562965+z5;
  {psllw xmm5,2;} pmulhw xmm5,SSERegs.w0_707106781;                  //z3:=tmp11*0.707106781;

  movaps xmm0,xmm7; paddw xmm7,xmm5; //z11:=tmp7+z3;
                    psubw xmm0,xmm5  //z13:=tmp7-z3;

  movaps xmm1,xmm7; paddw xmm7,xmm6; //movaps [eax+$10],xmm7; //data[1]:=z11+z4;
                    psubw xmm1,xmm6; movaps [eax+$70],xmm1; //data[7]:=z11-z4;
  movaps xmm3,xmm0; paddw xmm0,xmm4; movaps xmm6,xmm0//movaps [eax+$50],xmm0; //data[5]:=z13+z2;
                    psubw xmm3,xmm4; //movaps [eax+$30],xmm3; //data[3]:=z13-z2;

////////////////////////////////////////////////////////////////////////////////
//  FlipTable_PW;
  movaps xmm0,[eax+$00]
  movaps xmm1,xmm0
  punpcklwd xmm0,xmm7//[eax+$10]
  punpckhwd xmm1,xmm7//[eax+$10]

  movaps xmm4,[eax+$20]
  movaps xmm5,xmm4
  punpcklwd xmm4,xmm3//[eax+$30]
  punpckhwd xmm5,xmm3//[eax+$30]

  movaps xmm2,xmm0
  movaps xmm3,xmm1
  punpckldq xmm0,xmm4
  punpckhdq xmm2,xmm4 ;movaps SSERegs.tmp2,xmm2
  punpckldq xmm1,xmm5
  punpckhdq xmm3,xmm5 ;movaps SSERegs.tmp3,xmm3

  movaps xmm4,[eax+$40]
  movaps xmm5,xmm4
  punpcklwd xmm4,xmm6//[eax+$50]
  punpckhwd xmm5,xmm6//[eax+$50]

  movaps xmm2,[eax+$60]
  movaps xmm3,xmm2
  punpcklwd xmm2,[eax+$70]
  punpckhwd xmm3,[eax+$70]

  movaps xmm6,xmm4
  movaps xmm7,xmm5
  punpckldq xmm4,xmm2
  punpckhdq xmm6,xmm2
  punpckldq xmm5,xmm3
  punpckhdq xmm7,xmm3

  movaps xmm2,xmm0
  unpcklpd xmm0,xmm4 ;movaps [eax+$00],xmm0
  unpckhpd xmm2,xmm4 ;movaps [eax+$10],xmm2

  movaps xmm3,xmm1
  unpcklpd xmm1,xmm5 ;movaps [eax+$40],xmm1
  unpckhpd xmm3,xmm5 ;movaps [eax+$50],xmm3

  movaps xmm0,SSERegs.tmp2; movaps xmm2,xmm0
  unpcklpd xmm0,xmm6 //;movaps [eax+$20],xmm0
  unpckhpd xmm2,xmm6 ;movaps xmm4,xmm2//;movaps [eax+$30],xmm2

  movaps xmm1,SSERegs.tmp3; movaps xmm3,xmm1
  unpcklpd xmm1,xmm7 //;movaps [eax+$60],xmm1
  unpckhpd xmm3,xmm7 //;movaps [eax+$70],xmm3

////////////////////////////////////////////////////////////////////////////////

  movaps xmm7,[eax+$00]; psubw xmm7,xmm3//[eax+$70]; //movaps SSERegs.tmp7,xmm7
  movaps xmm6,[eax+$10]; psubw xmm6,xmm1//[eax+$60]; //movaps SSERegs.tmp6,xmm6
  movaps xmm5,xmm0{[eax+$20]}; psubw xmm5,[eax+$50]; movaps SSERegs.tmp5,xmm5
  movaps xmm5,xmm4{[eax+$30]}; psubw xmm5,[eax+$40]; movaps SSERegs.tmp4,xmm5

  movaps xmm2,xmm0{[eax+$20]}; paddw xmm2,[eax+$50]
  movaps xmm0,[eax+$00]; paddw xmm0,xmm3//[eax+$70]
  paddw xmm1,[eax+$10];//movaps xmm1,[eax+$10]; paddw xmm1,[eax+$60]
  movaps xmm3,xmm4{[eax+$30]}; paddw xmm3,[eax+$40]

  //Even part
  movaps xmm4,xmm0; paddw xmm4,xmm3 //tmp10:=tmp0+tmp3;
  movaps xmm5,xmm1; paddw xmm5,xmm2 //tmp11:=tmp1+tmp2;
  psubw xmm0,xmm3                   //tmp13:=tmp0-tmp3;
  psubw xmm1,xmm2                   //tmp12:=tmp1-tmp2;

  movaps xmm2,xmm4; paddw xmm2,xmm5; {quant}pmulhw xmm2,[ecx+$00];movaps xmm3,xmm2;psrlw xmm3,15;paddw xmm2,xmm3; movaps [edx+$00],xmm2; //data[0]:=tmp10+tmp11
                    psubw xmm4,xmm5; {quant}pmulhw xmm4,[ecx+$40];movaps xmm3,xmm4;psrlw xmm3,15;paddw xmm4,xmm3; movaps [edx+$40],xmm4; //data[4]:=tmp10-tmp11

  movaps xmm2,xmm0; paddw xmm2,xmm1; psllw xmm2,2; pmulhw xmm2,SSERegs.w0_707106781; //z1:=(tmp12+tmp13)*0.707106781
  movaps xmm1,xmm0; paddw xmm0,xmm2; {quant}pmulhw xmm0,[ecx+$20];movaps xmm3,xmm0;psrlw xmm3,15;paddw xmm0,xmm3; movaps [edx+$20],xmm0; //data[1]:=tmp13+z1;
                    psubw xmm1,xmm2; {quant}pmulhw xmm1,[ecx+$60];movaps xmm3,xmm1;psrlw xmm3,15;paddw xmm1,xmm3; movaps [edx+$60],xmm1; //data[6]:=tmp13-z1;

  //Odd part
  movaps xmm4,SSERegs.tmp4; movaps xmm5,SSERegs.tmp5;

  paddw xmm4,xmm5; //tmp10:=tmp4+tmp5;
  paddw xmm5,xmm6; //tmp11:=tmp5+tmp6;
  paddw xmm6,xmm7; //tmp12:=tmp6+tmp7;

  psllw xmm4,2;
  psllw xmm5,2;
  psllw xmm6,2;

  movaps xmm0,xmm4; psubw xmm0,xmm6; {psllw xmm0,2; }pmulhw xmm0,SSERegs.w0_382683433; //z5:=(tmp10-tmp12)*0.382683433;
  {psllw xmm4,2; }pmulhw xmm4,SSERegs.w0_541196100; paddw xmm4,xmm0; //z2:=tmp10*0.541196100+z5;
  {psllw xmm6,2; }pmulhw xmm6,SSERegs.w1_306562965; paddw xmm6,xmm0; //z4:=tmp12*1.306562965+z5;
  {psllw xmm5,2; }pmulhw xmm5,SSERegs.w0_707106781;                  //z3:=tmp11*0.707106781;

  movaps xmm0,xmm7; paddw xmm7,xmm5; //z11:=tmp7+z3;
                    psubw xmm0,xmm5  //z13:=tmp7-z3;

  movaps xmm1,xmm0; paddw xmm0,xmm4;  {quant}pmulhw xmm0,[ecx+$50];movaps xmm3,xmm0;psrlw xmm3,15;paddw xmm0,xmm3; movaps [edx+$50],xmm0; //data[5]:=z13+z2;
                    psubw xmm1,xmm4;  {quant}pmulhw xmm1,[ecx+$30];movaps xmm3,xmm1;psrlw xmm3,15;paddw xmm1,xmm3; movaps [edx+$30],xmm1; //data[3]:=z13-z2;
  movaps xmm1,xmm7; paddw xmm7,xmm6;  {quant}pmulhw xmm7,[ecx+$10];movaps xmm3,xmm7;psrlw xmm3,15;paddw xmm7,xmm3; movaps [edx+$10],xmm7; //data[1]:=z11+z4;
                    psubw xmm1,xmm6;  {quant}pmulhw xmm1,[ecx+$70];movaps xmm3,xmm1;psrlw xmm3,15;paddw xmm1,xmm3; movaps [edx+$70],xmm1; //data[7]:=z11-z4;
*)
end;

procedure _IDCT8(block,quant:PLinearBlockW);
var i:integer;
begin
  for i:=0 to 63 do block[i]:=block[i]*quant[i];
  _IDCT8_vertical(block,block);
  _Flip(block);
  _IDCT8_vertical(block,block);
  for i:=0 to 63 do block[i]:=EnsureRange(sar(block[i],3)+128,0,255); //range 0..255
end;

procedure _IDCT8_SSE(block,quant,constants:PLinearBlockW);
//w1_414213562 [ecx+$50]
//w1_847759065 [ecx+$60]
//w1_082392200 [ecx+$70]
//w_2_613125930 [ecx+$80]
//

asm
  movaps xmm7, [eax+0]; pmullw xmm7, [edx+0]; movaps xmm1,[eax+32]; pmullw xmm1,[edx+32]; movaps xmm2,[eax+64]; pmullw xmm2,[edx+64]; movaps xmm3,[eax+96]; pmullw xmm3,[edx+96]; movaps xmm4, xmm7; psubw xmm7, xmm2; paddw xmm4,xmm2; movaps xmm5, xmm1; paddw xmm5, xmm3; movaps xmm6,xmm1; psubw xmm6,xmm3; psllw xmm6,2; pmulhw xmm6,[ecx+$50]; psubw xmm6, xmm5; movaps xmm0, xmm4; paddw xmm0, xmm5; psubw xmm4, xmm5; movaps [eax+96], xmm4; movaps xmm1, xmm7; paddw xmm1, xmm6; psubw xmm7, xmm6; movaps xmm4,[eax+16]; pmullw xmm4,[edx+16]; movaps xmm5,[eax+48]; pmullw xmm5,[edx+48]; movaps xmm6,[eax+80]; pmullw xmm6,[edx+80]; movaps xmm2, [eax+112]; pmullw xmm2, [edx+112]; movaps xmm3, xmm4; paddw xmm3, xmm2; psubw xmm4, xmm2; movaps xmm2, xmm6; paddw xmm2, xmm5; psubw xmm6, xmm5; movaps xmm5, xmm3; paddw xmm5, xmm2; psubw xmm3, xmm2; psllw xmm3, 2; pmulhw xmm3, [ecx+$50]; movaps xmm2, xmm6; paddw xmm2, xmm4; psllw xmm2, 2; pmulhw xmm2, [ecx+$60]; psllw xmm4, 2
  pmulhw xmm4, [ecx+$70]; psubw xmm4, xmm2; psllw xmm6, 3; pmulhw xmm6, [ecx+$80]; paddw xmm6, xmm2; psubw xmm6, xmm5; psubw xmm3, xmm6; paddw xmm4, xmm3; movaps xmm2, xmm0; paddw xmm0, xmm5; psubw xmm2, xmm5; movaps xmm5, xmm2; movaps xmm2, xmm1; paddw xmm2, xmm6; psubw xmm1, xmm6; movaps xmm6, xmm7; paddw xmm7, xmm3; psubw xmm6, xmm3; movaps [eax+112], xmm1; movaps xmm3, [eax+96]; movaps xmm1, xmm3; paddw xmm1, xmm4; movaps [eax+96], xmm1; psubw xmm3,xmm4; movaps xmm1,xmm0; punpcklwd xmm0, xmm2; punpckhwd xmm1, xmm2; movaps xmm4, xmm7; punpcklwd xmm7, xmm3; punpckhwd xmm4, xmm3; movaps xmm2,xmm0; movaps xmm3,xmm1; punpckldq xmm0, xmm7; punpckhdq xmm2, xmm7; movaps [eax+48], xmm2; punpckldq xmm1, xmm4; punpckhdq xmm3, xmm4; movaps [eax+32], xmm3; movaps xmm2, [eax+112]; movaps xmm3,xmm2; punpcklwd xmm2, xmm5; punpckhwd xmm3, xmm5; movaps xmm4, [eax+96]; movaps xmm5,xmm4; punpcklwd xmm4, xmm6; punpckhwd xmm5, xmm6; movaps xmm6,xmm4; movaps xmm7,xmm5
  punpckldq xmm4,xmm2; punpckhdq xmm6,xmm2; punpckldq xmm5,xmm3; punpckhdq xmm7,xmm3; movaps xmm2,xmm0; punpcklqdq xmm0,xmm4; movaps [eax+0],xmm0; punpckhqdq xmm2,xmm4; movaps [eax+16],xmm2; movaps xmm3,xmm1; punpcklqdq xmm1,xmm5; movaps [eax+64],xmm1; punpckhqdq xmm3,xmm5; movaps [eax+80],xmm3; movaps xmm3, [eax+32]; movaps xmm0, [eax+48]; movaps xmm2,xmm0; punpcklqdq xmm0,xmm6; movaps [eax+32],xmm0; punpckhqdq xmm2,xmm6; movaps [eax+48],xmm2; movaps xmm5, xmm3; punpcklqdq xmm3, xmm7; movaps [eax+96], xmm3; punpckhqdq xmm5, xmm7; movaps [eax+112], xmm5; movaps xmm0,[eax+0]; movaps xmm1,[eax+32]; movaps xmm2,[eax+64]; movaps xmm3,[eax+96]; movaps xmm4,xmm0; paddw xmm4,xmm2; movaps xmm5,xmm0; psubw xmm5,xmm2; movaps xmm7,xmm1; paddw xmm7,xmm3; movaps xmm6,xmm1; psubw xmm6,xmm3; psllw xmm6,2; pmulhw xmm6,[ecx+$50]; psubw xmm6,xmm7; movaps xmm0,xmm4; paddw xmm0,xmm7; movaps [eax+0], xmm0; movaps xmm0,xmm4; psubw xmm0,xmm7; movaps [eax+96], xmm0; movaps xmm0,xmm5; paddw xmm0,xmm6
  movaps [eax+32], xmm0; movaps xmm0,xmm5; psubw xmm0,xmm6; movaps [eax+64], xmm0; movaps xmm4,[eax+16]; movaps xmm5,[eax+48]; movaps xmm6,[eax+80]; movaps xmm7,[eax+112]; movaps xmm1,xmm4; paddw xmm1,xmm7; movaps xmm2,xmm4; psubw xmm2,xmm7; movaps xmm3,xmm6; paddw xmm3,xmm5; psubw xmm6,xmm5; movaps xmm7,xmm1; paddw xmm7,xmm3; psubw xmm1,xmm3; psllw xmm1,2; pmulhw xmm1,[ecx+$50]; movaps xmm3,xmm6; paddw xmm3,xmm2; psllw xmm3,2; pmulhw xmm3,[ecx+$60]; movaps xmm4,xmm2; psllw xmm4,2; pmulhw xmm4,[ecx+$70]; psubw xmm4,xmm3; movaps xmm6,xmm6; psllw xmm6,3; pmulhw xmm6,[ecx+$80]; paddw xmm6,xmm3; psubw xmm6,xmm7; movaps xmm5,xmm1; psubw xmm5,xmm6; paddw xmm4,xmm5; movaps xmm3, [eax+0]; psubw xmm3,xmm7; movaps xmm2, [eax+32]; psubw xmm2,xmm6; movaps xmm0, [eax+0]; paddw xmm0,xmm7; movaps xmm1, [eax+32]; paddw xmm1,xmm6; pcmpeqw xmm7,xmm7; psrlw xmm7,15; psllw xmm7,7; psraw xmm2,3; psraw xmm3,3; paddw xmm2,xmm7; paddw xmm3,xmm7; packuswb xmm2,xmm3
  movaps [eax+48],xmm2; movaps xmm3, [eax+96]; paddw xmm3,xmm4; movaps xmm2, [eax+64]; psubw xmm2,xmm5; psraw xmm3,3; psraw xmm2,3; paddw xmm3,xmm7; paddw xmm2,xmm7; packuswb xmm3,xmm2; movaps [eax+32],xmm3; psraw xmm0,3; psraw xmm1,3; paddw xmm0,xmm7; paddw xmm1,xmm7; packuswb xmm0,xmm1; movaps [eax+0],xmm0; movaps xmm2, [eax+64]; paddw xmm2,xmm5; movaps xmm3, [eax+96]; psubw xmm3,xmm4; psraw xmm2,3; psraw xmm3,3; paddw xmm2,xmm7; paddw xmm3,xmm7; packuswb xmm2,xmm3; movaps [eax+16],xmm2



(*
    movaps xmm0,[eax+$00];pmullw xmm0,[edx+$00];//movaps xmm7,xmm0;psrlw xmm7,15;paddw xmm0,xmm7;//xmm0 := dIn[0] ;
    movaps xmm1,[eax+$20];pmullw xmm1,[edx+$20];//movaps xmm7,xmm1;psrlw xmm7,15;paddw xmm1,xmm7;//xmm1 := dIn[16];
    movaps xmm2,[eax+$40];pmullw xmm2,[edx+$40];//movaps xmm7,xmm2;psrlw xmm7,15;paddw xmm2,xmm7;//xmm2 := dIn[32];
    movaps xmm3,[eax+$60];pmullw xmm3,[edx+$60];//movaps xmm7,xmm3;psrlw xmm7,15;paddw xmm3,xmm7;//xmm3 := dIn[48];
//process                                                                   //
    movaps xmm4,xmm0;paddw xmm4,xmm2//xmm4 := xmm0 + xmm2;
    movaps xmm5,xmm0;psubw xmm5,xmm2//xmm5 := xmm0 - xmm2;

    movaps xmm7,xmm1;paddw xmm7,xmm3;//xmm7 := xmm1 + xmm3;
    movaps xmm6,xmm1;psubw xmm6,xmm3;psllw xmm6,2;pmulhw xmm6,SSERegs.w1_414213562;psubw xmm6,xmm7;//xmm6 :=mul2((xmm1 - xmm3),SSERegs.w1_414213562) - xmm7;

    movaps xmm0,xmm4;paddw xmm0,xmm7;movaps SSERegs.tmp0,xmm0//tmp0 := xmm4 + xmm7;
    movaps xmm0,xmm4;psubw xmm0,xmm7;movaps SSERegs.tmp3,xmm0//tmp3 := xmm4 - xmm7;
    movaps xmm0,xmm5;paddw xmm0,xmm6;movaps SSERegs.tmp1,xmm0//tmp1 := xmm5 + xmm6;
    movaps xmm0,xmm5;psubw xmm0,xmm6;movaps SSERegs.tmp2,xmm0//tmp2 := xmm5 - xmm6;
//read2                                                                         //
    movaps xmm4,[eax+$10];pmullw xmm4,[edx+$10];//movaps xmm0,xmm4;psrlw xmm0,15;paddw xmm4,xmm0;//xmm4 := dIn[8] ;
    movaps xmm5,[eax+$30];pmullw xmm5,[edx+$30];//movaps xmm0,xmm5;psrlw xmm0,15;paddw xmm5,xmm0;//xmm5 := dIn[24];
    movaps xmm6,[eax+$50];pmullw xmm6,[edx+$50];//movaps xmm0,xmm6;psrlw xmm0,15;paddw xmm6,xmm0;//xmm6 := dIn[40];
    movaps xmm7,[eax+$70];pmullw xmm7,[edx+$70];//movaps xmm0,xmm7;psrlw xmm0,15;paddw xmm7,xmm0;//xmm7 := dIn[56];
//process2                                                                      //
    movaps xmm1,xmm4;paddw xmm1,xmm7//xmm1 := xmm4 + xmm7;
    movaps xmm2,xmm4;psubw xmm2,xmm7//xmm2 := xmm4 - xmm7;
    movaps xmm3,xmm6;paddw xmm3,xmm5//xmm3 := xmm6 + xmm5;
    movaps xmm0,xmm6;psubw xmm0,xmm5//xmm0 := xmm6 - xmm5;

    movaps xmm7,xmm1;paddw xmm7,xmm3//xmm7 := xmm1 + xmm3;
    psubw xmm1,xmm3;psllw xmm1,2;pmulhw xmm1,SSERegs.w1_414213562//xmm1:= mul2((xmm1 - xmm3),SSERegs.w1_414213562);

    movaps xmm6,xmm0;paddw xmm6,xmm2;psllw xmm6,2;pmulhw xmm6,SSERegs.w1_847759065//xmm6 :=mul2((xmm0 + xmm2),SSERegs.w1_847759065);
    movaps xmm3,xmm2;psllw xmm3,2;pmulhw xmm3,SSERegs.w1_082392200;psubw xmm3,xmm6//xmm3 := mul2(xmm2,SSERegs.w1_082392200) - xmm6;
    movaps xmm2,xmm0;psllw xmm2,3;pmulhw xmm2,SSERegs.w_2_613125930;paddw xmm2,xmm6//xmm2 := mul3(xmm0,SSERegs.w_2_613125930) + xmm6;

    movaps xmm6,xmm2;psubw xmm6,xmm7//xmm6 := xmm2 - xmm7;
    movaps xmm5,xmm1;psubw xmm5,xmm6//xmm5 := xmm1 - xmm6;
    movaps xmm4,xmm3;paddw xmm4,xmm5//xmm4 := xmm3 + xmm5;
//write                                                                         //
    movaps xmm0,SSERegs.tmp0;paddw xmm0,xmm7;movaps [eax+$00],xmm0//dOut[0]  := xmm0 + xmm7;
    movaps xmm0,SSERegs.tmp0;psubw xmm0,xmm7;movaps [eax+$70],xmm0//dOut[56] := xmm0 - xmm7;
    movaps xmm1,SSERegs.tmp1;paddw xmm1,xmm6;movaps [eax+$10],xmm1//dOut[8]  := xmm1 + xmm6;
    movaps xmm1,SSERegs.tmp1;psubw xmm1,xmm6;movaps [eax+$60],xmm1//dOut[48] := xmm1 - xmm6;
    movaps xmm2,SSERegs.tmp2;paddw xmm2,xmm5;movaps [eax+$20],xmm2//dOut[16] := xmm2 + xmm5;
    movaps xmm2,SSERegs.tmp2;psubw xmm2,xmm5;movaps [eax+$50],xmm2//dOut[40] := xmm2 - xmm5;
    movaps xmm3,SSERegs.tmp3;paddw xmm3,xmm4;movaps [eax+$40],xmm3//dOut[32] := xmm3 + xmm4;
    movaps xmm3,SSERegs.tmp3;psubw xmm3,xmm4;movaps [eax+$30],xmm3//dOut[24] := xmm3 - xmm4;
{end;

procedure _Flip_SSE(data:PLinearBlockW);
asm}
  movaps xmm0,[eax+$00]
  movaps xmm1,xmm0
  punpcklwd xmm0,[eax+$10]
  punpckhwd xmm1,[eax+$10]

  movaps xmm4,[eax+$20]
  movaps xmm5,xmm4
  punpcklwd xmm4,[eax+$30]
  punpckhwd xmm5,[eax+$30]

  movaps xmm2,xmm0
  movaps xmm3,xmm1
  punpckldq xmm0,xmm4
  punpckhdq xmm2,xmm4 ;movaps SSERegs.tmp2,xmm2
  punpckldq xmm1,xmm5
  punpckhdq xmm3,xmm5 ;movaps SSERegs.tmp3,xmm3

  movaps xmm4,[eax+$40]
  movaps xmm5,xmm4
  punpcklwd xmm4,[eax+$50]
  punpckhwd xmm5,[eax+$50]

  movaps xmm2,[eax+$60]
  movaps xmm3,xmm2
  punpcklwd xmm2,[eax+$70]
  punpckhwd xmm3,[eax+$70]

  movaps xmm6,xmm4
  movaps xmm7,xmm5
  punpckldq xmm4,xmm2
  punpckhdq xmm6,xmm2
  punpckldq xmm5,xmm3
  punpckhdq xmm7,xmm3

  movaps xmm2,xmm0
  punpcklqdq xmm0,xmm4 ;movaps [eax+$00],xmm0
  punpckhqdq xmm2,xmm4 ;movaps [eax+$10],xmm2

  movaps xmm3,xmm1
  punpcklqdq xmm1,xmm5 ;movaps [eax+$40],xmm1
  punpckhqdq xmm3,xmm5 ;movaps [eax+$50],xmm3

  movaps xmm0,SSERegs.tmp2; movaps xmm2,xmm0
  punpcklqdq xmm0,xmm6 ;movaps [eax+$20],xmm0
  punpckhqdq xmm2,xmm6 ;movaps [eax+$30],xmm2

  movaps xmm1,SSERegs.tmp3; movaps xmm3,xmm1
  punpcklqdq xmm1,xmm7 ;movaps [eax+$60],xmm1
  punpckhqdq xmm3,xmm7 ;movaps [eax+$70],xmm3
{end;

procedure _IDCT8_vertical_bottom_SSE(dIn:PLinearBlockW);
asm}
    movaps xmm0,[eax+$00];//xmm0 := dIn[0] ;
    movaps xmm1,[eax+$20];//xmm1 := dIn[16];
    movaps xmm2,[eax+$40];//xmm2 := dIn[32];
    movaps xmm3,[eax+$60];//xmm3 := dIn[48];
//process                                                                   //
    movaps xmm4,xmm0;paddw xmm4,xmm2//xmm4 := xmm0 + xmm2;
    movaps xmm5,xmm0;psubw xmm5,xmm2//xmm5 := xmm0 - xmm2;

    movaps xmm7,xmm1;paddw xmm7,xmm3;//xmm7 := xmm1 + xmm3;
    movaps xmm6,xmm1;psubw xmm6,xmm3;psllw xmm6,2;pmulhw xmm6,SSERegs.w1_414213562;psubw xmm6,xmm7;//xmm6 :=mul2((xmm1 - xmm3),SSERegs.w1_414213562) - xmm7;

    movaps xmm0,xmm4;paddw xmm0,xmm7;movaps SSERegs.tmp0,xmm0//tmp0 := xmm4 + xmm7;
    movaps xmm0,xmm4;psubw xmm0,xmm7;movaps SSERegs.tmp3,xmm0//tmp3 := xmm4 - xmm7;
    movaps xmm0,xmm5;paddw xmm0,xmm6;movaps SSERegs.tmp1,xmm0//tmp1 := xmm5 + xmm6;
    movaps xmm0,xmm5;psubw xmm0,xmm6;movaps SSERegs.tmp2,xmm0//tmp2 := xmm5 - xmm6;
//read2                                                                         //
    movaps xmm4,[eax+$10]//xmm4 := dIn[8] ;
    movaps xmm5,[eax+$30]//xmm5 := dIn[24];
    movaps xmm6,[eax+$50]//xmm6 := dIn[40];
    movaps xmm7,[eax+$70]//xmm7 := dIn[56];
//process2                                                                      //
    movaps xmm1,xmm4;paddw xmm1,xmm7//xmm1 := xmm4 + xmm7;
    movaps xmm2,xmm4;psubw xmm2,xmm7//xmm2 := xmm4 - xmm7;
    movaps xmm3,xmm6;paddw xmm3,xmm5//xmm3 := xmm6 + xmm5;
    movaps xmm0,xmm6;psubw xmm0,xmm5//xmm0 := xmm6 - xmm5;

    movaps xmm7,xmm1;paddw xmm7,xmm3//xmm7 := xmm1 + xmm3;
    psubw xmm1,xmm3;psllw xmm1,2;pmulhw xmm1,SSERegs.w1_414213562//xmm1:= mul2((xmm1 - xmm3),SSERegs.w1_414213562);

    movaps xmm6,xmm0;paddw xmm6,xmm2;psllw xmm6,2;pmulhw xmm6,SSERegs.w1_847759065//xmm6 :=mul2((xmm0 + xmm2),SSERegs.w1_847759065);
    movaps xmm3,xmm2;psllw xmm3,2;pmulhw xmm3,SSERegs.w1_082392200;psubw xmm3,xmm6//xmm3 := mul2(xmm2,SSERegs.w1_082392200) - xmm6;
    movaps xmm2,xmm0;psllw xmm2,3;pmulhw xmm2,SSERegs.w_2_613125930;paddw xmm2,xmm6//xmm2 := mul3(xmm0,SSERegs.w_2_613125930) + xmm6;

    movaps xmm6,xmm2;psubw xmm6,xmm7//xmm6 := xmm2 - xmm7;
    movaps xmm5,xmm1;psubw xmm5,xmm6//xmm5 := xmm1 - xmm6;
    movaps xmm4,xmm3;paddw xmm4,xmm5//xmm4 := xmm3 + xmm5;
//write                                                                         //
    movaps xmm0,SSERegs.tmp0;paddw xmm0,xmm7;movaps [eax+$00],xmm0//dOut[0]  := xmm0 + xmm7;
    movaps xmm0,SSERegs.tmp0;psubw xmm0,xmm7;movaps [eax+$70],xmm0//dOut[56] := xmm0 - xmm7;
    movaps xmm1,SSERegs.tmp1;paddw xmm1,xmm6;movaps [eax+$10],xmm1//dOut[8]  := xmm1 + xmm6;
    movaps xmm1,SSERegs.tmp1;psubw xmm1,xmm6;movaps [eax+$60],xmm1//dOut[48] := xmm1 - xmm6;
    movaps xmm2,SSERegs.tmp2;paddw xmm2,xmm5;movaps [eax+$20],xmm2//dOut[16] := xmm2 + xmm5;
    movaps xmm2,SSERegs.tmp2;psubw xmm2,xmm5;movaps [eax+$50],xmm2//dOut[40] := xmm2 - xmm5;
    movaps xmm3,SSERegs.tmp3;paddw xmm3,xmm4;movaps [eax+$40],xmm3//dOut[32] := xmm3 + xmm4;
    movaps xmm3,SSERegs.tmp3;psubw xmm3,xmm4;movaps [eax+$30],xmm3//dOut[24] := xmm3 - xmm4;


    pcmpeqw xmm7,xmm7
    psrlw xmm7,15
    psllw xmm7,7

    movaps xmm0,[eax+$00];movaps xmm1,[eax+$10];
    psraw xmm0,3;         psraw xmm1,3;
    paddw xmm0,xmm7;      paddw xmm1,xmm7;
    packuswb xmm0,xmm1
    movaps [eax+$00],xmm0

    movaps xmm0,[eax+$20];movaps xmm1,[eax+$30];
    psraw xmm0,3;         psraw xmm1,3;
    paddw xmm0,xmm7;      paddw xmm1,xmm7;
    packuswb xmm0,xmm1
    movaps [eax+$10],xmm0

    movaps xmm0,[eax+$40];movaps xmm1,[eax+$50];
    psraw xmm0,3;         psraw xmm1,3;
    paddw xmm0,xmm7;      paddw xmm1,xmm7;
    packuswb xmm0,xmm1
    movaps [eax+$20],xmm0

    movaps xmm0,[eax+$60];movaps xmm1,[eax+$70];
    psraw xmm0,3;         psraw xmm1,3;
    paddw xmm0,xmm7;      paddw xmm1,xmm7;
    packuswb xmm0,xmm1
    movaps [eax+$30],xmm0
*)
end;

////////////////////////////////////////////////////////////////////////////////
/// Selectable Procs

// DCT

procedure DCT8_Y(WorkArea:PWorkArea);begin with WorkArea^ do begin
  _DCT8(@Y[0],@QTEncY); end;end;

procedure DCT8_YA(WorkArea:PWorkArea);begin with WorkArea^ do begin
  _DCT8(@Y[0],@QTEncY); _DCT8(@Y[1],@QTEncY); end;end;

procedure DCT8_BGR(WorkArea:PWorkArea);begin with WorkArea^ do begin
  _DCT8(@Y[0],@QTEncY); _DCT8(@Y[1],@QTEncY); _DCT8(@Y[2],@QTEncY); end;end;

procedure DCT8_BGRA(WorkArea:PWorkArea);begin with WorkArea^ do begin
  _DCT8(@Y[0],@QTEncY); _DCT8(@Y[1],@QTEncY); _DCT8(@Y[2],@QTEncY); _DCT8(@Y[3],@QTEncY); end;end;

procedure DCT8_YUV(WorkArea:PWorkArea);begin with WorkArea^ do begin
  DCT8_BGRA(WorkArea); _DCT8(@UV[0],@QTEncU); _DCT8(@UV[1],@QTEncV);end;end;

procedure DCT8_YUVA(WorkArea:PWorkArea);begin with WorkArea^ do begin
  DCT8_YUV(WorkArea); _DCT8(@A[0],@QTEncY); _DCT8(@A[1],@QTEncY); _DCT8(@A[2],@QTEncY); _DCT8(@A[3],@QTEncY); end;end;

//  DCT_SSE

procedure DCT8_Y_SSE(WorkArea:PWorkArea);begin with WorkArea^ do begin
  _DCT8_SSE(@Y[0],@QTEncY,@vars); end;end;

procedure DCT8_YA_SSE(WorkArea:PWorkArea);begin with WorkArea^ do begin
  _DCT8_SSE(@Y[0],@QTEncY,@vars); _DCT8_SSE(@Y[1],@QTEncY,@vars); end;end;

procedure DCT8_BGR_SSE(WorkArea:PWorkArea);begin with WorkArea^ do begin
  _DCT8_SSE(@Y[0],@QTEncY,@vars); _DCT8_SSE(@Y[1],@QTEncY,@vars); _DCT8_SSE(@Y[2],@QTEncY,@vars); end;end;

procedure DCT8_BGRA_SSE(WorkArea:PWorkArea);begin with WorkArea^ do begin
  _DCT8_SSE(@Y[0],@QTEncY,@vars); _DCT8_SSE(@Y[1],@QTEncY,@vars); _DCT8_SSE(@Y[2],@QTEncY,@vars); _DCT8_SSE(@Y[3],@QTEncY,@vars); end;end;

procedure DCT8_YUV_SSE(WorkArea:PWorkArea);begin with WorkArea^ do begin
  DCT8_BGRA_SSE(WorkArea); _DCT8_SSE(@UV[0],@QTEncU,@vars); _DCT8_SSE(@UV[1],@QTEncV,@vars); end;end;

procedure DCT8_YUVA_SSE(WorkArea:PWorkArea);begin with WorkArea^ do begin
  DCT8_YUV_SSE(WorkArea); _DCT8_SSE(@A[0],@QTEncY,@vars); _DCT8_SSE(@A[1],@QTEncY,@vars); _DCT8_SSE(@A[2],@QTEncY,@vars); _DCT8_SSE(@A[3],@QTEncY,@vars); end;end;

// IDCT

procedure IDCT8_Y(WorkArea:PWorkArea);begin with WorkArea^ do begin
  _IDCT8(@Y[0],@QTDecY); end;end;

procedure IDCT8_YA(WorkArea:PWorkArea);begin with WorkArea^ do begin
  _IDCT8(@Y[0],@QTDecY); _IDCT8(@Y[1],@QTDecY); end;end;

procedure IDCT8_BGR(WorkArea:PWorkArea);begin with WorkArea^ do begin
  _IDCT8(@Y[0],@QTDecY); _IDCT8(@Y[1],@QTDecY); _IDCT8(@Y[2],@QTDecY); end;end;

procedure IDCT8_BGRA(WorkArea:PWorkArea);begin with WorkArea^ do begin
  _IDCT8(@Y[0],@QTDecY); _IDCT8(@Y[1],@QTDecY); _IDCT8(@Y[2],@QTDecY); _IDCT8(@Y[3],@QTDecY); end;end;

procedure IDCT8_YUV(WorkArea:PWorkArea);begin with WorkArea^ do begin
  IDCT8_BGRA(WorkArea); _IDCT8(@UV[0],@QTDecU); _IDCT8(@UV[1],@QTDecV); end;end;

procedure IDCT8_YUVA(WorkArea:PWorkArea);begin with WorkArea^ do begin
  IDCT8_YUV(WorkArea); _IDCT8(@A[0],@QTDecY); _IDCT8(@A[1],@QTDecY); _IDCT8(@A[2],@QTDecY); _IDCT8(@A[3],@QTDecY); end;end;

//  DCT_SSE

procedure IDCT8_Y_SSE(WorkArea:PWorkArea);begin with WorkArea^ do begin
  _IDCT8_SSE(@Y[0],@QTDecY,@vars); end;end;

procedure IDCT8_YA_SSE(WorkArea:PWorkArea);begin with WorkArea^ do begin
  _IDCT8_SSE(@Y[0],@QTDecY,@vars);
  _IDCT8_SSE(@Y[1],@QTDecY,@vars); end;end;

procedure IDCT8_BGR_SSE(WorkArea:PWorkArea);begin with WorkArea^ do begin
  _IDCT8_SSE(@Y[0],@QTDecY,@vars);
  _IDCT8_SSE(@Y[1],@QTDecY,@vars);
  _IDCT8_SSE(@Y[2],@QTDecY,@vars); end;end;

procedure IDCT8_BGRA_SSE(WorkArea:PWorkArea);begin with WorkArea^ do begin
  _IDCT8_SSE(@Y[0],@QTDecY,@vars);
  _IDCT8_SSE(@Y[1],@QTDecY,@vars);
  _IDCT8_SSE(@Y[2],@QTDecY,@vars);
  _IDCT8_SSE(@Y[3],@QTDecY,@vars); end;end;

procedure IDCT8_YUV_SSE(WorkArea:PWorkArea);begin with WorkArea^ do begin
  IDCT8_BGRA_SSE(WorkArea);
  _IDCT8_SSE(@UV[0],@QTDecU,@vars);
  _IDCT8_SSE(@UV[1],@QTDecV,@vars); end;end;

procedure IDCT8_YUVA_SSE(WorkArea:PWorkArea);begin with WorkArea^ do begin
  IDCT8_YUV_SSE(WorkArea);
  _IDCT8_SSE(@A[0],@QTDecY,@vars);
  _IDCT8_SSE(@A[1],@QTDecY,@vars);
  _IDCT8_SSE(@A[2],@QTDecY,@vars);
  _IDCT8_SSE(@A[3],@QTDecY,@vars); end;end;

////////////////////////////////////////////////////////////////////////////////
/// Proc Selector

type
  TDCTProc=procedure(WorkArea:PWorkArea);
  TIDCTProc=procedure(WorkArea:PWorkArea);

function SelectDCTProc(const components:integer;const YUVMode:boolean):TDCTProc;
begin
  result:=nil;
  if SSEVersion>=SSE2 then case components of
    1:result:=@DCT8_Y_SSE;
    2:result:=@DCT8_YA_SSE;
    3:if YUVMode then result:=@DCT8_YUV_SSE
                 else result:=@DCT8_BGR_SSE;
    4:if YUVMode then result:=@DCT8_YUVA_SSE
                 else result:=@DCT8_BGRA_SSE;
  end else case Components of
    1:result:=@DCT8_Y;
    2:result:=@DCT8_YA;
    3:if YUVMode then result:=@DCT8_YUV
                 else result:=@DCT8_BGR;
    4:if YUVMode then result:=@DCT8_YUVA
                 else result:=@DCT8_BGRA;
  end;
  Assert(assigned(result),'HetJpeg: SelectDCTProc() failed.');
end;

function SelectIDCTProc(const components:integer;const YUVMode:boolean):TIDCTProc;
begin
  result:=nil;
  if SSEVersion>=SSE2 then case components of
    1:result:=@IDCT8_Y_SSE;
    2:result:=@IDCT8_YA_SSE;
    3:if YUVMode then result:=@IDCT8_YUV_SSE
                 else result:=@IDCT8_BGR_SSE;
    4:if YUVMode then result:=@IDCT8_YUVA_SSE
                 else result:=@IDCT8_BGRA_SSE;
  end else case Components of
    1:result:=@IDCT8_Y;
    2:result:=@IDCT8_YA;
    3:if YUVMode then result:=@IDCT8_YUV
                 else result:=@IDCT8_BGR;
    4:if YUVMode then result:=@IDCT8_YUVA
                 else result:=@IDCT8_BGRA;
  end;
  Assert(assigned(result),'HetJpeg: SelectIDCTProc() failed.');
end;

////////////////////////////////////////////////////////////////////////////////
/// Step3               Huffman+zigzag+bitstream coding / decoding
///
/// Description         ...
///

(*type
  THuffmanLookup=array[0..65535]of record HLvalue,HLbitcount:byte;end;
  PHuffmanLookup=^THuffmanLookup;

  PHuffmanTable=^THuffmanTable;
  THuffmanTable=record
    codes:array[0..255]of record value,length:word end;
    lookup:THuffmanLookup;
  end;

const
  std_dc_luminance_nrcodes:array[0..16]of byte=(0,0,1,5,1,1,1,1,1,1,0,0,0,0,0,0,0);
  std_dc_luminance_values:array[0..11]of byte=(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11);

  std_dc_chrominance_nrcodes:array[0..16]of byte=(0,0,3,1,1,1,1,1,1,1,1,1,0,0,0,0,0);
  std_dc_chrominance_values:array[0..11]of byte=(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11);

  std_ac_luminance_nrcodes:array[0..16]of byte=(0,0,2,1,3,3,2,4,3,5,5,4,4,0,0,1,$7d );
  std_ac_luminance_values:array[0..161]of byte= (
	  $01, $02, $03, $00, $04, $11, $05, $12,
	  $21, $31, $41, $06, $13, $51, $61, $07,
	  $22, $71, $14, $32, $81, $91, $a1, $08,
	  $23, $42, $b1, $c1, $15, $52, $d1, $f0,
	  $24, $33, $62, $72, $82, $09, $0a, $16,
	  $17, $18, $19, $1a, $25, $26, $27, $28,
	  $29, $2a, $34, $35, $36, $37, $38, $39,
	  $3a, $43, $44, $45, $46, $47, $48, $49,
	  $4a, $53, $54, $55, $56, $57, $58, $59,
	  $5a, $63, $64, $65, $66, $67, $68, $69,
	  $6a, $73, $74, $75, $76, $77, $78, $79,
	  $7a, $83, $84, $85, $86, $87, $88, $89,
	  $8a, $92, $93, $94, $95, $96, $97, $98,
	  $99, $9a, $a2, $a3, $a4, $a5, $a6, $a7,
	  $a8, $a9, $aa, $b2, $b3, $b4, $b5, $b6,
	  $b7, $b8, $b9, $ba, $c2, $c3, $c4, $c5,
	  $c6, $c7, $c8, $c9, $ca, $d2, $d3, $d4,
	  $d5, $d6, $d7, $d8, $d9, $da, $e1, $e2,
	  $e3, $e4, $e5, $e6, $e7, $e8, $e9, $ea,
	  $f1, $f2, $f3, $f4, $f5, $f6, $f7, $f8,
	  $f9, $fa );

  std_ac_chrominance_nrcodes:array[0..16]of byte=(0,0,2,1,2,4,4,3,4,7,5,4,4,0,1,2,$77);
  std_ac_chrominance_values:array[0..161]of byte=(
	  $00, $01, $02, $03, $11, $04, $05, $21,
	  $31, $06, $12, $41, $51, $07, $61, $71,
	  $13, $22, $32, $81, $08, $14, $42, $91,
	  $a1, $b1, $c1, $09, $23, $33, $52, $f0,
	  $15, $62, $72, $d1, $0a, $16, $24, $34,
	  $e1, $25, $f1, $17, $18, $19, $1a, $26,
	  $27, $28, $29, $2a, $35, $36, $37, $38,
	  $39, $3a, $43, $44, $45, $46, $47, $48,
	  $49, $4a, $53, $54, $55, $56, $57, $58,
	  $59, $5a, $63, $64, $65, $66, $67, $68,
	  $69, $6a, $73, $74, $75, $76, $77, $78,
	  $79, $7a, $82, $83, $84, $85, $86, $87,
	  $88, $89, $8a, $92, $93, $94, $95, $96,
	  $97, $98, $99, $9a, $a2, $a3, $a4, $a5,
	  $a6, $a7, $a8, $a9, $aa, $b2, $b3, $b4,
	  $b5, $b6, $b7, $b8, $b9, $ba, $c2, $c3,
	  $c4, $c5, $c6, $c7, $c8, $c9, $ca, $d2,
	  $d3, $d4, $d5, $d6, $d7, $d8, $d9, $da,
	  $e2, $e3, $e4, $e5, $e6, $e7, $e8, $e9,
	  $ea, $f2, $f3, $f4, $f5, $f6, $f7, $f8,
	  $f9, $fa );

var
  HuffAcY,HuffAcUV,
  HuffDcY,HuffDcUV:THuffmanTable;

function swapbits(v:integer;bits:integer):integer;
asm
  xor ecx,ecx
@@1:
  shr eax,1
  rcl ecx,1
  dec edx
  jg @@1
  mov eax,ecx
end;

procedure _PrepareHuffmanTables;

  procedure compute_Huffman_table(nrcodes:PByteArray;std_table:pbytearray;var HT:THuffmanTable);

    procedure AddToLookup(code,len,value:integer);
    var i:integer;
    begin
      for i:=0 to 1 shl(16-len)-1 do begin
        HT.lookup[i shl len+code].HLbitcount:=len;
        HT.lookup[i shl len+code].HLvalue:=value;
      end;
    end;

  var j,
      pos_in_table,
      CodeCounter,Code,CodeLen:integer;
  begin
    CodeCounter:=0; pos_in_table:=0;
    for CodeLen:=1 to 16 do begin
      for j:=0 to nrcodes[CodeLen]-1do begin
        Code:=swapbits(codeCounter,CodeLen)xor((1 shl CodeLen)-1);
        HT.codes[std_table[pos_in_table]].value:=Code;
        HT.codes[std_table[pos_in_table]].length:=CodeLen;
        AddToLookup(Code,CodeLen,std_table[pos_in_table]);
        inc(pos_in_table);
        inc(codeCounter);
      end;
      codeCounter:=codeCounter shl 1;
    end;
  end;

begin
  compute_Huffman_table(@std_ac_luminance_nrcodes,  @std_ac_luminance_values,  HuffAcY);
  compute_Huffman_table(@std_dc_luminance_nrcodes,  @std_dc_luminance_values,  HuffDcY);
  compute_Huffman_table(@std_ac_chrominance_nrcodes,@std_ac_chrominance_values,HuffAcUV);
  compute_Huffman_table(@std_dc_chrominance_nrcodes,@std_dc_chrominance_values,HuffDcUV);
end;

var
  category:array[-2047..2047]of byte;
  bitcode:array[-2047..2047]of word;

procedure _PrepareEncoderCategoryBitcodeTables;
var cat,i,big,small:integer;
begin
  for cat:=0 to 11 do begin
    big:=(1 shl cat)-1;small:=1 shl(cat -1);if small<0 then small:=0;
    for i:=-big to -small do begin
      bitcode[i]:=i+big;
      category[i]:=cat;
    end;
    for i:=small to big do begin
      bitcode[i]:=i;
      category[i]:=cat;
    end;
  end;
end;

var
  BitcodeCategory:array[0..15]of record small,ss1:integer end;

procedure _PrepareDecoderCategoryBitcodeTables;
var i:integer;
begin
  BitcodeCategory[0].small:=0;
  BitcodeCategory[0].ss1:=0;
  for i:=1 to 15 do with BitcodeCategory[i]do begin
    small:=1 shl(i-1);
    ss1:=small+small-1;
  end;
end;

function CategoryBitcode(cat:integer;bitcode:integer):integer;inline;
var small,ss1:integer;
begin
  if cat>0 then begin
    small:=1 shl(cat-1);
    ss1:=small+small-1;
    result:=bitcode and ss1;
    if result<small then
      result:=result-ss1;
  end else result:=0;
end;

const
{  zigzag:TLinearBlockB=( 0, 1, 5, 6,17,18,27,28,
                         2, 3, 7,12,19,26,29,42,
                         4, 8,11,13,25,30,41,43,
                         9,10,14,15,31,40,44,53,
                        16,20,24,32,39,45,52,54,
                        21,23,33,38,46,51,55,60,
                        22,34,37,47,50,56,59,61,
                        35,36,48,49,57,58,62,63 );}

  ZigZag:TLinearBlockB=( 0, 1, 5, 6,14,15,27,28,  //original
                         2, 4, 7,13,16,26,29,42,
                         3, 8,12,17,25,30,41,43,
                         9,11,18,24,31,40,44,53,
                        10,19,23,32,39,45,52,54,
                        20,22,33,38,46,51,55,60,
                        21,34,37,47,50,56,59,61,
                        35,36,48,49,57,58,62,63 );

var invZigZag:TLinearBlockB;

procedure _prepareInvZigZag;var i:integer;
begin
  for i:=0 to high(zigzag)do invzigzag[zigzag[i]]:=i;
end;

procedure _HuffEnc(indata:PLinearBlockW;var HuffAc,HuffDc:THuffmanTable;var Buffer:TBytes;var BufferBitOfs:cardinal;var PrevDC:smallint);

  procedure writeBits(bits,newVal:cardinal);
  var val:pcardinal;mask,o7:cardinal;
  begin
    if bits=0 then exit;
    val:=pcardinal(@buffer[bufferbitofs shr 3]);
    o7:=bufferbitofs and 7;
    mask:=((1 shl bits)-1)shl(o7);
    val^:=val^ and not mask or((newVal shl(o7))and mask);
    bufferbitOfs:=bufferbitOfs+bits;
  end;

  procedure writePairHuffman(a,b:integer);
  var cat:integer;val:byte;
  begin
    cat:=category[b];
    val:=a shl 4 or cat;
    with HuffAc.codes[val]do writeBits(length,value);
ACAbsMax:=max(ACAbsMax,b);
    writebits(cat,bitcode[b]);
  end;

var end0Pos,startPos,i,nrzeroes,Diff:integer;

const MinCodeSize=64*4;
begin
  if cardinal(length(Buffer))-BufferBitOfs shr 3<MinCodeSize then begin
    SetLength(Buffer,length(Buffer)*2+MinCodeSize);
  end;

  end0pos:=64;while(end0pos>1)and(indata[invzigzag[end0pos-1]]=0)do dec(end0Pos);

  Diff:={EnsureRange(}indata[0]-PrevDc{,-2047,2047)};
  PrevDC:=indata[0];

DCAbsMax:=max(DCAbsMax,Abs(Diff));
  with HuffDc.codes[category[Diff]]do writeBits(length,value);
  writeBits(category[Diff],bitcode[Diff]);

  if (end0pos<=1)then begin
    writePairHuffman(0,0);
    exit;
  end;
  i:=1;
  while(i<end0pos)do begin
    startpos:=i;
    while (indata[invzigzag[i]]=0)and(i<=end0pos)do inc(i);
    nrzeroes:=i-startpos;
    while nrzeroes>=16 do begin
      writePairHuffman(15,0);
      nrzeroes:=nrzeroes-16;
    end;
    writePairHuffman(nrzeroes,indata[invzigzag[i]]);
    inc(i);
  end;
  if (end0pos<64)then begin
    writePairHuffman(0,0);
  end;
end;

function SkipBits(bits:cardinal;bufferbase:pointer;var bufferbitofs:cardinal):cardinal;
asm
  add eax,[ecx]
  mov [ecx],eax
  mov ecx,eax
  shr eax,3
  and ecx,7
  mov eax,[edx+eax]
  shr eax,cl
end;

function _HuffDec(outData:PLinearBlockW;var HuffAc,HuffDc:THuffmanTable;var _Buffer:TBytes;var _BufferBitOfs:cardinal;var PrevDC:smallint):integer;
var //Buffer:TBytes;
    //BufferBitOfs:Cardinal;
    BufferValue:cardinal;
    BufferBitOfs:cardinal;
    BufferBase:pointer;

  function GetDCCategoryHuffman:integer;
  begin
    with HuffDc.lookup[word(BufferValue)]do begin
      Result:=HLvalue;
      BUfferValue:=skipBits(HLbitcount,BufferBase,BufferBitOfs);
    end;
  end;

  var zerocnt,number:integer;
      HuffLookup:PHuffmanLookup;

  procedure GetPairHuffman;
  var cat,len:integer;
  begin
    with HuffLookup[word(BufferValue)] do begin
      len:=HLbitcount;
      cat:=HLvalue and $f;
      zerocnt:=HLvalue shr 4;
    end;

    with BitcodeCategory[cat]do begin
      number:=(BufferValue shr len)and ss1;
      if number<small then
        number:=number-ss1;
    end;

    BufferValue:=skipBits(len+cat,BufferBase,BufferBitOfs);
  end;

var nr,k,diff:integer;

const MinCodeSize=64*4;
begin
  HuffLookup:=@HuffAc.lookup;

  BufferBase:=@_Buffer[0];
  BufferBitOfs:=_BufferBitOfs;
  BufferValue:=SkipBits(0,BufferBase,BufferBitOfs);

  if SSEVersion>0 then
  asm
    pxor xmm7,xmm7;
    mov edx,outData;
    mov ecx,128
  @@1:
    sub ecx,16
    movaps [edx+ecx],xmm7;
    jg @@1
  end else
    FillChar(outData^,128,0);

  k:=GetDCCategoryHuffman;
  Diff:=CategoryBitcode(k,BufferValue and(1 shl k-1));BufferValue:=SkipBits(k,BufferBase,BufferBitOfs);

  outData^[0]:=PrevDC+Diff;
  PrevDC:=outData^[0];

  nr:=1;
  while((nr<64))do begin
    GetPairHuffman;
    if(zerocnt or number=0)then begin
      _BufferBitOfs:=BufferBitOfs;
      exit(nr)
    end else
      if zerocnt>0 then inc(nr,zerocnt);
    outData[invzigzag[nr]]:=number;inc(nr);
  end;

  _BufferBitOfs:=BufferBitOfs;
  result:=64;
end;*)

const
  std_dc_luminance_nrcodes:array[0..16]of byte=(0,0,1,5,1,1,1,1,1,1,0,0,0,0,0,0,0);
  std_dc_luminance_values:array[0..11]of byte=(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11);

  std_dc_chrominance_nrcodes:array[0..16]of byte=(0,0,3,1,1,1,1,1,1,1,1,1,0,0,0,0,0);
  std_dc_chrominance_values:array[0..11]of byte=(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11);

  std_ac_luminance_nrcodes:array[0..16]of byte=(0,0,2,1,3,3,2,4,3,5,5,4,4,0,0,1,$7d );
  std_ac_luminance_values:array[0..161]of byte= (
	  $01, $02, $03, $00, $04, $11, $05, $12,
	  $21, $31, $41, $06, $13, $51, $61, $07,
	  $22, $71, $14, $32, $81, $91, $a1, $08,
	  $23, $42, $b1, $c1, $15, $52, $d1, $f0,
	  $24, $33, $62, $72, $82, $09, $0a, $16,
	  $17, $18, $19, $1a, $25, $26, $27, $28,
	  $29, $2a, $34, $35, $36, $37, $38, $39,
	  $3a, $43, $44, $45, $46, $47, $48, $49,
	  $4a, $53, $54, $55, $56, $57, $58, $59,
	  $5a, $63, $64, $65, $66, $67, $68, $69,
	  $6a, $73, $74, $75, $76, $77, $78, $79,
	  $7a, $83, $84, $85, $86, $87, $88, $89,
	  $8a, $92, $93, $94, $95, $96, $97, $98,
	  $99, $9a, $a2, $a3, $a4, $a5, $a6, $a7,
	  $a8, $a9, $aa, $b2, $b3, $b4, $b5, $b6,
	  $b7, $b8, $b9, $ba, $c2, $c3, $c4, $c5,
	  $c6, $c7, $c8, $c9, $ca, $d2, $d3, $d4,
	  $d5, $d6, $d7, $d8, $d9, $da, $e1, $e2,
	  $e3, $e4, $e5, $e6, $e7, $e8, $e9, $ea,
	  $f1, $f2, $f3, $f4, $f5, $f6, $f7, $f8,
	  $f9, $fa );

  std_ac_chrominance_nrcodes:array[0..16]of byte=(0,0,2,1,2,4,4,3,4,7,5,4,4,0,1,2,$77);
  std_ac_chrominance_values:array[0..161]of byte=(
	  $00, $01, $02, $03, $11, $04, $05, $21,
	  $31, $06, $12, $41, $51, $07, $61, $71,
	  $13, $22, $32, $81, $08, $14, $42, $91,
	  $a1, $b1, $c1, $09, $23, $33, $52, $f0,
	  $15, $62, $72, $d1, $0a, $16, $24, $34,
	  $e1, $25, $f1, $17, $18, $19, $1a, $26,
	  $27, $28, $29, $2a, $35, $36, $37, $38,
	  $39, $3a, $43, $44, $45, $46, $47, $48,
	  $49, $4a, $53, $54, $55, $56, $57, $58,
	  $59, $5a, $63, $64, $65, $66, $67, $68,
	  $69, $6a, $73, $74, $75, $76, $77, $78,
	  $79, $7a, $82, $83, $84, $85, $86, $87,
	  $88, $89, $8a, $92, $93, $94, $95, $96,
	  $97, $98, $99, $9a, $a2, $a3, $a4, $a5,
	  $a6, $a7, $a8, $a9, $aa, $b2, $b3, $b4,
	  $b5, $b6, $b7, $b8, $b9, $ba, $c2, $c3,
	  $c4, $c5, $c6, $c7, $c8, $c9, $ca, $d2,
	  $d3, $d4, $d5, $d6, $d7, $d8, $d9, $da,
	  $e2, $e3, $e4, $e5, $e6, $e7, $e8, $e9,
	  $ea, $f2, $f3, $f4, $f5, $f6, $f7, $f8,
	  $f9, $fa );

  Std_ZigZag:TLinearBlockB=( 0, 1, 5, 6,14,15,27,28,  //original
                             2, 4, 7,13,16,26,29,42,
                             3, 8,12,17,25,30,41,43,
                             9,11,18,24,31,40,44,53,
                            10,19,23,32,39,45,52,54,
                            20,22,33,38,46,51,55,60,
                            21,34,37,47,50,56,59,61,
                            35,36,48,49,57,58,62,63 );


procedure PrepareHuffmanTables(var H:THuffTables);

  procedure prepareZigZags;
  var i:integer;
  begin with H.Global do begin
    for i:=0 to high(zigzag)do begin
      zigzag[i]:=std_zigzag[i];
      invzigzag[zigzag[i]]:=i;
    end;
  end;end;

  function swapbits(v:integer;bits:integer):integer;
  asm
    xor ecx,ecx
  @@1:
    shr eax,1
    rcl ecx,1
    dec edx
    jg @@1
    mov eax,ecx
  end;

  procedure computeCategoryBitcodeTables(var g:THuffGlobal);
  var cat,i,big,small:integer;
  begin
    for cat:=0 to 10{AC optimized, de dealt with an if} do begin
      big:=(1 shl cat)-1;small:=1 shl(cat -1);if small<0 then small:=0;
      for i:=-big to -small do begin
        g.category[i]:=cat;
        g.bitcode[i]:=(i--big)shl 1 or 1;
      end;
      for i:=small to big do begin
        g.category[i]:=cat;
        g.bitcode[i]:=(i-small)shl 1;
      end;
    end;
  end;

  procedure computeBaseMaskTable(var t:TBaseMaskTable);
  var i,cat:integer;
  begin
    for i:=0 to high(t)do with t[i]do begin
      cat:=i shr 1;
      if cat=0 then begin
        mask:=0;
        base:=0;
      end else begin
        mask:=1 shl (cat-1)-1;
        if(i and 1)=0 then base:=1 shl (cat-1)
                      else base:=-(1 shl cat-1);
      end;
    end;
  end;

  procedure computeHuffTables(DC_nrcodes:PByteArray;DC_std_table:pbytearray;AC_nrcodes:PByteArray;AC_std_table:pbytearray;var HEnc:THuffEncTable;var HDec:THuffDecTable);

    function FillHuffLookupRecords(code,len,value,zeroBits:integer;subTable:PHuffLookupRecordArray;subTableLength:integer):boolean;
    var i,cat:integer;
    begin
      result:=code and (1 shl zeroBits-1)=0;
      if result then begin
        cat:=value and $F;
        len:=len-zeroBits;
        code:=code shr zeroBits;
        for i:=0 to subTableLength shr len-1 do with subTable^[i shl len+code]do begin
          basemaskID:=i and 1+cat shl 1;
          shift:=len+zeroBits+1;
          zcnt:=value shr 4;
          skip:=len+zeroBits+cat;
        end;
      end;
    end;

    procedure computeCodes(nrcodes:PByteArray;std_table:pbytearray;Codes:PHuffCodeRecordArray);
    var j,pos_in_table,CodeCounter,ActCode,CodeLen,value:integer;
    begin
      CodeCounter:=0; pos_in_table:=0;
      for CodeLen:=1 to 16 do begin
        for j:=0 to nrcodes[CodeLen]-1do begin
          ActCode:=swapbits(codeCounter,CodeLen)xor(1 shl CodeLen-1);
          value:=std_table[pos_in_table];
          with Codes[value]do begin
            Code:=ActCode;
            Len:=CodeLen;
            FullLen:=value and $F+CodeLen;
          end;
          inc(pos_in_table);
          inc(codeCounter);
        end;
        codeCounter:=codeCounter shl 1;
      end;
    end;

    procedure computeDCLookup(const Codes:THuffDCCodes;const Lookup:THuffDCLookup);
    var i:integer;
    begin
      for i:=0 to high(codes)do with Codes[i]do if Len>0 then begin
        if not FillHuffLookupRecords(code,len,i,6,@Lookup.medium,length(Lookup.medium))then
               FillHuffLookupRecords(code,len,i,0,@Lookup.small ,length(Lookup.small ));
      end;
    end;

    procedure computeACLookup(const Codes:THuffACCodes;const Lookup:THuffACLookup);
    var i:integer;
    begin
      for i:=0 to high(codes)do with Codes[i]do if Len>0 then begin
        if not FillHuffLookupRecords(code,len,i,9,@Lookup.big   ,length(Lookup.big   ))then
        if not FillHuffLookupRecords(code,len,i,4,@Lookup.medium,length(Lookup.medium))then
               FillHuffLookupRecords(code,len,i,0,@Lookup.small ,length(Lookup.small ));
      end;
    end;

  begin
    FillChar(HEnc,sizeof(HEnc),0);
    FillChar(HDec,sizeof(HDec),1);
    prepareZigZags;

    computeCodes(DC_nrcodes,DC_std_table,@HEnc.DCCodes);
    computeDCLookup(HEnc.DCCodes,HDec.DCLookup);
    computeCodes(AC_nrcodes,AC_std_table,@HEnc.ACCodes);
    computeACLookup(HEnc.ACCodes,HDec.ACLookup);
  end;

begin
  computeCategoryBitcodeTables(h.Global);
  computeBaseMaskTable(h.Global.BaseMaskTable);

  computeHuffTables(@std_dc_luminance_nrcodes  ,@std_dc_luminance_values  ,
                    @std_ac_luminance_nrcodes  ,@std_ac_luminance_values  ,H.YEnc ,H.YDec );

  computeHuffTables(@std_dc_chrominance_nrcodes,@std_dc_chrominance_values,
                    @std_ac_chrominance_nrcodes,@std_ac_chrominance_values,H.UVEnc,H.UVDec);
end;

procedure _HuffEnc(
  indata:PLinearBlockW;
  const Global:THuffGlobal; const DCCodes:THuffDCCodes; const ACCodes:THuffACCodes;
  var Buffer:RawByteString;var BufferBitOfs:cardinal;var PrevDC:smallint);

  procedure writeBits(value,len:cardinal);
  var p:pcardinal;o7:cardinal;
  begin
    p:=psucc(pointer(Buffer),bufferbitofs shr 3);
    o7:=bufferbitofs and 7;
    p^:=(value shl o7) or (p^ and (1 shl o7-1));
    bufferbitOfs:=bufferbitOfs+len;
  end;

  procedure HuffEncDC(const global:THuffGlobal;const DCCodes:THuffDCCodes;value:integer);
  var cat,base,sign:integer;
  begin
    Value:=EnsureRange(Value,-2047,2047);
    if(Value>1023)or(Value<-1023)then begin//Bitcode/Category tables optimized for ac values -> half size
      cat:=11;
      sign:=value shr 31;
      base:=global.BaseMaskTable[sign+cat shl 1].base;
      with DCCodes[cat] do
        writeBits(code or sign shl len or(value-base)shl(len+1),FullLen);
    end else begin
      cat:=global.Category[value];
      with DCCodes[cat] do
        writeBits(code or global.Bitcode[value]shl len,FullLen);
    end;
  end;

  procedure HuffEncAC(const global:THuffGlobal;const ACCodes:THuffACCodes;zcnt,value:integer);
  var cat:integer;
  begin
    Value:=EnsureRange(Value,-1023,1023);
    cat:=global.Category[value];
    with ACCodes[cat or zcnt shl 4] do if FullLen>24 then begin
      writeBits(code,Len);
      writeBits(global.BitCode[value],cat);
    end else begin
      writeBits(code+global.BitCode[value]shl Len,fullLen)
    end;
  end;

var end0Pos,startPos,i,nrzeroes,Diff:integer;

begin

  Diff:=indata[0]-PrevDc;
  PrevDC:=indata[0];
  HuffEncDC(Global,DCCodes,Diff);

  end0pos:=64;while(end0pos>1)and(indata[Global.invzigzag[end0pos-1]]=0)do dec(end0Pos);

  if (end0pos<=1)then begin
    HuffEncAC(Global,ACCodes,0,0);
    exit;
  end;
  i:=1;
  while(i<end0pos)do begin
    startpos:=i;
    while (indata[global.invzigzag[i]]=0)and(i<=end0pos)do inc(i);
    nrzeroes:=i-startpos;
    while nrzeroes>=16 do begin
      HuffEncAC(Global,ACCodes,15,0);
      nrzeroes:=nrzeroes-16;
    end;
    HuffEncAC(Global,ACCodes,nrzeroes,indata[global.invzigzag[i]]);
    inc(i);
  end;
  if (end0pos<64)then
    HuffEncAC(Global,ACCodes,0,0);
end;

(*function _HuffDec(
  outData:PLinearBlockW;
  const global:THuffGlobal;
  const DCLookup:THuffDCLookup; const ACLookup:THuffACLookup;
  const Buffer:TBytes;var _BufferBitOfs:cardinal;
  var PrevDC:smallint):integer;

var BufferValue:cardinal;
    BufferBitOfs:cardinal;

  procedure SkipBits(len:cardinal);
  begin
    BufferBitOfs:=BufferBitOfs+len;
    BufferValue:=pcardinal(cardinal(@Buffer[0])+BufferBitOfs shr 3)^ shr(BufferBitOfs and 7);
  end;

  var Value{eax},ZeroCnt{ebx}:integer;//resultok

  procedure HuffDecDC(const BaseMaskTable:TBaseMaskTable;const DCLookup:THuffDCLookup);
  begin with DCLookup do begin
    if BufferValue and $3f=0 then with medium[BufferValue shr 6 and high(medium)]do begin
      with BaseMaskTable[basemaskID]do value:=base+integer(BufferValue shr shift)and mask;
      SkipBits(skip);
    end else with small[BufferValue and high(small)]do begin
      with BaseMaskTable[basemaskID]do value:=base+integer(BufferValue shr shift)and mask;
      SkipBits(skip);
    end;
  end;end;

  procedure HuffDecAC(const BaseMaskTable:TBaseMaskTable;const ACLookup:THuffACLookup);
  begin with ACLookup do begin
    if BufferValue and $1FF=0 then begin
      with big[BufferValue shr 9 and high(big)]do begin
        zerocnt:=zcnt;
        SkipBits(9);
        with BaseMaskTable[basemaskID]do value:=base+integer(BufferValue shr (shift-9))and mask;
        SkipBits(skip-9);
      end;
    end else if BufferValue and $F=0 then begin
      with medium[BufferValue shr 4 and high(medium)]do begin
        with BaseMaskTable[basemaskID]do value:=base+integer(BufferValue shr shift)and mask;
        zerocnt:=zcnt;
        SkipBits(skip);
      end;
    end else begin
      with small[BufferValue and high(small)]do begin
        with BaseMaskTable[basemaskID]do value:=base+integer(BufferValue shr shift)and mask;
        zerocnt:=zcnt;
        SkipBits(skip);
      end;
    end;
  end;end;

var nr:integer;

const MinCodeSize=64*4;
begin
  BufferBitOfs:=_BufferBitOfs;
  SkipBits(0);

  if SSEVersion>0 then
  asm
    pxor xmm7,xmm7;
    mov edx,outData;
    mov ecx,128
  @@1:
    sub ecx,16
    movaps [edx+ecx],xmm7;
    jg @@1
  end else
    FillChar(outData^,128,0);

  HuffDecDC(global.BaseMaskTable{ebp},DCLookup{edx});
  outData^{edi}[0]:=PrevDC+Value;//diff
  PrevDC:=outData^[0];

  nr{ecx}:=1;
  while((nr{ecx}<64))do begin
    HuffDecAC(global.BaseMaskTable{ebp},ACLookup{edx});
    if(zerocnt{ebx} or value{eax}=0)then begin
      _BufferBitOfs:=BufferBitOfs;
      exit(nr)
    end else
      inc(nr{ecx},zerocnt{ebx});
    outData{edi}[global.invzigzag{ebp}[nr{ecx}]]:=value{eax};inc(nr{ecx});
  end;

  _BufferBitOfs:=BufferBitOfs;
  result:=64;
end;*)


function _HuffDec(
  outData:PLinearBlockW;
  const global:THuffGlobal;
  const DCLookup:THuffDCLookup; const ACLookup:THuffACLookup;
  const Buffer:RawByteString;var _BufferBitOfs:cardinal;
  var PrevDC:smallint):integer;

var BufferValue:cardinal;
    BufferBitOfs:cardinal;
    zerocnt,value,nr:integer;
    pBuffer:cardinal;
//    tmp:TBytes;
const MinCodeSize=64*4;
begin
  BufferBitOfs:=_BufferBitOfs;
  pBuffer:=cardinal(pointer(Buffer));

{  if SSEVersion>0 then}
  asm
    pxor xmm7,xmm7;
    mov edx,outData;
    mov ecx,128
  @@1:
    sub ecx,16
    movdqa [edx+ecx],xmm7;
    jg @@1
  end {else
    FillChar(outData^,128,0)};

  BufferValue:=pcardinal(pBuffer+BufferBitOfs shr 3)^ shr(BufferBitOfs and 7);
  with DCLookup do begin
    if BufferValue and $3f=0 then with medium[BufferValue shr 6 and high(medium)]do begin
      with global.BaseMaskTable[basemaskID]do value:=base+integer(BufferValue shr shift)and mask;
      BufferBitOfs:=BufferBitOfs+skip;
    end else with small[BufferValue and high(small)]do begin
      with global.BaseMaskTable[basemaskID]do value:=base+integer(BufferValue shr shift)and mask;
      BufferBitOfs:=BufferBitOfs+skip;
    end;
  end;
  BufferValue:=pcardinal(pBuffer+BufferBitOfs shr 3)^ shr(BufferBitOfs and 7);

  outData^[0]:=PrevDC+Value;
  PrevDC:=outData^[0];

  nr:=1;
  while((nr<64))do begin
    with ACLookup do
    if BufferValue and $1FF=0 then begin
      with big[BufferValue shr 9 and high(big)]do begin
        zerocnt:=zcnt;
        BufferBitOfs:=BufferBitOfs+9;BufferValue:=pcardinal(pBuffer+BufferBitOfs shr 3)^ shr(BufferBitOfs and 7);
        with global.BaseMaskTable[basemaskID]do value:=base+integer(BufferValue shr (shift-9))and mask;
        BufferBitOfs:=BufferBitOfs+cardinal(skip-9);BufferValue:=pcardinal(pBuffer+BufferBitOfs shr 3)^ shr(BufferBitOfs and 7);
      end;
    end else if BufferValue and $F=0 then begin
      with ACLookup.medium[BufferValue shr 4 and high(medium)]do begin
        with global.BaseMaskTable[basemaskID]do value:=base+integer(BufferValue shr shift)and mask;
        zerocnt:=zcnt;
        BufferBitOfs:=BufferBitOfs+skip;BufferValue:=pcardinal(pBuffer+BufferBitOfs shr 3)^ shr(BufferBitOfs and 7);
      end;
    end else begin
      with ACLookup.small[BufferValue and high(small)]do begin
        with global.BaseMaskTable[basemaskID]do value:=base+integer(BufferValue shr shift)and mask;
        zerocnt:=zcnt;
        BufferBitOfs:=BufferBitOfs+skip;BufferValue:=pcardinal(pBuffer+BufferBitOfs shr 3)^ shr(BufferBitOfs and 7);
      end;
    end;
    if(zerocnt or value=0)then begin
      _BufferBitOfs:=BufferBitOfs;
      exit(nr)
    end else
      inc(nr,zerocnt);
    outData[global.invzigzag[nr]]:=value;inc(nr);
  end;

  _BufferBitOfs:=BufferBitOfs;
  result:=64;
end;

////////////////////////////////////////////////////////////////////////////////
/// Selectable Procs

// Huffman encode

procedure HuffEnc_Y(WorkArea:PWorkArea;var Buffer:RawByteString;var BufferBitOfs:cardinal);begin with WorkArea^,HuffTables do begin
  _HuffEnc(@Y[0],Global,YEnc.DCCodes,YEnc.ACCodes,Buffer,BufferBitOfs,HuffDiff[0]);end;end;

procedure HuffEnc_YA(WorkArea:PWorkArea;var Buffer:RawByteString;var BufferBitOfs:cardinal);begin with WorkArea^,HuffTables do begin
  _HuffEnc(@Y[0],Global,YEnc.DCCodes,YEnc.ACCodes,Buffer,BufferBitOfs,HuffDiff[0]);
  _HuffEnc(@Y[1],Global,YEnc.DCCodes,YEnc.ACCodes,Buffer,BufferBitOfs,HuffDiff[1]);end;end;

procedure HuffEnc_BGR(WorkArea:PWorkArea;var Buffer:RawByteString;var BufferBitOfs:cardinal);begin with WorkArea^,HuffTables do begin
  _HuffEnc(@Y[0],Global,YEnc.DCCodes,YEnc.ACCodes,Buffer,BufferBitOfs,HuffDiff[0]);
  _HuffEnc(@Y[1],Global,YEnc.DCCodes,YEnc.ACCodes,Buffer,BufferBitOfs,HuffDiff[1]);
  _HuffEnc(@Y[2],Global,YEnc.DCCodes,YEnc.ACCodes,Buffer,BufferBitOfs,HuffDiff[2]);end;end;

procedure HuffEnc_BGRA(WorkArea:PWorkArea;var Buffer:RawByteString;var BufferBitOfs:cardinal);begin with WorkArea^,HuffTables do begin
  _HuffEnc(@Y[0],Global,YEnc.DCCodes,YEnc.ACCodes,Buffer,BufferBitOfs,HuffDiff[0]);
  _HuffEnc(@Y[1],Global,YEnc.DCCodes,YEnc.ACCodes,Buffer,BufferBitOfs,HuffDiff[1]);
  _HuffEnc(@Y[2],Global,YEnc.DCCodes,YEnc.ACCodes,Buffer,BufferBitOfs,HuffDiff[2]);
  _HuffEnc(@Y[3],Global,YEnc.DCCodes,YEnc.ACCodes,Buffer,BufferBitOfs,HuffDiff[3]);end;end;

procedure HuffEnc_YUV(WorkArea:PWorkArea;var Buffer:RawByteString;var BufferBitOfs:cardinal);begin with WorkArea^,HuffTables  do begin
  _HuffEnc(@Y[0],Global,YEnc.DCCodes,YEnc.ACCodes,Buffer,BufferBitOfs,HuffDiff[0]);
  _HuffEnc(@Y[2],Global,YEnc.DCCodes,YEnc.ACCodes,Buffer,BufferBitOfs,HuffDiff[0]);
  _HuffEnc(@Y[1],Global,YEnc.DCCodes,YEnc.ACCodes,Buffer,BufferBitOfs,HuffDiff[1]);
  _HuffEnc(@Y[3],Global,YEnc.DCCodes,YEnc.ACCodes,Buffer,BufferBitOfs,HuffDiff[1]);
  _HuffEnc(@UV[0],Global,UVEnc.DCCodes,UVEnc.ACCodes,Buffer,BufferBitOfs,HuffDiff[2]);
  _HuffEnc(@UV[1],Global,UVEnc.DCCodes,UVEnc.ACCodes,Buffer,BufferBitOfs,HuffDiff[3]);
end;end;

procedure HuffEnc_YUVA(WorkArea:PWorkArea;var Buffer:RawByteString;var BufferBitOfs:cardinal);begin with WorkArea^,HuffTables do begin
  _HuffEnc(@Y[0],Global,YEnc.DCCodes,YEnc.ACCodes,Buffer,BufferBitOfs,HuffDiff[0]);
  _HuffEnc(@Y[2],Global,YEnc.DCCodes,YEnc.ACCodes,Buffer,BufferBitOfs,HuffDiff[0]);
  _HuffEnc(@Y[1],Global,YEnc.DCCodes,YEnc.ACCodes,Buffer,BufferBitOfs,HuffDiff[1]);
  _HuffEnc(@Y[3],Global,YEnc.DCCodes,YEnc.ACCodes,Buffer,BufferBitOfs,HuffDiff[1]);
  _HuffEnc(@A[0],Global,YEnc.DCCodes,YEnc.ACCodes,Buffer,BufferBitOfs,HuffDiff[4]);
  _HuffEnc(@A[2],Global,YEnc.DCCodes,YEnc.ACCodes,Buffer,BufferBitOfs,HuffDiff[4]);
  _HuffEnc(@A[1],Global,YEnc.DCCodes,YEnc.ACCodes,Buffer,BufferBitOfs,HuffDiff[5]);
  _HuffEnc(@A[3],Global,YEnc.DCCodes,YEnc.ACCodes,Buffer,BufferBitOfs,HuffDiff[5]);
  _HuffEnc(@UV[0],Global,UVEnc.DCCodes,UVEnc.ACCodes,Buffer,BufferBitOfs,HuffDiff[2]);
  _HuffEnc(@UV[1],Global,UVEnc.DCCodes,UVEnc.ACCodes,Buffer,BufferBitOfs,HuffDiff[3]);
end;end;

// Huffman decode

procedure HuffDec_Y(WorkArea:PWorkArea;const Buffer:RawByteString;var BufferBitOfs:cardinal);begin with WorkArea^,HuffTables do begin
  _HuffDec(@Y[0],Global,YDec.DCLookup,YDec.ACLookup,Buffer,BufferBitOfs,HuffDiff[0]);end;end;

procedure HuffDec_YA(WorkArea:PWorkArea;const Buffer:RawByteString;var BufferBitOfs:cardinal);begin with WorkArea^,HuffTables do begin
  _HuffDec(@Y[0],Global,YDec.DCLookup,YDec.ACLookup,Buffer,BufferBitOfs,HuffDiff[0]);
  _HuffDec(@Y[1],Global,YDec.DCLookup,YDec.ACLookup,Buffer,BufferBitOfs,HuffDiff[1]);end;end;

procedure HuffDec_BGR(WorkArea:PWorkArea;const Buffer:RawByteString;var BufferBitOfs:cardinal);begin with WorkArea^,HuffTables do begin
  _HuffDec(@Y[0],Global,YDec.DCLookup,YDec.ACLookup,Buffer,BufferBitOfs,HuffDiff[0]);
  _HuffDec(@Y[1],Global,YDec.DCLookup,YDec.ACLookup,Buffer,BufferBitOfs,HuffDiff[1]);
  _HuffDec(@Y[2],Global,YDec.DCLookup,YDec.ACLookup,Buffer,BufferBitOfs,HuffDiff[2]);end;end;

procedure HuffDec_BGRA(WorkArea:PWorkArea;const Buffer:RawByteString;var BufferBitOfs:cardinal);begin with WorkArea^,HuffTables do begin
  _HuffDec(@Y[0],Global,YDec.DCLookup,YDec.ACLookup,Buffer,BufferBitOfs,HuffDiff[0]);
  _HuffDec(@Y[1],Global,YDec.DCLookup,YDec.ACLookup,Buffer,BufferBitOfs,HuffDiff[1]);
  _HuffDec(@Y[2],Global,YDec.DCLookup,YDec.ACLookup,Buffer,BufferBitOfs,HuffDiff[2]);
  _HuffDec(@Y[3],Global,YDec.DCLookup,YDec.ACLookup,Buffer,BufferBitOfs,HuffDiff[3]);end;end;

procedure HuffDec_YUV(WorkArea:PWorkArea;const Buffer:RawByteString;var BufferBitOfs:cardinal);begin with WorkArea^,HuffTables do begin
  _HuffDec(@Y[0],Global,YDec.DCLookup,YDec.ACLookup,Buffer,BufferBitOfs,HuffDiff[0]);
  _HuffDec(@Y[2],Global,YDec.DCLookup,YDec.ACLookup,Buffer,BufferBitOfs,HuffDiff[0]);
  _HuffDec(@Y[1],Global,YDec.DCLookup,YDec.ACLookup,Buffer,BufferBitOfs,HuffDiff[1]);
  _HuffDec(@Y[3],Global,YDec.DCLookup,YDec.ACLookup,Buffer,BufferBitOfs,HuffDiff[1]);
  _HuffDec(@UV[0],Global,UVDec.DCLookup,UVDec.ACLookup,Buffer,BufferBitOfs,HuffDiff[2]);
  _HuffDec(@UV[1],Global,UVDec.DCLookup,UVDec.ACLookup,Buffer,BufferBitOfs,HuffDiff[3]);end;end;

procedure HuffDec_YUVA(WorkArea:PWorkArea;const Buffer:RawByteString;var BufferBitOfs:cardinal);begin with WorkArea^,HuffTables do begin
  _HuffDec(@Y[0],Global,YDec.DCLookup,YDec.ACLookup,Buffer,BufferBitOfs,HuffDiff[0]);
  _HuffDec(@Y[2],Global,YDec.DCLookup,YDec.ACLookup,Buffer,BufferBitOfs,HuffDiff[0]);
  _HuffDec(@Y[1],Global,YDec.DCLookup,YDec.ACLookup,Buffer,BufferBitOfs,HuffDiff[1]);
  _HuffDec(@Y[3],Global,YDec.DCLookup,YDec.ACLookup,Buffer,BufferBitOfs,HuffDiff[1]);
  _HuffDec(@A[0],Global,YDec.DCLookup,YDec.ACLookup,Buffer,BufferBitOfs,HuffDiff[4]);
  _HuffDec(@A[2],Global,YDec.DCLookup,YDec.ACLookup,Buffer,BufferBitOfs,HuffDiff[4]);
  _HuffDec(@A[1],Global,YDec.DCLookup,YDec.ACLookup,Buffer,BufferBitOfs,HuffDiff[5]);
  _HuffDec(@A[3],Global,YDec.DCLookup,YDec.ACLookup,Buffer,BufferBitOfs,HuffDiff[5]);
  _HuffDec(@UV[0],Global,UVDec.DCLookup,UVDec.ACLookup,Buffer,BufferBitOfs,HuffDiff[2]);
  _HuffDec(@UV[1],Global,UVDec.DCLookup,UVDec.ACLookup,Buffer,BufferBitOfs,HuffDiff[3]);end;end;

////////////////////////////////////////////////////////////////////////////////
/// Proc Selector

type
  THuffEncProc=procedure(WorkArea:PWorkArea;var Buffer:RawByteString;var BufferBitOfs:cardinal);
  THuffDecProc=procedure(WorkArea:PWorkArea;const Buffer:RawByteString;var BufferBitOfs:cardinal);
//  THuffDecProc=procedure(WorkArea:PWorkArea);

function SelectHuffEncProc(const components:integer;const YUVMode:boolean):THuffEncProc;
begin
  result:=nil;
  case Components of
    1:result:=@HuffEnc_Y;
    2:result:=@HuffEnc_YA;
    3:if YUVMode then result:=@HuffEnc_YUV
                 else result:=@HuffEnc_BGR;
    4:if YUVMode then result:=@HuffEnc_YUVA
                 else result:=@HuffEnc_BGRA;
  end;
  Assert(assigned(result),'HetJpeg: SelectHuffEnc() failed.');
end;

function SelectHuffDecProc(const components:integer;const YUVMode:boolean):THuffDecProc;
begin
  result:=nil;
  case Components of
    1:result:=@HuffDec_Y;
    2:result:=@HuffDec_YA;
    3:if YUVMode then result:=@HuffDec_YUV
                 else result:=@HuffDec_BGR;
    4:if YUVMode then result:=@HuffDec_YUVA
                 else result:=@HuffDec_BGRA;
  end;
  Assert(assigned(result),'HetJpeg: SelectHuffDecProc() failed.');
end;

////////////////////////////////////////////////////////////////////////////////
///  THJPFrameHeader

function THJPFrameHeader.GetComponents: byte;begin result:=Components_Delta and $7f end;
function THJPFrameHeader.GetDelta: boolean;begin result:=(Components_delta and $80)<>0 end;
function THJPFrameHeader.GetQuality: byte;begin result:=Quality_YUV and $7f end;
function THJPFrameHeader.GetYUV: boolean;begin result:=(Quality_YUV and $80)<>0 end;
procedure THJPFrameHeader.SetComponents(const Value: byte);begin Components_delta:=Components_delta and not $7f or Value and $7f end;
procedure THJPFrameHeader.SetDelta(const Value: boolean);begin Components_delta:=Components_delta and not $80 or switch(Value,$80,0) end;
procedure THJPFrameHeader.SetQuality(const Value: byte);begin Quality_YUV:=Quality_YUV and not $7f or EnsureRange(Value,0,100) and $7f end;
procedure THJPFrameHeader.SetYUV(const Value: boolean);begin Quality_YUV:=Quality_YUV and not $80 or switch(Value,$80,0) end;

procedure THJPFrameHeader.Setup(const AWidth, AHeight, AComponents: integer;
  const AQuality: byte; const AYUVMode: boolean;const ADelta:boolean);
begin
  Magic:=HJPMagic;
  Width:=AWidth;
  Height:=AHeight;
  Components:=AComponents;
  Quality:=AQuality;
  YUV:=AYUVMode;
  Delta:=ADelta;
  datalen:=0;
  crc:=0;
end;

procedure THJPFrameHeader.Setup(const ABmp: TBitmap; const AQuality: byte;const AYUVMode: boolean;const ADelta:boolean);
begin
  Setup(ABmp.Width,ABmp.Height,ABmp.Components,AQuality,AYUVMode,ADelta);
end;

procedure THJPFrameHeader.CalcCRC;
begin
  Crc:=Crc32(@self,sizeof(self)-4);
end;

function THJPFrameHeader.CheckCRC:boolean;
begin
  result:=Crc=Crc32(@self,sizeof(self)-4);
end;

function THJPFrameHeader.Valid:boolean;
begin
  result:=(Magic=HJPMagic)and CheckCrc;
end;

function THJPFrameHeader.FrameLen:integer;
begin
  result:=SizeOf(self)+datalen;
end;

////////////////////////////////////////////////////////////////////////////////
///  tesing

function hjpTest(const bmp:TBitmap;const Quality:integer;const YUVmode:boolean):RawByteString;
var WAAllocator:TAlignedBuffer;
    WA:PWorkArea;
    MBSize,MBInc,MBLineInc,LineSize:integer;
    x,y,xc,yc:integer;
    pMBLine,pMB:pointer;

    LoadPixels:TLoadPixelsProc;
    StorePixels:TStorePixelsProc;
    DCT:TDCTProc;
    IDCT:TIDCTProc;
    HuffEnc:THuffEncProc;
    HuffDec:THuffDecProc;

    Buffer:RawByteString;
    BufferBitOfs:Cardinal;
    Components:integer;
begin
  {$IFDEF hjpProfiling}HjpProfile.Reset;{$ENDIF}

  WA:=WAAllocator.Alloc(sizeof(WA^),4096);

  if length(Buffer)<1024*1024 then
    setlength(Buffer,1024*1024);

  Components:=bmp.Components;

  LoadPixels:=SelectLoadPixelsProc(components,YUVmode);
  StorePixels:=SelectStorePixelsProc(components,YUVmode);

  DCT:=SelectDCTProc(components,YUVmode);
  IDCT:=SelectIDCTProc(components,YUVmode);

  HuffEnc:=SelectHuffEncProc(components,YUVmode);
  HuffDec:=SelectHuffDecProc(components,YUVmode);

  SetupConstants(WA^);
  SetupEncoderQuantTables(WA^,Quality);
  SetupDecoderQuantTables(WA^,Quality);
  PrepareHuffmanTables(WA^.HuffTables);

  if YUVmode then MBSize:=16 else MBSize:=8;
  LineSize:=components*bmp.width;
  MBInc:=components*MBSize;
  MBLineInc:=components*MBSize;

  xc:=bmp.Width div MBSize;
  yc:=bmp.Height div MBSize;
  pMBLine:=bmp.ScanLine[bmp.Height-1];
  for y:=0 to yc-1 do begin
    pMB:=pMBLine;
    for x:=0 to xc-1 do begin
      {$IFDEF hjpProfiling}HjpProfile.LoadPixels.Start;{$ENDIF}
      LoadPixels(WA,pMB,LineSize);
      {$IFDEF hjpProfiling}HjpProfile.LoadPixels.Stop;{$ENDIF}

      {$IFDEF hjpProfiling}HjpProfile.DCT.Start;{$ENDIF}
      DCT(WA);
      {$IFDEF hjpProfiling}HjpProfile.DCT.Stop;{$ENDIF}

      fillchar(WA^.HuffDiff,16,0);
      BufferBitOfs:=0;
      {$IFDEF hjpProfiling}HjpProfile.HuffEnc.Start;{$ENDIF}
      HuffEnc(WA,Buffer,BufferBitOfs);
      {$IFDEF hjpProfiling}HjpProfile.HuffEnc.Stop;{$ENDIF}

    //  FillChar(WA.Y,10*128,0);

      fillchar(WA^.HuffDiff,16,0);
      BufferBitOfs:=0;
      {$IFDEF hjpProfiling}HjpProfile.HuffDec.Start;{$ENDIF}
      HuffDec(WA,Buffer,BufferBitOfs);
      {$IFDEF hjpProfiling}HjpProfile.HuffDec.Stop;{$ENDIF}

      {$IFDEF hjpProfiling}HjpProfile.IDCT.Start;{$ENDIF}
      IDCT(WA);
      {$IFDEF hjpProfiling}HjpProfile.IDCT.Stop;{$ENDIF}

      {$IFDEF hjpProfiling}HjpProfile.StorePixels.Start;{$ENDIF}
      StorePixels(WA,pMB,LineSize);
      {$IFDEF hjpProfiling}HjpProfile.StorePixels.Stop;{$ENDIF}
      pInc(pMB,MBInc);
    end;
    pInc(pMBLine,MBLineInc);
  end;
end;

function hjpEncodeInternal(const bmp:TBitmap;const Quality:integer;const YUVmode:boolean;var Buffer:RawByteString;var BufferPos:integer):boolean;
var WAAllocator:TAlignedBuffer;
    WA:PWorkArea;
    MBSize,MBInc,MBLineInc,LineSize:integer;
    x,y,xc,yc:integer;
    pMBLine,pMB:pointer;

    LoadPixels:TLoadPixelsProc;
    DCT:TDCTProc;
    HuffEnc:THuffEncProc;

    BufferBitOfs:Cardinal;
    components:integer;
begin
  {$IFDEF hjpProfiling}HjpProfile.Reset;{$ENDIF}

  WA:=WAAllocator.Alloc(sizeof(WA^),4096);

  components:=bmp.Components;
  LoadPixels:=SelectLoadPixelsProc(components,YUVmode);
  DCT:=SelectDCTProc(components,YUVmode);
  HuffEnc:=SelectHuffEncProc(components,YUVmode);

  SetupConstants(WA^);
  SetupEncoderQuantTables(WA^,Quality);
  SetupDecoderQuantTables(WA^,Quality);
  PrepareHuffmanTables(WA^.HuffTables);

  if YUVmode then MBSize:=16
             else MBSize:=8;
  LineSize:=components*bmp.Width;
  MBInc:=components*MBSize;
  MBLineInc:=LineSize*MBSize;

  xc:=bmp.Width div MBSize;
  yc:=bmp.Height div MBSize;
  pMBLine:=bmp.ScanLine[bmp.Height-1];

  fillchar(WA^.HuffDiff,16,0);
  BufferBitOfs:=BufferPos shl 3;

  for y:=0 to yc-1 do begin
    pMB:=pMBLine;
    if BufferBitOfs shr 3+(64{dft}*4{chn}*4{codesize}*cardinal(xc){overhead})>cardinal(length(Buffer)) then begin
      setlength(buffer,BufferBitOfs shr 3+(64*4*4*cardinal(xc)));
    end;
    for x:=0 to xc-1 do begin
      //buffer size check
(*      if cardinal(length(Buffer))-BufferBitOfs shr 3<(64{dft}*4{chn}*10{overhead}) then begin
        setlength(buffer,length(buffer)+(64*4*10));
      end;*)

      {$IFDEF hjpProfiling}HjpProfile.LoadPixels.Start;{$ENDIF}
      LoadPixels(WA,pMB,LineSize);
      {$IFDEF hjpProfiling}HjpProfile.LoadPixels.Stop;{$ENDIF}

      {$IFDEF hjpProfiling}HjpProfile.DCT.Start;{$ENDIF}
      DCT(WA);
      {$IFDEF hjpProfiling}HjpProfile.DCT.Stop;{$ENDIF}

      {$IFDEF hjpProfiling}HjpProfile.HuffEnc.Start;{$ENDIF}
      HuffEnc(WA,Buffer,BufferBitOfs);
      {$IFDEF hjpProfiling}HjpProfile.HuffEnc.Stop;{$ENDIF}

      pInc(pMB,MBInc);
    end;
    pInc(pMBLine,MBLineInc);
  end;

  BufferPos:=(BufferBitOfs+7)shr 3;
  result:=true;
end;

function hjpDecodeInternal(var bmp:TBitmap;const Quality:integer;const YUVmode:boolean;const Buffer:RawByteString;var BufferPos:integer):boolean;
var WAAllocator:TAlignedBuffer;
    WA:PWorkArea;
    MBSize,MBInc,MBLineInc,LineSize:integer;
    x,y,xc,yc:integer;
    pMBLine,pMB:pointer;

    StorePixels:TStorePixelsProc;
    IDCT:TIDCTProc;
    HuffDec:THuffDecProc;

    BufferBitOfs:Cardinal;

//    actBuffer,tempBuffer:TBytes;
    components:integer;
begin
  result:=false;
  if bmp=nil then
    bmp:=TBitmap.Create;

  {$IFDEF hjpProfiling}HjpProfile.Reset;{$ENDIF}
  WA:=WAAllocator.Alloc(sizeof(WA^),4096);

  {$IFDEF hjpProfiling}HjpProfile.HuffEnc.Start;{$ENDIF}
  SetupConstants(WA^);
  SetupEncoderQuantTables(WA^,Quality);
  SetupDecoderQuantTables(WA^,Quality);
  PrepareHuffmanTables(WA^.HuffTables);
  {$IFDEF hjpProfiling}HjpProfile.HuffEnc.Stop;{$ENDIF}

  components:=bmp.Components;
  HuffDec:=SelectHuffDecProc(components,YUVmode);
  IDCT:=SelectIDCTProc(components,YUVmode);
  StorePixels:=SelectStorePixelsProc(components,YUVmode);

  if YUVmode then MBSize:=16
             else MBSize:=8;
  LineSize:=components*bmp.width;
  MBInc:=components*MBSize;
  MBLineInc:=LineSize*MBSize;

  xc:=bmp.Width div MBSize;
  yc:=bmp.Height div MBSize;
  pMBLine:=bmp.ScanLine[bmp.Height-1];

  fillchar(WA^.HuffDiff,16,0);
  BufferBitOfs:=BufferPos shl 3;
//  actBuffer:=Buffer;

  try
    for y:=0 to yc-1 do begin
      pMB:=pMBLine;
      for x:=0 to xc-1 do begin
        //buffer size check
  {      if tempBuffer=nil then begin
          if cardinal(length(Buffer))-BufferBitOfs shr 3<(64*4*10) then begin
            SetLength(tempBuffer,(64*4*20));
            i:=length(Buffer)-integer(BufferBitOfs shr 3);
            if i>0 then move(Buffer[BufferBitOfs shr 3],tempbuffer[0],i);
            BufferBitOfs:=BufferBitOfs and 7;
            actBuffer:=tempBuffer;
          end;
        end else begin
          if cardinal(length(tempBuffer))-BufferBitOfs shr 3<(64*4*10) then begin
            exit(false);
          end;
        end;}

        {$IFDEF hjpProfiling}HjpProfile.HuffDec.Start;{$ENDIF}
        HuffDec(WA,Buffer,BufferBitOfs);
        {$IFDEF hjpProfiling}HjpProfile.HuffDec.Stop;{$ENDIF}

        {$IFDEF hjpProfiling}HjpProfile.IDCT.Start;{$ENDIF}
        IDCT(WA);
        {$IFDEF hjpProfiling}HjpProfile.IDCT.Stop;{$ENDIF}

        {$IFDEF hjpProfiling}HjpProfile.StorePixels.Start;{$ENDIF}
        StorePixels(WA,pMB,LineSize);
        {$IFDEF hjpProfiling}HjpProfile.StorePixels.Stop;{$ENDIF}

        pInc(pMB,MBInc);
      end;
      pInc(pMBLine,MBLineInc);
    end;
    result:=true;
  except {possible AccessV on buffer overrun} end;
  BufferPos:=(BufferBitOfs+7)shr 3;
end;

////////////////////////////////////////////////////////////////////////////////
// Encoder/Decoder with headers

function hjpEncode(const bmp:TBitmap;const Quality:integer;const YUVmode,IsDelta:boolean;var Buffer:RawByteString;var BufferPos:integer):boolean;
var MBSize,headerPos,dataPos:integer;
    hdr:THJPFrameHeader;
    yuv:Boolean;
begin
  Assert(bmp<>nil,'hjpEncode() bmp=nil');

  yuv:=YUVmode and(bmp.Components>2);

  hdr.Setup(bmp,Quality,YUV,IsDelta);

  MBSize:=switch(YUV,16,8);

  bmp.Width:=(hdr.Width+mbSize-1)and not(MBSize-1);
  bmp.Height:=(hdr.Height+mbSize-1)and not(MBSize-1);

  headerPos:=BufferPos;
  inc(BufferPos,sizeof(hdr));
  dataPos:=BufferPos;
  result:=hjpEncodeInternal(bmp,Quality,YUV,Buffer,BufferPos);

  bmp.Width:=hdr.Width;
  bmp.Height:=hdr.Height;

  hdr.datalen:=BufferPos-dataPos;
  hdr.CalcCRC;

  Move(hdr,Buffer[headerPos+1],sizeof(hdr));
end;

function hjpEncode(const bmp:TBitmap;const Quality:integer;const YUVmode,IsDelta:boolean):RawByteString;
var pos:integer;
begin
  setlength(result,0);pos:=0;
  if hjpEncode(bmp,Quality,YUVMode,IsDelta,Result,pos)then begin
    setlength(result,pos);
  end else begin
    setlength(result,0);
  end;
end;

function hjpDecode(var bmp:TBitmap;out Quality:integer;out YUVMode,IsDelta:boolean;const Buffer:RawByteString;var BufferPos:integer):boolean;
type PHdr=^THJPFrameHeader;
var Hdr:PHdr;
    MBSize:integer;
begin
  result:=false;
  try
    if bmp=nil then
      bmp:=TBitmap.Create;

    hdr:=psucc(pointer(Buffer),BufferPos);
    if not Hdr.Valid then
      exit;

    yuvMode:=hdr.YUV;
    quality:=hdr.Quality;
    IsDelta:=Hdr.Delta;

    case hdr.Components of
      1..4:bmp.Components:=hdr.Components;
    else raise Exception.Create('HjpLoadFromStream() error: Corrupt header');end;

    MBSize:=switch(YUVMode,16,8);
    bmp.Width:=(hdr.Width+mbSize-1)and not(MBSize-1);
    bmp.Height:=(hdr.Height+mbSize-1)and not(MBSize-1);

    inc(BufferPos,sizeof(THJPFrameHeader));
    result:=hjpDecodeInternal(bmp,Quality,YUVMode,Buffer,BufferPos);

    bmp.SetSize(hdr.Width,hdr.Height);//na ez itt qrvalassu
  except {possible av on buffer overrun} end;

end;

function hjpDecode(var bmp:TBitmap;out Quality:integer;out YUVMode,IsDelta:boolean;const Buffer:RawByteString):boolean;
var pos:integer;
begin
  pos:=0;
  Result:=hjpDecode(bmp,Quality,YUVMode,IsDelta,Buffer,Pos);
end;

function hjpDecode(var bmp:TBitmap;const Buffer:RawByteString):boolean;
var q:integer;y,d:boolean;
begin
  result:=hjpDecode(bmp,q,y,d,Buffer);
end;

procedure HjpLoadFromStream(var bmp:TBitmap;const Stream:TStream);
var hdr:^THJPFrameHeader;
    data:RawByteString;
begin
  SetLength(data,sizeof(THJPFrameHeader));
  Stream.Read(data[1],Sizeof(THJPFrameHeader));
  hdr:=pointer(data);
  if not Hdr.Valid then
    raise Exception.Create('HjpLoadFromStream() error: Corrupt header');

  SetLength(data,length(data)+hdr.datalen);
  Stream.Read(data[SizeOf(THJPFrameHeader)+1],hdr.datalen);

  hjpDecode(bmp,data);
end;

procedure HjpSaveToStream(const bmp:TBitmap;const Stream:TStream;qual:integer;yuv:boolean);
var data:RawByteString;
begin
  data:=hjpEncode(bmp,qual,yuv,false);
  if data<>'' then Stream.Write(data[1],length(data));
end;

procedure HjpLoadFromStr(var bmp:TBitmap;const Str:rawbytestring);
var q:integer;y,d:boolean;
begin
  hjpDecode(bmp,q,y,d,Str);
end;

function HjpSaveToStr(const bmp:TBitmap;const qual:integer;yuv:boolean):RawByteString;
begin
  result:=hjpEncode(bmp,qual,yuv,false);
end;

////////////////////////////////////////////////////////////////////////////////
///  THJPCodec

procedure _Diff(const ref,act:TBitmap;const Inverse:boolean);

  procedure DiffAL(a16,b16:pointer;size16:integer);
  asm
    push edi
    //constants
    mov edi,$80808080 movd xmm4,edi; pshufd xmm4,xmm4,0  //128,b
    mov edi,$3f3f3f3f movd xmm5,edi; pshufd xmm5,xmm5,0  //63,b
    mov edi,$15151515 movd xmm6,edi; pshufd xmm6,xmm6,0  //21,b
    pxor xmm7,xmm7

    xor edi,edi//ofs
    cmp edi,ecx jae @@exit
  @@loop:
    //load
{$DEFINE    in    a0,d0;out   d0;temp  x0,x1,x2,x3;const x4,x5,x6,x7}
    movaps xmm0,[eax+edi]
    movaps xmm1,[edx+edi]

    movaps xmm2,xmm0  pminub xmm2,xmm1
    movaps xmm3,xmm0  pmaxub xmm3,xmm1  psubb xmm3,xmm2  //xmm3: abs diff
    pcmpeqb xmm2,xmm1 //sign

    movaps xmm0,xmm3  pavgb xmm0,xmm7    pavgb xmm0,xmm7  //shr 2

    movaps xmm1,xmm0
    pcmpgtb xmm1,xmm6  //selector

    paddb xmm0,xmm5    //rough

    pand xmm0,xmm1  pandn xmm1,xmm3  por xmm0,xmm1 //combine

    pxor xmm0,xmm2  psubb xmm0,xmm2   //sign

    paddb xmm0,xmm4  //shift

    movaps [edx+edi],xmm0

    add edi,16
    cmp edi,ecx
    jb @@loop
  @@exit:
    pop edi
  end;

  procedure InvDiffAL(a16,b16:pointer;size16:integer);
  asm
    push edi
    //constants
    mov edi,$80808080 movd xmm4,edi; pshufd xmm4,xmm4,0  //128,b
    mov edi,$3f3f3f3f movd xmm5,edi; pshufd xmm5,xmm5,0  //63,b
    mov edi,$54545454 movd xmm6,edi; pshufd xmm6,xmm6,0  //84,b
    pxor xmm7,xmm7

    xor edi,edi//ofs
    cmp edi,ecx jae @@exit
  @@loop:

    movaps xmm1,[edx+edi]

    psubb xmm1,xmm4 //shift
    pxor xmm2,xmm2   pcmpgtb xmm2,xmm1 //sign
    pxor xmm1,xmm2   psubb xmm1,xmm2  //abs diff

    movaps xmm3,xmm1 pcmpgtb xmm3,xmm6  //selector

    movaps xmm0,xmm1 {psubb xmm0,xmm5} pslld xmm0,2  //{-63}, shl 2  az agyam eldobom, de nem ertem, hogy miert nem kell a -63
    pand xmm0,xmm3   pandn xmm3,xmm1  por xmm3,xmm0  //diff

//    vesztesegesnel ez nem jo
//    pxor xmm3,xmm2   psubb xmm3,xmm2  //apply sign
//    paddb xmm3,[eax+edi] //sum ref,diff

    //szaturakonfelózni kell a fendort vesztesegesnel
    movaps xmm1,xmm2
    pandn xmm2,xmm3  paddusb xmm2,[eax+edi]//pozitiv resz
    pand xmm3,xmm1   psubusb xmm2,xmm3     //negativ resz

    movaps [edx+edi],xmm2

    add edi,16
    cmp edi,ecx
    jb @@loop
  @@exit:
    pop edi
  end;

var pa,pb:pointer;cnt:integer;
begin
  if not ref.EqualDimensions(act)then exit;

  pa:=ref.ScanLine[ref.Height-1];
  pb:=act.ScanLine[act.Height-1];
  cnt:=ref.ImageSize;

  if((integer(pa)and $f)=0)and((integer(pb)and $f)=0)then
    if Inverse then InvDiffAL(pa,pb,cnt and not $f)
               else DiffAL(pa,pb,cnt and not $f)
  else
    raise exception.Create('Diff() unaligned bitmaps');
end;

destructor THJPCodec.Destroy;
begin
  FreeAndNil(FEncoderKeyFrame);
  FreeAndNil(FEncoderDiffFrame);

  FreeAndNil(FDecoderKeyFrame);
  FreeAndNil(FDecoderActFrame);
end;

function THJPCodec.GetEncoderOptions:PEncoderOptions;
begin result:=@FEncoderOptions end;

procedure THJPCodec.Encode(const ABmp:TBitmap;var ABuffer:RawByteString;var ABufferPos:integer);

  function CheckCompatibleKeyFrame:boolean;
  begin
    result:=(FEncoderKeyFrame<>nil)
      and(FEncoderKeyFrame.Width=ABmp.Width)
      and(FEncoderKeyFrame.Height=ABmp.Height)
      and(FEncoderKeyFrame.PixelFormat=ABmp.PixelFormat);
  end;

  procedure EncodeKey;
  var oldPos:Integer;q:integer;d,y:boolean;
  begin
    oldPos:=ABufferPos;
    hjpEncode(ABmp,FEncoderOptions.Quality,FEncoderOptions.YUVMode,false,ABuffer,ABufferPos);
    FEncoderKeyFrameIndex:=FEncoderActFrameIndex;

    if FEncoderOptions.KeyFrameInterval>1 then begin//only save key frame when needed
      if FEncoderKeyFrame=nil then
        FEncoderKeyFrame:=TBitmap.Create;
      hjpDecode(FEncoderKeyFrame,q,y,d,ABuffer,oldPos);
    end else
      FreeAndNil(FEncoderKeyFrame);

  end;

  procedure CreateCompatibleDiffFrame;
  begin
    if FEncoderDiffFrame=nil then
      FEncoderDiffFrame:=TBitmap.Create;
    with FEncoderDiffFrame do begin
      Components:=ABmp.Components;
      Width:=ABmp.Width;
      Height:=ABmp.Height;
    end;
  end;

  procedure EncodeDelta;
  begin
    CreateCompatibleDiffFrame;
    FEncoderDiffFrame.Assign(ABmp);
    _Diff(FEncoderKeyFrame,FEncoderDiffFrame,false);
    hjpEncode(FEncoderDiffFrame,FEncoderOptions.Quality,FEncoderOptions.YUVMode,true,ABuffer,ABufferPos);
  end;

  procedure EncodeKeyOrDelta;
    procedure wr(const d:RawByteString);
    begin
      if d='' then exit;
      if length(ABuffer)<ABufferPos+length(d) then
        SetLength(ABuffer,ABufferPos+length(d)+$20000);
      Move(d[1],ABuffer[ABufferPos+1],length(d));
      inc(ABufferPos,length(d));
    end;

  var dKey,dDiff:RawByteString;
  begin
    dKey:=hjpEncode(ABmp,FEncoderOptions.Quality,FEncoderOptions.YUVMode,false);

    CreateCompatibleDiffFrame;
    FEncoderDiffFrame.Assign(ABmp);
    _Diff(FEncoderKeyFrame,FEncoderDiffFrame,false);
    dDiff:=hjpEncode(FEncoderDiffFrame,FEncoderOptions.Quality,FEncoderOptions.YUVMode,true);

    if length(dDiff)<=length(dKey)*1.4 then
      wr(dDiff)
    else begin
      wr(dKey);
      if FEncoderKeyFrame=nil then
        FEncoderKeyFrame:=TBitmap.Create;
      hjpDecode(FEncoderKeyFrame,dKey);
    end;
  end;

begin
  if not CheckCompatibleKeyFrame
  or(FEncoderActFrameIndex>=FEncoderKeyFrameIndex+FEncoderOptions.KeyFrameInterval)then
    EncodeKey//tuti keyframe
  else if not FEncoderOptions.AutomaticDeltaFrames then
    EncodeDelta//tuti delta frame
  else
    EncodeKeyOrDelta;

  inc(FEncoderActFrameIndex);
end;

function THJPCodec.Encode(const ABmp:TBitmap):RawByteString;
var pos:integer;
begin
  result:='';pos:=0;
  Encode(ABmp,result,pos);
  setlength(result,pos);
end;

procedure THJPCodec.Encode(const IO:TIO;const ABmp:TBitmap);
var d:RawByteString;
begin
  d:=Encode(ABmp);
  if d<>'' then IO.IOBlock(d[1],length(d));
end;

function THJPCodec.Decode(const ABuffer:RawByteString;var ABufferPos:integer):TBitmap;
var q:integer;y,d:boolean;
begin
  if hjpDecode(FDecoderActFrame,q,y,d,ABuffer,ABufferPos)then begin
    if not d then begin//keyframe
      if FDecoderKeyFrame=nil then
        FDecoderKeyFrame:=TBitmap.Create;
      FDecoderKeyFrame.Assign(FDecoderActFrame)
    end else begin//diff frame
      if FDecoderActFrame.EqualDimensions(FDecoderKeyFrame) then
        _Diff(FDecoderKeyFrame,FDecoderActFrame,true);
    end;

    result:=FDecoderActFrame;
  end else
    result:=nil;
end;

function THJPCodec.Decode(const ABuffer:RawByteString):TBitmap;
var p:integer;
begin
  p:=0;
  result:=Decode(ABuffer,p);
end;

{ THJPFrames }

procedure THJPFrames.Append(const fr: RawByteString);
begin
  if fr='' then exit;
  FIndex.Append(Length(FData)+1);
  FData:=FData+fr;
end;

procedure THJPFrames.Append(const b: TBitmap);
begin
  if b.Empty then exit;
  Append(FCodec.Encode(b));
end;

procedure THJPFrames.Clear;
begin
  FData:='';
  FIndex.Clear;
  lastFrame:=-1;
end;

constructor THJPFrames.Create;
begin
  inherited;
  FCodec:=THJPCodec.Create(nil);
  with FCodec.EncoderOptions^ do begin
    Quality:=85;
    YUVMode:=true;
    KeyFrameInterval:=0;
    AutomaticDeltaFrames:=false;
  end;
  lastFrame:=-1;
end;

function THJPFrames.Decode(const n: integer): TBitmap;
var fr:RawByteString;
begin
  FDecodedFrameChanged:=false;
  if lastFrame=n then exit(FCodec.FDecoderActFrame);

  fr:=GetFrame(n);
  if fr='' then exit(nil);
  result:=FCodec.Decode(fr);
  lastFrame:=n;
  FDecodedFrameChanged:=true;
end;

destructor THJPFrames.Destroy;
begin
  FreeAndNil(FCodec);
  inherited;
end;

function THJPFrames.GetFrame(n: integer): rawbytestring;
begin
  if(n<0)or(n>FIndex.Count-1) then exit('');
  if n=FIndex.Count-1 then result:=copy(FData,FIndex.FItems[n])
                      else result:=copy(FData,FIndex.FItems[n],FIndex.FItems[n+1]-FIndex.FItems[n]);
end;

function THJPFrames.GetFrameCount: integer;
begin
  result:=FIndex.FCount;
end;

procedure THJPFrames.LoadFromStr(const stream: RawByteString);
var p:integer;
    hdr:PHJPFrameHeader;
begin
  Clear;
  FData:=stream;

  p:=1;
  repeat
    p:=Pos('HJP ',FData,[],p);
    if p<=0 then break;//no more
    if p>=(length(FData)-SizeOf(THJPFrameHeader))then break; //eof
    hdr:=@FData[p];
    if not hdr.Valid then Continue;
    FIndex.Append(p);
    p:=p+max(1,hdr.FrameLen);
  until false;
end;

procedure THJPFrames.SaveToFile(const fn: string);
var f:file;
begin
  AssignFile(f,fn);
  {$I-}Rewrite(f,1);
  if FData<>'' then BlockWrite(f,FData[1],length(FData));
  closefile(f);
end;

function THJPFrames.SaveToStr: RawByteString;
begin
  result:=FData;
end;


initialization
  SSEDataBuffer.Alloc(sizeof(TSSEData),16);
  SSEData:=SSEDataBuffer.Address;
  SSEData.init;

  _PrepareFlipProgram;
  {$IFDEF hjpProfiling}HjpProfile:=THjpProfile.Create;{$ENDIF}
finalization
  {$IFDEF hjpProfiling}FreeAndNil(HjpProfile);{$ENDIF}
end.
