unit het.CoordSys;
//GHI source -> ftp://edcftp.cr.usgs.gov/pub/software/misc/gihll2ls.c
interface

uses
  UVector, sysUtils, het.Utils;

type
  TMajorCoordSys=(csWGS,csMRC,csGHI,csEOV);
  TMinorCoordSys=(csDeg,csRad,csTile);

  TCoordSys=(csWGSdeg,csWGSrad,csWGStile,
             csMRCdeg,csMRCrad,csMRCtile,
             csGHIdeg,csGHIrad,csGHItile,
             csEOVdeg_unused,csEOVmeters,csEOVtile);

const
  MajorSysOf:array[TCoordSys]of TMajorCoordSys=(
    csWGS,csWGS,csWGS, csMRC,csMRC,csMRC, csGHI,csGHI,csGHI, csEOV,csEOV,csEOV);
  MinorSysOf:array[TCoordSys]of TMinorCoordSys=(
    csDeg,csRad,csTile, csDeg,csRad,csTile, csDeg,csRad,csTile, csDeg,csRad,csTile);

function CoordSys(const Major:TMajorCoordSys;Minor:TMinorCoordSys):TCoordSys;inline;

type
  TCoordinate=record
  public
    Coord:TV2D;
  private
    FSystem:TCoordSys;
    function GetMinorSys:TMinorCoordSys;inline;
    procedure SetMinorSys(const Value:TMinorCoordSys);
    function GetMajorSys:TMajorCoordSys;inline;
    procedure SetMajorSys(const Value:TMajorCoordSys);

    procedure SetSystem(const ADstSystem:TCoordSys);
  public
    procedure SetSystemNoConvert(const ASystem:TCoordSys);inline;
    property System:TCoordSys read FSystem write SetSystem;
    property MajorSys:TMajorCoordSys read GetMajorSys write SetMajorSys;
    property MinorSys:TMinorCoordSys read GetMinorSys write SetMinorSys;

    function Convert(const ACoordSys:TCoordSys):TCoordinate;

    class operator Explicit(const c:TCoordinate):ansistring;
    class operator Explicit(const s:ansistring):TCoordinate;
    class operator Implicit(const c:TCoordinate):TV2d;
    class operator Equal(const a,b:TCoordinate):boolean;
    class operator NotEqual(const a,b:TCoordinate):boolean;
    class operator Add(const a,b:TCoordinate):TCoordinate;
    class operator Subtract(const a,b:TCoordinate):TCoordinate;
  end;

function Coord(const ASystem:TCoordSys;const ACoord:TV2d):TCoordinate;

implementation

uses Math;

// Mercator

procedure Convert_WGS_MRC(const lat:double;var y:double);
begin
  y:=ln(tan(0.25*pi+0.5*lat));
end;

procedure Convert_MRC_WGS(const y:double;var lat:double);
begin
  lat:=arcsin(tanh(y));
end;


function adjust_lon(const x:double):double;
begin
  if abs(x)<PI then result:=x
               else result:=x-(sign(x)*PI*2);
end;

const
// central meridians for each of the 12 regions
  lon_center:array[0..11]of double=(
    -1.74532925199,		// -100.0 degrees
    -1.74532925199,		// -100.0 degrees
     0.523598775598,	//   30.0 degrees
     0.523598775598,	//   30.0 degrees
    -2.79252680319,		// -160.0 degrees
    -1.0471975512,		//  -60.0 degrees
    -2.79252680319,		// -160.0 degrees
    -1.0471975512,		//  -60.0 degrees
     0.349065850399,	//   20.0 degrees
     2.44346095279,		//  140.0 degrees
     0.349065850399,	//   20.0 degrees
     2.44346095279); 		//  140.0 degrees

// false eastings for each of the 12 regions
  RG=6370997.0;//original
//  RG=6367686;
  feast:array[0..11]of double=(
    RG * -1.74532925199,
    RG * -1.74532925199,
    RG * 0.523598775598,
    RG * 0.523598775598,
    RG * -2.79252680319,
    RG * -1.0471975512,
    RG * -2.79252680319,
    RG * -1.0471975512,
    RG * 0.349065850399,
    RG * 2.44346095279,
    RG * 0.349065850399,
    RG * 2.44346095279);

const epsln=1e-10;

