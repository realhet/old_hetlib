unit U2dPhysics;
// based on 2d physics engine made by olivierrenault@hotmail.com

interface

uses
  windows, math, het.Utils, UVector, UMatrix;

type
  TCollisionInfo=record
    // overlaps
    overlapped:boolean;
    mtdLengthSquared:single;
    mtd:TV2f;

    // swept
    collided:boolean;
    Nenter,
    Nleave:TV2f;
    tenter,
    tleave:single;
  end;

  TSupportPoints=record
    support:array[0..3]of TV2f;
    count:integer;
  end;

  TPoly=record
  public
    vertices:array of TV2f;
    procedure CreateRect(const AMin,AMax:TV2f);
    procedure CreateNGon(const ACount:integer;const ARadius:single);
    function calculateMass(const ADensity:single):single;
    function calculateInertia:single;
    function calculateCentroid:TV2f;

    procedure Transform(const APosition:TV2f;const ARotation:single);
    procedure Translate(const ADelta:TV2f);
    function Collide(const APoly:TPoly;const ADelta:TV2f):TCollisionInfo;
    function getSupports(const AAxis:TV2f):TSupportPoints;
//	void			render		(bool solid=true) const;
    function Clone:TPoly;
  private
    function separatedByAxis(const AAxis:TV2f;const APoly:TPoly;const ADelta:TV2f;var AInfo:TCollisionInfo):boolean;
    procedure calculateInterval(const AAxis:TV2f;out AMin,AMax:single);
    function separatedByAxis_overlap(const AAxis:TV2f;const d0,d1:single;var AInfo:TCollisionInfo):boolean;
    function separatedByAxis_swept(const AAxis:TV2f;const d0,d1,v:single;var AInfo:TCollisionInfo):boolean;
  end;

  TBody=class;

  TContactPair=record
  public
    procedure Init;overload;
    procedure Init(const a,b:TV2f);overload;
  public
    position:array[0..1]of TV2f;
    distanceSquared:single;

    class operator Add(const a,b:TContactPair):TContactPair;
    class operator Multiply(const a:TContactPair;const k:single):TContactPair;
    class operator Divide(const a:TContactPair;const k:single):TContactPair;
  end;

  TContactManifold=record
    procedure Init;overload;
    procedure Init(const supports1,supports2:TSupportPoints);overload;

    procedure edgeEdge(const edge10,edge11,edge20,edge21:TV2f);
    procedure edgeVertex(const edge0,edge1,vertex:TV2f);
    procedure vertexEdge(const vertex,edge0,edge1:TV2f);
    procedure vertexVertex(const vertex1,vertex2:TV2f);
    function reduction:TContactPair;
  public
    contact:array[0..7]of TContactPair;
    count:integer;
  end;

  TCollisionReport=record
  public
    procedure Init;overload;
    procedure Init(const a,b:TBody);overload;

    procedure applyReponse(const cor,cof:single);

  public
    collisionReported:boolean;
    body:array[0..1]of TBody;
    poly:array[0..1]of TPoly;
    ncoll,
    mtd:TV2f;
    tcoll:single;
    collisionInfo:TCollisionInfo;
    manifold:TContactManifold;
    contact:TContactPair;
    vcoll:TV2f;
  end;

  TBody=class
  public
    constructor Create;
    constructor CreateRect(const AMin,AMax:TV2f);
    constructor CreateRandomPoly(const AWorldSizeX,AWorldSizeY:single);
    constructor CreatePoly(const AVelocity:TV2f;const AAngularVelocity:single;const APoints: TV2fArray;const Density:single);

    procedure update;
  public
    poly:TPoly;
    position:TV2f;
    orientation:single;
    velocity:TV2f;
    invmass,
    invinertia,
    angvelocity:single;
  end;

  TBodyArray=array of TBody;

implementation

// taken from
// http://www.physicsforums.com/showthread.php?s=e251fddad79b926d003e2d4154799c14&t=25293&page=2&pp=15

{ TPoly }

function TPoly.calculateMass(const ADensity:single):single;
var i,j:integer;
begin
  if length(vertices)<=2 then exit(0.0001);
  result:=0;
  j:=high(vertices);i:=0;
  while i<length(vertices)do begin
    result:=result+abs(VCrossZ(vertices[i],vertices[j]));
    j:=i;inc(i);
  end;
  result:=result*ADensity*0.5;
