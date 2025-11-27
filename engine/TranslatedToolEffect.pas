// This file is part of MicropolisJ.
// Copyright (C) 2013 Jason Long
// Portions Copyright (C) 1989-2007 Electronic Arts Inc.
//
// MicropolisJ is free software; you can redistribute it and/or modify
// it under the terms of the GNU GPLv3, with additional terms.
// See the README file, included in this distribution, for details.

unit TranslatedToolEffect;

interface

uses
  ToolEffectIfc, // assumed unit defining IToolEffectIfc and related types
  Sound, ToolResult; // assumed units for Sound and ToolResult types

type
  TTranslatedToolEffect = class(TInterfacedObject, IToolEffectIfc)
  private
    FBase: IToolEffectIfc;
    Fdx: Integer;
    Fdy: Integer;
  public
    constructor Create(const base: IToolEffectIfc; dx, dy: Integer);

    // IToolEffectIfc methods
    function GetTile(x, y: Integer): Integer;
    procedure MakeSound(x, y: Integer; sound: TSound);
    procedure SetTile(x, y: Integer; tileValue: Integer);
    procedure Spend(amount: Integer);
    procedure ToolResult(tr: TToolResult);
  end;

implementation

constructor TTranslatedToolEffect.Create(const base: IToolEffectIfc; dx, dy: Integer);
begin
  inherited Create;
  FBase := base;
  Fdx := dx;
  Fdy := dy;
end;

function TTranslatedToolEffect.GetTile(x, y: Integer): Integer;
begin
  Result := FBase.GetTile(x + Fdx, y + Fdy);
end;

procedure TTranslatedToolEffect.MakeSound(x, y: Integer; sound: TSound);
begin
  FBase.MakeSound(x + Fdx, y + Fdy, sound);
end;

procedure TTranslatedToolEffect.SetTile(x, y: Integer; tileValue: Integer);
begin
  FBase.SetTile(x + Fdx, y + Fdy, tileValue);
end;

procedure TTranslatedToolEffect.Spend(amount: Integer);
begin
  FBase.Spend(amount);
end;

procedure TTranslatedToolEffect.ToolResult(tr: TToolResult);
begin
  FBase.ToolResult(tr);
end;

end.