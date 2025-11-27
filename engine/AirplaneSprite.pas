// MicropolisJ is free software; you can redistribute it and/or modify
// it under the terms of the GNU GPLv3, with additional terms.
// See the README file, included in this distribution, for details.



{
 * Implements the airplane.
 * The airplane appears if the city contains an airport.
 * It first takes off, then flies around randomly,
 * occassionally crashing.
}



unit AirplaneSprite;

interface


uses
  SpriteCity, SpriteKind, SysUtils, Math;

const
  CDx : array[0..11] of Integer = (0, 0, 6, 8, 6, 0, -6, -8, -6, 8, 8, 8);
  CDy : array[0..11] of Integer = (0, -8, -6, 0, 6, 8, 6, 0, -6, 0, 0, 0);

type
  TAirplaneSprite = class(TSprite)
  private
    FDestX: Integer;
    FDestY: Integer;
    //class var
    //  CDx: array[0..11] of Integer;
    //  CDy: array[0..11] of Integer;
  public
    constructor Create(Engine: TSpriteCity; XPos, YPos: Integer); reintroduce;
    procedure MoveImpl; override;
  end;

implementation

{ Initialize direction deltas }
//initialization
 // TAirplaneSprite.CDx := (0, 0, 6, 8, 6, 0, -6, -8, -6, 8, 8, 8);
  //TAirplaneSprite.CDy := [0, -8, -6, 0, 6, 8, 6, 0, -6, 0, 0, 0];

{ TAirplaneSprite }

constructor TAirplaneSprite.Create(Engine: TSpriteCity; XPos, YPos: Integer);
begin
  inherited Create(Engine, AIR); // skAir = SpriteKind.AIR
  Self.X := XPos * 16 + 8;
  Self.Y := YPos * 16 + 8;
  Self.Width := 48;
  Self.Height := 48;
  Self.OffX := -24;
  Self.OffY := -24;

  FDestY := Self.Y;
  if XPos > Engine.GetWidth - 20 then
  begin
    // not enough room to the east of airport
    FDestX := Self.X - 200;
    Self.Frame := 7;
  end
  else
  begin
    FDestX := Self.X + 200;
    Self.Frame := 11;
  end;
end;

procedure TAirplaneSprite.MoveImpl;
var
  Z, D: Integer;
  S: TSprite;
  Explode: Boolean;
begin
  Z := Self.Frame;

  if (City.ACycle mod 5 = 0) then
  begin
    if Z > 8 then
    begin
      // Still taking off
      Dec(Z);
      if Z < 9 then Z := 3;
      Self.Frame := Z;
    end
    else
    begin
      D := GetDir(X, Y, FDestX, FDestY);
      Z := TurnTo(Z, D);
      Self.Frame := Z;
    end;
  end;

  if GetDis(X, Y, FDestX, FDestY) < 50 then
  begin
    FDestX := City.PRNG.NextInt(City.GetWidth) * 16 + 8;
    FDestY := City.PRNG.NextInt(City.GetHeight) * 16 + 8;
  end;

  if not City.NoDisasters then
  begin
    Explode := False;
    for S in City.AllSprites do
    begin
      if (S <> Self) and
         ((S.Kind = Air) or (S.Kind = Cop)) and
         CheckSpriteCollision(S) then
      begin
        S.ExplodeSprite;
        Explode := True;
      end;
    end;

    if Explode then
      Self.ExplodeSprite;
  end;

  Inc(Self.X, CDx[Z]);
  Inc(Self.Y, CDy[Z]);
end;

end.