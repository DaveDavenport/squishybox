/* Squishybox 
 * Copyright (C) 2010-2011 Qball Cow <qball@sarine.nl>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */
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
        public double	x;
        public double   y;
        public bool     pushed;
        public bool     released;
    }

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
