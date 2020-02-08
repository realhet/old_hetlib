unit het.typeinfo;//system het.bignum

interface

uses
  SysUtils, het.Utils, het.Arrays, TypInfo, Rtti;

type                 //extra
  THetBaseType=(btUnknown, btOrd, btFloat, btStr, btObj);

  THetType=(
    htUnknown,
    htId,
    htName,
    htShortInt,
    htSmallInt,
    htInteger,
    htInt64,
    htByte,
    htWord,
    htCardinal,
    htUInt64,
    htBoolean,
    htEnum,          //NameList
    htSet,           //NameList
    htSingle,
    htDouble,
    htExtended,
    htDate,
    htTime,
    htDateTime,
    htAnsiString,
    htUnicodeString,
    htSubObj,        //ObjType
    htObjId,         //ObjType
    htObjName,       //ObjType
    htObjIdx         //ObjType
  );

const
  HetTypeDetails:array[THetType]of record
    Base:THetBaseType;
    RawSize:byte;
    binWr:procedure
  end=(
{htUnknown      }(Base: btUnknown  ;RawSize: 0  ),
{htId           }(Base: btOrd      ;RawSize: 0  ),
{htName         }(Base: btStr      ;RawSize: 0  ),
{htShortInt     }(Base: btOrd      ;RawSize: 1  ),
{htSmallInt     }(Base: btOrd      ;RawSize: 2  ),
{htInteger      }(Base: btOrd      ;RawSize: 4  ),
{htInt64        }(Base: btOrd      ;RawSize: 8  ),
{htByte         }(Base: btOrd      ;RawSize: 1  ),
{htWord         }(Base: btOrd      ;RawSize: 2  ),
{htCardinal     }(Base: btOrd      ;RawSize: 4  ),
{htUInt64       }(Base: btOrd      ;RawSize: 8  ),
{htBoolean      }(Base: btOrd      ;RawSize: 1  ),
{htEnum         }(Base: btOrd      ;RawSize: 0  ),
{htSet          }(Base: btOrd      ;RawSize: 0  ),
{htSingle       }(Base: btFloat    ;RawSize: 4  ),
{htDouble       }(Base: btFloat    ;RawSize: 8  ),
{htExtended     }(Base: btFloat    ;RawSize:10  ),
{htDate         }(Base: btFloat    ;RawSize: 4  ),
{htTime         }(Base: btFloat    ;RawSize: 4  ),
{htDateTime     }(Base: btFloat    ;RawSize: 8  ),
{htAnsiString   }(Base: btStr      ;RawSize: 0  ),
{htUnicodeString}(Base: btStr      ;RawSize: 0  ),
{htSubObj       }(Base: btObj      ;RawSize: 0  ),
{htObjId        }(Base: btObj      ;RawSize: 0  ),
{htObjName      }(Base: btObj      ;RawSize: 0  ),
{htObjIdx       }(Base: btObj      ;RawSize: 0  ));

type
  THetTypeFlag=(flId,flName,flField,flReadOnly,flStored,flAlwaysStored);
  THetTypeFlags=set of THetTypeFlag;

  THetTypeRec=record
  private
    procedure _RecalculateFlags;
  public
    ObjClass:TClass;
    EnumNames:TArray<ansistring>;
    Typ:THetType;
    //redundant calculated stuff
    BaseTyp:THetBaseType;
    Flags:THetTypeFlags;
    RawSize:byte;
    procedure ImportRttiProperty(const AProp:TRttiProperty);
  end;

  PHetFieldDef=^THetFieldDef;
  THetFieldDef=record
    Name:ansistring;
    PropInfo:PPropInfo; //importalasnal ez mutat az eredeti propinfora
    Map:PHetFieldDef;   //importalasnal ez mutat az eredeti FieldDefArray-ra
    Typ:THetTypeRec;
    procedure IO(st:TObject);
  end;

function ClassByName(const AName:ansistring):TClass;
function ClassByHash(const AHash:integer):TClass;

function RttiTypeByName(const AName:ansistring):TRttiType;
function RttiTypeByHash(const AHash:integer):TRttiType;

function TypeDump(const ti:PTypeInfo):ansistring;
function TypeSize(const ti:PTypeInfo):integer;

implementation

uses
  het.Objects, het.stream;

var
  RttiContext:TRttiContext;
  RttiTypes:TArray<TRttiType>;

