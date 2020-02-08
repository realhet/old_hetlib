unit inv_mdct;
interface uses l3table,het.utils;

procedure inv_mdct_(var in_,out_:array of single;block_type:integer);

implementation

const c1:single=1.8793852415718;
      c2:single=1.532088886238;
      c3:single=0.34729635533386;
      c4:single=1.9696155060244;
      c5:single=1.2855752193731;
      c6:single=0.68404028665134;
      s2:single=0.707106781;
      s3:single=1.732050808;

procedure inv_mdct_(var in_,out_:array of single;block_type:integer);
type da=array[0..35] of single;
var tmp:array[0..17]of single;
    win_bt:^da;
    six_i,i,p,dummy:integer;
    pp1,pp2,sum,save:single;
   tmp0,tmp1,tmp2,tmp3,tmp4,tmp0_,tmp1_,tmp2_,tmp3_,
   e,o,i6_,i0,i0p12,tmp0o,tmp1o,tmp2o,tmp3o,tmp4o,tmp0_o,tmp1_o,tmp2_o,tmp3_o:single;
begin
  if(block_type = 2)then begin
    fillchar(out_,sizeof(out_),0);
    six_i := 0;
    for i:=0 to 3-1 do begin{      	// 12 point IMDCT}
      in_[15+i] :=in_[15+i]+ in_[12+i]; in_[12+i] :=in_[12+i]+ in_[9+i]; in_[9+i]  :=in_[9+i]  +  in_[6+i];
      in_[ 6+i] :=in_[ 6+i]+ in_[ 3+i]; in_[3+i]  :=in_[ 3+i]+ in_[0+i];
      in_[15+i] :=in_[15+i]+ in_[9+i];  in_[9+i]  :=in_[9+i]  + in_[3+i];

      pp2 := in_[12+i] * 0.500000000;
      pp1 := in_[ 6+i] * 0.866025403;
      sum := in_[0+i] + pp2;
      tmp[1] := in_[0+i] - in_[12+i];
      tmp[0] := sum + pp1;
      tmp[2] := sum - pp1;
{      	// End 3 point IDCT on even indices
	   	// 3 point IDCT on odd indices (for 6 point IDCT)}
{   	   // End 3 point IDCT on odd indices
   		// Twiddle factors on odd indices (for 6 point IDCT)}
      pp2 := in_[15+i] * 0.500000000;
      pp1 := in_[ 9+i] * 0.866025403;
      sum := in_[ 3+i] + pp2;
      tmp[4] :=(in_[3+i] - in_[15+i])* 0.707106781;
      tmp[5] :=(sum + pp1)* 0.517638090;
      tmp[3] :=(sum - pp1)* 1.931851653;
{	   	// Output butterflies on 2 3 point IDCT's (for 6 point IDCT)}
      save := tmp[0];
      tmp[0] :=(tmp[0]+ tmp[5])*0.504314480;;
      tmp[5] :=(save - tmp[5])*3.830648788;
      save := tmp[1];
      tmp[1] :=(tmp[1] + tmp[4])*0.541196100;
      tmp[4] :=(save - tmp[4])*1.306562965;
      save := tmp[2];
      tmp[2] :=(tmp[2] + tmp[3])*0.630236207;
      tmp[3] :=(save - tmp[3])*0.821339815;
{   		// End 6 point IDCT
     	// Twiddle factors on indices (for 12 point IDCT)}
{      tmp[0]  := tmp[0]  *  0.504314480;
      tmp[1]  := tmp[1]  *  0.541196100;
      tmp[2]  := tmp[2]  *  0.630236207;
      tmp[3]  := tmp[3]  *  0.821339815;
      tmp[4]  := tmp[4]  *  1.306562965;
      tmp[5]  := tmp[5]  *  3.830648788;}

{      	// End 12 point IDCT

	   	// Shift to 12 point modified IDCT, multiply by window type 2}
	   	tmp[8]  := -tmp[0] * 0.793353340;
	   	tmp[9]  := -tmp[0] * 0.608761429;
	   	tmp[7]  := -tmp[1] * 0.923879532;
	   	tmp[10] := -tmp[1] * 0.382683432;
	   	tmp[6]  := -tmp[2] * 0.991444861;
	   	tmp[11] := -tmp[2] * 0.130526192;

	   	tmp[0]  :=  tmp[3];
	   	tmp[1]  :=  tmp[4] * 0.382683432;
	   	tmp[2]  :=  tmp[5] * 0.608761429;

	   	tmp[3]  := -tmp[5] * 0.793353340;
   		tmp[4]  := -tmp[4] * 0.923879532;
	   	tmp[5]  := -tmp[0] * 0.991444861;

	   	tmp[0] :=tmp[0] * 0.130526192;

   		out_[six_i + 6]  :=out_[six_i + 6]  + tmp[0];
			out_[six_i + 7]  :=out_[six_i + 7]  + tmp[1];
	   	out_[six_i + 8]  := out_[six_i + 8]  +tmp[2];
			out_[six_i + 9]  := out_[six_i + 9]  +tmp[3];
   		out_[six_i + 10] := out_[six_i + 10] +tmp[4];
			out_[six_i + 11] := out_[six_i + 11] +tmp[5];
	   	out_[six_i + 12] := out_[six_i + 12] +tmp[6];
			out_[six_i + 13] := out_[six_i + 13] +tmp[7];
	   	out_[six_i + 14] := out_[six_i + 14] +tmp[8];
			out_[six_i + 15] := out_[six_i + 15] +tmp[9];
	   	out_[six_i + 16] := out_[six_i + 16] +tmp[10];
			out_[six_i + 17] := out_[six_i + 17] +tmp[11];

   		six_i :=six_i + 6;
   	end;

  end else begin


{   // 36 point IDCT

   // input aliasing for 36 point IDCT}
   in_[17]:=in_[17]+in_[16]; in_[16]:=in_[16]+in_[15]; in_[15]:=in_[15]+in_[14]; in_[14]:=in_[14]+in_[13];
   in_[13]:=in_[13]+in_[12]; in_[12]:=in_[12]+in_[11]; in_[11]:=in_[11]+in_[10]; in_[10]:=in_[10]+in_[9];
   in_[9] :=in_[9] +in_[8];  in_[8] :=in_[8] +in_[7];  in_[7] :=in_[7] +in_[6];  in_[6] :=in_[6] +in_[5];
   in_[5] :=in_[5] +in_[4];  in_[4] :=in_[4] +in_[3];  in_[3] :=in_[3] +in_[2];  in_[2] :=in_[2] +in_[1];
   in_[1] :=in_[1] +in_[0];

{   // 18 point IDCT for odd indices
   // input aliasing for 18 point IDCT}
   in_[17]:=in_[17]+in_[15]; in_[15]:=in_[15]+in_[13]; in_[13]:=in_[13]+in_[11]; in_[11]:=in_[11]+in_[9];
   in_[9] :=in_[9] +in_[7];  in_[7] :=in_[7] +in_[5];  in_[5] :=in_[5] +in_[3];  in_[3] :=in_[3] +in_[1];



{// Fast 9 Point Inverse Discrete Cosine Transform
//
// By  Francois-Raymond Boyer
//         mailto:boyerf@iro.umontreal.ca
//         http://www.iro.umontreal.ca/~boyerf
//
// The code has been optimized for Intel processors
//  (takes a lot of time to convert float to and from iternal FPU representation)
//
// It is a simple "factorization" of the IDCT matrix.

   // 9 point IDCT on even indices}
{// 5 points on odd indices (not realy an IDCT)}
   i0 := in_[0]+in_[0];
   i0p12 := i0 + in_[12];

   tmp0 := i0p12 + in_[4]*c1 + in_[8]*c2 + in_[16]*c3;
   tmp1 := i0    + in_[4]    - in_[8]    - in_[12] - in_[12] - in_[16];
   tmp2 := i0p12 - in_[4]*c3 - in_[8]*c1 + in_[16]*c2;
   tmp3 := i0p12 - in_[4]*c2 + in_[8]*c3 - in_[16]*c1;
   tmp4 := in_[0]- in_[4]    + in_[8]    - in_[12] + in_[16];

{// 4 points on even indices}
   i6_ := in_[6] * s3;		{/ Sqrt[3]}

   tmp0_ := in_[2]*c4 + i6_ + in_[10]*c5 + in_[14]*c6;
   tmp1_ :=(in_[2] - in_[10] - in_[14])*s3;
   tmp2_ := in_[2]*c5 - i6_ - in_[10]*c6 + in_[14]*c4;
   tmp3_ := in_[2]*c6 - i6_ + in_[10]*c4 - in_[14]*c5;

{   // 9 point IDCT on odd indices}
{// 5 points on odd indices (not realy an IDCT)}
   i0 := in_[0+1]+in_[0+1];
   i0p12 := i0 + in_[12+1];

   tmp0o := i0p12 + in_[4+1]*c1 + in_[8+1]*c2 + in_[16+1]*c3;
   tmp1o := i0    + in_[4+1]    - in_[8+1]    - in_[12+1] - in_[12+1] - in_[16+1];
   tmp2o := i0p12 - in_[4+1]*c3 - in_[8+1]*c1 + in_[16+1]*c2;
   tmp3o := i0p12 - in_[4+1]*c2 + in_[8+1]*c3 - in_[16+1]*c1;
   tmp4o := (in_[0+1] - in_[4+1] + in_[8+1] - in_[12+1] + in_[16+1])*s2; {// Twiddled}

{// 4 points on even indices}
   i6_ := in_[6+1]*s3;{		// Sqrt[3]}

   tmp0_o := in_[2+1]*c4  + i6_ + in_[10+1]*c5  + in_[14+1]*c6;
   tmp1_o := (in_[2+1]                        - in_[10+1]                   - in_[14+1])*s3;
   tmp2_o := in_[2+1]*c5  - i6_ - in_[10+1]*c6 + in_[14+1]*c4;
   tmp3_o := in_[2+1]*c6 - i6_ + in_[10+1]*c4  - in_[14+1]*c5;

{   // Twiddle factors on odd indices
   // and
   // Butterflies on 9 point IDCT's
   // and
   // twiddle factors for 36 point IDCT}

   e := tmp0 + tmp0_; o := (tmp0o + tmp0_o)*0.501909918; tmp[0] := e + o;    tmp[17] := e - o;
   e := tmp1 + tmp1_; o := (tmp1o + tmp1_o)*0.517638090; tmp[1] := e + o;    tmp[16] := e - o;
   e := tmp2 + tmp2_; o := (tmp2o + tmp2_o)*0.551688959; tmp[2] := e + o;    tmp[15] := e - o;
   e := tmp3 + tmp3_; o := (tmp3o + tmp3_o)*0.610387294; tmp[3] := e + o;    tmp[14] := e - o;
   tmp[4] := tmp4 + tmp4o; tmp[13] := tmp4 - tmp4o;
   e := tmp3 - tmp3_; o := (tmp3o - tmp3_o)*0.871723397; tmp[5] := e + o;    tmp[12] := e - o;
   e := tmp2 - tmp2_; o := (tmp2o - tmp2_o)*1.183100792; tmp[6] := e + o;    tmp[11] := e - o;
   e := tmp1 - tmp1_; o := (tmp1o - tmp1_o)*1.931851653; tmp[7] := e + o;    tmp[10] := e - o;
   e := tmp0 - tmp0_; o := (tmp0o - tmp0_o)*5.736856623; tmp[8] := e + o;    tmp[9] :=  e - o;

{   // end 36 point IDCT */

	// shift to modified IDCT}
   win_bt := addr(win[block_type]);

	out_[0] := tmp[9]  * win_bt^[0];
        out_[1] := tmp[10] * win_bt^[1];
	out_[2] := tmp[11] * win_bt^[2];
        out_[3] := tmp[12] * win_bt^[3];
        out_[4] := tmp[13] * win_bt^[4];
	out_[5] := tmp[14] * win_bt^[5];
	out_[6] := tmp[15] * win_bt^[6];
	out_[7] := tmp[16] * win_bt^[7];
	out_[8] := tmp[17] * win_bt^[8];

        out_[9] := tmp[17] * win_bt^[9];
        out_[10]:= tmp[16] * win_bt^[10];
	out_[11]:= tmp[15] * win_bt^[11];
	out_[12]:= tmp[14] * win_bt^[12];
	out_[13]:= tmp[13] * win_bt^[13];
	out_[14]:= tmp[12] * win_bt^[14];
        out_[15]:= tmp[11] * win_bt^[15];
	out_[16]:= tmp[10] * win_bt^[16];
	out_[17]:= tmp[9]  * win_bt^[17];

	out_[18]:= tmp[8]  * win_bt^[18];
        out_[19]:= tmp[7]  * win_bt^[19];
	out_[20]:= tmp[6]  * win_bt^[20];
        out_[21]:= tmp[5]  * win_bt^[21];
	out_[22]:= tmp[4]  * win_bt^[22];
	out_[23]:= tmp[3]  * win_bt^[23];
 	out_[24]:= tmp[2]  * win_bt^[24];
        out_[25]:= tmp[1]  * win_bt^[25];
	out_[26]:= tmp[0]  * win_bt^[26];

        out_[27]:= tmp[0]  * win_bt^[27];
	out_[28]:= tmp[1]  * win_bt^[28];
	out_[29]:= tmp[2]  * win_bt^[29];
	out_[30]:= tmp[3]  * win_bt^[30];
	out_[31]:= tmp[4]  * win_bt^[31];
        out_[32]:= tmp[5]  * win_bt^[32];
	out_[33]:= tmp[6]  * win_bt^[33];
	out_[34]:= tmp[7]  * win_bt^[34];
        out_[35]:= tmp[8]  * win_bt^[35];
	end;
end;
end.
