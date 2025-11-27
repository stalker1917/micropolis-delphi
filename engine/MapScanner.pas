unit MapScanner;

interface

uses
  TrafficGen, TileConstants, System.SysUtils,SpriteCity,TileSpec,CityDimension,
  CityLocation,System.Generics.Collections,SpriteKind,Tiles,
  HelicopterSprite,AirplaneSprite,MicropolisMessage,ShipSprite,
  Math,TerrainBehavior;



type
  TBehavior = (
    RESIDENTIAL,
    HOSPITAL_CHURCH,
    COMMERCIAL,
    INDUSTRIAL,
    COAL,
    NUCLEAR,
    FIRESTATION,
    POLICESTATION,
    STADIUM_EMPTY,
    STADIUM_FULL,
    AIRPORT,
    SEAPORT
  );


  TMapCity = Class;

  TMapScanner = class(TTileBehavior)
  private
    FBehavior: TBehavior;
    FTraffic: TTrafficGen;
    FCity : TMapCity;
  public
    constructor Create(ACity: TMapCity; ABehavior: TBehavior);
    procedure Apply; override;
    function  CheckZonePower: Boolean;
    function  SetZonePower: Boolean;
    function  ZonePlop(const Base: TTileSpec): Boolean;
    procedure MakeHospital;
    function  MakeTraffic(zoneType: TZoneType): Integer;
    procedure RepairZone(base: Integer);
    procedure DrawStadium(zoneCenter: Integer);
    procedure BuildHouse(value: Integer);
    
    // Add declarations for other methods like:
    procedure DoResidential;
    procedure DoHospitalChurch;
    procedure DoCommercial;
    procedure DoIndustrial;
    procedure DoCoalPower;
    procedure DoNuclearPower;
    procedure DoFireStation;
    procedure DoPoliceStation;
    procedure DoStadiumEmpty;
    procedure DoStadiumFull;
    procedure DoAirport;
    procedure DoSeaport;
    procedure DoCommercialIn(pop, value: Integer);
    procedure DoIndustrialIn(pop, value: Integer);
    procedure DoResidentialIn(pop, value: Integer);
    procedure DoResidentialOut(pop, value: Integer);
    procedure DoIndustrialOut(pop, value: Integer);
    procedure DoCommercialOut(pop, value: Integer);
    function  EvalCommercial(traf: Integer): Integer;
    function  EvalIndustrial(traf: Integer): Integer;
    function  EvalResidential(traf: Integer): Integer;
    function  EvalLot(x, y: Integer): Integer;
    procedure ComPlop(density, value: Integer);
    procedure IndPlop(density, value: Integer);
    procedure ResidentialPlop(density, value: Integer);
    function  GetCRValue: Integer;
    procedure AdjustROG(amount: Integer);

  end;

  TMapCity = Class(TTrafficCity)
    cityTime: Integer;
    powerPlants: TStack<TCityLocation>;
    fireStMap: TInt2DArray;
    policeMap: TInt2DArray;
    policeMapEffect: TInt2DArray;
    needHospital: Integer;
    needChurch: Integer;
    gameLevel: Integer;
    resZoneCount: Integer;
    comZoneCount: Integer;
    indZoneCount: Integer;


    MltdwnTab  : array  [0..2] of Integer;
    meltdownLocation: TCityLocation;

    powerMap : array of array of boolean;


   {
	 * For each 2x2 section of the city, the land value of the city (0-250).
	 * 0 is lowest land value; 250 is maximum land value.
	 * Updated each cycle by ptlScan().
   }

    pollutionMem: TInt2DArray;
{
	 * For each 2x2 section of the city, the pollution level of the city (0-255).
	 * 0 is no pollution; 255 is maximum pollution.
	 * Updated each cycle by ptlScan(); affects land value.}

    popDensity: TInt2DArray;
  {	/**
	 * For each 2x2 section of the city, the population density (0-?).
	 * Used for map overlays and as a factor for crime rates.
	 */
  }

   { For each 8x8 section of city, this is an integer between 0 and 64,
	 * with higher numbers being closer to the center of the city.}
   comRate: array of array of Integer;



    constructor Create; //virtual;
    function  HasPower(x, y: Integer): Boolean;
    function  IsTilePowered(xpos, ypos: Integer): Boolean;
    procedure SetTilePower(xpos, ypos: Integer; power: Boolean);
    procedure PowerZone(xPos, yPos: Integer; const zoneSize: TCityDimension);
    procedure GenerateCopter(xpos, ypos: Integer);
    procedure GeneratePlane(xpos, ypos: Integer);
    procedure DoMeltdown(xpos, ypos: Integer);
    procedure GenerateShip;
    procedure MakeShipAt(xpos, ypos, edge: Integer);
    procedure ClearMes;
    function  GetPopulationDensity(xpos, ypos: Integer): Integer;
    function  DoFreePop(xpos, ypos: Integer): Integer;

  End;

