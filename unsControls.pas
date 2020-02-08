unit unsControls;

interface
uses
  sysutils, hetParser, Variants, hetVariants, Classes, Controls, Graphics;

var
  nsControls:TNameSpace;


implementation

function MakeNameSpace:TNameSpace;
begin
  result:=TNameSpace.Create('Controls');
  with result do begin

    AddConstant('mrNone',mrNone);
    AddConstant('mrOk',mrOk);
    AddConstant('mrCancel',mrCancel);
    AddConstant('mrAbort',mrAbort);
    AddConstant('mrRetry',mrRetry);
    AddConstant('mrIgnore',mrIgnore);
    AddConstant('mrYes',mrYes);
    AddConstant('mrNo',mrNo);
    AddConstant('mrAll',mrAll);
    AddConstant('mrNoToAll',mrNoToAll);
    AddConstant('mrYesToAll',mrYesToAll);
    AddConstant('mrClose',mrClose);

    AddConstant('crDefault',crDefault);
    AddConstant('crNone',crNone);
    AddConstant('crArrow',crArrow);
    AddConstant('crCross',crCross);
    AddConstant('crIBeam',crIBeam);
    AddConstant('crSize',crSize);
    AddConstant('crSizeNESW',crSizeNESW);
    AddConstant('crSizeNS',crSizeNS);
    AddConstant('crSizeNWSE',crSizeNWSE);
    AddConstant('crSizeWE',crSizeWE);
    AddConstant('crUpArrow',crUpArrow);
    AddConstant('crHourGlass',crHourGlass);
    AddConstant('crDrag',crDrag);
    AddConstant('crNoDrop',crNoDrop);
    AddConstant('crHSplit',crHSplit);
    AddConstant('crVSplit',crVSplit);
    AddConstant('crMultiDrag',crMultiDrag);
    AddConstant('crSQLWait',crSQLWait);
    AddConstant('crNo',crNo);
    AddConstant('crAppStart',crAppStart);
    AddConstant('crHelp',crHelp);
    AddConstant('crHandPoint',crHandPoint);
    AddConstant('crSizeAll',crSizeAll);

    AddEnum(TypeInfo(TAlign));
    AddSet(TypeInfo(TControlState));
    AddSet(TypeInfo(TControlStyle));
    AddEnum(TypeInfo(TMouseButton));
    AddEnum(TypeInfo(TMouseActivate));
    AddEnum(TypeInfo(TDragMode));
    AddEnum(TypeInfo(TDragState));
    AddEnum(TypeInfo(TDragKind));

    //TSizeConstraints
    AddClass(TSizeConstraints);
    AddObjectConstructor(TSizeConstraints,'Create(control)',function(const p:TVariantArray):TObject
      begin result:=TSizeConstraints.Create(TControl(VarAsObject(p[0],TControl)))end);

    //TMargins
    AddClass(TMargins);
    AddObjectConstructor(TMargins,'Create(control)',function(const p:TVariantArray):TObject
      begin result:=TMargins.Create(TControl(VarAsObject(p[0],TControl)))end);

    //TPadding
    AddClass(TPadding);
    AddObjectConstructor(TPadding,'Create(control)',function(const p:TVariantArray):TObject
      begin result:=TPadding.Create(TControl(VarAsObject(p[0],TControl)))end);

    AddEnum(TypeInfo(TDockOrientation));

