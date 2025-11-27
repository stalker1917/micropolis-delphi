// This file is part of MicropolisJ.
// Copyright (C) 2013 Jason Long
// Portions Copyright (C) 1989-2007 Electronic Arts Inc.
//
// MicropolisJ is free software; you can redistribute it and/or modify
// it under the terms of the GNU GPLv3, with additional terms.
// See the README file, included in this distribution, for details.

unit CityDimension;

interface
uses System.SysUtils;

type
  TCityDimension = class
  public
    Width: Integer;
    Height: Integer;

    constructor Create(AWidth, AHeight: Integer);
    function Equals(Obj: TObject): Boolean; override;
    function GetHashCode: Integer; override;
    function ToString: string; override;
  end;

implementation

{ TCityDimension }

constructor TCityDimension.Create(AWidth, AHeight: Integer);
begin
  inherited Create;
  Width := AWidth;
  Height := AHeight;
end;

function TCityDimension.Equals(Obj: TObject): Boolean;
var
  Other: TCityDimension;
begin
  if Obj is TCityDimension then
  begin
    Other := TCityDimension(Obj);
    Result := (Width = Other.Width) and (Height = Other.Height);
  end
  else
    Result := False;
end;

function TCityDimension.GetHashCode: Integer;
begin
  Result := Width * 33 + Height;
end;

function TCityDimension.ToString: string;
begin
  Result := Format('%dx%d', [Width, Height]);
end;

end.
