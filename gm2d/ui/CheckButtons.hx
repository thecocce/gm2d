package gm2d.ui;

import gm2d.display.BitmapData;
import gm2d.display.Bitmap;
import gm2d.display.Shape;
import gm2d.display.Sprite;
import gm2d.ui.Button;
import gm2d.skin.Skin;
import gm2d.skin.ButtonRenderer;
import gm2d.skin.ButtonState;


class CheckButtons extends ChoiceButtons
{
   var onCheck:Bool->Void;
   public function new(inValue:Bool, inCheck:Bool->Void)
   {
      onCheck = inCheck;
      super(onButton);

      var renderer = new ButtonRenderer();
      renderer.downOffset = new gm2d.geom.Point(0,0);
      renderer.render = function renderButton(outChrome:Sprite,
         inRect:gm2d.geom.Rectangle, inState:ButtonState) {
            if (inState==BUTTON_DOWN)
            {
               var gfx = outChrome.graphics;
               gfx.beginFill(Skin.current.guiDark);
               gfx.drawRect(inRect.x, inRect.y, inRect.width, inRect.height);
            }
      };


      var shape = new Shape();
      var gfx = shape.graphics;
      gfx.lineStyle(4,0x00ff00);
      gfx.moveTo(4,16);
      gfx.lineTo(8,20);
      gfx.lineTo(20,8);
      var bmp = new BitmapData(24,24,true,gm2d.RGB.CLEAR );
      bmp.draw(shape);
      add(new Button(new Bitmap(bmp),null,renderer),"on");

      gfx.clear();
      gfx.lineStyle(4,0xff0000);
      gfx.moveTo(8,8);
      gfx.lineTo(16,16);
      gfx.moveTo(8,16);
      gfx.lineTo(16,8);
      var bmp = new BitmapData(24,24,true,gm2d.RGB.CLEAR );
      bmp.draw(shape);
      add(new Button(new Bitmap(bmp),null,renderer),"off");

      setChecked(inValue);
   }
   function onButton(inKey:String) { if (onCheck!=null) onCheck(inKey=="on"); }

   public function setChecked(inCheck:Bool)
   {
      setState(inCheck?"on":"off");
   }
}