function RttiTypeByName(const AName:ansistring):TRttiType;
begin
  result:=RttiTypeByHash(Crc32UC(AName));
end;

function RttiTypeByHash(const AHash:integer):TRttiType;
var t:TRttiType;
begin
  for t in RttiTypes do
    if(Crc32UC(t.Name)=AHash)and(t.TypeKind=tkClass)then
      exit(t);
  result:=nil;
end;

function ClassByHash(const AHash:integer):TClass;
var t:TRttiType;
begin
  t:=RttiTypeByHash(AHash);
  if t=nil then result:=nil
           else result:=GetTypeData(t.Handle).ClassType;
end;

function ClassByName(const AName:ansistring):TClass;
begin
  Result:=ClassByHash(Crc32UC(AName));
end;

function TypeDump(const ti:PTypeInfo):ansistring;
var td:PTypeData;
begin
  result:='('+ti.Name+' '+GetEnumName(typeinfo(ttypekind),ord(ti.Kind))+' ';
  td:=GetTypeData(ti);
  case ti.Kind of
    tkUnknown, tkWString, tkUString, tkVariant:;
    tkLString:result:=result+'CodePage:'+inttostr(td.CodePage)+' ';
    tkInteger, tkChar, tkEnumeration, tkSet, tkWChar:begin
      result:=result+'OrdType:'+GetEnumName(typeinfo(TOrdType),ord(td.OrdType))+' ';
      case ti.Kind of
        tkInteger, tkChar, tkEnumeration, tkWChar: begin
          result:=result+'min:'+inttostr(td.MinValue)+' max:'+inttostr(td.MaxValue)+' ';
          case ti.Kind of
            tkEnumeration: begin
              result:=result+'NameList:'+td.NameList+' ';
            end;
          end;
        end;
        tkSet: begin
        end;
      end;
    end;
    tkFloat: result:=result+'FloatType:'+GetEnumName(TypeInfo(TFloatType),ord(td.FloatType))+' ';
    tkString: result:=result+'MaxLength:'+inttostr(td.MaxLength);
    tkClass: begin
      result:=result+'ClassName:'+td.ClassType.ClassName;
    end;
    tkMethod: begin
      result:=result+'MethodKind:'+GetEnumName(TypeInfo(TMethodKind),ord(td.MethodKind))+' ';
      result:=result+'ParamCount:'+inttostr(td.ParamCount)+' ';
//      result:=result+'Paramlist:'+td.ParamList+' ';
    end;
    tkInt64:begin
      result:=result+'min:'+inttostr(td.MinInt64Value)+' max:'+inttostr(td.MaxInt64Value)+' ';
    end;
  end;
  result:=result+')';
end;

function TypeSize(const ti:PTypeInfo):integer;
//TOrdType = (otSByte, otUByte, otSWord, otUWord, otSLong, otULong);
const OrdSize:array[TOrdType]of integer=(1,1,2,2,4,4);
//TFloatType = (ftSingle, ftDouble, ftExtended, ftComp, ftCurr);
const FloatSize:array[TFloatType]of integer=(4,8,10,8,8);
begin
  case ti.Kind of
    tkInteger, tkChar, tkEnumeration, tkSet, tkWChar:result:=OrdSize[gettypedata(ti).OrdType];
    tkFloat:result:=FloatSize[gettypedata(ti).FloatType];
    tkString:result:=GetTypeData(ti).MaxLength+1;
    tkInt64:result:=8;
    else result:=0;
  end;
end;

{ THetTypeRec }

procedure THetTypeRec.ImportRttiProperty(const AProp:TRttiProperty);

  procedure Error(s:string);
  begin raise Exception.Create('THetTypeRec.ImportPropInfo('+AProp.Parent.QualifiedName+'.'+AProp.Name+') '+s);end;

  procedure ImportEnumNames(const n:shortstring;const max:integer);
  var act:PShortString;
      i:integer;
  begin
    act:=@n;
    SetLength(EnumNames,max+1);
    for i:=0 to high(EnumNames)do begin
      EnumNames[i]:=act^;
      pinc(act,length(act^)+1);
    end;
  end;

var pi:PPropInfo;
    t:PTypeInfo;
    d:PTypeData;
    sp:cardinal;
