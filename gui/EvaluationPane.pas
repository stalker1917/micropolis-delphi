unit EvaluationPane;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  FMX.Controls, FMX.Layouts, FMX.StdCtrls, FMX.Types, FMX.Objects,
  MicropolisUnit,SpriteCity,MicropolisMessage,
  CityLocation,Sound,CityProblem,System.TypInfo,System.Types;

type
  TEvaluationPane = class(TPanel, IListener)
  private
    FEngine: TMicropolis;
    FYesLbl: TLabel;
    FNoLbl: TLabel;
    FVoterProblemLbl: array[0..3] of TLabel;
    FVoterCountLbl: array[0..3] of TLabel;
    FPopLbl: TLabel;
    FDeltaLbl: TLabel;
    FAssessLbl: TLabel;
    FCityClassLbl: TLabel;
    FGameLevelLbl: TLabel;
    FScoreLbl: TLabel;
    FScoreDeltaLbl: TLabel;

    procedure OnDismissClicked(Sender: TObject);
    function MakePublicOpinionPane: TPanel;
    function MakeStatisticsPane: TPanel;
    procedure LoadEvaluation;
    function GetCityClassName(CityClass: Integer): string;
    function GetGameLevelName(GameLevel: Integer): string;
  public
    constructor Create(AEngine: TMicropolis); reintroduce;
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
  System.UITypes, System.Math, System.StrUtils;
  //Micropolis.Strings

{ TEvaluationPane }

constructor TEvaluationPane.Create(AEngine: TMicropolis);
var
  DismissBtn: TButton;
  MainLayout: TLayout;
  Separator: TLine;
begin
  inherited Create(nil);
  FEngine := AEngine;

  // Set up layout
  Align := TAlignLayout.Client;
  Margins.Rect := TRectF.Create(5, 5, 5, 5);

  // Dismiss button
  DismissBtn := TButton.Create(Self);
  DismissBtn.Parent := Self;
  DismissBtn.Align := TAlignLayout.Bottom;
  DismissBtn.Text := 'dismiss-evaluation';//Strings.Get('dismiss-evaluation');
  DismissBtn.OnClick := OnDismissClicked;

  // Main content area
  MainLayout := TLayout.Create(Self);
  MainLayout.Parent := Self;
  MainLayout.Align := TAlignLayout.Client;
  MainLayout.Margins.Bottom := 40;

  // Public opinion pane
  MainLayout.AddObject(MakePublicOpinionPane);

  // Separator
  Separator := TLine.Create(MainLayout);
  Separator.Parent := MainLayout;
  Separator.Align := TAlignLayout.Left;
  Separator.Width := 1;
  Separator.Margins.Left := 10;
  Separator.Margins.Right := 10;

  // Statistics pane
  MainLayout.AddObject(MakeStatisticsPane);

  if FEngine <> nil then
  begin
    FEngine.AddListener(Self);
    LoadEvaluation;
  end;
end;

procedure TEvaluationPane.SetEngine(NewEngine: TMicropolis);
begin
  if FEngine <> nil then
    FEngine.RemoveListener(Self);

  FEngine := NewEngine;

  if FEngine <> nil then
  begin
    FEngine.AddListener(Self);
    LoadEvaluation;
  end;
end;

procedure TEvaluationPane.OnDismissClicked(Sender: TObject);
begin
  Visible := False;
end;

function TEvaluationPane.MakePublicOpinionPane: TPanel;
var
  HeaderLbl, SubHeader1, SubHeader2: TLabel;
  YesTitleLbl, NoTitleLbl: TLabel;
  i: Integer;
