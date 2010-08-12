using SDL;
using SDLTTF;
using SDLImage;
using MPD;
using Posix;



class Main : GLib.Object
{
    public MPD.Interaction MI = new MPD.Interaction();

    private unowned Screen screen; 
    private GLib.MainLoop loop = new GLib.MainLoop();

    private BasicDrawer bg;
    private BasicDrawer frame;
    private BasicDrawer np;
    private BasicDrawer sp;
    private BasicDrawer ss;
    private DisplayControl display_control = new DisplayControl();


    private bool _screensaver = false;
    public bool screensaver { 
            get { 
                return _screensaver;
            }
            set {
                GLib.debug("Standby");
                _screensaver = value;
                redraw();
            }
    }


    private uint32 t = 0;
    private int changed = 1;
    private bool user_near = false;

    private SDLMpc.Event pev = null;

    private Queue<SDLMpc.Event> events= new Queue<SDLMpc.Event>();

    public void push_event(owned SDLMpc.Event event)
    {
        events.push_tail((owned)event);
    }


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

        if(screen == null) {
            GLib.error("failed to create screen\n");

        }

        /* Create background drawer */
        GLib.debug("Create background draw object");
        bg = new BackgroundDrawer(this,480, 272,32);

        frame = new DrawFrame   (this,480, 272,32);
        np = new NowPlaying     (this,480, 272,32);
        sp = new SongProgress   (this,480, 272,32);

        ss = new ScreenSaver (this,480, 272,32);


        GLib.debug("Add timeout");
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


        bg.Tick();
        np.Tick();
        sp.Tick();

        if(changed > 0){
            if(screensaver) {
                ss.draw(screen);
                screen.flip();
            }else{
                bg.draw(screen);
                if(user_near)
                    frame.draw(screen);

                np.draw(screen);
                sp.draw(screen);
                changed = 0;
                screen.flip();
            }
        }
        
        SDLMpc.Event ev;
        while((ev= events.pop_head()) != null)
        {
            if(ev.type == SDLMpc.EventType.INVALID) 
                continue;
            /*remove duplicate events.. */
            if(pev != null) {
                uint32 diff = (uint32)((ev.time.tv_sec*1000+ev.time.tv_usec/1000)-(pev.time.tv_sec*1000+pev.time.tv_usec/1000));
                GLib.debug("time diff: %u", diff);
                if(diff > 200) pev = null;

                if(pev != null && pev.type == ev.type && ev.code == pev.code && pev.value == ev.value){
                    continue;
                }

            }
            /* Handle event */
            if(ev.type == SDLMpc.EventType.IR_NEARNESS) {
                GLib.debug("User is near: %i", (int)this.user_near);
                this.user_near = (ev.value == 0)?false:true;
                redraw();
            }
            /* Handle incoming remote events */
            if(ev.type == SDLMpc.EventType.IR_KEY) {
                switch(ev.value) {
                    case 1988698335:
                        MI.player_toggle_pause(); 
                        break;
                    case 1988730975:
                        MI.player_next();
                        break;
                    case 1988739135:
                        MI.player_previous();
                        break;
                    case 1988694255:
                        MI.player_play();
                        break;
                    case 1988706495:
                        GLib.debug("Set Display\n"); 
                        display_control.setEnabled(!display_control.getEnabled());
                        if(!display_control.getEnabled())
                        {
                            screensaver = true; 
                            MI.player_stop();
                        }else{
                            screensaver = false; 
                        }
                        break;
                    case 1988737095:
                        {
                            var b = display_control.getBrightness();
                            if(b == 255)
                                b = 55;
                            else 
                                b+=50;
                            display_control.setBrightness(b);
                        }
                        break;
                    default:
                        break;
                }
                pev = (owned)ev;
            }


        }
        while(SDL.Event.poll(event)>0){
            switch(event.type)
            {
                case SDL.EventType.QUIT:
                        loop.quit();
                        np = null;
                        MI = null;
                        return false;
                case SDL.EventType.KEYUP:
                    if(event.key.keysym.sym == KeySymbol.q)
                    {
                        loop.quit();
                        np = null;
                        MI = null;
                        return false;
                    }
                    else if (event.key.keysym.sym == KeySymbol.s)
                    {
                        GLib.debug("Set Screensaver: %i", (int)screensaver);
                        screensaver = !screensaver;
                    }
                    break;
                 default:
                    break;

            }
        }
        return true;
    }
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

class ScreenSaver : GLib.Object, BasicDrawer
{
    private Surface sf;
    private weak Main m;
    public ScreenSaver(Main m,int w, int h, int bpp)
    {
        this.m = m;
        sf = new Surface.RGB(0, w,h,bpp,(uint32)0xFF000000, 0x00FF0000, 0x0000FF00, 0x000000FF);
        sf = sf.DisplayFormat();
        SDL.Rect rect = {0,0,(uint16)sf.w,(uint16)sf.h};

        sf.fill(rect, sf.format.map_rgb(0,0,0)); 
    }
    public int draw(Surface screen)
    {
        SDL.Rect rect = {0,0,(uint16)screen.w,(uint16)screen.h};
        sf.blit_surface(null, screen, rect);
        return 0;
    }
}




