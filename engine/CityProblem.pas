// This file is part of MicropolisJ.
// Copyright (C) 2013 Jason Long
// Portions Copyright (C) 1989-2007 Electronic Arts Inc.
//
// MicropolisJ is free software; you can redistribute it and/or modify
// it under the terms of the GNU GPLv3, with additional terms.
// See the README file, included in this distribution, for details.


{
 * Enumeration of various city problems that the citizens complain about.
}
unit CityProblem;

interface

type
  TCityProblem = (
    cpCrime,
    cpPollution,
    cpHousing,
    cpTaxes,
    cpTraffic,
    cpUnemployment,
    cpFire
  );

const CityProblems : TArray<TCityProblem> = [
cpCrime,
    cpPollution,
    cpHousing,
    cpTaxes,
    cpTraffic,
    cpUnemployment,
    cpFire
    ];

implementation

end.
