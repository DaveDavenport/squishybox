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
	if(m.MI.check_connected()) {
		m.MI.mpd_connect();
	}else{
		m.MI.mpd_disconnect();
	}
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
