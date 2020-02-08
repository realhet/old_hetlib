unit het.Bind; //het.Parser   //unsSystem   het.objects

interface

uses Windows, SysUtils, het.Utils, classes, controls, forms, het.Objects,
  stdctrls, extctrls, comctrls, CheckLst, Variants, het.Variants, UHetSlider,
  Spin, UFloatSpinEdit;

type
  TBindingHandlerCommand=(
    bcAddEvents,bcRemoveEvents,
    bcRefresh,
    bcGetFocusedListObject,bcSetFocusedListObject,
    bcSetReadOnly);

  TBinding=class;

  TBindingHandler=class
  private
    FBinding:TBinding;
    FOldOnChange:TNotifyEvent;//default onchange for every controls
  public
    procedure ChangeNotifierEvent(sender:TObject);virtual;
    class function ControlClass:TClass;virtual;abstract;
    property Binding:TBinding read FBinding;
    constructor Create(const ABinding:TBinding);virtual;
    procedure DoCommand(const cmd:TBindingHandlerCommand;var Param:variant);overload;virtual;abstract;
    function DoCommand(const cmd:TBindingHandlerCommand):Variant;overload;
  end;

  TBindingHandlerClass=class of TBindingHandler;

  TListBoxBindingHandler=class(TBindingHandler)
  public
    class function ControlClass:TClass;override;
    procedure DoCommand(const cmd:TBindingHandlerCommand;var Param:variant);override;
  end;

  TComboBoxBindingHandler=class(TBindingHandler)
  private
    FOldOnChange2:TNotifyEvent;
  public
    class function ControlClass:TClass;override;
    procedure DoCommand(const cmd:TBindingHandlerCommand;var Param:variant);override;
    procedure ChangeNotifierEvent(sender:TObject);override;
  end;

  TComboBoxExBindingHandler=class(TBindingHandler)
  public
    class function ControlClass:TClass;override;
    procedure DoCommand(const cmd:TBindingHandlerCommand;var Param:variant);override;
  end;

  TColorBoxBindingHandler=class(TBindingHandler)
  private
    FOldOnChange2:TNotifyEvent;
  public
    class function ControlClass:TClass;override;
    procedure DoCommand(const cmd:TBindingHandlerCommand;var Param:variant);override;
    procedure ChangeNotifierEvent(sender:TObject);override;
  end;

  TListViewBindingHandler=class(TBindingHandler)
  private
    FOldLVOnChange:TLVChangeEvent;
    FSettingsLoaded:boolean;
    FOwnChange:boolean;
    procedure LVOnChange(Sender: TObject; Item: TListItem; Change: TItemChange);
  public
    class function ControlClass:TClass;override;
    procedure DoCommand(const cmd:TBindingHandlerCommand;var Param:variant);override;
  end;

  TEditBindingHandler=class(TBindingHandler)
  private
    FOldOnExit:TNotifyEvent;
  public
    class function ControlClass:TClass;override;
    procedure DoCommand(const cmd:TBindingHandlerCommand;var Param:variant);override;
    procedure ChangeNotifierEvent(sender:TObject);override;
  end;

  TSpinEditBindingHandler=class(TBindingHandler)
  private
    FOldOnExit:TNotifyEvent;
  public
    class function ControlClass:TClass;override;
    procedure DoCommand(const cmd:TBindingHandlerCommand;var Param:variant);override;
    procedure ChangeNotifierEvent(sender:TObject);override;
  end;

  TFloatSpinEditBindingHandler=class(TBindingHandler)
  private
    FOldOnExit:TNotifyEvent;
  public
    class function ControlClass:TClass;override;
    procedure DoCommand(const cmd:TBindingHandlerCommand;var Param:variant);override;
    procedure ChangeNotifierEvent(sender:TObject);override;
  end;

  TMemoBindingHandler=class(TBindingHandler)
  private
    FOldOnExit:TNotifyEvent;
  public
    class function ControlClass:TClass;override;
    procedure DoCommand(const cmd:TBindingHandlerCommand;var Param:variant);override;
    procedure ChangeNotifierEvent(sender:TObject);override;
  end;

  TStaticTextBindingHandler=class(TBindingHandler)
  public
    class function ControlClass:TClass;override;
    procedure DoCommand(const cmd:TBindingHandlerCommand;var Param:variant);override;
  end;

  TCheckBoxBindingHandler=class(TBindingHandler)
  public
    class function ControlClass:TClass;override;
    procedure DoCommand(const cmd:TBindingHandlerCommand;var Param:variant);override;
    procedure ChangeNotifierEvent(sender:TObject);override;
  end;

  TCheckListBoxBindingHandler=class(TBindingHandler)
  public
    DataIsString:boolean;
    class function ControlClass:TClass;override;
    procedure DoCommand(const cmd:TBindingHandlerCommand;var Param:variant);override;
    procedure ChangeNotifierEvent(sender:TObject);override;
  end;

  TSliderBindingHandler=class(TBindingHandler)
  public
    Block:boolean;
    IgnoreChange:boolean;
    class function ControlClass:TClass;override;
    procedure DoCommand(const cmd:TBindingHandlerCommand;var Param:variant);override;
    procedure ChangeNotifierEvent(sender:TObject);override;
  end;

  TBindingFreeNotifier=class;
  TBinding=class(THetObject)
  private
    FHandler:TBindingHandler;
    FControl:TControl;
    FFreeNotifier:TBindingFreeNotifier;

    //ListBinding
    FListSource:THetObject;
    FListExpr:ansistring;
    FListIconExpr:ansistring;

    //DataBinding
    FDataSource:TObject;
    FDataExpr:ansistring;

    FNeedRefresh:boolean;
    FAlwaysRefresh:boolean;

    procedure SetListSource(const Value:THetObject);
    procedure SetListExpr(const Value:ansistring);
    procedure SetListIconExpr(const Value:ansistring);

    procedure SetDataSource(const Value:TObject);
    procedure SetDataExpr(const Value:ansistring);
    function GetControlAsInt:integer;
    procedure SetAlwaysRefresh(const Value: boolean);
  public
    constructor Create(const AControl:TControl;
                       const ADataSource:TObject;   const ADataExpr:ansistring;
                       const AListSource:THetObject;const AListExpr:ansistring;const AListIconExpr:ansistring='');reintroduce;
    destructor Destroy;override;

    procedure ObjectChanged(const AObj: THetObject;const AChangeType:TChangeType);override;

    procedure RefreshNow;
    procedure RefreshIfNeeded;
    procedure RefreshLater;
    property Control:TControl read FControl;
    function ControlIsFocused:boolean;virtual;

    function DataSourceObject:TObject;

    function GetFocusedListObject:TObject;
    procedure SetFocusedListObject(const AObject:TObject);
    property FocusedListObject:TObject read GetFocusedListObject write SetFocusedListObject;

    procedure SetControlReadOnly(const AValue:boolean);
    property ControlReadOnly:boolean write SetControlReadOnly;

    function Debug:ansistring;

    function EvalStr(const Def:ansistring=''):ansistring;
    function EvalInt(const Def:integer=0):integer;
    function EvalFloat(const Def:double=0):double;
    function EvalBool(const Def:boolean=false):boolean;
    procedure Let(const Val: variant);
  published
    property ListSource:THetObject read FListSource write SetListSource;
    property ListExpr:ansistring read FListExpr write SetListExpr;
    property ListIconExpr:ansistring read FListIconExpr write SetListIconExpr;
    property DataSource:TObject read FDataSource write SetDataSource;
    property DataExpr:ansistring read FDataExpr write SetDataExpr;
    property ControlAsInt:integer read GetControlAsInt;
    property AlwaysRefresh:boolean read FAlwaysRefresh write SetAlwaysRefresh;
  end;

  TBindingFreeNotifier=class(TComponent)
  public
    FBinding:TBinding;
    procedure Notification(AComponent: TComponent;Operation: TOperation);override;
  end;

  TBindings=class(THetList<TBinding>)
  public
    UpdateTimer:TTimer;
    FNeedRefresh:boolean;

    constructor Create(const AOwner:THetObject);override;
    destructor Destroy;override;

    procedure OnUpdateTimer(Sender:TObject);
    procedure RefreshIfNeeded;
  end;

