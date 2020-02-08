unit UGCNEmu;

interface

uses
  SysUtils, het.Utils, math;

type
  TCA=array[0..maxint shr 2-1]of cardinal;
  PCA=^TCA;

  //similiar to int64 in SRegs
  Cardinal2=packed record
    data:int64;
    class operator implicit(const a:Cardinal2):boolean;
    class operator implicit(const a:boolean):Cardinal2;
    class operator implicit(const a:Cardinal2):cardinal;
    class operator implicit(const a:cardinal):Cardinal2;
  end;

  TGCNEmu=class
  strict private
    FVRegs,FSRegs,FMem:pointer;
    FMemSize:integer;
    FLiterals:array of Cardinal;
    FCode:AnsiString;
    FRecording:boolean;
  public
    vcc,exec:Cardinal2;//special regs
    function VRegs:PCA;

    constructor create(const AVRegs,ASRegs,AMem:pointer;const AMemSize:integer);

    function Cnst(const c:cardinal):PCardinal;overload;
    function Cnst(const i: integer): PCardinal;overload;
    function Cnst(const f:single):PCardinal;overload;

    function RegName(var r: Cardinal): ansistring;overload;
    function RegName(var r: Cardinal2): ansistring;overload;
    procedure Emit(const line:ansistring);overload;
    procedure Emit(var r:cardinal);overload;
    procedure Emit(var r:cardinal2);overload;
    procedure Emit(const instr:ansistring;var d,s0:cardinal);overload;
    procedure Emit(const instr:ansistring;var d,s0,s1:cardinal);overload;
    procedure Emit(const instr:ansistring;var d,s0,s1,s2:cardinal);overload;
    procedure Emit(const instr:ansistring;var d:cardinal;var cout:cardinal2;var s0,s1:cardinal);overload;
    procedure Emit(const instr:ansistring;var d:cardinal;var cout:cardinal2;var s0,s1:cardinal;var cin:cardinal2);overload;

    procedure BeginRec;
    function EndRec:ansistring;

    procedure v_add_i32(var d:cardinal;var cout:Cardinal2;var s0,s1:cardinal);
    procedure v_sub_i32(var d:cardinal;var cout:Cardinal2;var s0,s1:cardinal);
    procedure v_addc_u32(var d:cardinal;var cout:Cardinal2;var s0,s1:cardinal;var cin:Cardinal2);
    procedure v_subb_u32(var d:cardinal;var cout:Cardinal2;var s0,s1:cardinal;var cin:Cardinal2);
    procedure v_xor_b32(var d,s0,s1:cardinal);
    procedure v_and_b32(var d,s0,s1:cardinal);
    procedure v_or_b32(var d,s0,s1:cardinal);
    procedure v_not_b32(var d,s0:cardinal);
    procedure v_alignbit_b32(var d,s0,s1,s2:cardinal);
    procedure v_mul_u32_u24(var d,s0,s1:cardinal);
    procedure v_mul_hi_u32_u24(var d,s0,s1:cardinal);
    procedure v_ashrrev_b32(var d,s0,s1:cardinal);
    procedure v_lshrrev_b32(var d,s0,s1:cardinal);
    procedure v_lshlrev_b32(var d,s0,s1:cardinal);
    procedure v_mad_u32_u24(var d,s0,s1,s2:cardinal);
    procedure v_mov_b32(var d,s0:cardinal);
    procedure tbuffer_load(const data:PCardinal;const src:PCardinal;const dwCount:integer);
    procedure tbuffer_store(const data:PCardinal;const Dst:PCardinal;const dwCount:integer);
  end;

implementation

{ Cardinal2 }

class operator Cardinal2.implicit(const a:Cardinal2):boolean;begin result:=a.data<>0;end;
class operator Cardinal2.implicit(const a:boolean):Cardinal2;begin result.data:=ord(a);end;
class operator Cardinal2.implicit(const a:Cardinal2):cardinal;begin result:=a.data;end;
class operator Cardinal2.implicit(const a:cardinal):Cardinal2;begin result.data:=a;end;

{ TGCNEmu }

