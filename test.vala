using SDL;
using SDLTTF;
using SDLImage;
using MPD;



class Main : GLib.Object
{
    public MPD.Interaction MI = new MPD.Interaction();

    private unowned Screen screen; 
    private GLib.MainLoop loop = new GLib.MainLoop();

    private BasicDrawer bg;
    private BasicDrawer frame;
    private BasicDrawer np;

    private GLib.Timer tt = new GLib.Timer();

    private uint32 t = 0;
    private int changed = 1;


    public void redraw()
    {
        changed = 1;
    }

    public void run()
    {
        loop.run();
    }


    /* Constructor */
    public Main()
    {
        /* Initialize SDL */
        GLib.debug("SDL.init");
        SDL.init(SDL.InitFlag.VIDEO);
        GLib.debug("SDLTTF.init");
        SDLTTF.init();

        SDL.Cursor.show(0);

        SDL.Key.enable_unicode(1);
        SDL.Key.set_repeat(100,100);
        GLib.debug("Set Video mode");
        screen = SDL.Screen.set_video_mode(480,272, 32,SDL.SurfaceFlag.DOUBLEBUF|SDL.SurfaceFlag.HWSURFACE/*|SDL.SurfaceFlag.FULLSCREEN*/);
        //screen.set_alpha(0,Opacity.OPAQUE);

        if(screen == null) {
            GLib.error("failed to create screen\n");

        }

        /* Create background drawer */
        GLib.debug("Create background draw object");
        bg = new BackgroundDrawer(this,480, 272,32);

        frame = new DrawFrame (this,480, 272,32);
        np = new NowPlaying (this,480, 272,32);


        GLib.debug("Add timeout");
        tt.start();
        GLib.Timeout.add(1000/10, main_draw);

        GLib.debug("Connect to mpd");
        MI.mpd_connect();
    }

    ~Main()
    {

        GLib.debug("Running SDL.quit()");
        SDL.quit();
    }
    private bool main_draw()
    {
        t++;
        SDL.Event event = SDL.Event();
        /* Clear the screen */

        SDL.Rect rect = {0,0,0,0};
        SDL.Color b = {255,255,255};


        np.Tick();

        if(changed > 0){
            bg.draw(screen);
            frame.draw(screen);

            np.draw(screen);
            changed = 0;
            screen.flip();
        }
        while(SDL.Event.poll(event)>0){
            switch(event.type)
            {
                case SDL.EventType.QUIT:
                case SDL.EventType.KEYUP:
                    loop.quit();
                    np = null;
                    MI = null;
                    return false;
                    break;
                default:
                    break;

            }
        }
        if(t == 100)
        {
            double elapsed = tt.elapsed();
            stdout.printf("fps: %f\n", 1.0/(elapsed/100.0));
            tt.reset();    
            tt.start();
            t = 0;
        }
        return true;
    }
}

/**
 * @params argv the command line arguments
 *
 * The entry point of the program  
 */

static int main (string[] argv)
{
    GLib.debug("Starting main");
    /* Create mainloop */
    Main m = new Main();
    /* Run */
    GLib.debug("Run main loop");
    m.run();
    SDL.quit();

    return 0;
}


public interface BasicDrawer : GLib.Object
{
    public abstract int draw(Surface screen);

    public virtual void Tick()
    {

    }
}

/** 
 * Background object.
 */
class BackgroundDrawer : GLib.Object, BasicDrawer
{
    private Surface sf;
    private weak Main m;

    public BackgroundDrawer(Main m,int w, int h, int bpp)
    {
        this.m = m;
        sf = SDLImage.load("test.png");
        sf = sf.DisplayFormat();
    }

    /* Return the surface it needs to draw */
    public int draw(Surface screen)
    {
        SDL.Rect rect = {0,0,(uint16)sf.w,(uint16)sf.h};
        sf.blit_surface(null, screen, rect);
        return 0;
    }
}

