unit GR32_PortableNetworkGraphic.Chunks;

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
 * The Original Code is GR32PNG for Graphics32
 *
 * The Initial Developer of the Original Code is
 * Christian-W. Budde
 *
 * Portions created by the Initial Developer are Copyright (C) 2000-2009
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *
 * ***** END LICENSE BLOCK ***** *)

interface

{$include GR32.inc}
{$include GR32_PngCompilerSwitches.inc}

// The following defines controls if the corresponding incomplete chunk
// implementations should be enabled. They are disabled by default because
// a complete implementation is required in order to pass the roundtrip unit
// tests.
{-$define PNG_CHUNK_SUGGESTED_PALETTE}
{-$define PNG_CHUNK_INTERNATIONAL_TEXT}

uses
  Generics.Collections,
  Classes, Graphics, SysUtils,
  GR32_PortableNetworkGraphic.Types;

type
  TChunkName = array [0..3] of AnsiChar;

//------------------------------------------------------------------------------
//
//      Chunk base classes
//
//------------------------------------------------------------------------------
type
  TCustomChunk = class;

  IChunkOwner = interface
    procedure AddChunk(AChunk: TCustomChunk);
    procedure RemoveChunk(AChunk: TCustomChunk);
  end;

  TCustomChunk = class abstract(TPersistent)
  private
    FOwner: IChunkOwner;
  protected
    procedure SetOwner(const AOwner: IChunkOwner);

    function GetChunkNameAsString: AnsiString; virtual; abstract;
    function GetChunkName: TChunkName; virtual; abstract;
    function GetChunkSize: Cardinal; virtual; abstract;
    function GetChunkData: pointer; virtual;

    property Owner: IChunkOwner read FOwner write SetOwner;
  public
    destructor Destroy; override;

    procedure Assign(Source: TPersistent); override;

    procedure ReadFromStream(Stream: TStream; ChunkSize: Cardinal); virtual; abstract;
    procedure WriteToStream(Stream: TStream); virtual; abstract;

    property ChunkName: TChunkName read GetChunkName;
    property ChunkNameAsString: AnsiString read GetChunkNameAsString;
    property ChunkSize: Cardinal read GetChunkSize;
    property ChunkData: pointer read GetChunkData;
  end;

  TCustomChunkClass = class of TCustomChunk;

type
  TCustomDefinedChunk = class abstract(TCustomChunk)
  protected
    function GetChunkNameAsString: AnsiString; override;
    function GetChunkName: TChunkName; override;
    class function GetClassChunkName: TChunkName; virtual; abstract;
  public
    property ChunkName: TChunkName read GetClassChunkName;
  end;

  TCustomDefinedChunkClass = class of TCustomDefinedChunk;

  TPngChunkImageHeader = class;

  TCustomDefinedChunkWithHeader = class(TCustomDefinedChunk)
  protected
    FHeader : TPngChunkImageHeader;

  public
    constructor Create(Header: TPngChunkImageHeader); reintroduce; virtual;

    procedure Assign(Source: TPersistent); override;
    procedure HeaderChanged; virtual;

    property Header: TPngChunkImageHeader read FHeader;
  end;

  TCustomDefinedChunkWithHeaderClass = class of TCustomDefinedChunkWithHeader;


//------------------------------------------------------------------------------
//
//      TPngChunkImageHeader
//
//------------------------------------------------------------------------------
  TPngChunkImageHeader = class(TCustomDefinedChunk)
  private
    FWidth                 : Integer;
    FHeight                : Integer;
    FBitDepth              : Byte;
    FColorType             : TColorType;
    FCompressionMethod     : Byte;
    FFilterMethod          : TFilterMethod;
    FInterlaceMethod       : TInterlaceMethod;
    FAdaptiveFilterMethods : TAvailableAdaptiveFilterMethods;
    function GetHasPalette: Boolean;
    function GetBytesPerRow: Integer;
    function GetPixelByteSize: Integer;
    procedure SetCompressionMethod(const Value: Byte);
    procedure SetFilterMethod(const Value: TFilterMethod);
    procedure SetAdaptiveFilterMethods(const Value: TAvailableAdaptiveFilterMethods);
  protected
    class function GetClassChunkName: TChunkName; override;
    function GetChunkSize: Cardinal; override;

  public
    constructor Create; virtual;

    procedure Assign(Source: TPersistent); override;
    procedure ReadFromStream(Stream: TStream; ChunkSize: Cardinal); override;
    procedure WriteToStream(Stream: TStream); override;

    procedure ResetToDefault; virtual;

    property Width: Integer read FWidth write FWidth;
    property Height: Integer read FHeight write FHeight;
    property BitDepth: Byte read FBitDepth write FBitDepth;
    property ColorType: TColorType read FColorType write FColorType;
    property CompressionMethod: Byte read FCompressionMethod write SetCompressionMethod;
    property AdaptiveFilterMethods: TAvailableAdaptiveFilterMethods read FAdaptiveFilterMethods write SetAdaptiveFilterMethods;
    property FilterMethod: TFilterMethod read FFilterMethod write SetFilterMethod;
    property InterlaceMethod: TInterlaceMethod read FInterlaceMethod write FInterlaceMethod;
    property HasPalette: Boolean read GetHasPalette;

    property BytesPerRow: Integer read GetBytesPerRow;
    property PixelByteSize: Integer read GetPixelByteSize;
  end;