// Goode`s Homolosine forward equations--mapping lat,long to x,y
//-------------------------------------------------------------*/
procedure Convert_WGS_GHI(const lon,lat:double;var x,y:double);

//double adjust_lon();	/* Function to adjust longitude to -180 - 180 */
var delta_lon:double;	// Delta longitude (Given longitude - center */
    theta,delta_theta,constant:double;
    i,region:integer;
begin

  if(lat >= 0.710987989993)then begin	          // if on or above 40 44' 11.8" */
    if(lon <= -0.698131700798)then region:=0        // If to the left of -40 */
    else region:=2;
  end else if(lat >= 0.0)then begin		  // Between 0.0 and 40 44' 11.8" */
    if(lon <= -0.698131700798)then region:=1        // If to the left of -40 */
    else region:=3;
  end else if(lat >= -0.710987989993)then begin   // Between 0.0 & -40 44' 11.8" */
    if(lon <= -1.74532925199)then region:= 4   	    // If between -180 and -100 */
    else if(lon <= -0.349065850399)then region:=5   // If between -100 and -20 */
    else if(lon <= 1.3962634016)then region:=8	    // If between -20 and 80 */
    else region:=9;				    // If between 80 and 180 */
  end else begin				  // Below -40 44' */
    if(lon <= -1.74532925199)then region:=6         // If between -180 and -100 */
    else if(lon <= -0.349065850399)then region:=7   // If between -100 and -20 */
    else if(lon <= 1.3962634016)then region:=10     // If between -20 and 80 */
    else region:=11;                                // If between 80 and 180 */
  end;

  if region in[1,3,4,5,8,9]then begin
    delta_lon:=adjust_lon(lon-lon_center[region]);
    x:=feast[region]+RG*delta_lon*cos(lat);
    y:=RG*lat;
  end else begin
    delta_lon:=adjust_lon(lon-lon_center[region]);
    theta:=lat;
    constant:=PI*sin(lat);
    // Iterate using the Newton-Raphson method to find theta
    for i:=0 to 30 do begin
      delta_theta:=-(theta+sin(theta)-constant)/(1.0+cos(theta));
      theta:=theta+delta_theta;
      if(abs(delta_theta)<EPSLN)then break;
    end;
    theta:=theta*0.5;
    x:=feast[region]+0.900316316158*RG*delta_lon*cos(theta);
    y:=RG*(1.4142135623731*sin(theta)-0.0528035274542*sign(lat));
  end;
end;

// Goode`s Homolosine inverse equations--mapping x,y to lat,long
//-------------------------------------------------------------*/

function Convert_GHI_WGS(x,y:double;var lon,lat:double):boolean;
var arg,theta,temp:double;
    region:integer;

