unit UFrmCodeInsight;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, het.Utils, het.CodeEditor;

type
  TFrmCodeInsight = class(TForm)
    lb: TListBox;
    procedure lbKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure lbKeyPress(Sender: TObject; var Key: Char);
    procedure FormDeactivate(Sender: TObject);
  private
    { Private declarations }
    WordList:TArray<AnsiString>;
    Editor:TCodeEditor;

    WordStartX:integer;//innen kezdodik a szoveg. Ha ettol balra megy, akkor hide;
    ActWord:ansistring;
    procedure RefreshList;
  public
    { Public declarations }
    procedure StartInsight(const AEditor:TCodeEditor;const AWordList:TArray<ansistring>);
  end;

var
  FrmCodeInsight: TFrmCodeInsight;

implementation

{$R *.dfm}

procedure TFrmCodeInsight.RefreshList;
var s,sOld:ansistring;
begin
  with lb, Items do begin
    ActWord:=copy(Editor.LineAtCursor,WordStartX+1,Editor.CursorPos.X-WordStartX);

    if ItemIndex>=0 then sOld:=Items[ItemIndex]
                    else sOld:='';

    BeginUpdate;
    Clear;
    for s in WordList do if Cmp(ActWord,copy(s,1,length(ActWord)))=0 then Add(s);
    EndUpdate;

    if sOld<>'' then
      ItemIndex:=IndexOf(sOld);

    if(ItemIndex<0)and(Count>0)then
      ItemIndex:=0;
  end;
end;


procedure TFrmCodeInsight.FormDeactivate(Sender: TObject);
begin
  Hide;
end;

procedure TFrmCodeInsight.lbKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key=VK_ESCAPE then begin
    Hide;
    Key:=0;
  end else if Key=VK_LEFT then begin
    if Editor.CursorPos.X=WordStartX then Hide;
    Editor.ExecuteCommand(ecMoveRel,-1);

    Key:=0;
  end else if Key=VK_RIGHT then begin
    Editor.ExecuteCommand(ecMoveRel,1);

    Key:=0;
  end;

  if Showing then begin
    RefreshList;
    if WordAt(ActWord,1)<>ActWord then Hide;
  end;
end;

procedure TFrmCodeInsight.lbKeyPress(Sender: TObject; var Key: Char);
var wl:Integer;
begin
  if ansichar(Key) in['a'..'z','A'..'Z','0'..'9','_']then begin
    Editor.ExecuteCommand(ecType,0,0,ansichar(Key));
    ActWord:=copy(Editor.LineAtCursor+' ',WordStartX+1,Editor.CursorPos.X-WordStartX);
    Key:=#0;
  end else if Key=#8 then begin
    if Editor.CursorPos.X=WordStartX then Hide;
    Editor.ExecuteCommand(ecBackSpace);

    Key:=#0;
  end else if ansichar(Key) in[#13,#32..#127] then begin
    if lb.ItemIndex>=0 then begin
      wl:=length(WordAt(Editor.LineAtCursor,WordStartX+1));//calc wordLen
      Editor.ExecuteCommand(ecMoveRel,WordStartX-Editor.CursorPos.X);
      Editor.ExecuteCommand(ecOverwrite,0);
      Editor.ExecuteCommand(ecType,0,0,lb.Items[lb.ItemIndex]+switch(Key<>#13,Key,''));
      Editor.ModifyCode(Editor.xy2pos(Editor.CursorPos,false),wl,'');
    end;

    Hide;
    Key:=#0;
  end;

  if Showing then begin
    RefreshList;
    if WordAt(ActWord,1)<>ActWord then Hide;
  end;
end;

procedure TFrmCodeInsight.StartInsight(const AEditor: TCodeEditor;const AWordList: TArray<ansistring>);
var p:TPoint;
begin
  WordList:=AWordList;
  DistinctStrArray(WordList,true);
  Editor:=AEditor;
  if(WordList=nil)or(Editor=nil)then begin Hide;exit;end;

  if Showing then begin
    Hide//toggle
  end else begin
    ActWord:=Editor.LineAtCursor;  //sor
    ActWord:=WordAt(ActWord,Editor.CursorPos.X); //wordat()
    ActWord:=copy(ActWord,1,Editor.CursorPos.X+1-WordStart); //word eleje

    if ActWord<>'' then WordStartX:=WordStart-1
                   else WordStartX:=Editor.CursorPos.X;

    lb.ItemIndex:=-1;
    RefreshList;

    if FrmCodeInsight.lb.Items.Count>0 then begin
      with Editor do p:=ClientToScreen((pt(CursorPos)-ScrollPos+pt(0,1))*CharExtent);
      Top:=p.Y;
      Left:=p.X;
      lb.ItemIndex:=0;
      Show;
    end;
  end;
end;

end.
