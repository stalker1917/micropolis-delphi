// This file is part of MicropolisJ.
// Copyright (C) 2013 Jason Long
// Portions Copyright (C) 1989-2007 Electronic Arts Inc.
//
// MicropolisJ is free software; you can redistribute it and/or modify
// it under the terms of the GNU GPLv3, with additional terms.
// See the README file, included in this distribution, for details.

unit OverlayMapView;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Graphics, FMX.Objects, FMX.ScrollBox, FMX.Layouts,
  MicropolisUnit, FMX.StdCtrls,SpriteCity,MapState,FMX.Forms,
  TerrainBehavior,TileConstants,MicropolisDrawingArea,TileImages,Math.Vectors;

const
	VAL_LOW       = $bfbfbf;
	VAL_MEDIUM    = $ffff00;
	VAL_HIGH      = $ff7f00;
	VAL_VERYHIGH  = $ff0000;
	VAL_PLUS      = $007f00;
	VAL_VERYPLUS  = $00e600;
	VAL_MINUS     = $ff7f00;
	VAL_VERYMINUS = $ffff00;
  UNPOWERED  = $6666e6;   //lightblue
  POWERED    = $ff0000;   //red
	CONDUCTIVE = $bfbfbf;   //lightgray
  OMV_VERTICAL = 0;
  TILE_WIDTH = 3;
	TILE_HEIGHT = 3;
  TILE_OFFSET_Y = 3;





type
{
  TMapState = (
    ALL,
    RESIDENTIAL,
    COMMERCIAL,
    INDUSTRIAL,
    POWER_OVERLAY,
    TRANSPORT,
    TRAFFIC_OVERLAY,
    LANDVALUE_OVERLAY,
    POLICE_OVERLAY,
    FIRE_OVERLAY,
    CRIME_OVERLAY,
    POLLUTE_OVERLAY,
    GROWTHRATE_OVERLAY,
    POPDEN_OVERLAY
  );
  }

  (*
  IMapListener = interface
    ['{D140E223-8359-4F4F-8616-2620DA1B7E79}']
    procedure MapOverlayDataChanged(OverlayDataType: TMapState);
    procedure SpriteMoved;
    procedure MapAnimation;
    procedure TileChanged(XPos, YPos: Integer);
    procedure WholeMapChanged;
  end;  *)

  TConnectedView = class(TInterfacedObject{,  IChangeListener})
  private
    FView: TMicropolisDrawingArea;
    FScrollBox: TScrollBox; // FMX equivalent of JScrollPane
    procedure RepaintView;
  public
    constructor Create(AView: TMicropolisDrawingArea; AScrollBox: TScrollBox);
    procedure StateChanged(Sender: TObject; const OldViewportPosition, NewViewportPosition: TPointF;
                                    const ContentSizeChanged: Boolean);
  end;


  TOverlayMapView = class(TControl, IMapListener)
    procedure OnMvMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure OnMvMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
  private
    FEngine: TMicropolis;
    FViews: TList;
    FMapState: TMapState;
    FOwner : TForm;
    //const TILE_WIDTH = 3;
    //const TILE_HEIGHT = 3;
    tileArray : TTileImages;

    procedure DragViewToCityCenter;
    procedure DragViewTo(P: TPointF);

    procedure InvalidateRect(X, Y: Integer); overload;
    procedure SetMapState(const Value: TMapState);
    function GetPreferredSize: TSizeF;
    function GetCI(X: Integer): TAlphaColor;
    function GetCI_rog(X: Integer): TAlphaColor;
    procedure DrawPollutionMap(const Canvas: TCanvas);
    procedure MaybeDrawRect(const Canvas: TCanvas; Color: TAlphaColor; X, Y, Width, Height: Single);
    procedure DrawCrimeMap(const Canvas: TCanvas);
    procedure DrawPopDensity(const Canvas: TCanvas);
    procedure DrawRateOfGrowth(const Canvas: TCanvas);
    procedure DrawFireRadius(const Canvas: TCanvas);
    procedure DrawPoliceRadius(const Canvas: TCanvas);
    function CheckLandValueOverlay(Bitmap: TBitmap; XPos, YPos, Tile: Integer): Integer;
    function CheckTrafficOverlay(Bitmap: TBitmap; XPos, YPos, Tile: Integer): Integer;
    function CheckPower(Bitmap: TBitmap; X, Y, RawTile: Integer): Integer;
    procedure PaintComponent(Canvas: TCanvas);
    procedure PaintTile(Bitmap: TBitmap; X, Y, Tile: Integer);
    function GetViewRect(const Cv: TConnectedView): TRectF;
   // procedure DragViewTo(const P: TPointF);
    function GetPreferredScrollableViewportSize: TSizeF;
    function GetScrollableBlockIncrement(const VisibleRect: TRectF;
  Orientation: Integer; Direction: Integer): Single;
    function GetScrollableTracksViewportWidth: Boolean;
    function GetScrollableTracksViewportHeight: Boolean;
    function GetScrollableUnitIncrement(const VisibleRect: TRectF;
  Orientation: Integer; Direction: Integer): Single;

  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent; Engine: TMicropolis); //override;
    destructor Destroy; override;
    procedure ConnectView(AView: TMicropolisDrawingArea; AScrollBox: TScrollBox);
    procedure SetEngine(NewEngine: TMicropolis);
    // IMapListener methods
    procedure MapOverlayDataChanged(OverlayDataType: TMapState);
    procedure SpriteMoved(Sprite: TSprite);
    procedure MapAnimation;
    procedure TileChanged(XPos, YPos: Integer);
    procedure WholeMapChanged;

    property Engine: TMicropolis read FEngine write SetEngine;
    property MapState: TMapState read FMapState write FMapState;

  end;

