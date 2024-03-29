package gm2d.ui;

import gm2d.display.BitmapData;
import gm2d.display.Bitmap;
import gm2d.display.DisplayObject;
import gm2d.display.DisplayObjectContainer;
import gm2d.display.Sprite;
import gm2d.events.MouseEvent;
import gm2d.text.TextField;
import gm2d.geom.Rectangle;
import gm2d.ui.Layout;
import gm2d.skin.Skin;
import gm2d.skin.ButtonRenderer;
import gm2d.skin.ButtonState;

class Button extends Control
{
   var mDisplayObj : DisplayObject;
   public var mChrome : Sprite;
   public var mRect : Rectangle;
   public var down(get_down,set_down):Bool;
   public var isToggle:Bool;
	public var noFocus:Bool;
   public var mCallback : Void->Void;
   var mIsDown:Bool;
   var mDownBmp:BitmapData;
   var mDownDX:Float;
   var mDownDY:Float;
   var mUpBmp:BitmapData;
   var mCurrentDX:Float;
   var mCurrentDY:Float;
   var mMainLayout:Layout;
   var mItemLayout:Layout;
   var mRenderer:ButtonRenderer;
   public var onCurrentChangedFunc:Bool->Void;

   static public var BMPButtonFont = "Arial";

   public function new(inObject:DisplayObject,?inOnClick:Void->Void,?inRenderer:ButtonRenderer)
   {
      super();
      name = "button";
      mCallback = inOnClick;
      mIsDown = false;
      mChrome = new Sprite();
      mDisplayObj = inObject;
      addChild(mChrome);
      addChild(mDisplayObj);
      mCurrentDX = mCurrentDY = 0;
      noFocus = false;
      mouseChildren = false;
      isToggle = false;
      mRenderer = inRenderer==null ? Skin.current.buttonRenderer : inRenderer;
      addEventListener(MouseEvent.CLICK, onClick );
      addEventListener(MouseEvent.MOUSE_DOWN, onDown );
      addEventListener(MouseEvent.MOUSE_UP, onUp );

      var offset = mRenderer.downOffset;
      mDownDX = offset.x;
      mDownDY = offset.y;
      getLayout();
   }

   function onClick(e:MouseEvent)
   {
      if (mCallback!=null && !isToggle)
         mCallback();
   }
   function onDown(e:MouseEvent)
   {
      if (isToggle)
      {
         set_down(!get_down());
         if (mCallback!=null)
            mCallback();
      }
      else
         set_down(true);
   }
   function onUp(e:MouseEvent)
   {
      if (!isToggle)
         set_down(false);
   }

   public function getItemLayout()
   {
      getLayout();
      return mItemLayout;
   }

   public function getLabel() : TextField
   { 
      if (Std.is(mDisplayObj,TextField))
         return cast mDisplayObj;
      return null;
   }

/*
   public function setBackground(inSVG:gm2d.svg.SvgRenderer, inW:Float, inH:Float)
   {
      inSVG.renderSprite(mBG);
      mBG.width = inW;
      mBG.height = inH;
   }

   public function setBGRenderer(inRenderer:gm2d.display.Graphics->Float->Float->Void)
   {
      var layout = getLayout();
      setBG(inRenderer,
          layout.getBestWidth()+Skin.current.buttonBorderX,
          layout.getBestHeight()+Skin.current.buttonBorderY);
   }

   public function setBG(inRenderer:gm2d.display.Graphics->Float->Float->Void,inW:Float, inH:Float)
   {
      var gfx = mBG.graphics;
      gfx.clear();
      inRenderer(gfx,inW,inH);
      var layout = getLayout();
      mMainLayout.setBestSize(mBG.width,mBG.height);
   }
   */

   public function setBGStates(inUpBmp:BitmapData, inDownBmp:BitmapData,
             inDownDX:Int = 0, inDownDY:Int = 0)
   {
      mUpBmp = inUpBmp;
      mDownBmp = inDownBmp;
      var w = mUpBmp!=null ? mUpBmp.width : mDownBmp==null? mDownBmp.width : 32;
      var h = mUpBmp!=null ? mUpBmp.height : mDownBmp==null? mDownBmp.height : 32;
      var layout = getLayout();
      mMainLayout.setBestSize(w,h);
      mDownDX = inDownDX;
      mDownDY = inDownDY;
      mIsDown = !mIsDown;
      mItemLayout.setRect(0,0,w,h);
      down = !mIsDown;
   }
   public function get_down() : Bool { return mIsDown; }
   public function set_down(inDown:Bool) : Bool
   {
      if (inDown!=mIsDown)
      {
         mIsDown = inDown;
         if (mDownBmp!=null || mUpBmp!=null)
         {
            var gfx = mChrome.graphics;
            gfx.clear();
            var bmp:BitmapData = mIsDown?mDownBmp:mUpBmp;
            if (bmp!=null)
            {
               gfx.beginBitmapFill(bmp,null,true,true);
               gfx.drawRect(0,0,bmp.width,bmp.height);
            }
         }
			var dx = mIsDown ? mDownDX : 0;
			var dy = mIsDown ? mDownDY : 0;
         if (dx!=mCurrentDX)
         {
			   mDisplayObj.x += dx-mCurrentDX;
				mCurrentDX = dx;
         }
         if (dy!=mCurrentDY)
         {
			   mDisplayObj.y += dy-mCurrentDY;
				mCurrentDY = dy;
         }

         if (mRenderer!=null && mRect!=null)
         {
            mChrome.graphics.clear();
            while(mChrome.numChildren>0)
               mChrome.removeChildAt(0);
            mRenderer.render(mChrome,mRect, mIsDown ? BUTTON_DOWN:BUTTON_UP);
         }
      }
      return mIsDown;
   }


