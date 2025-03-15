unit MainUnit;

(* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1 or LGPL 2.1 with linking exception
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * Alternatively, the contents of this file may be used under the terms of the
 * Free Pascal modified version of the GNU Lesser General Public License
 * Version 2.1 (the "FPC modified LGPL License"), in which case the provisions
 * of this license are applicable instead of those above.
 * Please see the file LICENSE.txt for additional information concerning this
 * license.
 *
 * The Original Code is GR32 Polygon Renderer Benchmark
 *
 * The Initial Developer of the Original Code is
 * Mattias Andersson <mattias@centaurix.com>
 *
 * Portions created by the Initial Developer are Copyright (C) 2000-2012
 * the Initial Developer. All Rights Reserved.
 *
 * ***** END LICENSE BLOCK ***** *)

interface

{$include GR32.inc}

(*
** Define TEST_BLEND2D to enable the Blend2D polygon rasterizer.
**
** The Blend2D rasterizer requires the Blend2D DLL files which can be
** downloaded from https://github.com/neslib/DelphiBlend2D/tree/master/Bin
*)
{-$define TEST_BLEND2D}

(*
** Define TEST_LCD to enable the VPR LCD polygon rasterizers (ClearType style anti-aliasing).
*)
{-$define TEST_LCD}

uses
{$ifdef MSWINDOWS}
  Windows, Messages,
{$endif}
  SysUtils, Classes, Graphics, StdCtrls, Controls, Forms, Dialogs, ExtCtrls,
  GR32_Image,
  GR32_Paths,
  GR32,
  GR32_System,
  GR32_Brushes,
  GR32_Polygons;

const
  // Run <TEST_SAMPLES> iterations, each taking <TEST_DURATION> milliseconds.
  // Use the best result of all samles as the final result.
  TEST_DURATION = 4000;
  TEST_SAMPLES = 4;

{$ifdef MSWINDOWS}
const
  MSG_BENCHMARK = WM_USER;
{$endif}

type
  TTestProc = procedure(Canvas: TCanvas32; FillBrush: TSolidBrush; StrokeBrush: TStrokeBrush);

  { TMainForm }

  TMainForm = class(TForm)
    BtnBenchmark: TButton;
    BtnExit: TButton;
    CbxAllRenderers: TCheckBox;
    CbxAllTests: TCheckBox;
    CmbRenderer: TComboBox;
    CmbTest: TComboBox;
    GbxResults: TGroupBox;
    GbxSettings: TGroupBox;
    Img: TImage32;
    LblRenderer: TLabel;
    LblTest: TLabel;
    MemoLog: TMemo;
    PnlBenchmark: TPanel;
    PnlBottom: TPanel;
    PnlSpacer: TPanel;
    PnlTop: TPanel;
    Splitter1: TSplitter;
    CheckBoxBatch: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure BtnBenchmarkClick(Sender: TObject);
    procedure ImgResize(Sender: TObject);
    procedure BtnExitClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    procedure RunTest(RendererClass: TPolygonRenderer32Class; TestProc: TTestProc; Samples: integer = TEST_SAMPLES; TestTime: integer = TEST_DURATION);
    procedure WriteTestResult(OperationsPerSecond: Integer);
{$ifdef MSWINDOWS}
    procedure MsgBenchmark(var Msg: TMessage); message MSG_BENCHMARK;
{$endif}
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  Types,
  Math,
  GR32_VectorUtils,
  GR32_LowLevel,
  GR32_Resamplers,
  GR32_Backends,
  GR32_VPR2,
  GR32_Polygons.GDI,
{$ifndef FPC}
  GR32_Polygons.GDIPlus,
  GR32_Polygons.Direct2D,
{$ifdef TEST_BLEND2D}
  GR32_Polygons.Blend2D,
{$endif TEST_BLEND2D}
{$endif}
  GR32_Polygons.AggLite;

var
  TestRegistry: TStringList;

procedure RegisterTest(const TestName: string; Test: TTestProc);
begin
  if not Assigned(TestRegistry) then
    TestRegistry := TStringList.Create;
  TestRegistry.AddObject(TestName, TObject(@Test));
end;

