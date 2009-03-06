/* xnoise-parameter.vala
 *
 * Copyright (C) 2009  Jörn Magens
 *
 * This library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 * 	Jörn Magens
 */

using GLib;

public class Xnoise.Parameter : GLib.Object, IParameter {
	private static Parameter _instance;
	private SList<IParameter> IParameter_implementors;
	public int posX         { get; set; default = 300;}
	public int posY         { get; set; default = 300;}
	public int winWidth     { get; set; default = 1000;}
	public int winHeight    { get; set; default = 500;}
	public bool winMaxed    { get; set; default = false;}

	public Parameter() {
			IParameter_implementors = new GLib.SList<IParameter>();
			data_register(this);
	}

	public static Parameter instance() {
		if (_instance == null) _instance = new Parameter();
		return _instance;
	}

	private string _build_file_name() {
		_create_file_folder();
		return GLib.Path.build_filename(GLib.Environment.get_home_dir(), ".xnoise/xnoise.ini", null);
	}

	private void _create_file_folder() { 
		string SettingsFolder = GLib.Path.build_filename(GLib.Environment.get_home_dir(), ".xnoise", null);
		string SettingsKeyFile = GLib.Path.build_filename(GLib.Environment.get_home_dir(), ".xnoise/xnoise.ini", null);
		if (FileUtils.test(SettingsFolder, FileTest.EXISTS) == false) {
			DirUtils.create(SettingsFolder, 0700);
		}
		if (FileUtils.test(SettingsKeyFile, FileTest.EXISTS) == false) {
//			File.create(SettingsKeyFile, 0700); TODO
		}
	}

	public void data_register(IParameter obj) {
		IParameter_implementors.remove(obj);
		IParameter_implementors.append(obj);
	}

	public void read_from_file() {
		KeyFile file;
		file = new GLib.KeyFile();
		try {
			string filename = _build_file_name();
			file.load_from_file(filename, GLib.KeyFileFlags.NONE);
		} catch (GLib.Error ex) {
			return;
		}
		foreach(weak IParameter c in IParameter_implementors) {
			try {
				c.read_data(file);
			} 
			catch (GLib.KeyFileError e) {
			}
		}
	}

	public void write_to_file() {
		FileStream stream = GLib.FileStream.open(_build_file_name(), "w");
		uint length;
		KeyFile file = new GLib.KeyFile();
		foreach (weak IParameter c in IParameter_implementors) {
			c.write_data(file);
		}
		stream.puts(file.to_data(out length));
	}

	public void read_data(KeyFile file) throws KeyFileError {
	}

	public void write_data(KeyFile file) {
	}
}

