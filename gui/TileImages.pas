// This file is part of MicropolisJ.
// Copyright (C) 2013 Jason Long
// Portions Copyright (C) 1989-2007 Electronic Arts Inc.
//
// MicropolisJ is free software; you can redistribute it and/or modify
// it under the terms of the GNU GPLv3, with additional terms.
// See the README file, included in this distribution, for details.

unit TileImages;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.Types,
  FMX.Graphics, FMX.Types, Xml.XMLIntf, TileImage, TileSpec, SpriteKind,
  Tiles,TileConstants,Xml.XMLDoc;

type
 // TTileImages = class;
  TTileImages = class
  private
    FName: string;
    FTileWidth: Integer;
    FTileHeight: Integer;
    FTileImageMap: TArray<TTileImage>;
    FSpriteImages: TDictionary<TSpriteKindInfo, TDictionary<Integer, TBitmap>>;
    FSubImageCache: TDictionary<TBitmap, TDictionary<TRect, TBitmap>>;

    type
      TMyLoaderContext = class(TInterfacedObject, ILoaderContext)
      private
        FParent: TTileImages;
        FImages: TDictionary<string, TSourceImage>;
      public
        constructor Create(AParent: TTileImages);
        function GetDefaultImage: TSourceImage;
        function GetImage(const FileName: string): TSourceImage;
        function ParseFrameSpec(const Tmp: string): TTileImage;
      end;


    procedure InitTileImageMap;
    procedure LoadSpriteImages;
    function LoadSpriteImage(Kind: TSpriteKindInfo; FrameNo: Integer): TBitmap;

    class function LoadImage(const ResourceName: string; BasisSize: Integer): TSourceImage;
  public
     type
    TImageInfo = class
      private
        FParent: TTileImages;
        FImage: TSimpleTileImage;
        FAnimated: Boolean;
      public
        constructor Create(AImage: TSimpleTileImage; AAnimated: Boolean;AParent: TTileImages);
        function IsAnimated: Boolean;
        procedure DrawTo(Canvas: TCanvas; DestX, DestY: Single);
        function GetImage: TBitmap;
        property Image: TSimpleTileImage read FImage;
        property Animated: Boolean read FAnimated;
      end;

    constructor Create(const AName: string; ASize: Integer);
    function GetResourceName: string;
    function GetTileImageInfo(TileNumber: Integer; ACycle: Integer = 0): TImageInfo;
    function GetTileImage(Tile: Integer): TBitmap;
    function GetSpriteImage(Kind: TSpriteKind; FrameNumber: Integer): TBitmap;
    function CacheSubImage(Bi: TBitmap; Rect: TRect): TBitmap;

    class function GetInstance(ASize: Integer): TTileImages; overload;
    class function GetInstance(const AName: string; ASize: Integer): TTileImages; overload;

    property Name: string read FName;
    property TileWidth: Integer read FTileWidth;
    property TileHeight: Integer read FTileHeight;
  end;

implementation

uses
  System.IOUtils, System.StrUtils, System.Math, XML_Helper;

var
  GSavedInstances: TDictionary<Integer, TTileImages>;

{ TTileImages }

constructor TTileImages.Create(const AName: string; ASize: Integer);
begin
  inherited Create;
  FName := AName;
  FTileWidth := ASize;
  FTileHeight := ASize;
  FSubImageCache := TDictionary<TBitmap, TDictionary<TRect, TBitmap>>.Create;
  InitTileImageMap;
end;

function TTileImages.GetResourceName: string;
begin
  Result := '/' + FName + '/tiles.png';
end;

procedure TTileImages.InitTileImageMap;
var
  Ctx: ILoaderContext;
  InStream: TStream;
  //InReader: IXMLDocument;
  ResourceName, TagName, TileName: string;
  Img: TTileImage;
  Ts: TTileSpec;
  XMLDoc: IXMLDocument;
  RootNode: IXMLNode;
  i:INteger;
