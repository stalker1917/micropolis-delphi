// This file is part of MicropolisJ.
// Copyright (C) 2013 Jason Long
// Portions Copyright (C) 1989-2007 Electronic Arts Inc.
//
// MicropolisJ is free software; you can redistribute it and/or modify
// it under the terms of the GNU GPLv3, with additional terms.
// See the README file, included in this distribution, for details.

unit NotificationPane;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Generics.Collections,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.StdCtrls, FMX.Layouts,
  FMX.Objects, FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo,
  MicropolisUnit, MicropolisDrawingArea,MicropolisMessage,
  ZoneStatus,Resources;

type
  TNotificationPane = class(TLayout)
  private
    FHeaderLbl: TLabel;

    FMainPane: TLayout;
    FInfoPane: TControl;
    FEngine: TMicropolis;
    FDismissBtn: TButton;


    const
      VIEWPORT_WIDTH = 160;
      VIEWPORT_HEIGHT = 160;
      QUERY_COLOR: TAlphaColor = $FFFFA500; // Orange

    procedure OnDismissClicked(Sender: TObject);
    procedure SetPicture(engine: TMicropolis; xpos, ypos: Integer);
  public
    FMapView: TMicropolisDrawingArea;
    constructor Create(AOwner: TComponent; engine: TMicropolis); reintroduce;
    
    procedure ShowMessage(engine: TMicropolis; msg: TMicropolisMessage; xpos, ypos: Integer);
    procedure ShowZoneStatus(engine: TMicropolis; xpos, ypos: Integer; zone: TZoneStatus);

    //procedure AddRow(const caption, value: string);
  end;

implementation

uses
  MainWindow; //CityMessages, StatusMessages;   //getBundle -  CityMessages

constructor TNotificationPane.Create(AOwner: TComponent; engine: TMicropolis);
begin
  inherited Create(AOwner);



  FEngine := engine;
  
  // Set up basic layout
  Align := TAlignLayout.Client;
  Visible := False;
  
  // Header label
  FHeaderLbl := TLabel.Create(Self);
  FHeaderLbl.Parent := Self;
  FHeaderLbl.Align := TAlignLayout.Top;
  FHeaderLbl.Height := 30;
  FHeaderLbl.TextAlign := TTextAlign.Center;
  FHeaderLbl.StyledSettings := FHeaderLbl.StyledSettings - [TStyledSetting.FontColor];
  FHeaderLbl.TextSettings.FontColor := TAlphaColors.Black;
  
  // Dismiss button
  FDismissBtn := TButton.Create(Self);
  FDismissBtn.Parent := Self;
  FDismissBtn.Align := TAlignLayout.Bottom;
  FDismissBtn.Height := 30;
  FDismissBtn.Text := MainWindowStrings.ReadString('','notification.dismiss',''); //Get('notification.dismiss');
  FDismissBtn.OnClick := OnDismissClicked;
  
  // Main content area
  FMainPane := TLayout.Create(Self);
  FMainPane.Parent := Self;
  FMainPane.Align := TAlignLayout.Client;
  FMainPane.Margins.Top := 5;
  FMainPane.Margins.Bottom := 5;
  
  // Map view container
  var viewportContainer := TRectangle.Create(FMainPane);
  viewportContainer.Parent := FMainPane;
  viewportContainer.Align := TAlignLayout.Left;
  viewportContainer.Width := VIEWPORT_WIDTH + 20; // Extra for margins
  viewportContainer.Stroke.Color := TAlphaColors.Black;
  viewportContainer.Stroke.Kind := TBrushKind.Solid;
  viewportContainer.Stroke.Thickness := 1;
  viewportContainer.Margins.Left := 4;
  viewportContainer.Margins.Right := 4;
  viewportContainer.Margins.Top := 8;
  viewportContainer.Margins.Bottom := 8;
  
  // Map view
  FMapView := TMicropolisDrawingArea.Create({viewportContainer}AOwner, engine);
  FMapView.Parent := viewportContainer;
  FMapView.Align := TAlignLayout.Center;
  FMapView.Width := VIEWPORT_WIDTH;
  FMapView.Height := VIEWPORT_HEIGHT;

 // MainWindowStrings := TResourceManager.Create('MainWindowStrings');
 // CityMessages :=  TResourceManager.Create('CityMessages');
 // StatusMessages := TResourceManager.Create('StatusMessages');
end;

procedure TNotificationPane.OnDismissClicked(Sender: TObject);
begin
  Visible := False;
end;

procedure TNotificationPane.SetPicture(engine: TMicropolis; xpos, ypos: Integer);
begin
  FMapView.SetEngine(engine);
  // Note: You'll need to implement GetTileBounds in TMicropolisDrawingArea
  var r := FMapView.GetTileBounds(xpos, ypos);
  
  // Adjust view position - FMX doesn't have exact equivalent of JViewport,
  // so you might need to implement scrolling logic in your drawing area
  // This is a simplified approach:
  //FMapView.ScrollTo(r.X + r.Width/2 - VIEWPORT_WIDTH/2,
         //          r.Y + r.Height/2 - VIEWPORT_HEIGHT/2);
