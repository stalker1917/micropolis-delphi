unit MakeTiles;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.Types,
  System.IOUtils, System.IniFiles, Vcl.Graphics, Vcl.Imaging.pngimage,
  Winapi.Windows, Xml.XMLIntf, Xml.XMLDoc, TileSpec, TileImage, System.UITypes,  System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,Math,
  FMX.Controls.Presentation, FMX.StdCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;
   TComposer = class;
  
  TTileMapping = record
    TileName: string;
    Ref: TTileImage;
    Dest: TTileImage;
    constructor Create(const ATileName: string; ARef, ADest: TTileImage);
  end;

  TLoaderContext = class(TInterfacedObject,ILoaderContext)
  private
    FLoadedImages: TDictionary<string, TSourceImage>;
  public
    constructor Create;
    destructor Destroy; override;


    function GetDefaultImage: TSourceImage;
    function GetImage(const FileName: string): TSourceImage;
    function ParseFrameSpec(const Tmp: string): TTileImage;
  end;


  TMakeTiles = class
  private
    class var
      FTileData: TDictionary<string, string>;
      FSkipTiles: Integer;
      FCountTiles: Integer;
      FTileSize: Integer;
      FStagingDir: string;
      FLoaderContext: TLoaderContext;
      
    class procedure GenerateFromRecipe(const RecipeFile, OutputDir: string);
    class function PrepareFrames(Ref: TTileImage; Composer: TComposer): TTileImage;
    class procedure DrawFrames(Dest: TTileImage; Composer: TComposer);
    class procedure WriteIndexFile(Mappings: TList<TTileMapping>; const IndexFile: string);
    class procedure WriteImageTags(ParentNode: IXMLNode; Dest: TTileImage);
    class function ParseFrameSpec(const Spec: TTileSpec): TTileImage; overload;
    class function ParseFrameSpec(const RawSpec: string): TTileImage; overload;
    class function ParseFrameSpec(const LayerStrings: TArray<string>): TTileImage; overload;
    class function ParseLayerSpec(const LayerStr: string): TTileImage;
    class function FindInkscape: string;
    class function RenderSvg(const FileName, SvgFile: string): string;
    class function LoadAnimation(const FileName: string): TTileImage;
    class function LoadImage(const FileName: string): TTileImage;
    class function LoadImageReal(const PngFile: string; BasisSize: Integer): TSourceImage;
    class function LoadImageNoCache(const FileName: string): TSourceImage;
    class function LoadImageXml(const XmlFile: string): TTileImage;
  public
    class procedure Main(const Args: TArray<string>);
  end;

  TComposeFrame = class(TTileImageSprite)
  private
    FRefImage: TTileImage;
  public
    constructor Create(ParentBuffer: TTileImage; ARefImage: TTileImage);
    property RefImage: TTileImage read FRefImage;
  end;

  TComposeBuffer = class(TTileImage)
  private
    FOutFile: string;
    FFileName: string;
    FUseAlpha: Boolean;
    FMaxWidth: Integer;
    FNextOffsetY: Integer;
    FWidthScaler : Integer;
    FBitmap: TBitmap;
  public
    constructor Create(const OutputDir, FileName: string; UseAlpha: Boolean);
    function PrepareTile(Size: TSize; RefImage: TTileImage): TTileImageSprite;
    procedure CreateBuffer;
    procedure WriteFile;
    procedure DrawFragment(Canvas: TCanvas; DestX, DestY, SrcX, SrcY: Integer); override;
    function GetCanvas:TCanvas;
  end;

  TComposer = class
  private
    FStanTiles: TComposeBuffer;
  public
    constructor Create(const OutputDir: string);
    function PrepareTile(RefImage: TTileImage): TTileImageSprite;
    procedure CreateBuffers;
    function GetCanvas(Sprite: TTileImageSprite): TCanvas;
    procedure WriteFiles;
    function GetBufCanvas:TCanvas;
  end;


var
  Form1: TForm1;
  
implementation
{$R *.fmx}

{ TMakeTiles }

class procedure TMakeTiles.Main(const Args: TArray<string>);
begin
  if Length(Args) <> 2 then
    raise Exception.Create('Wrong number of arguments');

  FTileSize := STD_SIZE;
  FSkipTiles := 0;
  FCountTiles := -1;
  
  // TODO: Implement reading system properties if needed
  
  GenerateFromRecipe(Args[0], Args[1]);
