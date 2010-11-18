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
class MpdDatabaseView : SDLWidget, SDLWidgetActivate,SDLWidgetDrawing,SDLWidgetMotion
{

    private Main m;
    private int top = 0;
    private uint length = 0;
    private uint num_items = 0;
    private uint current_song = 0;


    public bool motion(double x, double y, bool pushed, bool released)
    {
        if(!pushed && !released)
        {
            if(x > this.w-30) 
            {
                double offset = ((double)y)/this.h;
                var pos = (int)(offset*length);
                if(top != pos)
                {
                    top = pos;
                    if(top > length-num_items) {
                        top = (int)(length-num_items);
                    }
                    update();
                }
            }
        }
        return false;
    }


    public override unowned string get_name()
    {
        return "Database";
    }
    public void database_directory(List<MPD.Song>? song_list)
    {
        GLib.debug("data directory: %u\n", song_list.length());
        foreach(MPD.Song song in song_list)
        {
            var a = new Button(m, 0,20,20,20, song.uri);
            this.children.append(a);
        }

    }

    public MpdDatabaseView (Main m, int x, int y, int w, int h, int bpp)
    {
        this.m = m;

        this.x = x;
        this.y = y;
        this.w = w;
        this.h = h;

        num_items = this.h/28;

        m.MI.player_status_changed.connect((source, status) => 
        {
        });
        m.MI.player_connection_changed.connect((source, connect) => {
                if(connect) {
                    source.database_get_directory(database_directory, "");
                }
        });

        m.MI.database_get_directory(database_directory, "");

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
    public void draw_drawing(Surface screen, SDL.Rect *orect)
    {
        var index = 0;
        foreach(var child in this.children)
        {
            GLib.debug("position: %i->%i",child.y,index);
            (child as MenuButton).set_y(this.y+index);
            index += 30;
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
                SDLWidget last = a.data;
                while(a != null && a.prev!= null)
                {
                    a.data = a.prev.data;
                    a = a.prev;
                }
                if(a != null){
                    a.data = last;
                    (a.data as MenuButton).set_pos(top);
                }
                update();
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
                SDLWidget first = a.data;
                while(a != null && a.next!= null)
                {
                    a.data = a.next.data;
                    a = a.next;
                }
                if(a != null){
                    a.data = first;
                     (a.data as MenuButton).set_pos(top+num_items-1);
                }

                update();
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
