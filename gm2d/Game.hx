package gm2d;

import gm2d.display.Sprite;
import gm2d.Screen;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.text.TextField;
import gm2d.ui.Dialog;

class Game
{
   static public var initWidth = 480;
   static public var initHeight = 320;
   static public var useHardware = true;
   static public var isResizable = true;
   static public var frameRate = 30.0;
   static public var showFPS(getShowFPS,setShowFPS):Bool;
   static public var fpsColor(getFPSColor,setFPSColor):Int;
   static public var backgroundColor = 0xffffff;
   static public var title(default,setTitle):String;
   static public var icon(default,setIcon):String;
   static public var screenName(getScreenName,setScreenName):String;

   static var mCurrentScreen:Screen;

   static var mScreenParent:Sprite;
   static var mDialogParent:Sprite;
   static var mFPSControl:TextField;
   static var mFPSColor:Int = 0xff0000;
   static var mLastEnter = 0.0;
   static var mLastStep = 0.0;

   static var mShowFPS = false;
   static var mFrameTimes = new Array<Float>();
   static var created = false;

   static var mScreenMap:Hash<Screen> = new Hash<Screen>();

   public static function create( inOnLoaded:Void->Void )
   {
      if (created) throw "Game.create : already created";

      created = true;

   #if flash
     init();
     inOnLoaded();
   #else
     nme.Lib.create(function() { init(); inOnLoaded(); },
          initWidth,initHeight,frameRate,backgroundColor,
          (useHardware ? nme.Lib.HARDWARE : 0) | (isResizable ? nme.Lib.RESIZABLE : 0),
          title, icon );
   #end
   
   }

   static function init()
   {
      mScreenParent = new Sprite();
      mDialogParent = new Sprite();
      mDialogParent.visible = false;
      mFPSControl = new TextField();
      mFPSControl.text = "1.0 FPS";
      mFPSControl.selectable = false;
      mFPSControl.mouseEnabled = false;
      mFPSControl.x = 10;
      mFPSControl.y = 10;
      mFPSControl.visible = mShowFPS;
      mFPSControl.textColor = mFPSColor;

      var parent = gm2d.Lib.current;
      parent.addChild(mScreenParent);
      parent.addChild(mDialogParent);
      parent.addChild(mFPSControl);


      //parent.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown );
      //parent.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp );
      parent.stage.addEventListener(Event.ENTER_FRAME, onEnter);
      //parent.stage.addEventListener(Event.RESIZE, onSize);
   }


   public static function gm2dAddScreen(inScreen:Screen)
   {
      mScreenMap.set(inScreen.screenName,inScreen);
   }

   static public function setCurrentScreen(inScreen:Screen)
   {
      if (mCurrentScreen==inScreen)
         return;

      if (mCurrentScreen!=null)
      {
         mCurrentScreen.onActivate(false);
         mScreenParent.removeChild(mCurrentScreen);
      }

      mCurrentScreen = inScreen;

      if (mCurrentScreen!=null)
      {
         mScreenParent.addChild(mCurrentScreen);
         mCurrentScreen.onActivate(true);
      }
      mLastEnter = haxe.Timer.stamp();
      mLastStep = mLastEnter;
   }

   static function getShowFPS() { return mShowFPS; } 
   static function setShowFPS(inShowFPS:Bool) : Bool
   {
      mShowFPS = inShowFPS;
      if (mFPSControl!=null)
         mFPSControl.visible = mShowFPS;
      return inShowFPS;
   }

   static function getFPSColor() { return mFPSColor; } 
   static function setFPSColor(inCol:Int) : Int
   {
      mFPSColor = inCol;
      if (mFPSControl!=null)
         mFPSControl.textColor = mFPSColor;
      return inCol;
   }

   static function getScreenName()
   {
      return mCurrentScreen==null ? "" : mCurrentScreen.screenName;
   } 
   static function setScreenName(inName:String) : String
   {
      if (!mScreenMap.exists(inName))
         throw "Unknown screen : " + inName;

      setCurrentScreen( mScreenMap.get(inName) );
      return inName;
   }

   static function onEnter(_)
   {
      var now = haxe.Timer.stamp();
      if (mCurrentScreen!=null)
      {
         var freq = mCurrentScreen.getUpdateFrequency();
         if (freq<=0)
         {
            mCurrentScreen.updateDelta(now-mLastEnter);
            mLastEnter = now;
         }
         else
         {
            var fps = 1.0/(now-mLastEnter);

            // Do a number of descrete steps based on the frequency.
            var steps = Math.floor( (now-mLastStep) * freq );
            for(i in 0...steps)
               mCurrentScreen.updateFixed();

            mLastStep += steps / freq;

            var fractional_step = (now-mLastStep) * freq;

            mCurrentScreen.renderFixedExtra(fractional_step);

            //trace(steps + ":" + fps + "   (" + fractional_step + ")");

         }
      }
      mLastEnter = now;
      if (mShowFPS)
      {
         mFrameTimes.push(now);
         now -= 0.99;
         while(mFrameTimes[0]<now)
            mFrameTimes.shift();
         mFPSControl.text = "FPS:" + mFrameTimes.length;
      }
   }


