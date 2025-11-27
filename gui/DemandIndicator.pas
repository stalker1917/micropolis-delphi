// This file is part of MicropolisJ.
// Copyright (C) 2013 Jason Long
// Portions Copyright (C) 1989-2007 Electronic Arts Inc.
//
// MicropolisJ is free software; you can redistribute it and/or modify
// it under the terms of the GNU GPLv3, with additional terms.
// See the README file, included in this distribution, for details.

unit DemandIndicator;

interface

uses
  System.SysUtils, System.Types, System.Classes, FMX.Types, FMX.Controls, FMX.Graphics,
  FMX.Objects, MicropolisUnit, SpriteCity,MicropolisMessage,Sound,CityLocation,FMX.Forms; // Assume you have a unit for Micropolis engine declarations

type
  TTimePeriod = (tpTenYears, tpOneTwentyYears);

  TDemandIndicator = class(TControl, IListener)
  private
    FOwner : TForm;
    FEngine: TMicropolis;
    FBackgroundBitmap: TBitmap;

    procedure PaintDemandBars(Canvas: TCanvas);
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent; engine: TMicropolis); //override;
    destructor Destroy; override;
    procedure SetEngine(const Value: TMicropolis);
    procedure DemandChanged; // IMicropolisListener method
    procedure CityMessage( mmessage: TMicropolisMessage;  Loc: TCityLocation);
    procedure CitySound(Sound: TSound;  Loc: TCityLocation);
    procedure CensusChanged;
    procedure EvaluationChanged;
    procedure FundsChanged;
    procedure OptionsChanged;

    property Engine: TMicropolis read FEngine write SetEngine;
  end;

implementation

uses
   System.UITypes, System.Math, FMX.Platform;

{ TDemandIndicator }

const
  UPPER_EDGE = 19;
  LOWER_EDGE = 28;
  MAX_LENGTH = 16;
  RES_LEFT = 8;
  COM_LEFT = 17;
  IND_LEFT = 26;
  BAR_WIDTH = 6;

constructor TDemandIndicator.Create(AOwner: TComponent; engine: TMicropolis);
begin
  inherited Create(AOwner);
  FOwner := AOwner as TForm;
  FBackgroundBitmap := TBitmap.Create;
  // Load the image from resource or file
  // Assuming the resource is included or the file is available
  // Here you need to adapt loading your 'demandg.png' image correctly
  FBackgroundBitmap.LoadFromFile('resources/demandg.png');
  FEngine := Engine;

  Width := FBackgroundBitmap.Width;
  Height := FBackgroundBitmap.Height;
end;

destructor TDemandIndicator.Destroy;
begin
  if FEngine <> nil then
    FEngine.RemoveListener(Self);
  FBackgroundBitmap.Free;
  inherited;
end;

procedure TDemandIndicator.SetEngine(const Value: TMicropolis);
begin
  if FEngine <> nil then
    FEngine.RemoveListener(Self);

  FEngine := Value;

  if FEngine <> nil then
    FEngine.AddListener(Self);

  FOwner.Invalidate; // repaint
end;

procedure TDemandIndicator.Paint;
var
  R: TRectF;
begin
  inherited;

  if Assigned(FBackgroundBitmap) then
  begin
    Canvas.DrawBitmap(FBackgroundBitmap, 
      RectF(0, 0, FBackgroundBitmap.Width, FBackgroundBitmap.Height),
      RectF(0, 0, Width, Height), 1);
  end;

  if FEngine = nil then
    Exit;

  PaintDemandBars(Canvas);
end;

procedure TDemandIndicator.PaintDemandBars(Canvas: TCanvas);
var
  resValve, comValve, indValve: Integer;
  ry0, ry1, cy0, cy1, iy0, iy1: Single;
  resRect, comRect, indRect: TRectF;

  procedure DrawBar(Left: Single; Top0, Top1: Single; Color: TAlphaColor);
  var
    Rect: TRectF;
  begin
    Rect := TRectF.Create(Left, Min(Top0, Top1), BAR_WIDTH, Abs(Top1 - Top0));
    Canvas.Fill.Kind := TBrushKind.Solid;
    Canvas.Fill.Color := Color;
    Canvas.FillRect(Rect, 0, 0, [], 1);

    Canvas.Stroke.Kind := TBrushKind.Solid;
    Canvas.Stroke.Color := TAlphaColors.Black;
    Canvas.Stroke.Thickness := 1;
    Canvas.DrawRect(Rect, 0, 0, [], 1);
  end;

begin
  resValve := FEngine.GetResValve;
  if resValve <= 0 then
    ry0 := LOWER_EDGE
  else
    ry0 := UPPER_EDGE;
  ry1 := ry0 - resValve / 100;
  ry1 := Max(ry0 - MAX_LENGTH, Min(ry1, ry0 + MAX_LENGTH));

  comValve := FEngine.GetComValve;
  if comValve <= 0 then
    cy0 := LOWER_EDGE
  else
    cy0 := UPPER_EDGE;
  cy1 := cy0 - comValve / 100;
  cy1 := Max(cy0 - MAX_LENGTH, Min(cy1, cy0 + MAX_LENGTH));

  indValve := FEngine.GetIndValve;
  if indValve <= 0 then
    iy0 := LOWER_EDGE
  else
    iy0 := UPPER_EDGE;
  iy1 := iy0 - indValve / 100;
  iy1 := Max(iy0 - MAX_LENGTH, Min(iy1, iy0 + MAX_LENGTH));

  if ry0 <> ry1 then
    DrawBar(RES_LEFT, ry0, ry1, TAlphaColors.Green);

  if cy0 <> cy1 then
    DrawBar(COM_LEFT, cy0, cy1, TAlphaColors.Blue);

  if iy0 <> iy1 then
    DrawBar(IND_LEFT, iy0, iy1, TAlphaColors.Yellow);
end;

procedure TDemandIndicator.DemandChanged;
begin
  FOwner.Invalidate; // repaint
end;

procedure TDemandIndicator.CityMessage( Mmessage: TMicropolisMessage;  Loc: TCityLocation);
begin
  // No-op
end;

procedure TDemandIndicator.CitySound(Sound: TSound;  Loc: TCityLocation);
begin
  // No-op
end;

procedure TDemandIndicator.CensusChanged;
begin
  // No-op
end;

procedure TDemandIndicator.EvaluationChanged;
begin
  // No-op
end;

procedure TDemandIndicator.FundsChanged;
begin
  // No-op
end;

procedure TDemandIndicator.OptionsChanged;
begin
  // No-op
end;

end.