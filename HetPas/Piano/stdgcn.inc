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


///////////////////////////////////////////////////  Memory IO macros
// they need UAV and CB set up for dword access

  #macro s_read(dst, idx) enter
    s_buffer_load_dword  dst, UAV, idx ofsDWord
    s_waitcnt lgkmcnt(0)
  leave #endm

  #macro v_read(dst, idx) enter
    v_temp vAddr
    v_mov_b32 vAddr, (idx)
    buffer_load_dword  dst, vAddr, UAV, 0 idxen
    s_waitcnt vmcnt(0)
  leave #endm

  #macro v_read4(dst, idx) enter
    v_temp vAddr
    v_mov_b32 vAddr, (idx)
    buffer_load_dwordx4  dst, vAddr, UAV, 0 idxen
    s_waitcnt vmcnt(0)
  leave #endm

  #macro v_read8(dst, idx) enter v_temp vOfs
    v_mov_b32 vOfs, idx
    __for(i:=0 to 1, v_read4(dst[i*4], vOfs)  v_add_i32 vOfs, vcc, 4, vOfs)
  leave #endm

  #macro v_read16(dst, idx) enter v_temp vOfs
    v_mov_b32 vOfs, idx
    __for(i:=0 to 3, v_read4(dst[i*4], vOfs)  v_add_i32 vOfs, vcc, 4, vOfs)
  leave #endm

  #macro v_write(data, idx) enter
    v_temp vData, vAddr
    v_mov_b32 vData, data  v_mov_b32 vAddr, (idx)
    buffer_store_dword  vData, vAddr, UAV, 0 idxen
    s_waitcnt expcnt(0)
  leave #endm

  #macro v_dump(idx,val) //only writes when gid=DebugGID
    v_if_i32(gid=DebugGID)  write(idx,val)  _endif
  #endm

  #define v_dump(idx,val,cnt) __for__(i:=0 to cnt-1, v_dump((idx+i), val[i]) )


///////////////////////////////////////////////////  GDS macros

/*  #macro dsAddrCalc(dsAddrTmp,dsAddr)
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
  leave #endm*/


////////////////////////////////////////////////////////////////////////
///  KernelInit___(GrpSize,NumVGPRS,ldsSizeBytes) Init GCN kernel    ///
////////////////////////////////////////////////////////////////////////

function FindGCNDevice; //macroes are looking a bit silly here in the asm syntax highlighting
begin
  for var d in cl.devices where d.Info.TargetSeries>=7 do exit(d);
  raise exception.create("No GCN device found");
end;

)