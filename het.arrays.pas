unit het.Arrays;         //controls   hetfilesys het.Objects

interface

uses sysutils, classes, dialogs, variants, typinfo, Generics.Collections;

type
  TComparerFunct<T> =reference to function(const a,b:T):integer;
  TFinderFunct<T> =reference to function(const a:T):integer;
  TFinderFunctBool<T> =reference to function(const a:T):boolean;
  TSelectorFunct<T> =reference to function(const a:T):boolean;
  TForEachProc<T> =reference to procedure(const a:T);

  THetArrayEnumerator<T> =class;

  THetArray<T> =record
  public
    FItems:TArray<T>;
    FCount:integer;
  private
    procedure InitUninitialized;inline;//ha stackra lett lefoglalva, akkor length(FItems=0)and FCount<>0, ezert 0 lesz

    procedure AdjustGrow;
    procedure AdjustShrink;

  public
    function Count:integer;
    procedure Clear;
    procedure Insert(at:integer);overload;
    procedure Insert(const AItem:T;at:integer);overload;
    function InsertBinary(const AItem:T;const FinderFunct:TFinderFunct<T>;const InsertIfExists:boolean):integer;overload;
    function InsertBinary(const AItem:T;const ComparerFunct:TComparerFunct<T>;const InsertIfExists:boolean):integer;overload;
    function Append:integer;overload;
    function Append(const AItem:T):integer;overload;
    procedure Append(const AArray:THetArray<T>);overload;
    procedure Remove(const at:integer);
    function IndexValid(const idx:integer):boolean;
    function SetItem(const idx:integer;const AItem: T):boolean;
    function GetItem(const idx:integer;const IfNotFound:T):T;
    function GetLast(const IfEmpty:T):T;
    procedure SetLast(const AItem:T);

    procedure Push(const AItem:T);
    function Peek:T;
    function Pop:T;

    procedure Exchange(const at1,at2:integer);
    procedure Move(const AFrom,ATo:integer);

    procedure ExpandRange(const idx:integer;const FinderFunct:TFinderFunct<T>;out st,en:integer);overload;
    procedure ExpandRange(const idx:integer;const FinderFunct:TFinderFunctBool<T>;out st,en:integer);overload;
    procedure ExpandRange(const idx:integer;const ComparerFunct:TComparerFunct<T>;out st,en:integer);overload;

    function Find(const FinderFunct:TFinderFunctBool<T>;out Idx:integer):boolean;overload;
    function Find(const AItem:T;const ComparerFunct:TComparerFunct<T>;out Idx:integer):boolean;overload;

    function FindRange(const FinderFunct:TFinderFunctBool<T>;out st,en:integer):boolean;overload;
    function FindRange(const AItem:T;const ComparerFunct:TComparerFunct<T>;out st,en:integer):boolean;overload;

    function FindBinary(const FinderFunct:TFinderFunct<T>;out Idx:integer):boolean;overload;
    function FindBinary(const AItem:T;const ComparerFunct:TComparerFunct<T>;out Idx:integer):boolean;overload;

    function FindBinaryRange(const FinderFunct:TFinderFunct<T>;out st,en:integer):boolean;overload;
    function FindBinaryRange(const AItem:T;const ComparerFunct:TComparerFunct<T>;out st,en:integer):boolean;overload;

    function FindNewPosBinary(const AIdx:integer;const ComparerFunct:TComparerFunct<T>):integer;

    procedure QuickSort(const ComparerFunct:TComparerFunct<T>);overload;
    procedure QuickSort(const ComparerFunct:TComparerFunct<T>;L,R:Integer);overload;

    procedure Distinct(const ComparerFunct:TComparerFunct<T>;AlreadySorted:boolean=false);

    procedure Shuffle;

    function IsEmpty:boolean;
    function IsSorted(const ComparerFunct:TComparerFunct<T>):boolean;

    procedure Compact;

    procedure ForEach(const AProc:TForEachProc<T>);

    procedure SetItems(const AItems:TArray<T>);

    function Empty:boolean;

    procedure Reverse;
  public
    function GetEnumerator:THetArrayEnumerator<T>;
  public
    class operator Add(const AArray:THetArray<T>;const AItem:T):THetArray<T>;
    class operator Add(const AArray1,AArray2:THetArray<T>):THetArray<T>;
  end;

  THetArrayEnumerator<T> = class(TEnumerator<T>)
  private
    FArray:pointer;
    FIndex:Integer;
  protected
    function DoGetCurrent:T; override;
    function DoMoveNext:Boolean;override;
  public
    constructor Create(const AArray:THetArray<T>);
  end;

