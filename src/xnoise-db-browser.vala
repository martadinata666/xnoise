/* xnoise-db-browser.vala
 *
 * Copyright (C) 2009-2010  Jörn Magens
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

public errordomain Xnoise.DbError {
	FAILED;
}

public class Xnoise.DbBrowser {
	private const string DATABASE_NAME = "db.sqlite";
	private const string SETTINGS_FOLDER = ".xnoise";
	private string DATABASE;

	private static const string STMT_GET_ARTIST_COUNT_WITH_SEARCH =
		"SELECT COUNT (ar.name) FROM artists ar, items t, albums al WHERE t.artist = ar.id AND t.album = al.id AND (ar.name LIKE ? OR al.name LIKE ? OR t.title LIKE ?) ORDER BY LOWER(ar.name) DESC";
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
	private static const string STMT_TRACKDATA_FOR_URI =
		"SELECT ar.name, al.name, t.title, t.tracknumber, t.length FROM artists ar, items t, albums al, uris u WHERE t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND u.name = ?";
	private static const string STMT_TRACKDATA_FOR_ID =
		"SELECT ar.name, al.name, t.title, t.tracknumber, t.mediatype, u.name, t.length FROM artists ar, items t, albums al, uris u WHERE t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND t.id = ?";
	private static const string STMT_GET_ITEMS_WITH_MEDIATYPES_AND_IDS =
		"SELECT DISTINCT t.title, t.mediatype, t.id FROM artists ar, items t, albums al WHERE t.artist = ar.id AND t.album = al.id AND ar.name = ? AND al.name = ? AND (ar.name LIKE ? OR al.name LIKE ? OR t.title LIKE ?) ORDER BY t.tracknumber DESC, t.title DESC";
	private static const string STMT_STREAM_TD_FOR_ID =
		"SELECT name, uri FROM streams WHERE id = ?";
	private static const string STMT_URI_FOR_ID =
		"SELECT u.name FROM items t, uris u WHERE t.uri = u.id AND t.id = ?";
	private static const string STMT_TRACK_ID_FOR_URI =
		"SELECT t.id FROM items t, uris u WHERE t.uri = u.id AND u.name = ?";
	private static const string STMT_GET_LASTUSED =
		"SELECT uri FROM lastused";
	private static const string STMT_GET_VIDEO_DATA =
		"SELECT DISTINCT title, mediatype, id FROM items WHERE title LIKE ? AND mediatype = ? ORDER BY LOWER(title) DESC";
	private static const string STMT_GET_VIDEOS =
		"SELECT DISTINCT title FROM items WHERE title LIKE ? AND mediatype = ? ORDER BY LOWER(title) DESC";
	private static const string STMT_GET_ARTISTS =
		"SELECT DISTINCT ar.name FROM artists ar, items t, albums al WHERE t.artist = ar.id AND t.album = al.id AND (ar.name LIKE ? OR al.name LIKE ? OR t.title LIKE ?) ORDER BY LOWER(ar.name) DESC";
	private static const string STMT_GET_SOME_ARTISTS = 
		"SELECT DISTINCT ar.name FROM artists ar, items t, albums al WHERE t.artist = ar.id AND t.album = al.id AND (ar.name LIKE ? OR al.name LIKE ? OR t.title LIKE ?) ORDER BY LOWER(ar.name) ASC limit ? offset ?";
	private static const string STMT_GET_ALBUMS =
		"SELECT DISTINCT al.name FROM artists ar, items t, albums al WHERE t.artist = ar.id AND t.album = al.id AND ar.name = ? AND (ar.name LIKE ? OR al.name LIKE ? OR t.title LIKE ?) ORDER BY LOWER(al.name) DESC";
	private static const string STMT_GET_ITEMS =
		"SELECT DISTINCT t.title FROM artists ar, items t, albums al WHERE t.artist = ar.id AND t.album = al.id AND ar.name = ? AND al.name = ? AND t.title LIKE ? ORDER BY t.tracknumber DESC, LOWER(t.title) DESC";
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

	public DbBrowser() throws Error{
		DATABASE = dbFileName();
		db = null;
		if(Database.open_v2(DATABASE, out db, Sqlite.OPEN_READONLY, null)!=Sqlite.OK) {
			print("Can't open database: %s\n", (string)this.db.errmsg);
			throw new DbError.FAILED("failed messge");
		}
		if(this.db == null) {
			throw new DbError.FAILED("failed messge");
		}
	}
	
	//~DbBrowser() {
	//	print("dtor db browser\n");
	//}

	private Database db;

	private string dbFileName() {
		return GLib.Path.build_filename(global.settings_folder, DATABASE_NAME, null);
	}

	private void db_error() {
		print("Database error %d: %s \n\n", this.db.errcode(), this.db.errmsg());
	}

	public delegate void ReaderCallback(Database database);
	
	public void do_callback_transaction(ReaderCallback cb) {
		if(db == null) return;
		
		if(cb != null)
			cb(db);
	}

	public int count_artists_with_search(ref string searchtext) {
		Statement stmt;
		int count = 0;
		
		this.db.prepare_v2(STMT_GET_ARTIST_COUNT_WITH_SEARCH, -1, out stmt);
			
		stmt.reset();

		if((stmt.bind_text(1, "%%%s%%".printf(searchtext)) != Sqlite.OK)|
		   (stmt.bind_text(2, "%%%s%%".printf(searchtext)) != Sqlite.OK)|
		   (stmt.bind_text(3, "%%%s%%".printf(searchtext)) != Sqlite.OK)) {
			this.db_error();
		}
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

		if(stmt.bind_int(1, MediaType.VIDEO) != Sqlite.OK) {
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
			val.mediatype   = (MediaType)stmt.column_int(4);
			val.uri         = stmt.column_text(5);
			val.length      = stmt.column_int(6);
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
			File file = File.new_for_uri(val.uri);
			string fileBasename;
			if(file != null)
				fileBasename = GLib.Filename.display_basename(file.get_path());
			else
				fileBasename = val.uri;
			val.title = fileBasename;
		}
		return true;
	}

	public bool get_stream_td_for_id(int id, out TrackData val) {
		Statement stmt;
		val = new TrackData();
		this.db.prepare_v2(STMT_STREAM_TD_FOR_ID , -1, out stmt);
			
		stmt.reset();
		if(stmt.bind_int(1, id) != Sqlite.OK) {
			this.db_error();
		}
		if(stmt.step() == Sqlite.ROW) {
			val.artist      = "";
			val.album       = "";
			val.title       = stmt.column_text(0);
			val.mediatype   = MediaType.STREAM;
			val.uri         = stmt.column_text(1);
		}
		else {
			print("get_stream_td_for_id: track is not in db. ID: %d\n", id);
			return false;
		}
		return true;
	}

	public bool get_stream_for_id(int id, out string uri) {
		Statement stmt;
		
		this.db.prepare_v2(STMT_STREAM_TD_FOR_ID , -1, out stmt);
		
		stmt.reset();
		if(stmt.bind_int(1, id) != Sqlite.OK) {
			this.db_error();
		}
		if(stmt.step() == Sqlite.ROW) {
			uri = stmt.column_text(1);
			return true;
		}
		return false;
	}

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

	public bool get_trackdata_for_uri(string? uri, out TrackData val) {
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
			retval = true;
		}
		if((val.artist=="") | (val.artist==null)) {
			val.artist = "unknown artist";
		}
		if((val.album== "") | (val.album== null)) {
			val.album = "unknown album";
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
		
		stmt.reset();
		while(stmt.step() == Sqlite.ROW) {
			mfolders += stmt.column_text(0);
		}
		return mfolders;
	}

	public StreamData[] get_streams() {
		Statement stmt;
		StreamData[] sData = {};
		
		this.db.prepare_v2(STMT_GET_RADIOS, -1, out stmt);
			
		stmt.reset();
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
		stmt.reset();
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

	public string[] get_lastused_uris() {
		string[] val = {};
		Statement stmt;
		
		this.db.prepare_v2(STMT_GET_LASTUSED, -1,out stmt);
		
		stmt.reset();
		while(stmt.step() == Sqlite.ROW) {
			val += stmt.column_text(0);
		}
		return val;
	}
	
	public string[] get_uris(string search_string) {
		//print("searching for %s\n", STMT_GET_URIS.replace("?", search_string));
		string[] results = {};
		Statement stmt;
		
		this.db.prepare_v2(STMT_GET_URIS, -1, out stmt);
		
		stmt.reset();
		stmt.bind_text(1, search_string);
		while(stmt.step() == Sqlite.ROW) {
			//print("found %s", stmt.column_text(0));
			results += stmt.column_text(0);
		}
		return results;
	}

	public MediaData[] get_video_data(ref string searchtext) {
		MediaData[] val = {};
		Statement stmt;
		
		this.db.prepare_v2(STMT_GET_VIDEO_DATA, -1, out stmt);
		
		stmt.reset();
		if((stmt.bind_text(1, "%%%s%%".printf(searchtext)) != Sqlite.OK)|
		   (stmt.bind_int (2, (int)MediaType.VIDEO)        != Sqlite.OK)) {
			this.db_error();
		}
		while(stmt.step() == Sqlite.ROW) {
			MediaData vd = MediaData();
			vd.name = stmt.column_text(0);
			vd.mediatype = (MediaType)stmt.column_int(1);
			vd.id = stmt.column_int(2);
			val += vd;
		}
		return val;
	}

	public MediaData[] get_stream_data(ref string searchtext) {
		//	print("in get_stream_data\n");
		MediaData[] val = {};
		Statement stmt;
		
		this.db.prepare_v2(STMT_GET_RADIO_DATA, -1, out stmt);
		stmt.reset();
		if((stmt.bind_text(1, "%%%s%%".printf(searchtext)) != Sqlite.OK)) {
			this.db_error();
		}
		while(stmt.step() == Sqlite.ROW) {
			MediaData vd = MediaData();
			vd.id = stmt.column_int(0);
			vd.name = stmt.column_text(1);
			vd.mediatype = MediaType.STREAM;
			val += vd;
		}
		return val;
	}

	public string[] get_videos(ref string searchtext) {
		Statement stmt;
		string[] val = {};
		this.db.prepare_v2(STMT_GET_VIDEOS, -1, out stmt);
			
		stmt.reset();
		if((stmt.bind_text(1, "%%%s%%".printf(searchtext)) != Sqlite.OK)|
		   (stmt.bind_int (2, (int)MediaType.VIDEO)        != Sqlite.OK)) {
			this.db_error();
		}
		while(stmt.step() == Sqlite.ROW) {
			val += stmt.column_text(0);
		}
		return val;
	}

	private static const string STMT_GET_SOME_ARTISTS_2 = 
		"SELECT DISTINCT ar.name FROM artists ar, items t, albums al WHERE t.artist = ar.id AND t.album = al.id ORDER BY LOWER(ar.name) ASC limit ? offset ?";
	public string[] get_some_artists_2(int limit, int offset) {
		string[] val = {};
		Statement stmt;
		
		this.db.prepare_v2(STMT_GET_SOME_ARTISTS_2, -1, out stmt);
		
		stmt.reset();
		
		if((stmt.bind_int(1, limit ) != Sqlite.OK)|
		   (stmt.bind_int(2, offset) != Sqlite.OK)) {
			this.db_error();
		}
		while(stmt.step() == Sqlite.ROW) {
			val += stmt.column_text(0);
		}
		return val;
	}
	
//	public string[] get_some_artists(ref string searchtext, int limit, int offset) {
//		string[] val = {};
//		Statement stmt;
//		
//		this.db.prepare_v2(STMT_GET_SOME_ARTISTS, -1, out stmt);
//		
//		stmt.reset();
//		
//		if((stmt.bind_text(1, "%%%s%%".printf(searchtext)) != Sqlite.OK)|
//		   (stmt.bind_text(2, "%%%s%%".printf(searchtext)) != Sqlite.OK)|
//		   (stmt.bind_text(3, "%%%s%%".printf(searchtext)) != Sqlite.OK)|
//		   (stmt.bind_int(4, limit ) != Sqlite.OK)|
//		   (stmt.bind_int(5, offset) != Sqlite.OK)) {
//			this.db_error();
//		}
//		while(stmt.step() == Sqlite.ROW) {
//			val += stmt.column_text(0);
//		}
//		return val;
//	}

//	public string[] get_artists(ref string searchtext) {
//		string[] val = {};
//		Statement stmt;
//		
//		this.db.prepare_v2(STMT_GET_ARTISTS, -1, out stmt);
//		
//		stmt.reset();
//		
//		if((stmt.bind_text(1, "%%%s%%".printf(searchtext)) != Sqlite.OK)|
//		   (stmt.bind_text(2, "%%%s%%".printf(searchtext)) != Sqlite.OK)|
//		   (stmt.bind_text(3, "%%%s%%".printf(searchtext)) != Sqlite.OK)) {
//			this.db_error();
//		}
//		while(stmt.step() == Sqlite.ROW) {
//			val += stmt.column_text(0);
//		}
//		return val;
//	}
	private static const string STMT_GET_ARTISTS_2 =
		"SELECT DISTINCT ar.name FROM artists ar, items t, albums al WHERE t.artist = ar.id AND t.album = al.id ORDER BY LOWER(ar.name) DESC";
	public string[] get_artists_2() {
		string[] val = {};
		Statement stmt;
		
		this.db.prepare_v2(STMT_GET_ARTISTS_2, -1, out stmt);
		
		stmt.reset();
		
//		if((stmt.bind_text(1, "%%%s%%".printf(searchtext)) != Sqlite.OK)|
//		   (stmt.bind_text(2, "%%%s%%".printf(searchtext)) != Sqlite.OK)|
//		   (stmt.bind_text(3, "%%%s%%".printf(searchtext)) != Sqlite.OK)) {
//			this.db_error();
//		}
		while(stmt.step() == Sqlite.ROW) {
			val += stmt.column_text(0);
		}
		return val;
	}
	private static const string STMT_GET_ALBUMS_2 =
		"SELECT DISTINCT al.name FROM artists ar, items t, albums al WHERE t.artist = ar.id AND t.album = al.id AND ar.name = ? ORDER BY LOWER(al.name) DESC";
	public string[] get_albums_2(string artist) {
		string[] val = {};
		Statement stmt;
		
		this.db.prepare_v2(STMT_GET_ALBUMS_2, -1, out stmt);
		
		stmt.reset();
		if((stmt.bind_text(1, artist)!=Sqlite.OK)) {
			this.db_error();
		}
		while(stmt.step() == Sqlite.ROW) {
			val += stmt.column_text(0);
		}
		return val;
	}

//	public string[] get_albums(string artist, ref string searchtext) {
//		string[] val = {};
//		Statement stmt;
//		
//		this.db.prepare_v2(STMT_GET_ALBUMS, -1, out stmt);
//		
//		stmt.reset();
//		if((stmt.bind_text(1, artist)!=Sqlite.OK)|
//		   (stmt.bind_text(2, "%%%s%%".printf(searchtext)) != Sqlite.OK)|
//		   (stmt.bind_text(3, "%%%s%%".printf(searchtext)) != Sqlite.OK)|
//		   (stmt.bind_text(4, "%%%s%%".printf(searchtext)) != Sqlite.OK)) {
//			this.db_error();
//		}
//		while(stmt.step() == Sqlite.ROW) {
//			val += stmt.column_text(0);
//		}
//		return val;
//	}

	private static const string STMT_GET_TRACKDATA_FOR_ARTISTALBUM =
		"SELECT DISTINCT t.title, t.mediatype, t.id FROM artists ar, items t, albums al WHERE t.artist = ar.id AND t.album = al.id AND ar.name = ? AND al.name = ? AND (ar.name LIKE ? OR al.name LIKE ? OR t.title LIKE ?) ORDER BY t.tracknumber DESC, t.title DESC";

//	private static const string STMT_TRACKDATA_FOR_URI =
//		"SELECT ar.name, al.name, t.title, t.tracknumber, t.length FROM artists ar, items t, albums al, uris u WHERE t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND u.name = ?";
//	public bool get_trackdata_for_uri(string? uri, out TrackData val) {
//		bool retval = false;
//		val = new TrackData();
//		if(uri == null)
//			return retval;
//		
//		Statement stmt;
//		this.db.prepare_v2(STMT_TRACKDATA_FOR_URI, -1, out stmt);
//			
//		stmt.reset();
//		stmt.bind_text(1, uri);
//		if(stmt.step() == Sqlite.ROW) {
//			val.artist      = stmt.column_text(0);
//			val.album       = stmt.column_text(1);
//			val.title       = stmt.column_text(2);
//			val.tracknumber = (uint)stmt.column_int(3);
//			val.length      = stmt.column_int(4);
//			retval = true;
//		}
//		if((val.artist=="") | (val.artist==null)) {
//			val.artist = "unknown artist";
//		}
//		if((val.album== "") | (val.album== null)) {
//			val.album = "unknown album";
//		}
//		if((val.title== "") | (val.title== null)) {
//			val.title = "unknown title";
//			File file = File.new_for_uri(uri);
//			string fpath = file.get_path();
//			string fileBasename = "";
//			if(fpath!=null) fileBasename = GLib.Filename.display_basename(fpath);
//			val.title = fileBasename;
//		}
//		return retval;
//	}	
//	public TrackData[] get_trackdata_for_artistalbum(string artist, string album, ref string searchtext) {
//		Statement stmt;
//		TrackData[] retval = {};
//		this.db.prepare_v2(STMT_GET_TRACKDATA_FOR_ARTISTALBUM, -1, out stmt);

//		stmt.reset();
//		if((stmt.bind_text(1, artist)!=Sqlite.OK)|
//		   (stmt.bind_text(2, album )!=Sqlite.OK)|
//		   (stmt.bind_text(3, "%%%s%%".printf(searchtext)) != Sqlite.OK)|
//		   (stmt.bind_text(4, "%%%s%%".printf(searchtext)) != Sqlite.OK)|
//		   (stmt.bind_text(5, "%%%s%%".printf(searchtext)) != Sqlite.OK)) {
//			this.db_error();
//		}

//		while(stmt.step() == Sqlite.ROW) {
//			var val = new TrackData();
//			val.artist      = artist;
//			val.album       = album;
//			val.title       = stmt.column_text(0);
//			val.mediatype   = (MediaType) stmt.column_int(1);
//			val.id          = stmt.column_int(2);
//			
//			retval += val;
//		}
//		return retval;
//	}
	private static const string STMT_GET_ITEMS_WITH_MEDIATYPES_AND_IDS_2 =
		"SELECT DISTINCT t.title, t.mediatype, t.id FROM artists ar, items t, albums al WHERE t.artist = ar.id AND t.album = al.id AND ar.name = ? AND al.name = ? ORDER BY t.tracknumber DESC, t.title DESC";

	public MediaData[] get_titles_with_mediatypes_and_ids_2(string artist, string album) {
		MediaData[] val = {};
		Statement stmt;
		
		this.db.prepare_v2(STMT_GET_ITEMS_WITH_MEDIATYPES_AND_IDS_2, -1, out stmt);

		stmt.reset();
		if((stmt.bind_text(1, artist)!=Sqlite.OK)|
		   (stmt.bind_text(2, album )!=Sqlite.OK)) {
			this.db_error();
		}

		while(stmt.step() == Sqlite.ROW) {
			MediaData twt = MediaData();
			twt.name = stmt.column_text(0);
			twt.mediatype = (MediaType) stmt.column_int(1);
			twt.id = stmt.column_int(2);
			val += twt;
		}
		return val;
	}

	private static const string STMT_GET_ITEMS_WITH_DATA =
		"SELECT DISTINCT t.title, t.mediatype, t.id, t.tracknumber FROM artists ar, items t, albums al WHERE t.artist = ar.id AND t.album = al.id AND ar.name = ? AND al.name = ? ORDER BY t.tracknumber DESC, t.title DESC";

	public TrackData[] get_titles_with_data(string artist, string album) {
		TrackData[] val = {};
		Statement stmt;
		
		this.db.prepare_v2(STMT_GET_ITEMS_WITH_DATA, -1, out stmt);

		stmt.reset();
		if((stmt.bind_text(1, artist)!=Sqlite.OK)|
		   (stmt.bind_text(2, album )!=Sqlite.OK)) {
			this.db_error();
		}

		while(stmt.step() == Sqlite.ROW) {
			TrackData twt = new TrackData();
			twt.title = stmt.column_text(0);
			twt.mediatype = (MediaType) stmt.column_int(1);
			twt.db_id = stmt.column_int(2);
			twt.tracknumber = stmt.column_int(3);
			val += twt;
		}
		return val;
	}
	
//	public MediaData[] get_titles_with_mediatypes_and_ids(string artist, string album, ref string searchtext) {
//		MediaData[] val = {};
//		Statement stmt;
//		
//		this.db.prepare_v2(STMT_GET_ITEMS_WITH_MEDIATYPES_AND_IDS, -1, out stmt);

//		stmt.reset();
//		if((stmt.bind_text(1, artist)!=Sqlite.OK)|
//		   (stmt.bind_text(2, album )!=Sqlite.OK)|
//		   (stmt.bind_text(3, "%%%s%%".printf(searchtext)) != Sqlite.OK)|
//		   (stmt.bind_text(4, "%%%s%%".printf(searchtext)) != Sqlite.OK)|
//		   (stmt.bind_text(5, "%%%s%%".printf(searchtext)) != Sqlite.OK)) {
//			this.db_error();
//		}

//		while(stmt.step() == Sqlite.ROW) {
//			MediaData twt = MediaData();
//			twt.name = stmt.column_text(0);
//			twt.mediatype = (MediaType) stmt.column_int(1);
//			twt.id = stmt.column_int(2);
//			val += twt;
//		}
//		return val;
//	}
}

