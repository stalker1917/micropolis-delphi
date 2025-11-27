// This file is part of MicropolisJ.
// Copyright (C) 2013 Jason Long
// Portions Copyright (C) 1989-2007 Electronic Arts Inc.
//
// MicropolisJ is free software; you can redistribute it and/or modify
// it under the terms of the GNU GPLv3, with additional terms.
// See the README file, included in this distribution, for details.

unit GraphsPane;

interface

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.UIConsts,
  FMX.Types, FMX.Controls, FMX.Layouts, FMX.StdCtrls, FMX.Objects, FMX.Graphics,
  MicropolisUnit, System.Generics.Collections,Math,System.TypInfo,Sound,MicropolisMessage,
  CityLocation,SpriteCity,System.Generics.Defaults;

type
  TTimePeriod = (tpTenYears, tpOneTwentyYears);
  TGraphData = (gdResPop, gdComPop, gdIndPop, gdMoney, gdCrime, gdPollution);



type
  TGraphsPane = class(TLayout, IListener)
    //procedure OnPaint(Sender:TObject; Canvas:Fmx.Graphics.TCanvas ; const ARect:System.Types.TRectF );
  private
    FEngine: TMicropolis;
    FTenYearsBtn, FOneTwentyYearsBtn: TSpeedButton;
    FGraphArea: TLayout;
    FDataButtons: TDictionary<TGraphData, TSpeedButton>;
    FTenYearsPress, FOneTwentyYearsPress: Boolean;
    FButPressed : TDictionary<TGraphData, Boolean>;
    procedure OnDismissClicked(Sender: TObject);
    procedure SetTimePeriod(Period: TTimePeriod);
    procedure CreateUI;
    function MakeDataButton(Graph: TGraphData): TSpeedButton;
    function GetHistoryValue(Graph: TGraphData; Pos: Integer): Integer;
    function GetHistoryMax: Integer;
    procedure OnButtonClick(Sender: TObject);
    procedure paintComponent(Canvas: TCanvas);
   procedure OnMyPaint(Sender:TObject; Canvas:Fmx.Graphics.TCanvas ; const ARect:System.Types.TRectF );
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure SetEngine(NewEngine: TMicropolis);
     // IMicropolisListener implementation
    procedure CityMessage(Message: TMicropolisMessage; Loc: TCityLocation);
    procedure CitySound(Sound: TSound; Loc: TCityLocation);
    procedure CensusChanged;
    procedure DemandChanged;
    procedure FundsChanged;
    procedure OptionsChanged;
    procedure EvaluationChanged;
  end;

implementation

uses
  FMX.Forms;

{ TGraphsPane }

constructor TGraphsPane.Create(AOwner: TComponent);
var Graph :TGraphData;
begin
  inherited;
  FDataButtons := TDictionary<TGraphData, TSpeedButton>.Create;
  FButPressed :=  TDictionary<TGraphData, Boolean>.Create;
  for Graph := Low(TGraphData) to High(TGraphData) do FButPressed.Add(Graph,False);
  CreateUI;
  Visible :=False;
  SetTimePeriod(tpTenYears);
end;

destructor TGraphsPane.Destroy;
begin
  FDataButtons.Free;
  inherited;
end;

procedure TGraphsPane.OnButtonClick(Sender: TObject);
var Graph :TGraphData;
begin
if Sender=FTenYearsBtn then SetTimePeriod(tpTenYears);
if Sender=FOneTwentyYearsBtn then SetTimePeriod(tpOneTwentyYears);
//if Sender<>FTenYearsBtn and   Sender<>FOneTwentyYearsBtn then
for Graph := Low(TGraphData) to High(TGraphData) do  FButPressed[Graph] := (Sender as TSpeedButton)=FDataButtons[Graph];
if Visible then Repaint;
//if Visible then PaintComponent(Self.Canvas);

//if Visible then paintComponent(FGraphArea.Canvas);


{if Sender=FDataButtons[gdResPop] then FDataButtons[gdResPop].IsPressed := not FDataButtons[gdResPop].IsPressed;
if Sender=FDataButtons[gdComPop] then FDataButtons[gdComPop].IsPressed := not FDataButtons[gdComPop].IsPressed;
if Sender=FDataButtons[gdIndPop] then FDataButtons[gdIndPop].IsPressed := not FDataButtons[gdIndPop].IsPressed;
if Sender=FDataButtons[gdMoney] then FDataButtons[gdMoney].IsPressed := not FDataButtons[gdMoney].IsPressed;
if Sender=FDataButtons[gdCrime] then FDataButtons[gdCrime].IsPressed := not FDataButtons[gdCrime].IsPressed;
if Sender=FDataButtons[gdPollution] then FDataButtons[gdPollution].IsPressed := not FDataButtons[gdPollution].IsPressed;}


 // end;

