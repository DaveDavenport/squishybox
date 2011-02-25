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
 * A playlist view. 
 *
 */
class MpdDatabaseView : SDLWidget, SDLWidgetActivate
{

    private Main m;
    private Selector s;
    private string directory  = "";
    private string basename;



    public override unowned string get_name()
    {
        return basename;
    }
    public void database_directory(List<MPD.Entity>? entity_list)
    {
        int i = 0;
        GLib.debug("data directory: %u\n", entity_list.length());
        foreach(weak MPD.Entity entity in entity_list)
        {
            SDLWidget b = null;
            string path = null;
            if(entity.get_type() == MPD.Entity.Type.DIRECTORY)
            {
                weak MPD.Directory directory = entity.get_directory();
                path = directory.path;
                var a = new MpdDatabaseView(
                        this.m, this.x, this.y, this.w, (uint32)this.h,32,
                        path
                        );
                b = s.add_item(a, Theme.Icons.FOLDER); 

                (b as Button).long_clicked.connect((source)=>{
                        this.m.MI.queue_add_song(path);
                        this.m.notification.push_mesg("Added 1 directory"); 
                });

                (b as Button).key_pressed.connect((source, key)=>
                {
                  GLib.debug("Add key pressed connect");
                  switch(key) 
                  {
                      case EventCommand.MORE:
                      {
                          GLib.debug("Add more: %s\n",path); 
                          if(path != null) 
                          {
                               this.m.MI.queue_add_song(path);
                               this.m.notification.push_mesg("Added 1 directory"); 
                               return true;
                           }
                      }
                      break;
                      default:
                            break;
                   }
                   return false;
                });
                i++;
            }else if (entity.get_type() == MPD.Entity.Type.SONG)
            {
                weak MPD.Song song = entity.get_song();
                path = song.uri;
                b = new Button(this.m, (int16)this.x, (int16)this.y, (uint16)this.w,38,format_song_title(song),
                Theme.Icons.MUSIC);
                s.add_widget(b);
                (b as Button).b_clicked.connect((source)=>{
                    this.m.MI.queue_add_song(path);
                    this.m.notification.push_mesg("Added 1 song"); 
                });
                (b as Button).long_clicked.connect((source)=>{
                        this.m.MI.queue_add_song(path);
                        this.m.notification.push_mesg("Added 1 song"); 
                });
                (b as Button).key_pressed.connect((source, key)=>
                {
                  GLib.debug("Add key pressed connect");
                  switch(key) 
                  {
                      case EventCommand.MORE:
                      {
                          GLib.debug("Add more: %s\n",path); 
                          if(path != null) 
                          {
                               this.m.MI.queue_add_song(path);
                               this.m.notification.push_mesg("Added 1 song"); 
                               return true;
                           }
                      }
                      break;
                      default:
                            break;
                   }
                   return false;
                });

            }
        }

    }

    public MpdDatabaseView (Main m, int x, int y, uint w, uint h, int bpp, string? direct)
    {
        this.m = m;

        this.x = x;
        this.y = y;
        this.w = w;
        this.h = h;
        if(direct!= null) {
            this.directory = direct;
            basename = GLib.Path.get_basename(direct);
        }else{
            basename = "Database";
        }

        s = new Selector(m,x,y,(int)w,(int)h,bpp);
        this.children.append(s);


        m.MI.player_status_changed.connect((source, status) => 
        {
        });

    }
    private bool init = false;
    public bool activate()
    {
        if(!init) {
            m.MI.database_get_directory(database_directory, directory);
            init = true;
        }
        return false;
    }
    public void leave()
    {
        if(init){
            GLib.debug("Clearing entries");
            this.s.clear();
            init = false;
        }
    }

}

