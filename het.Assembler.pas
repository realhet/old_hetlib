unit het.Assembler;        //hetvariants
interface

uses sysutils, het.Utils, het.Parser, het.Arrays;

function AsmCompile(const src:ansistring;const AlignCode16:boolean=false):rawbytestring;
function AsmDump(const src:rawbytestring):ansistring;
procedure AsmExecute(const src:ansistring;const _eax:integer=0;const _ecx:integer=0;const _edx:integer=0);

implementation

const Instructions:array[0..222]of record instr,code:ansistring;end=(
(instr:'addps xmm,xmm';code:'0F58Rm'),
(instr:'addss xmm,xmm';code:'F30F58Rm'),
(instr:'subps xmm,xmm';code:'0F5CRm'),
(instr:'subss xmm,xmm';code:'F30F5CRm'),
(instr:'mulps xmm,xmm';code:'0F59Rm'),
(instr:'mulss xmm,xmm';code:'F30F59Rm'),
(instr:'divps xmm,xmm';code:'0F5ERm'),
(instr:'divss xmm,xmm';code:'F30F5ERm'),
(instr:'rcpps xmm,xmm';code:'0F53Rm'),
(instr:'rcpss xmm,xmm';code:'F30F53Rm'),
(instr:'sqrtps xmm,xmm';code:'0F51Rm'),
(instr:'sqrtss xmm,xmm';code:'F30F51Rm'),
(instr:'rsqrtps xmm,xmm';code:'0F52Rm'),
(instr:'rsqrtss xmm,xmm';code:'F30F52Rm'),
(instr:'maxps xmm,xmm';code:'0F5FRm'),
(instr:'maxss xmm,xmm';code:'F30F5FRm'),
(instr:'minps xmm,xmm';code:'0F5DRm'),
(instr:'minss xmm,xmm';code:'F30F5DRm'),
(instr:'pavgb xmm,xmm';code:'660FE0Rm'),
(instr:'pavgw xmm,xmm';code:'660FE3Rm'),
(instr:'psadbw xmm,xmm';code:'660FF6Rm'),
(instr:'pextrw r32,xmm,i';code:'660FC5RmI8'),
(instr:'pinsrw xmm,r32,i';code:'660FC4RmI8'),
(instr:'pmaxsw xmm,xmm';code:'660FEERm'),
(instr:'pmaxub xmm,xmm';code:'660FDERm'),
(instr:'pminsw xmm,xmm';code:'660FEARm'),
(instr:'pminub xmm,xmm';code:'660FDARm'),
(instr:'pmovmskb r32,xmm';code:'660FD7Rm'),
(instr:'pmulhuw xmm,xmm';code:'660FE4Rm'),
(instr:'pshufw mm,mm,i';code:'0F70Rm00'),
(instr:'andnps xmm,xmm';code:'0F55Rm'),
(instr:'andps xmm,xmm';code:'0F54Rm'),
(instr:'orps xmm,xmm';code:'0F56Rm'),
(instr:'xorps xmm,xmm';code:'0F57Rm'),
(instr:'cmpeqps xmm,xmm';code:'0FC2Rm00'),
(instr:'cmpneqps xmm,xmm';code:'0FC2Rm04'),
(instr:'cmpltps xmm,xmm';code:'0FC2Rm01'),
(instr:'cmpleps xmm,xmm';code:'0FC2Rm02'),
(instr:'cmpnltps xmm,xmm';code:'0FC2Rm05'),
(instr:'cmpnleps xmm,xmm';code:'0FC2Rm06'),
(instr:'cmpordps xmm,xmm';code:'0FC2Rm07'),
(instr:'cmpunordps xmm,xmm';code:'0FC2Rm03'),
(instr:'cmpeqss xmm,xmm';code:'F30FC2Rm00'),
(instr:'cmpneqss xmm,xmm';code:'F30FC2Rm04'),
(instr:'cmpltss xmm,xmm';code:'F30FC2Rm01'),
(instr:'cmpless xmm,xmm';code:'F30FC2Rm02'),
(instr:'cmpnltss xmm,xmm';code:'F30FC2Rm05'),
(instr:'cmpnless xmm,xmm';code:'F30FC2Rm06'),
(instr:'cmpordss xmm,xmm';code:'F30FC2Rm07'),
(instr:'cmpunordss xmm,xmm';code:'F30FC2Rm03'),
(instr:'comiss xmm,xmm';code:'0F2FRm'),
(instr:'ucomiss xmm,xmm';code:'0F2ERm'),
(instr:'cvtpi2ps xmm,mm';code:'0F2ARm'),
(instr:'cvtps2pi mm,xmm';code:'0F2DRm'),
(instr:'cvtsi2ss xmm,r32';code:'F30F2ARm'),
(instr:'cvtss2si r32,xmm';code:'F30F2DRm'),
(instr:'cvttps2pi mm,xmm';code:'0F2CRm'),
(instr:'cvttss2si r32,xmm';code:'F30F2CRm'),
(instr:'movdqa xmm,xmm';code:'660F6FRm'),
(instr:'movdqa m,xmm';code:'660F7FRm'),
(instr:'movdqu xmm,xmm';code:'F30F6FRm'),
(instr:'movdqu m,xmm';code:'F30F7FRm'),
(instr:'movaps xmm,xmm';code:'0F28Rm'),
(instr:'movaps m,xmm';code:'0F29Rm'),
(instr:'movups xmm,xmm';code:'0F10Rm'),
(instr:'movups m,xmm';code:'0F11Rm'),
(instr:'movhlps xmm,xmm';code:'0F12Rm'),
(instr:'movlhps xmm,xmm';code:'0F16Rm'),
(instr:'movmskps r32,xmm';code:'0F50Rm'),
(instr:'movss m,xmm';code:'F30F11Rm'),
(instr:'movss xmm,xmm';code:'F30F10Rm'),
(instr:'movss xmm,xmm';code:'F30F10Rm'),
(instr:'movntps m,xmm';code:'0F2B00'),
(instr:'shufps xmm,xmm,i';code:'0FC6RmI8'),
(instr:'unpckhps xmm,xmm';code:'0F15Rm'),
(instr:'unpcklps xmm,xmm';code:'0F14Rm'),
//hetAssembler.pas.99: nop;nop;nop;nop;nop;nop;nop;nop; //SSE2
(instr:'addpd xmm,xmm';code:'660F58Rm'),
(instr:'addsd xmm,xmm';code:'F20F58Rm'),
(instr:'subpd xmm,xmm';code:'660F5CRm'),
(instr:'subsd xmm,xmm';code:'F20F5CRm'),
(instr:'mulpd xmm,xmm';code:'660F59Rm'),
(instr:'mulsd xmm,xmm';code:'F20F59Rm'),
(instr:'divpd xmm,xmm';code:'660F5ERm'),
(instr:'divsd xmm,xmm';code:'F20F5ERm'),
(instr:'maxpd xmm,xmm';code:'660F5FRm'),
(instr:'maxsd xmm,xmm';code:'F20F5FRm'),
(instr:'minpd xmm,xmm';code:'660F5DRm'),
(instr:'minsd xmm,xmm';code:'F20F5DRm'),
(instr:'paddb xmm,xmm';code:'660FFCRm'),
(instr:'paddw xmm,xmm';code:'660FFDRm'),
(instr:'paddd xmm,xmm';code:'660FFERm'),
(instr:'paddq xmm,xmm';code:'660FD4Rm'),
(instr:'paddsb xmm,xmm';code:'660FECRm'),
(instr:'paddsw xmm,xmm';code:'660FEDRm'),
(instr:'paddusb xmm,xmm';code:'660FDCRm'),
(instr:'paddusw xmm,xmm';code:'660FDDRm'),
(instr:'psubb xmm,xmm';code:'660FF8Rm'),
(instr:'psubw xmm,xmm';code:'660FF9Rm'),
(instr:'psubd xmm,xmm';code:'660FFARm'),
(instr:'psubq xmm,xmm';code:'660FFBRm'),
(instr:'psubsb xmm,xmm';code:'660FE8Rm'),
(instr:'psubsw xmm,xmm';code:'660FE9Rm'),
(instr:'psubusb xmm,xmm';code:'660FD8Rm'),
(instr:'psubusw xmm,xmm';code:'660FD9Rm'),
(instr:'pmaddwd xmm,xmm';code:'660FF5Rm'),
(instr:'pmulhw xmm,xmm';code:'660FE5Rm'),
(instr:'pmullw xmm,xmm';code:'660FD5Rm'),
(instr:'pmuludq xmm,xmm';code:'660FF4Rm'),
(instr:'rcpps xmm,xmm';code:'0F53Rm'),
(instr:'rcpss xmm,xmm';code:'F30F53Rm'),
(instr:'sqrtpd xmm,xmm';code:'660F51Rm'),
(instr:'sqrtsd xmm,xmm';code:'F20F51Rm'),
(instr:'andnpd xmm,xmm';code:'660F55Rm'),
(instr:'andnps xmm,xmm';code:'0F55Rm'),
(instr:'andpd xmm,xmm';code:'660F54Rm'),
(instr:'pand xmm,xmm';code:'660FDBRm'),
(instr:'pandn xmm,xmm';code:'660FDFRm'),
(instr:'por xmm,xmm';code:'660FEBRm'),
(instr:'pslldq xmm,i';code:'660F73F8R3I8'),
(instr:'psllq xmm,xmm';code:'660FF3Rm'),
(instr:'pslld xmm,xmm';code:'660FF2Rm'),
(instr:'psllw xmm,xmm';code:'660FF1Rm'),
(instr:'psrad xmm,xmm';code:'660FE2Rm'),
(instr:'psraw xmm,xmm';code:'660FE1Rm'),
(instr:'psrldq xmm,i';code:'660F73D8R3I8'),
(instr:'psrlq xmm,xmm';code:'660FD3Rm'),
(instr:'psrld xmm,xmm';code:'660FD2Rm'),
(instr:'psrlw xmm,xmm';code:'660FD1Rm'),
(instr:'psllq xmm,i';code:'660F73F0R3I8'),
(instr:'pslld xmm,i';code:'660F72F0R3I8'),
(instr:'psllw xmm,i';code:'660F71F0R3I8'),
(instr:'psrad xmm,i';code:'660F72E0R3I8'),
(instr:'psraw xmm,i';code:'660F71E0R3I8'),
(instr:'psrlq xmm,i';code:'660F73D0R3I8'),
(instr:'psrld xmm,i';code:'660F72D0R3I8'),
(instr:'psrlw xmm,i';code:'660F71D0R3I8'),
(instr:'pxor xmm,xmm';code:'660FEFRm'),
(instr:'orpd xmm,xmm';code:'660F56Rm'),
(instr:'xorpd xmm,xmm';code:'660F57Rm'),
(instr:'cmpeqpd xmm,xmm';code:'660FC2Rm00'),
(instr:'cmpneqpd xmm,xmm';code:'660FC2Rm04'),
(instr:'cmpltpd xmm,xmm';code:'660FC2Rm01'),
(instr:'cmplepd xmm,xmm';code:'660FC2Rm02'),
(instr:'cmpnltpd xmm,xmm';code:'660FC2Rm05'),
(instr:'cmpnlepd xmm,xmm';code:'660FC2Rm06'),
(instr:'cmpordpd xmm,xmm';code:'660FC2Rm07'),
(instr:'cmpunordpd xmm,xmm';code:'660FC2Rm03'),
(instr:'cmpeqsd xmm,xmm';code:'F20FC2Rm00'),
(instr:'cmpneqsd xmm,xmm';code:'F20FC2Rm04'),
(instr:'cmpltsd xmm,xmm';code:'F20FC2Rm01'),
(instr:'cmplesd xmm,xmm';code:'F20FC2Rm02'),
(instr:'cmpnltsd xmm,xmm';code:'F20FC2Rm05'),
(instr:'cmpnlesd xmm,xmm';code:'F20FC2Rm06'),
(instr:'cmpordsd xmm,xmm';code:'F20FC2Rm07'),
(instr:'cmpunordsd xmm,xmm';code:'F20FC2Rm03'),
(instr:'comisd xmm,xmm';code:'660F2FRm'),
(instr:'ucomisd xmm,xmm';code:'660F2ERm'),
(instr:'pcmpeqb xmm,xmm';code:'660F74Rm'),
(instr:'pcmpgtb xmm,xmm';code:'660F64Rm'),
(instr:'pcmpeqw xmm,xmm';code:'660F75Rm'),
(instr:'pcmpgtw xmm,xmm';code:'660F65Rm'),
(instr:'pcmpeqd xmm,xmm';code:'660F76Rm'),
(instr:'pcmpgtd xmm,xmm';code:'660F66Rm'),
(instr:'cvtdq2pd xmm,xmm';code:'F30FE6Rm'),
(instr:'cvtdq2ps xmm,xmm';code:'0F5BRm'),
(instr:'cvtpd2pi mm,xmm';code:'660F2DRm'),
(instr:'cvtpd2dq xmm,xmm';code:'F20FE6Rm'),
(instr:'cvtpd2ps xmm,xmm';code:'660F5ARm'),
(instr:'cvtpi2pd xmm,mm';code:'660F2ARm'),
(instr:'cvtps2dq xmm,xmm';code:'660F5BRm'),
(instr:'cvtps2pd xmm,xmm';code:'0F5ARm'),
(instr:'cvtsd2si r32,xmm';code:'F20F2DRm'),
(instr:'cvtsd2ss xmm,xmm';code:'F20F5ARm'),
(instr:'cvtsi2sd xmm,r32';code:'F20F2ARm'),
(instr:'cvtsi2ss xmm,r32';code:'F30F2ARm'),
(instr:'cvtss2sd xmm,xmm';code:'F30F5ARm'),
(instr:'cvtss2si r32,xmm';code:'F30F2DRm'),
(instr:'cvttpd2pi mm,xmm';code:'660F2CRm'),
(instr:'cvttpd2dq xmm,xmm';code:'660FE6Rm'),
(instr:'cvttps2dq xmm,xmm';code:'F30F5BRm'),
(instr:'cvttps2pi mm,xmm';code:'0F2CRm'),
(instr:'cvttsd2si r32,xmm';code:'F20F2CRm'),
(instr:'cvttss2si r32,xmm';code:'F30F2CRm'),
(instr:'movq mm,mm';code:'0F6FRm'),
(instr:'movsd xmm,xmm';code:'F20F10Rm'),
(instr:'movapd xmm,xmm';code:'660F28Rm'),
(instr:'movupd xmm,xmm';code:'660F10Rm'),
(instr:'movapd m,xmm';code:'660F29Rm'),
(instr:'movupd m,xmm';code:'660F11Rm'),
(instr:'movhpd xmm,m';code:'660F16Rm'),
(instr:'movhpd m,xmm';code:'660F17Rm'),
(instr:'movlpd xmm,m';code:'660F12Rm'),
(instr:'movlpd m,xmm';code:'660F13Rm'),
(instr:'movdq2q mm,xmm';code:'F20FD6Rm'),
(instr:'movq2dq xmm,mm';code:'F30FD6Rm'),
(instr:'movntpd m,xmm';code:'660F2BRm'),
(instr:'movntdq m,xmm';code:'660FE7Rm'),
(instr:'maskmovdqu xmm,xmm';code:'660FF7Rm'),
(instr:'pmovmskb r32,xmm';code:'660FD7Rm'),
(instr:'pshufd xmm,xmm,i';code:'660F70RmI8'),
(instr:'pshufhw xmm,xmm,i';code:'F30F70RmI8'),
(instr:'pshuflw xmm,xmm,i';code:'F20F70RmI8'),
(instr:'unpckhpd xmm,xmm';code:'660F15Rm'),
(instr:'unpcklpd xmm,xmm';code:'660F14Rm'),
(instr:'punpckhbw xmm,xmm';code:'660F68Rm'),
(instr:'punpckhwd xmm,xmm';code:'660F69Rm'),
(instr:'punpckhdq xmm,xmm';code:'660F6ARm'),
(instr:'punpckhqdq xmm,xmm';code:'660F6DRm'),
(instr:'punpcklbw xmm,xmm';code:'660F60Rm'),
(instr:'punpcklwd xmm,xmm';code:'660F61Rm'),
(instr:'punpckldq xmm,xmm';code:'660F62Rm'),
(instr:'punpcklqdq xmm,xmm';code:'660F6CRm'),
(instr:'packssdw xmm,xmm';code:'660F6BRm'),
(instr:'packsswb xmm,xmm';code:'660F63Rm'),
(instr:'packuswb xmm,xmm';code:'660F67Rm'),
// SSE3 (csak a fele még)
(instr:'addsubpd xmm,xmm';code:'660FD0Rm'),
(instr:'addsubps xmm,xmm';code:'F20FD0Rm'),
(instr:'haddpd xmm,xmm';code:'660F7CRm'),
(instr:'haddps xmm,xmm';code:'F20F7CRm'),
(instr:'hsubpd xmm,xmm';code:'660F7DRm'),
(instr:'hsubps xmm,xmm';code:'F20F7DRm'),
// SSE4 cont
(instr:'roundps xmm,xmm,i';code:'660F3A08RmI8'), //0:nearest,1:floor,2:ceil,3:trunc_towards_zero
(instr:'pminud xmm,xmm';code:'660F383BRm')
);

