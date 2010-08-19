using SDL;
using SDLTTF;
using SDLImage;
using MPD;
using Posix;
using SDLMpc;

class BackgroundDrawer : SDLWidget, SDLWidgetDrawing
{
    private Surface sf;
    private weak Main m;


    public int period_time {
        set;
        get;
        default=30;
    }

    /**
     * List of backgrounds
     */
    private List<string>  backgrounds       = null;
    private weak List<string> current_bg    = null;
    private string directory = "Wallpapers/";




    public BackgroundDrawer(Main m,int x, int y, int w, int h, int bpp)
    {
        this.m = m;

        this.x = x;
        this.y = y;
        this.w = w;
        this.h = h;

        /* */
        try{
            GLib.Dir a = GLib.Dir.open(directory);
            for(var file = a.read_name(); file != null; file = a.read_name())
            {
                backgrounds.append(file); 
            }
        }catch (GLib.Error e)
        {

        }

        if(backgrounds.length() > 0) {
            current_bg = backgrounds.first();
            sf = SDLImage.load(directory+current_bg.data);
        }else {
            /* Failsafe */
            sf = SDLImage.load("test.png");
        }
        sf = sf.DisplayFormat();
    }

    /* Return the surface it needs to draw */
    public void draw_drawing(Surface screen)
    {
        SDL.Rect rect = {0,0,(uint16)sf.w,(uint16)sf.h};
        sf.blit_surface(null, screen, rect);
    }


    private time_t last_time = time_t(); 
    public override void Tick(time_t now)
    {
        if(current_bg == null) return;
        if((now - last_time)  > period_time){
            if(current_bg.next != null) {
                current_bg = current_bg.next;
            }else{
                current_bg = current_bg.first();
            }
            GLib.debug("Change background to: %s\n", current_bg.data);
            sf = SDLImage.load(directory+current_bg.data);
            sf = sf.DisplayFormat();
            m.redraw();
            last_time = now; 
        }
    }
}