begin
  fillchar(self,sizeof(self),0);

  if AProp is TRttiInstanceProperty then begin
    pi:=TRttiInstanceProperty(AProp).PropInfo;

    //storedness
    if AProp.Visibility=mvPublished then begin
      sp:=cardinal(pi.StoredProc);
      if sp=1 then  Flags:=Flags+[flStored,flAlwaysStored]else
      if sp<>0 then Flags:=Flags+[flStored];
    end;

    //is field?
    if cardinal(pi.GetProc)shr 24=$ff then
      Flags:=Flags+[flField]
  end;

  t:=AProp.PropertyType.Handle;
  d:=GetTypeData(t);

  //writeonly?  naneeee
  if not AProp.IsReadable then
    Error('Writeonly props not supported');

  //readonly?
  if not AProp.IsWritable then
    Flags:=Flags+[flReadOnly];

  //acquire hetType
  if SameText(t.Name,'TId')then Typ:=htId else
  if SameText(t.Name,'TName')then Typ:=htName else
  if SameText(t.Name,'TDate')then Typ:=htDate else
  if SameText(t.Name,'TTime')then Typ:=htTime else
  if SameText(t.Name,'TDateTime')then Typ:=htDateTime else
  case t.Kind of
    tkInteger:case d.OrdType of
      otSByte:Typ:=htShortInt;
      otUByte:Typ:=htByte;
      otSWord:Typ:=htSmallInt;
      otUWord:Typ:=htWord;
      otSLong:Typ:=htInteger;
      otULong:Typ:=htCardinal;
    end;
    tkInt64:Typ:=htInt64;
    tkEnumeration:if d.MaxValue<0 then begin
      Typ:=htBoolean;  //seems like deprecated
      if TypeSize(t)<>1 then
        Error('boolean size <> 1 byte');
    end else begin
      if(d.MaxValue=1)and SameStr('Boolean',t.Name)then
        Typ:=htBoolean
      else begin
        Typ:=htEnum;
        ImportEnumNames(d.NameList,d.MaxValue);
      end;
    end;
    tkSet:begin
      Typ:=htSet;
      with GetTypeData(d.CompType^)^do ImportEnumNames(NameList,MaxValue);
    end;
    tkFloat:begin
      case d.FloatType of
        ftSingle:Typ:=htSingle;
        ftDouble:Typ:=htDouble;
        ftExtended:Typ:=htExtended;
      else
        Error('Unsupported floatType:'+GetEnumName(TypeInfo(TFloatType),ord(d.FloatType)))
      end;
    end;
    tkLString:Typ:=htAnsiString;
    tkUString:Typ:=htUnicodeString;
    tkClass:begin
      ObjClass:=d.ClassType;
      if[flReadOnly,flField]<=Flags then
        Typ:=htSubObj
      else begin
        with HetClassInfo(ObjClass)do
          if IdProp<>nil then Typ:=htObjId else
          if NameProp<>nil then Typ:=htObjName else
            Typ:=htObjIdx;
      end;
    end;
  else
    Error('Unsupported typeKind:'+GetEnumName(TypeInfo(TTypeKind),ord(t.Kind)));
  end;

  _RecalculateFlags;
end;

procedure THetTypeRec._RecalculateFlags;
begin
  RawSize:=HetTypeDetails[Typ].RawSize;
  if RawSize=0 then case Typ of
    htEnum:RawSize:=Length(EnumNames)shr 8+1;
    htSet:RawSize:=(Length(EnumNames)+7)shr 3;
  end;

  BaseTyp:=HetTypeDetails[Typ].Base;
end;

procedure THetFieldDef.IO(st:TObject);
var s:ansistring;
begin
  with TIO(st)do begin
    io(byte(Typ.Typ));
    io(Name);
    //extra info
    case Typ.Typ of
      htEnum,htSet:io(Typ.EnumNames);//typename nem kell (asszem)
      htObjId,htObjName,htObjIdx,htSubObj:begin
        if IOWriting then begin
          if Typ.ObjClass<>nil then s:=Typ.ObjClass.ClassName
                               else s:='';//elvileg nem lehet nil
          io(s);
        end else begin
          IO(s);
          Typ.ObjClass:=ClassByName(s);
        end;
      end;
    end;

    if IOReading then begin
      Typ._RecalculateFlags;
    end;
  end;
end;


initialization
//  raise Exception.Create(ToStr(SizeOf(THetTypeRec)));12
  RttiContext:=TRttiContext.Create;
  RttiTypes:=RttiContext.GetTypes;
finalization
  RttiContext.Free;
end.