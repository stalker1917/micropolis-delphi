// This file is part of MicropolisJ.
// Copyright (C) 2013 Jason Long
// Portions Copyright (C) 1989-2007 Electronic Arts Inc.
//
// MicropolisJ is free software; you can redistribute it and/or modify
// it under the terms of the GNU GPLv3, with additional terms.
// See the README file, included in this distribution, for details.

unit BudgetDialog;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Forms, FMX.Controls, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Edit,
  FMX.Layouts, {FMX.TrackBar,} FMX.SpinBox, FMX.Types, MicropolisUnit,
  Speed,BudgetNumbers,Resources,FMX.Objects, CityBudget;

type
  //TMyBudgetForm = class(TLayout)

  //end;
  TBudgetDialog = class(TForm)

    procedure FormCreate(Sender: TObject);
    procedure OnValueChanged(Sender: TObject);
    procedure OnKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure BtnContinueClick(Sender: TObject);
    procedure BtnResetClick(Sender: TObject);
  private
    Engine: TMicropolis;
    OrigTaxRate: Integer;
    OrigRoadPct, OrigFirePct, OrigPolicePct: Double;
    procedure ApplyChange;
    procedure LoadBudgetNumbers(UpdateEntries: Boolean);
    function MakeBalancePane: TGridPanelLayout;
    function MakeTaxPane:  TGridPanelLayout;
    function MakeOptionsPane:  TGridPanelLayout;
   function MakeFundingRatesPane:  TGridPanelLayout;
  public
    LayoutMain: TVertScrollBox;
    PanelButtons: TPanel;
    BtnContinue: TButton;
    BtnReset: TButton;

    lblTaxRate: TLabel;
    spnTaxRate: TSpinBox;
    lblTaxRevenue: TLabel;

    trkRoadFund: TTrackBar;
    lblRoadRequest: TLabel;
    lblRoadAlloc: TLabel;

    trkPoliceFund: TTrackBar;
    lblPoliceRequest: TLabel;
    lblPoliceAlloc: TLabel;

    trkFireFund: TTrackBar;
    lblFireRequest: TLabel;
    lblFireAlloc: TLabel;

    chkAutoBudget: TCheckBox;
    chkPauseGame: TCheckBox;
    constructor CreateDialog(AOwner: TComponent; AEngine: TMicropolis); //reintroduce;
  end;

implementation

{$R *.fmx}

uses
  MainWindow;

procedure TBudgetDialog.OnKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
     if Key = vkEscape then
        Close;
end;

