// This file is part of MicropolisD.
// Copyright (C) 2025 Stalker1917
// Copyright (C) 2013 Jason Long (MicropolisJ)
// Portions Copyright (C) 1989-2007 Electronic Arts Inc.
//
// MicropolisD is free software; you can redistribute it and/or modify
// it under the terms of the GNU GPLv3, with additional terms.
// See the README file, included in this distribution, for details.


unit TerrainBehavior;

interface

uses
 SpriteCity, SysUtils,TileConstants,System.Generics.Collections,JavaRandom,SpriteKind,
 TrainSprite,CityProblem,Math,CityLocation,System.Generics.Defaults,ToolEffectIfc,TileSpec,ToolEffect,Tiles;

type
  TTerrainCity = class;
  TBehavior = (FIRE, FLOOD, RADIOACTIVE, ROAD, RAIL, EXPLOSION);
  

 
  TTerrainBehavior = class(TTileBehavior)
  private
    FBehavior: TBehavior;
    City  : TTerrainCity;
    class var TRAFFIC_DENSITY_TAB: array[0..2] of Integer;
  public
    constructor Create(ACity: TTerrainCity; ABehavior : TBehavior);

    procedure Apply; override;

    procedure DoFire;
    procedure DoFlood;
    procedure DoRadioactiveTile;
    procedure DoRoad;
    procedure DoRail;
    procedure DoExplosion;
    function DoBridge: Boolean;
    procedure ApplyBridgeChange(const Dx, Dy: array of Integer; const FromTab, ToTab: array of Integer);
    function GetBoatDis: Integer;
  end;

    TCityEval = class
  private
    engine: TTerrainCity;
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

    constructor Create(aEngine: TTerrainCity);
    procedure CityEvaluation;
    procedure EvalInit;
  end;

  TTerrainCity = class(TSpriteCity)
    floodCnt: Integer;
    floodX: Integer;
    floodY: Integer;

    poweredZoneCount: Integer;
    unpoweredZoneCount: Integer;

    firePop: Integer;
    totalPop: Integer;
    resPop: Integer;
    comPop: Integer;
    indPop: Integer;

    lastCityPop: Integer;

    roadEffect: Integer;
    policeEffect: Integer;
    fireEffect: Integer;

    roadTotal: Integer;
    railTotal: Integer;

    hospitalCount: Integer;
    churchCount: Integer;
    policeCount: Integer;
    fireStationCount: Integer;
    stadiumCount: Integer;
    coalCount: Integer;
    nuclearCount: Integer;
    seaportCount: Integer;
    airportCount: Integer;

    resValve: Integer;
    comValve: Integer;
    indValve: Integer;

    resCap: Boolean;
    comCap: Boolean;
    indCap: Boolean;

    cityTax: Integer;

    trafficAverage: Integer;
    pollutionMaxLocationX: Integer;
    pollutionMaxLocationY: Integer;

    crimeAverage: Integer;
    pollutionAverage: Integer;
    landValueAverage: Integer;


    trfDensity : array of array of Integer;
    fireRate: TInt2DArray;
    landValueMem : array of array of Integer;

    constructor Create;
    function  GetWidth: Integer;
    function  GetHeight: Integer;
    function  GetTrafficDensity(XPos, YPos: Integer): Integer;
    function  GetFireStationCoverage(XPos, YPos: Integer): Integer;
    procedure GenerateTrain(xpos, ypos: Integer);
    function  HasSprite(kind: TSpriteKind): Boolean;
    function  GetSprite(kind: TSpriteKind): TSprite;
    procedure FireEvaluationChanged;
    function  GetCityPopulation: Integer;
    function  GetLandValue(XPos, YPos: Integer): Integer;
    function  GetLocationOfMaxPollution: TCityLocation;
    function   IsTileDozeable(eff: IToolEffectIfc): Boolean; overload; //Перебросить выше, а то перекрёстная ссылка.
    function   IsTileDozeable(xpos, ypos: Integer): Boolean; overload;
  end;

implementation

{uses
  Constants, PRNGUnit;}

{ TTerrainBehavior }

constructor TTerrainBehavior.Create(ACity: TTerrainCity; ABehavior: TBehavior);
begin
  inherited Create(ACity);
  City := ACity;
  FBehavior := ABehavior;
end;

procedure TTerrainBehavior.Apply;
begin
  case FBehavior of
    FIRE: DoFire;
    FLOOD: DoFlood;
    RADIOACTIVE: DoRadioactiveTile;
    ROAD: DoRoad;
    RAIL: DoRail;
    EXPLOSION: DoExplosion;
  else
    raise Exception.Create('Unknown terrain behavior');
  end;
end;



procedure TTerrainBehavior.DoFire;
const
  DX: array[0..3] of Integer = (0, 1, 0, -1);
  DY: array[0..3] of Integer = (-1, 0, 1, 0);
