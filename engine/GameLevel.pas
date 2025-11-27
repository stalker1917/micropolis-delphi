// This file is part of MicropolisJ.
// Copyright (C) 2013 Jason Long
// Portions Copyright (C) 1989-2007 Electronic Arts Inc.
//
// MicropolisJ is free software; you can redistribute it and/or modify
// it under the terms of the GNU GPLv3, with additional terms.
// See the README file, included in this distribution, for details.

unit GameLevel;

interface
  const
      MIN_LEVEL = 0;
      MAX_LEVEL = 2;
type
  TGameLevel = class
  public


    class function IsValid(Lev: Integer): Boolean; static;
    class function GetStartingFunds(Lev: Integer): Integer; static;

  private
    // Prevent instantiation by making constructor private
    constructor Create; 
  end;

implementation

uses
  SysUtils;

{ TGameLevel }

constructor TGameLevel.Create;
begin
  inherited;
  // Prevent instantiation
  raise Exception.Create('TGameLevel cannot be instantiated');
end;

class function TGameLevel.IsValid(Lev: Integer): Boolean;
begin
  Result := (Lev >= MIN_LEVEL) and (Lev <= MAX_LEVEL);
end;

class function TGameLevel.GetStartingFunds(Lev: Integer): Integer;
begin
  case Lev of
    0: Result := 20000;
    1: Result := 10000;
    2: Result := 5000;
  else
    raise Exception.CreateFmt('Unexpected game level: %d', [Lev]);
  end;
end;

end.