// This file is part of MicropolisD.
// Copyright (C) 2025 Stalker1917
// Copyright (C) 2013 Jason Long (MicropolisJ)
// Portions Copyright (C) 1989-2007 Electronic Arts Inc.
//
// MicropolisD is free software; you can redistribute it and/or modify
// it under the terms of the GNU GPLv3, with additional terms.
// See the README file, included in this distribution, for details.



unit SpriteCity;

interface
uses System.Generics.Collections,CityProblem,MapState,
  Sound,CityLocation,MicropolisMessage,TileConstants,CityDimension,
  SpriteKind,TileSpec,Tiles,JavaRandom,CityBudget;

type
   TSprite = class;
   IListener = interface
		procedure  cityMessage(mmessage : TMicropolisMessage;loc : TCityLocation);
		procedure  citySound(sound : TSound ; loc: TCityLocation);

		///**
		//* Fired whenever the "census" is taken, and the various historical
	 //	 * counters have been updated. (Once a month in game.)
	 //	 */
		procedure  censusChanged();

	 //	/**
		// * Fired whenever resValve, comValve, or indValve changes.
	 //	 * (Twice a month in game.) */
		procedure  demandChanged();

	 //	/**
		// * Fired whenever the city evaluation is recalculated.
		 //* (Once a year.)
		// */
		procedure  evaluationChanged();

	 //	/**
	 //	 * Fired whenever the mayor's money changes.
	 //	 */
		procedure  fundsChanged();

	 //	/**
	 //	 * Fired whenever autoBulldoze, autoBudget, noDisasters,
		// * or simSpeed change.
	 //	 */
		procedure  optionsChanged();
  end;



  IMapListener = interface
    ['{DFA287C9-B2FB-44A5-9A88-94DBD1B9C502}'] // GUID for COM compatibility (optional)

    /// <summary>
    /// Called on every tick of the simulation.
    /// </summary>
    procedure MapAnimation;

    /// <summary>
    /// Called whenever data for a specific overlay has changed.
    /// </summary>
    procedure MapOverlayDataChanged(OverlayDataType: TMapState);

    /// <summary>
    /// Called when a sprite moves.
    /// </summary>
    procedure SpriteMoved(Sprite: TSprite);

    /// <summary>
    /// Called when a map tile changes, including for animations.
    /// </summary>
    procedure TileChanged(XPos, YPos: Integer);

    /// <summary>
    /// Called when the entire map should be reread and rendered.
    /// </summary>
    procedure WholeMapChanged;
  end;

TByte2DArray = array of array of byte;
Tword2DArray = array of array of word;
TIntArray = array of Integer;
TInt2DArray = array of TIntArray;

TSpriteCity = class(TObject)
  PRNG:TRandom;
  map : TWord2DArray;
  rateOGMem: TInt2DArray;
  listeners: TList<IListener>;
  mapListeners: TList<IMapListener>;
  sprites: TList<TSprite>;
  crashLocation: TCityLocation;
  acycle: Integer;
  noDisasters: Boolean;
  budget: TCityBudget;
  autoBulldoze: Boolean;
  constructor Create;
  function GetTile(XPos, YPos: Integer): Word;
  function GetTileRaw(XPos, YPos: Integer): Word;
  procedure SetTile(xpos, ypos: Integer; newTile: Word);
  procedure FireTileChanged(XPos, YPos: Integer);
  procedure SendMessageAt(message: TMicropolisMessage; x, y: Integer);
  procedure FireCityMessage(const Msg: TMicropolisMessage; const Loc: TCityLocation);
  procedure MakeSound(x, y: Integer; sound: TSound);
  procedure FireCitySound(const Sound: TSound; const Loc: TCityLocation);
  procedure MakeExplosionAt(x, y: Integer);
  function TestBounds(xpos, ypos: Integer): Boolean;
  function GetWidth: Integer;
  function GetHeight: Integer;
  procedure KillZone(xPos, yPos, zoneTile: Integer);
  procedure MakeExplosion(xPos, yPos: Integer);
  procedure FireSpriteMoved(Sprite: TSprite);
  procedure ShutdownZone(xPos, yPos: Integer; const zoneSize: TCityDimension);
  function  AllSprites: TArray<TSprite>;
  procedure Spend(Amount: Integer);
  procedure FireFundsChanged;


