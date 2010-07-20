/* pl-xspf-file-reader.vala
 *
 * Copyright(C) 2010  Jörn Magens
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or(at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Author:
 * 	Francisco Pérez Cuadrado <fsistemas@gmail.com>
 * 	Jörn Magens <shuerhaaken@googlemail.com>
 */

namespace Pl {
	// base class for all playlist filereader implementations
	private class Xspf.FileReader : AbstractFileReader {
		private unowned File file;
		
		public override DataCollection read(File _file) throws InternalReaderError {
			DataCollection data_collection = new DataCollection();
			this.file = _file;
			set_base_path();
			
			var entry_on = false;
		
			if(!file.query_exists(null)) {
				stderr.printf("File '%s' doesn't exist.\n", file.get_uri());
				return data_collection;
			}
			try {
				var in_stream = new DataInputStream(file.read(null));
				string line;
				Data? d = null;
				while((line = in_stream.read_line(null, null)) != null) {
					if(line.has_prefix("#")) { //# Comments
						continue;
					}
					else if(line.size() == 0) { //Blank line
						continue;
					}
					else if(line.contains("<track>")) {
						entry_on = true;
						//print("prepare new entry\n");
						d = new Data();
						continue;
					}
					else if(line.contains("</track>")) {
						entry_on = false;
						//print("add entry\n");
						data_collection.append(d);
						continue;
					}
					else if(entry_on) { // Can we always assume that this is in one line???
						if(line.contains("<location")) {
							char* begin = line.str(">");
							begin ++;
							char* end = line.rstr("<");
							if(begin >= end) {
								throw new InternalReaderError.INVALID_FILE("Error. Invalid playlist file (uri)\n");
							}
							*end = '\0';

							TargetType tt;
							File tmp = get_file_for_location(((string)begin)._strip(), ref base_path, out tt);
							d.add_field(Data.Field.URI, tmp.get_uri());
							d.target_type = tt;
						}
						if(line.contains("<title")) {
							char* begin = line.str(">");
							begin++;
							char* end = line.rstr("<");
							if(begin >= end) {
								throw new InternalReaderError.INVALID_FILE("Error. Invalid playlist file (title)\n");
							}
							*end = '\0';
							d.add_field(Data.Field.TITLE, ((string)begin)._strip());
						}
					}
					else {
						continue;
					}
				}
			}
			catch(GLib.Error e) {
				print("Error: %s\n", e.message); 
			}
			return data_collection;
		}

		public override async DataCollection read_asyn(File _file) throws InternalReaderError {
			DataCollection data_collection = new DataCollection();
			this.file = _file;
			set_base_path();
			return data_collection;
		}
		
		protected override void set_base_path() {
			base_path = file.get_parent().get_uri();
		}
	}
}
