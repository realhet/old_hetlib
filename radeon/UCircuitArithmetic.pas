unit UCircuitArithmetic;//het.parser variants unsCal het.cal unscal unsSystem

interface

uses
  Windows, SysUtils, Types, Classes, Forms, het.Utils, het.Objects,
  het.Arrays, het.Stream, UVector, UMatrix, math, opengl1x, graphics, het.Gfx,
  het.textures, GLTImage, typinfo, het.Assembler,het.glviewer;

type
  TGateType=(gtInput,gtMov,gtINot,gtIOr,gtIAnd,gtIXor,gtIEq,gtIAdd,gtISub,gtRol1,gtRol2,gtRol4,gtRol5,gtRol7,gtRol9,gtRol13,gtRol18,gtRol30,gtVectSel,gtUMin3,gtUMin,
             {s_instr}gtS_not,gtS_xor,gtS_and,gtS_or,gtS_andn2,gtS_iadd,gtS_isub,gtS_ushr,gtS_ishl,gtS_ishr,
             {new mandel2 stuff}
             gtUShr,gtIShr,gtIShl,gtBitalign
             );
  TGateFlag=(gfCommutative,gtPassive);
  TGateFlags=set of TGateFlag;
  TGateShape=(shRound,shSquare,shDot,shRndRect);//visual appearance

  TGateInfo=record
    name:ansistring;  //unique nev
    inCnt:integer;    //inputok szama
    shape:TGateShape;
    flags:TGateFlags;
    ilCode, //amd_il template iadd d,s0,s1
    isaCode,
    sseCode:ansistring;//forraskod sse-ben a szimulaciohoz
  end;
  PGateInfo=^TGateInfo;

var
  GateInfo:array[TGateType]of TGateInfo; //->InitGateInfo

var clConst,clDirty,clSelected,clTitle:tcolor;

type
  TGatePos=TV2i;

const
  gtLast=High(TGateType);

type
  TWire=class;

  TGate=class(THetObject)
  private
    F_Pos:integer;
    FConstant,FDirtyMask:Cardinal;
  private
    Work,Reference,DiffAccum:TSSEReg;//xmm aligned
  private
    FTyp:TGateType;
    FRegName: ansistring;
    function GetPos: TV2i;
    procedure Set_Pos(const Value: integer);
//    procedure SetId(const Value: integer);
    procedure SetPos(const Value: TV2i);
    procedure SetTyp(const Value: TGateType);
    function GetPosX: integer;
    function GetPosY: integer;
    function GetIsInput: boolean;
    procedure SetConstant(const Value: Cardinal);
    procedure SetDirtyMask(const Value: Cardinal);
    function GetValue: cardinal;
    function GetDirty: cardinal;
    function GetIsDirty: boolean;
    procedure SetRegName(const Value: ansistring);
  public
    sel,calced:ByteBool;
    FCalcOrder:integer;
    AlternateGate:TGate;//for optimize
    allocatedReg:integer;//for amd_il
    destructor Destroy;override;
    function SrcWires:TArray<TWire>;
    function DstWires:TArray<TWire>;
    function SrcGates:TArray<TGate>;
    function DstGates:TArray<TGate>;
    function InRect(const r:TRect):boolean;
    property Pos:TV2i read GetPos write SetPos stored false;
    function IsAllDstCalced(const AExcept:TGate=nil):boolean;
    function IsAllSrcCalced: boolean;
    function Info:PGateInfo;
    procedure Calculate;//recalculate Value
  published
//    property ID:integer read FID write SetId;
    property _Pos:integer read F_Pos write Set_Pos;
    property Typ:TGateType read FTyp write SetTyp;
    property PosX:integer read GetPosX stored false;
    property PosY:integer read GetPosY stored false;
    property IsInput:boolean read GetIsInput;
    property Constant:Cardinal read FConstant write SetConstant stored GetIsInput;
    property DirtyMask:Cardinal read FDirtyMask write SetDirtyMask stored GetIsInput;
    property RegName:ansistring read FRegName write SetRegName;
    property Value:cardinal read GetValue stored false;
    property Dirty:cardinal read GetDirty stored false;
    property IsDirty:boolean read GetIsDirty stored false;
    property CalcOrder:integer read FCalcOrder stored false;//1 based
  private
    //sse calc
    //16byte align here!
    procedure _StoreWork_CompareReference;
    procedure _GenerateRandomInput_xmm0;
    procedure _GenerateInput_xmm0;
  end;

  TGates=class(THetList<TGate>)
  public
    function ByPos(const APos:TV2i):TGate;
    property ByIndex;default;
  end;

  TWire=class(THetObject)
  private
    FSrc,FDst:TGate;
    procedure SetDst(const Value: TGate);
    procedure SetSrc(const Value: TGate);
  public
    function getLookupList(const PropInfo:PPropInfo):THetObjectList;override;
  published
    property Src:TGate read FSrc write SetSrc;
    property Dst:TGate read FDst write SetDst;
  end;

  TWires=class(THetList<TWire>)
  public
    property ByIndex;default;
  end;

  TSelectOperation=(soAdd,soRemove,soToggle);


  TCircuitStats=record
    SelectedGateCount,SelectedActiveGateCount,
    SelectedConstCount,SelectedActiveConstCount,
    TempRegCnt, {isa vreg}
    TempSRegCnt:integer;
  end;

  TCircuit=class(THetObject)
  private
    FName:AnsiString;
    FGates:TGates;
    FWires:TWires;
    procedure SetName(const Value: AnsiString);
  private
    function CompileSSE:AnsiString;
    procedure RunSSE(const prg:AnsiString;const ADirty:boolean);
  public
    Changed:boolean;
    Stats:TCircuitStats;
    procedure ObjectChanged(const AObj:THetObject;const AChangeType:TChangeType);override;

    procedure Clear;
    function Bounds:TRect;
    procedure GlDraw(const AViewer:TGLViewer;const ASelTrans:TV2f;const AClone: boolean);
    procedure GlDrawTexts(const AViewer: TGLViewer);
    procedure Simulate;
    procedure OptimizeRedundancy;
    procedure OptimizeCommutative;
    procedure OptimizeConstantCalculations;
    procedure Optimize;
    function GateAt(const APos:TGatePos):TGate;
    procedure UpdateStats;
    procedure SelectAll;
    procedure SelectNone;
    procedure UpdateSelection(const APos:TGatePos;const AOperation:TSelectOperation);overload;
    procedure UpdateSelection(const ARect:TRect;const AOperation:TSelectOperation);overload;

    procedure DeleteWiresAt(const APos: TGatePos);
    function CanTranslateSelected(const ADelta: TGatePos;const AClone:boolean):boolean;
    function TranslateSelected(const ADelta: TGatePos;const AClone:boolean):boolean;
    procedure DeleteSelected;
    procedure AddWire(const AStart,AEnd:TGatePos);
    function AddGate(const APos:TGatePos;const ATyp:TGateType):TGate;
    procedure SelectSourcePath(DirtyOnly:Boolean);
    procedure CropSelected;
    function PosSelected(const APos: TGatePos): boolean;
    function CompileAMD_IL(const TempRegBase:integer;const PullOrder:ansistring):ansistring;
    function CompileAMD_ISA(const TempVRegBase,TempSRegBase,TempVRegExtra,TempSRegExtra:integer;Const PullOrder:ansistring):ansistring;

  published
    property Name:AnsiString read FName write SetName;
    property Gates:TGates read FGates;
    property Wires:TWires read FWires;
  end;

{  TCircuitCache=class(TGenericHetObjectList<TCircuit>)
  public
    function GetByNameCached(const AName:ansistring):THetObject;override;
    property ByName;default;
  end;

const CircuitCache:TCircuitCache=nil;}

function GatePosCmp(const a,b:TGatePos):integer;
procedure glWireColor(const dirty:boolean);
procedure MakeGateTexture;
procedure MakeWireTexture(const phase:single);

implementation

