unit het.Objects;   //het.db het.filesys
interface

uses windows, sysutils, classes, typinfo, generics.Collections, variants,
  ansistrings, math, rtti,
  het.Utils, het.Arrays, het.Stream, het.TypeInfo, het.Parser,
  DebugInfo;

{$DEFINE ENUMERATORS}//qrvafasza, ettol debuggolhatatlanná válik a cucc 2009-en
{$DEFINE NOINCREMENTALNAME}//ihome_uinal nem kell a direktiva (amugy bugos szar ez)

//attributes
type
  _Default=class(TCustomAttribute)
  private
    FDefaultValue:single;
  public
    constructor Create(const ADefaultValue:single);
    property DefaultValue:single read FDefaultValue write FDefaultValue;
  end;

  _DefaultStr=class(TCustomAttribute)
  private
    FDefaultValue:string;
  public
    constructor Create(const ADefaultValue:string);
    property DefaultValue:String read FDefaultValue write FDefaultValue;
  end;

  _Range=class(TCustomAttribute)
  private
    FMinValue, FMaxValue:single;
  public
    constructor Create(const AMinValue, AMaxValue :single);
    property MinValue:single read FMinValue write FMinValue;
    property MaxValue:single read FMaxValue write FMaxValue;
  end;

type
  TFieldHash=record
    Hash:integer;
    PropInfo:PPropInfo;
  end;

  TClassDescription=class;
  TClassDescriptionCache=class;

  TClassDescription=class
  public
    Name:ansistring;
    Hash:integer;
    TypeInfo:PTypeInfo;
    FClass:TClass;
    PropList:PPropList;
    PropListCount:integer;
    IdProp:PPropInfo;//nil, ha nincs, vagy rossz a tipusa
    NameProp:PPropInfo;//nil, ha nincs, vagy rossz a tipusa
    Values,Defaults,Storeds,SubObjects,LinkedObjects,FieldMap:array of PPropInfo;
    StoredRawFieldSizes:array of cardinal;{ha nem 0, akkor lehet kiirni rawban, index megfelel a storeds-nek}
    PackedStoredRawFields:array of record ofs,size,storedId:integer end;{ha size<>0, akkor lehet kiirni rawban, kulonben ofs=index a storeds-ben}
    constructor Create(const ATypeInfo:PTypeInfo;const AClass:TClass);
    destructor Destroy;override;
    function Dump:ansistring;
  public
    procedure CreateSubObjs(const AObject:TObject);
    procedure FreeSubObjs(const AObject:TObject);
    procedure ClearLinkedObjs(const AObject:TObject);
    procedure SetDefaults(const AObject:TObject);
    procedure Reset(const AObject:TObject);
    function Validate(const AObject:TObject):TArray<ansistring>;
  private
    FieldHashArray:THetArray<TFieldHash>;
  public
    function PropInfoByHash(const AHash:integer):PPropInfo;
    function PropInfoByName(const AName:ansistring):PPropInfo;
  public
    attrDefaults:array of record Prop:TRttiInstanceProperty; DefaultValue:variant end;
    attrRanges:array of record Prop:TRttiInstanceProperty; MinValue,MaxValue:variant end;
    function DefaultOf(const pi:PPropInfo):variant;
    function RangeMinOf(const pi:PPropInfo):variant;
    function RangeMaxOf(const pi:PPropInfo):variant;
  end;

  TClassDescriptionCache=class
  private
    FItems:THetArray<TClassDescription>;
    function AddNew(const ATypeInfo:PTypeInfo;const AClass:TClass):TClassDescription;
  public
    function GetByTypeInfo(const ATypeInfo:PTypeInfo):TClassDescription;
    function GetByClass(const AClass:TClass):TClassDescription;//TClass-t is megjegyzi, nem csak a typeinfo-t
    function GetByHash(const AHash:integer):TClassDescription;
    function GetByName(const AName:ansistring):TClassDescription;
    destructor Destroy;override;
  end;

function ClassDescriptionOf(const ATypeInfo:PTypeInfo):TClassDescription;overload;
function ClassDescriptionOf(const AClass:TClass):TClassDescription;overload;
function ClassDescriptionOf(const AClassName:ansistring):TClassDescription;overload;
function ClassDescriptionOf(const AClassNameHash:integer):TClassDescription;overload;

procedure RegisterHetClass(const AClass:TClass);overload;deprecated;
procedure RegisterHetClass(const AClasses:array of const);overload;deprecated;

Type
  THetObjState=(
    stChangedSave, stChanged0,stChanged1,stChanged2,stChanged3,
    stListActive{accepts objs}, stListClearing, stListNonUniform,
    stViewList, stView
  );
  THetObjStates=set of THetObjState;

const
  stChangedAll=[stChanged0,stChanged1,stChanged2,stChanged3];

type
  THetObject=class;
  THetObjectClass=class of THetObject;
  THetObjectList=class;

  TChangeRec=packed record
    Obj:THetObject;
  end;
  TChangeType=(ctCreate,ctChange,ctDestroy);

  TSerializeType=(stBin,stDfm);

  THetObject=class(TPersistent)
  public
    FOwner:THetObject;
    FReferences:THetArray<THetObject>;
    ObjState:THetObjStates;
  protected
    procedure AfterCreate;virtual;
  public
    class function ClassDesc:TClassDescription;
    constructor Create(const AOwner:THetObject);virtual;
    destructor Destroy;override;

    function getLookupList(const PropInfo:PPropInfo):THetObjectList;virtual;
    function GetId:TId;
    procedure SetId(const AId:TId);
    function getIndex:integer;
    procedure setIndex(const newIdx:integer);
    function GetName:TName;
    procedure SetName(const AName:TName);
    procedure Serialize(const st:TIO;const SerType:TSerializeType);virtual;

    function SubObjName:AnsiString;
    property Owner:THetObject read FOwner;
  public
    procedure _AddReference(const AObj:THetObject);//a referencia listaba bekerul AObj
    procedure _RemoveReference(const AObj:THetObject);//a referencia listabol kikerul AObj

    procedure NotifyChange;virtual;//ezt hivja a set metodus, kotelezoen virtual
    procedure NotifyCreate;virtual;
    procedure NotifyDestroy;virtual;
    procedure ChangeEventDispatcher(const AObj:THetObject;const AChangeType:TChangeType);virtual;//ez szorja szet
    procedure ObjectChanged(const AObj:THetObject;const AChangeType:TChangeType);virtual;//ez meg feldolgozhatja

    procedure _LinkedObjDestroying(const AObj:THetObject);
      //  self-nek szol AObj, hogy megszunik, mert self rajta van AObj referencia listajan
    procedure _SubObjDestroying(const AObj:THetObject);virtual;
      //  self-nek szol AObj, hogy megszunik, mert AObj ownerje self
    procedure _SetID(const AID:integer);
  public
    function getFieldAsVariant(const AFieldName:ansistring):Variant;
    procedure setFieldAsVariant(const AFieldName:ansistring;const Value:Variant);
    property Field[const AFieldName:ansistring]:variant read getFieldAsVariant write setFieldAsVariant;
    property Index:integer read GetIndex;
  public
    procedure Reset;virtual;
    procedure LoadFromStr(const Data:RawByteString);
    function SaveToStr(const serType:TSerializeType):RawByteString;

    function TryLoadFromFile(const FN:string):boolean;
    procedure LoadFromFile(const FN:string);
    procedure SaveToFile(const FN:string;const serType:TSerializeType);
  public
{    function FieldCount:integer;
    function FieldByName(const AName:ansistring):integer;
    function GetFieldValue(const FieldIdx:integer):variant;overload;
    procedure SetFieldValue(const FieldIdx:integer;const Value:variant);overload;
    function GetFieldValue(const FieldName:AnsiString):variant;overload;
    procedure SetFieldValue(const FieldName:AnsiString;const Value:variant);overload;
    property FieldValue[idx:integer]read GetFieldByName write SetFieldByName;}

  published
  public
    function _Dump(const AIndent:integer=0):ansistring;virtual;
    function IsNil:boolean;inline;
    function ContentHash:integer;

    function Validate:TArray<ansistring>;
    function ValidateStr:ansistring;
  end;

  THetObjectComparerFunct=TComparerFunct<THetObject>;

  THetObjectViewSettings=class
  private
    FHash:integer;
    FDefinition:ansistring;
    FUnique:boolean;
    // id,name

    FNameSpace:TNameSpace;
    FCtx:TContext;
    FOrderBy:array of record node:TNodeBase;desc:integer{1:ascending;-1:descending} end;
    FWhereAnd:array of record node:TNodeBase;end;
{    FWhereBinary:array of record node:TObject;value:variant end;
    FWhereAnd:array of TObject;}

    FValueStack:array of array of variant;
    procedure PushValues(const values:array of const);
    procedure PopValues;
    procedure SetDefinition(const Value:ansistring);
  public
    destructor Destroy;override;
    procedure Reset;
    function Compare(const a,b:THetObject):integer;
    function Filter(const a:THetObject):boolean;
    function FindValues(const a:THetObject):integer;
    property Definition:ansistring read FDefinition write SetDefinition;
    property Hash:integer read FHash;
    property Unique:boolean read FUnique;
  end;

  TIdxRange=record St,En:integer end;

  THetObjectList=class(THetObject)
  private
    FItems:THetArray<THetObject>;
    function _RemoveListObj(const AListObj:THetObject):boolean;
    procedure _AppendListObj(const AListObj:THetObject);
    constructor CreateAsView(const AOwner:THetObject);
  protected
    function getNextItemId:integer; virtual;
  private
    FViewSettings:THetObjectViewSettings;
    FViews:THetObjectList;
    function GetIsView:boolean;inline;
    procedure Sort;
    procedure CopyItemsFrom(const ASrc:THetObjectList);
    function GetViewByDef(const ADef:ansistring):THetObjectList;
    function GetViewByHash(const AHash:integer):THetObjectList;
    function GetViewDefinition: ansistring;
    procedure SetViewDefinition(const Value: ansistring);
    function GetIsViewUnique: boolean;
    function NewView: THetObjectList;virtual;
  private
    FBaseClass:THetObjectClass;
    function AcquireBaseClass:THetObjectClass;
    procedure CreateViewList;
  public
    property BaseClass:THetObjectClass read FBaseClass;
    function NewUniqueView(const ADef:ansistring):THetObjectList;
    function GetViewHash:integer;
    property IsView:boolean read GetIsView;
    property IsViewUnique:boolean read GetIsViewUnique;
    function ViewBase:THetObjectList;
    property View[const ADef:ansistring]:THetObjectList read GetViewByDef;
    property ViewHash:integer read GetViewHash;
    property ViewDefinition:ansistring read GetViewDefinition write SetViewDefinition;

    function ViewAdjustFilter(const ANewFilter: ansistring): THetObjectList;
    function ViewAdjustOrder(const ANewOrder: ansistring): THetObjectList;
    procedure RefreshView;
  public
    procedure _SubObjDestroying(const AObj:THetObject);override;
    function GetByNameCached(const AName:ansistring):THetObject;virtual;
    constructor Create(const AOwner:THetObject);override;
    destructor Destroy;override;
    function IndexOf(const AObj:THetObject):integer;
    function Count:integer;inline;
    procedure Clear;
    function UniqueName(const AName:ansistring='';const AlwaysIndex:boolean=false):ansistring;
    function getNextItemNameFor(const AObj:THetObject):ansistring;//!!!!!!!!!!! ez a ketto ugyanaz!!!!!!!!

    //unsafe
    procedure Exchange(const Idx1,Idx2:integer);
    procedure Move(const Idx1,Idx2:integer);

    procedure ChangeEventDispatcher(const AObj:THetObject;const AChangeType:TChangeType);override;
    procedure ObjectChanged(const AObj:THetObject;const AChangeType:TChangeType);override;
  private
    function GetByIndex(const AIdx:integer):THetObject;
    function GetById(const AId:integer):THetObject;
    function GetByName(const AName:ansistring):THetObject;
  public
    property ByIndex[const AIndex:integer]:THetObject read GetByIndex;default;
    property ById[const AId:integer]:THetObject read GetById;
    property ByName[const AName:ansistring]:THetObject read GetByName;
  public
    function _Dump(const AIndent:integer=0):ansistring;override;

    function FindBinaryIdx(const AFields: ansistring;const AValues:array of const):integer;
    function FindBinary(const AFields: ansistring;const AValues:array of const):THetObject;
    function FindBinaryNearestIdx(const AFields: ansistring;const AValues:array of const):integer;

    function FindBinaryIdxRange(const AFields: ansistring;const AValues:array of const):TIdxRange;
    function FindBinaryRange(const AFields: ansistring;const AValues:array of const):TArray<THetObject>;

  public
//    function Select(const ASelect:ansistring):THetObjList;
  end;

(*  TGenericHetObjectListView<T:THetObject> =class(THetObjectListView)
  protected
    function GetByIndex(const AIndex:integer):T;
    function GetById(const AId:integer):T;
    function GetByName(const AName:ansistring):T;
  public
    property ByIndex[const AIndex:integer]:T read GetByIndex;default;
    property ById[const AId:integer]:T read GetById;
    property ByName[const AName:ansistring]:T read GetByName;
    procedure ForEach(const proc:TProc<T>);//ujrarendezodes es free ellen is véíd
  {$IFDEF ENUMERATORS}//debuggert ebassza...
    function GetEnumerator:TEnumerator<T>;reintroduce;
  {$ENDIF}
  end;*)

//  TSelectFunct<T:THetObject>=reference to Function(o:T):boolean;
  THetList<T:THetObject> =class(THetObjectList)
  private
    function GetByIndex(const AIndex:integer):T;
    function GetById(const AId:integer):T;
    function GetByName(const AName:ansistring):T;
    function NewView:THetObjectList;override;
  public
    //constructor Create(const AOwner:THetObject);override;
    property ByIndex[const AIndex:integer]:T read GetByIndex;default;
    property ById[const AId:integer]:T read GetById;
    property ByName[const AName:ansistring]:T read GetByName;
  public
    function GetViewByDef(const ADef:ansistring):THetList<T>;
    function ViewBase:THetList<T>;
    property View[const ADef:ansistring]:THetList<T> read GetViewByDef;
    procedure ForEach(const proc:TProc<T>);
    function NewListObj:T;overload;
    function NewListObj(const BaseClass:THetObjectClass):THetObject;overload;

  {$IFDEF ENUMERATORS}//debuggert ebassza... 2009-en
    type
      TEnumerator = class(TEnumerator<T>)
      private
        FList:THetList<T>;
        FIndex:Integer;
      protected
        function DoGetCurrent:T; override;
        function DoMoveNext:Boolean;override;
      public
        constructor Create(AList:THetList<T>);
      end;
    function GetEnumerator:TEnumerator;reintroduce;
  {$ENDIF}
  end;