var
  Dir, XT, YT, C, Cov, Rate: Integer;
begin
  City.FirePop := City.FirePop + 1;

  if FPRNG.NextInt(4) <> 0 then Exit;

  for Dir := 0 to 3 do
  begin
    if FPRNG.NextInt(8) = 0 then
    begin
      XT := FXPos + DX[Dir];
      YT := FYPos + DY[Dir];
      if not City.TestBounds(XT, YT) then Continue;
      C := City.GetTile(XT, YT);
      if IsCombustible(C) then
      begin
        if IsZoneCenter(C) then
        begin
          City.KillZone(XT, YT, C);
          if C > IZB then
            City.MakeExplosion(XT, YT);
        end;
        City.SetTile(XT, YT, TileConstants.FIRE);
      end;
    end;
  end;

  Cov := City.GetFireStationCoverage(FXPos, FYPos);
  if Cov > 100 then Rate := 1
  else if Cov > 20 then Rate := 2
  else if Cov > 0 then Rate := 3
  else Rate := 10;

  if FPRNG.NextInt(Rate + 1) = 0 then
    City.SetTile(FXPos, FYPos, RUBBLE + FPRNG.NextInt(4));
end;

procedure TTerrainBehavior.DoFlood;
const
  DX: array[0..3] of Integer = (0, 1, 0, -1);
  DY: array[0..3] of Integer = (-1, 0, 1, 0);
var
  Z, XX, YY, T: Integer;
begin
  if City.FloodCnt <> 0 then
  begin
    for Z := 0 to 3 do
    begin
      if FPRNG.NextInt(8) = 0 then
      begin
        XX := FXPos + DX[Z];
        YY := FYPos + DY[Z];
        if City.TestBounds(XX, YY) then
        begin
          T := City.GetTile(XX, YY);
          if IsCombustible(T) or (T = DIRT) or ((T >= WOODS5) and (T < TileConstants.FLOOD)) then
          begin
            if IsZoneCenter(T) then
              City.KillZone(XX, YY, T);
            City.SetTile(XX, YY, TileConstants.FLOOD + FPRNG.NextInt(3));
          end;
        end;
      end;
    end;
  end
  else if FPRNG.NextInt(16) = 0 then
    City.SetTile(FXPos, FYPos, DIRT);
end;

procedure TTerrainBehavior.DoRadioactiveTile;
begin
  if FPRNG.NextInt(4096) = 0 then
    City.SetTile(FXPos, FYPos, DIRT);
end;

procedure TTerrainBehavior.DoRoad;
var
  TDen, TrafficDensity, NewLevel, Z: Integer;
begin
  City.RoadTotal := City.RoadTotal + 1;

  if City.RoadEffect < 30 then
  begin
    if FPRNG.NextInt(512) = 0 then
    begin
      if not IsConductive(FTile) then
        if City.RoadEffect < FPRNG.NextInt(32) then
        begin
          if IsOverWater(FTile) then
            City.SetTile(FXPos, FYPos, RIVER)
          else
            City.SetTile(FXPos, FYPos, RUBBLE + FPRNG.NextInt(4));
          Exit;
        end;
    end;
  end;

  if not IsCombustible(FTile) then
  begin
    City.RoadTotal := City.RoadTotal + 4;
    if DoBridge then Exit;
  end;

  if FTile < LTRFBASE then TDen := 0
  else if FTile < HTRFBASE then TDen := 1
  else begin
    City.RoadTotal := City.RoadTotal + 1;
    TDen := 2;
  end;

  TrafficDensity := City.GetTrafficDensity(FXPos, FYPos);
  if TrafficDensity < 64 then NewLevel := 0
  else if TrafficDensity < 192 then NewLevel := 1
  else NewLevel := 2;

  if TDen <> NewLevel then
  begin
    Z := ((FTile - ROADBASE) and 15) + TRAFFIC_DENSITY_TAB[NewLevel];
    City.SetTile(FXPos, FYPos, Z);
  end;
end;

procedure TTerrainBehavior.DoRail;
begin
  City.RailTotal := City.RailTotal + 1;
  City.GenerateTrain(FXPos, FYPos);

  if City.RoadEffect < 30 then
    if FPRNG.NextInt(512) = 0 then
      if not IsConductive(FTile) then
        if City.RoadEffect < FPRNG.NextInt(32) then
        begin
          if IsOverWater(FTile) then
            City.SetTile(FXPos, FYPos, RIVER)
          else
            City.SetTile(FXPos, FYPos, RUBBLE + FPRNG.NextInt(4));
        end;
end;

procedure TTerrainBehavior.DoExplosion;
begin
  City.SetTile(FXPos, FYPos, RUBBLE + FPRNG.NextInt(4));
