unit het.Xml;  //av+het xml tobb eves takolas utan, todo: lecserelni az egeszet az uj parserrel
interface

uses windows, sysutils, dialogs;

type
  xmlString = ansistring;

  TXmlDocument=class;
  TXmlNode=class;
  TXmlNodes=array of TXMLNode;
  PXmlNodes=^TXMLNodes;

  TXMLNameSpace=class
  public
    nsId,nsUri,nsXsd:xmlString;
    IntroducingNode:TXmlNode;
    constructor Create(const Id:xmlString;const Intro:TXmlNode);
  end;

  TXMLAttribute = class
  public
    Document:TXMLDocument;
    Name,NameNoNS:xmlString;
    NSID:xmlString;
    Value:xmlString;
    Parent:TXMLNode;
    constructor Create(const Doc:TXmlDocument;const AttrName,Text:xmlString;const ParentNode:TXmlNode);
  end;

  TXmlNode = class
  private
    text:xmlString;
    procedure DeleteLeft(var s:xmlString;const n:integer=1);
    function DeleteAndGet(var s:xmlString):xmlString;
    function split(const s:xmlString;var name,value:xmlString):xmlString;
  public
    childNodes,childNodesWithText:TXmlNodeS;
    attributes:array of TXmlAttribute;
    schemas:array of TXmlNameSpace;
    nodeName:xmlString;
    nodeNameNoNS:xmlString;
    parent:TXmlNode;
    NSID:xmlString;
    isEmpty:boolean;
    document:TXmlDocument;
    mySchema:TXmlNameSpace;
    constructor Create(const doc:TXmlDocument;const name:xmlString;const parentNode:TXmlNode);
    destructor Destroy;override;
    function addChild(const name:xmlString):TXmlNode;
    function addAttribute(const name,value:xmlString):TXmlAttribute;
    function addSchema(const id:xmlString):TXmlNameSpace;
    function schemaById(const id:xmlString):TXmlNameSpace;
    function getText:xmlString;
    function selectSingleNode(const query:xmlString;const nonamespace:boolean):TXmlNode;
    function selectNodes(query:xmlString;const nonamespace:boolean):TXmlNodes;
    function getAttribute(const attrname:xmlString):xmlString;
  end;

  TXmlDocument = class
  private
    level,actpos:integer;
    currentNode:TXmlNode;
    isCurrentHeader:boolean;
    procedure parse;
    procedure addNode(nodestr:xmlString);
    procedure addText(const textstr:xmlString);
    procedure addNodeName(const nameStr:xmlString;const isHeader,isEmpty:boolean);
    procedure closeNodeName(const nameStr:xmlString);
    procedure addNodeAttribute(const attrStr:xmlString);
    procedure addSchema(const schema:TXmlNameSpace);
    procedure collectSchemas(const n:TXmlNode);
  public
    schemas:array of TXmlNameSpace;
    rootNode:TXmlNode;
    headerNodes:array of TXmlNode;
    xml:xmlString;
    constructor Create(const xmlstr:xmlString);
    destructor Destroy;override;
    function bejar(n:TXmlNode):string;
    function selectSingleNode(const query:xmlString;const nonamespace:boolean):TXmlNode;
    function selectNodes(const query:xmlString;const nonamespace:boolean):TXmlNodes;
  end;

implementation

uses Classes;


{ TXmlDocument }

procedure TXmlDocument.addNode(nodestr: xmlString);
var i:integer;
    s:xmlString;
    inStr,inSQuote,inDQuote,isFirst,isHeader,isClosing,isEmpty:boolean;
