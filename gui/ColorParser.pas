// This file is part of MicropolisJ.
// Copyright (C) 2013 Jason Long
// Portions Copyright (C) 1989-2007 Electronic Arts Inc.
//
// MicropolisJ is free software; you can redistribute it and/or modify
// it under the terms of the GNU GPLv3, with additional terms.
// See the README file, included in this distribution, for details.

unit ColorParser;

interface

uses
  System.SysUtils, System.RegularExpressions, System.Types, System.Classes, FMX.Graphics;

type
  EColorParseException = class(Exception);

  TColorParser = class
  public
    class function ParseColor(const Str: string): TAlphaColor; static;
  end;

implementation

class function TColorParser.ParseColor(const Str: string): TAlphaColor;
var
  R, G, B, A: Byte;
  AlphaFloat: Double;
  Parts: TArray<string>;
  S: string;
begin
  S := Trim(Str);

  // Format: #RRGGBB
  if (S.StartsWith('#')) and (Length(S) = 7) then
  begin
    // Parse hex RRGGBB
    R := StrToInt('$' + Copy(S, 2, 2));
    G := StrToInt('$' + Copy(S, 4, 2));
    B := StrToInt('$' + Copy(S, 6, 2));
    A := 255;
    Result := MakeColor(R, G, B, A);
    Exit;
  end;

  // Format: rgba(r,g,b,a)
  if S.StartsWith('rgba(') and S.EndsWith(')') then
  begin
    S := Copy(S, 6, Length(S) - 6); // extract inside parentheses

    Parts := S.Split([',']);
    if Length(Parts) <> 4 then
      raise EColorParseException.Create('Invalid rgba color format: ' + Str);

    R := StrToInt(Trim(Parts[0]));
    G := StrToInt(Trim(Parts[1]));
    B := StrToInt(Trim(Parts[2]));
    AlphaFloat := StrToFloat(Trim(Parts[3]));

    if (AlphaFloat < 0) or (AlphaFloat > 1) then
      raise EColorParseException.Create('Alpha value out of range (0..1): ' + Parts[3]);

    A := Min(255, Trunc(AlphaFloat * 256)); // replicate Java logic
    Result := MakeColor(R, G, B, A);
    Exit;
  end;

  raise EColorParseException.Create('Invalid color format: ' + Str);
end;

end.