begin
  if FSpriteImages <> nil then
    Exit; // already loaded

  Ctx := TMyLoaderContext.Create(Self);
  XMLDoc := TXMLDocument.Create(nil);
  XMLDoc.Options :=  XMLDoc.Options- [doAttrNull];
  try
    SetLength(FTileImageMap, TTiles.GetTileCount);
    ResourceName := GetCurrentDir+'/' +'sm' {FName} + '/tiles.idx';   //Временное решение

    // Load from resources
   // InStream := TResourceStream.Create(HInstance, ResourceName, RT_RCDATA);
     //try
      XMLDoc.LoadFromFile( ResourceName);
      XMLDoc.Active := True;

      try
      RootNode := XMLDoc.DocumentElement;
       // if not InReader.MoveToElement then
       //   raise Exception.Create('Unrecognized file format');

        for i:=0 to RootNode.ChildNodes.Count -1 do
        begin
          TagName := RootNode.ChildNodes[i].LocalName;
          if not SameText(TagName, 'tile') then
          begin
            //TXMLHelper.SkipToEndElement(InReader);
            Continue;
          end;

          TileName := RootNode.ChildNodes[i].GetAttribute('name');
          Img := ReadTileImageM(RootNode.ChildNodes[i], Ctx);

          if TileName = '' then
            raise Exception.Create('Missing tile name');
          if Img = nil then
            raise Exception.Create('Missing tile image');

          Ts := TTiles.Load(TileName);
          FTileImageMap[Ts.TileNumber] := Img;
        end;
      finally
        RootNode := nil;
     end;
    //finally
    //  InStream.Free;
   // end;
  except
    on E: Exception do
      raise Exception.Create('Unexpected error: ' + E.Message);
  end;
end;

class function TTileImages.GetInstance(ASize: Integer): TTileImages;
begin
  Result := GetInstance(Format('%dx%d', [ASize, ASize]), ASize);
  Result.LoadSpriteImages;
end;

class function TTileImages.GetInstance(const AName: string; ASize: Integer): TTileImages;
begin
  if not GSavedInstances.TryGetValue(ASize, Result) then
  begin
    Result := TTileImages.Create(AName, ASize);
    GSavedInstances.Add(ASize, Result);
  end;
end;

function TTileImages.GetTileImageInfo(TileNumber: Integer; ACycle: Integer): TImageInfo;
var
  Ti: TTileImage;
  Sti: TSimpleTileImage;
  Anim: TAnimation;
begin
  Assert((TileNumber and LOMASK) = TileNumber);
  Assert((TileNumber >= 0) and (TileNumber < Length(FTileImageMap)));

  Ti := FTileImageMap[TileNumber];
  if Ti is TSimpleTileImage then
  begin
    Sti := TSimpleTileImage(Ti);
    Result := TImageInfo.Create(Sti, False,Self);
  end
  else if Ti is TAnimation then
  begin
    Anim := TAnimation(Ti);
    Sti := TSimpleTileImage(Anim.GetFrameByTime(ACycle));
    Result := TImageInfo.Create(Sti, True,Self);
  end
  else
    raise Exception.CreateFmt('No image for tile %d', [TileNumber]);
end;

function TTileImages.GetTileImage(Tile: Integer): TBitmap;
begin
  Result := GetTileImageInfo(Tile).GetImage;
end;

function TTileImages.GetSpriteImage(Kind: TSpriteKind; FrameNumber: Integer): TBitmap;
begin
  Assert(FSpriteImages <> nil);
  if not FSpriteImages[SpriteKindInfo[Kind]].TryGetValue(FrameNumber, Result) then
    Result := nil;
end;

procedure TTileImages.LoadSpriteImages;
var
  Kind: TSpriteKindInfo;
  Imgs: TDictionary<Integer, TBitmap>;
  I: Integer;
  Img: TBitmap;
begin
  if FSpriteImages <> nil then
    Exit;

  FSpriteImages := TDictionary<TSpriteKindInfo, TDictionary<Integer, TBitmap>>.Create;
  for Kind in SpriteKindInfo do
  begin
    Imgs := TDictionary<Integer, TBitmap>.Create;
    for I := 0 to Kind.NumFrames - 1 do
    begin
      Img := LoadSpriteImage(Kind, I);
      if Img <> nil then
        Imgs.Add(I, Img);
    end;
    FSpriteImages.Add(Kind, Imgs);
  end;
end;

function TTileImages.LoadSpriteImage(Kind: TSpriteKindInfo; FrameNo: Integer): TBitmap;
var
  ResourceName: string;
  Bitmap: TBitmap;
