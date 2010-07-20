/* pl-pls-file-writer.vala
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
 * 	Jörn Magens <shuerhaaken@googlemail.com>
 */

namespace Pl {
	// base class for all playlist filewriter implementations
	private class Pls.FileWriter : AbstractFileWriter {
		
		private DataCollection data_collection;
		private File file;
		private bool _overwrite_if_exists = true;
		
		public bool overwrite_if_exists { 
			get {
				return _overwrite_if_exists;
			} 
		}

		public FileWriter(bool overwrite) {
			_overwrite_if_exists = overwrite;
		}

		public override Result write(File _file, DataCollection _data_collection) throws InternalWriterError {
			this.file = _file;
			this.data_collection = _data_collection;
			if(data_collection != null && data_collection.get_size() > 0) {
				try {
					if(file.query_exists(null)) {
						file.delete(null);
					}

					var file_stream = file.create(FileCreateFlags.NONE, null);
					var data_stream = new DataOutputStream(file_stream);
					
					data_stream.put_string("[playlist]\n\n", null);
					int i = 1;
					foreach(Data d in data_collection) {
						string? tmp_location = null;
						
						// find out the type of the target to save (uri, absolute path or relative to the playlist)
						switch(d.target_type) { //TODO: check if ASX specification allows relative paths
							case TargetType.URI:
								tmp_location = d.get_uri();
								if((tmp_location == null) && (tmp_location == ""))
									continue;
								break;
							case TargetType.ABS_PATH:
								tmp_location = d.get_abs_path();
								if((tmp_location == null) && (tmp_location == ""))
									continue;
								break;
							case TargetType.REL_PATH:
								tmp_location = d.get_rel_path();
								if((tmp_location == null) && (tmp_location == ""))
									continue;
								break;
						}
//						if(d.get_field(Data.Field.URI) == null)
//							continue;
						data_stream.put_string("File" +i.to_string() + "=" + tmp_location + "\n", null);
						data_stream.put_string("Title" +i.to_string() + "=" + d.get_title()  + "\n", null);
						data_stream.put_string("Length" +i.to_string() + "=" + "-1\n\n", null);
						i++;
					}
					data_stream.put_string("NumberOfEntries=" + data_collection.get_size().to_string() + "\n", null);
					data_stream.put_string("Version=2\n", null);
				}
				catch(GLib.Error e) {
					print("%s\n", e.message);
				}
			}
			return Result.UNHANDLED;
		}
		
		public override async Result write_asyn(File _file, DataCollection _data_collection) throws InternalWriterError {
			this.file = _file;
			this.data_collection = _data_collection;
			return Result.UNHANDLED;
		}

		protected override void set_base_path() {
			base_path = file.get_parent().get_uri();
		}
	}
}