procedure InitGateInfo;

  procedure a(t:TGateType;AName:AnsiString;AInCnt:integer;AShape:TGateShape;Aflags:TGateFlags;AILCode,AISACode,ASSECode:ansistring);
  begin
    with GateInfo[t]do begin
      name:=AName; inCnt:=AInCnt; shape:=AShape; flags:=Aflags;
      ilCode:=AILCode;
      isaCode:=AISACode;
      if ASSECode<>'' then begin
        if charn(ASSECode,1)=#0 then sseCode:=copy(ASSECode,2)
                                else sseCode:=AsmCompile(ASSECode)
      end else
        sseCode:='';
    end;
  end;

begin
//---specials
  a(gtInput     ,'input'        ,0,shSquare     ,[gtPassive]                    ,''                     ,''                     ,'');
  a(gtMov       ,'mov'          ,1,shDot        ,[gtPassive]                    ,'mov d,s0'             ,'v_mov_b32 d,s0'       ,''{movaps xmm0,xmm0});
//---int32 math
  a(gtINot      ,'inot'         ,1,shRound      ,[]                             ,'inot d,s0'            ,'!'                     ,'pcmpeqb xmm1,xmm1;pxor xmm0,xmm1');
  a(gtIOr       ,'ior'          ,2,shRound      ,[gfCommutative]                ,'ior d,s0,s1'          ,'!'                     ,'por xmm0,xmm1');
  a(gtIAnd      ,'iand'         ,2,shRound      ,[gfCommutative]                ,'iand d,s0,s1'         ,'v_and_b32 d,s0,s1'     ,'pand xmm0,xmm1');
  a(gtIXor      ,'ixor'         ,2,shRound      ,[gfCommutative]                ,'ixor d,s0,s1'         ,'v_xor_b32 d,s0,s1'     ,'pxor xmm0,xmm1');
  a(gtIEq       ,'ieq'          ,2,shRound      ,[gfCommutative]                ,'ieq d,s0,s1'          ,'!'                     ,'pcmpeqd xmm0,xmm1');
  a(gtIAdd      ,'iadd'         ,2,shRound      ,[gfCommutative]                ,'iadd d,s0,s1'         ,'v_add_i32 d,vcc,s0,s1' ,'paddd xmm0,xmm1');
  a(gtISub      ,'isub'         ,2,shRound      ,[]                             ,'inegate d,s1'#13#10'iadd d,s0,d' ,'!'          ,'psubd xmm0,xmm1');
  a(gtRol1      ,'rol1'         ,1,shRound      ,[]                             ,'bitalign d,s0,s0,31'  ,'v_alignbit_b32 d,s0,s0,31','movdqa xmm1,xmm0;pslld xmm0,1;psrld xmm1,31;por xmm0,xmm1');
  a(gtRol2      ,'rol2'         ,1,shRound      ,[]                             ,'bitalign d,s0,s0,30'  ,'v_alignbit_b32 d,s0,s0,30','movdqa xmm1,xmm0;pslld xmm0,2;psrld xmm1,30;por xmm0,xmm1');
  a(gtRol4      ,'rol4'         ,1,shRound      ,[]                             ,'bitalign d,s0,s0,28'  ,'v_alignbit_b32 d,s0,s0,28','movdqa xmm1,xmm0;pslld xmm0,4;psrld xmm1,28;por xmm0,xmm1');
  a(gtRol5      ,'rol5'         ,1,shRound      ,[]                             ,'bitalign d,s0,s0,27'  ,'v_alignbit_b32 d,s0,s0,27','movdqa xmm1,xmm0;pslld xmm0,5;psrld xmm1,27;por xmm0,xmm1');
  a(gtRol30     ,'rol7'         ,1,shRound      ,[]                             ,'bitalign d,s0,s0,25'  ,'v_alignbit_b32 d,s0,s0,25','movdqa xmm1,xmm0;pslld xmm0,7;psrld xmm1,25;por xmm0,xmm1');
  a(gtRol30     ,'rol9'         ,1,shRound      ,[]                             ,'bitalign d,s0,s0,23'  ,'v_alignbit_b32 d,s0,s0,23','movdqa xmm1,xmm0;pslld xmm0,9;psrld xmm1,23;por xmm0,xmm1');
  a(gtRol30     ,'rol13'        ,1,shRound      ,[]                             ,'bitalign d,s0,s0,19'  ,'v_alignbit_b32 d,s0,s0,19','movdqa xmm1,xmm0;pslld xmm0,13;psrld xmm1,19;por xmm0,xmm1');
  a(gtRol30     ,'rol18'        ,1,shRound      ,[]                             ,'bitalign d,s0,s0,14'  ,'v_alignbit_b32 d,s0,s0,14','movdqa xmm1,xmm0;pslld xmm0,18;psrld xmm1,14;por xmm0,xmm1');
  a(gtRol30     ,'rol30'        ,1,shRound      ,[]                             ,'bitalign d,s0,s0,2'   ,'v_alignbit_b32 d,s0,s0,2','movdqa xmm1,xmm0;pslld xmm0,30;psrld xmm1,2;por xmm0,xmm1');
  a(gtVectSel   ,'vs'           ,3,shRound      ,[]                             ,'vec_sel d,s0,s1,s2'   ,'v_bfi_b32 d,s2,s1,s0'  ,'pand xmm1,xmm2;pandn xmm2,xmm0;por xmm1,xmm2;movdqa xmm0,xmm1');
  a(gtUMin3     ,'umin3'        ,3,shRound      ,[gfCommutative]                ,'umin3 d,s0,s1,s2'     ,'!'                     ,'pminud xmm1,xmm2;pminud xmm0,xmm1');
  a(gtUMin      ,'umin'         ,2,shRound      ,[gfCommutative]                ,'umin d,s0,s1'         ,'!'                     ,'pminud xmm0,xmm1');
//---int32 S alu
  a(gtS_not    ,'s_not'         ,2,shRndRect    ,[]                             ,'!'                    ,'s_not_b32 d,s0'        ,'pcmpeqd xmm2,xmm1;pxor xmm0,xmm1');
  a(gtS_xor    ,'s_xor'         ,2,shRndRect    ,[gfCommutative]                ,'!'                    ,'s_xor_b32 d,s0,s1'     ,'pxor xmm0,xmm1');
  a(gtS_and    ,'s_and'         ,2,shRndRect    ,[gfCommutative]                ,'!'                    ,'s_and_b32 d,s0,s1'     ,'pand xmm0,xmm1');
  a(gtS_or     ,'s_or'          ,2,shRndRect    ,[gfCommutative]                ,'!'                    ,'s_or_b32 d,s0,s1'      ,'por xmm0,xmm1');
  a(gtS_andn2  ,'s_andn2'       ,2,shRndRect    ,[]                             ,'!'                    ,'s_andn2_b32 d,s0,s1'   ,'pcmpeqd xmm2,xmm2;pxor xmm1,xmm2;pand xmm0,xmm1');
  a(gtS_iadd   ,'s_iadd'        ,2,shRndRect    ,[gfCommutative]                ,'!'                    ,'s_add_i32 d,s0,s1'     ,'paddd xmm0,xmm1');
  a(gtS_isub   ,'s_isub'        ,2,shRndRect    ,[gfCommutative]                ,'!'                    ,'s_sub_i32 d,s0,s1'     ,'psubd xmm0,xmm1');
  a(gtS_ushr   ,'s_ushr'        ,2,shRndRect    ,[]                             ,'!'                    ,'s_lshr_b32 d,s0,s1'    ,#0#$51#$0F#$11#$44#$24#$F0#$0F#$11#$4C#$24#$E0#$8B#$4C#$24#$E0#$D3#$6C#$24#$F0#$8B#$4C#$24#$E4#$D3#$6C#$24#$F4#$8B#$4C#$24#$E8#$D3#$6C#$24#$F8#$8B#$4C#$24#$EC#$D3#$6C#$24#$FC#$0F#$10#$44#$24#$F0#$59);
  a(gtS_ishl   ,'s_ishl'        ,2,shRndRect    ,[]                             ,'!'                    ,'s_lshl_b32 d,s0,s1'    ,#0#$51#$0F#$11#$44#$24#$F0#$0F#$11#$4C#$24#$E0#$8B#$4C#$24#$E0#$D3#$64#$24#$F0#$8B#$4C#$24#$E4#$D3#$64#$24#$F4#$8B#$4C#$24#$E8#$D3#$64#$24#$F8#$8B#$4C#$24#$EC#$D3#$64#$24#$FC#$0F#$10#$44#$24#$F0#$59);
  a(gtS_ishr   ,'s_ishr'        ,2,shRndRect    ,[]                             ,'!'                    ,'s_ashr_b32 d,s0,s1'    ,#0#$51#$0F#$11#$44#$24#$F0#$0F#$11#$4C#$24#$E0#$8B#$4C#$24#$E0#$D3#$7C#$24#$F0#$8B#$4C#$24#$E4#$D3#$7C#$24#$F4#$8B#$4C#$24#$E8#$D3#$7C#$24#$F8#$8B#$4C#$24#$EC#$D3#$7C#$24#$FC#$0F#$10#$44#$24#$F0#$59);
//---New stuff for mandel2
  a(gtUShr     ,'ushr'          ,2,shRndRect    ,[]                             ,'!'                    ,'v_lshrrev_b32 d,s1,s0' ,#0#$51#$0F#$11#$44#$24#$F0#$0F#$11#$4C#$24#$E0#$8B#$4C#$24#$E0#$D3#$6C#$24#$F0#$8B#$4C#$24#$E4#$D3#$6C#$24#$F4#$8B#$4C#$24#$E8#$D3#$6C#$24#$F8#$8B#$4C#$24#$EC#$D3#$6C#$24#$FC#$0F#$10#$44#$24#$F0#$59);
  a(gtIShl     ,'ishl'          ,2,shRndRect    ,[]                             ,'!'                    ,'v_lshlrev_b32 d,s1,s0' ,#0#$51#$0F#$11#$44#$24#$F0#$0F#$11#$4C#$24#$E0#$8B#$4C#$24#$E0#$D3#$64#$24#$F0#$8B#$4C#$24#$E4#$D3#$64#$24#$F4#$8B#$4C#$24#$E8#$D3#$64#$24#$F8#$8B#$4C#$24#$EC#$D3#$64#$24#$FC#$0F#$10#$44#$24#$F0#$59);
  a(gtIShr     ,'ishr'          ,2,shRndRect    ,[]                             ,'!'                    ,'v_ashrrev_b32 d,s1,s0' ,#0#$51#$0F#$11#$44#$24#$F0#$0F#$11#$4C#$24#$E0#$8B#$4C#$24#$E0#$D3#$7C#$24#$F0#$8B#$4C#$24#$E4#$D3#$7C#$24#$F4#$8B#$4C#$24#$E8#$D3#$7C#$24#$F8#$8B#$4C#$24#$EC#$D3#$7C#$24#$FC#$0F#$10#$44#$24#$F0#$59);
  a(gtBitalign ,'bital'         ,3,shRound      ,[]                             ,'bitalign d,s0,s1,s2'  ,'v_alignbit_b32 d,s0,s1,s2',#0#$50#$53#$51#$0F#$11#$44#$24#$F0#$0F#$11#$4C#$24#$E0#$0F#$11#$54#$24#$D0#$8B#$44#$24#$F0#$8B#$5C#$24#$E0#$8A#$4C#$24#$D0#$D3#$E8#$F6#$D9#$80#$C1#$20#$D3#$E3#$09#$D8#$89#$44#$24#$F0#$8B#$44#$24#$F4#$8B#$5C#$24#$E4#$8A#$4C#$24#$D4#$D3#$E8#$F6#$D9#$80#$C1#$20#$D3#$E3#$09#$D8#$89#$44#$24#$F4#$8B#$44#$24#$F8#$8B#$5C#$24#$E8#$8A#$4C#$24#$D8#$D3#$E8#$F6#$D9#$80#$C1#$20#$D3#$E3#$09#$D8#$89#$44#$24#$F8#$8B#$44#$24#$FC#$8B#$5C#$24#$EC#$8A#$4C#$24#$DC#$D3#$E8#$F6#$D9#$80#$C1#$20#$D3#$E3#$09#$D8#$89#$44#$24#$FC#$0F#$10#$44#$24#$F0#$59#$5B#$58);

  if SSEVersion<SSE4_1 then begin //Athlon2 kiakad a pminud-tol -> fake it!
    GateInfo[gtUMin3].sseCode:=AsmCompile('psubd xmm1,xmm2;psubd xmm0,xmm1');
    GateInfo[gtUMin].sseCode:=AsmCompile('psubd xmm0,xmm1');
  end;
end;


function GatePosCmp(const a,b:TGatePos):integer;
begin
  if int64(a)>int64(b)then result:=1 else
  if int64(a)=int64(b)then result:=0 else
                           result:=-1;
end;

procedure glWireColor;
begin
  if Dirty then glColor3(clDirty)
           else glColor3(clConst);
end;

procedure MakeGateTexture;
const siz=512;
var b:TBitmap;
    xofs:integer;

  procedure a(shape:TGateShape;text:string);
  var r:trect;
  begin with b.Canvas do begin
    Brush.Style:=bsSolid;
    r:=rect(xofs,0,xofs+siz,siz);
    case shape of
      shSquare:begin Fillrect(r) end;
      shRound:with r do begin Ellipse(Left,Top,Right,Bottom)end;
      shRndRect:with r do begin RoundRect(Left,Top,Right,Bottom,(Right-Left)div 3,(Bottom-Top)div 3);end;
      shDot:with r do begin InflateRect(r,-siz div 3,-siz div 3);Ellipse(Left,Top,Right,Bottom);end;
    end;

{   if shape=1 then Font.Color:=clSelected;}

    Brush.Style:=bsClear;
    with TextExtent(text)do
      TextOut((r.Right+r.Left-cx)div 2,(r.Bottom+r.Top-cy*2)div 2,text);

    inc(xofs,siz);
  end;end;

var t:TGateType;
begin
  b:=TBitmap.CreateNew(pf32bit,siz*16,siz);
  with b,Canvas do begin
    SetBrush(bsSolid,clFuchsia);FillRect(rect(0,0,width,height));
    SetBrush(bsSolid,clWhite);
    with font do begin Name:='Tahoma';Size:=18*siz div 64;Style:=[fsBold];Color:=clGray end;
    Pen.Style:=psClear;
  end;

  xofs:=0;
  for t:=low(TGateType)to high(TGateType)do with GateInfo[t]do a(shape,name);

  b.PixelOp1(function(a:cardinal):cardinal begin if a=$ff00ff then result:=$FFFFFF else result:=a or $ff000000 end);

  b.Components:=2;
  TextureCache['gates'].LoadFromBitmap(b,mtColor_LA,atGradient,true,false);

  b.Free;
end;

procedure MakeWireTexture(const phase:single);
var b:TBitmap;i:integer;
begin
  b:=TBitmap.CreateNew(pf8bit,32,1);
  for i:=0 to b.Width-1 do b.Pix[i,0]:=round(95*sin((i/32+Phase)*pi*2*3)+128+32);
  TextureCache['wire'].LoadFromBitmap(b,mtColor_L,atGradient,True,False);
  b.Free;
end;

{ TGate }

{$O-}
//procedure TGate.SetId(const Value: integer);begin end;
procedure TGate.SetTyp(const Value: TGateType);begin end;
procedure TGate.Set_Pos(const Value: integer);begin end;
procedure TGate.SetConstant(const Value: Cardinal);begin end;
procedure TGate.SetDirtyMask(const Value: Cardinal);begin end;
procedure TGate.SetRegName(const Value: ansistring);begin end;
{$O+}

type tv2si=array[0..1]of smallint;

function TGate.GetPos: TV2i;
begin
  result.x:=TV2si(F_Pos)[0];
  result.y:=TV2si(F_Pos)[1];
end;

function TGate.GetIsInput: boolean;
begin
  result:=Typ=gtInput;
end;

function TGate.GetPosX: integer;
begin
  result:=tv2si(F_Pos)[0];
end;

function TGate.GetPosY: integer;
begin
  result:=tv2si(F_Pos)[1];
end;

function TGate.GetValue: cardinal;
begin
  result:=Reference.DW[0];
end;

function TGate.GetDirty: cardinal;
begin
  with DiffAccum do
    result:=DW[0];
end;

function TGate.GetIsDirty: boolean;
begin
  with DiffAccum do
    result:=DW[0]<>0;
end;

function TGate.Info: PGateInfo;
begin
  result:=@GateInfo[Typ];
end;

function TGate.InRect(const r: TRect): boolean;
begin
  with r,Pos do result:=Inrange(x,Left,Right)and InRange(y,Top,Bottom);
end;

function TGate.IsAllDstCalced(const AExcept:TGate=nil): boolean;
var g:TGate;
begin
  for g in DstGates do if(not g.calced)and(AExcept<>g)then exit(false);
  result:=true;
end;

function TGate.IsAllSrcCalced: boolean;
var g:TGate;
begin
  for g in SrcGates do if not g.calced then exit(false);
  result:=true;
end;

procedure TGate.SetPos(const Value: TV2i);
begin
  _Pos:=Value.x and $ffff+Value.y shl 16;
end;

function TGate.SrcWires:TArray<TWire>;
var res:THetArray<TWire>;
    o:THetObject;
begin
  for o in FReferences do if(o is TWire)and(TWire(o).Dst=self)then
    res.Append(TWire(o));
  res.Compact; result:=res.FItems;
end;

function TGate.DstWires:TArray<TWire>;
var res:THetArray<TWire>;
    o:THetObject;
begin
  for o in FReferences do if(o is TWire)and(TWire(o).Src=self)then
    res.Append(TWire(o));
  res.Compact; result:=res.FItems;
end;

function TGate.SrcGates:TArray<TGate>;
var res:THetArray<TGate>;
    o:THetObject;
begin
  for o in FReferences do if(o is TWire)and(TWire(o).Dst=self)and(TWire(o).Src<>nil)then
    res.Append(TWire(o).Src);
  res.Compact; result:=res.FItems;
end;

function TGate.DstGates:TArray<TGate>;
var res:THetArray<TGate>;
    o:THetObject;
begin
  for o in FReferences do if(o is TWire)and(TWire(o).Src=self)and(TWire(o).Dst<>nil)then
    res.Append(TWire(o).Dst);
  res.Compact; result:=res.FItems;
end;

procedure WriteXmmInt(n,value:integer);
begin
  case n of
    0:asm movd xmm0,value;pshufd xmm0,xmm0,0 end;
    1:asm movd xmm1,value;pshufd xmm1,xmm1,0 end;
    2:asm movd xmm2,value;pshufd xmm2,xmm2,0 end;
    3:asm movd xmm3,value;pshufd xmm3,xmm3,0 end;
    4:asm movd xmm4,value;pshufd xmm4,xmm4,0 end;
    5:asm movd xmm5,value;pshufd xmm5,xmm5,0 end;
    6:asm movd xmm6,value;pshufd xmm6,xmm6,0 end;
    7:asm movd xmm7,value;pshufd xmm7,xmm7,0 end;
  end;
end;

{procedure shl_xmm0_xmm1;
asm
  push ecx
  movups [esp-$10],xmm0
  movups [esp-$20],xmm1
  mov ecx,[esp-$20]; shl [esp-$10],cl
  mov ecx,[esp-$1C]; shl [esp-$0C],cl
  mov ecx,[esp-$18]; shl [esp-$08],cl
  mov ecx,[esp-$14]; shl [esp-$04],cl
  movups xmm0,[esp-$10]
  pop ecx
end;

procedure shr_xmm0_xmm1;
asm
  push ecx
  movups [esp-$10],xmm0
  movups [esp-$20],xmm1
  mov ecx,[esp-$20]; shr [esp-$10],cl
  mov ecx,[esp-$1C]; shr [esp-$0C],cl
  mov ecx,[esp-$18]; shr [esp-$08],cl
  mov ecx,[esp-$14]; shr [esp-$04],cl
  movups xmm0,[esp-$10]
  pop ecx
end;                   }

{procedure bitalign_xmm0_xmm1_xmm2;
asm
  push eax push ebx push ecx
  movups [esp-$10],xmm0
  movups [esp-$20],xmm1
  movups [esp-$30],xmm2
  mov eax,[esp-$10]; mov ebx,[esp-$20]; mov cl,[esp-$30]; shr eax,cl; neg cl; add cl,32; shl ebx,cl; or eax,ebx; mov [esp-$10],eax
  mov eax,[esp-$0c]; mov ebx,[esp-$1c]; mov cl,[esp-$2c]; shr eax,cl; neg cl; add cl,32; shl ebx,cl; or eax,ebx; mov [esp-$0c],eax
  mov eax,[esp-$08]; mov ebx,[esp-$18]; mov cl,[esp-$28]; shr eax,cl; neg cl; add cl,32; shl ebx,cl; or eax,ebx; mov [esp-$08],eax
  mov eax,[esp-$04]; mov ebx,[esp-$14]; mov cl,[esp-$24]; shr eax,cl; neg cl; add cl,32; shl ebx,cl; or eax,ebx; mov [esp-$04],eax
  movups xmm0,[esp-$10]
  pop ecx pop ebx pop eax
end;}

procedure TGate.Calculate;
var code:ansistring;
    sg:TArray<TGate>;
    i:integer;
    res:TSSEReg;
begin
  if Typ=gtInput then begin
    Reference.DW[0]:=FConstant;
  end else begin
    code:=GateInfo[typ].sseCode+#$C3{ret};
    sg:=SrcGates;
    for i:=0 to high(sg)do WriteXmmInt(i,sg[i].value);
    asm mov eax,code;call eax;movups res,xmm0 end;
    Reference:=res;
  end;
end;

destructor TGate.Destroy;
var w:TWire;
begin
  for w in SrcWires do w.Free;
  for w in DstWires do w.Free;

  inherited;
end;

{ TGates }

function TGates.ByPos(const APos: TV2i): TGate;
var p:integer;
begin
  TV2Si(p)[0]:=APos.x;
  TV2Si(p)[1]:=APos.y;
  result:=TGate(FindBinary('_pos',[p]));
end;

{ TWire }

{$O-}
procedure TWire.SetDst(const Value: TGate);begin end;
procedure TWire.SetSrc(const Value: TGate);begin end;
{$O+}

function TWire.getLookupList(const PropInfo: PPropInfo): THetObjectList;
begin
  result:=TCircuit(FOwner.FOwner).Gates;
end;

{ TCircuit }

{$O-}
procedure TCircuit.SetName(const Value: AnsiString);begin end;
{$O+}

procedure TCircuit.Clear;
begin
  inherited;
  Wires.Clear;
  Gates.Clear;
end;

function TCircuit.GateAt(const APos: TGatePos):TGate;
begin
  Result:=Gates.ByPos(APos);
end;

procedure TCircuit.ObjectChanged(const AObj: THetObject;const AChangeType: TChangeType);
begin
  Changed:=true;
end;

procedure TCircuit.UpdateSelection(const ARect: TRect;const AOperation: TSelectOperation);
var i:integer;
begin
  for i:=0 to Gates.Count-1 do with Gates.ByIndex[i]do
    if InRect(ARect)then
      case AOperation of
        soAdd:sel:=true;
        soRemove:sel:=false;
        soToggle:sel:=not sel;
      end;
end;

procedure TCircuit.UpdateSelection(const APos: TGatePos;const AOperation: TSelectOperation);
var g:TGate;
begin
  g:=GateAt(APos);if g=nil then exit;
  with g do case AOperation of
    soAdd:sel:=true;
    soRemove:sel:=false;
    soToggle:sel:=not sel;
  end;
  NotifyChange;
end;

procedure TCircuit.AddWire(const AStart, AEnd: TGatePos);
var gSrc,gDst:TGate;
    w:TWire;
begin
  if AStart=AEnd then exit;
  gSrc:=GateAt(AStart);if gSrc=nil then gSrc:=AddGate(AStart,gtMov);
  gDst:=GateAt(AEnd  );if gDst=nil then gDst:=AddGate(AEnd  ,gtMov);

  for w in gSrc.DstWires do if w.Dst=gDst then exit;//eleve letezik
  for w in gDst.DstWires do if w.Dst=gSrc then w.Free;//rossz iranyban all, delete

  w:=TWire.Create(Wires);
  w.Src:=gSrc;
  w.Dst:=gDst;
end;

function TCircuit.Bounds: TRect;
begin with result do begin
  if Gates.Count=0 then exit(rect(0,0,-1,-1));
  with Gates.View['PosX']do begin
    Left:=ByIndex[0].PosX;
    Right:=ByIndex[Count-1].PosX;
  end;
  with Gates.View['PosY']do begin
    Top:=ByIndex[0].PosY;
    Bottom:=ByIndex[Count-1].PosY;
  end;
end;end;

procedure TGate._StoreWork_CompareReference;
asm
  movdqa self.Work,xmm0
  //pcmpeqd xmm0,self.Reference
  pxor xmm0,self.Reference

  por xmm0,self.DiffAccum
  movdqa self.DiffAccum,xmm0
end;

procedure _randomxmm0;
asm
  push eax push edx push ecx
  mov eax,$10000;call random;pinsrw xmm0,eax,0 //kinda lame...
  mov eax,$10000;call random;pinsrw xmm0,eax,1
  mov eax,$10000;call random;pinsrw xmm0,eax,2
  mov eax,$10000;call random;pinsrw xmm0,eax,3
  mov eax,$10000;call random;pinsrw xmm0,eax,4
  mov eax,$10000;call random;pinsrw xmm0,eax,5
  mov eax,$10000;call random;pinsrw xmm0,eax,6
  mov eax,$10000;call random;pinsrw xmm0,eax,7
  pop ecx pop edx pop eax
end;

//destroys xmm3,xmm4
procedure TGate._GenerateRandomInput_xmm0;
asm
  push esi push edi
  cmp self.FDirtyMask,0
  je @@1
    call _randomxmm0
    movd xmm3,self.FDirtyMask  pshufd xmm3,xmm3,0  pand xmm0,xmm3  //rnd and mask
    movd xmm4,self.FConstant   pshufd xmm4,xmm4,0  pandn xmm3,xmm4 //not mask and const
    por xmm0,xmm3
    jmp @@2
  @@1:
    movd xmm0,self.FConstant   pshufd xmm0,xmm0,0
  @@2:
  pop edi pop esi
end;

procedure TGate._GenerateInput_xmm0;
asm
  movd xmm0,self.FConstant   pshufd xmm0,xmm0,0
end;

procedure _generatePrg(ActG:TGate;const sb:IAnsiStringBuilder);
  procedure error(const s:ansistring);
  begin
    raise Exception.CreateFmt('_generatePrg(%s) %s',[GateInfo[ActG.Typ].name,s]);
  end;

  function addrStr(data:pointer):ansistring;
  begin
    setlength(result,4);
    pcardinal(result)^:=cardinal(data);
  end;

var SrcNeeded:integer;
    SrcGates:TArray<TGate>;
    i:integer;
    g:TGate;

begin
  if ActG.calced then exit;

  //can calculate?
  SrcNeeded:=GateInfo[ActG.Typ].inCnt;
  if SrcNeeded>0 then
    Srcgates:=ActG.SrcGates;

  case sign(length(SrcGates)-SrcNeeded)of
    1:error('Too many src wires');
    -1:error('Not enough src wires');
  end;

  if not ActG.IsAllSrcCalced then exit;

  //Generate code

  //1. fetch
  for i:=0 to SrcNeeded-1 do
    sb.AddStr(#$66#$0F#$6F+ansichar(5+8*i){r/m}+addrStr(@SrcGates[i].Work)); //movdqa xmm0,[const]
  //2. operate
  case ActG.Typ of
    gtInput:sb.AddStr(#$B8+addrstr(ActG)+#$FF#$D1);//mov eax,self;call ecx
  else
    sb.AddStr(GateInfo[ActG.typ].sseCode);
  end;
  //3. store
  sb.AddStr(#$B8+addrstr(ActG)+#$FF#$D2);//mov eax,self; call edx

  ActG.calced:=true;

  //recursive calls
  for g in ActG.DstGates do
    _generatePrg(g,sb);
end;

function TCircuit.CompileSSE:ansistring;
var g:TGate;
    sb:IAnsiStringBuilder;
begin
  for g in Gates do g.Calced:=false;

  sb:=AnsiStringBuilder(result,true);
  for g in gates do if g.Typ=gtInput then
    _generatePrg(g,sb);

  sb.AddStr(#$C3);//ret
end;

procedure TCircuit.CropSelected;
var del:THetArray<TGate>;
    g:TGate;
begin
  for g in Gates do if not g.sel then del.Append(g);
  for g in del do
    g.Free;
end;

procedure TCircuit.RunSSE(const prg:AnsiString;const ADirty:boolean);
begin
  if ADirty then asm
    lea ecx,TGate._GenerateRandomInput_xmm0;
    lea edx,TGate._StoreWork_CompareReference;
    call prg;
  end else asm
    lea ecx,TGate._GenerateInput_xmm0;
    lea edx,TGate._StoreWork_CompareReference;
    call prg;
  end;
end;

procedure TCircuit.Simulate;
var i,rndCnt:integer;
    prg:ansistring;
    g:TGate;
begin
  rndCnt:=512;//ezt valahol majd meg kene adni {jelenleg 4*rndCnt iteracio}

  prg:=CompileSSE;

  //reference run
  RunSSE(prg,false);

  for g in gates do with g do begin
    Reference:=Work;
    DiffAccum.SetDW(0);
  end;

  //run random tests
  for i:=1 to rndCnt do RunSSE(prg,true);

  //ger dirty results
  for g in gates do with g.DiffAccum do DW[0]:=DW[0]or DW[1]or DW[2]or DW[3];

  NotifyChange;
end;

procedure TCircuit.OptimizeRedundancy;
var i,j:integer;
    prg:AnsiString;
    bits:array of array of TSSEReg;
    h:array of integer;
    orig:TGate;
const cnt=1024;
begin
  prg:=CompileSSE;
  setlength(bits,Gates.Count,cnt);
  for i:=0 to cnt-1 do begin
    if(i and $ff)=0then Application.MainForm.Caption:='optimized clac '+tostr(i);
    RunSSE(prg,True);
    for j:=0 to Gates.Count-1 do
      bits[j,i]:=Gates[j].Work;
  end;

  //calc hash
  SetLength(h,length(bits));
  for i:=0 to high(h)do h[i]:=Crc32(@bits[i,0],cnt*16);

  for i:=0 to High(bits) do begin
    if(i and 1023)=0 then Application.MainForm.Caption:='optimized find '+tostr(i);

    orig:=nil;
    for j:=0 to high(bits)do if h[j]=h[i] then begin
      orig:=Gates[j];
      Break;
    end;

    Gates[i].AlternateGate:=orig;
  end;

  //reroute
  for i:=0 to Wires.Count-1 do with Wires[i] do
    Src:=Src.AlternateGate;

end;

procedure TCircuit.OptimizeCommutative;
{         s1 <-dirty
       \ /              <-can swap s1,s2
       g1  s2 <- const
 one->  \ /
        g2
many-> / \           }
var g1,g2,s1,s2:TGate;w:TWire;
    wasswap:boolean;
begin
  repeat
    wasSwap:=false;
    for g1 in gates do
      if(gfCommutative in GateInfo[g1.Typ].flags)and g1.IsDirty
      and(length(g1.DstGates)=1)and(Length(g1.SrcGates)=2)then begin
        s1:=g1.SrcGates[0];
        if not s1.IsDirty then s1:=g1.SrcGates[1];
        if not s1.IsDirty then Continue;

        g2:=g1.DstGates[0];
        if(g2.Typ=g1.Typ)and(length(g2.SrcGates)=2)then begin
          s2:=g2.SrcGates[0];
          if s2=g1.DstGates[0]then s2:=g2.SrcGates[1];

          if not s2.IsDirty then begin //can swap s1,s2
            wasSwap:=true;
            for w in g2.SrcWires do if w.Src=s2 then w.Src:=s1;
            for w in g1.SrcWires do if w.Src=s1 then w.Src:=s2;
          end;

        end;
      end;
  until not wasswap;
end;

procedure TCircuit.OptimizeConstantCalculations;
var g:TGate;w:TWire;
begin
  //solve constant calculations (only after simulate)
  for g in Gates do if(not g.IsDirty)and(g.Typ<>gtInput)then begin
    g.Typ:=gtInput;
    g.DirtyMask:=0;
    g.Constant:=g.Reference.DW[0];

    for w in g.SrcWires do w.Free;
  end;
end;

procedure TCircuit.Optimize;
begin
  Simulate;OptimizeRedundancy;
  SelectSourcePath(false);CropSelected;  //ez csak az aktiv dolgokat jeloli ki rekurzivan
  OptimizeCommutative;Simulate;          //emiatt ez mar tudja rendezni a commutativ chaineket
  OptimizeConstantCalculations;Simulate; //konstanssá alakitja a nemDirty szamitasokat
end;

procedure TCircuit.UpdateStats;
var g:TGate;
begin with Stats do begin
  SelectedGateCount:=0;SelectedActiveGateCount:=0;
  SelectedConstCount:=0;SelectedActiveConstCount:=0;
  for g in gates do with g do if sel then
    if not(gtPassive in GateInfo[Typ].flags)then begin
      inc(SelectedGateCount);
      if IsDirty then
        inc(SelectedActiveGateCount);
    end else if Typ=gtInput then begin
      inc(SelectedConstCount);
      if IsDirty then
        inc(SelectedActiveConstCount);
    end;
end;end;

procedure _Quad(const p:TV2f;typ:TGateType);overload;
var tx0,tx1,n:single;
begin with p do begin
  tx0:=Ord(typ)*(1/16);tx1:=tx0+(1/16);n:=0.35{6};

  glTexCoord2f(tx0,1);glVertex2f(x-n,y-n);
  glTexCoord2f(tx0,0);glVertex2f(x-n,y+n);
  glTexCoord2f(tx1,0);glVertex2f(x+n,y+n);
  glTexCoord2f(tx1,1);glVertex2f(x+n,y-n);
end;end;

procedure _Quad(const p:TV2i;typ:TGateType);overload;
begin
  _Quad(V2f(p.x,p.y),typ);
end;

procedure _Line(const p0,p1:TV2f);
begin
  glTexCoord1f(0);
  with p0 do glVertex2f(x,y);
  glTexCoord1f(VDist(p0,p1));
  with p1 do glVertex2f(x,y);
end;

procedure TCircuit.GlDraw(const AViewer:TGLViewer;const ASelTrans:TV2f;const AClone: boolean);
var i:integer;t:TTexture;
    s0,s1:boolean;
begin
  //2. wires
  t:=TextureCache['wire'];
  t.Bind(0,rfLinearMipmapLinear,False);
  glLineWidth(1);
  glBegin(GL_LINES);
  for i:=0 to Wires.Count-1 do with Wires[i]do begin
    if Src.sel and Dst.sel then glColor3(clSelected)else glWireColor(Src.IsDirty);
    s0:=Src.sel;
    s1:=Dst.sel;
    if AClone then begin
      _line(Src.Pos,Dst.Pos);
      _line(Src.Pos+ASelTrans*ord(s0 and s1),Dst.Pos+ASelTrans*ord(s0 and s1));
    end else begin
      _line(Src.Pos+ASelTrans*ord(s0),Dst.Pos+ASelTrans*ord(s1));
    end;
  end;
  glEnd;
  glLineWidth(1);
  glDisable(GL_TEXTURE_1D);

  //3. blocks
  t:=TextureCache['gates'];
  t.Bind(0,rfLinearMipmapLinear,false);
  glEnable(GL_ALPHA_TEST);glAlphaFunc(GL_GREATER,0);
  glEnable(GL_BLEND);glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);

  glBegin(GL_QUADS);
  for i:=0 to Gates.Count-1 do with Gates[i]do
    if sel then begin
      glColor3f(1,1,1);
      if AClone then
        _Quad(Pos,typ);
      _Quad(Pos+ASelTrans,typ)
    end else begin
      glWireColor(IsDirty);
      _Quad(Pos,typ)
    end;
  glEnd;

  glDisable(GL_TEXTURE_2D);glDisable(GL_ALPHA_TEST);glDisable(GL_BLEND);
end;

function _V2F(const a:TV3f):TV2f;overload;
begin
  result.x:=a.x;
  result.y:=a.y;
end;

procedure TCircuit.GlDrawTexts(const AViewer:TGLViewer);

  procedure txt(const y,color:integer;const s:ansistring);
  begin
    glPushMatrix;
    glTranslatef(0,y,0);
    glColor3(color);
    AViewer.DrawText(s,'CC');
    glPopMatrix;
  end;

var TL,BR:TV2f;
    d:single;
    g:TGate;
begin
  //4. text
  d:=VDist(AViewer.ScreenToWorld(point(0,0)),AViewer.ScreenToWorld(point(1,0)));
  if d>0.04 then exit;

  TL:=_V2F(AViewer.ScreenToWorld(point(0,0)));
  BR:=_V2F(AViewer.ScreenToWorld(point(AViewer.ClientWidth-1,AViewer.ClientHeight-1)));

  sort(TL.x,BR.x);
  sort(TL.y,BR.y);

  for g in gates do with g do if(pos>=TL)and(pos<=BR)then begin
    glPushMatrix;
    with Pos do glTranslatef(x,y,0);
    glScalef(0.18,-0.18,0);

    txt(0,clBlack,IntToHex(Reference.DW[0],8));

    if typ=gtInput then
      txt(-1,clGray,IntToHex(DirtyMask,8));

      txt(-2,clTitle,RegName+' #'+ToStr(calcorder));

    glPopMatrix;
  end;

end;

procedure TCircuit.SelectAll;var i:integer;
begin
  for i:=0 to Gates.Count-1 do Gates[i].sel:=true;
  NotifyChange;
end;

procedure TCircuit.SelectNone;var i:integer;
begin
  for i:=0 to Gates.Count-1 do Gates[i].sel:=false;
  NotifyChange;
end;

function TCircuit.CanTranslateSelected(const ADelta:TGatePos;const AClone:boolean):boolean;
var i,j:integer;
begin
  if ADelta=NullV2i then exit(not AClone);

  for i:=0 to Gates.Count-1 do with Gates[i]do if sel and(typ<>gtMov)then
    for j:=0 to Gates.Count-1 do if not(Gates[j].sel or AClone)and((Gates[j].typ<>gtMov)and(Gates[j].Pos=Pos+ADelta))then
      exit(false);

  result:=true;
end;

function TCircuit.PosSelected(const APos:TGatePos):boolean;
var g:TGate;
begin
  g:=GateAt(APos);
  result:=(g<>nil)and g.sel;
end;

function TCircuit.TranslateSelected(const ADelta:TGatePos;const AClone:boolean):boolean;
var i,j,len:integer;
    t:TGateType;
begin
  result:=CanTranslateSelected(ADelta,AClone);
  if not result then exit;

  if ADelta=NullV2i then exit;

  len:=Gates.Count;
  if AClone then begin
    for i:=0 to len-1 do with gates[i]do if sel then begin
      t:=typ;
      if t=gtMov then
        with gateAt(Pos+ADelta)do if not IsNil then t:=typ;
      AddGate(Pos+ADelta,t);
      for j:=0 to Wires.Count-1 do with Wires[j]do if Src.sel and Dst.Sel then
        AddWire(Src.Pos+ADelta,Dst.Pos+ADelta);
    end;
  end else begin
    for i:=0 to len-1 do with gates[i]do if sel then
      Pos:=Pos+ADelta;
  end;
end;

procedure TCircuit.DeleteWiresAt(const APos:TGatePos);
var i:integer;
begin
  for i:=Wires.Count-1 downto 0 do with Wires[i]do
    if(Src.Pos=APos)or(Dst.Pos=APos)then
      Free;
end;

procedure TCircuit.DeleteSelected;
var i:integer;
begin
  for i:=Gates.Count-1 downto 0 do with gates[i]do if sel then Free;
end;

function TCircuit.AddGate(const APos: TGatePos; const ATyp: TGateType):TGate;
begin
  result:=GateAt(APos);
  if result=nil then
    result:=TGate.Create(gates);

  Result.Pos:=APos;
  Result.Typ:=ATyp;
end;

{ TCircuitCache }

{function TCircuitCache.GetByNameCached(const AName: ansistring): THetObject;
var fn:string;
begin
  fn:=AName+'.circuit';
  if FileExists(fn)then begin
    result:=TCircuit.Create(self);
    result.LoadFromStr(TFile(fn));
    Result.NotifyChange;
  end else begin
    result:=TCircuit.Create(self);
    TCircuit(Result).Name:=AName;
  end;
end;}


procedure _selectDirtySourceGatesIfSelected(g:TGate);
var gs:TGate;
begin
  if not g.sel then exit;
  for gs in g.SrcGates do if not gs.sel and gs.IsDirty then begin
    gs.sel:=true;
    _selectDirtySourceGatesIfSelected(gs);
  end;
end;

procedure _selectAllSourceGatesIfSelected(g:TGate);
var gs:TGate;
begin
  if not g.sel then exit;
  for gs in g.SrcGates do if not gs.sel then begin
    gs.sel:=true;
    _selectAllSourceGatesIfSelected(gs);
  end;
end;

procedure TCircuit.SelectSourcePath(DirtyOnly:boolean);
begin
  if DirtyOnly then Gates.ForEach(_selectDirtySourceGatesIfSelected)
               else Gates.ForEach(_selectAllSourceGatesIfSelected);

  NotifyChange;
end;

type
  TRegPool=record
    map:array[0..1023]of ByteBool;
    cnt,peak:integer;
    procedure clear;
    function alloc:integer;
    procedure free(const regname:integer);
  end;
  PRegPool=^TRegPool;

procedure TRegPool.clear;
begin
  fillchar(self,sizeof(self),0);
end;

function TRegPool.alloc:integer;
var i:integer;
begin
  for i:=0 to high(map)do if not map[i] then begin
    map[i]:=true;
    inc(cnt);peak:=Max(cnt,peak);
    exit(i);
  end;
  raise Exception.Create('TRegPool.alloc: Out of regs');
end;

procedure TRegPool.free(const regname:integer);
begin
  if not inrange(regname,0,high(map))then
    raise Exception.Create('TRegPool.free: Out of range');
  if not map[regname] then
    raise Exception.Create('TRegPool.free: Reg not allocated');
  Dec(cnt);
  map[regname]:=false;
end;

function TCircuit.CompileAMD_IL(const TempRegBase:integer;Const PullOrder:ansistring):ansistring;
  procedure error(const s:ansistring);begin raise Exception.Create('TCircuit.CompileAMD_IL() '+s);end;

  var
    regPool:TRegPool;
    bRegMap:TBitmap;//for debug
    _calcOrderCounter:integer;

  procedure bRegMapDraw;
  begin
    if bRegMap<>nil then
    if _calcOrderCounter<bRegMap.Height then
      move(regpool.map,bRegMap.ScanLine[_calcOrderCounter]^,min(length(regpool.map),bRegMap.Width));
  end;

  function TempRegName(n:integer):ansistring;
  begin
    inc(n,TempregBase);
    result:='r'+tostr(n shr 2)+'.'+'xyzw'[n and 3+1]
  end;

  function CanProcessGate(const ActG:TGate):boolean;
  var g:TGate;
  begin
    result:=false;
    if ActG.calced then exit;//already processed
    for g in ActG.SrcGates do if not g.calced then exit;//can't calculate yet
    result:=true;
  end;

  function ProcessableGates:TArray<TGate>;
  var res:THetArray<TGate>;
      g:TGate;
  begin
    for g in Gates.View[PullOrder]do if CanProcessGate(g)then
      res.Append(g);
    res.Compact; result:=res.FItems;
  end;

  procedure ProcessGate(ActG:TGate);
  var SrcGates:TArray<TGate>;
      g:TGate;
  begin
    ActG.calced:=true;
    inc(_calcOrderCounter);
    ActG.FCalcOrder:=_calcOrderCounter;

    SrcGates:=ActG.SrcGates;

    //early free
    for g in SrcGates do if(g.allocatedReg>=0)and(g.IsAllDstCalced)then begin
      regpool.free(g.allocatedReg); {!}
      g.allocatedReg:=-1;           {!}
      //regname benne marad
    end;

    //allocate reg for exprnode
    if ActG.RegName='' then begin
      //allocate new reg
      ActG.allocatedReg:=regpool.alloc;
      ActG.regname:=TempRegName(ActG.allocatedReg);
    end;
  end;

  procedure Optimize_PullOrder;
  var b:boolean;
      g:TGate;
  begin
    repeat
      b:=false;
      if PullOrder='' then begin
        for g in Gates do if CanProcessGate(g)then begin
          ProcessGate(g);
          Stats.TempRegCnt:=max(Stats.TempRegCnt,regPool.cnt);bRegMapDraw;
          b:=true;break;
        end
      end else begin
        for g in Gates.View[PullOrder]do if CanProcessGate(g)then begin
          ProcessGate(g);
          Stats.TempRegCnt:=max(Stats.TempRegCnt,regPool.cnt);bRegMapDraw;
          b:=true;break;
        end
      end;

      //Application.MainForm.Caption:='optimizing: '+tostr(_calcOrderCounter)+' '+ToStr(stats.TempRegCnt);
    until not b;
  end;

  function GenerateCode:ansistring;
  var g:TGate;
      SrcNeeded:integer;
      SrcGates:TArray<TGate>;
      line:ansistring;
      i:integer;
  begin with AnsiStringBuilder(result,true)do begin
    //error check
    Gates.View['CalcOrder'].RefreshView;
    for g in Gates.View['CalcOrder']do begin
      SrcGates:=g.SrcGates;

      SrcNeeded:=GateInfo[g.Typ].inCnt;
      case sign(length(SrcGates)-SrcNeeded)of
        1:error('Too many src wires');
        -1:error('Not enough src wires');
      end;

      line:=GateInfo[g.Typ].ilCode;
      if line<>'' then begin
        Replace('d',g.RegName,line,[roIgnoreCase,roWholeWords,roAll]);
        for i:=0 to high(SrcGates)do
          Replace('s'+ToStr(i),SrcGates[i].RegName,line,[roIgnoreCase,roWholeWords,roAll]);

        AddLine(line);
      end;
    end;
  end;end;

var g:TGate;
begin
  bRegMap:=TBitmap.CreateNew(pf8bit,128,5000);

  //reset
  stats.TempRegCnt:=0;
  _calcOrderCounter:=0;
  for g in Gates do with g do begin
    allocatedReg:=-1;//clear allocation
    calced:=Typ=gtInput;
    if(Typ=gtInput)and(RegName='')then
      RegName:='$'+inttohex(Value,8); //constant input
    FCalcOrder:=0;
  end;
  regPool.clear;

  Optimize_PullOrder;
  result:=GenerateCode;

  SelectAll;
  UpdateStats;
  with stats do result:=result+
    format(';gates: %d  Active gates: %d'#13#10';constants: %d  ActiveConstants: %d'#13#10';TempRegCnt: %d'#13#10,
           [SelectedGateCount,SelectedActiveGateCount,SelectedConstCount,SelectedActiveConstCount,TempRegCnt]);

  if bRegMap<>nil then begin
    bRegMap.SaveToFile('c:\regmap.bmp');
    FreeAndNil(bRegMap);
  end;
end;

function TCircuit.CompileAMD_ISA(const TempVRegBase,TempSRegBase,TempVRegExtra,TempSRegExtra:integer;Const PullOrder:ansistring):ansistring;

  procedure error(const s:ansistring);begin raise Exception.Create('TCircuit.CompileAMD_IL() '+s);end;

var
  _calcOrderCounter:integer;

var
  VRegPool:TRegPool;
  SRegPool:TRegPool;
  bRegMap:TBitmap;//for debug

  procedure bRegMapDraw;
  var halfw:integer;
      scan:pbyte;
  begin
    if bRegMap<>nil then exit;
    if _calcOrderCounter<bRegMap.Height then begin
      halfw:=bRegMap.Width shr 1;
      scan:=bRegMap.ScanLine[_calcOrderCounter];
      move(vregpool.map,scan^,min(length(vregpool.map),halfw));
      pinc(scan,halfw);
      move(sregpool.map,scan^,min(length(sregpool.map),halfw));
    end;
  end;

  function TempVRegName(n:integer):ansistring; begin result:='v'+tostr(n+TempVRegBase);end;
  function TempSRegName(n:integer):ansistring; begin result:='s'+tostr(n+TempSRegBase);end;

  function IsSReg(g:TGate):boolean;begin result:=iswild2('s_*',GateInfo[g.Typ].isaCode)end;
  function RegPoolOf(g:TGate):PRegPool;begin if IsSReg(g)then result:=@SRegPool else result:=@VRegPool end;

  procedure AllocReg(g:TGate);
  begin
    g.allocatedReg:=RegPoolOf(g).alloc;
    if IsSReg(g)then g.RegName:=TempSRegName(g.allocatedReg)
                else g.RegName:=TempVRegName(g.allocatedReg);
  end;

  function CanProcessGate(const ActG:TGate):boolean;
  var g:TGate;
  begin
    result:=false;
    if ActG.calced then exit;//already processed
    for g in ActG.SrcGates do if not g.calced then exit;//can't calculate yet
    result:=true;
  end;

  function ProcessableGates:TArray<TGate>;
  var res:THetArray<TGate>;
      g:TGate;
  begin
    for g in Gates.View[PullOrder]do if CanProcessGate(g)then
      res.Append(g);
    res.Compact; result:=res.FItems;
  end;

  procedure ProcessGate(ActG:TGate);
  var SrcGates:TArray<TGate>;
      g:TGate;
  begin
    ActG.calced:=true;
    inc(_calcOrderCounter);
    ActG.FCalcOrder:=_calcOrderCounter;

    SrcGates:=ActG.SrcGates;

    //early free
    for g in SrcGates do if(g.allocatedReg>=0)and(g.IsAllDstCalced)then begin
      RegPoolOf(g).free(g.allocatedReg);
      g.allocatedReg:=-1;
      //regname benne marad, az lesz majd kiirva a kodba
    end;

    //allocate reg for exprnode
    if ActG.RegName='' then begin
      //allocate new reg
      AllocReg(ActG);
    end;
  end;

  procedure Optimize_PullOrder;

    procedure UpdateStats;
    begin
      Stats.TempRegCnt :=max(Stats.TempRegCnt ,vregPool.cnt);
      Stats.TempSRegCnt:=max(Stats.TempSRegCnt,sregPool.cnt);
      bRegMapDraw;
    end;

  var b:boolean;
      g:TGate;
  begin
    repeat
      b:=false;
      if PullOrder='' then begin
        for g in Gates do if CanProcessGate(g)then begin
          ProcessGate(g);
          UpdateStats;b:=true;break;
        end
      end else begin
        for g in Gates.View[PullOrder]do if CanProcessGate(g)then begin
          ProcessGate(g);
          UpdateStats;b:=true;break;
        end
      end;

      //Application.MainForm.Caption:='optimizing: '+tostr(_calcOrderCounter)+' '+ToStr(stats.TempRegCnt);
    until not b;
  end;

  procedure PostProcessLine(var line:ansistring);
  var tempVReg,tempSReg:ansistring;

    function a(const wild,repl:ansistring):boolean;
    var parts:TArray<ansistring>;
        i:integer;
    begin
      result:=IsWild2(wild,line,parts);
      if not result then exit;
      line:=repl;
      for i:=0 to high(parts)do
        Replace('%'+tostr(i),parts[i],line,[roAll,roIgnoreCase]);
      Replace('\',#13#10,line,[roAll]);
      Replace('%s',tempSReg,line,[roAll,roIgnoreCase]);
      Replace('%v',tempVReg,line,[roAll,roIgnoreCase]);
    end;
  begin
    tempVReg:='v'+ToStr(TempVRegExtra);
    tempSReg:='s'+ToStr(TempSRegExtra);
        {vop3 opciosok elore jonnek!
        %0..%n  wildcard partok
        %v, %v  vtemp, stemp
        \       newline}
    if a('v_* v*,*,s*,s* vop3','v_mov_b32 %v,s%4\v_%0 v%1,%2,s%3,%v')then exit;
    if a('v_* v*,s*,$* vop3','v_mov_b32 %v,$%3\v_%0 v%1,s%2,%v')then exit;
    if a('v_* v*,v*,$*,$*','v_mov_b32 %v,$%3\s_mov_b32 %s,$%4\v_%0 v%1,v%2,%v,%s')then exit;
    //na ezen még finmitani kell, mert mi van ha a $* az 7bites konstans
    if a('v_* v*,v*,v*,$*','s_mov_b32 %s,$%4\v_%0 v%1,v%2,v%3,%s')then exit;
  end;

  function GenerateCode:ansistring;
  var g:TGate;
      SrcNeeded:integer;
      SrcGates:TArray<TGate>;
      line:ansistring;
      i:integer;
      srcnames:array of ansistring;
  begin with AnsiStringBuilder(result,true)do begin
    //error check
    Gates.View['CalcOrder'].RefreshView;
    for g in Gates.View['CalcOrder']do begin
      SrcGates:=g.SrcGates;

      SrcNeeded:=GateInfo[g.Typ].inCnt;
      case sign(length(SrcGates)-SrcNeeded)of
        1:error('Too many src wires');
        -1:error('Not enough src wires');
      end;

      line:=GateInfo[g.Typ].isaCode;{!!!!!!change}
      if line<>'' then begin
        setlength(SrcNames,length(SrcGates));
        for i:=0 to high(SrcGates)do SrcNames[i]:=SrcGates[i].RegName;

        {VOP2 src0 const}
        if g.Typ in[gtIOr,gtIAnd,gtIXor,gtIAdd]then begin
          if charn(SrcNames[1],1)in['0'..'9','$','s','S']then
            Swap(SrcNames[1],SrcNames[0]);

          if charn(SrcNames[1],1)in['0'..'9','$','s','S']then begin
            line:=line+' vop3'; //force vop3
          end;
        end;

        //replace parameters
        Replace('d',g.RegName,line,[roIgnoreCase,roWholeWords,roAll]);
        for i:=0 to high(srcNames)do
          Replace('s'+ToStr(i),SrcNames[i],line,[roIgnoreCase,roWholeWords,roAll]);

        PostProcessLine(line);//max 1 darab  S lehet csak 1 v_ben, nem lehet konstans a vop3-ban

        AddLine(line);
      end;
    end;
  end;end;

var g:TGate;
begin
  bRegMap:=TBitmap.CreateNew(pf8bit,128,5000);

  //reset
  stats.TempRegCnt:=0;
  _calcOrderCounter:=0;
  for g in Gates do with g do begin
    allocatedReg:=-1;//clear allocation
    calced:=Typ=gtInput;
    if(Typ=gtInput)and(RegName='')then
      RegName:='$'+inttohex(Value,8); //constant input
    FCalcOrder:=0;
  end;
  VRegPool.clear;SRegPool.clear;

  Optimize_PullOrder;
  result:=GenerateCode;

  SelectAll;
  UpdateStats;
  with stats do result:=result+
    format(';gates: %d  Active gates: %d'#13#10';constants: %d  ActiveConstants: %d'#13#10';TempRegCnt V: %d S:%d '#13#10,
           [SelectedGateCount,SelectedActiveGateCount,SelectedConstCount,SelectedActiveConstCount,TempRegCnt,TempSRegCnt]);

  if bRegMap<>nil then begin
    bRegMap.SaveToFile('c:\regmap.bmp');
    FreeAndNil(bRegMap);
  end;
end;


initialization
{  asm
    mov eax,$11111111;movd xmm0,eax;shufps xmm0,xmm0,0
    mov eax,$22222222;movd xmm1,eax;shufps xmm1,xmm1,0
    mov eax,$00000008;movd xmm2,eax;shufps xmm2,xmm2,0
    call bitalign_xmm0_xmm1_xmm2
  end;}


  InitGateInfo;

  clConst:=RGB( 26,105,232);
  clDirty:=RGB(255, 85, 43);
  clSelected:=clWhite;
  clTitle:=RGB(250,187,145);

  SetMinimumBlockAlignment(mba16Byte);
//  RegisterHetClass([TGate,TGates,TWire,TWires,TCircuit,TCircuitCache]);
//  TCircuitCache((@CircuitCache)^):=TCircuitCache.Create(nil);
end.