begin
// Inverse equations
  result:=false;
  if (y >= RG*0.710987989993)then begin                 /// if on or above 40 44min 11.8sec */
    if (x <= RG * -0.698131700798)then region:= 0 // If to the left of -40 */
    else region:= 2;
  end else if (y >= 0.0)then begin                           // Between 0.0 and 40 44min 11.8sec */
    if (x <= RG * -0.698131700798)then region:= 1 // If to the left of -40 */
    else region:= 3;
  end else if (y >= RG * -0.710987989993)then begin           // Between 0.0 & -40 44min 11.8sec */
    if (x <= RG * -1.74532925199)then region:= 4     // If between -180 and -100 */
    else if (x <= RG * -0.349065850399)then region:= 5 // If between -100 and -20 */
    else if (x <= RG * 1.3962634016)then region:= 8  // If between -20 and 80 */
    else region:= 9;                             // If between 80 and 180 */
  end else begin                                            // Below -40 44min 11.8sec */
    if (x <= RG * -1.74532925199)then region:= 6     // If between -180 and -100 */
    else if (x <= RG * -0.349065850399)then region:= 7 // If between -100 and -20 */
    else if (x <= RG * 1.3962634016)then region:= 10 // If between -20 and 80 */
    else region:= 11;                            // If between 80 and 180 */
  end;
  x:=x-feast[region];
  if region in[1,3,4,5,8,9]then begin
    lat:= y / RG;
    if (abs(lat)>PI*0.5)then exit;
    temp:=abs(lat)-PI*0.5;
    if (abs(temp) > EPSLN)then begin
       temp:=lon_center[region] + x / (RG * cos(lat));
       lon:= adjust_lon(temp);
    end else begin
      lon:= lon_center[region];
    end;
  end else begin
    arg:= (y + 0.0528035274542 * RG * sign(y)) /  (1.4142135623731 * RG);
    if (abs(arg) > 1.0)then exit;
    theta:= arcsin(arg);
    lon:= lon_center[region]+(x/(0.900316316158 * RG * cos(theta)));
    if(lon < (-PI))then exit;
    arg := (2.0 * theta + sin(2.0 * theta)) / PI;
    if (abs(arg) > 1.0)then exit;
    lat:=arcsin(arg);
  end;
  // Are we in a interrupted area?  If so, return status code of IN_BREAK.
  //---------------------------------------------------------------------*/
  if (region = 0)and((lon < -PI)or(lon > -0.698131700798))   then exit else
  if (region = 1)and((lon < -PI)or(lon > -0.698131700798))   then exit else
  if (region = 2)and((lon < -0.698131700798)or(lon > PI))    then exit else
  if (region = 3)and((lon < -0.698131700798)or(lon > PI))    then exit else
  if (region = 4)and((lon < -PI)or(lon > -1.74532925199))    then exit else
  if (region = 5)and((lon<-1.74532925199)or(lon>-0.349065850399))then exit else
  if (region = 6)and((lon < -PI)or(lon > -1.74532925199))    then exit else
  if (region = 7)and((lon<-1.74532925199)or(lon>-0.349065850399))then exit else
  if (region = 8)and((lon<-0.349065850399)or(lon>1.3962634016))then exit else
  if (region = 9)and((lon < 1.3962634016)or(lon > PI))        then exit else
  if (region =10)and((lon<-0.349065850399)or(lon>1.3962634016))then exit else
  if (region =11)and((lon < 1.3962634016)or(lon > PI))        then exit;
  result:=true;
end;


Procedure Convert_EOV_WGS(var x,y:double);overload;
  function DEGREES(s:double):double;begin result:=s*(180/pi);end;
  function RADIANS(s:double):double;begin result:=s*(pi/180);end;
  function ATAN2(x,y:double):double;begin result:=ArcTan2(y,x);end;
Type
  TMain=record G6,H6,C6,D6:double end;
  TParameters=record D6,E6,F6,G6,H6,I6,J6:double;end;
  TBursaWolf=record
    AI4,AG4,AE4,X4,Y4,Q4,W4,N4,M4,J4,I4,K4,
    B4,L4,C4,V4,O4,U4,P4,AB4,
    AA4,AF4,Z4,S4,T4,AC4,AJ4,AH4,R4:double;
  end;
  TBursaVolfConst=record
    D4,E4,F4,G4,H4:double;
  end;

  TEOV2HD72=record
    AD1,AE1,AB1,T1,S1,P1,G1,M1,K1,A1,N1,L1,B1,J1,X1,Y1,W1,
    Z1,AA1,AC1,E1,Q1:double;
  end;
  TEOV2HD72consts=record
    C1,D1,F1,H1,I1,O1,U1,V1:double;
  end;

const Parameters:tparameters=(
    D6:52.684;
    E6:-71.194;
    F6:-13.975;
    G6:0.312;
    H6:0.1063;
    I6:0.3729;
    J6:0.0000010191;
  );
const EOV2HD72Const:TEOV2HD72consts=(
    C1:1.0007197049;
    D1:19.048571778;
    F1:47.1;
    H1:6379296.419;
    I1:47+7/60+20.0578/3600;
    O1:47+1/6;
    U1:6378160;
    V1:6356774.516;
);
const BursaWolfConst:TBursaVolfConst=(
    D4:0;
    E4:6378160;
    F4:6356774.719;
    G4:6378137;
    H4:6356752.3142;
);
var Main:TMain;
    BursaWolf:TBursaWolf;
    EOV2HD72:teov2hd72;
