// This file is part of MicropolisJ.
// Copyright (C) 2013 Jason Long
// Portions Copyright (C) 1989-2007 Electronic Arts Inc.
//
// MicropolisJ is free software; you can redistribute it and/or modify
// it under the terms of the GNU GPLv3, with additional terms.
// See the README file, included in this distribution, for details.



{
 * Lists the simulation speeds available.
 * Contains properties identifying how often the animation timer fires,
 * and how many animation steps are fired at each interval.
 * Note: for every 2 animation steps, one simulation step is triggered.
}
Unit Speed;

interface
uses System.SysUtils;
 
type
  TSpeed = (
    PAUSED,
    SLOW,
    NORMAL,
    FAST,
    SUPER_FAST
  );

  TSpeedInfo = record
    AnimationDelay: Integer;
    SimStepsPerUpdate: Integer;
  end;

const
  SpeedInfo: array[TSpeed] of TSpeedInfo = (
    (AnimationDelay: 999; SimStepsPerUpdate: 0),  // PAUSED
    (AnimationDelay: 625; SimStepsPerUpdate: 1),  // SLOW
    (AnimationDelay: 125; SimStepsPerUpdate: 1),  // NORMAL
    (AnimationDelay: 25;  SimStepsPerUpdate: 1),  // FAST
    (AnimationDelay: 25;  SimStepsPerUpdate: 5)   // SUPER_FAST
  );
  function GetSpeedName(Speed: TSpeed): string;
  function SpeedFromString(const S: string): TSpeed;
implementation

function GetSpeedName(Speed: TSpeed): string;
begin
  case Speed of
    PAUSED:     Result := 'PAUSED';
    SLOW:       Result := 'SLOW';
    NORMAL:     Result := 'NORMAL';
    FAST:       Result := 'FAST';
    SUPER_FAST: Result := 'SUPER_FAST';
  else
    Result := 'NORMAL';
  end;
end;

function SpeedFromString(const S: string): TSpeed;
begin
  if SameText(S, 'SLOW') then
    Result := SLOW
  else if SameText(S, 'NORMAL') then
    Result := NORMAL
  else if SameText(S, 'FAST') then
    Result := FAST
  else if SameText(S, 'SUPER_FAST') then
    Result := SUPER_FAST
  else if SameText(S, 'PAUSED') then
    Result := PAUSED
  else
    Result := NORMAL;  // default fallback
end;


end.