constructor TBudgetDialog.CreateDialog(AOwner: TComponent; AEngine: TMicropolis);
var
//MainLayout: TVertScrollBox;
Sep: TLine;
begin
  inherited Create(AOwner);
  Engine := AEngine;

  // Store original values
  OrigTaxRate := Engine.CityTax;
  OrigRoadPct := Engine.RoadPercent;
  OrigFirePct := Engine.FirePercent;
  OrigPolicePct := Engine.PolicePercent;

  // Form setup
  Caption :=  Resources.GetGuiString('budgetdlg.title');
  Width := 500;
  Height := 500;
  Position := TFormPosition.ScreenCenter;
  BorderStyle := TFmxFormBorderStyle.Sizeable;

  // Main layout
  LayoutMain := TVertScrollBox.Create(Self);
  LayoutMain.Parent := Self;
  LayoutMain.Align := TAlignLayout.Client;
  LayoutMain.Margins.Rect := TRectF.Create(8, 8, 8, 8);

  // Create controls
  LayoutMain.AddObject(MakeTaxPane);

  Sep := TLine.Create( LayoutMain);
  Sep.Parent :=  LayoutMain;
  Sep.Align := TAlignLayout.Top;
  Sep.Height := 1;
  Sep.Margins.Top := 8;
  Sep.Margins.Bottom := 8;

  LayoutMain.AddObject(MakeFundingRatesPane);

  Sep := TLine.Create(LayoutMain);
  Sep.Parent := LayoutMain;
  Sep.Align := TAlignLayout.Top;
  Sep.Height := 1;
  Sep.Margins.Top := 8;
  Sep.Margins.Bottom := 8;

  LayoutMain.AddObject(MakeBalancePane);

  Sep := TLine.Create(LayoutMain);
  Sep.Parent := LayoutMain;
  Sep.Align := TAlignLayout.Top;
  Sep.Height := 1;
  Sep.Margins.Top := 8;
  Sep.Margins.Bottom := 8;

  LayoutMain.AddObject(MakeOptionsPane);

  // Button panel
  var ButtonLayout := TFlowLayout.Create(Self);
  ButtonLayout.Parent := Self;
  ButtonLayout.Align := TAlignLayout.Bottom;
  ButtonLayout.Height := 40;
  ButtonLayout.Margins.Rect := TRectF.Create(8, 8, 8, 8);
  ButtonLayout.Padding.Rect := TRectF.Create(8, 4, 8, 4); // Equal padding around all buttons
  ButtonLayout.HorizontalGap := 12; // More spacing between buttons

  BtnContinue := TButton.Create(ButtonLayout);
  BtnContinue.Parent := ButtonLayout;
  BtnContinue.Text := Resources.GetGuiString('budgetdlg.continue');
  BtnContinue.Width := 200;
  BtnContinue.OnClick := BtnContinueClick;

  BtnReset := TButton.Create(ButtonLayout);
  //BtnReset.Align := TAlignLayout.None;
 // BtnReset.Position.X := BtnContinue.Position.X + BtnContinue.Width + 120;
  BtnReset.Parent := ButtonLayout;
  BtnReset.Text := Resources.GetGuiString('budgetdlg.reset');
  BtnReset.Width := 180;
  BtnReset.OnClick := BtnResetClick;

  // Initialize values
  LoadBudgetNumbers(True);

  // Handle Escape key
  //Self.OnKeyDown :=
  //  procedure
  // begin

  //  end;
end;
{
  inherited Create(AOwner);
  Engine := AEngine;
  OrigTaxRate := Engine.CityTax;
  OrigRoadPct := Engine.RoadPercent;
  OrigFirePct := Engine.FirePercent;
  OrigPolicePct := Engine.PolicePercent;

  spnTaxRate.Value := OrigTaxRate;
  trkRoadFund.Value := OrigRoadPct * 100;
  trkPoliceFund.Value := OrigPolicePct * 100;
  trkFireFund.Value := OrigFirePct * 100;

  chkAutoBudget.IsChecked := Engine.AutoBudget;
  chkPauseGame.IsChecked := Engine.SimSpeed = Paused;

  LoadBudgetNumbers(True);

  spnTaxRate.OnChange := OnValueChanged;
  trkRoadFund.OnChange := OnValueChanged;
  trkPoliceFund.OnChange := OnValueChanged;
  trkFireFund.OnChange := OnValueChanged;
}


procedure TBudgetDialog.FormCreate(Sender: TObject);
begin
  // Initialized via CreateDialog
end;

procedure TBudgetDialog.OnValueChanged(Sender: TObject);
begin
  ApplyChange;
end;

procedure TBudgetDialog.ApplyChange;
begin
  Engine.CityTax := Round(spnTaxRate.Value);
  Engine.RoadPercent := trkRoadFund.Value / 100.0;
  Engine.PolicePercent := trkPoliceFund.Value / 100.0;
  Engine.FirePercent := trkFireFund.Value / 100.0;
  LoadBudgetNumbers(False);
end;

procedure TBudgetDialog.LoadBudgetNumbers(UpdateEntries: Boolean);
var
  B: TBudgetNumbers;