procedure TMainForm.WriteTestResult(OperationsPerSecond: Integer);
begin
  MemoLog.Lines.Add(Format('%-40s %8.0n', [cmbRenderer.Text, OperationsPerSecond*1.0]));
end;

procedure TMainForm.RunTest(RendererClass: TPolygonRenderer32Class; TestProc: TTestProc; Samples, TestTime: integer);
var
  Canvas: TCanvas32;
  FillBrush: TSolidBrush;
  StrokeBrush: TStrokeBrush;
  StopWatch: TStopWatch;
  WallClock: TStopWatch;
  i: integer;
  Operations: Int64;
  PolygonRendererBatching: IPolygonRendererBatching;
  Sample: integer;
  OpsPerSecond: integer;
  BestOpsPerSecond: integer;
  DoAbort: boolean;
begin
  RandSeed := 0;

  Canvas := TCanvas32.Create(Img.Bitmap);
  try
    Canvas.Renderer := RendererClass.Create;

    try
      Img.BeginUpdate;
      try
        Img.Bitmap.Clear(clWhite32);

        FillBrush := Canvas.Brushes.Add(TSolidBrush) as TSolidBrush;
        StrokeBrush := Canvas.Brushes.Add(TStrokeBrush) as TStrokeBrush;
        FillBrush.Visible := True;
        StrokeBrush.Visible := False;

        DoAbort := False;
        BestOpsPerSecond := 0;

        for Sample := 0 to Samples-1 do
        begin

          Operations := 0;
          Wallclock := TStopwatch.StartNew;
          StopWatch.Reset;

          repeat

            // If the rasterizer supports batching, we allow it to batch a block.
            // This might give batching rasterizers a slight unrealistic and
            // unfair advantage. One rasterizer that absolutely suffer, if we don't
            // batch, is the Direct2D rasterizer.
            if (CheckBoxBatch.Checked) and (Supports(Canvas.Renderer, IPolygonRendererBatching, PolygonRendererBatching)) then
            begin
              StopWatch.Start;
              PolygonRendererBatching.BeginDraw;
              StopWatch.Stop;
            end;
            try

              for i := 0 to 9 do
              begin
                Canvas.BeginUpdate;

                // Build path
                TestProc(Canvas, FillBrush, StrokeBrush);

                StopWatch.Start;

                // Flatten path and render
                Canvas.EndUpdate;

                StopWatch.Stop;

                Inc(Operations);
              end;

            finally
              if (PolygonRendererBatching <> nil) then
              begin
                StopWatch.Start;
                // For batching rasterizers, this is usually where the actual work will be done
                PolygonRendererBatching.EndDraw;
                StopWatch.Stop;
              end;
            end;

          until (Wallclock.ElapsedMilliseconds > TestTime);

          OpsPerSecond := (Operations * 1000) div StopWatch.ElapsedMilliseconds;

          if (OpsPerSecond > BestOpsPerSecond) then
            BestOpsPerSecond := OpsPerSecond;

          if (GetAsyncKeyState(VK_ESCAPE) <> 0) then
          begin
            DoAbort := False;
            break;
          end;
        end;

        WriteTestResult(BestOpsPerSecond);

{$IFNDEF CHANGENOTIFICATIONS}
        Img.Bitmap.Changed;
{$ENDIF}
      finally
        Img.EndUpdate;
      end;

      if (DoAbort) or (GetAsyncKeyState(VK_ESCAPE) <> 0) then
      begin
        MemoLog.Lines.Add('Aborted');
        Abort;
      end;

      Application.ProcessMessages; // Avoid Windows thinking we're hung and freezing UI

    except
      on E: EAbort do
        raise;

      on E: Exception do
        MemoLog.Lines.Add(Format('%s: Failed', [cmbRenderer.Text]));
    end;
  finally
    Canvas.Free;
  end;
end;

function RandColor: TColor32; {$IFDEF USEINLINING} inline; {$ENDIF}
begin
  Result := Random($FFFFFF) or Random($ff) shl 24;
end;

//----------------------------------------------------------------------------//
// ellipses
//----------------------------------------------------------------------------//
procedure EllipseTest(Canvas: TCanvas32; FillBrush: TSolidBrush; StrokeBrush: TStrokeBrush);
var
  W, H: Integer;