var
  Bindings:TBindings;

procedure RegisterBindingHandler(const AHandler:TBindingHandlerClass);
function FindBindingHandler(const AControlClass:TClass):TBindingHandlerClass;

function Bind(const AControl:TControl;const ADataSource:TObject;const ADataExpr:ansistring;const AListSource:THetObject=nil;const AListExpr:ansistring='';const AListIconExpr:ansistring=''):TBinding;overload;
function BindingOf(const AControl:TControl):TBinding;
function UnBind(const AControl:TControl):boolean;

procedure FillStrings(const ST:TStrings;const List:THetObjectList;const Expr:ansistring;var AItemIndex:integer);
procedure FillListBox(const LB:TListBox;const List:THetObjectList;const expr:ansistring);
procedure FillComboBox(const CB:TComboBox;const List:THetObjectList;const expr:ansistring);
procedure FillComboBoxEx(const CB:TComboBoxEx;const List:THetObjectList;const expr,iconexpr:ansistring);
procedure FillListView(const LV:TListView;const List:THetObjectList;const expr:ansistring);

procedure LoadListViewSettings(const LV:TListView);overload;
procedure LoadListViewSettings(const Frm:TForm);overload;

procedure SaveListViewSettings(const LV:TListView);overload;
procedure SaveListViewSettings(const Frm:TForm);overload;

implementation

uses
  het.Parser, unsSystem, inifiles;

var
  BindingHandlers:array of TBindingHandlerClass;

function FindBindingHandler(const AControlClass:TClass):TBindingHandlerClass;

  function ClassIs(const a,b:TClass):boolean;  //faster version
  begin
    if(a=nil)or(b=nil)then exit(false)
    else if a=b then exit(true)
    else begin
      if a=TControl then exit(false);  //ennel lejjebb nem keresunk
      result:=ClassIs(a.ClassParent,b);
    end;
  end;


var i:integer;
begin
  for i:=High(BindingHandlers)downto 0 do if BindingHandlers[i].ControlClass=AControlClass then
    exit(BindingHandlers[i]);
  for i:=High(BindingHandlers)downto 0 do if ClassIs(AControlClass,BindingHandlers[i].ControlClass)then
    exit(BindingHandlers[i]);
  result:=nil;
end;

procedure RegisterBindingHandler(const AHandler:TBindingHandlerClass);
var i:integer;
begin
  for i:=0 to high(BindingHandlers)do if BindingHandlers[i]=AHandler then exit;
  SetLength(BindingHandlers,length(BindingHandlers)+1);
  BindingHandlers[high(BindingHandlers)]:=AHandler;
end;

{ TBindingHandler }

constructor TBindingHandler.Create(const ABinding: TBinding);
begin
  FBinding:=ABinding;
end;

function TBindingHandler.DoCommand(const cmd: TBindingHandlerCommand): Variant;
begin
  result:=Unassigned;
  DoCommand(cmd,result);
end;

procedure TBindingHandler.ChangeNotifierEvent(sender:TObject);
begin
  if Assigned(FOldOnChange) then
    FOldOnChange(sender);
  Binding.NotifyChange;
end;

////////////////////////////////////////////////////////////////////////////////
/// Custom binding handlers                                                  ///
////////////////////////////////////////////////////////////////////////////////

{ TListBoxBindingHandler }

class function TListBoxBindingHandler.ControlClass:TClass;
begin
  result:=TListBox
