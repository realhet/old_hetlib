unit UCal;
//translation by real_het/2010

(**
 *  @file     cal.h
 *  @brief    CAL Interface Header
 *  @version  1.00.0 Beta
 *)


(* ============================================================

Copyright (c) 2007 Advanced Micro Devices, Inc.  All rights reserved.

Redistribution and use of this material is permitted under the following
conditions:

Redistributions must retain the above copyright notice and all terms of this
license.

In no event shall anyone redistributing or accessing or using this material
commence or participate in any arbitration or legal action relating to this
material against Advanced Micro Devices, Inc. or any copyright holders or
contributors. The foregoing shall survive any expiration or termination of
this license or any agreement or access or use related to this material.

ANY BREACH OF ANY TERM OF THIS LICENSE SHALL RESULT IN THE IMMEDIATE REVOCATION
OF ALL RIGHTS TO REDISTRIBUTE, ACCESS OR USE THIS MATERIAL.

THIS MATERIAL IS PROVIDED BY ADVANCED MICRO DEVICES, INC. AND ANY COPYRIGHT
HOLDERS AND CONTRIBUTORS "AS IS" IN ITS CURRENT CONDITION AND WITHOUT ANY
REPRESENTATIONS, GUARANTEE, OR WARRANTY OF ANY KIND OR IN ANY WAY RELATED TO
SUPPORT, INDEMNITY, ERROR FREE OR UNINTERRUPTED OPERATION, OR THAT IT IS FREE
FROM DEFECTS OR VIRUSES.  ALL OBLIGATIONS ARE HEREBY DISCLAIMED - WHETHER
EXPRESS, IMPLIED, OR STATUTORY - INCLUDING, BUT NOT LIMITED TO, ANY IMPLIED
WARRANTIES OF TITLE, MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE,
ACCURACY, COMPLETENESS, OPERABILITY, QUALITY OF SERVICE, OR NON-INFRINGEMENT.
IN NO EVENT SHALL ADVANCED MICRO DEVICES, INC. OR ANY COPYRIGHT HOLDERS OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, PUNITIVE,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, REVENUE, DATA, OR PROFITS; OR
BUSINESS INTERRUPTION) HOWEVER CAUSED OR BASED ON ANY THEORY OF LIABILITY
ARISING IN ANY WAY RELATED TO THIS MATERIAL, EVEN IF ADVISED OF THE POSSIBILITY
OF SUCH DAMAGE. THE ENTIRE AND AGGREGATE LIABILITY OF ADVANCED MICRO DEVICES,
INC. AND ANY COPYRIGHT HOLDERS AND CONTRIBUTORS SHALL NOT EXCEED TEN DOLLARS
(US $10.00). ANYONE REDISTRIBUTING OR ACCESSING OR USING THIS MATERIAL ACCEPTS
THIS ALLOCATION OF RISK AND AGREES TO RELEASE ADVANCED MICRO DEVICES, INC. AND
ANY COPYRIGHT HOLDERS AND CONTRIBUTORS FROM ANY AND ALL LIABILITIES,
OBLIGATIONS, CLAIMS, OR DEMANDS IN EXCESS OF TEN DOLLARS (US $10.00). THE
FOREGOING ARE ESSENTIAL TERMS OF THIS LICENSE AND, IF ANY OF THESE TERMS ARE
CONSTRUED AS UNENFORCEABLE, FAIL IN ESSENTIAL PURPOSE, OR BECOME VOID OR
DETRIMENTAL TO ADVANCED MICRO DEVICES, INC. OR ANY COPYRIGHT HOLDERS OR
CONTRIBUTORS FOR ANY REASON, THEN ALL RIGHTS TO REDISTRIBUTE, ACCESS OR USE
THIS MATERIAL SHALL TERMINATE IMMEDIATELY. MOREOVER, THE FOREGOING SHALL
SURVIVE ANY EXPIRATION OR TERMINATION OF THIS LICENSE OR ANY AGREEMENT OR
ACCESS OR USE RELATED TO THIS MATERIAL.

NOTICE IS HEREBY PROVIDED, AND BY REDISTRIBUTING OR ACCESSING OR USING THIS
MATERIAL SUCH NOTICE IS ACKNOWLEDGED, THAT THIS MATERIAL MAY BE SUBJECT TO
RESTRICTIONS UNDER THE LAWS AND REGULATIONS OF THE UNITED STATES OR OTHER
COUNTRIES, WHICH INCLUDE BUT ARE NOT LIMITED TO, U.S. EXPORT CONTROL LAWS SUCH
AS THE EXPORT ADMINISTRATION REGULATIONS AND NATIONAL SECURITY CONTROLS AS
DEFINED THEREUNDER, AS WELL AS STATE DEPARTMENT CONTROLS UNDER THE U.S.
MUNITIONS LIST. THIS MATERIAL MAY NOT BE USED, RELEASED, TRANSFERRED, IMPORTED,
EXPORTED AND/OR RE-EXPORTED IN ANY MANNER PROHIBITED UNDER ANY APPLICABLE LAWS,
INCLUDING U.S. EXPORT CONTROL LAWS REGARDING SPECIFICALLY DESIGNATED PERSONS,
COUNTRIES AND NATIONALS OF COUNTRIES SUBJECT TO NATIONAL SECURITY CONTROLS.
MOREOVER, THE FOREGOING SHALL SURVIVE ANY EXPIRATION OR TERMINATION OF ANY
LICENSE OR AGREEMENT OR ACCESS OR USE RELATED TO THIS MATERIAL.

NOTICE REGARDING THE U.S. GOVERNMENT AND DOD AGENCIES: This material is
provided with "RESTRICTED RIGHTS" and/or "LIMITED RIGHTS" as applicable to
computer software and technical data, respectively. Use, duplication,
distribution or disclosure by the U.S. Government and/or DOD agencies is
subject to the full extent of restrictions in all applicable regulations,
including those found at FAR52.227 and DFARS252.227 et seq. and any successor
regulations thereof. Use of this material by the U.S. Government and/or DOD
agencies is acknowledgment of the proprietary rights of any copyright holders
and contributors, including those of Advanced Micro Devices, Inc., as well as
the provisions of FAR52.227-14 through 23 regarding privately developed and/or
commercial computer software.

This license forms the entire agreement regarding the subject matter hereof and
supersedes all proposals and prior discussions and writings between the parties
with respect thereto. This license does not affect any ownership, rights, title,
or interest in, or relating to, this material. No terms of this license can be
modified or waived, and no breach of this license can be excused, unless done
so in a writing signed by all affected parties. Each term of this license is
separately enforceable. If any term of this license is determined to be or
becomes unenforceable or illegal, such term shall be reformed to the minimum
extent necessary in order for this license to remain in effect in accordance
with its terms as modified by such reformation. This license shall be governed
by and construed in accordance with the laws of the State of Texas without
regard to rules on conflicts of law of any state or jurisdiction or the United
Nations Convention on the International Sale of Goods. All disputes arising out
of this license shall be subject to the jurisdiction of the federal and state
courts in Austin, Texas, and all defenses are hereby waived concerning personal
jurisdiction and venue of these courts.

============================================================ *)

interface

{$WARNINGS OFF} //ignore 'DELAYED' is specific to a platform.

{$Z4} //Force all enums to DWord size

type
//void           CALvoid;       (**< void type                        *)
  CALchar       =ansichar;      (**< ASCII character                  *)
  CALbyte       =shortint;      (**< 1 byte signed integer value      *)
  CALubyte      =byte;          (**< 1 byte unsigned integer value    *)
  CALshort      =smallint;      (**< 2 byte signed integer value      *)
  CALushort     =word;          (**< 2 byte unsigned integer value    *)
  CALint        =integer;       (**< 4 byte signed integer value      *)
  CALuint       =cardinal;      (**< 4 byte unsigned intger value     *)
  CALfloat      =single;        (**< 32-bit IEEE floating point value *)
  CALdouble     =double;        (**< 64-bit IEEE floating point value *)
  CALlong       =integer;       (**< long value                       *)
  CALulong      =cardinal;      (**< unsigned long value              *)
  CALint64      =int64;         (**< 8 byte signed integer value *)
  CALuint64     =uint64;        (**< 8 byte unsigned integer value *)

  CALBoolean    =LongBool;

(** Function call result/return codes *)

  CALresult=(
    CAL_RESULT_OK                = 0, (**< No error *)
    CAL_RESULT_ERROR             = 1, (**< Operational error *)
    CAL_RESULT_INVALID_PARAMETER = 2, (**< Parameter passed in is invalid *)
    CAL_RESULT_NOT_SUPPORTED     = 3, (**< Function used properly but currently not supported *)
    CAL_RESULT_ALREADY           = 4, (**< Stateful operation requested has already been performed *)
    CAL_RESULT_NOT_INITIALIZED   = 5, (**< CAL function was called without CAL being initialized *)
    CAL_RESULT_BAD_HANDLE        = 6, (**< A handle parameter is invalid *)
    CAL_RESULT_BAD_NAME_TYPE     = 7, (**< A name parameter is invalid *)
    CAL_RESULT_PENDING           = 8, (**< An asynchronous operation is still pending *)
    CAL_RESULT_BUSY              = 9, (**< The resource in question is still in use *)
    CAL_RESULT_WARNING           = 10 (**< Compiler generated a warning *)
  );

