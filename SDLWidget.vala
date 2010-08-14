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

	}
	public interface SDLWidgetDrawing : SDLWidget  
	{
		public abstract void draw_drawing(Surface screen);

		public virtual void Tick()
		{

		}
	}
}
