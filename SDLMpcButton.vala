
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
        public Label       l;
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

        public void update()
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
			l.x =  (int16)(this.x+ ((sf.w -l.width())*_x_align)+1);
            l.y =  (int16)(this.y+ (sf.h-l.height())/2);
            l.w =  (uint16)(this.w-(l.x-this.x))-1;
            l.h =  (uint16)(this.h-(l.y-this.y))-1;
            this.l.require_redraw = true;;
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
            if(height < 30) {
                l = new Label(m, FontSize.SMALL,(int16)this.x+2,(int16)this.y+2,(uint16)w-4,(uint16)h-4);
            }else{
                l = new Label(m, FontSize.NORMAL,(int16)this.x+2,(int16)this.y+2,(uint16)w-4,(uint16)h-4);
            }
			this.children.append(l);
			update_text(text);
        }

        ~Button()
        {
            GLib.debug("finalize button");
        }

        public void draw_drawing(Surface screen, SDL.Rect *orect)
        {
            SDL.Rect dest_rect = {0,0,0,0};
            SDL.Rect src_rect = {0,0,0,0};
            
            dest_rect.x = (int16).max((int16)this.x,orect.x);
            dest_rect.y = int16.max((int16)this.y, orect.y);

            src_rect.x =  (int16).max(orect.x, (int16)this.x)-(int16)this.x;
            src_rect.y =  (int16).max(orect.y, (int16)this.y)-(int16)this.y;
            src_rect.w =  (uint16).min((uint16)this.w, (uint16)(orect.x+orect.w-this.x));
            src_rect.h =  (uint16).min((uint16)this.h, (uint16)(orect.y+orect.h-this.y));
            GLib.debug("rect: %i %i %u %u", src_rect.x, src_rect.y, src_rect.w, src_rect.h);
//            {(int16)this.x,(int16) this.y,(uint16)this.w,(uint16) this.h};
            sf.blit_surface(src_rect, screen, dest_rect);
        }

		public override bool button_press()
		{
			if(!pressed)
			{
				pressed =true;
				update_text(null);
				this.require_redraw = true;;
                return true;
			}
            return false;
		}
		public override void button_release(bool inside)
		{
			if(pressed) {
				SDL.Rect rect = {0,0,(uint16)this.w,(uint16)this.h};
				sf.fill(rect, sf.format.map_rgba(30,30,30,128)); 
				pressed = false;

				if(inside) {
					/* Button release */
					b_clicked();
				}
				update_text(null);
				this.require_redraw = true;;
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
