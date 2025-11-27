// This file is part of MicropolisJ.
// Copyright (C) 2013 Jason Long
// Portions Copyright (C) 1989-2007 Electronic Arts Inc.
//
// MicropolisJ is free software; you can redistribute it and/or modify
// it under the terms of the GNU GPLv3, with additional terms.
// See the README file, included in this distribution, for details.

{
 * Specifies a rectangular area in the city's coordinate space.
 * This class is functionally equivalent to Java AWT's Rectangle
 * class, but is portable to Java editions that do not contain AWT.
}
unit CityRect;

interface

uses
  System.SysUtils;

type
  TCityRect = record
  public
    X, Y: Integer;  
//The X coordinate of the upper-left corner of the rectangle.
//The Y coordinate of the upper-left corner of the rectangle.  
    Width, Height: Integer;

    constructor Create(AX, AY, AWidth, AHeight: Integer);

    function Equals(const Other: TCityRect): Boolean; overload;
    function ToString: string; //override;

    class operator Equal(a, b: TCityRect): Boolean;
    class operator NotEqual(a, b: TCityRect): Boolean;
  end;

implementation

{ TCityRect }

constructor TCityRect.Create(AX, AY, AWidth, AHeight: Integer);
begin
  X := AX;
  Y := AY;
  Width := AWidth;
  Height := AHeight;
end;

function TCityRect.Equals(const Other: TCityRect): Boolean;
begin
  Result := (X = Other.X) and (Y = Other.Y) and (Width = Other.Width) and (Height = Other.Height);
end;

function TCityRect.ToString: string;
begin
  Result := Format('[%d,%d,%dx%d]', [X, Y, Width, Height]);
end;

class operator TCityRect.Equal(a, b: TCityRect): Boolean;
begin
  Result := a.Equals(b);
end;

class operator TCityRect.NotEqual(a, b: TCityRect): Boolean;
begin
  Result := not a.Equals(b);
end;

end.