unit MainWindow;

interface

uses
 // System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
//  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs;
 System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.ScrollBox, FMX.StdCtrls, FMX.Layouts,
  MicropolisUnit,MicropolisDrawingArea,EvaluationPane,MessagesPane,
  NotificationPane,GraphsPane,DemandIndicator,OverlayMapView,
  MicropolisMessage,Sound,MapState,FMX.Menus,GameLevel,
  Disaster,Resources,Speed,IniFiles,System.IOUtils,ToolStroke,
  ToolResult,System.Generics.Collections,CityRect,NewCityDialog,
  ZoneStatus,CityLocation,FMX.Memo,FMX.Media,FMX.Objects,TranslationTool,
  BudgetDialog,SpriteCity,EarthquakeListener,FMX.ImgList,FMX.MultiResBitmap;

    const
  MENU_ZOOM_IN = 11;
  MENU_ZOOM_OUT = 12;
  MENU_BUDGET = 13;
  MENU_EVALUATION = 14;
  MENU_GRAPH = 15;
  MENU_LAUNCH_TRANSLATION = 16;
  MENU_ABOUT = 17;


type

  { TMicropolisTool = (BULLDOZER, WIRE, PARK, ROADS, RAIL, RESIDENTIAL, COMMERCIAL, INDUSTRIAL,
                     FIRE, QUERY, POLICE, POWERPLANT, NUCLEAR, STADIUM, SEAPORT, AIRPORT); }
  //IMicropolisListener = interface
    // Add Micropolis.Listener interface methods here
 // end;

  //IEarthquakeListener = interface
    // Add EarthquakeListener interface methods here
  //end;





  TMainWindow1 = class(TForm,IListener,IEarthQuakeListener)
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
  type
   TEarthquakeStepper = class
      private
        FCount: Integer;
        FOwner: TMainWindow1; // Reference to main form
      public
        constructor Create(AOwner: TMainWindow1);
        procedure OneStep;
      end;
   procedure OnMouseWheelMoved(Sender: TObject; Shift: TShiftState; WheelDelta: Integer;  var Handled: Boolean);
   private

    FDrawingArea: TMicropolisDrawingArea;
    FDrawingAreaScroll: TScrollBox;
    FDemandInd: TObject; // Replace with actual TDemandIndicator type
    FMessagesPane: TMessagesPane; // Replace with actual TMessagesPane type
    FMapLegendLbl: TLabel;
    FMapLegendImage : TImage;
    FMapView: TOverlayMapView; // Replace with actual TOverlayMapView type
    FNotificationPane: TNotificationPane; // Replace with actual TNotificationPane type
    FEvaluationPane: TEvaluationPane; // Replace with actual TEvaluationPane type
    FGraphsPane: TGraphsPane; // Replace with actual TGraphsPane type
    MapStateMenuItems: TDictionary<TMapState, TMenuItem>;
    // Add additional private fields as needed
    DoSounds,Dirty1,Dirty2 : Boolean;
    FLastSavedTime : Int64;
    Menu :TMainMenu;
    DateLbl,FundsLbl, PopLbl :TLabel;
    AutoBudgetPending : Boolean;
    FEngine: TMicropolis;
    DifficultyMenuItems,PriorityMenuItems : Array of TMenuItem;
    CurrentToolLbl,CurrentToolCostLbl : TLabel;
    ToolBtns : TDictionary<TMicropolisTool, TSpeedButton>;
    ToolImages : TDictionary<TMicropolisTool, TImage>;
    CurrentTool : TMicropolisTool;
    //DrawingArea : TMicropolisDrawingArea;
    ShakeTimer,SimTimer : TTimer;
    AutoBudgetMenuItem,AutoBulldozeMenuItem : TMenuItem;
    DisastersMenuItem, SoundsMenuItem : TMenuItem;
    CurrentEarthquake: TEarthquakeStepper;
    procedure ReloadFunds;

    procedure FundsChanged;
    procedure OptionsChanged;
    procedure ReloadOptions;
    procedure CitySound(Sound: TSound; Loc: TCityLocation);
    procedure CensusChanged;
    procedure DemandChanged;
    procedure EvaluationChanged;

    procedure StartTimer;

    function  MakeDateFunds: TLayout;
    procedure SetMapState(State: TMapState); overload;
    procedure SetMapState(Sender:TObject); overload;
    procedure StopEarthquake;
    procedure StopTimer;
    function IsTimerActive: Boolean;
    function NeedsSaved: Boolean;
    function MaybeSaveCity: Boolean;
    procedure SetupKeys(MenuItem: TMenuItem; const Prefix: string);
    procedure MakeMenu;
    procedure CloseWindow(Sender: TObject);
    function OnSaveCityClicked: Boolean;  overload;
    function OnSaveCityAsClicked: Boolean; overload;
    procedure OnSaveCityClicked(Sender: TObject);  overload;
    procedure OnSaveCityAsClicked(Sender: TObject);overload;
    procedure OnLoadGameClicked(Sender: TObject);
    procedure OnNewCityClicked(Sender: TObject);
    procedure OnAutoBudgetClicked(Sender: TObject);
    procedure OnAutoBulldozeClicked(Sender: TObject);
    procedure OnDisastersClicked(Sender: TObject);
    procedure OnSoundClicked(Sender: TObject);
    procedure OnViewBudgetClicked;
    procedure OnViewEvaluationClicked;
    procedure OnViewGraphClicked;
    procedure ShowAutoBudget;
    procedure AddDisasterItem(const Key: string; DisasterType: TDisaster;DisastersMenu:TMenuItem);
    procedure OnLaunchTranslationToolClicked;
    procedure OnAboutClicked;
    function GetEngine: TMicropolis;
    procedure OnInvokeDisasterClicked(Sender:TObject);//Disaster: TDisaster);
    procedure OnPriorityClicked(Sender:TObject);  //(NewSpeed: TSpeed);
    procedure AddSpeedItem(const Key: string; SpeedType: TSpeed;PriorityMenu:TMenuItem );
    procedure DoZoom(Dir: Integer; MousePt: TPointF);  overload;
    procedure DoZoom(Dir: Integer); overload;
    procedure OnDifficultyClicked(Sender:TObject); //(NewDifficulty: Integer);
    function MakeToolBtn(const Tool: TMicropolisTool): TSpeedButton;
    function MakeToolbar: TVertScrollBox;
    procedure SelectTool(Sender:TObject);//(const NewTool: TMicropolisTool);
    procedure DoNewCity(FirstTime: Boolean);
    procedure DoQueryTool(XPos, YPos: Integer);
    procedure OnToolDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure OnEscapePressed;
    procedure OnToolUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure PreviewTool;
    procedure OnToolDrag(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure OnToolHover(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure OnToolExited(Sender: TObject);
    procedure ShowToolResult(const Loc: TCityLocation; ResultCode: TToolResult);
    procedure OnShakeTimer(Sender: TObject);
    procedure OnSimTimer(Sender: TObject);




    procedure UpdateDateLabel;
    //procedure StartTimer;
    //procedure StartSimTimer;
    procedure ShowErrorMessage(E: Exception);
    procedure EarthquakeStarted;
    procedure OnWindowClosed(Sender: TObject);
    procedure ShowBudgetWindow(IsEndOfYear: Boolean);
    function MakeMapStateMenuItem(const StringPrefix: string; State: TMapState): TMenuItem;
    procedure SetMapLegend(State: TMapState);
    procedure MenuItemClick(Sender: TObject);
    //procedure StopEarthquake;
    //procedure StopTimer;
    //function IsTimerActive: Boolean;



  public
    CurrentFile : String;

    constructor Create(AOwner: TComponent); override;


    // Interface and event handler declarations go here
    procedure CityMessage(mmessage : TMicropolisMessage;loc : TCityLocation);
    procedure HandleEarthquake; // Placeholder
    procedure OnMicropolisEvent; // Placeholder
    procedure MakeClean;
    procedure SetEngine(NewEngine: TMicropolis);
    class function FormatFunds(Funds: Integer): string;
    class function FormatGameDate(CityTime: Integer): string;
  end;

type
  TImageListHelper = class helper for TImageList
    function Add(aBitmap: TBitmap): integer;
  end;


const
SOUNDS_PREF :String = 'enable_sounds';
EXTENSION :String = 'cty';  //'xml';

var
  MainWindow1: TMainWindow1;

  // ToolStroke and last tool positions
  ToolStroke: TToolStroke;
  LastX, LastY: Integer;


implementation
{$R *.fmx}


constructor TMainWindow1.Create(AOwner: TComponent);
//var
  //EvalGraphsBox: TVBox;
begin
  inherited Create(AOwner);
  ClientWidth := 1280;
  ClientHeight :=900;
  Resources.InitResources;
  FEngine := TMicropolis.Create;
  Self.Caption := 'Micropolis'; // Set Form Title
  MapStateMenuItems := TDictionary<TMapState, TMenuItem>.Create;

  // Initialize Drawing Area
  FDrawingArea := TMicropolisDrawingArea.Create(Self,FEngine);
  FDrawingArea.Height := ClientHeight;
  //FDrawingArea.HitTest := True;
  FDrawingArea.Align := TAlignLayout.None; // We'll wrap it in a scrollbox
  FDrawingArea.ClientMouseMove := Self.OnToolHover;
  FDrawingArea.ClientDrag := Self.OnToolDrag;
  FDrawingArea.ClientPress := Self.OnToolDown;
  FDrawingArea.ClientUp := Self.OnToolUp;

  FDrawingAreaScroll := TScrollBox.Create(Self);
  FDrawingAreaScroll.Parent := Self;
  FDrawingAreaScroll.Align := TAlignLayout.Client;
  FDrawingAreaScroll.HitTest := False;
  FDrawingAreaScroll.ShowScrollBars := False;
  FDrawingAreaScroll.AddObject(FDrawingArea);
  FDrawingArea.ParentScroll := FDrawingAreaScroll;
  Self.AddObject(FDrawingAreaScroll);


  // FDrawingAreaScroll.Visible := False;
  MakeMenu;
  // Initialize Toolbar
  // Replace with actual toolbar creation function
  var Toolbar := MakeToolbar;//TToolBar.Create(Self);
  Toolbar.Align := TAlignLayout.Left;
  Self.AddObject(Toolbar);

  // Evaluation and Graphs panel (VBox equivalent)
  //EvalGraphsBox := TVBox.Create(Self);
  //EvalGraphsBox.Align := TAlignLayout.Bottom;
  //Self.AddObject(EvalGraphsBox);

 // EvalGraphsBox :=



  // Left Pane with DemandIndicator, MapView and Notification/Message Panels
  var LeftPane := TLayout.Create(Self);
  LeftPane.Align := TAlignLayout.Left;
  LeftPane.Width := 420;
  Self.AddObject(LeftPane);

   // var RightPane := TLayout.Create(Self);
  //RightPane.Align := TAlignLayout.Left;
  //RightPane.AddObject(TFmxObject(FDrawingArea));
  //Self.AddObject(RightPane);



  FEvaluationPane := TEvaluationPane.Create(FEngine);//Self);    //Œ¯Ë·Í‡!
  //FEvaluationPane.Align := TAlignLayout.Top;  Need to Ajust
  FEvaluationPane.Visible := False;
  LeftPane.AddObject(FEvaluationPane);    //EvalGraphsBox.

  var FundsDemand := TLayout.Create(Self);
  FundsDemand.Align := TAlignLayout.Top;
  LeftPane.AddObject(FundsDemand);

  FDemandInd := TDemandIndicator.Create(Self,FEngine);
  TDemandIndicator(FDemandInd).Align := TAlignLayout.Left;
  FundsDemand.AddObject(TFmxObject(FDemandInd));

  // Date/Funds Panel
  var FundsPanel := MakeDateFunds;
  FundsDemand.Height := FundsPanel.Height;

  FundsPanel.Align := TAlignLayout.Left;
  FundsDemand.AddObject(FundsPanel);


  FGraphsPane := TGraphsPane.Create(Self);
  FGraphsPane.Align := TAlignLayout.Top;
  FGraphsPane.Height := 250;
  FGraphsPane.Visible := False; //True;
  LeftPane.AddObject(FGraphsPane);   ////EvalGraphsBox.
  // Map View container with menu
  var MapViewContainer := TPanel.Create(Self);
  MapViewContainer.Align := TAlignLayout.Top;//Top;
  //MapViewContainer.Position.Y:=200;
  MapViewContainer.Height := 350;
  //MapViewContainer.Width := 500;
  //MapViewContainer.Stroke.Kind := TBrushKind.Solid;
  //MapViewContainer.Stroke.Color := TAlphaColors.Black;
  LeftPane.AddObject(MapViewContainer);

  FMapLegendImage := TImage.Create(MapViewContainer);
  FMapLegendImage.Align := TAlignLayout.Left;
  FMapLegendImage.Width := 32; // Set your image width
  FMapLegendImage.Margins.Right := 5; // Space between image and label
  MapViewContainer.AddObject(FMapLegendImage);

  FMapLegendLbl := TLabel.Create(Self);
  FMapLegendLbl.Align := TAlignLayout.Top;
  MapViewContainer.AddObject(FMapLegendLbl);

  // Create map menu bar
var MapMenuBar := TMenuBar.Create(MapViewContainer);
MapMenuBar.Parent := MapViewContainer;
//MapMenuBar.Align := TAlignLayout.Top;
//MapMenuBar.Height := 25;

// Zones menu
var ZonesMenuItem := TMenuItem.Create(MapMenuBar);
ZonesMenuItem.Text := Resources.GetGuiString('menu.zones');
MapMenuBar.AddObject(ZonesMenuItem);

// Add zone submenu items
MapStateMenuItems := TDictionary<TMapState, TMenuItem>.Create;
ZonesMenuItem.AddObject(MakeMapStateMenuItem('menu.zones.ALL', msAll));
ZonesMenuItem.AddObject(MakeMapStateMenuItem('menu.zones.RESIDENTIAL', msResidential));
ZonesMenuItem.AddObject(MakeMapStateMenuItem('menu.zones.COMMERCIAL', msCommercial));
ZonesMenuItem.AddObject(MakeMapStateMenuItem('menu.zones.INDUSTRIAL', msIndustrial));
ZonesMenuItem.AddObject(MakeMapStateMenuItem('menu.zones.TRANSPORT', msTransport));

// Overlays menu
var OverlaysMenuItem := TMenuItem.Create(MapMenuBar);
OverlaysMenuItem.Text:= Resources.GetGuiString('menu.overlays');
MapMenuBar.AddObject(OverlaysMenuItem);

// Add overlay submenu items
OverlaysMenuItem.AddObject(MakeMapStateMenuItem('menu.overlays.POPDEN_OVERLAY', msPopDenOverlay));
OverlaysMenuItem.AddObject(MakeMapStateMenuItem('menu.overlays.GROWTHRATE_OVERLAY', msGrowthRateOverlay));
OverlaysMenuItem.AddObject(MakeMapStateMenuItem('menu.overlays.LANDVALUE_OVERLAY',msLandValueOverlay));
OverlaysMenuItem.AddObject(MakeMapStateMenuItem('menu.overlays.CRIME_OVERLAY', msCrimeOverlay));
OverlaysMenuItem.AddObject(MakeMapStateMenuItem('menu.overlays.POLLUTE_OVERLAY', msPolluteOverlay));
OverlaysMenuItem.AddObject(MakeMapStateMenuItem('menu.overlays.TRAFFIC_OVERLAY', msTrafficOverlay));
OverlaysMenuItem.AddObject(MakeMapStateMenuItem('menu.overlays.POWER_OVERLAY',msPowerOverlay));
OverlaysMenuItem.AddObject(MakeMapStateMenuItem('menu.overlays.FIRE_OVERLAY', msFireOverlay));
OverlaysMenuItem.AddObject(MakeMapStateMenuItem('menu.overlays.POLICE_OVERLAY', msPoliceOverlay));



  FMapView := TOverlayMapView.Create(Self,FEngine);
  TOverlayMapView(FMapView).ConnectView(FDrawingArea, FDrawingAreaScroll);
  TOverlayMapView(FMapView).Align := TAlignLayout.Client;
  MapViewContainer.AddObject(TFmxObject(FMapView));
  //LeftPane.AddObject(TFmxObject(FDrawingArea));



  SetMapState(msAll); // equivalent to MapState.ALL

  // Messages pane
  FMessagesPane := TMessagesPane.Create(Self);
  TMessagesPane(FMessagesPane).Align := TAlignLayout.Client;
  LeftPane.AddObject(TFmxObject(FMessagesPane));

  // Notification pane
  FNotificationPane := TNotificationPane.Create(Self,FEngine);
  TNotificationPane(FNotificationPane).Align := TAlignLayout.Bottom;
  LeftPane.AddObject(TFmxObject(FNotificationPane));

  // Preferences, sounds
  DoSounds := True; // Load from ini or registry later if needed

  FDrawingArea.Width := ClientWidth-FDrawingArea.Position.X;

  // Register listeners
  TOverlayMapView(FMapView).SetEngine(FEngine);
  FEngine.AddListener(Self);
  FEngine.AddEarthquakeListener(Self);


  AutoBudgetPending := False;
  CurrentTool := mtNONE;

  ReloadFunds;
  ReloadOptions;
  StartTimer;
  MakeClean;
end;

procedure TMainWindow1.SetEngine(NewEngine: TMicropolis);
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

function TMainWindow1.NeedsSaved: Boolean;
begin
  if Dirty1 then // player built something since last save
    Exit(True);

  if not Dirty2 then // no simulator ticks since last save
    Exit(False);

  // simulation ran, but no player actions ó check time threshold (30s)
  Result := (TThread.GetTickCount64 - FLastSavedTime) > 30000;
end;

function TMainWindow1.MaybeSaveCity: Boolean;
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

procedure TMainWindow1.CloseWindow;
begin
  if MaybeSaveCity then
    Close; // equivalent to dispose()
end;



function TMainWindow1.MakeDateFunds: TLayout;
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
  DateLblLabel.Text := Resources.GetGuiString('main.date_label');
  DateLblLabel.Position.X := 10;
  DateLblLabel.Position.Y := 0;

  DateLbl := TLabel.Create(Pane);
  DateLbl.Parent := Pane;
  DateLbl.Position.X := 80;
  DateLbl.Position.Y := 0;

  // Funds Row
  FundsLblLabel := TLabel.Create(Pane);
  FundsLblLabel.Parent := Pane;
  FundsLblLabel.Text := Resources.GetGuiString('main.funds_label');
  FundsLblLabel.Position.X := 10;
  FundsLblLabel.Position.Y := 30;

  FundsLbl := TLabel.Create(Pane);
  FundsLbl.Parent := Pane;
  FundsLbl.Position.X := 80;
  FundsLbl.Position.Y := 30;

  // Population Row
  PopLblLabel := TLabel.Create(Pane);
  PopLblLabel.Parent := Pane;
  PopLblLabel.Text := Resources.GetGuiString('main.population_label');
  PopLblLabel.Position.X := 10;
  PopLblLabel.Position.Y := 60;

  PopLbl := TLabel.Create(Pane);
  PopLbl.Parent := Pane;
  PopLbl.Position.X := 80;
  PopLbl.Position.Y := 60;

  Result := Pane;
end;

procedure TMainWindow1.SetupKeys(MenuItem: TMenuItem; const Prefix: string);
var
  KeyStr: string;
  ShortCutCode: TShortCut;
begin
  //if Strings.IndexOfName(Prefix + '.key') > -1 then
  begin
    KeyStr := Resources.GetGuiString(Prefix + '.key');
    MenuItem.Text := '&' + KeyStr + ' ' + MenuItem.Text;
  end;

//  if Strings.IndexOfName(Prefix + '.shortcut') > -1 then
  begin
    KeyStr := Resources.GetGuiString(Prefix + '.shortcut');
    ShortCutCode := TextToShortCut(KeyStr);
    MenuItem.ShortCut := ShortCutCode;
  end;
end;


procedure TMainWindow1.AddDisasterItem(const Key: string; DisasterType: TDisaster;DisastersMenu:TMenuItem);
var MenuItem: TMenuItem;
  begin
    MenuItem := TMenuItem.Create(DisastersMenu);
    MenuItem.Name := 'menudisasters_'+Key;
    MenuItem.Text := Resources.GetGuiString('menu.disasters.' + Key);
    MenuItem.OnClick := onInvokeDisasterClicked; //procedure(Sender: TObject)
    //begin
      //onInvokeDisasterClicked(DisasterType);
   // end;
    DisastersMenu.AddObject(MenuItem);
  end;

 procedure TMainWindow1.AddSpeedItem(const Key: string; SpeedType: TSpeed;PriorityMenu:TMenuItem );
 var MenuItem: TMenuItem;
  begin
    MenuItem := TMenuItem.Create(PriorityMenu);
    MenuItem.Text := Resources.GetGuiString('menu.speed.' + Key);
    MenuItem.Name := 'menuspeed_' + Key;
    MenuItem.RadioItem := True;
    MenuItem.OnClick := onPriorityClicked; //procedure(Sender: TObject)
    //begin
     // (SpeedType);
    //end;
    PriorityMenu.AddObject(MenuItem);
    PriorityMenuItems[Ord(SpeedType)] := MenuItem;
  end;

procedure TMainWindow1.MenuItemClick(Sender: TObject);
var
  MenuItem: TMenuItem;
begin
  if not (Sender is TMenuItem) then
    Exit;

  MenuItem := TMenuItem(Sender);

  case MenuItem.Tag of
    MENU_ZOOM_IN: DoZoom(1);
    MENU_ZOOM_OUT: DoZoom(-1);
    MENU_BUDGET: OnViewBudgetClicked;
    MENU_EVALUATION: OnViewEvaluationClicked;
    MENU_GRAPH: OnViewGraphClicked;
    MENU_LAUNCH_TRANSLATION: OnLaunchTranslationToolClicked;
    MENU_ABOUT: OnAboutClicked;
  else
    // Handle unknown menu item
  end;
end;



procedure TMainWindow1.MakeMenu;
var
  MenuBar: TMainMenu;
  GameMenu, OptionsMenu, DisastersMenu, PriorityMenu, WindowsMenu, HelpMenu: TMenuItem;
  LevelMenuItem ,MenuItem,LevelMenu:TMenuItem;
  Level,i: Integer;
begin
  MenuBar := TMainMenu.Create(Self);
  MenuBar.Parent := Self;
  Self.Menu := MenuBar;

  GameMenu := TMenuItem.Create(MenuBar);
  GameMenu.Text := Resources.GetGuiString('menu.game');
  SetupKeys(GameMenu, 'menu.game');
  MenuBar.AddObject(GameMenu);

  MenuItem := TMenuItem.Create(GameMenu);
  MenuItem.Text := Resources.GetGuiString('menu.game.new');
  SetupKeys(MenuItem, 'menu.game.new');
  MenuItem.OnClick := OnNewCityClicked;
  GameMenu.AddObject(MenuItem);

  MenuItem := TMenuItem.Create(GameMenu);
  MenuItem.Text := Resources.GetGuiString('menu.game.load');
  SetupKeys(MenuItem, 'menu.game.load');
  MenuItem.OnClick := OnLoadGameClicked;
  GameMenu.AddObject(MenuItem);

  MenuItem := TMenuItem.Create(GameMenu);
  MenuItem.Text := Resources.GetGuiString('menu.game.save');
  SetupKeys(MenuItem, 'menu.game.save');
  MenuItem.OnClick := OnSaveCityClicked;// procedure(Sender: TObject)
   // begin OnSaveCityClicked; end;
  GameMenu.AddObject(MenuItem);

  MenuItem := TMenuItem.Create(GameMenu);
  MenuItem.Text := Resources.GetGuiString('menu.game.save_as');
  SetupKeys(MenuItem, 'menu.game.save_as');
  MenuItem.OnClick := OnSaveCityAsClicked; //procedure(Sender: TObject)
   //begin OnSaveCityAsClicked;end;
  GameMenu.AddObject(MenuItem);

  MenuItem := TMenuItem.Create(GameMenu);
  MenuItem.Text := Resources.GetGuiString('menu.game.exit');
  SetupKeys(MenuItem, 'menu.game.exit');
  MenuItem.OnClick := CloseWindow;//procedure(Sender: TObject)  begin   CloseWindow; end;
  GameMenu.AddObject(MenuItem);

     // Options Menu
  OptionsMenu := TMenuItem.Create(MainMenu);
  OptionsMenu.Text := Resources.GetGuiString('menu.options');
  MenuBar.AddObject(OptionsMenu);

  // Level Menu
  LevelMenu := TMenuItem.Create(OptionsMenu);
  LevelMenu.Text := Resources.GetGuiString('menu.difficulty');
  OptionsMenu.AddObject(LevelMenu);

   SetLength(DifficultyMenuItems, GameLevel.MAX_LEVEL - GameLevel.MIN_LEVEL + 1);
  for i := GameLevel.MIN_LEVEL to GameLevel.MAX_LEVEL do
  begin
    Level := i;
    LevelMenuItem := TMenuItem.Create(LevelMenu);
    LevelMenuItem.Name := 'menudifficulty' + Level.ToString;
    LevelMenuItem.Text := Resources.GetGuiString('menu.difficulty.' + Level.ToString);
    LevelMenuItem.IsChecked := False;
    LevelMenuItem.RadioItem := True;
    LevelMenuItem.OnClick := onDifficultyClicked; //procedure(Sender: TObject)
   // begin
       //onDifficultyClicked(Level);
    //end;
    LevelMenu.AddObject(LevelMenuItem);
    DifficultyMenuItems[Level] := LevelMenuItem;
  end;

   // Auto Budget
  MenuItem := TMenuItem.Create(OptionsMenu);
  MenuItem.Text := Resources.GetGuiString('menu.options.auto_budget');
  MenuItem.IsChecked := False;
  MenuItem.OnClick :=  onAutoBudgetClicked; {procedure(Sender: TObject)
  begin
    onAutoBudgetClicked(Sender);
  end;     }
  OptionsMenu.AddObject(MenuItem);
  AutoBudgetMenuItem := MenuItem;

  // Auto Bulldoze
  MenuItem := TMenuItem.Create(OptionsMenu);
  MenuItem.Text := Resources.GetGuiString('menu.options.auto_bulldoze');
  MenuItem.IsChecked := False;
  MenuItem.OnClick := onAutoBulldozeClicked;{ procedure(Sender: TObject)
  begin
    onAutoBulldozeClicked();
  end;  }
  OptionsMenu.AddObject(MenuItem);
  AutoBulldozeMenuItem := MenuItem;

  // Disasters Option Toggle
  MenuItem := TMenuItem.Create(OptionsMenu);
  MenuItem.Text := Resources.GetGuiString('menu.options.disasters');
  MenuItem.IsChecked := False;
  MenuItem.OnClick := onDisastersClicked; {procedure(Sender: TObject)
  begin
    ();
  end;      }
  OptionsMenu.AddObject(MenuItem);
  DisastersMenuItem := MenuItem;

  // Sound Option Toggle
  MenuItem := TMenuItem.Create(OptionsMenu);
  MenuItem.Text := Resources.GetGuiString('menu.options.sound');
  MenuItem.IsChecked := False;
  MenuItem.OnClick := onSoundClicked; {procedure(Sender: TObject)
  begin
    ();
  end; }
  OptionsMenu.AddObject(MenuItem);
  SoundsMenuItem := MenuItem;

  // Zoom In
  MenuItem := TMenuItem.Create(OptionsMenu);
  MenuItem.Text := Resources.GetGuiString('menu.options.zoom_in');
  MenuItem.Tag := MENU_ZOOM_IN;
  MenuItem.OnClick := MenuItemClick;
  OptionsMenu.AddObject(MenuItem);

  // Zoom Out
  MenuItem := TMenuItem.Create(OptionsMenu);
  MenuItem.Text := Resources.GetGuiString('menu.options.zoom_out');
  MenuItem.Tag := MENU_ZOOM_OUT;
  MenuItem.OnClick := MenuItemClick;
  OptionsMenu.AddObject(MenuItem);

  // Disasters Menu
  DisastersMenu := TMenuItem.Create(MenuBar);
  DisastersMenu.Text := Resources.GetGuiString('menu.disasters');
  MenuBar.AddObject(DisastersMenu);

  // Disaster Items

  AddDisasterItem('MONSTER', Disaster.dMONSTER,DisastersMenu);
  AddDisasterItem('FIRE', Disaster.dFIRE,DisastersMenu);
  AddDisasterItem('FLOOD', Disaster.dFLOOD,DisastersMenu);
  AddDisasterItem('MELTDOWN', Disaster.dMELTDOWN,DisastersMenu);
  AddDisasterItem('TORNADO', Disaster.dTORNADO,DisastersMenu);
  AddDisasterItem('EARTHQUAKE', Disaster.dEARTHQUAKE,DisastersMenu);

  // Speed Menu
  PriorityMenu := TMenuItem.Create(MenuBar);
  PriorityMenu.Text := Resources.GetGuiString('menu.speed');
  MenuBar.AddObject(PriorityMenu);

  SetLength(PriorityMenuItems,Ord(high(TSpeed))+1);
  AddSpeedItem('SUPER_FAST', Speed.SUPER_FAST,PriorityMenu);
  AddSpeedItem('FAST', Speed.FAST,PriorityMenu);
  AddSpeedItem('NORMAL', Speed.NORMAL,PriorityMenu);
  AddSpeedItem('SLOW', Speed.SLOW,PriorityMenu);
  AddSpeedItem('PAUSED', Speed.PAUSED,PriorityMenu);

  // Windows Menu
  WindowsMenu := TMenuItem.Create(MenuBar);
  WindowsMenu.Text := Resources.GetGuiString('menu.windows');
  MenuBar.AddObject(WindowsMenu);

  // Budget
  MenuItem := TMenuItem.Create(WindowsMenu);
  MenuItem.Text := Resources.GetGuiString('menu.windows.budget');
  MenuItem.Tag := MENU_BUDGET;
  MenuItem.OnClick := MenuItemClick;
  WindowsMenu.AddObject(MenuItem);

  // Evaluation
  MenuItem := TMenuItem.Create(WindowsMenu);
  MenuItem.Text := Resources.GetGuiString('menu.windows.evaluation');
  MenuItem.Tag := MENU_EVALUATION;
  MenuItem.OnClick := MenuItemClick;
  WindowsMenu.AddObject(MenuItem);

  // Graph
  MenuItem := TMenuItem.Create(WindowsMenu);
  MenuItem.Text := Resources.GetGuiString('menu.windows.graph');
  MenuItem.Tag := MENU_GRAPH;
  MenuItem.OnClick := MenuItemClick;
  WindowsMenu.AddObject(MenuItem);

  // Help Menu
  HelpMenu := TMenuItem.Create(MainMenu);
  HelpMenu.Text := Resources.GetGuiString('menu.help');
  MenuBar.AddObject(HelpMenu);

  // Launch Translation Tool
  MenuItem := TMenuItem.Create(HelpMenu);
  MenuItem.Text := Resources.GetGuiString('menu.help.launch-translation-tool');
  MenuItem.Tag := MENU_LAUNCH_TRANSLATION;
  MenuItem.OnClick := MenuItemClick;
  HelpMenu.AddObject(MenuItem);

  // About
  MenuItem := TMenuItem.Create(HelpMenu);
  MenuItem.Text := Resources.GetGuiString('menu.help.about');
  MenuItem.Tag := MENU_ABOUT;
  MenuItem.OnClick := MenuItemClick;
  HelpMenu.AddObject(MenuItem);
end;

function TMainWindow1.GetEngine: TMicropolis;
begin
  Result := FEngine;
end;

{
procedure TMainWindow1.SetEngine(NewEngine: TMicropolis);
begin
  FEngine := NewEngine;
  // additional setup if needed
end;
}

procedure TMainWindow1.OnAutoBudgetClicked(Sender: TObject);
begin
  Dirty1 := True;
  GetEngine.ToggleAutoBudget;
end;

procedure TMainWindow1.OnAutoBulldozeClicked(Sender: TObject);
begin
  Dirty1 := True;
  GetEngine.ToggleAutoBulldoze;
end;

procedure TMainWindow1.OnDisastersClicked(Sender: TObject);
begin
  Dirty1 := True;
  GetEngine.ToggleDisasters;
end;

procedure TMainWindow1.OnSoundClicked(Sender: TObject);
var
  Ini: TIniFile;
begin
  DoSounds := not DoSounds;
  Ini := TIniFile.Create(System.IOUtils.TPath.Combine(System.IOUtils.TPath.GetHomePath, 'settings.ini'));
  try
    Ini.WriteBool('Preferences', SOUNDS_PREF, DoSounds);
  finally
    Ini.Free;
  end;
  ReloadOptions;
end;

procedure TMainWindow1.MakeClean;
var
  FileName, TitleText: string;
begin
  Dirty1 := False;
  Dirty2 := False;
  FLastSavedTime := TThread.GetTickCount64; //Now;
  if not CurrentFile.IsEmpty then
  begin
    FileName := System.IOUtils.TPath.GetFileName(CurrentFile);
    if FileName.EndsWith('.' + EXTENSION) then
      FileName := Copy(FileName, 1, Length(FileName) - Length(EXTENSION) - 1);

    TitleText := Format(Resources.GetGuiString('main.caption_named_city'), [FileName]);
  end
  else
    TitleText := Resources.GetGuiString('main.caption_unnamed_city');

  Caption:=TitleText;
end;

function TMainWindow1.OnSaveCityClicked: Boolean;
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

function TMainWindow1.OnSaveCityAsClicked: Boolean;
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
    Dialog.Filter := Resources.GetGuiString('cty_file') + '|*.' + EXTENSION;
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

procedure TMainWindow1.OnSaveCityClicked(Sender: TObject);
begin
  OnSaveCityClicked;
end;

procedure TMainWindow1.OnSaveCityAsClicked(Sender: TObject);
begin
  OnSaveCityAsClicked;
end;

procedure TMainWindow1.OnLoadGameClicked(Sender: TObject);
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
    Dialog.Filter := Resources.GetGuiString('cty_file') + '|*.' + EXTENSION;
    if Dialog.Execute then
    begin
      FileName := Dialog.FileName;
      NewEngine := TMicropolis.Create;
      try
        NewEngine.Load(FileName);
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

function TMainWindow1.MakeToolBtn(const Tool: TMicropolisTool): TSpeedButton;
var
  Btn: TSpeedButton;
  IconPath, TipText,IconSelectedPath: string;
  Icon,SelectedIcon : TBitmap;
  Image: TImage;
begin
  Btn := TSpeedButton.Create(Self);
  Btn.Parent := Self; // Or assign later when adding to a container
  Btn.Text := '';  // We only want an icon
  Btn.StyleLookup := 'toolbutton';
  Btn.Tag := 10+Ord(Tool);

  Image := TImage.Create(Btn);
  Image.Parent := Btn;
  Image.HitTest := False;
  Image.Align := TAlignLayout.Client;
  Image.Margins.Rect := TRectF.Create(4, 4, 4, 4);

  IconPath :=Resources.GetGuiString('tool.' + GetToolName(Tool) + '.icon');
  if IconPath='' then IconPath:= '/graphics/tools/' + LowerCase(GetToolName(Tool)) + '.png'
                 else IconPath:= './resources'+IconPath;

  IconSelectedPath := Resources.GetGuiString('tool.' + GetToolName(Tool) + '.selected_icon');
  if IconSelectedPath = '' then IconSelectedPath := IconPath  // Use normal icon as fallback
                           else IconSelectedPath := './resources' + IconSelectedPath;
  TipText := Resources.GetGuiString('tool.' + GetToolName(Tool) + '.tip');
  if TipText='' then TipText:= GetToolName(Tool);

  try
    Icon := TBitmap.Create;
    Icon.LoadFromFile(IconPath);//ExpandFileName(IconPath));
    //Btn.Images.Assign()
    //Btn.Bitmap.Bitmap.LoadFromFile(ExpandFileName(IconPath));
  except
    //logError('Failed to load icon: ' + IconName); // Handle missing image
  end;

  // Load selected icon

  try
    SelectedIcon := TBitmap.Create;
    SelectedIcon.LoadFromFile(IconSelectedPath);
  except
  // If selected icon fails to load, use normal icon as fallback
    SelectedIcon.Assign(Icon);
  end;
  //Image.Bitmap := Icon;
  // Use TImageList approach for proper state management
  //Var BtnBmp :=  Btn.Sour

var ImageList: TImageList;
ImageList := TImageList.Create(Self);
try
  // Add both icons to image list

  //ImageList.Source.Mul
  ImageList.Add(Icon);
  ImageList.Add(SelectedIcon);
  // Assign to button
  Btn.Images := ImageList;
  //Btn.ImageIndex := 0;  // Normal state
  //Btn.Images
  var Sz:TSize;
  Sz.cx := Icon.Width;
  Sz.cy := Icon.Height;
  Image.Bitmap := ImageList.Bitmap(Sz,0); //Icon;
  //Btn.DisabledIndex := 0; // Use normal icon when disabled
  // Note: TSpeedButton doesn't have direct SelectedImageIndex property
except
  ImageList.Free;
  raise;
end;

  Btn.Hint := TipText;
  Btn.HitTest := True;
  Btn.Margins.Rect := TRectF.Create(0, 0, 0, 0);
  Btn.StyledSettings := [TStyledSetting.Family, TStyledSetting.FontColor];
  Btn.OnClick := SelectTool;//procedure(Sender: TObject)
   // begin
    //  SelectTool(Tool);
    //end;

  ToolBtns.Add(Tool, Btn);
  ToolImages.Add(Tool, Image);

  Result := Btn;
end;

function TMainWindow1.MakeToolbar: TVertScrollBox;
var
  Toolbar: TVertScrollBox;
  Row: TLayout;
  Btn : TSpeedButton;
  Tools: array[0..5] of array of TMicropolisTool;
  //RowTools : array of TMicropolisTool;
  i:Integer;

begin
  ToolBtns := TDictionary<TMicropolisTool, TSpeedButton>.Create;
  ToolImages := TDictionary<TMicropolisTool, TImage>.Create;


  Toolbar := TVertScrollBox.Create(Self);
  Toolbar.Align := TAlignLayout.Left;
  Toolbar.Width := 110;
  Toolbar.Margins.Top := 10;
  Toolbar.HitTest := False;

  Row := TLayout.Create(Self);
  Row.Parent := Toolbar;
  Row.Align := TAlignLayout.Top;
  Row.Height := 40;

  // Tool Label
  CurrentToolLbl := TLabel.Create(Self);
  CurrentToolLbl.Parent := Row;//Toolbar;
  CurrentToolLbl.Text := ' ';
  CurrentToolLbl.Position.Y := 0;
  //CurrentToolLbl.Margins.Bottom := 5;

  // Cost Label
  CurrentToolCostLbl := TLabel.Create(Self);
  CurrentToolCostLbl.Parent := Row;//Toolbar;
  CurrentToolCostLbl.Text := ' ';
  CurrentToolCostLbl.Position.Y := 15;
  //CurrentToolCostLbl.Margins.Bottom := 10;

  Tools[0] := [mtBULLDOZER, mtWIRE, mtPARK];
  Tools[1] := [mtROADS, mtRAIL];
  Tools[2] := [mtRESIDENTIAL, mtCOMMERCIAL, mtINDUSTRIAL];
  Tools[3] := [mtFIRE, mtQUERY, mtPOLICE];
  Tools[4] := [mtPOWERPLANT, mtNUCLEAR];
  Tools[5] := [mtSTADIUM, mtSEAPORT];

  for i:=0 to 5 do
  begin
    Row := TLayout.Create(Self);
    Row.Parent := Toolbar;
    Row.Align := TAlignLayout.Top;
    Row.Height := 40;
    Row.Padding.Bottom := 5;

    for var Tool in Tools[i] do
    begin
      Btn := MakeToolBtn(Tool);
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
  Btn := MakeToolBtn(mtAIRPORT);
  Btn.Parent := Row;
  Btn.Align := TAlignLayout.Left;
  Btn.Width := 36;
  Btn.Height := 36;

  Result := Toolbar;
end;

procedure TMainWindow1.SelectTool(Sender:TObject);//(const NewTool: TMicropolisTool);
var NewTool: TMicropolisTool;
begin
  NewTool :=  TMicropolisTool((Sender as TSpeedButton).Tag - 10);
  if CurrentTool = NewTool then
    Exit;


   var Sz:TSize;

  // Unselect previous
  if ToolBtns.ContainsKey(CurrentTool) then
  begin
    ToolBtns[CurrentTool].IsPressed := False;
    //ToolBtns[CurrentTool].ImageIndex := 0;
     Sz.cx := ToolImages[CurrentTool].Bitmap.Width;
     Sz.cy := ToolImages[CurrentTool].Bitmap.Height;
     ToolImages[CurrentTool].Bitmap := ToolBtns[CurrentTool].Images.Bitmap(Sz,0);
  end;

  // Select new
  CurrentTool := NewTool;
  if ToolBtns.ContainsKey(CurrentTool) then
  begin
    ToolBtns[CurrentTool].IsPressed := True;
    Sz.cx := ToolImages[CurrentTool].Bitmap.Width;
     Sz.cy := ToolImages[CurrentTool].Bitmap.Height;
    ToolImages[CurrentTool].Bitmap := ToolBtns[CurrentTool].Images.Bitmap(Sz,1);
     //ToolBtns[CurrentTool].ImageIndex := 1;
  end;

  // Update UI
    CurrentToolLbl.Text := Resources.GetGuiString('tool.' + GetToolName(CurrentTool) + '.name');
  if CurrentToolLbl.Text ='' then
    CurrentToolLbl.Text := GetToolName(CurrentTool);

  var Cost := GetToolCost(CurrentTool);  // Youíll need to define this method
  if Cost <> 0 then
    CurrentToolCostLbl.Text := FormatFunds(Cost)
  else
    CurrentToolCostLbl.Text := ' ';
end;

procedure TMainWindow1.OnNewCityClicked(Sender: TObject);
begin
  if MaybeSaveCity then
    DoNewCity(False);
end;

procedure TMainWindow1.DoNewCity(FirstTime: Boolean);
begin
  var TimerEnabled := IsTimerActive;
  if TimerEnabled then StopTimer;

  var NewCityDlg := TNewCityDialog.CreateDialog(Self,True);
  try
    NewCityDlg.ShowModal;
  finally
    NewCityDlg.Free;
  end;

  if TimerEnabled then StartTimer;
end;

procedure TMainWindow1.DoQueryTool(XPos, YPos: Integer);
var
  Z: TZoneStatus;
begin
  if not FEngine.TestBounds(XPos, YPos) then Exit;
  Z := FEngine.QueryZoneStatus(XPos, YPos);
  FNotificationPane.ShowZoneStatus(FEngine, XPos, YPos, Z);
end;

procedure TMainWindow1.DoZoom(Dir: Integer; MousePt: TPointF);
var
  OldZoom, NewZoom: Integer;
  F: Double;
  Pos: TPointF;
  NewX, NewY: Integer;
begin
  OldZoom := FDrawingArea.GetTileSize;
  if Dir < 0 then
    NewZoom := OldZoom div 2
  else
    NewZoom := OldZoom * 2;

  if NewZoom < 8 then NewZoom := 8;
  if NewZoom > 32 then NewZoom := 32;

  if OldZoom <> NewZoom then
  begin
    if OldZoom>0 then F := NewZoom / OldZoom
                 else F := 1;
    Pos := FDrawingAreaScroll.ViewportPosition;
    NewX := Round(MousePt.X * F - (MousePt.X - Round(Pos.X)));
    NewY := Round(MousePt.Y * F - (MousePt.Y - Round(Pos.Y)));

    FDrawingArea.SelectTileSize(NewZoom);
    FDrawingAreaScroll.RealignContent;//Realign; // or Invalidate, depending on your FMX version
    FDrawingAreaScroll.ViewportPosition := PointF(NewX, NewY);
  end;
end;

procedure TMainWindow1.DoZoom(Dir: Integer);
var
  //Rect: TRectF;
  MousePt: TPointF;
begin
  //Rect := FDrawingAreaScroll.ViewportRect;
  MousePt.X :=  FDrawingAreaScroll.ViewportPosition.X + FDrawingAreaScroll.Width / 2;//Round(Rect.Left + Rect.Width / 2);
  MousePt.Y := FDrawingAreaScroll.ViewportPosition.Y + FDrawingAreaScroll.Height / 2;//Round(Rect.Top + Rect.Height / 2);
  DoZoom(Dir, MousePt);
end;

procedure TMainWindow1.OnMouseWheelMoved(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
var
  MousePos: TPointF;
begin

  MousePos := ScreenToClient(Screen.MousePos);
 // MousePos.X := Mouse.CursorPos.X; // Or translate to control coords
 // MousePos.Y := Mouse.CursorPos.Y;
  if WheelDelta > 0 then
    DoZoom(1, MousePos)
  else
    DoZoom(-1, MousePos);
  Handled := True;
end;


procedure TMainWindow1.OnToolDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  Loc: TCityLocation;
  IX, IY: Integer;
begin
  if Button = TMouseButton.mbRight then
  begin
    Loc := FDrawingArea.GetCityLocation(Round(X), Round(Y));
    DoQueryTool(Loc.X, Loc.Y);
    Exit;
  end;

  if Button <> TMouseButton.mbLeft then Exit;
  if CurrentTool = mtNone then Exit;

  Loc := FDrawingArea.GetCityLocation(Round(X), Round(Y));
  IX := Loc.X;
  IY := Loc.Y;

  if CurrentTool = mtQUERY then
  begin
    DoQueryTool(IX, IY);
    ToolStroke := nil;
  end
  else
  begin
    ToolStroke :=  BeginStroke(FEngine,CurrentTool, IX, IY);
    PreviewTool;
  end;

  LastX := IX;
  LastY := IY;
end;

procedure TMainWindow1.OnEscapePressed;
begin
  if Assigned(ToolStroke) then
  begin
    ToolStroke := nil;
    FDrawingArea.SetToolPreview(nil);
    FDrawingArea.SetToolCursor(nil);
  end
  else
    FNotificationPane.Visible := False;

    var Sz:TSize;
if ToolBtns.ContainsKey(CurrentTool) then
  begin
    ToolBtns[CurrentTool].IsPressed := False;
    //ToolBtns[CurrentTool].ImageIndex := 0;
     Sz.cx := ToolImages[CurrentTool].Bitmap.Width;
     Sz.cy := ToolImages[CurrentTool].Bitmap.Height;
     ToolImages[CurrentTool].Bitmap := ToolBtns[CurrentTool].Images.Bitmap(Sz,0);
  end;

   //if ToolBtns.ContainsKey(CurrentTool) then
   // ToolBtns[CurrentTool].IsPressed := False;
   CurrentTool := mtNone;
end;

procedure TMainWindow1.OnToolUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  Loc: TCityLocation;
  TR: TToolResult;
begin
  if CurrentTool = mtNone then Exit;
  if Assigned(ToolStroke) then
  begin
    FDrawingArea.SetToolPreview(nil);
    Loc := ToolStroke.GetLocation;
    TR := ToolStroke.Apply;
    ShowToolResult(Loc, TR);
    ToolStroke := nil;
    FundsChanged;
  end;

  OnToolHover(Sender, Shift, X, Y);

  if AutoBudgetPending then
  begin
    AutoBudgetPending := False;
    ShowBudgetWindow(True);
  end;
end;

procedure TMainWindow1.PreviewTool;
begin
  Assert(Assigned(ToolStroke));
  //Assert(CurrentTool <> nil);

  FDrawingArea.SetToolCursor(
    ToolStroke.GetBounds,
    CurrentTool);

  FDrawingArea.SetToolPreview(
    ToolStroke.GetPreview);
end;

procedure TMainWindow1.OnToolDrag(Sender: TObject; Shift: TShiftState; X, Y: Single);
var
  Loc: TCityLocation;
  IX, IY: Integer;
begin
  //if CurrentTool = nil then Exit;
  if not (ssLeft in Shift) then Exit;

  Loc := FDrawingArea.GetCityLocation(Round(X), Round(Y));
  IX := Loc.X;
  IY := Loc.Y;
  if (IX = LastX) and (IY = LastY) then Exit;

  if Assigned(ToolStroke) then
  begin
    ToolStroke.DragTo(IX, IY);
    PreviewTool;
  end
  else if CurrentTool = mtQuery then
  begin
    DoQueryTool(IX, IY);
  end;

  LastX := IX;
  LastY := IY;
end;

procedure TMainWindow1.OnToolHover(Sender: TObject; Shift: TShiftState; X, Y: Single);
var
  Loc: TCityLocation;
  CX, CY, W, H: Integer;
begin
  if (CurrentTool = mtNONE) or (CurrentTool = mtQuery) then
  begin
    FDrawingArea.SetToolCursor(nil);
    Exit;
  end;

  Loc := FDrawingArea.GetCityLocation(Round(X), Round(Y));
  CX := Loc.X;
  CY := Loc.Y;
  W := GetToolWidth(CurrentTool);
  H := GetToolHeight(CurrentTool);

  if W >= 3 then Dec(CX);
  if H >= 3 then Dec(CY);

  FDrawingArea.SetToolCursor(TCityRect.Create(CX, CY, W, H), CurrentTool);
end;

procedure TMainWindow1.OnToolExited(Sender: TObject);
begin
  FDrawingArea.SetToolCursor(nil);
end;

procedure TMainWindow1.ShowToolResult(const Loc: TCityLocation; ResultCode: TToolResult);
begin
  case ResultCode of
    trSUCCESS:
      begin
        if CurrentTool = TMicropolisTool.mtBulldozer then
          CitySound(TSound.Create(BULLDOZE), Loc)
        else
          CitySound(TSound.Create(BUILD), Loc);
        Dirty1 := True;
      end;

    trNONE: ; // do nothing

    trUHOH:
      begin
        FMessagesPane.AppendCityMessage(BULLDOZE_FIRST);
        CitySound(TSound.Create(UHUH), Loc);
      end;

    trINSUFFICIENTFUNDS:
      begin
        FMessagesPane.AppendCityMessage(INSUFFICIENT_FUNDS);
        CitySound(TSound.Create(SORRY), Loc);
      end;

  else
    Assert(False, 'Unexpected ToolResult');
  end;
end;

class function TMainWindow1.FormatFunds(Funds: Integer): string;
begin
  Result := Format(Resources.GetGuiString('funds'), [Funds]);
end;

class function TMainWindow1.FormatGameDate(CityTime: Integer): string;
var
  Year, Month, Day: Integer;
  Date: TDateTime;
begin
  Year := 1900 + CityTime div 48;
  Month := (CityTime mod 48) div 4 + 1;  // Delphi months are 1-based
  Day := (CityTime mod 4) * 7 + 1;

  Date := EncodeDate(Year, Month, Day);
  Result := IntToStr(Day)+'.'+IntToStr(Month)+'.'+IntToStr(Year);//Format(Resources.GetGuiString('citytime'), [Date]);
end;



procedure TMainWindow1.FormKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
begin
  if Key=27 then OnEscapePressed;
end;

procedure TMainWindow1.FormMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Single);
begin
  //if FDrawingArea.DaX>3 then OnToolHover(Sender,Shift,FDrawingArea.DaX,Y);
end;

procedure TMainWindow1.UpdateDateLabel;
var
  NF: TFormatSettings;
begin
  DateLbl.Text := FormatGameDate(FEngine.CityTime);

  NF := TFormatSettings.Create;
  NF.ThousandSeparator := ',';
  PopLbl.Text := FormatFloat('#,##0', FEngine.GetCityPopulation, NF);
end;

procedure TMainWindow1.OnShakeTimer(Sender: TObject);
begin
        CurrentEarthquake.OneStep;
        if CurrentEarthquake.FCount = 0 then
        begin
          StopTimer;
          CurrentEarthquake := nil;
          StartTimer;
        end;
end;


procedure TMainWindow1.OnSimTimer(Sender: TObject);
 var i: Integer;
    begin
      try
        for i := 1 to SpeedInfo[GetEngine.SimSpeed].SimStepsPerUpdate do
        begin
          GetEngine.Animate;
          if (not GetEngine.AutoBudget) and GetEngine.IsBudgetTime then
          begin
            ShowAutoBudget;
            Exit;
          end;
        end;
        UpdateDateLabel;
        FundsChanged;
        Dirty2 := True;
      except
        //on E: Exception do
         // ShowErrorMessage(E);
      end;
    end;

procedure TMainWindow1.StartTimer;
var
  Count, Interval: Integer;
  Engine: TMicropolis;
begin
  Engine := GetEngine;
 // Count := SpeedInfo[Engine.SimSpeed].SimStepsPerUpdate;

  Assert(not IsTimerActive);

  if Engine.SimSpeed = PAUSED then Exit;

  if Assigned(CurrentEarthquake) then
  begin
    Interval := 3000 div MicropolisDrawingArea.SHAKE_STEPS;
    ShakeTimer := TTimer.Create(Self);
    ShakeTimer.Interval := Interval;
    ShakeTimer.OnTimer := OnShakeTimer;
    ShakeTimer.Enabled := True;
    Exit;
  end;

  SimTimer := TTimer.Create(Self);
  SimTimer.Interval := SpeedInfo[Engine.SimSpeed].AnimationDelay;
  SimTimer.OnTimer := OnSimTimer;//procedure(Sender: TObject)

  SimTimer.Enabled := True;
end;

constructor TMainWindow1.TEarthquakeStepper.Create(AOwner: TMainWindow1);
begin
  inherited Create;
  FOwner := AOwner;
  FCount := 0;
end;


procedure TMainWindow1.TEarthquakeStepper.OneStep;
begin
  FCount := (FCount + 1) mod MicropolisDrawingArea.SHAKE_STEPS;
  FOwner.FDrawingArea.Shake(FCount);
end;


{
procedure TMainWindow1.StartSimTimer;
var
  i, Count: Integer;
begin
  Count := SpeedInfo[FEngine.SimSpeed].SimStepsPerUpdate;

  Assert(SimTimer = nil);

  SimTimer := TTimer.Create(Self);
  SimTimer.Interval := SpeedInfo[FEngine.SimSpeed].AnimationDelay;
  SimTimer.OnTimer := procedure(Sender: TObject)
  var
    i: Integer;
  begin
    try
      for i := 0 to Count - 1 do
      begin
        FEngine.Animate;
        if (not FEngine.AutoBudget) and FEngine.IsBudgetTime then
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
}

procedure TMainWindow1.ShowErrorMessage(E: Exception);
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
    DetailsForm.Caption := Resources.GetGuiString('main.error_unexpected');

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
      [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo, TMsgDlgBtn.mbCancel], THelpContext(0)) of
      mrYes: // Show stack trace
        begin
          DetailsForm.ShowModal;
        end;
      mrNo: // Close dialog, do nothing
        Exit;
      mrCancel: // Shutdown
        begin
          if MessageDlg(Resources.GetGuiString('error.shutdown_query'),
            TMsgDlgType.mtWarning, [TMsgDlgBtn.mbOk, TMsgDlgBtn.mbCancel], 0) = mrOk then
            Application.Terminate;
        end;
    end;
  finally
    DetailsForm.Free;
  end;
end;

procedure TMainWindow1.EarthquakeStarted;
begin
  if IsTimerActive then
    StopTimer;

  CurrentEarthquake := TEarthquakeStepper.Create(Self);
  CurrentEarthquake.OneStep;
  StartTimer;
end;

procedure TMainWindow1.StopEarthquake;
begin
  FDrawingArea.Shake(0);
  FreeAndNil(CurrentEarthquake);
end;

procedure TMainWindow1.StopTimer;
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

function TMainWindow1.IsTimerActive: Boolean;
begin
  Result := (SimTimer <> nil) or (ShakeTimer <> nil);
end;

procedure TMainWindow1.OnWindowClosed(Sender: TObject);
begin
  if IsTimerActive then
    StopTimer;
end;

procedure TMainWindow1.OnDifficultyClicked(Sender:TObject); //(NewDifficulty: Integer);
var S:String;
begin
  S:=TMenuItem(Sender).Name;
  FEngine.GameLevel := StrToInt(S[High(S)]);//NewDifficulty;
end;

procedure TMainWindow1.OnPriorityClicked; //  (NewSpeed: TSpeed);
var
NewSpeed: TSpeed;
begin
  if IsTimerActive then
    StopTimer;
  if TMenuItem(Sender).Name='menuspeed_SUPER_FAST' then NewSpeed := Speed.SUPER_FAST;
  if TMenuItem(Sender).Name='menuspeed_FAST' then NewSpeed := Speed.FAST;
  if TMenuItem(Sender).Name='menuspeed_NORMAL' then NewSpeed := Speed.NORMAL;
  if TMenuItem(Sender).Name='menuspeed_SLOW' then NewSpeed := Speed.SLOW;
  if TMenuItem(Sender).Name='menuspeed_PAUSED' then NewSpeed := Speed.PAUSED;
  FEngine.SetSpeed(NewSpeed);
  StartTimer;
end;

procedure TMainWindow1.OnInvokeDisasterClicked(Sender: TObject);
begin
Dirty1 := True;
if TMenuItem(Sender).Name='menudisasters_MONSTER' then FEngine.MakeMonster;
if TMenuItem(Sender).Name='menudisasters_FIRE' then FEngine.MakeFire;
if TMenuItem(Sender).Name='menudisasters_FLOOD' then FEngine.MakeFlood;
if TMenuItem(Sender).Name='menudisasters_MELTDOWN' then
  if not FEngine.MakeMeltdown then
        FMessagesPane.AppendCityMessage(NO_NUCLEAR_PLANTS);
if TMenuItem(Sender).Name='menudisasters_TORNADO' then FEngine.MakeTornado;
if TMenuItem(Sender).Name='menudisasters_EARTHQUAKE' then FEngine.MakeEarthquake;
end;


{

procedure TMainWindow1.OnInvokeDisasterClicked(Disaster: TDisaster);
begin
  Dirty1 := True;
  case Disaster of
    dFire: FEngine.MakeFire;
    dFlood: FEngine.MakeFlood;
    dMonster: FEngine.MakeMonster;
    dMeltdown:
      if not FEngine.MakeMeltdown then
        FMessagesPane.AppendCityMessage(NO_NUCLEAR_PLANTS);
    dTornado: FEngine.MakeTornado;
    dEarthquake: FEngine.MakeEarthquake;
  else
    Assert(False, 'Unknown disaster');
  end;
end;

}

procedure TMainWindow1.ReloadFunds;
begin
  FundsLbl.Text := FormatFunds(FEngine.Budget.TotalFunds);
end;

// Implements Micropolis.Listener
procedure TMainWindow1.CityMessage(mmessage : TMicropolisMessage;loc : TCityLocation);
begin
  FMessagesPane.AppendCityMessage(mmessage);

  if UsesNotificationPane(mmessage) and (loc <> nil) then
    FNotificationPane.ShowMessage(FEngine, mmessage, loc.X, loc.Y);
end;

// Implements Micropolis.Listener
procedure TMainWindow1.FundsChanged;
begin
  ReloadFunds;
end;

// Implements Micropolis.Listener
procedure TMainWindow1.OptionsChanged;
begin
  ReloadOptions;
end;

procedure TMainWindow1.ReloadOptions;
var
  //spd: TSpeed;
  lvl: Integer;
  I:Integer;
begin
  AutoBudgetMenuItem.IsChecked := FEngine.AutoBudget;
  AutoBulldozeMenuItem.IsChecked := FEngine.AutoBulldoze;
  DisastersMenuItem.IsChecked := not FEngine.NoDisasters;
  SoundsMenuItem.IsChecked := DoSounds;

  for I := Low(PriorityMenuItems) to High(PriorityMenuItems) do
    begin
      PriorityMenuItems[i].IsChecked :=  (FEngine.SimSpeed = TSpeed(i));
    end;


 // for spd in PriorityMenuItems{.Keys} do
 //   {PriorityMenuItems[spd]}.IsChecked := (Engine.SimSpeed = spd);

  for lvl := GameLevel.MIN_LEVEL to GameLevel.Max_Level do
    DifficultyMenuItems[lvl].IsChecked := (FEngine.GameLevel = lvl);
end;

procedure TMainWindow1.CitySound(Sound: TSound; Loc: TCityLocation);
var
  AudioFile: string;
  IsOnScreen: Boolean;
  Clip: TMediaPlayer;
  TileRect: TRectF;
  ViewRect: TRectF;
begin
  if not DoSounds then Exit;

  AudioFile := Sound.GetAudioFile(Sound.GetSoundType);
  if AudioFile = '' then Exit;

  TileRect := FDrawingArea.GetTileBounds(Loc.X, Loc.Y);
  //ViewRect := DrawingAreaScroll.Viewport.ViewRect;
  IsOnScreen := True;//ViewRect.Contains(TileRect.TopLeft) and ViewRect.Contains(TileRect.BottomRight);

  if (Sound.GetSoundType = HONKHONK_LOW) and (not IsOnScreen) then Exit;

  try
    Clip := TMediaPlayer.Create(Self);
    try
      Clip.FileName := AudioFile;
      Clip.Play;
    except
      //on E: Exception do
        //OutputDebugString(PChar('Audio play error: ' + E.Message));
    end;
  finally
    Clip.Free;
  end;
end;

procedure TMainWindow1.CensusChanged;
begin
  // empty per Java code
end;

procedure TMainWindow1.DemandChanged;
begin
  // empty per Java code
end;

procedure TMainWindow1.EvaluationChanged;
begin
  // empty per Java code
end;

procedure TMainWindow1.OnViewBudgetClicked;
begin
  Dirty1 := True;
  ShowBudgetWindow(False);
end;

procedure TMainWindow1.OnViewEvaluationClicked;
begin
  FEvaluationPane.Visible := True;
end;

procedure TMainWindow1.OnViewGraphClicked;
begin
  FGraphsPane.Visible := True;
end;

procedure TMainWindow1.ShowAutoBudget;
begin
  if ToolStroke = nil then
    ShowBudgetWindow(True)
  else
    AutoBudgetPending := True;
end;

procedure TMainWindow1.ShowBudgetWindow(IsEndOfYear: Boolean);
var
  TimerWasActive: Boolean;
  Dlg: TBudgetDialog;
begin
  TimerWasActive := IsTimerActive;
  if TimerWasActive then
    StopTimer;

  Dlg := TBudgetDialog.CreateDialog(Self, FEngine);
  try
    Dlg.ShowModal;
  finally
    Dlg.Free;
  end;

  if TimerWasActive then
    StartTimer;
end;

function TMainWindow1.MakeMapStateMenuItem(const StringPrefix: string; State: TMapState): TMenuItem;
var
  Caption: string;
  MenuItem: TMenuItem;
begin
  Caption := Resources.GetGuiString(StringPrefix);
  MenuItem := TMenuItem.Create(Self);
  MenuItem.Text := Caption;
  SetupKeys(MenuItem, StringPrefix);
  MenuItem.Tag := Ord(State)+20;
  MenuItem.OnClick := SetMapState;
  MapStateMenuItems.Add(State, MenuItem);
  Result := MenuItem;
end;

procedure TMainWindow1.SetMapState(Sender:TObject);//(State: TMapState);
var State: TMapState;
begin
  State:=TMapState((Sender as TMenuItem).Tag - 20);
  SetMapState(State);
end;

procedure TMainWindow1.SetMapState(State: TMapState);
begin
  MapStateMenuItems[FMapView.MapState].IsChecked := False;
  MapStateMenuItems[State].IsChecked := True;
  FMapView.MapState := State;
  SetMapLegend(State);
end;

procedure TMainWindow1.SetMapLegend(State: TMapState);
var
  Key, IconName: string;
  IconUrl,S: string;
begin
  Key := 'legend_image.' + GetMapStateName(State);
  S :=Resources.GetGUIString(Key);
  if S<>'' then
    FMapLegendImage.Bitmap.LoadFromFile('./resources'+S)
  else
    FMapLegendImage.Bitmap := nil;

  // Optional: Update label text
  //FMapLegendLbl.Text := 'Legend: ' + GetEnumName(TypeInfo(TMapState), Ord(State));
end;

procedure TMainWindow1.OnLaunchTranslationToolClicked;
begin
  if MaybeSaveCity then
  begin
    Close;
    with TTranslationToolForm.Create(nil) do
      Show;
  end;
end;

procedure TMainWindow1.OnAboutClicked;
var
  Version, VersionStr: string;
  AppNameLbl, AppDetailsLbl: TLabel;
  MsgForm: TForm;
  Layout: TVertScrollBox;
begin
  Version := GetPackageVersion; // Youíll need a helper function to get package version
  VersionStr := Format(Resources.GetGuiString('main.version_string'), [Version]);
  //VersionStr := StringReplace(VersionStr, '%java.version%', GetJavaVersion, [rfReplaceAll]);
  //VersionStr := StringReplace(VersionStr, '%java.vendor%', GetJavaVendor, [rfReplaceAll]);

  MsgForm := TForm.Create(nil);
  try
    MsgForm.Caption := Resources.GetGuiString('main.about_caption');
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
    AppDetailsLbl.Text := Resources.GetGuiString('main.about_text');
    AppDetailsLbl.TextSettings.HorzAlign := TTextAlign.Center;
    AppDetailsLbl.Margins.Top := 8;

    MsgForm.ShowModal;
  finally
    MsgForm.Free;
  end;
end;

procedure TMainWindow1.HandleEarthquake; // Placeholder
begin
  //TODO
end;
procedure TMainWindow1.OnMicropolisEvent; // Placeholder
begin
  //TODO
end;

function TImageListHelper.Add(aBitmap: TBitmap): integer;
const
  SCALE = 1;
var
  vSource: TCustomSourceItem;
  vBitmapItem: TCustomBitmapItem;
  vDest: TCustomDestinationItem;
  vLayer: TLayer;
begin
  Result := -1;
  if (aBitmap.Width = 0) or (aBitmap.Height = 0) then exit;

  // add source bitmap
  vSource := Source.Add;
  vSource.MultiResBitmap.TransparentColor := TColorRec.Fuchsia;
  vSource.MultiResBitmap.SizeKind := TSizeKind.Source;
  vSource.MultiResBitmap.Width := Round(aBitmap.Width / SCALE);
  vSource.MultiResBitmap.Height := Round(aBitmap.Height / SCALE);
  vBitmapItem := vSource.MultiResBitmap.ItemByScale(SCALE, True, True);
  if vBitmapItem = nil then
  begin
    vBitmapItem := vSource.MultiResBitmap.Add;
    vBitmapItem.Scale := Scale;
  end;
  vBitmapItem.Bitmap.Assign(aBitmap);

  vDest := Destination.Add;
  vLayer := vDest.Layers.Add;
  vLayer.SourceRect.Rect := TRectF.Create(TPoint.Zero, vSource.MultiResBitmap.Width,
      vSource.MultiResBitmap.Height);
  vLayer.Name := vSource.Name;
  Result := vDest.Index;
end;







end.