begin
  Main.C6:=x;
  Main.D6:=y;

  with EOV2HD72,EOV2HD72Const do begin
    A1:=Main.D6;
    B1:=Main.C6;

    L1:=B1-650000;
    N1:=L1/H1;
    K1:=A1-200000;
    M1:=2*(ArcTAN(EXP(K1/H1))-PI/4);
    G1:=F1*PI/180;
    P1:=ArcSIN(COS(G1)*SIN(M1)+SIN(G1)*COS(M1)*COS(N1));
    T1:=O1*PI/180;
    J1:=I1*PI/180;
    X1:=180*3600/PI;
    S1:=(P1-J1)*X1;
    W1:=(U1*U1-V1*V1)*COS(T1)*COS(T1)/V1/V1;
    Y1:=SQRT(1+W1);
    Z1:=1.5*W1*TAN(T1)/X1;
    AA1:=0.5*W1*(-1+TAN(T1)*TAN(T1)-W1+5*W1*TAN(T1)*TAN(T1))/Y1/X1/X1;
    AB1:=T1+S1*Y1/X1-S1*S1*Z1/X1+S1*S1*S1*AA1/X1;
    AD1:=AB1*180/PI;
    E1:=D1*PI/180;
    Q1:=ArcSIN(SIN(N1)*COS(M1)/COS(P1));
    AC1:=E1+Q1/C1;
    AE1:=AC1*180/PI;

    Main.G6:=AD1;
    Main.H6:=AE1;
  end;

  with BursaWolf,BursaWolfConst do begin
    B4:=Main.G6;
    C4:=Main.H6;

    K4:=B4*PI/180;
    L4:=C4*PI/180;
    I4:=(E4-F4)/E4;
    J4:=2*I4-I4*I4;
    M4:=E4/SQRT(1-J4*SIN(K4)*SIN(K4));
    N4:=(M4+D4)*COS(K4)*COS(L4);
    W4:=Parameters.J6;
    O4:=(M4+D4)*COS(K4)*SIN(L4);
    U4:=Parameters.H6;
    Q4:=Parameters.D6;
    V4:=Parameters.I6;
    P4:=(M4*(1-J4)+D4)*SIN(K4);
    X4:=Q4+(1+W4)*(N4+RADIANS(V4/3600)*O4-RADIANS(U4/3600)*P4);
    R4:=Parameters.E6;
    T4:=Parameters.G6;
    Y4:=R4+(1+W4)*(-N4*RADIANS(V4/3600)+O4+P4*RADIANS(T4/3600));
    AE4:=SQRT(X4*X4+Y4*Y4);
    AA4:=(G4-H4)/G4;
    AB4:=2*AA4-AA4*AA4;
    S4:=Parameters.F6;
    Z4:=S4+(1+W4)*(N4*RADIANS(U4/3600)-O4*RADIANS(T4/3600)+P4);
    AF4:=ATAN2(AE4*H4,Z4*G4);
    AC4:=(G4*G4-H4*H4)/H4/H4;
    AG4:=ATAN2(AE4-AB4*G4*COS(AF4)*COS(AF4)*COS(AF4),Z4+AC4*H4*SIN(AF4)*SIN(AF4)*SIN(AF4));
    AI4:={DEGREES}(AG4);
    AH4:=ATAN2(X4,Y4);
    AJ4:={DEGREES}(AH4);

    x:=AJ4;
    y:=AI4;
  end;
end;

