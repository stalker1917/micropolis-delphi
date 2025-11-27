// This file is part of MicropolisJ.
// Copyright (C) 2013 Jason Long
// Portions Copyright (C) 1989-2007 Electronic Arts Inc.
//
// MicropolisJ is free software; you can redistribute it and/or modify
// it under the terms of the GNU GPLv3, with additional terms.
// See the README file, included in this distribution, for details.



{
 * Lists the disasters that the user can invoke.
}
unit Disaster;

interface

type
  TDisaster = (
    dMonster,
    dFire,
    dFlood,
    dMeltdown,
    dTornado,
    dEarthquake
  );
  TDisasterClass = class(TObject)
    FDisaster : TDisaster;

  end;

implementation

end.