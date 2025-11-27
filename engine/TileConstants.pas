unit TileConstants;

interface
uses Tiles,TileSpec,CityDimension;
const
  CLEAR = -1;
	DIRT = 0;
	  RIVER = 2;
	  REDGE = 3;
	  CHANNEL = 4;
	  RIVEDGE = 5;
	  FIRSTRIVEDGE = 5;
	  LASTRIVEDGE = 20;
	  TREEBASE = 21;
	  WOODS_LOW = TREEBASE;
	  WOODS = 37;
	  WOODS_HIGH = 39;
	  WOODS2 = 40;
	  WOODS5 = 43;
	  RUBBLE = 44;
	  LASTRUBBLE = 47;
	  FLOOD = 48;
	  LASTFLOOD = 51;
	  RADTILE = 52;
	  FIRE = 56;
	  ROADBASE = 64;
	  HBRIDGE = 64;
	  VBRIDGE = 65;
	  ROADS = 66;
	  ROADS2 = 67;
	ROADS3 = 68;
	ROADS4 = 69;
	ROADS5 = 70;
	    ROADS6 = 71;
	    ROADS7 = 72;
	    ROADS8 = 73;
	    ROADS9 = 74;
	    ROADS10 = 75;
	  INTERSECTION = 76;
	  HROADPOWER = 77;
	  VROADPOWER = 78;
	  BRWH = 79;  //horz bridge, open
	  LTRFBASE = 80;
	  BRWV = 95;  //vert bridge, open
	  HTRFBASE = 144;
	    LASTROAD = 206;
	  POWERBASE = 208;
	  HPOWER = 208;    //underwater power-line
	  VPOWER = 209;
	  LHPOWER = 210;
	  LVPOWER = 211;
	  LVPOWER2 = 212;
	    LVPOWER3 = 213;
	    LVPOWER4 = 214;
	    LVPOWER5 = 215;
	    LVPOWER6 = 216;
	    LVPOWER7 = 217;
	    LVPOWER8 = 218;
	    LVPOWER9 = 219;
	    LVPOWER10 = 220;
	  RAILHPOWERV = 221;
	  RAILVPOWERH = 222;
	  LASTPOWER = 222;
	  RAILBASE = 224;
	  HRAIL = 224;//underwater rail (horz)
	  VRAIL = 225;//underwater rail (vert)
	  LHRAIL = 226;
	  LVRAIL = 227;
	  LVRAIL2 = 228;
	    LVRAIL3 = 229;
	    LVRAIL4 = 230;
	    LVRAIL5 = 231;
	    LVRAIL6 = 232;
	    LVRAIL7 = 233;
	    LVRAIL8 = 234;
	    LVRAIL9 = 235;
	    LVRAIL10 = 236;
	  HRAILROAD = 237;
	  VRAILROAD = 238;
	  LASTRAIL = 238;
	  RESBASE = 240;
	  RESCLR = 244;
	  HOUSE = 249;
	  LHTHR = 249;  //12 house tiles
	  HHTHR = 260;
	  RZB = 265; //residential zone base
	  HOSPITAL = 409;
	  CHURCH = 418;
	  COMBASE = 423;
	  COMCLR = 427;
	  CZB = 436; //commercial zone base
	  INDBASE = 612;
	  INDCLR = 616;
	  IZB = 625; //industrial zone base
	  PORTBASE = 693;
	  PORT = 698;
	  AIRPORT = 716;
	  POWERPLANT = 750;
	  FIRESTATION = 765;
	  POLICESTATION = 774;
	  STADIUM = 784;
	  FULLSTADIUM = 800;
	  NUCLEAR = 816;
	  LASTZONE = 826;
    LIGHTNINGBOLT = 827;
	  HBRDG0 = 828;   //draw bridge tiles (horz)
	  HBRDG1 = 829;
	  HBRDG2 = 830;
	  HBRDG3 = 831;
	  FOUNTAIN = 840;
	  TINYEXP = 860;
	    LASTTINYEXP = 867;
	  FOOTBALLGAME1 = 932;
	  FOOTBALLGAME2 = 940;
	  VBRDG0 = 948;   //draw bridge tiles (vert)
	  VBRDG1 = 949;
	  VBRDG2 = 950;
	  VBRDG3 = 951;
	LAST_TILE = 956;