type
  _TCacheRec=record//sajnos nem megy ez a lenti classon belul, pedig ott lenne a fasza
    Hash:integer;
    Obj:TObject;
  end;

  TCache<T:class> =class
  private type
    TLoaderFunct=reference to function(const AName:ansistring):T;
  private
    FList:THetArray<_TCacheRec>;//sort by hash
    FRecentCache:array of _TCacheRec;
    FLoader:TLoaderFunct;
    function GetByName(const AName:AnsiString):T;
  public
    constructor Create(const ALoader:TLoaderFunct;const ARecentCacheSize:integer=0);
    property ByName[const AName:ansistring]:T read GetByName;default;
    procedure Clear;
    destructor Destroy;override;
  end;

implementation

uses
  het.Utils;

{ THetArray }

procedure THetArray<T>.InitUninitialized;
begin
  if FItems=nil then FCount:=0;
end;

procedure THetArray<T>.AdjustGrow;
var len:integer;
begin
  len:=length(FItems);
  if len<FCount then
    setlength(FItems,FCount*3 shr 1);
end;

procedure THetArray<T>.AdjustShrink;
var len:integer;
begin
  len:=length(FItems);
  if FCount shl 1<len then begin
    if FCount>0 then
      setlength(FItems,FCount)
    else
      setlength(FItems,0);
  end;
end;

procedure THetArray<T>.Insert(at:integer);var len:integer;
var i:integer;
begin InitUninitialized;
  Assert((at>=0)and(at<=FCount),'TExpArray<T>.Insert: out of range');
  inc(FCount);AdjustGrow;
{  if at<FCount-1 then
    system.Move(FItems[at],FItems[at+1],(FCount-1-at)*sizeof(T));}
  for i:=FCount-1 downto at+1 do FItems[i]:=FItems[i-1];
end;

procedure THetArray<T>.Insert(const AItem:T;at:integer);var len:integer;
var i:integer;
begin InitUninitialized;
  Assert((at>=0)and(at<=FCount),'TExpArray<T>.Insert: out of range');
  inc(FCount);AdjustGrow;
{  if at<FCount-1 then
    system.Move(FItems[at],FItems[at+1],(FCount-1-at)*sizeof(T));}
  for i:=FCount-1 downto at+1 do FItems[i]:=FItems[i-1];

  FItems[at]:=AItem;
end;

function THetArray<T>.Append:integer;
begin InitUninitialized;
  result:=FCount;inc(FCount);AdjustGrow;
end;

function THetArray<T>.Append(const AItem:T):integer;
begin InitUninitialized;
  result:=FCount;inc(FCount);AdjustGrow;
  FItems[result]:=AItem;
end;

procedure THetArray<T>.Append(const AArray:THetArray<T>);
var i:T;
begin
{  i:=Count;  //non dynamic version
  FCount:=i+AArray.Count;
  AdjustGrow;
  system.move((@AArray.FItems[0])^,(@FItems[i])^,AArray.Count*Sizeof(T)); }
  for i in AArray do Append(i);//dynamic
end;

procedure THetArray<T>.SetLast(const AItem: T);
begin InitUninitialized;
  if FCount=0 then Append(AItem)
              else FItems[FCount-1]:=AItem;
end;

function THetArray<T>.GetLast(const IfEmpty:T):T;
begin InitUninitialized;
  if FCount=0 then result:=IfEmpty
              else result:=FItems[FCount-1];
