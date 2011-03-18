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

private class Item 
{
    public enum ItemType {
        SUBMENU,
        WIDGET
    }
    public bool own_button = false;
    public ItemType type;
    public SDLMpc.Button    button;
    public SDLWidget        widget;

}


class Selector : SDLWidget,  SDLWidgetMotion, SDLWidgetActivate
{
    /* Fixed offset between rows */
    private const int OFFSET =5;
    private Main m;
    private bool in_sub_item = false;
    private List<Item> entries;

    private unowned List<unowned Item> current= null;
    private unowned List<unowned Item> current_start = null;
    private unowned List<unowned Item> current_end= null;


	public override unowned string get_name()
	{
		return "Selector";
	}

    public void clear()
    {
        current = null;
        current_start = null;
        current_end = null;
        entries = null;

        this.require_redraw = true;
    }
    ~Selector()
    {
        GLib.debug("Quit: %s", this.get_name());
        this.clear();
    }
    public Selector(Main m, int x, int y, int w, int h, int bpp)
    {
        this.m = m;

        this.x = x;
        this.y = y;
        this.w = w;
        this.h = h;


    }
    public void add_widget(SDLWidget item)
    {

        Item i = new Item();
        i.type = Item.ItemType.WIDGET;
        i.widget = item;
        entries.append(i);
        Home();
    }

    private void button_pressed(Button but)
    {
        unowned Item i = but.get_data<unowned Item>("item");
        if(i.widget is SDLMpc.SDLWidgetActivate) {
            var r = (i.widget as SDLMpc.SDLWidgetActivate).activate();
            if(r) return;
        }
        this.children = null;
        this.current = null;
        this.children.append(i.widget);
        this.in_sub_item = true;
        this.require_redraw = true;
    }

    public void add(Button button, SDLWidget item)
    {
        Item i = new Item();
        i.type = Item.ItemType.SUBMENU;
        i.button = button;
        i.widget = item;

        i.button.set_data<unowned Item>("item", i);
        i.button.b_clicked.connect(button_pressed);
        entries.append(i);
        Home();
    }
    public SDLWidget add_item(SDLWidget item, Theme.Icons button_icon =  Theme.Icons.NO_ICON)
    {
        Item i = new Item();
        i.type = Item.ItemType.SUBMENU;
        i.button = new SDLMpc.Button(
                this.m,
                0,0,
                (uint16)this.w, 40,item.get_name(), button_icon);
        i.button.x_align = 0.03;
        i.widget = item;

        i.button.set_data<unowned Item>("item", i);
        i.button.b_clicked.connect(button_pressed);
        entries.append(i);
        Home();
        return i.button;
    }

    /* Return the surface it needs to draw */
    public void draw_drawing(Surface screen, SDL.Rect *orect)
    {
    }
/*
    public override void do_Tick(time_t t)
    {
        this.Tick(t);
        if(current != null){
            if(current.data.type == Item.ItemType.SUBMENU) {
                current.data.button.Tick(t);
            }
        }
        foreach ( var i in entries)
        {
            i.widget.do_Tick(t);
        }
    }
    */
    public void Home()
    {
        this.in_sub_item = false;
        this.children = null;
        if(current == null) {
            current = this.entries.first();
            current_start = current;
        }
        if(current == null) {
            this.require_redraw = true;
            return;
        }
        int top = this.y+OFFSET;
        unowned List<Item> start = current_start;

        do{
            if(start.data.type == Item.ItemType.SUBMENU)
            {
                start.data.button.y = top;
                start.data.button.set_highlight(false);
                if(start.data.own_button)
                    start.data.button.update_text(start.data.widget.get_name());
                this.children.append(start.data.button);
                top += (int)start.data.button.h+3;
            }
            else 
            {
                start.data.widget.focus = false;
                start.data.widget.y = top;
                this.children.append(start.data.widget);
                top += (int)start.data.widget.h+3;
            }
            start = start.next;
            current_end = start;
			GLib.debug("top: %i\n", top);
		}while((top+OFFSET) < (this.h + 38) && start != null);
        GLib.debug("top: %i\n", top);

        if(current != null)
        {
            if(current.data.type == Item.ItemType.SUBMENU)
            {
                current.data.button.set_highlight(true);
            }else{
                current.data.widget.focus = true;
            }
        }
        this.require_redraw = true;
    }