PWRBIT: Word = $8000; // Bit 15
  ALLBITS: Word = $FC00;// Upper 6 bits mask (bits 10–15)
  LOMASK: Word = $03FF; // Lower 10 bits mask
var
  RoadTable: array[0..15] of Byte = (
    ROADS, ROADS2, ROADS, ROADS3,
    ROADS2, ROADS2, ROADS4, ROADS8,
    ROADS, ROADS6, ROADS, ROADS7,
    ROADS5, ROADS10, ROADS9, INTERSECTION
  );

  RailTable: array[0..15] of Byte = (
    LHRAIL, LVRAIL, LHRAIL, LVRAIL2,
    LVRAIL, LVRAIL, LVRAIL3, LVRAIL7,
    LHRAIL, LVRAIL5, LHRAIL, LVRAIL6,
    LVRAIL4, LVRAIL9, LVRAIL8, LVRAIL10
  );

  WireTable: array[0..15] of Byte = (
    LHPOWER, LVPOWER, LHPOWER, LVPOWER2,
    LVPOWER, LVPOWER, LVPOWER3, LVPOWER7,
    LHPOWER, LVPOWER5, LHPOWER, LVPOWER6,
    LVPOWER4, LVPOWER9, LVPOWER8, LVPOWER10
  );

function CanAutoBulldozeRRW(tileValue: Integer): Boolean;
function CanAutoBulldozeZ(tileValue: Byte): Boolean;
function GetTileBehavior(tile: Integer): string;
function GetDescriptionNumber(tile: Integer): Integer;
function GetPollutionValue(tile: Integer): Integer;
function IsAnimated(tile: Integer): Boolean;
function IsArsonable(tile: Integer): Boolean;
function IsCombustible(tile: Integer): Boolean;
function IsConductive(tile: Integer): Boolean;
function IsIndestructible(tile: Integer): Boolean;
function IsOverWater(tile: Integer): Boolean;
function IsRubble(tile: Integer): Boolean;
function IsTree(tile: Byte): Boolean;
function IsVulnerable(tile: Integer): Boolean;
function GetZoneSizeFor(Tile: Integer): TCityDimension;
function IsConstructed(Tile: Integer): Boolean; 
function IsRiverEdge(Tile: Integer): Boolean; 
function IsDozeable(Tile: Integer): Boolean; 
function IsFloodable(Tile: Integer): Boolean; 
function IsRoad(Tile: Integer): Boolean; 
function IsRoadDynamic(Tile: Integer): Boolean; 
function RoadConnectsEast(Tile: Integer): Boolean; 
function RoadConnectsNorth(Tile: Integer): Boolean; 
function RoadConnectsSouth(Tile: Integer): Boolean; 
function RoadConnectsWest(Tile: Integer): Boolean; 
function IsRail(Tile: Integer): Boolean; 
function IsRailDynamic(Tile: Integer): Boolean; 
function RailConnectsEast(Tile: Integer): Boolean; 
function RailConnectsNorth(Tile: Integer): Boolean; 
function RailConnectsSouth(Tile: Integer): Boolean; 
function RailConnectsWest(Tile: Integer): Boolean; 
function IsWireDynamic(Tile: Integer): Boolean; 
function WireConnectsEast(Tile: Integer): Boolean; 
function WireConnectsNorth(Tile: Integer): Boolean; 
function WireConnectsSouth(Tile: Integer): Boolean; 
function WireConnectsWest(Tile: Integer): Boolean; 
function IsCommercialZone(Tile: Integer): Boolean; 
function IsIndustrialZone(Tile: Integer): Boolean; 
function IsResidentialClear(Tile: Integer): Boolean; 
function IsResidentialZone(Tile: Integer): Boolean; 
function IsResidentialZoneAny(Tile: Integer): Boolean; 
function IsZoneAny(Tile: Integer): Boolean; 
function IsZoneCenter(Tile: Integer): Boolean; 
function NeutralizeRoad(Tile: Integer): Integer; 
function ResidentialZonePop(Tile: Integer): Integer; 
function CommercialZonePop(Tile: Integer): Integer; 
function IndustrialZonePop(Tile: Integer): Integer; 
 

