unit het.DB;

interface

uses
  Windows, SysUtils, math, IOUtils, het.Utils, het.Arrays, het.Objects, het.Parser,
  het.Variants, typinfo, DB, AdoDB, classes, forms,
  ansistrings;

var
  sqlCnt:integer;

type
  TDataBase=class;
  TDataObject=class;

  TDataObject=class(THetObject)
  private
  public
    Function ScriptInsertBlank:ansistring;
    Function ScriptInsertFull(IdentityInsertState:boolean):ansistring;
    Function ScriptUpdate:ansistring;
    Function ScriptDelete:ansistring;

    function DataTable:THetObjectList;
    function DataBase:TDataBase;

    procedure NotifyCreate;override;
    procedure NotifyChange;override;
    procedure NotifyDestroy;override;

    function getLookupList(const PropInfo:PPropInfo):THetObjectList;override;
  end;

  TDataTable<T:TDataObject>=class(THetList<T>)//FUTURE
  public
    constructor Create(const AOwner:THetObject);override;
  end;

  TDataBase=class(THetObject)
  private
    FConnection:TADOConnection;
    FIgnoreChanges:boolean;
    FModifiedDataObject:TDataObject;

    FTables:array of THetObjectList;
    function GetTableCount:integer;
    function GetTable(const idx:integer):THetObjectList;
  public
    constructor Create(const AOwner:THetObject);override;
    destructor Destroy;override;
    procedure Connect(const AConnectionString,AUser,APassword:AnsiString);
    procedure Disconnect;
    function Connected:boolean;

    procedure FlushModifications;

    property TableCount:integer read GetTableCount;
    property Table[const idx:integer]:THetObjectList read GetTable;

    function ScriptDropAllTables: ansistring;
    function ScriptCreateTable(const ADataClass:TClass):ansistring;
    function ScriptCreateAllTables: ansistring;
    function ScriptInsertTableRows(const AList:THetObjectList):ansistring;
    function ScriptInsertAllTableRows: ansistring;
    function ScriptEverything: ansistring;
    function ScriptSelect(const ADataClass:TClass;const where:ansistring=''): ansistring;
    procedure LoadTable_Ado(const AList:THetObjectList);
    procedure LoadAllTables_ADO;

    procedure DataObjectChanged(const AObj:THetObject;const AChangeType:TChangeType);virtual;

    property IgnoreChanges:boolean read FIgnoreChanges write FIgnoreChanges;

    class function Script_TxtDb_Pas(const APath:string;const ADbName:ansistring;const ACompact:boolean=true):ansistring;
    procedure LoadTable_Txt(const AList:THetObjectList;const AFileName:string);
    procedure LoadAllTables_Txt(const APath:string);

    function TableNames:ansistring;
    function TableByName(const AName:ansistring):THetObjectList;
    function TableByClass(const AClass:TClass):THetObjectList;
  end;

implementation

uses
  het.FileSys;

type
  TNameValueRec=record name,value:ansistring end;
  TNameValueArray=THetArray<TNameValueRec>;

function EncodeMSSQLDate(const dt:TDate):ansistring;
var y,m,d:word;
begin
  if dt<=1 then exit('NULL');
  DecodeDate(dt,y,m,d);
  result:=format('''%.4d%.2d%.2d''',[y,m,d]);
end;

function EncodeMSSQLTime(const dt:TTime):ansistring;
var h,n,s,ms:word;
begin
  if dt<=0 then exit('NULL');
  DecodeTime(dt,h,n,s,ms);
  result:=format('''%.2d:%.2d:%.2d''',[h,n,s]);
end;

function EncodeMSSQLDateTime(const dt:TTime):ansistring;
var y,m,d,h,n,s,ms:word;
begin
  if dt<=0 then exit('NULL');
  DecodeDate(dt,y,m,d);
  DecodeTime(dt,h,n,s,ms);
  result:=format('''%.4d%.2d%.2d %.2d:%.2d:%.2d''',[y,m,d,h,n,s]);
end;

