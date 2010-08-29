
using SDLMpc;
using SDL;
using SDLTTF;

namespace SDLMpc
{
    /**
     * This Widget will display a text, scroll if needed.
     * Ment for single line.
     *
     */
    class Button : SDLWidget, SDLWidgetDrawing
    {
        private Main        m;
        private Label       l;
        private Surface     sf;
		private bool pressed = false;
        private bool highlight = false;

        private double _x_align =0.5;
        public double x_align
        {
            set { 
                _x_align = value;
                update();
            }
            get
            {
                return _x_align;
            }
        }


        public void set_highlight(bool val)
        {
            highlight = val;
            update();
        }

        private void update()
        {
            SDL.Rect rect = {0,0,(uint16)sf.w,(uint16)sf.h};

            if(highlight){ 
    			sf.fill(rect, sf.format.map_rgba(0,255,255,170)); 
            }else{
    			sf.fill(rect, sf.format.map_rgba(255,255,255,170)); 
            }
            rect.x = 1; rect.y=1; rect.w-=2;rect.h-=2;
			if(pressed) {
				sf.fill(rect, sf.format.map_rgba(0,255,255,170)); 
			}else {
				sf.fill(rect, sf.format.map_rgba(0,0,0,170)); 
			}
			l.render(sf, (int)((sf.w -l.width())*_x_align)+1 , (sf.h-l.height())/2);
            m.redraw();
        }
        public void update_text(string? text)
        {
			if(text != null) {
	            l.set_text(text);
			}
            update();
        }

        public Button(Main m,int16 x, int16 y, uint16 width, uint16 height, string text)
        {
            this.m = m;
			
			this.x = x;
			this.y = y;
			this.w = width;
			this.h = height;


            sf = new Surface.RGB(0, width,height,32,(uint32)0xFF000000, 0x00FF0000, 0x0000FF00, 0x000000FF);
            sf = sf.DisplayFormatAlpha();
            l = new Label(m, height-10);
            update_text(text);
        }

        ~Button()
        {
            GLib.debug("finalize button");
        }

        public void draw_drawing(Surface screen)
        {
            SDL.Rect dest_rect = {(int16)this.x,(int16) this.y,(uint16)this.w,(uint16) this.h};
            sf.blit_surface(null, screen, dest_rect);
        }

		public override void button_press()
		{
			if(!pressed)
			{
				SDL.Rect rect = {0,0,(uint16)this.w,(uint16)this.h};
				GLib.debug("PlayerControl bg press");
				pressed =true;
				update_text(null);
				m.redraw();
			}
		}
		public override void button_release(bool inside)
		{
			if(pressed) {
				SDL.Rect rect = {0,0,(uint16)this.w,(uint16)this.h};
				GLib.debug("PlayerControl bg release");
				sf.fill(rect, sf.format.map_rgba(30,30,30,128)); 
				pressed = false;

				if(inside) {
					/* Button release */
					b_clicked();
				}
				update_text(null);
				m.redraw();
			}
		}

		public signal void b_clicked();

        public override void Tick(time_t t)
        {
            if(l.scrolling){
                update();
            }
        }
    }
}
