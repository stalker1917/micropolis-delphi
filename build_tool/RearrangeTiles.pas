unit RearrangeTiles;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  FMX.Graphics, FMX.Types, System.IOUtils;

type
  TRearrangeTiles = class
  private
    const
      DEST_COLUMNS = 16;
      TILE_SIZE = 16;
  public
    class procedure Rearrange(const InputFile, OutputFile: string);
  end;

implementation

class procedure TRearrangeTiles.Rearrange(const InputFile, OutputFile: string);
var
  SrcBitmap, DestBitmap: TBitmap;
  SrcCols, SrcRows, Ntiles, DestRows: Integer;
  i, SrcRow, SrcCol, DestRow, DestCol: Integer;
  SrcRect, DestRect: TRectF;
begin
  SrcBitmap := TBitmap.Create;
  DestBitmap := TBitmap.Create;
  try
    // Load source image
    SrcBitmap.LoadFromFile(InputFile);

    // Calculate source columns and rows based on tile size
    SrcCols := SrcBitmap.Width div TILE_SIZE;
    SrcRows := SrcBitmap.Height div TILE_SIZE;
    Ntiles := SrcCols * SrcRows;

    // Calculate destination rows
    DestRows := (Ntiles + DEST_COLUMNS - 1) div DEST_COLUMNS;

    // Create destination bitmap with the proper size
    DestBitmap.SetSize(DEST_COLUMNS * TILE_SIZE, DestRows * TILE_SIZE);
    DestBitmap.Clear(TAlphaColorRec.Black);

    // Copy tiles from source to destination in rearranged order
    for i := 0 to Ntiles - 1 do
    begin
      SrcRow := i div SrcCols;
      SrcCol := i mod SrcCols;

      DestRow := i div DEST_COLUMNS;
      DestCol := i mod DEST_COLUMNS;

      SrcRect := RectF(SrcCol * TILE_SIZE, SrcRow * TILE_SIZE,
                       (SrcCol + 1) * TILE_SIZE, (SrcRow + 1) * TILE_SIZE);
      DestRect := RectF(DestCol * TILE_SIZE, DestRow * TILE_SIZE,
                        (DestCol + 1) * TILE_SIZE, (DestRow + 1) * TILE_SIZE);

      DestBitmap.Canvas.BeginScene;
      try
        DestBitmap.Canvas.DrawBitmap(SrcBitmap, SrcRect, DestRect, 1.0, False);
      finally
        DestBitmap.Canvas.EndScene;
      end;
    end;

    // Save output image
    DestBitmap.SaveToFile(OutputFile);

  finally
    SrcBitmap.Free;
    DestBitmap.Free;
  end;
end;

end.