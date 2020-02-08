unit UModelPart;

interface
uses windows, Sysutils, Het.Objects, het.utils, dialogs, TypInfo, opengl1x,
  Het.Textures, Het.Gfx, UVector, UMatrix;

type
  TDrawOption=(doNoTextures,doPushNames,doDrawNormals,doTransparentOnly,doOpaqueOnly,doPass2,doPass3,doNoLighting);
  TDrawOptions=set of TDrawOption;

  PV3f=^TV3f;
  PV2f=^TV2f;
  PM44f=^TM44f;

type
  TTransformationF=class(THetObject)
  public
    FM00,FM01,FM02,FM03,
    FM10,FM11,FM12,FM13,
    FM20,FM21,FM22,FM23,
    FM30,FM31,FM32,FM33:single;
    function M:PM44f;inline;
    procedure AfterCreate;override;
    function Position:TV3f;
  published
    property M00:single read FM00 write FM00;
    property M01:single read FM01 write FM01;
    property M02:single read FM02 write FM02;
    property M10:single read FM10 write FM10;
    property M11:single read FM11 write FM11;
    property M12:single read FM12 write FM12;
    property M20:single read FM20 write FM20;
    property M21:single read FM21 write FM21;
    property M22:single read FM22 write FM22;
    property M30:single read FM30 write FM30;
    property M31:single read FM31 write FM31;
    property M32:single read FM32 write FM32;
  end;

  TVertex=class(THetObject)
  private
    FVx,FVy,FVz,FNx,FNy,FNz,FTx,FTy:single;
  public
    procedure glDraw;
    function V:PV3f;inline;
    function N:PV3f;inline;
    function T:PV2f;inline;
  published
    property Vx:single read fVx write fVx;
    property Vy:single read fVy write fVy;
    property Vz:single read fVz write fVz;

    property Nx:single read fNx write fNx;
    property Ny:single read fNy write fNy;
    property Nz:single read fNz write fNz;

    property Tx:single read fTx write fTx;
    property Ty:single read fTy write fTy;
  end;

  TVertexArray=array of TVertex;

  TVertices=class(THetList<TVertex>)
  public
    function Add(const _v, _n: TV3f; const _t: TV2F):TVertex;
    function Find(const _v,_n:TV3f;const _t:TV2F):TVertex;
    function FindAdd(const _v,_n:TV3f;const _t:TV2F):TVertex;
    property ByIndex;default;
  end;

  TFace=class(THetObject)
  private
    FVertices:array[0..3]of TVertex;
    FNextP0:byte; {0..3: Optimize order allitja be, a kovetkezo face ezeket a pontokat fogja alapul venni; tomoritesnel lesz ertelme}
    procedure SetVertex0(const Value: TVertex);
    procedure SetVertex1(const Value: TVertex);
    procedure SetVertex2(const Value: TVertex);
    procedure SetVertex3(const Value: TVertex);
    function GetVertex(const idx: integer): TVertex;
    procedure SetVertex(const idx: integer; const Value: TVertex);
  public
    function getLookupList(const PropInfo:PPropInfo):THetObjectList;override;

    function Valid:boolean;
    procedure glDraw;

    property Vertex[const idx:integer]:TVertex read GetVertex write SetVertex;
    function IsTriangle:boolean;
    function IsQuad:boolean;
    function Count:integer;
    procedure SetFirstVertex(n:integer);
    function FindVertex(const V:TVertex):integer;overload;
    function FindVertex(const V:TV3F):integer;overload;
    function FindNormal(const N:TV3F):integer;
    function FindTexCoord(const T:TV2F):integer;
    function FindEdge(const V0,V1:TVertex):integer;overload;
    function FindEdge(const V0,V1:TV3F):integer;overload;
    function NearestVertex(const V:TV3F):integer;
    function NearestEdge(const V:TV3F):integer;
    function PickNearestThing(const V:TV3F):integer;                  // vertex 0..3, edge 4..7, face 8
    function PickNearestThingVertexArray(const V:TV3F):TVertexArray;  //ugyanaz, csak arra of vertexet ad vissza

    function Normal: TV3F;
    function RayIntersectPoint(const rayStart,rayPoint:TV3F;out Intersection:TV3F):boolean;
    function RayIntersectDist(const rayStart,rayPoint:TV3F;out distance:single):boolean;
    property NextP0:byte read FNextP0;
  published
    property Vertex0:TVertex read FVertices[0] write SetVertex0;
    property Vertex1:TVertex read FVertices[1] write SetVertex1;
    property Vertex2:TVertex read FVertices[2] write SetVertex2;
    property Vertex3:TVertex read FVertices[3] write SetVertex3;
  end;

  TFaceGroup=class(THetList<TFace>)
  private
    FVertices:TVertices;
    FMaterial:ansistring;
    FCompressedData:ansistring;
    FList:GLenum;
    procedure SetMaterial(const Value: ansistring);
    procedure SetCompressedData(const Value: ansistring);
    function GetCompressed: boolean;
    procedure SetCompressed(const Value: boolean);
  public
    function getLookupList(const PropInfo:PPropInfo):THetObjectList;override;

    procedure glDraw(Const Options:TDrawOptions);
    procedure ClearFacesAndVertices;
    procedure ClearInvalidFaces;
    procedure MakeQuads;
    procedure MakeTriangles;
    function CalcAbsBounds(fromFaces:boolean):TV3f;
    procedure OptimizeOrder;

    procedure Compress;
    procedure UnCompress;

    function FindNearestFaceByRay(const rayStart,rayPoint:tv3f):TFace;
  published
    property Material:ansistring read FMaterial write SetMaterial;
    property Vertices:TVertices read FVertices;
    property CompressedData:ansistring read FCompressedData write SetCompressedData;
    property Compressed:boolean read GetCompressed write SetCompressed stored false;
  end;

  TFaceGroups=class(THetList<TFaceGroup>)
  private
    FLodLevel:single;
    function GetCompressed: boolean;
    procedure SetCompressed(const Value: boolean);
  public
    procedure glDraw(const Options:TDrawOptions);
    function FindNearestFaceByRay(const rayStart, rayPoint: tv3f): TFace;
    function VertexCount:integer;
    function FaceCount:integer;
    function UsedMaterialNames: ansistring;
    procedure ClearInvalidFacesAndVertices;
    procedure Compress;
  published
    property LodLevel:single read FLodLevel write FLodLevel;
    property Compressed:boolean read GetCompressed write SetCompressed stored false;
  end;

  TPart=class;

  TSubPart=class(THetObject)
  private
    FName:ansistring;
    FPartName:ansistring;
    FPart:TPart;
    FDefaultTrans:TTransformationF;
    procedure SetName(const Value: ansistring);
    procedure SetPartName(const Value: ansistring);
    procedure SetIt(const Value:ansistring);
  public
    function getLookupList(const PropInfo:PPropInfo):THetObjectList;override;
    procedure GlDraw(const ADrawOptions: TDrawOptions);
    function Stats(const Indent:ansistring=''):AnsiString;
    function OwnerPart:TPart;inline;
    property Part:TPart read FPart;
  published
    property Name:ansistring read FName write SetName;
    property DefaultTrans:TTransformationF read FDefaultTrans;
    property PartName:ansistring read FPartName write SetPartName;
  end;

  TSubParts=class(THetList<TSubPart>)
  public
    property ByIndex;default;
  end;

  TPart=class(THetList<TFaceGroups>)
  private
    FName:ansistring;
    FFileName:ansistring;
    FHash:integer;
    FSubParts:TSubParts;
    FLocalTextureCache:TTextureCache;
    procedure SetName(const Value: ansistring);
    procedure SetFileName(const Value: ansistring);
    procedure SetHash(const Value: integer);
    function GetCompressed: boolean;
    procedure SetCompressed(const Value: boolean);
    function LocalTextureCache:TTextureCache;
  public
    procedure glDraw(const ADrawOptions:TDrawOptions);
    function Stats(const indent:ansistring=''):AnsiString;
    procedure ClearInvalidFacesAndVertices;
  published
    property Name:ansistring read FName write SetName;
    property FileName:ansistring read FFileName write SetFileName stored false;
    property Hash:integer read FHash write SetHash stored false;
    property SubParts:TSubParts read FSubParts;
    property Compressed:boolean read GetCompressed write SetCompressed stored false;
  end;

  TParts=class(THetList<TPart>)
  public
    function AccessPart(const AFileName,AOwnerFileName:ansistring):TPart;
  end;

