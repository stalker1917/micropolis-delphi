// This file is part of MicropolisJ.
// Copyright (C) 2013 Jason Long
// Portions Copyright (C) 1989-2007 Electronic Arts Inc.
//
// MicropolisJ is free software; you can redistribute it and/or modify
// it under the terms of the GNU GPLv3, with additional terms.
// See the README file, included in this distribution, for details.

unit TileSpec;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.Math,
  CityDimension, RegularExpressions;

type
 TTileSpec = class;
 TBuildingInfo = class
      public
        Width, Height: Integer;
        Members: TArray<TTileSpec>;
      end;
  TTileSpec = class
  public
    TileNumber: Integer;
    Name: string;

    AnimNext, OnPower, OnShutdown: TTileSpec;
    CanBulldoze, CanBurn, CanConduct, OverWater, Zone: Boolean;

    Owner: TTileSpec;
    OwnerOffsetX, OwnerOffsetY: Integer;




    BuildingInfo: TBuildingInfo;

    Attributes: TDictionary<string, string>;
    Images: TList<string>;

    constructor Create(ATileNumber: Integer; const ATileName: string);
    destructor Destroy; override;

    class function Parse(ATileNumber: Integer; const ATileName, InStr: string; TilesRc: TStringList): TTileSpec;
    class function GenerateTileNames(TilesRc: TStringList): TArray<string>;
    class function GetRecipeValue(Recipe: TStringList; const Key: string): string;
    function GetAttribute(const Key: string): string;
    function GetBooleanAttribute(const Key: string): Boolean;

    procedure LoadSpec(const InStr: string; TilesRc: TStringList);
    procedure ResolveReferences(TileMap: TDictionary<string, TTileSpec>);

    function IsNumberedTile: Boolean;
    class function MakeOffsetSuffix(DX, DY: Integer): string;

    function GetBuildingInfo: TBuildingInfo;
    function GetBuildingSize: TCityDimension;
    function GetDescriptionNumber: Integer;
    function GetImages: TArray<string>;
    function GetPollutionValue: Integer;
    function GetPopulation: Integer;

    function ToString: string; override;

  private
    procedure ResolveBuildingInfo(TileMap: TDictionary<string, TTileSpec>);
    procedure HandleBuildingPart(const Text: string; TileMap: TDictionary<string, TTileSpec>);

  end;

  TStringScanner = class
  private
    FText: string;
    FPosition: Integer;
  public
    constructor Create(const AText: string);
    function Eof: Boolean;
    function PeekChar: Char;
    procedure EatChar(Expected: Char); overload;
    procedure EatChar; overload;
    function ReadAttributeKey: string;
    function ReadAttributeValue: string;
    function ReadImageSpec: string;
  end;

implementation

{ TTileSpec }

constructor TTileSpec.Create(ATileNumber: Integer; const ATileName: string);
begin
  TileNumber := ATileNumber;
  Name := ATileName;
  AnimNext := nil;
  OnPower := nil;
  OnShutdown := nil;
  owner := nil;
  Attributes := TDictionary<string, string>.Create;
  Images := TList<string>.Create;
end;

destructor TTileSpec.Destroy;
begin
  Attributes.Free;
  Images.Free;
  BuildingInfo.Free;
  inherited;
end;

class function TTileSpec.Parse(ATileNumber: Integer; const ATileName, InStr: string; TilesRc: TStringList): TTileSpec;
begin
  Result := Create(ATileNumber, ATileName);
  Result.LoadSpec(InStr, TilesRc);
end;

function TTileSpec.GetAttribute(const Key: string): string;
begin
  if not Attributes.TryGetValue(Key, Result) then
    Result := '';
end;

function TTileSpec.GetBooleanAttribute(const Key: string): Boolean;
var
  V: string;
begin
  V := GetAttribute(Key);
  Result := SameText(V, 'true');
end;

procedure TTileSpec.LoadSpec(const InStr: string; TilesRc: TStringList);
var
  Scanner: TStringScanner;
  K, V, Sup: string;
  C: Char;