implementation

uses
  System.Math;

{ TOverlayMapView }

{
constructor TOverlayMapView.Create(AOwner: TComponent);
begin
  inherited;
  FViews := TList.Create;
  FMapState := TMapState.msALL;
  CanFocus := True;
  HitTest := True;
  //OnMouseDown := OnMouseDown;
  //OnMouseMove := OnMouseMove;
end;
}

destructor TOverlayMapView.Destroy;
begin
  FViews.Free;
  inherited;
end;

procedure TOverlayMapView.SetEngine(NewEngine: TMicropolis);
begin
  if Assigned(FEngine) then
    FEngine.RemoveMapListener(Self);

  FEngine := NewEngine;

  if Assigned(FEngine) then
    FEngine.AddMapListener(Self);

  Repaint;
  if Assigned(FEngine) then
  begin
    FEngine.CalculateCenterMass;
    DragViewToCityCenter;
  end;
end;

{
procedure TOverlayMapView.DragViewTo(P: TPointF);
begin
  // To be implemented based on FMX ScrollBox handling
end;
}

procedure TOverlayMapView.DragViewToCityCenter;
begin
  if Assigned(FEngine) then
    DragViewTo(Point(TILE_WIDTH * FEngine.CenterMassX + 1, TILE_HEIGHT * FEngine.CenterMassY + 1));
end;

procedure TOverlayMapView.OnMvMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if Button = TMouseButton.mbLeft then
    DragViewTo(Point(Round(X), Round(Y)));
end;

procedure TOverlayMapView.OnMvMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
begin
  if ssLeft in Shift then
    DragViewTo(Point(Round(X), Round(Y)));
end;

procedure TOverlayMapView.InvalidateRect(X, Y: Integer);
begin
  InvalidateRect(TRectF.Create(X * TILE_WIDTH, Y * TILE_HEIGHT, (X + 1) * TILE_WIDTH, (Y + 1) * TILE_HEIGHT));
end;

procedure TOverlayMapView.Paint;
begin
  inherited;
  PaintComponent(Self.Canvas);  //Bad effect - paint component on every onpaint;
  // Tile rendering implementation would go here
end;

{
procedure TOverlayMapView.ConnectView(View: TObject; ScrollBox: TScrollBox);
begin
  FViews.Add(Pointer(View));
end;
}

procedure TOverlayMapView.MapOverlayDataChanged(OverlayDataType: TMapState);
begin
  Repaint;
end;

procedure TOverlayMapView.SpriteMoved;
begin
  // Optional: implement if sprite overlay effects are needed
