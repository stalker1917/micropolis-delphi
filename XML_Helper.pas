unit XML_Helper;

interface

uses
  System.SysUtils, System.Classes, Xml.XMLDoc, Xml.XMLIntf;

type
  TXMLHelper = class
  public
    class procedure SkipToEndElement(const Node: IXMLNode);
    class function ReadElementText(const Node: IXMLNode): TStringList;
    //class function ReadElementText(const Node: IXMLNode): TStringStream;
  end;

implementation

{ TXMLHelper }

class procedure TXMLHelper.SkipToEndElement(const Node: IXMLNode);
begin
  // In Delphi XML DOM model, elements are already parsed in full.
  // This method is only meaningful in streaming readers like StAX in Java.
  // You can use it to move to the end sibling or simply ignore it here.
end;

{
class function TXMLHelper.ReadElementText(const Node: IXMLNode): TStringStream;
var
  TextContent: string;

  procedure CollectText(n: IXMLNode);
  var
    i: Integer;
  begin
    if (n.NodeType in [ntText, ntCData]) then
      TextContent := TextContent + n.NodeValue;

    for i := 0 to n.ChildNodes.Count - 1 do
      CollectText(n.ChildNodes[i]);
  end;

begin
  TextContent := '';
  CollectText(Node);
  Result := TStringStream.Create(TextContent, TEncoding.UTF8);
end;
}
class function TXMLHelper.ReadElementText(const Node: IXMLNode): TStringList;
var
  TextContent: TstringList;

  procedure CollectText(n: IXMLNode);
  var
    i: Integer;
  begin
    if (n.NodeType in [ntText, ntCData]) then
      TextContent.Add(n.NodeValue); //:= TextContent + n.NodeValue;

    for i := 0 to n.ChildNodes.Count - 1 do
      CollectText(n.ChildNodes[i]);
  end;

begin
  //TextContent := '';
  CollectText(Node);
  Result := TextContent;//TStringStream.Create(TextContent, TEncoding.UTF8);
end;


end.
