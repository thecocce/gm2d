package gm2d.ui;

import gm2d.display.DisplayObject;
import gm2d.text.TextField;

// --- Layout -------------------------------------------

class Layout
{
   public static var AlignStretch  = 0x0000;
   public static var AlignLeft     = 0x0001;
   public static var AlignRight    = 0x0002;
   public static var AlignCenterX  = 0x0004;
   public static var AlignTop      = 0x0008;
   public static var AlignBottom   = 0x0010;
   public static var AlignCenterY  = 0x0020;
   public static var AlignMaskX    = AlignLeft | AlignRight | AlignCenterX;
   public static var AlignMaskY    = AlignTop | AlignBottom | AlignCenterY;

   public var mBLeft:Float;
   public var mBTop:Float;
   public var mBRight:Float;
   public var mBBottom:Float;

   public var width:Float;
   public var height:Float;

   static var mDebug:gm2d.display.Graphics;

   public function new()
   {
      width = height = 0.0;
      mBLeft = mBRight = mBTop = mBBottom = 5;
   }

   public function calcSize(inWidth:Null<Float>,inHeight:Null<Float>) : Void
      { throw "calcSize - not implemented"; }
   public function setRect(inX:Float,inY:Float,inW:Float,inH:Float) : Void
      { throw "setRect - not implemented"; }
   public function setSpacing(inX:Float,inY:Float) : Layout { return this; }

   static public function SetDebug(inGfx:gm2d.display.Graphics) { mDebug = inGfx; }

   public function setBorders(inL:Float,inT:Float,inR:Float,inB:Float) : Layout
   {
      mBLeft = inL;
      mBTop = inT;
      mBRight = inR;
      mBBottom = inB;
      return this;
   }
   public function add(inLayout:Layout) : Layout
   {
      throw "Can't add to this layout";
      return null;
   }

   public function getBestWidth(?inHeight:Null<Float>) : Float { return 0.0; }
   public function getBestHeight(?inWidth:Null<Float>) : Float { return 0.0; }
}

typedef LayoutList = Array<Layout>;

// --- DisplayLayout ---------------------------------------------------

class DisplayLayout extends Layout
{
   var mObj:DisplayObject;
   var mOX:Float;
   var mOY:Float;
   var mOWidth:Float;
   var mOHeight:Float;
   var mAlign:Int;

   public function new(inObj:DisplayObject,inAlign:Int = 0x24, // AlignCenterX|AlignCenterY
	        ?inPrefWidth:Null<Float>,?inPrefHeight:Null<Float>)
   {
      super();
		mAlign = inAlign;
      mObj = inObj;
      mOWidth = inPrefWidth==null ? inObj.width : inPrefWidth;
      mOHeight =  inPrefHeight==null ? inObj.height : inPrefHeight;
      mOX = inObj.x;
      mOY = inObj.y;
      mBLeft = mBRight = mBTop = mBBottom = 0;
      mAlign = Layout.AlignCenterX | Layout.AlignCenterY;
   }
   public override function calcSize(inWidth:Null<Float>,inHeight:Null<Float>) : Void
   {
   }
   public override function setRect(inX:Float,inY:Float,inW:Float,inH:Float) : Void
   {
      //trace("Set rect " + mObj + " = " + inX + "," + inY + "  " + inW + "x" + inH);
      var w = inW - mBLeft - mBRight;
      var x = mOX + inX + mBLeft;
      switch(mAlign & Layout.AlignMaskX)
      {
         case Layout.AlignLeft:
            mObj.x = x;
            mObj.width = mOWidth;
         case Layout.AlignRight:
            mObj.x = x + w-mOWidth;
            mObj.width = mOWidth;
         case Layout.AlignCenterX:
            mObj.x = x + (w-mOWidth)/2;
            mObj.width = mOWidth;
         default:
            mObj.x = x;
            mObj.width = w;
      }

      var h = inH - mBTop - mBBottom;
      var y = mOY + inY + mBTop;
      switch(mAlign & Layout.AlignMaskY)
      {
         case Layout.AlignTop:
            mObj.y = y;
            mObj.height = mOHeight;
         case Layout.AlignBottom:
            mObj.y = y + h - mOHeight;
            mObj.height = mOHeight;
         case Layout.AlignCenterY:
            mObj.y = y + (h - mOHeight)/2;
            mObj.height = mOHeight;
         default:
            mObj.y = y;
            mObj.height = h;
      }

      if (Layout.mDebug!=null)
      {
         Layout.mDebug.lineStyle(1,0xff0000);
         Layout.mDebug.drawRect(inX,inY,inW,inH);
         Layout.mDebug.lineStyle(1,0x00ff00);
         Layout.mDebug.drawRect(mObj.x,mObj.y,mObj.width,mObj.height);
      }
   }

   public override function getBestWidth(?inHeight:Null<Float>) : Float { return mOWidth; }
   public override function getBestHeight(?inWidth:Null<Float>) : Float { return mOHeight; }
}