end;

procedure TOverlayMapView.MapAnimation;
begin
  // Optional: implement for animated overlays
end;

procedure TOverlayMapView.TileChanged(XPos, YPos: Integer);
begin
  InvalidateRect(XPos, YPos);
end;

procedure TOverlayMapView.WholeMapChanged;
begin
  Repaint;
  if Assigned(FEngine) then
  begin
    FEngine.CalculateCenterMass;
    DragViewToCityCenter;
  end;
end;

constructor TOverlayMapView.Create(AOwner: TComponent; Engine: TMicropolis);
begin
  inherited Create(AOwner);
  FOwner := Aowner as TForm;
  FViews := TList.Create;
  FMapState := TMapState.msALL;
  CanFocus := True;
  HitTest := True;

  Assert(Engine <> nil, 'Engine must not be nil');
  Self.OnMouseDown :=  Self.OnMvMouseDown;
  Self.OnMouseMove :=  Self.OnMvMouseMove;
  //Self.On
  //Self.OnMouseDown;


  // Connect mouse events
  //OnMouseDown := OnMouseDownHandler;
  //OnMouseMove := OnMouseMoveHandler;

  SetEngine(Engine);
  tileArray := TTileImages.getInstance('sm', TILE_HEIGHT);
end;

{
procedure TOverlayMapView.SetEngine(const Value: TMicropolis);
begin
  Assert(Value <> nil, 'Engine must not be nil');

  if FEngine <> nil then
    FEngine.RemoveMapListener(Self);

  FEngine := Value;

  if FEngine <> nil then
    FEngine.AddMapListener(Self);

  Invalidate; // Map size might have changed

  FEngine.CalculateCenterMass;
  DragViewToCityCenter; // You need to implement this method
end;
}

procedure TOverlayMapView.SetMapState(const Value: TMapState);
begin
  if FMapState = Value then Exit;
  FMapState := Value;
  FOwner.Invalidate;
end;

function TOverlayMapView.GetPreferredSize: TSizeF;
var
  Insets: TRectF;
begin
  Insets := Padding.Rect; // or define your own Insets

  Result.cx := Insets.Left + Insets.Right + TILE_WIDTH * FEngine.GetWidth;
  Result.cy := Insets.Top + Insets.Bottom + TILE_HEIGHT * FEngine.GetHeight;
end;