end;

procedure TGraphsPane.CreateUI;
var
  ToolsPane: TLayout;
begin
  Align := TAlignLayout.Client; //TAlignLayout.Top;

  // Dismiss button
  var DismissBtn := TButton.Create(Self);
  DismissBtn.Text := 'Dismiss'; // Replace with string from resource
  DismissBtn.Align := TAlignLayout.Bottom;
  DismissBtn.OnClick := OnDismissClicked;
  AddObject(DismissBtn);

  // Main layout
  var MainLayout := TLayout.Create(Self);
  MainLayout.Align := TAlignLayout.Client;
  AddObject(MainLayout);

  // Tools Pane
  ToolsPane := TLayout.Create(MainLayout);
  ToolsPane.Width := 150;
  ToolsPane.Align := TAlignLayout.Left;
  MainLayout.AddObject(ToolsPane);

  // Time period buttons
  FTenYearsBtn := TSpeedButton.Create(ToolsPane);
  FTenYearsBtn.Text := '10 Years';
  FTenYearsBtn.Align := TAlignLayout.Top;
  FTenYearsBtn.OnClick := OnButtonClick;//SetTimePeriod(tpTenYears);//procedure(Sender: TObject) begin
    //SetTimePeriod(tpTenYears);
 // end;
  ToolsPane.AddObject(FTenYearsBtn);

  FOneTwentyYearsBtn := TSpeedButton.Create(ToolsPane);
  FOneTwentyYearsBtn.Text := '120 Years';
  FOneTwentyYearsBtn.Align := TAlignLayout.Top;
  FOneTwentyYearsBtn.OnClick :=OnButtonClick;// procedure(Sender: TObject) begin
   // SetTimePeriod(tpOneTwentyYears);
 // end;
  ToolsPane.AddObject(FOneTwentyYearsBtn);

  // Data buttons
  FDataButtons.Add(gdResPop, MakeDataButton(gdResPop));
  FDataButtons.Add(gdComPop, MakeDataButton(gdComPop));
  FDataButtons.Add(gdIndPop, MakeDataButton(gdIndPop));
  FDataButtons.Add(gdMoney, MakeDataButton(gdMoney));
  FDataButtons.Add(gdCrime, MakeDataButton(gdCrime));
  FDataButtons.Add(gdPollution, MakeDataButton(gdPollution));

  for var Btn in FDataButtons.Values do
    ToolsPane.AddObject(Btn);

  // Graph Area (stub for now)
  FGraphArea := TLayout.Create(MainLayout);
  FGraphArea.Align := TAlignLayout.Client;
  FGraphArea.Margins.Rect := TRectF.Create(10, 10, 10, 10);
 // FGraphArea.Margins.SetBounds(10, 10, 10, 10);
  var Background := TRectangle.Create(FGraphArea);
  Background.Parent := FGraphArea;
  Background.Align := TAlignLayout.Contents;
  Background.Fill.Color := TAlphaColorRec.White;
  Background.Stroke.Kind := TBrushKind.None;
  //FGraphArea.BackgroundColor := TAlphaColorRec.White;
  MainLayout.AddObject(FGraphArea);
  Self.OnPaint := OnMyPaint;

end;

procedure TGraphsPane.OnDismissClicked(Sender: TObject);
begin
  Self.Visible := False;
end;

procedure TGraphsPane.SetEngine(NewEngine: TMicropolis);
begin
  if Assigned(FEngine) then
    FEngine.RemoveListener(Self);

  FEngine := NewEngine;

  if Assigned(FEngine) then
  begin
    FEngine.AddListener(Self);
    // Update graph display here
  end;
end;

procedure TGraphsPane.SetTimePeriod(Period: TTimePeriod);
begin
  FTenYearsPress := (Period = tpTenYears);
  FOneTwentyYearsPress := (Period = tpOneTwentyYears);
  //FTenYearsBtn.IsPressed := (Period = tpTenYears);
 // FOneTwentyYearsBtn.IsPressed := (Period = tpOneTwentyYears);


  //if Visible then paintComponent(FGraphArea.Canvas);// Trigger redraw of graph
