program Project1;

uses
  System.StartUpCopy,
  FMX.Forms,
  MakeTiles in 'MakeTiles.pas' {Form1},
  TileImage in '..\graphics\TileImage.pas',
  XML_Helper in '..\XML_Helper.pas',
  TileSpec in '..\engine\TileSpec.pas',
  CityDimension in '..\engine\CityDimension.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
