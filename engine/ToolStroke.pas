// This file is part of MicropolisJ.
// Copyright (C) 2013 Jason Long
// Portions Copyright (C) 1989-2007 Electronic Arts Inc.
//
// MicropolisJ is free software; you can redistribute it and/or modify
// it under the terms of the GNU GPLv3, with additional terms.
// See the README file, included in this distribution, for details.

unit ToolStroke;

interface

uses
  System.SysUtils,
  ToolPreview,
  ToolEffectIfc, TranslatedToolEffect, TileSpec, CityRect, CityLocation,
  ToolEffect, ToolResult, TileConstants,TerrainBehavior,Tiles; // adjust as needed

type
  TMicropolisTool = (
    mtBULLDOZER,
    mtWIRE,
    mtROADS,
    mtRAIL,
    mtRESIDENTIAL,
    mtCOMMERCIAL,
    mtINDUSTRIAL,
    mtFIRE,
    mtPOLICE,
    mtSTADIUM,
    mtPARK,
    mtSEAPORT,
    mtPOWERPLANT,
    mtNUCLEAR,
    mtAIRPORT,
    mtQUERY,
    mtNONE
  );

  TToolStroke = class
  protected
    FTool: TMicropolisTool;
    FCity: TTerrainCity;
    FInPreview: Boolean;
    FXPos, FYPos, FDestX, FDestY: Integer;
    procedure ApplyArea(Eff: IToolEffectIfc); virtual;
    function Apply1(Eff: IToolEffectIfc): Boolean; virtual;
    function ApplyZone(Eff: IToolEffectIfc; Base: TTileSpec): Boolean;
    function ApplyParkTool(Eff: IToolEffectIfc): Boolean;
    procedure FixBorder(Left, Top, Right, Bottom: Integer); overload;
    procedure FixBorder(Eff: IToolEffectIfc; Width, Height: Integer); overload;
    procedure  FixZone(XPos, YPos: Integer); overload;
    procedure  FixZone(Eff: IToolEffectIfc);  overload;
    procedure  FixSingle(Eff: IToolEffectIfc); overload;
  public
    constructor Create(City: TTerrainCity; Tool: TMicropolisTool; X, Y: Integer);

    function GetPreview: TToolPreview;
    function Apply: TToolResult;

    procedure DragTo(X, Y: Integer); virtual;
    function GetBounds: TCityRect; virtual;
    function GetLocation: TCityLocation;
  end;


function GetToolSize(Tool: TMicropolisTool): Integer;
function GetToolHeight(Tool: TMicropolisTool): Integer;
function GetToolWidth(Tool: TMicropolisTool): Integer;
function GetToolCost(Tool: TMicropolisTool): Integer;
function BeginStroke(Engine: TTerrainCity; Tool: TMicropolisTool; X, Y: Integer): TToolStroke;
function ApplyTool(Engine: TTerrainCity; Tool: TMicropolisTool; X, Y: Integer): TToolResult;
function GetToolName(Tool: TMicropolisTool):String;


implementation

uses
  Bulldozer, RoadLikeTool, BuildingTool, Math;

constructor TToolStroke.Create(City: TTerrainCity; Tool: TMicropolisTool; X, Y: Integer);
begin
  inherited Create;
  FCity := City;
  FTool := Tool;
  FXPos := X;
  FYPos := Y;
  FDestX := X;
  FDestY := Y;
  FInPreview := False;
end;

function TToolStroke.GetPreview: TToolPreview;
var
  Eff: TToolEffect;
begin
  Eff := TToolEffect.Create(FCity);
  FInPreview := True;
  try
    ApplyArea(Eff);
  finally
    FInPreview := False;
  end;
  Result := Eff.FPreview;
end;

function TToolStroke.Apply: TToolResult;
var
  Eff: TToolEffect;
begin
  Eff := TToolEffect.Create(FCity);
  ApplyArea(Eff);
  Result := Eff.Apply();
end;

procedure TToolStroke.DragTo(X, Y: Integer);
begin
  FDestX := X;
  FDestY := Y;
end;

function TToolStroke.GetBounds: TCityRect;
var
  R: TCityRect;
  dx, dy: Integer;
