(*
unit XML_Helper;

interface

uses
  System.SysUtils, System.Classes, Xml.XMLDoc, Xml.XMLIntf;

type
  TXMLHelper = class
  //private
    //class procedure SkipToEndElement(const Node: IXMLNode); overload;
  public
    class procedure SkipToEndElement(var Node: IXMLNode);  overload;
    class function ReadElementText(const Node: IXMLNode): TStringStream;
  end;

implementation

{ TXMLHelper }

class procedure TXMLHelper.SkipToEndElement(var Node: IXMLNode);
var
  TagDepth: Integer;
  CurrentNode: IXMLNode;
begin
  if Node = nil then
    Exit;

  // We assume Node is a start element
  TagDepth := 1;
  CurrentNode := Node;

  // Move forward until matching end element is found
  while (TagDepth > 0) and Assigned(CurrentNode) do
  begin
    CurrentNode := CurrentNode.NextSibling;
    if CurrentNode = nil then
      Break;

    if CurrentNode.NodeType = ntElement then
    begin
      if CurrentNode.HasChildNodes then
        Inc(TagDepth)
      else
        Dec(TagDepth);
    end; //Отладчиком проверять!
    //else if CurrentNode.NodeType = ntEndElement then
     // Dec(TagDepth);
  end;

  Node := CurrentNode; // update caller node reference
end;

class function TXMLHelper.ReadElementText(const Node: IXMLNode): TStringStream;
var
  TextContent: string;
begin
  if Node = nil then
    raise Exception.Create('Node is nil');

  TextContent := Node.Text;
  Result := TStringStream.Create(TextContent, TEncoding.UTF8);
end;

end.
*)
unit XML_Helper;

interface

uses
  System.SysUtils, System.Classes, Xml.XMLIntf;

type
  TXMLHelper = class
  private
    // Private constructor to prevent instantiation
    constructor Create;
  public
    class procedure SkipToEndElement(Node: IXMLNode);
    class function ReadElementText(InReader: IXMLNode): TTextReader;
  end;

  TElementTextReader = class(TTextReader)
  private
    FReader: IXMLNode;
    FTagDepth: Integer;
    FBuffer: string;
    FBufferPos: Integer;
    procedure ReadMore;
  public
    constructor Create(Reader: IXMLNode);
    function Read(var Buffer; Count: Longint): Longint; //override;
    function ReadString(Count: Longint): string; //override;
    procedure Close; override;
  end;

implementation

{ TXMLHelper }

constructor TXMLHelper.Create;
begin
  raise EInvalidOperation.Create('TXMLHelper cannot be instantiated');
end;

class procedure TXMLHelper.SkipToEndElement(Node: IXMLNode);
var
  TagDepth: Integer;
  CurrentNode: IXMLNode;
begin
  if Node = nil then
    Exit;

  // We assume Node is a start element
  TagDepth := 1;
  CurrentNode := Node;

  // Move forward until matching end element is found
  while (TagDepth > 0) and Assigned(CurrentNode) do
  begin
    CurrentNode := CurrentNode.NextSibling;
    if CurrentNode = nil then
      Break;

    if CurrentNode.NodeType = ntElement then
    begin
      if CurrentNode.HasChildNodes then
        Inc(TagDepth)
      else
        Dec(TagDepth);
    end; //Отладчиком проверять!
    //else if CurrentNode.NodeType = ntEndElement then
     // Dec(TagDepth);
  end;

  Node := CurrentNode; // update caller node referenc
end;

class function TXMLHelper.ReadElementText(InReader: IXMLNode): TTextReader;
begin
  Result := TElementTextReader.Create(InReader);
end;

{ TElementTextReader }

constructor TElementTextReader.Create(Reader: IXMLNode);
begin
  inherited Create;
  FReader := Reader;
  FTagDepth := 1;
  FBufferPos := 1;
end;

procedure TElementTextReader.ReadMore;
var
 CurrentNode: IXMLNode;
begin
  CurrentNode:=FReader;
  while (FTagDepth > 0) {and (FBufferPos > Length(FBuffer))} do
  begin
    CurrentNode:= CurrentNode.NextSibling;
    if CurrentNode = nil then
      Break;

    case FReader.NodeType of
      ntElement: Inc(FTagDepth);
      //ntEndElement: Dec(FTagDepth);
      ntText, ntCData, ntEntityRef{, ntWhitespace}:
        begin
          FBuffer := FReader.NodeValue;
          FBufferPos := 1;
        end;
    end;
  end;
end;

function TElementTextReader.Read(var Buffer; Count: Longint): Longint;
var
  Chars: PChar;
  CharsCopied: Integer;
begin
  if FBufferPos > Length(FBuffer) then
  begin
    ReadMore;
    if FTagDepth = 0 then
    begin
      Result := 0;
      Exit;
    end;
  end;

  if FBufferPos + Count - 1 <= Length(FBuffer) then
  begin
    CharsCopied := Count;
    Chars := PChar(@Buffer);
    Move(FBuffer[FBufferPos], Chars^, Count * SizeOf(Char));
    Inc(FBufferPos, Count);
  end
  else
  begin
    CharsCopied := Length(FBuffer) - FBufferPos + 1;
    Chars := PChar(@Buffer);
    Move(FBuffer[FBufferPos], Chars^, CharsCopied * SizeOf(Char));
    FBufferPos := Length(FBuffer) + 1;
  end;

  Result := CharsCopied;
end;

function TElementTextReader.ReadString(Count: Longint): string;
var
  CharsCopied: Integer;

begin
  if FBufferPos > Length(FBuffer) then
  begin
    ReadMore;
    if FTagDepth = 0 then
    begin
      Result := '';
      Exit;
    end;
  end;

  if FBufferPos + Count - 1 <= Length(FBuffer) then
  begin
    Result := Copy(FBuffer, FBufferPos, Count);
    Inc(FBufferPos, Count);
  end
  else
  begin
    Result := Copy(FBuffer, FBufferPos, Length(FBuffer) - FBufferPos + 1);
    FBufferPos := Length(FBuffer) + 1;
  end;
end;

procedure TElementTextReader.Close;
var
 CurrentNode: IXMLNode;
begin
  FBuffer := '';
  FBufferPos := 1;
  CurrentNode:=FReader;
  while (FTagDepth > 0) and (CurrentNode<>nil) do
  begin
    case FReader.NodeType of
      ntElement: Inc(FTagDepth);
      //ntEndElement: Dec(FTagDepth);
    end;
    CurrentNode:=CurrentNode.NextSibling;
  end;
end;

end.
