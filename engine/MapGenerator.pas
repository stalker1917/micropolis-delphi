// This file is part of MicropolisJ.
// Copyright (C) 2013 Jason Long
// Portions Copyright (C) 1989-2007 Electronic Arts Inc.
//
// MicropolisJ is free software; you can redistribute it and/or modify
// it under the terms of the GNU GPLv3, with additional terms.
// See the README file, included in this distribution, for details.

unit MapGenerator;

interface

uses
  SysUtils, Classes, MicropolisUnit, TileConstants,JavaRandom,Math,SpriteCity;

const
  // Direction deltas for X and Y coordinates
  DX: array[0..3] of Integer = (-1, 0, 1, 0);
  DY: array[0..3] of Integer = (0, 1, 0, -1);

  // Tile edge table (converted from char to Byte since Delphi doesn't have unsigned char)
  TEdTab: array[0..15] of Byte = (
    0,  0,  0,  34,
    0,  0,  36, 35,
    0,  32, 0,  33,
    30, 31, 29, 37
  );

  REdTab: array[0..15] of Byte = (
    RIVEDGE + 8,  RIVEDGE + 8,  RIVEDGE + 12, RIVEDGE + 10,
    RIVEDGE + 0,  RIVER,        RIVEDGE + 14, RIVEDGE + 12,
    RIVEDGE + 4,  RIVEDGE + 6,  RIVER,        RIVEDGE + 8,
    RIVEDGE + 2,  RIVEDGE + 4,  RIVEDGE + 0,  RIVER
  );

  // BRMatrix - 9x9 array
  BRMatrix: array[0..8, 0..8] of Byte = (
    (0, 0, 0, 3, 3, 3, 0, 0, 0),
    (0, 0, 3, 2, 2, 2, 3, 0, 0),
    (0, 3, 2, 2, 2, 2, 2, 3, 0),
    (3, 2, 2, 2, 2, 2, 2, 2, 3),
    (3, 2, 2, 2, 4, 2, 2, 2, 3),
    (3, 2, 2, 2, 2, 2, 2, 2, 3),
    (0, 3, 2, 2, 2, 2, 2, 3, 0),
    (0, 0, 3, 2, 2, 2, 3, 0, 0),
    (0, 0, 0, 3, 3, 3, 0, 0, 0)
  );

  // SRMatrix - 6x6 array
  SRMatrix: array[0..5, 0..5] of Byte = (
    (0, 0, 3, 3, 0, 0),
    (0, 3, 2, 2, 3, 0),
    (3, 2, 2, 2, 2, 3),
    (3, 2, 2, 2, 2, 3),
    (0, 3, 2, 2, 3, 0),
    (0, 0, 3, 3, 0, 0)
  );

  // 8-direction movement table (X coordinates)
  DIRECTION_TABX: array[0..7] of Integer = (0,  1,  1,  1,  0, -1, -1, -1);

  // 8-direction movement table (Y coordinates)
  DIRECTION_TABY: array[0..7] of Integer = (-1, -1,  0,  1,  1,  1,  0, -1);

type
  TCreateIsland = (ciNever, ciAlways, ciSeldom);

  TMapGenerator = class
  private
    FEngine: TMicropolis;
    FMap: TWord2DArray;
    FPRNG: TRandom;

    FCreateIsland: TCreateIsland;
    FTreeLevel: Integer;
    FCurveLevel: Integer;
    FLakeLevel: Integer;
    xStart: Integer;
	  yStart: Integer;
	  mapX: Integer;
	  mapY: Integer;
	  dir: Integer;
	  lastDir: Integer;


    function GetWidth: Integer;
    function GetHeight: Integer;
    function Erand(Limit: Integer): Integer;
    procedure ClearMap;
    procedure MakeNakedIsland;
    procedure MakeIsland;
    procedure GetRandStart;
    procedure DoRivers;
    procedure MakeLakes;
    procedure SmoothRiver;
    procedure DoTrees;
    procedure doBRiv;
    procedure doSRiv;
    procedure treeSplash(xloc, yloc: Integer);
    procedure moveMap(dir: Integer);
    procedure smoothTrees;
    procedure BRivPlop;
    procedure SRivPlop;
    procedure putOnMap(mapChar: Byte; xoff, yoff: Integer);

  public
    constructor Create(Engine: TMicropolis);
    procedure GenerateNewCity;
    procedure GenerateSomeCity(R: Int64);
    procedure GenerateMap(R: Int64);
  end;




implementation

constructor TMapGenerator.Create(Engine: TMicropolis);
begin
  Assert(Engine <> nil);
  FEngine := Engine;
  FPRNG := Engine.PRNG;
  FMap := Engine.Map;
  FCreateIsland := ciSeldom;
  FTreeLevel := -1;
  FCurveLevel := -1;
  FLakeLevel := -1;
end;

function TMapGenerator.GetWidth: Integer;
begin
  Result := Length(FMap[0]);
end;

