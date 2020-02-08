unit unsCal; //system    //unsSSE unssystem    het.parser het.cal unssystem unsCl

interface

uses
  SysUtils, Classes, het.Utils, het.Objects, het.Parser, Variants, het.Variants,
  het.Cal, ComObj, UCircuitArithmetic, typinfo; //unsClasses

const
  varGate:word=0;

type
  TGateVariantType=class(TCustomVariantTypeSpecialRelation)
    procedure Clear(var V: TVarData); override;
    procedure Copy(var Dest: TVarData; const Source: TVarData; const Indirect: Boolean); override;
    procedure CastTo(var Dest: TVarData; const Source: TVarData; const AVarType: TVarType);override;
    procedure Cast(var Dest: TVarData; const Source: TVarData); override;
    procedure UnaryOp(var Right: TVarData; const Op: TVarOp);override;
    procedure BinaryOp(var Left: TVarData; const Right: TVarData; const Op: TVarOp);override;
    procedure RelationOp(var L:variant;const R:variant;const op:TVarOp);override;//ez csak dispatcholja a binaryopnak
    function RightPromotion(const V: TVarData; const Op: TVarOp; out RequiredVarType: TVarType): Boolean;override;
    function AsObject(const V:TVarData):TObject;override;
  end;

var
  nsCal:TNameSpace;

implementation

uses UVector;

var
  Circuit:TCircuit;

////////////////////////////////////////////////////////////////////////////////
///  HetPas compiler                                                         ///
////////////////////////////////////////////////////////////////////////////////

function VGate(const typ:TGateType;var vres:Variant):TGate;
var p:TV2i;
    i:integer;
begin
  i:=Circuit.Gates.Count;
  p:=v2i(i and $ff,i shr 8);
  result:=Circuit.AddGate(p,typ);

  VarClear(vres);
  with TVarData(vres)do begin
    VType:=varGate;
    VLongs[0]:=integer(result);
  end;
end;

function VarIsGate(const V:Variant):boolean;
begin
  result:=TVarData(V).VType=varGate;
end;

function VGateInput(const ARegName:ansistring;const AValue:int64;const ADirtyMask:int64=0):Variant;
begin
  with VGate(gtInput,result)do begin
    Constant:=AValue;
    DirtyMask:=ADirtyMask;
    RegName:=ARegName;
    Calculate;
  end;
end;

function VarAsGate(const V:Variant):TGate;
begin
  if VarIsGate(V)then result:=TGate(TVarData(V).VLongs[0])
                 else result:=VarAsGate(VGateInput('',V));//constant
end;

function VGateOp1(const t:TGateType;const src0:variant):Variant;
var g0:TGate;
begin
  g0:=VarAsGate(src0);
  with VGate(t,result)do begin
    Circuit.AddWire(g0.Pos,Pos);
    Calculate;
  end;
end;

function VGateOp2(const t:TGateType;const src0,src1:variant):Variant;
var g0,g1:TGate;
begin
  g0:=VarAsGate(src0);
  g1:=VarAsGate(src1);
  with VGate(t,result)do begin
    Circuit.AddWire(g0.Pos,Pos);
    Circuit.AddWire(g1.Pos,Pos);
    Calculate;
  end;
end;

function VGateOp3(const t:TGateType;const src0,src1,src2:variant):Variant;
var g0,g1,g2:TGate;
begin
  g0:=VarAsGate(src0);
  g1:=VarAsGate(src1);
  g2:=VarAsGate(src2);
  with VGate(t,result)do begin
    Circuit.AddWire(g0.Pos,Pos);
    Circuit.AddWire(g1.Pos,Pos);
    Circuit.AddWire(g2.Pos,Pos);
    Calculate;
  end;
end;

procedure TGateVariantType.Clear(var V: TVarData);
begin
  SimplisticClear(V);
end;

procedure TGateVariantType.Copy(var Dest: TVarData; const Source: TVarData; const Indirect: Boolean);
begin
  if Indirect then raise EVariantInvalidOpError.Create('TCalVariantType.Copy() Cannot copy indirectly');
  SimplisticCopy(Dest,Source);
end;

procedure TGateVariantType.CastTo(var Dest: TVarData; const Source: TVarData; const AVarType: TVarType);
var VDest:Variant absolute Dest;
    s:ansistring;
    g:TGate;
begin
  if(Source.VType=VarType)then begin
    if(AVarType=varString)or(AVarType=varUString)or(AVarType=varStrArg)then begin
      g:=TGate(Source.VLongs[0]);
      if g=nil then s:='gate(nil)'
               else s:=format('gate(%s,%d,%d):%.8x',
                             [GateInfo[g.Typ].name,g.PosX,g.PosY,g.Value]);
      VDest:=s;
    end else
      RaiseCastError;
  end else
    inherited;
