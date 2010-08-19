using SDL;
using SDLTTF;
using SDLImage;
using MPD;
using Posix;
using SDLMpc;



class Main : GLib.Object
{
    public MPD.Interaction MI = new MPD.Interaction();

    private unowned Screen screen; 
    private GLib.MainLoop loop = new GLib.MainLoop();

    private SDLWidget bg;
    private SDLWidget np;
    private SDLWidget selector;  
    /**
     * Object to set backlight 
     */
    public DisplayControl display_control = new DisplayControl();


    SDL.Rect mo_rect;


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


        SDL.Key.enable_unicode(1);
        SDL.Key.set_repeat(100,100);
        GLib.debug("Set Video mode");

#if PC
        screen = SDL.Screen.set_video_mode(
                480,
                272,
                32,
                SDL.SurfaceFlag.DOUBLEBUF|SDL.SurfaceFlag.HWSURFACE);
#else
        SDL.Cursor.show(0);
        screen = SDL.Screen.set_video_mode(
                480,
                272,
                32,
                SDL.SurfaceFlag.DOUBLEBUF|
                SDL.SurfaceFlag.HWSURFACE|
                SDL.SurfaceFlag.FULLSCREEN);
#endif

        if(screen == null) {
            GLib.error("failed to create screen\n");

        }

        /* Create background drawer */
        GLib.debug("Create background draw object");


        /* Prepare basic widget */
        bg       = new BackgroundDrawer  (this,  0,      0,  480, 272, 32);

        selector = new Selector (this,  0,      0,  480, 272, 32);

        np      = new NowPlaying        (this,480, 272, 32);

        (selector as Selector).add_item(np);
        (selector as Selector).add_item(new Standby(this));
        bg.children.append(selector);



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
        bool cc = false;
        t++;
        SDL.Event event = SDL.Event();
        /* Clear the screen */


        bg.do_Tick(time_t());

        if(changed > 0){
            if(screensaver) {
            }else{
                bg.draw(screen);
                changed = 0;
                cc = true;
            }
        }
        SDLMpc.Event ev; 
        /** 
         * Translate SDL Events 
         */
        while(SDL.Event.poll(event)>0){
            switch(event.type)
            {
                case SDL.EventType.MOUSEMOTION:
                    if(event.motion.state > 0)
                    {
                        ev = new SDLMpc.Event();
                        ev.type = SDLMpc.EventType.MOUSE_MOTION;
                        ev.motion.x = event.motion.x;
                        ev.motion.y = event.motion.y;
                        push_event((owned)ev);
                    }
                    break;
                 case SDL.EventType.MOUSEBUTTONDOWN:
                    ev = new SDLMpc.Event();
                    ev.type = SDLMpc.EventType.MOUSE_MOTION;
                    ev.motion.x = event.motion.x;
                    ev.motion.y = event.motion.y;
                    ev.motion.pushed = true;
                    push_event((owned)ev);
                    break;
                 case SDL.EventType.MOUSEBUTTONUP:
                    ev = new SDLMpc.Event();
                    ev.type = SDLMpc.EventType.MOUSE_MOTION;
                    ev.motion.x = event.motion.x;
                    ev.motion.y = event.motion.y;
                    ev.motion.released = true;
                    push_event((owned)ev);
                    break;
                case SDL.EventType.QUIT:
                     ev = new SDLMpc.Event();
                     ev.type = SDLMpc.EventType.COMMANDS;
                     ev.command = EventCommand.QUIT;
                     push_event((owned)ev);
                     break;
                case SDL.EventType.KEYUP:
                    if(event.key.keysym.sym == KeySymbol.q)
                    {
                        ev = new SDLMpc.Event();
                        ev.type = SDLMpc.EventType.COMMANDS;
                        ev.command = EventCommand.QUIT;
                        push_event((owned)ev);
                    }
                    else if (event.key.keysym.sym == KeySymbol.h)
                    {
                        ev = new SDLMpc.Event();
                        ev.type = SDLMpc.EventType.COMMANDS;
                        ev.command = EventCommand.BROWSE;
                        push_event((owned)ev);
                    }
                    else if (event.key.keysym.sym == KeySymbol.z)
                    {
                        GLib.debug("insert z event");
                        ev = new SDLMpc.Event();
                        ev.type = SDLMpc.EventType.KEY;
                        ev.command = EventCommand.PREVIOUS;
                        push_event((owned)ev);
                    }
                    else if (event.key.keysym.sym == KeySymbol.s)
                    {
                    }
                    break;
                 default:
                    break;

            }
        }


        /**
         * Internal Event Queue 
         */
        while((ev= events.pop_head()) != null)
        {
            if(ev.type == SDLMpc.EventType.INVALID) 
                continue;
            /* Handle incoming remote events */
            if(ev.type == SDLMpc.EventType.COMMANDS) {
                switch(ev.command) {
                    case EventCommand.QUIT:
                        GLib.debug("request quit");
                        loop.quit();
                        MI = null;
                        return false;
                    case EventCommand.PAUSE:
                        MI.player_toggle_pause(); 
                        break;
                    case EventCommand.NEXT:
                        MI.player_next();
                        break;
                    case EventCommand.PREVIOUS:
                        MI.player_previous();
                        break;
                    case EventCommand.PLAY:
                        MI.player_play();
                        break;
                    case EventCommand.STOP:
                        MI.player_stop();
                        break;
                    case EventCommand.BROWSE:
                        (selector as Selector).Home();
                        break;
                    case EventCommand.POWER:
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
                    case EventCommand.SLEEP:
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
                        bg.do_Event(ev);
                        break;
                }
                pev = (owned)ev;
            }
            else if(ev.type == SDLMpc.EventType.MOUSE_MOTION) {
                if(ev.motion.pushed) {
                    mo_rect.x = (int16) ev.motion.x;
                    mo_rect.y = (int16) ev.motion.y;
                    GLib.debug("push %i %i", ev.motion.x, ev.motion.y); 

                    bg.clicked(mo_rect.x, mo_rect.y, true);
                }
                else if (ev.motion.released) {
                    bg.clicked(mo_rect.x, mo_rect.y, false);
                    mo_rect.x = 0;
                    mo_rect.y = 0;
                    GLib.debug("push release %i %i", ev.motion.x, ev.motion.y); 
                } else {
                    mo_rect.x = (int16) ev.motion.x;
                    mo_rect.y = (int16) ev.motion.y;
                }
            }
            else {
                bg.do_Event(ev);
            }

        }
        if(cc){
            screen.flip();
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
    IREvent e  = new IREvent(m);
    TCEvent tc = new TCEvent(m);
    /* Run */
    GLib.debug("Run main loop");
    m.run();
    /* Cleanup */
    e = null;
    tc = null;
    SDL.quit();

    return 0;
}