begin
  Scanner := TStringScanner.Create(InStr);
  try
    while not Scanner.Eof do
    begin
      if Scanner.PeekChar = '(' then
      begin
        Scanner.EatChar('(');
        K := Scanner.ReadAttributeKey;
        V := 'true';

        if Scanner.PeekChar = '=' then
        begin
          Scanner.EatChar('=');
          V := Scanner.ReadAttributeValue;
        end;
        Scanner.EatChar(')');

        if not Attributes.ContainsKey(K) then
        begin
          Attributes.Add(K, V);
          Sup := GetRecipeValue(TilesRc, K); // Use the function from previous conversion
          if Sup <> '' then
          begin
            LoadSpec(Sup, TilesRc); // Recursive load
          end;
        end
        else
        begin
          Attributes.AddOrSetValue(K, V);
        end;
      end
      else if CharInSet(Scanner.PeekChar, ['|',' ',#9]) then   //','
      begin
        C := Scanner.PeekChar;
        Scanner.EatChar(C);
      end
      else
      begin
        V := Scanner.ReadImageSpec;
        if V<>'' then Images.Add(V);    //Terrain или terrain@,0 ?    //Need Terrain 0,0
      end;
    end;
  finally
    Scanner.Free;
  end;

  // Set boolean properties
  CanBulldoze := GetBooleanAttribute('bulldozable');
  CanBurn := not GetBooleanAttribute('noburn');
  CanConduct := GetBooleanAttribute('conducts');
  OverWater := GetBooleanAttribute('overwater');
  Zone := GetBooleanAttribute('zone');
end;


{
procedure TTileSpec.LoadSpec(const InStr: string; TilesRc: TStrings);
var
  Attr: string;
  Value: string;
  Parts: TArray<string>;
  I: Integer;
begin
  // Rough parsing: split by whitespace and separators; adjust if needed.
  Parts := InStr.Split([',','|']);
  for I := 0 to High(Parts) do
  begin
    Attr := Trim(Parts[I]);
    if (Attr.StartsWith('(')) and (Attr.EndsWith(')')) then
    begin
      Delete(Attr, 1, 1);
      Delete(Attr, Length(Attr), 1);
      if Attr.Contains('=') then
      begin
        Value := Attr.Substring(Attr.IndexOf('=') + 1).Trim;
        Attr := Attr.Substring(0, Attr.IndexOf('=')).Trim;
      end
      else
        Value := 'true';
      Attributes.AddOrSetValue(Attr, Value);
      // load inherited attributes
      Value := TilesRc.Values[Attr];
      if Value <> '' then
        LoadSpec(Value, TilesRc);
    end
    else if Attr <> '' then
      Images.Add(Attr); //Attr.Trim('"'));  //Отладить дебагером
  end;

  CanBulldoze := GetBooleanAttribute('bulldozable');
  CanBurn := not GetBooleanAttribute('noburn');
  CanConduct := GetBooleanAttribute('conducts');
  OverWater := GetBooleanAttribute('overwater');
  Zone := GetBooleanAttribute('zone');
end;
}

procedure TTileSpec.ResolveReferences(TileMap: TDictionary<string, TTileSpec>);
var
  Tmp: string;
begin
  if Attributes.TryGetValue('becomes', Tmp) then
    if Tmp<>'143' then AnimNext := TileMap.Items[Tmp]
                  else AnimNext := TileMap.Items['95'];
  if Attributes.TryGetValue('onpower', Tmp) then
    OnPower := TileMap.Items[Tmp];
  if Attributes.TryGetValue('onshutdown', Tmp) then
    OnShutdown := TileMap.Items[Tmp];
  if Attributes.TryGetValue('building-part', Tmp) then
    HandleBuildingPart(Tmp, TileMap);
  ResolveBuildingInfo(TileMap);
end;

procedure TTileSpec.ResolveBuildingInfo(TileMap: TDictionary<string, TTileSpec>);
var
  Tmp, Sx, Sy: string;
  BI: TBuildingInfo;
  I, W, H, StartTile, Row, Col: Integer;
begin
  if not Attributes.TryGetValue('building', Tmp) then Exit;
  BI := TBuildingInfo.Create;
  W := StrToInt(Tmp.Split(['x'])[0]);
  H := StrToInt(Tmp.Split(['x'])[1]);
  BI.Width := W;
  BI.Height := H;
  SetLength(BI.Members, W*H);

  if IsNumberedTile then
  begin
    StartTile := StrToInt(Name);
    if W >= 3 then Dec(StartTile);
    if H >= 3 then Dec(StartTile, W);
    for Row := 0 to H - 1 do
      for Col := 0 to W - 1 do
        BI.Members[Row*W+Col] := TileMap.Items[IntToStr(StartTile + Row*W + Col)];
  end
  else
  begin
    for Row := 0 to H - 1 do
      for Col := 0 to W - 1 do
        BI.Members[Row*W+Col] :=
          TileMap.Items[Name + MakeOffsetSuffix(Col + IfThen(W >= 3, -1, 0),
                                                Row + IfThen(H >= 3, -1, 0))];
  end;

  BuildingInfo.Free;
  BuildingInfo := BI;
end;

procedure TTileSpec.HandleBuildingPart(const Text: string; TileMap: TDictionary<string, TTileSpec>);
var
  Parts: TArray<string>;
begin
  Parts := Text.Split([',']);
  if Length(Parts) <> 3 then
    raise Exception.Create('Invalid building-part spec');

  Owner := TileMap.Items[Parts[0]];
  OwnerOffsetX := StrToInt(Parts[1]);
  OwnerOffsetY := StrToInt(Parts[2]);
end;

function TTileSpec.IsNumberedTile: Boolean;
begin
  Result := TRegEx.IsMatch(Name, '^\d+$');
end;

class function TTileSpec.MakeOffsetSuffix(DX, DY: Integer): string;
begin
  Result := '';
  if (DX = 0) and (DY = 0) then Exit;

  if DY > 0 then Result := Result + Format('@S%d', [DY])
  else if DY < 0 then Result := Result + Format('@N%d', [-DY]);
  if DX > 0 then Result := Result + Format('E%d', [DX])
  else if DX < 0 then Result := Result + Format('W%d', [-DX]);
end;

function TTileSpec.GetBuildingInfo: TBuildingInfo;
begin
  Result := BuildingInfo;
end;

function TTileSpec.GetBuildingSize: TCityDimension;
begin
  if Assigned(BuildingInfo) then
    Exit(TCityDimension.Create(BuildingInfo.Width, BuildingInfo.Height));
  Result := nil;
end;

function TTileSpec.GetDescriptionNumber: Integer;
var
  V: string;
begin
  Result := -1;
  if Attributes.TryGetValue('description', V) and V.StartsWith('#') then
    Result := StrToInt(Copy(V, 2, MaxInt))
  else if Assigned(Owner) then
    Result := Owner.GetDescriptionNumber;
end;

function TTileSpec.GetImages: TArray<string>;
begin
  Result := Images.ToArray;
end;

function TTileSpec.GetPollutionValue: Integer;
var
  V: string;
begin
  if Attributes.TryGetValue('pollution', V) then
    Result := StrToInt(V)
  else if Assigned(Owner) then
    Result := Owner.GetPollutionValue
  else
    Result := 0;
end;

function TTileSpec.GetPopulation: Integer;
var
  V: string;
begin
  if Attributes.TryGetValue('population', V) then
    Result := StrToInt(V)
  else
    Result := 0;
end;

class function TTileSpec.GenerateTileNames(TilesRc: TStringList): TArray<string>;
var
  Keys: TList<string>;
  NTiles, NaturalNumberTiles, I, X: Integer;
  Line, N,S: string;
  SpacePos: Integer;
begin
  // First, extract all keys from non-comment lines
  Keys := TList<string>.Create;
  try
    for Line in TilesRc do
    begin
      S := Trim(Line);
      if (S = '') or Line.StartsWith('#') then
        Continue;

      // Extract the key (first token before space)
      SpacePos := Pos(' ', S);
      if SpacePos > 0 then
        N := Copy(S, 1, SpacePos - 1)
      else
        N := S;

      Keys.Add(N);
    end;

    SetLength(Result, Keys.Count);
    NTiles := 0;

    // First pass: add numeric keys in order
    I := 0;
    while Keys.Contains(IntToStr(I)) do
    begin
      Result[NTiles] := IntToStr(I);
      Inc(NTiles);
      Inc(I);
    end;
    NaturalNumberTiles := NTiles;

    // Second pass: add remaining keys
    for N in Keys do
    begin
      // Skip numeric keys already processed
      if TRegEx.IsMatch(N, '^\d+$') then
      begin
        X := StrToInt(N);
        if (X >= 0) and (X < NaturalNumberTiles) then
        begin
          Assert(Result[X] = N);
          Continue;
        end;
      end;

      Assert(NTiles < Length(Result));
      Result[NTiles] := N;
      Inc(NTiles);
    end;

    Assert(NTiles = Length(Result));
  finally
    Keys.Free;
  end;
end;


{
class function TTileSpec.GenerateTileNames(TilesRc: TStringList): TArray<string>;
var
  I, N, Count: Integer;
begin
  Count := TilesRc.Count;
  SetLength(Result, Count);
  N := 0;
  for I := 0 to Count - 1 do
    if TilesRc.IndexOfName(IntToStr(I)) >= 0 then
      Result[N] := IntToStr(I);
  for I := 0 to Count - 1 do
    if not TRegEx.IsMatch(TilesRc.Names[I], '^\d+$') then
      Result[N] := TilesRc.Names[I];
end;
}

class function TTileSpec.GetRecipeValue(Recipe: TStringList; const Key: string): string;
var
  Line,S: string;
  SpacePos, ParenPos: Integer;
  CurrentKey: string;
begin
  Result := '';

  for Line in Recipe do
  begin
    S := Trim(Line);

    // Skip comments and empty lines
    if (S = '') or S.StartsWith('#') then
      Continue;

    // Extract the key (first token before space)
    SpacePos := Pos(' ', S);
    if SpacePos > 0 then
      CurrentKey := Copy(S, 1, SpacePos - 1)
    else
      CurrentKey := S;

    // Check if this is the key we're looking for
    if CurrentKey = Key then
    begin
      // Extract the value (everything after the key)
      if SpacePos > 0 then
      begin
        Result := Trim(Copy(S, SpacePos + 1, MaxInt));

        // Remove any trailing comments (if present)
       // ParenPos := Pos('(', Result);
       // if ParenPos > 0 then
         // Result := Trim(Copy(Result, 1, ParenPos - 1));
      end;
      Exit;
    end;
  end;
end;

function TTileSpec.ToString: string;
begin
  Result := '{tile:' + Name + '}';
end;

constructor TStringScanner.Create(const AText: string);
begin
  FText := AText;
  FPosition := 1;
end;

function TStringScanner.Eof: Boolean;
begin
  Result := FPosition > Length(FText);
end;

function TStringScanner.PeekChar: Char;
begin
  if Eof then
    Result := #0
  else
    Result := FText[FPosition];
end;

procedure TStringScanner.EatChar(Expected: Char);
begin
  if PeekChar <> Expected then
    raise Exception.CreateFmt('Expected "%s" but found "%s"', [Expected, PeekChar]);
  Inc(FPosition);
end;

procedure TStringScanner.EatChar;
begin
  if not Eof then
    Inc(FPosition);
end;

function TStringScanner.ReadAttributeKey: string;
var
  StartPos: Integer;
begin
  // Read until '=', ')', or whitespace
  StartPos := FPosition;
  while not Eof and not CharInSet(PeekChar, ['=', ')', ' ', #9]) do
    EatChar;
  Result := Copy(FText, StartPos, FPosition - StartPos);
end;

function TStringScanner.ReadAttributeValue: string;
var
  StartPos: Integer;
begin
  // Read until ')' or whitespace
  StartPos := FPosition;
  while not Eof and not CharInSet(PeekChar, [')', ' ', #9]) do
    EatChar;
  Result := Copy(FText, StartPos, FPosition - StartPos);
end;

function TStringScanner.ReadImageSpec: string;
var
  StartPos: Integer;
begin
  // Read until '(', '|', ',', or whitespace
  StartPos := FPosition;
  while not Eof and not CharInSet(PeekChar, ['(', '|', ' ', #9]) do  //','
    EatChar;
  Result := Copy(FText, StartPos, FPosition - StartPos);
end;

{
function TTileSpec.GetBooleanAttribute(const Key: string): Boolean;
var
  Value: string;
begin
  Result := False;
  if FAttributes.TryGetValue(Key, Value) then
    Result := (Value = 'true') or (Value = '1') or (Value = 'yes');
end;
}

end.
