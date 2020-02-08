unit UModelCompressor;
{
Zaes
raw tris                        248k
raw quads                       164k
compr tris                      101k
comp quads                       68k
comp quads delta1                40k
comp quads delta2                38k
comp quads delta2 listIdx        26k
comp quads delta2 listIdx travel 21k
+ optimized prediction           18k
+ 6bit idximproved huff,vertbits 15k
+ normal compress 13bits         14k
}

interface

uses SysUtils, Het.Objects, Het.Utils, UVector, UModelPart, Opengl1x;

function CompressNormal(const n:TV3F;const bits:integer):integer;
function UnCompressNormal(const n:integer;const bits:integer):TV3F;

function CompressCoord(const s:single):integer;
function UnCompressCoord(i,bits:integer):single;

function CompressTexCoord(const s:single):integer;
function UnCompressTexCoord(const i:integer):single;

function CompressFacegroup(AFaceGroup:TFaceGroup;NormalBits:integer=13;IndexBits:integer=6):ansistring;

function UnCompressFacegroup(AFaceGroup:TFaceGroup;{ha nil, akkor glquads}const Data:ansistring):boolean;
function GlUnCompressFacegroup(const data:ansistring):boolean;

Type
  TAttributeCache=Object  //hasonlo, mint a vga vertex cache
    SizeSh,Size,SizeMask:integer;
    Buffer:array of integer;
    Pos:integer;
    constructor Init(ASizeSh:integer);
    procedure Add(value:integer);
    function Get(idx:integer):integer;
    function Find(value:integer):integer;
  end;


implementation

uses Classes;


function CompressCoord(const s:single):integer;begin result:=round(s*1023);end;//10 bit fix point

function UnCompressCoord(i,bits:integer):single;
  function sar(a,b:integer):integer;register asm mov ecx,edx;sar eax,cl end;
begin
  bits:=32-bits;
  result:=sar(i shl bits,bits)*(1/1023);
end;

function CompressTexCoord(const s:single):integer;
begin
  result:=round(s*2047);
  if result<0 then result:=0 else if result>2047 then result:=2047;
end;//11 bit texture coords

function UnCompressTexCoord(const i:integer):single;
begin
  result:=i*(1/2047);
end;

//                      normal compression                                      //

Type
  TNormalTri=class  //Normal triangle tree node
    Center:TV3f;
    SubTri:array[0..3]of TNormalTri;
    constructor Create(const Level:integer;const V0,V1,V2:TV3F);
    destructor Destroy;override;
    function ClosestSubTriId(const N:TV3F):integer;
  end;

constructor TNormalTri.Create(const Level:integer;const V0,V1,V2:TV3F);
var V01,V02,V12:TV3f;
begin
  Center:=VNormalize(V0+V1+V2);
  if level<6 then begin
    V01:=VNormalize(V0+V1);
    V02:=VNormalize(V0+V2);
    V12:=VNormalize(V1+V2);
    SubTri[0]:=TNormalTri.Create(Level+1, V0,V01,V02);
    SubTri[1]:=TNormalTri.Create(Level+1, V1,V01,V12);
    SubTri[2]:=TNormalTri.Create(Level+1, V2,V02,V12);
    SubTri[3]:=TNormalTri.Create(Level+1,V01,V02,V12);
  end;
end;

destructor TNormalTri.Destroy;
var i:integer;
begin
  for i:=0 to high(SubTri)do
    SubTri[i].Free;
end;

function TNormalTri.ClosestSubTriId(const N:TV3F):integer;
var d,mind:single;i:integer;
begin
  result:=0;mind:=1e30;
  for i:=0 to 3 do begin
    d:=VDistManh(N,Subtri[i].Center);
    if d<mind then begin mind:=d;result:=i;end;
  end;
end;

var _NormalTree:TNormalTri;

function NormalTreeRoot:TNormalTri;
begin
  if _NormalTree=nil then _NormalTree:=TNormalTri.Create(0,V3F(1,0,0),V3F(0,1,0),V3F(0,0,1));
  result:=_NormalTree;
end;