end;


  TTileBehavior = class(TObject)
  protected
    FCity: TSpriteCity;
    FPRNG: TRandom; // or whatever type you use for random number generator
    FXPos: Integer;
    FYPos: Integer;
    FTile: Integer;

    procedure Apply; virtual; abstract;

  public
    constructor Create(ACity: TSpriteCity); // virtual;

    procedure ProcessTile(AXPos, AYPos: Integer);
  end;

 // TSpriteKind = (AIR, SHI, TRA, BUS, COP);

  TSprite = class abstract
  protected
    city: TSpriteCity;
    dir: Integer;

    function GetChar(x, y: Integer): Integer;
    procedure MoveImpl; virtual; abstract;

  public
    kind: TSpriteKind;

    offx: Integer;
    offy: Integer;
    width: Integer;
    height: Integer;

    frame: Integer;
    x: Integer;
    y: Integer;

    lastX: Integer;
    lastY: Integer;

    constructor Create(engine: TSpriteCity; kind: TSpriteKind);

    procedure Move;
    function IsVisible: Boolean;

    class function GetDir(orgX, orgY, desX, desY: Integer): Integer; static;
    class function GetDis(x0, y0, x1, y1: Integer): Integer; static;
    class function TurnTo(p, d: Integer): Integer; static;

    procedure ExplodeSprite;
    function CheckSpriteCollision(otherSprite: TSprite): Boolean;
    procedure DestroyTile(xpos, ypos: Integer);
  end;
  TExplosionSprite = class(TSprite)
  public
    constructor Create(Engine: TSpriteCity; AX, AY: Integer);

    procedure MoveImpl; override;

  private
    procedure StartFire(XPos, YPos: Integer);
  end;


implementation

constructor TSpriteCity.Create;
begin
  inherited Create;
  listeners := TList<IListener>.Create;
  mapListeners := TList<IMapListener>.Create;
  sprites := TList<TSprite>.Create;
end;

function TSpriteCity.GetTile(XPos, YPos: Integer): Word;
begin
  Result := map[YPos][XPos] and LOMASK;
end;

procedure TSpriteCity.SetTile(xpos, ypos: Integer; newTile: Word);
begin
  // check to make sure we aren't setting an upper bit using this method
  Assert((newTile and LOMASK) = newTile);

  if Map[ypos][xpos] <> newTile then       //Fmap
  begin
    Map[ypos][xpos] := newTile;
    FireTileChanged(xpos, ypos);
  end;
end;

procedure TSpriteCity.FireTileChanged(XPos, YPos: Integer);
var
  ML: IMapListener;
begin
  for ML in mapListeners do
    ML.TileChanged(XPos, YPos);
end;

procedure TSpriteCity.SendMessageAt(message: TMicropolisMessage; x, y: Integer);
begin
  FireCityMessage(message, TCityLocation.Create(x, y));
end;

procedure TSpriteCity.FireCityMessage(const Msg: TMicropolisMessage; const Loc: TCityLocation);
var
  L: IListener;
begin
  for L in listeners do
    L.CityMessage(Msg, Loc);
end;

procedure TSpriteCity.MakeSound(x, y: Integer; sound: TSound);
begin
  FireCitySound(sound, TCityLocation.Create(x, y));
end;

procedure TSpriteCity.FireCitySound(const Sound: TSound; const Loc: TCityLocation);
var
  L: IListener;
begin
  for L in listeners do
    L.CitySound(Sound, Loc);
end;

procedure TSpriteCity.MakeExplosionAt(x, y: Integer);
begin
  Sprites.Add(TExplosionSprite.Create(Self, x, y));
end;

function TSpriteCity.TestBounds(xpos, ypos: Integer): Boolean;
begin
  Result := (xpos >= 0) and (xpos < GetWidth) and
            (ypos >= 0) and (ypos < GetHeight);
end;