begin
  if nodestr[1]='!' then exit;
  try
  isHeader := false;
  if nodestr[1]='?' then begin
    for i := 2 to length(nodestr) do nodestr[i-1]:=nodestr[i];
    setlength(nodestr,length(nodestr)-1);
    if nodestr[length(nodestr)]='?' then setlength(nodestr,length(nodestr)-1);
    isHeader := true;
  end;
  isEmpty := false;
  if nodestr[length(nodestr)]='/' then begin
    setlength(nodestr,length(nodestr)-1);
    isEmpty := true;
  end;
  isClosing := false;
  if nodestr[1]='/' then begin
    for i := 2 to length(nodestr) do nodestr[i-1]:=nodestr[i];
    setlength(nodestr,length(nodestr)-1);
    isClosing := true;
  end;
  inStr := false; inSQuote := false; inDQuote := false; isFirst := true;
  for i := 1 to length(nodestr) do begin
    case nodestr[i] of
      ' ',#9,#13,#10:
        begin
          if inStr and (not inSQuote) and (not inDQuote) then begin
            if s<>'' then
              if isFirst then begin
                if isClosing then begin
                  closeNodeName(s);
                  exit;
                end else
                  addNodeName(s,isHeader,isEmpty)
              end else
                addNodeAttribute(s);
              s := '';
              isFirst := false;
            inStr := false;
          end else if inSquote or inDQuote then
            s:=s+nodestr[i];
        end;
      '''':
        begin
          if not inDQuote then inSQuote := not inSQuote;
          s := s + nodestr[i];
        end;
      '"':
        begin
          if not inSQuote then inDQuote := not inDQuote;
          s := s + nodestr[i];
        end;
      else begin
        s := s + nodestr[i];
        inStr := true;
      end;
    end;
  end;
  if inStr and (s<>'') then
    if isFirst then begin
      if isClosing then begin
        closeNodeName(s);
        exit;
      end else
        addNodeName(s,isHeader,isEmpty);
    end else
      addNodeAttribute(s);
  finally
    isCurrentHeader := false;
  end;
end;

procedure TXmlDocument.addNodeAttribute(const attrStr: xmlString);
var i:integer;
  name,value:xmlString;
  isNameOver:boolean;
begin
  isNameOver := false;
  name := ''; value := '';
  for i:=1 to length(attrStr)-1 do begin
    if attrStr[i]='=' then begin
      if isNameOver then value := value + attrStr[i] else isNameOver := true;
    end else begin
      if isNameOver then begin
        if length(name)+2<i then value := value + attrstr[i];
      end else name := name + attrStr[i];
    end;
  end;
  if isCurrentHeader then begin
    headerNodes[high(headerNodes)].addAttribute(name,value);
    exit;
  end;
  if currentNode=nil then exit;
  currentNode.addAttribute(name,value);
end;

procedure TXmlDocument.addNodeName(const nameStr: xmlString;const isHeader,isEmpty:boolean);
begin
  if isHeader then begin
    setlength(headerNodes,length(headerNodes)+1);
    headerNodes[high(headerNodes)]:= TXmlNode.Create(self,nameStr,nil);
    isCurrentHeader := true;
    exit;
  end;
  if rootNode=nil then begin
    if nameStr='' then exit;
    rootNode := TXmlNode.Create(self,nameStr,nil);
    currentNode := rootNode;
  end else begin
    if currentNode = nil then exit;
    if currentNode.isEmpty then currentNode := currentNode.parent;
    if currentNode = nil then exit;
    currentNode := currentNode.addChild(nameStr);
  end;
  currentNode.isEmpty := isEmpty;
end;

procedure TXmlDocument.addSchema(const schema: TXmlNameSpace);
begin
  setlength(schemas,length(schemas)+1);
  schemas[high(schemas)]:=schema;
end;

procedure TXmlDocument.addText(const textstr: xmlString);
var realtext,ref:xmlString;
i:integer;
begin
  if currentNode=nil then exit;
  if currentNode.isEmpty then currentNode := currentNode.parent;
  if system.pos('&',textstr)>0 then begin
    ref := ''; realtext := '';
    for i:=1 to length(textstr) do
      if length(ref)<1 then begin
        if textstr[i]='&' then begin
          ref := '&';
        end else begin
          realtext := realtext + textstr[i];
        end;
      end else begin
        ref := ref + textstr[i];
        if textstr[i]=';' then begin
          if ref='&amp;' then realtext := realtext + '&'
          else if ref='&nbsp;' then realtext := realtext + ' '
          else if ref='&lt;' then realtext := realtext + '<'
          else if ref='&gt;' then realtext := realtext + '>'
          else if ref='&quot;' then realtext := realtext + '"'
          else if ref='&apos;' then realtext := realtext + '''';
          ref := '';
        end;
      end;
    currentNode.addChild('').text:=realtext;
  end else
    currentNode.addChild('').text:=textstr;
end;

function TXmlDocument.bejar(n: TXmlNode):string;
var i:integer;
    s:string;