   public static function BMPButton(inBitmapData:BitmapData,inX:Float=0, inY:Float=0,?inOnClick:Void->Void)
   {
      var bmp = new Bitmap(inBitmapData);
      var result = new Button(bmp,inOnClick);
      result.x = inX;
      result.y = inY;
      return result;
   }

   public static function BitmapButton(inBitmapData:BitmapData,?inOnClick:Void->Void,?inRenderer:ButtonRenderer)
   {
      var renderer = inRenderer==null ? Skin.current.buttonRenderer : inRenderer;
      var bmp = new Bitmap(inBitmapData);
      var result = new Button(bmp,inOnClick,renderer);
      return result;
   }


   public static function TextButton(inText:String,inOnClick:Void->Void,?inRenderer:ButtonRenderer)
   {
      var renderer = inRenderer==null ? Skin.current.buttonRenderer : inRenderer;
      var label = new TextField();
      renderer.styleLabel(label);
      label.text = inText;
      label.selectable = false;
      var result =  new Button(label,inOnClick,renderer);
      return result;
   }

   public static function BMPTextButton(inBitmapData:BitmapData,inText:String,
       ?inOnClick:Void->Void, ?inRenderer:ButtonRenderer)
   {
      var sprite = new Sprite();
      var bmp = new Bitmap(inBitmapData);
      sprite.addChild(bmp);
      var label = new TextField();
      var renderer = inRenderer==null ? Skin.current.buttonRenderer : inRenderer;
      renderer.styleLabel(label);
      label.text = inText;
      sprite.addChild(label);
      label.x = bmp.width;
      label.y = (bmp.height - label.height)/2;
      var result = new Button(sprite,inOnClick,inRenderer);
      var layout = result.getItemLayout();
      layout.setBestSize(label.x + label.width, bmp.height);
      return result;
   }

   function renderBackground(inX:Float, inY:Float, inW:Float, inH:Float)
   {
      mRect = new Rectangle(inX-x,inY-y,inW,inH);
      mRenderer.render(mChrome,mRect, mIsDown ? BUTTON_DOWN:BUTTON_UP);
   }

   override public function createLayout() : Layout
   {
      var layout = new ChildStackLayout( );
      layout.setBorders(0,0,0,0);
      mMainLayout = new DisplayLayout(this).setOrigin(0,0);
      mMainLayout.mAlign = Layout.AlignLeft | Layout.AlignTop | Layout.AlignPixel;
      layout.add( mMainLayout );
      mItemLayout = ( Std.is(mDisplayObj,TextField)) ?
           new TextLayout(cast mDisplayObj)  : 
           new DisplayLayout(mDisplayObj) ;
      layout.add(mItemLayout);
      layout.mDebugCol = 0x00ff00;
      layout.onLayout = renderBackground;
      mLayout = layout;
      mRenderer.updateLayout(this);
      return layout;
   }

   override public function onCurrentChanged(inCurrent:Bool)
	{
	   if (onCurrentChangedFunc!=null)
			onCurrentChangedFunc(inCurrent);
		else
		   super.onCurrentChanged(inCurrent);
	}


   override public function activate(inDirection:Int)
   {
      if (inDirection>=0)
      {
        if (isToggle)
           set_down(!get_down());
        if (mCallback!=null)
           mCallback();
      }
   }
}

class BmpButton extends Button
{
   public var bitmap(default,null):Bitmap;
   public var normal:BitmapData;
   public var disabled:BitmapData;

   public function new(inBitmapData:BitmapData,?inOnClick:Void->Void)
   {
      normal = inBitmapData;
      bitmap = new Bitmap(normal);
      super(bitmap,inOnClick);
   }

   public function createDisabled(inBmp:BitmapData)
   {
      var w = inBmp.width;
      var h = inBmp.height;
      var result = new BitmapData(w,h,true,gm2d.RGB.CLEAR);

      for(y in 0...h)
         for(x in 0...w)
         {
            var pix:Int = inBmp.getPixel32(x,y);
            var val:Int = (pix&0xff) + ( (pix>>8)&0xff ) + ( (pix>>16)&0xff ); 
            if (val<255) val=0;
            else if (val>512) val = 255;
            else val = 128;
            val = (val * 0x10101) | (pix&0xff000000);
            result.setPixel32(x,y,val);
         }

      return result;
   }

   public function enable(inEnable:Bool)
   {
      mouseEnabled = inEnable;
      if (inEnable)
         bitmap.bitmapData = normal;
      else
      {
         if (disabled==null)
            disabled = createDisabled(normal);
         bitmap.bitmapData = disabled;
      }
   }
}

