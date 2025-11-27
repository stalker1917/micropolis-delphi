// This file is part of MicropolisJ.
// Copyright (C) 2013 Jason Long
// Portions Copyright (C) 1989-2007 Electronic Arts Inc.
//
// MicropolisJ is free software; you can redistribute it and/or modify
// it under the terms of the GNU GPLv3, with additional terms.
// See the README file, included in this distribution, for details.

unit ToolEffect;

interface

uses
  SysUtils,
  SpriteCity,  // adjust according to your project
  ToolPreview, // adjust according to your project
  Sound,       // adjust according to your project
  ToolResult,
  TileConstants,
  ToolEffectIfc;  // adjust according to your project


type
  TToolEffect = class(TInterfacedObject,IToolEffectIfc)
  private
    FCity: TSpriteCity;
    FOriginX: Integer;
    FOriginY: Integer;

  public
    FPreview: TToolPreview;
    constructor Create(ACity: TSpriteCity); overload;
    constructor Create(ACity: TSpriteCity; AXPos, AYPos: Integer); overload;

    function GetTile(dx, dy: Integer): Integer;
    procedure MakeSound(dx, dy: Integer; ASound: TSound);
    procedure SetTile(dx, dy: Integer; tileValue: Integer);
    procedure Spend(amount: Integer);
    procedure ToolResult(tr: TToolResult);

    function Apply: TToolResult;
  end;

implementation

{ TToolEffect }

constructor TToolEffect.Create(ACity: TSpriteCity);
begin
  Create(ACity, 0, 0);
end;

constructor TToolEffect.Create(ACity: TSpriteCity; AXPos, AYPos: Integer);
begin
  inherited Create;
  FCity := ACity;
  FPreview := TToolPreview.Create;
  FOriginX := AXPos;
  FOriginY := AYPos;
end;

function TToolEffect.GetTile(dx, dy: Integer): Integer;
var
  c: Integer;
begin
  c := FPreview.GetTile(dx, dy);
  if c <> CLEAR then
    Exit(c);

  if FCity.TestBounds(FOriginX + dx, FOriginY + dy) then
    Result := FCity.GetTile(FOriginX + dx, FOriginY + dy)
  else
    Result := 0;  // tiles outside city boundary assumed to be tile #0 (dirt)
end;

procedure TToolEffect.MakeSound(dx, dy: Integer; ASound: TSound);
begin
  FPreview.MakeSound(dx, dy, ASound);
end;

procedure TToolEffect.SetTile(dx, dy: Integer; tileValue: Integer);
begin
  FPreview.SetTile(dx, dy, tileValue);
end;

procedure TToolEffect.Spend(amount: Integer);
begin
  FPreview.Spend(amount);
end;

procedure TToolEffect.ToolResult(tr: TToolResult);
begin
  FPreview.ToolResult(tr);
end;

function TToolEffect.Apply: TToolResult;
var
  x, y: Integer;
  c: Integer;
  anyFound: Boolean;
  si: ToolPreview.TSoundInfo; // assuming this is the Delphi equivalent of ToolPreview.SoundInfo
begin
  if (FOriginX - FPreview.OffsetX < 0) or
     (FOriginX - FPreview.OffsetX + FPreview.GetWidth > FCity.GetWidth) or
     (FOriginY - FPreview.OffsetY < 0) or
     (FOriginY - FPreview.OffsetY + FPreview.GetHeight > FCity.GetHeight) then
  begin
    Exit(TToolResult.trUhOh);
  end;

  if FCity.Budget.TotalFunds < FPreview.Cost then
    Exit(TToolResult.trInsufficientFunds);

  anyFound := False;
  for y := 0 to Length(FPreview.Tiles) - 1 do
  begin
    for x := 0 to Length(FPreview.Tiles[y]) - 1 do
    begin
      c := FPreview.Tiles[y][x];
      if c <> CLEAR then
      begin
        FCity.SetTile(FOriginX + x - FPreview.OffsetX,
                      FOriginY + y - FPreview.OffsetY,
                      c);
        anyFound := True;
      end;
    end;
  end;

  for si in FPreview.Sounds do
  begin
    FCity.MakeSound(si.X, si.Y, si.Sound);
  end;

  if anyFound and (FPreview.Cost <> 0) then
  begin
    FCity.Spend(FPreview.Cost);
    Result := TToolResult.trSUCCESS;
  end
  else
    Result := FPreview.ToolResultValue;
end;

end.
