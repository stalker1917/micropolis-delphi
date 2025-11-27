unit MicropolisUnit;

interface

uses
  System.SysUtils, System.Classes,System.Generics.Collections,
  CityBudget,JavaRandom,EarthquakeListener,CityProblem,MapState,
  Sound,CityLocation,MicropolisMessage,TileConstants,SpriteCity,
  Xml.XMLDoc, Xml.XMLIntf, XML_Helper,
  TerrainBehavior,MapScanner,TileSpec,
  ToolEffectIfc,ToolEffect,BudgetNumbers,Tiles,Math,
  MonsterSprite,SpriteKind,ZoneStatus,Speed,GameLevel,
  TornadoSprite;

{
 * The main simulation engine for Micropolis.
 * The front-end should call animate() periodically
 * to move the simulation forward in time.
}
const
  DEFAULT_WIDTH = 120;
  DEFAULT_HEIGHT = 100;
  VALVERATE = 2;
  CENSUSRATE = 4;
  TAXFREQ = 48;
  //** Annual maintenance cost of each police station. */
  POLICE_STATION_MAINTENANCE = 100;

 //** Annual maintenance cost of each fire station. */
	FIRE_STATION_MAINTENANCE = 100;
  
  TaxTable: array[0..20] of Integer = (
    200, 150, 120, 100, 80, 50, 30, 0, -10, -40, -100,
    -150, -200, -250, -300, -350, -400, -450, -500, -550, -600
  );

  //** Road/rail maintenance cost multiplier, for various difficulty settings.
 //	 */
	RLevels : array[0..2] of Double = ( 0.7, 0.9, 1.2);

	//** Tax income multiplier, for various difficulty settings.
	// */
	FLevels : array[0..2] of Double = ( 1.4, 1.2, 0.8);

  


type
  //TSpeed = (NORMAL); // Placeholder enum
  //TCityBudget = class; // Forward declaration
  //TCityEval = class;   // Forward declaration
  //TTileBehavior = class;
  TMicropolis = class;
  //TSprite = class;

 
  TTileBehaviorMap = TDictionary<string, TTileBehavior>;
  TArray240 = array[0..239] of Integer;
  
 THistory = class
  public
    CityTime: Integer;
    Res: TArray240;
    Com: TArray240;
    Ind: TArray240;
    Money: TArray240;
    Pollution: TArray240;
    Crime: TArray240;
  private
    ResMax: Integer;
    ComMax: Integer;
    IndMax: Integer;
  public
    constructor Create;
  end;




  TMicropolis = class(TMapCity)
  public



	// full size arrays
   //	map : array of array of char;





    crimeMem: TInt2DArray;
 {
	 * For each 2x2 section of the city, the crime level of the city (0-250).
	 * 0 is no crime; 250 is maximum crime.
	 * Updated each cycle by crimeScan(); affects land value.
}   


 	// quarter-size arrays

{
	 * For each 4x4 section of the city, an integer representing the natural
	 * land features in the vicinity of this part of the city.
}
      terrainMem : TInt2DArray;//array of array of Integer;
 
	// eighth-size arrays

{
	 * For each 8x8 section of the city, the rate of growth.
	 * Capped to a number between -200 and 200.
	 * Used for reporting purposes only; the number has no affect.
}
     






    autoBudget: Boolean;
    simSpeed: TSpeed;
    history : THistory;

   

    roadPercent: Double;
    policePercent: Double;
    firePercent: Double;


    centerMassX: Integer;
    centerMassY: Integer;

    evaluation: TCityEval;

    // Assuming a generic list for sprites
    sprites: TList<TSprite>;
    financialHistory: TList<TFinancialHistory>;
    listeners: TList<IListener>;
    mapListeners: TList<IMapListener>;
    earthquakeListeners: TList<IEarthquakeListener>;

    procedure  AddListener(const L: IListener);
    procedure  RemoveListener(const L: IListener);
    procedure  AddMapListener(const L: IMapListener);
    procedure  RemoveMapListener(const L: IMapListener);
    procedure  AddEarthquakeListener(const L: IEarthquakeListener);
    procedure  RemoveEarthquakeListener(const L: IEarthquakeListener);
    procedure CalculateCenterMass;
    function  GetResValve: Integer;
    function  GetComValve: Integer;
    function  GetIndValve: Integer;
    procedure  ToggleAutoBulldoze;
    procedure  ToggleDisasters;
    procedure  ToggleAutoBudget;
    procedure SaveToFile(const FileName: string);   // Placeholder
    procedure  Load(const filename: string);
    procedure  FireWholeMapChanged;
    procedure  SetFunds(totalFunds: Integer);
    function   QueryZoneStatus(xpos, ypos: Integer): TZoneStatus;
    procedure Animate;
    function  IsBudgetTime: Boolean;
    procedure MakeFire;
    procedure  MakeMonster;
    procedure  MakeMonsterAt(xPos, yPos: Integer);
    procedure  MakeTornado;
    procedure  MakeFlood;
    function   MakeMeltdown: Boolean;
    procedure  MakeEarthquake;
    procedure  SetSpeed(newSpeed: TSpeed);
    function   GenerateBudget: TBudgetNumbers;
    constructor Create;  overload; //override;
    constructor Create(Width, Height: Integer);  overload;

  private

    autoGo: Boolean;



    lastRoadTotal: Integer;
    lastRailTotal: Integer;
    lastTotalPop: Integer;
    lastFireStationCount: Integer;
    lastPoliceCount: Integer;


    crimeMaxLocationX: Integer;
    crimeMaxLocationY: Integer;


    crashLocation: TCityLocation;


    crimeRamp: Integer;
    polluteRamp: Integer;

    taxEffect: Integer;



    cashFlow: Integer;

    newPower: Boolean;

  

    scycle: Integer;
    fcycle: Integer;

    FTileBehaviors : TDictionary<string, TTileBehavior>;




    procedure InitValues;
    procedure LoadHistoryArrayV1(arrayToLoad: TArray240; dis: TStream);
    procedure LoadHistoryArrayV2(arrayToLoad: TArray240; inXML: IXMLNode);
    procedure WriteHistoryArray(tagName: string; arrayToWrite: TArray240; outXML: IXMLNode);
    procedure  FireCensusChanged;
    procedure  FireCityMessage(const Msg: TMicropolisMessage; const Loc: TCityLocation);
    procedure  FireCitySound(const Sound: TSound; const Loc: TCityLocation);
    procedure  FireEvaluationChanged;
    procedure  FireDemandChanged;
    procedure  FireEarthquakeStarted;

    procedure  FireMapAnimation;
    procedure  FireMapOverlayDataChanged(OverlayDataType: TMapState);
    procedure  FireOptionsChanged;
    procedure  FireSpriteMoved(Sprite: TSprite);
    procedure  FireTileChanged(XPos, YPos: Integer);

 
    procedure  LoadMisc_v2(inXML: IXMLNode);
    procedure  Load_v1(inStream: TStream);
    procedure  Load_v2(filename: String);
    procedure  MapScan(x0, x1: Integer);
    procedure  MapScanTile(xpos, ypos: Integer);
    procedure  Save(xmlWriter: IXMLNode);
    procedure  TakeCensus;
    procedure  TakeCensus2;

    procedure Init(Width, Height: Integer);
    procedure Simulate(Mod16: Integer);
    procedure SendMessageAt(Amessage: TMicropolisMessage; x, y: Integer);
    procedure InitTileBehaviors;
    procedure Step;
    procedure ClearCensus;
    function  ComputePopDen(X, Y: Integer; Tile: Word): Integer;
    function  DoSmooth(const Tem: TInt2DArray): TInt2DArray;
    procedure SetValves;


    procedure PopDenScan;
    procedure DistIntMarket;
    procedure DecROGMem;
    procedure DecTrafficMem;
    procedure CrimeScan;
    procedure DoDisasters;
    function SmoothFirePoliceMap(const OMap: TInt2DArray): TInt2DArray;
    procedure FireAnalysis;
    function TestForCond(var Loc: TCityLocation; Dir: Integer): Boolean;
    function MovePowerLocation(var Loc: TCityLocation; Dir: Integer): Boolean;
    procedure PtlScan;
    procedure PowerScan;
    function  SmoothTerrain(const qtem: TInt2DArray): TInt2DArray;
    procedure CollectTaxPartial;
    procedure CollectTax;
    function StrToBoolDef(const S: string; Def: Boolean): Boolean;
    procedure LoadBudget_v2(inXML: IXMLNode);
    procedure LoadCityTime_v2(inXML: IXMLNode);
    procedure LoadMisc_v1(dis: TStream);
    procedure WriteMisc(outXML: IXMLNode);
    procedure LoadMap_v1(dis: TStream);
    procedure LoadMap_v2(inReader: IXMLNode);
    procedure WriteMap(outWriter: IXMLNode);
    function GetDisCC(x, y: Integer): Integer;
    procedure CheckPowerMap;

    procedure  MakeSound(x, y: Integer; sound: TSound);
    procedure  AnimateTiles;
    procedure  MoveObjects;


    procedure  SetFire;
    procedure  CheckGrowth;
    procedure  DoMessages;
    procedure  SendMessage(Amessage: TMicropolisMessage);


    procedure  SetGameLevel(newLevel: Integer);

    function  GetAnimationCycle: Integer;


end;




//var


implementation


constructor TMicropolis.Create;
begin
  inherited Create;
  Self.Create(DEFAULT_WIDTH, DEFAULT_HEIGHT);
end;

constructor TMicropolis.Create(Width, Height: Integer);
begin
  inherited Create;
  PRNG := TRandom.Create;
  budget := TCityBudget.Create;
  evaluation := TCityEval.Create(Self); // Assuming TCityEval has a constructor accepting TMicropolis
  history := THistory.Create;
  listeners := TList<IListener>.Create;
  mapListeners := TList<IMapListener>.Create;
  earthquakeListeners := TList<IEarthquakeListener>.Create;
  sprites := TList<TSprite>.Create;
  financialHistory := TList<TFinancialHistory>.Create;
  InitValues;
  Init(Width, Height);
  InitTileBehaviors;
end;


procedure TMicropolis.InitValues;
begin
 // budget stuff
	cityTax := 7;
	roadPercent := 1.0;
	policePercent := 1.0;
	firePercent := 1.0;

  taxEffect := 7;
  roadEffect := 32;
	policeEffect := 1000;
	fireEffect := 1000; 
	
	listeners := TList<IListener>.Create;
  mapListeners := TList<IMapListener>.Create;
  earthquakeListeners := TList<IEarthquakeListener>.Create;
end;

procedure TMicropolis.Init(Width, Height: Integer);
var
  hX, hY, qX, qY, smX, smY: Integer;