end;

class procedure TMakeTiles.GenerateFromRecipe(const RecipeFile, OutputDir: string);
var
 // Recipe: TMemIniFile;
  TileNames: TArray<string>;
  NTiles, I, j,TileNumber: Integer;
  Composer: TComposer;
  Mappings: TList<TTileMapping>;
  TileName, RawSpec: string;
  TileSpec: TTileSpec;
  Ref, Dest: TTileImage;
  Mapping: TTileMapping;
  Contents : TStringList;
begin
  //Recipe := TMemIniFile.Create(RecipeFile);
  if FLoaderContext=nil then FLoaderContext := TLoaderContext.Create;

  Contents := TStringList.Create;
  try
    Contents.LoadFromFile(RecipeFile);
    TileNames := TTileSpec.GenerateTileNames(Contents);
    
    if FCountTiles = -1 then
      NTiles := Length(TileNames)
    else
      NTiles := FCountTiles;
      
    Composer := TComposer.Create(OutputDir);
    try
      Mappings := TList<TTileMapping>.Create;
      try
        for I := 0 to NTiles - 1 do
        begin
          //if i=80 then
           //j:=0;
          TileNumber := FSkipTiles + I;
          if not (TileNumber >= 0) and (TileNumber < Length(TileNames)) then
            Continue;

          TileName := TileNames[TileNumber];
          RawSpec := TTileSpec.GetRecipeValue(Contents, TileName); //   Recipe.ReadString('', TileName, '');
          if RawSpec = '' then
            Continue;
            
          TileSpec := TTileSpec.Parse(TileNumber, TileName, RawSpec, Contents);
          Ref := ParseFrameSpec(TileSpec);
          if Ref = nil then
            Continue;
            
          Ref := Ref.NormalForm;
          Dest := PrepareFrames(Ref, Composer);
          
          Mapping := TTileMapping.Create(TileName, Ref, Dest);
          Mappings.Add(Mapping);
        end;
        
        Composer.CreateBuffers;

        Composer.GetBufCanvas.BeginScene();
        for Mapping in Mappings do
          DrawFrames(Mapping.Dest, Composer);
        Composer.GetBufCanvas.EndScene();
        ForceDirectories(OutputDir);
        Composer.WriteFiles;

        WriteIndexFile(Mappings, TPath.Combine(OutputDir, 'tiles.idx'));
      finally
        Mappings.Free;
      end;
    finally
      Composer.Free;
    end;
  finally
   Contents.Free;
  end;
end;

class function TMakeTiles.PrepareFrames(Ref: TTileImage; Composer: TComposer): TTileImage;
var
  MC: TAnimation;
  Dest: TAnimation;
  Frame: TAnimationFrame;
  S: TTileImage;
begin
  if Ref is TAnimation then
  begin
    MC := TAnimation(Ref);
    Dest := TAnimation.Create;
    try
      for Frame in MC.Frames do
      begin
        S := PrepareFrames(Frame.Frame, Composer);
        Dest.AddFrame(S, Frame.Duration);
      end;
      Result := Dest;
    except
      Dest.Free;
      raise;
    end;
  end
  else
  begin
    Result := Composer.PrepareTile(Ref);
  end;
end;

class procedure TMakeTiles.DrawFrames(Dest: TTileImage; Composer: TComposer);
var
  Ani: TAnimation;
  Frame: TAnimationFrame;
  CompFrame: TComposeFrame;
begin
  if Dest is TAnimation then
  begin
    Ani := TAnimation(Dest);
    for Frame in Ani.Frames do
      DrawFrames(Frame.Frame, Composer);
  end
  else if Dest is TComposeFrame then
  begin
    CompFrame := TComposeFrame(Dest);
    CompFrame.RefImage.DrawTo(Composer.GetCanvas(CompFrame), CompFrame.OffsetX, CompFrame.OffsetY);
  end;
end;

class procedure TMakeTiles.WriteIndexFile(Mappings: TList<TTileMapping>; const IndexFile: string);
var
  XMLDoc: IXMLDocument;
  RootNode, TileNode: IXMLNode;
  Mapping: TTileMapping;
