package gm2d.ui;

import gm2d.geom.Rectangle;
import gm2d.display.Sprite;
import gm2d.display.Shape;
import gm2d.display.Bitmap;
import gm2d.display.BitmapData;
import gm2d.display.DisplayObjectContainer;
import gm2d.text.TextField;
//import gm2d.ui.HitBoxes;
import gm2d.geom.Point;
import gm2d.events.MouseEvent;
import gm2d.ui.HitBoxes;
import gm2d.ui.Dock;
import gm2d.ui.DockPosition;
import gm2d.Game;




class MDIParent extends Widget, implements IDock, implements IDockable
{
   var parentDock:IDock;
   var mChildren:Array<MDIChildFrame>;
   var mDockables:Array<IDockable>;
   public var clientArea(default,null):Sprite;
   public var clientWidth(default,null):Float;
   public var clientHeight(default,null):Float;
   var mTabHeight:Int;
   var mTabArea:Bitmap;
   var mHitBoxes:HitBoxes;
   var mMaximizedPane:IDockable;
   var current:IDockable;
   var flags:Int;

   public function new( )
   {
      super();
      clientArea = new Sprite();
      clientArea.name = "Client area";
      clientWidth = 100;
      clientHeight = 100;
      mHitBoxes = new HitBoxes(this,onHitBox);
      addChild(clientArea);
      mTabArea = new Bitmap();
      addChild(mTabArea);
      mChildren = [];
      mDockables = [];
      mMaximizedPane = null;
      clientWidth = clientHeight = 100.0;
      mTabHeight = 20;
      current = null;
      flags = 0;
   }

   // --- IDock --------------------------------------------------------------

   public function canAddDockable(inPos:DockPosition):Bool { return inPos==DOCK_OVER; }
   public function addDockable(inChild:IDockable,inPos:DockPosition,inSlot:Int):Void
   {
      if (inPos!=DOCK_OVER) throw "Bad dock";

      inChild.setDock(this);
      mDockables.push(inChild);
      if (mMaximizedPane==null)
      {
         Dock.setMinimized(inChild,false);
         var child = new MDIChildFrame(inChild,this,true);
         mChildren.push(child);
         clientArea.addChild(child);
         current = inChild;
         redrawTabs();
      }
      else
         maximize(inChild);
   }
   public function getDockablePosition(child:IDockable):Int
   {
      for(i in 0...mDockables.length)
         if (mDockables[i]==child)
           return i;
      return -1;
   }


   public function removeDockable(inPane:IDockable):IDockable
   {
      if (mMaximizedPane!=null)
      {
         if (mMaximizedPane==inPane)
         {
            if (mDockables.length==1)
               mMaximizedPane = null;
            else if (mDockables[mDockables.length-1]==inPane)
               maximize(mDockables[mDockables.length-2]);
            else
               maximize(mDockables[mDockables.length-1]);
          }
       }
       else
       {
	       var idx = findChildPane(inPane);
	       if (idx>=0)
          {
	          clientArea.removeChild(mChildren[idx]);
	          mChildren.splice(idx,1);
	       }
       }

       var idx = findPaneIndex(inPane);
       mDockables.splice(idx,1);
       redrawTabs();
       return this;
   }

   public function raiseDockable(child:IDockable):Bool
   {
      if (mMaximizedPane!=null)
      {
         if (mMaximizedPane!=child)
           return false;
         maximize(child);
      }
      else
      {
         var idx = findChildPane(child);
         if (idx<0)
            return false;
         current = child;
         if (idx>=0 && clientArea.getChildIndex(mChildren[idx])<mChildren.length-1)
         {
            clientArea.setChildIndex(mChildren[idx], mChildren.length-1);
            redrawTabs();
         }
      }
      return true;
   }



   // --- IDockable --------------------------------------------------------------

   // Hierarchy
   public function getDock():IDock { return parentDock; }
   public function setDock(inDock:IDock):Void { parentDock = inDock; }
   public function setContainer(inParent:DisplayObjectContainer):Void
   {
      inParent.addChild(this);
   }
   public function closeRequest(inForce:Bool):Void {  }
   // Display
   public function getTitle():String { return ""; }
   public function getShortTitle():String { return ""; }
   public function buttonStates():Array<Int> { return null; }
   public function getFlags():Int { return flags; }
   public function setFlags(inFlags:Int):Void { flags = inFlags; }
   // Layout
   public function getBestSize(inPos:DockPosition):Size { return new Size(clientWidth,clientHeight); }
   public function getMinSize():Size { return new Size(1,1); }
   public function getLayoutSize(w:Float,h:Float,limitX:Bool):Size { return new Size(w,h); }
   public function setRect(inX:Float,inY:Float,w:Float,h:Float):Void
   {
      x = inX;
      y = inY;
      layout(w,h);
   }