function Convert_WGS_EOV(var x,y: Double):boolean;
Type
  TDoubleCoord3D = Record X, Y, Z: Double; End;
  TDoubleCoord2D = Record X, Y: Double; End;
  TDoubleCoordPolar = Record XFok, YTav: Double; End;

 Function ELL_XYZ(Const ad: TDoubleCoord2D; Const ad1, ad2, d, d1:  Double): TDoubleCoord3D;
 Var d2, d3, d4: Double;
 Begin
   d2:= (d * d - d1 * d1) / (d * d);
   d3:= d / sqrt(1.0 - d2 * sin(ad.Y) * sin(ad.Y));
   d4:= ad1 + ad2;
   Result.X:= (d3 + d4) * cos(ad.Y) * cos(ad.x);  //Polarbol XYZ
   Result.Y:= (d3 + d4) * cos(ad.Y) * sin(ad.x);
   Result.Z:= (d3 * (1.0 - d2) + d4) * sin(ad.Y);
 End;

 Function EUREF_HD72(Const ad: TDoubleCoord3D): TDoubleCoord3D; //EUREF89 -ben adja vissza az adatokat
 Var ad2, ad3: TDoubleCoord3D;
      d, d1: Double;
 Begin
   d:= 1.000000000005822;
   d1:=  1.0000010190999999;

   ad3.X:= ad.X - 52.683999999999997;
   ad3.Y:= ad.Y - -71.194000000000003;
   ad3.Z:= ad.Z - -13.975;

   ad2.X:= (1.0000000000022879 * ad3.X + -1.8078694373184586E-006 * ad3.Y + 5.1535967763767014E-007 * ad3.Z) / d;
   ad2.Y:= (1.0000000000002656 * ad3.Y + 1.8078709963955414E-006 * ad3.X + -1.5126177533635316E-006 * ad3.Z) / d;
   ad2.Z:= (1.0000000000032685 * ad3.Z + -5.153542084011298E-007 * ad3.X + 1.5126196167604682E-006 * ad3.Y) / d;

   Result.X:= ad2.X / d1;
   Result.Y:= ad2.Y / d1;
   Result.Z:= ad2.Z / d1;
 End;

 Procedure XYZ_ELL(Const ad: TDoubleCoord3D; Var ad1: TDoubleCoordPolar; var ad2: Double; Const d, d1: Double);
 Var d2, d3, d4, d5, d6, d7, d8: Double;
 Begin
   d2:= (d * d - d1 * d1) / (d * d);
   d3:= sqrt(ad.X * ad.X + ad.Y * ad.Y);
   d4:= d;
   d5:= 9.9999999999999995E-007;
   ad2:= 0.0;
   ad1.YTav:= arctan2(ad.Y, ad.X);
   While True do Begin
     d7:= ad.Z / d3;
     d8:= 1.0 - (d2 * d4) / (d4 + ad2);
     ad1.XFok:= arctan2(d7, d8);
     d4:= d / sqrt(1.0 - d2 * sin(ad1.XFok) * sin(ad1.XFok));
     ad2:= d3 / cos(ad1.XFok) - d4;
     d6:= (d4 * (1.0 - d2) + ad2) * sin(ad1.XFok) - ad.Z;
     ad2:= ad2 - d6;
     If Not (abs(d6) > d5) Then Break;
   End;
 End;

 Function iugg_e(): Double;
 Begin
   Result:= sqrt(0.0066946053569177958);
 End;

 Function iugg_n(): Double;
 Begin
   Result:= sin(0.82321363052399998) / sin(0.82243820885649999);
 End;

 Function iugg_k(): Double;
 Var d, d1, d2, d3, d4, d5, d6, d7: Double;
 Begin
   d:= 3.1415926535897931;
   d1:= iugg_n();
   d2:= iugg_e();
   d:= d/4.0;
   d3:= tan(0.41121910442824999 + d);
   d4:= tan(0.41160681526199999 + d);
   d5:= power(d4, d1);
   d4:= d5;
   d5:= (1.0 - d2 * sin(0.82321363052399998)) / (1.0 + d2 * sin(0.82321363052399998));
   d6:= (d1 * d2) / 2.0;
   d7:= power(d5, d6);
   d5:= d7 * d4;
   Result:= d3 / d5;
 End;

 Function iugg_FILA_fila(Const ad1: TDoubleCoordPolar): TDoubleCoordPolar;
 Var d, d1, d2, d3, d4, d5, d6, d7: Double;
 Begin
   d:= 3.1415926535897931;
   d:= d/4.0;
   d1:= iugg_e();
   d2:= iugg_n();
   d3:= iugg_k();
   d4:= ad1.XFok / 2.0 + d;
   d5:= tan(d4);
   d6:= power(d5, d2);
   d4:= (1.0 - d1 * sin(ad1.XFok)) / (1.0 + d1 * sin(ad1.XFok));
   d5:= (d2 * d1) / 2.0;
   d7:= Power(d4, d5);
   d4:= d3 * d6 * d7;
   d5:= arctan(d4);
   d4:= d5 - d;
   Result.XFok:= 2.0 * d4;
   Result.YTav:= d2 * (ad1.YTav - 0.33246029532470001);
 End;

 Function iugg_R(): Double;
 Var d, d1, d2, d3, d4: Double;
 Begin
   d:= iugg_e();
   d1:= sqrt(1.0 - d * d * sin(0.82321363052399998) * sin(0.82321363052399998));
   d2:= 6378160.0 / d1;
   d1:= 40680924985600.0 * cos(0.82321363052399998) * cos(0.82321363052399998) + 40408582247267.031 * sin(0.82321363052399998) * sin(0.82321363052399998);
   d3:= power(d1, 1.5);
   d4:= 1.6438585031755181E+027 / d3;
   Result:= sqrt(d4 * d2);
 End;

 Function gauss_sgomb(Const ad1: TDoubleCoordPolar): TDoubleCoord2D;
 Begin
   Result.X:= arcsin(sin(ad1.XFok) * cos(0.82205007768930005) - cos(ad1.XFok) * cos(ad1.YTav) * sin(0.82205007768930005));
   Result.Y:= arcsin((cos(ad1.XFok) * sin(ad1.YTav)) / cos(Result.X));
 End;

 Function iugg_fila_xy(Const ad1: TDoubleCoordPolar): TDoubleCoord2D;
 Var ad2: TDoubleCoord2D;
     d, d1,d2, d3: Double;
 Begin
   d:= 3.1415926535897931;
   d1:= 0.99992999999999999;
   d:= d / 4.0;
   d2:= iugg_R();
   ad2:= gauss_sgomb(ad1);
   d3:= d + ad2.X / 2.0;
   Result.Y:= d1 * d2 * ln(tan(d3)) + 200000.0;
   Result.X:= d1 * d2 * ad2.Y + 650000.0;
 End;