(*  TModel=class(THetObject)//encapulate all things
  private
    FName:ansistring;
    FRootPart:TSubPart;
    procedure SetName(const Value: ansistring);
  public
    procedure ForEachSubPart(const proc:TProc<TSubPart>);
    function SubParts: TArray<TSubPart>;
    function Parts:TArray<TPart>;
    function Materials:TArray<ansistring>;
    function Dump:ansistring;
    procedure ClearInvalidFacesAndVertices;
    procedure GlDraw(Const Options:TDrawOptions);
  published
    property Name:ansistring read FName write SetName;
    property Root:TSubPart read FRootPart;
  end;*)

var
  ModelTexturePath:ansistring;

var
  PartCache:TParts;

implementation

uses UModelCompressor, het.FileSys;

{ TTransformationF }

function TTransformationF.M:PM44f;
begin
  result:=@M00;
end;

function TTransformationF.Position: TV3f;
begin
  result:=v3f(FM30,FM31,FM32);
end;

procedure TTransformationF.AfterCreate;
begin
  inherited;
  FM00:=1;
  FM11:=1;
  FM22:=1;
  FM33:=1;
end;

{ TVertex }

procedure TVertex.glDraw;
begin
  glNormal3fv(@Nx);
  glTexCoord2fv(@Tx);
  glVertex3fv(@Vx);
end;

function TVertex.N: PV3f;
begin
  result:=@Nx;
end;

function TVertex.T: PV2f;
begin
  result:=@Tx;
end;

function TVertex.V: PV3f;
begin
  result:=@Vx;
end;

{ TVertices }

function TVertices.Find(const _v, _n: TV3f; const _t: TV2F): TVertex;
var i:integer;
const VSmall=1/1024;NSmall=1/127;TSmall=1/2048;
begin
  for i:=Count-1 downto 0 do with ByIndex[i]do if(VDistManh(V^,_V)<VSmall)and(VDistManh(N^,_N)<NSmall)and(VDistManh(T^,_T)<TSmall)then
    exit(ByIndex[i]);
  result:=nil;
end;

function TVertices.Add(const _v, _n: TV3f; const _t: TV2F): TVertex;
begin
  result:=TVertex.Create(self);
  result.V^:=_v;
  result.N^:=_n;
  result.T^:=_t;
end;

function TVertices.FindAdd(const _v, _n: TV3f; const _t: TV2F): TVertex;
begin
  result:=Find(_v,_n,_t);
  if result=nil then begin
    result:=TVertex.Create(self);
    result.V^:=_v;
    result.N^:=_n;
    result.T^:=_t;
  end;
end;

//                                                                              //
{ TFace }