begin
  R.X := FXPos;
  if GetToolWidth(FTool) >= 3 then Dec(R.X);

  dx := FDestX - FXPos;
  if dx >= 0 then
    R.Width := ((dx div GetToolWidth(FTool)) + 1) * GetToolWidth(FTool)
  else
  begin
    R.Width := ((-dx div GetToolWidth(FTool)) + 1) * GetToolWidth(FTool);
    Inc(R.X, GetToolWidth(FTool) - R.Width);
  end;

  R.Y := FYPos;
  if GetToolHeight(FTool) >= 3 then Dec(R.Y);

  dy := FDestY - FYPos;
  if dy >= 0 then
    R.Height := ((dy div GetToolHeight(FTool)) + 1) * GetToolHeight(FTool)
  else
  begin
    R.Height := ((-dy div GetToolHeight(FTool)) + 1) * GetToolHeight(FTool);
    Inc(R.Y, GetToolHeight(FTool) - R.Height);
  end;

  Result := R;
end;

function TToolStroke.GetLocation: TCityLocation;
begin
  Result := TCityLocation.Create(FXPos, FYPos);
end;

procedure TToolStroke.ApplyArea(Eff: IToolEffectIfc);
var
  R: TCityRect;
  i, j: Integer;
  SubEff: IToolEffectIfc;
begin
  R := GetBounds;
  for i := 0 to R.Height - 1 do
    for j := 0 to R.Width - 1 do
    begin
      SubEff := TTranslatedToolEffect.Create(Eff, R.X + j, R.Y + i);
      Apply1(SubEff);
    end;
end;

function TToolStroke.Apply1(Eff: IToolEffectIfc): Boolean;
begin
  case FTool of
    mtPark:    Result := ApplyParkTool(Eff);
    mtResidential:
               Result := ApplyZone(Eff, TTiles.LoadByOrdinal(RESCLR));
    mtCommercial:
               Result := ApplyZone(Eff, TTiles.LoadByOrdinal(COMCLR));
    mtIndustrial:
               Result := ApplyZone(Eff, TTiles.LoadByOrdinal(INDCLR));
  else
    raise Exception.Create('Unexpected tool');
  end;
end;

function TToolStroke.ApplyZone(Eff: IToolEffectIfc; Base: TTileSpec): Boolean;
var
  Bi: TileSpec.TBuildingInfo;
  Cost, TileValue, i, r, c, idx: Integer;
  CanBuild: Boolean;
begin
  Bi := Base.BuildingInfo;
  if Bi = nil then
    raise Exception.Create('Cannot applyZone to #' + Base.Name);

  Cost := GetToolCost(FTool);
  CanBuild := True;

  for r := 0 to Bi.Height - 1 do
    for c := 0 to Bi.Width - 1 do
    begin
      TileValue := Eff.GetTile(c, r) and LOMASK;
      if TileValue <> DIRT then
      begin
        if FCity.AutoBulldoze and CanAutoBulldozeZ(TileValue) then
          Inc(Cost)
        else
          CanBuild := False;
      end;
    end;

  if not CanBuild then
  begin
    Eff.ToolResult(trUhOh);
    Exit(False);
  end;

  Eff.Spend(Cost);
  idx := 0;
  for r := 0 to Bi.Height - 1 do
    for c := 0 to Bi.Width - 1 do
    begin
      Eff.SetTile(c, r, Bi.Members[idx].TileNumber);
      Inc(idx);
    end;

  FixBorder(Eff, Bi.Width, Bi.Height);
  Result := True;
end;

function TToolStroke.ApplyParkTool(Eff: IToolEffectIfc): Boolean;
var
  Cost: Integer;
  z, Tile: Integer;
begin
  Cost := GetToolCost(FTool);

  if Eff.GetTile(0, 0) <> DIRT then
  begin
    if not FCity.AutoBulldoze or
       not IsRubble(Eff.GetTile(0, 0)) then
    begin
      Eff.ToolResult(trUhOh);
      Exit(False);
    end;
    Inc(Cost);
  end;

  if not FInPreview then
    z := FCity.PRNG.NextInt(5)
  else
    z := 0;

  if z < 4 then
    Tile := WOODS2 + z
  else
    Tile := FOUNTAIN;

  Eff.Spend(Cost);
  Eff.SetTile(0, 0, Tile);
  Result := True;
end;

