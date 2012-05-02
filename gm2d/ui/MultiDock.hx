package gm2d.ui;

import gm2d.display.DisplayObjectContainer;
import gm2d.display.Sprite;
import gm2d.ui.DockPosition;
import gm2d.geom.Rectangle;


class MultiDock implements IDock, implements IDockable
{
   var parentDock:IDock;
   var mDockables:Array<IDockable>;
   var mRect:Rectangle;
   var container:DisplayObjectContainer;
   var currentDockable:IDockable;
   var bestSize:Array<Size>;
   var flags:Int;

   public function new()
   {
      flags = 0;
      mDockables = [];
      bestSize = [];
      mRect = new Rectangle();
   }
   
   // Hierarchy
   public function getDock():IDock { return parentDock; }
   public function getSlot():Int { return parentDock==null ? Dock.DOCK_SLOT_FLOAT : parentDock.getSlot(); }
   public function setDock(inDock:IDock):Void { parentDock = inDock; }
   public function setContainer(inParent:DisplayObjectContainer):Void
   {
      container = inParent;
      for(d in mDockables)
         d.setContainer(container);
   }
   public function closeRequest(inForce:Bool):Void { }
   // Display
   public function getTitle():String { return ""; }
   public function getShortTitle():String { return ""; }
   public function buttonStates():Array<Int> { return null; }
   public function getFlags():Int { return flags; }
   public function setFlags(inFlags:Int):Void { flags = inFlags; }
   // Layout
   public function addPadding(ioSize:Size):Size
   {
      var pad = Skin.current.getMultiDockChromePadding(mDockables.length);
      ioSize.x += pad.x;
      ioSize.y += pad.y;
      return ioSize;
   }
   public function getBestSize(inSlot:Int):Size
   {
      if (bestSize[inSlot]==null)
      {
         var best = new Size(0,0);
         for(dock in mDockables)
         {
            var s = dock.getBestSize(inSlot);
            if (s.x>best.x)
               best.x = s.x;
            if (s.y>best.y)
               best.y = s.y;
         }
         bestSize[inSlot] = addPadding(best);
      }
      return bestSize[inSlot];
   }

   public function getMinSize():Size
   {
      var min = new Size(0,0);
      var s = getSlot();
      for(dock in mDockables)
      {
         var s = dock.getMinSize();
         if (s.x>min.x)
            s.x = min.x;
         if (s.y>min.y)
            s.y = min.y;
      }
 
     return addPadding(min);
   }
   public function getLayoutSize(w:Float,h:Float,limitX:Bool):Size
   {
      var min = getMinSize();
      return new Size(w<min.x ? min.x : w,h<min.y ? min.y : h);
   }
   public function setRect(x:Float,y:Float,w:Float,h:Float):Void
   {
      mRect = new Rectangle(x,y,w,h);

      if (currentDockable!=null)
      {
         var rect = Skin.current.getMultDockRect(mRect,mDockables,currentDockable);

         currentDockable.setRect(rect.x,rect.y,rect.width,rect.height);
      }
      bestSize[getSlot()] = new Size(w,h);

      setDirty(false,true);
   }

   public function getDockRect():gm2d.geom.Rectangle
   {
      return mRect.clone();
   }

   public function renderChrome(inContainer:Sprite,outHitBoxes:HitBoxes):Void
   {
      Skin.current.renderMultDock(this,inContainer,outHitBoxes,mRect,mDockables,currentDockable);
   }

   public function asPane() : Pane { return null; }

   /*
   function onDock(inDockable:IDockable, inPos:Int )
   {
      Dock.remove(inDockable);
      addDockable(inDockable,horizontal?DOCK_LEFT:DOCK_TOP,inPos);
      raiseDockable(inDockable);
   }
   */

   public function addDockZones(outZones:DockZones):Void
   {
      var rect = getDockRect();

      if (rect.contains(outZones.x,outZones.y))
      {
         var skin = Skin.current;
         var dock = getDock();
         skin.renderDropZone(rect,outZones,DOCK_LEFT,true,   function(d) dock.addSibling(this,d,DOCK_LEFT) );
         skin.renderDropZone(rect,outZones,DOCK_RIGHT,true,  function(d) dock.addSibling(this,d,DOCK_RIGHT));
         skin.renderDropZone(rect,outZones,DOCK_TOP,true,    function(d) dock.addSibling(this,d,DOCK_TOP) );
         skin.renderDropZone(rect,outZones,DOCK_BOTTOM,true, function(d) dock.addSibling(this,d,DOCK_BOTTOM) );
         skin.renderDropZone(rect,outZones,DOCK_OVER,true,   function(d) addDockable(d,DOCK_OVER,9999) );
      }
   }




   // --- IDock -----------------------------------------
   public function canAddDockable(inPos:DockPosition):Bool
   {
      return inPos==DOCK_OVER;
   }
   public function pushDockableInternal(child:IDockable)
   {
      mDockables.push(child);
   }
   public function addDockable(child:IDockable,inPos:DockPosition,inSlot:Int):Void
   {
      Dock.remove(child);
      child.setDock(this);
      child.setContainer(container);
      if (inSlot>=mDockables.length)
         mDockables.push(child);
      else
         mDockables.insert(inSlot<0?0:inSlot, child);
      raiseDockable(child);
      setDirty(true,true);
   }
   public function addSibling(inReference:IDockable,inIncoming:IDockable,inPos:DockPosition)
   {
      throw "No sibling for multi-dock";
   }

   public function toString()
   {
      var r = getDockRect();
      return("MultiDock " + mDockables);
   }

   public function verify()
   {
      for(d in mDockables)
      {
         if (d.getDock()!=this)
         {
             trace("  this  " + this );
             trace("  child " + d );
             trace("  is    " + d.getDock() );
             trace("  children " + mDockables );
             throw("Bad dock reference");
         }
         d.verify();
      }
   }

   public function getDockablePosition(child:IDockable):Int
   {
      for(i in 0...mDockables.length)
        if (child==mDockables[i])
           return i;
      return -1;
   }
   public function removeDockable(child:IDockable):IDockable
   {
      if (mDockables.remove(child))
      {
         child.setDock(null);
         child.setContainer(null);
         if (mDockables.length==0)
         {
             // Hmmm?
             trace("Bad pane nesting");
             return null;
         }
         else if (mDockables.length==1)
         {
            mDockables[0].setDock(getDock());
            return mDockables[0];
         }
      }
      else
      {
         for(i in 0...mDockables.length)
         {
             mDockables[i] = mDockables[i].removeDockable(child);
             mDockables[i].setDock(this);
         }
      }
      
      return this;
   }
 
   public function raiseDockable(child:IDockable):Bool
   {
      for(i in 0...mDockables.length)
        if (child==mDockables[i])
        {
           currentDockable = child;
           for(d in mDockables)
           {
              if (d==child)
                 d.setContainer(container);
              else
                 d.setContainer(null);
           }
           return true;
        }
      return false;
   }
   public function setDirty(inLayout:Bool, inChrome:Bool):Void
   {
      if (parentDock!=null)
         parentDock.setDirty(inLayout,inChrome);
   }


}

