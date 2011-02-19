using SDL;
using SDLMpc;
using SDLTTF;


class Standby : SDLMpc.SDLWidget, SDLMpc.SDLWidgetActivate
{
    private Main m;
    private new unowned string get_name()
    {
        return "Standby";
    }

    public Standby(Main m)
    {
        this.m = m;
    }

    private void Wakeup()
    {
        this.m.display_control.setEnabled(true);
        var ev = new SDLMpc.Event();
        ev.type = SDLMpc.EventType.COMMANDS;
        ev.command = EventCommand.BROWSE;
        m.push_event((owned)ev);
    }
    private new void button_release(bool inside)
    {
        Wakeup();
    }

    public override bool Event(SDLMpc.Event e)
    {
        GLib.debug("Got event in standby, see if wakeup: %i %i", e.type, e.command);
        if(e.type == SDLMpc.EventType.KEY)
        {
            Wakeup();
            return true;
        }
        return false;
    }

    public override void Tick(time_t t)
    {

    }

    public bool activate()
    {
        this.m.display_control.setEnabled(false);
        var ev = new SDLMpc.Event();
        ev.type = SDLMpc.EventType.COMMANDS;
        ev.command = EventCommand.STOP;
        m.push_event((owned)ev);
        return false;
    }
}

