package gm2d.svg;

import gm2d.reso.Resources;
import gm2d.svg.SvgRenderer;
import gm2d.geom.Matrix;

import gm2d.display.Shape;
import gm2d.display.Bitmap;
import gm2d.display.BitmapData;

#if haxe3
typedef BitmapDataHash = haxe.ds.StringMap<BitmapData>;
#else
typedef BitmapDataHash = Hash<BitmapData>;
#end

class BitmapDataManager
{
   static var bitmaps = new BitmapDataHash();
   static var mScale = 0.0;

   public static function create(inSVG:String, inGroup:String, inScale:Float, inCache=false)
   {
      var key = inSVG + " : " + inGroup + " : " +inScale;
      if (bitmaps.exists(key))
         return bitmaps.get(key);

      var svg:SvgRenderer = new SvgRenderer( Resources.loadSvg(inSVG) );
      var shape = new Shape();
      if (inGroup=="")
         svg.renderObject(shape,shape.graphics);
      else
         svg.renderObject(shape,shape.graphics,null, function(_,groups) { return groups[0]==inGroup; });

      var matrix = new Matrix();
      matrix.scale(inScale,inScale);

      var w = Std.int(svg.width*inScale +  0.99);
      var h = Std.int(svg.height*inScale +  0.99);
      var bmp = new BitmapData(w,h,true,RGB.ZERO);
      var q = gm2d.Lib.current.stage.quality;
      gm2d.Lib.current.stage.quality = gm2d.display.StageQuality.BEST;
      bmp.draw(shape,matrix);
      gm2d.Lib.current.stage.quality = q;

      if (inCache)
         bitmaps.set(key,bmp);
      return bmp;
   }

   static public function setCacheScale(inScale:Float)
   {
      if (inScale!=mScale)
      {
         bitmaps = new BitmapDataHash();
         mScale = inScale;
      }
   }
}