begin
  B := Engine.GenerateBudget;

  if UpdateEntries then
  begin
    spnTaxRate.Value := B.TaxRate;
    trkRoadFund.Value := B.RoadPercent * 100;
    trkPoliceFund.Value := B.PolicePercent * 100;
    trkFireFund.Value := B.FirePercent * 100;
  end;

  lblTaxRevenue.Text := TMainWindow1.FormatFunds(B.TaxIncome);
  lblRoadRequest.Text := TMainWindow1.FormatFunds(B.RoadRequest);
  lblRoadAlloc.Text := TMainWindow1.FormatFunds(B.RoadFunded);

  lblPoliceRequest.Text := TMainWindow1.FormatFunds(B.PoliceRequest);
  lblPoliceAlloc.Text := TMainWindow1.FormatFunds(B.PoliceFunded);

  lblFireRequest.Text := TMainWindow1.FormatFunds(B.FireRequest);
  lblFireAlloc.Text := TMainWindow1.FormatFunds(B.FireFunded);
end;

procedure TBudgetDialog.BtnContinueClick(Sender: TObject);
begin
  if chkAutoBudget.IsChecked <> Engine.AutoBudget then
    Engine.ToggleAutoBudget;

  if chkPauseGame.IsChecked then
    Engine.SetSpeed(Paused)
  else
    Engine.SetSpeed(Normal);

  Close;
end;

procedure TBudgetDialog.BtnResetClick(Sender: TObject);
begin
  Engine.CityTax := OrigTaxRate;
  Engine.RoadPercent := OrigRoadPct;
  Engine.FirePercent := OrigFirePct;
  Engine.PolicePercent := OrigPolicePct;
  LoadBudgetNumbers(True);
end;

function TBudgetDialog.MakeBalancePane: TGridPanelLayout;
var
  BalancePane: TGridPanelLayout;
  Col, Row, i,j: Integer;
  ThLbl, LabelItem: TLabel;
  F, FPrior: TFinancialHistory;
  CapExpenses, CashFlow: Integer;
  HeadFontStyle: TFontStyle;
  // Left column labels
  procedure AddLeftLabel(const TextKey: string; RowIdx: Integer);
  var
    Lbl: TLabel;
    I:Integer;
  begin
    Lbl := TLabel.Create(Self);
    Lbl.Text := Resources.GetGuiString('TextKey');
    BalancePane.AddObject(Lbl);
    i:=BalancePane.ControlCollection.Count-1;
    BalancePane.ControlCollection[i].Column := 0;
    BalancePane.ControlCollection[i].Row := RowIdx;
  end;
begin
  BalancePane := TGridPanelLayout.Create(Self);
  BalancePane.Parent := Self;
  BalancePane.Align := TAlignLayout.Top;
  //BalancePane.Margins.SetBounds(24, 8, 24, 8);
  BalancePane.ColumnCollection.Clear;
  BalancePane.RowCollection.Clear;

  // Add columns (1 label column + up to 2 financial history columns)
  for Col := 0 to 2 do
  begin
    with BalancePane.ColumnCollection.Add do
    begin
      Value := 33.33;
      SizeStyle := TGridPanelLayout.TSizeStyle.Percent;
    end;
  end;

  // Add 6 rows
  for Row := 0 to 5 do
    with BalancePane.RowCollection.Add do
    begin
      Value := 16.67;
      SizeStyle := TGridPanelLayout.TSizeStyle.Percent;
    end;

  // Header Label
  ThLbl := TLabel.Create(Self);
  ThLbl.Text :=  Resources.GetGuiString('budgetdlg.period_ending');
  ThLbl.TextSettings.Font.Style := [TFontStyle.fsItalic];
  ThLbl.TextSettings.FontColor := TAlphaColorRec.Magenta;
  BalancePane.AddObject(ThLbl);
  i:=BalancePane.ControlCollection.Count-1;
  BalancePane.ControlCollection[i].Column := 0;
  BalancePane.ControlCollection[i].Row := 0;



