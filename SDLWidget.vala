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

		public bool require_redraw = false;

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

		}
		public virtual void button_release(bool inside)
		{

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

		public virtual void get_redraw_rect(SDL.Rect *rect)
		{
			if(x > 0) {
             	stdout.printf("w: %d %d %d %d\n ", x,y,w,h);
			}
			if(this.require_redraw) {
            	rect.x = (int16)((x > 0)? ((rect.x >x)?rect.x:x):rect.x);
            	rect.y = (int16)((y > 0)? ((rect.y >y)?rect.y:y):rect.y);
            	rect.w = (int16)((w > 0)? ((rect.w >w)?rect.w:w):rect.w);
            	rect.h = (int16)((h > 0)? ((rect.h >h)?rect.h:h):rect.h);
			}     
			foreach ( var child in children) 
			{
				child.get_redraw_rect(rect);
			}  


		}
		public bool intersect(SDL.Rect r)
		{
			if(((x >= r.x && x <= (r.x+r.w)) || (x+w >= r.x && x+w  <= (r.x+r.w))) &&
						((y >= r.y && y <= (r.y+r.h)) || (y+h >= r.y && y+h  <= (r.y+r.h))))
			{
				return true;
			}
			return false;
		}
		public void draw(Surface screen, SDL.Rect *rect)
		{
			if(this is SDLWidgetDrawing) {
				if(this.intersect(*rect)){
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