////////////////////////////////////////////////////////////////////////////////
///  HetClassInfo                                                            ///
////////////////////////////////////////////////////////////////////////////////

  THetPropInfo=class(THetObject)
  private
    FHash:integer;//namehash
    FName:TName;
    FRttiProperty:TRttiProperty;
    FHetTypeRec:THetTypeRec;
    function HasExtra:boolean;
    function GetExtra: ansistring;
    procedure SetExtra(const Value: ansistring);
    procedure SetEnumNames(const Value: TArray<AnsiString>);
    procedure SetFlags(const Value: THetTypeFlags);
    procedure SetObjClass(const Value: TClass);
    procedure SetTyp(const Value: THetType);
    procedure SetNameAndHash(const n:TName);
  public
    constructor CreateFromRTTIProperty(const AOwner:THetObject;const ARttiProperty:TRttiProperty);
  published
    property Name:TName read FName write SetNameAndHash;
    property Typ:THetType read FHetTypeRec.Typ write SetTyp;
    property Extra:ansistring read GetExtra write SetExtra stored HasExtra;
  public
    property Flags:THetTypeFlags read FHetTypeRec.Flags write SetFlags;
    property BaseTyp:THetBaseType read FHetTypeRec.BaseTyp stored false;
    property RawSize:byte read FHetTypeRec.RawSize;
    property Hash:Integer read FHash;
    property RttiProperty:TRttiProperty read FRttiProperty;
    property ObjClass:TClass read FHetTypeRec.ObjClass write SetObjClass;
    property EnumNames:TArray<AnsiString> read FHetTypeRec.EnumNames write SetEnumNames;
    function PropInfo:PPropInfo;
  end;

  THetPropInfos=class(THetList<THetPropInfo>)
  end;

  THetClassInfo=class(THetObject)
  private
    FId:integer;//hash
    FName:TName;
    FRttiType:TRttiType;
    FProps:THetPropInfos;
    FStoredProps:THetPropInfos;
    FIdProp:THetPropInfo;
    FNameProp:THetPropInfo;
  public
    constructor Create(const AOwner:THetObject;const AClassName:ansistring);reintroduce;
  published
    property Name:TName read FName;
    property StoredProps:THetPropInfos read FStoredProps;
    property Props:THetPropInfos read FProps stored false;
  public
    property Id:integer read FId;//hash
    property RttiType:TRttiType read FRttiType;
    property IdProp:THetPropInfo read FIdProp;
    property NameProp:THetPropInfo read FNameProp;
  end;

  THetClassInfoList=class(THetList<THetClassInfo>)
  end;

function HetClassInfo(const AClassName:ansistring):THetClassInfo;overload;
function HetClassInfo(const AClass:TClass):THetClassInfo;overload;

procedure WriteObjectBin(const AObject:THetObject;const IO:TIO);
procedure WriteObjectDfm(const AObject:THetObject;const IO:TIO;const AFieldName:ansistring='');

procedure ReadObjectPropertiesBin(const AObject:THetObject;const IO:TIO);
procedure ReadObjectPropertiesDfm(const AObject:THetObject;const IO:TIO);

procedure ReadObjectProperties(const AObject:THetObject;const AST:TIO);overload;
procedure ReadObjectProperties(const AObject:THetObject;const Data:RawByteString);overload;

function ReadHetObject(const AOwner:THetObject;const IO:TIO):THetObject;

function ClassDescriptionCache:TClassDescriptionCache;

procedure WriteObjectDfmFilteredPropsOnly(const AObject:THetObject;const IO:TIO;const AFieldName:ansistring;const AFilter:ansistring;const AFieldPath:ansistring='');overload;
function  WriteObjectDfmFilteredPropsOnly(const AObject:THetObject;const AFieldName:ansistring;const AFilter:ansistring;const AFieldPath:ansistring=''):ansistring;overload;

const
  Root:THetObjectList=nil;//entry

/////////// test stuff

type
  TIOTestSubObj=class(THetObject)
    private FByte:Byte;procedure SetByte(const Value:byte);published property _Byte:Byte read FByte write SetByte default 251;
  end;

  TIOTestNamedObj=class(THetObject)
    private FName:TName;published property Name:TName read FName write SetName;
    private FByte:Byte;procedure SetByte(const Value:byte);
    public procedure SetName(const Value: TName);published property _Byte:Byte read FByte write SetByte default 251;
  end;
  TIOTestNamedObjList=class(THetList<TIOTestNamedObj>)end;

  TIOTestIdedObj=class(THetObject)
    private FId:TId;published property Id:TId read FId write SetId;
    private FByte:Byte;procedure SetByte(const Value:byte);
    published property _Byte:Byte read FByte write SetByte default 251;
  end;
  TIOTestIdedObjList=class(THetList<TIOTestIdedObj>)end;

  TIOTestIndexedObj=class(THetObject)
    private FByte:Byte;procedure SetByte(const Value:byte);published property _Byte:Byte read FByte write SetByte default 251;
  end;
  TIOTestIndexedObjList=class(THetList<TIOTestIndexedObj>)end;

  TIOTestObj=class(THetObject)
    //ordinals
    private FByte:Byte;procedure SetByte(const Value:byte);published property _Byte:Byte read FByte write SetByte default 254;
    private FShortInt:ShortInt;procedure SetShortInt(const Value:ShortInt);published property _ShortInt:ShortInt read FShortInt write SetShortInt default -126;
    private FWord:Word;procedure SetWord(const Value:Word);published property _Word:Word read FWord write SetWord default $fedc;
    private FSmallInt:SmallInt;procedure SetSmallInt(const Value:SmallInt);published property _SmallInt:SmallInt read FSmallInt write SetSmallInt default -32700;
    private Finteger:integer;procedure Setinteger(const Value:integer);published property _integer:integer read Finteger write Setinteger default -$789abcde;
    private Fcardinal:cardinal;procedure Setcardinal(const Value:cardinal);published property _cardinal:cardinal read Fcardinal write Setcardinal default $fedcba98;
    private Fint64:int64;procedure Setint64(const Value:int64);published property _int64:int64 read Fint64 write Setint64 default $789abcde;
    private Fuint64:uint64;procedure Setuint64(const Value:uint64);published property _uint64:uint64 read Fuint64 write Setuint64 default $789abcde;

    //enums/sets
    private FBoolean:Boolean;procedure SetBoolean(const Value:Boolean);published property _Boolean:Boolean read FBoolean write SetBoolean default true;
    private FIOTestEnum:TIOTestEnum;procedure SetIOTestEnum(const Value:TIOTestEnum);published property _IOTestEnum:TIOTestEnum read FIOTestEnum write SetIOTestEnum default Csutortok;
    private FIOTestSet:TIOTestSet;procedure SetIOTestSet(const Value:TIOTestSet);published property _IOTestSet:TIOTestSet read FIOTestSet write SetIOTestSet default [Szombat,Vasarnap];

    //floats
    private FSingle:Single;procedure SetSingle(const Value:Single);published property _Single:Single read FSingle write SetSingle;
    private FDouble:Double;procedure SetDouble(const Value:Double);published property _Double:Double read FDouble write SetDouble;
    private FExtended:Extended;procedure SetExtended(const Value:Extended);published property _Extended:Extended read FExtended write SetExtended;

    //dates
    private FDate:TDate;procedure SetDate(const Value:TDate);published property _Date:TDate read FDate write SetDate;
    private FTime:TTime;procedure SetTime(const Value:TTime);published property _Time:TTime read FTime write SetTime;
    private FDateTime:TDateTime;procedure SetDateTime(const Value:TDateTime);published property _DateTime:TDateTime read FDateTime write SetDateTime;

    //strings
    private FAnsiString:AnsiString;procedure SetAnsiString(const Value:AnsiString);published property _AnsiString:AnsiString read FAnsiString write SetAnsiString;
    private FUnicodeString:UnicodeString;procedure SetUnicodeString(const Value:UnicodeString);published property _UnicodeString:UnicodeString read FUnicodeString write SetUnicodeString;

    //ClassType
//    private FClass:TClass;procedure SetClass(const Value:TClass);published property _Class:TClass read FClass write SetClass;

    //objs
    public FSubObj:TIOTestSubObj;procedure SetSubObj(const Value:TIOTestSubObj);published property _SubObj:TIOTestSubObj read FSubObj;
    private FNamedObj:TIOTestNamedObj;procedure SetNamedObj(const Value:TIOTestNamedObj);published property _NamedObj:TIOTestNamedObj read FNamedObj write SetNamedObj;
    private FIDedObj:TIOTestIDedObj;procedure SetIDedObj(const Value:TIOTestIDedObj);published property _IDedObj:TIOTestIDedObj read FIDedObj write SetIDedObj;
    private FIndexedObj:TIOTestIndexedObj;procedure SetIndexedObj(const Value:TIOTestIndexedObj);published property _IndexedObj:TIOTestIndexedObj read FIndexedObj write SetIndexedObj;
  end;


implementation

uses het.Patch, het.Variants, unsSystem
{$IFDEF USEFILESYS},het.FileSys{$ENDIF}
;

////////////////////////////////////////////////////////////////////////////////
///  HetTypeInfo                                                             ///
////////////////////////////////////////////////////////////////////////////////

var
  RttiContext:TRttiContext;
//  RttiTypes:TArray<TRttiType>;
  HetClassInfoList:THetClassInfoList;

function HetClassInfo(const AClassName:ansistring):THetClassInfo;
begin
  if HetClassInfoList=nil then
    HetClassInfoList:=THetClassInfoList.Create(nil);
  result:=HetClassInfoList.ById[Crc32UC(AClassName)];
  if result=nil then
    result:=THetClassInfo.Create(HetClassInfoList,AClassName);
end;

function HetClassInfo(const AClass:TClass):THetClassInfo;
begin
  result:=HetClassInfo(AClass.ClassName);
end;

{ THetPropInfo }

{$O-}
procedure THetPropInfo.SetFlags(const Value: THetTypeFlags);begin end;
procedure THetPropInfo.SetTyp(const Value: THetType);begin end;
{$O+}

constructor THetPropInfo.createFromRTTIProperty(const AOwner: THetObject; const ARttiProperty: TRttiProperty);
begin
  create(AOwner);
  FRttiProperty:=ARttiProperty;
  FName:=FRttiProperty.Name;
  FHetTypeRec.ImportRttiProperty(FRttiProperty);
end;

procedure THetPropInfo.SetNameAndHash(const n: TName);
begin
  if FName=n then exit;
  FName:=n;
  FHash:=Crc32UC(n);
  NotifyChange;
end;

function THetPropInfo.HasExtra: boolean;
begin
  result:=typ in [htEnum, htSet, htSubObj, htObjId, htObjName, htObjIdx];
end;

function THetPropInfo.PropInfo: PPropInfo;
begin
  result:=TRttiInstanceProperty(FRttiProperty).PropInfo;
end;

function THetPropInfo.GetExtra: ansistring;
begin
  if Typ in[htEnum, htSet]then exit(ListMake(EnumNames,','));
  if BaseTyp=btObj then
    if ObjClass<>nil then exit(ObjClass.ClassName);
  result:='';
end;

procedure THetPropInfo.SetEnumNames(const Value: TArray<AnsiString>);
begin
  FHetTypeRec.EnumNames := Value;
  NotifyChange;
end;

procedure THetPropInfo.SetExtra(const Value: ansistring);
begin
  if Typ in[htEnum,htSet]then
    EnumNames:=ListSplit(Value,',')
  else if BaseTyp=btObj then
    ObjClass:=ClassByName(Value);
  NotifyChange;
end;

procedure THetPropInfo.SetObjClass(const Value: TClass);
begin
  FHetTypeRec.ObjClass := Value;
  NotifyChange;
end;


{ THetClassInfo }

constructor THetClassInfo.create(const AOwner: THetObject; const AClassName: AnsiString);
var t:TRttiType;
    p:TRttiProperty;
    hpi:THetPropInfo;
begin
  t:=RttiTypeByName(AClassName);
  if t=nil then
    raise Exception.Create('CreateHetClassInfo('+AClassName+') Unknown class');

  inherited create(AOwner);

  FRttiType:=t;
  FName:=t.Name;
  FId:=Crc32UC(FName);

  //import members
  for p in t.GetProperties do if(p.Visibility=mvPublished)and(p is TRttiInstanceProperty)then begin
    if flStored in THetPropInfo.CreateFromRTTIProperty(Props,p).Flags then
      THetPropInfo.CreateFromRTTIProperty(StoredProps,p);
  end;

  //Id, Name
  for hpi in Props do begin
    case hpi.Typ of
      htId:if IdProp=nil then FIdProp:=hpi
                         else raise Exception.Create('Multiple Id fields');
      htName:if NameProp=nil then FNameProp:=hpi
                             else raise Exception.Create('Multiple Name fields');
    end;
  end;

  NotifyChange;
end;

////////////////////////////////////////////////////////////////////////////////
///  ClassDescriptionCache                                                   ///
////////////////////////////////////////////////////////////////////////////////

procedure RegisterHetClass(const AClasses:array of const);deprecated;
var i:integer;
begin
  for i:=0 to high(AClasses)do if AClasses[i].VType=vtClass then
    RegisterHetClass(AClasses[i].VClass);
end;

procedure RegisterHetClass(const AClass:TClass);deprecated;
begin
  ClassDescriptionOf(AClass);
end;

function ClassDescriptionOf(const ATypeInfo:PTypeInfo):TClassDescription;inline;
begin
  result:=ClassDescriptionCache.GetByTypeInfo(ATypeInfo);
end;

function ClassDescriptionOf(const AClass:TClass):TClassDescription;inline;
begin
  Result:=ClassDescriptionCache.GetByClass(AClass);
end;

function ClassDescriptionOf(const AClassName:ansistring):TClassDescription;inline;
begin
  Result:=ClassDescriptionCache.GetByHash(Crc32UC(AClassName));
end;

function ClassDescriptionOf(const AClassNameHash:integer):TClassDescription;inline;
begin
  result:=ClassDescriptionCache.GetByHash(AClassNameHash);
end;


{ TClassDescription }

