/* xnoise-testplugin.vala
 *
 * Copyright (C) 2009  Jörn Magens
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
 * 	Jörn Magens
 */

using Gtk;
using Xnoise;
using Xnoise.PluginModule;

public class TestPlugin : GLib.Object, IPlugin {
	private Gtk.Button b;
	private unowned PluginModule.Container _owner;
	
	public PluginModule.Container owner {
		get {
			return _owner;
		}
		set {
			_owner = value;
		}
	}

	public Xnoise.Main xn { get; set; }
	
	public string name { 
		get {
			return "Test";
		} 
	}

	private void on_b_clicked(Gtk.Button sender) {
		sender.label = sender.label + "_1";
	}

	public bool init() {
		return true;
	}

	public void uninit() {
	}

	public Gtk.Widget? get_settings_widget() {
		b = new Gtk.Button.with_label("bingo");
		b.clicked.connect(on_b_clicked);
		return b;
	}

	public bool has_settings_widget() {
		return true;
	}
}

