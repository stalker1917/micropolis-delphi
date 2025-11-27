// This file is part of MicropolisJ.
// Copyright (C) 2013 Jason Long
// Portions Copyright (C) 1989-2007 Electronic Arts Inc.
//
// MicropolisJ is free software; you can redistribute it and/or modify
// it under the terms of the GNU GPLv3, with additional terms.
// See the README file, included in this distribution, for details.

unit MicropolisDrawingArea;

interface

uses
  System.Classes, System.Types, FMX.Types, FMX.Controls, FMX.Graphics,
  FMX.Objects, FMX.Forms, FMX.Types3D, System.UITypes, System.Generics.Collections,
  Math, MicropolisUnit, TileImages,TileConstants,
  SpriteCity,ToolPreview,CityRect,ToolStroke,System.SysUtils,System.IniFiles,
  CityLocation,MapState,FMX.Layouts; // your engine & image units

  const
  BlinkUnpoweredZones = True;
  SHAKE_STEPS = 40;


type
{  TCityLocation = record
    X, Y: Integer;
    constructor Create(AX, AY: Integer);
  end;  }
  TOnMouse = procedure (Sender: TObject; Shift: TShiftState; X, Y: Single) of object;
  TOnPress = procedure (Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single) of object;
  TToolCursor = class(TObject)    //nil нужен, переделать в class;

    rect : TCityRect;
		borderColor : TAlphaColor;
		fillColor : TAlphaColor;
    constructor Create;
	end;

  TMicropolisDrawingArea = class(TControl,IMapListener)

    procedure DAMouseDown(Sender: TObject;Button: TMouseButton; Shift: TShiftState;
      X, Y: Single); //override;
    procedure DAMouseMove(Sender: TObject;Shift: TShiftState; X, Y: Single); //override;
    procedure DAMouseUp(Sender: TObject;Button: TMouseButton; Shift: TShiftState;
      X, Y: Single); //override;
  private
    FOwner :TForm;
    FEngine: TMicropolis;
    FTiles: TTileImages;
    FTileSize: Integer;
    FBlinkTimer: TTimer;
    FBlinkState: Boolean;
    FUnpowered: TList<TPoint>;
    FAnimated: TList<TPoint>;
    // drag state fields:
    FDragging,FTDragging: Boolean;
    FLastMouse: TPointF;
    ShakeStep : Integer;
    toolPreview : TToolPreview;
    ToolCursor : TToolCursor;
    FStrings : TIniFile;
    dragX, dragY : integer;
	  dragging : boolean ;
    blinkUnpoweredZones,Blink : boolean;
    BlinkTimer :  TTimer;




    procedure OnBlinkTimer(Sender: TObject);



    function GetPreferredSize: TSizeF;
    procedure DrawSprite(Canvas: TCanvas; Sprite: TSprite);
  protected
    procedure Paint; override;


    function GetShakeModifier(Row: Integer): Integer;
  public
    // DaX:Single;
    ClientMouseMove : TOnMouse;
    ClientDrag : TOnMouse;
    ClientPress :  TOnPress;
    ClientUp :  TOnPress;

     ParentScroll : TScrollBox;
    constructor Create(AOwner: TComponent;AEngine:TMicropolis);
    destructor Destroy; override;
    procedure SetEngine(const Value: TMicropolis);
    procedure SelectTileSize(NewSize: Integer);
    property Engine: TMicropolis read FEngine write SetEngine;
    procedure SetToolCursor(NewRect: TCityRect; Tool: TMicropolisTool); overload;
    procedure SetToolCursor(NewCursor: TToolCursor); overload;
    function ToolCursorToRect(ARect: TCityRect; TileSize: Integer): TRectF;
    procedure SetToolPreview(NewPreview: TToolPreview);
    function GetScrollableUnitIncrement(Orientation: TOrientation): Integer;
    procedure StartDrag(X, Y: Integer);
    procedure EndDrag(X, Y: Integer);
    procedure ContinueDrag(X, Y: Integer);
    procedure DoBlink(Sender: TObject);
    procedure StartBlinkTimer;
    procedure StopBlinkTimer;
    procedure Shake(Step: Integer);
    //function GetShakeModifier(Row: Integer): Integer;
   // procedure MapOverlayDataChanged();
    procedure MapOverlayDataChanged(OverlayDataType: TMapState);
    procedure SpriteMoved(Sprite: TSprite);
    procedure MapAnimation;  //IMapListener
    procedure TileChanged(X, Y: Integer);
    procedure WholeMapChanged;
    function GetSpriteBounds(Sprite: TSprite; X, Y: Integer): TRectF;
    function GetTileBounds(X, Y: Integer): TRectF;
    function GetTileSize: Integer;
    function GetCityLocation(X, Y: Integer): TCityLocation;
  end;

  function ParseColor(const ColorStr: string): TAlphaColor;