{
procedure TToolStroke.FixBorder(Eff: IToolEffectIfc);
var
  SubEff: TToolEffect;
begin
  SubEff := TToolEffect.Create(FCity, 0, 0);
  FixBorder(SubEff, GetToolWidth(FTool), GetToolHeight(FTool));
  SubEff.Apply();
end;

procedure TToolStroke.FixBorder(Left, Top, Right, Bottom: Integer);
var
  Eff: IToolEffectIfc;
  x, y: Integer;
begin
  Eff := TToolEffect.Create(FCity, Left, Top);
  FixBorder(Eff);
end;   }

procedure TToolStroke.FixBorder(Left, Top, Right, Bottom: Integer);
var
  Eff: TToolEffect;
begin
  Eff := TToolEffect.Create(FCity, Left, Top);
  FixBorder(Eff, Right + 1 - Left, Bottom + 1 - Top);
  Eff.Apply;
end;

procedure TToolStroke.FixBorder(Eff: IToolEffectIfc; Width, Height: Integer);
var
  X, Y: Integer;
begin
  // Fix top and bottom borders
  for X := 0 to Width - 1 do
  begin
    FixZone(TTranslatedToolEffect.Create(Eff, X, 0));
    FixZone(TTranslatedToolEffect.Create(Eff, X, Height - 1));
  end;

  // Fix left and right borders (excluding corners already done)
  for Y := 1 to Height - 2 do
  begin
    FixZone(TTranslatedToolEffect.Create(Eff, 0, Y));
    FixZone(TTranslatedToolEffect.Create(Eff, Width - 1, Y));
  end;
end;

{
procedure TToolStroke.FixZoneSolo(X, Y: Integer);
var
  Eff: TToolEffect;
begin
  Eff := TToolEffect.Create(FCity, X, Y);
  FixZone(Eff);
  Eff.Apply();
end;

procedure TToolStroke.FixZone(Eff: IToolEffectIfc);
begin
  FixZoneSolo(0, 0);
  FixZoneSolo(0, -1);
  FixZoneSolo(-1, 0);
  FixZoneSolo(1, 0);
  FixZoneSolo(0, 1);
end;
}
procedure  TToolStroke.FixZone(XPos, YPos: Integer);
var
  Eff: TToolEffect;
begin
  Eff := TToolEffect.Create(FCity, XPos, YPos);
  FixZone(Eff);
  Eff.Apply;
end;

procedure  TToolStroke.FixZone(Eff: IToolEffectIfc);
begin
  FixSingle(Eff);

  // Fix adjacent cells (north, west, east, south)
  FixSingle(TTranslatedToolEffect.Create(Eff, 0, -1));
  FixSingle(TTranslatedToolEffect.Create(Eff, -1, 0));
  FixSingle(TTranslatedToolEffect.Create(Eff, 1, 0));
  FixSingle(TTranslatedToolEffect.Create(Eff, 0, 1));
end;

procedure  TToolStroke.FixSingle(Eff: IToolEffectIfc);
var
  Tile, AdjTile: Integer;
begin
  Tile := Eff.GetTile(0, 0);

  if IsRoadDynamic(Tile) then
  begin
    // Cleanup road
    AdjTile := 0;

    // Check road connections
    if RoadConnectsSouth(Eff.GetTile(0, -1)) then
      AdjTile := AdjTile or 1;
    if RoadConnectsWest(Eff.GetTile(1, 0)) then
      AdjTile := AdjTile or 2;
    if RoadConnectsNorth(Eff.GetTile(0, 1)) then
      AdjTile := AdjTile or 4;
    if RoadConnectsEast(Eff.GetTile(-1, 0)) then
      AdjTile := AdjTile or 8;

    Eff.SetTile(0, 0, RoadTable[AdjTile]);
  end
  else if IsRailDynamic(Tile) then
  begin
    // Cleanup rail
    AdjTile := 0;

    // Check rail connections
    if RailConnectsSouth(Eff.GetTile(0, -1)) then
      AdjTile := AdjTile or 1;
    if RailConnectsWest(Eff.GetTile(1, 0)) then
      AdjTile := AdjTile or 2;
    if RailConnectsNorth(Eff.GetTile(0, 1)) then
      AdjTile := AdjTile or 4;
    if RailConnectsEast(Eff.GetTile(-1, 0)) then
      AdjTile := AdjTile or 8;

    Eff.SetTile(0, 0, RailTable[AdjTile]);
  end
  else if IsWireDynamic(Tile) then
  begin
    // Cleanup wire
    AdjTile := 0;

    // Check wire connections
    if WireConnectsSouth(Eff.GetTile(0, -1)) then
      AdjTile := AdjTile or 1;
    if WireConnectsWest(Eff.GetTile(1, 0)) then
      AdjTile := AdjTile or 2;
    if WireConnectsNorth(Eff.GetTile(0, 1)) then
      AdjTile := AdjTile or 4;
    if WireConnectsEast(Eff.GetTile(-1, 0)) then
      AdjTile := AdjTile or 8;

    Eff.SetTile(0, 0, WireTable[AdjTile]);
  end;
