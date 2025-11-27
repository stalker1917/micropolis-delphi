unit MainWindow;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  MicropolisEngine, MicropolisDrawingArea, FMX.ScrollBox, FMX.StdCtrls, FMX.Layouts;

type
   TMicropolisTool = (BULLDOZER, WIRE, PARK, ROADS, RAIL, RESIDENTIAL, COMMERCIAL, INDUSTRIAL,
                     FIRE, QUERY, POLICE, POWERPLANT, NUCLEAR, STADIUM, SEAPORT, AIRPORT);
  IMicropolisListener = interface
    // Add Micropolis.Listener interface methods here
  end;

  IEarthquakeListener = interface
    // Add EarthquakeListener interface methods here
  end;

  TMainWindow = class(TForm, IMicropolisListener, IEarthquakeListener)
  private
    FEngine: TMicropolis;
    FDrawingArea: TMicropolisDrawingArea;
    FDrawingAreaScroll: TScrollBox;
    FDemandInd: TObject; // Replace with actual TDemandIndicator type
    FMessagesPane: TObject; // Replace with actual TMessagesPane type
    FMapLegendLbl: TLabel;
    FMapView: TObject; // Replace with actual TOverlayMapView type
    FNotificationPane: TObject; // Replace with actual TNotificationPane type
    FEvaluationPane: TObject; // Replace with actual TEvaluationPane type
    FGraphsPane: TObject; // Replace with actual TGraphsPane type
    // Add additional private fields as needed
  public
    constructor Create(AOwner: TComponent); override;

    // Interface and event handler declarations go here
    procedure HandleEarthquake; // Placeholder
    procedure OnMicropolisEvent; // Placeholder
  end;

implementation

constructor TMainWindow.Create(AOwner: TComponent);
var
  EvalGraphsBox: TVBox;
begin
  inherited Create(AOwner);

  FEngine := TMicropolis.Create;
  Self.Caption := 'Micropolis'; // Set Form Title

  // Initialize Drawing Area
  FDrawingArea := TMicropolisDrawingArea.Create(Self);
  FDrawingArea.Align := TAlignLayout.None; // We'll wrap it in a scrollbox

  FDrawingAreaScroll := TScrollBox.Create(Self);
  FDrawingAreaScroll.Parent := Self;
  FDrawingAreaScroll.Align := TAlignLayout.Client;
  FDrawingAreaScroll.AddObject(FDrawingArea);

  // Initialize Toolbar
  // Replace with actual toolbar creation function
  var Toolbar := TToolBar.Create(Self);
  Toolbar.Align := TAlignLayout.Left;
  Self.AddObject(Toolbar);

  // Evaluation and Graphs panel (VBox equivalent)
  EvalGraphsBox := TVBox.Create(Self);
  EvalGraphsBox.Align := TAlignLayout.Bottom;
  Self.AddObject(EvalGraphsBox);

  FGraphsPane := TGraphsPane.Create(Self);
  FGraphsPane.Visible := False;
  EvalGraphsBox.AddObject(FGraphsPane);

  FEvaluationPane := TEvaluationPane.Create(Self);
  FEvaluationPane.Visible := False;
  EvalGraphsBox.AddObject(FEvaluationPane);

  // Left Pane with DemandIndicator, MapView and Notification/Message Panels
  var LeftPane := TLayout.Create(Self);
  LeftPane.Align := TAlignLayout.Left;
  Self.AddObject(LeftPane);

  FDemandInd := TDemandIndicator.Create(Self);
  TDemandInd(FDemandInd).Align := TAlignLayout.Top;
  LeftPane.AddObject(TFmxObject(FDemandInd));

  // Date/Funds Panel
  var FundsPanel := MakeDateFunds;
  FundsPanel.Align := TAlignLayout.Top;
  LeftPane.AddObject(FundsPanel);

  // Map View container with menu
  var MapViewContainer := TPanel.Create(Self);
  MapViewContainer.Align := TAlignLayout.Top;
  MapViewContainer.Height := 200;
  MapViewContainer.Stroke.Kind := TBrushKind.Solid;
  MapViewContainer.Stroke.Color := TAlphaColors.Black;
  LeftPane.AddObject(MapViewContainer);

  FMapLegendLbl := TLabel.Create(Self);
  FMapLegendLbl.Align := TAlignLayout.Top;
  MapViewContainer.AddObject(FMapLegendLbl);

  FMapView := TOverlayMapView.Create(Self);
  TOverlayMapView(FMapView).ConnectView(FDrawingArea, FDrawingAreaScroll);
  TOverlayMapView(FMapView).Align := TAlignLayout.Client;
  MapViewContainer.AddObject(TFmxObject(FMapView));

  SetMapState(msAll); // equivalent to MapState.ALL

  // Messages pane
  FMessagesPane := TMessagesPane.Create(Self);
  TMessagesPane(FMessagesPane).Align := TAlignLayout.Client;
  LeftPane.AddObject(TFmxObject(FMessagesPane));

  // Notification pane
  FNotificationPane := TNotificationPane.Create(Self);
  TNotificationPane(FNotificationPane).Align := TAlignLayout.Bottom;
  LeftPane.AddObject(TFmxObject(FNotificationPane));

  // Preferences, sounds
  DoSounds := True; // Load from ini or registry later if needed

  // Register listeners
  TOverlayMapView(FMapView).SetEngine(FEngine);
  FEngine.AddListener(Self);
  FEngine.AddEarthquakeListener(Self);

  ReloadFunds;
  ReloadOptions;
  StartTimer;
  MakeClean;
end;

procedure TMainWindow.SetEngine(NewEngine: TMicropolis);
var
  TimerEnabled: Boolean;
begin
  if Assigned(FEngine) then
  begin
    FEngine.RemoveListener(Self);
    FEngine.RemoveEarthquakeListener(Self);
  end;

  FEngine := NewEngine;

  if Assigned(FEngine) then
  begin
    FEngine.AddListener(Self);
    FEngine.AddEarthquakeListener(Self);
  end;

  TimerEnabled := IsTimerActive;
  if TimerEnabled then
    StopTimer;

  StopEarthquake;

  FDrawingArea.SetEngine(FEngine);
  TOverlayMapView(FMapView).SetEngine(FEngine); // must update after drawingArea
  TEvaluationPane(FEvaluationPane).SetEngine(FEngine);
  TDemandIndicator(FDemandInd).SetEngine(FEngine);
  TGraphsPane(FGraphsPane).SetEngine(FEngine);

  ReloadFunds;
  ReloadOptions;

  TNotificationPane(FNotificationPane).Visible := False;

  if TimerEnabled then
    StartTimer;
