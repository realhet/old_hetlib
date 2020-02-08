unit het.FastRtl;

interface

var
  FastMoveCacheLimit:integer=3 shl 20; //should set to half of the cache size of one processor core

procedure FastMove(const src;var dst;size:integer);
function _TestFastMove:ansistring;

implementation

uses
  Windows, SysUtils, het.utils;

////////////////////////////////////////////////////////////////////////////////
///  FastMove                                                  real_het 2011 ///
////////////////////////////////////////////////////////////////////////////////

{$R-}{$O+}

procedure FastMove(const src;var dst;size:integer);

  procedure _SSE_Move64_fwd_nocache(dst,dstEnd:pointer;dstToSrc:integer);
  asm
  @@1:
    movups xmm0,[eax+ecx+$00]
    movups xmm1,[eax+ecx+$10]
    movups xmm2,[eax+ecx+$20]
    movups xmm3,[eax+ecx+$30]
    movntps [eax+$00],xmm0 prefetchnta [eax+ecx+$100]
    movntps [eax+$10],xmm1 add eax,$40
    movntps [eax+$20-$40],xmm2
    movntps [eax+$30-$40],xmm3 cmp eax,edx jne @@1
  end;

  procedure _SSE_Move64_fwd_cache(dst,dstEnd:pointer;dstToSrc:integer);

    procedure A1;const a=1;//reference implementation
    asm
      movdqa xmm0,[eax+ecx+$00]
    @@1:
      movdqa xmm1,[eax+ecx+$10]
      movdqa xmm2,[eax+ecx+$20]  movdqa xmm7,xmm1  palignr xmm1,xmm0,a
      movdqa xmm3,[eax+ecx+$30]  movdqa xmm6,xmm2  palignr xmm2,xmm7,a
      movdqa xmm4,[eax+ecx+$40]  movdqa xmm5,xmm3  palignr xmm3,xmm6,a
      movdqa [eax+$00    ],xmm1  movdqa xmm0,xmm4  palignr xmm4,xmm5,a
      movdqa [eax+$10    ],xmm2  add eax,$40
      movdqa [eax+$20-$40],xmm3  prefetchnta [eax+ecx+$100]
      movdqa [eax+$30-$40],xmm4  cmp eax,edx jne @@1
    end;

    //copy+paste
    procedure A2;const a=$2;asm movdqa xmm0,[eax+ecx+$00];@@1:;movdqa xmm1,[eax+ecx+$10];movdqa xmm2,[eax+ecx+$20]  movdqa xmm7,xmm1  palignr xmm1,xmm0,a;movdqa xmm3,[eax+ecx+$30]  movdqa xmm6,xmm2  palignr xmm2,xmm7,a;movdqa xmm4,[eax+ecx+$40]  movdqa xmm5,xmm3  palignr xmm3,xmm6,a;movdqa [eax+$00    ],xmm1  movdqa xmm0,xmm4  palignr xmm4,xmm5,a;movdqa [eax+$10    ],xmm2  add eax,$40;movdqa [eax+$20-$40],xmm3  prefetchnta [eax+ecx+$100];movdqa [eax+$30-$40],xmm4  cmp eax,edx jne @@1 ret;end;
    procedure A3;const a=$3;asm movdqa xmm0,[eax+ecx+$00];@@1:;movdqa xmm1,[eax+ecx+$10];movdqa xmm2,[eax+ecx+$20]  movdqa xmm7,xmm1  palignr xmm1,xmm0,a;movdqa xmm3,[eax+ecx+$30]  movdqa xmm6,xmm2  palignr xmm2,xmm7,a;movdqa xmm4,[eax+ecx+$40]  movdqa xmm5,xmm3  palignr xmm3,xmm6,a;movdqa [eax+$00    ],xmm1  movdqa xmm0,xmm4  palignr xmm4,xmm5,a;movdqa [eax+$10    ],xmm2  add eax,$40;movdqa [eax+$20-$40],xmm3  prefetchnta [eax+ecx+$100];movdqa [eax+$30-$40],xmm4  cmp eax,edx jne @@1 ret;end;
    procedure A4;const a=$4;asm movdqa xmm0,[eax+ecx+$00];@@1:;movdqa xmm1,[eax+ecx+$10];movdqa xmm2,[eax+ecx+$20]  movdqa xmm7,xmm1  palignr xmm1,xmm0,a;movdqa xmm3,[eax+ecx+$30]  movdqa xmm6,xmm2  palignr xmm2,xmm7,a;movdqa xmm4,[eax+ecx+$40]  movdqa xmm5,xmm3  palignr xmm3,xmm6,a;movdqa [eax+$00    ],xmm1  movdqa xmm0,xmm4  palignr xmm4,xmm5,a;movdqa [eax+$10    ],xmm2  add eax,$40;movdqa [eax+$20-$40],xmm3  prefetchnta [eax+ecx+$100];movdqa [eax+$30-$40],xmm4  cmp eax,edx jne @@1 ret;end;
    procedure A5;const a=$5;asm movdqa xmm0,[eax+ecx+$00];@@1:;movdqa xmm1,[eax+ecx+$10];movdqa xmm2,[eax+ecx+$20]  movdqa xmm7,xmm1  palignr xmm1,xmm0,a;movdqa xmm3,[eax+ecx+$30]  movdqa xmm6,xmm2  palignr xmm2,xmm7,a;movdqa xmm4,[eax+ecx+$40]  movdqa xmm5,xmm3  palignr xmm3,xmm6,a;movdqa [eax+$00    ],xmm1  movdqa xmm0,xmm4  palignr xmm4,xmm5,a;movdqa [eax+$10    ],xmm2  add eax,$40;movdqa [eax+$20-$40],xmm3  prefetchnta [eax+ecx+$100];movdqa [eax+$30-$40],xmm4  cmp eax,edx jne @@1 ret;end;
    procedure A6;const a=$6;asm movdqa xmm0,[eax+ecx+$00];@@1:;movdqa xmm1,[eax+ecx+$10];movdqa xmm2,[eax+ecx+$20]  movdqa xmm7,xmm1  palignr xmm1,xmm0,a;movdqa xmm3,[eax+ecx+$30]  movdqa xmm6,xmm2  palignr xmm2,xmm7,a;movdqa xmm4,[eax+ecx+$40]  movdqa xmm5,xmm3  palignr xmm3,xmm6,a;movdqa [eax+$00    ],xmm1  movdqa xmm0,xmm4  palignr xmm4,xmm5,a;movdqa [eax+$10    ],xmm2  add eax,$40;movdqa [eax+$20-$40],xmm3  prefetchnta [eax+ecx+$100];movdqa [eax+$30-$40],xmm4  cmp eax,edx jne @@1 ret;end;
    procedure A7;const a=$7;asm movdqa xmm0,[eax+ecx+$00];@@1:;movdqa xmm1,[eax+ecx+$10];movdqa xmm2,[eax+ecx+$20]  movdqa xmm7,xmm1  palignr xmm1,xmm0,a;movdqa xmm3,[eax+ecx+$30]  movdqa xmm6,xmm2  palignr xmm2,xmm7,a;movdqa xmm4,[eax+ecx+$40]  movdqa xmm5,xmm3  palignr xmm3,xmm6,a;movdqa [eax+$00    ],xmm1  movdqa xmm0,xmm4  palignr xmm4,xmm5,a;movdqa [eax+$10    ],xmm2  add eax,$40;movdqa [eax+$20-$40],xmm3  prefetchnta [eax+ecx+$100];movdqa [eax+$30-$40],xmm4  cmp eax,edx jne @@1 ret;end;
    procedure A8;const a=$8;asm movdqa xmm0,[eax+ecx+$00];@@1:;movdqa xmm1,[eax+ecx+$10];movdqa xmm2,[eax+ecx+$20]  movdqa xmm7,xmm1  palignr xmm1,xmm0,a;movdqa xmm3,[eax+ecx+$30]  movdqa xmm6,xmm2  palignr xmm2,xmm7,a;movdqa xmm4,[eax+ecx+$40]  movdqa xmm5,xmm3  palignr xmm3,xmm6,a;movdqa [eax+$00    ],xmm1  movdqa xmm0,xmm4  palignr xmm4,xmm5,a;movdqa [eax+$10    ],xmm2  add eax,$40;movdqa [eax+$20-$40],xmm3  prefetchnta [eax+ecx+$100];movdqa [eax+$30-$40],xmm4  cmp eax,edx jne @@1 ret;end;
    procedure A9;const a=$9;asm movdqa xmm0,[eax+ecx+$00];@@1:;movdqa xmm1,[eax+ecx+$10];movdqa xmm2,[eax+ecx+$20]  movdqa xmm7,xmm1  palignr xmm1,xmm0,a;movdqa xmm3,[eax+ecx+$30]  movdqa xmm6,xmm2  palignr xmm2,xmm7,a;movdqa xmm4,[eax+ecx+$40]  movdqa xmm5,xmm3  palignr xmm3,xmm6,a;movdqa [eax+$00    ],xmm1  movdqa xmm0,xmm4  palignr xmm4,xmm5,a;movdqa [eax+$10    ],xmm2  add eax,$40;movdqa [eax+$20-$40],xmm3  prefetchnta [eax+ecx+$100];movdqa [eax+$30-$40],xmm4  cmp eax,edx jne @@1 ret;end;
    procedure AA;const a=$A;asm movdqa xmm0,[eax+ecx+$00];@@1:;movdqa xmm1,[eax+ecx+$10];movdqa xmm2,[eax+ecx+$20]  movdqa xmm7,xmm1  palignr xmm1,xmm0,a;movdqa xmm3,[eax+ecx+$30]  movdqa xmm6,xmm2  palignr xmm2,xmm7,a;movdqa xmm4,[eax+ecx+$40]  movdqa xmm5,xmm3  palignr xmm3,xmm6,a;movdqa [eax+$00    ],xmm1  movdqa xmm0,xmm4  palignr xmm4,xmm5,a;movdqa [eax+$10    ],xmm2  add eax,$40;movdqa [eax+$20-$40],xmm3  prefetchnta [eax+ecx+$100];movdqa [eax+$30-$40],xmm4  cmp eax,edx jne @@1 ret;end;
    procedure AB;const a=$B;asm movdqa xmm0,[eax+ecx+$00];@@1:;movdqa xmm1,[eax+ecx+$10];movdqa xmm2,[eax+ecx+$20]  movdqa xmm7,xmm1  palignr xmm1,xmm0,a;movdqa xmm3,[eax+ecx+$30]  movdqa xmm6,xmm2  palignr xmm2,xmm7,a;movdqa xmm4,[eax+ecx+$40]  movdqa xmm5,xmm3  palignr xmm3,xmm6,a;movdqa [eax+$00    ],xmm1  movdqa xmm0,xmm4  palignr xmm4,xmm5,a;movdqa [eax+$10    ],xmm2  add eax,$40;movdqa [eax+$20-$40],xmm3  prefetchnta [eax+ecx+$100];movdqa [eax+$30-$40],xmm4  cmp eax,edx jne @@1 ret;end;
    procedure AC;const a=$C;asm movdqa xmm0,[eax+ecx+$00];@@1:;movdqa xmm1,[eax+ecx+$10];movdqa xmm2,[eax+ecx+$20]  movdqa xmm7,xmm1  palignr xmm1,xmm0,a;movdqa xmm3,[eax+ecx+$30]  movdqa xmm6,xmm2  palignr xmm2,xmm7,a;movdqa xmm4,[eax+ecx+$40]  movdqa xmm5,xmm3  palignr xmm3,xmm6,a;movdqa [eax+$00    ],xmm1  movdqa xmm0,xmm4  palignr xmm4,xmm5,a;movdqa [eax+$10    ],xmm2  add eax,$40;movdqa [eax+$20-$40],xmm3  prefetchnta [eax+ecx+$100];movdqa [eax+$30-$40],xmm4  cmp eax,edx jne @@1 ret;end;
    procedure AD;const a=$D;asm movdqa xmm0,[eax+ecx+$00];@@1:;movdqa xmm1,[eax+ecx+$10];movdqa xmm2,[eax+ecx+$20]  movdqa xmm7,xmm1  palignr xmm1,xmm0,a;movdqa xmm3,[eax+ecx+$30]  movdqa xmm6,xmm2  palignr xmm2,xmm7,a;movdqa xmm4,[eax+ecx+$40]  movdqa xmm5,xmm3  palignr xmm3,xmm6,a;movdqa [eax+$00    ],xmm1  movdqa xmm0,xmm4  palignr xmm4,xmm5,a;movdqa [eax+$10    ],xmm2  add eax,$40;movdqa [eax+$20-$40],xmm3  prefetchnta [eax+ecx+$100];movdqa [eax+$30-$40],xmm4  cmp eax,edx jne @@1 ret;end;
    procedure AE;const a=$E;asm movdqa xmm0,[eax+ecx+$00];@@1:;movdqa xmm1,[eax+ecx+$10];movdqa xmm2,[eax+ecx+$20]  movdqa xmm7,xmm1  palignr xmm1,xmm0,a;movdqa xmm3,[eax+ecx+$30]  movdqa xmm6,xmm2  palignr xmm2,xmm7,a;movdqa xmm4,[eax+ecx+$40]  movdqa xmm5,xmm3  palignr xmm3,xmm6,a;movdqa [eax+$00    ],xmm1  movdqa xmm0,xmm4  palignr xmm4,xmm5,a;movdqa [eax+$10    ],xmm2  add eax,$40;movdqa [eax+$20-$40],xmm3  prefetchnta [eax+ecx+$100];movdqa [eax+$30-$40],xmm4  cmp eax,edx jne @@1 ret;end;
    procedure AF;const a=$F;asm movdqa xmm0,[eax+ecx+$00];@@1:;movdqa xmm1,[eax+ecx+$10];movdqa xmm2,[eax+ecx+$20]  movdqa xmm7,xmm1  palignr xmm1,xmm0,a;movdqa xmm3,[eax+ecx+$30]  movdqa xmm6,xmm2  palignr xmm2,xmm7,a;movdqa xmm4,[eax+ecx+$40]  movdqa xmm5,xmm3  palignr xmm3,xmm6,a;movdqa [eax+$00    ],xmm1  movdqa xmm0,xmm4  palignr xmm4,xmm5,a;movdqa [eax+$10    ],xmm2  add eax,$40;movdqa [eax+$20-$40],xmm3  prefetchnta [eax+ecx+$100];movdqa [eax+$30-$40],xmm4  cmp eax,edx jne @@1 ret;end;

  asm
    test ecx,$F jz @@2
    push esi
    mov esi,ecx; and esi,$f; lea esi,[esi*4+offset @@jt-4]; //select function
    and ecx,not $f //align delta
    call [esi]
    pop esi
    ret
    @@jt: dd A1,A2,A3,A4,A5,A6,A7,A8,A9,AA,AB,AC,AD,AE,AF
  @@2:
    movaps xmm0,[eax+ecx+$00]
    movaps xmm1,[eax+ecx+$10]
    movaps xmm2,[eax+ecx+$20]
    movaps xmm3,[eax+ecx+$30]
    movaps [eax+$00],xmm0 prefetchnta [eax+ecx+$100]
    movaps [eax+$10],xmm1 add eax,$40
    movaps [eax+$20-$40],xmm2
    movaps [eax+$30-$40],xmm3 cmp eax,edx jne @@2
  end;

  procedure _SSE_Move64_rev_nocache(dst,dstEnd:pointer;dstToSrc:integer);
  asm
    xchg edx,eax sub eax,$40 sub edx,$40 //mirror buffer start/end positions
  @@1:
    movups xmm0,[eax+ecx+$00]
    movups xmm1,[eax+ecx+$10]
    movups xmm2,[eax+ecx+$20]
    movups xmm3,[eax+ecx+$30]
    movntps [eax+$00],xmm0 prefetchnta [eax+ecx-$100]
    movntps [eax+$10],xmm1 sub eax,$40
    movntps [eax+$20+$40],xmm2
    movntps [eax+$30+$40],xmm3 cmp eax,edx jne @@1
  end;

  procedure _SSE_Move64_rev_cache(dst,dstEnd:pointer;dstToSrc:integer);

    procedure A1;const a=1;//reference implementation
    asm
      movdqa xmm0,[eax+ecx+$30]
    @@1:
      movdqa xmm1,[eax+ecx+$20]
      movdqa xmm2,[eax+ecx+$10]  palignr xmm0,xmm1,a
      movdqa xmm3,[eax+ecx+$00]  palignr xmm1,xmm2,a
      movdqa xmm4,[eax+ecx-$10]  palignr xmm2,xmm3,a
      movdqa [eax+$30    ],xmm0  palignr xmm3,xmm4,a  movdqa xmm0,xmm4
      movdqa [eax+$20    ],xmm1  sub eax,$40
      movdqa [eax+$10+$40],xmm2  prefetchnta [eax+ecx-$100]
      movdqa [eax+$00+$40],xmm3  cmp eax,edx jne @@1 ret
    end;

    //copy+paste
    procedure A2;const a=$2;asm movdqa xmm0,[eax+ecx+$30];@@1:;  movdqa xmm1,[eax+ecx+$20];  movdqa xmm2,[eax+ecx+$10]  palignr xmm0,xmm1,a;  movdqa xmm3,[eax+ecx+$00]  palignr xmm1,xmm2,a;  movdqa xmm4,[eax+ecx-$10]  palignr xmm2,xmm3,a;  movdqa [eax+$30    ],xmm0  palignr xmm3,xmm4,a  movdqa xmm0,xmm4;  movdqa [eax+$20    ],xmm1  sub eax,$40;  movdqa [eax+$10+$40],xmm2  prefetchnta [eax+ecx-$100];  movdqa [eax+$00+$40],xmm3  cmp eax,edx jne @@1 ret;  end;
    procedure A3;const a=$3;asm movdqa xmm0,[eax+ecx+$30];@@1:;  movdqa xmm1,[eax+ecx+$20];  movdqa xmm2,[eax+ecx+$10]  palignr xmm0,xmm1,a;  movdqa xmm3,[eax+ecx+$00]  palignr xmm1,xmm2,a;  movdqa xmm4,[eax+ecx-$10]  palignr xmm2,xmm3,a;  movdqa [eax+$30    ],xmm0  palignr xmm3,xmm4,a  movdqa xmm0,xmm4;  movdqa [eax+$20    ],xmm1  sub eax,$40;  movdqa [eax+$10+$40],xmm2  prefetchnta [eax+ecx-$100];  movdqa [eax+$00+$40],xmm3  cmp eax,edx jne @@1 ret;  end;
    procedure A4;const a=$4;asm movdqa xmm0,[eax+ecx+$30];@@1:;  movdqa xmm1,[eax+ecx+$20];  movdqa xmm2,[eax+ecx+$10]  palignr xmm0,xmm1,a;  movdqa xmm3,[eax+ecx+$00]  palignr xmm1,xmm2,a;  movdqa xmm4,[eax+ecx-$10]  palignr xmm2,xmm3,a;  movdqa [eax+$30    ],xmm0  palignr xmm3,xmm4,a  movdqa xmm0,xmm4;  movdqa [eax+$20    ],xmm1  sub eax,$40;  movdqa [eax+$10+$40],xmm2  prefetchnta [eax+ecx-$100];  movdqa [eax+$00+$40],xmm3  cmp eax,edx jne @@1 ret;  end;
    procedure A5;const a=$5;asm movdqa xmm0,[eax+ecx+$30];@@1:;  movdqa xmm1,[eax+ecx+$20];  movdqa xmm2,[eax+ecx+$10]  palignr xmm0,xmm1,a;  movdqa xmm3,[eax+ecx+$00]  palignr xmm1,xmm2,a;  movdqa xmm4,[eax+ecx-$10]  palignr xmm2,xmm3,a;  movdqa [eax+$30    ],xmm0  palignr xmm3,xmm4,a  movdqa xmm0,xmm4;  movdqa [eax+$20    ],xmm1  sub eax,$40;  movdqa [eax+$10+$40],xmm2  prefetchnta [eax+ecx-$100];  movdqa [eax+$00+$40],xmm3  cmp eax,edx jne @@1 ret;  end;
    procedure A6;const a=$6;asm movdqa xmm0,[eax+ecx+$30];@@1:;  movdqa xmm1,[eax+ecx+$20];  movdqa xmm2,[eax+ecx+$10]  palignr xmm0,xmm1,a;  movdqa xmm3,[eax+ecx+$00]  palignr xmm1,xmm2,a;  movdqa xmm4,[eax+ecx-$10]  palignr xmm2,xmm3,a;  movdqa [eax+$30    ],xmm0  palignr xmm3,xmm4,a  movdqa xmm0,xmm4;  movdqa [eax+$20    ],xmm1  sub eax,$40;  movdqa [eax+$10+$40],xmm2  prefetchnta [eax+ecx-$100];  movdqa [eax+$00+$40],xmm3  cmp eax,edx jne @@1 ret;  end;
    procedure A7;const a=$7;asm movdqa xmm0,[eax+ecx+$30];@@1:;  movdqa xmm1,[eax+ecx+$20];  movdqa xmm2,[eax+ecx+$10]  palignr xmm0,xmm1,a;  movdqa xmm3,[eax+ecx+$00]  palignr xmm1,xmm2,a;  movdqa xmm4,[eax+ecx-$10]  palignr xmm2,xmm3,a;  movdqa [eax+$30    ],xmm0  palignr xmm3,xmm4,a  movdqa xmm0,xmm4;  movdqa [eax+$20    ],xmm1  sub eax,$40;  movdqa [eax+$10+$40],xmm2  prefetchnta [eax+ecx-$100];  movdqa [eax+$00+$40],xmm3  cmp eax,edx jne @@1 ret;  end;
    procedure A8;const a=$8;asm movdqa xmm0,[eax+ecx+$30];@@1:;  movdqa xmm1,[eax+ecx+$20];  movdqa xmm2,[eax+ecx+$10]  palignr xmm0,xmm1,a;  movdqa xmm3,[eax+ecx+$00]  palignr xmm1,xmm2,a;  movdqa xmm4,[eax+ecx-$10]  palignr xmm2,xmm3,a;  movdqa [eax+$30    ],xmm0  palignr xmm3,xmm4,a  movdqa xmm0,xmm4;  movdqa [eax+$20    ],xmm1  sub eax,$40;  movdqa [eax+$10+$40],xmm2  prefetchnta [eax+ecx-$100];  movdqa [eax+$00+$40],xmm3  cmp eax,edx jne @@1 ret;  end;
    procedure A9;const a=$9;asm movdqa xmm0,[eax+ecx+$30];@@1:;  movdqa xmm1,[eax+ecx+$20];  movdqa xmm2,[eax+ecx+$10]  palignr xmm0,xmm1,a;  movdqa xmm3,[eax+ecx+$00]  palignr xmm1,xmm2,a;  movdqa xmm4,[eax+ecx-$10]  palignr xmm2,xmm3,a;  movdqa [eax+$30    ],xmm0  palignr xmm3,xmm4,a  movdqa xmm0,xmm4;  movdqa [eax+$20    ],xmm1  sub eax,$40;  movdqa [eax+$10+$40],xmm2  prefetchnta [eax+ecx-$100];  movdqa [eax+$00+$40],xmm3  cmp eax,edx jne @@1 ret;  end;
    procedure AA;const a=$A;asm movdqa xmm0,[eax+ecx+$30];@@1:;  movdqa xmm1,[eax+ecx+$20];  movdqa xmm2,[eax+ecx+$10]  palignr xmm0,xmm1,a;  movdqa xmm3,[eax+ecx+$00]  palignr xmm1,xmm2,a;  movdqa xmm4,[eax+ecx-$10]  palignr xmm2,xmm3,a;  movdqa [eax+$30    ],xmm0  palignr xmm3,xmm4,a  movdqa xmm0,xmm4;  movdqa [eax+$20    ],xmm1  sub eax,$40;  movdqa [eax+$10+$40],xmm2  prefetchnta [eax+ecx-$100];  movdqa [eax+$00+$40],xmm3  cmp eax,edx jne @@1 ret;  end;
    procedure AB;const a=$B;asm movdqa xmm0,[eax+ecx+$30];@@1:;  movdqa xmm1,[eax+ecx+$20];  movdqa xmm2,[eax+ecx+$10]  palignr xmm0,xmm1,a;  movdqa xmm3,[eax+ecx+$00]  palignr xmm1,xmm2,a;  movdqa xmm4,[eax+ecx-$10]  palignr xmm2,xmm3,a;  movdqa [eax+$30    ],xmm0  palignr xmm3,xmm4,a  movdqa xmm0,xmm4;  movdqa [eax+$20    ],xmm1  sub eax,$40;  movdqa [eax+$10+$40],xmm2  prefetchnta [eax+ecx-$100];  movdqa [eax+$00+$40],xmm3  cmp eax,edx jne @@1 ret;  end;
    procedure AC;const a=$C;asm movdqa xmm0,[eax+ecx+$30];@@1:;  movdqa xmm1,[eax+ecx+$20];  movdqa xmm2,[eax+ecx+$10]  palignr xmm0,xmm1,a;  movdqa xmm3,[eax+ecx+$00]  palignr xmm1,xmm2,a;  movdqa xmm4,[eax+ecx-$10]  palignr xmm2,xmm3,a;  movdqa [eax+$30    ],xmm0  palignr xmm3,xmm4,a  movdqa xmm0,xmm4;  movdqa [eax+$20    ],xmm1  sub eax,$40;  movdqa [eax+$10+$40],xmm2  prefetchnta [eax+ecx-$100];  movdqa [eax+$00+$40],xmm3  cmp eax,edx jne @@1 ret;  end;
    procedure AD;const a=$D;asm movdqa xmm0,[eax+ecx+$30];@@1:;  movdqa xmm1,[eax+ecx+$20];  movdqa xmm2,[eax+ecx+$10]  palignr xmm0,xmm1,a;  movdqa xmm3,[eax+ecx+$00]  palignr xmm1,xmm2,a;  movdqa xmm4,[eax+ecx-$10]  palignr xmm2,xmm3,a;  movdqa [eax+$30    ],xmm0  palignr xmm3,xmm4,a  movdqa xmm0,xmm4;  movdqa [eax+$20    ],xmm1  sub eax,$40;  movdqa [eax+$10+$40],xmm2  prefetchnta [eax+ecx-$100];  movdqa [eax+$00+$40],xmm3  cmp eax,edx jne @@1 ret;  end;
    procedure AE;const a=$E;asm movdqa xmm0,[eax+ecx+$30];@@1:;  movdqa xmm1,[eax+ecx+$20];  movdqa xmm2,[eax+ecx+$10]  palignr xmm0,xmm1,a;  movdqa xmm3,[eax+ecx+$00]  palignr xmm1,xmm2,a;  movdqa xmm4,[eax+ecx-$10]  palignr xmm2,xmm3,a;  movdqa [eax+$30    ],xmm0  palignr xmm3,xmm4,a  movdqa xmm0,xmm4;  movdqa [eax+$20    ],xmm1  sub eax,$40;  movdqa [eax+$10+$40],xmm2  prefetchnta [eax+ecx-$100];  movdqa [eax+$00+$40],xmm3  cmp eax,edx jne @@1 ret;  end;
    procedure AF;const a=$F;asm movdqa xmm0,[eax+ecx+$30];@@1:;  movdqa xmm1,[eax+ecx+$20];  movdqa xmm2,[eax+ecx+$10]  palignr xmm0,xmm1,a;  movdqa xmm3,[eax+ecx+$00]  palignr xmm1,xmm2,a;  movdqa xmm4,[eax+ecx-$10]  palignr xmm2,xmm3,a;  movdqa [eax+$30    ],xmm0  palignr xmm3,xmm4,a  movdqa xmm0,xmm4;  movdqa [eax+$20    ],xmm1  sub eax,$40;  movdqa [eax+$10+$40],xmm2  prefetchnta [eax+ecx-$100];  movdqa [eax+$00+$40],xmm3  cmp eax,edx jne @@1 ret;  end;

  asm
    xchg edx,eax sub eax,$40 sub edx,$40 //mirror buffer start/end positions
    test ecx,$F jz @@2 //aligned?
    push esi
    mov esi,ecx; and esi,$f; lea esi,[esi*4+offset @@jt-4]; //select function
    and ecx,not $f; add ecx,$10 //align delta
    call [esi]
    pop esi
    ret
    @@jt: dd A1,A2,A3,A4,A5,A6,A7,A8,A9,AA,AB,AC,AD,AE,AF
  @@2:
    movaps xmm0,[eax+ecx+$00]
    movaps xmm1,[eax+ecx+$10]
    movaps xmm2,[eax+ecx+$20]
    movaps xmm3,[eax+ecx+$30]
    movaps [eax+$00],xmm0 prefetchnta [eax+ecx-$100]
    movaps [eax+$10],xmm1 sub eax,$40
    movaps [eax+$20+$40],xmm2
    movaps [eax+$30+$40],xmm3 cmp eax,edx jne @@2
  end;