Var WGS, EOV: TDoubleCoord2D;
    Polar: TDoubleCoordPolar;
    Geoidundulacio, tegerszint_feletti_magassag, EOVfelettiMagassag: Double;
Begin
  result:=InRange(x,0.273434916,0.462512252)and InRange(y,0.785398163,0.852302451);
  if not result then begin
    x:=0;y:=0;
    exit;
  end;
  WGS.X:= x{* Pi/180};
  WGS.Y:= Y{* Pi/180};
  tegerszint_feletti_magassag:= 0;
  Geoidundulacio:= 44.5; //A Fold alakjanak az elterese a geoidhoz kepest (geoid-ellipszoid)
                         // ez kb 40-46m. BP-en 44.5 LSD google://geoidunduláció-térképe
  //A WGS'84 ellipszoid feletti magassag=Geoidundulacio+WGSH
  XYZ_ELL(EUREF_HD72({WGS84}ELL_XYZ(WGS, tegerszint_feletti_magassag, Geoidundulacio, {WGS84ellipszoid:} 6378137.0, 6356752.3141400004)), Polar, EOVfelettiMagassag, {IUGG/1967 ellipszoid:} 6378160.0, 6356774.5159999998);
  EOV:= iugg_fila_xy(iugg_FILA_fila(Polar));
  x:= EOV.X; y:= EOV.Y;
End;

procedure EOVSwapIfNeeded(var x,y:double);
var t:double;
begin
  if(X<400000)and(Y>400000)then begin
    t:=x;x:=y;y:=t;
  end;
end;

////////////////////////////////////////////////////////////////////////////////

//some double constants
var
  _DegToRad,_RadToDeg,
  _TileToRad,_RadToTile,
  _TileToDeg,_DegToTile:double;

function CoordSys(const Major:TMajorCoordSys;Minor:TMinorCoordSys):TCoordSys;
begin
  result:=TCoordSys(ord(Major)*3+ord(Minor));
end;

function Coord(const ASystem:TCoordSys;const ACoord:TV2d):TCoordinate;
begin
  result.Coord:=ACoord;
  result.FSystem:=ASystem;
end;

function TCoordinate.GetMinorSys:TMinorCoordSys;
begin
  result:=MinorSysOf[FSystem];
end;