implementation

constructor TMicropolisDrawingArea.Create(AOwner: TComponent;AEngine:TMicropolis);
begin
  inherited Create(AOwner);
  FOwner := AOwner as TForm;
  FEngine := AEngine;
  CanFocus := True;
  HitTest := True;
  FUnpowered := TList<TPoint>.Create;
  FAnimated := TList<TPoint>.Create;
  FBlinkTimer := TTimer.Create(Self);
  FBlinkTimer.Interval := 500;
  FBlinkTimer.OnTimer := OnBlinkTimer;
  FStrings := TIniFile.Create('GuiStrings.properties');
  Self.OnMouseDown := DAMouseDown;
  Self.OnMouseUp := DAMouseUp;
  Self.OnMouseMove := DAMouseMove;
  //DaX := 0;
  //Self.Left := 500;
end;

destructor TMicropolisDrawingArea.Destroy;
begin
  FBlinkTimer.Free;
  FUnpowered.Free;
  FAnimated.Free;
  inherited;
end;

procedure TMicropolisDrawingArea.SelectTileSize(NewSize: Integer);
begin
  FTiles := TTileImages.GetInstance(NewSize); // from your unit
  FTileSize := NewSize;
  Width := FEngine.GetWidth*NewSize;
  Height :=  FEngine.GetHeight*NewSize;
  FOwner.Invalidate;
end;

procedure TMicropolisDrawingArea.SetEngine(const Value: TMicropolis);
begin
  if FEngine <> nil then
    FEngine.RemoveMapListener(Self); // define interface as needed
  FEngine := Value;
  if FEngine <> nil then
    FEngine.AddMapListener(Self);
  FOwner.Invalidate;
end;

procedure TMicropolisDrawingArea.Paint;    //OnPaint
var
  Row, Col, Cell: Integer;
  ClipRect: TRectF;
  MinX, MinY, MaxX, MaxY: Integer;
  ImgInfo: TTileImages.TImageInfo;//TTileImageInfo;
  ShakeOffset: Integer;
  Pt: TPoint;
  Sprite: TSprite;
  X0, X1, Y0, Y1: Integer;
