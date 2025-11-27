// This file is part of MicropolisJ.
// Copyright (C) 2013 Jason Long
// Portions Copyright (C) 1989-2007 Electronic Arts Inc.
//
// MicropolisJ is free software; you can redistribute it and/or modify
// it under the terms of the GNU GPLv3, with additional terms.
// See the README file, included in this distribution, for details.



{
 * Enumeration of the various kinds of sprites that may appear in the city.
}
unit SpriteKind;

interface

type
  TSpriteKind = (
    TRA,
    COP,
    AIR,
    SHI,
    GOD,
    TOR,
    EXP,
    BUS
  );

  TSpriteKindInfo = record
    ObjectId: Integer;
    NumFrames: Integer;
  end;

const
  SpriteKindInfo: array[TSpriteKind] of TSpriteKindInfo = (
    (ObjectId: 1; NumFrames: 5),   // TRA
    (ObjectId: 2; NumFrames: 8),   // COP
    (ObjectId: 3; NumFrames: 11),  // AIR
    (ObjectId: 4; NumFrames: 8),   // SHI
    (ObjectId: 5; NumFrames: 16),  // GOD
    (ObjectId: 6; NumFrames: 3),   // TOR
    (ObjectId: 7; NumFrames: 6),   // EXP
    (ObjectId: 8; NumFrames: 4)    // BUS
  );

implementation

end.