package gm2d.ui;

import gm2d.text.TextField;
import gm2d.ui.Layout;
import gm2d.events.MouseEvent;
import gm2d.RGBHSV;


class RGBBox extends Widget
{
   var textField:TextField;
   var mWidth:Float;
   var mHeight:Float;
   var mColour:RGBHSV;
   var updateLockout:Int;
   public var onColourChange:RGBHSV->Void;
   public var onDialogCreated:RGBDialog->Void;
   var mShowAlpha:Bool;
   var rgbDialog:RGBDialog;

   public function new(inColour:RGBHSV,inShowAlpha:Bool,inShouldShowPopup=false,?inOnColour:RGBHSV->Void)
   {
      super();
      mShowAlpha = inShowAlpha;
      onColourChange = inOnColour;
      mColour = inColour.clone();
      mWidth = mHeight = 32;
      updateLockout = 0;
      getLayout().setMinSize(20,32);

      var fmt = new nme.text.TextFormat();
      fmt.align = nme.text.TextFormatAlign.CENTER;

      textField = new TextField( );
      textField.border = true;
      textField.defaultTextFormat = fmt;
      textField.borderColor = 0x000000;
      textField.background = true;
      addChild(textField);

      if (inShouldShowPopup)
         textField.addEventListener(MouseEvent.CLICK, function(_) showDialog() );

      redraw();
   }

   public function showDialog( )
   {
      var isNew = false;
      if (rgbDialog==null)
      {
         isNew = true;
         rgbDialog = new RGBDialog(mColour, function(colour) {
            if (onColourChange!=null && updateLockout==0)
               onColourChange(colour.clone());
            setColour(colour);
            } );
         rgbDialog.onClose = function() rgbDialog = null;
         if (onDialogCreated!=null)
            onDialogCreated(rgbDialog);
      }
      Game.doShowDialog(rgbDialog,isNew);
   }

   public function getColour():RGBHSV
   {
      return mColour.clone();
   }

   public function setColour(inCol:RGBHSV)
   {
      updateLockout++;
      var draw =  (inCol.compare(mColour)!=0 || (inCol.a!=mColour.a && mShowAlpha) );
      mColour = inCol.clone();
      if (rgbDialog!=null)
         rgbDialog.setColour(inCol);
      if (draw)
         redraw();
      updateLockout--;
   }

   function redraw()
   {
      textField.width = mWidth;
      textField.height = mHeight;
      textField.backgroundColor = mColour.getRGB();
      textField.textColor = mColour.v > 128 ? 0x000000 : 0xffffff;
      updateLockout++;
      if (mShowAlpha)
         textField.text = StringTools.hex(Std.int(mColour.a*255),2) + StringTools.hex(mColour.getRGB(),6);
      else
         textField.text = StringTools.hex(mColour.getRGB(),6);
      updateLockout--;
   }

   public override function layout(inWidth:Float,inHeight:Float)
   {
      mWidth = inWidth;
      mHeight = inHeight;
      redraw();
   }
}

