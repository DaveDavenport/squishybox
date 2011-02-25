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

class BackgroundDrawer : SDLWidget, SDLWidgetDrawing
{
    private Surface sf;
    private unowned Main m;


    public int period_time {
        set;
        get;
        default=30;
    }

    /**
     * List of backgrounds
     */
    private List<string>  backgrounds       = null;
    private unowned List<string> current_bg    = null;
    private string directory = "Wallpapers/";




    public BackgroundDrawer(Main m,int x, int y, int w, int h, int bpp)
    {
        this.m = m;

        this.x = x;
        this.y = y;
        this.w = w;
        this.h = h;

        Regex regex = null;
        try{
		    regex = new Regex (".*\\.png$");
        }catch (GLib.Error e) {
            GLib.error("Failed to create regex");
        }
        /* */
        try{
            GLib.Dir a = GLib.Dir.open(directory);
            for(var file = a.read_name(); file != null; file = a.read_name())
            {
				if(regex.match(file)) {
	                backgrounds.append(file); 
				}
			}
        }catch (GLib.Error e)
        {

        }

        if(backgrounds.length() > 0) {
            current_bg = backgrounds.first();
            sf = SDLImage.load(directory+current_bg.data);
        }else {
            /* Failsafe */
            sf = SDLImage.load("test.png");
        }
		if(sf != null)
			sf = sf.DisplayFormat();
		this.require_redraw = true;
	}

    /* Return the surface it needs to draw */
    public void draw_drawing(Surface screen, SDL.Rect *rect)
    {
		sf.blit_surface(*rect, screen, *rect);
    }


    private time_t last_time = time_t(); 
    public override void Tick(time_t now)
    {
        if(current_bg == null) return;
        if((now - last_time)  > period_time){
            if(current_bg.next != null) {
                current_bg = current_bg.next;
            }else{
                current_bg = current_bg.first();
            }
            GLib.debug("Change background to: %s\n", current_bg.data);
            sf = SDLImage.load(directory+current_bg.data);
            sf = sf.DisplayFormat();
			this.require_redraw = true;
            last_time = now; 
        }
    }
    ~Background()
    {
        GLib.debug("BG destroy\n");
    }
}