begin
  // Set up primary maps (not declared in interface; add if needed)
  SetLength(Map, Height, Width);
  SetLength(PowerMap, Height, Width);

  hX := (Width + 1) div 2;
  hY := (Height + 1) div 2;

  SetLength(LandValueMem, hY, hX);
  SetLength(PollutionMem, hY, hX);
  SetLength(CrimeMem, hY, hX);
  SetLength(PopDensity, hY, hX);
  SetLength(TrfDensity, hY, hX);

  qX := (Width + 3) div 4;
  qY := (Height + 3) div 4;

  SetLength(TerrainMem, qY, qX);

  smX := (Width + 7) div 8;
  smY := (Height + 7) div 8;

  SetLength(RateOGMem, smY, smX);
  SetLength(fireStMap, smY, smX);
  SetLength(FireRate, smY, smX);
  SetLength(PoliceMap, smY, smX);
  SetLength(PoliceMapEffect, smY, smX);
  SetLength(ComRate, smY, smX);

  CenterMassX := hX;
  CenterMassY := hY;
end;

procedure TMicropolis.InitTileBehaviors;
var

  bb : TDictionary<string,TTileBehavior>; //TTerrainBehavior>;//TTileBehavior>;

begin
  bb := TDictionary<string,TTileBehavior>.Create; //>.Create;//

  try
   
    bb.Add('FIRE', TTerrainBehavior.Create(Self, TerrainBehavior.TBehavior.FIRE));
    bb.Add('FLOOD', TTerrainBehavior.Create(Self, TerrainBehavior.TBehavior.FLOOD));
    bb.Add('RADIOACTIVE', TTerrainBehavior.Create(Self, TerrainBehavior.TBehavior.RADIOACTIVE));
    bb.Add('ROAD', TTerrainBehavior.Create(Self, TerrainBehavior.TBehavior.ROAD));
    bb.Add('RAIL', TTerrainBehavior.Create(Self, TerrainBehavior.TBehavior.RAIL));
    bb.Add('EXPLOSION', TTerrainBehavior.Create(Self, TerrainBehavior.TBehavior.EXPLOSION));

    bb.Add('RESIDENTIAL', TMapScanner.Create(Self, MapScanner.TBehavior.RESIDENTIAL));
    bb.Add('HOSPITAL_CHURCH', TMapScanner.Create(Self, MapScanner.TBehavior.HOSPITAL_CHURCH));
    bb.Add('COMMERCIAL', TMapScanner.Create(Self, MapScanner.TBehavior.COMMERCIAL));
    bb.Add('INDUSTRIAL', TMapScanner.Create(Self, MapScanner.TBehavior.INDUSTRIAL));
    bb.Add('COAL', TMapScanner.Create(Self, MapScanner.TBehavior.COAL));
    bb.Add('NUCLEAR', TMapScanner.Create(Self, MapScanner.TBehavior.NUCLEAR));
    bb.Add('FIRESTATION', TMapScanner.Create(Self, MapScanner.TBehavior.FIRESTATION));
    bb.Add('POLICESTATION', TMapScanner.Create(Self, MapScanner.TBehavior.POLICESTATION));
    bb.Add('STADIUM_EMPTY', TMapScanner.Create(Self, MapScanner.TBehavior.STADIUM_EMPTY));
    bb.Add('STADIUM_FULL', TMapScanner.Create(Self, MapScanner.TBehavior.STADIUM_FULL));
    bb.Add('AIRPORT', TMapScanner.Create(Self, MapScanner.TBehavior.AIRPORT));
    bb.Add('SEAPORT', TMapScanner.Create(Self, MapScanner.TBehavior.SEAPORT));

    // Free the old behaviors if they exist
    if Assigned(FTileBehaviors) then
    begin
      for var behavior in FTileBehaviors.Values do
        behavior.Free;
      FTileBehaviors.Free;
    end;

    FTileBehaviors := bb;
  except
    // Clean up if something goes wrong
    for var behavior in bb.Values do
      behavior.Free;
    bb.Free;
    raise;
  end;
end;



procedure TMicropolis.FireCensusChanged;
var
  L: IListener;
begin
  for L in listeners do
    L.CensusChanged;
end;

procedure TMicropolis.FireCityMessage(const Msg: TMicropolisMessage; const Loc: TCityLocation);
var
  L: IListener;
begin
  for L in listeners do
    L.CityMessage(Msg, Loc);
end;

procedure TMicropolis.FireCitySound(const Sound: TSound; const Loc: TCityLocation);
var
  L: IListener;
begin
  for L in listeners do
    L.CitySound(Sound, Loc);
end;

procedure TMicropolis.FireDemandChanged;
var
  L: IListener;
begin
  for L in listeners do
    L.DemandChanged;
end;

procedure TMicropolis.FireEarthquakeStarted;
var
  EL: IEarthquakeListener;
begin
  for EL in earthquakeListeners do
    EL.EarthquakeStarted;
end;

procedure TMicropolis.FireEvaluationChanged;
var
  L: IListener;
begin
  for L in listeners do
    L.EvaluationChanged;
end;



procedure TMicropolis.FireMapAnimation;
var
  ML: IMapListener;
begin
  for ML in mapListeners do
    ML.MapAnimation;
end;

procedure TMicropolis.FireMapOverlayDataChanged(OverlayDataType: TMapState);
var
  ML: IMapListener;
begin
  for ML in mapListeners do
    ML.MapOverlayDataChanged(OverlayDataType);
end;

procedure TMicropolis.FireOptionsChanged;
var
  L: IListener;
begin
  for L in listeners do
    L.OptionsChanged;
end;

procedure TMicropolis.FireSpriteMoved(Sprite: TSprite);
var
  ML: IMapListener;
begin
  for ML in mapListeners do
    ML.SpriteMoved(Sprite);
end;

procedure TMicropolis.FireTileChanged(XPos, YPos: Integer);
var
  ML: IMapListener;
begin
  for ML in mapListeners do
    ML.TileChanged(XPos, YPos);
end;

procedure TMicropolis.FireWholeMapChanged;
var
  ML: IMapListener;
begin
  for ML in mapListeners do
    ML.WholeMapChanged;
end;

procedure TMicropolis.AddListener(const L: IListener);
begin
  listeners.Add(L);
end;

procedure TMicropolis.RemoveListener(const L: IListener);
begin
  listeners.Remove(L);
end;

procedure TMicropolis.AddEarthquakeListener(const L: IEarthquakeListener);
begin
  earthquakeListeners.Add(L);
end;

procedure TMicropolis.RemoveEarthquakeListener(const L: IEarthquakeListener);
begin
  earthquakeListeners.Remove(L);
end;

procedure TMicropolis.AddMapListener(const L: IMapListener);
begin
  mapListeners.Add(L);
end;

procedure TMicropolis.RemoveMapListener(const L: IMapListener);
begin
  mapListeners.Remove(L);
end;






{*
 * Checks whether the next call to animate() will collect taxes and
 * process the budget.
 *}
function TMicropolis.IsBudgetTime: Boolean;
begin
  Result := (CityTime <> 0) and
            ((CityTime mod TAXFREQ) = 0) and
            (((fcycle + 1) mod 16) = 10) and
            (((acycle + 1) mod 2) = 0);
end;

procedure TMicropolis.Step;
begin
  fcycle := (fcycle + 1) mod 1024;
  Simulate(fcycle mod 16);
end;

procedure TMicropolis.ClearCensus;
var
  x, y: Integer;
begin
  PoweredZoneCount := 0;
  UnpoweredZoneCount := 0;
  FirePop := 0;
  RoadTotal := 0;
  RailTotal := 0;
  ResPop := 0;
  ComPop := 0;
  IndPop := 0;
  ResZoneCount := 0;
  ComZoneCount := 0;
  IndZoneCount := 0;
  HospitalCount := 0;
  ChurchCount := 0;
  PoliceCount := 0;
  FireStationCount := 0;
  StadiumCount := 0;
  CoalCount := 0;
  NuclearCount := 0;
  SeaportCount := 0;
  AirportCount := 0;
  PowerPlants.Clear;

  for y := 0 to High(FireStMap) do
  begin
    for x := 0 to High(FireStMap[y]) do
    begin
      FireStMap[y][x] := 0;
      PoliceMap[y][x] := 0;
    end;
  end;
end;

procedure TMicropolis.Simulate(Mod16: Integer);
var
  Band: Integer;
begin
  Band := GetWidth div 8;

  case Mod16 of
    0:
      begin
        scycle := (scycle + 1) mod 1024;
        Inc(cityTime);
        if (scycle mod 2 = 0) then
          SetValves;
        ClearCensus;
      end;

    1: MapScan(0 * Band, 1 * Band);
    2: MapScan(1 * Band, 2 * Band);
    3: MapScan(2 * Band, 3 * Band);
    4: MapScan(3 * Band, 4 * Band);
    5: MapScan(4 * Band, 5 * Band);
    6: MapScan(5 * Band, 6 * Band);
    7: MapScan(6 * Band, 7 * Band);
    8: MapScan(7 * Band, GetWidth);

    9:
      begin
        if (cityTime mod CENSUSRATE = 0) then
        begin
          TakeCensus;

          if (cityTime mod (CENSUSRATE * 12) = 0) then
            TakeCensus2;

          FireCensusChanged;
        end;

        CollectTaxPartial;

        if (cityTime mod TAXFREQ = 0) then
        begin
          CollectTax;
          Evaluation.CityEvaluation;
        end;
      end;

    10:
      begin
        if (scycle mod 5 = 0) then
          DecROGMem;
        DecTrafficMem;
        FireMapOverlayDataChanged(MapState.msTrafficOverlay);   // TDMAP
        FireMapOverlayDataChanged(MapState.msTRANSPORT);         // RDMAP
        FireMapOverlayDataChanged(MapState.msALL);               // ALMAP
        FireMapOverlayDataChanged(MapState.msRESIDENTIAL);       // REMAP
        FireMapOverlayDataChanged(MapState.msCOMMERCIAL);        // COMAP
        FireMapOverlayDataChanged(MapState.msINDUSTRIAL);        // INMAP
        DoMessages;
      end;

    11:
      begin
        PowerScan;
        FireMapOverlayDataChanged(MapState.msPOWEROVERLAY);
        NewPower := True;
      end;

    12: PtlScan;
    13: CrimeScan;
    14: PopDenScan;
    15:
      begin
        FireAnalysis;
        DoDisasters;
      end;

  else
    raise Exception.Create('Unreachable code reached in Simulate');
  end;
end;

function TMicropolis.ComputePopDen(X, Y: Integer; Tile: Word): Integer;
begin
  if Tile = RESCLR then
    Exit(DoFreePop(X, Y));

  if Ord(Tile) < COMBASE then
    Exit(ResidentialZonePop(Tile));

  if Ord(Tile) < INDBASE then
    Exit(CommercialZonePop(Tile) * 8);

  if Ord(Tile) < PORTBASE then
    Exit(IndustrialZonePop(Tile) * 8);

  Result := 0;
end;

function TMicropolis.DoSmooth(const Tem: TInt2DArray): TInt2DArray;
var
  H, W, X, Y, Z: Integer;
  Tem2: TInt2DArray;