begin
  XMLDoc := TXMLDocument.Create(nil);
  try
    XMLDoc.Active := True;
    XMLDoc.Version := '1.0';
    XMLDoc.Encoding := 'UTF-8';
    
    RootNode := XMLDoc.AddChild('micropolis-tiles-index');
    
    for Mapping in Mappings do
    begin
      TileNode := RootNode.AddChild('tile');
      TileNode.Attributes['name'] := Mapping.TileName;
      WriteImageTags(TileNode, Mapping.Dest);
    end;
    
    XMLDoc.SaveToFile(IndexFile);
  finally
    XMLDoc := nil;
  end;
end;

class procedure TMakeTiles.WriteImageTags(ParentNode: IXMLNode; Dest: TTileImage);
var
  Ani: TAnimation;
  Frame: TAnimationFrame;
  S: TTileImageSprite;
  FrameNode, ImageNode: IXMLNode;
begin
  if Dest is TAnimation then
  begin
    Ani := TAnimation(Dest);
    FrameNode := ParentNode.AddChild('animation');
    
    for Frame in Ani.Frames do
    begin
      S := TTileImageSprite(Frame.Frame);
      ImageNode := FrameNode.AddChild('frame');
      ImageNode.Attributes['duration'] := Frame.Duration.ToString;
      WriteImageTags(ImageNode, Frame.Frame);
    end;
  end
  else if Dest is TTileImageSprite then
  begin
    S := TTileImageSprite(Dest);
    while S.OffsetY>4095 do
      begin
        S.OffsetY := S.OffsetY - 4096;
        S.OffsetX := S.OffsetX + 16;
      end;

    ImageNode := ParentNode.AddChild('image');
    ImageNode.Attributes['at'] := Format('%d,%d', [S.OffsetX, S.OffsetY]);
  end;
end;

class function TMakeTiles.ParseFrameSpec(const Spec: TTileSpec): TTileImage;
begin
  Result := ParseFrameSpec(Spec.GetImages);
end;

class function TMakeTiles.ParseFrameSpec(const RawSpec: string): TTileImage;
var
  Parts: TArray<string>;
  I: Integer;
begin
  Parts := RawSpec.Split(['|']);
  for I := 0 to High(Parts) do
    Parts[I] := Parts[I].Trim;
    
  Result := ParseFrameSpec(Parts);
end;

class function TMakeTiles.ParseFrameSpec(const LayerStrings: TArray<string>): TTileImage;
var
  LayerStr: string;
  NewLayer: TTileImage;
begin
  Result := nil;
  
  for LayerStr in LayerStrings do
  begin
    NewLayer := ParseLayerSpec(LayerStr);
    
    if Result = nil then
      Result := NewLayer
    else
      Result := TTileImageLayer.Create(Result, NewLayer);
  end;
end;

class function TMakeTiles.ParseLayerSpec(const LayerStr: string): TTileImage;
var
  Parts: TArray<string>;
  Img: TTileImage;
  Sprite: TTileImageSprite;
  OffsetInfo: string;
  OffsetParts: TArray<string>;
begin
  Parts := LayerStr.Split(['@']);
  Img := LoadAnimation('./graphics/'+Parts[0]);

  
  if Length(Parts) >= 2 then
  begin
    Sprite := TTileImageSprite.Create(Img);
    
    OffsetInfo := Parts[1];
    OffsetParts := OffsetInfo.Split([',']);
    
    if Length(OffsetParts) >= 1 then
      Sprite.OffsetX := StrToInt(OffsetParts[0]);
      
    if Length(OffsetParts) >= 2 then
      Sprite.OffsetY := StrToInt(OffsetParts[1]);
      
    Result := Sprite;
  end
  else
    Result := Img;
end;

class function TMakeTiles.FindInkscape: string;
var
  ExeName: string;
  PathsToTry: TArray<string>;
  Path: string;
begin
  ExeName := 'inkscape';
  //if GetOSVersion in [osWindows] then
    ExeName := ExeName + '.exe';
    
  PathsToTry := [
    'C:\Program Files\Inkscape',
    'C:\Program Files (x86)\Inkscape',
    '/usr/bin'
  ];
  
  for Path in PathsToTry do
  begin
    Result := TPath.Combine(Path, ExeName);
    if FileExists(Result) then
      Exit;
  end;
  
  raise Exception.Create('INKSCAPE not installed (or not found)');
