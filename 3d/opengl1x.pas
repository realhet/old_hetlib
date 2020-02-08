//
// This unit is part of the GLScene Project, http://glscene.org
//
{: OpenGL1x<p>

	OpenGL 1.x import unit for GLScene. Unit remains "general purpose", but with
   a more "pragmatic" approach :)<p>

   This unit is based on OpenGL12.pas orginally written by Mike Lischke,
   please refer to OpenGL12.pas header.<p>

	<b>History : </b><font size=-1><ul>
      <li>13/10/04 - NC - Added GL_ATI_draw_buffers
      <li>08/10/04 - LR - Added const in the prototype of the following function for compatibility :
      TGLUTessCombineProc, TGLUTessCombineDataProc, gluPickMatrix
      gluProject, gluUnProject, gluTessVertex, gluLoadSamplingMatrices
      <li>04/10/04 - NC - Added GL_ATI_texture_float, WGL_ATI_pixel_format_float,
                          WGL_NV_float_buffer, GL_NV_float_buffer
      <li>08/07/04 - LR - Change case for Linux
      <li>05/07/04 - LR - Corrections for Linux. Now glX function are directly load
                          by external action (like for Windows). So i suppress
                          the function LoadLinuxOpenGL.
      <li>28/06/04 - LR - Removed ..\ from the GLScene.inc
      <li>24/06/04 - SG - Added GL_ARB_fragment_program
      <li>17/05/04 - EG - Dropped EXT_vertex_array (assumed as standard)
      <li>06/04/04 - EG - Added GL_ARB_shader_objects, GL_ARB_vertex_shader
                          and GL_ARB_fragment_shader, dropped a few oldies
      <li>13/02/04 - EG - Added GL_NV_texture_rectangle
      <li>18/11/03 - EG - Fixed binding of core extensions, added GL_ARB_depth_texture
                          and GL_ARB_shadow support
      <li>20/09/03 - EG - Added GL_NV_occlusion_query, dropped some more oldies
      <li>09/09/03 - EG - Added GL_ARB_vertex_buffer_object, dropped some oldies
      <li>04/09/03 - EG - Added GL_ARB_vertex_program
      <li>23/07/03 - EG - Creation from OpenGL12.pas "morph": classic OpenGL
                          calls made static, obsolete/rare extensions support
                          dropped
   </ul></font>
}
unit OpenGL1x;

interface

{.$define MULTITHREADOPENGL}

uses
  Windows, sysutils, graphics, UVector, UMatrix;

type
   TRCOptions = set of (
      opDoubleBuffered,
      opGDI,
      opStereo
   );

   GLenum      = UINT;
   TGLenum     = UINT; 
   PGLenum     = ^TGLenum;

   GLboolean   = BYTEBOOL;
   TGLboolean  = BYTEBOOL;
   PGLboolean  = ^TGLboolean;

   GLbitfield  = UINT;
   TGLbitfield = UINT;
   PGLbitfield = ^TGLbitfield;

   GLbyte      = ShortInt;
   TGLbyte     = ShortInt;
   PGLbyte     = ^TGLbyte;

   GLshort     = SmallInt;
   TGLshort    = SmallInt;
   PGLshort    = ^TGLshort;

   GLint       = Integer;
   TGLint      = Integer;
   PGLint      = ^Integer;

   GLsizei     = Integer;
   TGLsizei    = Integer;
   PGLsizei    = ^TGLsizei;

   GLubyte     = Byte;
   TGLubyte    = Byte;
   PGLubyte    = ^TGLubyte;

   GLushort    = Word;
   TGLushort   = Word;
   PGLushort   = ^TGLushort;

   GLuint      = UINT;
   TGLuint     = UINT;
   PGLuint     = ^TGLuint;

   GLfloat     = Single;
   TGLfloat    = Single;
   PGLfloat    = ^TGLfloat;

   GLclampf    = Single;
   TGLclampf   = Single;
   PGLclampf   = ^TGLclampf;

   GLdouble    = Double;
   TGLdouble   = Double;
   PGLdouble   = ^TGLdouble;

   GLclampd    = Double;
   TGLclampd   = Double;
   PGLclampd   = ^TGLclampd;

   GLhandleARB = Cardinal;
   PGLhandleARB = ^GLhandleARB;

   PGLPAnsiCharArray = ^PAnsiChar;

   PGLvoid = Pointer;

   TVector4p = array[0..3] of Pointer;

   PGLPointer = ^Pointer;

   PWGLSwap = ^TWGLSwap;
   _WGLSWAP = packed record
     hdc: HDC;
     uiFlags: UINT;
   end;
   TWGLSwap = _WGLSWAP;
   WGLSWAP = _WGLSWAP;

{$ifdef MULTITHREADOPENGL}
threadvar
{$else}
var
{$endif}
   GL_VERSION_1_0,
   GL_VERSION_1_1,
   GL_VERSION_1_2,
   GL_VERSION_1_3,
   GL_VERSION_1_4,
   GL_VERSION_1_5,
   GLU_VERSION_1_1,
   GLU_VERSION_1_2,
   GLU_VERSION_1_3: Boolean;

   // Extensions (gl)
   GL_3DFX_multisample,
   GL_3DFX_tbuffer,
   GL_3DFX_texture_compression_FXT1,

   GL_ARB_imaging,
   GL_ARB_multisample,
   GL_ARB_multitexture,
   GL_ARB_depth_texture,
   GL_ARB_shadow,
   GL_ARB_texture_border_clamp,
   GL_ARB_texture_compression,
   GL_ARB_texture_cube_map,
   GL_ARB_transpose_matrix,
   GL_ARB_vertex_blend,
   GL_ARB_point_parameters,
   GL_ARB_texture_env_combine,
   GL_ARB_texture_env_crossbar,
   GL_ARB_texture_env_dot3,
   GL_ARB_vertex_program,
   GL_ARB_vertex_buffer_object,
   GL_ARB_shader_objects,
   GL_ARB_vertex_shader,
   GL_ARB_fragment_shader,
   GL_ARB_fragment_program,

   GL_EXT_abgr,
   GL_EXT_bgra,
   GL_EXT_blend_color,
   GL_EXT_blend_func_separate,
   GL_EXT_blend_logic_op,
   GL_EXT_blend_minmax,
   GL_EXT_blend_subtract,
   GL_EXT_Cg_shader,
   GL_EXT_compiled_vertex_array,
   GL_EXT_copy_texture,
   GL_EXT_draw_range_elements,
   GL_EXT_fog_coord,
   GL_EXT_multi_draw_arrays,
   GL_EXT_multisample,
   GL_EXT_packed_pixels,
   GL_EXT_paletted_texture,
   GL_EXT_polygon_offset,
   GL_EXT_rescale_normal,
   GL_EXT_secondary_color,
   GL_EXT_separate_specular_color,
   GL_EXT_shared_texture_palette,
   GL_EXT_stencil_wrap,
   GL_EXT_stencil_two_side,
   GL_EXT_texture_compression_s3tc,
   GL_EXT_texture_cube_map,
   GL_EXT_texture_edge_clamp,
   GL_EXT_texture_env_add,
   GL_EXT_texture_env_combine,
   GL_EXT_texture_filter_anisotropic,
   GL_EXT_texture_lod_bias,
   GL_EXT_texture_object,
   GL_EXT_texture3D,
   GL_EXT_clip_volume_hint,

   GL_HP_occlusion_test,

   GL_IBM_rasterpos_clip,

   GL_KTX_buffer_region,

   GL_MESA_resize_buffers,

   GL_NV_blend_square,
   GL_NV_fog_distance,
   GL_NV_light_max_exponent,
   GL_NV_register_combiners,
   GL_NV_texgen_reflection,
   GL_NV_texture_env_combine4,
   GL_NV_vertex_array_range,
   GL_NV_vertex_program,
   GL_NV_multisample_filter_hint,
   GL_NV_fence,
   GL_NV_occlusion_query,
   GL_NV_texture_rectangle,

   GL_ATI_texture_float,
   GL_ATI_draw_buffers,

   GL_ATI_texture_compression_3dc,

   GL_SGI_color_matrix,

   GL_SGIS_generate_mipmap,
   GL_SGIS_multisample,
   GL_SGIS_texture_border_clamp,
   GL_SGIS_texture_color_mask,
   GL_SGIS_texture_edge_clamp,
   GL_SGIS_texture_lod,

   GL_SGIX_depth_texture,
   GL_SGIX_shadow,
   GL_SGIX_shadow_ambient,

   GL_WIN_swap_hint,

   // WGL Extensions ----------------------------
   WGL_EXT_swap_control,
   WGL_ARB_multisample,
   WGL_ARB_extensions_string,
   WGL_ARB_pixel_format,
   WGL_ARB_pbuffer,
   WGL_ARB_buffer_region,
   WGL_ATI_pixel_format_float,

   // Extensions (glu)
   GLU_EXT_Texture,
   GLU_EXT_object_space_tess,
   GLU_EXT_nurbs_tessellator: Boolean;

const
    opengl32 = 'OpenGL32.dll';
    glu32 = 'GLU32.dll';


   // ********** GL generic constants **********

   // errors
   GL_NO_ERROR                                       = 0;
   GL_INVALID_ENUM                                   = $0500;
   GL_INVALID_VALUE                                  = $0501;
   GL_INVALID_OPERATION                              = $0502;
   GL_STACK_OVERFLOW                                 = $0503;
   GL_STACK_UNDERFLOW                                = $0504;
   GL_OUT_OF_MEMORY                                  = $0505;

   // attribute bits
   GL_CURRENT_BIT                                    = $00000001;
   GL_POINT_BIT                                      = $00000002;
   GL_LINE_BIT                                       = $00000004;
   GL_POLYGON_BIT                                    = $00000008;
   GL_POLYGON_STIPPLE_BIT                            = $00000010;
   GL_PIXEL_MODE_BIT                                 = $00000020;
   GL_LIGHTING_BIT                                   = $00000040;
   GL_FOG_BIT                                        = $00000080;
   GL_DEPTH_BUFFER_BIT                               = $00000100;
   GL_ACCUM_BUFFER_BIT                               = $00000200;
   GL_STENCIL_BUFFER_BIT                             = $00000400;
   GL_VIEWPORT_BIT                                   = $00000800;
   GL_TRANSFORM_BIT                                  = $00001000;
   GL_ENABLE_BIT                                     = $00002000;
   GL_COLOR_BUFFER_BIT                               = $00004000;
   GL_HINT_BIT                                       = $00008000;
   GL_EVAL_BIT                                       = $00010000;
   GL_LIST_BIT                                       = $00020000;
   GL_TEXTURE_BIT                                    = $00040000;
   GL_SCISSOR_BIT                                    = $00080000;
   GL_ALL_ATTRIB_BITS                                = $000FFFFF;

   // client attribute bits
   GL_CLIENT_PIXEL_STORE_BIT                         = $00000001;
   GL_CLIENT_VERTEX_ARRAY_BIT                        = $00000002;
   GL_CLIENT_ALL_ATTRIB_BITS                         = $FFFFFFFF;

   // boolean values
   GL_FALSE                                          = 0;
   GL_TRUE                                           = 1;

   // primitives
   GL_POINTS                                         = $0000;
   GL_LINES                                          = $0001;
   GL_LINE_LOOP                                      = $0002;
   GL_LINE_STRIP                                     = $0003;
   GL_TRIANGLES                                      = $0004;
   GL_TRIANGLE_STRIP                                 = $0005;
   GL_TRIANGLE_FAN                                   = $0006;
   GL_QUADS                                          = $0007;
   GL_QUAD_STRIP                                     = $0008;
   GL_POLYGON                                        = $0009;

   // blending
   GL_ZERO                                           = 0;
   GL_ONE                                            = 1;
   GL_SRC_COLOR                                      = $0300;
   GL_ONE_MINUS_SRC_COLOR                            = $0301;
   GL_SRC_ALPHA                                      = $0302;
   GL_ONE_MINUS_SRC_ALPHA                            = $0303;
   GL_DST_ALPHA                                      = $0304;
   GL_ONE_MINUS_DST_ALPHA                            = $0305;
   GL_DST_COLOR                                      = $0306;
   GL_ONE_MINUS_DST_COLOR                            = $0307;
   GL_SRC_ALPHA_SATURATE                             = $0308;
   GL_BLEND_DST                                      = $0BE0;
   GL_BLEND_SRC                                      = $0BE1;
   GL_BLEND                                          = $0BE2;

   // blending (GL 1.2 ARB imaging)
   GL_BLEND_COLOR                                    = $8005;
   GL_CONSTANT_COLOR                                 = $8001;
   GL_ONE_MINUS_CONSTANT_COLOR                       = $8002;
   GL_CONSTANT_ALPHA                                 = $8003;
   GL_ONE_MINUS_CONSTANT_ALPHA                       = $8004;
   GL_FUNC_ADD                                       = $8006;
   GL_MIN                                            = $8007;
   GL_MAX                                            = $8008;
   GL_FUNC_SUBTRACT                                  = $800A;
   GL_FUNC_REVERSE_SUBTRACT                          = $800B;

   // color table GL 1.2 ARB imaging
   GL_COLOR_TABLE                                    = $80D0;
   GL_POST_CONVOLUTION_COLOR_TABLE                   = $80D1;
   GL_POST_COLOR_MATRIX_COLOR_TABLE                  = $80D2;
   GL_PROXY_COLOR_TABLE                              = $80D3;
   GL_PROXY_POST_CONVOLUTION_COLOR_TABLE             = $80D4;
   GL_PROXY_POST_COLOR_MATRIX_COLOR_TABLE            = $80D5;
   GL_COLOR_TABLE_SCALE                              = $80D6;
   GL_COLOR_TABLE_BIAS                               = $80D7;
   GL_COLOR_TABLE_FORMAT                             = $80D8;
   GL_COLOR_TABLE_WIDTH                              = $80D9;
   GL_COLOR_TABLE_RED_SIZE                           = $80DA;
   GL_COLOR_TABLE_GREEN_SIZE                         = $80DB;
   GL_COLOR_TABLE_BLUE_SIZE                          = $80DC;
   GL_COLOR_TABLE_ALPHA_SIZE                         = $80DD;
   GL_COLOR_TABLE_LUMINANCE_SIZE                     = $80DE;
   GL_COLOR_TABLE_INTENSITY_SIZE                     = $80DF;

   // convolutions GL 1.2 ARB imaging
   GL_CONVOLUTION_1D                                 = $8010;
   GL_CONVOLUTION_2D                                 = $8011;
   GL_SEPARABLE_2D                                   = $8012;
   GL_CONVOLUTION_BORDER_MODE                        = $8013;
   GL_CONVOLUTION_FILTER_SCALE                       = $8014;
   GL_CONVOLUTION_FILTER_BIAS                        = $8015;
   GL_REDUCE                                         = $8016;
   GL_CONVOLUTION_FORMAT                             = $8017;
   GL_CONVOLUTION_WIDTH                              = $8018;
   GL_CONVOLUTION_HEIGHT                             = $8019;
   GL_MAX_CONVOLUTION_WIDTH                          = $801A;
   GL_MAX_CONVOLUTION_HEIGHT                         = $801B;
   GL_POST_CONVOLUTION_RED_SCALE                     = $801C;
   GL_POST_CONVOLUTION_GREEN_SCALE                   = $801D;
   GL_POST_CONVOLUTION_BLUE_SCALE                    = $801E;
   GL_POST_CONVOLUTION_ALPHA_SCALE                   = $801F;
   GL_POST_CONVOLUTION_RED_BIAS                      = $8020;
   GL_POST_CONVOLUTION_GREEN_BIAS                    = $8021;
   GL_POST_CONVOLUTION_BLUE_BIAS                     = $8022;
   GL_POST_CONVOLUTION_ALPHA_BIAS                    = $8023;

   // histogram GL 1.2 ARB imaging
   GL_HISTOGRAM                                      = $8024;
   GL_PROXY_HISTOGRAM                                = $8025;
   GL_HISTOGRAM_WIDTH                                = $8026;
   GL_HISTOGRAM_FORMAT                               = $8027;
   GL_HISTOGRAM_RED_SIZE                             = $8028;
   GL_HISTOGRAM_GREEN_SIZE                           = $8029;
   GL_HISTOGRAM_BLUE_SIZE                            = $802A;
   GL_HISTOGRAM_ALPHA_SIZE                           = $802B;
   GL_HISTOGRAM_LUMINANCE_SIZE                       = $802C;
   GL_HISTOGRAM_SINK                                 = $802D;
   GL_MINMAX                                         = $802E;
   GL_MINMAX_FORMAT                                  = $802F;
   GL_MINMAX_SINK                                    = $8030;

   // buffers
   GL_NONE                                           = 0;
   GL_FRONT_LEFT                                     = $0400;
   GL_FRONT_RIGHT                                    = $0401;
   GL_BACK_LEFT                                      = $0402;
   GL_BACK_RIGHT                                     = $0403;
   GL_FRONT                                          = $0404;
   GL_BACK                                           = $0405;
   GL_LEFT                                           = $0406;
   GL_RIGHT                                          = $0407;
   GL_FRONT_AND_BACK                                 = $0408;
   GL_AUX0                                           = $0409;
   GL_AUX1                                           = $040A;
   GL_AUX2                                           = $040B;
   GL_AUX3                                           = $040C;
   GL_AUX_BUFFERS                                    = $0C00;
   GL_DRAW_BUFFER                                    = $0C01;
   GL_READ_BUFFER                                    = $0C02;
   GL_DOUBLEBUFFER                                   = $0C32;
   GL_STEREO                                         = $0C33;

   // depth buffer
   GL_DEPTH_RANGE                                    = $0B70;
   GL_DEPTH_TEST                                     = $0B71;
   GL_DEPTH_WRITEMASK                                = $0B72;
   GL_DEPTH_CLEAR_VALUE                              = $0B73;
   GL_DEPTH_FUNC                                     = $0B74;
   GL_NEVER                                          = $0200;
   GL_LESS                                           = $0201;
   GL_EQUAL                                          = $0202;
   GL_LEQUAL                                         = $0203;
   GL_GREATER                                        = $0204;
   GL_NOTEQUAL                                       = $0205;
   GL_GEQUAL                                         = $0206;
   GL_ALWAYS                                         = $0207;

   // accumulation buffer
   GL_ACCUM                                          = $0100;
   GL_LOAD                                           = $0101;
   GL_RETURN                                         = $0102;
   GL_MULT                                           = $0103;
   GL_ADD                                            = $0104;
   GL_ACCUM_CLEAR_VALUE                              = $0B80;

   // feedback buffer
   GL_FEEDBACK_BUFFER_POINTER                        = $0DF0;
   GL_FEEDBACK_BUFFER_SIZE                           = $0DF1;
   GL_FEEDBACK_BUFFER_TYPE                           = $0DF2;

   // feedback types
   GL_2D                                             = $0600;
   GL_3D                                             = $0601;
   GL_3D_COLOR                                       = $0602;
   GL_3D_COLOR_TEXTURE                               = $0603;
   GL_4D_COLOR_TEXTURE                               = $0604;

   // feedback tokens
   GL_PASS_THROUGH_TOKEN                             = $0700;
   GL_POINT_TOKEN                                    = $0701;
   GL_LINE_TOKEN                                     = $0702;
   GL_POLYGON_TOKEN                                  = $0703;
   GL_BITMAP_TOKEN                                   = $0704;
   GL_DRAW_PIXEL_TOKEN                               = $0705;
   GL_COPY_PIXEL_TOKEN                               = $0706;
   GL_LINE_RESET_TOKEN                               = $0707;

   // fog
   GL_EXP                                            = $0800;
   GL_EXP2                                           = $0801;
   GL_FOG                                            = $0B60;
   GL_FOG_INDEX                                      = $0B61;
   GL_FOG_DENSITY                                    = $0B62;
   GL_FOG_START                                      = $0B63;
   GL_FOG_END                                        = $0B64;
   GL_FOG_MODE                                       = $0B65;
   GL_FOG_COLOR                                      = $0B66;

   // pixel mode, transfer
   GL_PIXEL_MAP_I_TO_I                               = $0C70;
   GL_PIXEL_MAP_S_TO_S                               = $0C71;
   GL_PIXEL_MAP_I_TO_R                               = $0C72;
   GL_PIXEL_MAP_I_TO_G                               = $0C73;
   GL_PIXEL_MAP_I_TO_B                               = $0C74;
   GL_PIXEL_MAP_I_TO_A                               = $0C75;
   GL_PIXEL_MAP_R_TO_R                               = $0C76;
   GL_PIXEL_MAP_G_TO_G                               = $0C77;
   GL_PIXEL_MAP_B_TO_B                               = $0C78;
   GL_PIXEL_MAP_A_TO_A                               = $0C79;

   // vertex arrays
   GL_VERTEX_ARRAY_POINTER                           = $808E;
   GL_NORMAL_ARRAY_POINTER                           = $808F;
   GL_COLOR_ARRAY_POINTER                            = $8090;
   GL_INDEX_ARRAY_POINTER                            = $8091;
   GL_TEXTURE_COORD_ARRAY_POINTER                    = $8092;
   GL_EDGE_FLAG_ARRAY_POINTER                        = $8093;

   // stenciling
   GL_STENCIL_TEST                                   = $0B90;
   GL_STENCIL_CLEAR_VALUE                            = $0B91;
   GL_STENCIL_FUNC                                   = $0B92;
   GL_STENCIL_VALUE_MASK                             = $0B93;
   GL_STENCIL_FAIL                                   = $0B94;
   GL_STENCIL_PASS_DEPTH_FAIL                        = $0B95;
   GL_STENCIL_PASS_DEPTH_PASS                        = $0B96;
   GL_STENCIL_REF                                    = $0B97;
   GL_STENCIL_WRITEMASK                              = $0B98;
   GL_KEEP                                           = $1E00;
   GL_REPLACE                                        = $1E01;
   GL_INCR                                           = $1E02;
   GL_DECR                                           = $1E03;

   // color material
   GL_COLOR_MATERIAL_FACE                            = $0B55;
   GL_COLOR_MATERIAL_PARAMETER                       = $0B56;
   GL_COLOR_MATERIAL                                 = $0B57;

   // points
   GL_POINT_SMOOTH                                   = $0B10;
   GL_POINT_SIZE                                     = $0B11;
   GL_POINT_SIZE_RANGE                               = $0B12;
   GL_POINT_SIZE_GRANULARITY                         = $0B13;

   // lines
   GL_LINE_SMOOTH                                    = $0B20;
   GL_LINE_WIDTH                                     = $0B21;
   GL_LINE_WIDTH_RANGE                               = $0B22;
   GL_LINE_WIDTH_GRANULARITY                         = $0B23;
   GL_LINE_STIPPLE                                   = $0B24;
   GL_LINE_STIPPLE_PATTERN                           = $0B25;
   GL_LINE_STIPPLE_REPEAT                            = $0B26;

   // polygons
   GL_POLYGON_MODE                                   = $0B40;
   GL_POLYGON_SMOOTH                                 = $0B41;
   GL_POLYGON_STIPPLE                                = $0B42;
   GL_EDGE_FLAG                                      = $0B43;
   GL_CULL_FACE                                      = $0B44;
   GL_CULL_FACE_MODE                                 = $0B45;
   GL_FRONT_FACE                                     = $0B46;
   GL_CW                                             = $0900;
   GL_CCW                                            = $0901;
   GL_POINT                                          = $1B00;
   GL_LINE                                           = $1B01;
   GL_FILL                                           = $1B02;

   // display lists
   GL_LIST_MODE                                      = $0B30;
   GL_LIST_BASE                                      = $0B32;
   GL_LIST_INDEX                                     = $0B33;
   GL_COMPILE                                        = $1300;
   GL_COMPILE_AND_EXECUTE                            = $1301;

   // lighting
   GL_LIGHTING                                       = $0B50;
   GL_LIGHT_MODEL_LOCAL_VIEWER                       = $0B51;
   GL_LIGHT_MODEL_TWO_SIDE                           = $0B52;
   GL_LIGHT_MODEL_AMBIENT                            = $0B53;
   GL_LIGHT_MODEL_COLOR_CONTROL                      = $81F8; // GL 1.2
   GL_SHADE_MODEL                                    = $0B54;
   GL_NORMALIZE                                      = $0BA1;
   GL_AMBIENT                                        = $1200;
   GL_DIFFUSE                                        = $1201;
   GL_SPECULAR                                       = $1202;
   GL_POSITION                                       = $1203;
   GL_SPOT_DIRECTION                                 = $1204;
   GL_SPOT_EXPONENT                                  = $1205;
   GL_SPOT_CUTOFF                                    = $1206;
   GL_CONSTANT_ATTENUATION                           = $1207;
   GL_LINEAR_ATTENUATION                             = $1208;
   GL_QUADRATIC_ATTENUATION                          = $1209;
   GL_EMISSION                                       = $1600;
   GL_SHININESS                                      = $1601;
   GL_AMBIENT_AND_DIFFUSE                            = $1602;
   GL_COLOR_INDEXES                                  = $1603;
   GL_FLAT                                           = $1D00;
   GL_SMOOTH                                         = $1D01;
   GL_LIGHT0                                         = $4000;
   GL_LIGHT1                                         = $4001;
   GL_LIGHT2                                         = $4002;
   GL_LIGHT3                                         = $4003;
   GL_LIGHT4                                         = $4004;
   GL_LIGHT5                                         = $4005;
   GL_LIGHT6                                         = $4006;
   GL_LIGHT7                                         = $4007;

   // matrix modes
   GL_MATRIX_MODE                                    = $0BA0;
   GL_MODELVIEW                                      = $1700;
   GL_PROJECTION                                     = $1701;
   GL_TEXTURE                                        = $1702;

   // gets
   GL_CURRENT_COLOR                                  = $0B00;
   GL_CURRENT_INDEX                                  = $0B01;
   GL_CURRENT_NORMAL                                 = $0B02;
   GL_CURRENT_TEXTURE_COORDS                         = $0B03;
   GL_CURRENT_RASTER_COLOR                           = $0B04;
   GL_CURRENT_RASTER_INDEX                           = $0B05;
   GL_CURRENT_RASTER_TEXTURE_COORDS                  = $0B06;
   GL_CURRENT_RASTER_POSITION                        = $0B07;
   GL_CURRENT_RASTER_POSITION_VALID                  = $0B08;
   GL_CURRENT_RASTER_DISTANCE                        = $0B09;
   GL_MAX_LIST_NESTING                               = $0B31;
   GL_VIEWPORT                                       = $0BA2;
   GL_MODELVIEW_STACK_DEPTH                          = $0BA3;
   GL_PROJECTION_STACK_DEPTH                         = $0BA4;
   GL_TEXTURE_STACK_DEPTH                            = $0BA5;
   GL_MODELVIEW_MATRIX                               = $0BA6;
   GL_PROJECTION_MATRIX                              = $0BA7;
   GL_TEXTURE_MATRIX                                 = $0BA8;
   GL_ATTRIB_STACK_DEPTH                             = $0BB0;
   GL_CLIENT_ATTRIB_STACK_DEPTH                      = $0BB1;

   GL_SINGLE_COLOR                                   = $81F9; // GL 1.2
   GL_SEPARATE_SPECULAR_COLOR                        = $81FA; // GL 1.2

   // alpha testing
   GL_ALPHA_TEST                                     = $0BC0;
   GL_ALPHA_TEST_FUNC                                = $0BC1;
   GL_ALPHA_TEST_REF                                 = $0BC2;

   GL_LOGIC_OP_MODE                                  = $0BF0;
   GL_INDEX_LOGIC_OP                                 = $0BF1;
   GL_LOGIC_OP                                       = $0BF1;
   GL_COLOR_LOGIC_OP                                 = $0BF2;
   GL_SCISSOR_BOX                                    = $0C10;
   GL_SCISSOR_TEST                                   = $0C11;
   GL_INDEX_CLEAR_VALUE                              = $0C20;
   GL_INDEX_WRITEMASK                                = $0C21;
   GL_COLOR_CLEAR_VALUE                              = $0C22;
   GL_COLOR_WRITEMASK                                = $0C23;
   GL_INDEX_MODE                                     = $0C30;
   GL_RGBA_MODE                                      = $0C31;
   GL_RENDER_MODE                                    = $0C40;
   GL_PERSPECTIVE_CORRECTION_HINT                    = $0C50;
   GL_POINT_SMOOTH_HINT                              = $0C51;
   GL_LINE_SMOOTH_HINT                               = $0C52;
   GL_POLYGON_SMOOTH_HINT                            = $0C53;
   GL_FOG_HINT                                       = $0C54;
   GL_TEXTURE_GEN_S                                  = $0C60;
   GL_TEXTURE_GEN_T                                  = $0C61;
   GL_TEXTURE_GEN_R                                  = $0C62;
   GL_TEXTURE_GEN_Q                                  = $0C63;
   GL_PIXEL_MAP_I_TO_I_SIZE                          = $0CB0;
   GL_PIXEL_MAP_S_TO_S_SIZE                          = $0CB1;
   GL_PIXEL_MAP_I_TO_R_SIZE                          = $0CB2;
   GL_PIXEL_MAP_I_TO_G_SIZE                          = $0CB3;
   GL_PIXEL_MAP_I_TO_B_SIZE                          = $0CB4;
   GL_PIXEL_MAP_I_TO_A_SIZE                          = $0CB5;
   GL_PIXEL_MAP_R_TO_R_SIZE                          = $0CB6;
   GL_PIXEL_MAP_G_TO_G_SIZE                          = $0CB7;
   GL_PIXEL_MAP_B_TO_B_SIZE                          = $0CB8;
   GL_PIXEL_MAP_A_TO_A_SIZE                          = $0CB9;
   GL_UNPACK_SWAP_BYTES                              = $0CF0;
   GL_UNPACK_LSB_FIRST                               = $0CF1;
   GL_UNPACK_ROW_LENGTH                              = $0CF2;
   GL_UNPACK_SKIP_ROWS                               = $0CF3;
   GL_UNPACK_SKIP_PIXELS                             = $0CF4;
   GL_UNPACK_ALIGNMENT                               = $0CF5;
   GL_PACK_SWAP_BYTES                                = $0D00;
   GL_PACK_LSB_FIRST                                 = $0D01;
   GL_PACK_ROW_LENGTH                                = $0D02;
   GL_PACK_SKIP_ROWS                                 = $0D03;
   GL_PACK_SKIP_PIXELS                               = $0D04;
   GL_PACK_ALIGNMENT                                 = $0D05;
   GL_PACK_SKIP_IMAGES                               = $806B; // GL 1.2
   GL_PACK_IMAGE_HEIGHT                              = $806C; // GL 1.2
   GL_UNPACK_SKIP_IMAGES                             = $806D; // GL 1.2
   GL_UNPACK_IMAGE_HEIGHT                            = $806E; // GL 1.2
   GL_MAP_COLOR                                      = $0D10;
   GL_MAP_STENCIL                                    = $0D11;
   GL_INDEX_SHIFT                                    = $0D12;
   GL_INDEX_OFFSET                                   = $0D13;
   GL_RED_SCALE                                      = $0D14;
   GL_RED_BIAS                                       = $0D15;
   GL_ZOOM_X                                         = $0D16;
   GL_ZOOM_Y                                         = $0D17;
   GL_GREEN_SCALE                                    = $0D18;
   GL_GREEN_BIAS                                     = $0D19;
   GL_BLUE_SCALE                                     = $0D1A;
   GL_BLUE_BIAS                                      = $0D1B;
   GL_ALPHA_SCALE                                    = $0D1C;
   GL_ALPHA_BIAS                                     = $0D1D;
   GL_DEPTH_SCALE                                    = $0D1E;
   GL_DEPTH_BIAS                                     = $0D1F;
   GL_MAX_EVAL_ORDER                                 = $0D30;
   GL_MAX_LIGHTS                                     = $0D31;
   GL_MAX_CLIP_PLANES                                = $0D32;
   GL_MAX_TEXTURE_SIZE                               = $0D33;
   GL_MAX_3D_TEXTURE_SIZE                            = $8073; // GL 1.2
   GL_MAX_PIXEL_MAP_TABLE                            = $0D34;
   GL_MAX_ATTRIB_STACK_DEPTH                         = $0D35;
   GL_MAX_MODELVIEW_STACK_DEPTH                      = $0D36;
   GL_MAX_NAME_STACK_DEPTH                           = $0D37;
   GL_MAX_PROJECTION_STACK_DEPTH                     = $0D38;
   GL_MAX_TEXTURE_STACK_DEPTH                        = $0D39;
   GL_MAX_VIEWPORT_DIMS                              = $0D3A;
   GL_MAX_CLIENT_ATTRIB_STACK_DEPTH                  = $0D3B;
   GL_MAX_ELEMENTS_VERTICES                          = $80E8; // GL 1.2
   GL_MAX_ELEMENTS_INDICES                           = $80E9; // GL 1.2
   GL_RESCALE_NORMAL                                 = $803A; // GL 1.2
   GL_SUBPIXEL_BITS                                  = $0D50;
   GL_INDEX_BITS                                     = $0D51;
   GL_RED_BITS                                       = $0D52;
   GL_GREEN_BITS                                     = $0D53;
   GL_BLUE_BITS                                      = $0D54;
   GL_ALPHA_BITS                                     = $0D55;
   GL_DEPTH_BITS                                     = $0D56;
   GL_STENCIL_BITS                                   = $0D57;
   GL_ACCUM_RED_BITS                                 = $0D58;
   GL_ACCUM_GREEN_BITS                               = $0D59;
   GL_ACCUM_BLUE_BITS                                = $0D5A;
   GL_ACCUM_ALPHA_BITS                               = $0D5B;
   GL_NAME_STACK_DEPTH                               = $0D70;
   GL_AUTO_NORMAL                                    = $0D80;
   GL_MAP1_COLOR_4                                   = $0D90;
   GL_MAP1_INDEX                                     = $0D91;
   GL_MAP1_NORMAL                                    = $0D92;
   GL_MAP1_TEXTURE_COORD_1                           = $0D93;
   GL_MAP1_TEXTURE_COORD_2                           = $0D94;
   GL_MAP1_TEXTURE_COORD_3                           = $0D95;
   GL_MAP1_TEXTURE_COORD_4                           = $0D96;
   GL_MAP1_VERTEX_3                                  = $0D97;
   GL_MAP1_VERTEX_4                                  = $0D98;
   GL_MAP2_COLOR_4                                   = $0DB0;
   GL_MAP2_INDEX                                     = $0DB1;
   GL_MAP2_NORMAL                                    = $0DB2;
   GL_MAP2_TEXTURE_COORD_1                           = $0DB3;
   GL_MAP2_TEXTURE_COORD_2                           = $0DB4;
   GL_MAP2_TEXTURE_COORD_3                           = $0DB5;
   GL_MAP2_TEXTURE_COORD_4                           = $0DB6;
   GL_MAP2_VERTEX_3                                  = $0DB7;
   GL_MAP2_VERTEX_4                                  = $0DB8;
   GL_MAP1_GRID_DOMAIN                               = $0DD0;
   GL_MAP1_GRID_SEGMENTS                             = $0DD1;
   GL_MAP2_GRID_DOMAIN                               = $0DD2;
   GL_MAP2_GRID_SEGMENTS                             = $0DD3;
   GL_TEXTURE_1D                                     = $0DE0;
   GL_TEXTURE_2D                                     = $0DE1;
   GL_TEXTURE_3D                                     = $806F; // GL 1.2
   GL_SELECTION_BUFFER_POINTER                       = $0DF3;
   GL_SELECTION_BUFFER_SIZE                          = $0DF4;
   GL_POLYGON_OFFSET_UNITS                           = $2A00;
   GL_POLYGON_OFFSET_POINT                           = $2A01;
   GL_POLYGON_OFFSET_LINE                            = $2A02;
   GL_POLYGON_OFFSET_FILL                            = $8037;
   GL_POLYGON_OFFSET_FACTOR                          = $8038;
   GL_TEXTURE_BINDING_1D                             = $8068;
   GL_TEXTURE_BINDING_2D                             = $8069;
   GL_VERTEX_ARRAY                                   = $8074;
   GL_NORMAL_ARRAY                                   = $8075;
   GL_COLOR_ARRAY                                    = $8076;
   GL_INDEX_ARRAY                                    = $8077;
   GL_TEXTURE_COORD_ARRAY                            = $8078;
   GL_EDGE_FLAG_ARRAY                                = $8079;
   GL_VERTEX_ARRAY_SIZE                              = $807A;
   GL_VERTEX_ARRAY_TYPE                              = $807B;
   GL_VERTEX_ARRAY_STRIDE                            = $807C;
   GL_NORMAL_ARRAY_TYPE                              = $807E;
   GL_NORMAL_ARRAY_STRIDE                            = $807F;
   GL_COLOR_ARRAY_SIZE                               = $8081;
   GL_COLOR_ARRAY_TYPE                               = $8082;
   GL_COLOR_ARRAY_STRIDE                             = $8083;
   GL_INDEX_ARRAY_TYPE                               = $8085;
   GL_INDEX_ARRAY_STRIDE                             = $8086;
   GL_TEXTURE_COORD_ARRAY_SIZE                       = $8088;
   GL_TEXTURE_COORD_ARRAY_TYPE                       = $8089;
   GL_TEXTURE_COORD_ARRAY_STRIDE                     = $808A;
   GL_EDGE_FLAG_ARRAY_STRIDE                         = $808C;
   GL_COLOR_MATRIX                                   = $80B1; // GL 1.2 ARB imaging
   GL_COLOR_MATRIX_STACK_DEPTH                       = $80B2; // GL 1.2 ARB imaging
   GL_MAX_COLOR_MATRIX_STACK_DEPTH                   = $80B3; // GL 1.2 ARB imaging
   GL_POST_COLOR_MATRIX_RED_SCALE                    = $80B4; // GL 1.2 ARB imaging
   GL_POST_COLOR_MATRIX_GREEN_SCALE                  = $80B5; // GL 1.2 ARB imaging
   GL_POST_COLOR_MATRIX_BLUE_SCALE                   = $80B6; // GL 1.2 ARB imaging
   GL_POST_COLOR_MATRIX_ALPHA_SCALE                  = $80B7; // GL 1.2 ARB imaging
   GL_POST_COLOR_MATRIX_RED_BIAS                     = $80B8; // GL 1.2 ARB imaging
   GL_POST_COLOR_MATRIX_GREEN_BIAS                   = $80B9; // GL 1.2 ARB imaging
   GL_POST_COLOR_MATRIX_BLUE_BIAS                    = $80BA; // GL 1.2 ARB imaging
   GL_POST_COLOR_MATRIX_ALPHA_BIAS                   = $80BB; // GL 1.2 ARB imaging

   // evaluators
   GL_COEFF                                          = $0A00;
   GL_ORDER                                          = $0A01;
   GL_DOMAIN                                         = $0A02;

   // texture mapping
   GL_TEXTURE_WIDTH                                  = $1000;
   GL_TEXTURE_HEIGHT                                 = $1001;
   GL_TEXTURE_INTERNAL_FORMAT                        = $1003;
   GL_TEXTURE_COMPONENTS                             = $1003;
   GL_TEXTURE_BORDER_COLOR                           = $1004;
   GL_TEXTURE_BORDER                                 = $1005;
   GL_TEXTURE_RED_SIZE                               = $805C;
   GL_TEXTURE_GREEN_SIZE                             = $805D;
   GL_TEXTURE_BLUE_SIZE                              = $805E;
   GL_TEXTURE_ALPHA_SIZE                             = $805F;
   GL_TEXTURE_LUMINANCE_SIZE                         = $8060;
   GL_TEXTURE_INTENSITY_SIZE                         = $8061;
   GL_TEXTURE_PRIORITY                               = $8066;
   GL_TEXTURE_RESIDENT                               = $8067;
   GL_BGR                                            = $80E0; // v 1.2
   GL_BGRA                                           = $80E1; // v 1.2
   GL_S                                              = $2000;
   GL_T                                              = $2001;
   GL_R                                              = $2002;
   GL_Q                                              = $2003;
   GL_MODULATE                                       = $2100;
   GL_DECAL                                          = $2101;
   GL_TEXTURE_ENV_MODE                               = $2200;
   GL_TEXTURE_ENV_COLOR                              = $2201;
   GL_TEXTURE_ENV                                    = $2300;
   GL_EYE_LINEAR                                     = $2400;
   GL_OBJECT_LINEAR                                  = $2401;
   GL_SPHERE_MAP                                     = $2402;
   GL_TEXTURE_GEN_MODE                               = $2500;
   GL_OBJECT_PLANE                                   = $2501;
   GL_EYE_PLANE                                      = $2502;
   GL_NEAREST                                        = $2600;
   GL_LINEAR                                         = $2601;
   GL_NEAREST_MIPMAP_NEAREST                         = $2700;
   GL_LINEAR_MIPMAP_NEAREST                          = $2701;
   GL_NEAREST_MIPMAP_LINEAR                          = $2702;
   GL_LINEAR_MIPMAP_LINEAR                           = $2703;
   GL_TEXTURE_MAG_FILTER                             = $2800;
   GL_TEXTURE_MIN_FILTER                             = $2801;
   GL_TEXTURE_WRAP_R                                 = $8072; // GL 1.2
   GL_TEXTURE_WRAP_S                                 = $2802;
   GL_TEXTURE_WRAP_T                                 = $2803;
   GL_CLAMP_TO_EDGE                                  = $812F; // GL 1.2
   GL_TEXTURE_MIN_LOD                                = $813A; // GL 1.2
   GL_TEXTURE_MAX_LOD                                = $813B; // GL 1.2
   GL_TEXTURE_BASE_LEVEL                             = $813C; // GL 1.2
   GL_TEXTURE_MAX_LEVEL                              = $813D; // GL 1.2
   GL_TEXTURE_DEPTH                                  = $8071; // GL 1.2
   GL_PROXY_TEXTURE_1D                               = $8063;
   GL_PROXY_TEXTURE_2D                               = $8064;
   GL_PROXY_TEXTURE_3D                               = $8070; // GL 1.2
   GL_CLAMP                                          = $2900;
   GL_REPEAT                                         = $2901;

   // hints
   GL_DONT_CARE                                      = $1100;
   GL_FASTEST                                        = $1101;
   GL_NICEST                                         = $1102;

   // data types
   GL_BYTE                                           = $1400;
   GL_UNSIGNED_BYTE                                  = $1401;
   GL_SHORT                                          = $1402;
   GL_UNSIGNED_SHORT                                 = $1403;
   GL_INT                                            = $1404;
   GL_UNSIGNED_INT                                   = $1405;
   GL_FLOAT                                          = $1406;
   GL_2_BYTES                                        = $1407;
   GL_3_BYTES                                        = $1408;
   GL_4_BYTES                                        = $1409;
   GL_DOUBLE                                         = $140A;
   GL_DOUBLE_EXT                                     = $140A;

   // logic operations
   GL_CLEAR                                          = $1500;
   GL_AND                                            = $1501;
   GL_AND_REVERSE                                    = $1502;
   GL_COPY                                           = $1503;
   GL_AND_INVERTED                                   = $1504;
   GL_NOOP                                           = $1505;
   GL_XOR                                            = $1506;
   GL_OR                                             = $1507;
   GL_NOR                                            = $1508;
   GL_EQUIV                                          = $1509;
   GL_INVERT                                         = $150A;
   GL_OR_REVERSE                                     = $150B;
   GL_COPY_INVERTED                                  = $150C;
   GL_OR_INVERTED                                    = $150D;
   GL_NAND                                           = $150E;
   GL_SET                                            = $150F;

   // PixelCopyType
   GL_COLOR                                          = $1800;
   GL_DEPTH                                          = $1801;
   GL_STENCIL                                        = $1802;

   // pixel formats
   GL_COLOR_INDEX                                    = $1900;
   GL_STENCIL_INDEX                                  = $1901;
   GL_DEPTH_COMPONENT                                = $1902;
   GL_RED                                            = $1903;
   GL_GREEN                                          = $1904;
   GL_BLUE                                           = $1905;
   GL_ALPHA                                          = $1906;
   GL_RGB                                            = $1907;
   GL_RGBA                                           = $1908;
   GL_LUMINANCE                                      = $1909;
   GL_LUMINANCE_ALPHA                                = $190A;

   // pixel type
   GL_BITMAP                                         = $1A00;

   // rendering modes
   GL_RENDER                                         = $1C00;
   GL_FEEDBACK                                       = $1C01;
   GL_SELECT                                         = $1C02;

   // implementation strings
   GL_VENDOR                                         = $1F00;
   GL_RENDERER                                       = $1F01;
   GL_VERSION                                        = $1F02;
   GL_EXTENSIONS                                     = $1F03;

   // pixel formats
   GL_R3_G3_B2                                       = $2A10;
   GL_ALPHA4                                         = $803B;
   GL_ALPHA8                                         = $803C;
   GL_ALPHA12                                        = $803D;
   GL_ALPHA16                                        = $803E;
   GL_LUMINANCE4                                     = $803F;
   GL_LUMINANCE8                                     = $8040;
   GL_LUMINANCE12                                    = $8041;
   GL_LUMINANCE16                                    = $8042;
   GL_LUMINANCE4_ALPHA4                              = $8043;
   GL_LUMINANCE6_ALPHA2                              = $8044;
   GL_LUMINANCE8_ALPHA8                              = $8045;
   GL_LUMINANCE12_ALPHA4                             = $8046;
   GL_LUMINANCE12_ALPHA12                            = $8047;
   GL_LUMINANCE16_ALPHA16                            = $8048;
   GL_INTENSITY                                      = $8049;
   GL_INTENSITY4                                     = $804A;
   GL_INTENSITY8                                     = $804B;
   GL_INTENSITY12                                    = $804C;
   GL_INTENSITY16                                    = $804D;
   GL_RGB4                                           = $804F;
   GL_RGB5                                           = $8050;
   GL_RGB8                                           = $8051;
   GL_RGB10                                          = $8052;
   GL_RGB12                                          = $8053;
   GL_RGB16                                          = $8054;
   GL_RGBA2                                          = $8055;
   GL_RGBA4                                          = $8056;
   GL_RGB5_A1                                        = $8057;
   GL_RGBA8                                          = $8058;
   GL_RGB10_A2                                       = $8059;
   GL_RGBA12                                         = $805A;
   GL_RGBA16                                         = $805B;
   UNSIGNED_BYTE_3_3_2                               = $8032; // GL 1.2
   UNSIGNED_BYTE_2_3_3_REV                           = $8362; // GL 1.2
   UNSIGNED_SHORT_5_6_5                              = $8363; // GL 1.2
   UNSIGNED_SHORT_5_6_5_REV                          = $8364; // GL 1.2
   UNSIGNED_SHORT_4_4_4_4                            = $8033; // GL 1.2
   UNSIGNED_SHORT_4_4_4_4_REV                        = $8365; // GL 1.2
   UNSIGNED_SHORT_5_5_5_1                            = $8034; // GL 1.2
   UNSIGNED_SHORT_1_5_5_5_REV                        = $8366; // GL 1.2
   UNSIGNED_INT_8_8_8_8                              = $8035; // GL 1.2
   UNSIGNED_INT_8_8_8_8_REV                          = $8367; // GL 1.2
   UNSIGNED_INT_10_10_10_2                           = $8036; // GL 1.2
   UNSIGNED_INT_2_10_10_10_REV                       = $8368; // GL 1.2

   // interleaved arrays formats
   GL_V2F                                            = $2A20;
   GL_V3F                                            = $2A21;
   GL_C4UB_V2F                                       = $2A22;
   GL_C4UB_V3F                                       = $2A23;
   GL_C3F_V3F                                        = $2A24;
   GL_N3F_V3F                                        = $2A25;
   GL_C4F_N3F_V3F                                    = $2A26;
   GL_T2F_V3F                                        = $2A27;
   GL_T4F_V4F                                        = $2A28;
   GL_T2F_C4UB_V3F                                   = $2A29;
   GL_T2F_C3F_V3F                                    = $2A2A;
   GL_T2F_N3F_V3F                                    = $2A2B;
   GL_T2F_C4F_N3F_V3F                                = $2A2C;
   GL_T4F_C4F_N3F_V4F                                = $2A2D;

   // clip planes
   GL_CLIP_PLANE0                                    = $3000;
   GL_CLIP_PLANE1                                    = $3001;
   GL_CLIP_PLANE2                                    = $3002;
   GL_CLIP_PLANE3                                    = $3003;
   GL_CLIP_PLANE4                                    = $3004;
   GL_CLIP_PLANE5                                    = $3005;

   // miscellaneous
   GL_DITHER                                         = $0BD0;

   // ----- extensions enumerants -----
   // EXT_abgr
   GL_ABGR_EXT                                       = $8000;

   // EXT_packed_pixels
   GL_UNSIGNED_BYTE_3_3_2_EXT                        = $8032;
   GL_UNSIGNED_SHORT_4_4_4_4_EXT                     = $8033;
   GL_UNSIGNED_SHORT_5_5_5_1_EXT                     = $8034;
   GL_UNSIGNED_INT_8_8_8_8_EXT                       = $8035;
   GL_UNSIGNED_INT_10_10_10_2_EXT                    = $8036;

   // EXT_bgra
   GL_BGR_EXT                                        = $80E0;
   GL_BGRA_EXT                                       = $80E1;

   // EXT_paletted_texture
   GL_COLOR_INDEX1_EXT                               = $80E2;
   GL_COLOR_INDEX2_EXT                               = $80E3;
   GL_COLOR_INDEX4_EXT                               = $80E4;
   GL_COLOR_INDEX8_EXT                               = $80E5;
   GL_COLOR_INDEX12_EXT                              = $80E6;
   GL_COLOR_INDEX16_EXT                              = $80E7;

   // EXT_blend_color
   GL_CONSTANT_COLOR_EXT                             = $8001;
   GL_ONE_MINUS_CONSTANT_COLOR_EXT                   = $8002;
   GL_CONSTANT_ALPHA_EXT                             = $8003;
   GL_ONE_MINUS_CONSTANT_ALPHA_EXT                   = $8004;
   GL_BLEND_COLOR_EXT                                = $8005;

   // EXT_blend_minmax
   GL_FUNC_ADD_EXT                                   = $8006;
   GL_MIN_EXT                                        = $8007;
   GL_MAX_EXT                                        = $8008;
   GL_BLEND_EQUATION_EXT                             = $8009;

   // EXT_blend_subtract
   GL_FUNC_SUBTRACT_EXT                              = $800A;
   GL_FUNC_REVERSE_SUBTRACT_EXT                      = $800B;

   // EXT_convolution
   GL_CONVOLUTION_1D_EXT                             = $8010;
   GL_CONVOLUTION_2D_EXT                             = $8011;
   GL_SEPARABLE_2D_EXT                               = $8012;
   GL_CONVOLUTION_BORDER_MODE_EXT                    = $8013;
   GL_CONVOLUTION_FILTER_SCALE_EXT                   = $8014;
   GL_CONVOLUTION_FILTER_BIAS_EXT                    = $8015;
   GL_REDUCE_EXT                                     = $8016;
   GL_CONVOLUTION_FORMAT_EXT                         = $8017;
   GL_CONVOLUTION_WIDTH_EXT                          = $8018;
   GL_CONVOLUTION_HEIGHT_EXT                         = $8019;
   GL_MAX_CONVOLUTION_WIDTH_EXT                      = $801A;
   GL_MAX_CONVOLUTION_HEIGHT_EXT                     = $801B;
   GL_POST_CONVOLUTION_RED_SCALE_EXT                 = $801C;
   GL_POST_CONVOLUTION_GREEN_SCALE_EXT               = $801D;
   GL_POST_CONVOLUTION_BLUE_SCALE_EXT                = $801E;
   GL_POST_CONVOLUTION_ALPHA_SCALE_EXT               = $801F;
   GL_POST_CONVOLUTION_RED_BIAS_EXT                  = $8020;
   GL_POST_CONVOLUTION_GREEN_BIAS_EXT                = $8021;
   GL_POST_CONVOLUTION_BLUE_BIAS_EXT                 = $8022;
   GL_POST_CONVOLUTION_ALPHA_BIAS_EXT                = $8023;

   // EXT_histogram
   GL_HISTOGRAM_EXT                                  = $8024;
   GL_PROXY_HISTOGRAM_EXT                            = $8025;
   GL_HISTOGRAM_WIDTH_EXT                            = $8026;
   GL_HISTOGRAM_FORMAT_EXT                           = $8027;
   GL_HISTOGRAM_RED_SIZE_EXT                         = $8028;
   GL_HISTOGRAM_GREEN_SIZE_EXT                       = $8029;
   GL_HISTOGRAM_BLUE_SIZE_EXT                        = $802A;
   GL_HISTOGRAM_ALPHA_SIZE_EXT                       = $802B;
   GL_HISTOGRAM_LUMINANCE_SIZE_EXT                   = $802C;
   GL_HISTOGRAM_SINK_EXT                             = $802D;
   GL_MINMAX_EXT                                     = $802E;
   GL_MINMAX_FORMAT_EXT                              = $802F;
   GL_MINMAX_SINK_EXT                                = $8030;

   // EXT_polygon_offset
   GL_POLYGON_OFFSET_EXT                             = $8037;
   GL_POLYGON_OFFSET_FACTOR_EXT                      = $8038;
   GL_POLYGON_OFFSET_BIAS_EXT                        = $8039;

   // EXT_texture
   GL_ALPHA4_EXT                                     = $803B;
   GL_ALPHA8_EXT                                     = $803C;
   GL_ALPHA12_EXT                                    = $803D;
   GL_ALPHA16_EXT                                    = $803E;
   GL_LUMINANCE4_EXT                                 = $803F;
   GL_LUMINANCE8_EXT                                 = $8040;
   GL_LUMINANCE12_EXT                                = $8041;
   GL_LUMINANCE16_EXT                                = $8042;
   GL_LUMINANCE4_ALPHA4_EXT                          = $8043;
   GL_LUMINANCE6_ALPHA2_EXT                          = $8044;
   GL_LUMINANCE8_ALPHA8_EXT                          = $8045;
   GL_LUMINANCE12_ALPHA4_EXT                         = $8046;
   GL_LUMINANCE12_ALPHA12_EXT                        = $8047;
   GL_LUMINANCE16_ALPHA16_EXT                        = $8048;
   GL_INTENSITY_EXT                                  = $8049;
   GL_INTENSITY4_EXT                                 = $804A;
   GL_INTENSITY8_EXT                                 = $804B;
   GL_INTENSITY12_EXT                                = $804C;
   GL_INTENSITY16_EXT                                = $804D;
   GL_RGB2_EXT                                       = $804E;
   GL_RGB4_EXT                                       = $804F;
   GL_RGB5_EXT                                       = $8050;
   GL_RGB8_EXT                                       = $8051;
   GL_RGB10_EXT                                      = $8052;
   GL_RGB12_EXT                                      = $8053;
   GL_RGB16_EXT                                      = $8054;
   GL_RGBA2_EXT                                      = $8055;
   GL_RGBA4_EXT                                      = $8056;
   GL_RGB5_A1_EXT                                    = $8057;
   GL_RGBA8_EXT                                      = $8058;
   GL_RGB10_A2_EXT                                   = $8059;
   GL_RGBA12_EXT                                     = $805A;
   GL_RGBA16_EXT                                     = $805B;
   GL_TEXTURE_RED_SIZE_EXT                           = $805C;
   GL_TEXTURE_GREEN_SIZE_EXT                         = $805D;
   GL_TEXTURE_BLUE_SIZE_EXT                          = $805E;
   GL_TEXTURE_ALPHA_SIZE_EXT                         = $805F;
   GL_TEXTURE_LUMINANCE_SIZE_EXT                     = $8060;
   GL_TEXTURE_INTENSITY_SIZE_EXT                     = $8061;
   GL_REPLACE_EXT                                    = $8062;
   GL_PROXY_TEXTURE_1D_EXT                           = $8063;
   GL_PROXY_TEXTURE_2D_EXT                           = $8064;
   GL_TEXTURE_TOO_LARGE_EXT                          = $8065;

   // EXT_texture_object
   GL_TEXTURE_PRIORITY_EXT                           = $8066;
   GL_TEXTURE_RESIDENT_EXT                           = $8067;
   GL_TEXTURE_1D_BINDING_EXT                         = $8068;
   GL_TEXTURE_2D_BINDING_EXT                         = $8069;
   GL_TEXTURE_3D_BINDING_EXT                         = $806A;

   // EXT_texture3D
   GL_PACK_SKIP_IMAGES_EXT                           = $806B;
   GL_PACK_IMAGE_HEIGHT_EXT                          = $806C;
   GL_UNPACK_SKIP_IMAGES_EXT                         = $806D;
   GL_UNPACK_IMAGE_HEIGHT_EXT                        = $806E;
   GL_TEXTURE_3D_EXT                                 = $806F;
   GL_PROXY_TEXTURE_3D_EXT                           = $8070;
   GL_TEXTURE_DEPTH_EXT                              = $8071;
   GL_TEXTURE_WRAP_R_EXT                             = $8072;
   GL_MAX_3D_TEXTURE_SIZE_EXT                        = $8073;

   // SGI_color_matrix
   GL_COLOR_MATRIX_SGI                               = $80B1;
   GL_COLOR_MATRIX_STACK_DEPTH_SGI                   = $80B2;
   GL_MAX_COLOR_MATRIX_STACK_DEPTH_SGI               = $80B3;
   GL_POST_COLOR_MATRIX_RED_SCALE_SGI                = $80B4;
   GL_POST_COLOR_MATRIX_GREEN_SCALE_SGI              = $80B5;
   GL_POST_COLOR_MATRIX_BLUE_SCALE_SGI               = $80B6;
   GL_POST_COLOR_MATRIX_ALPHA_SCALE_SGI              = $80B7;
   GL_POST_COLOR_MATRIX_RED_BIAS_SGI                 = $80B8;
   GL_POST_COLOR_MATRIX_GREEN_BIAS_SGI               = $80B9;
   GL_POST_COLOR_MATRIX_BLUE_BIAS_SGI                = $80BA;
   GL_POST_COLOR_MATRIX_ALPHA_BIAS_SGI               = $80BB;

   // ARB_point_parameters
   GL_POINT_SIZE_MIN_ARB                             = $8126;
   GL_POINT_SIZE_MAX_ARB                             = $8127;
   GL_POINT_FADE_THRESHOLD_SIZE_ARB                  = $8128;
   GL_DISTANCE_ATTENUATION_ARB                       = $8129;

   // EXT_rescale_normal
   GL_RESCALE_NORMAL_EXT                             = $803A;

   // EXT_shared_texture_palette
   GL_SHARED_TEXTURE_PALETTE_EXT                     = $81FB;

   // EXT_nurbs_tessellator
   GLU_NURBS_MODE_EXT                                = 100160;
   GLU_NURBS_TESSELLATOR_EXT                         = 100161;
   GLU_NURBS_RENDERER_EXT                            = 100162;
   GLU_NURBS_BEGIN_EXT                               = 100164;
   GLU_NURBS_VERTEX_EXT                              = 100165;
   GLU_NURBS_NORMAL_EXT                              = 100166;
   GLU_NURBS_COLOR_EXT                               = 100167;
   GLU_NURBS_TEX_COORD_EXT                           = 100168;
   GLU_NURBS_END_EXT                                 = 100169;
   GLU_NURBS_BEGIN_DATA_EXT                          = 100170;
   GLU_NURBS_VERTEX_DATA_EXT                         = 100171;
   GLU_NURBS_NORMAL_DATA_EXT                         = 100172;
   GLU_NURBS_COLOR_DATA_EXT                          = 100173;
   GLU_NURBS_TEX_COORD_DATA_EXT                      = 100174;
   GLU_NURBS_END_DATA_EXT                            = 100175;

   // EXT_object_space_tess
   GLU_OBJECT_PARAMETRIC_ERROR_EXT                   = 100208;
   GLU_OBJECT_PATH_LENGTH_EXT                        = 100209;

   // EXT_compiled_vertex_array
   GL_ARRAY_ELEMENT_LOCK_FIRST_EXT                   = $81A8;
   GL_ARRAY_ELEMENT_LOCK_COUNT_EXT                   = $81A9;

   // ARB_multitexture
   GL_ACTIVE_TEXTURE_ARB                             = $84E0;
   GL_CLIENT_ACTIVE_TEXTURE_ARB                      = $84E1;
   GL_MAX_TEXTURE_UNITS_ARB                          = $84E2;
   GL_TEXTURE0_ARB                                   = $84C0;
   GL_TEXTURE1_ARB                                   = $84C1;
   GL_TEXTURE2_ARB                                   = $84C2;
   GL_TEXTURE3_ARB                                   = $84C3;
   GL_TEXTURE4_ARB                                   = $84C4;
   GL_TEXTURE5_ARB                                   = $84C5;
   GL_TEXTURE6_ARB                                   = $84C6;
   GL_TEXTURE7_ARB                                   = $84C7;
   GL_TEXTURE8_ARB                                   = $84C8;
   GL_TEXTURE9_ARB                                   = $84C9;
   GL_TEXTURE10_ARB                                  = $84CA;
   GL_TEXTURE11_ARB                                  = $84CB;
   GL_TEXTURE12_ARB                                  = $84CC;
   GL_TEXTURE13_ARB                                  = $84CD;
   GL_TEXTURE14_ARB                                  = $84CE;
   GL_TEXTURE15_ARB                                  = $84CF;
   GL_TEXTURE16_ARB                                  = $84D0;
   GL_TEXTURE17_ARB                                  = $84D1;
   GL_TEXTURE18_ARB                                  = $84D2;
   GL_TEXTURE19_ARB                                  = $84D3;
   GL_TEXTURE20_ARB                                  = $84D4;
   GL_TEXTURE21_ARB                                  = $84D5;
   GL_TEXTURE22_ARB                                  = $84D6;
   GL_TEXTURE23_ARB                                  = $84D7;
   GL_TEXTURE24_ARB                                  = $84D8;
   GL_TEXTURE25_ARB                                  = $84D9;
   GL_TEXTURE26_ARB                                  = $84DA;
   GL_TEXTURE27_ARB                                  = $84DB;
   GL_TEXTURE28_ARB                                  = $84DC;
   GL_TEXTURE29_ARB                                  = $84DD;
   GL_TEXTURE30_ARB                                  = $84DE;
   GL_TEXTURE31_ARB                                  = $84DF;

   // EXT_stencil_wrap
   GL_INCR_WRAP_EXT                                  = $8507;
   GL_DECR_WRAP_EXT                                  = $8508;

   // EXT_stencil_two_side
   GL_STENCIL_TEST_TWO_SIDE_EXT                      = $8910;
   GL_ACTIVE_STENCIL_FACE_EXT                        = $8911;

   // NV_texgen_reflection
   GL_NORMAL_MAP_NV                                  = $8511;
   GL_REFLECTION_MAP_NV                              = $8512;

   // NV_fence
   GL_ALL_COMPLETED_NV                               = $84F2;
   GL_FENCE_STATUS_NV                                = $84F3;
   GL_FENCE_CONDITION_NV                             = $84F4;

   // NV_occlusion_query
   GL_PIXEL_COUNTER_BITS_NV                          = $8864;
   GL_CURRENT_OCCLUSION_QUERY_ID_NV                  = $8865;
   GL_PIXEL_COUNT_NV                                 = $8866;
   GL_PIXEL_COUNT_AVAILABLE_NV                       = $8867;

   // NV_texture_rectangle
   GL_TEXTURE_RECTANGLE_NV                           = $84F5;
   GL_TEXTURE_BINDING_RECTANGLE_NV                   = $84F6;
   GL_PROXY_TEXTURE_RECTANGLE_NV                     = $84F7;
   GL_MAX_RECTANGLE_TEXTURE_SIZE_NV                  = $84F8;

   // EXT_texture_env_combine
   GL_COMBINE_EXT                                    = $8570;
   GL_COMBINE_RGB_EXT                                = $8571;
   GL_COMBINE_ALPHA_EXT                              = $8572;
   GL_RGB_SCALE_EXT                                  = $8573;
   GL_ADD_SIGNED_EXT                                 = $8574;
   GL_INTERPOLATE_EXT                                = $8575;
   GL_CONSTANT_EXT                                   = $8576;
   GL_PRIMARY_COLOR_EXT                              = $8577;
   GL_PREVIOUS_EXT                                   = $8578;
   GL_SOURCE0_RGB_EXT                                = $8580;
   GL_SOURCE1_RGB_EXT                                = $8581;
   GL_SOURCE2_RGB_EXT                                = $8582;
   GL_SOURCE0_ALPHA_EXT                              = $8588;
   GL_SOURCE1_ALPHA_EXT                              = $8589;
   GL_SOURCE2_ALPHA_EXT                              = $858A;
   GL_OPERAND0_RGB_EXT                               = $8590;
   GL_OPERAND1_RGB_EXT                               = $8591;
   GL_OPERAND2_RGB_EXT                               = $8592;
   GL_OPERAND0_ALPHA_EXT                             = $8598;
   GL_OPERAND1_ALPHA_EXT                             = $8599;
   GL_OPERAND2_ALPHA_EXT                             = $859A;

   // ARB_texture_env_combine
   GL_COMBINE_ARB                                    = $8570;
   GL_COMBINE_RGB_ARB                                = $8571;
   GL_COMBINE_ALPHA_ARB                              = $8572;
   GL_SOURCE0_RGB_ARB                                = $8580;
   GL_SOURCE1_RGB_ARB                                = $8581;
   GL_SOURCE2_RGB_ARB                                = $8582;
   GL_SOURCE0_ALPHA_ARB                              = $8588;
   GL_SOURCE1_ALPHA_ARB                              = $8589;
   GL_SOURCE2_ALPHA_ARB                              = $858A;
   GL_OPERAND0_RGB_ARB                               = $8590;
   GL_OPERAND1_RGB_ARB                               = $8591;
   GL_OPERAND2_RGB_ARB                               = $8592;
   GL_OPERAND0_ALPHA_ARB                             = $8598;
   GL_OPERAND1_ALPHA_ARB                             = $8599;
   GL_OPERAND2_ALPHA_ARB                             = $859A;
   GL_RGB_SCALE_ARB                                  = $8573;
   GL_ADD_SIGNED_ARB                                 = $8574;
   GL_INTERPOLATE_ARB                                = $8575;
   GL_SUBTRACT_ARB                                   = $84E7;
   GL_CONSTANT_ARB                                   = $8576;
   GL_CONSTANT_COLOR_ARB                             = $8576;
   GL_PRIMARY_COLOR_ARB                              = $8577;
   GL_PREVIOUS_ARB                                   = $8578;

   // ARB_texture_env_dot3
   GL_DOT3_RGB_ARB                                   = $86AE;
   GL_DOT3_RGBA_ARB                                  = $86AF;

   // ARB_vertex_program
   GL_VERTEX_PROGRAM_ARB                             = $8620;
   GL_VERTEX_PROGRAM_POINT_SIZE_ARB                  = $8642;
   GL_VERTEX_PROGRAM_TWO_SIDE_ARB                    = $8643;
   GL_COLOR_SUM_ARB                                  = $8458;
   GL_PROGRAM_FORMAT_ASCII_ARB                       = $8875;
   GL_VERTEX_ATTRIB_ARRAY_ENABLED_ARB                = $8622;
   GL_VERTEX_ATTRIB_ARRAY_SIZE_ARB                   = $8623;
   GL_VERTEX_ATTRIB_ARRAY_STRIDE_ARB                 = $8624;
   GL_VERTEX_ATTRIB_ARRAY_TYPE_ARB                   = $8625;
   GL_VERTEX_ATTRIB_ARRAY_NORMALIZED_ARB             = $886A;
   GL_CURRENT_VERTEX_ATTRIB_ARB                      = $8626;
   GL_VERTEX_ATTRIB_ARRAY_POINTER_ARB                = $8645;
   GL_PROGRAM_LENGTH_ARB                             = $8627;
   GL_PROGRAM_FORMAT_ARB                             = $8876;
   GL_PROGRAM_BINDING_ARB                            = $8677;
   GL_PROGRAM_INSTRUCTIONS_ARB                       = $88A0;
   GL_MAX_PROGRAM_INSTRUCTIONS_ARB                   = $88A1;
   GL_PROGRAM_NATIVE_INSTRUCTIONS_ARB                = $88A2;
   GL_MAX_PROGRAM_NATIVE_INSTRUCTIONS_ARB            = $88A3;
   GL_PROGRAM_TEMPORARIES_ARB                        = $88A4;
   GL_MAX_PROGRAM_TEMPORARIES_ARB                    = $88A5;
   GL_PROGRAM_NATIVE_TEMPORARIES_ARB                 = $88A6;
   GL_MAX_PROGRAM_NATIVE_TEMPORARIES_ARB             = $88A7;
   GL_PROGRAM_PARAMETERS_ARB                         = $88A8;
   GL_MAX_PROGRAM_PARAMETERS_ARB                     = $88A9;
   GL_PROGRAM_NATIVE_PARAMETERS_ARB                  = $88AA;
   GL_MAX_PROGRAM_NATIVE_PARAMETERS_ARB              = $88AB;
   GL_PROGRAM_ATTRIBS_ARB                            = $88AC;
   GL_MAX_PROGRAM_ATTRIBS_ARB                        = $88AD;
   GL_PROGRAM_NATIVE_ATTRIBS_ARB                     = $88AE;
   GL_MAX_PROGRAM_NATIVE_ATTRIBS_ARB                 = $88AF;
   GL_PROGRAM_ADDRESS_REGISTERS_ARB                  = $88B0;
   GL_MAX_PROGRAM_ADDRESS_REGISTERS_ARB              = $88B1;
   GL_PROGRAM_NATIVE_ADDRESS_REGISTERS_ARB           = $88B2;
   GL_MAX_PROGRAM_NATIVE_ADDRESS_REGISTERS_ARB       = $88B3;
   GL_MAX_PROGRAM_LOCAL_PARAMETERS_ARB               = $88B4;
   GL_MAX_PROGRAM_ENV_PARAMETERS_ARB                 = $88B5;
   GL_PROGRAM_UNDER_NATIVE_LIMITS_ARB                = $88B6;
   GL_PROGRAM_STRING_ARB                             = $8628;
   GL_PROGRAM_ERROR_POSITION_ARB                     = $864B;
   GL_CURRENT_MATRIX_ARB                             = $8641;
   GL_TRANSPOSE_CURRENT_MATRIX_ARB                   = $88B7;
   GL_CURRENT_MATRIX_STACK_DEPTH_ARB                 = $8640;
   GL_MAX_VERTEX_ATTRIBS_ARB                         = $8869;
   GL_MAX_PROGRAM_MATRICES_ARB                       = $862F;
   GL_MAX_PROGRAM_MATRIX_STACK_DEPTH_ARB             = $862E;
   GL_PROGRAM_ERROR_STRING_ARB                       = $8874;
   GL_MATRIX0_ARB                                    = $88C0;
   GL_MATRIX1_ARB                                    = $88C1;
   GL_MATRIX2_ARB                                    = $88C2;
   GL_MATRIX3_ARB                                    = $88C3;
   GL_MATRIX4_ARB                                    = $88C4;
   GL_MATRIX5_ARB                                    = $88C5;
   GL_MATRIX6_ARB                                    = $88C6;
   GL_MATRIX7_ARB                                    = $88C7;
   GL_MATRIX8_ARB                                    = $88C8;
   GL_MATRIX9_ARB                                    = $88C9;
   GL_MATRIX10_ARB                                   = $88CA;
   GL_MATRIX11_ARB                                   = $88CB;
   GL_MATRIX12_ARB                                   = $88CC;
   GL_MATRIX13_ARB                                   = $88CD;
   GL_MATRIX14_ARB                                   = $88CE;
   GL_MATRIX15_ARB                                   = $88CF;
   GL_MATRIX16_ARB                                   = $88D0;
   GL_MATRIX17_ARB                                   = $88D1;
   GL_MATRIX18_ARB                                   = $88D2;
   GL_MATRIX19_ARB                                   = $88D3;
   GL_MATRIX20_ARB                                   = $88D4;
   GL_MATRIX21_ARB                                   = $88D5;
   GL_MATRIX22_ARB                                   = $88D6;
   GL_MATRIX23_ARB                                   = $88D7;
   GL_MATRIX24_ARB                                   = $88D8;
   GL_MATRIX25_ARB                                   = $88D9;
   GL_MATRIX26_ARB                                   = $88DA;
   GL_MATRIX27_ARB                                   = $88DB;
   GL_MATRIX28_ARB                                   = $88DC;
   GL_MATRIX29_ARB                                   = $88DD;
   GL_MATRIX30_ARB                                   = $88DE;
   GL_MATRIX31_ARB                                   = $88DF;

   // ARB_vertex_buffer_object
   GL_ARRAY_BUFFER_ARB                               = $8892;
   GL_ELEMENT_ARRAY_BUFFER_ARB                       = $8893;
   GL_ARRAY_BUFFER_BINDING_ARB                       = $8894;
   GL_ELEMENT_ARRAY_BUFFER_BINDING_ARB               = $8895;
   GL_VERTEX_ARRAY_BUFFER_BINDING_ARB                = $8896;
   GL_NORMAL_ARRAY_BUFFER_BINDING_ARB                = $8897;
   GL_COLOR_ARRAY_BUFFER_BINDING_ARB                 = $8898;
   GL_INDEX_ARRAY_BUFFER_BINDING_ARB                 = $8899;
   GL_TEXTURE_COORD_ARRAY_BUFFER_BINDING_ARB         = $889A;
   GL_EDGE_FLAG_ARRAY_BUFFER_BINDING_ARB             = $889B;
   GL_SECONDARY_COLOR_ARRAY_BUFFER_BINDING_ARB       = $889C;
   GL_FOG_COORDINATE_ARRAY_BUFFER_BINDING_ARB        = $889D;
   GL_WEIGHT_ARRAY_BUFFER_BINDING_ARB                = $889E;
   GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING_ARB         = $889F;
   GL_STREAM_DRAW_ARB                                = $88E0;
   GL_STREAM_READ_ARB                                = $88E1;
   GL_STREAM_COPY_ARB                                = $88E2;
   GL_STATIC_DRAW_ARB                                = $88E4;
   GL_STATIC_READ_ARB                                = $88E5;
   GL_STATIC_COPY_ARB                                = $88E6;
   GL_DYNAMIC_DRAW_ARB                               = $88E8;
   GL_DYNAMIC_READ_ARB                               = $88E9;
   GL_DYNAMIC_COPY_ARB                               = $88EA;
   GL_READ_ONLY_ARB                                  = $88B8;
   GL_WRITE_ONLY_ARB                                 = $88B9;
   GL_READ_WRITE_ARB                                 = $88BA;
   GL_BUFFER_SIZE_ARB                                = $8764;
   GL_BUFFER_USAGE_ARB                               = $8765;
   GL_BUFFER_ACCESS_ARB                              = $88BB;
   GL_BUFFER_MAPPED_ARB                              = $88BC;
   GL_BUFFER_MAP_POINTER_ARB                         = $88BD;

   // ARB_shader_objects
   GL_PROGRAM_OBJECT_ARB                             = $8B40;
   GL_OBJECT_TYPE_ARB                                = $8B4E;
   GL_OBJECT_SUBTYPE_ARB                             = $8B4F;
   GL_OBJECT_DELETE_STATUS_ARB                       = $8B80;
   GL_OBJECT_COMPILE_STATUS_ARB                      = $8B81;
   GL_OBJECT_LINK_STATUS_ARB                         = $8B82;
   GL_OBJECT_VALIDATE_STATUS_ARB                     = $8B83;
   GL_OBJECT_INFO_LOG_LENGTH_ARB                     = $8B84;
   GL_OBJECT_ATTACHED_OBJECTS_ARB                    = $8B85;
   GL_OBJECT_ACTIVE_UNIFORMS_ARB                     = $8B86;
   GL_OBJECT_ACTIVE_UNIFORM_MAX_LENGTH_ARB           = $8B87;
   GL_OBJECT_SHADER_SOURCE_LENGTH_ARB                = $8B88;
   GL_SHADER_OBJECT_ARB                              = $8B48;
   GL_FLOAT_VEC2_ARB                                 = $8B50;
   GL_FLOAT_VEC3_ARB                                 = $8B51;
   GL_FLOAT_VEC4_ARB                                 = $8B52;
   GL_INT_VEC2_ARB                                   = $8B53;
   GL_INT_VEC3_ARB                                   = $8B54;
   GL_INT_VEC4_ARB                                   = $8B55;
   GL_BOOL_ARB                                       = $8B56;
   GL_BOOL_VEC2_ARB                                  = $8B57;
   GL_BOOL_VEC3_ARB                                  = $8B58;
   GL_BOOL_VEC4_ARB                                  = $8B59;
   GL_FLOAT_MAT2_ARB                                 = $8B5A;
   GL_FLOAT_MAT3_ARB                                 = $8B5B;
   GL_FLOAT_MAT4_ARB                                 = $8B5C;

   // ARB_vertex_shader
   GL_VERTEX_SHADER_ARB                              = $8B31;
   GL_MAX_VERTEX_UNIFORM_COMPONENTS_ARB              = $8B4A;
   GL_MAX_VARYING_FLOATS_ARB                         = $8B4B;
   GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS_ARB             = $8B4C;
   GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS_ARB           = $8B4D;
   GL_OBJECT_ACTIVE_ATTRIBUTES_ARB                   = $8B89;
   GL_OBJECT_ACTIVE_ATTRIBUTE_MAX_LENGTH_ARB         = $8B8A;

   // ARB_fragment_shader
   GL_FRAGMENT_SHADER_ARB                            = $8B30;
   GL_MAX_FRAGMENT_UNIFORM_COMPONENTS_ARB            = $8B49;

   // ARB_fragment_program
   GL_FRAGMENT_PROGRAM_ARB                           = $8804;

   // NV_texture_env_combine4
   GL_COMBINE4_NV                                    = $8503;
   GL_SOURCE3_RGB_NV                                 = $8583;
   GL_SOURCE3_ALPHA_NV                               = $858B;
   GL_OPERAND3_RGB_NV                                = $8593;
   GL_OPERAND3_ALPHA_NV                              = $859B;

   GL_BLEND_EQUATION                                 = $8009;
   GL_TABLE_TOO_LARGE                                = $8031;
   GL_UNSIGNED_BYTE_3_3_2                            = $8032;
   GL_UNSIGNED_SHORT_4_4_4_4                         = $8033;
   GL_UNSIGNED_SHORT_5_5_5_1                         = $8034;
   GL_UNSIGNED_INT_8_8_8_8                           = $8035;
   GL_UNSIGNED_INT_10_10_10_2                        = $8036;
   GL_UNSIGNED_BYTE_2_3_3_REV                        = $8362;
   GL_UNSIGNED_SHORT_5_6_5                           = $8363;
   GL_UNSIGNED_SHORT_5_6_5_REV                       = $8364;
   GL_UNSIGNED_SHORT_4_4_4_4_REV                     = $8365;
   GL_UNSIGNED_SHORT_1_5_5_5_REV                     = $8366;
   GL_UNSIGNED_INT_8_8_8_8_REV                       = $8367;
   GL_UNSIGNED_INT_2_10_10_10_REV                    = $8368;

   // GL_ARB_transpose_matrix
   GL_TRANSPOSE_MODELVIEW_MATRIX_ARB                 = $84E3;
   GL_TRANSPOSE_PROJECTION_MATRIX_ARB                = $84E4;
   GL_TRANSPOSE_TEXTURE_MATRIX_ARB                   = $84E5;
   GL_TRANSPOSE_COLOR_MATRIX_ARB                     = $84E6;

   // GL_ARB_multisample
   GL_MULTISAMPLE_ARB                                = $809D;
   GL_SAMPLE_ALPHA_TO_COVERAGE_ARB                   = $809E;
   GL_SAMPLE_ALPHA_TO_ONE_ARB                        = $809F;
   GL_SAMPLE_COVERAGE_ARB                            = $80A0;
   GL_SAMPLE_BUFFERS_ARB                             = $80A8;
   GL_SAMPLES_ARB                                    = $80A9;
   GL_SAMPLE_COVERAGE_VALUE_ARB                      = $80AA;
   GL_SAMPLE_COVERAGE_INVERT_ARB                     = $80AB;
   GL_MULTISAMPLE_BIT_ARB                            = $20000000;
   GLX_SAMPLE_BUFFERS_ARB                            = 100000;
   GLX_SAMPLES_ARB                                   = 100001;
   WGL_SAMPLE_BUFFERS_ARB                            = $2041;
   WGL_SAMPLES_ARB                                   = $2042;

   // GL_ARB_depth_texture
   GL_DEPTH_COMPONENT16_ARB                          = $81A5;
   GL_DEPTH_COMPONENT24_ARB                          = $81A6;
   GL_DEPTH_COMPONENT32_ARB                          = $81A7;
   GL_TEXTURE_DEPTH_SIZE_ARB                         = $884A;
   GL_DEPTH_TEXTURE_MODE_ARB                         = $884B;

   // GL_ARB_shadow
   GL_TEXTURE_COMPARE_MODE_ARB                       = $884C;
   GL_TEXTURE_COMPARE_FUNC_ARB                       = $884D;
   GL_COMPARE_R_TO_TEXTURE_ARB                       = $884E;

   // GL_ARB_texture_cube_map
   GL_NORMAL_MAP_ARB                                 = $8511;
   GL_REFLECTION_MAP_ARB                             = $8512;
   GL_TEXTURE_CUBE_MAP_ARB                           = $8513;
   GL_TEXTURE_BINDING_CUBE_MAP_ARB                   = $8514;
   GL_TEXTURE_CUBE_MAP_POSITIVE_X_ARB                = $8515;
   GL_TEXTURE_CUBE_MAP_NEGATIVE_X_ARB                = $8516;
   GL_TEXTURE_CUBE_MAP_POSITIVE_Y_ARB                = $8517;
   GL_TEXTURE_CUBE_MAP_NEGATIVE_Y_ARB                = $8518;
   GL_TEXTURE_CUBE_MAP_POSITIVE_Z_ARB                = $8519;
   GL_TEXTURE_CUBE_MAP_NEGATIVE_Z_ARB                = $851A;
   GL_PROXY_TEXTURE_CUBE_MAP_ARB                     = $851B;
   GL_MAX_CUBE_MAP_TEXTURE_SIZE_ARB                  = $851C;

   // GL_ARB_texture_border_clamp
   GL_CLAMP_TO_BORDER_ARB                            = $812D;

   // GL_ARB_texture_compression
   GL_COMPRESSED_ALPHA_ARB                           = $84E9;
   GL_COMPRESSED_LUMINANCE_ARB                       = $84EA;
   GL_COMPRESSED_LUMINANCE_ALPHA_ARB                 = $84EB;
   GL_COMPRESSED_INTENSITY_ARB                       = $84EC;
   GL_COMPRESSED_RGB_ARB                             = $84ED;
   GL_COMPRESSED_RGBA_ARB                            = $84EE;
   GL_TEXTURE_COMPRESSION_HINT_ARB                   = $84EF;
   GL_TEXTURE_COMPRESSED_IMAGE_SIZE_ARB              = $86A0;
   GL_TEXTURE_COMPRESSED_ARB                         = $86A1;
   GL_NUM_COMPRESSED_TEXTURE_FORMATS_ARB             = $86A2;
   GL_COMPRESSED_TEXTURE_FORMATS_ARB                 = $86A3;

   // GL_ARB_vertex_blend
   GL_MAX_VERTEX_UNITS_ARB                           = $86A4;
   GL_ACTIVE_VERTEX_UNITS_ARB                        = $86A5;
   GL_WEIGHT_SUM_UNITY_ARB                           = $86A6;
   GL_VERTEX_BLEND_ARB                               = $86A7;
   GL_CURRENT_WEIGHT_ARB                             = $86A8;
   GL_WEIGHT_ARRAY_TYPE_ARB                          = $86A9;
   GL_WEIGHT_ARRAY_STRIDE_ARB                        = $86AA;
   GL_WEIGHT_ARRAY_SIZE_ARB                          = $86AB;
   GL_WEIGHT_ARRAY_POINTER_ARB                       = $86AC;
   GL_WEIGHT_ARRAY_ARB                               = $86AD;
   GL_MODELVIEW0_ARB                                 = $1700;
   GL_MODELVIEW1_ARB                                 = $850A;
   GL_MODELVIEW2_ARB                                = $8722;
   GL_MODELVIEW3_ARB                                = $8723;
   GL_MODELVIEW4_ARB                                = $8724;
   GL_MODELVIEW5_ARB                                = $8725;
   GL_MODELVIEW6_ARB                                = $8726;
   GL_MODELVIEW7_ARB                                = $8727;
   GL_MODELVIEW8_ARB                                = $8728;
   GL_MODELVIEW9_ARB                                = $8729;
   GL_MODELVIEW10_ARB                               = $872A;
   GL_MODELVIEW11_ARB                               = $872B;
   GL_MODELVIEW12_ARB                               = $872C;
   GL_MODELVIEW13_ARB                               = $872D;
   GL_MODELVIEW14_ARB                               = $872E;
   GL_MODELVIEW15_ARB                               = $872F;
   GL_MODELVIEW16_ARB                               = $8730;
   GL_MODELVIEW17_ARB                               = $8731;
   GL_MODELVIEW18_ARB                               = $8732;
   GL_MODELVIEW19_ARB                               = $8733;
   GL_MODELVIEW20_ARB                               = $8734;
   GL_MODELVIEW21_ARB                               = $8735;
   GL_MODELVIEW22_ARB                               = $8736;
   GL_MODELVIEW23_ARB                               = $8737;
   GL_MODELVIEW24_ARB                               = $8738;
   GL_MODELVIEW25_ARB                               = $8739;
   GL_MODELVIEW26_ARB                               = $873A;
   GL_MODELVIEW27_ARB                               = $873B;
   GL_MODELVIEW28_ARB                               = $873C;
   GL_MODELVIEW29_ARB                               = $873D;
   GL_MODELVIEW30_ARB                               = $873E;
   GL_MODELVIEW31_ARB                               = $873F;

   // GL_SGIS_texture_lod
   GL_TEXTURE_MIN_LOD_SGIS                          = $813A;
   GL_TEXTURE_MAX_LOD_SGIS                          = $813B;
   GL_TEXTURE_BASE_LEVEL_SGIS                       = $813C;
   GL_TEXTURE_MAX_LEVEL_SGIS                        = $813D;

   // GL_SGIS_multisample
   GL_MULTISAMPLE_SGIS                              = $809D;
   GL_SAMPLE_ALPHA_TO_MASK_SGIS                     = $809E;
   GL_SAMPLE_ALPHA_TO_ONE_SGIS                      = $809F;
   GL_SAMPLE_MASK_SGIS                              = $80A0;
   GL_1PASS_SGIS                                    = $80A1;
   GL_2PASS_0_SGIS                                  = $80A2;
   GL_2PASS_1_SGIS                                  = $80A3;
   GL_4PASS_0_SGIS                                  = $80A4;
   GL_4PASS_1_SGIS                                  = $80A5;
   GL_4PASS_2_SGIS                                  = $80A6;
   GL_4PASS_3_SGIS                                  = $80A7;
   GL_SAMPLE_BUFFERS_SGIS                           = $80A8;
   GL_SAMPLES_SGIS                                  = $80A9;
   GL_SAMPLE_MASK_VALUE_SGIS                        = $80AA;
   GL_SAMPLE_MASK_INVERT_SGIS                       = $80AB;
   GL_SAMPLE_PATTERN_SGIS                           = $80AC;

   // GL_SGIS_generate_mipmap
   GL_GENERATE_MIPMAP_SGIS                          = $8191;
   GL_GENERATE_MIPMAP_HINT_SGIS                     = $8192;

   // GL_SGIX_shadow
   GL_TEXTURE_COMPARE_SGIX                          = $819A;
   GL_TEXTURE_COMPARE_OPERATOR_SGIX                 = $819B;
   GL_TEXTURE_LEQUAL_R_SGIX                         = $819C;
   GL_TEXTURE_GEQUAL_R_SGIX                         = $819D;

   // GL_SGIS_texture_edge_clamp
   GL_CLAMP_TO_EDGE_SGIS                            = $812F;

   // GL_SGIS_texture_border_clamp
   GL_CLAMP_TO_BORDER_SGIS                          = $812D;

   // GL_EXT_paletted_texture
   GL_TEXTURE_INDEX_SIZE_EXT                        = $80ED;

   // GL_SGIX_shadow_ambient
   GL_SHADOW_AMBIENT_SGIX                           = $80BF;

   // GL_IBM_rasterpos_clip
   GL_RASTER_POSITION_UNCLIPPED_IBM                 = $19262;

   // GL_EXT_draw_range_elements
   GL_MAX_ELEMENTS_VERTICES_EXT                     = $80E8;
   GL_MAX_ELEMENTS_INDICES_EXT                      = $80E9;

   // GL_HP_occlusion_test
   GL_OCCLUSION_TEST_HP                             = $8165;
   GL_OCCLUSION_TEST_RESULT_HP                      = $8166;

   // GL_EXT_separate_specular_color
   GL_LIGHT_MODEL_COLOR_CONTROL_EXT                 = $81F8;
   GL_SINGLE_COLOR_EXT                              = $81F9;
   GL_SEPARATE_SPECULAR_COLOR_EXT                   = $81FA;

   // GL_EXT_secondary_color
   GL_COLOR_SUM_EXT                                 = $8458;
   GL_CURRENT_SECONDARY_COLOR_EXT                   = $8459;
   GL_SECONDARY_COLOR_ARRAY_SIZE_EXT                = $845A;
   GL_SECONDARY_COLOR_ARRAY_TYPE_EXT                = $845B;
   GL_SECONDARY_COLOR_ARRAY_STRIDE_EXT              = $845C;
   GL_SECONDARY_COLOR_ARRAY_POINTER_EXT             = $845D;
   GL_SECONDARY_COLOR_ARRAY_EXT                     = $845E;

   // GL_EXT_fog_coord
   GL_FOG_COORDINATE_SOURCE_EXT                     = $8450;
   GL_FOG_COORDINATE_EXT                            = $8451;
   GL_FRAGMENT_DEPTH_EXT                            = $8452;
   GL_CURRENT_FOG_COORDINATE_EXT                    = $8453;
   GL_FOG_COORDINATE_ARRAY_TYPE_EXT                 = $8454;
   GL_FOG_COORDINATE_ARRAY_STRIDE_EXT               = $8455;
   GL_FOG_COORDINATE_ARRAY_POINTER_EXT              = $8456;
   GL_FOG_COORDINATE_ARRAY_EXT                      = $8457;

   // GL_EXT_texture_env_combine
   GL_SOURCE3_RGB_EXT                               = $8583;
   GL_SOURCE4_RGB_EXT                               = $8584;
   GL_SOURCE5_RGB_EXT                               = $8585;
   GL_SOURCE6_RGB_EXT                               = $8586;
   GL_SOURCE7_RGB_EXT                               = $8587;
   GL_SOURCE3_ALPHA_EXT                             = $858B;
   GL_SOURCE4_ALPHA_EXT                             = $858C;
   GL_SOURCE5_ALPHA_EXT                             = $858D;
   GL_SOURCE6_ALPHA_EXT                             = $858E;
   GL_SOURCE7_ALPHA_EXT                             = $858F;
   GL_OPERAND3_RGB_EXT                              = $8593;
   GL_OPERAND4_RGB_EXT                              = $8594;
   GL_OPERAND5_RGB_EXT                              = $8595;
   GL_OPERAND6_RGB_EXT                              = $8596;
   GL_OPERAND7_RGB_EXT                              = $8597;
   GL_OPERAND3_ALPHA_EXT                            = $859B;
   GL_OPERAND4_ALPHA_EXT                            = $859C;
   GL_OPERAND5_ALPHA_EXT                            = $859D;
   GL_OPERAND6_ALPHA_EXT                            = $859E;
   GL_OPERAND7_ALPHA_EXT                            = $859F;

   // GL_EXT_blend_func_separate
   GL_BLEND_DST_RGB_EXT                             = $80C8;
   GL_BLEND_SRC_RGB_EXT                             = $80C9;
   GL_BLEND_DST_ALPHA_EXT                           = $80CA;
   GL_BLEND_SRC_ALPHA_EXT                           = $80CB;

   // GL_EXT_texture_cube_map
   GL_NORMAL_MAP_EXT                                = $8511;
   GL_REFLECTION_MAP_EXT                            = $8512;
   GL_TEXTURE_CUBE_MAP_EXT                          = $8513;
   GL_TEXTURE_BINDING_CUBE_MAP_EXT                  = $8514;
   GL_TEXTURE_CUBE_MAP_POSITIVE_X_EXT               = $8515;
   GL_TEXTURE_CUBE_MAP_NEGATIVE_X_EXT               = $8516;
   GL_TEXTURE_CUBE_MAP_POSITIVE_Y_EXT               = $8517;
   GL_TEXTURE_CUBE_MAP_NEGATIVE_Y_EXT               = $8518;
   GL_TEXTURE_CUBE_MAP_POSITIVE_Z_EXT               = $8519;
   GL_TEXTURE_CUBE_MAP_NEGATIVE_Z_EXT               = $851A;
   GL_PROXY_TEXTURE_CUBE_MAP_EXT                    = $851B;
   GL_MAX_CUBE_MAP_TEXTURE_SIZE_EXT                 = $851C;

   // GL_EXT_texture_lod_bias
   GL_MAX_TEXTURE_LOD_BIAS_EXT                      = $84FD;
   GL_TEXTURE_FILTER_CONTROL_EXT                    = $8500;
   GL_TEXTURE_LOD_BIAS_EXT                          = $8501;

   // GL_EXT_texture_filter_anisotropic
   GL_TEXTURE_MAX_ANISOTROPY_EXT                    = $84FE;
   GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT                = $84FF;

   // GL_NV_light_max_exponent
   GL_MAX_SHININESS_NV                              = $8504;
   GL_MAX_SPOT_EXPONENT_NV                          = $8505;

   // GL_NV_vertex_array_range
   GL_VERTEX_ARRAY_RANGE_NV                         = $851D;
   GL_VERTEX_ARRAY_RANGE_LENGTH_NV                  = $851E;
   GL_VERTEX_ARRAY_RANGE_VALID_NV                   = $851F;
   GL_MAX_VERTEX_ARRAY_RANGE_ELEMENT_NV             = $8520;
   GL_VERTEX_ARRAY_RANGE_POINTER_NV                 = $8521;

   // GL_NV_vertex_array_range2
   GL_VERTEX_ARRAY_RANGE_WITHOUT_FLUSH_NV          = $8533;

   // GL_NV_register_combiners
   GL_REGISTER_COMBINERS_NV                         = $8522;
   GL_VARIABLE_A_NV                                 = $8523;
   GL_VARIABLE_B_NV                                 = $8524;
   GL_VARIABLE_C_NV                                 = $8525;
   GL_VARIABLE_D_NV                                 = $8526;
   GL_VARIABLE_E_NV                                 = $8527;
   GL_VARIABLE_F_NV                                 = $8528;
   GL_VARIABLE_G_NV                                 = $8529;
   GL_CONSTANT_COLOR0_NV                            = $852A;
   GL_CONSTANT_COLOR1_NV                            = $852B;
   GL_PRIMARY_COLOR_NV                              = $852C;
   GL_SECONDARY_COLOR_NV                            = $852D;
   GL_SPARE0_NV                                     = $852E;
   GL_SPARE1_NV                                     = $852F;
   GL_DISCARD_NV                                    = $8530;
   GL_E_TIMES_F_NV                                  = $8531;
   GL_SPARE0_PLUS_SECONDARY_COLOR_NV                = $8532;
   GL_UNSIGNED_IDENTITY_NV                          = $8536;
   GL_UNSIGNED_INVERT_NV                            = $8537;
   GL_EXPAND_NORMAL_NV                              = $8538;
   GL_EXPAND_NEGATE_NV                              = $8539;
   GL_HALF_BIAS_NORMAL_NV                           = $853A;
   GL_HALF_BIAS_NEGATE_NV                           = $853B;
   GL_SIGNED_IDENTITY_NV                            = $853C;
   GL_SIGNED_NEGATE_NV                              = $853D;
   GL_SCALE_BY_TWO_NV                               = $853E;
   GL_SCALE_BY_FOUR_NV                              = $853F;
   GL_SCALE_BY_ONE_HALF_NV                          = $8540;
   GL_BIAS_BY_NEGATIVE_ONE_HALF_NV                  = $8541;
   GL_COMBINER_INPUT_NV                             = $8542;
   GL_COMBINER_MAPPING_NV                           = $8543;
   GL_COMBINER_COMPONENT_USAGE_NV                   = $8544;
   GL_COMBINER_AB_DOT_PRODUCT_NV                    = $8545;
   GL_COMBINER_CD_DOT_PRODUCT_NV                    = $8546;
   GL_COMBINER_MUX_SUM_NV                           = $8547;
   GL_COMBINER_SCALE_NV                             = $8548;
   GL_COMBINER_BIAS_NV                              = $8549;
   GL_COMBINER_AB_OUTPUT_NV                         = $854A;
   GL_COMBINER_CD_OUTPUT_NV                         = $854B;
   GL_COMBINER_SUM_OUTPUT_NV                        = $854C;
   GL_MAX_GENERAL_COMBINERS_NV                      = $854D;
   GL_NUM_GENERAL_COMBINERS_NV                      = $854E;
   GL_COLOR_SUM_CLAMP_NV                            = $854F;
   GL_COMBINER0_NV                                  = $8550;
   GL_COMBINER1_NV                                  = $8551;
   GL_COMBINER2_NV                                  = $8552;
   GL_COMBINER3_NV                                  = $8553;
   GL_COMBINER4_NV                                  = $8554;
   GL_COMBINER5_NV                                  = $8555;
   GL_COMBINER6_NV                                  = $8556;
   GL_COMBINER7_NV                                  = $8557;

   // GL_NV_fog_distance
   GL_FOG_DISTANCE_MODE_NV                          = $855A;
   GL_EYE_RADIAL_NV                                 = $855B;
   GL_EYE_PLANE_ABSOLUTE_NV                         = $855C;

   // GL_EXT_texture_compression_s3tc
   GL_COMPRESSED_RGB_S3TC_DXT1_EXT                  = $83F0;
   GL_COMPRESSED_RGBA_S3TC_DXT1_EXT                 = $83F1;
   GL_COMPRESSED_RGBA_S3TC_DXT3_EXT                 = $83F2;
   GL_COMPRESSED_RGBA_S3TC_DXT5_EXT                 = $83F3;

   // GL_3DFX_texture_compression_FXT1
   GL_COMPRESSED_RGB_FXT1_3DFX                      = $86B0;
   GL_COMPRESSED_RGBA_FXT1_3DFX                     = $86B1;

   // GL_3DFX_multisample
   GL_MULTISAMPLE_3DFX                              = $86B2;
   GL_SAMPLE_BUFFERS_3DFX                           = $86B3;
   GL_SAMPLES_3DFX                                  = $86B4;
   GL_MULTISAMPLE_BIT_3DFX                          = $20000000;

   // GL_EXT_multisample
   GL_MULTISAMPLE_EXT                               = $809D;
   GL_SAMPLE_ALPHA_TO_MASK_EXT                      = $809E;
   GL_SAMPLE_ALPHA_TO_ONE_EXT                       = $809F;
   GL_SAMPLE_MASK_EXT                               = $80A0;
   GL_1PASS_EXT                                     = $80A1;
   GL_2PASS_0_EXT                                   = $80A2;
   GL_2PASS_1_EXT                                   = $80A3;
   GL_4PASS_0_EXT                                   = $80A4;
   GL_4PASS_1_EXT                                   = $80A5;
   GL_4PASS_2_EXT                                   = $80A6;
   GL_4PASS_3_EXT                                   = $80A7;
   GL_SAMPLE_BUFFERS_EXT                            = $80A8;
   GL_SAMPLES_EXT                                   = $80A9;
   GL_SAMPLE_MASK_VALUE_EXT                         = $80AA;
   GL_SAMPLE_MASK_INVERT_EXT                        = $80AB;
   GL_SAMPLE_PATTERN_EXT                            = $80AC;

   // GL_EXT_clip_volume_hint
   GL_CLIP_VOLUME_CLIPPING_HINT_EXT                 = $80F0;

   // GL_SGIS_texture_color_mask
   GL_TEXTURE_COLOR_WRITEMASK_SGIS                  = $81EF;

   // GL_NV_vertex_program
   GL_VERTEX_PROGRAM_NV                             = $8620;
   GL_VERTEX_STATE_PROGRAM_NV                       = $8621;
   GL_ATTRIB_ARRAY_SIZE_NV                          = $8623;
   GL_ATTRIB_ARRAY_STRIDE_NV                        = $8624;
   GL_ATTRIB_ARRAY_TYPE_NV                          = $8625;
   GL_CURRENT_ATTRIB_NV                             = $8626;
   GL_PROGRAM_LENGTH_NV                             = $8627;
   GL_PROGRAM_STRING_NV                             = $8628;
   GL_MODELVIEW_PROJECTION_NV                       = $8629;
   GL_IDENTITY_NV                                   = $862A;
   GL_INVERSE_NV                                    = $862B;
   GL_TRANSPOSE_NV                                  = $862C;
   GL_INVERSE_TRANSPOSE_NV                          = $862D;
   GL_MAX_TRACK_MATRIX_STACK_DEPTH_NV               = $862E;
   GL_MAX_TRACK_MATRICES_NV                         = $862F;
   GL_MATRIX0_NV                                    = $8630;
   GL_MATRIX1_NV                                    = $8631;
   GL_MATRIX2_NV                                    = $8632;
   GL_MATRIX3_NV                                    = $8633;
   GL_MATRIX4_NV                                    = $8634;
   GL_MATRIX5_NV                                    = $8635;
   GL_MATRIX6_NV                                    = $8636;
   GL_MATRIX7_NV                                    = $8637;
   GL_CURRENT_MATRIX_STACK_DEPTH_NV                 = $8640;
   GL_CURRENT_MATRIX_NV                             = $8641;
   GL_VERTEX_PROGRAM_POINT_SIZE_NV                  = $8642;
   GL_VERTEX_PROGRAM_TWO_SIDE_NV                    = $8643;
   GL_PROGRAM_PARAMETER_NV                          = $8644;
   GL_ATTRIB_ARRAY_POINTER_NV                       = $8645;
   GL_PROGRAM_TARGET_NV                             = $8646;
   GL_PROGRAM_RESIDENT_NV                           = $8647;
   GL_TRACK_MATRIX_NV                               = $8648;
   GL_TRACK_MATRIX_TRANSFORM_NV                     = $8649;
   GL_VERTEX_PROGRAM_BINDING_NV                     = $864A;
   GL_PROGRAM_ERROR_POSITION_NV                     = $864B;
   GL_VERTEX_ATTRIB_ARRAY0_NV                       = $8650;
   GL_VERTEX_ATTRIB_ARRAY1_NV                       = $8651;
   GL_VERTEX_ATTRIB_ARRAY2_NV                       = $8652;
   GL_VERTEX_ATTRIB_ARRAY3_NV                       = $8653;
   GL_VERTEX_ATTRIB_ARRAY4_NV                       = $8654;
   GL_VERTEX_ATTRIB_ARRAY5_NV                       = $8655;
   GL_VERTEX_ATTRIB_ARRAY6_NV                       = $8656;
   GL_VERTEX_ATTRIB_ARRAY7_NV                       = $8657;
   GL_VERTEX_ATTRIB_ARRAY8_NV                       = $8658;
   GL_VERTEX_ATTRIB_ARRAY9_NV                       = $8659;
   GL_VERTEX_ATTRIB_ARRAY10_NV                      = $865A;
   GL_VERTEX_ATTRIB_ARRAY11_NV                      = $865B;
   GL_VERTEX_ATTRIB_ARRAY12_NV                      = $865C;
   GL_VERTEX_ATTRIB_ARRAY13_NV                      = $865D;
   GL_VERTEX_ATTRIB_ARRAY14_NV                      = $865E;
   GL_VERTEX_ATTRIB_ARRAY15_NV                      = $865F;
   GL_MAP1_VERTEX_ATTRIB0_4_NV                      = $8660;
   GL_MAP1_VERTEX_ATTRIB1_4_NV                      = $8661;
   GL_MAP1_VERTEX_ATTRIB2_4_NV                      = $8662;
   GL_MAP1_VERTEX_ATTRIB3_4_NV                      = $8663;
   GL_MAP1_VERTEX_ATTRIB4_4_NV                      = $8664;
   GL_MAP1_VERTEX_ATTRIB5_4_NV                      = $8665;
   GL_MAP1_VERTEX_ATTRIB6_4_NV                      = $8666;
   GL_MAP1_VERTEX_ATTRIB7_4_NV                      = $8667;
   GL_MAP1_VERTEX_ATTRIB8_4_NV                      = $8668;
   GL_MAP1_VERTEX_ATTRIB9_4_NV                      = $8669;
   GL_MAP1_VERTEX_ATTRIB10_4_NV                     = $866A;
   GL_MAP1_VERTEX_ATTRIB11_4_NV                     = $866B;
   GL_MAP1_VERTEX_ATTRIB12_4_NV                     = $866C;
   GL_MAP1_VERTEX_ATTRIB13_4_NV                     = $866D;
   GL_MAP1_VERTEX_ATTRIB14_4_NV                     = $866E;
   GL_MAP1_VERTEX_ATTRIB15_4_NV                     = $866F;
   GL_MAP2_VERTEX_ATTRIB0_4_NV                      = $8670;
   GL_MAP2_VERTEX_ATTRIB1_4_NV                      = $8671;
   GL_MAP2_VERTEX_ATTRIB2_4_NV                      = $8672;
   GL_MAP2_VERTEX_ATTRIB3_4_NV                      = $8673;
   GL_MAP2_VERTEX_ATTRIB4_4_NV                      = $8674;
   GL_MAP2_VERTEX_ATTRIB5_4_NV                      = $8675;
   GL_MAP2_VERTEX_ATTRIB6_4_NV                      = $8676;
   GL_MAP2_VERTEX_ATTRIB7_4_NV                      = $8677;
   GL_MAP2_VERTEX_ATTRIB8_4_NV                      = $8678;
   GL_MAP2_VERTEX_ATTRIB9_4_NV                      = $8679;
   GL_MAP2_VERTEX_ATTRIB10_4_NV                     = $867A;
   GL_MAP2_VERTEX_ATTRIB11_4_NV                     = $867B;
   GL_MAP2_VERTEX_ATTRIB12_4_NV                     = $867C;
   GL_MAP2_VERTEX_ATTRIB13_4_NV                     = $867D;
   GL_MAP2_VERTEX_ATTRIB14_4_NV                     = $867E;
   GL_MAP2_VERTEX_ATTRIB15_4_NV                     = $867F;

   // NV_multisample_filter_hint
   GL_MULTISAMPLE_FILTER_HINT_NV                    = $8534;

   // WGL_ARB_pixel_format
   WGL_NUMBER_PIXEL_FORMATS_ARB                     = $2000;
   WGL_DRAW_TO_WINDOW_ARB                           = $2001;
   WGL_DRAW_TO_BITMAP_ARB                           = $2002;
   WGL_ACCELERATION_ARB                             = $2003;
   WGL_NEED_PALETTE_ARB                             = $2004;
   WGL_NEED_SYSTEM_PALETTE_ARB                      = $2005;
   WGL_SWAP_LAYER_BUFFERS_ARB                       = $2006;
   WGL_SWAP_METHOD_ARB                              = $2007;
   WGL_NUMBER_OVERLAYS_ARB                          = $2008;
   WGL_NUMBER_UNDERLAYS_ARB                         = $2009;
   WGL_TRANSPARENT_ARB                              = $200A;
   WGL_TRANSPARENT_RED_VALUE_ARB                    = $2037;
   WGL_TRANSPARENT_GREEN_VALUE_ARB                  = $2038;
   WGL_TRANSPARENT_BLUE_VALUE_ARB                   = $2039;
   WGL_TRANSPARENT_ALPHA_VALUE_ARB                  = $203A;
   WGL_TRANSPARENT_INDEX_VALUE_ARB                  = $203B;
   WGL_SHARE_DEPTH_ARB                              = $200C;
   WGL_SHARE_STENCIL_ARB                            = $200D;
   WGL_SHARE_ACCUM_ARB                              = $200E;
   WGL_SUPPORT_GDI_ARB                              = $200F;
   WGL_SUPPORT_OPENGL_ARB                           = $2010;
   WGL_DOUBLE_BUFFER_ARB                            = $2011;
   WGL_STEREO_ARB                                   = $2012;
   WGL_PIXEL_TYPE_ARB                               = $2013;
   WGL_COLOR_BITS_ARB                               = $2014;
   WGL_RED_BITS_ARB                                 = $2015;
   WGL_RED_SHIFT_ARB                                = $2016;
   WGL_GREEN_BITS_ARB                               = $2017;
   WGL_GREEN_SHIFT_ARB                              = $2018;
   WGL_BLUE_BITS_ARB                                = $2019;
   WGL_BLUE_SHIFT_ARB                               = $201A;
   WGL_ALPHA_BITS_ARB                               = $201B;
   WGL_ALPHA_SHIFT_ARB                              = $201C;
   WGL_ACCUM_BITS_ARB                               = $201D;
   WGL_ACCUM_RED_BITS_ARB                           = $201E;
   WGL_ACCUM_GREEN_BITS_ARB                         = $201F;
   WGL_ACCUM_BLUE_BITS_ARB                          = $2020;
   WGL_ACCUM_ALPHA_BITS_ARB                         = $2021;
   WGL_DEPTH_BITS_ARB                               = $2022;
   WGL_STENCIL_BITS_ARB                             = $2023;
   WGL_AUX_BUFFERS_ARB                              = $2024;
   WGL_NO_ACCELERATION_ARB                          = $2025;
   WGL_GENERIC_ACCELERATION_ARB                     = $2026;
   WGL_FULL_ACCELERATION_ARB                        = $2027;
   WGL_SWAP_EXCHANGE_ARB                            = $2028;
   WGL_SWAP_COPY_ARB                                = $2029;
   WGL_SWAP_UNDEFINED_ARB                           = $202A;
   WGL_TYPE_RGBA_ARB                                = $202B;
   WGL_TYPE_COLORINDEX_ARB                          = $202C;

   // WGL_NV_float_buffer
   WGL_FLOAT_COMPONENTS_NV                          = $20B0;
   WGL_BIND_TO_TEXTURE_RECTANGLE_FLOAT_R_NV         = $20B1;
   WGL_BIND_TO_TEXTURE_RECTANGLE_FLOAT_RG_NV        = $20B2;
   WGL_BIND_TO_TEXTURE_RECTANGLE_FLOAT_RGB_NV       = $20B3;
   WGL_BIND_TO_TEXTURE_RECTANGLE_FLOAT_RGBA_NV      = $20B4;
   WGL_TEXTURE_FLOAT_R_NV                           = $20B5;
   WGL_TEXTURE_FLOAT_RG_NV                          = $20B6;
   WGL_TEXTURE_FLOAT_RGB_NV                         = $20B7;
   WGL_TEXTURE_FLOAT_RGBA_NV                        = $20B8;

   // GL_NV_float_buffer
   GL_FLOAT_R_NV                                    = $8880;
   GL_FLOAT_RG_NV                                   = $8881;
   GL_FLOAT_RGB_NV                                  = $8882;
   GL_FLOAT_RGBA_NV                                 = $8883;
   GL_FLOAT_R16_NV                                  = $8884;
   GL_FLOAT_R32_NV                                  = $8885;
   GL_FLOAT_RG16_NV                                 = $8886;
   GL_FLOAT_RG32_NV                                 = $8887;
   GL_FLOAT_RGB16_NV                                = $8888;
   GL_FLOAT_RGB32_NV                                = $8889;
   GL_FLOAT_RGBA16_NV                               = $888A;
   GL_FLOAT_RGBA32_NV                               = $888B;
   GL_TEXTURE_FLOAT_COMPONENTS_NV                   = $888C;
   GL_FLOAT_CLEAR_COLOR_VALUE_NV                    = $888D;
   GL_FLOAT_RGBA_MODE_NV                            = $888E;

   // WGL_ATI_pixel_format_float
   WGL_TYPE_RGBA_FLOAT_ATI                          = $21A0;
   GL_TYPE_RGBA_FLOAT_ATI                           = $8820;
   GL_COLOR_CLEAR_UNCLAMPED_VALUE_ATI               = $8835;

   // GL_ATI_texture_float
   GL_RGBA_FLOAT32_ATI                              = $8814;
   GL_RGB_FLOAT32_ATI                               = $8815;
   GL_ALPHA_FLOAT32_ATI                             = $8816;
   GL_INTENSITY_FLOAT32_ATI                         = $8817;
   GL_LUMINANCE_FLOAT32_ATI                         = $8818;
   GL_LUMINANCE_ALPHA_FLOAT32_ATI                   = $8819;
   GL_RGBA_FLOAT16_ATI                              = $881A;
   GL_RGB_FLOAT16_ATI                               = $881B;
   GL_ALPHA_FLOAT16_ATI                             = $881C;
   GL_INTENSITY_FLOAT16_ATI                         = $881D;
   GL_LUMINANCE_FLOAT16_ATI                         = $881E;
   GL_LUMINANCE_ALPHA_FLOAT16_ATI                   = $881F;

   // GL_ATI_draw_buffers
   GL_MAX_DRAW_BUFFERS_ATI                          = $8824;
   GL_DRAW_BUFFER0_ATI                              = $8825;
   GL_DRAW_BUFFER1_ATI                              = $8826;
   GL_DRAW_BUFFER2_ATI                              = $8827;
   GL_DRAW_BUFFER3_ATI                              = $8828;
   GL_DRAW_BUFFER4_ATI                              = $8829;
   GL_DRAW_BUFFER5_ATI                              = $882A;
   GL_DRAW_BUFFER6_ATI                              = $882B;
   GL_DRAW_BUFFER7_ATI                              = $882C;
   GL_DRAW_BUFFER8_ATI                              = $882D;
   GL_DRAW_BUFFER9_ATI                              = $882E;
   GL_DRAW_BUFFER10_ATI                             = $882F;
   GL_DRAW_BUFFER11_ATI                             = $8830;
   GL_DRAW_BUFFER12_ATI                             = $8831;
   GL_DRAW_BUFFER13_ATI                             = $8832;
   GL_DRAW_BUFFER14_ATI                             = $8833;
   GL_DRAW_BUFFER15_ATI                             = $8834;

   // GL_ATI_texture_compression_3dc
   GL_COMPRESSED_LUMINANCE_ALPHA_3DC_ATI            = $8837;

   // WGL_ARB_pbuffer
type
   HPBUFFERARB= Integer;
const
   WGL_DRAW_TO_PBUFFER_ARB                          = $202D;
   WGL_MAX_PBUFFER_PIXELS_ARB                       = $202E;
   WGL_MAX_PBUFFER_WIDTH_ARB                        = $202F;
   WGL_MAX_PBUFFER_HEIGHT_ARB                       = $2030;
   WGL_PBUFFER_LARGEST_ARB                          = $2033;
   WGL_PBUFFER_WIDTH_ARB                            = $2034;
   WGL_PBUFFER_HEIGHT_ARB                           = $2035;
   WGL_PBUFFER_LOST_ARB                             = $2036;

   // WGL_ARB_buffer_region
   WGL_FRONT_COLOR_BUFFER_BIT_ARB                   = $00000001;
   WGL_BACK_COLOR_BUFFER_BIT_ARB                    = $00000002;
   WGL_DEPTH_BUFFER_BIT_ARB                         = $00000004;
   WGL_STENCIL_BUFFER_BIT_ARB                       = $00000008;

   // ********** GLU generic constants **********

   // Errors: (return value 0= no error)
   GLU_INVALID_ENUM                                 = 100900;
   GLU_INVALID_VALUE                                = 100901;
   GLU_OUT_OF_MEMORY                                = 100902;
   GLU_INCOMPATIBLE_GL_VERSION                      = 100903;

   // StringName
   GLU_VERSION                                      = 100800;
   GLU_EXTENSIONS                                   = 100801;

   // Boolean
   GLU_TRUE                                         = GL_TRUE;
   GLU_FALSE                                        = GL_FALSE;

   // Quadric constants
   // QuadricNormal
   GLU_SMOOTH                                       = 100000;
   GLU_FLAT                                         = 100001;
   GLU_NONE                                         = 100002;

   // QuadricDrawStyle
   GLU_POINT                                        = 100010;
   GLU_LINE                                         = 100011;
   GLU_FILL                                         = 100012;
   GLU_SILHOUETTE                                   = 100013;

   // QuadricOrientation
   GLU_OUTSIDE                                      = 100020;
   GLU_INSIDE                                       = 100021;

   // Tesselation constants
   GLU_TESS_MAX_COORD                               = 1.0e150;

   // TessProperty
   GLU_TESS_WINDING_RULE                            = 100140;
   GLU_TESS_BOUNDARY_ONLY                           = 100141;
   GLU_TESS_TOLERANCE                               = 100142;

   // TessWinding
   GLU_TESS_WINDING_ODD                             = 100130;
   GLU_TESS_WINDING_NONZERO                         = 100131;
   GLU_TESS_WINDING_POSITIVE                        = 100132;
   GLU_TESS_WINDING_NEGATIVE                        = 100133;
   GLU_TESS_WINDING_ABS_GEQ_TWO                     = 100134;

   // TessCallback
   GLU_TESS_BEGIN                                   = 100100; // TGLUTessBeginProc
   GLU_TESS_VERTEX                                  = 100101; // TGLUTessVertexProc
   GLU_TESS_END                                     = 100102; // TGLUTessEndProc
   GLU_TESS_ERROR                                   = 100103; // TGLUTessErrorProc
   GLU_TESS_EDGE_FLAG                               = 100104; // TGLUTessEdgeFlagProc
   GLU_TESS_COMBINE                                 = 100105; // TGLUTessCombineProc
   GLU_TESS_BEGIN_DATA                              = 100106; // TGLUTessBeginDataProc
   GLU_TESS_VERTEX_DATA                             = 100107; // TGLUTessVertexDataProc
   GLU_TESS_END_DATA                                = 100108; // TGLUTessEndDataProc
   GLU_TESS_ERROR_DATA                              = 100109; // TGLUTessErrorDataProc
   GLU_TESS_EDGE_FLAG_DATA                          = 100110; // TGLUTessEdgeFlagDataProc
   GLU_TESS_COMBINE_DATA                            = 100111; // TGLUTessCombineDataProc

   // TessError
   GLU_TESS_ERROR1                                  = 100151;
   GLU_TESS_ERROR2                                  = 100152;
   GLU_TESS_ERROR3                                  = 100153;
   GLU_TESS_ERROR4                                  = 100154;
   GLU_TESS_ERROR5                                  = 100155;
   GLU_TESS_ERROR6                                  = 100156;
   GLU_TESS_ERROR7                                  = 100157;
   GLU_TESS_ERROR8                                  = 100158;

   GLU_TESS_MISSING_BEGIN_POLYGON                   = GLU_TESS_ERROR1;
   GLU_TESS_MISSING_BEGIN_CONTOUR                   = GLU_TESS_ERROR2;
   GLU_TESS_MISSING_END_POLYGON                     = GLU_TESS_ERROR3;
   GLU_TESS_MISSING_END_CONTOUR                     = GLU_TESS_ERROR4;
   GLU_TESS_COORD_TOO_LARGE                         = GLU_TESS_ERROR5;
   GLU_TESS_NEED_COMBINE_CALLBACK                   = GLU_TESS_ERROR6;

   // NURBS constants

   // NurbsProperty
   GLU_AUTO_LOAD_MATRIX                             = 100200;
   GLU_CULLING                                      = 100201;
   GLU_SAMPLING_TOLERANCE                           = 100203;
   GLU_DISPLAY_MODE                                 = 100204;
   GLU_PARAMETRIC_TOLERANCE                         = 100202;
   GLU_SAMPLING_METHOD                              = 100205;
   GLU_U_STEP                                       = 100206;
   GLU_V_STEP                                       = 100207;

   // NurbsSampling
   GLU_PATH_LENGTH                                  = 100215;
   GLU_PARAMETRIC_ERROR                             = 100216;
   GLU_DOMAIN_DISTANCE                              = 100217;

   // NurbsTrim
   GLU_MAP1_TRIM_2                                  = 100210;
   GLU_MAP1_TRIM_3                                  = 100211;

   // NurbsDisplay
   GLU_OUTLINE_POLYGON                              = 100240;
   GLU_OUTLINE_PATCH                                = 100241;

   // NurbsErrors
   GLU_NURBS_ERROR1                                 = 100251;
   GLU_NURBS_ERROR2                                 = 100252;
   GLU_NURBS_ERROR3                                 = 100253;
   GLU_NURBS_ERROR4                                 = 100254;
   GLU_NURBS_ERROR5                                 = 100255;
   GLU_NURBS_ERROR6                                 = 100256;
   GLU_NURBS_ERROR7                                 = 100257;
   GLU_NURBS_ERROR8                                 = 100258;
   GLU_NURBS_ERROR9                                 = 100259;
   GLU_NURBS_ERROR10                                = 100260;
   GLU_NURBS_ERROR11                                = 100261;
   GLU_NURBS_ERROR12                                = 100262;
   GLU_NURBS_ERROR13                                = 100263;
   GLU_NURBS_ERROR14                                = 100264;
   GLU_NURBS_ERROR15                                = 100265;
   GLU_NURBS_ERROR16                                = 100266;
   GLU_NURBS_ERROR17                                = 100267;
   GLU_NURBS_ERROR18                                = 100268;
   GLU_NURBS_ERROR19                                = 100269;
   GLU_NURBS_ERROR20                                = 100270;
   GLU_NURBS_ERROR21                                = 100271;
   GLU_NURBS_ERROR22                                = 100272;
   GLU_NURBS_ERROR23                                = 100273;
   GLU_NURBS_ERROR24                                = 100274;
   GLU_NURBS_ERROR25                                = 100275;
   GLU_NURBS_ERROR26                                = 100276;
   GLU_NURBS_ERROR27                                = 100277;
   GLU_NURBS_ERROR28                                = 100278;
   GLU_NURBS_ERROR29                                = 100279;
   GLU_NURBS_ERROR30                                = 100280;
   GLU_NURBS_ERROR31                                = 100281;
   GLU_NURBS_ERROR32                                = 100282;
   GLU_NURBS_ERROR33                                = 100283;
   GLU_NURBS_ERROR34                                = 100284;
   GLU_NURBS_ERROR35                                = 100285;
   GLU_NURBS_ERROR36                                = 100286;
   GLU_NURBS_ERROR37                                = 100287;

   // Contours types -- obsolete!
   GLU_CW                                           = 100120;
   GLU_CCW                                          = 100121;
   GLU_INTERIOR                                     = 100122;
   GLU_EXTERIOR                                     = 100123;
   GLU_UNKNOWN                                      = 100124;

   // Names without "TESS_" prefix
   GLU_BEGIN                                        = GLU_TESS_BEGIN;
   GLU_VERTEX                                       = GLU_TESS_VERTEX;
   GLU_END                                          = GLU_TESS_END;
   GLU_ERROR                                        = GLU_TESS_ERROR;
   GLU_EDGE_FLAG                                    = GLU_TESS_EDGE_FLAG;

   GLX_VERSION_1_1                                  = 1;
   GLX_VERSION_1_2                                  = 1;
   GLX_VERSION_1_3                                  = 1;
   GLX_EXTENSION_NAME                               = 'GLX';
   GLX_USE_GL                                       = 1;
   GLX_BUFFER_SIZE                                  = 2;
   GLX_LEVEL                                        = 3;
   GLX_RGBA                                         = 4;
   GLX_DOUBLEBUFFER                                 = 5;
   GLX_STEREO                                       = 6;
   GLX_AUX_BUFFERS                                  = 7;
   GLX_RED_SIZE                                     = 8;
   GLX_GREEN_SIZE                                   = 9;
   GLX_BLUE_SIZE                                    = 10;
   GLX_ALPHA_SIZE                                   = 11;
   GLX_DEPTH_SIZE                                   = 12;
   GLX_STENCIL_SIZE                                 = 13;
   GLX_ACCUM_RED_SIZE                               = 14;
   GLX_ACCUM_GREEN_SIZE                             = 15;
   GLX_ACCUM_BLUE_SIZE                              = 16;
   GLX_ACCUM_ALPHA_SIZE                             = 17;

   // Error codes returned by glXGetConfig:
   GLX_BAD_SCREEN                                   = 1;
   GLX_BAD_ATTRIBUTE                                = 2;
   GLX_NO_EXTENSION                                 = 3;
   GLX_BAD_VISUAL                                   = 4;
   GLX_BAD_CONTEXT                                  = 5;
   GLX_BAD_VALUE                                    = 6;
   GLX_BAD_ENUM                                     = 7;

   // GLX 1.1 and later:
   GLX_VENDOR                                       = 1;
   GLX_VERSION                                      = 2;
   GLX_EXTENSIONS                                   = 3;

   // GLX 1.3 and later:
   GLX_CONFIG_CAVEAT                                = $20;
   GLX_DONT_CARE                                    = $FFFFFFFF;
   GLX_SLOW_CONFIG                                  = $8001;
   GLX_NON_CONFORMANT_CONFIG                        = $800D;
   GLX_X_VISUAL_TYPE                                = $22;
   GLX_TRANSPARENT_TYPE                             = $23;
   GLX_TRANSPARENT_INDEX_VALUE                      = $24;
   GLX_TRANSPARENT_RED_VALUE                        = $25;
   GLX_TRANSPARENT_GREEN_VALUE                      = $26;
   GLX_TRANSPARENT_BLUE_VALUE                       = $27;
   GLX_TRANSPARENT_ALPHA_VALUE                      = $28;
   GLX_MAX_PBUFFER_WIDTH                            = $8016;
   GLX_MAX_PBUFFER_HEIGHT                           = $8017;
   GLX_MAX_PBUFFER_PIXELS                           = $8018;
   GLX_PRESERVED_CONTENTS                           = $801B;
   GLX_LARGEST_BUFFER                               = $801C;
   GLX_DRAWABLE_TYPE                                = $8010;
   GLX_FBCONFIG_ID                                  = $8013;
   GLX_VISUAL_ID                                    = $800B;
   GLX_WINDOW_BIT                                   = $00000001;
   GLX_PIXMAP_BIT                                   = $00000002;
   GLX_PBUFFER_BIT                                  = $00000004;
   GLX_AUX_BUFFERS_BIT                              = $00000010;
   GLX_FRONT_LEFT_BUFFER_BIT                        = $00000001;
   GLX_FRONT_RIGHT_BUFFER_BIT                       = $00000002;
   GLX_BACK_LEFT_BUFFER_BIT                         = $00000004;
   GLX_BACK_RIGHT_BUFFER_BIT                        = $00000008;
   GLX_DEPTH_BUFFER_BIT                             = $00000020;
   GLX_STENCIL_BUFFER_BIT                           = $00000040;
   GLX_ACCUM_BUFFER_BIT                             = $00000080;
   GLX_RENDER_TYPE                                  = $8011;
   GLX_X_RENDERABLE                                 = $8012;
   GLX_NONE                                         = $8000;
   GLX_TRUE_COLOR                                   = $8002;
   GLX_DIRECT_COLOR                                 = $8003;
   GLX_PSEUDO_COLOR                                 = $8004;
   GLX_STATIC_COLOR                                 = $8005;
   GLX_GRAY_SCALE                                   = $8006;
   GLX_STATIC_GRAY                                  = $8007;
   GLX_TRANSPARENT_INDEX                            = $8009;
   GLX_COLOR_INDEX_TYPE                             = $8015;
   GLX_COLOR_INDEX_BIT                              = $00000002;
   GLX_SCREEN                                       = $800C;
   GLX_PBUFFER_CLOBBER_MASK                         = $08000000;
   GLX_DAMAGED                                      = $8020;
   GLX_SAVED                                        = $8021;
   GLX_WINDOW                                       = $8022;
   GLX_PBUFFER                                      = $8023;
   GLX_EXT_visual_info                              = 1;
   GLX_X_VISUAL_TYPE_EXT                            = $22;
   GLX_TRANSPARENT_TYPE_EXT                         = $23;
   GLX_TRANSPARENT_INDEX_VALUE_EXT                  = $24;
   GLX_TRANSPARENT_RED_VALUE_EXT                    = $25;
   GLX_TRANSPARENT_GREEN_VALUE_EXT                  = $26;
   GLX_TRANSPARENT_BLUE_VALUE_EXT                   = $27;
   GLX_TRANSPARENT_ALPHA_VALUE_EXT                  = $28;
   GLX_TRUE_COLOR_EXT                               = $8002;
   GLX_DIRECT_COLOR_EXT                             = $8003;
   GLX_PSEUDO_COLOR_EXT                             = $8004;
   GLX_STATIC_COLOR_EXT                             = $8005;
   GLX_GRAY_SCALE_EXT                               = $8006;
   GLX_STATIC_GRAY_EXT                              = $8007;
   GLX_NONE_EXT                                     = $8000;
   GLX_TRANSPARENT_RGB_EXT                          = $8008;
   GLX_TRANSPARENT_INDEX_EXT                        = $8009;
   GLX_VISUAL_CAVEAT_EXT                            = $20;
   GLX_SLOW_VISUAL_EXT                              = $8001;
   GLX_NON_CONFORMANT_VISUAL_EXT                    = $800D;
   GLX_SHARE_CONTEXT_EXT                            = $800A;
   GLX_VISUAL_ID_EXT                                = $800B;
   GLX_SCREEN_EXT                                   = $800C;
   GLX_3DFX_WINDOW_MODE_MESA                        = $1;
   GLX_3DFX_FULLSCREEN_MODE_MESA                    = $2;


type
   // GLU types
   TGLUNurbs = record end;
   TGLUQuadric = record end;
   TGLUTesselator = record end;

   PGLUNurbs = ^TGLUNurbs;
   PGLUQuadric = ^TGLUQuadric;
   PGLUTesselator=  ^TGLUTesselator;

   // backwards compatibility
   TGLUNurbsObj = TGLUNurbs;
   TGLUQuadricObj = TGLUQuadric;
   TGLUTesselatorObj = TGLUTesselator;
   TGLUTriangulatorObj = TGLUTesselator;

   PGLUNurbsObj = PGLUNurbs;
   PGLUQuadricObj = PGLUQuadric;
   PGLUTesselatorObj = PGLUTesselator;
   PGLUTriangulatorObj = PGLUTesselator;

   // Callback function prototypes
   // GLUQuadricCallback
   TGLUQuadricErrorProc = procedure(errorCode: TGLEnum); stdcall;

   // GLUTessCallback
   TGLUTessBeginProc = procedure(AType: TGLEnum); stdcall;
   TGLUTessEdgeFlagProc = procedure(Flag: TGLboolean); stdcall;
   TGLUTessVertexProc = procedure(VertexData: Pointer); stdcall;
   TGLUTessEndProc = procedure; stdcall;
   TGLUTessErrorProc = procedure(ErrNo: TGLEnum); stdcall;
   TGLUTessCombineProc = procedure(const Coords: TV3d; const VertexData: TVector4p; const Weight: TV4f; OutData: PGLPointer); stdcall;
   TGLUTessBeginDataProc = procedure(AType: TGLEnum; UserData: Pointer); stdcall;
   TGLUTessEdgeFlagDataProc = procedure(Flag: TGLboolean; UserData: Pointer); stdcall;
   TGLUTessVertexDataProc = procedure(VertexData: Pointer; UserData: Pointer); stdcall;
   TGLUTessEndDataProc = procedure(UserData: Pointer); stdcall;
   TGLUTessErrorDataProc = procedure(ErrNo: TGLEnum; UserData: Pointer); stdcall;
   TGLUTessCombineDataProc = procedure(const Coords: TV3d; const VertexData: TVector4p; const Weight: TV4f; OutData: PGLPointer; UserData: Pointer); stdcall;

   // GLUNurbsCallback
   TGLUNurbsErrorProc = procedure(ErrorCode: TGLEnum); stdcall;

   // GL functions and procedures
   procedure glAccum(op: TGLuint; value: TGLfloat); stdcall; external opengl32;
   procedure glAlphaFunc(func: TGLEnum; ref: TGLclampf); stdcall; external opengl32;
   function  glAreTexturesResident(n: TGLsizei; Textures: PGLuint; residences: PGLboolean): TGLboolean; stdcall; external opengl32;
   procedure glArrayElement(i: TGLint); stdcall; external opengl32;
   procedure glBegin(mode: TGLEnum); stdcall; external opengl32;
   procedure glBindTexture(target: TGLEnum; texture: TGLuint); stdcall; external opengl32;
   procedure glBitmap(width: TGLsizei; height: TGLsizei; xorig, yorig: TGLfloat; xmove: TGLfloat; ymove: TGLfloat; bitmap: Pointer); stdcall; external opengl32;
   procedure glBlendFunc(sfactor: TGLEnum; dfactor: TGLEnum); stdcall; external opengl32;
   procedure glCallList(list: TGLuint); stdcall; external opengl32;
   procedure glCallLists(n: TGLsizei; atype: TGLEnum; lists: Pointer); stdcall; external opengl32;
   procedure glClear(mask: TGLbitfield); stdcall; external opengl32;
   procedure glClearAccum(red, green, blue, alpha: TGLfloat); stdcall; external opengl32;
   procedure glClearColor(red, green, blue, alpha: TGLclampf); stdcall; overload; external opengl32;
   procedure glClearDepth(depth: TGLclampd); stdcall; external opengl32;
   procedure glClearIndex(c: TGLfloat); stdcall; external opengl32;
   procedure glClearStencil(s: TGLint ); stdcall; external opengl32;
   procedure glClipPlane(plane: TGLEnum; equation: PGLdouble); stdcall; external opengl32;

   procedure glColor3b(red, green, blue: TGLbyte); stdcall; external opengl32;
   procedure glColor3bv(v: PGLbyte); stdcall; external opengl32;
   procedure glColor3d(red, green, blue: TGLdouble); stdcall; external opengl32;
   procedure glColor3dv(v: PGLdouble); stdcall; external opengl32;
   procedure glColor3f(red, green, blue: TGLfloat); stdcall; external opengl32;
   procedure glColor3fv(v: PGLfloat); stdcall; external opengl32;
   procedure glColor3i(red, green, blue: TGLint); stdcall; external opengl32;
   procedure glColor3iv(v: PGLint); stdcall; external opengl32;
   procedure glColor3s(red, green, blue: TGLshort); stdcall; external opengl32;
   procedure glColor3sv(v: PGLshort); stdcall; external opengl32;
   procedure glColor3ub(red, green, blue: TGLubyte); stdcall; external opengl32;
   procedure glColor3ubv(v: PGLubyte); stdcall; external opengl32;
   procedure glColor3ui(red, green, blue: TGLuint); stdcall; external opengl32;
   procedure glColor3uiv(v: PGLuint); stdcall; external opengl32;
   procedure glColor3us(red, green, blue: TGLushort); stdcall; external opengl32;
   procedure glColor3usv(v: PGLushort); stdcall; external opengl32;
   procedure glColor4b(red, green, blue, alpha: TGLbyte); stdcall; external opengl32;
   procedure glColor4bv(v: PGLbyte); stdcall; external opengl32;
   procedure glColor4d(red, green, blue, alpha: TGLdouble ); stdcall; external opengl32;
   procedure glColor4dv(v: PGLdouble); stdcall; external opengl32;
   procedure glColor4f(red, green, blue, alpha: TGLfloat); stdcall; external opengl32;
   procedure glColor4fv(v: PGLfloat); stdcall; external opengl32;
   procedure glColor4i(red, green, blue, alpha: TGLint); stdcall; external opengl32;
   procedure glColor4iv(v: PGLint); stdcall; external opengl32;
   procedure glColor4s(red, green, blue, alpha: TGLshort); stdcall; external opengl32;
   procedure glColor4sv(v: TGLshort); stdcall; external opengl32;
   procedure glColor4ub(red, green, blue, alpha: TGLubyte); stdcall; external opengl32;
   procedure glColor4ubv(v: PGLubyte); stdcall; external opengl32;
   procedure glColor4ui(red, green, blue, alpha: TGLuint); stdcall; external opengl32;
   procedure glColor4uiv(v: PGLuint); stdcall; external opengl32;
   procedure glColor4us(red, green, blue, alpha: TGLushort); stdcall; external opengl32;
   procedure glColor4usv(v: PGLushort); stdcall; external opengl32;

   procedure glColorMask(red, green, blue, alpha: TGLboolean); stdcall; external opengl32;
   procedure glColorMaterial(face: TGLEnum; mode: TGLEnum); stdcall; external opengl32;
   procedure glColorPointer(size: TGLint; atype: TGLEnum; stride: TGLsizei; data: pointer); stdcall; external opengl32;
   procedure glCopyPixels(x, y: TGLint; width, height: TGLsizei; atype: TGLEnum); stdcall; external opengl32;
   procedure glCopyTexImage1D(target: TGLEnum; level: TGLint; internalFormat: TGLEnum; x, y: TGLint; width: TGLsizei; border: TGLint); stdcall; external opengl32;
   procedure glCopyTexImage2D(target: TGLEnum; level: TGLint; internalFormat: TGLEnum; x, y: TGLint; width, height: TGLsizei; border: TGLint); stdcall; external opengl32;
   procedure glCopyTexSubImage1D(target: TGLEnum; level, xoffset, x, y: TGLint; width: TGLsizei); stdcall; external opengl32;
   procedure glCopyTexSubImage2D(target: TGLEnum; level, xoffset, yoffset, x, y: TGLint; width, height: TGLsizei); stdcall; external opengl32;
   procedure glCullFace(mode: TGLEnum); stdcall; external opengl32;
   procedure glDeleteLists(list: TGLuint; range: TGLsizei); stdcall; external opengl32;
   procedure glDeleteTextures(n: TGLsizei; textures: PGLuint); stdcall; external opengl32;
   procedure glDepthFunc(func: TGLEnum); stdcall; external opengl32;
   procedure glDepthMask(flag: TGLEnum); stdcall; external opengl32;
   procedure glDepthRange(zNear, zFar: TGLclampd); stdcall; external opengl32;
   procedure glDisable(cap: TGLEnum); stdcall; external opengl32;
   procedure glDisableClientState(aarray: TGLEnum); stdcall; external opengl32;
   procedure glDrawArrays(mode: TGLEnum; first: TGLint; count: TGLsizei); stdcall; external opengl32;
   procedure glDrawBuffer(mode: TGLEnum); stdcall; external opengl32;
   procedure glDrawElements(mode: TGLEnum; count: TGLsizei; atype: TGLEnum; indices: Pointer); stdcall; external opengl32;
   procedure glDrawPixels(width, height: TGLsizei; format, atype: TGLEnum; pixels: Pointer); stdcall; external opengl32;

   procedure glEdgeFlag(flag: TGLboolean); stdcall; external opengl32;
   procedure glEdgeFlagPointer(stride: TGLsizei; data: pointer); stdcall; external opengl32;
   procedure glEdgeFlagv(flag: PGLboolean); stdcall; external opengl32;
   procedure glEnable(cap: TGLEnum); stdcall; external opengl32;
   procedure glEnableClientState(aarray: TGLEnum); stdcall; external opengl32;
   procedure glEnd; stdcall; external opengl32;
   procedure glEndList; stdcall; external opengl32;
   procedure glEvalCoord1d(u: TGLdouble); stdcall; external opengl32;
   procedure glEvalCoord1dv(u: PGLdouble); stdcall; external opengl32;
   procedure glEvalCoord1f(u: TGLfloat); stdcall; external opengl32;
   procedure glEvalCoord1fv(u: PGLfloat); stdcall; external opengl32;
   procedure glEvalCoord2d(u: TGLdouble; v: TGLdouble); stdcall; external opengl32;
   procedure glEvalCoord2dv(u: PGLdouble); stdcall; external opengl32;
   procedure glEvalCoord2f(u, v: TGLfloat); stdcall; external opengl32;
   procedure glEvalCoord2fv(u: PGLfloat); stdcall; external opengl32;
   procedure glEvalMesh1(mode: TGLEnum; i1, i2: TGLint); stdcall; external opengl32;
   procedure glEvalMesh2(mode: TGLEnum; i1, i2, j1, j2: TGLint); stdcall; external opengl32;
   procedure glEvalPoint1(i: TGLint); stdcall; external opengl32;
   procedure glEvalPoint2(i, j: TGLint); stdcall; external opengl32;

   procedure glFeedbackBuffer(size: TGLsizei; atype: TGLEnum; buffer: PGLfloat); stdcall; external opengl32;
   procedure glFinish; stdcall; external opengl32;
   procedure glFlush; stdcall; external opengl32;
   procedure glFogf(pname: TGLEnum; param: TGLfloat); stdcall; external opengl32;
   procedure glFogfv(pname: TGLEnum; params: PGLfloat); stdcall; external opengl32;
   procedure glFogi(pname: TGLEnum; param: TGLint); stdcall; external opengl32;
   procedure glFogiv(pname: TGLEnum; params: PGLint); stdcall; external opengl32;
   procedure glFrontFace(mode: TGLEnum); stdcall; external opengl32;
   procedure glFrustum(left, right, bottom, top, zNear, zFar: TGLdouble); stdcall; external opengl32;
   function  glGenLists(range: TGLsizei): TGLuint; stdcall; external opengl32;
   procedure glGenTextures(n: TGLsizei; textures: PGLuint); stdcall; external opengl32;
   procedure glGetBooleanv(pname: TGLEnum; params: PGLboolean); stdcall; external opengl32;
   procedure glGetClipPlane(plane: TGLEnum; equation: PGLdouble); stdcall; external opengl32;
   procedure glGetDoublev(pname: TGLEnum; params: PGLdouble); stdcall; external opengl32;
   function  glGetError: TGLuint; stdcall; external opengl32;
   procedure glGetFloatv(pname: TGLEnum; params: PGLfloat); stdcall; external opengl32;
   procedure glGetIntegerv(pname: TGLEnum; params: PGLint); stdcall; external opengl32;
   procedure glGetLightfv(light, pname: TGLEnum; params: PGLfloat); stdcall; external opengl32;
   procedure glGetLightiv(light, pname: TGLEnum; params: PGLint); stdcall; external opengl32;
   procedure glGetMapdv(target, query: TGLEnum; v: PGLdouble); stdcall; external opengl32;
   procedure glGetMapfv(target, query: TGLEnum; v: PGLfloat); stdcall; external opengl32;
   procedure glGetMapiv(target, query: TGLEnum; v: PGLint); stdcall; external opengl32;
   procedure glGetMaterialfv(face, pname: TGLEnum; params: PGLfloat); stdcall; external opengl32;
   procedure glGetMaterialiv(face, pname: TGLEnum; params: PGLint); stdcall; external opengl32;
   procedure glGetPixelMapfv(map: TGLEnum; values: PGLfloat); stdcall; external opengl32;
   procedure glGetPixelMapuiv(map: TGLEnum; values: PGLuint); stdcall; external opengl32;
   procedure glGetPixelMapusv(map: TGLEnum; values: PGLushort); stdcall; external opengl32;
   procedure glGetPointerv(pname: TGLEnum; var params); stdcall; external opengl32;
   procedure glGetPolygonStipple(mask: PGLubyte); stdcall; external opengl32;
   function  glGetString(name: TGLEnum): PAnsiChar; stdcall; external opengl32;
   procedure glGetTexEnvfv(target, pname: TGLEnum; params: PGLfloat); stdcall; external opengl32;
   procedure glGetTexEnviv(target, pname: TGLEnum; params: PGLint); stdcall; external opengl32;
   procedure glGetTexGendv(coord, pname: TGLEnum; params: PGLdouble); stdcall; external opengl32;
   procedure glGetTexGenfv(coord, pname: TGLEnum; params: PGLfloat); stdcall; external opengl32;
   procedure glGetTexGeniv(coord, pname: TGLEnum; params: PGLint); stdcall; external opengl32;
   procedure glGetTexImage(target: TGLEnum; level: TGLint; format, atype: TGLEnum; pixels: Pointer); stdcall; external opengl32;
   procedure glGetTexLevelParameterfv(target: TGLEnum; level: TGLint; pname: TGLEnum; params: PGLfloat); stdcall; external opengl32;
   procedure glGetTexLevelParameteriv(target: TGLEnum; level: TGLint; pname: TGLEnum; params: PGLint); stdcall; external opengl32;
   procedure glGetTexParameterfv(target, pname: TGLEnum; params: PGLfloat); stdcall; external opengl32;
   procedure glGetTexParameteriv(target, pname: TGLEnum; params: PGLint); stdcall; external opengl32;

   procedure glHint(target, mode: TGLEnum); stdcall; external opengl32;
   procedure glIndexMask(mask: TGLuint); stdcall; external opengl32;
   procedure glIndexPointer(atype: TGLEnum; stride: TGLsizei; data: pointer); stdcall; external opengl32;
   procedure glIndexd(c: TGLdouble); stdcall; external opengl32;
   procedure glIndexdv(c: PGLdouble); stdcall; external opengl32;
   procedure glIndexf(c: TGLfloat); stdcall; external opengl32;
   procedure glIndexfv(c: PGLfloat); stdcall; external opengl32;
   procedure glIndexi(c: TGLint); stdcall; external opengl32;
   procedure glIndexiv(c: PGLint); stdcall; external opengl32;
   procedure glIndexs(c: TGLshort); stdcall; external opengl32;
   procedure glIndexsv(c: PGLshort); stdcall; external opengl32;
   procedure glIndexub(c: TGLubyte); stdcall; external opengl32;
   procedure glIndexubv(c: PGLubyte); stdcall; external opengl32;
   procedure glInitNames; stdcall; external opengl32;
   procedure glInterleavedArrays(format: TGLEnum; stride: TGLsizei; data: pointer); stdcall; external opengl32;
   function  glIsEnabled(cap: TGLEnum): TGLboolean; stdcall; external opengl32;
   function  glIsList(list: TGLuint): TGLboolean; stdcall; external opengl32;
   function  glIsTexture(texture: TGLuint): TGLboolean; stdcall; external opengl32;
   procedure glLightModelf(pname: TGLEnum; param: TGLfloat); stdcall; external opengl32;
   procedure glLightModelfv(pname: TGLEnum; params: PGLfloat); stdcall; external opengl32;
   procedure glLightModeli(pname: TGLEnum; param: TGLint); stdcall; external opengl32;
   procedure glLightModeliv(pname: TGLEnum; params: PGLint); stdcall; external opengl32;
   procedure glLightf(light, pname: TGLEnum; param: TGLfloat); stdcall; external opengl32;
   procedure glLightfv(light, pname: TGLEnum; params: PGLfloat); stdcall; external opengl32;
   procedure glLighti(light, pname: TGLEnum; param: TGLint); stdcall; external opengl32;
   procedure glLightiv(light, pname: TGLEnum; params: PGLint); stdcall; external opengl32;
   procedure glLineStipple(factor: TGLint; pattern: TGLushort); stdcall; external opengl32;
   procedure glLineWidth(width: TGLfloat); stdcall; external opengl32;
   procedure glListBase(base: TGLuint); stdcall; external opengl32;
   procedure glLoadIdentity; stdcall; external opengl32;
   procedure glLoadMatrixd(m: PGLdouble); stdcall; external opengl32;
   procedure glLoadMatrixf(m: PGLfloat); stdcall; external opengl32;
   procedure glLoadName(name: TGLuint); stdcall; external opengl32;
   procedure glLogicOp(opcode: TGLEnum); stdcall; external opengl32;

   procedure glMap1d(target: TGLEnum; u1, u2: TGLdouble; stride, order: TGLint; points: PGLdouble); stdcall; external opengl32;
   procedure glMap1f(target: TGLEnum; u1, u2: TGLfloat; stride, order: TGLint; points: PGLfloat); stdcall; external opengl32;
   procedure glMap2d(target: TGLEnum; u1, u2: TGLdouble; ustride, uorder: TGLint; v1, v2: TGLdouble; vstride,
                     vorder: TGLint; points: PGLdouble); stdcall; external opengl32;
   procedure glMap2f(target: TGLEnum; u1, u2: TGLfloat; ustride, uorder: TGLint; v1, v2: TGLfloat; vstride,
                     vorder: TGLint; points: PGLfloat); stdcall; external opengl32;
   procedure glMapGrid1d(un: TGLint; u1, u2: TGLdouble); stdcall; external opengl32;
   procedure glMapGrid1f(un: TGLint; u1, u2: TGLfloat); stdcall; external opengl32;
   procedure glMapGrid2d(un: TGLint; u1, u2: TGLdouble; vn: TGLint; v1, v2: TGLdouble); stdcall; external opengl32;
   procedure glMapGrid2f(un: TGLint; u1, u2: TGLfloat; vn: TGLint; v1, v2: TGLfloat); stdcall; external opengl32;
   procedure glMaterialf(face, pname: TGLEnum; param: TGLfloat); stdcall; external opengl32;
   procedure glMaterialfv(face, pname: TGLEnum; params: PGLfloat); stdcall; external opengl32;
   procedure glMateriali(face, pname: TGLEnum; param: TGLint); stdcall; external opengl32;
   procedure glMaterialiv(face, pname: TGLEnum; params: PGLint); stdcall; external opengl32;
   procedure glMatrixMode(mode: TGLEnum); stdcall; external opengl32;
   procedure glMultMatrixd(m: PGLdouble); stdcall; external opengl32;
   procedure glMultMatrixf(m: PGLfloat); stdcall; external opengl32;
   procedure glNewList(list: TGLuint; mode: TGLEnum); stdcall; external opengl32; overload;
   procedure glNormal3b(nx, ny, nz: TGLbyte); stdcall; external opengl32;
   procedure glNormal3bv(v: PGLbyte); stdcall; external opengl32;
   procedure glNormal3d(nx, ny, nz: TGLdouble); stdcall; external opengl32;
   procedure glNormal3dv(v: PGLdouble); stdcall; external opengl32;
   procedure glNormal3f(nx, ny, nz: TGLfloat); stdcall; external opengl32;
   procedure glNormal3fv(v: PGLfloat); stdcall; external opengl32;
   procedure glNormal3i(nx, ny, nz: TGLint); stdcall; external opengl32;
   procedure glNormal3iv(v: PGLint); stdcall; external opengl32;
   procedure glNormal3s(nx, ny, nz: TGLshort); stdcall; external opengl32;
   procedure glNormal3sv(v: PGLshort); stdcall; external opengl32;
   procedure glNormalPointer(atype: TGLEnum; stride: TGLsizei; data: pointer); stdcall; external opengl32;

   procedure glOrtho(left, right, bottom, top, zNear, zFar: TGLdouble); stdcall; external opengl32;
   procedure glPassThrough(token: TGLfloat); stdcall; external opengl32;
   procedure glPixelMapfv(map: TGLEnum; mapsize: TGLsizei; values: PGLfloat); stdcall; external opengl32;
   procedure glPixelMapuiv(map: TGLEnum; mapsize: TGLsizei; values: PGLuint); stdcall; external opengl32;
   procedure glPixelMapusv(map: TGLEnum; mapsize: TGLsizei; values: PGLushort); stdcall; external opengl32;
   procedure glPixelStoref(pname: TGLEnum; param: TGLfloat); stdcall; external opengl32;
   procedure glPixelStorei(pname: TGLEnum; param: TGLint); stdcall; external opengl32;
   procedure glPixelTransferf(pname: TGLEnum; param: TGLfloat); stdcall; external opengl32;
   procedure glPixelTransferi(pname: TGLEnum; param: TGLint); stdcall; external opengl32;
   procedure glPixelZoom(xfactor, yfactor: TGLfloat); stdcall; external opengl32;
   procedure glPointSize(size: TGLfloat); stdcall; external opengl32;
   procedure glPolygonMode(face, mode: TGLEnum); stdcall; external opengl32;
   procedure glPolygonOffset(factor, units: TGLfloat); stdcall; external opengl32;
   procedure glPolygonStipple(mask: PGLubyte); stdcall; external opengl32;
   procedure glPopAttrib; stdcall; external opengl32;
   procedure glPopClientAttrib; stdcall; external opengl32;
   procedure glPopMatrix; stdcall; external opengl32;
   procedure glPopName; stdcall; external opengl32;
   procedure glPrioritizeTextures(n: TGLsizei; textures: PGLuint; priorities: PGLclampf); stdcall; external opengl32;
   procedure glPushAttrib(mask: TGLbitfield); stdcall; external opengl32;
   procedure glPushClientAttrib(mask: TGLbitfield); stdcall; external opengl32;
   procedure glPushMatrix; stdcall; external opengl32;
   procedure glPushName(name: TGLuint); stdcall; external opengl32;

   procedure glRasterPos2d(x, y: TGLdouble); stdcall; external opengl32;
   procedure glRasterPos2dv(v: PGLdouble); stdcall; external opengl32;
   procedure glRasterPos2f(x, y: TGLfloat); stdcall; external opengl32;
   procedure glRasterPos2fv(v: PGLfloat); stdcall; external opengl32;
   procedure glRasterPos2i(x, y: TGLint); stdcall; external opengl32;
   procedure glRasterPos2iv(v: PGLint); stdcall; external opengl32;
   procedure glRasterPos2s(x, y: PGLshort); stdcall; external opengl32;
   procedure glRasterPos2sv(v: PGLshort); stdcall; external opengl32;
   procedure glRasterPos3d(x, y, z: TGLdouble); stdcall; external opengl32;
   procedure glRasterPos3dv(v: PGLdouble); stdcall; external opengl32;
   procedure glRasterPos3f(x, y, z: TGLfloat); stdcall; external opengl32;
   procedure glRasterPos3fv(v: PGLfloat); stdcall; external opengl32;
   procedure glRasterPos3i(x, y, z: TGLint); stdcall; external opengl32;
   procedure glRasterPos3iv(v: PGLint); stdcall; external opengl32;
   procedure glRasterPos3s(x, y, z: TGLshort); stdcall; external opengl32;
   procedure glRasterPos3sv(v: PGLshort); stdcall; external opengl32;
   procedure glRasterPos4d(x, y, z, w: TGLdouble); stdcall; external opengl32;
   procedure glRasterPos4dv(v: PGLdouble); stdcall; external opengl32;
   procedure glRasterPos4f(x, y, z, w: TGLfloat); stdcall; external opengl32;
   procedure glRasterPos4fv(v: PGLfloat); stdcall; external opengl32;
   procedure glRasterPos4i(x, y, z, w: TGLint); stdcall; external opengl32;
   procedure glRasterPos4iv(v: PGLint); stdcall; external opengl32;
   procedure glRasterPos4s(x, y, z, w: TGLshort); stdcall; external opengl32;
   procedure glRasterPos4sv(v: PGLshort); stdcall; external opengl32;
   procedure glReadBuffer(mode: TGLEnum); stdcall; external opengl32;
   procedure glReadPixels(x, y: TGLint; width, height: TGLsizei; format, atype: TGLEnum; pixels: Pointer); stdcall; external opengl32;
   procedure glRectd(x1, y1, x2, y2: TGLdouble); stdcall; external opengl32;
   procedure glRectdv(v1, v2: PGLdouble); stdcall; external opengl32;
   procedure glRectf(x1, y1, x2, y2: TGLfloat); stdcall; external opengl32;
   procedure glRectfv(v1, v2: PGLfloat); stdcall; external opengl32;
   procedure glRecti(x1, y1, x2, y2: TGLint); stdcall; external opengl32;
   procedure glRectiv(v1, v2: PGLint); stdcall; external opengl32;
   procedure glRects(x1, y1, x2, y2: TGLshort); stdcall; external opengl32;
   procedure glRectsv(v1, v2: PGLshort); stdcall; external opengl32;
   function  glRenderMode(mode: TGLEnum): TGLint; stdcall; external opengl32;
   procedure glRotated(angle, x, y, z: TGLdouble); stdcall; external opengl32;
   procedure glRotatef(angle, x, y, z: TGLfloat); stdcall; external opengl32;

   procedure glScaled(x, y, z: TGLdouble); stdcall; external opengl32;
   procedure glScalef(x, y, z: TGLfloat); stdcall; external opengl32;
   procedure glScissor(x, y: TGLint; width, height: TGLsizei); stdcall; external opengl32;
   procedure glSelectBuffer(size: TGLsizei; buffer: PGLuint); stdcall; external opengl32;
   procedure glShadeModel(mode: TGLEnum); stdcall; external opengl32;
   procedure glStencilFunc(func: TGLEnum; ref: TGLint; mask: TGLuint); stdcall; external opengl32;
   procedure glStencilMask(mask: TGLuint); stdcall; external opengl32;
   procedure glStencilOp(fail, zfail, zpass: TGLEnum); stdcall; external opengl32;
   procedure glTexCoord1d(s: TGLdouble); stdcall; external opengl32;
   procedure glTexCoord1dv(v: PGLdouble); stdcall; external opengl32;
   procedure glTexCoord1f(s: TGLfloat); stdcall; external opengl32;
   procedure glTexCoord1fv(v: PGLfloat); stdcall; external opengl32;
   procedure glTexCoord1i(s: TGLint); stdcall; external opengl32;
   procedure glTexCoord1iv(v: PGLint); stdcall; external opengl32;
   procedure glTexCoord1s(s: TGLshort); stdcall; external opengl32;
   procedure glTexCoord1sv(v: PGLshort); stdcall; external opengl32;
   procedure glTexCoord2d(s, t: TGLdouble); stdcall; external opengl32;
   procedure glTexCoord2dv(v: PGLdouble); stdcall; external opengl32;
   procedure glTexCoord2f(s, t: TGLfloat); stdcall; external opengl32;
   procedure glTexCoord2fv(v: PGLfloat); stdcall; external opengl32;
   procedure glTexCoord2i(s, t: TGLint); stdcall; external opengl32;
   procedure glTexCoord2iv(v: PGLint); stdcall; external opengl32;
   procedure glTexCoord2s(s, t: TGLshort); stdcall; external opengl32;
   procedure glTexCoord2sv(v: PGLshort); stdcall; external opengl32;
   procedure glTexCoord3d(s, t, r: TGLdouble); stdcall; external opengl32;
   procedure glTexCoord3dv(v: PGLdouble); stdcall; external opengl32;
   procedure glTexCoord3f(s, t, r: TGLfloat); stdcall; external opengl32;
   procedure glTexCoord3fv(v: PGLfloat); stdcall; external opengl32;
   procedure glTexCoord3i(s, t, r: TGLint); stdcall; external opengl32;
   procedure glTexCoord3iv(v: PGLint); stdcall; external opengl32;
   procedure glTexCoord3s(s, t, r: TGLshort); stdcall; external opengl32;
   procedure glTexCoord3sv(v: PGLshort); stdcall; external opengl32;
   procedure glTexCoord4d(s, t, r, q: TGLdouble); stdcall; external opengl32;
   procedure glTexCoord4dv(v: PGLdouble); stdcall; external opengl32;
   procedure glTexCoord4f(s, t, r, q: TGLfloat); stdcall; external opengl32;
   procedure glTexCoord4fv(v: PGLfloat); stdcall; external opengl32;
   procedure glTexCoord4i(s, t, r, q: TGLint); stdcall; external opengl32;
   procedure glTexCoord4iv(v: PGLint); stdcall; external opengl32;
   procedure glTexCoord4s(s, t, r, q: TGLshort); stdcall; external opengl32;
   procedure glTexCoord4sv(v: PGLshort); stdcall; external opengl32;
   procedure glTexCoordPointer(size: TGLint; atype: TGLEnum; stride: TGLsizei; data: pointer); stdcall; external opengl32;
   procedure glTexEnvf(target, pname: TGLEnum; param: TGLfloat); stdcall; external opengl32;
   procedure glTexEnvfv(target, pname: TGLEnum; params: PGLfloat); stdcall; external opengl32;
   procedure glTexEnvi(target, pname: TGLEnum; param: TGLint); stdcall; external opengl32;
   procedure glTexEnviv(target, pname: TGLEnum; params: PGLint); stdcall; external opengl32;
   procedure glTexGend(coord, pname: TGLEnum; param: TGLdouble); stdcall; external opengl32;
   procedure glTexGendv(coord, pname: TGLEnum; params: PGLdouble); stdcall; external opengl32;
   procedure glTexGenf(coord, pname: TGLEnum; param: TGLfloat); stdcall; external opengl32;
   procedure glTexGenfv(coord, pname: TGLEnum; params: PGLfloat); stdcall; external opengl32;
   procedure glTexGeni(coord, pname: TGLEnum; param: TGLint); stdcall; external opengl32;
   procedure glTexGeniv(coord, pname: TGLEnum; params: PGLint); stdcall; external opengl32;
   procedure glTexImage1D(target: TGLEnum; level, internalformat: TGLint; width: TGLsizei; border: TGLint; format,
                          atype: TGLEnum; pixels: Pointer); stdcall; external opengl32;
   procedure glTexImage2D(target: TGLEnum; level, internalformat: TGLint; width, height: TGLsizei; border: TGLint;
                          format, atype: TGLEnum; Pixels:Pointer); stdcall; external opengl32;
   procedure glTexParameterf(target, pname: TGLEnum; param: TGLfloat); stdcall; external opengl32;
   procedure glTexParameterfv(target, pname: TGLEnum; params: PGLfloat); stdcall; external opengl32;
   procedure glTexParameteri(target, pname: TGLEnum; param: TGLint); stdcall; external opengl32;
   procedure glTexParameteriv(target, pname: TGLEnum; params: PGLint); stdcall; external opengl32;
   procedure glTexSubImage1D(target: TGLEnum; level, xoffset: TGLint; width: TGLsizei; format, atype: TGLEnum;
                             pixels: Pointer); stdcall; external opengl32;
   procedure glTexSubImage2D(target: TGLEnum; level, xoffset, yoffset: TGLint; width, height: TGLsizei; format,
                             atype: TGLEnum; pixels: Pointer); stdcall; external opengl32;
   procedure glTranslated(x, y, z: TGLdouble); stdcall; external opengl32;
   procedure glTranslatef(x, y, z: TGLfloat); stdcall; external opengl32; overload;

   procedure glVertex2d(x, y: TGLdouble); stdcall; external opengl32;
   procedure glVertex2dv(v: PGLdouble); stdcall; external opengl32;
   procedure glVertex2f(x, y: TGLfloat); stdcall; external opengl32;
   procedure glVertex2fv(v: PGLfloat); stdcall; external opengl32;
   procedure glVertex2i(x, y: TGLint); stdcall; external opengl32;
   procedure glVertex2iv(v: PGLint); stdcall; external opengl32;
   procedure glVertex2s(x, y: TGLshort); stdcall; external opengl32;
   procedure glVertex2sv(v: PGLshort); stdcall; external opengl32;
   procedure glVertex3d(x, y, z: TGLdouble); stdcall; external opengl32;
   procedure glVertex3dv(v: PGLdouble); stdcall; external opengl32;
   procedure glVertex3f(x, y, z: TGLfloat); stdcall; external opengl32;
   procedure glVertex3fv(v: PGLfloat); stdcall; external opengl32;
   procedure glVertex3i(x, y, z: TGLint); stdcall; external opengl32;
   procedure glVertex3iv(v: PGLint); stdcall; external opengl32;
   procedure glVertex3s(x, y, z: TGLshort); stdcall; external opengl32;
   procedure glVertex3sv(v: PGLshort); stdcall; external opengl32;
   procedure glVertex4d(x, y, z, w: TGLdouble); stdcall; external opengl32;
   procedure glVertex4dv(v: PGLdouble); stdcall; external opengl32;
   procedure glVertex4f(x, y, z, w: TGLfloat); stdcall; external opengl32;
   procedure glVertex4fv(v: PGLfloat); stdcall; external opengl32;
   procedure glVertex4i(x, y, z, w: TGLint); stdcall; external opengl32;
   procedure glVertex4iv(v: PGLint); stdcall; external opengl32;
   procedure glVertex4s(x, y, z, w: TGLshort); stdcall; external opengl32;
   procedure glVertex4sv(v: PGLshort); stdcall; external opengl32;
   procedure glVertexPointer(size: TGLint; atype: TGLEnum; stride: TGLsizei; data: pointer); stdcall; external opengl32;
   procedure glViewport(x, y: TGLint; width, height: TGLsizei); stdcall; external opengl32;

   // GL utility functions and procedures
   function  gluErrorString(errCode: TGLEnum): PAnsiChar; stdcall; external glu32;
   function  gluGetString(name: TGLEnum): PAnsiChar; stdcall; external glu32;
   procedure gluOrtho2D(left, right, bottom, top: TGLdouble); stdcall; external glu32;
   procedure gluPerspective(fovy, aspect, zNear, zFar: TGLdouble); stdcall; external glu32;
   procedure gluPickMatrix(x, y, width, height: TGLdouble; const viewport: TV4i); stdcall; external glu32;
   procedure gluLookAt(eyex, eyey, eyez, centerx, centery, centerz, upx, upy, upz: TGLdouble); overload; stdcall; external glu32;
   function  gluProject(objx, objy, objz: TGLdouble; const modelMatrix: TM44d; const projMatrix: TM44d; const viewport: TV4i;
                        winx, winy, winz: PGLdouble): TGLint; stdcall; external glu32;
   function  gluUnProject(winx, winy, winz: TGLdouble; const modelMatrix: TM44d; const projMatrix: TM44d; const viewport: TV4i;
                          objx, objy, objz: PGLdouble): TGLint; stdcall; external glu32;
   function  gluScaleImage(format: TGLEnum; widthin, heightin: TGLint; typein: TGLEnum; datain: Pointer; widthout,
                           heightout: TGLint; typeout: TGLEnum; dataout: Pointer): TGLint; stdcall; external glu32;
   function  gluBuild1DMipmaps(target: TGLEnum; components, width: TGLint; format, atype: TGLEnum;
                               data: Pointer): TGLint; stdcall; external glu32;
   function  gluBuild2DMipmaps(target: TGLEnum; components, width, height: TGLint; format, atype: TGLEnum;
                               data: Pointer): TGLint; stdcall; external glu32;
   function  gluNewQuadric: PGLUquadric; stdcall; external glu32;
   procedure gluDeleteQuadric(state: PGLUquadric); stdcall; external glu32;
   procedure gluQuadricNormals(quadObject: PGLUquadric; normals: TGLEnum); stdcall; external glu32;
   procedure gluQuadricTexture(quadObject: PGLUquadric; textureCoords: TGLboolean); stdcall; external glu32;
   procedure gluQuadricOrientation(quadObject: PGLUquadric; orientation: TGLEnum); stdcall; external glu32;
   procedure gluQuadricDrawStyle(quadObject: PGLUquadric; drawStyle: TGLEnum); stdcall; external glu32;
   procedure gluCylinder(quadObject: PGLUquadric; baseRadius, topRadius, height: TGLdouble; slices,
                         stacks: TGLint); stdcall; external glu32;
   procedure gluDisk(quadObject: PGLUquadric; innerRadius, outerRadius: TGLdouble; slices, loops: TGLint); stdcall; external glu32;
   procedure gluPartialDisk(quadObject: PGLUquadric; innerRadius, outerRadius: TGLdouble; slices, loops: TGLint;
                            startAngle, sweepAngle: TGLdouble); stdcall; external glu32;
   procedure gluSphere(quadObject: PGLUquadric; radius: TGLdouble; slices, stacks: TGLint); stdcall; external glu32;
   procedure gluQuadricCallback(quadObject: PGLUquadric; which: TGLEnum; fn: TGLUQuadricErrorProc); stdcall; external glu32;
   function  gluNewTess: PGLUtesselator; stdcall; external glu32;
   procedure gluDeleteTess(tess: PGLUtesselator); stdcall; external glu32;
   procedure gluTessBeginPolygon(tess: PGLUtesselator; polygon_data: Pointer); stdcall; external glu32;
   procedure gluTessBeginContour(tess: PGLUtesselator); stdcall; external glu32;
   procedure gluTessVertex(tess: PGLUtesselator; const coords: TV3d; data: Pointer); stdcall; external glu32;
   procedure gluTessEndContour(tess: PGLUtesselator); stdcall; external glu32;
   procedure gluTessEndPolygon(tess: PGLUtesselator); stdcall; external glu32;
   procedure gluTessProperty(tess: PGLUtesselator; which: TGLEnum; value: TGLdouble); stdcall; external glu32;
   procedure gluTessNormal(tess: PGLUtesselator; x, y, z: TGLdouble); stdcall; external glu32;
   procedure gluTessCallback(tess: PGLUtesselator; which: TGLEnum; fn: Pointer); stdcall; external glu32;
   procedure gluGetTessProperty(tess: PGLUtesselator; which: TGLEnum; value: PGLdouble); stdcall; external glu32;
   function  gluNewNurbsRenderer: PGLUnurbs; stdcall; external glu32;
   procedure gluDeleteNurbsRenderer(nobj: PGLUnurbs); stdcall; external glu32;
   procedure gluBeginSurface(nobj: PGLUnurbs); stdcall; external glu32;
   procedure gluBeginCurve(nobj: PGLUnurbs); stdcall; external glu32;
   procedure gluEndCurve(nobj: PGLUnurbs); stdcall; external glu32;
   procedure gluEndSurface(nobj: PGLUnurbs); stdcall; external glu32;
   procedure gluBeginTrim(nobj: PGLUnurbs); stdcall; external glu32;
   procedure gluEndTrim(nobj: PGLUnurbs); stdcall; external glu32;
   procedure gluPwlCurve(nobj: PGLUnurbs; count: TGLint; points: PGLfloat; stride: TGLint; atype: TGLEnum); stdcall; external glu32;
   procedure gluNurbsCurve(nobj: PGLUnurbs; nknots: TGLint; knot: PGLfloat; stride: TGLint; ctlarray: PGLfloat; order: TGLint; atype: TGLEnum); stdcall; external glu32;
   procedure gluNurbsSurface(nobj: PGLUnurbs; sknot_count: TGLint; sknot: PGLfloat; tknot_count: TGLint; tknot: PGLfloat; s_stride, t_stride: TGLint; ctlarray: PGLfloat; sorder, torder: TGLint; atype: TGLEnum); stdcall; external glu32;
   procedure gluLoadSamplingMatrices(nobj: PGLUnurbs; const modelMatrix: TM44f; const projMatrix: TM44f; const viewport: TV4i); stdcall; external glu32;
   procedure gluNurbsProperty(nobj: PGLUnurbs; aproperty: TGLEnum; value: TGLfloat); stdcall; external glu32;
   procedure gluGetNurbsProperty(nobj: PGLUnurbs; aproperty: TGLEnum; value: PGLfloat); stdcall; external glu32;
   procedure gluNurbsCallback(nobj: PGLUnurbs; which: TGLEnum; fn: TGLUNurbsErrorProc); stdcall; external glu32;
   procedure gluBeginPolygon(tess: PGLUtesselator); stdcall; external glu32;
   procedure gluNextContour(tess: PGLUtesselator; atype: TGLEnum); stdcall; external glu32;
   procedure gluEndPolygon(tess: PGLUtesselator); stdcall; external glu32;

   // window support functions
   function wglGetProcAddress(ProcName: PAnsiChar): Pointer; stdcall; external opengl32;
   function wglCopyContext(p1: HGLRC; p2: HGLRC; p3: Cardinal): BOOL; stdcall; external opengl32;
   function wglCreateContext(DC: HDC): HGLRC; stdcall; external opengl32;
   function wglCreateLayerContext(p1: HDC; p2: Integer): HGLRC; stdcall; external opengl32;
   function wglDeleteContext(p1: HGLRC): BOOL; stdcall; external opengl32;
   function wglDescribeLayerPlane(p1: HDC; p2, p3: Integer; p4: Cardinal; var p5: TLayerPlaneDescriptor): BOOL; stdcall; external opengl32;
   function wglGetCurrentContext: HGLRC; stdcall; external opengl32;
   function wglGetCurrentDC: HDC; stdcall; external opengl32;
   function wglGetLayerPaletteEntries(p1: HDC; p2, p3, p4: Integer; var pcr): Integer; stdcall; external opengl32;
   function wglMakeCurrent(DC: HDC; p2: HGLRC): BOOL; stdcall; external opengl32;
   function wglRealizeLayerPalette(p1: HDC; p2: Integer; p3: BOOL): BOOL; stdcall; external opengl32;
   function wglSetLayerPaletteEntries(p1: HDC; p2, p3, p4: Integer; var pcr): Integer; stdcall; external opengl32;
   function wglShareLists(p1, p2: HGLRC): BOOL; stdcall; external opengl32;
   function wglSwapLayerBuffers(p1: HDC; p2: Cardinal): BOOL; stdcall; external opengl32;
   function wglSwapMultipleBuffers(p1: UINT; const p2: PWGLSwap): DWORD; stdcall; external opengl32;
   function wglUseFontBitmapsA(DC: HDC; p2, p3, p4: DWORD): BOOL; stdcall; external opengl32;
   function wglUseFontOutlinesA (p1: HDC; p2, p3, p4: DWORD; p5, p6: Single; p7: Integer; p8: PGlyphMetricsFloat): BOOL; stdcall; external opengl32;
   function wglUseFontBitmapsW(DC: HDC; p2, p3, p4: DWORD): BOOL; stdcall; external opengl32;
   function wglUseFontOutlinesW (p1: HDC; p2, p3, p4: DWORD; p5, p6: Single; p7: Integer; p8: PGlyphMetricsFloat): BOOL; stdcall; external opengl32;
   function wglUseFontBitmaps(DC: HDC; p2, p3, p4: DWORD): BOOL; stdcall; external opengl32 name 'wglUseFontBitmapsA';
   function wglUseFontOutlines(p1: HDC; p2, p3, p4: DWORD; p5, p6: Single; p7: Integer; p8: PGlyphMetricsFloat): BOOL; stdcall; external opengl32 name 'wglUseFontOutlinesA';

{$ifdef MULTITHREADOPENGL}
threadvar
{$else}
var
{$endif}

   // GL 1.2
   glDrawRangeElements: procedure(mode: TGLEnum; Astart, Aend: TGLuint; count: TGLsizei; Atype: TGLEnum;
                                  indices: Pointer); stdcall;
   glTexImage3D: procedure(target: TGLEnum; level: TGLint; internalformat: TGLEnum; width, height, depth: TGLsizei;
                           border: TGLint; format: TGLEnum; Atype: TGLEnum; pixels: Pointer); stdcall;

   // GL 1.2 ARB imaging
   glBlendColor: procedure(red, green, blue, alpha: TGLclampf); stdcall;
   glBlendEquation: procedure(mode: TGLEnum); stdcall;
   glColorSubTable: procedure(target: TGLEnum; start, count: TGLsizei; format, Atype: TGLEnum; data: Pointer); stdcall;
   glCopyColorSubTable: procedure(target: TGLEnum; start: TGLsizei; x, y: TGLint; width: TGLsizei); stdcall;
   glColorTable: procedure(target, internalformat: TGLEnum; width: TGLsizei; format, Atype: TGLEnum;
     table: Pointer); stdcall;
   glCopyColorTable: procedure(target, internalformat: TGLEnum; x, y: TGLint; width: TGLsizei); stdcall;
   glColorTableParameteriv: procedure(target, pname: TGLEnum; params: PGLint); stdcall;
   glColorTableParameterfv: procedure(target, pname: TGLEnum; params: PGLfloat); stdcall;
   glGetColorTable: procedure(target, format, Atype: TGLEnum; table: Pointer); stdcall;
   glGetColorTableParameteriv: procedure(target, pname: TGLEnum; params: PGLint); stdcall;
   glGetColorTableParameterfv: procedure(target, pname: TGLEnum; params: PGLfloat); stdcall;
   glConvolutionFilter1D: procedure(target, internalformat: TGLEnum; width: TGLsizei; format, Atype: TGLEnum;
     image: Pointer); stdcall;
   glConvolutionFilter2D: procedure(target, internalformat: TGLEnum; width, height: TGLsizei; format, Atype: TGLEnum;
     image: Pointer); stdcall;
   glCopyConvolutionFilter1D: procedure(target, internalformat: TGLEnum; x, y: TGLint; width: TGLsizei); stdcall;
   glCopyConvolutionFilter2D: procedure(target, internalformat: TGLEnum; x, y: TGLint; width, height: TGLsizei); stdcall;
   glGetConvolutionFilter: procedure(target, internalformat, Atype: TGLEnum; image: Pointer); stdcall;
   glSeparableFilter2D: procedure(target, internalformat: TGLEnum; width, height: TGLsizei; format, Atype: TGLEnum; row,
     column: Pointer); stdcall;
   glGetSeparableFilter: procedure(target, format, Atype: TGLEnum; row, column, span: Pointer); stdcall;
   glConvolutionParameteri: procedure(target, pname: TGLEnum; param: TGLint); stdcall;
   glConvolutionParameteriv: procedure(target, pname: TGLEnum; params: PGLint); stdcall;
   glConvolutionParameterf: procedure(target, pname: TGLEnum; param: TGLfloat); stdcall;
   glConvolutionParameterfv: procedure(target, pname: TGLEnum; params: PGLfloat); stdcall;
   glGetConvolutionParameteriv: procedure(target, pname: TGLEnum; params: PGLint); stdcall;
   glGetConvolutionParameterfv: procedure(target, pname: TGLEnum; params: PGLfloat); stdcall;
   glHistogram: procedure(target: TGLEnum; width: TGLsizei; internalformat: TGLEnum; sink: TGLboolean); stdcall;
   glResetHistogram: procedure(target: TGLEnum); stdcall;
   glGetHistogram: procedure(target: TGLEnum; reset: TGLboolean; format, Atype: TGLEnum; values: Pointer); stdcall;
   glGetHistogramParameteriv: procedure(target, pname: TGLEnum; params: PGLint); stdcall;
   glGetHistogramParameterfv: procedure(target, pname: TGLEnum; params: PGLfloat); stdcall;
   glMinmax: procedure(target, internalformat: TGLEnum; sink: TGLboolean); stdcall;
   glResetMinmax: procedure(target: TGLEnum); stdcall;
   glGetMinmax: procedure(target: TGLEnum; reset: TGLboolean; format, Atype: TGLEnum; values: Pointer); stdcall;
   glGetMinmaxParameteriv: procedure(target, pname: TGLEnum; params: PGLint); stdcall;
   glGetMinmaxParameterfv: procedure(target, pname: TGLEnum; params: PGLfloat); stdcall;

   // ARB wgl extensions
   wglGetExtensionsStringARB: function(DC: HDC): PAnsiChar; stdcall;
   wglGetPixelFormatAttribivARB: function(DC: HDC; iPixelFormat, iLayerPlane: Integer; nAttributes: TGLenum;
     const piAttributes: PGLint; piValues : PGLint) : BOOL; stdcall;
   wglGetPixelFormatAttribfvARB: function(DC: HDC; iPixelFormat, iLayerPlane: Integer; nAttributes: TGLenum;
     const piAttributes: PGLint; piValues: PGLFloat) : BOOL; stdcall;
   wglChoosePixelFormatARB: function(DC: HDC; const piAttribIList: PGLint; const pfAttribFList: PGLFloat;
     nMaxFormats: GLint; piFormats: PGLint; nNumFormats: PGLenum) : BOOL; stdcall;
   wglCreatePbufferARB: function(DC: HDC; iPixelFormat: Integer; iWidth, iHeight : Integer;
     const piAttribList: PGLint) : HPBUFFERARB; stdcall;
   wglGetPbufferDCARB: function(hPbuffer: HPBUFFERARB) : HDC; stdcall;
   wglReleasePbufferDCARB: function(hPbuffer: HPBUFFERARB; DC: HDC) : Integer; stdcall;
   wglDestroyPbufferARB: function(hPbuffer: HPBUFFERARB): BOOL; stdcall;
   wglQueryPbufferARB: function(hPbuffer: HPBUFFERARB; iAttribute : Integer;
     piValue: PGLint) : BOOL; stdcall;

   wglCreateBufferRegionARB: function(DC: HDC; iLayerPlane: Integer; uType: TGLenum) : Integer; stdcall;
   wglDeleteBufferRegionARB: procedure(hRegion: Integer); stdcall;
   wglSaveBufferRegionARB: function(hRegion: Integer; x, y, width, height: Integer): BOOL; stdcall;
   wglRestoreBufferRegionARB: function(hRegion: Integer; x, y, width, height: Integer;
     xSrc, ySrc: Integer): BOOL; stdcall;

   // non-ARB wgl extensions
   wglSwapIntervalEXT: function(interval : Integer) : BOOL; stdcall;
   wglGetSwapIntervalEXT: function : Integer; stdcall;


   // ARB_multitexture
   glMultiTexCoord1dARB: procedure(target: TGLenum; s: TGLdouble); stdcall;
   glMultiTexCoord1dVARB: procedure(target: TGLenum; v: PGLdouble); stdcall;
   glMultiTexCoord1fARB: procedure(target: TGLenum; s: TGLfloat); stdcall;
   glMultiTexCoord1fVARB: procedure(target: TGLenum; v: TGLfloat); stdcall;
   glMultiTexCoord1iARB: procedure(target: TGLenum; s: TGLint); stdcall;
   glMultiTexCoord1iVARB: procedure(target: TGLenum; v: PGLInt); stdcall;
   glMultiTexCoord1sARB: procedure(target: TGLenum; s: TGLshort); stdcall;
   glMultiTexCoord1sVARB: procedure(target: TGLenum; v: PGLshort); stdcall;
   glMultiTexCoord2dARB: procedure(target: TGLenum; s, t: TGLdouble); stdcall;
   glMultiTexCoord2dvARB: procedure(target: TGLenum; v: PGLdouble); stdcall;
   glMultiTexCoord2fARB: procedure(target: TGLenum; s, t: TGLfloat); stdcall;
   glMultiTexCoord2fvARB: procedure(target: TGLenum; v: PGLfloat); stdcall;
   glMultiTexCoord2iARB: procedure(target: TGLenum; s, t: TGLint); stdcall;
   glMultiTexCoord2ivARB: procedure(target: TGLenum; v: PGLint); stdcall;
   glMultiTexCoord2sARB: procedure(target: TGLenum; s, t: TGLshort); stdcall;
   glMultiTexCoord2svARB: procedure(target: TGLenum; v: PGLshort); stdcall;
   glMultiTexCoord3dARB: procedure(target: TGLenum; s, t, r: TGLdouble); stdcall;
   glMultiTexCoord3dvARB: procedure(target: TGLenum; v: PGLdouble); stdcall;
   glMultiTexCoord3fARB: procedure(target: TGLenum; s, t, r: TGLfloat); stdcall;
   glMultiTexCoord3fvARB: procedure(target: TGLenum; v: PGLfloat); stdcall;
   glMultiTexCoord3iARB: procedure(target: TGLenum; s, t, r: TGLint); stdcall;
   glMultiTexCoord3ivARB: procedure(target: TGLenum; v: PGLint); stdcall;
   glMultiTexCoord3sARB: procedure(target: TGLenum; s, t, r: TGLshort); stdcall;
   glMultiTexCoord3svARB: procedure(target: TGLenum; v: PGLshort); stdcall;
   glMultiTexCoord4dARB: procedure(target: TGLenum; s, t, r, q: TGLdouble); stdcall;
   glMultiTexCoord4dvARB: procedure(target: TGLenum; v: PGLdouble); stdcall;
   glMultiTexCoord4fARB: procedure(target: TGLenum; s, t, r, q: TGLfloat); stdcall;
   glMultiTexCoord4fvARB: procedure(target: TGLenum; v: PGLfloat); stdcall;
   glMultiTexCoord4iARB: procedure(target: TGLenum; s, t, r, q: TGLint); stdcall;
   glMultiTexCoord4ivARB: procedure(target: TGLenum; v: PGLint); stdcall;
   glMultiTexCoord4sARB: procedure(target: TGLenum; s, t, r, q: TGLshort); stdcall;
   glMultiTexCoord4svARB: procedure(target: TGLenum; v: PGLshort); stdcall;
   glActiveTextureARB: procedure(target: TGLenum); stdcall;
   glClientActiveTextureARB: procedure(target: TGLenum); stdcall;

   // GLU extensions
   gluNurbsCallbackDataEXT: procedure(nurb: PGLUnurbs; userData: Pointer); stdcall;
   gluNewNurbsTessellatorEXT: function: PGLUnurbs; stdcall;
   gluDeleteNurbsTessellatorEXT: procedure(nurb: PGLUnurbs); stdcall;

   // Extension functions
   glAreTexturesResidentEXT: function(n: TGLsizei; textures: PGLuint; residences: PGLBoolean): TGLboolean; stdcall;
   glArrayElementArrayEXT: procedure(mode: TGLEnum; count: TGLsizei; pi: Pointer); stdcall;
   glBeginSceneEXT: procedure; stdcall;
   glBindTextureEXT: procedure(target: TGLEnum; texture: TGLuint); stdcall;
   glColorTableEXT: procedure(target, internalFormat: TGLEnum; width: TGLsizei; format, atype: TGLEnum; data: Pointer); stdcall;
   glColorSubTableExt: procedure(target: TGLEnum; start, count: TGLsizei; format, atype: TGLEnum; data: Pointer); stdcall;
   glCopyTexImage1DEXT: procedure(target: TGLEnum; level: TGLint; internalFormat: TGLEnum; x, y: TGLint; width: TGLsizei; border: TGLint); stdcall;
   glCopyTexSubImage1DEXT: procedure(target: TGLEnum; level, xoffset, x, y: TGLint; width: TGLsizei); stdcall;
   glCopyTexImage2DEXT: procedure(target: TGLEnum; level: TGLint; internalFormat: TGLEnum; x, y: TGLint; width, height: TGLsizei; border: TGLint); stdcall;
   glCopyTexSubImage2DEXT: procedure(target: TGLEnum; level, xoffset, yoffset, x, y: TGLint; width, height: TGLsizei); stdcall;
   glCopyTexSubImage3DEXT: procedure(target: TGLEnum; level, xoffset, yoffset, zoffset, x, y: TGLint; width, height: TGLsizei); stdcall;
   glDeleteTexturesEXT: procedure(n: TGLsizei; textures: PGLuint); stdcall;
   glEndSceneEXT: procedure; stdcall;
   glGenTexturesEXT: procedure(n: TGLsizei; textures: PGLuint); stdcall;
   glGetColorTableEXT: procedure(target, format, atype: TGLEnum; data: Pointer); stdcall;
   glGetColorTablePameterfvEXT: procedure(target, pname: TGLEnum; params: Pointer); stdcall;
   glGetColorTablePameterivEXT: procedure(target, pname: TGLEnum; params: Pointer); stdcall;
   glIndexFuncEXT: procedure(func: TGLEnum; ref: TGLfloat); stdcall;
   glIndexMaterialEXT: procedure(face: TGLEnum; mode: TGLEnum); stdcall;
   glIsTextureEXT: function(texture: TGLuint): TGLboolean; stdcall;
   glPolygonOffsetEXT: procedure(factor, bias: TGLfloat); stdcall;
   glPrioritizeTexturesEXT: procedure(n: TGLsizei; textures: PGLuint; priorities: PGLclampf); stdcall;
   glTexSubImage1DEXT: procedure(target: TGLEnum; level, xoffset: TGLint; width: TGLsizei; format, Atype: TGLEnum; pixels: Pointer); stdcall;
   glTexSubImage2DEXT: procedure(target: TGLEnum; level, xoffset, yoffset: TGLint; width, height: TGLsizei; format, Atype: TGLEnum; pixels: Pointer); stdcall;
   glTexSubImage3DEXT: procedure(target: TGLEnum; level, xoffset, yoffset, zoffset: TGLint; width, height, depth: TGLsizei; format, Atype: TGLEnum; pixels: Pointer); stdcall;

   // EXT_compiled_vertex_array
   glLockArraysEXT: procedure(first: TGLint; count: TGLsizei); stdcall;
   glUnlockArraysEXT: procedure; stdcall;

   // EXT_stencil_two_side
   glActiveStencilFaceEXT: procedure(face: TGLenum); stdcall;

   // WIN_swap_hint
   glAddSwapHintRectWIN: procedure(x, y: TGLint; width, height: TGLsizei); stdcall;

   // GL_ARB_point_parameter
   glPointParameterfARB: procedure(pname: TGLenum; param: TGLfloat); stdcall;
   glPointParameterfvARB: procedure(pname: TGLenum; params: PGLfloat); stdcall;

   // GL_ARB_transpose_matrix
   glLoadTransposeMatrixfARB: procedure(m: PGLfloat); stdcall;
   glLoadTransposeMatrixdARB: procedure(m: PGLdouble); stdcall;
   glMultTransposeMatrixfARB: procedure(m: PGLfloat); stdcall;
   glMultTransposeMatrixdARB: procedure(m: PGLdouble); stdcall;

   // GL_ARB_multisample
   glSampleCoverageARB: procedure(Value: TGLclampf; invert: TGLboolean); stdcall;
   glSamplePassARB: procedure(pass: TGLenum); stdcall;

   // GL_ARB_texture_compression
   glCompressedTexImage3DARB: procedure(target: TGLenum; level: TGLint; internalformat: TGLenum; Width, Height, depth: TGLsizei; border: TGLint; imageSize: TGLsizei; data: pointer); stdcall;
   glCompressedTexImage2DARB: procedure(target: TGLenum; level: TGLint; internalformat: TGLenum; Width, Height: TGLsizei; border: TGLint; imageSize: TGLsizei; data: pointer); stdcall;
   glCompressedTexImage1DARB: procedure(target: TGLenum; level: TGLint; internalformat: TGLenum; Width: TGLsizei; border: TGLint; imageSize: TGLsizei; data: pointer); stdcall;
   glCompressedTexSubImage3DARB: procedure(target: TGLenum; level: TGLint; xoffset, yoffset, zoffset: TGLint; width, height, depth: TGLsizei; Format: TGLenum; imageSize: TGLsizei; data: pointer); stdcall;
   glCompressedTexSubImage2DARB: procedure(target: TGLenum; level: TGLint; xoffset, yoffset: TGLint; width, height: TGLsizei; Format: TGLenum; imageSize: TGLsizei; data: pointer); stdcall;
   glCompressedTexSubImage1DARB: procedure(target: TGLenum; level: TGLint; xoffset: TGLint; width: TGLsizei; Format: TGLenum; imageSize: TGLsizei; data: pointer); stdcall;
   glGetCompressedTexImageARB: procedure(target: TGLenum; level: TGLint; img: pointer); stdcall;

   // GL_ARB_vertex_program
   glVertexAttrib1sARB: procedure(index: GLuint; x: GLshort); stdcall;
   glVertexAttrib1fARB: procedure(index: GLuint; x: GLfloat); stdcall;
   glVertexAttrib1dARB: procedure(index: GLuint; x: GLdouble); stdcall;
   glVertexAttrib2sARB: procedure(index: GLuint; x: GLshort; y: GLshort); stdcall;
   glVertexAttrib2fARB: procedure(index: GLuint; x: GLfloat; y: GLfloat); stdcall;
   glVertexAttrib2dARB: procedure(index: GLuint; x: GLdouble; y: GLdouble); stdcall;
   glVertexAttrib3sARB: procedure(index: GLuint; x: GLshort; y: GLshort; z: GLshort); stdcall;
   glVertexAttrib3fARB: procedure(index: GLuint; x: GLfloat; y: GLfloat; z: GLfloat); stdcall;
   glVertexAttrib3dARB: procedure(index: GLuint; x: GLdouble; y: GLdouble; z: GLdouble); stdcall;
   glVertexAttrib4sARB: procedure(index: GLuint; x: GLshort; y: GLshort; z: GLshort; w: GLshort); stdcall;
   glVertexAttrib4fARB: procedure(index: GLuint; x: GLfloat; y: GLfloat; z: GLfloat; w: GLfloat); stdcall;
   glVertexAttrib4dARB: procedure(index: GLuint; x: GLdouble; y: GLdouble; z: GLdouble; w: GLdouble); stdcall;
   glVertexAttrib4NubARB: procedure(index: GLuint; x: GLubyte; y: GLubyte; z: GLubyte; w: GLubyte); stdcall;
   glVertexAttrib1svARB: procedure(index: GLuint; const v: PGLshort); stdcall;
   glVertexAttrib1fvARB: procedure(index: GLuint; const v: PGLfloat); stdcall;
   glVertexAttrib1dvARB: procedure(index: GLuint; const v: PGLdouble); stdcall;
   glVertexAttrib2svARB: procedure(index: GLuint; const v: PGLshort); stdcall;
   glVertexAttrib2fvARB: procedure(index: GLuint; const v: PGLfloat); stdcall;
   glVertexAttrib2dvARB: procedure(index: GLuint; const v: PGLdouble); stdcall;
   glVertexAttrib3svARB: procedure(index: GLuint; const v: PGLshort); stdcall;
   glVertexAttrib3fvARB: procedure(index: GLuint; const v: PGLfloat); stdcall;
   glVertexAttrib3dvARB: procedure(index: GLuint; const v: PGLdouble); stdcall;
   glVertexAttrib4bvARB: procedure(index: GLuint; const v: PGLbyte); stdcall;
   glVertexAttrib4svARB: procedure(index: GLuint; const v: PGLshort); stdcall;
   glVertexAttrib4ivARB: procedure(index: GLuint; const v: PGLint); stdcall;
   glVertexAttrib4ubvARB: procedure(index: GLuint; const v: PGLubyte); stdcall;
   glVertexAttrib4usvARB: procedure(index: GLuint; const v: PGLushort); stdcall;
   glVertexAttrib4uivARB: procedure(index: GLuint; const v: PGLuint); stdcall;
   glVertexAttrib4fvARB: procedure(index: GLuint; const v: PGLfloat); stdcall;
   glVertexAttrib4dvARB: procedure(index: GLuint; const v: PGLdouble); stdcall;
   glVertexAttrib4NbvARB: procedure(index: GLuint; const v: PGLbyte); stdcall;
   glVertexAttrib4NsvARB: procedure(index: GLuint; const v: PGLshort); stdcall;
   glVertexAttrib4NivARB: procedure(index: GLuint; const v: PGLint); stdcall;
   glVertexAttrib4NubvARB: procedure(index: GLuint; const v: PGLubyte); stdcall;
   glVertexAttrib4NusvARB: procedure(index: GLuint; const v: PGLushort); stdcall;
   glVertexAttrib4NuivARB: procedure(index: GLuint; const v: PGLuint); stdcall;
   glVertexAttribPointerARB: procedure(index: GLuint; size: GLint; _type: GLenum; normalized: GLboolean; stride: GLsizei; const _pointer: pointer); stdcall;
   glEnableVertexAttribArrayARB: procedure(index: GLuint); stdcall;
   glDisableVertexAttribArrayARB: procedure(index: GLuint); stdcall;
   glProgramStringARB: procedure(target: GLenum; format: GLenum; len: GLsizei; const _string: pointer); stdcall;
   glBindProgramARB: procedure(target: GLenum; _program: GLuint); stdcall;
   glDeleteProgramsARB: procedure(n: GLsizei; const programs: PGLuint); stdcall;
   glGenProgramsARB: procedure(n: GLsizei; programs: PGLuint); stdcall;
   glProgramEnvParameter4dARB: procedure(target: GLenum; index: GLuint; x: GLdouble; y: GLdouble; z: GLdouble; w: GLdouble); stdcall;
   glProgramEnvParameter4dvARB: procedure(target: GLenum; index: GLuint; const params: PGLdouble); stdcall;
   glProgramEnvParameter4fARB: procedure(target: GLenum; index: GLuint; x: GLfloat; y: GLfloat; z: GLfloat; w: GLfloat); stdcall;
   glProgramEnvParameter4fvARB: procedure(target: GLenum; index: GLuint; const params: PGLfloat); stdcall;
   glProgramLocalParameter4dARB: procedure(target: GLenum; index: GLuint; x: GLdouble; y: GLdouble; z: GLdouble; w: GLdouble); stdcall;
   glProgramLocalParameter4dvARB: procedure(target: GLenum; index: GLuint; const params: PGLdouble); stdcall;
   glProgramLocalParameter4fARB: procedure(target: GLenum; index: GLuint; x: GLfloat; y: GLfloat; z: GLfloat; w: GLfloat); stdcall;
   glProgramLocalParameter4fvARB: procedure(target: GLenum; index: GLuint; const params: PGLfloat); stdcall;
   glGetProgramEnvParameterdvARB: procedure(target: GLenum; index: GLuint; params: PGLdouble); stdcall;
   glGetProgramEnvParameterfvARB: procedure(target: GLenum; index: GLuint; params: PGLfloat); stdcall;
   glGetProgramLocalParameterdvARB: procedure(target: GLenum; index: GLuint; params: PGLdouble); stdcall;
   glGetProgramLocalParameterfvARB: procedure(target: GLenum; index: GLuint; params: PGLfloat); stdcall;
   glGetProgramivARB: procedure(target: GLenum; pname: GLenum; params: PGLint); stdcall;
   glGetProgramStringARB: procedure(target: GLenum; pname: GLenum; _string: pointer); stdcall;
   glGetVertexAttribdvARB: procedure(index: GLuint; pname: GLenum; params: PGLdouble); stdcall;
   glGetVertexAttribfvARB: procedure(index: GLuint; pname: GLenum; params: PGLfloat); stdcall;
   glGetVertexAttribivARB: procedure(index: GLuint; pname: GLenum; params: PGLint); stdcall;
   glGetVertexAttribPointervARB: procedure(index: GLuint; pname: GLenum; _pointer: pointer); stdcall;
   glIsProgramARB: function(_program: GLuint): GLboolean; stdcall;

   // GL_ARB_vertex_buffer_object
   glBindBufferARB: procedure(target: GLenum; buffer: GLuint); stdcall;
   glDeleteBuffersARB: procedure(n: GLsizei; const buffers: PGLuint); stdcall;
   glGenBuffersARB: procedure(n: GLsizei; buffers: PGLuint); stdcall;
   glIsBufferARB: function(buffer: GLuint): GLboolean; stdcall;
   glBufferDataARB: procedure(target: GLenum; size: GLsizei; const data: Pointer; usage: GLenum); stdcall;
   glBufferSubDataARB: procedure(target: GLenum; offset: GLuint; size: GLsizei; const data: Pointer); stdcall;
   glGetBufferSubDataARB: procedure(target: GLenum; offset: GLuint; size: GLsizei; data: Pointer); stdcall;
   glMapBufferARB: function(target: GLenum; access: GLenum): Pointer; stdcall;
   glUnmapBufferARB: function(target: GLenum): GLboolean; stdcall;
   glGetBufferParameterivARB: procedure(target: GLenum; pname: GLenum; params: PGLint); stdcall;
   glGetBufferPointervARB: procedure(target: GLenum; pname: GLenum; params: Pointer); stdcall;

   // GL_ARB_shader_objects
   glDeleteObjectARB: procedure(obj: GLhandleARB); stdcall;
   glGetHandleARB: function(pname: GLenum): GLhandleARB; stdcall;
   glDetachObjectARB: procedure(containerObj: GLhandleARB; attachedObj: GLhandleARB); stdcall;
   glCreateShaderObjectARB: function(shaderType: GLenum): GLhandleARB; stdcall;
   glShaderSourceARB: procedure(shaderObj: GLhandleARB; count: GLsizei; const _string: PGLPAnsiCharArray; const length: PGLint); stdcall;
   glCompileShaderARB: procedure(shaderObj: GLhandleARB); stdcall;
   glCreateProgramObjectARB: function(): GLhandleARB; stdcall;
   glAttachObjectARB: procedure(containerObj: GLhandleARB; obj: GLhandleARB); stdcall;
   glLinkProgramARB: procedure(programObj: GLhandleARB); stdcall;
   glUseProgramObjectARB: procedure(programObj: GLhandleARB); stdcall;
   glValidateProgramARB: procedure(programObj: GLhandleARB); stdcall;
   glUniform1fARB: procedure(location: GLint; v0: GLfloat); stdcall;
   glUniform2fARB: procedure(location: GLint; v0: GLfloat; v1: GLfloat); stdcall;
   glUniform3fARB: procedure(location: GLint; v0: GLfloat; v1: GLfloat; v2: GLfloat); stdcall;
   glUniform4fARB: procedure(location: GLint; v0: GLfloat; v1: GLfloat; v2: GLfloat; v3: GLfloat); stdcall;
   glUniform1iARB: procedure(location: GLint; v0: GLint); stdcall;
   glUniform2iARB: procedure(location: GLint; v0: GLint; v1: GLint); stdcall;
   glUniform3iARB: procedure(location: GLint; v0: GLint; v1: GLint; v2: GLint); stdcall;
   glUniform4iARB: procedure(location: GLint; v0: GLint; v1: GLint; v2: GLint; v3: GLint); stdcall;
   glUniform1fvARB: procedure(location: GLint; count: GLsizei; value: PGLfloat); stdcall;
   glUniform2fvARB: procedure(location: GLint; count: GLsizei; value: PGLfloat); stdcall;
   glUniform3fvARB: procedure(location: GLint; count: GLsizei; value: PGLfloat); stdcall;
   glUniform4fvARB: procedure(location: GLint; count: GLsizei; value: PGLfloat); stdcall;
   glUniform1ivARB: procedure(location: GLint; count: GLsizei; value: PGLint); stdcall;
   glUniform2ivARB: procedure(location: GLint; count: GLsizei; value: PGLint); stdcall;
   glUniform3ivARB: procedure(location: GLint; count: GLsizei; value: PGLint); stdcall;
   glUniform4ivARB: procedure(location: GLint; count: GLsizei; value: PGLint); stdcall;
   glUniformMatrix2fvARB: procedure(location: GLint; count: GLsizei; transpose: GLboolean; value: PGLfloat); stdcall;
   glUniformMatrix3fvARB: procedure(location: GLint; count: GLsizei; transpose: GLboolean; value: PGLfloat); stdcall;
   glUniformMatrix4fvARB: procedure(location: GLint; count: GLsizei; transpose: GLboolean; value: PGLfloat); stdcall;
   glGetObjectParameterfvARB: procedure(obj: GLhandleARB; pname: GLenum; params: PGLfloat); stdcall;
   glGetObjectParameterivARB: procedure(obj: GLhandleARB; pname: GLenum; params: PGLint); stdcall;
   glGetInfoLogARB: procedure(obj: GLhandleARB; maxLength: GLsizei; length: PGLsizei; infoLog: PAnsiChar); stdcall;
   glGetAttachedObjectsARB: procedure(containerObj: GLhandleARB; maxCount: GLsizei; count: PGLsizei; obj: PGLhandleARB); stdcall;
   glGetUniformLocationARB: function(programObj: GLhandleARB; const name: PAnsiChar): GLint; stdcall;
   glGetActiveUniformARB: procedure(programObj: GLhandleARB; index: GLuint; maxLength: GLsizei; length: PGLsizei; size: PGLint; _type: PGLenum; name: PAnsiChar); stdcall;
   glGetUniformfvARB: procedure(programObj: GLhandleARB; location: GLint; params: PGLfloat); stdcall;
   glGetUniformivARB: procedure(programObj: GLhandleARB; location: GLint; params: PGLint); stdcall;
   glGetShaderSourceARB: procedure(obj: GLhandleARB; maxLength: GLsizei; length: PGLsizei; source: PAnsiChar); stdcall;

   // GL_ARB_vertex_shader
   glBindAttribLocationARB: procedure(programObj: GLhandleARB; index: GLuint; const name: PAnsiChar); stdcall;
   glGetActiveAttribARB: procedure(programObj: GLhandleARB; index: GLuint; maxLength: GLsizei; length: PGLsizei; size: PGLint; _type: PGLenum; name: PAnsiChar); stdcall;
   glGetAttribLocationARB: function(programObj: GLhandleARB; const name: PAnsiChar): GLint; stdcall;

   // GL_EXT_blend_color
   glBlendColorEXT: procedure(red, green, blue: TGLclampf; alpha: TGLclampf); stdcall;

   // GL_EXT_texture3D
   glTexImage3DEXT: procedure(target: TGLenum; level: TGLint; internalformat: TGLenum; width, height, depth: TGLsizei; border: TGLint; Format, AType: TGLenum; pixels: Pointer); stdcall;

   // GL_SGIS_multisample
   glSampleMaskSGIS: procedure(Value: TGLclampf; invert: TGLboolean); stdcall;
   glSamplePatternSGIS: procedure(pattern: TGLenum); stdcall;

   // GL_EXT_blend_minmax
   glBlendEquationEXT: procedure(mode: TGLenum); stdcall;

   // GL_EXT_paletted_texture
   glGetColorTableParameterivEXT: procedure(target, pname: TGLenum; params: PGLint); stdcall;
   glGetColorTableParameterfvEXT: procedure(target, pname: TGLenum; params: PGLfloat); stdcall;

   // GL_EXT_draw_range_elements
   glDrawRangeElementsEXT: procedure(mode: TGLenum; start, Aend: TGLuint; Count: TGLsizei; Atype: TGLenum; indices: Pointer); stdcall;

   // GL_EXT_secondary_color
   glSecondaryColor3bEXT: procedure(red, green, blue: TGLbyte); stdcall;
   glSecondaryColor3bvEXT: procedure(v: PGLbyte); stdcall;
   glSecondaryColor3dEXT: procedure(red, green, blue: TGLdouble); stdcall;
   glSecondaryColor3dvEXT: procedure(v: PGLdouble); stdcall;
   glSecondaryColor3fEXT: procedure(red, green, blue: TGLfloat); stdcall;
   glSecondaryColor3fvEXT: procedure(v: PGLfloat); stdcall;
   glSecondaryColor3iEXT: procedure(red, green, blue: TGLint); stdcall;
   glSecondaryColor3ivEXT: procedure(v: PGLint); stdcall;

   glSecondaryColor3sEXT: procedure(red, green, blue: TGLshort); stdcall;
   glSecondaryColor3svEXT: procedure(v: PGLshort); stdcall;
   glSecondaryColor3ubEXT: procedure(red, green, blue: TGLubyte); stdcall;
   glSecondaryColor3ubvEXT: procedure(v: PGLubyte); stdcall;
   glSecondaryColor3uiEXT: procedure(red, green, blue: TGLuint); stdcall;
   glSecondaryColor3uivEXT: procedure(v: PGLuint); stdcall;
   glSecondaryColor3usEXT: procedure(red, green, blue: TGLushort); stdcall;
   glSecondaryColor3usvEXT: procedure(v: PGLushort); stdcall;
   glSecondaryColorPointerEXT: procedure(Size: TGLint; Atype: TGLenum; stride: TGLsizei; p: pointer); stdcall;

   // GL_EXT_multi_draw_arrays
   glMultiDrawArraysEXT: procedure(mode: TGLenum; First: PGLint; Count: PGLsizei; primcount: TGLsizei); stdcall;
   glMultiDrawElementsEXT: procedure(mode: TGLenum; Count: PGLsizei; AType: TGLenum; var indices; primcount: TGLsizei); stdcall;

   // GL_EXT_fog_coord
   glFogCoordfEXT: procedure(coord: TGLfloat); stdcall;
   glFogCoordfvEXT: procedure(coord: PGLfloat); stdcall;
   glFogCoorddEXT: procedure(coord: TGLdouble); stdcall;
   glFogCoorddvEXT: procedure(coord: PGLdouble); stdcall;
   glFogCoordPointerEXT: procedure(AType: TGLenum; stride: TGLsizei; p: Pointer); stdcall;

   // GL_EXT_blend_func_separate
   glBlendFuncSeparateEXT: procedure(sfactorRGB, dfactorRGB, sfactorAlpha, dfactorAlpha: TGLenum); stdcall;

   // GL_NV_vertex_array_range
   glFlushVertexArrayRangeNV: procedure; stdcall;
   glVertexArrayRangeNV: procedure(Size: TGLsizei; p: pointer); stdcall;
   wglAllocateMemoryNV: function(size: TGLsizei; readFrequency, writeFrequency, priority: Single): Pointer; stdcall;
   wglFreeMemoryNV: procedure(ptr: Pointer); stdcall;

   // GL_NV_register_combiners
   glCombinerParameterfvNV: procedure(pname: TGLenum; params: PGLfloat); stdcall;
   glCombinerParameterfNV: procedure(pname: TGLenum; param: TGLfloat); stdcall;
   glCombinerParameterivNV: procedure(pname: TGLenum; params: PGLint); stdcall;
   glCombinerParameteriNV: procedure(pname: TGLenum; param: TGLint); stdcall;
   glCombinerInputNV: procedure(stage, portion, variable, input, mapping, componentUsage: TGLenum); stdcall;
   glCombinerOutputNV: procedure(stage, portion, abOutput, cdOutput, sumOutput, scale, bias: TGLenum; abDotProduct, cdDotProduct, muxSum: TGLboolean); stdcall;
   glFinalCombinerInputNV: procedure(variable, input, mapping, componentUsage: TGLenum); stdcall;
   glGetCombinerInputParameterfvNV: procedure(stage, portion, variable, pname: TGLenum; params: PGLfloat); stdcall;
   glGetCombinerInputParameterivNV: procedure(stage, portion, variable, pname: TGLenum; params: PGLint); stdcall;
   glGetCombinerOutputParameterfvNV: procedure(stage, portion, pname: TGLenum; params: PGLfloat); stdcall;
   glGetCombinerOutputParameterivNV: procedure(stage, portion, pname: TGLenum; params: PGLint); stdcall;
   glGetFinalCombinerInputParameterfvNV: procedure(variable, pname: TGLenum; params: PGLfloat); stdcall;
   glGetFinalCombinerInputParameterivNV: procedure(variable, pname: TGLenum; params: PGLint); stdcall;

   // GL_NV_fence
   glGenFencesNV: procedure(n: TGLsizei; fences: PGLuint); stdcall;
   glDeleteFencesNV: procedure(n: TGLsizei; fences: PGLuint); stdcall;
   glSetFenceNV: procedure(fence: TGLuint; condition: TGLenum); stdcall;
   glTestFenceNV: function(fence: TGLuint): TGLboolean; stdcall;
   glFinishFenceNV: procedure(fence: TGLuint); stdcall;
   glIsFenceNV: function(fence: TGLuint): TGLboolean; stdcall;
   glGetFenceivNV: procedure(fence: TGLuint; pname: TGLenum; params: PGLint); stdcall;

   // GL_NV_occlusion_query
   glGenOcclusionQueriesNV: procedure(n: TGLsizei; ids: PGLuint); stdcall;
   glDeleteOcclusionQueriesNV: procedure(n: TGLsizei; const ids: PGLuint); stdcall;
   glIsOcclusionQueryNV: function(id: TGLuint): TGLboolean; stdcall;
   glBeginOcclusionQueryNV: procedure(id: TGLuint); stdcall;
   glEndOcclusionQueryNV: procedure; stdcall;
   glGetOcclusionQueryivNV: procedure(id: TGLuint; pname: TGLenum; params: PGLint); stdcall;
   glGetOcclusionQueryuivNV: procedure(id: TGLuint; pname: TGLenum; params: PGLuint); stdcall;

   // GL_MESA_resize_buffers
   glResizeBuffersMESA: procedure; stdcall;

   // GL_3DFX_tbuffer
   glTbufferMask3DFX: procedure(mask: TGLuint); stdcall;

   // GL_EXT_multisample
   glSampleMaskEXT: procedure(Value: TGLclampf; invert: TGLboolean); stdcall;
   glSamplePatternEXT: procedure(pattern: TGLenum); stdcall;

   // GL_SGIS_texture_color_mask
   glTextureColorMaskSGIS: procedure(red, green, blue, alpha: TGLboolean); stdcall;

   // GL_NV_vertex_program
   glAreProgramsResidentNV: procedure(n: TGLSizei; programs: PGLuint; residences: PGLboolean); stdcall;
   glBindProgramNV: procedure(target: TGLenum; id: TGLuint); stdcall;
   glDeleteProgramsNV: procedure(n: TGLSizei; programs: PGLuint); stdcall;
   glExecuteProgramNV: procedure(target: TGLenum; id: TGLuint; params: PGLfloat); stdcall;
   glGenProgramsNV: procedure(n: TGLSizei; programs: PGLuint); stdcall;
   glGetProgramParameterdvNV: procedure (target: TGLenum; index: TGLuint; pname: TGLenum; params: PGLdouble); stdcall;
   glGetProgramParameterfvNV: procedure (target: TGLenum; index: TGLuint; pname: TGLenum; params: PGLfloat); stdcall;
   glGetProgramivNV: procedure (id: TGLuint; pname: TGLenum; params: PGLint); stdcall;
   glGetProgramStringNV: procedure (id: TGLuint; pname: TGLenum; programIdx: PGLubyte); stdcall;
   glGetTrackMatrixivNV: procedure (target: TGLenum; address: TGLuint; pname: TGLenum; params: PGLint); stdcall;
   glGetVertexAttribdvNV: procedure (index: TGLuint; pname: TGLenum; params: PGLdouble); stdcall;
   glGetVertexAttribfvNV: procedure (index: TGLuint; pname: TGLenum; params: PGLfloat); stdcall;
   glGetVertexAttribivNV: procedure (index: TGLuint; pname: TGLenum; params: PGLint); stdcall;
   glGetVertexAttribPointervNV: procedure (index: TGLuint; pname: TGLenum; pointer: PGLPointer); stdcall;
   glIsProgramNV: function (id: TGLuint): TGLboolean; stdcall;
   glLoadProgramNV: procedure (target: TGLenum; id: TGLuint; len: TGLSizei; programIdx: PGLubyte); stdcall;
   glProgramParameter4dNV: procedure (target: TGLenum; index: TGLuint; x, y, z, w: TGLdouble); stdcall;
   glProgramParameter4dvNV: procedure (target: TGLenum; index: TGLuint; v: PGLdouble ); stdcall;
   glProgramParameter4fNV: procedure (target: TGLenum; index: TGLuint; x, y, z, w: TGLfloat); stdcall;
   glProgramParameter4fvNV: procedure (target: TGLenum; index: TGLuint; v: PGLfloat); stdcall;
   glProgramParameters4dvNV: procedure (target: TGLenum; index: TGLuint; count: TGLSizei; v: PGLdouble); stdcall;
   glProgramParameters4fvNV: procedure (target: TGLenum; index: TGLuint; count: TGLSizei; v: PGLfloat); stdcall;
   glRequestResidentProgramsNV: procedure (n: TGLSizei; programs: PGLuint); stdcall;
   glTrackMatrixNV: procedure (target: TGLenum; address: TGLuint; matrix: TGLenum; transform: TGLenum); stdcall;
   glVertexAttribPointerNV: procedure (index: TGLuint; fsize: TGLint; vertextype: TGLenum; stride: TGLSizei; pointer: Pointer); stdcall;
   glVertexAttrib1dNV: procedure (index: TGLuint; x: TGLdouble); stdcall;
   glVertexAttrib1dvNV: procedure (index: TGLuint; v: PGLdouble); stdcall;
   glVertexAttrib1fNV: procedure (index: TGLuint; x: TGLfloat); stdcall;
   glVertexAttrib1fvNV: procedure (index: TGLuint; v: PGLfloat); stdcall;
   glVertexAttrib1sNV: procedure (index: TGLuint; x: TGLshort); stdcall;
   glVertexAttrib1svNV: procedure (index: TGLuint; v: PGLshort); stdcall;
   glVertexAttrib2dNV: procedure (index: TGLuint; x: TGLdouble; y: TGLdouble); stdcall;
   glVertexAttrib2dvNV: procedure (index: TGLuint; v: PGLdouble); stdcall;
   glVertexAttrib2fNV: procedure (index: TGLuint; x: TGLfloat; y: TGLfloat); stdcall;
   glVertexAttrib2fvNV: procedure (index: TGLuint; v: PGLfloat); stdcall;
   glVertexAttrib2sNV: procedure (index: TGLuint; x: TGLshort; y: TGLshort); stdcall;
   glVertexAttrib2svNV: procedure (index: TGLuint; v: PGLshort); stdcall;
   glVertexAttrib3dNV: procedure (index: TGLuint; x: TGLdouble; y: TGLdouble; z: TGLdouble); stdcall;
   glVertexAttrib3dvNV: procedure (index: TGLuint; v: PGLdouble); stdcall;
   glVertexAttrib3fNV: procedure (index: TGLuint; x: TGLfloat; y: TGLfloat; z: TGLfloat); stdcall;
   glVertexAttrib3fvNV: procedure (index: TGLuint; v: PGLfloat); stdcall;
   glVertexAttrib3sNV: procedure (index: TGLuint; x: TGLshort; y: TGLshort; z: TGLshort); stdcall;
   glVertexAttrib3svNV: procedure (index: TGLuint; v: PGLshort); stdcall;
   glVertexAttrib4dNV: procedure (index: TGLuint; x: TGLdouble; y: TGLdouble; z: TGLdouble; w: TGLdouble); stdcall;
   glVertexAttrib4dvNV: procedure (index: TGLuint; v: PGLdouble); stdcall;
   glVertexAttrib4fNV: procedure(index: TGLuint; x: TGLfloat; y: TGLfloat; z: TGLfloat; w: TGLfloat); stdcall;
   glVertexAttrib4fvNV: procedure(index: TGLuint; v: PGLfloat); stdcall;
   glVertexAttrib4sNV: procedure (index: TGLuint; x: TGLshort; y: TGLshort; z: TGLdouble; w: TGLshort); stdcall;
   glVertexAttrib4svNV: procedure (index: TGLuint; v: PGLshort); stdcall;
   glVertexAttrib4ubvNV: procedure (index: TGLuint; v: PGLubyte); stdcall;
   glVertexAttribs1dvNV: procedure (index: TGLuint; count: TGLSizei; v: PGLdouble); stdcall;
   glVertexAttribs1fvNV: procedure (index: TGLuint; count: TGLSizei; v: PGLfloat); stdcall;
   glVertexAttribs1svNV: procedure (index: TGLuint; count: TGLSizei; v: PGLshort); stdcall;
   glVertexAttribs2dvNV: procedure (index: TGLuint; count: TGLSizei; v: PGLdouble); stdcall;
   glVertexAttribs2fvNV: procedure (index: TGLuint; count: TGLSizei; v: PGLfloat); stdcall;
   glVertexAttribs2svNV: procedure (index: TGLuint; count: TGLSizei; v: PGLshort); stdcall;
   glVertexAttribs3dvNV: procedure (index: TGLuint; count: TGLSizei; v: PGLdouble); stdcall;
   glVertexAttribs3fvNV: procedure (index: TGLuint; count: TGLSizei; v: PGLfloat); stdcall;
   glVertexAttribs3svNV: procedure (index: TGLuint; count: TGLSizei; v: PGLshort); stdcall;
   glVertexAttribs4dvNV: procedure (index: TGLuint; count: TGLSizei; v: PGLdouble); stdcall;
   glVertexAttribs4fvNV: procedure (index: TGLuint; count: TGLSizei; v: PGLfloat); stdcall;
   glVertexAttribs4svNV: procedure (index: TGLuint; count: TGLSizei; v: PGLshort); stdcall;
   glVertexAttribs4ubvNV: procedure (index: TGLuint; count: TGLSizei; v: PGLubyte); stdcall;

   // GL_ATI_draw_buffers
   glDrawBuffersATI: procedure(n: GLsizei; const bufs: PGLenum); stdcall;

//------------------------------------------------------------------------------

procedure CloseOpenGL;
function InitOpenGL : Boolean;
function InitOpenGLFromLibrary(const GLName, GLUName : AnsiString) : Boolean;
function IsOpenGLInitialized: Boolean;

procedure UnloadOpenGL;
function LoadOpenGL : Boolean;
function LoadOpenGLFromLibrary(GLName, GLUName: AnsiString): Boolean;
//: True if OpenGL is loaded
function IsOpenGLLoaded : Boolean;
function IsMesaGL : Boolean;


procedure ReadExtensions;
procedure ReadImplementationProperties;
procedure ReadWGLExtensions;
procedure ReadWGLImplementationProperties;

// Buffer ID's for Multiple-Render-Targets (using GL_ATI_draw_buffers)
const
  MRT_BUFFERS: array [0..3] of GLenum = (GL_FRONT_LEFT, GL_AUX0, GL_AUX1, GL_AUX2);

const
  glEnumDictionary:array[0..1628]of record id:GLEnum;name:ansistring end=(
    (id:GL_NO_ERROR;name:'GL_NO_ERROR'),
    (id:GL_INVALID_ENUM;name:'GL_INVALID_ENUM'),
    (id:GL_INVALID_VALUE;name:'GL_INVALID_VALUE'),
    (id:GL_INVALID_OPERATION;name:'GL_INVALID_OPERATION'),
    (id:GL_STACK_OVERFLOW;name:'GL_STACK_OVERFLOW'),
    (id:GL_STACK_UNDERFLOW;name:'GL_STACK_UNDERFLOW'),
    (id:GL_OUT_OF_MEMORY;name:'GL_OUT_OF_MEMORY'),
    (id:GL_CURRENT_BIT;name:'GL_CURRENT_BIT'),
    (id:GL_POINT_BIT;name:'GL_POINT_BIT'),
    (id:GL_LINE_BIT;name:'GL_LINE_BIT'),
    (id:GL_POLYGON_BIT;name:'GL_POLYGON_BIT'),
    (id:GL_POLYGON_STIPPLE_BIT;name:'GL_POLYGON_STIPPLE_BIT'),
    (id:GL_PIXEL_MODE_BIT;name:'GL_PIXEL_MODE_BIT'),
    (id:GL_LIGHTING_BIT;name:'GL_LIGHTING_BIT'),
    (id:GL_FOG_BIT;name:'GL_FOG_BIT'),
    (id:GL_DEPTH_BUFFER_BIT;name:'GL_DEPTH_BUFFER_BIT'),
    (id:GL_ACCUM_BUFFER_BIT;name:'GL_ACCUM_BUFFER_BIT'),
    (id:GL_STENCIL_BUFFER_BIT;name:'GL_STENCIL_BUFFER_BIT'),
    (id:GL_VIEWPORT_BIT;name:'GL_VIEWPORT_BIT'),
    (id:GL_TRANSFORM_BIT;name:'GL_TRANSFORM_BIT'),
    (id:GL_ENABLE_BIT;name:'GL_ENABLE_BIT'),
    (id:GL_COLOR_BUFFER_BIT;name:'GL_COLOR_BUFFER_BIT'),
    (id:GL_HINT_BIT;name:'GL_HINT_BIT'),
    (id:GL_EVAL_BIT;name:'GL_EVAL_BIT'),
    (id:GL_LIST_BIT;name:'GL_LIST_BIT'),
    (id:GL_TEXTURE_BIT;name:'GL_TEXTURE_BIT'),
    (id:GL_SCISSOR_BIT;name:'GL_SCISSOR_BIT'),
    (id:GL_ALL_ATTRIB_BITS;name:'GL_ALL_ATTRIB_BITS'),
    (id:GL_CLIENT_PIXEL_STORE_BIT;name:'GL_CLIENT_PIXEL_STORE_BIT'),
    (id:GL_CLIENT_VERTEX_ARRAY_BIT;name:'GL_CLIENT_VERTEX_ARRAY_BIT'),
    (id:GL_CLIENT_ALL_ATTRIB_BITS;name:'GL_CLIENT_ALL_ATTRIB_BITS'),
    (id:GL_FALSE;name:'GL_FALSE'),
    (id:GL_TRUE;name:'GL_TRUE'),
    (id:GL_POINTS;name:'GL_POINTS'),
    (id:GL_LINES;name:'GL_LINES'),
    (id:GL_LINE_LOOP;name:'GL_LINE_LOOP'),
    (id:GL_LINE_STRIP;name:'GL_LINE_STRIP'),
    (id:GL_TRIANGLES;name:'GL_TRIANGLES'),
    (id:GL_TRIANGLE_STRIP;name:'GL_TRIANGLE_STRIP'),
    (id:GL_TRIANGLE_FAN;name:'GL_TRIANGLE_FAN'),
    (id:GL_QUADS;name:'GL_QUADS'),
    (id:GL_QUAD_STRIP;name:'GL_QUAD_STRIP'),
    (id:GL_POLYGON;name:'GL_POLYGON'),
    (id:GL_ZERO;name:'GL_ZERO'),
    (id:GL_ONE;name:'GL_ONE'),
    (id:GL_SRC_COLOR;name:'GL_SRC_COLOR'),
    (id:GL_ONE_MINUS_SRC_COLOR;name:'GL_ONE_MINUS_SRC_COLOR'),
    (id:GL_SRC_ALPHA;name:'GL_SRC_ALPHA'),
    (id:GL_ONE_MINUS_SRC_ALPHA;name:'GL_ONE_MINUS_SRC_ALPHA'),
    (id:GL_DST_ALPHA;name:'GL_DST_ALPHA'),
    (id:GL_ONE_MINUS_DST_ALPHA;name:'GL_ONE_MINUS_DST_ALPHA'),
    (id:GL_DST_COLOR;name:'GL_DST_COLOR'),
    (id:GL_ONE_MINUS_DST_COLOR;name:'GL_ONE_MINUS_DST_COLOR'),
    (id:GL_SRC_ALPHA_SATURATE;name:'GL_SRC_ALPHA_SATURATE'),
    (id:GL_BLEND_DST;name:'GL_BLEND_DST'),
    (id:GL_BLEND_SRC;name:'GL_BLEND_SRC'),
    (id:GL_BLEND;name:'GL_BLEND'),
    (id:GL_BLEND_COLOR;name:'GL_BLEND_COLOR'),
    (id:GL_CONSTANT_COLOR;name:'GL_CONSTANT_COLOR'),
    (id:GL_ONE_MINUS_CONSTANT_COLOR;name:'GL_ONE_MINUS_CONSTANT_COLOR'),
    (id:GL_CONSTANT_ALPHA;name:'GL_CONSTANT_ALPHA'),
    (id:GL_ONE_MINUS_CONSTANT_ALPHA;name:'GL_ONE_MINUS_CONSTANT_ALPHA'),
    (id:GL_FUNC_ADD;name:'GL_FUNC_ADD'),
    (id:GL_MIN;name:'GL_MIN'),
    (id:GL_MAX;name:'GL_MAX'),
    (id:GL_FUNC_SUBTRACT;name:'GL_FUNC_SUBTRACT'),
    (id:GL_FUNC_REVERSE_SUBTRACT;name:'GL_FUNC_REVERSE_SUBTRACT'),
    (id:GL_COLOR_TABLE;name:'GL_COLOR_TABLE'),
    (id:GL_POST_CONVOLUTION_COLOR_TABLE;name:'GL_POST_CONVOLUTION_COLOR_TABLE'),
    (id:GL_POST_COLOR_MATRIX_COLOR_TABLE;name:'GL_POST_COLOR_MATRIX_COLOR_TABLE'),
    (id:GL_PROXY_COLOR_TABLE;name:'GL_PROXY_COLOR_TABLE'),
    (id:GL_PROXY_POST_CONVOLUTION_COLOR_TABLE;name:'GL_PROXY_POST_CONVOLUTION_COLOR_TABLE'),
    (id:GL_PROXY_POST_COLOR_MATRIX_COLOR_TABLE;name:'GL_PROXY_POST_COLOR_MATRIX_COLOR_TABLE'),
    (id:GL_COLOR_TABLE_SCALE;name:'GL_COLOR_TABLE_SCALE'),
    (id:GL_COLOR_TABLE_BIAS;name:'GL_COLOR_TABLE_BIAS'),
    (id:GL_COLOR_TABLE_FORMAT;name:'GL_COLOR_TABLE_FORMAT'),
    (id:GL_COLOR_TABLE_WIDTH;name:'GL_COLOR_TABLE_WIDTH'),
    (id:GL_COLOR_TABLE_RED_SIZE;name:'GL_COLOR_TABLE_RED_SIZE'),
    (id:GL_COLOR_TABLE_GREEN_SIZE;name:'GL_COLOR_TABLE_GREEN_SIZE'),
    (id:GL_COLOR_TABLE_BLUE_SIZE;name:'GL_COLOR_TABLE_BLUE_SIZE'),
    (id:GL_COLOR_TABLE_ALPHA_SIZE;name:'GL_COLOR_TABLE_ALPHA_SIZE'),
    (id:GL_COLOR_TABLE_LUMINANCE_SIZE;name:'GL_COLOR_TABLE_LUMINANCE_SIZE'),
    (id:GL_COLOR_TABLE_INTENSITY_SIZE;name:'GL_COLOR_TABLE_INTENSITY_SIZE'),
    (id:GL_CONVOLUTION_1D;name:'GL_CONVOLUTION_1D'),
    (id:GL_CONVOLUTION_2D;name:'GL_CONVOLUTION_2D'),
    (id:GL_SEPARABLE_2D;name:'GL_SEPARABLE_2D'),
    (id:GL_CONVOLUTION_BORDER_MODE;name:'GL_CONVOLUTION_BORDER_MODE'),
    (id:GL_CONVOLUTION_FILTER_SCALE;name:'GL_CONVOLUTION_FILTER_SCALE'),
    (id:GL_CONVOLUTION_FILTER_BIAS;name:'GL_CONVOLUTION_FILTER_BIAS'),
    (id:GL_REDUCE;name:'GL_REDUCE'),
    (id:GL_CONVOLUTION_FORMAT;name:'GL_CONVOLUTION_FORMAT'),
    (id:GL_CONVOLUTION_WIDTH;name:'GL_CONVOLUTION_WIDTH'),
    (id:GL_CONVOLUTION_HEIGHT;name:'GL_CONVOLUTION_HEIGHT'),
    (id:GL_MAX_CONVOLUTION_WIDTH;name:'GL_MAX_CONVOLUTION_WIDTH'),
    (id:GL_MAX_CONVOLUTION_HEIGHT;name:'GL_MAX_CONVOLUTION_HEIGHT'),
    (id:GL_POST_CONVOLUTION_RED_SCALE;name:'GL_POST_CONVOLUTION_RED_SCALE'),
    (id:GL_POST_CONVOLUTION_GREEN_SCALE;name:'GL_POST_CONVOLUTION_GREEN_SCALE'),
    (id:GL_POST_CONVOLUTION_BLUE_SCALE;name:'GL_POST_CONVOLUTION_BLUE_SCALE'),
    (id:GL_POST_CONVOLUTION_ALPHA_SCALE;name:'GL_POST_CONVOLUTION_ALPHA_SCALE'),
    (id:GL_POST_CONVOLUTION_RED_BIAS;name:'GL_POST_CONVOLUTION_RED_BIAS'),
    (id:GL_POST_CONVOLUTION_GREEN_BIAS;name:'GL_POST_CONVOLUTION_GREEN_BIAS'),
    (id:GL_POST_CONVOLUTION_BLUE_BIAS;name:'GL_POST_CONVOLUTION_BLUE_BIAS'),
    (id:GL_POST_CONVOLUTION_ALPHA_BIAS;name:'GL_POST_CONVOLUTION_ALPHA_BIAS'),
    (id:GL_HISTOGRAM;name:'GL_HISTOGRAM'),
    (id:GL_PROXY_HISTOGRAM;name:'GL_PROXY_HISTOGRAM'),
    (id:GL_HISTOGRAM_WIDTH;name:'GL_HISTOGRAM_WIDTH'),
    (id:GL_HISTOGRAM_FORMAT;name:'GL_HISTOGRAM_FORMAT'),
    (id:GL_HISTOGRAM_RED_SIZE;name:'GL_HISTOGRAM_RED_SIZE'),
    (id:GL_HISTOGRAM_GREEN_SIZE;name:'GL_HISTOGRAM_GREEN_SIZE'),
    (id:GL_HISTOGRAM_BLUE_SIZE;name:'GL_HISTOGRAM_BLUE_SIZE'),
    (id:GL_HISTOGRAM_ALPHA_SIZE;name:'GL_HISTOGRAM_ALPHA_SIZE'),
    (id:GL_HISTOGRAM_LUMINANCE_SIZE;name:'GL_HISTOGRAM_LUMINANCE_SIZE'),
    (id:GL_HISTOGRAM_SINK;name:'GL_HISTOGRAM_SINK'),
    (id:GL_MINMAX;name:'GL_MINMAX'),
    (id:GL_MINMAX_FORMAT;name:'GL_MINMAX_FORMAT'),
    (id:GL_MINMAX_SINK;name:'GL_MINMAX_SINK'),
    (id:GL_NONE;name:'GL_NONE'),
    (id:GL_FRONT_LEFT;name:'GL_FRONT_LEFT'),
    (id:GL_FRONT_RIGHT;name:'GL_FRONT_RIGHT'),
    (id:GL_BACK_LEFT;name:'GL_BACK_LEFT'),
    (id:GL_BACK_RIGHT;name:'GL_BACK_RIGHT'),
    (id:GL_FRONT;name:'GL_FRONT'),
    (id:GL_BACK;name:'GL_BACK'),
    (id:GL_LEFT;name:'GL_LEFT'),
    (id:GL_RIGHT;name:'GL_RIGHT'),
    (id:GL_FRONT_AND_BACK;name:'GL_FRONT_AND_BACK'),
    (id:GL_AUX0;name:'GL_AUX0'),
    (id:GL_AUX1;name:'GL_AUX1'),
    (id:GL_AUX2;name:'GL_AUX2'),
    (id:GL_AUX3;name:'GL_AUX3'),
    (id:GL_AUX_BUFFERS;name:'GL_AUX_BUFFERS'),
    (id:GL_DRAW_BUFFER;name:'GL_DRAW_BUFFER'),
    (id:GL_READ_BUFFER;name:'GL_READ_BUFFER'),
    (id:GL_DOUBLEBUFFER;name:'GL_DOUBLEBUFFER'),
    (id:GL_STEREO;name:'GL_STEREO'),
    (id:GL_DEPTH_RANGE;name:'GL_DEPTH_RANGE'),
    (id:GL_DEPTH_TEST;name:'GL_DEPTH_TEST'),
    (id:GL_DEPTH_WRITEMASK;name:'GL_DEPTH_WRITEMASK'),
    (id:GL_DEPTH_CLEAR_VALUE;name:'GL_DEPTH_CLEAR_VALUE'),
    (id:GL_DEPTH_FUNC;name:'GL_DEPTH_FUNC'),
    (id:GL_NEVER;name:'GL_NEVER'),
    (id:GL_LESS;name:'GL_LESS'),
    (id:GL_EQUAL;name:'GL_EQUAL'),
    (id:GL_LEQUAL;name:'GL_LEQUAL'),
    (id:GL_GREATER;name:'GL_GREATER'),
    (id:GL_NOTEQUAL;name:'GL_NOTEQUAL'),
    (id:GL_GEQUAL;name:'GL_GEQUAL'),
    (id:GL_ALWAYS;name:'GL_ALWAYS'),
    (id:GL_ACCUM;name:'GL_ACCUM'),
    (id:GL_LOAD;name:'GL_LOAD'),
    (id:GL_RETURN;name:'GL_RETURN'),
    (id:GL_MULT;name:'GL_MULT'),
    (id:GL_ADD;name:'GL_ADD'),
    (id:GL_ACCUM_CLEAR_VALUE;name:'GL_ACCUM_CLEAR_VALUE'),
    (id:GL_FEEDBACK_BUFFER_POINTER;name:'GL_FEEDBACK_BUFFER_POINTER'),
    (id:GL_FEEDBACK_BUFFER_SIZE;name:'GL_FEEDBACK_BUFFER_SIZE'),
    (id:GL_FEEDBACK_BUFFER_TYPE;name:'GL_FEEDBACK_BUFFER_TYPE'),
    (id:GL_2D;name:'GL_2D'),
    (id:GL_3D;name:'GL_3D'),
    (id:GL_3D_COLOR;name:'GL_3D_COLOR'),
    (id:GL_3D_COLOR_TEXTURE;name:'GL_3D_COLOR_TEXTURE'),
    (id:GL_4D_COLOR_TEXTURE;name:'GL_4D_COLOR_TEXTURE'),
    (id:GL_PASS_THROUGH_TOKEN;name:'GL_PASS_THROUGH_TOKEN'),
    (id:GL_POINT_TOKEN;name:'GL_POINT_TOKEN'),
    (id:GL_LINE_TOKEN;name:'GL_LINE_TOKEN'),
    (id:GL_POLYGON_TOKEN;name:'GL_POLYGON_TOKEN'),
    (id:GL_BITMAP_TOKEN;name:'GL_BITMAP_TOKEN'),
    (id:GL_DRAW_PIXEL_TOKEN;name:'GL_DRAW_PIXEL_TOKEN'),
    (id:GL_COPY_PIXEL_TOKEN;name:'GL_COPY_PIXEL_TOKEN'),
    (id:GL_LINE_RESET_TOKEN;name:'GL_LINE_RESET_TOKEN'),
    (id:GL_EXP;name:'GL_EXP'),
    (id:GL_EXP2;name:'GL_EXP2'),
    (id:GL_FOG;name:'GL_FOG'),
    (id:GL_FOG_INDEX;name:'GL_FOG_INDEX'),
    (id:GL_FOG_DENSITY;name:'GL_FOG_DENSITY'),
    (id:GL_FOG_START;name:'GL_FOG_START'),
    (id:GL_FOG_END;name:'GL_FOG_END'),
    (id:GL_FOG_MODE;name:'GL_FOG_MODE'),
    (id:GL_FOG_COLOR;name:'GL_FOG_COLOR'),
    (id:GL_PIXEL_MAP_I_TO_I;name:'GL_PIXEL_MAP_I_TO_I'),
    (id:GL_PIXEL_MAP_S_TO_S;name:'GL_PIXEL_MAP_S_TO_S'),
    (id:GL_PIXEL_MAP_I_TO_R;name:'GL_PIXEL_MAP_I_TO_R'),
    (id:GL_PIXEL_MAP_I_TO_G;name:'GL_PIXEL_MAP_I_TO_G'),
    (id:GL_PIXEL_MAP_I_TO_B;name:'GL_PIXEL_MAP_I_TO_B'),
    (id:GL_PIXEL_MAP_I_TO_A;name:'GL_PIXEL_MAP_I_TO_A'),
    (id:GL_PIXEL_MAP_R_TO_R;name:'GL_PIXEL_MAP_R_TO_R'),
    (id:GL_PIXEL_MAP_G_TO_G;name:'GL_PIXEL_MAP_G_TO_G'),
    (id:GL_PIXEL_MAP_B_TO_B;name:'GL_PIXEL_MAP_B_TO_B'),
    (id:GL_PIXEL_MAP_A_TO_A;name:'GL_PIXEL_MAP_A_TO_A'),
    (id:GL_VERTEX_ARRAY_POINTER;name:'GL_VERTEX_ARRAY_POINTER'),
    (id:GL_NORMAL_ARRAY_POINTER;name:'GL_NORMAL_ARRAY_POINTER'),
    (id:GL_COLOR_ARRAY_POINTER;name:'GL_COLOR_ARRAY_POINTER'),
    (id:GL_INDEX_ARRAY_POINTER;name:'GL_INDEX_ARRAY_POINTER'),
    (id:GL_TEXTURE_COORD_ARRAY_POINTER;name:'GL_TEXTURE_COORD_ARRAY_POINTER'),
    (id:GL_EDGE_FLAG_ARRAY_POINTER;name:'GL_EDGE_FLAG_ARRAY_POINTER'),
    (id:GL_STENCIL_TEST;name:'GL_STENCIL_TEST'),
    (id:GL_STENCIL_CLEAR_VALUE;name:'GL_STENCIL_CLEAR_VALUE'),
    (id:GL_STENCIL_FUNC;name:'GL_STENCIL_FUNC'),
    (id:GL_STENCIL_VALUE_MASK;name:'GL_STENCIL_VALUE_MASK'),
    (id:GL_STENCIL_FAIL;name:'GL_STENCIL_FAIL'),
    (id:GL_STENCIL_PASS_DEPTH_FAIL;name:'GL_STENCIL_PASS_DEPTH_FAIL'),
    (id:GL_STENCIL_PASS_DEPTH_PASS;name:'GL_STENCIL_PASS_DEPTH_PASS'),
    (id:GL_STENCIL_REF;name:'GL_STENCIL_REF'),
    (id:GL_STENCIL_WRITEMASK;name:'GL_STENCIL_WRITEMASK'),
    (id:GL_KEEP;name:'GL_KEEP'),
    (id:GL_REPLACE;name:'GL_REPLACE'),
    (id:GL_INCR;name:'GL_INCR'),
    (id:GL_DECR;name:'GL_DECR'),
    (id:GL_COLOR_MATERIAL_FACE;name:'GL_COLOR_MATERIAL_FACE'),
    (id:GL_COLOR_MATERIAL_PARAMETER;name:'GL_COLOR_MATERIAL_PARAMETER'),
    (id:GL_COLOR_MATERIAL;name:'GL_COLOR_MATERIAL'),
    (id:GL_POINT_SMOOTH;name:'GL_POINT_SMOOTH'),
    (id:GL_POINT_SIZE;name:'GL_POINT_SIZE'),
    (id:GL_POINT_SIZE_RANGE;name:'GL_POINT_SIZE_RANGE'),
    (id:GL_POINT_SIZE_GRANULARITY;name:'GL_POINT_SIZE_GRANULARITY'),
    (id:GL_LINE_SMOOTH;name:'GL_LINE_SMOOTH'),
    (id:GL_LINE_WIDTH;name:'GL_LINE_WIDTH'),
    (id:GL_LINE_WIDTH_RANGE;name:'GL_LINE_WIDTH_RANGE'),
    (id:GL_LINE_WIDTH_GRANULARITY;name:'GL_LINE_WIDTH_GRANULARITY'),
    (id:GL_LINE_STIPPLE;name:'GL_LINE_STIPPLE'),
    (id:GL_LINE_STIPPLE_PATTERN;name:'GL_LINE_STIPPLE_PATTERN'),
    (id:GL_LINE_STIPPLE_REPEAT;name:'GL_LINE_STIPPLE_REPEAT'),
    (id:GL_POLYGON_MODE;name:'GL_POLYGON_MODE'),
    (id:GL_POLYGON_SMOOTH;name:'GL_POLYGON_SMOOTH'),
    (id:GL_POLYGON_STIPPLE;name:'GL_POLYGON_STIPPLE'),
    (id:GL_EDGE_FLAG;name:'GL_EDGE_FLAG'),
    (id:GL_CULL_FACE;name:'GL_CULL_FACE'),
    (id:GL_CULL_FACE_MODE;name:'GL_CULL_FACE_MODE'),
    (id:GL_FRONT_FACE;name:'GL_FRONT_FACE'),
    (id:GL_CW;name:'GL_CW'),
    (id:GL_CCW;name:'GL_CCW'),
    (id:GL_POINT;name:'GL_POINT'),
    (id:GL_LINE;name:'GL_LINE'),
    (id:GL_FILL;name:'GL_FILL'),
    (id:GL_LIST_MODE;name:'GL_LIST_MODE'),
    (id:GL_LIST_BASE;name:'GL_LIST_BASE'),
    (id:GL_LIST_INDEX;name:'GL_LIST_INDEX'),
    (id:GL_COMPILE;name:'GL_COMPILE'),
    (id:GL_COMPILE_AND_EXECUTE;name:'GL_COMPILE_AND_EXECUTE'),
    (id:GL_LIGHTING;name:'GL_LIGHTING'),
    (id:GL_LIGHT_MODEL_LOCAL_VIEWER;name:'GL_LIGHT_MODEL_LOCAL_VIEWER'),
    (id:GL_LIGHT_MODEL_TWO_SIDE;name:'GL_LIGHT_MODEL_TWO_SIDE'),
    (id:GL_LIGHT_MODEL_AMBIENT;name:'GL_LIGHT_MODEL_AMBIENT'),
    (id:GL_LIGHT_MODEL_COLOR_CONTROL;name:'GL_LIGHT_MODEL_COLOR_CONTROL'),
    (id:GL_SHADE_MODEL;name:'GL_SHADE_MODEL'),
    (id:GL_NORMALIZE;name:'GL_NORMALIZE'),
    (id:GL_AMBIENT;name:'GL_AMBIENT'),
    (id:GL_DIFFUSE;name:'GL_DIFFUSE'),
    (id:GL_SPECULAR;name:'GL_SPECULAR'),
    (id:GL_POSITION;name:'GL_POSITION'),
    (id:GL_SPOT_DIRECTION;name:'GL_SPOT_DIRECTION'),
    (id:GL_SPOT_EXPONENT;name:'GL_SPOT_EXPONENT'),
    (id:GL_SPOT_CUTOFF;name:'GL_SPOT_CUTOFF'),
    (id:GL_CONSTANT_ATTENUATION;name:'GL_CONSTANT_ATTENUATION'),
    (id:GL_LINEAR_ATTENUATION;name:'GL_LINEAR_ATTENUATION'),
    (id:GL_QUADRATIC_ATTENUATION;name:'GL_QUADRATIC_ATTENUATION'),
    (id:GL_EMISSION;name:'GL_EMISSION'),
    (id:GL_SHININESS;name:'GL_SHININESS'),
    (id:GL_AMBIENT_AND_DIFFUSE;name:'GL_AMBIENT_AND_DIFFUSE'),
    (id:GL_COLOR_INDEXES;name:'GL_COLOR_INDEXES'),
    (id:GL_FLAT;name:'GL_FLAT'),
    (id:GL_SMOOTH;name:'GL_SMOOTH'),
    (id:GL_LIGHT0;name:'GL_LIGHT0'),
    (id:GL_LIGHT1;name:'GL_LIGHT1'),
    (id:GL_LIGHT2;name:'GL_LIGHT2'),
    (id:GL_LIGHT3;name:'GL_LIGHT3'),
    (id:GL_LIGHT4;name:'GL_LIGHT4'),
    (id:GL_LIGHT5;name:'GL_LIGHT5'),
    (id:GL_LIGHT6;name:'GL_LIGHT6'),
    (id:GL_LIGHT7;name:'GL_LIGHT7'),
    (id:GL_MATRIX_MODE;name:'GL_MATRIX_MODE'),
    (id:GL_MODELVIEW;name:'GL_MODELVIEW'),
    (id:GL_PROJECTION;name:'GL_PROJECTION'),
    (id:GL_TEXTURE;name:'GL_TEXTURE'),
    (id:GL_CURRENT_COLOR;name:'GL_CURRENT_COLOR'),
    (id:GL_CURRENT_INDEX;name:'GL_CURRENT_INDEX'),
    (id:GL_CURRENT_NORMAL;name:'GL_CURRENT_NORMAL'),
    (id:GL_CURRENT_TEXTURE_COORDS;name:'GL_CURRENT_TEXTURE_COORDS'),
    (id:GL_CURRENT_RASTER_COLOR;name:'GL_CURRENT_RASTER_COLOR'),
    (id:GL_CURRENT_RASTER_INDEX;name:'GL_CURRENT_RASTER_INDEX'),
    (id:GL_CURRENT_RASTER_TEXTURE_COORDS;name:'GL_CURRENT_RASTER_TEXTURE_COORDS'),
    (id:GL_CURRENT_RASTER_POSITION;name:'GL_CURRENT_RASTER_POSITION'),
    (id:GL_CURRENT_RASTER_POSITION_VALID;name:'GL_CURRENT_RASTER_POSITION_VALID'),
    (id:GL_CURRENT_RASTER_DISTANCE;name:'GL_CURRENT_RASTER_DISTANCE'),
    (id:GL_MAX_LIST_NESTING;name:'GL_MAX_LIST_NESTING'),
    (id:GL_VIEWPORT;name:'GL_VIEWPORT'),
    (id:GL_MODELVIEW_STACK_DEPTH;name:'GL_MODELVIEW_STACK_DEPTH'),
    (id:GL_PROJECTION_STACK_DEPTH;name:'GL_PROJECTION_STACK_DEPTH'),
    (id:GL_TEXTURE_STACK_DEPTH;name:'GL_TEXTURE_STACK_DEPTH'),
    (id:GL_MODELVIEW_MATRIX;name:'GL_MODELVIEW_MATRIX'),
    (id:GL_PROJECTION_MATRIX;name:'GL_PROJECTION_MATRIX'),
    (id:GL_TEXTURE_MATRIX;name:'GL_TEXTURE_MATRIX'),
    (id:GL_ATTRIB_STACK_DEPTH;name:'GL_ATTRIB_STACK_DEPTH'),
    (id:GL_CLIENT_ATTRIB_STACK_DEPTH;name:'GL_CLIENT_ATTRIB_STACK_DEPTH'),
    (id:GL_SINGLE_COLOR;name:'GL_SINGLE_COLOR'),
    (id:GL_SEPARATE_SPECULAR_COLOR;name:'GL_SEPARATE_SPECULAR_COLOR'),
    (id:GL_ALPHA_TEST;name:'GL_ALPHA_TEST'),
    (id:GL_ALPHA_TEST_FUNC;name:'GL_ALPHA_TEST_FUNC'),
    (id:GL_ALPHA_TEST_REF;name:'GL_ALPHA_TEST_REF'),
    (id:GL_LOGIC_OP_MODE;name:'GL_LOGIC_OP_MODE'),
    (id:GL_INDEX_LOGIC_OP;name:'GL_INDEX_LOGIC_OP'),
    (id:GL_LOGIC_OP;name:'GL_LOGIC_OP'),
    (id:GL_COLOR_LOGIC_OP;name:'GL_COLOR_LOGIC_OP'),
    (id:GL_SCISSOR_BOX;name:'GL_SCISSOR_BOX'),
    (id:GL_SCISSOR_TEST;name:'GL_SCISSOR_TEST'),
    (id:GL_INDEX_CLEAR_VALUE;name:'GL_INDEX_CLEAR_VALUE'),
    (id:GL_INDEX_WRITEMASK;name:'GL_INDEX_WRITEMASK'),
    (id:GL_COLOR_CLEAR_VALUE;name:'GL_COLOR_CLEAR_VALUE'),
    (id:GL_COLOR_WRITEMASK;name:'GL_COLOR_WRITEMASK'),
    (id:GL_INDEX_MODE;name:'GL_INDEX_MODE'),
    (id:GL_RGBA_MODE;name:'GL_RGBA_MODE'),
    (id:GL_RENDER_MODE;name:'GL_RENDER_MODE'),
    (id:GL_PERSPECTIVE_CORRECTION_HINT;name:'GL_PERSPECTIVE_CORRECTION_HINT'),
    (id:GL_POINT_SMOOTH_HINT;name:'GL_POINT_SMOOTH_HINT'),
    (id:GL_LINE_SMOOTH_HINT;name:'GL_LINE_SMOOTH_HINT'),
    (id:GL_POLYGON_SMOOTH_HINT;name:'GL_POLYGON_SMOOTH_HINT'),
    (id:GL_FOG_HINT;name:'GL_FOG_HINT'),
    (id:GL_TEXTURE_GEN_S;name:'GL_TEXTURE_GEN_S'),
    (id:GL_TEXTURE_GEN_T;name:'GL_TEXTURE_GEN_T'),
    (id:GL_TEXTURE_GEN_R;name:'GL_TEXTURE_GEN_R'),
    (id:GL_TEXTURE_GEN_Q;name:'GL_TEXTURE_GEN_Q'),
    (id:GL_PIXEL_MAP_I_TO_I_SIZE;name:'GL_PIXEL_MAP_I_TO_I_SIZE'),
    (id:GL_PIXEL_MAP_S_TO_S_SIZE;name:'GL_PIXEL_MAP_S_TO_S_SIZE'),
    (id:GL_PIXEL_MAP_I_TO_R_SIZE;name:'GL_PIXEL_MAP_I_TO_R_SIZE'),
    (id:GL_PIXEL_MAP_I_TO_G_SIZE;name:'GL_PIXEL_MAP_I_TO_G_SIZE'),
    (id:GL_PIXEL_MAP_I_TO_B_SIZE;name:'GL_PIXEL_MAP_I_TO_B_SIZE'),
    (id:GL_PIXEL_MAP_I_TO_A_SIZE;name:'GL_PIXEL_MAP_I_TO_A_SIZE'),
    (id:GL_PIXEL_MAP_R_TO_R_SIZE;name:'GL_PIXEL_MAP_R_TO_R_SIZE'),
    (id:GL_PIXEL_MAP_G_TO_G_SIZE;name:'GL_PIXEL_MAP_G_TO_G_SIZE'),
    (id:GL_PIXEL_MAP_B_TO_B_SIZE;name:'GL_PIXEL_MAP_B_TO_B_SIZE'),
    (id:GL_PIXEL_MAP_A_TO_A_SIZE;name:'GL_PIXEL_MAP_A_TO_A_SIZE'),
    (id:GL_UNPACK_SWAP_BYTES;name:'GL_UNPACK_SWAP_BYTES'),
    (id:GL_UNPACK_LSB_FIRST;name:'GL_UNPACK_LSB_FIRST'),
    (id:GL_UNPACK_ROW_LENGTH;name:'GL_UNPACK_ROW_LENGTH'),
    (id:GL_UNPACK_SKIP_ROWS;name:'GL_UNPACK_SKIP_ROWS'),
    (id:GL_UNPACK_SKIP_PIXELS;name:'GL_UNPACK_SKIP_PIXELS'),
    (id:GL_UNPACK_ALIGNMENT;name:'GL_UNPACK_ALIGNMENT'),
    (id:GL_PACK_SWAP_BYTES;name:'GL_PACK_SWAP_BYTES'),
    (id:GL_PACK_LSB_FIRST;name:'GL_PACK_LSB_FIRST'),
    (id:GL_PACK_ROW_LENGTH;name:'GL_PACK_ROW_LENGTH'),
    (id:GL_PACK_SKIP_ROWS;name:'GL_PACK_SKIP_ROWS'),
    (id:GL_PACK_SKIP_PIXELS;name:'GL_PACK_SKIP_PIXELS'),
    (id:GL_PACK_ALIGNMENT;name:'GL_PACK_ALIGNMENT'),
    (id:GL_PACK_SKIP_IMAGES;name:'GL_PACK_SKIP_IMAGES'),
    (id:GL_PACK_IMAGE_HEIGHT;name:'GL_PACK_IMAGE_HEIGHT'),
    (id:GL_UNPACK_SKIP_IMAGES;name:'GL_UNPACK_SKIP_IMAGES'),
    (id:GL_UNPACK_IMAGE_HEIGHT;name:'GL_UNPACK_IMAGE_HEIGHT'),
    (id:GL_MAP_COLOR;name:'GL_MAP_COLOR'),
    (id:GL_MAP_STENCIL;name:'GL_MAP_STENCIL'),
    (id:GL_INDEX_SHIFT;name:'GL_INDEX_SHIFT'),
    (id:GL_INDEX_OFFSET;name:'GL_INDEX_OFFSET'),
    (id:GL_RED_SCALE;name:'GL_RED_SCALE'),
    (id:GL_RED_BIAS;name:'GL_RED_BIAS'),
    (id:GL_ZOOM_X;name:'GL_ZOOM_X'),
    (id:GL_ZOOM_Y;name:'GL_ZOOM_Y'),
    (id:GL_GREEN_SCALE;name:'GL_GREEN_SCALE'),
    (id:GL_GREEN_BIAS;name:'GL_GREEN_BIAS'),
    (id:GL_BLUE_SCALE;name:'GL_BLUE_SCALE'),
    (id:GL_BLUE_BIAS;name:'GL_BLUE_BIAS'),
    (id:GL_ALPHA_SCALE;name:'GL_ALPHA_SCALE'),
    (id:GL_ALPHA_BIAS;name:'GL_ALPHA_BIAS'),
    (id:GL_DEPTH_SCALE;name:'GL_DEPTH_SCALE'),
    (id:GL_DEPTH_BIAS;name:'GL_DEPTH_BIAS'),
    (id:GL_MAX_EVAL_ORDER;name:'GL_MAX_EVAL_ORDER'),
    (id:GL_MAX_LIGHTS;name:'GL_MAX_LIGHTS'),
    (id:GL_MAX_CLIP_PLANES;name:'GL_MAX_CLIP_PLANES'),
    (id:GL_MAX_TEXTURE_SIZE;name:'GL_MAX_TEXTURE_SIZE'),
    (id:GL_MAX_3D_TEXTURE_SIZE;name:'GL_MAX_3D_TEXTURE_SIZE'),
    (id:GL_MAX_PIXEL_MAP_TABLE;name:'GL_MAX_PIXEL_MAP_TABLE'),
    (id:GL_MAX_ATTRIB_STACK_DEPTH;name:'GL_MAX_ATTRIB_STACK_DEPTH'),
    (id:GL_MAX_MODELVIEW_STACK_DEPTH;name:'GL_MAX_MODELVIEW_STACK_DEPTH'),
    (id:GL_MAX_NAME_STACK_DEPTH;name:'GL_MAX_NAME_STACK_DEPTH'),
    (id:GL_MAX_PROJECTION_STACK_DEPTH;name:'GL_MAX_PROJECTION_STACK_DEPTH'),
    (id:GL_MAX_TEXTURE_STACK_DEPTH;name:'GL_MAX_TEXTURE_STACK_DEPTH'),
    (id:GL_MAX_VIEWPORT_DIMS;name:'GL_MAX_VIEWPORT_DIMS'),
    (id:GL_MAX_CLIENT_ATTRIB_STACK_DEPTH;name:'GL_MAX_CLIENT_ATTRIB_STACK_DEPTH'),
    (id:GL_MAX_ELEMENTS_VERTICES;name:'GL_MAX_ELEMENTS_VERTICES'),
    (id:GL_MAX_ELEMENTS_INDICES;name:'GL_MAX_ELEMENTS_INDICES'),
    (id:GL_RESCALE_NORMAL;name:'GL_RESCALE_NORMAL'),
    (id:GL_SUBPIXEL_BITS;name:'GL_SUBPIXEL_BITS'),
    (id:GL_INDEX_BITS;name:'GL_INDEX_BITS'),
    (id:GL_RED_BITS;name:'GL_RED_BITS'),
    (id:GL_GREEN_BITS;name:'GL_GREEN_BITS'),
    (id:GL_BLUE_BITS;name:'GL_BLUE_BITS'),
    (id:GL_ALPHA_BITS;name:'GL_ALPHA_BITS'),
    (id:GL_DEPTH_BITS;name:'GL_DEPTH_BITS'),
    (id:GL_STENCIL_BITS;name:'GL_STENCIL_BITS'),
    (id:GL_ACCUM_RED_BITS;name:'GL_ACCUM_RED_BITS'),
    (id:GL_ACCUM_GREEN_BITS;name:'GL_ACCUM_GREEN_BITS'),
    (id:GL_ACCUM_BLUE_BITS;name:'GL_ACCUM_BLUE_BITS'),
    (id:GL_ACCUM_ALPHA_BITS;name:'GL_ACCUM_ALPHA_BITS'),
    (id:GL_NAME_STACK_DEPTH;name:'GL_NAME_STACK_DEPTH'),
    (id:GL_AUTO_NORMAL;name:'GL_AUTO_NORMAL'),
    (id:GL_MAP1_COLOR_4;name:'GL_MAP1_COLOR_4'),
    (id:GL_MAP1_INDEX;name:'GL_MAP1_INDEX'),
    (id:GL_MAP1_NORMAL;name:'GL_MAP1_NORMAL'),
    (id:GL_MAP1_TEXTURE_COORD_1;name:'GL_MAP1_TEXTURE_COORD_1'),
    (id:GL_MAP1_TEXTURE_COORD_2;name:'GL_MAP1_TEXTURE_COORD_2'),
    (id:GL_MAP1_TEXTURE_COORD_3;name:'GL_MAP1_TEXTURE_COORD_3'),
    (id:GL_MAP1_TEXTURE_COORD_4;name:'GL_MAP1_TEXTURE_COORD_4'),
    (id:GL_MAP1_VERTEX_3;name:'GL_MAP1_VERTEX_3'),
    (id:GL_MAP1_VERTEX_4;name:'GL_MAP1_VERTEX_4'),
    (id:GL_MAP2_COLOR_4;name:'GL_MAP2_COLOR_4'),
    (id:GL_MAP2_INDEX;name:'GL_MAP2_INDEX'),
    (id:GL_MAP2_NORMAL;name:'GL_MAP2_NORMAL'),
    (id:GL_MAP2_TEXTURE_COORD_1;name:'GL_MAP2_TEXTURE_COORD_1'),
    (id:GL_MAP2_TEXTURE_COORD_2;name:'GL_MAP2_TEXTURE_COORD_2'),
    (id:GL_MAP2_TEXTURE_COORD_3;name:'GL_MAP2_TEXTURE_COORD_3'),
    (id:GL_MAP2_TEXTURE_COORD_4;name:'GL_MAP2_TEXTURE_COORD_4'),
    (id:GL_MAP2_VERTEX_3;name:'GL_MAP2_VERTEX_3'),
    (id:GL_MAP2_VERTEX_4;name:'GL_MAP2_VERTEX_4'),
    (id:GL_MAP1_GRID_DOMAIN;name:'GL_MAP1_GRID_DOMAIN'),
    (id:GL_MAP1_GRID_SEGMENTS;name:'GL_MAP1_GRID_SEGMENTS'),
    (id:GL_MAP2_GRID_DOMAIN;name:'GL_MAP2_GRID_DOMAIN'),
    (id:GL_MAP2_GRID_SEGMENTS;name:'GL_MAP2_GRID_SEGMENTS'),
    (id:GL_TEXTURE_1D;name:'GL_TEXTURE_1D'),
    (id:GL_TEXTURE_2D;name:'GL_TEXTURE_2D'),
    (id:GL_TEXTURE_3D;name:'GL_TEXTURE_3D'),
    (id:GL_SELECTION_BUFFER_POINTER;name:'GL_SELECTION_BUFFER_POINTER'),
    (id:GL_SELECTION_BUFFER_SIZE;name:'GL_SELECTION_BUFFER_SIZE'),
    (id:GL_POLYGON_OFFSET_UNITS;name:'GL_POLYGON_OFFSET_UNITS'),
    (id:GL_POLYGON_OFFSET_POINT;name:'GL_POLYGON_OFFSET_POINT'),
    (id:GL_POLYGON_OFFSET_LINE;name:'GL_POLYGON_OFFSET_LINE'),
    (id:GL_POLYGON_OFFSET_FILL;name:'GL_POLYGON_OFFSET_FILL'),
    (id:GL_POLYGON_OFFSET_FACTOR;name:'GL_POLYGON_OFFSET_FACTOR'),
    (id:GL_TEXTURE_BINDING_1D;name:'GL_TEXTURE_BINDING_1D'),
    (id:GL_TEXTURE_BINDING_2D;name:'GL_TEXTURE_BINDING_2D'),
    (id:GL_VERTEX_ARRAY;name:'GL_VERTEX_ARRAY'),
    (id:GL_NORMAL_ARRAY;name:'GL_NORMAL_ARRAY'),
    (id:GL_COLOR_ARRAY;name:'GL_COLOR_ARRAY'),
    (id:GL_INDEX_ARRAY;name:'GL_INDEX_ARRAY'),
    (id:GL_TEXTURE_COORD_ARRAY;name:'GL_TEXTURE_COORD_ARRAY'),
    (id:GL_EDGE_FLAG_ARRAY;name:'GL_EDGE_FLAG_ARRAY'),
    (id:GL_VERTEX_ARRAY_SIZE;name:'GL_VERTEX_ARRAY_SIZE'),
    (id:GL_VERTEX_ARRAY_TYPE;name:'GL_VERTEX_ARRAY_TYPE'),
    (id:GL_VERTEX_ARRAY_STRIDE;name:'GL_VERTEX_ARRAY_STRIDE'),
    (id:GL_NORMAL_ARRAY_TYPE;name:'GL_NORMAL_ARRAY_TYPE'),
    (id:GL_NORMAL_ARRAY_STRIDE;name:'GL_NORMAL_ARRAY_STRIDE'),
    (id:GL_COLOR_ARRAY_SIZE;name:'GL_COLOR_ARRAY_SIZE'),
    (id:GL_COLOR_ARRAY_TYPE;name:'GL_COLOR_ARRAY_TYPE'),
    (id:GL_COLOR_ARRAY_STRIDE;name:'GL_COLOR_ARRAY_STRIDE'),
    (id:GL_INDEX_ARRAY_TYPE;name:'GL_INDEX_ARRAY_TYPE'),
    (id:GL_INDEX_ARRAY_STRIDE;name:'GL_INDEX_ARRAY_STRIDE'),
    (id:GL_TEXTURE_COORD_ARRAY_SIZE;name:'GL_TEXTURE_COORD_ARRAY_SIZE'),
    (id:GL_TEXTURE_COORD_ARRAY_TYPE;name:'GL_TEXTURE_COORD_ARRAY_TYPE'),
    (id:GL_TEXTURE_COORD_ARRAY_STRIDE;name:'GL_TEXTURE_COORD_ARRAY_STRIDE'),
    (id:GL_EDGE_FLAG_ARRAY_STRIDE;name:'GL_EDGE_FLAG_ARRAY_STRIDE'),
    (id:GL_COLOR_MATRIX;name:'GL_COLOR_MATRIX'),
    (id:GL_COLOR_MATRIX_STACK_DEPTH;name:'GL_COLOR_MATRIX_STACK_DEPTH'),
    (id:GL_MAX_COLOR_MATRIX_STACK_DEPTH;name:'GL_MAX_COLOR_MATRIX_STACK_DEPTH'),
    (id:GL_POST_COLOR_MATRIX_RED_SCALE;name:'GL_POST_COLOR_MATRIX_RED_SCALE'),
    (id:GL_POST_COLOR_MATRIX_GREEN_SCALE;name:'GL_POST_COLOR_MATRIX_GREEN_SCALE'),
    (id:GL_POST_COLOR_MATRIX_BLUE_SCALE;name:'GL_POST_COLOR_MATRIX_BLUE_SCALE'),
    (id:GL_POST_COLOR_MATRIX_ALPHA_SCALE;name:'GL_POST_COLOR_MATRIX_ALPHA_SCALE'),
    (id:GL_POST_COLOR_MATRIX_RED_BIAS;name:'GL_POST_COLOR_MATRIX_RED_BIAS'),
    (id:GL_POST_COLOR_MATRIX_GREEN_BIAS;name:'GL_POST_COLOR_MATRIX_GREEN_BIAS'),
    (id:GL_POST_COLOR_MATRIX_BLUE_BIAS;name:'GL_POST_COLOR_MATRIX_BLUE_BIAS'),
    (id:GL_POST_COLOR_MATRIX_ALPHA_BIAS;name:'GL_POST_COLOR_MATRIX_ALPHA_BIAS'),
    (id:GL_COEFF;name:'GL_COEFF'),
    (id:GL_ORDER;name:'GL_ORDER'),
    (id:GL_DOMAIN;name:'GL_DOMAIN'),
    (id:GL_TEXTURE_WIDTH;name:'GL_TEXTURE_WIDTH'),
    (id:GL_TEXTURE_HEIGHT;name:'GL_TEXTURE_HEIGHT'),
    (id:GL_TEXTURE_INTERNAL_FORMAT;name:'GL_TEXTURE_INTERNAL_FORMAT'),
    (id:GL_TEXTURE_COMPONENTS;name:'GL_TEXTURE_COMPONENTS'),
    (id:GL_TEXTURE_BORDER_COLOR;name:'GL_TEXTURE_BORDER_COLOR'),
    (id:GL_TEXTURE_BORDER;name:'GL_TEXTURE_BORDER'),
    (id:GL_TEXTURE_RED_SIZE;name:'GL_TEXTURE_RED_SIZE'),
    (id:GL_TEXTURE_GREEN_SIZE;name:'GL_TEXTURE_GREEN_SIZE'),
    (id:GL_TEXTURE_BLUE_SIZE;name:'GL_TEXTURE_BLUE_SIZE'),
    (id:GL_TEXTURE_ALPHA_SIZE;name:'GL_TEXTURE_ALPHA_SIZE'),
    (id:GL_TEXTURE_LUMINANCE_SIZE;name:'GL_TEXTURE_LUMINANCE_SIZE'),
    (id:GL_TEXTURE_INTENSITY_SIZE;name:'GL_TEXTURE_INTENSITY_SIZE'),
    (id:GL_TEXTURE_PRIORITY;name:'GL_TEXTURE_PRIORITY'),
    (id:GL_TEXTURE_RESIDENT;name:'GL_TEXTURE_RESIDENT'),
    (id:GL_BGR;name:'GL_BGR'),
    (id:GL_BGRA;name:'GL_BGRA'),
    (id:GL_S;name:'GL_S'),
    (id:GL_T;name:'GL_T'),
    (id:GL_R;name:'GL_R'),
    (id:GL_Q;name:'GL_Q'),
    (id:GL_MODULATE;name:'GL_MODULATE'),
    (id:GL_DECAL;name:'GL_DECAL'),
    (id:GL_TEXTURE_ENV_MODE;name:'GL_TEXTURE_ENV_MODE'),
    (id:GL_TEXTURE_ENV_COLOR;name:'GL_TEXTURE_ENV_COLOR'),
    (id:GL_TEXTURE_ENV;name:'GL_TEXTURE_ENV'),
    (id:GL_EYE_LINEAR;name:'GL_EYE_LINEAR'),
    (id:GL_OBJECT_LINEAR;name:'GL_OBJECT_LINEAR'),
    (id:GL_SPHERE_MAP;name:'GL_SPHERE_MAP'),
    (id:GL_TEXTURE_GEN_MODE;name:'GL_TEXTURE_GEN_MODE'),
    (id:GL_OBJECT_PLANE;name:'GL_OBJECT_PLANE'),
    (id:GL_EYE_PLANE;name:'GL_EYE_PLANE'),
    (id:GL_NEAREST;name:'GL_NEAREST'),
    (id:GL_LINEAR;name:'GL_LINEAR'),
    (id:GL_NEAREST_MIPMAP_NEAREST;name:'GL_NEAREST_MIPMAP_NEAREST'),
    (id:GL_LINEAR_MIPMAP_NEAREST;name:'GL_LINEAR_MIPMAP_NEAREST'),
    (id:GL_NEAREST_MIPMAP_LINEAR;name:'GL_NEAREST_MIPMAP_LINEAR'),
    (id:GL_LINEAR_MIPMAP_LINEAR;name:'GL_LINEAR_MIPMAP_LINEAR'),
    (id:GL_TEXTURE_MAG_FILTER;name:'GL_TEXTURE_MAG_FILTER'),
    (id:GL_TEXTURE_MIN_FILTER;name:'GL_TEXTURE_MIN_FILTER'),
    (id:GL_TEXTURE_WRAP_R;name:'GL_TEXTURE_WRAP_R'),
    (id:GL_TEXTURE_WRAP_S;name:'GL_TEXTURE_WRAP_S'),
    (id:GL_TEXTURE_WRAP_T;name:'GL_TEXTURE_WRAP_T'),
    (id:GL_CLAMP_TO_EDGE;name:'GL_CLAMP_TO_EDGE'),
    (id:GL_TEXTURE_MIN_LOD;name:'GL_TEXTURE_MIN_LOD'),
    (id:GL_TEXTURE_MAX_LOD;name:'GL_TEXTURE_MAX_LOD'),
    (id:GL_TEXTURE_BASE_LEVEL;name:'GL_TEXTURE_BASE_LEVEL'),
    (id:GL_TEXTURE_MAX_LEVEL;name:'GL_TEXTURE_MAX_LEVEL'),
    (id:GL_TEXTURE_DEPTH;name:'GL_TEXTURE_DEPTH'),
    (id:GL_PROXY_TEXTURE_1D;name:'GL_PROXY_TEXTURE_1D'),
    (id:GL_PROXY_TEXTURE_2D;name:'GL_PROXY_TEXTURE_2D'),
    (id:GL_PROXY_TEXTURE_3D;name:'GL_PROXY_TEXTURE_3D'),
    (id:GL_CLAMP;name:'GL_CLAMP'),
    (id:GL_REPEAT;name:'GL_REPEAT'),
    (id:GL_DONT_CARE;name:'GL_DONT_CARE'),
    (id:GL_FASTEST;name:'GL_FASTEST'),
    (id:GL_NICEST;name:'GL_NICEST'),
    (id:GL_BYTE;name:'GL_BYTE'),
    (id:GL_UNSIGNED_BYTE;name:'GL_UNSIGNED_BYTE'),
    (id:GL_SHORT;name:'GL_SHORT'),
    (id:GL_UNSIGNED_SHORT;name:'GL_UNSIGNED_SHORT'),
    (id:GL_INT;name:'GL_INT'),
    (id:GL_UNSIGNED_INT;name:'GL_UNSIGNED_INT'),
    (id:GL_FLOAT;name:'GL_FLOAT'),
    (id:GL_2_BYTES;name:'GL_2_BYTES'),
    (id:GL_3_BYTES;name:'GL_3_BYTES'),
    (id:GL_4_BYTES;name:'GL_4_BYTES'),
    (id:GL_DOUBLE;name:'GL_DOUBLE'),
    (id:GL_DOUBLE_EXT;name:'GL_DOUBLE_EXT'),
    (id:GL_CLEAR;name:'GL_CLEAR'),
    (id:GL_AND;name:'GL_AND'),
    (id:GL_AND_REVERSE;name:'GL_AND_REVERSE'),
    (id:GL_COPY;name:'GL_COPY'),
    (id:GL_AND_INVERTED;name:'GL_AND_INVERTED'),
    (id:GL_NOOP;name:'GL_NOOP'),
    (id:GL_XOR;name:'GL_XOR'),
    (id:GL_OR;name:'GL_OR'),
    (id:GL_NOR;name:'GL_NOR'),
    (id:GL_EQUIV;name:'GL_EQUIV'),
    (id:GL_INVERT;name:'GL_INVERT'),
    (id:GL_OR_REVERSE;name:'GL_OR_REVERSE'),
    (id:GL_COPY_INVERTED;name:'GL_COPY_INVERTED'),
    (id:GL_OR_INVERTED;name:'GL_OR_INVERTED'),
    (id:GL_NAND;name:'GL_NAND'),
    (id:GL_SET;name:'GL_SET'),
    (id:GL_COLOR;name:'GL_COLOR'),
    (id:GL_DEPTH;name:'GL_DEPTH'),
    (id:GL_STENCIL;name:'GL_STENCIL'),
    (id:GL_COLOR_INDEX;name:'GL_COLOR_INDEX'),
    (id:GL_STENCIL_INDEX;name:'GL_STENCIL_INDEX'),
    (id:GL_DEPTH_COMPONENT;name:'GL_DEPTH_COMPONENT'),
    (id:GL_RED;name:'GL_RED'),
    (id:GL_GREEN;name:'GL_GREEN'),
    (id:GL_BLUE;name:'GL_BLUE'),
    (id:GL_ALPHA;name:'GL_ALPHA'),
    (id:GL_RGB;name:'GL_RGB'),
    (id:GL_RGBA;name:'GL_RGBA'),
    (id:GL_LUMINANCE;name:'GL_LUMINANCE'),
    (id:GL_LUMINANCE_ALPHA;name:'GL_LUMINANCE_ALPHA'),
    (id:GL_BITMAP;name:'GL_BITMAP'),
    (id:GL_RENDER;name:'GL_RENDER'),
    (id:GL_FEEDBACK;name:'GL_FEEDBACK'),
    (id:GL_SELECT;name:'GL_SELECT'),
    (id:GL_VENDOR;name:'GL_VENDOR'),
    (id:GL_RENDERER;name:'GL_RENDERER'),
    (id:GL_VERSION;name:'GL_VERSION'),
    (id:GL_EXTENSIONS;name:'GL_EXTENSIONS'),
    (id:GL_R3_G3_B2;name:'GL_R3_G3_B2'),
    (id:GL_ALPHA4;name:'GL_ALPHA4'),
    (id:GL_ALPHA8;name:'GL_ALPHA8'),
    (id:GL_ALPHA12;name:'GL_ALPHA12'),
    (id:GL_ALPHA16;name:'GL_ALPHA16'),
    (id:GL_LUMINANCE4;name:'GL_LUMINANCE4'),
    (id:GL_LUMINANCE8;name:'GL_LUMINANCE8'),
    (id:GL_LUMINANCE12;name:'GL_LUMINANCE12'),
    (id:GL_LUMINANCE16;name:'GL_LUMINANCE16'),
    (id:GL_LUMINANCE4_ALPHA4;name:'GL_LUMINANCE4_ALPHA4'),
    (id:GL_LUMINANCE6_ALPHA2;name:'GL_LUMINANCE6_ALPHA2'),
    (id:GL_LUMINANCE8_ALPHA8;name:'GL_LUMINANCE8_ALPHA8'),
    (id:GL_LUMINANCE12_ALPHA4;name:'GL_LUMINANCE12_ALPHA4'),
    (id:GL_LUMINANCE12_ALPHA12;name:'GL_LUMINANCE12_ALPHA12'),
    (id:GL_LUMINANCE16_ALPHA16;name:'GL_LUMINANCE16_ALPHA16'),
    (id:GL_INTENSITY;name:'GL_INTENSITY'),
    (id:GL_INTENSITY4;name:'GL_INTENSITY4'),
    (id:GL_INTENSITY8;name:'GL_INTENSITY8'),
    (id:GL_INTENSITY12;name:'GL_INTENSITY12'),
    (id:GL_INTENSITY16;name:'GL_INTENSITY16'),
    (id:GL_RGB4;name:'GL_RGB4'),
    (id:GL_RGB5;name:'GL_RGB5'),
    (id:GL_RGB8;name:'GL_RGB8'),
    (id:GL_RGB10;name:'GL_RGB10'),
    (id:GL_RGB12;name:'GL_RGB12'),
    (id:GL_RGB16;name:'GL_RGB16'),
    (id:GL_RGBA2;name:'GL_RGBA2'),
    (id:GL_RGBA4;name:'GL_RGBA4'),
    (id:GL_RGB5_A1;name:'GL_RGB5_A1'),
    (id:GL_RGBA8;name:'GL_RGBA8'),
    (id:GL_RGB10_A2;name:'GL_RGB10_A2'),
    (id:GL_RGBA12;name:'GL_RGBA12'),
    (id:GL_RGBA16;name:'GL_RGBA16'),
    (id:UNSIGNED_BYTE_3_3_2;name:'UNSIGNED_BYTE_3_3_2'),
    (id:UNSIGNED_BYTE_2_3_3_REV;name:'UNSIGNED_BYTE_2_3_3_REV'),
    (id:UNSIGNED_SHORT_5_6_5;name:'UNSIGNED_SHORT_5_6_5'),
    (id:UNSIGNED_SHORT_5_6_5_REV;name:'UNSIGNED_SHORT_5_6_5_REV'),
    (id:UNSIGNED_SHORT_4_4_4_4;name:'UNSIGNED_SHORT_4_4_4_4'),
    (id:UNSIGNED_SHORT_4_4_4_4_REV;name:'UNSIGNED_SHORT_4_4_4_4_REV'),
    (id:UNSIGNED_SHORT_5_5_5_1;name:'UNSIGNED_SHORT_5_5_5_1'),
    (id:UNSIGNED_SHORT_1_5_5_5_REV;name:'UNSIGNED_SHORT_1_5_5_5_REV'),
    (id:UNSIGNED_INT_8_8_8_8;name:'UNSIGNED_INT_8_8_8_8'),
    (id:UNSIGNED_INT_8_8_8_8_REV;name:'UNSIGNED_INT_8_8_8_8_REV'),
    (id:UNSIGNED_INT_10_10_10_2;name:'UNSIGNED_INT_10_10_10_2'),
    (id:UNSIGNED_INT_2_10_10_10_REV;name:'UNSIGNED_INT_2_10_10_10_REV'),
    (id:GL_V2F;name:'GL_V2F'),
    (id:GL_V3F;name:'GL_V3F'),
    (id:GL_C4UB_V2F;name:'GL_C4UB_V2F'),
    (id:GL_C4UB_V3F;name:'GL_C4UB_V3F'),
    (id:GL_C3F_V3F;name:'GL_C3F_V3F'),
    (id:GL_N3F_V3F;name:'GL_N3F_V3F'),
    (id:GL_C4F_N3F_V3F;name:'GL_C4F_N3F_V3F'),
    (id:GL_T2F_V3F;name:'GL_T2F_V3F'),
    (id:GL_T4F_V4F;name:'GL_T4F_V4F'),
    (id:GL_T2F_C4UB_V3F;name:'GL_T2F_C4UB_V3F'),
    (id:GL_T2F_C3F_V3F;name:'GL_T2F_C3F_V3F'),
    (id:GL_T2F_N3F_V3F;name:'GL_T2F_N3F_V3F'),
    (id:GL_T2F_C4F_N3F_V3F;name:'GL_T2F_C4F_N3F_V3F'),
    (id:GL_T4F_C4F_N3F_V4F;name:'GL_T4F_C4F_N3F_V4F'),
    (id:GL_CLIP_PLANE0;name:'GL_CLIP_PLANE0'),
    (id:GL_CLIP_PLANE1;name:'GL_CLIP_PLANE1'),
    (id:GL_CLIP_PLANE2;name:'GL_CLIP_PLANE2'),
    (id:GL_CLIP_PLANE3;name:'GL_CLIP_PLANE3'),
    (id:GL_CLIP_PLANE4;name:'GL_CLIP_PLANE4'),
    (id:GL_CLIP_PLANE5;name:'GL_CLIP_PLANE5'),
    (id:GL_DITHER;name:'GL_DITHER'),
    (id:GL_ABGR_EXT;name:'GL_ABGR_EXT'),
    (id:GL_UNSIGNED_BYTE_3_3_2_EXT;name:'GL_UNSIGNED_BYTE_3_3_2_EXT'),
    (id:GL_UNSIGNED_SHORT_4_4_4_4_EXT;name:'GL_UNSIGNED_SHORT_4_4_4_4_EXT'),
    (id:GL_UNSIGNED_SHORT_5_5_5_1_EXT;name:'GL_UNSIGNED_SHORT_5_5_5_1_EXT'),
    (id:GL_UNSIGNED_INT_8_8_8_8_EXT;name:'GL_UNSIGNED_INT_8_8_8_8_EXT'),
    (id:GL_UNSIGNED_INT_10_10_10_2_EXT;name:'GL_UNSIGNED_INT_10_10_10_2_EXT'),
    (id:GL_BGR_EXT;name:'GL_BGR_EXT'),
    (id:GL_BGRA_EXT;name:'GL_BGRA_EXT'),
    (id:GL_COLOR_INDEX1_EXT;name:'GL_COLOR_INDEX1_EXT'),
    (id:GL_COLOR_INDEX2_EXT;name:'GL_COLOR_INDEX2_EXT'),
    (id:GL_COLOR_INDEX4_EXT;name:'GL_COLOR_INDEX4_EXT'),
    (id:GL_COLOR_INDEX8_EXT;name:'GL_COLOR_INDEX8_EXT'),
    (id:GL_COLOR_INDEX12_EXT;name:'GL_COLOR_INDEX12_EXT'),
    (id:GL_COLOR_INDEX16_EXT;name:'GL_COLOR_INDEX16_EXT'),
    (id:GL_CONSTANT_COLOR_EXT;name:'GL_CONSTANT_COLOR_EXT'),
    (id:GL_ONE_MINUS_CONSTANT_COLOR_EXT;name:'GL_ONE_MINUS_CONSTANT_COLOR_EXT'),
    (id:GL_CONSTANT_ALPHA_EXT;name:'GL_CONSTANT_ALPHA_EXT'),
    (id:GL_ONE_MINUS_CONSTANT_ALPHA_EXT;name:'GL_ONE_MINUS_CONSTANT_ALPHA_EXT'),
    (id:GL_BLEND_COLOR_EXT;name:'GL_BLEND_COLOR_EXT'),
    (id:GL_FUNC_ADD_EXT;name:'GL_FUNC_ADD_EXT'),
    (id:GL_MIN_EXT;name:'GL_MIN_EXT'),
    (id:GL_MAX_EXT;name:'GL_MAX_EXT'),
    (id:GL_BLEND_EQUATION_EXT;name:'GL_BLEND_EQUATION_EXT'),
    (id:GL_FUNC_SUBTRACT_EXT;name:'GL_FUNC_SUBTRACT_EXT'),
    (id:GL_FUNC_REVERSE_SUBTRACT_EXT;name:'GL_FUNC_REVERSE_SUBTRACT_EXT'),
    (id:GL_CONVOLUTION_1D_EXT;name:'GL_CONVOLUTION_1D_EXT'),
    (id:GL_CONVOLUTION_2D_EXT;name:'GL_CONVOLUTION_2D_EXT'),
    (id:GL_SEPARABLE_2D_EXT;name:'GL_SEPARABLE_2D_EXT'),
    (id:GL_CONVOLUTION_BORDER_MODE_EXT;name:'GL_CONVOLUTION_BORDER_MODE_EXT'),
    (id:GL_CONVOLUTION_FILTER_SCALE_EXT;name:'GL_CONVOLUTION_FILTER_SCALE_EXT'),
    (id:GL_CONVOLUTION_FILTER_BIAS_EXT;name:'GL_CONVOLUTION_FILTER_BIAS_EXT'),
    (id:GL_REDUCE_EXT;name:'GL_REDUCE_EXT'),
    (id:GL_CONVOLUTION_FORMAT_EXT;name:'GL_CONVOLUTION_FORMAT_EXT'),
    (id:GL_CONVOLUTION_WIDTH_EXT;name:'GL_CONVOLUTION_WIDTH_EXT'),
    (id:GL_CONVOLUTION_HEIGHT_EXT;name:'GL_CONVOLUTION_HEIGHT_EXT'),
    (id:GL_MAX_CONVOLUTION_WIDTH_EXT;name:'GL_MAX_CONVOLUTION_WIDTH_EXT'),
    (id:GL_MAX_CONVOLUTION_HEIGHT_EXT;name:'GL_MAX_CONVOLUTION_HEIGHT_EXT'),
    (id:GL_POST_CONVOLUTION_RED_SCALE_EXT;name:'GL_POST_CONVOLUTION_RED_SCALE_EXT'),
    (id:GL_POST_CONVOLUTION_GREEN_SCALE_EXT;name:'GL_POST_CONVOLUTION_GREEN_SCALE_EXT'),
    (id:GL_POST_CONVOLUTION_BLUE_SCALE_EXT;name:'GL_POST_CONVOLUTION_BLUE_SCALE_EXT'),
    (id:GL_POST_CONVOLUTION_ALPHA_SCALE_EXT;name:'GL_POST_CONVOLUTION_ALPHA_SCALE_EXT'),
    (id:GL_POST_CONVOLUTION_RED_BIAS_EXT;name:'GL_POST_CONVOLUTION_RED_BIAS_EXT'),
    (id:GL_POST_CONVOLUTION_GREEN_BIAS_EXT;name:'GL_POST_CONVOLUTION_GREEN_BIAS_EXT'),
    (id:GL_POST_CONVOLUTION_BLUE_BIAS_EXT;name:'GL_POST_CONVOLUTION_BLUE_BIAS_EXT'),
    (id:GL_POST_CONVOLUTION_ALPHA_BIAS_EXT;name:'GL_POST_CONVOLUTION_ALPHA_BIAS_EXT'),
    (id:GL_HISTOGRAM_EXT;name:'GL_HISTOGRAM_EXT'),
    (id:GL_PROXY_HISTOGRAM_EXT;name:'GL_PROXY_HISTOGRAM_EXT'),
    (id:GL_HISTOGRAM_WIDTH_EXT;name:'GL_HISTOGRAM_WIDTH_EXT'),
    (id:GL_HISTOGRAM_FORMAT_EXT;name:'GL_HISTOGRAM_FORMAT_EXT'),
    (id:GL_HISTOGRAM_RED_SIZE_EXT;name:'GL_HISTOGRAM_RED_SIZE_EXT'),
    (id:GL_HISTOGRAM_GREEN_SIZE_EXT;name:'GL_HISTOGRAM_GREEN_SIZE_EXT'),
    (id:GL_HISTOGRAM_BLUE_SIZE_EXT;name:'GL_HISTOGRAM_BLUE_SIZE_EXT'),
    (id:GL_HISTOGRAM_ALPHA_SIZE_EXT;name:'GL_HISTOGRAM_ALPHA_SIZE_EXT'),
    (id:GL_HISTOGRAM_LUMINANCE_SIZE_EXT;name:'GL_HISTOGRAM_LUMINANCE_SIZE_EXT'),
    (id:GL_HISTOGRAM_SINK_EXT;name:'GL_HISTOGRAM_SINK_EXT'),
    (id:GL_MINMAX_EXT;name:'GL_MINMAX_EXT'),
    (id:GL_MINMAX_FORMAT_EXT;name:'GL_MINMAX_FORMAT_EXT'),
    (id:GL_MINMAX_SINK_EXT;name:'GL_MINMAX_SINK_EXT'),
    (id:GL_POLYGON_OFFSET_EXT;name:'GL_POLYGON_OFFSET_EXT'),
    (id:GL_POLYGON_OFFSET_FACTOR_EXT;name:'GL_POLYGON_OFFSET_FACTOR_EXT'),
    (id:GL_POLYGON_OFFSET_BIAS_EXT;name:'GL_POLYGON_OFFSET_BIAS_EXT'),
    (id:GL_ALPHA4_EXT;name:'GL_ALPHA4_EXT'),
    (id:GL_ALPHA8_EXT;name:'GL_ALPHA8_EXT'),
    (id:GL_ALPHA12_EXT;name:'GL_ALPHA12_EXT'),
    (id:GL_ALPHA16_EXT;name:'GL_ALPHA16_EXT'),
    (id:GL_LUMINANCE4_EXT;name:'GL_LUMINANCE4_EXT'),
    (id:GL_LUMINANCE8_EXT;name:'GL_LUMINANCE8_EXT'),
    (id:GL_LUMINANCE12_EXT;name:'GL_LUMINANCE12_EXT'),
    (id:GL_LUMINANCE16_EXT;name:'GL_LUMINANCE16_EXT'),
    (id:GL_LUMINANCE4_ALPHA4_EXT;name:'GL_LUMINANCE4_ALPHA4_EXT'),
    (id:GL_LUMINANCE6_ALPHA2_EXT;name:'GL_LUMINANCE6_ALPHA2_EXT'),
    (id:GL_LUMINANCE8_ALPHA8_EXT;name:'GL_LUMINANCE8_ALPHA8_EXT'),
    (id:GL_LUMINANCE12_ALPHA4_EXT;name:'GL_LUMINANCE12_ALPHA4_EXT'),
    (id:GL_LUMINANCE12_ALPHA12_EXT;name:'GL_LUMINANCE12_ALPHA12_EXT'),
    (id:GL_LUMINANCE16_ALPHA16_EXT;name:'GL_LUMINANCE16_ALPHA16_EXT'),
    (id:GL_INTENSITY_EXT;name:'GL_INTENSITY_EXT'),
    (id:GL_INTENSITY4_EXT;name:'GL_INTENSITY4_EXT'),
    (id:GL_INTENSITY8_EXT;name:'GL_INTENSITY8_EXT'),
    (id:GL_INTENSITY12_EXT;name:'GL_INTENSITY12_EXT'),
    (id:GL_INTENSITY16_EXT;name:'GL_INTENSITY16_EXT'),
    (id:GL_RGB2_EXT;name:'GL_RGB2_EXT'),
    (id:GL_RGB4_EXT;name:'GL_RGB4_EXT'),
    (id:GL_RGB5_EXT;name:'GL_RGB5_EXT'),
    (id:GL_RGB8_EXT;name:'GL_RGB8_EXT'),
    (id:GL_RGB10_EXT;name:'GL_RGB10_EXT'),
    (id:GL_RGB12_EXT;name:'GL_RGB12_EXT'),
    (id:GL_RGB16_EXT;name:'GL_RGB16_EXT'),
    (id:GL_RGBA2_EXT;name:'GL_RGBA2_EXT'),
    (id:GL_RGBA4_EXT;name:'GL_RGBA4_EXT'),
    (id:GL_RGB5_A1_EXT;name:'GL_RGB5_A1_EXT'),
    (id:GL_RGBA8_EXT;name:'GL_RGBA8_EXT'),
    (id:GL_RGB10_A2_EXT;name:'GL_RGB10_A2_EXT'),
    (id:GL_RGBA12_EXT;name:'GL_RGBA12_EXT'),
    (id:GL_RGBA16_EXT;name:'GL_RGBA16_EXT'),
    (id:GL_TEXTURE_RED_SIZE_EXT;name:'GL_TEXTURE_RED_SIZE_EXT'),
    (id:GL_TEXTURE_GREEN_SIZE_EXT;name:'GL_TEXTURE_GREEN_SIZE_EXT'),
    (id:GL_TEXTURE_BLUE_SIZE_EXT;name:'GL_TEXTURE_BLUE_SIZE_EXT'),
    (id:GL_TEXTURE_ALPHA_SIZE_EXT;name:'GL_TEXTURE_ALPHA_SIZE_EXT'),
    (id:GL_TEXTURE_LUMINANCE_SIZE_EXT;name:'GL_TEXTURE_LUMINANCE_SIZE_EXT'),
    (id:GL_TEXTURE_INTENSITY_SIZE_EXT;name:'GL_TEXTURE_INTENSITY_SIZE_EXT'),
    (id:GL_REPLACE_EXT;name:'GL_REPLACE_EXT'),
    (id:GL_PROXY_TEXTURE_1D_EXT;name:'GL_PROXY_TEXTURE_1D_EXT'),
    (id:GL_PROXY_TEXTURE_2D_EXT;name:'GL_PROXY_TEXTURE_2D_EXT'),
    (id:GL_TEXTURE_TOO_LARGE_EXT;name:'GL_TEXTURE_TOO_LARGE_EXT'),
    (id:GL_TEXTURE_PRIORITY_EXT;name:'GL_TEXTURE_PRIORITY_EXT'),
    (id:GL_TEXTURE_RESIDENT_EXT;name:'GL_TEXTURE_RESIDENT_EXT'),
    (id:GL_TEXTURE_1D_BINDING_EXT;name:'GL_TEXTURE_1D_BINDING_EXT'),
    (id:GL_TEXTURE_2D_BINDING_EXT;name:'GL_TEXTURE_2D_BINDING_EXT'),
    (id:GL_TEXTURE_3D_BINDING_EXT;name:'GL_TEXTURE_3D_BINDING_EXT'),
    (id:GL_PACK_SKIP_IMAGES_EXT;name:'GL_PACK_SKIP_IMAGES_EXT'),
    (id:GL_PACK_IMAGE_HEIGHT_EXT;name:'GL_PACK_IMAGE_HEIGHT_EXT'),
    (id:GL_UNPACK_SKIP_IMAGES_EXT;name:'GL_UNPACK_SKIP_IMAGES_EXT'),
    (id:GL_UNPACK_IMAGE_HEIGHT_EXT;name:'GL_UNPACK_IMAGE_HEIGHT_EXT'),
    (id:GL_TEXTURE_3D_EXT;name:'GL_TEXTURE_3D_EXT'),
    (id:GL_PROXY_TEXTURE_3D_EXT;name:'GL_PROXY_TEXTURE_3D_EXT'),
    (id:GL_TEXTURE_DEPTH_EXT;name:'GL_TEXTURE_DEPTH_EXT'),
    (id:GL_TEXTURE_WRAP_R_EXT;name:'GL_TEXTURE_WRAP_R_EXT'),
    (id:GL_MAX_3D_TEXTURE_SIZE_EXT;name:'GL_MAX_3D_TEXTURE_SIZE_EXT'),
    (id:GL_COLOR_MATRIX_SGI;name:'GL_COLOR_MATRIX_SGI'),
    (id:GL_COLOR_MATRIX_STACK_DEPTH_SGI;name:'GL_COLOR_MATRIX_STACK_DEPTH_SGI'),
    (id:GL_MAX_COLOR_MATRIX_STACK_DEPTH_SGI;name:'GL_MAX_COLOR_MATRIX_STACK_DEPTH_SGI'),
    (id:GL_POST_COLOR_MATRIX_RED_SCALE_SGI;name:'GL_POST_COLOR_MATRIX_RED_SCALE_SGI'),
    (id:GL_POST_COLOR_MATRIX_GREEN_SCALE_SGI;name:'GL_POST_COLOR_MATRIX_GREEN_SCALE_SGI'),
    (id:GL_POST_COLOR_MATRIX_BLUE_SCALE_SGI;name:'GL_POST_COLOR_MATRIX_BLUE_SCALE_SGI'),
    (id:GL_POST_COLOR_MATRIX_ALPHA_SCALE_SGI;name:'GL_POST_COLOR_MATRIX_ALPHA_SCALE_SGI'),
    (id:GL_POST_COLOR_MATRIX_RED_BIAS_SGI;name:'GL_POST_COLOR_MATRIX_RED_BIAS_SGI'),
    (id:GL_POST_COLOR_MATRIX_GREEN_BIAS_SGI;name:'GL_POST_COLOR_MATRIX_GREEN_BIAS_SGI'),
    (id:GL_POST_COLOR_MATRIX_BLUE_BIAS_SGI;name:'GL_POST_COLOR_MATRIX_BLUE_BIAS_SGI'),
    (id:GL_POST_COLOR_MATRIX_ALPHA_BIAS_SGI;name:'GL_POST_COLOR_MATRIX_ALPHA_BIAS_SGI'),
    (id:GL_POINT_SIZE_MIN_ARB;name:'GL_POINT_SIZE_MIN_ARB'),
    (id:GL_POINT_SIZE_MAX_ARB;name:'GL_POINT_SIZE_MAX_ARB'),
    (id:GL_POINT_FADE_THRESHOLD_SIZE_ARB;name:'GL_POINT_FADE_THRESHOLD_SIZE_ARB'),
    (id:GL_DISTANCE_ATTENUATION_ARB;name:'GL_DISTANCE_ATTENUATION_ARB'),
    (id:GL_RESCALE_NORMAL_EXT;name:'GL_RESCALE_NORMAL_EXT'),
    (id:GL_SHARED_TEXTURE_PALETTE_EXT;name:'GL_SHARED_TEXTURE_PALETTE_EXT'),
    (id:GLU_NURBS_MODE_EXT;name:'GLU_NURBS_MODE_EXT'),
    (id:GLU_NURBS_TESSELLATOR_EXT;name:'GLU_NURBS_TESSELLATOR_EXT'),
    (id:GLU_NURBS_RENDERER_EXT;name:'GLU_NURBS_RENDERER_EXT'),
    (id:GLU_NURBS_BEGIN_EXT;name:'GLU_NURBS_BEGIN_EXT'),
    (id:GLU_NURBS_VERTEX_EXT;name:'GLU_NURBS_VERTEX_EXT'),
    (id:GLU_NURBS_NORMAL_EXT;name:'GLU_NURBS_NORMAL_EXT'),
    (id:GLU_NURBS_COLOR_EXT;name:'GLU_NURBS_COLOR_EXT'),
    (id:GLU_NURBS_TEX_COORD_EXT;name:'GLU_NURBS_TEX_COORD_EXT'),
    (id:GLU_NURBS_END_EXT;name:'GLU_NURBS_END_EXT'),
    (id:GLU_NURBS_BEGIN_DATA_EXT;name:'GLU_NURBS_BEGIN_DATA_EXT'),
    (id:GLU_NURBS_VERTEX_DATA_EXT;name:'GLU_NURBS_VERTEX_DATA_EXT'),
    (id:GLU_NURBS_NORMAL_DATA_EXT;name:'GLU_NURBS_NORMAL_DATA_EXT'),
    (id:GLU_NURBS_COLOR_DATA_EXT;name:'GLU_NURBS_COLOR_DATA_EXT'),
    (id:GLU_NURBS_TEX_COORD_DATA_EXT;name:'GLU_NURBS_TEX_COORD_DATA_EXT'),
    (id:GLU_NURBS_END_DATA_EXT;name:'GLU_NURBS_END_DATA_EXT'),
    (id:GLU_OBJECT_PARAMETRIC_ERROR_EXT;name:'GLU_OBJECT_PARAMETRIC_ERROR_EXT'),
    (id:GLU_OBJECT_PATH_LENGTH_EXT;name:'GLU_OBJECT_PATH_LENGTH_EXT'),
    (id:GL_ARRAY_ELEMENT_LOCK_FIRST_EXT;name:'GL_ARRAY_ELEMENT_LOCK_FIRST_EXT'),
    (id:GL_ARRAY_ELEMENT_LOCK_COUNT_EXT;name:'GL_ARRAY_ELEMENT_LOCK_COUNT_EXT'),
    (id:GL_ACTIVE_TEXTURE_ARB;name:'GL_ACTIVE_TEXTURE_ARB'),
    (id:GL_CLIENT_ACTIVE_TEXTURE_ARB;name:'GL_CLIENT_ACTIVE_TEXTURE_ARB'),
    (id:GL_MAX_TEXTURE_UNITS_ARB;name:'GL_MAX_TEXTURE_UNITS_ARB'),
    (id:GL_TEXTURE0_ARB;name:'GL_TEXTURE0_ARB'),
    (id:GL_TEXTURE1_ARB;name:'GL_TEXTURE1_ARB'),
    (id:GL_TEXTURE2_ARB;name:'GL_TEXTURE2_ARB'),
    (id:GL_TEXTURE3_ARB;name:'GL_TEXTURE3_ARB'),
    (id:GL_TEXTURE4_ARB;name:'GL_TEXTURE4_ARB'),
    (id:GL_TEXTURE5_ARB;name:'GL_TEXTURE5_ARB'),
    (id:GL_TEXTURE6_ARB;name:'GL_TEXTURE6_ARB'),
    (id:GL_TEXTURE7_ARB;name:'GL_TEXTURE7_ARB'),
    (id:GL_TEXTURE8_ARB;name:'GL_TEXTURE8_ARB'),
    (id:GL_TEXTURE9_ARB;name:'GL_TEXTURE9_ARB'),
    (id:GL_TEXTURE10_ARB;name:'GL_TEXTURE10_ARB'),
    (id:GL_TEXTURE11_ARB;name:'GL_TEXTURE11_ARB'),
    (id:GL_TEXTURE12_ARB;name:'GL_TEXTURE12_ARB'),
    (id:GL_TEXTURE13_ARB;name:'GL_TEXTURE13_ARB'),
    (id:GL_TEXTURE14_ARB;name:'GL_TEXTURE14_ARB'),
    (id:GL_TEXTURE15_ARB;name:'GL_TEXTURE15_ARB'),
    (id:GL_TEXTURE16_ARB;name:'GL_TEXTURE16_ARB'),
    (id:GL_TEXTURE17_ARB;name:'GL_TEXTURE17_ARB'),
    (id:GL_TEXTURE18_ARB;name:'GL_TEXTURE18_ARB'),
    (id:GL_TEXTURE19_ARB;name:'GL_TEXTURE19_ARB'),
    (id:GL_TEXTURE20_ARB;name:'GL_TEXTURE20_ARB'),
    (id:GL_TEXTURE21_ARB;name:'GL_TEXTURE21_ARB'),
    (id:GL_TEXTURE22_ARB;name:'GL_TEXTURE22_ARB'),
    (id:GL_TEXTURE23_ARB;name:'GL_TEXTURE23_ARB'),
    (id:GL_TEXTURE24_ARB;name:'GL_TEXTURE24_ARB'),
    (id:GL_TEXTURE25_ARB;name:'GL_TEXTURE25_ARB'),
    (id:GL_TEXTURE26_ARB;name:'GL_TEXTURE26_ARB'),
    (id:GL_TEXTURE27_ARB;name:'GL_TEXTURE27_ARB'),
    (id:GL_TEXTURE28_ARB;name:'GL_TEXTURE28_ARB'),
    (id:GL_TEXTURE29_ARB;name:'GL_TEXTURE29_ARB'),
    (id:GL_TEXTURE30_ARB;name:'GL_TEXTURE30_ARB'),
    (id:GL_TEXTURE31_ARB;name:'GL_TEXTURE31_ARB'),
    (id:GL_INCR_WRAP_EXT;name:'GL_INCR_WRAP_EXT'),
    (id:GL_DECR_WRAP_EXT;name:'GL_DECR_WRAP_EXT'),
    (id:GL_STENCIL_TEST_TWO_SIDE_EXT;name:'GL_STENCIL_TEST_TWO_SIDE_EXT'),
    (id:GL_ACTIVE_STENCIL_FACE_EXT;name:'GL_ACTIVE_STENCIL_FACE_EXT'),
    (id:GL_NORMAL_MAP_NV;name:'GL_NORMAL_MAP_NV'),
    (id:GL_REFLECTION_MAP_NV;name:'GL_REFLECTION_MAP_NV'),
    (id:GL_ALL_COMPLETED_NV;name:'GL_ALL_COMPLETED_NV'),
    (id:GL_FENCE_STATUS_NV;name:'GL_FENCE_STATUS_NV'),
    (id:GL_FENCE_CONDITION_NV;name:'GL_FENCE_CONDITION_NV'),
    (id:GL_PIXEL_COUNTER_BITS_NV;name:'GL_PIXEL_COUNTER_BITS_NV'),
    (id:GL_CURRENT_OCCLUSION_QUERY_ID_NV;name:'GL_CURRENT_OCCLUSION_QUERY_ID_NV'),
    (id:GL_PIXEL_COUNT_NV;name:'GL_PIXEL_COUNT_NV'),
    (id:GL_PIXEL_COUNT_AVAILABLE_NV;name:'GL_PIXEL_COUNT_AVAILABLE_NV'),
    (id:GL_TEXTURE_RECTANGLE_NV;name:'GL_TEXTURE_RECTANGLE_NV'),
    (id:GL_TEXTURE_BINDING_RECTANGLE_NV;name:'GL_TEXTURE_BINDING_RECTANGLE_NV'),
    (id:GL_PROXY_TEXTURE_RECTANGLE_NV;name:'GL_PROXY_TEXTURE_RECTANGLE_NV'),
    (id:GL_MAX_RECTANGLE_TEXTURE_SIZE_NV;name:'GL_MAX_RECTANGLE_TEXTURE_SIZE_NV'),
    (id:GL_COMBINE_EXT;name:'GL_COMBINE_EXT'),
    (id:GL_COMBINE_RGB_EXT;name:'GL_COMBINE_RGB_EXT'),
    (id:GL_COMBINE_ALPHA_EXT;name:'GL_COMBINE_ALPHA_EXT'),
    (id:GL_RGB_SCALE_EXT;name:'GL_RGB_SCALE_EXT'),
    (id:GL_ADD_SIGNED_EXT;name:'GL_ADD_SIGNED_EXT'),
    (id:GL_INTERPOLATE_EXT;name:'GL_INTERPOLATE_EXT'),
    (id:GL_CONSTANT_EXT;name:'GL_CONSTANT_EXT'),
    (id:GL_PRIMARY_COLOR_EXT;name:'GL_PRIMARY_COLOR_EXT'),
    (id:GL_PREVIOUS_EXT;name:'GL_PREVIOUS_EXT'),
    (id:GL_SOURCE0_RGB_EXT;name:'GL_SOURCE0_RGB_EXT'),
    (id:GL_SOURCE1_RGB_EXT;name:'GL_SOURCE1_RGB_EXT'),
    (id:GL_SOURCE2_RGB_EXT;name:'GL_SOURCE2_RGB_EXT'),
    (id:GL_SOURCE0_ALPHA_EXT;name:'GL_SOURCE0_ALPHA_EXT'),
    (id:GL_SOURCE1_ALPHA_EXT;name:'GL_SOURCE1_ALPHA_EXT'),
    (id:GL_SOURCE2_ALPHA_EXT;name:'GL_SOURCE2_ALPHA_EXT'),
    (id:GL_OPERAND0_RGB_EXT;name:'GL_OPERAND0_RGB_EXT'),
    (id:GL_OPERAND1_RGB_EXT;name:'GL_OPERAND1_RGB_EXT'),
    (id:GL_OPERAND2_RGB_EXT;name:'GL_OPERAND2_RGB_EXT'),
    (id:GL_OPERAND0_ALPHA_EXT;name:'GL_OPERAND0_ALPHA_EXT'),
    (id:GL_OPERAND1_ALPHA_EXT;name:'GL_OPERAND1_ALPHA_EXT'),
    (id:GL_OPERAND2_ALPHA_EXT;name:'GL_OPERAND2_ALPHA_EXT'),
    (id:GL_COMBINE_ARB;name:'GL_COMBINE_ARB'),
    (id:GL_COMBINE_RGB_ARB;name:'GL_COMBINE_RGB_ARB'),
    (id:GL_COMBINE_ALPHA_ARB;name:'GL_COMBINE_ALPHA_ARB'),
    (id:GL_SOURCE0_RGB_ARB;name:'GL_SOURCE0_RGB_ARB'),
    (id:GL_SOURCE1_RGB_ARB;name:'GL_SOURCE1_RGB_ARB'),
    (id:GL_SOURCE2_RGB_ARB;name:'GL_SOURCE2_RGB_ARB'),
    (id:GL_SOURCE0_ALPHA_ARB;name:'GL_SOURCE0_ALPHA_ARB'),
    (id:GL_SOURCE1_ALPHA_ARB;name:'GL_SOURCE1_ALPHA_ARB'),
    (id:GL_SOURCE2_ALPHA_ARB;name:'GL_SOURCE2_ALPHA_ARB'),
    (id:GL_OPERAND0_RGB_ARB;name:'GL_OPERAND0_RGB_ARB'),
    (id:GL_OPERAND1_RGB_ARB;name:'GL_OPERAND1_RGB_ARB'),
    (id:GL_OPERAND2_RGB_ARB;name:'GL_OPERAND2_RGB_ARB'),
    (id:GL_OPERAND0_ALPHA_ARB;name:'GL_OPERAND0_ALPHA_ARB'),
    (id:GL_OPERAND1_ALPHA_ARB;name:'GL_OPERAND1_ALPHA_ARB'),
    (id:GL_OPERAND2_ALPHA_ARB;name:'GL_OPERAND2_ALPHA_ARB'),
    (id:GL_RGB_SCALE_ARB;name:'GL_RGB_SCALE_ARB'),
    (id:GL_ADD_SIGNED_ARB;name:'GL_ADD_SIGNED_ARB'),
    (id:GL_INTERPOLATE_ARB;name:'GL_INTERPOLATE_ARB'),
    (id:GL_SUBTRACT_ARB;name:'GL_SUBTRACT_ARB'),
    (id:GL_CONSTANT_ARB;name:'GL_CONSTANT_ARB'),
    (id:GL_CONSTANT_COLOR_ARB;name:'GL_CONSTANT_COLOR_ARB'),
    (id:GL_PRIMARY_COLOR_ARB;name:'GL_PRIMARY_COLOR_ARB'),
    (id:GL_PREVIOUS_ARB;name:'GL_PREVIOUS_ARB'),
    (id:GL_DOT3_RGB_ARB;name:'GL_DOT3_RGB_ARB'),
    (id:GL_DOT3_RGBA_ARB;name:'GL_DOT3_RGBA_ARB'),
    (id:GL_VERTEX_PROGRAM_ARB;name:'GL_VERTEX_PROGRAM_ARB'),
    (id:GL_VERTEX_PROGRAM_POINT_SIZE_ARB;name:'GL_VERTEX_PROGRAM_POINT_SIZE_ARB'),
    (id:GL_VERTEX_PROGRAM_TWO_SIDE_ARB;name:'GL_VERTEX_PROGRAM_TWO_SIDE_ARB'),
    (id:GL_COLOR_SUM_ARB;name:'GL_COLOR_SUM_ARB'),
    (id:GL_PROGRAM_FORMAT_ASCII_ARB;name:'GL_PROGRAM_FORMAT_ASCII_ARB'),
    (id:GL_VERTEX_ATTRIB_ARRAY_ENABLED_ARB;name:'GL_VERTEX_ATTRIB_ARRAY_ENABLED_ARB'),
    (id:GL_VERTEX_ATTRIB_ARRAY_SIZE_ARB;name:'GL_VERTEX_ATTRIB_ARRAY_SIZE_ARB'),
    (id:GL_VERTEX_ATTRIB_ARRAY_STRIDE_ARB;name:'GL_VERTEX_ATTRIB_ARRAY_STRIDE_ARB'),
    (id:GL_VERTEX_ATTRIB_ARRAY_TYPE_ARB;name:'GL_VERTEX_ATTRIB_ARRAY_TYPE_ARB'),
    (id:GL_VERTEX_ATTRIB_ARRAY_NORMALIZED_ARB;name:'GL_VERTEX_ATTRIB_ARRAY_NORMALIZED_ARB'),
    (id:GL_CURRENT_VERTEX_ATTRIB_ARB;name:'GL_CURRENT_VERTEX_ATTRIB_ARB'),
    (id:GL_VERTEX_ATTRIB_ARRAY_POINTER_ARB;name:'GL_VERTEX_ATTRIB_ARRAY_POINTER_ARB'),
    (id:GL_PROGRAM_LENGTH_ARB;name:'GL_PROGRAM_LENGTH_ARB'),
    (id:GL_PROGRAM_FORMAT_ARB;name:'GL_PROGRAM_FORMAT_ARB'),
    (id:GL_PROGRAM_BINDING_ARB;name:'GL_PROGRAM_BINDING_ARB'),
    (id:GL_PROGRAM_INSTRUCTIONS_ARB;name:'GL_PROGRAM_INSTRUCTIONS_ARB'),
    (id:GL_MAX_PROGRAM_INSTRUCTIONS_ARB;name:'GL_MAX_PROGRAM_INSTRUCTIONS_ARB'),
    (id:GL_PROGRAM_NATIVE_INSTRUCTIONS_ARB;name:'GL_PROGRAM_NATIVE_INSTRUCTIONS_ARB'),
    (id:GL_MAX_PROGRAM_NATIVE_INSTRUCTIONS_ARB;name:'GL_MAX_PROGRAM_NATIVE_INSTRUCTIONS_ARB'),
    (id:GL_PROGRAM_TEMPORARIES_ARB;name:'GL_PROGRAM_TEMPORARIES_ARB'),
    (id:GL_MAX_PROGRAM_TEMPORARIES_ARB;name:'GL_MAX_PROGRAM_TEMPORARIES_ARB'),
    (id:GL_PROGRAM_NATIVE_TEMPORARIES_ARB;name:'GL_PROGRAM_NATIVE_TEMPORARIES_ARB'),
    (id:GL_MAX_PROGRAM_NATIVE_TEMPORARIES_ARB;name:'GL_MAX_PROGRAM_NATIVE_TEMPORARIES_ARB'),
    (id:GL_PROGRAM_PARAMETERS_ARB;name:'GL_PROGRAM_PARAMETERS_ARB'),
    (id:GL_MAX_PROGRAM_PARAMETERS_ARB;name:'GL_MAX_PROGRAM_PARAMETERS_ARB'),
    (id:GL_PROGRAM_NATIVE_PARAMETERS_ARB;name:'GL_PROGRAM_NATIVE_PARAMETERS_ARB'),
    (id:GL_MAX_PROGRAM_NATIVE_PARAMETERS_ARB;name:'GL_MAX_PROGRAM_NATIVE_PARAMETERS_ARB'),
    (id:GL_PROGRAM_ATTRIBS_ARB;name:'GL_PROGRAM_ATTRIBS_ARB'),
    (id:GL_MAX_PROGRAM_ATTRIBS_ARB;name:'GL_MAX_PROGRAM_ATTRIBS_ARB'),
    (id:GL_PROGRAM_NATIVE_ATTRIBS_ARB;name:'GL_PROGRAM_NATIVE_ATTRIBS_ARB'),
    (id:GL_MAX_PROGRAM_NATIVE_ATTRIBS_ARB;name:'GL_MAX_PROGRAM_NATIVE_ATTRIBS_ARB'),
    (id:GL_PROGRAM_ADDRESS_REGISTERS_ARB;name:'GL_PROGRAM_ADDRESS_REGISTERS_ARB'),
    (id:GL_MAX_PROGRAM_ADDRESS_REGISTERS_ARB;name:'GL_MAX_PROGRAM_ADDRESS_REGISTERS_ARB'),
    (id:GL_PROGRAM_NATIVE_ADDRESS_REGISTERS_ARB;name:'GL_PROGRAM_NATIVE_ADDRESS_REGISTERS_ARB'),
    (id:GL_MAX_PROGRAM_NATIVE_ADDRESS_REGISTERS_ARB;name:'GL_MAX_PROGRAM_NATIVE_ADDRESS_REGISTERS_ARB'),
    (id:GL_MAX_PROGRAM_LOCAL_PARAMETERS_ARB;name:'GL_MAX_PROGRAM_LOCAL_PARAMETERS_ARB'),
    (id:GL_MAX_PROGRAM_ENV_PARAMETERS_ARB;name:'GL_MAX_PROGRAM_ENV_PARAMETERS_ARB'),
    (id:GL_PROGRAM_UNDER_NATIVE_LIMITS_ARB;name:'GL_PROGRAM_UNDER_NATIVE_LIMITS_ARB'),
    (id:GL_PROGRAM_STRING_ARB;name:'GL_PROGRAM_STRING_ARB'),
    (id:GL_PROGRAM_ERROR_POSITION_ARB;name:'GL_PROGRAM_ERROR_POSITION_ARB'),
    (id:GL_CURRENT_MATRIX_ARB;name:'GL_CURRENT_MATRIX_ARB'),
    (id:GL_TRANSPOSE_CURRENT_MATRIX_ARB;name:'GL_TRANSPOSE_CURRENT_MATRIX_ARB'),
    (id:GL_CURRENT_MATRIX_STACK_DEPTH_ARB;name:'GL_CURRENT_MATRIX_STACK_DEPTH_ARB'),
    (id:GL_MAX_VERTEX_ATTRIBS_ARB;name:'GL_MAX_VERTEX_ATTRIBS_ARB'),
    (id:GL_MAX_PROGRAM_MATRICES_ARB;name:'GL_MAX_PROGRAM_MATRICES_ARB'),
    (id:GL_MAX_PROGRAM_MATRIX_STACK_DEPTH_ARB;name:'GL_MAX_PROGRAM_MATRIX_STACK_DEPTH_ARB'),
    (id:GL_PROGRAM_ERROR_STRING_ARB;name:'GL_PROGRAM_ERROR_STRING_ARB'),
    (id:GL_MATRIX0_ARB;name:'GL_MATRIX0_ARB'),
    (id:GL_MATRIX1_ARB;name:'GL_MATRIX1_ARB'),
    (id:GL_MATRIX2_ARB;name:'GL_MATRIX2_ARB'),
    (id:GL_MATRIX3_ARB;name:'GL_MATRIX3_ARB'),
    (id:GL_MATRIX4_ARB;name:'GL_MATRIX4_ARB'),
    (id:GL_MATRIX5_ARB;name:'GL_MATRIX5_ARB'),
    (id:GL_MATRIX6_ARB;name:'GL_MATRIX6_ARB'),
    (id:GL_MATRIX7_ARB;name:'GL_MATRIX7_ARB'),
    (id:GL_MATRIX8_ARB;name:'GL_MATRIX8_ARB'),
    (id:GL_MATRIX9_ARB;name:'GL_MATRIX9_ARB'),
    (id:GL_MATRIX10_ARB;name:'GL_MATRIX10_ARB'),
    (id:GL_MATRIX11_ARB;name:'GL_MATRIX11_ARB'),
    (id:GL_MATRIX12_ARB;name:'GL_MATRIX12_ARB'),
    (id:GL_MATRIX13_ARB;name:'GL_MATRIX13_ARB'),
    (id:GL_MATRIX14_ARB;name:'GL_MATRIX14_ARB'),
    (id:GL_MATRIX15_ARB;name:'GL_MATRIX15_ARB'),
    (id:GL_MATRIX16_ARB;name:'GL_MATRIX16_ARB'),
    (id:GL_MATRIX17_ARB;name:'GL_MATRIX17_ARB'),
    (id:GL_MATRIX18_ARB;name:'GL_MATRIX18_ARB'),
    (id:GL_MATRIX19_ARB;name:'GL_MATRIX19_ARB'),
    (id:GL_MATRIX20_ARB;name:'GL_MATRIX20_ARB'),
    (id:GL_MATRIX21_ARB;name:'GL_MATRIX21_ARB'),
    (id:GL_MATRIX22_ARB;name:'GL_MATRIX22_ARB'),
    (id:GL_MATRIX23_ARB;name:'GL_MATRIX23_ARB'),
    (id:GL_MATRIX24_ARB;name:'GL_MATRIX24_ARB'),
    (id:GL_MATRIX25_ARB;name:'GL_MATRIX25_ARB'),
    (id:GL_MATRIX26_ARB;name:'GL_MATRIX26_ARB'),
    (id:GL_MATRIX27_ARB;name:'GL_MATRIX27_ARB'),
    (id:GL_MATRIX28_ARB;name:'GL_MATRIX28_ARB'),
    (id:GL_MATRIX29_ARB;name:'GL_MATRIX29_ARB'),
    (id:GL_MATRIX30_ARB;name:'GL_MATRIX30_ARB'),
    (id:GL_MATRIX31_ARB;name:'GL_MATRIX31_ARB'),
    (id:GL_ARRAY_BUFFER_ARB;name:'GL_ARRAY_BUFFER_ARB'),
    (id:GL_ELEMENT_ARRAY_BUFFER_ARB;name:'GL_ELEMENT_ARRAY_BUFFER_ARB'),
    (id:GL_ARRAY_BUFFER_BINDING_ARB;name:'GL_ARRAY_BUFFER_BINDING_ARB'),
    (id:GL_ELEMENT_ARRAY_BUFFER_BINDING_ARB;name:'GL_ELEMENT_ARRAY_BUFFER_BINDING_ARB'),
    (id:GL_VERTEX_ARRAY_BUFFER_BINDING_ARB;name:'GL_VERTEX_ARRAY_BUFFER_BINDING_ARB'),
    (id:GL_NORMAL_ARRAY_BUFFER_BINDING_ARB;name:'GL_NORMAL_ARRAY_BUFFER_BINDING_ARB'),
    (id:GL_COLOR_ARRAY_BUFFER_BINDING_ARB;name:'GL_COLOR_ARRAY_BUFFER_BINDING_ARB'),
    (id:GL_INDEX_ARRAY_BUFFER_BINDING_ARB;name:'GL_INDEX_ARRAY_BUFFER_BINDING_ARB'),
    (id:GL_TEXTURE_COORD_ARRAY_BUFFER_BINDING_ARB;name:'GL_TEXTURE_COORD_ARRAY_BUFFER_BINDING_ARB'),
    (id:GL_EDGE_FLAG_ARRAY_BUFFER_BINDING_ARB;name:'GL_EDGE_FLAG_ARRAY_BUFFER_BINDING_ARB'),
    (id:GL_SECONDARY_COLOR_ARRAY_BUFFER_BINDING_ARB;name:'GL_SECONDARY_COLOR_ARRAY_BUFFER_BINDING_ARB'),
    (id:GL_FOG_COORDINATE_ARRAY_BUFFER_BINDING_ARB;name:'GL_FOG_COORDINATE_ARRAY_BUFFER_BINDING_ARB'),
    (id:GL_WEIGHT_ARRAY_BUFFER_BINDING_ARB;name:'GL_WEIGHT_ARRAY_BUFFER_BINDING_ARB'),
    (id:GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING_ARB;name:'GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING_ARB'),
    (id:GL_STREAM_DRAW_ARB;name:'GL_STREAM_DRAW_ARB'),
    (id:GL_STREAM_READ_ARB;name:'GL_STREAM_READ_ARB'),
    (id:GL_STREAM_COPY_ARB;name:'GL_STREAM_COPY_ARB'),
    (id:GL_STATIC_DRAW_ARB;name:'GL_STATIC_DRAW_ARB'),
    (id:GL_STATIC_READ_ARB;name:'GL_STATIC_READ_ARB'),
    (id:GL_STATIC_COPY_ARB;name:'GL_STATIC_COPY_ARB'),
    (id:GL_DYNAMIC_DRAW_ARB;name:'GL_DYNAMIC_DRAW_ARB'),
    (id:GL_DYNAMIC_READ_ARB;name:'GL_DYNAMIC_READ_ARB'),
    (id:GL_DYNAMIC_COPY_ARB;name:'GL_DYNAMIC_COPY_ARB'),
    (id:GL_READ_ONLY_ARB;name:'GL_READ_ONLY_ARB'),
    (id:GL_WRITE_ONLY_ARB;name:'GL_WRITE_ONLY_ARB'),
    (id:GL_READ_WRITE_ARB;name:'GL_READ_WRITE_ARB'),
    (id:GL_BUFFER_SIZE_ARB;name:'GL_BUFFER_SIZE_ARB'),
    (id:GL_BUFFER_USAGE_ARB;name:'GL_BUFFER_USAGE_ARB'),
    (id:GL_BUFFER_ACCESS_ARB;name:'GL_BUFFER_ACCESS_ARB'),
    (id:GL_BUFFER_MAPPED_ARB;name:'GL_BUFFER_MAPPED_ARB'),
    (id:GL_BUFFER_MAP_POINTER_ARB;name:'GL_BUFFER_MAP_POINTER_ARB'),
    (id:GL_PROGRAM_OBJECT_ARB;name:'GL_PROGRAM_OBJECT_ARB'),
    (id:GL_OBJECT_TYPE_ARB;name:'GL_OBJECT_TYPE_ARB'),
    (id:GL_OBJECT_SUBTYPE_ARB;name:'GL_OBJECT_SUBTYPE_ARB'),
    (id:GL_OBJECT_DELETE_STATUS_ARB;name:'GL_OBJECT_DELETE_STATUS_ARB'),
    (id:GL_OBJECT_COMPILE_STATUS_ARB;name:'GL_OBJECT_COMPILE_STATUS_ARB'),
    (id:GL_OBJECT_LINK_STATUS_ARB;name:'GL_OBJECT_LINK_STATUS_ARB'),
    (id:GL_OBJECT_VALIDATE_STATUS_ARB;name:'GL_OBJECT_VALIDATE_STATUS_ARB'),
    (id:GL_OBJECT_INFO_LOG_LENGTH_ARB;name:'GL_OBJECT_INFO_LOG_LENGTH_ARB'),
    (id:GL_OBJECT_ATTACHED_OBJECTS_ARB;name:'GL_OBJECT_ATTACHED_OBJECTS_ARB'),
    (id:GL_OBJECT_ACTIVE_UNIFORMS_ARB;name:'GL_OBJECT_ACTIVE_UNIFORMS_ARB'),
    (id:GL_OBJECT_ACTIVE_UNIFORM_MAX_LENGTH_ARB;name:'GL_OBJECT_ACTIVE_UNIFORM_MAX_LENGTH_ARB'),
    (id:GL_OBJECT_SHADER_SOURCE_LENGTH_ARB;name:'GL_OBJECT_SHADER_SOURCE_LENGTH_ARB'),
    (id:GL_SHADER_OBJECT_ARB;name:'GL_SHADER_OBJECT_ARB'),
    (id:GL_FLOAT_VEC2_ARB;name:'GL_FLOAT_VEC2_ARB'),
    (id:GL_FLOAT_VEC3_ARB;name:'GL_FLOAT_VEC3_ARB'),
    (id:GL_FLOAT_VEC4_ARB;name:'GL_FLOAT_VEC4_ARB'),
    (id:GL_INT_VEC2_ARB;name:'GL_INT_VEC2_ARB'),
    (id:GL_INT_VEC3_ARB;name:'GL_INT_VEC3_ARB'),
    (id:GL_INT_VEC4_ARB;name:'GL_INT_VEC4_ARB'),
    (id:GL_BOOL_ARB;name:'GL_BOOL_ARB'),
    (id:GL_BOOL_VEC2_ARB;name:'GL_BOOL_VEC2_ARB'),
    (id:GL_BOOL_VEC3_ARB;name:'GL_BOOL_VEC3_ARB'),
    (id:GL_BOOL_VEC4_ARB;name:'GL_BOOL_VEC4_ARB'),
    (id:GL_FLOAT_MAT2_ARB;name:'GL_FLOAT_MAT2_ARB'),
    (id:GL_FLOAT_MAT3_ARB;name:'GL_FLOAT_MAT3_ARB'),
    (id:GL_FLOAT_MAT4_ARB;name:'GL_FLOAT_MAT4_ARB'),
    (id:GL_VERTEX_SHADER_ARB;name:'GL_VERTEX_SHADER_ARB'),
    (id:GL_MAX_VERTEX_UNIFORM_COMPONENTS_ARB;name:'GL_MAX_VERTEX_UNIFORM_COMPONENTS_ARB'),
    (id:GL_MAX_VARYING_FLOATS_ARB;name:'GL_MAX_VARYING_FLOATS_ARB'),
    (id:GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS_ARB;name:'GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS_ARB'),
    (id:GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS_ARB;name:'GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS_ARB'),
    (id:GL_OBJECT_ACTIVE_ATTRIBUTES_ARB;name:'GL_OBJECT_ACTIVE_ATTRIBUTES_ARB'),
    (id:GL_OBJECT_ACTIVE_ATTRIBUTE_MAX_LENGTH_ARB;name:'GL_OBJECT_ACTIVE_ATTRIBUTE_MAX_LENGTH_ARB'),
    (id:GL_FRAGMENT_SHADER_ARB;name:'GL_FRAGMENT_SHADER_ARB'),
    (id:GL_MAX_FRAGMENT_UNIFORM_COMPONENTS_ARB;name:'GL_MAX_FRAGMENT_UNIFORM_COMPONENTS_ARB'),
    (id:GL_FRAGMENT_PROGRAM_ARB;name:'GL_FRAGMENT_PROGRAM_ARB'),
    (id:GL_COMBINE4_NV;name:'GL_COMBINE4_NV'),
    (id:GL_SOURCE3_RGB_NV;name:'GL_SOURCE3_RGB_NV'),
    (id:GL_SOURCE3_ALPHA_NV;name:'GL_SOURCE3_ALPHA_NV'),
    (id:GL_OPERAND3_RGB_NV;name:'GL_OPERAND3_RGB_NV'),
    (id:GL_OPERAND3_ALPHA_NV;name:'GL_OPERAND3_ALPHA_NV'),
    (id:GL_BLEND_EQUATION;name:'GL_BLEND_EQUATION'),
    (id:GL_TABLE_TOO_LARGE;name:'GL_TABLE_TOO_LARGE'),
    (id:GL_UNSIGNED_BYTE_3_3_2;name:'GL_UNSIGNED_BYTE_3_3_2'),
    (id:GL_UNSIGNED_SHORT_4_4_4_4;name:'GL_UNSIGNED_SHORT_4_4_4_4'),
    (id:GL_UNSIGNED_SHORT_5_5_5_1;name:'GL_UNSIGNED_SHORT_5_5_5_1'),
    (id:GL_UNSIGNED_INT_8_8_8_8;name:'GL_UNSIGNED_INT_8_8_8_8'),
    (id:GL_UNSIGNED_INT_10_10_10_2;name:'GL_UNSIGNED_INT_10_10_10_2'),
    (id:GL_UNSIGNED_BYTE_2_3_3_REV;name:'GL_UNSIGNED_BYTE_2_3_3_REV'),
    (id:GL_UNSIGNED_SHORT_5_6_5;name:'GL_UNSIGNED_SHORT_5_6_5'),
    (id:GL_UNSIGNED_SHORT_5_6_5_REV;name:'GL_UNSIGNED_SHORT_5_6_5_REV'),
    (id:GL_UNSIGNED_SHORT_4_4_4_4_REV;name:'GL_UNSIGNED_SHORT_4_4_4_4_REV'),
    (id:GL_UNSIGNED_SHORT_1_5_5_5_REV;name:'GL_UNSIGNED_SHORT_1_5_5_5_REV'),
    (id:GL_UNSIGNED_INT_8_8_8_8_REV;name:'GL_UNSIGNED_INT_8_8_8_8_REV'),
    (id:GL_UNSIGNED_INT_2_10_10_10_REV;name:'GL_UNSIGNED_INT_2_10_10_10_REV'),
    (id:GL_TRANSPOSE_MODELVIEW_MATRIX_ARB;name:'GL_TRANSPOSE_MODELVIEW_MATRIX_ARB'),
    (id:GL_TRANSPOSE_PROJECTION_MATRIX_ARB;name:'GL_TRANSPOSE_PROJECTION_MATRIX_ARB'),
    (id:GL_TRANSPOSE_TEXTURE_MATRIX_ARB;name:'GL_TRANSPOSE_TEXTURE_MATRIX_ARB'),
    (id:GL_TRANSPOSE_COLOR_MATRIX_ARB;name:'GL_TRANSPOSE_COLOR_MATRIX_ARB'),
    (id:GL_MULTISAMPLE_ARB;name:'GL_MULTISAMPLE_ARB'),
    (id:GL_SAMPLE_ALPHA_TO_COVERAGE_ARB;name:'GL_SAMPLE_ALPHA_TO_COVERAGE_ARB'),
    (id:GL_SAMPLE_ALPHA_TO_ONE_ARB;name:'GL_SAMPLE_ALPHA_TO_ONE_ARB'),
    (id:GL_SAMPLE_COVERAGE_ARB;name:'GL_SAMPLE_COVERAGE_ARB'),
    (id:GL_SAMPLE_BUFFERS_ARB;name:'GL_SAMPLE_BUFFERS_ARB'),
    (id:GL_SAMPLES_ARB;name:'GL_SAMPLES_ARB'),
    (id:GL_SAMPLE_COVERAGE_VALUE_ARB;name:'GL_SAMPLE_COVERAGE_VALUE_ARB'),
    (id:GL_SAMPLE_COVERAGE_INVERT_ARB;name:'GL_SAMPLE_COVERAGE_INVERT_ARB'),
    (id:GL_MULTISAMPLE_BIT_ARB;name:'GL_MULTISAMPLE_BIT_ARB'),
    (id:GLX_SAMPLE_BUFFERS_ARB;name:'GLX_SAMPLE_BUFFERS_ARB'),
    (id:GLX_SAMPLES_ARB;name:'GLX_SAMPLES_ARB'),
    (id:WGL_SAMPLE_BUFFERS_ARB;name:'WGL_SAMPLE_BUFFERS_ARB'),
    (id:WGL_SAMPLES_ARB;name:'WGL_SAMPLES_ARB'),
    (id:GL_DEPTH_COMPONENT16_ARB;name:'GL_DEPTH_COMPONENT16_ARB'),
    (id:GL_DEPTH_COMPONENT24_ARB;name:'GL_DEPTH_COMPONENT24_ARB'),
    (id:GL_DEPTH_COMPONENT32_ARB;name:'GL_DEPTH_COMPONENT32_ARB'),
    (id:GL_TEXTURE_DEPTH_SIZE_ARB;name:'GL_TEXTURE_DEPTH_SIZE_ARB'),
    (id:GL_DEPTH_TEXTURE_MODE_ARB;name:'GL_DEPTH_TEXTURE_MODE_ARB'),
    (id:GL_TEXTURE_COMPARE_MODE_ARB;name:'GL_TEXTURE_COMPARE_MODE_ARB'),
    (id:GL_TEXTURE_COMPARE_FUNC_ARB;name:'GL_TEXTURE_COMPARE_FUNC_ARB'),
    (id:GL_COMPARE_R_TO_TEXTURE_ARB;name:'GL_COMPARE_R_TO_TEXTURE_ARB'),
    (id:GL_NORMAL_MAP_ARB;name:'GL_NORMAL_MAP_ARB'),
    (id:GL_REFLECTION_MAP_ARB;name:'GL_REFLECTION_MAP_ARB'),
    (id:GL_TEXTURE_CUBE_MAP_ARB;name:'GL_TEXTURE_CUBE_MAP_ARB'),
    (id:GL_TEXTURE_BINDING_CUBE_MAP_ARB;name:'GL_TEXTURE_BINDING_CUBE_MAP_ARB'),
    (id:GL_TEXTURE_CUBE_MAP_POSITIVE_X_ARB;name:'GL_TEXTURE_CUBE_MAP_POSITIVE_X_ARB'),
    (id:GL_TEXTURE_CUBE_MAP_NEGATIVE_X_ARB;name:'GL_TEXTURE_CUBE_MAP_NEGATIVE_X_ARB'),
    (id:GL_TEXTURE_CUBE_MAP_POSITIVE_Y_ARB;name:'GL_TEXTURE_CUBE_MAP_POSITIVE_Y_ARB'),
    (id:GL_TEXTURE_CUBE_MAP_NEGATIVE_Y_ARB;name:'GL_TEXTURE_CUBE_MAP_NEGATIVE_Y_ARB'),
    (id:GL_TEXTURE_CUBE_MAP_POSITIVE_Z_ARB;name:'GL_TEXTURE_CUBE_MAP_POSITIVE_Z_ARB'),
    (id:GL_TEXTURE_CUBE_MAP_NEGATIVE_Z_ARB;name:'GL_TEXTURE_CUBE_MAP_NEGATIVE_Z_ARB'),
    (id:GL_PROXY_TEXTURE_CUBE_MAP_ARB;name:'GL_PROXY_TEXTURE_CUBE_MAP_ARB'),
    (id:GL_MAX_CUBE_MAP_TEXTURE_SIZE_ARB;name:'GL_MAX_CUBE_MAP_TEXTURE_SIZE_ARB'),
    (id:GL_CLAMP_TO_BORDER_ARB;name:'GL_CLAMP_TO_BORDER_ARB'),
    (id:GL_COMPRESSED_ALPHA_ARB;name:'GL_COMPRESSED_ALPHA_ARB'),
    (id:GL_COMPRESSED_LUMINANCE_ARB;name:'GL_COMPRESSED_LUMINANCE_ARB'),
    (id:GL_COMPRESSED_LUMINANCE_ALPHA_ARB;name:'GL_COMPRESSED_LUMINANCE_ALPHA_ARB'),
    (id:GL_COMPRESSED_INTENSITY_ARB;name:'GL_COMPRESSED_INTENSITY_ARB'),
    (id:GL_COMPRESSED_RGB_ARB;name:'GL_COMPRESSED_RGB_ARB'),
    (id:GL_COMPRESSED_RGBA_ARB;name:'GL_COMPRESSED_RGBA_ARB'),
    (id:GL_TEXTURE_COMPRESSION_HINT_ARB;name:'GL_TEXTURE_COMPRESSION_HINT_ARB'),
    (id:GL_TEXTURE_COMPRESSED_IMAGE_SIZE_ARB;name:'GL_TEXTURE_COMPRESSED_IMAGE_SIZE_ARB'),
    (id:GL_TEXTURE_COMPRESSED_ARB;name:'GL_TEXTURE_COMPRESSED_ARB'),
    (id:GL_NUM_COMPRESSED_TEXTURE_FORMATS_ARB;name:'GL_NUM_COMPRESSED_TEXTURE_FORMATS_ARB'),
    (id:GL_COMPRESSED_TEXTURE_FORMATS_ARB;name:'GL_COMPRESSED_TEXTURE_FORMATS_ARB'),
    (id:GL_MAX_VERTEX_UNITS_ARB;name:'GL_MAX_VERTEX_UNITS_ARB'),
    (id:GL_ACTIVE_VERTEX_UNITS_ARB;name:'GL_ACTIVE_VERTEX_UNITS_ARB'),
    (id:GL_WEIGHT_SUM_UNITY_ARB;name:'GL_WEIGHT_SUM_UNITY_ARB'),
    (id:GL_VERTEX_BLEND_ARB;name:'GL_VERTEX_BLEND_ARB'),
    (id:GL_CURRENT_WEIGHT_ARB;name:'GL_CURRENT_WEIGHT_ARB'),
    (id:GL_WEIGHT_ARRAY_TYPE_ARB;name:'GL_WEIGHT_ARRAY_TYPE_ARB'),
    (id:GL_WEIGHT_ARRAY_STRIDE_ARB;name:'GL_WEIGHT_ARRAY_STRIDE_ARB'),
    (id:GL_WEIGHT_ARRAY_SIZE_ARB;name:'GL_WEIGHT_ARRAY_SIZE_ARB'),
    (id:GL_WEIGHT_ARRAY_POINTER_ARB;name:'GL_WEIGHT_ARRAY_POINTER_ARB'),
    (id:GL_WEIGHT_ARRAY_ARB;name:'GL_WEIGHT_ARRAY_ARB'),
    (id:GL_MODELVIEW0_ARB;name:'GL_MODELVIEW0_ARB'),
    (id:GL_MODELVIEW1_ARB;name:'GL_MODELVIEW1_ARB'),
    (id:GL_MODELVIEW2_ARB;name:'GL_MODELVIEW2_ARB'),
    (id:GL_MODELVIEW3_ARB;name:'GL_MODELVIEW3_ARB'),
    (id:GL_MODELVIEW4_ARB;name:'GL_MODELVIEW4_ARB'),
    (id:GL_MODELVIEW5_ARB;name:'GL_MODELVIEW5_ARB'),
    (id:GL_MODELVIEW6_ARB;name:'GL_MODELVIEW6_ARB'),
    (id:GL_MODELVIEW7_ARB;name:'GL_MODELVIEW7_ARB'),
    (id:GL_MODELVIEW8_ARB;name:'GL_MODELVIEW8_ARB'),
    (id:GL_MODELVIEW9_ARB;name:'GL_MODELVIEW9_ARB'),
    (id:GL_MODELVIEW10_ARB;name:'GL_MODELVIEW10_ARB'),
    (id:GL_MODELVIEW11_ARB;name:'GL_MODELVIEW11_ARB'),
    (id:GL_MODELVIEW12_ARB;name:'GL_MODELVIEW12_ARB'),
    (id:GL_MODELVIEW13_ARB;name:'GL_MODELVIEW13_ARB'),
    (id:GL_MODELVIEW14_ARB;name:'GL_MODELVIEW14_ARB'),
    (id:GL_MODELVIEW15_ARB;name:'GL_MODELVIEW15_ARB'),
    (id:GL_MODELVIEW16_ARB;name:'GL_MODELVIEW16_ARB'),
    (id:GL_MODELVIEW17_ARB;name:'GL_MODELVIEW17_ARB'),
    (id:GL_MODELVIEW18_ARB;name:'GL_MODELVIEW18_ARB'),
    (id:GL_MODELVIEW19_ARB;name:'GL_MODELVIEW19_ARB'),
    (id:GL_MODELVIEW20_ARB;name:'GL_MODELVIEW20_ARB'),
    (id:GL_MODELVIEW21_ARB;name:'GL_MODELVIEW21_ARB'),
    (id:GL_MODELVIEW22_ARB;name:'GL_MODELVIEW22_ARB'),
    (id:GL_MODELVIEW23_ARB;name:'GL_MODELVIEW23_ARB'),
    (id:GL_MODELVIEW24_ARB;name:'GL_MODELVIEW24_ARB'),
    (id:GL_MODELVIEW25_ARB;name:'GL_MODELVIEW25_ARB'),
    (id:GL_MODELVIEW26_ARB;name:'GL_MODELVIEW26_ARB'),
    (id:GL_MODELVIEW27_ARB;name:'GL_MODELVIEW27_ARB'),
    (id:GL_MODELVIEW28_ARB;name:'GL_MODELVIEW28_ARB'),
    (id:GL_MODELVIEW29_ARB;name:'GL_MODELVIEW29_ARB'),
    (id:GL_MODELVIEW30_ARB;name:'GL_MODELVIEW30_ARB'),
    (id:GL_MODELVIEW31_ARB;name:'GL_MODELVIEW31_ARB'),
    (id:GL_TEXTURE_MIN_LOD_SGIS;name:'GL_TEXTURE_MIN_LOD_SGIS'),
    (id:GL_TEXTURE_MAX_LOD_SGIS;name:'GL_TEXTURE_MAX_LOD_SGIS'),
    (id:GL_TEXTURE_BASE_LEVEL_SGIS;name:'GL_TEXTURE_BASE_LEVEL_SGIS'),
    (id:GL_TEXTURE_MAX_LEVEL_SGIS;name:'GL_TEXTURE_MAX_LEVEL_SGIS'),
    (id:GL_MULTISAMPLE_SGIS;name:'GL_MULTISAMPLE_SGIS'),
    (id:GL_SAMPLE_ALPHA_TO_MASK_SGIS;name:'GL_SAMPLE_ALPHA_TO_MASK_SGIS'),
    (id:GL_SAMPLE_ALPHA_TO_ONE_SGIS;name:'GL_SAMPLE_ALPHA_TO_ONE_SGIS'),
    (id:GL_SAMPLE_MASK_SGIS;name:'GL_SAMPLE_MASK_SGIS'),
    (id:GL_1PASS_SGIS;name:'GL_1PASS_SGIS'),
    (id:GL_2PASS_0_SGIS;name:'GL_2PASS_0_SGIS'),
    (id:GL_2PASS_1_SGIS;name:'GL_2PASS_1_SGIS'),
    (id:GL_4PASS_0_SGIS;name:'GL_4PASS_0_SGIS'),
    (id:GL_4PASS_1_SGIS;name:'GL_4PASS_1_SGIS'),
    (id:GL_4PASS_2_SGIS;name:'GL_4PASS_2_SGIS'),
    (id:GL_4PASS_3_SGIS;name:'GL_4PASS_3_SGIS'),
    (id:GL_SAMPLE_BUFFERS_SGIS;name:'GL_SAMPLE_BUFFERS_SGIS'),
    (id:GL_SAMPLES_SGIS;name:'GL_SAMPLES_SGIS'),
    (id:GL_SAMPLE_MASK_VALUE_SGIS;name:'GL_SAMPLE_MASK_VALUE_SGIS'),
    (id:GL_SAMPLE_MASK_INVERT_SGIS;name:'GL_SAMPLE_MASK_INVERT_SGIS'),
    (id:GL_SAMPLE_PATTERN_SGIS;name:'GL_SAMPLE_PATTERN_SGIS'),
    (id:GL_GENERATE_MIPMAP_SGIS;name:'GL_GENERATE_MIPMAP_SGIS'),
    (id:GL_GENERATE_MIPMAP_HINT_SGIS;name:'GL_GENERATE_MIPMAP_HINT_SGIS'),
    (id:GL_TEXTURE_COMPARE_SGIX;name:'GL_TEXTURE_COMPARE_SGIX'),
    (id:GL_TEXTURE_COMPARE_OPERATOR_SGIX;name:'GL_TEXTURE_COMPARE_OPERATOR_SGIX'),
    (id:GL_TEXTURE_LEQUAL_R_SGIX;name:'GL_TEXTURE_LEQUAL_R_SGIX'),
    (id:GL_TEXTURE_GEQUAL_R_SGIX;name:'GL_TEXTURE_GEQUAL_R_SGIX'),
    (id:GL_CLAMP_TO_EDGE_SGIS;name:'GL_CLAMP_TO_EDGE_SGIS'),
    (id:GL_CLAMP_TO_BORDER_SGIS;name:'GL_CLAMP_TO_BORDER_SGIS'),
    (id:GL_TEXTURE_INDEX_SIZE_EXT;name:'GL_TEXTURE_INDEX_SIZE_EXT'),
    (id:GL_SHADOW_AMBIENT_SGIX;name:'GL_SHADOW_AMBIENT_SGIX'),
    (id:GL_RASTER_POSITION_UNCLIPPED_IBM;name:'GL_RASTER_POSITION_UNCLIPPED_IBM'),
    (id:GL_MAX_ELEMENTS_VERTICES_EXT;name:'GL_MAX_ELEMENTS_VERTICES_EXT'),
    (id:GL_MAX_ELEMENTS_INDICES_EXT;name:'GL_MAX_ELEMENTS_INDICES_EXT'),
    (id:GL_OCCLUSION_TEST_HP;name:'GL_OCCLUSION_TEST_HP'),
    (id:GL_OCCLUSION_TEST_RESULT_HP;name:'GL_OCCLUSION_TEST_RESULT_HP'),
    (id:GL_LIGHT_MODEL_COLOR_CONTROL_EXT;name:'GL_LIGHT_MODEL_COLOR_CONTROL_EXT'),
    (id:GL_SINGLE_COLOR_EXT;name:'GL_SINGLE_COLOR_EXT'),
    (id:GL_SEPARATE_SPECULAR_COLOR_EXT;name:'GL_SEPARATE_SPECULAR_COLOR_EXT'),
    (id:GL_COLOR_SUM_EXT;name:'GL_COLOR_SUM_EXT'),
    (id:GL_CURRENT_SECONDARY_COLOR_EXT;name:'GL_CURRENT_SECONDARY_COLOR_EXT'),
    (id:GL_SECONDARY_COLOR_ARRAY_SIZE_EXT;name:'GL_SECONDARY_COLOR_ARRAY_SIZE_EXT'),
    (id:GL_SECONDARY_COLOR_ARRAY_TYPE_EXT;name:'GL_SECONDARY_COLOR_ARRAY_TYPE_EXT'),
    (id:GL_SECONDARY_COLOR_ARRAY_STRIDE_EXT;name:'GL_SECONDARY_COLOR_ARRAY_STRIDE_EXT'),
    (id:GL_SECONDARY_COLOR_ARRAY_POINTER_EXT;name:'GL_SECONDARY_COLOR_ARRAY_POINTER_EXT'),
    (id:GL_SECONDARY_COLOR_ARRAY_EXT;name:'GL_SECONDARY_COLOR_ARRAY_EXT'),
    (id:GL_FOG_COORDINATE_SOURCE_EXT;name:'GL_FOG_COORDINATE_SOURCE_EXT'),
    (id:GL_FOG_COORDINATE_EXT;name:'GL_FOG_COORDINATE_EXT'),
    (id:GL_FRAGMENT_DEPTH_EXT;name:'GL_FRAGMENT_DEPTH_EXT'),
    (id:GL_CURRENT_FOG_COORDINATE_EXT;name:'GL_CURRENT_FOG_COORDINATE_EXT'),
    (id:GL_FOG_COORDINATE_ARRAY_TYPE_EXT;name:'GL_FOG_COORDINATE_ARRAY_TYPE_EXT'),
    (id:GL_FOG_COORDINATE_ARRAY_STRIDE_EXT;name:'GL_FOG_COORDINATE_ARRAY_STRIDE_EXT'),
    (id:GL_FOG_COORDINATE_ARRAY_POINTER_EXT;name:'GL_FOG_COORDINATE_ARRAY_POINTER_EXT'),
    (id:GL_FOG_COORDINATE_ARRAY_EXT;name:'GL_FOG_COORDINATE_ARRAY_EXT'),
    (id:GL_SOURCE3_RGB_EXT;name:'GL_SOURCE3_RGB_EXT'),
    (id:GL_SOURCE4_RGB_EXT;name:'GL_SOURCE4_RGB_EXT'),
    (id:GL_SOURCE5_RGB_EXT;name:'GL_SOURCE5_RGB_EXT'),
    (id:GL_SOURCE6_RGB_EXT;name:'GL_SOURCE6_RGB_EXT'),
    (id:GL_SOURCE7_RGB_EXT;name:'GL_SOURCE7_RGB_EXT'),
    (id:GL_SOURCE3_ALPHA_EXT;name:'GL_SOURCE3_ALPHA_EXT'),
    (id:GL_SOURCE4_ALPHA_EXT;name:'GL_SOURCE4_ALPHA_EXT'),
    (id:GL_SOURCE5_ALPHA_EXT;name:'GL_SOURCE5_ALPHA_EXT'),
    (id:GL_SOURCE6_ALPHA_EXT;name:'GL_SOURCE6_ALPHA_EXT'),
    (id:GL_SOURCE7_ALPHA_EXT;name:'GL_SOURCE7_ALPHA_EXT'),
    (id:GL_OPERAND3_RGB_EXT;name:'GL_OPERAND3_RGB_EXT'),
    (id:GL_OPERAND4_RGB_EXT;name:'GL_OPERAND4_RGB_EXT'),
    (id:GL_OPERAND5_RGB_EXT;name:'GL_OPERAND5_RGB_EXT'),
    (id:GL_OPERAND6_RGB_EXT;name:'GL_OPERAND6_RGB_EXT'),
    (id:GL_OPERAND7_RGB_EXT;name:'GL_OPERAND7_RGB_EXT'),
    (id:GL_OPERAND3_ALPHA_EXT;name:'GL_OPERAND3_ALPHA_EXT'),
    (id:GL_OPERAND4_ALPHA_EXT;name:'GL_OPERAND4_ALPHA_EXT'),
    (id:GL_OPERAND5_ALPHA_EXT;name:'GL_OPERAND5_ALPHA_EXT'),
    (id:GL_OPERAND6_ALPHA_EXT;name:'GL_OPERAND6_ALPHA_EXT'),
    (id:GL_OPERAND7_ALPHA_EXT;name:'GL_OPERAND7_ALPHA_EXT'),
    (id:GL_BLEND_DST_RGB_EXT;name:'GL_BLEND_DST_RGB_EXT'),
    (id:GL_BLEND_SRC_RGB_EXT;name:'GL_BLEND_SRC_RGB_EXT'),
    (id:GL_BLEND_DST_ALPHA_EXT;name:'GL_BLEND_DST_ALPHA_EXT'),
    (id:GL_BLEND_SRC_ALPHA_EXT;name:'GL_BLEND_SRC_ALPHA_EXT'),
    (id:GL_NORMAL_MAP_EXT;name:'GL_NORMAL_MAP_EXT'),
    (id:GL_REFLECTION_MAP_EXT;name:'GL_REFLECTION_MAP_EXT'),
    (id:GL_TEXTURE_CUBE_MAP_EXT;name:'GL_TEXTURE_CUBE_MAP_EXT'),
    (id:GL_TEXTURE_BINDING_CUBE_MAP_EXT;name:'GL_TEXTURE_BINDING_CUBE_MAP_EXT'),
    (id:GL_TEXTURE_CUBE_MAP_POSITIVE_X_EXT;name:'GL_TEXTURE_CUBE_MAP_POSITIVE_X_EXT'),
    (id:GL_TEXTURE_CUBE_MAP_NEGATIVE_X_EXT;name:'GL_TEXTURE_CUBE_MAP_NEGATIVE_X_EXT'),
    (id:GL_TEXTURE_CUBE_MAP_POSITIVE_Y_EXT;name:'GL_TEXTURE_CUBE_MAP_POSITIVE_Y_EXT'),
    (id:GL_TEXTURE_CUBE_MAP_NEGATIVE_Y_EXT;name:'GL_TEXTURE_CUBE_MAP_NEGATIVE_Y_EXT'),
    (id:GL_TEXTURE_CUBE_MAP_POSITIVE_Z_EXT;name:'GL_TEXTURE_CUBE_MAP_POSITIVE_Z_EXT'),
    (id:GL_TEXTURE_CUBE_MAP_NEGATIVE_Z_EXT;name:'GL_TEXTURE_CUBE_MAP_NEGATIVE_Z_EXT'),
    (id:GL_PROXY_TEXTURE_CUBE_MAP_EXT;name:'GL_PROXY_TEXTURE_CUBE_MAP_EXT'),
    (id:GL_MAX_CUBE_MAP_TEXTURE_SIZE_EXT;name:'GL_MAX_CUBE_MAP_TEXTURE_SIZE_EXT'),
    (id:GL_MAX_TEXTURE_LOD_BIAS_EXT;name:'GL_MAX_TEXTURE_LOD_BIAS_EXT'),
    (id:GL_TEXTURE_FILTER_CONTROL_EXT;name:'GL_TEXTURE_FILTER_CONTROL_EXT'),
    (id:GL_TEXTURE_LOD_BIAS_EXT;name:'GL_TEXTURE_LOD_BIAS_EXT'),
    (id:GL_TEXTURE_MAX_ANISOTROPY_EXT;name:'GL_TEXTURE_MAX_ANISOTROPY_EXT'),
    (id:GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT;name:'GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT'),
    (id:GL_MAX_SHININESS_NV;name:'GL_MAX_SHININESS_NV'),
    (id:GL_MAX_SPOT_EXPONENT_NV;name:'GL_MAX_SPOT_EXPONENT_NV'),
    (id:GL_VERTEX_ARRAY_RANGE_NV;name:'GL_VERTEX_ARRAY_RANGE_NV'),
    (id:GL_VERTEX_ARRAY_RANGE_LENGTH_NV;name:'GL_VERTEX_ARRAY_RANGE_LENGTH_NV'),
    (id:GL_VERTEX_ARRAY_RANGE_VALID_NV;name:'GL_VERTEX_ARRAY_RANGE_VALID_NV'),
    (id:GL_MAX_VERTEX_ARRAY_RANGE_ELEMENT_NV;name:'GL_MAX_VERTEX_ARRAY_RANGE_ELEMENT_NV'),
    (id:GL_VERTEX_ARRAY_RANGE_POINTER_NV;name:'GL_VERTEX_ARRAY_RANGE_POINTER_NV'),
    (id:GL_VERTEX_ARRAY_RANGE_WITHOUT_FLUSH_NV;name:'GL_VERTEX_ARRAY_RANGE_WITHOUT_FLUSH_NV'),
    (id:GL_REGISTER_COMBINERS_NV;name:'GL_REGISTER_COMBINERS_NV'),
    (id:GL_VARIABLE_A_NV;name:'GL_VARIABLE_A_NV'),
    (id:GL_VARIABLE_B_NV;name:'GL_VARIABLE_B_NV'),
    (id:GL_VARIABLE_C_NV;name:'GL_VARIABLE_C_NV'),
    (id:GL_VARIABLE_D_NV;name:'GL_VARIABLE_D_NV'),
    (id:GL_VARIABLE_E_NV;name:'GL_VARIABLE_E_NV'),
    (id:GL_VARIABLE_F_NV;name:'GL_VARIABLE_F_NV'),
    (id:GL_VARIABLE_G_NV;name:'GL_VARIABLE_G_NV'),
    (id:GL_CONSTANT_COLOR0_NV;name:'GL_CONSTANT_COLOR0_NV'),
    (id:GL_CONSTANT_COLOR1_NV;name:'GL_CONSTANT_COLOR1_NV'),
    (id:GL_PRIMARY_COLOR_NV;name:'GL_PRIMARY_COLOR_NV'),
    (id:GL_SECONDARY_COLOR_NV;name:'GL_SECONDARY_COLOR_NV'),
    (id:GL_SPARE0_NV;name:'GL_SPARE0_NV'),
    (id:GL_SPARE1_NV;name:'GL_SPARE1_NV'),
    (id:GL_DISCARD_NV;name:'GL_DISCARD_NV'),
    (id:GL_E_TIMES_F_NV;name:'GL_E_TIMES_F_NV'),
    (id:GL_SPARE0_PLUS_SECONDARY_COLOR_NV;name:'GL_SPARE0_PLUS_SECONDARY_COLOR_NV'),
    (id:GL_UNSIGNED_IDENTITY_NV;name:'GL_UNSIGNED_IDENTITY_NV'),
    (id:GL_UNSIGNED_INVERT_NV;name:'GL_UNSIGNED_INVERT_NV'),
    (id:GL_EXPAND_NORMAL_NV;name:'GL_EXPAND_NORMAL_NV'),
    (id:GL_EXPAND_NEGATE_NV;name:'GL_EXPAND_NEGATE_NV'),
    (id:GL_HALF_BIAS_NORMAL_NV;name:'GL_HALF_BIAS_NORMAL_NV'),
    (id:GL_HALF_BIAS_NEGATE_NV;name:'GL_HALF_BIAS_NEGATE_NV'),
    (id:GL_SIGNED_IDENTITY_NV;name:'GL_SIGNED_IDENTITY_NV'),
    (id:GL_SIGNED_NEGATE_NV;name:'GL_SIGNED_NEGATE_NV'),
    (id:GL_SCALE_BY_TWO_NV;name:'GL_SCALE_BY_TWO_NV'),
    (id:GL_SCALE_BY_FOUR_NV;name:'GL_SCALE_BY_FOUR_NV'),
    (id:GL_SCALE_BY_ONE_HALF_NV;name:'GL_SCALE_BY_ONE_HALF_NV'),
    (id:GL_BIAS_BY_NEGATIVE_ONE_HALF_NV;name:'GL_BIAS_BY_NEGATIVE_ONE_HALF_NV'),
    (id:GL_COMBINER_INPUT_NV;name:'GL_COMBINER_INPUT_NV'),
    (id:GL_COMBINER_MAPPING_NV;name:'GL_COMBINER_MAPPING_NV'),
    (id:GL_COMBINER_COMPONENT_USAGE_NV;name:'GL_COMBINER_COMPONENT_USAGE_NV'),
    (id:GL_COMBINER_AB_DOT_PRODUCT_NV;name:'GL_COMBINER_AB_DOT_PRODUCT_NV'),
    (id:GL_COMBINER_CD_DOT_PRODUCT_NV;name:'GL_COMBINER_CD_DOT_PRODUCT_NV'),
    (id:GL_COMBINER_MUX_SUM_NV;name:'GL_COMBINER_MUX_SUM_NV'),
    (id:GL_COMBINER_SCALE_NV;name:'GL_COMBINER_SCALE_NV'),
    (id:GL_COMBINER_BIAS_NV;name:'GL_COMBINER_BIAS_NV'),
    (id:GL_COMBINER_AB_OUTPUT_NV;name:'GL_COMBINER_AB_OUTPUT_NV'),
    (id:GL_COMBINER_CD_OUTPUT_NV;name:'GL_COMBINER_CD_OUTPUT_NV'),
    (id:GL_COMBINER_SUM_OUTPUT_NV;name:'GL_COMBINER_SUM_OUTPUT_NV'),
    (id:GL_MAX_GENERAL_COMBINERS_NV;name:'GL_MAX_GENERAL_COMBINERS_NV'),
    (id:GL_NUM_GENERAL_COMBINERS_NV;name:'GL_NUM_GENERAL_COMBINERS_NV'),
    (id:GL_COLOR_SUM_CLAMP_NV;name:'GL_COLOR_SUM_CLAMP_NV'),
    (id:GL_COMBINER0_NV;name:'GL_COMBINER0_NV'),
    (id:GL_COMBINER1_NV;name:'GL_COMBINER1_NV'),
    (id:GL_COMBINER2_NV;name:'GL_COMBINER2_NV'),
    (id:GL_COMBINER3_NV;name:'GL_COMBINER3_NV'),
    (id:GL_COMBINER4_NV;name:'GL_COMBINER4_NV'),
    (id:GL_COMBINER5_NV;name:'GL_COMBINER5_NV'),
    (id:GL_COMBINER6_NV;name:'GL_COMBINER6_NV'),
    (id:GL_COMBINER7_NV;name:'GL_COMBINER7_NV'),
    (id:GL_FOG_DISTANCE_MODE_NV;name:'GL_FOG_DISTANCE_MODE_NV'),
    (id:GL_EYE_RADIAL_NV;name:'GL_EYE_RADIAL_NV'),
    (id:GL_EYE_PLANE_ABSOLUTE_NV;name:'GL_EYE_PLANE_ABSOLUTE_NV'),
    (id:GL_COMPRESSED_RGB_S3TC_DXT1_EXT;name:'GL_COMPRESSED_RGB_S3TC_DXT1_EXT'),
    (id:GL_COMPRESSED_RGBA_S3TC_DXT1_EXT;name:'GL_COMPRESSED_RGBA_S3TC_DXT1_EXT'),
    (id:GL_COMPRESSED_RGBA_S3TC_DXT3_EXT;name:'GL_COMPRESSED_RGBA_S3TC_DXT3_EXT'),
    (id:GL_COMPRESSED_RGBA_S3TC_DXT5_EXT;name:'GL_COMPRESSED_RGBA_S3TC_DXT5_EXT'),
    (id:GL_COMPRESSED_RGB_FXT1_3DFX;name:'GL_COMPRESSED_RGB_FXT1_3DFX'),
    (id:GL_COMPRESSED_RGBA_FXT1_3DFX;name:'GL_COMPRESSED_RGBA_FXT1_3DFX'),
    (id:GL_MULTISAMPLE_3DFX;name:'GL_MULTISAMPLE_3DFX'),
    (id:GL_SAMPLE_BUFFERS_3DFX;name:'GL_SAMPLE_BUFFERS_3DFX'),
    (id:GL_SAMPLES_3DFX;name:'GL_SAMPLES_3DFX'),
    (id:GL_MULTISAMPLE_BIT_3DFX;name:'GL_MULTISAMPLE_BIT_3DFX'),
    (id:GL_MULTISAMPLE_EXT;name:'GL_MULTISAMPLE_EXT'),
    (id:GL_SAMPLE_ALPHA_TO_MASK_EXT;name:'GL_SAMPLE_ALPHA_TO_MASK_EXT'),
    (id:GL_SAMPLE_ALPHA_TO_ONE_EXT;name:'GL_SAMPLE_ALPHA_TO_ONE_EXT'),
    (id:GL_SAMPLE_MASK_EXT;name:'GL_SAMPLE_MASK_EXT'),
    (id:GL_1PASS_EXT;name:'GL_1PASS_EXT'),
    (id:GL_2PASS_0_EXT;name:'GL_2PASS_0_EXT'),
    (id:GL_2PASS_1_EXT;name:'GL_2PASS_1_EXT'),
    (id:GL_4PASS_0_EXT;name:'GL_4PASS_0_EXT'),
    (id:GL_4PASS_1_EXT;name:'GL_4PASS_1_EXT'),
    (id:GL_4PASS_2_EXT;name:'GL_4PASS_2_EXT'),
    (id:GL_4PASS_3_EXT;name:'GL_4PASS_3_EXT'),
    (id:GL_SAMPLE_BUFFERS_EXT;name:'GL_SAMPLE_BUFFERS_EXT'),
    (id:GL_SAMPLES_EXT;name:'GL_SAMPLES_EXT'),
    (id:GL_SAMPLE_MASK_VALUE_EXT;name:'GL_SAMPLE_MASK_VALUE_EXT'),
    (id:GL_SAMPLE_MASK_INVERT_EXT;name:'GL_SAMPLE_MASK_INVERT_EXT'),
    (id:GL_SAMPLE_PATTERN_EXT;name:'GL_SAMPLE_PATTERN_EXT'),
    (id:GL_CLIP_VOLUME_CLIPPING_HINT_EXT;name:'GL_CLIP_VOLUME_CLIPPING_HINT_EXT'),
    (id:GL_TEXTURE_COLOR_WRITEMASK_SGIS;name:'GL_TEXTURE_COLOR_WRITEMASK_SGIS'),
    (id:GL_VERTEX_PROGRAM_NV;name:'GL_VERTEX_PROGRAM_NV'),
    (id:GL_VERTEX_STATE_PROGRAM_NV;name:'GL_VERTEX_STATE_PROGRAM_NV'),
    (id:GL_ATTRIB_ARRAY_SIZE_NV;name:'GL_ATTRIB_ARRAY_SIZE_NV'),
    (id:GL_ATTRIB_ARRAY_STRIDE_NV;name:'GL_ATTRIB_ARRAY_STRIDE_NV'),
    (id:GL_ATTRIB_ARRAY_TYPE_NV;name:'GL_ATTRIB_ARRAY_TYPE_NV'),
    (id:GL_CURRENT_ATTRIB_NV;name:'GL_CURRENT_ATTRIB_NV'),
    (id:GL_PROGRAM_LENGTH_NV;name:'GL_PROGRAM_LENGTH_NV'),
    (id:GL_PROGRAM_STRING_NV;name:'GL_PROGRAM_STRING_NV'),
    (id:GL_MODELVIEW_PROJECTION_NV;name:'GL_MODELVIEW_PROJECTION_NV'),
    (id:GL_IDENTITY_NV;name:'GL_IDENTITY_NV'),
    (id:GL_INVERSE_NV;name:'GL_INVERSE_NV'),
    (id:GL_TRANSPOSE_NV;name:'GL_TRANSPOSE_NV'),
    (id:GL_INVERSE_TRANSPOSE_NV;name:'GL_INVERSE_TRANSPOSE_NV'),
    (id:GL_MAX_TRACK_MATRIX_STACK_DEPTH_NV;name:'GL_MAX_TRACK_MATRIX_STACK_DEPTH_NV'),
    (id:GL_MAX_TRACK_MATRICES_NV;name:'GL_MAX_TRACK_MATRICES_NV'),
    (id:GL_MATRIX0_NV;name:'GL_MATRIX0_NV'),
    (id:GL_MATRIX1_NV;name:'GL_MATRIX1_NV'),
    (id:GL_MATRIX2_NV;name:'GL_MATRIX2_NV'),
    (id:GL_MATRIX3_NV;name:'GL_MATRIX3_NV'),
    (id:GL_MATRIX4_NV;name:'GL_MATRIX4_NV'),
    (id:GL_MATRIX5_NV;name:'GL_MATRIX5_NV'),
    (id:GL_MATRIX6_NV;name:'GL_MATRIX6_NV'),
    (id:GL_MATRIX7_NV;name:'GL_MATRIX7_NV'),
    (id:GL_CURRENT_MATRIX_STACK_DEPTH_NV;name:'GL_CURRENT_MATRIX_STACK_DEPTH_NV'),
    (id:GL_CURRENT_MATRIX_NV;name:'GL_CURRENT_MATRIX_NV'),
    (id:GL_VERTEX_PROGRAM_POINT_SIZE_NV;name:'GL_VERTEX_PROGRAM_POINT_SIZE_NV'),
    (id:GL_VERTEX_PROGRAM_TWO_SIDE_NV;name:'GL_VERTEX_PROGRAM_TWO_SIDE_NV'),
    (id:GL_PROGRAM_PARAMETER_NV;name:'GL_PROGRAM_PARAMETER_NV'),
    (id:GL_ATTRIB_ARRAY_POINTER_NV;name:'GL_ATTRIB_ARRAY_POINTER_NV'),
    (id:GL_PROGRAM_TARGET_NV;name:'GL_PROGRAM_TARGET_NV'),
    (id:GL_PROGRAM_RESIDENT_NV;name:'GL_PROGRAM_RESIDENT_NV'),
    (id:GL_TRACK_MATRIX_NV;name:'GL_TRACK_MATRIX_NV'),
    (id:GL_TRACK_MATRIX_TRANSFORM_NV;name:'GL_TRACK_MATRIX_TRANSFORM_NV'),
    (id:GL_VERTEX_PROGRAM_BINDING_NV;name:'GL_VERTEX_PROGRAM_BINDING_NV'),
    (id:GL_PROGRAM_ERROR_POSITION_NV;name:'GL_PROGRAM_ERROR_POSITION_NV'),
    (id:GL_VERTEX_ATTRIB_ARRAY0_NV;name:'GL_VERTEX_ATTRIB_ARRAY0_NV'),
    (id:GL_VERTEX_ATTRIB_ARRAY1_NV;name:'GL_VERTEX_ATTRIB_ARRAY1_NV'),
    (id:GL_VERTEX_ATTRIB_ARRAY2_NV;name:'GL_VERTEX_ATTRIB_ARRAY2_NV'),
    (id:GL_VERTEX_ATTRIB_ARRAY3_NV;name:'GL_VERTEX_ATTRIB_ARRAY3_NV'),
    (id:GL_VERTEX_ATTRIB_ARRAY4_NV;name:'GL_VERTEX_ATTRIB_ARRAY4_NV'),
    (id:GL_VERTEX_ATTRIB_ARRAY5_NV;name:'GL_VERTEX_ATTRIB_ARRAY5_NV'),
    (id:GL_VERTEX_ATTRIB_ARRAY6_NV;name:'GL_VERTEX_ATTRIB_ARRAY6_NV'),
    (id:GL_VERTEX_ATTRIB_ARRAY7_NV;name:'GL_VERTEX_ATTRIB_ARRAY7_NV'),
    (id:GL_VERTEX_ATTRIB_ARRAY8_NV;name:'GL_VERTEX_ATTRIB_ARRAY8_NV'),
    (id:GL_VERTEX_ATTRIB_ARRAY9_NV;name:'GL_VERTEX_ATTRIB_ARRAY9_NV'),
    (id:GL_VERTEX_ATTRIB_ARRAY10_NV;name:'GL_VERTEX_ATTRIB_ARRAY10_NV'),
    (id:GL_VERTEX_ATTRIB_ARRAY11_NV;name:'GL_VERTEX_ATTRIB_ARRAY11_NV'),
    (id:GL_VERTEX_ATTRIB_ARRAY12_NV;name:'GL_VERTEX_ATTRIB_ARRAY12_NV'),
    (id:GL_VERTEX_ATTRIB_ARRAY13_NV;name:'GL_VERTEX_ATTRIB_ARRAY13_NV'),
    (id:GL_VERTEX_ATTRIB_ARRAY14_NV;name:'GL_VERTEX_ATTRIB_ARRAY14_NV'),
    (id:GL_VERTEX_ATTRIB_ARRAY15_NV;name:'GL_VERTEX_ATTRIB_ARRAY15_NV'),
    (id:GL_MAP1_VERTEX_ATTRIB0_4_NV;name:'GL_MAP1_VERTEX_ATTRIB0_4_NV'),
    (id:GL_MAP1_VERTEX_ATTRIB1_4_NV;name:'GL_MAP1_VERTEX_ATTRIB1_4_NV'),
    (id:GL_MAP1_VERTEX_ATTRIB2_4_NV;name:'GL_MAP1_VERTEX_ATTRIB2_4_NV'),
    (id:GL_MAP1_VERTEX_ATTRIB3_4_NV;name:'GL_MAP1_VERTEX_ATTRIB3_4_NV'),
    (id:GL_MAP1_VERTEX_ATTRIB4_4_NV;name:'GL_MAP1_VERTEX_ATTRIB4_4_NV'),
    (id:GL_MAP1_VERTEX_ATTRIB5_4_NV;name:'GL_MAP1_VERTEX_ATTRIB5_4_NV'),
    (id:GL_MAP1_VERTEX_ATTRIB6_4_NV;name:'GL_MAP1_VERTEX_ATTRIB6_4_NV'),
    (id:GL_MAP1_VERTEX_ATTRIB7_4_NV;name:'GL_MAP1_VERTEX_ATTRIB7_4_NV'),
    (id:GL_MAP1_VERTEX_ATTRIB8_4_NV;name:'GL_MAP1_VERTEX_ATTRIB8_4_NV'),
    (id:GL_MAP1_VERTEX_ATTRIB9_4_NV;name:'GL_MAP1_VERTEX_ATTRIB9_4_NV'),
    (id:GL_MAP1_VERTEX_ATTRIB10_4_NV;name:'GL_MAP1_VERTEX_ATTRIB10_4_NV'),
    (id:GL_MAP1_VERTEX_ATTRIB11_4_NV;name:'GL_MAP1_VERTEX_ATTRIB11_4_NV'),
    (id:GL_MAP1_VERTEX_ATTRIB12_4_NV;name:'GL_MAP1_VERTEX_ATTRIB12_4_NV'),
    (id:GL_MAP1_VERTEX_ATTRIB13_4_NV;name:'GL_MAP1_VERTEX_ATTRIB13_4_NV'),
    (id:GL_MAP1_VERTEX_ATTRIB14_4_NV;name:'GL_MAP1_VERTEX_ATTRIB14_4_NV'),
    (id:GL_MAP1_VERTEX_ATTRIB15_4_NV;name:'GL_MAP1_VERTEX_ATTRIB15_4_NV'),
    (id:GL_MAP2_VERTEX_ATTRIB0_4_NV;name:'GL_MAP2_VERTEX_ATTRIB0_4_NV'),
    (id:GL_MAP2_VERTEX_ATTRIB1_4_NV;name:'GL_MAP2_VERTEX_ATTRIB1_4_NV'),
    (id:GL_MAP2_VERTEX_ATTRIB2_4_NV;name:'GL_MAP2_VERTEX_ATTRIB2_4_NV'),
    (id:GL_MAP2_VERTEX_ATTRIB3_4_NV;name:'GL_MAP2_VERTEX_ATTRIB3_4_NV'),
    (id:GL_MAP2_VERTEX_ATTRIB4_4_NV;name:'GL_MAP2_VERTEX_ATTRIB4_4_NV'),
    (id:GL_MAP2_VERTEX_ATTRIB5_4_NV;name:'GL_MAP2_VERTEX_ATTRIB5_4_NV'),
    (id:GL_MAP2_VERTEX_ATTRIB6_4_NV;name:'GL_MAP2_VERTEX_ATTRIB6_4_NV'),
    (id:GL_MAP2_VERTEX_ATTRIB7_4_NV;name:'GL_MAP2_VERTEX_ATTRIB7_4_NV'),
    (id:GL_MAP2_VERTEX_ATTRIB8_4_NV;name:'GL_MAP2_VERTEX_ATTRIB8_4_NV'),
    (id:GL_MAP2_VERTEX_ATTRIB9_4_NV;name:'GL_MAP2_VERTEX_ATTRIB9_4_NV'),
    (id:GL_MAP2_VERTEX_ATTRIB10_4_NV;name:'GL_MAP2_VERTEX_ATTRIB10_4_NV'),
    (id:GL_MAP2_VERTEX_ATTRIB11_4_NV;name:'GL_MAP2_VERTEX_ATTRIB11_4_NV'),
    (id:GL_MAP2_VERTEX_ATTRIB12_4_NV;name:'GL_MAP2_VERTEX_ATTRIB12_4_NV'),
    (id:GL_MAP2_VERTEX_ATTRIB13_4_NV;name:'GL_MAP2_VERTEX_ATTRIB13_4_NV'),
    (id:GL_MAP2_VERTEX_ATTRIB14_4_NV;name:'GL_MAP2_VERTEX_ATTRIB14_4_NV'),
    (id:GL_MAP2_VERTEX_ATTRIB15_4_NV;name:'GL_MAP2_VERTEX_ATTRIB15_4_NV'),
    (id:GL_MULTISAMPLE_FILTER_HINT_NV;name:'GL_MULTISAMPLE_FILTER_HINT_NV'),
    (id:WGL_NUMBER_PIXEL_FORMATS_ARB;name:'WGL_NUMBER_PIXEL_FORMATS_ARB'),
    (id:WGL_DRAW_TO_WINDOW_ARB;name:'WGL_DRAW_TO_WINDOW_ARB'),
    (id:WGL_DRAW_TO_BITMAP_ARB;name:'WGL_DRAW_TO_BITMAP_ARB'),
    (id:WGL_ACCELERATION_ARB;name:'WGL_ACCELERATION_ARB'),
    (id:WGL_NEED_PALETTE_ARB;name:'WGL_NEED_PALETTE_ARB'),
    (id:WGL_NEED_SYSTEM_PALETTE_ARB;name:'WGL_NEED_SYSTEM_PALETTE_ARB'),
    (id:WGL_SWAP_LAYER_BUFFERS_ARB;name:'WGL_SWAP_LAYER_BUFFERS_ARB'),
    (id:WGL_SWAP_METHOD_ARB;name:'WGL_SWAP_METHOD_ARB'),
    (id:WGL_NUMBER_OVERLAYS_ARB;name:'WGL_NUMBER_OVERLAYS_ARB'),
    (id:WGL_NUMBER_UNDERLAYS_ARB;name:'WGL_NUMBER_UNDERLAYS_ARB'),
    (id:WGL_TRANSPARENT_ARB;name:'WGL_TRANSPARENT_ARB'),
    (id:WGL_TRANSPARENT_RED_VALUE_ARB;name:'WGL_TRANSPARENT_RED_VALUE_ARB'),
    (id:WGL_TRANSPARENT_GREEN_VALUE_ARB;name:'WGL_TRANSPARENT_GREEN_VALUE_ARB'),
    (id:WGL_TRANSPARENT_BLUE_VALUE_ARB;name:'WGL_TRANSPARENT_BLUE_VALUE_ARB'),
    (id:WGL_TRANSPARENT_ALPHA_VALUE_ARB;name:'WGL_TRANSPARENT_ALPHA_VALUE_ARB'),
    (id:WGL_TRANSPARENT_INDEX_VALUE_ARB;name:'WGL_TRANSPARENT_INDEX_VALUE_ARB'),
    (id:WGL_SHARE_DEPTH_ARB;name:'WGL_SHARE_DEPTH_ARB'),
    (id:WGL_SHARE_STENCIL_ARB;name:'WGL_SHARE_STENCIL_ARB'),
    (id:WGL_SHARE_ACCUM_ARB;name:'WGL_SHARE_ACCUM_ARB'),
    (id:WGL_SUPPORT_GDI_ARB;name:'WGL_SUPPORT_GDI_ARB'),
    (id:WGL_SUPPORT_OPENGL_ARB;name:'WGL_SUPPORT_OPENGL_ARB'),
    (id:WGL_DOUBLE_BUFFER_ARB;name:'WGL_DOUBLE_BUFFER_ARB'),
    (id:WGL_STEREO_ARB;name:'WGL_STEREO_ARB'),
    (id:WGL_PIXEL_TYPE_ARB;name:'WGL_PIXEL_TYPE_ARB'),
    (id:WGL_COLOR_BITS_ARB;name:'WGL_COLOR_BITS_ARB'),
    (id:WGL_RED_BITS_ARB;name:'WGL_RED_BITS_ARB'),
    (id:WGL_RED_SHIFT_ARB;name:'WGL_RED_SHIFT_ARB'),
    (id:WGL_GREEN_BITS_ARB;name:'WGL_GREEN_BITS_ARB'),
    (id:WGL_GREEN_SHIFT_ARB;name:'WGL_GREEN_SHIFT_ARB'),
    (id:WGL_BLUE_BITS_ARB;name:'WGL_BLUE_BITS_ARB'),
    (id:WGL_BLUE_SHIFT_ARB;name:'WGL_BLUE_SHIFT_ARB'),
    (id:WGL_ALPHA_BITS_ARB;name:'WGL_ALPHA_BITS_ARB'),
    (id:WGL_ALPHA_SHIFT_ARB;name:'WGL_ALPHA_SHIFT_ARB'),
    (id:WGL_ACCUM_BITS_ARB;name:'WGL_ACCUM_BITS_ARB'),
    (id:WGL_ACCUM_RED_BITS_ARB;name:'WGL_ACCUM_RED_BITS_ARB'),
    (id:WGL_ACCUM_GREEN_BITS_ARB;name:'WGL_ACCUM_GREEN_BITS_ARB'),
    (id:WGL_ACCUM_BLUE_BITS_ARB;name:'WGL_ACCUM_BLUE_BITS_ARB'),
    (id:WGL_ACCUM_ALPHA_BITS_ARB;name:'WGL_ACCUM_ALPHA_BITS_ARB'),
    (id:WGL_DEPTH_BITS_ARB;name:'WGL_DEPTH_BITS_ARB'),
    (id:WGL_STENCIL_BITS_ARB;name:'WGL_STENCIL_BITS_ARB'),
    (id:WGL_AUX_BUFFERS_ARB;name:'WGL_AUX_BUFFERS_ARB'),
    (id:WGL_NO_ACCELERATION_ARB;name:'WGL_NO_ACCELERATION_ARB'),
    (id:WGL_GENERIC_ACCELERATION_ARB;name:'WGL_GENERIC_ACCELERATION_ARB'),
    (id:WGL_FULL_ACCELERATION_ARB;name:'WGL_FULL_ACCELERATION_ARB'),
    (id:WGL_SWAP_EXCHANGE_ARB;name:'WGL_SWAP_EXCHANGE_ARB'),
    (id:WGL_SWAP_COPY_ARB;name:'WGL_SWAP_COPY_ARB'),
    (id:WGL_SWAP_UNDEFINED_ARB;name:'WGL_SWAP_UNDEFINED_ARB'),
    (id:WGL_TYPE_RGBA_ARB;name:'WGL_TYPE_RGBA_ARB'),
    (id:WGL_TYPE_COLORINDEX_ARB;name:'WGL_TYPE_COLORINDEX_ARB'),
    (id:WGL_FLOAT_COMPONENTS_NV;name:'WGL_FLOAT_COMPONENTS_NV'),
    (id:WGL_BIND_TO_TEXTURE_RECTANGLE_FLOAT_R_NV;name:'WGL_BIND_TO_TEXTURE_RECTANGLE_FLOAT_R_NV'),
    (id:WGL_BIND_TO_TEXTURE_RECTANGLE_FLOAT_RG_NV;name:'WGL_BIND_TO_TEXTURE_RECTANGLE_FLOAT_RG_NV'),
    (id:WGL_BIND_TO_TEXTURE_RECTANGLE_FLOAT_RGB_NV;name:'WGL_BIND_TO_TEXTURE_RECTANGLE_FLOAT_RGB_NV'),
    (id:WGL_BIND_TO_TEXTURE_RECTANGLE_FLOAT_RGBA_NV;name:'WGL_BIND_TO_TEXTURE_RECTANGLE_FLOAT_RGBA_NV'),
    (id:WGL_TEXTURE_FLOAT_R_NV;name:'WGL_TEXTURE_FLOAT_R_NV'),
    (id:WGL_TEXTURE_FLOAT_RG_NV;name:'WGL_TEXTURE_FLOAT_RG_NV'),
    (id:WGL_TEXTURE_FLOAT_RGB_NV;name:'WGL_TEXTURE_FLOAT_RGB_NV'),
    (id:WGL_TEXTURE_FLOAT_RGBA_NV;name:'WGL_TEXTURE_FLOAT_RGBA_NV'),
    (id:GL_FLOAT_R_NV;name:'GL_FLOAT_R_NV'),
    (id:GL_FLOAT_RG_NV;name:'GL_FLOAT_RG_NV'),
    (id:GL_FLOAT_RGB_NV;name:'GL_FLOAT_RGB_NV'),
    (id:GL_FLOAT_RGBA_NV;name:'GL_FLOAT_RGBA_NV'),
    (id:GL_FLOAT_R16_NV;name:'GL_FLOAT_R16_NV'),
    (id:GL_FLOAT_R32_NV;name:'GL_FLOAT_R32_NV'),
    (id:GL_FLOAT_RG16_NV;name:'GL_FLOAT_RG16_NV'),
    (id:GL_FLOAT_RG32_NV;name:'GL_FLOAT_RG32_NV'),
    (id:GL_FLOAT_RGB16_NV;name:'GL_FLOAT_RGB16_NV'),
    (id:GL_FLOAT_RGB32_NV;name:'GL_FLOAT_RGB32_NV'),
    (id:GL_FLOAT_RGBA16_NV;name:'GL_FLOAT_RGBA16_NV'),
    (id:GL_FLOAT_RGBA32_NV;name:'GL_FLOAT_RGBA32_NV'),
    (id:GL_TEXTURE_FLOAT_COMPONENTS_NV;name:'GL_TEXTURE_FLOAT_COMPONENTS_NV'),
    (id:GL_FLOAT_CLEAR_COLOR_VALUE_NV;name:'GL_FLOAT_CLEAR_COLOR_VALUE_NV'),
    (id:GL_FLOAT_RGBA_MODE_NV;name:'GL_FLOAT_RGBA_MODE_NV'),
    (id:WGL_TYPE_RGBA_FLOAT_ATI;name:'WGL_TYPE_RGBA_FLOAT_ATI'),
    (id:GL_TYPE_RGBA_FLOAT_ATI;name:'GL_TYPE_RGBA_FLOAT_ATI'),
    (id:GL_COLOR_CLEAR_UNCLAMPED_VALUE_ATI;name:'GL_COLOR_CLEAR_UNCLAMPED_VALUE_ATI'),
    (id:GL_RGBA_FLOAT32_ATI;name:'GL_RGBA_FLOAT32_ATI'),
    (id:GL_RGB_FLOAT32_ATI;name:'GL_RGB_FLOAT32_ATI'),
    (id:GL_ALPHA_FLOAT32_ATI;name:'GL_ALPHA_FLOAT32_ATI'),
    (id:GL_INTENSITY_FLOAT32_ATI;name:'GL_INTENSITY_FLOAT32_ATI'),
    (id:GL_LUMINANCE_FLOAT32_ATI;name:'GL_LUMINANCE_FLOAT32_ATI'),
    (id:GL_LUMINANCE_ALPHA_FLOAT32_ATI;name:'GL_LUMINANCE_ALPHA_FLOAT32_ATI'),
    (id:GL_RGBA_FLOAT16_ATI;name:'GL_RGBA_FLOAT16_ATI'),
    (id:GL_RGB_FLOAT16_ATI;name:'GL_RGB_FLOAT16_ATI'),
    (id:GL_ALPHA_FLOAT16_ATI;name:'GL_ALPHA_FLOAT16_ATI'),
    (id:GL_INTENSITY_FLOAT16_ATI;name:'GL_INTENSITY_FLOAT16_ATI'),
    (id:GL_LUMINANCE_FLOAT16_ATI;name:'GL_LUMINANCE_FLOAT16_ATI'),
    (id:GL_LUMINANCE_ALPHA_FLOAT16_ATI;name:'GL_LUMINANCE_ALPHA_FLOAT16_ATI'),
    (id:GL_MAX_DRAW_BUFFERS_ATI;name:'GL_MAX_DRAW_BUFFERS_ATI'),
    (id:GL_DRAW_BUFFER0_ATI;name:'GL_DRAW_BUFFER0_ATI'),
    (id:GL_DRAW_BUFFER1_ATI;name:'GL_DRAW_BUFFER1_ATI'),
    (id:GL_DRAW_BUFFER2_ATI;name:'GL_DRAW_BUFFER2_ATI'),
    (id:GL_DRAW_BUFFER3_ATI;name:'GL_DRAW_BUFFER3_ATI'),
    (id:GL_DRAW_BUFFER4_ATI;name:'GL_DRAW_BUFFER4_ATI'),
    (id:GL_DRAW_BUFFER5_ATI;name:'GL_DRAW_BUFFER5_ATI'),
    (id:GL_DRAW_BUFFER6_ATI;name:'GL_DRAW_BUFFER6_ATI'),
    (id:GL_DRAW_BUFFER7_ATI;name:'GL_DRAW_BUFFER7_ATI'),
    (id:GL_DRAW_BUFFER8_ATI;name:'GL_DRAW_BUFFER8_ATI'),
    (id:GL_DRAW_BUFFER9_ATI;name:'GL_DRAW_BUFFER9_ATI'),
    (id:GL_DRAW_BUFFER10_ATI;name:'GL_DRAW_BUFFER10_ATI'),
    (id:GL_DRAW_BUFFER11_ATI;name:'GL_DRAW_BUFFER11_ATI'),
    (id:GL_DRAW_BUFFER12_ATI;name:'GL_DRAW_BUFFER12_ATI'),
    (id:GL_DRAW_BUFFER13_ATI;name:'GL_DRAW_BUFFER13_ATI'),
    (id:GL_DRAW_BUFFER14_ATI;name:'GL_DRAW_BUFFER14_ATI'),
    (id:GL_DRAW_BUFFER15_ATI;name:'GL_DRAW_BUFFER15_ATI'),
    (id:WGL_DRAW_TO_PBUFFER_ARB;name:'WGL_DRAW_TO_PBUFFER_ARB'),
    (id:WGL_MAX_PBUFFER_PIXELS_ARB;name:'WGL_MAX_PBUFFER_PIXELS_ARB'),
    (id:WGL_MAX_PBUFFER_WIDTH_ARB;name:'WGL_MAX_PBUFFER_WIDTH_ARB'),
    (id:WGL_MAX_PBUFFER_HEIGHT_ARB;name:'WGL_MAX_PBUFFER_HEIGHT_ARB'),
    (id:WGL_PBUFFER_LARGEST_ARB;name:'WGL_PBUFFER_LARGEST_ARB'),
    (id:WGL_PBUFFER_WIDTH_ARB;name:'WGL_PBUFFER_WIDTH_ARB'),
    (id:WGL_PBUFFER_HEIGHT_ARB;name:'WGL_PBUFFER_HEIGHT_ARB'),
    (id:WGL_PBUFFER_LOST_ARB;name:'WGL_PBUFFER_LOST_ARB'),
    (id:WGL_FRONT_COLOR_BUFFER_BIT_ARB;name:'WGL_FRONT_COLOR_BUFFER_BIT_ARB'),
    (id:WGL_BACK_COLOR_BUFFER_BIT_ARB;name:'WGL_BACK_COLOR_BUFFER_BIT_ARB'),
    (id:WGL_DEPTH_BUFFER_BIT_ARB;name:'WGL_DEPTH_BUFFER_BIT_ARB'),
    (id:WGL_STENCIL_BUFFER_BIT_ARB;name:'WGL_STENCIL_BUFFER_BIT_ARB'),
    (id:GLU_INVALID_ENUM;name:'GLU_INVALID_ENUM'),
    (id:GLU_INVALID_VALUE;name:'GLU_INVALID_VALUE'),
    (id:GLU_OUT_OF_MEMORY;name:'GLU_OUT_OF_MEMORY'),
    (id:GLU_INCOMPATIBLE_GL_VERSION;name:'GLU_INCOMPATIBLE_GL_VERSION'),
    (id:GLU_VERSION;name:'GLU_VERSION'),
    (id:GLU_EXTENSIONS;name:'GLU_EXTENSIONS'),
    (id:GLU_TRUE;name:'GLU_TRUE'),
    (id:GLU_FALSE;name:'GLU_FALSE'),
    (id:GLU_SMOOTH;name:'GLU_SMOOTH'),
    (id:GLU_FLAT;name:'GLU_FLAT'),
    (id:GLU_NONE;name:'GLU_NONE'),
    (id:GLU_POINT;name:'GLU_POINT'),
    (id:GLU_LINE;name:'GLU_LINE'),
    (id:GLU_FILL;name:'GLU_FILL'),
    (id:GLU_SILHOUETTE;name:'GLU_SILHOUETTE'),
    (id:GLU_OUTSIDE;name:'GLU_OUTSIDE'),
    (id:GLU_INSIDE;name:'GLU_INSIDE'),
    (id:GLU_TESS_WINDING_RULE;name:'GLU_TESS_WINDING_RULE'),
    (id:GLU_TESS_BOUNDARY_ONLY;name:'GLU_TESS_BOUNDARY_ONLY'),
    (id:GLU_TESS_TOLERANCE;name:'GLU_TESS_TOLERANCE'),
    (id:GLU_TESS_WINDING_ODD;name:'GLU_TESS_WINDING_ODD'),
    (id:GLU_TESS_WINDING_NONZERO;name:'GLU_TESS_WINDING_NONZERO'),
    (id:GLU_TESS_WINDING_POSITIVE;name:'GLU_TESS_WINDING_POSITIVE'),
    (id:GLU_TESS_WINDING_NEGATIVE;name:'GLU_TESS_WINDING_NEGATIVE'),
    (id:GLU_TESS_WINDING_ABS_GEQ_TWO;name:'GLU_TESS_WINDING_ABS_GEQ_TWO'),
    (id:GLU_TESS_BEGIN;name:'GLU_TESS_BEGIN'),
    (id:GLU_TESS_VERTEX;name:'GLU_TESS_VERTEX'),
    (id:GLU_TESS_END;name:'GLU_TESS_END'),
    (id:GLU_TESS_ERROR;name:'GLU_TESS_ERROR'),
    (id:GLU_TESS_EDGE_FLAG;name:'GLU_TESS_EDGE_FLAG'),
    (id:GLU_TESS_COMBINE;name:'GLU_TESS_COMBINE'),
    (id:GLU_TESS_BEGIN_DATA;name:'GLU_TESS_BEGIN_DATA'),
    (id:GLU_TESS_VERTEX_DATA;name:'GLU_TESS_VERTEX_DATA'),
    (id:GLU_TESS_END_DATA;name:'GLU_TESS_END_DATA'),
    (id:GLU_TESS_ERROR_DATA;name:'GLU_TESS_ERROR_DATA'),
    (id:GLU_TESS_EDGE_FLAG_DATA;name:'GLU_TESS_EDGE_FLAG_DATA'),
    (id:GLU_TESS_COMBINE_DATA;name:'GLU_TESS_COMBINE_DATA'),
    (id:GLU_TESS_ERROR1;name:'GLU_TESS_ERROR1'),
    (id:GLU_TESS_ERROR2;name:'GLU_TESS_ERROR2'),
    (id:GLU_TESS_ERROR3;name:'GLU_TESS_ERROR3'),
    (id:GLU_TESS_ERROR4;name:'GLU_TESS_ERROR4'),
    (id:GLU_TESS_ERROR5;name:'GLU_TESS_ERROR5'),
    (id:GLU_TESS_ERROR6;name:'GLU_TESS_ERROR6'),
    (id:GLU_TESS_ERROR7;name:'GLU_TESS_ERROR7'),
    (id:GLU_TESS_ERROR8;name:'GLU_TESS_ERROR8'),
    (id:GLU_TESS_MISSING_BEGIN_POLYGON;name:'GLU_TESS_MISSING_BEGIN_POLYGON'),
    (id:GLU_TESS_MISSING_BEGIN_CONTOUR;name:'GLU_TESS_MISSING_BEGIN_CONTOUR'),
    (id:GLU_TESS_MISSING_END_POLYGON;name:'GLU_TESS_MISSING_END_POLYGON'),
    (id:GLU_TESS_MISSING_END_CONTOUR;name:'GLU_TESS_MISSING_END_CONTOUR'),
    (id:GLU_TESS_COORD_TOO_LARGE;name:'GLU_TESS_COORD_TOO_LARGE'),
    (id:GLU_TESS_NEED_COMBINE_CALLBACK;name:'GLU_TESS_NEED_COMBINE_CALLBACK'),
    (id:GLU_AUTO_LOAD_MATRIX;name:'GLU_AUTO_LOAD_MATRIX'),
    (id:GLU_CULLING;name:'GLU_CULLING'),
    (id:GLU_SAMPLING_TOLERANCE;name:'GLU_SAMPLING_TOLERANCE'),
    (id:GLU_DISPLAY_MODE;name:'GLU_DISPLAY_MODE'),
    (id:GLU_PARAMETRIC_TOLERANCE;name:'GLU_PARAMETRIC_TOLERANCE'),
    (id:GLU_SAMPLING_METHOD;name:'GLU_SAMPLING_METHOD'),
    (id:GLU_U_STEP;name:'GLU_U_STEP'),
    (id:GLU_V_STEP;name:'GLU_V_STEP'),
    (id:GLU_PATH_LENGTH;name:'GLU_PATH_LENGTH'),
    (id:GLU_PARAMETRIC_ERROR;name:'GLU_PARAMETRIC_ERROR'),
    (id:GLU_DOMAIN_DISTANCE;name:'GLU_DOMAIN_DISTANCE'),
    (id:GLU_MAP1_TRIM_2;name:'GLU_MAP1_TRIM_2'),
    (id:GLU_MAP1_TRIM_3;name:'GLU_MAP1_TRIM_3'),
    (id:GLU_OUTLINE_POLYGON;name:'GLU_OUTLINE_POLYGON'),
    (id:GLU_OUTLINE_PATCH;name:'GLU_OUTLINE_PATCH'),
    (id:GLU_NURBS_ERROR1;name:'GLU_NURBS_ERROR1'),
    (id:GLU_NURBS_ERROR2;name:'GLU_NURBS_ERROR2'),
    (id:GLU_NURBS_ERROR3;name:'GLU_NURBS_ERROR3'),
    (id:GLU_NURBS_ERROR4;name:'GLU_NURBS_ERROR4'),
    (id:GLU_NURBS_ERROR5;name:'GLU_NURBS_ERROR5'),
    (id:GLU_NURBS_ERROR6;name:'GLU_NURBS_ERROR6'),
    (id:GLU_NURBS_ERROR7;name:'GLU_NURBS_ERROR7'),
    (id:GLU_NURBS_ERROR8;name:'GLU_NURBS_ERROR8'),
    (id:GLU_NURBS_ERROR9;name:'GLU_NURBS_ERROR9'),
    (id:GLU_NURBS_ERROR10;name:'GLU_NURBS_ERROR10'),
    (id:GLU_NURBS_ERROR11;name:'GLU_NURBS_ERROR11'),
    (id:GLU_NURBS_ERROR12;name:'GLU_NURBS_ERROR12'),
    (id:GLU_NURBS_ERROR13;name:'GLU_NURBS_ERROR13'),
    (id:GLU_NURBS_ERROR14;name:'GLU_NURBS_ERROR14'),
    (id:GLU_NURBS_ERROR15;name:'GLU_NURBS_ERROR15'),
    (id:GLU_NURBS_ERROR16;name:'GLU_NURBS_ERROR16'),
    (id:GLU_NURBS_ERROR17;name:'GLU_NURBS_ERROR17'),
    (id:GLU_NURBS_ERROR18;name:'GLU_NURBS_ERROR18'),
    (id:GLU_NURBS_ERROR19;name:'GLU_NURBS_ERROR19'),
    (id:GLU_NURBS_ERROR20;name:'GLU_NURBS_ERROR20'),
    (id:GLU_NURBS_ERROR21;name:'GLU_NURBS_ERROR21'),
    (id:GLU_NURBS_ERROR22;name:'GLU_NURBS_ERROR22'),
    (id:GLU_NURBS_ERROR23;name:'GLU_NURBS_ERROR23'),
    (id:GLU_NURBS_ERROR24;name:'GLU_NURBS_ERROR24'),
    (id:GLU_NURBS_ERROR25;name:'GLU_NURBS_ERROR25'),
    (id:GLU_NURBS_ERROR26;name:'GLU_NURBS_ERROR26'),
    (id:GLU_NURBS_ERROR27;name:'GLU_NURBS_ERROR27'),
    (id:GLU_NURBS_ERROR28;name:'GLU_NURBS_ERROR28'),
    (id:GLU_NURBS_ERROR29;name:'GLU_NURBS_ERROR29'),
    (id:GLU_NURBS_ERROR30;name:'GLU_NURBS_ERROR30'),
    (id:GLU_NURBS_ERROR31;name:'GLU_NURBS_ERROR31'),
    (id:GLU_NURBS_ERROR32;name:'GLU_NURBS_ERROR32'),
    (id:GLU_NURBS_ERROR33;name:'GLU_NURBS_ERROR33'),
    (id:GLU_NURBS_ERROR34;name:'GLU_NURBS_ERROR34'),
    (id:GLU_NURBS_ERROR35;name:'GLU_NURBS_ERROR35'),
    (id:GLU_NURBS_ERROR36;name:'GLU_NURBS_ERROR36'),
    (id:GLU_NURBS_ERROR37;name:'GLU_NURBS_ERROR37')
  );

function glEnumToStr(const AEnum:GLenum):AnsiString;
function glStrToEnum(AName:AnsiString):GLenum;

type
  GlException=class(Exception);

// --------- own helper stuff ---------------------------------------

procedure glTexGenSimplef(const texGenMode:TGLEnum;const s,t:single;const r:Single=1);
function glGetErrorText:string;
procedure glRaiseError(const location:string='');

procedure glColor3(const clr:TColor);
procedure glColor4(const clr:TColor);
procedure glClearColor(const clr:TColor);overload;

procedure glRect(const r:TRect);
procedure glDrawCube(const BeginEnd:boolean=true);

procedure gluLookAt(const eye, center, up: TV3f); overload;

procedure glVertex(const v:TV2f);inline;overload;
procedure glVertex(const v:TV3f);inline;overload;

procedure glTranslateF(const v:TV3f);inline;overload;

type
  IGLList=interface
    function GetHandle:GLEnum;
    property Handle:TGLEnum read GetHandle;
    procedure Call;
    Procedure New(const ARun:boolean=false);
    procedure EndList;
    procedure Delete;
  end;

  TGLList=class(TInterfacedObject,IGlList)
  private
    FHandle:GLEnum;
  public
    destructor Destroy;override;
    function GetHandle:GLEnum;
    property Handle:TGLEnum read GetHandle;
    procedure Call;
    Procedure New(const ARun:boolean=false);
    procedure EndList;
    procedure Delete;
  end;

function glNewList(const ARun:boolean=false):IGLList; overload;

// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------
implementation
// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------


// ************** Windows specific ********************
resourcestring
  SDefaultGLLibrary= 'OpenGL32.dll';
  SDefaultGLULibrary= 'GLU32.dll';




const
   INVALID_MODULEHANDLE = 0;

var
   GLHandle: HINST;
   GLUHandle: HINST;

function GLGetProcAddress(ProcName: PAnsiChar):Pointer;
begin
  result := wglGetProcAddress(ProcName);
end;

// ************** Extensions ********************

// ReadExtensions
//
procedure ReadExtensions;
   // To be used in an active rendering context only!
begin
   // Extensions integrated into 1.2 core

   // GL 1.2
   glDrawRangeElements := GLGetProcAddress('glDrawRangeElements');
   glTexImage3D := GLGetProcAddress('glTexImage3D');

   // GL 1.2 ARB imaging
   glBlendColor := GLGetProcAddress('glBlendColor');
   glBlendEquation := GLGetProcAddress('glBlendEquation');
   glColorSubTable := GLGetProcAddress('glColorSubTable');
   glCopyColorSubTable := GLGetProcAddress('glCopyColorSubTable');
   glColorTable := GLGetProcAddress('glCopyColorSubTable');
   glCopyColorTable := GLGetProcAddress('glCopyColorTable');
   glColorTableParameteriv := GLGetProcAddress('glColorTableParameteriv'); 
   glColorTableParameterfv := GLGetProcAddress('glColorTableParameterfv');
   glGetColorTable := GLGetProcAddress('glGetColorTable'); 
   glGetColorTableParameteriv := GLGetProcAddress('glGetColorTableParameteriv');
   glGetColorTableParameterfv := GLGetProcAddress('glGetColorTableParameterfv');
   glConvolutionFilter1D := GLGetProcAddress('glConvolutionFilter1D'); 
   glConvolutionFilter2D := GLGetProcAddress('glConvolutionFilter2D'); 
   glCopyConvolutionFilter1D := GLGetProcAddress('glCopyConvolutionFilter1D');
   glCopyConvolutionFilter2D := GLGetProcAddress('glCopyConvolutionFilter2D');
   glGetConvolutionFilter := GLGetProcAddress('glGetConvolutionFilter'); 
   glSeparableFilter2D := GLGetProcAddress('glSeparableFilter2D'); 
   glGetSeparableFilter := GLGetProcAddress('glGetSeparableFilter');
   glConvolutionParameteri := GLGetProcAddress('glConvolutionParameteri'); 
   glConvolutionParameteriv := GLGetProcAddress('glConvolutionParameteriv');
   glConvolutionParameterf := GLGetProcAddress('glConvolutionParameterf');
   glConvolutionParameterfv := GLGetProcAddress('glConvolutionParameterfv');
   glGetConvolutionParameteriv := GLGetProcAddress('glGetConvolutionParameteriv');
   glGetConvolutionParameterfv := GLGetProcAddress('glGetConvolutionParameterfv'); 
   glHistogram := GLGetProcAddress('glHistogram');
   glResetHistogram := GLGetProcAddress('glResetHistogram');
   glGetHistogram := GLGetProcAddress('glGetHistogram');
   glGetHistogramParameteriv := GLGetProcAddress('glGetHistogramParameteriv');
   glGetHistogramParameterfv := GLGetProcAddress('glGetHistogramParameterfv');
   glMinmax := GLGetProcAddress('glMinmax');
   glResetMinmax := GLGetProcAddress('glResetMinmax');
   glGetMinmax := GLGetProcAddress('glGetMinmax');
   glGetMinmaxParameteriv := GLGetProcAddress('glGetMinmaxParameteriv');
   glGetMinmaxParameterfv := GLGetProcAddress('glGetMinmaxParameterfv');

   // GL extensions
   glArrayElementArrayEXT := GLGetProcAddress('glArrayElementArrayEXT');
   glColorTableEXT := GLGetProcAddress('glColorTableEXT');
   glColorSubTableEXT := GLGetProcAddress('glColorSubTableEXT');
   glGetColorTableEXT := GLGetProcAddress('glGetColorTableEXT');
   glGetColorTablePameterivEXT := GLGetProcAddress('glGetColorTablePameterivEXT');
   glGetColorTablePameterfvEXT := GLGetProcAddress('glGetColorTablePameterfvEXT');
   glCopyTexImage1DEXT := GLGetProcAddress('glCopyTexImage1DEXT');
   glCopyTexSubImage1DEXT := GLGetProcAddress('glCopyTexSubImage1DEXT');
   glCopyTexImage2DEXT := GLGetProcAddress('glCopyTexImage2DEXT');
   glCopyTexSubImage2DEXT := GLGetProcAddress('glCopyTexSubImage2DEXT');
   glCopyTexSubImage3DEXT := GLGetProcAddress('glCopyTexSubImage3DEXT');
   glIndexFuncEXT := GLGetProcAddress('glIndexFuncEXT');
   glIndexMaterialEXT := GLGetProcAddress('glIndexMaterialEXT');
   glPolygonOffsetEXT := GLGetProcAddress('glPolygonOffsetEXT');
   glTexSubImage1dEXT := GLGetProcAddress('glTexSubImage1DEXT');
   glTexSubImage2dEXT := GLGetProcAddress('glTexSubImage2DEXT');
   glTexSubImage3dEXT := GLGetProcAddress('glTexSubImage3DEXT');
   glGenTexturesEXT := GLGetProcAddress('glGenTexturesEXT');
   glDeleteTexturesEXT := GLGetProcAddress('glDeleteTexturesEXT');
   glBindTextureEXT := GLGetProcAddress('glBindTextureEXT');
   glPrioritizeTexturesEXT := GLGetProcAddress('glPrioritizeTexturesEXT');
   glAreTexturesResidentEXT := GLGetProcAddress('glAreTexturesResidentEXT');
   glIsTextureEXT := GLGetProcAddress('glIsTextureEXT');

   // EXT_compiled_vertex_array
   glLockArraysEXT := GLGetProcAddress('glLockArraysEXT');
   glUnlockArraysEXT := GLGetProcAddress('glUnlockArraysEXT');

   // ARB_multitexture
   glMultiTexCoord1dARB := GLGetProcAddress('glMultiTexCoord1dARB');
   glMultiTexCoord1dVARB := GLGetProcAddress('glMultiTexCoord1dVARB');
   glMultiTexCoord1fARB := GLGetProcAddress('glMultiTexCoord1fARB');
   glMultiTexCoord1fVARB := GLGetProcAddress('glMultiTexCoord1fVARB');
   glMultiTexCoord1iARB := GLGetProcAddress('glMultiTexCoord1iARB'); 
   glMultiTexCoord1iVARB := GLGetProcAddress('glMultiTexCoord1iVARB'); 
   glMultiTexCoord1sARB := GLGetProcAddress('glMultiTexCoord1sARB'); 
   glMultiTexCoord1sVARB := GLGetProcAddress('glMultiTexCoord1sVARB'); 
   glMultiTexCoord2dARB := GLGetProcAddress('glMultiTexCoord2dARB');
   glMultiTexCoord2dvARB := GLGetProcAddress('glMultiTexCoord2dvARB'); 
   glMultiTexCoord2fARB := GLGetProcAddress('glMultiTexCoord2fARB');
   glMultiTexCoord2fvARB := GLGetProcAddress('glMultiTexCoord2fvARB');
   glMultiTexCoord2iARB := GLGetProcAddress('glMultiTexCoord2iARB');
   glMultiTexCoord2ivARB := GLGetProcAddress('glMultiTexCoord2ivARB');
   glMultiTexCoord2sARB := GLGetProcAddress('glMultiTexCoord2sARB'); 
   glMultiTexCoord2svARB := GLGetProcAddress('glMultiTexCoord2svARB'); 
   glMultiTexCoord3dARB := GLGetProcAddress('glMultiTexCoord3dARB'); 
   glMultiTexCoord3dvARB := GLGetProcAddress('glMultiTexCoord3dvARB'); 
   glMultiTexCoord3fARB := GLGetProcAddress('glMultiTexCoord3fARB'); 
   glMultiTexCoord3fvARB := GLGetProcAddress('glMultiTexCoord3fvARB'); 
   glMultiTexCoord3iARB := GLGetProcAddress('glMultiTexCoord3iARB'); 
   glMultiTexCoord3ivARB := GLGetProcAddress('glMultiTexCoord3ivARB'); 
   glMultiTexCoord3sARB := GLGetProcAddress('glMultiTexCoord3sARB'); 
   glMultiTexCoord3svARB := GLGetProcAddress('glMultiTexCoord3svARB');
   glMultiTexCoord4dARB := GLGetProcAddress('glMultiTexCoord4dARB'); 
   glMultiTexCoord4dvARB := GLGetProcAddress('glMultiTexCoord4dvARB');
   glMultiTexCoord4fARB := GLGetProcAddress('glMultiTexCoord4fARB');
   glMultiTexCoord4fvARB := GLGetProcAddress('glMultiTexCoord4fvARB'); 
   glMultiTexCoord4iARB := GLGetProcAddress('glMultiTexCoord4iARB');
   glMultiTexCoord4ivARB := GLGetProcAddress('glMultiTexCoord4ivARB');
   glMultiTexCoord4sARB := GLGetProcAddress('glMultiTexCoord4sARB');
   glMultiTexCoord4svARB := GLGetProcAddress('glMultiTexCoord4svARB');
   glActiveTextureARB := GLGetProcAddress('glActiveTextureARB');
   glClientActiveTextureARB := GLGetProcAddress('glClientActiveTextureARB');

   // EXT_stencil_two_side
   glActiveStencilFaceEXT := GLGetProcAddress('glActiveStencilFaceEXT');

   // WIN_swap_hint
   glAddSwapHintRectWIN := GLGetProcAddress('glAddSwapHintRectWIN'); 

   // GL_ARB_point_parameter
   glPointParameterfARB := GLGetProcAddress('glPointParameterfARB');
   glPointParameterfvARB := GLGetProcAddress('glPointParameterfvARB');

   // GL_ARB_transpose_matrix
   glLoadTransposeMatrixfARB := GLGetProcAddress('glLoadTransposeMatrixfARB');
   glLoadTransposeMatrixdARB := GLGetProcAddress('glLoadTransposeMatrixdARB');
   glMultTransposeMatrixfARB := GLGetProcAddress('glMultTransposeMatrixfARB'); 
   glMultTransposeMatrixdARB := GLGetProcAddress('glMultTransposeMatrixdARB'); 

   glSampleCoverageARB := GLGetProcAddress('glSampleCoverageARB');
   glSamplePassARB := GLGetProcAddress('glSamplePassARB'); 

   // GL_ARB_multisample
   glCompressedTexImage3DARB := GLGetProcAddress('glCompressedTexImage3DARB');
   glCompressedTexImage2DARB := GLGetProcAddress('glCompressedTexImage2DARB');
   glCompressedTexImage1DARB := GLGetProcAddress('glCompressedTexImage1DARB');
   glCompressedTexSubImage3DARB := GLGetProcAddress('glCompressedTexSubImage3DARB');
   glCompressedTexSubImage2DARB := GLGetProcAddress('glCompressedTexSubImage2DARB');
   glCompressedTexSubImage1DARB := GLGetProcAddress('glCompressedTexSubImage1DARB');
   glGetCompressedTexImageARB := GLGetProcAddress('glGetCompressedTexImageARB');

   // GL_ARB_vertex_program
   glVertexAttrib1sARB := GLGetProcAddress('glVertexAttrib1sARB');
   glVertexAttrib1fARB := GLGetProcAddress('glVertexAttrib1fARB');
   glVertexAttrib1dARB := GLGetProcAddress('glVertexAttrib1dARB');
   glVertexAttrib2sARB := GLGetProcAddress('glVertexAttrib2sARB');
   glVertexAttrib2fARB := GLGetProcAddress('glVertexAttrib2fARB');
   glVertexAttrib2dARB := GLGetProcAddress('glVertexAttrib2dARB');
   glVertexAttrib3sARB := GLGetProcAddress('glVertexAttrib3sARB');
   glVertexAttrib3fARB := GLGetProcAddress('glVertexAttrib3fARB');
   glVertexAttrib3dARB := GLGetProcAddress('glVertexAttrib3dARB');
   glVertexAttrib4sARB := GLGetProcAddress('glVertexAttrib4sARB');
   glVertexAttrib4fARB := GLGetProcAddress('glVertexAttrib4fARB');
   glVertexAttrib4dARB := GLGetProcAddress('glVertexAttrib4dARB');
   glVertexAttrib4NubARB := GLGetProcAddress('glVertexAttrib4NubARB');
   glVertexAttrib1svARB := GLGetProcAddress('glVertexAttrib1svARB');
   glVertexAttrib1fvARB := GLGetProcAddress('glVertexAttrib1fvARB');
   glVertexAttrib1dvARB := GLGetProcAddress('glVertexAttrib1dvARB');
   glVertexAttrib2svARB := GLGetProcAddress('glVertexAttrib2svARB');
   glVertexAttrib2fvARB := GLGetProcAddress('glVertexAttrib2fvARB');
   glVertexAttrib2dvARB := GLGetProcAddress('glVertexAttrib2dvARB');
   glVertexAttrib3svARB := GLGetProcAddress('glVertexAttrib3svARB');
   glVertexAttrib3fvARB := GLGetProcAddress('glVertexAttrib3fvARB');
   glVertexAttrib3dvARB := GLGetProcAddress('glVertexAttrib3dvARB');
   glVertexAttrib4bvARB := GLGetProcAddress('glVertexAttrib4bvARB');
   glVertexAttrib4svARB := GLGetProcAddress('glVertexAttrib4svARB');
   glVertexAttrib4ivARB := GLGetProcAddress('glVertexAttrib4ivARB');
   glVertexAttrib4ubvARB := GLGetProcAddress('glVertexAttrib4ubvARB');
   glVertexAttrib4usvARB := GLGetProcAddress('glVertexAttrib4usvARB');
   glVertexAttrib4uivARB := GLGetProcAddress('glVertexAttrib4uivARB');
   glVertexAttrib4fvARB := GLGetProcAddress('glVertexAttrib4fvARB');
   glVertexAttrib4dvARB := GLGetProcAddress('glVertexAttrib4dvARB');
   glVertexAttrib4NbvARB := GLGetProcAddress('glVertexAttrib4NbvARB');
   glVertexAttrib4NsvARB := GLGetProcAddress('glVertexAttrib4NsvARB');
   glVertexAttrib4NivARB := GLGetProcAddress('glVertexAttrib4NivARB');
   glVertexAttrib4NubvARB := GLGetProcAddress('glVertexAttrib4NubvARB');
   glVertexAttrib4NusvARB := GLGetProcAddress('glVertexAttrib4NusvARB');
   glVertexAttrib4NuivARB := GLGetProcAddress('glVertexAttrib4NuivARB');
   glVertexAttribPointerARB := GLGetProcAddress('glVertexAttribPointerARB');
   glEnableVertexAttribArrayARB := GLGetProcAddress('glEnableVertexAttribArrayARB');
   glDisableVertexAttribArrayARB := GLGetProcAddress('glDisableVertexAttribArrayARB');
   glProgramStringARB := GLGetProcAddress('glProgramStringARB');
   glBindProgramARB := GLGetProcAddress('glBindProgramARB');
   glDeleteProgramsARB := GLGetProcAddress('glDeleteProgramsARB');
   glGenProgramsARB := GLGetProcAddress('glGenProgramsARB');
   glProgramEnvParameter4dARB := GLGetProcAddress('glProgramEnvParameter4dARB');
   glProgramEnvParameter4dvARB := GLGetProcAddress('glProgramEnvParameter4dvARB');
   glProgramEnvParameter4fARB := GLGetProcAddress('glProgramEnvParameter4fARB');
   glProgramEnvParameter4fvARB := GLGetProcAddress('glProgramEnvParameter4fvARB');
   glProgramLocalParameter4dARB := GLGetProcAddress('glProgramLocalParameter4dARB');
   glProgramLocalParameter4dvARB := GLGetProcAddress('glProgramLocalParameter4dvARB');
   glProgramLocalParameter4fARB := GLGetProcAddress('glProgramLocalParameter4fARB');
   glProgramLocalParameter4fvARB := GLGetProcAddress('glProgramLocalParameter4fvARB');
   glGetProgramEnvParameterdvARB := GLGetProcAddress('glGetProgramEnvParameterdvARB');
   glGetProgramEnvParameterfvARB := GLGetProcAddress('glGetProgramEnvParameterfvARB');
   glGetProgramLocalParameterdvARB := GLGetProcAddress('glGetProgramLocalParameterdvARB');
   glGetProgramLocalParameterfvARB := GLGetProcAddress('glGetProgramLocalParameterfvARB');
   glGetProgramivARB := GLGetProcAddress('glGetProgramivARB');
   glGetProgramStringARB := GLGetProcAddress('glGetProgramStringARB');
   glGetVertexAttribdvARB := GLGetProcAddress('glGetVertexAttribdvARB');
   glGetVertexAttribfvARB := GLGetProcAddress('glGetVertexAttribfvARB');
   glGetVertexAttribivARB := GLGetProcAddress('glGetVertexAttribivARB');
   glGetVertexAttribPointervARB := GLGetProcAddress('glGetVertexAttribPointervARB');
   glIsProgramARB := GLGetProcAddress('glIsProgramARB');

   // GL_ARB_vertex_buffer_object
   glBindBufferARB := GLGetProcAddress('glBindBufferARB');
   glDeleteBuffersARB := GLGetProcAddress('glDeleteBuffersARB');
   glGenBuffersARB := GLGetProcAddress('glGenBuffersARB');
   glIsBufferARB := GLGetProcAddress('glIsBufferARB');
   glBufferDataARB := GLGetProcAddress('glBufferDataARB');
   glBufferSubDataARB := GLGetProcAddress('glBufferSubDataARB');
   glGetBufferSubDataARB := GLGetProcAddress('glGetBufferSubDataARB');
   glMapBufferARB := GLGetProcAddress('glMapBufferARB');
   glUnmapBufferARB := GLGetProcAddress('glUnmapBufferARB');
   glGetBufferParameterivARB := GLGetProcAddress('glGetBufferParameterivARB');
   glGetBufferPointervARB := GLGetProcAddress('glGetBufferPointervARB');

   // GL_ARB_shader_objects
   glDeleteObjectARB := GLGetProcAddress('glDeleteObjectARB');
   glGetHandleARB := GLGetProcAddress('glGetHandleARB');
   glDetachObjectARB := GLGetProcAddress('glDetachObjectARB');
   glCreateShaderObjectARB := GLGetProcAddress('glCreateShaderObjectARB');
   glShaderSourceARB := GLGetProcAddress('glShaderSourceARB');
   glCompileShaderARB := GLGetProcAddress('glCompileShaderARB');
   glCreateProgramObjectARB := GLGetProcAddress('glCreateProgramObjectARB');
   glAttachObjectARB := GLGetProcAddress('glAttachObjectARB');
   glLinkProgramARB := GLGetProcAddress('glLinkProgramARB');
   glUseProgramObjectARB := GLGetProcAddress('glUseProgramObjectARB');
   glValidateProgramARB := GLGetProcAddress('glValidateProgramARB');
   glUniform1fARB := GLGetProcAddress('glUniform1fARB');
   glUniform2fARB := GLGetProcAddress('glUniform2fARB');
   glUniform3fARB := GLGetProcAddress('glUniform3fARB');
   glUniform4fARB := GLGetProcAddress('glUniform4fARB');
   glUniform1iARB := GLGetProcAddress('glUniform1iARB');
   glUniform2iARB := GLGetProcAddress('glUniform2iARB');
   glUniform3iARB := GLGetProcAddress('glUniform3iARB');
   glUniform4iARB := GLGetProcAddress('glUniform4iARB');
   glUniform1fvARB := GLGetProcAddress('glUniform1fvARB');
   glUniform2fvARB := GLGetProcAddress('glUniform2fvARB');
   glUniform3fvARB := GLGetProcAddress('glUniform3fvARB');
   glUniform4fvARB := GLGetProcAddress('glUniform4fvARB');
   glUniform1ivARB := GLGetProcAddress('glUniform1ivARB');
   glUniform2ivARB := GLGetProcAddress('glUniform2ivARB');
   glUniform3ivARB := GLGetProcAddress('glUniform3ivARB');
   glUniform4ivARB := GLGetProcAddress('glUniform4ivARB');
   glUniformMatrix2fvARB := GLGetProcAddress('glUniformMatrix2fvARB');
   glUniformMatrix3fvARB := GLGetProcAddress('glUniformMatrix3fvARB');
   glUniformMatrix4fvARB := GLGetProcAddress('glUniformMatrix4fvARB');
   glGetObjectParameterfvARB := GLGetProcAddress('glGetObjectParameterfvARB');
   glGetObjectParameterivARB := GLGetProcAddress('glGetObjectParameterivARB');
   glGetInfoLogARB := GLGetProcAddress('glGetInfoLogARB');
   glGetAttachedObjectsARB := GLGetProcAddress('glGetAttachedObjectsARB');
   glGetUniformLocationARB := GLGetProcAddress('glGetUniformLocationARB');
   glGetActiveUniformARB := GLGetProcAddress('glGetActiveUniformARB');
   glGetUniformfvARB := GLGetProcAddress('glGetUniformfvARB');
   glGetUniformivARB := GLGetProcAddress('glGetUniformivARB');
   glGetShaderSourceARB := GLGetProcAddress('glGetShaderSourceARB');

   // GL_ARB_vertex_shader
   glBindAttribLocationARB := GLGetProcAddress('glBindAttribLocationARB');
   glGetActiveAttribARB := GLGetProcAddress('glGetActiveAttribARB');
   glGetAttribLocationARB := GLGetProcAddress('glGetAttribLocationARB');

   // GL_EXT_blend_color
   glBlendColorEXT := GLGetProcAddress('glBlendColorEXT');

   // GL_EXT_texture3D
   glTexImage3DEXT := GLGetProcAddress('glTexImage3DEXT');

   // GL_SGIS_multisample
   glSampleMaskSGIS := GLGetProcAddress('glSampleMaskSGIS');
   glSamplePatternSGIS := GLGetProcAddress('glSamplePatternSGIS');

   // GL_EXT_blend_minmax
   glBlendEquationEXT := GLGetProcAddress('glBlendEquationEXT');

   // GL_EXT_paletted_texture
   glGetColorTableParameterivEXT := GLGetProcAddress('glGetColorTableParameterivEXT');
   glGetColorTableParameterfvEXT := GLGetProcAddress('glGetColorTableParameterfvEXT');

   // GL_EXT_draw_range_elements
   glDrawRangeElementsEXT := GLGetProcAddress('glDrawRangeElementsEXT');

   // GL_EXT_secondary_color
   glSecondaryColor3bEXT := GLGetProcAddress('glSecondaryColor3bEXT');
   glSecondaryColor3bvEXT := GLGetProcAddress('glSecondaryColor3bvEXT');
   glSecondaryColor3dEXT := GLGetProcAddress('glSecondaryColor3dEXT'); 
   glSecondaryColor3dvEXT := GLGetProcAddress('glSecondaryColor3dvEXT'); 
   glSecondaryColor3fEXT := GLGetProcAddress('glSecondaryColor3fEXT'); 
   glSecondaryColor3fvEXT := GLGetProcAddress('glSecondaryColor3fvEXT'); 
   glSecondaryColor3iEXT := GLGetProcAddress('glSecondaryColor3iEXT'); 
   glSecondaryColor3ivEXT := GLGetProcAddress('glSecondaryColor3ivEXT'); 
   glSecondaryColor3sEXT := GLGetProcAddress('glSecondaryColor3sEXT'); 
   glSecondaryColor3svEXT := GLGetProcAddress('glSecondaryColor3svEXT'); 
   glSecondaryColor3ubEXT := GLGetProcAddress('glSecondaryColor3ubEXT'); 
   glSecondaryColor3ubvEXT := GLGetProcAddress('glSecondaryColor3ubvEXT'); 
   glSecondaryColor3uiEXT := GLGetProcAddress('glSecondaryColor3uiEXT'); 
   glSecondaryColor3uivEXT := GLGetProcAddress('glSecondaryColor3uivEXT'); 
   glSecondaryColor3usEXT := GLGetProcAddress('glSecondaryColor3usEXT');
   glSecondaryColor3usvEXT := GLGetProcAddress('glSecondaryColor3usvEXT');
   glSecondaryColorPointerEXT := GLGetProcAddress('glSecondaryColorPointerEXT'); 

   // GL_EXT_multi_draw_arrays
   glMultiDrawArraysEXT := GLGetProcAddress('glMultiDrawArraysEXT'); 
   glMultiDrawElementsEXT := GLGetProcAddress('glMultiDrawElementsEXT');

   // GL_EXT_fog_coord
   glFogCoordfEXT := GLGetProcAddress('glFogCoordfEXT'); 
   glFogCoordfvEXT := GLGetProcAddress('glFogCoordfvEXT'); 
   glFogCoorddEXT := GLGetProcAddress('glFogCoorddEXT'); 
   glFogCoorddvEXT := GLGetProcAddress('glFogCoorddvEXT'); 
   glFogCoordPointerEXT := GLGetProcAddress('glFogCoordPointerEXT'); 

   // GL_EXT_blend_func_separate
   glBlendFuncSeparateEXT := GLGetProcAddress('glBlendFuncSeparateEXT');

   // GL_NV_vertex_array_range
   glFlushVertexArrayRangeNV := GLGetProcAddress('glFlushVertexArrayRangeNV'); 
   glVertexArrayRangeNV := GLGetProcAddress('glVertexArrayRangeNV'); 
   wglAllocateMemoryNV := GLGetProcAddress('wglAllocateMemoryNV'); 
   wglFreeMemoryNV := GLGetProcAddress('wglFreeMemoryNV'); 

   // GL_NV_register_combiners
   glCombinerParameterfvNV := GLGetProcAddress('glCombinerParameterfvNV'); 
   glCombinerParameterfNV := GLGetProcAddress('glCombinerParameterfNV');
   glCombinerParameterivNV := GLGetProcAddress('glCombinerParameterivNV'); 
   glCombinerParameteriNV := GLGetProcAddress('glCombinerParameteriNV'); 
   glCombinerInputNV := GLGetProcAddress('glCombinerInputNV');
   glCombinerOutputNV := GLGetProcAddress('glCombinerOutputNV'); 
   glFinalCombinerInputNV := GLGetProcAddress('glFinalCombinerInputNV'); 
   glGetCombinerInputParameterfvNV := GLGetProcAddress('glGetCombinerInputParameterfvNV');
   glGetCombinerInputParameterivNV := GLGetProcAddress('glGetCombinerInputParameterivNV'); 
   glGetCombinerOutputParameterfvNV := GLGetProcAddress('glGetCombinerOutputParameterfvNV');
   glGetCombinerOutputParameterivNV := GLGetProcAddress('glGetCombinerOutputParameterivNV');
   glGetFinalCombinerInputParameterfvNV := GLGetProcAddress('glGetFinalCombinerInputParameterfvNV'); 
   glGetFinalCombinerInputParameterivNV := GLGetProcAddress('glGetFinalCombinerInputParameterivNV');

   // GL_NV_fence
   glGenFencesNV := GLGetProcAddress('glGenFencesNV');
   glDeleteFencesNV := GLGetProcAddress('glDeleteFencesNV');
   glSetFenceNV := GLGetProcAddress('glSetFenceNV');
   glTestFenceNV := GLGetProcAddress('glTestFenceNV');
   glFinishFenceNV := GLGetProcAddress('glFinishFenceNV');
   glIsFenceNV := GLGetProcAddress('glIsFenceNV');
   glGetFenceivNV := GLGetProcAddress('glGetFenceivNV');

   // GL_NV_occlusion_query
   glGenOcclusionQueriesNV := GLGetProcAddress('glGenOcclusionQueriesNV');
   glDeleteOcclusionQueriesNV := GLGetProcAddress('glDeleteOcclusionQueriesNV');
   glIsOcclusionQueryNV := GLGetProcAddress('glIsOcclusionQueryNV');
   glBeginOcclusionQueryNV := GLGetProcAddress('glBeginOcclusionQueryNV');
   glEndOcclusionQueryNV := GLGetProcAddress('glEndOcclusionQueryNV');
   glGetOcclusionQueryivNV := GLGetProcAddress('glGetOcclusionQueryivNV');
   glGetOcclusionQueryuivNV := GLGetProcAddress('glGetOcclusionQueryuivNV');

   // GL_MESA_resize_buffers
   glResizeBuffersMESA := GLGetProcAddress('glResizeBuffersMESA');

   // GL_3DFX_tbuffer
   glTbufferMask3DFX := GLGetProcAddress('glTbufferMask3DFX');

   // GL_EXT_multisample
   glSampleMaskEXT := GLGetProcAddress('glSampleMaskEXT');
   glSamplePatternEXT := GLGetProcAddress('glSamplePatternEXT');

   // GL_SGIS_texture_color_mask
   glTextureColorMaskSGIS := GLGetProcAddress('glTextureColorMaskSGIS');

   // GLU extensions
   gluNurbsCallbackDataEXT := GLGetProcAddress('gluNurbsCallbackDataEXT');
   gluNewNurbsTessellatorEXT := GLGetProcAddress('gluNewNurbsTessellatorEXT'); 
   gluDeleteNurbsTessellatorEXT := GLGetProcAddress('gluDeleteNurbsTessellatorEXT');

   // GL_NV_vertex_program
   glAreProgramsResidentNV := GLGetProcAddress('glAreProgramsResidentNV');
   glBindProgramNV := GLGetProcAddress('glBindProgramNV');
   glDeleteProgramsNV := GLGetProcAddress('glDeleteProgramsNV'); 
   glExecuteProgramNV := GLGetProcAddress('glExecuteProgramNV'); 
   glGenProgramsNV := GLGetProcAddress('glGenProgramsNV');
   glGetProgramParameterdvNV := GLGetProcAddress('glGetProgramParameterdvNV'); 
   glGetProgramParameterfvNV := GLGetProcAddress('glGetProgramParameterfvNV');
   glGetProgramivNV := GLGetProcAddress('glGetProgramivNV');
   glGetProgramStringNV := GLGetProcAddress('glGetProgramStringNV'); 
   glGetTrackMatrixivNV := GLGetProcAddress('glGetTrackMatrixivNV'); 
   glGetVertexAttribdvNV:= GLGetProcAddress('glGetVertexAttribdvNV'); 
   glGetVertexAttribfvNV:= GLGetProcAddress('glGetVertexAttribfvNV'); 
   glGetVertexAttribivNV:= GLGetProcAddress('glGetVertexAttribivNV');
   glGetVertexAttribPointervNV := GLGetProcAddress ('glGetVertexAttribPointervNV');
   glIsProgramNV := GLGetProcAddress('glIsProgramNV'); 
   glLoadProgramNV := GLGetProcAddress('glLoadProgramNV'); 
   glProgramParameter4dNV := GLGetProcAddress('glProgramParameter4dNV'); 
   glProgramParameter4dvNV := GLGetProcAddress('glProgramParameter4dvNV'); 
   glProgramParameter4fNV := GLGetProcAddress('glProgramParameter4fNV'); 
   glProgramParameter4fvNV := GLGetProcAddress('glProgramParameter4fvNV'); 
   glProgramParameters4dvNV := GLGetProcAddress ('glProgramParameters4dvNV'); 
   glProgramParameters4fvNV := GLGetProcAddress ('glProgramParameters4fvNV');
   glRequestResidentProgramsNV := GLGetProcAddress ('glRequestResidentProgramsNV');
   glTrackMatrixNV := GLGetProcAddress('glTrackMatrixNV'); 
   glVertexAttribPointerNV := GLGetProcAddress('glVertexAttribPointerNV');
   glVertexAttrib1dNV := GLGetProcAddress('glVertexAttrib1dNV'); 
   glVertexAttrib1dvNV := GLGetProcAddress('glVertexAttrib1dvNV'); 
   glVertexAttrib1fNV := GLGetProcAddress('glVertexAttrib1fNV');
   glVertexAttrib1fvNV := GLGetProcAddress('glVertexAttrib1fvNV'); 
   glVertexAttrib1sNV := GLGetProcAddress('glVertexAttrib1sNV'); 
   glVertexAttrib1svNV := GLGetProcAddress('glVertexAttrib1svNV'); 
   glVertexAttrib2dNV := GLGetProcAddress('glVertexAttrib2dNV');
   glVertexAttrib2dvNV := GLGetProcAddress('glVertexAttrib2dvNV');
   glVertexAttrib2fNV := GLGetProcAddress('glVertexAttrib2fNV'); 
   glVertexAttrib2fvNV := GLGetProcAddress('glVertexAttrib2fvNV');
   glVertexAttrib2sNV := GLGetProcAddress('glVertexAttrib2sNV'); 
   glVertexAttrib2svNV := GLGetProcAddress('glVertexAttrib2svNV'); 
   glVertexAttrib3dNV := GLGetProcAddress('glVertexAttrib3dNV'); 
   glVertexAttrib3dvNV := GLGetProcAddress('glVertexAttrib3dvNV');
   glVertexAttrib3fNV := GLGetProcAddress('glVertexAttrib3fNV');
   glVertexAttrib3fvNV := GLGetProcAddress('glVertexAttrib3fvNV');
   glVertexAttrib3sNV := GLGetProcAddress('glVertexAttrib3sNV');
   glVertexAttrib3svNV := GLGetProcAddress('glVertexAttrib3svNV');
   glVertexAttrib4dNV := GLGetProcAddress('glVertexAttrib4dNV');
   glVertexAttrib4dvNV := GLGetProcAddress('glVertexAttrib4dvNV');
   glVertexAttrib4fNV := GLGetProcAddress('glVertexAttrib4fNV');
   glVertexAttrib4fvNV := GLGetProcAddress('glVertexAttrib4fvNV');
   glVertexAttrib4sNV := GLGetProcAddress('glVertexAttrib4sNV');
   glVertexAttrib4svNV := GLGetProcAddress('glVertexAttrib4svNV');
   glVertexAttrib4ubvNV := GLGetProcAddress('glVertexAttrib4ubvNV');
   glVertexAttribs1dvNV := GLGetProcAddress('glVertexAttribs1dvNV');
   glVertexAttribs1fvNV := GLGetProcAddress('glVertexAttribs1fvNV');
   glVertexAttribs1svNV := GLGetProcAddress('glVertexAttribs1svNV');
   glVertexAttribs2dvNV := GLGetProcAddress('glVertexAttribs2dvNV');
   glVertexAttribs2fvNV := GLGetProcAddress('glVertexAttribs2fvNV');
   glVertexAttribs2svNV := GLGetProcAddress('glVertexAttribs2svNV');
   glVertexAttribs3dvNV := GLGetProcAddress('glVertexAttribs3dvNV');
   glVertexAttribs3fvNV := GLGetProcAddress('glVertexAttribs3fvNV');
   glVertexAttribs3svNV := GLGetProcAddress('glVertexAttribs3svNV');
   glVertexAttribs4dvNV := GLGetProcAddress('glVertexAttribs4dvNV');
   glVertexAttribs4fvNV := GLGetProcAddress('glVertexAttribs4fvNV');
   glVertexAttribs4svNV := GLGetProcAddress('glVertexAttribs4svNV');
   glVertexAttribs4ubvNV := GLGetProcAddress('glVertexAttribs4ubvN');

   // GL_ATI_draw_buffers
   glDrawBuffersATI := GLGetProcAddress('glDrawBuffersATI');

   ReadWGLExtensions;
end;


// ReadWGLExtensions
//
procedure ReadWGLExtensions;
begin
   // ARB wgl extensions
   wglGetExtensionsStringARB := GLGetProcAddress('wglGetExtensionsStringARB');
   wglGetPixelFormatAttribivARB := GLGetProcAddress('wglGetPixelFormatAttribivARB');
   wglGetPixelFormatAttribfvARB := GLGetProcAddress('wglGetPixelFormatAttribfvARB');
   wglChoosePixelFormatARB := GLGetProcAddress('wglChoosePixelFormatARB');

   wglCreatePbufferARB := GLGetProcAddress('wglCreatePbufferARB');
   wglGetPbufferDCARB := GLGetProcAddress('wglGetPbufferDCARB');
   wglReleasePbufferDCARB := GLGetProcAddress('wglReleasePbufferDCARB');
   wglDestroyPbufferARB := GLGetProcAddress('wglDestroyPbufferARB');
   wglQueryPbufferARB := GLGetProcAddress('wglQueryPbufferARB');

   wglCreateBufferRegionARB := GLGetProcAddress('wglCreateBufferRegionARB');
   wglDeleteBufferRegionARB := GLGetProcAddress('wglDeleteBufferRegionARB');
   wglSaveBufferRegionARB := GLGetProcAddress('wglSaveBufferRegionARB');
   wglRestoreBufferRegionARB := GLGetProcAddress('wglRestoreBufferRegionARB');

   // -EGG- ----------------------------
   wglSwapIntervalEXT := GLGetProcAddress('wglSwapIntervalEXT');
   wglGetSwapIntervalEXT := GLGetProcAddress('wglGetSwapIntervalEXT');
end;

// TrimAndSplitVersionString
//
{$WARNINGS OFF}
procedure TrimAndSplitVersionString(Buffer: AnsiString; var Max, Min: Integer);
// Peels out the X.Y form from the given Buffer which must contain a version string like "text Minor.Major.Build text"
// at least however "Major.Minor".
var
  Separator: Integer;
begin
  try
    // There must be at least one dot to separate major and minor version number.
    Separator := Pos('.', Buffer);
    // At least one number must be before and one after the dot.
    if (Separator > 1) and (Separator < Length(Buffer)) and (Buffer[Separator - 1] in ['0'..'9']) and
      (Buffer[Separator + 1] in ['0'..'9']) then
    begin
      // OK, it's a valid version string. Now remove unnecessary parts.
      Dec(Separator);
      // Find last non-numeric character before version number.
      while (Separator > 0) and (Buffer[Separator] in ['0'..'9']) do
        Dec(Separator);
      // Delete leading characters which do not belong to the version string.
      Delete(Buffer, 1, Separator);
      Separator := Pos('.', Buffer) + 1;
      // Find first non-numeric character after version number
      while (Separator <= Length(Buffer)) and (Buffer[Separator] in ['0'..'9']) do
        Inc(Separator);
      // delete trailing characters not belonging to the version string
      Delete(Buffer, Separator, 255);
      // Now translate the numbers.
      Separator := Pos('.', Buffer); // This is necessary because the buffer length might have changed.
      Max := StrToInt(Copy(Buffer, 1, Separator - 1));
      Min := StrToInt(Copy(Buffer, Separator + 1, 255));
    end
    else
      Abort;
  except
    Min := 0;
    Max := 0;
  end;
end;
{$WARNINGS ON}

// ReadImplementationProperties
//
procedure ReadImplementationProperties;
var
   Buffer : AnsiString;
   MajorVersion, MinorVersion: Integer;

   // Checks if the given Extension string is in Buffer.
   function CheckExtension(const Extension: AnsiString): Boolean;
   var
     ExtPos: Integer;
   begin
     // First find the position of the extension string as substring in Buffer.
     ExtPos := Pos(Extension, Buffer);
     Result := ExtPos > 0;
     // Now check that it isn't only a substring of another extension.
     if Result then
       Result := ((ExtPos + Length(Extension) - 1)= Length(Buffer))
                 or (Buffer[ExtPos + Length(Extension)]=' ');
   end;

begin
   // determine version of implementation
   // GL
   buffer:=glGetString(GL_VERSION);
   TrimAndSplitVersionString(buffer, majorversion, minorVersion);
   GL_VERSION_1_0:=True;
   GL_VERSION_1_1:=(minorVersion>=1) or (majorVersion>1);
   GL_VERSION_1_2:=(minorVersion>=2) or (majorVersion>1);
   GL_VERSION_1_3:=(minorVersion>=3) or (majorVersion>1);
   GL_VERSION_1_4:=(minorVersion>=4) or (majorVersion>1);
   GL_VERSION_1_5:=(minorVersion>=5) or (majorVersion>1);

   // GLU
   buffer:=gluGetString(GLU_VERSION);
   TrimAndSplitVersionString(buffer, majorversion, minorVersion);
   GLU_VERSION_1_1:=True; // won't load without at least GLU 1.1
   GLU_VERSION_1_2:=(minorVersion>1) or (majorVersion>1);
   GLU_VERSION_1_3:=(minorVersion>2) or (majorVersion>1);

   // check supported extensions
   // GL
   Buffer := StrPas(glGetString(GL_EXTENSIONS));

   GL_3DFX_multisample := CheckExtension('GL_3DFX_multisample');
   GL_3DFX_tbuffer := CheckExtension('GL_3DFX_tbuffer');
   GL_3DFX_texture_compression_FXT1 := CheckExtension('GL_3DFX_texture_compression_FXT1');

   GL_ARB_imaging := CheckExtension('GL_ARB_imaging');
   GL_ARB_multisample := CheckExtension(' GL_ARB_multisample'); // ' ' to avoid collision with WGL variant
   GL_ARB_multitexture := CheckExtension('GL_ARB_multitexture');
   GL_ARB_depth_texture := CheckExtension('GL_ARB_depth_texture');
   GL_ARB_shadow := CheckExtension('GL_ARB_shadow');
   GL_ARB_texture_border_clamp := CheckExtension('GL_ARB_texture_border_clamp');
   GL_ARB_texture_compression := CheckExtension('GL_ARB_texture_compression');
   GL_ARB_texture_cube_map := CheckExtension('GL_ARB_texture_cube_map');
   GL_ARB_transpose_matrix := CheckExtension('GL_ARB_transpose_matrix');
   GL_ARB_vertex_blend := CheckExtension('GL_ARB_vertex_blend');
   GL_ARB_point_parameters := CheckExtension('GL_ARB_point_parameters');
   GL_ARB_texture_env_combine := CheckExtension('GL_ARB_texture_env_combine');
   GL_ARB_texture_env_crossbar := CheckExtension('GL_ARB_texture_env_crossbar');
   GL_ARB_texture_env_dot3 := CheckExtension('GL_ARB_texture_env_dot3');
   GL_ARB_vertex_program := CheckExtension('GL_ARB_vertex_program');
   GL_ARB_vertex_buffer_object := CheckExtension('GL_ARB_vertex_buffer_object');
   GL_ARB_shader_objects := CheckExtension('GL_ARB_shader_objects');
   GL_ARB_vertex_shader := CheckExtension('GL_ARB_vertex_shader');
   GL_ARB_fragment_shader := CheckExtension('GL_ARB_fragment_shader');
   GL_ARB_fragment_program := CheckExtension('GL_ARB_fragment_program');

   GL_EXT_abgr := CheckExtension('GL_EXT_abgr');
   GL_EXT_bgra := CheckExtension('GL_EXT_bgra');
   GL_EXT_blend_color := CheckExtension('GL_EXT_blend_color');
   GL_EXT_blend_func_separate := CheckExtension('GL_EXT_blend_func_separate');
   GL_EXT_blend_logic_op := CheckExtension('GL_EXT_blend_logic_op');
   GL_EXT_blend_minmax := CheckExtension('GL_EXT_blend_minmax');
   GL_EXT_blend_subtract := CheckExtension('GL_EXT_blend_subtract');
   GL_EXT_Cg_shader := CheckExtension('GL_EXT_Cg_shader');
   GL_EXT_compiled_vertex_array := CheckExtension('GL_EXT_compiled_vertex_array');
   GL_EXT_copy_texture := CheckExtension('GL_EXT_copy_texture');
   GL_EXT_draw_range_elements := CheckExtension('GL_EXT_draw_range_elements');
   GL_EXT_fog_coord := CheckExtension('GL_EXT_fog_coord');
   GL_EXT_multi_draw_arrays := CheckExtension('GL_EXT_multi_draw_arrays');
   GL_EXT_multisample := CheckExtension('GL_EXT_multisample');
   GL_EXT_packed_pixels := CheckExtension('GL_EXT_packed_pixels');
   GL_EXT_paletted_texture := CheckExtension('GL_EXT_paletted_texture');
   GL_EXT_polygon_offset := CheckExtension('GL_EXT_polygon_offset');
   GL_EXT_rescale_normal := CheckExtension('GL_EXT_rescale_normal');
   GL_EXT_secondary_color := CheckExtension('GL_EXT_secondary_color');
   GL_EXT_separate_specular_color := CheckExtension('GL_EXT_separate_specular_color');
   GL_EXT_shared_texture_palette := CheckExtension('GL_EXT_shared_texture_palette');
   GL_EXT_stencil_wrap := CheckExtension('GL_EXT_stencil_wrap');
   GL_EXT_stencil_two_side := CheckExtension('EXT_stencil_two_side');
   GL_EXT_texture_compression_s3tc := CheckExtension('GL_EXT_texture_compression_s3tc');
   GL_EXT_texture_cube_map := CheckExtension('GL_EXT_texture_cube_map');
   GL_EXT_texture_edge_clamp := CheckExtension('GL_EXT_texture_edge_clamp');
   GL_EXT_texture_env_add := CheckExtension('GL_EXT_texture_env_add');
   GL_EXT_texture_env_combine := CheckExtension('GL_EXT_texture_env_combine');
   GL_EXT_texture_filter_anisotropic := CheckExtension('GL_EXT_texture_filter_anisotropic');
   GL_EXT_texture_lod_bias := CheckExtension('GL_EXT_texture_lod_bias');
   GL_EXT_texture_object := CheckExtension('GL_EXT_texture_object');
   GL_EXT_texture3D := CheckExtension('GL_EXT_texture3D');
   GL_EXT_clip_volume_hint := CheckExtension('GL_EXT_clip_volume_hint');

   GL_HP_occlusion_test := CheckExtension('GL_HP_occlusion_test');

   GL_IBM_rasterpos_clip := CheckExtension('GL_IBM_rasterpos_clip');

   GL_KTX_buffer_region := CheckExtension('GL_KTX_buffer_region');

   GL_MESA_resize_buffers := CheckExtension('GL_MESA_resize_buffers');

   GL_NV_blend_square := CheckExtension('GL_NV_blend_square');
   GL_NV_fog_distance := CheckExtension('GL_NV_fog_distance');
   GL_NV_light_max_exponent := CheckExtension('GL_NV_light_max_exponent');
   GL_NV_register_combiners := CheckExtension('GL_NV_register_combiners');
   GL_NV_texgen_reflection := CheckExtension('GL_NV_texgen_reflection');
   GL_NV_texture_env_combine4 := CheckExtension('GL_NV_texture_env_combine4');
   GL_NV_vertex_array_range := CheckExtension('GL_NV_vertex_array_range');
   GL_NV_multisample_filter_hint  := CheckExtension('GL_NV_multisample_filter_hint');
   GL_NV_vertex_program := CheckExtension('GL_NV_vertex_program');
   GL_NV_fence := CheckExtension('GL_NV_fence');
   GL_NV_occlusion_query := CheckExtension('GL_NV_occlusion_query');
   GL_NV_texture_rectangle := CheckExtension('GL_NV_texture_rectangle');

   GL_ATI_texture_float := CheckExtension('GL_ATI_texture_float');
   GL_ATI_draw_buffers := CheckExtension('GL_ATI_draw_buffers');
   GL_ATI_texture_compression_3dc := CheckExtension('GL_ATI_texture_compression_3dc');

   GL_SGI_color_matrix := CheckExtension('GL_SGI_color_matrix');

   GL_SGIS_generate_mipmap := CheckExtension('GL_SGIS_generate_mipmap');
   GL_SGIS_multisample := CheckExtension('GL_SGIS_multisample');
   GL_SGIS_texture_border_clamp := CheckExtension('GL_SGIS_texture_border_clamp');
   GL_SGIS_texture_color_mask := CheckExtension('GL_SGIS_texture_color_mask');
   GL_SGIS_texture_edge_clamp := CheckExtension('GL_SGIS_texture_edge_clamp');
   GL_SGIS_texture_lod := CheckExtension('GL_SGIS_texture_lod');

   GL_SGIX_depth_texture := CheckExtension('GL_SGIX_depth_texture');
   GL_SGIX_shadow := CheckExtension('GL_SGIX_shadow'); 
   GL_SGIX_shadow_ambient := CheckExtension('GL_SGIX_shadow_ambient');

   GL_WIN_swap_hint := CheckExtension('GL_WIN_swap_hint');

   WGL_ARB_extensions_string := CheckExtension('WGL_ARB_extensions_string');

   // GLU
   Buffer := gluGetString(GLU_EXTENSIONS);
   GLU_EXT_TEXTURE := CheckExtension('GLU_EXT_TEXTURE');
   GLU_EXT_object_space_tess := CheckExtension('GLU_EXT_object_space_tess');
   GLU_EXT_nurbs_tessellator := CheckExtension('GLU_EXT_nurbs_tessellator');

   ReadWGLImplementationProperties;
end;

// ReadWGLImplementationProperties
//
procedure ReadWGLImplementationProperties;
var
   buffer: AnsiString;

   // Checks if the given Extension string is in Buffer.
   function CheckExtension(const extension : AnsiString) : Boolean;
   begin
      Result:=(Pos(extension, Buffer)>0);
   end;

begin
   // ARB wgl extensions
   if Assigned(wglGetExtensionsStringARB) then
      Buffer:=wglGetExtensionsStringARB(wglGetCurrentDC)
   else Buffer:='';
   WGL_ARB_multisample:=CheckExtension('WGL_ARB_multisample');
   WGL_EXT_swap_control:=CheckExtension('WGL_EXT_swap_control');
   WGL_ARB_buffer_region:=CheckExtension('WGL_ARB_buffer_region');
   WGL_ARB_extensions_string:=CheckExtension('WGL_ARB_extensions_string');
   WGL_ARB_pbuffer:=CheckExtension('WGL_ARB_pbuffer ');
   WGL_ARB_pixel_format:=CheckExtension('WGL_ARB_pixel_format');
   WGL_ATI_pixel_format_float:=CheckExtension('WGL_ATI_pixel_format_float');
end;

// CloseOpenGL
//
procedure CloseOpenGL;
begin
   if GLHandle<>INVALID_MODULEHANDLE then begin
      FreeLibrary(Cardinal(GLHandle));
      GLHandle:=INVALID_MODULEHANDLE;
   end;

   if GLUHandle<>INVALID_MODULEHANDLE then begin
      FreeLibrary(Cardinal(GLUHandle));
      GLUHandle:=INVALID_MODULEHANDLE;
   end;
end;

// InitOpenGL
//

{$WARNINGS OFF}
function InitOpenGL : Boolean;
begin
   if (GLHandle=INVALID_MODULEHANDLE) or (GLUHandle=INVALID_MODULEHANDLE) then
      Result:=InitOpenGLFromLibrary(SDefaultGLLibrary, SDefaultGLULibrary)
   else Result:=True;
end;
{$WARNINGS ON}

// InitOpenGLFromLibrary
//
{$WARNINGS OFF}
function InitOpenGLFromLibrary(const GLName, GLUName : AnsiString) : Boolean;
begin
   Result := False;
   CloseOpenGL;

   GLHandle:=LoadLibrary(PWideChar(GLName));
   GLUHandle:=LoadLibrary(PWideChar(GLUName));

   if (GLHandle<>INVALID_MODULEHANDLE) and (GLUHandle<>INVALID_MODULEHANDLE) then
     Result:=True
   else begin
      if GLHandle<>INVALID_MODULEHANDLE then
         FreeLibrary(Cardinal(GLHandle));
      if GLUHandle<>INVALID_MODULEHANDLE then
         FreeLibrary(Cardinal(GLUHandle));
   end;
end;
{$WARNINGS ON}

// IsOpenGLInitialized
//
function IsOpenGLInitialized: Boolean;
begin
   Result:=(GLHandle<>INVALID_MODULEHANDLE);
end;

// UnloadOpenGL
//
procedure UnloadOpenGL;
begin
   CloseOpenGL;
end; 

// LoadOpenGL
//
function LoadOpenGL: Boolean;
begin
   Result := InitOpenGL;
end;

// LoadOpenGLFromLibrary
//
function LoadOpenGLFromLibrary(GLName, GLUName: AnsiString): Boolean;
begin
   Result := InitOpenGLFromLibrary(GLName, GLUName);
end;

// IsOpenGLLoaded
//
function IsOpenGLLoaded: Boolean;
begin
   // compatibility routine
  Result:=(GLHandle<>INVALID_MODULEHANDLE);
end;

// IsMesaGL
//
function IsMesaGL : Boolean;
begin
   Result:=(GetProcAddress(Cardinal(GLHandle), 'glResizeBuffersMESA')<>nil);
end;


//own helper stuff

function glEnumToStr(const AEnum:GLenum):AnsiString;
var i:integer;
begin
  for i:=0 to high(glEnumDictionary)do if glEnumDictionary[i].id=AEnum then
    exit(glEnumDictionary[i].name);
  result:='';
end;

function glStrToEnum(AName:AnsiString):GLenum;
var i:integer;
begin
  {$Warnings off}AName:=UpperCase(AName);{$Warnings on}
  for i:=0 to high(glEnumDictionary)do if glEnumDictionary[i].name=AName then
    exit(glEnumDictionary[i].id);
  result:=0;
end;

procedure glTexGenSimplef(const texGenMode:TGLEnum;const s,t:single;const r:Single=1);
  var v:array[0..3]of single;
  procedure DoIt(const coor:integer);
  begin
    if v[coor]=1 then begin
      glDisable(GL_TEXTURE_GEN_S+coor)
    end else begin
      glEnable(GL_TEXTURE_GEN_S+coor);
      glTexGeni(GL_S+coor,GL_TEXTURE_GEN_MODE,GL_OBJECT_LINEAR);
      glTexGenfv(GL_S+coor,GL_OBJECT_PLANE,@v);
    end;
  end;
begin
  fillchar(v,sizeof(v),0);
  v[0]:=s;doit(0);v[0]:=0;
  v[1]:=t;doit(1);v[1]:=0;
  v[2]:=r;doit(2);
end;

function glGetErrorText:string;
var err:GLenum;
begin
  err:=glGetError;
  if err=GL_NO_ERROR then exit('');
  result:=glEnumToStr(err);
end;

procedure glRaiseError(const location:string='');
var s:string;
begin
  s:=glGetErrorText;if s='' then exit;
  raise Exception.Create('glError: '+location+' '+s);
end;

procedure glColor3(const clr:TColor);
begin
  with TRGBQuad({ColorToRGB}(clr))do glColor3ub(rgbBlue,rgbGreen,rgbRed);
end;

procedure glColor4(const clr:TColor);
begin
  with TRGBQuad({ColorToRGB}(clr))do glColor4ub(rgbBlue,rgbGreen,rgbRed,rgbReserved);
end;

procedure glClearColor(const clr:TColor);
  function a(const c:integer):single;begin result:=c*(1/$FF)end;
begin
  with TRGBQuad({ColorToRGB}(clr))do glClearColor(a(rgbBlue),a(rgbGreen),a(rgbRed),a(rgbReserved));
end;

procedure glRect(const r:TRect);
begin
  with r do glRecti(Left,Top,Right,Bottom);
end;

procedure glDrawCube;
begin
  glBegin(GL_QUADS);
                      glNormal3f(   0,   0,   1);
    glTexCoord2f(0,0);glVertex3f(-0.5,-0.5, 0.5);
    glTexCoord2f(1,0);glVertex3f( 0.5,-0.5, 0.5);
    glTexCoord2f(1,1);glVertex3f( 0.5, 0.5, 0.5);
    glTexCoord2f(0,1);glVertex3f(-0.5, 0.5, 0.5);

                      glNormal3f(   0,   0,  -1);
    glTexCoord2f(0,1);glVertex3f(-0.5, 0.5,-0.5);
    glTexCoord2f(1,1);glVertex3f( 0.5, 0.5,-0.5);
    glTexCoord2f(1,0);glVertex3f( 0.5,-0.5,-0.5);
    glTexCoord2f(0,0);glVertex3f(-0.5,-0.5,-0.5);

                      glNormal3f(   1,   0,   0);
    glTexCoord2f(0,1);glVertex3f( 0.5,-0.5,-0.5);
    glTexCoord2f(1,1);glVertex3f( 0.5, 0.5,-0.5);
    glTexCoord2f(1,0);glVertex3f( 0.5, 0.5, 0.5);
    glTexCoord2f(0,0);glVertex3f( 0.5,-0.5, 0.5);

                      glNormal3f(  -1,   0,   0);
    glTexCoord2f(0,1);glVertex3f(-0.5,-0.5, 0.5);
    glTexCoord2f(1,1);glVertex3f(-0.5, 0.5, 0.5);
    glTexCoord2f(1,0);glVertex3f(-0.5, 0.5,-0.5);
    glTexCoord2f(0,0);glVertex3f(-0.5,-0.5,-0.5);

                      glNormal3f(   0,   1,   0);
    glTexCoord2f(0,1);glVertex3f(-0.5, 0.5, 0.5);
    glTexCoord2f(1,1);glVertex3f( 0.5, 0.5, 0.5);
    glTexCoord2f(1,0);glVertex3f( 0.5, 0.5,-0.5);
    glTexCoord2f(0,0);glVertex3f(-0.5, 0.5,-0.5);

                      glNormal3f(   0,  -1,   0);
    glTexCoord2f(0,0);glVertex3f(-0.5,-0.5,-0.5);
    glTexCoord2f(1,0);glVertex3f( 0.5,-0.5,-0.5);
    glTexCoord2f(1,1);glVertex3f( 0.5,-0.5, 0.5);
    glTexCoord2f(0,1);glVertex3f(-0.5,-0.5, 0.5);
  glEnd;
end;

procedure gluLookAt(const eye, center, up: TV3f);
begin
  gluLookAt(eye.x,eye.y,eye.z, center.x,center.y,center.z, up.x,up.y,up.z);
end;

procedure glVertex(const v:TV2f);begin glVertex2fv(@v)end;
procedure glVertex(const v:TV3f);begin glVertex3fv(@v)end;

procedure glTranslateF(const v:TV3f);inline;begin with v do glTranslatef(x,y,z);end;

////////////////////////////////////////////////////////////////////////////////
{ TGLList }

destructor TGLList.Destroy;
begin
  Delete;
  inherited;
end;

function TGLList.GetHandle:GLEnum;
begin
  if FHandle=0 then
    FHandle:=glGenLists(1);
  result:=FHandle;
end;

procedure TGLList.Call;
begin
  if FHandle<>0 then
    glCallList(FHandle);
end;

procedure TGLList.New(const ARun:boolean=false);
var m:GLEnum;
begin
  if ARun then m:=GL_COMPILE_AND_EXECUTE
          else m:=GL_COMPILE;
  glNewList(Handle,m);
end;

procedure TGLList.EndList;
begin
  glEndList;
end;

procedure TGLList.Delete;
begin
  if FHandle<>0 then begin
    glDeleteLists(FHandle,1);
    FHandle:=0;
  end;
end;

function glNewList(const ARun:boolean=false):IGLList;
begin
  result:=TGlList.Create;
  result.New(ARun);
end;


initialization
  Set8087CW($133F);
  //            ^ ne errorozzon
  //          ^ precision control
finalization
  CloseOpenGL;
end.