function TFace.getLookupList(const PropInfo:PPropInfo):THetObjectList;
begin
  if GetTypeData(PropInfo.PropType^).ClassType=TVertex then result:=TFaceGroup(FOwner).Vertices
                                else result:=nil;
end;

function TFace.GetVertex(const idx: integer): TVertex;
begin
  result:=FVertices[idx];
end;

procedure TFace.SetVertex(const idx: integer; const Value: TVertex);
begin
  FVertices[idx]:=Value;
//  SetField(@FVertices[idx],Value);
end;

procedure TFace.glDraw;

  procedure n(v:tvertex);
  var no1,no2:TV3F;
  begin
    glColor3f(0,0,0);
    glVertex3fv(@v.Vx);
    no1:=v.v^+v.n^;
    no2:=no1+v3f(0.03,0,0);
    no1:=no1-v3f(0.03,0,0);
    glvertex3fv(@no1);
    glvertex3fv(@no2);
    glvertex3fv(@no2);
    glColor3f(1,1,1);
  end;

begin
  if not Valid then exit;

  Vertex0.glDraw;
  Vertex1.glDraw;
  Vertex2.glDraw;
  if Vertex3<>nil then Vertex3.glDraw
                  else Vertex2.glDraw;

{  n(Vertex0);n(Vertex1);n(Vertex2);
  if vertex3<>nil then n(Vertex3);}
end;

{$O-}
procedure TFace.SetVertex0(const Value: TVertex);begin end;
procedure TFace.SetVertex1(const Value: TVertex);begin end;
procedure TFace.SetVertex2(const Value: TVertex);begin end;
procedure TFace.SetVertex3(const Value: TVertex);begin end;
{$O+}

function TFace.Valid: boolean;
begin
  result:=(Vertex0<>nil)and(Vertex1<>nil)and(Vertex2<>nil)and
          (Vertex0<>Vertex1)and(Vertex0<>Vertex2)and(Vertex0<>Vertex3)and
          (Vertex1<>Vertex2)and(Vertex1<>Vertex3)and
          (Vertex2<>Vertex3);
end;

function TFace.IsQuad: boolean;
begin result:=valid and (Vertex3<>nil);end;

function TFace.IsTriangle: boolean;
begin result:=valid and (Vertex3=nil);end;

procedure TFace.SetFirstVertex(n: integer);
var tmp:array[0..3]of TVertex;
    i:integer;
begin
  if n<=0 then exit;
  for i:=0 to 3 do tmp[i]:=vertex[i];
  if IsTriangle then begin
    for i:=0 to 2 do Vertex[i]:=tmp[(i+n)mod 3];
  end else
    for i:=0 to 3 do Vertex[i]:=tmp[(i+n)mod 4];
end;

function TFace.Count: integer;
begin
  if IsQuad then result:=4 else
  if IsTriangle then result:=3
                else result:=0;
end;

function TFace.FindVertex(const V: TV3F): integer;var i:integer;
begin for i:=0 to Count-1 do if V=Vertex[i].V^ then begin result:=i;exit end; result:=-1;end;

function TFace.FindVertex(const V: TVertex): integer;var i:integer;
begin for i:=0 to Count-1 do if V=Vertex[i] then begin result:=i;exit end; result:=-1;end;

function TFace.FindNormal(const N: TV3F): integer;var i:integer;
begin for i:=0 to Count-1 do if N=Vertex[i].N^ then begin result:=i;exit end; result:=-1;end;

function TFace.FindTexCoord(const T: TV2F): integer;var i:integer;
begin for i:=0 to Count-1 do if T=Vertex[i].T^ then begin result:=i;exit end; result:=-1;end;

function TFace.FindEdge(const V0, V1: TVertex): integer;var i,cnt:integer;
begin
  cnt:=count;for i:=0 to cnt-1 do if(Vertex[i]=V0)and(Vertex[(i+1)mod cnt]=V1)then begin result:=i;exit;end;result:=-1;
end;

function TFace.FindEdge(const V0, V1: TV3F): integer;var i,cnt:integer;
begin
  cnt:=count;for i:=0 to cnt-1 do if(Vertex[i].V^=V0)and(Vertex[(i+1)mod cnt].V^=V1)then begin result:=i;exit;end;result:=-1;
end;

function TFace.NearestEdge(const V: TV3F): integer;var i,cnt:integer;d,mind:single;
begin
  cnt:=count;result:=-1;mind:=1e30;
  for i:=0 to cnt-1 do begin
    d:=PointSegmentDistance(V,Vertex[i].V^,Vertex[(i+1)mod cnt].V^);
    if d<mind then begin mind:=d;result:=i;end;
  end;
end;

function TFace.NearestVertex(const V:TV3F):integer;var i:integer;
var d,mind:single;
begin
  result:=-1;mind:=0;
  for i:=0 to count-1 do begin
    d:=VDistSqr(V,Vertex[i].V^);
    if(d<mind)or(i=0)then begin
      result:=i;mind:=d;
    end;
  end;
end;

function TFace.PickNearestThing(const V: TV3F): integer;
var maxSegmentDistance,mind,d:single;
    i,cnt:integer;
    onEdge:array[0..4]of boolean;
begin
  result:=8;//0..3:vertex, 4..7:edge 8:face
  if not valid then exit;
  mind:=1e30;cnt:=count;
  for i:=0 to cnt-1 do begin
    d:=VDistSqr(Vertex[i].V^,Vertex[(i+1)mod cnt].V^);
    if mind>d then mind:=d;
  end;
  maxSegmentDistance:=sqrt(mind)*0.25;
  for i:=0 to cnt-1 do
    onEdge[i]:=PointSegmentDistance(V,Vertex[i].V^,Vertex[(i+1)mod cnt].V^)<maxSegmentDistance;
  //point?
  for i:=0 to cnt-1 do if onEdge[i]and onEdge[(i+1)mod cnt] then begin result:=i;exit end;
  //edge?
  for i:=0 to cnt-1 do if onEdge[i]then begin result:=i+4;exit end;
  //else face