end;

class function TMakeTiles.RenderSvg(const FileName, SvgFile: string): string;
var
  PngFile: string;
  InkscapeBin: string;
  CmdLine: string;
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
begin
  PngFile := TPath.Combine(FStagingDir, 
    Format('%s_%dx%d.png', [FileName, FTileSize, FTileSize]));
    
  if FileExists(PngFile) and 
    (FileAge(PngFile) > FileAge(SvgFile)) then
  begin
    Result := PngFile;
    Exit;
  end;
  
  InkscapeBin := FindInkscape;
  
  ForceDirectories(ExtractFilePath(PngFile));
  
  CmdLine := Format('"%s" --export-dpi=%f --export-png="%s" "%s"',
    [InkscapeBin, FTileSize * 90.0 / STD_SIZE, PngFile, SvgFile]);
    
  FillChar(StartupInfo, SizeOf(StartupInfo), 0);
  StartupInfo.cb := SizeOf(StartupInfo);
  
  if not CreateProcess(nil, PChar(CmdLine), nil, nil, False, 0, nil, nil, 
    StartupInfo, ProcessInfo) then
    RaiseLastOSError;
    
  try
    WaitForSingleObject(ProcessInfo.hProcess, INFINITE);
  finally
    CloseHandle(ProcessInfo.hProcess);
    CloseHandle(ProcessInfo.hThread);
  end;
  
  if not FileExists(PngFile) then
    raise Exception.CreateFmt('File not found: %s', [PngFile]);
    
  Result := PngFile;
end;

class function TMakeTiles.LoadAnimation(const FileName: string): TTileImage;
var
  AniFile: string;
begin
  AniFile := FileName + '.ani';
  if FileExists(AniFile) then
    Result := TAnimation.Load(AniFile, FLoaderContext)
  else
    Result := LoadImage(FileName);
end;

class function TMakeTiles.LoadImage(const FileName: string): TTileImage;
var
  XmlFile: string;
begin
  XmlFile := FileName + '.xml';
  if FileExists(XmlFile) then
    Result := LoadImageXml(XmlFile)
  else
    Result := FLoaderContext.GetImage(FileName);
end;

class function TMakeTiles.LoadImageReal(const PngFile: string; BasisSize: Integer): TSourceImage;
var
  Bitmap: TBitmap;
begin
  Bitmap := TBitmap.Create;
  try
    Bitmap.LoadFromFile(PngFile);
    Result := TScaledSourceImage.Create(Bitmap, BasisSize, FTileSize);
  except
    Bitmap.Free;
    raise;
  end;
end;

class function TMakeTiles.LoadImageNoCache(const FileName: string): TSourceImage;
var
  SvgFile, PngFile: string;
begin
  SvgFile := FileName + '_' + IntToStr(FTileSize) + 'x' + IntToStr(FTileSize) + '.svg';
  if FileExists(SvgFile) then
  begin
    PngFile := RenderSvg(FileName, SvgFile);
    Result := LoadImageReal(PngFile, FTileSize);
    Exit;
  end;
  
  SvgFile := FileName + '.svg';
  if FileExists(SvgFile) then
  begin
    PngFile := RenderSvg(FileName, SvgFile);
    Result := LoadImageReal(PngFile, FTileSize);
    Exit;
  end;
  
  PngFile := FileName + '_' + IntToStr(FTileSize) + 'x' + IntToStr(FTileSize) + '.png';
  if FileExists(PngFile) then
  begin
    Result := LoadImageReal(PngFile, FTileSize);
    Exit;
  end;
  
  if FTileSize < 128 then
  begin
    PngFile := FileName + '_128x128.png';
    if FileExists(PngFile) then
    begin
      Result := LoadImageReal(PngFile, 128);
      Exit;
    end;
  end;
  
  PngFile := FileName + '.png';
  if FileExists(PngFile) then
  begin
    Result := LoadImageReal(PngFile, STD_SIZE);
    Exit;
  end;
  
  raise Exception.CreateFmt('File not found: %s.{svg,png}', [FileName]);
end;

class function TMakeTiles.LoadImageXml(const XmlFile: string): TTileImage;
var
  XMLDoc: IXMLDocument;