function regTypeOf(const s:ansistring):ansistring;
var i:integer;
begin
  if isWild2('xmm?',s)then result:='xmm' else
  if isWild2('mm?',s)then result:='mm' else
  if isWild2('[*]',s)then result:='m' else
  if isWild2('e??',s)then result:='r32' else
  if TryStrToInt(s,i) then result:='i' else
    result:='';
end;

function regIndexOf(const s:ansistring):integer;
var t:AnsiString;
begin
  result:=-1;
  t:=regTypeOf(s);
  if t='' then exit;

  if t='xmm' then result:=strtointdef(copy(s,4,1),-1)else
  if t='mm' then result:=strtointdef(copy(s,3,1),-1)else
  if cmp(s,'eax')=0 then result:=0 else
  if cmp(s,'ecx')=0 then result:=1 else
  if cmp(s,'edx')=0 then result:=2 else
  if cmp(s,'ebx')=0 then result:=3 else
  if cmp(s,'esp')=0 then result:=4 else
  if cmp(s,'ebp')=0 then result:=5 else
  if cmp(s,'esi')=0 then result:=6 else
  if cmp(s,'edi')=0 then result:=7 else
    result:=-1;
end;

function AsmCompile(const src:ansistring;const AlignCode16:boolean=false):rawbytestring;
var ch:PAnsiChar;tk:TToken;val:variant;

  procedure Parse;begin tk:=ParsePascalToken(ch,val)end;
  procedure Error(const s:string);begin raise Exception.Create('CompileAsm() '+s)end;