begin
  AddLeftLabel('budgetdlg.cash_begin', 1);
  AddLeftLabel('budgetdlg.taxes_collected', 2);
  AddLeftLabel('budgetdlg.capital_expenses', 3);
  AddLeftLabel('budgetdlg.operating_expenses', 4);
  AddLeftLabel('budgetdlg.cash_end', 5);

  for i := 0 to 1 do
  begin
    if (i + 1) >= engine.FinancialHistory.Count then
      Break;

    F := engine.FinancialHistory[i];
    FPrior := engine.FinancialHistory[i + 1];
    CashFlow := F.TotalFunds - FPrior.TotalFunds;
    CapExpenses := -(CashFlow - F.TaxIncome + F.OperatingExpenses);

    // Column index for this history
    Col := i + 1;

    // Period ending label
    ThLbl := TLabel.Create(Self);
    ThLbl.Text := TMainWindow1.FormatGameDate(F.CityTime - 1);
    ThLbl.TextSettings.Font.Style := [TFontStyle.fsItalic];
    ThLbl.TextSettings.FontColor := TAlphaColorRec.Magenta;
    BalancePane.AddObject(ThLbl);
    j:=BalancePane.ControlCollection.Count-1;
    BalancePane.ControlCollection[j].Column := Col;
    BalancePane.ControlCollection[j].Row := 0;

    // Cash Begin
    LabelItem := TLabel.Create(Self);
    LabelItem.Text := TMainWindow1.FormatFunds(FPrior.TotalFunds);
    BalancePane.AddObject(LabelItem);
    j:=BalancePane.ControlCollection.Count-1;
    BalancePane.ControlCollection[j].Column := Col;
    BalancePane.ControlCollection[j].Row := 1;

    // Taxes Collected
    LabelItem := TLabel.Create(Self);
    LabelItem.Text := TMainWindow1.FormatFunds(F.TaxIncome);
    BalancePane.AddObject(LabelItem);
    j:=BalancePane.ControlCollection.Count-1;
    BalancePane.ControlCollection[j].Column := Col;
    BalancePane.ControlCollection[j].Row := 2;

    // Capital Expenses
    LabelItem := TLabel.Create(Self);
    LabelItem.Text := TMainWindow1.FormatFunds(CapExpenses);
    BalancePane.AddObject(LabelItem);
    j:=BalancePane.ControlCollection.Count-1;
    BalancePane.ControlCollection[j].Column := Col;
    BalancePane.ControlCollection[j].Row := 3;

    // Operating Expenses
    LabelItem := TLabel.Create(Self);
    LabelItem.Text := TMainWindow1.FormatFunds(F.OperatingExpenses);
    BalancePane.AddObject(LabelItem);
    j:=BalancePane.ControlCollection.Count-1;
    BalancePane.ControlCollection[j].Column := Col;
    BalancePane.ControlCollection[j].Row := 4;

    // Cash End
    LabelItem := TLabel.Create(Self);
    LabelItem.Text := TMainWindow1.FormatFunds(F.TotalFunds);
    BalancePane.AddObject(LabelItem);
    j:=BalancePane.ControlCollection.Count-1;
    BalancePane.ControlCollection[j].Column := Col;
    BalancePane.ControlCollection[j].Row := 5;
  end;
end;

  Result := BalancePane;
end;

function TBudgetDialog.MakeTaxPane:  TGridPanelLayout;
var
  GridPanel: TGridPanelLayout;
  i:Integer;