begin
  H := Length(Tem);
  W := Length(Tem[0]);
  SetLength(Tem2, H, W);

  for Y := 0 to H - 1 do
  begin
    for X := 0 to W - 1 do
    begin
      Z := Tem[Y][X];
      if X > 0 then
        Inc(Z, Tem[Y][X - 1]);
      if X + 1 < W then
        Inc(Z, Tem[Y][X + 1]);
      if Y > 0 then
        Inc(Z, Tem[Y - 1][X]);
      if Y + 1 < H then
        Inc(Z, Tem[Y + 1][X]);
      Z := Z div 4;
      if Z > 255 then
        Z := 255;
      Tem2[Y][X] := Z;
    end;
  end;

  Result := Tem2;
end;

procedure TMicropolis.CalculateCenterMass;
begin
  PopDenScan;
end;

procedure TMicropolis.PopDenScan;
var
  X, Y, Den, Width, Height, ZoneCount, XTot, YTot: Integer;
  Tile: Word;
  Tem: TInt2DArray;
begin
  XTot := 0;
  YTot := 0;
  ZoneCount := 0;
  Width := GetWidth;
  Height := GetHeight;
  SetLength(Tem, (Height + 1) div 2, (Width + 1) div 2);

  for X := 0 to Width - 1 do
  begin
    for Y := 0 to Height - 1 do
    begin
      Tile := GetTile(X, Y);
      if IsZoneCenter(Tile) then
      begin
        Den := ComputePopDen(X, Y, Tile) * 8;
        if Den > 254 then Den := 254;
        Tem[Y div 2][X div 2] := Den;
        Inc(XTot, X);
        Inc(YTot, Y);
        Inc(ZoneCount);
      end;
    end;
  end;

  Tem := DoSmooth(Tem);
  Tem := DoSmooth(Tem);
  Tem := DoSmooth(Tem);

  for X := 0 to (Width + 1) div 2 - 1 do
    for Y := 0 to (Height + 1) div 2 - 1 do
      PopDensity[Y][X] := 2 * Tem[Y][X];

  DistIntMarket;

  if ZoneCount <> 0 then
  begin
    CenterMassX := XTot div ZoneCount;
    CenterMassY := YTot div ZoneCount;
  end
  else
  begin
    CenterMassX := (Width + 1) div 2;
    CenterMassY := (Height + 1) div 2;
  end;

  FireMapOverlayDataChanged(MapState.msPOPDENOVERLAY);
  FireMapOverlayDataChanged(MapState.msGROWTHRATEOVERLAY);
end;

procedure TMicropolis.DistIntMarket;
var
  X, Y, Z: Integer;
begin
  for Y := 0 to High(ComRate) do
    for X := 0 to High(ComRate[Y]) do
    begin
      Z := GetDisCC(X * 4, Y * 4);
      Z := 64 - (Z div 4);
      ComRate[Y][X] := Z;
    end;
end;

procedure TMicropolis.DecROGMem;
var
  X, Y, Z: Integer;
begin
  for Y := 0 to High(RateOGMem) do
    for X := 0 to High(RateOGMem[Y]) do
    begin
      Z := RateOGMem[Y][X];
      if Z = 0 then Continue;

      if Z > 0 then
      begin
        Dec(RateOGMem[Y][X]);
        if Z > 200 then
          RateOGMem[Y][X] := 200;
      end
      else if Z < 0 then
      begin
        Inc(RateOGMem[Y][X]);
        if Z < -200 then
          RateOGMem[Y][X] := -200;
      end;
    end;
end;

procedure TMicropolis.DecTrafficMem;
var
  X, Y, Z: Integer;
begin
  for Y := 0 to High(TrfDensity) do
    for X := 0 to High(TrfDensity[Y]) do
    begin
      Z := TrfDensity[Y][X];
      if Z <> 0 then
      begin
        if Z > 200 then
          TrfDensity[Y][X] := Z - 34
        else if Z > 24 then
          TrfDensity[Y][X] := Z - 24
        else
          TrfDensity[Y][X] := 0;
      end;
    end;
end;

procedure TMicropolis.CrimeScan;
var
  SX, SY, HX, HY, Z, Val, Count, Sum, CMax: Integer;
begin
  PoliceMap := SmoothFirePoliceMap(PoliceMap);
  PoliceMap := SmoothFirePoliceMap(PoliceMap);
  PoliceMap := SmoothFirePoliceMap(PoliceMap);

  for SY := 0 to High(PoliceMap) do
    for SX := 0 to High(PoliceMap[SY]) do
      PoliceMapEffect[SY][SX] := PoliceMap[SY][SX];

  Count := 0;
  Sum := 0;
  CMax := 0;

  for HY := 0 to High(LandValueMem) do
    for HX := 0 to High(LandValueMem[HY]) do
    begin
      Val := LandValueMem[HY][HX];
      if Val <> 0 then
      begin
        Inc(Count);
        Z := 128 - Val + PopDensity[HY][HX];
        Z := Min(300, Z);
        Dec(Z, PoliceMap[HY div 4][HX div 4]);
        Z := Min(250, Z);
        Z := Max(0, Z);
        CrimeMem[HY][HX] := Z;

        Inc(Sum, Z);
        if (Z > CMax) or ((Z = CMax) and (PRNG.NextInt(4) = 0)) then
        begin
          CMax := Z;
          CrimeMaxLocationX := HX * 2;
          CrimeMaxLocationY := HY * 2;
        end;
      end
      else
        CrimeMem[HY][HX] := 0;
    end;

  if Count <> 0 then
    CrimeAverage := Sum div Count
  else
    CrimeAverage := 0;

  FireMapOverlayDataChanged(MapState.msPOLICEOVERLAY);
end;
procedure TMicropolis.DoDisasters;
const
  DisChance: array[0..2] of Integer = (480, 240, 60);
var
  R: Integer;
begin
  if FloodCnt > 0 then
    Dec(FloodCnt);

  if NoDisasters then
    Exit;

  if PRNG.NextInt(DisChance[GameLevel] + 1) <> 0 then
    Exit;

  R := PRNG.NextInt(9);
  case R of
    0, 1: SetFire;
    2, 3: MakeFlood;
    4: ; // no disaster
    5: MakeTornado;
    6: MakeEarthquake;
    7, 8:
      if PollutionAverage > 60 then
        MakeMonster;
  end;
end;

function TMicropolis.SmoothFirePoliceMap(const OMap: TInt2DArray): TInt2DArray;
var
  SX, SY, Edge, X, Y: Integer;
  NMap: TInt2DArray;
begin
  SY := Length(OMap);
  if SY=0 then SX := 0
          else SX := Length(OMap[0]);
  SetLength(NMap, SY, SX);

  for Y := 0 to SY - 1 do
  begin
    for X := 0 to SX - 1 do
    begin
      Edge := 0;
      if X > 0 then Inc(Edge, OMap[Y][X - 1]);
      if X + 1 < SX then Inc(Edge, OMap[Y][X + 1]);
      if Y > 0 then Inc(Edge, OMap[Y - 1][X]);
      if Y + 1 < SY then Inc(Edge, OMap[Y + 1][X]);

      Edge := (Edge div 4) + OMap[Y][X];
      NMap[Y][X] := Edge div 2;
    end;
  end;

  Result := NMap;
end;

procedure TMicropolis.FireAnalysis;
var
  X, Y: Integer;
begin
  FireStMap := SmoothFirePoliceMap(FireStMap);
  FireStMap := SmoothFirePoliceMap(FireStMap);
  FireStMap := SmoothFirePoliceMap(FireStMap);

  for Y := 0 to High(FireStMap) do
    for X := 0 to High(FireStMap[Y]) do
      FireRate[Y][X] := FireStMap[Y][X];

  FireMapOverlayDataChanged(MapState.msFIREOVERLAY);
end;

function TMicropolis.TestForCond(var Loc: TCityLocation; Dir: Integer): Boolean;
var
  XSave, YSave: Integer;
  T: Word;
begin
  XSave := Loc.X;
  YSave := Loc.Y;

  Result := False;
  if MovePowerLocation(Loc, Dir) then
  begin
    T := GetTile(Loc.X, Loc.Y);
    Result := IsConductive(T) and
              (T <> TileConstants.NUCLEAR) and
              (T <> TileConstants.POWERPLANT) and
              (not HasPower(Loc.X, Loc.Y));
  end;

  Loc.X := XSave;
  Loc.Y := YSave;
end;

function TMicropolis.MovePowerLocation(var Loc: TCityLocation; Dir: Integer): Boolean;
begin
  case Dir of
    0:
      if Loc.Y > 0 then
      begin
        Dec(Loc.Y);
        Exit(True);
      end;
    1:
      if Loc.X + 1 < GetWidth then
      begin
        Inc(Loc.X);
        Exit(True);
      end;
    2:
      if Loc.Y + 1 < GetHeight then
      begin
        Inc(Loc.Y);
        Exit(True);
      end;
    3:
      if Loc.X > 0 then
      begin
        Dec(Loc.X);
        Exit(True);
      end;
    4: Exit(True); // No move, still valid
  end;
  Result := False;
end;

procedure TMicropolis.PowerScan;
var
  Loc: TCityLocation;
  aDir, conNum, dir: Integer;
  numPower, maxPower: Integer;
begin
  // Clear powerMap (2D array of booleans)
  for var y := Low(PowerMap) to High(PowerMap) do
    for var x := Low(PowerMap[y]) to High(PowerMap[y]) do
      PowerMap[y][x] := False;

  // Brownouts based on total number of power plants, not connected ones
  maxPower := CoalCount * 700 + NuclearCount * 2000;
  numPower := 0;

  // Process power plants queue/stack
  while PowerPlants.Count > 0 do
  begin
    Loc := PowerPlants.Pop; // Remove last CityLocation from stack/list
    aDir := 4;

    repeat
      Inc(numPower);
      if numPower > maxPower then
      begin
        SendMessage(MicropolisMessage.BROWNOUTS_REPORT);
        Exit;
      end;

      MovePowerLocation(Loc, aDir);
      PowerMap[Loc.Y][Loc.X] := True;

      conNum := 0;
      dir := 0;
      while (dir < 4) and (conNum < 2) do
      begin
        if TestForCond(Loc, dir) then
        begin
          Inc(conNum);
          aDir := dir;
        end;
        Inc(dir);
      end;

      if conNum > 1 then
        PowerPlants.Push(TCityLocation.Create(Loc.X, Loc.Y));

    until conNum = 0;
  end;
end;






procedure TMicropolis.PtlScan;

var
  qX, qY: Integer;
  qtem: TInt2DArray;
  tem: TInt2DArray;
  LandValueTotal, LandValueCount: Integer;
  X, Y, MX, MY, PLevel, LVFlag, ZX, ZY, Tile, Dis, Z: Integer;
  PCount, PTotal, PMax: Integer;