function TSpriteCity.GetWidth: Integer;
begin
  if Length(map) > 0 then
    Result := Length(map[0])
  else
    Result := 0;
end;

function TSpriteCity.GetHeight: Integer;
begin
  Result := Length(map);
end;

procedure TSpriteCity.KillZone(xPos, yPos, zoneTile: Integer);
var
  dim: TCityDimension;
  zoneBase: Integer;
begin
  rateOGMem[yPos div 8][xPos div 8] := rateOGMem[yPos div 8][xPos div 8] - 20;

  Assert(IsZoneCenter(zoneTile));
  dim := GetZoneSizeFor(zoneTile);
  Assert(Assigned(dim));
  Assert(dim.Width >= 3);
  Assert(dim.Height >= 3);

  zoneBase := (zoneTile and LOMASK) - 1 - dim.Width;

  // This will take care of stopping smoke animations
  ShutdownZone(xPos, yPos, dim);
end;

procedure TSpriteCity.ShutdownZone(xPos, yPos: Integer; const zoneSize: TCityDimension);
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
      if Assigned(ts) and Assigned(ts.OnShutdown) then
      begin
        SetTile(x, y, ts.OnShutdown.TileNumber or (tile and ALLBITS));
      end;
    end;
  end;
end;

function TSpriteCity.GetTileRaw(XPos, YPos: Integer): Word;
begin
  Result := map[YPos][XPos];
end;



procedure TSpriteCity.MakeExplosion(xPos, yPos: Integer);
begin
  MakeExplosionAt(xPos * 16 + 8, yPos * 16 + 8);
end;

procedure TSpriteCity.FireSpriteMoved(Sprite: TSprite);
var
  ML: IMapListener;
begin
  for ML in mapListeners do
    ML.SpriteMoved(Sprite);
end;

function TSpriteCity.AllSprites: TArray<TSprite>;
begin
  Result := sprites.ToArray;
end;

procedure TSpriteCity.FireFundsChanged;
var
  L: IListener;
begin
  for L in listeners do
    L.FundsChanged;
end;

procedure TSpriteCity.Spend(Amount: Integer);
begin
  Dec(Budget.TotalFunds, Amount);
  FireFundsChanged;
end;






 constructor TSprite.Create(engine: TSpriteCity; kind: TSpriteKind);
begin
  inherited Create;
  Self.city := engine;
  Self.kind := kind;
  width := 32;
  height := 32;
end;

function TSprite.GetChar(x, y: Integer): Integer;
var
  xpos, ypos: Integer;
begin
  xpos := x div 16;
  ypos := y div 16;
  if city.TestBounds(xpos, ypos) then
    Result := city.GetTile(xpos, ypos)
  else
    Result := -1;
end;

procedure TSprite.Move;
begin
  lastX := x;
  lastY := y;
  MoveImpl;
  city.FireSpriteMoved(Self);
end;

function TSprite.IsVisible: Boolean;
begin
  Result := frame <> 0;
end;

class function TSprite.GetDir(orgX, orgY, desX, desY: Integer): Integer;
const
  Gdtab: array[0..12] of Integer = (0, 3, 2, 1, 3, 4, 5, 7, 6, 5, 7, 8, 1);
var
  dispX, dispY, z, absDist: Integer;
begin
  dispX := desX - orgX;
  dispY := desY - orgY;

  if dispX < 0 then
    if dispY < 0 then z := 11 else z := 8
  else
    if dispY < 0 then z := 2 else z := 5;

  dispX := Abs(dispX);
  dispY := Abs(dispY);
  absDist := dispX + dispY;

  if dispX * 2 < dispY then Inc(z)
  else if dispY * 2 < dispX then Dec(z);

  if (z >= 1) and (z <= 12) then
    Result := Gdtab[z]
  else
  begin
    Assert(False, 'Invalid direction calculation.');
    Result := 0;
  end;
end;

class function TSprite.GetDis(x0, y0, x1, y1: Integer): Integer;
begin
  Result := Abs(x0 - x1) + Abs(y0 - y1);
end;

procedure TSprite.ExplodeSprite;
var
  xpos, ypos: Integer;
