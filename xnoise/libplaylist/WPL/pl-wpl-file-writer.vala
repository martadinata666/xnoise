/* pl-wpl-file-writer.vala
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
 * 	Francisco Pérez Cuadrado <fsistemas@gmail.com>
 */

namespace Pl {
	private class Wpl.FileWriter : AbstractFileWriter {
		
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
			// TODO: honor overwrite, etc.
		}

		public override Result write(File _file, DataCollection _data_collection, Cancellable? cancellable = null) throws InternalWriterError {
			this.file = _file;
			set_base_path();
			this.data_collection = _data_collection;
			if(data_collection != null && data_collection.get_size() > 0) {
				try {
					if(file.query_exists(null)) {
						file.delete(null);
					}

					var file_stream = file.create(FileCreateFlags.NONE, null);
					var data_stream = new DataOutputStream(file_stream);
					
					data_stream.put_string("<wpl version=\"1.0\">\n", null);
					data_stream.put_string("<smil>\n", null);

					data_stream.put_string("<head>\n", null);
					data_stream.put_string("<meta name=\"Generator\" content=\"Xnoise media player\"/>\n", null);

					//TODO: 
					//<meta name="AverageRating" content="33"/>
					//<meta name="TotalDuration" content="1102"/>
					//<meta name="ItemCount" content="3"/>
					//<author/>
					//<title>Bach Organ Works</title>

					data_stream.put_string("</head>\n", null);
					data_stream.put_string("<body>\n", null);
					data_stream.put_string("<seq>\n", null);

					foreach(Data d in data_collection) {
						string? tmp_location = null;
						
						// find out the type of the target to save (uri, absolute path or relative to the playlist)
						switch(d.target_type) { //TODO: check if WPL specification allows relative paths
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
						
						string? tmp_title = d.get_title();
						
						data_stream.put_string(Markup.printf_escaped("<media src=\"%s\" />\n", tmp_location), null);
					}
					data_stream.put_string("</body>\n", null);
					data_stream.put_string("</seq>\n", null);
					data_stream.put_string("</smil>\n", null);
				} 
				catch(GLib.Error e) {
					print("%s\n", e.message);
				}
			}
			return Result.SUCCESS;
		}
		
		public override async Result write_asyn(File _file, DataCollection _data_collection, Cancellable? cancellable = null) throws InternalWriterError {
			this.file = _file;
			set_base_path();
			this.data_collection = _data_collection;
			return Result.UNHANDLED;
		}
		
		protected override void set_base_path() {
			base_path = file.get_parent().get_uri();
		}
	}
}