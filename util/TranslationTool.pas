// This file is part of MicropolisJ.
// Copyright (C) 2013 Jason Long
// Portions Copyright (C) 1989-2007 Electronic Arts Inc.
//
// MicropolisJ is free software; you can redistribute it and/or modify
// it under the terms of the GNU GPLv3, with additional terms.
// See the README file, included in this distribution, for details.

unit TranslationTool;

interface

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Grid.Style, FMX.ScrollBox, FMX.Grid, FMX.Layouts,
  StringsModel,Math,System.StrUtils; // your Delphi port of StringsModel

type
  TTranslationToolForm = class(TForm)
    StringGrid: TStringGrid;
    PanelBottom: TLayout;
    btnAddLocale: TButton;
    btnRemoveLocale: TButton;
    btnTest: TButton;
    btnSubmit: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnAddLocaleClick(Sender: TObject);
    procedure btnRemoveLocaleClick(Sender: TObject);
    procedure btnTestClick(Sender: TObject);
    procedure btnSubmitClick(Sender: TObject);
  private
    StringsModel: TStringsModel;
    procedure UpdateButtons;
    procedure MaybeSave;
    function PickLocale(const AMessage, ATitle: string): string;
    function GetJavaPath: string;
    function GetJarPath: string;
  public
  end;

implementation

//{$R *.fmx}

uses
  System.IOUtils, FMX.Edit, FMX.DialogService.Async;

procedure TTranslationToolForm.FormCreate(Sender: TObject);
begin
  Caption := 'MicropolisJ Translation Tool';
  StringsModel := TStringsModel.Create;
  try
    StringsModel.AddLocale('');
  except
    on E: Exception do
    begin
      ShowMessage('Error loading locales: ' + E.Message);
      Application.Terminate;
      Exit;
    end;
  end;
  // Prepare StringGrid
  StringGrid.RowCount := Max(1, Length(StringsModel.GetAllLocaleCodes));
  // Add new columns
  StringGrid.AddObject(TStringColumn.Create(nil)); // Column 0
  StringGrid.AddObject(TStringColumn.Create(nil)); // Column 1
 // StringGrid.ColumnCount := 2; // Key + latest locale
  UpdateButtons;
end;

procedure TTranslationToolForm.UpdateButtons;
begin
  btnRemoveLocale.Enabled := StringsModel.LocaleCount > 1;
  btnTest.Enabled := btnRemoveLocale.Enabled;
  btnSubmit.Enabled := btnRemoveLocale.Enabled;
end;

procedure TTranslationToolForm.MaybeSave;
begin
  try
    StringsModel.Save;
  except
    on E: Exception do
      ShowMessage('Error saving translations: ' + E.Message);
  end;
end;

function TTranslationToolForm.PickLocale(const AMessage, ATitle: string): string;
var
  Code: string;
  Items: TArray<string>;
begin
  Items := StringsModel.GetAllLocaleCodes;
  if Length(Items) = 0 then
    Exit('');
  if Length(Items) = 1 then
    Exit(Items[0]);

  // Prompt using FMX dialog
  if InputQuery(ATitle, AMessage + sLineBreak + 'Available: ' + String.Join(', ', Items), Code) then
    if Code.Trim.IsEmpty {or (not StringsModel.LocaleExists(Code.Trim))} then
      Exit('')
    else
      Exit(Code.Trim);
  Result := '';
end;

procedure TTranslationToolForm.btnAddLocaleClick(Sender: TObject);
var
  Lang, Country, Variant, Code: string;
begin
  MaybeSave;
  if not InputQuery('Add Locale', 'Language:', Lang) or Lang.Trim.IsEmpty then Exit;
  InputQuery('Add Locale', 'Country (optional):', Country);
  InputQuery('Add Locale', 'Variant (optional):', Variant);
  if (Country.Trim.IsEmpty) and not Variant.Trim.IsEmpty then
    ShowMessage('Cannot specify variant without country.')
  else
  begin
    Code := Lang;
    if Country <> '' then Code := Code + '_' + Country;
    if Variant <> '' then Code := Code + '_' + Variant;
    StringsModel.AddLocale(Code);
    UpdateButtons;
  end;
end;

procedure TTranslationToolForm.btnRemoveLocaleClick(Sender: TObject);
var
  Code: string;
begin
  MaybeSave;
  Code := PickLocale('Select locale to remove:', 'Remove Locale');
  if Code <> '' then
  begin
    StringsModel.RemoveLocale(Code);
    UpdateButtons;
  end;
end;

procedure TTranslationToolForm.btnTestClick(Sender: TObject);
var
  Code, FLang, FCountry, FVariant, Cmd: string;
  LocaleParts: TArray<string>;
begin
  MaybeSave;
  Code := PickLocale('Which locale do you want to test?', 'Test Locale');
  if Code = '' then Exit;

  LocaleParts := SplitString(Code, '_');

  if Length(LocaleParts) >= 1 then
     FLang := LocaleParts[0];
  if Length(LocaleParts) >= 2 then
    FCountry := LocaleParts[1];
  if Length(LocaleParts) >= 3 then
    FVariant := LocaleParts[2];

  
  Cmd := Format('"%s" -Duser.language=%s -Duser.country=%s -Duser.variant=%s -cp "%s;%s" micropolisj.Main',
    [GetJavaPath, FLang, FCountry, FVariant, StringsModel.WorkingDirectory, GetJarPath]);
  
 // if TFile.Exists(GetJavaPath) then
 //   WinApi.ShellAPI.ShellExecute(0, 'open', PChar(GetJavaPath),
  //    PChar(Cmd), nil, SW_SHOWNORMAL)
 // else
 //  ShowMessage('Java executable not found.');
end;

procedure TTranslationToolForm.btnSubmitClick(Sender: TObject);
var
  Code, Msg: string;
  FileName: string;
begin
  MaybeSave;
  Code := PickLocale('Which locale to submit?', 'Submit Locale');
  if Code = '' then Exit;

  Msg := 'Translated strings saved to:' + sLineBreak +
         TPath.Combine(StringsModel.WorkingDirectory, 'micropolisj') + sLineBreak +
         'Files:' + sLineBreak;
  for FileName in StringsModel.Files do
    Msg := Msg + ' * ' + FileName + '_' + Code + '.properties' + sLineBreak;
  Msg := Msg + sLineBreak + 'Submit these via issue to the Micropolis site.';
  ShowMessage(Msg);
end;

function TTranslationToolForm.GetJavaPath: string;
begin
  Result := TPath.Combine(GetEnvironmentVariable('JAVA_HOME'), 'bin\java');
end;

function TTranslationToolForm.GetJarPath: string;
begin
  Result := TPath.Combine(ExtractFilePath(ParamStr(0)), 'micropolisj.jar');
end;

end.