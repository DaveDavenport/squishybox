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
    class Label
    {
        private Main        m;
        static Font        font;
        private Surface     sf;
        private Surface     sf_shadow;
		private int16 		shadow_offset 	= 2;


        /* Inidicates if scrolling is needed, if enabled make sure screen get regular updates */
        public bool             scrolling 	= false;
        /* Scrolling variables. */
        private int             step 		= 2;
        private int             end_delay 	= 10;
        private int             offset 		= 0;

        /* Shadow color */
        private const SDL.Color c_shadow = {0,0,0};
        /* Text color */
        private const SDL.Color fg_shadow = {255,255,255};


        public int width()
        {
            return sf.w+shadow_offset;
        }

        public int height()
        {
            /* Height off text + shadow */
            return sf.h+shadow_offset;
        }

        public Label(Main m, uint16 size)
        {
            SDL.Color b = {255,255,255};
            this.m = m;
            if(font == null)
                font = new Font("test.ttf", size);
            sf = font.render_blended_utf8(" ",b); 
            sf_shadow = font.render_blended_utf8(" ", c_shadow);
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
            m.redraw();
        }

        public void render(Surface screen, int x, int y)
        {
            SDL.Rect shadow_dst_rect = {0,0,0,0};
            SDL.Rect src_rect = {0,0,0,0};
            SDL.Rect dst_rect = {0,0,0,0};


            dst_rect.x = (int16) x;
            dst_rect.y = (int16) y;

            /* Shadow has an offset of shadow_offset */
            shadow_dst_rect.x = (int16) x+shadow_offset;
            shadow_dst_rect.y = (int16) y+shadow_offset;
           
           /* Check if we need todo scrolling, if so, scroll */
            if(sf.w > (screen.w-x)) {
                /* Scroll */
                if((screen.w-x) > (sf.w-offset)  || offset < 0 ) {
                    if((end_delay--)  == 0) {
                        step = -step;
                        offset += step;
                        end_delay = 10;
                    }
                }
                else offset+=step;
                scrolling = true;
            }



            src_rect.x = (int16) (0+offset);
            src_rect.y = (int16) 0;
            src_rect.w = (int16) (screen.w-x);
            src_rect.h = (int16) (screen.h-y);

            sf_shadow.blit_surface(src_rect, screen, shadow_dst_rect);
            sf.blit_surface(src_rect, screen, dst_rect);

        }

    }
}
