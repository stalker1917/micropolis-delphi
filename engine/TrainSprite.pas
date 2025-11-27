// This file is part of MicropolisJ.
// Copyright (C) 2013 Jason Long
// Portions Copyright (C) 1989-2007 Electronic Arts Inc.
//
// MicropolisJ is free software; you can redistribute it and/or modify
// it under the terms of the GNU GPLv3, with additional terms.
// See the README file, included in this distribution, for details.



{
 * Implements the commuter train.
 * The commuter train appears if the city has a certain amount of
 * railroad track. It wanders around the city's available track
 * randomly.
}
unit TrainSprite;

interface

uses
  System.SysUtils, System.Classes, SpriteCity,SpriteKind,TileConstants; // assuming these units exist

type
  TTrainSprite = class(TSprite)
  private
    const
      Cx: array[0..3] of Integer = (0, 16, 0, -16);
      Cy: array[0..3] of Integer = (-16, 0, 16, 0);
      Dx: array[0..4] of Integer = (0, 4, 0, -4, 0);
      Dy: array[0..4] of Integer = (-4, 0, 4, 0, 0);
      TrainPic2: array[0..4] of Integer = (1, 2, 1, 2, 5);

      TRA_GROOVE_X = 8;
      TRA_GROOVE_Y = 8;

      FRAME_NORTHSOUTH = 1;
      FRAME_EASTWEST = 2;
      FRAME_NW_SE = 3;
      FRAME_SW_NE = 4;
      FRAME_UNDERWATER = 5;

      DIR_NORTH = 0;
      DIR_EAST = 1;
      DIR_SOUTH = 2;
      DIR_WEST = 3;
      DIR_NONE = 4;

  protected
    procedure MoveImpl; override;

  public
    constructor Create(aEngine: TSpriteCity; xpos, ypos: Integer);
  end;

implementation

constructor TTrainSprite.Create(aEngine: TSpriteCity; xpos, ypos: Integer);
begin
  inherited Create(aEngine, SpriteKind.TRA);
  x := xpos * 16 + TRA_GROOVE_X;
  y := ypos * 16 + TRA_GROOVE_Y;
  offx := -16;
  offy := -16;
  dir := DIR_NONE;  // not moving
end;

procedure TTrainSprite.MoveImpl;
var
  d1, z, d2, c: Integer;
begin
  if (frame = 3) or (frame = 4) then
    frame := TrainPic2[dir];

  Inc(x, Dx[dir]);
  Inc(y, Dy[dir]);

  if city.acycle mod 4 = 0 then
  begin
    // Correct position to center of cell
    x := (x div 16) * 16 + TRA_GROOVE_X;
    y := (y div 16) * 16 + TRA_GROOVE_Y;

    d1 := city.PRNG.NextInt(4);

    for z := d1 to d1 + 3 do
    begin
      d2 := z mod 4;

      if (dir <> DIR_NONE) and (d2 = (dir + 2) mod 4) then
        Continue;

      c := GetChar(x + Cx[d2], y + Cy[d2]);

      if ((c >= RAILBASE) and (c <= LASTRAIL)) or
         (c = RAILVPOWERH) or
         (c = RAILHPOWERV) then
      begin
        if (dir <> d2) and (dir <> DIR_NONE) then
        begin
          if (dir + d2 = 3) then
            frame := FRAME_NW_SE
          else
            frame := FRAME_SW_NE;
        end
        else
          frame := TrainPic2[d2];

        if (c = RAILBASE) or (c = RAILBASE + 1) then
          frame := FRAME_UNDERWATER;

        dir := d2;
        Exit;
      end;
    end;

    if dir = DIR_NONE then
    begin
      frame := 0; // train retires
      Exit;
    end;

    dir := DIR_NONE;
  end;
end;

end.
