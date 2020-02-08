unit UMSTSParser;

interface
uses windows, sysutils, het.utils;

type
  TMSTSNode=class
  private
    FParent:TMSTSNode;
    FId:integer;
    FData:ansistring;
    FSubNodes:array of TMSTSNode;
    FSubNodeCount:integer;
    function AddSubNode:TMSTSNode;
    procedure RemoveSubNode(ANode:TMSTSNode);
    procedure Parse(const txt:ansistring;var APos:integer);
  public
    destructor Destroy;override;
    function SubNodeCount:integer;
    function SubNode(n:integer):TMSTSNode;overload;
    function SubNode(const aname:ansistring):TMSTSNode;overload;
    function Asansistring:ansistring;
    function AsInteger:integer;
    function AsFloat:double;
    function Dump:ansistring;
  end;

function MSTSParseStr(const txt:ansistring):TMSTSNode;
function UnpackFFE(const fn:ansistring):ansistring;

implementation

uses
  het.filesys;

const
  Whitespace:set of ansichar=[' ',#9,#13,#10,#0];
  NewLineansichars:set of ansichar=[#13,#10];
  NewLineMainansichar=#10;
  ansistringDelim:set of ansichar=['"'];
  CommentStart:ansistring='//';

  FFEDITDir:ansistring='c:\Program Files\Microsoft Games\Train Simulator\UTILS\FFEDIT';
  FFEDIT:ansistring='ffeditc_unicode.exe';
  UnCompressedHeader:ansistring='SIMISA@@@@@@@@@';
  CompressedHeader:ansistring='SIMISA@';

function UnpackFFE(const fn:ansistring):ansistring;
var s,dir,tempfn:ansistring;
    by:TBytes;
begin
  if fn=filereadstr(FFEDITDir+'\temp.sn')then begin
    result:=TEncoding.Unicode.GetString(fileReadBytes(FFEDITDir+'\temp.s'));
    delete(result,1,$20);
    exit;
  end;

  filewritestr(FFEDITDir+'\temp.sn',fn);
  result:='';
  s:=FileReadStr(fn);
  if copy(s,1,2)=#$FF#$FE then begin
    result:=TEncoding.Unicode.GetString(BytesOf(s));
    delete(result,1,$20);
  end else if copy(s,1,4)='SIMI' then begin
    GetDir(0,dir);
    chdir(FFEDITDir);
    if Exec(FFEDIT+' "'+fn+'" /u /o:temp.s',FFEDITDir)then begin
      result:=TEncoding.Unicode.GetString(fileReadBytes(FFEDITDir+'\temp.s'));
      delete(result,1,$20);
    end else result:='';
    chdir(dir);
  end;
end;

var EmptyNode:TMSTSNode;

function MSTSParseStr(const txt:ansistring):TMSTSNode;
var p:integer;
begin
  result:=TMSTSNode.Create;
  p:=1;
  Result.Parse(txt,p);
end;

{ TMSTSNode }

function TMSTSNode.AddSubNode: TMSTSNode;
begin
  if length(FSubNodes)<=FSubNodeCount then
    setlength(FSubNodes,(length(FSubNodes)+1)*2);
  result:=TMSTSNode.Create;
  result.FId:=FSubNodeCount;
  result.FParent:=self;
  FSubNodes[FSubNodeCount]:=result;
  inc(FSubNodeCount);
end;

function TMSTSNode.AsFloat: double;
begin
  result:=StrToFloatDef(FData,0)
end;

function TMSTSNode.AsInteger: integer;
begin
  result:=StrToIntDef(FData,0)
end;

function TMSTSNode.Asansistring: ansistring;
begin
  result:=FData;
end;

destructor TMSTSNode.Destroy;
var i:integer;
begin
  if FParent<>nil then
    FParent.RemoveSubNode(self);
  for i:=0 to FSubNodeCount-1 do begin
    FSubNodes[i].fparent:=nil;
    FSubNodes[i].free;
  end;
  FSubNodeCount:=0;
  inherited;
end;

function TMSTSNode.SubNode(n: integer): TMSTSNode;
begin
  if(n>=0)and(n<FSubNodeCount)then result:=FSubNodes[n]
                              else result:=EmptyNode;
end;

procedure TMSTSNode.RemoveSubNode(anode: TMSTSNode);
var i,j:integer;
begin
  for i:=0 to FSubNodeCount-1 do if ANode=fsubnodes[i] then begin
    for j:=i to FSubNodeCount-2 do FSubNodes[j]:=FSubNodes[j+1];
    Dec(FSubNodeCount);
  end;
end;

function TMSTSNode.SubNode(const aname: ansistring): TMSTSNode;
var i:integer;
begin
  for i:=0 to FSubNodeCount-1 do if (cmp(aname,FSubNodes[i].FData)=0)and(FSubNodes[i].FSubNodeCount>0)then begin
    result:=FSubNodes[i];exit;
  end;
  result:=EmptyNode;
end;

function TMSTSNode.SubNodeCount: integer;
begin
  result:=FSubNodeCount;
end;

procedure TMSTSNode.Parse(const txt: ansistring; var APos: integer);
  function eof:boolean;
  begin result:=APos>length(txt);end;

  function peek:ansichar;
  begin if (APos<=length(txt)) then result:=txt[apos] else result:=#0 end;

  procedure skipSpaces;
  begin while(APos<=length(txt)+1)and(peek in whitespace)do inc(APos);end;

  procedure skipline;
  begin
    while(APos<=length(txt))and(peek in NewLineansichars)do begin
      inc(APos);
      if peek=newlinemainansichar then begin inc(APos);break;end;
    end;
  end;

var nextnode:TMSTSNode;
    s:ansistring;
begin
  s:='';
  skipSpaces;
  nextnode:=nil;
  while length(txt)+1>=apos do begin
    if peek='/' then begin
      Inc(apos);
      if peek='/' then begin
        if(s<>'')then begin
          nextnode:=AddSubNode;
          nextnode.FData:=s;
          s:='';
        end;
        skipLine;skipSpaces
      end else dec(apos);
    end;
    case peek of
      '(':begin
            inc(Apos);
            if(nextnode=nil)then begin
              nextnode:=AddSubNode;
              nextnode.FData:=s;
              s:=''
            end;
            nextnode.Parse(txt,apos);
            skipSpaces;
            nextnode:=nil;
          end;
      ')':begin
            if(s<>'')then begin
              nextnode:=AddSubNode;
              nextnode.FData:=s;
              s:='';
            end;
            inc(APos);
            exit;
          end;
      '"':begin
            inc(apos);
            s:='';
            while not eof do begin
              if peek='"' then begin inc(apos);break;end;
              s:=s+peek;
              inc(apos);
            end;
            nextnode:=AddSubNode;
            nextnode.FData:=s;
            skipSpaces;
            s:='';
          end;
      ' ',#9,#10,#13,#0:begin
            if s<>'' then begin
              nextnode:=AddSubNode;
              nextnode.FData:=s;
            end;
            skipSpaces;
            s:='';
          end;
    else
      s:=s+peek;
      inc(apos);
    end;
  end;
end;

var ident:ansistring='';

function TMSTSNode.Dump: ansistring;
var i:integer;
    leafs:boolean;
begin
  result:=ident+FData;
  if FSubNodeCount>0 then begin
    leafs:=true;
    for i:=0 to FSubNodeCount-1 do if FSubNodes[i].FSubNodeCount>0 then begin
      leafs:=false;break;
    end;
    if leafs then begin
      result:=result+' (';
      for i:=0 to FSubNodeCount-1 do result:=result+' '+FSubNodes[i].FData;
      result:=result+' )'#13#10;
    end else begin
      result:=result+' ('#13#10;
      ident:=ident+'  ';
      for i:=0 to FSubNodeCount-1 do result:=result+FSubNodes[i].Dump;
      ident:=copy(ident,1,length(ident)-2);
      result:=result+ident+')'#13#10;
    end;
  end else result:=result+#13#10;
end;

initialization
  EmptyNode:=TMSTSNode.Create;
finalization
  FreeAndNil(EmptyNode);
end.
