/* xnoise-db-browser.vala
 *
 * Copyright (C) 2009-2011  Jörn Magens
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


using Sqlite;

using Xnoise;
using Xnoise.Services;

public errordomain Xnoise.Database.DbError {
	FAILED;
}

public class Xnoise.Database.DbBrowser {
	private const string DATABASE_NAME = "db.sqlite";
	private const string SETTINGS_FOLDER = ".xnoise";
	private string DATABASE;

	private static const string STMT_IMAGE_PATH_FOR_URI =
		"SELECT al.image FROM artists ar, items t, albums al, uris u WHERE t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND u.name = ?";
	private static const string STMT_COUNT_FOR_STREAMS =
		"SELECT COUNT (id) FROM streams st WHERE st.uri = ?";
	private static const string STMT_TRACKDATA_FOR_STREAM =
		"SELECT st.name FROM streams st WHERE st.name = ?";
	private static const string STMT_COUNT_STREAMS =
		"SELECT COUNT (id) FROM streams";
	private static const string STMT_COUNT_FOR_MEDIATYPE =
		"SELECT COUNT (title) FROM items WHERE mediatype = ?";
	private static const string STMT_COUNT_FOR_URI =
		"SELECT COUNT (i.title) FROM items i, uris u WHERE i.uri = u.id AND u.name = ?";
	private static const string STMT_TRACKDATA_FOR_ID =
		"SELECT ar.name, al.name, t.title, t.tracknumber, t.mediatype, u.name, t.length FROM artists ar, items t, albums al, uris u WHERE t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND t.id = ?";
	private static const string STMT_URI_FOR_ID =
		"SELECT u.name FROM items t, uris u WHERE t.uri = u.id AND t.id = ?";
	private static const string STMT_TRACK_ID_FOR_URI =
		"SELECT t.id FROM items t, uris u WHERE t.uri = u.id AND u.name = ?";
	private static const string STMT_GET_LASTUSED =
		"SELECT uri FROM lastused";
	private static const string STMT_GET_VIDEOS =
		"SELECT DISTINCT title FROM items i, uris u WHERE u.id = i.uri AND (i.title LIKE ? OR u.name LIKE ?) AND mediatype = ? GROUP BY LOWER(title) ORDER BY LOWER(title) DESC";
//	private static const string STMT_GET_ITEMS =
//		"SELECT DISTINCT t.title FROM artists ar, items t, albums al WHERE t.artist = ar.id AND t.album = al.id AND ar.name = ? AND al.name = ? AND t.title LIKE ? ORDER BY t.tracknumber DESC, LOWER(t.title) DESC";
	private static const string STMT_GET_URIS = 
		"SELECT name FROM uris WHERE name LIKE ? ESCAPE \'\\\'";
	private static const string STMT_GET_RADIOS =
		"SELECT name, uri FROM streams";
	private static const string STMT_GET_SINGLE_RADIO_URI =
		"SELECT uri FROM streams WHERE name = ?";
	private static const string STMT_GET_MEDIA_FOLDERS =
		"SELECT * FROM media_folders";
	private static const string STMT_GET_MEDIA_FILES =
		"SELECT * FROM media_files";
	private static const string STMT_GET_RADIO_DATA	=
		"SELECT DISTINCT id, name, uri FROM streams WHERE name LIKE ? ORDER BY name DESC";

	public DbBrowser() throws DbError {
		DATABASE = dbFileName();
		db = null;
		if(Sqlite.Database.open_v2(DATABASE, out db, Sqlite.OPEN_READONLY, null)!=Sqlite.OK) {
			print("Can't open database: %s\n", (string)this.db.errmsg);
			throw new DbError.FAILED("failed messge");
		}
		if(this.db == null) {
			throw new DbError.FAILED("failed messge");
		}
		db.progress_handler(5, progress_handler);
	}
	
	public void cancel() {
		abort = true;
	}
	
	private bool abort = false;
	private int progress_handler() {
		if(abort) {
			abort = false;
			return 1;
		}
		return 0;
	}
	//~DbBrowser() {
	//	print("dtor db browser\n");
	//}

	private Sqlite.Database db;

	private string dbFileName() {
		return GLib.Path.build_filename(data_folder(), DATABASE_NAME, null);
	}

	private void db_error() {
		print("Database error %d: %s \n\n", this.db.errcode(), this.db.errmsg());
	}

	public delegate void ReaderCallback(Sqlite.Database database);
	
	public void do_callback_transaction(ReaderCallback cb) {
		if(db == null) return;
		
		if(cb != null)
			cb(db);
	}

	private static const string STMT_GET_ARTIST_COUNT_WITH_SEARCH =
		"SELECT COUNT (ar.name) FROM artists ar, items t, albums al, uris u WHERE t.artist = ar.id AND t.album = al.id AND u.id = t.uri AND (ar.name LIKE ? OR al.name LIKE ? OR t.title LIKE ? OR u.name LIKE ?)";
	public int count_artists_with_search(ref string searchtext) {
		Statement stmt;
		int count = 0;
		
		this.db.prepare_v2(STMT_GET_ARTIST_COUNT_WITH_SEARCH, -1, out stmt);
			
		stmt.reset();

		if((stmt.bind_text(1, "%%%s%%".printf(searchtext)) != Sqlite.OK)||
		   (stmt.bind_text(2, "%%%s%%".printf(searchtext)) != Sqlite.OK)||
		   (stmt.bind_text(3, "%%%s%%".printf(searchtext)) != Sqlite.OK)||
		   (stmt.bind_text(4, "%%%s%%".printf(searchtext)) != Sqlite.OK)) {
			this.db_error();
			return 0;
		}
		if(stmt.step() == Sqlite.ROW) {
			count = stmt.column_int(0);
		}
		return count;
	}

	private static const string STMT_GET_VIDEO_COUNT = "SELECT COUNT (t.id) FROM items t, uris u WHERE t.mediatype=? AND u.id = t.uri AND (t.title LIKE ? OR u.name LIKE ?)";
	public int32 count_videos(ref string searchtext) {
		Statement stmt;
		int count = 0;
		
		this.db.prepare_v2(STMT_GET_VIDEO_COUNT, -1, out stmt);
		
		if(stmt.bind_int (1, ItemType.LOCAL_VIDEO_TRACK) != Sqlite.OK ||
		   stmt.bind_text(2, "%%%s%%".printf(searchtext)) != Sqlite.OK ||
		   stmt.bind_text(3, "%%%s%%".printf(searchtext)) != Sqlite.OK) {
			this.db_error();
			return 0;
		}
		
		if(stmt.step() == Sqlite.ROW) {
			count = stmt.column_int(0);
		}
		return count;
	}

	private static const string STMT_GET_ARTIST_COUNT = "SELECT COUNT (name) FROM artists";
	public int count_artists() {
		Statement stmt;
		int count = 0;
		
		this.db.prepare_v2(STMT_GET_ARTIST_COUNT, -1, out stmt);
		
		stmt.reset();
		
		if(stmt.step() == Sqlite.ROW) {
			count = stmt.column_int(0);
		}
		return count;
	}

	public bool videos_available() {
		Statement stmt;
		int count = 0;
		
		this.db.prepare_v2(STMT_COUNT_FOR_MEDIATYPE, -1, out stmt);
			
		stmt.reset();

		if(stmt.bind_int(1, ItemType.LOCAL_VIDEO_TRACK) != Sqlite.OK) {
			this.db_error();
		}
		if(stmt.step() == Sqlite.ROW) {
			count = stmt.column_int(0);
		}
		if(count>0) return true;
		return false;
	}

	public bool streams_available() {
		Statement stmt;
		int count = 0;
		this.db.prepare_v2(STMT_COUNT_STREAMS, -1, out stmt);
			
		stmt.reset();

		if(stmt.step() == Sqlite.ROW) {
			count = stmt.column_int(0);
			if(count > 0) return true;
		}
		return false;
	}

	public bool stream_in_db(string uri) {
		Statement stmt;
		int count = 0;
		
		this.db.prepare_v2(STMT_COUNT_FOR_STREAMS, -1, out stmt);
			
		stmt.reset();

		if(stmt.bind_text(1, uri) != Sqlite.OK) {
			this.db_error();
		}
		if(stmt.step() == Sqlite.ROW) {
			count = stmt.column_int(0);
			if(count > 0) return true;
		}
		return false;
	}

	public bool track_in_db(string uri) {
		Statement stmt;
		int count = 0;
		
		this.db.prepare_v2(STMT_COUNT_FOR_URI, -1, out stmt);
			
		stmt.reset();

		if(stmt.bind_text(1, uri) != Sqlite.OK) {
			this.db_error();
		}
		if(stmt.step() == Sqlite.ROW) {
			count = stmt.column_int(0);
		}
		if(count>0) return true;
		return false;
	}

	public bool get_uri_for_id(int id, out string val) {
		Statement stmt;
		val = "";
		this.db.prepare_v2(STMT_URI_FOR_ID, -1, out stmt);
		stmt.reset();
		if(stmt.bind_int(1, id) != Sqlite.OK) {
			this.db_error();
		}
		if(stmt.step() == Sqlite.ROW) {
			val = stmt.column_text(0);
			return true;
		}
		return false;
	}

	private static const string STMT_ALL_TRACKDATA =
		"SELECT ar.name, al.name, t.title, t.tracknumber, t.mediatype, u.name, t.length, t.id, g.name, t.year FROM artists ar, items t, albums al, uris u, genres g WHERE t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND t.genre = g.id AND (ar.name LIKE ? OR al.name LIKE ? OR t.title LIKE ? OR u.name LIKE ?) ORDER BY LOWER(ar.name) ASC, LOWER(al.name) ASC, t.tracknumber ASC";

	public TrackData[]? get_all_tracks(ref string searchtext) {
		Statement stmt;
		TrackData[] retv = {};
		
		this.db.prepare_v2(STMT_ALL_TRACKDATA , -1, out stmt);
		
		if((stmt.bind_text(1, "%%%s%%".printf(searchtext)) != Sqlite.OK) ||
		   (stmt.bind_text(2, "%%%s%%".printf(searchtext)) != Sqlite.OK) ||
		   (stmt.bind_text(3, "%%%s%%".printf(searchtext)) != Sqlite.OK) ||
		   (stmt.bind_text(4, "%%%s%%".printf(searchtext)) != Sqlite.OK)) {
			this.db_error();
			return null;
		}
		while(stmt.step() == Sqlite.ROW) {
			TrackData val = new TrackData();
			val.artist      = stmt.column_text(0);
			val.album       = stmt.column_text(1);
			val.title       = stmt.column_text(2);
			val.tracknumber = stmt.column_int(3);
			val.length      = stmt.column_int(6);
			val.item        = Item((ItemType)stmt.column_int(4), stmt.column_text(5), stmt.column_int(7));
			val.genre       = stmt.column_text(8);
			val.year        = stmt.column_int(9);
			if((val.artist=="") || (val.artist==null)) {
				val.artist = "unknown artist";
			}
			if((val.album== "") || (val.album== null)) {
				val.album = "unknown album";
			}
			if((val.genre== "") || (val.genre== null)) {
				val.genre = "unknown genre";
			}
			if((val.title== "") || (val.title== null)) {
				val.title = "unknown title";
				File file = File.new_for_uri(val.item.uri);
				string fileBasename;
				if(file != null)
					fileBasename = GLib.Filename.display_basename(file.get_path());
				else
					fileBasename = val.item.uri;
				val.title = fileBasename;
			}
			retv += val;
		}
		return retv;
	}

	public bool get_trackdata_for_id(int id, out TrackData val) {
		Statement stmt;
		val = new TrackData();
		
		this.db.prepare_v2(STMT_TRACKDATA_FOR_ID , -1, out stmt);
		
		stmt.reset();
		if(stmt.bind_int(1, id) != Sqlite.OK) {
			this.db_error();
		}
		if(stmt.step() == Sqlite.ROW) {
			val.artist      = stmt.column_text(0);
			val.album       = stmt.column_text(1);
			val.title       = stmt.column_text(2);
			val.tracknumber = stmt.column_int(3);
			val.length      = stmt.column_int(6);
			val.item        = Item((ItemType)stmt.column_int(4), stmt.column_text(5), id);
		}
		else {
			print("get_trackdata_for_id: track is not in db. ID: %d\n", id);
			return false;
		}
		if((val.artist=="") | (val.artist==null)) {
			val.artist = "unknown artist";
		}
		if((val.album== "") | (val.album== null)) {
			val.album = "unknown album";
		}
		if((val.title== "") | (val.title== null)) {
			val.title = "unknown title";
			File file = File.new_for_uri(val.item.uri);
			string fileBasename;
			if(file != null)
				fileBasename = GLib.Filename.display_basename(file.get_path());
			else
				fileBasename = val.item.uri;
			val.title = fileBasename;
		}
		return true;
	}

	private static const string STMT_STREAM_TD_FOR_ID =
		"SELECT name, uri FROM streams WHERE id = ?";
	//	private static const string STMT_STREAM_TD_FOR_ID_WITH_SEARCH =
	//		"SELECT name, uri FROM streams WHERE id = ? AND uri LIKE ?";

	public bool get_stream_td_for_id(int id, out TrackData val) {
		Statement stmt;
		val = new TrackData();
		this.db.prepare_v2(STMT_STREAM_TD_FOR_ID , -1, out stmt);
			
		stmt.reset();
		if(stmt.bind_int (1, id) != Sqlite.OK) {
			this.db_error();
			return false;
		}
		if(stmt.step() == Sqlite.ROW) {
			val.artist      = "";
			val.album       = "";
			val.title       = stmt.column_text(0);
			val.item        = Item(ItemType.STREAM, stmt.column_text(1), id);
		}
		else {
			print("get_stream_td_for_id: track is not in db. ID: %d\n", id);
			return false;
		}
		return true;
	}

//	public bool get_stream_for_id(int id, out string uri) {
//		Statement stmt;
//		
//		this.db.prepare_v2(STMT_STREAM_TD_FOR_ID , -1, out stmt);
//		
//		stmt.reset();
//		if(stmt.bind_int(1, id) != Sqlite.OK) {
//			this.db_error();
//		}
//		if(stmt.step() == Sqlite.ROW) {
//			uri = stmt.column_text(1);
//			return true;
//		}
//		return false;
//	}

	public string? get_local_image_path_for_track(ref string? uri) {
		Statement stmt;
		string retval = null;
		if(uri == null) 
			return retval;
		this.db.prepare_v2(STMT_IMAGE_PATH_FOR_URI, -1, out stmt);
		
		stmt.reset();
		if(stmt.bind_text(1, uri) != Sqlite.OK) {
			this.db_error();
		}
		if(stmt.step() == Sqlite.ROW) {
			retval = stmt.column_text(0);
		}
		return retval;
	}

	public bool get_trackdata_for_stream(string uri, out TrackData val) {
		Statement stmt;
		bool retval = false;
		val = new TrackData();
		this.db.prepare_v2(STMT_TRACKDATA_FOR_STREAM, -1, out stmt);
			
		stmt.reset();
		if(stmt.bind_text(1, uri) != Sqlite.OK) {
			this.db_error();
		}
		if(stmt.step() == Sqlite.ROW) {
			val.title = stmt.column_text(0);
			retval = true;
		}
		return retval;
	}

	private static const string STMT_TRACKDATA_FOR_URI =
		"SELECT ar.name, al.name, t.title, t.tracknumber, t.length, t.mediatype, t.id, g.name, t.year FROM artists ar, items t, albums al, uris u, genres g WHERE t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND t.genre = g.id AND u.name = ?";

	public bool get_trackdata_for_uri(ref string? uri, out TrackData val) {
		bool retval = false;
		val = new TrackData();
		if(uri == null)
			return retval;
		
		Statement stmt;
		this.db.prepare_v2(STMT_TRACKDATA_FOR_URI, -1, out stmt);
			
		stmt.reset();
		stmt.bind_text(1, uri);
		if(stmt.step() == Sqlite.ROW) {
			val.artist      = stmt.column_text(0);
			val.album       = stmt.column_text(1);
			val.title       = stmt.column_text(2);
			val.tracknumber = (uint)stmt.column_int(3);
			val.length      = stmt.column_int(4);
			val.item        = Item((ItemType)stmt.column_int(5), uri, stmt.column_int(6));
			val.genre       = stmt.column_text(7);
			val.year        = stmt.column_int(8);
			retval = true;
		}
		if((val.artist=="") | (val.artist==null)) {
			val.artist = "unknown artist";
		}
		if((val.album== "") | (val.album== null)) {
			val.album = "unknown album";
		}
		if((val.genre== "") | (val.genre== null)) {
			val.genre = "unknown genre";
		}
		if((val.title== "") | (val.title== null)) {
			val.title = "unknown title";
			File file = File.new_for_uri(uri);
			string fpath = file.get_path();
			string fileBasename = "";
			if(fpath!=null) fileBasename = GLib.Filename.display_basename(fpath);
			val.title = fileBasename;
		}
		return retval;
	}

	public string[] get_media_files() {
		Statement stmt;
		string[] mfiles = {};
		
		this.db.prepare_v2(STMT_GET_MEDIA_FILES, -1, out stmt);
		
		stmt.reset();
		while(stmt.step() == Sqlite.ROW) {
			mfiles += stmt.column_text(0);
		}
		return mfiles;
	}

	public string[] get_media_folders() {
		Statement stmt;
		string[] mfolders = {};
		
		this.db.prepare_v2(STMT_GET_MEDIA_FOLDERS, -1, out stmt);
		
		while(stmt.step() == Sqlite.ROW) {
			mfolders += stmt.column_text(0);
		}
		return mfolders;
	}

	public StreamData[] get_streams() {
		Statement stmt;
		StreamData[] sData = {};
		
		this.db.prepare_v2(STMT_GET_RADIOS, -1, out stmt);
			
		while(stmt.step() == Sqlite.ROW) {
			StreamData sd = StreamData();
			sd.name = stmt.column_text(0);
			sd.uri  = stmt.column_text(1);
			sData += sd;
		}
		return sData;
	}

	public string? get_single_stream_uri(string name) {
		Statement stmt;
		this.db.prepare_v2(STMT_GET_SINGLE_RADIO_URI, -1, out stmt);
		stmt.bind_text(1, name);
		if(stmt.step() == Sqlite.ROW) {
			return stmt.column_text(0);
		}
		return null;
	}

	public int get_track_id_for_path(string uri) {
		int val = -1;
		Statement stmt;
		
		this.db.prepare_v2(STMT_TRACK_ID_FOR_URI, -1, out stmt);
		stmt.reset();
		stmt.bind_text(1, uri);
		if(stmt.step() == Sqlite.ROW) {
			val = stmt.column_int(0);
		}
		return val;
	}

	private static const string STMT_GET_SOME_LASTUSED_ITEMS =
		"SELECT mediatype, uri, id FROM lastused LIMIT ? OFFSET ?";
	public Item[] get_some_lastused_items(int limit, int offset) {
		Item[] val = {};
		Statement stmt;
		
		this.db.prepare_v2(STMT_GET_SOME_LASTUSED_ITEMS, -1, out stmt);
		
		if((stmt.bind_int(1, limit)  != Sqlite.OK) ||
		   (stmt.bind_int(2, offset) != Sqlite.OK)) {
			this.db_error();
			return val;
		}
		
		while(stmt.step() == Sqlite.ROW) {
			Item? item = Item((ItemType)stmt.column_int(0), stmt.column_text(1), stmt.column_int(2));
			val += item;
		}
		return val;
	}
	
	private static const string STMT_CNT_LASTUSED =
		"SELECT COUNT(mediatype) FROM lastused";
	
	public uint count_lastused_items() {
		uint val = 0;
		Statement stmt;
		
		this.db.prepare_v2(STMT_CNT_LASTUSED, -1, out stmt);
		
		if(stmt.step() == Sqlite.ROW) {
			return stmt.column_int(0);
		}
		return val;
	}
	
	private static const string STMT_GET_LASTUSED_ITEMS =
		"SELECT mediatype, uri, id FROM lastused";
	public Item[] get_lastused_items() {
		Item[] val = {};
		Statement stmt;
		
		this.db.prepare_v2(STMT_GET_LASTUSED_ITEMS, -1, out stmt);
		
		while(stmt.step() == Sqlite.ROW) {
			Item? item = Item((ItemType)stmt.column_int(0), stmt.column_text(1), stmt.column_int(2));
			val += item;
		}
		return val;
	}
	
	public string[] get_uris(string search_string) {
		//print("searching for %s\n", STMT_GET_URIS.replace("?", search_string));
		string[] results = {};
		Statement stmt;
		
		this.db.prepare_v2(STMT_GET_URIS, -1, out stmt);
		
		stmt.bind_text(1, search_string);
		while(stmt.step() == Sqlite.ROW) {
			//print("found %s", stmt.column_text(0));
			results += stmt.column_text(0);
		}
		return results;
	}

	private static const string STMT_GET_STREAM_DATA =
		"SELECT DISTINCT s.id, s.uri, s.name FROM streams s WHERE s.name LIKE ? ORDER BY LOWER(s.name) DESC";

	public TrackData[] get_stream_data(ref string searchtext) {
		TrackData[] val = {};
		Statement stmt;
		
		this.db.prepare_v2(STMT_GET_STREAM_DATA, -1, out stmt);
		
		if(stmt.bind_text(1, "%%%s%%".printf(searchtext))     != Sqlite.OK) {
			this.db_error();
			return val;
		}
		while(stmt.step() == Sqlite.ROW) {
			TrackData td = new TrackData();
			td.title       = stmt.column_text(2);
			td.name        = stmt.column_text(1);
			td.item        = Item(ItemType.STREAM, stmt.column_text(1), stmt.column_int(0));
			td.item.text   = stmt.column_text(2);
			val += td;
		}
		return val;
	}

	private static const string STMT_GET_VIDEO_DATA =
		"SELECT DISTINCT t.title, t.id, t.tracknumber, u.name, ar.name, al.name, t.length, t.genre FROM artists ar, items t, albums al, uris u WHERE t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND t.mediatype = ? AND (t.title LIKE ? OR u.name LIKE ?) GROUP BY LOWER(t.title) ORDER BY LOWER(t.title) DESC";

	public TrackData[] get_video_data(ref string searchtext) {
		TrackData[] val = {};
		Statement stmt;
		
		this.db.prepare_v2(STMT_GET_VIDEO_DATA, -1, out stmt);
		
		if((stmt.bind_int (1, (int)ItemType.LOCAL_VIDEO_TRACK) != Sqlite.OK)||
		   (stmt.bind_text(2, "%%%s%%".printf(searchtext))     != Sqlite.OK)||
		   (stmt.bind_text(3, "%%%s%%".printf(searchtext))     != Sqlite.OK)) {
			this.db_error();
			return val;
		}
		while(stmt.step() == Sqlite.ROW) {
			TrackData td = new TrackData();
			td.artist      = stmt.column_text(4);
			td.album       = stmt.column_text(5);
			td.title       = stmt.column_text(0);
			td.tracknumber = stmt.column_int(2);
			td.length      = stmt.column_int(6);
			td.genre       = stmt.column_text(7);
			td.name        = stmt.column_text(0);
			td.item        = Item(ItemType.LOCAL_VIDEO_TRACK, stmt.column_text(3), stmt.column_int(1));
			val += td;
		}
		return val;
	}

	private static const string STMT_GET_TRACKDATA_FOR_VIDEO =
		"SELECT DISTINCT t.title, t.id, t.tracknumber, u.name, ar.name, al.name, t.length, g.name, t.year FROM artists ar, items t, albums al, uris u, genres g WHERE t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND t.genre = g.id AND t.mediatype = ? AND (t.title LIKE ? OR u.name LIKE ?) GROUP BY LOWER(t.title) ORDER BY LOWER(t.title) ASC";

	public TrackData[] get_trackdata_for_video(ref string searchtext) {
		TrackData[] val = {};
		Statement stmt;
		
		this.db.prepare_v2(STMT_GET_TRACKDATA_FOR_VIDEO, -1, out stmt);
		
		if((stmt.bind_int (1, (int)ItemType.LOCAL_VIDEO_TRACK) != Sqlite.OK)||
		   (stmt.bind_text(2, "%%%s%%".printf(searchtext))     != Sqlite.OK)||
		   (stmt.bind_text(3, "%%%s%%".printf(searchtext))     != Sqlite.OK)) {
			this.db_error();
			return val;
		}
		while(stmt.step() == Sqlite.ROW) {
			TrackData td = new TrackData();
			td.artist      = stmt.column_text(4);
			td.album       = stmt.column_text(5);
			td.title       = stmt.column_text(0);
			td.tracknumber = stmt.column_int(2);
			td.length      = stmt.column_int(6);
			td.genre       = stmt.column_text(7);
			td.year        = stmt.column_int(8);
			td.name        = stmt.column_text(0);
			td.item        = Item(ItemType.LOCAL_VIDEO_TRACK, stmt.column_text(3), stmt.column_int(1));
			val += td;
		}
		return val;
	}

	private static const string STMT_GET_TRACKDATA_FOR_STREAMS =
		"SELECT DISTINCT s.id, s.uri, s.name FROM streams s WHERE s.name LIKE ? OR s.uri LIKE ? ORDER BY LOWER(s.name) ASC";

	public TrackData[] get_trackdata_for_streams(ref string searchtext) {
		TrackData[] val = {};
		Statement stmt;
		
		this.db.prepare_v2(STMT_GET_TRACKDATA_FOR_STREAMS, -1, out stmt);
		
		if((stmt.bind_text(1, "%%%s%%".printf(searchtext))     != Sqlite.OK)||
		   (stmt.bind_text(2, "%%%s%%".printf(searchtext))     != Sqlite.OK)) {
			this.db_error();
			return val;
		}
		while(stmt.step() == Sqlite.ROW) {
			TrackData td = new TrackData();
			td.title       = stmt.column_text(2);
			td.name        = stmt.column_text(2);
			td.item        = Item(ItemType.STREAM, stmt.column_text(1), stmt.column_int(0));
			td.item.text   = stmt.column_text(2);
			val += td;
		}
		return val;
	}

//	public TrackData[] get_stream_data(ref string searchtext) {
//		//	print("in get_stream_data\n");
//		TrackData[] val = {};
//		Statement stmt;
//		
//		this.db.prepare_v2(STMT_GET_RADIO_DATA, -1, out stmt);
//		if((stmt.bind_text(1, "%%%s%%".printf(searchtext)) != Sqlite.OK)) {
//			this.db_error();
//		}
//		while(stmt.step() == Sqlite.ROW) {
//			TrackData vd = new TrackData();
//			vd.name = stmt.column_text(1);
//			vd.item = Item(ItemType.STREAM, stmt.column_text(2), stmt.column_int(0));
//			val += vd;
//		}
//		return val;
//	}

	public string[] get_videos(ref string searchtext) {
		Statement stmt;
		string[] val = {};
		this.db.prepare_v2(STMT_GET_VIDEOS, -1, out stmt);
			
		if((stmt.bind_text(1, "%%%s%%".printf(searchtext))     != Sqlite.OK)||
		   (stmt.bind_text(2, "%%%s%%".printf(searchtext))     != Sqlite.OK)||
		   (stmt.bind_int (3, (int)ItemType.LOCAL_VIDEO_TRACK) != Sqlite.OK)) {
			this.db_error();
		}
		while(stmt.step() == Sqlite.ROW) {
			val += stmt.column_text(0);
		}
		return val;
	}

	private static const string STMT_GET_SOME_ARTISTS = 
		"SELECT DISTINCT ar.name , ar.id FROM artists ar ORDER BY LOWER(ar.name) ASC limit ? offset ?";
	public Item[] get_some_artists(int limit, int offset) {
		Item[] val = {};
		Statement stmt;
		
		this.db.prepare_v2(STMT_GET_SOME_ARTISTS, -1, out stmt);
		
		
		if((stmt.bind_int(1, limit ) != Sqlite.OK)|
		   (stmt.bind_int(2, offset) != Sqlite.OK)) {
			this.db_error();
		}
		while(stmt.step() == Sqlite.ROW) {
			Item i = Item(ItemType.COLLECTION_CONTAINER_ARTIST, null, stmt.column_int(1));
			i.text = stmt.column_text(0);
			val += i;
		}
		return val;
	}

	private static const string STMT_GET_ARTISTS_WITH_SEARCH =
		"SELECT DISTINCT ar.name, ar.id FROM artists ar, items t, albums al, uris u WHERE t.artist = ar.id AND t.album = al.id AND u.id = t.uri AND (ar.name LIKE ? OR al.name LIKE ? OR t.title LIKE ? OR u.name LIKE ?) ORDER BY LOWER(ar.name) ASC";

	private static const string STMT_GET_ARTISTS =
		"SELECT DISTINCT ar.name, ar.id  FROM artists ar, items t, albums al WHERE t.artist = ar.id AND t.album = al.id ORDER BY LOWER(ar.name) ASC"; //LOWER(ar.name)
	
	public Item[] get_artists_with_search(ref string searchtext) {
		
		Item[] val = {};
		Statement stmt;
		if(searchtext != "") {
			this.db.prepare_v2(STMT_GET_ARTISTS_WITH_SEARCH, -1, out stmt);
			if((stmt.bind_text(1, "%%%s%%".printf(searchtext)) != Sqlite.OK) ||
			   (stmt.bind_text(2, "%%%s%%".printf(searchtext)) != Sqlite.OK) ||
			   (stmt.bind_text(3, "%%%s%%".printf(searchtext)) != Sqlite.OK) ||
			   (stmt.bind_text(4, "%%%s%%".printf(searchtext)) != Sqlite.OK)) {
				this.db_error();
				return val;
			}
		}
		else {
			this.db.prepare_v2(STMT_GET_ARTISTS, -1, out stmt);
		}
		
		while(stmt.step() == Sqlite.ROW) {
			Item i = Item(ItemType.COLLECTION_CONTAINER_ARTIST, null, stmt.column_int(1));
			i.text = stmt.column_text(0);
			val += i;
		}
		
		return val;
	}

//	public string[] get_artists() {
//		string[] val = {};
//		Statement stmt;
//		this.db.prepare_v2(STMT_GET_ARTISTS, -1, out stmt);
//		stmt.reset();
//		
//		while(stmt.step() == Sqlite.ROW)
//			val += stmt.column_text(0);
//		
//		return val;
//	}

	private static const string STMT_GET_TRACKDATA_BY_ALBUMID_WITH_SEARCH =
		"SELECT DISTINCT t.title, t.mediatype, t.id, t.tracknumber, u.name, ar.name, al.name, t.length, g.name, t.year  FROM artists ar, items t, albums al, uris u, genres g WHERE t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND t.genre = g.id AND al.id = ? AND (ar.name LIKE ? OR al.name LIKE ? OR t.title LIKE ? OR u.name LIKE ?) GROUP BY LOWER(t.title) ORDER BY t.tracknumber ASC, t.title ASC";
	
	private static const string STMT_GET_TRACKDATA_BY_ALBUMID =
		"SELECT DISTINCT t.title, t.mediatype, t.id, t.tracknumber, u.name, ar.name, al.name, t.length, g.name, t.year  FROM artists ar, items t, albums al, uris u, genres g WHERE t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND t.genre = g.id AND al.id = ? GROUP BY LOWER(t.title) ORDER BY t.tracknumber ASC, t.title ASC";
	
	public TrackData[]? get_trackdata_by_albumid(ref string searchtext, int32 id) {
		TrackData[] val = {};
		Statement stmt;
		
		if(searchtext != "") {
			this.db.prepare_v2(STMT_GET_TRACKDATA_BY_ALBUMID_WITH_SEARCH, -1, out stmt);
			if((stmt.bind_int (1, id) != Sqlite.OK) ||
			   (stmt.bind_text(2, "%%%s%%".printf(searchtext)) != Sqlite.OK) ||
			   (stmt.bind_text(3, "%%%s%%".printf(searchtext)) != Sqlite.OK) ||
			   (stmt.bind_text(4, "%%%s%%".printf(searchtext)) != Sqlite.OK)||
			   (stmt.bind_text(5, "%%%s%%".printf(searchtext)) != Sqlite.OK)) {
				this.db_error();
				return val;
			}
		}
		else {
			this.db.prepare_v2(STMT_GET_TRACKDATA_BY_ALBUMID, -1, out stmt);
			if((stmt.bind_int(1, id) != Sqlite.OK)) {
				this.db_error();
				return null;
			}
		}
		while(stmt.step() == Sqlite.ROW) {
			TrackData td = new TrackData();
			Item? i = Item((ItemType)stmt.column_int(1), stmt.column_text(4), stmt.column_int(2));
			
			td.artist      = stmt.column_text(5);
			td.album       = stmt.column_text(6);
			td.title       = stmt.column_text(0);
			td.item        = i;
			td.tracknumber = stmt.column_int(3);
			td.length      = stmt.column_int(7);
			td.genre       = stmt.column_text(8);
			td.year        = stmt.column_int(9);
			val += td;
		}
		return val;
	}

	private static const string STMT_GET_TRACKDATA_BY_ARTISTID_WITH_SEARCH =
		"SELECT t.title, t.mediatype, t.id, t.tracknumber, u.name, ar.name, al.name, t.length, g.name, t.year FROM artists ar, items t, albums al, uris u, genres g  WHERE t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND t.genre = g.id AND ar.id = ? AND (ar.name LIKE ? OR al.name LIKE ? OR t.title LIKE ? OR u.name LIKE ?) GROUP BY LOWER(t.title), al.id ORDER BY al.name ASC, t.tracknumber ASC, t.title ASC";
	
	private static const string STMT_GET_TRACKDATA_BY_ARTISTID =
		"SELECT t.title, t.mediatype, t.id, t.tracknumber, u.name, ar.name, al.name, t.length, g.name, t.year  FROM artists ar, items t, albums al, uris u, genres g WHERE t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND t.genre = g.id AND ar.id = ? GROUP BY LOWER(t.title), al.id ORDER BY al.name ASC, t.tracknumber ASC, t.title ASC";
	
	public TrackData[]? get_trackdata_by_artistid(ref string searchtext, int32 id) {
		TrackData[] val = {};
		Statement stmt;
		
		if(searchtext != "") {
			this.db.prepare_v2(STMT_GET_TRACKDATA_BY_ARTISTID_WITH_SEARCH, -1, out stmt);
			if((stmt.bind_int (1, id) != Sqlite.OK) ||
			   (stmt.bind_text(2, "%%%s%%".printf(searchtext)) != Sqlite.OK) ||
			   (stmt.bind_text(3, "%%%s%%".printf(searchtext)) != Sqlite.OK) ||
			   (stmt.bind_text(4, "%%%s%%".printf(searchtext)) != Sqlite.OK) ||
			   (stmt.bind_text(5, "%%%s%%".printf(searchtext)) != Sqlite.OK)) {
				this.db_error();
				return val;
			}
		}
		else {
			this.db.prepare_v2(STMT_GET_TRACKDATA_BY_ARTISTID, -1, out stmt);
			if((stmt.bind_int(1, id)!=Sqlite.OK)) {
				this.db_error();
				return null;
			}
		}		
		while(stmt.step() == Sqlite.ROW) {
			TrackData td = new TrackData();
			Item? i = Item((ItemType)stmt.column_int(1), stmt.column_text(4), stmt.column_int(2));
			
			td.artist      = stmt.column_text(5);
			td.album       = stmt.column_text(6);
			td.title       = stmt.column_text(0);
			td.item        = i;
			td.tracknumber = stmt.column_int(3);
			td.length      = stmt.column_int(7);
			td.genre       = stmt.column_text(8);
			td.year        = stmt.column_int(9);
			val += td;
		}
		return val;
	}

	private static const string STMT_GET_ARTISTITEM_BY_ARTISTID_WITH_SEARCH =
		"SELECT DISTINCT ar.name FROM artists ar, items t, albums al, uris u WHERE t.artist = ar.id AND t.album = al.id AND u.id = t.uri AND ar.id = ? AND (ar.name LIKE ? OR al.name LIKE ? OR t.title LIKE ? OR u.name LIKE ?)";
	
	private static const string STMT_GET_ARTISTITEM_BY_ARTISTID =
		"SELECT DISTINCT ar.name FROM artists ar, items t, albums al WHERE t.artist = ar.id AND t.album = al.id AND ar.id = ?";
	
	public Item? get_artistitem_by_artistid(ref string searchtext, int32 id) {
		Statement stmt;
		Item? i = Item(ItemType.UNKNOWN);
		if(searchtext != "") {
			this.db.prepare_v2(STMT_GET_ARTISTITEM_BY_ARTISTID_WITH_SEARCH, -1, out stmt);
			if((stmt.bind_int (1, id) != Sqlite.OK) ||
			   (stmt.bind_text(2, "%%%s%%".printf(searchtext)) != Sqlite.OK) ||
			   (stmt.bind_text(3, "%%%s%%".printf(searchtext)) != Sqlite.OK) ||
			   (stmt.bind_text(4, "%%%s%%".printf(searchtext)) != Sqlite.OK) ||
			   (stmt.bind_text(5, "%%%s%%".printf(searchtext)) != Sqlite.OK)) {
				this.db_error();
				return i;
			}
		}
		else {
			this.db.prepare_v2(STMT_GET_ARTISTITEM_BY_ARTISTID, -1, out stmt);
			if((stmt.bind_int(1, id)!=Sqlite.OK)) {
				this.db_error();
				return i;
			}
		}
		if(stmt.step() == Sqlite.ROW) {
			i = Item(ItemType.COLLECTION_CONTAINER_ARTIST, null, id);
			i.text = stmt.column_text(0);
		}
		return i;
	}

	private static const string STMT_GET_TRACKDATA_BY_TITLEID =
		"SELECT DISTINCT t.title, t.mediatype, t.id, t.tracknumber, u.name, ar.name, al.name, t.length, g.name, t.year FROM artists ar, items t, albums al, uris u, genres g WHERE t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND t.genre = g.id AND t.id = ?";
		
	public TrackData? get_trackdata_by_titleid(ref string searchtext, int32 id) {
		Statement stmt;
		
		this.db.prepare_v2(STMT_GET_TRACKDATA_BY_TITLEID, -1, out stmt);
		
		if((stmt.bind_int(1, id)!=Sqlite.OK)) {
			this.db_error();
			return null;
		}
		TrackData td = null; 
		if(stmt.step() == Sqlite.ROW) {
			td = new TrackData();
			Item? i = Item((ItemType)stmt.column_int(1), stmt.column_text(4), stmt.column_int(2));
			
			td.artist      = stmt.column_text(5);
			td.album       = stmt.column_text(6);
			td.title       = stmt.column_text(0);
			td.item        = i;
			td.tracknumber = stmt.column_int(3);
			td.length      = stmt.column_int(7);
			td.genre       = stmt.column_text(8);
			td.year        = stmt.column_int(9);
		}
		return td;
	}

	private static const string STMT_GET_ALBUMS_WITH_SEARCH =
		"SELECT DISTINCT al.name, al.id FROM artists ar, albums al, items t, uris u WHERE ar.id = t.artist AND al.id = t.album AND u.id = t.uri AND ar.id = ? AND (ar.name LIKE ? OR al.name LIKE ? OR t.title LIKE ? OR u.name LIKE ?) ORDER BY LOWER(al.name) ASC";

	private static const string STMT_GET_ALBUMS =
		"SELECT DISTINCT al.name, al.id FROM artists ar, albums al WHERE ar.id = al.artist AND ar.id = ? ORDER BY LOWER(al.name) ASC";

	public Item[] get_albums_with_search(ref string searchtext, int32 id) {
		Item[] val = {};
		Statement stmt;
		
		if(searchtext != "") {
			this.db.prepare_v2(STMT_GET_ALBUMS_WITH_SEARCH, -1, out stmt);
			if((stmt.bind_int (1, id) != Sqlite.OK) ||
			   (stmt.bind_text(2, "%%%s%%".printf(searchtext)) != Sqlite.OK) ||
			   (stmt.bind_text(3, "%%%s%%".printf(searchtext)) != Sqlite.OK) ||
			   (stmt.bind_text(4, "%%%s%%".printf(searchtext)) != Sqlite.OK) ||
			   (stmt.bind_text(5, "%%%s%%".printf(searchtext)) != Sqlite.OK)) {
				this.db_error();
				return val;
			}
		}
		else {
			this.db.prepare_v2(STMT_GET_ALBUMS, -1, out stmt);
			if((stmt.bind_int(1, id)!=Sqlite.OK)) {
				this.db_error();
				return val;
			}
		}
		while(stmt.step() == Sqlite.ROW) {
			Item i = Item(ItemType.COLLECTION_CONTAINER_ALBUM, null, stmt.column_int(1));
			i.text = stmt.column_text(0);
			val += i;
		}
		return val;
	}

//	private static const string STMT_GET_TRACKDATA_FOR_ARTISTALBUM =
//		"SELECT DISTINCT t.title, t.mediatype, t.id, t.genre, t.year FROM artists ar, items t, albums al WHERE t.artist = ar.id AND t.album = al.id AND ar.name = ? AND al.name = ? AND (ar.name LIKE ? OR al.name LIKE ? OR t.title LIKE ?) ORDER BY t.tracknumber DESC, t.title DESC";


	private static const string STMT_GET_ITEMS_WITH_MEDIATYPES_AND_IDS =
		"SELECT DISTINCT t.title, t.mediatype, t.id FROM artists ar, items t, albums al WHERE t.artist = ar.id AND t.album = al.id AND ar.name = ? AND al.name = ? ORDER BY t.tracknumber DESC, t.title DESC";

	public TrackData[] get_titles_with_mediatypes_and_ids(string artist, string album) {
		TrackData[] val = {};
		Statement stmt;
		
		this.db.prepare_v2(STMT_GET_ITEMS_WITH_MEDIATYPES_AND_IDS, -1, out stmt);

		if((stmt.bind_text(1, artist)!=Sqlite.OK)|
		   (stmt.bind_text(2, album )!=Sqlite.OK)) {
			this.db_error();
		}

		while(stmt.step() == Sqlite.ROW) {
			TrackData twt = new TrackData();
			twt.name = stmt.column_text(0);
			twt.item = Item((ItemType)stmt.column_int(1), null , stmt.column_int(2)) ;
			val += twt;
		}
		return val;
	}

//	private static const string STMT_GET_TRACKDATA_f =
//		"SELECT DISTINCT t.title, t.mediatype, t.id, t.tracknumber, u.name FROM artists ar, items t, albums al, uris u WHERE t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND ar.name = ? AND al.name = ? ORDER BY t.tracknumber DESC, t.title DESC";

//	private static const string STMT_GET_ITEMS_WITH_DATA =
//		"SELECT DISTINCT t.title, t.mediatype, t.id, t.tracknumber, u.name FROM artists ar, items t, albums al, uris u WHERE t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND ar.name = ? AND al.name = ? ORDER BY t.tracknumber DESC, t.title DESC";

//	public TrackData[] get_trackdata_with_search(ref string searchtext, int32 artist_id, int32 album_id) {
//		TrackData[] val = {};
//		Statement stmt;
//		
//		this.db.prepare_v2(STMT_GET_ITEMS_WITH_DATA, -1, out stmt);
//		
//		stmt.reset();
////		if((stmt.bind_text(1, artist)!=Sqlite.OK)|
////		   (stmt.bind_text(2, album )!=Sqlite.OK)) {
////			this.db_error();
////		}
//		
//		while(stmt.step() == Sqlite.ROW) {
//			TrackData twt = new TrackData();
//			twt.artist    = artist;
//			twt.album     = album;
//			twt.title     = stmt.column_text(0);
//			twt.mediatype = (ItemType) stmt.column_int(1);
//			twt.db_id = stmt.column_int(2);
//			twt.tracknumber = stmt.column_int(3);
//			twt.uri = stmt.column_text(4);
//			val += twt;
//		}
//		return val;
//	}

//	private static const string STMT_GET_ITEMS_WITH_DATA =
//		"SELECT DISTINCT t.title, t.mediatype, t.id, t.tracknumber, u.name FROM artists ar, items t, albums al, uris u WHERE t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND ar.name = ? AND al.name = ? ORDER BY t.tracknumber DESC, t.title DESC";

//	public TrackData[] get_titles_with_data(string artist, string album) {
//		TrackData[] val = {};
//		Statement stmt;
//		
//		this.db.prepare_v2(STMT_GET_ITEMS_WITH_DATA, -1, out stmt);
//		
//		stmt.reset();
//		if((stmt.bind_text(1, artist)!=Sqlite.OK)|
//		   (stmt.bind_text(2, album )!=Sqlite.OK)) {
//			this.db_error();
//		}
//		
//		while(stmt.step() == Sqlite.ROW) {
//			TrackData twt = new TrackData();
//			twt.artist    = artist;
//			twt.album     = album;
//			twt.title     = stmt.column_text(0);
//			twt.mediatype = (ItemType) stmt.column_int(1);
//			twt.db_id = stmt.column_int(2);
//			twt.tracknumber = stmt.column_int(3);
//			twt.uri = stmt.column_text(4);
//			val += twt;
//		}
//		return val;
//	}
}