var code:ansistring;

  procedure MakeRM(const reg,regmem:ansistring);
    procedure SetRm(const rm:ansistring);begin Replace('Rm',rm,code,[roIgnoreCase])end;
  var regId,regMemId:integer;
      regMemType,s:AnsiString;
      s2,rt:ansistring;

      base,index,disp,dispCode:ansistring;
      baseRegId,indexRegId,indexShl,dispNum:integer;
      i:integer;

  begin
    if pos('Rm',code)<=0 then error('fatal error in MakeRm() no Rm in code');

    regId:=regIndexOf(reg);
    if not(regId in[0..7])then error('Invalid register '+reg);

    baseRegId:=0;indexRegId:=0;indexShl:=0;dispNum:=0;//nowarn

    regMemType:=regTypeOf(regmem);
    if(regMemType='m')then begin
      s:=copy(regmem,2,length(regmem)-2);trim(s);
      for i:=0 to listcount(s,'+')-1 do begin
        s2:=ListItem(s,i,'+');
        rt:=regTypeOf(s2);
        if rt='i' then begin //displacement
          if disp<>'' then Error('Displacement already specified');
          disp:=s2;
          dispNum:=StrToInt(s2);
        end else if rt='r32' then begin //base or index*1
          if base='' then begin
            base:=s2;
            baseRegId:=regIndexOf(base);
            if not(baseregId in[0..7])then error('Invalid register '+regmem);
          end else if index='' then begin
            index:=s2;
            indexShl:=0;
            indexRegId:=regIndexOf(index);
            if not(indexRegId in[0..7])then error('Invalid register '+regmem);
          end else
            error('Invalid RegMem '+regmem);
        end else if pos('*',s2)>0 then begin //index*x
          if index='' then begin
            indexShl:=StrToIntDef(listitem(s2,1,'*'),-1);
            case indexShl of
              1:indexShl:=0;
              2:indexShl:=1;
              4:indexShl:=2;
              8:indexShl:=3;
            else
              error('invalid regmem index '+regmem);
            end;
            index:=listitem(s2,0,'*');
            if regTypeOf(index)<>'r32' then
              error('invalid regmem '+regmem);
            indexRegId:=regIndexOf(index);
            if not(indexRegId in[0..7])then
              error('Invalid register '+regmem);
          end else
            error('Invalid RegMem '+regmem);
        end else
          error('Invalid RegMem '+regmem);
      end;

      //base,index,disp are valid.
      if(index<>'')and(base='')then error('Invalid regmem '+regmem);

      if(disp<>'')and(dispNum<>0)then begin
        if(dispNum>=-128)and(dispNum<=127)then
          dispCode:=inttohex(byte(dispNum),2)
        else begin
          dispCode:=inttohex(dispNum shr  0 and $ff,2)+inttohex(dispNum shr  8 and $ff,2)+
                    inttohex(dispNum shr 16 and $ff,2)+inttohex(dispNum shr 24 and $ff,2);
        end;
        if(base='')then begin //[disp]
          if length(dispCode)=2 then dispcode:='000000'+dispcode;
          SetRm(intToHex(regId shl 3+5,2)+dispCode);
        end else if(index='')then begin //[base+disp]
          if baseRegId=4{sib} then error('Invalid regmem '+regmem);
          if length(dispCode)=2 then SetRm(inttohex(1 shl 6+regid shl 3+baseRegId,2)+dispcode)
                                else SetRm(inttohex(2 shl 6+regid shl 3+baseRegId,2)+dispcode)
        end else begin //[base+index*x+disp]
          if length(dispCode)=2 then SetRm(inttohex(1 shl 6+regid shl 3+4{sib},2)+inttohex(indexShl shl 6+baseRegId+indexRegId shl 3,2)+dispcode)
                                else SetRm(inttohex(2 shl 6+regid shl 3+4{sib},2)+inttohex(indexShl shl 6+baseRegId+indexRegId shl 3,2)+dispcode)
        end;
      end else begin
        if(base='')then error('Invalid regmem '+regmem);
        if index='' then begin //[base]
          if baseRegId in[4,5] then error('Invalid regmem '+regmem);
          SetRm(intToHex(regId shl 3+baseRegId,2));
        end else begin //[base+index*n]
          //checks!!
          SetRm(inttohex(regid shl 3+4{sib},2)+inttohex(indexShl shl 6+baseRegId+indexRegId shl 3,2))
        end;
      end;
    end else begin    // reg,reg
      regMemId:=regIndexOf(regMem);
      if not(regId in[0..7])then error('Invalid register '+reg);
      SetRm(IntToHex($C0+regId shl 3+regMemId,2));
    end;
  end;

  procedure MakeI8(const imm:ansistring);
  var i:integer;
  begin
    if pos('I8',code)<=0 then error('fatal error in MakeI8() no I8 in code');
    i:=StrToIntDef(imm,-1);
    if(i<0)or(i>255)then error('Invalid immed8 '+imm);

    Replace('I8',IntToHex(i,2),code,[roIgnoreCase]);
  end;

  procedure MakeR3(const reg:ansistring);
  var i,rid:integer;
  begin
    i:=pos('R3',code);
    if i<=1 then error('fatal error in MakeR3() no R3 in code');
    rid:=regIndexOf(reg);
    if(rid<0)or(rid>7)then error('Invalid reg '+reg);

    Delete(code,i,2);
    code[i-1]:=charn(inttohex(strtoint('$'+code[i-1])or rid,1),1);
  end;

