using Posix;

class DisplayControl : GLib.Object
{
    const string fn_power       = "/sys/class/backlight/mxc_ipu_bl.0/bl_power";
    const string fn_brightness  = "/sys/class/backlight/mxc_ipu_bl.0/brightness";


    /** 
     * Constructor 
     */

    public DisplayControl ()
    {
        GLib.debug("Create brightness control");
    }

    public bool getEnabled()
    {
        bool retv = true;
        FILE fp = FILE.open(fn_power, "r");
        if(fp != null)
        {
            char  buffer[10];
            string a;
            if((a = fp.gets(buffer)) != null)
            {
                GLib.debug("getEnabled(): '%s'".printf(a));
                if(a[0] == '0') retv = true;
                if(a[0] == '1') retv = false;
            }
        }
        else
        {
            GLib.warning("Failed to getEnabled()");
        }
        return retv;
    }

    public void setEnabled(bool enabled)
    {
        FILE fp = FILE.open(fn_power, "w");
        if(fp != null) {

            if(enabled) {
                fp.putc('0');
            }else{
                fp.putc('1');
            }
        }
        else
        {
            GLib.warning("Failed to setBrightness");
        }
    }

    public void setBrightness(uint8 brightness)
    {
        FILE fp = FILE.open(fn_brightness, "w");
        if(fp != null)
        {
            string data = "%u".printf(brightness);;
            fp.puts(data);
        }
        else
        {
            GLib.warning("Failed to getBrightness");
        }
    }

    public uint8 getBrightness()
    {
        uint8 retv = 128;
        FILE fp = FILE.open(fn_brightness, "r");
        if(fp != null)
        {
            char buffer[32];
            string data;
            if((data = fp.gets(buffer)) != null)
            {
                retv = (uint8)(data.to_int());
            }
        }
        else
        {
            GLib.warning("Failed to getBrightness");
        }
        return retv;
    }

}
