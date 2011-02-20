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
using SDL;
using GLib;
using Posix;
using Linux;
using SDLMpc;

/**
 * This class will handle SDL events, translate them and forward them to our 
 * event queue.
 */
class SDLEvent
{
    private Main m;

    public SDLEvent(Main m)
    {
        this.m = m;
    }

    public void process_events()
    {
        SDL.Event event = SDL.Event();
        SDLMpc.Event ev; 
        while(SDL.Event.poll(event)>0){
            switch(event.type)
            {
                case SDL.EventType.MOUSEMOTION:
                    if(event.motion.state > 0)
                    {
                        ev = new SDLMpc.Event();
                        ev.type = SDLMpc.EventType.MOUSE_MOTION;
                        ev.motion.x = event.motion.x;
                        ev.motion.y = event.motion.y;
                        this.m.push_event((owned)ev);
                    }
                    break;
                case SDL.EventType.MOUSEBUTTONDOWN:
                    ev = new SDLMpc.Event();
                    ev.type = SDLMpc.EventType.MOUSE_MOTION;
                    ev.motion.x = event.motion.x;
                    ev.motion.y = event.motion.y;
                    ev.motion.pushed = true;
                    this.m.push_event((owned)ev);
                    break;
                case SDL.EventType.MOUSEBUTTONUP:
                    ev = new SDLMpc.Event();
                    ev.type = SDLMpc.EventType.MOUSE_MOTION;
                    ev.motion.x = event.motion.x;
                    ev.motion.y = event.motion.y;
                    ev.motion.released = true;
                    this.m.push_event((owned)ev);
                    break;
                case SDL.EventType.QUIT:
                    ev = new SDLMpc.Event();
                    ev.type = SDLMpc.EventType.COMMANDS;
                    ev.command = EventCommand.QUIT;
                    this.m.push_event((owned)ev);
                    break;
                case SDL.EventType.KEYDOWN:
                    if(event.key.keysym.sym == 49)
                    {
                        ev = new SDLMpc.Event();
                        ev.type = SDLMpc.EventType.KEY;
                        ev.command = EventCommand.K_1;
                        this.m.push_event((owned)ev);
                    }
                    if(event.key.keysym.sym == 50)
                    {
                        ev = new SDLMpc.Event();
                        ev.type = SDLMpc.EventType.KEY;
                        ev.command = EventCommand.K_2;
                        this.m.push_event((owned)ev);
                    }
                    if(event.key.keysym.sym == 51)
                    {
                        ev = new SDLMpc.Event();
                        ev.type = SDLMpc.EventType.KEY;
                        ev.command = EventCommand.K_3;
                        this.m.push_event((owned)ev);
                    }
                    if(event.key.keysym.sym == 52)
                    {
                        ev = new SDLMpc.Event();
                        ev.type = SDLMpc.EventType.KEY;
                        ev.command = EventCommand.K_4;
                        this.m.push_event((owned)ev);
                    }
                    if(event.key.keysym.sym == 53)
                    {
                        ev = new SDLMpc.Event();
                        ev.type = SDLMpc.EventType.KEY;
                        ev.command = EventCommand.K_5;
                        this.m.push_event((owned)ev);
                    }
                    if(event.key.keysym.sym == 54) 
                    {
                        ev = new SDLMpc.Event();
                        ev.type = SDLMpc.EventType.KEY;
                        ev.command = EventCommand.K_6;
                        this.m.push_event((owned)ev);
                    }
                    if(event.key.keysym.sym == 55) 
                    {
                        ev = new SDLMpc.Event();
                        ev.type = SDLMpc.EventType.KEY;
                        ev.command = EventCommand.K_7;
                        this.m.push_event((owned)ev);
                    }
                    if(event.key.keysym.sym == 56) 
                    {
                        ev = new SDLMpc.Event();
                        ev.type = SDLMpc.EventType.KEY;
                        ev.command = EventCommand.K_8;
                        this.m.push_event((owned)ev);
                    }
                    if(event.key.keysym.sym == 57) 
                    {
                        ev = new SDLMpc.Event();
                        ev.type = SDLMpc.EventType.KEY;
                        ev.command = EventCommand.K_9;
                        this.m.push_event((owned)ev);
                    }
                    if(event.key.keysym.sym == 48)
                    {
                        ev = new SDLMpc.Event();
                        ev.type = SDLMpc.EventType.KEY;
                        ev.command = EventCommand.K_0;
                        this.m.push_event((owned)ev);
                    }
                    if(event.key.keysym.sym == KeySymbol.q)
                    {
                        ev = new SDLMpc.Event();
                        ev.type = SDLMpc.EventType.COMMANDS;
                        ev.command = EventCommand.QUIT;
                        this.m.push_event((owned)ev);
                    }
                    else if (event.key.keysym.sym == KeySymbol.h)
                    {
                        ev = new SDLMpc.Event();
                        ev.type = SDLMpc.EventType.KEY;
                        ev.command = EventCommand.BROWSE;
                        this.m.push_event((owned)ev);
                    }
                    else if (event.key.keysym.sym == KeySymbol.z)
                    {
                        GLib.debug("insert z event");
                        ev = new SDLMpc.Event();
                        ev.type = SDLMpc.EventType.KEY;
                        ev.command = EventCommand.PREVIOUS;
                        this.m.push_event((owned)ev);
                    }
                    else if (event.key.keysym.sym == KeySymbol.UP)
                    {
                        ev = new SDLMpc.Event();
                        ev.type = SDLMpc.EventType.KEY;
                        ev.command = EventCommand.UP;
                        this.m.push_event((owned)ev);
                    }
                    else if (event.key.keysym.sym == KeySymbol.DOWN)
                    {
                        ev = new SDLMpc.Event();
                        ev.type = SDLMpc.EventType.KEY;
                        ev.command = EventCommand.DOWN;
                        this.m.push_event((owned)ev);
                    }
                    else if (event.key.keysym.sym == KeySymbol.RIGHT)
                    {
                        ev = new SDLMpc.Event();
                        ev.type = SDLMpc.EventType.KEY;
                        ev.command = EventCommand.RIGHT;
                        this.m.push_event((owned)ev);
                    }
                    break;
                default:
                    break;

            }
        }
    }
}