//------------------------------------------------------------------------------
//
//      Chunk lists
//
//------------------------------------------------------------------------------
type
  TCustomChunkList<T: TCustomChunk> = class(TObject, IChunkOwner)
  private
    FHeader: TPngChunkImageHeader;
    FChunks: TObjectList<T>;
  protected
    function AddClone(AChunk: TCustomChunk): TCustomChunk; virtual;
  private
{$IFDEF FPC_HAS_CONSTREF}
    function QueryInterface(constref iid: TGuid; out obj): HResult; {$ifdef MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
    function _AddRef: LongInt; {$ifdef MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
    function _Release: LongInt; {$ifdef MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
{$ELSE}
    function QueryInterface(const iid: TGuid; out obj): HResult; stdcall;
    function _AddRef: LongInt; stdcall;
    function _Release: LongInt; stdcall;
{$ENDIF}
  private
    function GetChunk(Index: integer): T;
    function GetCount: integer;
  private
    // IChunkOwner
    procedure AddChunk(AChunk: TCustomChunk);
    procedure RemoveChunk(AChunk: TCustomChunk);
  public
    constructor Create(AHeader: TPngChunkImageHeader);
    destructor Destroy; override;

    procedure Assign(Source: TCustomChunkList<T>);
    procedure Add(AChunk: T);
    procedure Clear;

    property Header: TPngChunkImageHeader read FHeader;

    property Chunks[Index: integer]: T read GetChunk; default;
    property Count: integer read GetCount;

    function GetEnumerator: TEnumerator<T>;
  end;

  TChunkList = class(TCustomChunkList<TCustomChunk>)
  protected
    function AddClone(AChunk: TCustomChunk): TCustomChunk; override;
  public
    function Add(const AChunkName: TChunkName): TCustomChunk; overload;
  end;

type
  TCustomDefinedChunkWithHeaderList<T: TCustomDefinedChunkWithHeader> = class(TCustomChunkList<T>)
  protected
    function AddClone(AChunk: TCustomChunk): TCustomChunk; override;
  public
    function Add(AChunkClass: TCustomDefinedChunkWithHeaderClass): T; overload;
{$if defined(GENERIC_FUNCTION_CLASS)}
    function Add<TT: TCustomDefinedChunkWithHeader>: TT; overload;
{$ifend}
  end;

  TDefinedChunkWithHeaderList = TCustomDefinedChunkWithHeaderList<TCustomDefinedChunkWithHeader>;


//------------------------------------------------------------------------------
//
//      Chunk registration
//
//------------------------------------------------------------------------------
procedure RegisterPngChunk(ChunkClass: TCustomDefinedChunkWithHeaderClass);
procedure RegisterPngChunks(ChunkClasses: array of TCustomDefinedChunkWithHeaderClass);
function FindPngChunkByChunkName(const ChunkName: TChunkName): TCustomDefinedChunkWithHeaderClass;
function IsPngChunkRegistered(AChunkClass: TCustomDefinedChunkWithHeaderClass): Boolean;

var
  GPngChunkClasses: array of TCustomDefinedChunkWithHeaderClass;


//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

implementation

uses
  GR32.BigEndian,
  GR32_PortableNetworkGraphic.Chunks.Unknown;

//------------------------------------------------------------------------------
//
//      Chunk registration
//
//------------------------------------------------------------------------------
function IsPngChunkRegistered(AChunkClass: TCustomDefinedChunkWithHeaderClass): Boolean;
var
  ChunkClass: TCustomDefinedChunkWithHeaderClass;
begin
  for ChunkClass in GPngChunkClasses do
    if ChunkClass = AChunkClass then
      Exit(True);
  Result := False;
end;

procedure RegisterPngChunk(ChunkClass: TCustomDefinedChunkWithHeaderClass);
begin
  Assert(not IsPngChunkRegistered(ChunkClass), 'PNG chunk already registered');

  SetLength(GPngChunkClasses, Length(GPngChunkClasses) + 1);
  GPngChunkClasses[High(GPngChunkClasses)] := ChunkClass;
end;

procedure RegisterPngChunks(ChunkClasses: array of TCustomDefinedChunkWithHeaderClass);
var
  ChunkClass: TCustomDefinedChunkWithHeaderClass;
begin
  for ChunkClass in ChunkClasses do
    RegisterPngChunk(ChunkClass);
end;

function FindPngChunkByChunkName(const ChunkName: TChunkName): TCustomDefinedChunkWithHeaderClass;
var
  ChunkClass: TCustomDefinedChunkWithHeaderClass;
begin
  for ChunkClass in GPngChunkClasses do
    if ChunkClass.GetClassChunkName = ChunkName then
      Exit(ChunkClass);
  Result := nil;
end;


//------------------------------------------------------------------------------
//
//      TCustomChunkList<T>
//
//------------------------------------------------------------------------------
constructor TCustomChunkList<T>.Create(AHeader: TPngChunkImageHeader);
begin
  inherited Create;
  FHeader := AHeader;
  FChunks := TObjectList<T>.Create;
end;

destructor TCustomChunkList<T>.Destroy;
begin
  FChunks.Free;

  inherited;
end;

procedure TCustomChunkList<T>.Clear;
begin
  FChunks.Clear;
end;

function TCustomChunkList<T>.GetChunk(Index: integer): T;
begin
  Result := FChunks[Index];
end;

function TCustomChunkList<T>.GetCount: integer;
begin
  Result := FChunks.Count;
end;

function TCustomChunkList<T>.GetEnumerator: TEnumerator<T>;
begin
  Result := FChunks.GetEnumerator;
end;

function TCustomChunkList<T>.QueryInterface(
  {$IFDEF FPC_HAS_CONSTREF}constref{$ELSE}const{$ENDIF}IID: TGUID; out Obj): HResult;
const
  E_NOINTERFACE = HResult($80004002);
begin
  if GetInterface(IID, Obj) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;

procedure TCustomChunkList<T>.Add(AChunk: T);
begin
  FChunks.Add(AChunk);
  AChunk.Owner := Self;
end;

procedure TCustomChunkList<T>.AddChunk(AChunk: TCustomChunk);
begin
  if (not FChunks.Contains(AChunk as T)) then
    Add(T(AChunk));
end;

procedure TCustomChunkList<T>.RemoveChunk(AChunk: TCustomChunk);
begin
  if (FChunks.Contains(AChunk as T)) then
  begin
    FChunks.Extract(T(AChunk));
    AChunk.Owner := nil;
  end;
end;

function TCustomChunkList<T>._AddRef: Integer;
begin
  Result := -1;
end;

function TCustomChunkList<T>._Release: Integer;
begin
  Result := -1;
end;

function TCustomChunkList<T>.AddClone(AChunk: TCustomChunk): TCustomChunk;
begin
  raise EPngError.CreateFmt('Unable to clone PNG chunk: %s', [AChunk.ClassName]);
end;

procedure TCustomChunkList<T>.Assign(Source: TCustomChunkList<T>);
var
  Chunk: TCustomChunk;
  NewChunk: TCustomChunk;
begin
  FChunks.Clear;
  FChunks.Capacity := Source.Count;

  for Chunk in Source do
  begin
    NewChunk := AddClone(Chunk);
    NewChunk.Assign(Chunk);
  end;
end;


//------------------------------------------------------------------------------
//
//      TChunkList
//
//------------------------------------------------------------------------------
function TChunkList.Add(const AChunkName: TChunkName): TCustomChunk;
begin
  Result := TPngChunkUnknown.Create(AChunkName);
  Add(Result);
end;

function TChunkList.AddClone(AChunk: TCustomChunk): TCustomChunk;
begin
  if (AChunk is TPngChunkUnknown) then
    Result := Add(TPngChunkUnknown(AChunk).ChunkName)
  else
    Result := inherited;
end;

//------------------------------------------------------------------------------
//
//      TCustomDefinedChunkWithHeaderList<T>
//
//------------------------------------------------------------------------------
function TCustomDefinedChunkWithHeaderList<T>.Add(AChunkClass: TCustomDefinedChunkWithHeaderClass): T;
begin
  Result := T(AChunkClass.Create(Header));
  Add(Result);
end;

{$if defined(GENERIC_FUNCTION_CLASS)}
function TCustomDefinedChunkWithHeaderList<T>.Add<TT>: TT;
begin
  Result := TT.Create(Header);

  // "TT" is "class of T", so the result of "TT.Create" is "T"
  // The compiler can't figure that out so we have to cheat and
  // cast to pointer to T

  Add(T(pointer(Result)));
end;
{$ifend}

function TCustomDefinedChunkWithHeaderList<T>.AddClone(AChunk: TCustomChunk): TCustomChunk;
begin
  if (AChunk is TCustomDefinedChunkWithHeader) then
    Result := Add(TCustomDefinedChunkWithHeaderClass(AChunk.ClassType))
  else
    Result := inherited;
end;



procedure TCustomChunk.Assign(Source: TPersistent);
begin
  // This makes it safe to call "inherited" on all derived classes
  if not(Source is TCustomChunk) then
    inherited;
end;

//------------------------------------------------------------------------------
//
//      TCustomChunk
//
//------------------------------------------------------------------------------
destructor TCustomChunk.Destroy;
begin
  Owner := nil;
  inherited;
end;

function TCustomChunk.GetChunkData: pointer;
begin
  Result := nil;
end;

procedure TCustomChunk.SetOwner(const AOwner: IChunkOwner);
begin
  if (FOwner = AOwner) then
    exit;

  if (FOwner <> nil) then
    FOwner.RemoveChunk(Self);

  FOwner := AOwner;

  if (FOwner <> nil) then
    FOwner.AddChunk(Self);
end;


//------------------------------------------------------------------------------
//
//      TCustomDefinedChunk
//
//------------------------------------------------------------------------------
function TCustomDefinedChunk.GetChunkName: TChunkName;
begin
  Result := GetClassChunkName;
end;

function TCustomDefinedChunk.GetChunkNameAsString: AnsiString;
begin
  Result := AnsiString(GetClassChunkName);
end;


//------------------------------------------------------------------------------
//
//      TCustomDefinedChunkWithHeader
//
//------------------------------------------------------------------------------
constructor TCustomDefinedChunkWithHeader.Create(Header: TPngChunkImageHeader);
begin
  if not (Header is TPngChunkImageHeader) then
    raise EPngError.Create(RCStrHeaderInvalid);

  FHeader := Header;
  inherited Create;
end;

procedure TCustomDefinedChunkWithHeader.Assign(Source: TPersistent);
begin
  inherited;

  if (Source is TCustomDefinedChunkWithHeader) then
    FHeader.Assign(TCustomDefinedChunkWithHeader(Source).Header);
end;

procedure TCustomDefinedChunkWithHeader.HeaderChanged;
begin
 // purely virtual, do nothing by default
end;


//------------------------------------------------------------------------------
//
//      TPngChunkImageHeader
//
//------------------------------------------------------------------------------
constructor TPngChunkImageHeader.Create;
begin
  inherited;
  FAdaptiveFilterMethods := [aafmSub, aafmUp, aafmAverage, aafmPaeth];

  ResetToDefault;
end;

procedure TPngChunkImageHeader.Assign(Source: TPersistent);
begin
  inherited;

  if (Source is TPngChunkImageHeader) then
  begin
    FWidth                 := TPngChunkImageHeader(Source).Width;
    FHeight                := TPngChunkImageHeader(Source).Height;
    FBitDepth              := TPngChunkImageHeader(Source).BitDepth;
    FColorType             := TPngChunkImageHeader(Source).ColorType;
    FCompressionMethod     := TPngChunkImageHeader(Source).CompressionMethod;
    FFilterMethod          := TPngChunkImageHeader(Source).FilterMethod;
    FInterlaceMethod       := TPngChunkImageHeader(Source).InterlaceMethod;
    FAdaptiveFilterMethods := TPngChunkImageHeader(Source).AdaptiveFilterMethods;
  end;
end;

function TPngChunkImageHeader.GetBytesPerRow: Integer;
begin
  case FColorType of
    ctGrayscale,
    ctIndexedColor:
      Result := ((FWidth * FBitDepth + $7) and not $7) shr 3;

    ctGrayscaleAlpha:
      Result := 2 * (FBitDepth shr 3) * FWidth;

    ctTrueColor:
      Result := 3 * (FBitDepth shr 3) * FWidth;

    ctTrueColorAlpha:
      Result := 4 * (FBitDepth shr 3) * FWidth;
  else
    raise EPngError.Create(RCStrUnknownColorType);
  end;
end;

class function TPngChunkImageHeader.GetClassChunkName: TChunkName;
begin
  Result := 'IHDR';
end;

function TPngChunkImageHeader.GetChunkSize: Cardinal;
begin
  Result := 13;
end;

procedure TPngChunkImageHeader.ReadFromStream(Stream: TStream; ChunkSize: Cardinal);
begin
  if (Stream.Position+ChunkSize > Stream.Size) or (GetChunkSize > ChunkSize) then
    raise EPngError.Create(RCStrChunkSizeTooSmall);

  // read width
  FWidth := BigEndian.ReadCardinal(Stream);

  // read height
  FHeight := BigEndian.ReadCardinal(Stream);

  // read bit depth
  Stream.Read(FBitDepth, 1);

  // read Color type
  Stream.Read(FColorType, 1);

  // check consistency between Color type and bit depth
  case FColorType of
    ctGrayscale:
      if not (FBitDepth in [1, 2, 4, 8, 16]) then
        raise EPngError.Create(RCStrWrongBitdepth);

    ctTrueColor,
    ctGrayscaleAlpha,
    ctTrueColorAlpha:
      if not (FBitDepth in [8, 16]) then
        raise EPngError.Create(RCStrWrongBitdepth);

    ctIndexedColor:
      if not (FBitDepth in [1, 2, 4, 8]) then
        raise EPngError.Create(RCStrWrongBitdepth);
  else
    raise EPngError.Create(RCStrUnsupportedColorType);
  end;

  // read compression method
  Stream.Read(FCompressionMethod, 1);

  // check for compression method
  if FCompressionMethod <> 0 then
    raise EPngError.Create(RCStrUnsupportedCompressMethod);

  // read filter method
  Stream.Read(FFilterMethod, 1);

  // check for filter method
  if FFilterMethod <> fmAdaptiveFilter then
    raise EPngError.Create(RCStrUnsupportedFilterMethod);

  // read interlace method
  Stream.Read(FInterlaceMethod, 1);

  // check for interlace method
  if not (FInterlaceMethod in [imNone, imAdam7]) then
    raise EPngError.Create(RCStrUnsupportedInterlaceMethod);
end;

procedure TPngChunkImageHeader.WriteToStream(Stream: TStream);
begin
  // write width
  BigEndian.WriteCardinal(Stream, FWidth);

  // write height
  BigEndian.WriteCardinal(Stream, FHeight);

  // write bit depth
  Stream.Write(FBitDepth, 1);

  // write Color type
  Stream.Write(FColorType, 1);

  // write compression method
  Stream.Write(FCompressionMethod, 1);

  // write filter method
  Stream.Write(FFilterMethod, 1);

  // write interlace method
  Stream.Write(FInterlaceMethod, 1);
end;

function TPngChunkImageHeader.GetPixelByteSize: Integer;
begin
  case ColorType of
    ctGrayscale:
      if FBitDepth = 16 then
        Result := 2
      else
        Result := 1;

    ctTrueColor:
      Result := 3 * FBitDepth div 8;

    ctIndexedColor:
      Result := 1;

    ctGrayscaleAlpha:
      Result := 2 * FBitDepth div 8;

    ctTrueColorAlpha:
      Result := 4 * FBitDepth div 8;
  else
    Result := 0;
  end;
end;

function TPngChunkImageHeader.GetHasPalette: Boolean;
begin
  Result := FColorType in [ctIndexedColor];
end;

procedure TPngChunkImageHeader.ResetToDefault;
begin
  FWidth             := 0;
  FHeight            := 0;
  FBitDepth          := 8;
  FColorType         := ctTrueColor;
  FCompressionMethod := 0;
  FFilterMethod      := fmAdaptiveFilter;
  FInterlaceMethod   := imNone;
end;

procedure TPngChunkImageHeader.SetAdaptiveFilterMethods(const Value: TAvailableAdaptiveFilterMethods);
begin
  FAdaptiveFilterMethods := Value;
end;

procedure TPngChunkImageHeader.SetCompressionMethod(const Value: Byte);
begin
  // check for compression method
  if Value <> 0 then
    raise EPngError.Create(RCStrUnsupportedCompressMethod);
end;

procedure TPngChunkImageHeader.SetFilterMethod(const Value: TFilterMethod);
begin
  // check for filter method
  if Value <> fmAdaptiveFilter then
    raise EPngError.Create(RCStrUnsupportedFilterMethod);
end;



end.