function TMapGenerator.GetHeight: Integer;
begin
  Result := Length(FMap);
end;

procedure TMapGenerator.GenerateNewCity;
var
  R: Int64;
begin
  R := FEngine.PRNG.RInt64;
  GenerateSomeCity(R);
end;

procedure TMapGenerator.GenerateSomeCity(R: Int64);
begin
  GenerateMap(R);
  FEngine.FireWholeMapChanged;
end;

procedure TMapGenerator.GenerateMap(R: Int64);
begin
  FPRNG := FEngine.PRNG;//TRandom.Create(R);

  if FCreateIsland = ciSeldom then
  begin
    if FPRNG.NextInt(100) < 10 then
    begin
      MakeIsland;
      Exit;
    end;
  end;

  if FCreateIsland = ciAlways then
    MakeNakedIsland
  else
    ClearMap;

  GetRandStart;

  if FCurveLevel <> 0 then
    DoRivers;

  if FLakeLevel <> 0 then
    MakeLakes;

  SmoothRiver;

  if FTreeLevel <> 0 then
    DoTrees;
end;

function TMapGenerator.Erand(Limit: Integer): Integer;
begin
  Result := Min(FPRNG.NextInt(Limit), FPRNG.NextInt(Limit));
end;

procedure TMapGenerator.MakeIsland;
begin
  MakeNakedIsland;
  SmoothRiver;
  DoTrees;
end;

procedure TMapGenerator.MakeNakedIsland;
const
  ISLAND_RADIUS = 18;
var
  x, y: Integer;
  WorldX, WorldY: Integer;
begin
  WorldX := GetWidth;
  WorldY := GetHeight;

  for y := 0 to WorldY - 1 do
    for x := 0 to WorldX - 1 do
      FMap[y][x] := RIVER;

  for y := 5 to WorldY - 6 do
    for x := 5 to WorldX - 6 do
      FMap[y][x] := DIRT;

  for x := 0 to WorldX - 6 do
  begin
    // Placeholder for mapX/Y + BRivPlop + SRivPlop methods
  end;
end;

// Placeholder implementations
procedure TMapGenerator.ClearMap;
var
  x, y: Integer;
begin
  for y := 0 to GetHeight - 1 do
    for x := 0 to GetWidth - 1 do
      FMap[y][x] := 0;
end;

procedure TMapGenerator.getRandStart;
begin
  xStart := 40 + FPRNG.NextInt(getWidth - 79);
  yStart := 33 + FPRNG.NextInt(getHeight - 66);

  mapX := xStart;
  mapY := yStart;
end;

procedure TMapGenerator.makeLakes;
var
  lim1, t, x, y, lim2, z: Integer;
begin
  if FlakeLevel < 0 then
    lim1 := FPRNG.NextInt(11)
  else
    lim1 := FlakeLevel div 2;

  for t := 0 to lim1 - 1 do
  begin
    x := FPRNG.NextInt(getWidth - 20) + 10;
    y := FPRNG.NextInt(getHeight - 19) + 10;
    lim2 := FPRNG.NextInt(13) + 2;

    for z := 0 to lim2 - 1 do
    begin
      mapX := x - 6 + FPRNG.NextInt(13);
      mapY := y - 6 + FPRNG.NextInt(13);

      if FPRNG.NextInt(5) <> 0 then
        SRivPlop
      else
        BRivPlop;
    end;
  end;
end;

procedure TMapGenerator.doRivers;
begin
  dir := FPRNG.NextInt(4);
  lastDir := dir;
  doBRiv;

  mapX := xStart;
  mapY := yStart;
  dir := lastDir xor 4;
  lastDir := dir;
  doBRiv;

  mapX := xStart;
  mapY := yStart;
  lastDir := FPRNG.NextInt(4);
  doSRiv;
end;

procedure TMapGenerator.doBRiv;
var
  r1, r2: Integer;
begin
  if FcurveLevel < 0 then
  begin
    r1 := 100;
    r2 := 200;
  end
  else
  begin
    r1 := FcurveLevel + 10;
    r2 := FcurveLevel + 100;
  end;

  while Fengine.testBounds(mapX + 4, mapY + 4) do
  begin
    BRivPlop;

    if FPRNG.NextInt(r1 + 1) < 10 then
      dir := lastDir
    else
    begin
      if FPRNG.NextInt(r2 + 1) > 90 then
        Inc(dir);
      if FPRNG.NextInt(r2 + 1) > 90 then
        Dec(dir);
    end;

    moveMap(dir);
  end;
end;

procedure TMapGenerator.doSRiv;
var
  r1, r2: Integer;
begin
  if FcurveLevel < 0 then
  begin
    r1 := 100;
    r2 := 200;
  end
  else
  begin
    r1 := FcurveLevel + 10;
    r2 := FcurveLevel + 100;
  end;

  while Fengine.testBounds(mapX + 3, mapY + 3) do
  begin
    SRivPlop;

    if FPRNG.NextInt(r1 + 1) < 10 then
      dir := lastDir
    else
    begin
      if FPRNG.NextInt(r2 + 1) > 90 then
        Inc(dir);
      if FPRNG.NextInt(r2 + 1) > 90 then
        Dec(dir);
    end;

    moveMap(dir);
  end;
