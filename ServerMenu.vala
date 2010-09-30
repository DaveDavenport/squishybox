using SDL;
using SDLTTF;
using SDLImage;
using MPD;
using Posix;
using SDLMpc;

class ServerMenu : SDLWidget, SDLWidgetActivate 
{
    private Main m;
    private Selector s;


    public override unowned string get_name()
    {
        return "Server Menu";
    }
    public ServerMenu(Main m, int x, int y, int w, int h, int bpp)
    {
        this.m = m;

        this.x = x;
        this.y = y;
        this.w = w;
        this.h = h;

        s = new Selector(m,x,y,w,h,bpp);
        this.children.append(s);

        s.add_item(new ConnectButton(m, x,y,w,h,32));
        s.add_item(new RepeatButton(m, x,y,w,h,32));
        s.add_item(new RandomButton(m, x,y,w,h,32));
        s.add_item(new SingleButton(m, x,y,w,h,32));
        s.add_item(new ConsumeButton(m, x,y,w,h,32));
        s.add_item(new  ReturnButton(m, x,y,w,h,32));
    }



    public bool activate()
    {
        this.s.activate();
        return false;
    }
}


class ConnectButton : SDLWidget, SDLWidgetActivate
{
    private Main m;
    public ConnectButton(Main m, int x, int y, int w, int h, int bpp)
    {
        this.m = m;

        this.x = x;
        this.y = y;
        this.w = w;
        this.h = h;

	this.m.MI.player_connection_changed.connect((source,connect)=> {
        GLib.debug("connection changed: %i", (int)connect);
		this.require_redraw = true;
	});

    }
    public override unowned string get_name()
    {
        if(m.MI.check_connected())
        {
            return "Disconnect from MPD";
        }else{
            return "Connect to MPD";
        }
    }
    public bool activate()
    {
        GLib.debug("activate");
        if(!m.MI.check_connected()) {
            m.MI.mpd_connect();
        }else{
            m.MI.mpd_disconnect();
        }
		this.require_redraw = true;
        return true;
    }
}
class ReturnButton : SDLWidget, SDLWidgetActivate
{
    private Main m;
    public ReturnButton(Main m, int x, int y, int w, int h, int bpp)
    {
        this.m = m;
        this.x = x; this.y = y; this.w = w; this.h = h;
    }
    public override unowned string get_name()
    {
        return "... ";
    }
    public bool activate()
    {
        GLib.debug("activate");
        SDLMpc.Event ev = new SDLMpc.Event();
        ev.type = SDLMpc.EventType.COMMANDS;
        ev.command = SDLMpc.EventCommand.BROWSE;
        this.m.push_event((owned)ev);
        return true;
    }
}

class RepeatButton : SDLWidget, SDLWidgetActivate
{
    private Main m;
    private string label = "N/A Repeat";
    private bool enable = false;

    public RepeatButton(Main m, int x, int y, int w, int h, int bpp)
    {
        this.m = m;

        this.x = x;
        this.y = y;
        this.w = w;
        this.h = h;
        this.m.MI.player_status_changed.connect((source,status)=> {
            enable = status.repeat;
            GLib.debug("New repeat state: %s", (enable)?"true":"false");
            if(enable) {
                label = "Disable Repeat";
            }else{
                label = "Enable Repeat";
            }
		    this.require_redraw = true;
        });
        this.m.MI.player_fetch_status();

    }
    public override unowned string get_name()
    {
        return label;
    }
    public bool activate()
    {
        this.m.MI.player_set_repeat(!enable); 
        return true;
    }
}
class RandomButton : SDLWidget, SDLWidgetActivate
{
    private Main m;
    private string label = "N/A Random";
    private bool enable = false;

    public RandomButton(Main m, int x, int y, int w, int h, int bpp)
    {
        this.m = m;

        this.x = x;
        this.y = y;
        this.w = w;
        this.h = h;
        this.m.MI.player_status_changed.connect((source,status)=> {
            enable = status.random;
            GLib.debug("New Random state: %s", (enable)?"true":"false");
            if(enable) {
                label = "Disable Random";
            }else{
                label = "Enable Random";
            }
		    this.require_redraw = true;
        });
        this.m.MI.player_fetch_status();

    }
    public override unowned string get_name()
    {
        return label;
    }
    public bool activate()
    {
        this.m.MI.player_set_random(!enable); 
        return true;
    }
}
class SingleButton : SDLWidget, SDLWidgetActivate
{
    private Main m;
    private string label = "N/A Single Mode";
    private bool enable = false;

    public SingleButton(Main m, int x, int y, int w, int h, int bpp)
    {
        this.m = m;

        this.x = x;
        this.y = y;
        this.w = w;
        this.h = h;
        this.m.MI.player_status_changed.connect((source,status)=> {
            enable = status.single;
            GLib.debug("New Single state: %s", (enable)?"true":"false");
            if(enable) {
                label = "Disable Single Mode";
            }else{
                label = "Enable Single Mode";
            }
		    this.require_redraw = true;
        });
        this.m.MI.player_fetch_status();

    }
    public override unowned string get_name()
    {
        return label;
    }
    public bool activate()
    {
        this.m.MI.player_set_single_mode(!enable); 
        return true;
    }
}
class ConsumeButton : SDLWidget, SDLWidgetActivate
{
    private Main m;
    private string label = "N/A Consume Mode";
    private bool enable = false;

    public ConsumeButton(Main m, int x, int y, int w, int h, int bpp)
    {
        this.m = m;

        this.x = x;
        this.y = y;
        this.w = w;
        this.h = h;
        this.m.MI.player_status_changed.connect((source,status)=> {
            enable = status.consume;
            GLib.debug("New Consume state: %s", (enable)?"true":"false");
            if(enable) {
                label = "Disable Consume Mode";
            }else{
                label = "Enable Consume Mode";
            }
		    this.require_redraw = true;
        });
        this.m.MI.player_fetch_status();

    }
    public override unowned string get_name()
    {
        return label;
    }
    public bool activate()
    {
        this.m.MI.player_set_consume_mode(!enable); 
        return true;
    }
}
