/* xnoise-dockable-dynamic-playlist.vala
 *
 * Copyright (C) 2012  Jörn Magens
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  The Xnoise authors hereby grant permission for non-GPL compatible
 *  GStreamer plugins to be used and distributed together with GStreamer
 *  and Xnoise. This permission is above and beyond the permissions granted
 *  by the GPL license by which Xnoise is covered. If you modify this code
 *  you may extend this exception to your version of the code, but you are not
 *  obligated to do so. If you do not wish to do so, delete this exception
 *  statement from your version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA.
 *
 * Author:
 *     Jörn Magens
 */

using Gtk;


private class Xnoise.DockableDynamicPlaylists : DockableMedia {
    
    public override string name() {
        return "MostPlayedPlaylist";
    }
    
    public override string headline() {
        return _("Most Played");
    }
    
    public override DockableMedia.Category category() {
        return DockableMedia.Category.PLAYLIST;
    }

    public override Gtk.Widget? get_widget(MainWindow window) {
        var tv = new PlaylistTreeView(window);
        var sw = new ScrolledWindow(null, null);
        sw.add(tv);
        return sw;
    }

    public override Gdk.Pixbuf get_icon() {
        Gdk. Pixbuf pixb_playlist = null;
        Gtk.Invisible i = new Gtk.Invisible();
        try {
            if(IconTheme.get_default().has_icon("xn-playlist"))
                pixb_playlist = IconTheme.get_default().load_icon("xn-playlist", 16, IconLookupFlags.FORCE_SIZE);
            else
                pixb_playlist = i.render_icon_pixbuf(Gtk.Stock.YES, IconSize.BUTTON);
        }
        catch(Error e) {
        }
        return pixb_playlist;
    }
}