procedure TCoordinate.SetMinorSys(const Value: TMinorCoordSys);
begin
  if MinorSys=Value then exit;
  with Coord do if MajorSys=csEOV then case MinorSys of
    csDeg,csRad:case Value of
      csTile:begin EOVSwapIfNeeded(V[0],V[1]);V[0]:=(V[0]-650000)*(1/600000);V[1]:=-V[1]*(1/600000);end;
    end;
    csTile:case Value of
      csDeg,csRad:begin V[0]:=V[0]*600000+650000;V[1]:=V[1]*600000;end;
    end
  end
  else case MinorSys of
    csDeg:case Value of
      csRad:begin V[0]:=V[0]*_DegToRad;V[1]:=V[1]*_DegToRad;end;
      csTile:begin V[0]:=V[0]*_DegToTile+0.5;V[1]:=-V[1]*_DegToTile+0.5;end;
    end;
    csRad:case Value of
      csDeg:begin V[0]:=V[0]*_RadToDeg;V[1]:=V[1]*_RadToDeg;end;
      csTile:begin V[0]:=V[0]*_RadToTile+0.5;V[1]:=-V[1]*_RadToTile+0.5;end;
    end;
    csTile:case Value of
      csDeg:begin V[0]:=(V[0]-0.5)*_TileToDeg;V[1]:=(0.5-V[1])*_TileToDeg;end;
      csRad:begin V[0]:=(V[0]-0.5)*_TileToRad;V[1]:=(0.5-V[1])*_TileToRad;end;
    end;
  end;
  FSystem:=CoordSys(MajorSysOf[FSystem],Value);
end;

function TCoordinate.GetMajorSys:TMajorCoordSys;
begin
  result:=MajorSysOf[FSystem];
end;

procedure TCoordinate.SetMajorSys(const Value: TMajorCoordSys);
begin
  System:=CoordSys(Value,MinorSys);
end;

procedure TCoordinate.SetSystem(const ADstSystem:TCoordSys);
begin with Coord do begin
  if MajorSys<>MajorSysOf[ADstSystem] then begin
    MinorSys:=csRad;
    case MajorSys of
      csWGS:case MajorSysOf[ADstSystem] of
        csMRC:Convert_WGS_MRC(V[1],V[1]);
        csGHI:Convert_WGS_GHI(V[0],V[1],V[0],V[1]);
        csEOV:Convert_WGS_EOV(V[0],V[1]);
      end;
      csMRC:case MajorSysOf[ADstSystem] of
        csWGS:Convert_MRC_WGS(V[1],V[1]);
        csGHI:begin Convert_MRC_WGS(V[1],V[1]);Convert_WGS_GHI(V[0],V[1],V[0],V[1]);end;
        csEOV:begin Convert_MRC_WGS(V[1],V[1]);Convert_WGS_EOV(V[0],V[1]);end;
      end;
      csGHI:case MajorSysOf[ADstSystem] of
        csWGS:Convert_GHI_WGS(V[0],V[1],V[0],V[1]);
        csMRC:begin Convert_GHI_WGS(V[0],V[1],V[0],V[1]);Convert_WGS_MRC(V[1],V[1]);end;
        csEOV:begin Convert_GHI_WGS(V[0],V[1],V[0],V[1]);Convert_WGS_EOV(V[0],V[1]);end;
      end;
      csEOV:begin
        EOVSwapIfNeeded(V[0],V[1]);
        case MajorSysOf[ADstSystem] of
          csWGS:Convert_EOV_WGS(V[0],V[1]);
          csMRC:begin Convert_EOV_WGS(V[0],V[1]);Convert_WGS_MRC(V[1],V[1]);end;
          csGHI:begin Convert_EOV_WGS(V[0],V[1]);Convert_WGS_GHI(V[0],V[1],V[0],V[1]);end;
        end;
      end;
    end;
    FSystem:=CoordSys(MajorSysOf[ADstSystem],MinorSys);
  end;
  MinorSys:=MinorSysOf[ADstSystem];
end;end;

procedure TCoordinate.SetSystemNoConvert(const ASystem: TCoordSys);
begin
  FSystem:=ASystem;
end;