begin
  XMLDoc := TXMLDocument.Create(nil);
  try
    XMLDoc.LoadFromFile(XmlFile);
    XMLDoc.Active := True;
    Result := ReadTileImage(XMLDoc.DocumentElement, FLoaderContext);
  finally
    XMLDoc := nil;
  end;
end;

{ TTileMapping }

constructor TTileMapping.Create(const ATileName: string; ARef, ADest: TTileImage);
begin
  TileName := ATileName;
  Ref := ARef;
  Dest := ADest;
end;

{ TComposeFrame }

constructor TComposeFrame.Create(ParentBuffer: TTileImage; ARefImage: TTileImage);
begin
  inherited Create(ParentBuffer);
  FRefImage := ARefImage;
end;

{ TComposeBuffer }

constructor TComposeBuffer.Create(const OutputDir, FileName: string; UseAlpha: Boolean);
begin
  inherited Create;
  FOutFile := TPath.Combine(OutputDir, FileName);
  FFileName := FileName;
  FUseAlpha := UseAlpha;
end;

function TComposeBuffer.PrepareTile(Size: TSize; RefImage: TTileImage): TTileImageSprite;
begin
  Result := TComposeFrame.Create(Self, RefImage);
  Result.OffsetY := FNextOffsetY + Size.Height - STD_SIZE;//FTileSize;
  FNextOffsetY := FNextOffsetY + Size.Height;
  FMaxWidth := Max(FMaxWidth, Size.Width);
end;

procedure TComposeBuffer.CreateBuffer;
begin
  FBitmap := TBitmap.Create;
  //FBitmap.PixelFormat := pf32bit;     //Size Limitation 8192 * 8192!
  if FNextOffsetY<4096 then
    FBitmap.SetSize(FMaxWidth, FNextOffsetY)
  else
   begin
     FWidthScaler := FNextOffsetY div 4096 + 1;
     FBitmap.SetSize(FMaxWidth*FWidthScaler, 4096);
   end;
  //if not FUseAlpha then
   // FBitmap.Canvas.Brush.Color := clWhite;
  //FBitmap.Canvas.FillRect(Rect(0, 0, FBitmap.Width, FBitmap.Height));
   if not FUseAlpha then
  begin
    // For non-alpha images, fill with white background
    FBitmap.Canvas.BeginScene;
    try
      FBitmap.Canvas.Clear(TAlphaColorRec.White);
    finally
      FBitmap.Canvas.EndScene;
    end;
  end
  else
  begin
    // For alpha images, clear with transparent
    FBitmap.Canvas.BeginScene;
    try
      FBitmap.Canvas.Clear(TAlphaColorRec.Null);
    finally
      FBitmap.Canvas.EndScene;
    end;
  end;
end;

procedure TComposeBuffer.WriteFile;
begin
  FBitmap.SaveToFile(FOutFile);
end;

procedure TComposeBuffer.DrawFragment(Canvas: TCanvas; DestX, DestY, SrcX, SrcY: Integer);
begin
  raise Exception.Create('Unsupported operation');
end;

{ TComposer }

constructor TComposer.Create(const OutputDir: string);
begin
  FStanTiles := TComposeBuffer.Create(OutputDir, 'tiles.png', False);
end;

function TComposer.PrepareTile(RefImage: TTileImage): TTileImageSprite;
begin
  Result := FStanTiles.PrepareTile(TSize.Create({FTileSize, FTileSize}STD_SIZE,STD_SIZE), RefImage);
end;

procedure TComposer.CreateBuffers;
begin
  FStanTiles.CreateBuffer;
end;

function TComposer.GetCanvas(Sprite: TTileImageSprite): TCanvas;
begin
  Result := TComposeBuffer(Sprite.Source).FBitmap.Canvas;
end;

procedure TComposer.WriteFiles;
begin
  FStanTiles.WriteFile;
end;

constructor TLoaderContext.Create;
begin
  inherited Create;
  FLoadedImages := TDictionary<string, TSourceImage>.Create;
end;

destructor TLoaderContext.Destroy;
begin
  // Free all loaded images
  var Image: TSourceImage;
  for Image in FLoadedImages.Values do
    Image.Free;
  FLoadedImages.Free;
  inherited Destroy;
end;