end;

function TMainWindow.NeedsSaved: Boolean;
begin
  if Dirty1 then // player built something since last save
    Exit(True);

  if not Dirty2 then // no simulator ticks since last save
    Exit(False);

  // simulation ran, but no player actions — check time threshold (30s)
  Result := (TThread.GetTickCount64 - FLastSavedTime) > 30000;
end;

function TMainWindow.MaybeSaveCity: Boolean;
var
  TimerEnabled: Boolean;
  Response: Integer;
begin
  Result := True;

  if NeedsSaved then
  begin
    TimerEnabled := IsTimerActive;
    if TimerEnabled then
      StopTimer;

    try
      Response := MessageDlg('Do you want to save your city?', TMsgDlgType.mtWarning,
        [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo, TMsgDlgBtn.mbCancel], 0);

      if Response = mrCancel then
        Exit(False);

      if Response = mrYes then
      begin
        if not OnSaveCityClicked then
          Exit(False); // save dialog canceled
      end;
    finally
      if TimerEnabled then
        StartTimer;
    end;
  end;
end;

procedure TMainWindow.CloseWindow;
begin
  if MaybeSaveCity then
    Close; // equivalent to dispose()
end;

function TMainWindow.MakeDateFunds: TLayout;
var
  Pane: TLayout;
  DateLblLabel, FundsLblLabel, PopLblLabel: TLabel;
begin
  Pane := TLayout.Create(Self);
  Pane.Align := TAlignLayout.Top;
  Pane.Height := 90; // Adjust height as needed

  // Date Row
  DateLblLabel := TLabel.Create(Pane);
  DateLblLabel.Parent := Pane;
  DateLblLabel.Text := Strings.Values['main.date_label'];
  DateLblLabel.Position.X := 10;
  DateLblLabel.Position.Y := 0;

  DateLbl := TLabel.Create(Pane);
  DateLbl.Parent := Pane;
  DateLbl.Position.X := 200;
  DateLbl.Position.Y := 0;

  // Funds Row
  FundsLblLabel := TLabel.Create(Pane);
  FundsLblLabel.Parent := Pane;
  FundsLblLabel.Text := Strings.Values['main.funds_label'];
  FundsLblLabel.Position.X := 10;
  FundsLblLabel.Position.Y := 30;

  FundsLbl := TLabel.Create(Pane);
  FundsLbl.Parent := Pane;
  FundsLbl.Position.X := 200;
  FundsLbl.Position.Y := 30;

  // Population Row
  PopLblLabel := TLabel.Create(Pane);
  PopLblLabel.Parent := Pane;
  PopLblLabel.Text := Strings.Values['main.population_label'];
  PopLblLabel.Position.X := 10;
  PopLblLabel.Position.Y := 60;

  PopLbl := TLabel.Create(Pane);
  PopLbl.Parent := Pane;
  PopLbl.Position.X := 200;
  PopLbl.Position.Y := 60;

  Result := Pane;
end;

procedure TMainWindow.SetupKeys(MenuItem: TMenuItem; const Prefix: string);
var
  KeyStr: string;
  ShortCutCode: TShortCut;
begin
  if Strings.IndexOfName(Prefix + '.key') > -1 then
  begin
    KeyStr := Strings.Values[Prefix + '.key'];
    MenuItem.Caption := '&' + KeyStr + ' ' + MenuItem.Caption;
  end;

  if Strings.IndexOfName(Prefix + '.shortcut') > -1 then
  begin
    KeyStr := Strings.Values[Prefix + '.shortcut'];
    ShortCutCode := TextToShortCut(KeyStr);
    MenuItem.ShortCut := ShortCutCode;
  end;
end;

procedure TMainWindow.MakeMenu;
var
  MenuBar: TMainMenu;
  GameMenu, OptionsMenu, DisastersMenu, PriorityMenu, WindowsMenu, HelpMenu: TMenuItem;
  MenuItem: TMenuItem;
  i: Integer;
