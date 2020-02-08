Unit FStream;interface uses sysutils,Het.utils,math;{$I-} //header
type Ba=array[0..0]of byte;

Const FSBlockShl=15;
      FSBlockSize=1 shl FSBlockShl;
      FSBlockMask=FSBlockSize-1;
      FSMaxBlock=1 shl 13;{maximum filesize=16m}
      fsChange=32;
      smallblocksize=8192;
{      MaxBlocks=64;}{not used yet}
      LowMem=100000;{ennyi memoriat hagy masra}

Type TFSBlock=array[0..FSBlockSize-1]of byte;
     PFSBlock=^TFSBlock;

Type PFileStream=^TFileStream;
     TFileStream=Object
       Pos,Size:Integer;
       Success,Opened:boolean;
       NewBlock:PFSBlock;
       fname:ansistring;
       cached:boolean;
     private
       BitOffset:integer;
       f:file;
       blocks:array[0..FSMaxBlock]of PFSBlock;
       CurByte:Byte;

       NewBlockNum,NewBlockpos:word;NewBlockSeek:integer;
       BlocksLoaded:integer;
       Procedure TryOpen;
     public
       Constructor Init;
       Function Open(name:ansistring):boolean;
       Function OpenMemory(const AData:ansistring):boolean;
       Procedure Seek(p:Integer);
       Function BlockRead(var buf;len:integer):boolean;
       Function Get1Bit:integer;
       Function GetBits(n:integer):integer;
       function SStell:Integer;
       Procedure Close;
       Procedure Update;
       Function Display(n,maxn:integer):integer;
       Destructor Done;virtual;
     end;

implementation
{$I-}
Function TFileStream.Display;
var po,n1:integer;
begin
  Display:=0;
  if(maxn<=0)or(size shr FSBlockShl<=0)then exit;
  po:=round(Pos/size*maxn);
  if (n=po)then Display:=2 else begin
    n1:=integer(n)*integer(size shr FSBlockShl)div maxn;
    if cached and(n1>=0)and(n1<FSMaxBlock)then
      if Blocks[n1]=nil then Display:=0 else Display:=1;
  end;
end;

var LastCache:PFileStream=nil;
    LastCount:Longint=0;

Procedure TFileStream.TryOpen;var c:char;
var om:integer;
begin
  if Opened then exit;
  if copy(fname,1,2)='*:'then for c:='C' to 'Z' do begin
    assign(f,c+copy(fname,2,255));
    Reset(f,1);
    Opened:=IOResult=0;
    if Opened then break;
  end else begin
    assignfile(f,fname);
    om:=FileMode;FileMode:=fmOpenRead;Reset(f,1);FileMode:=om;
    Opened:=IOResult=0;
  end;
  if Opened then begin
    Size:=System.FileSize(f);
    Cached:=Size<16*1024*1024;
  end;
  Ranger(0,Size,FSMaxBlock*FSBlockSize);
end;

Constructor TFileStream.Init;
begin
  opened:=false;fname:='nofile.dss';assign(f,fname);
  fillchar(Blocks,sizeof(blocks),0);
  NewBlock:=nil;BlocksLoaded:=0;
end;

Function TFileStream.Open;
begin
  Close;
  fname:=Name;
  assign(f,Name);
  Pos:=0;Size:=0;
  TryOpen;
  Open:=true;
end;

Function TFileStream.OpenMemory;
var i:integer;
begin
  Close;
  fname:='@memory';

  Pos:=0;Size:=Length(AData);

  for i:=0 to min(FSMaxBlock,(Length(AData)+FSBlockMask)shr FSBlockShl)-1 do begin
    New(Blocks[i]);
    move(AData[i shl FSBlockShl+1],Blocks[i]^,min(length(AData)-i shl FSBlockShl,FSBlockSize));
    inc(BlocksLoaded);
  end;

  Opened:=true;
  cached:=true;
  result:=true;
end;

Procedure TFileStream.Seek;
begin
  Ranger(0,P,Size);pos:=p;BitOffset:=7;
end;

Function TFileStream.BlockRead;
var bufpos,o,o0,o1:integer;
    bl,bl0,bl1:integer;
    bu:PFSBlock;
begin
  if cached then begin
    result:=false;Success:=false;BitOffset:=7;
    bufpos:=0;
    if(pos<0)or(pos>=size)then exit;
    bl0:=pos shr FSBlockShl;bl1:=(Pos+Len-1)shr FSBlockShl;
    for bl:=bl0 to bl1 do begin
      bu:=Blocks[bl];if(bu=nil)then exit;
      if bl=bl0 then o0:=pos and FSBlockMask else o0:=0;
      if bl=bl1 then o1:=(pos+Len-1)and FSBlockMask else o1:=FSBlockMask;
      o:=o1-o0+1;
      system.move(bu^[o0],ba(buf)[bufpos],o);
      bufpos:=bufpos+o;
    end;
    pos:=pos+Len;
    Success:=true;
    Result:=success;
  end else begin
    result:=false;Success:=false;BitOffset:=7;
    if(pos<0)or(pos>=size)then exit;
    system.Seek(f,pos);
    system.blockread(f,buf,Len,bl);
    result:=Len=bl;success:=result;
    pos:=pos+len;
  end;