end;

procedure TGateVariantType.Cast(var Dest: TVarData; const Source: TVarData);
begin
  if VarIsOrdinal(variant(Source))then begin
    VarDataInit(Dest);
    Variant(Dest):=VGateInput('',variant(Source));
  end else
    inherited;
end;

procedure TGateVariantType.UnaryOp(var Right: TVarData; const Op: TVarOp);
  procedure op1(t:TGateType);begin Right:=TVarData(VGateOp1(t,variant(Right)));end;
begin
  case Op of
    opNot:op1(gtINot);
//    opNegate:op1(gtINegate);
  else
    RaiseInvalidOp;
  end;
end;

function TGateVariantType.AsObject(const V:TVarData): TObject;
begin
  result:=TObject(V.VLongs[0]);
end;

procedure TGateVariantType.BinaryOp(var Left: TVarData; const Right: TVarData; const Op: TVarOp);
  procedure op2(t:TGateType);begin Left:=TVarData(VGateOp2(t,variant(Left),variant(Right)));end;
begin
  case Op of
    opAdd:op2(gtIAdd);
    opSubtract:op2(gtISub);
{    opMultiply:;
    opDivide:;
    opIntDivide:;
    opModulus:;}
    opShiftLeft:op2(gtIShl);
    opShiftRight:op2(gtUShr);
    opAnd:op2(gtIAnd);
    opOr:op2(gtIOr);
    opXor:op2(gtIXor);
{    opCompare:;
    opCmpEQ:;
    opCmpNE:;
    opCmpLT:;
    opCmpLE:;
    opCmpGT:;
    opCmpGE:;}
  else
    RaiseInvalidOp;
  end;
end;

procedure TGateVariantType.RelationOp(var L:variant;const R:variant;const op:TVarOp);
var typ:TVarType;
    R2:Variant;
begin
  if not VarIsgate(R)and RightPromotion(TVarData(R),op,typ)then begin
    CastTo(TVarData(R2),TVarData(R),typ);
    BinaryOp(TVarData(L),TVarData(R2),Op);
  end else begin
    BinaryOp(TVarData(L),TVarData(R),Op);
  end;
end;

function TGateVariantType.RightPromotion(const V: TVarData; const Op: TVarOp; out RequiredVarType: TVarType): Boolean;
begin
  if{(Op in[opShiftLeft,opShiftRight])and }VarIsOrdinal(variant(V))then begin
    RequiredVarType:=VarType;
    result:=true;
  end else
    result:=false;
end;

////////////////////////////////////////////////////////////////////////////////
///  NameSpace declarations                                                  ///
////////////////////////////////////////////////////////////////////////////////