end;

procedure TListBoxBindingHandler.DoCommand(const cmd:TBindingHandlerCommand;var Param:variant);
begin with Binding,TListBox(Control)do case cmd of
  bcAddEvents:begin FOldOnChange:=OnClick;OnClick:=ChangeNotifierEvent;end;
  bcRemoveEvents:begin OnClick:=FOldOnChange;end;
  bcRefresh:begin
    if ListExpr<>'' then FillListBox(TListBox(Control),THetObjectList(ListSource),ListExpr)
  end;
  bcGetFocusedListObject:if ItemIndex>=0 then Param:=VObject(Items.Objects[ItemIndex]);
  bcSetFocusedListObject:ItemIndex:=Items.IndexOfObject(VarAsObject(Param));
  bcSetReadOnly:Enabled:=not Param;
end;end;

{ TComboBoxBindingHandler }

class function TComboBoxBindingHandler.ControlClass:TClass;
begin
  result:=TComboBox
end;

procedure TComboBoxBindingHandler.DoCommand(const cmd:TBindingHandlerCommand;var Param:variant);
begin with Binding,TComboBox(Control)do case cmd of
  bcAddEvents:begin FOldOnChange:=OnClick;OnClick:=ChangeNotifierEvent;
                    FOldOnChange2:=OnChange;OnChange:=ChangeNotifierEvent;end;
  bcRemoveEvents:begin OnClick:=FOldOnChange;OnChange:=FOldOnChange2 end;
  bcRefresh:begin
    if ListExpr<>'' then FillComboBox(TComboBox(Control),THetObjectList(ListSource),ListExpr);
    if Style=csDropDownList then ItemIndex:=EvalInt(-1)
                            else Text:=EvalStr;
  end;
  bcGetFocusedListObject:if ItemIndex>=0 then Param:=VObject(Items.Objects[ItemIndex]);
  bcSetFocusedListObject:ItemIndex:=Items.IndexOfObject(VarAsObject(Param));
  bcSetReadOnly:Enabled:=not Param;
end;end;

procedure TComboBoxBindingHandler.ChangeNotifierEvent(sender:TObject);
begin with Binding,TComboBox(Control) do begin
  if Style=csDropDownList then Let(ItemIndex)
                          else Let(Text);
  inherited
end;end;

{ TComboBoxExBindingHandler }

class function TComboBoxExBindingHandler.ControlClass:TClass;
begin
  result:=TComboBoxEx
end;

procedure TComboBoxExBindingHandler.DoCommand(const cmd:TBindingHandlerCommand;var Param:variant);
begin with Binding,TComboBoxEx(Control)do case cmd of
  bcAddEvents:begin FOldOnChange:=OnClick;OnClick:=ChangeNotifierEvent;end;
  bcRemoveEvents:begin OnClick:=FOldOnChange;end;
  bcRefresh:begin
    if ListExpr<>'' then FillComboBoxEx(TComboBoxEx(Control),THetObjectList(ListSource),ListExpr,ListIconExpr);
  end;
  bcGetFocusedListObject:if ItemIndex>=0 then Param:=VObject(Items.Objects[ItemIndex]);
  bcSetFocusedListObject:ItemIndex:=Items.IndexOfObject(VarAsObject(Param));
  bcSetReadOnly:Enabled:=not Param;
end;end;

{ TColorBoxBindingHandler }

class function TColorBoxBindingHandler.ControlClass:TClass;
begin
  result:=TColorBox
end;

procedure TColorBoxBindingHandler.DoCommand(const cmd:TBindingHandlerCommand;var Param:variant);
begin with Binding,TColorBox(Control)do case cmd of
  bcAddEvents:begin FOldOnChange:=OnClick;OnClick:=ChangeNotifierEvent;
                    FOldOnChange2:=OnChange;OnChange:=ChangeNotifierEvent;end;
  bcRemoveEvents:begin OnClick:=FOldOnChange;OnChange:=FOldOnChange2 end;
  bcRefresh:if not ControlIsFocused then Selected:=EvalInt(0);
  bcSetReadOnly:Enabled:=not Param;
end;end;

procedure TColorBoxBindingHandler.ChangeNotifierEvent(sender:TObject);
begin with Binding,TColorBox(Control) do begin
  Let(Selected);
  inherited
end;end;

{ TListViewBindingHandler }

class function TListViewBindingHandler.ControlClass:TClass;
begin
  result:=TListView
end;

procedure TListViewBindingHandler.DoCommand(const cmd:TBindingHandlerCommand;var Param:variant);
var i:integer;
begin with Binding,TListView(Control)do case cmd of
  bcAddEvents:begin FOldLVOnChange:=OnChange;OnChange:=LVOnChange;end;
  bcRemoveEvents:begin OnChange:=FOldLVOnChange;end;
  bcRefresh:begin
    if CheckAndClear(FOwnChange) then exit;
    if ListExpr<>'' then begin
      FillListView(TListView(Control),THetObjectList(ListSource),ListExpr);
      if CheckAndSet(FSettingsLoaded)then
        LoadListViewSettings(TListView(Control));
    end;
  end;
  bcGetFocusedListObject:if ItemIndex>=0 then Param:=VObject(TObject(Items[ItemIndex].Data));
  bcSetFocusedListObject:begin
    for i:=0 to Items.Count-1 do
      if Items[i].Data=pointer(VarAsObject(Param))then begin
        ItemIndex:=i;exit;
      end;
    RefreshNow;//uj itemnel ujraprobalkozas
    for i:=0 to Items.Count-1 do
      if Items[i].Data=pointer(VarAsObject(Param))then begin
        ItemIndex:=i;exit;
      end;
  end;
  bcSetReadOnly:Enabled:=not Param;
end;end;