type
  TInstr=record
    code:ansistring;
    RmOfs:integer;
  end;

var
  InstrList:array of TInstr;

  procedure AddInstruction(const code,template:RawByteString);
  var a:TInstr;
  begin
    a.code:=code;
    a.RmOfs:=pos('Rm',template,[poIgnoreCase]);
    if a.RmOfs>0 then a.RmOfs:=(a.RmOfs-1)shr 1
                 else a.RmOfs:=-1;
    setlength(InstrList,length(InstrList)+1);
    InstrList[high(InstrList)]:=a;
  end;

  procedure DoAlignCode16;

    procedure DoAlign(first,last:integer);
    const nops:array[0..9]of rawbytestring=(
      '',
      '90',
      '8BC0',
      '8D4000',
      '0F1F4000',
      '0F1F440000',
      '8D8000000000',
      '0F1F8000000000',
      '0F1F840000000000',
      '660F1F840000000000');

    function ByteAt(const s:ansistring;const pos:integer):byte;
    begin
      result:=strtoint('$'+copy(s,pos shl 1+1,2));
    end;

    procedure SetByteAt(var s:ansistring;const pos:integer;const b:byte);
    var s2:ansistring;
    begin
      s2:=IntToHex(b,2);
      s[pos shl 1+1]:=s2[1];
      s[pos shl 1+1+1]:=s2[2];
    end;

    procedure InsertByteAt(var s:ansistring;const pos:integer;const b:byte);
    begin
      insert(IntToHex(b,2),s,pos shl 1+1);