(** Data format representation *)
  CALformat=(
    CAL_FORMAT_UNORM_INT8_1,        (**< 1 component, normalized unsigned 8-bit integer value per component *)
    CAL_FORMAT_UNORM_INT8_2,        (**< 2 component, normalized unsigned 8-bit integer value per component *)
    CAL_FORMAT_UNORM_INT8_4,        (**< 4 component, normalized unsigned 8-bit integer value per component *)
    CAL_FORMAT_UNORM_INT16_1,       (**< 1 component, normalized unsigned 16-bit integer value per component *)
    CAL_FORMAT_UNORM_INT16_2,       (**< 2 component, normalized unsigned 16-bit integer value per component *)
    CAL_FORMAT_UNORM_INT16_4,       (**< 4 component, normalized unsigned 16-bit integer value per component *)
    CAL_FORMAT_UNORM_INT32_4,       (**< 4 component, normalized unsigned 32-bit integer value per component *)
    CAL_FORMAT_SNORM_INT8_4,        (**< 4 component, normalized signed 8-bit integer value per component *)
    CAL_FORMAT_SNORM_INT16_1,       (**< 1 component, normalized signed 16-bit integer value per component *)
    CAL_FORMAT_SNORM_INT16_2,       (**< 2 component, normalized signed 16-bit integer value per component *)
    CAL_FORMAT_SNORM_INT16_4,       (**< 4 component, normalized signed 16-bit integer value per component *)
    CAL_FORMAT_FLOAT32_1,           (**< A 1 component, 32-bit float value per component *)
    CAL_FORMAT_FLOAT32_2,           (**< A 2 component, 32-bit float value per component *)
    CAL_FORMAT_FLOAT32_4,           (**< A 4 component, 32-bit float value per component *)
    CAL_FORMAT_FLOAT64_1,           (**< A 1 component, 64-bit float value per component *)
    CAL_FORMAT_FLOAT64_2,           (**< A 2 component, 64-bit float value per component *)
    CAL_FORMAT_UNORM_INT32_1,       (**< 1 component, normalized unsigned 32-bit integer value per component *)
    CAL_FORMAT_UNORM_INT32_2,       (**< 2 component, normalized unsigned 32-bit integer value per component *)
    CAL_FORMAT_SNORM_INT8_1,        (**< 1 component, normalized signed 8-bit integer value per component *)
    CAL_FORMAT_SNORM_INT8_2,        (**< 2 component, normalized signed 8-bit integer value per component *)
    CAL_FORMAT_SNORM_INT32_1,       (**< 1 component, normalized signed 32-bit integer value per component *)
    CAL_FORMAT_SNORM_INT32_2,       (**< 2 component, normalized signed 32-bit integer value per component *)
    CAL_FORMAT_SNORM_INT32_4,       (**< 4 component, normalized signed 32-bit integer value per component *)

    CAL_FORMAT_UNSIGNED_INT8_1,     (**< 1 component, unnormalized unsigned 8-bit integer value per component *)
    CAL_FORMAT_UNSIGNED_INT8_2,     (**< 2 component, unnormalized unsigned 8-bit integer value per component *)
    CAL_FORMAT_UNSIGNED_INT8_4,     (**< 4 component, unnormalized unsigned 8-bit integer value per component *)
    CAL_FORMAT_SIGNED_INT8_1,       (**< 1 component, unnormalized signed 8-bit integer value per component *)
    CAL_FORMAT_SIGNED_INT8_2,       (**< 2 component, unnormalized signed 8-bit integer value per component *)
    CAL_FORMAT_SIGNED_INT8_4,       (**< 4 component, unnormalized signed 8-bit integer value per component *)
    CAL_FORMAT_UNSIGNED_INT16_1,    (**< 1 component, unnormalized unsigned 16-bit integer value per component *)
    CAL_FORMAT_UNSIGNED_INT16_2,    (**< 2 component, unnormalized unsigned 16-bit integer value per component *)
    CAL_FORMAT_UNSIGNED_INT16_4,    (**< 4 component, unnormalized unsigned 16-bit integer value per component *)
    CAL_FORMAT_SIGNED_INT16_1,      (**< 1 component, unnormalized signed 16-bit integer value per component *)
    CAL_FORMAT_SIGNED_INT16_2,      (**< 2 component, unnormalized signed 16-bit integer value per component *)
    CAL_FORMAT_SIGNED_INT16_4,      (**< 4 component, unnormalized signed 16-bit integer value per component *)
    CAL_FORMAT_UNSIGNED_INT32_1,    (**< 1 component, unnormalized unsigned 32-bit integer value per component *)
    CAL_FORMAT_UNSIGNED_INT32_2,    (**< 2 component, unnormalized unsigned 32-bit integer value per component *)
    CAL_FORMAT_UNSIGNED_INT32_4,    (**< 4 component, unnormalized unsigned 32-bit integer value per component *)
    CAL_FORMAT_SIGNED_INT32_1,      (**< 1 component, unnormalized signed 32-bit integer value per component *)
    CAL_FORMAT_SIGNED_INT32_2,      (**< 2 component, unnormalized signed 32-bit integer value per component *)
    CAL_FORMAT_SIGNED_INT32_4,      (**< 4 component, unnormalized signed 32-bit integer value per component *)

    CAL_FORMAT_UNORM_SHORT_565,     (**< 3 component, normalized 5-6-5 RGB image. *)
    CAL_FORMAT_UNORM_SHORT_555,     (**< 4 component, normalized x-5-5-5 xRGB image *)
    CAL_FORMAT_UNORM_INT10_3,       (**< 4 component, normalized x-10-10-10 xRGB *)
    CAL_FORMAT_FLOAT16_1,           (**< A 1 component, 16-bit float value per component *)
    CAL_FORMAT_FLOAT16_2,           (**< A 2 component, 16-bit float value per component *)
    CAL_FORMAT_FLOAT16_4,           (**< A 4 component, 16-bit float value per component *)

    //Deprecated CAL formats.
    CAL_FORMAT_UBYTE_1  = CAL_FORMAT_UNORM_INT8_1,      (**< A 1 component 8-bit  unsigned byte format    *)
    CAL_FORMAT_BYTE_1   = CAL_FORMAT_SNORM_INT8_1,      (**< A 1 component 8-bit  byte format    *)
    CAL_FORMAT_UINT_1   = CAL_FORMAT_UNORM_INT32_1,     (**< A 1 component 32-bit unsigned integer format *)
    CAL_FORMAT_INT_1    = CAL_FORMAT_SNORM_INT32_1,     (**< A 1 component 32-bit signed integer format *)
    CAL_FORMAT_UBYTE_2  = CAL_FORMAT_UNORM_INT8_2,      (**< A 2 component 8-bit  unsigned byte format    *)
    CAL_FORMAT_UBYTE_4  = CAL_FORMAT_UNORM_INT8_4,      (**< A 4 component 8-bit  unsigned byte format    *)
    CAL_FORMAT_USHORT_1 = CAL_FORMAT_UNORM_INT16_1,     (**< A 1 component 16-bit unsigned short format   *)
    CAL_FORMAT_USHORT_2 = CAL_FORMAT_UNORM_INT16_2,     (**< A 2 component 16-bit unsigned short format   *)
    CAL_FORMAT_USHORT_4 = CAL_FORMAT_UNORM_INT16_4,     (**< A 4 component 16-bit unsigned short format   *)
    CAL_FORMAT_UINT_4   = CAL_FORMAT_UNORM_INT32_4,     (**< A 4 component 32-bit unsigned integer format *)
    CAL_FORMAT_BYTE_4   = CAL_FORMAT_SNORM_INT8_4,      (**< A 4 component 8-bit  byte format    *)
    CAL_FORMAT_SHORT_1  = CAL_FORMAT_SNORM_INT16_1,     (**< A 1 component 16-bit short format   *)
    CAL_FORMAT_SHORT_2  = CAL_FORMAT_SNORM_INT16_2,     (**< A 2 component 16-bit short format   *)
    CAL_FORMAT_SHORT_4  = CAL_FORMAT_SNORM_INT16_4,     (**< A 4 component 16-bit short format   *)
    CAL_FORMAT_FLOAT_1  = CAL_FORMAT_FLOAT32_1,         (**< A 1 component 32-bit float format   *)
    CAL_FORMAT_FLOAT_2  = CAL_FORMAT_FLOAT32_2,         (**< A 2 component 32-bit float format   *)
    CAL_FORMAT_FLOAT_4  = CAL_FORMAT_FLOAT32_4,         (**< A 4 component 32-bit float format   *)
    CAL_FORMAT_DOUBLE_1 = CAL_FORMAT_FLOAT64_1,         (**< A 1 component 64-bit float format   *)
    CAL_FORMAT_DOUBLE_2 = CAL_FORMAT_FLOAT64_2,         (**< A 2 component 64-bit float format   *)
    CAL_FORMAT_UINT_2   = CAL_FORMAT_UNORM_INT32_2,     (**< A 2 component 32-bit unsigned integer format *)
    CAL_FORMAT_BYTE_2   = CAL_FORMAT_SNORM_INT8_2,      (**< A 2 component 8-bit  byte format    *)
    CAL_FORMAT_INT_2    = CAL_FORMAT_SNORM_INT32_2,     (**< A 2 component 32-bit signed integer format *)
    CAL_FORMAT_INT_4    = CAL_FORMAT_SNORM_INT32_4,     (**< A 4 component 32-bit signed integer format *)
    CAL_FORMAT_32BIT_TYPELESS = CAL_FORMAT_UNSIGNED_INT32_1,     (**< A 1 component 32-bit unsigned integer format *)
    // End Deprecated formats.

    //CAL_FORMAT_LAST     = CAL_FORMAT_INT_1,
    CAL_FORMAT_LAST     = CAL_FORMAT_FLOAT16_4 );