end;

function THetArray<T>.IndexValid(const idx:integer):boolean;
begin InitUninitialized;
  result:=(idx>=0)and(idx<FCount);
end;

function THetArray<T>.SetItem(const idx:integer;const AItem: T):boolean;
begin InitUninitialized;
  result:=IndexValid(idx);
  if result then
    FItems[idx]:=AItem;
end;

function THetArray<T>.GetItem(const idx:integer;const IfNotFound:T):T;
begin InitUninitialized;
  if IndexValid(idx)then result:=FItems[idx]
                    else result:=IfNotFound;
end;

procedure THetArray<T>.Clear;
begin
  SetLength(FItems,0);
  FCount:=0;
end;

procedure THetArray<T>.Compact;
begin
  if length(FItems)=0 then FCount:=0//inituninitialized
                      else setlength(FItems,FCount);
end;

function THetArray<T>.Count: integer;
begin InitUninitialized;
  result:=FCount;
end;

procedure THetArray<T>.Push(const AItem:T);
begin InitUninitialized;
  inc(FCount);AdjustGrow;
  FItems[FCount-1]:=AItem;
end;

function THetArray<T>.Peek:T;
begin InitUninitialized;
  Assert(FCount>0,'TExpArray<T>.Peek: empty array');
  result:=FItems[FCount-1];
end;

function THetArray<T>.Pop:T;
begin InitUninitialized;
  Assert(FCount>0,'TExpArray<T>.Pop: empty array');
  result:=FItems[FCount-1];
  dec(FCount);AdjustShrink;
end;


procedure THetArray<T>.Remove(const at:integer);
var i:integer;
begin InitUninitialized;
  Assert(IndexValid(at),'TExpArray<T>.Remove: out of range');
{  if at<FCount-1 then
    system.Move(FItems[at+1],FItems[at],(FCount-1-at)*sizeof(T));}
  for i:=at to FCount-2 do FItems[i]:=FItems[i+1];
  dec(FCount);AdjustShrink;
end;

procedure THetArray<T>.Reverse;
var i,j:integer;
    tmp:T;
begin InitUninitialized;
  i:=0; j:=Count-1;
  while i<j do begin
    tmp:=FItems[i];
    FItems[i]:=FItems[j];
    FItems[j]:=tmp;
    inc(i);dec(j);
  end;
end;

function THetArray<T>.Empty: boolean;
begin InitUninitialized;
  result:=FCount<=0;
end;

procedure THetArray<T>.Exchange(const at1,at2:integer);
var temp:T;
begin InitUninitialized;
  Assert(IndexValid(at1),'TExpArray<T>.Exchange: at1 out of range');
  Assert(IndexValid(at2),'TExpArray<T>.Exchange: at2 out of range');
  temp:=FItems[at1];
  FItems[at1]:=FItems[at2];
  FItems[at2]:=temp;
end;

procedure THetArray<T>.Move(const AFrom,ATo:integer);
var temp:T;i:integer;
begin InitUninitialized;
  Assert(IndexValid(AFrom),'TExpArray<T>.Move: AFrom out of range');
  Assert(IndexValid(ATo)  ,'TExpArray<T>.Move: ATo out of range');
  if AFrom<ATo then begin
    temp:=FItems[AFrom];
    //system.Move(FItems[AFrom+1],FItems[AFrom],(ATo-AFrom)*sizeof(T));
    for i:=AFrom to ATo-1 do FItems[i]:=FItems[i+1];
    FItems[ATo]:=temp;
  end else if ATo<AFrom then begin
    temp:=FItems[AFrom];
    //system.Move(FItems[ATo],FItems[ATo+1],(AFrom-ATo)*sizeof(T));
    for i:=AFrom downto ATo+1 do FItems[i]:=FItems[i-1];
    FItems[ATo]:=temp;
  end;
end;

