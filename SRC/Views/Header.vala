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

class Header : SDLWidget, SDLWidgetDrawing
{
    private const int OFFSET = 5;
    /* Pointer to the main object */
    private weak Main m;
    /* Quit button */
    private SDLMpc.Button quit_button;
    private SDLMpc.Button up_button;
    /* Label */
    private SDLMpc.Label title_label;


    /** Turn the top label into a clock */
    Time old_time; 
    public override void Tick (time_t now)
    {
        Time new_time = Time.local(now); 
        if(old_time.minute != new_time.minute ||
            old_time.hour != new_time.hour ||
            old_time.second != new_time.second 
          )
        {
            string strtm = new_time.format("%T %x");
            title_label.set_text(strtm);
            old_time = new_time;
        }


    }

	public override unowned string get_name()
	{
		return "Header";
	}

    private void power_button_pressed()
    {
        SDLMpc.Event ev = new SDLMpc.Event();
        ev.type = SDLMpc.EventType.COMMANDS;
        ev.command = SDLMpc.EventCommand.POWER;
        m.push_event((owned)ev);
    }
    private void up_button_pressed()
    {
        SDLMpc.Event ev = new SDLMpc.Event();
        ev.type = SDLMpc.EventType.KEY;
        ev.command = SDLMpc.EventCommand.BROWSE;
        m.push_event((owned)ev);
    }

    public Header(Main m,int x, int y, int w, int h, int bpp)
    {
        /* Set constructor variables to SDLWidget */
        this.m = m;
        this.x = x; this.y  = y; this.w = w; this.h = h;


        unowned SDL.Surface sf = this.m.theme.get_element(Theme.Element.HEADER, Theme.ElementState.NORMAL);
        /* Quit button */
        quit_button = new SDLMpc.Button(m, 
                            (int16) this.x,
                            (int16) this.y,
                            (uint16)this.h,
                            (uint16)this.h,
                            "Q");
        this.children.append(quit_button);
        quit_button.b_clicked.connect(power_button_pressed);


        /* Up button */
        up_button = new SDLMpc.Button(m, (int16) (this.x+(this.w-this.h)),
                            (int16) this.y,
                            (uint16)this.h,
                            (uint16)this.h,
                            "U");
        this.children.append(up_button);
        up_button.b_clicked.connect(up_button_pressed);

        title_label = new SDLMpc.Label (this.m,
                FontSize.NORMAL,
                (int16)(this.x+this.h+OFFSET),
                (int16)this.y,
                (uint16)(this.w-this.x-this.h-this.h-2*OFFSET),
                (uint16)this.h-2);
        title_label.center = true;
        this.children.append(title_label);
        title_label.set_text("SDLMPC");

    }

    public void draw_drawing(Surface screen, SDL.Rect *orect)
    {
        unowned SDL.Surface sf = this.m.theme.get_element(Theme.Element.HEADER, Theme.ElementState.NORMAL);
        SDL.Rect dest_rect = {0,0,0,0};
        SDL.Rect src_rect = {0,0,0,0};

        src_rect.x = int16.max((int16)(orect.x-this.x),0);
        src_rect.y = int16.max((int16)(orect.y-this.y), 0);
        src_rect.w = uint16.min(orect.w,(uint16)this.w);
        src_rect.h = uint16.min(orect.h,(uint16)this.h);


        dest_rect.x = (int16)(src_rect.x+this.x);
        dest_rect.y = (int16)(src_rect.y+this.y);
        dest_rect.w = (int16)(src_rect.w);
        dest_rect.h = (int16)(src_rect.h);

        sf.blit_surface(src_rect, screen, dest_rect);
    }

    public void set_title(string title)
    {
        title_label.set_text(title);
    }
    ~Header()
    {
        GLib.debug("header destroy");
    }
}
