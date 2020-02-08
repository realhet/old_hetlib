unit synfilt;interface uses sysutils,het.utils,l3table;

{ synfilt.cpp
	Synthesis Filter implementation}

{-- 03/20/97--
*  compute_new_v()-- reoptimized with the assumption thatconstant offsets
*    to memory are free.  Common subexpression were redonefor better
*    optimization.
*  compute_pcm_samples()-- reoptimized withconstant offsets.
*
*-- Conrad Wei-Li Song(conradsong@mail.utexas.edu)
}{
*  @(#) synthesis_filter.cc 1.14, last edit: 6/21/94 11:22:20
*  @(#) Copyright(C) 1993, 1994 Tobias Bading(bading@cs.tu-berlin.de)
*  @(#) Berlin University of Technology
*
*  This program is free software; you can redistribute it and/or modify
*  it under the terms of the GNU General Public License as published by
*  the Free Software Foundation; either version 2 of the License, or
*(at your option) any later version.
*
*  This program is distributed in the hope that it will be useful,
*  but WITHOUT ANY WARRANTY; without even the implied warranty of
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*  GNU General Public Licensefor more details.
*
*  You should have received a copy of the GNU General Public License
*  along with this program;if not, write to the Free Software
*  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
}{
*  Changes from version 1.1 to 1.2:
*- compute_new_v() uses a 32 point fast cosine transform as described by
*      Byeong Gi Lee in IEEE Transactions ASSP-32 Part 2, August 1984,
*"A New Algorithm to Compute the Discrete Cosine Transform"
*      instead of the matrix-vector multiplication in V1.1
*- loop unrollingdone in compute_pcm_samples()
*-if ULAW is defined, the synthesis filterdoes adownsampling
*      to 8 kHz by dropping samples and ignoring subbands above 4 kHz
}
type sia=array[0..8191]of single;
type PSynthesisFilter=^TSynthesisFilter;TSynthesisFilter=object
      private
       v1,v2:array[0..512-1]of single;
       actual_v:^SiA;			{// v1 or v2}
       actual_write_pos:integer;		{// 0-15}
       procedure compute_new_v(var samples);
       procedure compute_pcm_samples(var outs);
      public
       procedure calculate_pcm_samples(var samples;var Obuffer);
       procedure reset;
     end;

implementation

procedure tSynthesisFilter.reset;
Begin
  fillchar(v1,sizeof(v1),0);
  fillchar(v2,sizeof(v2),0);

  actual_v:= addr(v1);
  actual_write_pos:= 15;
End;


procedure tSynthesisFilter.compute_new_v;
var new_v:array[0..32-1]of single ;{ new V[0-15] and V[33-48] of Figure 3-A.2 in ISO DIS 11172-3}
    p,pp:array[0..16-1]of single ;
    tmp1,tmp2:single;
    x1,x2:^sia;
    i,j:integer;

Begin
{ compute new values via a fast cosine transform:}
  x1:=addr(samples);
  j:=31;for i:=0 to 15 do begin p[i]:=x1^[i]+x1^[j];dec(j);end;

  j:=15;for i:=0 to 7 do begin
    pp[i]:=p[i]+p[j];
    pp[i+8]:=(p[i]-p[j])* cos_32[i];
    dec(j);
  end;

  j:=7;for i:=0 to 3 do begin
    p[i]:=pp[i]+pp[j];
    p[i+4]:=(pp[i]- pp[j])* cos_16[i];
    p[i+8]:=pp[8+i]+pp[8+j];
    p[i+12]:=(pp[8+i]- pp[8+j])* cos_16[i];
    dec(j);
  end;

  j:=0;for i:=0 to 3 do begin
    pp[j+0]:= p[j+0]+ p[j+3];
    pp[j+1]:= p[j+1]+ p[j+2];
    pp[j+2]:=(p[j+0]- p[j+3])* cos_8[0];
    pp[j+3]:=(p[j+1]- p[j+2])* cos_8[1];
    j:=j+4;
  end;

  j:=0;for i:=0 to 7 do begin
    p[j+0]:= pp[j+0]+ pp[j+1];
    p[j+1]:=(pp[j+0]- pp[j+1])* cos_4;
    j:=j+2;
  end;
Begin
{ this is pretty insane coding}
        new_v[12]:= p[7];
        new_v[4]:=(new_v[12])+ p[5];
	new_v[36-17]:=-(new_v[4])- p[6];
	new_v[44-17]:=-p[6]- p[7]- p[4];
        new_v[14]:= p[15];
        new_v[10]:=(new_v[14])+ p[11];
	new_v[6]:=(new_v[10])+ p[13];
        new_v[2]:= p[15]+ p[13]+ p[9];
	new_v[34-17]:=-(new_v[2])- p[14];
        tmp1:=-p[14]- p[15]- p[10]- p[11];
	new_v[38-17]:=(tmp1)- p[13];
	new_v[46-17]:=-p[14]- p[15]- p[12]- p[8];
	new_v[42-17]:= tmp1- p[12];
	new_v[48-17]:=-p[0];
	new_v[0]:= p[1];
        new_v[8]:= p[3];
	new_v[40-17]:=-(new_v[8])- p[2];
End;
  j:=31;for i:=0 to 15 do begin p[i]:=(x1^[i]-x1^[j])*cos_64[i];dec(j);end;

  j:=15;for i:=0 to 7 do begin
    pp[i]:=p[i]+p[j];
    pp[i+8]:=(p[i]-p[j])* cos_32[i];
    dec(j);
  end;

  j:=7;for i:=0 to 3 do begin
    p[i]:=pp[i]+pp[j];
    p[i+4]:=(pp[i]- pp[j])* cos_16[i];
    p[i+8]:=pp[8+i]+pp[8+j];
    p[i+12]:=(pp[8+i]- pp[8+j])* cos_16[i];
    dec(j);
  end;

  j:=0;for i:=0 to 3 do begin
    pp[j+0]:= p[j+0]+ p[j+3];
    pp[j+1]:= p[j+1]+ p[j+2];
    pp[j+2]:=(p[j+0]- p[j+3])* cos_8[0];
    pp[j+3]:=(p[j+1]- p[j+2])* cos_8[1];
    j:=j+4;
  end;

  j:=0;for i:=0 to 7 do begin
    p[j+0]:= pp[j+0]+ pp[j+1];
    p[j+1]:=(pp[j+0]- pp[j+1])* cos_4;
    j:=j+2;
  end;

Begin
{ manuallydoing something that a compiler should handle sucks}
{ coding like this is hard to read}
        new_v[15]:= p[15];
        new_v[13]:=(new_v[15])+ p[7];
        new_v[11]:=(new_v[13])+ p[11];
	new_v[5]:=(new_v[11])+ p[5]+ p[13];
        new_v[9]:= p[15]+ p[11]+ p[3];
	new_v[7]:=(new_v[9])+ p[13];
        tmp1:= p[13]+ p[15]+ p[9];
        new_v[1]:=(tmp1)+ p[1];
	new_v[33-17]:=-(new_v[1])- p[14];
        new_v[3]:= tmp1+ p[5]+ p[7];
	new_v[35-17]:=-(new_v[3])- p[6]- p[14];

        tmp1:=-p[10]- p[11]- p[14]- p[15];
	new_v[39-17]:=(tmp1)- p[13]- p[2]- p[3];
	new_v[37-17]:= tmp1- p[13]- p[5]- p[6]- p[7];
	new_v[41-17]:= tmp1- p[12]- p[2]- p[3];
        tmp2:= p[4]+ p[6]+ p[7];
	new_v[43-17]:= tmp1- p[12]-(tmp2);
        tmp1:=-p[8]- p[12]- p[14]- p[15];
	new_v[47-17]:=(tmp1)- p[0];
	new_v[45-17]:= tmp1- tmp2;
End;

  x1:= addr(actual_v^[actual_write_pos]);
  if actual_v=addr(v1) then x2:=addr(v2[actual_write_pos])else x2:=addr(v1[actual_write_pos]);

  for i:=0 to 15 do x1^[i shl 4]:=new_v[i];
  x1^[16 shl 4]:= 0.0;
  for i:=1 to 15 do x1^[256+i shl 4]:=-new_v[16-i];
  x2^[0]:=-new_v[0];
  for i:=1 to 16 do x2^[i shl 4]:=new_v[i+15];
  for i:=1 to 15 do x2^[256+i shl 4]:=new_v[31-i];
End;

procedure tSynthesisFilter.compute_pcm_samples;
var vp,dp,outsmp:^sia;i:integer;
begin
  outsmp:=addr(outs);vp:=addr(actual_v^);dp:=addr(d);
  case actual_write_pos of
    0:for i:=0 to 31 do begin outsmp^[i*2]:=
      vp^[ 0]*dp^[ 0]+
      vp^[15]*dp^[ 1]+
      vp^[14]*dp^[ 2]+
      vp^[13]*dp^[ 3]+
      vp^[12]*dp^[ 4]+
      vp^[11]*dp^[ 5]+
      vp^[10]*dp^[ 6]+
      vp^[ 9]*dp^[ 7]+
      vp^[ 8]*dp^[ 8]+
      vp^[ 7]*dp^[ 9]+
      vp^[ 6]*dp^[10]+
      vp^[ 5]*dp^[11]+
      vp^[ 4]*dp^[12]+
      vp^[ 3]*dp^[13]+
      vp^[ 2]*dp^[14]+
      vp^[ 1]*dp^[15];
      vp:=addr(vp^[16]);dp:=addr(dp^[16]);
    end;
    1:for i:=0 to 31 do begin outsmp^[i*2]:=
      vp^[ 1]*dp^[ 0]+
      vp^[ 0]*dp^[ 1]+
      vp^[15]*dp^[ 2]+
      vp^[14]*dp^[ 3]+
      vp^[13]*dp^[ 4]+
      vp^[12]*dp^[ 5]+
      vp^[11]*dp^[ 6]+
      vp^[10]*dp^[ 7]+
      vp^[ 9]*dp^[ 8]+
      vp^[ 8]*dp^[ 9]+
      vp^[ 7]*dp^[10]+
      vp^[ 6]*dp^[11]+
      vp^[ 5]*dp^[12]+
      vp^[ 4]*dp^[13]+
      vp^[ 3]*dp^[14]+
      vp^[ 2]*dp^[15];
      vp:=addr(vp^[16]);dp:=addr(dp^[16]);
    end;
    2:for i:=0 to 31 do begin outsmp^[i*2]:=
      vp^[ 2]*dp^[ 0]+
      vp^[ 1]*dp^[ 1]+
      vp^[ 0]*dp^[ 2]+
      vp^[15]*dp^[ 3]+
      vp^[14]*dp^[ 4]+
      vp^[13]*dp^[ 5]+
      vp^[12]*dp^[ 6]+
      vp^[11]*dp^[ 7]+
      vp^[10]*dp^[ 8]+
      vp^[ 9]*dp^[ 9]+
      vp^[ 8]*dp^[10]+
      vp^[ 7]*dp^[11]+
      vp^[ 6]*dp^[12]+
      vp^[ 5]*dp^[13]+
      vp^[ 4]*dp^[14]+
      vp^[ 3]*dp^[15];
      vp:=addr(vp^[16]);dp:=addr(dp^[16]);
    end;
    3:for i:=0 to 31 do begin outsmp^[i*2]:=
      vp^[ 3]*dp^[ 0]+
      vp^[ 2]*dp^[ 1]+
      vp^[ 1]*dp^[ 2]+
      vp^[ 0]*dp^[ 3]+
      vp^[15]*dp^[ 4]+
      vp^[14]*dp^[ 5]+
      vp^[13]*dp^[ 6]+
      vp^[12]*dp^[ 7]+
      vp^[11]*dp^[ 8]+
      vp^[10]*dp^[ 9]+
      vp^[ 9]*dp^[10]+
      vp^[ 8]*dp^[11]+
      vp^[ 7]*dp^[12]+
      vp^[ 6]*dp^[13]+
      vp^[ 5]*dp^[14]+
      vp^[ 4]*dp^[15];
      vp:=addr(vp^[16]);dp:=addr(dp^[16]);
    end;
    4:for i:=0 to 31 do begin outsmp^[i*2]:=
      vp^[ 4]*dp^[ 0]+
      vp^[ 3]*dp^[ 1]+
      vp^[ 2]*dp^[ 2]+
      vp^[ 1]*dp^[ 3]+
      vp^[ 0]*dp^[ 4]+
      vp^[15]*dp^[ 5]+
      vp^[14]*dp^[ 6]+
      vp^[13]*dp^[ 7]+
      vp^[12]*dp^[ 8]+
      vp^[11]*dp^[ 9]+
      vp^[10]*dp^[10]+
      vp^[ 9]*dp^[11]+
      vp^[ 8]*dp^[12]+
      vp^[ 7]*dp^[13]+
      vp^[ 6]*dp^[14]+
      vp^[ 5]*dp^[15];
      vp:=addr(vp^[16]);dp:=addr(dp^[16]);
    end;
    5:for i:=0 to 31 do begin outsmp^[i*2]:=
      vp^[ 5]*dp^[ 0]+
      vp^[ 4]*dp^[ 1]+
      vp^[ 3]*dp^[ 2]+
      vp^[ 2]*dp^[ 3]+
      vp^[ 1]*dp^[ 4]+
      vp^[ 0]*dp^[ 5]+
      vp^[15]*dp^[ 6]+
      vp^[14]*dp^[ 7]+
      vp^[13]*dp^[ 8]+
      vp^[12]*dp^[ 9]+
      vp^[11]*dp^[10]+
      vp^[10]*dp^[11]+
      vp^[ 9]*dp^[12]+
      vp^[ 8]*dp^[13]+
      vp^[ 7]*dp^[14]+
      vp^[ 6]*dp^[15];
      vp:=addr(vp^[16]);dp:=addr(dp^[16]);
    end;
    6:for i:=0 to 31 do begin outsmp^[i*2]:=
      vp^[ 6]*dp^[ 0]+
      vp^[ 5]*dp^[ 1]+
      vp^[ 4]*dp^[ 2]+
      vp^[ 3]*dp^[ 3]+
      vp^[ 2]*dp^[ 4]+
      vp^[ 1]*dp^[ 5]+
      vp^[ 0]*dp^[ 6]+
      vp^[15]*dp^[ 7]+
      vp^[14]*dp^[ 8]+
      vp^[13]*dp^[ 9]+
      vp^[12]*dp^[10]+
      vp^[11]*dp^[11]+
      vp^[10]*dp^[12]+
      vp^[ 9]*dp^[13]+
      vp^[ 8]*dp^[14]+
      vp^[ 7]*dp^[15];
      vp:=addr(vp^[16]);dp:=addr(dp^[16]);
    end;
    7:for i:=0 to 31 do begin outsmp^[i*2]:=
      vp^[ 7]*dp^[ 0]+
      vp^[ 6]*dp^[ 1]+
      vp^[ 5]*dp^[ 2]+
      vp^[ 4]*dp^[ 3]+
      vp^[ 3]*dp^[ 4]+
      vp^[ 2]*dp^[ 5]+
      vp^[ 1]*dp^[ 6]+
      vp^[ 0]*dp^[ 7]+
      vp^[15]*dp^[ 8]+
      vp^[14]*dp^[ 9]+
      vp^[13]*dp^[10]+
      vp^[12]*dp^[11]+
      vp^[11]*dp^[12]+
      vp^[10]*dp^[13]+
      vp^[ 9]*dp^[14]+
      vp^[ 8]*dp^[15];
      vp:=addr(vp^[16]);dp:=addr(dp^[16]);
    end;
    8:for i:=0 to 31 do begin outsmp^[i*2]:=
      vp^[ 8]*dp^[ 0]+
      vp^[ 7]*dp^[ 1]+
      vp^[ 6]*dp^[ 2]+
      vp^[ 5]*dp^[ 3]+
      vp^[ 4]*dp^[ 4]+
      vp^[ 3]*dp^[ 5]+
      vp^[ 2]*dp^[ 6]+
      vp^[ 1]*dp^[ 7]+
      vp^[ 0]*dp^[ 8]+
      vp^[15]*dp^[ 9]+
      vp^[14]*dp^[10]+
      vp^[13]*dp^[11]+
      vp^[12]*dp^[12]+
      vp^[11]*dp^[13]+
      vp^[10]*dp^[14]+
      vp^[ 9]*dp^[15];
      vp:=addr(vp^[16]);dp:=addr(dp^[16]);
    end;
    9:for i:=0 to 31 do begin outsmp^[i*2]:=
      vp^[ 9]*dp^[ 0]+
      vp^[ 8]*dp^[ 1]+
      vp^[ 7]*dp^[ 2]+
      vp^[ 6]*dp^[ 3]+
      vp^[ 5]*dp^[ 4]+
      vp^[ 4]*dp^[ 5]+
      vp^[ 3]*dp^[ 6]+
      vp^[ 2]*dp^[ 7]+
      vp^[ 1]*dp^[ 8]+
      vp^[ 0]*dp^[ 9]+
      vp^[15]*dp^[10]+
      vp^[14]*dp^[11]+
      vp^[13]*dp^[12]+
      vp^[12]*dp^[13]+
      vp^[11]*dp^[14]+
      vp^[10]*dp^[15];
      vp:=addr(vp^[16]);dp:=addr(dp^[16]);
    end;
   10:for i:=0 to 31 do begin outsmp^[i*2]:=
      vp^[10]*dp^[ 0]+
      vp^[ 9]*dp^[ 1]+
      vp^[ 8]*dp^[ 2]+
      vp^[ 7]*dp^[ 3]+
      vp^[ 6]*dp^[ 4]+
      vp^[ 5]*dp^[ 5]+
      vp^[ 4]*dp^[ 6]+
      vp^[ 3]*dp^[ 7]+
      vp^[ 2]*dp^[ 8]+
      vp^[ 1]*dp^[ 9]+
      vp^[ 0]*dp^[10]+
      vp^[15]*dp^[11]+
      vp^[14]*dp^[12]+
      vp^[13]*dp^[13]+
      vp^[12]*dp^[14]+
      vp^[11]*dp^[15];
      vp:=addr(vp^[16]);dp:=addr(dp^[16]);
    end;
   11:for i:=0 to 31 do begin outsmp^[i*2]:=
      vp^[11]*dp^[ 0]+
      vp^[10]*dp^[ 1]+
      vp^[ 9]*dp^[ 2]+
      vp^[ 8]*dp^[ 3]+
      vp^[ 7]*dp^[ 4]+
      vp^[ 6]*dp^[ 5]+
      vp^[ 5]*dp^[ 6]+
      vp^[ 4]*dp^[ 7]+
      vp^[ 3]*dp^[ 8]+
      vp^[ 2]*dp^[ 9]+
      vp^[ 1]*dp^[10]+
      vp^[ 0]*dp^[11]+
      vp^[15]*dp^[12]+
      vp^[14]*dp^[13]+
      vp^[13]*dp^[14]+
      vp^[12]*dp^[15];
      vp:=addr(vp^[16]);dp:=addr(dp^[16]);
    end;
   12:for i:=0 to 31 do begin outsmp^[i*2]:=
      vp^[12]*dp^[ 0]+
      vp^[11]*dp^[ 1]+
      vp^[10]*dp^[ 2]+
      vp^[ 9]*dp^[ 3]+
      vp^[ 8]*dp^[ 4]+
      vp^[ 7]*dp^[ 5]+
      vp^[ 6]*dp^[ 6]+
      vp^[ 5]*dp^[ 7]+
      vp^[ 4]*dp^[ 8]+
      vp^[ 3]*dp^[ 9]+
      vp^[ 2]*dp^[10]+
      vp^[ 1]*dp^[11]+
      vp^[ 0]*dp^[12]+
      vp^[15]*dp^[13]+
      vp^[14]*dp^[14]+
      vp^[13]*dp^[15];
      vp:=addr(vp^[16]);dp:=addr(dp^[16]);
    end;
   13:for i:=0 to 31 do begin outsmp^[i*2]:=
      vp^[13]*dp^[ 0]+
      vp^[12]*dp^[ 1]+
      vp^[11]*dp^[ 2]+
      vp^[10]*dp^[ 3]+
      vp^[ 9]*dp^[ 4]+
      vp^[ 8]*dp^[ 5]+
      vp^[ 7]*dp^[ 6]+
      vp^[ 6]*dp^[ 7]+
      vp^[ 5]*dp^[ 8]+
      vp^[ 4]*dp^[ 9]+
      vp^[ 3]*dp^[10]+
      vp^[ 2]*dp^[11]+
      vp^[ 1]*dp^[12]+
      vp^[ 0]*dp^[13]+
      vp^[15]*dp^[14]+
      vp^[14]*dp^[15];
      vp:=addr(vp^[16]);dp:=addr(dp^[16]);
    end;
   14:for i:=0 to 31 do begin outsmp^[i*2]:=
      vp^[14]*dp^[ 0]+
      vp^[13]*dp^[ 1]+
      vp^[12]*dp^[ 2]+
      vp^[11]*dp^[ 3]+
      vp^[10]*dp^[ 4]+
      vp^[ 9]*dp^[ 5]+
      vp^[ 8]*dp^[ 6]+
      vp^[ 7]*dp^[ 7]+
      vp^[ 6]*dp^[ 8]+
      vp^[ 5]*dp^[ 9]+
      vp^[ 4]*dp^[10]+
      vp^[ 3]*dp^[11]+
      vp^[ 2]*dp^[12]+
      vp^[ 1]*dp^[13]+
      vp^[ 0]*dp^[14]+
      vp^[15]*dp^[15];
      vp:=addr(vp^[16]);dp:=addr(dp^[16]);
    end;
   15:for i:=0 to 31 do begin outsmp^[i*2]:=
      vp^[15]*dp^[ 0]+
      vp^[14]*dp^[ 1]+
      vp^[13]*dp^[ 2]+
      vp^[12]*dp^[ 3]+
      vp^[11]*dp^[ 4]+
      vp^[10]*dp^[ 5]+
      vp^[ 9]*dp^[ 6]+
      vp^[ 8]*dp^[ 7]+
      vp^[ 7]*dp^[ 8]+
      vp^[ 6]*dp^[ 9]+
      vp^[ 5]*dp^[10]+
      vp^[ 4]*dp^[11]+
      vp^[ 3]*dp^[12]+
      vp^[ 2]*dp^[13]+
      vp^[ 1]*dp^[14]+
      vp^[ 0]*dp^[15];
      vp:=addr(vp^[16]);dp:=addr(dp^[16]);
    end;
  end;
end;


procedure tSynthesisFilter.calculate_pcm_samples;
var s:ansistring;
    i:integer;
Begin
  compute_new_v(samples);
  compute_pcm_samples(obuffer);

  actual_write_pos:=(actual_write_pos+ 1) and $f;
  if actual_v=addr(v1)then actual_v:=addr(v2)else actual_v:=addr(v1);
End;

End.