end;

procedure TNotificationPane.ShowMessage(engine: TMicropolis; msg: TMicropolisMessage; xpos, ypos: Integer);
begin
  SetPicture(engine, xpos, ypos);

  if Assigned(FInfoPane) then
  begin
    FMainPane.RemoveObject(FInfoPane);
    FInfoPane.Free;
    FInfoPane := nil;
  end;

  FHeaderLbl.Text := CityMessages.ReadString('',mmToSting(msg) + '.title','');//Get(msg.Name + '.title');
  FHeaderLbl.TextSettings.FontColor := ParseColor(CityMessages.ReadString('',mmToSting(msg) + '.color',''));
  
  var myLabel := TMemo.Create(FMainPane);
  myLabel.Parent := FMainPane;
  myLabel.Align := TAlignLayout.Client;
  myLabel.Margins.Left := 10;
  myLabel.Text := CityMessages.ReadString('',mmToSting(msg) + '.detail','');
  myLabel.WordWrap := True;
  myLabel.ReadOnly := True;

  FInfoPane := myLabel;
  Visible := True;
end;

procedure TNotificationPane.ShowZoneStatus(engine: TMicropolis; xpos, ypos: Integer; zone: TZoneStatus);
var
layout :TGridPanelLayout;

procedure AddRow(const caption, value: string);
  begin
    var row := layout.RowCollection.Add;
    row.SizeStyle := TGridPanelLayout.TSizeStyle.Auto;

    var lbl1 := TLabel.Create(layout);
    lbl1.Parent := layout;
    lbl1.Align := TAlignLayout.Left;
    lbl1.Margins.Left := 5;
    lbl1.Text := caption;
    lbl1.StyledSettings := lbl1.StyledSettings - [TStyledSetting.FontColor];
    lbl1.TextSettings.Font.Style := [TFontStyle.fsBold];
    lbl1.SetSubComponent(True);
    layout.AddObject(lbl1);//, 0, layout.RowCollection.Count - 1);

    var lbl2 := TLabel.Create(layout);
    lbl2.Parent := layout;
    lbl2.Align := TAlignLayout.Left;
    lbl2.Margins.Left := 5;
    lbl2.Text := value;
    lbl2.SetSubComponent(True);
    layout.AddObject(lbl2)//, 1, layout.RowCollection.Count - 1);
  end;

begin
  FHeaderLbl.Text := MainWindowStrings.ReadString('','notification.query_hdr','');
  FHeaderLbl.TextSettings.FontColor := QUERY_COLOR;

  var buildingStr := '';
  if zone.building <> -1 then
    buildingStr := StatusMessages.ReadString('','zone.' + zone.building.ToString,'');

  var popDensityStr := StatusMessages.ReadString('','status.' + zone.popDensity.ToString,'');
  var landValueStr := StatusMessages.ReadString('','status.' + zone.landValue.ToString,'');
  var crimeLevelStr := StatusMessages.ReadString('','status.' + zone.crimeLevel.ToString,'');
  var pollutionStr := StatusMessages.ReadString('','status.' + zone.pollution.ToString,'');
  var growthRateStr := StatusMessages.ReadString('','status.' + zone.growthRate.ToString,'');

  SetPicture(engine, xpos, ypos);

  if Assigned(FInfoPane) then
  begin
    FMainPane.RemoveObject(FInfoPane);
    FInfoPane.Free;
    FInfoPane := nil;
  end;

  var p := TVertScrollBox.Create(FMainPane);
  p.Parent := FMainPane;
  p.Align := TAlignLayout.Client;
  FInfoPane := p;

  layout := TGridPanelLayout.Create(p);
  layout.Parent := p;
  layout.Align := TAlignLayout.Top;
  layout.ColumnCollection.BeginUpdate;
  try
    layout.ColumnCollection.Add;
    layout.ColumnCollection.Add;
    layout.ColumnCollection[0].SizeStyle := TGridPanelLayout.TSizeStyle.Absolute;
    layout.ColumnCollection[0].Value := 120;
    layout.ColumnCollection[1].SizeStyle := TGridPanelLayout.TSizeStyle.Auto;
  finally
    layout.ColumnCollection.EndUpdate;
  end;

  // Add rows for each piece of information


  AddRow(MainWindowStrings.ReadString('','notification.zone_lbl',''), buildingStr);
  AddRow(MainWindowStrings.ReadString('','notification.density_lbl',''), popDensityStr);
  AddRow(MainWindowStrings.ReadString('','notification.value_lbl',''), landValueStr);
  AddRow(MainWindowStrings.ReadString('','notification.crime_lbl',''), crimeLevelStr);
  AddRow(MainWindowStrings.ReadString('','notification.pollution_lbl',''), pollutionStr);
  AddRow(MainWindowStrings.ReadString('','notification.growth_lbl',''), growthRateStr);

  Visible := True;
end;





end.

