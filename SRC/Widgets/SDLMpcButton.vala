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
    class Button : SDLWidget, SDLWidgetDrawing, SDLWidgetActivate
    {
        private Main        m;
        public Label       label;
        /* Load the surfaces once */
        private static Surface     sf = null;
        private static Surface     sf_pressed = null;
        private static Surface     sf_highlight = null;
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
        }
        public void update_text(string? text)
        {
			if(text != null) {
	            label.set_text(text);
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


            //sf = new Surface.RGB(0, width,height,32,(uint32)0xFF000000, 0x00FF0000, 0x0000FF00, 0x000000FF);

            if(sf == null)
            {
			    sf = SDLImage.load("Data/button.png");
			    sf = sf.DisplayFormatAlpha();
            }
            if(sf_pressed == null)
            {
                sf_pressed = SDLImage.load("Data/button_pressed.png");
			    sf_pressed = sf_pressed.DisplayFormatAlpha();
            }
            if(sf_highlight == null)
            {
                sf_highlight = SDLImage.load("Data/button_highlight.png");
			    sf_highlight = sf_highlight.DisplayFormatAlpha();
            }
            if(height < 30) {
                label  = new Label(m, FontSize.SMALL,(int16)2,(int16)2,(uint16)w-4,(uint16)h-4,this);
            }else{
                label = new Label(m, FontSize.NORMAL,(int16)2,(int16)2,(uint16)w-4,(uint16)h-4,this);
            }
			this.children.append(label);
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
			if(pressed)
			{
				sf_pressed.blit_surface(src_rect, screen, dest_rect);
            }else if (highlight || focus ) {
				sf_highlight.blit_surface(src_rect, screen, dest_rect);
            }else{
				sf.blit_surface(src_rect, screen, dest_rect);
			}
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
				//sf.fill(rect, sf.format.map_rgba(30,30,30,128)); 
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
        public signal bool key_pressed(EventCommand key);

        public override bool Event(SDLMpc.Event ev)
        {
            if(this.focus || this.highlight) {
                if(ev.type == SDLMpc.EventType.KEY) {
                    return key_pressed(ev.command);
                }
            }
            return false;
        }

        public override void Tick(time_t t)
        {
            if(this.label.scrolling) {
                
                this.label.require_redraw = true;
            }
        }
        public bool activate()
        {
            b_clicked();
            return false;
        }
    }
}