constructor TClassDescription.Create(const ATypeInfo: PTypeInfo;const AClass:TClass);

  procedure MakeFieldHashArray;
  var i,idx:integer;
      tmp:TFieldHash;
  begin
    for i:=0 to high(values)do begin
      tmp.PropInfo:=Values[i];
      tmp.Hash:=Crc32UC(Values[i].Name);
      FieldHashArray.FindBinary(function(const a:TFieldHash):integer begin result:=Cmp(tmp.hash,a.hash)end,idx);
      FieldHashArray.Insert(tmp,idx);
    end;
  end;

  procedure AddPackedStored(AOfs,ASize,AStoredId:integer);
  begin
    SetLength(PackedStoredRawFields,length(PackedStoredRawFields)+1);
    with PackedStoredRawFields[high(PackedStoredRawFields)]do begin
      ofs:=AOfs;Size:=ASize;StoredId:=AStoredId;
    end;
  end;

  function GetLastPackedOfs:cardinal;
  begin
    if length(PackedStoredRawFields)=0 then exit(0);
    with PackedStoredRawFields[high(PackedStoredRawFields)]do
      if StoredId<0 then result:=ofs+size
                    else result:=0;
  end;

  procedure IncPackedStored(ASize:integer);
  begin
    if length(PackedStoredRawFields)>0 then with PackedStoredRawFields[high(PackedStoredRawFields)]do inc(size,ASize);
  end;

  function ErrorText(const s:ansistring;pi:PPropInfo=nil):string;
  begin
    result:='TClassDescription.create('+Name+') '+s;
    if pi<>nil then result:=result+' '+pi.Name+' '+TypeDump(pi.PropType^);
  end;

  procedure CollectAttribs;
  var t:TRttiInstanceType;
      q:TRttiProperty;
      p:TRttiInstanceProperty;
      a:TCustomAttribute;
  begin
    t:=TRttiInstanceType(RttiContext.GetType(ATypeInfo));
    for q in t.GetProperties do if q is TRttiInstanceProperty then begin
      p:=TRttiInstanceProperty(q);
      for a in p.GetAttributes do begin

        if a.ClassType=_Default then begin
          setlength(attrDefaults,length(attrDefaults)+1);
          with attrDefaults[high(attrDefaults)]do begin
            Prop:=p;
            DefaultValue:=_Default(a).DefaultValue;
          end;
        end else if a.ClassType=_DefaultStr then begin
          setlength(attrDefaults,length(attrDefaults)+1);
          with attrDefaults[high(attrDefaults)]do begin
            Prop:=p;
            DefaultValue:=_DefaultStr(a).DefaultValue;
          end;
        end else if a.ClassType=_Range then begin
          setlength(attrRanges,length(attrRanges)+1);
          with attrRanges[high(attrRanges)]do begin
            Prop:=p;
            MinValue:=_Range(a).MinValue;
            MaxValue:=_Range(a).MaxValue;
          end;
        end;

      end;
    end;
  end;

var
  i,j:Integer;
  fieldofs:Cardinal;
  changedVMTId:integer;
  bw:NativeUInt;
label l1;
begin
  TypeInfo:=ATypeInfo;
  FClass:=AClass;
  Name:=TypeInfo.Name;
  Hash:=Crc32UC(Name);
  PropListCount:=GetPropList(TypeInfo,PropList);

  CollectAttribs;

  for i:=0 to PropListCount-1 do begin//tamogatott tipusok, amik nem writeonly-ak es index nelkuliek
    with PropList[i]^ do begin
      Assert(GetProc<>nil,
        errortext('Write only property not supported: ',PropList[i]));
      Assert((SetProc=nil)or(SetProc=GetProc)or(cardinal(SetProc)<$FF000000),
        errortext('Invalid set/get combination: ',PropList[i]));
      Assert(cardinal(Index)=$80000000,
        errortext('Indexed property not supported: ',PropList[i]));
      Assert(PropType^.Kind in [tkInteger, tkChar, tkEnumeration, tkFloat,
      tkString, tkSet, tkClass, tkWChar, tkLString, tkWString, tkInt64, tkUString],
        errortext('Unsupported property type: ',PropList[i]));
    end;
    SetLength(Values,length(Values)+1);
    Values[high(Values)]:=PropList[i];
  end;

  //check if hetobject
  changedVMTId:=VMTIndex(THetObject,@THetObject.NotifyChange);
  for i:=0 to high(values)do
    if(cardinal(Values[i].SetProc)<$FE000000)and(Values[i].SetProc<>nil)
    and(PByte(values[i].SetProc)^=$55)then//{if unoptimized set}
      PatchPropertySetter(Values[i],changedVMTId,TypeInfo.Name);

  for i:=0 to high(Values)do if CompareText('Id',Values[i].Name)=0 then begin
    IdProp:=Values[i];break end;
  if(IdProp<>nil)then begin
{    Assert(Idprop.SetProc=nil,
      errortext('Id must be readonly',IdProp));}
    Assert(cardinal(Idprop.GetProc)>=$FF000000,
      errortext('Id.get must be a field',IdProp));
    Assert((IdProp.PropType^.Kind in [tkInteger])and(GetTypeData(IdProp.PropType^).OrdType in[otULong,otSLong]),
      errortext('Id must be 32bit integer ',IdProp));
  end;

  for i:=0 to high(Values)do if CompareText('Name',Values[i].Name)=0 then begin
    NameProp:=Values[i];break end;
  if(NameProp<>nil)then begin
    Assert((NameProp.PropType^.Kind in [tkString,tkWString,tkLString,tkUString]),
      errortext('Name must be string',NameProp));
    Assert(cardinal(Nameprop.GetProc)>=$FF000000,
      errortext('Name.get must be a field',NameProp));
    if(NameProp.SetProc=nil)then try WriteProcessMemory(GetCurrentProcess,@NameProp.setproc,@NameProp.getproc,4,DWORD(bw))except on EAccessViolation do;end;
  end;

{  for i:=0 to high(Values)do if CompareText('Description',Values[i].Name)=0 then begin
    DescriptionProp:=Values[i];break end;
  if(IdProp<>nil)then begin
    Assert((DescriptionProp.PropType^.Kind in [tkString,tkWString,tkLString,tkUString]),
      'Description must be string ',DescriptionProp);
  end;}

  for i:=0 to high(Values)do if(Values[i].SetProc<>nil)then begin//ezeknek kell a Defaultjait beallitani
    if(Values[i].PropType^.Kind in [tkInteger, tkChar, tkEnumeration, tkSet, tkWChar])and(cardinal(Values[i].Default)<>$80000000)then begin
      SetLength(Defaults,length(Defaults)+1);
      Defaults[high(Defaults)]:=Values[i];
    end;
  end;

  for i:=0 to high(Values)do//ezeket lehet hogy menteni kell (Setterrel rendelkezoek plusz readonly fieldeket)
    if(Values[i].StoredProc<>nil)and((Values[i].SetProc<>nil)or(cardinal(Values[i].GetProc)>$FF000000))then begin
      SetLength(Storeds,length(Storeds)+1);
      Storeds[high(Storeds)]:=Values[i];
    end;

  setlength(StoredRawFieldSizes,length(Storeds));
  for i:=0 to High(Storeds) do begin
    if cardinal(Storeds[i].GetProc)>=$FF000000 then StoredRawFieldSizes[i]:=TypeSize(Storeds[i].PropType^)
                                               else StoredRawFieldSizes[i]:=0;
  end;

  for i:=0 to High(Storeds)do if(StoredRawFieldSizes[i]>0)and(cardinal(Storeds[i].StoredProc)=1)then begin//biztosan stored
    fieldofs:=cardinal(Storeds[i].GetProc)and $FFFFFF;
    if false and(fieldofs=GetLastPackedOfs) then IncPackedStored(StoredRawFieldSizes[i])
                                            else AddPackedStored(fieldofs,StoredRawFieldSizes[i],-1);
  end else begin
    AddPackedStored(0,0,i);
  end;


  j:=0;for i:=0 to high(Values)do with Values[i]^do
    if cardinal(GetProc)>$FF000000 then j:=max(j,cardinal(GetProc)and $FFFFFF);
  SetLength(FieldMap,j+1);fillchar(FieldMap[0],length(FieldMap)*SizeOf(FieldMap[0]),0);
  for i:=0 to high(Values)do with Values[i]^do
    if cardinal(GetProc)>$FF000000 then FieldMap[cardinal(GetProc)and $FFFFFF]:=Values[i];

  for i:=0 to high(values)do if(Values[i].PropType^.Kind=tkClass)then begin
{    Assert(cardinal(values[i].GetProc)>=$FF000000,
      errortext('Class property.get must be a field',Values[i]));  getteres readonly class megengedett}
    if not(cardinal(values[i].GetProc)>=$FF000000) then continue;
    if not(GetTypeData(Values[i].PropType^).ClassType.InheritsFrom(THetObject))then continue;

    Assert((values[i].SetProc=nil)or(cardinal(values[i].SetProc)<$FE000000),
      errortext('Class property.set must be nil or static method',Values[i]));
    if Values[i].SetProc=nil then begin
      SetLength(SubObjects,length(SubObjects)+1);
      SubObjects[high(SubObjects)]:=Values[i];
    end else begin
      SetLength(LinkedObjects,length(LinkedObjects)+1);
      LinkedObjects[high(LinkedObjects)]:=Values[i];
    end;
  end;

//Propinfo hash list
  MakeFieldHashArray;
end;

destructor TClassDescription.Destroy;
begin
  if PropListCount>0 then
    FreeMem(PropList);
  inherited;
end;

function TClassDescription.Dump: ansistring;
  procedure a(const s:ansistring);
  begin result:=result+s+#9 end;
var pi:PPropInfo;
{    ti:PTypeInfo;
    td:PTypeData;}
    i:integer;
begin
  result:='';
  a('Name');
  a('Get');
  a('Set');
  a('Stored');
  a('Default');
  a('NameIndex');
  a('TypeInfo');
  result:=result+#13#10;

  for i:=0 to PropListCount-1 do begin
    pi:=PropList[i];
//    ti:=pi.PropType^;
//    td:=GetTypeData(ti);

    a(pi.Name);
    a('#'+inttohex(cardinal(pi.GetProc),8));
    a('#'+inttohex(cardinal(pi.SetProc),8));
    a('#'+inttohex(cardinal(pi.StoredProc),8));
    a('#'+inttohex(pi.Default,8));
    a(inttostr(pi.NameIndex));
    a(TypeDump(pi.PropType^));
    result:=result+#13#10;
  end;
end;

procedure TClassDescription.CreateSubObjs(const AObject:TObject);
var i:integer;
begin
  for i:=0 to high(SubObjects)do begin
    ppointer(cardinal(AObject)+(cardinal(SubObjects[i].GetProc)and $FFFFFF))^:=
      THetObjectClass(getTypeData(SubObjects[i].PropType^).ClassType).Create(THetObject(AObject));
  end;
end;

procedure TClassDescription.FreeSubObjs(const AObject:TObject);
var i:integer;
    p:ppointer;
begin
  for i:=high(SubObjects)downto 0 do begin
    p:=ppointer(cardinal(AObject)+(cardinal(SubObjects[i].GetProc)and $FFFFFF));
    if p^<>nil then begin
      FreeAndNil(p^);
    end;
  end;
end;

function TClassDescription.PropInfoByHash(const AHash: integer): PPropInfo;
var idx:integer;
begin
  if FieldHashArray.FindBinary(function(const a:TFieldHash):integer begin result:=AHash-a.Hash end,idx)then
    result:=FieldHashArray.FItems[idx].propinfo
  else
    result:=nil;
end;

function TClassDescription.PropInfoByName(const AName: ansistring): PPropInfo;
begin
  result:=PropInfoByHash(Crc32UC(AName))
end;

procedure TClassDescription.ClearLinkedObjs(const AObject:TObject);
var i:integer;
begin
  for i:=0 to high(LinkedObjects)do begin
    SetOrdProp(AObject,LinkedObjects[i],0);
  end;
end;

procedure TClassDescription.Reset(const AObject: TObject);
var i:integer;
    obj:THetObject;
begin
  if AObject is THetObjectList then //130423 elorehoztam
    THetObjectList(AObject).Clear;

  for i:=0 to high(storeds)do with Storeds[i]^do case PropType^.Kind of
    tkInteger, tkChar, tkEnumeration, tkSet, tkWChar:begin
      if cardinal(Default)<>$80000000 then SetOrdProp(AObject,storeds[i],Default)
                                      else SetOrdProp(AObject,storeds[i],0);
    end;
    tkInt64:SetInt64Prop(AObject,storeds[i],0);
    tkFloat:SetFloatProp(AObject,Storeds[i],0);
    tkString, tkWString, tkUString, tkLString: SetStrProp(AObject,storeds[i],'');
    tkClass:
      if SetProc<>nil then begin
        SetOrdProp(AObject,storeds[i],0)
      end else begin
        obj:=THetObject(GetOrdProp(AObject,storeds[i]));
        ClassDescriptionOf(obj.ClassInfo).Reset(obj);
      end;
  end;

  for i:=0 to high(attrDefaults)do
    with attrDefaults[i] do SetPropValue(AObject,Prop.PropInfo,DefaultValue);
end;

procedure TClassDescription.SetDefaults(const AObject: TObject);
var i:integer;
begin
  for i:=0 to high(Defaults)do
    SetOrdProp(AObject,Defaults[i],Defaults[i].Default);
  for i:=0 to high(attrDefaults)do with attrDefaults[i] do
    SetPropValue(AObject,Prop.PropInfo,DefaultValue);
end;

function TClassDescription.Validate(const AObject:TObject):TArray<ansistring>;
  procedure err(const s:ansistring);begin AddStrArrayNoCheck(result,s);end;
var i:integer;
    v:variant;
    ok:boolean;
begin
  if AObject=nil then begin err('Object is nil');exit end;
  for i:=0 to high(attrRanges)do with attrRanges[i]do begin
    v:=GetPropValue(AObject,Prop.PropInfo);

    ok:=false;
    try ok:=(v>=MinValue)and(v<=MaxValue);except end;

    if not ok then err(format('  %s (%s) is out of range [%s..%s]',[Prop.Name,tostr(v),tostr(MinValue),tostr(MaxValue)]));
  end;
  if result<>nil then InsStrArray(result,0,'Error validating object:'+AObject.ClassName);
end;

function TClassDescription.DefaultOf(const pi: PPropInfo): variant;
var i:integer;
begin
  for i:=0 to high(attrDefaults)do with attrDefaults[i]do if Prop.PropInfo=pi then exit(DefaultValue);
  if cardinal(pi.Default)<>$80000000 then exit(pi.Default);
  result:=null;
end;

function TClassDescription.RangeMinOf(const pi: PPropInfo): variant;
var i:integer;
begin
  for i:=0 to high(attrRanges)do with attrRanges[i]do if Prop.PropInfo=pi then exit(MinValue);
end;

function TClassDescription.RangeMaxOf(const pi: PPropInfo): variant;
var i:integer;
begin
  for i:=0 to high(attrRanges)do with attrRanges[i]do if Prop.PropInfo=pi then exit(MaxValue);
end;



{function TClassDescription.StoredDef: ansistring;
var p:PPropInfo;
    s:ansistring;
begin
  with AnsiStringBuilder(result,true)do
  for p in Storeds do begin
//    AddChar(ansichar(p.PropType);

  end;
end;}

{ TClassDescriptionCache }

function TClassDescriptionCache.AddNew(const ATypeInfo:PTypeInfo;const AClass:TClass):TClassDescription;
begin
  result:=TClassDescription.Create(ATypeInfo,AClass);
  FItems.Insert(result,0);
end;

destructor TClassDescriptionCache.Destroy;
var i:integer;
begin
  with FItems do for i:=0 to FCount-1 do FItems[i].Free;
  inherited;
