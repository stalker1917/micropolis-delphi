// This file is part of MicropolisJ.
// Copyright (C) 2013 Jason Long
// Portions Copyright (C) 1989-2007 Electronic Arts Inc.
//
// MicropolisJ is free software; you can redistribute it and/or modify
// it under the terms of the GNU GPLv3, with additional terms.
// See the README file, included in this distribution, for details.

unit CityEval

interface

type 

{
 * Contains the code for performing a city evaluation.
}
TCityEval = class
  private
    engine: TMicropolis;
    PRNG: TRandom;

    procedure CalculateAssValue;
    procedure DoPopNum;
    procedure DoProblems;
    procedure CalculateScore;
    procedure DoVotes;
    function VoteProblems(probTab: TDictionary<TCityProblem, Integer>): TDictionary<TCityProblem, Integer>;
    function AverageTrf: Integer;
    function GetUnemployment: Integer;
    function GetFire: Integer;
    function Clamp(x, minVal, maxVal: Double): Double;
  public
    cityYes, cityNo: Integer;
    cityAssValue: Integer;
    cityScore: Integer;
    deltaCityScore: Integer;
    cityPop, deltaCityPop: Integer;
    cityClass: Integer;

    problemOrder: array of TCityProblem;
    problemVotes: TDictionary<TCityProblem, Integer>;
    problemTable: TDictionary<TCityProblem, Integer>;

    constructor Create(aEngine: TMicropolis);
    procedure CityEvaluation;
    procedure EvalInit;
  end;
  
implementation  

constructor TCityEval.Create(aEngine: TMicropolis);
begin
  inherited Create;
  engine := aEngine;
  PRNG := engine.PRNG;
  Assert(PRNG <> nil);
  problemVotes := TDictionary<TCityProblem, Integer>.Create;
  problemTable := TDictionary<TCityProblem, Integer>.Create;
end;

procedure TCityEval.CityEvaluation;
begin
  if engine.totalPop <> 0 then
  begin
    CalculateAssValue;
    DoPopNum;
    DoProblems;
    CalculateScore;
    DoVotes;
  end
  else
    EvalInit;
  engine.FireEvaluationChanged;
end;

procedure TCityEval.EvalInit;
begin
  cityYes := 0;
  cityNo := 0;
  cityAssValue := 0;
  cityClass := 0;
  cityScore := 500;
  deltaCityScore := 0;
  problemVotes.Clear;
  SetLength(problemOrder, 0);
end;

procedure TCityEval.CalculateAssValue;
var
  z: Integer;
begin
  z := 0;
  Inc(z, engine.roadTotal * 5);
  Inc(z, engine.railTotal * 10);
  Inc(z, engine.policeCount * 1000);
  Inc(z, engine.fireStationCount * 1000);
  Inc(z, engine.hospitalCount * 400);
  Inc(z, engine.stadiumCount * 3000);
  Inc(z, engine.seaportCount * 5000);
  Inc(z, engine.airportCount * 10000);
  Inc(z, engine.coalCount * 3000);
  Inc(z, engine.nuclearCount * 6000);
  cityAssValue := z * 1000;
end;

procedure TCityEval.DoPopNum;
begin
  cityPop := engine.GetCityPopulation;
  deltaCityPop := cityPop - deltaCityPop;

  if cityPop > 500000 then cityClass := 5
  else if cityPop > 100000 then cityClass := 4
  else if cityPop > 50000 then cityClass := 3
  else if cityPop > 10000 then cityClass := 2
  else if cityPop > 2000 then cityClass := 1
  else cityClass := 0;
end;

function TCityEval.AverageTrf: Integer;
var
  x, y, count, total: Integer;
begin
  count := 1;
  total := 0;
  for y := 0 to engine.GetHeight - 1 do
    for x := 0 to engine.GetWidth - 1 do
      if engine.GetLandValue(x, y) <> 0 then
      begin
        Inc(total, engine.GetTrafficDensity(x, y));
        Inc(count);
      end;
  engine.trafficAverage := Round((total / count) * 2.4);
  Result := engine.trafficAverage;
end;

function TCityEval.GetUnemployment: Integer;
var
  b: Integer;
  r: Double;
begin
  b := (engine.comPop + engine.indPop) * 8;
  if b = 0 then Exit(0);
  r := engine.resPop / b;
  b := Trunc((r - 1.0) * 255);
  if b > 255 then b := 255;
  Result := b;
end;

function TCityEval.GetFire: Integer;
begin
  Result := Min(255, engine.firePop * 5);
end;

function TCityEval.Clamp(x, minVal, maxVal: Double): Double;
begin
  Result := Max(minVal, Min(maxVal, x));
end;



procedure TCityEval.CalculateScore;
var
  x: Integer;
  z, SM: Double;
  TM: Integer;
  value: Integer;
  pair: TPair<Integer, Integer>;
begin
  oldCityScore := cityScore;

  x := 0;
  for pair in problemTable do
  begin
    value := pair.Value;
    x := x + value;
  end;

  x := x div 3;
  if x > 256 then
    x := 256;

  z := Clamp((256 - x) * 4, 0, 1000);

  if engine.resCap then
    z := 0.85 * z;
  if engine.comCap then
    z := 0.85 * z;
  if engine.indCap then
    z := 0.85 * z;
  if engine.roadEffect < 32 then
    z := z - (32 - engine.roadEffect);
  if engine.policeEffect < 1000 then
    z := z * (0.9 + (engine.policeEffect / 10000.1));
  if engine.fireEffect < 1000 then
    z := z * (0.9 + (engine.fireEffect / 10000.1));
  if engine.resValve < -1000 then
    z := z * 0.85;
  if engine.comValve < -1000 then
    z := z * 0.85;
  if engine.indValve < -1000 then
    z := z * 0.85;

  if (cityPop = 0) and (deltaCityPop = 0) then
    SM := 1.0
  else if deltaCityPop = cityPop then
    SM := 1.0
  else if deltaCityPop > 0 then
    SM := (deltaCityPop / cityPop) + 1.0
  else // deltaCityPop < 0
    SM := 0.95 + (deltaCityPop / (cityPop - deltaCityPop));

  z := z * SM;
  z := z - GetFire();
  z := z - engine.cityTax;

  TM := engine.unpoweredZoneCount + engine.poweredZoneCount;
  if TM <> 0 then
    SM := engine.poweredZoneCount / TM
  else
    SM := 1.0;

  z := z * SM;

  z := Clamp(z, 0, 1000);

  cityScore := Round((cityScore + z) / 2);
  deltaCityScore := cityScore - oldCityScore;
end;

procedure TCityEval.DoVotes;
var
  i: Integer;
  randVal: Integer;
begin
  cityYes := 0;
  cityNo := 0;
  for i := 0 to 99 do
  begin
    randVal := Random(1001);  // Random generates 0..Max-1 so 1001 is used
    if randVal < cityScore then
      Inc(cityYes)
    else
      Inc(cityNo);
  end;
end;

}
