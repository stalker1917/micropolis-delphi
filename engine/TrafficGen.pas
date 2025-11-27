// This file is part of MicropolisJ.
// Copyright (C) 2013 Jason Long
// Portions Copyright (C) 1989-2007 Electronic Arts Inc.
//
// MicropolisJ is free software; you can redistribute it and/or modify
// it under the terms of the GNU GPLv3, with additional terms.
// See the README file, included in this distribution, for details.

Unit TrafficGen;
interface 

{
 * Contains the code for generating city traffic.
}
uses
  System.Generics.Collections, System.SysUtils,SpriteCity,CityLocation,
  TileConstants,TerrainBehavior,SpriteKind,HelicopterSprite;

type
  TTrafficCity = class;
  TZoneType = (ztResidential, ztCommercial, ztIndustrial);

  TTrafficGen = class
  private
    const
      MAX_TRAFFIC_DISTANCE = 30;
      PerimX: array[0..11] of Integer = (-1, 0, 1, 2, 2, 2, 1, 0, -1, -2, -2, -2);
      PerimY: array[0..11] of Integer = (-2, -2, -2, -1, 0, 1, 2, 2, 2, 1, 0, -1);
      DX: array[0..3] of Integer = (0, 1, 0, -1);
      DY: array[0..3] of Integer = (-1, 0, 1, 0);
  private
    city: TTrafficCity;
    lastdir: Integer;
    positions: TStack<TCityLocation>;
  public
    mapX, mapY: Integer;
    sourceZone: TZoneType;
    constructor Create(aCity: TTrafficCity);
    destructor Destroy; override;

    function MakeTraffic: Integer;
    procedure SetTrafficMem;
    function FindPerimeterRoad: Boolean;
    function RoadTest(tx, ty: Integer): Boolean;
    function TryDrive: Boolean;
    function TryGo(z: Integer): Boolean;
    function DriveDone: Boolean;
    function GetCity:TSpriteCity;

    //property City: TSpriteCity read city;
    //property MapX: Integer read mapX write mapX;
    //property MapY: Integer read mapY write mapY;
    //property SourceZone: TZoneType read sourceZone write sourceZone;
  end;

  TTrafficCity = class(TTerrainCity)
    trafficMaxLocationX: Integer;
    trafficMaxLocationY: Integer;
    constructor Create;
    procedure AddTraffic(MapX, MapY, Traffic: Integer);
  end;


implementation


constructor TTrafficGen.Create(aCity: TTrafficCity);
begin
  inherited Create;
  city := aCity;
  positions := TStack<TCityLocation>.Create;
end;


destructor TTrafficGen.Destroy;
begin
  positions.Free;
  inherited;
end;

function TTrafficGen.GetCity: TSpriteCity;
begin
  Result:=City;
end;

function TTrafficGen.MakeTraffic: Integer;
begin
  if FindPerimeterRoad then
  begin
    if TryDrive then
    begin
      SetTrafficMem;
      Result := 1;
      Exit;
    end;
    Result := 0;
    Exit;
  end
  else
    Result := -1;
end;

procedure TTrafficGen.SetTrafficMem;
var
  pos: TCityLocation;
  tile: Integer;
begin
  while positions.Count > 0 do
  begin
    pos := positions.Pop;
    mapX := pos.X;
    mapY := pos.Y;
    Assert(city.TestBounds(mapX, mapY));

    tile := city.GetTile(mapX, mapY);
    if (tile >= ROADBASE) and (tile < POWERBASE) then
      city.AddTraffic(mapX, mapY, 50);
  end;
end;

function TTrafficGen.FindPerimeterRoad: Boolean;
var
  z, tx, ty: Integer;
begin
  for z := 0 to 11 do
  begin
    tx := mapX + PerimX[z];
    ty := mapY + PerimY[z];
    if RoadTest(tx, ty) then
    begin
      mapX := tx;
      mapY := ty;
      Exit(True);
    end;
  end;
  Result := False;
end;

