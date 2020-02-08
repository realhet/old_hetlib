unit UMSTSShapeLoader;

interface
uses windows, sysutils, het.Utils, het.arrays, umstsparser;



type
  dword=cardinal;
  float=single;
  uint=cardinal;
  token=ansistring;
  sint=integer;

tbase=class
  _fvname:ansistring;
  constructor create;
  procedure addtoobjlist;
end;

Tshape_header            =class(tbase)constructor create;public
  flag1:dword; flag2:dword;{o}  end;


Tvector                  =class(tbase)constructor create;public
  X,Y,Z:float;  end;
Tvol_sphere              =class(tbase)constructor create;public
  Vector:tvector; radius:float  end;
Tvolumes                 =class(tbase)constructor create;public
NumVols:uint; vol_sphere:array of Tvol_sphere; end;

Tnamed_shader            =class(tbase)constructor create;public
shader_name:ansistring;  end;
Tshader_names            =class(tbase)constructor create;public
num_shaders:uint; named_shader:array of Tnamed_shader;  end;
Tnamed_filter_mode       =class(tbase)constructor create;public
filter_name:ansistring;  end;
Ttexture_filter_names    =class(tbase)constructor create;public
num_texture_filters:uint; named_filter_mode:array of Tnamed_filter_mode;  end;

Tpoint                   =class(tbase)constructor create;public
  pX,pY,pZ:float  end;
Tpoints                  =class(tbase)constructor create;public
num_points:uint; point:array of tpoint  end;

Tuv_point                =class(tbase)constructor create;public
  U,V:float  end;
Tuv_points               =class(tbase)constructor create;public
num_uv_points:uint; uv_point:array of tuv_point;  end;

Tnormals                 =class(tbase)constructor create;public
num_normals:uint; vector:array of tvector  end;

Tsort_vectors            =class(tbase)constructor create;public
num_sort_vectors:uint; vector:array of tvector  end;

Tcolour                  =class(tbase)constructor create;public
  A,R,G,B:float;end;
Tcolours                 =class(tbase)constructor create;public
num_colours:uint; colour:array of tcolour  end;

Tmatrix                  =class(tbase)constructor create;public
M11,M12,M13,M21,M22,M23,M31,M32,M33,M41,M42,M43:float;end;
Tmatrices                =class(tbase)constructor create;public
num_matrices :uint; matrix:array of tmatrix  end;

Timage                   =class(tbase)constructor create;public
filename:ansistring;  end;
Timages                  =class(tbase)constructor create;public
num_images:uint; image:array of timage  end;

Ttexture                 =class(tbase)constructor create;public
ImageIdx:uint; FilterMode:uint; MipMapLODBias:float; BorderColour:dword;{o}  end;
Ttextures                =class(tbase)constructor create;public
num_textures:uint; texture:array of ttexture;  end;

Tlight_material          =class(tbase)constructor create;public
flags:dword; DiffColIdx:uint; AmbColIdx:uint; SpecColIdx:uint; EmissiveColIdx:uint; SpecPower:float;  end;
Tlight_materials         =class(tbase)constructor create;public
num_light_materials:uint; light_material:array of tlight_material  end;

Tuv_op_share             =class(tbase)constructor create;public
TexAddrMode:uint; UvOpIdx:uint;  end;
Tuv_op_copy              =class(tbase)constructor create;public
TexAddrMode:uint; SrcUVIdx:uint;  end;
Tuvop_copy               =class(tbase)constructor create;public
IgnoredValue:uint;  end;
Tuv_op_uniformscale      =class(tbase)constructor create;public
TexAddrMode:uint; SrcUVIdx:uint; Scale:float;  end;
Tuv_op_user_uninformscale =class(tbase)constructor create;public
TexAddrMode:uint; SrcUVIdx:uint; CallbackToken:token;  end;
Tuv_op_nonuniformscale   =class(tbase)constructor create;public
TexAddrMode:uint; SrcUVIdx:uint; UScale:float; Vscale:float;  end;
Tuv_op_user_nonuninformscale =class(tbase)constructor create;public
TexAddrMode:uint; SrcUVIdx:uint; CallbackToken:token;  end;
Tuv_op_transform         =class(tbase)constructor create;public
TexAddrMode:uint; SrcUVIdx:uint; e11:float; e12:float; e21:float; e22:float; e31:float; e32:float;  end;
Tuv_op_user_transform    =class(tbase)constructor create;public
TexAddrMode:uint; SrcUVIdx:uint; CallbackToken:token;  end;
Tuv_op_reflectmap        =class(tbase)constructor create;public
TexAddrMode:uint;  end;
Tuv_op_reflectmapfull    =class(tbase)constructor create;public
TexAddrMode:uint  end;
Tuv_op_spheremap         =class(tbase)constructor create;public
TexAddrMode:uint  end;
Tuv_op_spheremapfull     =class(tbase)constructor create;public
TexAddrMode:uint  end;
Tuv_op_specularmap       =class(tbase)constructor create;public
TexAddrMode:uint  end;
Tuv_op_embossbump        =class(tbase)constructor create;public
TexAddrMode:uint; SrcUVIdx:uint; UVShiftScale:float;  end;

Tuv_op                   =class(tbase)constructor create;public
  uv_op_share:tuv_op_share;
  uv_op_copy:tuv_op_copy;
  uvop_copy:tuvop_copy;
  uv_op_uniformscale:tuv_op_uniformscale;
  uv_op_user_uninformscale:tuv_op_user_uninformscale;
  uv_op_nonuniformscale:tuv_op_nonuniformscale;
  uv_op_user_nonuninformscale:tuv_op_user_nonuninformscale;
  uv_op_transform:tuv_op_transform;
  uv_op_user_transform:tuv_op_user_transform;
  uv_op_reflectmap:tuv_op_reflectmap;
  uv_op_reflectmapfull:tuv_op_reflectmapfull;
  uv_op_spheremap:tuv_op_spheremap;
  uv_op_spheremapfull:tuv_op_spheremapfull;
  uv_op_specularmap:tuv_op_specularmap;
  uv_op_embossbump:tuv_op_embossbump;
end;
Tuv_ops                  =class(tbase)constructor create;public
num_uvops:uint; uv_op:array of tuv_op;end;
Tlight_model_cfg         =class(tbase)constructor create;public
flags:dword; uv_ops:tuv_ops;  end;
Tlight_model_cfgs        =class(tbase)constructor create;public
num_lm_cfgs:uint; light_model_cfg:array of tlight_model_cfg  end;

