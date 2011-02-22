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

class AlarmTimer : SDLWidget, SDLWidgetDrawing
{
    /* Pointer to the main object */
    private weak Main m;
    private bool enabled = false;
    private uint alarm_minute = 0;
    private uint alarm_hour = 8;
    private SDLMpc.Label hour_label;
    private SDLMpc.Label minute_label;



    public override unowned string get_name()
    {
        return "Alarm Timer";
    }
    /** Turn the top label into a clock */
    Time old_time; 
    public override void Tick (time_t now)
    {
        Time new_time = Time.local(now); 
        if(old_time.minute != new_time.minute ||
            old_time.hour != new_time.hour
          )
        {
            /* Check alarm */
            if(enabled && alarm_hour == new_time.hour && alarm_minute == new_time.minute)
            {
                SDLMpc.Event ev = new SDLMpc.Event();
                ev.type = SDLMpc.EventType.COMMANDS;
                ev.command = SDLMpc.EventCommand.PLAY;
                m.push_event((owned)ev);
            }
            old_time = new_time;
        }


    }



    public AlarmTimer(Main m,int x, int y, int w, int h, int bpp)
    {
        /* Set constructor variables to SDLWidget */
        this.m = m;
        this.x = x; this.y  = y; this.w = w; this.h = h;

        /**
         * Enable, disable button
         */
        var enable_button = new SDLMpc.Button(m, 
                (int16) this.x+5,
                (int16) this.y+5,
                (uint16)this.w-10,
                (uint16) 38,
                "Enable");
        enable_button.b_clicked.connect((source) => {
            enabled = ! enabled;
            if(enabled) {
                source.update_text("Disable");
            }else {
                source.update_text("Enable");
            }
            
        });
        this.children.append(enable_button);
        this.add_focus_widget(enable_button);

        /** 
         *
         */
        hour_label = new SDLMpc.Label(this.m,FontSize.LARGE, 
                (int16)this.x+5,
                (int16)this.y+5+38+5,
                (uint16)50,
                (uint16)56);
        hour_label.set_text("%02u".printf(alarm_hour));
        this.children.append(hour_label);
        this.add_focus_widget(hour_label);

        var sep_label = new SDLMpc.Label(this.m,FontSize.LARGE, 
                (int16)this.x+5+56,
                (int16)this.y+5+38,
                (uint16)20,
                (uint16)56);
        
        sep_label.set_text(":");
        this.children.append(sep_label);
        minute_label = new SDLMpc.Label(this.m,FontSize.LARGE, 
                (int16)this.x+5+56+20,
                (int16)this.y+5+38+5,
                (uint16)50,
                (uint16)56);
        minute_label.set_text("%02u".printf(alarm_minute));
        this.children.append(minute_label);
        this.add_focus_widget(minute_label);

    }


    public void draw_drawing(Surface screen, SDL.Rect *orect)
    {


    }

    private int index = 3;
    public override bool Event(SDLMpc.Event ev)
    {
        GLib.debug("KEY: %i", ev.command);
        int current = -1;
        if(ev.type == SDLMpc.EventType.KEY) {
            switch(ev.command)
            {
                case EventCommand.K_1:
                    current = 1;
                break;
               case EventCommand.K_2:
                current = 2;
                break;
               case EventCommand.K_3:
                current = 3;
                break;
               case EventCommand.K_4:
                current = 4;
                break;
               case EventCommand.K_5:
                current = 5;
                break;
               case EventCommand.K_6:
                current = 6;
                break;
               case EventCommand.K_7:
                current = 7;
                break;
               case EventCommand.K_8:
                current = 8;
                break;
               case EventCommand.K_9:
                current = 9;
                break;
               case EventCommand.K_0:
                current = 0;
                break;
               default:
                   break;
            }
        }
        if(current >= 0) {
            if(index == 3) {
                if(current >= 0 && current <= 2) {
                    alarm_hour = alarm_hour%10+current*10;
                }
            }else if (index == 2) {
                if((alarm_hour > 20 && current >= 0 && current <= 4) ||
                    (alarm_hour < 20)
                )
                
                {
                    alarm_hour = (alarm_hour -alarm_hour%10)+current;
                }
            }else if (index == 1) {
                if(current >= 0 && current <= 5) {
                    alarm_minute = alarm_minute%10+current*10;
                }
            }else {
                alarm_minute = alarm_minute - alarm_minute%10+current;
            }

            index--;
            if(index < 0) index = 3;
            hour_label.set_text("%02u".printf(alarm_hour));
            minute_label.set_text("%02u".printf(alarm_minute));
        }
        return false;
    }

}
