unit UGauge;//system het.patch

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, het.Utils, het.Gfx, math;

type
  TGaugeValue=class
    FValue:double;
    FLabel,FFormat,FUnit:ansistring;
    FColor:TColor;
  end;

function GaugeValue(const ALabel:ansistring;const AValue:Double;const AFormat,AUnit:ansistring;const AColor:TColor=0):TGaugeValue;

type
  TGaugeScale=class
    FLeft,FRight:double;
    FSegs:array[0..2]of integer;
    FFormat:ansistring;
    FUnit:ansistring;
    FColor:TColor;
  end;

function GaugeScale(const ALeft,ARight:Double;const ASegs0,ASegs1,ASegs2:integer;const AFormat,AUnit:ansistring;const AColor:TColor=0):TGaugeScale;

procedure DrawGauge(const ACanvas:TCanvas;const RDst:TRect;const AData:array of const);

implementation

var _bmAnalogMeter:TBitmap;function bmAnalogMeter:TBitmap;const data:ansistring=
'ÿØÿà'#0#16'JFIF'#0#1#1#1#0'`'#0'`'#0#0'ÿá'#0'6Exif'#0#0'II*'#0#8#0#0#0#2#0#1#3#5#0#1#0#0#0'&'#0#0#0#3#3#1#0#1#0#0#0#0#0#0#0#0#0#0#0' †'#1#0'±'#0#0'ÿÛ'#0'C'#0#8#6#6#7#6#5#8#7#7#7#9#9#8#10#12#20#13#12#11#11#12#25#18#19#15#20#29#26#31#30#29#26#28#28' $'+
'.'#39' ",#'#28#28'(7),01444'#31#39'9=82<.342ÿÛ'#0'C'#1#9#9#9#12#11#12#24#13#13#24'2!'#28'!22222222222222222222222222222222222222222222222222ÿÀ'#0#17#8#0'´'#1'$'#3#1'"'#0#2#17#1#3#17#1'ÿÄ'#0#31#0#0#1#5#1#1#1#1#1#1#0#0#0#0#0#0#0#0#1#2#3#4#5#6#7#8#9#10#11+
'ÿÄ'#0'µ'#16#0#2#1#3#3#2#4#3#5#5#4#4#0#0#1'}'#1#2#3#0#4#17#5#18'!1A'#6#19'Qa'#7'"q'#20'2‘¡'#8'#B±Á'#21'RÑğ$3br‚'#9#10#22#23#24#25#26'%&'#39'()*456789:CDEFGHIJSTUVWXYZcdefghijstuvwxyzƒ„…†‡ˆ‰Š’“”•–—˜™š¢£¤¥¦§¨©ª²³´µ¶·¸¹ºÂÃÄÅÆÇÈÉÊÒÓÔÕÖ×ØÙÚáâãäåæçèéêñòóôõ'+
'ö÷øùúÿÄ'#0#31#1#0#3#1#1#1#1#1#1#1#1#1#0#0#0#0#0#0#1#2#3#4#5#6#7#8#9#10#11'ÿÄ'#0'µ'#17#0#2#1#2#4#4#3#4#7#5#4#4#0#1#2'w'#0#1#2#3#17#4#5'!1'#6#18'AQ'#7'aq'#19'"2'#8#20'B‘¡±Á'#9'#3Rğ'#21'brÑ'#10#22'$4á%ñ'#23#24#25#26'&'#39'()*56789:CDEFGHIJSTUVWXYZcdefg'+
'hijstuvwxyz‚ƒ„…†‡ˆ‰Š’“”•–—˜™š¢£¤¥¦§¨©ª²³´µ¶·¸¹ºÂÃÄÅÆÇÈÉÊÒÓÔÕÖ×ØÙÚâãäåæçèéêòóôõö÷øùúÿÚ'#0#12#3#1#0#2#17#3#17#0'?'#0'ùşŠ'#0#39'¥t'#27'ğ¬úÖë‰'#1'[T8'#39'»'#26'¡7c›'#3'=)â)'#15'HÛò¯Sƒ@·¶ÂÛÙF'#0'ş,dşupi·'#39'îÀ1ô cÈ|‰ç“ÿ'#0'ß&—ìóÿ'#0'Ï'#25'?ï“^Â4»Ïùä?*'+
'xÒoçˆü¨'#14'sÆşÍ?üñ“şù4}ùã'#39'ıòkÙ†‘}Ÿõ"—û"÷'#31'êE'#2'ç<cìóÿ'#0'Ï'#25'?ï“Iöy€Ï“'#39'ıòkÚ?±ï±ş¨Qı|åü¨'#14'sÅü‰Oü²ûäÑäMÿ'#0'<Ÿşù5í'#31'Ø×ƒşY'#10'_ì{ÏùåúP'#28'ç‹'#11'yHŸşù4L¿óÉÿ'#0'ï“^Ô4‹Áÿ'#0',J?²/çé@s-öy¿ç“ÿ'#0'ß&"oùäÿ'#0'÷É¯işÉ¼ÿ'#0''+
'?¥'#31'Ø÷óÄP'#28'ìñS'#12'£¬oÿ'#0'|šQ'#4'¤q'#19'ÿ'#0'ß&½§û'#30'óşxş”ŸØ÷}¡ı('#14'sÅ¼©?ç›ÿ'#0'ß&*Bqå¿ıó^Óıyÿ'#0'<JOìk¿ùãúP'#28'çŒ'#24'%'#29'bûäĞ ”ŒˆŸ'#31'îšöìk³ÿ'#0',J?±îÿ'#0'çé@s/äMÿ'#0'<Ÿşù4y'#19'g'#30'Sÿ'#0'ß&½§û'#30'óşxş”ŸØ÷ŸóÇô 9Ï'#23'û<ßó'+
'Éÿ'#0'ï“GÙæÿ'#0'Oÿ'#0'|šöì‹ÏùãúRÿ'#0'cŞÏ!ùP'#28'ç‹}oùäÿ'#0'÷É£ìóÏ'#39'ÿ'#0'¾M{Oö=æÔş”cŞcıOéKPç<[ìóÏ'#23'ÿ'#0'¾M'#31'g›şy?ıòkÚ±ï?ç'#39'ö=çüñ'#20'j'#28'ç‹ù'#19'Ï'#39'ÿ'#0'¾M'#30'D¿óÉÿ'#0'ï“^Ît‹¿ùãúR'#29'"ë?êGåF¡ÎxÁŠAÕ'#27'ò¦AÁ'#4'W³'#29'&|'#29+
'Ğ'#15'Ê —C.¿=º6{'#21#6'€ç<~Šô=OÁKt¬m¢'#16'ÏÔ'#1'Âµp7'#22'òZÜ<'#19')Y'#16'á ¥+‘QE'#20'Ê&¶Mò…õ ~µô?ƒô$‹Áöx@'#25'Óy8îOøb¾}°'#25'¸_@À×Ö'#30#25'„7…´ó°¨0&'#1'ú'#10'RØ›]” ĞcÚ>AZ'#16'èQãî'#10'Ü‚Ü`qWã€c¥+…y4'#24'ÿ'#0'¸*uĞ¢şà®…a'#3'µL!_J.'#22'G64(¿¸)ßØQpWGå'+
#10'<¡EÂÈç°¢şàü¨şÂ‹û‚º?,Rl¢áds§B‹ûƒò£û'#10'/î'#10'è¼ºpŒzQp²9¿ì(¿ç˜ü©°¢şà®Ëö£Êö¢ác›şÂ‹û‚ì(¿¸?*é'#12'\ô¤òÇ¥'#23#11'#œşÂ‹û‚ì(¿çšşUÒy~Ôy~Ô\,sû'#10'/î'#10'Oì(¿¸?*é<¿jO+Ú‹…‘ÎaEıÁùQı…'#23'÷'#5't~Xô¥òı¨¸Y'#28'ßö'#20'_óÍ*_ì(¿¸+£òı¨òı¨¸Xæÿ'#0'°¢şàü¨şÂ‹û'+
'ƒò®Êö£Ë'#30'”\9QÎaEıÁKı…'#23'÷'#7'å]'#31'–(òÇ¥'#23#11#28'ÙĞ¢ÇÜ'#20'Ó¡EıÁ]7”'#8'éG’´\,\èQp~U'#27'hQp~UÔ˜½©†!éJádrO¡EıÁùUi4'#24'ùù'#5'vM'#0'ô¨$€`ñEÂÈáäĞ0;'#6'ExoÅ'#29'tÏ'#19',¨ '#11'„'#14'qëşE}=-¸ô¯'#6'øñ'#8'ûN`'#6'Lg'#39#29'y¡=BÖ<rŠ(«(µ§ÿ'#0'Ç'+
'ÒsüB¾Âğôxğİ€<şá9Çµ|}§ÇÒ¼+ìo'#14'('#30#25'Óğ0<„Çä)OdJÜÖ…8'#21'v5â«Ä8'#21'm'#7#21'%'#14#11'R'#1'Å §'#10#0'Z(¢˜'#5#7'¥'#20'P'#2#1'ŠZ( '#2'Š( '#2'“'#20'´P'#1'E'#20'P'#1'E'#20'P'#2'b–Š('#0'¢Š('#0'¤Å-'#20#0'˜¢–“'#20'€(¢Š'#4#20'Â)ô”'#12'Œ­DëS‘LaH'#10'2§µ|'+
'ÿ'#0'ñø‘§®'#14'<£üëèYE|ùûA.5'#29';ş¹'#31'çMn&x'#20'QV2Şÿ'#0#31'qÿ'#0'¼+ìÍ'#5#2'ørÁT'#16'¢'#4#3'?A_'#26'i¿ñù'#31'ûÂ¾ÏÑ'#6'<=eÎpŸú'#8'¥=–æ¤CV“¥V‹¥ZJ'#20'êJZ '#10'(¢€'#10'(¢€'#10'(¢€'#10'(¢€'#10'(¢€'#10'(¢€'#10'(¢€'#10'(¢€'#10'(¢€'#10'(¢€'#10'(¢'+
'€'#10'LRÑ@'#5'%-% '#18'˜Â¤¦0¤'#5'ikçßÚ'#19#31'nÓq×Ë9üëè9+ç¯Ú'#20'ÿ'#0'ÄÇN'#24'ÿ'#0'–_ÔĞ·'#19'<FŠ(­'#6'\Óãñ3Ó5öŒ1 Ù'#12'ÿ'#0'Ë'#4'ÿ'#0'ĞE|[§ÇÒ¼+í-'#27'ş@6?õÁ?ô'#17'J['#9'niÅÒ­/J«'#23'J´µ'#3#31'N'#29')‚œ:S'#1'h¢Š`'#20'QE'#0#20'QE'#0#20'QE'#0#20'QE'#0+
#20'QE'#0#20'QE'#0#20'QE'#0#20'QE'#0#20'QE'#0#20'QE'#0#20'”´R'#1#7'J)i('#0'¦1§÷¦5 +Ë÷kçŸÚ'#16'ƒ©i '#30'D\şuô4½'#13'|óûAø™éÇ'#31'òÄÿ'#0':'#22'âg‰QE'#21' Ëzwü}'#39'ûÂ¾ÏĞÏüSö?õÁ?ô'#17'_'#24'iç'#23'Işğ¯³´<'#2'Ä'#31'ùàŸÈRÈKvkÅÒ¬­V‹ «)Ò¡'#12'x§'#1'IN¦'#2+
'RÑE0'#10'(¢€'#10'(¢€'#10'(¢€'#10'(¢€'#10'(¢€'#10'(¢€'#10'(¢€'#10'(¢€'#10'(¢€'#10'(¢'#5#20'Rf€'#22'ÒÒP'#1'Lj}1©'#1'Z_»_<şĞcş&Zw?òÌµô4§ŒWÎÿ'#0'´'#16'Û«XrÑ×ëBÜLñZ(¢´'#25'jÃş>Pç¸¯´tƒÿ'#0#18'K/úàŸú'#8'¯‹¬ãáŞ'#21'ö†ÿ'#0' ;'#31'úàŸú'#8'¥=–ìÖ‹¥YZ«'#23+
'AVV d‚M'#20'áL'#2'–’–˜'#5#20'Q@'#5#20'Q@'#5#20'QH'#2'Š*®£'#30'›c-Ü ”'#3#3'ø‰ '#1'ø’'#5#0'Z¢³ôÛ««–ŸÏX6)'#10''#9'$'#19'üC'#39'®'#15#25'ã¿'#28'V…0'#10'*½Õíµ’£\Ì‘+¶ĞÎp3õ¬ÿ'#0'øI´ÖD{wšé\‘ºŞ'#22'('#7#4'’'#6#0'â€6(¨-.’òÖ+˜ÕÖ9T2‡R­ƒê'#15'J€'#10'(¢€'#10+
'(¢€'#10'(¢€'#10'LqKE '#10'JZJ'#0'JcSéH'#10'Ót¯?h3ÿ'#0#19'M7Ÿùgş5ô<İ+çÚ'#15'şBºw'#31'òÏúš'#22'âg‹QE'#21' Ë6?ñğ¿ï'#10'û?D$èV9ÿ'#0''#9'ÿ'#0' ŠøÆÇ'#31'hQşĞ¯³tOù'#0'Øãşx'#39'ş‚)OdJÜØ‹ «+Ò«EĞU¤éRPñN¦Šu'#0#20'´”†DS‚ê'#15'¡4'#0'ê;ÑE0'#10'(¢€'#10'(¢'#21'ï'+
'nÅœ'#6'S'#12'Ó'#30'‚8Ss1ö'#21'ÎjúÌÖ'#6'=B'#17'e'#29'ÆQm‹«ÈË2Çî¯$'#12#12'òG=««ªwz]…ü‰%å”'#23#12'€„2Æ'#27'h$'#19'×è?*bg3çÿ'#0'gÄ¶örJÒ†WHap'#3'`m'#8#1'à+'#16'SÕMJÚäÈ]&Ô'#19'”ÁhÂ›OÏ&}'#9'!GĞšê'#5'¼!÷ˆ7'#28'í'#25'ãJ°Ä‹µ"E_@ '#10#5'c—šı®­gc0¸Š'#0'×,@'+
#4'$h¤'#1'¸'#19'0'#39'#¶qU'#31']·‘n,'#18'şÚXàp¥—nÆ"5b /T\äü/zìã‚(·ùq"oÆíª'#6'p1Ïà'#0'¨#ÓlbR±Ù[¢Ù'#11#18'Œç¯nıè'#11#28'İÎ¹¨Dñ¥«‰î'#0#12'mğ¿>ì'#4'Rİ'#7' ’G\68'#2'›'#14'·ww$°ı­Y#ˆ4’Æ'#2'ªq’wuéÉ<q×"ºÑ'#4'A·'#8'Ó>¡G¦?—'#20'í‰‚6Œ'#30'£'#29'h'#11'3'#31'Ã'+
#18'İ\éFîæí®'#18'æV–'#13'ÁAHİ'#7#3'¯Ç'#29'«j'#0#6#0'À'#29'…-"‚Š( '#2'Š( '#2'Š:R'#2#15'B'#13#0'-%-%'#0#21#27'T•'#27'R'#2'´İ+çÚ'#12'ím8'#15'ùçÏë_DMÒ¾wı ÕF«§'#17'ÔÇÏëBÜLñj(¢´'#25'fËızÿ'#0'¼+ìı'#15'ş@6'#7'şÓÿ'#0'A'#21'ñ…—úõÿ'#0'xWÙÚ'#25'Îaÿ'#0'^ñÿ'#0+
'è"”öB[³^2'#2'ä'#7'©«!ÕA,Ê '#12'œœ`zšÍ½€\éw'#16'’€<d'#18'ç'#10#7'¹¬ù´Èá›ÍI¡9'#12'L#¸˜fãi—'#39'Œ'#0'ËÙ'#31'@'#29'*È„)'#14'¤7İ ~”ıËœddvÍr2i’y®ZÊÅ‰ó'#10'Û4Ê'#5'¶ğ€'#30'œ}ÒÇ'#3'«qš?²'#39'C©ŸİM-Å¾Õ¹2 ÏîÑy8Ü2Ê{â˜\èµMRÛH³ûUÓ'#21'ˆ0R@É'#25'ö¬;ï'#23'é'#22+
'öÆKxÄÄd'#2'˜'#11'şñ=?hj(š¦ŠÉx±[±a„–U##‘’'#15'zó©íµˆo^Î;('#24'©á"è û'#14'‚¥¶;ß…õÔÔƒ@f'#18'H'#1'sµ'#10'„çîŠé+—ğƒq¦¬·w¡Vâ`'#0'@>ê×I$ñDTI*!c…'#12'ÀdûU-€ye'#12#20'°Üz'#12'óH$F '#7'RHÈÁê=k'#27'YÒ?´î£xâdŠ)19'#3'xr¥UsÔ'#12'1?•TÓ´››}ZŞvÓà†'#21'2¾c‘s'#25'l'+
'€>è'#25'àq–ö¦#¦¢’–…! '#2'IÀ'#29'MPÖµ«'#15#15'é3êz•ÂÃk'#10'å˜õ>Àw'#39'Ò¾cñïÆ=[Ä÷R[i®öZN6ˆÃKîÄ*'#18#19'gºø‡â·†<>í'#9'¹{Û‘ÿ'#0',­Fì'#31'vè+ˆ½øízï;AŒ/c4…ä'#0'¯'#9'_»Œ†'#9#3#30'å£É«CÅúª'#28#5'µ'#24'ÿ'#0'¦"„]¼Ÿ'#27'¼J­—Ò,™}'#2'¸şµ·§|wµÊ®­£O'#14'z½'+
'»ïÇàqüëÂ'#15'Œõ‚'#15'üzÿ'#0'ß‘Q?Šµ)TïKR?ë'#20'h'#23'‘ö'#22'âİ'#19'ÄĞùš]ôs0'#25'1Ÿ•×ê§šÛ¯‡"ñ'#30'£kq'#29'Å´‹o*'#29'ÊĞåH>¹'#21'îŸ'#12'ş6&¢ğèŞ'#39'”%Û°Ho1…@Ş‡Ş•ŠO¹íôQE"ˆæ'#8'İ‘çYW{+8'#4'/©ö¡n`r'#39'‹Œ '#14#14'áíë\¾·¦Ü\ê—±Â°"İÀ‰ó¶ZFÊã'#31'!Ú'#0'S'+
'HèqR'#14'Yu'#29'6÷}ºı•T'#8'ƒƒ¼†9;‚›ã'#0''#8' W:Š*+y$’'#21'ic'#17'ÉüH'#27'vßÆ¥$'#1'’p('#25'‡yâ'#29'.Öîx/§'#17'¬D.'#10'’'#9'ÆyÇÖ±çñ^›'#22'µ'#9'ûJÚÙ"–Ü'#16'ær}±÷j·Šô©-5FÔÖ?´E/H'#1#0'´˜ã¯QÇnx®sL†ÿ'#0'Ä'#23'©'#24'µH¢w*Ò¾'#7'#¨'#30'üt¨w¸]'#30'µ'#13'Ô3G'+
#11'¬‹ûåÜ€œ'#22#24'Ï'#20'¢xYK,¨T6ÒC'#12#3'éõ¬×Óe7'#22'›'#4#6#8'TpÜ0`x#ƒ=2*œ'#30#31'¸Šİ¢ia|ğVPdSò•İÎ'#8'>ƒœsÍXƒr’@a‘Á'#25'éMb2FFGjÅµğï‘%ÛM$W'#30'r²ªÈ™'#7',Xn'#7'#ƒíI&Šæ|*C'#12'1Û4'#8'Ñ·Ìà…ÆFŞ1R1Ú'#26'S'#28'®GJùßöƒ'#24'Õ´îzÅùrkßm->Ã§¤'#7'fàK7–»W$óØ'+
'W€şĞyşØÓÿ'#0'_ÔĞ·'#6'x½'#20'QZ'#12'µf?x'#15'ûB¾ÎĞ@şÀ²Æ'#15'î'#19#31'÷È¯ô+A=¥äáw5¸'#15'·Ôdgô¯ª|'#3'©ÛêŞ'#15'±x&'#18'2D±¹î'#8#24'©ÂìŞÔmšóFº¶FDib*'#25'Î'#2'ûšÎ]1í%°‘äµt´Ş'#11'¼Ê„«8*Ç*zàğ1ÏC['#18'Û››'#25'íò'#20'É'#27'&OlŒVdÚF£s'#27'ÊÑZ¥ÊÇ'#28'p…˜áJn'+
'ùÉ+şÖ6xÏ5)ƒ%´²M×'#22#15'kc,›dß9‘YßqÈÜ¸Îzg>œTo¤Å¶+3%œb(`'#18'F'#10'ñ±÷1ÚF?1Ş¯éz}Õ•íÔ“yM'#28'ÎÎ'#25'$=Èş'#29'¼ßF¢şË¼KıRuŠÚXîòQe”ãî"á—gL©ïÓµ0(jö'#17'G&çšÉQ.'#21'ÂË2F0!ÙTôÇJ³g£½·ˆî5Çx'#12'3ƒÑ†'#17'vG†Î'#6'yB9íŒw¥³ğìÖºGösÉ'#28'ûnbŸí'#18'g|€:³nÎyÂí'#28+
'ôÀã'#21'­wm-îyhÁ"óQ¢‡ÍÁ\'#2'F=sÅ'#1'bÁ'#16'á'#12'¨'#28'ã'#11'¸dç8şGò®wÄÚ{j'#19'[Ï'#20'ÖÁm£°™—'#7#12'™'#25'?w¡ù‡J˜è—W·>}ñ·Nc'#27'`f8'#8'¯†'#12'@Ãn|Lu56Ÿ¤]ÛIn÷W'#17'NÑµÁv'#11'·˜À:g'#3'Ÿz'#0'«-€Õã¸–Öâ'#25#4'—!•ÒEuQå¢“ÇF'#27'N1Ï?>M&ñ\Km'#20'1'#9'/'+
#18'i#S³åVP½'#6#15#0'±'#30'§Úµ4‹'#39'Ó´«{Y'#10'´‘®'#25'—¡5v€'#10'l’,Q´ÁUA$ÀS«–ñ® `Ó’É'#14#26'äüØşàëş'#20#12'á|JÃÆÚ {Œ6'#1'Ä'#16'8È?íŸsTWÂZ'#21'º–}.Äåá'#31'á[vñ„Œ'#29'¥Tÿ'#0'³\G5ö»´[k³'#13'¼Iæ_Ü/'#27#19'ûƒÜÒİ“¦ìÊÔïôi¯$Ó¼;áÍ>òt'#4'Ipğ¨Š#õÅr'#23'¶z'+
'D2–Õ5h'#12'½áÓmÔí'#5'gjş!kˆşÃ¦!³ÓS'#18#28#25'?ÚsÜÖ'#21']Xé'#1'ğ“¢]V#ı÷'#24'~@ÖÖ•j#ıö˜tj'#5#25'ki­Õ&ÇÓ'#25'5ÀÓâ–HdY"vGSÊpE'#22'L9Ooğì'#20'ñ'#2'4k¢Ù[ŞÇÄ¶òÀ¡—ôäV½Ç‚´iQŒzu¬dò'#10'Ä'#6'+Ê4­lêòB³ÍäkpœÚŞ'#14'<Ü'#3'ı}kÙ|5â'#4'ñ'#6'”%lÇs'#17'òç‹o(â¥'+
'«'#2'¶Ìë¼'#7'­K'#26'aßLd–!›y'#27'« ş'#19'î?•wUä²—µ¹Šæ D±°tlw'#29'«Ô¬nÒúÊ'#27'˜şìŠ'#24'P4e^iSO¨ÜÉöxd3'#4'ò®Y¾k}£°ë×$c¹ç'#20'’h³¤÷SG"H<èå·„ü»'#20'8w\ú³dçéKya®I©Í5® ‘Ú°]‘“Êàsü>µkìW'#14'¶æq'#28'²Å'#11#6''#28'39'#24'àã‚ß'#0'RŸOÕä³v³¸K[™®LÌ¢N'#2'à'#0'¤'+
'íl'#1'<S¬´ıamo"Ô/'#18'o6=±üù'#0'óŸà_ëOşÏºÙ'#26'ù)…L'#31'˜}ß›÷};äg·'#6'¦]+í'#13'hn–6‚'#20'oôg]À1#'#7'®>Q‘Ó½'#0'WÖá@öÁÑ&V”4Šä—TP3°'#5'$'#12'…ÏO¯5Ÿ'#6'‘ö÷Šé#µVà™#F '#0#25'0'#10'”'#4'|ª8ã$ç85%î{'#28'Q®ÿ'#0'>5fÀXË€¹}ŠÊNX'#13'êzÿ'#0#0'Ï­ZÓt™íôˆ­¶"l’'#2'£'+
#27'~HÊõ'#28'óÁ?áØ'#17'>…§=€¸7'#19'¤²'#23'òc*s¶%ûŠÚÁÉúÖ¸ ô9®}ô{ÂÇˆ‡ÈcV'#15'Ñ³‘/O½íúÑ'#22'‡rñ–ûCYÈ˜òÄ.Jï'#1'Fò'#6#1'ÎÓ{'#31'^€Î‚£jÊ'#25' ¶'#9'q7)ffp09bp'#1#39#0'g'#3'Õ+R'#25'ZQ•¯¿h&C¬éê§,°å†zsÅ}'#19'6'#7'|c¹¯œ>-_[kZıÿ'#0'”wGenC1Æ3ĞcêN'#10'Kq='#17+
'ã”QEj3[Ãº¿ö6«'#28'î¥íÛå™?¼§­z>¨ê'#18'¸'#26'Ï†ÜßhÓ|Ïl§%}F+ÈªîŸ«j'#26'T›ìo%€õ;'#27'ƒõ'#20#10'İQôU·ÇÍ'#15'hûf™}'#12' |ÁW<Õåøûá@'#1'k]Oğ„x'#0'ñæ¶@ó'#30'ÖSİ¤¶BOéJ<y«ş®Çÿ'#0#1'V§•'#14'ìú'#3'ş'#23'ÿ'#0'„Á?èš¯ıø'#31'üU/ü/ÿ'#0#10'c&ÓT'#31'öÀ|ıÿ'#0#9'æ±'+
'Œyv?ø'#10'´Ÿğjüæ;'#19'ŸúuJv'#22'§Ğ_ğ¿ü('#6'~Éªãş½ÇøÒÿ'#0'Ã@xO<Zê¿ø'#14'?Æ¾{ÿ'#0'„çWî–GşİSü(ÿ'#0'„çWÿ'#0'v?ø'#10'ŸáEƒSèQñÿ'#0'Â]íõAÿ'#0'nãüiGÇï'#8'÷‡S'#31'[ş½|ïÿ'#0#9'¾¯ıÛ?ü'#5'Oğ¥'#30'8Õæ;#õµZ,'#26'ŸCÿ'#0'Âÿ'#0'ğ‡üñÔÿ'#0'ğ'#27'ÿ'#0'¯Gü/ï'#8'ÿ'#0'Ï'+
#29'Kÿ'#0#1'ÿ'#0'úõóÇü'#39#26'¯üò±?öê”ÿ'#0'øNµN?Ñôüz}•y¥`Ôú'#1'¾?øWømõ'#3'õƒÿ'#0'¯\½ñkKÖ5E¹†×PxÒ0Š‹'#7'|’{ı?*òµñæ°™Ú–+‘ƒ‹Tÿ'#0#10'kø÷ÄN¡VøD'#7'A'#28'H ~”r†§¦\x¿VÕ¬dHÒ®,c#ç½½!'#22'%î@ÏZó?'#16'êV‰l4Í>áî'#1'2êäŸõÏı@¬›íoTÔ¿ãòşâqØ<„øtª'#20'ía[¸QE'#20'Ê'+
#10'(¢€'#21'X£†RC)È#±¯FĞuy¯.#Ô´‹•‡UU'#11'si#an@ïõ¯8¥Vd`ÊHaÈ ò('#19'W=ÆˆpÆ'#12'Z†“i(êJo_ÀŠé<9ñ¯ÃZN’-/'#13'óº3'#21')oÆÒr'#7#39'­x'#21'¯ŠõËD'#9#30'£+ è²aÿ'#0'jâøçWÇï'#18'Ê_÷í”ÔØZŸD^'#16' '#29'š—=?Ñÿ'#0'úô'#31'^'#16#13'µ“Q'#4'uÍ¿OÖ¾w>8Ô'#8'Á²Óğ'#24+
'R'#15#27'_ùrÓOı»'#15'ñ¢ÃÔú(|zğwıDğ'#31'ÿ'#0'¯J~=x4'#12'ÿ'#0'ÄÇéöoş½|ëÿ'#0#9'Åş?ãÇMÿ'#0'Àş½'#31'ğœ_ÿ'#0'Ï–›ÿ'#0'€Ãüh°j}'#17'ÿ'#0#11'óÁ¿İÔ‡ÖØ'#3'ãçƒNxÔ¿ğ'#27'ÿ'#0'¯_<ÿ'#0'Âu¨Ï™ÿ'#0'€Ãüi?á8¾ÿ'#0'Ÿ'#13'3ÿ'#0#1'‡øÑ`Ôú'#31'ş'#23'ßƒsÓQÿ'#0'Àqş4'#31''+
'~'#13'ÿ'#0'¨‡ş'#3'ÿ'#0'õëçƒã‹ìÇ†˜?íØ'#39'ü&÷ÿ'#0'óã¦ÿ'#0'à0ÿ'#0#26','#26'ŸD'#31'~'#12#29'ïÿ'#0'ğ'#31'ÿ'#0'¯QKñóÁár‹|Ç°0ãükçßøMïè'#31'¦à?ÿ'#0'^øÚûµ†š'#15'ı{'#10'9Bìõ­wâÎ¥â¸'#31'MğÖ›,+'#39#13's/'#1'G®kÊ¼K¨[ÚÙÿ'#0'cÚÎng2y—·YâWì£ØVmÿ'#0'ŠµF'#19#4+
'·^\'#7'¬P¨OåXÔÒ°Y½ÂŠ(¦0¢Š('#0'¢Š('#0'¢Š('#0'¢Š('#0'¢Š('#0'¢Š('#0'¢Š('#0'¢Š('#0'¢Š('#0'¢Š('#0'¢Š('#0'¢Š('#0'¢Š('#0'¢Š('#0'¢Š('#0'¢Š('#0'¢Š('#0'¢Š('#0'¢Š('#3'ÿÙ';
begin if _bmAnalogMeter=nil then _bmAnalogMeter:=TBitmap.CreateFromStr(data);result:=_bmAnalogMeter end;

function GaugeValue(const ALabel:ansistring;const AValue:Double;const AFormat,AUnit:ansistring;const AColor:TColor=0):TGaugeValue;
begin
  result:=TGaugeValue.Create;
  with result do begin
    FValue:=AValue;
    FLabel:=ALabel;
    FUnit:=AUnit;
    FFormat:=AFormat;if FFormat='' then FFormat:='%g';
    FColor:=AColor;
  end;
end;

function GaugeScale(const ALeft,ARight:Double;const ASegs0,ASegs1,ASegs2:integer;const AFormat,AUnit:ansistring;const AColor:TColor=0):TGaugeScale;
begin
  result:=TGaugeScale.Create;
  with result do begin
    FLeft:=ALeft;
    FRight:=ARight;
    FSegs[0]:=ASegs0;
    FSegs[1]:=ASegs1;
    FSegs[2]:=ASegs2;
    FFormat:=AFormat;if FFormat='' then FFormat:='%g';
    FUnit:=AUnit;
    FColor:=AColor;
  end;
end;

procedure DrawGauge(const ACanvas:TCanvas;const RDst:TRect;const AData:array of const);
const supersample=4;
var w,h:integer;
    c:TCanvas;

    Scales:array of TGaugeScale;
    Values:array of TGaugeValue;

  function toScr(const x,y:single{0..1}):TPoint;
  var a:single;
  const ang=0.85;
  begin
    a:=Remap(x,0,1,-ang,ang);
    result.x:=Round(remap(Sin(a)*y*0.9,-1,1,0,w));
    result.y:=Round(remap(Cos(a)*y*0.9,-1,1,h*1.7,h*0.2));
  end;

  procedure SetLineWidth(const lw:single{1=normal});
  begin
    c.Pen.Width:=round(h*lw*supersample*0.001);
  end;

  var fsize:single;
  procedure SetFontSize(const fs:single{1=normal});
  begin
    //c.Font.Size:=round(h*fs*supersample*0.017);
    fsize:=fs;
  end;

  procedure DrawCenteredRotatedText(const x,y:integer;const deg:single;const s:ansistring);
  var lf: LOGFONT;
      vx,vy,d:single;
  begin
    FillChar(lf, SizeOf(lf), 0) ;
    lf.lfHeight := round(h*fsize*supersample*0.024);
    lf.lfEscapement := round(10 * deg); // degrees to rotate
    lf.lfOrientation := round(10 * deg);
    lf.lfCharSet := DEFAULT_CHARSET;
    lf.lfFaceName:='Times New Roman';

    c.Font.Handle := CreateFontIndirect(lf) ;
    d:=DegToRad(deg);
    vx:=cos(d);
    vy:=sin(d);
    with c.TextExtent(s)do
      c.TextOut(round(x-(cx*vx+cy*vy)*0.5),
                round(y-(-cx*vy+cy*vx)*0.5),s);
  end;

  procedure DrawScale(const AFrom,ATo:double;const line:integer;const ASegs0,ASegs1,ASegs2:integer;const color:tcolor;const AUnit:ansistring;const AOneUnit:boolean;const AFormat:ansistring);

    var liney:single;//multiscale

    procedure DrawSegs(const ASegs:integer;const y0,y1:single);
    var p,inv:single;
    begin
      if ASegs<=0 then exit;
      inv:=1/ASegs;
      p:=0;
      while p<=1.0001 do begin
        c.Line(toScr(p,y0+liney),toScr(p,y1+liney));
        p:=p+inv;
      end;
    end;

  var i:integer;s:ansistring;
      p1,p2:TPoint;
      x,y,d:single;
  begin
    liney:=0.05-line*0.22;

    SetLineWidth(1);
    c.Pen.Color:=color;
    DrawSegs(ASegs0,1.01,1.12);
    DrawSegs(ASegs0*ASegs1,1.01,1.09);
    DrawSegs(ASegs0*ASegs1*ASegs2,1.01,1.06);

    c.Font.Name:='Times New Roman';
    c.SetBrush(bsClear);

    if ASegs0<=0 then exit;
    c.Font.Color:=color;
    SetFontSize(1);
    p1:=toScr(0,0);
    for i:=0 to ASegs0 do begin
      s:=format(AFormat,[i*(ATo-AFrom)/ASegs0+AFrom]);
      if(i=ASegs0)and(not AOneUnit)then s:=s+' '+AUnit;
      p2:=toScr(i/ASegs0,1.17+liney);
      x:=p1.X-p2.X;y:=p1.Y-p2.Y;
      d:=1/sqrt(x*x+y*y);
      d:=90-ArcTan2(y*d,x*d)/pi*180;
      DrawCenteredRotatedText(p2.x,p2.y,d,s);
    end;
  end;

  function ScaleByUnit(const AUnit:ansistring):TGaugeScale;
  var i:integer;
  begin
    for i:=0 to high(Scales)do if cmp(AUnit,Scales[i].FUnit)=0 then exit(Scales[i]);
    result:=nil;
  end;

  procedure DrawValue(const x:double;const line,color:integer;const AUnit,AFormat:ansistring);
  var x2:single;
      sc:TGaugeScale;
      liney:single;
      p:TPoint;
      s:ansistring;
  begin
    sc:=ScaleByUnit(AUnit);
    if sc=nil then exit;

    liney:=0.6+0.125*line;

    x2:=EnsureRange(remap(x,sc.FLeft,sc.FRight,0,1),-0.1,1.1);

    SetLineWidth(2);
    c.SetPen(psSolid,color);
    c.Line(toScr(x2,0.2),toScr(x2,1.1));

    s:=format(AFormat,[x]);
    c.Font.Color:=color;
    SetFontSize(1.25);
    p:=toScr(0.5,liney);
    DrawCenteredRotatedText(p.x,p.y,0,s);
  end;

var b:TBitmap;
    i:integer;
    oneunit:boolean;
begin
  //collect data
  for i:=0 to high(AData)do with AData[i] do if VType=vtObject then begin
    if VObject is TGaugeScale then begin SetLength(Scales,length(Scales)+1);Scales[high(Scales)]:=TGaugeScale(VObject);end else
    if VObject is TGaugeValue then begin SetLength(Values,length(Values)+1);Values[high(Values)]:=TGaugeValue(VObject);end;
  end;

  try

    w:=RDst.Right-RDst.Left;
    h:=RDst.Bottom-RDst.Top;
    if(w<1)or(h<1)then exit;

    //workspace
    w:=w*supersample;h:=h*supersample;
    b:=TBitmap.CreateNew(pf32bit,w,h);AutoFree(b);c:=b.Canvas;

    //background
    c.StretchDraw(rect(0,0,w,h),bmAnalogMeter);

    //scales
    oneunit:=true;
    for i:=1 to high(Scales)do if Scales[i].FUnit<>Scales[0].FUnit then begin oneunit:=false;break end;

    for i:=0 to high(Scales)do with Scales[i]do
      DrawScale(FLeft,FRight,i,FSegs[0],FSegs[1],FSegs[2],FColor,FUnit,oneunit,FFormat);

    //values
    for i:=0 to high(Values)do with Values[i]do
      DrawValue(FValue,high(Values)-i,FColor,FUnit,FFormat);

  //    DrawScale(0,100,5,2,5);
  //    DrawScale(0,50,5,2,5);
  //    DrawScale(0,25,5,5,2);
  //    DrawScale(0,20,4,5,2);
  //    DrawScale(0,100000,5,2,5);

//    DrawNeedle(pos,$2222CC);

    b.Resize(w div supersample,h div supersample,rfLinearMipmapLinear);
    ACanvas.draw(RDst.Left,RDst.Top,b);

  finally
    for i:=0 to high(Scales)do Scales[i].free;
    for i:=0 to high(Values)do Values[i].free;
  end;
end;

initialization
finalization
  FreeAndNil(_bmAnalogMeter);
end.
