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


namespace SDLMpc
{
    class Theme
    {
        [Compact]
        private class ElementItem {
            public SDL.Surface normal = null;
            public SDL.Surface highlight = null;
            public SDL.Surface pressed = null;
        }

        private const string directory = "Data";
        private string _theme_name = "Basic";

        private string theme_name {
            get{
                return _theme_name;
            }
            set{
                _theme_name = value;
                /* update list of surfaces */
            }
        }

        /* A list of available Interface elements */
        public enum Element {
            /* Large button 38x480 */
            BUTTON_LARGE,
            /* Checkbox 38x38 */
            CHECK_BOX,
            /* Checkbox 38x38 but checked */
            CHECK_BOX_ACTIVE,
            /* The notification popup background */
            NOTIFICATION,
            /* Header background */
            HEADER,
            /* Button small (38x28) */
            BUTTON_SMALL,
            /* */
            NUM_ELEMENTS
        }
        private string[] element_names = { 
            "button_large",
            "check_button",
            "check_button_active",
            "notification",
            "header",
            "button_small"
        };
        public enum ElementState {
            NORMAL,
            HIGHLIGHT,
            PRESSED,
            NUM_STATES
        }
        private string[] state_names = {
            "",
            "_highlight",
            "_pressed"
        };



        private ElementItem?[] surfaces = new ElementItem[Element.NUM_ELEMENTS]; 
        /* This 'pre-loads' all the surfaces */
        private void update_surfaces()
        {
            for(int i=0; i < Icons.NUM_ICONS;i++){
                icons[i] = null;
            }
             for(int i=0; i < Element.NUM_ELEMENTS; i++)
             {
                /* Create element when needed */
                if(surfaces[i] == null){
                    surfaces[i] = new ElementItem();
                }

                for(int j = 0; j<ElementState.NUM_STATES;j++)
                {
                    string filename = "%s%s.png".printf(element_names[i], state_names[j]);
                    string Path = GLib.Path.build_filename(directory, _theme_name, filename);
                    if(j == ElementState.NORMAL) {
                        surfaces[i].normal = SDLImage.load(Path);
                        if(surfaces[i].normal != null)
                            surfaces[i].normal = surfaces[i].normal.DisplayFormatAlpha();
                    }else if (j == ElementState.HIGHLIGHT) {
                        surfaces[i].highlight = SDLImage.load(Path);
                        if(surfaces[i].highlight != null)
                            surfaces[i].highlight = surfaces[i].highlight.DisplayFormatAlpha();
                    }else if (j == ElementState.PRESSED) {
                        surfaces[i].pressed = SDLImage.load(Path);
                        if(surfaces[i].pressed != null)
                            surfaces[i].pressed = surfaces[i].pressed.DisplayFormatAlpha();
                    }
                }
             }
        }

        public unowned SDL.Surface? get_element(Theme.Element element, Theme.ElementState state)
        {
            weak ElementItem e = this.surfaces[element];
            switch(state)
            {
                case ElementState.HIGHLIGHT:
                    return e.highlight;
                case ElementState.PRESSED:
                    return e.pressed;
                default:
                    return e.normal;
            }
        }

        /* List of available icons */
        private SDL.Surface?[] icons = new SDL.Surface[Icons.NUM_ICONS];
        public enum Icons {
            MUSIC,
            FOLDER,
            PLAY,
            PAUSE,
            STOP,
            FORWARD,
            BACKWARD,
            NUM_ICONS,
            NO_ICON
        }
        private string[] icon_names = {
            "music",
            "folder",
            "play",
            "pause",
            "stop",
            "forward",
            "backward"
        };

        public unowned SDL.Surface? get_icon(Theme.Icons icon)
        {
            if(icons[icon] == null)
            {
                string filename = "%s.png".printf(icon_names[icon]);
                string Path = GLib.Path.build_filename(directory, _theme_name, filename);
                icons[icon]= SDLImage.load(Path);
                if(icons[icon]!= null)
                    icons[icon] = icons[icon].DisplayFormatAlpha();
            }
            return icons[icon];
        }


        /**
         * Constructor 
         */
        public Theme()
        {
            update_surfaces();
        }

    }
}