end;

function TClassDescriptionCache.GetByHash(const AHash: integer): TClassDescription;
var i:integer;cl:TClass;
begin
  with FItems do for i:=0 to FCount-1 do if FItems[i].Hash=AHash then begin
    exit(FItems[i]);
    if i>4 then Move(i,0);
  end;

  cl:=het.TypeInfo.ClassByHash(AHash);
  if cl<>nil then result:=AddNew(cl.ClassInfo,cl)
             else result:=nil;
end;

function TClassDescriptionCache.GetByName(const AName: ansistring): TClassDescription;
var i:integer;cl:TClass;
begin
  with FItems do for i:=0 to FCount-1 do if AnsiCompareText(FItems[i].Name,AName)=0 then begin
    exit(FItems[i]);
    if i>4 then Move(i,0);
  end;

  cl:=het.TypeInfo.ClassByName(AName);
  if cl<>nil then result:=AddNew(cl.ClassInfo,cl)
             else result:=nil;
end;

function TClassDescriptionCache.GetByTypeInfo(const ATypeInfo: PTypeInfo): TClassDescription;
var i:integer;
begin
  for i:=0 to FItems.Count-1 do begin
    if FItems.FItems[i].TypeInfo=ATypeInfo then begin
      exit(FItems.FItems[i]);
      if i>4 then FItems.Move(i,0);
    end;
  end;
  result:=AddNew(ATypeInfo,nil);
end;

function TClassDescriptionCache.GetByClass(const AClass:TClass): TClassDescription;
var i:integer;
begin
  for i:=0 to FItems.Count-1 do begin
    if FItems.FItems[i].FClass=AClass then begin
      exit(FItems.FItems[i]);
      if i>4 then FItems.Move(i,0);
    end;
  end;
  result:=AddNew(AClass.ClassInfo,AClass);
end;

////////////////////////////////////////////////////////////////////////////////
//                         HETOBJECT                                          //
////////////////////////////////////////////////////////////////////////////////


procedure WriteObjectBin(const AObject:THetObject;const IO:TIO);
  procedure WritePropBin(const PropInfo:PPropInfo);
  var
    _ansistring:AnsiString;
    _int:integer;
    _single:Single;
    _double:Double;
    _extended:Extended;
    _comp:Comp;
    _curr:Currency;
    _int64:int64;
    obj:THetObject;
    linkCD:TClassDescription;
//    lookuplist:THetObjectList;
  begin with PropInfo^ do begin
    case PropType^.Kind of
      tkInteger, tkChar, tkEnumeration, tkSet, tkWChar:begin
        _int:=GetOrdProp(AObject,PropInfo);
        case GetTypeData(PropType^).OrdType of
          otSByte,otUByte:IO.IOBlock(_int,1);
          otSWord,otUWord:IO.IOBlock(_int,2);
          otSLong,otULong:IO.IOBlock(_int,4);
        end;
      end;
      tkInt64:begin _int64:=GetInt64Prop(AObject,PropInfo);IO.IOBlock(_int64,8);end;
      tkFloat:case GetTypeData(PropType^).FloatType of
        ftSingle:  begin _single:=  GetFloatProp(AObject,PropInfo);IO.IOBlock(_single  ,sizeof(_single  ));end;
        ftDouble:  begin _Double:=  GetFloatProp(AObject,PropInfo);IO.IOBlock(_Double  ,sizeof(_Double  ));end;
        ftExtended:begin _Extended:=GetFloatProp(AObject,PropInfo);IO.IOBlock(_Extended,sizeof(_Extended));end;
        ftComp:    begin _Comp:=    GetFloatProp(AObject,PropInfo);IO.IOBlock(_Comp    ,sizeof(_Comp    ));end;
        ftCurr:    begin _Curr:=    GetFloatProp(AObject,PropInfo);IO.IOBlock(_Curr    ,sizeof(_Curr    ));end;
      end;
      tkLString,tkWString,tkUString:begin
        _ansistring:=GetAnsiStrProp(AObject,PropInfo);
        IO.IO(_ansistring);
      end;
      tkClass:begin
        obj:=THetObject(pointer(cardinal(AObject)+cardinal(GetProc)and $FFFFFF)^);
        if SetProc=nil then begin//subobj
          WriteObjectBin(obj,IO);
        end else begin//link
          linkCD:=ClassDescriptionCache.GetByTypeInfo(GetTypeData(PropType^).ClassType.ClassInfo);
          if linkCD.IdProp<>nil then begin//by id
            if obj<>nil then begin
              _int:=GetOrdProp(obj,linkCD.IdProp)//1based
            end else
              _int:=0;
            IO.IOComprCardinal(cardinal(_int));
          end else if linkCD.NameProp<>nil then begin//by name
            if obj<>nil then begin
              _ansistring:=GetAnsiStrProp(obj,linkCD.NameProp)
            end else
              _ansistring:='';
            IO.IO(_ansistring);
          end else begin//by index
            if obj<>nil then begin
//              lookuplist:=AObject.getLookupList(PropInfo);
//              Assert(lookuplist<>nil,'WritePropBin() can''t get lookuplist');
              _int:=obj.getIndex{lookuplist.IndexOf(obj)}+1;
              Assert(_int>0,'WritePropBin() can''t find object in lookuplist');
            end else
              _Int:=0;
            IO.IOComprCardinal(cardinal(_int));
          end;
        end;
      end;
    end;
  end;end;

var CD:TClassDescription;
    i:Integer;
    actProp:PPropInfo;
begin
  if AObject=nil then begin
    i:=0;IO.IOBlock(i,4);
    exit;
  end;
  CD:=ClassDescriptionCache.GetByTypeInfo(AObject.ClassInfo);
  IO.IOBlock(CD.Hash,4);
  with CD do for i := 0 to high(PackedStoredRawFields)do with PackedStoredRawFields[i]do if storedId<0 then//packed stored
    IO.IOBlock(pointer(cardinal(AObject)+cardinal(ofs))^,size)
  else begin
    actProp:=Storeds[storedId];
    with actProp^do begin
      if(cardinal(StoredProc)=1)or IsStoredProp(AObject,actProp)then begin
        if StoredRawFieldSizes[storedId]>0 then begin//field es raw
          IO.IOBlock(pointer(cardinal(AObject)+(cardinal(GetProc)and $FFFFFF))^,StoredRawFieldSizes[storedId]);
        end else begin//method vagy nem_raw
          WritePropBin(actProp);
        end;
      end;
    end;
  end;
  if AObject is THetObjectList then with AObject as THetObjectList do begin
    IO.IOComprCardinal(cardinal(FItems.FCount));
    for I:=0 to FItems.FCount-1 do
      FItems.FItems[i].Serialize(IO,stBin);
  end;
end;

procedure WriteObjectDfm(const AObject:THetObject;const IO:TIO;const AFieldName:ansistring='');
  procedure WritePropDfm(const PropInfo:PPropInfo);

    procedure wr(const s:ansistring);
    begin
      IO.WriteLine(Propinfo.Name+'='+s);
    end;

  var
    _ansistring:AnsiString;
    _int:integer;
    obj:THetObject;
    linkCD:TClassDescription;
    lookuplist:THetObjectList;
    val:Variant;
    _cardinal:Cardinal;
  begin with PropInfo^ do begin
    GetPropValue(AObject,PropInfo,false);

    case PropType^.Kind of
      tkClass:begin
        obj:=THetObject(pointer(cardinal(AObject)+cardinal(GetProc)and $FFFFFF)^);
        if SetProc=nil then begin//subobj
          WriteObjectDfm(obj,IO,Propinfo.name);
        end else begin//link
          linkCD:=ClassDescriptionCache.GetByTypeInfo(GetTypeData(PropType^).ClassType.ClassInfo);
          if linkCD.IdProp<>nil then begin//by id
            if obj<>nil then begin
              _int:=GetOrdProp(obj,linkCD.IdProp){+1}//1based
            end else
              _int:=0;
            wr(ToStr(_int));
          end else if linkCD.NameProp<>nil then begin//by name
            if obj<>nil then begin
              _ansistring:=GetAnsiStrProp(obj,linkCD.NameProp)
            end else
              _ansistring:='';
            wr(ToPas(_ansistring));
          end else begin//by index
            if obj<>nil then begin
              lookuplist:=AObject.getLookupList(PropInfo);
              Assert(lookuplist<>nil,'WritePropBin() can''t get lookuplist ('+AObject.ClassName+'.'+PropInfo.Name+')');
              _int:=lookuplist.IndexOf(obj)+1;
              Assert(_int>0,'WritePropBin() can''t find object in lookuplist ('+AObject.ClassName+'.'+PropInfo.Name+')');
            end else
              _Int:=0;
            wr(ToStr(_int));
          end;
        end;
      end;
    tkInteger:begin //cardinal is not int!!
      val:=GetPropValue(AObject,PropInfo,true);
      if GetTypeData(Propinfo.PropType^).OrdType=otULong then begin
        _cardinal:=val;
        val:=_cardinal;
      end;
      wr(VariantToPas(val));
    end else
      val:=GetPropValue(AObject,PropInfo,true);
      wr(VariantToPas(val));
    end;
  end;end;

var CD:TClassDescription;
    i:Integer;
    actProp:PPropInfo;
    oldDs:char;
begin
  if AObject=nil then begin
    if AFieldName='' then IO.WriteLine('nil')
                     else IO.WriteLine(AFieldName+'=nil');
    exit;
  end;

  oldDs:=FormatSettings.DecimalSeparator;
  FormatSettings.DecimalSeparator:='.';

  CD:=ClassDescriptionCache.GetByTypeInfo(AObject.ClassInfo);
  if AFieldName='' then IO.WriteLine('object '+CD.Name)
                   else IO.WriteLine(AFieldName+'=object '+CD.Name);
  IO.WriteIndentInc;
  with CD do for i:=0 to High(Storeds)do begin
    actProp:=Storeds[i];
    with actProp^do
      if(cardinal(StoredProc)=1)or IsStoredProp(AObject,actProp)then
        WritePropDfm(actProp);
  end;

  if AObject is THetObjectList then with AObject as THetObjectList do begin
    for I:=0 to FItems.FCount-1 do
      WriteObjectDfm(FItems.FItems[i],IO);
  end;
  IO.WriteIndentDec;
  IO.WriteLine('end');

  FormatSettings.DecimalSeparator:=oldDs;
end;

function WriteObjectDfmFilteredPropsOnly(const AObject:THetObject;const AFieldName:ansistring;const AFilter:ansistring;const AFieldPath:ansistring=''):ansistring;
var st:TIO;
begin
  st:=TIOBinWriter.Create;
  result:='';
  try
    WriteObjectDfmFilteredPropsOnly(AObject,st,AFieldName,AFilter,AFieldPath);
    result:=st.Data;
  finally
    st.Free;
  end;
end;