end;

procedure TMapGenerator.BRivPlop;
var
  x, y: Integer;
begin
  for x := 0 to 8 do
    for y := 0 to 8 do
      putOnMap(BRMatrix[y, x], x, y);
end;

procedure TMapGenerator.SRivPlop;
var
  x, y: Integer;
begin
  for x := 0 to 5 do
    for y := 0 to 5 do
      putOnMap(SRMatrix[y, x], x, y);
end;

procedure TMapGenerator.putOnMap(mapChar: Byte; xoff, yoff: Integer);
var
  xloc, yloc: Integer;
  tmp: byte;
begin
  if mapChar = 0 then Exit;

  xloc := mapX + xoff;
  yloc := mapY + yoff;

  if not Fengine.testBounds(xloc, yloc) then Exit;

  tmp := Fmap[yloc][xloc];
  if tmp <> DIRT then
  begin
    tmp := (tmp) and LOMASK;
    if (tmp = RIVER) and (mapChar <> CHANNEL) then Exit;
    if tmp = CHANNEL then Exit;
  end;

  Fmap[yloc][xloc] := mapChar;
end;

procedure TMapGenerator.smoothRiver;
var
  mapX, mapY, z, xtem, ytem, bitindex: Integer;
  temp: Byte;
begin
  for mapY := 0 to High(Fmap) do
    for mapX := 0 to High(Fmap[mapY]) do
      if Fmap[mapY][mapX] = REDGE then
      begin
        bitindex := 0;

        for z := 0 to 3 do
        begin
          bitindex := bitindex shl 1;
          xtem := mapX + DX[z];
          ytem := mapY + DY[z];

          if Fengine.testBounds(xtem, ytem) and
            ((Ord(Fmap[ytem][xtem]) and LOMASK) <> DIRT) and
            ((Ord(Fmap[ytem][xtem]) and LOMASK < WOODS_LOW) or
             (Ord(Fmap[ytem][xtem]) and LOMASK > WOODS_HIGH)) then
          begin
            bitindex := bitindex or 1;
          end;
        end;

        temp := REdTab[bitindex and 15];
        if (temp <> RIVER) and (FPRNG.NextInt(2) <> 0) then
          Inc(temp);

        Fmap[mapY][mapX] := temp;
      end;
end;

procedure TMapGenerator.doTrees;
var
  amount, x, xloc, yloc: Integer;
begin
  if FtreeLevel < 0 then
    amount := FPRNG.NextInt(101) + 50
  else
    amount := FtreeLevel + 3;

  for x := 0 to amount - 1 do
  begin
    xloc := FPRNG.NextInt(getWidth);
    yloc := FPRNG.NextInt(getHeight);
    treeSplash(xloc, yloc);
  end;

  smoothTrees;
  smoothTrees;
end;

procedure TMapGenerator.treeSplash(xloc, yloc: Integer);
var
  dis, z, dir: Integer;
begin
  if FtreeLevel < 0 then
    dis := FPRNG.NextInt(151) + 50
  else
    dis := FPRNG.NextInt(101 + (FtreeLevel * 2)) + 50;

  mapX := xloc;
  mapY := yloc;

  for z := 0 to dis - 1 do
  begin
    dir := FPRNG.NextInt(8);
    moveMap(dir);

    if not Fengine.testBounds(mapX, mapY) then Exit;

    if (Ord(Fmap[mapY][mapX]) and LOMASK) = DIRT then
      Fmap[mapY][mapX] := WOODS;
  end;
end;

procedure TMapGenerator.moveMap(dir: Integer);
begin
  dir := dir and 7;
  Inc(mapX, DIRECTION_TABX[dir]);
  Inc(mapY, DIRECTION_TABY[dir]);
end;

procedure TMapGenerator.smoothTrees;
var
  mapX, mapY, z, xtem, ytem, bitindex: Integer;
  temp: Byte;
begin
  for mapY := 0 to High(Fmap) do
    for mapX := 0 to High(Fmap[mapY]) do
      if isTree(Fmap[mapY][mapX]) then
      begin
        bitindex := 0;
        for z := 0 to 3 do
        begin
          bitindex := bitindex shl 1;
          xtem := mapX + DX[z];
          ytem := mapY + DY[z];

          if Fengine.testBounds(xtem, ytem) and isTree(Fmap[ytem][xtem]) then
            bitindex := bitindex or 1;
        end;

        temp := TEdTab[bitindex and 15];

        if temp <> 0 then
        begin
          if (temp <> WOODS) and (((mapX + mapY) and 1) <> 0) then
            Dec(temp, 8);

          Fmap[mapY][mapX] := temp;
        end
        else
          Fmap[mapY][mapX] := temp;
      end;
end;

end.