unit het.Utils; //het.filesys umodelpart het.objects het.arrays unsSystem system het.bind  het.fastrtl het.cl het.bignum unssystem
interface

{DEFINE SSE_DYNARRAYS}

uses windows, sysutils, Types, classes, graphics, forms, Controls,
  Dialogs, messages, math, variants, spin, Clipbrd;

//Ebbe a unitba tilos beimportalni a het.objects-t!!!!!

type
  TSyntaxKind=(
    skWhitespace,
    skSelected,
    skFoundAct,
    skFoundAlso,
    skNavLink,
    skNumber,
    skString,
    skKeyword,
    skSymbol,
    skComment,
    skDirective,
    skIdentifier1,
    skIdentifier2,
    skIdentifier3,
    skIdentifier4,
    skIdentifier5,
    skIdentifier6,
    skLabel,
    skAttribute,
    skBasicType,
    skError,
    skBinary1
  );
  TSyntaxKinds=skWhitespace..skBinary1;

type
  TId=type integer;
  TName=type ansistring;
  TDate=type integer;
  TTime=type single;

Function Cmp(const a,b:cardinal):Integer;overload;inline;
Function Cmp(const a,b:Integer):Integer;overload;inline;
Function Cmp(const a,b:Int64):Integer;overload;inline;
Function Cmp(const a,b:single):Integer;overload;inline;
Function Cmp(const a,b:double):Integer;overload;inline;
Function Cmp(const a,b:ansistring):Integer;overload;
Function Cmp(const a,b:string):Integer;overload;
Function Cmp(const a,b:TPoint):Integer;overload;inline;

type
  TIntegerArray=TArray<integer>;
  TSingleArray=TArray<single>;
  TDoubleArray=TArray<double>;
  TAnsiStringArray=TArray<AnsiString>;

type
  TCharMap=array [ansichar]of ansichar;

const
  AnsiCodePage=1252;

const charmapDefault:tcharmap=(
#$00,#$01,#$02,#$03,#$04,#$05,#$06,#$07,#$08,#$09,#$0A,#$0B,#$0C,#$0D,#$0E,#$0F,  #$10,#$11,#$12,#$13,#$14,#$15,#$16,#$17,#$18,#$19,#$1A,#$1B,#$1C,#$1D,#$1E,#$1F,
#$20,#$21,#$22,#$23,#$24,#$25,#$26,#$27,#$28,#$29,#$2A,#$2B,#$2C,#$2D,#$2E,#$2F,  #$30,#$31,#$32,#$33,#$34,#$35,#$36,#$37,#$38,#$39,#$3A,#$3B,#$3C,#$3D,#$3E,#$3F,
'@', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O',   'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', '[', '\', ']', '^', '_',
'`', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o',   'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '{', '|', '}', '~', '',
#$80,#$81,#$82,#$83,#$84,#$85,#$86,#$87,#$88,#$89,#$8A,#$8B,#$8C,#$8D,#$8E,#$8F,  #$90,#$91,#$92,#$93,#$94,#$95,#$96,#$97,#$98,#$99,#$9A,#$9B,#$9C,#$9D,#$9E,#$9F,
#$A0,#$A1,#$A2,#$A3,#$A4,#$A5,#$A6,#$A7,#$A8,#$A9,#$AA,#$AB,#$AC,#$AD,#$AE,#$AF,  #$B0,#$B1,#$B2,#$B3,#$B4,#$B5,#$B6,#$B7,#$B8,#$B9,#$BA,#$BB,#$BC,#$BD,#$BE,#$BF,
'À', 'Á', 'Â', 'Ã', 'Ä', 'Å', 'Æ', 'Ç', 'È', 'É', 'Ê', 'Ë', 'Ì', 'Í', 'Î', 'Ï',   'Ð', 'Ñ', 'Ò', 'Ó', 'Ô', 'Õ', 'Ö', '×', 'Ø', 'Ù', 'Ú', 'Û', 'Ü', 'Ý', 'Þ', 'ß',
'á', 'á', 'â', 'ã', 'ä', 'å', 'æ', 'ç', 'è', 'é', 'ê', 'ë', 'ì', 'í', 'î', 'ï',   'ð', 'ñ', 'ò', 'ó', 'ô', 'õ', 'ö', '÷', 'ø', 'ù', 'ú', 'û', 'ü', 'ý', 'þ', 'ÿ'
);
const charmapOEM:tcharmap=(
#$00,#$01,#$02,#$03,#$04,#$05,#$06,#$07,#$08,#$09,#$0A,#$0B,#$0C,#$0D,#$0E,#$0F,  #$10,#$11,#$12,#$13,#$14,#$15,#$16,#$17,#$18,#$19,#$1A,#$1B,#$1C,#$1D,#$1E,#$1F,
#$20,#$21,#$22,#$23,#$24,#$25,#$26,#$27,#$28,#$29,#$2A,#$2B,#$2C,#$2D,#$2E,#$2F,  #$30,#$31,#$32,#$33,#$34,#$35,#$36,#$37,#$38,#$39,#$3A,#$3B,#$3C,#$3D,#$3E,#$3F,
'@', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O',   'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', '[', '\', ']', '^', '_',
'`', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o',   'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '{', '|', '}', '~', '',
#$80,'ü', 'é', #$83,#$84,#$85,#$86,#$87,#$88,#$89,'Õ', 'õ', #$8C,#$8D,#$8E,#$8F,  'é', #$91,#$92,#$93,'ö', #$95,#$96,#$97,#$98,'Ö', 'Ü', #$9B,#$9C,#$9D,#$9E,#$9F,
'á' ,'í', 'ó', 'ú' ,#$A4,#$A5,#$A6,#$A7,#$A8,#$A9,#$AA,#$AB,#$AC,#$AD,#$AE,#$AF,  #$B0,#$B1,#$B2,#$B3,#$B4,'Á' ,#$B6,#$B7,#$B8,#$B9,#$BA,#$BB,#$BC,#$BD,#$BE,#$BF,
'À', 'Á', 'Â', 'Ã', 'Ä', 'Å', 'Æ', 'Ç', 'È', 'É', 'Ê', 'Ë', 'Ì', 'Í', 'Î', 'Ï',   'Ð', 'Ñ', 'Ò', 'Ó', 'Ô', 'Õ', 'Í', '×', 'Ø', 'Ù', 'Ú', 'Û', 'Ü', 'Ý', 'Þ', 'ß',
'Ó', 'á', 'â', 'ã', 'ä', 'å', 'æ', 'ç', 'è', 'Ú', 'ê', 'Û', 'ì', 'í', 'î', 'ï',   'ð', 'ñ', 'ò', 'ó', 'ô', 'õ', 'ö', '÷', 'ø', 'ù', 'ú', 'û', 'ü', 'ý', 'þ', 'á'
); //R0707 A $ff es $90 javitva

const charmapUpper:tcharmap=(#$00,#$01,#$02,#$03,#$04,#$05,#$06,#$07,#$08,#$09,#$0A,#$0B,#$0C,#$0D,#$0E,#$0F,#$10,#$11,#$12,#$13,#$14,#$15,#$16,#$17,#$18,#$19,#$1A,#$1B,#$1C,#$1D,#$1E,#$1F,#$20,#$21,#$22,#$23,#$24,#$25,#$26,#$27,#$28,#$29,#$2A,#$2B,#$2C,#$2D,#$2E,#$2F,#$30,#$31,#$32,#$33,#$34,#$35,#$36,#$37,#$38,#$39,#$3A,#$3B,#$3C,#$3D,#$3E,#$3F,

'@','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','[','\',']','^','_',
'`','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','{','|','}','~','',       #$80,#$81,#$82,#$83,#$84,#$85,#$86,#$87,#$88,#$89,#$8A,#$8B,#$8C,#$8D,#$8E,#$8F,#$90,#$91,#$92,#$93,#$94,#$95,#$96,#$97,#$98,#$99,#$9A,#$9B,#$9C,#$9D,#$9E,#$9F,#$A0,#$A1,#$A2,#$A3,#$A4,#$A5,#$A6,#$A7,#$A8,#$A9,#$AA,#$AB,#$AC,#$AD,#$AE,#$AF,#$B0,#$B1,#$B2,#$B3,#$B4,#$B5,#$B6,#$B7,#$B8,#$B9,#$BA,#$BB,#$BC,#$BD,#$BE,#$BF,

'À','Á','Â','Ã','Ä','Å','Æ','Ç','È','É','Ê','Ë','Ì','Í','Î','Ï','Ð','Ñ','Ò','Ó','Ô','Õ','Ö','×','Ø','Ù','Ú','Û','Ü','Ý','Þ','ß',
'À','Á','Â','Ã','Ä','Å','Æ','Ç','È','É','Ê','Ë','Ì','Í','Î','Ï','Ð','Ñ','Ò','Ó','Ô','Õ','Ö','÷','Ø','Ù','Ú','Û','Ü','Ý','Þ','ß'
);
const charmapLower:tcharmap=(#$00,#$01,#$02,#$03,#$04,#$05,#$06,#$07,#$08,#$09,#$0A,#$0B,#$0C,#$0D,#$0E,#$0F,#$10,#$11,#$12,#$13,#$14,#$15,#$16,#$17,#$18,#$19,#$1A,#$1B,#$1C,#$1D,#$1E,#$1F,#$20,#$21,#$22,#$23,#$24,#$25,#$26,#$27,#$28,#$29,#$2A,#$2B,#$2C,#$2D,#$2E,#$2F,#$30,#$31,#$32,#$33,#$34,#$35,#$36,#$37,#$38,#$39,#$3A,#$3B,#$3C,#$3D,#$3E,#$3F,

'@','a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','[','\',']','^','_',
'`','a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','{','|','}','~','',       #$80,#$81,#$82,#$83,#$84,#$85,#$86,#$87,#$88,#$89,#$8A,#$8B,#$8C,#$8D,#$8E,#$8F,#$90,#$91,#$92,#$93,#$94,#$95,#$96,#$97,#$98,#$99,#$9A,#$9B,#$9C,#$9D,#$9E,#$9F,#$A0,#$A1,#$A2,#$A3,#$A4,#$A5,#$A6,#$A7,#$A8,#$A9,#$AA,#$AB,#$AC,#$AD,#$AE,#$AF,#$B0,#$B1,#$B2,#$B3,#$B4,#$B5,#$B6,#$B7,#$B8,#$B9,#$BA,#$BB,#$BC,#$BD,#$BE,#$BF,

'á','á','â','ã','ä','å','æ','ç','è','é','ê','ë','ì','í','î','ï','ð','ñ','ò','ó','ô','õ','ö','×','ø','ù','ú','û','ü','ý','þ','ÿ',
'á','á','â','ã','ä','å','æ','ç','è','é','ê','ë','ì','í','î','ï','ð','ñ','ò','ó','ô','õ','ö','÷','ø','ù','ú','û','ü','ý','þ','ÿ'
);
const charmapEnglish:tcharmap=(#$00,#$01,#$02,#$03,#$04,#$05,#$06,#$07,#$08,#$09,#$0A,#$0B,#$0C,#$0D,#$0E,#$0F,#$10,#$11,#$12,#$13,#$14,#$15,#$16,#$17,#$18,#$19,#$1A,#$1B,#$1C,#$1D,#$1E,#$1F,#$20,#$21,#$22,#$23,#$24,#$25,#$26,#$27,#$28,#$29,#$2A,#$2B,#$2C,#$2D,#$2E,#$2F,#$30,#$31,#$32,#$33,#$34,#$35,#$36,#$37,#$38,#$39,#$3A,#$3B,#$3C,#$3D,#$3E,#$3F,

'@','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','[','\',']','^','_',
'`','a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','{','|','}','~','',       #$80,#$81,#$82,#$83,#$84,#$85,#$86,#$87,#$88,#$89,#$8A,#$8B,#$8C,#$8D,#$8E,#$8F,#$90,#$91,#$92,#$93,#$94,#$95,#$96,#$97,#$98,#$99,#$9A,#$9B,#$9C,#$9D,#$9E,#$9F,#$A0,#$A1,#$A2,#$A3,#$A4,#$A5,#$A6,#$A7,#$A8,#$A9,#$AA,#$AB,#$AC,#$AD,#$AE,#$AF,#$B0,#$B1,#$B2,#$B3,#$B4,#$B5,#$B6,#$B7,#$B8,#$B9,#$BA,#$BB,#$BC,#$BD,#$BE,#$BF,

'A','A','A','A','A','A','Æ','Ç','E','E','E','E','I','I','I','I','Ð','Ñ','O','O','O','O','O','×','Ø','U','U','U','U','Ý','Þ','ß',
'a','a','a','a','a','a','æ','ç','e','e','e','e','i','i','i','i','ð','ñ','o','o','o','o','o','÷','ø','u','u','u','u','ý','þ','ÿ'
);
const charmapPascal:tcharmap=('_','_','_','_','_','_','_','_','_',#9,#10,'_','_',#13,'_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_',#$30,#$31,#$32,#$33,#$34,#$35,#$36,#$37,#$38,#$39,#$3A,'_','_','_','_','_',

'_','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','_','_','_','_','_',
'_','a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','_','_','_','_','_',       '_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_','_',

'A','A','A','A','A','A','C','C','E','E','E','E','I','I','I','I','D','N','O','O','O','O','O','_','_','U','U','U','U','Y','T','_',
'a','a','a','a','a','a','c','c','e','e','e','e','i','i','i','i','d','n','o','o','o','o','o','_','_','u','u','u','u','y','t','_'
);
const charmapEnglishUpper:tcharmap=(#$00,#$01,#$02,#$03,#$04,#$05,#$06,#$07,#$08,#$09,#$0A,#$0B,#$0C,#$0D,#$0E,#$0F,#$10,#$11,#$12,#$13,#$14,#$15,#$16,#$17,#$18,#$19,#$1A,#$1B,#$1C,#$1D,#$1E,#$1F,#$20,#$21,#$22,#$23,#$24,#$25,#$26,#$27,#$28,#$29,#$2A,#$2B,#$2C,#$2D,#$2E,#$2F,#$30,#$31,#$32,#$33,#$34,#$35,#$36,#$37,#$38,#$39,#$3A,#$3B,#$3C,#$3D,#$3E,#$3F,

'@','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','[','\',']','^','_',
'`','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','{','|','}','~','',       #$80,#$81,#$82,#$83,#$84,#$85,#$86,#$87,#$88,#$89,#$8A,#$8B,#$8C,#$8D,#$8E,#$8F,#$90,#$91,#$92,#$93,#$94,#$95,#$96,#$97,#$98,#$99,#$9A,#$9B,#$9C,#$9D,#$9E,#$9F,#$A0,#$A1,#$A2,#$A3,#$A4,#$A5,#$A6,#$A7,#$A8,#$A9,#$AA,#$AB,#$AC,#$AD,#$AE,#$AF,#$B0,#$B1,#$B2,#$B3,#$B4,#$B5,#$B6,#$B7,#$B8,#$B9,#$BA,#$BB,#$BC,#$BD,#$BE,#$BF,

'A','A','A','A','A','A','Æ','Ç','E','E','E','E','I','I','I','I','Ð','Ñ','O','O','O','O','O','×','Ø','U','U','U','U','Ý','Þ','ß',
'A','A','A','A','A','A','Æ','Ç','E','E','E','E','I','I','I','I','Ð','Ñ','O','O','O','O','O','÷','ø','U','U','U','U','Ý','Þ','ß'
);
const charmapEnglishLower:tcharmap=(#$00,#$01,#$02,#$03,#$04,#$05,#$06,#$07,#$08,#$09,#$0A,#$0B,#$0C,#$0D,#$0E,#$0F,#$10,#$11,#$12,#$13,#$14,#$15,#$16,#$17,#$18,#$19,#$1A,#$1B,#$1C,#$1D,#$1E,#$1F,#$20,#$21,#$22,#$23,#$24,#$25,#$26,#$27,#$28,#$29,#$2A,#$2B,#$2C,#$2D,#$2E,#$2F,#$30,#$31,#$32,#$33,#$34,#$35,#$36,#$37,#$38,#$39,#$3A,#$3B,#$3C,#$3D,#$3E,#$3F,

'@','a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','[','\',']','^','_',
'`','a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','{','|','}','~','',       #$80,#$81,#$82,#$83,#$84,#$85,#$86,#$87,#$88,#$89,#$8A,#$8B,#$8C,#$8D,#$8E,#$8F,#$90,#$91,#$92,#$93,#$94,#$95,#$96,#$97,#$98,#$99,#$9A,#$9B,#$9C,#$9D,#$9E,#$9F,#$A0,#$A1,#$A2,#$A3,#$A4,#$A5,#$A6,#$A7,#$A8,#$A9,#$AA,#$AB,#$AC,#$AD,#$AE,#$AF,#$B0,#$B1,#$B2,#$B3,#$B4,#$B5,#$B6,#$B7,#$B8,#$B9,#$BA,#$BB,#$BC,#$BD,#$BE,#$BF,

'a','a','a','a','a','a','æ','ç','e','e','e','e','i','i','i','i','ð','ñ','o','o','o','o','o','×','ø','u','u','u','u','ý','þ','ÿ',
'a','a','a','a','a','a','æ','ç','e','e','e','e','i','i','i','i','ð','ñ','o','o','o','o','o','÷','ø','u','u','u','u','ý','þ','ÿ'
);

const charmapEnglishUpperJelekbolSzokoz:tcharmap=(#$00,#$01,#$02,#$03,#$04,#$05,#$06,#$07,#$08,#$09,#$0A,#$0B,#$0C,#$0D,#$0E,#$0F,#$10,#$11,#$12,#$13,#$14,#$15,#$16,#$17,#$18,#$19,#$1A,#$1B,#$1C,#$1D,#$1E,#$1F,#$20,#$21,#$22,#$23,#$24,#$25,#$26,#$27,#$28,#$29,#$2A,#$2B,#$20,#$20,#$20,#$20,#$30,#$31,#$32,#$33,#$34,#$35,#$36,#$37,#$38,#$39,#$3A,#$3B,#$3C,#$3D,#$3E,#$3F,
'@','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','[','\',']','^','_',
'`','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','{','|','}','~','',       #$80,#$81,#$82,#$83,#$84,#$85,#$86,#$87,#$88,#$89,#$8A,#$8B,#$8C,#$8D,#$8E,#$8F,#$90,#$91,#$92,#$93,#$94,#$95,#$96,#$97,#$98,#$99,#$9A,#$9B,#$9C,#$9D,#$9E,#$9F,#$A0,#$A1,#$A2,#$A3,#$A4,#$A5,#$A6,#$A7,#$A8,#$A9,#$AA,#$AB,#$AC,#$AD,#$AE,#$AF,#$B0,#$B1,#$B2,#$B3,#$B4,#$B5,#$B6,#$B7,#$B8,#$B9,#$BA,#$BB,#$BC,#$BD,#$BE,#$BF,

'A','A','A','A','A','A','Æ','Ç','E','E','E','E','I','I','I','I','Ð','Ñ','O','O','O','O','O','×','Ø','U','U','U','U','Ý','Þ','ß',
'A','A','A','A','A','A','Æ','Ç','E','E','E','E','I','I','I','I','Ð','Ñ','O','O','O','O','O','÷','ø','U','U','U','U','Ý','Þ','ß'
);

const charmapReklam:tcharmap=(#$00,#$01,#$02,#$03,#$04,#$05,#$06,#$07,#$08,#$09,#$0A,#$0B,#$0C,#$0D,#$0E,#$0F,#$10,#$11,#$12,#$13,#$14,#$15,#$16,#$17,#$18,#$19,#$1A,#$1B,#$1C,#$1D,#$1E,#$1F,#$20,#$21,#$22,#$23,#$24,#$25,#$26,#$27,#$28,#$29,#$2A,#$2B,#$20,#$2D,#$20,#$20,#$30,#$31,#$32,#$33,#$34,#$35,#$36,#$37,#$38,#$39,#$3A,#$3B,#$3C,#$3D,#$3E,#$3F,
'@','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','[','\',']','^','_',
'`','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','{','|','}','~','',       #$80,#$81,#$82,#$83,#$84,#$85,#$86,#$87,#$88,#$89,#$8A,#$8B,#$8C,#$8D,#$8E,#$8F,#$90,#$91,#$92,#$93,#$94,#$95,#$96,#$97,#$98,#$99,#$9A,#$9B,#$9C,#$9D,#$9E,#$9F,#$A0,#$A1,#$A2,#$A3,#$A4,#$A5,#$A6,#$A7,#$A8,#$A9,#$AA,#$AB,#$AC,#$AD,#$AE,#$AF,#$B0,#$B1,#$B2,#$B3,#$B4,#$B5,#$B6,#$B7,#$B8,#$B9,#$BA,#$BB,#$BC,#$BD,#$BE,#$BF,

