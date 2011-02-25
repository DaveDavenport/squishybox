/* Squishybox 
 * Copyright (C) 2010-2011 Qball Cow <qball@sarine.nl>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */
using SDL;

namespace SDLMpc
{
	public class SDLWidget : GLib.Object 
	{
        public unowned SDLWidget parent = null;
		public int x;
		public int y;
		public uint w;
		public uint h;

        ~SDLWidget()
        {
        }
        /**
         * Flag indicating that the widget is visible
         */
        public bool visible = true;
        /**
         * Flag indicating that the widget has focus 
         */
        private bool _focus;
        public bool focus {
            get{return _focus;}
            set {
               _focus = value;
               this.require_redraw =true;
            }
            }
        public List<unowned SDLWidget?> focus_chain = null;
        public unowned List<unowned SDLWidget?> focus_current = null;
        public void add_focus_widget(SDLWidget w)
        {
            focus_chain.append(w);
            if(focus_current == null) {
                focus_current = focus_chain.first();
                w.focus = true;
            }
        }


        /**
         * List of children 
         */
		public List<SDLWidget> children;

        /**
         * Flag indicates that the widget needs to be redrawn
         */
		public bool require_redraw = true;

        public virtual unowned string get_name()
        {
            return "Not Set";
        }


        public void get_absolute_position(ref int nx, ref int ny)
        {
            nx += this.x;
            ny += this.y;
            if(this.parent!= null) {
                this.parent.get_absolute_position(ref nx, ref ny);     
            }
        }
		public bool inside(int x, int y)
		{
            int tx=0, ty=0;
            this.get_absolute_position(ref tx, ref ty);

			if(x > tx && (x) < (tx+this.w)) 
			{
				if(y > ty && (y) < (ty+this.h)) 
				{
					return true;
				}
			}
			return false;
		}

		public bool clicked(int x, int y, bool press_state)
		{
			foreach (var child in children)
			{
				if(child.clicked(x, y, press_state))return true;
			}
			if(this.inside(x,y))
			{
				if(press_state) {
					if(this.button_press()) return true;
				}
				else
					this.button_release(true);
//				return press_state;
			}
			else {
				if(!press_state) {
					this.button_release(false);
				}
			}
			return false;
		}
		
		public virtual bool button_press()
		{
            return false;
		}
		public virtual void button_release(bool inside)
		{
            
		}

		public virtual bool check_redraw()
		{
			if(this.require_redraw) return true;
			return false;
		}

		public virtual List<SDL.Rect ?> get_redraw_rect(owned List<SDL.Rect?> rr,SDL.Rect g)
		{
            if(this.visible == false && this.require_redraw = false) return (owned)rr;
            int tx=0, ty=0;
            this.get_absolute_position(ref tx, ref ty);

			g.x += (int16)tx;
			g.y += (int16)ty;
			foreach ( var child in children) 
			{
				rr = child.get_redraw_rect((owned)rr,g);
			}  
			g.x -= (int16)tx;
			g.y -= (int16)ty;
			if(this.check_redraw()) {
				if((w) > 0 && (h) > 0)
				{
					SDL.Rect r = {0,0,0,0};
					r.x =(int16) tx; r.y =(int16) ty; r.w =(uint16)this.w; r.h =(uint16) this.h;
					rr.append(r);
				}
			}     

        	return (owned)rr;
		}


		public virtual bool intersect(SDL.Rect r)
		{
            if(visible == false) return false;
            if(r.x == 0 && r.y == 0 && r.h == 272 && r.w == 480) return true;
            int tx=0, ty=0;
            this.get_absolute_position(ref tx, ref ty);
            return !(tx> (r.x+r.w) || (tx+this.w) <= r.x ||
                    ty > (r.y+r.h) || (ty+this.h) <= r.y);
		}
		public virtual void draw(Surface screen, SDL.Rect *rect)
		{
			if(this is SDLWidgetDrawing) {
				if(this.intersect(*rect))
				{
					(this as SDLWidgetDrawing).draw_drawing(screen, rect);
				}
			}
			this.require_redraw = false;
			foreach ( var child in children) 
			{
				child.draw(screen,rect);
			}

		}

        public virtual void Tick(time_t now)
        {
        }

        public virtual void do_Tick(time_t t)
        {
            this.Tick(t);
			foreach ( var child in children) 
			{
				child.do_Tick(t);
			}
        }

        public virtual bool Event(Event ev)
        {
      
            /* By default do not block */
            return false;
        }

        /**
         * test
         * returns: try to stop. 
         */
        public bool do_Event(Event ev)
        {
			foreach ( var child in children) 
			{
				if(child.do_Event(ev)) {
                    return true;
                }
			}
            if(ev.type == SDLMpc.EventType.KEY)
            {
                switch(ev.command)
                {
                    case EventCommand.UP:
                        if(focus_chain == null) break;
                        if(focus_current != null){
                            focus_current.data.focus = false;
                            focus_current = focus_current.prev;
                        }
                        if(focus_current == null) {
                            focus_current = focus_chain.first(); 
                        }
                        if(focus_current != null) {
                            focus_current.data.focus = true;
                        }
                        return true;
                    case EventCommand.DOWN:
                        if(focus_chain == null) break;
                        if(focus_current != null){
                            focus_current.data.focus = false;
                            focus_current = focus_current.next;
                        }
                        if(focus_current == null) {
                            focus_current = focus_chain.first(); 
                        }
                        if(focus_current != null) {
                            focus_current.data.focus = true;
                        }
                        return true;
                        break;
                    case EventCommand.RIGHT:
                        if(focus_current != null) {
                            if(focus_current.data is SDLWidgetActivate){
                                GLib.debug("Active\n");
                                (focus_current.data as SDLWidgetActivate).activate();
                                return true;
                            }
                        }
                        break;
                    default:
                        break;
                }
            }
            GLib.debug("handle event: %s", this.get_name());
            if(this.Event(ev)) {
                GLib.debug("Took event: %s", this.get_name());
                return true;
            }
            return false;
        }

        public bool do_Motion(double x, double y, bool pressed, bool released)
        {

            if(this is SDLWidgetMotion)
            {
                if((this as SDLWidgetMotion).motion(x,y,pressed, released)) return true;
            }
			foreach ( var child in children) 
			{
				if(child.do_Motion(x,y,pressed, released)) {
                    return true;
                }
			}
            return false;
        }
	}
	public interface SDLWidgetDrawing : SDLWidget  
	{
		public abstract void draw_drawing(Surface screen, SDL.Rect *rect);
	}
    public interface SDLWidgetActivate : SDLWidget
    {
        public abstract bool activate();
        public virtual void leave()
        {
        }
    }

    public interface SDLWidgetMotion : SDLWidget
    {
        public abstract bool motion(double x, double y, bool pushed, bool released);
    }
}