class DrawFrame : GLib.Object, BasicDrawer
{
    private Surface sf;
    private weak Main m;
    public DrawFrame(Main m,int w, int h, int bpp)
    {
        this.m = m;
        sf = new Surface.RGB(0, w,30,bpp,(uint32)0xFF000000, 0x00FF0000, 0x0000FF00, 0x000000FF);
        sf = sf.DisplayFormatAlpha();
        SDL.Rect rect = {0,0,(uint16)sf.w,(uint16)sf.h};

        rect.h = 30;
        sf.fill(rect, sf.format.map_rgba(128,0,0,128)); 
        this.update_frame();
    }
    public int draw(Surface screen)
    {
        SDL.Rect rect = {0,0,(uint16)sf.w,(uint16)30};
        rect.y = (int16)screen.h-30;
        sf.blit_surface(null, screen, rect);
        return 0;
    }

    /* Private */
    private void update_frame()
    {

    }
}



class NowPlaying : GLib.Object, BasicDrawer
{
    private weak Main m;

    private SDLMpc.Label title_label;
    private SDLMpc.Label artist_label;
    private SDLMpc.Label album_label;

    private int current_song_id = -1;


    public NowPlaying(Main m,int w, int h, int bpp)
    {
        this.m = m;

        title_label = new SDLMpc.Label(this.m,40);
        artist_label = new SDLMpc.Label(this.m,30);
        album_label = new SDLMpc.Label(this.m,20);


        m.MI.player_get_current_song(got_current_song);
        m.MI.player_status_changed.connect((source, status) => {
                if((status.state == MPD.Status.State.PLAY ||
                    status.state == MPD.Status.State.PAUSE) 
                    )
                {
                    /* Update the text */
                    if(status.song_id != current_song_id) {
                        m.MI.player_get_current_song(got_current_song);
                        current_song_id = status.song_id;
                    }
                }else{
                    got_current_song(null);
                    current_song_id = -1;
                }
        });


    }
    public int draw(Surface screen)
    {
        int16 offset = 2;
        SDL.Rect rect = {0,0,0,0};

        rect.y = 5;
        title_label.render(screen, 5, rect.y);

        rect.y += (int16)title_label.height();
        artist_label.render(screen, 5, rect.y);

        rect.y += (int16)artist_label.height();
        album_label.render(screen, 5, rect.y);

        return 0;
    }

    private void got_current_song(MPD.Song? song)
    {
        SDL.Color b = {255,255,255};
        SDL.Color d = {0,0,0};
        GLib.debug("Got current song");

        if(song != null)
        {
            string a;
            if((a = song.get_tag(MPD.Tag.Type.TITLE,0)) == null) {
                a="";
                /* TODO: Try filename */
            }
            title_label.set_text(a);

            if((a = song.get_tag(MPD.Tag.Type.ARTIST,0)) == null) {
                a = "";
            }
            artist_label.set_text(a);

            if((a = song.get_tag(MPD.Tag.Type.ALBUM,0)) == null) {
                a = "";
            }
            album_label.set_text(a);
        }else {
            title_label.set_text("Music Player Daemon");

            artist_label.set_text(null);
            album_label.set_text(null);
        }
        m.redraw();
    }
    /* Private */
    private void update_frame()
    {

    }

    public void Tick()
    {
        if(title_label.scrolling ||
            artist_label.scrolling ||
            album_label.scrolling ) {
            m.redraw();
            return;
        }
    }
}

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
        private Font        font;
        private Font        font_shadow;
        private Surface     sf;
        private Surface     sf_shadow;


        /* Inidicates if scrolling is needed, if enabled make sure screen get regular updates */
        public bool             scrolling = false;
        /* Scrolling variables. */
        private int             step = 2;
        private int             end_delay = 10;
        private int             offset = 0;

        /* Shadow color */
        private const SDL.Color c_shadow = {0,0,0};
        /* Text color */
        private const SDL.Color fg_shadow = {255,255,255};


        public int width()
        {
            return sf.w;
        }

        public int height()
        {
            /* Height off text + shadow */
            return sf.h+2;
        }

        public Label(Main m, uint16 size)
        {
            SDL.Color b = {255,255,255};
            this.m = m;
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

        private bool queue_redraw()
        {
            m.redraw();
            return false;
        }

        public void render(Surface screen, int x, int y)
        {
            SDL.Rect shadow_dst_rect = {0,0,0,0};
            SDL.Rect src_rect = {0,0,0,0};
            SDL.Rect dst_rect = {0,0,0,0};


            dst_rect.x = (int16) x;
            dst_rect.y = (int16) y;

            /* Shadow has an offset of 2 */
            shadow_dst_rect.x = (int16) x+2;
            shadow_dst_rect.y = (int16) y+2;
           
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