procedure _ScriptSQLNameValuePairs(var res:TNameValueArray;const AObj:THetObject;const AClass:TClass;const IncludeIdentity:boolean;const SubObjSeparator:ansichar);

  function GetStr(o:THetObject;pi:PPropInfo):ansistring;
  begin
    if o<>nil then begin//instance data
      if pi.PropType^.Name='TDate' then exit(EncodeMSSQLDate(GetOrdProp(o,pi)));
      if pi.PropType^.Name='TTime' then exit(EncodeMSSQLTime(GetFloatProp(o,pi)));
      if pi.PropType^.Name='TDateTime' then exit(EncodeMSSQLDateTime(GetFloatProp(o,pi)));
      case pi.PropType^.Kind of
        tkInteger,tkEnumeration{bit}:Exit(toStr(GetOrdProp(o,pi)));
        tkString,tkLString,tkUString,tkWString:Exit(het.Utils.ToSql(GetStrProp(o,pi)));
        tkFloat:exit(floattostr(GetFloatProp(o,pi)));
      end;
      raise Exception.Create('TDataObject._ScriptValueNamePairs() Ismeretlen SQL tipus '+pi.Name+':'+pi.PropType^.Name);
    end else begin//type
      if pi.PropType^.Name='TDate' then exit('DATETIME NULL');
      if pi.PropType^.Name='TTime' then exit('DATETIME NULL');
      if pi.PropType^.Name='TDateTime' then exit('DATETIME NULL');
      case pi.PropType^.Kind of
        tkInteger:exit('INT DEFAULT 0');
        tkString,tkLString,tkUString,tkWString:exit('VARCHAR(250) DEFAULT ''''');
        tkEnumeration:exit('BIT NOT NULL DEFAULT 0');
        tkFloat:exit('FLOAT NOT NULL DEFAULT 0');
      end;
      raise Exception.Create('Ismeretlen SQL tipus '+pi.Name+':'+pi.PropType^.Name);
    end;
  end;

  procedure ScriptFields(const APrefix:ansistring;const AObj:THetObject;AClass:TClass);
  var CD:TClassDescription;
      i:integer;
      actProp:PPropInfo;
      link:THetObject;
      tmp:TNameValueRec;
      isId:boolean;
  begin
    if AObj<>nil then
      AClass:=AObj.ClassType;

    CD:=ClassDescriptionOf(AClass);
    for i:=0 to high(CD.Storeds)do begin
      actProp:=CD.Storeds[i];
      if(actProp.PropType^.Kind=tkClass)then begin
        if(actProp.SetProc=nil)then begin//SubObject
          if AObj<>nil then ScriptFields(actProp.Name+SubObjSeparator,THetObject(GetOrdProp(AObj,actProp)),nil)
                       else ScriptFields(actProp.Name+SubObjSeparator,nil,GetTypeData(actProp.PropType^).ClassType);
        end else begin//LinkObject
          tmp.name:='['+APrefix+actProp.Name+SubObjSeparator+'ID]';
          if AObj<>nil then begin
            link:=THetObject(GetOrdProp(AObj,actProp));
            if link=nil then tmp.value:='NULL'
                        else tmp.value:=toStr(Link.getId);
          end else begin
            tmp.value:='INT NULL FOREIGN KEY REFERENCES ['+copy(actProp.PropType^.Name,2)+']([ID])';
          end;
          res.Append(tmp);
        end;
      end else begin//simple field
        isID:=(actProp=CD.IdProp);
        if isId and(APrefix<>'') then continue;//subobjoknak nincs idjuk
        if isId and not IncludeIdentity then Continue;

        tmp.name:='['+APrefix+actProp.Name+']';
        if isID and(AObj=nil)then tmp.value:='INT NOT NULL IDENTITY(1,1) PRIMARY KEY'
                             else tmp.value:=GetStr(AObj,actProp);

        res.Append(tmp);
      end;
    end;
  end;

begin
  res.Clear;
  ScriptFields('',AObj,AClass);
end;


{ TDataObject }

function TDataObject.DataTable: THetObjectList;
begin
  result:=THetObjectList(FOwner);
end;

function TDataObject.DataBase: TDataBase;
var o:THetObject;
begin
  o:=FOwner.FOwner;
  while o<>nil do begin
    if o is TDataBase then exit(TDataBase(o));
    o:=o.FOwner;
  end;
  result:=nil;
end;

function TDataObject.ScriptInsertBlank: ansistring;
begin with AnsiStringBuilder(Result,true)do begin
  if ClassDesc.IdProp=nil then exit;

  AddStr('INSERT INTO ['+Copy(ClassName,2)+'] default values');
  if ClassDesc.IdProp<>nil then AddStr(' select max(ID)from ['+Copy(ClassName,2)+']');
  AddStr(#13#10);
end;end;

function TDataObject.ScriptInsertFull(IdentityInsertState:boolean):ansistring;
var nv:TNameValueArray;
    i:integer;
begin with AnsiStringBuilder(Result,true)do begin
  if not IdentityInsertState then
    AddStr('SET IDENTITY_INSERT ['+Copy(classname,2)+'] ON'#13#10);
  _ScriptSQLNameValuePairs(nv,self,nil,true,'_');
  AddStr('INSERT INTO ['+Copy(ClassName,2)+'] (');
  for i:=0 to nv.Count-1 do begin
    if i>0 then AddChar(',');
    AddStr(nv.FItems[i].name);
  end;
  AddStr(')VALUES(');
  for i:=0 to nv.Count-1 do begin
    if i>0 then AddChar(',');
    AddStr(nv.FItems[i].value);
  end;
  AddStr(')'#13#10);
  if not IdentityInsertState then
    AddStr('SET IDENTITY_INSERT ['+Copy(classname,2)+'] OFF'#13#10);
end;end;

procedure TDataObject.NotifyCreate;
begin
  inherited;
  DataBase.DataObjectChanged(self,ctCreate);
end;

procedure TDataObject.NotifyChange;
begin
  inherited;
  DataBase.DataObjectChanged(self,ctChange);
end;

procedure TDataObject.NotifyDestroy;
begin
  inherited;
  DataBase.DataObjectChanged(self,ctDestroy);
end;

function TDataObject.ScriptDelete: ansistring;
begin
  if ClassDesc.IdProp<>nil then
    result:='DELETE FROM ['+Copy(ClassName,2)+'] WHERE ID='+toStr(getId)+#13#10
  else
    result:='';
end;

function TDataObject.ScriptUpdate: ansistring;
var nv:TNameValueArray;
    i:integer;
begin with AnsiStringBuilder(Result,true)do begin
  if ClassDesc.IdProp=nil then exit('');

  _ScriptSQLNameValuePairs(nv,Self,nil,False,'_');
  AddStr('UPDATE ['+Copy(ClassName,2)+'] SET ');
  for i:=0 to nv.Count-1 do begin
    if i>0 then AddChar(',');
    AddStr(nv.FItems[i].name+'='+nv.FItems[i].value);
  end;
  AddStr(' WHERE ID='+toStr(getId)+#13#10);
end;end;

function TDataObject.getLookupList(const PropInfo: PPropInfo): THetObjectList;
begin
  result:=DataBase.TableByClass(GetTypeData(PropInfo.PropType^).ClassType);
end;

{ TDataTable<T> }

constructor TDataTable<T>.Create(const AOwner: THetObject);
begin
  inherited;
//  ViewDefinition:='Id'; {tilos, mert ilyenkor nincs qsort a betolteskor}
end;

{ TDataBase }

constructor TDataBase.Create(const AOwner: THetObject);
var i:integer;
begin
  inherited;

  setlength(FTables,0);
  with ClassDesc do for i:=0 to high(SubObjects)do
    if ClassIs(GetTypeData(SubObjects[i].PropType^).ClassType,THetObjectList) then begin
      setlength(FTables,length(FTables)+1);
      FTables[high(FTables)]:=THetObjectList(GetOrdProp(self,SubObjects[i]));
    end;
end;

destructor TDataBase.Destroy;
begin
  Disconnect;
  inherited;
end;

procedure TDataBase.Connect(const AConnectionString,AUser, APassword: AnsiString);
begin
  Disconnect;
  FConnection:=TADOConnection.Create(nil);
  FConnection.ConnectionString:=AConnectionString;
  try
    FConnection.Open(AUser,APassword);
  except
    FreeAndNil(FConnection);raise
  end;
end;

procedure TDataBase.Disconnect;
begin
  FlushModifications;
  FreeAndNil(FConnection);
end;

function TDataBase.GetTableCount: integer;
begin
  result:=Length(FTables)
end;

function TDataBase.GetTable(const idx: integer): THetObjectList;
begin
  if InRange(idx,0,high(FTables))then result:=FTables[idx] else result:=nil;
end;

function TDataBase.Connected: boolean;
begin
  result:=(FConnection<>nil)and(FConnection.Connected);
end;

function TDataBase.ScriptDropAllTables:ansistring;
var i:integer;
begin with AnsiStringBuilder(result,true)do begin
  for i:=TableCount-1 downto 0 do
    AddStr('DROP TABLE ['+copy(Table[i].BaseClass.ClassName,2)+']'#13#10);
  AddStr('GO'#13#10);
end;end;

function TDataBase.ScriptCreateTable(const ADataClass: TClass): ansistring;
var nv:TNameValueArray;
    i:integer;
begin with AnsiStringBuilder(Result,true)do begin
  AddStr('CREATE TABLE ['+Copy(ADataClass.ClassName,2)+'] ('#13#10);
  _ScriptSQLNameValuePairs(nv,nil,ADataClass,true,'_');
  for i:=0 to nv.Count-1 do begin
    AddStr('  '+nv.FItems[i].Name+' '+nv.FItems[i].value);
    if i<nv.Count-1 then AddStr(','#13#10);
  end;
  AddStr(')'#13#10'GO'#13#10);
end;end;

function TDataBase.ScriptCreateAllTables:ansistring;
var i:integer;
begin with AnsiStringBuilder(result,true)do begin
  for i:=0 to TableCount-1 do
    AddStr(ScriptCreateTable(Table[i].BaseClass));
end;end;

function TDataBase.ScriptInsertTableRows(const AList:THetObjectList):ansistring;
var i:integer;
begin with AnsiStringBuilder(result,true)do begin
  AddStr('SET IDENTITY_INSERT ['+Copy(AList.BaseClass.classname,2)+'] ON'#13#10'GO'#13#10);
  for i:=0 to AList.Count-1 do with TDataObject(AList.ByIndex[i])do begin
    AddStr(ScriptInsertFull(true));
  end;
  AddStr('SET IDENTITY_INSERT ['+Copy(AList.BaseClass.classname,2)+'] OFF'#13#10);
end;end;

function TDataBase.ScriptInsertAllTableRows:ansistring;
var i:integer;
begin with AnsiStringBuilder(result,true)do begin
  for i:=0 to TableCount-1 do
    AddStr(ScriptInsertTableRows(Table[i]));
end;end;

function TDataBase.ScriptEverything: ansistring;
begin
  result:='-- *** Automatic script generated by het.Objects - Do not delete/modify fields ***'#13#10+
    ScriptDropAllTables+
    ScriptCreateAllTables+
    ScriptInsertAllTableRows;
end;

function TDataBase.ScriptSelect(const ADataClass:TClass;const where:ansistring=''):ansistring;
var nv:TNameValueArray;
    i:integer;
begin with AnsiStringBuilder(result,true)do begin
  AddStr('SELECT ');
  _ScriptSQLNameValuePairs(nv,nil,ADataClass,true,'_');
  for i:=0 to nv.Count-1 do begin
    if i>0 then AddChar(',');
    AddStr(nv.FItems[i].name);
  end;
  AddStr(' FROM ['+copy(ADataClass.ClassName,2)+']');
  if where<>'' then
    AddStr(' WHERE '+where);
  AddStr(#13#10);
end;end;

procedure TDataBase.LoadTable_Ado(const AList:THetObjectList);
var ds:TADOQuery;
    f:TField;
    nv:TNameValueArray;
    lookups:array of THetObjectList;
    firstRow:boolean;
    i,j,id,idIndex:integer;
    baseClass:THetObjectClass;
    actObj:THetObject;

    ns:TNameSpace;
    ctx:TContext;
    nodes:array of TNodeBase;
begin
  FIgnoreChanges:=true;
  ds:=TADOQuery.Create(nil);
  ns:=nil;ctx:=nil;
  try
    with ds do begin
      Connection := FConnection;
      CursorLocation :=  clUseClient;
      CursorType := ctOpenForwardOnly;
      LockType := ltReadOnly;
      SQL.Text := scriptSelect(AList.BaseClass);
      Open;
      First;

      baseClass:=AList.BaseClass;
      firstRow:=true;idIndex:=-1;
      while not Eof do begin
        actObj:=baseClass.Create(AList);

        if checkAndClear(firstRow) then begin
          _ScriptSQLNameValuePairs(nv,nil,BaseClass,true,'.');
          setlength(Lookups,nv.Count);
          for i:=0 to high(lookups)do begin
            lookups[i]:=nil;
            replace('[','',nv.FItems[i].name,[roAll]);
            replace(']','',nv.FItems[i].name,[roAll]);
            if cmp(nv.FItems[i].name,'ID')=0 then idIndex:=i; //!!!!!!!!!!!!!!! ták
          end;
          //find lookups
          with actObj.ClassDesc do for i:=0 to high(LinkedObjects)do begin
            for j:=0 to high(lookups)do if cmp(nv.FItems[j].name,LinkedObjects[i].Name+'.ID')=0 then begin
              lookups[j]:=actObj.getLookupList(LinkedObjects[i]);
              nv.FItems[j].name:=ListItem(nv.FItems[j].name,0,'.');//!!!!!!!!! SubObject nem linkelhet!!!!!!!!!!
              break
            end;
          end;
          //create nodes
          ns:=TNameSpace.Create('ADOfetch');
          ctx:=TContext.Create(nil,ns,nil,actObj);
          setlength(nodes,nv.Count);
          for i:=0 to high(nodes)do nodes[i]:=CompilePascalStatement(nv.FItems[i].name,ns);
        end;

        i:=0;ctx.WithStack.FItems[0]:=actObj;
        for f in Fields do begin
          if lookups[i]<>nil then begin
            id:=f.AsInteger;
            if id>0 then nodes[i].Let(ctx,VObject(lookups[i].ById[id]))
                    else nodes[i].Let(ctx,VObject(nil))
          end else begin
            if i=idIndex then actObj.SetID(f.AsInteger)    //!!!!!!!!!!!!!!! gány, mert tobbfele index lehet
                         else nodes[i].Let(ctx,f.AsVariant);
          end;
          inc(i);if i>high(nodes)then break;
        end;

        Next;
      end;
    end;
  finally
    for i:=0 to high(nodes)do nodes[i].Free;
    ctx.Free;
    ns.Free;

    ds.Free;
    FIgnoreChanges:=false;
  end;
end;

procedure TDataBase.LoadAllTables_ADO;
var i:integer;
begin
  for i:=0 to TableCount-1 do
    LoadTable_Ado(Table[i]);
end;

function Exec(const AConnection:TADOConnection;const q:ansistring;const returnId:boolean=false):integer;
var FQuery:TADOQuery;
begin
  result:=0;
  if q='' then exit;
  FQuery:=TADOQuery.Create(nil);
  beep;
  try
    FQuery.Connection:=AConnection;
    FQuery.SQL.Text:=q;
    if returnId then begin
      FQuery.Open;
      result:=FQuery.Fields[0].AsInteger
    end else
      FQuery.ExecSQL;
    inc(sqlCnt);
  finally
    FQuery.Free;
  end;
end;

procedure TDataBase.FlushModifications;
begin
  if not Connected then exit;
  if FModifiedDataObject=nil then exit;
  Exec(FConnection,FModifiedDataObject.ScriptUpdate);
end;

procedure TDataBase.DataObjectChanged(const AObj: THetObject; const AChangeType: TChangeType);
begin
  inherited;
  if(AChangeType=ctDestroy)and(AObj=FModifiedDataObject)then FModifiedDataObject:=nil;

  if FIgnoreChanges or not Connected or not(AObj is TDataObject) then exit;

  if FModifiedDataObject<>AObj then
    FlushModifications;

  case AChangeType of
    ctCreate:begin
      FIgnoreChanges:=true;
      try
        AObj.setId(Exec(FConnection,TDataObject(AObj).ScriptInsertBlank,true));
        FModifiedDataObject:=TDataObject(AObj);
      finally
        FIgnoreChanges:=false
      end
    end;
    ctChange:begin
      //Exec(TDataObject(AObj).ScriptUpdate);//realtime changes
      FModifiedDataObject:=TDataObject(AObj);//lazy update
    end;
    ctDestroy:Exec(FConnection,TDataObject(AObj).ScriptDelete);
  end;
end;


////////////////////////////////////////////////////////////////////////////////
///  TabText                                                                 ///
////////////////////////////////////////////////////////////////////////////////

const
  TablePrefix=''; //na ehhez NEM NYULNI!!!!!

type
  TTxtFieldInfo=record
    FieldName:ansistring;
    FieldType:(ftInt,ftDouble,ftBool,ftString,ftDateTime,ftReference);
    FieldTypeStr:ansistring;
    IsPrimaryKey,
    IsForeignKey:boolean;
  end;

function TxtFieldInfo(const fielddef:ansistring;const TableNames:ansistring{foreign keyekhez}):TTxtFieldInfo;

  function FindTable(AName:ansistring):boolean;
  begin
    result:=ListFind(TableNames,AName,',')>=0;
  end;

var i:integer;
begin with result do begin
  IsPrimaryKey:=false;
  IsForeignKey:=false;
  FieldName:=WordAt(fielddef,1,false);
  case charn(fielddef,length(fielddef)) of
    '%':begin
      FieldType:=ftInt;
      FieldTypeStr:='integer';
      if cmp(FieldName,'az')=0 then begin//primary key?
        FieldName:='Id';
        IsPrimaryKey:=true;
      end else if EndsWith(FieldName,'az')then//secondary key?
        for i:=length(FieldName)-2 downto 2 do
          if FindTable(copy(FieldName,1,i)) then begin
            IsForeignKey:=true;
            FieldType:=ftReference;
            FieldTypeStr:='T'+copy(FieldName,1,i);
            FieldName:=copy(FieldName,1,length(FieldName)-2);
            break;
          end;
    end;
    '?':begin FieldType:=ftBool;FieldTypeStr:='boolean';end;
    '!':begin FieldType:=ftDouble;FieldTypeStr:='double';end;
    '@':begin FieldType:=ftDateTime;FieldTypeStr:='TDateTime';end;
  else FieldType:=ftString;FieldTypeStr:='ansistring';end;
end;end;

class function TDataBase.Script_TxtDb_Pas(const APath:string;const ADbName:ansistring;const ACompact:boolean=true):ansistring;
  procedure Error(e:string);begin raise Exception.Create('Script_TxtDb_Pas() '+e);end;

  const
    rowSepar=#10;
    colSepar=#9;

  var
    Tables:array of record
      name:ansistring;
      header:ansistring;
      foreignkeys:array of integer;
      saved:boolean;
    end;
    TableNames:ansistring;

  function FindTable(n:ansistring):integer;
  var i:integer;
  begin
    for i:=0 to high(Tables)do if cmp(tables[i].name,n)=0 then exit(i);
    result:=-1;
  end;

  var Decl,Impl,Registrations:ansistring;
      DBFields,DBProps:ansistring;

  procedure ScriptTable(const AName,AHead:string);

  var Fields,SetterDecl,Props,SetterImpl:AnsiString;

  var TableName,EntityName:ansistring;
      col:ansistring;
  begin
    EntityName:=AName;
    TableName:=TablePrefix+EntityName;

    for col in ListSplit(AHead,colSepar)do with TxtFieldInfo(col,TableNames)do begin
      if ACompact then begin
        Fields:=Fields+format('    private F%s:%s;',[FieldName,FieldTypeStr]);
        if cmp(FieldName,'Id')<>0 then begin
          Fields:=Fields+format(' procedure Set%s(const Value:%s);',[FieldName,FieldTypeStr]);
          Fields:=Fields+format(' published property %s:%s read F%s write Set%s;',[FieldName,FieldTypeStr,FieldName,FieldName]);
          SetterImpl:=SetterImpl+format('{$O-}procedure T%s.Set%s;begin end;{$O+}'#13#10,[EntityName,FieldName]);
        end else begin
          Fields:=Fields+format(' published property %s:%s read F%s;',[FieldName,FieldTypeStr,FieldName]);
        end;
        Fields:=Fields+#13#10;
      end else begin //not ACompact
        Fields:=Fields+format('    F%s:%s;'#13#10,[FieldName,FieldTypeStr]);
        if cmp(FieldName,'Id')<>0 then begin
          Props:=Props+format('    property %s:%s read F%s write Set%s;'#13#10,[FieldName,FieldTypeStr,FieldName,FieldName]);
          SetterDecl:=SetterDecl+format('    procedure Set%s(const Value:%s);'#13#10,[FieldName,FieldTypeStr]);
          SetterImpl:=SetterImpl+format('{$O-}procedure T%s.Set%s;begin end;{$O+}'#13#10,[EntityName,FieldName]);
        end else begin
          Props:=Props+format('    property %s:%s read F%s;'#13#10,[FieldName,FieldTypeStr,FieldName]);
        end;
      end;
    end;

    Decl:=Decl+format('  T%s=class(TDataObject)'#13#10,[EntityName])+
                      switch(ACompact,'','  private'#13#10)+
                           Fields+SetterDecl+
                      switch(ACompact,'','  published'#13#10)+
                           Props+
                      '  end;'#13#10+
               format('  T%s=class(TGenericHetObjectList<T%s>)end;'#13#10#13#10,[TableName,EntityName]);

    ListAppend(Registrations,'T'+EntityName,',');
    ListAppend(Registrations,'T'+TableName,',');

    Impl:=Impl+'{ T'+EntityName+' }'#13#10#13#10+
                SetterImpl+
                #13#10;

    if ACompact then begin
      DBFields:=DBFields+'    private F'+TableName+':T'+TableName+';'+
                         'published property '+TableName+':T'+TableName+' read F'+TableName+';'#13#10;
    end else begin
      DBFields:=DBFields+'  F'+TableName+':T'+TableName+';'+#13#10;
      DBProps:=DBProps+'  property '+TableName+':T'+TableName+' read F'+TableName+';'#13#10;
    end;
  end;

  function PickOne:integer;//picks one table in dependecy order
  var foreignSaved:boolean;
      i,j:integer;
  begin
    for i:=0 to high(Tables)do with Tables[i]do if not saved then begin
      foreignSaved:=true;
      for j:=0 to high(foreignkeys)do if not Tables[foreignkeys[j]].saved then
        foreignSaved:=false;

      if foreignSaved then begin
        saved:=true;
        Exit(i);
      end;
    end;

    raise Exception.Create('Unable to pick table (circular reference?)');
  end;

var fn:string;
    i,j:integer;
    s,dbName:ansistring;

begin
  dbName:='db'+ADbName;

  //explore tables in path, build TableNames list
  for fn in TDirectory.GetFiles(APath)do begin
    if cmp(ExtractFileExt(fn),'.txt')=0 then begin
      SetLength(Tables,length(Tables)+1);
      with Tables[high(Tables)]do begin
        Name:=ChangeFileExt(ExtractFileName(fn),'');
        ListAppend(TableNames,Name,',');
        header:=ListItem(TFile(fn),0,rowSepar);
        saved:=false;
      end;
    end;
  end;

  //find foreign keys
  for i:=0 to high(Tables)do
    for j:=0 to high(Tables)do with tables[j]do
      for s in ListSplit(header,colSepar)do
        if BeginsWith(s,Tables[i].name)and EndsWith(s,'az%')then begin
          setlength(foreignkeys,length(foreignkeys)+1);
          foreignkeys[high(foreignkeys)]:=i;
        end;

  //script tables
  for i:=0 to high(Tables)do with Tables[PickOne]do
    ScriptTable(name,header);

  //database
  Decl:=Decl+'  T'+dbName+'=class(TDataBase)'#13#10;
  if ACompact then begin
    Decl:=Decl+DBFields;
  end else begin
    Decl:=Decl+'  private'#13#10+
                    DBFields+
               '  published'#13#10+
                    DBProps;
  end;
  decl:=decl+'  end;'#13#10#13#10;

  //register
  ListAppend(Registrations,'T'+dbName,',');
  Impl:=Impl+'  RegisterHetClass(['+Registrations+']);'+#13#10;

  result:=Decl+#13#10+Impl;
end;

function TDataBase.TableNames:ansistring;
var t:THetObjectList;
begin
  result:='';
  for t in FTables do ListAppend(result,copy(t.BaseClass.ClassName,2),',');
end;

function TDataBase.TableByName(const AName:ansistring):THetObjectList;
var t:THetObjectList;
begin
  for t in FTables do if Cmp(copy(t.BaseClass.ClassName,2),AName)=0 then exit(t);
  result:=nil;
end;

function TDataBase.TableByClass(const AClass:TClass):THetObjectList;
var t:THetObjectList;
begin
  for t in FTables do if AClass=t.BaseClass then exit(t);
  result:=nil;
end;

procedure TDataBase.LoadTable_Txt(const AList:THetObjectList;const AFileName:string);
  procedure error(s:string);begin raise Exception.Create('TDataBase.LoadTable_Txt('+topas(AFileName)+') '+s)end;

  function ToDateTime(s:ansistring):TDateTime;
  begin
    if(s='')or(cmp(s,'null')=0)then exit(0);

    if ListCount(s,' ')=2 then
      result:=MyStrToDate(ListItem(s,0,' '))+MyStrToTime(ListItem(s,1,' '))
    else
      result:=0;

    if Result=0 then
      raise Exception.Create('Unknown date format: '+topas(s));
  end;

var BaseClass:THetObjectClass;
    Rows:TArray<ansistring>;
    FieldDef:AnsiString;
    TableNames:ansistring;
    mappings:array of record
      ColIdx:integer;
      PropInfo:PPropInfo;
      FieldInfo:TTxtFieldInfo;
      ReferencedTable:THetObjectList;
      isId:boolean;
    end;
    i,id,j:integer;
    fi:TTxtFieldInfo;
    pi:PPropInfo;
    actRow:TArray<ansistring>;
    actCell:ansistring;
    obj:THetObject;

begin
  if not fileexists(AFileName)then error('File not found');
  Rows:=ListSplit(TFile(AFileName),#10);
  if length(Rows)=0 then raise Exception.Create('No header');

  TableNames:=self.TableNames;
  BaseClass:=AList.BaseClass;

  //explore columns  {ide hibakezeles hegyek kellenek majd!!!!}
  i:=0;for FieldDef in listsplit(Rows[0],#9)do begin
    fi:=TxtFieldInfo(FieldDef,TableNames);
    pi:=GetPropInfo(BaseClass,fi.FieldName);
    if pi<>nil then begin
      setlength(mappings,length(mappings)+1);
      with mappings[high(mappings)]do begin
        ColIdx:=i;
        PropInfo:=pi;
        FieldInfo:=fi;
        isId:=cmp(fi.FieldName,'id')=0;
        if isId and(fi.FieldType<>ftInt)then
          error('Id field type must be integer');
        if fi.FieldType=ftReference then begin
          ReferencedTable:=Self.TableByName(copy(fi.FieldTypeStr,2));
          if ReferencedTable=nil then
            error('ReferencedTable does not exists: '+topas(copy(fi.FieldTypeStr,2)));
        end;
      end;
    end;
    inc(i);
  end;

  if length(mappings)=0 then
    error('no matching columns to load');

  i:=0;j:=0;//nowarn
  try
{$WARNINGS OFF}
    for i:=0 to high(Rows)-1 do begin {$WARNINGS OFF}
      if(i and $1fff)=0 then Application.MainForm.Caption:=format('%s %d/%d',[AList.ClassName,i,high(Rows)]);

      actRow:=ListSplit(Rows[i+1],#9);
      obj:=BaseClass.Create(AList);
      for j:=0 to high(mappings)do with mappings[j]do begin
        if ColIdx>high(actRow)then actCell:=''
                              else actCell:=actRow[ColIdx];
        if isId then begin
          obj.setId(strtoint(actCell));
        end else case FieldInfo.FieldType of
          ftInt:SetOrdProp(obj,PropInfo,strtointdef(actCell,0));
          ftDouble:SetFloatProp(obj,PropInfo,StrToFloatDef(actCell,0));
          ftBool:SetOrdProp(obj,PropInfo,switch(CharN(actCell,1)in['Y','y','T','t','1','I','i'],1,0));
          ftString:SetAnsiStrProp(obj,PropInfo,actCell);
          ftDateTime:SetFloatProp(obj,PropInfo,ToDateTime(actCell));
          ftReference:begin
            id:=StrToIntDef(actCell,-1);
            if id<>-1 then
              SetObjectProp(obj,PropInfo,ReferencedTable.ById[id]);
          end;
        end;
      end;
    end;
  except
    on e:exception do error(format('r:%d c:%d cn:%s %s',[i,j,Mappings[j].FieldInfo.FieldName,e.Message]));
  end;
end;

procedure TDataBase.LoadAllTables_Txt(const APath:string);
var i:integer;
begin
  for i:=0 to TableCount-1 do
    LoadTable_Txt(Table[i],APath+copy(Table[i].BaseClass.ClassName,2)+'.txt');
end;

end.