begin
  const HWLDX = (GetWidth + 1) div 2;
  const HWLDY = (GetHeight + 1) div 2;
  qX := (GetWidth + 3) div 4;
  qY := (GetHeight + 3) div 4;
  SetLength(qtem, qY, qX);

  LandValueTotal := 0;
  LandValueCount := 0;

  SetLength(tem, HWLDY, HWLDX);

  for X := 0 to HWLDX - 1 do
  begin
    for Y := 0 to HWLDY - 1 do
    begin
      PLevel := 0;
      LVFlag := 0;
      ZX := 2 * X;
      ZY := 2 * Y;

      for MX := ZX to ZX + 1 do
        for MY := ZY to ZY + 1 do
        begin
          Tile := GetTile(MX, MY);
          if Tile <> DIRT then
          begin
            if Tile < RUBBLE then
            begin
              // Natural land features increase terrainMem
              Inc(qtem[Y div 2][X div 2], 15);
              Continue;
            end;

            Inc(PLevel, GetPollutionValue(Tile));
            if IsConstructed(Tile) then
              Inc(LVFlag);
          end;
        end;

      if PLevel < 0 then
        PLevel := 250;
      if PLevel > 255 then
        PLevel := 255;

      tem[Y][X] := PLevel;

      if LVFlag <> 0 then
      begin
        // Land value equation
        Dis := 34 - GetDisCC(X, Y);
        Dis := Dis * 4 + TerrainMem[Y div 2][X div 2] - PollutionMem[Y][X];
        if CrimeMem[Y][X] > 190 then
          Dec(Dis, 20);

        if Dis > 250 then
          Dis := 250;
        if Dis < 1 then
          Dis := 1;

        LandValueMem[Y][X] := Dis;
        Inc(LandValueTotal, Dis);
        Inc(LandValueCount);
      end
      else
        LandValueMem[Y][X] := 0;
    end;
  end;

  if LandValueCount <> 0 then
    LandValueAverage := LandValueTotal div LandValueCount
  else
    LandValueAverage := 0;

  tem := DoSmooth(tem);
  tem := DoSmooth(tem);

  PCount := 0;
  PTotal := 0;
  PMax := 0;

  for X := 0 to HWLDX - 1 do
    for Y := 0 to HWLDY - 1 do
    begin
      Z := tem[Y][X];
      PollutionMem[Y][X] := Z;
      if Z <> 0 then
      begin
        Inc(PCount);
        Inc(PTotal, Z);
        if (Z > PMax) or ((Z = PMax) and (PRNG.NextInt(4) = 0)) then
        begin
          PMax := Z;
          PollutionMaxLocationX := 2 * X;
          PollutionMaxLocationY := 2 * Y;
        end;
      end;
    end;

  if PCount <> 0 then
    PollutionAverage := PTotal div PCount
  else
    PollutionAverage := 0;

  TerrainMem := SmoothTerrain(qtem);

  FireMapOverlayDataChanged(MapState.msPOLLUTEOVERLAY);
  FireMapOverlayDataChanged(MapState.msLANDVALUEOVERLAY);
end;




constructor THistory.Create;
begin
  inherited Create;
  // Optionally initialize arrays or variables here
  CityTime := 0;
  ResMax := 0;
  ComMax := 0;
  IndMax := 0;
  FillChar(Res, SizeOf(Res), 0);
  FillChar(Com, SizeOf(Com), 0);
  FillChar(Ind, SizeOf(Ind), 0);
  FillChar(Money, SizeOf(Money), 0);
  FillChar(Pollution, SizeOf(Pollution), 0);
  FillChar(Crime, SizeOf(Crime), 0);
end;



procedure TMicropolis.SetValves;
const
  BIRTH_RATE = 0.02;
var
  normResPop, employment, migration, births, projectedResPop: Double;
  temp, laborBase, internalMarket, projectedComPop, projectedIndPop: Double;
  resRatio, comRatio, indRatio: Double;
  z, z2: Integer;
begin
  normResPop := resPop / 8.0;
  totalPop := Trunc(normResPop + comPop + indPop);

  if normResPop <> 0.0 then
    employment := (history.Com[1] + history.Ind[1]) / normResPop
  else
    employment := 1;

  migration := normResPop * (employment - 1);
  births := normResPop * BIRTH_RATE;
  projectedResPop := normResPop + migration + births;

  temp := history.Com[1] + history.Ind[1];
  if temp <> 0.0 then
    laborBase := history.Res[1] / temp
  else
    laborBase := 1;

  // clamp laborBase to between 0.0 and 1.3
  if laborBase < 0.0 then
    laborBase := 0.0
  else if laborBase > 1.3 then
    laborBase := 1.3;

  internalMarket := (normResPop + comPop + indPop) / 3.7;
  projectedComPop := internalMarket * laborBase;

  z := gameLevel;
  temp := 1.0;
  case z of
    0: temp := 1.2;
    1: temp := 1.1;
    2: temp := 0.98;
  end;

  projectedIndPop := indPop * laborBase * temp;
  if projectedIndPop < 5.0 then
    projectedIndPop := 5.0;

  if normResPop <> 0 then
    resRatio := projectedResPop / normResPop
  else
    resRatio := 1.3;

  if comPop <> 0 then
    comRatio := projectedComPop / comPop
  else
    comRatio := projectedComPop;

  if indPop <> 0 then
    indRatio := projectedIndPop / indPop
  else
    indRatio := projectedIndPop;

  if resRatio > 2.0 then
    resRatio := 2.0;

  if comRatio > 2.0 then
    comRatio := 2.0;

  if indRatio > 2.0 then
    indRatio := 2.0;

  z2 := taxEffect + gameLevel;
  if z2 > 20 then
    z2 := 20;

  resRatio := (resRatio - 1) * 600 + TaxTable[z2];
  comRatio := (comRatio - 1) * 600 + TaxTable[z2];
  indRatio := (indRatio - 1) * 600 + TaxTable[z2];

  Inc(resValve, Trunc(resRatio));
  Inc(comValve, Trunc(comRatio));
  Inc(indValve, Trunc(indRatio));

  if resValve > 2000 then
    resValve := 2000
  else if resValve < -2000 then
    resValve := -2000;

  if comValve > 1500 then
    comValve := 1500
  else if comValve < -1500 then
    comValve := -1500;

  if indValve > 1500 then
    indValve := 1500
  else if indValve < -1500 then
    indValve := -1500;

  if resCap and (resValve > 0) then
    resValve := 0;

  if comCap and (comValve > 0) then
    comValve := 0;

  if indCap and (indValve > 0) then
    indValve := 0;

  fireDemandChanged;
end;

function TMicropolis.SmoothTerrain(const qtem: TInt2DArray): TInt2DArray;
var
  QWX, QWY: Integer;
  x, y, z: Integer;
begin
  QWY := Length(qtem);
  if QWY = 0 then Exit(nil);
  QWX := Length(qtem[0]);

  SetLength(Result, QWY, QWX);
  for y := 0 to QWY - 1 do
  begin
    for x := 0 to QWX - 1 do
    begin
      z := 0;
      if x > 0 then
        Inc(z, qtem[y][x-1]);
      if x + 1 < QWX then
        Inc(z, qtem[y][x+1]);
      if y > 0 then
        Inc(z, qtem[y-1][x]);
      if y + 1 < QWY then
        Inc(z, qtem[y+1][x]);
      
      Result[y][x] := (z div 4) + (qtem[y][x] div 2);
    end;
  end;
end;

function TMicropolis.GetDisCC(x, y: Integer): Integer;
var
  xdis, ydis, z: Integer;
begin
  Assert((x >= 0) and (x <= GetWidth div 2));
  Assert((y >= 0) and (y <= GetHeight div 2));

  xdis := Abs(x - centerMassX div 2);
  ydis := Abs(y - centerMassY div 2);

  z := xdis + ydis;
  if z > 32 then
    Result := 32
  else
    Result := z;
end;



procedure TMicropolis.MapScan(x0, x1: Integer);
var
  x, y: Integer;
begin
  for x := x0 to x1 - 1 do
    for y := 0 to GetHeight - 1 do
      MapScanTile(x, y);
end;

procedure TMicropolis.MapScanTile(xpos, ypos: Integer);
var
  tile: Integer;
  behaviorStr: string;
  b: TTileBehavior;
begin
  tile := GetTile(xpos, ypos);
  behaviorStr := GetTileBehavior(tile);
  if behaviorStr = '' then
    Exit; // nothing to do

  if FtileBehaviors.TryGetValue(behaviorStr, b) then
    b.ProcessTile(xpos, ypos)
  else
    raise Exception.Create('Unknown behavior: ' + behaviorStr);
end;



procedure TMicropolis.TakeCensus;
var
  i: Integer;
  resMax, comMax, indMax: Integer;
  moneyScaled: Integer;
begin
  resMax := 0;
  comMax := 0;
  indMax := 0;

  for i := 118 downto 0 do
  begin
    if history.res[i] > resMax then
      resMax := history.res[i];

    if history.com[i] > comMax then
      comMax := history.com[i];

    if history.ind[i] > indMax then
      indMax := history.ind[i];

    if i < 118 then
    begin
      history.res[i + 1] := history.res[i];
      history.com[i + 1] := history.com[i];
      history.ind[i + 1] := history.ind[i];
      history.crime[i + 1] := history.crime[i];
      history.pollution[i + 1] := history.pollution[i];
      history.money[i + 1] := history.money[i];
    end;
  end;

  history.resMax := resMax;
  history.comMax := comMax;
  history.indMax := indMax;

  history.res[0] := resPop div 8;
  history.com[0] := comPop;
  history.ind[0] := indPop;

  crimeRamp := crimeRamp + (crimeAverage - crimeRamp) div 4;
  history.crime[0] := Min(255, Round(crimeRamp));

  polluteRamp := polluteRamp + (pollutionAverage - polluteRamp) div 4;
  history.pollution[0] := Min(255, Round(polluteRamp));

  moneyScaled := cashFlow div 20 + 128;
  if moneyScaled < 0 then
    moneyScaled := 0
  else if moneyScaled > 255 then
    moneyScaled := 255;

  history.money[0] := moneyScaled;
  history.cityTime := cityTime;

  if hospitalCount < resPop div 256 then
    needHospital := 1
  else if hospitalCount > resPop div 256 then
    needHospital := -1
  else
    needHospital := 0;

  if churchCount < resPop div 256 then
    needChurch := 1
  else if churchCount > resPop div 256 then
    needChurch := -1
  else
    needChurch := 0;
end;

procedure TMicropolis.TakeCensus2;
var
  i: Integer;
  resMax, comMax, indMax: Integer;
begin
  resMax := 0;
  comMax := 0;
  indMax := 0;

  for i := 238 downto 120 do
  begin
    if history.res[i] > resMax then
      resMax := history.res[i];
    if history.com[i] > comMax then
      comMax := history.com[i];
    if history.ind[i] > indMax then
      indMax := history.ind[i];

    if i < 238 then
    begin
      history.res[i + 1] := history.res[i];
      history.com[i + 1] := history.com[i];
      history.ind[i + 1] := history.ind[i];
      history.crime[i + 1] := history.crime[i];
      history.pollution[i + 1] := history.pollution[i];
      history.money[i + 1] := history.money[i];
    end;
  end;

  history.res[120] := resPop div 8;
  history.com[120] := comPop;
  history.ind[120] := indPop;

  history.crime[120] := history.crime[0];
  history.pollution[120] := history.pollution[0];
  history.money[120] := history.money[0];