begin
  Result := TPanel.Create(Self);
  Result.Align := TAlignLayout.Left;
  Result.Width := 250;

  // Header
  HeaderLbl := TLabel.Create(Result);
  HeaderLbl.Parent := Result;
  HeaderLbl.Align := TAlignLayout.Top;
  HeaderLbl.Text := 'public-opinion';//Strings.Get('public-opinion');
  HeaderLbl.StyledSettings := HeaderLbl.StyledSettings - [TStyledSetting.FontColor, TStyledSetting.Style];
  HeaderLbl.TextSettings.Font.Style := [TFontStyle.fsBold];
  HeaderLbl.TextSettings.Font.Size := HeaderLbl.TextSettings.Font.Size * 1.2;

  // Subheader 1
  SubHeader1 := TLabel.Create(Result);
  SubHeader1.Parent := Result;
  SubHeader1.Align := TAlignLayout.Top;
  SubHeader1.Margins.Top := 3;
  SubHeader1.Margins.Bottom := 3;
  SubHeader1.Text := 'public-opinion-1';//Strings.Get('public-opinion-1');

  // Yes/No labels
  YesTitleLbl := TLabel.Create(Result);
  YesTitleLbl.Parent := Result;
  YesTitleLbl.Align := TAlignLayout.Top;
  YesTitleLbl.Text := 'public-opinion-yes';//Strings.Get('public-opinion-yes');
  YesTitleLbl.Margins.Right := 4;
  YesTitleLbl.TextSettings.HorzAlign := TTextAlign.Trailing;

  FYesLbl := TLabel.Create(Result);
  FYesLbl.Parent := Result;
  FYesLbl.Align := TAlignLayout.Top;
  FYesLbl.Margins.Left := 4;
  FYesLbl.TextSettings.HorzAlign := TTextAlign.Leading;

  NoTitleLbl := TLabel.Create(Result);
  NoTitleLbl.Parent := Result;
  NoTitleLbl.Align := TAlignLayout.Top;
  NoTitleLbl.Text := 'public-opinion-no';//Strings.Get('public-opinion-no');
  NoTitleLbl.Margins.Right := 4;
  NoTitleLbl.TextSettings.HorzAlign := TTextAlign.Trailing;

  FNoLbl := TLabel.Create(Result);
  FNoLbl.Parent := Result;
  FNoLbl.Align := TAlignLayout.Top;
  FNoLbl.Margins.Left := 4;
  FNoLbl.TextSettings.HorzAlign := TTextAlign.Leading;

  // Subheader 2
  SubHeader2 := TLabel.Create(Result);
  SubHeader2.Parent := Result;
  SubHeader2.Align := TAlignLayout.Top;
  SubHeader2.Margins.Top := 3;
  SubHeader2.Margins.Bottom := 3;
  SubHeader2.Text := 'public-opinion-2';//Strings.Get('public-opinion-2');

  // Voter problem labels
  for i := 0 to 3 do
  begin
    FVoterProblemLbl[i] := TLabel.Create(Result);
    FVoterProblemLbl[i].Parent := Result;
    FVoterProblemLbl[i].Align := TAlignLayout.Top;
    FVoterProblemLbl[i].Margins.Right := 4;
    FVoterProblemLbl[i].TextSettings.HorzAlign := TTextAlign.Trailing;

    FVoterCountLbl[i] := TLabel.Create(Result);
    FVoterCountLbl[i].Parent := Result;
    FVoterCountLbl[i].Align := TAlignLayout.Top;
    FVoterCountLbl[i].Margins.Left := 4;
    FVoterCountLbl[i].TextSettings.HorzAlign := TTextAlign.Leading;
  end;

  // Add spacer at bottom
  var Spacer := TPanel.Create(Result);
  Spacer.Parent := Result;
  Spacer.Align := TAlignLayout.Client;
end;

function TEvaluationPane.MakeStatisticsPane: TPanel;
var
  HeaderLbl, Header2Lbl: TLabel;
  PopTitleLbl, DeltaTitleLbl, AssessTitleLbl, CityClassTitleLbl,
  GameLevelTitleLbl, ScoreTitleLbl, ScoreDeltaTitleLbl: TLabel;