implementation

// The implementation section will go here in the final unit
constructor TMapScanner.Create(ACity: TMapCity; ABehavior: TBehavior);
	begin
		inherited Create(Acity);
    FCity := Acity;
		FBehavior := Abehavior;
		Ftraffic := TTrafficGen.Create(Acity); // new TrafficGen(city);
	end;


procedure TMapScanner.Apply;
begin
  case FBehavior of
    RESIDENTIAL: DoResidential;
    HOSPITAL_CHURCH: DoHospitalChurch;
    COMMERCIAL: DoCommercial;
    INDUSTRIAL: DoIndustrial;
    COAL: DoCoalPower;
    NUCLEAR: DoNuclearPower;
    FIRESTATION: DoFireStation;
    POLICESTATION: DoPoliceStation;
    STADIUM_EMPTY: DoStadiumEmpty;
    STADIUM_FULL: DoStadiumFull;
    AIRPORT: DoAirport;
    SEAPORT: DoSeaport;
  else
    Assert(False, 'Unexpected behavior value');
  end;
end;

function TMapScanner.CheckZonePower: Boolean;
begin
  Result := SetZonePower;
  if Result then
    FCity.poweredZoneCount := FCity.poweredZoneCount + 1
  else
    FCity.unpoweredZoneCount := FCity.unpoweredZoneCount + 1;
end;

function TMapScanner.SetZonePower: Boolean;
var
  oldPower, newPower: Boolean;
begin
  oldPower := FCity.IsTilePowered(FXPos, FYPos);
  newPower := (FTile = TileConstants.NUCLEAR) or
              (FTile = TileConstants.POWERPLANT) or
              FCity.HasPower(FXPos, FYPos);

  if newPower and not oldPower then
  begin
    FCity.SetTilePower(FXPos, FYPos, True);
    FCity.PowerZone(FXPos, FYPos, GetZoneSizeFor(FTile));
  end
  else if not newPower and oldPower then
  begin
    FCity.SetTilePower(FXPos, FYPos, False);
    FCity.ShutdownZone(FXPos, FYPos, GetZoneSizeFor(FTile));
  end;

  Result := newPower;
end;
{
	 * Place a 3x3 zone on to the map, centered on the current location.
	 * Note: nothing is done if part of this zone is off the edge
	 * of the map or is being flooded or radioactive.
	 *
	 * @param base The "zone" tile value for this zone.
	 * @return true iff the zone was actually placed.
}

function TMapScanner.ZonePlop(const Base: TTileSpec): Boolean;
var
  Bi: TBuildingInfo;//TTileSpecBuildingInfo;
  XOrg, YOrg, X, Y, I: Integer;
begin
  Assert(Base.Zone);
  Bi := Base.GetBuildingInfo;
  Assert(Bi <> nil);
  if Bi = nil then
    Exit(False);

  XOrg := FXPos - 1;
  YOrg := FYPos - 1;

  for Y := YOrg to YOrg + Bi.Height - 1 do
  begin
    for X := XOrg to XOrg + Bi.Width - 1 do
    begin
      if not FCity.TestBounds(X, Y) then
        Exit(False);
      if IsIndestructible(FCity.GetTile(X, Y)) then
        Exit(False); // radioactive, on fire, or flooded
    end;
  end;

  Assert(Length(Bi.Members) = Bi.Width * Bi.Height);
  I := 0;
  for Y := YOrg to YOrg + Bi.Height - 1 do
  begin
    for X := XOrg to XOrg + Bi.Width - 1 do
    begin
      FCity.SetTile(X, Y, Bi.Members[I].TileNumber);
      Inc(I);
    end;
  end;

  // Refresh own tile property
  FTile := FCity.GetTile(FXPos, FYPos);

  SetZonePower;
  Result := True;