//      s:=copy(s,1,pos*2)++copy(s,pos shl 1+1,$ff);
    end;

    var i,j,len,dispOfs:integer;
        rmFull,_mod,_rm:byte;
        hasSib:boolean;
        b:byte;
    begin
      len:=0;
      for i:=first to last do
        len:=len+length(InstrList[i].code)shr 1;
      len:=16-len;
      if(len<=0)or(len>9)then raise Exception.Create('AsmCompile.DoAlign16() serious shit happens');

      for i:=first to last do with InstrList[i]do if RmOfs>0 then begin
        rmFull:=ByteAt(code,RmOfs);
        _mod:=rmFull shr 6;
        if _mod<2 then begin
          _rm:=rmFull and 7;
          hasSib:=_rm=4;
          dispOfs:=RmOfs+ord(HasSib)+1;
          if(_mod=0)and(len>=4)then begin //0->dword
            SetByteAt(code,RmOfs,rmFull+2 shl 6);
            for j:=0 to 3 do InsertByteAt(code,dispOfs,0);
            dec(len,4);
          end else if(_mod=1)and(len>=3)then begin //byte->dword
            SetByteAt(code,RmOfs,rmFull+1 shl 6);
            b:=ByteAt(code,dispOfs)shr 7*255;
            for j:=0 to 2 do InsertByteAt(code,dispOfs+1,b);
            dec(len,3);
          end else if(_mod=0)and(len>=1)then begin //0->byte
            SetByteAt(code,RmOfs,rmFull+1 shl 6);
            InsertByteAt(code,dispOfs,0);
            dec(len);
          end;
        end;
        if(len>=1)and(IsWild2('0F28*',code)or IsWild2('0F29*',code))then begin
          code:='66'+code;
          dec(len);
        end;
      end;

      InstrList[last].code:=InstrList[last].code+nops[len];
    end;

  var i,start,ofs,actLen:integer;
  begin
    ofs:=0;start:=0;
    for i:=0 to high(InstrList)do begin
      actLen:=length(InstrList[i].code)shr 1;
      ofs:=ofs+actLen;
      if ofs=16 then begin
        ofs:=0;
        start:=i+1;
      end else if ofs>16 then begin
        DoAlign(start,i-1);
        ofs:=actLen;
        start:=i;
      end;
    end;
  end;

var instr:AnsiString;
    s,s1,s2:ansistring;
    declParams:ansistring;
    params:THetArray<ansistring>;
    i,j:integer;
    template:RawByteString;