begin
  Result := TPanel.Create(Self);
  Result.Align := TAlignLayout.Client;

  // Header
  HeaderLbl := TLabel.Create(Result);
  HeaderLbl.Parent := Result;
  HeaderLbl.Align := TAlignLayout.Top;
  HeaderLbl.Margins.Bottom := 3;
  HeaderLbl.Text := 'statistics-head';//Strings.Get('statistics-head');
  HeaderLbl.StyledSettings := HeaderLbl.StyledSettings - [TStyledSetting.FontColor, TStyledSetting.Style];
  HeaderLbl.TextSettings.Font.Style := [TFontStyle.fsBold];
  HeaderLbl.TextSettings.Font.Size := HeaderLbl.TextSettings.Font.Size * 1.2;

  // Population labels
  PopTitleLbl := TLabel.Create(Result);
  PopTitleLbl.Parent := Result;
  PopTitleLbl.Align := TAlignLayout.Top;
  PopTitleLbl.Text := 'stats-population';//Strings.Get('stats-population');
  PopTitleLbl.Margins.Right := 4;
  PopTitleLbl.TextSettings.HorzAlign := TTextAlign.Trailing;

  FPopLbl := TLabel.Create(Result);
  FPopLbl.Parent := Result;
  FPopLbl.Align := TAlignLayout.Top;
  FPopLbl.Margins.Left := 4;
  FPopLbl.TextSettings.HorzAlign := TTextAlign.Leading;

  // Delta labels
  DeltaTitleLbl := TLabel.Create(Result);
  DeltaTitleLbl.Parent := Result;
  DeltaTitleLbl.Align := TAlignLayout.Top;
  DeltaTitleLbl.Text := 'stats-net-migration';//Strings.Get('stats-net-migration');
  DeltaTitleLbl.Margins.Right := 4;
  DeltaTitleLbl.TextSettings.HorzAlign := TTextAlign.Trailing;

  FDeltaLbl := TLabel.Create(Result);
  FDeltaLbl.Parent := Result;
  FDeltaLbl.Align := TAlignLayout.Top;
  FDeltaLbl.Margins.Left := 4;
  FDeltaLbl.TextSettings.HorzAlign := TTextAlign.Leading;

  // Assessed value labels
  AssessTitleLbl := TLabel.Create(Result);
  AssessTitleLbl.Parent := Result;
  AssessTitleLbl.Align := TAlignLayout.Top;
  AssessTitleLbl.Text := 'stats-assessed-value';//Strings.Get('stats-assessed-value');
  AssessTitleLbl.Margins.Right := 4;
  AssessTitleLbl.TextSettings.HorzAlign := TTextAlign.Trailing;

  FAssessLbl := TLabel.Create(Result);
  FAssessLbl.Parent := Result;
  FAssessLbl.Align := TAlignLayout.Top;
  FAssessLbl.Margins.Left := 4;
  FAssessLbl.TextSettings.HorzAlign := TTextAlign.Leading;

  // City class labels
  CityClassTitleLbl := TLabel.Create(Result);
  CityClassTitleLbl.Parent := Result;
  CityClassTitleLbl.Align := TAlignLayout.Top;
  CityClassTitleLbl.Text :='stats-category';// Strings.Get('stats-category');
  CityClassTitleLbl.Margins.Right := 4;
  CityClassTitleLbl.TextSettings.HorzAlign := TTextAlign.Trailing;

  FCityClassLbl := TLabel.Create(Result);
  FCityClassLbl.Parent := Result;
  FCityClassLbl.Align := TAlignLayout.Top;
  FCityClassLbl.Margins.Left := 4;
  FCityClassLbl.TextSettings.HorzAlign := TTextAlign.Leading;

  // Game level labels
  GameLevelTitleLbl := TLabel.Create(Result);
  GameLevelTitleLbl.Parent := Result;
  GameLevelTitleLbl.Align := TAlignLayout.Top;
  GameLevelTitleLbl.Text := 'stats-game-level';//Strings.Get('stats-game-level');
  GameLevelTitleLbl.Margins.Right := 4;
  GameLevelTitleLbl.TextSettings.HorzAlign := TTextAlign.Trailing;

  FGameLevelLbl := TLabel.Create(Result);
  FGameLevelLbl.Parent := Result;
  FGameLevelLbl.Align := TAlignLayout.Top;
  FGameLevelLbl.Margins.Left := 4;
  FGameLevelLbl.TextSettings.HorzAlign := TTextAlign.Leading;

  // Second header
  Header2Lbl := TLabel.Create(Result);
  Header2Lbl.Parent := Result;
  Header2Lbl.Align := TAlignLayout.Top;
  Header2Lbl.Margins.Top := 9;
  Header2Lbl.Margins.Bottom := 3;
  Header2Lbl.Text := 'city-score-head';//Strings.Get('city-score-head');

  // Score labels
  ScoreTitleLbl := TLabel.Create(Result);
  ScoreTitleLbl.Parent := Result;
  ScoreTitleLbl.Align := TAlignLayout.Top;
  ScoreTitleLbl.Text := 'city-score-current';//Strings.Get('city-score-current');
  ScoreTitleLbl.Margins.Right := 4;
  ScoreTitleLbl.TextSettings.HorzAlign := TTextAlign.Trailing;

  FScoreLbl := TLabel.Create(Result);
  FScoreLbl.Parent := Result;
  FScoreLbl.Align := TAlignLayout.Top;
  FScoreLbl.Margins.Left := 4;
  FScoreLbl.TextSettings.HorzAlign := TTextAlign.Leading;

  // Score delta labels
  ScoreDeltaTitleLbl := TLabel.Create(Result);
  ScoreDeltaTitleLbl.Parent := Result;
  ScoreDeltaTitleLbl.Align := TAlignLayout.Top;
  ScoreDeltaTitleLbl.Text := 'city-score-change';//Strings.Get('city-score-change');
  ScoreDeltaTitleLbl.Margins.Right := 4;
  ScoreDeltaTitleLbl.TextSettings.HorzAlign := TTextAlign.Trailing;

  FScoreDeltaLbl := TLabel.Create(Result);
  FScoreDeltaLbl.Parent := Result;
  FScoreDeltaLbl.Align := TAlignLayout.Top;
  FScoreDeltaLbl.Margins.Left := 4;
  FScoreDeltaLbl.TextSettings.HorzAlign := TTextAlign.Leading;

  // Add spacer at bottom
  var Spacer := TPanel.Create(Result);
  Spacer.Parent := Result;
  Spacer.Align := TAlignLayout.Client;
