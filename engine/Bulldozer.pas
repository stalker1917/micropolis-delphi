// This file is part of MicropolisJ.
// Copyright (C) 2013 Jason Long
// Portions Copyright (C) 1989-2007 Electronic Arts Inc.
//
// MicropolisJ is free software; you can redistribute it and/or modify
// it under the terms of the GNU GPLv3, with additional terms.
// See the README file, included in this distribution, for details.

unit Bulldozer;

interface

uses
  ToolStroke, ToolEffectIfc, Tiles, TileConstants,
  TranslatedToolEffect, CityRect, CityDimension, SysUtils, Sound,TerrainBehavior;

type
  TBulldozer = class(TToolStroke)
  public
    constructor Create(City: TTerrainCity; XPos, YPos: Integer);
  protected
    procedure ApplyArea(Eff: IToolEffectIfc); override;
    procedure DozeZone(Eff: IToolEffectIfc);
    procedure DozeField(Eff: IToolEffectIfc);
    procedure PutRubble(Eff: IToolEffectIfc; W, H: Integer);
  end;

implementation

{ TBulldozer }

constructor TBulldozer.Create(City: TTerrainCity; XPos, YPos: Integer);
begin
  inherited Create(City, mtBulldozer, XPos, YPos);
end;

procedure TBulldozer.ApplyArea(Eff: IToolEffectIfc);
var
  B: TCityRect;
  X, Y: Integer;
  SubEff: IToolEffectIfc;
begin
  B := GetBounds;

  // First pass: remove rubble/forest/etc.
  for Y := 0 to B.Height - 1 do
    for X := 0 to B.Width - 1 do
    begin
      SubEff := TTranslatedToolEffect.Create(Eff, B.X + X, B.Y + Y);
      if FCity.IsTileDozeable(SubEff) then
        DozeField(SubEff);
    end;

  // Second pass: remove zone centers
  for Y := 0 to B.Height - 1 do
    for X := 0 to B.Width - 1 do
      if IsZoneCenter(Eff.GetTile(B.X + X, B.Y + Y)) then
        DozeZone(TTranslatedToolEffect.Create(Eff, B.X + X, B.Y + Y));
end;

procedure TBulldozer.DozeZone(Eff: IToolEffectIfc);
var
  CurrTile, Z, NTile: Integer;
  Dim: TCityDimension;
begin
  CurrTile := Eff.GetTile(0, 0);
  Assert(IsZoneCenter(CurrTile));

  Dim := GetZoneSizeFor(CurrTile);
  Assert(Assigned(Dim));
  Assert((Dim.Width >= 3) and (Dim.Height >= 3));

  Eff.Spend(1);

  if Dim.Width * Dim.Height < 16 then
    Eff.MakeSound(0, 0, TSound.Create(EXPLOSION_HIGH))
  else if Dim.Width * Dim.Height < 36 then
    Eff.MakeSound(0, 0, TSound.Create(EXPLOSION_LOW))
  else
    Eff.MakeSound(0, 0, TSound.Create(EXPLOSION_BOTH));

  PutRubble(TTranslatedToolEffect.Create(Eff, -1, -1), Dim.Width, Dim.Height);
end;

procedure TBulldozer.DozeField(Eff: IToolEffectIfc);
var
  Tile: Integer;
begin
  Tile := Eff.GetTile(0, 0);

  if IsOverWater(Tile) then
    Eff.SetTile(0, 0, RIVER)
  else
    Eff.SetTile(0, 0, DIRT);

  FixZone(Eff);
  Eff.Spend(1);
end;

procedure TBulldozer.PutRubble(Eff: IToolEffectIfc; W, H: Integer);
var
  XX, YY, Tile, Z, NTile: Integer;
begin
  for YY := 0 to H - 1 do
    for XX := 0 to W - 1 do
    begin
      Tile := Eff.GetTile(XX, YY);
      if Tile = CLEAR then
        Continue;

      if (Tile <> RADTILE) and (Tile <> DIRT) then
      begin
        if FInPreview then
          Z := 0
        else
          Z := FCity.PRNG.NextInt(3);

        NTile := TINYEXP + Z;
        Eff.SetTile(XX, YY, NTile);
      end;
    end;

  FixBorder(Eff, W, H);
end;

end.