Tvtx_state               =class(tbase)constructor create;public
flags:dword; MatrixIdx:uint; LightMatIdx:sint; LightCfgIdx:uint; LightFlags:dword; matrix2:sint;{o}  end;
Tvtx_states              =class(tbase)constructor create;public
num_vtx_states:uint; vtx_state:array of tvtx_state  end;

Ttex_idxs                =class(tbase)constructor create;public
NumTexIdxs:uint; tex_idx:array of uint  end;
Tprim_state              =class(tbase)constructor create;public
flags:dword; ShaderIdx:uint; tex_idx:ttex_idxs; ZBias:float; VertStateIdx:sint; alphatestmode:uint;{o} LightCfgIdx:uint;{o} ZBufMode:uint{o}  end;
Tprim_states             =class(tbase)constructor create;public
num_primstates:uint; prim_state:array of tprim_state  end;

Tvertex_idxs             =class(tbase)constructor create;public
NumVertIdxs:uint; vertex_id:array of uint  end;
Tnormal_idxs             =class(tbase)constructor create;public
NumNormalIdxs:uint; normal_id:array of uint  end;
Tflags                   =class(tbase)constructor create;public
NumFaceFlags:uint; flag:array of dword  end;
Tindexed_trilist         =class(tbase)constructor create;public
VertIdxs:tvertex_idxs; NormalIdxs:tnormal_idxs; FaceFlags:tflags;  end;
Tindexed_line_list       =class(tbase)constructor create;public
VertIdxs:tvertex_idxs;  end;
Tpoint_list              =class(tbase)constructor create;public
FirstVertIdx:uint; NumVtxs:uint;  end;
Tprim_state_idx          =class(tbase)constructor create;public
  prim_state_idx:uint  end;
Tprim_item               =class(tbase)constructor create;public{or}
   prim_state_idx:tprim_state_idx;
   indexed_trilist:tindexed_trilist;
   indexed_line_list:tindexed_line_list;
   point_list:tpoint_list;  {!!!!}list:cardinal;end;
Tprimitives              =class(tbase)constructor create;public
NumPrims:uint; prim_item:array of tprim_item  end;
Tvertex_set              =class(tbase)constructor create;public
VtxStateIdx:uint; StartVtxIdx:uint; VtxCount:uint;  end;
Tvertex_sets             =class(tbase)constructor create;public
NumVtxSets:uint; vertex_set:array of tvertex_set  end;
Tvertex_uvs              =class(tbase)constructor create;public
NumSrcUVIdxs:uint; vertex_uv:array of uint;  end;
Tvertex                  =class(tbase)constructor create;public
flags:dword; PointIdx:uint; NormalIdx:uint; Colour1:dword; Colour2:dword; VtxUVs:tvertex_uvs; weight:float{o}  end;
Tvertices                =class(tbase)constructor create;public
NumVerts:uint; vertex:array of tvertex; end;
Tcullable_prims          =class(tbase)constructor create;public
NumPrims:uint;NumFlatSections :uint; NumPrimIdxs:uint;  end;
Tgeometry_node           =class(tbase)constructor create;public
TxLightCmds:uint; NodeXTxLightCmds:uint; TriLists:uint; LineLists:uint; PtLists:uint; cullable_prims:Tcullable_prims  end;
Tgeometry_nodes          =class(tbase)constructor create;public
NumGeomNodes:uint; geometry_node:array of tgeometry_node  end;
Tgeometry_node_map       =class(tbase)constructor create;public
NumEntries:uint; geometry_node_map:array of sint;  end;
Tsubobject_shaders       =class(tbase)constructor create;public
num:uint;subobject_shader:array of uint  end;
Tsubobject_light_cfgs    =class(tbase)constructor create;public
num:uint;subobject_light_cfg:array of uint;end;
Tgeometry_info           =class(tbase)constructor create;public
FaceNormals:uint; TxLightCmds:uint; NodeXTxLightCmds:uint; TrilistIdxs:uint; LineListIdxs:uint; NodeXTrilistIdxs:uint; Trilists:uint; LineLists:uint; PtLists:uint; NodeXTrilists:uint; GeomNodes:tgeometry_nodes; GeomNodeMap:tgeometry_node_map;  end;
Tsub_object_header       =class(tbase)constructor create;public
flags:dword; SortVectorIdx:sint; VolIdx:sint; SrcVtxFmtFlags:dword; DstVtxFmtFlags:dword; GeomInfo:tgeometry_info; SubObjShaders:tsubobject_shaders;{o} SubObjLightCfgs:tsubobject_light_cfgs;{o} SubObjID:uint;{o}  end;
Tsub_object              =class(tbase)constructor create;public
SubObjHdr:tsub_object_header; Verts:tvertices; VtxSets:tvertex_sets; Prims:tprimitives;  end;
Tsub_objects             =class(tbase)constructor create;public
NumSubObjects:uint; sub_object:array of tsub_object  end;
Tdlevel_selection        =class(tbase)constructor create;public
VisibleDistance:float;  end;
Thierarchy               =class(tbase)constructor create;public
NumItems:uint; hierarchy:array of sint  end;
Tdistance_level_header   =class(tbase)constructor create;public
dlev_selection:tdlevel_selection; hierarchy:thierarchy;  end;
Tdistance_level          =class(tbase)constructor create;public
DLevHdr:tdistance_level_header; SubObjs:tsub_objects;  end;
Tdistance_levels_header  =class(tbase)constructor create;public
DlevBias:uint; DlevScale:float;{o}  end;
Tdistance_levels         =class(tbase)constructor create;public
NumDlevs:uint; distance_level:array of tdistance_level  end;
Tlod_control             =class(tbase)constructor create;public
DlevHdr:tdistance_levels_header; Dlevs:tdistance_levels;  end;
Tlod_controls            =class(tbase)constructor create;public
NumLODControls:uint; lod_control:array of tlod_control  end;

Tlinear_key              =class(tbase)constructor create;public
frame:uint; x,y,z:float; end;
Ttcb_key                 =class(tbase)constructor create;public
frame:uint; x,y,z,w,tension,continuity,bias,in_,out_:float  end;

Ttcb_rot                 =class(tbase)constructor create;public
  num_keys:uint; tcb_key:array of ttcb_key  end;