end;

procedure TMapScanner.DoCoalPower;
var
  PowerOn: Boolean;
begin
  PowerOn := CheckZonePower;
  Inc(FCity.CoalCount);
  if (FCity.CityTime mod 8) = 0 then
    RepairZone(POWERPLANT);

  FCity.PowerPlants.Push(TCityLocation.Create(FXPos, FYPos));
end;

procedure TMapScanner.DoNuclearPower;
var
  PowerOn: Boolean;
begin
  PowerOn := CheckZonePower;
  if (not FCity.NoDisasters) and (FPRNG.NextInt(FCity.MltdwnTab[FCity.GameLevel] + 1) = 0) then
  begin
    FCity.DoMeltdown(FXPos, FYPos);
    Exit;
  end;

  Inc(FCity.NuclearCount);
  if (FCity.CityTime mod 8) = 0 then
    RepairZone(TileConstants.NUCLEAR);

  FCity.PowerPlants.Push(TCityLocation.Create(FXPos, FYPos));
end;

procedure TMapScanner.DoFireStation;
var
  PowerOn, FoundRoad: Boolean;
  Z: Integer;
begin
  PowerOn := CheckZonePower;
  Inc(FCity.FireStationCount);
  if (FCity.CityTime mod 8) = 0 then
    RepairZone(TileConstants.FIRESTATION);

  if PowerOn then
    Z := FCity.FireEffect
  else
    Z := FCity.FireEffect div 2;

  FTraffic.MapX := FXPos;
  FTraffic.MapY := FYPos;
  FoundRoad := FTraffic.FindPerimeterRoad;
  if not FoundRoad then
    Z := Z div 2;

  Inc(FCity.FireStMap[FYPos div 8, FXPos div 8], Z);
end;

procedure TMapScanner.DoPoliceStation;
var
  PowerOn, FoundRoad: Boolean;
  Z: Integer;
begin
  PowerOn := CheckZonePower;
  Inc(FCity.PoliceCount);
  if (FCity.CityTime mod 8) = 0 then
    RepairZone(TileConstants.POLICESTATION);

  if PowerOn then
    Z := FCity.PoliceEffect
  else
    Z := FCity.PoliceEffect div 2;

  FTraffic.MapX := FXPos;
  FTraffic.MapY := FYPos;
  FoundRoad := FTraffic.FindPerimeterRoad;
  if not FoundRoad then
    Z := Z div 2;

  Inc(FCity.PoliceMap[FYPos div 8, FXPos div 8], Z);
end;

procedure TMapScanner.DoStadiumEmpty;
var
  PowerOn: Boolean;
begin
  PowerOn := CheckZonePower;
  Inc(FCity.StadiumCount);
  if (FCity.CityTime mod 16) = 0 then
    RepairZone(STADIUM);

  if PowerOn and ((FCity.CityTime + FXPos + FYPos) mod 32 = 0) then
  begin
    DrawStadium(FULLSTADIUM);
    FCity.SetTile(FXPos + 1, FYPos, FOOTBALLGAME1);
    FCity.SetTile(FXPos + 1, FYPos + 1, FOOTBALLGAME2);
  end;
end;

procedure TMapScanner.DoStadiumFull;
var
  PowerOn: Boolean;
begin
  PowerOn := CheckZonePower;
  Inc(FCity.StadiumCount);
  if ((FCity.CityTime + FXPos + FYPos) mod 8) = 0 then
    DrawStadium(STADIUM);
end;

procedure TMapScanner.DoAirport;
var
  PowerOn: Boolean;
begin
  PowerOn := CheckZonePower;
  Inc(FCity.AirportCount);
  if (FCity.CityTime mod 8) = 0 then
    RepairZone(TileConstants.AIRPORT);

  if PowerOn then
  begin
    if FPRNG.NextInt(6) = 0 then
      FCity.GeneratePlane(FXPos, FYPos);

    if FPRNG.NextInt(13) = 0 then
      FCity.GenerateCopter(FXPos, FYPos);
  end;
end;

procedure TMapScanner.DoSeaport;
var
  PowerOn: Boolean;