end;

function TPoly.calculateInertia:single;
var a,b,denom,numer:single;
    i,j:integer;
begin
  if length(vertices)<=1 then exit(0);
  denom:=0;
  numer:=0;
  j:=high(vertices);i:=0;
  while i<length(vertices)do begin
    a:=abs(VCrossZ(vertices[i],vertices[j]));
    b:=VDot(vertices[j],vertices[j])+VDot(vertices[j],vertices[i])+VDot(vertices[i],vertices[i]);
    denom:=denom+a*b;
    numer:=numer+a;
    j:=i;inc(i);
  end;
  result:=(denom/numer)*(1/6);
end;

function TPoly.calculateCentroid:TV2f; //http://local.wasp.uwa.edu.au/~pbourke/geometry/polyarea/
var inv6A:Single;
    i,j:integer;
begin
  inv6A:=1/calculateMass(6);//bugos asszem

  result:=V2f(0,0);
  j:=high(vertices);i:=0;
  while i<length(vertices)do begin
    result:=result+(vertices[i]+vertices[j])*VCrossZ(vertices[j],vertices[i]);
    j:=i;inc(i);
  end;
  result:=result*inv6A;
end;

procedure TPoly.CreateRect(const AMin,AMax:TV2f);
begin
  setlength(vertices,4);
  vertices[0]:=V2f(AMin.x,AMin.y);
  vertices[1]:=V2f(AMin.x,AMax.y);
  vertices[2]:=V2f(AMax.x,AMax.y);
  vertices[3]:=V2f(AMax.x,AMin.y);
end;

procedure TPoly.CreateNGon(const ACount:integer;const ARadius:single);
var i:integer;a:single;
begin
  setlength(vertices,ACount);
  for i:=0 to high(vertices)do begin
    a:=2*pi*i/length(vertices);
    vertices[i]:=V2f(cos(a),sin(a))*ARadius;
  end;

end;

procedure TPoly.transform(const APosition:TV2f;const ARotation:single);
var i:integer;
    co,si:single;
begin
  co:=Cos(ARotation);
  si:=Sin(ARotation);
  for i:=0 to high(vertices)do
    vertices[i]:=V2F(vertices[i].x*co-vertices[i].y*si+APosition.x,
                     vertices[i].x*si+vertices[i].y*co+APosition.y);
end;

procedure TPoly.translate(const ADelta:TV2f);
var i:integer;
begin
  for i:=0 to high(vertices)do
    vertices[i]:=vertices[i]+ADelta;
end;

function perp(const v:TV2f):TV2f;
begin
  result.x:=-v.y;
  result.y:= v.x;
end;

function TPoly.Clone: TPoly;
begin
  setlength(result.vertices,length(vertices));
  Move(pointer(vertices)^,pointer(result.vertices)^,Length(vertices)*sizeof(vertices[0]));

end;

function TPoly.Collide(const APoly:TPoly;const ADelta:TV2f):TCollisionInfo;
var i,j:integer;
    v0,v1,edge,axis:TV2f;
begin
// reset info to some weird values
  with result do begin
    overlapped:=true;		 // we'll be regressing tests from there
    collided:=true;
    mtdLengthSquared:=-1;        // flags mtd as not being calculated yet
    tenter:=1;			 // flags swept test as not being calculated yet
    tleave:=0;			 // <--- ....
  end;

  // test separation axes of current polygon
  j:=high(vertices);i:=0;
  while i<length(vertices)do begin
    v0:=vertices[j];
    v1:=vertices[i];

    edge:=v1-v0; // edge
    axis:=perp(edge); // sep axis is perpendicular ot the edge
    if separatedByAxis(axis, APOly, ADelta, result)then begin fillchar(result,sizeof(result),0);exit;end;

    j:=i;inc(i);
  end;

  // test separation axes of other polygon
  j:=high(APoly.vertices);i:=0;
  while i<length(APoly.vertices)do begin
    v0:=APoly.vertices[j];
    v1:=APoly.vertices[i];

    edge:=v1-v0; // edge
    axis:=perp(edge); // sep axis is perpendicular ot the edge
    if separatedByAxis(axis, APOly, ADelta, result)then begin fillchar(result,sizeof(result),0);exit;end;

    j:=i;inc(i);
  end;

  assert(not result.overlapped or (result.mtdLengthSquared>=0),'Fakk1');
  assert(not result.collided   or (result.tenter<=result.tleave),'Fakk2');

  // sanity checks
  result.overlapped := result.overlapped and(result.mtdLengthSquared>=0);
  result.collided   := result.collided   and(result.tenter <= result.tleave);

	// normalise normals
  result.Nenter:=VNormalize(result.Nenter);
  result.Nleave:=VNormalize(result.Nleave);

