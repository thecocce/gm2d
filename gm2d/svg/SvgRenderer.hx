package gm2d.svg;

import Xml;
import gm2d.svg.PathParser;
import gm2d.svg.PathSegment;

import gm2d.geom.Matrix;
import gm2d.geom.Rectangle;
import gm2d.display.Graphics;

import gm2d.display.Shape;
import gm2d.display.Sprite;
import gm2d.display.DisplayObject;
import gm2d.display.GradientType;
import gm2d.display.SpreadMethod;
import gm2d.display.InterpolationMethod;
import gm2d.display.CapsStyle;
import gm2d.display.JointStyle;
import gm2d.display.LineScaleMode;

import gm2d.svg.Grad;
import gm2d.svg.Group;
import gm2d.svg.FillType;
import gm2d.gfx.Gfx;
import gm2d.geom.Rectangle;


typedef GroupPath = Array<String>;
typedef ObjectFilter = String->GroupPath->Bool;

class SvgRenderer
{
    public var width(default,null):Float;
    public var height(default,null):Float;

    var mSvg:Svg;
    var mRoot:Group;
    var mGfx : Gfx;
    var mMatrix : Matrix;
    var mScaleRect:Rectangle;
    var mScaleW:Null<Float>;
    var mScaleH:Null<Float>;
    var mFilter : ObjectFilter;
    var mGroupPath : GroupPath;

    public function new(inSvg:Svg,?inLayer:String)
    {
       mSvg = inSvg;

       width = mSvg.width;
       height = mSvg.height;
       mRoot = mSvg;
       if (inLayer!=null)
       {
          mRoot = mSvg.findGroup(inLayer);
          if (mRoot==null)
             throw "Could not find SVG group: " + inLayer;
       }
    }

    public static function toHaxe(inXML:Xml,?inFilter:ObjectFilter) : Array<String>
    {
       return new SvgRenderer(new Svg(inXML,true)).iterate(new gm2d.gfx.Gfx2Haxe(),inFilter).commands;
    }

    public static function toBytes(inXML:Xml,?inFilter:ObjectFilter) : gm2d.gfx.GfxBytes
    {
       return new SvgRenderer(new Svg(inXML,true)).iterate(new gm2d.gfx.GfxBytes(),inFilter);
    }


    public function iterate<T>(inGfx:T, ?inFilter:ObjectFilter) : T
    {
       mGfx = cast inGfx;
       mMatrix = new Matrix();
       mFilter = inFilter;
       mGroupPath = [];
       mGfx.size(width,height);
       iterateGroup(mRoot,true);
       mGfx.eof();
       return inGfx;
    }
    public function hasGroup(inName:String)
    {
        return mRoot.hasGroup(inName);
    }

    public function iterateText(inText:Text)
    {
       if (mFilter!=null && !mFilter(inText.name,mGroupPath))
          return;
       mGfx.renderText(inText);
    }

    public function iteratePath(inPath:Path)
    {
       if (mFilter!=null && !mFilter(inPath.name,mGroupPath))
          return;

       if (inPath.segments.length==0 || mGfx==null)
           return;
       var px = 0.0;
       var py = 0.0;

       var m:Matrix  = inPath.matrix.clone();
       m.concat(mMatrix);
       var context = new RenderContext(m,mScaleRect,mScaleW,mScaleH);

       var geomOnly = mGfx.geometryOnly();
       if (!geomOnly)
       {
          // Move to avoid the case of:
          //  1. finish drawing line on last path
          //  2. set fill=something
          //  3. move (this draws in the fill)
          //  4. continue with "real" drawing
          inPath.segments[0].toGfx(mGfx, context);

          switch(inPath.fill)
          {
             case FillGrad(grad):
                grad.updateMatrix(m);
                mGfx.beginGradientFill(grad);
             case FillSolid(colour):
                mGfx.beginFill(colour,inPath.fill_alpha);
             case FillNone:
                //mGfx.endFill();
          }


          if (inPath.stroke_colour==null)
          {
             //mGfx.lineStyle();
          }
          else
          {
             var style = new gm2d.gfx.LineStyle();
             var scale = Math.sqrt(m.a*m.a + m.c*m.c);
             style.thickness = inPath.stroke_width*scale;
             style.alpha = inPath.stroke_alpha;
             style.color = inPath.stroke_colour;
             style.capsStyle = inPath.stroke_caps;
             style.jointStyle = inPath.joint_style;
             style.miterLimit = inPath.miter_limit;
             mGfx.lineStyle(style);
          }
       }


       for(segment in inPath.segments)
          segment.toGfx(mGfx, context);

       mGfx.endFill();
       mGfx.endLineStyle();
    }



    public function iterateGroup(inGroup:Group,inIgnoreDot:Bool)
    {
       // Convention for hidden layers ...
       if (inIgnoreDot && inGroup.name!=null && inGroup.name.substr(0,1)==".")
          return;

       mGroupPath.push(inGroup.name);

       // if (mFilter!=null && !mFilter(inGroup.name)) return;

       for(child in inGroup.children)
       {
          switch(child)
          {
             case DisplayGroup(group):
                iterateGroup(group,inIgnoreDot);
             case DisplayPath(path):
                iteratePath(path);
             case DisplayText(text):
                iterateText(text);
          }
       }

       mGroupPath.pop();
    }