begin
  PowerOn := CheckZonePower;
  Inc(FCity.SeaportCount);
  if (FCity.CityTime mod 16) = 0 then
    RepairZone(PORT);

  if PowerOn and (not FCity.HasSprite(SpriteKind.SHI)) then
    FCity.GenerateShip;
end;

procedure TMapScanner.MakeHospital;
begin
  if FCity.NeedHospital > 0 then
  begin
    ZonePlop(TTiles.LoadByOrdinal(HOSPITAL));
    FCity.NeedHospital := 0;
  end;

  // FIXME: should be else if
  if FCity.NeedChurch > 0 then
  begin
    ZonePlop(TTiles.LoadByOrdinal(CHURCH));
    FCity.NeedChurch := 0;
  end;
end;

procedure TMapScanner.DoHospitalChurch;
var
  PowerOn: Boolean;
begin
  PowerOn := CheckZonePower;
  if FTile = HOSPITAL then
  begin
    Inc(FCity.HospitalCount);
    if (FCity.CityTime mod 16) = 0 then
      RepairZone(HOSPITAL);
    if FCity.NeedHospital = -1 then
    begin
      if FPRNG.NextInt(21) = 0 then
        ZonePlop(TTiles.LoadByOrdinal(RESCLR));
    end;
  end
  else if FTile = CHURCH then
  begin
    Inc(FCity.ChurchCount);
    if (FCity.CityTime mod 16) = 0 then
      RepairZone(CHURCH);
    if FCity.NeedChurch = -1 then
    begin
      if FPRNG.NextInt(21) = 0 then
        ZonePlop(TTiles.LoadByOrdinal(RESCLR));
    end;
  end;
end;

procedure TMapScanner.RepairZone(base: Integer);
var
  powerOn: Boolean;
  bi: TBuildingInfo;
  xorg, yorg, xx, yy, x, y, i: Integer;
  ts: TTileSpec;
  thCh: Integer;
begin
  Assert(IsZoneCenter(base));
  powerOn := FCity.IsTilePowered(FXPos, FYPos);

  bi := TTiles.Get(base).GetBuildingInfo;
  Assert(bi <> nil);

  xorg := FXPos - 1;
  yorg := FYPos - 1;

  Assert(Length(bi.Members) = bi.Width * bi.Height);

  i := 0;
  for y := 0 to bi.Height - 1 do
  begin
    for x := 0 to bi.Width - 1 do
    begin
      xx := xorg + x;
      yy := yorg + y;

      ts := bi.Members[i];
      Inc(i);

      if powerOn and (ts.OnPower <> nil) then
        ts := ts.OnPower;

      if FCity.TestBounds(xx, yy) then
      begin
        thCh := FCity.GetTile(xx, yy);
        if IsZoneCenter(thCh) then
          Continue;
        if IsAnimated(thCh) then
          Continue;
        if IsRubble(thCh) then
          Continue;
        if not IsIndestructible(thCh) then
          FCity.SetTile(xx, yy, ts.TileNumber);
      end;
    end;
  end;
end;

procedure TMapScanner.DoCommercial;
var
  powerOn: Boolean;
  tpop, trafficGood, locValve, zscore, value: Integer;
begin
  powerOn := CheckZonePower;
  Inc(FCity.ComZoneCount);

  tpop := CommercialZonePop(FTile);
  FCity.ComPop := FCity.ComPop + tpop;

  if tpop > FPRNG.NextInt(6) then
    trafficGood := MakeTraffic(TZoneType.ztCOMMERCIAL)
  else
    trafficGood := 1;

  if trafficGood = -1 then
  begin
    value := GetCRValue;
    DoCommercialOut(tpop, value);
    Exit;
  end;

  if FPRNG.NextInt(8) = 0 then
  begin
    locValve := EvalCommercial(trafficGood);
    zscore := FCity.ComValve + locValve;

    if not powerOn then
      zscore := -500;

    if (trafficGood <> 0) and (zscore > -350) and (zscore - 26380 > (FPRNG.NextInt($10000) - $8000)) then
    begin
      value := GetCRValue;
      DoCommercialIn(tpop, value);
      Exit;
    end;

    if (zscore < 350) and (zscore + 26380 < (FPRNG.NextInt($10000) - $8000)) then
    begin
      value := GetCRValue;
      DoCommercialOut(tpop, value);
    end;
  end;
end;

procedure TMapScanner.DoIndustrial;
var
  powerOn: Boolean;
  tpop, trafficGood, locValve, zscore, value: Integer;
