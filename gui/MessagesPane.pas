// This file is part of MicropolisJ.
// Copyright (C) 2013 Jason Long
// Portions Copyright (C) 1989-2007 Electronic Arts Inc.
//
// MicropolisJ is free software; you can redistribute it and/or modify
// it under the terms of the GNU GPLv3, with additional terms.
// See the README file, included in this distribution, for details.

unit MessagesPane;

interface

uses
  System.SysUtils, System.Classes, FMX.Types, FMX.Controls, FMX.StdCtrls, FMX.Memo,
  System.Generics.Collections,MicropolisMessage,System.TypInfo,Resources;

  //TMicropolisMessage = (mmSomeMessage1, mmSomeMessage2); // Example, replace with your actual enum

type
  TMessagesPane = class(TMemo)
  private
    class var
      FCityMessageStrings: TStringList;
    class constructor Create;
    class destructor Destroy;
  public
    constructor Create(AOwner: TComponent); override;
    procedure AppendCityMessage(Message: TMicropolisMessage);
    procedure AppendMessageText(const MessageText: string);
  end;

implementation

uses
  System.IOUtils;

{ TMessagesPane }

class constructor TMessagesPane.Create;
begin
  // Load city message strings from resource file
  FCityMessageStrings := TStringList.Create;
  try
  //  FCityMessageStrings.LoadFromFile(
   //   TPath.Combine(TPath.GetDocumentsPath, 'CityMessages.txt'),
    //  TEncoding.UTF8);
  except
    // Handle error if file not found
    on E: EFileNotFoundException do
      FCityMessageStrings.Add('Messages not available');
  end;
end;

class destructor TMessagesPane.Destroy;
begin
  FCityMessageStrings.Free;
end;

constructor TMessagesPane.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ReadOnly := True;
  WordWrap := True;
  HitTest := False; // Make non-interactive
end;

procedure TMessagesPane.AppendCityMessage(Message: TMicropolisMessage);
var
  MessageKey: string;
begin
  MessageKey := GetEnumName(TypeInfo(TMicropolisMessage), Ord(Message));
  AppendMessageText(Resources.CityMessages.ReadString('',MessageKey,''));//FCityMessageStrings.Values[MessageKey]);
end;

procedure TMessagesPane.AppendMessageText(const MessageText: string);
begin
  if Text <> '' then
    Text := Text + sLineBreak + MessageText
  else
    Text := MessageText;

  // Auto-scroll to bottom
  SelStart := Text.Length;
  Repaint;
end;

end.

end.