begin
  GridPanel := TGridPanelLayout.Create(Self);
  GridPanel.Align := TAlignLayout.Top; // or TAlignLayout.Top if you have other controls
  GridPanel.Height := Trunc(Self.Height * 0.15); // 50% of window height
  try
    // Setup columns (3 columns)
    GridPanel.ColumnCollection.BeginUpdate;
    try
      // Column 0 - 25% (labels)
      with GridPanel.ColumnCollection.Add do
      begin
        SizeStyle := TGridPanelLayout.TSizeStyle.Percent;
        Value := 25;
      end;
      // Column 1 - 25% (controls)
      with GridPanel.ColumnCollection.Add do
      begin
        SizeStyle := TGridPanelLayout.TSizeStyle.Percent;
        Value := 25;
      end;
      // Column 2 - 50% (values)
      with GridPanel.ColumnCollection.Add do
      begin
        SizeStyle := TGridPanelLayout.TSizeStyle.Percent;
        Value := 50;
      end;
    finally
      GridPanel.ColumnCollection.EndUpdate;
    end;

    // Setup rows (2 rows)
    GridPanel.RowCollection.BeginUpdate;
    try
      // Row 0 - Headers
      with GridPanel.RowCollection.Add do
      begin
        SizeStyle := TGridPanelLayout.TSizeStyle.Auto;
      end;
      // Row 1 - Content
      with GridPanel.RowCollection.Add do
      begin
        SizeStyle := TGridPanelLayout.TSizeStyle.Auto;
      end;
    finally
      GridPanel.RowCollection.EndUpdate;
    end;

    // Add controls
    // Row 0 - Headers
    var TaxHdr := TLabel.Create(GridPanel);
    TaxHdr.Parent := GridPanel;
    TaxHdr.Text := Resources.GetGuiString('budgetdlg.tax_rate_hdr');
    TaxHdr.TextAlign := TTextAlign.Trailing;
    TaxHdr.Align := TAlignLayout.Client;
    GridPanel.AddObject(TaxHdr);
    i:=GridPanel.ControlCollection.Count-1;
    GridPanel.ControlCollection[i].Column := 1;
    GridPanel.ControlCollection[i].Row := 0;

    var AnnualHdr := TLabel.Create(GridPanel);
    AnnualHdr.Parent := GridPanel;
    AnnualHdr.Text := Resources.GetGuiString('budgetdlg.annual_receipts_hdr');
    AnnualHdr.TextAlign := TTextAlign.Trailing;
    AnnualHdr.Align := TAlignLayout.Client;
    GridPanel.AddObject(AnnualHdr);
    i:=GridPanel.ControlCollection.Count-1;
    GridPanel.ControlCollection[i].Column := 2;
    GridPanel.ControlCollection[i].Row := 0;

    // Row 1 - Content
    var TaxLbl := TLabel.Create(GridPanel);
    TaxLbl.Parent := GridPanel;
    TaxLbl.Text := Resources.GetGuiString('budgetdlg.tax_revenue');
    TaxLbl.TextAlign := TTextAlign.Leading;
    TaxLbl.Align := TAlignLayout.Client;
    GridPanel.AddObject(TaxLbl);
    i:=GridPanel.ControlCollection.Count-1;
    GridPanel.ControlCollection[i].Column := 0;
    GridPanel.ControlCollection[i].Row := 1;

    spnTaxRate := TSpinBox.Create(GridPanel);
    spnTaxRate.Parent := GridPanel;
    spnTaxRate.Min := 0;
    spnTaxRate.Max := 20;
    spnTaxRate.Value := 7;
    spnTaxRate.OnChange := OnValueChanged;
    spnTaxRate.Align := TAlignLayout.Client;
    GridPanel.AddObject(spnTaxRate);
    i:=GridPanel.ControlCollection.Count-1;
    GridPanel.ControlCollection[i].Column := 1;
    GridPanel.ControlCollection[i].Row := 1;

    lblTaxRevenue := TLabel.Create(GridPanel);
    lblTaxRevenue.Parent := GridPanel;
    lblTaxRevenue.Text := '';
    lblTaxRevenue.TextAlign := TTextAlign.Trailing;
    lblTaxRevenue.Align := TAlignLayout.Client;
    GridPanel.AddObject(lblTaxRevenue);
    i:=GridPanel.ControlCollection.Count-1;
    GridPanel.ControlCollection[i].Column := 2;
    GridPanel.ControlCollection[i].Row := 1;

    // Margins
    GridPanel.Margins.Bottom := 8;
  except
    GridPanel.Free;
    raise;
  end;
  Result := GridPanel;
end;



function TBudgetDialog.MakeOptionsPane:  TGridPanelLayout;
var
  FlowPanel: TGridPanelLayout;