Ttcb_pos			=class(tbase)constructor create;public
num_keys:uint; tcb_key:array of ttcb_key  end;
Tslerp_rot               =class(tbase)constructor create;public
num_keys:uint; linear_key:array of tlinear_key  end;
Tlinear_pos		=class(tbase)constructor create;public
num_keys:uint; linear_key:array of tlinear_key  end;

Tcontroller              =class(tbase){or}constructor create;public
tcb_rot:ttcb_rot;
slerp_rot:tslerp_rot;
tcb_pos:ttcb_pos;
linear_pos:tlinear_pos  end;
Tcontrollers	         =class(tbase)constructor create;public
num_controllers:uint; controller:array of tcontroller  end;

Tanim_node               =class(tbase)constructor create;public
  controllers:tcontrollers  end;
Tanim_nodes              =class(tbase)constructor create;public
NumNodes:uint; anim_node:array of tanim_node  end;
Tanimation               =class(tbase)constructor create;public
num_frames:uint; frame_rate:uint; AnimNodes:tanim_nodes;  end;
Tanimations              =class(tbase)constructor create;public
num_animations:uint; animation:array of tanimation   end;

Tshape_named_data_header =class(tbase)constructor create;public
NumNames:uint;  end;
Tshape_geom_ref          =class(tbase)constructor create;public
type_:uint; DlevIdx:uint; SubObjIdx:uint; first:uint; n:uint;  end;
Tshape_named_geometry    =class(tbase)constructor create;public
name:ansistring; NumRefs:uint; shape_geom_ref:array of tshape_geom_ref  end;
Tshape_named_data        =class(tbase)constructor create;public
shape_named_data_header:tshape_named_data_header;shape_named_geometry:tshape_named_geometry  end;

Tshape                   =class(tbase)constructor create;destructor destroy;override;public
ShapeHdr:tshape_header;
Volumes:tvolumes;
ShaderNames:tshader_names;
TexFilterNames:ttexture_filter_names;
Points:tpoints;
UVPoints:tuv_points;
Normals:tnormals;
SortVectors:tsort_vectors;
Colours:tcolours;
Matrices:tmatrices;
Images:timages;
Textures:ttextures;
LightMats:tlight_materials;
LightModelCfgs:tlight_model_cfgs;
VtxStates:tvtx_states;
PrimStates:tprim_states;
LODControls:tlod_controls;
Animations:tanimations;{o}
ShapeNamedData:tshape_named_data;

{!!!}
modelpath:ansistring;
objlist:THetArray<TObject>;
//procedure DrawMSTSShape(rci:TRenderContextInfo;matlib:TGLMaterialLibrary;dlev:integer);
end;


procedure skipWhitespace;
function peekCh:ansichar;
function getCh:ansichar;
function getStr:ansistring;
function getInt:integer;
function getDword:dword;
function getFloat:float;
function peekStr:ansistring;
function peekInt:integer;
function peekDword:dword;
function peekFloat:float;

function assertFvName(const s:ansistring):ansistring;
function isClosingBracket:boolean;
procedure assertClosingBracket;

function LoadShapeData(fn:ansistring):Tshape;

implementation

uses Classes;

