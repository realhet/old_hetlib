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
'����'#0#16'JFIF'#0#1#1#1#0'`'#0'`'#0#0'��'#0'6Exif'#0#0'II*'#0#8#0#0#0#2#0#1#3#5#0#1#0#0#0'&'#0#0#0#3#3#1#0#1#0#0#0#0#0#0#0#0#0#0#0'��'#1#0'��'#0#0'��'#0'C'#0#8#6#6#7#6#5#8#7#7#7#9#9#8#10#12#20#13#12#11#11#12#25#18#19#15#20#29#26#31#30#29#26#28#28' $'+
'.'#39' ",#'#28#28'(7),01444'#31#39'9=82<.342��'#0'C'#1#9#9#9#12#11#12#24#13#13#24'2!'#28'!22222222222222222222222222222222222222222222222222��'#0#17#8#0'�'#1'$'#3#1'"'#0#2#17#1#3#17#1'��'#0#31#0#0#1#5#1#1#1#1#1#1#0#0#0#0#0#0#0#0#1#2#3#4#5#6#7#8#9#10#11+
'��'#0'�'#16#0#2#1#3#3#2#4#3#5#5#4#4#0#0#1'}'#1#2#3#0#4#17#5#18'!1A'#6#19'Qa'#7'"q'#20'2���'#8'#B��'#21'R��$3br�'#9#10#22#23#24#25#26'%&'#39'()*456789:CDEFGHIJSTUVWXYZcdefghijstuvwxyz��������������������������������������������������������������������'+
'�������'#0#31#1#0#3#1#1#1#1#1#1#1#1#1#0#0#0#0#0#0#1#2#3#4#5#6#7#8#9#10#11'��'#0'�'#17#0#2#1#2#4#4#3#4#7#5#4#4#0#1#2'w'#0#1#2#3#17#4#5'!1'#6#18'AQ'#7'aq'#19'"2�'#8#20'B����'#9'#3R�'#21'br�'#10#22'$4�%�'#23#24#25#26'&'#39'()*56789:CDEFGHIJSTUVWXYZcdefg'+
'hijstuvwxyz��������������������������������������������������������������������������'#0#12#3#1#0#2#17#3#17#0'?'#0'���'#0#39'�t�'#27'����'#1'[T8'#39'�'#26'�7c�'#3'=)�)'#15'H��S�@�����F'#0'�,d�upi�'#39'��1���c�|���'#0'�&����'#0'�'#25'?�^�4����?*'+
'x�o���'#14's���?����4}���'#39'��kن�}��"��"�'#31'�E'#2'�<c���'#0'�'#25'?�I�y�ϓ'#39'��k�?����Q��|���'#14's���O������M�'#0'<���5�'#31'�׃�Y'#10'_�{����P'#28'�'#11'y�H���4�L����'#0'�^�4���'#0',J?�/��@s�-�y���'#0'�&�"o���'#0'�ɯi�ɼ�'#0'�'+
'?�'#31'����P'#28'��S'#12'��o�'#0'|�Q'#4'�q'#19'�'#0'�&���'#30'��x�����}��('#14'sż�?��'#0'�&�*Bq���^���y�'#0'<JO�k����P'#28'�'#24'%'#29'b��� ����'#31'����k��'#0',J?���'#0'��@s�/�M�'#0'<���4y'#19'g'#30'S�'#0'�&���'#30'��x����������9�'#23'�<��'+
'��'#0'�G���'#0'�O�'#0'|��������R�'#0'c��!�P'#28'�}�o���'#0'�ɣ���'#39'�'#0'�M{O�=����c�c�O�KP�<[���'#23'�'#0'�M'#31'g��y?��k���?�'#39'�=���'#20'j'#28'��'#19'�'#39'�'#0'�M'#30'D����'#0'�^�t�����R'#29'"�?�G�F��x��A�'#27'�A�'#4'W�'#29'&|'#29+
'�'#15'ʠ�C.�=�6{'#21#6'��<~��=O�Kt�m�'#16'��'#1'µp7'#22'�Z�<'#19')Y'#16'ၠ�+�QE'#20'�&�M�� ~��?��$���x@'#25'�y8�O�b�}�'#25'�_@���'#30#25'�7���0&'#1'�'#10'R؛]���c�>AZ'#16'�Q��'#10'܂�`qW�c�+��y4'#24'�'#0'�*uТ�அa'#3'�L!_J.'#22'G64(��)��QpWG�'+
#10'<�E�������������?,Rl��ds�B�����'#10'/�'#10'輺p�zQp�9��(�������ஏ�������c������(��?*�'#12'\���ǥ'#23#11'#������(���U�y~�y~�\,�s�'#10'/�'#10'O�(��?*�<�jO+ڋ���aE���Q��'#23'�'#5't~X������Y'#28'��'#20'_��*_�(��+��������X��'#0'��������'+
'������'#30'�\9Q�aE��K��'#23'�'#7'�]'#31'�(�ǥ'#23#11#28'�Т��'#20'ӡE��]7�'#8'�G��\,�\�Qp~U'#27'hQp~UԘ���!�J�drO�E���Ui4'#24'��'#5'vM'#0'��$�`�E����А0;'#6'Exoō'#29't�'#19',��'#11'�'#14'q��E}=-���'#6'��'#8'��N`'#6'Lg'#39#29'y�=B�<r�(�(���'#0'�'+
'�s�B����x�݀<��9ǵ|}����+�o'#14'('#30#25'��0<���)OdJ�օ8'#21'v5��8'#21'm'#7#21'%'#14#11'R'#1'� �'#10#0'Z(��'#5#7'�'#20'P'#2#1'�Z(�'#2'�(�'#2'�'#20'�P'#1'E'#20'P'#1'E'#20'P'#2'b��('#0'��('#0'��-'#20#0'����'#20'�(��'#4#20'�)��'#12'��D�S�LaH'#10'2��|'+
'�'#0'�����'#14'<����YE|��A.5'#29';��'#31'�Mn&x�'#20'QV2ޝ�'#0#31'q�'#0'�+��'#5#2'�r�T'#16'�'#4#3'?A_'#26'i���'#31'�¾��'#6'<=e�p��'#8'�=���C�V��V��ZJ��'#20'�JZ�'#10'(��'#10'(��'#10'(��'#10'(��'#10'(��'#10'(��'#10'(��'#10'(��'#10'(��'#10'(��'#10'(�'+
'�'#10'LR�@'#5'%-% '#18'�¤�0�'#5'ik���'#19#31'n�q��9���9+��'#20'�'#0'��N'#24'�'#0'�_�з'#19'<F�(�'#6'\���3�5���1��'#12'�'#0'�'#4'�'#0'�E|[����+�-'#27'�@6?��?�'#17'J['#9'ni�ҭ/J�'#23'J��'#3#31'N'#29')��:S'#1'h��`'#20'QE'#0#20'QE'#0#20'QE'#0#20'QE'#0+
#20'QE'#0#20'QE'#0#20'QE'#0#20'QE'#0#20'QE'#0#20'QE'#0#20'��R'#1#7'J)i('#0'�1���5 +��k��'#16'��i�'#30'D\�u�4�'#13'|��A�����'#31'���'#0':'#22'�g�QE'#21'��zw�}'#39'�¾����S�?��?�'#17'_'#24'i�'#23'I�𯳴<�'#2'�'#31'����R��Kvk�Ҭ�V���)ҡ'#12'x�'#1'IN�'#2+
'R�E0'#10'(��'#10'(��'#10'(��'#10'(��'#10'(��'#10'(��'#10'(��'#10'(��'#10'(��'#10'(��'#5#20'Rf�'#22'���P'#1'Lj}1�'#1'Z_�_<��c�&Zw?�̞��4��W��'#0'�'#16'۫X�rс��B�L�Z(��'#25'j��>P縯�t��'#0#18'K/����'#8'������'#21'����'#0' ;'#31'����'#8'�=���֋�YZ�'#23+
'AVV�d��M'#20'�L'#2'����'#5#20'Q@'#5#20'Q@'#5#20'QH'#2'�*��'#30'�c-ܠ��'#3#3'�� '#1'��'#5#0'Z���۫����X6)'#10'�'#9'$'#19'�C'#39'�'#15#25'�'#28'V�0'#10'*����\̑+���p3���'#0'�I��D{w��\���'#22'�('#7#4'�'#6#0'�6(�-.���+���9T2�R���'#15'J��'#10'(��'#10+
'(��'#10'(��'#10'LqKE '#10'JZJ'#0'JcS�H'#10'�t��?h3�'#0#19'M7��g�5�<�+��'#15'�B�w'#31'����'#22'�g�QE'#21'��6?���'#10'�?D$�V9�'#0'�'#9'�'#0'�����'#31'hQ�Я�tO�'#0'���x'#39'��)OdJ�؋��+ҫE�U��RP�N��u'#0#20'���DS��'#15'�4'#0'�;�E0'#10'(��'#10'(��'#21'�'+
'nŜ'#6'S'#12'�'#30'�8Ss1�'#21'�j����'#6'=B'#17'e'#29'�Qm���ː2��$'#12#12'�G=���wz]���%�'#23#12'��2�'#27'h$'#19'��?*bg3��'#0'gĶ�rJ҆WHap'#3'`m'#8#1'�+'#16'S�MJ���]&�'#19'��h�O�&}'#9'!GК�'#5'�!���7'#28'�'#25'�J�ċ�"E_@�'#10#5'c�����gc0��'#0'�,@'+
#4'$h�'#1'�'#19'0'#39'#�qU'#31']��n,'#18'��X�p��n�"5b�/T\��/z��(��q"o��'#6'p1��'#0'�#�lbR��[���'#11#18'��n��'#11#28'�ι�D񥫉�'#0#12'm�>�'#4'R�'#7' �G\68'#2'�'#14'�ww$���Y#�4��'#2'�q�wu��<q��"��'#4'A�'#8'�>�G�?�'#20'퉂6�'#30'�'#29'h'#11'3'#31'�'+
#18'�\�F���'#18'�V�'#13'�AH��'#7#3'��'#29'�j�'#0#6#0'�'#29'�-"��(�'#2'�(�'#2'�:R'#2#15'B'#13#0'-%-%'#0#21#27'T�'#27'R'#2'��+��'#12'��m8'#15'����_DMҾw���F��'#17'����B�L�j(��'#25'f��z�'#0'�+��'#15'�@6'#7'����'#0'A'#21'����'#0'xW��'#25'΁a�'#0'^��'#0+
'�"��B[�^2'#2'�'#7'��!�A,ʠ'#12'��`z�ͽ�\�w'#16'��<d'#18'�'#10#7'�������I��9'#12'L#��f�i�'#39'�'#0'ˎ�'#31'�@'#29'*Ȅ)'#14'�7� �~��˜ddv�r2i�y�Z�ŉ�'#10'�4�'#5'���'#30'�}��'#3'�q�?�'#39'C���M-žչ2 ���y8�2�{�\�MR�H��U�'#21'�0R@�'#25'��;�'#23'�'#22+
'��Kx���d'#2'�'#11'��=?�hj(����x�[�a��U##��'#15'z��o^�;('#24'��"��'#14'���;�߅��ԃ@f'#18'H'#1's�'#10'����+����q���w�V�`'#0'@>��I$�DTI*!c�'#12'�d�U-�ye'#12#20'��z'#12'�H$F '#7'RH���=k'#27'Y�?��x�d�)19'#3'xr�Us�'#12'1?�TӴ��}Z�v���'#21'2�c�s'#25'l'+
'��>�'#25'�q���#������! '#2'I�'#29'MPֵ�'#15#15'�3�z���k'#10'��>�w'#39'Ҿc���=[��R[i��ZN6���K��*'#18#19'g���ⷆ<>�'#9'�{ۑ�'#0',�F�'#31'v�+����z�;A�/c4���'#0'�'#9'�_���'#9#3#30'�ɫC���'#28#5'�'#24'�'#0'�"��]���'#27'�J���,�}'#2'�����|w�ʮ��O'#14'z�'+
'����q���'#15'���'#15'�z�'#0'ߑQ?��)T�KR?�'#20'h'#23'��'#22'���'#19'����]�s0'#25'1���꧚ۯ�"�'#30'�kq'#29'Ŵ�o*'#29'���H>�'#21'�'#12'�6&����'#39'�%۰Ho1�@އޕ�O���QE"���'#8'ݑ�YW{+8'#4'/���n`r�'#39'����'#14#14'���\����\ꗱ°"����ZF��'#31'!�'#0'S�'+
'H�qR�'#14'Yu'#29'6�}���T'#8'����9;�����'#0'�'#8'�W:�*+y$�'#21'ic'#17'��H'#27'v�ƥ$'#1'�p('#25'�y�'#29'.��x/�'#17'�D.'#10'�'#9'�y�ֱ��^�'#22'�'#9'�J��"��'#16'�r}��j����-5F��?�E/H'#1#0'���Q�nx�sL��'#0'�'#23'�'#24'�H�w*Ҿ'#7'#�'#30'�t�w�]'#30'�'#13'�3G'+
#11'����܀�'#22#24'�'#20'�xYK,�T6�C'#12#3'�����e7'#22'�'#4#6#8'Tp�0`x#��=2*�'#30#31'��ݢia|�VPdS���'#8'>��s�X��r�@a��'#25'�Mb2FFGjŵ��%�M$W'#30'r��ș'#7',Xn'#7'#��I&��|*C'#12'1�4'#8'ѷ����F�1�R1ڐ'#26'S'#28'�GJ����'#24'մ�z��rk�m->ç�'#7'f�K7��W$��'+
'W���y��Ӂ�'#0'�_�з'#6'x�'#20'QZ'#12'�f?x'#15'�B���@����'#15'�'#19#31'�ȯ��+A=���w5�'#15'��dg���|'#3'����'#15'�x&'#18'2D���'#8#24'�����m��F��FDib*'#25'�'#2'���]1�%���t��'#11'�ʄ�8*�*z��1�C['#18'ۛ�'#25'��'#20'�'#27'&Ol�Vd�F�s'#27'��Z���'#28'p���Jn'+
'��+��6�x�5)�%��M�'#22#15'kc,�d�9�Y�q�ܸ�zg>�To�Ŷ+3%�b(`'#18'F'#10'��1�F?1ޯ�z}Օ�ԓyM'#28'��'#25'$=��'#29'��F��˼K�Ru��X��Qe���"�gL��ӵ0(j�'#17'G&��Q.'#21'��2F0!َT���J�g�����5�x'#12'3�ц'#17'vG��'#6'yB9�w����ֺG�s�'#28'�nb��'#18'g|�:�n�y��'#28+
'���'#21'�wm-�yh�"�Q�����\'#2'F=s�'#1'b��'#16'�'#12'�'#28'�'#11'�d�8�G�w��{j'#19'[�'#20'��m�����'#7#12'�'#25'?w���J��W�>}�Nc'#27'`f8'#8'��'#12'@�n|�Lu56��]�In�W'#17'Nѵ�v'#11'����:g'#3'�z'#0'�-��㸖��'#25#4'�!��EuQ墓�F'#27'N1�?�>M&�\Km'#20'1'#9'/'+
#18'i#S��VP�'#6#15#0'�'#30'�ڵ4�'#39'Ӵ�{Y'#10'���'#25'��5v�'#10'l�,Q���UA$��S���`Ӓ�'#14#26'�������'#20#12'�|J��ڠ{�6�'#1'�'#16'8�?�sTW�Z'#21'��}.Ď��'#31'�[v�'#29'�T�'#0'�\G�5����[k�'#13'�I�_�/'#27#19'����ݓ������i�$Ӽ;��>�t'#4'Ip�#��r'#23'�z'+
'D2��5h'#12'���mԁ�'#5'gj�!k��æ!��S�'#18#28#25'?�s��'#21']�X�'#1'𓝢]V#���'#24'~@�֕j#���t�j'#5#25'ki��&��'#25'5���HdY"vGS��pE'#22'L9Oo��'#20'�'#2'4k��[��Ķ������V�ǂ�iQ�zu�d�'#10'�'#6'+�4�l��B���kp���'#14'<�'#3'�}k�|5�'#4'�'#6'�%l�s'#17'��o(�'+
'�'#2'���'#7'�K'#26'a�Ld�!�y'#27'� �'#19'�?�wU䲗���� D��tlw'#29'�Ԭn���'#27'���'#24'P4e^iSO����xd3'#4'�Y�k}����$c��'#20'�h���SG"H<�巄��'#20'8w\��d��Kya�I��5���ڰ]����s�>�k�W'#14'��q'#28'��'#11#6'�'#28'39'#24'�あߝ'#0'R�O��v��K[��L̢N'#2'�'#0'�'+
'�l�'#1'<S���amo"�/'#18'o6=���'#0'��_�O�Ϻ�'#26'�)�L'#31'�}ߛ�};�g�'#6'�]+�'#13'hn�6�'#20'o�g]�1#'#7'�>Q�ӽ'#0'W��@���&V�4��TP3�'#5'$'#12'��O�5�'#6'�����#��V��#F '#0#25'0'#10'�'#4'|�8�$�85%�{'#28'Q��'#0'>5f�Xˀ�}��NX'#13'�z�'#0#0'ϭZ�t��􈭶"l�'#2'�'+
#27'~H��'#28'��?��'#17'>��=��7'#19'��'#23'�c*s�%������ָ �9�}�{�ǈ��cV'#15'ѳ�/O����'#22'�r��CYȘ��.J�'#1'F�'#6#1'�Ӑ{'#31'^�΂�j��'#25'��'#9'q7�)ffp09bp'#1#39#0'g'#3'��+R'#25'ZQ����h&C���,��zs�}'#19'6'#7'|c���>-_[kZ��'#0'�wGenC1�3�c�N'#10'Kq='#17+
'�QEj3[ú��6�'#28'����?���z>���'#18'�'#26'φ��h�|�l�%}F+Ȫj'#26'T��o%��;'#27'��'#20#10'�Q�U���'#15'h�f�}'#12'�|�W<�����@'#1'k]O���x'#0'��@�'#30'�Sݤ�BO�J<y������'#0#1'V��'#14'��'#3'�'#23'�'#0'��?蚯��'#31'�U/�/�'#0#10'c&�T'#31'���|��'#0#9'�'+
'�yv?�'#10'���j��;'#19'��uJv'#22'��_��('#6'~ɪ�������'#0'�@xO<Z��'#14'?ƾ{�'#0'��W�G��S�(�'#0'��W�'#0'�v?�'#10'��E�S�Q��'#0'�]��A�'#0'n��iG��'#8'��S'#31'[��|��'#0#9'����?�'#5'O�'#30'8Ձ�;#��Z,'#26'�C�'#0'��'#0'������'#0'�'#27'�'#0'�G�/�'#8'�'#0'�'+
#29'K�'#0#1'�'#0'�����'#39#26'���?���'#0'�N�N?���z}�y�`��'#1'�?�W�m�'#3'���'#0'�\���kK�5E���Px�0��'#7'|�{�?*��氙ږ+���T�'#0#10'k���N�V�D'#7'A'#28'H�~�r���\x�Vլd�HҮ,c#罽!'#22'%�@�Z�?'#16'�V�l4�>��'#1'2�����@���oTԿ����q�<���t�'#20'�a[�QE'#20'�'+
#10'(��'#21'X��RC)�#��F�uy�.#Դ���UU'#11'si#an@���8�Vd`�Ha� �('#19'W=��p�'#12'Z��i(�Jo_���<9��ZN�-/'#13'�3'#21')o��r'#7#39'�x'#21'����D'#9#30'�+ �a�'#0'�j���W��'#18'�_����Z�D��^'#16' '#29'��=?��'#0'��'#31'�^'#16#13'��Q'#4'uͿO־w>8�'#8'����'#24+
'R'#15#27'_��r�O��'#15'����(|z�w�D�'#31'�'#0'�J~=x4'#12'�'#0'����o��|��'#0#9'��?��M�'#0'���'#31'�_�'#0'ϖ��'#0'���h�j}'#17'�'#0#11'����ԇ���'#3'��NxԿ�'#27'�'#0'�_<�'#0'�u�ώ��'#0'���i?�8��'#0'�'#13'3�'#0#1'���`��'#31'�'#23'߃s�Q�'#0'�q�4'#31'�'+
'~'#13'�'#0'���'#3'�'#0'�����ǆ�?���'#39'�&��'#0'���'#0'�0�'#0#26','#26'�D'#31'�~'#12#29'��'#0'�'#31'�'#0'�QK����r�|ǰ0��k���M��'#31'��?�'#0'^�������'#15'�{'#10'9B���w�Υ�'#31'M�֛,+'#39#13's/'#1'G�kʼK�[���'#0'c��ng2y��Y�W��Vm�'#0'���F'#19#4+
'�^\'#7'�P��O�X�ҰY�(�0��('#0'��('#0'��('#0'��('#0'��('#0'��('#0'��('#0'��('#0'��('#0'��('#0'��('#0'��('#0'��('#0'��('#0'��('#0'��('#0'��('#0'��('#0'��('#3'��';
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
