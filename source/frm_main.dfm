object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'frmMain'
  ClientHeight = 442
  ClientWidth = 628
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  TextHeight = 15
  object btnOpenFile: TButton
    Left = 526
    Top = 336
    Width = 75
    Height = 25
    Action = actOpen
    TabOrder = 0
  end
  object memoFile: TMemo
    Left = 8
    Top = 16
    Width = 225
    Height = 409
    Lines.Strings = (
      'memoFile')
    ScrollBars = ssBoth
    TabOrder = 1
  end
  object memoBin: TMemo
    Left = 256
    Top = 16
    Width = 345
    Height = 105
    Lines.Strings = (
      'memoBin')
    ScrollBars = ssBoth
    TabOrder = 2
  end
  object memoToken: TMemo
    Left = 264
    Top = 136
    Width = 241
    Height = 289
    Lines.Strings = (
      'memoToken')
    ScrollBars = ssBoth
    TabOrder = 3
  end
  object dlgOpenText: TOpenTextFileDialog
    Filter = 'Text files|*.txt|SQL files|*.sql|All files|*.*'
    Encodings.Strings = (
      'ASCII'
      'ANSI'
      'UTF-7'
      'UTF-8')
    Left = 576
    Top = 152
  end
  object lstMain: TActionList
    Left = 576
    Top = 248
    object actOpen: TAction
      Caption = 'Open File'
      OnExecute = actOpenExecute
    end
  end
end