begin
  W := Canvas.Bitmap.Width;
  H := Canvas.Bitmap.Height;

  FillBrush.FillColor := RandColor;
  FillBrush.FillMode := pfNonZero;
  StrokeBrush.Visible := False;

  Canvas.Ellipse(Random(W), Random(H), Random(W shr 1), Random(H shr 1));
end;

//----------------------------------------------------------------------------//
// thin lines
//----------------------------------------------------------------------------//
procedure ThinLineTest(Canvas: TCanvas32; FillBrush: TSolidBrush; StrokeBrush: TStrokeBrush);
var
  W, H: Integer;
begin
  W := Canvas.Bitmap.Width;
  H := Canvas.Bitmap.Height;

  FillBrush.Visible := False;
  StrokeBrush.Visible := True;
  StrokeBrush.StrokeWidth := 1.0;
  StrokeBrush.FillColor := RandColor;

  Canvas.MoveTo(Random(W), Random(H));
  Canvas.LineTo(Random(W), Random(H));
  Canvas.EndPath;
end;

//----------------------------------------------------------------------------//
// thick lines
//----------------------------------------------------------------------------//
procedure ThickLineTest(Canvas: TCanvas32; FillBrush: TSolidBrush; StrokeBrush: TStrokeBrush);
var
  W, H: Integer;
begin
  W := Canvas.Bitmap.Width;
  H := Canvas.Bitmap.Height;

  FillBrush.Visible := False;
  StrokeBrush.Visible := True;
  StrokeBrush.StrokeWidth := 10.0;
  StrokeBrush.FillColor := RandColor;

  Canvas.MoveTo(Random(W), Random(H));
  Canvas.LineTo(Random(W), Random(H));
  Canvas.EndPath;
end;

//----------------------------------------------------------------------------//
// text
//----------------------------------------------------------------------------//
const
  STRINGS: array [0..5] of string = (
    'Graphics32',
    'Excellence endures!',
    'Hello World!',
    'Lorem ipsum dolor sit amet, consectetur adipisicing elit,' + #13#10 +
    'sed do eiusmod tempor incididunt ut labore et dolore magna' + #13#10 +
    'aliqua. Ut enim ad minim veniam, quis nostrud exercitation' + #13#10 +
    'ullamco laboris nisi ut aliquip ex ea commodo consequat.',
    'The quick brown fox jumps over the lazy dog.',
    'Jackdaws love my big sphinx of quartz.');

type
  TFontEntry = record
    Name: string;
    Size: Integer;
    Style: TFontStyles;
  end;

const
  FACES: array [0..5] of TFontEntry = (
    (Name: 'Trebuchet MS'; Size: 24; Style: [fsBold]),
    (Name: 'Tahoma'; Size: 20; Style: [fsItalic]),
    (Name: 'Courier New'; Size: 14; Style: []),
    (Name: 'Georgia'; Size: 8; Style: [fsItalic]),
    (Name: 'Times New Roman'; Size: 12; Style: []),
    (Name: 'Garamond'; Size: 12; Style: [])
  );

procedure TextTest(Canvas: TCanvas32; FillBrush: TSolidBrush; StrokeBrush: TStrokeBrush);
var
  W, H, I: Integer;
  Font: TFont;
begin
  W := Canvas.Bitmap.Width;
  H := Canvas.Bitmap.Height;

  FillBrush.Visible := True;
  FillBrush.FillMode := pfAlternate;
  FillBrush.FillColor := RandColor;
  StrokeBrush.Visible := False;

  I := Random(5);
  Font := Canvas.Bitmap.Font;
  Font.Name := FACES[I].Name;
  Font.Size := FACES[I].Size;
  Font.Style := FACES[I].Style;

  Canvas.RenderText(Random(W), Random(H), STRINGS[I]);
end;

//----------------------------------------------------------------------------//
// splines
//----------------------------------------------------------------------------//
function MakeCurve(const Points: TArrayOfFloatPoint; Kernel: TCustomKernel;
  Closed: Boolean; StepSize: Integer): TArrayOfFloatPoint;
