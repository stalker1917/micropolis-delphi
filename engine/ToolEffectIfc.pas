// This file is part of MicropolisJ.
// Copyright (C) 2013 Jason Long
// Portions Copyright (C) 1989-2007 Electronic Arts Inc.
//
// MicropolisJ is free software; you can redistribute it and/or modify
// it under the terms of the GNU GPLv3, with additional terms.
// See the README file, included in this distribution, for details.

{
	 * Gets the tile at a relative location.
	 * @return a non-negative tile identifier
}
unit ToolEffectIfc;

interface

uses
  Sound,     // for TSound, adjust as needed
  ToolResult; // for TToolResult, adjust as needed

type
  IToolEffectIfc = interface
    ['{8F8E45B3-9F35-4D1B-9A2E-5E4B6A7B1C72}']  // GUID - generate a unique one for your interface
    function GetTile(dx, dy: Integer): Integer;
    procedure MakeSound(dx, dy: Integer; Asound: TSound);
    procedure SetTile(dx, dy: Integer; tileValue: Integer);
    procedure Spend(amount: Integer);
    procedure ToolResult(tr: TToolResult);
  end;

implementation

end.