begin
  result:='';
  if src='' then exit;

  ch:=pointer(src);
  parse;
  while true do case tk of
    tkEof:break;
    tkSemiColon,tkDirective:begin parse;continue;end;
    tkIdentifier:begin
      instr:=val;params.clear;
      parse;
      while true do begin
        case tk of
          tkIdentifier,tkConstant:begin
            params.Append(val);
            parse;
          end;
          tkSqrBracketOpen:begin
            parse;
            s:='[';
            while true do case tk of
              tkSqrBracketClose:begin s:=s+']';parse;params.Append(s);break end;
              tkPlus:begin s:=s+'+';Parse;end;
              tkMinus:begin s:=s+'+-';Parse;end;
              tkMul:begin s:=s+'*';Parse;end;
              tkConstant,tkIdentifier:begin s:=s+ansistring(val);parse end;
            else
              Error('invalid token (at '+instr+' [] )');
            end;
          end;
        else
          Error('invalid token (at '+instr+' [] )');
        end;
        if tk=tkComma then Parse else break;
      end;

      //instr, params are valid
      s:=instr+' ';
      for i:=0 to params.FCount-1 do begin
        if i>0 then s:=s+',';
        s:=s+regTypeOf(params.FItems[i]);
      end;
      s1:=s;
      //find instruction
      j:=-1;for i:=0 to high(Instructions)do if Instructions[i].instr=s then begin j:=i;break end;
      //try read from mem instead of reg
      if j<0 then begin
        s:=instr+' ';
        for i:=0 to params.FCount-1 do begin
          if i>0 then s:=s+',';
          s2:=regTypeOf(params.FItems[i]);
          if(i=1)and((s2='m'))then s2:='xmm';
          s:=s+s2;
        end;
        for i:=0 to high(Instructions)do if Instructions[i].instr=s then begin j:=i;break end;
      end;
      if j<0 then error('unknown asm instruction '+s1);

      declParams:=listitem(Instructions[j].instr,1,' ');
      template:=Instructions[j].code;
      code:=template;
      with params do
      if declParams='m,xmm' then         MakeRM(FItems[1],FItems[0])else
      if declParams='r32,xmm' then       MakeRM(FItems[1],FItems[0])else
      if declParams='mm,xmm' then        MakeRM(FItems[1],FItems[0])else
      if declParams='xmm,xmm'then        MakeRM(FItems[0],FItems[1])else
      if declParams='xmm,r32'then        MakeRM(FItems[0],FItems[1])else
      if declParams='xmm,mm'then        MakeRM(FItems[0],FItems[1])else
      if declParams='xmm,i' then         begin MakeR3(FItems[0]);MakeI8(FItems[1])end else
      if declParams='xmm,xmm,i' then     begin MakeRM(FItems[0],FItems[1]);MakeI8(FItems[2])end else
        Error('Unknown parameter declaration '+declParams);

      AddInstruction(code,template);
    end;
  else
    error('asm instruction expected.');
  end;

  if AlignCode16 then
    DoAlignCode16;

  result:='';
  for i:=0 to high(InstrList) do
    result:=result+InstrList[i].code;

  if result<>'' then begin
    result:='#$'+result;
    ch:=pointer(result);
    result:=ParsePascalConstant(ch);
  end;
end;

function AsmDump(const src:rawbytestring):ansistring;
var pos:integer;
    act:rawbytestring;