function CompressNormal(const n:TV3F;const bits:integer):integer;
var _shortints:array[0..3]of shortint;
    _int:integer absolute _shortints;
    absN:TV3F;act:TNormalTri;i,nextid,level:integer;
begin
  case bits of
    24:begin
      _int:=0;for i:=0 to 2 do _shortints[i]:=round(N.Coord[i]*127);result:=_int;
    end;
    17:begin
      _int:=0;
      _shortints[0]:=round(N.x*127);
      _shortints[1]:=round(N.z*127);
      if n.y<0 then _shortints[2]:=1;
      result:=_int;
    end;
    15,13,11,9:begin
      level:=(bits-3)shr 1;
      result:=ord(n.x<0)+ord(n.y<0)shl 1+ord(n.z<0)shl 2;
      absN:=VAbs(N);
      act:=NormalTreeRoot;
      for i:=0 to level-1 do begin
        nextid:=act.ClosestSubTriId(absN);
        Result:=Result shl 2+nextid;
        act:=act.SubTri[nextid];
      end;
    end;
    else raise Exception.Create('CompressNormal() invalid bitcount -> '+inttostr(bits));
  end;
end;

function UnCompressNormal(const n,bits:integer):TV3F;
var _shortints:array[0..3]of shortint;
    _int:integer absolute _shortints;
    i,level,nextid,sign:integer;act:TNormalTri;
begin
  case bits of
    24:begin
      _int:=N;for i:=0 to 2 do result.Coord[i]:=_shortints[i]*(1/127);
    end;
    17:begin
      _int:=N;
      result.x:=_shortints[0]*(1/127);
      result.z:=_shortints[1]*(1/127);
      with result do begin
        y:=(1-sqr(x)-sqr(z));
        if y<=0 then y:=0 else y:=sqrt(y);
        if _shortints[2]<>0 then y:=-y;
      end;
    end;
    15,13,11,9:begin
      level:=(bits-3)shr 1;
      act:=NormalTreeRoot;
      for i:=level-1 downto 0 do begin
        nextid:=n shr(i*2)and 3;
        act:=act.SubTri[nextId];
      end;
      result:=act.Center;
      sign:=n shr(level*2);
      if sign and 1<>0 then result.x:=-result.x;
      if sign and 2<>0 then result.y:=-result.y;
      if sign and 4<>0 then result.z:=-result.z;
    end;
    else raise Exception.Create('UnCompressNormal() invalid bitcount -> '+inttostr(bits));
  end;
end;

//                              Vertex attribute sets                           //

type TCompressedVertex=array[0..5]of integer;

//                      Attribute cache                                         //

constructor TAttributeCache.Init(ASizeSh:integer);
begin
  SizeSh:=ASizeSh;
  Size:=1 shl ASizeSh;
  SizeMask:=Size-1;
  SetLength(Buffer,Size);
  fillchar(Buffer[0],Size*sizeof(Buffer[0]),0);
  Pos:=0;
end;

procedure TAttributeCache.Add(value:integer);
begin
  Pos:=(Pos+1)and SizeMask;
  Buffer[Pos]:=value;
end;

function TAttributeCache.Find(Value:integer):integer;var i:integer;
begin
  for i:=0 to SizeMask do if Get(i)=Value then begin result:=i;exit end;
  result:=-1;
end;

function TAttributeCache.Get(idx:integer):integer;
begin result:=Buffer[(Pos-idx)and SizeMask]end;

//                      Facegroup compressor                                    //