procedure THetArray<T>.ExpandRange(const idx:integer;const FinderFunct:TFinderFunct<T>;out st,en:integer);
begin InitUninitialized;
  Assert(IndexValid(idx),'THetArray<T>.ExpandRange: idx out of range');
  st:=idx;en:=idx;
  while(st>0)and(FinderFunct(FItems[st-1])=0)do dec(st);
  while(en<FCount-1)and(FinderFunct(FItems[en+1])=0)do inc(en);
end;

procedure THetArray<T>.ExpandRange(const idx:integer;const FinderFunct:TFinderFunctBool<T>;out st,en:integer);
begin InitUninitialized;
  Assert(IndexValid(idx),'THetArray<T>.ExpandRange: idx out of range');
  st:=idx;en:=idx;
  while(st>0)and FinderFunct(FItems[st-1])do dec(st);
  while(en<FCount-1)and FinderFunct(FItems[en+1])do inc(en);
end;

procedure THetArray<T>.ExpandRange(const idx:integer;const ComparerFunct:TComparerFunct<T>;out st,en:integer);
begin InitUninitialized;
  Assert(IndexValid(idx),'THetArray<T>.ExpandRange: idx out of range');
  st:=idx;en:=idx;
  while(st>0)and(ComparerFunct(FItems[idx],FItems[st-1])=0)do dec(st);
  while(en<FCount-1)and(ComparerFunct(FItems[idx],FItems[en+1])=0)do inc(en);
end;

function THetArray<T>.Find(const FinderFunct:TFinderFunctBool<T>;out Idx:integer):boolean;
var i:integer;
begin InitUninitialized;
  for i:=0 to FCount-1 do if FinderFunct(FItems[i]) then begin
    Idx:=i;exit(true);
  end;
  Idx:=-1;
  result:=false;
end;

function THetArray<T>.Find(const AItem:T;const ComparerFunct:TComparerFunct<T>;out Idx:integer):boolean;
var i:integer;
begin InitUninitialized;
  for i:=0 to FCount-1 do if ComparerFunct(AItem,FItems[i])=0 then begin
    Idx:=i;exit(true);
  end;
  Idx:=-1;
  result:=false;
end;

function THetArray<T>.FindRange(const FinderFunct:TFinderFunctBool<T>;out st,en:integer):boolean;
begin
  result:=Find(FinderFunct,st);
  if result then ExpandRange(st,FinderFunct,st,en)
            else begin st:=0;en:=-1;end;
end;

function THetArray<T>.FindRange(const AItem:T;const ComparerFunct:TComparerFunct<T>;out st,en:integer):boolean;
begin
  result:=Find(AItem,ComparerFunct,st);
  if result then ExpandRange(st,ComparerFunct,st,en)
            else begin st:=0;en:=-1;end;
end;

function THetArray<T>.FindBinary(const FinderFunct:TFinderFunct<T>;out Idx:integer):boolean;
var hi,lo,cmp:integer;
begin InitUninitialized;
  lo:=0;
  hi:=FCount-1;
  if hi<0 then begin
    Idx:=0;
    result:=false;
  end else begin
    repeat
      Idx:=(lo+hi)shr 1;
      cmp:=FinderFunct(FItems[Idx]);
      if cmp>0 then lo:=Idx+1
               else hi:=Idx-1;
    until(cmp=0)or(lo>hi);
    if cmp=0 then begin
      result:=true;
    end else begin
      if Cmp>0 then inc(Idx);
      result:=false;
    end;
  end;
end;

function THetArray<T>.FindBinary(const AItem:T;const ComparerFunct:TComparerFunct<T>;out Idx:integer):boolean;
var hi,lo,cmp:integer;
begin InitUninitialized;
  lo:=0;
  hi:=FCount-1;
  if hi<0 then begin
    Idx:=0;
    result:=false;
  end else begin
    repeat
      Idx:=(lo+hi)shr 1;
      cmp:=ComparerFunct(AItem,FItems[Idx]);
      if cmp>0 then lo:=Idx+1
               else hi:=Idx-1;
    until(cmp=0)or(lo>hi);
    if cmp=0 then begin
      result:=true;
    end else begin
      if Cmp>0 then inc(Idx);
      result:=false;
    end;
  end;