class TextLayout extends DisplayLayout
{
   public function new(inObj:TextField,inAlign:Int = 0x24, // AlignCenterX|AlignCenterY
	        ?inPrefWidth:Null<Float>,?inPrefHeight:Null<Float>)
   {
      super(inObj,inAlign);
      mOWidth = inPrefWidth==null ? inObj.textWidth : inPrefWidth;
      mOHeight =  inPrefHeight==null ? inObj.textHeight : inPrefHeight;
   }
}

// --- StackLayout ---------------------------------------------------------------------

class StackLayout extends Layout
{
   var mChildren:LayoutList;

   public function new()
   {
      mChildren = [];
      super();
   }

   public override function calcSize(inWidth:Null<Float>,inHeight:Null<Float>) : Void
   {
      if (inWidth!=null)
         width = inWidth;
      else
         width = getBestWidth(inHeight);

      if (inHeight!=null)
         height = inHeight;
      else
         height = getBestHeight(width);
   }

   public override function setRect(inX:Float,inY:Float,inW:Float,inH:Float) : Void
   {
      for(child in mChildren)
         child.setRect( inX+mBLeft, inY+mBTop, inW-mBLeft-mBRight, inH-mBTop-mBBottom );
   }

   public override function add(inLayout:Layout) : Layout
   {
      mChildren.push(inLayout);
      return this;
   }


   public override function getBestWidth(?inHeight:Null<Float>) : Float
   {
      width = 0;
      for(child in mChildren)
      {
         var w = child.getBestWidth(inHeight);
         if (w>width) width=w;
      }
      width += mBLeft + mBRight;
      return width;

   }
   public override function getBestHeight(?inWidth:Null<Float>) : Float
   {
      height = 0;
      for(child in mChildren)
      {
         var h = child.getBestHeight(inWidth);
         if (h>height) height=h;
      }
      height += mBTop + mBBottom;
      return height;
   }



}

class ChildStackLayout extends StackLayout
{
   public function new()
   {
      super();
   }
   public override function setRect(inX:Float,inY:Float,inW:Float,inH:Float) : Void
   {
      for(i in 0...mChildren.length)
      {
         var child = mChildren[i];
         if (i==0)
            child.setRect( inX+mBLeft, inY+mBTop, inW-mBLeft-mBRight, inH-mBTop-mBBottom );
         else
            child.setRect( 0, 0, inW-mBLeft-mBRight, inH-mBTop-mBBottom );
       }
   }
}

// --- GridLayout -------------------------------------------

class ColInfo
{
   public function new()
   {
      mMaxWidth = 0;
      mFlags = 0;
      mWidth = 0;
      mStretch = 1.0;
   }
   public var mMaxWidth:Float;
   public var mWidth:Float;
   public var mFlags:Int;
   public var mStretch:Float;
}

class RowInfo
{
   public function new()
   {
      mCols = [];
      mStretch = 1.0;
      mFlags = 0;
   }
   public var mCols:LayoutList;
   public var mStretch:Float;
   public var mHeight:Float;
   public var mFlags:Int;
}


class GridLayout extends Layout
{
   var mCols:Null<Int>;
   var mColInfo : Array<ColInfo>;
   var mRowInfo : Array<RowInfo>;
   var mSpaceX:Float;
   var mSpaceY:Float;
   var mPos:Int;
   var mName:String;
   static var mID = 0;

   public function new(?inCols:Null<Int>,?inName:String)
   {
      super();
      mCols = inCols;
      mColInfo = [];
      mRowInfo = [];
      if (inCols!=null)
      {
         for(i in 0...inCols)
            mColInfo[i] = new ColInfo();
      }
      else
      {
         mRowInfo[0] = new RowInfo();
      }
      mName =  (inName==null) ? ("Layout:" + mID++) : inName;
      mPos = 0;
      mSpaceX = 10;
      mSpaceY = 10;
   }
   public override function add(inLayout:Layout) : Layout
   {
      var row = 0;
      if (mCols!=null && mCols>0)
      {
         row = Std.int(mPos / mCols);
         if (row>=mRowInfo.length)
            mRowInfo.push(new RowInfo());
      }
      else
      {
         mColInfo.push(new ColInfo());
      }
      mRowInfo[row].mCols.push(inLayout);
      mPos++;
      return this;
   }

   public override function setSpacing(inX:Float,inY:Float) : Layout
   {
      mSpaceX = inX; mSpaceY = inY;
      return this;
   }
   public function setRowStretch(inRow:Int,inStretch:Float)
   {
      if (mRowInfo[inRow]==null)
         mRowInfo[inRow] = new RowInfo();
      mRowInfo[inRow].mStretch = inStretch;
      return this;
   }
   public function setRowFlags(inRow:Int,inFlags:Int)
   {
      if (mRowInfo[inRow]==null)
         mRowInfo[inRow] = new RowInfo();
      mRowInfo[inRow].mFlags = inFlags & Layout.AlignMaskY;
      return this;
   }