begin
  MenuBar := TMainMenu.Create(Self);
  Self.Menu := MenuBar;

  GameMenu := TMenuItem.Create(MenuBar);
  GameMenu.Text := Strings.Values['menu.game'];
  SetupKeys(GameMenu, 'menu.game');
  MenuBar.Items.Add(GameMenu);

  MenuItem := TMenuItem.Create(GameMenu);
  MenuItem.Text := Strings.Values['menu.game.new'];
  SetupKeys(MenuItem, 'menu.game.new');
  MenuItem.OnClick := OnNewCityClicked;
  GameMenu.Add(MenuItem);

  MenuItem := TMenuItem.Create(GameMenu);
  MenuItem.Text := Strings.Values['menu.game.load'];
  SetupKeys(MenuItem, 'menu.game.load');
  MenuItem.OnClick := OnLoadGameClicked;
  GameMenu.Add(MenuItem);

  MenuItem := TMenuItem.Create(GameMenu);
  MenuItem.Text := Strings.Values['menu.game.save'];
  SetupKeys(MenuItem, 'menu.game.save');
  MenuItem.OnClick := OnSaveCityClicked;
  GameMenu.Add(MenuItem);

  MenuItem := TMenuItem.Create(GameMenu);
  MenuItem.Text := Strings.Values['menu.game.save_as'];
  SetupKeys(MenuItem, 'menu.game.save_as');
  MenuItem.OnClick := OnSaveCityAsClicked;
  GameMenu.Add(MenuItem);

  MenuItem := TMenuItem.Create(GameMenu);
  MenuItem.Text := Strings.Values['menu.game.exit'];
  SetupKeys(MenuItem, 'menu.game.exit');
  MenuItem.OnClick := CloseWindow;
  GameMenu.Add(MenuItem);
  
     // Options Menu
  OptionsMenu := TMenuItem.Create(MainMenu);
  OptionsMenu.Text := strings['menu.options'];
  MainMenu.Items.Add(OptionsMenu);

  // Level Menu
  LevelMenu := TMenuItem.Create(OptionsMenu);
  LevelMenu.Text := strings['menu.difficulty'];
  OptionsMenu.Add(LevelMenu);
  
   SetLength(DifficultyMenuItems, GameLevel.MAX_LEVEL - GameLevel.MIN_LEVEL + 1);
  for i := GameLevel.MIN_LEVEL to GameLevel.MAX_LEVEL do
  begin
    Level := i;
    LevelMenuItem := TMenuItem.Create(LevelMenu);
    LevelMenuItem.Text := strings['menu.difficulty.' + Level.ToString];
    LevelMenuItem.IsChecked := False;
    LevelMenuItem.RadioItem := True;
    LevelMenuItem.OnClick := procedure(Sender: TObject)
    begin
      onDifficultyClicked(Level);
    end;
    LevelMenu.Add(LevelMenuItem);
    DifficultyMenuItems[Level] := LevelMenuItem;
  end;

   // Auto Budget
  MenuItem := TMenuItem.Create(OptionsMenu);
  MenuItem.Text := strings['menu.options.auto_budget'];
  MenuItem.IsChecked := False;
  MenuItem.OnClick := procedure(Sender: TObject)
  begin
    onAutoBudgetClicked();
  end;
  OptionsMenu.Add(MenuItem);
  AutoBudgetMenuItem := MenuItem;

  // Auto Bulldoze
  MenuItem := TMenuItem.Create(OptionsMenu);
  MenuItem.Text := strings['menu.options.auto_bulldoze'];
  MenuItem.IsChecked := False;
  MenuItem.OnClick := procedure(Sender: TObject)
  begin
    onAutoBulldozeClicked();
  end;
  OptionsMenu.Add(MenuItem);
  AutoBulldozeMenuItem := MenuItem;

  // Disasters Option Toggle
  MenuItem := TMenuItem.Create(OptionsMenu);
  MenuItem.Text := strings['menu.options.disasters'];
  MenuItem.IsChecked := False;
  MenuItem.OnClick := procedure(Sender: TObject)
  begin
    onDisastersClicked();
  end;
  OptionsMenu.Add(MenuItem);
  DisastersMenuItem := MenuItem;

  // Sound Option Toggle
  MenuItem := TMenuItem.Create(OptionsMenu);
  MenuItem.Text := strings['menu.options.sound'];
  MenuItem.IsChecked := False;
  MenuItem.OnClick := procedure(Sender: TObject)
  begin
    onSoundClicked();
  end;
  OptionsMenu.Add(MenuItem);
  SoundsMenuItem := MenuItem;

  // Zoom In
  MenuItem := TMenuItem.Create(OptionsMenu);
  MenuItem.Text := strings['menu.options.zoom_in'];
  MenuItem.OnClick := procedure(Sender: TObject)
  begin
    doZoom(1);
  end;
  OptionsMenu.Add(MenuItem);

  // Zoom Out
  MenuItem := TMenuItem.Create(OptionsMenu);
  MenuItem.Text := strings['menu.options.zoom_out'];
  MenuItem.OnClick := procedure(Sender: TObject)
  begin
    doZoom(-1);
  end;
  OptionsMenu.Add(MenuItem);

  // Disasters Menu
  DisastersMenu := TMenuItem.Create(MainMenu);
  DisastersMenu.Text := strings['menu.disasters'];
  MainMenu.Items.Add(DisastersMenu);

  // Disaster Items
  procedure AddDisasterItem(const Key: string; DisasterType: TDisaster);
  begin
    MenuItem := TMenuItem.Create(DisastersMenu);
    MenuItem.Text := strings['menu.disasters.' + Key];
    MenuItem.OnClick := procedure(Sender: TObject)
    begin
      onInvokeDisasterClicked(DisasterType);
    end;
    DisastersMenu.Add(MenuItem);
  end;

  AddDisasterItem('MONSTER', Disaster.MONSTER);
  AddDisasterItem('FIRE', Disaster.FIRE);
  AddDisasterItem('FLOOD', Disaster.FLOOD);
  AddDisasterItem('MELTDOWN', Disaster.MELTDOWN);
  AddDisasterItem('TORNADO', Disaster.TORNADO);
  AddDisasterItem('EARTHQUAKE', Disaster.EARTHQUAKE);

  // Speed Menu
  PriorityMenu := TMenuItem.Create(MainMenu);
  PriorityMenu.Text := strings['menu.speed'];
  MainMenu.Items.Add(PriorityMenu);

 procedure AddSpeedItem(const Key: string; SpeedType: TSpeed);
  begin
    MenuItem := TMenuItem.Create(PriorityMenu);
    MenuItem.Text := strings['menu.speed.' + Key];
    MenuItem.RadioItem := True;
    MenuItem.OnClick := procedure(Sender: TObject)
    begin
      onPriorityClicked(SpeedType);
    end;
    PriorityMenu.Add(MenuItem);
    PriorityMenuItems[SpeedType] := MenuItem;
  end;

  AddSpeedItem('SUPER_FAST', Speed.SUPER_FAST);
  AddSpeedItem('FAST', Speed.FAST);
  AddSpeedItem('NORMAL', Speed.NORMAL);
  AddSpeedItem('SLOW', Speed.SLOW);
  AddSpeedItem('PAUSED', Speed.PAUSED);

  // Windows Menu
  WindowsMenu := TMenuItem.Create(MainMenu);
  WindowsMenu.Text := strings['menu.windows'];
  MainMenu.Items.Add(WindowsMenu);

  // Budget
  MenuItem := TMenuItem.Create(WindowsMenu);
  MenuItem.Text := strings['menu.windows.budget'];
  MenuItem.OnClick := procedure(Sender: TObject)
  begin
    onViewBudgetClicked();
  end;
  WindowsMenu.Add(MenuItem);

  // Evaluation
  MenuItem := TMenuItem.Create(WindowsMenu);
  MenuItem.Text := strings['menu.windows.evaluation'];
  MenuItem.OnClick := procedure(Sender: TObject)
  begin
    onViewEvaluationClicked();
  end;
  WindowsMenu.Add(MenuItem);

  // Graph
  MenuItem := TMenuItem.Create(WindowsMenu);
  MenuItem.Text := strings['menu.windows.graph'];
  MenuItem.OnClick := procedure(Sender: TObject)
  begin
    onViewGraphClicked();
  end;
  WindowsMenu.Add(MenuItem);

  // Help Menu
  HelpMenu := TMenuItem.Create(MainMenu);
  HelpMenu.Text := strings['menu.help'];
  MainMenu.Items.Add(HelpMenu);

  // Launch Translation Tool
  MenuItem := TMenuItem.Create(HelpMenu);
  MenuItem.Text := strings['menu.help.launch-translation-tool'];
  MenuItem.OnClick := procedure(Sender: TObject)
  begin
    onLaunchTranslationToolClicked();
  end;
  HelpMenu.Add(MenuItem);

  // About
  MenuItem := TMenuItem.Create(HelpMenu);
  MenuItem.Text := strings['menu.help.about'];
  MenuItem.OnClick := procedure(Sender: TObject)
  begin
    onAboutClicked();
  end;
  HelpMenu.Add(MenuItem);
