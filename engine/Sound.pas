// This file is part of MicropolisJ.
// Copyright (C) 2013 Jason Long
// Portions Copyright (C) 1989-2007 Electronic Arts Inc.
//
// MicropolisJ is free software; you can redistribute it and/or modify
// it under the terms of the GNU GPLv3, with additional terms.
// See the README file, included in this distribution, for details.
{
 * Enumerates the various sounds that the city may produce.
 * The engine is not responsible for actually playing the sound. That task
 * belongs to the front-end (i.e. the user interface).
 *
 }
unit Sound;

interface
 
type
  TSound = class
  public
    type
      TSoundType = (
        EXPLOSION_LOW,
        EXPLOSION_HIGH,
        EXPLOSION_BOTH,
        UHUH,
        SORRY,
        BUILD,
        BULLDOZE,
        HONKHONK_LOW,
        HONKHONK_MED,
        HONKHONK_HIGH,
        HONKHONK_HI,
        SIREN,
        HEAVYTRAFFIC,
        MONSTER
      );
    class function WavName(SoundType: TSoundType): string; static;
    class function GetAudioFile(SoundType: TSoundType): string; static;
    constructor Create(SoundType: TSoundType);
    function GetSoundType:TSoundType;
    private
      FSoundType:TSoundType;

  end;

implementation

constructor TSound.Create;
begin
  FSoundType := SoundType;
end;

class function TSound.WavName(SoundType: TSoundType): string;
begin
  case SoundType of
    EXPLOSION_LOW: Result := 'explosion-low';
    EXPLOSION_HIGH: Result := 'explosion-high';
    EXPLOSION_BOTH: Result := 'explosion-low';
    UHUH: Result := 'bop';
    SORRY: Result := 'bop';
    BUILD: Result := 'layzone';
    BULLDOZE: Result := ''; // null in Java
    HONKHONK_LOW: Result := 'honkhonk-low';
    HONKHONK_MED: Result := 'honkhonk-med';
    HONKHONK_HIGH: Result := 'honkhonk-high';
    HONKHONK_HI: Result := 'honkhonk-hi';
    SIREN: Result := 'siren';
    HEAVYTRAFFIC: Result := 'heavytraffic';
    MONSTER: Result := 'zombie-roar-5';
  else
    Result := '';
  end;
end;

class function TSound.GetAudioFile(SoundType: TSoundType): string;
var
  _wavName: string;
begin
  _wavName := WavName(SoundType);
  if _wavName = '' then
    Result := ''
  else
    Result := './sounds/' + _wavName + '.wav';
  // Adjust path logic as needed for your Delphi resource handling
end;


function TSound.GetSoundType:TSoundType;
begin
  result := FSoundType;
end;


end.