begin
  FlowPanel := TGridPanelLayout.Create(Self);
  try
    FlowPanel.Margins.Top := 8;
    FlowPanel.Align := TAlignLayout.Top;
    //FlowPanel.HorizontalSpacing := 10;

    chkAutoBudget := TCheckBox.Create(FlowPanel);
    chkAutoBudget.Parent := FlowPanel;
    chkAutoBudget.Text := Resources.GetGuiString('budgetdlg.auto_budget');
    chkAutoBudget.Align := TAlignLayout.Client;
    chkAutoBudget.IsChecked := Engine.AutoBudget;
    chkAutoBudget.Width := 150;

    chkPauseGame := TCheckBox.Create(FlowPanel);
    chkPauseGame.Parent := FlowPanel;
    chkPauseGame.Text := Resources.GetGuiString('budgetdlg.pause_game');
    chkPauseGame.Align := TAlignLayout.Client;
    chkPauseGame.IsChecked := (Engine.SimSpeed = TSpeed.Paused);
    chkPauseGame.Width := 150;
  except
    FlowPanel.Free;
    raise;
  end;
  Result := FlowPanel;
end;



function TBudgetDialog.MakeFundingRatesPane:  TGridPanelLayout;
var
  GridPanel: TGridPanelLayout;
  I: Integer;
  ColumnWidth : Single;
