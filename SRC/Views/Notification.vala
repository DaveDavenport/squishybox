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



class Notification : SDLWidget, SDLWidgetDrawing
{
    private const int TIMEOUT = 2;
    private Main m;
    public Label l;

    public override unowned string get_name()
    {
        return "Notification";
    }


    public Notification(Main m, int x, int y, int w, int h, int bpp)
    {
        this.m = m;

        this.x = x;
        this.y = y;
        this.w = w;
        this.h = h;

        unowned SDL.Surface sf = this.m.theme.get_element(Theme.Element.NOTIFICATION, Theme.ElementState.NORMAL);
        /* Center widget */
        this.x = (int)((this.w - sf.w)/2);
        this.y = (int)((this.h - sf.h)/2);
        this.w = sf.w;
        this.h = sf.h;

        l = new Label(m, FontSize.LARGE, (int16)(this.x+8), (int16)(this.y+this.h/2-24), (uint16)(this.w-16),(uint16)(48));
        l.center = true;
        l.set_text("N/A");
        this.children.append(l);
        GLib.debug("notification: %d %d %u %u\n", this.x, this.y, this.w, this.h);


        l.visible = false;
        this.visible = false;


        bool first_time  = true;
        bool single = false; bool repeat = false;
        bool random = false; bool consume = false;
        this.m.MI.player_status_changed.connect((source,status)=> {
                if(first_time) {
                    single = status.single;
                    consume = status.consume;
                    random = status.random;
                    repeat = status.repeat;

                    first_time = false;
                    return;
                }
                if(single != status.single)
                {
                    if(status.single) {
                        this.push_mesg("Single Mode: On");
                    }else {
                        this.push_mesg("Single Mode: Off");
                    }
                    single = status.single;
                }
                if(consume != status.consume)
                {
                    if(status.consume) {
                        this.push_mesg("Consume: On");
                    }else {
                        this.push_mesg("Consume: Off");
                    }
                    consume = status.consume;
                }
                if(random != status.random)
                {
                    if(status.random) {
                        this.push_mesg("Random: On");
                    }else {
                        this.push_mesg("Random: Off");
                    }
                    random = status.random;
                }
                if(status.repeat != repeat)
                {
                    if(status.repeat) {
                        this.push_mesg("Repeat: On");
                    }else {
                        this.push_mesg("Repeat: Off");
                    }
                    repeat = status.repeat;
                }

        });


    }
    public void draw_drawing(Surface screen, SDL.Rect *orect)
    {
        GLib.debug("Notification redraw");
        if(visible)
        {
            SDL.Rect dest_rect = {0,0,0,0};
            SDL.Rect src_rect = {0,0,0,0};
            
            dest_rect.x = (int16).max((int16)this.x,orect.x);
            dest_rect.y = int16.max((int16)this.y, orect.y);

            src_rect.x =  (int16).max(orect.x, (int16)this.x)-(int16)this.x;
            src_rect.y =  (int16).max(orect.y, (int16)this.y)-(int16)this.y;
            src_rect.w =  (uint16).min((uint16)this.w, (uint16)(orect.x+orect.w-dest_rect.x));
            src_rect.h =  (uint16).min((uint16)this.h, (uint16)(orect.y+orect.h-dest_rect.y));
            GLib.debug("rect: %i %i %u %u", src_rect.x, src_rect.y, src_rect.w, src_rect.h);

            unowned SDL.Surface sf = this.m.theme.get_element(Theme.Element.NOTIFICATION, Theme.ElementState.NORMAL);
            sf.blit_surface(src_rect, screen, dest_rect);

        }
    }

    /****
     * 
     */
    private time_t  start_msg = 0;
    public override void Tick (time_t now)
    {
        if(visible && start_msg +TIMEOUT <= now) {
            l.require_redraw = true; 
            this.require_redraw = true;
            l.visible = false;
            this.visible = false;
        }
    }

    public void push_mesg(string message)
    {
        start_msg = time_t();
        this.visible = true;
        l.visible = true;
        l.set_text(message);
        this.require_redraw = true;
    }



}
