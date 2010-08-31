using SDL;
using SDLTTF;
using SDLImage;
using MPD;
using Posix;
using SDLMpc;


/**
 * A playlist view. 
 *
 */
class MpdPlaylistView : SDLWidget, SDLWidgetActivate
{

    private Main m;
    private Selector s;
    private int top = 0;
    private uint length = 0;
    private uint num_items = 0;
    private uint current_song = 0;

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

        num_items = this.h/28;

        m.MI.player_status_changed.connect((source, status) => {
                if(status.queue_length != length)
                {
                length = status.queue_length;
                this.children = null;
                for(var i=0; i < num_items && i < length;i++)
                {
                var b = new MenuButton(this.m,(int16)x,(int16)( y+i*30),(uint16) w-30, (uint16)28, i);
                this.children.append(b);
                }
                }
                if(status.song_pos != current_song) 
                {
                    current_song = status.song_pos;
                    top = (int)(current_song-num_items/2);
                    if(top > length-num_items) {
                        top = (int)(length-num_items); 
                    }
                    update();
                }
                });
        m.MI.player_connection_changed.connect((source, connect) => {
                if(connect) {
                top = 0;
                var i = 0;
                foreach(var child in this.children)
                {
                (child as MenuButton).set_pos(i);
                i++;
                }
                }
                });

    }
    private void update()
    {
        var i = 0;
        foreach(var child in this.children)
        {
            (child as MenuButton).set_pos(i+top);
            i++;
        }
    }

    public override bool Event(SDLMpc.Event ev)
    {
        if(ev.type == SDLMpc.EventType.KEY)
        {
            if(ev.command == SDLMpc.EventCommand.UP)
            {
                top -= 1;
                if(top < 0){
                    top = 0;
                    return true;
                }
               

                unowned List<unowned SDLWidget> a = this.children.last();
                while(a != null && a.prev!= null)
                {
                    GLib.debug("new: %s", (a.prev.data as MenuButton).name);
                    (a.data as MenuButton).update_entry((a.prev.data as MenuButton).pos, (a.prev.data as MenuButton).name);
                    a = a.prev;
                }
                if(a != null) (a.data as MenuButton).set_pos(top);
                m.redraw();

                return true;
            }
            else if(ev.command == SDLMpc.EventCommand.DOWN)
            {
                top += 1;
                if(top+num_items >  (length))
                {
                    top -=1;
                    return true;
                }

                unowned List<unowned SDLWidget> a = this.children.first();
                while(a != null && a.next!= null)
                {
                    GLib.debug("new: %s", (a.next.data as MenuButton).name);
                    (a.data as MenuButton).update_entry((a.next.data as MenuButton).pos, (a.next.data as MenuButton).name);
                    a = a.next;
                }
                if(a != null) (a.data as MenuButton).set_pos(top+num_items-1);
                m.redraw();

                return true;
            } else if(ev.command == SDLMpc.EventCommand.RIGHT)
            {
                return true;
            }
        }
        return false;
    }

    public bool activate()
    {
        return false;
    }


}

class MenuButton : SDLWidget, SDLWidgetActivate
{
    private Main m;
    public string name;
    public uint pos = 0;
    private Button b; 

    public void update_entry(uint pos, string name)
    {
        this.pos = pos;
        this.name = name;
        this.b.update_text(this.name);
    }

    public override unowned string get_name()
    {
        return name;
    }
    private void get_song(MPD.Song? song)
    {
        if(song != null && song.pos == this.pos)
        {
            string a = "%u: ".printf(this.pos+1);
            var b = song.get_tag(MPD.Tag.Type.TITLE,0);
            if(b != null) {
                a +=b;;
            }
            b = song.get_tag(MPD.Tag.Type.ARTIST,0);
            if(b != null)
            {
                a += " - "+b;
            }
            this.name = a;
            this.b.update_text(this.name);
        }
    }
    public MenuButton(Main m,int16 x, int16 y, uint16 w, uint16 h, uint pos)
    {
        this.m = m;
        this.pos = pos;
        this.name = "%u - loading".printf(pos);
        this.b = new  Button(m, x, y,w, h, this.name);
        this.b.l.do_scrolling = false;
        this.b.x_align = 0.0;
        this.children.append(b);
        this.m.MI.player_get_queue_pos(get_song, this.pos);

       this.b.b_clicked.connect((source) => {
            this.m.MI.player_play_pos(this.pos);
        });
    }
    ~MenuButton()
    {
        GLib.debug("menu button destroy");
    }

    public void set_pos(uint pos)
    {
        this.pos = pos;
        this.name = "%u - loading".printf(pos);
        this.b.update_text(this.name);
        this.m.MI.player_get_queue_pos(get_song, this.pos);
    }

    public bool activate()
    {
        this.b.b_clicked();
        return true;
    }
}
