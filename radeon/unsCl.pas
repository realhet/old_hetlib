unit unsCl;

interface

uses
  SysUtils, Classes, het.Utils, het.Objects, het.Parser, Variants, het.Variants,
  het.Cl, typinfo; 

var
  nsCl:TNameSpace;

implementation


////////////////////////////////////////////////////////////////////////////////
///  NameSpace declarations                                                  ///
////////////////////////////////////////////////////////////////////////////////

function MakeNameSpace:TNameSpace;
begin
  result:=TNameSpace.Create('Cl');
  with result do begin
    AddConstant('Cl',VClass(Cl));

    AddObjectFunction(TClDevices,'__Default[n]',function(const o:TObject;const p:TVariantArray):variant
      begin result:=VObject(TClDevices(o).ByIndex[p[0]])end);

    AddObjectFunction(TClDevice,'NewKernel(code,oclSkeleton="")',function(const o:TObject;const p:TVariantArray):variant
      begin result:=VObject(TClDevice(o).NewKernel(p[0],p[1]))end);

    AddObjectFunction(TClKernel,'Run(WorkCount,b0=nil,b1=nil,b2=nil,b3=nil)',function(const o:TObject;const p:TVariantArray):variant
      begin result:=VObject(TClKernel(o).Run(p[0],
        TClBuffer(VarAsObject(p[1],TClBuffer)),
        TClBuffer(VarAsObject(p[2],TClBuffer)),
        TClBuffer(VarAsObject(p[3],TClBuffer)),
        TClBuffer(VarAsObject(p[4],TClBuffer))
      ))end);
    AddObjectFunction(TClKernel,'RunRange(WorkOffset,WorkCount,b0=nil,b1=nil,b2=nil,b3=nil)',function(const o:TObject;const p:TVariantArray):variant
      begin result:=VObject(TClKernel(o).RunRange(p[0],p[1],
        TClBuffer(VarAsObject(p[2],TClBuffer)),
        TClBuffer(VarAsObject(p[3],TClBuffer)),
        TClBuffer(VarAsObject(p[4],TClBuffer)),
        TClBuffer(VarAsObject(p[5],TClBuffer))
      ))end);

    AddObjectFunction(TClKernel,'SetArg(idx,val)', function(const o:TObject;const p:TVariantArray):variant
      begin
        result:=Unassigned;
        TClKernel(o).SetArg(p[0],p[1]);
      end);

    AddObjectFunction(TClBuffer,'IntVArray',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TClBuffer(o).IntVArray end,
    procedure(const o:TObject;const p:TVariantArray;const v:variant)
      begin TClBuffer(o).IntVArray:=v end);

    AddObjectFunction(TClBuffer,'FloatVArray',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TClBuffer(o).FloatVArray end,
    procedure(const o:TObject;const p:TVariantArray;const v:variant)
      begin TClBuffer(o).FloatVArray:=v end);

    AddObjectFunction(TClBuffer,'Bytes[x]',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TClBuffer(o).Bytes[p[0]] end,
    procedure(const o:TObject;const p:TVariantArray;const v:variant)
      begin TClBuffer(o).Bytes[p[0]]:=v end);

    AddObjectFunction(TClBuffer,'Ints[x]',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TClBuffer(o).Ints[p[0]] end,
    procedure(const o:TObject;const p:TVariantArray;const v:variant)
      begin TClBuffer(o).Ints[p[0]]:=v end);

    AddObjectFunction(TClBuffer,'Int64s[x]',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TClBuffer(o).Int64s[p[0]] end,
    procedure(const o:TObject;const p:TVariantArray;const v:variant)
      begin TClBuffer(o).Int64s[p[0]]:=v end);

    AddObjectFunction(TClBuffer,'Floats[x]',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TClBuffer(o).Floats[p[0]] end,
    procedure(const o:TObject;const p:TVariantArray;const v:variant)
      begin TClBuffer(o).Floats[p[0]]:=v end);

    AddObjectFunction(TClBuffer,'Doubles[x]',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TClBuffer(o).Doubles[p[0]] end,
    procedure(const o:TObject;const p:TVariantArray;const v:variant)
      begin TClBuffer(o).Doubles[p[0]]:=v end);

  end;
end;

initialization
  nsCl:=MakeNameSpace;
  RegisterNameSpace(nsCl);
finalization
end.
