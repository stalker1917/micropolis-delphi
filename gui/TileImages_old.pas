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
  System.SysUtils, System.Classes, System.Generics.Collections,
  FMX.Graphics, FMX.Types, Xml.XmlDoc, Xml.XmlIntf, System.IOUtils,Types,
  TileImage;

type
  TImageCache = TDictionary<TRect,TBitmap>;
  TTileImages = class;
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

      TImageInfo = class
      private
        FImage: TSimpleTileImage;
        FAnimated: Boolean;
      public
        constructor Create(AImage: TSimpleTileImage; AAnimated: Boolean);
        function IsAnimated: Boolean;
        procedure DrawTo(Canvas: TCanvas; DestX, DestY: Integer);
        function GetImage: TBitmap;
        property Image: TSimpleTileImage read FImage;
        property Animated: Boolean read FAnimated;
      end;

  TTileImages = class
  strict private
    FName: string;
    FTileSize: Integer;
    FTileImages: TObjectList<TTileImage>;
    FSubImageCache : TDictionary<TBitmap,TImageCache>;
    procedure LoadTileIndex;
    function LoadBitmapFromResource(const ResName: string): TBitmap;
  public
    constructor Create(const AName: string; ASize: Integer);
    destructor Destroy; override;
    function GetImage(TileNum: Integer): TBitmap;
    function CacheSubImage(ABitmap: TBitmap; const Rect: TRect): TBitmap;
    function GetTileImageInfo(TileNumber, ACycle: Integer): TBitmap;
  end;


implementation

uses
  FMX.Dialogs;



{ TTileImage }
{

constructor TTileImage.Create(const ABitmap: TBitmap);
begin
  inherited Create;
  FBitmap := ABitmap;
end;

destructor TTileImage.Destroy;
begin
  FBitmap.Free;
  inherited;
end;
}

{ TTileImages }

constructor TTileImages.Create(const AName: string; ASize: Integer);
begin
  inherited Create;
  FName := AName;   //resources
  FTileSize := ASize;
  FTileImages := TObjectList<TTileImage>.Create;
  LoadTileIndex;
end;

destructor TTileImages.Destroy;
begin
  FTileImages.Free;
  inherited;
end;

procedure TTileImages.LoadTileIndex;
var
  Doc: IXMLDocument;
  Root{, NodeTile}: IXMLNode;
  TileName, ImgName: string;
  ImgStream: TMemoryStream;
  Bmp: TBitmap;
  i:Integer;
begin
  // Load XML index
  Doc := TXMLDocument.Create(nil);
  Doc.LoadFromFile(TPath.Combine('/' + FName, '/tiles.idx'));
  Root := Doc.DocumentElement;

  //Root.ChildNodes.

  for i:=0 to Root.ChildNodes.Count -1 do
  //NodeTile in Root.ChildNodes do
  begin
    if SameText(Root.ChildNodes[i].NodeName, 'tile') then
    begin
      TileName :=Root.ChildNodes[i].Attributes['name'];
      ImgName := Root.ChildNodes[i].Attributes['image'];
      Bmp := LoadBitmapFromResource('/' + FName + '/' + ImgName);
      FTileImages.Add(TTileImage.Create(Bmp));
    end;
  end;
end;

function TTileImages.LoadBitmapFromResource(const ResName: string): TBitmap;
var
  FileName: string;
begin
  FileName := TPath.Combine('res', ResName.Replace('/', PathDelim));
  if not TFile.Exists(FileName) then
    raise Exception.CreateFmt('Missing resource: %s', [FileName]);

  Result := TBitmap.CreateFromFile(FileName);
end;

function TTileImages.GetImage(TileNum: Integer): TBitmap;
begin
  Result := GetTileImageInfo(TileNum,0);//.GetImage;
 // if (TileNum >= 0) and (TileNum < FTileImages.Count) then
 //   Exit(FTileImages[TileNum].Bitmap)
 /// else
  //  raise Exception.CreateFmt('Invalid tile index %d', [TileNum]);
end;