begin
  GridPanel := TGridPanelLayout.Create(Self);
  GridPanel.Align := TAlignLayout.Top; // or TAlignLayout.Top if you have other controls
  GridPanel.Height := Trunc(Self.Height * 0.3); // 50% of window height
  try
    // Setup columns (4 columns)
    GridPanel.ColumnCollection.BeginUpdate;
    try
      // Column 0 - 25% (labels)
      with GridPanel.ColumnCollection.Add do
      begin
        SizeStyle := TGridPanelLayout.TSizeStyle.Percent;
        Value := 25;
      end;
      // Column 1 - 25% (sliders)
      with GridPanel.ColumnCollection.Add do
      begin
        SizeStyle := TGridPanelLayout.TSizeStyle.Percent;
        Value := 25;
      end;
      // Column 2 - 25% (requested)
      with GridPanel.ColumnCollection.Add do
      begin
        SizeStyle := TGridPanelLayout.TSizeStyle.Percent;
        Value := 25;
      end;
      // Column 3 - 25% (allocated)
      with GridPanel.ColumnCollection.Add do
      begin
        SizeStyle := TGridPanelLayout.TSizeStyle.Percent;
        Value := 25;
      end;
    finally
      GridPanel.ColumnCollection.EndUpdate;
    end;

    // Setup rows (4 rows)
    GridPanel.RowCollection.BeginUpdate;
    try
      // Header row
      with GridPanel.RowCollection.Add do
      begin
        SizeStyle := TGridPanelLayout.TSizeStyle.Auto;
      end;
      // 3 content rows
      for I := 1 to 3 do
        with GridPanel.RowCollection.Add do
        begin
          SizeStyle := TGridPanelLayout.TSizeStyle.Auto;
        end;
    finally
      GridPanel.RowCollection.EndUpdate;
    end;

    // Add headers
    var FundingHdr := TLabel.Create(GridPanel);
    FundingHdr.Parent := GridPanel;
    FundingHdr.Text := Resources.GetGuiString('budgetdlg.funding_level_hdr');
    FundingHdr.TextAlign := TTextAlign.Trailing;
    FundingHdr.Align := TAlignLayout.Client; // Fill the entire cell
    FundingHdr.Trimming := TTextTrimming.None;
    FundingHdr.WordWrap := True;
    FundingHdr.VertTextAlign := TTextAlign.Center;
    FundingHdr.Margins.Rect := TRectF.Create(2, 2, 2, 2); // Small margins

    GridPanel.AddObject(FundingHdr);
    i := GridPanel.ControlCollection.Count - 1;
    GridPanel.ControlCollection[i].Column := 1;
    GridPanel.ControlCollection[i].Row := 0;


    var RequestedHdr := TLabel.Create(GridPanel);
    RequestedHdr.Parent := GridPanel;

    RequestedHdr.Text :=  Resources.GetGuiString('budgetdlg.requested_hdr');
    RequestedHdr.TextAlign := TTextAlign.Trailing;
    RequestedHdr.Align := TAlignLayout.Client;
    GridPanel.AddObject(RequestedHdr);
    i:=GridPanel.ControlCollection.Count-1;
    GridPanel.ControlCollection[i].Column := 2;
    GridPanel.ControlCollection[i].Row := 0;

    var AllocHdr := TLabel.Create(GridPanel);
    AllocHdr.Parent := GridPanel;
    AllocHdr.Text :=  Resources.GetGuiString('budgetdlg.allocation_hdr');
    AllocHdr.TextAlign := TTextAlign.Trailing;
    AllocHdr.Align := TAlignLayout.Client;
    GridPanel.AddObject(AllocHdr);
    i:=GridPanel.ControlCollection.Count-1;
    GridPanel.ControlCollection[i].Column := 3;
    GridPanel.ControlCollection[i].Row := 0;

    // Road Fund Row
    var RoadLbl := TLabel.Create(GridPanel);
    RoadLbl.Parent := GridPanel;
    RoadLbl.Text :=  Resources.GetGuiString('budgetdlg.road_fund');
    RoadLbl.TextAlign := TTextAlign.Leading;
    RoadLbl.Align := TAlignLayout.Client;
    GridPanel.AddObject(RoadLbl);
    i:=GridPanel.ControlCollection.Count-1;
    GridPanel.ControlCollection[i].Column := 0;
    GridPanel.ControlCollection[i].Row := 1;

    trkRoadFund := TTrackBar.Create(GridPanel);
    trkRoadFund.Parent := GridPanel;
    trkRoadFund.Min := 0;
    trkRoadFund.Max := 100;
    trkRoadFund.Value := 100;
    trkRoadFund.OnChange := OnValueChanged;
    trkRoadFund.Align := TAlignLayout.Client;
    GridPanel.AddObject(trkRoadFund);
    i:=GridPanel.ControlCollection.Count-1;
    GridPanel.ControlCollection[i].Column := 1;
    GridPanel.ControlCollection[i].Row := 1;

    lblRoadRequest := TLabel.Create(GridPanel);
    lblRoadRequest.Parent := GridPanel;
    lblRoadRequest.Text := '';
    lblRoadRequest.TextAlign := TTextAlign.Trailing;
    lblRoadRequest.Align := TAlignLayout.Client;
    GridPanel.AddObject(lblRoadRequest);
    i:=GridPanel.ControlCollection.Count-1;
    GridPanel.ControlCollection[i].Column := 2;
    GridPanel.ControlCollection[i].Row := 1;

    lblRoadAlloc := TLabel.Create(GridPanel);
    lblRoadAlloc.Parent := GridPanel;
    lblRoadAlloc.Text := '';
    lblRoadAlloc.TextAlign := TTextAlign.Trailing;
    lblRoadAlloc.Align := TAlignLayout.Client;
    GridPanel.AddObject(lblRoadAlloc);
    i:=GridPanel.ControlCollection.Count-1;
    GridPanel.ControlCollection[i].Column := 3;
    GridPanel.ControlCollection[i].Row := 1;

    // Police Fund Row (Row 2)
var PoliceLbl := TLabel.Create(GridPanel);
PoliceLbl.Parent := GridPanel;
PoliceLbl.Text :=  Resources.GetGuiString('budgetdlg.police_fund');
PoliceLbl.Align := TAlignLayout.Client;
PoliceLbl.TextAlign := TTextAlign.Leading;
GridPanel.AddObject(PoliceLbl);
i:=GridPanel.ControlCollection.Count-1;
GridPanel.ControlCollection[i].Column := 0;
GridPanel.ControlCollection[i].Row := 2;

