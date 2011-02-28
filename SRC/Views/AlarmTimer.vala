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

/**
 * This class represent and executes an alarm event
 * 
 */
public class AEvent 
{
    /* if enabled */
    private bool _enabled = false;
    public bool enabled {
        get {
            return _enabled;
        }
        set {
            _enabled = value;
            changed();
        }
    } 
    /* The minute */
    public uint minute;
    /* The hour */
    public uint hour;
    /* The action to perform */
    public enum Action {
        START_PLAYBACK,
            STOP_PLAYBACK
    }
    public Action action = Action.START_PLAYBACK;

    public AEvent()
    {
        this.enabled = false;
        this.minute = 0;
        this.hour = 8;

    }

    /* Call this function every minute (not more then once)  */
    public void check(Time now)
    {
        if(this.enabled &&
                this.hour == now.hour &&
                this.minute == now.minute)
        {
            this.fire();
        }
    }
    private void fire()
    {

    }

    public string get_name()
    {
        string retv = "Alarm: %02u:%02u".printf(this.hour, this.minute);
        if(!this.enabled) retv+= " (disabled)";
        return retv;
    }

    public signal void changed();
}
class AlarmTimer : SDLWidget
{

    private List<AEvent> alarms = null;
    private weak List<AEvent> current_alarm = null;

    /* Pointer to the main object */
    private weak Main m;

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
            foreach (AEvent e in alarms) {
                e.check(new_time);
            }
            old_time = new_time;
        }


    }
    private void add_ae(AEvent ea)
    {
        var butt = new Button(this.m, 0,0, (uint16)this.w, 38, 
                ea.get_name());
        ea.changed.connect((source) => {
                butt.update_text(source.get_name());
                });
        var edit_win = new EditAlarmTimer(m, this, ea, this.x, this.y, (int)this.w, (int)this.h);

        this.s.add(butt,edit_win);

        butt.long_clicked.connect((source)=> {
                this.alarms.remove(ea);
                this.m.notification.push_mesg("Removed 1 Alarm");
                update();
                });
    }
    private void update()
    {
        s.clear();
        var but = new Button(this.m, 0,0,(uint16)this.w, 38, "Add");
        but.b_clicked.connect((source)=>{
                AEvent e = new AEvent();
                add_ae(e);
                this.alarms.append((owned)e);
                });
        this.s.add_widget(but);
        foreach(AEvent e in alarms)
        {
            add_ae(e);
        }
    }

    private Selector s;

    public AlarmTimer(Main m,int x, int y, int w, int h, int bpp)
    {
        /* Set constructor variables to SDLWidget */
        this.m = m;
        this.x = x; this.y  = y; this.w = w; this.h = h;

        s = new Selector(m,x,y,w,h,bpp);
    
        this.children.append(s);

        update();
    }
}

class EditAlarmTimer : SDLWidget
{
    /* Pointer to the main object */
    private weak Main m;
    private weak AlarmTimer parent;
    private AEvent alarm_event;
    private CheckBox check;

    public EditAlarmTimer(Main m, AlarmTimer p, AEvent ae, int x, int y, int w, int h)
    {
        /* Set constructor variables to SDLWidget */
        this.alarm_event = ae;
        this.m = m;
        this.parent = p;
        this.x = x; this.y  = y; this.w = w; this.h = h;

        this.check = new CheckBox(this.m,
                (int16) this.x+5,
                (int16) this.y+5,
                (uint16)this.w-10,
                (uint16) 38,
                "Enabled");
        this.check.toggled.connect((source, state) =>{
            if(this.alarm_event.enabled != state) {
                this.alarm_event.enabled = state;
            }
        });
        this.children.append(this.check);
        this.add_focus_widget(this.check);


    }
}