var
  I, J, F, H, Index, LastIndex, Steps, R: Integer;
  K, V, W, X, Y: TFloat;
  Delta: TFloatPoint;
  Filter: TFilterMethod;
  WrapProc: TWrapProc;
  PPoint: PFloatPoint;
const
  WRAP_PROC: array[Boolean] of TWrapProc = (Clamp, Wrap);
begin
  WrapProc := Wrap_PROC[Closed];
  Filter := Kernel.Filter;
  R := Ceil(Kernel.GetWidth);
  H := High(Points);

  LastIndex := H - Ord(not Closed);
  Steps := 0;
  for I := 0 to LastIndex do
  begin
    Index := WrapProc(I + 1, H);
    Delta.X := Points[Index].X - Points[I].X;
    Delta.Y := Points[Index].Y - Points[I].Y;
    Inc(Steps, Floor(Hypot(Delta.X, Delta.Y) / StepSize) + 1);
  end;

  SetLength(Result, Steps);
  PPoint := @Result[0];

  for I := 0 to LastIndex do
  begin
    Index := WrapProc(I + 1, H);
    Delta.X := Points[Index].X - Points[I].X;
    Delta.Y := Points[Index].Y - Points[I].Y;
    Steps := Floor(Hypot(Delta.X, Delta.Y) / StepSize);
    if Steps > 0 then
    begin
      K := 1 / Steps;
      V := 0;
      for J := 0 to Steps do
      begin
        X := 0; Y := 0;
        for F := -R to R do
        begin
          Index := WrapProc(I - F, H);
          W := Filter(F + V);
          X := X + W * Points[Index].X;
          Y := Y + W * Points[Index].Y;
        end;
        PPoint^ := FloatPoint(X, Y);
        Inc(PPoint);
        V := V + K;
      end;
    end;
  end;
end;

procedure SplinesTest(Canvas: TCanvas32; FillBrush: TSolidBrush; StrokeBrush: TStrokeBrush);
var
  Input, Points: TArrayOfFloatPoint;
  K: TSplineKernel;
  W, H, I: Integer;
begin
  W := Canvas.Bitmap.Width;
  H := Canvas.Bitmap.Height;
  SetLength(Input, 10);
  for I := 0 to High(Input) do
  begin
    Input[I].X := Random(W);
    Input[I].Y := Random(H);
  end;
  K := TSplineKernel.Create;
  try
    Points := MakeCurve(Input, K, True, 3);
  finally
    K.Free;
  end;

  FillBrush.Visible := True;
  FillBrush.FillMode := pfEvenOdd;
  FillBrush.FillColor := RandColor;
  StrokeBrush.Visible := False;

  Canvas.Polygon(Points);
end;

//----------------------------------------------------------------------------//

procedure TMainForm.FormCreate(Sender: TObject);
begin
  // set priority class and thread priority for better accuracy
{$ifdef MSWINDOWS}
  SetPriorityClass(GetCurrentProcess, HIGH_PRIORITY_CLASS);
  SetThreadPriority(GetCurrentThread, THREAD_PRIORITY_HIGHEST);
{$endif}

  CmbTest.Items := TestRegistry;
  CmbTest.ItemIndex := 0;
  PolygonRendererList.GetClassNames(CmbRenderer.Items);
  CmbRenderer.ItemIndex := 0;
  Img.SetupBitmap(True, clWhite32);
end;


procedure TMainForm.FormShow(Sender: TObject);
begin
{$ifdef MSWINDOWS}
  if (FindCmdLineSwitch('benchmark')) then
    PostMessage(Handle, MSG_BENCHMARK, 0, 0);
{$endif}
end;

{$ifdef MSWINDOWS}
procedure TMainForm.MsgBenchmark(var Msg: TMessage);
var
  Iterations: integer;
  i: integer;
{$if defined(FRAMEWORK_VCL)}
  s: string;
{$ifend}
begin
  (*
  ** Detect and initiate automated benchmark for profiling
  *)

