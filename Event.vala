using GLib;

namespace SDLMpc
{
	public enum EventType {
        INVALID,
        IR_NEARNESS,
        KEY,
		COMMANDS,
        MOUSE_MOTION,
        OTHER
	}
	public enum EventCommand
	{
        QUIT,

     	POWER,
        SLEEP,
		/* Player command */
		NEXT,
		PREVIOUS,
		PAUSE,
		PLAY,
		STOP,
        SHUFFLE,
        REPEAT,
        /* KEYP */
        K_1,
        K_2,
        K_3,
        K_4,
        K_5,
        K_6,
        K_7,
        K_8,
        K_9,
        K_0,
        MORE,
        VOL_UP,
        VOL_DOWN,
        UP,
        DOWN,
        LEFT,
        RIGHT,
        FAVORITES,
        NOW_PLAYING,
        SIZE,
        BRIGHTNESS,
        SEARCH,
        BROWSE,
        UNKNOWN
	}
    public enum EventOther
    {
        MOTION_NEAR,
        MOTION_LEFT
    }

    public struct EventMotion
    {
        public uint16   x;
        public uint16   y;
        public bool     pushed;
        public bool     released;
    }

    [Compact]
    public class Event {
        public Posix.timeval    time;
        public EventType        type;
        public uint32           code;
        public uint32           value; 
		public EventCommand	    command;
        public EventOther       other;
        public EventMotion      motion;

        public Event Copy()
        {
            var ret = new Event();
            ret.time = this.time;
            ret.type = this.type;
            ret.command = this.command;
            ret.code = this.code;
            ret.value =this.value;
            ret.other = this.other;
            ret.motion = this.motion;
            return ret;
        }

    }

}