end;

procedure TPoly.calculateInterval(const AAxis:TV2f;out AMin,AMax:single);
var i:integer;d:single;
begin
  AMin:=VDot(vertices[0],AAxis);AMax:=AMin;
  for i:=1 to high(vertices)do begin
    d:=VDot(vertices[i],AAxis);
    if d<AMin then AMin:=d else if d>AMax then AMax:=d;
  end;
end;

function TPoly.separatedByAxis(const AAxis:TV2f;const APoly:TPoly;const ADelta:TV2f;var AInfo:TCollisionInfo):boolean;
var mina,maxa,minb,maxb,d0,d1,v:single;
    sep_overlap,sep_swept:boolean;
begin
  // calculate both polygon intervals along the axis we are testing
  calculateInterval(AAxis, mina, maxa);
  APoly.calculateInterval(AAxis, minb, maxb);

  // calculate the two possible overlap ranges.
  // either we overlap on the left or right of the polygon.
  d0:=(maxb - mina); // 'left' side
  d1:=(minb - maxa); // 'right' side
  v :=VDot(AAxis,ADelta); // project delta on axis for swept tests

  sep_overlap := separatedByAxis_overlap(AAxis, d0, d1, AInfo);
  sep_swept   := separatedByAxis_swept  (AAxis, d0, d1, v, AInfo);

  // both tests didnt find any collision
  // return separated
  result:=sep_overlap and sep_swept;
end;

function TPoly.separatedByAxis_overlap(const AAxis:TV2f;const d0,d1:single;var AInfo:TCollisionInfo):boolean;
var overlap,axis_length_squared,sep_length_squared:single;
    sep:TV2f;
begin
  if not AInfo.overlapped then exit(false);

  // intervals do not overlap.
  // so no overlpa possible.
  if(d0<0)or(d1>0)then begin
    AInfo.overlapped:=false;
    exit(true);
  end;

  // find out if we overlap on the 'right' or 'left' of the polygon.
  overlap:=switch(d0<-d1,d0,d1);

  // the axis length squared
  axis_length_squared:=VDot(AAxis,AAxis);

  assert(axis_length_squared>0.00001,'Fakk3');

  // the mtd vector for that axis
  sep:=AAxis*(overlap/axis_length_squared);

  // the mtd vector length squared.
  sep_length_squared:=VDot(sep,sep);

  // if that vector is smaller than our computed MTD (or the mtd hasn't been computed yet)
  // use that vector as our current mtd.
  if(sep_length_squared < AInfo.mtdLengthSquared) or (AInfo.mtdLengthSquared < 0)then begin
    AInfo.mtdLengthSquared:=sep_length_squared;
    AInfo.mtd:=sep;
  end;
  result:=false;
end;

//procedure Swap(var a,b:TV2f);overload;var c:TV2f;begin c:=a;a:=b;b:=c;end;

function TPoly.separatedByAxis_swept(const AAxis:TV2f;const d0,d1,v:single;var AInfo:TCollisionInfo):boolean;
var N0,N1:TV2f;
    t0,t1:single;
