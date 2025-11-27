// This file is part of MicropolisJ.
// Copyright (C) 2013 Jason Long
// Portions Copyright (C) 1989-2007 Electronic Arts Inc.
//
// MicropolisJ is free software; you can redistribute it and/or modify
// it under the terms of the GNU GPLv3, with additional terms.
// See the README file, included in this distribution, for details.



{
 * Implements the helicopter.
 * The helicopter appears if the city contains an airport.
 * It usually flies to the location in the city with the highest
 * traffic density, but sometimes flies to other locations.
}
unit HelicopterSprite;

interface

uses
  SpriteCity,  SpriteKind, Sound, MicropolisMessage, MonsterSprite,
  TornadoSprite, SysUtils, TerrainBehavior;

type
  THelicopterSprite = class(TSprite)
  private
    Count: Integer;
    OrigX, OrigY: Integer;
    FCity : TTerrainCity;

    const
      CDx: array[0..8] of Integer = (0, 0, 3, 5, 3, 0, -3, -5, -3);
      CDy: array[0..8] of Integer = (0, -5, -3, 0, 3, 5, 3, 0, -3);
      SOUND_FREQ = 200;

  public
    DestX, DestY: Integer;
    constructor Create(Engine: TTerrainCity; XPos, YPos: Integer);
    procedure MoveImpl; override;
  end;

implementation

constructor THelicopterSprite.Create(Engine: TTerrainCity; XPos, YPos: Integer);
begin
  inherited Create(Engine, SpriteKind.COP);
  FCity := Engine;
  Self.X := XPos * 16 + 8;
  Self.Y := YPos * 16 + 8;
  Self.Width := 32;
  Self.Height := 32;
  Self.OffX := -16;
  Self.OffY := -16;

  DestX := FCity.PRNG.NextInt(FCity.GetWidth) * 16 + 8;
  DestY := FCity.PRNG.NextInt(FCity.GetHeight) * 16 + 8;

  OrigX := X;
  OrigY := Y;
  Count := 1500;
  Frame := 5;
end;

procedure THelicopterSprite.MoveImpl;
var
  Z, D, XPosGrid, YPosGrid: Integer;
  Monster: TMonsterSprite;
  Tornado: TTornadoSprite;
begin
  if Count > 0 then
    Dec(Count);

  if Count = 0 then
  begin
    if FCity.HasSprite(SpriteKind.GOD) then
    begin
      Monster := TMonsterSprite(FCity.GetSprite(SpriteKind.GOD));
      DestX := Monster.X;
      DestY := Monster.Y;
    end
    else if FCity.HasSprite(SpriteKind.TOR) then
    begin
      Tornado := TTornadoSprite(FCity.GetSprite(SpriteKind.TOR));
      DestX := Tornado.X;
      DestY := Tornado.Y;
    end
    else
    begin
      DestX := OrigX;
      DestY := OrigY;
    end;

    if GetDis(X, Y, OrigX, OrigY) < 30 then
    begin
      Frame := 0;
      Exit;
    end;
  end;

  if (FCity.ACycle mod SOUND_FREQ = 0) then
  begin
    XPosGrid := X div 16;
    YPosGrid := Y div 16;
    if (FCity.GetTrafficDensity(XPosGrid, YPosGrid) > 170) and
       (FCity.PRNG.NextInt(8) = 0) then
    begin
      FCity.SendMessageAt(HEAVY_TRAFFIC_REPORT, XPosGrid, YPosGrid);
      FCity.MakeSound(XPosGrid, YPosGrid, TSound.Create(HEAVYTRAFFIC));
    end;
  end;

  Z := Frame;
  if FCity.ACycle mod 3 = 0 then
  begin
    D := GetDir(X, Y, DestX, DestY);
    Z := TurnTo(Z, D);
    Frame := Z;
  end;

  Inc(X, CDx[Z]);
  Inc(Y, CDy[Z]);
end;

end.
