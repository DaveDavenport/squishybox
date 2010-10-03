using SDL;
using SDLTTF;
using SDLImage;
using MPD;
using Posix;
using SDLMpc;

[compact]
private class Item 
{
    public SDLMpc.Button    button;
    public SDLWidget        widget;

}


class Selector : SDLWidget,  SDLWidgetMotion, SDLWidgetActivate
{
    private Main m;
    private bool in_sub_item = false;
    private List<Item> entries;

    private unowned List<unowned Item> current= null;
    private unowned List<unowned Item> current_start = null;
    private unowned List<unowned Item> current_end= null;



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
    }
    public Selector(Main m, int x, int y, int w, int h, int bpp)
    {
        this.m = m;

        this.x = x;
        this.y = y;
        this.w = w;
        this.h = h;


    }

    public void add_item(SDLWidget item)
    {
        Item i = new Item();
        i.button = new SDLMpc.Button(
                this.m,
                0,0,
                (uint16)this.w, 40,item.get_name());
        i.button.x_align = 0.03;
        i.widget = item;
        entries.append(i);

        i.button.b_clicked.connect((source) => {
                if(item is SDLMpc.SDLWidgetActivate) {
                    var r = (item as SDLMpc.SDLWidgetActivate).activate();
                    if(r) return;
                }
                this.children = null;
                this.current = null;
                this.children.append(item);
                this.in_sub_item = true;
                this.require_redraw = true;
                });
        Home();
    }

    /* Return the surface it needs to draw */
    public void draw_drawing(Surface screen)
    {
    }

    public override void do_Tick(time_t t)
    {
        this.Tick(t);
        if(current != null) current.data.button.Tick(t);
        foreach ( var i in entries)
        {
            i.widget.do_Tick(t);
        }
    }
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
        int top = 0;
        unowned List<Item> start = current_start;

        do{
            start.data.button.y = top;
            start.data.button.set_highlight(false);
            start.data.button.update_text(start.data.widget.get_name());
            this.children.append(start.data.button);
            top += start.data.button.h+3;
            start = start.next;
            current_end = start;
        }while((top+5) < this.h && start != null);
        GLib.debug("top: %i\n", top);

        if(current != null)
        {
            current.data.button.set_highlight(true);
        }
        this.require_redraw = true;
    }

    public override bool check_redraw()
    {
        if(!this.in_sub_item) {
            foreach(Item i in entries)
            {
                if(i.widget.require_redraw) {
                    GLib.debug("redraw button text");
                    i.button.update_text(i.widget.get_name());
                    i.widget.require_redraw = false;
                    this.require_redraw = true;
                }
            }
            return this.require_redraw;
        }

        if(this.require_redraw) return true;
        foreach ( var child in children) 
        {
            if(child.check_redraw()) {
                return true;
            }
        }
        return false;
    }

    public override bool Event(SDLMpc.Event ev)
    {
        if(in_sub_item && (ev.type == SDLMpc.EventType.KEY || ev.type == SDLMpc.EventType.COMMANDS))
        {
            if (ev.command == EventCommand.BROWSE) {
                GLib.debug("Return home: %s", this.get_name());
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
                return true;
            } else if(ev.command == SDLMpc.EventCommand.RIGHT)
            {
                GLib.debug("Select: %s", current.data.widget.get_name());
                if(current.data.widget is SDLMpc.SDLWidgetActivate) {
                    var r = (current.data.widget as SDLMpc.SDLWidgetActivate).activate();
                    if(r) return true;
                }
                this.in_sub_item = true;
                this.children = null;
                this.children.append(current.data.widget);
                //this.current = null;
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
        /*
           if(current == null) return false;
           if(pushed) {
           d_start = y;
           start = y;
           }
           offset += y-start;
           start = y;
           if(offset > 0 ) offset = 0;
           if(released){
           start = 0;
           d_start = 0;
           }
        //if(offset.abs() > 10) {
        Home();
        this.require_redraw = true;;
        //}
         */
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
