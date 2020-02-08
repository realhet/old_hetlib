unit het.cl; //unsCl het.cal

//CL_CONTEXT_OFFLINE_DEVICES_AMD !!!

interface

uses
  windows, sysutils, types, ioutils, het.utils, het.Objects, uctypes, ucl, graphics,
  variants, het.Variants, math, het.Gfx, het.cal{for lits};

type
  TOclSection=(osSource, osLLVMir, osAMDIL, osExe);
  TOclSections=set of TOclSection;

const
  osExeOnly=[osExe];
  OclSectionNames:array[TOclSection]of ansistring=('source','llvmir','amdil','exe');

type
  TClObject=THetObject;

  TClDevice=class;
  TClDeviceInfo=class;
  TClKernel=class;
  TClBuffer=class;
  TClEvent=class;

  TClDeviceInfo=class(TClObject)
  private
    FId:integer;
    FVendor,FTargetStr,FDriverVer,FDeviceVer,FExtensions:ansistring;
    FCoreMHz,FComputeUnits,FCacheKB,FMemoryMB:integer;
    FTarget:CALTarget;
  published
    constructor Create(const AOwner:TClDevice;const ADeviceId:cl_device_id);reintroduce;
    property Id:integer read FId;
    property Vendor:ansistring read FVendor;
    property TargetStr:ansistring read FTargetStr;
    property CoreMHz:integer read FCoreMHz;
    property ComputeUnits:integer read FComputeUnits;
    property CacheKB:integer read FCacheKB;
    property MemoryMB:integer read FMemoryMB;
    property Extensions:ansistring read FExtensions;
    property Target:CALTarget read FTarget;

    function Streams: integer;
    function TargetSeries: integer;
    function VLIWSize: integer;
    function NumberOfSimd: integer;
    function WavefrontSize: integer;
    function TFlops: single;
    function LocalRam: integer;
    function engineClock: integer;
    function Dump(const showExtensions:boolean=true):AnsiString;
    function Description:ansistring;
  end;

  TClDevice=class(TClObject)
  private
    FDeviceId:cl_device_id;
    FContext:cl_context;
    FQueue:cl_command_queue;
    FInfo:TClDeviceInfo;
    function GetActive:boolean;
    procedure SetActive(const a:boolean);

  private
    //cached prototype
    last_proto_src:ansistring;
    last_proto_ocl:rawbytestring;
    function makePrototype(const proto_src:ansistring):rawbytestring;
  public
    constructor Create(const ADeviceId:cl_device_id);reintroduce;
    destructor Destroy;override;
    function NewKernel(const AImage:ansistring;const oclSkeleton:ansistring='';const AOclSections:TOclSections=osExeOnly):TClKernel;
    function NewBuffer(const AFlagsStr: ansistring; const ASize: integer):TClBuffer;
    property Active:boolean read GetActive write SetActive;
    procedure Activate;
    procedure Deactivate;
    function Info:TClDeviceInfo;
    function Dump:ansistring;
    procedure Flush;
    procedure Finish;
    property DeviceId:cl_device_id read FDeviceId;
  end;
  TClDevices=class(THetList<TClDevice>)public property ByIndex;default;end;

  TClBuffer=class(TClObject)
  private
    FBuffer:cl_mem;
    FSize:integer;
    FFlags:integer;
    FMap:pointer;
    FMapFlags:Integer;//rw
  public
    constructor Create(const AOwner:TClDevice;const AFlagsStr:ansistring;const ASize:integer);reintroduce;
    destructor Destroy;override;
    function OwnerDevice:TClDevice;
    property Size:integer read FSize;
    function Map(const rw:ansistring='rw'):Pointer;
    procedure UnMap;
  public//data access
    type TElementType=(etInt,etFloat);
    function ReadVArray(const AElementType:TElementType):Variant;

    procedure WriteVArray(const Src:variant);

    function ReadIntVArray:variant;
    property IntVArray:variant read ReadIntVArray write WriteVArray;

    function ReadFloatVArray:variant;
    property FloatVArray:variant read ReadFloatVArray write WriteVArray;

    function AccessData(Elementsize,x: integer):pointer;

    function AccessByte(x:integer):PByte;
    function AccessInt(x:integer):PInteger;
    function AccessInt64(x:integer):PInt64;
    function AccessFloat(x:integer):PSingle;
    function AccessDouble(x:integer):PDouble;

    function GetByte(x:integer):Byte;
    function GetInt(x:integer):Integer;
    function GetInt64(x:integer):Int64;
    function GetFloat(x:integer):Single;
    function GetDouble(x:integer):Double;

    procedure SetByte(x:integer;v:Byte);
    procedure SetInt(x:integer;v:integer);
    procedure SetInt64(x:integer;v:int64);
    procedure SetFloat(x:integer;v:single);
    procedure SetDouble(x:integer;v:double);

    property Bytes[x:integer]:Byte read GetByte write SetByte;
    property Ints[x:integer]:integer read GetInt write SetInt;
    property Int64s[x:integer]:int64 read GetInt64 write SetInt64;
    property Floats[x:integer]:single read GetFloat write SetFloat;
    property Doubles[x:integer]:double read GetDouble write SetDouble;

    procedure ImportBitmap(const bmp: TBitmap; const ofs: integer);
    function ExportBitmap(const ofs,w,h,bpp:integer):TBitmap;

    procedure ImportStr(const s:ansistring;const ofs:integer);
    function ExportStr(const ofs,size:integer):ansistring;

    procedure Clear;
  end;

  TClKernel=class(TClObject)
  private
    FImage:ansistring;
    FProgram:cl_program;
    FKernel:cl_kernel;
    FLiteralConsts:TLiteralConsts;
    FClCode,FILCode,FISACode,FName:ansistring;
    FNumThreadsPerGroup:array[0..2]of integer;
    function GetElfImage: ansistring;
  public
    constructor Create(const AOwner:TClDevice;const AImage:ansistring;const oclSkeleton:ansistring='';const AOclSections:TOclSections=osExeOnly);reintroduce;
    function OwnerDevice:TClDevice;
    procedure ApplyLiteralConsts(const buf: TClBuffer);
    function RunRange(const AWorkOffset, AWorkSize: cardinal;ABuf0:TClBuffer=nil;ABuf1:TClBuffer=nil;ABuf2:TClBuffer=nil;ABuf3:TClBuffer=nil):TClEvent;
    function Run(const AWorkSize: cardinal;ABuf0:TClBuffer=nil;ABuf1:TClBuffer=nil;ABuf2:TClBuffer=nil;ABuf3:TClBuffer=nil):TClEvent;
    property Name:ansistring read FName;
    property ElfImage:ansistring read GetElfImage;
    property ClCode:ansistring read FClCode;
    property ILCode:ansistring read FILCode;
    property ISACode:ansistring read FISACode;
    procedure Dump(DstDir:string);
    procedure SetArg(const idx: integer; const arg:Variant);overload;
    procedure SetArg(const idx: integer; const buf:TClBuffer);overload;
  end;

  TClEvent=class(TClObject)
  private
    FEvent:cl_event;
    FKernel:TClKernel;
    FRunning,FSuccess:boolean;
    T0,T1:double;
    procedure CheckEvent;
  public
    constructor Create(const AOwner:TClDevice;const AEvent:cl_event;const AKernel:TClKernel=nil);reintroduce;
    destructor Destroy;override;
    function OwnerDevice:TClDevice;

    function Running:boolean;
    function Finished:boolean;
    function Success:boolean;
    function ElapsedTime_sec:single;

    procedure WaitFor;
  end;

  Cl=class //Entry point to the whole thing
  private
    class var FDevices:TClDevices;
    class var FDefaultKernelName:ansistring;
  public
    class function Devices:TClDevices;
    class function CompileISA79xx(const AKernel:ansistring; const isGCN3:boolean):RawByteString;
    class function DefaultKernelName:ansistring;
    class procedure SetDefaultKernelName(n:ansistring);
    class procedure DumpElf(const ElfImage:ansistring; const DstDir:string);
  end;