begin
  s := '';
  for i := 0 to level do s := s + #9;
  s := s + '<'+n.NSID+'*'+n.nodeNameNoNS+'> ';
  for i:= 0 to high(n.attributes) do s := s + n.attributes[i].NSID+'*'+n.attributes[i].nameNoNS+'='+n.attributes[i].value+' ';
  s := s + #13 + #10;
  inc(level);
  for i := 0 to high(n.childNodes) do s := s + bejar(n.childNodes[i]);
  dec(level);
  for i := 0 to level do s := s + #9;
  s := s + '</'+n.nodeName+'>'+#13+#10;
  result := s;
end;

procedure TXmlDocument.closeNodeName(const nameStr: xmlString);
begin
  if currentNode=nil then exit;
  while (currentNode.nodeName='') and (currentNode<>nil) do currentNode:=currentNode.parent;
  if currentNode.isEmpty then currentNode := currentNode.parent;
  if currentNode=nil then exit;
  if currentNode.nodeName<>nameStr then begin
    raise exception.Create('XML parsing error -> Missing closing "'+currentNode.nodeName+'" tag pos='+inttostr(actpos));
//    showMessage('Missing closing "'+currentNode.nodeName+'" tag pos='+inttostr(actpos));exit;
  end;
  currentNode := currentNode.parent;
end;

procedure TXmlDocument.collectSchemas(const n: TXmlNode);
var i:integer;
    curn:TXmlNode;
begin
  if n=nil then exit;
  if n.mySchema=nil then begin
    curn:=n;
    while (n.mySchema=nil) and (curn<>nil) do begin
      for i:=0 to high(curn.schemas) do
        if curn.schemas[i].NSID=n.NSID then begin
          n.mySchema:=curn.schemas[i];
          break;
        end;
      curn := curn.parent;
    end;
  end;
  for i:=0 to high(n.childNodes) do collectSchemas(n.childNodes[i]);
end;