(** Resource type for access view *)
  CALdimension=(
    CAL_DIM_BUFFER,                     (**< A resource dimension type *)
    CAL_DIM_1D,                         (**< A resource type *)
    CAL_DIM_2D,                         (**< A resource type *)
    CAL_DIM_3D,                         (**< A resource type *)
    CAL_DIM_CUBEMAP,                    (**< A resource type *)
    CAL_DIM_FIRST = CAL_DIM_BUFFER,     (**< FIRST resource dimension type *)
    CAL_DIM_LAST = CAL_DIM_CUBEMAP      (**< LAST resource type *)
  );

(** Device Kernel ISA *)
  CALtarget=(
    CAL_TARGET_600,                (**< R600 GPU ISA *)
    CAL_TARGET_610,                (**< RV610 GPU ISA *)
    CAL_TARGET_630,                (**< RV630 GPU ISA *)
    CAL_TARGET_670,                (**< RV670 GPU ISA *)
    CAL_TARGET_7XX,                (**< R700 class GPU ISA *)
    CAL_TARGET_770,                (**< RV770 GPU ISA *)
    CAL_TARGET_710,                (**< RV710 GPU ISA *)
    CAL_TARGET_730,                (**< RV730 GPU ISA *)
    CAL_TARGET_CYPRESS,            (**< CYPRESS GPU ISA *)
    CAL_TARGET_JUNIPER,            (**< JUNIPER GPU ISA *)
    CAL_TARGET_REDWOOD,            (**< REDWOOD GPU ISA *)
    CAL_TARGET_CEDAR,              (**< CEDAR GPU ISA *)
    CAL_TARGET_SUMO,
    CAL_TARGET_SUPERSUMO,
    CAL_TARGET_WRESTLER,           (**< WRESTLER GPU ISA *)
    CAL_TARGET_CAYMAN,             (**< CAYMAN GPU ISA *)
    CAL_TARGET_KAUAI,
    CAL_TARGET_BARTS,              (**< BARTS GPU ISA *)
    CAL_TARGET_TURKS,
    CAL_TARGET_CAICOS,

    CAL_TARGET_TAHITI,
    CAL_TARGET_PITCAIRN,
    CAL_TARGET_CAPEVERDE,
    CAL_TARGET_BONAIRE,     //my

    CAL_TARGET_OLAND,       //8000
    CAL_TARGET_MALTA,

    CAL_TARGET_SUN,         //8000M
    CAL_TARGET_MARS,
    CAL_TARGET_VENUS,
    CAL_TARGET_SATURN,
    CAL_TARGET_NEPTUNE,

    CAL_TARGET_CURACAO,
    CAL_TARGET_HAWAII,
    CAL_TARGET_VESUVIUS,

    CAL_TARGET_FIJI,       //GCN3------------------------
    CAL_TARGET_ICELAND,
    CAL_TARGET_TONGA,
    CAL_TARGET_CARRIZO,

    CAL_TARGET_UNKNOWN
  );

const
  CALTargetStr:array[CALTarget]of ansistring=(
    '600', '610', '630', '670',
    '7XX', '770', '710', '730',
    'CYPRESS',  'JUNIPER', 'REDWOOD', 'CEDAR', 'SUMO',  'SUPERSUMO',
    'WRESTLER', 'CAYMAN',  'KAUAI',   'BARTS', 'TURKS', 'CAICOS',
    'TAHITI', 'PITCAIRN', 'CAPEVERDE', 'BONAIRE',
    'OLAND', 'MALTA',
    'SUN', 'MARS', 'VENUS', 'SATURN', 'NEPTUNE',
    'CURACAO', 'HAWAII', 'VESUVIUS',
    'FIJI', 'ICELAND', 'TONGA', 'CARRIZO',
     'UNKNOWN');
  CALTargetSeries:array[CALtarget]of integer=(
    3,3,3,3,
    4,4,4,4,
    5,5,5,5,5,5,
    6,6,6,6,6,6,
    7,7,7,7,
    7,7,
    7,7,7,7,7,
    7,7,7,
    9,9,9,9,
    7);

function CALTargetOfName(const AName:ansistring):CALtarget;

type
(** CAL object container *)
  CALobject=CALuint;

(** CAL image container *)
  CALimage=CALuint;

  CALdevice=CALuint;      (**< Device handle *)
  CALcontext=CALuint;     (**< context *)
  CALresource=CALuint;    (**< resource handle *)
  CALmem=CALuint;         (**< memory handle *)
  CALfunc=CALuint;        (**< function handle *)
  CALname=CALuint;        (**< name handle *)
  CALmodule=CALuint;      (**< module handle *)
  CALevent=CALuint;       (**< event handle *)

const CAL_EVENT_INVALID=0;

type
(** CAL computational domain *)
  CALdomain=record
    x,                 (**< x origin of domain *)
    y,                 (**< y origin of domain *)
    width,             (**< width of domain *)
    height:CALuint;    (**< height of domain *)
    procedure setup(const AX,AY,AWidth,AHeight:CALuint);
  end;

(** CAL device information *)
  PCALdeviceinfo=^CALdeviceinfo;
  CALdeviceinfo=record
    target:CALtarget;              (**< Device Kernel ISA  *)
    maxResource1DWidth,            (**< Maximum resource 1D width *)
    maxResource2DWidth,            (**< Maximum resource 2D width *)
    maxResource2DHeight:CALuint;   (**< Maximum resource 2D height *)
    function dump:ansistring;
  end;

(** CAL device attributes *)
  PCALdeviceattribs=^CALdeviceattribs;
  CALdeviceattribs=record
    struct_size:CALuint;        (**< Client filled out size of CALdeviceattribs struct *)
    target:CALtarget;           (**< Asic identifier *)
    localRAM,                   (**< Amount of local GPU RAM in megabytes *)
    uncachedRemoteRAM,          (**< Amount of uncached remote GPU memory in megabytes *)
    cachedRemoteRAM,            (**< Amount of cached remote GPU memory in megabytes *)
    engineClock,                (**< GPU device clock rate in megahertz *)
    memoryClock,                (**< GPU memory clock rate in megahertz *)
    wavefrontSize,              (**< Wavefront size *)
    numberOfSIMD:CALuint;       (**< Number of SIMDs *)
    doublePrecision,            (**< double precision supported *)
    localDataShare,             (**< local data share supported *)
    globalDataShare,            (**< global data share supported *)
    globalGPR,                  (**< global GPR supported *)
    computeShader,              (**< compute shader supported *)
    memExport:CALboolean;       (**< memexport supported *)
    pitch_alignment,            (**< Required alignment for calCreateRes allocations (in data elements) *)
    surface_alignment,          (**< Required start address alignment for calCreateRes allocations (in bytes) *)
    numberOfUAVs:CALuint;       (**< Number of UAVs *)
    bUAVMemExport,              (**< Hw only supports mem export to simulate 1 UAV *)
    b3dProgramGrid:CALboolean;  (**< CALprogramGrid for have height and depth bigger than 1*)
    numberOfShaderEngines,      (**< Number of shader engines *)
    targetRevision:CALuint;     (**< Asic family revision *)
    function VLIWSize:integer;
    function dump:ansistring;
    function streams:integer;
    function description:ansistring;
    function TFlops: single;
    function targetStr:AnsiString;
    function targetSeries:integer;
  end;

(** CAL device status *)
  CALdevicestatus=record
    struct_size,                    (**< Client filled out size of CALdevicestatus struct *)
    availLocalRAM,                  (**< Amount of available local GPU RAM in megabytes *)
    availUncachedRemoteRAM,         (**< Amount of available uncached remote GPU memory in megabytes *)
    availCachedRemoteRAM:CALuint;   (**< Amount of available cached remote GPU memory in megabytes *)
    function dump:ansistring;
  end;

(** CAL resource allocation flags **)
const
  CAL_RESALLOC_GLOBAL_BUFFER  = 1; (**< used for global import/export buffer *)
  CAL_RESALLOC_CACHEABLE      = 2; (**< cacheable memory? *)

type
(** CAL computational 3D domain *)
  CALdomain3D=record
    width,             (**< width of domain *)
    height,            (**< height of domain *)
    depth:CALuint;     (**< depth  of domain *)
  end;

(** CAL computational grid *)
  CALprogramGrid=record
    func:CALfunc;           (**< CALfunc to execute *)
    gridBlock,              (**< size of a block of data *)
    gridSize:CALdomain3D;   (**< size of 'blocks' to execute. *)
    flags:CALuint;          (**< misc grid flags *)
  end;

(** CAL computational grid array*)
  CALprogramGridArray=record
    gridArray:array of CALprogramGrid;//delphi dyn array only for (in) parameter! (**< array of programGrid structures *)
    num,                              (**< number of entries in the grid array *)
    flags:CALuint;                    (**< misc grid array flags *)
  end;


