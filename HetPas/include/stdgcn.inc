asm_isa(

#define s_inc(x,i) s_add_u32 x, x, i
#define s_inc(x) s_inc(x, 1)


#macro s_if(relation)     script gcn_macrogen('if', ''     , relation);#endm
#macro s_if_i32(relation) script gcn_macrogen('if', 'si32' , relation);#endm
#macro s_if_u32(relation) script gcn_macrogen('if', 'su32' , relation);#endm
#macro v_if_i32(relation) script gcn_macrogen('if', 'vi32' , relation);#endm
#macro v_if_u32(relation) script gcn_macrogen('if', 'vu32' , relation);#endm
#macro v_if_i64(relation) script gcn_macrogen('if', 'vi64' , relation);#endm
#macro v_if_u64(relation) script gcn_macrogen('if', 'vu64' , relation);#endm
#macro v_if_f32(relation) script gcn_macrogen('if', 'vf32' , relation);#endm
#macro v_if_f64(relation) script gcn_macrogen('if', 'vf64' , relation);#endm

#macro _else            script gcn_macrogen('else'                 );#endm
#macro _endif           script gcn_macrogen('endif'                );#endm

#macro s_while(relation)     script gcn_macrogen('while', ''     , relation);#endm
#macro s_while_i32(relation) script gcn_macrogen('while', 'si32' , relation);#endm
#macro s_while_u32(relation) script gcn_macrogen('while', 'su32' , relation);#endm
#macro v_while_i32(relation) script gcn_macrogen('while', 'vi32' , relation);#endm
#macro v_while_u32(relation) script gcn_macrogen('while', 'vu32' , relation);#endm
#macro v_while_i64(relation) script gcn_macrogen('while', 'vi64' , relation);#endm
#macro v_while_u64(relation) script gcn_macrogen('while', 'vu64' , relation);#endm
#macro v_while_f32(relation) script gcn_macrogen('while', 'vf32' , relation);#endm
#macro v_while_f64(relation) script gcn_macrogen('while', 'vf64' , relation);#endm

#macro _endw            script gcn_macrogen('endw'                 );#endm

#macro s_repeat          script gcn_macrogen('repeat', 's'         );#endm
#macro v_repeat          script gcn_macrogen('repeat', 'v'         );#endm

#macro s_until(relation)     script gcn_macrogen('until', ''     , relation);#endm
#macro s_until_i32(relation) script gcn_macrogen('until', 'si32' , relation);#endm
#macro s_until_u32(relation) script gcn_macrogen('until', 'su32' , relation);#endm
#macro v_until_i32(relation) script gcn_macrogen('until', 'vi32' , relation);#endm
#macro v_until_u32(relation) script gcn_macrogen('until', 'vu32' , relation);#endm
#macro v_until_i64(relation) script gcn_macrogen('until', 'vi64' , relation);#endm
#macro v_until_u64(relation) script gcn_macrogen('until', 'vu64' , relation);#endm
#macro v_until_f32(relation) script gcn_macrogen('until', 'vf32' , relation);#endm
#macro v_until_f64(relation) script gcn_macrogen('until', 'vf64' , relation);#endm

#macro _break           script gcn_macrogen('break'                );#endm
#macro _continue        script gcn_macrogen('continue'             );#endm

#assign _labelIndex 0

///////////////////////////////////////////////////  simple math

///////////////////////////////////////////////////  simple If's //deprecated

//cannot be nested!!!!!!!

  #macro s_ifz(ifValue,_Then)
    #assign _labelIndex _labelIndex+1
    s_cmpk_eq_i32 ifValue,0
    s_cbranch_scc0 @_skip![_labelIndex]
      _Then
    @_skip![_labelIndex]:
  #endm

  #macro s_ifnz(ifValue,_Then)
    #assign _labelIndex _labelIndex+1
    s_cmpk_eq_i32 ifValue,0
    s_cbranch_scc1 @_skip![_labelIndex]
      _Then
    @_skip![_labelIndex]:
  #endm

///////////////////////////////////////////////////  Memory IO macros

  #macro uavAddrCalc(uavId,dwAddr,resAddr)
    v_mov_b32 resAddr, dwaddr
    v_lshlrev_b32 resAddr, 2, resAddr
    v_add_i32 resAddr, vcc, uav##uavId##ofs, resAddr
  #endm

  #macro uavWrite(uavId,dwaddr,value,AOption)  enter v_temp memAddr, memData
    uavAddrCalc(uavId,dwAddr,memAddr)
    v_mov_b32 memData, value
    tbuffer_store_format_x  memData, memAddr, uav##uavId##rsc, 0 offen format:[BUF_DATA_FORMAT_32,BUF_NUM_FORMAT_FLOAT] AOption
    s_waitcnt expcnt(0)
  leave #endm
  #define uavWrite(uavId,dwaddr,value) uavWrite(uavId,dwaddr,value,)

  #macro uavRead(uavid, dwaddr,value,AOption)  enter v_temp memAddr
    uavAddrCalc(uavId,dwAddr,memAddr)
    tbuffer_load_format_x value, memAddr, uav##uavId##rsc, 0 offen format:[BUF_DATA_FORMAT_32,BUF_NUM_FORMAT_FLOAT] AOption
    s_waitcnt vmcnt(0)
  leave #endm
  #define uavRead(uavid, dwaddr,value) uavRead(uavid, dwaddr,value,)

  #macro cbRead(cbId,dwaddr,value)  enter s_temp smemAddr
    s_mov_b32   smemAddr, dwaddr
    s_lshl_b32  smemAddr, smemAddr, 2
    s_buffer_load_dword  value, cb##cbId##rsc, smemAddr
    s_waitcnt   lgkmcnt(0)
  leave #endm

  #macro cbRead(dwaddr,value)
    cbRead(0,dwaddr,value)
  #endm

  #macro uavReads(uavId,dwaddr,value)  enter s_temp smemAddr
    s_mov_b32   smemAddr, dwaddr
    s_lshl_b32  smemAddr, smemAddr, 2
    s_add_i32   smemAddr, smemAddr, uav##uavId##ofs
    s_buffer_load_dword  value, uav##uavId##rsc, smemAddr
    s_waitcnt   lgkmcnt(0)
  leave #endm

///////////////////////////////////////////////////  HW_INFO stuff

  #define getWaveId(ghwRes)             s_getreg_b32 ghwRes, hwreg(HW_REG_HW_ID, 0, 4)
  #define getSIMDId(ghwRes)             s_getreg_b32 ghwRes, hwreg(HW_REG_HW_ID, 4, 2)
  #define getCUId(ghwRes)               s_getreg_b32 ghwRes, hwreg(HW_REG_HW_ID, 8, 4)
  #define getSHId(ghwRes)               s_getreg_b32 ghwRes, hwreg(HW_REG_HW_ID,12, 1){shader array}
  #define getSEId(ghwRes)               s_getreg_b32 ghwRes, hwreg(HW_REG_HW_ID,13, 2){shader engine}
  #define getThreadGroupId(ghwRes)      s_getreg_b32 ghwRes, hwreg(HW_REG_HW_ID,16, 4)
  #define getVirtualMemoryId(ghwRes)    s_getreg_b32 ghwRes, hwreg(HW_REG_HW_ID,20, 4)
  #define getRingId(ghwRes)             s_getreg_b32 ghwRes, hwreg(HW_REG_HW_ID,24, 3)
  #define getStateId(ghwRes)            s_getreg_b32 ghwRes, hwreg(HW_REG_HW_ID,27, 3){graphics only}

  #macro getGlobalSIMDId(ggsRes) enter s_temp ggsTmp
    getCUId(ggsRes)   {0..4}
    s_lshl_b32 ggsRes,ggsRes,1
    getSHId(ggsTmp)   {0..1}
    s_add_i32  ggsRes,ggsRes,ggsTmp //global CU id
    s_lshl_b32 ggsRes,ggsRes,2
    getSIMDId(ggsTmp) {0..3}
    s_add_i32  ggsRes,ggsRes,ggsTmp //global SIMD id
  leave #endm

///////////////////////////////////////////////////  GDS macros

  #macro dsAddrCalc(dsAddrTmp,dsAddr)
    v_mov_b32 dsAddrTmp,dsAddr
    s_mov_b32 m0, $FFFF             // M0!!!!!!!
    v_lshlrev_b32 dsAddrTmp, 2, dsAddrTmp
  #endm

  #macro gdsWrite(gwAddr,gwData) enter v_temp gwAddrTmp,gwDataTmp
    dsAddrCalc(gwAddrTmp,gwAddr)
    v_mov_b32 gwDataTmp,gwData
    ds_write_b32 gwAddrTmp, gwDataTmp gds
    s_waitcnt expcnt(0)
  leave #endm

  #macro gdsRead(gwAddr,gwData) enter v_temp gwAddrTmp
    dsAddrCalc(gwAddrTmp,gwAddr)
    ds_read_b32 gwData, gwAddrTmp gds
    s_waitcnt lgkmcnt(0)
  leave #endm

  #macro gdsAdd(gwAddr,gwData) enter v_temp gwAddrTmp, gwDataTmp
    dsAddrCalc(gwAddrTmp,gwAddr)
    v_mov_b32 gwDataTmp,gwData
    ds_add_u32 gwAddrTmp, gwDataTmp gds
    s_waitcnt lgkmcnt(0)
  leave #endm

///////////////////////////////////////////////////  Synch macroes

  #macro gwsInit(gwsId,gwsThreads) enter v_temp _gwsThreads
    v_mov_b32 _gwsThreads,(gwsThreads)
    ds_gws_init _gwsThreads offset0:gwsId gds
    s_waitcnt lgkmcnt(0)
  leave #endm

  #macro gwsBarrier(gwsId)
    ds_gws_barrier v0 offset0:gwsId gds
    s_waitcnt lgkmcnt(0)
  #endm

///////////////////////////////////////////////////  Timing macroes

  //initialize start tick
  #macro _getTickInit
    s_temp _getTickT0  //global: kernel start time
    enter s_temp tmp[2] align:2
      s_memtime tmp[0]
      s_waitcnt lgkmcnt(0)
      s_mov_b32 _getTickT0, tmp[0]
    leave
  #endm

  #macro getTick(gtRes)
  enter s_temp gtTmp[2] align:2
    s_memtime gtTmp[0]
    s_waitcnt lgkmcnt(0)
    s_sub_u32 gtRes, gtTmp[0], _getTickT0
  leave #endm

  #macro breakOnTimeOut(botTimeoutMS)
  enter s_temp botTmp
    getTick(botTmp)
    s_cmp_ge_u32 botTmp, botTimeoutMS*1000000
    s_cbranch_scc0 1 //16bit index, 1 = 4 bytes!!
      s_endpgm
  leave #endm

  #macro _KernelStartup

  #endm

////////////////////////////////////////////////////////////////////////
///  KernelInit___(GrpSize,NumVGPRS,ldsSizeBytes) Init GCN kernel    ///
////////////////////////////////////////////////////////////////////////

{  ____ marks parameter configuration eg. UUUC meanc 3 UAVs and a CB

  Initializes the following:
   - sets WorkGroupSize
   - numgprs, oclBuffers
   - grpId, lid, gid
   - loads uav#rsc and cb#Rsc resource constants
   - loads uav#ofs offsets
   - clears m0
   - sets v_temp and s_temp ranges  }

  #macro _CalculateKernelIDs(AGrpSize,AUserSGPR)  {result:s0,v0,v1 uses s40!!!!}
    alias grpId=s0, lid=v0, gid=v1
    s_mov_b32 grpId, AUserSGPR
    s_mul_i32 s40, grpId, AGrpSize
    v_add_i32 gid, vcc, s40, lid
  #endm

  #macro _KernelHeader(AGrpSize,ANumVGPRS,ALdsSizeBytes)
    isa79xx
    numVgprs ANumVGPRS  numSgprs 105  //used registers
    numThreadPerGroup AGrpSize
    ldssize ALdsSizeBytes
    #assign maxvgprs ANumVGPRS-1
  #endm

  #macro _KernelStartup
    s_mov_b32 m0, $FFFF
    _getTickInit
  #endm

  #macro KernelInitUUUC(AGrpSize,ANumVGPRS,ALdsSizeBytes)
    _KernelHeader(AGrpSize,ANumVGPRS,ALdsSizeBytes)

    //Parameter specific stuff ------------------------------
    //uuuc   grpid=s12 a=dwx4(s[2:3],0x50) ofs dw(s[4:7],0)
    //              b=dwx4(s[2:3],0x58) ofs dw(s[4:7],4)
    //              c=dwx4(s[2:3],0x60) ofs dw(s[4:7],8)
    //              d=s[8:11] ofs 0

    oclBuffers 3,1                     //3 uavs, 1 cb
    //calculate kernel Id's
    _CalculateKernelIDs(AGrpSize,s12)  //s12: USER_SGPR

    //get kernel parameter resources and offsets UUUC
    alias uav0rsc=s[12:15], uav1rsc=s[16:19], uav2rsc=s[20:23]
    s_load_dwordx4 uav0rsc, s[2:3], 0x50
    s_load_dwordx4 uav1rsc, s[2:3], 0x58
    s_load_dwordx4 uav2rsc, s[2:3], 0x60
    alias uav0ofs=s24, uav1ofs=s25, uav2ofs=s26
    s_load_dword uav0ofs, s[4:7], 0x00
    s_load_dword uav1ofs, s[4:7], 0x04
    s_load_dword uav2ofs, s[4:7], 0x08
    s_waitcnt lgkmcnt(0)

    //access CB resource
    alias cb0rsc=s[8:11]

    //setup temp registers
    s_temp_range 1..7, 27..103
    v_temp_range 2..![maxvgprs]  //!!!! parser error: .maxvgprs is not detected as a word

    //end of parameter specific stuff ------------------------

    _KernelStartup
  #endm

  #macro KernelInitUU(AGrpSize,ANumVGPRS,ALdsSizeBytes)
    _KernelHeader(AGrpSize,ANumVGPRS,ALdsSizeBytes)

    //Parameter specific stuff ------------------------------
    //uu        s16          a=s[4:7] ofs dw(s[12:15],0)
    //                       b=s[8:11] ofs dw(s[12:15],4)

    oclBuffers 2,0                     //3 uavs, 1 cb
    //calculate kernel Id's
    _CalculateKernelIDs(AGrpSize,s16)  //s16: USER_SGPR

    //get kernel parameter resources and offsets UUUC
    alias uav0rsc=s[4:7], uav1rsc=s[8:11]
    alias uav0ofs=s1, uav1ofs=s2
    s_load_dword uav0ofs, s[12:15], 0x00
    s_load_dword uav1ofs, s[12:15], 0x04
    s_waitcnt lgkmcnt(0)

    //setup temp registers  //s0:grpId v0:gid v1:
    s_temp_range 3, 12..103
    v_temp_range 2..![maxvgprs]

    //end of parameter specific stuff ------------------------

    _KernelStartup
  #endm

  #macro KernelInitUC(AGrpSize,ANumVGPRS,ALdsSizeBytes)
    _KernelHeader(AGrpSize,ANumVGPRS,ALdsSizeBytes)

    //Parameter specific stuff ------------------------------
    //uc       s16      a=s[4:7] ofs dw(s[8:11],0)
    //                  b=s[12:15] ofs 0

    oclBuffers 1,1                     //1 uav, 1 cb
    //calculate kernel Id's
    _CalculateKernelIDs(AGrpSize,s16)  //s16: USER_SGPR

    //get kernel parameter resources and offsets UUUC
    alias uav0rsc=s[4:7]
    alias uav0ofs=s1
    s_load_dword uav0ofs, s[8:11], 0x00
    s_waitcnt lgkmcnt(0)

    //access CB resource
    alias cb0rsc=s[12:15]

    //setup temp registers  //s0:grpId v0:gid v1:
    s_temp_range 2..3, 8..11, 16..103
    v_temp_range 2..![maxvgprs]

    //end of parameter specific stuff ------------------------

    _KernelStartup
  #endm

  #macro KernelInitU(AGrpSize,ANumVGPRS,ALdsSizeBytes)
    _KernelHeader(AGrpSize,ANumVGPRS,ALdsSizeBytes)

    //Parameter specific stuff ------------------------------
    //uc       s12      a=s[4:7] ofs dw(s[8:11],0)

    oclBuffers 1,0
    //calculate kernel Id's
    _CalculateKernelIDs(AGrpSize,s12)  //s12: USER_SGPR

    //get kernel parameter resources and offsets U
    alias uav0rsc=s[4:7]
    alias uav0ofs=s1
    s_load_dword uav0ofs, s[8:11], 0x00
    s_waitcnt lgkmcnt(0)

    //setup temp registers  //s0:grpId v0:gid v1:
    s_temp_range 2..3, 8..103
    v_temp_range 2..![maxvgprs]

    //end of parameter specific stuff ------------------------

    _KernelStartup
  #endm

(*////////////////////////////////////////////
///  OpenCL dummy kernel                   ///
//////////////////////////////////////////////

procedure CompileOpenclDummyKernel;
begin
  var code:='
    __kernel __attribute__((reqd_work_group_size(64,1,1)))
    void main(__global int* uav0, __global int* uav1, __global int* uav2, __constant int* cb)
    {
      uav0[0x20]+=cb[0x10];
      uav1[0x21]+=cb[0x21];
      uav2[0x22]+=cb[0x32];
    }';

  var kernel:=dev.NewKernel(code);
  writeln(kernel.ISACode);  //show disasm
  kernel.free;
end;

//CompileOpenclDummyKernel;  *)

function FindGCNDevice; //macroes are looking a bit silly here in the asm syntax highlighting
begin
  for var d in cl.devices where d.Info.TargetSeries>=7 do exit(d);
  raise exception.create("No GCN device found");
end;

)