end;

procedure TMicropolis.CollectTaxPartial;
var
  b: TBudgetNumbers;
begin
  lastRoadTotal := roadTotal;
  lastRailTotal := railTotal;
  lastTotalPop := totalPop;
  lastFireStationCount := fireStationCount;
  lastPoliceCount := policeCount;

  b := GenerateBudget;

  try
    budget.taxFund := budget.taxFund + b.taxIncome;
    budget.roadFundEscrow := budget.roadFundEscrow - b.roadFunded;
    budget.fireFundEscrow := budget.fireFundEscrow - b.fireFunded;
    budget.policeFundEscrow := budget.policeFundEscrow - b.policeFunded;

    taxEffect := Round(b.taxRate);
    if b.roadRequest <> 0 then
      roadEffect := Floor(32.0 * b.roadFunded / b.roadRequest)
    else
      roadEffect := 32;

    if b.policeRequest <> 0 then
      policeEffect := Floor(1000.0 * b.policeFunded / b.policeRequest)
    else
      policeEffect := 1000;

    if b.fireRequest <> 0 then
      fireEffect := Floor(1000.0 * b.fireFunded / b.fireRequest)
    else
      fireEffect := 1000;
  finally
    b.Free;
  end;
end;

procedure TMicropolis.CollectTax;
var
  revenue, expenses: Integer;
  hist: TFinancialHistory;
begin
  revenue := budget.taxFund div TAXFREQ;
  expenses := - (budget.roadFundEscrow + budget.fireFundEscrow + budget.policeFundEscrow) div TAXFREQ;

  //hist := TFinancialHistory.Create;
  try
    hist.cityTime := cityTime;
    hist.taxIncome := revenue;
    hist.operatingExpenses := expenses;

    cashFlow := revenue - expenses;
    Spend(-cashFlow);

    hist.totalFunds := budget.totalFunds;

    financialHistory.Insert(0, hist); // Add to start of list

    budget.taxFund := 0;
    budget.roadFundEscrow := 0;
    budget.fireFundEscrow := 0;
    budget.policeFundEscrow := 0;
  except
    //hist.Free;
    raise;
  end;
end;

function TMicropolis.GenerateBudget: TBudgetNumbers;
var
  yumDuckets: Integer;
begin
  Result := TBudgetNumbers.Create;

  Result.taxRate := Max(0, cityTax);
  Result.roadPercent := Max(0.0, roadPercent);
  Result.firePercent := Max(0.0, firePercent);
  Result.policePercent := Max(0.0, policePercent);

  Result.previousBalance := budget.totalFunds;

  Result.taxIncome := Round(lastTotalPop * landValueAverage / 120 * Result.taxRate * FLevels[gameLevel]);
  Assert(Result.taxIncome >= 0);

  Result.roadRequest := Round((lastRoadTotal + lastRailTotal * 2) * RLevels[gameLevel]);
  Result.fireRequest := FIRE_STATION_MAINTENANCE * lastFireStationCount;
  Result.policeRequest := POLICE_STATION_MAINTENANCE * lastPoliceCount;

  Result.roadFunded := Round(Result.roadRequest * Result.roadPercent);
  Result.fireFunded := Round(Result.fireRequest * Result.firePercent);
  Result.policeFunded := Round(Result.policeRequest * Result.policePercent);

  yumDuckets := budget.totalFunds + Result.taxIncome;
  Assert(yumDuckets >= 0);

  if yumDuckets >= Result.roadFunded then
  begin
    yumDuckets := yumDuckets - Result.roadFunded;
    if yumDuckets >= Result.fireFunded then
    begin
      yumDuckets := yumDuckets - Result.fireFunded;
      if yumDuckets >= Result.policeFunded then
      begin
        yumDuckets := yumDuckets - Result.policeFunded;
      end
      else
      begin
        Assert(Result.policeRequest <> 0);
        Result.policeFunded := yumDuckets;
        Result.policePercent := Result.policeFunded / Result.policeRequest;
        yumDuckets := 0;
      end;
    end
    else
    begin
      Assert(Result.fireRequest <> 0);
      Result.fireFunded := yumDuckets;
      Result.firePercent := Result.fireFunded / Result.fireRequest;
      Result.policeFunded := 0;
      Result.policePercent := 0.0;
      yumDuckets := 0;
    end;
  end
  else
  begin
    Assert(Result.roadRequest <> 0);
    Result.roadFunded := yumDuckets;
    Result.roadPercent := Result.roadFunded / Result.roadRequest;
    Result.fireFunded := 0;
    Result.firePercent := 0.0;
    Result.policeFunded := 0;
    Result.policePercent := 0.0;
  end;

  Result.operatingExpenses := Result.roadFunded + Result.fireFunded + Result.policeFunded;
  Result.newBalance := Result.previousBalance + Result.taxIncome - Result.operatingExpenses;
end;





procedure TMicropolis.LoadHistoryArrayV1(arrayToLoad: TArray240; dis: TStream);
var
  i: Integer;
  buf: array[0..1] of Byte;
  val: SmallInt;
begin
  for i := 0 to 239 do
  begin
    if dis.Read(buf, 2) <> 2 then
      raise Exception.Create('Unexpected end of stream');

    val := PSmallInt(@buf[0])^;
    arrayToLoad[i] := val;
  end;
end;

procedure TMicropolis.LoadHistoryArrayV2(arrayToLoad: TArray240; inXML: IXMLNode);
var
  textData,TagName: string;
  values: TArray<string>;
  i,j: Integer;