begin
  powerOn := CheckZonePower;
  Inc(FCity.IndZoneCount);

  tpop := IndustrialZonePop(FTile);
  FCity.IndPop := FCity.IndPop + tpop;

  if tpop > FPRNG.NextInt(6) then
    trafficGood := MakeTraffic(TZoneType.ztINDUSTRIAL)
  else
    trafficGood := 1;

  if trafficGood = -1 then
  begin
    DoIndustrialOut(tpop, FPRNG.NextInt(2));
    Exit;
  end;

  if FPRNG.NextInt(8) = 0 then
  begin
    locValve := EvalIndustrial(trafficGood);
    zscore := FCity.IndValve + locValve;

    if not powerOn then
      zscore := -500;

    if (zscore > -350) and (zscore - 26380 > (FPRNG.NextInt($10000) - $8000)) then
    begin
      value := FPRNG.NextInt(2);
      DoIndustrialIn(tpop, value);
      Exit;
    end;

    if (zscore < 350) and (zscore + 26380 < (FPRNG.NextInt($10000) - $8000)) then
    begin
      value := FPRNG.NextInt(2);
      DoIndustrialOut(tpop, value);
    end;
  end;
end;

procedure TMapScanner.DoResidential;
var
  powerOn: Boolean;
  tpop, trafficGood, locValve, zscore, value: Integer;
begin
  powerOn := CheckZonePower;
  Inc(FCity.ResZoneCount);

  if FTile = RESCLR then
    tpop := FCity.DoFreePop(FXPos, FYPos)
  else
    tpop := ResidentialZonePop(FTile);

  FCity.ResPop := FCity.ResPop + tpop;

  if tpop > FPRNG.NextInt(36) then
    trafficGood := MakeTraffic(TZoneType.ztRESIDENTIAL)
  else
    trafficGood := 1;

  if trafficGood = -1 then
  begin
    value := GetCRValue;
    DoResidentialOut(tpop, value);
    Exit;
  end;

  if (FTile = RESCLR) or (FPRNG.NextInt(8) = 0) then
  begin
    locValve := EvalResidential(trafficGood);
    zscore := FCity.ResValve + locValve;

    if not powerOn then
      zscore := -500;

    if (zscore > -350) and (zscore - 26380 > (FPRNG.NextInt($10000) - $8000)) then
    begin
      if (tpop = 0) and (FPRNG.NextInt(4) = 0) then
      begin
        MakeHospital;
        Exit;
      end;

      value := GetCRValue;
      DoResidentialIn(tpop, value);
      Exit;
    end;

    if (zscore < 350) and (zscore + 26380 < (FPRNG.NextInt($10000) - $8000)) then
    begin
      value := GetCRValue;
      DoResidentialOut(tpop, value);
    end;
  end;
end;

function TMapScanner.EvalLot(x, y: Integer): Integer;
const
  DX: array[0..3] of Integer = (0, 1, 0, -1);
  DY: array[0..3] of Integer = (-1, 0, 1, 0);
var
  aTile, z, xx, yy, tmp: Integer;
  score: Integer;
begin
  aTile := Fcity.GetTile(x, y);
  if (aTile <> DIRT) and (not IsResidentialClear(aTile)) then
  begin
    Result := -1;
    Exit;
  end;

  score := 1;

  for z := 0 to 3 do
  begin
    xx := x + DX[z];
    yy := y + DY[z];
    if Fcity.TestBounds(xx, yy) then
    begin
      tmp := Fcity.GetTile(xx, yy);
      if IsRoad(tmp) or IsRail(tmp) then
        Inc(score);
    end;
  end;

  Result := score;
end;

procedure TMapScanner.BuildHouse(value: Integer);
const
  ZeX: array[0..8] of Integer = (0, -1, 0, 1, -1, 1, -1, 0, 1);
  ZeY: array[0..8] of Integer = (0, -1, -1, -1, 0, 0, 1, 1, 1);
var
  bestLoc, hscore, z, xx, yy, score, houseNumber: Integer;
