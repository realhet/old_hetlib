object FrmConstProperties: TFrmConstProperties
  Left = 0
  Top = 0
  Caption = 'FrmConstProperties'
  ClientHeight = 71
  ClientWidth = 294
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Value: TLabel
    Left = 12
    Top = 19
    Width = 26
    Height = 13
    Caption = 'Value'
  end
  object Label1: TLabel
    Left = 12
    Top = 43
    Width = 47
    Height = 13
    Caption = 'DirtyMask'
  end
  object eConst: TEdit
    Left = 72
    Top = 16
    Width = 105
    Height = 21
    TabOrder = 0
    OnChange = eDirtyChange
  end
  object eDirty: TEdit
    Left = 72
    Top = 42
    Width = 105
    Height = 21
    TabOrder = 1
    OnChange = eDirtyChange
  end
  object bOk: TBitBtn
    Left = 200
    Top = 16
    Width = 75
    Height = 22
    DoubleBuffered = True
    Kind = bkOK
    NumGlyphs = 2
    ParentDoubleBuffered = False
    TabOrder = 2
  end
  object bCancel: TBitBtn
    Left = 200
    Top = 40
    Width = 75
    Height = 22
    DoubleBuffered = True
    Kind = bkCancel
    NumGlyphs = 2
    ParentDoubleBuffered = False
    TabOrder = 3
  end
end