end;

function TGraphsPane.MakeDataButton(Graph: TGraphData): TSpeedButton;
begin
  Result := TSpeedButton.Create(Self);
  Result.Text := GetEnumName(TypeInfo(TGraphData), Ord(Graph));
  Result.Align := TAlignLayout.Top;
  Result.OnClick := OnButtonClick;
end;

function TGraphsPane.GetHistoryMax: Integer;
var
  G: TGraphData;
  Pos: Integer;
begin
  Result := 0;
  for G := Low(TGraphData) to High(TGraphData) do
    for Pos := 0 to 239 do
      Result := Max(Result, GetHistoryValue(G, Pos));
end;

function TGraphsPane.GetHistoryValue(Graph: TGraphData; Pos: Integer): Integer;
begin
  if not Assigned(FEngine) then
    Exit(0);

  case Graph of
    gdResPop: Result := FEngine.History.Res[Pos];
    gdComPop: Result := FEngine.History.Com[Pos];
    gdIndPop: Result := FEngine.History.Ind[Pos];
    gdMoney: Result := FEngine.History.Money[Pos];
    gdCrime: Result := FEngine.History.Crime[Pos];
    gdPollution: Result := FEngine.History.Pollution[Pos];
  else
    raise Exception.Create('Unknown graph data');
  end;
end;

procedure TGraphsPane.paintComponent(Canvas: TCanvas);
var
  R: TRectF;
  Graph: TGraphData;
  MaxLabelWidth: Single;
  LabelStr: string;
  LeftEdge, RightEdge, TopEdge, BottomEdge: Single;
  XInterval: Single;
  FontHeight: Single;
  Year: Integer;
  I, T, StartTime, UnitPeriod, HashPeriod: Integer;
  IsOneTwenty: Boolean;
  Scale, X, Y: Single;
  Path: TPathData;
  ActivePaths: TDictionary<TGraphData, TPathData>;
  LabelY, LBottom: Single;
  PathList: TArray<TGraphData>;
  PX,PY:Single;