const
  whitespace=[' ',#13,#10,#9];
  bracketIn='(';
  bracketOut=')';

var
  data:ansistring;
  datapos:integer;

function peekCh:ansichar;
begin
  if datapos<=length(data)then result:=data[datapos]
                          else result:=#0;
end;

function getCh:ansichar;
begin
  result:=peekch;inc(datapos);
end;

procedure skipWhitespace;
begin
  while peekCh in whitespace do inc(datapos);
end;

function getStr:ansistring;
begin
  skipWhitespace;
  result:=getch;
  if result[1] in[#0,bracketIn,bracketOut]then exit;
  while not(peekch in (whitespace+[bracketIn,bracketOut]))do
    result:=result+getch;
end;

function getInt:integer;
begin
  result:=strtointdef(getstr,0);
end;

function getDword:dword;
var s:ansistring;i:integer;
begin
  s:=getstr;result:=0;
  for i:=1 to length(s)do begin
    result:=result shl 4;
    case upcase(s[i])of
      '0'..'9':result:=result or cardinal(ord(s[i])-ord('0'));
      'A'..'F':result:=result or cardinal(ord(s[i])-ord('A')+10);
      else result:=0;exit
    end;
  end;
end;

function getFloat:float;
begin
  result:=StrToFloatDef(getstr,0);
end;

function peekStr:ansistring;var old:integer;
begin old:=datapos;result:=getstr;datapos:=old end;
function peekInt:integer;var old:integer;
begin old:=datapos;result:=getint;datapos:=old end;
function peekDword:dword;var old:integer;
begin old:=datapos;result:=getDWord;datapos:=old end;
function peekFloat:float;var old:integer;
begin old:=datapos;result:=getFloat;datapos:=old end;

function AssertFvName(const s:ansistring):ansistring;
var s2:ansistring;
begin
  result:='';
  s2:=getStr;
  if s2<>s then raise Exception.create('AssertFvName() error: ['+s+'] needed but ['+s2+'] found in file');
  result:=getstr;
  if result=bracketIn then begin result:='';exit end;
  s2:=getstr;
  if s2<>bracketIn then raise Exception.create('AssertFvName() error: ['+s+'] NO BRACKET');
end;

function isClosingBracket:boolean;
begin result:=peekstr=bracketOut;end;
procedure assertClosingBracket;
begin
  if getStr<>bracketout then raise Exception.create('isClosingBracket() error NO CLOSING BRACKET');
end;

procedure freearray(var a);
type tobjarray=array of TObject;
var i:integer;
begin
  for i:=0 to high(TObjArray(a))do
    TObjArray(a)[i].Free;
end;

var ActShape:TShape;

procedure tbase.addtoobjlist;
begin
  if classtype=TShape then
    ActShape:=TShape(self)
  else
    ActShape.ObjList.Append(self);
end;

constructor tbase.create;
begin
  _fvname:=assertFvName(copy(ClassName,2,$1000));
  addtoobjlist;
end;

constructor Tvector.create;
begin inherited;
  X:=getFloat;y:=getFloat;z:=getFloat;
  assertClosingBracket;
end;

constructor Tshape_header.create;
begin inherited;
  flag1:=getDword;
  if not isClosingBracket then flag2:=getDword;
  assertClosingBracket;
end;

constructor Tvol_sphere.create;
begin inherited;
  Vector:=Tvector.create;
  radius:=getFloat;
  assertClosingBracket;
end;

constructor Tvolumes.create;var i:integer;
begin inherited;
  NumVols:=getInt;
  SetLength(vol_sphere,NumVols);
  for i:=0 to high(vol_sphere)do
    vol_sphere[i]:=Tvol_sphere.create;
  assertClosingBracket;
end;

constructor Tnamed_shader.create;
begin inherited;
  shader_name:=getStr;
  assertClosingBracket;
end;

constructor Tshader_names.create;var i:integer;
begin inherited;
  num_shaders:=getInt;
  SetLength(named_shader,num_shaders);
  for i:=0 to high(named_shader)do named_shader[i]:=Tnamed_shader.create;
  assertClosingBracket;
end;

constructor Tnamed_filter_mode.create;
begin inherited;
  filter_name:=getStr;
  assertClosingBracket;
end;

constructor Ttexture_filter_names.create;var i:integer;
begin inherited;
  num_texture_filters:=getInt;
  setlength(named_filter_mode,num_texture_filters);
  for i:=0 to high(named_filter_mode)do
    named_filter_mode[i]:=Tnamed_filter_mode.create;
  assertClosingBracket;
end;

constructor Tpoint.create;
begin inherited;
  pX:=getFloat;pY:=getFloat;pZ:=getFloat;
  assertClosingBracket;
end;

constructor Tpoints.create;var i:integer;
begin inherited;
  num_points:=getInt;
  setlength(point,num_points);
  for i:=0 to high(point)do
    point[i]:=Tpoint.create;
  assertClosingBracket;
end;

constructor Tuv_point.create;
begin inherited;
  U:=getFloat;V:=getFloat;
  assertClosingBracket;
end;

constructor Tuv_points.create;var i:integer;
begin inherited;
  num_uv_points:=getInt;
  SetLength(uv_point,num_uv_points);
  for i:=0 to high(uv_point)do
    uv_point[i]:=Tuv_point.create;
  assertClosingBracket;
end;

constructor Tnormals.create;var i:integer;
begin inherited;
  num_normals:=getInt;
  setlength(vector,num_normals);
  for i:=0 to high(vector)do
    vector[i]:=Tvector.create;
  assertClosingBracket;
end;

constructor Tsort_vectors.create;var i:integer;
begin inherited;
  num_sort_vectors:=getInt;
  setlength(vector,num_sort_vectors);
  for i:=0 to high(vector)do
    vector[i]:=Tvector.create;
  assertClosingBracket;
end;

constructor Tcolour.create;
begin inherited;
  A:=getFloat;R:=getFloat;G:=getFloat;B:=getFloat;
  assertClosingBracket;
end;

constructor TColours.create;var i:integer;
begin inherited;
  num_colours:=getInt;
  setlength(colour,num_colours);
  for i:=0 to High(colour) do
    colour[i]:=Tcolour.create;
  assertClosingBracket;
end;

constructor Tmatrix.create;
begin inherited;
  M11:=getFloat;M12:=getFloat;M13:=getFloat;
  M21:=getFloat;M22:=getFloat;M23:=getFloat;
  M31:=getFloat;M32:=getFloat;M33:=getFloat;
  M41:=getFloat;M42:=getFloat;M43:=getFloat;
  assertClosingBracket;
end;

constructor TMatrices.create;var i:integer;
begin inherited;
  num_matrices:=getInt;
  setlength(matrix,num_matrices);
  for i:=0 to high(matrix)do
    matrix[i]:=Tmatrix.create;
  assertClosingBracket;
end;

constructor Timage.create;
begin inherited;
  filename:=getStr;
  assertClosingBracket;
end;

constructor TImages.create;var i:integer;
begin inherited;
  num_images:=getInt;
  setlength(image,num_images);
  for i:=0 to high(image)do
    image[i]:=Timage.create;
  assertClosingBracket;
end;

constructor Ttexture.create;
begin inherited;
  ImageIdx:=getInt;
  FilterMode:=getInt;
  MipMapLODBias:=getFloat;
  if not isClosingBracket then BorderColour:=getDword;
  assertClosingBracket;
end;

constructor Ttextures.create;var i:integer;
begin inherited;
  num_textures:=getInt;
  setlength(texture,num_textures);
  for i:=0 to high(texture)do
    texture[i]:=Ttexture.create;
  assertClosingBracket;
end;

constructor Tlight_material.create;
begin inherited;
  flags:=getDword;
  DiffColIdx:=getInt;
  AmbColIdx:=getInt;
  SpecColIdx:=getInt;
  EmissiveColIdx:=getInt;
  SpecPower:=getFloat;
  assertClosingBracket;
end;

constructor Tlight_materials.create;var i:integer;
begin inherited;
  num_light_materials:=getInt;
  setlength(light_material,num_light_materials);
  for i:=0 to high(light_material)do
    light_material[i]:=Tlight_material.create;
  assertClosingBracket;
end;

constructor Tuv_op_share.create;
begin inherited;
  TexAddrMode:=getInt;
  UvOpIdx:=getInt;
  assertClosingBracket;
end;

constructor Tuv_op_copy.create;
begin inherited;
  TexAddrMode:=getInt;
  SrcUVIdx:=getInt;
  assertClosingBracket;
end;

constructor Tuvop_copy.create;
begin inherited;
  IgnoredValue:=getInt;
  assertClosingBracket;
end;

constructor Tuv_op_uniformscale.create;
begin inherited;
  TexAddrMode:=getInt;
  SrcUVIdx:=getInt;
  Scale:=getFloat;
  assertClosingBracket;
end;

constructor Tuv_op_user_uninformscale.create;
begin inherited;
  TexAddrMode:=getInt;
  SrcUVIdx:=getInt;
  CallbackToken:=getStr;
  assertClosingBracket;
end;

constructor Tuv_op_nonuniformscale.create;
begin inherited;
  TexAddrMode:=getInt;
  SrcUVIdx:=getInt;
  UScale:=getFloat;
  Vscale:=getFloat;
  assertClosingBracket;
end;

constructor Tuv_op_user_nonuninformscale.create;
begin inherited;
  TexAddrMode:=getInt;
  SrcUVIdx:=getInt;
  CallbackToken:=getStr;
  assertClosingBracket;
end;

constructor Tuv_op_transform.create;
begin inherited;
  TexAddrMode:=getInt;
  SrcUVIdx:=getInt;
  e11:=getFloat;
  e12:=getFloat;
  e21:=getFloat;
  e22:=getFloat;
  e31:=getFloat;
  e32:=getFloat;
  assertClosingBracket;
end;

constructor Tuv_op_user_transform.create;
begin inherited;
  TexAddrMode:=getInt;
  SrcUVIdx:=getInt;
  CallbackToken:=getStr;
  assertClosingBracket;
end;

constructor Tuv_op_reflectmap.create;
begin inherited;
  TexAddrMode:=getInt;
  assertClosingBracket;
end;

constructor Tuv_op_reflectmapfull.create;
begin inherited;
  TexAddrMode:=getInt;
  assertClosingBracket;
end;

constructor Tuv_op_spheremap.create;
begin inherited;
  TexAddrMode:=getInt;
  assertClosingBracket;
end;

constructor Tuv_op_spheremapfull.create;
begin inherited;
  TexAddrMode:=getInt;
  assertClosingBracket;
end;

constructor Tuv_op_specularmap.create;
begin inherited;
  TexAddrMode:=getInt;
  assertClosingBracket;
end;

constructor Tuv_op_embossbump.create;
begin inherited;
  TexAddrMode:=getInt;
  SrcUVIdx:=getInt;
  UVShiftScale:=getFloat;
  assertClosingBracket;
end;

constructor Tuv_op.create;var s:ansistring;
begin {inherited;}AddToObjList;
  s:=peekStr;
  if s='uv_op_share'then uv_op_share:=Tuv_op_share.create else
  if s='uv_op_copy'then uv_op_copy:=Tuv_op_copy.create else
  if s='uvop_copy'then uvop_copy:=Tuvop_copy.create else
  if s='uv_op_uniformscale'then uv_op_uniformscale:=Tuv_op_uniformscale.create else
  if s='uv_op_user_uninformscale'then uv_op_user_uninformscale:=Tuv_op_user_uninformscale.create else
  if s='uv_op_nonuniformscale'then uv_op_nonuniformscale:=Tuv_op_nonuniformscale.create else
  if s='uv_op_user_nonuninformscale'then uv_op_user_nonuninformscale:=Tuv_op_user_nonuninformscale.create else
  if s='uv_op_transform'then uv_op_transform:=Tuv_op_transform.create else
  if s='uv_op_user_transform'then uv_op_user_transform:=Tuv_op_user_transform.create else
  if s='uv_op_reflectmap'then uv_op_reflectmap:=Tuv_op_reflectmap.create else
  if s='uv_op_reflectmapfull'then uv_op_reflectmapfull:=Tuv_op_reflectmapfull.create else
  if s='uv_op_spheremap'then uv_op_spheremap:=Tuv_op_spheremap.create else
  if s='uv_op_spheremapfull'then uv_op_spheremapfull:=Tuv_op_spheremapfull.create else
  if s='uv_op_specularmap'then uv_op_specularmap:=Tuv_op_specularmap.create else
  if s='uv_op_embossbump'then uv_op_embossbump:=Tuv_op_embossbump.create else
    raise Exception.Create('Tuv_op.create() unknown uv_op '+s);
{  assertClosingBracket;}
end;

constructor Tuv_ops.create;var i:integer;
begin inherited;
  num_uvops:=getInt;
  setlength(uv_op,num_uvops);
  for i:=0 to high(uv_op)do
    uv_op[i]:=Tuv_op.create;
  assertClosingBracket;
end;

constructor Tlight_model_cfg.create;
begin inherited;
  flags:=getDword;
  uv_ops:=Tuv_ops.create;
  assertClosingBracket;
end;

constructor Tlight_model_cfgs.create;var i:integer;
begin inherited;
  num_lm_cfgs:=getInt;
  setlength(light_model_cfg,num_lm_cfgs);
  for i:=0 to high(light_model_cfg)do
    light_model_cfg[i]:=Tlight_model_cfg.create;
  assertClosingBracket;
end;

constructor Tvtx_state.create;
begin inherited;
  flags:=getDword;
  MatrixIdx:=getInt;
  LightMatIdx:=getInt;
  LightCfgIdx:=getInt;
  LightFlags:=getDword;
  if not isClosingBracket then matrix2:=getInt;
  assertClosingBracket;
end;

constructor Tvtx_states.create;var i:integer;
begin inherited;
  num_vtx_states:=getInt;
  setlength(vtx_state,num_vtx_states);
  for i:=0 to high(vtx_state)do
    vtx_state[i]:=Tvtx_state.create;
  assertClosingBracket;
end;

constructor Ttex_idxs.create;var i:integer;
begin inherited;
  NumTexIdxs:=getInt;
  SetLength(tex_idx,NumTexIdxs);
  for i:=0 to high(tex_idx)do
    tex_idx[i]:=getInt;
  assertClosingBracket;
end;

constructor Tprim_state.create;
begin inherited;
  flags:=getDword;
  ShaderIdx:=getInt;
  tex_idx:=Ttex_idxs.create;
  ZBias:=getFloat;
  VertStateIdx:=getInt;
  if not isClosingBracket then alphatestmode:=getInt;
  if not isClosingBracket then LightCfgIdx:=getInt;
  if not isClosingBracket then ZBufMode:=getInt;
  assertClosingBracket;
end;

constructor Tprim_states.create;var i:integer;
begin inherited;
  num_primstates:=getInt;
  setlength(prim_state,num_primstates);
  for i:=0 to high(prim_state)do
    prim_state[i]:=Tprim_state.create;
  assertClosingBracket;
end;

constructor Tvertex_idxs.create;var i:integer;
begin inherited;
  NumVertIdxs:=getInt;
  SetLength(vertex_id,NumVertIdxs);
  for i:=0 to high(vertex_id)do
    vertex_id[i]:=getInt;
  assertClosingBracket;
end;

constructor Tnormal_idxs.create;var i:integer;
begin inherited;
  NumNormalIdxs:=getInt*2;
  setlength(normal_id,NumNormalIdxs);
  for i:=0 to high(normal_id)do
    normal_id[i]:=getInt;
  assertClosingBracket;
end;

constructor Tflags.create;var i:integer;
begin inherited;
  NumFaceFlags:=getInt;
  SetLength(flag,NumFaceFlags);
  for i:=0 to high(flag)do
    flag[i]:=getDword;
  assertClosingBracket;
end;

constructor Tindexed_trilist.create;
begin inherited;
  VertIdxs:=Tvertex_idxs.create;
  NormalIdxs:=Tnormal_idxs.create;
  FaceFlags:=Tflags.create;
  assertClosingBracket;
end;

constructor Tindexed_line_list.create;
begin inherited;
  VertIdxs:=Tvertex_idxs.create;
  assertClosingBracket;
end;

constructor Tpoint_list.create;
begin inherited;
  FirstVertIdx:=getInt;
  NumVtxs:=getInt;
  assertClosingBracket;
end;

constructor Tprim_state_idx.create;
begin inherited;
  prim_state_idx:=getInt;
  assertClosingBracket;
end;

constructor Tprim_item.create;var s:ansistring;
begin {inherited;}AddToObjList;
  s:=peekStr;
  if s='prim_state_idx'    then prim_state_idx:=Tprim_state_idx.create else
  if s='indexed_trilist'   then indexed_trilist:=Tindexed_trilist.create else
  if s='indexed_line_list' then indexed_line_list:=Tindexed_line_list.create else
  if s='point_list'        then point_list:=Tpoint_list.create else
    raise Exception.Create('Tprim_item.create() unknown prim_item '+s);
{  assertClosingBracket;}
end;

constructor Tprimitives.create;var i:integer;
begin inherited;
  NumPrims:=getInt;
  setlength(prim_item,NumPrims);
  for i:=0 to high(prim_item)do
    prim_item[i]:=Tprim_item.create;
  assertClosingBracket;
end;

constructor Tvertex_set.create;
begin inherited;
  VtxStateIdx:=getInt;
  StartVtxIdx:=getInt;
  VtxCount:=getInt;
  assertClosingBracket;
end;

constructor Tvertex_sets.create;var i:integer;
begin inherited;
  NumVtxSets:=getInt;
  setlength(vertex_set,NumVtxSets);
  for i:=0 to high(vertex_set)do
    vertex_set[i]:=Tvertex_set.create;
  assertClosingBracket;
end;

constructor Tvertex_uvs.create;var i:integer;
begin inherited;
  NumSrcUVIdxs:=getInt;
  SetLength(vertex_uv,NumSrcUVIdxs);
  for i:=0 to high(vertex_uv)do
    vertex_uv[i]:=getInt;
  assertClosingBracket;
end;

constructor Tvertex.create;
begin inherited;
  flags:=getDword;
  PointIdx:=getInt;
  NormalIdx:=getInt;
  Colour1:=getDword;
  Colour2:=getDword;
  VtxUVs:=Tvertex_uvs.create;
  if not isClosingBracket then weight:=getFloat;
  assertClosingBracket;
end;

constructor Tvertices.create;var i:integer;
begin inherited;
  NumVerts:=getInt;
  setlength(vertex,NumVerts);
  for i:=0 to high(vertex)do
    vertex[i]:=Tvertex.create;
  assertClosingBracket;
end;

constructor Tcullable_prims.create;
begin inherited;
  NumPrims:=getInt;
  NumFlatSections:=getInt;
  NumPrimIdxs:=getInt;
  assertClosingBracket;
end;

constructor Tgeometry_node.create;
begin inherited;
  TxLightCmds:=getInt;
  NodeXTxLightCmds:=getInt;
  TriLists:=getInt;
  LineLists:=getInt;
  PtLists:=getInt;
  cullable_prims:=Tcullable_prims.create;
  assertClosingBracket;
end;

constructor Tgeometry_nodes.create;var i:integer;
begin inherited;
  NumGeomNodes:=getInt;
  setlength(geometry_node,NumGeomNodes);
  for i:=0 to high(geometry_node)do
    geometry_node[i]:=Tgeometry_node.create;
  assertClosingBracket;
end;

constructor Tgeometry_node_map.create;var i:integer;
begin inherited;
  NumEntries:=getInt;
  SetLength(geometry_node_map,NumEntries);
  for i:=0 to high(geometry_node_map)do
    geometry_node_map[i]:=getInt;
  assertClosingBracket;
end;

constructor Tsubobject_shaders.create;var i:integer;
begin inherited;
  num:=getInt;
  SetLength(subobject_shader,num);
  for i:=0 to high(subobject_shader)do
    subobject_shader[i]:=getInt;
  assertClosingBracket;
end;

constructor Tsubobject_light_cfgs.create;var i:integer;
begin inherited;
  num:=getInt;
  SetLength(subobject_light_cfg,num);
  for i:=0 to high(subobject_light_cfg)do
    subobject_light_cfg[i]:=getInt;
  assertClosingBracket;
end;

constructor Tgeometry_info.create;
begin inherited;
  FaceNormals:=getInt;
  TxLightCmds:=getInt;
  NodeXTxLightCmds:=getInt;
  TrilistIdxs:=getInt;
  LineListIdxs:=getInt;
  NodeXTrilistIdxs:=getInt;
  Trilists:=getInt;
  LineLists:=getInt;
  PtLists:=getInt;
  NodeXTrilists:=getInt;
  GeomNodes:=Tgeometry_nodes.create;
  GeomNodeMap:=Tgeometry_node_map.create;
  assertClosingBracket;
end;

constructor Tsub_object_header.create;
begin inherited;
  flags:=getDword;
  SortVectorIdx:=getInt;
  VolIdx:=getInt;
  SrcVtxFmtFlags:=getDword;
  DstVtxFmtFlags:=getDword;
  GeomInfo:=Tgeometry_info.create;
  if not isClosingBracket then SubObjShaders:=Tsubobject_shaders.create;
  if not isClosingBracket then SubObjLightCfgs:=Tsubobject_light_cfgs.create;
  if not isClosingBracket then SubObjID:=getInt;
  assertClosingBracket;
end;

constructor Tsub_object.create;
begin inherited;
  SubObjHdr:=Tsub_object_header.create;
  Verts:=Tvertices.create;
  VtxSets:=Tvertex_sets.create;
  Prims:=Tprimitives.create;
  assertClosingBracket;
end;

constructor Tsub_objects.create;var i:integer;
begin inherited;
  NumSubObjects:=getInt;
  setlength(sub_object,NumSubObjects);
  for i:=0 to high(sub_object)do
    sub_object[i]:=Tsub_object.create;
  assertClosingBracket;
end;

constructor Tdlevel_selection.create;
begin inherited;
  VisibleDistance:=getFloat;
  assertClosingBracket;
end;

constructor Thierarchy.create;var i:integer;
begin inherited;
  NumItems:=getInt;
  setlength(hierarchy,NumItems);
  for i:=0 to high(hierarchy)do
    hierarchy[i]:=getInt;
  assertClosingBracket;
end;

constructor Tdistance_level_header.create;
begin inherited;
  dlev_selection:=Tdlevel_selection.create;
  hierarchy:=Thierarchy.create;
  assertClosingBracket;
end;

constructor Tdistance_level.create;
begin inherited;
  DLevHdr:=Tdistance_level_header.create;
  SubObjs:=Tsub_objects.create;
  assertClosingBracket;
end;

constructor Tdistance_levels_header.create;
begin inherited;
  DlevBias:=getInt;
  if not isClosingBracket then DlevScale:=getFloat;
  assertClosingBracket;
end;

constructor Tdistance_levels.create;var i:integer;
begin inherited;
  NumDlevs:=getInt;
  setlength(distance_level,NumDlevs);
  for i:=0 to high(distance_level)do
    distance_level[i]:=Tdistance_level.create;
  assertClosingBracket;
end;

constructor Tlod_control.create;
begin inherited;
  DlevHdr:=Tdistance_levels_header.create;
  Dlevs:=Tdistance_levels.create;
  assertClosingBracket;
end;

constructor Tlod_controls.create;var i:integer;
begin inherited;
  NumLODControls:=getInt;
  setlength(lod_control,NumLODControls);
  for i:=0 to high(lod_control)do
    lod_control[i]:=Tlod_control.create;
  assertClosingBracket;
end;

constructor Tlinear_key.create;
begin inherited;
  frame:=getInt;
  x:=getFloat;
  y:=getFloat;
  z:=getFloat;
  assertClosingBracket;
end;

constructor Ttcb_key.create;
begin inherited;
  frame:=getInt;
  x:=getFloat;
  y:=getFloat;
  z:=getFloat;
  w:=getFloat;
  tension:=getFloat;
  continuity:=getFloat;
  bias:=getFloat;
  in_:=getFloat;
  out_:=getFloat;
  assertClosingBracket;
end;

constructor Ttcb_rot.create;var i:integer;
begin inherited;
  num_keys:=getInt;
  setlength(tcb_key,num_keys);
  for i:=0 to high(tcb_key)do
    tcb_key[i]:=Ttcb_key.create;
  assertClosingBracket;
end;

constructor Ttcb_pos.create;var i:integer;
begin inherited;
  num_keys:=getInt;
  setlength(tcb_key,num_keys);
  for i:=0 to high(tcb_key)do
    tcb_key[i]:=Ttcb_key.create;
  assertClosingBracket;
end;

constructor Tslerp_rot.create;var i:integer;
begin inherited;
  num_keys:=getInt;
  SetLength(linear_key,num_keys);
  for i:=0 to high(linear_key)do
    linear_key[i]:=Tlinear_key.create;
  assertClosingBracket;
end;

constructor Tlinear_pos.create;var i:integer;
begin inherited;
  num_keys:=getInt;
  SetLength(linear_key,num_keys);
  for i:=0 to high(linear_key)do
    linear_key[i]:=Tlinear_key.create;
  assertClosingBracket;
end;

constructor Tcontroller.create;var s:ansistring;
begin {inherited;}AddToObjList;
  s:=peekStr;
  if s='tcb_rot'then tcb_rot:=Ttcb_rot.create else
  if s='slerp_rot'then slerp_rot:=Tslerp_rot.create else
  if s='tcb_pos'then tcb_pos:=Ttcb_pos.create else
  if s='linear_pos'then linear_pos:=Tlinear_pos.create else
    raise Exception.Create('Tcontroller.create() invalid anim controller: '+s);
{  assertClosingBracket;}
end;

constructor Tcontrollers.create;var i:integer;
begin inherited;
  num_controllers:=getInt;
  SetLength(controller,num_controllers);
  for i:=0 to high(controller)do
    controller[i]:=Tcontroller.create;
  assertClosingBracket;
end;

constructor Tanim_node.create;
begin inherited;
  controllers:=Tcontrollers.create;
  assertClosingBracket;
end;

constructor Tanim_nodes.create;var i:integer;
begin inherited;
  NumNodes:=getInt;
  setlength(anim_node,NumNodes);
  for i:=0 to high(anim_node)do
    anim_node[i]:=Tanim_node.create;
  assertClosingBracket;
end;

constructor Tanimation.create;
begin inherited;
  num_frames:=getInt;
  frame_rate:=getInt;
  AnimNodes:=Tanim_nodes.create;
  assertClosingBracket;
end;

constructor Tanimations.create;var i:integer;
begin inherited;
  num_animations:=getInt;
  setlength(animation,num_animations);
  for i:=0 to high(animation)do
    animation[i]:=Tanimation.create;
  assertClosingBracket;
end;

constructor Tshape_named_data_header.create;
begin inherited;
  NumNames:=getInt;
  assertClosingBracket;
end;

constructor Tshape_geom_ref.create;
begin inherited;
  type_:=getInt;
  DlevIdx:=getInt;
  SubObjIdx:=getInt;
  first:=getInt;
  n:=getInt;
  assertClosingBracket;
end;

constructor Tshape_named_geometry.create;var i:integer;
begin inherited;
  name:=getStr;
  NumRefs:=getInt;
  setlength(shape_geom_ref,NumRefs);
  for i:=0 to high(shape_geom_ref)do
    shape_geom_ref[i]:=Tshape_geom_ref.create;
  assertClosingBracket;
end;

constructor Tshape_named_data.create;
begin inherited;
  shape_named_data_header:=Tshape_named_data_header.create;
  shape_named_geometry:=Tshape_named_geometry.create;
  assertClosingBracket;
end;

constructor Tshape.create;
begin inherited;
  ShapeHdr:=Tshape_header.create;
  Volumes:=Tvolumes.create;
  ShaderNames:=Tshader_names.create;
  TexFilterNames:=Ttexture_filter_names.create;
  Points:=Tpoints.create;
  UVPoints:=Tuv_points.create;
  Normals:=Tnormals.create;
  SortVectors:=Tsort_vectors.create;
  Colours:=Tcolours.create;
  Matrices:=Tmatrices.create;
  Images:=Timages.create;
  Textures:=TTextures.create;
  LightMats:=Tlight_materials.create;
  LightModelCfgs:=Tlight_model_cfgs.create;
  VtxStates:=Tvtx_states.create;
  PrimStates:=Tprim_states.create;
  LODControls:=Tlod_controls.create;
  if not isClosingBracket then Animations:=Tanimations.create;
  if not isClosingBracket then ShapeNamedData:=Tshape_named_data.create;
  assertClosingBracket;
end;

destructor TShape.Destroy;
var i:integer;
begin
  with objlist do for i:=0 to Count-1 do
    FItems[i].Free;
  inherited;
end;

function LoadShapeData(fn:ansistring):Tshape;
var oldsep:char;
begin
  data:=UnpackFFE(fn);
  if data='' then
    raise Exception.Create('LoadShapeData('+fn+') empty file or fnf');
  datapos:=1;
  oldsep:=DecimalSeparator;DecimalSeparator:='.';
  try
    Result:=Tshape.create;
    result.modelpath:=ExtractFilePath(fn);
  finally
    DecimalSeparator:=oldsep;
  end;
end;

(*procedure tshape.DrawMSTSShape(rci:TRenderContextInfo;matlib:TGLMaterialLibrary;dlev:integer);
  function selectMaterial(tex_idx,ShaderIdx:integer;priStateId:Integer):TGLLibMaterial;
  var mn:ansistring;
      bmClr:TGLBitmap32;
      bm:TBitmap;
      fnClr,fnAlpha:ansistring;
      x,y:integer;
      sname:ansistring;
      sl:PGLPixel32Array;
      apath:ansistring;
  begin
    mn:=Images.image[Textures.texture[tex_idx].ImageIdx].filename;
    replace('.ace','',mn);
    Result:=matlib.Materials.GetLibMaterialByName(mn);
    if result=nil then begin
      Result:=matlib.Materials.Add;
      Result.Name:=mn;
      with result.Material.Texture do begin
        apath:=modelpath;
        fnClr:=apath+mn+'_clr.bmp';
        if not FileExists(fnClr)then begin
          delete(apath,length(apath),1);
          apath:=ExtractFilePath(apath)+'textures\';
          fnClr:=apath+mn+'_clr.bmp';
        end;
        if FileExists(fnClr)then begin
          Disabled:=false;
          MappingMode:=tmmUser;
          bmClr:=TGlBitmap32.Create;
          bm:=TBitmap.Create;bm.LoadFromFile(fnClr);
          bmClr.Assign(bm);
          bm.Free;
          fnAlpha:=apath+mn+'_alpha.bmp';
          if FileExists(fnAlpha)then begin
            bm:=TBitmap.Create;
            bm.LoadFromFile(fnAlpha);
            for y:=0 to bm.height-1 do begin
              sl:=bmClr.ScanLine[bm.height-y-1];
              for x:=0 to bm.width-1 do
                sl[x].a:=bm.Canvas.Pixels[x,y]and $ff;
            end;
            bm.Free;
          end;
          Image.Assign(bmClr);
          bmClr.Free;
        end;
      end;
    end;
    sname:=ShaderNames.named_shader[ShaderIdx].shader_name;
    with Result.Material do
    if sname='BlendATexDiff'then begin
      if PrimStates.prim_state[priStateId].alphatestmode=1 then begin
        Texture.TextureMode:=tmreplace;
        BlendingMode:=bmAlphaTest50;
      end else begin
        Texture.TextureMode:=tmModulate;
        BlendingMode:=bmTransparency;
      end;
    end else
    {if sname='TexDiff'then }begin {default}
      Texture.TextureMode:=tmModulate;
      BlendingMode:=bmOpaque;
    end;

  end;

  procedure SetupMatrix2(MatrixIdx:integer;var hierarcy:thierarchy);
  var m:TMatrix4f;v2:integer;
  begin
    v2:=hierarcy.hierarcy[MatrixIdx];if v2>0 then SetupMatrix2(v2,hierarcy);
    with Matrices.matrix[MatrixIdx]do begin
      M:=IdentityHmgMatrix;
      m[0,0]:=M11; m[0,1]:=M12; m[0,2]:=M13;
      m[1,0]:=M21; m[1,1]:=M22; m[1,2]:=M23;
      m[2,0]:=M31; m[2,1]:=M32; m[2,2]:=M33;
      m[3,0]:={!}-M41; m[3,1]:=M42; m[3,2]:=M43;
      glMultMatrixf(@m);
    end;
  end;

var so,pri,tri,actPrimStateId,actVertStateId:integer;
    mat:TGLLibMaterial;
begin
  mat:=nil;
  actPrimStateId:=-1;actVertStateId:=-1;
  with LODControls.lod_control[0].Dlevs.distance_level[dlev]do begin

    for so:=0 to high(SubObjs.sub_object)do with SubObjs.sub_object[so]do begin
      for pri:=0 to high(Prims.prim_item)do with Prims.prim_item[pri]do begin
        if prim_state_idx<>nil then begin
          if utils4.setchk(actPrimStateId,prim_state_idx.prim_state_idx)then begin//promstate valtas
            with PrimStates.prim_state[actPrimStateId]do begin
              actVertStateId:=VertStateIdx;
              mat:=selectMaterial(tex_idx.tex_idx[0],ShaderIdx,actPrimStateId);
            end;
          end;
        end else if indexed_trilist<>nil then with indexed_trilist.VertIdxs do begin
          glPushMatrix;
//          mname:=shp.matrices.matrix[shp.VtxStates.vtx_state[ActVertStateId].MatrixIdx]._fvname;
          setupMatrix2(VtxStates.vtx_state[ActVertStateId].MatrixIdx,DLevHdr.hierarchy);

          mat.Apply(rci);
          glFrontFace(gl_cw);
          repeat
            if list=0 then begin
              list:=glGenLists(1);
              glNewList(list,GL_COMPILE);
              glBegin(GL_TRIANGLES);
              for tri:=0 to high(vertex_id)do with Verts.vertex[vertex_id[tri]]do begin
                with UVPoints.uv_point[VtxUVs.vertex_uv[0]]do glTexCoord2f(U,1-V);
                with Normals.vector[NormalIdx]do glNormal3f({!}-X,Y,Z);
                with Points.point[PointIdx]do glVertex3f({!}-pX,pY,pZ);
              end;
              glEnd;
              glEndList;
            end;
            glCallList(list);
          until not mat.UnApply(rci);

          glPopMatrix;
        end;
      end;
    end;
  end;
end;
*)

end.

