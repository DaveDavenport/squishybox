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

using MPD;
using Posix;
using SDLMpc;

/**
 * Default event handler
 */
 class DefaultHandler
 {
    private Main m = null;
    private int volume = 0;
    /**
     * Default event handler
     */
    public DefaultHandler(Main m)
    {
        this.m = m;


        this.m.MI.player_status_changed.connect((source, status) => {
                volume = status.get_volume();
                });
    }

    /**
     * Process incoming events 
     */
    public void process(Event ev)
    {
        if(ev.type == SDLMpc.EventType.KEY) {
            switch(ev.command) 
            {
                case EventCommand.VOL_UP:
                    if(volume <= 95) {
                        this.m.MI.mixer_set_volume(volume+5);
                    }else{
                        this.m.MI.mixer_set_volume(100);
                    }
                    break;
                case EventCommand.VOL_DOWN:
                    if(volume >= 5) {
                        this.m.MI.mixer_set_volume(volume-5);
                    }else{
                        this.m.MI.mixer_set_volume(0);
                    }
                    break;
                default:
                    break;
            }
        }


    }
 }
