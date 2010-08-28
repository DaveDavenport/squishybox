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
    }
    public override unowned string get_name()
    {
        if(m.MI.check_connected())
        {
            return "Disconnect";
        }else{
            return "Connect";
        }
    }
    public bool activate()
    {
        GLib.debug("activate");
        return true;
    }
}