end;

function GetToolHeight(Tool: TMicropolisTool): Integer;
begin
 result :=GetToolSize(Tool);
end;

function GetToolWidth(Tool: TMicropolisTool): Integer;
begin
 result :=GetToolSize(Tool);
end;

function GetToolSize(Tool: TMicropolisTool): Integer;
begin
  case Tool of
    mtBULLDOZER,
    mtWIRE,
    mtROADS,
    mtRAIL,
    mtPARK,
    mtQUERY:
      Result := 1;

    mtRESIDENTIAL,
    mtCOMMERCIAL,
    mtINDUSTRIAL,
    mtFIRE,
    mtPOLICE:
      Result := 3;

    mtSTADIUM,
    mtSEAPORT,
    mtPOWERPLANT,
    mtNUCLEAR:
      Result := 4;

    mtAIRPORT:
      Result := 6;

  else
    Result := 1; // Default fallback
  end;
end;

function GetToolCost(Tool: TMicropolisTool): Integer;
begin
  case Tool of
    mtBULLDOZER:   Result := 1;
    mtWIRE:        Result := 5;
    mtROADS:       Result := 10;
    mtRAIL:        Result := 20;
    mtRESIDENTIAL: Result := 100;
    mtCOMMERCIAL:  Result := 100;
    mtINDUSTRIAL:  Result := 100;
    mtFIRE:        Result := 500;
    mtPOLICE:      Result := 500;
    mtSTADIUM:     Result := 5000;
    mtPARK:        Result := 10;
    mtSEAPORT:     Result := 3000;
    mtPOWERPLANT:  Result := 3000;
    mtNUCLEAR:     Result := 5000;
    mtAIRPORT:     Result := 10000;
    mtQUERY:       Result := 0;
  else
    Result := 0;
  end;
end;

function BeginStroke(Engine: TTerrainCity; Tool: TMicropolisTool; X, Y: Integer): TToolStroke;
begin
  case Tool of
    mtBULLDOZER:
      Result := TBulldozer.Create(Engine, X, Y);
    mtWIRE, mtROADS, mtRAIL:
      Result := TRoadLikeTool.Create(Engine, Tool, X, Y);
    mtFIRE, mtPOLICE, mtSTADIUM, mtSEAPORT, mtPOWERPLANT, mtNUCLEAR, mtAIRPORT:
      Result := TBuildingTool.Create(Engine, Tool, X, Y);
  else
    Result := TToolStroke.Create(Engine, Tool, X, Y);
  end;
end;

function ApplyTool(Engine: TTerrainCity; Tool: TMicropolisTool; X, Y: Integer): TToolResult;
var
  Stroke: TToolStroke;
begin
  Stroke := BeginStroke(Engine, Tool, X, Y);
  try
    Result := Stroke.Apply;
  finally
    Stroke.Free;
  end;
end;

function GetToolName(Tool: TMicropolisTool):String;
begin
  case Tool of
    mtBULLDOZER	: Result :='BULLDOZER';
    mtWIRE	: Result :='WIRE';
    mtROADS	: Result :='ROADS';
    mtRAIL	: Result :='RAIL';
    mtRESIDENTIAL	: Result :='RESIDENTIAL';
    mtCOMMERCIAL	: Result :='COMMERCIAL';
    mtINDUSTRIAL	: Result :='INDUSTRIAL';
    mtFIRE	: Result :='FIRE';
    mtPOLICE	: Result :='POLICE';
    mtSTADIUM	: Result :='STADIUM';
    mtPARK	: Result := 'PARK';
    mtSEAPORT	: Result :='SEAPORT';
    mtPOWERPLANT	: Result :='POWERPLANT';
    mtNUCLEAR	: Result :='NUCLEAR';
    mtAIRPORT	: Result :='AIRPORT';
    mtQUERY	: Result :='QUERY';
  end;
end;

end.