function TGCNEmu.Cnst(const c: cardinal): PCardinal;
var i:integer;
begin
  for i:=0 to high(FLiterals)do
    if FLiterals[i]=c then exit(@FLiterals[i]);
  SetLength(FLiterals,length(FLiterals)+1);
  result:=@FLiterals[high(FLiterals)];
  result^:=c;
end;

function TGCNEmu.Cnst(const i: integer): PCardinal;
begin
  result:=Cnst(PCardinal(@i)^);
end;

function TGCNEmu.Cnst(const f: single): PCardinal;
begin
  result:=Cnst(PCardinal(@f)^);
end;

constructor TGCNEmu.create(const AVregs,ASRegs,AMem:pointer;const AMemSize:integer);
begin
  FVRegs:=AVRegs;
  FSRegs:=ASRegs;
  FMem:=AMem;
  FMemSize:=AMemSize;
end;

const
  _unknownReg:ansistring='<UNKNOWN>';

function TGCNEmu.RegName(var r: Cardinal):ansistring;
var i:integer;
begin
  if integer(@r)and 3<>0 then exit('');//must be aligned
  i:=(integer(@r)-integer(FVRegs))shr 2;
  if inrange(i,0,255)then exit('v'+tostr(i));
  i:=(integer(@r)-integer(FSRegs))shr 2;
  if inrange(i,0,104)then exit('s'+tostr(i));
  i:=(integer(@r)-integer(FLiterals))shr 2;
  if inrange(i,0,high(FLiterals))then exit('s'+tostr(104-i));
  result:=_unknownReg;
end;

function TGCNEmu.RegName(var r: Cardinal2):ansistring;
var i:integer;
begin
  if @r=@vcc then exit('vcc');
  if @r=@exec then exit('exec');
  i:=(integer(@r)-integer(FSRegs))shr 3;
  if inrange(i,0,51)then exit('s['+tostr(i shl 1)+':'+tostr(i shl 1+1)+']');
  result:=_unknownReg;
end;

procedure TGCNEmu.emit(var r: cardinal);
var s:ansistring;
begin if not FRecording then exit;
  s:=RegName(r);if s=_unknownReg then raise Exception.Create('invalid reg');
  emit(s);
end;

procedure TGCNEmu.emit(var r: cardinal2);
var s:ansistring;
begin if not FRecording then exit;
  s:=RegName(r);if s='' then raise Exception.Create('invalid reg');
  emit(s);
end;

