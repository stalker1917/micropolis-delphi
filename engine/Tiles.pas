// This file is part of MicropolisJ.
// Copyright (C) 2013 Jason Long
// Portions Copyright (C) 1989-2007 Electronic Arts Inc.
//
// MicropolisJ is free software; you can redistribute it and/or modify
// it under the terms of the GNU GPLv3, with additional terms.
// See the README file, included in this distribution, for details.

unit Tiles;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, TileSpec; 

type
  TTiles = class
  private
    class var
      FUTF8Encoding: TEncoding;
      FTiles: TArray<TTileSpec>;
      FTilesByName: TDictionary<string, TTileSpec>;
    class procedure ReadTiles;
    class procedure CheckTiles;

  public
    class constructor Create;
    class destructor Destroy;

    class function Load(const TileName: string): TTileSpec; overload; static;
    class function LoadByOrdinal(TileNumber: Integer): TTileSpec; static;
    class function LoadTileUpgradeMap: TDictionary<string, string>;
    class function Get(TileNumber: Integer): TTileSpec; static;
    class function GetTileCount: Integer; static;
  end;

implementation

uses
  System.IOUtils, System.Types;

{ TTiles }

class constructor TTiles.Create;
begin
  FUTF8Encoding := TEncoding.UTF8;
  FTilesByName := TDictionary<string, TTileSpec>.Create;
  try
    ReadTiles;
    CheckTiles;
  except
    on E: Exception do
      raise Exception.Create('Failed to initialize Tiles: ' + E.Message);
  end;
end;

class destructor TTiles.Destroy;
begin
  FTilesByName.Free;
  // Free each TileSpec in FTiles array
  for var TileSpec in FTiles do
    TileSpec.Free;
  inherited;
end;

class procedure TTiles.ReadTiles;
var
  TilesList: TObjectList<TTileSpec>;
  TilesRc: TStringList;
  TileNames: TArray<string>;
  I: Integer;
  TileName, RawSpec: string;
  TS: TTileSpec;
  Bi: TBuildingInfo;
  J, OffX, OffY: Integer;
  MemberTile: TTileSpec;
  ResourceStream: TResourceStream;
begin
  TilesList := TObjectList<TTileSpec>.Create;
  TilesRc := TStringList.Create;
  try
    // Load the /tiles.rc resource file
    //ResourceStream := TResourceStream.Create(HInstance, 'graphics/tiles', RT_RCDATA);
    TilesRc.LoadFromFile('graphics/tiles.rc');  // adjust path accordingly or use resource stream

    TileNames := TTileSpec.GenerateTileNames(TilesRc);
    SetLength(FTiles, Length(TileNames));

    for I := 0 to High(TileNames) do
    begin
      TileName := TileNames[I];
      RawSpec := TTileSpec.GetRecipeValue(TilesRc,TileName); //TilesRc.Values[TileName];
      if RawSpec = '' then
        continue;

      TS := TTileSpec.Parse(I, TileName, RawSpec, TilesRc);
      FTilesByName.Add(TileName, TS);
      FTiles[I] := TS;
    end;

    for I := 0 to High(FTiles) do
    begin
      if FTiles[I]=nil then continue;
      //if i=95 then
      //j:=0;
      FTiles[I].ResolveReferences(FTilesByName);


      Bi := FTiles[I].GetBuildingInfo;
      if Bi <> nil then
      begin
        for J := 0 to Length(Bi.Members) - 1 do
        begin
          MemberTile := Bi.Members[J];
          if Bi.Width >= 3 then
            OffX := -1 + (J mod Bi.Width)
          else
            OffX := J mod Bi.Width;
          if Bi.Height >= 3 then
            OffY := -1 + (J div Bi.Width)
          else
            OffY := J div Bi.Width;

          if (MemberTile.Owner = nil) and ((OffX <> 0) or (OffY <> 0)) then
          begin
            MemberTile.Owner := FTiles[I];
            MemberTile.OwnerOffsetX := OffX;
            MemberTile.OwnerOffsetY := OffY;
          end;
        end;
      end;
    end;
  finally
    TilesRc.Free;
    TilesList.Free;
  end;
end;

class procedure TTiles.CheckTiles;
var
  I: Integer;
begin
  for I := 0 to High(FTiles) do
  begin
    // Placeholder: do something here if needed
  end;
end;

class function TTiles.Load(const TileName: string): TTileSpec;
begin
  if not FTilesByName.TryGetValue(TileName, Result) then
    Result := nil;
end;

class function TTiles.LoadByOrdinal(TileNumber: Integer): TTileSpec;
begin
  Result := Load(IntToStr(TileNumber));
end;

class function TTiles.Get(TileNumber: Integer): TTileSpec;
begin
  if (TileNumber >= 0) and (TileNumber < Length(FTiles)) then
    Result := FTiles[TileNumber]
  else
    Result := nil;
end;

class function TTiles.GetTileCount: Integer;
begin
  Result := Length(FTiles);
end;

class function TTiles.LoadTileUpgradeMap: TDictionary<string, string>;
var
  Props: TStrings;
  I: Integer;
  Key, Value: string;
  RV: TDictionary<string, string>;
begin
  RV := TDictionary<string, string>.Create;
  Props := TStringList.Create;
  try
    try
      Props.LoadFromFile('tiles/aliases.txt');  // adjust path accordingly
      for I := 0 to Props.Count - 1 do
      begin
        Key := Trim(Copy(Props[I], 1, Pos('=', Props[I]) - 1));
        Value := Trim(Copy(Props[I], Pos('=', Props[I]) + 1, MaxInt));
        RV.Add(Key, Value);
      end;
    except
      on E: Exception do
      begin
        Writeln('tiles/aliases.txt: ', E.Message);
        RV.Free;
        RV := TDictionary<string, string>.Create; // empty map
      end;
    end;
  finally
    Props.Free;
  end;
  Result := RV;
end;

end.