function TTileImages.CacheSubImage(ABitmap: TBitmap; const Rect: TRect): TBitmap;
var
  Cache: TImageCache;
begin
  if not FSubImageCache.TryGetValue(ABitmap, Cache) then
  begin
    Cache := TImageCache.Create;
    FSubImageCache.Add(ABitmap, Cache);
  end;

  if not Cache.TryGetValue(Rect, Result) then
  begin
    Result := TBitmap.Create(Rect.Width, Rect.Height);
    Result.CopyFromBitmap(ABitmap, Rect, 0, 0);
    Cache.Add(Rect, Result);
  end;
end;


function TTileImages.GetTileImageInfo(TileNumber, ACycle: Integer): TBitmap;
var
  TI: TObject;
  STI: TSimpleTileImage;
  Anim: TAnimation;
begin
  TI := FTileImages[TileNumber];//FTileImageMap[TileNumber];
  if TI is TSimpleTileImage then
  begin
    STI := TSimpleTileImage(TI);
    Result := CacheSubImage(STI.SourceImage.Bitmap, TRect.Create(0, STI.OffsetY, FTILE_WIDTH, FTILE_HEIGHT));
  end
  else if TI is TAnimation then
  begin
    Anim := TAnimation(TI);
    STI := Anim.GetFrameByTime(ACycle);
    Result := CacheSubImage(STI.SourceImage.Bitmap, TRect.Create(0, STI.OffsetY, FTILE_WIDTH, FTILE_HEIGHT));
  end
  else
    raise Exception.CreateFmt('No image for tile %d', [TileNumber]);
end;

function TTileImages.GetTileImage(Tile: Integer): TBitmap;
begin
  Result := GetTileImageInfo(Tile);
end;

procedure TTileImages.LoadSpriteImages;
var
  Kind: TSpriteKind;
  FrameDict: TDictionary<Integer, TBitmap>;
  Img: TBitmap;
begin
  for Kind in TSpriteKind do
  begin
    FrameDict := TDictionary<Integer, TBitmap>.Create;
    for var I := 0 to Kind.NumFrames - 1 do
    begin
      Img := LoadSpriteImage(Kind, I);
      if Assigned(Img) then
        FrameDict.Add(I, Img);
    end;
    FSpriteImages.Add(Kind, FrameDict);
  end;
end;

function TTileImages.GetSpriteImage(Kind: TSpriteKind; FrameNumber: Integer): TBitmap;
var
  Frames: TDictionary<Integer, TBitmap>;
begin
  if not FSpriteImages.TryGetValue(Kind, Frames) then
    raise Exception.Create('Sprite kind not loaded');
  if not Frames.TryGetValue(FrameNumber, Result) then
    raise Exception.Create('Frame number not loaded');
end;

function TTileImages.LoadSpriteImage(Kind: TSpriteKind; FrameNo: Integer): TBitmap;
var
  FileName: string;
  Bitmap: TBitmap;
  Source: TBitmap;
begin
  FileName := Format('res/obj%d-%d_%dx%d.png', [Kind.ObjectId, FrameNo, FTILE_WIDTH, FTILE_HEIGHT]);
  if not TFile.Exists(FileName) then
    FileName := Format('res/obj%d-%d.png', [Kind.ObjectId, FrameNo]);

  if not TFile.Exists(FileName) then
    Exit(nil);

  Source := TBitmap.CreateFromFile(FileName);
  try
    if (FTILE_WIDTH = 16) and (FTILE_HEIGHT = 16) then
      Exit(Source)
    else
    begin
      Bitmap := TBitmap.Create(FTILE_WIDTH, FTILE_HEIGHT);
      Bitmap.Canvas.BeginScene;
      try
        Bitmap.Canvas.DrawBitmap(Source,
          RectF(0, 0, Source.Width, Source.Height),
          RectF(0, 0, Bitmap.Width, Bitmap.Height),
          1);
      finally
        Bitmap.Canvas.EndScene;
      end;
      Result := Bitmap;
    end;
  finally
    if Result <> Source then
      Source.Free;
  end;
end;

end.

