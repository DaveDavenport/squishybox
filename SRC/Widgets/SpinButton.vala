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


class SpinButton : SDLWidget
{
    private Main m;
    private Label val_label;
    
    private int _val = 0;
    public int val{
        get{
            return _val;
        }
        set {
            _val = (value > max)?max:((value < min)?min:value);
        }
    }
    private int min = 0;
    private int max = 9;

    public void set_range(int min, int max)
    {
        this.min = min;
        this.max = max;
        val = (val > max)?max:((val < min)?min:val);
        val_label.set_text("%i".printf(val));
    }
    public void set_value(int value)
    {
        this.val = (value > max)?max:((value < min)?min:value);
        val_label.set_text("%i".printf(val));

    }

    public SpinButton(Main m, int x, int y, SDLWidget parent)
    {
        this.parent = parent;
        this.m = m;
        this.x = x;
        this.y = y;
        this.w = 38;
        this.h = 38;

        val_label = new Label(this.m, FontSize.NORMAL, 0,0,38,38,this);
        this.children.append(val_label);

        val_label.set_text("%i".printf(val));
        
        this.notify["focus"].connect((source)=>{
            val_label.focus = this.focus;
        });

    }

   public override bool Event(SDLMpc.Event ev)
   {
        if(!this.focus) return false;
       if((ev.type == SDLMpc.EventType.KEY || ev.type == SDLMpc.EventType.COMMANDS))
       {
           if (ev.command == EventCommand.K_1) {
                this.set_value(1);
           }
           else if (ev.command == EventCommand.K_2) {
                this.set_value(2);
           }
           else if (ev.command == EventCommand.K_3) {
                this.set_value(3);
           }
           else if (ev.command == EventCommand.K_4) {
                this.set_value(4);
           }
           else if (ev.command == EventCommand.K_5) {
                this.set_value(5);
           }
           else if (ev.command == EventCommand.K_6) {
                this.set_value(6);
           }
           else if (ev.command == EventCommand.K_7) {
                this.set_value(7);
           }
           else if (ev.command == EventCommand.K_8) {
                this.set_value(8);
           }
           else if (ev.command == EventCommand.K_9) {
                this.set_value(9);
           }
           else if (ev.command == EventCommand.K_0) {
                this.set_value(0);
           }
           else if (ev.command == EventCommand.LEFT) {
                this.set_value(this.val -1);
           }
           else if (ev.command == EventCommand.RIGHT){
                this.set_value(this.val +1);
           }
       }
        return false;
   }



}