class BackgroundDrawer : GLib.Object, BasicDrawer
{
    private Surface sf;
    private Surface next = null;
    private weak Main m;


    private List<string>  backgrounds       = null;
    private weak List<string> current_bg    = null;
    private string directory = "Wallpapers/";

    public BackgroundDrawer(Main m,int w, int h, int bpp)
    {
        this.m = m;

        /* */
        GLib.Dir a = GLib.Dir.open(directory);
        for(var file = a.read_name(); file != null; file = a.read_name())
        {
            backgrounds.append(file); 
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
    private uint16 fade = 0 ;
    public int draw(Surface screen)
    {
        SDL.Rect rect = {0,0,(uint16)sf.w,(uint16)sf.h};
        if(fade > 0)
        {
            fade += 5;

            sf.set_alpha(SDL.SurfaceFlag.SRCALPHA, 255);
            sf.blit_surface(null, screen, rect);
            if(next != null) {
                next.set_alpha(SDL.SurfaceFlag.SRCALPHA, (uchar)fade);
                next.blit_surface(null, screen, rect);
                if(fade > 254 ) {
                    sf = (owned)next;
                }
            }
        }else{
            sf.blit_surface(null, screen, rect);
        }
        m.redraw();
        return 0;
    }


    private time_t last_time = time_t(); 
    public void Tick()
    {
        if(current_bg == null) return;
        if(fade > 0) m.redraw();
        var now = time_t();
        if((now - last_time)  > 30){
            if(current_bg.next != null) {
                current_bg = current_bg.next;
            }else{
                current_bg = current_bg.first();
            }

            sf = SDLImage.load(directory+current_bg.data);
            sf = sf.DisplayFormat();
            m.redraw();
          //  fade = 5;
            last_time = now; 
        }
    }
}

class DrawFrame : GLib.Object, BasicDrawer
{
    private Surface sf;
    private weak Main m;
    public DrawFrame(Main m,int w, int h, int bpp)
    {
        this.m = m;
        sf = new Surface.RGB(0, w,32,bpp,(uint32)0xFF000000, 0x00FF0000, 0x0000FF00, 0x000000FF);
        sf = sf.DisplayFormatAlpha();
        SDL.Rect rect = {0,0,(uint16)sf.w,(uint16)sf.h};

        rect.h = 30;
        sf.fill(rect, sf.format.map_rgba(128,0,0,128)); 
    }
    public int draw(Surface screen)
    {
        SDL.Rect rect = {0,0,(uint16)sf.w,(uint16)30};
        rect.y = (int16)screen.h-30;
        sf.blit_surface(null, screen, rect);
        return 0;
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
                    title_label.set_text("Music Player Daemon");
                    album_label.set_text(null);
                    if(status.state == MPD.Status.State.STOP) {
                        artist_label.set_text("Stopped");
                    }
                    current_song_id = -1;
                }
        });


    }
    public int draw(Surface screen)
    {
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

/**
 * TODO: make this precise (ms - precise)
 */

class SongProgress : GLib.Object, BasicDrawer
{
    private weak Main m;
    private SDLMpc.Label elapsed_label;
    private SDLMpc.Label total_label;
    private int current_song_id = -1;

    private uint32 elapsed_time = 0;
    private uint32 total_time = 0;
    private bool progressing = false;

    public SongProgress (Main m,int w, int h, int bpp)
    {
        this.m = m;

        elapsed_label = new SDLMpc.Label(this.m,20);
        total_label = new SDLMpc.Label(this.m,20);

        /* initialize */
        m.MI.player_status_changed.connect((source, status) => {
                elapsed_time = status.get_elapsed_time(); 
                total_time = status.get_total_time(); 

                /* Update total time string */
                string a = "- %02u:%02u".printf(total_time/60, total_time%60);
                total_label.set_text(a);

                if(current_song_id != status.song_id)
                {
                    current_song_id = status.song_id;
                }
                if(status.state == MPD.Status.State.PLAY) progressing = true;
                else progressing = false;
                update_time();
                });


    }
    public int draw(Surface screen)
    {
        SDL.Rect rect = {0,0,0,0};

        rect.y = (int16)(screen.h-30-elapsed_label.height());
        rect.x = 5;

        elapsed_label.render(screen,  5, rect.y);
        total_label.render(screen, 10+elapsed_label.width(), rect.y);


        return 0;
    }
    private void update_time()
    {
        string a = "%02u:%02u".printf(elapsed_time/60, elapsed_time%60);
        elapsed_label.set_text(a);

        m.redraw();
    }


    private time_t last_time = time_t(); 
    public void Tick()
    {
        var now = time_t();
        if(last_time != now){
            if(progressing) {
                GLib.stdout.printf("Tick time\n");
                elapsed_time++;
                update_time();
            }

            last_time = now; 
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
            font = new Font("test.ttf", size);
            sf = font.render_blended_utf8(" ",b); 
            sf_shadow = font.render_blended_utf8(" ", c_shadow);
			
//			if(size <30) shadow_offset = 1;

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
    IREvent e  = new IREvent(m);
    /* Run */
    GLib.debug("Run main loop");
    m.run();
    e = null;
    SDL.quit();

    return 0;
}