(** CAL function information **)
  CALfuncInfo=record
    maxScratchRegsNeeded,            (**< Maximum number of scratch regs needed *)
    numSharedGPRUser,                (**< Number of shared GPRs *)
    numSharedGPRTotal:CALuint;       (**< Number of shared GPRs including ones used by SC *)
    eCsSetupMode:CALboolean;         (**< Slow mode *)
    numThreadPerGroup,               (**< Flattend umber of threads per group *)
    numThreadPerGroupX,              (**< x dimension of numThreadPerGroup *)
    numThreadPerGroupY,              (**< y dimension of numThreadPerGroup *)
    numThreadPerGroupZ,              (**< z dimension of numThreadPerGroup *)
    totalNumThreadGroup,             (**< Total number of thread groups *)
    wavefrontPerSIMD,                (**< Number of wavefronts per SIMD *) //CAL_USE_SC_PRM
    numWavefrontPerSIMD:CALuint;     (**< Number of wavefronts per SIMD *)
    isMaxNumWavePerSIMD,             (**< Is this the max num active wavefronts per SIMD *)
    setBufferForNumGroup:CALboolean; (**< Need to set up buffer for info on number of thread groups? *)
  end;

(*============================================================================
 * CAL Runtime Interface
 *============================================================================

calInit;

*)
function calInit:CALresult;stdcall;
function calGetVersion(out major,minor,imp:CALuint):CALresult;stdcall;
function calShutdown:CALresult;stdcall;

function calDeviceGetCount(out count:CALuint):CALresult;stdcall;
function calDeviceGetInfo(out info:CALdeviceinfo;const ordinal:CALuint):CALresult;stdcall;
function calDeviceGetAttribs(out attribs:CALdeviceattribs;const ordinal:CALuint):CALresult;stdcall;
function calDeviceGetStatus(out status:CALdevicestatus;const device:CALdevice):CALresult;stdcall;
function calDeviceOpen(var dev:CALdevice;const ordinal:CALuint):CALresult;stdcall;
function calDeviceClose(const dev:CALdevice):CALresult;stdcall;

function calResAllocLocal2D(out res:CALresource;const dev:CALdevice;const width, height:CALuint;const format:CALformat;const flags:CALuint=0):CALresult;stdcall;
function calResAllocRemote2D(out res:CALresource;var dev:CALdevice;const deviceCount,width,height:CALuint;const format:CALformat;const flags:CALuint=0):CALresult;stdcall;
function calResAllocLocal1D(out res:CALresource;const dev:CALdevice;const width:CALuint;const format:CALformat;const flags:CALuint=0):CALresult;stdcall;
function calResAllocRemote1D(out res:CALresource;var dev:CALdevice;const deviceCount,width:CALuint;const format:CALformat;const flags:CALuint=0):CALresult;stdcall;
function calResFree(const res:CALresource):CALresult;stdcall;
function calResMap(out pPtr;out pitch:CALuint;const res:CALresource;const flags:CALuint=0):CALresult;stdcall;
function calResUnmap(const res:CALresource):CALresult;stdcall;

function calCtxCreate(out ctx:CALcontext;const dev:CALdevice):CALresult;stdcall;
function calCtxDestroy(const ctx:CALcontext):CALresult;stdcall;
function calCtxGetMem(out mem:CALmem;const ctx:CALcontext;const res:CALresource):CALresult;stdcall;
function calCtxReleaseMem(const ctx:CALcontext;const mem:CALmem):CALresult;stdcall;
function calCtxSetMem(const ctx:CALcontext;const name:CALname;const mem:CALmem):CALresult;stdcall;
function calCtxRunProgram(out event:CALevent;const ctx:CALcontext;const func:CALfunc;const domain:CALdomain):CALresult;stdcall;
function calCtxRunProgramGrid(out event:CALevent;const ctx:CALcontext;const pProgramGrid:CALprogramGrid):CALresult;stdcall;
function calCtxRunProgramGridArray(out event:CALevent;const ctx:CALcontext;const GridArray:CALprogramGridArray):CALresult;stdcall;
function calCtxIsEventDone(const ctx:CALcontext;const event:CALevent):CALresult;stdcall;
function calCtxFlush(const ctx:CALcontext):CALresult;stdcall;
function calMemCopy(out event:CALevent;const ctx:CALcontext;const srcMem,dstMem:CALmem;const flags:CALuint):CALresult;stdcall;

function calImageRead(out image:CALimage;const buffer:pointer;const size:CALuint):CALresult;stdcall;
function calImageFree(const image:CALimage):CALresult;stdcall;

function calModuleLoad(out module:CALmodule;const ctx:CALcontext;const image:CALimage):CALresult;stdcall;
function calModuleUnload(const ctx:CALcontext ;const module:CALmodule):CALresult;stdcall;
function calModuleGetEntry(out func:CALfunc;const ctx:CALcontext;const module:CALmodule;const procName:PAnsiChar):CALresult;stdcall;
function calModuleGetName(out name:CALname;const ctx:CALcontext;const module:CALmodule;const varName:PAnsiChar):CALresult;stdcall;
function calModuleGetFuncInfo(out Info:CALfuncInfo;const ctx:CALcontext;const module:CALmodule;const func:CALfunc):CALresult;stdcall;

function calGetErrorString:PAnsiChar;stdcall;

//utility functions
procedure calCheck(const res:CALresult;const msg:ansistring);
function calInfo:ansistring;


//extensions
function calExtGetProc(out proc:pointer;const extid:integer;const procname:PAnsiChar):CALresult;stdcall;

type
  TCalResCreate1D=function(out res:CALresource;const dev:CALdevice;const mem:pointer;const width:integer;       const format:CALformat;const zero_size:CALuint;const flags:CALuint=0):CALresult;stdcall;
  TCalResCreate2D=function(out res:CALresource;const dev:CALdevice;const mem:pointer;const width,height:integer;const format:CALformat;const zero_size:CALuint;const flags:CALuint=0):CALresult;stdcall;

var
  calResCreate1D:TCalResCreate1D;
  calResCreate2D:TCalResCreate2D;

implementation

uses
  windows, sysutils, typinfo, het.utils;

(*----------------------------------------------------------------------------
 * CAL Subsystem Functions
 *----------------------------------------------------------------------------*)

const _CALdll='aticalrt.dll';

(**
 * @fn calInit(void)
 *
 * @brief Initialize the CAL subsystem.
 *
 * Initializes the CAL system for computation. The behavior of CAL methods is
 * undefined if the system is not initialized.
 *
 * @return Returns CAL_RESULT_OK on success, CAL_RESULT_ERROR if there was an error, and CAL_RESULT_ALREADY
 * of CAL has already been initialized. //het: CAL_RESULT_NOT_SUPPORTED if dll doesn't exist
 *
 * @sa calShutdown
 *)
var _calDLLExists:integer;//-1:does not exist 1:exists 0:have to check
function _calInit:CALresult;stdcall;external _CALdll name 'calInit' delayed;

var CalInitialized:boolean=false;

function calExtGetProc(out proc:pointer;const extid:integer;const procname:PAnsiChar):CALresult;stdcall;external _CALdll delayed;

procedure calInitExtensions;
const CAL_EXT_RES_CREATE = $1006;
begin
  if calExtGetProc(@CalResCreate1D,CAL_EXT_RES_CREATE,'calResCreate1D')<>CAL_RESULT_OK then CalResCreate1D:=nil;
  if calExtGetProc(@CalResCreate2D,CAL_EXT_RES_CREATE,'calResCreate2D')<>CAL_RESULT_OK then CalResCreate2D:=nil;
end;

function calInit:CALresult;stdcall;
var h:HMODULE;
begin
  if CalInitialized then exit(CAL_RESULT_ALREADY);
  if _calDLLExists=0 then begin
    h:=LoadLibrary(_CALdll);
    if h=0 then begin
      _calDLLExists:=-1;
      result:=CAL_RESULT_NOT_SUPPORTED;
    end else begin
      _calDLLExists:=1;
      result:=_calInit;
      FreeLibrary(h);//decrease refcount after the first real dll call

      calInitExtensions;
    end;
  end else if _calDLLExists=1 then begin
    result:=_calInit;
    if Result in[CAL_RESULT_OK,CAL_RESULT_ALREADY] then
      CalInitialized:=true;
  end else
    result:=CAL_RESULT_NOT_SUPPORTED;
end;

(**
 * @fn calGetVersion(CALuint* major, CALuint* minor, CALuint* imp)
 *
 * @brief Retrieve the CAL version that is loaded
 *
 * CAL version is in the form of API_Major.API_Minor.Implementation where
 * "API_Major" is the major version number of the CAL API. "API_Minor" is the
 * minor version number of the CAL API. "Implementation" is the implementation
 * instance of the supplied API version number.
 *
 * @return Returns CAL_RESULT_OK on success.
 *
 * @sa calInit calShutdown
 *)
function calGetVersion(out major,minor,imp:CALuint):CALresult;stdcall;external _CALdll delayed;

(**
 * @fn calShutdown(void)
 *
 * @brief Shuts down the CAL subsystem.
 *
 * Shuts down the CAL system. calShutdown should always be paired with
 * calInit. An application may have any number of calInit - calShutdown
 * pairs. Any CAL call outsied calInit - calShutdown pair will return
 * CAL_RESULT_NOT_INITIALIZED.
 *
 * @return Returns CAL_RESULT_OK on success, CAL_RESULT_ERROR if there was an error.
 *
 * @sa calInit
 *)