function TLoaderContext.GetDefaultImage: TSourceImage;
begin
  raise ENotSupportedException.Create('GetDefaultImage not supported');
end;

function TLoaderContext.GetImage(const FileName: string): TSourceImage;
begin
  if not FLoadedImages.ContainsKey(FileName) then
  begin
    var Image := TMakeTiles.LoadImageNoCache(FileName); // Assume this function exists
    FLoadedImages.Add(FileName, Image);
  end;

  Result := FLoadedImages[FileName];
end;

function TLoaderContext.ParseFrameSpec(const Tmp: string): TTileImage;
begin
  Result := TMakeTiles.ParseFrameSpec(Tmp); // Assume MakeTiles class exists
end;

function TComposeBuffer.GetCanvas: TCanvas;
begin
  result:=FBitmap.Canvas;
end;

function TComposer.GetBufCanvas: TCanvas;
begin
  result:=FStanTiles.GetCanvas;
end;


(*
class function TMakeTiles.LoadImage(const FileName: string): TTileImage;
var
  XmlFile: string;
begin
  XmlFile := FileName + '.xml';
  if TFile.Exists(XmlFile) then
    Result := LoadImageXml(XmlFile)
  else
    Result := LoaderContext.GetImage(FileName);
end;

class function TMakeTiles.LoadImageReal(const PngFile: string; BasisSize: Integer): TSourceImage;
var
  Bitmap: TBitmap;
begin
  Bitmap := TBitmap.Create;
  try
    Bitmap.LoadFromFile(PngFile);
    Result := TScaledSourceImage.Create(Bitmap, BasisSize, TILE_SIZE);
  except
    Bitmap.Free;
    raise;
  end;
end;

class function TMakeTiles.LoadImageNoCache(const FileName: string): TSourceImage;
var
  SvgFile, PngFile: string;
begin
  PngFile := '';

  // Check for SVG files with specific tile size
  SvgFile := FileName + '_' + IntToStr(TILE_SIZE) + 'x' + IntToStr(TILE_SIZE) + '.svg';
  if TFile.Exists(SvgFile) then
    PngFile := RenderSvg(FileName, SvgFile)
  else
  begin
    // Check for generic SVG file
    SvgFile := FileName + '.svg';
    if TFile.Exists(SvgFile) then
      PngFile := RenderSvg(FileName, SvgFile);
  end;

  // If we have a rendered PNG file, load it
  if (PngFile <> '') and TFile.Exists(PngFile) then
    Exit(LoadImageReal(PngFile, TILE_SIZE));

  // Check for PNG files with specific tile size
  PngFile := FileName + '_' + IntToStr(TILE_SIZE) + 'x' + IntToStr(TILE_SIZE) + '.png';
  if TFile.Exists(PngFile) then
    Exit(LoadImageReal(PngFile, TILE_SIZE));

  // Check for 128x128 PNG if tile size is smaller
  if TILE_SIZE < 128 then
  begin
    PngFile := FileName + '_128x128.png';
    if TFile.Exists(PngFile) then
      Exit(LoadImageReal(PngFile, 128));
  end;

  // Check for generic PNG file
  PngFile := FileName + '.png';
  if TFile.Exists(PngFile) then
    Exit(LoadImageReal(PngFile, STD_SIZE));

  // File not found
  raise EFileNotFoundException.Create('File not found: ' + FileName + '.{svg,png}');
end;

class function TMakeTiles.LoadImageXml(const XmlFile: string): TTileImage;
var
  InStream: TFileStream;
  XMLDoc: IXMLDocument;
begin
  InStream := TFileStream.Create(XmlFile, fmOpenRead);
  try
    XMLDoc := TXMLDocument.Create(nil);
    try
      XMLDoc.LoadFromStream(InStream);
      XMLDoc.Active := True;
      Result := ReadTileImage(XMLDoc.DocumentElement, LoaderContext);
    except
      on E: Exception do
        raise EIOException.Create('XML Parse error: ' + E.Message);
    end;
  finally
    InStream.Free;
  end;
end;
*)

procedure TForm1.Button1Click(Sender: TObject);
 var A:TArray<String>;
begin
   SetLength(A,2);
   A[0]:='./graphics/tiles.rc';
   A[1]:=GetCurrentDir;
   TMakeTiles.Main(A);
end;

end.