procedure clChk(res:cl_int;const at:ansistring='');

implementation

uses ucal;//for amd_il in ocl

procedure clChk(res:cl_int;const at:ansistring='');
const list:array[0..49]of record s:ansistring;r:integer end=(
(s:'CL_SUCCESS'                                   ;r: 0),
(s:'CL_DEVICE_NOT_FOUND'                          ;r: -1),
(s:'CL_DEVICE_NOT_AVAILABLE'                      ;r: -2),
(s:'CL_DEVICE_COMPILER_NOT_AVAILABLE'             ;r: -3),
(s:'CL_MEM_OBJECT_ALLOCATION_FAILURE'             ;r: -4),
(s:'CL_OUT_OF_RESOURCES'                          ;r: -5),
(s:'CL_OUT_OF_HOST_MEMORY'                        ;r: -6),
(s:'CL_PROFILING_INFO_NOT_AVAILABLE'              ;r: -7),
(s:'CL_MEM_COPY_OVERLAP'                          ;r: -8),
(s:'CL_IMAGE_FORMAT_MISMATCH'                     ;r: -9),
(s:'CL_IMAGE_FORMAT_NOT_SUPPORTED'                ;r: -10),
(s:'CL_BUILD_PROGRAM_FAILURE'                     ;r: -11),
(s:'CL_MAP_FAILURE'                               ;r: -12),
(s:'CL_MISALIGNED_SUB_BUFFER_OFFSET'              ;r: -13),
(s:'CL_EXEC_STATUS_ERROR_FOR_EVENTS_IN_WAIT_LIST' ;r: -14),
(s:'CL_INVALID_VALUE'                   ;r: -30),
(s:'CL_INVALID_DEVICE_TYPE'             ;r: -31),
(s:'CL_INVALID_PLATFORM'                ;r: -32),
(s:'CL_INVALID_DEVICE'                  ;r: -33),
(s:'CL_INVALID_CONTEXT'                 ;r: -34),
(s:'CL_INVALID_QUEUE_PROPERTIES'        ;r: -35),
(s:'CL_INVALID_COMMAND_QUEUE'           ;r: -36),
(s:'CL_INVALID_HOST_PTR'                ;r: -37),
(s:'CL_INVALID_MEM_OBJECT'              ;r: -38),
(s:'CL_INVALID_IMAGE_FORMAT_DESCRIPTOR' ;r: -39),
(s:'CL_INVALID_IMAGE_SIZE'              ;r: -40),
(s:'CL_INVALID_SAMPLER'                 ;r: -41),
(s:'CL_INVALID_BINARY'                  ;r: -42),
(s:'CL_INVALID_BUILD_OPTIONS'           ;r: -43),
(s:'CL_INVALID_PROGRAM'                 ;r: -44),
(s:'CL_INVALID_PROGRAM_EXECUTABLE'      ;r: -45),
(s:'CL_INVALID_KERNEL_NAME'             ;r: -46),
(s:'CL_INVALID_KERNEL_DEFINITION'       ;r: -47),
(s:'CL_INVALID_KERNEL'                  ;r: -48),
(s:'CL_INVALID_ARG_INDEX'               ;r: -49),
(s:'CL_INVALID_ARG_VALUE'               ;r: -50),
(s:'CL_INVALID_ARG_SIZE'                ;r: -51),
(s:'CL_INVALID_KERNEL_ARGS'             ;r: -52),
(s:'CL_INVALID_WORK_DIMENSION'          ;r: -53),
(s:'CL_INVALID_WORK_GROUP_SIZE'         ;r: -54),
(s:'CL_INVALID_WORK_ITEM_SIZE'          ;r: -55),
(s:'CL_INVALID_GLOBAL_OFFSET'           ;r: -56),
(s:'CL_INVALID_EVENT_WAIT_LIST'         ;r: -57),
(s:'CL_INVALID_EVENT'                   ;r: -58),
(s:'CL_INVALID_OPERATION'               ;r: -59),
(s:'CL_INVALID_GL_OBJECT'               ;r: -60),
(s:'CL_INVALID_BUFFER_SIZE'             ;r: -61),
(s:'CL_INVALID_MIP_LEVEL'               ;r: -62),
(s:'CL_INVALID_GLOBAL_WORK_SIZE'        ;r: -63),
(s:'CL_INVALID_PROPERTY'                ;r: -64));
var i:integer;
begin
  if res=CL_SUCCESS then exit;
  for i:=0 to high(list)do with list[i]do if r=res then
    raise Exception.Create('OpenCL error: '+s+' '+at);
end;

function GenerateOclPrototype(bufferCfg:ansistring;global_id:boolean;attr:ansistring):ansistring;
                         // 'u':uav, 'c':constbuffer
var hdr,body,code,s,l:ansistring;
    i:integer;
begin
  for i:=1 to length(bufferCfg)do begin
    L:=ansichar(Ord('a')+i-1);
    s:=switch(bufferCfg[i]='c','__constant','__global')+' uint *'+L;
    listappend(hdr,s,', ');
    if i=1 then body:=L+'['+switch(global_id,'get_global_id(0)','3')+']=1'
           else body:=body+'+'+L+'['+tostr(i-1)+']';
  end;
  code:='__kernel '+attr+' void '+cl.DefaultKernelName+'('+hdr+') {'+#13#10+'  '+body+'; }';

  result:=code;
end;

procedure ReplaceOclElfSection(var elf:ansistring;const SectionName,Data:AnsiString);
//replaces a section and also changes size information in .symtab
var i,secIdx,symIdx:integer;
    Sym:PElfSym;
    SymHdr:PElfSect;
