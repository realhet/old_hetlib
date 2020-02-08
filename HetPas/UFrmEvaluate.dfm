object FrmEvaluate: TFrmEvaluate
  Left = 0
  Top = 0
  Caption = 'Evaluate'
  ClientHeight = 273
  ClientWidth = 426
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  OnKeyDown = FormKeyDown
  DesignSize = (
    426
    273)
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 8
    Width = 52
    Height = 13
    Caption = 'Expression'
  end
  object Label2: TLabel
    Left = 8
    Top = 55
    Width = 30
    Height = 13
    Caption = 'Result'
  end
  object cbExpression: TComboBoxEx
    Left = 8
    Top = 27
    Width = 410
    Height = 22
    ItemsEx = <>
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 0
    OnKeyDown = cbExpressionKeyDown
    ExplicitWidth = 412
  end
  object mResult: TMemo
    Left = 8
    Top = 74
    Width = 410
    Height = 191
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 1
    WordWrap = False
    ExplicitWidth = 412
    ExplicitHeight = 193
  end
end