implementation
function CanAutoBulldozeRRW(tileValue: Integer): Boolean;
begin
  Result := (tileValue >= FIRSTRIVEDGE) and (tileValue <= LASTRUBBLE) or
  (tileValue >= TINYEXP) and (tileValue <= LASTTINYEXP);
end;

function CanAutoBulldozeZ(tileValue: Byte): Boolean;
begin
  Result := (tileValue >= FIRSTRIVEDGE) and (tileValue <= LASTRUBBLE) or
  (tileValue >= POWERBASE + 2) and (tileValue <= POWERBASE + 12) or
  (tileValue >= TINYEXP) and (tileValue <= LASTTINYEXP);
end;

function GetTileBehavior(tile: Integer): string;
var
  ts: TTileSpec;
begin
  Assert((tile and LOMASK) = tile);
  ts := TTiles.Get(tile);
  if Assigned(ts) then
    Result := ts.GetAttribute('behavior')  //Attributes['behavior']
  else
    Result := '';
end;

function GetDescriptionNumber(tile: Integer): Integer;
var
  ts: TTileSpec;
begin
  Assert((tile and LOMASK) = tile);
  ts := TTiles.Get(tile);
  if Assigned(ts) then
    Result := ts.GetDescriptionNumber
  else
    Result := -1;
end;

function GetPollutionValue(tile: Integer): Integer;
var
  spec: TTileSpec;
begin
  Assert((tile and LOMASK) = tile);
  spec := TTiles.Get(tile);
  if Assigned(spec) then
    Result := spec.GetPollutionValue
  else
    Result := 0;
end;

function IsAnimated(tile: Integer): Boolean;
var
  spec: TTileSpec;
begin
  Assert((tile and LOMASK) = tile);
  spec := TTiles.Get(tile);
  Result := Assigned(spec) and Assigned(spec.AnimNext);
end;

function IsArsonable(tile: Integer): Boolean;
begin
  Assert((tile and LOMASK) = tile);
  Result := (not IsZoneCenter(tile)) and
  (tile >= LHTHR) and (tile <= LASTZONE);
end;

function IsCombustible(tile: Integer): Boolean;
var
  spec: TTileSpec;
begin
  Assert((tile and LOMASK) = tile);
  spec := TTiles.Get(tile);
  Result := Assigned(spec) and spec.CanBurn;
end;

function IsConductive(tile: Integer): Boolean;
var
  spec: TTileSpec;
begin
  Assert((tile and LOMASK) = tile);
  spec := TTiles.Get(tile);
  Result := Assigned(spec) and spec.CanConduct;
end;

function IsIndestructible(tile: Integer): Boolean;
begin
  Assert((tile and LOMASK) = tile);
  Result := (tile >= FLOOD) and (tile < ROADBASE);
end;

function IsOverWater(tile: Integer): Boolean;
var
  spec: TTileSpec;
begin
  Assert((tile and LOMASK) = tile);
  spec := TTiles.Get(tile);
  Result := Assigned(spec) and spec.OverWater;
end;

function IsRubble(tile: Integer): Boolean;
begin
  Assert((tile and LOMASK) = tile);
  Result := (tile >= RUBBLE) and (tile <= LASTRUBBLE);
end;

function IsTree(tile: Byte): Boolean;
begin
  Assert((Ord(tile) and LOMASK) = Ord(tile));
  Result := (tile >= WOODS_LOW) and (tile <= WOODS_HIGH);
end;

function IsVulnerable(tile: Integer): Boolean;
begin
  Assert((tile and LOMASK) = tile);
  if (tile < RESBASE) or (tile > LASTZONE) or IsZoneCenter(tile) then
    Result := False
  else
    Result := True;
end;

function GetZoneSizeFor(Tile: Integer): TCityDimension;
var
  Spec: TTileSpec;
begin
  Assert(IsZoneCenter(Tile));
  Assert((Tile and LOMASK) = Tile);
  Spec := TTiles.Get(Tile);
  if Assigned(Spec) then
    Result := Spec.GetBuildingSize
  else
    Result := nil;
end;

function IsConstructed(Tile: Integer): Boolean;
begin
  Assert((Tile and LOMASK) = Tile);
  Result := (Tile >= 0) and (Tile >= ROADBASE);
end;

