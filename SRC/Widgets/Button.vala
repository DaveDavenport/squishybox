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
        public Label       label = null;
        /* Load the surfaces once */
        private Surface      sf_image = null;
        private Theme.Icons  icon = Theme.Icons.NO_ICON;
        private Theme.Element   element = Theme.Element.BUTTON_LARGE;
		private bool pressed = false;

        private double _x_align =0.5;
        public double x_align
        {
            set { 
                _x_align = value;
            }
            get
            {
                return _x_align;
            }
        }


        public void set_highlight(bool val)
        {
            focus = val; 
        }

        public void update_text(string? text)
        {
            if(label != null)
            {
                if(text != null) {
                    label.set_text(text);
                }
                else
                    label.set_text("");
            }
        }

        public Button(Main m,
                int16 x, int16 y, 
                uint16 width, uint16 height,
                string? text,
                Theme.Icons icon = Theme.Icons.NO_ICON)
        {
            this.m = m;
			
			this.x = x;
			this.y = y;
			this.w = width;
			this.h = height;

            uint16 child_offset = 5;

            if(width < 50) element = Theme.Element.BUTTON_SMALL;
            //sf = new Surface.RGB(0, width,height,32,(uint32)0xFF000000, 0x00FF0000, 0x0000FF00, 0x000000FF);

            this.icon = icon;
            if(this.icon != Theme.Icons.NO_ICON) {
                unowned Surface sf_image = this.m.theme.get_icon(this.icon);
                child_offset += (uint16)(sf_image.w+5);
            }
            if(text != null)
            {
                if(height < 30) {
                    label  = new Label(m, FontSize.SMALL,(int16)child_offset+2,(int16)2,(uint16)w-2-child_offset-4,(uint16)h-4,this);
                }else{
                    label = new Label(m, FontSize.NORMAL,(int16)child_offset+2,(int16)2,(uint16)w-2-child_offset-4,(uint16)h-4,this);
                }
                this.children.append(label);
                update_text(text);
            }
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
            src_rect.w =  (uint16).min((uint16)this.w, (uint16)(orect.x+orect.w-dest_rect.x));
            src_rect.h =  (uint16).min((uint16)this.h, (uint16)(orect.y+orect.h-dest_rect.y));
            GLib.debug("rect: %i %i %u %u", src_rect.x, src_rect.y, src_rect.w, src_rect.h);

			if(pressed)
			{
                weak Surface sf = this.m.theme.get_element(element, Theme.ElementState.PRESSED);
				sf.blit_surface(src_rect, screen, dest_rect);
            }else if (focus ) {
                weak Surface sf= this.m.theme.get_element(element, Theme.ElementState.HIGHLIGHT);
				sf.blit_surface(src_rect, screen, dest_rect);
            }else{
                weak Surface sf = this.m.theme.get_element(element, Theme.ElementState.NORMAL);
				sf.blit_surface(src_rect, screen, dest_rect);
			}

            if(this.icon != Theme.Icons.NO_ICON)
            {
                unowned Surface sf_image = this.m.theme.get_icon(this.icon);
                dest_rect.x = (int16).max((int16)this.x+5,orect.x);
                dest_rect.y = int16.max((int16)(this.y+(this.h-sf_image.h)/2), orect.y);

                src_rect.x =  (int16).max(orect.x, (int16)this.x+5)-(int16)(this.x+5);
                src_rect.y =  (int16).max(orect.y, (int16)this.y)-(int16)this.y;
                src_rect.w =  (uint16).min((uint16)sf_image.h, (uint16)(orect.x+orect.w-this.x-5));
                src_rect.h =  (uint16).min((uint16)sf_image.h, 
                        (uint16)(orect.y+orect.h-(this.y+(this.h-sf_image.h)/2)));
                sf_image.blit_surface(src_rect, screen, dest_rect);
            }
        }

        private time_t press_time = 0;
		public override bool button_press()
		{
			if(!pressed)
			{
				pressed =true;
                press_time = time_t();
				this.require_redraw = true;;
                return true;
			}
            return false;
		}
		public override void button_release(bool inside)
		{
			if(pressed) {
				SDL.Rect rect = {0,0,(uint16)this.w,(uint16)this.h};
				pressed = false;

				if(inside) {
					/* Button release */
                    if((time_t()-press_time) >= 2)
                    {
                        GLib.debug("Long click");
                        long_clicked();
                    }else{
                        GLib.debug("Short click");
                        b_clicked();
                    }
                }
				this.require_redraw = true;;
			}
		}

		public signal void b_clicked();
		public signal void long_clicked();
        public signal bool key_pressed(EventCommand key);

        public override bool Event(SDLMpc.Event ev)
        {
            if(this.focus) {
                if(ev.type == SDLMpc.EventType.KEY) {
                    return key_pressed(ev.command);
                }
            }
            return false;
        }

        public override void Tick(time_t t)
        {
            if(this.label != null) {
                if(this.label.scrolling && this.focus) {

                    this.label.require_redraw = true;
                }
            }
            if(pressed)GLib.debug("%i", (int)(t-press_time));
/*            if(pressed && (t-press_time) >=2){
                button_release(true);
            }*/
        }
        public bool activate()
        {
            b_clicked();
            return false;
        }
        public void set_icon(Theme.Icons icon)
        {
            this.icon = icon;
            this.require_redraw = true;
        }
    }
}
