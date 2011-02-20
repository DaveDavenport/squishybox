using SDL;
using SDLMpc;
using SDLTTF;


class Standby 
{
    private Main m;
    public bool is_standby {get; set; default = false;}
    private time_t off_time = 0;
    private time_t on_time = time_t();
    private bool playing = false;


    public void Tick (time_t t)
    {
        /* if we are one minute 'idle', turn off screen */
        if(!playing && (t-on_time) > 60) {
            if(!this.is_standby)
                this.activate();
        }
    }
    public Standby(Main m)
    {
        this.m = m;

        m.MI.player_status_changed.connect((source, status) => 
        {
            Wakeup();
            if((status.state == MPD.Status.State.PLAY ||
                    status.state == MPD.Status.State.PAUSE) 
                    )
                {
                    playing = true;
                }else{
                    playing = false;
                }
        });
    }

    public bool Wakeup()
    {
        if(this.is_standby)
        {
            if(time_t() -off_time > 1)
            {
                GLib.debug("wakeup");
                turn_display_on();
                this.is_standby = false;
            }
            else return false;
        }
        on_time = time_t();
        return true;
    }
    public void activate()
    {
        var ev = new SDLMpc.Event();
        ev.type = SDLMpc.EventType.COMMANDS;
        ev.command = EventCommand.STOP;
        m.push_event((owned)ev);

        turn_display_off();
        is_standby = true;
        off_time = time_t();
    }

    private void turn_display_off()
    {
        this.m.display_control.setEnabled(false);
    }
    private void turn_display_on()
    {
        this.m.display_control.setEnabled(true);
    }
}

