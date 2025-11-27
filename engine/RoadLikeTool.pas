// This file is part of MicropolisJ.
// Copyright (C) 2013 Jason Long
// Portions Copyright (C) 1989-2007 Electronic Arts Inc.
//
// MicropolisJ is free software; you can redistribute it and/or modify
// it under the terms of the GNU GPLv3, with additional terms.
// See the README file, included in this distribution, for details.

unit RoadLikeTool;

interface

uses
  ToolStroke, TerrainBehavior, ToolEffectIfc, TranslatedToolEffect, CityRect,
  TileConstants, SysUtils,System.TypInfo;

type
  TRoadLikeTool = class(TToolStroke)
  public
    constructor Create(ACity: TTerrainCity; ATool: TMicropolisTool; AX, AY: Integer);
    procedure ApplyArea(Eff: IToolEffectIfc); override;
    function ApplyForward(Eff: IToolEffectIfc): Boolean;
    function ApplyBackward(Eff: IToolEffectIfc): Boolean;
    function ApplySingle(Eff: IToolEffectIfc): Boolean;
    function ApplyRailTool(Eff: IToolEffectIfc): Boolean;
    function ApplyRoadTool(Eff: IToolEffectIfc): Boolean;
    function ApplyWireTool(Eff: IToolEffectIfc): Boolean;
    function GetBounds: TCityRect; override;

  private
    function LayRail(Eff: IToolEffectIfc): Boolean;
    function LayRoad(Eff: IToolEffectIfc): Boolean;
    function LayWire(Eff: IToolEffectIfc): Boolean;
  end;

implementation
uses Math;

{ TRoadLikeTool }

constructor TRoadLikeTool.Create(ACity: TTerrainCity; ATool: TMicropolisTool; AX, AY: Integer);
begin
  inherited Create(ACity, ATool, AX, AY);
end;

procedure TRoadLikeTool.ApplyArea(Eff: IToolEffectIfc);
begin
  while True do
  begin
    if not ApplyForward(Eff) then Break;
    if not ApplyBackward(Eff) then Break;
  end;
end;

function TRoadLikeTool.ApplyBackward(Eff: IToolEffectIfc): Boolean;
var
  B: TCityRect;
  I, J: Integer;
  TTE: TTranslatedToolEffect;
begin
  Result := False;
  B := GetBounds;
  for I := B.Height - 1 downto 0 do
    for J := B.Width - 1 downto 0 do
    begin
      TTE := TTranslatedToolEffect.Create(Eff, B.X + J, B.Y + I);
      Result := ApplySingle(TTE) or Result;
    end;
end;

function TRoadLikeTool.ApplyForward(Eff: IToolEffectIfc): Boolean;
var
  B: TCityRect;
  I, J: Integer;
  TTE: TTranslatedToolEffect;
begin
  Result := False;
  B := GetBounds;
  for I := 0 to B.Height - 1 do
    for J := 0 to B.Width - 1 do
    begin
      TTE := TTranslatedToolEffect.Create(Eff, B.X + J, B.Y + I);
      Result := ApplySingle(TTE) or Result;
    end;
end;

function TRoadLikeTool.GetBounds: TCityRect;
var
  R: TCityRect;
begin
  Assert(GetToolWidth(Ftool) = 1);
  Assert(GetToolHeight(Ftool) = 1);

  if Abs(FDestX - FXPos) >= Abs(FDestX - FYPos) then
  begin
    R.X := Min(FXPos, FDestX);
    R.Width := Abs(FDestX - FXPos) + 1;
    R.Y := FYPos;
    R.Height := 1;
  end
  else
  begin
    R.X := FXPos;
    R.Width := 1;
    R.Y := Min(FYPos, FDestY);
    R.Height := Abs(FDestY - FYPos) + 1;
  end;

  Result := R;
end;

function TRoadLikeTool.ApplySingle(Eff: IToolEffectIfc): Boolean;
begin
  case FTool of
    mtRAIL: Result := ApplyRailTool(Eff);
    mtROADS: Result := ApplyRoadTool(Eff);
    mtWIRE: Result := ApplyWireTool(Eff);
  else
    raise Exception.CreateFmt('Unexpected tool: %s', [GetEnumName(TypeInfo(TMicropolisTool), Ord(FTool))]);
  end;
end;

function TRoadLikeTool.ApplyRailTool(Eff: IToolEffectIfc): Boolean;
begin
  if LayRail(Eff) then
  begin
    FixZone(Eff);
    Result := True;
  end
  else
    Result := False;
end;

