using GLib;

namespace SDLMpc
{
	public enum EventType {
        INVALID,
        IR_KEY,
        IR_NEARNESS,
		COMMAND
	}
	public enum EventCommand
	{
     	QUIT,
		/* Player command */
		NEXT,
		PREVIOUS,
		PAUSE,
		PLAY,
		STOP

	}

    [Compact]
    public class Event {
        public Posix.timeval    time;
        public EventType        type;
        public uint32           code;
        public uint32           value; 
		public EventCommand		command;

    }

 	class EventQueue
	{
		private Queue<Event> event_queue;
	}
}
