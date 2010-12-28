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
            if(entity.get_type() == MPD.Entity.Type.DIRECTORY)
            {
                weak MPD.Directory directory = entity.get_directory();
                string path;
                path = directory.path;
                var a = new MpdDatabaseView(
                        this.m, this.x, this.y, this.w, (uint32)this.h,32,
                        path
                        );
                s.add_item(a); 
                i++;
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
        /*
        m.MI.player_connection_changed.connect((source, connect) => {
                if(connect) {
                    source.database_get_directory(database_directory,directory); 
                }
        });
*/

    }
    private bool init = false;
    public bool activate()
    {
        if(!init) {
            m.MI.database_get_directory(database_directory, directory);
            init = true;
        }
//        this.s.activate();
        return false;
    }


}