end;

Procedure TFileStream.Close;
var i:integer;
begin
  if not opened then exit;
  if NewBlock<>nil then begin
    Dispose(NewBlock);
    NewBlock:=nil;
  end;
  Opened:=false;

  if fname<>'@memory' then
    system.close(f);

  fname:='nofile.nws';
  assign(f,fname);
  for i:=0 to FSMaxBlock-1 do if Blocks[i]<>nil then begin
    Dispose(Blocks[i]);Blocks[i]:=nil
  end;
  BlocksLoaded:=0;
end;

Destructor TFileStream.Done;
begin
  Close;
  fname:='';
  if LastCache=@self then LastCache:=nil;
end;


Procedure TFileStream.Update;
var maxbl:integer;
    free:PFSBlock;
Function Load(i:integer):boolean;
begin
  Load:=false;if NewBlock<>nil then exit;
  if not opened then exit;
  if(i<0)or(i>=FSMaxBlock)then exit;
  if Blocks[i]<>nil then exit;
{  if maxavail<sizeof(NewBlock^)then exit;}

  NewBlockSeek:=Integer(i)shl FSBlockShl;
  if free=nil then begin New(newBlock);inc(blocksloaded) end else begin NewBlock:=free;free:=nil;end;
  NewBlockPos:=0;NewBlockNum:=i;
  Load:=true;
end;

var bl,i:integer;w:integer;
label megse;
begin
  if not Opened then TryOpen;
  if not Opened then exit;
  if not cached then exit;
  if NewBlock<>nil then begin
    system.Seek(f,NewBlockSeek);
    if IOResult=0 then system.Blockread(f,NewBlock^[NewBlockPos],smallblocksize,w);
    if IOResult<>0 then begin Dispose(NewBlock);NewBlock:=nil;system.close(f);opened:=false;BlocksLoaded:=0;exit end;
    NewBlockSeek:=NewBlockSeek+smallblocksize;
    NewBlockPos:=NewBlockPos+smallblocksize;
    if NewBlockPos>=FSBlockSize then begin
      Blocks[NewBlockNum]:=NewBlock;{ <----lehet, hogy alatta jon az interrupt...!!!!!!!!!!!!! }
      NewBlock:=nil;
    end;
  end else begin
    if pos<0 then pos:=0;
    bl:=pos shr FSBlockShl;if bl>=FSMaxBlock then bl:=FSMaxBlock-1;
    maxbl:=size shr FSBlockShl;if maxbl>=FSMaxBlock then maxbl:=FSMaxBlock-1;if maxbl<0 then exit;
    free:=nil;
    if {MaxAvail<LowMem}false{!!!} then begin
      for i:=0 to bl-16 do if Blocks[i]<>nil then begin
        free:=Blocks[i];Blocks[i]:=nil;break;end;
      if free=nil then for i:=maxbl downto bl+128 do if Blocks[i]<>nil then begin
        free:=Blocks[i];Blocks[i]:=nil;break;end;
      if free=nil then exit;
    end;
    if (bl>MaxBl)then exit;
    if(lastCache=nil)or(LastCache=@self)or(LastCount>FSChange)or(Blocks[bl]=nil)then begin
      if LastCache<>@Self then begin
        if(LastCache<>nil)and(LastCache^.NewBlock<>nil)then begin
          Dispose(LastCache^.NewBlock);
          LastCache^.NewBlock:=nil;{too agresive...}
          Dec(LastCache^.BlocksLoaded);
        end;
        LastCache:=@Self;LastCount:=0;
      end;
      inc(LastCount);
      if Load(bl)then exit;
      for i:=bl+1 to maxbl do if load(i)then exit;
      LastCache:=nil;LastCount:=0;
    end;
    if Free<>nil then begin Dispose(Free);Free:=nil;dec(BlocksLoaded);end;
  end;
end;

Function TFileStream.Get1bit;
const bitmask:array[0..7]of byte=($01,$02,$04,$08,$10,$20,$40,$80);
begin
  if BitOffset=7 then
    blockread(curByte,1);
  if CurByte and Bitmask[BitOffset]=0 then
    Get1Bit:=0
  else
    Get1Bit:=1;
  dec(BitOffset);
  if BitOffset<0 then BitOffset:=7;
end;

Function TFileStream.GetBits;
var l:integer;
begin
  l:=0;
  for n:=1 to n do begin
    l:=l shl 1;
    if get1bit<>0 then l:=l or 1;
  end;
  GetBits:=l;
end;

function TFileStream.SStell;
begin
 if BitOffset=7 then SSTell:=(Pos)shl 3
 else SSTell:=(Pos)shl 3-1-BitOffset;
end;

end.
