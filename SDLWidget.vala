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


        public virtual unowned string get_name()
        {
            return "Not Set";
        }


		private bool inside(int x, int y)
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


		public void draw(Surface screen)
		{
			if(this is SDLWidgetDrawing) {
				(this as SDLWidgetDrawing).draw_drawing(screen);
			}
			foreach ( var child in children) 
			{
				child.draw(screen);
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
         *
         * @returns: try to stop. 
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

        public bool do_Motion(int x, int y, bool pressed, bool released)
        {
            
			foreach ( var child in children) 
			{
				if(child.do_Motion(x,y,pressed, released)) {
                    return true;
                }
			}
            if(this is SDLWidgetMotion)
            {
                if((this as SDLWidgetMotion).motion(x,y,pressed, released)) return true;
            }
            return false;
        }
	}
	public interface SDLWidgetDrawing : SDLWidget  
	{
		public abstract void draw_drawing(Surface screen);
	}
    public interface SDLWidgetActivate : SDLWidget
    {
        public abstract bool activate();
    }

    public interface SDLWidgetMotion : SDLWidget
    {
        public abstract bool motion(int x, int y, bool pushed, bool released);
    }
}