function TTrafficGen.RoadTest(tx, ty: Integer): Boolean;
var
  c: Char;
  tileVal: Integer;
begin
  if not city.TestBounds(tx, ty) then
    Exit(False);

  tileVal := Ord(city.GetTile(tx, ty));
  // The original Java code checks char values, here I assume tile constants are integers or chars.
  // Adjust these constants accordingly.

  if tileVal < ROADBASE then
    Exit(False)
  else if tileVal > LASTRAIL then
    Exit(False)
  else if (tileVal >= POWERBASE) and (tileVal < LASTPOWER) then
    Exit(False)
  else
    Exit(True);
end;

function TTrafficGen.TryDrive: Boolean;
var
  z: Integer;
begin
  lastdir := 5;
  positions.Clear;

  z := 0;
  while z < MAX_TRAFFIC_DISTANCE do
  begin
    if TryGo(z) then
    begin
      if DriveDone then
        Exit(True);
    end
    else
    begin
      if positions.Count > 0 then
      begin
        positions.Pop;
        Inc(z, 3);
      end
      else
        Exit(False);
    end;
    Inc(z);
  end;

  Result := False;
end;

function TTrafficGen.TryGo(z: Integer): Boolean;
var
  rdir, d, realdir: Integer;
begin
  rdir := city.PRNG.NextInt(4); // Delphi’s Random range 0..3

  for d := rdir to rdir + 3 do
  begin
    realdir := d mod 4;
    if realdir = lastdir then
      Continue;

    if RoadTest(mapX + DX[realdir], mapY + DY[realdir]) then
    begin
      mapX := mapX + DX[realdir];
      mapY := mapY + DY[realdir];
      lastdir := (realdir + 2) mod 4;

      if (z mod 2) = 1 then
        positions.Push(TCityLocation.Create(mapX, mapY));

      Exit(True);
    end;
  end;

  Result := False;
end;

function TTrafficGen.DriveDone: Boolean;
var
  low, high: Integer;
  tile: Integer;
begin
  case sourceZone of
    ztResidential:
      begin
        low := COMBASE;
        high := NUCLEAR;
      end;
    ztCommercial:
      begin
        low := LHTHR;
        high := PORT;
      end;
    ztIndustrial:
      begin
        low := LHTHR;
        high := COMBASE;
      end;
  else
    raise Exception.Create('Unreachable zone type');
  end;

  if mapY > 0 then
  begin
    tile := city.GetTile(mapX, mapY - 1);
    if (tile >= low) and (tile <= high) then
      Exit(True);
  end;
  if (mapX + 1) < city.GetWidth then
  begin
    tile := city.GetTile(mapX + 1, mapY);
    if (tile >= low) and (tile <= high) then
      Exit(True);
  end;
  if (mapY + 1) < city.GetHeight then
  begin
    tile := city.GetTile(mapX, mapY + 1);
    if (tile >= low) and (tile <= high) then
      Exit(True);
  end;
  if mapX > 0 then
  begin
    tile := city.GetTile(mapX - 1, mapY);
    if (tile >= low) and (tile <= high) then
      Exit(True);
  end;

  Result := False;
end;

constructor TTrafficCity.Create;
begin
  inherited Create;
end;

procedure TTrafficCity.AddTraffic(MapX, MapY, Traffic: Integer);
var
  Z: Integer;
  Copter: THelicopterSprite;
begin
  Z := TrfDensity[MapY div 2][MapX div 2];
  Inc(Z, Traffic);

  // FIXME: Why only capped at 240 by chance? No other cap?

  if (Z > 240) and (PRNG.NextInt(6) = 0) then
  begin
    Z := 240;
    TrafficMaxLocationX := MapX;
    TrafficMaxLocationY := MapY;

    Copter := THelicopterSprite(GetSprite(SpriteKind.COP));
    if Assigned(Copter) then
    begin
      Copter.DestX := MapX;
      Copter.DestY := MapY;
    end;
  end;

  TrfDensity[MapY div 2][MapX div 2] := Z;
end;


end.
