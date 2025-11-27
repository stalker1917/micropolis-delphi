// This file is part of MicropolisJ.
// Copyright (C) 2013 Jason Long
// Portions Copyright (C) 1989-2007 Electronic Arts Inc.
//
// MicropolisJ is free software; you can redistribute it and/or modify
// it under the terms of the GNU GPLv3, with additional terms.
// See the README file, included in this distribution, for details.

unit TranslatedStringsTable;

interface

uses
  System.Classes, FMX.Types, FMX.Controls, FMX.Grid, FMX.StdCtrls, FMX.Edit;

type
  TTranslatedStringsTable = class(TStringGrid)
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

constructor TTranslatedStringsTable.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  // Enable editing
  //TGridOption.
  Options := Options + [TGridOption.Editing];

  // Set all columns (if any) to text editor - FMX TStringGrid uses TStringColumn by default
  // If you add columns dynamically, make sure to set their EditMode as needed

  // Optionally, you can customize the default editor for columns here
end;

end.