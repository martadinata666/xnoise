/* vlfm-track.vala
 *
 * Copyright (C) 2011  Jörn Magens
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

using Xnoise;
using Xnoise.SimpleMarkup;

namespace Lastfm {

	public class Track : GLib.Object {
		public string artist_name;
		public string album_name;
		public string title_name;
		private string api_key;
		public unowned Session parent_session;
		private string? username;
		private string? session_key;
		private string? lang;
		public string? releasedate;
		private string secret;
		
		public signal void scrobbled(string artist, string? album = null, string title, bool success = false);
		
		public Track(Session session, string _artist_name, string _album_name,
		             string _title_name,
		             string api_key, string? username = null,
		             string? session_key = null, string? lang = null, string _secret) {
			this.artist_name = _artist_name;
			this.album_name = _album_name;
			this.title_name = _title_name;
			this.api_key = api_key;
			this.parent_session = session;
			this.username = username;
			this.session_key = session_key;
			this.lang = lang;
			this.secret = _secret;
			this.parent_session.login_successful.connect( (sender, un) => {
				assert(sender == this.parent_session);
				this.username = un;
			});
		}
		
		public bool scrobble(int64 start_time) {
			string artist_escaped, album_escaped, title_escaped;
			uint trackno = 0;
			uint length = 0;
			
			if( start_time == 0) {
				print("Missing start time in scrobble\n");
				return false;
			}
			
			if(!parent_session.logged_in) {
				print("not logged in!\n");
				return false;
			}
			
			artist_escaped = parent_session.web.escape(this.artist_name);
			album_escaped  = parent_session.web.escape(this.album_name);
			title_escaped  = parent_session.web.escape(this.title_name);
			
			string buffer = "album%sapi_key%sartist%sduration%umethod%ssk%stimestamp%lutrack%strackNumber%u%s".printf(
			   this.album_name,
			   this.api_key,
			   this.artist_name,
			   length,
			   "track.scrobble",
			   this.session_key,
			   (ulong)start_time,
			   title_name,
			   trackno,
			   this.secret
			);
			string api_sig = Checksum.compute_for_string(ChecksumType.MD5, buffer);
			
			buffer = "%s?album=%s&api_key=%s&api_sig=%s&artist=%s&duration=%u&method=track.scrobble&timestamp=%lu&track=%s&trackNumber=%u&sk=%s".printf(
			   ROOT_URL,
			   album_escaped,
			   this.api_key,
			   api_sig,
			   artist_escaped,
			   length,
			   (ulong)start_time,
			   title_escaped,
			   trackno,
			   this.session_key
			);
			
			int id = parent_session.web.post_data(buffer);
			var rhc = new ResponseHandlerContainer(this.scrobble_cb, id);
			parent_session.handlers.insert(id, rhc);
			return true;
		}
		
		private void scrobble_cb(int id, string response) {
			//print("response:\n%s\n", response);
			var mr = new Xnoise.SimpleMarkup.Reader.from_string(response);
			mr.read();
			
			if(!check_response_status_ok(ref mr.root)) {
				Idle.add( () => {
					scrobbled(this.artist_name, this.album_name, this.title_name, false);
					return false;
				});
			}
			
			var n = mr.root.get_child_by_name("lfm").get_child_by_name("scrobbles");
			
			if(n.attributes["accepted"] == "1") {
				Idle.add( () => {
					scrobbled(this.artist_name, this.album_name, this.title_name, true);
					return false;
				});
			}
			else {
				Idle.add( () => {
					scrobbled(this.artist_name, this.album_name, this.title_name, false);
					return false;
				});
			}
		}
	}
}