procedure TListViewBindingHandler.LVOnChange(Sender: TObject; Item: TListItem;Change: TItemChange);
begin
  FOwnChange:=true;
  ChangeNotifierEvent(Sender);
end;

{ TEditBindingHandler }

class function TEditBindingHandler.ControlClass:TClass;
begin
  result:=TEdit
end;

procedure TEditBindingHandler.DoCommand(const cmd:TBindingHandlerCommand;var Param:variant);
begin with Binding,TEdit(Control)do case cmd of
  bcAddEvents:begin FOldOnChange:=OnChange;OnChange:=ChangeNotifierEvent;
                    FOldOnExit:=OnExit;OnExit:=ChangeNotifierEvent;end;
  bcRemoveEvents:begin OnChange:=FOldOnChange;OnExit:=FOldOnExit;end;
  bcRefresh:if not ControlIsFocused then Text:=EvalStr;
  bcSetReadOnly:ReadOnly:=Param;
end;end;

procedure TEditBindingHandler.ChangeNotifierEvent(sender:TObject);
begin with Binding,TEdit(Control) do begin
  Let(Text);
  inherited
end;end;

{ TSpinEditBindingHandler }

class function TSpinEditBindingHandler.ControlClass:TClass;
begin
  result:=TSpinEdit;
end;

procedure TSpinEditBindingHandler.DoCommand(const cmd:TBindingHandlerCommand;var Param:variant);
var v:variant;
begin with Binding,TSpinEdit(Control)do case cmd of
  bcAddEvents:begin FOldOnChange:=OnChange;OnChange:=ChangeNotifierEvent;
                    FOldOnExit:=OnExit;OnExit:=ChangeNotifierEvent;end;
  bcRemoveEvents:begin OnChange:=FOldOnChange;OnExit:=FOldOnExit;end;
  bcRefresh:begin
    if(DataSourceObject<>nil)and(DataExpr<>'')then try
       v:=PropQuery(pqRangeMin,DataExpr,DataSourceObject); if not VarIsNull(v)then MinValue:=v;
       v:=PropQuery(pqRangeMax,DataExpr,DataSourceObject); if not VarIsNull(v)then MaxValue:=v;
    except end;
    if not ControlIsFocused then Value:=EvalInt;
  end;
  bcSetReadOnly:ReadOnly:=Param;
end;end;

procedure TSpinEditBindingHandler.ChangeNotifierEvent(sender:TObject);
begin with Binding,TSpinEdit(Control) do begin
  Let(Value);
  inherited
end;end;

{ TFloatSpinEditBindingHandler }

class function TFloatSpinEditBindingHandler.ControlClass:TClass;
begin
  result:=TFloatSpinEdit;
end;

procedure TFloatSpinEditBindingHandler.DoCommand(const cmd:TBindingHandlerCommand;var Param:variant);
var v:variant;
begin with Binding,TFloatSpinEdit(Control)do case cmd of
  bcAddEvents:begin FOldOnChange:=OnChange;OnChange:=ChangeNotifierEvent;
                    FOldOnExit:=OnExit;OnExit:=ChangeNotifierEvent;end;
  bcRemoveEvents:begin OnChange:=FOldOnChange;OnExit:=FOldOnExit;end;
  bcRefresh:begin
    if(DataSourceObject<>nil)and(DataExpr<>'')then try
       v:=PropQuery(pqRangeMin,DataExpr,DataSourceObject); if not VarIsNull(v)then MinValue:=v;
       v:=PropQuery(pqRangeMax,DataExpr,DataSourceObject); if not VarIsNull(v)then MaxValue:=v;
    except end;
    if not ControlIsFocused then Value:=EvalFloat;
  end;
  bcSetReadOnly:ReadOnly:=Param;
end;end;

procedure TFloatSpinEditBindingHandler.ChangeNotifierEvent(sender:TObject);
begin with Binding,TFloatSpinEdit(Control) do begin
  Let(Value);
  inherited
end;end;

{ TMemoBindingHandler }

class function TMemoBindingHandler.ControlClass:TClass;
begin
  result:=TMemo
end;

procedure TMemoBindingHandler.DoCommand(const cmd:TBindingHandlerCommand;var Param:variant);
begin with Binding,TMemo(Control)do case cmd of
  bcAddEvents:begin FOldOnChange:=OnChange;OnChange:=ChangeNotifierEvent;
                    FOldOnExit:=OnExit;OnExit:=ChangeNotifierEvent;end;
  bcRemoveEvents:begin OnChange:=FOldOnChange;OnExit:=FOldOnExit;end;
  bcRefresh:if not ControlIsFocused then Text:=EvalStr;
  bcSetReadOnly:ReadOnly:=Param;
end;end;

procedure TMemoBindingHandler.ChangeNotifierEvent(sender:TObject);
begin with Binding,TMemo(Control) do begin
  Let(Text);
  inherited
end;end;

{ TStaticTextBindingHandler }

class function TStaticTextBindingHandler.ControlClass:TClass;
begin
  result:=TStaticText
end;

procedure TStaticTextBindingHandler.DoCommand(const cmd:TBindingHandlerCommand;var Param:variant);
begin with Binding,TStaticText(Control)do case cmd of
  bcAddEvents:;
  bcRemoveEvents:;
  bcRefresh:Caption:=EvalStr;
  bcSetReadOnly:;
end;end;

{ TCheckBoxBindingHandler }

class function TCheckBoxBindingHandler.ControlClass:TClass;
begin
  result:=TCheckBox
end;

procedure TCheckBoxBindingHandler.DoCommand(const cmd:TBindingHandlerCommand;var Param:variant);
begin with Binding,TCheckBox(Control)do case cmd of
  bcAddEvents:begin FOldOnChange:=OnClick;OnClick:=ChangeNotifierEvent;end;
  bcRemoveEvents:begin OnClick:=FOldOnChange;end;
  bcRefresh:if not ControlIsFocused then Checked:=EvalBool;
  bcSetReadOnly:Enabled:=not Param;