function TRoadLikeTool.ApplyRoadTool(Eff: IToolEffectIfc): Boolean;
begin
  if LayRoad(Eff) then
  begin
    FixZone(Eff);
    Result := True;
  end
  else
    Result := False;
end;

function TRoadLikeTool.ApplyWireTool(Eff: IToolEffectIfc): Boolean;
begin
  if LayWire(Eff) then
  begin
    FixZone(Eff);
    Result := True;
  end
  else
    Result := False;
end;



function TRoadLikeTool.LayRail(eff: IToolEffectIfc): Boolean;
const
  RAIL_COST = 20;
  TUNNEL_COST = 100;
var
  cost: Integer;
  tile, eTile, wTile, sTile, nTile: Byte;
begin
  cost := RAIL_COST;

  tile := eff.getTile(0, 0);
  tile := NeutralizeRoad(tile);

  case tile of
    RIVER, REDGE, CHANNEL:
      begin
        cost := TUNNEL_COST;

        // check east
        eTile := NeutralizeRoad(eff.getTile(1, 0));
        if (eTile = RAILHPOWERV) or
           (eTile = HRAIL) or
           ((eTile >= LHRAIL) and (eTile <= HRAILROAD)) then
        begin
          eff.setTile(0, 0, HRAIL);
          Result := True;
          eff.spend(cost);
          Exit;
        end;

        // check west
        wTile := NeutralizeRoad(eff.getTile(-1, 0));
        if (wTile = RAILHPOWERV) or
           (wTile = HRAIL) or
           ((wTile > VRAIL) and (wTile < VRAILROAD)) then
        begin
          eff.setTile(0, 0, HRAIL);
          Result := True;
          eff.spend(cost);
          Exit;
        end;

        // check south
        sTile := NeutralizeRoad(eff.getTile(0, 1));
        if (sTile = RAILVPOWERH) or
           (sTile = VRAILROAD) or
           ((sTile > HRAIL) and (sTile < HRAILROAD)) then
        begin
          eff.setTile(0, 0, VRAIL);
          Result := True;
          eff.spend(cost);
          Exit;
        end;

        // check north
        nTile := NeutralizeRoad(eff.getTile(0, -1));
        if (nTile = RAILVPOWERH) or
           (nTile = VRAILROAD) or
           ((nTile > HRAIL) and (nTile < HRAILROAD)) then
        begin
          eff.setTile(0, 0, VRAIL);
          Result := True;
          eff.spend(cost);
          Exit;
        end;

        // cannot do rail here
        Result := False;
        Exit;
      end;

    LHPOWER:
      eff.setTile(0, 0, RAILVPOWERH);

    LVPOWER:
      eff.setTile(0, 0, RAILHPOWERV);

    TileConstants.ROADS:
      eff.setTile(0, 0, VRAILROAD);

    ROADS2:
      eff.setTile(0, 0, HRAILROAD);

  else
    begin
      if tile <> DIRT then
      begin
        if Fcity.autoBulldoze and CanAutoBulldozeRRW(tile) then
          Inc(cost) // autodoze cost
        else
        begin
          // cannot do rail here
          Result := False;
          Exit;
        end;
      end;

      // rail on dirt
      eff.setTile(0, 0, LHRAIL);
    end;
  end;

  eff.spend(cost);
  Result := True;
end;

function TRoadLikeTool.LayRoad(eff: IToolEffectIfc): Boolean;
const
  ROAD_COST = 10;
  BRIDGE_COST = 50;
var
  cost: Integer;
  tile, eTile, wTile, sTile, nTile: Byte;