function _calShutdown:CALresult;stdcall;external _CALdll name 'calShutdown' delayed;

function calShutdown:CALresult;stdcall;
begin
  if CalInitialized then begin
    CalInitialized:=false;
    exit(_calShutdown);
  end;
  Result:=CAL_RESULT_OK;
end;

(*----------------------------------------------------------------------------
 * CAL Device Functions
 *----------------------------------------------------------------------------*)

(**
 * @fn calDeviceGetCount(CALuint* count)
 *
 * @brief Retrieve the number of devices available to the CAL subsystem.
 *
 * Returns in *count the total number of supported GPUs present in the system.
 *
 * @param count (out) - the number of devices available to CAL. On error, count will be zero.
 *
 * @return Returns CAL_RESULT_OK on success, CAL_RESULT_ERROR if there was an error.
 *
 * @sa calDeviceGetInfo calDeviceOpen calDeviceClose
 *)
function calDeviceGetCount(out count:CALuint):CALresult;stdcall;external _CALdll delayed;

(**
 * @fn calDeviceGetInfo(CALdeviceinfo* info, CALuint ordinal)
 *
 * @brief Retrieve information about a specific device available to the CAL subsystem.
 *
 * Returns the device specific information in *info. calDeviceGetInfo returns
 * CAL_RESULT_ERROR if the ordinal is not less than the *count returned in
 * calDeviceGetCount. The target instruction set, the maximum width of
 * 1D resources, the maximum width and height of 2D resources are part
 * of the CALdeviceinfo structure.
 *
 * @param info (out) - the device descriptor struct for the specified device.
 * @param ordinal (in) - zero based index of the device to retrieve information.
 *
 * @return Returns CAL_RESULT_OK on success, CAL_RESULT_ERROR if there was an error.
 *
 * @sa calDeviceGetCount calDeviceOpen calDeviceClose
 *)
function calDeviceGetInfo(out info:CALdeviceinfo;const ordinal:CALuint):CALresult;stdcall;external _CALdll delayed;

(**
 * @fn calDeviceGetAttribs(CALdeviceattribs* attribs, CALuint ordinal)
 *
 * @brief Retrieve information about a specific device available to the CAL subsystem.
 *
 * Returns the device specific attributes in *attribs. calDeviceGetAttribs returns
 * CAL_RESULT_ERROR if the ordinal is not less than the *count returned in
 * calDeviceGetCount.
 *
 * @param attribs (out) - the device attribute struct for the specified device.
 * @param ordinal (in) - zero based index of the device to retrieve information.
 *
 * @return Returns CAL_RESULT_OK on success, CAL_RESULT_ERROR if there was an error.
 *
 * @sa calDeviceGetCount calDeviceOpen calDeviceClose
 *)
function calDeviceGetAttribs(out attribs:CALdeviceattribs;const ordinal:CALuint):CALresult;stdcall;external _CALdll delayed;


(**
 * @fn calDeviceGetStatus(CALdevicestatus* status, CALdevice device)
 *
 * @brief Retrieve information about a specific device available to the CAL subsystem.
 *
 * Returns the current status of an open device in *status.
 *
 * @param status (out) - the status struct for the specified device.
 * @param device (in) - handle of the device from which status is to be retrieved.
 *
 * @return Returns CAL_RESULT_OK on success, CAL_RESULT_ERROR if there was an error.
 *
 * @sa calDeviceGetAttribs calDeviceOpen calDeviceClose
 *)
function calDeviceGetStatus(out status:CALdevicestatus;const device:CALdevice):CALresult;stdcall;external _CALdll delayed;

(**
 * @fn calDeviceOpen(CALdevice* dev, CALuint ordinal)
 *
 * @brief Open the specified device.
 *
 * Opens a device. A device has to be closed before it can be opened again in
 * the same application. This call should always be paired with calDeviceClose.
 * Open the device indexed by the <i>ordinal</i> parameter, which
 * is an unsigned integer in the range of zero to the number of available devices (minus one).
 *
 * @param dev (out) - the device handle for the specified device. On error, dev will be zero.
 * @param ordinal (in) - zero based index of the device to retrieve information.
 *
 * @return Returns CAL_RESULT_OK on success, CAL_RESULT_ERROR if there was an error.
 *
 * @sa calDeviceGetCount calDeviceGetInfo calDeviceClose
 *)
function calDeviceOpen(var dev:CALdevice;const ordinal:CALuint):CALresult;stdcall;external _CALdll delayed;

(**
 * @fn calDeviceClose(CALdevice dev)
 *
 * @brief Close the specified device.
 *
 * Close the device specified by <i>dev</i> parameter. The
 *
 * @param dev (in) - the device handle for the device to close
 *
 * @return Returns CAL_RESULT_OK on success, CAL_RESULT_ERROR if there was an error.
 *
 * @sa calDeviceGetCount calDeviceGetInfo calDeviceOpen
 *)
function calDeviceClose(const dev:CALdevice):CALresult;stdcall;external _CALdll delayed;


(*----------------------------------------------------------------------------
 * CAL Resource Functions
 *----------------------------------------------------------------------------*)

(**
 * @fn calResAllocLocal2D(CALresource* res, CALdevice dev, CALuint width, CALuint height, CALformat format, CALuint flags)
 *
 * @brief Allocate a memory resource local to a device
 *
 * allocates memory resource local to a device <i>dev</i> and returns a
 * resource handle in <i>*res</i> if successful. This memory is structured
 * as a 2 dimensional region of <i>width</i> and <i>height</i> with a <i>format</i>.
 * The maximum values of <i>width</i> and <i>height</i> are available through
 * the calDeviceGetInfo function. The call returns CAL_RESULT_ERROR if requested
 * memory was not available.
 *
 * Initial implementation will allow this memory to be accessible by all contexts
 * created on this device only. Contexts residing on other devices cannot access
 * this memory.
 *
 * <i>flags</i> can be zero or CAL_RESALLOC_GLOBAL_BUFFER
 * - to specify that the resource will be used as a global
 *   buffer.
 *
 * There are some performance implications when <i>width</i> is not a multiple
 * of 64 for R6xx GPUs.
 *
 * @param res (out)   - returned resource handle. On error, res will be zero.
 * @param dev (in)    - device the resource should be local.
 * @param width (in)  - width of resource (in elements).
 * @param height (in) - height of the resource (in elements).
 * @param format (in) - format/type of each element of the resource.
 * @param flags (in) - currently unused.
 *
 * @return Returns CAL_RESULT_OK on success, CAL_RESULT_ERROR if there was an error.
 *
 * @sa calResFree
 *)
function calResAllocLocal2D(out res:CALresource;const dev:CALdevice;const width, height:CALuint;const format:CALformat;const flags:CALuint=0):CALresult;stdcall;external _CALdll delayed;

(**
 * @fn calResAllocRemote2D(CALresource* res, CALdevice* dev, CALuint devCount, CALuint width, CALuint height, CALformat format, CALuint flags)
 *
 * @brief Allocate a memory resource remote to a set of devices
 *
 * allocates memory resource global to <i>devCount</i> number of devices in <i>dev</i> array
 * and returns a resource handle in <i>*res</i> if successful. This memory is structured
 * as a 2 dimensional region of <i>width</i> and <i>height</i> with a <i>format</i>.
 * The maximum values of <i>width</i> and <i>height</i> are available through
 * the calDeviceGetInfo function. The call returns CAL_RESULT_ERROR if requested
 * memory was not available.
 *
 * Currently only a single device is functional (<i>devCount</i> must be 1).
 *
 * Initial implementation will allow this memory to be accessible by all contexts
 * created on this device only. Contexts residing on other devices cannot access
 * this memory.
 *
 * <i>flags</i> can be zero or CAL_RESALLOC_GLOBAL_BUFFER - to
 * specify that the resource will be used as a global buffer or
 * CAL_RESALLOC_CACHEABLE for GART cacheable memory.
 *
 * One of the benefits with devices being able to write to remote (i.e. system)
 * memory is performance. For example, with large computational kernels, it is
 * sometimes faster for the GPU contexts to write directly to remote
 * memory than it is to do these in 2 steps of GPU context writing to local memory
 * and copying data from GPU local memory to remote system memory via calMemCopy
 *
 * @param res (out)   - returned resource handle. On error, res will be zero.
 * @param dev (in)    - list of devices the resource should be available to.
 * @param devCount (in) - number of devices in the device list.
 * @param width (in)  - width of resource (in elements).
 * @param height (in) - height of the resource (in elements).
 * @param format (in) - format/type of each element of the resource.
 * @param flags (in) - currently unused.
 *
 * @return Returns CAL_RESULT_OK on success, CAL_RESULT_ERROR if there was an error.
 *
 * @sa calResFree
 *)
function calResAllocRemote2D(out res:CALresource;var dev:CALdevice;const deviceCount,width,height:CALuint;const format:CALformat;const flags:CALuint=0):CALresult;stdcall;external _CALdll delayed;

