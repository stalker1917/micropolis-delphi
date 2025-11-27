// This file is part of MicropolisJ.
// Copyright (C) 2013 Jason Long
// Portions Copyright (C) 1989-2007 Electronic Arts Inc.
//
// MicropolisJ is free software; you can redistribute it and/or modify
// it under the terms of the GNU GPLv3, with additional terms.
// See the README file, included in this distribution, for details.

unit ToolPreview;

interface

uses
  SysUtils,
  Classes,
  Generics.Collections,
  TileConstants, // for CLEAR constant, adjust as needed
  Sound,         // for TSound, adjust as needed
  ToolResult,    // for TToolResult, adjust as needed
  CityRect;      // for TCityRect, adjust as needed

type
  TSoundInfo = record
    X, Y: Integer;
    Sound: TSound;
    constructor Create(AX, AY: Integer; ASound: TSound);
  end;

  TToolPreview = class
  private
    FOffsetX: Integer;
    FOffsetY: Integer;
    FTiles: TArray<TArray<SmallInt>>;
    FCost: Integer;
    FToolResult: TToolResult;
    FSounds: TList<TSoundInfo>;


    function InRange(dx, dy: Integer): Boolean;
    procedure ExpandTo(dx, dy: Integer);

  public
    constructor Create;
    destructor Destroy; override;

    function GetTile(dx, dy: Integer): Integer;
    function GetBounds: TCityRect;

    procedure MakeSound(dx, dy: Integer; sound: TSound);
    procedure SetTile(dx, dy: Integer; tileValue: Integer);
    procedure Spend(amount: Integer);
    procedure ToolResult(tr: TToolResult);

    function GetWidth: Integer;
    function GetHeight: Integer;

    property OffsetX: Integer read FOffsetX write FOffsetX;
    property OffsetY: Integer read FOffsetY write FOffsetY;
    property Tiles: TArray<TArray<SmallInt>> read FTiles write FTiles;
    property Cost: Integer read FCost write FCost;
    property ToolResultValue: TToolResult read FToolResult write FToolResult;
    property Sounds: TList<TSoundInfo> read FSounds;


  end;

implementation

{ TSoundInfo }

constructor TSoundInfo.Create(AX, AY: Integer; ASound: TSound);
begin
  X := AX;
  Y := AY;
  Sound := ASound;
end;

{ TToolPreview }

constructor TToolPreview.Create;
begin
  inherited Create;
  SetLength(FTiles, 0);
  FSounds := TList<TSoundInfo>.Create;//  (True);
  FToolResult := TToolResult.trNone;
  FCost := 0;
  FOffsetX := 0;
  FOffsetY := 0;
end;

destructor TToolPreview.Destroy;
begin
  FSounds.Free;
  inherited Destroy;
end;

function TToolPreview.GetTile(dx, dy: Integer): Integer;
begin
  if InRange(dx, dy) then
    Result := FTiles[FOffsetY + dy][FOffsetX + dx]
  else
    Result := CLEAR;
end;

function TToolPreview.GetBounds: TCityRect;
begin
  Result := TCityRect.Create(
    -FOffsetX,
    -FOffsetY,
    GetWidth,
    GetHeight);
end;

function TToolPreview.GetWidth: Integer;
begin
  if Length(FTiles) <> 0 then
    Result := Length(FTiles[0])
  else
    Result := 0;
end;

function TToolPreview.GetHeight: Integer;
begin
  Result := Length(FTiles);
end;

function TToolPreview.InRange(dx, dy: Integer): Boolean;
begin
  Result := (FOffsetY + dy >= 0) and (FOffsetY + dy < GetHeight) and
            (FOffsetX + dx >= 0) and (FOffsetX + dx < GetWidth);
end;

procedure TToolPreview.ExpandTo(dx, dy: Integer);
var
  i, newLen, addl, width, y: Integer;
  AA: TArray<SmallInt>;
  newTiles: TArray<TArray<SmallInt>>;
begin
  if (Length(FTiles) = 0) then
  begin
    SetLength(FTiles, 1);
    SetLength(FTiles[0], 1);
    FTiles[0][0] := CLEAR;
    FOffsetX := -dx;
    FOffsetY := -dy;
    Exit;
  end;

  // Expand each row as needed
  for i := 0 to Length(FTiles) - 1 do
  begin
    AA := FTiles[i];
    if (FOffsetX + dx >= Length(AA)) then
    begin
      newLen := FOffsetX + dx + 1;
      SetLength(AA, newLen);
      for y := Length(AA) - (newLen - Length(AA)) to newLen - 1 do
        AA[y] := CLEAR;
      FTiles[i] := AA;
    end
    else if (FOffsetX + dx < 0) then
    begin
      addl := -(FOffsetX + dx);
      newLen := Length(AA) + addl;
      SetLength(AA, newLen);
      // shift existing data right by addl
      Move(AA[0], AA[addl], (Length(AA) - addl) * SizeOf(SmallInt));
      for y := 0 to addl - 1 do
        AA[y] := CLEAR;
      FTiles[i] := AA;
    end;
  end;

  if FOffsetX + dx < 0 then
    FOffsetX := FOffsetX + (-(FOffsetX + dx));

  width := Length(FTiles[0]);
  if FOffsetY + dy >= Length(FTiles) then
  begin
    newLen := FOffsetY + dy + 1;
    SetLength(newTiles, newLen);
    for i := 0 to Length(FTiles) - 1 do
      newTiles[i] := FTiles[i];
    for i := Length(FTiles) to newLen - 1 do
    begin
      SetLength(newTiles[i], width);
      for y := 0 to width - 1 do
        newTiles[i][y] := CLEAR;
    end;
    FTiles := newTiles;
  end
  else if FOffsetY + dy < 0 then
  begin
    addl := -(FOffsetY + dy);
    newLen := Length(FTiles) + addl;
    SetLength(newTiles, newLen);
    for i := 0 to Length(FTiles) - 1 do
      newTiles[i + addl] := FTiles[i];
    for i := 0 to addl - 1 do
    begin
      SetLength(newTiles[i], width);
      for y := 0 to width - 1 do
        newTiles[i][y] := CLEAR;
    end;
    FTiles := newTiles;
    FOffsetY := FOffsetY + addl;
  end;
end;

procedure TToolPreview.MakeSound(dx, dy: Integer; sound: TSound);
begin
  FSounds.Add(TSoundInfo.Create(dx, dy, sound));
end;

procedure TToolPreview.SetTile(dx, dy: Integer; tileValue: Integer);
begin
  ExpandTo(dx, dy);
  FTiles[FOffsetY + dy][FOffsetX + dx] := SmallInt(tileValue);
end;

procedure TToolPreview.Spend(amount: Integer);
begin
  Inc(FCost, amount);
end;

procedure TToolPreview.ToolResult(tr: TToolResult);
begin
  FToolResult := tr;
end;

end.