begin
  secIdx:=PElfHdr(elf).SectionIdxByName(SectionName,true);
  ReplaceElfSection(elf,secIdx,Data);
  //symbol table: set size of kernel
  symIdx:=PElfHdr(elf).SectionIdxByName('.symtab',true);
  Sym:=PElfHdr(elf).SectionData(symIdx);
  SymHdr:=PElfHdr(elf).shdr(symIdx);
  for i:=0 to SymHdr.size div SymHdr.entsize-1 do begin
    if Sym.shndx=secIdx then begin
      Sym.size:=Length(Data);
      break;
    end;
    Sym:=pSucc(Sym,SymHdr.entsize);
  end;
end;

function MakeIsa79xxOclELF(const ACode:rawbytestring;const AOptions:TIsa79xxOptions;const AProtoDevice:TClDevice):RawByteString;
var cal:ansistring;
    NoteProgramIdx:integer;

  procedure SetCalNote(key,orValue:cardinal;mask:cardinal=0);
  var p:PIntegerArray;
      i,len:integer;
  begin
    p:=PElfHdr(Cal).ProgramData(NoteProgramIdx);
    len:=PElfHdr(Cal).phdr(NoteProgramIdx).filesiz;
    for i:=0 to len shr 2-2 do
      if p[i]=integer(key) then
        p[i+1]:=p[i+1]and integer(mask)or integer(orValue);
  end;

var proto_src, proto_ocl, proto_cal, ocl, new_isa, sizeAttr: ansistring;
    ia: PIntegerArray;
    strip: boolean;

begin
  strip:=true;

  new_isa:=ACode;

  //make skeleton code
  with AOptions.NumThreadPerGroup do sizeAttr:=format('__attribute__((reqd_work_group_size(%d,%d,%d)))',[x,y,z]);

  with AOptions do if AOptions.OclSkeleton<>'' then
    proto_src:='__kernel '+sizeAttr+' '+OclSkeleton
  else proto_src:=GenerateOclPrototype(
    StrMul('u',AOptions.OclBuffers.uavCount)+StrMul('c',OclBuffers.cbCount),
    false,//kernel range cb
    sizeAttr
  );

  //generate prototype
  proto_ocl:=AProtoDevice.makePrototype(proto_src);

  //PElfHdr(proto_ocl).Dump('c:\dump\cat13.4_other\');

  proto_cal:=PElfHdr(proto_ocl).SectionContents(5);

  //put isa code into prototype
  cal:=proto_cal;

  if PElfHdr(cal).shdrcnt=6 then begin //new cal file format (cat 13.4)

(*---- ELF Section header ----
 # namestr     na ty fl     addr      ofs      siz      end li in al esiz
 0              0  0  0        0        0        0        0  0  0  0    0
 1.shstrtab     1  3  0        0       A8       28       D0  0  0  0    0
 2.text         B  1  0        0      5CC       24      5F0  0  0  0    0
 3.data        11  1  0        0      5F0     1280     1870  0  0  0 1280
 4.symtab      17  2  0        0     1870       10     1880  5  1  0   10
  Symbol                            value     size in ot shndx
                                        0        0  0  0    0
 5.strtab      1F  3  0        0     1880        2     1882  0  0  0    0
----ELF Program header----
 #        ty      ofs     vaddr    paddr  filesiz      end   memsiz fl al
 0  70000002       94        0        0       14       A8        0  0  0
  0000001C 00000004 000001C0 000016C2 00000000   *)

    ReplaceElfSection(cal,2,new_isa);
    if strip then begin
      ReplaceElfSection(cal,3,'');
    end;

    //recalculate prog0, typ:70000002 offsets/sizes
    with PElfHdr(cal)^ do begin
      ia:=ProgramData(0);
      ia[2]:=phdr(1).offset; ia[3]:=phdr(1).filesiz+phdr(2).filesiz;
    end;

    NoteProgramIdx:=1;
  end else if PElfHdr(cal).shdrcnt=10 then begin  //old cal file format