function IsRiverEdge(Tile: Integer): Boolean;
begin
  Assert((Tile and LOMASK) = Tile);
  Result := (Tile >= FIRSTRIVEDGE) and (Tile <= LASTRIVEDGE);
end;

function IsDozeable(Tile: Integer): Boolean;
var
  Spec: TTileSpec;
begin
  Assert((Tile and LOMASK) = Tile);
  Spec := TTiles.Get(Tile);
  Result := Assigned(Spec) and Spec.CanBulldoze;
end;

function IsFloodable(Tile: Integer): Boolean;
begin
  Assert((Tile and LOMASK) = Tile);
  Result := (Tile = DIRT) or (IsDozeable(Tile) and IsCombustible(Tile));
end;

function IsRoad(Tile: Integer): Boolean;
begin
  Assert((Tile and LOMASK) = Tile);
  Result := ((Tile >= ROADBASE) and (Tile < POWERBASE)) or
            (Tile = HRAILROAD) or (Tile = VRAILROAD);
end;

function IsRoadDynamic(Tile: Integer): Boolean;
var
  Tmp: Integer;
begin
  Tmp := NeutralizeRoad(Tile);
  Result := (Tmp >= ROADS) and (Tmp <= INTERSECTION);
end;

function RoadConnectsEast(Tile: Integer): Boolean;
begin
  Tile := NeutralizeRoad(Tile);
  Result := ((Tile = VRAILROAD) or ((Tile >= ROADBASE) and (Tile <= VROADPOWER))) and
            (Tile <> VROADPOWER) and (Tile <> HRAILROAD) and (Tile <> VBRIDGE);
end;

function RoadConnectsNorth(Tile: Integer): Boolean;
begin
  Tile := NeutralizeRoad(Tile);
  Result := ((Tile = HRAILROAD) or ((Tile >= ROADBASE) and (Tile <= VROADPOWER))) and
            (Tile <> HROADPOWER) and (Tile <> VRAILROAD) and (Tile <> ROADBASE);
end;

function RoadConnectsSouth(Tile: Integer): Boolean;
begin
  Result := RoadConnectsNorth(Tile);
end;

function RoadConnectsWest(Tile: Integer): Boolean;
begin
  Tile := NeutralizeRoad(Tile);
  Result := ((Tile = VRAILROAD) or ((Tile >= ROADBASE) and (Tile <= VROADPOWER))) and
            (Tile <> VROADPOWER) and (Tile <> HRAILROAD) and (Tile <> VBRIDGE);
end;

function IsRail(Tile: Integer): Boolean;
begin
  Assert((Tile and LOMASK) = Tile);
  Result := ((Tile >= RAILBASE) and (Tile < RESBASE)) or
            (Tile = RAILHPOWERV) or (Tile = RAILVPOWERH);
end;

function IsRailDynamic(Tile: Integer): Boolean;
begin
  Assert((Tile and LOMASK) = Tile);
  Result := (Tile >= LHRAIL) and (Tile <= LVRAIL10);
end;

function RailConnectsEast(Tile: Integer): Boolean;
begin
  Tile := NeutralizeRoad(Tile);
  Result := (Tile >= RAILHPOWERV) and (Tile <= VRAILROAD) and
            (Tile <> RAILVPOWERH) and (Tile <> VRAILROAD) and (Tile <> VRAIL);
end;

function RailConnectsNorth(Tile: Integer): Boolean;
begin
  Tile := NeutralizeRoad(Tile);
  Result := (Tile >= RAILHPOWERV) and (Tile <= VRAILROAD) and
            (Tile <> RAILHPOWERV) and (Tile <> HRAILROAD) and (Tile <> HRAIL);
end;

function RailConnectsSouth(Tile: Integer): Boolean;
begin
  Result := RailConnectsNorth(Tile);
end;

function RailConnectsWest(Tile: Integer): Boolean;
begin
  Tile := NeutralizeRoad(Tile);
  Result := (Tile >= RAILHPOWERV) and (Tile <= VRAILROAD) and
            (Tile <> RAILVPOWERH) and (Tile <> VRAILROAD) and (Tile <> VRAIL);
end;

function IsWireDynamic(Tile: Integer): Boolean;
begin
  Assert((Tile and LOMASK) = Tile);
  Result := (Tile >= LHPOWER) and (Tile <= LVPOWER10);
