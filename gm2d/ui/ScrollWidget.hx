package gm2d.ui;

import gm2d.events.MouseEvent;
import gm2d.display.Stage;
import gm2d.geom.Point;
import gm2d.geom.Rectangle;
import gm2d.tween.Tween;
import gm2d.math.TimeAverage;
import gm2d.Timer;

class ScrollWidget extends Control
{
   public var scrollX(getScrollX,setScrollX):Float;
   public var scrollY(getScrollY,setScrollY):Float;
   public var scrollWheelStep:Float;
   public var maxScrollX:Float;
   public var maxScrollY:Float;
   public var windowWidth:Float;
   public var windowHeight:Float;
   public var viscousity:Float;
   public var onScroll:Void->Void;
   var mScrollX:Float;
   var mScrollY:Float;
   var mDownPos:Point;
   var mLastPos:Point;
   var mEventStage:Stage;
   public var mScrolling(default,null):Bool;
   var mDownScrollX:Float;
   var mDownScrollY:Float;


   var speedX:TimeAverage;
   var speedY:TimeAverage;
   var mLastT:Float;

   public function new()
   {
      super();
      mEventStage = null;
      maxScrollX = 0;
      maxScrollY = 0;
      windowWidth = windowHeight = 0.0;
      mScrollX = mScrollY = 0.0;
      scrollWheelStep = 20.0;
      mScrolling = false;
      viscousity = 2500.0;
      speedX = new TimeAverage(0.2);
      speedY = new TimeAverage(0.2);
      addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
      addEventListener(MouseEvent.MOUSE_WHEEL,onMouseWheel);
   }
   public function setScrollRange(inControlWidth:Float, inWindowWidth:Float,
                           inControlHeight:Float, inWindowHeight:Float)
   {
       windowWidth = inWindowWidth;
       windowHeight = inWindowHeight;
       maxScrollX = inControlWidth - inWindowWidth;
       if (maxScrollX<0) maxScrollX = 0;
       maxScrollY = inControlHeight - inWindowHeight;
       if (maxScrollY<0) maxScrollY = 0;
       if (mScrollX>maxScrollX)
         mScrollX = maxScrollX;
       if (mScrollY>maxScrollY)
         mScrollY = maxScrollY;
       scrollRect = new Rectangle(mScrollX,mScrollY,windowWidth,windowHeight);
   }

   function onMouseWheel(event:MouseEvent)
   {
      if (maxScrollY>0 && scrollWheelStep>0)
      {
          setScrollY(mScrollY - scrollWheelStep * event.delta);
          if (onScroll!=null)
             onScroll();
      }
   }

   public dynamic function shouldBeginScroll(ev:MouseEvent) : Bool
   {
      return true;
   }

   function onMouseDown(ev:MouseEvent)
   {
       if (!shouldBeginScroll(ev))
          return;

       mLastT = Timer.stamp();
       mEventStage = stage;
       mDownPos = new Point(ev.stageX,ev.stageY);
       mLastPos = mDownPos;
       mEventStage.addEventListener(MouseEvent.MOUSE_MOVE, onStageDrag);
       mEventStage.addEventListener(MouseEvent.MOUSE_UP, onStageUp);
       mScrolling = false;
       //trace("Not scrolling!");
       mDownScrollX= mScrollX;
       mDownScrollY= mScrollY;
       speedX.clear();
       speedY.clear();
       gm2d.Game.screen.timeline.remove(name);
   }
   function removeStageListeners()
   {
      if (mEventStage!=null)
      {
         mEventStage.removeEventListener(MouseEvent.MOUSE_MOVE, onStageDrag);
         mEventStage.removeEventListener(MouseEvent.MOUSE_UP, onStageUp);
         mEventStage = null;
      }
   }

   function onClick(inX:Float, inY:Float)
   {
      trace(inX+","+inY);
   }

   function onStageUp(ev:MouseEvent)
   {
      if (!mScrolling)
      {
         var local = globalToLocal(mDownPos);
         onClick(local.x,local.y);
      }
      else
      {
         if (speedX.isValid)
         {
            var pixels_per_second = speedX.mean;
            //trace("pixels_per_second : " + pixels_per_second);
            var time = Math.abs(pixels_per_second/viscousity);
            var dest = 0.5*pixels_per_second*time;
    
            gm2d.Game.screen.timeline.createTween(name,mScrollX,mScrollX-dest, time,
                function(x) scrollX = x, finishScroll, Tween.DECELERATE );
         }
         if (speedY.isValid)
         {
            var pixels_per_second = speedY.mean;
            //trace("pixels_per_second : " + pixels_per_second);
            var time = Math.abs(pixels_per_second/viscousity);
            var dest = 0.5*pixels_per_second*time;
    
            gm2d.Game.screen.timeline.createTween(name,mScrollY,mScrollY-dest, time,
                function(y) scrollY = y, finishScroll, Tween.DECELERATE );
         }
         if (!speedX.isValid && !speedY.isValid)
            finishScroll();
      }
      removeStageListeners();
   }
   public function finishScroll()
   {
      //if (mScrolling) trace("Scrolling done");
      mScrolling = false;
   }
   public function getScrollX() { return mScrollX; }
   public function setScrollX(val:Float) : Float
   {
      mScrollX = val;
      if (mScrollX<0) mScrollX=0;
      if (mScrollX>maxScrollX) mScrollX = maxScrollX;
      scrollRect = new Rectangle(mScrollX,mScrollY,windowWidth,windowHeight);
      if (onScroll!=null)
         onScroll();
      return mScrollX;
   }
   public function getScrollY() { return mScrollY; }
   public function setScrollY(val:Float) : Float
   {
      mScrollY = val;
      if (mScrollY<0) mScrollY=0;
      if (mScrollY>maxScrollY) mScrollY = maxScrollY;
      scrollRect = new Rectangle(mScrollX,mScrollY,windowWidth,windowHeight);
      if (onScroll!=null)
         onScroll();
      return mScrollY;
   }

   function onStageDrag(ev:MouseEvent)
   {
      var now = Timer.stamp();
      var p0 = globalToLocal(mDownPos);
      var pos = new Point(ev.stageX,ev.stageY);
      var p1 = globalToLocal(pos);
      var dx = p1.x-p0.x;
      var dy = p1.y-p0.y;
      if (!mScrolling && (Math.abs(dx)>10 || Math.abs(dy)>10))
      {
         mScrolling = true;
      }
      if (mScrolling)
      {
         mScrollX = mDownScrollX - dx;
         if (mScrollX<0) mScrollX = 0;
         if (mScrollX>maxScrollX) mScrollX= maxScrollX;
         mScrollY = mDownScrollY - dy;
         if (mScrollY<0) mScrollY = 0;
         if (mScrollY>maxScrollY) mScrollY= maxScrollY;
         scrollRect = new Rectangle(mScrollX,mScrollY,windowWidth,windowHeight);
         var plast = globalToLocal(mLastPos);
         var dt = now-mLastT;
         if (dt>0)
         {
            speedX.add( (p1.x - plast.x)/dt, dt );
            speedY.add( (p1.y - plast.y)/dt, dt );
            mLastPos = pos;
         }
         if (onScroll!=null)
            onScroll();
      }
      mLastT = now;
   }
}