begin
  //Short term,long term
  // Assuming inXML points to the node containing the array text content
  try
  for i:=0 to inXML.ChildNodes.Count -1 do
   begin
     TagName := inXML.ChildNodes[i].LocalName;
     textData := inXML.ChildNodes[i].Text;
     values := textData.Split([' ', #13, #10], TStringSplitOptions.ExcludeEmpty);
     if TagName='shortTerm' then
       for j := 0 to 119 do  arrayToLoad[j] := StrToInt(values[j])
     else
       for j := 120 to 239 do  arrayToLoad[j] := StrToInt(values[j-120]);
   end;

  except
    raise Exception.Create('Not enough data in XML for history array');
  end;
end;

procedure TMicropolis.WriteHistoryArray(tagName: string; arrayToWrite: TArray240; outXML: IXMLNode);
var
  i: Integer;
  shortTermNode, longTermNode: IXMLNode;
  strBuilder: TStringBuilder;
begin
  // Create tagName node
  var tagNode := outXML.AddChild(tagName);

  // shortTerm element
  shortTermNode := tagNode.AddChild('shortTerm');
  strBuilder := TStringBuilder.Create;
  try
    for i := 0 to 119 do
      strBuilder.Append(' ').Append(IntToStr(arrayToWrite[i]));
    shortTermNode.Text := strBuilder.ToString;
  finally
    strBuilder.Free;
  end;

  // longTerm element
  longTermNode := tagNode.AddChild('longTerm');
  strBuilder := TStringBuilder.Create;
  try
    for i := 120 to 239 do
      strBuilder.Append(' ').Append(IntToStr(arrayToWrite[i]));
    longTermNode.Text := strBuilder.ToString;
  finally
    strBuilder.Free;
  end;
end;

function TMicropolis.StrToBoolDef(const S: string; Def: Boolean): Boolean;
begin
  if SameText(S, 'true') then
    Result := True
  else if SameText(S, 'false') then
    Result := False
  else
    Result := Def;
end;






procedure TMicropolis.LoadBudget_v2(inXML: IXMLNode);
begin
  budget.totalFunds := StrToIntDef(inXML.Attributes['funds'], 0);
  cityTax := StrToIntDef(inXML.Attributes['cityTax'], 7);
  policePercent := StrToFloatDef(inXML.Attributes['policePercent'], 0) / 100.0;
  firePercent := StrToFloatDef(inXML.Attributes['firePercent'], 0) / 100.0;
  roadPercent := StrToFloatDef(inXML.Attributes['roadPercent'], 0) / 100.0;

  //SkipToEndElement(inXML);

  if (cityTax < 0) or (cityTax > 20) then
    cityTax := 7;

  policePercent := EnsureRange(policePercent, 0.0, 1.0);
  firePercent := EnsureRange(firePercent, 0.0, 1.0);
  roadPercent := EnsureRange(roadPercent, 0.0, 1.0);
end;

procedure TMicropolis.LoadCityTime_v2(inXML: IXMLNode);
begin
  cityTime := StrToIntDef(inXML.Attributes['time'], 0);
  fcycle := StrToIntDef(inXML.Attributes['fcycle'], 0);
  acycle := StrToIntDef(inXML.Attributes['acycle'], 0);

 // SkipToEndElement(inXML);

  if cityTime < 0 then
    cityTime := 0;
end;

procedure TMicropolis.LoadMisc_v2(inXML: IXMLNode);
var
  allowDisastersStr: string;
begin
  crimeRamp := StrToIntDef(inXML.Attributes['crimeRamp'], 0);
  polluteRamp := StrToIntDef(inXML.Attributes['polluteRamp'], 0);
  landValueAverage := StrToIntDef(inXML.Attributes['landValueAverage'], 0);
  crimeAverage := StrToIntDef(inXML.Attributes['crimeAverage'], 0);
  pollutionAverage := StrToIntDef(inXML.Attributes['pollutionAverage'], 0);
  gameLevel := StrToIntDef(inXML.Attributes['gameLevel'], 0);
  autoBulldoze := StrToBoolDef(inXML.Attributes['autoBulldoze'], False);
  autoBudget := StrToBoolDef(inXML.Attributes['autoBudget'], False);
  autoGo := StrToBoolDef(inXML.Attributes['autoGo'], False);

  allowDisastersStr := inXML.Attributes['allowDisasters'];
  noDisasters := not StrToBoolDef(allowDisastersStr, True);

  simSpeed := SpeedFromString(inXML.Attributes['simSpeed']);

  //WriSkipToEndElement(inXML);

  if (gameLevel < 0) or (gameLevel > 2) then
    gameLevel := 0;

  // Reset capacity flags
  // resCap, comCap, indCap assumed defined elsewhere as Boolean fields
  // You can initialize here as needed
end;

procedure TMicropolis.LoadMisc_v1(dis: TStream);
var
  buf2: array[0..1] of Byte;
  buf4: array[0..3] of Byte;
  n, i: Integer;
  shortVal: SmallInt;
  intVal: Integer;
//begin
  // Helper to read a short (2 bytes, little-endian)
  function ReadShort: SmallInt;
  begin
    if dis.Read(buf2, 2) <> 2 then
      raise Exception.Create('Unexpected end of stream in LoadMisc_v1');
    Result := PSmallInt(@buf2[0])^;
  end;

  // Helper to read an int (4 bytes, little-endian)
  function ReadInt: Integer;
  begin
    if dis.Read(buf4, 4) <> 4 then
      raise Exception.Create('Unexpected end of stream in LoadMisc_v1');
    Result := PInteger(@buf4[0])^;
  end;

begin
  ReadShort(); // [0] ignored
  ReadShort(); // [1] externalMarket ignored

  resPop := ReadShort();  // [2]
  comPop := ReadShort();
  indPop := ReadShort();

  resValve := ReadShort(); // [5]
  comValve := ReadShort();
  indValve := ReadShort();

  cityTime := ReadInt();   // [8-9]

  crimeRamp := ReadShort();  // [10]
  polluteRamp := ReadShort();

  landValueAverage := ReadShort(); // [12]
  crimeAverage := ReadShort();
  pollutionAverage := ReadShort(); // [14]

  gameLevel := ReadShort();

  evaluation.cityClass := ReadShort();  // [16]
  evaluation.cityScore := ReadShort();

  for i := 18 to 49 do
    ReadShort(); // discard

  budget.totalFunds := ReadInt(); // [50-51]

  autoBulldoze := ReadShort() <> 0;  // 52
  autoBudget := ReadShort() <> 0;
  autoGo := ReadShort() <> 0;         // 54

  ReadShort(); // userSoundOn - ignored

  cityTax := ReadShort(); // 56
  // taxEffect assumed same as cityTax here if needed

  n := ReadShort();
  if (n >= 0) and (n <= 4) then
    simSpeed := TSpeed(n)
  else
    simSpeed := NORMAL;

  // Read and convert percentages (stored as int/65536)
  n := ReadInt(); // policePercent
  policePercent := n / 65536.0;

  n := ReadInt(); // firePercent
  firePercent := n / 65536.0;

  n := ReadInt(); // roadPercent
  roadPercent := n / 65536.0;

  for i := 64 to 119 do
    ReadShort(); // discard

  if cityTime < 0 then cityTime := 0;
  if (cityTax < 0) or (cityTax > 20) then cityTax := 7;
  if (gameLevel < 0) or (gameLevel > 2) then gameLevel := 0;
  if (evaluation.cityClass < 0) or (evaluation.cityClass > 5) then evaluation.cityClass := 0;
  if (evaluation.cityScore < 1) or (evaluation.cityScore > 999) then evaluation.cityScore := 500;

  // Reset capacity flags if needed
end;

procedure TMicropolis.WriteMisc(outXML: IXMLNode);
begin
  // population element
  with outXML.AddChild('population') do
  begin
    Attributes['resPop'] := IntToStr(resPop);
    Attributes['comPop'] := IntToStr(comPop);
    Attributes['indPop'] := IntToStr(indPop);
  end;

  // valves element
  with outXML.AddChild('valves') do
  begin
    Attributes['resValve'] := IntToStr(resValve);
    Attributes['comValve'] := IntToStr(comValve);
    Attributes['indValve'] := IntToStr(indValve);
  end;

  // cityTime element
  with outXML.AddChild('cityTime') do
  begin
    Attributes['time'] := IntToStr(cityTime);
    Attributes['fcycle'] := IntToStr(fcycle);
    Attributes['acycle'] := IntToStr(acycle);
  end;

  // misc element
  with outXML.AddChild('misc') do
  begin
    Attributes['crimeRamp'] := IntToStr(crimeRamp);
    Attributes['polluteRamp'] := IntToStr(polluteRamp);
    Attributes['landValueAverage'] := IntToStr(landValueAverage);
    Attributes['crimeAverage'] := IntToStr(crimeAverage);
    Attributes['pollutionAverage'] := IntToStr(pollutionAverage);
    Attributes['gameLevel'] := IntToStr(gameLevel);
    Attributes['autoBulldoze'] := BoolToStr(autoBulldoze, True);
    Attributes['autoBudget'] := BoolToStr(autoBudget, True);
    Attributes['autoGo'] := BoolToStr(autoGo, True);
    Attributes['simSpeed'] := GetSpeedName(simSpeed);
    Attributes['allowDisasters'] := BoolToStr(not noDisasters, True);
  end;

  // evaluation element
  with outXML.AddChild('evaluation') do
  begin
    Attributes['cityClass'] := IntToStr(evaluation.cityClass);
    Attributes['cityScore'] := IntToStr(evaluation.cityScore);
  end;

  // budget element
  with outXML.AddChild('budget') do
  begin
    Attributes['funds'] := IntToStr(budget.totalFunds);
    Attributes['cityTax'] := IntToStr(cityTax);
    Attributes['policePercent'] := FloatToStr(policePercent * 100);
    Attributes['firePercent'] := FloatToStr(firePercent * 100);
    Attributes['roadPercent'] := FloatToStr(roadPercent * 100);
  end;
end;


procedure TMicropolis.LoadMap_V1(Dis: TStream);
var
  x, y: Integer;
  z: SmallInt; // Equivalent to Java's short (16-bit signed integer)
  TileNumber: Integer;
  TileSpec: TTileSpec;
begin
  for x := 0 to DEFAULT_WIDTH - 1 do
  begin
    for y := 0 to DEFAULT_HEIGHT - 1 do
    begin
      // Read 16-bit value from stream
      Dis.ReadBuffer(z, SizeOf(SmallInt));

      // Clear specific bits (ZONEBIT, ANIMBIT, BULLBIT, BURNBIT, CONDBIT)
      z := z and not (1024 or 2048 or 4096 or 8192 or 16384);

      // Get tile specification
      TileSpec := TTiles.LoadByOrdinal(z and LOMASK);
      if TileSpec = nil then
        raise EStreamError.CreateFmt('Invalid tile ordinal at position (%d,%d)', [x, y]);

      // Combine bits and store in map
      Map[y][x] := (z and (not LOMASK) or TileSpec.TileNumber);
    end;
  end;
end;

procedure TMicropolis.LoadMap_v2(inReader: IXMLNode);
var
  tileUpgradeMap: TDictionary<string, string>;
  //mapList: TList<TArray<Byte>>;
  //tmpList: TList<string>;
  values,values2: TArray<string>;
  textData, tileName,TagName: string;
  row: TArray<Byte>;
  i, j, x,y,z: Integer;
  s_parts: TArray<string>;
  t: TTileSpec;
begin
  y:=0;
  for i:=0 to inReader.ChildNodes.Count -1 do
   begin
     TagName := inReader.ChildNodes[i].LocalName;
     if TagName='mapRow' then
       begin
         textData := inReader.ChildNodes[i].Text;
         values := textData.Split([' ', #13, #10], TStringSplitOptions.ExcludeEmpty);
         for x := 0 to DEFAULT_WIDTH - 1 do
           begin
             values2:=Values[x].Split([':'],TStringSplitOptions.ExcludeEmpty);
             map[y][x] := StrToInt(Values2[0]);
             if Length(Values2)>1 then
              if Values2[1]='pwr' then
               map[y][x] := map[y][x] or PWRBIT;
           end;
         inc(y);
       end;
   end;
  //Будет глючить при PWR.

//Выправить по Write
{
  tileUpgradeMap := TTiles.LoadTileUpgradeMap;
  mapList := TList<TArray<Byte>>.Create;
  try
    while (inReader.NodeType <> TXmlNodeType.ElementEnd) do
    begin
      inReader.Read;
      if (inReader.NodeType <> TXmlNodeType.Element) or (inReader.LocalName <> 'mapRow') then
      begin
        SkipToEndElement(inReader);
        Continue;
      end;

      tmpList := TXMLHelper.ReadElementText(inReader);
      //tmpList := TList<string>.Create;
      try
       // tmpList.AddRange(lineText.Split([' ']));
        SetLength(row, tmpList.Count);

        for i := 0 to tmpList.Count - 1 do
        begin
          s_parts := tmpList[i].Split([':']);
          tileName := s_parts[0];

          while tileUpgradeMap.ContainsKey(tileName) do
            tileName := tileUpgradeMap[tileName];

          t := TTiles.Load(tileName);
          if t = nil then
            raise EXMLStreamException.CreateFmt(
              'Unrecognized tile ''%s'' at map coordinates (%d,%d)',
              [s_parts[0], i, mapList.Count]
            );

          z := t.tileNumber;
          for j := 1 to High(s_parts) do
          begin
            if s_parts[j] = 'pwr' then
              z := z or PWRBIT
            else
              raise EXMLStreamException.CreateFmt(
                'Unrecognized tile modifier ''%s'' at map coordinates (%d,%d)',
                [s_parts[j], i, mapList.Count]
              );
          end;
          row[i] := z;
        end;

        mapList.Add(row);
      finally
        tmpList.Free;
      end;
    end;

    SetLength(map, mapList.Count);
    for i := 0 to mapList.Count - 1 do
      map[i] := mapList[i];
  finally
    mapList.Free;
  end;
  }
end;

procedure TMicropolis.WriteMap(outWriter: IXMLNode);

var
  i: Integer;
   x, y,z: Integer;
  //shortTermNode, longTermNode: IXMLNode;
  strBuilder: TStringBuilder;
  tagNode,tagNode2 : IXMLNode;
  S, tileStr: String;
begin
  // Create tagName node
  tagNode := outWriter.AddChild('map');
   for y := 0 to DEFAULT_HEIGHT - 1 do
  begin
    tagNode2 :=  tagNode.AddChild('mapRow');
    S:='';
    for x := 0 to DEFAULT_WIDTH - 1 do
    begin
      z := map[y][x];
      if x <> 0 then
        S:=S+' ';
      //else S := '';
      tileStr := TTiles.Get(z and LOMASK).name;
      S := s + tileStr;
      if (z and PWRBIT) = PWRBIT then
        S := S+':pwr';//tileStr;
    end;
    tagNode2.Text := S;
  end;



end;

procedure TMicropolis.Load(const filename: string);
var
  fs: TFileStream;
 // b1, b2: Byte;
  b : array[0..1] of Byte;
  header: array[0..127] of Byte;
begin
  fs := TFileStream.Create(filename, fmOpenRead or fmShareDenyWrite);
  try
    fs.Read(b,2);
    //b1 := fs.ReadByte;
   // b2 := fs.ReadByte;
    fs.Position := 0;

    if (b[0] = $3C) and (b[1] = $3F) then
    //if (b[0] = $1F) and (b[1] = $8B) then
    begin
      // Handle gzipped
      Load_v2(filename); // implement with gzip handling
    end
    else
    begin
      if fs.Size > 27120 then
      begin
        fs.ReadBuffer(header, 128); // skip SimCity header
      end;
      Load_v1(fs);
    end;
  finally
    fs.Free;
  end;
end;

procedure TMicropolis.CheckPowerMap;
var
  x, y, tile: Integer;
begin
  coalCount := 0;
  nuclearCount := 0;
  powerPlants.Clear;  //nil

  for y := 0 to High(map) do
  begin
    for x := 0 to High(map[y]) do
    begin
      tile := GetTile(x, y);
      if tile = TileConstants.NUCLEAR then
      begin
        Inc(nuclearCount);
        powerPlants.Push(TCityLocation.Create(x, y));
      end
      else if tile = TileConstants.POWERPLANT then
      begin
        Inc(coalCount);
        powerPlants.Push(TCityLocation.Create(x, y));
      end;
    end;
  end;

  PowerScan;
  newPower := True;
end;

procedure TMicropolis.Load_v2(filename: String);
var
 // z_in: TGZInputStream;
  //xmlReader: IXMLReader;
  XMLDoc : IXMLDocument;
  tagName: string;
  RootNode: IXMLNode;
  i:Integer;
begin
  XMLDoc := TXMLDocument.Create(nil);
  XMLDoc.LoadFromFile(filename);
  XMLDoc.Active := True;
  RootNode :=  XMLDoc.DocumentElement;
  for i:=0 to RootNode.ChildNodes.Count -1 do
    begin
      if RootNode.ChildNodes[i].NodeType <> TNodeType.ntElement then
        Continue;
      TagName := RootNode.ChildNodes[i].LocalName;
          if tagName = 'res-history' then
        LoadHistoryArrayV2(history.res, RootNode.ChildNodes[i])
      else if tagName = 'com-history' then
        LoadHistoryArrayV2(history.com, RootNode.ChildNodes[i])
      else if tagName = 'ind-history' then
        LoadHistoryArrayV2(history.ind, RootNode.ChildNodes[i])
      else if tagName = 'crime-history' then
        LoadHistoryArrayV2(history.crime, RootNode.ChildNodes[i])
      else if tagName = 'pollution-history' then
        LoadHistoryArrayV2(history.pollution, RootNode.ChildNodes[i])
      else if tagName = 'money-history' then
        LoadHistoryArrayV2(history.money, RootNode.ChildNodes[i])
      else if tagName = 'population' then
      begin
        resPop := StrToInt(RootNode.ChildNodes[i].GetAttribute('resPop'));
        comPop := StrToInt(RootNode.ChildNodes[i].GetAttribute('comPop'));
        indPop := StrToInt(RootNode.ChildNodes[i].GetAttribute('indPop'));
        //SkipToEndElement(xmlReader);
      end
      else if tagName = 'valves' then
      begin
        resValve := StrToInt(RootNode.ChildNodes[i].GetAttribute('resValve'));
        comValve := StrToInt(RootNode.ChildNodes[i].GetAttribute('comValve'));
        indValve := StrToInt(RootNode.ChildNodes[i].GetAttribute('indValve'));
        //SkipToEndElement(xmlReader);
      end
      else if tagName = 'cityTime' then
        LoadCityTime_v2(RootNode.ChildNodes[i])
      else if tagName = 'misc' then
        LoadMisc_v2(RootNode.ChildNodes[i])
      else if tagName = 'evaluation' then
      begin
        evaluation.cityClass := StrToInt(RootNode.ChildNodes[i].GetAttribute('cityClass'));
        evaluation.cityScore := StrToInt(RootNode.ChildNodes[i].GetAttribute('cityScore'));

        if (evaluation.cityClass < 0) or (evaluation.cityClass > 5) then
          evaluation.cityClass := 0;
        if (evaluation.cityScore < 1) or (evaluation.cityScore > 999) then
          evaluation.cityScore := 500;

        //SkipToEndElement(xmlReader);
      end
      else if tagName = 'budget' then
        LoadBudget_v2(RootNode.ChildNodes[i])
      else if tagName = 'map' then
        LoadMap_v2(RootNode.ChildNodes[i])
      else
        //SkipToEndElement(xmlReader);
    end;

  //AddChild('micropolis');
  //fs := TFileStream.Create(filename, fmCreate);
  //try
  //  Save(RootNode);


 // Делать по Writer
  {
  z_in := TGZInputStream.Create(inStream);
  try
    xmlReader := CreateXMLReader(z_in, 'UTF-8');
    xmlReader.Read;
    xmlReader.MoveToContent;

    if not (xmlReader.NodeType = TXmlNodeType.Element) or (xmlReader.LocalName <> 'micropolis') then
      raise EIOException.Create('Unrecognized file format');

    while xmlReader.Read and (xmlReader.NodeType <> TXmlNodeType.EndElement) do
    begin
      if xmlReader.NodeType <> TXmlNodeType.Element then
        Continue;

      tagName := xmlReader.LocalName;

      if tagName = 'res-history' then
        LoadHistoryArray_v2(history.res, xmlReader)
      else if tagName = 'com-history' then
        LoadHistoryArray_v2(history.com, xmlReader)
      else if tagName = 'ind-history' then
        LoadHistoryArray_v2(history.ind, xmlReader)
      else if tagName = 'crime-history' then
        LoadHistoryArray_v2(history.crime, xmlReader)
      else if tagName = 'pollution-history' then
        LoadHistoryArray_v2(history.pollution, xmlReader)
      else if tagName = 'money-history' then
        LoadHistoryArray_v2(history.money, xmlReader)
      else if tagName = 'population' then
      begin
        resPop := StrToInt(xmlReader.GetAttribute('resPop'));
        comPop := StrToInt(xmlReader.GetAttribute('comPop'));
        indPop := StrToInt(xmlReader.GetAttribute('indPop'));
        SkipToEndElement(xmlReader);
      end
      else if tagName = 'valves' then
      begin
        resValve := StrToInt(xmlReader.GetAttribute('resValve'));
        comValve := StrToInt(xmlReader.GetAttribute('comValve'));
        indValve := StrToInt(xmlReader.GetAttribute('indValve'));
        SkipToEndElement(xmlReader);
      end
      else if tagName = 'cityTime' then
        LoadCityTime_v2(xmlReader)
      else if tagName = 'misc' then
        LoadMisc_v2(xmlReader)
      else if tagName = 'evaluation' then
      begin
        evaluation.cityClass := StrToInt(xmlReader.GetAttribute('cityClass'));
        evaluation.cityScore := StrToInt(xmlReader.GetAttribute('cityScore'));

        if (evaluation.cityClass < 0) or (evaluation.cityClass > 5) then
          evaluation.cityClass := 0;
        if (evaluation.cityScore < 1) or (evaluation.cityScore > 999) then
          evaluation.cityScore := 500;

        SkipToEndElement(xmlReader);
      end
      else if tagName = 'budget' then
        LoadBudget_v2(xmlReader)
      else if tagName = 'map' then
        LoadMap_v2(xmlReader)
      else
        SkipToEndElement(xmlReader);
    end;

    xmlReader := nil; // ensures proper release
  except
    on E: EXMLStreamException do
      raise EIOException.Create(E.Message);
  end;
  }

  CheckPowerMap;
  FireWholeMapChanged;
  FireDemandChanged;
  FireFundsChanged;
end;

procedure TMicropolis.Load_v1(inStream: TStream);
//var
  //dis: TBinaryReader;
begin
 // dis := TBinaryReader.Create(inStream, TEncoding.Default, False);
  try
    LoadHistoryArrayv1(history.res,inStream); //dis);
    LoadHistoryArrayv1(history.com, inStream);
    LoadHistoryArrayv1(history.ind,inStream);
    LoadHistoryArrayv1(history.crime, inStream);
    LoadHistoryArrayv1(history.pollution, inStream);
    LoadHistoryArrayv1(history.money, inStream);
    LoadMisc_v1(inStream);
    LoadMap_v1(inStream);
  finally
    //dis.Free;
  end;

  CheckPowerMap;
  FireWholeMapChanged;
  FireDemandChanged;
  FireFundsChanged;
end;



procedure TMicropolis.SaveToFile(const filename: string);
var
  fs: TFileStream;
  XMLDoc: IXMLDocument;
  RootNode: IXMLNode;
begin
  //tagNode := outWriter.AddChild('map');
  XMLDoc:= NewXMLDocument;
  XMLDoc.Encoding := 'utf-8';
  XMLDoc.Options := [doNodeAutoIndent];
 // XMLDoc := TXMLDocument.Create(nil);
  RootNode := XMLDoc.AddChild('micropolis');
  //fs := TFileStream.Create(filename, fmCreate);
  try
    Save(RootNode);
    XMLDoc.SaveToFile(filename);
  finally
    //fs.Free;
  end;
end;

procedure TMicropolis.Save(xmlWriter: IXMLNode);
//var
 // z_out: TGZOutputStream;

begin
 // z_out := TGZOutputStream.Create(outStream);
  try
   // xmlWriter := CreateXMLWriter(z_out, 'UTF-8');
   // xmlWriter.WriteStartDocument;
   //

    WriteHistoryArray('res-history', history.res, xmlWriter);
    WriteHistoryArray('com-history', history.com, xmlWriter);
    WriteHistoryArray('ind-history', history.ind, xmlWriter);
    WriteHistoryArray('crime-history', history.crime, xmlWriter);
    WriteHistoryArray('pollution-history', history.pollution, xmlWriter);
    WriteHistoryArray('money-history', history.money, xmlWriter);

    WriteMisc(xmlWriter);
    WriteMap(xmlWriter);

   // xmlWriter.WriteEndElement; // micropolis
    //xmlWriter.WriteEndDocument;
  finally
   // xmlWriter := nil;
   // z_out.Free; // required since XMLWriter doesn’t close stream
  end;
end;

procedure TMicropolis.ToggleAutoBudget;
begin
  autoBudget := not autoBudget;
  FireOptionsChanged;
end;

procedure TMicropolis.ToggleAutoBulldoze;
begin
  autoBulldoze := not autoBulldoze;
  FireOptionsChanged;
end;

procedure TMicropolis.ToggleDisasters;
begin
  noDisasters := not noDisasters;
  FireOptionsChanged;
end;

procedure TMicropolis.SetSpeed(newSpeed: TSpeed);
begin
  simSpeed := newSpeed;
  FireOptionsChanged;
end;

procedure TMicropolis.Animate;
begin
  Inc(acycle);
  acycle := acycle mod 960;

  if (acycle mod 2 = 0) then
    Step;

  MoveObjects;
  AnimateTiles;
end;


procedure TMicropolis.MoveObjects;
var
  sprite: TSprite;
  i: Integer;
begin
  for i := sprites.Count - 1 downto 0 do
  begin
    sprite := sprites[i];
    sprite.Move;

    if sprite.Frame = 0 then
      sprites.Delete(i);
  end;
end;

procedure TMicropolis.AnimateTiles;
var
  x, y, flags: Integer;
  tileValue: Word;
  spec: TTileSpec;
begin
  for y := 0 to High(map) do
  begin
    for x := 0 to High(map[y]) do
    begin
      tileValue := map[y][x];
      spec := TTiles.Get(Ord(tileValue) and LOMASK);
      if Assigned(spec) and Assigned(spec.AnimNext) then
      begin
        flags := Ord(tileValue) and ALLBITS;
        SetTile(x, y, spec.AnimNext.TileNumber or flags);
      end;
    end;
  end;

  FireMapAnimation;
end;



procedure TMicropolis.MakeSound(x, y: Integer; sound: TSound);
begin
  FireCitySound(sound, TCityLocation.Create(x, y));
end;

procedure TMicropolis.MakeEarthquake;
var
  x, y, time, z: Integer;
begin
  MakeSound(centerMassX, centerMassY, TSound.Create(EXPLOSION_LOW));
  FireEarthquakeStarted;
  SendMessageAt(EARTHQUAKE_REPORT, centerMassX, centerMassY);

  time := PRNG.NextInt(701) + 300;

  for z := 0 to time - 1 do
  begin
    x := PRNG.NextInt(GetWidth);
    y := PRNG.NextInt(GetHeight);

    if TestBounds(x, y) then
    begin
      if IsVulnerable(GetTile(x, y)) then
      begin
        if PRNG.NextInt(4) <> 0 then
          SetTile(x, y, RUBBLE + PRNG.NextInt(4))
        else
          SetTile(x, y, TileConstants.FIRE);
      end;
    end;
  end;
end;

procedure TMicropolis.SetFire;
var
  x, y, t: Integer;
begin
  x := PRNG.NextInt(GetWidth);
  y := PRNG.NextInt(GetHeight);
  t := GetTile(x, y);

  if IsArsonable(t) then
  begin
    SetTile(x, y, TileConstants.FIRE);
    crashLocation := TCityLocation.Create(x, y);
    SendMessageAt(FIRE_REPORT, x, y);
  end;
end;
procedure TMicropolis.MakeFire;
var
  x, y, tile, t: Integer;
begin
  // Forty attempts at finding a place to start fire
  for t := 0 to 39 do
  begin
    x := PRNG.NextInt(GetWidth);
    y := PRNG.NextInt(GetHeight);
    tile := GetTile(x, y);

    if (not IsZoneCenter(tile)) and IsCombustible(tile) then
    begin
      if (tile > 21) and (tile < LASTZONE) then
      begin
        SetTile(x, y, TileConstants.FIRE);
        SendMessageAt(FIRE_REPORT, x, y);
        Exit;
      end;
    end;
  end;
end;

function TMicropolis.MakeMeltdown: Boolean;
var
  candidates: TList<TCityLocation>;
  x, y, i: Integer;
  p: TCityLocation;
begin
  candidates := TList<TCityLocation>.Create;
  try
    for y := 0 to High(map) do
      for x := 0 to High(map[y]) do
        if GetTile(x, y) = TileConstants.NUCLEAR then
          candidates.Add(TCityLocation.Create(x, y));

    if candidates.Count = 0 then
      Exit(False);

    i := PRNG.NextInt(candidates.Count);
    p := candidates[i];
    DoMeltdown(p.X, p.Y);
    Result := True;
  finally
    candidates.Free;
  end;
end;

procedure TMicropolis.MakeMonster;
var
  monster: TMonsterSprite;
  x, y, t, i: Integer;
begin
  monster := TMonsterSprite(GetSprite(SpriteKind.GOD));
  if Assigned(monster) then
  begin
    // Already have a monster in town
    monster.SoundCount := 1;
    monster.Count := 1000;
    monster.Flag := False;
    monster.DestX := PollutionMaxLocationX;
    monster.DestY := PollutionMaxLocationY;
    Exit;
  end;

  // Try to find a suitable starting spot for monster
  for i := 0 to 299 do
  begin
    x := PRNG.NextInt(GetWidth - 19) + 10;
    y := PRNG.NextInt(GetHeight - 9) + 5;
    t := GetTile(x, y);

    if t = RIVER then
    begin
      MakeMonsterAt(x, y);
      Exit;
    end;
  end;

  // No "nice" location found, just start in center of map
  MakeMonsterAt(GetWidth div 2, GetHeight div 2);
end;

procedure TMicropolis.MakeMonsterAt(xPos, yPos: Integer);
begin
  Assert(not HasSprite(SpriteKind.GOD));
  Sprites.Add(TMonsterSprite.Create(Self, xPos, yPos));
end;

procedure TMicropolis.MakeTornado;
var
  tornado: TTornadoSprite;
  xPos, yPos: Integer;
begin
  tornado := TTornadoSprite(GetSprite(SpriteKind.TOR));
  if Assigned(tornado) then
  begin
    // Already have a tornado, so extend the duration
    tornado.FCount := 200;
    Exit;
  end;

  xPos := PRNG.NextInt(GetWidth - 19) + 10;
  yPos := PRNG.NextInt(GetHeight - 19) + 10;
  Sprites.Add(TTornadoSprite.Create(Self, xPos, yPos));
  SendMessageAt(TORNADO_REPORT, xPos, yPos);
end;

procedure TMicropolis.MakeFlood;
const
  DX: array[0..3] of Integer = (0, 1, 0, -1);
  DY: array[0..3] of Integer = (-1, 0, 1, 0);
var
  x, y, tile, xx, yy, c, t, z: Integer;
begin
  for z := 0 to 299 do
  begin
    x := PRNG.NextInt(GetWidth);
    y := PRNG.NextInt(GetHeight);
    tile := GetTile(x, y);

    if IsRiverEdge(tile) then
    begin
      for t := 0 to 3 do
      begin
        xx := x + DX[t];
        yy := y + DY[t];

        if TestBounds(xx, yy) then
        begin
          c := map[yy][xx];
          if IsFloodable(c) then
          begin
            SetTile(xx, yy, TileConstants.FLOOD);
            floodCnt := 30;
            SendMessageAt(FLOOD_REPORT, xx, yy);
            floodX := xx;
            floodY := yy;
            Exit;
          end;
        end;
      end;
    end;
  end;
end;






procedure TMicropolis.CheckGrowth;
var
  newPop: Integer;
  msg: TMicropolisMessage;
begin
  if cityTime mod 4 = 0 then
  begin
    newPop := (resPop + comPop * 8 + indPop * 8) * 20;

    if lastCityPop <> 0 then
    begin
      msg := TMicropolisMessage.None;

      if (lastCityPop < 500000) and (newPop >= 500000) then
        msg := POP_500K_REACHED
      else if (lastCityPop < 100000) and (newPop >= 100000) then
        msg := POP_100K_REACHED
      else if (lastCityPop < 50000) and (newPop >= 50000) then
        msg := POP_50K_REACHED
      else if (lastCityPop < 10000) and (newPop >= 10000) then
        msg := POP_10K_REACHED
      else if (lastCityPop < 2000) and (newPop >= 2000) then
        msg := POP_2K_REACHED;

      if msg <> None then
        SendMessage(msg);
    end;

    lastCityPop := newPop;
  end;
end;

procedure TMicropolis.DoMessages;
var
  totalZoneCount, powerCount, z, TM: Integer;
  ratio: Double;
begin
  // MORE (scenario stuff, not implemented)

  CheckGrowth;

  totalZoneCount := resZoneCount + comZoneCount + indZoneCount;
  powerCount := nuclearCount + coalCount;

  z := cityTime mod 64;

  case z of
    1:
      if (totalZoneCount div 4 >= resZoneCount) then
        SendMessage(NEED_RES);

    5:
      if (totalZoneCount div 8 >= comZoneCount) then
        SendMessage(NEED_COM);

    10:
      if (totalZoneCount div 8 >= indZoneCount) then
        SendMessage(NEED_IND);

    14:
      if (totalZoneCount > 10) and (totalZoneCount * 2 > roadTotal) then
        SendMessage(NEED_ROADS);

    18:
      if (totalZoneCount > 50) and (totalZoneCount > railTotal) then
        SendMessage(NEED_RAILS);

    22:
      if (totalZoneCount > 10) and (powerCount = 0) then
        SendMessage(NEED_POWER);

    26:
      begin
        resCap := (resPop > 500) and (stadiumCount = 0);
        if resCap then
          SendMessage(NEED_STADIUM);
      end;

    28:
      begin
        indCap := (indPop > 70) and (seaportCount = 0);
        if indCap then
          SendMessage(NEED_SEAPORT);
      end;

    30:
      begin
        comCap := (comPop > 100) and (airportCount = 0);
        if comCap then
          SendMessage(NEED_AIRPORT);
      end;

    32:
      begin
        TM := unpoweredZoneCount + poweredZoneCount;
        if TM <> 0 then
        begin
          ratio := poweredZoneCount / TM;
          if ratio < 0.7 then
            SendMessage(BLACKOUTS);
        end;
      end;

    35:
      if (pollutionAverage > 60) then
        SendMessage(HIGH_POLLUTION); // Consider raising to 80

    42:
      if (crimeAverage > 100) then
        SendMessage(HIGH_CRIME);

    45:
      if (totalPop > 60) and (fireStationCount = 0) then
        SendMessage(NEED_FIRESTATION);

    48:
      if (totalPop > 60) and (policeCount = 0) then
        SendMessage(NEED_POLICE);

    51:
      if (cityTax > 12) then
        SendMessage(HIGH_TAXES);

    54:
      if (roadEffect < 20) and (roadTotal > 30) then
        SendMessage(ROADS_NEED_FUNDING);

    57:
      if (fireEffect < 700) and (totalPop > 20) then
        SendMessage(FIRE_NEED_FUNDING);

    60:
      if (policeEffect < 700) and (totalPop > 20) then
        SendMessage(POLICE_NEED_FUNDING);

    63:
      if (trafficAverage > 60) then
        SendMessage(HIGH_TRAFFIC);

    else
      // nothing
  end;
end;


procedure TMicropolis.SendMessage(Amessage: TMicropolisMessage);
begin
  FireCityMessage(Amessage, nil);
end;

procedure TMicropolis.SendMessageAt(Amessage: TMicropolisMessage; x, y: Integer);
begin
  FireCityMessage(Amessage, TCityLocation.Create(x, y));
end;

function TMicropolis.QueryZoneStatus(xpos, ypos: Integer): TZoneStatus;
var
  z: Integer;
begin
 // Result := TZoneStatus.Create;

  Result.building := GetDescriptionNumber(GetTile(xpos, ypos));

  z := (popDensity[ypos div 2][xpos div 2] div 64) mod 4;
  Result.popDensity := z + 1;

  z := landValueMem[ypos div 2][xpos div 2];
  if z < 30 then
    z := 4
  else if z < 80 then
    z := 5
  else if z < 150 then
    z := 6
  else
    z := 7;
  Result.landValue := z + 1;

  z := (crimeMem[ypos div 2][xpos div 2] div 64) mod 4 + 8;
  Result.crimeLevel := z + 1;

  z := Max(13, (pollutionMem[ypos div 2][xpos div 2] div 64) mod 4 + 12);
  Result.pollution := z + 1;

  z := rateOGMem[ypos div 8][xpos div 8];
  if z < 0 then
    z := 16
  else if z = 0 then
    z := 17
  else if z <= 100 then
    z := 18
  else
    z := 19;
  Result.growthRate := z + 1;
end;

function TMicropolis.GetResValve: Integer;
begin
  Result := resValve;
end;

function TMicropolis.GetComValve: Integer;
begin
  Result := comValve;
end;

function TMicropolis.GetIndValve: Integer;
begin
  Result := indValve;
end;

procedure TMicropolis.SetGameLevel(newLevel: Integer);
begin
  Assert(TGameLevel.IsValid(newLevel));
  gameLevel := newLevel;
  FireOptionsChanged;
end;

procedure TMicropolis.SetFunds(totalFunds: Integer);
begin
  budget.totalFunds := totalFunds;
end;

function TMicropolis.GetAnimationCycle: Integer;
begin
  Result := aCycle;
end;


















end.