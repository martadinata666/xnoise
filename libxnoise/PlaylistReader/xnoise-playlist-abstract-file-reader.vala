/* pl-abstract-file-reader.vala
 *
 * Copyright (C) 2010  Jörn Magens
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

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


namespace Xnoise.Playlist {
	// abstract base class for all playlist filereader implementations
	private abstract class AbstractFileReader : GLib.Object {
		// relative paths from playlists are turnedinto absolute paths, by using base path
		protected string base_path;
		 
		public signal void started(string playlist_uri);
		public signal void finished(string playlist_uri);

		public abstract EntryCollection read(File file, Cancellable? cancellable = null) throws InternalReaderError;
		public abstract async EntryCollection read_asyn(File file, Cancellable? cancellable = null) throws InternalReaderError;

		protected abstract void set_base_path();
	}
}

