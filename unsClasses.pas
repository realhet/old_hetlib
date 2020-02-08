unit unsClasses;

deprecated -> NewRTTI

interface

uses
  sysutils, hetParser, Variants, hetVariants, Classes, hetObject;

var
  nsClasses:TNameSpace;

implementation

type TFreeAndNil=class(TNameSpaceEntry)procedure Eval(var AResult:variant;var AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;end;
procedure TFreeAndNil.Eval;
begin with AParams.SubNode(0)do begin
  VarAsObject(Eval(AContext)).Free;
  Let(AContext,VObject(nil));
end;end;

function MakeNameSpace:TNameSpace;
begin
  result:=TNameSpace.Create('Classes');
  with result do begin
    //TClassReference
    AddObjectFunction(TClassReference,'ClassName',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TClassReference(o).ReferencedClass.ClassName end);
    AddObjectFunction(TClassReference,'ClassType',function(const o:TObject;const p:TVariantArray):variant
      begin result:=VClass(TClassReference(o).ReferencedClass) end);
    AddObjectFunction(TClassReference,'ClassParent',function(const o:TObject;const p:TVariantArray):variant
      begin result:=VClass(TClassReference(o).ReferencedClass.ClassParent) end);
    AddObjectFunction(TClassReference,'InheritsFrom',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TClassReference(o).ReferencedClass.InheritsFrom(VarAsClass(p[0])) end);

    //TObject
    AddClass(TObject);
    AddObjectConstructor(TObject,'Create',function(const p:TVariantArray):TObject
      begin result:=TObject.Create end);

    AddObjectFunction(TObject,'Free',function(const o:TObject;const p:TVariantArray):variant
      begin o.Free end);
    AddObjectFunction(TObject,'Destroy',function(const o:TObject;const p:TVariantArray):variant
      begin o.Destroy end);
    AddObjectFunction(TObject,'ClassName',function(const o:TObject;const p:TVariantArray):variant
      begin result:=o.ClassName end);
    AddObjectFunction(TObject,'ClassParent',function(const o:TObject;const p:TVariantArray):variant
      begin result:=VClass(o.ClassParent) end);
    AddObjectFunction(TObject,'Equals(o)',function(const o:TObject;const p:TVariantArray):variant
      begin result:=o.Equals(VarAsObject(p[0])) end);
    AddObjectFunction(TObject,'GetHashCode',function(const o:TObject;const p:TVariantArray):variant
      begin result:=o.GetHashCode end);
    AddObjectFunction(TObject,'ToString',function(const o:TObject;const p:TVariantArray):variant
      begin result:=o.ToString end);
    Add(TFreeAndNil.Create('FreeAndNil(X)'));

    //TList
    AddClass(TList);
    AddObjectConstructor(TList,'Create',function(const p:TVariantArray):TObject
      begin result:=TList.Create end);

    AddObjectFunction(TList,'Add(item)',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TList(o).Add(VarAsObject(p[0]))end);
    AddObjectFunction(TList,'Clear',function(const o:TObject;const p:TVariantArray):variant
      begin TList(o).Clear end);
    AddObjectFunction(TList,'Delete(item)',function(const o:TObject;const p:TVariantArray):variant
      begin TList(o).Delete(p[0])end);
    AddObjectFunction(TList,'Exchange(idx1,idx2)',function(const o:TObject;const p:TVariantArray):variant
      begin TList(o).Exchange(p[0],p[1])end);
    AddObjectFunction(TList,'Extract(item)',function(const o:TObject;const p:TVariantArray):variant
      begin result:=VObject(TList(o).Extract(VarAsObject(p[0])))end);
    AddObjectFunction(TList,'First',function(const o:TObject;const p:TVariantArray):variant
      begin result:=VObject(TList(o).First)end);
    AddObjectFunction(TList,'Last',function(const o:TObject;const p:TVariantArray):variant
      begin result:=VObject(TList(o).Last)end);
    AddObjectFunction(TList,'IndexOf(item)',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TList(o).IndexOf(VarAsObject(p[0]))end);
    AddObjectFunction(TList,'Insert(idx,item)',function(const o:TObject;const p:TVariantArray):variant
      begin TList(o).Insert(p[0],VarAsObject(p[1]))end);
    AddObjectFunction(TList,'Move(idx1,idx2)',function(const o:TObject;const p:TVariantArray):variant
      begin TList(o).Move(p[0],p[1])end);
    AddObjectFunction(TList,'Remove(item)',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TList(o).Remove(VarAsObject(p[0]))end);
    AddEnum(TypeInfo(TListAssignOp));
    AddObjectFunction(TList,'Assign(ListA,Op=0,ListB=nil)',function(const o:TObject;const p:TVariantArray):variant
      begin TList(o).Assign(TList(VarAsObject(p[0],TList)),TListAssignOp(p[1]),TList(VarAsObject(p[2],TList)))end);
    AddObjectFunction(TList,'Count',function(const o:TObject;const p:TVariantArray):variant begin result:=TList(o).Count end,
                           procedure(const o:TObject;const p:TVariantArray;const v:variant) begin TList(o).Count:=v end);
    AddDefaultObjectFunction(TList,'Items[idx]',function(const o:TObject;const p:TVariantArray):variant begin result:=VObject(TList(o).Items[p[0]])end,
                                procedure(const o:TObject;const p:TVariantArray;const v:variant) begin TList(o).Items[p[0]]:=VarAsObject(v)end);

    //persistent
    AddClass(TPersistent);
    AddObjectConstructor(TPersistent,'Create',function(const p:TVariantArray):TObject
      begin result:=TPersistent.Create end);

    AddObjectFunction(TPersistent,'Assign(src)',function(const o:TObject;const p:TVariantArray):variant
      begin TPersistent(o).Assign(TPersistent(VarAsObject(p[0],TPersistent)))end);
    AddObjectFunction(TPersistent,'GetNamePath',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TPersistent(o).GetNamePath end);

    //TCollectionItem
    AddClass(TCollectionItem);
    AddObjectConstructor(TCollectionItem,'Create(Collection)',function(const p:TVariantArray):TObject
      begin result:=TCollectionItem.Create(TCollection(VarAsObject(p[0],TCollection)))end);

    AddObjectFunction(TCollectionItem,'Collection',function(const o:TObject;const p:TVariantArray):variant
      begin result:=VObject(TCollectionItem(o).Collection) end,  procedure(const o:TObject;const p:TVariantArray;const v:variant)
      begin TCollectionItem(o).Collection:=TCollection(VarAsObject(p[0],TCollection)) end);
    AddObjectFunction(TCollectionItem,'ID',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TCollectionItem(o).ID end);
    AddObjectFunction(TCollectionItem,'Index',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TCollectionItem(o).Index end,  procedure(const o:TObject;const p:TVariantArray;const v:variant)
      begin TCollectionItem(o).Index:=p[0] end);
    AddObjectFunction(TCollectionItem,'DisplayName',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TCollectionItem(o).DisplayName end,  procedure(const o:TObject;const p:TVariantArray;const v:variant)
      begin TCollectionItem(o).DisplayName:=p[0] end);

    //TCollection
    AddClass(TCollection);
    AddObjectConstructor(TCollection,'Create(ItemClass)',function(const p:TVariantArray):TObject
      begin result:=TCollection.Create(TCollectionItemClass(VarAsClass(p[0],TCollectionItem)))end);

    AddObjectFunction(TCollection,'Owner',function(const o:TObject;const p:TVariantArray):variant
      begin result:=VObject(TCollection(o).Owner) end);
    AddObjectFunction(TCollection,'Add',function(const o:TObject;const p:TVariantArray):variant
      begin result:=VObject(TCollection(o).Add) end);
    AddObjectFunction(TCollection,'BeginUpdate',function(const o:TObject;const p:TVariantArray):variant
      begin TCollection(o).BeginUpdate end);
    AddObjectFunction(TCollection,'EndUpdate',function(const o:TObject;const p:TVariantArray):variant
      begin TCollection(o).EndUpdate end);
    AddObjectFunction(TCollection,'Clear',function(const o:TObject;const p:TVariantArray):variant
      begin TCollection(o).Clear end);
    AddObjectFunction(TCollection,'Delete(idx)',function(const o:TObject;const p:TVariantArray):variant
      begin TCollection(o).Delete(p[0]) end);
    AddObjectFunction(TCollection,'FindItemID(ID)',function(const o:TObject;const p:TVariantArray):variant
      begin result:=VObject(TCollection(o).FindItemID(p[0])) end);
    AddObjectFunction(TCollection,'Insert(idx)',function(const o:TObject;const p:TVariantArray):variant
      begin result:=VObject(TCollection(o).Insert(p[0])) end);
    AddObjectFunction(TCollection,'Count',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TCollection(o).Count end);
    AddObjectFunction(TCollection,'ItemClassName',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TCollection(o).ItemClass.ClassName end);
    AddDefaultObjectFunction(TCollection,'Items[idx]',function(const o:TObject;const p:TVariantArray):variant begin result:=VObject(TCollection(o).Items[p[0]])end,
                                procedure(const o:TObject;const p:TVariantArray;const v:variant) begin TCollection(o).Items[p[0]]:=TCollectionItem(VarAsObject(v,TCollectionItem))end);

    //TStrings
    AddClass(TStrings);

    AddObjectFunction(TStrings,'Add(str)',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TStrings(o).Add(p[0]) end);
    AddObjectFunction(TStrings,'AddObject(str,obj)',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TStrings(o).AddObject(p[0],VarAsObject(p[1])) end);
    AddObjectFunction(TStrings,'Append(str)',function(const o:TObject;const p:TVariantArray):variant
      begin TStrings(o).Append(p[0]) end);
    AddObjectFunction(TStrings,'AddStrings(strs)',function(const o:TObject;const p:TVariantArray):variant
      begin TStrings(o).AddStrings(TStrings(VarAsObject(p[0],TStrings))) end);
    AddObjectFunction(TStrings,'BeginUpdate',function(const o:TObject;const p:TVariantArray):variant
      begin TStrings(o).BeginUpdate end);
    AddObjectFunction(TStrings,'EndUpdate',function(const o:TObject;const p:TVariantArray):variant
      begin TStrings(o).EndUpdate end);
    AddObjectFunction(TStrings,'Clear',function(const o:TObject;const p:TVariantArray):variant
      begin TStrings(o).Clear end);
    AddObjectFunction(TStrings,'Delete(idx)',function(const o:TObject;const p:TVariantArray):variant
      begin TStrings(o).Delete(p[0]) end);
    AddObjectFunction(TStrings,'Equals(strs)',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TStrings(o).Equals(TStrings(VarAsObject(p[0],TStrings))) end);
    AddObjectFunction(TStrings,'Exchange(idx1,idx2)',function(const o:TObject;const p:TVariantArray):variant
      begin TStrings(o).Exchange(p[0],p[1])end);
    AddObjectFunction(TStrings,'GetText',function(const o:TObject;const p:TVariantArray):variant
      begin result:=string(TStrings(o).GetText) end);
    AddObjectFunction(TStrings,'SetText(str)',function(const o:TObject;const p:TVariantArray):variant
      begin TStrings(o).SetText(PWideChar(WideString(p[0]))) end);
    AddObjectFunction(TStrings,'IndexOf(str)',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TStrings(o).IndexOf(p[0])end);
    AddObjectFunction(TStrings,'IndexOfName(str)',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TStrings(o).IndexOfName(p[0])end);
    AddObjectFunction(TStrings,'IndexOfObject(str)',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TStrings(o).IndexOfObject(VarAsObject(p[0]))end);
    AddObjectFunction(TStrings,'Insert(idx,str)',function(const o:TObject;const p:TVariantArray):variant
      begin TStrings(o).Insert(p[0],p[1])end);
    AddObjectFunction(TStrings,'InsertObject(idx,str,obj)',function(const o:TObject;const p:TVariantArray):variant
      begin TStrings(o).InsertObject(p[0],p[1],VarAsObject(p[2]))end);
    AddObjectFunction(TStrings,'Move(idx1,idx2)',function(const o:TObject;const p:TVariantArray):variant
      begin TStrings(o).Move(p[0],p[1])end);
    AddObjectFunction(TStrings,'CommaText',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TStrings(o).CommaText end, procedure(const o:TObject;const p:TVariantArray;const v:variant)
      begin TStrings(o).CommaText:=v end);
    AddObjectFunction(TStrings,'Count',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TStrings(o).Count end);
    AddObjectFunction(TStrings,'Delimiter',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TStrings(o).Delimiter end, procedure(const o:TObject;const p:TVariantArray;const v:variant)
      begin TStrings(o).Delimiter:=VarAsUnicodeChar(v) end);
    AddObjectFunction(TStrings,'DelimitedText',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TStrings(o).DelimitedText end, procedure(const o:TObject;const p:TVariantArray;const v:variant)
      begin TStrings(o).DelimitedText:=v end);
    AddObjectFunction(TStrings,'LineBreak',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TStrings(o).LineBreak end, procedure(const o:TObject;const p:TVariantArray;const v:variant)
      begin TStrings(o).LineBreak:=v end);
    AddObjectFunction(TStrings,'Names[idx]',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TStrings(o).Names[p[0]] end);
    AddObjectFunction(TStrings,'Objects[idx]',function(const o:TObject;const p:TVariantArray):variant
      begin result:=VObject(TStrings(o).Objects[p[0]]) end, procedure(const o:TObject;const p:TVariantArray;const v:variant)
      begin TStrings(o).Objects[p[0]]:=VarAsObject(v) end);
    AddObjectFunction(TStrings,'QuoteChar',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TStrings(o).QuoteChar end, procedure(const o:TObject;const p:TVariantArray;const v:variant)
      begin TStrings(o).QuoteChar:=VarAsUnicodeChar(v) end);
    AddObjectFunction(TStrings,'Values[name]',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TStrings(o).Values[p[0]] end, procedure(const o:TObject;const p:TVariantArray;const v:variant)
      begin TStrings(o).Values[p[0]]:=v end);
    AddObjectFunction(TStrings,'ValueFromIndex[idx]',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TStrings(o).ValueFromIndex[p[0]] end, procedure(const o:TObject;const p:TVariantArray;const v:variant)
      begin TStrings(o).ValueFromIndex[p[0]]:=v end);
    AddObjectFunction(TStrings,'NameValueSeparator',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TStrings(o).NameValueSeparator end, procedure(const o:TObject;const p:TVariantArray;const v:variant)
      begin TStrings(o).NameValueSeparator:=VarAsUnicodeChar(v) end);
    AddObjectFunction(TStrings,'StrictDelimiter',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TStrings(o).StrictDelimiter end, procedure(const o:TObject;const p:TVariantArray;const v:variant)
      begin TStrings(o).StrictDelimiter:=v end);
    AddDefaultObjectFunction(TStrings,'Strings[idx]',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TStrings(o).Strings[p[0]] end, procedure(const o:TObject;const p:TVariantArray;const v:variant)
      begin TStrings(o).Strings[p[0]]:=v end);
    AddObjectFunction(TStrings,'Text',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TStrings(o).Text end, procedure(const o:TObject;const p:TVariantArray;const v:variant)
      begin TStrings(o).Text:=v end);

    //TStringList
    AddClass(TStringList);
    AddObjectConstructor(TStringList,'Create',function(const p:TVariantArray):TObject
      begin result:=TStringList.Create end);

    AddObjectFunction(TStringList,'Sort',function(const o:TObject;const p:TVariantArray):variant
      begin TStringList(o).Sort end);
      {customsort with lambda}
    AddEnum(TypeInfo(TDuplicates));
    AddObjectFunction(TStringList,'Duplicates',function(const o:TObject;const p:TVariantArray):variant
      begin result:=VEnum(ord(TStringList(o).Duplicates),TypeInfo(TDuplicates)) end, procedure(const o:TObject;const p:TVariantArray;const v:variant)
      begin TStringList(o).Duplicates:=TDuplicates(integer(v))end);
    AddObjectFunction(TStringList,'Sorted',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TStringList(o).Sorted end, procedure(const o:TObject;const p:TVariantArray;const v:variant)
      begin TStringList(o).Sorted:=v end);
    AddObjectFunction(TStringList,'CaseSensitive',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TStringList(o).CaseSensitive end, procedure(const o:TObject;const p:TVariantArray;const v:variant)
      begin TStringList(o).CaseSensitive:=v end);
    AddObjectFunction(TStringList,'OwnsObjects',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TStringList(o).OwnsObjects end, procedure(const o:TObject;const p:TVariantArray;const v:variant)
      begin TStringList(o).OwnsObjects:=v end);

    //TComponent
    AddClass(TComponent);
    AddObjectConstructor(TComponent,'Create(AOwner)',function(const p:TVariantArray):TObject
      begin result:=TComponent.Create(TComponent(VarAsObject(p[0],TComponent)))end);

    AddObjectFunction(TComponent,'ExecuteAction(action)',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TComponent(o).ExecuteAction(TBasicAction(VarAsObject(p[0],TBasicAction))) end);
    AddObjectFunction(TComponent,'FindComponent(name)',function(const o:TObject;const p:TVariantArray):variant
      begin result:=VObject(TComponent(o).FindComponent(p[0])) end);
    AddObjectFunction(TComponent,'FreeNotification(comp)',function(const o:TObject;const p:TVariantArray):variant
      begin TComponent(o).FreeNotification(TComponent(VarAsObject(p[0],TComponent))) end);
    AddObjectFunction(TComponent,'RemoveFreeNotification(comp)',function(const o:TObject;const p:TVariantArray):variant
      begin TComponent(o).RemoveFreeNotification(TComponent(VarAsObject(p[0],TComponent))) end);
    AddObjectFunction(TComponent,'GetParentComponent',function(const o:TObject;const p:TVariantArray):variant
      begin result:=VObject(TComponent(o).GetParentComponent) end);
    AddObjectFunction(TComponent,'HasParent',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TComponent(o).HasParent end);
    AddObjectFunction(TComponent,'InsertComponent(AComponent)',function(const o:TObject;const p:TVariantArray):variant
      begin TComponent(o).InsertComponent(TComponent(VarAsObject(p[0],TComponent))) end);
    AddObjectFunction(TComponent,'RemoveComponent(AComponent)',function(const o:TObject;const p:TVariantArray):variant
      begin TComponent(o).RemoveComponent(TComponent(VarAsObject(p[0],TComponent))) end);
    AddObjectFunction(TComponent,'SetSubComponent(IsSubComponent)',function(const o:TObject;const p:TVariantArray):variant
      begin TComponent(o).SetSubComponent(p[0]) end);
    AddObjectFunction(TComponent,'UpdateAction(action)',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TComponent(o).UpdateAction(TBasicAction(VarAsObject(p[0],TBasicAction))) end);
    AddObjectFunction(TComponent,'ComObject',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TComponent(o).ComObject end);
    AddObjectFunction(TComponent,'Components[idx]',function(const o:TObject;const p:TVariantArray):variant
      begin result:=VObject(TComponent(o).Components[p[0]]) end);
    AddObjectFunction(TComponent,'ComponentCount',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TComponent(o).ComponentCount end);
    AddObjectFunction(TComponent,'ComponentIndex',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TComponent(o).ComponentIndex end, procedure(const o:TObject;const p:TVariantArray;const v:variant)
      begin TComponent(o).ComponentIndex:=v end);
    AddSet(TypeInfo(TComponentState));
    AddObjectFunction(TComponent,'ComponentState',function(const o:TObject;const p:TVariantArray):variant
      var cs:TComponentState;begin cs:=TComponent(o).ComponentState;result:=VSetOrdinal(pByte(@cs)^,TypeInfo(TComponentState)) end);
    AddSet(TypeInfo(TComponentStyle));
    AddObjectFunction(TComponent,'ComponentStyle',function(const o:TObject;const p:TVariantArray):variant
      var cs:TComponentStyle;begin cs:=TComponent(o).ComponentStyle;result:=VSetOrdinal(pByte(@cs)^,TypeInfo(TComponentStyle)) end);
    AddObjectFunction(TComponent,'Owner',function(const o:TObject;const p:TVariantArray):variant
      begin result:=VObject(TComponent(o).Owner)end);

(*    //TBasicActionLink
    AddClass(TBasicActionLink);
    AddObjectConstructor(TBasicActionLink,'Create(AClient)',function(const p:TVariantArray):TObject
      begin result:=TBasicActionLink.Create(VarAsObject(p[0]))end);

    AddObjectFunction(TBasicActionLink,'Execute(AClient=nil)',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TBasicActionLink(o).Execute(TComponent(VarAsObject(p[0],TComponent)))end);
    AddObjectFunction(TBasicActionLink,'Update',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TBasicActionLink(o).Update end);
    AddObjectFunction(TBasicActionLink,'Action',function(const o:TObject;const p:TVariantArray):variant
      begin result:=VObject(TBasicActionLink(o).Action) end);

    //TBasicAction
    AddClass(TBasicAction);
    AddObjectConstructor(TBasicAction,'Create(AOwner)',function(const p:TVariantArray):TObject
      begin result:=TBasicAction.Create(TComponent(VarAsObject(p[0],TComponent)))end);

    AddObjectFunction(TBasicAction,'HandlesTarget(Target)',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TBasicAction(o).HandlesTarget(VarAsObject(p[0]))end);
    AddObjectFunction(TBasicAction,'UpdateTarget(Target)',function(const o:TObject;const p:TVariantArray):variant
      begin TBasicAction(o).UpdateTarget(VarAsObject(p[0]))end);
    AddObjectFunction(TBasicAction,'ExecuteTarget(Target)',function(const o:TObject;const p:TVariantArray):variant
      begin TBasicAction(o).ExecuteTarget(VarAsObject(p[0]))end);
    AddObjectFunction(TBasicAction,'Execute',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TBasicAction(o).Execute end);
    AddObjectFunction(TBasicAction,'RegisterChanges(Link)',function(const o:TObject;const p:TVariantArray):variant
      begin TBasicAction(o).RegisterChanges(TBasicActionLink(VarAsObject(p[0],TBasicActionLink)))end);
    AddObjectFunction(TBasicAction,'UnRegisterChanges(Link)',function(const o:TObject;const p:TVariantArray):variant
      begin TBasicAction(o).UnRegisterChanges(TBasicActionLink(VarAsObject(p[0],TBasicActionLink)))end);
    AddObjectFunction(TBasicAction,'Update',function(const o:TObject;const p:TVariantArray):variant
      begin result:=TBasicAction(o).Update end);
    AddObjectFunction(TBasicAction,'ActionComponent',function(const o:TObject;const p:TVariantArray):variant
      begin result:=VObject(TBasicAction(o).ActionComponent) end);*)

    //TDataModule
    AddClass(TDataModule);
    AddObjectConstructor(TDataModule,'Create(AOwner)',function(const p:TVariantArray):TObject
      begin result:=TDataModule.Create(TComponent(VarAsObject(p[0],TComponent)))end);

    AddClass(THetObject);
    AddClass(THetObjectList);
    AddObjectFunction(THetObjectList,'Count',function(const o:TObject;const p:TVariantArray):variant
      begin result:=THetObjectList(o).Count end);
    AddDefaultObjectFunction(THetObjectList,'ByIndex[idx]',function(const o:TObject;const p:TVariantArray):variant
      begin result:=VObject(THetObjectList(o).GetHetObjByIndex(p[0]))end);
    AddObjectFunction(THetObjectList,'ByID[idx]',function(const o:TObject;const p:TVariantArray):variant
      begin result:=VObject(THetObjectList(o).GetHetObjByID(p[0]))end);
    AddObjectFunction(THetObjectList,'ByName[name]',function(const o:TObject;const p:TVariantArray):variant
      begin result:=VObject(THetObjectList(o).GetHetObjByName(p[0]))end);

  end;
end;

initialization
  nsClasses:=MakeNameSpace;
  RegisterNameSpace(nsClasses);
end.