function CompressFacegroup;
  //simple bitstream writer
  var buffer:pointer;
      bufferbitOfs:cardinal;

  procedure writeBits(bits,newVal:cardinal);
  var val:pcardinal;mask,o7:cardinal;
  begin
    if bits<=0 then exit;
    val:=pcardinal(cardinal(buffer)+bufferbitofs shr 3);
    o7:=bufferbitofs and 7;
    mask:=((1 shl bits)-1)shl(o7);
    val^:=val^ and not mask or((newVal shl(o7))and mask);
    bufferbitOfs:=bufferbitOfs+bits;
  end;

  //vertex attributes compression
  var CompressedVertexBits:TCompressedVertex;

  function CompressVertex(V:TVertex):TCompressedVertex;
  begin
    if V<>nil then with V do begin
      Result[0]:=CompressCoord(Vx);
      Result[1]:=CompressCoord(Vy);
      Result[2]:=CompressCoord(Vz);
      Result[3]:=CompressNormal(N^,compressedVertexBits[3]);
      Result[4]:=CompressTexCoord(Tx);
      Result[5]:=CompressTexCoord(Ty);
    end else
      fillchar(result,sizeof(result),0);
  end;

  {large cache vx,vy,vz,N,tx,ty}
  var Cache:array[0..5]of TAttributeCache;

  procedure writeVertex(const act,prev0,prev1:TCompressedVertex;canBeSameVertex:boolean);
    function cmp(const prev:TCompressedVertex):boolean;
    begin
      result:=(act[0]=prev[0])and(act[1]=prev[1])and(act[2]=prev[2])and
              (act[3]=prev[3])and(act[4]=prev[4])and(act[5]=prev[5]);
    end;
  var i,idx:integer;
  begin
    if canBeSameVertex and cmp(prev0) then writeBits(2,0)else // 00 =prev0
    if canBeSameVertex and cmp(prev1) then writeBits(2,2)else // 01 =prev1
    begin
      if canBeSameVertex then writeBits(1,1);                 // 1  details
      for i:=0 to high(act)do begin
        if act[i]=prev0[i] then writebits(1,0)else            // 0    =prev0
        if act[i]=prev1[i] then writebits(3,3)else begin      // 110  =prev1
          idx:=Cache[i].Find(act[i]);
          if(idx>=0)then begin
            writeBits(2,1);                                   // 10   in large cache
            writeBits(IndexBits,idx);
          end else begin
            Cache[i].Add(Act[i]);
            writebits(3,7);                                   // 111  data
            writebits(compressedVertexBits[i],cardinal(act[i]));
          end;
        end;
      end;
    end;
  end;

  procedure writeFaceFlags(isQuad:boolean;NextP0:integer);
  begin
    if isQuad then case NextP0 of
      0:writebits(2,0);         // 00   quad, left
      2:writebits(2,2);         // 01   quad, right
      else writebits(2,1);      // 10   quad, forward
    end else case NextP0 of
      0:writeBits(3,3);         // 110  tri, left
      else writeBits(3,7);      // 111  tri, right
    end;
  end;

var i,j:integer;
    Prev0,Prev1:TCompressedVertex;
    Act:array[0..3]of TCompressedVertex;

    AbsBounds:TV3F;
begin with AFaceGroup do begin
  //prepare model
  MakeQuads;
  OptimizeOrder;

  //init buffer
  SetLength(Result,1024);
  buffer:=@Result[1];
  bufferbitOfs:=0;

  //init compressedVertexBits
  AbsBounds:=CalcAbsBounds(true);
  for i:=0 to 2 do begin
    for j:=0 to 23 do if (1 shl j)*(1/1024)>AbsBounds.Coord[i]then break;
    compressedVertexBits[i]:=j+1;//Vxyz
  end;
  compressedVertexBits[3]:=NormalBits;//Normal
  compressedVertexBits[4]:=11;//Tx
  compressedVertexBits[5]:=11;//Ty

  //init large cache
  for i:=0 to high(Cache)do Cache[i].Init(IndexBits);

  //init small cache
  Fillchar(Act,sizeof(Act),0);
  Fillchar(prev0,sizeof(prev0),0);
  Fillchar(prev1,sizeof(prev1),0);

  //Write header
  for i:=0 to 5 do writeBits(5,compressedVertexBits[i]);  //attribute bitcounts
  writeBits(4,IndexBits);//large cache size

  //process faces
  for i:=0 to Count-1 do with AFaceGroup.ByIndex[i]do begin
    if not Valid then Continue;
    //buffer resize
    if bufferbitOfs shr 3+256>cardinal(length(Result))then begin
      setlength(Result,length(Result)*2);
      buffer:=@Result[1];
    end;

    writeFaceFlags(IsQuad,NextP0);

    Act[0]:=CompressVertex(Vertex0);    WriteVertex(Act[0],Prev0 ,Prev1 ,true);
    Act[1]:=CompressVertex(Vertex1);    WriteVertex(Act[1],Prev1, Act[0],true);
    Act[2]:=CompressVertex(Vertex2);    WriteVertex(Act[2],Act[1],Act[0],false);
    if Vertex[3]<>nil then begin
      Act[3]:=CompressVertex(Vertex3);  WriteVertex(Act[3],Act[2],Act[0],false);
    end;

      //prepare prev0, prev1 for next face
    case NextP0 of
      0:begin Prev0:=act[0];prev1:=act[count-1];end;
      2:begin Prev0:=act[2];prev1:=act[1];end;
      else Prev0:=act[3];prev1:=act[2];//csak quad
    end;
  end;

  SetLength(Result,(bufferbitOfs+7) shr 3);
