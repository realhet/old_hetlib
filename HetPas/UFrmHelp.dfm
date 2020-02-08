object FrmHelp: TFrmHelp
  Left = 0
  Top = 0
  Caption = 'Help'
  ClientHeight = 556
  ClientWidth = 517
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Visible = True
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 0
    Top = 103
    Width = 517
    Height = 3
    Cursor = crVSplit
    Align = alTop
    ExplicitTop = 111
    ExplicitWidth = 445
  end
  object cbCategory: TComboBoxEx
    Left = 0
    Top = 0
    Width = 517
    Height = 22
    Align = alTop
    ItemsEx = <>
    TabOrder = 0
    Text = 'cbCategory'
    OnChange = cbCategoryChange
  end
  object RichEdit1: TRichEdit
    Left = 0
    Top = 106
    Width = 517
    Height = 450
    Align = alClient
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    Lines.Strings = (
      '')
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 1
  end
  object lvEntries: TListView
    Left = 0
    Top = 25
    Width = 517
    Height = 78
    Align = alTop
    Columns = <>
    HideSelection = False
    ReadOnly = True
    TabOrder = 2
    ViewStyle = vsList
  end
  object Panel1: TPanel
    Left = 0
    Top = 22
    Width = 517
    Height = 3
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 3
  end
  object Timer1: TTimer
    Interval = 250
    OnTimer = Timer1Timer
    Left = 128
    Top = 160
  end
end