end;

function THetArray<T>.FindBinaryRange(const FinderFunct:TFinderFunct<T>;out st,en:integer):boolean;
begin
  result:=FindBinary(FinderFunct,st);
  if result then ExpandRange(st,FinderFunct,st,en)
            else begin st:=0;en:=-1;end;
end;

function THetArray<T>.FindBinaryRange(const AItem:T;const ComparerFunct:TComparerFunct<T>;out st,en:integer):boolean;
begin
  result:=FindBinary(AItem,ComparerFunct,st);
  if result then ExpandRange(st,ComparerFunct,st,en)
            else begin st:=0;en:=-1;end;
end;

function THetArray<T>.FindNewPosBinary(const AIdx:integer;const ComparerFunct:TComparerFunct<T>):integer;
var hi,lo,cmp,idx:integer;
    leftOK,rightOK:boolean;
    act:T;
begin InitUninitialized;
  result:=AIdx;
  if(AIdx<0)or(AIdx>=FCount)then exit;

  Act:=FItems[AIdx];
  leftOK:= (AIdx<=0)       or(ComparerFunct(FItems[AIdx-1],Act)<=0);
  rightOk:=(AIdx>=FCount-1)or(ComparerFunct(Act,FItems[AIdx+1])<=0);

  if not leftOK then begin
    lo:=0;hi:=AIdx-1;
  end else if not RightOk then begin
    lo:=AIdx+1;hi:=FCount-1;//right side
  end else
    exit;

  repeat
    result:=(lo+hi)shr 1;
    cmp:=ComparerFunct(Act,FItems[result]);
    if cmp>0 then lo:=result+1
             else hi:=result-1;
  until(cmp=0)or(lo>hi);
  if cmp>0 then inc(result);

  if result>AIdx then dec(result);
end;


procedure THetArray<T>.QuickSort(const ComparerFunct:TComparerFunct<T>;L,R:Integer);
var I,J:Integer;
    pivot,temp:T;
begin InitUninitialized;
  repeat
    I:=L;
    J:=R;
    pivot:=FItems[L+(R-L)shr 1];
    repeat
      while ComparerFunct(FItems[I],pivot)<0 do Inc(I);
      while ComparerFunct(FItems[J],pivot)>0 do Dec(J);
      if I<=J then begin
        if I <> J then begin
          temp:=FItems[I];
          FItems[I]:=FItems[J];
          FItems[J]:=temp;
        end;
        Inc(I);
        Dec(J);
      end;
    until I>J;
    if L<J then
      QuickSort(ComparerFunct,L,J);
    L:=I;
  until I>=R;
end;

procedure THetArray<T>.QuickSort(const ComparerFunct:TComparerFunct<T>);
begin InitUninitialized;
  if FCount>1 then
    QuickSort(ComparerFunct,0,FCount-1);
end;

procedure THetArray<T>.Distinct(const ComparerFunct: TComparerFunct<T>; AlreadySorted: boolean);
var i,j:integer;
begin
  if Count=0 then exit;
  if not AlreadySorted then
    QuickSort(ComparerFunct);
  j:=0;
  for i:=1 to Count-1 do if ComparerFunct(FItems[j],FItems[i])<>0 then begin
    inc(j);
    if i<>j then
      FItems[j]:=FItems[i];
  end;
  FCount:=j+1;
end;

procedure THetArray<T>.Shuffle;
var i,j:integer;
    temp:T;
begin InitUninitialized;
  for i:=0 to FCount-1 do begin
    j:=Random(FCount);
    temp:=FItems[i];
    FItems[i]:=FItems[j];
    FItems[j]:=temp;
  end;
end;