end;

function TMainWindow.GetEngine: TMicropolis;
begin
  Result := Engine;
end;

procedure TMainWindow.SetEngine(NewEngine: TMicropolis);
begin
  Engine := NewEngine;
  // additional setup if needed
end;

procedure TMainWindow.OnAutoBudgetClicked(Sender: TObject);
begin
  Dirty1 := True;
  GetEngine.ToggleAutoBudget;
end;

procedure TMainWindow.OnAutoBulldozeClicked(Sender: TObject);
begin
  Dirty1 := True;
  GetEngine.ToggleAutoBulldoze;
end;

procedure TMainWindow.OnDisastersClicked(Sender: TObject);
begin
  Dirty1 := True;
  GetEngine.ToggleDisasters;
end;

procedure TMainWindow.OnSoundClicked(Sender: TObject);
var
  Ini: TIniFile;
begin
  DoSounds := not DoSounds;
  Ini := TIniFile.Create(TPath.Combine(TPath.GetHomePath, 'settings.ini'));
  try
    Ini.WriteBool('Preferences', SOUNDS_PREF, DoSounds);
  finally
    Ini.Free;
  end;
  ReloadOptions;
end;

procedure TMainWindow.MakeClean;
var
  FileName, TitleText: string;
begin
  Dirty1 := False;
  Dirty2 := False;
  LastSavedTime := Now;
  if not CurrentFile.IsEmpty then
  begin
    FileName := TPath.GetFileName(CurrentFile);
    if FileName.EndsWith('.' + EXTENSION) then
      FileName := Copy(FileName, 1, Length(FileName) - Length(EXTENSION) - 1);

    TitleText := Format(strings['main.caption_named_city'], [FileName]);
  end
  else
    TitleText := strings['main.caption_unnamed_city'];

  SetTitle(TitleText);
end;

function TMainWindow.OnSaveCityClicked: Boolean;
begin
  Result := False;
  if CurrentFile.IsEmpty then
  begin
    Result := OnSaveCityAsClicked;
    Exit;
  end;

  try
    GetEngine.SaveToFile(CurrentFile);
    MakeClean;
    Result := True;
  except
    on E: Exception do
    begin
      ShowMessage(E.Message);
    end;
  end;
end;

function TMainWindow.OnSaveCityAsClicked: Boolean;
var
  Dialog: TSaveDialog;
  FileName: string;
  TimerWasActive: Boolean;
begin
  Result := False;
  TimerWasActive := IsTimerActive;
  if TimerWasActive then StopTimer;

  Dialog := TSaveDialog.Create(Self);
  try
    Dialog.Filter := strings['cty_file'] + '|*.' + EXTENSION;
    if Dialog.Execute then
    begin
      FileName := Dialog.FileName;
      if not FileName.EndsWith('.' + EXTENSION) then
        FileName := FileName + '.' + EXTENSION;

      CurrentFile := FileName;
      GetEngine.SaveToFile(CurrentFile);
      MakeClean;
      Result := True;
    end;
  except
    on E: Exception do
      ShowMessage(E.Message);
  end;
  if TimerWasActive then StartTimer;
  Dialog.Free;
end;

procedure TMainWindow.OnLoadGameClicked(Sender: TObject);
var
  Dialog: TOpenDialog;
  FileName: string;
  NewEngine: TMicropolis;
  TimerWasActive: Boolean;
begin
  if not MaybeSaveCity then
    Exit;

  TimerWasActive := IsTimerActive;
  if TimerWasActive then StopTimer;

  Dialog := TOpenDialog.Create(Self);
  try
    Dialog.Filter := strings['cty_file'] + '|*.' + EXTENSION;
    if Dialog.Execute then
    begin
      FileName := Dialog.FileName;
      NewEngine := TMicropolis.Create;
      try
        NewEngine.LoadFromFile(FileName);
        SetEngine(NewEngine);
        CurrentFile := FileName;
        MakeClean;
      except
        on E: Exception do
          ShowMessage(E.Message);
      end;
    end;
  finally
    if TimerWasActive then StartTimer;
    Dialog.Free;
  end;
end;

function TMainWindow.MakeToolBtn(const Tool: TMicropolisTool): TSpeedButton;
var
  Btn: TSpeedButton;
  IconPath, TipText: string;
begin
  Btn := TSpeedButton.Create(Self);
  Btn.Parent := Self; // Or assign later when adding to a container
  Btn.Text := '';  // We only want an icon
  Btn.StyleLookup := 'toolbutton';

  IconPath := IfThen(strings.ContainsKey('tool.' + Tool.ToString + '.icon'),
    strings['tool.' + Tool.ToString + '.icon'],
    '/graphics/tools/' + LowerCase(Tool.ToString) + '.png');

  TipText := IfThen(strings.ContainsKey('tool.' + Tool.ToString + '.tip'),
    strings['tool.' + Tool.ToString + '.tip'],
    Tool.ToString);

  try
    Btn.Bitmap.Bitmap.LoadFromFile(ExpandFileName(IconPath));
  except
    // Handle missing image
  end;

  Btn.Hint := TipText;
  Btn.HitTest := True;
  Btn.Margins.Rect := TRectF.Create(0, 0, 0, 0);
  Btn.StyledSettings := [TStyledSetting.Family, TStyledSetting.FontColor];
  Btn.OnClick := procedure(Sender: TObject)
    begin
      SelectTool(Tool);
    end;

  ToolBtns.Add(Tool, Btn);
  Result := Btn;