begin
  //if not Assigned(FOwner.FEngine) then Exit;

  Canvas.BeginScene;
  try
    Px :=FGraphArea.Position.X; //(Parent as TLayout).Position.X + Self.Position.X{+100}+FGraphArea.Position.X;     //  Self.Position.X not work
    Py :=FGraphArea.Position.Y-30; //Self.Position.Y+FGraphArea.Position.Y;
    R := TRectF.Create(PX,PY,PX+FGraphArea.Width,PY+FGraphArea.Height);//LocalRect;
    //Canvas.Clear(TAlphaColorRec.White);
    Canvas.Fill.Color := TAlphaColorRec.White;
    Canvas.Fill.Kind := TBrushKind.Solid;

    Canvas.Font.Size := 12;
    //Canvas.Stroke.Color := TAlphaColorRec.Black;
    FontHeight := Canvas.TextHeight('Hg');

    // Measure longest label
    MaxLabelWidth := 0;
    for Graph := Low(TGraphData) to High(TGraphData) do
    begin
      LabelStr := 'graph'; //strings.getString("graph_label."+gd.name());
      MaxLabelWidth := Max(MaxLabelWidth, Canvas.TextWidth(LabelStr));
    end;

    LeftEdge := 4+R.Left;//FGraphArea.Position.X;
    TopEdge := 2 + 2 * FontHeight+R.Top;//FGraphArea.Position.Y;
    BottomEdge := R.Bottom-2;//R.Height - 2;
    RightEdge := R.Right - 4 - MaxLabelWidth - 6;//R.Width - 4 - MaxLabelWidth - 6;
    Canvas.FillRect(R, 0, 0, [], 1.0);

    // Draw top and bottom borders
    Canvas.Stroke.Color := TAlphaColorRec.Black;
    Canvas.Stroke.Thickness := 1;
    Canvas.Stroke.Kind := TBrushKind.Solid;
    Canvas.DrawLine(PointF(LeftEdge, TopEdge), PointF(RightEdge, TopEdge), 1);
    Canvas.DrawLine(PointF(LeftEdge, BottomEdge), PointF(RightEdge, BottomEdge), 1);

    IsOneTwenty := {FOwner.}FOneTwentyYearsPress;//FOneTwentyYearsBtn.IsPressed;
    UnitPeriod := IfThen(IsOneTwenty, 12 * CENSUSRATE, CENSUSRATE);
    HashPeriod := IfThen(IsOneTwenty, 10 * UnitPeriod, 12 * UnitPeriod);
    StartTime := ((FEngine.History.CityTime div UnitPeriod) - 119) * UnitPeriod;
    XInterval := (RightEdge - LeftEdge) / 120;

    // Draw vertical bars and years
    for I := 0 to 119 do
    begin
      T := StartTime + I * UnitPeriod;
      if (T mod HashPeriod = 0) then
      begin
        Year := 1900 + (T div (12 * CENSUSRATE));
        X := LeftEdge + I * XInterval;
        Y := TopEdge + IfThen((T div HashPeriod) mod 2 = 0, FontHeight, 0);
        Canvas.Fill.Color := TAlphaColorRec.Black;
        Canvas.FillText(RectF(X - 20, Y - FontHeight, X + 20, Y + FontHeight),
                        IntToStr(Year), False, 1, [], TTextAlign.Leading);
        Canvas.DrawLine(PointF(X, TopEdge), PointF(X, BottomEdge), 1);
      end;
    end;

    // Draw paths
    ActivePaths := TDictionary<TGraphData, TPathData>.Create;
    try
      Scale := Max(256.0, GetHistoryMax);
      for Graph := Low(TGraphData) to High(TGraphData) do
      begin
        if FButPressed[Graph]=True then //FDataButtons[Graph].IsPressed then
        begin
          Path := TPathData.Create;
          for I := 0 to 119 do
          begin
            X := LeftEdge + I * XInterval;
            Y := BottomEdge - GetHistoryValue(Graph, IfThen(IsOneTwenty, 239, 119) - I) * (BottomEdge - TopEdge) / Scale;
            if I = 0 then
              Path.MoveTo(PointF(X, Y))
            else
              Path.LineTo(PointF(X, Y));
          end;
          ActivePaths.Add(Graph, Path);
        end;
      end;

      // Sort paths (descending Y)
      PathList := ActivePaths.Keys.ToArray;
      TArray.Sort<TGraphData>(PathList,
        TComparer<TGraphData>.Construct(
          function(const A, B: TGraphData): Integer
          begin
            Result := -CompareValue(
              ActivePaths[A].Points[ActivePaths[A].Count-1].Point.Y,
              ActivePaths[B].Points[ActivePaths[B].Count-1].Point.Y
            );
          end));

      // Draw paths with labels
      LBottom := BottomEdge;
      for Graph in PathList do
      begin
        LabelStr := 'Graph'; //Graph.ToString;//Strings.Get('public-opinion-1');
        Path := ActivePaths[Graph];
        Canvas.Stroke.Color := TAlphaColorRec.Blue; // Customize color
        Canvas.Stroke.Thickness := 2;
        Canvas.DrawPath(Path, 1);

        LabelY := Path.Points[Path.Count-1].Point.Y + FontHeight / 2;
        LabelY := Min(LBottom, LabelY);
        LBottom := LabelY - FontHeight;

        Canvas.Fill.Color := TAlphaColorRec.Black;
        Canvas.FillText(RectF(RightEdge + 6, LabelY - FontHeight, R.Width, LabelY),
                        LabelStr, False, 1, [], TTextAlign.Leading);
      end;
    finally
      for Path in ActivePaths.Values do
        Path.Free;
      ActivePaths.Free;
    end;

  finally
    Canvas.EndScene;
  end;
end;

procedure TGraphsPane.OnMyPaint;
begin
  PaintComponent(Canvas); //FGraphArea.Canvas);
end;

procedure TGraphsPane.CityMessage(Message: TMicropolisMessage; Loc: TCityLocation);
begin
  //TODO
end;
procedure TGraphsPane.CitySound(Sound: TSound; Loc: TCityLocation);
begin
  //TODO
end;
procedure TGraphsPane.CensusChanged;
begin
  //TODO
end;
procedure TGraphsPane.DemandChanged;
begin
  //TODO
end;
procedure TGraphsPane.FundsChanged;
begin
  //TODO
end;
procedure TGraphsPane.OptionsChanged;
begin
  //TODO
end;
procedure TGraphsPane.EvaluationChanged;
begin
  //TODO
end;

end.