end;

function TTerrainBehavior.DoBridge: Boolean;
const
  HDx: array[0..6] of Integer = (-2, 2, -2, -1, 0, 1, 2);
  HDy: array[0..6] of Integer = (-1, -1, 0, 0, 0, 0, 0);
  HBRTAB: array[0..6] of Integer = (HBRDG1, HBRDG3, HBRDG0, RIVER, BRWH, RIVER, HBRDG2);
  HBRTAB2: array[0..6] of Integer = (RIVER, RIVER, HBRIDGE, HBRIDGE, HBRIDGE, HBRIDGE, HBRIDGE);

  VDx: array[0..6] of Integer = (0, 1, 0, 0, 0, 0, 1);
  VDy: array[0..6] of Integer = (-2, -2, -1, 0, 1, 2, 2);
  VBRTAB: array[0..6] of Integer = (VBRDG0, VBRDG1, RIVER, BRWV, RIVER, VBRDG2, VBRDG3);
  VBRTAB2: array[0..6] of Integer= (VBRIDGE, RIVER, VBRIDGE, VBRIDGE, VBRIDGE, VBRIDGE, RIVER);
begin
  if FTile = BRWV then
  begin
    if (FPRNG.NextInt(4) = 0) and (GetBoatDis > (340 div 16)) then
      ApplyBridgeChange(VDx, VDy, VBRTAB, VBRTAB2);
    Result := True;
    Exit;
  end
  else if FTile = BRWH then
  begin
    if (FPRNG.NextInt(4) = 0) and (GetBoatDis > (340 div 16)) then
      ApplyBridgeChange(HDx, HDy, HBRTAB, HBRTAB2);
    Result := True;
    Exit;
  end;

  if (GetBoatDis < (300 div 16)) and (FPRNG.NextInt(8) = 0) then
  begin
    if (FTile and 1) <> 0 then
    begin
      if (FXPos < City.GetWidth - 1) and (City.GetTile(FXPos + 1, FYPos) = CHANNEL) then
      begin
        ApplyBridgeChange(VDx, VDy, VBRTAB2, VBRTAB);
        Exit(True);
      end;
    end
    else
    begin
      if (FYPos > 0) and (City.GetTile(FXPos, FYPos - 1) = CHANNEL) then
      begin
        ApplyBridgeChange(HDx, HDy, HBRTAB2, HBRTAB);
        Exit(True);
      end;
    end;
  end;

  Result := False;
end;

procedure TTerrainBehavior.ApplyBridgeChange(const Dx, Dy: array of Integer;
  const FromTab, ToTab: array of Integer);
var
  Z, X, Y: Integer;
begin
  for Z := 0 to High(Dx) do
  begin
    X := FXPos + Dx[Z];
    Y := FYPos + Dy[Z];
    if City.TestBounds(X, Y) then
      if (City.GetTile(X, Y) = FromTab[Z]) or (City.GetTile(X, Y) = CHANNEL) then
        City.SetTile(X, Y, ToTab[Z]);
  end;
end;

function TTerrainBehavior.GetBoatDis: Integer;
var
  S: TSprite;
  D, X, Y: Integer;
begin
  Result := MaxInt;
  for S in City.Sprites do
    if S.IsVisible and (S.Kind = SpriteKind.SHI) then
    begin
      X := S.X div 16;
      Y := S.Y div 16;
      D := Abs(FXPos - X) + Abs(FYPos - Y);
      if D < Result then
        Result := D;
    end;
end;




constructor TCityEval.Create(aEngine: TTerrainCity);
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
  pair: TPair<TCityProblem, Integer>;
  oldCityScore : Integer;
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

procedure  TCityEval.DoProblems;
var
  ProbOrder: TArray<TCityProblem>;
  c, i: Integer;
begin
  // Clear and populate problem table
  ProblemTable.Clear;
  ProblemTable.Add(TCityProblem.cpCRIME, Engine.CrimeAverage);
  ProblemTable.Add(TCityProblem.cpPOLLUTION, Engine.PollutionAverage);
  ProblemTable.Add(TCityProblem.cpHOUSING, Round(Engine.LandValueAverage * 0.7));
  ProblemTable.Add(TCityProblem.cpTAXES, Engine.CityTax * 10);
  ProblemTable.Add(TCityProblem.cpTRAFFIC, AverageTrf);
  ProblemTable.Add(TCityProblem.cpUNEMPLOYMENT, GetUnemployment);
  ProblemTable.Add(TCityProblem.cpFIRE, GetFire);

  // Vote on problems
  ProblemVotes := VoteProblems(ProblemTable);

  // Sort problems by vote count (descending)
  ProbOrder :=  CityProblems;//СityProblem.GetValues;
  TArray.Sort<TCityProblem>(ProbOrder, TComparer<TCityProblem>.Construct(
    function(const A, B: TCityProblem): Integer
    begin
      Result := ProblemVotes[B] - ProblemVotes[A];
    end
  ));

  // Determine how many problems have votes
  c := 0;
  while (c < Length(ProbOrder)) and (ProblemVotes[ProbOrder[c]] <> 0) and (c < 4) do
    Inc(c);

  // Store the top problems
  SetLength(ProblemOrder, c);
  for i := 0 to c - 1 do
    ProblemOrder[i] := ProbOrder[i];
