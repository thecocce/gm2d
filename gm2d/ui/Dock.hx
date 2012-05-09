package gm2d.ui;

class Dock
{
   public static inline var RESIZABLE     = 0x0001;
   public static inline var TOOLBAR       = 0x0002;
   public static inline var DONT_DESTROY  = 0x0004;

   public static inline var DOCK_SLOT_HORIZ = 0;
   public static inline var DOCK_SLOT_VERT  = 1;
   public static inline var DOCK_SLOT_FLOAT = 2;
   public static inline var DOCK_SLOT_MDI   = 3;
   public static inline var DOCK_SLOT_MDIMAX = 4;

   public static function isResizeable(i:IDockable) { return (i.getFlags()&RESIZABLE)!=0; }
   public static function isToolbar(i:IDockable) { return (i.getFlags()&TOOLBAR)!=0; }

   public static function remove(child:IDockable)
   {
      var parent = child.getDock();
      if (parent!=null)
      {
         while(true)
         {
            var pp = parent.getDock();
            if (pp==null)
               break;
            parent = pp;
         }
         parent.removeDockable(child);
         child.setDock(null,null);
      }
   }
   public static function raise(child:IDockable)
   {
      child.getDock().raiseDockable(child);
   }
   public static function minimize(child:IDockable)
   {
      child.getDock().minimizeDockable(child);
   }



}
