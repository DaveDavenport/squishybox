using SDL;
using SDLTTF;
using SDLImage;
using MPD;



class Main : GLib.Object
{
    public MPD.Interaction MI = new MPD.Interaction();

    private unowned Screen screen; 
    private Font normal_font;
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
//        GLib.debug("SDLIMAGE.init");
//        SDLImage.init(SDLImage.InitFlags.PNG);
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

        GLib.debug("Load font");
        normal_font = new Font("test.ttf", 40);
        if(normal_font == null) {
            GLib.error("failed to load font\n");
        }

        /* Create background drawer */
        GLib.debug("Create background draw object");
        bg = new BackgroundDrawer(this,480, 272,32);

        frame = new DrawFrame (this,480, 272,32);
        np = new NowPlaying (this,480, 272,32);


        GLib.debug("Add timeout");
        tt.start();
        GLib.Timeout.add(1000/24, main_draw);

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

        if(changed > 0){
            bg.draw(screen);
            frame.draw(screen);

/*            SDL.Color c = {0,0,0};
            var fs = normal_font.render_blended_utf8("Music Player Daemon",b); 
            fs = fs.Alpha();


            rect.x = (int16)( (screen.w-fs.w)/2);
            rect.y = 0;
            rect.w= 0;//(uint16)fs.w;
            rect.h= 0;//(uint16)fs.h;
            fs.blit_surface(null, screen, rect);
            */
            np.draw(screen);
            changed = 0;
            screen.flip();
        }
        while(SDL.Event.poll(event)>0){
            switch(event.type)
            {
                case SDL.EventType.QUIT:
//                case SDL.EventType.KEYDOWN:
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
}

/** 
 * Background object.
 */
class BackgroundDrawer : GLib.Object, BasicDrawer
{
    private Surface sf;
    private weak Main m;

    private void update_background()
    {
        SDL.Rect rect = {0,0,(uint16)sf.w,(uint16)sf.h};
        /* Create background */
//        sf.fill(rect, sf.format.map_rgb(32,32,64)); 
    }

    public BackgroundDrawer(Main m,int w, int h, int bpp)
    {
        this.m = m;
        sf = SDLImage.load("test.png");//new Surface.RGB(SurfaceFlag.SWSURFACE|SurfaceFlag.SRCALPHA, w,h,bpp,0,0,0,0);
        sf = sf.Alpha();
        this.update_background();
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
        sf = new Surface.RGB(0, w,h,bpp,(uint32)0xFF000000, 0x00FF0000, 0x0000FF00, 0x000000FF);
        sf = sf.Alpha();
        SDL.Rect rect = {0,0,(uint16)sf.w,(uint16)sf.h};

        sf.fill(rect, sf.format.map_rgba(0,0,0,0)); 
/*
        rect.h = 60;
        sf.fill(rect, sf.format.map_rgba(128,0,0,128)); 
*/

        rect.y = (int16)sf.h-30;
        rect.h = 30;
        sf.fill(rect, sf.format.map_rgba(128,0,0,128)); 
        this.update_frame();
    }
    public int draw(Surface screen)
    {
        SDL.Rect rect = {0,0,(uint16)sf.w,(uint16)sf.h};
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
    private Font title_font = new Font("test.ttf", 40);
    private Font artist_font = new Font("test.ttf", 30);
    private Font album_font = new Font("test.ttf", 20);
    private Surface title_sf;
    private Surface artist_sf;
    private Surface album_sf;
    private Surface title_sfb;
    private Surface artist_sfb;
    private Surface album_sfb;

    public NowPlaying(Main m,int w, int h, int bpp)
    {
        this.m = m;


        m.MI.player_get_current_song(got_current_song);
        m.MI.player_status_changed.connect((source, status) => {
                /* Update the text */
                m.MI.player_get_current_song(got_current_song);
        });


        SDL.Color b = {255,255,255};
        SDL.Color d = {0,0,0};
//        title_font.set_style(FontStyle.BOLD);
        title_sf = title_font.render_blended_utf8("Music Player Daemon",b); 
        title_sfb = title_font.render_blended_utf8("Music Player Daemon",d); 

  //      artist_font.set_style(FontStyle.BOLD);
        artist_sf = artist_font.render_blended_utf8(" ",b); 
        artist_sfb = artist_font.render_blended_utf8(" ",d); 

        album_sf = album_font.render_blended_utf8(" ",b); 
        album_sfb = album_font.render_blended_utf8(" ",d); 
    }
    public int draw(Surface screen)
    {
        int16 offset = 2;
        SDL.Rect rect = {0,0,0,0};
        rect.x = 5+offset;
        rect.y += offset;
        title_sfb.blit_surface(null, screen, rect);
        rect.y -=offset;
        rect.x = 5;
        title_sf.blit_surface(null, screen, rect);

        rect.y += (int16)title_sf.h;
        rect.x = 5+offset;
        rect.y += offset;
        artist_sfb.blit_surface(null, screen, rect);
        rect.x = 5;
        rect.y -= offset;
        artist_sf.blit_surface(null, screen, rect);


        rect.y += (int16)artist_sf.h;
        rect.x = 5+offset;
        rect.y += offset;
        album_sfb.blit_surface(null, screen, rect);
        rect.x = 5;
        rect.y -= 1;
        album_sf.blit_surface(null, screen, rect);
        return 0;
    }

    private void got_current_song(MPD.Song? song)
    {
        SDL.Color b = {255,255,255};
        SDL.Color d = {0,0,0};
        GLib.debug("Got current song");
        string a;
        if((a = song.get_tag(MPD.Tag.Type.TITLE,0)) != null) {
            title_sf = title_font.render_blended_utf8(a,b); 
            title_sfb = title_font.render_blended_utf8(a,d); 
        }
        if((a = song.get_tag(MPD.Tag.Type.ARTIST,0)) != null) {
            artist_sf = artist_font.render_blended_utf8(a,b); 
            artist_sfb = artist_font.render_blended_utf8(a,d); 
        }
        if((a = song.get_tag(MPD.Tag.Type.ALBUM,0)) != null) {
            album_sf = album_font.render_blended_utf8(a,b); 
            album_sfb = album_font.render_blended_utf8(a,d); 
        }
        m.redraw();
    }
    /* Private */
    private void update_frame()
    {

    }
}