begin
  Assert((value >= 0) and (value <= 3));

  bestLoc := 0;
  hscore := 0;

  for z := 1 to 8 do
  begin
    xx := FXPos + ZeX[z];
    yy := FYPos + ZeY[z];

    if Fcity.TestBounds(xx, yy) then
    begin
      score := EvalLot(xx, yy);

      if score <> 0 then
      begin
        if score > hscore then
        begin
          hscore := score;
          bestLoc := z;
        end
        else if (score = hscore) and (FPRNG.NextInt(8) = 0) then
          bestLoc := z;
      end;
    end;
  end;

  if bestLoc <> 0 then
  begin
    xx := FXPos + ZeX[bestLoc];
    yy := FYPos + ZeY[bestLoc];
    houseNumber := value * 3 + FPRNG.NextInt(3);
    Assert((houseNumber >= 0) and (houseNumber < 12));
    Assert(Fcity.TestBounds(xx, yy));

    Fcity.SetTile(xx, yy, HOUSE + houseNumber);
  end;
end;

procedure TMapScanner.DoCommercialIn(pop, value: Integer);
var
  z: Integer;
begin
  z := Fcity.GetLandValue(FXPos, FYPos) div 32;
  if pop > z then
    Exit;

  if pop < 5 then
  begin
    ComPlop(pop, value);
    AdjustROG(8);
  end;
end;

procedure TMapScanner.DoIndustrialIn(pop, value: Integer);
begin
  if pop < 4 then
  begin
    IndPlop(pop, value);
    AdjustROG(8);
  end;
end;

procedure TMapScanner.DoResidentialIn(pop, value: Integer);
var
  z: Integer;
begin
  Assert((value >= 0) and (value <= 3));

  z := Fcity.pollutionMem[FYPos div 2, FXPos div 2];
  if z > 128 then Exit;

  if Ftile = RESCLR then
  begin
    if pop < 8 then
    begin
      BuildHouse(value);
      AdjustROG(1);
      Exit;
    end;

    if Fcity.GetPopulationDensity(FXPos, FYPos) > 64 then
    begin
      ResidentialPlop(0, value);
      AdjustROG(8);
      Exit;
    end;
    Exit;
  end;

  if pop < 40 then
  begin
    ResidentialPlop((pop div 8) - 1, value);
    AdjustROG(8);
  end;
end;

procedure TMapScanner.ComPlop(density, value: Integer);
var
  base: Integer;
begin
  base := (value * 5 + density) * 9 + CZB;
  zonePlop(TTiles.LoadByOrdinal(base));
end;

procedure TMapScanner.IndPlop(density, value: Integer);
var
  base: Integer;
begin
  base := (value * 4 + density) * 9 + IZB;
  zonePlop(TTiles.LoadByOrdinal(base));
end;

procedure TMapScanner.ResidentialPlop(density, value: Integer);
var
  base: Integer;
begin
  base := (value * 4 + density) * 9 + RZB;
  zonePlop(TTiles.LoadByOrdinal(base));
end;

procedure TMapScanner.DoCommercialOut(pop, value: Integer);
begin
  if pop > 1 then
  begin
    ComPlop(pop - 2, value);
    AdjustROG(-8);
  end
  else if pop = 1 then
  begin
    zonePlop(TTiles.LoadByOrdinal(COMCLR));
    AdjustROG(-8);
  end;
end;

procedure TMapScanner.DoIndustrialOut(pop, value: Integer);
begin
  if pop > 1 then
  begin
    IndPlop(pop - 2, value);
    AdjustROG(-8);
  end
  else if pop = 1 then
  begin
    zonePlop(TTiles.LoadByOrdinal(INDCLR));
    AdjustROG(-8);
  end;
end;

procedure TMapScanner.DoResidentialOut(pop, value: Integer);
const
  Brdr: array[0..8] of Byte = (0, 3, 6, 1, 4, 7, 2, 5, 8);
var
  x, y, z: Integer;
  loc: Integer;
  pwr: Boolean;