end;

function WireConnectsEast(Tile: Integer): Boolean;
var
  NTile: Integer;
begin
  NTile := NeutralizeRoad(Tile);
  Result := IsConductive(Tile) and
            (NTile <> HPOWER) and (NTile <> HROADPOWER) and (NTile <> RAILHPOWERV);
end;

function WireConnectsNorth(Tile: Integer): Boolean;
var
  NTile: Integer;
begin
  NTile := NeutralizeRoad(Tile);
  Result := IsConductive(Tile) and
            (NTile <> VPOWER) and (NTile <> VROADPOWER) and (NTile <> RAILVPOWERH);
end;

function WireConnectsSouth(Tile: Integer): Boolean;
begin
  Result := WireConnectsNorth(Tile);
end;

function WireConnectsWest(Tile: Integer): Boolean;
var
  NTile: Integer;
begin
  NTile := NeutralizeRoad(Tile);
  Result := IsConductive(Tile) and
            (NTile <> HPOWER) and (NTile <> HROADPOWER) and (NTile <> RAILHPOWERV);
end;

function IsCommercialZone(Tile: Integer): Boolean;
var
  TS: TTileSpec;
begin
  Assert((Tile and LOMASK) = Tile);
  TS := TTiles.Get(Tile);
  if Assigned(TS) then
  begin
    if Assigned(TS.Owner) then
      TS := TS.Owner;
    Result := TS.GetBooleanAttribute('commercial-zone');
  end else
    Result := False;
end;

function IsIndustrialZone(Tile: Integer): Boolean;
var
  TS: TTileSpec;
begin
  Assert((Tile and LOMASK) = Tile);
  TS := TTiles.Get(Tile);
  if Assigned(TS) then
  begin
    if Assigned(TS.Owner) then
      TS := TS.Owner;
    Result := TS.GetBooleanAttribute('industrial-zone');
  end else
    Result := False;
end;

function IsResidentialClear(Tile: Integer): Boolean;
begin
  Assert((Tile and LOMASK) = Tile);
  Result := (Tile >= RESBASE) and (Tile <= RESBASE + 8);
end;

function IsResidentialZone(Tile: Integer): Boolean;
begin
  Assert((Tile and LOMASK) = Tile);
  Result := (Tile >= RESBASE) and (Tile < HOSPITAL);
end;

function IsResidentialZoneAny(Tile: Integer): Boolean;
var
  TS: TTileSpec;
begin
  Assert((Tile and LOMASK) = Tile);
  TS := TTiles.Get(Tile);
  if Assigned(TS) then
  begin
    if Assigned(TS.Owner) then
      TS := TS.Owner;
    Result := TS.GetBooleanAttribute('residential-zone');
  end else
    Result := False;
end;

function IsZoneAny(Tile: Integer): Boolean;
begin
  Assert((Tile and LOMASK) = Tile);
  Result := Tile >= RESBASE;
end;

function IsZoneCenter(Tile: Integer): Boolean;
var
  Spec: TTileSpec;
begin
  Assert((Tile and LOMASK) = Tile);
  Spec := TTiles.Get(Tile);
  Result := Assigned(Spec) and Spec.Zone;
end;

function NeutralizeRoad(Tile: Integer): Integer;
begin
  Assert((Tile and LOMASK) = Tile);
  if (Tile >= ROADBASE) and (Tile <= LASTROAD) then
    Tile := ((Tile - ROADBASE) and $F) + ROADBASE;
  Result := Tile;
end;

function ResidentialZonePop(Tile: Integer): Integer;
var
  TS: TTileSpec;
begin
  Assert((Tile and LOMASK) = Tile);
  TS := TTiles.Get(Tile);
  Result := TS.GetPopulation;
end;

function CommercialZonePop(Tile: Integer): Integer;
var
  TS: TTileSpec;
begin
  Assert((Tile and LOMASK) = Tile);
  TS := TTiles.Get(Tile);
  Result := TS.GetPopulation div 8;
end;

function IndustrialZonePop(Tile: Integer): Integer;
var
  TS: TTileSpec;
begin
  Assert((Tile and LOMASK) = Tile);
  TS := TTiles.Get(Tile);
  Result := TS.GetPopulation div 8;
end;



end.