end;end;

procedure TCheckBoxBindingHandler.ChangeNotifierEvent(sender:TObject);
begin with Binding,TCheckBox(Control) do begin
  Let(Checked);
  inherited
end;end;

{ TCheckListBoxBindingHandler }

class function TCheckListBoxBindingHandler.ControlClass:TClass;
begin
  result:=TCheckListBox
end;

procedure TCheckListBoxBindingHandler.DoCommand(const cmd:TBindingHandlerCommand;var Param:variant);
var i,mask:integer;v:variant;s:ansistring;
begin with Binding,TCheckListBox(Control)do case cmd of
  bcAddEvents:begin FOldOnChange:=OnClickCheck;OnClickCheck:=ChangeNotifierEvent;end;
  bcRemoveEvents:begin OnClickCheck:=FOldOnChange;end;
  bcRefresh:begin if{ not ControlIsFocused } true then begin
    try
      if ListExpr<>'' then
        FillListBox(TListBox(Control),THetObjectList(ListSource),ListExpr);
      if DataExpr<>'' then begin
        if DataSourceObject=nil then
          v:=0
        else
          v:=Eval(DataExpr,DataSourceObject);

        if VarIsOrdinal(v)then begin//integer mask
          DataIsString:=false;
          mask:=v;
          for i:=0 to Items.Count-1 do
            Checked[i]:=(mask and(1 shl i))<>0;
        end else if VarIsStr(v) then begin//string list ,
          DataIsString:=true;
          s:=v;
          for i:=0 to Items.Count-1 do
            Checked[i]:=ListFind(s,Items[i],',')>=0;
        end;
      end;
    except
    end;end;
  end;
  bcSetReadOnly:Enabled:=not Param;
end;end;

procedure TCheckListBoxBindingHandler.ChangeNotifierEvent(sender:TObject);
var i,mask:integer;s:ansistring;v:variant;
begin with Binding,TCheckListBox(Control) do begin
  try
    if DataIsString then begin
      s:='';
      for i:=0 to Items.Count-1 do
        if Checked[i] then begin
          if s<>'' then s:=s+',';
          s:=s+Items[i];
        end;
      v:=s;
    end else begin
      mask:=0;
      for i:=0 to Items.Count-1 do
        if Checked[i] then
          mask:=mask or 1 shl i;
      v:=mask;
    end;
    Let(v);
  except end;
  inherited
end;end;

{ TSliderBindingHandler }

class function TSliderBindingHandler.ControlClass:TClass;
begin
  result:=TSlider
end;

procedure TSliderBindingHandler.DoCommand(const cmd:TBindingHandlerCommand;var Param:variant);
var v:variant;
begin with Binding,TSlider(Control)do case cmd of
  bcAddEvents:begin FOldOnChange:=OnChange;OnChange:=ChangeNotifierEvent;end;
  bcRemoveEvents:begin OnChange:=FOldOnChange;end;
  bcRefresh:begin
    IgnoreChange:=true;
    if(DataSourceObject<>nil)and(DataExpr<>'')then try
       v:=PropQuery(pqRangeMin,DataExpr,DataSourceObject); if not VarIsNull(v)then Min:=v;
       v:=PropQuery(pqRangeMax,DataExpr,DataSourceObject); if not VarIsNull(v)then Max:=v;
    except end;
    IgnoreChange:=false;
    if not Block then Value:=EvalFloat;
  end;
  bcSetReadOnly:Enabled:=not Param;
end;end;

procedure TSliderBindingHandler.ChangeNotifierEvent(sender:TObject);
begin with Binding,TSlider(Control) do begin
  if IgnoreChange then exit;

  Block:=true;
  Let(Value);
  Block:=false;
  inherited
end;end;


const
  lvIniFileName='settings\ViewSettings.ini';

procedure LoadListViewSettings(const LV:TListView);overload;
var ini:TIniFile;
    c:TCollectionItem;
    b:TBinding;
begin
  if not FileExists(AppPath+lvIniFileName) then exit;

  b:=BindingOf(LV);
  if b<>nil then begin
    b.RefreshNow;
  end;

  ini:=TIniFile.Create(AppPath+lvIniFileName);
  try
    for c in LV.Columns do with TListColumn(c)do
      Width:=ini.ReadInteger(LV.Owner.Name+'.'+LV.Name,Caption+'.Width',Width);
  finally
    FreeAndNil(ini);
  end;
end;

procedure LoadListViewSettings(const Frm:TForm);overload;
var i:integer;
begin
  for i:=0 to Frm.ComponentCount-1 do if Frm.Components[i]is TListView then
    LoadListViewSettings(TListView(Frm.Components[i]));
end;

procedure SaveListViewSettings(const LV:TListView);overload;
var ini:TIniFile;
    c:TCollectionItem;
begin
  ini:=TIniFile.Create(AppPath+lvIniFileName);
  try
    for c in LV.Columns do with TListColumn(c)do
      ini.WriteInteger(LV.Owner.Name+'.'+LV.Name,Caption+'.Width',Width);
  finally
    ini.UpdateFile;
    FreeAndNil(ini);
  end;
end;

procedure SaveListViewSettings(const Frm:TForm);overload;
var i:integer;
begin
  for i:=0 to Frm.ComponentCount-1 do if Frm.Components[i]is TListView then begin
    SaveListViewSettings(TListView(Frm.Components[i]));
  end else if Frm.Components[i]is TFrame then
    SaveListViewSettings(TForm(Frm.Components[i]));
end;

procedure FillStrings(const ST:TStrings;const List:THetObjectList;const Expr:ansistring;var AItemIndex:integer);
var i:integer;
    o:THetObject;
    n:TNodeBase;ns:TNameSpace;ctx:TContext;
    FocusedObj:TObject;
