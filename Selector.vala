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


class Selector : SDLWidget, SDLWidgetDrawing, SDLWidgetMotion, SDLWidgetActivate
{
    private Main m;
    private List<Item> entries;
    private unowned List<unowned Item> current= null;

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
        i.button = new SDLMpc.Button(this.m,0,0,(uint16)this.w, 50,item.get_name());
        i.button.x_align = 0.03;
        i.widget = item;
        entries.append(i);

        this.children.append(i.button);

        i.button.b_clicked.connect((source) => {
            this.children = null;
            this.current = null;
            this.children.append(item);
            if(item is SDLMpc.SDLWidgetActivate) {
                (item as SDLMpc.SDLWidgetActivate).activate();
            }

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
        foreach ( var i in entries)
        {
            i.widget.do_Tick(t);
        }
    }
    public void Home()
    {
        this.children=  null;
        int top = offset;
        foreach (Item i in entries)
        {
            i.button.y = top;
            i.button.set_highlight(false);
            i.button.update_text(i.widget.get_name());
            this.children.append(i.button);
            top += i.button.h+5;
        }
        current = entries.first();
        if(current != null)
        {
            current.data.button.set_highlight(true);
        }
        m.redraw();

    }
    
    public override bool Event(SDLMpc.Event ev)
    {
        if(current == null && ev.type == SDLMpc.EventType.KEY)
        {
            if (ev.command == EventCommand.BROWSE) {
                GLib.debug("Return home: %s", this.get_name());
                Home();
                return true;
            }
        }
        if(current == null) return false;
        if(ev.type == SDLMpc.EventType.KEY)
        {
            if(ev.command == SDLMpc.EventCommand.UP)
            {
                if(current.prev != null)
                {
                    current.data.button.set_highlight(false);
                    current = current.prev;
                    current.data.button.set_highlight(true);
                }
                return true;
            }
            else if(ev.command == SDLMpc.EventCommand.DOWN)
            {
                if(current.next != null)
                {
                    current.data.button.set_highlight(false);
                    current = current.next;
                    current.data.button.set_highlight(true);
                }
                return true;
            } else if(ev.command == SDLMpc.EventCommand.RIGHT)
            {
                GLib.debug("Select: %s", current.data.widget.get_name());
                this.children = null;
                this.children.append(current.data.widget);
                if(current.data.widget is SDLMpc.SDLWidgetActivate) {
                    (current.data.widget as SDLMpc.SDLWidgetActivate).activate();
                }
                this.current = null;
                m.redraw();
                return true;
            }
        }
        return false;
    }


    /**
     * Handle dragging events
     */
    private int start = -1;
    private int offset = 0;
    public bool motion(int x, int y, bool pushed, bool released)
    {
        if(current == null) return false;
        if(pushed) start = y;
        offset = y-start;
        if(released){
            offset = 0;
            start = 0;
        }
        if(offset > 10) {
            Home();
            m.redraw();
        }
        return false;
    }

    public void activate()
    {
        GLib.debug("Selector activate");
        offset = 0;start =0;
        this.Home();
    }
}
