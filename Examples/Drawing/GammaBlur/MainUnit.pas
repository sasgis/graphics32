unit MainUnit;

interface

uses
  {$IFNDEF FPC} Windows, {$ELSE} LCLIntf, LCLType, {$ENDIF}
  SysUtils, Classes, Graphics, Controls, Forms, Menus, Dialogs, ComCtrls,
  ExtCtrls, StdCtrls, Math,
  GR32, GR32_Image, GR32_Layers, GR32_RangeBars;

type
  TFormGammaBlur = class(TForm)
    PaintBoxIncorrect: TPaintBox32;
    LabelIncorrect: TLabel;
    LabelCorrect: TLabel;
    PaintBoxCorrect: TPaintBox32;
    GaugeBarGamma: TGaugeBar;
    LabelGamma: TLabel;
    LabelGammaValue: TLabel;
    GaugeBarBlurRadius: TGaugeBar;
    LabelBlur: TLabel;
    LabelBlurValue: TLabel;
    Panel1: TPanel;
    LabelTestImage: TLabel;
    RadioButtonRedGreen: TRadioButton;
    RadioButtonCircles: TRadioButton;
    Panel2: TPanel;
    LabelBlurType: TLabel;
    RadioButtonGaussianBlur: TRadioButton;
    RadioButtonFastBlur: TRadioButton;
    procedure PaintBoxIncorrectPaintBuffer(Sender: TObject);
    procedure PaintBoxCorrectPaintBuffer(Sender: TObject);
    procedure GaugeBarGammaChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure GaugeBarBlurRadiusChange(Sender: TObject);
    procedure PaintBoxResize(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure RadioButtonTestImageClick(Sender: TObject);
  private
    FTestBitmap: TBitmap32;
    procedure ComposeTestImage;
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  FormGammaBlur: TFormGammaBlur;

implementation

{$IFDEF FPC}
{$R *.lfm}
{$ELSE}
{$R *.dfm}
{$ENDIF}

uses
  GR32_Math,
  GR32_Polygons,
  GR32_VectorUtils,
  GR32_Gamma,
  GR32_System,
  GR32_Blurs,
  GR32_Resamplers;

{ TFrmGammaBlur }

constructor TFormGammaBlur.Create(AOwner: TComponent);
begin
  inherited;
  PaintBoxIncorrect.BufferOversize := 0;
  PaintBoxCorrect.BufferOversize := 0;
end;

procedure TFormGammaBlur.FormCreate(Sender: TObject);
begin
  GaugeBarGammaChange(nil);
  FTestBitmap := TBitmap32.Create;
end;

procedure TFormGammaBlur.FormDestroy(Sender: TObject);
begin
  FTestBitmap.Free;
end;

procedure TFormGammaBlur.GaugeBarBlurRadiusChange(Sender: TObject);
var
  BlurRadius: Double;
begin
  BlurRadius := 0.1 * GaugeBarBlurRadius.Position;
  LabelBlurValue.Caption := FloatToStrF(BlurRadius, ffFixed, 3, 1) + 'px';
  PaintBoxIncorrect.Invalidate;
  PaintBoxCorrect.Invalidate;
end;

procedure TFormGammaBlur.GaugeBarGammaChange(Sender: TObject);
var
  GammaValue: Double;
begin
  GammaValue := 0.001 * GaugeBarGamma.Position;
  LabelGammaValue.Caption := FloatToStrF(GammaValue, ffFixed, 4, 3);
  SetGamma(GammaValue);
  PaintBoxCorrect.Invalidate;
end;

procedure ComposeTestImageRedGreen(Bitmap: TBitmap32);
begin
  Bitmap.Clear(clRed32);
  Bitmap.FillRect(0, 0, Bitmap.Width, Bitmap.Height div 2, clLime32);
end;

procedure ComposeTestImageCircles(Bitmap: TBitmap32);
var
  Points: TArrayOfFloatPoint;
  Index: Integer;
begin
  Bitmap.Clear(clBlack32);
  RandSeed := integer($DEADBABE);
  for Index := 0 to 70 do
  begin
    Points := Circle(Bitmap.Width * Random, Bitmap.Height * Random,
      0.5 * Min(Bitmap.Width, Bitmap.Height) * Random);
    PolygonFS(Bitmap, Points, HSLtoRGB(Random, 1, 0.5));
  end;
end;

procedure TFormGammaBlur.PaintBoxCorrectPaintBuffer(Sender: TObject);
begin
  FTestBitmap.DrawTo(PaintBoxCorrect.Buffer);
  if RadioButtonGaussianBlur.Checked then
    GaussianBlurGamma(PaintBoxCorrect.Buffer, 0.1 * GaugeBarBlurRadius.Position)
  else
    FastBlurGamma(PaintBoxCorrect.Buffer, 0.1 * GaugeBarBlurRadius.Position);
end;

procedure TFormGammaBlur.ComposeTestImage;
begin
  if RadioButtonCircles.Checked then
    ComposeTestImageCircles(FTestBitmap)
  else
    ComposeTestImageRedGreen(FTestBitmap);
end;

procedure TFormGammaBlur.PaintBoxResize(Sender: TObject);
begin
  FTestBitmap.SetSize(
    Max(PaintBoxCorrect.Width, PaintBoxIncorrect.Width),
    Max(PaintBoxCorrect.Height, PaintBoxIncorrect.Height)
    );
  ComposeTestImage;
end;

procedure TFormGammaBlur.RadioButtonTestImageClick(Sender: TObject);
begin
  ComposeTestImage;
  PaintBoxCorrect.Invalidate;
  PaintBoxIncorrect.Invalidate;
end;

procedure TFormGammaBlur.PaintBoxIncorrectPaintBuffer(Sender: TObject);
begin
  FTestBitmap.DrawTo(PaintBoxIncorrect.Buffer);
  if RadioButtonGaussianBlur.Checked then
    GaussianBlur(PaintBoxIncorrect.Buffer, 0.1 * GaugeBarBlurRadius.Position)
  else
    FastBlur(PaintBoxIncorrect.Buffer, 0.1 * GaugeBarBlurRadius.Position);
end;

end.