begin
  if not(List is THetObjectList) then exit;

  if AItemIndex>=0 then FocusedObj:=ST.Objects[AItemIndex]
                   else FocusedObj:=nil;
  AItemIndex:=-1;

  ST.BeginUpdate;
  ns:=TNameSpace.Create('bind');
  ns.nsUses.Append(nsSystem);
  Ctx:=TContext.Create(nil,ns,nil);
  Ctx.WithStack.Append(nil);
  n:=CompilePascalProgram(Expr,ns);
  try
    for i:=ST.Count-1 downto List.Count do
      ST.Delete(i);
    if n<>nil then for i:=0 to List.Count-1 do begin
      o:=List.ByIndex[i];
      if o=FocusedObj then AItemIndex:=i;
      ctx.WithStack.FItems[0]:=o;
      if ST.Count>i then begin
        ST[i]:=n.Eval(ctx);
        ST.Objects[i]:=o
      end else
        ST.AddObject(n.Eval(ctx),o);
    end;
  finally
    n.Free;
    ctx.Free;
    ns.Free;
    ST.EndUpdate;
  end;
end;

procedure FillListBox(const LB:TListBox;const List:THetObjectList;const Expr:ansistring);
var Idx:integer;
begin
  Idx:=LB.ItemIndex;
  FillStrings(LB.Items,List,Expr,Idx);
  if (Idx>=0)and(LB.ItemIndex<>Idx)then LB.ItemIndex:=Idx;
end;

procedure FillComboBox(const CB:TComboBox;const List:THetObjectList;const Expr:ansistring);
var Idx:integer;
begin
  Idx:=CB.ItemIndex;
  FillStrings(CB.Items,List,Expr,Idx);
  if (Idx>=0)and(CB.ItemIndex<>Idx)then CB.ItemIndex:=Idx;
end;

procedure FillComboBoxEx(const CB:TComboBoxEx;const List:THetObjectList;const Expr,IconExpr:ansistring);
var i,idx:integer;
    o:THetObject;
    n,nIcon:TNodeBase;ns:TNameSpace;ctx:TContext;
    FocusedObj:TObject;
    ST:TComboExItems;
    IT:TComboExItem;
begin
  if not(List is THetObjectList) then exit;
  ST:=CB.ItemsEx;

  idx:=CB.ItemIndex;
  if idx>=0 then FocusedObj:=CB.Items.Objects[idx]
            else FocusedObj:=nil;
  idx:=-1;

  ST.BeginUpdate;
  ns:=TNameSpace.Create('bind');
  ns.nsUses.Append(nsSystem);
  Ctx:=TContext.Create(nil,ns,nil);
  Ctx.WithStack.Append(nil);
  n:=CompilePascalProgram(Expr,ns);
  if IconExpr<>'' then nIcon:=CompilePascalProgram(IconExpr,ns)
                  else nIcon:=nil;
  try
    for i:=ST.Count-1 downto List.Count do
      ST.Delete(i);
    for i:=0 to List.Count-1 do begin
      o:=List.ByIndex[i];
      if o=FocusedObj then idx:=i;
      ctx.WithStack.FItems[0]:=o;
      if ST.Count>i then IT:=TComboExItem(ST.Items[i])
                    else IT:=ST.Add;
      with IT do begin
        if n<>nil then Caption:=n.Eval(ctx)
                  else Caption:='hetobj'+inttohex(integer(o),8);
        if nIcon<>nil then ImageIndex:=nIcon.Eval(ctx)
                      else ImageIndex:=-1;
        Data:=o;
      end;
    end;
  finally
    n.Free;
    nIcon.Free;
    ctx.Free;
    ns.Free;
    ST.EndUpdate;
  end;

  if(idx>=0)and(CB.ItemIndex<>idx)then CB.ItemIndex:=idx;
end;

procedure FillListView(const LV:TListView;const List:THetObjectList;const expr:ansistring);
var i,idx:integer;
    LI:TListItems;
    IT:TListItem;
    o,FocusedObj:THetObject;
    n,nIcon:TNodeBase;ns:TNameSpace;ctx:TContext;
//    err:ansistring;

    isArrayConstruct:boolean;
    columnCount:Integer;

  function ColumnNode(i:integer;TryGetName:boolean):TNodeBase;
  begin
    if isArrayConstruct then result:=TNodeArrayConstruct(n).SubNode(i)
                        else result:=n;
    if(result<>nil)and(Result is TNodeNamedVariant)then
      result:=TNodeNamedVariant(result).SubNode(switch(TryGetName,0,1));
  end;

  function ColumnCaption(i:integer):AnsiString;
  var resNode:TNodeBase;
  begin
    resNode:=ColumnNode(i,true);

    if(resNode<>nil)and(resNode is TNodeIdentifier)then
      result:=TNodeIdentifier(resNode).IdName
    else
      result:='Calc'+inttostr(i);
  end;

  function ColumnReadOnly(i:integer):boolean;
  var resNode:TNodeBase;
  begin
    resNode:=ColumnNode(i,true);

    result:=not((resNode<>nil)and(resNode is TNodeIdentifier));
  end;

var
  ColumnNodes:array of TNodeBase;
  nFirst:TNodeBase;
  s:ansistring;
  j:integer;

