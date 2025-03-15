object MainForm: TMainForm
  Left = 324
  Top = 77
  Caption = 'Polygon Renderer Benchmark'
  ClientHeight = 612
  ClientWidth = 754
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  ShowHint = True
  OnCreate = FormCreate
  OnShow = FormShow
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 0
    Top = 373
    Width = 754
    Height = 5
    Cursor = crVSplit
    Align = alBottom
    AutoSnap = False
    Beveled = True
    ResizeStyle = rsUpdate
    ExplicitTop = 350
    ExplicitWidth = 746
  end
  object PnlTop: TPanel
    Left = 0
    Top = 0
    Width = 754
    Height = 373
    Align = alClient
    BevelOuter = bvNone
    BorderWidth = 10
    TabOrder = 0
    object Img: TImage32
      Left = 10
      Top = 10
      Width = 734
      Height = 353
      Align = alClient
      Bitmap.ResamplerClassName = 'TNearestResampler'
      BitmapAlign = baTopLeft
      Scale = 1.000000000000000000
      ScaleMode = smNormal
      TabOrder = 0
      OnResize = ImgResize
    end
  end
  object PnlBottom: TPanel
    Left = 0
    Top = 378
    Width = 754
    Height = 234
    Align = alBottom
    BevelOuter = bvNone
    BorderWidth = 10
    TabOrder = 1
    object GbxSettings: TGroupBox
      Left = 10
      Top = 10
      Width = 319
      Height = 214
      Align = alLeft
      Caption = 'Benchmark Settings'
      TabOrder = 0
      DesignSize = (
        319
        214)
      object LblTest: TLabel
        Left = 14
        Top = 34
        Width = 23
        Height = 13
        Caption = '&Test:'
        Color = clBtnFace
        FocusControl = CmbTest
        ParentColor = False
        Transparent = False
      end
      object LblRenderer: TLabel
        Left = 14
        Top = 61
        Width = 50
        Height = 13
        Caption = '&Renderer:'
        Color = clBtnFace
        FocusControl = CmbRenderer
        ParentColor = False
        Transparent = False
      end
      object BtnBenchmark: TButton
        Left = 14
        Top = 178
        Width = 139
        Height = 25
        Caption = 'Do &Benchmark'
        TabOrder = 4
        OnClick = BtnBenchmarkClick
      end
      object CmbTest: TComboBox
        Left = 78
        Top = 31
        Width = 225
        Height = 21
        Style = csDropDownList
        TabOrder = 0
      end
      object CmbRenderer: TComboBox
        Left = 78
        Top = 58
        Width = 225
        Height = 21
        Style = csDropDownList
        TabOrder = 1
      end
      object CbxAllTests: TCheckBox
        Left = 14
        Top = 98
        Width = 167
        Height = 19
        Caption = 'Benchmark all tests'
        TabOrder = 2
      end
      object CbxAllRenderers: TCheckBox
        Left = 14
        Top = 118
        Width = 167
        Height = 19
        Caption = 'Benchmark all renderers'
        TabOrder = 3
      end
      object BtnExit: TButton
        Left = 164
        Top = 178
        Width = 139
        Height = 25
        Caption = 'E&xit'
        TabOrder = 5
        OnClick = BtnExitClick
      end
      object CheckBoxBatch: TCheckBox
        Left = 14
        Top = 138
        Width = 167
        Height = 19
        Hint = 'Enable batching for renderers that support it'
        Caption = 'Enable batching'
        TabOrder = 6
      end
    end
    object GbxResults: TGroupBox
      Left = 339
      Top = 10
      Width = 405
      Height = 214
      Align = alClient
      Caption = 'Benchmark Res&ults'
      TabOrder = 1
      object PnlBenchmark: TPanel
        Left = 2
        Top = 15
        Width = 401
        Height = 197
        Align = alClient
        BevelOuter = bvNone
        BorderWidth = 10
        TabOrder = 0
        object MemoLog: TMemo
          Left = 10
          Top = 10
          Width = 381
          Height = 177
          Align = alClient
          Font.Charset = ANSI_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Courier New'
          Font.Pitch = fpFixed
          Font.Style = []
          ParentFont = False
          ScrollBars = ssVertical
          TabOrder = 0
          WordWrap = False
        end
      end
    end
    object PnlSpacer: TPanel
      Left = 329
      Top = 10
      Width = 10
      Height = 214
      Align = alLeft
      BevelOuter = bvNone
      TabOrder = 2
    end
  end
end
