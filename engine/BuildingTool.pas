// This file is part of MicropolisJ.
// Copyright (C) 2013 Jason Long
// Portions Copyright (C) 1989-2007 Electronic Arts Inc.
//
// MicropolisJ is free software; you can redistribute it and/or modify
// it under the terms of the GNU GPLv3, with additional terms.
// See the README file, included in this distribution, for details.



unit BuildingTool;

interface

uses
  TerrainBehavior, ToolStroke, Tiles, TileConstants, ToolEffectIfc, SysUtils,System.TypInfo;

type
  TBuildingTool = class(TToolStroke)
  public
    constructor Create(Engine: TTerrainCity; Tool: TMicropolisTool; XPos, YPos: Integer);
    procedure DragTo(XDest, YDest: Integer); override;
    function Apply1(Eff: IToolEffectIfc): Boolean; override;
  end;

implementation

{ TBuildingTool }

constructor TBuildingTool.Create(Engine: TTerrainCity; Tool: TMicropolisTool; XPos, YPos: Integer);
begin
  inherited Create(Engine, Tool, XPos, YPos);
end;

procedure TBuildingTool.DragTo(XDest, YDest: Integer);
begin
  Self.FXPos := XDest;
  Self.FYPos := YDest;
  Self.FDestX := XDest;
  Self.FDestY := YDest;
end;

function TBuildingTool.Apply1(Eff: IToolEffectIfc): Boolean;
begin
  case FTool of
    mtFire:
      Result := ApplyZone(Eff, TTiles.LoadByOrdinal(FIRESTATION));
    mtPolice:
      Result := ApplyZone(Eff, TTiles.LoadByOrdinal(POLICESTATION));
    mtPowerPlant:
      Result := ApplyZone(Eff, TTiles.LoadByOrdinal(POWERPLANT));
    mtStadium:
      Result := ApplyZone(Eff, TTiles.LoadByOrdinal(STADIUM));
    mtSeaport:
      Result := ApplyZone(Eff, TTiles.LoadByOrdinal(PORT));
    mtNuclear:
      Result := ApplyZone(Eff, TTiles.LoadByOrdinal(NUCLEAR));
    mtAirport:
      Result := ApplyZone(Eff, TTiles.LoadByOrdinal(AIRPORT));
  else
    raise Exception.Create('Unexpected tool: ' + GetEnumName(TypeInfo(TMicropolisTool), Ord(FTool)));
  end;
end;

end.