begin
  Assert((value >= 0) and (value < 4));

  if pop = 0 then Exit;

  if pop > 16 then
  begin
    ResidentialPlop((pop - 24) div 8, value);
    AdjustROG(-8);
    Exit;
  end;

  if pop = 16 then
  begin
    pwr := Fcity.IsTilePowered(FXPos, FYPos);
    Fcity.SetTile(FXPos, FYPos, RESCLR);
    Fcity.SetTilePower(FXPos, FYPos, pwr);

    for x := FXPos - 1 to FXPos + 1 do
      for y := FYPos - 1 to FYPos + 1 do
        if Fcity.TestBounds(x, y) then
          if not ((x = FXPos) and (y = FYPos)) then
          begin
            loc := value * 3 + FPRNG.NextInt(3);
            Fcity.SetTile(x, y, HOUSE + loc);
          end;

    AdjustROG(-8);
    Exit;
  end;

  if pop < 16 then
  begin
    AdjustROG(-1);
    z := 0;
    for x := FXPos - 1 to FXPos + 1 do
      for y := FYPos - 1 to FYPos + 1 do
        if Fcity.TestBounds(x, y) then
        begin
          loc := Fcity.GetTile(x, y);
          if (loc >= LHTHR) and (loc <= HHTHR) then
          begin
            Fcity.SetTile(x, y,Brdr[z] + RESCLR - 4);
            Exit;
          end;
          Inc(z);
        end;
  end;
end;


function TMapScanner.EvalCommercial(traf: Integer): Integer;
begin
  if traf < 0 then
    Exit(-3000);

  Result := Fcity.comRate[FYPos div 8][FXPos div 8];
end;

function TMapScanner.EvalIndustrial(traf: Integer): Integer;
begin
  if traf < 0 then
    Result := -1000
  else
    Result := 0;
end;

function TMapScanner.EvalResidential(traf: Integer): Integer;
var
  value: Integer;
begin
  if traf < 0 then
    Exit(-3000);

  value := Fcity.GetLandValue(FXPos, FYPos);
  value := value - Fcity.pollutionMem[FYPos div 2][FXPos div 2];

  if value < 0 then
    value := 0
  else
    value := value * 32;

  if value > 6000 then
    value := 6000;

  Result := value - 3000;
end;

function TMapScanner.GetCRValue: Integer;
var
  lval: Integer;
begin
  lval := Fcity.GetLandValue(FXPos, FYPos);
  lval := lval - Fcity.pollutionMem[FYPos div 2][FXPos div 2];

  if lval < 30 then
    Exit(0)
  else if lval < 80 then
    Exit(1)
  else if lval < 150 then
    Exit(2)
  else
    Exit(3);
end;

procedure TMapScanner.AdjustROG(amount: Integer);
begin
  Fcity.rateOGMem[FYPos div 8][FXPos div 8] := Fcity.rateOGMem[FYPos div 8][FXPos div 8] + 4 * amount;
end;

procedure TMapScanner.DrawStadium(zoneCenter: Integer);
var
  zoneBase, x, y: Integer;
begin
  zoneBase := zoneCenter - 1 - 4;

  for y := 0 to 3 do
    for x := 0 to 3 do
    begin
      Fcity.SetTile(FXPos - 1 + x, FYPos - 1 + y, zoneBase);
      Inc(zoneBase);
    end;

  Fcity.SetTilePower(FXPos, FYPos, True);
end;

function TMapScanner.MakeTraffic(zoneType: TZoneType): Integer;
begin
  Ftraffic.mapX := FXPos;
  Ftraffic.mapY := FYPos;
  Ftraffic.sourceZone := zoneType;
  Result :=Ftraffic.MakeTraffic;
end;


constructor TMapCity.Create;
begin
  inherited Create;
  MltdwnTab[0] := 30000;
  MltdwnTab[1] := 20000;
  MltdwnTab[2] := 10000;
  powerPlants := TStack<TCityLocation>.Create;
end;

function TMapCity.IsTilePowered(xpos, ypos: Integer): Boolean;
begin
  Result := (GetTileRaw(xpos, ypos) and PWRBIT) = PWRBIT;
end;

function TMapCity.HasPower(x, y: Integer): Boolean;
begin
  Result := PowerMap[y][x];
end;

procedure TMapCity.SetTilePower(xpos, ypos: Integer; power: Boolean);
begin
  Map[ypos][xpos] := (Map[ypos][xpos] and (not PWRBIT)) or (IfThen(power, PWRBIT, 0));
end;

procedure TMapCity.PowerZone(xPos, yPos: Integer; const zoneSize: TCityDimension);
var
  dx, dy, x, y, tile: Integer;
  ts: TTileSpec;
