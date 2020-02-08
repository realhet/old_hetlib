object FrmMain: TFrmMain
  Left = 0
  Top = 0
  Caption = 'OclSpeedTest'
  ClientHeight = 527
  ClientWidth = 738
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Memo1: TMemo
    Left = 0
    Top = 0
    Width = 738
    Height = 527
    Align = alClient
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Courier New'
    Font.Style = []
    Lines.Strings = (
      'Memo1')
    ParentFont = False
    TabOrder = 0
  end
  object tStartup: TTimer
    Interval = 100
    OnTimer = tStartupTimer
    Left = 192
    Top = 24
  end
  object tTwinUpdate: TTimer
    Enabled = False
    Interval = 15
    OnTimer = tTwinUpdateTimer
    Left = 272
    Top = 24
  end
end
