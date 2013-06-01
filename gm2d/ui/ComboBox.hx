package gm2d.ui;

import gm2d.text.TextField;
import gm2d.display.BitmapData;
import gm2d.events.MouseEvent;
import gm2d.ui.Button;
import gm2d.skin.Skin;

class ComboList extends Window
{
   var mList:ListControl;
   var mCombo:ComboBox;
   var mOptions:Array<String>;
   var closeLockout = 0;

   public function new(inParent:ComboBox, inW:Float, inOptions:Array<String>)
   {
      super();
      mCombo = inParent;
      mList = new ListControl(inW);
      mOptions = inOptions;
      if (mOptions.length==0)
         mOptions.push("");

      for(o in mOptions)
         mList.addRow([o]);
      addChild(mList);
      mList.scrollRect = null;

      mList.onSelect = onSelect;
   }

   public function getControlHeight() { return mList.getControlHeight(); }
   public function getControlWidth() { return mList.getControlWidth(); }

   override function windowMouseMove(inEvent:MouseEvent)
   {
      closeLockout++;
      mList.selectByY(inEvent.localY);
      closeLockout--;
   }
   override public function layout(inW:Float, inH:Float)
   {
      var gfx = graphics;
      gfx.lineStyle(1,0x000000);
      gfx.beginFill(0xffffff);
      gfx.drawRect(-0.5,-0.5,inW+2, inH+2);

      mList.layout(inW, inH);
   }

   public function onSelect(idx:Int)
   {
      if (idx>=0)
         mCombo.setText(mOptions[idx]);
      if (closeLockout==0)
         gm2d.Game.closePopup();
   }



   override public function destroy()
   {
      super.destroy();
   }
}



class ComboBox extends Control
{
   var mText:TextField;
   var mButtonX:Float;
   var mWidth:Float;
   var mOptions:Array<String>;
   static var mBMP:BitmapData;

   public function new(inVal="", ?inOptions:Array<String>)
   {
       super();
       mText = new TextField();
       mText.defaultTextFormat = Skin.current.textFormat;
       mText.text = inVal;
       mText.x = 0.5;
       mText.y = 0.5;
       mText.height = 21;
       mText.type = gm2d.text.TextFieldType.INPUT;
 
       if (mBMP==null)
       {
          mBMP = new BitmapData(22,22);
          var shape = new gm2d.display.Shape();
          var gfx = shape.graphics;
          gfx.beginFill(0xffffff);
          gfx.drawRect(-2,-2,28,28);

          gfx.beginFill(0xf0f0f0);
          gfx.lineStyle(1,0x808080);
          gfx.drawRoundRect(0.5,0.5,21,21,3);
          gfx.lineStyle();

          gfx.beginFill(0x000000);
          gfx.moveTo(8,8);
          gfx.lineTo(8,8);
          gfx.lineTo(16,8);
          gfx.lineTo(12,14);
          gfx.lineTo(8,8);
          mBMP.draw(shape);
       }
       mOptions = inOptions==null ? [] : inOptions.copy();
       addChild(mText);
       var me = this;
       addEventListener(MouseEvent.CLICK, function(ev)  if (ev.localX > me.mButtonX) me.doPopup()  );
   }

   function doPopup()
   {
      var pop = new ComboList(this, mWidth, mOptions);
      var pos = this.localToGlobal( new gm2d.geom.Point(0,0) );
      var h = pop.getControlHeight();
      var w = pop.getControlWidth();
      var max = Std.int(stage.stageHeight/2);
      var below = Math.min(max,stage.stageHeight - (pos.y+22));
      var above = Math.min(max,pos.y);
      if (h+pos.y+22 < stage.stageHeight)
      {
         pop.layout(w,h);
         gm2d.Game.popup(pop,pos.x,pos.y+22);
      }
      else if (below>above)
      {
         pop.layout(w,below);
         gm2d.Game.popup(pop,pos.x,pos.y+22);
      }
      else
      {
         pop.layout(w,above);
         gm2d.Game.popup(pop,pos.x,pos.y-above);
      }
   }


   public function setText(inText:String)
   {
       mText.text = inText;
   }

   public override function layout(inW:Float, inH:Float)
   {
       var gfx = graphics;
       gfx.clear();
       gfx.lineStyle(1,0x808080);
       gfx.beginFill(0xf0f0ff);
       gfx.drawRect(0.5,0.5,inW-1,23);
       gfx.lineStyle();
       var mtx = new gm2d.geom.Matrix();
       mtx.tx = inW-mBMP.width-1;
       mtx.ty = 1;
       gfx.beginBitmapFill(mBMP,mtx);
       mButtonX = inW-mBMP.width-1+0.5;
       mWidth = inW;
       gfx.drawRect(mButtonX,1.5,mBMP.width,mBMP.height);
       mText.width = inW - mBMP.width - 2;
       mText.y =  (mBMP.height - 2 - mText.textHeight)/2;
       mText.height =  mBMP.height-mText.y;
   }

}