begin
  if(not AInfo.collided)then exit(false);

  // projection too small. ignore test
  if(abs(v)<0.0000001)then exit(true);

  N0:=AAxis;
  N1:=-AAxis;
  t0:= d0 / v;   // estimated time of collision to the 'left' side
  t1:= d1 / v;  // estimated time of collision to the 'right' side

  // sort values on axis
  // so we have a valid swept interval
  if(t0 > t1)then begin
    swap(t0, t1);
    swap(N0, N1);
  end;

  // swept interval outside [0, 1] boundaries.
  // polygons are too far apart
  if(t0 > 1)or(t1 < 0)then begin
    AInfo.collided:=false;
    exit(true);
  end;

  // the swept interval of the collison result hasn't been
  // performed yet.
  if(AInfo.tenter > AInfo.tleave)then begin
    AInfo.tenter := t0;
    AInfo.tleave := t1;
    AInfo.Nenter := N0;
    AInfo.Nleave := N1;
    // not separated
    exit(false);

  // else, make sure our current interval is in
  // range [info.m_tenter, info.m_tleave];
  end else begin
    // separated.
    if(t0 > AInfo.tleave) or (t1 < AInfo.tenter)then begin
      AInfo.collided := false;
      exit(true);
    end;

    // reduce the collison interval
    // to minima
    if (t0 > AInfo.tenter)then begin
      AInfo.tenter := t0;
      AInfo.Nenter := N0;
    end;
    if (t1 < AInfo.tleave)then begin
      AInfo.tleave := t1;
      AInfo.Nleave := N1;
    end;
    // not separated
    exit(false);
  end;
end;

function TPoly.getSupports(const AAxis:TV2f):TSupportPoints;
const threshold:single=1.0E-1;
var min,t:single;
    i,num:integer;
begin
  min:=-1;
  result.count:=0;

  num:=length(vertices);
  for i:=0 to num-1 do begin
    t:=VDot(AAxis,vertices[i]);
    if(t < min) or (i = 0)then
      min:= t;
  end;

  for i:=0 to num-1 do begin
    t:=VDot(AAxis,vertices[i]);

    if(t < min+threshold)then begin
      Result.support[Result.count]:=vertices[i];
      inc(Result.count);
      if Result.count=2 then
         break;
    end;
  end;
end;


{ TBody }

constructor TBody.Create;
begin
end;

constructor TBody.CreateRect(const AMin, AMax: TV2f);
begin
  invinertia:=0;
  invmass:=0;
  orientation:=0;
  position:=V2f(0,0);
  poly.CreateRect(AMin,AMax);
end;

constructor TBody.CreatePoly(const AVelocity:TV2f;const AAngularVelocity:single;const APoints: TV2fArray;const Density:single);
var centroid:TV2f;i:integer;inertia,mass:single;
begin
  setlength(Poly.vertices,length(APoints));
  move(APoints[0],poly.vertices[0],Length(APoints)*sizeof(APoints[0]));

  centroid:=poly.calculateCentroid;
  if centroid<>V2f(0,0) then for i:=0 to high(poly.vertices)do poly.vertices[i]:=poly.vertices[i]-centroid;
  position:=centroid;
  velocity:=AVelocity;
  angvelocity:=AAngularVelocity;

  inertia  := switch(density=0,0,poly.calculateInertia);
  mass     := switch(density=0,0,poly.calculateMass(density));

  if mass>0 then invmass := 1/mass else invmass:=0;
  if inertia>0 then invinertia := 1/(inertia*mass) else invinertia:=0;
end;

constructor TBody.CreateRandomPoly(const AWorldSizeX,AWorldSizeY: single);
var count:integer;
    rad,inertia,mass,density:single;

begin
  position:=v2f(RandomRange(25,75)/100*AWorldSizeX,RandomRange(25,75)/100*AWorldSizeY);
  orientation:=random(628)/1000;
  velocity:=v2f(RandomRange(-10,10)/100*AWorldSizeX,RandomRange(-10,10)/100*AWorldSizeY);
  angvelocity:=randomRange(-10,10)/100;

  count:=random(10)+3;
  rad:=(5+random(5))/100*AWorldSizeX;
  poly.CreateNGon(count, rad*0.7);

  density  := switch(random(10)<0{2},0,random(30)/100+0.7);
  inertia  := switch(density=0,0,poly.calculateInertia);
  mass     := switch(density=0,0,poly.calculateMass(density));

  if mass>0 then invmass := 1/mass else invmass:=0;
  if inertia>0 then invinertia := 1/(inertia*mass) else invinertia:=0;
end;

procedure TBody.update;
begin
  if(invmass = 0)then begin
    velocity:=V2f(0,0);
    angvelocity:=0;
    exit;
  end;