end;

function TMainWindow.MakeToolbar: TVertScrollBox;
var
  Toolbar: TVertScrollBox;
  Row: TLayout;
begin
  ToolBtns := TDictionary<TMicropolisTool, TSpeedButton>.Create;

  Toolbar := TVertScrollBox.Create(Self);
  Toolbar.Align := TAlignLayout.Left;
  Toolbar.Width := 100;
  Toolbar.Margins.Top := 10;

  // Tool Label
  CurrentToolLbl := TLabel.Create(Self);
  CurrentToolLbl.Parent := Toolbar;
  CurrentToolLbl.Text := ' ';
  CurrentToolLbl.Margins.Bottom := 5;

  // Cost Label
  CurrentToolCostLbl := TLabel.Create(Self);
  CurrentToolCostLbl.Parent := Toolbar;
  CurrentToolCostLbl.Text := ' ';
  CurrentToolCostLbl.Margins.Bottom := 10;

  // Grouped tool buttons
  var Tools: array[0..5] of array of TMicropolisTool = (
    [BULLDOZER, WIRE, PARK],
    [ROADS, RAIL],
    [RESIDENTIAL, COMMERCIAL, INDUSTRIAL],
    [FIRE, QUERY, POLICE],
    [POWERPLANT, NUCLEAR],
    [STADIUM, SEAPORT]
  );

  for var RowTools in Tools do
  begin
    Row := TLayout.Create(Self);
    Row.Parent := Toolbar;
    Row.Align := TAlignLayout.Top;
    Row.Height := 40;
    Row.Padding.Bottom := 5;

    for var Tool in RowTools do
    begin
      var Btn := MakeToolBtn(Tool);
      Btn.Parent := Row;
      Btn.Align := TAlignLayout.Left;
      Btn.Width := 36;
      Btn.Height := 36;
    end;
  end;

  // Final tool (AIRPORT) in a row
  Row := TLayout.Create(Self);
  Row.Parent := Toolbar;
  Row.Align := TAlignLayout.Top;
  var Btn := MakeToolBtn(AIRPORT);
  Btn.Parent := Row;
  Btn.Align := TAlignLayout.Left;
  Btn.Width := 36;
  Btn.Height := 36;

  Result := Toolbar;
end;

procedure TMainWindow.SelectTool(const NewTool: TMicropolisTool);
begin
  if CurrentTool = NewTool then
    Exit;

  // Unselect previous
  if ToolBtns.ContainsKey(CurrentTool) then
    ToolBtns[CurrentTool].IsPressed := False;

  // Select new
  CurrentTool := NewTool;
  if ToolBtns.ContainsKey(CurrentTool) then
    ToolBtns[CurrentTool].IsPressed := True;

  // Update UI
  if strings.ContainsKey('tool.' + CurrentTool.ToString + '.name') then
    CurrentToolLbl.Text := strings['tool.' + CurrentTool.ToString + '.name']
  else
    CurrentToolLbl.Text := CurrentTool.ToString;

  var Cost := GetToolCost(CurrentTool);  // You’ll need to define this method
  if Cost <> 0 then
    CurrentToolCostLbl.Text := FormatFunds(Cost)
  else
    CurrentToolCostLbl.Text := ' ';
end;

procedure TMainWindow.OnNewCityClicked(Sender: TObject);
begin
  if MaybeSaveCity then
    DoNewCity(False);
end;

procedure TMainWindow.DoNewCity(FirstTime: Boolean);
begin
  var TimerEnabled := IsTimerActive;
  if TimerEnabled then StopTimer;

  var NewCityDlg := TNewCityDialog.Create(Self);
  try
    NewCityDlg.ShowModal;
  finally
    NewCityDlg.Free;
  end;

  if TimerEnabled then StartTimer;
end;

procedure TMainWindow.DoQueryTool(XPos, YPos: Integer);
var
  Z: TZoneStatus;
begin
  if not Engine.TestBounds(XPos, YPos) then Exit;
  Z := Engine.QueryZoneStatus(XPos, YPos);
  NotificationPane.ShowZoneStatus(Engine, XPos, YPos, Z);
end;

procedure TMainWindow.DoZoom(Dir: Integer; MousePt: TPoint);
var
  OldZoom, NewZoom: Integer;
  F: Double;
  Pos: TPointF;
  NewX, NewY: Integer;
begin
  OldZoom := DrawingArea.TileSize;
  if Dir < 0 then
    NewZoom := OldZoom div 2
  else
    NewZoom := OldZoom * 2;

  if NewZoom < 8 then NewZoom := 8;
  if NewZoom > 32 then NewZoom := 32;

  if OldZoom <> NewZoom then
  begin
    F := NewZoom / OldZoom;
    Pos := DrawingAreaScroll.ViewportPosition;
    NewX := Round(MousePt.X * F - (MousePt.X - Round(Pos.X)));
    NewY := Round(MousePt.Y * F - (MousePt.Y - Round(Pos.Y)));

    DrawingArea.SelectTileSize(NewZoom);
    DrawingAreaScroll.Realign; // or Invalidate, depending on your FMX version
    DrawingAreaScroll.ViewportPosition := PointF(NewX, NewY);
  end;
end;

procedure TMainWindow.DoZoom(Dir: Integer);
var
  Rect: TRectF;
  MousePt: TPoint;
begin
  Rect := DrawingAreaScroll.ViewportRect;
  MousePt.X := Round(Rect.Left + Rect.Width / 2);
  MousePt.Y := Round(Rect.Top + Rect.Height / 2);
  DoZoom(Dir, MousePt);
end;

