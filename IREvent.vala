using GLib;
using Posix;
using Linux;


/**
 * This class will listen on the remote control event device and insert SDLMpc.Event's into the main object
 * When an IR event is recieved.
 *
 * It supports recieving IR_Key events and IR_Nearness events.
 */
class IREvent : GLib.Object
{
    private uint watch_id {get; set; default=0;}
    private GLib.IOChannel io_channel = null;
    private Main m;

    ~IREvent() 
    {
        io_channel = null;
    }


    /**
     * @params source the Source iochannel.
     * @params conditions the conditions that occured 
     * Handle Watch events.
     *
     * @returns if watch should be continued. in this case always false.
     * A new watch will be created.
     *
     */
    private bool watch_callback(IOChannel source, IOCondition condition)
    {
        /* If there is data to read */
        if((condition&IOCondition.IN) == IOCondition.IN)
        {
            /* Read 1! event every time. if more are available the callback is called again anyway */
            Linux.Input.Event event = Linux.Input.Event();
            /* Get File descriptor so we can do a nice read off Event */
            int fd = source.unix_get_fd();
            /* Read the event */
            ssize_t s = Posix.read(fd, &event, sizeof(Linux.Input.Event)); 
            if (s > 0 ) 
            {
                GLib.debug("Input data: %lu %lu %u %u %i", event.time.tv_sec, event.time.tv_usec, 
                        event.type, event.code, event.value);
                
                /* Create SDLMpc event and insert into Main */
                SDLMpc.Event ev = new SDLMpc.Event();
                ev.time = event.time;
                if(event.type == 5) ev.type = SDLMpc.EventType.IR_NEARNESS;
                else if(event.type == 4) ev.type = SDLMpc.EventType.IR_KEY;
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

    /**
     * Create a watch for the iochannel 
     */
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

    /**
     * @param m The Main object this lib should insert events into.
     *
     * Create IREvent object.
     */
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