{
procedure TOverlayMapView.OnMouseDownHandler(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  // Call your onMousePressed equivalent here
  // Example: DoMousePressed(X, Y, Button, Shift);
end;

procedure TOverlayMapView.OnMouseMoveHandler(Sender: TObject; Shift: TShiftState; X, Y: Single);
begin
  // Call your onMouseDragged equivalent here
  // Example: DoMouseDragged(X, Y, Shift);
end;
}

function TOverlayMapView.GetCI(X: Integer): TAlphaColor;
begin
  if X < 50 then
    Result := TAlphaColorRec.Null // equivalent of null; maybe $00000000 or Alpha=0
  else if X < 100 then
    Result := VAL_LOW
  else if X < 150 then
    Result := VAL_MEDIUM
  else if X < 200 then
    Result := VAL_HIGH
  else
    Result := VAL_VERYHIGH;
end;

function TOverlayMapView.GetCI_rog(X: Integer): TAlphaColor;
begin
  if X > 100 then
    Result := VAL_VERYPLUS
  else if X > 20 then
    Result := VAL_PLUS
  else if X < -100 then
    Result := VAL_VERYMINUS
  else if X < -20 then
    Result := VAL_MINUS
  else
    Result := TAlphaColorRec.Null;
end;

procedure TOverlayMapView.DrawPollutionMap(const Canvas: TCanvas);
var
  Y, X: Integer;
  PollutionArray: TInt2DArray;
  ColorToDraw: TAlphaColor;
  Rect: TRectF;
begin
  PollutionArray := FEngine.PollutionMem; // Assuming it's a 2D array of Integer

  for Y := 0 to Length(PollutionArray) - 1 do
  begin
    for X := 0 to Length(PollutionArray[Y]) - 1 do
    begin
      ColorToDraw := GetCI(10 + PollutionArray[Y][X]);
      if ColorToDraw <> TAlphaColorRec.Null then
      begin
        Rect := TRectF.Create(X * 6, Y * 6, X * 6 + 6, Y * 6 + 6);
        Canvas.Fill.Kind := TBrushKind.Solid;
        Canvas.Fill.Color := ColorToDraw;
        Canvas.FillRect(Rect, 0, 0, [], 1);
      end;
    end;
  end;
end;

procedure TOverlayMapView.MaybeDrawRect(const Canvas: TCanvas; Color: TAlphaColor; X, Y, Width, Height: Single);
begin
  if Color <> TAlphaColorRec.Null then
  begin
    Canvas.Fill.Color := Color;
    Canvas.FillRect(TRectF.Create(X, Y, X + Width, Y + Height), 0, 0, [], 1);
  end;
end;

procedure TOverlayMapView.DrawCrimeMap(const Canvas: TCanvas);
var
  Y, X: Integer;
  A: TInt2DArray;
begin
  A := FEngine.CrimeMem;
  for Y := 0 to Length(A) - 1 do
    for X := 0 to Length(A[Y]) - 1 do
      MaybeDrawRect(Canvas, GetCI(A[Y][X]), X * 6, Y * 6, 6, 6);
end;

procedure TOverlayMapView.DrawPopDensity(const Canvas: TCanvas);
var
  Y, X: Integer;
  A: TInt2DArray;
begin
  A := FEngine.PopDensity;
  for Y := 0 to Length(A) - 1 do
    for X := 0 to Length(A[Y]) - 1 do
      MaybeDrawRect(Canvas, GetCI(A[Y][X]), X * 6, Y * 6, 6, 6);
end;

procedure TOverlayMapView.DrawRateOfGrowth(const Canvas: TCanvas);
var
  Y, X: Integer;
  A: TInt2DArray;
begin
  A := FEngine.RateOGMem;
  for Y := 0 to Length(A) - 1 do
    for X := 0 to Length(A[Y]) - 1 do
      MaybeDrawRect(Canvas, GetCI_rog(A[Y][X]), X * 24, Y * 24, 24, 24);
end;

procedure TOverlayMapView.DrawFireRadius(const Canvas: TCanvas);
var
  Y, X: Integer;
  A: TInt2DArray;
begin
  A := FEngine.FireRate;
  for Y := 0 to Length(A) - 1 do
    for X := 0 to Length(A[Y]) - 1 do
      MaybeDrawRect(Canvas, GetCI(A[Y][X]), X * 24, Y * 24, 24, 24);
end;

procedure TOverlayMapView.DrawPoliceRadius(const Canvas: TCanvas);
var
  Y, X: Integer;
  A: TInt2DArray;
begin
  A := FEngine.PoliceMapEffect;
  for Y := 0 to Length(A) - 1 do
    for X := 0 to Length(A[Y]) - 1 do
      MaybeDrawRect(Canvas, GetCI(A[Y][X]), X * 24, Y * 24, 24, 24);
end;

function TOverlayMapView.CheckLandValueOverlay(Bitmap: TBitmap; XPos, YPos, Tile: Integer): Integer;
var
  LandValue: Integer;
  Color: TAlphaColor;
  BitmapData: TBitmapData;
  PX, PY: Integer;
  RectLeft, RectTop: Integer;
begin
  LandValue := FEngine.GetLandValue(XPos, YPos);
  Color := GetCI(LandValue);
  if Color = TAlphaColorRec.Null then
    Exit(Tile);

  RectLeft := XPos * TILE_WIDTH;
  RectTop := YPos * TILE_HEIGHT;

  if Bitmap.Map(TMapAccess.Write, BitmapData) then
  try
    for PY := 0 to TILE_HEIGHT - 1 do
      for PX := 0 to TILE_WIDTH - 1 do
        BitmapData.SetPixel(RectLeft + PX, RectTop + PY, Color);
  finally
    Bitmap.Unmap(BitmapData);
  end;

  Result := CLEAR;
end;


function TOverlayMapView.CheckPower(Bitmap: TBitmap; X, Y, RawTile: Integer): Integer;
var
  Pix: TAlphaColor;
  XX, YY: Integer;
  BitmapData: TBitmapData;
  StartX, StartY: Integer;
begin
  if (RawTile and LOMASK) <= 63 then
    Exit(RawTile and LOMASK);

  if IsZoneCenter(RawTile) then
  begin
    if (RawTile and PWRBIT) <> 0 then
      Pix := POWERED
    else
      Pix := UNPOWERED;
  end
  else if IsConductive(RawTile) then
    Pix := CONDUCTIVE
  else
    Exit(DIRT);

  StartX := X * TILE_WIDTH;
  StartY := Y * TILE_HEIGHT;

  if Bitmap.Map(TMapAccess.Write, BitmapData) then
  try
    for YY := 0 to TILE_HEIGHT - 1 do
      for XX := 0 to TILE_WIDTH - 1 do
        BitmapData.SetPixel(StartX + XX, StartY + YY, Pix);
  finally
    Bitmap.Unmap(BitmapData);
  end;

  Result := -1; // skip bitblt, pixel set done here
end;

function TOverlayMapView.CheckTrafficOverlay(Bitmap: TBitmap; XPos, YPos, Tile: Integer): Integer;
var
  D: Integer;
  C: TAlphaColor;
  XX, YY: Integer;
  BitmapData: TBitmapData;
  StartX, StartY: Integer;
begin
  D := FEngine.GetTrafficDensity(XPos, YPos);
  C := GetCI(D);
  if C = TAlphaColorRec.Null then
    Exit(Tile);

  StartX := XPos * TILE_WIDTH;
  StartY := YPos * TILE_HEIGHT;

  if Bitmap.Map(TMapAccess.Write, BitmapData) then
  try
    for YY := 0 to TILE_HEIGHT - 1 do
      for XX := 0 to TILE_WIDTH - 1 do
        BitmapData.SetPixel(StartX + XX, StartY + YY, C);
  finally
    Bitmap.Unmap(BitmapData);
  end;

  Result := CLEAR;
end;

procedure TOverlayMapView.PaintComponent(Canvas: TCanvas);
var
  Width, Height: Integer;
  Img: TBitmap;
  ClipRect: TRectF;
  MinX, MinY, MaxX, MaxY: Integer;
  X, Y, Tile: Integer;
  Insets: TRectF;
  TmpCanvas: TCanvas;
  cv: TConnectedView;
  ViewRect: TRectF;
begin
  Canvas.BeginScene();
  Width := FEngine.GetWidth;
  Height := FEngine.GetHeight;

  Insets :=  RectF(0, 0, Fowner.Width, Fowner.Height);//GetInsets; // You need to implement this to return TRectF with your margins

  // Create offscreen bitmap matching map size in pixels
  Img := TBitmap.Create(Width * TILE_WIDTH, Height * TILE_HEIGHT);
  try
    // Clear bitmap (optional)
    //Img.Clear(TAlphaColorRec.Black);
    //FOwner.Canvas.Rec
    // Determine clip rectangle in component coordinates
    ClipRect := RectF(0, 0, Fowner.Width, Fowner.Height); //FOwner.Canvas;//ClipRect;

    MinX := Max(0, Trunc((ClipRect.Left - Insets.Left) / TILE_WIDTH));
    MinY := Max(0, Trunc((ClipRect.Top - Insets.Top) / TILE_HEIGHT));
    MaxX := Min(Width, 1 + Trunc((ClipRect.Right - Insets.Left) / TILE_WIDTH));
    MaxY := Min(Height, 1 + Trunc((ClipRect.Bottom - Insets.Top) / TILE_HEIGHT));

    // Draw map tiles to offscreen bitmap
    for Y := MinY to MaxY - 1 do
    begin
      for X := MinX to MaxX - 1 do
      begin
        Tile := FEngine.GetTile(X, Y);

        case FMapState of
          TMapState.msRESIDENTIAL:
            if IsZoneAny(Tile) and (not IsResidentialZoneAny(Tile)) then
              Tile := DIRT;
          TMapState.msCOMMERCIAL:
            if IsZoneAny(Tile) and (not IsCommercialZone(Tile)) then
              Tile := DIRT;
          TMapState.msINDUSTRIAL:
            if IsZoneAny(Tile) and (not IsIndustrialZone(Tile)) then
              Tile := DIRT;
          TMapState.msPOWEROVERLAY:
            Tile := CheckPower(Img, X, Y, FEngine.GetTile(X, Y));
          TMapState.msTRANSPORT,
          TMapState.msTRAFFICOVERLAY:
            begin
              if IsConstructed(Tile) and (not IsRoad(Tile)) and (not IsRail(Tile)) then
                Tile := DIRT;

              if FMapState = TMapState.msTRAFFICOVERLAY then
                Tile := CheckTrafficOverlay(Img, X, Y, Tile);
            end;
          TMapState.msLANDVALUEOVERLAY:
            Tile := CheckLandValueOverlay(Img, X, Y, Tile);
          else
            // default - no changes
        end;

        // Tile = -1 means tile already drawn in CheckPower or similar
        if Tile <> -1 then
          PaintTile(Img, X, Y, Tile);
      end;
    end;

    // Draw the offscreen bitmap to the main canvas at offset by insets
    Canvas.DrawBitmap(Img,
      RectF(0, 0, Img.Width, Img.Height),
      RectF(Insets.Left, Insets.Top, Insets.Left + Img.Width, Insets.Top + Img.Height),
      1.0);

  finally
    Img.Free;
  end;

  // Draw overlays on top

  TmpCanvas := Canvas;
  try
     var M: TMatrix;
     M := TMatrix.Identity;
     M.m31 := Insets.Left;  // X translation
     M.m32 := Insets.Top;   // Y translation
    // Canvas.SetMatrix(M);   //If set matrix canvas go to 0,0 of form.
    //TmpCanvas.Translate(Insets.Left, Insets.Top);

    case FMapState of
      TMapState.msPOLICEOVERLAY: DrawPoliceRadius(TmpCanvas);
      TMapState.msFIREOVERLAY: DrawFireRadius(TmpCanvas);
      TMapState.msCRIMEOVERLAY: DrawCrimeMap(TmpCanvas);
      TMapState.msPOLLUTEOVERLAY: DrawPollutionMap(TmpCanvas);
      TMapState.msGROWTHRATEOVERLAY: DrawRateOfGrowth(TmpCanvas);
      TMapState.msPOPDENOVERLAY: DrawPopDensity(TmpCanvas);
    end;

    // Draw connected views rectangles
    for cv in FViews do
    begin
      ViewRect := GetViewRect(cv);
      TmpCanvas.Stroke.Color := TAlphaColorRec.White;
      TmpCanvas.DrawRect(RectF(ViewRect.Left - 2, ViewRect.Top - 2,
                ViewRect.Right + 2, ViewRect.Bottom + 2), 0, 0, AllCorners, 1);

      TmpCanvas.Stroke.Color := TAlphaColorRec.Black;
      TmpCanvas.DrawRect(RectF(ViewRect.Left, ViewRect.Top,
                ViewRect.Right + 2, ViewRect.Bottom + 2), 0, 0, AllCorners, 1);

      TmpCanvas.Stroke.Color := TAlphaColorRec.Yellow;
      TmpCanvas.DrawRect(RectF(ViewRect.Left - 1, ViewRect.Top - 1,
                ViewRect.Right + 2, ViewRect.Bottom + 2), 0, 0, AllCorners, 1);
    end;

  finally
    // No need to restore canvas translation in FMX, but if you prefer, you can save/restore state
  end;
  Canvas.EndScene;
end;

procedure TOverlayMapView.PaintTile(Bitmap: TBitmap; X, Y, Tile: Integer);
var
  TileImg: TTileImages.TImageInfo;
  DestRect: TRectF;
begin
  Assert(Tile >= 0);

  TileImg := TileArray.GetTileImageInfo(Tile);
  DestRect := RectF(X * TILE_WIDTH, Y * TILE_HEIGHT,
                    (X + 1) * TILE_WIDTH, (Y + 1) * TILE_HEIGHT);
  Bitmap.Canvas.BeginScene();
  TileImg.DrawTo(Bitmap.Canvas, DestRect.Left,DestRect.Top);
   Bitmap.Canvas.EndScene;
end;

function TOverlayMapView.GetViewRect(const Cv: TConnectedView): TRectF;
var
  RawRect: TRectF;
  TileSize: Single;
begin
  RawRect := RectF(Cv.FScrollBox.ViewPortPosition.X,Cv.FScrollBox.ViewPortPosition.Y,Cv.FScrollBox.ViewPortPosition.X+Cv.FScrollBox.Width,Cv.FScrollBox.ViewPortPosition.Y+Cv.FScrollBox.Height);//ViewportRect; // or get the viewport rect in your FMX scrollbox
  TileSize := Cv.FView.GetTileSize;

  Result.Left := RawRect.Left * 3 / TileSize;
  Result.Top := RawRect.Top * 3 / TileSize;
  Result.Width := RawRect.Width * 3 / TileSize;
  Result.Height := RawRect.Height * 3 / TileSize;
end;


procedure TOverlayMapView.DragViewTo( P: TPointF);
var
  Cv: TConnectedView;
  ViewportSize, MapSize: TSizeF;
  NewPos: TPointF;
  TileSize: Single;
begin
  if FViews.Count = 0 then
    Exit;

  Cv := FViews[0];
  TileSize := Cv.FView.GetTileSize;

  ViewportSize := Cv.FScrollBox.LocalRect.Size;
  MapSize := TSizeF.Create(Cv.FView.Width,Cv.FView.Height);//(CV.FScrollBox.Content.Width, CV.FScrollBox.Content.Height);

  NewPos.X := P.X * TileSize / 3 - ViewportSize.Width / 2;
  NewPos.Y := P.Y * TileSize / 3 - ViewportSize.Height / 2;

  NewPos.X := Max(0, Min(NewPos.X, MapSize.Width - ViewportSize.Width));
  NewPos.Y := Max(0, Min(NewPos.Y, MapSize.Height - ViewportSize.Height));

  Cv.FScrollBox.ViewportPosition := NewPos;
  FOwner.Invalidate;
end;

function TOverlayMapView.GetPreferredScrollableViewportSize: TSizeF;
begin
  Result := TSizeF.Create(120, 120);
end;

function TOverlayMapView.GetScrollableBlockIncrement(const VisibleRect: TRectF;
  Orientation: Integer; Direction: Integer): Single;
begin
  if Orientation = OMV_VERTICAL  then
    Result := VisibleRect.Height
  else
    Result := VisibleRect.Width;
end;

function TOverlayMapView.GetScrollableTracksViewportWidth: Boolean;
begin
  Result := False;
end;

function TOverlayMapView.GetScrollableTracksViewportHeight: Boolean;
begin
  Result := False;
end;

function TOverlayMapView.GetScrollableUnitIncrement(const VisibleRect: TRectF;
  Orientation: Integer; Direction: Integer): Single;
begin
  if Orientation = OMV_VERTICAL then
    Result := TILE_HEIGHT
  else
    Result := TILE_WIDTH;
end;

procedure TOverlayMapView.ConnectView(AView: TMicropolisDrawingArea; AScrollBox: TScrollBox);
var
  Cv: TConnectedView;
begin
  Cv := TConnectedView.Create(AView, AScrollBox);
  FViews.Add(Cv);
  FOwner.Invalidate;
end;

 {
procedure TOverlayMapView.OnMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if Button = TMouseButton.mbLeft then
    DragViewTo(PointF(X, Y));
end;

procedure TOverlayMapView.OnMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
begin
  if (ssLeft in Shift) then
    DragViewTo(PointF(X, Y));
end;
}

constructor TConnectedView.Create(AView: TMicropolisDrawingArea; AScrollBox: TScrollBox);
begin
  inherited Create;
  FView := AView;
  FScrollBox := AScrollBox;

  // Connect the scroll event
  FScrollBox.OnViewportPositionChange := StateChanged;
end;

procedure TConnectedView.StateChanged(Sender: TObject; const OldViewportPosition, NewViewportPosition: TPointF;
                                    const ContentSizeChanged: Boolean);
begin
  RepaintView;
end;

procedure TConnectedView.RepaintView;
begin
  FView.Repaint;
end;

end.