    public function render(inGfx:Graphics,?inMatrix:Matrix, ?inFilter:ObjectFilter, ?inScaleRect:Rectangle,?inScaleW:Float, ?inScaleH:Float )
    {
       mGfx = new gm2d.gfx.GfxGraphics(inGfx);
       if (inMatrix==null)
          mMatrix = new Matrix();
       else
          mMatrix = inMatrix.clone();

       mScaleRect = inScaleRect;
       mScaleW = inScaleW;
       mScaleH = inScaleH;
       mFilter = inFilter;
       mGroupPath = [];

       iterateGroup(mRoot,inFilter==null);
    }
    public function renderRect(inGfx:Graphics,inFilter:ObjectFilter,scaleRect:Rectangle,inBounds:Rectangle,inRect:Rectangle) : Void
    {
       var matrix = new Matrix();
       matrix.tx = inRect.x-(inBounds.x);
       matrix.ty = inRect.y-(inBounds.y);
       if (scaleRect!=null)
       {
          var extraX = inRect.width-(inBounds.width-scaleRect.width);
          var extraY = inRect.height-(inBounds.height-scaleRect.height);
          render(inGfx,matrix,inFilter,scaleRect, extraX, extraY );
       }
       else
         render(inGfx,matrix,inFilter);
    }

    public function renderRect0(inGfx:Graphics,inFilter:ObjectFilter,scaleRect:Rectangle,inBounds:Rectangle,inRect:Rectangle) : Void
    {
       var matrix = new Matrix();
       matrix.tx = -(inBounds.x);
       matrix.ty = -(inBounds.y);
       if (scaleRect!=null)
       {
          var extraX = inRect.width-(inBounds.width-scaleRect.width);
          var extraY = inRect.height-(inBounds.height-scaleRect.height);
          render(inGfx,matrix,inFilter,scaleRect, extraX, extraY );
       }
       else
         render(inGfx,matrix,inFilter);
    }




    public function getExtent(?inMatrix:Matrix, ?inFilter:ObjectFilter, ?inIgnoreDot:Bool ) :
        Rectangle
    {
       if (inIgnoreDot==null)
          inIgnoreDot = inFilter==null;
       var gfx = new gm2d.gfx.GfxExtent();
       mGfx = gfx;
       if (inMatrix==null)
          mMatrix = new Matrix();
       else
          mMatrix = inMatrix.clone();

       mFilter = inFilter;
       mGroupPath = [];

       iterateGroup(mRoot,inIgnoreDot);

       return gfx.extent;
    }

    public function findText(?inFilter:ObjectFilter)
    {
       mFilter = inFilter;
       mGroupPath = [];
       var finder = new gm2d.gfx.GfxTextFinder();
       mGfx = finder;
       iterateGroup(mRoot,false);
       return finder.text;
    }

    public function getMatchingRect(inMatch:EReg) : Rectangle
    {
       return getExtent(null, function(_,groups) {
          return groups[1]!=null && inMatch.match(groups[1]);
       }, false  );
    }

    public function renderObject(inObj:DisplayObject,inGfx:Graphics,
                    ?inMatrix:Matrix,?inFilter:ObjectFilter,?inScale9:Rectangle)
    {
       render(inGfx,inMatrix,inFilter,inScale9);
       var rect = getExtent(inMatrix, function(_,groups) { return groups[1]==".scale9"; } );
		 // TODO:
		 /*
       if (rect!=null)
          inObj.scale9Grid = rect;
       #if !flash
       inObj.cacheAsBitmap = neash.Lib.IsOpenGL();
       #end
		 */
    }

    public function renderSprite(inObj:Sprite, ?inMatrix:Matrix,?inFilter:ObjectFilter, ?inScale9:Rectangle)
    {
       renderObject(inObj,inObj.graphics,inMatrix,inFilter,inScale9);
    }

    public function createShape(?inMatrix:Matrix,?inFilter:ObjectFilter, ?inScale9:Rectangle) : Shape
    {
       var shape = new Shape();
       renderObject(shape,shape.graphics,inMatrix,inFilter,inScale9);
       return shape;
    }

    public function namedShape(inName:String) : Shape
    {
       return createShape(null, function(name,_) { return name==inName; } );
    }


    public function renderBitmap(?inRect:Rectangle,inScale:Float = 1.0)
    {
       mMatrix = new Matrix(inScale,0,0,inScale, -inRect.x*inScale, -inRect.y*inScale);

       var w = Std.int(Math.ceil( inRect==null ? width : inRect.width*inScale ));
       var h = Std.int(Math.ceil( inRect==null ? width : inRect.height*inScale ));

       var bmp = new gm2d.display.BitmapData(w,h,true,gm2d.RGB.CLEAR );

       var shape = new gm2d.display.Shape();
       mGfx = new gm2d.gfx.GfxGraphics(shape.graphics);

       mGroupPath = [];
       iterateGroup(mRoot,true);

       bmp.draw(shape);
       mGfx = null;

       return bmp;
    }
}