(**
 * @fn calResAllocLocal1D(CALresource* res, CALdevice dev, CALuint width, CALformat format, CALuint flags)
 *
 * @brief Allocate a 1D memory resource local to a device
 *
 * allocates memory resource local to a device <i>device</i> and returns
 * a resource handle in <i>*res</i> if successful. This memory is
 * structured as a 1 dimensional array of <i>width</i> elements with a <i>format</i>}.
 * The maximum values of <i>width</i> is available from the calDeviceGetInfo function.
 * The call returns CAL_RESULT_ERROR if requested memory was not available.
 *
 * @param res (out)   - returned resource handle. On error, res will be zero.
 * @param dev (in)    - device the resource should be local.
 * @param width (in)  - width of resource (in elements).
 * @param format (in) - format/type of each element of the resource.
 * @param flags (in) - currently unused.
 *
 * @return Returns CAL_RESULT_OK on success, CAL_RESULT_ERROR if there was an error.
 *
 * @sa calResFree
 *)
function calResAllocLocal1D(out res:CALresource;const dev:CALdevice;const width:CALuint;const format:CALformat;const flags:CALuint=0):CALresult;stdcall;external _CALdll delayed;

(**
 * @fn calResAllocRemote1D(CALresource* res, CALdevice* dev, CALuint deviceCount, CALuint width, CALformat format, CALuint flags)
 *
 * @brief Allocate a 1D memory resource remote to a device
 *
 * allocates memory resource global to <i>devCount</i> number of devices
 * in <i>dev</i> array and returns a resource memory handle in <i>*res</i> if
 * successful. This memory resource is structured as a 1 dimensional
 * region of <i>width</i> elements with a <i>format</i>. The maximum values of
 * <i>width</i> is available from the calDeviceGetInfo function. The call returns
 * CAL_RESULT_ERROR if requested memory was not available.
 *
 * Currently only a single device is functional (<i>devCount</i> must be 1).
 *
 * @param res (out)   - returned resource handle. On error, res will be zero.
 * @param dev (in)    - device the resource should be local.
 * @param deviceCount (in) - number of devices in the device list.
 * @param width (in)  - width of resource (in elements).
 * @param format (in) - format/type of each element of the resource.
 * @param flags (in) - currently unused.
 *
 * @return Returns CAL_RESULT_OK on success, CAL_RESULT_ERROR if there was an error.
 *
 * @sa calResFree
 *)
function calResAllocRemote1D(out res:CALresource;var dev:CALdevice;const deviceCount,width:CALuint;const format:CALformat;const flags:CALuint=0):CALresult;stdcall;external _CALdll delayed;

(**
 * @fn calResFree(CALresource res)
 *
 * @brief Free a resource
 *
 * releases allocated memory resource. calResFree returns CAL_RESULT_BUSY if
 * the resources is in use by any context.
 *
 * @param res (in)   - resource handle to free.
 *
 * @return Returns CAL_RESULT_OK on success, CAL_RESULT_ERROR if there was an error.
 *
 * @sa calResAllocLocal2D calResAllocRemote2D calResAllocLocal1D calResAllocRemote1D
 *)
function calResFree(const res:CALresource):CALresult;stdcall;external _CALdll delayed;

(**
 * @fn calResMap(CALvoid** pPtr, CALuint* pitch, CALresource res, CALuint flags)
 *
 * @brief Map memory to the CPU
 *
 *
 * returns a CPU accessible pointer to the memory surface in <i>**pPtr</i>
 * and the pitch in <i>*pitch</i>.  All memory resources are CPU accessible. It is an
 * error to call <i>calResMap</i> within a <i>calResMap</i> - <i>calResUnmap</i> pair
 * for the same <i>CALresource</i> memory resource handle.
 *
 * A mapped surface cannot be used as input or output of a calCtxRunProgram or calMemCopy.
 *
 * @param pPtr (out) - CPU pointer to the mapped resource. On error, pPtr will be zero.
 * @param pitch (out) - Pitch in elements of the resource. On error, pitch will be zero.
 * @param res (in) - resource handle to map
 * @param flags (in) - not used
 *
 * @return Returns CAL_RESULT_OK on success, CAL_RESULT_ERROR if there was an error.
 *
 * @sa calResUnmap
 *)
function calResMap(out pPtr;out pitch:CALuint;const res:CALresource;const flags:CALuint=0):CALresult;stdcall;external _CALdll delayed;

(**
 * @fn calResUnmap(CALresource res)
 *
 * @brief Unmap a CPU mapped resource.
 *
 * releases the address returned in <i>calResMap</i>. This should always be
 * paired with <i>calResMap</i>
 *
 * @param res (in) - resource handle to unmap
 *
 * @return Returns CAL_RESULT_OK on success, CAL_RESULT_ERROR if there was an error.
 *
 * @sa calResMap
 *)
function calResUnmap(const res:CALresource):CALresult;stdcall;external _CALdll delayed;


(*----------------------------------------------------------------------------
 * CAL Context Functions
 *----------------------------------------------------------------------------*)

(**
 * @fn calCtxCreate(CALcontext* ctx, CALdevice dev)
 *
 * @brief Create a CAL context on the specified device
 *
 * creates a context on a device. Multiple contexts can be created on
 * a single device.
 *
 * @param ctx (out) - handle of the newly created context. On error, ctx will be zero.
 * @param dev (in) - device handle to create the context on
 *
 * @return Returns CAL_RESULT_OK on success, CAL_RESULT_ERROR if there was an error.
 *
 * @sa calCtxDestroy
 *)
function calCtxCreate(out ctx:CALcontext;const dev:CALdevice):CALresult;stdcall;external _CALdll delayed;

(**
 * @fn calCtxDestroy(CALcontext ctx)
 *
 * @brief Destroy a CAL context
 *
 * destroys a context. All current modules are unloaded and all CALmem objects
 * mapped to the context are released. This call should be paired with
 * <i>calCtxCreate</i>
 *
 * @param ctx (in) - context to destroy
 *
 * @return Returns CAL_RESULT_OK on success, CAL_RESULT_ERROR if there was an error.
 *
 * @sa calCtxCreate
 *)
function calCtxDestroy(const ctx:CALcontext):CALresult;stdcall;external _CALdll delayed;

(**
 * @fn calCtxGetMem(CALmem* mem, CALcontext ctx, CALresource res)
 *
 * @brief Map a resource to a context
 *
 * returns a memory handle in <i>*mem</i> for the resource surface <i>res</i>
 * for use by the context <i>ctx</i>.
 *
 * @param mem (out) - created memory handle. On error, mem will be zero.
 * @param ctx (in) - context in which resouce is mapped
 * @param res (in) - resource to map to context
 *
 * @return Returns CAL_RESULT_OK on success, CAL_RESULT_ERROR if there was an error.
 *
 * @sa calCtxReleaseMem calCtxSetMem
 *)
function calCtxGetMem(out mem:CALmem;const ctx:CALcontext;const res:CALresource):CALresult;stdcall;external _CALdll delayed;

(**
 * @fn calCtxReleaseMem(CALcontext ctx, CALmem mem)
 *
 * @brief Release a resource to context mapping
 *
 * releases memory handle <i>mem</i> that is obtained by <i>calCtxGetMem</i>.
 *
 * @param ctx (in) - context in which resouce is mapped
 * @param mem (in) - memory handle to release
 *
 * @return Returns CAL_RESULT_OK on success, CAL_RESULT_ERROR if there was an error.
 *
 * @sa calCtxGetMem calCtxSetMem
 *)
function calCtxReleaseMem(const ctx:CALcontext;const mem:CALmem):CALresult;stdcall;external _CALdll delayed;

(**
 * @fn calCtxSetMem(CALcontext ctx, CALname name, CALmem mem)
 *
 * @brief Set memory used for kernel input or output
 *
 * sets a memory handle <i>mem</i> with the associated <i>name</i> in
 * the module to the context <i>ctx</i>. This can be input or output.
 *
 * @param ctx (in) - context to apply attachment.
 * @param name (in) - name to bind memory.
 * @param mem (in) - memory handle to apply.
 *
 * @return Returns CAL_RESULT_OK on success, CAL_RESULT_ERROR if there was an error.
 *
 * @sa calCtxGetMem calCtxReleaseMem
 *)
function calCtxSetMem(const ctx:CALcontext;const name:CALname;const mem:CALmem):CALresult;stdcall;external _CALdll delayed;

(**
 * @fn calCtxRunProgram(CALevent* event, CALcontext ctx, CALfunc func, const CALdomain* domain)
 *
 * @brief Invoke the kernel over the specified domain.
 *
 *
 * issues a task to invoke the computation of the kernel identified by
 * <i>func</i> within a region <i>domain</i> on the context <i>ctx</i> and
 * returns an associated event token in <i>*event</i> with this task. This
 * method returns CAL_RESULT_ERROR if <i>func</i> is not found in the currently
 * loaded module. This method returns CAL_RESULT_ERROR, if any of the inputs,
 * input references, outputs and constant buffers associated with the kernel
 * are not setup. Completion of this event can be queried by the master process
 * using <i>calIsEventDone</i>
 *
 * Extended contextual information regarding a calCtxRunProgram failure
 * can be obtained with the calGetErrorString function.
 *
 * @param event (out) - event associated with RunProgram instance. On error, event will be zero.
 * @param ctx (in) - context.
 * @param func (in) - function to use as kernel.
 * @param domain (in) - domain over which kernel is applied.
 *
 * @return Returns CAL_RESULT_OK on success, CAL_RESULT_ERROR if there was an error.
 *
 * @sa calCtxIsEventDone
 *)
function calCtxRunProgram(out event:CALevent;const ctx:CALcontext;const func:CALfunc;const domain:CALdomain):CALresult;stdcall;external _CALdll delayed;

