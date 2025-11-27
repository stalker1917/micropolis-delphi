// This file is part of MicropolisJ.
// Copyright (C) 2013 Jason Long
// Portions Copyright (C) 1989-2007 Electronic Arts Inc.
//
// MicropolisJ is free software; you can redistribute it and/or modify
// it under the terms of the GNU GPLv3, with additional terms.
// See the README file, included in this distribution, for details.

unit NewCityDialog;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Generics.Collections, FMX.Forms, FMX.Controls, FMX.Types,
  FMX.StdCtrls, FMX.Layouts, FMX.Objects, FMX.Dialogs, MicropolisUnit,
  MapGenerator, OverlayMapView, GameLevel,Resources, FMX.Controls.Presentation,FMX.Graphics;

type
  TNewCityDialog = class(TForm)
    Button1: TButton;
    procedure FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
   // procedure Button1Click(Sender: TObject);
  private
    Engine: TMicropolis;
    PreviousMaps, NextMaps: TStack<TMicropolis>;
    MapPane: TOverlayMapView;
    LevelButtons: TDictionary<Integer, TRadioButton>;
    PreviousMapBtn: TButton;

    procedure CreateUI(ShowCancelOption: Boolean);
    procedure OnPreviousMapClicked(Sender: TObject);
    procedure OnNextMapClicked(Sender: TObject);
    procedure OnLoadCityClicked(Sender: TObject);
    procedure OnPlayClicked(Sender: TObject);
    procedure OnCancelClicked(Sender: TObject);
    procedure OnQuitClicked(Sender: TObject);
    procedure OnRadioButtonChange(Sender: TObject);
    procedure SetGameLevel(Level: Integer);
    function GetSelectedGameLevel: Integer;
    procedure StartPlaying(NewEngine: TMicropolis; const FileName: string);
  public
    constructor CreateDialog(AOwner: TForm; ShowCancelOption: Boolean); reintroduce;
  end;

implementation

{$R *.fmx}


uses
  FMX.DialogService, FMX.DialogService.Async, System.IOUtils,MainWindow;

  {
procedure TNewCityDialog.Button1Click(Sender: TObject);
begin
close;
end;
}

constructor TNewCityDialog.CreateDialog(AOwner: TForm; ShowCancelOption: Boolean);
begin
  inherited Create(AOwner);  //Aowner
  //Owner := AOwner;
  Self.Caption := GetGuiString('welcome.caption');
  Self.BorderStyle := TFmxFormBorderStyle.Sizeable;
  Self.Position := TFormPosition.ScreenCenter;
  Self.Width := 700;
  Self.Height := 400;

  Engine := TMicropolis.Create;
  TMapGenerator.Create(Engine).GenerateNewCity;
  PreviousMaps := TStack<TMicropolis>.Create;
  NextMaps := TStack<TMicropolis>.Create;
  LevelButtons := TDictionary<Integer, TRadioButton>.Create;

  CreateUI(ShowCancelOption);

  SetGameLevel(GameLevel.MIN_LEVEL);
end;

procedure TNewCityDialog.OnRadioButtonChange(Sender: TObject);
begin
 if TRadioButton(Sender).IsChecked then
        SetGameLevel(TRadioButton(Sender).Tag-10);
end;

procedure TNewCityDialog.CreateUI(ShowCancelOption: Boolean);
var
  Root: TLayout;
  MapLayout, OptionsLayout, ButtonLayout: TLayout;
  LevelBox: TVertScrollBox;
  Btn: TButton;
  I: Integer;
  RBtn: TRadioButton;
