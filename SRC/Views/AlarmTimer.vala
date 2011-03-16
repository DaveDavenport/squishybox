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
	public bool enabled
	{
		get
		{
			return _enabled;
		}
		set
		{
			_enabled = value;
			changed();
		}
	}
	/* The minute */
	private uint _minute = 0;
    public uint minute {
           get
           {
            return _minute;
           }
           set
           {
            _minute = value;
            changed();
           }
    }
	/* The hour */
	private uint _hour = 8;
    public uint hour {
           get
           {
            return _hour;
           }
           set
           {
            _hour = value;
            changed();
           }
    }
	/* The action to perform */
	public enum Action
	{
		START_PLAYBACK,
		STOP_PLAYBACK
	}
	public Action action = Action.START_PLAYBACK;

	public AEvent()
	{
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

	/** check each alarm each minute */
	Time old_time;
	public override void Tick (time_t now)
	{
		Time new_time = Time.local(now);
		if(old_time.minute != new_time.minute ||
			old_time.hour != new_time.hour
			)
		{
			foreach (AEvent e in alarms)
			{
				e.check(new_time);
			}
			old_time = new_time;
		}

	}
	/**
	 * Handle a long click, a long click here removes the alarm entry
	 */
	private void event_button_long_clicked_callback(Button butt)
	{
		AEvent event = butt.get_data("event");
		this.alarms.remove((owned)event);
		this.m.notification.push_mesg("Removed 1 Alarm");
		save_alarms();
		update();
	}
	private void add_ae(AEvent ea)
	{
		var butt = new Button(this.m, 0,0, (uint16)this.w, 38,
			ea.get_name());

		ea.changed.connect((source) =>
		{
			butt.update_text(source.get_name());
		});
		var edit_win = new EditAlarmTimer(m, this, ea,0,0, (int)this.w, (int)this.h);

		this.s.add(butt,edit_win);

		butt.set_data("event", ea);
		butt.long_clicked.connect(this.event_button_long_clicked_callback);
	}
	/**
	 * Rebuild the complete list.
	 */
	private void update()
	{
		/* Clear the list */
		s.clear();
		/* Add an Add button */
		var but = new Button(this.m, 0,0,(uint16)this.w, 38, "Add");
		but.b_clicked.connect((source)=>
		{
			AEvent e = new AEvent();
				add_ae(e);
				this.alarms.append((owned)e);
				save_alarms();
				e.changed.connect((source) =>
			{
				this.save_alarms();
			});
		});
		this.s.add_widget(but);
		/* Add an entry for each AEvent */
		foreach(AEvent e in alarms)
		{
			add_ae(e);
		}
	}

	/* The list widget */
	private Selector s;

	/* Constructor */
	public AlarmTimer(Main m,int x, int y, int w, int h, int bpp)
	{
		/* Set constructor variables to SDLWidget */
		this.m = m;
		this.x = x; this.y  = y; this.w = w; this.h = h;

		s = new Selector(m,x,y,w,h,bpp);

		this.children.append(s);
		load_alarms();
		update();
	}

	~AlarmTimer()
	{
	}
	/*********************************
	 * Storing and loading of files   *
	 *********************************/
	/** Save the alarms to a file */
	private void save_alarms()
	{
		string output = "";
		foreach(AEvent e in alarms)
		{
			output += "%i:%i:%u:%u\n".printf((int)(e.action),(int)(e.enabled),e.hour,e.minute);
		}
		try
		{
			GLib.FileUtils.set_contents("alarms.txt", output);
		}
		catch(GLib.Error err)
		{
			GLib.error("Failed to write alarms.txt: %s", err.message);
		}
	}
	/** Load the alarm file */
	private void load_alarms()
	{
		string? input = null;
		try
		{
			GLib.FileUtils.get_contents("alarms.txt",out input);
			if(input != null)
			{
				foreach(var line in input.split("\n"))
				{
					string[] split = line.split(":");
					if(split.length == 4)
					{
						AEvent e = new AEvent();
						e.action = (AEvent.Action)split[0].to_int();
						e.enabled = (bool)split[1].to_int();
						e.hour = (uint)split[2].to_int();
						e.minute = (uint)split[3].to_int();
						alarms.append(e);
						e.changed.connect((source) =>
						{
							this.save_alarms();
						});
					}
				}
			}
		}
		catch (GLib.Error err)
		{
			GLib.warning("Failed to load alarms.txt file: %s", err.message);
		}
	}
}


class EditAlarmTimer : SDLWidget
{
	/* Pointer to the main object */
	private weak Main m;
	private AEvent alarm_event;
	private CheckBox check;

    private SpinButton h_n = null;
    private SpinButton ht_n = null;
    private SpinButton m_n = null;
    private SpinButton mt_n = null;

	public EditAlarmTimer(Main m, AlarmTimer p, AEvent ae, int x, int y, int w, int h)
	{
		/* Set constructor variables to SDLWidget */
		this.alarm_event = ae;
		this.m = m;
		this.parent = p;
		this.x = x; this.y  = y; this.w = w; this.h = h;

		this.check = new CheckBox(this.m,
			(int16) 5,
			(int16) 5,
			(uint16)this.w-10,
			(uint16) 38,
			"Enabled",this);
        this.check.active = this.alarm_event.enabled;
        this.check.toggled.connect((source, state) =>
		{
			if(this.alarm_event.enabled != state)
			{
				this.alarm_event.enabled = state;
			}
		});
		this.children.append(this.check);
		this.add_focus_widget(this.check);

        /* Add label */
        var l = new Label(this.m, FontSize.NORMAL, (int16)20,(int16)40,100, 38,this);
        l.set_text("Time:");
        this.children.append(l);


        ht_n = new SpinButton(this.m, 120,40,this);
        this.children.append(ht_n);
        ht_n.set_range(0,2);
        ht_n.set_value((int)(this.alarm_event.hour/10));
        this.add_focus_widget(ht_n);

        h_n = new SpinButton(this.m, 150,40,this);
        h_n.set_range(0,9);
        h_n.set_value((int)(this.alarm_event.hour%10));
        this.children.append(h_n);
        this.add_focus_widget(h_n);

        l = new Label(this.m, FontSize.NORMAL, (int16)180,(int16)40,100, 38,this);
        l.set_text(":");
        this.children.append(l);

        mt_n = new SpinButton(this.m, 210,40,this);
        mt_n.set_range(0,5);
        mt_n.set_value((int)(this.alarm_event.minute/10));
        this.children.append(mt_n);
        this.add_focus_widget(mt_n);

        m_n = new SpinButton(this.m, 240,40,this);
        m_n.set_range(0,9);
        m_n.set_value((int)(this.alarm_event.minute%10));
        this.children.append(m_n);
        this.add_focus_widget(m_n);

        ht_n.notify["val"].connect((source)=>{
            int val = ht_n.val;
            if(val == 2) h_n.set_range(0,3);
            else h_n.set_range(0,9);
            this.alarm_event.hour = ht_n.val*10+h_n.val;
        });
        h_n.notify["val"].connect((source)=>{
            this.alarm_event.hour = ht_n.val*10+h_n.val;
        });
        mt_n.notify["val"].connect((source)=>{
            this.alarm_event.minute= mt_n.val*10+m_n.val;
        });
        m_n.notify["val"].connect((source)=>{
            this.alarm_event.minute= mt_n.val*10+m_n.val;
        });
	}
}