(**
 * @fn calCtxRunProgramGrid(CALevent* event, CALcontext ctx, CALprogramGrid* pProgramGrid)
 *
 * @brief Invoke the kernel over the specified domain.
 *
 *
 * issues a task to invoke the computation of the kernel identified by
 * <i>func</i> within a region <i>domain</i> on the context <i>ctx</i> and
 * returns an associated event token in <i>*event</i> with this task. This
 * method returns CAL_RESULT_ERROR if <i>func</i> is not found in the currently
 * loaded module. This method returns CAL_RESULT_ERROR, if any of the inputs,
 * input references, outputs and constant buffers associated with the kernel
 * are not setup. Completion of this event can be queried by the master process
 * using <i>calIsEventDone</i>
 *
 * Extended contextual information regarding a calCtxRunProgram failure
 * can be obtained with the calGetErrorString function.
 *
 * @param event (out) - event associated with RunProgram instance. On error, event will be zero.
 * @param ctx (in) - context.
 * @param pProgramGrid (in) - description of program information to get kernel and thread counts.
 *
 * @return Returns CAL_RESULT_OK on success, CAL_RESULT_ERROR if there was an error.
 *
 * @sa calCtxIsEventDone
 *)
function calCtxRunProgramGrid(out event:CALevent;const ctx:CALcontext;const pProgramGrid:CALprogramGrid):CALresult;stdcall;external _CALdll delayed;

(**
 * @fn calCtxRunProgramGridArray(CALevent* event, CALcontext ctx, CALprogramGridArray* pGridArray)
 *
 * @brief Invoke the kernel array over the specified domain(s).
 *
 *
 * issues a task to invoke the computation of the kernel arrays identified by
 * <i>func</i> within a region <i>domain</i> on the context <i>ctx</i> and
 * returns an associated event token in <i>*event</i> with this task. This
 * method returns CAL_RESULT_ERROR if <i>func</i> is not found in the currently
 * loaded module. This method returns CAL_RESULT_ERROR, if any of the inputs,
 * input references, outputs and constant buffers associated with the kernel
 * are not setup. Completion of this event can be queried by the master process
 * using <i>calIsEventDone</i>
 *
 * Extended contextual information regarding a calCtxRunProgram failure
 * can be obtained with the calGetErrorString function.
 *
 * @param event (out) - event associated with RunProgram instance. On error, event will be zero.
 * @param ctx (in) - context.
 * @param pGridArray (in) - array containing kernel programs and grid information.
 *
 * @return Returns CAL_RESULT_OK on success, CAL_RESULT_ERROR if there was an error.
 *
 * @sa calCtxIsEventDone
 *)
function calCtxRunProgramGridArray(out event:CALevent;const ctx:CALcontext;const GridArray:CALprogramGridArray):CALresult;stdcall;external _CALdll delayed;

(**
 * @fn calCtxIsEventDone(CALcontext ctx, CALevent event)
 *
 * @brief Query to see if event has completed
 *
 *
 * is a mechanism for the master process to query if an event <i>event</i> on
 * context <i>ctx</i> from <i>calCtxRunProgram</i> or <i>calMemCopy</i> is
 * completed. This call also ensures that the commands associated with
 * the context are flushed.
 *
 * @param ctx (in) - context to query.
 * @param event (in) - event to query.
 *
 * @return Returns CAL_RESULT_OK if the event is complete, CAL_RESULT_PENDING if the event is
 * still being processed and CAL_RESULT_ERROR if there was an error.
 *
 * @sa calCtxRunProgram
 *)
function calCtxIsEventDone(const ctx:CALcontext;const event:CALevent):CALresult;stdcall;external _CALdll delayed;

(**
 * @fn calCtxFlush(CALcontext ctx)
 *
 * @brief Flush any commands associated with the supplied context
 *
 * This call ensures that the commands associated with the
 * context are flushed.
 *
 * @param ctx (in) - context to flush.
 *
 * @return Returns CAL_RESULT_OK if the event is complete, CAL_RESULT_ERROR if
 * there was an error.
 *
 * @sa calCtxRunProgram calCtxIsEventDone
 *)
function calCtxFlush(const ctx:CALcontext):CALresult;stdcall;external _CALdll delayed;

(**
 * @fn calMemCopy(CALevent* event, CALcontext ctx, CALmem srcMem, CALmem dstMem, CALuint flags)
 *
 * @brief Copy srcMem to dstMem
 *
 * issues a task to copy data from a source memory handle to a
 * destination memory handle. This method returns CAL_RESULT_ERROR if the source
 * and destination memory have different memory formats or if the destination
 * memory handle is not as big in 2 dimensions as the source memory or
 * if the source and destination memory handles do not belong to the
 * context <i>ctx</i>. An event is associated with this task and is returned in
 * <i>*event</i> and completion of this event can be queried by the master
 * process using <i>calIsEventDone</i>. Data can be copied between memory
 * handles from remote system memory to device local memory, remote system
 * memory to remote system memory, device local memory to remote
 * system memory, device local memory to same device local memory, device
 * local memory to a different device local memory. The memory is copied by
 * the context <i>ctx</i>
 *
 * @param event (out) - event associated with Memcopy instance. On error, event will be zero.
 * @param ctx (in) - context to query.
 * @param srcMem (in) - source of the copy.
 * @param dstMem (in) - destination of the copy.
 * @param flags (in) - currently not used.
 *
 * @return Returns CAL_RESULT_OK on success, CAL_RESULT_ERROR if there was an error.
 *
 * @sa calCtxRunProgram
 *)
function calMemCopy(out event:CALevent;const ctx:CALcontext;const srcMem,dstMem:CALmem;const flags:CALuint):CALresult;stdcall;external _CALdll delayed;

(*----------------------------------------------------------------------------
 * CAL Image Functions
 *----------------------------------------------------------------------------*)

(**
 * @fn calImageRead(CALimage* image, const CALvoid* buffer, CALuint size)
 *
 * @brief Create a CALimage and serialize into it from the supplied buffer.
 *
 * Create a CALimage and populate it with information from the supplied buffer.
 *
 * @param image (out) - image created from serialization
 * @param buffer (in) - buffer to serialize from
 * @param size (in) - size of buffer
 *
 * @return Returns CAL_RESULT_OK on success, CAL_RESULT_ERROR if there was an error.
 * @sa calImageFree
 *)
function calImageRead(out image:CALimage;const buffer:pointer;const size:CALuint):CALresult;stdcall;external _CALdll delayed;

(**
 * @fn calImageFree(CALimage image)
 *
 * @brief Free the supplied CALimage.
 *
 * Free a calImage that was created with calImageRead.
 *
 * @param image (in) - image to free
 *
 * @return Returns CAL_RESULT_OK on success, CAL_RESULT_ERROR if there was an error.
 *
 * @sa calImageRead
 *)
function calImageFree(const image:CALimage):CALresult;stdcall;external _CALdll delayed;

(*----------------------------------------------------------------------------
 * CAL Module Functions
 *----------------------------------------------------------------------------*)

(**
 * @fn calModuleLoad(CALmodule* module, CALcontext ctx, CALimage image)
 *
 * @brief Load a kernel image to a context
 *
 * creates a module from precompiled image <i>image</i>, loads the module
 * on the context and returns the loaded module in <i>*module</i>. This
 * method returns CAL_RESULT_ERROR if the module cannot be loaded onto the
 * processor. One of the reasons why a module cannot be loaded is if the
 * module does not have generated ISA for the hardware that it is loaded
 * onto. Multiple images can be loaded onto a single context at any single time.
 *
 * @param module (out) - handle to the loaded image. On error, module will be zero.
 * @param ctx (in) - context to load an image.
 * @param image (in) - raw image to load.
 *
 * @return Returns CAL_RESULT_OK on success, CAL_RESULT_ERROR if there was an error.
 *
 * @sa calModuleUnload calModuleGetEntry calModuleGetName
 *)
function calModuleLoad(out module:CALmodule;const ctx:CALcontext;const image:CALimage):CALresult;stdcall;external _CALdll delayed;

(**
 * @fn calModuleUnload(CALcontext ctx, CALmodule module)
 *
 * @brief Unload a kernel image
 *
 * unloads the module from the context.
 *
 * @param ctx (in) - context.
 * @param module (in) - handle to the loaded image.
 *
 * @return Returns CAL_RESULT_OK on success, CAL_RESULT_ERROR if there was an error.
 *
 * @sa calModuleLoad calModuleGetEntry calModuleGetName
 *)
function calModuleUnload(const ctx:CALcontext ;const module:CALmodule):CALresult;stdcall;external _CALdll delayed;

(**
 * @fn calModuleGetEntry(CALfunc* func, CALcontext ctx, CALmodule module, const CALchar* procName)
 *
 * @brief Retrieve a kernel function
 *
 * returns in <i>*func</i> the entry point to the kernel function named
 * <i>procName</i> from the module <i>module</i>. This method returns
 * CAL_RESULT_ERROR if the entry point <i>procName</i> is not found in the module.
 *
 * @param func (out) - handle to kernel function. On error, func will be zero.
 * @param ctx (in) - context.
 * @param module (in) - handle to the loaded image.
 * @param procName (in) - name of the function.
 *
 * @return Returns CAL_RESULT_OK on success, CAL_RESULT_ERROR if there was an error.
 *
 * @sa calModuleLoad calModuleUnload calModuleGetEntry
 *)