procedure TGCNEmu.emit(const line: ansistring);
begin if not FRecording then exit;
  ListAppend(FCode,line,#13#10);
end;

procedure TGCNEmu.emit(const instr: ansistring; var d, s0, s1: cardinal);
begin if not FRecording then exit;
  emit(instr+' '+regname(d)+', '+regname(s0)+', '+regname(s1));
end;

procedure TGCNEmu.emit(const instr: ansistring; var d, s0: cardinal);
begin if not FRecording then exit;
  emit(instr+' '+regname(d)+', '+regname(s0));
end;

procedure TGCNEmu.emit(const instr: ansistring; var d: cardinal; var cout: cardinal2; var s0, s1: cardinal; var cin: cardinal2);
begin if not FRecording then exit;
  emit(instr+' '+regname(d)+', '+regname(cout)+', '+regname(s0)+', '+regname(s1)+', '+regname(cin));
end;

procedure TGCNEmu.emit(const instr: ansistring; var d: cardinal; var cout: cardinal2; var s0, s1: cardinal);
begin if not FRecording then exit;
  emit(instr+' '+regname(d)+', '+regname(cout)+', '+regname(s0)+', '+regname(s1));
end;

procedure TGCNEmu.emit(const instr: ansistring; var d, s0, s1, s2: cardinal);
begin if not FRecording then exit;

  emit(instr+' '+regname(d)+', '+regname(s0)+', '+regname(s1)+', '+regname(s2));
end;

procedure TGCNEmu.BeginRec;
begin
  FRecording:=true;
end;

function TGCNEmu.EndRec: ansistring;
begin
  FRecording:=false;
  result:=FCode;
  FCode:='';
end;

procedure TGCNEmu.v_add_i32(var d:cardinal;var cout:Cardinal2;var s0,s1:cardinal);var s:Int64;
begin
  emit('v_add_i32',d,cout,s0,s1);
  s:=int64(s0)+s1; d:=s; cout:=s shr 32 and 1;
end;

procedure TGCNEmu.v_sub_i32(var d:cardinal;var cout:Cardinal2;var s0,s1:cardinal);var s:Int64;
begin
  emit('v_sub_i32',d,cout,s0,s1);
  s:=int64(s0)-s1; d:=s; cout:=s shr 32 and 1;
end;

procedure TGCNEmu.v_addc_u32(var d:cardinal;var cout:Cardinal2;var s0,s1:cardinal;var cin:Cardinal2);var s:Int64;
begin
  emit('v_addc_u32',d,cout,s0,s1,cin);
  s:=int64(s0)+s1+cardinal(cin)and 1; d:=s; cout:=s shr 32 and 1;
end;

procedure TGCNEmu.v_subb_u32(var d:cardinal;var cout:Cardinal2;var s0,s1:cardinal;var cin:Cardinal2);var s:Int64;
begin
  emit('v_subb_u32',d,cout,s0,s1,cin);
  s:=int64(s0)-s1-cardinal(cin)and 1; d:=s; cout:=s shr 32 and 1;
end;

procedure TGCNEmu.v_xor_b32(var d,s0,s1:cardinal);
begin
  emit('v_xor_b32',d,s0,s1);
  d:=s0 xor s1;
end;

procedure TGCNEmu.v_and_b32(var d,s0,s1:cardinal);
begin
  emit('v_and_b32',d,s0,s1);
  d:=s0 and s1;
end;

procedure TGCNEmu.v_or_b32(var d,s0,s1:cardinal);
begin
  emit('v_or_b32',d,s0,s1);
  d:=s0 or s1;
end;

procedure TGCNEmu.v_not_b32(var d,s0:cardinal);
begin
  emit('v_not_b32',d,s0);
  d:=not s0;
end;

procedure TGCNEmu.v_alignbit_b32(var d,s0,s1,s2:cardinal);
begin
  emit('v_alignbit_b32',d,s0,s1,s2);
   d:=(int64(s1)or int64(s0)shl 32)shr s2;
end;

procedure TGCNEmu.v_mul_u32_u24(var d,s0,s1:cardinal);
begin
  emit('v_mul_u32_u24',d,s0,s1);
  d:=umul64(s0 and $FFFFFF,s1 and $FFFFFF);
end;

procedure TGCNEmu.v_mul_hi_u32_u24(var d,s0,s1:cardinal);
begin
  emit('v_mul_hi_u32_u24',d,s0,s1);
  d:=umul64(s0 and $FFFFFF,s1 and $FFFFFF)shr 32 and $FFFF;
end;

procedure TGCNEmu.v_ashrrev_b32(var d,s0,s1:cardinal);
begin
  emit('v_ashrrev_b32',d,s0,s1);
  d:=sar(s1,s0);
end;

procedure TGCNEmu.v_lshrrev_b32(var d,s0,s1:cardinal);
begin
  emit('v_lshrrev_b32',d,s0,s1);
  d:=s1 shr s0;
end;

procedure TGCNEmu.v_lshlrev_b32(var d,s0,s1:cardinal);
begin
  emit('v_lshlrev_b32',d,s0,s1);
  d:=s1 shl s0;
end;

procedure TGCNEmu.v_mad_u32_u24(var d,s0,s1,s2:cardinal);
begin
  emit('v_mad_u32_u24',d,s0,s1,s2);
  d:=(s0 and $FFFFFF)*(s1 and $FFFFFF)+s2;
end;

procedure TGCNEmu.v_mov_b32(var d,s0:cardinal);
begin
  emit('v_mov_b32',d,s0);
  d:=s0;
end;

procedure TGCNEmu.tbuffer_load(const data:PCardinal;const src:PCardinal;const dwCount:integer);
begin
  move(Src^,data^,dwCount*4);
end;

procedure TGCNEmu.tbuffer_store(const data:PCardinal;const Dst:PCardinal;const dwCount:integer);
begin
//tbuffer_store_format_x  v4, v0, UAV, 0 offen format:[BUF_DATA_FORMAT_32,BUF_NUM_FORMAT_FLOAT]
  move(data^,Dst^,dwCount*4);
end;

function TGCNEmu.VRegs: PCA;
begin
  result:=pca(FVregs);
end;

end.