{$if defined(FRAMEWORK_VCL)}
  if (not FindCmdLineSwitch('benchmark', s)) then
    exit;
  Iterations := StrToIntDef(s, 1);
{$else}
  if (not FindCmdLineSwitch('benchmark')) then
    exit;
  Iterations := 1;
{$ifend}

  Screen.Cursor := crHourGlass;

  MemoLog.Lines.Add(Format('Running benchmark: %d iterations', [Iterations]));

  CbxAllTests.Checked := True;

  for i := 0 to Iterations-1 do
  begin
    MemoLog.Lines.Add(Format('Iteration %d', [i+1]));
    Update;

    BtnBenchmark.Click;
  end;

  Application.Terminate;
end;
{$endif}

procedure TMainForm.BtnBenchmarkClick(Sender: TObject);

  procedure TestRenderer(RendererClass: TPolygonRenderer32Class);
  begin
    RunTest(RendererClass, TTestProc(cmbTest.Items.Objects[cmbTest.ItemIndex]));
  end;

  procedure TestAllRenderers;
  var
    I: Integer;
    RendererClass: TPolygonRenderer32Class;
  begin
    for I := 0 to CmbRenderer.Items.Count - 1 do
    begin
      CmbRenderer.ItemIndex := I;
      RendererClass := TPolygonRenderer32Class(PolygonRendererList[CmbRenderer.ItemIndex]);
      TestRenderer(RendererClass);
    end;
    MemoLog.Lines.Add('');
  end;

  procedure PerformTest;
  var
    RendererClass: TPolygonRenderer32Class;
  begin
    MemoLog.Lines.Add(Format('=== Test: %s (operations/second) ===', [cmbTest.Text]));
    if CbxAllRenderers.Checked then
      TestAllRenderers
    else
    begin
      RendererClass := TPolygonRenderer32Class(PolygonRendererList[CmbRenderer.ItemIndex]);
      TestRenderer(RendererClass);
    end;
  end;

  procedure PerformAllTests;
  var
    I: Integer;
  begin
    for I := 0 to CmbTest.Items.Count - 1 do
    begin
      CmbTest.ItemIndex := I;
      Update;
      PerformTest;
    end;
    MemoLog.Lines.Add('');
  end;

begin
  Screen.Cursor := crHourGlass;
  try
    Img.Bitmap.Clear(clWhite32);
    Update;

    // We are calling Application.ProcessMessages inside the test loop
    // so disable form to avoid UI recursion.
    Enabled := False;
    try

      if CbxAllTests.Checked then
        PerformAllTests
      else
        PerformTest;

    finally
      Enabled := True;
    end;

  finally
    Screen.Cursor := crDefault;
  end;
end;

function CreateLine(const x1, y1, x2, y2, width: TFloat): TArrayOfFloatPoint;
var
  dx, dy, d: TFloat;
begin
  dx := x2 - x1;
  dy := y2 - y1;
  d := Sqrt(Sqr(dx) + Sqr(dy));
  if d <> 0 then
  begin
    dx := width * (y2 - y1) / d;
    dy := width * (x2 - x1) / d;
    SetLength(Result, 4);
    Result[0] := FloatPoint(x1 - dx, y1 + dy);
    Result[1] := FloatPoint(x2 - dx, y2 + dy);
    Result[2] := FloatPoint(x2 + dx, y2 - dy);
    Result[3] := FloatPoint(x1 + dx, y1 - dy);
  end
  else
  begin
    SetLength(Result, 2);
    Result[0] := FloatPoint(x1, y1);
    Result[1] := FloatPoint(x2, y2);
  end;
end;

procedure TMainForm.ImgResize(Sender: TObject);
begin
  Img.SetupBitmap(True, clWhite32);
end;

procedure TMainForm.BtnExitClick(Sender: TObject);
begin
  Close;
end;

initialization
{$if not defined(TEST_LCD)}
  // We're not interested in the ClearType rasterizers
  UnregisterPolygonRenderer(TPolygonRenderer32LCD);
  UnregisterPolygonRenderer(TPolygonRenderer32LCD2);
{$ifend}

  RegisterTest('Ellipses', EllipseTest);
  RegisterTest('Thin Lines', ThinLineTest);
  RegisterTest('Thick Lines', ThickLineTest);
  RegisterTest('Splines', SplinesTest);
  if Assigned(TBitmap32.GetPlatformBackendClass.GetInterfaceEntry(ITextToPathSupport)) then
    RegisterTest('Text', TextTest);

end.
