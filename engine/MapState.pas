// This file is part of MicropolisJ.
// Copyright (C) 2013 Jason Long
// Portions Copyright (C) 1989-2007 Electronic Arts Inc.
//
// MicropolisJ is free software; you can redistribute it and/or modify
// it under the terms of the GNU GPLv3, with additional terms.
// See the README file, included in this distribution, for details.



{
 * Lists the various map overlay options that are available.
}

unit MapState;

interface

type
  TMapState = (
    msAll,                // ALMAP
    msResidential,        // REMAP
    msCommercial,         // COMAP
    msIndustrial,         // INMAP
    msTransport,          // RDMAP
    msPopDenOverlay,      // PDMAP
    msGrowthRateOverlay,  // RGMAP
    msLandValueOverlay,   // LVMAP
    msCrimeOverlay,       // CRMAP
    msPolluteOverlay,     // PLMAP
    msTrafficOverlay,     // TDMAP
    msPowerOverlay,       // PRMAP
    msFireOverlay,        // FIMAP
    msPoliceOverlay       // POMAP
  );

function GetMapStateName(State:TMapState):String;

implementation

function GetMapStateName;
begin
   case State of
    msAll: Result := 'All';
    msResidential: Result := 'Residential';
    msCommercial: Result := 'Commercial';
    msIndustrial: Result := 'Industrial';
    msTransport: Result := 'Transport';
    msPopDenOverlay: Result := 'PopDen_Overlay';
    msGrowthRateOverlay: Result := 'GrowthRate_Overlay';
    msLandValueOverlay: Result := 'LandValue_Overlay';
    msCrimeOverlay: Result := 'Crime_Overlay';
    msPolluteOverlay: Result := 'Pollute_Overlay';
    msTrafficOverlay: Result := 'Traffic_Overlay';
    msPowerOverlay: Result := 'Power_Overlay';
    msFireOverlay: Result := 'Fire_Overlay';
    msPoliceOverlay  : Result := 'Police_Overlay';
   end;
end;

end.