begin
  frame := 0;
  city.MakeExplosionAt(x, y);
  xpos := x div 16;
  ypos := y div 16;

  city.crashLocation := TCityLocation.Create(xpos, ypos);

  case kind of
    AIR: city.SendMessageAt(PLANECRASH_REPORT, xpos, ypos);
    SHI: city.SendMessageAt(SHIPWRECK_REPORT, xpos, ypos);
    TRA, BUS: city.SendMessageAt(TRAIN_CRASH_REPORT, xpos, ypos);
    COP: city.SendMessageAt(COPTER_CRASH_REPORT, xpos, ypos);
  end;

  city.MakeSound(xpos, ypos, TSound.Create(EXPLOSION_HIGH));
end;

function TSprite.CheckSpriteCollision(otherSprite: TSprite): Boolean;
begin
  if not IsVisible or not otherSprite.IsVisible then
    Exit(False);

  Result := GetDis(x, y, otherSprite.x, otherSprite.y) < 30;
end;

procedure TSprite.DestroyTile(xpos, ypos: Integer);
var
  t: Integer;
  d: TCityDimension;
begin
  if not city.TestBounds(xpos, ypos) then Exit;

  t := city.GetTile(xpos, ypos);
  if IsOverWater(t) then
  begin
    if IsRoad(t) then
      city.SetTile(xpos, ypos, RIVER);
    Exit;
  end;

  if not IsCombustible(t) then Exit;

  if IsZoneCenter(t) then
  begin
    city.KillZone(xpos, ypos, t);
    d := GetZoneSizeFor(t);
    if (d.Width >= 3) and (d.Height >= 3) then
    begin
      city.MakeExplosion(xpos, ypos);
      Exit;
    end;
  end;

  city.SetTile(xpos, ypos, TINYEXP);
end;

class function TSprite.TurnTo(p, d: Integer): Integer;
begin
  if p = d then Exit(p);
  if p < d then
  begin
    if d - p < 4 then Inc(p) else Dec(p);
  end
  else
  begin
    if p - d < 4 then Dec(p) else Inc(p);
  end;

  if p > 8 then Exit(1);
  if p < 1 then Exit(8);
  Result := p;
end;

constructor TExplosionSprite.Create(Engine: TSpriteCity; AX, AY: Integer);
begin
  inherited Create(Engine, TSpriteKind.EXP);
  x := AX;
  y := AY;
  width := 48;
  height := 48;
  offx := -24;
  offy := -24;
  frame := 1;
end;

procedure TExplosionSprite.MoveImpl;
begin
  if (city.acycle mod 2) = 0 then
  begin
    if frame = 1 then
    begin
      city.MakeSound(x div 16, y div 16, TSound.Create(EXPLOSION_HIGH));
      city.SendMessageAt(MicropolisMessage.EXPLOSION_REPORT, x div 16, y div 16);
    end;
    Inc(frame);
  end;

  if frame > 6 then
  begin
    frame := 0;

    StartFire(x div 16, y div 16);
    StartFire((x div 16) - 1, (y div 16) - 1);
    StartFire((x div 16) + 1, (y div 16) - 1);
    StartFire((x div 16) - 1, (y div 16) + 1);
    StartFire((x div 16) + 1, (y div 16) + 1);
    Exit;
  end;
end;

procedure TExplosionSprite.StartFire(XPos, YPos: Integer);
var
  t: Integer;
begin
  if not city.TestBounds(XPos, YPos) then
    Exit;

  t := city.GetTile(XPos, YPos);
  if (not IsCombustible(t)) and (t <> DIRT) then
    Exit;

  if IsZoneCenter(t) then
    Exit;

  city.SetTile(XPos, YPos, FIRE);
end;

//TTileBehavior

constructor TTileBehavior.Create(ACity: TSpriteCity);
begin
  inherited Create;
  FCity := ACity;
  FPRNG := FCity.PRNG;
end;

procedure TTileBehavior.ProcessTile(AXPos, AYPos: Integer);
begin
  FXPos := AXPos;
  FYPos := AYPos;
  FTile := FCity.GetTile(AXPos, AYPos);
  Apply;
end;











end.