end;

function  TCityEval.VoteProblems(ProbTab: TDictionary<TCityProblem, Integer>): TDictionary<TCityProblem, Integer>;
var
  pp: TArray<TCityProblem>;
  Votes: TArray<Integer>;
  i, CountVotes: Integer;
begin
  pp := CityProblems;//TCityProblem.GetValues;
  SetLength(Votes, Length(pp));
  CountVotes := 0;

  // Simulate voting
  for i := 0 to 599 do
  begin
    if (Random(301) < ProbTab[pp[i mod Length(pp)]]) then
    begin
      Inc(Votes[i mod Length(pp)]);
      Inc(CountVotes);
      if CountVotes >= 100 then
        Break;
    end;
  end;

  // Create result dictionary
  Result := TDictionary<TCityProblem, Integer>.Create;
  for i := 0 to High(pp) do
    Result.Add(pp[i], Votes[i]);
end;


constructor TTerrainCity.Create;
begin
  inherited Create;
end;

function TTerrainCity.GetWidth: Integer;
begin
  if Length(map) > 0 then
    Result := Length(map[0])
  else
    Result := 0;
end;

function TTerrainCity.GetHeight: Integer;
begin
  Result := Length(map);
end;

function TTerrainCity.GetTrafficDensity(XPos, YPos: Integer): Integer;
begin
  if TestBounds(XPos, YPos) then
    Result := TrfDensity[YPos div 2][XPos div 2]
  else
    Result := 0;
end;

function TTerrainCity.GetFireStationCoverage(XPos, YPos: Integer): Integer;
begin
  Result := FireRate[YPos div 8][XPos div 8];
end;

procedure TTerrainCity.GenerateTrain(xpos, ypos: Integer);
begin
  if (totalPop > 20) and (not HasSprite(SpriteKind.TRA)) and (PRNG.NextInt(26) = 0) then
    sprites.Add(TTrainSprite.Create(Self, xpos, ypos));
end;

function TTerrainCity.HasSprite(kind: TSpriteKind): Boolean;
begin
  Result := GetSprite(kind) <> nil;
end;

function TTerrainCity.GetSprite(kind: TSpriteKind): TSprite;
var
  s: TSprite;
begin
  for s in sprites do
    if s.Kind = kind then
      Exit(s);
  Result := nil;
end;

procedure TTerrainCity.FireEvaluationChanged;
var
  L: IListener;
begin
  for L in listeners do
    L.EvaluationChanged;
end;

function TTerrainCity.GetCityPopulation: Integer;
begin
  Result := lastCityPop;
end;

function TTerrainCity.GetLandValue(XPos, YPos: Integer): Integer;
begin
  if TestBounds(XPos, YPos) then
    Result := LandValueMem[YPos div 2][XPos div 2]
  else
    Result := 0;
end;

function TTerrainCity.GetLocationOfMaxPollution: TCityLocation;
begin
  Result := TCityLocation.Create(PollutionMaxLocationX, PollutionMaxLocationY);
end;

function TTerrainCity.IsTileDozeable(eff: IToolEffectIfc): Boolean;
var
  myTile: Integer;
  ts: TTileSpec;
  baseTile: Integer;
begin
  myTile := eff.GetTile(0, 0);
  ts := TTiles.Get(MyTile);
  if ts.CanBulldoze then
  begin
    Result := True;
    Exit;
  end;

  if ts.Owner <> nil then
  begin
    // part of a zone; only bulldozeable if the owner tile is no longer intact
    baseTile := eff.GetTile(-ts.OwnerOffsetX, -ts.OwnerOffsetY);
    Result := not (ts.Owner.TileNumber = baseTile);
    Exit;
  end;

  Result := False;
end;

function TTerrainCity.IsTileDozeable(xpos, ypos: Integer): Boolean;
begin
  Result := IsTileDozeable(TToolEffect.Create(Self, xpos, ypos));
end;







initialization
  TTerrainBehavior.TRAFFIC_DENSITY_TAB[0] := ROADBASE;
  TTerrainBehavior.TRAFFIC_DENSITY_TAB[1] := LTRFBASE;
  TTerrainBehavior.TRAFFIC_DENSITY_TAB[2] := HTRFBASE;

end.