(*    //TControl
    AddClass(TControl);
    AddObjectConstructor(TControl,'Create(owner)',function(const p:TVariantArray):TObject
      begin result:=TControl.Create(TComponent(VarAsObject(p[0],TComponent)))end);

    AddEnum(TypeInfo(TBevelCut));
    AddSet(TypeInfo(TBevelEdges));
    AddEnum(TypeInfo(TBevelKind));

    //TControl
    AddClass(TWinControl);
    AddObjectConstructor(TControl,'Create(owner)',function(const p:TVariantArray):TObject
      begin result:=TWinControl.Create(TComponent(VarAsObject(p[0],TComponent)))end);

    AddObjectFunction(TControl,'DockClientCount',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TWinControl(o).DockClientCount end);
    AddObjectFunction(TControl,'DockSite',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TWinControl(o).DockSite end, procedure(const o:TObject;const p:TVariantArray;const v:variant)
      begin TWinControl(o).DockSite:=v end);
    AddObjectFunction(TControl,'DockManager',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TWinControl(o).DockManager end);
    AddObjectFunction(TControl,'DoubleBuffered',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TWinControl(o).DoubleBuffered end, procedure(const o:TObject;const p:TVariantArray;const v:variant)
      begin TWinControl(o).DoubleBuffered:=v end);
    AddObjectFunction(TControl,'AlignDisabled',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TWinControl(o).AlignDisabled end);
    AddObjectFunction(TControl,'MouseInClient',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TWinControl(o).MouseInClient end);
    AddObjectFunction(TControl,'VisibleDockClientCount',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TWinControl(o).VisibleDockClientCount end);
    AddObjectFunction(TControl,'Brush',function(const o:TObject;const p:TVariantArray):variant
      begin result:=VObject(TWinControl(o).Brush)end);
    AddObjectFunction(TControl,'ControlCount',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TWinControl(o).ControlCount end);
    AddObjectFunction(TControl,'Handle',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TWinControl(o).Handle end);
    AddObjectFunction(TControl,'Padding',function(const o:TObject;const p:TVariantArray):variant
      begin result:=VObject(TWinControl(o).Padding)end, procedure(const o:TObject;const p:TVariantArray;const v:variant)
      begin TWinControl(o).Padding:=TPadding(VarAsObject(v,TPadding))end);
    AddObjectFunction(TControl,'ParentDoubleBuffered',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TWinControl(o).ParentDoubleBuffered end, procedure(const o:TObject;const p:TVariantArray;const v:variant)
      begin TWinControl(o).ParentDoubleBuffered:=v end);
    AddObjectFunction(TControl,'ParentWindow',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TWinControl(o).ParentWindow end, procedure(const o:TObject;const p:TVariantArray;const v:variant)
      begin TWinControl(o).ParentWindow:=v end);
    AddObjectFunction(TControl,'Showing',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TWinControl(o).Showing end);
    AddObjectFunction(TControl,'TabOrder',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TWinControl(o).TabOrder end, procedure(const o:TObject;const p:TVariantArray;const v:variant)
      begin TWinControl(o).TabOrder:=v end);
    AddObjectFunction(TControl,'TabStop',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TWinControl(o).TabStop end, procedure(const o:TObject;const p:TVariantArray;const v:variant)
      begin TWinControl(o).TabStop:=v end);
    AddObjectFunction(TControl,'UseDockManager',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TWinControl(o).UseDockManager end, procedure(const o:TObject;const p:TVariantArray;const v:variant)
      begin TWinControl(o).UseDockManager:=v end);
    AddObjectFunction(TControl,'Controls[index]',function(const o:TObject;const p:TVariantArray):variant
      begin result:=VObject(TWinControl(o).Controls[p[0]])end);
    AddObjectFunction(TControl,'DockClients[index]',function(const o:TObject;const p:TVariantArray):variant
      begin result:=VObject(TWinControl(o).DockClients[p[0]])end);

    AddObjectFunction(TControl,'DockDrop(Source,X,Y)',function(const o:TObject;const p:TVariantArray):variant
      begin TWinControl(o).DockDrop(TDragDockObject(VarAsObject(p[0],TDragDockObject)),p[1],p[2])end);
    AddObjectFunction(TControl,'EnableAlign',function(const o:TObject;const p:TVariantArray):variant
      begin TWinControl(o).EnableAlign end);
    AddObjectFunction(TControl,'FlipChildren(AllLevels)',function(const o:TObject;const p:TVariantArray):variant
      begin TWinControl(o).FlipChildren(p[0]) end);
    AddObjectFunction(TControl,'GetTabOrderList',function(const o:TObject;const p:TVariantArray):variant
      begin TWinControl(o).GetTabOrderList(TList(VarAsObject(p[0],TList)))end);
    AddObjectFunction(TControl,'HandleNeeded',function(const o:TObject;const p:TVariantArray):variant
      begin TWinControl(o).HandleNeeded end);
    AddObjectFunction(TControl,'InsertControl(AControl)',function(const o:TObject;const p:TVariantArray):variant
      begin TWinControl(o).InsertControl(TControl(VarAsObject(p[0],TControl)))end);
    AddObjectFunction(TControl,'RemoveControl(AControl)',function(const o:TObject;const p:TVariantArray):variant
      begin TWinControl(o).RemoveControl(TControl(VarAsObject(p[0],TControl)))end);
    AddObjectFunction(TControl,'Invalidate',function(const o:TObject;const p:TVariantArray):variant
      begin TWinControl(o).Invalidate end);
    AddObjectFunction(TControl,'PaintTo(Canvas,X,Y)',function(const o:TObject;const p:TVariantArray):variant
      begin TWinControl(o).PaintTo(TCanvas(VarAsObject(p[0],TCanvas)),p[1],p[2])end);
    AddObjectFunction(TControl,'Realign',function(const o:TObject;const p:TVariantArray):variant
      begin TWinControl(o).Realign end);
    AddObjectFunction(TControl,'ScaleBy(M,D)',function(const o:TObject;const p:TVariantArray):variant
      begin TWinControl(o).ScaleBy(p[0],p[1]) end);
    AddObjectFunction(TControl,'ScrollBy(DX,DY)',function(const o:TObject;const p:TVariantArray):variant
      begin TWinControl(o).ScrollBy(p[0],p[1]) end);
    AddObjectFunction(TControl,'SetBounds(ALeft,ATop,AWidth,AHeight)',function(const o:TObject;const p:TVariantArray):variant
      begin TWinControl(o).SetBounds(p[0],p[1],p[2],p[3]) end);
    AddObjectFunction(TControl,'SetFocus',function(const o:TObject;const p:TVariantArray):variant
      begin TWinControl(o).SetFocus end);
    AddObjectFunction(TControl,'Repaint',function(const o:TObject;const p:TVariantArray):variant
      begin TWinControl(o).Repaint end);
    AddObjectFunction(TControl,'Show',function(const o:TObject;const p:TVariantArray):variant
      begin TWinControl(o).Show end);
    AddObjectFunction(TControl,'Update',function(const o:TObject;const p:TVariantArray):variant
      begin TWinControl(o).Update end);
    AddObjectFunction(TControl,'UpdateControlState',function(const o:TObject;const p:TVariantArray):variant
      begin TWinControl(o).UpdateControlState end);

    AddObjectFunction(TControl,'CanFocus',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TWinControl(o).CanFocus end);
    AddObjectFunction(TControl,'ContainsControl(Control)',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TWinControl(o).ContainsControl(TControl(VarAsObject(p[0],TControl))) end);
    AddObjectFunction(TControl,'ControlAtPos(Pos,AllowDisabled,AllowWinControls=false,AllLevels=false)',function(const o:TObject;const p:TVariantArray):variant
      begin result:=VObject(TWinControl(o).ControlAtPos(VarAsPoint(p[0]),p[1],p[2],p[3]))end);
    AddObjectFunction(TControl,'FindChildControl(ControlName)',function(const o:TObject;const p:TVariantArray):variant
      begin result:=VObject(TWinControl(o).FindChildControl(p[0]))end);
    AddObjectFunction(TControl,'HandleAllocated',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TWinControl(o).HandleAllocated end);
    AddObjectFunction(TControl,'ScreenToClient(Point)',function(const o:TObject;const p:TVariantArray):variant
      begin result:=VPoint(TWinControl(o).ScreenToClient(VarAsPoint(p[0])))end);
    AddObjectFunction(TControl,'ClientToScreen(Point)',function(const o:TObject;const p:TVariantArray):variant
      begin result:=VPoint(TWinControl(o).ClientToScreen(VarAsPoint(p[0])))end);
    AddObjectFunction(TControl,'ParentToClient(Point,AParent=nil)',function(const o:TObject;const p:TVariantArray):variant
      begin result:=VPoint(TWinControl(o).ParentToClient(VarAsPoint(p[0]),TWinControl(VarAsObject(p[1],TWinControl))))end);
*)

  end;
end;

initialization
  nsControls:=MakeNameSpace;
  RegisterNameSpace(nsControls);
end.