begin
  inherited;

  if FEngine = nil then Exit;
  //BeginScene();

  ClipRect :=  RectF(ParentScroll.ViewportPosition.X,ParentScroll.ViewportPosition.Y,ParentScroll.ViewportPosition.X+Width,ParentScroll.ViewportPosition.Y+Height);  //ParentScroll.ClientRect;
  //{Fowner.};  //Canvas.ClipRect;

  MinX := Max(0, Floor(ClipRect.Left / FTileSize));
  MinY := Max(0, Floor(ClipRect.Top / FTileSize));
  MaxX := Min(FEngine.GetWidth, 1 + Floor((ClipRect.Right - 1) / FTileSize));
  MaxY := Min(FEngine.GetHeight, 1 + Floor((ClipRect.Bottom - 1) / FTileSize));

  for Row := MinY to MaxY - 1 do
    for Col := MaxX - 1 downto MinX do
    begin
      Cell := FEngine.GetTile(Col, Row);

      if BlinkUnpoweredZones and IsZoneCenter(Cell) and not FEngine.IsTilePowered(Col, Row) then
      begin
        FUnpowered.Add(TPoint.Create(Col, Row));
        if FBlinkState then
          Cell := LIGHTNINGBOLT;
      end;

      if Assigned(ToolPreview) then
      begin
        var PreviewCell := ToolPreview.GetTile(Col, Row);
        if PreviewCell <> CLEAR then
          Cell := PreviewCell;
      end;

      ImgInfo := FTiles.GetTileImageInfo(Cell, FEngine.ACycle);

      ShakeOffset := 0;
      if ShakeStep <> 0 then
        ShakeOffset := GetShakeModifier(Row); // define this separately
      //ShakeOffset := ShakeOffset+100;

      ImgInfo.DrawTo(Canvas, Col * FTileSize + ShakeOffset, Row * FTileSize);

      if ImgInfo.Animated then
        FAnimated.Add(TPoint.Create(Col, Row));
    end;

  // Draw all visible sprites
  for Sprite in FEngine.AllSprites do
    if Sprite.IsVisible then
      DrawSprite(Canvas, Sprite);

  // Draw tool cursor if exists
  if Assigned(ToolCursor) then
  begin
    X0 := ToolCursor.Rect.X * FTileSize;
    Y0 := ToolCursor.Rect.Y * FTileSize;
    X1 := (ToolCursor.Rect.X + ToolCursor.Rect.Width) * FTileSize;
    Y1 := (ToolCursor.Rect.Y + ToolCursor.Rect.Height) * FTileSize;

    Canvas.Fill.Color := TAlphaColorRec.Black;
    Canvas.FillRect(RectF(X0 - 1, Y0 - 1, X1, Y0), 0, 0, [], 1);
    Canvas.FillRect(RectF(X0 - 1, Y0, X0, Y1), 0, 0, [], 1);
    Canvas.FillRect(RectF(X0 - 3, Y1 + 3, X1 + 4, Y1 + 4), 0, 0, [], 1);
    Canvas.FillRect(RectF(X1 + 3, Y0 - 3, X1 + 4, Y1 + 3), 0, 0, [], 1);

    Canvas.Fill.Color := TAlphaColorRec.White;
    Canvas.FillRect(RectF(X0 - 4, Y0 - 4, X1 + 4, Y0 - 3), 0, 0, [], 1);
    Canvas.FillRect(RectF(X0 - 4, Y0 - 3, X0 - 3, Y1 + 4), 0, 0, [], 1);
    Canvas.FillRect(RectF(X0 - 1, Y1, X1 + 1, Y1 + 1), 0, 0, [], 1);
    Canvas.FillRect(RectF(X1, Y0 - 1, X1 + 1, Y1), 0, 0, [], 1);

    Canvas.Fill.Color := ToolCursor.BorderColor;
    Canvas.FillRect(RectF(X0 - 3, Y0 - 3, X1 + 1, Y0 - 1), 0, 0, [], 1);
    Canvas.FillRect(RectF(X1 + 1, Y0 - 3, X1 + 3, Y1 + 1), 0, 0, [], 1);
    Canvas.FillRect(RectF(X0 - 1, Y1 + 1, X1 + 3, Y1 + 3), 0, 0, [], 1);
    Canvas.FillRect(RectF(X0 - 3, Y0 - 1, X0 - 1, Y1 + 3), 0, 0, [], 1);

    if ToolCursor.FillColor <> TAlphaColorRec.Null then
    begin
      Canvas.Fill.Color := ToolCursor.FillColor;
      Canvas.FillRect(RectF(X0, Y0, X1, Y1), 0, 0, [], 1);
    end;
  end;
end;

procedure TMicropolisDrawingArea.OnBlinkTimer(Sender: TObject);
begin
  if FUnpowered.Count > 0 then
  begin
    FBlinkState := not FBlinkState;
    Fowner.Invalidate; // re-draw unpowered areas
  end;