    public override bool check_redraw()
    {
        if(!this.in_sub_item) {
            foreach(Item i in entries)
            {
                if(i.type == Item.ItemType.SUBMENU) {
                    if(i.widget.require_redraw) {
                        GLib.debug("redraw button text");
                        if(i.own_button)
                            i.button.update_text(i.widget.get_name());
                        i.widget.require_redraw = false;
                    }
                }
            }
        }
        return this.require_redraw;
    }

    public override bool Event(SDLMpc.Event ev)
    {
        if(in_sub_item && (ev.type == SDLMpc.EventType.KEY || ev.type == SDLMpc.EventType.COMMANDS))
        {
            if (ev.command == EventCommand.BROWSE) {
                GLib.debug("Return home: %s", this.get_name());
                if(
                        this.current != null && 
                        this.current.data != null && 
                        this.current.data.widget != null) {
                    if(current.data.widget is SDLMpc.SDLWidgetActivate) {
                        (current.data.widget as SDLMpc.SDLWidgetActivate).leave();
                    }
                }
                Home();
                return true;
            }
        }
        if(in_sub_item) return false;
        if(ev.type == SDLMpc.EventType.KEY)
        {
            if(ev.command == SDLMpc.EventCommand.UP)
            {
                if(current.prev != null)
                {
                    if(current == current_start) {
                        current_start =current.prev;
                    }
                    current = current.prev;
                    Home();
                }
                else
                {
                    current = current.last();
                    current_start = current;
                    Home();
                }
                return true;
            }
            else if(ev.command == SDLMpc.EventCommand.DOWN)
            {
                if(current.next != null)
                {
                    if(current.next == current_end)
                    {
                        current_start = current_start.next;
                    }
                    current = current.next;
                    Home();
                }
                else {
                    current = current.first();
                    current_start = current;
                    Home();
                }
                return true;
            } else if(ev.command == SDLMpc.EventCommand.RIGHT)
            {
                GLib.debug("Select: %s", current.data.widget.get_name());
                if(current.data.type == Item.ItemType.SUBMENU)
                {
                    if(current.data.widget is SDLMpc.SDLWidgetActivate) {
                        var r = (current.data.widget as SDLMpc.SDLWidgetActivate).activate();
                        if(r) return true;
                    }
                }else{
                    if(current.data.widget is SDLMpc.SDLWidgetActivate) {
                        var r = (current.data.widget as SDLMpc.SDLWidgetActivate).activate();
                        return true;
                    }
                }
                this.in_sub_item = true;
                this.children = null;
                this.children.append(current.data.widget);
                this.current = null;
                this.require_redraw = true;
                return true;
            }
            else if(ev.command == SDLMpc.EventCommand.LEFT)
            {
                SDLMpc.Event nev = new SDLMpc.Event();
                nev.type = SDLMpc.EventType.COMMANDS;
                nev.command = SDLMpc.EventCommand.BROWSE;
                this.m.push_event((owned)nev);
                return true;
            }
        }
        return false;
    }


    /**
     * Handle dragging events
     */
    private int start = 0;
    private int d_start = 0;
    private int offset = 0;
    public bool motion(double x, double y, bool pushed, bool released)
    {
        if(current == null) return false;
        if(pushed) {
            d_start = (int)y;
            start = (int)y;
        }
        offset =  (int)(y-start);
         {
            if(offset > 42) {
                start = (int)y;
                if(current_start.prev != null){
                    GLib.debug("setting\n");
                    current_start = current_start.prev;
                    Home();
                }
            }
            if(offset <-42) {
                start = (int)y;
                if(current_start.next!= null){
                    GLib.debug("setting\n");
                    current_start = current_start.next;
                    Home();
                }
            }

         }

        GLib.debug("offset: %i", (int)x - start); 
        if(released){
            start = 0;
            d_start = 0;
        }
        //if(offset.abs() > 10) {
        Home();
        this.require_redraw = true;;
        //}
        return false;
    }

    public bool activate()
    {
        GLib.debug("Selector activate");
        offset = 0;start =0;
        this.Home();
        return false;
    }
}
