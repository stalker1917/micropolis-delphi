// This file is part of MicropolisJ.
// Copyright (C) 2013 Jason Long
// Portions Copyright (C) 1989-2007 Electronic Arts Inc.
//
// MicropolisJ is free software; you can redistribute it and/or modify
// it under the terms of the GNU GPLv3, with additional terms.
// See the README file, included in this distribution, for details.


{
 * Coordinates of a location (x,y) in the city.
}
unit CityLocation;


interface
uses System.SysUtils;
type
  TCityLocation = class
  public
    X: Integer;  // East-West axis
    Y: Integer;  // North-South axis

    constructor Create(AX, AY: Integer);
    function Equals(Obj: TObject): Boolean; override;
    function GetHashCode: Integer; override;
    function ToString: string; override;
  end;

implementation

{ TCityLocation }

constructor TCityLocation.Create(AX, AY: Integer);
begin
  inherited Create;
  X := AX;
  Y := AY;
end;

function TCityLocation.Equals(Obj: TObject): Boolean;
var
  Other: TCityLocation;
begin
  if Obj is TCityLocation then
  begin
    Other := TCityLocation(Obj);
    Result := (X = Other.X) and (Y = Other.Y);
  end
  else
    Result := False;
end;

function TCityLocation.GetHashCode: Integer;
begin
  Result := X * 33 + Y;
end;

function TCityLocation.ToString: string;
begin
  Result := Format('(%d,%d)', [X, Y]);
end;

end.