const AlignPosMask=16-1;
      AlignSizeMask=64-1;

var delta:integer;
    pDst,pDstInner,pDstEnd,pDstInnerEnd:integer;
    InnerSize:integer;
    reverse,nocache,unaligned:boolean;
begin
  if size<(AlignSizeMask+1)*2 then begin system.Move(src,dst,size);exit end;
  //check params
  if(@src=nil)or(@dst=nil)then exit;
  delta:=integer(@dst)-integer(@src);
  if delta=0 then exit;
  reverse:=(delta>0)and(delta<size);
  delta:=-delta;//Delta: points from dst -> src
  unaligned:=(delta and $f)<>0;

  pDst:=integer(@dst);
  pDstEnd:=pDst+size;
  pDstInner:=(pDst+AlignPosMask+16*ord(    reverse and unaligned))and not AlignPosMask;
  InnerSize:=(pDstEnd-pDstInner-16*ord(not reverse and unaligned))and not AlignSizeMask;
  pDstInnerEnd:=pDstInner+InnerSize;

  nocache:=Size>FastMoveCacheLimit;
  if reverse then begin
    system.Move(pointer(pDstInnerEnd+delta)^,pointer(pDstInnerEnd)^,pDstEnd-pDstInnerEnd);
    if nocache then _SSE_Move64_rev_nocache(pointer(pDstInner),pointer(pDstInnerEnd),delta)
               else _SSE_Move64_rev_cache  (pointer(pDstInner),pointer(pDstInnerEnd),delta);
    system.Move(Src,Dst,pDstInner-pDst);
  end else begin
    system.Move(Src,Dst,pDstInner-pDst);
    if nocache then _SSE_Move64_fwd_nocache(pointer(pDstInner),pointer(pDstInnerEnd),delta)
               else _SSE_Move64_fwd_cache  (pointer(pDstInner),pointer(pDstInnerEnd),delta);
    system.Move(pointer(pDstInnerEnd+delta)^,pointer(pDstInnerEnd)^,pDstEnd-pDstInnerEnd);
  end;
