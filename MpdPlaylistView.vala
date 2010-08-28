using SDL;
using SDLTTF;
using SDLImage;
using MPD;
using Posix;
using SDLMpc;

class MpdPlaylistView : SDLWidget, SDLWidgetActivate
{

    private Main m;
    private Selector s;

    private void song_queue_callback(List<MPD.Song>? song_list)
    {
        s.clear();
        foreach(MPD.Song song in song_list)
        {
            string a;
            if((a = song.get_tag(MPD.Tag.Type.TITLE,0)) == null) {
                a="";
                /* TODO: Try filename */
            }
            var entry = new MenuButton(m, a);
            this.s.add_item(entry);
        }
    }
    public override unowned string get_name()
    {
        return "Playlist";
    }

    public MpdPlaylistView (Main m, int x, int y, int w, int h, int bpp)
    {
        this.m = m;

        this.x = x;
        this.y = y;
        this.w = w;
        this.h = h;

        s = new Selector(m,x,y,w,h,bpp);
        this.children.append(s);


        m.MI.player_connection_changed.connect((source, connect) => {
            if(connect) {
                m.MI.player_get_queue(song_queue_callback);
            }
        });
        m.MI.player_queue_changed.connect((source) => {
            m.MI.player_get_queue(song_queue_callback);
        });
    }


    public bool activate()
    {
        this.s.activate();
        return false;
    }


}

class MenuButton : SDLWidget, SDLWidgetActivate
{
    private Main m;
    private string name;
    public override unowned string get_name()
    {
        return name;
    }
    public MenuButton(Main m, string name)
    {
        this.m = m;
        this.name = name;
    }
    ~MenuButton()
    {
        GLib.debug("menu button destroy");
    }

    public bool activate()
    {
        return true;
    }
}
