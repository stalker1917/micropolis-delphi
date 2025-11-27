// This file is part of MicropolisJ.
// Copyright (C) 2013 Jason Long
// Portions Copyright (C) 1989-2007 Electronic Arts Inc.
//
// MicropolisJ is free software; you can redistribute it and/or modify
// it under the terms of the GNU GPLv3, with additional terms.
// See the README file, included in this distribution, for details.



{
 * Implements the cargo ship.
 * The cargo ship is created if the city contains a sea port.
 * It follows the river "channel" that was originally generated.
 * It frequently turns around.
}
unit ShipSprite;

interface

uses
  SysUtils, SpriteCity,  TileConstants, Sound, SpriteKind;

type
  TShipSprite = class(TSprite)
  private
    const
      BDx: array[0..8] of Integer = (0, 0, 1, 1, 1, 0, -1, -1, -1);
      BDy: array[0..8] of Integer = (0, -1, -1, 0, 1, 1, 1, 0, -1);
      BPx: array[0..8] of Integer = (0, 0, 2, 2, 2, 0, -2, -2, -2);
      BPy: array[0..8] of Integer = (0, -2, -2, 0, 2, 2, 2, 0, -2);
      BtClrTab: array[0..7] of Integer = (
        RIVER, CHANNEL, POWERBASE, POWERBASE + 1,
        RAILBASE, RAILBASE + 1, BRWH, BRWV);

  private
    FNewDir: Integer;
    FCount: Integer;
    FSoundCount: Integer;

  public
    const
      NORTH_EDGE = 5;
      EAST_EDGE  = 7;
      SOUTH_EDGE = 1;
      WEST_EDGE  = 3;

    constructor Create(AEngine: TSpriteCity; AXPos, AYPos, AEdge: Integer);
    procedure MoveImpl; override;

  private
    function TryOther(ATile, AOldDir, ANewDir: Integer): Boolean;
    function SpriteInBounds: Boolean;
    function TurnTo(AFrom, ATo: Integer): Integer; // Assuming this method exists or implement if needed
  end;

implementation



constructor TShipSprite.Create(AEngine: TSpriteCity; AXPos, AYPos, AEdge: Integer);
begin
  inherited Create(AEngine, Shi);
  X := AXPos * 16 + 8;
  Y := AYPos * 16 + 8;
  Width := 48;
  Height := 48;
  OffX := -24;
  OffY := -24;
  Frame := AEdge;
  FNewDir := AEdge;
  Dir := 10;
  FCount := 1;
end;

procedure TShipSprite.MoveImpl;
var
  T, Tem, Pem, Z, XPos, YPos: Integer;
  Found: Boolean;
begin
  T := RIVER;

  Dec(FSoundCount);
  if FSoundCount <= 0 then
  begin
    if City.PRNG.NextInt(4) = 0 then
      City.MakeSound(X div 16, Y div 16, TSound.Create(HONKHONK_LOW));
    FSoundCount := 200;
  end;

  Dec(FCount);
  if FCount <= 0 then
  begin
    FCount := 9;
    if FNewDir <> Frame then
    begin
      Frame := TurnTo(Frame, FNewDir);
      Exit;
    end;

    Tem := City.PRNG.NextInt(8);
    Pem := Tem;
    while Pem < Tem + 8 do
    begin
      Z := (Pem mod 8) + 1;
      if Z = Dir then
      begin
        Inc(Pem);
        Continue;
      end;

      XPos := X div 16 + BDx[Z];
      YPos := Y div 16 + BDy[Z];

      if City.TestBounds(XPos, YPos) then
      begin
        T := City.GetTile(XPos, YPos);
        if (T = CHANNEL) or (T = BRWH) or (T = BRWV) or TryOther(T, Dir, Z) then
        begin
          FNewDir := Z;
          Frame := TurnTo(Frame, FNewDir);
          Dir := Z + 4;
          if Dir > 8 then
            Dec(Dir, 8);
          Break;
        end;
      end;
      Inc(Pem);
    end;

    if Pem = Tem + 8 then
    begin
      Dir := 10;
      FNewDir := City.PRNG.NextInt(8) + 1;
    end;
  end
  else
  begin
    Z := Frame;
    if Z = FNewDir then
    begin
      Inc(X, BPx[Z]);
      Inc(Y, BPy[Z]);
    end;
  end;

  if not SpriteInBounds then
  begin
    Frame := 0;
    Exit;
  end;

  Found := False;
  for Z := Low(BtClrTab) to High(BtClrTab) do
    if T = BtClrTab[Z] then
    begin
      Found := True;
      Break;
    end;

  if not Found then
  begin
    if not City.NoDisasters then
    begin
      ExplodeSprite;
      DestroyTile(X div 16, Y div 16);
    end;
  end;
end;

function TShipSprite.TryOther(ATile, AOldDir, ANewDir: Integer): Boolean;
var
  Z: Integer;
begin
  Z := AOldDir + 4;
  if Z > 8 then
    Dec(Z, 8);
  if ANewDir <> Z then
    Exit(False);

  Result := (ATile = POWERBASE) or (ATile = POWERBASE + 1) or
            (ATile = RAILBASE) or (ATile = RAILBASE + 1);
end;

function TShipSprite.SpriteInBounds: Boolean;
begin
  Result := City.TestBounds(X div 16, Y div 16);
end;

// You must implement or adapt TurnTo if missing:
function TShipSprite.TurnTo(AFrom, ATo: Integer): Integer;
begin
  // Stub: example returns ATo unchanged
  Result := ATo;
end;

end.
