object FormLineStippling: TFormLineStippling
  Left = 216
  Top = 109
  Caption = 'Line Stippling Example'
  ClientHeight = 221
  ClientWidth = 249
  Color = clBtnFace
  Constraints.MinHeight = 260
  Constraints.MinWidth = 265
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  DesignSize = (
    249
    221)
  TextHeight = 13
  object PaintBox: TPaintBox32
    Left = 8
    Top = 10
    Width = 200
    Height = 200
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 0
    OnPaintBuffer = PaintBoxPaintBuffer
  end
  object ScrollBar: TScrollBar
    Left = 224
    Top = 10
    Width = 16
    Height = 200
    Anchors = [akTop, akRight, akBottom]
    Kind = sbVertical
    Min = 1
    PageSize = 0
    Position = 50
    TabOrder = 1
    OnChange = ScrollBarChange
  end
end