function calModuleGetEntry(out func:CALfunc;const ctx:CALcontext;const module:CALmodule;const procName:PAnsiChar):CALresult;stdcall;external _CALdll delayed;

(**
 * @fn calModuleGetName(CALname* name, CALcontext ctx, CALmodule module, const CALchar* varName)
 *
 * @brief Retrieve a kernel parameter by name
 *
 * returns in <i>*name</i> the handle to the module global variable named
 * <i>varName</i> that can be used to setup inputs and constant buffers to
 * the kernel computation. This method returns CAL_RESULT_ERROR if the variable
 * <i>varName</i> is not found in the module.
 *
 * @param name (out) - handle to name symbol. On error, name will be zero.
 * @param ctx (in) - context.
 * @param module (in) - handle to the loaded image.
 * @param varName (in) - name of the input or output.
 *
 * @return Returns CAL_RESULT_OK on success, CAL_RESULT_ERROR if there was an error.
 *
 * @sa calModuleLoad calModuleUnload calModuleGetEntry
 *)
function calModuleGetName(out name:CALname;const ctx:CALcontext;const module:CALmodule;const varName:PAnsiChar):CALresult;stdcall;external _CALdll delayed;

(**
 * @fn calModuleGetFuncInfo(CALfuncInfo* pInfo, CALcontext ctx, CALmodule module, CALfunc func)
 *
 * @brief Retrieve information regarding the named func in the
 * named module.
 *
 * returns in <i>*info</i> the information regarding the func.
 * This method returns CAL_RESULT_NOT_INITIALIZED if CAL is not
 * initialied.
 * This method returns CAL_RESULT_INVALID_PARAMETER if info is
 * NULL.
 * This method returns CAL_RESULT_BAD_HANDLE if ctx is invalid
 * or module is not loaded or func is not found.
 * This method returns CAL_RESULT_ERROR if there was an error
 *
 * @param pInfo (out) - pointer to CALmoduleInfo output
 *              structure.
 * @param ctx (in) - context.
 * @param module (in) - handle to the loaded image.
 * @param func (in) - name of the function.
 *
 * @return Returns CAL_RESULT_OK on success,
 *         CAL_RESULT_NOT_INITIALIZED,
 *         CAL_RESULT_INVALID_PARAMETER, CAL_RESULT_BAD_HANDLE,
 *         or CAL_RESULT_ERROR if there was an error.
 *
 *)
function calModuleGetFuncInfo(out Info:CALfuncInfo;const ctx:CALcontext;const module:CALmodule;const func:CALfunc):CALresult;stdcall;external _CALdll delayed;


(*----------------------------------------------------------------------------
 * CAL Error/Debug Helper Functions
 *----------------------------------------------------------------------------*)
(**
 * @fn calGetErrorString(void)
 *
 * @brief Return details about current error state
 *
 * calGetErrorString returns a text string containing details about the last
 * returned error condition. Calling calGetErrorString does not effect the
 * error state.
 *
 * @return Returns a null terminated string detailing the error condition
 *
 * @sa calInit calShutdown
 *)
function calGetErrorString:PAnsiChar;stdcall;external _CALdll delayed;


(*----------------------------------------------------------------------------
 * Utility functions  (not part of the original header)
 *----------------------------------------------------------------------------*)

{ CALdeviceinfo }

function CALdeviceinfo.dump: ansistring;
begin
  result:='CALdeviceinfo'#13#10+
          '  target : '+GetEnumName(typeinfo(CALtarget),ord(target))+#13#10+
          '  maxResource1DWidth : '+inttostr(maxResource1DWidth)+#13#10+
          '  maxResource2DWidth : '+inttostr(maxResource2DWidth)+#13#10+
          '  maxResource3DHeight : '+inttostr(maxResource2DHeight)+#13#10;
end;

{ CALdeviceattribs }

function CALdeviceattribs.dump: ansistring;
  function b2s(const b:boolean):ansistring;begin if b then result:='true' else result:='false'end;
begin
  result:='CALdeviceattribs'#13#10+
          '  target : '+GetEnumName(typeinfo(CALtarget),ord(target))+#13#10+
          '  localRAM : '+inttostr(localRAM)+' MB'#13#10+
          '  uncachedRemoteRAM : '+inttostr(uncachedRemoteRAM)+' MB'#13#10+
          '  cachedRemoteRAM : '+inttostr(cachedRemoteRAM)+' MB'#13#10+
          '  engineClock : '+inttostr(engineClock)+' MHz'#13#10+
          '  memoryClock : '+inttostr(memoryClock)+' MHz'#13#10+
          '  wavefrontSize : '+inttostr(wavefrontSize)+#13#10+
          '  numberOfSIMD : '+inttostr(numberOfSIMD)+#13#10+
          '  doublePrecision : '+b2s(doublePrecision)+#13#10+
          '  localDataShare : '+b2s(localDataShare)+#13#10+
          '  globalDataShare : '+b2s(globalDataShare)+#13#10+
          '  globalGPR : '+b2s(globalGPR)+#13#10+
          '  computeShader : '+b2s(computeShader)+#13#10+
          '  memExport : '+b2s(memExport)+#13#10+
          '  pitch_alignment : '+inttostr(pitch_alignment)+' elements'#13#10+
          '  surface_alignment : '+inttostr(surface_alignment)+' bytes'#13#10+
          '  numberOfUAVs : '+inttostr(numberOfUAVs)+#13#10+
          '  bUAVMemExport : '+b2s(bUAVMemExport)+#13#10+
          '  b3dProgramGrid : '+b2s(b3dProgramGrid)+#13#10+
          '  numberOfShaderEngines : '+inttostr(numberOfShaderEngines)+#13#10+
          '  targetRevision : '+inttostr(targetRevision)+#13#10;
end;

function CALdeviceattribs.VLIWSize: integer;
begin
  if target<CAL_TARGET_WRESTLER then result:=5 else result:=4;
end;

function CALdeviceattribs.streams: integer;
begin
  result:=numberOfSIMD*wavefrontSize shr 2*VLIWSize;
end;

function CALdeviceattribs.TFlops: single;
begin
  result:=engineClock*streams*2*1e-6{FMA};
end;

function CALdeviceattribs.targetSeries: integer;
begin
  if target<cal_target_7xx then exit(3);
  if target<cal_target_Cypress then exit(4);
  if target<cal_target_Wrestler then exit(5);
  if target<cal_target_Tahiti then exit(6);
  exit(7);
end;

function CALdeviceattribs.targetStr: ansistring;
begin
  result:=copy(GetEnumName(typeinfo(CalTarget),ord(target)),12);
end;

function CALdeviceattribs.description: ansistring;
begin
  result:=
    targetStr+
    '/'+inttostr(engineClock)+'MHz'+
    '/'+inttostr(streams)+'st'+
    '/'+inttostr(localRAM)+'MB'+
    '/'+FormatFloat('0.00',TFlops)+'TFlops';
end;

{ CALdevicestatus }

function CALdevicestatus.dump: ansistring;
begin
  result:='CALdevicestatus'#13#10+
          '  availLocalRAM : '+inttostr(availLocalRAM)+' MB'#13#10+
          '  availUncachedRemoteRAM : '+inttostr(availUncachedRemoteRAM)+' MB'#13#10+
          '  availCachedRemoteRAM : '+inttostr(availCachedRemoteRAM)+' MB'#13#10;
end;

{ CALdomain }

procedure CALdomain.setup(const AX, AY, AWidth, AHeight: CALuint);
begin
  x:=AX;y:=AY;width:=AWidth;height:=AHeight;
end;

//utility functions

procedure calCheck(const res:CALresult;const msg:ansistring);
begin
  if not(res in [CAL_RESULT_OK,CAL_RESULT_ALREADY])then
    raise Exception.Create(msg+' '+calGetErrorString+' '+GetEnumName(TypeInfo(CALResult),ord(res)));
end;

//cal system information
function CALInfo:AnsiString;
  procedure wr(const s:ansistring);begin result:=result+s+#13#10;end;
var cnt:cardinal;
    d:CALdevice;
    i:integer;
    di:CALdeviceinfo;
    da:CALdeviceattribs;
    ds:CALdevicestatus;
begin
  result:='';wr('CAL System Information');
  try
    calCheck(calInit,'Initializing CAL');

    calDeviceGetCount(cnt);
    wr('Number of CAL devices = '+IntToStr(cnt));
    for i:=0 to cnt-1 do begin
      wr('-------------- CalDevice '+inttostr(i)+' -------------');
      calDeviceGetInfo(di,i);wr(di.dump);
      da.struct_size:=sizeof(da);calDeviceGetAttribs(da,i);wr(da.dump);
      calDeviceOpen(d,i);
      ds.struct_size:=sizeof(ds);calDeviceGetStatus(ds,d);wr(ds.dump);
      calDeviceClose(d);
    end;
  except on e:Exception do wr(e.classname+' '+e.message); end;
end;

function CALTargetOfName(const AName:ansistring):CALtarget;
var t:CALtarget;
begin
  for t:=low(CALTarget)to high(CALTarget)do
    if pos(CALTargetStr[t],AName,[poIgnoreCase])>0 then exit(t);
  calCheck(CAL_RESULT_ERROR,'Invalid cal target name:"'+AName+'"');
end;

initialization

finalization
  calShutdown;
end.