begin
  if not(List is THetObjectList) then exit;

  LI:=LV.Items;

  idx:=LV.ItemIndex;
  if idx>=0 then FocusedObj:=THetObject(LI[idx].Data)
            else FocusedObj:=nil;
  idx:=-1;

  LI.BeginUpdate;
  ns:=TNameSpace.Create('bind');
  ns.nsUses.Append(nsSystem);
  Ctx:=TContext.Create(nil,ns,nil);
  Ctx.WithStack.Append(nil);

  n:=CompilePascalProgram(Expr,ns);
  isArrayConstruct:=(n<>nil)and(n is TNodeArrayConstruct);
  if isArrayConstruct then ColumnCount:=TNodeArrayConstruct(n).SubNodeCount
                      else columnCount:=1;

  setlength(ColumnNodes,columnCount);
  LV.Columns.BeginUpdate;
  try
    for i:=0 to high(ColumnNodes)do begin
      if LV.Columns.Count<=i then
        LV.Columns.Add;
      ColumnNodes[i]:=ColumnNode(i,false);
      LV.Columns[i].Caption:=ColumnCaption(i);
      LV.Columns[i].Tag:=integer(ColumnNodes[i]);
    end;
    while LV.Columns.Count>Length(ColumnNodes)do
      LV.Columns.Delete(LV.Columns.Count-1);
  finally
    LV.Columns.EndUpdate;
  end;

{  if IconExpr<>'' then nIcon:=CompilePascalStatement(IconExpr,ns,err)
                  else} nIcon:=nil;
  nFirst:=ColumnNodes[0];
  try
    for i:=LI.Count-1 downto List.Count do
      LI.Delete(i);
    for i:=0 to List.Count-1 do begin
      o:=List.ByIndex[i];
      if o=FocusedObj then idx:=i;
      ctx.WithStack.FItems[0]:=o;
      if LI.Count>i then IT:=LI[i]
                    else IT:=LI.Add;
      with IT do begin
        if nFirst<>nil then Caption:=nFirst.Eval(ctx)
                       else Caption:='hetobj'+inttohex(integer(o),8);
        Data:=o;
        for j:=1 to high(ColumnNodes)do begin
          if ColumnNodes[j]<>nil then s:=ColumnNodes[j].Eval(ctx)
                                 else s:='null';
          if IT.SubItems.Count<=j-1 then
            IT.SubItems.Add(s)
          else
            IT.SubItems[j-1]:=s;
        end;
        while IT.SubItems.Count>length(ColumnNodes)-1 do
          IT.SubItems.Delete(IT.SubItems.Count-1);
      end;
    end;
  finally
    n.Free;
    nIcon.Free;
    ctx.Free;
    ns.Free;
    LI.EndUpdate;
  end;

  if(idx>=0)and(LV.ItemIndex<>idx)then LV.ItemIndex:=idx;

  //AllwaysFocusRow
  if(LV.ItemIndex<0)and(LV.Items.Count>0)then
    LV.ItemIndex:=0;
end;

procedure TBindingFreeNotifier.Notification(AComponent: TComponent;Operation: TOperation);
begin
  if Operation=opRemove then
    FBinding.Free;
end;

function TBinding.ControlIsFocused: boolean;
var o:TComponent;
begin
  if Control is TWinControl then with TWinControl(Control)do result:=Focused
                            else exit(false);

  if result then begin
    if not Application.Active then exit(false);

    o:=Control;
    repeat
      o:=o.Owner;
      if o=nil then exit;
      if o is(TForm)then if not(TForm(o).Active)then exit(false);
    until false;
  end;
end;

constructor TBinding.Create(const AControl:TControl;const ADataSource:TObject;const ADataExpr:ansistring;const AListSource:THetObject;const AListExpr:ansistring;const AListIconExpr:ansistring='');
var HandlerClass:TBindingHandlerClass;
begin
  HandlerClass:=FindBindingHandler(AControl.ClassType);
  if HandlerClass=nil then
    raise Exception.Create('TBinding.Create() unable to bind on '+AControl.ClassName);

  inherited Create(Bindings);
  FControl:=AControl;

  FListSource:=AListSource;
  FListExpr:=AListExpr;
  FListIconExpr:=AListIconExpr;

  FDataSource:=ADataSource;
  FDataExpr:=ADataExpr;

  FFreeNotifier:=TBindingFreeNotifier.Create(nil);
  FFreeNotifier.FBinding:=self;
  if Assigned(Control)then
    Control.FreeNotification(FFreeNotifier);

  if Assigned(ListSource)and(ListSource is THetObject)then
    THetObject(ListSource)._AddReference(self);

  if Assigned(DataSource)and(DataSource is THetObject) then
    THetObject(DataSource)._AddReference(self);

  FHandler:=HandlerClass.Create(self);
  FHandler.DoCommand(bcAddEvents);

  NotifyChange;
  RefreshLater;
end;

function TBinding.DataSourceObject: TObject;
begin
  result:=FDataSource;
  if result=nil then exit;
  if result is TBinding then
    result:=TBinding(result).GetFocusedListObject;
end;

function TBinding.Debug: ansistring;
begin
  result:='('+Control.Name+','+tostr(controlAsInt)+','+ListExpr+','+DataExpr+')';
end;

destructor TBinding.Destroy;
begin
  if Assigned(ListSource)and(ListSource is THetObject)then
    THetObject(ListSource)._RemoveReference(self);
  if Assigned(DataSource)and(DataSource is THetObject)then
    THetObject(DataSource)._RemoveReference(self);

  if Control<>nil then begin
    FHandler.DoCommand(bcRemoveEvents);
    Control.RemoveFreeNotification(FFreeNotifier);
  end;
  FreeAndNil(FFreeNotifier);

  FreeAndNil(FHandler);

  inherited;
end;

function TBinding.GetControlAsInt: integer;
begin
  Result:=integer(Control);
end;

function TBinding.GetFocusedListObject: TObject;
var res:Variant;
begin
  RefreshIfNeeded;
  FHandler.DoCommand(bcGetFocusedListObject,res);
  if res=Unassigned then result:=nil
                    else result:=VarAsObject(res);
end;

procedure TBinding.SetFocusedListObject(const AObject: TObject);
var param:Variant;
begin
  if FocusedListObject=AObject then exit;
  Param:=VObject(AObject);
  FHandler.DoCommand(bcSetFocusedListObject,Param);