(*---- ELF Section header ----
 # namestr     na ty fl     addr      ofs      siz      end li in al esiz
 0              0  0  0        0        0        0        0  0  0  0    0
 1.shstrtab     1  3  0        0       FC       28      124  0  0  0    0
 2.text         B  1  0        0      4B0       E8      598  0  0  0    0
 3.data        11  1  0        0      598     1280     1818  0  0  0 1280
 4.symtab      17  2  0        0     1818       30     1848  5  1  0   10
  Symbol          value     size in ot shndx
                      0        0  0  0    0
  uav0                0        0  0  0   10
  cb0                 0        0  0  0    A
 5.strtab      1F  3  0        0     1848        B     1853  0  0  0    0
 6.text         B  1  0        0     1DDF       58     1E37  0  0  0    0
 7.data        11  1  0        0     1E37     1280     30B7  0  0  0 1280
 8.symtab      17  2  0        0     30B7       30     30E7  9  1  0   10
  Symbol          value     size in ot shndx
                      0        0  0  0    0
  uav0                0        0  0  0   10
  cb0                 0        0  0  0    A
 9.strtab      1F  3  0        0     30E7        B     30F2  0  0  0    0
----ELF Program header----
 #        ty      ofs     vaddr    paddr  filesiz      end   memsiz fl al
 0  70000002       D4        0        0       28       FC        0  0  0
  00000019 00000004 000002B4 0000159F 00000000
  0000001A 00000004 00001853 0000189F 00000000  *)

    ReplaceElfSection(cal,2,''); //amd_il = empty
    ReplaceElfSection(cal,6,new_isa);

    if strip then begin
      ReplaceElfSection(cal,3,''); //amd_il zeroes
      ReplaceElfSection(cal,7,''); //isa zeroes
    end;

    //recalculate prog0, typ:70000002 offsets/sizes
    with PElfHdr(cal)^ do begin
      ia:=ProgramData(0);
      ia[2]:=phdr(1).offset; ia[3]:=phdr(1).filesiz+phdr(2).filesiz;
      ia[7]:=phdr(3).offset; ia[8]:=phdr(3).filesiz+phdr(4).filesiz;
    end;

    NoteProgramIdx:=3;
  end else begin
    raise Exception.Create('MakeIsa79xxOclELF() Invalid cal.elf image');
  end;


  //set prog3 notes:
  with AOptions do begin
    SetCalNote($80001041,numvgprs);
    SetCalNote($80001042,numsgprs);
{    SetCalNote($8000001C,NumThreadPerGroup.x);
    SetCalNote($8000001D,NumThreadPerGroup.y);
    SetCalNote($8000001E,NumThreadPerGroup.z);  not needed because of __attribute__((reqd_work_group_size}
    SetCalNote($80000082,ldsSizeBytes);
    //compute_pgm_rsrc2
    SetCalNote($00002e13,(ldsSizeBytes+255)shr 8 shl 15,$FFF07FFF{and mask}); //lds size {256byte granularity}
    SetCalNote($00002e13,1 shl 7,$FFFFFF7F);   //tgid_x_en=1
  end;

  Ocl:=proto_ocl;

  //put new cal image into ocl prototype
  ReplaceOclElfSection(Ocl,'.text',Cal);

  //.rodata.LDSSize       rodata binary part is int[8]
  with PElfHdr(Ocl)^ do ia:=psucc(SectionData(4),shdr(4).size-8*4);
  ia[3]:=AOptions.ldsSizeBytes;  //also there is ;hwlocal:n in .rodata

  //attach Literal Constants if any
{  if ALiteralConsts<>nil then
    Ocl:=LiteralConstsToStr(ALiteralConsts)+Ocl;}

  result:=Ocl;
end;

procedure PatchVFetchFC153(var cal_elf:ansistring);
{ uav.read is bugged when compiled with calclcompile.
  01 TEX: ADDR(48) CNT(1)
        6  VFETCH R0.x___, R1.x, fc0   <- have to replace with fc153 (0x99 hex)
CF_WORD0: [23: 0]=addr
CF_WORD1: [15:10]=count-1 [29:22]=opcode (CF_INST_NOP=0;CF_INST_TC=1; CF_INST_END=32)
VTX_WORD0: [4:0] VC_INST (VC_INST_FETCH=0)  [15:8] BUFFER_ID <- have to be patched }

type
  t2=array[0..1]of cardinal; p2=^t2;
  t4=array[0..3]of cardinal; p4=^t4;

var cf:p2;
    vf:p4;
    codeBase,cfLast:pointer;
    codeSize,op,cnt,addr,i:integer;
begin
  codebase:=PElfHdr(cal_elf).SectionData(6);
  codesize:=PElfHdr(cal_elf).shdr(6).size;

  cf:=codebase;
  cfLast:=psucc(cf,codesize-8);

  //browse control flow
  while integer(cf)<=integer(cfLast)do begin
    op:=cf[1]shr 22 and $ff;
    case op of
      32:break; //CF_INST_END
      1:begin   //CF_INST_TC
        addr:=cf[0]and $FFFFFF shl 3;
        cnt:=cf[1]shr 10 and $3F+1;
        if inrange(cnt,0,16)and(addr<=codesize-16)then begin
          vf:=psucc(codeBase,addr);
          for i:=0 to Cnt-1 do begin
            if(vf[0]shr 8 and $ff)=0 then
              vf[0]:=vf[0] or $9900; //<- fc153 patch
            inc(vf);
          end;
        end;
      end;
    end;
    inc(cf);
  end;
end;

(*//old version, compiles with calclCompile
function MakeAMDILOclElf(const AIL:ansistring;const AClDev:TClDevice):ansistring;
const proto_code='__kernel void main(__global int* uav,__constant int* cb){ uav[get_global_id(0)]+=cb[0]; }';

var cal,ocl:AnsiString;
    ct:CALtarget;
begin
  //compile IL with CAL
  ct:=AClDev.Info.Target;
  cal:=calclBuild(AIL,ct);
  if ct<CAL_Target_Tahiti then
    PatchVFetchFC153(cal);

  //make ocl prototype
          //GenerateOclPrototype('uc',true,{'__attribute__((reqd_work_group_size(64,1,1)))'}'')
  with AClDev.NewKernel(proto_code)do begin
    ocl:=ElfImage; //Dump('c:\oclproto\');
    Free;
  end;
  //put new cal image into ocl prototype
  ReplaceOclElfSection(Ocl,'.text',cal);

  result:=ocl;
end;*)

function DetectWorkGroupSize(const il:ansistring;const default:integer=64):integer;
const instr='dcl_num_thread_per_group';
var line,s:ansistring;
begin
  for line in ListSplit(il,#10)do begin
    s:=listitem(line,0,';');
    if BeginsWith(s,instr,true)then begin
      delete(s,1,length(instr));
      exit(StrToIntDef(listitem(s,0,','),default));
    end;
  end;
  result:=default;
end;

function MakeAMDILOclElf(const AIL:ansistring;const AClDev:TClDevice):ansistring;
var proto_code, s:ansistring;
begin
  proto_code:='__kernel __attribute__((reqd_work_group_size(@thrd@,1,1))) void '+cl.DefaultKernelName+'(__global int* uav,__constant int* cb){ uav[get_global_id(0)]+=cb[0]; }';
  s:=ReplaceF('@thrd@',tostr(DetectWorkGroupSize(AIl,64)),proto_code,[roIgnoreCase]);
  with AClDev.NewKernel(s,'',[osAMDIL])do begin
    result:=ElfImage; //Dump('c:\!oclproto\');
    Free;
  end;
  ReplaceOclElfSection(result,'.amdil',AIL);
end;

////////////////////////////////////////////////////////////////////////////////
///  CL wrapper classes                                                     ///
////////////////////////////////////////////////////////////////////////////////

{ TClDeviceInfo }

constructor TClDeviceInfo.Create(const AOwner: TClDevice; const ADeviceId: cl_device_id);

  function getI(n:integer):integer;var i:integer;
  begin clChk(clGetDeviceInfo(ADeviceId,n,sizeof(i),@i,nil)); result:=i; end;

  function getI64(n:integer):integer;var i:int64;
  begin clChk(clGetDeviceInfo(ADeviceId,n,sizeof(i),@i,nil)); result:=i; end;

  function getS(n:integer):ansistring;var s:array[0..4095]of ansichar;
  begin clChk(clGetDeviceInfo(ADeviceId,n,sizeof(s),@s,nil)); result:=s; end;

begin
  inherited Create(AOwner);
  FId:=getI(CL_DEVICE_VENDOR_ID);
  FVendor:=getS(CL_DEVICE_VENDOR);
  FDriverVer:=getS(CL_DRIVER_VERSION);
  FDeviceVer:=getS(CL_DEVICE_VERSION);
  FTargetStr:=getS(CL_DEVICE_NAME);
  FComputeUnits:=getI(CL_DEVICE_MAX_COMPUTE_UNITS);
  FCoreMHz:=getI(CL_DEVICE_MAX_CLOCK_FREQUENCY);
  FCacheKB:=getI64(CL_DEVICE_GLOBAL_MEM_CACHE_SIZE)shr 10;
  FMemoryMB:=getI64(CL_DEVICE_GLOBAL_MEM_SIZE)shr 20;
  FExtensions:=GetS(CL_DEVICE_EXTENSIONS);

  try
    FTarget:=CALTargetOfName(FTargetStr);
  except
    FTarget:=CAL_TARGET_UNKNOWN;
  end;
end;

function TClDeviceInfo.Dump;
begin
  result:=format('Target: %s  Series: %d  Core:%d MHz  CU:%d  RAM:%d MB  UID:%d',
    [targetStr, targetSeries, CoreMHz, ComputeUnits, MemoryMB, Id]);
  if showExtensions then
    result:=result+'  Exts: ['+Extensions+']';
end;

function TClDeviceInfo.EngineClock:integer;     begin result:=coreMHz end;
function TClDeviceInfo.TargetSeries:integer;    begin result:=CALTargetSeries[Target] end;
function TClDeviceInfo.VLIWSize:integer;        begin if target<CAL_TARGET_WRESTLER then result:=5 else result:=4 end;
function TClDeviceInfo.NumberOfSimd:integer;    begin result:=computeUnits end;
function TClDeviceInfo.WavefrontSize:integer;   begin result:=64 end;
function TClDeviceInfo.Streams:integer;         begin result:=numberOfSIMD*wavefrontSize shr 2*VLIWSize end;
function TClDeviceInfo.TFlops: single;          begin result:=engineClock*streams*2*1e-6{FMA};end;
function TClDeviceInfo.LocalRam:integer;        begin result:=MemoryMB end;

function TClDeviceInfo.Description: ansistring;
begin
  result:=
    targetStr+
    '/'+inttostr(engineClock)+'MHz'+
    '/'+inttostr(streams)+'st'+
    '/'+inttostr(localRAM)+'MB'+
    '/'+FormatFloat('0.00',TFlops)+'TFlops';
end;

{ TClDevice }

procedure TClDevice.Activate;
begin
  Active:=true;
end;

constructor TClDevice.Create(const ADeviceId: cl_device_id);
begin
  inherited Create(cl.FDevices);
  FDeviceId:=ADeviceId;
end;

procedure TClDevice.Deactivate;
begin
  Active:=false;
end;

destructor TClDevice.Destroy;
begin
  Active:=false;
  FreeAndNil(FInfo);
  inherited;
end;

function TClDevice.Dump: ansistring;
begin
  result:=Info.Dump;
end;

procedure TClDevice.Finish;
begin
  if Active then clChk(clFinish(FQueue));
end;

procedure TClDevice.Flush;
begin
  if Active then clChk(clFlush(FQueue));
end;

procedure TClDevice.SetActive(const a: boolean);
var err:integer;
    o:THetObject;
    i:integer;
begin
  if Active=a then exit;
  if a then begin
    //create ctx, queue     1 device = 1 ctx, 1 queue
    FContext:=clCreateContext(nil,1,@FDeviceId,nil,nil,@err);clChk(err);
            FQueue:=clCreateCommandQueue(FContext,FDeviceId,CL_QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE,@err);clChk(err);
  end else begin
    //!!!!!!!!!!!!!!! itt fagy, ha megy valami!!!!!!! elvileg uj driverrel ok
    Finish;

    //drop related objects  ...ez lehet, hogy baromsag
    with FReferences do for i:=Count-1 downto 0 do begin
      o:=FItems[i];
      if(o.FOwner=self)and((o is TClKernel)or(o is TClBuffer))then
        o.Free
    end;

    clReleaseCommandQueue(FQueue);
    clReleaseContext(FContext);
    FQueue:=nil;FContext:=nil;
  end;
end;

function TClDevice.Info: TClDeviceInfo;
begin
  if FInfo=nil then FInfo:=TClDeviceInfo.Create(self,FDeviceId);
  result:=FInfo;
end;

function TClDevice.GetActive: boolean;
begin
  result:=FContext<>nil;
end;

function TClDevice.NewBuffer(const AFlagsStr: ansistring; const ASize: integer): TClBuffer;
begin
  result:=TClBuffer.Create(self,AFlagsStr,ASize);
end;

function TClDevice.NewKernel(const AImage:ansistring;const oclSkeleton:ansistring='';const AOclSections:TOclSections=osExeOnly):TClKernel;
begin
  Result:=TClKernel.Create(self,AImage,oclSkeleton,AOclSections);
end;

function TClDevice.makePrototype(const proto_src: ansistring): rawbytestring;
begin
  //generate prototype (cached)
  if last_proto_src<>proto_src then begin
    last_proto_src:=proto_src;
    with NewKernel(proto_src)do begin
      last_proto_ocl:=ElfImage;
      Free;
    end;
  end;

  result:=last_proto_ocl;
end;

{ TClBuffer }

function TClBuffer.OwnerDevice: TClDevice;
begin
  result:=TClDevice(FOwner);
end;

function StrToClMemFlags(const AFlagsStr: ansistring):integer;
var fl:integer;
    fs:AnsiString;
  procedure f(const s:ansistring;val:integer);
  begin
    if pos(s,fs,[])>0 then begin
      fl:=fl or val;
      replace(s,'',fs,[]);
    end;
  end;

begin
  //process flags
  fs:=LC(TrimF(AFlagsStr));fl:=0;
  f('rw',CL_MEM_READ_WRITE);
  f('r',CL_MEM_READ_ONLY);
  f('w',CL_MEM_WRITE_ONLY);
  f('u',CL_MEM_USE_HOST_PTR);
  f('a',CL_MEM_ALLOC_HOST_PTR);
  f('c',CL_MEM_COPY_HOST_PTR);
  if fs<>'' then raise Exception.Create('Invalid cl_mem flags "'+AFlagsStr+'". rw, r, w, u, a, c are valid. (use, alloc, copy hostptr)');
  result:=fl;
end;

constructor TClBuffer.Create(const AOwner:TClDevice;const AFlagsStr: ansistring; const ASize: integer);
var err:integer;
begin
  inherited Create(AOwner);
  FSize:=ASize;
  FFlags:=StrToClMemFlags(AFlagsStr);
  OwnerDevice.Active:=true;
  FBuffer:=clCreateBuffer(OwnerDevice.FContext, FFlags, FSize, nil, @err);clChk(err);
end;

destructor TClBuffer.Destroy;
begin
  UnMap;
  inherited;
end;

function StrToMemRW(const rw:ansistring):integer;
var fl:integer;
begin
  if lc(rw)='rw' then fl:=CL_MAP_READ+CL_MAP_WRITE else
  if lc(rw)='r' then fl:=CL_MAP_READ else
  if lc(rw)='w' then fl:=CL_MAP_WRITE else
    raise Exception.Create('StrToMemRW invalid RW specifier "'+rw+'". (valids: rw, r, w)');
  result:=fl;
end;

function TClBuffer.Map(const rw:ansistring='rw'): Pointer;
var fl,err:integer;
begin
  fl:=StrToMemRW(rw);
  if(FMap<>nil)and(fl and FMapFlags=fl)then exit(FMap);

  UnMap;
  FMapFlags:=fl;
  FMap:=clEnqueueMapBuffer(OwnerDevice.FQueue,FBuffer,CL_TRUE,FMapFlags,0,FSize,0,nil,nil,@err);
  clChk(err);

  result:=FMap;
end;

procedure TClBuffer.UnMap;
begin
  if FMap=nil then exit;
  clChk(clEnqueueUnmapMemObject(OwnerDevice.FQueue,FBuffer,FMap,0,nil,nil));
  FMap:=nil;
end;

// data access

procedure TClBuffer.WriteVArray(const Src:variant);
var P:Pointer;
    PMax:Pointer;

  procedure Advance(const size:integer);
  begin
    if cardinal(p)>=cardinal(pmax)then
      raise Exception.Create('TClBuffer.WriteVar out of range');
    pinc(p,size);
  end;

  procedure Append(const V:variant);
  var i:integer;
  begin
    if VarIsArray(V)   then begin
      with VarArrayAsPSafeArray(V)^ do for i:=0 to Bounds[0].ElementCount-1 do
        Append(VarArrayAccess(v,i)^);
    end else if VarIsOrdinal(V) then begin pinteger(p)^:=TVarData(V).VInteger;Advance(4)end else
    if VarIsFloat(V)   then begin psingle(p)^ :=single(V) ;Advance(4)end else
      raise Exception.Create('TClBuffer.WriteVar unhandled vartype');
  end;

begin
  P:=Map;
  PMax:=pSucc(P,Size);
  Append(Src);
end;

function TClBuffer.ReadVArray(const AElementType:TElementType):variant;
var bounds:array of integer;
    src:pointer;
    dst:pvariant;
    i,ComponentSize:integer;
begin
  src:=Map;
  SetLength(bounds,1);

  ComponentSize:=4;
  bounds[0]:=Size div ComponentSize;
  result:=VarArrayCreate(bounds,varVariant);
  with VarArrayAsPSafeArray(result)^ do begin
    dst:=Data;
    case AElementType of
      etInt:  for i:=0 to Bounds[0].ElementCount do begin dst^:=PInteger(src)^;pinc(src,4);inc(dst);end;
      etFloat:for i:=0 to Bounds[0].ElementCount do begin dst^:=PSingle (src)^;pinc(src,4);inc(dst);end;
    end;
  end;
end;

function TClBuffer.ReadIntVArray:variant;
begin
  result:=ReadVArray(etInt);
end;

function TClBuffer.ReadFloatVArray:variant;
begin
  result:=ReadVArray(etFloat);
end;

function TClBuffer.AccessData(Elementsize,x: integer):pointer;
begin
  x:=x*ElementSize;
  if not InRange(x,0,Size-elementSize)then
    raise Exception.Create('TClBufferData.AccessData() out of range '+tostr(x));
  result:=psucc(Map,x);
end;

function TClBuffer.AccessDouble(x: integer): PDouble;begin result:=AccessData(8,x);end;
function TClBuffer.AccessFloat(x: integer): PSingle;begin result:=AccessData(4,x);end;
function TClBuffer.AccessInt(x: integer): PInteger;begin result:=AccessData(4,x);end;
function TClBuffer.AccessInt64(x: integer): PInt64;begin result:=AccessData(8,x);end;
function TClBuffer.AccessByte(x: integer): PByte;begin result:=AccessData(1,x);end;

procedure TClBuffer.SetDouble(x: integer; v: double);begin AccessDouble(x)^:=v;end;
procedure TClBuffer.SetFloat(x: integer; v: single);begin AccessFloat(x)^:=v;end;
procedure TClBuffer.SetInt(x, v: integer);begin AccessInt(x)^:=v;end;
procedure TClBuffer.SetInt64(x:integer; v: int64);begin AccessInt64(x)^:=v;end;
procedure TClBuffer.SetByte(x:integer; v: byte);begin AccessByte(x)^:=v;end;

function TClBuffer.GetDouble(x: integer): Double;begin result:=AccessDouble(x)^ end;
function TClBuffer.GetFloat(x: integer): Single;begin result:=AccessFloat(x)^ end;
function TClBuffer.GetInt(x: integer): Integer;begin result:=AccessInt(x)^ end;
function TClBuffer.GetInt64(x: integer): Int64;begin result:=AccessInt64(x)^ end;
function TClBuffer.GetByte(x: integer): byte;begin result:=AccessByte(x)^ end;

procedure TClBuffer.ImportBitmap(const bmp: TBitmap; const ofs: integer);
begin
  if bmp<>nil then
    bmp.SaveToData(psucc(Map,ofs)^);
end;

function TClBuffer.ExportBitmap(const ofs, w, h, bpp: integer): TBitmap;
begin
  result:=TBitmap.CreateFromData(psucc(Map,ofs)^,w,h,bpp);
end;

procedure TClBuffer.ImportStr(const s:ansistring;const ofs:integer);
begin
  move(pointer(s)^, psucc(map('w'),ofs)^, length(s));
end;

function TClBuffer.ExportStr(const ofs,size:integer):ansistring;
begin
  setlength(result,size);
  move(psucc(map('r'),ofs)^, pointer(result)^, size);
end;

procedure TClBuffer.Clear;
begin
  FillChar(map('w')^,size,0);
end;

{ TClKernel }

function getRawFromComments(const s:RawByteString):RawByteString;
var i,minlen:integer;
    addr, d0, d1:cardinal;
    b64:boolean;
    p:PCardinal;
begin
//012345678901234567890123456789
  // 0000000C: EBA0101C 80010100

  i:=1; result:='';
  while true do begin
    i:=Pos('// 00', s, [], i);
    if i<=0 then break;

    if s[i+11]<>':' then i:=i+4; //GCN3 has a ridiculously large 48bit address field.

    addr:=StrToIntDef('$'+copy(s, i+ 3, 8), 0);
    d0  :=StrToIntDef('$'+copy(s, i+13, 8), 0);
    b64 :=TryStrToInt('$'+copy(s, i+22, 8), integer(d1));

    minlen:=addr+4; if b64 then inc(minlen, 4);

    if length(result)<minlen then setlength(result, minlen);
    p:=PCardinal(@result[addr+1]);
    p^:=d0;
    if b64 then begin inc(p); p^:=d1; end;

    inc(i, 20);
  end;
end;

function formatCLRXComments(const src:ansistring):ansistring;
var i,cnt:integer;
    s,sact,c:ansistring;
begin
  cnt:=0;
  with AnsiStringBuilder(result, true)do
    for sact in ListSplit(src, #10, false)do begin
      s:=TrimRight(sact);
      if BeginsWith(s, '/*')then begin
        i:=pos('*/', s);
        if i>0 then begin
          c:=copy(s, 3, i-3);
          delete(s, 1, i+2);

          s:=LeftJ('  '+s, 50)+' // '+IntToHex(cnt shl 2, 6)+': '+uc(c);
          if uc(charn(c,4  ))in['0'..'9','A'..'F'] then inc(cnt);
          if uc(charn(c,4+9))in['0'..'9','A'..'F'] then inc(cnt);
        end;
      end;
      AddLine(s);
    end;
end;

constructor TClKernel.Create(const AOwner:TClDevice;const AImage: ansistring;const oclSkeleton:ansistring='';const AOclSections:TOclSections=osExeOnly);

  function OclSectionParams:ansistring;
  var os:TOclSection;
  begin
    result:='';
    for os:=low(TOclSection)to high(TOclSection)do begin
//      if(os=osExe)and(os in AOclSections)then Continue;//-f-bin-exe is invalid, I guess it is straightforward
      ListAppend(result,'-f'+switch(os in AOclSections,'','no-')+'bin-'+OclSectionNames[os],' ');
    end;
  end;

  function GetBuildProgramInfo:ansistring;
  var len:integer;
      buf:array[0..$8000]of ansichar;
  begin
    clGetProgramBuildInfo(FProgram, OwnerDevice.FDeviceId, CL_PROGRAM_BUILD_LOG, sizeof(buf), @buf, @len);
    result:='log:'#13#10 + StrMake(@buf, len) + #13#10;
    clGetProgramBuildInfo(FProgram, OwnerDevice.FDeviceId, CL_PROGRAM_BUILD_STATUS, sizeof(buf), @buf, @len);
    result:=result+'status:'#13#10 + StrMake(@buf, len) + #13#10;
    clGetProgramBuildInfo(FProgram, OwnerDevice.FDeviceId, CL_PROGRAM_BUILD_OPTIONS, sizeof(buf), @buf, @len);
    result:=result+'options:'#13#10 + StrMake(@buf, len) + #13#10;

{
    size_t len;
    char *buffer;
    buffer = calloc(2048,sizeof(char));
    clGetProgramBuildInfo(program, &device_id, CL_PROGRAM_BUILD_LOG, 2048*sizeof(char), buffer, &len);
    printf("%s\n", buffer);
    clGetProgramBuildInfo(program, &device_id, CL_PROGRAM_BUILD_STATUS, 2048*sizeof(char), buffer, &len);
    printf("%s\n", buffer);
    clGetProgramBuildInfo(program, &device_id, CL_PROGRAM_BUILD_OPTIONS, 2048*sizeof(char), buffer, &len);
    printf("%s\n", buffer);
    return EXIT_FAILURE;}
  end;


const tempDir='c:\$ocl_tmp';
var len,err:Integer;
    fn, tempFn:string;
    i:integer;
    raw, rawGCN, s:RawByteString;
    Opts:TIsa79xxOptions;
    cmdline:ansistring;
    arch:integer;
begin
  inherited Create(AOwner);
  FImage:=StripLiteralConsts(AImage,FLiteralConsts);

  OwnerDevice.Active:=true;
  len:=Length(FImage);

  if FourCC(FImage)=_ElfMagic then begin//ELF image
    FProgram:=clCreateProgramWithBinary(
      OwnerDevice.FContext,1,@OwnerDevice.FDeviceId,@len,@FImage,nil,@err);clChk(err);
  end else if Pos('__kernel',FImage,[poWholeWords,poIgnoreCase])>0 then begin//OCL source
    FProgram:=clCreateProgramWithSource(
      OwnerDevice.FContext,1,@FImage,nil,nil);
  end else if pos('il_cs_2_0',FImage,[poWholeWords,poIgnoreCase])>0 then begin//AMDIL_source
    raw:=PreCompileIL(FImage,OwnerDevice.Info.Target,FLiteralConsts,lmLiteral,true);

    FILCode:=raw;
    raw:=MakeAMDILOclElf(raw,OwnerDevice);

//    TFile('c:\test_il.elf').write(raw);

    len:=length(raw);
    FProgram:=clCreateProgramWithBinary(OwnerDevice.FContext,1,@OwnerDevice.FDeviceId,@len,@raw,nil,@err);clChk(err);
  end else if pos('isa79xx',FImage,[poWholeWords,poIgnoreCase])>0 then begin
    raw:=CompileISA79xx(FImage, OwnerDevice.Info.TargetSeries=9, FLiteralConsts,Opts,rawGCN);
    if oclSkeleton<>'' then Opts.OclSkeleton:=oclSkeleton; //inject oclSkeleton
    raw:=MakeIsa79xxOclELF(raw,Opts,OwnerDevice);
    len:=length(raw);
    FProgram:=clCreateProgramWithBinary(OwnerDevice.FContext,1,@OwnerDevice.FDeviceId,@len,@raw,nil,@err);clChk(err);
  end else
    raise Exception.Create('TClKernel.Create() Unknown kernel image');

  try
    CreateDir(tempDir);
    for fn in TDirectory.GetFiles(TempDir)do DeleteFile(fn);

    //build
    cmdLine:='-save-temps='+tempDir+'\cl '+OclSectionParams;
    try
      clChk(clBuildProgram(FProgram,1,@OwnerDevice.FDeviceId,nil(*PAnsiChar(cmdLine)*),nil,nil));
    except
      raise Exception.Create('OpenCL Build Error: '+GetBuildProgramInfo);
    end;

    for fn in TDirectory.GetFiles(TempDir,'cl_*_*_*.isa')do begin //disasm
      if FName<>'' then
        raise Exception.Create('TClKernel.Create() multipe-funct kernels not supported');
      FName:=ChangeFileExt(ExtractFileName(fn),'');
      for i:=0 to 2 do FName:=copy(FName,Pos('_',FName)+1);  //got kernel name
      FISACode:=TFile(fn);

      rawGCN:=getRawFromComments(FISACode);
    end;

    //CLRX Disasm
    fn:=AppPath+'CLRX_Disasm.exe'; //CLRX Disassembler
    if(rawGCN<>'')and FileExists(fn)then begin
      arch:=-1;
      case OwnerDevice.Info.TargetSeries of
        7:arch:=0; //GCN1
        8:arch:=1; //GCN2
        9:arch:=2; //GCN3
      end;
      if arch>=0 then begin
        tempFn:=tempDir+'\temp.bin';
        TFile(tempFn).Write(rawGCN);
        Exec('cmd /c "'+fn+' '+IntToStr(arch)+' '+tempFn+' >> '+tempFn+'2', tempDir+'\', true);

        s:=formatCLRXComments(TFile(tempFn+'2').Read());
        if s<>'' then begin
          FISACode:=FISACode+#13#10+s;
        end;
      end;
    end;

    for fn in TDirectory.GetFiles(TempDir,'cl_*_*_*.il')do FILCode:=TFile(fn);
    for fn in TDirectory.GetFiles(TempDir,'cl_*.cl')do FClCode:=TFile(fn);
  finally
    for fn in TDirectory.GetFiles(TempDir)do DeleteFile(fn);
    RemoveDir(tempDir);
  end;

  //if FName='' then raise Exception.Create('TClKernel.Create() Unable to detect kernel name');
  if FName='' then FName:=cl.DefaultKernelName;

  try
    FKernel:=clCreateKernel(FProgram,pointer(FName),@err);clChk(err);
  except
    on e:exception do raise Exception.Create('Error in clCreateKernel() (wrong name?)'+e.ClassName+' '+e.Message);
  end;

  clChk(clGetKernelWorkGroupInfo(FKernel,OwnerDevice.FDeviceId,
    CL_KERNEL_COMPILE_WORK_GROUP_SIZE,SizeOf(FNumThreadsPerGroup),@FNumThreadsPerGroup,nil));
end;

function TClKernel.GetElfImage: ansistring;
var siz:integer;
begin
  //image is on 1 device only
  clChk(clGetProgramInfo(FProgram,CL_PROGRAM_BINARY_SIZES,4,@siz,nil));
  setlength(result,siz);
  clChk(clGetProgramInfo(FProgram,CL_PROGRAM_BINARIES,4,@result,nil));

  if FLiteralConsts<>nil then
    result:=LiteralConstsToStr(FLiteralConsts)+result;
end;

function TClKernel.OwnerDevice: TClDevice;
begin
  result:=TClDevice(FOwner);
end;

procedure TClKernel.Dump(DstDir: string);
begin
  if DstDir='' then DstDir:='.';
  DstDir:=IncludeTrailingPathDelimiter(DstDir);
  CreateDirForFile(DstDir+'a');
  TFile(DstDir+'kernel.elf').Write(ElfImage);
  if IlCode<>'' then TFile(DstDir+'kernel.il').Write(IlCode);
  if ClCode<>'' then TFile(DstDir+'kernel.cl').Write(ClCode);
  if ISACode<>'' then TFile(DstDir+'kernel.isa').Write(ISACode);
  cl.dumpElf(ElfImage, DstDir);
end;

procedure TClkernel.ApplyLiteralConsts(const buf:TClBuffer);
begin
  if(FLiteralConsts<>nil)and(buf<>nil)then
    het.cal.ApplyLiteralConsts(buf.Map('w'),FLiteralConsts);
end;

procedure TClKernel.SetArg(const idx:integer; const arg:variant);
var buf:TClBuffer;
begin
  try
    if VarIsObject(arg, TClBuffer)then begin
      buf:=TClBuffer(VarAsObject(arg));
      buf.UnMap;
      clChk(clSetKernelArg(FKernel, idx, 4, @buf.FBuffer));
    end else with TVarData(arg)do case VType of
      varInteger, varSingle: clChk(clSetKernelArg(FKernel, idx, 4, @VInteger));
      varInt64, varDouble:clChk(clSetKernelArg(FKernel, idx, 8, @VInt64));
    else
      raise Exception.Create('Unsupported Variant type: '+tostr(TVarData(arg).VType));
    end;
  except
    on e:exception do raise Exception.Create('TClKernel.SetArg('+tostr(idx)+') '+e.ClassName+' '+e.Message);
  end;
end;

procedure TClKernel.SetArg(const idx:integer; const buf:TClBuffer);
begin
  if buf=nil then exit;
  buf.UnMap;
  clChk(clSetKernelArg(FKernel, idx, 4, @buf.FBuffer));
end;

function TClKernel.RunRange(const AWorkOffset, AWorkSize: cardinal;ABuf0:TClBuffer=nil;ABuf1:TClBuffer=nil;ABuf2:TClBuffer=nil;ABuf3:TClBuffer=nil):TClEvent;
var ev:cl_event;
    p:pointer;
begin
  setarg(0,ABuf0);
  setarg(1,ABuf1);
  setarg(2,ABuf2);
  setarg(3,ABuf3);

  if FNumThreadsPerGroup[0]>0 then p:=@FNumThreadsPerGroup
                              else p:=nil;
  clChk(clEnqueueNDRangeKernel(OwnerDevice.FQueue, FKernel, 1, @AWorkOffset, @AWorkSize, p, 0, nil, @ev));

  Result:=TClEvent.Create(OwnerDevice,ev,self);
end;

function TClKernel.Run(const AWorkSize: cardinal;ABuf0:TClBuffer=nil;ABuf1:TClBuffer=nil;ABuf2:TClBuffer=nil;ABuf3:TClBuffer=nil):TClEvent;
begin
  result:=RunRange(0, AWorkSize, ABuf0, ABuf1, ABuf2, ABuf3);
end;

{ TClEvent }

constructor TClEvent.Create(const AOwner: TClDevice; const AEvent: cl_event;const AKernel:TClKernel=nil);
begin
  inherited Create(AOwner);
  FEvent:=AEvent;
  FKernel:=AKernel;

  T0:=QPS;T1:=T0;
  FRunning:=true;
end;

destructor TClEvent.Destroy;
begin
  if FEvent<>nil then begin
    clReleaseEvent(FEvent);
    FEvent:=nil;
  end;
  inherited;
end;

function TClEvent.OwnerDevice: TClDevice;
begin
  result:=TClDevice(FOwner);
end;

procedure TClEvent.CheckEvent;
var st,err:Integer;
    pending:boolean;
begin
  if FRunning then begin
    OwnerDevice.Flush;
    err:=clGetEventInfo(FEvent, CL_EVENT_COMMAND_EXECUTION_STATUS, 4, @st, nil);
    pending:=(err=CL_SUCCESS)and(st>0);
    if not pending then begin
      FRunning:=false;
      FSuccess:=(err=CL_SUCCESS)and(st=CL_COMPLETE);
      T1:=QPS;
    end;
  end;
end;

function TClEvent.ElapsedTime_sec: single;
begin
  CheckEvent;
  if FRunning then T1:=QPS;
  result:=(T1-T0);
end;

function TClEvent.Running: boolean;
begin
  CheckEvent;
  result:=FRunning;
end;

function TClEvent.Finished: boolean;
begin
  CheckEvent;
  result:=not FRunning;
end;

procedure TClEvent.WaitFor;
begin
//  while Running do;
  clWaitForEvents(1,@FEvent);//vegre van ilyen is 0% cpu-val elvileg
  CheckEvent;
end;

function TClEvent.Success: boolean;
begin
  WaitFor;
  result:=FSuccess;
end;

////////////////////////////////////////////////////////////////////////////////
///  CL wrapper base class                                                  ///
////////////////////////////////////////////////////////////////////////////////

class function Cl.CompileISA79xx(const AKernel: ansistring; const isGCN3:boolean): RawByteString;
var L:TLiteralConsts;
    O:TIsa79xxOptions;
    rawDisasm:RawByteString;
begin
  result:=het.cal.CompileISA79xx(AKernel,isGCN3,L,O,rawDisasm);
end;

class function Cl.Devices:TClDevices;
var i,cnt:integer;
    plt:cl_platform_id;
    devlist:TArray<cl_device_id>;
begin
  result:=FDevices;
  if Result=nil then begin
    result:=TClDevices.Create(nil);
    FDevices:=result;

    //collect all devices
    clChk(clGetPlatformIDs(1,@plt,nil));
    clChk(clGetDeviceIDs(plt,CL_DEVICE_TYPE_GPU,0,nil,@cnt));
    if cnt>0 then begin
      setlength(devlist,cnt);
      clChk(clGetDeviceIDs(plt,CL_DEVICE_TYPE_GPU,cnt,@devlist[0],nil));
      for i:=0 to high(devlist)do
        TClDevice.Create(devlist[i]);
    end;
  end;
end;

class function cl.DefaultKernelName:ansistring;
begin
  result:=FDefaultKernelName;
  if result='' then result:='kernel1';
end;

class procedure cl.SetDefaultKernelName(n:ansistring);
begin
  FDefaultKernelName:=n;
end;

class procedure Cl.DumpElf(const ElfImage:ansistring; const DstDir:string);
begin
  TFile(DstDir+'kernel.dump').Write(PElfHdr(ElfImage).Dump(DstDir));
end;


initialization
finalization
  //free cl before het.objects
  cl.FDevices.Free;
end.