   public function wantsResize(inHorizontal:Bool,inMove:Int):Bool
   {
      if (inMove>=0)
         return true;

      if (inHorizontal)
         return clientWidth>1;
      else
         return clientHeight>1;
   }

   public function setChromeDirty():Void
   {
      // Do nothing for now...
   }

   public function renderChrome(inBackground:Sprite):Void
   {
   }

   public function asPane() : Pane { return null; }



   // ---------------------------------------------------------------------------

   public function getCurrent() : IDockable
   {
      return current;
   }
  
   public function maximize(inPane:IDockable)
   {
      current = inPane;
      for(child in mChildren)
         child.destroy();
      mChildren = [];
      if (clientArea.numChildren==1)
         clientArea.removeChildAt(0);
      if (mMaximizedPane==null)
         clientArea.graphics.clear();
      mMaximizedPane = inPane;
      inPane.setContainer(clientArea);
      inPane.setRect(0,0,clientWidth,clientHeight);
      redrawTabs();
   }
   public function restore()
   {
      mHitBoxes.buttonState[MiniButton.RESTORE] = 0;
      if (mMaximizedPane!=null)
      {
         current = mMaximizedPane;
         mMaximizedPane.setContainer(null);
         mMaximizedPane = null;
         for(pane in mDockables)
         {
            //if ((pane.getFlags()&Dock.MINIMIZED)==0)
            {
               var frame = new MDIChildFrame(pane,this,pane==current);
               mChildren.push(frame);
               clientArea.addChild(frame);
            }
         }
         doLayout();
         raiseDockable(current);
      }
   }

   override public function layout(inW:Float,inH:Float):Void
   {
      // TODO: other tab layouts...
      mTabHeight = Skin.current.getTabHeight();
      clientWidth = inW;
      clientHeight = inH-mTabHeight;
      clientArea.y = mTabHeight;
      doLayout();
   }


   function doLayout()
   {
      if (clientHeight<1)
         clientArea.visible = false;
      else
      {
         clientArea.visible = true;
         clientArea.scrollRect = new Rectangle(0,0,clientWidth,clientHeight);
         if (mMaximizedPane!=null)
         {
            clientArea.graphics.clear();
            mMaximizedPane.setRect(0,0,clientWidth,clientHeight);
         }
         else
            Skin.current.renderMDI(clientArea);
      }

      var bmp = new BitmapData(Std.int(clientWidth), mTabHeight, false);
      mTabArea.bitmapData = bmp;
      redrawTabs();
   }

   function findPaneIndex(inPane:IDockable)
   {
      for(idx in 0...mDockables.length)
         if (mDockables[idx]==inPane)
            return idx;
      return -1;
   }


   function findChildPane(inPane:IDockable)
   {
      for(idx in 0...mChildren.length)
         if (mChildren[idx].pane==inPane)
            return idx;
      return -1;
   }

   function redrawTabs()
   {
	   var current = getCurrent();
	   for(child in mChildren)
		   child.setCurrent(child.pane==current);
      if (mTabArea.bitmapData!=null)
         Skin.current.renderTabs(mTabArea.bitmapData,mDockables,current,mHitBoxes, mMaximizedPane!=null);
   }

	function showPaneMenu()
	{
	   var menu = new MenuItem("Tabs");
		for(pane in mDockables)
		   menu.add( new MenuItem(pane.getShortTitle(), function(_)  Dock.raise(pane) ) );
		popup( new PopupMenu(menu), clientWidth-50,mTabHeight);
	}

   function onHitBox(inAction:HitAction)
   {
      switch(inAction)
      {
         case DRAG(pane):
            //trace("Drag:" + pane.title);
            //stage.addEventListener(MouseEvent.MOUSE_UP,onEndDrag);
            //mDragStage = stage;
            //startDrag();
         case TITLE(pane):
            Dock.raise(pane);
         case BUTTON(pane,id):
            if (id==MiniButton.CLOSE)
               pane.closeRequest(false);
            else if (id==MiniButton.RESTORE)
               restore();
            else if (id==MiniButton.POPUP)
				{
			      if (mDockables.length>0)
			         showPaneMenu();
				}
            redrawTabs();
         case REDRAW:
            redrawTabs();
         default:
      }
   }
}



// --- MDIChildFrame ----------------------------------------------------------------------



class MDIChildFrame extends Sprite
{
   public var pane(default,null) : IDockable;

   static var mNextChildPos = 0;
   var mMDI : MDIParent;
   var mHitBoxes:HitBoxes;
   var mClientWidth:Int;
   var mClientHeight:Int;
   var mClientOffset:Point;
   var mDragStage:gm2d.display.Stage;
   var mResizeHandle:Sprite;
	var mIsCurrent:Bool;
   var mSizeX0:Int;
   var mSizeY0:Int;