begin
  Assert(zoneSize.Width >= 3);
  Assert(zoneSize.Height >= 3);

  for dx := 0 to zoneSize.Width - 1 do
  begin
    for dy := 0 to zoneSize.Height - 1 do
    begin
      x := xPos - 1 + dx;
      y := yPos - 1 + dy;
      tile := GetTileRaw(x, y);
      ts := TTiles.Get(tile and LOMASK);
      if Assigned(ts) and Assigned(ts.OnPower) then
      begin
        SetTile(x, y, ts.OnPower.TileNumber or (tile and ALLBITS));
      end;
    end;
  end;
end;

procedure TMapCity.GenerateCopter(xpos, ypos: Integer);
begin
  if not HasSprite(SpriteKind.COP) then
    sprites.Add(THelicopterSprite.Create(Self, xpos, ypos));
end;

procedure TMapCity.GeneratePlane(xpos, ypos: Integer);
begin
  if not HasSprite(SpriteKind.AIR) then
    sprites.Add(TAirplaneSprite.Create(Self, xpos, ypos));
end;

procedure TMapCity.DoMeltdown(xpos, ypos: Integer);
var
  x, y, z: Integer;
  t: Integer;
begin
  if meltdownLocation<>nil then meltdownLocation.Free;
  meltdownLocation := TCityLocation.Create(xpos, ypos);

  makeExplosion(xpos - 1, ypos - 1);
  makeExplosion(xpos - 1, ypos + 2);
  makeExplosion(xpos + 2, ypos - 1);
  makeExplosion(xpos + 2, ypos + 2);

  for x := xpos - 1 to xpos + 2 do
    for y := ypos - 1 to ypos + 2 do
      setTile(x, y, TileConstants.FIRE);

  for z := 0 to 199 do
  begin
    x := xpos - 20 + Random(41);
    y := ypos - 15 + Random(31);

    if not testBounds(x, y) then
      Continue;

    t := map[y][x];
    if isZoneCenter(t) then
      Continue;

    if isCombustible(t) or (t = DIRT) then
      setTile(x, y, RADTILE);
  end;

  clearMes;
  sendMessageAt(MicropolisMessage.MELTDOWN_REPORT, xpos, ypos);
end;

procedure TMapCity.GenerateShip;
var
  edge, x, y: Integer;
begin
  edge := PRNG.NextInt(4);

  case edge of
    0:
      begin
        for x := 4 to GetWidth - 3 do
          if GetTile(x, 0) = CHANNEL then
          begin
            MakeShipAt(x, 0, TShipSprite.NORTH_EDGE);
            Exit;
          end;
      end;
    1:
      begin
        for y := 1 to GetHeight - 3 do
          if GetTile(0, y) = CHANNEL then
          begin
            MakeShipAt(0, y, TShipSprite.EAST_EDGE);
            Exit;
          end;
      end;
    2:
      begin
        for x := 4 to GetWidth - 3 do
          if GetTile(x, GetHeight - 1) = CHANNEL then
          begin
            MakeShipAt(x, GetHeight - 1, TShipSprite.SOUTH_EDGE);
            Exit;
          end;
      end;
    3:
      begin
        for y := 1 to GetHeight - 3 do
          if GetTile(GetWidth - 1, y) = CHANNEL then
          begin
            MakeShipAt(GetWidth - 1, y, TShipSprite.EAST_EDGE);
            Exit;
          end;
      end;
  end;
end;

procedure TMapCity.MakeShipAt(xpos, ypos, edge: Integer);
begin
  Assert(not HasSprite(SpriteKind.SHI));
  sprites.Add(TShipSprite.Create(Self, xpos, ypos, edge));
end;

procedure TMapCity.ClearMes;
begin
  // TODO:
  // In the original, this clears the 'last message' properties,
  // ensuring that repeated messages still get delivered.
end;

function TMapCity.GetPopulationDensity(xpos, ypos: Integer): Integer;
begin
  Result := popDensity[ypos div 2][xpos div 2];
end;

function TMapCity.DoFreePop(xpos, ypos: Integer): Integer;
var
  x, y: Integer;
  loc: Word;
begin
  Result := 0;
  for x := xpos - 1 to xpos + 1 do
    for y := ypos - 1 to ypos + 1 do
      if TestBounds(x, y) then
      begin
        loc := GetTile(x, y);
        if (loc >= LHTHR) and (loc <= HHTHR) then
          Inc(Result);
      end;
end;




end.