end;

////////////////////////////////////////////////////////////////////////////////
///  FastMove Functional and performance test                                 ///
////////////////////////////////////////////////////////////////////////////////

function _TestFastMove:ansistring;

  procedure log(s:ansistring);begin result:=result+s+#13#10;writeln(s)end;

const TestDataSize=256;
      BufSize=128 shl 20;

type TByteArray=array[0..BufSize-1]of byte;PByteArray=^TByteArray;

var
  _buf:array of byte;
  buf:PByteArray;
//  bufhalf:integer;
  i,j,k{,L}:integer;
  pref,psrc,pdst:pointer;
  siz,alignMask,TestDataSizeBig:integer;
  rate:single;
  bestrate:array[0..7]of single;
  t0,t1,tf:int64;
  s:ansistring;
begin
  result:='';randseed:=0;
  //functional test
  alignMask:=$fff;
  setlength(_buf,BufSize+alignMask);
  buf:=pointer((integer(_buf)+alignMask)and not alignMask);
  //buf:4K aligned 256megs

  //test small blocks with various src/dst offsets and sizes
  TestDataSizeBig:=FastMoveCacheLimit+1;
  for i:=0 to TestDataSizeBig-1 do buf[i]:=i*251;//reference data
  for i:=-64 to 64 do for j:=-64 to 64 do for k:=0 to TestDataSize do begin
    if k=TestDataSize then
      if((i or j) and $1f)<>0 then continue;//only a few shifts for big blocks

    pref:=@buf[0];
    psrc:=@buf[BufSize shr 1+i];
    pdst:=@buf[BufSize shr 1+j];
    if k=TestDataSize then siz:=TestDataSizeBig//big data a vegen
                      else siz:=k;

    System.Move(pref^,psrc^,siz);
    FastMove(psrc^,pdst^,siz);
    if not sysutils.CompareMem(pref,pdst,siz)then begin
