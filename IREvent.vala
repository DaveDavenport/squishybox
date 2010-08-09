using GLib;
using Posix;
using Linux;


class IREvent : GLib.Object
{
    private GLib.IOChannel io_channel = null;
    private Main m;

    ~IREvent() 
    {
        io_channel = null;
    }

    private uint watch_id {get; set; default=0;}

    private bool watch_callback(IOChannel source, IOCondition condition)
    {
        if((condition&IOCondition.IN) == IOCondition.IN)
        {
            Linux.Input.Event event = Linux.Input.Event();
            int fd = source.unix_get_fd();
            ssize_t s = Posix.read(fd, &event, sizeof(Linux.Input.Event)); 
            if (s > 0 ) 
            {
                GLib.debug("Input data: %lu %lu %u %u %i", event.time.tv_sec, event.time.tv_usec, 
                        event.type, event.code, event.value);
                SDLMpc.Event ev = new SDLMpc.Event();
                ev.time = event.time;
                if(event.type == 5) ev.type = SDLMpc.EventType.IR_NEARNESS;
                if(event.type == 4) ev.type = SDLMpc.EventType.IR_KEY;
                else ev.type = SDLMpc.EventType.INVALID;
                ev.code = event.code;
                ev.value = event.value;
                m.push_event((owned)ev);

            }
        }else if((condition&IOCondition.ERR) == IOCondition.ERR ||
            (condition&IOCondition.ERR) == IOCondition.ERR)
        {
            GLib.warning("Error state in connection");
        }

         
        /* Add watch again* */
        /* TODO: Check re-use */
        GLib.Source.remove(watch_id);
        watch_id = 0;
        create_watch();
        return false;
    }
    private void create_watch()
    {
        if(watch_id == 0) {
            watch_id = io_channel.add_watch(
                    GLib.IOCondition.IN|
                    GLib.IOCondition.OUT|
                    GLib.IOCondition.ERR|
                    GLib.IOCondition.HUP,
                    watch_callback);
        }
    }

    public IREvent(Main m)
    {
        this.m = m;
        try{
            io_channel = new GLib.IOChannel.file("/dev/input/event1", "r");
            create_watch();
        }catch(Error e) {
            GLib.warning("Failed to open ir device");
        }

    }




}
