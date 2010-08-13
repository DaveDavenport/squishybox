
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
    class Button
    {
        private Main        m;
        private Label       l;
        private Surface     sf;

        public void update_text(string text)
        {
            SDL.Rect rect = {0,0,(uint16)sf.w,(uint16)sf.h};
            sf.fill(rect, sf.format.map_rgba(255,255,255,170)); 
            rect.x = 1; rect.y=1; rect.w-=2;rect.h-=2;
            sf.fill(rect, sf.format.map_rgba(0,0,0,170)); 
            l.set_text(text);
            l.render(sf, (sf.w -l.width())/2, (sf.h-l.height())/2);

        }

        public Button(Main m, uint16 width, uint16 height, string text)
        {
            this.m = m;
            sf = new Surface.RGB(0, width,height,32,(uint32)0xFF000000, 0x00FF0000, 0x0000FF00, 0x000000FF);
            sf = sf.DisplayFormatAlpha();
            l = new Label(m, 10);
            update_text(text);
        }


        public void render(Surface screen, int16 x, int16 y)
        {
            SDL.Rect dest_rect = {x,y,(uint16)sf.w,(uint16) sf.h};
            sf.blit_surface(null, screen, dest_rect);
        }

    }
}