procedure TMainWindow.OnMouseWheelMoved(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
var
  MousePos: TPoint;
begin
  MousePos.X := Mouse.CursorPos.X; // Or translate to control coords
  MousePos.Y := Mouse.CursorPos.Y;
  if WheelDelta > 0 then
    DoZoom(1, MousePos)
  else
    DoZoom(-1, MousePos);
  Handled := True;
end;

// ToolStroke and last tool positions
var
  ToolStroke: TToolStroke;
  LastX, LastY: Integer;

procedure TMainWindow.OnToolDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  Loc: TCityLocation;
  IX, IY: Integer;
begin
  if Button = TMouseButton.mbRight then
  begin
    Loc := DrawingArea.GetCityLocation(Round(X), Round(Y));
    DoQueryTool(Loc.X, Loc.Y);
    Exit;
  end;

  if Button <> TMouseButton.mbLeft then Exit;
  if CurrentTool = nil then Exit;

  Loc := DrawingArea.GetCityLocation(Round(X), Round(Y));
  IX := Loc.X;
  IY := Loc.Y;

  if CurrentTool = TMicropolisTool.Query then
  begin
    DoQueryTool(IX, IY);
    ToolStroke := nil;
  end
  else
  begin
    ToolStroke := CurrentTool.BeginStroke(Engine, IX, IY);
    PreviewTool;
  end;

  LastX := IX;
  LastY := IY;
end;

procedure TMainWindow.OnEscapePressed;
begin
  if Assigned(ToolStroke) then
  begin
    ToolStroke := nil;
    DrawingArea.SetToolPreview(nil);
    DrawingArea.SetToolCursor(nil);
  end
  else
    NotificationPane.Visible := False;
end;

procedure TMainWindow.OnToolUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  Loc: TCityLocation;
  TR: TToolResult;
begin
  if Assigned(ToolStroke) then
  begin
    DrawingArea.SetToolPreview(nil);
    Loc := ToolStroke.Location;
    TR := ToolStroke.Apply;
    ShowToolResult(Loc, TR);
    ToolStroke := nil;
  end;

  OnToolHover(Sender, Button, Shift, X, Y);

  if AutoBudgetPending then
  begin
    AutoBudgetPending := False;
    ShowBudgetWindow(True);
  end;
end;

procedure TMainWindow.PreviewTool;
begin
  Assert(Assigned(ToolStroke));
  Assert(CurrentTool <> nil);

  DrawingArea.SetToolCursor(
    ToolStroke.Bounds,
    CurrentTool);

  DrawingArea.SetToolPreview(
    ToolStroke.Preview);
end;

procedure TMainWindow.OnToolDrag(Sender: TObject; Shift: TShiftState; X, Y: Single);
var
  Loc: TCityLocation;
  IX, IY: Integer;
begin
  if CurrentTool = nil then Exit;
  if not (ssLeft in Shift) then Exit;

  Loc := DrawingArea.GetCityLocation(Round(X), Round(Y));
  IX := Loc.X;
  IY := Loc.Y;
  if (IX = LastX) and (IY = LastY) then Exit;

  if Assigned(ToolStroke) then
  begin
    ToolStroke.DragTo(IX, IY);
    PreviewTool;
  end
  else if CurrentTool = TMicropolisTool.Query then
  begin
    DoQueryTool(IX, IY);
  end;

  LastX := IX;
  LastY := IY;
end;

procedure TMainWindow.OnToolHover(Sender: TObject; Shift: TShiftState; X, Y: Single);
var
  Loc: TCityLocation;
  CX, CY, W, H: Integer;
begin
  if (CurrentTool = nil) or (CurrentTool = TMicropolisTool.Query) then
  begin
    DrawingArea.SetToolCursor(nil);
    Exit;
  end;

  Loc := DrawingArea.GetCityLocation(Round(X), Round(Y));
  CX := Loc.X;
  CY := Loc.Y;
  W := CurrentTool.Width;
  H := CurrentTool.Height;

  if W >= 3 then Dec(CX);
  if H >= 3 then Dec(CY);

  DrawingArea.SetToolCursor(TCityRect.Create(CX, CY, W, H), CurrentTool);
end;

procedure TMainWindow.OnToolExited(Sender: TObject);
begin
  DrawingArea.SetToolCursor(nil);
end;

procedure TMainWindow.ShowToolResult(const Loc: TCityLocation; ResultCode: TToolResult);
begin
  case ResultCode of
    TR_SUCCESS:
      begin
        if CurrentTool = TMicropolisTool.Bulldozer then
          CitySound(Sound_BULLDOZE, Loc)
        else
          CitySound(Sound_BUILD, Loc);
        Dirty1 := True;
      end;

    TR_NONE: ; // do nothing

    TR_UH_OH:
      begin
        MessagesPane.AppendCityMessage(MicropolisMessage_BULLDOZE_FIRST);
        CitySound(Sound_UHUH, Loc);
      end;

    TR_INSUFFICIENT_FUNDS:
      begin
        MessagesPane.AppendCityMessage(MicropolisMessage_INSUFFICIENT_FUNDS);
        CitySound(Sound_SORRY, Loc);
      end;

  else
    Assert(False, 'Unexpected ToolResult');
  end;
end;

function TMainWindow.FormatFunds(Funds: Integer): string;
begin
  Result := Format(strings.GetString('funds'), [Funds]);
end;

function TMainWindow.FormatGameDate(CityTime: Integer): string;
var
  Year, Month, Day: Integer;
  Date: TDateTime;
begin
  Year := 1900 + CityTime div 48;
  Month := (CityTime mod 48) div 4 + 1;  // Delphi months are 1-based
  Day := (CityTime mod 4) * 7 + 1;

  Date := EncodeDate(Year, Month, Day);
  Result := Format(strings.GetString('citytime'), [Date]);
end;

procedure TMainWindow.UpdateDateLabel;
var
  NF: TFormatSettings;
begin
  DateLbl.Text := FormatGameDate(Engine.CityTime);

  NF := TFormatSettings.Create;
  NF.ThousandSeparator := ',';
  PopLbl.Text := FormatFloat('#,##0', Engine.GetCityPopulation, NF);
end;

procedure TMainWindow.StartTimer;
var
  Count, Interval: Integer;
  Engine: TMicropolis;
begin
  Engine := GetEngine;
  Count := Engine.SimSpeed.SimStepsPerUpdate;

  Assert(not IsTimerActive);

  if Engine.SimSpeed = Speed_PAUSED then Exit;

  if Assigned(CurrentEarthquake) then
  begin
    Interval := 3000 div MicropolisDrawingArea.SHAKE_STEPS;
    ShakeTimer := TTimer.Create(Self);
    ShakeTimer.Interval := Interval;
    ShakeTimer.OnTimer := procedure(Sender: TObject)
      begin
        CurrentEarthquake.OneStep;
        if CurrentEarthquake.Count = 0 then
        begin
          StopTimer;
          CurrentEarthquake := nil;
          StartTimer;
        end;
      end;
    ShakeTimer.Enabled := True;
    Exit;
  end;

  SimTimer := TTimer.Create(Self);
  SimTimer.Interval := Engine.SimSpeed.AnimationDelay;
  SimTimer.OnTimer := procedure(Sender: TObject)
    var i: Integer;
    begin
      try
        for i := 1 to Count do
        begin
          Engine.Animate;
          if (not Engine.AutoBudget) and Engine.IsBudgetTime then
          begin
            ShowAutoBudget;
            Exit;
          end;
        end;
        UpdateDateLabel;
        Dirty2 := True;
      except
        on E: Exception do
          ShowErrorMessage(E);
      end;
    end;
  SimTimer.Enabled := True;
end;


procedure TEarthquakeStepper.OneStep;
begin
  FCount := (FCount + 1) mod MicropolisDrawingArea.SHAKE_STEPS;
  DrawingArea.Shake(FCount);
end;

procedure TMainWindow.StartSimTimer;
var
  i, Count: Integer;
begin
  Count := Engine.SimSpeed.SimStepsPerUpdate;

  Assert(SimTimer = nil);

  SimTimer := TTimer.Create(Self);
  SimTimer.Interval := Engine.SimSpeed.AnimationDelay;
  SimTimer.OnTimer := procedure(Sender: TObject)
  var
    i: Integer;
  begin
    try
      for i := 0 to Count - 1 do
      begin
        Engine.Animate;
        if (not Engine.AutoBudget) and Engine.IsBudgetTime then
        begin
          ShowAutoBudget;
          Exit;
        end;
      end;
      UpdateDateLabel;
      Dirty2 := True;
    except
      on E: Exception do
        ShowErrorMessage(E);
    end;
  end;
  SimTimer.Enabled := True;
end;

procedure TMainWindow.ShowErrorMessage(E: Exception);
var
  Msg, Details: string;
  DetailsForm: TForm;
  Memo: TMemo;
  BtnShowStackTrace, BtnClose, BtnShutdown: Integer;
begin
  Msg := E.Message;
  Details := E.ClassName + ': ' + Msg + sLineBreak + E.StackTrace;

  DetailsForm := TForm.Create(nil);
  try
    DetailsForm.Width := 480;
    DetailsForm.Height := 240;
    DetailsForm.Caption := Strings.GetString('main.error_unexpected');

    Memo := TMemo.Create(DetailsForm);
    Memo.Parent := DetailsForm;
    Memo.Align := TAlignLayout.Client;
    Memo.ReadOnly := True;
    Memo.Text := Details;

    BtnShowStackTrace := 0;
    BtnClose := 1;
    BtnShutdown := 2;

    // Simulate a message dialog with options; replace with your dialog implementation
    case MessageDlg(Msg, TMsgDlgType.mtError,
      [mbYes, mbNo, mbCancel], 0) of
      mrYes: // Show stack trace
        begin
          DetailsForm.ShowModal;
        end;
      mrNo: // Close dialog, do nothing
        Exit;
      mrCancel: // Shutdown
        begin
          if MessageDlg(Strings.GetString('error.shutdown_query'),
            TMsgDlgType.mtWarning, [mbOk, mbCancel], 0) = mrOk then
            Application.Terminate;
        end;
    end;
  finally
    DetailsForm.Free;
  end;
end;

procedure TMainWindow.EarthquakeStarted;
begin
  if IsTimerActive then
    StopTimer;

  CurrentEarthquake := TEarthquakeStepper.Create;
  CurrentEarthquake.OneStep;
  StartTimer;
end;

procedure TMainWindow.StopEarthquake;
begin
  DrawingArea.Shake(0);
  FreeAndNil(CurrentEarthquake);
end;

procedure TMainWindow.StopTimer;
begin
  Assert(IsTimerActive);

  if SimTimer <> nil then
  begin
    SimTimer.Enabled := False;
    FreeAndNil(SimTimer);
  end;
  if ShakeTimer <> nil then
  begin
    ShakeTimer.Enabled := False;
    FreeAndNil(ShakeTimer);
  end;
end;

function TMainWindow.IsTimerActive: Boolean;
begin
  Result := (SimTimer <> nil) or (ShakeTimer <> nil);
end;

procedure TMainWindow.OnWindowClosed(Sender: TObject);
begin
  if IsTimerActive then
    StopTimer;
end;

procedure TMainWindow.OnDifficultyClicked(NewDifficulty: Integer);
begin
  Engine.GameLevel := NewDifficulty;
end;

procedure TMainWindow.OnPriorityClicked(NewSpeed: TSpeed);
begin
  if IsTimerActive then
    StopTimer;

  Engine.Speed := NewSpeed;
  StartTimer;
end;

procedure TMainWindow.OnInvokeDisasterClicked(Disaster: TDisaster);
begin
  Dirty1 := True;
  case Disaster of
    fdFire: Engine.MakeFire;
    fdFlood: Engine.MakeFlood;
    fdMonster: Engine.MakeMonster;
    fdMeltdown:
      if not Engine.MakeMeltdown then
        MessagesPane.AppendCityMessage(MicropolisMessageNoNuclearPlants);
    fdTornado: Engine.MakeTornado;
    fdEarthquake: Engine.MakeEarthquake;
  else
    Assert(False, 'Unknown disaster');
  end;
end;

procedure TMainWindow.ReloadFunds;
begin
  FundsLbl.Text := FormatFunds(Engine.Budget.TotalFunds);
end;

// Implements Micropolis.Listener
procedure TMainWindow.CityMessage(const M: TMicropolisMessage; const P: TCityLocation);
begin
  MessagesPane.AppendCityMessage(M);

  if M.UseNotificationPane and (P <> nil) then
    NotificationPane.ShowMessage(Engine, M, P.X, P.Y);
end;

// Implements Micropolis.Listener
procedure TMainWindow.FundsChanged;
begin
  ReloadFunds;
end;

// Implements Micropolis.Listener
procedure TMainWindow.OptionsChanged;
begin
  ReloadOptions;
end;

procedure TMainWindow.ReloadOptions;
var
  spd: TSpeed;
  lvl: Integer;
begin
  AutoBudgetMenuItem.IsChecked := Engine.AutoBudget;
  AutoBulldozeMenuItem.IsChecked := Engine.AutoBulldoze;
  DisastersMenuItem.IsChecked := not Engine.NoDisasters;
  SoundsMenuItem.IsChecked := DoSounds;

  for spd in PriorityMenuItems.Keys do
    PriorityMenuItems[spd].IsChecked := (Engine.SimSpeed = spd);

  for lvl := GameLevel.MinLevel to GameLevel.MaxLevel do
    DifficultyMenuItems[lvl].IsChecked := (Engine.GameLevel = lvl);
end;

procedure TMainWindow.CitySound(Sound: TSound; Loc: TCityLocation);
var
  AudioFile: string;
  IsOnScreen: Boolean;
  Clip: TMediaPlayer;
  TileRect: TRectF;
  ViewRect: TRectF;
begin
  if not DoSounds then Exit;

  AudioFile := Sound.GetAudioFile;
  if AudioFile = '' then Exit;

  TileRect := DrawingArea.GetTileBounds(Loc.X, Loc.Y);
  ViewRect := DrawingAreaScroll.Viewport.ViewRect;
  IsOnScreen := ViewRect.Contains(TileRect.TopLeft) and ViewRect.Contains(TileRect.BottomRight);

  if (Sound = Sound.HonkHonkLow) and (not IsOnScreen) then Exit;

  try
    Clip := TMediaPlayer.Create(Self);
    try
      Clip.FileName := AudioFile;
      Clip.Play;
    except
      on E: Exception do
        OutputDebugString(PChar('Audio play error: ' + E.Message));
    end;
  finally
    Clip.Free;
  end;
end;

procedure TMainWindow.CensusChanged;
begin
  // empty per Java code
end;

procedure TMainWindow.DemandChanged;
begin
  // empty per Java code
end;

procedure TMainWindow.EvaluationChanged;
begin
  // empty per Java code
end;

procedure TMainWindow.OnViewBudgetClicked;
begin
  Dirty1 := True;
  ShowBudgetWindow(False);
end;

procedure TMainWindow.OnViewEvaluationClicked;
begin
  EvaluationPane.Visible := True;
end;

procedure TMainWindow.OnViewGraphClicked;
begin
  GraphsPane.Visible := True;
end;

procedure TMainWindow.ShowAutoBudget;
begin
  if ToolStroke = nil then
    ShowBudgetWindow(True)
  else
    AutoBudgetPending := True;
end;

procedure TMainWindow.ShowBudgetWindow(IsEndOfYear: Boolean);
var
  TimerWasActive: Boolean;
  Dlg: TBudgetDialog;
begin
  TimerWasActive := IsTimerActive;
  if TimerWasActive then
    StopTimer;

  Dlg := TBudgetDialog.Create(Self, Engine);
  try
    Dlg.ShowModal;
  finally
    Dlg.Free;
  end;

  if TimerWasActive then
    StartTimer;
end;

function TMainWindow.MakeMapStateMenuItem(const StringPrefix: string; State: TMapState): TMenuItem;
var
  Caption: string;
  MenuItem: TRadioButtonMenuItem;
begin
  Caption := Strings.GetString(StringPrefix);
  MenuItem := TRadioButtonMenuItem.Create(Self);
  MenuItem.Text := Caption;
  SetupKeys(MenuItem, StringPrefix);
  MenuItem.OnClick := procedure(Sender: TObject)
    begin
      SetMapState(State);
    end;
  MapStateMenuItems.Add(State, MenuItem);
  Result := MenuItem;
end;

procedure TMainWindow.SetMapState(State: TMapState);
begin
  MapStateMenuItems[MapView.MapState].IsChecked := False;
  MapStateMenuItems[State].IsChecked := True;
  MapView.MapState := State;
  SetMapLegend(State);
end;

procedure TMainWindow.SetMapLegend(State: TMapState);
var
  Key, IconName: string;
  IconUrl: string;
begin
  Key := 'legend_image.' + GetEnumName(TypeInfo(TMapState), Ord(State));
  if Strings.ContainsKey(Key) then
  begin
    IconName := Strings.GetString(Key);
    IconUrl := TPath.Combine(GetResourcePath, IconName);
    if FileExists(IconUrl) then
      MapLegendImg.Bitmap.LoadFromFile(IconUrl)
    else
      MapLegendImg.Bitmap := nil;
  end
  else
    MapLegendImg.Bitmap := nil;
end;

procedure TMainWindow.OnLaunchTranslationToolClicked;
begin
  if MaybeSaveCity then
  begin
    Close;
    with TTranslationTool.Create(nil) do
      Show;
  end;
end;

procedure TMainWindow.OnAboutClicked;
var
  Version, VersionStr: string;
  AppNameLbl, AppDetailsLbl: TLabel;
  MsgForm: TForm;
  Layout: TVertScrollBox;
begin
  Version := GetPackageVersion; // You’ll need a helper function to get package version
  VersionStr := Format(Strings.GetString('main.version_string'), [Version]);
  VersionStr := StringReplace(VersionStr, '%java.version%', GetJavaVersion, [rfReplaceAll]);
  VersionStr := StringReplace(VersionStr, '%java.vendor%', GetJavaVendor, [rfReplaceAll]);

  MsgForm := TForm.Create(nil);
  try
    MsgForm.Caption := Strings.GetString('main.about_caption');
    MsgForm.Width := 400;
    MsgForm.Height := 200;
    MsgForm.Position := TFormPosition.ScreenCenter;

    Layout := TVertScrollBox.Create(MsgForm);
    Layout.Parent := MsgForm;
    Layout.Align := TAlignLayout.Client;

    AppNameLbl := TLabel.Create(Layout);
    AppNameLbl.Parent := Layout;
    AppNameLbl.Text := VersionStr;
    AppNameLbl.TextSettings.HorzAlign := TTextAlign.Center;
    AppNameLbl.Margins.Top := 12;

    AppDetailsLbl := TLabel.Create(Layout);
    AppDetailsLbl.Parent := Layout;
    AppDetailsLbl.Text := Strings.GetString('main.about_text');
    AppDetailsLbl.TextSettings.HorzAlign := TTextAlign.Center;
    AppDetailsLbl.Margins.Top := 8;

    MsgForm.ShowModal;
  finally
    MsgForm.Free;
  end;
end;


end.