end;

function TFace.PickNearestThingVertexArray(const V: TV3F): TVertexArray;
var res,cnt,i:integer;
begin
  SetLength(Result,0);
  if not Valid then exit;
  res:=PickNearestThing(V);
  cnt:=Count;
  case res of
    0..3:setlength(result,1);
    4..7:setlength(result,2);
    8:setlength(result,cnt);
  end;
  res:=res and 3;
  for i:=0 to high(result)do result[i]:=Vertex[(i+res)mod cnt];
end;

function TFace.Normal:TV3F;
begin
  if count>=3 then result:=VNormalize(VCross(Vertex1.v^-Vertex0.v^,Vertex2.v^-Vertex0.v^));
end;

function TFace.rayIntersectPoint(const rayStart,rayPoint:TV3F;out Intersection:TV3F):boolean;
var rayDir:TV3F;
begin
  result:=false;
  rayDir:=rayPoint-rayStart;
  if VDot(rayDir,Normal)>0 then exit;
  if count>=3 then if RayCastTriangleIntersect(rayStart,rayDir,Vertex0.V^,Vertex1.V^,Vertex2.V^,Intersection)then begin
    result:=true;exit;end;
  if count=4 then  if RayCastTriangleIntersect(rayStart,rayDir,Vertex0.V^,Vertex2.V^,Vertex3.V^,Intersection)then begin
    result:=true;exit;end;
end;

function TFace.rayIntersectDist(const rayStart,rayPoint:TV3F;out distance:single):boolean;
var Intersection:TV3F;
begin
  Result:=RayIntersectPoint(rayStart,rayPoint,Intersection);
  if result then distance:=VDist(rayPoint,Intersection);
end;

{ TFaceGroup }

procedure TFaceGroup.SetMaterial(const Value: ansistring);
begin
  if FMaterial<>Value then begin
    FMaterial:=value;NotifyChange
  end;
end;

function TFaceGroup.getLookupList(const PropInfo: PPropInfo): THetObjectList;
begin
  result:=nil;
end;

