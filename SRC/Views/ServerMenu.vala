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
using SDLTTF;
using SDLImage;
using MPD;
using Posix;
using SDLMpc;

class ServerMenu : SDLWidget, SDLWidgetActivate 
{
    private Main m;
    private Selector s;

    private CheckBox repeat_button;
    private CheckBox random_button;
    private CheckBox single_button;
    private CheckBox consume_button;


    public override unowned string get_name()
    {
        return "Server Menu";
    }

    private bool repeat = false;
    private bool random = false;
    private bool consume = false;
    private bool single =false;
    public ServerMenu(Main m, int x, int y, int w, int h, int bpp)
    {
        this.m = m;

        this.x = x;
        this.y = y;
        this.w = w;
        this.h = h;

        s = new Selector(m,x,y,w,h,bpp);
        this.children.append(s);

        s.add_item(new ConnectButton(m, x,y,w,h,32));
        repeat_button = new CheckBox(m, (int16)x,(int16)y,(uint16)w,(uint16)38, "Repeat");
        repeat_button.toggled.connect((source, active) => {
                this.m.MI.player_set_repeat(active); 
        });
        s.add_widget(repeat_button);

        random_button = new CheckBox(m, (int16)x,(int16)y,(uint16)w,(uint16)38, "Random");
        random_button.toggled.connect((source, active) => {
                this.m.MI.player_set_random(active); 
        });
        s.add_widget(random_button);

        consume_button = new CheckBox(m, (int16)x,(int16)y,(uint16)w,(uint16)38, "Consume Mode");
        consume_button.toggled.connect((source, active) => {
                this.m.MI.player_set_consume_mode(active); 
        });
        s.add_widget(consume_button);

        single_button = new CheckBox(m, (int16)x,(int16)y,(uint16)w,(uint16)38, "Single  Mode");
        single_button.toggled.connect((source, active) => {
                this.m.MI.player_set_single_mode(active); 
        });
        s.add_widget(single_button);



        this.m.MI.player_status_changed.connect((source,status)=> {
            if(status.repeat != repeat) {
                repeat_button.active = status.repeat;      
                repeat = status.repeat;
            }
            if(status.random != random) {
                random_button.active = status.random;      
                random = status.random;
            }
            if(status.consume != consume) {
                consume_button.active = status.consume;      
                consume = status.consume;
            }
            if(status.single != single) {
                single_button.active = status.single;      
                single = status.single;
            }
        });
    }



    public bool activate()
    {
        this.s.activate();
        return false;
    }
}


class ConnectButton : SDLWidget, SDLWidgetActivate
{
    private Main m;
    public ConnectButton(Main main, int x, int y, int w, int h, int bpp)
    {
        this.m = main;

        this.x = x;
        this.y = y;
        this.w = w;
        this.h = h;

	this.m.MI.player_connection_changed.connect((source,connect)=> {
        GLib.debug("connection changed: %i", (int)connect);
		this.require_redraw = true;
	});

    }
    public override unowned string get_name()
    {
        if(m.MI.check_connected())
        {
            return "Disconnect from MPD";
        }else{
            return "Connect to MPD";
        }
    }
    public bool activate()
    {
        GLib.debug("activate");
        if(!m.MI.check_connected()) {
            m.MI.mpd_connect();
        }else{
            m.MI.mpd_disconnect();
        }
		this.require_redraw = true;
        return true;
    }
}