function MakeNameSpace:TNameSpace;
begin
  result:=TNameSpace.Create('Cal');
  with result do begin
    AddConstant('Cal',VClass(Cal));

    AddObjectFunction(TCalDevices,'__Default[n]',function(const o:TObject;const p:TVariantArray):variant
      begin result:=VObject(TCalDevices(o).ByIndex[p[0]])end);

    AddObjectFunction(TCalModule,'__Default[n]',function(const o:TObject;const p:TVariantArray):variant
      begin result:=VObject(TCalModule(o).Symbol[p[0]])end,
    procedure(const o:TObject;const p:TVariantArray;const v:variant)
      begin TCalModule(o).Symbol[p[0]]:=TCalResource(VarAsObject(v,TCalResource))end);

    AddObjectFunction(TCalResource,'IntVArray',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TCalResource(o).IntVArray end,
    procedure(const o:TObject;const p:TVariantArray;const v:variant)
      begin TCalResource(o).IntVArray:=v end);

    AddObjectFunction(TCalResource,'FloatVArray',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TCalResource(o).FloatVArray end,
    procedure(const o:TObject;const p:TVariantArray;const v:variant)
      begin TCalResource(o).FloatVArray:=v end);

    AddObjectFunction(TCalResource,'Bytes[x]',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TCalResource(o).Bytes[p[0]] end,
    procedure(const o:TObject;const p:TVariantArray;const v:variant)
      begin TCalResource(o).Bytes[p[0]]:=v end);

    AddObjectFunction(TCalResource,'Ints[x]',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TCalResource(o).Ints[p[0]] end,
    procedure(const o:TObject;const p:TVariantArray;const v:variant)
      begin TCalResource(o).Ints[p[0]]:=v end);

    AddObjectFunction(TCalResource,'Floats[x]',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TCalResource(o).Floats[p[0]] end,
    procedure(const o:TObject;const p:TVariantArray;const v:variant)
      begin TCalResource(o).Floats[p[0]]:=v end);

    AddObjectFunction(TCalResource,'Doubles[x]',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TCalResource(o).Doubles[p[0]] end,
    procedure(const o:TObject;const p:TVariantArray;const v:variant)
      begin TCalResource(o).Doubles[p[0]]:=v end);

    AddConstant('Circuit',VObject(Circuit));

    AddFunction('input(regname,val,dirtymask=0)',function(const p:TVariantArray):variant
      begin result:=VGateInput(p[0],p[1],p[2])end);

    AddFunction('pull(regName,gate)',function(const p:TVariantArray):variant
      var g:TGate;
      begin
        g:=VarAsGate(p[1]);
        if(g.regname='')or(cmp(g.regname,p[0])=0)then begin
          result:=p[1];
        end else begin//pull input with mov
          result:=VGateOp1(gtMov,p[1]);
          g:=VarAsGate(result);
        end;
        g.sel:=true;
        g.regname:=p[0];
      end);

    AddFunction('rolc(x,y)',function(const p:TVariantArray):variant   //renamed. there is new vector rol
      begin
        case p[1]of
          1:result:=VGateOp1(gtRol1,p[0]);
          2:result:=VGateOp1(gtRol2,p[0]);
          4:result:=VGateOp1(gtRol4,p[0]);
          5:result:=VGateOp1(gtRol5,p[0]);
          7:result:=VGateOp1(gtRol7,p[0]);
          9:result:=VGateOp1(gtRol9,p[0]);
         13:result:=VGateOp1(gtRol13,p[0]);
         18:result:=VGateOp1(gtRol18,p[0]);
         30:result:=VGateOp1(gtRol30,p[0]);
        else
          raise Exception.Create('rol.fck');
        end;
      end);

    AddFunction('vec_sel(x,y,z)',function(const p:TVariantArray):variant
      begin result:=VGateOp3(gtVectSel,p[0],p[1],p[2]) end);

    AddFunction('s_not(x)',function(const p:TVariantArray):variant
      begin result:=VGateOp1(gtS_not,p[0]) end);
    AddFunction('s_xor(x,y)',function(const p:TVariantArray):variant
      begin result:=VGateOp2(gtS_xor,p[0],p[1]) end);
    AddFunction('s_or(x,y)',function(const p:TVariantArray):variant
      begin result:=VGateOp2(gtS_or,p[0],p[1]) end);
    AddFunction('s_and(x,y)',function(const p:TVariantArray):variant
      begin result:=VGateOp2(gtS_and,p[0],p[1]) end);
    AddFunction('s_andn2(x,y)',function(const p:TVariantArray):variant
      begin result:=VGateOp2(gtS_andn2,p[0],p[1]) end);
    AddFunction('s_iadd(x,y)',function(const p:TVariantArray):variant
      begin result:=VGateOp2(gtS_iadd,p[0],p[1]) end);
    AddFunction('s_isub(x,y)',function(const p:TVariantArray):variant
      begin result:=VGateOp2(gtS_isub,p[0],p[1]) end);
    AddFunction('s_ushr(x,y)',function(const p:TVariantArray):variant
      begin result:=VGateOp2(gtS_ushr,p[0],p[1]) end);
    AddFunction('s_ishl(x,y)',function(const p:TVariantArray):variant
      begin result:=VGateOp2(gtS_ishl,p[0],p[1]) end);
    AddFunction('s_ishr(x,y)',function(const p:TVariantArray):variant
      begin result:=VGateOp2(gtS_ishr,p[0],p[1]) end);

    AddFunction('ushr(x,y)',function(const p:TVariantArray):variant
      begin result:=VGateOp2(gtushr,p[0],p[1]) end);
    AddFunction('ishl(x,y)',function(const p:TVariantArray):variant
      begin result:=VGateOp2(gtishl,p[0],p[1]) end);
    AddFunction('ishr(x,y)',function(const p:TVariantArray):variant
      begin result:=VGateOp2(gtishr,p[0],p[1]) end);

    AddFunction('bitalign(x,y,shift)',function(const p:TVariantArray):variant
      begin result:=VGateOp3(gtBitalign,p[0],p[1],p[2]) end);

    AddFunction('ResetCircuit',function(const p:TVariantArray):variant
      begin
        Circuit.free;Circuit:=TCircuit.Create(nil);
        TNameSpaceConstant(nsCal.FindByName('Circuit')).Value:=VObject(Circuit);
      end);

  end;
end;

var
  GateVariantType:TGateVariantType;

initialization
//  asmtest;
  GateVariantType:=TGateVariantType.Create;
  pword(@varGate)^:=GateVariantType.VarType;
  Circuit:=TCircuit.Create(nil);
  nsCal:=MakeNameSpace;
  RegisterNameSpace(nsCal);
finalization
end.

