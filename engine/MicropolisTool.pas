// This file is part of MicropolisJ.
// Copyright (C) 2013 Jason Long
// Portions Copyright (C) 1989-2007 Electronic Arts Inc.
//
// MicropolisJ is free software; you can redistribute it and/or modify
// it under the terms of the GNU GPLv3, with additional terms.
// See the README file, included in this distribution, for details.



{
 * Enumerates the various tools that can be applied to the map by the user.
 * Call the tool's apply() method to actually use the tool on the map.
}
unit MicropolisTool;

interface

uses
  SpriteCity, ToolStroke;

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
    mtQUERY
  );

function GetToolSize(Tool: TMicropolisTool): Integer;
function GetToolCost(Tool: TMicropolisTool): Integer;
function BeginStroke(Engine: TSpriteCity; Tool: TMicropolisTool; X, Y: Integer): TToolStroke;
function ApplyTool(Engine: TSpriteCity; Tool: TMicropolisTool; X, Y: Integer): TToolResult;

implementation
uses Bulldozer, RoadLikeTool, BuildingTool;

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

function BeginStroke(Engine: TSpriteCity; Tool: TMicropolisTool; X, Y: Integer): TToolStroke;
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

function ApplyTool(Engine: TSpriteCity; Tool: TMicropolisTool; X, Y: Integer): TToolResult;
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

end.
