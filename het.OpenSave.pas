unit het.OpenSave;

interface
uses Windows, Messages, SysUtils, Classes, Graphics, Controls, dialogs, forms;

type topensavenotify=procedure(fname:string)of object;
type
  TOpenSave=class(TComponent)
  private
    FFileName:string;
    FIntOD,FExOD:TOpenDialog;
    FIntSD,FExSD:TSaveDialog;
    FOnO,FOnS,FOnN:topensavenotify;
    FFilter:string;
    fDefExt: string;
    fcreatebak: boolean;
    FChg,FIsNew:boolean;
    function OD:TOpenDialog;
    function SD:TSaveDialog;
  public
    function DoSave(fn: String): boolean;
    function DoOpen(fn: string): boolean;
    function Open(fn:string=''):boolean;
    function Save:boolean;
    function SaveAs:boolean;
    function New(const ANewFileName:string=''):boolean;
    procedure Chg;
    procedure SetChg(v:boolean);
    procedure ClearChg;
    property isChanged:boolean read fchg write fchg;
    property isNew:boolean read FIsNew;
    procedure Loaded;override;
    Destructor Destroy;override;
    Constructor Create(o:tcomponent);override;
    procedure CloseQuery(var ca:boolean);
    function CanSave:boolean;
  published
    property DefaultExt:string read fDefExt write fDefExt;
    property Filter:string read ffilter write ffilter;
    property FileName:string read FFileName write FFileName;
    property OnOpen:topensavenotify read FOnO write FOnO;
    property OnSave:topensavenotify read FOnS write FOnS;
    property OnNew:topensavenotify read FOnN write FOnN;
    property CreateBak:boolean read fcreatebak write fcreatebak;
    property ExternalOpenDialog:TOpenDialog read FExOD write FExOD;
    property ExternalSaveDialog:TSaveDialog read FExSD write FExSD;
  end;


  {hasznalat: a document.beforechangeben kell hivogatni a store metodust,
              az OnRestore eventnel pedig visszaallitan az elozo helyzetet}
  TUndoManager=class;
  TOnUndoRestore=procedure(sender:tundoManager;var caption,data:ansistring)of object;
  TUndoManager=class(TComponent)
  private
    FMaxSizeKB: integer;
    FMaxCount: integer;
    FCounter: integer;
  public
    mode:integer;
    UBuf:array of record capt,data:ansistring end;
    FRedo:TUndoManager;
    FOnRestore: TOnUndoRestore;
    procedure SetRedoEnabled(const Value: boolean);
    function GetRedoEnabled:boolean;
    procedure CheckMax;
  public
    destructor Destroy;override;
    procedure Reset;
    procedure Store(const caption,data:ansistring);
    procedure Undo;
    procedure Redo;
    function CanUndo:boolean;
    function CanRedo:boolean;
    property Counter:integer read FCounter write FCounter;  //store,redo:+1, undo:-1
  published
    property RedoEnabled:boolean read GetRedoEnabled write SetRedoEnabled default false;
    property OnRestore:TOnUndoRestore read FOnRestore write FOnRestore;
    property MaxCount:integer read FMaxCount write FMaxCount default 0;
    property MaxSizeKB:integer read FMaxSizeKB write FMaxSizeKB default 0;
  end;

procedure Register;

implementation
uses registry, Math, het.utils;
{ TAppearance }

procedure Register;
begin
  RegisterComponents('Het', [TOpenSave,TUndoManager]);
end;

{ TOpenSave }

function TOpenSave.OD:TOpenDialog;
  procedure setupfod;
  begin
    fintod.Filter:=filter;
    fintod.DefaultExt:=DefaultExt;
    fintod.Options:=[ofPathMustExist,ofFileMustExist,ofNoChangeDir];
  end;
begin
  if FExOD<>nil then
    Result:=FExOD
  else begin
    setupfod;
    Result:=FIntOD;
  end;
end;

function TOpenSave.SD:TSaveDialog;
  procedure setupfsd;
  begin
    fintsd.Filter:=filter;
    fintsd.DefaultExt:=DefaultExt;
    fintsd.Options:=[ofPathMustExist,ofOverwritePrompt,ofNoChangeDir];
  end;
begin
  if FExOD<>nil then
    result:=FExSD
  else begin
    setupfsd;
    result:=FIntSD;
  end;
end;

procedure TOpenSave.SetChg(v: boolean);
begin
  FChg:=v;
end;

function TOpenSave.CanSave: boolean;
begin
  result:=isChanged or isNew;
end;

procedure TOpenSave.Chg;begin FChg:=true;end;
procedure TOpenSave.ClearChg;begin FChg:=false;end;

constructor TOpenSave.Create(o: tcomponent);
begin
  inherited;
  FIntOD:=TOpenDialog.Create(self);FIntOD.Title:='Open';fIntOD.InitialDir:=apppath;
  FIntSD:=TSaveDialog.Create(Self);FIntSD.Title:='Save';fIntSD.InitialDir:=apppath;
end;

destructor TOpenSave.Destroy;
begin
  if ischanged then
    if not(csdestroying in Application.ComponentState) then begin
      case Application.MessageBox(pchar('Save changes to "'+extractfilename(filename)+'" ?'),'Confirm',MB_ICONQUESTION+MB_YESNO)of
        ID_YES:Save;
      end;
    end else begin
      //Assert(false,'TOpenSave.Destroy() '+extractfilename(filename)+' cannot show a file save confirmation dialog while application.destroy :@');
    end;

  inherited;