//  velocity:=velocity+V2f(0,0.01);//nemide jon a gravity

  orientation:=orientation+angvelocity;
  position:=position+velocity;
end;

{ TContactPair }

procedure TContactPair.Init;
begin
  position[0] := V2f(0,0);
  position[1] := V2f(0,0);
  distanceSquared := 0;
end;

procedure TContactPair.Init(const a, b: TV2f);
var d:TV2f;
begin
  d:=b-a;
  position[0] := a;
  position[1] := b;
  distanceSquared := VDot(d,d);
end;

class operator TContactPair.Add(const a, b: TContactPair): TContactPair;
begin
  result.Init(a.position[0]+b.position[0],a.position[1]+b.position[1]);
end;

class operator TContactPair.Divide(const a: TContactPair;
  const k: single): TContactPair;
begin
  result:=a*(1/k);
end;

class operator TContactPair.Multiply(const a: TContactPair;
  const k: single): TContactPair;
begin
  result.position[0]:=a.position[0]*k;
  result.position[1]:=a.position[1]*k;
  result.distanceSquared:=k*k;
//  result.Init(a.position[0]*k,a.position[1]*k);
end;

{ TContactManifold }

function CompareContacts(const v0,v1:TContactPair):integer;
begin
  result:=switch(V0.distanceSquared > V1.distanceSquared,1,-1);
end;

function closestPointOnEdge(const edge0,edge1,v:TV2f):TV2f;
var e,d:TV2f;t:single;
begin
  e:=edge1-edge0;
  d:=v-edge0;
  t:=EnsureRange(VDot(e,d)/VDot(e,e),0,1);
  result:=edge0+e*t;
end;

procedure TContactManifold.Init;
begin
  count:=0;
end;

procedure TContactManifold.Init(const supports1, supports2: TSupportPoints);
begin
  if(supports1.count = 1)then begin
    if (supports2.count = 1)then vertexVertex(supports1.support[0], supports2.support[0])
    else if(supports2.count = 2)then vertexEdge(supports1.support[0], supports2.support[0],supports2.support[1])
    else assert(false, 'invalid support point count');
  end else if (supports1.count = 2)then begin
    if (supports2.count = 1)then edgeVertex(supports1.support[0],supports1.support[1], supports2.support[0])
    else if(supports2.count = 2)then edgeEdge(supports1.support[0],supports1.support[1], supports2.support[0],supports2.support[1])
    else assert(false, 'invalid support point count');
  end else
    assert(false, 'invalid support point count');
end;

function TContactManifold.reduction: TContactPair;
var i:integer;
begin
  result.Init;
  for i:=0 to count-1 do
    result:=result+contact[i];
  Result:=Result/count;
end;

procedure TContactManifold.edgeEdge(const edge10,edge11,edge20,edge21:TV2f);
var c:TContactPair;i,j:integer;
begin
  // setup all the potential 4 contact pairs
  contact[0].Init(edge10, closestPointOnEdge(edge20,edge21, edge10));
  contact[1].Init(edge11, closestPointOnEdge(edge20,edge21, edge11));
  contact[2].Init(closestPointOnEdge(edge10,edge11, edge20), edge20);
  contact[3].Init(closestPointOnEdge(edge10,edge11, edge21), edge21);

  // sort the contact pairs by distance value
  for i:=0 to 2 do for j:=i+1 to 3 do
    if contact[i].distanceSquared>contact[j].distanceSquared then begin
      c:=contact[i];contact[i]:=contact[j];contact[j]:=c;end;

  // take the closest two
  count := 2;
end;

procedure TContactManifold.edgeVertex(const edge0,edge1,vertex:TV2f);
begin
  contact[0].Init(closestPointOnEdge(edge0,edge1, vertex), vertex);
  count := 1;
end;

procedure TContactManifold.vertexEdge(const vertex,edge0,edge1:TV2f);
begin
  contact[0].Init(vertex, closestPointOnEdge(edge0,edge1, vertex));
  count := 1;
end;

procedure TContactManifold.vertexVertex(const vertex1, vertex2: TV2f);
begin
  contact[0].Init(vertex1, vertex2);
  count := 1;
end;

{ TCollisionReport }

procedure TCollisionReport.Init;
begin
  collisionReported := false;
  body[0] :=nil; body[1] := NiL;
  ncoll := V2f(0, 0);
  mtd := V2f(0, 0);
  tcoll := 0;
