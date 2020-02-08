unit UHetPaintBox;

interface

uses
  Windows, Sysutils, Classes, Messages, ExtCtrls, Controls, Graphics;

type
  THetPaintBox=class(TPaintBox)
  protected
    procedure WMERASEBKGND(var m:TMessage);message WM_ERASEBKGND;
  end;

type
  THetWinPaintBox=class(TCustomControl)
  private
    FOnPaint:TNotifyEvent;
  protected
    procedure WMERASEBKGND(var m:TMessage);message WM_ERASEBKGND;
    procedure Paint;override;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode);message WM_GETDLGCODE;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);override;
  public
    constructor Create(AOwner: TComponent); override;
    property Canvas;
  published
    property OnPaint: TNotifyEvent read FOnPaint write FOnPaint;

    property Align;
    property Anchors;
    property Color;
    property Constraints;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property Touch;
    property Visible;
    property OnClick;
    property OnContextPopup;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnGesture;
    property OnMouseActivate;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheel;
    property OnMouseWheelUp;
    property OnMouseWheelDown;
    property OnStartDock;
    property OnStartDrag;

    property DoubleBuffered;
    property Padding;
    property ParentDoubleBuffered;
    property TabStop;
    property TabOrder;

    property OnDockDrop;
    property OnDockOver;
    property OnEnter;
    property OnExit;
    property OnGetSiteInfo;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnUnDock;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Het',[THetPaintBox, THetWinPaintBox]);
end;

{ THetPaintBox }

procedure THetPaintBox.WMERASEBKGND(var m: TMessage);
begin
  m.Result:=ord(assigned(onpaint)or(csDesigning in ComponentState));
end;

{ THetWinPaintBox }

procedure THetWinPaintBox.WMERASEBKGND(var m: TMessage);
begin
  m.Result:=ord(assigned(OnPaint)or(csDesigning in ComponentState));
end;

procedure THetWinPaintBox.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  message.Result:=DLGC_WANTARROWS or DLGC_WANTCHARS;
  //DLGC_STATIC
  //DLGC_BUTTON;
  //DLGC_WANTTAB;
end;

constructor THetWinPaintBox.Create(AOwner: TComponent);
begin
  inherited;
  controlStyle:=[csReplicatable,csAcceptsControls,csOpaque,csReflector,csClickEvents,csDoubleClicks];
end;

procedure THetWinPaintBox.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if not (csDesigning in ComponentState) and CanFocus then
    SetFocus;

  inherited;
end;

procedure THetWinPaintBox.Paint;
begin
  Canvas.Font := Font;
  Canvas.Brush.Color := Color;
  if csDesigning in ComponentState then
    with Canvas do
    begin
      Pen.Style := psDash;
      Brush.Style := bsClear;
      Rectangle(0, 0, Width, Height);
    end;
  if Assigned(FOnPaint) then FOnPaint(Self);
end;

end.