procedure TFaceGroup.glDraw(const Options:TDrawOptions);var i:integer;

  var cancel:boolean;

  procedure ApplyObjMaterial(const def:ansistring);
  var line:ansistring;

    function readV:TV4f;
    var i:integer;
    begin with result do begin
      for i:=0 to 2 do Coord[i]:=StrToFloatDef(listitem(line,i+1,' '),0);
      w:=1;
    end;end;

    function readF:single;
    begin
      result:=StrToFloatDef(listitem(line,i+1,' '),0);
    end;

    function readS:ansistring;
    begin
      result:=copy(line,pos(' ',line)+1);
    end;

  var Ka,Kd,Ks,Ke,Tf:TV4f;
      Ns{spec param}:single;
      //Ni{refraction}:single;
      Map_Kd:ansistring;
      id:ansistring;
      tmp:TV4f;
      pass:integer;
  begin
    glDisable(GL_COLOR_MATERIAL);
    pass:=1;
    if doPass2 in Options then pass:=2;
    if doPass3 in Options then pass:=3;

    Ka:=V4f(0,0,0,1);Kd:=V4f(1,1,1,1);Ks:=V4f(0,0,0,1);Ke:=V4f(0,0,0,1);
    {Ni:=1;}Ns:=1;
    map_kd:='';

    for line in ListSplit(def,#10)do begin
      id:=lc(listitem(line,0,' '));
      if id='ka' then Ka:=readV else
      if id='kd' then Kd:=readV else
      if id='ks' then Ks:=readV else
      if id='tf' then Tf:=readV else
//      if id='ni' then Ni:=readF else
      if id='ns' then Ns:=readF else
      if id='map_kd' then map_kd:=readS else
      ;
    end;

    Ka:=V4f(0.1,0.1,0.1,1)*0.5;

    if(doTransparentOnly in Options)and(Tf.x=1)
    or(doOpaqueOnly in Options)and(Tf.x<1)
      then begin Cancel:=true;exit end;

    if Map_kd<>'' then begin
      if pass=1 then begin //duffuse color*texture
        TPart(FOwner.FOwner).LocalTextureCache[Map_kd].Bind(0,rfLinearMipmapLinear,false);

        glDisable(GL_TEXTURE_GEN_S);
        glDisable(GL_TEXTURE_GEN_T);
        glTexEnvf(GL_TEXTURE_ENV,GL_TEXTURE_ENV_MODE,GL_MODULATE);

        glActiveTextureARB(GL_TEXTURE0_ARB);
        Ka:=v4f(0,0,0,1);
        Kd:=v4f(1,1,1,1);//diff=tex
        Ks:=v4f(0,0,0,1);//no spec
        glEnable(GL_LIGHTING);
      end else if pass=2 then begin //specularColor
        glActiveTextureARB(GL_TEXTURE0_ARB);
        glDisable(GL_TEXTURE_2D);

        Kd:=v4f(0,0,0,1);//diff=0
        Ks:=Ks*Tf;
        glEnable(GL_LIGHTING);
     end;
    end else begin
      glDisable(GL_TEXTURE_2D);
      glEnable(GL_LIGHTING);
      if pass=1 then begin
        Ka:=v4f(0,0,0,1);
        Ks:=v4f(0,0,0,1);
        glEnable(GL_LIGHTING);
      end else if pass=2 then begin //specularColor
        Kd:=v4f(0,0,0,1);//diff=0
        Ks:=Ks*Tf;
        glEnable(GL_LIGHTING);
      end;
    end;

    if pass=3 then begin
      TextureCache['EnvMap'].Bind(0,rfLinearMipmapLinear,false);
      glTexGeni(GL_S, GL_TEXTURE_GEN_MODE, GL_SPHERE_MAP);glEnable(GL_TEXTURE_GEN_S);
      glTexGeni(GL_T, GL_TEXTURE_GEN_MODE, GL_SPHERE_MAP);glEnable(GL_TEXTURE_GEN_T);
      glTexEnvf(GL_TEXTURE_ENV,GL_TEXTURE_ENV_MODE,GL_MODULATE);
      tmp:=Ks*0.15;
      glColor4fv(@tmp);
      glDisable(GL_LIGHTING);
    end;

    glMaterialfv(GL_FRONT,GL_EMISSION,@Ke);
    glMaterialfv(GL_FRONT,GL_AMBIENT ,@Ka);
    glMaterialfv(GL_FRONT,GL_DIFFUSE ,@Kd);
    glMaterialfv(GL_FRONT,GL_SPECULAR,@Ks);
    glMaterialf(GL_FRONT,GL_SHININESS,(128/(Ns+1)));

    if pass in[2,3] then begin
      glEnable(GL_BLEND);
      glBlendFunc(GL_ONE,GL_ONE);
    end else
      if Tf.x=1 then begin
        glDisable(GL_BLEND)
      end else begin
        glEnable(GL_BLEND);
        with tf do glBlendColor(x,y,z,w);
        glBlendFunc(GL_CONSTANT_COLOR,GL_ONE_MINUS_CONSTANT_COLOR);
      end;

    if doNoLighting in Options then begin
      glDisable(GL_LIGHTING);
      if pass=2 then cancel:=true;
    end;
  end;

var tmp:TV3f;
begin
  cancel:=false;
  if not(doNoTextures in Options)then begin
    if cmp(copy(Material,1,7),'newmtl ')=0 then begin
      ApplyObjMaterial(Material);
    end else if Material<>'' then
      TextureCache[Material].Bind(0,rfLinearMipmapLinear,false)
    else
      glDisable(GL_TEXTURE_2D);
  end;

  if cancel then exit;

  if doPushNames in Options then begin
    for i:=0 to count-1 do begin
      glBegin(GL_Quads);
      glPushName(cardinal(ByIndex[i]));
      ByIndex[i].glDraw;
      glPopName;
      glEnd;
    end;
  end else begin
    if FList=0 then begin
      FList:=glGenLists(1);
      glNewList(FList,GL_COMPILE);
      if Compressed then
        GlUnCompressFacegroup(CompressedData)
      else begin
        glBegin(GL_Quads);
        for i:=0 to count-1 do
          ByIndex[i].glDraw;
        glEnd;
      end;
      glEndList;
    end;
    glCallList(FList);
  end;

  if doDrawNormals in Options then begin
    glBegin(GL_LINES);
    for i:=0 to count-1 do with ByIndex[i].Vertex0 do begin
      glVertex3fv(@Vx);
      tmp:=V^+N^;
      glVertex3fv(@tmp);
    end;
    glEnd;
  end;
end;

procedure TFaceGroup.ClearInvalidFaces;var i:integer;
begin
  for i:=count-1 downto 0 do if not ByIndex[i].Valid then ByIndex[i].Free;
end;

procedure TFaceGroup.ClearFacesAndVertices;
begin
  Clear;
  Vertices.Clear;
end;

function TFaceGroup.CalcAbsBounds(fromFaces: boolean): TV3f;
var i,j:integer;
begin
  result:=V3F(0,0,0);
  if fromFaces then for i:=0 to Count-1 do with ByIndex[i] do for j:=0 to count-1 do result:=VMax(result,VAbs(Vertex[j].V^))
               else with Vertices do for i:=0 to Count-1 do with ByIndex[i]do result:=VMax(result,VAbs(V^));
end;

procedure TFaceGroup.MakeQuads;

type TEdge=record v:array[0..1]of TVertex;f:array[0..1]of TFace;score:single end;
var edges:array of tedge;
    edgecount:integer;
    edgetemp:TEdge;

  procedure findaddedge(V0,V1:tvertex;Face:TFace);
  var i:integer;
  begin
    if(V0=nil)or(V0=nil)or(V0=V1)then exit;
    for i:=edgecount-1 downto 0 do with edges[i]do if(v[0]=V1)and(v[1]=V0)then begin
      f[1]:=Face;
      exit;
    end;
    Inc(edgecount);
    with edges[edgecount-1]do begin
      v[0]:=v0;v[1]:=v1;
      f[0]:=face;
      f[1]:=nil;
      score:=0;
    end;
  end;

  function edgeAligned(va,vb:TVertex):integer;
  begin result:=ord(va.V.x=vb.V.x)+ord(va.V.y=vb.V.y)+ord(va.V.z=vb.V.z);end;

  function faceAligned(f:TFace):integer;
  begin result:=edgeAligned(f.Vertex0,f.Vertex1)+edgeAligned(f.Vertex1,f.Vertex2)+edgeAligned(f.Vertex2,f.Vertex0)end;

  function get3rdvertex(f:Tface;va,vb:TVertex):tvertex;
  begin
    if(f.Vertex2<>va)and(f.Vertex2<>vb)then result:=f.Vertex2 else
    if(f.Vertex1<>va)and(f.Vertex1<>vb)then result:=f.Vertex1
                                       else result:=f.Vertex0;
  end;

var i,j:integer;
    f:tface;
    a,b,c,d:TVertex;

begin
  //edgelist
  setlength(edges,Count*4);edgecount:=0;
  for i:=0 to Count-1 do begin
    f:=ByIndex[i];
    if f.IsTriangle then
      for j:=0 to 2 do findaddedge(f.Vertex[j],f.Vertex[(j+1)mod 3],f);
  end;
  setlength(edges,edgecount);
  //edge score
  for i:=0 to high(edges)do with edges[i]do if f[1]<>nil then begin
    score:=-VDistmanh(V[0].V^,V[1].V^);
    //score:=faceAligned(f[0])+faceAligned(f[1])-2*edgeAligned(V[0],V[1]);
  end;
  //sort by score
  for i:=0 to high(edges)-1 do for j:=0 to high(edges)do if edges[i].score>edges[j].score then
    begin edgetemp:=edges[i];edges[i]:=edges[j];edges[j]:=edgetemp end;
  //make quads
  for i:=high(edges)downto 0 do if(edges[i].f[0]<>nil)and(edges[i].f[1]<>nil)then begin
    a:=edges[i].V[0];
    b:=edges[i].V[1];
    c:=get3rdvertex(edges[i].f[0],a,b);
    d:=get3rdvertex(edges[i].f[1],a,b);
    with edges[i].f[0] do begin Vertex0:=c;Vertex1:=a;Vertex2:=d;Vertex3:=b;end;
    for j:=0 to high(edges)do if(edges[j].f[0]=edges[i].f[0])or(edges[j].f[1]=edges[i].f[0])or(edges[j].f[0]=edges[i].f[1])or(edges[j].f[1]=edges[i].f[1])then
      edges[j].f[0]:=nil;//delete
    freeandnil(edges[i].f[1])
  end;
end;

procedure TFaceGroup.MakeTriangles;
var i:integer;
    f:TFace;
begin
  for i:=0 to count-1 do if ByIndex[i].IsQuad then begin
    f:=TFace.Create(self);
    f.Vertex0:=ByIndex[i].Vertex2;
    f.Vertex1:=ByIndex[i].Vertex3;
    f.Vertex2:=ByIndex[i].Vertex0;
    ByIndex[i].Vertex3:=nil;
  end;
end;

procedure TFaceGroup.OptimizeOrder;

  function FindByEdgeFrom(from:integer;v0,v1:TVertex;vertexMatchOnly:boolean):integer;
  var i,j:integer;f:TFace;
  begin
    for i:=from to Count-1 do begin
      f:=ByIndex[i];if not f.Valid then continue;
      if vertexMatchOnly then j:=f.FindEdge(v0.V^,v1.V^)
                         else j:=f.FindEdge(v0,v1);
      if j>=0 then begin f.SetFirstVertex(j);result:=i;exit;end;
    end;
    result:=-1;
  end;

var i,j,k:integer;
    Act:TFace;
    NextId:integer;
    V,V2:TVertex;
    VMatch:boolean;
    a:TV3F;
begin
  for i:=0 to Count-2 do begin
    Act:=ByIndex[i];
    if not Act.Valid then continue;
    NextId:=-1;
    for VMatch:=false to true do begin
      if Act.IsTriangle then begin
        if NextId<0 then NextId:=FindByEdgeFrom(i+1,Act.Vertex0,Act.Vertex2,VMatch);//balra
        if NextId<0 then NextId:=FindByEdgeFrom(i+1,Act.Vertex2,Act.Vertex1,VMatch);//jobbra
      end else if Act.IsQuad then begin
        if NextId<0 then NextId:=FindByEdgeFrom(i+1,Act.Vertex0,Act.Vertex3,VMatch);//balra
        if NextId<0 then NextId:=FindByEdgeFrom(i+1,Act.Vertex3,Act.Vertex2,VMatch);//egyenesen
        if NextId<0 then NextId:=FindByEdgeFrom(i+1,Act.Vertex2,Act.Vertex1,VMatch);//jobbra
      end;
      if NextId>=0 then break;
    end;

    if NextId<0 then begin //nem talalt folytatast, ezert keres egy olyan, ami legalabb normalvektorkent stimmen
      if Act.IsTriangle then V:=Act.Vertex[2]
                        else V:=Act.Vertex[3];
      for j:=i+1 to Count-1 do if ByIndex[j].Valid then begin
        for k:=0 to 3 do begin
          V2:=ByIndex[j].Vertex[k];
          if(V2<>nil)and(V.N=V2.N)then begin
            NextId:=j;
            ByIndex[NextId].SetFirstVertex(k);
            break;
          end;
        end;
        if NextId>=0 then break;
      end;
    end;

    Act.FNextP0:=0;
    if NextId>=0 then begin
      a:=ByIndex[NextId].Vertex0.V^;
      for j:=0 to Act.Count-1 do if VDistManh(a,Act.Vertex[j].V^)<(1/1024)then begin
        Act.FNextP0:=j;break end;
      exchange(i+1,NextId);
    end;
  end;
end;

//facegroup compression

procedure TFaceGroup.SetCompressedData(const Value: ansistring);
begin
  FCompressedData:=Value;
  NotifyChange;
end;

procedure TFaceGroup.SetCompressed(const Value: boolean);
begin
  if Compressed<>Value then begin
    if Value then Compress
             else UnCompress;
    NotifyChange;
  end;
end;

function TFaceGroup.GetCompressed: boolean;
begin
  result:=FCompressedData<>'';
end;

function TFaceGroup.FindNearestFaceByRay(const rayStart, rayPoint: tv3f): TFace;
var i:integer;
    d,mind:single;
begin
  mind:=1e30;result:=nil;
  for i:=0 to Count-1 do with ByIndex[i]do
    if rayIntersectDist(rayStart,rayPoint,d)then
      if mind>d then begin mind:=d;result:=ByIndex[i];end;
end;

procedure TFaceGroup.Compress;
begin
  FCompressedData:=CompressFacegroup(Self,17,6);
  Clear;
  Vertices.Clear;
end;

procedure TFaceGroup.UnCompress;
begin
  UnCompressFacegroup(self,FCompressedData);
  FCompressedData:='';
end;

{ TFaceGroups }

procedure TFaceGroups.glDraw;var i:integer;
begin for i:=0 to count-1 do ByIndex[i].glDraw(Options);end;

function TFaceGroups.GetCompressed: boolean;
var i:integer;
begin
  for i:=0 to Count-1 do if not ByIndex[i].Compressed then exit(false);
  result:=true;
end;

procedure TFaceGroups.SetCompressed(const Value: boolean);
var i:integer;
begin
  for i:=0 to count-1 do ByIndex[i].Compressed:=Value;
  NotifyChange;
end;

function TFaceGroups.VertexCount: integer;
var i:integer;
begin
  result:=0;for i:=0 to Count-1 do inc(result,ByIndex[i].Vertices.Count);
end;

procedure TFaceGroups.ClearInvalidFacesAndVertices;
var i:integer;
begin
  for i:=0 to count-1 do ByIndex[i].ClearInvalidFaces
end;

procedure TFaceGroups.Compress;
var i:integer;
begin
  for i:=0 to count-1 do ByIndex[i].Compress;
end;

function TFaceGroups.FaceCount: integer;
var i:integer;
begin
  result:=0;for i:=0 to Count-1 do inc(result,ByIndex[i].Count);
end;

function TFaceGroups.UsedMaterialNames:ansistring;
var i:integer;
begin
  result:='';for i:=0 to Count-1 do with ByIndex[i] do if ListFind(result,Material,',')<0 then ListAppend(result,Material,',');
end;

function TFaceGroups.FindNearestFaceByRay(const rayStart, rayPoint: tv3f): TFace;
var i,j:integer;
    d,mind:single;
begin
  mind:=1e30;result:=nil;
  for j:=0 to count-1 do with ByIndex[j]do
    for i:=0 to count-1 do with ByIndex[i]do
      if RayIntersectDist(rayStart,rayPoint,d)then
        if mind>d then begin mind:=d;result:=ByIndex[i];end;
end;

{ TPart }

{$O-}
procedure TPart.SetName(const Value: ansistring);begin end;
procedure TPart.SetHash(const Value: integer);begin end;
{$O+}

function TPart.GetCompressed: boolean;
var i:integer;
begin
  for i:=0 to Count-1 do if not ByIndex[i].Compressed then exit(false);
  result:=true;
end;

procedure TPart.SetCompressed(const Value: boolean);
var i:integer;
begin
  for i:=0 to Count-1 do ByIndex[i].Compressed:=Value;
  NotifyChange;
end;

procedure TPart.SetFileName(const Value: ansistring);
begin
  if FFileName=Value then exit;
  FFileName:=Value;
  Hash:=Crc32UC(FFileName);
end;

procedure TPart.ClearInvalidFacesAndVertices;
var i:integer;
begin
  for i:=0 to Count-1 do ByIndex[i].ClearInvalidFacesAndVertices;
end;

function TPart.Stats(const indent:ansistring=''): AnsiString;
var lods:ansistring;
    i:integer;
begin
  result:=indent+Name;

  lods:='';for i:=0 to Count-1 do ListAppend(lods,toStr(ByIndex[i].LodLevel),',');

  result:=result+indent+'  l:'+{tostr(count)}lods;
  if Count>0 then begin
    result:=result+'v:'+toStr(ByIndex[0].VertexCount);
    result:=result+'f:'+toStr(ByIndex[0].FaceCount);
    result:=result+'m:'+toStr(ByIndex[0].UsedMaterialNames)+#13#10;
  end;
  for i:=0 to SubParts.Count-1 do result:=result+SubParts.ByIndex[i].Stats(Indent+'  ');
end;

procedure TPart.glDraw(const ADrawOptions: TDrawOptions);
var i:integer;
begin
  //csak lod[0]
  if count>0 then ByIndex[0].glDraw(ADrawOptions);

  //subparts
  with SubParts do for i:=0 to Count-1 do
    ByIndex[i].GlDraw(ADrawOptions);
end;

function TPart.LocalTextureCache: TTextureCache;
begin
  if FLocalTextureCache=nil then
    FLocalTextureCache:=TTextureCache.Create(self);
  result:=FLocalTextureCache;
end;

{ TParts }

function QualifiedFileName(const AFileName, AOwnerFileName: ansistring):ansistring;
var path:ansistring;
    i:integer;
begin
  if AOwnerFileName='' then exit(AFileName);

  path:=ExtractFileDir(AOwnerFileName);
  for i:=0 to ListCount(AFileName,'\')-2 do path:=ExtractFileDir(path);
  result:=path+'\'+AFileName;
end;

function TParts.AccessPart(const AFileName, AOwnerFileName: ansistring):TPart;
var fn:ansistring;
    s:rawbytestring;
    h:integer;
begin
  fn:=QualifiedFileName(AFileName,AOwnerFileName);

  safelog('Accessing '+fn);
  h:=Crc32UC(fn);
  safelog('Finding hash '+inttostr(h));
  result:=TPart(FindBinary('hash',[h]));

  if result=nil then safelog('FUCK!')
                else safelog('found');

  if result<>nil then exit;

  s:=TFile(fn);
  if s='' then
    raise Exception.Create('File Not Found "'+AFilename+'" near "'+AOwnerFileName+'"');

  result:=TPart.Create(self);
  with result do begin
    FileName:=fn;
    LoadFromStr(s);
  end;
end;

{ TSubPart }

{$O-}
procedure TSubPart.SetName(const Value: ansistring);begin end;
{$O+}

function TSubPart.OwnerPart: TPart;
begin
  result:=TPart(FOwner.FOwner);
end;

procedure TSubPart.SetIt(const Value:ansistring);//ezt az O+- -t at kell irni most mar :@
var s:ansistring;
    i:integer;
begin
  if FPartName=Value then exit;

  safelogEnabled:=true;
  for i:=0 to PartCache.Count-1 do s:=s+PartCache.ByIndex[i].FFileName+'('+tostr(PartCache.ByIndex[i].Hash)+')  ';

  FPartName:=Value;
  FPart:=PartCache.AccessPart(PartName+'.prt',OwnerPart.FFileName);
  SafeLog('Setting PartName "'+Value+'" cache:'+s+'   '+inttohex(integer(fpart),8));
  NotifyChange;
end;

procedure TSubPart.SetPartName(const Value: ansistring);
asm jmp setit end;

function TSubPart.Stats(const Indent:ansistring=''):AnsiString;
begin
  result:=Indent+Name+':';
  if Part=nil then result:=result+'nil'
              else result:=result+Part.Stats(Indent);
  result:=result+#13#10;
end;

function TSubPart.getLookupList(const PropInfo: PPropInfo): THetObjectList;
begin
  if GetTypeData(PropInfo.PropType^).ClassType=TPart then result:=PartCache
                                                     else result:=nil;
end;

procedure TSubPart.GlDraw(const ADrawOptions:TDrawOptions);
begin
  glPushMatrix;
  glMultMatrixf(@DefaultTrans.M^);
  if assigned(Part)then
    Part.glDraw(ADrawOptions);
  glPopMatrix;
end;

{ TModel }

(*procedure TModel.SetName(const Value: ansistring);
begin
  FName := Value;
  NotifyChange;
end;

procedure TModel.ForEachSubPart(const proc: TProc<TSubPart>);
  procedure doit(const r:TSubPart);
  var i:integer;
  begin
    proc(r);
    for i:=0 to r.SubParts.Count-1 do doit(r.SubParts.ByIndex[i]);
  end;
begin
  doit(Root);
end;

procedure TModel.GlDraw(const Options: TDrawOptions);
begin
  Root.GlDraw(Options);
end;

function TModel.SubParts: TArray<TSubPart>;
var a:TArray<TSubPart>;
begin
  ForEachSubPart(procedure(r:TSubPart)
  begin
    SetLength(a,length(a)+1);
    a[high(a)]:=r;
  end);
  result:=a;
end;

function TModel.Parts: TArray<TPart>;
var r:TSubPart;
    found:boolean;
    i:integer;
begin
  setlength(result,0);
  for r in SubParts do if Assigned(r.Part)then begin
    found:=false;for i:=0 to high(Result)do if result[i]=r.Part then begin found:=true;break end;
    if not found then begin
      SetLength(result,length(result)+1);
      result[high(result)]:=r.Part;
    end;
  end;
end;

function TModel.Materials: TArray<ansistring>;
var p:TPart;
    L:TFaceGroups;
    F:TFaceGroup;
    i,i0,i1,i2:integer;
    found:boolean;
begin
  setlength(result,0);
  for i0:=0 to Length(Parts)-1 do begin p:=Parts[i0];
    for i1:=0 to p.Count-1 do begin L:=p.ByIndex[i1];
      for i2:=0 to L.Count-1 do begin F:=L.ByIndex[i2];
        found:=false;for i:=0 to high(Result)do if result[i]=F.Material then begin found:=true;break end;
        if not found then begin
          SetLength(result,length(result)+1);
          result[high(result)]:=F.Material;
        end;
      end;
    end;
  end;
end;

procedure TModel.ClearInvalidFacesAndVertices;
var p:TPart;
begin
  for p in Parts do p.ClearInvalidFacesAndVertices;
end;

function TModel.Dump;
  var indent:ansistring;
      sb:IAnsiStringBuilder;

  procedure doit(r:TSubPart);
  var i:integer;
  begin
    sb.AddLine(indent+r.dump);
    indent:=indent+'  ';
    for i:=0 to r.SubParts.Count-1 do doit(r.SubParts.ByIndex[i]);
    delete(indent,1,2);
  end;

var p:TArray<TPart>;
    m:TArray<ansistring>;

begin sb:=AnsiStringBuilder(result,true);with sb do begin
  p:=Parts;
  m:=Materials;

  AddLine('ModelDump  Name='+Name+' PartCount='+tostr(length(p))+' MatCount='+tostr(length(m)));
  AddLine(Root.Dump);
end;end;*)

initialization
{  RegisterHetClass(TTransformationF);
  RegisterHetClass(TVertex);
  RegisterHetClass(TVertices);
  RegisterHetClass(TFace);
  RegisterHetClass(TFaceGroup);
  RegisterHetClass(TFaceGroups);
  RegisterHetClass(TPart);
  RegisterHetClass(TSubPart);
  RegisterHetClass(TSubParts);
//  RegisterHetClass(TModel);  deprecated}

  PartCache:=TParts.Create(nil);
finalization
  FreeAndNil(PartCache);
end.
