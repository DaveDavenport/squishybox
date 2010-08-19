using SDL;
using SDLTTF;
using SDLImage;
using MPD;
using Posix;
using SDLMpc;

/**
 * This is the now playing widget. It shows the song title/artist/album/year
 * It also shows some player control buttons 
 */

class NowPlaying : SDLWidget, SDLWidgetDrawing
{
    private weak Main m;

    private SDLMpc.Label title_label;
    private SDLMpc.Label artist_label;
    private SDLMpc.Label album_label;

    private int current_song_id = -1;

    public override unowned string get_name()
    {
        return "Now playing";
    }

    public NowPlaying(Main m,int w, int h, int bpp)
    {
        this.m = m;

        var  sp = new SongProgress      (this.m,480, 272, 32);
        this.children.append(sp);
        var frame   = new PlayerControl     (this.m,  0, 272-42,  480, 42,  32);
        this.children.append(frame);

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
    public void draw_drawing(Surface screen)
    {
        SDL.Rect rect = {0,0,0,0};

        rect.y = 5;
        title_label.render(screen, 5, rect.y);

        rect.y += (int16)title_label.height();
        artist_label.render(screen, 5, rect.y);

        rect.y += (int16)artist_label.height();
        album_label.render(screen, 5, rect.y);
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

    public override void Tick(time_t now)
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

class SongProgress : SDLWidget, SDLWidgetDrawing
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
    public void draw_drawing(Surface screen)
    {
        SDL.Rect rect = {0,0,0,0};

        rect.y = (int16)(screen.h-40-elapsed_label.height());
        rect.x = 5;

        elapsed_label.render(screen,  5, rect.y);
        total_label.render(screen, 10+elapsed_label.width(), rect.y);
    }
    private void update_time()
    {
        string a = "%02u:%02u".printf(elapsed_time/60, elapsed_time%60);
        elapsed_label.set_text(a);

        m.redraw();
    }


    private time_t last_time = time_t(); 
    public override void Tick(time_t now)
    {
        if(last_time != now){
            if(progressing) {
                elapsed_time++;
                update_time();
            }

            last_time = now; 
        }
    }
}

class PlayerControl : SDLWidget, SDLWidgetDrawing
{
    private Surface sf;
    private weak Main m;

    private SDLMpc.Button prev_button;

    private SDLMpc.Button pause_button;
    private SDLMpc.Button next_button;

    private SDLMpc.Button quit_button;

    private bool pressed = false;
    private bool stopped = false;



    public PlayerControl(Main m,int x, int y, int w, int h, int bpp)
    {
        this.m = m;

        this.x = x; this.y  = y; this.w = w; this.h = h;


        sf = new Surface.RGB(0, w,h,bpp,(uint32)0xFF000000, 0x00FF0000, 0x0000FF00, 0x000000FF);
        sf = sf.DisplayFormatAlpha();

        SDL.Rect rect = {0,0,(uint16)sf.w,(uint16)sf.h};
        rect.h = (uint16)this.h;
        if(pressed) {
            sf.fill(rect, sf.format.map_rgba(200,30,30,128)); 
        }else{
            sf.fill(rect, sf.format.map_rgba(30,30,30,128)); 
        }

        prev_button = new SDLMpc.Button(m, (int16) this.x+ 1,(int16) this.y+1,  50, 40, "◂◂");
        prev_button.b_clicked.connect((source) => {
                SDLMpc.Event ev = new SDLMpc.Event();
                ev.type = SDLMpc.EventType.COMMANDS;
                ev.command = SDLMpc.EventCommand.NEXT;
                m.push_event((owned)ev);
                });
        pause_button = new SDLMpc.Button(m,(int16) this.x+ 52,(int16) this.y+1, 50, 40, "▶");
        pause_button.b_clicked.connect((source) => {
                SDLMpc.Event ev = new SDLMpc.Event();
                ev.type = SDLMpc.EventType.COMMANDS;
                if(stopped) {
                    ev.command = SDLMpc.EventCommand.PLAY;
                }else{
                    ev.command = SDLMpc.EventCommand.PAUSE;
                }
                m.push_event((owned)ev);
                });
        next_button = new SDLMpc.Button(m, (int16) this.x+ 103,(int16) this.y+1, 50, 40, "▸▸");
        next_button.b_clicked.connect((source) => {
                SDLMpc.Event ev = new SDLMpc.Event();
                ev.type = SDLMpc.EventType.COMMANDS;
                ev.command = SDLMpc.EventCommand.NEXT;
                m.push_event((owned)ev);
                });

        quit_button = new SDLMpc.Button(m, (int16) this.w- 51,(int16) this.y+1, 50, 40, "⌂");
        quit_button.b_clicked.connect((source) => {
                SDLMpc.Event ev = new SDLMpc.Event();
                ev.type = SDLMpc.EventType.COMMANDS;
                ev.command = SDLMpc.EventCommand.BROWSE;
                m.push_event((owned)ev);
                });




        m.MI.player_status_changed.connect((source, status) => {
                stopped = false;
                if(status.state == MPD.Status.State.PLAY) {
                    pause_button.update_text("▮▮");
                }else {
                    pause_button.update_text("▶");
                    if(status.state == MPD.Status.State.STOP){
                        stopped = true;
                    }
                }
        });


        this.children.append(prev_button);
        this.children.append(pause_button);
        this.children.append(next_button);
        this.children.append(quit_button);
    }
    public void draw_drawing(Surface screen)
    {
        SDL.Rect dest_rect = {0,0,0,0};

        dest_rect.x = (int16)this.x;
        dest_rect.y = (int16)this.y;
        dest_rect.w = (uint16)this.w;
        dest_rect.h = (uint16)this.h;

        sf.blit_surface(null, screen, dest_rect);
    }
    public override void button_press()
    {
        if(!pressed)
        {
            SDL.Rect rect = {0,0,(uint16)this.w,(uint16)this.h};
            GLib.debug("PlayerControl bg press");
            pressed =true;
            sf.fill(rect, sf.format.map_rgba(200,30,30,128)); 
            m.redraw();
        }
    }
    public override void button_release(bool inside)
    {
        if(pressed) {
            SDL.Rect rect = {0,0,(uint16)this.w,(uint16)this.h};
            GLib.debug("PlayerControl bg release");
            sf.fill(rect, sf.format.map_rgba(30,30,30,128)); 
            pressed = false;

            if(inside) {
                /* Button release */

            }
            m.redraw();
        }
    }


    /**
     * Player control claims several buttons.
     * And handles these
     */
    public override bool Event(SDLMpc.Event ev)
    {
        if(ev.type == SDLMpc.EventType.KEY) {
            switch(ev.command)
            {
                case EventCommand.PAUSE:
                case EventCommand.NEXT:
                case EventCommand.PLAY:
                case EventCommand.PREVIOUS:
                    var pev = ev.Copy(); 
                    pev.type = SDLMpc.EventType.COMMANDS;
                    m.push_event((owned)pev);
                    return true;
                default:
                    break;
            }
        }
        return false;
    }
}
