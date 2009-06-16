/* xnoise-plugin-loader.vala
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
 
public class Xnoise.PluginLoader : Object {
	private Type type;
	private Module module;
    public HashTable<string,IPlugin> plugin_hash;
	
    public signal void plugin_available(IPlugin plugin);
		
	private delegate Type InitModuleFunction();

	public PluginLoader() {
		assert (Module.supported());
		this.plugin_hash = new HashTable<string,Plugin>(str_hash, str_equal);
	}

	public bool load () {
		string path = Config.PLUGINSDIR + "libxnoisetest.la"; 
		print("path: %s\n", path);
		module = Module.open(path, ModuleFlags.BIND_LAZY);
		
		if (module == null) {
			return false;
		}
		print("Loaded %s\n", module.name());

		void* func;
		module.symbol("init_module", out func);
		InitModuleFunction init_module = (InitModuleFunction)func;
		if(init_module == null) return false;
		
//		module.make_resident ();
		type = init_module();
		add_plugin();
		return true;
	}
	
	public void add_plugin() {
		var plug = (IPlugin)Object.new(type);
		if(plug == null) {
			print("add plugin error\n");
			return;
		}
			
		this.plugin_hash.insert("Test", plug);
		this.plugin_available(plug);
	}
}
