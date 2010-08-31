using GLib;
using Posix;
using Linux;
using SDLMpc;


/**
 * This class will listen on touchscreen event device and insert SDLMpc.Event's into the main object
 * When an IR event is recieved.
 *
 * It supports recieving IR_Key events and IR_Nearness events.
 */
class TCEvent : GLib.Object
{
    private uint watch_id {get; set; default=0;}
    private GLib.IOChannel io_channel = null;
    private Main m;


    private uint16 pressure = 0;
    private bool pushed = false;
    private int fingers = 0;

    /**
	 * Destruction function
	 */
    ~TCEvent() 
    {
		GLib.debug("Destroying TCEvent");
        io_channel = null;
    }


    /**
     * Watch callback
     * params source the Source iochannel.
     * params conditions the conditions that occured 
     * Handle Watch events.
     *
     * returns if watch should be continued. in this case always false.
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
            GLib.debug("read block");


            SDLMpc.Event ev = new SDLMpc.Event();
            int16 a = 0;
            while (s > 0  && event.type != 0) 
            {
                GLib.debug("Input data: %lu %lu %u %u %i", event.time.tv_sec, event.time.tv_usec, 
                        event.type, event.code, event.value);
//                GLib.debug("Input data: %lu %lu %u %u %i", event.time.tv_sec, event.time.tv_usec, 
//                        event.type, event.code, event.value);
                /**
                 * TODO:need a propper algorithm here.. 
                 */
                if(event.type == Linux.Input.EV_ABS)
                {
                        if(event.code== Linux.Input.ABS_X) {
                            ev = new SDLMpc.Event();
                            ev.type = SDLMpc.EventType.MOUSE_MOTION;
                            ev.motion.x = 480-(uint16)((event.value/7447.0)*480.0);
                            a = 1;
                        }
                        else if (event.code == Linux.Input.ABS_Y) {
                            ev.motion.y = 272-(uint16)((event.value/4164.0)*272.0);
                            a++;
                        }else if (event.code == Linux.Input.ABS_MISC) {
                            GLib.debug("finger: %i:%i",Linux.Input.ABS_MISC, event.value);
                            if(event.value == 0) {
                                ev.type = SDLMpc.EventType.MOUSE_MOTION;
                                ev.motion.released = true;
                                pushed = false;
                                pressure = 0;
                                a = 2;
                            }
                            else fingers = event.value;
                        }else if (event.code == Linux.Input.ABS_PRESSURE) {
                            if(event.value > pressure && !pushed) {
                                ev.motion.pushed = true;
                                pushed = true;
                                pressure = (uint16)event.value;
                            }else if (pushed && event.value > pressure) {
                                pressure = (uint16)event.value;
                            }

                        }

                }
                s = Posix.read(fd, &event, sizeof(Linux.Input.Event)); 
            }
            if(a > 1 ){
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
     * param m The Main object this lib should insert events into.
     *
     * Create TCEvent object.
     */
    public TCEvent(Main m)
    {
        this.m = m;
        try{
            io_channel = new GLib.IOChannel.file("/dev/input/touchscreen0", "r");

            io_channel.set_flags(GLib.IOFlags.NONBLOCK);
            create_watch();
        }catch(Error e) {
            GLib.warning("Failed to open ir device");
        }

    }

}