end;

procedure TCollisionReport.Init(const a, b: TBody);
var delta:TV2f;asup,bsup:TSupportPoints;
begin
  collisionReported := false;
  body[0]:=a;
  body[1]:=b;
  manifold.Init;
  contact.Init;
  ncoll:=V2f(0,0);
  mtd:=V2f(0,0);
  tcoll:=0;

  // polygons in world space at the time of collision
  poly[0]:=a.poly.Clone;
  poly[1]:=b.poly.Clone;
  poly[0].transform(a.position, a.orientation);
  poly[1].transform(b.position, b.orientation);

  // find collision
  delta := (a.velocity - b.velocity);
  collisionInfo := poly[0].collide(poly[1], delta);
  collisionReported := (collisionInfo.overlapped or collisionInfo.collided);

  if(not collisionReported)then
    exit;

  // convert collision info into collison plane info
  if(collisionInfo.overlapped)then begin
    if(collisionInfo.mtdLengthSquared <= 0.00001)then begin
      collisionReported := false;
      exit;
    end;

    ncoll := collisionInfo.mtd / sqrt(collisionInfo.mtdLengthSquared);
    tcoll := 0;
    mtd   := collisionInfo.mtd;
  end else if(collisionInfo.collided)then begin
    ncoll := collisionInfo.Nenter;
    tcoll := collisionInfo.tenter;
  end;

  // find contact points at time of collision
  poly[0].translate(a.velocity * tcoll);
  poly[1].translate(b.velocity * tcoll);

  // support pointys of the two objects
  asup := poly[0].getSupports(ncoll);
  bsup := poly[1].getSupports(-ncoll);

  // the contact patch .
  manifold.Init(asup, bsup);

  // approximate the contact patch to a single contact pair.
  contact:=manifold.reduction;
end;

procedure TCollisionReport.applyReponse(const cor, cof: single);
var a,b:TBody;
    pa,pb,ra,rb,va,vb,v,vt,nf,nc,impulse:TV2f;
    jc,jf:single;
begin
  if(not collisionReported)then
    exit;

  a := body[0];
  b := body[1];

  // overlapped. then separate the bodies.
  a.position:=a.position + mtd * (a.invmass / (a.invmass + b.invmass));
  b.position:=b.position - mtd * (b.invmass / (a.invmass + b.invmass));

  // move to time of collision
  a.position:=a.position + a.velocity * tcoll;
  b.position:=b.position + b.velocity * tcoll;

  // apply friction impulses at contacts
  pa := contact.position[0];
  pb := contact.position[1];
  ra := pa - a.position;
  rb := pb - b.position;
  va := a.velocity + perp(ra) * a.angvelocity;
  vb := b.velocity + perp(rb) * b.angvelocity;
  v  := (va - vb);
  vt := v - ncoll * VDot(v , ncoll);
  nf := VNormalize(-vt); // friction normal
  nc := ncoll; // collision normal

  // contact points separating, no impulses.
  if(VDot(v , nc) > 0)then
    exit;

  // collision impulse
  jc := VDot(v , nc)/ ((a.invmass + b.invmass) +
                       VCrossZ(ra , nc) * VCrossZ(ra , nc) * a.invinertia +
                       VCrossZ(rb , nc) * VCrossZ(rb , nc) * b.invinertia);

  // friction impulse
  jf := VDot(v , nf)/ ((a.invmass + b.invmass) +
                       VCrossZ(ra , nf) * VCrossZ(ra , nf) * a.invinertia +
                       VCrossZ(rb , nf) * VCrossZ(rb , nf) * b.invinertia);

  // clamp friction.
  if(abs(jf) > abs(jc * cof))then
          jf := abs(cof) * sign(jc);

  // total impulse restituted
  impulse := nc * (jc * -(1 + cor)) + nf * (jf * -1);

  a.velocity:=a.velocity + impulse * a.invmass;
  b.velocity:=b.velocity - impulse * b.invmass;

  a.angvelocity:=a.angvelocity + VCrossZ(ra , impulse) * a.invinertia;
  b.angvelocity:=b.angvelocity - VCrossZ(rb , impulse) * b.invinertia;
end;

end.