class operator TCoordinate.explicit(const c: TCoordinate): ansistring;

  function to2Digit(const i:integer):ansistring;begin result:=toStr(i);while length(result)<2 do result:='0'+result end;
  function to4Digit(const i:integer):ansistring;begin result:=toStr(i);while length(result)<4 do result:='0'+result end;

  function DegToStr(const Adeg:double;AVertical:boolean):ansistring;
  var d:double;
  begin
    if ADeg>=0 then begin result:=switch(AVertical,'N','E');d:=ADeg end
               else begin result:=switch(AVertical,'S','W');d:=-ADeg end;
    result:=result+toStr(floor(d));d:=(d-floor(d))*60;
    result:=result+#248+to2digit(floor(d));d:=(d-floor(d))*60;
    result:=result+''''+to2digit(floor(d));d:=(d-floor(d))*10000;
    result:=result+'.'+to4digit(floor(d))+'"';
  end;

  function EOVToStr(d:double):ansistring;
  begin
    result:=toStr(floor(d));d:=(d-floor(d))*100;
    result:=result+'.'+to2Digit(floor(d));
  end;

var c2:TCoordinate;
begin
  c2:=c;
  c2.MinorSys:=csDeg;
  if c2.MajorSys=csEOV then
    result:=EOVToStr(c2.Coord.V[0])+' '+EOVToStr(c2.Coord.V[1])
  else
    result:=DegToStr(c2.Coord.V[1],true)+' '+DegToStr(c2.Coord.V[0],false);
end;

function TCoordinate.Convert(const ACoordSys: TCoordSys): TCoordinate;
begin
  result:=self;
  result.System:=ACoordSys;
end;

class operator TCoordinate.explicit(const s:ansistring):TCoordinate;

  procedure Str2Deg(const s:ansistring;idx:integer;out res:TV2D);
    procedure Split(var Act,Remainder:ansistring;const ch:ansichar);
    var i:integer;
    begin
      i:=pos(ch,Act,[]);
      if i>0 then begin
        Remainder:=copy(Act,i+1,$ff);
        SetLength(Act,i-1);
      end else begin
        Remainder:='';
      end;
    end;

  var sDeg,sMin,sSec,sDummy:ansistring;
      ch:ansichar;
      sign:double;
  begin
    sDeg:=s;

    ch:=UC(charn(sDeg,1));
    sign:=switch(ch in ['S','W'],-1,1);

    if ch in['N','S']then idx:=1 else
    if ch in['E','W']then idx:=0;

    if ch in['N','S','E','W'] then
      delete(sDeg,1,1);

    Split(sDeg,sMin,#248);
    Split(sMin,sSec,'''');
    Split(sSec,sDummy,'"');

    res.V[idx]:=StrToFloatDef(sDeg,0)+
                StrToFloatDef(sMin,0)*(1/60)+
                StrToFloatDef(sSec,0)*(1/60/60);

    if sign<0 then
      res.V[idx]:=-res.V[idx];
  end;

var i:integer;
begin with result.Coord do begin
  V[0]:=0;
  V[1]:=0;
  for i:=0 to 1 do
    Str2Deg(listItem(trimf(s),i,' '),1-i{forditva van!},result.Coord);

  if(V[0]>400000)xor(V[0]>400000)then begin
    result.FSystem:=csEOVmeters;
    EOVSwapIfNeeded(V[0],V[1]);
  end else
    result.FSystem:=csWGSdeg;
end;end;

class operator TCoordinate.implicit(const c:TCoordinate):TV2d;
begin
  result:=c.Coord;
end;

class operator TCoordinate.Equal(const a, b: TCoordinate): boolean;
begin
  if a.system=b.System then result:=a.Coord=b.Coord
                       else result:=a.Coord=b.Convert(a.System).Coord;
end;

class operator TCoordinate.NotEqual(const a, b: TCoordinate): boolean;
begin
  if a.system=b.System then result:=a.Coord<>b.Coord
                       else result:=a.Coord<>b.Convert(a.System).Coord;
end;

class operator TCoordinate.Subtract(const a, b: TCoordinate): TCoordinate;
begin
  result.FSystem:=a.FSystem;
  if a.FSystem=b.FSystem then with b do begin result.Coord:=a.Coord-Coord end
                         else with b.Convert(a.FSystem)do result.Coord:=a.Coord-Coord;
end;

class operator TCoordinate.Add(const a, b: TCoordinate): TCoordinate;
begin
  result.FSystem:=a.FSystem;
  if a.FSystem=b.FSystem then with b do begin result.Coord:=a.Coord+Coord end
                         else with b.Convert(a.FSystem)do result.Coord:=a.Coord+Coord;
end;


initialization
  _DegToRad:=pi/180;                _RadToDeg:=1/_DegToRad;
  _TileToRad:=2*pi;                 _RadToTile:=1/_TileToRad;
  _TileToDeg:=_TileToRad*_RadToDeg; _DegToTile:=_DegToRad*_RadToTile;
finalization

end.