begin
  result:='';
  pos:=1;
  with AnsiStringBuilder(result)do begin
    while pos<=length(src) do begin
      act:=copy(src,pos,16);
      pos:=pos+16;

      while length(act)>=4 do begin
        AddStr('dd $'+inttohex(pcardinal(act)^,8)+';');
        delete(act,1,4);
      end;
      while length(act)>=2 do begin
        AddStr('dw $'+inttohex(pword(act)^,4)+';');
        delete(act,1,2);
      end;
      while length(act)>=1 do begin
        AddStr('db $'+inttohex(pword(act)^,2)+';');
        delete(act,1,1);
      end;
      AddStr(#13#10);
    end;
  end;
end;

procedure AsmExecute(const src:ansistring;const _eax:integer=0;const _ecx:integer=0;const _edx:integer=0);
var code:RawByteString;
begin
  code:=AsmCompile(src)+#$C3;
  asm
    mov eax,_eax;
    mov edx,_edx;
    mov ecx,_ecx;
    call [code]
  end;
end;


procedure asmtestSSE;
var i:array[0..16*32]of byte;
asm
  lea eax,i;add eax,15;and eax,not 15;xor ecx,ecx
  nop;nop;nop;nop; //SSE1

  pxor xmm0,xmm0

  addps xmm0,xmm0
  addss xmm0,xmm0
  subps xmm0,xmm0
  subss xmm0,xmm0
  mulps xmm0,xmm0
  mulss xmm0,xmm0
  divps xmm0,xmm0
  divss xmm0,xmm0
  rcpps xmm0,xmm0
  rcpss xmm0,xmm0
  sqrtps xmm0,xmm0
  sqrtss xmm0,xmm0
  rsqrtps xmm0,xmm0
  rsqrtss xmm0,xmm0
  maxps xmm0,xmm0
  maxss xmm0,xmm0
  minps xmm0,xmm0
  minss xmm0,xmm0
  pavgb xmm0,xmm0
  pavgw xmm0,xmm0
  psadbw xmm0,xmm0
  push eax pextrw eax,xmm0,0 pop eax
  pinsrw xmm0,eax,0
  pmaxsw xmm0,xmm0
  pmaxub xmm0,xmm0
  pminsw xmm0,xmm0
  pminub xmm0,xmm0
  push eax pmovmskb eax,xmm0 pop eax
  pmulhuw xmm0,xmm0
  pshufw mm0,mm0,0
  andnps xmm0,xmm0
  andps xmm0,xmm0
  orps xmm0,xmm0
  xorps xmm0,xmm0

  cmpeqps xmm0,xmm0
  cmpneqps xmm0,xmm0
  cmpltps xmm0,xmm0
  cmpleps xmm0,xmm0
  cmpnltps xmm0,xmm0
  cmpnleps xmm0,xmm0
  cmpordps xmm0,xmm0
  cmpunordps xmm0,xmm0

  cmpeqss xmm0,xmm0
  cmpneqss xmm0,xmm0
  cmpltss xmm0,xmm0
  cmpless xmm0,xmm0
  cmpnltss xmm0,xmm0
  cmpnless xmm0,xmm0
  cmpordss xmm0,xmm0
  cmpunordss xmm0,xmm0

  comiss xmm0,xmm0
  ucomiss xmm0,xmm0

  cvtpi2ps xmm0,mm0
  cvtps2pi mm0,xmm0
  cvtsi2ss xmm0,eax
  cvtss2si eax,xmm0
  cvttps2pi mm0,xmm0
  cvttss2si eax,xmm0

  movdqa xmm0,xmm0
  movdqa [eax],xmm0
  movdqu xmm0,xmm0
  movdqu [eax],xmm0

  movaps xmm0,xmm0
  movaps [eax],xmm0
  movups xmm0,xmm0
  movups [eax],xmm0

  movhlps xmm0,xmm0
  movlhps xmm0,xmm0

  movmskps eax,xmm0
//  movss [eax],xmm0
  movss xmm0,xmm0
  movss xmm0,xmm0

//  movntps [eax],xmm0

  shufps xmm0,xmm0,0
  unpckhps xmm0,xmm0
  unpcklps xmm0,xmm0

  nop;nop;nop;nop;nop;nop;nop;nop; //SSE2

  addpd xmm0,xmm0
  addsd xmm0,xmm0
  subpd xmm0,xmm0
  subsd xmm0,xmm0
  mulpd xmm0,xmm0
  mulsd xmm0,xmm0
  divpd xmm0,xmm0
  divsd xmm0,xmm0
  maxpd xmm0,xmm0
  maxsd xmm0,xmm0
  minpd xmm0,xmm0
  minsd xmm0,xmm0
  paddb xmm0,xmm0
  paddw xmm0,xmm0
  paddd xmm0,xmm0
  paddq xmm0,xmm0
  paddsb xmm0,xmm0
  paddsw xmm0,xmm0
  paddusb xmm0,xmm0
  paddusw xmm0,xmm0
  psubb xmm0,xmm0
  psubw xmm0,xmm0
  psubd xmm0,xmm0
  psubq xmm0,xmm0
  psubsb xmm0,xmm0
  psubsw xmm0,xmm0
  psubusb xmm0,xmm0
  psubusw xmm0,xmm0
  pmaddwd xmm0,xmm0
  pmulhw xmm0,xmm0
  pmullw xmm0,xmm0
  pmuludq xmm0,xmm0
  rcpps xmm0,xmm0
  rcpss xmm0,xmm0
  sqrtpd xmm0,xmm0
  sqrtsd xmm0,xmm0


  andnpd xmm0,xmm0
  andnps xmm0,xmm0
  andpd xmm0,xmm0
  pand xmm0,xmm0
  pandn xmm0,xmm0
  por xmm0,xmm0
  pslldq xmm0,0
  psllq xmm0,xmm0
  pslld xmm0,xmm0
  psllw xmm0,xmm0
  psrad xmm0,xmm0
  psraw xmm0,xmm0
  psrldq xmm0,0
  psrlq xmm0,xmm0
  psrld xmm0,xmm0
  psrlw xmm0,xmm0
  psllq xmm0,0
  pslld xmm0,0
  psllw xmm0,0
  psrad xmm0,0
  psraw xmm0,0
  psrlq xmm0,0
  psrld xmm0,0
  psrlw xmm0,0
  pxor xmm0,xmm0
  orpd xmm0,xmm0
  xorpd xmm0,xmm0

  cmpeqpd xmm0,xmm0
  cmpneqpd xmm0,xmm0
  cmpltpd xmm0,xmm0
  cmplepd xmm0,xmm0
  cmpnltpd xmm0,xmm0
  cmpnlepd xmm0,xmm0
  cmpordpd xmm0,xmm0
  cmpunordpd xmm0,xmm0

  cmpeqsd xmm0,xmm0
  cmpneqsd xmm0,xmm0
  cmpltsd xmm0,xmm0
  cmplesd xmm0,xmm0
  cmpnltsd xmm0,xmm0
  cmpnlesd xmm0,xmm0
  cmpordsd xmm0,xmm0
  cmpunordsd xmm0,xmm0

  comisd xmm0,xmm0
  ucomisd xmm0,xmm0

  pcmpeqb xmm0,xmm0
  pcmpgtb xmm0,xmm0
  pcmpeqw xmm0,xmm0
  pcmpgtw xmm0,xmm0
  pcmpeqd xmm0,xmm0
  pcmpgtd xmm0,xmm0

  cvtdq2pd xmm0,xmm0
  cvtdq2ps xmm0,xmm0
  cvtpd2pi mm0,xmm0
  cvtpd2dq xmm0,xmm0
  cvtpd2ps xmm0,xmm0
  cvtpi2pd xmm0,mm0
  cvtps2dq xmm0,xmm0
  cvtps2pd xmm0,xmm0
  cvtsd2si eax,xmm0
  cvtsd2ss xmm0,xmm0
  cvtsi2sd xmm0,eax
  cvtsi2ss xmm0,eax
  cvtss2sd xmm0,xmm0
  cvtss2si eax,xmm0
  cvttpd2pi mm0,xmm0
  cvttpd2dq xmm0,xmm0
  cvttps2dq xmm0,xmm0
  cvttps2pi mm0,xmm0
  cvttsd2si eax,xmm0
  cvttss2si eax,xmm0

  movq mm0,mm0
  movsd xmm0,xmm0
  movapd xmm0,xmm0
  movupd xmm0,xmm0
{  movapd [eax],xmm0
  movupd [eax],xmm0
  movhpd xmm0,[eax]
  movhpd [eax],xmm0
  movlpd xmm0,[eax]
  movlpd [eax],xmm0
  movdq2q mm0,xmm0
  movq2dq xmm0,mm0
  movntpd [eax],xmm0
  movntdq [eax],xmm0
  maskmovdqu xmm0,xmm0
  pmovmskb eax,xmm0

  pshufd xmm0,xmm0,0
  pshufhw xmm0,xmm0,0
  pshuflw xmm0,xmm0,0
  unpckhpd xmm0,xmm0
  unpcklpd xmm0,xmm0
  punpckhbw xmm0,xmm0
  punpckhwd xmm0,xmm0
  punpckhdq xmm0,xmm0
  punpckhqdq xmm0,xmm0
  punpcklbw xmm0,xmm0
  punpcklwd xmm0,xmm0
  punpckldq xmm0,xmm0
  punpcklqdq xmm0,xmm0
  packssdw xmm0,xmm0
  packsswb xmm0,xmm0
  packuswb xmm0,xmm0

}  nop;nop;nop;nop;nop;nop;nop;nop; //SSE3

  addsubpd xmm0,xmm0
  addsubps xmm0,xmm0
  haddpd   xmm0,xmm0
  haddps   xmm0,xmm0
  hsubpd   xmm0,xmm0
  hsubps   xmm0,xmm0

{  lddqu xmm0,[eax]
  movddup xmm0,xmm0
  movshdup xmm0,xmm0
  movsldup xmm0,xmm0

  nop;nop;nop;nop;nop;nop;nop;nop; //SSSE3

  psignd xmm0,xmm0
  psignw xmm0,xmm0
  psignb xmm0,xmm0
  phaddd xmm0,xmm0
  phaddw xmm0,xmm0
  phaddsw xmm0,xmm0
  phsubd xmm0,xmm0
  phsubw xmm0,xmm0
  phsubsw xmm0,xmm0
  pmaddubsw xmm0,xmm0
  pabsd xmm0,xmm0
  pabsw xmm0,xmm0
  pabsb xmm0,xmm0
  pmulhrsw xmm0,xmm0
  pshufb xmm0,xmm0
//  palignr xmm0,xmm0

  nop;nop;nop;nop;nop;nop;nop;nop; //SSE4.1

  mpsadbw xmm0,xmm0,0
  phminposuw xmm0,xmm0
  pmuldq xmm0,xmm0
  pmulld xmm0,xmm0
  dpps xmm0,xmm0,0
  dppd xmm0,xmm0,0
  blendps xmm0,xmm0,0
  blendpd xmm0,xmm0,0  }
//  blendvps xmm0,xmm0
//  blendvpd xmm0,xmm0
//  pblendvb xmm0,xmm0
//  pblendw xmm0,xmm0
  pminsb xmm0,xmm0
  pmaxsb xmm0,xmm0
  pminuw xmm0,xmm0
  pmaxuw xmm0,xmm0
  pminud xmm0,xmm0
  pmaxud xmm0,xmm0
  pminsd xmm0,xmm0
  pmaxsd xmm0,xmm0

  roundps xmm0,xmm0,0
//  roundps - packed round single precision float to integer.
//  roundss - scalar round single precision float to integer.
//  roundpd - packed round double precision float to integer.
//  roundsd - scalar round double precision float to integer.

//  inserps - complex data shuffling.
//  pinsrb - complex data shuffling.
//  pinsrd - complex data shuffling.
//  pinsrq - complex data shuffling.
//  extractps - complex data shuffling.
//  pextrb - complex data shuffling.
//  pextrw - complex data shuffling.
//  pextrd - complex data shuffling.
//  pextrq - complex data shuffling.
//  pmovsxbw - packed sign extension.
//  pmovzxbw - packed zero extension.
//  pmovsxbd - packed sign extension.
//  pmovzxbd - packed zero extension.
//  pmovsxbq - packed sign extension.
//  pmovzxbq - packed zero extension.
//  pmovxswd - packed sign extension.
//  pmovzxwd - packed zero extension.
//  pmovsxwq - packed sign extension.
//  pmovzxwq - packed zero extension.
//  pmovsxdq - packed sign extension.
//  pmovzxdq - packed zero extension.
//  ptest - same as test, but for sse registers.
//  pcmpeqq - quadword compare for equality.
//  packusdw - saturating signed dwords to unsigned words.
//  movntdqa - Non-temporal aligned move (this uses write-combining for efficiency).
//
//SSE4.2
//crc32 - CRC32C function (using 0x11edc6f41 as the polynomial).
//pcmpestri - Packed compare explicit length string, Index.
//pcmpestrm - Packed compare explicit length string, Mask.
//pcmpistri - Packed compare implicit length string, Index.
//pcmpistrm - Packed compare implicit length string, Mask.
//pcmpgtq - Packed compare, greater than.
//popcnt - Population count.
//
//SSE4a
//lzcnt - Leading Zero count.
//popcnt - Population count.
//extrq - Mask-shift operation.
//inserq - Mask-shift operation.
//movntsd - Non-temporal double precision move.
//movntss - Non-temporal single precision move.
end;

{var code:RawByteString;
    ch:pansichar;
    temp:array[0..1023]of byte;}
begin
//  asmtestSSE
{  code:=FileReadStr('c:\sample.sse');

  code:='#$'+compileAsm(code)+'C3';
  ch:=pointer(code);
  code:=ParsePascalConstant(ch);
  asm
    mov eax,code
    lea ecx,temp
    add ecx,128
    and ecx,not $f
    call eax
  end;}
end.
