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

    Linux.Input.Event old_event = Linux.Input.Event();
    /**
	 * Destruction function
	 */
    ~IREvent() 
    {
		GLib.debug("Destroying IREvent");
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
            if (s > 0  && event.type != 0) 
            {
                GLib.debug("Input data: %lu %lu %u %u %x", event.time.tv_sec, event.time.tv_usec, 
                        event.type, event.code, event.value);
    			/* Translate the event into a SDLMpc event */
				SDLMpc.Event ev = translate_event(event);
                {
                    uint32 diff = (uint32)((event.time.tv_sec*1000+event.time.tv_usec/1000)-(old_event.time.tv_sec*1000+old_event.time.tv_usec/1000));
                    if(diff > 200) old_event.type = -1;
                    if(old_event.type == ev.type && ev.code == old_event.code && old_event.value == ev.value){
                        ev = null;
                    }
                }
				/* Push the event into the event queue */
                if(ev != null) {
                    m.push_event((owned)ev);
                }
                old_event = event;
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
	/**
	 * @param event a Linux.Input.Event to translate.
	 *
	 * This function translates the IR event into a SDLMpc Event.
	 *
	 * @returns a SDLMpc.Event.
	 */
	private SDLMpc.Event translate_event(Linux.Input.Event event)
	{
		/* Create SDLMpc event and insert into Main */
		SDLMpc.Event ev = new SDLMpc.Event();
		ev.time = event.time;


		if(event.type == 5)
        {
            ev.type = SDLMpc.EventType.OTHER;
            if(ev.value == 1)
                ev.other = SDLMpc.EventOther.MOTION_NEAR;
            else
                ev.other = SDLMpc.EventOther.MOTION_LEFT;
        
        }
		else if(event.type == 4)
        {   
            ev.type = SDLMpc.EventType.COMMANDS;
            switch(event.value)
            {
                case 0x7689b847: // SLEEP
                    GLib.debug("IR::Sleep");
                    ev.command = SDLMpc.EventCommand.SLEEP;
                    break;
                case 0x768940BF: // POWER
                    GLib.debug("IR::Power");
                    ev.command = SDLMpc.EventCommand.POWER;
                    break;
                case  0x7689e01f: // UP
                    GLib.debug("IR::UP");
                    ev.command = SDLMpc.EventCommand.UP;
                    break;
                case 0x7689906f: // Key LEFT
                    GLib.debug("IR::LEFT");
                    ev.command = SDLMpc.EventCommand.LEFT;
                    break;
                case 0x7689d02f: // Key RIGHT
                    GLib.debug("IR::RIGHT");
                    ev.command = SDLMpc.EventCommand.RIGHT;
                    break;
                case 0x7689b04f: // Key DOWN
                    GLib.debug("IR::DOWN");
                    ev.command = SDLMpc.EventCommand.DOWN;
                    break;
                case 0x7689f00f: // 1
                    GLib.debug("IR::1");
                    ev.command = SDLMpc.EventCommand.K_1;
                    break;
                case 0x768908f7: // 2
                    GLib.debug("IR::2");
                    ev.command = SDLMpc.EventCommand.K_2;
                    break;
                case 0x76898877: // 3
                    GLib.debug("IR::3");
                    ev.command = SDLMpc.EventCommand.K_3;
                    break;
                case 0x768948b7: // 4
                    GLib.debug("IR::4");
                    ev.command = SDLMpc.EventCommand.K_4;
                    break;
                case 0x7689c837: // 5
                    GLib.debug("IR::5");
                    ev.command = SDLMpc.EventCommand.K_5;
                    break;
                case 0x768928d7: // 6
                    GLib.debug("IR::6");
                    ev.command = SDLMpc.EventCommand.K_6;
                    break;
                case 0x7689a857: // 7
                    GLib.debug("IR::7");
                    ev.command = SDLMpc.EventCommand.K_7;
                    break;
                case 0x76896897: // 8
                    GLib.debug("IR::8");
                    ev.command = SDLMpc.EventCommand.K_8;
                    break;
                case 0x7689e817: // 9
                    GLib.debug("IR::9");
                    ev.command = SDLMpc.EventCommand.K_9;
                    break;
                case 0x76899867: // 0
                    GLib.debug("IR::0");
                    ev.command = SDLMpc.EventCommand.K_0;
                    break;
                case 0x7689629D: // Search
                    GLib.debug("IR::SEARCH");
                    ev.command = SDLMpc.EventCommand.SEARCH;
                    break;
                case 0x768922dd: // Browse
                    GLib.debug("IR::BROWSE");
                    ev.command = SDLMpc.EventCommand.BROWSE;
                    break;
                case 0x7689d827: // Shuffle
                    GLib.debug("IR::SHUFFLE");
                    ev.command = SDLMpc.EventCommand.SHUFFLE;
                    break;
                case 0x768938c7: // Repeat
                    GLib.debug("IR::REPEAT");
                    ev.command = SDLMpc.EventCommand.REPEAT;
                    break;
                case 0x7689e21d: // Favorites
                    GLib.debug("IR::FAVORITES");
                    ev.command = SDLMpc.EventCommand.FAVORITES;
                    break;
                case 0x7689A25D: // Now Playing
                    GLib.debug("IR::NOW_PLAYING");
                    ev.command = SDLMpc.EventCommand.NOW_PLAYING;
                    break;
                case 0x7689f807: // Size
                    GLib.debug("IR::SIZE");
                    ev.command = SDLMpc.EventCommand.SIZE;
                    break;
                case 0x768904fb: // Brightness 
                    GLib.debug("IR::BRIGHTNESS");
                    ev.command = SDLMpc.EventCommand.BRIGHTNESS;
                    break;
                case 0x7689807f: // VOL Up
                    GLib.debug("IR::VOL_UP");
                    ev.command = SDLMpc.EventCommand.VOL_UP;
                    break;
                case 0x768900ff: // Vol Down
                    GLib.debug("IR::VOL_DOWN");
                    ev.command = SDLMpc.EventCommand.VOL_DOWN;
                    break;
                case 0x7689609f: // More
                    GLib.debug("IR::MORE");
                    ev.command = SDLMpc.EventCommand.MORE;
                    break;
                case 0x768910ef: // Play
                    GLib.debug("IR::PLAY");
                    ev.command = SDLMpc.EventCommand.PLAY;
                    break;
                case 0x7689c03f: // Rew
                    GLib.debug("IR::PREVIOUS");
                    ev.command = SDLMpc.EventCommand.PREVIOUS;
                    break;
                case 0x7689a05f: // FWD
                    GLib.debug("IR::NEXT");
                    ev.command = SDLMpc.EventCommand.NEXT;
                    break;
                case 0x768920df: // Pause
                    GLib.debug("IR::PAUSE");
                    ev.command = SDLMpc.EventCommand.PAUSE;
                    break;
                default:
                    GLib.debug("IR::UNKNOWN");
                    ev.command = SDLMpc.EventCommand.UNKNOWN;
                    break;
            }
        }
        else ev.type = SDLMpc.EventType.INVALID;
        return ev;
	}
}
