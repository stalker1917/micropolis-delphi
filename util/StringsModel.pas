// This file is part of MicropolisJ.
// Copyright (C) 2013 Jason Long
// Portions Copyright (C) 1989-2007 Electronic Arts Inc.
//
// MicropolisJ is free software; you can redistribute it and/or modify
// it under the terms of the GNU GPLv3, with additional terms.
// See the README file, included in this distribution, for details.


unit StringsModel;

interface

uses
  System.SysUtils, System.Classes, System.Types,Generics.Collections, System.IOUtils;

type
  TStringInfo = record
    FileName: string;
    ID: string;
    constructor Create(const AFileName, AID: string);
  end;

  TMyLocaleInfo = class
    Code: string;
    PropsMap: TDictionary<string, TStringList>;
    Dirty: Boolean;
    constructor Create(const ACode: string);
    destructor Destroy; override;
  end;

  TStringsModel = class
  public
    const FILES: array[0..3] of string = (
      'CityMessages',
      'CityStrings',
      'GuiStrings',
      'StatusMessages'
    );
  private
    FStringList: TList<TStringInfo>;
    FLocales: TObjectList<TMyLocaleInfo>;
    FWorkingDirectory: string;
    procedure LoadStrings(const FileName: string; Dest: TList<TStringInfo>);
    function GetPFile(const FileName, LocaleCode: string): string;
    procedure MakeDirectories(const AFile: string);
  public
    constructor Create;
    destructor Destroy; override;

    procedure AddLocale(const LocaleCode: string);
    procedure RemoveLocale(const LocaleCode: string);
    procedure Save;
    function GetAllLocaleCodes: TArray<string>;
    function GetRowCount: Integer;
    function GetColumnCount: Integer;
    function GetValueAt(Row, Col: Integer): string;
    procedure SetValueAt(const AValue: string; Row, Col: Integer);

    property WorkingDirectory: string read FWorkingDirectory;
    property LocaleCount: Integer read GetColumnCount;
    property Strings: TList<TStringInfo> read FStringList;
    property Locales: TObjectList<TMyLocaleInfo> read FLocales;
  end;

implementation

{ TStringInfo }

constructor TStringInfo.Create(const AFileName, AID: string);
begin
  FileName := AFileName;
  ID := AID;
end;

{ TMyLocaleInfo }

constructor TMyLocaleInfo.Create(const ACode: string);
begin
  Code := ACode;
  PropsMap := TDictionary<string, TStringList>.Create;
  Dirty := False;
end;

destructor TMyLocaleInfo.Destroy;
var
  SL: TStringList;
begin
  for SL in PropsMap.Values do
    SL.Free;
  PropsMap.Free;
  inherited;
end;

{ TStringsModel }

constructor TStringsModel.Create;
var
  FileName: string;
begin
  FWorkingDirectory := TPath.Combine(TPath.GetDocumentsPath, 'micropolis-translations');
  FStringList := TList<TStringInfo>.Create;
  FLocales := TObjectList<TMyLocaleInfo>.Create(True);

  for FileName in FILES do
    LoadStrings(FileName, FStringList);
end;

destructor TStringsModel.Destroy;
begin
  FStringList.Free;
  FLocales.Free;
  inherited;
end;

procedure TStringsModel.LoadStrings(const FileName: string; Dest: TList<TStringInfo>);
var
  ResStream: TStream;
  SL: TStringList;
  I: Integer;
begin
  SL := TStringList.Create;
  try
    ResStream := TResourceStream.Create(HInstance, FileName, RT_RCDATA);
    try
      SL.LoadFromStream(ResStream);
    finally
      ResStream.Free;
    end;

    SL.Sort;
    for I := 0 to SL.Count - 1 do
      Dest.Add(TStringInfo.Create(FileName, SL.Names[I]));
  finally
    SL.Free;
  end;
end;

procedure TStringsModel.AddLocale(const LocaleCode: string);
var
  Locale: TMyLocaleInfo;
  FileName, FullPath: string;
  SL: TStringList;
begin
  Locale := TMyLocaleInfo.Create(LocaleCode);

  for FileName in FILES do
  begin
    SL := TStringList.Create;
    try
      // Load default resources (optional)
      // Here you'd load embedded resources if available

      FullPath := GetPFile(FileName, LocaleCode);
      if TFile.Exists(FullPath) then
        SL.LoadFromFile(FullPath);
    except
      on E: Exception do
        SL.Clear;
    end;
    Locale.PropsMap.Add(FileName, SL);
  end;

  FLocales.Add(Locale);
end;

procedure TStringsModel.RemoveLocale(const LocaleCode: string);
var
  I: Integer;
begin
  for I := FLocales.Count - 1 downto 0 do
    if FLocales[I].Code = LocaleCode then
      FLocales.Delete(I);
end;

procedure TStringsModel.Save;
var
  L: TMyLocaleInfo;
  FileName, FilePath: string;
  SL: TStringList;
begin
  for L in FLocales do
  begin
    if not L.Dirty then Continue;

    for FileName in FILES do
    begin
      if not L.PropsMap.TryGetValue(FileName, SL) then Continue;

      FilePath := GetPFile(FileName, L.Code);
      MakeDirectories(FilePath);
      SL.SaveToFile(FilePath);
    end;
    L.Dirty := False;
  end;
end;

function TStringsModel.GetPFile(const FileName, LocaleCode: string): string;
var
  Dir: string;
begin
  Dir := TPath.Combine(FWorkingDirectory, 'micropolisj');
  if not LocaleCode.IsEmpty then
    Result := TPath.Combine(Dir, Format('%s_%s.properties', [FileName, LocaleCode]))
  else
    Result := TPath.Combine(Dir, FileName + '.properties');
end;

procedure TStringsModel.MakeDirectories(const AFile: string);
var
  Dir: string;
begin
  Dir := TPath.GetDirectoryName(AFile);
  if not TDirectory.Exists(Dir) then
    TDirectory.CreateDirectory(Dir);
end;

function TStringsModel.GetAllLocaleCodes: TArray<string>;
var
  I: Integer;
begin
  SetLength(Result, FLocales.Count);
  for I := 0 to FLocales.Count - 1 do
    Result[I] := FLocales[I].Code;
end;

function TStringsModel.GetRowCount: Integer;
begin
  Result := FStringList.Count;
end;

function TStringsModel.GetColumnCount: Integer;
begin
  Result := FLocales.Count;
end;

function TStringsModel.GetValueAt(Row, Col: Integer): string;
var
  SI: TStringInfo;
  Locale: TMyLocaleInfo;
  Props: TStringList;
  Index: Integer;
begin
  SI := FStringList[Row];
  Locale := FLocales[Col];
  if Locale.PropsMap.TryGetValue(SI.FileName, Props) then
  begin
    Index := Props.IndexOfName(SI.ID);
    if Index <> -1 then
      Exit(Props.ValueFromIndex[Index]);
  end;
  Result := '';
end;

procedure TStringsModel.SetValueAt(const AValue: string; Row, Col: Integer);
var
  SI: TStringInfo;
  Locale: TMyLocaleInfo;
  Props: TStringList;
begin
  SI := FStringList[Row];
  Locale := FLocales[Col];
  if Locale.PropsMap.TryGetValue(SI.FileName, Props) then
  begin
    Props.Values[SI.ID] := AValue;
    Locale.Dirty := True;
  end;
end;

end.