   static function setTitle(inTitle:String) : String
   {
      title = inTitle;
      return inTitle;
   }

   static function setIcon(inIcon:String) : String
   {
      icon = inIcon;
      return inIcon;
   }



#if false
   var mScreen:Screen;
   var mDialogScreen:Screen;
   var mDialog:Dialog;
   var mKeyDown:Array<Bool>;
   var mLastStep:Float;
   var mLastEnter:Float;

   var mDialogMap:Hash<Dialog>;
   var mResources:Resources;


   public function new()
   {
      super();
      #if !flash
      neash.Lib.mQuitOnEscape = false;
      #end
      flash.Lib.current.addChild(this);
      stage.stageFocusRect = false;
      stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;


      mLastEnter = haxe.Timer.stamp();
      mLastStep = mLastEnter;
      mScreen = null;
      mDialog = null;
      mKeyDown = [];

      mScreenMap = new Hash<Screen>();
      mDialogMap = new Hash<Dialog>();
      Screen.SetGame(this);
   }

   function SetResources(inResources:Resources) { mResources = inResources; }


   function AddScreen(inName:String, inScreen:Screen) { mScreenMap.set(inName,inScreen); }
   function AddDialog(inName:String, inDialog:Dialog) { mDialogMap.set(inName,inDialog); }

   public function Resource(inName:String) { return mResources.get(inName); }
   public function FreeResource(inName:String) { return mResources.remove(inName); }

   public function IsDown(inCode:Int) : Bool { return mKeyDown[inCode]; }



   function OnKeyDown(event:flash.events.KeyboardEvent )
   {
      if (mDialog!=null)
         mDialog.OnKeyDown(event);
      else if (mScreen!=null)
         mScreen.OnKeyDown(event);
      mKeyDown[event.keyCode] = true;
   }

   function OnKeyUp(event:flash.events.KeyboardEvent )
   {
      if (mDialog==null && mScreen!=null)
         mScreen.OnKeyUp(event);
      mKeyDown[event.keyCode] = false;
   }

   function onUpdate(e:flash.events.Event)
   {
      var now = haxe.Timer.stamp();
      if (mCurrentScreen!=null)
      {
         var freq = mCurrentScreen.GetUpdateFrequency();
         if (freq<=0)
         {
            mScreen.UpdateDelta(now-mLastEnter);
            mScreen.Render(0);
            mLastEnter = now;
         }
         else
         {
            var fps = 1.0/(now-mLastEnter);

            // Do a number of descrete steps based on the frequency.
            var steps = Math.floor( (now-mLastStep) * freq );
            for(i in 0...steps)
               mScreen.UpdateFixed();

            mLastStep += steps / freq;


            var fractional_step = (now-mLastStep) * freq;

            mScreen.Render(fractional_step);

            //hxcpp.Lib.println(steps + ":" + fps + "   (" + fractional_step + ")");

         }
      }
      mLastEnter = now;
   }

   public function SetScreen(inScreen:String)
   {
      var screen:Screen = mScreenMap.get(inScreen);
      if (screen==null)
         throw "Invalid Screen "+  inScreen;

      CloseDialog();

      if (mScreen!=null)
      {
         removeChild(mScreen);
         mScreen = null;
      }

      mScreen = screen;

      addChildAt(mScreen,0);
      mScreen.OnAdded();
      mScreen.Layout(stage.stageWidth,stage.stageHeight);
   }

   public function ShowDialog(inDialog:String)
   {
      var dialog:Dialog = mDialogMap.get(inDialog);
      if (dialog==null)
         throw "Invalid Dialog "+  inDialog;
      DoShowDialog(dialog);
   }

   public function CloseDialog() { DoShowDialog(null); }

   function DoShowDialog(inDialog:Dialog)
   {
      if (mDialog!=null)
      {
         mDialog.onClose();
         mDialogScreen.removeChild(mDialog);
         mDialog = null;
      }

      mDialog = inDialog;

      if (mDialog!=null)
      {
         if (mScreen==null)
            throw "Can't add a dialog without a screen.";

         mDialogScreen = mScreen;
         mDialogScreen.addChild(mDialog);
         mDialog.onAdded();
         mDialog.DoLayout();
      }
   }

   function OnSize(e:Event)
   {
      if (mScreen!=null)
         mScreen.Layout(stage.stageWidth,stage.stageHeight);
   }


#end
}