end;

procedure TEvaluationPane.LoadEvaluation;
var
  i: Integer;
  P: TCityProblem;
  NumVotes: Integer;
   YesPct, NoPct,NumVt: Double;
begin
  if FEngine = nil then Exit;

  // Update public opinion
  YesPct := 0.01 * FEngine.Evaluation.CityYes;
  NoPct := 0.01 * FEngine.Evaluation.CityNo;
  FYesLbl.Text := FormatFloat('0.00%',YesPct); //  ('%.0f%%', [FEngine.Evaluation.CityYes]);
  FNoLbl.Text := FormatFloat('0.00%',NoPct);//Format('%.0f%%', [FEngine.Evaluation.CityNo]);

  // Update voter problems
  for i := 0 to 3 do
  begin
    if i < Length(FEngine.Evaluation.ProblemOrder) then
      P := FEngine.Evaluation.ProblemOrder[i]
    else
      P := cpCrime; // Default problem
    if FEngine.Evaluation.ProblemVotes.Count>Ord(P) then
      NumVotes := FEngine.Evaluation.ProblemVotes[P];

    if NumVotes <> 0 then
    begin
      NumVt:= 0.01 *NumVotes;
      FVoterProblemLbl[i].Text :='problem.'+GetEnumName(TypeInfo(TCityProblem), Ord(P));  //Strings.Get('problem.' + GetEnumName(TypeInfo(TCityProblem), Ord(P)));
      FVoterCountLbl[i].Text := FormatFloat('0',NumVt);//Format('%.0f%%', [NumVotes]);
      FVoterProblemLbl[i].Visible := True;
      FVoterCountLbl[i].Visible := True;
    end
    else
    begin
      FVoterProblemLbl[i].Visible := False;
      FVoterCountLbl[i].Visible := False;
    end;
  end;

  // Update statistics
  FPopLbl.Text := FormatFloat('#,##0', FEngine.Evaluation.CityPop);
  FDeltaLbl.Text := FormatFloat('#,##0', FEngine.Evaluation.DeltaCityPop);
  FAssessLbl.Text := FormatFloat('$#,##0', FEngine.Evaluation.CityAssValue);
  FCityClassLbl.Text := GetCityClassName(FEngine.Evaluation.CityClass);
  FGameLevelLbl.Text := GetGameLevelName(FEngine.GameLevel);
  FScoreLbl.Text := FormatFloat('#,##0', FEngine.Evaluation.CityScore);
  FScoreDeltaLbl.Text := FormatFloat('#,##0', FEngine.Evaluation.DeltaCityScore);
end;

function TEvaluationPane.GetCityClassName(CityClass: Integer): string;
begin
  Result := 'class.' + IntToStr(CityClass);//Strings.Get('class.' + IntToStr(CityClass));
end;

function TEvaluationPane.GetGameLevelName(GameLevel: Integer): string;
begin
  Result := 'level.' + IntToStr(GameLevel);//Strings.Get('level.' + IntToStr(GameLevel));
end;

{ IMicropolisListener implementation }

procedure TEvaluationPane.CityMessage(Message: TMicropolisMessage; Loc: TCityLocation);
begin
  // Not needed for evaluation pane
end;

procedure TEvaluationPane.CitySound(Sound: TSound; Loc: TCityLocation);
begin
  // Not needed for evaluation pane
end;

procedure TEvaluationPane.CensusChanged;
begin
  // Not needed for evaluation pane
end;

procedure TEvaluationPane.DemandChanged;
begin
  // Not needed for evaluation pane
end;

procedure TEvaluationPane.FundsChanged;
begin
  // Not needed for evaluation pane
end;

procedure TEvaluationPane.OptionsChanged;
begin
  // Not needed for evaluation pane
end;

procedure TEvaluationPane.EvaluationChanged;
begin
  LoadEvaluation;
  //TThread.Synchronize(
  //procedure
  //  begin
   //   LoadEvaluation;
   // end);
end;

end.
