package gm2d.swf;

import gm2d.geom.ColorTransform;
import gm2d.geom.Matrix;
import gm2d.display.DisplayObject;


class DisplayAttributes
{
   public var mFrame:Int;
   public var mCharacterID:Int;
   public var mMatrix:Matrix;
   public var mColorTransform:ColorTransform;
   public var mRatio:Null<Int>;
   public var mName:String;

   public function new() { }

   public function clone()
   {
      var n = new DisplayAttributes();
      n.mFrame = mFrame;
      n.mMatrix = mMatrix;
      n.mColorTransform = mColorTransform;
      n.mRatio = mRatio;
      n.mName = mName;
      n.mCharacterID = mCharacterID;
      return n;
   }

   public function Apply(inObj:DisplayObject)
   {
      if (mMatrix!=null)
         inObj.transform.matrix = mMatrix.clone();

      if (mRatio!=null && Std.is(inObj,MorphObject))
      {
         var morph:MorphObject = untyped inObj;
         return morph.SetRatio(mRatio);
      }
      return false;
   }
}


typedef DisplayAttributesList = Array<DisplayAttributes>;