begin
  cost := ROAD_COST;

  tile := eff.getTile(0, 0);

  case tile of
    RIVER, REDGE, CHANNEL:
      begin
        cost := BRIDGE_COST;

        // check east
        eTile := NeutralizeRoad(eff.getTile(1, 0));
        if (eTile = VRAILROAD) or
           (eTile = HBRIDGE) or
           ((eTile >= TileConstants.ROADS) and (eTile <= HROADPOWER)) then
        begin
          eff.setTile(0, 0, HBRIDGE);
          Result := True;
          eff.spend(cost);
          Exit;
        end;

        // check west
        wTile := NeutralizeRoad(eff.getTile(-1, 0));
        if (wTile = VRAILROAD) or
           (wTile = HBRIDGE) or
           ((wTile >= TileConstants.ROADS) and (wTile <= INTERSECTION)) then
        begin
          eff.setTile(0, 0, HBRIDGE);
          Result := True;
          eff.spend(cost);
          Exit;
        end;

        // check south
        sTile := NeutralizeRoad(eff.getTile(0, 1));
        if (sTile = HRAILROAD) or
           (sTile = VROADPOWER) or
           ((sTile >= VBRIDGE) and (sTile <= INTERSECTION)) then
        begin
          eff.setTile(0, 0, VBRIDGE);
          Result := True;
          eff.spend(cost);
          Exit;
        end;

        // check north
        nTile := NeutralizeRoad(eff.getTile(0, -1));
        if (nTile = HRAILROAD) or
           (nTile = VROADPOWER) or
           ((nTile >= VBRIDGE) and (nTile <= INTERSECTION)) then
        begin
          eff.setTile(0, 0, VBRIDGE);
          Result := True;
          eff.spend(cost);
          Exit;
        end;

        // cannot do road here
        Result := False;
        Exit;
      end;

    LHPOWER:
      eff.setTile(0, 0, VROADPOWER);

    LVPOWER:
      eff.setTile(0, 0, HROADPOWER);

    LHRAIL:
      eff.setTile(0, 0, HRAILROAD);

    LVRAIL:
      eff.setTile(0, 0, VRAILROAD);

  else
    begin
      if tile <> DIRT then
      begin
        if Fcity.autoBulldoze and CanAutoBulldozeRRW(tile) then
          Inc(cost) // autodoze cost
        else
        begin
          Result := False;
          Exit;
        end;
      end;

      // road on dirt
      eff.setTile(0, 0, TileConstants.ROADS);
    end;
  end;

  eff.spend(cost);
  Result := True;
end;

function TRoadLikeTool.LayWire(eff: IToolEffectIfc): Boolean;
const
  WIRE_COST = 5;
  UNDERWATER_WIRE_COST = 25;
var
  cost: Integer;
  tile: Word;
  tmp: Integer;
  tmpn: Word;
begin
  cost := WIRE_COST;

  tile := eff.getTile(0, 0);
  tile := NeutralizeRoad(tile);

  case tile of
    RIVER, REDGE, CHANNEL:
      begin
        cost := UNDERWATER_WIRE_COST;

        // check east
        tmp := eff.getTile(1, 0);
        tmpn := NeutralizeRoad(tmp);
        if IsConductive(tmp) and
           (tmpn <> HROADPOWER) and
           (tmpn <> RAILHPOWERV) and
           (tmpn <> HPOWER) then
        begin
          eff.setTile(0, 0, VPOWER);
          Result := True;
          eff.spend(cost);
          Exit;
        end;

        // check west
        tmp := eff.getTile(-1, 0);
        tmpn := NeutralizeRoad(tmp);
        if IsConductive(tmp) and
           (tmpn <> HROADPOWER) and
           (tmpn <> RAILHPOWERV) and
           (tmpn <> HPOWER) then
        begin
          eff.setTile(0, 0, VPOWER);
          Result := True;
          eff.spend(cost);
          Exit;
        end;

        // check south
        tmp := eff.getTile(0, 1);
        tmpn := NeutralizeRoad(tmp);
        if IsConductive(tmp) and
           (tmpn <> VROADPOWER) and
           (tmpn <> RAILVPOWERH) and
           (tmpn <> VPOWER) then
        begin
          eff.setTile(0, 0, HPOWER);
          Result := True;
          eff.spend(cost);
          Exit;
        end;

        // check north
        tmp := eff.getTile(0, -1);
        tmpn := NeutralizeRoad(tmp);
        if IsConductive(tmp) and
           (tmpn <> VROADPOWER) and
           (tmpn <> RAILVPOWERH) and
           (tmpn <> VPOWER) then
        begin
          eff.setTile(0, 0, HPOWER);
          Result := True;
          eff.spend(cost);
          Exit;
        end;

        // cannot do wire here
        Result := False;
        Exit;
      end;

    TileConstants.ROADS:
      eff.setTile(0, 0, HROADPOWER);

    ROADS2:
      eff.setTile(0, 0, VROADPOWER);

    LHRAIL:
      eff.setTile(0, 0, RAILHPOWERV);

    LVRAIL:
      eff.setTile(0, 0, RAILVPOWERH);

  else
    begin
      if tile <> DIRT then
      begin
        if Fcity.autoBulldoze and CanAutoBulldozeRRW(tile) then
          Inc(cost) // autodoze cost
        else
        begin
          // cannot do wire here
          Result := False;
          Exit;
        end;
      end;

      // wire on dirt
      eff.setTile(0, 0, LHPOWER);
    end;
  end;

  eff.spend(cost);
  Result := True;
end;
end.