constructor TXmlDocument.Create(const xmlstr:xmlString);
begin
  xml := xmlstr;
  rootNode := nil;
  currentNode := nil;
  isCurrentHeader := false;
  SetLength(headerNodes,0);
  setlength(schemas,0);
  parse;
  collectSchemas(rootNode);
  level := 0;
  if rootnode=nil then begin
    raise exception.create('Hiba az XML-ben (xml='''')');
  end else
end;

destructor TXmlDocument.Destroy;
var i:integer;
begin
  for i:=0 to high(schemas) do schemas[i].Free;
  for i:=0 to high(headernodes) do headerNodes[i].Free;
  rootNode.free;
  inherited;
end;

procedure TXmlDocument.parse;
var i:integer;
    inKacsa:boolean;
    //s:xmlString;
    sstart,slen:integer;
begin
  inKacsa := false;
  sstart := 1;slen:=0;
  for i:=1 to length(xml) do begin
    actpos:=i;
    if xml[i]='<' then begin
      if inKacsa then begin
        if slen=0 then sstart:=i;inc(slen);
      end else begin
        inKacsa := true;
        if slen>0 then begin
          addText(copy(xml,sstart,slen));
          slen:=0;
        end;
      end;
    end else
      if xml[i]='>' then begin
        if inKacsa then begin
          inKacsa := false;
          addNode(copy(xml,sstart,slen));
          slen:=0;
        end else begin
          if slen=0 then sstart:=i;inc(slen);
        end;
      end else begin
        if slen=0 then sstart:=i;inc(slen);
      end;
  end;
end;

function TXmlDocument.selectNodes(const query:xmlString;const nonamespace: boolean): TXmlNodes;
begin
  result:=rootNode.selectNodes(query,nonamespace);
end;

function TXmlDocument.selectSingleNode(const query:xmlString;const nonamespace:boolean): TXmlNode;
begin
  result:=rootNode.selectSingleNode(query,nonamespace);
end;

{ TXmlNode }

function TXmlNode.addAttribute(const name,value:xmlString):TXmlAttribute;
begin
  setlength(attributes,length(attributes)+1);
  result := TXmlAttribute.Create(document,name,value,self);
  attributes[high(attributes)]:=result;
end;

function TXmlNode.addChild(const name:xmlString):TXmlNode;
begin
  setlength(childNodesWithText,length(childNodesWithText)+1);
  result := TXmlNode.Create(document,name,self);
  childNodesWithText[high(childNodesWithText)]:=result;
  if name<>'' then begin
    setlength(childNodes,length(childNodes)+1);
    childNodes[high(childNodes)]:=result;
  end;
end;

function TXmlNode.addSchema(const id:xmlString):TXmlNameSpace;
begin
  setlength(schemas,length(schemas)+1);
  result := TXmlNameSpace.Create(id,self);
  schemas[high(schemas)] := result;
end;

constructor TXmlNode.Create(const doc:TXmlDocument;const name:xmlString;const parentNode:TXmlNode);
var i,j:integer;
    wasNS:boolean;
begin
  document := doc;
  nodeName := name;
  isEmpty := false;
  parent := parentNode;
  setlength(childNodes,0);
  SetLength(attributes,0);
  setlength(schemas,0);
  NSID := '';
  wasNS:=false;
  nodeNameNoNS := nodeName;
  for i:=1 to length(nodeNameNoNS) do
    if nodeNameNoNS[i]<>':' then begin
      NSID := NSID + nodeNameNoNS[i];
    end else begin
      wasNS := true;
      for j:=1 to length(nodeNameNoNS)-i do nodeNameNoNS[j]:=nodeNameNoNS[j+i];
      setlength(nodeNameNoNS,length(nodeNameNoNS)-i);
      break;
    end;
  if not wasNS then NSID:='';
  mySchema := nil;
end;


function TXmlNode.DeleteAndGet(var s: xmlString): xmlString;
begin
  result := '';
  while (length(s) > 0) and (s[1]<>'/') do begin
    result := result + s[1];
    deleteleft(s);
  end;
  deleteleft(s);
end;

procedure TXmlNode.DeleteLeft(var s:xmlString;const n:integer);
var i:integer;
begin
  for i:=1 to length(s)-n do begin
    s[i] := s[i+n];
  end;
  setlength(s,length(s)-n);
end;

destructor TXmlNode.Destroy;
var i:integer;
begin
  for i:=0 to high(attributes) do attributes[i].Free;
  for i:=0 to high(childNodesWithText) do childNodesWithText[i].Free;
end;

function TXmlNode.getAttribute(const attrname:xmlString):xmlString;
var i:integer;
begin
  result := '';
  for i := 0 to high(attributes) do begin
    if attributes[i].name=attrname then begin
      result := attributes[i].value;
    end;
  end;
end;

function TXmlNode.getText: xmlString;
var i:integer;
begin
  result := '';
  if self=nil then exit;
  if text <> '' then result := text;
  for i:=0 to high(childNodesWithText) do result := result + childNodesWithText[i].getText;
end;

function TXmlNode.schemaById(const id:xmlString):TXmlNameSpace;
var i:integer;
begin
  result := nil;
  for i := 0 to high(schemas) do
    if schemas[i].NSID=id then begin
      result := schemas[i];
      exit;
    end;
end;

function TXmlNode.selectNodes(query:xmlString;const nonamespace:boolean):TXmlNodes;
var s:xmlString;
    isMulti,volt:boolean;
    i,j,k:integer;
    res:TXmlNodes;
    xname,xvalue:xmlString;
begin
  isMulti := false;
  setlength(result,0);
  if length(query)>2 then
  if (query[1]='/') and (query[2]='/') then begin
    isMulti := true;
    DeleteLeft(query);
    DeleteLeft(query);
  end;
  if length(query)>1 then
  if(query[1]='/') then begin
    deleteleft(query);
    s := split(DeleteAndGet(query),xname,xvalue);
    if (nonamespace and (nodeNameNoNS=s)) or ((not nonamespace) and (nodeName=s)) then begin
      result := document.rootNode.selectNodes(query,nonamespace);
    end else exit;
  end;
  if (length(query)>1) and (query[length(query)]='/') then setlength(query,length(query)-1);
  if query='' then begin
    setlength(result,1);
    result[0] := self;
    exit;
  end;
  if ismulti then begin
    setlength(res,0);
    for i:=0 to high(childnodes) do begin
      res := childnodes[i].selectNodes('//'+query,nonamespace);
      for j:=0 to high(res) do begin
        volt := false;
        for k:=0 to high(result) do
          if result[k]=res[j] then begin
            volt := true;
            break;
          end;
        if not volt then begin
          setlength(result,length(result)+1);
          result[high(result)] := res[j];
        end;
      end;
    end;
  end;
  s := DeleteAndGet(query);
  s := split(s,xname,xvalue);
  if s='' then begin
          setlength(result,length(result)+1);
          result[high(result)] := self;
          exit;
  end;
  for i:=0 to high(childnodes) do begin
    if (nonamespace and (childnodes[i].nodeNameNoNS=s)) or ((not nonamespace) and (childNodes[i].nodeName=s)) then begin

      if xname<>'' then begin
        if xvalue <>'' then begin
          if childnodes[i].getAttribute(xname)<>xvalue then continue;
        end else begin
          if childnodes[i].getAttribute(xname)='' then continue;
        end;
      end;

      res := childnodes[i].selectNodes(query,nonamespace);
      for j:=0 to high(res) do begin
        volt := false;
        for k:=0 to high(result) do
          if result[k]=res[j] then begin
            volt := true;
            break;
          end;
        if not volt then begin
          setlength(result,length(result)+1);
          result[high(result)] := res[j];
        end;
      end;

    end;
  end;
end;

function TXmlNode.selectSingleNode(const query:xmlString;const nonamespace:boolean):TXmlNode;
var res:TXmlNodes;
begin
  res := selectNodes(query,nonamespace);
  if length(res) < 1 then result := nil else result := res[0];
end;

function TXmlNode.split(const s:xmlString; var name,value: xmlString):xmlString;
var i,at:integer;
begin
  result := '';
  name := '';
  value := '';
  at := 0;
  for i:=1 to length(s) do begin
    case at of
      0:
        begin
          if s[i]='[' then begin
            at := 1;
          end else begin
            result := result + s[i];
          end;
        end;
      1: at := 2;
      2:
        begin
          if s[i]='=' then begin
            at := 3;
          end else begin
            if s[i]=']' then begin
              at := 5;
            end else begin
              name := name + s[i];
            end;
          end;
        end;
      3: at := 4;
      4:
        begin
          if s[i]='"' then begin
            at := 5;
          end else begin
            value := value + s[i];
          end;
        end;
    end;
  end;
end;

{ TXmlAttribute }

constructor TXmlAttribute.Create(const doc:TXmlDocument;const attrname,text:xmlString;const parentNode:TXmlNode);
var i,j:integer;
    wasNS,wasspace:boolean;
    schema:TXmlNameSpace;
begin
  document := doc;
  name := attrname;
  value := text;
  parent := parentNode;
  NSID := '';
  wasNS:=false;
  nameNoNS := name;
  for i:=1 to length(nameNoNS) do
    if nameNoNS[i]<>':' then begin
      NSID := NSID + nameNoNS[i];
    end else begin
      wasNS := true;
      for j:=1 to length(nameNoNS)-i do nameNoNS[j]:=nameNoNS[j+i];
      setlength(nameNoNS,length(nameNoNS)-i);
      break;
    end;
  if not wasNS then NSID:='';
  if NSID='xmlns' then begin
    schema := parent.addSchema(nameNoNS);
    document.addSchema(schema);
    wasspace := false;
    for i:=1 to length(value) do begin
      if value[i]=' ' then begin
        wasspace := true;
        if schema.NSXSD<>'' then break;
      end else begin
        if wasspace then schema.NSXSD := schema.NSXSD + value[i]
          else schema.NSURI := schema.NSURI + value[i];
      end;
    end;
  end;
  if name='xmlns' then begin
    schema := parent.addSchema('');
    document.addSchema(schema);
    wasspace := false;
    for i:=1 to length(value) do begin
      if value[i]=' ' then begin
        wasspace := true;
        if schema.NSXSD<>'' then break;
      end else begin
        if wasspace then schema.NSXSD := schema.NSXSD + value[i]
          else schema.NSURI := schema.NSURI + value[i];
      end;
    end;
  end;
  if nameNoNS='schemaLocation' then begin
    schema := parent.schemaById(NSID);
    if schema<>nil then begin
      schema.NSXSD := value;
    end;
  end;
end;

{ TXmlNameSpace }

constructor TXmlNameSpace.Create(const id:xmlString;const intro:TXmlNode);
begin
  NSID:=id;
  NSURI:='';
  NSXSD:='';
  introducingNode:=intro;
end;

end.