end;

procedure TMicropolisDrawingArea.DAMouseDown(Sender: TObject;Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  if (Button = TMouseButton.mbRight) then //mbMiddle) then
  begin
    FDragging := True;
    FLastMouse := PointF(X, Y);
  end;
    if (Button = TMouseButton.mbLeft) then
      begin
        ClientPress(Sender,Button,Shift,X,Y);
        FTDragging := True;
      end;
end;

procedure TMicropolisDrawingArea.DAMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
begin
  //inherited;
  //Переписать с нуля
  //Parent.Vie
  //DaX := X;
  if FDragging {and (ParentScroll is TScrollBox)} then
    ParentScroll.ViewportPosition := PointF(
      ParentScroll.ViewportPosition.X - (X - FLastMouse.X),
      ParentScroll.ViewportPosition.Y - (Y - FLastMouse.Y)
    );
  if FTDragging then ClientDrag(Sender,Shift,X,Y);

  FOwner.Invalidate;
  ClientMouseMove(Sender,Shift,X,Y);

end;

procedure TMicropolisDrawingArea.DAMouseUp(Sender: TObject;Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  //inherited;
  if Button = TMouseButton.mbRight then//mbMiddle then
    FDragging := False;
  if (Button = TMouseButton.mbLeft) then
    begin
      ClientUp(Sender,Button,Shift,X,Y);
      FTDragging := False;
    end;
end;

 {
constructor TCityLocation.Create(AX, AY: Integer);
begin
  X := AX;
  Y := AY;
end;
}

function TMicropolisDrawingArea.GetTileSize: Integer;
begin
  Result := FTileSize; // TILE_WIDTH in Java
end;

function TMicropolisDrawingArea.GetCityLocation(X, Y: Integer): TCityLocation;
begin
  Result := TCityLocation.Create(Trunc(X / FTileSize), Trunc(Y / FTileSize));
end;

function TMicropolisDrawingArea.GetPreferredSize: TSizeF;
begin
  Assert(FEngine <> nil);
  Result := TSizeF.Create(FTileSize * FEngine.GetWidth, FTileSize * FEngine.GetHeight );
end;

procedure TMicropolisDrawingArea.DrawSprite(Canvas: TCanvas; Sprite: TSprite);
var
  Px, Py: Integer;
  Img: TBitmap;
  Rect: TRectF;
begin
  if not Sprite.IsVisible then Exit;

  Px := (Sprite.X + Sprite.OffX) * FTileSize div 16;
  Py := (Sprite.Y + Sprite.OffY) * FTileSize div 16;

  Img := FTiles.GetSpriteImage(Sprite.Kind, Sprite.Frame - 1);
  if Img <> nil then
    Canvas.DrawBitmap(Img, RectF(0, 0, Img.Width, Img.Height), RectF(Px, Py, Px + Img.Width, Py + Img.Height), 1)
  else
  begin
    Canvas.Fill.Color := TAlphaColorRec.Red;
    Canvas.FillRect(RectF(Px, Py, Px + 16, Py + 16), 0, 0, [], 1);
    Canvas.Fill.Color := TAlphaColorRec.White;
    Canvas.FillText(RectF(Px, Py, Px + 32, Py + 32), IntToStr(Sprite.Frame), False, 1, [], TTextAlign.Leading, TTextAlign.Leading);
  end;
end;

procedure TMicropolisDrawingArea.SetToolCursor(NewRect: TCityRect; Tool: TMicropolisTool);
var
  Tp: TToolCursor;
  ToolKey,S: string;

begin
  Tp := TToolCursor.Create;
  Tp.Rect := NewRect;

  ToolKey := 'tool.' + GetToolName(Tool) + '.border';
  S:= FStrings.ReadString('',ToolKey,'NONE');
  if S<>'NONE' then
    ParseColor(S)
  else
    Tp.BorderColor := ParseColor(FStrings.ReadString('','tool.*.border','NONE'));

  ToolKey := 'tool.' + GetToolName(Tool) + '.bgcolor';
  S:= FStrings.ReadString('',ToolKey,'NONE');
  if S<>'NONE' then
    Tp.FillColor := ParseColor(S)
  else
    Tp.FillColor := ParseColor(FStrings.ReadString('','tool.*.bgcolor','NONE'));

  SetToolCursor(Tp);
end;

procedure TMicropolisDrawingArea.SetToolCursor(NewCursor: TToolCursor);
var
  R: TRectF;
begin
  if ToolCursor = NewCursor then Exit;
  if (ToolCursor <> nil) and (NewCursor <> nil)  and (ToolCursor.Rect = NewCursor.Rect) then Exit;

  if ToolCursor <> nil then
  begin
    R := ToolCursorToRect(ToolCursor.Rect, FTileSize);
    InvalidateRect(R);
  end;

  ToolCursor := NewCursor;

  if ToolCursor <> nil then
  begin
    R := ToolCursorToRect(ToolCursor.Rect, FTileSize);
    InvalidateRect(R);
  end;
end;

function TMicropolisDrawingArea.ToolCursorToRect(ARect: TCityRect; TileSize: Integer): TRectF;
begin
  Result := TRectF.Create(
    ARect.X * TileSize - 4,
    ARect.Y * TileSize - 4,
    (ARect.X + ARect.Width) * TileSize + 4,
    (ARect.Y + ARect.Height) * TileSize + 4
  );
end;

procedure TMicropolisDrawingArea.SetToolPreview(NewPreview: TToolPreview);
var
  Bounds: TCityRect;
  R: TRectF;
begin
  if Assigned(ToolPreview) then
  begin
    Bounds := ToolPreview.GetBounds;
    R := TRectF.Create(Bounds.X * FTileSize, Bounds.Y * FTileSize,
                       (Bounds.X + Bounds.Width) * FTileSize, (Bounds.Y + Bounds.Height) * FTileSize);
    InvalidateRect(R);
  end;

  ToolPreview := NewPreview;

  if Assigned(ToolPreview) then
  begin
    Bounds := ToolPreview.GetBounds;
    R := TRectF.Create(Bounds.X * FTileSize, Bounds.Y * FTileSize,
                       (Bounds.X + Bounds.Width) * FTileSize, (Bounds.Y + Bounds.Height) * FTileSize);
    InvalidateRect(R);
  end;
end;


function TMicropolisDrawingArea.GetScrollableUnitIncrement(Orientation: TOrientation): Integer;
begin
  if Orientation = TOrientation.Vertical then
    Result := FTileSize * 3
  else
    Result := FTileSize * 3;
end;



procedure TMicropolisDrawingArea.StartDrag(X, Y: Integer);
begin
  Dragging := True;
  DragX := X;
  DragY := Y;
end;

procedure TMicropolisDrawingArea.EndDrag(X, Y: Integer);
begin
  Dragging := False;
end;

procedure TMicropolisDrawingArea.ContinueDrag(X, Y: Integer);
var
  DX, DY: Integer;
  ParentScroll: TScrollBox;
begin
  DX := X - DragX;
  DY := Y - DragY;

  ParentScroll := TScrollBox(Parent.Parent); // Adjust based on layout
  ParentScroll.ViewportPosition := PointF(
    ParentScroll.ViewportPosition.X - DX,
    ParentScroll.ViewportPosition.Y - DY
  );
end;


procedure TMicropolisDrawingArea.DoBlink(Sender: TObject);
var
  Loc: TPoint;
begin
  if FUnpowered.Count > 0 then
  begin
    Blink := not Blink;

    //for Loc in UnpoweredZones do
      //InvalidateTile(Loc.X, Loc.Y);
    FOwner.Invalidate;
    FUnpowered.Clear;

  end;

end;

procedure TMicropolisDrawingArea.StartBlinkTimer;
begin
  if Assigned(BlinkTimer) then Exit;

  BlinkTimer := TTimer.Create(nil);
  BlinkTimer.Interval := 500;
  BlinkTimer.OnTimer := DoBlink;// procedure
    //begin
     // DoBlink;
    //end;
  BlinkTimer.Enabled := True;
end;

procedure TMicropolisDrawingArea.StopBlinkTimer;
begin
  if Assigned(BlinkTimer) then
  begin
    BlinkTimer.Enabled := False;
    BlinkTimer.Free;
    BlinkTimer := nil;
  end;
end;


procedure TMicropolisDrawingArea.Shake(Step: Integer);
begin
  ShakeStep := Step;
  Fowner.Invalidate;
end;

function TMicropolisDrawingArea.GetShakeModifier(Row: Integer): Integer;
begin
  Result := Round(4.0 * Sin((ShakeStep + Row / 2) / 2.0));
end;

procedure TMicropolisDrawingArea.MapOverlayDataChanged(OverlayDataType: TMapState);
begin
  // Optional: logic to refresh overlays
end;

procedure TMicropolisDrawingArea.SpriteMoved(Sprite: TSprite);
begin
  InvalidateRect(GetSpriteBounds(Sprite, Sprite.LastX, Sprite.LastY));
  InvalidateRect(GetSpriteBounds(Sprite, Sprite.X, Sprite.Y));
end;

procedure TMicropolisDrawingArea.MapAnimation;
var
  Loc: TPoint;
begin
 // for Loc in AnimatedTiles do
    //InvalidateTile(Loc.X, Loc.Y);
  FOwner.Invalidate;
  FAnimated.Clear;
end;

procedure TMicropolisDrawingArea.TileChanged(X, Y: Integer);
begin
  //InvalidateTile(X, Y);
   FOwner.Invalidate;
end;

procedure TMicropolisDrawingArea.WholeMapChanged;
begin
   Fowner.Invalidate;
end;

function TMicropolisDrawingArea.GetSpriteBounds(Sprite: TSprite; X, Y: Integer): TRectF;
begin
  Result := TRectF.Create(
    (X + Sprite.OffX) * FTileSize / 16,
    (Y + Sprite.OffY) * FTileSize / 16,
    ((X + Sprite.OffX) + Sprite.Width) * FTileSize / 16,
    ((Y + Sprite.OffY) + Sprite.Height) * FTileSize / 16
  );
end;

function TMicropolisDrawingArea.GetTileBounds(X, Y: Integer): TRectF;
begin
  Result := TRectF.Create(X * FTileSize, Y * FTileSize, (X + 1) * FTileSize, (Y + 1) * FTileSize);
end;

function ParseColor(const ColorStr: string): TAlphaColor;
var
  HexStr: string;
begin
  Result := TAlphaColorRec.Null; // Default if parsing fails

  if ColorStr.StartsWith('#') then
  begin
    HexStr := ColorStr.Substring(1); // Remove '#'

    case HexStr.Length of
      3: // Short format like "#fff"
        HexStr := HexStr[1] + HexStr[1] + // Expand to 6 digits
                  HexStr[2] + HexStr[2] +
                  HexStr[3] + HexStr[3];
      6, 8: ; // Valid formats "#rrggbb" or "#aarrggbb"
    else
      Exit(TAlphaColorRec.Red); // Or raise exception for invalid format
    end;

    // Convert to TAlphaColor (supports 6-digit and 8-digit hex)
    Result := TAlphaColorRec.Create(
      StrToInt('$' + HexStr.PadLeft(8, 'F')) // Pad alpha to FF if missing
    ).Color;
  end
  else
  begin
    // Try named colors (like "red", "blue")
    //if IdentToAlphaColor('cla' + ColorStr, Integer(Result)) then
      //Exit;

    // Fallback for invalid strings
    Result := TAlphaColorRec.Red;
  end;

end;

constructor TToolCursor.Create;
 begin
   Inherited Create;
 end;

  end.