begin
  Root := TLayout.Create(Self);
  Root.Align := TAlignLayout.Client;
  Root.Padding.Rect := TRectF.Create(20, 20, 20, 20);
  Root.Parent := Self;
  Root.Enabled := True;
  Root.HitTest := False;

  // Map pane
  MapLayout := TLayout.Create(Root);
  MapLayout.Align := TAlignLayout.Left;
  MapLayout.Width := 320;
  MapLayout.Parent := Root;
  MapLayout.HitTest := False;

  MapPane := TOverlayMapView.Create({MapLayout}Self,engine);
  MapPane.Align := TAlignLayout.Client;
  MapPane.Engine := Engine;
  MapPane.Parent := Self;//MapLayout;
  MapPane.HitTest := False;
  // Difficulty options
  OptionsLayout := TLayout.Create(Root);
  OptionsLayout.Align := TAlignLayout.Client;
  OptionsLayout.Parent := Root;
  OptionsLayout.HitTest := False;
  //OptionsLayout.
  //OptionsLayout.Height := 300;

  LevelBox := TVertScrollBox.Create(OptionsLayout);
  LevelBox.Align := TAlignLayout.Client;
 // LevelBox.Height := 300;
  LevelBox.Padding.Top := 10;
  LevelBox.Parent := OptionsLayout;
  LevelBox.Enabled := True;
  LevelBox.HitTest := False;

  for I := GameLevel.MIN_LEVEL to GameLevel.MAX_LEVEL do
  begin
    RBtn := TRadioButton.Create(LevelBox);
    RBtn.Position.X := 50;
    RBtn.Position.Y := 25*i;
    RBtn.HitTest := True;
    //RBtn.
    RBtn.Text := GetGuiString('menu.difficulty.' + I.ToString);
    RBtn.GroupName := 'Difficulty';
    RBtn.OnChange := OnRadioButtonChange;
    RBtn.Parent := LevelBox;
    RBtn.Tag := 10+i;
    LevelButtons.Add(I, RBtn);
  end;

  // Buttons
  ButtonLayout := TLayout.Create(Root);
  ButtonLayout.Align := TAlignLayout.Bottom;
  //ButtonLayout.Position.Y := 70;
  ButtonLayout.Height := 30;
  ButtonLayout.Padding.Rect := TRectF.Create(10, 5, 10, 5);
  ButtonLayout.HitTest := False;
  ButtonLayout.Enabled := True;
  ButtonLayout.Parent := Root;


  PreviousMapBtn := TButton.Create(ButtonLayout);
  PreviousMapBtn.Text := GetGuiString('welcome.previous_map');
  PreviousMapBtn.OnClick := OnPreviousMapClicked;
  PreviousMapBtn.Enabled := False;
  PreviousMapBtn.Parent := ButtonLayout;

  Btn := TButton.Create(ButtonLayout);
  Btn.Text := GetGuiString('welcome.play_this_map');
  Btn.OnClick := OnPlayClicked;
  Btn.Parent := ButtonLayout;
  //Self.Default := Btn;

  Btn := TButton.Create(ButtonLayout);
  Btn.Position.X := 100;
  Btn.Text := GetGuiString('welcome.next_map');
  Btn.OnClick := OnNextMapClicked;
  Btn.Parent := ButtonLayout;

  Btn := TButton.Create(ButtonLayout);
  Btn.Position.X := 200;
  Btn.Text := GetGuiString('welcome.load_city');
  Btn.OnClick := OnLoadCityClicked;
  Btn.Parent := ButtonLayout;

  Btn := TButton.Create(Self);
  Btn.Position.X := 300;
  Btn.HitTest := True;
  if ShowCancelOption then
  begin
    Btn.Text := GetGuiString('welcome.cancel');
    Btn.OnClick := OnCancelClicked;
  end
  else
  begin
    Btn.Text := GetGuiString('welcome.quit');
    Btn.OnClick := OnQuitClicked;
  end;
  Btn.Parent := ButtonLayout;
 // Button1 := Btn;
end;

procedure TNewCityDialog.FormPaint(Sender: TObject; Canvas: TCanvas;
  const ARect: TRectF);
begin
  MapPane.Repaint;
end;

procedure TNewCityDialog.OnPreviousMapClicked(Sender: TObject);
begin
  if PreviousMaps.Count = 0 then Exit;

  NextMaps.Push(Engine);
  Engine := PreviousMaps.Pop;
  MapPane.Engine := Engine;
  PreviousMapBtn.Enabled := PreviousMaps.Count > 0;
end;

procedure TNewCityDialog.OnNextMapClicked(Sender: TObject);
var
  M: TMicropolis;
begin
  if NextMaps.Count = 0 then
  begin
    M := TMicropolis.Create;
    TMapGenerator.Create(M).GenerateNewCity;
    NextMaps.Push(M);
  end;

  PreviousMaps.Push(Engine);
  Engine := NextMaps.Pop;
  MapPane.Engine := Engine;
  PreviousMapBtn.Enabled := True;
end;

procedure TNewCityDialog.OnLoadCityClicked(Sender: TObject);
var
  OpenDialog: TOpenDialog;
  FileName: string;
  NewEngine: TMicropolis;
begin
  OpenDialog := TOpenDialog.Create(nil);
  try
    // Configure file dialog
    OpenDialog.Title := 'Load City';
    OpenDialog.Filter := Format('%s (*.%s)|*.%s', [
      GetGuiString('cty_file'),
      EXTENSION,
      EXTENSION
    ]);
    OpenDialog.FilterIndex := 1;
    OpenDialog.DefaultExt := EXTENSION;

    // Show the dialog
    if OpenDialog.Execute then
    begin
      FileName := OpenDialog.FileName;
      NewEngine := TMicropolis.Create;
      try
        Engine.Load(FileName);
        StartPlaying(NewEngine, FileName);
      except
        NewEngine.Free;
        raise;
      end;
    end;
  except
    on E: Exception do
    begin
      // Log error
      //logError(E.Message); // Your custom logging method
    end;
  end;
end;

procedure TNewCityDialog.OnPlayClicked(Sender: TObject);
begin
  Engine.GameLevel := GetSelectedGameLevel;
  Engine.setFunds(TGameLevel.GetStartingFunds(Engine.GameLevel));
  StartPlaying(Engine, '');
end;

procedure TNewCityDialog.OnCancelClicked(Sender: TObject);
begin
  Close;
end;

procedure TNewCityDialog.OnQuitClicked(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TNewCityDialog.SetGameLevel(Level: Integer);
var
  Key: Integer;
begin
  for Key in LevelButtons.Keys do
    LevelButtons[Key].IsChecked := (Key = Level);
end;

function TNewCityDialog.GetSelectedGameLevel: Integer;
var
  Key: Integer;
begin
  for Key in LevelButtons.Keys do
  begin
    if LevelButtons[Key].IsChecked then
      Exit(Key);
  end;
  Result := GameLevel.MIN_LEVEL;
end;

procedure TNewCityDialog.StartPlaying(NewEngine: TMicropolis; const FileName: string);
var
  MainWin: TMainWindow1;
begin
  MainWin := TMainWindow1(Owner);
  MainWin.SetEngine(NewEngine);
  MainWin.CurrentFile := FileName;
  MainWin.MakeClean;
  Close;
end;

end.