//filter: 'name,Drawbar?.Amount,...'
procedure WriteObjectDfmFilteredPropsOnly(const AObject:THetObject;const IO:TIO;const AFieldName:ansistring;const AFilter:ansistring;const AFieldPath:ansistring='');

  procedure WritePropDfm(const PropInfo:PPropInfo;const FullPath:ansistring);
    function PasStr(const s:ansistring):ansistring;
    begin
      result:=s;
      Replace('''','''''',result,[roAll]);
      result:=''''+s+'''';
    end;

    procedure wr(const s:ansistring);
    begin
      IO.WriteLine(Propinfo.Name+'='+s);
    end;

  var
    _ansistring:AnsiString;
    _int:integer;
    obj:THetObject;
    linkCD:TClassDescription;
    lookuplist:THetObjectList;
    val:Variant;

  begin with PropInfo^ do begin
    GetPropValue(AObject,PropInfo,false);

    case PropType^.Kind of
      tkClass:begin
        obj:=THetObject(pointer(cardinal(AObject)+cardinal(GetProc)and $FFFFFF)^);
        if SetProc=nil then begin//subobj
          /////!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
          WriteObjectDfmFilteredPropsOnly(obj,IO,Propinfo.name,AFilter,FullPath);
        end else begin//link
          linkCD:=ClassDescriptionCache.GetByTypeInfo(GetTypeData(PropType^).ClassType.ClassInfo);
          if linkCD.IdProp<>nil then begin//by id
            if obj<>nil then begin
              _int:=GetOrdProp(obj,linkCD.IdProp){+1}//1based
            end else
              _int:=0;
            wr(ToStr(_int));
          end else if linkCD.NameProp<>nil then begin//by name
            if obj<>nil then begin
              _ansistring:=GetAnsiStrProp(obj,linkCD.NameProp)
            end else
              _ansistring:='';
            wr(PasStr(_ansistring));
          end else begin//by index
            if obj<>nil then begin
              lookuplist:=AObject.getLookupList(PropInfo);
              Assert(lookuplist<>nil,'WritePropBin() can''t get lookuplist ('+AObject.ClassName+'.'+PropInfo.Name+')');
              _int:=lookuplist.IndexOf(obj)+1;
              Assert(_int>0,'WritePropBin() can''t find object in lookuplist ('+AObject.ClassName+'.'+PropInfo.Name+')');
            end else
              _Int:=0;
            wr(ToStr(_int));
          end;
        end;
      end;
    else
      val:=GetPropValue(AObject,PropInfo,true);
      if VarIsStr(val)then wr(PasStr(val))
                      else wr(ToStr(val));
    end;
  end;end;

var CD:TClassDescription;
    i:Integer;
    actProp:PPropInfo;
    filt,path:ansistring;
    oldDs:char;
begin
  if AObject=nil then begin
    if AFieldName='' then IO.WriteLine('nil')
                     else IO.WriteLine(AFieldName+'=nil');
    exit;
  end;

  oldDs:=FormatSettings.DecimalSeparator;
  FormatSettings.DecimalSeparator:='.';

  CD:=ClassDescriptionCache.GetByTypeInfo(AObject.ClassInfo);
  if AFieldName='' then IO.WriteLine('object '+CD.Name)
                   else IO.WriteLine(AFieldName+'=object '+CD.Name);
  IO.WriteIndentInc;
  with CD do for i:=0 to High(Storeds)do begin
    actProp:=Storeds[i];
    with actProp^do begin
      path:=AFieldPath+switch(AFieldPath='','','.')+actProp.name;
      if(actProp.SetProc=nil)and(actProp.PropType^.Kind=tkClass)then
        WritePropDfm(actProp,path)
      else for filt in ListSplit(AFilter,',')do
        if IsWild2(filt,path)then begin
          WritePropDfm(actProp,path);
          break;
        end;
    end;
  end;

  if AObject is THetObjectList then with AObject as THetObjectList do begin
    for I:=0 to FItems.FCount-1 do
      WriteObjectDfm(FItems.FItems[i],IO);
  end;
  IO.WriteIndentDec;
  IO.WriteLine('end');

  FormatSettings.DecimalSeparator:=oldDs;
end;

procedure ReadObjectPropertiesBin(const AObject:THetObject;const IO:TIO);

  procedure ReadPropBin(const PropInfo:PPropInfo);
  var
    _ansistring:AnsiString;
    _int:integer;
    _single:Single;
    _double:Double;
    _extended:Extended;
    _comp:Comp;
    _curr:Currency;
    _int64:int64;
    obj:THetObject;
    linkCD:TClassDescription;
    lookupList:THetObjectList;
  begin with PropInfo^ do begin
    case PropType^.Kind of
      tkInteger, tkChar, tkEnumeration, tkSet, tkWChar:begin
        _int:=0;
        case GetTypeData(PropType^).OrdType of
          otSByte,otUByte:IO.IOBlock(_int,1);
          otSWord,otUWord:IO.IOBlock(_int,2);
          otSLong,otULong:IO.IOBlock(_int,4);
        end;
        SetOrdProp(AObject,PropInfo,_int);
      end;
      tkInt64:begin IO.IOBlock(_int64,8);SetInt64Prop(AObject,PropInfo,_int64);end;
      tkFloat:case GetTypeData(PropType^).FloatType of
        ftSingle:  begin IO.IOBlock(_single  ,sizeof(_single  ));SetFloatProp(AObject,PropInfo,_single  );end;
        ftDouble:  begin IO.IOBlock(_Double  ,sizeof(_Double  ));SetFloatProp(AObject,PropInfo,_Double  );end;
        ftExtended:begin IO.IOBlock(_Extended,sizeof(_Extended));SetFloatProp(AObject,PropInfo,_Extended);end;
        ftComp:    begin IO.IOBlock(_Comp    ,sizeof(_Comp    ));SetFloatProp(AObject,PropInfo,_Comp    );end;
        ftCurr:    begin IO.IOBlock(_Curr    ,sizeof(_Curr    ));SetFloatProp(AObject,PropInfo,_Curr    );end;
      end;
      tkLString,tkWString,tkUString:begin
        IO.IO(_ansistring);
        SetAnsiStrProp(AObject,PropInfo,_ansistring);
      end;
      tkClass:begin
        obj:=THetObject(pointer(cardinal(AObject)+cardinal(GetProc)and $FFFFFF)^);
        if SetProc=nil then begin//subobj
          ReadObjectPropertiesBin(obj,IO);
        end else begin//link
          linkCD:=ClassDescriptionCache.GetByTypeInfo(GetTypeData(PropType^).ClassType.ClassInfo);
          if linkCD.IdProp<>nil then begin//by id
            IO.IOComprCardinal(cardinal(_int));
            if _int>0 then begin
              lookupList:=AObject.getLookupList(PropInfo);
              Assert(lookuplist<>nil,'ReadPropBin() can''t get lookuplist');
              obj:=lookupList.ById[_int-1];
            end else
              obj:=nil;
            SetOrdProp(AObject,PropInfo,integer(obj));
          end else if linkCD.NameProp<>nil then begin//by name
            IO.IO(_ansistring);
            if _ansistring<>'' then begin
              lookupList:=AObject.getLookupList(PropInfo);
              Assert(lookuplist<>nil,'ReadPropBin() can''t get lookuplist');
              obj:=lookupList.ByName[_ansistring];
            end else
              obj:=nil;
            SetOrdProp(AObject,PropInfo,integer(obj));
          end else begin//by index
            IO.IOComprCardinal(cardinal(_int));
            if _int>0 then begin
              lookupList:=AObject.getLookupList(PropInfo);
              Assert(lookuplist<>nil,'ReadPropBin() can''t get lookuplist');
              obj:=lookupList.ByIndex[_int-1];
            end else
              obj:=nil;
            SetOrdProp(AObject,PropInfo,integer(obj));
          end;
        end;
      end;
    end;
  end;end;

var CD:TClassDescription;
    i:Integer;
    actProp:PPropInfo;
    Hash:integer;
    needChanged:boolean;
    list:THetObjectList;
    cnt:Cardinal;

begin
  IO.IOBlock(Hash,4);
  if(AObject=nil)and(Hash<>0)then raise Exception.Create('ReadObjectBin() AObject is nil, but hash<>0');
  if AObject=nil then exit;
  if Hash=0 then raise Exception.Create('ReadObjectBin() AObject is not nil, but hash=0');
  CD:=ClassDescriptionCache.GetByTypeInfo(AObject.ClassInfo);
  if CD.Hash<>Hash then raise Exception.Create('ReadObjectBin() Classtype missmatch');

  needChanged:=false;
  with CD do for i:=0 to high(PackedStoredRawFields)do with PackedStoredRawFields[i]do if storedId<0 then begin//packed stored
    IO.IOBlock(pointer(cardinal(AObject)+cardinal(ofs))^,size);
    needChanged:=true;
  end else begin
    actProp:=Storeds[storedId];
    with actProp^do begin
      if(cardinal(StoredProc)=1)or IsStoredProp(AObject,actProp)then begin
        if StoredRawFieldSizes[storedId]>0 then begin//field es raw
          IO.IOBlock(pointer(cardinal(AObject)+(cardinal(GetProc)and $FFFFFF))^,StoredRawFieldSizes[storedId]);
          needChanged:=true;
        end else begin//method vagy nem_raw
          ReadPropBin(actProp);
        end;
      end;
    end;
  end;
  if needChanged then
    AObject.NotifyChange;

  if AObject is THetObjectList then begin
    list:=AObject as THetObjectList;
    list.clear;
    IO.IOComprCardinal(cnt);
    setlength(list.FItems.FItems,cnt);
    for i:=0 to cnt-1 do
      ReadHetObject(list,IO);
  end;
end;

function ReadThing(const IO:TIO):ansistring;
  function PeekChar:AnsiChar;
  begin
    if IO.EOF then result:=#0
              else IO.IOPeek(result,1);
  end;

  procedure SkipChar;
  begin
    IO.IOSeek(IO.IOPos+1);
  end;

  function GetChar:ansichar;
  begin
    result:=PeekChar;
    SkipChar;
  end;

  procedure SkipWhiteSpace;
  begin
    while PeekChar in [#10,#13,#9,' ']do SkipChar;
  end;

label re;
begin
  result:='';
  SkipWhiteSpace;

  case PeekChar of
    #0:exit;
    'a'..'z','A'..'Z','_':begin
      while PeekChar in['a'..'z','A'..'Z','_','0'..'9','.']do
        result:=result+GetChar;
    end;
    '''','#':begin
      re:
      while PeekChar='''' do begin
        result:=result+GetChar;
        while not(PeekChar in[#0,''''])do
          result:=result+GetChar;
        result:=result+GetChar;
      end;
      if PeekChar='#' then begin
        result:=result+GetChar;
        while PeekChar in['$','0'..'9']do
          result:=result+GetChar;
        goto re;
      end;
    end;
    '+','-','0'..'9':while PeekChar in['+','-','0'..'9','.','e','E']do Result:=Result+GetChar;
  else result:=GetChar;end;

  SkipWhiteSpace;
end;

function PasToVar(const s:ansistring):Variant;
var ch:PAnsiChar;
begin
  if s='' then exit(Unassigned);

  if s[1]in['''','#']then begin
    {replace('''''','''',s,[roAll]);
    s:=copy(s,2,length(s)-2);
    result:=s;}
    ch:=pointer(s);
    result:=AnsiString(ParsePascalConstant(ch));
  end else begin
    if pos('.',s)>0 then result:=StrToFloatDef(s,0)
                    else Result:=StrToIntDef(s,0);
//    result:=ParsePascalConstant(s); //ez csak 2-3%-al gyorsabb, jobb a masik}
  end;
end;

procedure ReadObjectPropertiesDfm(const AObject:THetObject;const IO:TIO);

var CD:TClassDescription;
    i:Integer;
    actProp:PPropInfo;
    CName:ansistring;
    list:THetObjectList;
    s,s2:ansistring;
    oldPos,posStart:integer;
    obj:THetObject;
    linkCD:TClassDescription;
    _int:integer;
    _ansistring:ansistring;
    lookupList:THetObjectList;
    oldDs:char;
begin
  if cmp(ReadThing(IO),'object')=0 then CName:=ReadThing(IO)
                                   else begin CName:='';raise exception.Create('fakk');end;

  //ez suxx, nem megy nil-re
  if(AObject=nil)and(CName<>'')then raise Exception.Create('ReadObjectDfm() AObject is nil, but CName<>""');
  if AObject=nil then exit;
  if CName='' then raise Exception.Create('ReadObjectDfm() AObject is not nil, but CName=""'+inttostr(IO.IOPos));
  CD:=ClassDescriptionCache.GetByTypeInfo(AObject.ClassInfo);
  if CD.Hash<>Crc32UC(CName)then raise Exception.Create('ReadObjectDfm() Classtype missmatch');

  oldDs:=FormatSettings.DecimalSeparator;
  FormatSettings.DecimalSeparator:='.';

  if AObject is THetObjectList then begin
    list:=AObject as THetObjectList;
    list.clear;
  end else
    list:=nil;

  while not IO.EOF do begin
    posStart:=IO.IOPos;
    s:=readThing(IO);

    if cmp(s,'object')=0 then begin
      if list=nil then raise Exception.Create('ReadObjectDfm() object found, but Self is not THetObjectList');
      IO.IOSeek(posStart);
      ReadHetObject(list,IO);
    end else if Cmp(s,'end')=0 then begin
      break;
    end else begin
      //field
      if ReadThing(IO)<>'=' then raise Exception.Create('ReadObjectDfm() "=" expected ('+AObject.ClassName+'.'+s+' at '+tostr(io.iopos)+')'+AObject.getName);
      oldpos:=IO.IOPos;
      s2:=ReadThing(IO);

      with CD do for i:=0 to High(Storeds)do if cmp(storeds[i].Name,s)=0 then begin
        actProp:=Storeds[i];
        with actProp^do
          if(cardinal(StoredProc)=1)or IsStoredProp(AObject,actProp)then begin
            if actProp.PropType^.Kind=tkClass then begin
              obj:=THetObject(pointer(cardinal(AObject)+cardinal(GetProc)and $FFFFFF)^);
              if SetProc=nil then begin//subobj
                IO.IOSeek(oldPos);
                ReadObjectPropertiesDfm(obj,IO);
              end else begin//link
                linkCD:=ClassDescriptionCache.GetByTypeInfo(GetTypeData(PropType^).ClassType.ClassInfo);
                if linkCD.IdProp<>nil then begin//by id
                  _int:=PasToVar(s2);
                  if _int>0 then begin
                    lookupList:=AObject.getLookupList(actProp);
                    Assert(lookuplist<>nil,'ReadPropBin() can''t get lookuplist');
                    obj:=lookupList.ById[_int{-1}];
{                    if obj=nil then
                      raise Exception.Create(lookupList.ClassName+'.gethetobjbyid('+tostr(_int-1)+' fail');}
                  end else
                    obj:=nil;
                  SetOrdProp(AObject,actProp,integer(obj));
                end else if linkCD.NameProp<>nil then begin//by name
                  _ansistring:=PasToVar(s2);
                  if _ansistring<>'' then begin
                    lookupList:=AObject.getLookupList(actProp);
                    Assert(lookuplist<>nil,'ReadPropBin() can''t get lookuplist');
                    obj:=lookupList.ByName[_ansistring];
                  end else
                    obj:=nil;
                  SetOrdProp(AObject,actProp,integer(obj));
                end else begin//by index
                  _int:=PasToVar(s2);
                  if _int>0 then begin
                    lookupList:=AObject.getLookupList(actProp);
                    Assert(lookuplist<>nil,'ReadPropBin() can''t get lookuplist');
                    obj:=lookupList.ByIndex[_int-1];
                  end else
                    obj:=nil;
                  SetOrdProp(AObject,actProp,integer(obj));
                end;
              end;

            end else begin
              if(actProp=CD.IdProp)then
                AObject._SetID(PasToVar(s2))
              else begin
                if actProp.PropType^.Kind=tkInt64 then
                  SetPropValue(AObject,actProp,StrToInt64(s2))
                else
                  try SetPropValue(AObject,actProp,PasToVar(s2));except end;
              end;
            end;
          end;
      end;

    end;
  end;

  FormatSettings.DecimalSeparator:=oldDs;

  AObject.NotifyChange;
end;

function DetectDFM(AST:TIO):boolean;
var p0:integer;
    s:array[1..6]of ansichar;
begin with AST do begin
  p0:=IOPos;
  while IOPeekChr in[' ',#9,#10,#13]do IOSeek(IOPos+1);

  IOPeek(s,6);
  result:=cmp(s,'object')=0;

  if not result then
    IOSeek(p0);//seek back if not dfm
end;end;

procedure ReadObjectProperties(const AObject:THetObject;const AST:TIO);
begin
  if DetectDFM(AST)then ReadObjectPropertiesDfm(AObject,AST)
                   else ReadObjectPropertiesBin(AObject,AST);
end;

procedure ReadObjectProperties(const AObject:THetObject;const Data:RawByteString);
var st:TIO;
begin
  st:=TIOBinReader.Create;
  try
    st.Data:=Data;
    ReadObjectProperties(AObject,st);
  finally
    st.Free;
  end;
end;


function ReadHetObject(const AOwner:THetObject;const IO:TIO):THetObject;
var Hash:integer;
    i:integer;
    CD:TClassDescription;
    serType:TSerializeType;
begin
  if DetectDFM(IO)then serType:=stDfm
                  else serType:=stBin;

  //het classHash
  Hash:=0;
  case serType of
    stBin:IO.IOPeek(Hash,4);
    stDfm:begin
      i:=IO.IOPos;
      ReadThing(IO);
      Hash:=Crc32UC(ReadThing(IO));
      IO.IOSeek(i);
    end;
  end;

  CD:=ClassDescriptionOf(Hash);
  if CD=nil then raise Exception.Create('het.Objects.ReadHetObject(): Unknown ClassHash');

  result:=THetObjectClass(GetTypeData(CD.TypeInfo).ClassType).Create(AOwner);
  result.Serialize(IO, serType);
end;

{ THetObject }

{var _Root:THetObjectList=nil;
    CreatingRoot:boolean=false;
function Root:THetObjectList;
begin
  if _Root=nil then begin
    CreatingRoot:=true;
    _Root:=THetObjectList.Create(nil);
    CreatingRoot:=false;
  end;
  result:=_Root;
end;}

constructor THetObject.Create(const AOwner:THetObject);
begin
  if AOwner<>nil then
    FOwner:=AOwner
  else
{    if CreatingRoot then
      FOwner:=nil
    else}
      FOwner:=Root;

  if(FOwner is THetObjectList)and(stListActive in THetObjectList(FOwner).ObjState)then
    THetObjectList(FOwner)._AppendListObj(self);

  NotifyCreate;

  with ClassDesc do begin
    SetDefaults(self);
    CreateSubObjs(self);
  end;

  AfterCreate;
end;

destructor THetObject.Destroy;
var i:integer;
begin
  NotifyDestroy;
  with FReferences do for i:=0 to FCount-1 do FItems[i]._LinkedObjDestroying(self);FReferences.FCount:=0;
  if Assigned(FOwner)then FOwner._SubObjDestroying(self);
  with ClassDesc do begin
    ClearLinkedObjs(self);
    FreeSubObjs(self);
  end;
end;

procedure THetObject.AfterCreate;
begin
end;

procedure THetObject.Serialize(const st: TIO;const SerType:TSerializeType);
begin
  if st.IOWriting then begin
    case SerType of
      stBin:WriteObjectBin(self,st);
      stDfm:WriteObjectDfm(self,st);
    end;
  end else
    ReadObjectProperties(self,st);
end;

function THetObject._Dump(const AIndent: integer):ansistring;

  function DumpOne(o:THetObject):ansistring;
    function GetNameOrPtr:ansistring;
    begin result:=o.getName;if result='' then result:='$'+inttohex(integer(o),8);end;
  begin
    if o=nil then result:=result+'nil'
             else result:='('+getNameOrPtr+':'+o.ClassName+')';
  end;

begin
  result:=DumpOne(self);
  if self<>nil then begin
    result:=result+' Owner='+DumpOne(FOwner);
    if FOwner<>nil then
      result:=result+'.Owner='+DumpOne(FOwner.FOwner);
  end;

  result:=Indent('  ',AIndent)+result+#13#10;
end;

function THetObject.getId: TId;
begin
  if self=nil then exit(0);//nil safe
  with ClassDesc do begin
    if IdProp<>nil then result:=pinteger(cardinal(self)+cardinal(IdProp.GetProc)and $FFFFFF)^
                   else result:=0;
  end;
end;

procedure THetObject.setId(const aId:TId);
var p:PInteger;
begin with ClassDesc do begin
  if IdProp<>nil then begin
    p:=pinteger(cardinal(self)+cardinal(IdProp.GetProc)and $FFFFFF);
    if p^<>aId then begin
      p^:=aId;
      NotifyChange;
    end;
  end;
end;end;

procedure THetObject.SetName(const AName: TName);
var p:PAnsiString;
begin with ClassDesc do begin
  if NameProp<>nil then begin
    p:=pAnsiString(cardinal(self)+cardinal(NameProp.GetProc)and $FFFFFF);
    if p^<>AName then begin
      p^:=AName;
      NotifyChange;
    end;
  end;
end;end;

function THetObject.getIndex: integer;
begin
  if self=nil then exit(-1);//nil safe
  if FOwner is THetObjectList then result:=THetObjectList(FOwner).IndexOf(self)
                              else result:=-1;
end;

procedure THetObject.setIndex(const newIdx:integer);
var oldIdx:integer;
begin
  if FOwner is THetObjectList then begin
    oldIdx:=THetObjectList(FOwner).IndexOf(self);
    if(oldIdx>=0)then
      THetObjectList(FOwner).Move(oldIdx,newIdx);
  end;
end;

function THetObject.SubObjName: AnsiString;
var i:integer;
begin
  result:='';
  if FOwner=nil then exit;
  with FOwner.ClassDesc do
    for i:=0 to high(SubObjects)do
      if GetOrdProp(FOwner,SubObjects[i])=integer(self) then
        exit(Subobjects[i].Name);
end;

function THetObject.getFieldAsVariant(const AFieldName: ansistring): Variant;
const types=[tkInteger,tkInt64,tkChar,tkEnumeration,tkSet,tkFloat,tkString,tkLString,tkUString,tkWString];
var cd:TClassDescription;
    pi:PPropInfo;
begin
  cd:=ClassDesc;
  pi:=cd.PropInfoByName(AFieldName);
  if(pi<>nil)and(pi.GetProc<>nil)and(pi.PropType^.Kind in Types)then
    Result:=GetPropValue(self,pi,false)
  else
    Result:=Unassigned;
end;

procedure THetObject.setFieldAsVariant(const AFieldName: ansistring; const Value: Variant);
const types=[tkInteger,tkInt64,tkChar,tkEnumeration,tkSet,tkFloat,tkString,tkLString,tkUString,tkWString];
var cd:TClassDescription;
    pi:PPropInfo;
begin
  cd:=ClassDesc;
  pi:=cd.PropInfoByName(AFieldName);
  if(pi<>nil)and(pi.SetProc<>nil)and(pi.PropType^.Kind in types)then
    SetPropValue(self,pi,Value);
  //!!!!!!!!!!!Classra figyelni majd
end;

function THetObject.getLookupList(const PropInfo: PPropInfo): THetObjectList;
begin
  raise Exception.Create('Unable to get LookupList for '+ClassName+'.'+PropInfo.Name);
end;

function THetObject.getName: TName;
begin
  if self=nil then exit('');//nil safe
  with ClassDesc do begin
    if NameProp<>nil then result:=GetStrProp(self,NameProp)
                     else result:='';
  end;
end;

function THetObject.IsNil: boolean;
begin
  result:=Self=nil;
end;

class function THetObject.ClassDesc: TClassDescription;
begin
  result:=ClassDescriptionCache.GetByTypeInfo(ClassInfo);
end;

procedure THetObject.NotifyChange;
begin
  ObjState:=ObjState+[stChangedSave];  //only when changed, not on create/destroy
  ChangeEventDispatcher(self,ctChange);
end;

procedure THetObject.NotifyCreate;
begin
  ChangeEventDispatcher(self,ctCreate);
end;

procedure THetObject.NotifyDestroy;
begin
  ChangeEventDispatcher(self,ctDestroy);
end;

procedure THetObject.ChangeEventDispatcher(const AObj:THetObject;const AChangeType:TChangeType);
var i:integer;
begin
  ObjState:=ObjState+stChangedAll;
  ObjectChanged(AObj,AChangeType);
  if Assigned(FOwner)then FOwner.ChangeEventDispatcher(AObj,AChangeType);
  with FReferences do for i:=0 to FCount-1 do FItems[i].ChangeEventDispatcher(AObj,AChangeType);//rekurziv szivas
end;

procedure THetObject.ObjectChanged;
begin
end;

procedure THetObject._AddReference(const AObj:THetObject);
begin
  FReferences.Append(AObj);
end;

procedure THetObject._RemoveReference(const AObj:THetObject);
var i:integer;
begin
  for i:=FReferences.FCount-1 downto 0 do
    if FReferences.FItems[i]=AObj then begin
      FReferences.Remove(i);
      exit;
    end;
end;

procedure THetObject._SetID(const AID: integer);
var pi:PPropInfo;
begin
  pi:=ClassDesc.IdProp;
  if pi<>nil then begin
    pinteger(integer(self)+(integer(pi.GetProc)and $FFFFFF))^:=AID;
//    NotifyChange;
  end;
end;

procedure THetObject._SubObjDestroying(const AObj:THetObject);
{var i:integer;
    p:ppointer;}
begin
  {semmi, mert subobjokat nem destroyozunk, azok csak a main obj altal szabadulhatnak fel}
{  with ClassDesc do begin
    for i:=0 to high(SubObjects)do with SubObjects[i]^ do begin
      p:=pointer(cardinal(self)+cardinal(GetProc)and $FFFFFF);
      if p^=AObj then begin
        p^:=nil;
        NotifyChange;
        exit;
      end;
    end;
    Assert(false,'Subobject not found');
  end;}
end;

procedure THetObject._LinkedObjDestroying(const AObj:THetObject);
var i:integer;
    p:ppointer;
begin
  with ClassDesc do begin
    for i:=0 to high(LinkedObjects)do with LinkedObjects[i]^ do begin
      p:=pointer(cardinal(self)+cardinal(GetProc)and $FFFFFF);
      if p^=AObj then begin
        p^:=nil;
        NotifyChange;
      end;
    end;
  end;
end;

procedure THetObject.Reset;
begin
  ClassDesc.Reset(self);
end;

procedure THetObject.LoadFromStr(const Data:RawByteString);
var st:TIO;
begin
  if pointer(Data)=nil then begin
    Reset;
    exit
  end;
  st:=TIOBinReader.Create;
  st.Data:=Data;
  try
    Serialize(st,stBin);
  finally
    st.Free;
  end;
end;

function THetObject.SaveToStr;
var st:TIO;
begin
  setlength(result,0);
  st:=TIOBinWriter.Create;
  try
    Serialize(st,serType);
    result:=st.Data;
  finally
    st.Free;
  end;
end;

function THetObject.TryLoadFromFile(const FN:string):boolean;
var data:RawByteString;
begin
  data:=TFile(FN);
  if Data='' then exit(false);
  LoadFromStr(data);
  result:=true;
end;

procedure THetObject.LoadFromFile(const FN:string);
var data:RawByteString;
begin
  data:=TFile(fn);
  if data='' then raise Exception.Create(ClassName+'.LoadFromFile() File not found or empty "'+FN+'"');
  LoadFromStr(data);
end;

procedure THetObject.SaveToFile(const FN:string;const serType:TSerializeType);
begin
  TFile(FN).Write(SaveToStr(serType));
end;

function THetObject.ContentHash: integer;
var st:TIO;
begin
  st:=TIOBinWriter.Create;
  try
    st.FObjStorageFormat:=sfBin;
    st.FDontWriteClassInfo:=true;
    st.IO(TObject(self));
    result:=crc32(st.Data);
  finally
    st.Free;
  end;
end;

function THetObject.Validate: TArray<ansistring>;
begin
  result:=ClassDesc.Validate(self);
end;

function THetObject.ValidateStr: ansistring;
begin
  result:=ListMake(Validate,#13#10,true);
end;

{ THetObjectViewSettings }

destructor THetObjectViewSettings.Destroy;
begin
  Reset;
  inherited;
end;

procedure THetObjectViewSettings.Reset;
var i:integer;
begin
  for i:=0 to high(FOrderBy)do FOrderBy[i].Node.Free;
  setlength(FOrderBy,0);

  for i:=0 to high(FWhereAnd)do FWhereAnd[i].Node.Free;
  setlength(FWhereAnd,0);

  FreeAndNil(FNameSpace);
  FreeAndNil(FCtx);
end;

procedure THetObjectViewSettings.SetDefinition;

  procedure AddOrderBy(s:ansistring);
  var n:TNodeBase;
      d:boolean;
  begin
    d:=charn(s,1)='-';
    if d then delete(s,1,1);
    n:=CompilePascalProgram(s,TNameSpace(FNameSpace));
    if n<>nil then begin
      SetLength(FOrderBy,length(FOrderBy)+1);
      with FOrderBy[high(FOrderBy)]do begin
        node:=n;
        desc:=switch(d,-1,1);
      end;
    end;
  end;

  procedure AddWhereAnd(const s:ansistring);
  var n:TNodeBase;
  begin
    n:=CompilePascalProgram(s,TNameSpace(FNameSpace));
    if n<>nil then begin
      SetLength(FWhereAnd,length(FWhereAnd)+1);
      with FWhereAnd[high(FWhereAnd)]do begin
        node:=n;
      end;
    end;
  end;

var sOrder,s:ansistring;
    i:integer;
begin
  if Value<>FDefinition then begin
    Reset;

    FDefinition:=Value;
    FHash:=Crc32UC(FDefinition);
    if FUnique then FHash:=FHash xor integer(self);

    try
      FNameSpace:=TNameSpace.Create('nsHetObjectComparer');
      FNameSpace.nsUses.Append(nsSystem);
      FCtx:=TContext.Create(nil,FNameSpace,nil);
      FCtx.WithStack.Append(nil);

      sOrder:=ListItem(FDefinition,0,'|');
      for s in ListSplit(sOrder,',')do
        AddOrderBy(s);

      for i:=1 to ListCount(FDefinition,'|')-1 do
        AddWhereAnd(ListItem(FDefinition,i,'|'));

    except
      Reset;
    end;

  end;
end;

function THetObjectViewSettings.Compare(const a,b:THetObject):integer;
var i:integer;
    va,vb:Variant;
begin
  for i:=0 to high(FOrderBy)do with FOrderBy[i]do begin

    FCtx.WithStack.FItems[0]:=a;
    node.Eval(FCtx,va);

    FCtx.WithStack.FItems[0]:=b;
    node.Eval(FCtx,vb);

    if va<vb then exit(-desc);
    if va>vb then exit(desc);
  end;
  result:=0;
end;

function THetObjectViewSettings.Filter(const a:THetObject):boolean;
var i:integer;
    b:boolean;
begin
  b:=false;//anti warning
  result:=true;
  if length(FWhereAnd)>0 then begin
    Assert(FCtx.WithStack.Count=1,'THetObjectViewSettings.Filter ctx.withstack.count<>1');
    FCtx.WithStack.FItems[0]:=a;
    for i:=0 to high(FWhereAnd)do with FWhereAnd[i]do
      try b:=node.Eval(FCtx)except b:=false end;//!!!!!!!!!!!!!!!ez a try except ide elvileg nem kell
      if not b then exit(false);
  end;
end;

function THetObjectViewSettings.FindValues(const a:THetObject):integer;
var i,k:integer;
    va:PVariant;
    vb:Variant;
begin
  k:=high(FValueStack);
  for i:=0 to max(high(FOrderBy),high(FValueStack[k]))do with FOrderBy[i]do begin

    FCtx.WithStack.FItems[0]:=a;
    node.Eval(FCtx,vb);

    va:=@FValueStack[k,i];

    if va^<vb then exit(-desc);
    if va^>vb then exit(desc);
  end;
  result:=0;
end;

procedure THetObjectViewSettings.PopValues;
begin
  setlength(FValueStack,high(FValueStack));
end;

procedure THetObjectViewSettings.PushValues(const values: array of const);
var i,k:integer;
begin
  setlength(FValueStack,Length(FValueStack)+1);
  k:=high(FValueStack);
  setlength(FValueStack[k],length(values));
  for i:=0 to high(values)do with values[i]do case VType of
    vtInteger       :FValueStack[k,i]:=VInteger;
    vtBoolean       :FValueStack[k,i]:=VBoolean;
    vtChar          :FValueStack[k,i]:=VChar;
    vtExtended      :FValueStack[k,i]:=VExtended^;
    vtString        :FValueStack[k,i]:=VString^;
    vtPointer       :{FValueStack[k,i]:=                 Unassigned};
    vtPChar         :FValueStack[k,i]:=VPChar^;
    vtObject        :FValueStack[k,i]:=het.Variants.VObject(VObject);
    vtClass         :FValueStack[k,i]:=het.Variants.VClass(VClass);
    vtWideChar      :FValueStack[k,i]:=VWideChar;
    vtPWideChar     :FValueStack[k,i]:=VPWideChar^;
    vtAnsiString    :FValueStack[k,i]:=AnsiString(VAnsiString);
    vtCurrency      :FValueStack[k,i]:=VCurrency^;
    vtVariant       :FValueStack[k,i]:=VVariant^;
    vtInterface     :FValueStack[k,i]:=IInterface(VInterface);
    vtWideString    :FValueStack[k,i]:=WideString(VWideString);
    vtInt64         :FValueStack[k,i]:=VInt64^;
    vtUnicodeString :FValueStack[k,i]:=UnicodeString(VUnicodeString);
  end;
end;

{ THetObjectList }

function THetObjectList.GetById(const AId: integer): THetObject;
var idx:integer;
begin
  //binary search baszki?!!!
//  {slow search}with FItems do for i:=0 to FCount-1 do if FItems[i].getId=AId then exit(FItems[i]);
  with View['id']do
    if FItems.FindBinary(function(const a:THetObject):integer begin result:=AId-a.getId end,idx)then
      exit(FItems.FItems[idx]);
  result:=nil;
end;

function THetObjectList.GetByIndex(const AIdx: integer): THetObject;
begin
  with FItems do if AIdx<FCount then result:=FItems[AIdx]
                                else result:=nil;
end;

function THetObjectList.GetByName(const AName: ansistring): THetObject;
var idx:integer;
begin
  with View['name']do
    if FItems.FindBinary(function(const a:THetObject):integer begin result:=cmp(AName,a.getName)end,idx)then
      exit(FItems.FItems[idx]);
  result:=GetByNameCached(AName);//create new
end;

function THetObjectList.GetIsView: boolean;
begin
//  result:=ClassType.ClassParent=THetObjectListView; {ez volt a régi}
  result:=stView in ObjState;
end;

function THetObjectList.GetIsViewUnique: boolean;
begin
  result:=(FViewSettings<>nil)and(FViewSettings.FUnique);
end;

function THetObjectList.getNextItemId: integer;
begin
  with FItems do if FCount>0 then result:=FItems[FCount-1].getId+1
                             else result:=1;
end;

function THetObjectList.getNextItemNameFor(const AObj:THetObject):ansistring;
var idx,i,j:integer;
    n:ansistring;
begin
  result:=AObj.ClassName+'1';
  if charn(result,1)='T' then delete(result,1,1);

  idx:=FindBinaryIdx('Name',[result]);
  if idx>=0 then begin
    setlength(result,length(result)-1);j:=1;
    for i:=0 to FItems.Count-1 do if FItems.FItems[i]<>self then begin
      n:=FItems.FItems[i].getName;
      if cmp(n,result+toStr(j))=0 then inc(j)
    end;
    result:=result+toStr(j);
  end;
end;

function THetObjectList.IndexOf(const AObj: THetObject):integer;var i:integer;
begin
  with FItems do for i:=0 to FCount-1 do if FItems[i]=AObj then exit(i);
  result:=-1;
end;

procedure THetObjectList.Sort;
begin
  if FViewSettings=nil then exit;
  FItems.QuickSort(FViewSettings.Compare);
  NotifyChange;
end;

procedure THetObjectList.Exchange(const Idx1, Idx2: integer);
begin
  FItems.Exchange(Idx1,Idx2);
end;

function THetObjectList.FindBinaryIdx(const AFields: ansistring;const AValues:array of const):integer;
begin
  result:=-1;
  with View[AFields]do begin
    FViewSettings.PushValues(AValues);
    try
      if not FItems.FindBinary(FViewSettings.FindValues,result)then result:=-1;
    finally
      FViewSettings.PopValues;
    end;
  end;
end;

function THetObjectList.FindBinary(const AFields: ansistring;const AValues:array of const):THetObject;
var idx:integer;
begin
  result:=nil;
  with View[AFields]do begin
    FViewSettings.PushValues(AValues);
    try
      if FItems.FindBinary(FViewSettings.FindValues,idx)then result:=FItems.FItems[idx];
    finally
      FViewSettings.PopValues;
    end;
  end;
end;

function THetObjectList.FindBinaryNearestIdx(const AFields: ansistring;const AValues:array of const):integer;
begin
  result:=-1;
  with View[AFields]do begin
    FViewSettings.PushValues(AValues);
    try
      FItems.FindBinary(FViewSettings.FindValues,result);
    finally
      FViewSettings.PopValues;
    end;
  end;
end;

function THetObjectList.FindBinaryIdxRange(const AFields: ansistring;const AValues:array of const):TIdxRange;
begin
  with View[AFields]do begin
    FViewSettings.PushValues(AValues);
    try
      if FItems.FindBinary(FViewSettings.FindValues,result.st)then begin
        result.en:=result.st;
        while(result.St>0)and(FViewSettings.FindValues(FItems.FItems[result.St-1])=0)do
          dec(result.St);
        while(result.En<FItems.FCount-1)and(FViewSettings.FindValues(FItems.FItems[result.En+1])=0)do
          inc(result.En);
      end else begin
        result.St:=0;
        result.En:=-1;
      end;
    finally
      FViewSettings.PopValues;
    end;
  end;
end;

function THetObjectList.FindBinaryRange(const AFields: ansistring;const AValues:array of const):TArray<THetObject>;
var tmp:THetArray<THetObject>;
    i,st,en:integer;
begin
  tmp.Clear;

  with View[AFields]do begin
    FViewSettings.PushValues(AValues);
    try
      if FItems.FindBinary(FViewSettings.FindValues,st)then begin
        en:=st;
        while(St>0)and(FViewSettings.FindValues(FItems.FItems[St-1])=0)do
          dec(St);
        while(En<FItems.FCount-1)and(FViewSettings.FindValues(FItems.FItems[En+1])=0)do
          inc(En);
      end else begin
        St:=0;
        En:=-1;
      end;
    finally
      FViewSettings.PopValues;
    end;

    for i:=st to en do
      tmp.Append(FItems.FItems[i]);
    tmp.Compact;
  end;
  result:=tmp.FItems;
end;

procedure THetObjectList.Move(const Idx1, Idx2: integer);
begin
  if(Idx1=Idx2)then exit;
  FItems.Move(Idx1,Idx2);
  NotifyChange;
end;

function THetObjectList.NewUniqueView(const ADef:ansistring): THetObjectList;
begin
  if IsView then exit(ViewBase.NewUniqueView(ADef));

  result:=NewView;
  with result do begin
    FViewSettings:=THetObjectViewSettings.create;
    FViewSettings.FUnique:=true;
    FViewSettings.Definition:=ADef;
    Result.NotifyChange;//sort by hash
  end;
  result.RefreshView;
end;

procedure THetObjectList.ChangeEventDispatcher(const AObj:THetObject;const AChangeType:TChangeType);
var i:integer;
begin
  inherited;

  if AObj=FViews then exit;

  //View-eken is vegigmengy a main.change
  if FViews<>nil then
    for i:=0 to FViews.Count-1 do
      FViews.GetByIndex(i).ObjectChanged(AObj,AChangeType);
end;

procedure THetObjectList.ObjectChanged(const AObj: THetObject;const AChangeType:TChangeType);
var i,idx:integer;
begin
  inherited;

  if AChangeType=ctDestroy then exit;

  if AObj=FViews then exit;

  if IsView and (stListClearing in ViewBase.ObjState) then exit;

  //resort
  if(FViewSettings<>nil)and(AObj.FOwner=ViewBase)then begin
    idx:=-1;with FItems do for i:=FCount-1 downto 0 do if FItems[i]=AObj then begin idx:=i;break end;

    if FViewSettings.Filter(AObj)then begin//filter passed
      if(idx<0)and IsView then begin
        FItems.Append(AObj);
        idx:=FItems.FCount-1;
      end;
      if idx>=0 then begin
        FItems.Move(idx,FItems.FindNewPosBinary(idx,FViewSettings.Compare));
        NotifyChange;
      end;
    end else begin//fitered out from a view
      if(idx>=0)and IsView then begin
        FItems.Remove(idx);
        NotifyChange;
      end;
    end;
  end;
  if assigned(FViews)then with FViews.FItems do for i:=0 to FCount-1 do FItems[i].ObjectChanged(AObj,AChangeType);
end;

procedure THetObjectList._AppendListObj(const AListObj: THetObject);
var p:pinteger;
    i:integer;
begin
  if self<>root then with AListObj.ClassDesc do begin
    if IdProp<>nil then begin
      p:=pointer(cardinal(AListObj)+cardinal(IdProp.GetProc) and $FFFFFF);
      p^:=getNextItemId;
    end else if NameProp<>nil then begin
      {$IFNDEF NOINCREMENTALNAME}
        SetStrProp(AListObj,NameProp,getNextItemNameFor(AListObj));
      {$ENDIF}
    end;
  end;

  FItems.Append(AListObj);
  if assigned(FViews)then with FViews.FItems do for i:=0 to FCount-1 do FItems[i].ObjectChanged(AListObj,ctChange);

  //uniform?
  if not (stListNonUniform in ObjState)then
    if AListObj.ClassType<>BaseClass then
      include(ObjState,stListNonUniform);

  NotifyChange;
end;

function THetObjectList._RemoveListObj(const AListObj: THetObject):boolean;
var i:integer;
begin
  i:=IndexOf(AListObj);
  if i>=0 then begin
    result:=true;

    FItems.Remove(i); //physical remove

    if FItems.FCount=0 then Exclude(ObjState,stListNonUniform);//empty list is always uniform

    if assigned(FViews) then with FViews.FItems do  //update views
      for i:=0 to FCount-1 do THetObjectList(FItems[i])._RemoveListObj(AListObj);

    NotifyChange;
  end else
    result:=false;
end;

procedure THetObjectList._SubObjDestroying(const AObj:THetObject);//!!!elnevezesben kavarodas van
begin
  if stListClearing in ObjState then exit;
  if _RemoveListObj(AObj)then exit;
  inherited;//subobj
end;

procedure THetObjectList.Clear;
var i:integer;
begin
  if FItems.FCount=0 then exit;
  ObjState:=ObjState+[stListClearing];
  try
    if not self.IsView then with FItems do begin
      for i:=FCount-1 downto 0 do
        FreeAndNil(FItems[i]);
      FCount:=0;
      setlength(FItems,0);
    end else
      FItems.Clear;

    if Assigned(FViews)then with FViews.FItems do for i:=0 to FCount-1 do THetObjectList(FItems[i]).Clear;
  finally
    ObjState:=ObjState-[stListClearing,stListNonUniform];
    NotifyChange;
  end;
end;

function THetObjectList.Count: integer;
begin
  result:=FItems.FCount;
end;

constructor THetObjectList.Create(const AOwner: THetObject);
begin
  inherited;
  ObjState:=ObjState+[stListActive];//!!! Ez mar a hetobjba kellene
  FBaseClass:=AcquireBaseClass;
end;

constructor THetObjectList.CreateAsView(const AOwner:THetObject);
begin
  ObjState:=ObjState+[stView];
  Create(AOwner);
end;

destructor THetObjectList.Destroy;
begin
  FreeAndNil(FViews);
  FreeAndNil(FViewSettings);

  Clear;
  inherited;
end;

function THetObjectList._Dump(const AIndent: integer): ansistring;
var i:integer;
begin
  result:=inherited _Dump(AIndent);
  result:=result+indent('  ',aindent)+'View:'+ViewDefinition+#13#10;
  if assigned(FViews)then for i:=0 to FViews.Count-1 do begin
    result:=result+THetObjectList(FViews.GetByIndex(i))._Dump(AIndent+2);
  end;
  result:=result+indent('  ',aindent)+'Items:'+tostr(Count)+#13#10;
  for i:=0 to Count-1 do
    result:=result+GetByIndex(i)._Dump(AIndent+1);
end;

function THetObjectList.AcquireBaseClass: THetObjectClass;
var cn:ansistring;
    cd:TClassDescription;
begin
  result:=nil;
  cn:=FindBetween(ClassParent.ClassName,'<','>');
  cn:=ListItem(cn,ListCount(cn,'.')-1,'.');
  if cn<>'' then begin
    cd:=ClassDescriptionOf(cn);
    if cd<>nil then
      result:=THetObjectClass(cd.FClass);
  end;
end;

function THetObjectList.GetByNameCached(const AName: ansistring): THetObject;
begin
  result:=nil;
end;

function THetObjectList.UniqueName(const AName:ansistring='';const AlwaysIndex:boolean=false):ansistring;
var i,Idx,MaxIdx:integer;
    n1,n2,sIdx:ansistring;
begin
  if AName='' then exit(UniqueName('noname'));
  if not AlwaysIndex and(GetByName(AName)=nil)then exit(AName);

  n1:=AName;while(n1<>'')and(n1[length(n1)]in['0'..'9']) do setlength(n1,length(n1)-1);
  if n1='' then n1:='noname';

  MaxIdx:=1;
  for i:=0 to Count-1 do begin
    n2:=FItems.FItems[i].getName;
    if cmp(copy(n2,1,length(n1)),n1)=0 then begin
      sIdx:=copy(n2,length(n1)+1,100);
      idx:=strtointdef(sIdx,0)+1;
      if Idx>MaxIdx then
        MaxIdx:=Idx;
    end;
  end;
  result:=n1+toStr(maxIdx);
end;

function THetObjectList.GetViewByHash(const AHash: integer): THetObjectList;
var idx:integer;
begin
  if IsView then exit(THetObjectList(FOwner).GetViewByHash(AHash));
  if Assigned(FViewSettings)and(FViewSettings.FHash=AHash)then exit(self);
  if Assigned(FViews) then if FViews.FItems.FindBinary(function(const a:THetObject):integer begin result:=THetObjectList(a).GetViewHash-AHash end,idx)then
    exit(THetObjectList(FViews.FItems.FItems[idx]));
  result:=nil;
end;

procedure THetObjectList.CopyItemsFrom(const ASrc:THetObjectList);
begin
  FItems.FCount:=ASrc.FItems.FCount;
  setlength(FItems.FItems,FItems.FCount);
  system.move(ASrc.FItems.FItems[0],FItems.FItems[0],length(FItems.FItems)*sizeof(ASrc.FItems.FItems[0]));
end;

procedure THetObjectList.RefreshView;
var i:integer;
    o:THetObject;
begin
  if FViewSettings=nil then exit;
  if IsView then begin
    if length(FViewSettings.FWhereAnd)=0 then begin
      CopyItemsFrom(THetObjectList(FOwner.FOwner))
    end else begin
      FItems.Clear;
      for i:=0 to THetObjectList(FOwner.FOwner).FItems.FCount-1 do begin
        o:=THetObjectList(FOwner.FOwner).FItems.FItems[i];
        if FViewSettings.Filter(o)then
          FItems.Append(o);
      end;
    end;

  end;

  Sort;
end;

procedure THetObjectList.CreateViewList;
begin
  if FViews<>nil then exit;
  ObjState:=ObjState-[stListActive];
  FViews:=THetObjectList.Create(self);
  ObjState:=ObjState+[stListActive];

  FViews.ObjState:=FViews.ObjState+[stViewList];
  FViews.ViewDefinition:='ViewHash';
end;

function THetObjectList.NewView:THetObjectList;
begin
  CreateViewList;
  result:=THetObjectList.CreateAsView(FViews);
end;

function THetObjectList.GetViewByDef(const ADef: ansistring): THetObjectList;
var h:integer;
begin
  if IsView then exit(ViewBase.GetViewByDef(ADef));
  h:=Crc32UC(ADef);
  result:=GetViewByHash(h);if assigned(result)then exit;

  result:=NewView;
  with result do begin
    FViewSettings:=THetObjectViewSettings.create;
    FViewSettings.Definition:=ADef;
    Result.NotifyChange;//sort
  end;
  result.RefreshView;

{    if length(FViewSettings.FWhereAnd)=0 then begin
      CopyItemsFrom(self)
    end else begin
      FItems.Clear;
      for i:=0 to self.FItems.FCount-1 do begin
        o:=self.FItems.FItems[i];
        if FViewSettings.Filter(o)then
          FItems.Append(o);
      end;
    end;
    Sort;
  end;}

end;

function THetObjectList.GetViewDefinition: ansistring;
begin
  if assigned(FViewSettings) then result:=FViewSettings.Definition
                             else result:='';
end;

procedure THetObjectList.SetViewDefinition(const Value: ansistring);
begin
  if Value=ViewDefinition then exit;
  if(Value<>'')and(FViewSettings=nil)then
    FViewSettings:=THetObjectViewSettings.Create;
  if assigned(FViewSettings) then begin
    FViewSettings.Definition:=Value;
    //RefreshView
  end;
end;

function THetObjectList.GetViewHash: integer;
begin
  if assigned(FViewSettings) then result:=FViewSettings.Hash
                             else result:=0;
end;

type
  TViewDefinitionRec=record
    Order,Filter:ansistring;
  end;

function DecodeViewDefinition(const def:ansistring):TViewDefinitionRec;
begin
  result.Order:=ListItem(def,0,'|');
  result.Filter:=copy(def,length(result.Order)+2);
end;

function EncodeViewDefinition(const order,filter:ansistring):ansistring;
begin
  result:=order;
  if filter<>'' then
    result:=result+'|'+filter;
end;

function THetObjectList.ViewAdjustFilter(const ANewFilter:ansistring):THetObjectList;
begin
  with DecodeViewDefinition(ViewDefinition)do
    result:=View[EncodeViewDefinition(order,ANewFilter)];
end;

function THetObjectList.ViewAdjustOrder(const ANewOrder:ansistring):THetObjectList;
begin
  with DecodeViewDefinition(ViewDefinition)do
    result:=View[EncodeViewDefinition(ANewOrder,filter)];
end;

function THetObjectList.ViewBase: THetObjectList;
begin
  if IsView then result:=THetObjectList(FOwner.FOwner)
            else result:=self;
end;

{ THetList<T> }

(*constructor THetList<T>.Create(const AOwner: THetObject);
var i,j:integer;
begin
  inherited;
//  j:=VMTIndex(self,@THetObjectList._SafeGetByIndex);PatchVMT(self,j+3*4,j);
//  j:=VMTIndex(self,@THetObjectList._SafeGetById);PatchVMT(self,j+3*4,j);
//  j:=VMTIndex(self,@THetObjectList._SafeGetByName);PatchVMT(self,j+3*4,j);
end;*)

//mappings

function THetList<T>.GetById(const AId: integer): T;
begin
  result:=T(THetObjectList(self).GetById(AId));
end;

function THetList<T>.GetByIndex(const AIndex: integer): T;
begin
  result:=T(THetObjectList(self).GetByIndex(AIndex));
end;

function THetList<T>.GetByName(const AName: ansistring): T;
begin
  result:=T(THetObjectList(self).GetByName(AName));
end;

function THetList<T>.GetViewByDef(const ADef:ansistring):THetList<T>;
begin
  result:=THetList<T>(THetObjectList(self).GetViewByDef(ADef));
                                               //^^^^^^ kell a cast!!!!
end;

function THetList<T>.NewListObj(const BaseClass: THetObjectClass): THetObject;
begin
  result:=BaseClass.Create(self);
end;

function THetList<T>.ViewBase: THetList<T>;
begin
  result:=THetList<T>(THetObjectList(Self).ViewBase);
end;

function THetList<T>.NewListObj: T;
begin
  result:=T(BaseClass.Create(ViewBase));
end;

function THetList<T>.NewView: THetObjectList;
begin
  CreateViewList;
  result:=THetList<T>.CreateAsView(FViews);
end;

procedure THetList<T>.ForEach(const proc:TProc<T>);
var i:integer;o:THetObject;
begin
  i:=0;
  with FItems do while i<FCount do begin
    o:=FItems[i];
    proc(o);
    if(i<FCount)and(o=FItems[i])then
      inc(i);//delete safe
  end;
end;

{ THetList<T>.TEnumerator }

{$IFDEF ENUMERATORS}
constructor THetList<T>.TEnumerator.Create(
  AList: THetList<T>);
begin
  FList:=AList;
  FIndex:=-1;
end;

function THetList<T>.TEnumerator.DoGetCurrent: T;
begin
  result:=FList.ByIndex[FIndex];
end;

function THetList<T>.TEnumerator.DoMoveNext: Boolean;
begin
  inc(FIndex);
  result:=(FIndex<FList.Count);
end;

function THetList<T>.GetEnumerator: TEnumerator;
begin
  result:=TEnumerator.Create(self);
end;
{$ENDIF}

var _ClassDescriptionCache:TClassDescriptionCache=nil;

function ClassDescriptionCache:TClassDescriptionCache;
begin
  if _ClassDescriptionCache=nil then
    _ClassDescriptionCache:=TClassDescriptionCache.Create;
  result:=_ClassDescriptionCache;
end;


{ TGenericHetObjectListView<T> }
(*
function TGenericHetObjectListView<T>.GetById(const AId: integer): T;
begin
  result:=T(GetHetObjById(AId));
end;

function TGenericHetObjectListView<T>.GetByIndex(const AIndex: integer): T;
begin
  result:=T(GetHetObjByIndex(AIndex));
end;

function TGenericHetObjectListView<T>.GetByName(const AName: ansistring): T;
begin
  result:=T(GetHetObjByName(AName));
end;

function TGenericHetObjectListView<T>.GetEnumerator: TEnumerator<T>;
begin
  result:=THetList<T>(self).getEnumerator;
end;

procedure TGenericHetObjectListView<T>.ForEach(const proc:TProc<T>);
var a:TArray<T>; o:T;
begin
  setlength(a,FItems.FCount);
  system.move(pointer(FItems.FItems)^,pointer(a)^,length(a)shl 2);
  for o in a do proc(o);
end;
*)
////////////////////////////////////////////////////////////////////////////////
///  Self Tests                                                              ///
////////////////////////////////////////////////////////////////////////////////

type
  TSelfTest=class(THetObject)
  private
    FName: ansistring;
    FValue: integer;
    procedure SetName(const Value: ansistring);
    procedure SetValue(const Value: integer);
  published
    property Name:ansistring read FName write SetName;
    property Value:integer read FValue write SetValue;
  end;

  TSelfTests=class(THetList<TSelfTest>)
  public
    property ByName;default;
  end;

{ TSelfTest }

{$O-}
procedure TSelfTest.SetName(const Value: ansistring);begin end;
procedure TSelfTest.SetValue(const Value: integer);begin end;
{$O+}

procedure SelfTest;
var list:TSelfTests;
    s:ansistring;
    i:integer;
    lv:THetObjectList;
//    stage:integer;
begin
    list:=TSelfTests.Create(nil);
    try
      //test lists, views
      TSelfTest.Create(list).Name:='Zoltan';
      TSelfTest.Create(list).Name:='Bea';
      TSelfTest.Create(list).Name:='Aladar';
      TSelfTest.Create(list).Name:='Emese';
      TSelfTest.Create(list).Name:='Denes';

      //kibaszottul fontos!!!!!! a het.parser elott kell legyen egy het.objects a unit listaban!
      list['Denes'].Value:=5;
      list['Bea'].Value:=3;
      list['Aladar'].Value:=2;
      list['Zoltan'].Value:=1;
      list['Emese'].Value:=3;

      lv:=list.View['-Value,Name|Value>1'];
      with lv do
        for i:=0 to Count-1 do
          s:=s+Eval('Name&Value',ByIndex[i]);

      if s<>'Denes5Bea3Emese3Aladar2' then
        raise Exception.Create('ListView test failed');

      //asm mov [$1234],eax end//manual error

    finally
      list.Free;
    end
end;

{ TIOTestSubObj }
{$O-}
procedure TIOTestSubObj.SetByte(const Value: byte);begin end;
{ TIOTestNamedObj }
procedure TIOTestNamedObj.SetByte(const Value: byte);begin end;
procedure TIOTestNamedObj.SetName(const Value: TName);begin end;
{ TIOTestIdedObj }
procedure TIOTestIdedObj.SetByte(const Value: byte);begin end;
{ TIOTestIndexedObj }
procedure TIOTestIndexedObj.SetByte(const Value: byte);begin end;
{ TIOTestHetObj }
procedure TIOTestObj.SetAnsiString(const Value: AnsiString);begin end;
procedure TIOTestObj.SetBoolean(const Value: Boolean);begin end;
procedure TIOTestObj.SetByte(const Value: byte);begin end;
procedure TIOTestObj.Setcardinal(const Value: cardinal);begin end;
procedure TIOTestObj.SetDate(const Value: TDate);begin end;
procedure TIOTestObj.SetDateTime(const Value: TDateTime);begin end;
procedure TIOTestObj.SetDouble(const Value: Double);begin end;
procedure TIOTestObj.SetExtended(const Value: Extended);begin end;
procedure TIOTestObj.SetIDedObj(const Value: TIOTestIDedObj);begin end;
procedure TIOTestObj.SetIndexedObj(const Value: TIOTestIndexedObj);begin end;
procedure TIOTestObj.Setint64(const Value: int64);begin end;
procedure TIOTestObj.Setinteger(const Value: integer);begin end;
procedure TIOTestObj.SetIOTestEnum(const Value: TIOTestEnum);begin end;
procedure TIOTestObj.SetIOTestSet(const Value: TIOTestSet);begin end;
procedure TIOTestObj.SetNamedObj(const Value: TIOTestNamedObj);begin end;
procedure TIOTestObj.SetShortInt(const Value: ShortInt);begin end;
procedure TIOTestObj.SetSingle(const Value: Single);begin end;
procedure TIOTestObj.SetSmallInt(const Value: SmallInt);begin end;
procedure TIOTestObj.SetSubObj(const Value: TIOTestSubObj);begin end;
procedure TIOTestObj.SetTime(const Value: TTime);begin end;
procedure TIOTestObj.Setuint64(const Value: uint64);begin end;
procedure TIOTestObj.SetUnicodeString(const Value: UnicodeString);begin end;
procedure TIOTestObj.SetWord(const Value: Word);begin end;
{$O+}

procedure _IOTest;
  procedure error(s:string);begin raise Exception.Create('IOTest failed:');end;

var
  namedList:TIOTestNamedObjList;
  IdedList:TIOTestIdedObjList;
  IndexedList:TIOTestIndexedObjList;

var o:TIOTestObj;

    named:TIOTestNamedObj;
    Ided:TIOTestIdedObj;
    Indexed:TIOTestIndexedObj;

    st:TIO;

    ow:THetObjectList;
begin
  ow:=THetObjectList.Create(nil);//parent for lists

  namedList:=TIOTestNamedObjList.Create(ow);
  named:=TIOTestNamedObj.Create(namedList);
  named.Name:='NAME';
  IdedList:=TIOTestIdedObjList.Create(ow);
  Ided:=TIOTestIdedObj.Create(IdedList);
  IndexedList:=TIOTestIndexedObjList.Create(ow);
    {Indexed:=}TIOTestIndexedObj.Create(IndexedList);
    Indexed:=TIOTestIndexedObj.Create(IndexedList);//idx=1

  o:=TIOTestObj.Create(ow);

  o._int64:=$7766554433221100;
  o._uint64:=$8866554433221100;
  o._Single:=1.2345;
  o._double:=2.3456;
  o._extended:=3.4567;
  o._Date:=12345;
  o._Time:=0.123;
  o._DateTime:=123456.123;
  o._AnsiString:='AnsiString';
  o._UnicodeString:='UnicodeString'#1234'ENDS';
  o._SubObj._Byte:=$AA;
  o._NamedObj:=named;
  o._IDedObj:=Ided;
  o._IndexedObj:=Indexed;

//  o.SaveToFile(stBin,'c:\hetObj_old.bin');

  st:=TIOBinWriter.Create;
  st.FObjStorageFormat:=sfBin;
  st.io(TObject(o));
//  TFile('c:\hetObj.bin').Write(st.Data);
  st.Free;

  ow.Free;
end;

{ _Default }

constructor _Default.Create(const ADefaultValue: single);
begin
  FDefaultValue:=ADefaultValue;
end;

{ _DefaultStr }

constructor _DefaultStr.Create(const ADefaultValue: string);
begin
  FDefaultValue:=ADefaultValue;
end;

{ _Range }

constructor _Range.Create(const AMinValue, AMaxValue: single);
begin
  FMinValue:=AMinValue;
  FMaxValue:=AMaxValue;
end;



function DumpRoot:ansistring;
var i:integer;
begin
  with AnsiStringBuilder(result, true)do for i:=0 to root.Count-1 do begin
    AddStr(tostr(i)+' : ');
    try
      AddLine(root.ByIndex[i].ClassName);
    except
      on e:exception do AddLine('EXCEPTION : '+e.ClassName+' '+e.Message);
    end;
  end;
end;

initialization
  RttiContext:=TRttiContext.Create;

  PatchInitPropertySetterFunctions(@THetObject._AddReference,@THetObject._RemoveReference);

  PPointer(@Root)^:=THetObjectList.Create(nil);

  try
    //SelfTest;
//    _IOTest;
  except
    on e:exception do begin
      if MessageBox('Start the application anyways?'#13#10'(Win7+ note: This error might be caused by "Data Execution Prevention", you can run the application after disabling it.)','SelfTest failed',MB_ICONWARNING+MB_YESNO)=ID_NO then begin
        MessageBox(e.ClassName+' '+e.Message+#13#10+lastExceptionDebugInfo,'SelfTest exception',MB_ICONERROR+MB_OK);
        TerminateProcess(GetCurrentProcess,1);
//        raise Exception.Create('FATAL ERROR: HetObj.SelfTest FAILED ('+e.Message+')');
      end;
    end;
  end;
finalization
//  if TFile('c:\het').Exists then TFile('c:\hetObjRoot.txt').Write(DumpRoot);

  FreeAndNil(PPointer(@Root)^);

  FreeAndNil(_ClassDescriptionCache);
  RttiContext.Free;
  //!!!!!!!!!!!!!  QRVANAGY BUG d2009, valami miatt ez a hetfilesys.pas a hetobj.PAS elott hivodik meg
  //debug kell
end.