end;

procedure TBinding.ObjectChanged(const AObj: THetObject;const AChangeType:TChangeType);
begin
  inherited;
//  if(AObj=FListSource)or(AObj=FDataSource)then  //nem kell leszikuteni!

  if AChangeType=ctDestroy then begin
    if TObject(AObj)=FDataSource then FDataSource:=nil;
    if TObject(AObj)=FListSource then FListSource:=nil;
  end;

  RefreshLater;
end;

function TBinding.EvalFloat(const Def: double=0): double;
begin
  try if(DataSourceObject=nil)or(DataExpr='')then result:=Def else result:=Eval(DataExpr,DataSourceObject);
  except result:=Def;end;
end;

function TBinding.EvalInt(const Def: integer=0): integer;
begin
  try if(DataSourceObject=nil)or(DataExpr='')then result:=Def else result:=Eval(DataExpr,DataSourceObject);
  except result:=Def;end;
end;

function TBinding.EvalStr(const Def: ansistring=''): ansistring;
begin
  try if(DataSourceObject=nil)or(DataExpr='')then result:=Def else result:=Eval(DataExpr,DataSourceObject);
  except result:=Def;end;
end;

function TBinding.EvalBool(const Def: boolean=false): boolean;
begin
  try if(DataSourceObject=nil)or(DataExpr='')then result:=Def else result:=Eval(DataExpr,DataSourceObject);
  except result:=Def;end;
end;

procedure TBinding.Let(const Val:variant);
begin
  try if(DataExpr<>'')and(DataSourceObject<>nil)then het.Parser.Let(DataExpr,Val,DataSourceObject)except end;
end;

{$O-}
procedure TBinding.SetListExpr(const Value:ansistring);begin end;
procedure TBinding.SetListIconExpr(const Value:ansistring);begin end;
procedure TBinding.SetDataSource(const Value:TObject);begin end;
procedure TBinding.SetDataExpr(const Value:ansistring);begin end;
procedure TBinding.SetAlwaysRefresh(const Value: boolean);begin end;
{$O+}

procedure TBinding.SetListSource(const Value:THetObject);

  procedure ReplaceListSource(const ANewSrc: THetObject);
  begin
    if FListSource<>nil then FListSource._RemoveReference(self);
    if ANewSrc<>nil then ANewSrc._AddReference(self);
    FListSource:=ANewSrc;
    RefreshLater;
  end;

begin
  ReplaceListSource(Value);
  NotifyChange;
end;

procedure TBinding.RefreshNow;
begin
  if Control=nil then exit;
  if csDestroying in Control.ComponentState then exit;

  FHandler.DoCommand(bcRefresh);
end;

procedure TBinding.RefreshIfNeeded;
begin
  if FNeedRefresh or FAlwaysRefresh then begin
    FNeedRefresh:=false;
    RefreshNow;
  end;
end;

procedure TBinding.RefreshLater;
begin
  if not FNeedRefresh then begin
    FNeedRefresh:=true;
    TBindings(FOwner).FNeedRefresh:=true;
  end;
end;

procedure TBinding.SetControlReadOnly(const AValue: boolean);
var param:Variant;
begin
  param:=AValue;
  FHandler.DoCommand(bcSetReadOnly,param);
end;


function Bind(const AControl:TControl;const ADataSource:TObject;const ADataExpr:ansistring;const AListSource:THetObject=nil;const AListExpr:ansistring='';const AListIconExpr:ansistring=''):TBinding;overload;
begin
  if AControl=nil then begin
    raise Exception.Create('Cannot Bind() nil');
    exit(nil);
  end;
  UnBind(AControl);
  result:=TBinding.Create(AControl,ADataSource,ADataExpr,AListSource,AListExpr,AListIconExpr);
end;

function BindingOf(const AControl:TControl):TBinding;
begin
  result:=TBinding(Bindings.FindBinary('ControlAsInt',[integer(AControl)]));
end;

function UnBind(const AControl:TControl):boolean;
var b:TBinding;
begin
  b:=BindingOf(AControl);
  result:=b<>nil;
  b.Free;
end;

{ TBindings }

constructor TBindings.Create(const AOwner: THetObject);
begin
  inherited;
  UpdateTimer:=TTimer.Create(nil);
  with UpdateTimer do begin
    Interval:=15;
    OnTimer:=OnUpdateTimer;
    Enabled:=true;
  end;
end;

destructor TBindings.Destroy;
begin
  FreeAndNil(UpdateTimer);
  inherited;
end;

procedure TBindings.OnUpdateTimer(Sender: TObject);
begin
  RefreshIfNeeded;
end;

procedure TBindings.RefreshIfNeeded;
var b:TBinding;
begin
  for b in self do b.RefreshIfNeeded;
  FNeedRefresh:=false; //nincs hasznalva, mert van olyan is most, hogy AlwaysRefresh
end;

initialization
  Bindings:=TBindings.Create(nil);

  RegisterBindingHandler(TListBoxBindingHandler);
  RegisterBindingHandler(TComboBoxBindingHandler);
  RegisterBindingHandler(TComboBoxExBindingHandler);
  RegisterBindingHandler(TColorBoxBindingHandler);
  RegisterBindingHandler(TListViewBindingHandler);
  RegisterBindingHandler(TEditBindingHandler);
  RegisterBindingHandler(TSpinEditBindingHandler);
  RegisterBindingHandler(TFloatSpinEditBindingHandler);
  RegisterBindingHandler(TMemoBindingHandler);
  RegisterBindingHandler(TStaticTextBindingHandler);
  RegisterBindingHandler(TCheckBoxBindingHandler);
  RegisterBindingHandler(TCheckListBoxBindingHandler);
  RegisterBindingHandler(TSliderBindingHandler);
finalization
  FreeAndNil(Bindings);
end.