   public function new(inPane:IDockable, inMDI:MDIParent, inIsCurrent:Bool )
   {
      super();
		mIsCurrent = inIsCurrent;
      pane = inPane;
      pane.setContainer(this);
      mHitBoxes = new HitBoxes(this, onHitBox);
      mMDI = inMDI;

      var size = inPane.getBestSize(DOCK_OVER);
      if (size.x<Skin.current.getMinFrameWidth())
         size = inPane.getLayoutSize(Skin.current.getMinFrameWidth(),size.y,true);

      mNextChildPos += 20;
      if (mNextChildPos+size.x>mMDI.clientWidth || mNextChildPos+size.y>mMDI.clientHeight)
         mNextChildPos = 0;
      x = mNextChildPos;
      y = mNextChildPos;

      mClientWidth = Std.int(Math.max(size.x,Skin.current.getMinFrameWidth())+0.99);
      mClientHeight = Std.int(size.y+0.99);
      setClientSize(mClientWidth,mClientHeight);

      mSizeX0 = mClientWidth;
      mSizeY0 = mClientHeight;

      pane.setRect(mClientOffset.x, mClientOffset.y, mClientWidth, mClientHeight);
   }

   public function setClientSize(inW:Int, inH:Int)
   {
      var minW = Skin.current.getMinFrameWidth();
      mClientWidth = Std.int(Math.max(inW,minW));
      mClientHeight = Std.int(Math.max(inH,1));
      var size = pane.getLayoutSize(mClientWidth,mClientHeight,true);
      if (size.x<minW)
         size = pane.getLayoutSize(minW,mClientHeight,true);
      mClientWidth = Std.int(size.x);
      mClientHeight = Std.int(size.y);
      mClientOffset = Skin.current.getFrameClientOffset();
      pane.setRect(mClientOffset.x, mClientOffset.y, mClientWidth, mClientHeight);
      Skin.current.renderFrame(this,pane,mClientWidth,mClientHeight,mHitBoxes,mIsCurrent);
   }

	public function setCurrent(inIsCurrent:Bool)
	{
	   if (mIsCurrent!=inIsCurrent)
		{
		   mIsCurrent = inIsCurrent;
         Skin.current.renderFrame(this,pane,mClientWidth,mClientHeight,mHitBoxes,mIsCurrent);
		}
	}

   public function destroy()
   {
      pane.setContainer(null);
      parent.removeChild(this);
   }

   function onHitBox(inAction:HitAction)
   {
      switch(inAction)
      {
         case DRAG(pane):
            stage.addEventListener(MouseEvent.MOUSE_UP,onEndDrag);
            mDragStage = stage;
            startDrag();
         case TITLE(pane):
            Dock.raise(pane);
         case BUTTON(pane,id):
            if (id==MiniButton.CLOSE)
               pane.closeRequest(false);
            else if (id==MiniButton.MAXIMIZE)
               mMDI.maximize(pane);
            redraw();
         case REDRAW:
            redraw();
         case RESIZE(pane,flags):
            stage.addEventListener(MouseEvent.MOUSE_UP,onEndDrag);
            stage.addEventListener(MouseEvent.MOUSE_MOVE,onUpdateSize);
            mDragStage = stage;
            mResizeHandle = new Sprite();
            mResizeHandle.name = "Resize handle";
            mSizeX0 = mClientWidth;
            mSizeY0 = mClientHeight;
            addChild(mResizeHandle);
            mResizeHandle.startDrag();
         default:
      }
   }

   function saveRect()
   {
      //pane.gm2dMDIRect = new Rectangle(x,y,mClientWidth,mClientHeight);
   }

   function redraw()
   {
      Skin.current.renderFrame(this,pane,mClientWidth,mClientHeight,mHitBoxes,mIsCurrent);
   }

   function onEndDrag(_)
   {
      mDragStage.removeEventListener(MouseEvent.MOUSE_UP,onEndDrag);
      if (mResizeHandle!=null)
      {
         mDragStage.removeEventListener(MouseEvent.MOUSE_MOVE,onUpdateSize);
         removeChild(mResizeHandle);
         mResizeHandle.stopDrag();
         mResizeHandle = null;
      }
      else
         stopDrag();
      saveRect();
   }

   function onUpdateSize(_)
   {
      if (mResizeHandle!=null)
      {
         var cw = Std.int(mResizeHandle.x + mSizeX0 );
         var ch = Std.int(mResizeHandle.y + mSizeY0  );
         setClientSize(cw,ch);
      }
   }

   public function setPosition(inX:Float, inY:Float)
   {
      x = inX;
      y = inY;
   }
}