//      System.Move(pref^,psrc^,siz);FastMove(psrc^,pdst^,siz);}//reproduce last error for debugging
      raise Exception.CreateFmt('TestFastMove() functional test failed %p %p %x',[psrc,pdst,siz]);
    end;
  end;

  //Benchmark
  SetPriorityClass(GetCurrentProcess,REALTIME_PRIORITY_CLASS);

  log(Format('%10s%8s%8s%7s%8s%8s%7s%8s%8s%7s%8s%8s%7s',
    ['Size','AASys','AAFast','AAGain','UASys','UAFast','UAGain','AUSys','AUFast','AUGain','UUSys','UUFast','UUGain']));
  siz:=1;
  while siz<=bufsize shr 1 do begin

    for k:=0 to 1 do //repeat full test
    for i:=0 to high(bestrate) do begin

      bestrate[i]:=0;
      for j:=0 to 7 do begin

        QueryPerformanceCounter(t0);

        case i and 1 of  //bit0:Fast or not
          0:System.Move(buf[0+i shr 1 and 1],buf[bufsize shr 1-(i shr 2 and 1)*3],siz);
          else FastMove(buf[0+i shr 1 and 1],buf[bufsize shr 1-(i shr 2 and 1)*3],siz);
        end;                //Bit1:srcalign  //Bit2:dstAlign

        QueryPerformanceCounter(t1);
        QueryPerformanceFrequency(tf);
        rate:=siz*(tf/(t1-t0))/(1024*1024);
        if bestrate[i]<rate then bestrate[i]:=rate;
      end;
    end;

    s:=format('%10d',[siz]);
    for i:=0 to high(bestrate)do begin
      s:=s+format('%8.0f',[bestRate[i]]);
      if(i and 1)<>0 then
        s:=s+format('%7.3f',[bestRate[i]/bestRate[i-1]]);
    end;
    log(s);

    if siz<4 then inc(siz)
             else if(siz and(siz shr 1))<>0 then siz:=siz*4 div 3
                                            else siz:=siz*3 div 2;
  end;
end;

end.
