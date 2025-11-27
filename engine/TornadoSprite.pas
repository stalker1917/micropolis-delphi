// This file is part of MicropolisJ.
// Copyright (C) 2013 Jason Long
// Portions Copyright (C) 1989-2007 Electronic Arts Inc.
//
// MicropolisJ is free software; you can redistribute it and/or modify
// it under the terms of the GNU GPLv3, with additional terms.
// See the README file, included in this distribution, for details.



{
 * Implements a tornado (one of the Micropolis disasters).
}
unit TornadoSprite;

interface

uses
  SpriteCity,  SpriteKind, Sound, MicropolisMessage, SysUtils,
  TerrainBehavior,CityLocation,System.Math;

type
  TTornadoSprite = class(TSprite)
  private
    class var
      CDx: array[0..5] of Integer;
      CDy: array[0..5] of Integer;
  private
    FFlag: Boolean;
  public
    FCount: Integer;
    constructor Create(Engine: TSpriteCity; XPos, YPos: Integer);
    procedure MoveImpl; override;
  end;

implementation

{ TTornadoSprite }

constructor TTornadoSprite.Create(Engine: TSpriteCity; XPos, YPos: Integer);
begin
  inherited Create(Engine, TOR);  // assuming skTOR corresponds to SpriteKind.TOR
  // Initialize static arrays once
  if Length(CDx) = 0 then
  begin
    CDx[0] := 2;  CDx[1] := 3;  CDx[2] := 2;  CDx[3] := 0;  CDx[4] := -2; CDx[5] := -3;
    CDy[0] := -2; CDy[1] := 0;  CDy[2] := 2;  CDy[3] := 3;  CDy[4] := 2;  CDy[5] := 0;
  end;

  X := XPos * 16 + 8;
  Y := YPos * 16 + 8;
  Width := 48;
  Height := 48;
  OffX := -24;
  OffY := -40;

  Frame := 1;
  FCount := 200;
end;

procedure TTornadoSprite.MoveImpl;
var
  z, zz, i: Integer;
  s: TSprite;
begin
  z := Frame;

  if z = 2 then
  begin
    if FFlag then
      z := 3
    else
      z := 1;
  end
  else
  begin
    FFlag := (z = 1);
    z := 2;
  end;

  if FCount > 0 then
    Dec(FCount);

  Frame := z;

  for s in City.AllSprites do
  begin
    if CheckSpriteCollision(s) and
       ((s.Kind = AIR) or (s.Kind = COP) or (s.Kind = SHI) or (s.Kind = TRA)) then
    begin
      s.ExplodeSprite;
    end;
  end;

  zz := City.PRNG.NextInt(Length(CDx));
  Inc(X, CDx[zz]);
  Inc(Y, CDy[zz]);

  if not City.TestBounds(X div 16, Y div 16) then
  begin
    Frame := 0;
    Exit;
  end;

  if (FCount = 0) and (City.PRNG.NextInt(501) = 0) then
  begin
    Frame := 0;
    Exit;
  end;

  DestroyTile(X div 16, Y div 16);
end;

end.