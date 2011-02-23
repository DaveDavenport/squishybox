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
    class Label : SDLWidget, SDLWidgetDrawing
    {
        private SDLMpc.Main        m;
        private weak Font        font;
        private Surface     sf;
        private Surface     sf_shadow;
		private int16 		shadow_offset 	= 2;
        public bool            do_scrolling = true;


        /* Inidicates if scrolling is needed, if enabled make sure screen get regular updates */
        public bool             scrolling 	= false;
        /* Scrolling variables. */
        private int             step 		= 2;
        private int             end_delay 	= 10;
        private int             offset 		= 0;
        public bool            center      = false;

        /* Shadow color */
        private const SDL.Color c_shadow = {0,0,0};
        /* Text color */
        private const SDL.Color fg_shadow = {255,255,255};

        /**
         * Get the Width off the label 
         */
        public int width()
        {
            return sf.w+shadow_offset;
        }

        /**
         * Get the height off the label 
         */
        public int height()
        {
            /* Height off text + shadow */
            return sf.h+shadow_offset;
        }

        public Label(Main m, FontSize size, int16 x, int16 y, uint16 width, uint16 height,SDLWidget? parent = null )
        {
            SDL.Color b = {255,255,255};
            this.parent = parent;
            this.m = m;
			this.x = x;
			this.y = y;
			this.w = width;
			this.h = height;
            font = this.m.fonts[size];
            sf = font.render_blended_utf8(" ",b); 
            sf_shadow = font.render_blended_utf8(" ", c_shadow);
			this.require_redraw = true;
        }

        public void set_text(string? a)
        {
            SDL.Color b = {255,255,255};
            if(a != null && a.length > 0) {
                sf = font.render_blended_utf8(a,b); 
                sf_shadow = font.render_blended_utf8(a, c_shadow);
            }else{
                sf = font.render_blended_utf8(" ",b); 
                sf_shadow = font.render_blended_utf8(" ", c_shadow);
            }
            scrolling = false;
            /* Reset everything */
            offset = 0;
            step = step.abs();
            end_delay = 10;
			this.require_redraw = true;
        }

        public void draw_drawing(Surface screen, SDL.Rect *orect)
        {
            int tx=0, ty=0;
            this.get_absolute_position(ref tx, ref ty);
            if(this.parent != null) {
                stdout.printf("tx: %i ty: %i\n" , tx,ty);
            }

            SDL.Rect shadow_dst_rect = {0,0,0,0};
            SDL.Rect src_rect = {0,0,0,0};
            SDL.Rect dst_rect = {0,0,0,0};


            dst_rect.x = (int16).max((int16)tx,orect.x);
            dst_rect.y = int16.max((int16)ty, orect.y);

            /* Shadow has an offset of shadow_offset */
            shadow_dst_rect.x = (int16).max((int16)(tx), orect.x)+shadow_offset;
            shadow_dst_rect.y = (int16).max((int16)(ty), orect.y)+shadow_offset;

           
           /* Check if we need todo scrolling, if so, scroll */
            if(this.do_scrolling && sf.w > (screen.w-tx)) {
                /* Scroll */
                if((screen.w-tx) > (sf.w-offset)  || offset < 0 ) {
                    if((end_delay--)  == 0) {
                        step = -step;
                        offset += step;
                        end_delay = 10;
                    }
                }
                else offset+=step;
                scrolling = true;
            }
            /* hack for centering */
            if(!scrolling && center)
            {
                offset = (int16)(-(this.w-sf.w)/2);
            }

            src_rect.x =  (int16).max(orect.x, (int16)tx)-(int16)(tx)+(int16)offset;
            src_rect.y =  (int16).max(orect.y, (int16)ty)-(int16)ty;

            src_rect.w = uint16.min((uint16)w, (uint16)(orect.x+orect.w-tx))-shadow_offset;
            src_rect.h = uint16.min((uint16)h, (uint16)(orect.y+orect.h-ty))-shadow_offset;
            sf_shadow.blit_surface(src_rect, screen, shadow_dst_rect);
            //src_rect.h = (int16) (h);
            src_rect.w+=shadow_offset;
            src_rect.h+=shadow_offset;

            sf.blit_surface(src_rect, screen, dst_rect);
        }
    }
}
