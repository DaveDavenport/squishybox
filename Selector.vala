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


class Selector : SDLWidget, SDLWidgetDrawing
{
    private weak Main m;
    private List<Item> entries;
    private unowned Item current= null;

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
        int top = 0;
        foreach (Item i in entries)
        {
            i.button.y = top;
            this.children.append(i.button);
            top += i.button.h+5;
        }
        m.redraw();
    }

}