end;end;



function UnCompressFacegroup(AFaceGroup:TFaceGroup;const Data:ansistring):boolean;

  //simple bitstream reader
  var buffer:pointer;
      bBitOfs,bByteOfs:cardinal;
      bValue:Cardinal;

  function readBits(bits:cardinal):cardinal;var bo:cardinal;
  begin
    result:=bValue and (1 shl bits-1);
    bBitOfs:=bBitOfs+bits;
    bo:=bBitOfs shr 3;
    if bo=0 then begin
      bValue:=bValue shr bits;
    end else begin
      bByteOfs:=bByteOfs+bo;
      bBitOfs:=bBitOfs and $7;
      bValue:=PCardinal(cardinal(buffer)+bByteOfs)^shr bBitOfs;
    end;
  end;

  function read1Bit:cardinal;var bo:cardinal;//hardwired stuff
  begin
    result:=bValue and 1;
    bBitOfs:=bBitOfs+1;
    bo:=bBitOfs shr 3;
    if bo=0 then begin
      bValue:=bValue shr 1;
    end else begin
      bByteOfs:=bByteOfs+1;
      bBitOfs:=bBitOfs and $7;
      bValue:=PCardinal(cardinal(buffer)+bByteOfs)^shr bBitOfs;
    end;
  end;

  function read2Bit:cardinal;var bo:cardinal;//hardwired stuff
  begin
    result:=bValue and 3;
    bBitOfs:=bBitOfs+2;
    bo:=bBitOfs shr 3;
    if bo=0 then begin
      bValue:=bValue shr 2;
    end else begin
      bByteOfs:=bByteOfs+1;
      bBitOfs:=bBitOfs and $7;
      bValue:=PCardinal(cardinal(buffer)+bByteOfs)^shr bBitOfs;
    end;
  end;

  //vertex attributes uncompression
  var CompressedVertexBits:TCompressedVertex;
      IndexBits:integer;

  var unV,unN:TV3F;unT:TV2F;
  procedure UnCompressVertex(const C:TCompressedVertex);
  begin
    unV.x:=UnCompressCoord(C[0],compressedVertexBits[0]);
    unV.y:=UnCompressCoord(C[1],compressedVertexBits[1]);
    unV.z:=UnCompressCoord(C[2],compressedVertexBits[2]);
    unN:=UnCompressNormal(C[3],compressedVertexBits[3]);
    unT.x:=UnCompressTexCoord(C[4]);
    unT.y:=UnCompressTexCoord(C[5]);
  end;

  {large cache vx,vy,vz,N,tx,ty}
  var Cache:array[0..5]of TAttributeCache;

  procedure readVertex(var Act:TCompressedVertex;const prev0,prev1:TCompressedVertex;canBeSameVertex:boolean);
  var i:integer;
  begin
    if canBeSameVertex and(read1Bit=0)then begin
      if readBits(1)=0 then Act:=prev0         // 00 =prev0
                       else Act:=prev1;        // 01 =prev1
      exit;
    end;

    for i:=0 to high(Act)do begin          //details
      if read1bit=0 then begin           // 0       =prev0
        Act[i]:=prev0[i];
      end else if read1bit=0 then begin  // 10      in large cache
        Act[i]:=Cache[i].Get(readbits(IndexBits));
      end else if read1bit=0 then begin  // 110     =prev1
        Act[i]:=prev1[i];
      end else begin                       // 111     data
        Act[i]:=readbits(CompressedVertexBits[i]);
        Cache[i].Add(Act[i]);
      end;
    end;
  end;

  procedure readFaceFlags(var isQuad:boolean;var NextP0:integer);
  begin
    case read2Bit of
      0:begin isQuad:=true;NextP0:=0 end;// 00   quad, left
      2:begin isQuad:=true;NextP0:=2 end;// 01   quad, right
      1:begin isQuad:=true;NextP0:=3 end;// 10   quad, forward
      else case read1Bit of
        0:begin isQuad:=false;NextP0:=0 end;     // 110  tri, left
        else begin isQuad:=false;NextP0:=2 end;  // 111  tri, right
      end;
    end;
  end;

