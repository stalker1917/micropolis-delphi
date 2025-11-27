// This file is part of MicropolisJ.
// Copyright (C) 2013 Jason Long
// Portions Copyright (C) 1989-2007 Electronic Arts Inc.
//
// MicropolisJ is free software; you can redistribute it and/or modify
// it under the terms of the GNU GPLv3, with additional terms.
// See the README file, included in this distribution, for details.


{
 * Implements a monster (one of the Micropolis disasters).
}
unit MonsterSprite;

interface

uses
  SpriteCity,  SpriteKind, Sound, MicropolisMessage, SysUtils,
  TerrainBehavior,CityLocation,System.Math,TileConstants;

type
  TMonsterSprite = class(TSprite)
  private
    OrigX, OrigY: Integer;
    Step: Integer;

    FCity : TTerrainCity;


    // Movement deltas
    const Gx: array[0..4] of Integer = (2, 2, -2, -2, 0);
    const Gy: array[0..4] of Integer = (-2, 2, 2, -2, 0);
    const ND1: array[0..3] of Integer = (0, 1, 2, 3);
    const ND2: array[0..3] of Integer = (1, 2, 3, 0);
    const nn1: array[0..3] of Integer = (2, 5, 8, 11);
    const nn2: array[0..3] of Integer = (11, 2, 5, 8);

  public
    Count: Integer;
    SoundCount: Integer;
    DestX, DestY: Integer;
    Flag: Boolean; // True if the monster wants to return home
    constructor Create(AEngine: TTerrainCity; AXPos, AYPos: Integer);
    procedure MoveImpl; override;
  end;

implementation

//uses
 // Sound, TileConstants, SpriteKind;

constructor TMonsterSprite.Create(AEngine: TTerrainCity; AXPos, AYPos: Integer);
var
  P: TCityLocation;
begin
  inherited Create(AEngine, GOD); // SpriteKind.GOD
  FCity := AEngine;

  Self.X := AXPos * 16 + 8;
  Self.Y := AYPos * 16 + 8;
  Self.Width := 48;
  Self.Height := 48;
  Self.OffX := -24;
  Self.OffY := -24;

  OrigX := X;
  OrigY := Y;

  if AXPos > FCity.GetWidth div 2 then
    Frame := IfThen(AYPos > FCity.GetHeight div 2, 10, 7)
  else
    Frame := IfThen(AYPos > FCity.GetHeight div 2, 1, 4);

  Count := 1000;
  P := FCity.GetLocationOfMaxPollution;
  DestX := P.X * 16 + 8;
  DestY := P.Y * 16 + 8;
  Flag := False;
  Step := 1;
end;

procedure TMonsterSprite.MoveImpl;
var
  D, Z, C, Z2, NewFrame: Integer;
  S: TSprite;
begin
  if Frame = 0 then Exit;

  if SoundCount > 0 then
    Dec(SoundCount);

  D := (Frame - 1) div 3;
  Z := (Frame - 1) mod 3;

  if D < 4 then
  begin
    if Z = 2 then Step := -1;
    if Z = 0 then Step := 1;
    Inc(Z, Step);

    if GetDis(X, Y, DestX, DestY) < 60 then
    begin
      if not Flag then
      begin
        Flag := True;
        DestX := OrigX;
        DestY := OrigY;
      end
      else
      begin
        Frame := 0;
        Exit;
      end;
    end;

    C := GetDir(X, Y, DestX, DestY);
    C := (C - 1) div 2;

    if (C <> D) and (FCity.PRNG.NextInt(11) = 0) then
    begin
      if FCity.PRNG.NextInt(2) = 0 then
        Z := ND1[D]
      else
        Z := ND2[D];

      D := 4;

      if SoundCount = 0 then
      begin
        FCity.MakeSound(X div 16, Y div 16, TSound.Create(MONSTER));
        SoundCount := 50 + FCity.PRNG.NextInt(101);
      end;
    end;
  end
  else
  begin
    Z2 := (Frame - 13) mod 4;

    if FCity.PRNG.NextInt(4) = 0 then
    begin
      if FCity.PRNG.NextInt(2) = 0 then
        NewFrame := nn1[Z2]
      else
        NewFrame := nn2[Z2];

      D := (NewFrame - 1) div 3;
      Z := (NewFrame - 1) mod 3;
    end
    else
    begin
      D := 4;
    end;
  end;

  Frame := (D * 3 + Z) + 1;

  Inc(X, Gx[D]);
  Inc(Y, Gy[D]);

  if Count > 0 then
    Dec(Count);

  C := GetChar(X, Y);
  if (C = -1) or ((C = RIVER) and (Count <> 0) and (False)) then
  begin
    Frame := 0;
    Exit;
  end;

  for S in FCity.AllSprites do
  begin
    if CheckSpriteCollision(S) and
       (S.Kind in [Air, Cop, Shi, Tra]) then
    begin
      S.ExplodeSprite;
    end;
  end;

  DestroyTile(X div 16, Y div 16);
end;

end.