function THetArray<T>.InsertBinary(const AItem:T;const FinderFunct:TFinderFunct<T>;const InsertIfExists:boolean):integer;
begin InitUninitialized;
  if FindBinary(FinderFunct,result)and not InsertIfExists then exit;
  Insert(AItem,result);
end;

function THetArray<T>.InsertBinary(const AItem:T;const ComparerFunct:TComparerFunct<T>;const InsertIfExists:boolean):integer;
begin InitUninitialized;
  if FindBinary(AItem,ComparerFunct,result)and not InsertIfExists then exit;
  Insert(AItem,result);
end;

function THetArray<T>.IsEmpty: boolean;
begin InitUninitialized;
  result:=FCount=0;
end;

function THetArray<T>.IsSorted(const ComparerFunct: TComparerFunct<T>): boolean;
var i:integer;
begin InitUninitialized;
  result:=true;
  for i:=0 to FCount-2 do
    if ComparerFunct(FItems[i],FItems[i+1])>0 then exit(false);
end;

procedure THetArray<T>.ForEach(const AProc: TForEachProc<T>);
var i:integer;
begin
  for i:=0 to FCount-1 do AProc(FItems[i]);
end;

procedure THetArray<T>.SetItems(const AItems:TArray<T>);
begin
  FItems:=AItems;
  FCount:=Length(FItems);
end;

class operator THetArray<T>.Add(const AArray:THetArray<T>;const AItem:T):THetArray<T>;
begin
  result:=AArray;
  result.Append(AItem);
end;

class operator THetArray<T>.Add(const AArray1,AArray2:THetArray<T>):THetArray<T>;
begin
  result:=AArray1;
  result.Append(AArray2);
end;

{ THetArrayEnumerator<T> }

function THetArray<T>.GetEnumerator: THetArrayEnumerator<T>;
begin
  result:=THetArrayEnumerator<T>.Create(self);
end;

constructor THetArrayEnumerator<T>.Create(const AArray: THetArray<T>);
begin
  FArray:=@AArray;
  FIndex:=-1;
end;

function THetArrayEnumerator<T>.DoGetCurrent: T;
begin
  result:=THetArray<T>(FArray^).FItems[FIndex];
end;

function THetArrayEnumerator<T>.DoMoveNext: Boolean;
begin
  inc(FIndex);
  result:=(FIndex<THetArray<T>(FArray^).Count);
end;


{ TCache<T> }

constructor TCache<T>.Create(const ALoader: TLoaderFunct;const ARecentCacheSize: integer=0);
var i:integer;
begin
  inherited Create;
  FLoader:=ALoader;
  SetLength(FRecentCache,ARecentCacheSize);
  for i:=0 to high(FRecentCache)do FRecentCache[i].Hash:=0;
end;

procedure TCache<T>.Clear;
var i:integer;
begin
  with FList do for i:=FCount-1 downto 0 do FItems[i].Obj.Free;
  FList.Clear;
  for i:=0 to high(FRecentCache)do with FRecentCache[i]do begin Hash:=0;Obj:=nil;end;
end;

destructor TCache<T>.Destroy;
begin
  Clear;
  inherited;
end;

function TCache<T>.GetByName(const AName: AnsiString): T;
var idx,i:integer;
    cr:_TCacheRec;
begin
  cr.Hash:=Crc32UC(AName);
  //1. recent cache
  for i:=0 to High(FRecentCache)do if FRecentCache[i].Hash=cr.Hash then
    exit(T(cr.Obj));
  //2. normal cache
  if FList.FindBinary(function(const a:_TCacheRec):integer begin result:=a.Hash-cr.Hash end,idx)then begin
    result:=T(FList.FItems[idx].Obj);
  end else begin//3. load
    result:=FLoader(AName);//can throw exceptions
    cr.Obj:=result;FList.Insert(cr,idx)
  end;
  //4. put in recentcache
  if FRecentCache<>nil then begin
    for i:=high(FRecentCache)downto 1 do FRecentCache[i]:=FRecentCache[i-1];
    FRecentCache[0]:=FList.FItems[idx];
  end;
end;

end.