   public function setColStretch(inCol:Int,inStretch:Float)
   {
      if (mColInfo[inCol]==null)
         mColInfo[inCol] = new ColInfo();
      mColInfo[inCol].mStretch = inStretch;
      return this;
   }
   public function setColFlags(inCol:Int,inFlags:Int)
   {
      if (mColInfo[inCol]==null)
         mColInfo[inCol] = new ColInfo();
      mColInfo[inCol].mFlags = inFlags & Layout.AlignMaskX;
      return this;
   }

   function BestColWidths()
   {
      for(col in mColInfo)
         col.mWidth = 0;
      for(row in mRowInfo)
      {
         for(i in 0...row.mCols.length)
         {
            var col =  row.mCols[i];
            if (col!=null)
            {
               var w = col.getBestWidth();
               if (w>mColInfo[i].mWidth)
                  mColInfo[i].mWidth = w;
            }
         }
      }
      var str = "";
      for(col in mColInfo)
        str+="  " + col.mWidth;
   }

   function BestRowHeights()
   {
      for(r in 0...mRowInfo.length)
      {
         var row = mRowInfo[r];
         row.mHeight = 0;
         for(i in 0...row.mCols.length)
         {
            var col =  row.mCols[i];
            if (col!=null)
            {
               var h = col.getBestHeight(mColInfo[i].mWidth);
               if (h>row.mHeight)
                  row.mHeight = h;
            }
         }
      }

   }


   public override function calcSize(inWidth:Null<Float>,inHeight:Null<Float>) : Void
   {
     BestColWidths();

     width = 0;
     for(col in mColInfo)
        width+=col.mWidth;
     width += mBLeft + mBRight;
     if (mColInfo.length>0)
        width += (mColInfo.length -1)*mSpaceX;


     if (inWidth!=null)
     {
        var extra = inWidth - width;
        if (extra!=0)
        {
           var stretch = 0.0;
           for(col in mColInfo)
              stretch += col.mStretch;
           if (stretch!=0)
              for(col in mColInfo)
                 col.mWidth += col.mStretch * extra / stretch;
        }
        width = inWidth;
     }

     BestRowHeights();

     height = 0;
     for(row in mRowInfo)
        height+=row.mHeight;
     height += mBTop + mBBottom;
     if (mRowInfo.length>0)
        height += (mRowInfo.length -1)*mSpaceY;


     if (inHeight!=null)
     {
        var extra = inHeight-height;
        if (extra!=0)
        {
           var stretch = 0.0;
           for(row in mRowInfo)
              stretch += row.mStretch;
           if (stretch!=0)
                 for(row in mRowInfo)
                    row.mHeight += row.mStretch * extra / stretch;
        }

        height = inHeight;
     }
   }

   public override function getBestWidth(?inHeight:Null<Float>) : Float
   {
      BestColWidths();
      var w = mBLeft + mBRight;
      if (mColInfo.length>0)
         w+=(mColInfo.length-1)*mSpaceX;
      for(col in mColInfo)
         w+= col.mWidth;
      return w;
   }
   public override function getBestHeight(?inWidth:Null<Float>) : Float
   {
      BestRowHeights();
      var h = mBTop + mBBottom;
      if (mRowInfo.length>0)
        h+= (mRowInfo.length-1)*mSpaceY;
      for(row in mRowInfo)
         h+= row.mHeight;
      return h;
   }

   public override function setRect(inX:Float,inY:Float,inW:Float,inH:Float) : Void
   {
      calcSize(inW,inH);
      var y = inY + mBTop;
      for(row in mRowInfo)
      {
         var row_h = row.mHeight;
         var x = inX + mBLeft;
         for(c in 0...row.mCols.length)
         {
            var col_w = mColInfo[c].mWidth;
            var ox = x;
            var oy = y;
            var w = col_w;
            var h = row_h;

            var item = row.mCols[c];
            switch(mColInfo[c].mFlags)
            {
               case Layout.AlignLeft:
                  w = item.getBestWidth();
               case Layout.AlignRight:
                  w = item.getBestWidth();
                  ox += col_w - w;
               case Layout.AlignCenterX:
                  w = item.getBestWidth();
                  ox += (col_w - w)/2;
            }

            switch(row.mFlags)
            {
               case Layout.AlignTop:
                  h = item.getBestHeight();
               case Layout.AlignBottom:
                  h = item.getBestHeight();
                  oy += row_h - h;
               case Layout.AlignCenterY:
                  h = item.getBestHeight();
                  oy += (row_h - y)/2;
            }

            item.setRect(ox,oy,w,h);
            x+=col_w + mSpaceX;
         }
         y+= row.mHeight + mSpaceY;
      }

      if (Layout.mDebug!=null)
      {
         Layout.mDebug.lineStyle(1,0xff0000);
         Layout.mDebug.drawRect(inX,inY,inW,inH);
      }
   }
}
