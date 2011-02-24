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
    class CheckBox : SDLWidget, SDLWidgetDrawing, SDLWidgetActivate
    {
        private Main        m;
        public Label       l;


		private bool pressed = false;
        private bool _active = false;
        public bool active {
            get{
                return _active;
            }
            set{
                _active = value;
                this.require_redraw = true;;
            }

        }


        public void update_text(string? text)
        {
			if(text != null) {
	            l.set_text(text);
			}
        }

        public CheckBox(Main m,int16 x, int16 y, uint16 width, uint16 height, string text)
        {
            this.m = m;
			
			this.x = x;
			this.y = y;
			this.w = width;
			this.h = height;


            //sf = new Surface.RGB(0, width,height,32,(uint32)0xFF000000, 0x00FF0000, 0x0000FF00, 0x000000FF);


            l = new Label(m, FontSize.NORMAL,(int16)42,(int16)2,(uint16)w-4-38,(uint16)h-4, this);
            this.children.append(l);
			update_text(text);
        }

        ~CheckBox()
        {
            GLib.debug("finalize button");
        }

        public void draw_drawing(Surface screen, SDL.Rect *orect)
        {
            int tx=0, ty=0;
            this.get_absolute_position(ref tx,ref ty);
            SDL.Rect dest_rect = {0,0,0,0};
            SDL.Rect src_rect = {0,0,0,0};
            
            dest_rect.x = (int16).max((int16)tx,orect.x);
            dest_rect.y = int16.max((int16)ty, orect.y);

            src_rect.x =  (int16).max(orect.x, (int16)tx)-(int16)tx;
            src_rect.y =  (int16).max(orect.y, (int16)ty)-(int16)ty;
            src_rect.w =  (uint16).min((uint16)38, (uint16)(orect.x+orect.w-tx));
            src_rect.h =  (uint16).min((uint16)this.h, (uint16)(orect.y+orect.h-ty));

            if(src_rect.x >= tx+38) return;
            if(active)
            {
                weak Surface sf;
                if(this.focus) {
                    sf = this.m.theme.get_element(Theme.Element.CHECK_BOX_ACTIVE, Theme.ElementState.HIGHLIGHT);
                }else{
                    sf = this.m.theme.get_element(Theme.Element.CHECK_BOX_ACTIVE, Theme.ElementState.NORMAL);
                }

                sf.blit_surface(src_rect, screen, dest_rect);
            }else{
                weak Surface sf;
                if(this.focus) {
                    sf = this.m.theme.get_element(Theme.Element.CHECK_BOX, Theme.ElementState.HIGHLIGHT);
                }else{
                    sf = this.m.theme.get_element(Theme.Element.CHECK_BOX, Theme.ElementState.NORMAL);
                }
                sf.blit_surface(src_rect, screen, dest_rect);
            }
        }

		public override bool button_press()
		{
			if(!pressed)
			{
				pressed =true;
                return true;
			}
            return false;
		}
		public override void button_release(bool inside)
		{
			if(pressed) {
				pressed = false;

				if(inside) {
					/* CheckBox release */
                    active = !active;
					toggled(active);
				}
			}
		}

		public signal void toggled(bool active);

        public bool activate()
        {
            active = !active;
            toggled(active);
            return true;
        }
    }
}