'A','A','A','A','A','A','Æ','Ç','E','E','E','E','I','I','I','I','Ð','Ñ','O','O','O','O','O','×','Ø','U','U','U','U','Ý','Þ','ß',
'A','A','A','A','A','A','Æ','Ç','E','E','E','E','I','I','I','I','Ð','Ñ','O','O','O','O','O','÷','ø','U','U','U','U','Ý','Þ','ß'
);
const charmapFilename:tcharmap=(
 '_', '_', '_', '_', '_', '_', '_', '_', '_', '_', '_', '_', '_', '_', '_', '_',
 '_', '_', '_', '_', '_', '_', '_', '_', '_', '_', '_', '_', '_', '_', '_', '_',
 '_',#$21, '_',#$23,#$24,#$25,#$26,#$27,#$28,#$29, '_',#$2B,#$2C,#$2D, #$2E{pont!!!}, '_',
#$30,#$31,#$32,#$33,#$34,#$35,#$36,#$37,#$38,#$39, '_',#$3B, '_',#$3D, '_', '_',
#$40,#$41,#$42,#$43,#$44,#$45,#$46,#$47,#$48,#$49,#$4A,#$4B,#$4C,#$4D,#$4E,#$4F,
#$50,#$51,#$52,#$53,#$54,#$55,#$56,#$57,#$58,#$59,#$5A,#$5B, '_',#$5D,#$5E,#$5F,
#$60,#$61,#$62,#$63,#$64,#$65,#$66,#$67,#$68,#$69,#$6A,#$6B,#$6C,#$6D,#$6E,#$6F,
#$70,#$71,#$72,#$73,#$74,#$75,#$76,#$77,#$78,#$79,#$7A,#$7B, '_',#$7D,#$7E,#$7F,
#$80,#$81,#$82,#$83,#$84,#$85,#$86,#$87,#$88,#$89,#$8A,#$8B,#$8C,#$8D,#$8E,#$8F,
#$90,#$91,#$92,#$93,#$94,#$95,#$96,#$97,#$98,#$99,#$9A,#$9B,#$9C,#$9D,#$9E,#$9F,
#$A0,#$A1,#$A2,#$A3,#$A4,#$A5,#$A6,#$A7,#$A8,#$A9,#$AA,#$AB,#$AC,#$AD,#$AE,#$AF,
#$B0,#$B1,#$B2,#$B3,#$B4,#$B5,#$B6,#$B7,#$B8,#$B9,#$BA,#$BB,#$BC,#$BD,#$BE,#$BF,
#$C0,#$C1,#$C2,#$C3,#$C4,#$C5,#$C6,#$C7,#$C8,#$C9,#$CA,#$CB,#$CC,#$CD,#$CE,#$CF,
#$D0,#$D1,#$D2,#$D3,#$D4,#$D5,#$D6,#$D7,#$D8,#$D9,#$DA,#$DB,#$DC,#$DD,#$DE,#$DF,
#$E0,#$E1,#$E2,#$E3,#$E4,#$E5,#$E6,#$E7,#$E8,#$E9,#$EA,#$EB,#$EC,#$ED,#$EE,#$EF,
#$F0,#$F1,#$F2,#$F3,#$F4,#$F5,#$F6,#$F7,#$F8,#$F9,#$FA,#$FB,#$FC,#$FD,#$FE,#$FF);


var charmapUpperSort:tcharmap;
const charmaplist:array[0..11]of record name:string;map:^TCharMap end=(
(name:'Default';map:@charmapDefault),
(name:'OEM';map:@charmapOEM),
(name:'Upper';map:@charmapUpper),
(name:'Lower';map:@charmapLower),
(name:'English';map:@charmapEnglish),
(name:'Pascal';map:@charmapPascal),
(name:'EnglishUpper';map:@charmapEnglishUpper),
(name:'EnglishLower';map:@charmapEnglishLower),
(name:'EnglishUpperJelekbolSzokoz';map:@charmapEnglishUpperJelekbolSzokoz),
(name:'Reklam';map:@charmapReklam),
(name:'Filename';map:@charmapFilename),
(name:'UpperSort';map:@charmapUpperSort)
);


function sar(a,b:integer):integer;
function sal(a,b:integer):integer;

Function Crc16(data:pointer;len:integer):word;

Function Crc32(data:pointer;len:integer):integer;overload;
Function Crc32(const s:RawByteString):integer;overload;
procedure Crc32Init(var h:Integer);inline;
procedure Crc32Next(var h:Integer;var data;const len:integer);
procedure Crc32NextChar(var h:Integer;const ch:ansichar);
procedure Crc32Finalize(var h:Integer);inline;

Function Crc32UC(data:pointer;len:integer):integer;overload;
Function Crc32UC(const s:RawByteString):integer;overload;
procedure Crc32UCInit(var h:Integer);inline;
procedure Crc32UCNextChar(var h:Integer;const ch:ansichar);
procedure Crc32UCFinalize(var h:Integer);inline;

function Crc32Combine(const c1,c2:integer):integer;

var
  perfOptions:record listDelim,rowDelim:string end=(listDelim:' = ';rowDelim:#13#10);

procedure perfStart(const aname:string);
procedure perfStop;
procedure perfStopStart(const aname:string);
procedure perf(const aname:string);//alias a perfStopStart-ra
function perfReport:string;

function GetLastErrorText:string;
procedure RaiseLastError(const location:string='');

function Range(const min,value,max:Int64):Integer;overload;inline;
function Range(const min,value,max:Integer):Integer;overload;inline;
function Range(const min,value,max:single):Integer;overload;inline;
function Range(const min,value,max:double):Integer;overload;inline;

function Rangerf(const min:Int64;value:Int64;max:Int64):Integer;overload;inline;
function Rangerf(const min:Integer;value:Integer;max:Integer):Integer;overload;inline;
function Rangerf(const min:single;value:single;max:single):single;overload;inline;
function Rangerf(const min:double;value:double;max:double):double;overload;inline;

function Lerp(const a,b:integer;const t:single):integer;overload;inline;
function Lerp(const a,b:int64;const t:double):int64;overload;inline;
function Lerp(const a,b,t:single):single;overload;inline;
function Lerp(const a,b,t:double):double;overload;inline;
function Lerp(const a,b:TPoint;const t:single):TPoint;overload;
function Lerp(const a,b:TRect;const t:single):TRect;overload;

function UnLerp(const a,b,r:single):single;

//function min(const a,b,c:single):single;overload;
//function max(const a,b,c:single):single;overload;

Function StringCmpUpperSort(const a,b:string):Integer;

procedure CharMap(var s:AnsiString;const map:TCharMap);
function CharMapF(const s:AnsiString;const map:TCharMap):Ansistring;

type
  TPosOption=(poIgnoreCase,poBackwards,poReturnEnd,poWholeWords,poExtendedChars{for wholeWords});
  TPosOptions=set of TPosOption;

type TSetOfChar=set of ansichar;
     PSetOfChar=^TSetOfChar;

const wordsetExtended:TSetOfChar=['a'..'z','A'..'Z','0'..'9','_','$','.','#','~'];
      wordsetSimple:TSetOfChar=['a'..'z','A'..'Z','0'..'9','_'];

function Pos(const SubStr,Str:AnsiString;const Options:TPosOptions=[];From:integer=0):integer;overload;

function PosMulti(const SubStr,Str:AnsiString;const Options:TPosOptions=[];const st:integer=1;const en:integer=$7fffffff):TArray<integer>;
function CountPos(const SubStr,Str:AnsiString;const Options:TPosOptions=[];const st:integer=1;const en:integer=$7fffffff):integer;

type
  TReplaceOption=(roIgnoreCase,roBackwards,roWholeWords,roAll);
  TReplaceOptions=set of TReplaceOption;

function Replace(Const SubStr,ReplaceWith:ansistring;Var Str:ansistring;const Options:TReplaceOptions;const From:integer=0):boolean;
function ReplaceF(Const SubStr,ReplaceWith,Str:ansistring;const Options:TReplaceOptions;const From:integer=0):AnsiString;

var ListItemPos,ListItemLength:integer;

procedure LTrim(var result:ansistring);
procedure RTrim(var result:ansistring);
procedure Trim(var result:ansistring);

function LTrimF(const s:ansistring):ansistring;
function RTrimF(const s:ansistring):ansistring;
function TrimF(const s:ansistring):ansistring;

Function UC(const s:ansiString):ansiString;overload;
Function UC(const s:ansiChar):ansiChar;overload;
Function LC(const s:ansiString):ansiString;overload;
Function LC(const s:ansiChar):ansiChar;overload;

Function RightJ(const s:ansiString;n:Integer):ansiString;
Function LeftJ(const s:ansiString;n:Integer):ansiString;
Function CenterJ(const s:ansiString;n:Integer):ansiString;
Function RightStr(const s:ansiString;n:Integer):ansiString;
Function LeftStr(const s:ansiString;n:Integer):ansiString;

function ListCount(const s:ansiString;ListDelimiter:ansichar):integer;
function ListItem(const s:ansiString;n:integer;ListDelimiter:ansichar;dotrim:boolean=true):ansistring;
procedure SetListItem(var s:ansiString;n:integer;const setto:ansiString;ListDelimiter:ansichar);
procedure DelListItem(var s:ansiString;n:integer;ListDelimiter:ansichar);
procedure InsListItem(var s:ansiString;n:integer;const insertthis:ansiString;ListDelimiter:ansichar);
function ListItemRange(const s:ansiString;from,cnt:integer;ListDelimiter:ansichar;withDelim:boolean=true):ansiString;

procedure ListAppend(var list:ansiString;const s:ansiString;const delimiter:ansistring;const distinct:boolean=false);
function ListAppendF(const list:ansiString;const s:ansiString;const delimiter:ansistring;const distinct:boolean=false):ansistring;

function ListFind(const list:ansiString;const s:ansiString;const delimiter:ansichar):integer;
procedure ListAppendNewOnly(var list:ansiString;const s:ansiString;const delimiter:ansistring);

function ListSplit(const s:ansistring;const ListDelimiter:ansichar;const doTrim:boolean=true):TAnsistringarray;
function ListMake(const list:TAnsiStringArray;const ListDelimiter:ansistring;const doTrim:boolean=true):ansistring;

function CharN(const s:ansiString;n:integer):ansichar;inline;

type
  TMagic=array[0..3]of AnsiChar;

function Nearest2NSize(const size:integer):integer;

function RGBLerp(const a,b,Alpha:cardinal):cardinal;
function RGBALerp(const a,b,alpha:cardinal):cardinal;

function RGBMax(const a,b:cardinal):cardinal;
function RGBAMax(const a,b:cardinal):cardinal;
function RGBMin(const a,b:cardinal):cardinal;
function RGBAMin(const a,b:cardinal):cardinal;

procedure pInc(var p);overload;inline;
procedure pDec(var p);overload;inline;
procedure pInc(var p;const incr:integer);overload;inline;
procedure pDec(var p;const decr:integer);overload;inline;

function pSucc(p:pointer):pointer;overload;inline;
function pPred(p:pointer):pointer;overload;inline;
function pSucc(p:pointer;const incr:integer):pointer;overload;inline;
function pPred(p:pointer;const decr:integer):pointer;overload;inline;

function pSub(a,b:pointer):integer;

function pAlignUp(p:pointer;const align:integer):pointer;
function pAlignDown(p:pointer;const align:integer):pointer;

function AlignUp(i:integer;const align:integer):integer;
function AlignDown(i:integer;const align:integer):integer;

function IsWild2(const AWild,AInput:ansistring;out AVariablePart:TAnsiStringArray;const AIgnoreCase: Boolean=true):boolean;overload;
function IsWild2(const AWild,AInput:ansistring;const AIgnoreCase: Boolean=true):boolean;overload;
function IsWild2(const AWild,AInput:ansistring;out AVariablePart0:ansistring;const AIgnoreCase: Boolean=true):boolean;overload;
function IsWild2(const AWild,AInput:ansistring;out AVariablePart0,AVariablePart1:ansistring;const AIgnoreCase: Boolean=true):boolean;overload;
function IsWild2(const AWild,AInput:ansistring;out AVariablePart0,AVariablePart1,AVariablePart2:ansistring;const AIgnoreCase: Boolean=true):boolean;overload;
function IsWild2(const AWild,AInput:ansistring;out AVariablePart0,AVariablePart1,AVariablePart2,AVariablePart3:ansistring;const AIgnoreCase: Boolean=true):boolean;overload;

function IsWild2(const AWild,AInput:ansistring;out AVariablePart0:single;const AIgnoreCase: Boolean=true):boolean;overload;
function IsWild2(const AWild,AInput:ansistring;out AVariablePart0,AVariablePart1:single;const AIgnoreCase: Boolean=true):boolean;overload;
function IsWild2(const AWild,AInput:ansistring;out AVariablePart0,AVariablePart1,AVariablePart2:single;const AIgnoreCase: Boolean=true):boolean;overload;
function IsWild2(const AWild,AInput:ansistring;out AVariablePart0,AVariablePart1,AVariablePart2,AVariablePart3:single;const AIgnoreCase: Boolean=true):boolean;overload;

function FindListItem(const filter:ansistring;const list:ansistring;listDelimiter:ansichar):integer;

procedure Swap(var a,b:variant);overload;inline;
procedure Swap(var a,b:pointer);overload;inline;
procedure Swap(var a,b:integer);overload;inline;
procedure Swap(var a,b:single);overload;inline;
procedure Swap(var a,b:double);overload;inline;
procedure Swap(var a,b:TDateTime);overload;inline;
procedure Swap(var a,b:byte);overload;inline;
procedure Swap(var a,b:AnsiString);overload;
procedure Swap(var a,b:String);overload;
procedure Swap(var a,b:TPoint);overload;inline;

procedure Sort(var a,b:integer);overload;inline;
procedure Sort(var a,b:single);overload;inline;
procedure Sort(var a,b:byte);overload;inline;
procedure Sort(var a,b:ansichar);overload;

function NormalizeRect(const r:TRect):TRect;

procedure IniWrite(const Controls:array of const;const FFileName:string='');
procedure IniRead(const Controls:array of const;const FFileName:string='');

function Indent(const AStr:ansistring;const ACount:integer):ansistring;overload;
function Indent(const ACount:integer):ansistring;overload;

function ToStr(const Value:ansistring):ansistring;overload;
function ToStr(Value:integer):ansistring;overload;
function ToStr(Value:cardinal):ansistring;overload;
function ToStr(Value:int64):ansistring;overload;
function ToStr(const Value:boolean):ansistring;overload;
function ToStr(const Value:TDateTime):ansistring;overload;
function ToStr(const Value:single):ansistring;overload;
function ToStr(const Value:double):ansistring;overload;
function ToStr(const Value:extended):ansistring;overload;
function ToStr(const P:TPoint):ansistring;overload;
function ToStr(const R:TRect):ansistring;overload;
function ToStr(const V:TArray<integer>):ansistring;overload;
function ToStr(const V:variant):ansistring;overload;

function ToPas(const s:ansistring;const SplitLines:integer=0):ansistring;overload;
function ToPas(const v:integer):ansistring;overload;
function ToPas(const v:int64):ansistring;overload;
function ToPas(const v:single):ansistring;overload;
function ToPas(const v:double):ansistring;overload;
function ToPas(const v:extended):ansistring;overload;
function TimeToPas(const v:TTime;const full:boolean):ansistring;overload;
function DateToPas(const v:TDate):ansistring;overload;
function DateTimeToPas(const v:TDateTime;const full:boolean):ansistring;overload;
function VariantToPas(const V:Variant;const SplitLines:integer=0):ansistring;overload;


function ToSql(const src:ansistring):ansistring;

function ToExtendedDef(const s:ansistring;const Default:extended=0):extended;
function ToDoubleDef(const s:ansistring;const Default:double=0):Double;
function ToSingleDef(const s:ansistring;const Default:single=0):Single;
function ToIntDef(const s:ansistring;const Default:integer=0):integer;
function ToInt64Def(const s:ansistring;const Default:int64=0):int64;
function ToCardinalDef(const s:ansistring;const Default:cardinal=0):cardinal;
function ToBooleanDef(const s:ansistring;const Default:boolean=false):boolean;

var
  NullAsAnsiStringValue:ansistring='';

//function VarToAnsiStr(const V:variant):ansistring;

type
  IAnsiStringBuilder=interface
    procedure AddBlock(var AData;const ALen:integer);
    procedure AddStr(const s:ansistring);
    procedure AddLine(const s:ansistring);
    procedure AddChar(const ch:AnsiChar);
    procedure AddStrAfterPrevLine(s:ansistring);
    procedure DeleteLastChar;
    function GetLen:integer;
    procedure Finalize;
  end;

  TAnsiStringBuilder=class(TInterfacedObject,IAnsiStringBuilder)
  private
    PStr:PAnsiString;
    FLen:integer;
  public
    constructor Create(var AStr:AnsiString);
    procedure AddBlock(var AData;const ALen:integer);
    procedure AddStr(const s:ansistring);
    procedure AddLine(const s:ansistring);
    procedure AddChar(const ch:AnsiChar);
    procedure AddStrAfterPrevLine(s:ansistring);
    procedure DeleteLastChar;
    function GetLen:integer;
    procedure Finalize;
    destructor Destroy;override;
  end;

  IUnicodeStringBuilder=interface
    procedure AddStr(const s:UnicodeString);
    procedure AddLine(const s:UnicodeString);
    procedure AddChar(const ch:WideChar);
    procedure Finalize;
  end;

  TUnicodeStringBuilder=class(TInterfacedObject,IUnicodeStringBuilder)
  private
    PStr:PUnicodeString;
    Len:integer;
    procedure AddBlock(var AData;const ALenInWords:integer);
  public
    constructor Create(var AStr:UnicodeString);
    procedure AddStr(const s:UnicodeString);
    procedure AddLine(const s:UnicodeString);
    procedure AddChar(const ch:WideChar);
    procedure Finalize;
    destructor Destroy;override;
  end;

function AnsiStringBuilder(var s:AnsiString;const Clear:boolean=false):IAnsiStringBuilder;
function UnicodeStringBuilder(var s:UnicodeString;const Clear:boolean=false):IUnicodeStringBuilder;

function AutoFree(const AObject:TObject):IUnknown;

function switch(const b:Boolean;const t:ansistring;const f:ansistring=''):ansistring;overload;
function switch(const b:Boolean;const t:string    ;const f:string    =''):string;overload;
function switch(const b:Boolean;const t:integer   ;const f:integer   =0 ):integer;overload;
function switch(const b:Boolean;const t:cardinal  ;const f:cardinal  =0 ):cardinal;overload;
function switch(const b:Boolean;const t:single    ;const f:single    =0 ):single;overload;
function switch(const b:Boolean;const t:boolean   ;const f:boolean   =false):boolean;overload;

type
  TRawStream = class(TStream)
  private
    FDataString: RawByteString;
    FPosition: Integer;
  protected
    procedure SetSize(NewSize: Longint); override;
  public
    constructor Create(const AString: rawByteString);
    function Read(var Buffer; Count: Longint): Longint; override;
    function ReadString(Count: Longint): rawbytestring;
    function Seek(Offset: Longint; Origin: Word): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    procedure WriteString(const AString: rawByteString);
    property DataString: rawByteString read FDataString;

    property Position:integer read FPosition;
  end;

function ChkChanged(const act:boolean;var last:boolean):boolean;overload;

function ChkPressed(const act:boolean;var last:boolean):boolean;
function ChkReleased(const act:boolean;var last:boolean):boolean;

function ComputerName:ansistring;

function Remap(const src,srcFrom,srcTo,dstFrom,dstTo:single):single;overload;
function RemapClamp(const src,srcFrom,srcTo,dstFrom,dstTo:single):single;
function Remap(const p:TPoint;const rSrc,rDst:TRect):TPoint;overload;
function Remap(const r,rSrc,rDst:TRect):TRect;overload;

function CmdLineParam(const Param:String):string;

function AppPath:string;

function HungarianAnsiToUnicode(const s:ansistring):UnicodeString;
function HungarianUnicodeToAnsi(s:UnicodeString):ansistring;

procedure Ranger(const a:integer;var b:integer;const c:integer);

procedure SafeLog(const s:ansistring);

var safelogEnabled:boolean=false;

function HotVKeyToStr(const HK:integer):ansistring;
function ToHotVKey(name:ansistring):integer;overload;
function ToHotVKey(const Key:integer;const Shift:TShiftState):integer;overload;

const
  clVgaBlack            =$000000;
  clVgaDarkGray         =$555555;
  clVgaLowBlue          =$AA0000;
  clVgaHighBlue         =$FF5555;
  clVgaLowGreen         =$00AA00;
  clVgaHighGreen        =$55FF55;
  clVgaLowCyan          =$AAAA00;
  clVgaHighCyan         =$FFFF55;
  clVgaLowRed           =$0000AA;
  clVgaHighRed          =$5555FF;
  clVgaLowMagenta       =$AA00AA;
  clVgaHighMagenta      =$FF55FF;
  clVgaBrown            =$0055AA;
  clVgaYellow           =$55FFFF;
  clVgaLightGray        =$AAAAAA;
  clVgaWhite            =$FFFFFF;

  clVga:array[0..15]of integer=(
    clVgaBlack,clVgaLowBlue,clVgaLowGreen,clVgaLowCyan,clVgaLowRed,clVgaLowMagenta,clVgaBrown,clVgaLightGray,
    clVgaDarkGray,clVgaHighBlue,clVgaHighGreen,clVgaHighCyan,clVgaHighRed,clVgaHighMagenta,clVgaYellow,clVgaWhite);

  clC64Black                     =$000000;
  clC64White                     =$FFFFFF;
  clC64Red                       =$354374;
  clC64Cyan                      =$BAAC7C;
  clC64Purple                    =$90487B;
  clC64Green                     =$4F9764;
  clC64Blue                      =$853240;
  clC64Yellow                    =$7ACDBF;
  clC64Orange                    =$2F5B7B;
  clC64Brown                     =$00454f;
  clC64Pink                      =$6572a3;
  clC64DGrey                     =$505050;
  clC64Grey                      =$787878;
  clC64LGreen                    =$8ed7a4;
  clC64LBlue                     =$bd6a78;
  clC64LGrey                     =$9f9f9f;

  clC64:array[0..15]of integer=(clC64Black,clC64White,clC64Red,clC64Cyan,clC64Purple,clC64Green,
    clC64Blue,clC64Yellow,clC64Orange,clC64Brown,clC64Pink,clC64DGrey,clC64Grey,clC64LGreen,clC64LBlue,
    clC64LGrey);

  clWowGrey             =$9d9d9d;
  clWowWhite            =$ffffff;
  clWowGreen            =$00ff1e;
  clWowBlue             =$dd7000;
  clWowPurple           =$ee35a3;
  clWowRed              =$0080ff;
  clWowRed2             =$80cce5;

  clWow:array[0..6]of integer=(clWowGrey,clWowWhite,clWowGreen,clWowBlue,clWowPurple,clWowRed,clWowRed2);

function CountBitsOld(i:integer):integer;
function CountBits(i:integer):integer;overload;
function CountBits(i:int64):integer;overload;

//function FindListItem(const filter:ansistring;const list:ansistring;listDelimiter:ansichar):integer;

type
  TMouseState=class(TComponent)
  private
    FOldMouseDown,FOldMouseUp:TMouseEvent;
    FOldMouseMove:TMouseMoveEvent;
    FOldMouseWheel:TMouseWheelEvent;
//    FOldMouseWheelUp,FOldMouseWheelDown:TMouseWheelUpDownEvent;

    FOnChange:TNotifyEvent;
    procedure MyMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure MyMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure MyMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure MyMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
//    procedure MyMouseWheelDown(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
//    procedure MyMouseWheelUp(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
  public
    Act,Last,Pressed:record
      Button:TMouseButton;
      Shift:TShiftState;
      Screen:tpoint;
      Wheel:integer;
    end;
    Delta,Hover,HoverMax:record
      Screen:TPoint;
      Wheel:integer;
    end;
    justPressed,JustReleased:boolean;
    constructor Create(AOwner:TComponent);override;
    destructor Destroy;override;
    procedure Update(const shift:TShiftState;const X,Y:integer;const WD:integer=0);
    property OnChange:TNotifyEvent read FOnChange write FOnChange;
  end;

function FindBetween(const s,st,en:ansistring;const actpos:pinteger=nil;const startpos:pinteger=nil):ansistring;
function ReplaceBetween(var s:ansistring;st,en,replacewith:ansistring;const from:integer=1):boolean;

type
  THetThread=class;
  THetThreadProc=reference to procedure(thrd:THetThread);
  THetThread=class(TComponent)
  private
    type TMyThread=class(TThread)
    public
      FHetThread:THetThread;
      TLast:int64;
      procedure CallSynchProc;
      procedure Execute;override;
      constructor Create(AOwner:THetThread);
      destructor Destroy;override;
    end;
  private
    FThreadProc:THetThreadProc;
    FThread:TMyThread;
    FSynchProc:TProc;
    FInterval_ms:single;//millisec-ben
  public
    constructor Create(AOwner:TComponent;AInterval_ms:single;AProc:THetThreadProc);reintroduce;
    destructor Destroy;override;
    property Interval_ms:single read FInterval_ms write FInterval_ms;
    procedure Synchronize(const AProc:TProc);
    procedure Terminate;
    function Terminated:boolean;
    property Thread:TMyThread read FThread;
  end;

function Unescape(const s:ansistring):ansistring;
function Escape(const s:ansistring):ansistring;

type
  TOnIdleProc=reference to procedure(var Done:boolean);
  TOnIdle=class(TComponent)
  private
    FProc1:TProc;
    FProc2:TOnIdleProc;
  public
    constructor Create(const AOwner:TComponent);reintroduce;
    destructor Destroy;override;
  end;

function OnIdle(const AOwner:TComponent;const AProc:TProc):TOnIdle;overload;
function OnIdle(const AOwner:TComponent;const AProc:TOnIdleProc):TOnIdle;overload;
procedure OnIdleRemove(const AOwner:TComponent);

type
  TRectAlignment=record
    hAlign,vAlign:integer;
    hShrink,vShrink,hEnlarge,vEnlarge,proportional:boolean;
  end;

function DecodeRectAlignment(const def:ansistring):TRectAlignment;
function AlignRect(const rImage,rCanvas:TRect;const RectAlignment:TRectAlignment):TRect;overload;
function AlignRect(const rImage,rCanvas:TRect;const RectAlignment:ansistring):TRect;overload;

function MyDateToStr(const date:TDateTime):ansistring;
function MyStrToDate(const s:ansistring):TDateTime;
function MyTimeToStr(const time:TDateTime):ansistring;
function MyStrToTime(const str:ansistring):TDateTime;

function CheckAndClear(var b:boolean):boolean;inline;
function CheckAndSet(var b:boolean):boolean;overload;
function CheckAndSet(var b:boolean;const bnew:boolean):boolean;overload;
function CheckAndSet(var b:integer;const bnew:integer):boolean;overload;
function CheckAndSet(var b:single;const bnew:single):boolean;overload;
function CheckAndSet(var s:ansistring;const s2:ansistring):boolean;overload;overload;

type
  TCustomFormHelper=class helper for TCustomForm
  public
    function GetFullScreen:boolean;
    procedure SetFullScreen(const Value:boolean);
    property FullScreen:boolean read GetFullScreen write SetFullScreen;
    procedure ToggleFullScreen;

    function GetWindowPlacement:AnsiString;
    procedure SetWindowPlacement(const Value:AnsiString);
    property WindowPlacement:ansistring read GetWindowPlacement write SetWindowPlacement;
  end;

type
  TDeltaTime=record
    Delta:double;
    tLast,tFreq:int64;
    _check:integer;
    procedure Start;
    function Update:double;
    function SecStr:ansistring;
    function MilliSecStr:ansistring;
    function MicroSecStr:ansistring;
    function NanoSecStr:ansistring;
  end;

function StrToHexDump(const src:ansistring):ansistring;

function ClassIs(const a,b:TClass):boolean;

type
  TControlHelper=class helper for TControl
  public
    function ClientToScreen(const r:TRect):TRect;overload;
  end;

function BinToHex(const s:rawbytestring):rawbytestring;overload;
function HexToBin(const s:rawbytestring):rawbytestring;overload;

function Num2Roman(n:integer):ansistring;
function Num2Hun(n:integer):ansistring;
function Nevelo(const s:ansistring;nagybetuvel:boolean=false):ansistring;

function Exec(const cmd,path:string;const hidden:boolean):integer;

procedure ParalellFor(const st,en:integer;const proc:TProc<integer>);
procedure LaunchThread(const proc:TProc);

function RandomF:single;{-1..1}
procedure RandomGaussPair(out y1,y2:single);
function RandomGauss:single;{-1..1}

type
  TMyPoint=record
    x,y:integer;
    class operator implicit(const a:TPoint):TMyPoint;
    class operator implicit(const a:TMyPoint):TPoint;
    class operator negative(const a:TMyPoint):TMyPoint;
    class operator add(const a,b:TMyPoint):TMyPoint;
    class operator subtract(const a,b:TMyPoint):TMyPoint;
    class operator multiply(const a,b:TMyPoint):TMyPoint;
    class operator multiply(const a:TMyPoint;const b:single):TMyPoint;
    class operator divide(const a,b:TMyPoint):TMyPoint;
    class operator divide(const a:TMyPoint;const b:single):TMyPoint;
    class operator intdivide(const a:TMyPoint;const b:integer):TMyPoint;
    class operator leftShift(const a:TMyPoint;const b:integer):TMyPoint;
    class operator rightShift(const a:TMyPoint;const b:integer):TMyPoint;

    class operator add(const a:TRect;const b:TMyPoint):TRect;
    class operator subtract(const a:TRect;const b:TMyPoint):TRect;

    class operator in(const a:TMyPoint;const b:TRect):boolean;
    class operator Equal(const a,b:TMyPoint):boolean;
    class operator NotEqual(const a,b:TMyPoint):boolean;
  end;

function Pt(const x,y:Integer):TMyPoint;overload;
function Pt(const a:TPoint):TMyPoint;overload;

function GetHddSerial: AnsiString;
function CanGetHddSerial(Prepare: Boolean): Integer;

function TryStrToIntArray(const sa:TArray<AnsiString>;out ia:TArray<integer>):boolean;

function WordAt(const n:ansistring;p:integer;const extendedChars:boolean=true):ansistring;
var WordStart,WordLen:integer;

function MessageBox(const Text, Caption: String; Flags: Longint): Integer;

function RTrimLines(const s:ansistring):ansistring;

function StrMake(const ASrc:pointer;const ALen:integer):AnsiString;overload;
function StrMake(const ASrc,AEnd:pointer):AnsiString;overload;

function StrMul(const Src:ansistring;const count:integer):ansistring;overload;

function ByteOrderSwap(const A: Cardinal): Cardinal; overload;
function ByteOrderSwap(const A: integer): integer; overload;
function ByteOrderSwap(const A: word): word; overload;
function ByteOrderSwap(const A: smallint): smallint; overload;

function ROL(const a,b:cardinal):cardinal;
function ROR(const a,b:cardinal):cardinal;

type
  TSystem_Basic_Information = packed record
    dwUnknown1: DWORD;
    uKeMaximumIncrement: ULONG;
    uPageSize: ULONG;
    uMmNumberOfPhysicalPages: ULONG;
    uMmLowestPhysicalPage: ULONG;
    uMmHighestPhysicalPage: ULONG;
    uAllocationGranularity: ULONG;
    pLowestUserAddress: Pointer;
    pMmHighestUserAddress: Pointer;
    uKeActiveProcessors: ULONG;
    bKeNumberProcessors: byte;
    bUnknown2: byte;
    wUnknown3: word;
  end;

function SysInfo:TSystem_Basic_Information;

//c++ compatibility stuff
procedure printf(const s:string;const Args:array of const);overload;
procedure printf(const s:string;const v0,v1,v2,v3,v4,v5:variant);overload;
procedure printf(const s:string;const v0,v1,v2,v3,v4:variant);overload;
procedure printf(const s:string;const v0,v1,v2,v3:variant);overload;
procedure printf(const s:string;const v0,v1,v2:variant);overload;
procedure printf(const s:string;const v0,v1:variant);overload;
procedure printf(const s:string;const v0:variant);overload;
procedure printf(const s:string);overload;

function HammingDist(const a,b:integer):integer;

type
  TIA=TIntegerArray;
  TSA=TAnsiStringArray;

procedure IntArrayDecGreaterValues(var a:tia;r:integer);//az r-nel nagyobbakat csokkenti
procedure CopyIntArray(var s,d:tia);
procedure InsIntArray(var a:tia;pos:integer;b:integer);
procedure InsStrArray(var a:tsa;pos:integer;const b:ansistring);
procedure SortIntArray(var a:tia);
procedure AddIntArray(var a:tia;b:integer);
procedure AddIntArrayNoCheck(var a:tia;b:integer);
procedure DelIntArrayValue(var a:tia;b:integer);
procedure DelIntArray(var a:tia;b:integer);
procedure ToggleIntArray(var a:tia;b:integer);
function FindIntArray(const a:tia;b:integer):integer;
function FindStrArray(const a:tsa;b:ansistring):integer;
procedure StrToIntArray(const s:ansistring;var a:tia;separ:ansichar);

procedure AddStrArray(var a:tsa;const b:ansistring);
procedure AddStrArrayNoCheck(var a:tsa;const b:ansistring);
procedure SortStrArray(var a:tsa);
procedure DistinctStrArray(var a:tsa;const doSort:boolean);
function FindBinStrArray(const a:tsa;const s:ansistring):integer;
function FindBinIntArray(const a:tia;const s:integer):integer;

function vec_sel(const selZero,selOne,sel:integer):integer;overload;

function postInc(var i:integer):integer;overload;inline;
function postDec(var i:integer):integer;overload;inline;
function postInc(var i:integer;const n:integer):integer;overload;inline;
function postDec(var i:integer;const n:integer):integer;overload;inline;

function postInc(var i:cardinal):cardinal;overload;inline;
function postDec(var i:cardinal):cardinal;overload;inline;
function postInc(var i:cardinal;const n:integer):cardinal;overload;inline;
function postDec(var i:cardinal;const n:integer):cardinal;overload;inline;

function postInc(var i:byte):byte;overload;inline;

function ValidEmail(email:ansistring): boolean;

function DataToStr(const Data;const Size:integer):RawByteString;
procedure StrToData(const s:RawByteString;var Data;const Size:integer=0; const fillZero:boolean=true);

function FourCC(const a:integer):ansistring;overload;
function FourCC(const a:cardinal):ansistring;overload;
function FourCC(const a:ansistring):ansistring;overload;

//Fast move for data bigger than >chachesize
procedure FastMove(const src;var dst;size:integer);
function _TestFastMove:ansistring;

function BrowseForFolder(var Foldr: string; Title: string): Boolean;

function UMod(const i,j:integer):integer;

function BeginsWith(const str,beginning:string;const CaseInsens:boolean=true):boolean;
function EndsWith(const str,ending:string;const CaseInsens:boolean=true):boolean;

////////////////////////////////////////////////////////////////////////////////
///  FileSys                                                                 ///
////////////////////////////////////////////////////////////////////////////////

function ZCompress(const src:RawByteString):RawByteString;
function ZDecompress(const src:RawByteString):RawByteString;

type
  SearchPath=class
  public
    class var Paths:TArray<string>;
    class procedure Add(const APath:string);
    class procedure Remove(const APath:string);
    class procedure Push(const APath:string);
    class function Peek:string;
    class function Pop:string;
    class function DstPath:string;
    class procedure Clear;
  end;

  IFileHandler=interface
    function Supports(const fn:String):boolean;
    function Exists(const fn:String):boolean;
    function Read(const fn:String;const MustExists:boolean):RawByteString;
    procedure Write(const fn:String;const data:RawByteString);
  end;

  TFile=record
  strict private
    FFileName:ansistring;
  public
    class operator explicit(const fn:string):TFile;
    class operator implicit(const f:TFile):rawbytestring;//read
    function Read(const MustExists:boolean=false):rawbytestring;
    procedure Write(const d:RawByteString);
    function Exists:boolean;
    function FullName:String;
  end;

function FindFileExt(const AFileName:string;const AExtensionList:AnsiString=''):string;

procedure RegisterFileHandler(const AHandler:IFileHandler);

function ExpandFileNameForWrite(const AFileName:string):string;
function ExpandFileNameForRead(const AFileName:string):string;

Procedure CreateDirForFile(const FN:ansiString);

////////////////////////////////////////////////////////////////////////////////

function SwapRB(c:TColor):TColor;

procedure Inc2(var a:single;const b:single=0);overload;

function QPF:int64;
function QPC:int64;
function QPS:double;

procedure PInvoke(const AProc:TProc);

function SgnSqr(const x:single):single;

type TRawFindBinaryFunct=reference to function(const item):integer;
function RawFindBinary(const list;const length,stride,offset:integer;const F:TRawFindBinaryFunct;out AIdx:integer):boolean;

function ToSeconds(const dt:TDateTime):double;

function umul64(const a,b:cardinal):int64;

function GetFileLastWriteTime(const AFileName:ansistring):int64;
procedure SetFileLastWriteTime(const AFileName:ansistring;const ATime:int64);

function GetFileCreationTime(const AFileName:ansistring):int64;
procedure SetFileCreationTime(const AFileName:ansistring;const ATime:int64);

procedure GetFileInfo(const AFileName:ansistring;out cre,acc,wri:int64;out attr:cardinal);
procedure SetFileInfo(const AFileName:ansistring;const cre,acc,wri:int64;const attr:cardinal);

function Bitmap2Icon(Bitmap: TBitmap; TransparentColor: TColor): TIcon;

////////////////////////////////////////////////////////////////////////////////
/// SSE stuff

type TSSEVersion=(SSENone,SSE1,SSE2,SSE3,SSE4_1);

var SSEVersion:TSSEVersion=SSENone;

const
  SHUFFLE_0000=0;SHUFFLE_1000=1;SHUFFLE_2000=2;SHUFFLE_3000=3;SHUFFLE_0100=4;SHUFFLE_1100=5;SHUFFLE_2100=6;SHUFFLE_3100=7;  SHUFFLE_0200=8;SHUFFLE_1200=9;SHUFFLE_2200=10;SHUFFLE_3200=11;SHUFFLE_0300=12;SHUFFLE_1300=13;SHUFFLE_2300=14;SHUFFLE_3300=15;  SHUFFLE_0010=16;SHUFFLE_1010=17;SHUFFLE_2010=18;SHUFFLE_3010=19;SHUFFLE_0110=20;SHUFFLE_1110=21;SHUFFLE_2110=22;SHUFFLE_3110=23;  SHUFFLE_0210=24;SHUFFLE_1210=25;SHUFFLE_2210=26;SHUFFLE_3210=27;SHUFFLE_0310=28;SHUFFLE_1310=29;SHUFFLE_2310=30;SHUFFLE_3310=31;
  SHUFFLE_0020=32;SHUFFLE_1020=33;SHUFFLE_2020=34;SHUFFLE_3020=35;SHUFFLE_0120=36;SHUFFLE_1120=37;SHUFFLE_2120=38;SHUFFLE_3120=39;  SHUFFLE_0220=40;SHUFFLE_1220=41;SHUFFLE_2220=42;SHUFFLE_3220=43;SHUFFLE_0320=44;SHUFFLE_1320=45;SHUFFLE_2320=46;SHUFFLE_3320=47;  SHUFFLE_0030=48;SHUFFLE_1030=49;SHUFFLE_2030=50;SHUFFLE_3030=51;SHUFFLE_0130=52;SHUFFLE_1130=53;SHUFFLE_2130=54;SHUFFLE_3130=55;  SHUFFLE_0230=56;SHUFFLE_1230=57;SHUFFLE_2230=58;SHUFFLE_3230=59;SHUFFLE_0330=60;SHUFFLE_1330=61;SHUFFLE_2330=62;SHUFFLE_3330=63;
  SHUFFLE_0001=64;SHUFFLE_1001=65;SHUFFLE_2001=66;SHUFFLE_3001=67;SHUFFLE_0101=68;SHUFFLE_1101=69;SHUFFLE_2101=70;SHUFFLE_3101=71;  SHUFFLE_0201=72;SHUFFLE_1201=73;SHUFFLE_2201=74;SHUFFLE_3201=75;SHUFFLE_0301=76;SHUFFLE_1301=77;SHUFFLE_2301=78;SHUFFLE_3301=79;  SHUFFLE_0011=80;SHUFFLE_1011=81;SHUFFLE_2011=82;SHUFFLE_3011=83;SHUFFLE_0111=84;SHUFFLE_1111=85;SHUFFLE_2111=86;SHUFFLE_3111=87;  SHUFFLE_0211=88;SHUFFLE_1211=89;SHUFFLE_2211=90;SHUFFLE_3211=91;SHUFFLE_0311=92;SHUFFLE_1311=93;SHUFFLE_2311=94;SHUFFLE_3311=95;
  SHUFFLE_0021=96;SHUFFLE_1021=97;SHUFFLE_2021=98;SHUFFLE_3021=99;SHUFFLE_0121=100;SHUFFLE_1121=101;SHUFFLE_2121=102;SHUFFLE_3121=103;  SHUFFLE_0221=104;SHUFFLE_1221=105;SHUFFLE_2221=106;SHUFFLE_3221=107;SHUFFLE_0321=108;SHUFFLE_1321=109;SHUFFLE_2321=110;SHUFFLE_3321=111;  SHUFFLE_0031=112;SHUFFLE_1031=113;SHUFFLE_2031=114;SHUFFLE_3031=115;SHUFFLE_0131=116;SHUFFLE_1131=117;SHUFFLE_2131=118;SHUFFLE_3131=119;  SHUFFLE_0231=120;SHUFFLE_1231=121;SHUFFLE_2231=122;SHUFFLE_3231=123;SHUFFLE_0331=124;SHUFFLE_1331=125;SHUFFLE_2331=126;SHUFFLE_3331=127;
  SHUFFLE_0002=128;SHUFFLE_1002=129;SHUFFLE_2002=130;SHUFFLE_3002=131;SHUFFLE_0102=132;SHUFFLE_1102=133;SHUFFLE_2102=134;SHUFFLE_3102=135;  SHUFFLE_0202=136;SHUFFLE_1202=137;SHUFFLE_2202=138;SHUFFLE_3202=139;SHUFFLE_0302=140;SHUFFLE_1302=141;SHUFFLE_2302=142;SHUFFLE_3302=143;  SHUFFLE_0012=144;SHUFFLE_1012=145;SHUFFLE_2012=146;SHUFFLE_3012=147;SHUFFLE_0112=148;SHUFFLE_1112=149;SHUFFLE_2112=150;SHUFFLE_3112=151;  SHUFFLE_0212=152;SHUFFLE_1212=153;SHUFFLE_2212=154;SHUFFLE_3212=155;SHUFFLE_0312=156;SHUFFLE_1312=157;SHUFFLE_2312=158;SHUFFLE_3312=159;
  SHUFFLE_0022=160;SHUFFLE_1022=161;SHUFFLE_2022=162;SHUFFLE_3022=163;SHUFFLE_0122=164;SHUFFLE_1122=165;SHUFFLE_2122=166;SHUFFLE_3122=167;  SHUFFLE_0222=168;SHUFFLE_1222=169;SHUFFLE_2222=170;SHUFFLE_3222=171;SHUFFLE_0322=172;SHUFFLE_1322=173;SHUFFLE_2322=174;SHUFFLE_3322=175;  SHUFFLE_0032=176;SHUFFLE_1032=177;SHUFFLE_2032=178;SHUFFLE_3032=179;SHUFFLE_0132=180;SHUFFLE_1132=181;SHUFFLE_2132=182;SHUFFLE_3132=183;  SHUFFLE_0232=184;SHUFFLE_1232=185;SHUFFLE_2232=186;SHUFFLE_3232=187;SHUFFLE_0332=188;SHUFFLE_1332=189;SHUFFLE_2332=190;SHUFFLE_3332=191;
  SHUFFLE_0003=192;SHUFFLE_1003=193;SHUFFLE_2003=194;SHUFFLE_3003=195;SHUFFLE_0103=196;SHUFFLE_1103=197;SHUFFLE_2103=198;SHUFFLE_3103=199;  SHUFFLE_0203=200;SHUFFLE_1203=201;SHUFFLE_2203=202;SHUFFLE_3203=203;SHUFFLE_0303=204;SHUFFLE_1303=205;SHUFFLE_2303=206;SHUFFLE_3303=207;  SHUFFLE_0013=208;SHUFFLE_1013=209;SHUFFLE_2013=210;SHUFFLE_3013=211;SHUFFLE_0113=212;SHUFFLE_1113=213;SHUFFLE_2113=214;SHUFFLE_3113=215;  SHUFFLE_0213=216;SHUFFLE_1213=217;SHUFFLE_2213=218;SHUFFLE_3213=219;SHUFFLE_0313=220;SHUFFLE_1313=221;SHUFFLE_2313=222;SHUFFLE_3313=223;
  SHUFFLE_0023=224;SHUFFLE_1023=225;SHUFFLE_2023=226;SHUFFLE_3023=227;SHUFFLE_0123=228;SHUFFLE_1123=229;SHUFFLE_2123=230;SHUFFLE_3123=231;  SHUFFLE_0223=232;SHUFFLE_1223=233;SHUFFLE_2223=234;SHUFFLE_3223=235;SHUFFLE_0323=236;SHUFFLE_1323=237;SHUFFLE_2323=238;SHUFFLE_3323=239;  SHUFFLE_0033=240;SHUFFLE_1033=241;SHUFFLE_2033=242;SHUFFLE_3033=243;SHUFFLE_0133=244;SHUFFLE_1133=245;SHUFFLE_2133=246;SHUFFLE_3133=247;  SHUFFLE_0233=248;SHUFFLE_1233=249;SHUFFLE_2233=250;SHUFFLE_3233=251;SHUFFLE_0333=252;SHUFFLE_1333=253;SHUFFLE_2333=254;SHUFFLE_3333=255;

type
  TAlignedBuffer=record
    _internalData:TBytes;
    Address:pointer;
    function Alloc(const length,align:integer):pointer;
  end;

  TSSEReg=packed record
    procedure SetB(const b0:integer);overload;
    procedure SetB(const b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,b10,b11,b12,b13,b14,b15:integer);overload;
    procedure SetW(const w0:integer);overload;
    procedure SetW(const w0,w1,w2,w3,w4,w5,w6,w7:integer);overload;
    procedure SetDW(const dw0:integer);overload;
    procedure SetDW(const dw0,dw1,dw2,dw3:integer);overload;
    procedure SetQW(const qw0:int64);overload;
    procedure SetQW(const qw0,qw1:int64);overload;
    procedure SetF(const f0:single);overload;
    procedure SetF(const f0,f1,f2,f3:single);overload;
    procedure SetD(const d0:double);overload;
    procedure SetD(const d0,d1:double);overload;
  case integer of
    0:(B:array[0..15]of byte);
    1:(W:array[0..7]of word);
    2:(DW:array[0..3]of cardinal);
    4:(QW:array[0..1]of int64);
    5:(F:array[0..3]of single);
    6:(D:array[0..1]of double);
  end;

////////////////////////////////////////////////////////////////////////////////

function NewLineCorrect(const s:ansistring):ansistring;

function umul24_hi(a,b:cardinal):cardinal;
function umul24_lo(a,b:cardinal):cardinal;
function umul_hi(a,b:cardinal):cardinal;

function BFE(const value,bitofs,size:cardinal):cardinal;
function BFI(const value,bitOfs,size,ins:cardinal):cardinal;

//function min(a,b:cardinal):cardinal;overload;
//function max(a,b:cardinal):cardinal;overload;
//function max3(a,b,c:cardinal):cardinal;overload;

function min(a,b:integer):integer;
function max(a,b:integer):integer;

procedure minimize(var a:integer;b:integer);
procedure maximize(var a:integer;b:integer);

function minf(a,b:single):single;
function maxf(a,b:single):single;

function IsIdentifier(const s:ansistring):boolean;

function GetCurrentProcessorNumber:integer;

function LoadSingleArray(const fn:string):TArray<single>;
procedure SaveSingleArray(const fn:string;const a:TArray<single>);

procedure ComplexMul(const a,b,c,d:single;out r,i:single); //r0,i0,r1,i1
procedure ComplexMAD(const a,b,c,d:single;var r,i:single); //r0,i0,r1,i1
function SingleArrayZeroes(const len:integer):TArray<single>;
function IntArrayZeroes(const len:integer):TArray<integer>;

procedure Append(var f:text);overload; //just call original
procedure Append(var A:TArray<single>;const B:TArray<single>);overload;
procedure Append(var A:TArray<integer>;const B:TArray<integer>);overload;

function Copy(const A:string;const ofs:integer;const len:integer=maxint):string;overload;
function Copy(const A:ansistring;const ofs:integer;const len:integer=maxint):ansistring;overload;
function Copy(const A:Rawbytestring;const ofs:integer;const len:integer=maxint):rawbytestring;overload;
function Copy(const A:TArray<single>;const ofs:integer;const len:integer=maxint):TArray<single>;overload;
function Copy(const A:TArray<integer>;const ofs:integer;const len:integer=maxint):TArray<integer>;overload;

procedure Delete(var A:string;const ofs:integer;const len:integer=maxint);overload;
procedure Delete(var A:ansistring;const ofs:integer;const len:integer=maxint);overload;
procedure Delete(var A:Rawbytestring;const ofs:integer;const len:integer=maxint);overload;
procedure Delete(var A:TArray<single>;const ofs:integer;const len:integer=maxint);overload;
procedure Delete(var A:TArray<integer>;const ofs:integer;const len:integer=maxint);overload;

type
  TArrayOps=class
    class Procedure Append<T>(var A:TArray<T>;const B:TArray<T>);
    class Function  Copy<T>(const A:TArray<T>;Ofs,Len:integer):TArray<T>;
    class Procedure Delete<T>(var A:TArray<T>;Ofs,Len:integer);
  end;

Function ArcSinCos(X,Y:single):single;

function CountChar(const s:ansistring;const ch:ansichar):integer;overload;
function CountChar(const s:PAnsiChar;const len:integer;const ch:ansichar):integer;overload;

type
  TLineSplitter=record
    FBuff:ansistring;
    procedure AppendStr(const s:ansistring);
    function HasLine:boolean;
    function GetLine(out line:ansistring):boolean;
  end;

procedure SetComposited(WinControl: TWinControl; Value: Boolean);  //when doublebuffer sucks (TGroupBox, TPageControl flicker)


////////// perf measure
type
  TPerfEntry=record
    cnt:integer;
    max,min,total:single;
    t0:double;
    function avg:single;
    procedure Start;
    procedure Stop;
    function MeasureFunct:IUnknown;
  end;
  PPerfEntry=^TPerfEntry;

  TPerfAutoFree=class
    PerfEntry:PPerfEntry;
    constructor Create(A: PPerfEntry);
    destructor Destroy;override;
  end;

function BitReverse(b: byte): byte;

function CanOpenFile(const fn:string;const AFileMode:byte=fmOpenReadWrite):boolean; //checks if file can be opened
function LatestFile(const Path:string;const SearchPattern:string;const OlderThan:TDateTime=0):string; //finds the latest openable filein a path

type
  TClipboardHelper = class helper for TClipboard
    procedure SetAsHtml(const str: AnsiString; const htmlStr: AnsiString = '');
  end;

function ifk(const key:ansistring):boolean; overload;
function ifk(const key:ansistring; a:single; b:single=0):single; overload;
function ifk(const key1:ansistring; const key2:ansistring):integer; overload;//1, 0, -1

implementation

uses IniFiles, StdCtrls, ExtCtrls, ComCtrls, Typinfo, SyncObjs,
  MultiMon, shlobj, activex, ZLib, IOUtils {$IFDEF SSE_DYNARRAYS},het.patch{$ENDIF};

function ifk(const key:ansistring):boolean; overload;
begin
  if(key<>'')and(getKeyState(ToHotVKey(key))<0)then exit(true);
  exit(false);
end;

function ifk(const key:ansistring; a:single; b:single=0):single; overload;
begin
  if ifk(key) then exit(a);
  exit(b);
end;

function ifk(const key1:ansistring; const key2:ansistring):integer; overload;//1, 0, -1
begin
  if ifk(key1) then exit( 1);
  if ifk(key2)then exit(-1);
  exit(0);
end;

procedure CopyHTMLToClipBoard(const str: AnsiString; const htmlStr: AnsiString = '');

{#define USEVCLCLIPBOARD}
//Code from http://www.lorriman.com
// Example: CopyHTMLToClipBoard('Hello world', 'Hello <b>world</b>');

  function FormatHTMLClipboardHeader(HTMLText: string): string;
  const
    CrLf = #13#10;
  begin
    Result := 'Version:0.9' + CrLf;
    Result := Result + 'StartHTML:-1' + CrLf;
    Result := Result + 'EndHTML:-1' + CrLf;
    Result := Result + 'StartFragment:000081' + CrLf;
    Result := Result + 'EndFragment:°°°°°°' + CrLf;
    Result := Result + HTMLText + CrLf;
    Result := StringReplace(Result, '°°°°°°', Format('%.6d', [Length(Result)]), []);
  end;

var
  gMem: HGLOBAL;
  lp: pointer;
  Strings: array[0..1] of AnsiString;
  Formats: array[0..1] of UINT;
  i: Integer;
begin
  raise Exception.Create('CopyHTMLToClipBoard() not working');

  {$IFNDEF USEVCLCLIPBOARD}
  Win32Check(OpenClipBoard(0));
  {$ENDIF}
  try
    //most descriptive first as per api docs
    Strings[0] := FormatHTMLClipboardHeader(htmlStr);
    Strings[1] := str;
    Formats[0] := RegisterClipboardFormat('HTML Format');
    Formats[1] := CF_TEXT;
    {$IFNDEF USEVCLCLIPBOARD}
    Win32Check(EmptyClipBoard);
    {$ENDIF}
    for i := 0 to High(Strings) do
    begin
      if Strings[i] = '' then Continue;
      //an extra "1" for the null terminator
      gMem := GlobalAlloc(GMEM_DDESHARE + GMEM_MOVEABLE, Length(Strings[i]) + 1);
      {Succeeded, now read the stream contents into the memory the pointer points at}
      try
        Win32Check(gmem <> 0);
        lp := GlobalLock(gMem);
        Win32Check(lp <> nil);
        CopyMemory(lp, pointer(Strings[i]), Length(Strings[i]) + 1);
      finally
        GlobalUnlock(gMem);
      end;
      Win32Check(gmem <> 0);
      SetClipboardData(Formats[i], gMEm);
      Win32Check(gmem <> 0);
    end;
  finally
    {$IFNDEF USEVCLCLIPBOARD}
    Win32Check(CloseClipBoard);
    {$ENDIF}
  end;
end;

procedure TClipboardHelper.SetAsHtml(const str: AnsiString; const htmlStr: AnsiString = '');
begin
  CopyHTMLToClipBoard(str,htmlStr);
end;

function CanOpenFile(const fn:string;const AFileMode:byte=fmOpenReadWrite):boolean;
var f:File;
    oldFileMode:byte;
begin
  AssignFile(f,fn);
  {$I-}
  oldFileMode:=FileMode;
  FileMode:=AFileMode;
  Reset(f,1);
  result:= IOResult=0;
  CloseFile(f);
  FileMode:=oldFileMode;
  {$I+}
end;

function LatestFile(const Path:string;const SearchPattern:string;const OlderThan:TDateTime=0):string;
var fn:string;
    age,a:TDateTime;
begin
  result:='';
  age:=olderThan;
  if not DirectoryExists(Path)then exit;
  for fn in TDirectory.GetFiles(Path,SearchPattern)do begin
    FileAge(fn,a);
    if age<a then begin
      result:=fn;
      age:=a;
    end;
  end;

  if Result<>'' then begin //Check if the file is accessible
    if not CanOpenFile(result)then
      result:='';
  end;
end;

function BitReverse(b: byte): byte;
asm
  MOV EDX, EAX
  SHR EDX, 1    RCL EAX, 1
  SHR EDX, 1    RCL EAX, 1
  SHR EDX, 1    RCL EAX, 1
  SHR EDX, 1    RCL EAX, 1
  SHR EDX, 1    RCL EAX, 1
  SHR EDX, 1    RCL EAX, 1
  SHR EDX, 1    RCL EAX, 1
  SHR EDX, 1    RCL EAX, 1
end;

////////////////////////////////////////////////////////////////////////////////
{ TPerfEntry }

function TPerfEntry.avg: single;
begin
  if cnt=0 then result:=0
           else result:=total/cnt;
end;

procedure TPerfEntry.Start;
begin
  if t0<>0 then raise Exception.Create('TPerfEntry.Start() Timing session already started');
  t0:=QPS;
end;

procedure TPerfEntry.Stop;
var d:single;
begin
  if t0=0 then raise Exception.Create('TPerfEntry.Stop() Timing session haven''t started');
  d:=qps-t0;
  if cnt=0 then begin max:=d;min:=d;end
           else begin if d>max then max:=d else if d<min then min:=d end;
  inc(cnt);
  total:=total+d;
  t0:=0;
end;

function TPerfEntry.MeasureFunct:IUnknown;
begin
  result:=AutoFree(TPerfAutoFree.Create(@self));
  Start;
end;

constructor TPerfAutoFree.Create(A:PPerfEntry);
begin
  PerfEntry:=A;
end;

destructor TPerfAutoFree.Destroy;
begin
  PerfEntry.Stop;
end;

////////////////////////////////////////////////////////////////////////////////

procedure SetComposited(WinControl: TWinControl; Value: Boolean);
var
  ExStyle, NewExStyle: DWORD;
begin
  ExStyle := GetWindowLong(WinControl.Handle, GWL_EXSTYLE);
  if Value then begin
    NewExStyle := ExStyle or WS_EX_COMPOSITED;
  end else begin
    NewExStyle := ExStyle and not WS_EX_COMPOSITED;
  end;
  if NewExStyle<>ExStyle then begin
    SetWindowLong(WinControl.Handle, GWL_EXSTYLE, NewExStyle);
  end;
end;

procedure TLineSplitter.AppendStr(const s:ansistring);
begin
  FBuff:=FBuff+s;
end;

function TLineSplitter.HasLine:boolean;
begin
  result:=pos(#10,FBuff,[])>0;
end;

function TLineSplitter.GetLine(out line:ansistring):boolean;
var i,j:integer;
begin
  i:=pos(#10,FBuff,[]);
  result:=i>0;
  if not result then begin line:='';exit;end;

  //make result, process backspace
  if charn(line,length(line))=#13 then setlength(line,length(line)-1);
  with AnsiStringBuilder(line,true)do begin
    for j:=1 to i-1 do if FBuff[j]=#8 then DeleteLastChar
                                      else AddChar(FBuff[j]);
  end;

  //extract from FBuff
  if charn(FBuff,i+1)=#13 then inc(i);
  FBuff:=copy(FBuff,i+1);
end;


function CountChar(const s:PAnsiChar;const len:integer;const ch:ansichar):integer;overload;
var i:integer;
    p:PAnsiChar;
begin
  result:=0;
  p:=s;
  for i:=0 to len-1 do begin
    inc(result,ord(p[0]=ch));
    inc(p);
  end;
end;

function CountChar(const s:ansistring;const ch:ansichar):integer;
begin
  result:=CountChar(pointer(s),length(s),ch);

//  r:=0;for i:=1 to length(s)do if s[i]=ch then inc(r);
//  if result<>r then raise Exception.Create('fuck');
end;

Function ArcSinCos(X,Y:single):single;
var d:single;
begin
  d:=x*x+y*y;
  if d=0 then begin result:=0;exit end;
  if d<>1 then d:=1/sqrt(d);
  if abs(x)<abs(y) then begin
    result:=ArcCos(x*d);
    if y<0 then result:=-result+pi*2;
  end else begin
    result:=ArcSin(y*d);
    if x<0 then result:=-result+pi;
    if result<0 then result:=result+pi*2;
  end;
end;

class Procedure TArrayOps.Append<T>(var A:TArray<T>;const B:TArray<T>);
var l1,l2:integer;
begin
  if B=nil then exit;
  l1:=length(A);
  l2:=length(B);
  SetLength(A,l1+l2);
  move(B[0],A[l1],l2*sizeof(T));
end;

procedure PreprocessOfsLen(ArrayLen:integer;var ofs,len:integer);
var x:integer;
begin
  if ofs<0 then begin len:=len+ofs;ofs:=0;end;
  if len<=0 then exit;
  x:=(ofs+len)-ArrayLen;
  if x>0 then len:=len-x;
end;

class function TArrayOps.Copy<T>(const A:TArray<T>;Ofs,Len:integer):TArray<T>;
var x:integer;
begin
  if ofs<0 then begin len:=len+ofs;ofs:=0;end;
  x:=(ofs+len)-Length(A);
  if x>0 then len:=len-x;
  if len<=0 then exit(nil);

  setlength(Result,len);
  move(A[ofs],Result[0],len*sizeof(T));
end;

class procedure TArrayOps.Delete<T>(var A:TArray<T>;Ofs,Len:integer);
var x,remain:integer;
begin
  if ofs<0 then begin len:=len+ofs;ofs:=0;end;
  x:=(ofs+len)-Length(A);
  if x>0 then len:=len-x;
  if len<=0 then exit;

  remain:=length(A)-(ofs+len);
  if remain>0 then
    move(A[ofs+len],A[ofs],len*sizeof(T));
  setlength(A,length(A)-len);
end;

procedure Append(var f:text);overload;
begin
  System.Append(f);
end;

procedure Append(var A:TArray<single>;const B:TArray<single>);begin TArrayOps.Append<single>(A,B)end;
procedure Append(var A:TArray<integer>;const B:TArray<integer>);begin TArrayOps.Append<integer>(A,B)end;

function Copy(const A:string;const ofs:integer;const len:integer=maxint):string;begin result:=system.Copy(A,ofs,len)end;
function Copy(const A:ansistring;const ofs:integer;const len:integer=maxint):ansistring;begin result:=system.Copy(A,ofs,len)end;
function Copy(const A:Rawbytestring;const ofs:integer;const len:integer=maxint):rawbytestring;begin result:=system.Copy(A,ofs,len)end;
function Copy(const A:TArray<single>;const ofs:integer;const len:integer=maxint):TArray<single>;begin result:=TArrayOps.Copy<single>(A,ofs,len)end;
function Copy(const A:TArray<integer>;const ofs:integer;const len:integer=maxint):TArray<integer>;begin result:=TArrayOps.Copy<integer>(A,ofs,len)end;

procedure Delete(var A:string;const ofs:integer;const len:integer=maxint);begin system.Delete(A,ofs,len)end;
procedure Delete(var A:ansistring;const ofs:integer;const len:integer=maxint);begin system.Delete(A,ofs,len)end;
procedure Delete(var A:Rawbytestring;const ofs:integer;const len:integer=maxint);begin system.Delete(A,ofs,len)end;
procedure Delete(var A:TArray<single>;const ofs:integer;const len:integer=maxint);begin TArrayOps.Delete<single>(A,ofs,len)end;
procedure Delete(var A:TArray<integer>;const ofs:integer;const len:integer=maxint);begin TArrayOps.Delete<integer>(A,ofs,len)end;

procedure ComplexMul(const a,b,c,d:single;out r,i:single); //r0,i0,r1,i1
var newR:single;
begin
  newr:=a*c-b*d;
  i:=a*d+b*c; //can be otped to 3 muls 5 adds vs. 4 muls 2 adds
  r:=newr;
end;

procedure ComplexMAD(const a,b,c,d:single;var r,i:single); //r0,i0,r1,i1
var newR:single;
begin
  newR:=r+a*c-b*d;
  i:=i+a*d+b*c;
  r:=newR;
end;

function SingleArrayZeroes(const len:integer):TArray<single>;
begin
  setlength(result,len);
  FillChar(pointer(result)^,len shl 2,0);
end;

function IntArrayZeroes(const len:integer):TArray<integer>;
begin
  setlength(result,len);
  FillChar(pointer(result)^,len shl 2,0);
end;

function LoadSingleArray(const fn:string):TArray<single>;
var s:RawByteString;
begin
  s:=TFile(fn);
  setlength(result,length(s)shr 2);
  move(pointer(s)^,pointer(result)^,length(result)shl 2);
end;

procedure SaveSingleArray(const fn:string;const a:TArray<single>);
begin
  TFile(fn).Write(DataToStr(pointer(a)^,length(a)shl 2));
end;

function GetCurrentProcessorNumber:integer;
asm
  push ebx
  mov eax, 1
  cpuid
  shr ebx, 24
  mov eax, ebx
  pop ebx
end;

function IsIdentifier(const s:ansistring):boolean;
var w:ansistring;
begin
  w:=wordat(s,1,false);
  result:=(w<>'')and(length(s)=length(w));
end;

//function min(a,b:cardinal):cardinal;begin if a>b then result:=b else result:=a end;
//function max(a,b:cardinal):cardinal;begin if a<b then result:=b else result:=a end;
//function max3(a,b,c:cardinal):cardinal;begin result:=max(max(a,b),c)end;

function min(a,b:integer):integer;begin if a>b then result:=b else result:=a end;
function max(a,b:integer):integer;begin if a<b then result:=b else result:=a end;

procedure minimize(var a:integer;b:integer); begin a:=min(a,b); end;
procedure maximize(var a:integer;b:integer); begin a:=max(a,b); end;

function minf(a,b:single):single;begin if a>b then result:=b else result:=a end;
function maxf(a,b:single):single; begin if a<b then result:=b else result:=a end;

function BFE(const value,bitofs,size:cardinal):cardinal;
begin
  result:=value shr bitofs and(1 shl size-1);
end;

function BFI(const value,bitOfs,size,ins:cardinal):cardinal;
begin
  result:=value and not((1 shl size-1)shl bitOfs)or ins shl bitOfs;
end;

function umul24_hi(a,b:cardinal):cardinal;
asm and eax,$FFFFFF;and edx,$FFFFFF; mul eax,edx  movzx eax,dx end;

function umul24_lo(a,b:cardinal):cardinal;
asm and eax,$FFFFFF;and edx,$FFFFFF; mul eax,edx end;

function umul_hi(a,b:cardinal):cardinal;
asm mul eax,edx mov eax,edx end;


function NewLineCorrect(const s:ansistring):ansistring;
begin
  result:=s;
  Replace(#10,#13#10,result,[roAll]);
end;

////////////////////////////////////////////////////////////////////////////////
/// SSE stuff

var _CPUID:record a,b,c,d:cardinal;end;

procedure getCPUID(const func:cardinal);
asm
  push ebx
  cpuid
  mov _CPUID.a,eax
  mov _CPUID.b,ebx
  mov _CPUID.c,ecx
  mov _CPUID.d,edx
  pop ebx
end;

procedure DetectSSEVersion;
  function bit(const c,n:cardinal):boolean;begin result:=(c shr n and 1)<>0;end;
begin
  SSEVersion:=SSENone;
  getCPUID(0);
  if _CPUID.a>0 then begin
    getCPUID(1);
    if bit(_CPUID.c,19) then SSEVersion:=SSE4_1 else
    if bit(_CPUID.c, 0) then SSEVersion:=SSE3 else
    if bit(_CPUID.d,26)then SSEVersion:=SSE2 else
    if bit(_CPUID.d,25)then SSEVersion:=SSE1;
  end;
end;

{ TSSEReg }

procedure TSSEReg.SetB(const b0:integer);var i:integer;
begin
  for i:=0 to high(b)do b[i]:=b0;
end;

procedure TSSEReg.SetB(const b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,b10,b11,b12,b13,b14,b15:integer);
begin
  b[0]:=b0;b[1]:=b1;b[2]:=b2;b[3]:=b3;b[4]:=b4;b[5]:=b5;b[6]:=b6;b[7]:=b7;
  b[8]:=b8;b[9]:=b9;b[10]:=b10;b[11]:=b11;b[12]:=b12;b[13]:=b13;b[14]:=b14;
  b[15]:=b15;
end;

procedure TSSEReg.SetW(const w0:integer);var i:integer;
begin
  for i:=0 to high(w)do w[i]:=w0;
end;

procedure TSSEReg.SetW(const w0,w1,w2,w3,w4,w5,w6,w7:integer{smallint miatt});
begin
  w[0]:=w0;w[1]:=w1;w[2]:=w2;w[3]:=w3;w[4]:=w4;w[5]:=w5;w[6]:=w6;w[7]:=w7;
end;

procedure TSSEReg.SetDW(const dw0:integer);var i:integer;
begin
  for i:=0 to high(dw)do dw[i]:=dw0;
end;

procedure TSSEReg.SetDW(const dw0,dw1,dw2,dw3:integer);
begin
  dw[0]:=dw0;dw[1]:=dw1;dw[2]:=dw2;dw[3]:=dw3;
end;

procedure TSSEReg.SetQW(const qw0:int64);
begin
  qw[0]:=qw0;qw[1]:=qw0;
end;

procedure TSSEReg.SetQW(const qw0,qw1:int64);
begin
  qw[0]:=qw0;qw[1]:=qw1;
end;

procedure TSSEReg.SetF(const f0:single);var i:integer;
begin
  for i:=0 to high(f)do f[i]:=f0;
end;

procedure TSSEReg.SetF(const f0,f1,f2,f3:single);
begin
  f[0]:=f0;f[1]:=f1;f[2]:=f2;f[3]:=f3;
end;

procedure TSSEReg.SetD(const d0:double);
begin
  d[0]:=d0;d[1]:=d0;
end;

procedure TSSEReg.SetD(const d0,d1:double);
begin
  d[0]:=d0;d[1]:=d1;
end;


{ TAlignedBuffer }

function TAlignedBuffer.Alloc(const length,align: integer): pointer;
var mask:integer;
begin
  if length>0 then begin
    mask:=align-1;
    Assert((align and mask)=0,'TAlignedBuffer.Alloc() error align is NOT power of 2');
    setlength(_internalData,length+mask);
    Address:=pointer((cardinal(@_internalData[0])+cardinal(mask))and not mask);
  end else begin
    SetLength(_internalData,0);
    Address:=nil;
  end;
  result:=Address;
  Assert(integer(result)and $f=0,'argh '+inttostr(length)+inttohex(integer(result),8)+' '+inttostr(align));
end;

////////////////////////////////////////////////////////////////////////////////

function Bitmap2Icon(Bitmap: TBitmap; TransparentColor: TColor): TIcon;
begin
  with TImageList.CreateSize(Bitmap.Width, Bitmap.Height) do
  begin
    try
      AllocBy := 1;
      AddMasked(Bitmap, TransparentColor);
      Result := TIcon.Create;
      try
        GetIcon(0, Result);
      except
        Result.Free;
        raise;
      end;
    finally
      Free;
    end;
  end;
end;

procedure GetFileInfo(const AFileName:ansistring;out cre,acc,wri:int64;out attr:cardinal);
var h:integer;
begin
  attr:=GetFileAttributesA(PAnsiChar(AFileName));
  h:=FileOpen(AFileName,fmOpenRead);
  if h=-1 then begin cre:=-1;wri:=-1;acc:=-1 end
          else begin GetFileTime(h,@cre,@acc,@wri);CloseHandle(h);end;
end;

procedure SetFileInfo(const AFileName:ansistring;const cre,acc,wri:int64;const attr:cardinal);
var h:integer;
begin
  h:=FileOpen(AFileName,fmOpenRead);
  if h<>-1 then begin
    SetFileTime(h,@cre,@acc,@wri);
    CloseHandle(h);
  end;
  SetFileAttributesA(PAnsiChar(AFileName),attr);
end;

function GetFileLastWriteTime(const AFileName:ansistring):int64;
var h:integer;
    i1,i2:int64;
begin
  h:=FileOpen(AFileName,fmOpenRead);
  if h=-1 then exit(-1)
          else GetFileTime(h,@i1,@i2,@result);
  CloseHandle(h);
end;

procedure SetFileLastWriteTime(const AFileName:ansistring;const ATime:int64);
var h:integer;
    i1,i2,i3:int64;
begin
  h:=FileOpen(AFileName,fmOpenRead);
  if h=-1 then exit;
  GetFileTime(h,@i1,@i2,@i3);
  SetFileTime(h,@i1,@i2,@ATime);
  CloseHandle(h);
end;

function GetFileCreationTime(const AFileName:ansistring):int64;
var h:integer;
    i1,i2:int64;
begin
  h:=FileOpen(AFileName,fmOpenRead);
  if h=-1 then exit(-1)
          else GetFileTime(h,@result,@i1,@i2);
  CloseHandle(h);
end;

procedure SetFileCreationTime(const AFileName:ansistring;const ATime:int64);
var h:integer;
    i1,i2,i3:int64;
begin
  h:=FileOpen(AFileName,fmOpenRead);
  if h=-1 then exit;
  GetFileTime(h,@i1,@i2,@i3);
  SetFileTime(h,@ATime,@i2,@i3);
  CloseHandle(h);
end;

function umul64(const a,b:cardinal):int64;
asm
  mul edx
  mov dword ptr[result], eax
  mov dword ptr[result+4], edx
end;

function ToSeconds(const dt:TDateTime):double;
begin
  result:=dt*(24*60*60);
end;

function RawFindBinary(const list;const length,stride,offset:integer;const F:TRawFindBinaryFunct;out AIdx:integer):boolean;
var hi,lo,cmp,idx:integer;
begin
  lo:=0;
  hi:=length-1;
  if hi<0 then begin
    AIdx:=0;
    result:=false;
  end else begin
    repeat
      Idx:=(lo+hi)shr 1;
      cmp:=F(psucc(@list,Idx*stride+offset)^);
      if cmp>0 then lo:=Idx+1
               else hi:=Idx-1;
    until(cmp=0)or(lo>hi);
    result:=cmp=0;
    if not result then
      if Cmp>0 then inc(Idx);
    AIdx:=Idx;
  end;
end;

function FindListItem(const filter:ansistring;const list:ansistring;listDelimiter:ansichar):integer;
var s:AnsiString;
begin
  result:=0;
  for s in listsplit(list,listDelimiter)do begin
    if IsWild2(filter,s)then exit;
    inc(result);
  end;
  result:=-1;
end;

function SgnSqr(const x:single):single;
begin
  if x<0 then result:=-x*x
         else result:= x*x;
end;

type
  TPInvokeThread=class(TThread)
  private
    FProc:TProc;
  public
    procedure Execute;override;
  end;

procedure TPInvokeThread.Execute;
begin
  FProc;
end;

procedure PInvoke(const AProc:TProc);
begin
  with TPInvokeThread.Create(true)do begin
    FProc:=AProc;
    FreeOnTerminate:=True;
    Start;
  end;
end;

function QPF:int64;
begin
  QueryPerformanceFrequency(result);
end;

function QPC:int64;
begin
  QueryPerformanceCounter(result);
end;

function QPS:double;
begin
  result:=QPC/QPF;
end;

procedure Inc2(var a:single;const b:single=0);
begin
  a:=a+b;
end;

function SwapRB;
begin
  result:=c and integer($ff00ff00)+c and $ff shl 16+c and $ff0000 shr 16;
end;

////////////////////////////////////////////////////////////////////////////////
///  FileSys                                                                 ///
////////////////////////////////////////////////////////////////////////////////

//globals
var
  FileHandlers:TArray<IFileHandler>;


Procedure CreateDirForFile(const FN:ansiString);//!!!!!! na ez nem unicode!!!!
var i:Integer;
Begin
  For i:= 0 To ListCount(FN, '\')-1 Do
    {$WARNINGS OFF}CreateDir(ListItemRange(FN, 0, i, '\'));{$WARNINGS ON}
End;

function IsFullPath(const AFileName:string):boolean;
begin
  result:=(system.pos(':',AFilename)=2)or((AFileName<>'')and(AFileName[1]='\'));
end;

function ExpandFileNameForWrite(const AFileName:string):string;
begin
  if(Length(SearchPath.Paths)>0)and not IsFullPath(AFileName)then
    result:=ExpandFileName(SearchPath.Peek+AFileName)
  else
    result:=ExpandFileName(AFileName);
end;

function ExpandFileNameForRead(const AFileName:string):string;
var i:integer;
begin
  if(SearchPath.Peek<>'')and not IsFullPath(AFileName)then begin
    for i:=high(SearchPath.Paths)downto 0 do begin
      result:=ExpandFileName(SearchPath.Paths[i]+AFileName);
      if FileExists(result)then exit;
    end;
    result:='';
  end else
    result:=ExpandFileName(AFileName);
end;

procedure RegisterFileHandler(const AHandler:IFileHandler);
begin
  setlength(FileHandlers,length(FileHandlers)+1);
  FileHandlers[high(FileHandlers)]:=AHandler;
end;

function GetFileHandler(AFileName:string):IFileHandler;
var i:integer;
begin
  for i:=high(FileHandlers)downto 0 do
    if FileHandlers[i].Supports(AFileName)then
      exit(FileHandlers[i]);
  raise Exception.Create('No FileHandler for file '+toPas(AFileName));
end;

//default handler
type
  TWin32FileHandler=class(TInterfacedObject,IFileHandler)
    function Supports(const fn:String):boolean;
    function Exists(const fn:String):boolean;
    function Read(const fn:String;const MustExists:boolean):RawByteString;
    procedure Write(const fn:String;const data:RawByteString);
  end;

function TWin32FileHandler.Supports(const fn:String):boolean;
begin
  result:=true;
end;

function TWin32FileHandler.Exists(const fn:String):boolean;
begin
  result:=sysutils.FileExists(fn);
end;

function TWin32FileHandler.Read(const fn:String;const MustExists:boolean):RawByteString;
var fm:byte;
    f:file;
begin
  if not sysutils.FileExists(fn)then
    if MustExists then raise Exception.Create('File not found:"'+fn+'"')
                  else exit('');

  AssignFile(f,fn);

  fm:=FileMode;FileMode:=fmOpenRead;
  try
    reset(f,1);
  except
    FileMode:=fm;
    raise Exception.Create('Error opening file'+toStr(fn));
  end;

  setlength(result,System.FileSize(F));
  try
    if length(Result)>0 then
      BlockRead(f,result[1],length(result));
    result:=ZDecompress(result);
    CloseFile(f);
  except
    result:='';
    closefile(f);
    raise Exception.Create('Error reading file '+toStr(fn));
  end;
end;

procedure TWin32FileHandler.Write(const fn:String;const data:RawByteString);
var fm:byte;
    f:file;
begin
  CreateDirForFile(fn);

  AssignFile(f,fn);
  fm:=FileMode;FileMode:=fmOpenReadWrite;
  try
    rewrite(f,1);
  except
    FileMode:=fm;
    raise Exception.Create('Error opening(rw) file'+toStr(fn));
  end;

  try
    BlockWrite(f,pointer(data)^,length(data));
    closefile(f);
  except
    closefile(f);
    raise Exception.Create('Error writing file '+toStr(fn));
  end;
end;

{ ZCompress }

function _ZCompress(const src:RawByteString;const Decompress:boolean):RawByteString;overload;
type TMagic=array[0..3]of ansichar;
     PMagic=^TMagic;
const magic:TMagic='Y\ ['; //ZLIB xor magic

var stIn,stOut:TRawStream;
begin
  if src='' then exit;
  if Decompress then
    if(Length(src)<4)or(pMagic(src)^<>magic)then exit(src);//nothing to decompress

  if not Decompress then
    if(Length(src)>=4)and(pMagic(src)^=magic)then exit(src);//already compressed

  result:='';
  stin:=TRawStream.Create(src);
  stOut:=TRawStream.Create('');
  try
    if Decompress then begin stIn.Seek(4,soFromBeginning);ZDecompressStream(stIn,stOut)end
                  else begin stOut.WriteString(magic);ZCompressStream(stIn,stOut);end;
    result:=stout.DataString;
  finally
    stIn.Free;
    stOut.Free;
  end;
end;

function ZCompress(const src:RawByteString):RawByteString;overload;
begin
  Result:=_ZCompress(src,false);
end;

function ZDecompress(const src:RawByteString):RawByteString;overload;
begin
  Result:=_ZCompress(src,true);
end;

{ SearchPath }

class procedure SearchPath.Add(const APath:string);
begin
  SetLength(Paths,length(Paths)+1);
  Paths[high(Paths)]:=sysutils.ExpandFileName(APath);
end;

class procedure SearchPath.Remove(const APath:string);
var s:string;
    i,j:integer;
begin
  s:=ExpandFileName(APath);
  for i:=high(Paths)downto 0 do if SameText(Paths[i],s)then begin
    for j:=i to high(Paths)-1 do Paths[j]:=Paths[j+1];
    setlength(Paths,Length(Paths)-1);
  end;
end;

class function SearchPath.Peek:string;
begin
  if Paths<>nil then result:=Paths[high(Paths)]
                else result:='';
end;

class procedure SearchPath.Push(const APath:string);
begin
  Add(APath);
end;

class function SearchPath.Pop:string;
begin
  result:=Peek;
  if Paths<>nil then
    SetLength(Paths,length(Paths)-1);
end;

class procedure SearchPath.Clear;
begin
  SetLength(Paths,0);
end;

class function SearchPath.DstPath:string;
begin
  result:=peek;
end;

{ TFile }

class operator TFile.explicit(const fn:string):TFile;
begin
  Result.FFileName:=fn;
end;

function TFile.Read;
var fn:string;
begin
  fn:=ExpandFileNameForRead(FFileName);
  result:=GetFileHandler(fn).Read(fn,MustExists);
end;

procedure TFile.Write(const d:RawByteString);
var fn:string;
begin
  fn:=ExpandFileNameForWrite(FFileName);
  GetFileHandler(fn).Write(fn,d);
end;

class operator TFile.implicit(const f:TFile):rawbytestring;//read
begin
  Result:=f.Read;
end;

function TFile.Exists:boolean;
var fn:string;
begin
  fn:=ExpandFileNameForRead(FFileName);
  result:=GetFileHandler(fn).Exists(fn);
end;

function TFile.FullName:String;
begin
  result:=ExpandFileNameForRead(FFileName);
end;
////////////////////////////////////////////////////////////////////////////////

function FindFileExt(const AFileName:string;const AExtensionList:AnsiString=''):string;
var e:ansistring;
begin
  //asse tudom mar, hogy itt mi a rakot akarok csinalni argh :@
  if AExtensionList='' then begin
    result:=TFile(AFileName).FullName;
    if not TFile(Result).Exists then result:='';
  end else begin
    result:='';
    for e in ListSplit(AExtensionList,';')do begin
      result:=TFile(ChangeFileExt(AFileName,e)).FullName;
      if not TFile(Result).Exists then result:='';
      if result<>'' then exit;
    end;
  end;
end;

function BeginsWith(const str,beginning:string;const CaseInsens:boolean=true):boolean;
var s:string;
begin
  s:=copy(str,1,length(beginning));
  if CaseInsens then result:=SameText(s,beginning)
                else result:=SameStr(s,beginning);
end;

function EndsWith(const str,ending:string;const CaseInsens:boolean=true):boolean;
var s:string;
begin
  s:=copy(str,length(str)-length(ending)+1,length(ending));
  if CaseInsens then result:=SameText(s,ending)
                else result:=SameStr(s,ending);
end;

function _BrowseCallback(Wnd: HWND; uMsg: UINT; lParam, lpData: LPARAM): Integer stdcall;
begin
  case uMsg of
    BFFM_INITIALIZED:begin
      if lpData<>0 then
        SendMessage(wnd, BFFM_SETSELECTION, 1, lpData);
    end;
  end;
  result:=0;
end;

function BrowseForFolder(var Foldr: string; Title: string): Boolean;
var
  BrowseInfo: TBrowseInfo;
  ItemIDList: PItemIDList;
  DisplayName: array[0..MAX_PATH] of Char;
begin
  Result := False;
  FillChar(BrowseInfo, SizeOf(BrowseInfo), #0);
  fillchar(DisplayName,sizeof(DisplayName),0);
  if Foldr<>'' then
    move(Foldr[1],DisplayName[0],min(length(DisplayName)-1,length(Foldr)*2));
  with BrowseInfo do begin
    hwndOwner := Application.Handle;
    pszDisplayName := @DisplayName[0];
    lpszTitle := PChar(Title);
    ulFlags := BIF_RETURNONLYFSDIRS;
    lpfn:=@_BrowseCallback;
    lParam:=integer(@foldr[1]);
  end;
  ItemIDList := SHBrowseForFolder(BrowseInfo);
  if Assigned(ItemIDList) then begin
    if SHGetPathFromIDList(ItemIDList, DisplayName) then begin
      Foldr := DisplayName;
      Result := True;
    end;
    coTaskMemFree(ItemIDList);
  end;
end;

function UMod(const i,j:integer):integer;
begin
  if i>=0 then result:=i mod j
          else result:=j-(-(i+1) mod j)-1;
end;

////////////////////////////////////////////////////////////////////////////////
///  SSE implementation of delphi.move()                       real_het 2011 ///
////////////////////////////////////////////////////////////////////////////////

{$R-}{$O+}

var
  FastMoveCacheLimit:integer=3 shl 20; //should set to the cache size of one processor core

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
  asm
    test ecx,$F jz @@2
  @@1:
    movups xmm0,[eax+ecx+$00]
    movups xmm1,[eax+ecx+$10]
    movups xmm2,[eax+ecx+$20]
    movups xmm3,[eax+ecx+$30]
    movaps [eax+$00],xmm0 prefetchnta [eax+ecx+$100]
    movaps [eax+$10],xmm1 add eax,$40
    movaps [eax+$20-$40],xmm2
    movaps [eax+$30-$40],xmm3 cmp eax,edx jne @@1 ret
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
    xchg edx,eax sub eax,$40 sub edx,$40
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
  asm
    xchg edx,eax sub eax,$40 sub edx,$40
    test ecx,$f jz @@2
  @@1:
    movups xmm0,[eax+ecx+$00]
    movups xmm1,[eax+ecx+$10]
    movups xmm2,[eax+ecx+$20]
    movups xmm3,[eax+ecx+$30]
    movaps [eax+$00],xmm0 prefetchnta [eax+ecx-$100]
    movaps [eax+$10],xmm1 sub eax,$40
    movaps [eax+$20+$40],xmm2
    movaps [eax+$30+$40],xmm3 cmp eax,edx jne @@1 ret
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
    reverse,nocache:boolean;
begin
  if size<(AlignSizeMask+1)*2 then begin system.Move(src,dst,size);exit end;
  //check params
  if(@src=nil)or(@dst=nil)then exit;
  delta:=integer(@dst)-integer(@src);
  if delta=0 then exit;
  reverse:=(delta>0)and(delta<size);
  delta:=-delta;//Delta: dst -> src

  pDst:=integer(@dst);
  pDstEnd:=pDst+size;
  pDstInner:=(pDst+AlignPosMask)and not AlignPosMask;
  InnerSize:=(pDstEnd-pDstInner)and not AlignSizeMask;
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
///  Functional and performance testing                                      ///
////////////////////////////////////////////////////////////////////////////////

function _TestFastMove:ansistring;

  procedure log(s:ansistring);begin result:=result+s+#13#10;writeln(s)end;

const TestDataSize=256;
      BufSize=128 shl 20;

type TByteArray=array[0..BufSize-1]of byte;PByteArray=^TByteArray;

var
  _buf:array of byte;
  buf:PByteArray;
  i,j,k:integer;
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
    if not sysutils.CompareMem(pref,pdst,siz)then
      raise Exception.CreateFmt('TestFastMove() functional test failed %p %p %x',[psrc,pdst,siz]);
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
          0: System.Move(buf[0+i shr 1 and 1],buf[bufsize shr 1-(i shr 2 and 1)*3],siz);
          else FastMove (buf[0+i shr 1 and 1],buf[bufsize shr 1-(i shr 2 and 1)*3],siz);
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

////////////////////////////////////////////////////////////////////////////////

function DataToStr(const Data;const Size:integer):RawByteString;
begin
  setlength(result,size);
  system.move(Data,pointer(result)^,size);
end;

procedure StrToData(const s:RawByteString;var Data;const Size:integer=0; const fillZero:boolean=true);
var i:integer;
begin
  if size=0 then i:=length(s)
            else i:=min(Size,length(s));
  system.move(pointer(s)^,Data,i);
  if(size>length(s))and fillZero then
    fillchar(pointer(integer(@data)+length(s))^,size-length(s),0);
end;

function FourCC(const a:integer):ansistring;
begin
  Result:=DataToStr(a,4);
end;

function FourCC(const a:cardinal):ansistring;overload;
begin
  Result:=DataToStr(a,4);
end;

function FourCC(const a:ansistring):ansistring;overload;
begin
  result:=copy(a,1,4);
  while length(result)<4 do
    result:=result+#0;
end;

function ValidEmail(email:ansistring): boolean;
// Returns True if the email address is valid
// Author: Ernesto D'Spirito
const
  // Valid characters in an "atom"
  atom_chars = [#33..#255] - ['(', ')', '<', '>', '@', ',', ';', ':',
                              '\', '/', '"', '.', '[', ']', #127];
  // Valid characters in a "quoted-string"
  quoted_string_chars = [#0..#255] - ['"', #13, '\'];
  // Valid characters in a subdomain
  letters = ['A'..'Z', 'a'..'z'];
  letters_digits = ['0'..'9', 'A'..'Z', 'a'..'z'];
  subdomain_chars = ['-', '0'..'9', 'A'..'Z', 'a'..'z'];
type
  States = (STATE_BEGIN, STATE_ATOM, STATE_QTEXT, STATE_QCHAR,
    STATE_QUOTE, STATE_LOCAL_PERIOD, STATE_EXPECTING_SUBDOMAIN,
    STATE_SUBDOMAIN, STATE_HYPHEN);
var
  State: States;
  i, n, subdomains: integer;
  c: ansichar;
begin
  State := STATE_BEGIN;
  n := Length(email);
  i := 1;
  subdomains := 1;
  while (i <= n) do begin
    c := email[i];
    case State of
    STATE_BEGIN:
      if c in atom_chars then
        State := STATE_ATOM
      else if c = '"' then
        State := STATE_QTEXT
      else
        break;
    STATE_ATOM:
      if c = '@' then
        State := STATE_EXPECTING_SUBDOMAIN
      else if c = '.' then
        State := STATE_LOCAL_PERIOD
      else if not (c in atom_chars) then
        break;
    STATE_QTEXT:
      if c = '\' then
        State := STATE_QCHAR
      else if c = '"' then
        State := STATE_QUOTE
      else if not (c in quoted_string_chars) then
        break;
    STATE_QCHAR:
      State := STATE_QTEXT;
    STATE_QUOTE:
      if c = '@' then
        State := STATE_EXPECTING_SUBDOMAIN
      else if c = '.' then
        State := STATE_LOCAL_PERIOD
      else
        break;
    STATE_LOCAL_PERIOD:
      if c in atom_chars then
        State := STATE_ATOM
      else if c = '"' then
        State := STATE_QTEXT
      else
        break;
    STATE_EXPECTING_SUBDOMAIN:
      if c in letters then
        State := STATE_SUBDOMAIN
      else
        break;
    STATE_SUBDOMAIN:
      if c = '.' then begin
        inc(subdomains);
        State := STATE_EXPECTING_SUBDOMAIN
      end else if c = '-' then
        State := STATE_HYPHEN
      else if not (c in letters_digits) then
        break;
    STATE_HYPHEN:
      if c in letters_digits then
        State := STATE_SUBDOMAIN
      else if c <> '-' then
        break;
    end;
    inc(i);
  end;
  if i <= n then
    Result := False
  else
    Result := (State = STATE_SUBDOMAIN) and (subdomains >= 2);
end;

function postInc(var i:integer):integer;overload;inline;begin result:=i;inc(i);end;
function postDec(var i:integer):integer;overload;inline;begin result:=i;dec(i);end;
function postInc(var i:integer;const n:integer):integer;overload;inline;begin result:=i;inc(i,n);end;
function postDec(var i:integer;const n:integer):integer;overload;inline;begin result:=i;dec(i,n);end;

function postInc(var i:cardinal):cardinal;overload;inline;begin result:=i;inc(i);end;
function postDec(var i:cardinal):cardinal;overload;inline;begin result:=i;dec(i);end;
function postInc(var i:cardinal;const n:integer):cardinal;overload;inline;begin result:=i;inc(i,n);end;
function postDec(var i:cardinal;const n:integer):cardinal;overload;inline;begin result:=i;dec(i,n);end;

function postInc(var i:byte):byte;overload;inline;begin result:=i;inc(i);end;

function vec_sel(const selZero,selOne,sel:integer):integer;
begin
  result:=(selOne and sel)or(selZero and not sel);
end;

function FindIntArray(const a:tia;b:integer):integer;var i:integer;
begin
  for i:=0 to high(a)do if a[i]=b then exit(i);
  result:=-1;
end;

function FindStrArray(const a:tsa;b:ansistring):integer;var i:integer;
begin
  for i:=0 to high(a)do if cmp(a[i],b)=0 then exit(i);
  result:=-1;
end;

procedure SortIntArray(var a:tia);var i,j:integer;
begin
  for i:=0 to high(a)-1do for j:=i+1 to high(a)do if a[i]>a[j] then swap(a[i],a[j]);
end;

procedure AddIntArray(var a:tia;b:integer);var i:integer;
begin
  for i:=0 to high(a)do if a[i]=b then exit;
  setlength(a,length(a)+1);a[high(a)]:=b;
end;

procedure AddIntArrayNoCheck(var a:tia;b:integer);
begin
  setlength(a,length(a)+1);a[high(a)]:=b;
end;

procedure AddStrArray(var a:tsa;const b:ansistring);var i:integer;
begin
  for i:=0 to high(a)do if a[i]=b then exit;
  setlength(a,length(a)+1);a[high(a)]:=b;
end;

procedure AddStrArrayNoCheck(var a:tsa;const b:ansistring);
begin
  setlength(a,length(a)+1);a[high(a)]:=b;
end;

procedure InsIntArray(var a:tia;pos:integer;b:integer);var i:integer;
begin
  setlength(a,length(a)+1);
  for i:=high(a) downto pos+1 do a[i]:=a[i-1];
  a[pos]:=b;
end;

procedure InsStrArray(var a:tsa;pos:integer;const b:ansistring);var i:integer;
begin
  setlength(a,length(a)+1);
  for i:=high(a) downto pos+1 do a[i]:=a[i-1];
  a[pos]:=b;
end;

procedure DelIntArrayValue(var a:tia;b:integer);var i,j:integer;
begin
  for i:=0 to high(a)do if a[i]=b then begin
    for j:=i to high(a)-1 do a[j]:=a[j+1];
    setlength(a,high(a));
    exit;
  end;
end;

procedure DelIntArray(var a:tia;b:integer);var j:integer;
begin
  if b<=high(a) then begin
    for j:=b to high(a)-1 do a[j]:=a[j+1];
    setlength(a,high(a));
  end;
end;

procedure ToggleIntArray(var a:tia;b:integer);var i,j:integer;
begin
  for i:=0 to high(a)do if a[i]=b then begin
    for j:=i to high(a)-1 do a[j]:=a[j+1];
    setlength(a,high(a));
    exit;
  end;
  AddIntArray(a,b);
end;

procedure CopyIntArray(var s,d:tia);var i:integer;
begin
  setlength(d,length(s));
  for i:=0 to high(s)do d[i]:=s[i];
end;

procedure IntArrayDecGreaterValues(var a:tia;r:integer);var i:integer;
begin
  for i:=0 to high(a)do if a[i]>r then dec(a[i]);
end;

procedure StrToIntArray(const s:ansistring;var a:tia;separ:ansichar);
var i:integer;
begin
  SetLength(a,listcount(s,separ)-switch((s<>'')and(s[length(s)]=separ),1,0));
  for i:=0 to high(a)do a[i]:=strtointdef(listitem(s,i,separ),0);
end;

procedure SortStrArray(var a:tsa);var i,j:integer;
begin
  for i:=0 to high(a)-1do for j:=i+1 to high(a)do if cmp(a[i],a[j])>0 then swap(a[i],a[j]);
end;

procedure DistinctStrArray(var a:tsa;const doSort:boolean);
var i,j:integer;
begin
  if doSort then SortStrArray(a);
  for i:=high(a)-1 downto 0 do if cmp(a[i],a[i+1])=0 then begin
    for j:=i to high(a)-1 do a[j]:=a[j+1];
    setlength(a,high(a));
  end;
end;

function FindBinStrArray(const a:tsa;const s:ansistring):integer;
begin
  if not RawFindBinary(pointer(a)^,length(a),4,0,function(const a):integer begin result:=cmp(s,ansistring(a))end,result)then
    result:=-1;
end;

function FindBinIntArray(const a:tia;const s:integer):integer;
begin
  if not RawFindBinary(pointer(a)^,length(a),4,0,function(const a):integer begin result:=cmp(s,integer(a))end,result)then
    result:=-1;
end;

function CountBits(i:integer):integer;
begin
  i:=(i       and $11111111)+
     (i shr 1 and $11111111)+
     (i shr 2 and $11111111)+
     (i shr 3 and $11111111);
  i:=(i       and $0F0F0F0F)+
     (i shr 4 and $0F0F0F0F);
  i:=(i       and $00FF00FF)+
     (i shr 8 and $00FF00FF);
  result:=i and $ff+i shr 16;
end;

function HammingDist(const a,b:integer):integer;
begin
  result:=CountBits(a xor b);
end;

//c++ compatibility stuff
procedure printf(const s:string;const Args:array of const);overload;
begin Write(ReplaceF('\n',#13#10,Format(s,Args),[roAll]))end;

procedure printf(const s:string;const v0,v1,v2,v3,v4,v5:variant);overload;
begin printf(s,[v0,v1,v2,v3,v4,v5])end;
procedure printf(const s:string;const v0,v1,v2,v3,v4:variant);overload;
begin printf(s,[v0,v1,v2,v3,v4])end;
procedure printf(const s:string;const v0,v1,v2,v3:variant);overload;
begin printf(s,[v0,v1,v2,v3])end;
procedure printf(const s:string;const v0,v1,v2:variant);overload;
begin printf(s,[v0,v1,v2])end;
procedure printf(const s:string;const v0,v1:variant);overload;
begin printf(s,[v0,v1])end;
procedure printf(const s:string;const v0:variant);overload;
begin printf(s,[v0])end;
procedure printf(const s:string);overload;
begin printf(s,[])end;


function ROL(const a,b:cardinal):cardinal; asm mov cl,dl rol eax,cl end;
function ROR(const a,b:cardinal):cardinal; asm mov cl,dl ror eax,cl end;

function ByteOrderSwap(const A: Cardinal): Cardinal;
begin
  Result:= (A shr 24) or ((A shr 8) and $FF00) or ((A shl 8) and $FF0000) or (A shl 24);
end;

function ByteOrderSwap(const A: Integer): Integer;
begin
  Result:= (A shr 24) or ((A shr 8) and $FF00) or ((A shl 8) and $FF0000) or (A shl 24);
end;

function ByteOrderSwap(const A: Word): word;
begin
  Result:= (A shr 8) or (A shl 8);
end;

function ByteOrderSwap(const A: Smallint): smallint;
begin
  Result:= (A shr 8) or (A shl 8);
end;

function StrMul(const Src:ansistring;const count:integer):ansistring;overload;
var i,len:integer;
    pdst:PAnsiChar;
begin
  if(count<=0)or(Src='')then exit('');
  len:=length(Src);
  setlength(result,count*len);
  pDst:=pointer(result);
  for i:=0 to count-1 do begin
    move(pointer(Src)^,pdst^,len);
    inc(pdst,len);
  end;
end;

function StrMake(const ASrc:pointer;const ALen:integer):AnsiString;overload;
begin
  if(ASrc=nil)or(ALen<=0)then exit('');
  setlength(Result,ALen);
  move(ASrc^,pointer(result)^,ALen);
end;

function StrMake(const ASrc,AEnd:pointer):AnsiString;overload;
begin
  result:=StrMake(ASrc,integer(AEnd)-integer(ASrc));
end;

function RTrimLines(const s:ansistring):ansistring;
var sp:boolean;
    i,p0,p1,p2,len:integer;
begin
  result:=s;
  sp:=false;
  for i:=1 to length(s)do case s[i] of
    ' ':sp:=true;
    #13:;
    #10:if sp then break else sp:=false;
  else sp:=false;end;
  if not sp then exit(s);

  with AnsiStringBuilder(result,true)do begin
    p0:=1;Len:=length(s);
    repeat
      p1:=pos(#10,s,[],p0);
      if p1=0 then p1:=len+1;
      p2:=p1;
      while(p2>1)and(charn(s,p2-1)in[#13,' '])do dec(p2);
      if p2>p0 then AddBlock((@s[p0])^,p2-p0);
      if p1<=len then AddStr(#13#10);
      p0:=p1+1;
    until p1>Len;
  end;
end;

function MessageBox(const Text, Caption: String; Flags: Longint): Integer;
var
  ActiveWindow, TaskActiveWindow: HWnd;
  MBMonitor, AppMonitor: HMonitor;
  MonInfo: TMonitorInfo;
  Rect: TRect;
  FocusState: TFocusState;
  WindowList: TTaskWindowList;
begin
  ActiveWindow:=0;
  MBMonitor:=0;
  AppMonitor:=0;
  FocusState:=nil;
  WindowList:=nil;


  if not(csDestroying in Application.ComponentState)then begin
    ActiveWindow := Application.ActiveFormHandle;
    if ActiveWindow = 0 then
      TaskActiveWindow := Application.Handle
    else
      TaskActiveWindow := ActiveWindow;
    MBMonitor := MonitorFromWindow(ActiveWindow, MONITOR_DEFAULTTONEAREST);
    AppMonitor := MonitorFromWindow(Application.Handle, MONITOR_DEFAULTTONEAREST);
    if MBMonitor <> AppMonitor then
    begin
      MonInfo.cbSize := Sizeof(TMonitorInfo);
      GetMonitorInfo(MBMonitor, {$IFNDEF CLR}@{$ENDIF}MonInfo);
      GetWindowRect(Application.Handle, Rect);
      SetWindowPos(Application.Handle, 0,
        MonInfo.rcMonitor.Left + ((MonInfo.rcMonitor.Right - MonInfo.rcMonitor.Left) div 2),
        MonInfo.rcMonitor.Top + ((MonInfo.rcMonitor.Bottom - MonInfo.rcMonitor.Top) div 2),
        0, 0, SWP_NOACTIVATE or SWP_NOREDRAW or SWP_NOSIZE or SWP_NOZORDER);
    end;
    WindowList := DisableTaskWindows(ActiveWindow);
    FocusState := SaveFocusState;
    if Application.UseRightToLeftReading then Flags := Flags or MB_RTLREADING;
  end else
    TaskActiveWindow:=0;

  try
    Result := Windows.MessageBox(TaskActiveWindow, PChar(Text), PChar(Caption), Flags);
  finally

    if not(csDestroying in Application.ComponentState)then begin
      if MBMonitor <> AppMonitor then
        SetWindowPos(Application.Handle, 0,
          Rect.Left + ((Rect.Right - Rect.Left) div 2),
          Rect.Top + ((Rect.Bottom - Rect.Top) div 2),
          0, 0, SWP_NOACTIVATE or SWP_NOREDRAW or SWP_NOSIZE or SWP_NOZORDER);
      EnableTaskWindows(WindowList);
      SetActiveWindow(ActiveWindow);
      RestoreFocusState(FocusState);
    end;

  end;
end;


function WordAt(const n:ansistring;p:integer;const extendedChars:boolean=true):ansistring;
var i:integer;
    wordset:PSetOfChar;
begin
  if extendedChars then wordset:=@wordsetExtended
                   else wordset:=@wordsetSimple;
  WordStart:=p;WordLen:=0;
  if(p<=0)or(p>Length(n))then exit('');
  if not(CharN(n,p)in wordset^)then dec(p);//megprobalja egyel balább
  if not(CharN(n,p)in wordset^)then exit;
  for i:=p to length(n)do if charmapEnglishUpper[n[i]]in wordset^ then inc(wordLen) else break;
  for i:=p-1 downto 1 do if charmapEnglishUpper[n[i]]in wordset^ then begin wordstart:=i;inc(wordlen)end else break;
  result:=Copy(n,WordStart,WordLen);
end;

//******************************************************************************
//Get HDD Serial
//source http://www.delphipages.com/forum/showthread.php?t=89413
function GetIdeDiskSerialNumber: AnsiString;
type
  TSrbIoControl = packed record
    HeaderLength : ULONG;
    Signature : Array[0..7] of AnsiChar;
    Timeout : ULONG;
    ControlCode : ULONG;
    ReturnCode : ULONG;
    Length : ULONG;
  end;
  SRB_IO_CONTROL = TSrbIoControl;
  PSrbIoControl = ^TSrbIoControl;

  TIDERegs = packed record
    bFeaturesReg : Byte; // Used for specifying SMART "commands".
    bSectorCountReg : Byte; // IDE sector count register
    bSectorNumberReg : Byte; // IDE sector number register
    bCylLowReg : Byte; // IDE low order cylinder value
    bCylHighReg : Byte; // IDE high order cylinder value
    bDriveHeadReg : Byte; // IDE drive/head register
    bCommandReg : Byte; // Actual IDE command.
    bReserved : Byte; // reserved for future use. Must be zero.
  end;
  IDEREGS = TIDERegs;
  PIDERegs = ^TIDERegs;

  TSendCmdInParams = packed record
    cBufferSize : DWORD; // Buffer size in bytes
    irDriveRegs : TIDERegs; // Structure with drive register values.
    bDriveNumber : Byte; // Physical drive number to send command to (0,1,2,3).
    bReserved : Array[0..2] of Byte; // Reserved for future expansion.
    dwReserved : Array[0..3] of DWORD; // For future use.
    bBuffer : Array[0..0] of Byte; // Input buffer.
  end;
  SENDCMDINPARAMS = TSendCmdInParams;
  PSendCmdInParams = ^TSendCmdInParams;

  TIdSector = packed record
    wGenConfig : Word;
    wNumCyls : Word;
    wReserved : Word;
    wNumHeads : Word;
    wBytesPerTrack : Word;
    wBytesPerSector : Word;
    wSectorsPerTrack : Word;
    wVendorUnique : Array[0..2] of Word;
    sSerialNumber : Array[0..19] of AnsiChar;
    wBufferType : Word;
    wBufferSize : Word;
    wECCSize : Word;
    sFirmwareRev : Array[0..7] of AnsiChar;
    sModelNumber : Array[0..39] of AnsiChar;
    wMoreVendorUnique : Word;
    wDoubleWordIO : Word;
    wCapabilities : Word;
    wReserved1 : Word;
    wPIOTiming : Word;
    wDMATiming : Word;
    wBS : Word;
    wNumCurrentCyls : Word;
    wNumCurrentHeads : Word;
    wNumCurrentSectorsPerTrack : Word;
    ulCurrentSectorCapacity : ULONG;
    wMultSectorStuff : Word;
    ulTotalAddressableSectors : ULONG;
    wSingleWordDMA : Word;
    wMultiWordDMA : Word;
    bReserved : Array[0..127] of Byte;
  end;
  PIdSector = ^TIdSector;

const
  IDE_ID_FUNCTION = $EC;
  IDENTIFY_BUFFER_SIZE = 512;
  DFP_RECEIVE_DRIVE_DATA = $0007c088;
  IOCTL_SCSI_MINIPORT = $0004d008;
  IOCTL_SCSI_MINIPORT_IDENTIFY = $001b0501;
  DataSize = sizeof(TSendCmdInParams)-1+IDENTIFY_BUFFER_SIZE;
  BufferSize = SizeOf(SRB_IO_CONTROL)+DataSize;
  W9xBufferSize = IDENTIFY_BUFFER_SIZE+16;

var
  hDevice : THandle;
  cbBytesReturned : DWORD;
  pInData : PSendCmdInParams;
  pOutData : Pointer; // PSendCmdInParams;
  Buffer : Array[0..BufferSize-1] of Byte;
  srbControl : TSrbIoControl absolute Buffer;

  procedure ChangeByteOrder( var Data; Size : Integer );
  var ptr : PAnsiChar;
      i : Integer;
      c : AnsiChar;
  begin
    ptr := @Data;
    for i := 0 to (Size shr 1)-1 do begin
      c := ptr^;
      ptr^ := (ptr+1)^;
      (ptr+1)^ := c;
      Inc(ptr,2);
    end;
  end;

begin
  Result := '';
  FillChar(Buffer,BufferSize,#0);
  if Win32Platform=VER_PLATFORM_WIN32_NT then begin // Windows NT, Windows 2000
    // Get SCSI port handle
    hDevice := CreateFileA( '\\.\Scsi0:', GENERIC_READ or GENERIC_WRITE,
      FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0 );
    if hDevice=INVALID_HANDLE_VALUE then Exit;
    try
      srbControl.HeaderLength := SizeOf(SRB_IO_CONTROL);
      srbControl.Signature:='SCSIDISK';
      srbControl.Timeout := 2;
      srbControl.Length := DataSize;
      srbControl.ControlCode := IOCTL_SCSI_MINIPORT_IDENTIFY;
      pInData := PSendCmdInParams(PAnsiChar(@Buffer)+SizeOf(SRB_IO_CONTROL));
      pOutData := pInData;
      with pInData^ do begin
        cBufferSize := IDENTIFY_BUFFER_SIZE;
        bDriveNumber := 0;
        with irDriveRegs do begin
          bFeaturesReg := 0;
          bSectorCountReg := 1;
          bSectorNumberReg := 1;
          bCylLowReg := 0;
          bCylHighReg := 0;
          bDriveHeadReg := $A0;
          bCommandReg := IDE_ID_FUNCTION;
        end;
      end;
      if not DeviceIoControl( hDevice, IOCTL_SCSI_MINIPORT, @Buffer, BufferSize, @Buffer, BufferSize, cbBytesReturned, nil ) then Exit;
    finally
      CloseHandle(hDevice);
    end;
  end else begin // Windows 95 OSR2, Windows 98
    hDevice := CreateFileA( '\\.\SMARTVSD', 0, 0, nil, CREATE_NEW, 0, 0 );
    if hDevice=INVALID_HANDLE_VALUE then Exit;
    try
      pInData := PSendCmdInParams(@Buffer);
      pOutData := PAnsiChar(@pInData^.bBuffer);
      with pInData^ do begin
        cBufferSize := IDENTIFY_BUFFER_SIZE;
        bDriveNumber := 0;
        with irDriveRegs do begin
          bFeaturesReg := 0;
          bSectorCountReg := 1;
          bSectorNumberReg := 1;
          bCylLowReg := 0;
          bCylHighReg := 0;
          bDriveHeadReg := $A0;
          bCommandReg := IDE_ID_FUNCTION;
        end;
      end;
      if not DeviceIoControl( hDevice, DFP_RECEIVE_DRIVE_DATA, pInData, SizeOf(TSendCmdInParams)-1, pOutData, W9xBufferSize, cbBytesReturned, nil ) then Exit;
    finally
      CloseHandle(hDevice);
    end;
  end;
  with PIdSector(PAnsiChar(pOutData)+16)^ do begin
    ChangeByteOrder(sSerialNumber,SizeOf(sSerialNumber ));
    Result:=sSerialNumber;
    Trim(Result);
  end;
end;

function GetDeviceHandle( sDeviceName : AnsiString ) : THandle;
begin
  Result := CreateFileA( PAnsiChar('\\.\'+sDeviceName), GENERIC_READ or GENERIC_WRITE,
  FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0 );
end;

function ScsiHddSerialNumber: AnsiString;
{$ALIGN ON}
type
  TScsiPassThrough = record
    Length : Word;
    ScsiStatus : Byte;
    PathId : Byte;
    TargetId : Byte;
    Lun : Byte;
    CdbLength : Byte;
    SenseInfoLength : Byte;
    DataIn : Byte;
    DataTransferLength : ULONG;
    TimeOutValue : ULONG;
    DataBufferOffset : DWORD;
    SenseInfoOffset : ULONG;
    Cdb : Array[0..15] of Byte;
  end;
  TScsiPassThroughWithBuffers = record
    spt : TScsiPassThrough;
    bSenseBuf : Array[0..31] of Byte;
    bDataBuf : Array[0..191] of Byte;
  end;
//{ALIGN OFF}
var
  DeviceHandle : THandle;
  dwReturned : DWORD;
  len : DWORD;
  Buffer : Array[0..SizeOf(TScsiPassThroughWithBuffers)+SizeOf(TScsiPassThrough)-1] of Byte;
  sptwb : TScsiPassThroughWithBuffers absolute Buffer;
begin
  Result := '';
  DeviceHandle := GetDeviceHandle('C:');
  If DeviceHandle <> INVALID_HANDLE_VALUE Then Begin
    Try
      FillChar(Buffer,SizeOf(Buffer),#0);
      with sptwb.spt do begin
        Length := SizeOf(TScsiPassThrough);
        CdbLength := 6; // CDB6GENERIC_LENGTH
        SenseInfoLength := 24;
        DataIn := 1; // SCSI_IOCTL_DATA_IN
        DataTransferLength := 192;
        TimeOutValue := 2;
        DataBufferOffset := PAnsiChar(@sptwb.bDataBuf)-PAnsiChar(@sptwb);
        SenseInfoOffset := PAnsiChar(@sptwb.bSenseBuf)-PAnsiChar(@sptwb);
        Cdb[0] := $12; // OperationCode := SCSIOP_INQUIRY;
        Cdb[1] := $01; // Flags := CDB_INQUIRY_EVPD; Vital product data
        Cdb[2] := $80; // PageCode Unit serial number
        Cdb[4] := 192; // AllocationLength
      end;
      len := sptwb.spt.DataBufferOffset+sptwb.spt.DataTransferLength;
      if DeviceIoControl( DeviceHandle, $0004d004, @sptwb, SizeOf(TScsiPassThrough), @sptwb, len, dwReturned, nil ) and ((PAnsiChar(@sptwb.bDataBuf)+1)^=#$80) then

      //SetString( Result, PAnsiChar(@sptwb.bDataBuf)+4, Ord((PAnsiChar(@sptwb.bDataBuf)+3)^) );
      setlength(result,Ord((PAnsiChar(@sptwb.bDataBuf)+3)^));
      if result<>'' then move((PAnsiChar(@sptwb.bDataBuf)+4)^,result[1],length(result));
      Trim(Result);
    Finally
      CloseHandle(DeviceHandle);
    End;
  End;
end;

function GetLogicalSerial: AnsiString;
var
  D_Id, Tmp1, Tmp2: DWord;
begin
  GetVolumeInformationA(PAnsiChar('c:\'), Nil, 0, @D_Id, Tmp1, Tmp2, Nil, 0);
  Result := Format('%8.8x', [D_Id]);
end;

function GetHddSerial: AnsiString;
begin
  result:=ScsiHddSerialNumber;if result<>'' then exit;
  result:=GetIdeDiskSerialNumber;if result<>'' then exit;
//  result:=GetLogicalSerial;if result<>'' then exit;
end;

function CanGetHddSerial(Prepare: Boolean): Integer;
var
  WinPath: Array[0..250] Of Char;
  CopyFrom: AnsiString;
  CopyTo: AnsiString;
begin
// Results:
// 1 - Can get HDD Serial
// 0 - Can get HDD Serial after reboot
// -1 - Can NOT get HDD Serial

  If Win32Platform = VER_PLATFORM_WIN32_NT Then
    Result := 1
  Else Begin
    If ScsiHddSerialNumber <> '' Then
      Result := 1
    Else Begin
      GetWindowsDirectory(WinPath, SizeOf(WinPath));
      CopyTo := WinPath + '\System\Iosubsys\Smartvsd.vxd';
      If FileExists(CopyTo) Then
        Result := 1
      Else Begin
        CopyFrom := WinPath + '\System\Smartvsd.vxd';
        If Not FileExists(CopyFrom) Then
          Result := -1
        Else Begin
          If Prepare Then Begin
            If CopyFile(PChar(String(CopyFrom)), PChar(String(CopyTo)), False) Then
              Result := 0
            Else
              Result := -1;
          End Else
            Result := -1;
        End;
      End;
    End;
  End;
end;

//******************************************************************************
class operator TMyPoint.implicit(const a:TPoint):TMyPoint;begin result.x:=a.X;result.y:=a.Y end;
class operator TMyPoint.implicit(const a:TMyPoint):TPoint;begin result.x:=a.X;result.y:=a.Y end;
class operator TMyPoint.negative(const a:TMyPoint):TMyPoint;begin result.x:=-a.X;result.y:=-a.Y end;
class operator TMyPoint.add(const a,b:TMyPoint):TMyPoint;begin result.x:=a.x+b.x;result.y:=a.y+b.y end;
class operator TMyPoint.subtract(const a,b:TMyPoint):TMyPoint;begin result.x:=a.x-b.x;result.y:=a.y-b.y end;
class operator TMyPoint.multiply(const a,b:TMyPoint):TMyPoint;begin result.x:=a.x*b.x;result.y:=a.y*b.y end;
class operator TMyPoint.multiply(const a:TMyPoint;const b:single):TMyPoint;begin result.x:=trunc(a.x*b);result.y:=trunc(a.y*b)end;
class operator TMyPoint.divide(const a,b:TMyPoint):TMyPoint;begin result.x:=trunc(a.x/b.x);result.y:=trunc(a.y/b.y) end;
class operator TMyPoint.divide(const a:TMyPoint;const b:single):TMyPoint;begin result.x:=trunc(a.x/b);result.y:=trunc(a.y/b)end;
class operator TMyPoint.intdivide(const a:TMyPoint;const b:integer):TMyPoint;begin result.x:=a.x div b;result.y:=a.y div b end;
class operator TMyPoint.RightShift(const a:TMyPoint;const b:integer):TMyPoint;begin result.x:=a.x shr b;result.y:=a.y shr b end;
class operator TMyPoint.LeftShift(const a:TMyPoint;const b:integer):TMyPoint;begin result.x:=a.x shl b;result.y:=a.y shl b end;
class operator TMyPoint.in(const a:TMyPoint;const b:TRect):boolean;begin result:=(a.x>=b.Left)and(a.y>=b.Top)and(a.x<b.Right)and(a.y<b.Bottom)end;
class operator TMyPoint.Equal(const a,b:TMyPoint):boolean;begin result:=(a.x=b.x)and(a.y=b.y)end;
class operator TMyPoint.NotEqual(const a,b:TMyPoint):boolean;begin result:=(a.x<>b.x)or(a.y<>b.y)end;


class operator TMyPoint.add(const a:TRect;const b:TMyPoint):TRect;begin result.TopLeft:=result.TopLeft+b;result.BottomRight:=result.BottomRight+b;end;
class operator TMyPoint.subtract(const a:TRect;const b:TMyPoint):TRect;begin result.TopLeft:=result.TopLeft-b;result.BottomRight:=result.BottomRight-b;end;

function Pt(const x,y:Integer):TMyPoint;overload;begin result.x:=x;result.y:=y end;
function Pt(const a:TPoint):TMyPoint;overload;begin result.x:=a.x;result.y:=a.y end;

function RandomF:single;
begin
  Random;
  Result:=RandSeed*(1/$80000000);
end;

procedure RandomGaussPair(out y1,y2:single);
var x1,x2,w:single;
begin
  repeat
    x1:=RandomF;
    x2:=RandomF;
    w:=x1*x1+x2*x2;
  until w<1;
  w:=sqrt((-2*ln(w))/w);
  y1:=x1*w;
  y2:=x2*w;
end;

function RandomGauss:single;
begin
  RandomGaussPair(result,result);
end;

const
  SystemBasicInformation = 0;
  SystemPerformanceInformation = 2;
  SystemTimeInformation = 3;

var
  NtQuerySystemInformation: function(infoClass: DWORD; buffer: Pointer; bufSize: DWORD; returnSize: PDword): DWORD; stdcall = nil;

function SysInfo:TSystem_Basic_Information;
begin
  if @NtQuerySystemInformation = nil then
    NtQuerySystemInformation := GetProcAddress(GetModuleHandle('ntdll.dll'),
      'NtQuerySystemInformation');

  if 0<>NtQuerySystemInformation(SystemBasicInformation, @result, SizeOf(result), nil)then
    fillchar(result,sizeof(result),0);
end;

procedure ParalellFor(const st,en:integer;const proc:TProc<integer>);
var threads:array of THetThread;
    i,j:integer;
    index:integer;
begin
  index:=st;
  if index>en then exit;
  try
    setlength(threads,max(0,SysInfo.bKeNumberProcessors-1));
    for i:=0 to high(Threads)do
      Threads[i]:=THetThread.Create(nil,0,procedure(t:THetThread)
      var actIndex:integer;
      begin
        actIndex:=InterlockedIncrement(index)-1;
        if actIndex<=en then
          proc(actIndex)
        else
          t.Terminate;
      end);

    while true do begin//main loop
      j:=InterlockedIncrement(index)-1;
      if j<=en then
        proc(j)
      else
        break;
    end;
  finally
    for i:=0 to high(threads)do begin
      threads[i].Free;
    end;
  end;
end;

procedure LaunchThread(const proc:TProc);
begin
  THetThread.Create(Application,0,procedure(t:THetThread)begin
    proc;
    t.Thread.FreeOnTerminate:=true;
    t.Terminate;
  end);
end;

function Exec(const cmd,path:string;const hidden:boolean):integer;
var
proc_info: TProcessInformation;
startinfo: TStartupInfoW;
ExitCode: cardinal;
begin
  // Initialize the structures
  Fillchar(proc_info, sizeof(proc_info), 0);
  Fillchar(startinfo, sizeof(startinfo), 0);
  startinfo.cb := sizeof(startinfo);

  if hidden then begin
    startinfo.wShowWindow := SW_HIDE;
    startinfo.dwFlags := STARTF_USESHOWWINDOW;
  end;

  // Attempts to create the process
  if CreateProcessW(nil, PChar(WideString(cmd)), nil,
      nil, false, NORMAL_PRIORITY_CLASS, nil, nil,
       startinfo, proc_info) <> False then begin
    // The process has been successfully created
    // No let's wait till it ends...
    WaitForSingleObject(proc_info.hProcess, INFINITE);
    // Process has finished. Now we should close it.
    GetExitCodeProcess(proc_info.hProcess, ExitCode);  // Optional
    CloseHandle(proc_info.hThread);
    CloseHandle(proc_info.hProcess);
    result:=ExitCode;
  end else begin
    result:=-1;
  end;//if
end;

function Num2Roman(n:integer):ansistring;
const
  str:array[0..12]of ansistring=('M','CM','D','CD','C','XC','L','XL','X','IX','V','IV','I');
  min:array[0..12]of integer=(  1000, 900,500, 400,100,  90, 50,  40, 10,   9,  5,   4,  1);
var
  i:integer;
begin
  result:='';
  for i:=0 to high(min)do
    while n>=min[i] do begin
      result:=result+str[i];
      dec(n,min[i]);
    end;
end;

function Num2Hun(n:integer):ansistring;
const
  egyes:array[0..9]of string[10]=('','egy','kettô','három','négy','öt','hat','hét','nyolc','kilenc');
  tizesnulla:array[0..9]of string[10]=('','tíz','húsz','harminc','negyven','ötven','hatvan','hetven','nyolcvan','kilencven');
  tizes:array[0..9]of string[10]=('','tizen','huszon','harminc','negyven','ötven','hatvan','hetven','nyolcvan','kilencven');
  millak:array[0..7]of string[16]=('','ezer','millió','milliárd','billió','billiárd','trillió','trilliárd');
var s,s1:string;i:integer;
    minusz:boolean;
begin
  minusz:=n<0;
  if minusz then n:=-n;
  s:=inttostr(n);s1:='';
  for i:=1 to length(s)do begin
    case(length(s)-i) mod 3 of
      0:begin
          s1:=s1+egyes[byte(s[i])-48];
          if rightstr(s1,1)<>'-' then begin
            s1:=s1+millak[(length(s)-i) div 3];
            if((length(s)>4)or(length(s)=4)and(s[1]>'1'))and(length(s)>i)then s1:=s1+'-';
          end;
        end;
      1:if(i+1>length(s))or(s[i+1]='0')then
          s1:=s1+tizesnulla[byte(s[i])-48]
        else
          s1:=s1+tizes[byte(s[i])-48];
      2:begin
          if s[i]<>'0' then s1:=s1+egyes[byte(s[i])-48]+'száz';
        end;
    end;
  end;
  if s1='' then s1:='nulla';
  if minusz then s1:='mínusz '+s1;
  if rightstr(s1,1)='-' then setlength(s1,length(s1)-1);
  num2hun:=s1;
end;

function Nevelo(const s:ansistring;nagybetuvel:boolean=false):ansistring;
begin
  if s='' then begin result:='';exit;end;
  if charmapEnglishUpper[s[1]] in ['A','E','I','O','U'] then result:='az' else result:='a';
  if nagybetuvel then result[1]:=uc(result[1]);
end;

function BinToHex(const s:rawbytestring):rawbytestring;overload;
begin
  if s='' then exit('');
  setlength(result,length(s)*2);
  classes.BinToHex(PAnsiChar(s),PAnsiChar(result),length(s));
end;

function HexToBin(const s:rawbytestring):rawbytestring;overload;
begin
  SetLength(result,length(s)div 2);
  if result='' then exit;
  classes.HexToBin(PAnsiChar(s),PAnsiChar(result),length(result));
end;

function TControlHelper.ClientToScreen(const r:TRect):TRect;
begin
  result.TopLeft    :=ClientToScreen(r.TopLeft    );
  result.BottomRight:=ClientToScreen(r.BottomRight);
end;

function ClassIs(const a,b:TClass):boolean;
begin
  if(a=nil)or(b=nil)then result:=false
  else if a=b then result:=true
  else result:=ClassIs(a.ClassParent,b);
end;


function StrToHexDump(const src:ansistring):ansistring;
  const hdr:ansistring=
   '          0  1  2  3   4  5  6  7   8  9  A  B   C  D  E  F   0123456789ABCDEF'#13#10;
  function MakeLine(n:integer):ansistring;
  //         111111111122222222223333333333444444444455555555556666666666777777777
  //123456789012345678901234567890123456789012345678901234567890123456789012345678
  //00000000  00 00 00 00  00 00 00 00  00 00 00 00  00 00 00 00  ................
  const base:ansistring=
   '                                                                              '#13#10;
    procedure Overwrite(pos:integer;const s:ansistring);
    var i:integer;
    begin
      for i:=pos to pos+length(s)-1do
        result[i]:=s[i-pos+1];
    end;

  var i,j,k:integer;
      ch:ansichar;
  begin
    result:=base;
    Overwrite(1,inttohex(n shl 4,8));
    j:=0;k:=0;for i:=n shl 4+1 to min(n shl 4+1+15,length(src))do begin
      ch:=src[i];
      Overwrite(11+j*3+k,inttohex(ord(ch),2));
      if ch in[#0..#31] then ch:='.';
      overwrite(63+j,ch);
      inc(j);
      if(j and 3)=0 then inc(k);
    end;
  end;

var linecount,i:integer;
begin with Ansistringbuilder(result,true)do begin
  AddStr('  '+hdr);
  lineCount:=(length(src)+15)div 16;
  if lineCount=0 then LineCount:=1;
  for i:=0 to LineCount-1 do
    AddStr('  '+MakeLine(i));
end;end;

function ToPas(const S:ansistring;const SplitLines:integer=0):ansistring;
var inStr:boolean;
    c:ansichar;
    bldr:IAnsiStringBuilder;
    prevLen:integer;

  procedure StepIn;begin if not inStr then begin inStr:=not inStr;bldr.AddChar('''');end;end;
  procedure StepOut;begin if inStr then begin inStr:=not inStr;bldr.AddChar('''');end;end;

begin bldr:=AnsiStringBuilder(result,True);with bldr do begin
  if s='' then
    AddStr('''''')
  else begin
    inStr:=false;
    prevlen:=0;
    for c in s do begin
      if(SplitLines>0)and(GetLen-prevLen>SplitLines)then begin
        stepOut;AddStr('+'#13#10);
        prevLen:=getLen;
      end;
      if(c<' ')or(c='''')then begin
        StepOut;
        AddStr('#'+IntToStr(ord(c)));
      end else begin
        stepIn;
        AddChar(c);
      end;
    end;
    StepOut;
  end;
end;end;

function ToPas(const v:integer):ansistring;begin result:=IntToStr(v)end;

function ToPas(const v:int64):ansistring;begin result:=IntToStr(v)end;

function ToPas(const v:single):ansistring;
var o:char;
begin
  o:=FormatSettings.DecimalSeparator; FormatSettings.DecimalSeparator:='.';
  Result:=FloatToStrF(v,ffGeneral,7,0);
  FormatSettings.DecimalSeparator:=o;
end;

function ToPas(const v:double):ansistring;
var o:char;
begin
  o:=FormatSettings.DecimalSeparator; FormatSettings.DecimalSeparator:='.';
  Result:=FloatToStrF(v,ffGeneral,15,0);
  FormatSettings.DecimalSeparator:=o;
end;

function ToPas(const v:extended):ansistring;
var o:char;
begin
  o:=FormatSettings.DecimalSeparator; FormatSettings.DecimalSeparator:='.';
  Result:=FloatToStrF(v,ffGeneral,18,0);
  FormatSettings.DecimalSeparator:=o;
end;

function TimeToPas(const v:TTime;const full:boolean):ansistring;
var h,m,s,z:word;
    d:integer;
begin
  d:=trunc(v);
  DecodeTime(v-d,h,m,s,z);
  result:=format('%d:%.2d',[d*24+h,m]);
  if full or(s<>0)or(m<>0)then begin
    result:=result+format(':%.2d',[s]);
    if full or(m<>0)then
      result:=result+format('.%.3d',[z]);
  end;
end;

function DateToPas(const v:TDate):ansistring;
var y,m,d:word;
begin
  if v<=0 then exit('0');
  DecodeDate(v,y,m,d);
  result:=format('%d.%.2d.%.2d',[y,m,d]);
end;

function DateTimeToPas(const v:TDateTime;const full:boolean):ansistring;overload;
var d:integer;
    t:double;
begin
  if v<=0 then exit('0');
  d:=trunc(v); t:=v-d;
  result:=DateToPas(d);
  if full or(t>0) then
    result:=result+' '+TimeToPas(t,full);
end;

function VariantToPas(const V:Variant;const SplitLines:integer=0):ansistring;
begin
  if(TVarData(V).VType and varTypeMask)<=varInt64{aka varlast} then result:=ToStr(V)
                                                else result:=ToPas(AnsiString(V),SplitLines);
end;

function ToSql(const src:ansistring):ansistring;
var i:integer;
begin
  result:=replacef(#13#10,'\n',src,[roAll]);
  for i:=1 to length(result)do case result[i] of
    #0..#31:result[i]:=' ';
  end;
  replacef('''','''''',result,[roAll]);
  result:=''''+result+'''';
end;

function TDeltaTime.Update:double;
var tAct:int64;
begin
  QueryPerformanceFrequency(tFreq);
  QueryPerformanceCounter(tAct);
  if tLast=0 then Delta:=0.001
             else Delta:=(tAct-tLast)/tFreq;
  result:=Delta;
  tLast:=tAct;
end;

procedure TDeltaTime.Start;
begin
  FillChar(self,sizeof(self),0);
  Update;
end;

function TDeltaTime.SecStr:ansistring;       begin result:=format('%.3f',[Delta]);end;
function TDeltaTime.MilliSecStr:ansistring;  begin result:=format('%.3f',[Delta*1e-3]);end;
function TDeltaTime.MicroSecStr:ansistring;  begin result:=format('%.3f',[Delta*1e-6]);end;
function TDeltaTime.NanoSecStr:ansistring;   begin result:=format('%.3f',[Delta*1e-6]);end;

function TCustomFormHelper.GetFullScreen:boolean;
begin
  result:=WindowState=wsMaximized;
end;

procedure TCustomFormHelper.SetFullScreen(const Value:boolean);
begin
  if Value=FullScreen then exit;
  if Value then begin
    WindowState:=wsMaximized;
    BorderStyle:=bsNone;
    FormStyle:=fsStayOnTop;
  end else begin
    BorderStyle:=bsSizeable;
    WindowState:=wsNormal;
    FormStyle:=fsNormal;
  end;
end;

procedure TCustomFormHelper.ToggleFullScreen;
begin
  FullScreen:=not FullScreen;
end;

function TCustomFormHelper.GetWindowPlacement:AnsiString;
var wp:TWindowPlacement;
begin
  wp.length:=SizeOf(wp);
  if windows.GetWindowPlacement(Handle,@wp)then
    with wp,rcNormalPosition do result:=format('%d,%d,%d,%d,%d',[showCmd,Left,Top,Right,Bottom])
  else result:='';
end;

function TryStrToIntArray(const sa:TArray<AnsiString>;out ia:TArray<integer>):boolean;
var i:integer;
begin
  SetLength(ia,length(sa));
  for i:=0 to Length(sa)-1 do
    if not TryStrToInt(sa[i],ia[i]) then begin setlength(ia,0);exit(false);end;
  result:=true;
end;

procedure TCustomFormHelper.SetWindowPlacement(const Value:AnsiString);
var a:TArray<integer>;
    wp:TWindowPlacement;
begin
  if TryStrToIntArray(ListSplit(Value,','),a)and(length(a)>=5)then begin
    wp.length:=SizeOf(wp);
    if windows.GetWindowPlacement(Handle,@wp)then begin
      with wp,rcNormalPosition do begin
        showCmd:=a[0];Left:=a[1];Top:=a[2];Right:=a[3];Bottom:=a[4];end;
      windows.SetWindowPlacement(Handle,wp);
    end;
  end;
end;

function CheckAndClear(var b:boolean):boolean;
begin
  result:=b;if result then b:=false;
end;

function CheckAndSet(var b:boolean):boolean;
begin
  result:=not b;if result then b:=true;
end;

function CheckAndSet(var b:boolean;const bnew:boolean):boolean;
begin
  result:=b<>bNew;b:=bNew;
end;

function CheckAndSet(var b:integer;const bnew:integer):boolean;
begin
  result:=b<>bNew;b:=bNew;
end;

function CheckAndSet(var b:single;const bnew:single):boolean;
begin
  result:=b<>bNew;b:=bNew;
end;

function CheckAndSet(var s:ansistring;const s2:ansistring):boolean;
begin
  result:=cmp(s,s2)<>0;if result then s:=s2;
end;

function MyDateToStr(const date:TDateTime):ansistring;
var y,m,d:word;
begin
  if date<=0 then
    result:=''
  else begin
    DecodeDate(date,y,m,d);
//    if y>=2000 then y:=y-2000;
    result:=Format('%.2d.%.2d.%.2d',[y,m,d])
  end;
end;

function MyStrToDate(const s:ansistring):TDateTime;
var y,m,d:integer;
begin
  y:=StrToIntDef(listitem(s,0,'.'),0);
  m:=StrToIntDef(listitem(s,1,'.'),0);
  d:=StrToIntDef(listitem(s,2,'.'),0);
  if y<2000 then y:=y+2000;
  if not TryEncodeDate(y,m,d,result)then
    result:=0;
end;

function MyTimeToStr(const time:TDateTime):ansistring;
var h,m,s,ms:word;
begin
  if time<0 then
    result:=''
  else begin
    DecodeTime(Time,h,m,s,ms);
    if(Time>=1)and(Time<2)then
      h:=h+24;
    if(s=0)then
      if(ms=0)then result:=Format('%.2d:%.2d',[h,m])
              else result:=Format('%.2d:%.2d:%.2d',[h,m,s])
           else result:=Format('%.2d:%.2d:%.2d.%3d',[h,m,s,ms]);
  end;
end;

function MyStrToTime(const str:ansistring):TDateTime;
var h,m,s,ms:integer;
    ssec:ansistring;
begin
  h:=StrToIntDef(listitem(str,0,':'),-1);
  m:=StrToIntDef(listitem(str,1,':'),-1);
  ssec:=listitem(str,2,':');
  s:=StrToIntDef(listitem(ssec,0,'.'),0);
  ms:=StrToIntDef(listitem(ssec,1,'.'),0);
  if not TryEncodeTime(h,m,s,ms,result)then
    result:=-0.00000001;
  if h>=24 then
    result:=1;
end;

function DecodeRectAlignment(const def:ansistring):TRectAlignment;
var i:integer;
begin
  with result do begin
    hAlign:=0;vAlign:=0;
    hShrink:=false;vShrink:=false;
    hEnlarge:=false;vEnlarge:=false;
    proportional:=false;
    for i:=1 to length(def)do case uc(def[i])of
      'T':vAlign:=-1;
      'B':vAlign:=1;
      'L':hAlign:=-1;
      'R':hAlign:=1;
      'S':case uc(charn(def,i-1))of
        'H':hShrink:=true;
        'V':vShrink:=true;
      end;
      'E':case uc(charn(def,i-1))of
        'H':hEnlarge:=true;
        'V':vEnlarge:=true;
      end;
      'P':proportional:=true;
    end;
  end;
end;

function AlignRect(const rImage,rCanvas:TRect;const RectAlignment:TRectAlignment):TRect;overload;

  procedure alignOne(var dst1,dst2,src1,src2:integer;shrink,enlarge:boolean;align:integer);
  begin
    if shrink and enlarge then exit;
    if not shrink and(dst2-dst1<src2-src1)then begin{a bmp nagyobb es nincs kicsinyites}
      case align of
        -1:src2:=src1+dst2-dst1;
        0:begin src1:=(src1+src2)div 2-(dst2-dst1)div 2;src2:=src1+dst2-dst1;end;
        1:src1:=src2-(dst2-dst1);
      end;
    end;
    if not enlarge and(dst2-dst1>src2-src1)then begin{a bmp kisebb es nincs nagyitas}
      case align of
        -1:dst2:=dst1+src2-src1;
        0:begin dst1:=(dst1+dst2)div 2-(src2-src1)div 2;dst2:=dst1+src2-src1;end;
        1:dst1:=dst2-(src2-src1);
      end;
    end;
  end;

var rsrc,rdst,rdst2:trect;
    r1,r2:double;
    a1,a2,b1,b2:integer;
begin with RectAlignment do begin
  rdst:=rCanvas;
  rdst2:=rdst;
  rsrc:=rImage;
  alignOne(rdst2.left,rdst2.right,rsrc.left,rsrc.Right,hShrink,hEnlarge,hAlign);
  alignOne(rdst2.Top,rdst2.Bottom,rsrc.Top,rsrc.Bottom,vShrink,vEnlarge,vAlign);
  if proportional then begin
    a1:=(rdst2.Right-rdst2.Left);b1:=(rdst2.Bottom-rdst2.Top);
    a2:=rImage.Right-rImage.left;b2:=rImage.Bottom-rImage.Top;
    r1:=a1/max(1,b1);r2:=a2/max(1,b2);
    if r1<r2 then begin
      b1:=trunc(a1/maxf(0.000001,r2));
      case vAlign of
        -1:rdst2.top:=rdst.top;
        1:rdst2.top:=rdst.bottom-b1;
        0:rdst2.top:=(rdst.top+rdst.bottom-b1)div 2;
      end;
      rdst2.bottom:=rdst2.top+b1;
      rsrc.Top:=0;rsrc.Bottom:=rImage.Bottom-rImage.Top;
    end else if r1>r2 then begin
      a1:=trunc(b1*r2);
      case hAlign of
        -1:rdst2.left:=rdst.Left;
        1:rdst2.left:=rdst.right-a1;
        0:rdst2.left:=(rdst.left+rdst.right-a1)div 2;
      end;
      rdst2.Right:=rdst2.left+a1;
      rsrc.Left:=0;rsrc.Right:=rImage.Right-rImage.Left;
    end;
  end;
  result:=rdst2;
  //rsrc-t is ki kell!!!!
end;end;

function AlignRect(const rImage,rCanvas:TRect;const RectAlignment:ansistring):TRect;overload;
begin
  result:=AlignRect(rImage,rCanvas,DecodeRectAlignment(RectAlignment));
end;





type
  TOnIdleList=class(TList)
    procedure OnIdle(sender:TObject;var Done:boolean);
  end;

procedure TOnIdleList.OnIdle(sender:TObject;var Done:boolean);
var i:integer;
    lDone:boolean;
begin
  Done:=true;
  for i:=0 to Count-1 do begin
    lDone:=false;
    try
      with TOnIdle(Get(i))do if Assigned(FProc1)then FProc1 else FProc2(lDone);
    except end;
    if not lDone then
      Done:=false;
  end;
end;

var
  OnIdleList:TOnIdleList=nil;

constructor TOnIdle.Create(const AOwner:TComponent);
begin
  inherited Create(AOwner);
  OnIdleList.Add(self);
end;

destructor TOnIdle.Destroy;
begin
  OnIdleList.Remove(Self);
  inherited;
end;

function OnIdle(const AOwner:TComponent;const AProc:TProc):TOnIdle;
begin
  result:=TOnIdle.Create(AOwner);
  result.FProc1:=AProc;

  Application.OnIdle:=OnIdleList.OnIdle;//valami lenyulja...
end;

function OnIdle(const AOwner:TComponent;const AProc:TOnIdleProc):TOnIdle;overload;
begin
  result:=TOnIdle.Create(AOwner);
  result.FProc2:=AProc;

  Application.OnIdle:=OnIdleList.OnIdle;//valami lenyulja...
end;


procedure OnIdleRemove(const AOwner:TComponent);overload;
var i:integer;
begin
  with OnIdleList do for i:=Count-1 downto 0 do with TOnIdle(Get(i))do if Owner=AOwner then Free;
end;


function Unescape(const s:ansistring):ansistring;
var i:integer;
begin with AnsiStringBuilder(result,true)do begin
  i:=1;while i<=length(s)do
    if s[i]='%'then begin
      AddChar(AnsiChar(StrToIntDef('$'+copy(s,i+1,2),32)));
      inc(i,3);
    end else begin
      AddChar(s[i]);
      inc(i);
    end;
end;end;

function Escape(const s:ansistring):ansistring;
const noConv=['A'..'Z', 'a'..'z', '*', '@', '.', '_', '-', '0'..'9', '$', '!', '''', '(', ')', '/'];
var ch:ansichar;
begin with AnsiStringBuilder(result, true)do
  for ch in s do if ch in noConv then AddChar(ch)
                                 else AddStr('%'+inttohex(ord(ch),2));
end;



constructor THetThread.TMyThread.Create(AOwner:THetThread);
begin
  inherited Create(false);{!!!!!!!!!!!!!!}
//  FreeOnTerminate:=True;
  FHetThread:=AOwner;
end;

destructor THetThread.TMyThread.Destroy;
begin
  inherited;
end;

procedure THetThread.TMyThread.CallSynchProc;
begin
  FHetThread.FSynchProc();
end;

procedure THetThread.TMyThread.Execute;

  procedure SynchWait(msec:single);
  var fr,frSleep,TNext:int64;
  begin
    if msec<=0 then exit;
    QueryPerformanceFrequency(fr);
    frSleep:=fr shr 6;//kb 15 ms
    if TLast=0 then QueryPerformanceCounter(TLast);
    TNext:=TLast+trunc(fr*0.001*EnsureRange(msec,0,60000));
    repeat
      QueryPerformanceCounter(TLast);
      if(TLast>=TNext)then break;
      if TNext-TLast>frSleep then sleep(10);
    until Terminated;
  end;

begin
  while not Assigned(FHetThread)and not Terminated do sleep(15);
  while not Terminated do begin
    if Assigned(FHetThread)then
      FHetThread.FThreadProc(FHetThread);
    if FHetThread.FInterval_ms>=0 then
      SynchWait(FHetThread.FInterval_ms)
    else
      Terminate;
  end;
end;

constructor THetThread.Create(AOwner:TComponent;AInterval_ms:single;AProc:THetThreadProc);
begin
  inherited Create(AOwner);
  FInterval_ms:=AInterval_ms;
  FThreadProc:=AProc;
  FThread:=TMyThread.Create(self);
end;

procedure THetThread.Synchronize(const AProc:TProc);
begin
  FSynchProc:=AProc;
  FThread.Synchronize(FThread.CallSynchProc);
end;

procedure THetThread.Terminate;
begin
  FThread.Terminate;
end;

function THetThread.Terminated:boolean;
begin
  result:=FThread.Terminated;
end;

destructor THetThread.Destroy;
begin
  FThread.Terminate;
  FThread.WaitFor;
  FThread.Free;
  inherited;
end;

function FindBetween(const s,st,en:ansistring;const actpos:pinteger=nil;const startpos:pinteger=nil):ansistring;
  procedure SetActPos(n:integer);begin if actpos<>nil then actpos^:=n end;
var i,j,from:integer;
begin
  result:='';
  if actpos=nil then from:=1
                else from:=actpos^;
  i:=pos(st,s,[poIgnoreCase,poReturnEnd],from);
  if startpos<>nil then begin
    if i<=0 then startpos^:=length(s)+1
            else startpos^:=i-length(st);
  end;
  if i>0 then begin
    j:=pos(en,s,[poIgnoreCase],i);
    if j>0 then begin
      result:=copy(s,i,j-i);
      setActPos(j+length(en));
    end else
      setActPos(length(s)+1);
  end else
    setActPos(length(s)+1);
end;

function ReplaceBetween(var s:ansistring;st,en,replacewith:ansistring;const from:integer=1):boolean;
var i,j:integer;
begin
  result:=false;
  i:=pos(st,s,[poIgnoreCase,poReturnEnd],from);
  if i>0 then begin
    j:=pos(en,s,[poIgnoreCase],i);
    if j>0 then begin
      result:=true;
      delete(s,i,j-i);
      insert(replacewith,s,i);
    end;
  end;
end;


type
  TFakeControl=class(TControl);

constructor TMouseState.Create(AOwner:TComponent);
begin
  inherited;
  //attach events
  if Assigned(Owner)and(Owner is TControl)then with TFakeControl(Owner) do begin
    FOldMouseMove       :=OnMouseMove      ;OnMouseMove      :=MyMouseMove     ;
    FOldMouseDown       :=OnMouseDown      ;OnMouseDown      :=MyMouseDown     ;
    FOldMouseUp         :=OnMouseUp        ;OnMouseUp        :=MyMouseUp       ;

    if(Owner<>nil)and(owner is TForm)then begin
      FOldMouseWheel      :=TForm(Owner).OnMouseWheel     ;TForm(Owner).OnMouseWheel     :=MyMouseWheel;
    end;
//    FOldMouseWheelDown  :=OnMouseWheelDown ;OnMouseWheelDown :=MyMouseWheelDown;
//    FOldMouseWheelUp    :=OnMouseWheelUp   ;OnMouseWheelUp   :=MyMouseWheelUp  ;
  end;
end;

destructor TMouseState.Destroy;
begin
  if Assigned(Owner)and not(csDestroying in Owner.ComponentState)
  and(Owner is TControl)then with Owner as TFakeControl do begin
    OnMouseMove       :=FOldMouseMove      ;
    OnMouseDown       :=FOldMouseDown      ;
    OnMouseUp         :=FOldMouseUp        ;

    if(Owner<>nil)and(owner is TForm)then begin
      TForm(owner).OnMouseWheel      :=FOldMouseWheel     ;
    end;
//    OnMouseWheelDown  :=FOldMouseWheelDown ;
//    OnMouseWheelUp    :=FOldMouseWheelUp   ;
  end;
  inherited
end;

procedure TMouseState.MyMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  Update(Shift,X,Y);
  if Assigned(FOldMouseDown)then FOldMouseDown(Sender,Button,Shift,X,Y);
end;

procedure TMouseState.MyMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  Update(Shift,X,Y);
  if Assigned(FOldMouseUp)then FOldMouseUp(Sender,Button,Shift,X,Y);
end;

procedure TMouseState.MyMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  Update(Shift,X,Y);
  if Assigned(FOldMouseMove)then FOldMouseMove(Sender,Shift,X,Y);
end;

procedure TMouseState.MyMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  Update(Shift,Act.Screen.X,Act.Screen.Y,WheelDelta);
  if Assigned(FOldMouseWheel)then FOldMouseWheel(Sender,Shift,WheelDelta,MousePos,Handled);
end;

(*procedure TMouseState.MyMouseWheelDown(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
begin
  Update(Shift,Act.Screen.X,Act.Screen.Y);
  if Assigned(FOldMouseWheelDown)then FOldMouseWheelDown(Sender,Shift,MousePos,Handled);
end;

procedure TMouseState.MyMouseWheelUp(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
begin
  Update(Shift,Act.Screen.X,Act.Screen.Y);
  if Assigned(FOldMouseWheelUp)then FOldMouseWheelUp(Sender,Shift,MousePos,Handled);
end;*)

procedure TMouseState.Update(const shift: TShiftState; const X,Y: integer;const WD:integer=0);
var pressing,lastpressing:boolean;
begin
  pressing:=((ssLeft in Shift)or(ssRight in Shift)or(ssMiddle in Shift));
  lastPressing:=((ssLeft in Act.Shift)or(ssRight in Act.Shift)or(ssMiddle in Act.Shift));
  justPressed:=pressing and not lastpressing;
  justReleased:=not pressing and lastpressing;

  Last:=Act;

  Act.Screen:=Point(X,Y);
  Act.Shift:=Shift;
  if(ssLeft  in shift)then Act.Button:=mbLeft else
  if(ssRight in shift)then Act.Button:=mbRight else
                           Act.button:=mbMiddle;

  if justPressed then begin
    HoverMax.Screen:=point(0,0);
    Pressed:=Act;
  end;

  Delta.Screen.X:=Act.Screen.X-Last.Screen.X;
  Delta.Screen.Y:=Act.Screen.Y-Last.Screen.Y;

  Hover.Screen.X:=Act.Screen.X-Pressed.Screen.X;
  Hover.Screen.Y:=Act.Screen.Y-Pressed.Screen.Y;

  HoverMax.Screen.X:=max(HoverMax.Screen.X,abs(Hover.Screen.X));
  HoverMax.Screen.Y:=max(HoverMax.Screen.Y,abs(Hover.Screen.Y));

  Delta.Wheel:=WD;
  inc(Act.Wheel,WD);

  if Assigned(OnChange)then
    OnChange(self);
end;

function CountBitsOld(i:integer):integer;
begin
  result:=0;
  while i<>0 do begin
    result:=result+i and 1;
    i:=i shr 1;
  end;
end;

function CountBits(i:int64):integer;
begin
  result:=0;
  while i<>0 do begin
    result:=result+i and 1;
    i:=i shr 1;
  end;
end;

const VK_NAmes:array[0..114]of record c:integer;n:ansistring end=(
(c:VK_LBUTTON   ;n:'Left mouse'),
(c:VK_RBUTTON 	;n:'Right mouse'),
(c:VK_CANCEL 	;n:'Break'),
(c:VK_MBUTTON 	;n:'Middle mouse'),
(c:VK_BACK 	;n:'Backspace'),
(c:VK_TAB 	;n:'Tab'),
(c:VK_CLEAR 	;n:'Clear'),
(c:VK_RETURN 	;n:'Enter'),
(c:VK_SHIFT 	;n:'Shift'),
(c:VK_CONTROL 	;n:'Ctrl'),
(c:VK_MENU 	;n:'Alt'),
(c:VK_PAUSE 	;n:'Pause'),
(c:VK_CAPITAL 	;n:'Caps lock'),
(c:VK_ESCAPE 	;n:'Esc'),
(c:VK_SPACE 	;n:'Space'),
(c:VK_PRIOR 	;n:'Page up'),
(c:VK_NEXT 	;n:'Page down'),
(c:VK_END 	;n:'End'),
(c:VK_HOME 	;n:'Home'),
(c:VK_LEFT 	;n:'Left'),
(c:VK_UP 	;n:'Up'),
(c:VK_RIGHT 	;n:'Right'),
(c:VK_DOWN 	;n:'Down'),
(c:VK_SELECT 	;n:'Select'),
(c:VK_PRINT 	;n:'Print'),
(c:VK_EXECUTE 	;n:'Execute'),
(c:VK_SNAPSHOT 	;n:'Print screen'),
(c:VK_INSERT 	;n:'Ins'),
(c:VK_DELETE 	;n:'Del'),
(c:VK_HELP 	;n:'Help'),
(c:$30 	;n:'0'),
(c:$31 	;n:'1'),
(c:$32 	;n:'2'),
(c:$33 	;n:'3'),
(c:$34 	;n:'4'),
(c:$35 	;n:'5'),
(c:$36 	;n:'6'),
(c:$37 	;n:'7'),
(c:$38 	;n:'8'),
(c:$39 	;n:'9'),
(c:$41 	;n:'A'),
(c:$42 	;n:'B'),
(c:$43 	;n:'C'),
(c:$44 	;n:'D'),
(c:$45 	;n:'E'),
(c:$46 	;n:'F'),
(c:$47 	;n:'G'),
(c:$48 	;n:'H'),
(c:$49 	;n:'I'),
(c:$4A 	;n:'J'),
(c:$4B 	;n:'K'),
(c:$4C 	;n:'L'),
(c:$4D 	;n:'M'),
(c:$4E 	;n:'N'),
(c:$4F 	;n:'O'),
(c:$50 	;n:'P'),
(c:$51 	;n:'Q'),
(c:$52 	;n:'R'),
(c:$53 	;n:'S'),
(c:$54 	;n:'T'),
(c:$55 	;n:'U'),
(c:$56 	;n:'V'),
(c:$57 	;n:'W'),
(c:$58 	;n:'X'),
(c:$59 	;n:'Y'),
(c:$5A 	;n:'Z'),
(c:VK_NUMPAD0 	;n:'Numpad 0'),
(c:VK_NUMPAD1 	;n:'Numpad 1'),
(c:VK_NUMPAD2 	;n:'Numpad 2'),
(c:VK_NUMPAD3 	;n:'Numpad 3'),
(c:VK_NUMPAD4 	;n:'Numpad 4'),
(c:VK_NUMPAD5 	;n:'Numpad 5'),
(c:VK_NUMPAD6 	;n:'Numpad 6'),
(c:VK_NUMPAD7 	;n:'Numpad 7'),
(c:VK_NUMPAD8 	;n:'Numpad 8'),
(c:VK_NUMPAD9 	;n:'Numpad 9'),
(c:VK_SEPARATOR ;n:'Separator'),
(c:VK_SUBTRACT 	;n:'Numpad -'),
(c:VK_ADD 	;n:'Numpad +'),
(c:VK_DECIMAL 	;n:'Decimal'),
(c:VK_DIVIDE 	;n:'Divide'),
(c:VK_F1 	;n:'F1'),
(c:VK_F2 	;n:'F2'),
(c:VK_F3 	;n:'F3'),
(c:VK_F4 	;n:'F4'),
(c:VK_F5 	;n:'F5'),
(c:VK_F6 	;n:'F6'),
(c:VK_F7 	;n:'F7'),
(c:VK_F8 	;n:'F8'),
(c:VK_F9 	;n:'F9'),
(c:VK_F10 	;n:'F10'),
(c:VK_F11 	;n:'F11'),
(c:VK_F12 	;n:'F12'),
(c:VK_F13 	;n:'F13'),
(c:VK_F14 	;n:'F14'),
(c:VK_F15 	;n:'F15'),
(c:VK_F16 	;n:'F16'),
(c:VK_F17 	;n:'F17'),
(c:VK_F18 	;n:'F18'),
(c:VK_F19 	;n:'F19'),
(c:VK_F20 	;n:'F20'),
(c:VK_F21 	;n:'F21'),
(c:VK_F22 	;n:'F22'),
(c:VK_F23 	;n:'F23'),
(c:VK_F24 	;n:'F24'),
(c:VK_NUMLOCK 	;n:'Num lock'),
(c:VK_SCROLL 	;n:'Scroll lock'),
(c:VK_LSHIFT 	;n:'Left Shift'),
(c:VK_RSHIFT 	;n:'Right Shift'),
(c:VK_LCONTROL 	;n:'Left Ctrl'),
(c:VK_RCONTROL 	;n:'Right Ctrl'),
(c:VK_LMENU 	;n:'Left Menu'),
(c:VK_RMENU 	;n:'Right Menu'),
(c:VK_PLAY 	;n:'Play'),
(c:VK_ZOOM 	;n:'Zoom'));

function HotVKeyToStr(const HK:integer):ansistring;
var i,j,k:integer;
begin
  result:='';
  if(hk and scShift)<>0then result:=result+'Shift+';
  if(hk and scCtrl )<>0then result:=result+'Ctrl+';
  if(hk and scAlt  )<>0then result:=result+'Alt+';

  k:=HK and $ff;
  j:=-1;for i:=0 to high(VK_NAmes)do if VK_NAmes[i].c=k then begin j:=i;break end;
  if j<0 then result:=result+'$'+inttohex(k,2)
         else result:=result+VK_Names[i].n;
end;

function ToHotVKey(name:ansistring):integer;overload;

  procedure CheckMod(const m:string;const code:integer);
  var i:integer;
  begin
    i:=pos(m+'+',name,[poIgnoreCase]);
    if i<=0 then exit;
    Delete(name,i,length(m)+1);
    result:=result or code;
  end;

var i:integer;
begin
  result:=0;
  CheckMod('Shift',scShift);
  CheckMod('Ctrl' ,scCtrl );
  CheckMod('Alt'  ,scAlt  );

  for i:=0 to high(VK_NAmes)do if cmp(VK_Names[i].n,name)=0 then exit(result or VK_Names[i].c);
  result:=result or StrToIntDef(name,0);
end;

function ToHotVkey(const Key:integer;const Shift:TShiftState):integer;overload;
begin
  result:=key;
  if ssShift in Shift then result:=result or scShift;
  if ssCtrl  in Shift then result:=result or scCtrl;
  if ssAlt   in Shift then result:=result or scAlt;
end;

procedure SafeLog(const s:ansistring);
const fn='c:\safelog.txt';
var f:text;
begin
  if not safelogEnabled then exit;

  AssignFile(f,fn);
  if fileexists(fn)then Append(f)else Rewrite(f);
  writeln(f,FormatDateTime('YYMMDD HHNNSS ZZZ',now)+' '+s);
  closefile(f);
end;

procedure Ranger(const a:integer;var b:integer;const c:integer);
begin
  if b<a then b:=a else if b>c then b:=c;
end;

function HungarianUnicodeToAnsi(s:UnicodeString):ansistring;
var i:integer;
begin
  for i:=1 to length(s)do case s[i] of
    #$0151:s[i]:='ô';
    #$0150:s[i]:='Ô';
    #$0171:s[i]:='û';
    #$0170:s[i]:='Û';
  end;
  result:=s;
end;

function HungarianAnsiToUnicode(const s:ansistring):UnicodeString;
var i:integer;
begin
  result:=s;
  for i:=1 to length(s)do case s[i] of
    'ô':result[i]:=#$0151;
    'Ô':result[i]:=#$0150;
    'û':result[i]:=#$0171;
    'Û':result[i]:=#$0170;
  end;
end;

function AppPath:string;
begin
  result:=ExtractFilePath(ParamStr(0))
end;

function CmdLineParam(const Param:String):string;
var i:integer;
begin
  result:='';
  for i:=1 to ParamCount-1 do if(Copy(ParamStr(i),1,1)='/')or(Copy(ParamStr(i),1,1)='-')then begin
    if AnsiSameText(copy(ParamStr(i),2,$ff),Param)then
      exit(ParamStr(i+1));
  end;
end;

function Remap(const src,srcFrom,srcTo,dstFrom,dstTo:single):single;overload;
var s:Single;
begin
  s:=(srcTo-srcFrom);
  if s=0 then result:=dstFrom
         else result:=(src-srcFrom)/s*(dstTo-dstFrom)+dstFrom;
end;

function RemapClamp(const src,srcFrom,srcTo,dstFrom,dstTo:single):single;
begin
  result:=EnsureRange(remap(src, srcFrom, srcTo, dstFrom, dstTo), minf(dstFrom, dstTo), maxf(dstFrom, dstTo));
end;

function Remap(const p:TPoint;const rSrc,rDst:TRect):TPoint;overload;
begin
  result.X:=round(remap(p.X,rSrc.Left,rSrc.Right ,rDst.Left,rDst.Right ));
  result.Y:=round(remap(p.Y,rSrc.Top ,rSrc.Bottom,rDst.Top ,rDst.Bottom));
end;

function Remap(const r,rSrc,rDst:TRect):TRect;overload;
begin
  result.TopLeft    :=remap(r.TopLeft    ,rSrc,rDst);
  result.BottomRight:=remap(r.BottomRight,rSrc,rDst);
end;


function ComputerName: ansistring;
var c:array[0..100]of ansichar;
    siz:cardinal;
begin
  siz:=100;
  GetComputerNameA(@c[0], siz);
  Result:=PAnsiChar(@c);
end;

function ChkChanged(const act:boolean;var last:boolean):boolean;
begin
  result:=act<>last;
  last:=act;
end;

function ChkPressed(const act:boolean;var last:boolean):boolean;
begin
  result:=act and not last;
  last:=act;
end;

function ChkReleased(const act:boolean;var last:boolean):boolean;
begin
  result:=not act and last;
  last:=act;
end;

constructor TRawStream.Create(const AString: rawbytestring);
begin
  inherited Create;
  FDataString := AString;
end;

function TRawStream.Read(var Buffer; Count: Longint): Longint;
begin
  Result := Length(FDataString) - FPosition;
  if Result > Count then Result := Count;
  Move(PAnsiChar(@FDataString[FPosition+1])^, Buffer, Result);
  Inc(FPosition, Result);
end;

function TRawStream.Write(const Buffer; Count: Longint): Longint;
begin
  Result := Count;
  SetLength(FDataString, (FPosition + Result));
  Move(Buffer, PAnsiChar(@FDataString[FPosition+1])^, Result);
  Inc(FPosition, Result);
end;

function TRawStream.Seek(Offset: Longint; Origin: Word): Longint;
begin
  case Origin of
    soFromBeginning: FPosition := Offset;
    soFromCurrent: FPosition := FPosition + Offset;
    soFromEnd: FPosition := Length(FDataString) - Offset;
  end;
  if FPosition > Length(FDataString) then
    FPosition := Length(FDataString)
  else if FPosition < 0 then FPosition := 0;
  Result := FPosition;
end;

function TRawStream.ReadString(Count: Longint): rawbytestring;
var
  Len: Integer;
begin
  Len := Length(FDataString) - FPosition;
  if Len > Count then Len := Count;
  SetLength(result,Len);
  if len>0 then
    move(FDataString[FPosition + 1],result[1],Len);
  Inc(FPosition, Len);
end;

procedure TRawStream.WriteString(const AString: rawbytestring);
begin
  Write(PAnsiChar(AString)^, Length(AString));
end;

procedure TRawStream.SetSize(NewSize: Longint);
begin
  SetLength(FDataString, NewSize);
  if FPosition > NewSize then FPosition := NewSize;
end;


function switch(const b:Boolean;const t:ansistring;const f:ansistring=''):ansistring;overload;
begin if b then result:=t else result:=f end;
function switch(const b:Boolean;const t:string    ;const f:string    =''):string;overload;
begin if b then result:=t else result:=f end;
function switch(const b:Boolean;const t:integer   ;const f:integer   =0):integer;overload;
begin if b then result:=t else result:=f end;
function switch(const b:Boolean;const t:cardinal  ;const f:cardinal  =0):cardinal;overload;
begin if b then result:=t else result:=f end;
function switch(const b:Boolean;const t:single    ;const f:single    =0):single;overload;
begin if b then result:=t else result:=f end;
function switch(const b:Boolean;const t:boolean   ;const f:boolean   =false):boolean;overload;
begin if b then result:=t else result:=f end;

type
  TAutoFree=class(TInterfacedObject)
  private
    FObject:TObject;
  public
    constructor Create(const AObject:TObject);
    destructor Destroy;override;
  end;

function AutoFree(const AObject:TObject):IUnknown;
begin
  result:=TAutoFree.Create(AObject)as IUnknown;
end;

{ TAutoFree }

constructor TAutoFree.Create(const AObject: TObject);
begin
  FObject:=AObject;
end;

destructor TAutoFree.Destroy;
begin
  FObject.Free;
  inherited;
end;


procedure MakeCharmapUpperSort;

  const order:ansistring='@AÀÁÂÃÄÅÆBCÇDÐEÈÉÊËFGHIÌÍÎÏJKLMNÑOÒÓÔÖÕØPQRSTUÙÚÛÜVWXYÝZ[\]^_{|}~';

  function find(const ch:ansichar):integer;
  var i:integer;
  begin
    for i:=1 to length(order)do if order[i]=ch then exit(i);
    result:=0;
  end;

var ch,actch:AnsiChar;n:integer;
begin
  fillchar(charmapUpperSort,sizeof(charmapUpperSort),0);
  for ch:=#0 to #$3F do charmapUpperSort[ch]:=ch;
  for ch:=#0 to #255 do begin
    n:=find(charmapUpper[ch]);
    if n>0 then charmapUpperSort[ch]:=ansichar($40+n-1);
  end;
  actch:=ansichar($40+length(order));
  for ch:=#1 to #255 do if charmapUpperSort[ch]=#0 then begin
    charmapUpperSort[ch]:=actch;inc(actch);
  end;
end;

{ TAnsiStringBuilder }

constructor TAnsiStringBuilder.Create(var AStr: AnsiString);
begin
  PStr:=@AStr;
  FLen:=Length(PStr^);
end;

procedure TAnsiStringBuilder.Finalize;
begin
  SetLength(PStr^,FLen);
end;

destructor TAnsiStringBuilder.Destroy;
begin
  Finalize;
  inherited;
end;

procedure TAnsiStringBuilder.AddBlock(var AData;const ALen: integer);
var actLen,newLen:integer;
begin
  if ALen<=0 then exit;
  actLen:=length(PStr^);
  newLen:=FLen+ALen;
  if actLen<newLen then begin
    actLen:=actLen+max(newLen*2-actlen,$4000000);
    SetLength(PStr^,actLen);
  end;
  move(AData,PStr^[FLen+1],ALen);
  FLen:=newLen;
end;

procedure TAnsiStringBuilder.AddChar(const ch: AnsiChar);
begin
  AddBlock((@ch)^,1);
end;

procedure TAnsiStringBuilder.AddStr(const s: ansistring);
var p:pointer;
begin
  p:=pointer(s);//avoiding _LStrAddRef
  if p<>nil then
    AddBlock(p^,pinteger(cardinal(p)-4)^);
end;

procedure TAnsiStringBuilder.AddLine(const s: ansistring);
begin
  AddStr(s);
  AddStr(#13#10);
end;

procedure TAnsiStringBuilder.AddStrAfterPrevLine(s:ansistring);
var oldLen:integer;
begin
  if s='' then exit;
  if charn(s,length(s))<>#10 then s:=s+#13#10;

  oldLen:=FLen;
  FLen:=pos(#10,pstr^,[poBackwards],FLen);
  AddStr(s+copy(PStr^,FLen+1,OldLen-FLen));
end;

procedure TAnsiStringBuilder.DeleteLastChar;
begin
  if FLen>0 then dec(FLen);
end;

function TAnsiStringBuilder.GetLen:integer;
begin
  result:=FLen;
end;

function AnsiStringBuilder(var s:AnsiString;const Clear:boolean=false):IAnsiStringBuilder;
begin
  if clear then s:='';
  result:=TAnsiStringBuilder.Create(s);
end;

{ TUnicodeStringBuilder }

constructor TUnicodeStringBuilder.Create(var AStr: UnicodeString);
begin
  PStr:=@AStr;
  Len:=Length(PStr^);
end;

procedure TUnicodeStringBuilder.Finalize;
begin
  SetLength(PStr^,Len);
end;

destructor TUnicodeStringBuilder.Destroy;
begin
  Finalize;
  inherited;
end;

procedure TUnicodeStringBuilder.AddBlock(var AData;const ALenInWords: integer);
var actLen,newLen:integer;
begin
  if ALenInWords<=0 then exit;
  actLen:=length(PStr^);
  newLen:=Len+ALenInWords;
  if actLen<newLen then begin
    actLen:=newLen*2;
    SetLength(PStr^,actLen);
  end;
  move(AData,PStr^[Len+1],ALenInWords shl 1{!!!});
  len:=newLen;
end;

procedure TUnicodeStringBuilder.AddChar(const ch: {Unicode}Char);
var ch2:{Unicode}Char;
begin
  ch2:=ch;
  AddBlock(ch2,1);
end;

procedure TUnicodeStringBuilder.AddStr(const s: UnicodeString);
var p:pointer;
begin
  p:=pointer(s);//avoiding _LStrAddRef
  if p<>nil then
    AddBlock(p^,pinteger(cardinal(p)-4)^);
end;

procedure TUnicodeStringBuilder.AddLine(const s: UnicodeString);
begin
  AddStr(s);
  AddStr(#13#10);
end;

function UnicodeStringBuilder(var s:UnicodeString;const Clear:boolean=false):IUnicodeStringBuilder;
begin
  if Clear then s:='';
  result:=TUnicodeStringBuilder.Create(s);
end;


{function VarToAnsiStr(const V:variant):ansistring;
begin
  if VarIsNull(v)then result:=NullAsAnsiStringValue
                 else result:=V;
end;}

function ToStr(const Value:ansistring):ansistring;overload;
begin result:=Value end;

function ToStr(Value:integer):ansistring;overload;
var rpos:integer;
    neg:boolean;
    buf:array[0..9]of ansichar;
    p:pointer;
begin
  if Value=0 then exit('0');
  neg:=Value<0;
  if neg then Value:=-Value;
  rpos:=high(buf);
  p:=@buf[0];
  asm
    push edi;push esi
    mov edi,p
    mov esi,rpos
    mov eax,Value
    mov ecx,10
  @@1:
    xor edx,edx
    idiv ecx
    add dl,$30
    mov [edi+esi],dl
    sub esi,1
    test eax,eax
    jnz @@1
    mov rpos,esi
    pop esi;pop edi
  end;

{  while true do begin
    m:=Value mod 10;
    buf[rpos]:=ansichar(ord('0')+m);dec(rpos);
    Value:=Value div 10;
    if Value=0 then break;
  end;}

  if neg then begin
    setlength(result,1+high(buf)-rpos);
    result[1]:='-';
    move(buf[rpos+1],result[2],length(result)-1);
  end else begin
    setlength(result,high(buf)-rpos);
    move(buf[rpos+1],result[1],length(result));
  end;
end;

function ToStr(Value:cardinal):ansistring;overload;
var rpos:integer;
    buf:array[0..9]of ansichar;
    p:pointer;
begin
  if Value=0 then exit('0');
  rpos:=high(buf);
  p:=@buf[0];
  asm
    push edi;push esi
    mov edi,p
    mov esi,rpos
    mov eax,Value
    mov ecx,10
  @@1:
    xor edx,edx
    idiv ecx
    add dl,$30
    mov [edi+esi],dl
    sub esi,1
    test eax,eax
    jnz @@1
    mov rpos,esi
    pop esi;pop edi
  end;

{  while true do begin
    m:=Value mod 10;
    buf[rpos]:=ansichar(ord('0')+m);dec(rpos);
    Value:=Value div 10;
    if Value=0 then break;
  end;}

  setlength(result,high(buf)-rpos);
  move(buf[rpos+1],result[1],length(result));
end;

function ToStr(Value:int64):ansistring;overload;
var m,rpos:integer;
    neg:boolean;
    buf:array[0..21]of ansichar;
begin
  if Value=0 then exit('0');
  neg:=Value<0;
  if neg then Value:=-Value;
  rpos:=high(buf);

  while true do begin
    m:=Value mod 10;
    buf[rpos]:=ansichar(ord('0')+m);dec(rpos);
    Value:=Value div 10;
    if Value=0 then break;
  end;

  if neg then begin
    setlength(result,1+high(buf)-rpos);
    result[1]:='-';
    move(buf[rpos+1],result[2],length(result)-1);
  end else begin
    setlength(result,high(buf)-rpos);
    move(buf[rpos+1],result[1],length(result));
  end;
end;

var HetFormatSettings:TFormatSettings;

procedure CopyFormatSettings(var h:TFormatSettings);
var i:integer;
begin
  with FormatSettings do begin
    h.CurrencyFormat:=CurrencyFormat;
    h.NegCurrFormat:=NegCurrFormat;
    h.ThousandSeparator:=ThousandSeparator;
    h.DecimalSeparator:=DecimalSeparator;
    h.CurrencyDecimals:=CurrencyDecimals;
    h.DateSeparator:=DateSeparator;
    h.TimeSeparator:=TimeSeparator;
    h.ListSeparator:=ListSeparator;
    h.CurrencyString:=CurrencyString;
    h.ShortDateFormat:=ShortDateFormat;
    h.LongDateFormat:=LongDateFormat;
    h.TimeAMString:=TimeAMString;
    h.TimePMString:=TimePMString;
    h.ShortTimeFormat:=ShortTimeFormat;
    h.LongTimeFormat:=LongTimeFormat;

    for i:=low(ShortMonthNames)to high(ShortMonthNames)do
      h.ShortMonthNames[i]:=ShortMonthNames[i];
    for i:=low(LongMonthNames)to high(LongMonthNames)do
      h.LongMonthNames[i]:=LongMonthNames[i];

    for i:=low(ShortDayNames)to high(ShortDayNames)do
      h.ShortDayNames[i]:=ShortDayNames[i];
    for i:=low(LongDayNames)to high(LongDayNames)do
      h.LongDayNames[i]:=LongDayNames[i];

    h.TwoDigitYearCenturyWindow:=TwoDigitYearCenturyWindow;
  end;
end;

procedure InitHetFormatSettings;
begin
  CopyFormatSettings(HetFormatSettings);
  with HetFormatSettings do begin
    DecimalSeparator:='.';
    DateSeparator:='.';
    TimeSeparator:=':';
    ListSeparator:=',';
    ThousandSeparator:=' ';
{    ShortDateFormat:='yy/mm/dd';
    ShortTimeFormat:=' hh:nn:ss.zzz';}
  end;
end;

function ToStr(const Value:TDateTime):ansistring;overload;
begin
  if Value<1 then result:=FormatDateTime('hh:nn:ss.zzz',Value,HetFormatSettings)
  else if frac(value)=0 then result:=FormatDateTime('yyyy/mm/dd',Value,HetFormatSettings)
  else if frac(value*24*60)=0 then result:=FormatDateTime('yyyy/mm/dd hh:nn',Value,HetFormatSettings)
                              else result:=FormatDateTime('yyyy/mm/dd hh:nn:ss.zzz',Value,HetFormatSettings);
end;

function ToStr(const Value:boolean):ansistring;overload;
begin
  if Value then result:='1'
           else result:='0';
end;

function ToStr(const Value:single):ansistring;overload;
var ext:extended;
begin
  ext:=value;
  setlength(result,16);
  setlength(result,FloatToText(PAnsiChar(@result[1]),ext,fvExtended,ffGeneral, 8,0,HetFormatSettings));
end;

function ToStr(const Value:double):ansistring;overload;
var ext:extended;
begin
  ext:=value;
  setlength(result,24);
  setlength(result,FloatToText(PAnsiChar(@result[1]),ext,fvExtended,ffGeneral,16,0,HetFormatSettings));
end;

function ToStr(const Value:extended):ansistring;overload;
begin
  setlength(result,32);
  setlength(result,FloatToText(PAnsiChar(@result[1]),Value,fvExtended,ffGeneral,18,0,HetFormatSettings));
end;

function ToStr(const V:TArray<integer>):ansistring;
var i:integer;
begin
  if length(v)=0 then exit('()');
  if length(v)=1 then exit('('+inttostr(v[0])+')');
  with AnsiStringBuilder(result,true)do begin
    AddStr('('+tostr(v[0]));
    for i:=1 to high(v)do AddStr(', '+tostr(v[i]));
    AddChar(')');
  end;
end;

function ToStr(const V:variant):ansistring;
begin
  result:=ansistring(V);
end;

function ToStr(const P:TPoint):ansistring;overload;
begin
  result:='('+ToStr(P.x)+', '+ToStr(P.y)+')';
end;

function ToStr(const R:TRect):ansistring;overload;
begin
  result:='('+ToStr(R.TopLeft)+', '+ToStr(R.BottomRight)+')';
end;

function ToExtendedDef(const s:ansistring;const Default:extended=0):extended;
begin
  if not TextToFloat(PAnsiChar(s),result,fvExtended)then result:=Default;
end;

function ToDoubleDef(const s:ansistring;const Default:double=0):Double;
var x:extended;
begin
  if not TextToFloat(PAnsiChar(s),x,fvExtended)then result:=Default else result:=x;
end;

function ToSingleDef(const s:ansistring;const Default:single=0):Single;
var x:extended;
begin
  if not TextToFloat(PAnsiChar(s),x,fvExtended)then result:=Default else result:=x;
end;

function ToIntDef(const s:ansistring;const Default:integer=0):integer;
begin
  raise Exception.Create('not yet implemented');
end;

function ToInt64Def(const s:ansistring;const Default:int64=0):int64;
begin
  raise Exception.Create('not yet implemented');
end;

function ToCardinalDef(const s:ansistring;const Default:cardinal=0):cardinal;
begin
  raise Exception.Create('not yet implemented');
end;

function ToBooleanDef(const s:ansistring;const Default:boolean=false):boolean;
begin
  raise Exception.Create('not yet implemented');
end;

function Indent(const AStr:ansistring;const ACount:integer):ansistring;
begin
  result:=StrMul(AStr,ACount);
end;

function Indent(const ACount:integer):ansistring;
begin
  result:=StrMul('  ',ACount);
end;

function pwScramble(const s:ansistring):ansistring;
var i:integer;
begin
  result:=s;
  for i:=1 to length(result)do result[i]:=ansichar(ord(result[i])xor $15);
end;

procedure IniWrite(const Controls:array of const;const FFileName:string);
var ini:TIniFile;

  procedure write(c:tcomponent);

    procedure writeString(const s:string);
    begin ini.WriteString(c.Owner.Name,c.Name,HungarianUnicodeToAnsi(s))end;

    procedure writeStringPw(const s:string);
    begin ini.WriteString(c.Owner.Name,c.Name,pwScramble(HungarianUnicodeToAnsi(s)))end;

    procedure writeInteger(const i:integer);
    begin ini.WriteInteger(c.Owner.Name,c.Name,i)end;

    procedure writeFloat(const f:double);
    begin ini.WriteFloat(c.Owner.Name,c.Name,f)end;

    procedure writeBool(const b:Boolean);
    begin ini.WriteBool(c.Owner.Name,c.Name,b)end;

    function getRadioGroupText(const rg:TRadioGroup):string;
    begin
      if rg.ItemIndex>=0 then result:=rg.Items[rg.ItemIndex]
                         else result:='';
    end;

    function getListBoxText(const lb:TListBox):string;
    begin
      if lb.ItemIndex>=0 then result:=lb.Items[lb.ItemIndex]
                         else result:='';
    end;

    procedure WriteFont(const f:TFont);
    begin
      ini.WriteString(c.Owner.Name,c.Name+'.FontName',f.Name);
      ini.WriteInteger(c.Owner.Name,c.Name+'.FontSize',f.Size);
      ini.WriteInteger(c.Owner.Name,c.Name+'.FontColor',f.Color);
      ini.WriteInteger(c.Owner.Name,c.Name+'.FontStyle',byte(f.Style));
    end;

    function EncodeMultiline(const s:ansistring):ansistring;
    begin
      result:=s;
      Replace(#10,'<LF>',result,[roAll]);
      Replace(#13,'<CR>',result,[roAll]);
    end;

  var i:integer;
  begin
    if c is TCustomMemo then begin
      WriteString(EncodeMultiLine(TCustomMemo(c).Text));
    end else if c is TComboBox then begin
      WriteString(TComboBox(c).Text);
    end else if c is TComboBoxEx then begin
      WriteString(TComboBoxEx(c).Text);
    end else if c is TCustomEdit then begin
      if TEdit(c).PasswordChar=#0 then WriteString(TCustomEdit(c).Text)
                                        else WriteStringPw(TCustomEdit(c).Text);
    end else if c is TFontDialog then begin
      writeFont(TFontDialog(c).Font);
    end else if c is TSpinEdit then begin
      writeInteger(TSpinEdit(c).Value);
(*    end else if c is TFloatSpinEdit then begin
      writeFloat(TFloatSpinEdit(c).Value);*)
    end else if c is TCheckBox then begin
      WriteString(GetEnumName(TypeInfo(TCheckBoxState),integer(TCheckBox(c).State)))
    end else if c is TRadioButton then begin
      WriteBool(TRadioButton(c).Checked)
    end else if c is TRadioGroup then begin
      WriteString(GetRadioGroupText(TRadioGroup(c)))
    end else if c is TListBox then begin
      WriteString(GetListBoxText(TListBox(c)))
    end else if c is TTrackBar then begin
      WriteInteger(TTrackBar(c).Position);
    end else if c is TScrollBar then begin
      WriteInteger(TScrollBar(c).Position);
    end else if c is THotKey then begin
      WriteInteger(THotKey(c).HotKey);
    end else if c.ClassNameIs('TSlider') then begin
      WriteFloat(GetFloatProp(c,'Value'));
    end else if c.ClassNameIs('TCodeEditor') then begin
      writeString(EncodeMultiLine(GetStrProp(c,'Code')));
//if all above fails
    end else if(c is TWinControl)then begin
      for i:=0 to TWinControl(c).ControlCount-1 do write(TPanel(c).Controls[i]);
    end;
  end;

var fn:string;
    i:integer;
begin
  if FFileName='' then fn:=ChangeFileExt(ParamStr(0),'.ini')
                  else fn:=FFileName;
  ini:=TIniFile.Create(fn);
  try
    for i:=0 to high(Controls)do if(Controls[i].VType=vtObject)and(Controls[i].VObject<>nil)and(Controls[i].VObject is TComponent)then
      write(TComponent(Controls[i].VObject));
    ini.UpdateFile;
  finally
    ini.Free;
  end;
end;

procedure IniRead(const Controls:array of const;const FFileName:string='');
var ini:TIniFile;

  procedure read(const c:tcomponent);

    function readString(const default:string=''):string;
    begin result:=HungarianAnsiToUnicode(ini.ReadString(c.Owner.Name,c.Name,default));end;

    function readStringPw(const default:string=''):string;
    begin result:=HungarianAnsiToUnicode(pwScramble(ini.ReadString(c.Owner.Name,c.Name,default)));end;

    function readInteger(const default:integer=0):integer;
    begin result:=ini.ReadInteger(c.Owner.Name,c.Name,default);end;

    function readFloat(const default:double=0):double;
    begin result:=ini.ReadFloat(c.Owner.Name,c.Name,default);end;

    function readBool(const default:boolean=false):boolean;
    begin result:=ini.ReadBool(c.Owner.Name,c.Name,default);end;

    procedure setRadioGroupText(const rg:TRadioGroup;const text:string);
    var i:integer;
    begin
      i:=rg.Items.IndexOf(text);
      if i>=0 then rg.ItemIndex:=i;
    end;

    function setListBoxText(const lb:TListBox;const text:string):string;
    var i:integer;
    begin
      i:=lb.Items.IndexOf(text);
      if i>=0 then lb.ItemIndex:=i;
    end;

    procedure setComboBoxText(const cb:TCombobox;const text:string);
    var i:integer;
    begin
      i:=cb.Items.IndexOf(text);
      if i>=0 then begin
        cb.ItemIndex:=i;
        if assigned(cb.OnChange)then cb.OnChange(cb);
      end else if cb.Style<>csDropDownList then cb.Text:=text;

    end;

    procedure setComboBoxExText(const cb:TComboboxEx;const text:string);
    var i:integer;
    begin
      i:=cb.Items.IndexOf(text);
      if i>=0 then begin
        cb.ItemIndex:=i;
        if assigned(cb.OnChange)then cb.OnChange(cb);
      end else if cb.Style<>csExDropDownList then cb.Text:=text;
    end;

    procedure ReadFont(const f:TFont);
    begin
      f.Name:=ini.ReadString(c.Owner.Name,c.Name+'.FontName',f.Name);
      f.Size:=ini.ReadInteger(c.Owner.Name,c.Name+'.FontSize',f.Size);
      f.Color:=ini.ReadInteger(c.Owner.Name,c.Name+'.FontColor',f.Color);
      f.Style:=TFontStyles(byte(ini.ReadInteger(c.Owner.Name,c.Name+'.FontStyle',byte(f.Style))));
    end;

    function DecodeMultiline(const s:ansistring):ansistring;
    begin
      result:=s;
      Replace('<LF>',#10,result,[roAll]);
      Replace('<CR>',#13,result,[roAll]);
    end;

  var i:integer;
      exists:boolean;

  begin
    exists:=ini.ValueExists(c.Owner.Name,c.Name);
    if c is TCustomMemo then begin
      if exists then TCustomMemo(c).Text:=DecodeMultiline(readString);
    end else if c is TComboBox then begin
      if exists then setComboBoxText(TComboBox(c),readString);
    end else if c is TComboBoxEx then begin
      if exists then setComboBoxExText(TComboBoxEx(c),readString);
    end else if c is TCustomEdit then begin
      if exists then if TEdit(c).PasswordChar=#0 then TCustomEdit(c).Text:=readString
                                                 else TCustomEdit(c).Text:=readStringPw;
    end else if c is TFontDialog then begin
      {if exists then }ReadFont(TFontDialog(c).Font);
    end else if c is TSpinEdit then begin
      if exists then TSpinEdit(c).Value:=readInteger;
(*    end else if c is TFloatSpinEdit then begin
      if exists then TFloatSpinEdit(c).Value:=readFloat;*)
    end else if c is TCheckBox then begin
      if exists then TCheckBox(c).State:=TCheckBoxState(GetEnumValue(TypeInfo(TCheckBoxState),ReadString('cbUnchecked')));
    end else if c is TRadioButton then begin
      if exists then TRadioButton(c).Checked:=readbool;
    end else if c is TRadioGroup then begin
      if exists then setRadioGroupText(TRadioGroup(c),ReadString);
    end else if c is TListBox then begin
      if exists then setListBoxText(TListBox(c),readString);
    end else if c is TTrackBar then begin
      if exists then TTrackBar(c).Position:=readInteger;
    end else if c is TScrollBar then begin
      if exists then TScrollBar(c).Position:=readInteger;
    end else if c is THotKey then begin
      if exists then THotKey(c).HotKey:=readInteger;
    end else if c.ClassNameIs('TSlider') then begin
      if exists then SetFloatProp(c,'Value',readFloat);
    end else if c.ClassNameIs('TCodeEditor') then begin
      if exists then SetStrProp(c,'Code',DecodeMultiLine(readString));
//if all above fails
    end else if(c is TWinControl)then begin
      for i:=0 to TWinControl(c).ControlCount-1 do read(TWinControl(c).Controls[i]);
    end;
  end;

var fn:string;
    i:integer;
begin
  if FFileName='' then fn:=ChangeFileExt(ParamStr(0),'.ini')
                  else fn:=FFileName;
  if not fileexists(fn) then exit;
  ini:=TIniFile.Create(fn);
  try
    for i:=0 to high(Controls)do if(Controls[i].VType=vtObject)and(Controls[i].VObject<>nil)and(Controls[i].VObject is TComponent)then
      read(TComponent(Controls[i].VObject));
  finally
    ini.Free;
  end;
end;

function NormalizeRect(const r:TRect):TRect;
begin
  result:=r;
  sort(result.Left,result.Right);
  sort(result.Top,result.Bottom);
end;

procedure Swap(var a,b:variant);overload;var c:variant;
begin
  c:=a;a:=b;b:=c;
end;

procedure Swap(var a,b:pointer);overload;var c:pointer;
begin
  c:=a;a:=b;b:=c;
end;

procedure Swap(var a,b:integer);overload;var c:integer;
begin
  c:=a;a:=b;b:=c;
end;

procedure Swap(var a,b:single);overload;var c:single;
begin
  c:=a;a:=b;b:=c;
end;

procedure Swap(var a,b:double);overload;var c:double;
begin
  c:=a;a:=b;b:=c;
end;

procedure Swap(var a,b:TDateTime);overload;var c:TDateTime;
begin
  c:=a;a:=b;b:=c;
end;

procedure Swap(var a,b:byte);overload;var c:byte;
begin
  c:=a;a:=b;b:=c;
end;

procedure Swap(var a,b:ansichar);overload;var c:ansichar;
begin
  c:=a;a:=b;b:=c;
end;

procedure Swap(var a,b:ansistring);overload;var c:ansistring;
begin
  c:=a;a:=b;b:=c;
end;

procedure Swap(var a,b:string);overload;var c:string;
begin
  c:=a;a:=b;b:=c;
end;

procedure Swap(var a,b:TPoint);overload;var c:TPoint;
begin
  c:=a;a:=b;b:=c;
end;

procedure Sort(var a,b:integer);overload;
begin
  if a>b then swap(a,b);
end;

procedure Sort(var a,b:single);overload;
begin
  if a>b then swap(a,b);
end;

procedure Sort(var a,b:byte);overload;
begin
  if a>b then swap(a,b);
end;

procedure Sort(var a,b:ansichar);overload;
begin
  if a>b then swap(a,b);
end;

procedure pInc(var p);
begin
  inc(PByte(p));
end;

procedure pDec(var p);
begin
  dec(PByte(p));
end;

procedure pInc(var p;const incr:integer);
begin
  inc(PByte(p),incr);
end;

procedure pDec(var p;const decr:integer);
begin
  dec(PByte(p),decr);
end;

function pSucc(p:pointer):pointer;
begin
  result:=pointer(integer(p)+1);
end;

function pPred(p:pointer):pointer;
begin
  result:=pointer(integer(p)-1);
end;

function pSucc(p:pointer;const incr:integer):pointer;
begin
  result:=pointer(integer(p)+incr);
end;

function pPred(p:pointer;const decr:integer):pointer;
begin
  result:=pointer(integer(p)-decr);
end;

function pAlignDown(p:pointer;const align:integer):pointer;
asm
  sub edx,1;  not edx;  and eax,edx
end;

function pAlignUp(p:pointer;const align:integer):pointer;
asm
  sub edx,1;  add eax,edx  not edx;  and eax,edx
end;

function AlignDown(i:integer;const align:integer):integer;
asm
  sub edx,1;  not edx;  and eax,edx
end;

function AlignUp(i:integer;const align:integer):integer;
asm
  sub edx,1;  add eax,edx;  not edx;  and eax,edx
end;

function pSub(a,b:pointer):integer;
begin
  result:=integer(a)-integer(b);
end;

function RGBLerp(const a,b,alpha:cardinal):cardinal;
var a0,a1,a2,alpha1:cardinal;
    b0,b1,b2:cardinal;
begin
  a0:=a shr  0 and $ff; b0:=b shr  0 and $ff;
  a1:=a shr  8 and $ff; b1:=b shr  8 and $ff;
  a2:=a shr 16 and $ff; b2:=b shr 16 and $ff;
  alpha1:=256-alpha;
  result:=(a0*alpha1+b0*alpha)shr 8 and $ff+
          (a1*alpha1+b1*alpha)and $ff00+
          (a2*alpha1+b2*alpha)and $ff00 shl 8;
end;

function RGBALerp(const a,b,alpha:cardinal):cardinal;
var a0,a1,a2,a3,alpha1:cardinal;
    b0,b1,b2,b3:cardinal;
begin
  a0:=a shr  0 and $ff; b0:=b shr  0 and $ff;
  a1:=a shr  8 and $ff; b1:=b shr  8 and $ff;
  a2:=a shr 16 and $ff; b2:=b shr 16 and $ff;
  a3:=a shr 24 and $ff; b3:=b shr 24 and $ff;
  alpha1:=256-alpha;
  result:=(a0*alpha1+b0*alpha)shr 8 and $ff+
          (a1*alpha1+b1*alpha)and $ff00+
          (a2*alpha1+b2*alpha)and $ff00 shl 8+
          (a3*alpha1+b3*alpha)and $ff00 shl 16;
end;

function RGBMax(const a,b:cardinal):cardinal;
begin
  result:=max(a        and $ff,b        and $ff)      +
          max(a shr  8 and $ff,b shr  8 and $ff)shl  8+
          max(a shr 16 and $ff,b shr 16 and $ff)shl 16;
end;

function RGBAMax(const a,b:cardinal):cardinal;
begin
  result:=max(a        and $ff,b        and $ff)      +
          max(a shr  8 and $ff,b shr  8 and $ff)shl  8+
          max(a shr 16 and $ff,b shr 16 and $ff)shl 16+
          max(a shr 24 and $ff,b shr 24 and $ff)shl 24;
end;

function RGBMin(const a,b:cardinal):cardinal;
begin
  result:=min(a        and $ff,b        and $ff)      +
          min(a shr  8 and $ff,b shr  8 and $ff)shl  8+
          min(a shr 16 and $ff,b shr 16 and $ff)shl 16;
end;

function RGBAMin(const a,b:cardinal):cardinal;
begin
  result:=min(a        and $ff,b        and $ff)      +
          min(a shr  8 and $ff,b shr  8 and $ff)shl  8+
          min(a shr 16 and $ff,b shr 16 and $ff)shl 16+
          min(a shr 24 and $ff,b shr 24 and $ff)shl 24;
end;

function Nearest2NSize(const size:integer):integer;
begin
  if size>0 then result:=round(Power(2,ceil(Log2(size))))
            else result:=0;
end;

//var gecikurvaelet:TAnsiStringArray;

function ListSplit(const s:ansistring;const ListDelimiter:ansichar;const doTrim:boolean=true):TAnsistringarray;

  function mycopy(i0,i1:integer):ansistring;
  begin
    if doTrim then begin
      while(i0<=i1)and(s[i0]in[' ',#9,#10,#13])do inc(i0);
      while(i0<=i1)and(s[i1-1]in[' ',#9,#10,#13])do dec(i1);
    end;
    result:=copy(s,i0,i1-i0);
  end;

var i,lasti,delimlen,cnt:integer;
begin

  SetLength(result,0);cnt:=0;
  if(length(s)=0)or(length(listdelimiter)=0)then exit;
  i:=1;delimlen:=length(listdelimiter);
  repeat
    lasti:=i;//last
    i:=Pos(ListDelimiter,s,[],lasti);
    if i<=0 then
      i:=Length(s)+1;
    //add
    if cnt=Length(result)then
      setlength(result,length(result)+EnsureRange(length(result),8,1 shl 20));
    Result[cnt]:=mycopy(lasti,i);
    inc(cnt);

    inc(i,delimlen);

  until i>length(s);
  setlength(result,cnt);

{  setlength(gecikurvaelet,ListCount(s,ListDelimiter));
  for i:=0 to length(gecikurvaelet)-1 do
    gecikurvaelet[i]:=ListItem(s,i,ListDelimiter,doTrim);

  for i:=0 to length(gecikurvaelet)-1 do if gecikurvaelet[i]<>result[i]then
    raise Exception.Create('fakk! '+gecikurvaelet[i]+'<>'+result[i]);}
end;

function ListMake(const list:TAnsiStringArray;const ListDelimiter:ansistring;const doTrim:boolean=true):ansistring;
var s:ansistring;
begin
  result:='';
  if doTrim then for s in list do ListAppend(result,trimf(s),listdelimiter)
            else for s in list do ListAppend(result,s,listdelimiter);
end;

procedure LTrim(var result:ansistring);begin while(result<>'')and(result[1]in[#9,#10,#13,' '])do result:=copy(result,2,length(result)-1);end;
procedure RTrim(var result:ansistring);begin while(result<>'')and(result[length(result)]in[#9,#10,#13,' '])do setlength(result,length(result)-1);end;
procedure Trim(var result:ansistring);begin LTrim(result);RTrim(result)end;

function LTrimF(const s:ansistring):ansistring;begin result:=s;LTrim(result);end;
function RTrimF(const s:ansistring):ansistring;begin result:=s;RTrim(result);end;
function TrimF(const s:ansistring):ansistring;begin result:=s;Trim(result);end;

Function UC(const s:ansiString):ansiString;overload;begin Result:=charmapf(s,charmapUpper)end;
Function UC(const s:ansiChar):ansiChar;overload;begin Result:=charmapUpper[s]end;
Function LC(const s:ansiString):ansiString;overload;begin Result:=charmapf(s,charmapLower)end;
Function LC(const s:ansiChar):ansiChar;overload;begin Result:=charmapLower[s]end;

Function RightJ(const s:ansiString;n:Integer):ansiString;begin result:=s;while length(result)<n do result:=' '+result;end;
Function LeftJ(const s:ansiString;n:Integer):ansiString;begin result:=s;while length(result)<n do result:=result+' ';end;
Function CenterJ(const s:ansiString;n:Integer):ansiString;
begin
  result:=s;
  while length(result)<n do begin
    result:=' '+result;
    if length(result)<n then result:=result+' ';
  end;
end;
Function RightStr(const s:ansiString;n:Integer):ansiString;
begin
  if n>=0 then result:=copy(s,length(s)-n+1,n)
          else result:=copy(s,-n+1,length(s));
end;
Function LeftStr(const s:ansiString;n:Integer):ansiString;
begin
  if n>=0 then result:=copy(s,1,n)
          else result:=copy(s,1,length(s)+n);
end;

function ListCount(const s:ansiString;ListDelimiter:ansichar):integer;var i:integer;
begin
  if s='' then begin result:=0;exit end;
  result:=1;for i:=1 to length(s)do if s[i]=listdelimiter then inc(result);
end;

function ListItem;var i:integer;eleje,vege,max:integer;
begin
  eleje:=1;max:=length(s);if max=0 then begin result:='';exit;end;
  for i:=1 to n do begin
    while s[eleje]<>listdelimiter do begin
      inc(eleje);
      if eleje>max then begin result:='';exit end;
    end;
    inc(eleje);
    if eleje>max then begin listitempos:=eleje;result:='';exit end;
  end;
  vege:=eleje;
  while(vege<max)and(s[vege]<>listdelimiter)do inc(vege);
  if(vege<max)or((vege=max)and(s[vege]=listdelimiter))then dec(vege);
  if dotrim then begin
    while(eleje<=vege)and(s[eleje]in [' ',#10,#13,#9])do inc(eleje);
    while(eleje<=vege)and(s[vege]in [' ',#10,#13,#9,listdelimiter])do dec(vege);
  end;
  listitempos:=eleje;
  listitemlength:=vege-eleje+1;
  result:=copy(s,eleje,listitemlength);
end;

procedure SetListItem(var s:ansiString;n:integer;const setto:ansiString;ListDelimiter:ansichar);
begin
  listitem(s,n,ListDelimiter,false);
  delete(s,ListItemPos,listitemlength);
  insert(setto,s,ListItemPos);
end;

procedure DelListItem(var s:ansiString;n:integer;ListDelimiter:ansichar);
begin
  listitem(s,n,ListDelimiter,false);
  delete(s,ListItemPos,listitemlength+1);
end;

procedure InsListItem(var s:ansiString;n:integer;const insertthis:ansiString;ListDelimiter:ansichar);
begin
  listitem(s,n,ListDelimiter,false);
  insert(insertthis+ListDelimiter,s,ListItemPos);
  if RightStr(s,1)=ListDelimiter then setlength(s,length(s)-1);
end;

function ListItemRange(const s:ansiString;from,cnt:integer;ListDelimiter:ansichar;withDelim:boolean=true):ansiString;
var i,st,en:integer;var s2:ansiString;
begin
  result:='';
  st:=max(0,from);
  en:=min(ListCount(s,ListDelimiter)-1,from+cnt-1);
  for i:=st to en do begin
    s2:=ListItem(s,i,ListDelimiter,true);
    if withDelim then ListAppend(Result,s2,ListDelimiter)
                 else result:=result+s2;
  end;
end;

function ListFind(const list:ansiString;const s:ansiString;const delimiter:ansichar):integer;
var i:integer;
begin
  for i:=0 to ListCount(list,delimiter)-1 do
    if cmp(ListItem(list,i,delimiter),s)=0 then exit(i);
  result:=-1;
end;

procedure ListAppend(var list:ansiString;const s:ansiString;const delimiter:ansistring;const distinct:boolean=false);
begin
  if distinct then begin
    if length(delimiter)<>1 then raise Exception.Create('ListAppend distinct only works for 1 char delimiter');

    if ListFind(list,s,delimiter[1])>=0 then exit;
  end;

  if(list<>'')then list:=list+delimiter+s
              else list:=s;
end;

procedure ListAppendNewOnly(var list:ansiString;const s:ansiString;const delimiter:ansistring);
var d:ansichar;
begin
  d:=charn(trimf(delimiter),1);
  if ListFind(list,s,d)>=0 then exit;
  ListAppend(list,s,delimiter);
end;

function ListAppendF(const list:ansistring;const s:ansistring;const delimiter:ansistring;const distinct:boolean=false):ansistring;
begin result:=list;listappend(result,s,delimiter,distinct);end;

function CharN(const s:ansiString;n:integer):ansichar;
begin
  if(n<1)or(n>length(s))then result:=#0
  else result:=s[n];
end;

function Range(const min,value,max:Int64):Integer;   begin if value<min then result:=-1 else if value>max then result:=1 else result:=0;end;
function Range(const min,value,max:Integer):Integer; begin if value<min then result:=-1 else if value>max then result:=1 else result:=0;end;
function Range(const min,value,max:single):Integer;  begin if value<min then result:=-1 else if value>max then result:=1 else result:=0;end;
function Range(const min,value,max:double):Integer;  begin if value<min then result:=-1 else if value>max then result:=1 else result:=0;end;

function Rangerf(const min:Int64;value:Int64;max:Int64):Integer;        begin if value<min then result:=min else if value>max then result:=max else result:=value;end;
function Rangerf(const min:Integer;value:Integer;max:Integer):Integer;  begin if value<min then result:=min else if value>max then result:=max else result:=value;end;
function Rangerf(const min:single;value:single;max:single):single;      begin if value<min then result:=min else if value>max then result:=max else result:=value;end;
function Rangerf(const min:double;value:double;max:double):double;      begin if value<min then result:=min else if value>max then result:=max else result:=value;end;

function Lerp(const a,b:integer;const t:single):integer; begin result:=a+round((b-a)*t);end;
function Lerp(const a,b:int64;const t:double):int64;     begin result:=a+round((b-a)*t);end;
function Lerp(const a,b,t:single):single;   begin result:=a+(b-a)*t;end;
function Lerp(const a,b,t:double):double;   begin result:=a+(b-a)*t;end;
function Lerp(const a,b:TPoint;const t:single):TPoint; begin result.X:=lerp(a.X,b.X,t);result.Y:=lerp(a.Y,b.Y,t);end;
function Lerp(const a,b:TRect;const t:single):TRect; begin result.TopLeft:=lerp(a.TopLeft,b.TopLeft,t);result.BottomRight:=lerp(a.BottomRight,b.BottomRight,t);end;

function UnLerp(const a,b,r:single):single;
begin
  if a=b then exit(0);
  result:=(r-a)/(b-a);
end;

function min3f(const a,b,c:single):single;
begin
  if a<=b then if a<=c then exit(a)else exit(c)
          else if b<=c then exit(b)else exit(c);
end;

function max3f(const a,b,c:single):single;
begin
  if a>=b then if a>=c then exit(a)else exit(c)
          else if b>=c then exit(b)else exit(c);
end;

Function Cmp(const a,b:cardinal):Integer;overload;begin if a=b then result:=0 else if a>b then result:=1 else result:=-1 end;
Function Cmp(const a,b:Integer):Integer;overload;begin if a=b then result:=0 else if a>b then result:=1 else result:=-1 end;
Function Cmp(const a,b:Int64):Integer;overload;begin if a=b then result:=0 else if a>b then result:=1 else result:=-1 end;
Function Cmp(const a,b:single):Integer;overload;begin if a=b then result:=0 else if a>b then result:=1 else result:=-1 end;
Function Cmp(const a,b:double):Integer;overload;begin if a=b then result:=0 else if a>b then result:=1 else result:=-1 end;
Function Cmp(const a,b:TPoint):Integer;overload;
begin
  result:=cmp(a.x,b.x);
  if result=0 then result:=cmp(a.y,b.Y);
end;

Function Cmp(const a,b:ansistring):Integer;overload;
var i,la,lb:integer;ca,cb:ansichar;
begin
  la:=length(a);lb:=length(b);
  if la<lb then i:=la else i:=lb;
  for i:=1 to i do begin
    ca:=CharMapUpperSort[a[i]];cb:=CharMapUpperSort[b[i]];
    if ca=cb then continue;
    if ca>cb then exit(1)
             else exit(-1);
  end;
  result:=cmp(la,lb);
end;

Function StringCmpUpperSort(const a,b:string):Integer;
var i,la,lb:integer;ca,cb:ansichar;
begin
  la:=length(a);lb:=length(b);
  if la<lb then i:=la else i:=lb;
  for i:=1 to i do begin
    ca:=CharMapUpperSort[AnsiChar(a[i])];cb:=CharMapUpperSort[AnsiChar(b[i])];
    if ca=cb then continue;
    if ca>cb then exit(1)
             else exit(-1);
  end;
  result:=cmp(la,lb);
end;

Function Cmp(const a,b:string):Integer;overload;
asm jmp StringCmpUpperSort end;

procedure CharMap(var s:AnsiString;const map:TCharMap);var i:integer;
var p:pansichar;
begin
  p:=@s[1];
  for i:=0 to length(s)-1do
    p[i]:=map[p[i]];
end;

function CharMapF(const s:ansistring;const map:TCharMap):ansistring;
begin result:=s;CharMap(result,map);end;

function Pos(const SubStr,Str:AnsiString;const Options:TPosOptions=[];From:integer=0):integer;
var i,j:integer;
    SubStrLen,StrLen:integer;
    SubStrEnglishUpper:ansistring;
    wwCheck:array[0..1]of boolean;
    wordSet:PSetOfChar;
label WholeWordsRetry;
begin
  result:=0;
  StrLen:=length(Str);
  SubStrLen:=length(SubStr);
  if(strlen=0)or(SubStrLen=0)then exit;

  if poExtendedChars in Options then wordSet:=@wordsetExtended
                                else wordSet:=@wordsetSimple;

  if poWholeWords in Options then begin
    wwCheck[0]:=SubStr[1]in WordSet^;
    wwCheck[1]:=SubStr[length(SubStr)]in WordSet^;
  end else begin
    wwCheck[0]:=false;
    wwCheck[1]:=false;
  end;

WholeWordsRetry:
  result:=0;
  if not(poBackwards in Options)then begin//forwards
    if From>0 then i:=From else i:=1;
    j:=1;
    if not(poIgnoreCase in Options)then begin//sens
      for i:=i to StrLen do begin
        if str[i]=SubStr[j] then begin
          inc(j);if j>SubStrLen then
            begin result:=i-subStrLen+1;break end;
        end else begin
          j:=1;
          if str[i]=SubStr[j] then begin
            inc(j);if j>SubStrLen then
              begin result:=i-subStrLen+1;break end;
          end;
        end;
      end
    end else begin//insens
      SubStrEnglishUpper:=CharMapF(SubStr,charmapEnglishUpper);
      for i:=i to StrLen do begin
        if charmapEnglishUpper[str[i]]=SubStrEnglishUpper[j]then begin
          inc(j);if j>SubStrLen then
            begin result:=i-subStrLen+1;break end;
        end else begin
          j:=1;
          if charmapEnglishUpper[str[i]]=SubStrEnglishUpper[j]then begin
            inc(j);if j>SubStrLen then
              begin result:=i-subStrLen+1;break end;
          end;
        end;
      end;
    end;
  end else begin//backwards
    if From>0 then i:=From else i:=$7fffffff;
    if i>StrLen then i:=StrLen;
    j:=SubStrLen;
    if not(poIgnoreCase in Options)then begin//sens
      for i:=i downto 1 do begin
        if str[i]=SubStr[j] then begin
          dec(j);if j<=0 then
            begin result:=i;break end;
        end else begin
          j:=SubStrLen;
          if str[i]=SubStr[j] then begin
            dec(j);if j<=0 then
              begin result:=i;break end;
          end
        end;
      end;
    end else begin//insens
      SubStrEnglishUpper:=CharMapF(SubStr,charmapEnglishUpper);
      for i:=i downto 1 do begin
        if charmapEnglishUpper[str[i]]=SubStrEnglishUpper[j] then begin
          dec(j);if j<=0 then
            begin result:=i;break end;
        end else begin
          j:=SubStrLen;
          if charmapEnglishUpper[str[i]]=SubStrEnglishUpper[j] then begin
            dec(j);if j<=0 then
              begin result:=i;break end;
          end;
        end;
      end;
    end;
  end;

  if(result>0)and(poWholeWords in Options)then
    if wwCheck[0]and(CharN(Str,result-1)in WordSet^)
    or wwCheck[1]and(CharN(Str,result+SubStrLen)in WordSet^)then begin
      if poBackwards in options then From:=result+SubStrLen-1-1
                                else From:=result+1;
      if InRange(From,1,StrLen)then
        goto WholeWordsRetry;
    end;

  if(result>0)and(poReturnEnd in Options)then
    inc(result,length(SubStr));
end;

function PosMulti(const SubStr,Str:AnsiString;const Options:TPosOptions=[];const st:integer=1;const en:integer=$7fffffff):TArray<integer>;
var op:TPosOptions;
    actp:integer;
begin
  SetLength(result,0);
  op:=Options-[poReturnEnd,poBackwards];
  actp:=st;

  while true do begin
    actp:=pos(SubStr,Str,op,actp);
    if(actp<=0)or(actp+Length(SubStr)-1>en)then break;
    SetLength(result,length(result)+1);
    Result[Length(result)-1]:=actp;
    inc(actp);
  end;
end;

function CountPos(const SubStr,Str:AnsiString;const Options:TPosOptions=[];const st:integer=1;const en:integer=$7fffffff):integer;
var op:TPosOptions;
    actp:integer;
begin
  result:=0;
  op:=Options-[poReturnEnd,poBackwards];
  actp:=st;

  while true do begin
    actp:=pos(SubStr,Str,op,actp);
    if(actp<=0)or(actp+Length(SubStr)-1>en)then break;
    inc(Result);
    inc(actp);
  end;
end;


function Replace(Const SubStr,ReplaceWith:ansistring;Var Str:ansistring;const Options:TReplaceOptions;const From:integer=0):boolean;
var PosOptions:TPosOptions;
    ActPos:integer;
  function CheckWholeWords:boolean;
  const WordSet=['A'..'Z','_','0'..'9'];
    function W(const ch:ansichar):boolean;
    begin result:=charmapEnglishUpper[ch]in WordSet end;
  begin
    if not(roWholeWords in Options)then exit(true);
    result:=(not W(charn(SubStr,1             ))or not W(CharN(Str,ActPos-1             )))
         and(not W(charn(SubStr,length(SubStr)))or not W(CharN(Str,ActPos+Length(SubStr))))

{    result:=not(roWholeWords in Options)or
      ((not(charmapEnglishUpper[CharN(Str,ActPos-1)]in WordSet))
      and(not(charmapEnglishUpper[CharN(Str,ActPos+Length(SubStr))]in WordSet)));}
  end;

label re;
begin
  PosOptions:=[];
  if roIgnoreCase in Options then PosOptions:=PosOptions+[poIgnoreCase];
  if roBackwards in Options then PosOptions:=PosOptions+[poBackwards];

  result:=false;ActPos:=From;
  if not(roBackwards in Options) then begin
    repeat re:
      ActPos:=Pos(SubStr,Str,PosOptions,ActPos);
      if ActPos<=0 then exit;
      if CheckWholeWords then begin
        Delete(Str,ActPos,length(SubStr));
        Insert(ReplaceWith,Str,ActPos);
        inc(ActPos,length(ReplaceWith));
      end else begin
        inc(ActPos);
        goto re;
      end;
    until not(roAll in Options);
  end else begin
    Assert(false,'replace backwards not implemented');
  end;
  result:=true;
end;

function ReplaceF(Const SubStr,ReplaceWith,Str:ansistring;const Options:TReplaceOptions;const From:integer=0):AnsiString;
begin
  result:=Str;
  Replace(SubStr,ReplaceWith,result,Options,From);
end;

function GetLastErrorText:string;
var e:integer;
    error:array[0..511]of char;
begin
  e:=GetLastError;if e=0 then exit('');
  FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM or FORMAT_MESSAGE_IGNORE_INSERTS, nil, e, 0, @error[0], sizeof(error), nil );
  result:=error;
end;

procedure RaiseLastError(const location:string='');
var error:string;
begin
  error:=GetLastErrorText;
  if error<>'' then
    raise Exception.Create('WinError : '+location+' - '+error);
end;


function sar(a,b:integer):integer;asm mov ecx,edx;sar eax,cl end;
function sal(a,b:integer):integer;asm mov ecx,edx;sal eax,cl end;

// CRC16                                                                        //

Function Crc16(data:pointer;len:integer):word;

  function culCalcCRC(crcData:byte;crcReg:word):word;
  const CRC16_POLY=$8005;
  var i:integer;
  begin
    for i:=0 to 7 do begin
      if (((crcReg and $8000) shr 8) xor (crcData and $80))<>0 then
        crcReg:=(crcReg shl 1) xor CRC16_POLY
      else
        crcReg:=(crcReg shl 1);
      crcData:=crcData shl 1;
    end;
    result:=crcReg;
  end;

const CRC_INIT=$FFFF;
var i:integer;
begin
  result:=CRC_INIT;
  for i:=0 to len-1 do begin
    result:=culCalcCRC(PByte(data)^,result);
    pinc(data,1);
  end;
end;

// CRC32                                                                        //

  const
    CRC32tab : Array[0..255] of cardinal = (
      $00000000, $77073096, $ee0e612c, $990951ba, $076dc419, $706af48f,
      $e963a535, $9e6495a3, $0edb8832, $79dcb8a4, $e0d5e91e, $97d2d988,
      $09b64c2b, $7eb17cbd, $e7b82d07, $90bf1d91, $1db71064, $6ab020f2,
      $f3b97148, $84be41de, $1adad47d, $6ddde4eb, $f4d4b551, $83d385c7,
      $136c9856, $646ba8c0, $fd62f97a, $8a65c9ec, $14015c4f, $63066cd9,
      $fa0f3d63, $8d080df5, $3b6e20c8, $4c69105e, $d56041e4, $a2677172,
      $3c03e4d1, $4b04d447, $d20d85fd, $a50ab56b, $35b5a8fa, $42b2986c,
      $dbbbc9d6, $acbcf940, $32d86ce3, $45df5c75, $dcd60dcf, $abd13d59,
      $26d930ac, $51de003a, $c8d75180, $bfd06116, $21b4f4b5, $56b3c423,
      $cfba9599, $b8bda50f, $2802b89e, $5f058808, $c60cd9b2, $b10be924,
      $2f6f7c87, $58684c11, $c1611dab, $b6662d3d, $76dc4190, $01db7106,
      $98d220bc, $efd5102a, $71b18589, $06b6b51f, $9fbfe4a5, $e8b8d433,
      $7807c9a2, $0f00f934, $9609a88e, $e10e9818, $7f6a0dbb, $086d3d2d,
      $91646c97, $e6635c01, $6b6b51f4, $1c6c6162, $856530d8, $f262004e,
      $6c0695ed, $1b01a57b, $8208f4c1, $f50fc457, $65b0d9c6, $12b7e950,
      $8bbeb8ea, $fcb9887c, $62dd1ddf, $15da2d49, $8cd37cf3, $fbd44c65,
      $4db26158, $3ab551ce, $a3bc0074, $d4bb30e2, $4adfa541, $3dd895d7,
      $a4d1c46d, $d3d6f4fb, $4369e96a, $346ed9fc, $ad678846, $da60b8d0,
      $44042d73, $33031de5, $aa0a4c5f, $dd0d7cc9, $5005713c, $270241aa,
      $be0b1010, $c90c2086, $5768b525, $206f85b3, $b966d409, $ce61e49f,
      $5edef90e, $29d9c998, $b0d09822, $c7d7a8b4, $59b33d17, $2eb40d81,
      $b7bd5c3b, $c0ba6cad, $edb88320, $9abfb3b6, $03b6e20c, $74b1d29a,
      $ead54739, $9dd277af, $04db2615, $73dc1683, $e3630b12, $94643b84,
      $0d6d6a3e, $7a6a5aa8, $e40ecf0b, $9309ff9d, $0a00ae27, $7d079eb1,
      $f00f9344, $8708a3d2, $1e01f268, $6906c2fe, $f762575d, $806567cb,
      $196c3671, $6e6b06e7, $fed41b76, $89d32be0, $10da7a5a, $67dd4acc,
      $f9b9df6f, $8ebeeff9, $17b7be43, $60b08ed5, $d6d6a3e8, $a1d1937e,
      $38d8c2c4, $4fdff252, $d1bb67f1, $a6bc5767, $3fb506dd, $48b2364b,
      $d80d2bda, $af0a1b4c, $36034af6, $41047a60, $df60efc3, $a867df55,
      $316e8eef, $4669be79, $cb61b38c, $bc66831a, $256fd2a0, $5268e236,
      $cc0c7795, $bb0b4703, $220216b9, $5505262f, $c5ba3bbe, $b2bd0b28,
      $2bb45a92, $5cb36a04, $c2d7ffa7, $b5d0cf31, $2cd99e8b, $5bdeae1d,
      $9b64c2b0, $ec63f226, $756aa39c, $026d930a, $9c0906a9, $eb0e363f,
      $72076785, $05005713, $95bf4a82, $e2b87a14, $7bb12bae, $0cb61b38,
      $92d28e9b, $e5d5be0d, $7cdcefb7, $0bdbdf21, $86d3d2d4, $f1d4e242,
      $68ddb3f8, $1fda836e, $81be16cd, $f6b9265b, $6fb077e1, $18b74777,
      $88085ae6, $ff0f6a70, $66063bca, $11010b5c, $8f659eff, $f862ae69,
      $616bffd3, $166ccf45, $a00ae278, $d70dd2ee, $4e048354, $3903b3c2,
      $a7672661, $d06016f7, $4969474d, $3e6e77db, $aed16a4a, $d9d65adc,
      $40df0b66, $37d83bf0, $a9bcae53, $debb9ec5, $47b2cf7f, $30b5ffe9,
      $bdbdf21c, $cabac28a, $53b39330, $24b4a3a6, $bad03605, $cdd70693,
      $54de5729, $23d967bf, $b3667a2e, $c4614ab8, $5d681b02, $2a6f2b94,
      $b40bbe37, $c30c8ea1, $5a05df1b, $2d02ef8d  );

Function Crc32(data:pointer;len:integer):integer;
var i:Integer;
begin
  result:=integer($ffffffff);
  for i:=0 to len-1 do begin
    Result:=integer(CRC32tab[Byte(Result xor PByte(Data)^)])xor(result shr 8);
    inc(PByte(data));
  end;
  Result:=not result;
end;

Function Crc32(const s:RawByteString):integer;
begin
  if s<>'' then result:=Crc32(@s[1],length(s))
           else result:=0;
end;

procedure Crc32Init(var h:Integer);
begin
  h:=integer($ffffffff);
end;

procedure Crc32Next(var h:Integer;var data;const len:integer);var i:integer;
begin
  for i:=0 to len-1 do
    h:=integer(CRC32tab[Byte(h xor pbyte(psucc(@data,i))^)]) xor(h shr 8);
end;

procedure Crc32NextChar(var h:Integer;const ch:ansichar);
begin
  h:=integer(CRC32tab[Byte(h xor byte(charmapEnglishUpper[ch]))]) xor(h shr 8);
end;

procedure Crc32Finalize(var h:Integer);
begin
  h:=not h;
end;

Function Crc32UC(data:pointer;len:integer):integer;
var i:Integer;
begin
  result:=integer($ffffffff);
  for i:=0 to len-1 do begin
    Result:=integer(CRC32tab[Byte(Result xor byte(charmapEnglishUpper[pansichar(Data)^]))]) xor(result shr 8);
    inc(PByte(data));
  end;
  Result:=not result;
end;

procedure Crc32UCInit(var h:Integer);
begin
  h:=integer($ffffffff);
end;

procedure Crc32UCNextChar(var h:Integer;const ch:ansichar);
begin
  h:=integer(CRC32tab[Byte(h xor byte(charmapEnglishUpper[ch]))]) xor(h shr 8);
end;

procedure Crc32UCFinalize(var h:Integer);
begin
  h:=not h;
end;

Function Crc32UC(const s:RawByteString):integer;
begin
  if s<>'' then result:=Crc32UC(@s[1],length(s))
           else result:=0;
end;

function Crc32Combine(const c1,c2:integer):integer;
begin
  result:=c1*15485863{big prime}+c2;
end;

// performance monitor                                                          //

var _perfStack:array of record name:string;t0:int64 end;
var _perfreport:string;

procedure perfStart(const aname:string);
var prefix:string;
begin
  if length(_perfStack)>0 then prefix:=_perfStack[high(_perfStack)].name+'.'
                          else prefix:='';
  SetLength(_perfStack,length(_perfStack)+1);
  with _perfStack[high(_perfStack)]do begin
    name:=prefix+aname;
    QueryPerformanceCounter(t0);
  end;
end;

procedure perfStop;
var t1,tf:int64;
begin
  QueryPerformanceCounter(t1);
  if Length(_perfStack)=0 then exit;
  QueryPerformanceFrequency(tf);
  with _perfStack[high(_perfStack)]do begin
    if _perfreport<>'' then _perfreport:=_perfreport+perfOptions.rowDelim;
//    _perfreport:=_perfreport+name+perfOptions.listDelim+inttostr(round((t1-t0)*1000000/tf))+'us';
      _perfreport:=_perfreport+format('%.12s',[name])+{perfOptions.listDelim+}format('%10.3fms',[(t1-t0)*1000/tf]);
  end;
  setlength(_perfStack,high(_perfStack));
end;

procedure perfStopStart(const aname:string);
begin
  perfStop;perfStart(aname);
end;

procedure perf(const aname:string);
begin
  perfStop;perfStart(aname);
end;

function perfReport:string;
begin
  while length(_perfStack)>0 do perfStop;
  result:=_perfReport;
  _perfreport:='';
end;

function IsWild2(const AWild,AInput:ansistring;out AVariablePart:TAnsiStringArray;const AIgnoreCase: Boolean=true):boolean;
var i,WildMinLen,InputPos,InputPos0:integer;
    WildAnyLen:boolean;
    W,M:pansichar;
    MatchStr:ansistring;
    po:TPosOptions;
begin
  if AWild='' then exit(AInput='');

  po:=[];
  if AIgnoreCase then Include(po,poIgnoreCase);

  if(@AVariablePart<>nil)then setlength(AVariablePart,0);
  W:=pointer(AWild);InputPos:=1;
  repeat
    InputPos0:=InputPos;

    //1. process ?,*
    WildMinLen:=0;WildAnyLen:=false;
    while true do begin
      case W[0] of
        '?':inc(WildMinLen);
        '*':WildAnyLen:=true;
      else break end;
      inc(W);
    end;

    //1.b skip minimal number of ?'s
    inc(InputPos,WildMinLen);
    if InputPos>length(AInput)+1then exit(false);

    //2. get matching fragment
    M:=W;
    while not(W[0] in ['*','?',#0])do inc(W);
    MatchStr:=StrMake(M,W);

    //3. find matching fragment in Input
    if MatchStr='' then begin
      if WildAnyLen then
        InputPos:=Length(AInput)+1;
    end else begin
      if InputPos+Length(MatchStr)-1>Length(AInput)then
        exit(false);//AInput is too small

      if WildAnyLen then begin
        InputPos:=Pos(MatchStr,AInput,po,InputPos);//only the 1st match
        if InputPos<=0 then exit(false);
      end else begin
        if AIgnoreCase then begin
          for i:=1 to Length(MatchStr)do if charmapEnglishUpper[MatchStr[i]]<>charmapEnglishUpper[AInput[i+InputPos-1]]then exit(false);
        end else begin
          for i:=1 to Length(MatchStr)do if MatchStr[i]<>AInput[i+InputPos-1]then exit(false);
        end;
      end;
      InputPos:=InputPos+Length(MatchStr);//advance
    end;

    if(@AVariablePart<>nil)and((WildMinLen>0)or WildAnyLen)then begin
      SetLength(AVariablepart,length(AVariablepart)+1);
      AVariablepart[length(AVariablePart)-1]:=Copy(AInput,InputPos0,(InputPos-Length(MatchStr))-InputPos0);
    end;

  until W[0]=#0;
  result:=InputPos=Length(AInput)+1;
end;

function IsWild2(const AWild,AInput:ansistring;const AIgnoreCase: Boolean=true):boolean;
type PAnsiStringArray=^TAnsiStringArray;
begin
  Result:=IsWild2(AWild,AInput,PAnsiStringArray(nil)^,AIgnoreCase);
end;

function IsWild2(const AWild,AInput:ansistring;out AVariablePart0,AVariablePart1,AVariablePart2,AVariablePart3:ansistring;const AIgnoreCase: Boolean=true):boolean;
var vp:TAnsiStringArray;
begin
  Result:=IsWild2(AWild,AInput,vp,AIgnoreCase);
  if result then begin
    if Length(vp)>0 then AVariablePart0:=vp[0] else AVariablePart0:='';
    if Length(vp)>1 then AVariablePart1:=vp[1] else AVariablePart1:='';
    if Length(vp)>2 then AVariablePart2:=vp[2] else AVariablePart2:='';
    if Length(vp)>3 then AVariablePart3:=vp[3] else AVariablePart3:='';
  end;
end;

function IsWild2(const AWild,AInput:ansistring;out AVariablePart0:ansistring;const AIgnoreCase: Boolean=true):boolean;
var s1,s2,s3:AnsiString;
begin
  Result:=IsWild2(AWild,AInput,AVariablePart0,s1,s2,s3,AIgnoreCase);
end;

function IsWild2(const AWild,AInput:ansistring;out AVariablePart0,AVariablePart1:ansistring;const AIgnoreCase: Boolean=true):boolean;
var s1,s2:AnsiString;
begin
  Result:=IsWild2(AWild,AInput,AVariablePart0,AVariablePart1,s1,s2,AIgnoreCase);
end;

function IsWild2(const AWild,AInput:ansistring;out AVariablePart0,AVariablePart1,AVariablePart2:ansistring;const AIgnoreCase: Boolean=true):boolean;
var s1:AnsiString;
begin
  Result:=IsWild2(AWild,AInput,AVariablePart0,AVariablePart1,AVariablePart2,s1,AIgnoreCase);
end;

function IsWild2(const AWild,AInput:ansistring;out AVariablePart0:single;const AIgnoreCase: Boolean=true):boolean;overload;
var p0:ansistring;
begin
  if not IsWild2(AWild, AInput, p0, AIgnoreCase)then exit(false);
  result:=TryStrToFloat(p0, AVariablePart0);
end;

function IsWild2(const AWild,AInput:ansistring;out AVariablePart0,AVariablePart1:single;const AIgnoreCase: Boolean=true):boolean;overload;
var p0,p1:ansistring;
begin
  if not IsWild2(AWild, AInput, p0, p1, AIgnoreCase)then exit(false);
  result:=TryStrToFloat(p0, AVariablePart0)
      and TryStrToFloat(p1, AVariablePart1);
end;

function IsWild2(const AWild,AInput:ansistring;out AVariablePart0,AVariablePart1,AVariablePart2:single;const AIgnoreCase: Boolean=true):boolean;overload;
var p0,p1,p2:ansistring;
begin
  if not IsWild2(AWild, AInput, p0, p1, p2, AIgnoreCase)then exit(false);
  result:=TryStrToFloat(p0, AVariablePart0)
      and TryStrToFloat(p1, AVariablePart1)
      and TryStrToFloat(p2, AVariablePart2);
end;

function IsWild2(const AWild,AInput:ansistring;out AVariablePart0,AVariablePart1,AVariablePart2,AVariablePart3:single;const AIgnoreCase: Boolean=true):boolean;overload;
var p0,p1,p2,p3:ansistring;
begin
  if not IsWild2(AWild, AInput, p0, p1, p2, p3, AIgnoreCase)then exit(false);
  result:=TryStrToFloat(p0, AVariablePart0)
      and TryStrToFloat(p1, AVariablePart1)
      and TryStrToFloat(p2, AVariablePart2)
      and TryStrToFloat(p3, AVariablePart3);
end;

////////////////////////////////////////////////////////////////////////////////
///  16byte Dynamic Array Alignment patch                                    ///
////////////////////////////////////////////////////////////////////////////////

{$IFDEF SSE_DYNARRAYS}

type
  TReallocMem=function(var P:pointer;Size:Integer):pointer;
  TGetMem=function(Size:Integer):Pointer;
  TFreeMem=function(P:Pointer):Integer;

var
  originalReallocMem:TReallocMem;
  originalGetMem:TGetMem;
  originalFreeMem:TFreeMem;

function DynArray_IsShifted(p:pointer):boolean;inline;
begin
  result:=(p<>nil)and((integer(p)and $F)=8)and(pinteger(integer(p)-4)^=integer(p)xor $19691003);
end;

function DynArray_ShifBack(var p:pointer):boolean;inline;
begin
  result:=DynArray_IsShifted(p);
  if Result then
    pDec(p,8);
end;

function DynArray_Shift(var p:pointer):boolean;inline;
begin
  result:=(p<>nil)and((integer(p)and $F)=0);
  if result then begin
    pInc(p,8);
    pinteger(integer(p)-4)^:=integer(p)xor $19691003;
  end;
end;

function DynArray_ReallocMem(var P:pointer;Size:Integer):pointer;
var wasShifted:boolean;
begin
  wasShifted:=DynArray_ShifBack(p);

  result:=originalReallocMem(p,Size+8);

  if DynArray_Shift(p)then
    if not wasShifted then
      system.move(pPred(p,8)^,p^,Size-8);
end;

function DynArray_GetMem(Size:Integer):Pointer;
begin
  Result:=originalGetMem(Size+8);
  DynArray_Shift(Result);
end;

function DynArray_FreeMem(P:Pointer):Integer;
begin
  DynArray_ShifBack(p);
  Result:=OriginalFreeMem(P);
end;

{$O+}{$R-}{$B-}
procedure PatchSSEDynArrays;
var p_DynArrayClear,p_DynArrayCopyRange:pointer;
    arr1,arr2:TArray<integer>;
    i:integer;
begin
  SetMinimumBlockAlignment(mba16Byte);

  //get original memory managger functions
  originalReallocMem:=PatchGetCallAbsoluteAddress(@DynArraySetLength,$455-$390);
  originalGetMem    :=PatchGetCallAbsoluteAddress(@DynArraySetLength,$464-$390);

  p_DynArrayClear    :=PatchGetCallAbsoluteAddress(@DynArrayClear,0);
  originalFreeMem    :=PatchGetCallAbsoluteAddress(p_DynArrayClear,$695-$660);

  p_DynArrayCopyRange:=pSucc(p_DynArrayClear,$56C-$660);//relative to dynaclear

  //patch dyn array functions
  PatchRelativeAddress(pSucc(@DynArraySetLength  ,$456-$390),@DynArray_ReallocMem,@originalReallocMem);
  PatchRelativeAddress(pSucc(@DynArraySetLength  ,$465-$390),@DynArray_GetMem    ,@originalGetMem    );

  PatchRelativeAddress(pSucc(p_DynArrayClear    ,$696-$660),@DynArray_FreeMem   ,@originalFreeMem   );

  PatchRelativeAddress(pSucc(p_DynArrayCopyRange,$5F3-$56C),@DynArray_GetMem    ,@originalGetMem    );

  //test functionality

  setlength(arr1,32);
  for i:=0 to high(arr1)do arr1[i]:=i;
  arr2:=arr1;
  setlength(arr2,16);
  for i:=0 to high(arr1)do if arr1[i]<>i then raise Exception.Create('SSEDynArrayPatch failed');
  for i:=0 to high(arr2)do if arr2[i]<>i then raise Exception.Create('SSEDynArrayPatch failed');

  arr1:=nil;
  arr2:=nil;
end;

{$ENDIF}

////////////////////////////////////////////////////////////////////////////////

initialization
{$IFDEF SSE_DYNARRAYS}
  PatchSSEDynArrays;
{$ENDIF}
  DetectSSEVersion;

  if SysUtils.FileExists('c:\het')then
    ReportMemoryLeaksOnShutdown:=true;

  with FormatSettings do begin
    DecimalSeparator:='.';
    ListSeparator:=';';
    DateSeparator:='.';
    ShortDateFormat:='yyyy.mm.dd';
    LongDateFormat:='yyyy.mm.dd';
    TimeSeparator:=':';
    ShortTimeFormat:='hh:nn:ss.zzz';
  end;

  InitHetFormatSettings;
  MakeCharmapUpperSort;

  OnIdleList:=TOnIdleList.Create;
  Application.OnIdle:=OnIdleList.OnIdle;

  RegisterFileHandler(TWin32FileHandler.Create);

finalization
  Application.OnIdle:=nil;
  FreeAndNil(OnIdleList);
end.
