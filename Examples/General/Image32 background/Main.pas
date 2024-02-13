unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  GR32,
  GR32_Image;

type
  TFormMain = class(TForm)
    ImgView: TImgView32;
    procedure FormCreate(Sender: TObject);
  private
  protected
  public
  end;

var
  FormMain: TFormMain;

implementation

{$R *.dfm}

uses
  GR32.Examples,
  GR32_PNG,
  GR32_PortableNetworkGraphic; // Required for inline expansion

{ TFormMain }

{.$define SOLID_DROPSHADOW}

procedure TFormMain.FormCreate(Sender: TObject);
begin
  ImgView.Bitmap.LoadFromFile(Graphics32Examples.MediaFolder+'\coffee.png');

  ImgView.Background.CheckersStyle := bcsMedium;
  ImgView.Background.CheckersExponent := 3; // Size of each tile becomes 2^3 = 8 pixels
  ImgView.Background.PatternBitmap.LoadFromFile(Graphics32Examples.MediaFolder+'\bumps.bmp');
  ImgView.Background.OuterBorderColor := clGray;
  ImgView.Background.InnerBorderWidth := 8;
  ImgView.Background.InnerBorderColor := clWhite;
  ImgView.Background.DropShadowOffset := 6;
{$ifdef SOLID_DROPSHADOW}
  ImgView.Background.DropShadowSize := 4;
  ImgView.Background.DropShadowColor := $20000000;
{$else SOLID_DROPSHADOW}
  ImgView.Background.DropShadowBitmap.LoadFromFile(Graphics32Examples.MediaFolder+'\dropshadow.bmp');
  ImgView.Background.DropShadowBitmap.MasterAlpha := 128;
{$endif SOLID_DROPSHADOW}
end;

end.