var i:integer;
    Prev0,Prev1:TCompressedVertex;
    Act:array[0..3]of TCompressedVertex;
    _IsQuad:boolean;_NextP0:integer;
    lastN:TV3f;lastT:TV2f;

begin
  //clear facegroup
  result:=false;
  if AFaceGroup<>nil then with AFaceGroup do begin
    Clear;Vertices.Clear;end;

  if length(data)<16 then exit;
  //init buffer
  buffer:=@Data[1];
  bByteOfs:=0;bBitOfs:=0;bValue:=PCardinal(buffer)^;

  //read header
  for i:=0 to 5 do compressedVertexBits[i]:=readBits(5);  //attribute bitcounts
  IndexBits:=readBits(4);//large cache size

  //init large cache
  for i:=0 to high(Cache)do Cache[i].Init(IndexBits);

  //init small cache
  Fillchar(Act,sizeof(Act),0);
  Fillchar(prev0,sizeof(prev0),0);
  Fillchar(prev1,sizeof(prev1),0);

  //inig last gl attriputes
  lastN:=V3F(0,0,0);lastT:=V2F(0,0);

  //process faces
  while integer(bByteOfs)<length(Data)-2 do begin //mindenhol kene tesztelni a bufferbol kiszaaldast, de az lassu
    readFaceFlags(_IsQuad,_NextP0);

    ReadVertex(Act[0],Prev0 ,Prev1 ,true);
    ReadVertex(Act[1],Prev1, Act[0],true);
    ReadVertex(Act[2],Act[1],Act[0],false);
    if _IsQuad then begin
      ReadVertex(Act[3],Act[2],Act[0],false);
    end;

    if AFaceGroup<>nil then with TFace.Create(AFaceGroup)do begin
      for i:=0 to 2+ord(_IsQuad) do begin
        UnCompressVertex(Act[i]);
        Vertex[i]:=AFaceGroup.Vertices.FindAdd(unV,unN,unT);
      end;
    end else begin
      if not _IsQuad then Act[3]:=Act[2];
      for i:=0 to 3 do begin
        UnCompressVertex(Act[i]);
        if lastN<>unN then begin glNormal3fv  (@unN);lastN:=unN end;
        if lastT<>unT then begin glTexcoord2fv(@unT);lastT:=unT end;
        glVertex3fv(@unV);
      end;
    end;

    //prepare prev0, prev1 for next face
    case _NextP0 of
      0:begin Prev0:=act[0];prev1:=act[2+ord(_IsQuad)];end;
      2:begin Prev0:=act[2];prev1:=act[1];end;
      else Prev0:=act[3];prev1:=act[2];//csak quad
    end;
  end;

  result:=true;
end;

function GlUnCompressFacegroup(const data:ansistring):boolean;
begin
  glBegin(GL_QUADS);
  result:=UnCompressFacegroup(nil,data);
  glEnd;
end;

initialization

finalization
  if _NormalTree<>nil then
    FreeAndNil(_NormalTree);
end.
