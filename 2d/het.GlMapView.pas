unit het.GlMapView;

interface

uses
  Windows, SysUtils, Graphics, het.Utils, het.MapView, het.GlViewer, het.Bitmaps,
  het.Textures, OpenGL1x;

type
  TGlMapView=class(TMapView)
  private
    _Viewer:TGLViewer;
    _TextureCache:TTextureCache;
    procedure GlDrawTile(const Tile:PMapTile;const RSrc,RDst:TRect);
  public
    TextureCache:TTextureCache;
    procedure GlDraw(const Viewer:TGLViewer);//viewport already setup
  end;

implementation

procedure TGlMapView.GlDrawTile(const Tile:PMapTile;const RSrc,RDst:TRect);

  procedure pt(x,y:integer);
  begin
    //glColor3f(x,y,0); debug
    with RSrc do glTexCoord2f(switch(x=0,Left,Right)*(1/256),1-switch(y=0,Top,Bottom)*(1/256));
    with RDst do glVertex2f(switch(x=0,Left,Right),switch(y=0,Top,Bottom));
  end;

begin
  if(Tile<>nil)and(Tile.Bitmap<>nil)then begin
    if TTexture(Tile.Texture)=nil then begin
      TTexture(Tile.Texture):=_TextureCache['MapCache'+toStr(Tile.TileIndex)];
      TTexture(Tile.Texture).LoadFromBitmap(TBitmap.CreateClone(Tile.Bitmap),mtColor_RGB,atGradient,false,false);
                                            //^^^^^^^^^^^ klonozas, mert felszabaditja
    end;

    TTexture(Tile.Texture).Bind(0,rfLinear,true);
    glBegin(GL_QUADS);
    pt(0,0);pt(0,1);pt(1,1);pt(1,0);
    glEnd;
    glDisable(GL_TEXTURE_2D);
  end;
end;

procedure TGlMapView.GlDraw(const Viewer:TGLViewer);
begin
  if self.TextureCache=nil then _TextureCache:=het.Textures.TextureCache
                           else _TextureCache:=self.TextureCache;
  DoDraw(GlDrawTile);
end;

end.