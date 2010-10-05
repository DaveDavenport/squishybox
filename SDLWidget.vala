using SDL;

namespace SDLMpc
{
	public class SDLWidget : GLib.Object 
	{
		public int x;
		public int y;
		public int w;
		public int h;

		public List<SDLWidget> children;

		public bool require_redraw = true;

        public virtual unowned string get_name()
        {
            return "Not Set";
        }


		public bool inside(int x, int y)
		{
			if(x > this.x && (x) < (this.x+this.w)) 
			{
				if(y > this.y && (y) < (this.y+this.h)) 
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
				if(child.clicked(x, y, press_state)) return true;
			}
			if(this.inside(x,y))
			{
				if(press_state) {
					this.button_press();
				}
				else
					this.button_release(true);
				return press_state;
			}
			else {
				if(!press_state) {
					this.button_release(false);
				}
			}
			return false;
		}
		
		public virtual void button_press()
		{
			stdout.printf("button_press()\n");

		}
		public virtual void button_release(bool inside)
		{
			stdout.printf("button_release()\n");
		}

		public virtual bool check_redraw()
		{
			if(this.require_redraw) return true;
			foreach ( var child in children) 
			{
				if(child.check_redraw()) return true;
			}
			return false;
		}

		public virtual List<SDL.Rect ?> get_redraw_rect(owned List<SDL.Rect?> rr,SDL.Rect g)
		{
			g.x += (int16)x;
			g.y += (int16)y;
			foreach ( var child in children) 
			{
				rr = child.get_redraw_rect((owned)rr,g);
			}  
			g.x -= (int16)x;
			g.y -= (int16)y;
			if(this.require_redraw) {
				if((w) > 0 && (h) > 0)
				{
					GLib.stdout.printf("ll %d %d %d %d\n", this.x,this.y, this.w, this.h);

					SDL.Rect r = {0,0,0,0};
					r.x =(int16) this.x; r.y =(int16) this.y; r.w =(uint16)this.w; r.h =(uint16) this.h;
					rr.append(r);
				}
			}     

        	return (owned)rr;
		}
		public bool intersect(SDL.Rect r)
		{

			GLib.stdout.printf("%s: %d-%d %d-%d -> %d-%d %d-%d\n",
				this.get_name(),
				r.x, r.x+r.w, r.y, r.y+r.h,
				this.x, this.x+this.w, this.y, this.y+this.h);
			if(((this.x >= r.x && r.x <= (this.x+this.w)) || ((this.x >= r.x+r.w) && (r.x+r.w <= (this.x+this.w))))
					&&
					((this.y >= r.y && r.y <= (this.y+this.h)) || ((this.y >= r.y+r.h) && (r.y+r.h <= (this.y+this.h))))){
					GLib.stdout.printf("intersect; %s\n", this.get_name());
                 return true;
				}
			if(((r.x >= this.x && this.x <= (r.x+r.w)) || ((r.x >= this.x+this.w) && (this.x+this.w <= (r.x+r.w))))
					&&
					((r.y >= this.y && this.y <= (r.y+r.h)) || ((r.y >= this.y+this.h) && (this.y+this.h <= (r.y+r.h))))){
					GLib.stdout.printf("intersect; %s\n", this.get_name());
                 return true;
			}
			return false;
		}
		public void draw(Surface screen, SDL.Rect *rect)
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
    }

    public interface SDLWidgetMotion : SDLWidget
    {
        public abstract bool motion(double x, double y, bool pushed, bool released);
    }
}
