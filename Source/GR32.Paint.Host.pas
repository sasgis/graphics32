unit GR32.Paint.Host;

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
 * The Original Code is Paint tools for Graphics32
 *
 * The Initial Developer of the Original Code is
 * Anders Melander, anders@melander.dk
 *
 * Portions created by the Initial Developer are Copyright (C) 2008-2025
 * the Initial Developer. All Rights Reserved.
 *
 * ***** END LICENSE BLOCK ***** *)

interface

{$INCLUDE GR32.inc}

uses
  Classes,
  Controls,
  GR32,
  GR32_Image,
  GR32_Layers,
  GR32.Paint.API,
  GR32.Paint.Tool,
  GR32.Paint.Tool.API;


//------------------------------------------------------------------------------
//
//      TBitmap32PaintHost
//
//------------------------------------------------------------------------------
// An example implementation of IBitmap32PaintHost using TImage32 or TImgView32.
//------------------------------------------------------------------------------
type
  TBitmap32PaintHost = class(TInterfacedObject, IBitmap32PaintHost)
  private
    FImage: TCustomImage32;

  private
    FPaintLayer: TBitmapLayer;

  private
    FColorPrimary: TColor32;
    FColorSecondary: TColor32;

  private
    // IBitmap32PaintHost
    function GetPaintLayer: TBitmapLayer;
    procedure SetPaintLayer(const Value: TBitmapLayer);

    function GetColorPrimary: TColor32;
    procedure SetColorPrimary(const Value: TColor32);
    function GetColorSecondary: TColor32;
    procedure SetColorSecondary(const Value: TColor32);

    function GetMagnification: Single;
    procedure SetMagnification(const Value: Single);

    function ViewPortToScreen(const APoint: TPoint): TPoint;
    function ScreenToViewPort(const APoint: TPoint): TPoint;
    function ViewPortToBitmap(const APoint: TPoint; SnapToNearest: boolean = True): TPoint; overload;
    function ViewPortToBitmap(const APoint: TFloatPoint): TFloatPoint; overload;
    function BitmapToViewPort(const APoint: TPoint): TPoint;

    function GetToolSettings(const AToolKey: string): ISettingValues;

    function CreateToolContext(const APaintTool: IBitmap32PaintTool): IBitmap32PaintToolContext;

    function SetToolVectorCursor(const Polygon: TArrayOfFixedPoint; HotspotX, HotspotY: integer; Color: TColor32; const OutlinePattern: TArrayOfColor32): boolean;
    procedure Changed(const Action: string);

  public
    constructor Create(AImage: TCustomImage32);
  end;


//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

implementation

//------------------------------------------------------------------------------
//
//      TBitmap32PaintHost
//
//------------------------------------------------------------------------------
constructor TBitmap32PaintHost.Create(AImage: TCustomImage32);
begin
  inherited Create;

  FImage := AImage;
end;

//------------------------------------------------------------------------------

function TBitmap32PaintHost.GetPaintLayer: TBitmapLayer;
begin
  Result := FPaintLayer;
end;

procedure TBitmap32PaintHost.SetPaintLayer(const Value: TBitmapLayer);
begin
  FPaintLayer := Value;
end;

//------------------------------------------------------------------------------

function TBitmap32PaintHost.GetColorPrimary: TColor32;
begin
  Result := FColorPrimary;
end;

function TBitmap32PaintHost.GetColorSecondary: TColor32;
begin
  Result := FColorSecondary;
end;

procedure TBitmap32PaintHost.SetColorPrimary(const Value: TColor32);
begin
  FColorPrimary := Value;
end;

procedure TBitmap32PaintHost.SetColorSecondary(const Value: TColor32);
begin
  FColorSecondary := Value;
end;

//------------------------------------------------------------------------------

function TBitmap32PaintHost.ViewPortToBitmap(const APoint: TPoint; SnapToNearest: boolean): TPoint;
var
  SnapThreshold: integer;
begin
  if (SnapToNearest) then
  begin
    SnapThreshold := Trunc((FImage.Scale-1) / 2);

    // Snap the coordinates to the nearest pixel
    Result := GR32.Point(APoint.X + SnapThreshold, APoint.Y + SnapThreshold);
  end else
    Result := APoint;

  if (FPaintLayer <> nil) then
    Result := FPaintLayer.ControlToLayer(Result)
  else
    Result := FImage.ControlToBitmap(Result);
end;

function TBitmap32PaintHost.ViewPortToBitmap(const APoint: TFloatPoint): TFloatPoint;
begin
  if (FPaintLayer <> nil) then
    Result := FPaintLayer.ControlToLayer(APoint)
  else
    Result := FImage.ControlToBitmap(APoint);
end;

function TBitmap32PaintHost.BitmapToViewPort(const APoint: TPoint): TPoint;
begin
  if (FPaintLayer <> nil) then
    Result := FPaintLayer.LayerToControl(APoint)
  else
    Result := FImage.BitmapToControl(APoint);
end;

function TBitmap32PaintHost.ViewPortToScreen(const APoint: TPoint): TPoint;
begin
  Result := FImage.ClientToScreen(APoint);
end;

function TBitmap32PaintHost.ScreenToViewPort(const APoint: TPoint): TPoint;
begin
  Result := FImage.ScreenToClient(APoint);
end;

//------------------------------------------------------------------------------

function TBitmap32PaintHost.CreateToolContext(const APaintTool: IBitmap32PaintTool): IBitmap32PaintToolContext;
begin
  if (FPaintLayer <> nil) then
    Result := TBitmap32PaintToolContext.Create(Self, APaintTool, FPaintLayer.Bitmap)
  else
    Result := TBitmap32PaintToolContext.Create(Self, APaintTool, FImage.Bitmap);
end;

//------------------------------------------------------------------------------

function TBitmap32PaintHost.GetMagnification: Single;
begin
  Result := FImage.Scale;
end;

procedure TBitmap32PaintHost.SetMagnification(const Value: Single);
begin
  FImage.Scale := Value;
end;

//------------------------------------------------------------------------------

function TBitmap32PaintHost.GetToolSettings(const AToolKey: string): ISettingValues;
begin
  // Not implemented in this example (yet)
  Result := nil;
end;

procedure TBitmap32PaintHost.Changed(const Action: string);
begin
end;

function TBitmap32PaintHost.SetToolVectorCursor(const Polygon: TArrayOfFixedPoint; HotspotX, HotspotY: integer;
  Color: TColor32; const OutlinePattern: TArrayOfColor32): boolean;
begin
  // Not implemented in this example (yet)
  Result := False;
(*
  if (FCursorLayer = nil) then
    FCursorLayer := TCursorLayer.Create(Self);

  TCursorLayer(FCursorLayer).Polygon := Polygon;
  TCursorLayer(FCursorLayer).Hotspot := Types.Point(HotspotX, HotspotY);
  TCursorLayer(FCursorLayer).Color := Color;
  TCursorLayer(FCursorLayer).OutlinePattern := OutlinePattern;

  ShowCursor(True);
*)
end;

//------------------------------------------------------------------------------

end.