end;


procedure TOpenSave.Loaded;
begin inherited;New;end;

Function TOpenSave.New(const ANewFileName:string=''):boolean;
begin
  result:=false;
  if ischanged then begin
    case Application.MessageBox(pchar('Save changes to "'+extractfilename(filename)+'" ?'),'Confirm',MB_ICONQUESTION+MB_YESNOCANCEL)of
      ID_Cancel:exit;
      ID_YES:if not save then exit;
    end;
  end;
  FileName:=ANewFileName;
  if assigned(FOnN)then FOnN(FileName);
  fisnew:=true;
  ischanged:=false;
  result:=true;
end;

function TOpenSave.Open(fn:string=''):boolean;
begin
  result:=false;
  if ischanged then begin
    case Application.MessageBox(pchar('Save changes to "'+extractfilename(filename)+'" ?'),'Confirm',MB_ICONQUESTION+MB_YESNOCANCEL)of
      ID_Cancel:exit;
      ID_YES:if not Save then exit;
    end;
  end;
  if fn<>'' then begin OD.FileName:=fn;result:=true end
            else result:=od.Execute;
  if result then result:=DoOpen(od.FileName);
end;

function TOpenSave.DoOpen(fn:string):boolean;
begin
  if not FileExists(fn)then exit(false);
  FFileName:=fn;
  if assigned(FOnO)then begin
    FOnO(FileName);
    ischanged:=false;
    FIsNew:=false;
    result:=true;
  end else
    result:=false;
end;

function TOpenSave.Save: boolean;
begin
  if FIsNew then result:=SaveAs
            else result:=DoSave(FileName);
end;

function TOpenSave.SaveAs: boolean;
begin
  sd.FileName:=ffilename;
  with sd do begin
    result:=Execute;
    if result then
      result:=DoSave(sd.FileName);
  end;
end;

function TOpenSave.DoSave(fn:String):boolean;
begin
  filename:=fn;

  if CreateBak and fileexists(FileName)then begin
    try CopyFile(PWideChar(FileName),PWideChar(FileName+'.bak'),false);except end;
  end;

  if assigned(FOnS)then FOnS(filename);
  ischanged:=false;
  FIsNew:=false;
  result:=true;
end;


procedure TOpenSave.CloseQuery(var ca:boolean);
begin
  if ca=false then exit;
  if ischanged then begin
    case Application.MessageBox(pchar('Save changes to '+extractfilename(filename)+' ?'),'Confirm',MB_ICONQUESTION+MB_YESNOCancel)of
      ID_Cancel:ca:=false;
      ID_YES:ca:=Save;
      ID_NO:begin fchg:=false;ca:=true;end;
    end;
  end;
end;

{ TUndoManager }

function TUndoManager.CanRedo: boolean;
begin
  result:=(FRedo<>nil)and FRedo.CanUndo;
end;

function TUndoManager.CanUndo: boolean;
begin
  result:=length(UBuf)>0;
end;

destructor TUndoManager.Destroy;
begin
  RedoEnabled:=false;
  reset;
  inherited;
end;

function TUndoManager.GetRedoEnabled: boolean;
begin
  result:=FRedo<>nil;
end;

procedure TUndoManager.Redo;
begin
  if not canredo then exit;
  FRedo.OnRestore:=OnRestore;
  mode:=2;
  try FRedo.Undo;finally end;
  mode:=0;
end;

procedure TUndoManager.Reset;
begin
  SetLength(ubuf,0);
  if FRedo<>nil then FRedo.Reset;
end;

procedure TUndoManager.SetRedoEnabled(const Value: boolean);
begin
  if Value=GetRedoEnabled then exit;
  if Value then FRedo:=TUndoManager.Create(Self)
           else FreeAndNil(FRedo);
end;

procedure TUndoManager.CheckMax;
procedure DelFirst(n:integer);var i:integer;
begin
  if n>=length(UBuf)then n:=high(ubuf);
  if n<=0 then exit;
  for i:=0 to high(ubuf)-n do Ubuf[i]:=Ubuf[i+n];
  setlength(UBuf,length(UBuf)-n);
end;
var i,j:integer;
begin
  {count}if MaxCount>0 then begin
    DelFirst(length(UBuf)-MaxCount);
  end;
  {size}if MaxSizeKB>0 then begin
     i:=high(UBuf);j:=0;
     while i>=0 do begin
       j:=j+length(ubuf[i].data);
       if j shr 10>MaxSizeKB then break;
       i:=i-1;
     end;
     DelFirst(i+1);
  end;
end;

procedure TUndoManager.Store(const caption, data: ansistring);
begin
  if mode in[0,2] then begin
    if mode=0 then if FRedo<>nil then FRedo.Reset;
    SetLength(UBuf,length(UBuf)+1);
    UBuf[high(UBuf)].capt:=caption;
    UBuf[high(UBuf)].data:=data;
    CheckMax;
    inc(FCounter);
  end else if mode=1 then begin
    If FRedo<>nil then FRedo.Store(caption,data);
  end;
end;

procedure TUndoManager.Undo;
begin
  If not canundo then exit;
  if assigned(OnRestore)then begin
    mode:=1;
    try with ubuf[High(UBuf)]do OnRestore(self,capt,data);finally end;
    mode:=0;
  end;
  SetLength(UBuf,Length(UBuf)-1);
  dec(FCounter);
end;

end.