trkPoliceFund := TTrackBar.Create(GridPanel);
trkPoliceFund.Parent := GridPanel;
trkPoliceFund.Min := 0;
trkPoliceFund.Max := 100;
trkPoliceFund.Value := 100;
trkPoliceFund.Align := TAlignLayout.Client;
trkPoliceFund.OnChange := OnValueChanged;
GridPanel.AddObject(trkPoliceFund);
i:=GridPanel.ControlCollection.Count-1;
GridPanel.ControlCollection[i].Column := 1;
GridPanel.ControlCollection[i].Row := 2;

lblPoliceRequest := TLabel.Create(GridPanel);
lblPoliceRequest.Parent := GridPanel;
lblPoliceRequest.Text := '';
lblPoliceRequest.TextAlign := TTextAlign.Trailing;
lblPoliceRequest.Align := TAlignLayout.Client;
GridPanel.AddObject(lblPoliceRequest);
i:=GridPanel.ControlCollection.Count-1;
GridPanel.ControlCollection[i].Column := 2;
GridPanel.ControlCollection[i].Row := 2;

lblPoliceAlloc := TLabel.Create(GridPanel);
lblPoliceAlloc.Parent := GridPanel;
lblPoliceAlloc.Text := '';
lblPoliceAlloc.TextAlign := TTextAlign.Trailing;
lblPoliceAlloc.Align := TAlignLayout.Client;
GridPanel.AddObject(lblPoliceAlloc);
i:=GridPanel.ControlCollection.Count-1;
GridPanel.ControlCollection[i].Column := 3;
GridPanel.ControlCollection[i].Row := 2;

// Fire Fund Row (Row 3)
var FireLbl := TLabel.Create(GridPanel);
FireLbl.Parent := GridPanel;
FireLbl.Text :=  Resources.GetGuiString('budgetdlg.fire_fund');
FireLbl.Align := TAlignLayout.Client;
FireLbl.TextAlign := TTextAlign.Leading;
GridPanel.AddObject(FireLbl);
i:=GridPanel.ControlCollection.Count-1;
GridPanel.ControlCollection[i].Column := 0;
GridPanel.ControlCollection[i].Row := 3;

trkFireFund := TTrackBar.Create(GridPanel);
trkFireFund.Parent := GridPanel;
trkFireFund.Min := 0;
trkFireFund.Max := 100;
trkFireFund.Value := 100;
trkFireFund.Align := TAlignLayout.Client;
trkFireFund.OnChange := OnValueChanged;

GridPanel.AddObject(trkFireFund);
i:=GridPanel.ControlCollection.Count-1;
GridPanel.ControlCollection[i].Column := 1;
GridPanel.ControlCollection[i].Row := 3;

lblFireRequest := TLabel.Create(GridPanel);
lblFireRequest.Parent := GridPanel;
lblFireRequest.Text := '';
lblFireRequest.TextAlign := TTextAlign.Trailing;
lblFireRequest.Align := TAlignLayout.Client;
GridPanel.AddObject(lblFireRequest);
i:=GridPanel.ControlCollection.Count-1;
GridPanel.ControlCollection[i].Column := 2;
GridPanel.ControlCollection[i].Row := 3;

lblFireAlloc := TLabel.Create(GridPanel);
lblFireAlloc.Parent := GridPanel;
lblFireAlloc.Text := '';
lblFireAlloc.TextAlign := TTextAlign.Trailing;
lblFireAlloc.Align := TAlignLayout.Client;
GridPanel.AddObject(lblFireAlloc);
i:=GridPanel.ControlCollection.Count-1;
GridPanel.ControlCollection[i].Column := 3;
GridPanel.ControlCollection[i].Row := 3;

    // Margins
    GridPanel.Margins.Top := 8;
    GridPanel.Margins.Bottom := 8;
  // GridPanel.Padding.Rect := TRectF.Create(8, 4, 8, 4);
  except
    GridPanel.Free;
    raise;
  end;
  Result := GridPanel;
end;

end.