begin
  ResourceName := 'obj' + IntToStr(Kind.ObjectId) + '-' + IntToStr(FrameNo);

  // Try to load specific size image first
  try
    Bitmap := TBitmap.Create;
    try
      Bitmap.LoadFromFile(TPath.Combine(ExtractFilePath(ParamStr(0)),
        'resources/'+ResourceName {+ '_' + IntToStr(FTileWidth)} {+ 'x' + IntToStr(FTileHeight)} + '.png'));
      Result := Bitmap;
      Exit;
    except
      Bitmap.Free;
    end;
  except
    // Fall through to next attempt
  end;

  // Try default image
  try
    Bitmap := TBitmap.Create;
    try
      Bitmap.LoadFromFile(TPath.Combine(ExtractFilePath(ParamStr(0)), ResourceName + '.png'));

      if (FTileWidth = 16) and (FTileHeight = 16) then
      begin
        Result := Bitmap;
        Exit;
      end;

      // Scale the image
      var ScaledBitmap := TBitmap.Create;
      try
        ScaledBitmap.SetSize(
          Round(Bitmap.Width * FTileWidth / 16),
          Round(Bitmap.Height * FTileHeight / 16));
        ScaledBitmap.Canvas.BeginScene;
        try
          ScaledBitmap.Canvas.DrawBitmap(Bitmap,
            RectF(0, 0, Bitmap.Width, Bitmap.Height),
            RectF(0, 0, ScaledBitmap.Width, ScaledBitmap.Height),
            1.0, True);
        finally
          ScaledBitmap.Canvas.EndScene;
        end;
        Result := ScaledBitmap;
        Bitmap.Free;
        Exit;
      except
        ScaledBitmap.Free;
        raise;
      end;
    except
      Bitmap.Free;
      raise;
    end;
  except
    Result := nil;
  end;
end;

function TTileImages.CacheSubImage(Bi: TBitmap; Rect: TRect): TBitmap;
var
  ImgCache: TDictionary<TRect, TBitmap>;
begin
  if not FSubImageCache.TryGetValue(Bi, ImgCache) then
  begin
    ImgCache := TDictionary<TRect, TBitmap>.Create;
    FSubImageCache.Add(Bi, ImgCache);
  end;

  if not ImgCache.TryGetValue(Rect, Result) then
  begin
    Result := TBitmap.Create(Rect.Width, Rect.Height);
    Result.Canvas.BeginScene;
    try
      Result.Canvas.DrawBitmap(Bi,
        RectF(Rect.Left, Rect.Top, Rect.Right, Rect.Bottom),
        RectF(0, 0, Rect.Width, Rect.Height),
        1.0, True);
    finally
      Result.Canvas.EndScene;
    end;
    ImgCache.Add(Rect, Result);
  end;
end;

class function TTileImages.LoadImage(const ResourceName: string; BasisSize: Integer): TSourceImage;
var
  Bitmap: TBitmap;
begin
  try
    Bitmap := TBitmap.Create;
    try
      Bitmap.LoadFromFile(TPath.Combine(ExtractFilePath(ParamStr(0)), ResourceName));
      Result := TSourceImage.Create(Bitmap, BasisSize);
    except
      Bitmap.Free;
      raise;
    end;
  except
    on E: Exception do
      raise Exception.Create('Error loading image: ' + E.Message);
  end;
end;

{ TTileImages.TMyLoaderContext }

constructor TTileImages.TMyLoaderContext.Create(AParent: TTileImages);
begin
  inherited Create;
  FParent := AParent;
  FImages := TDictionary<string, TSourceImage>.Create;
end;

function TTileImages.TMyLoaderContext.GetDefaultImage: TSourceImage;
begin
  Result := GetImage('tiles.png');
end;

function TTileImages.TMyLoaderContext.GetImage(const FileName: string): TSourceImage;
begin
  if not FImages.TryGetValue(FileName, Result) then
  begin
    Result := FParent.LoadImage('./' + {FParent.Name}'sm' + '/' + FileName, FParent.TileHeight);
    FImages.Add(FileName, Result);
  end;
end;

function TTileImages.TMyLoaderContext.ParseFrameSpec(const Tmp: string): TTileImage;
begin
  raise Exception.Create('Not implemented');
end;

{ TTileImages.TImageInfo }

constructor TTileImages.TImageInfo.Create(AImage: TSimpleTileImage; AAnimated: Boolean;AParent: TTileImages);
begin
  inherited Create;
  FParent := AParent;
  FImage := AImage;
  FAnimated := AAnimated;
end;

function TTileImages.TImageInfo.IsAnimated: Boolean;
begin
  Result := FAnimated;
end;

procedure TTileImages.TImageInfo.DrawTo(Canvas: TCanvas; DestX, DestY: Single);
begin
  Canvas.DrawBitmap(GetImage,
    RectF(0, 0, GetImage.Width, GetImage.Height),
    RectF(DestX, DestY, DestX + {GetImage.Width}FParent.TileWidth, DestY + {GetImage.Height}FParent.TileHeight),
    1.0, True);
end;

function TTileImages.TImageInfo.GetImage: TBitmap;
begin
    Result := FParent.CacheSubImage(FImage.SrcImage.Image,
    Rect(FImage.OffsetX, FImage.OffsetY, {FParent.TileWidth}FImage.OffsetX+16, FImage.OffsetY + 16{FParent.TileHeight}));
end;

initialization
  GSavedInstances := TDictionary<Integer, TTileImages>.Create;

finalization
  GSavedInstances.Free;

end.
