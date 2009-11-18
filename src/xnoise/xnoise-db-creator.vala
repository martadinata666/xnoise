/* xnoise-db-creator.vala
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

using Sqlite;

public class Xnoise.DbCreator : GLib.Object {
	private const string DATABASE_NAME = "db.sqlite";
	private const string SETTINGS_FOLDER = ".xnoise";
	private Sqlite.Database db;
	public static const int DB_VERSION_MAJOR = 3;
	public static const int DB_VERSION_MINOR = 0;
	private static File xnoisedb;
	//CREATE TABLE STATEMENTS
	private static const string STMT_CREATE_LASTUSED = 
		"CREATE TABLE lastused(uri text, mediatype integer);";
	private static const string STMT_CREATE_MEDIAFOLDERS = 
		"CREATE TABLE media_folders(name TEXT PRIMARY KEY);";
	private static const string STMT_CREATE_MEDIAFILES = 
		"CREATE TABLE media_files(name TEXT PRIMARY KEY);";
	private static const string STMT_CREATE_RADIO = 
		"CREATE TABLE streams (id INTEGER PRIMARY KEY, name TEXT, uri TEXT);";
	private static const string STMT_CREATE_ARTISTS = 
		"CREATE TABLE artists (id INTEGER PRIMARY KEY, name TEXT);";
	private static const string STMT_CREATE_ALBUMS = 
		"CREATE TABLE albums (id INTEGER PRIMARY KEY, artist INTEGER, name TEXT, image TEXT);";
	private static const string STMT_CREATE_URIS = 
		"CREATE TABLE uris (id INTEGER PRIMARY KEY, name TEXT, type INTEGER);";
	private static const string STMT_CREATE_GENRES = 
		"CREATE TABLE genres (id integer primary key, name TEXT);";
	private static const string STMT_CREATE_ITEMS = 
		"CREATE TABLE items (id INTEGER PRIMARY KEY, tracknumber INTEGER, artist INTEGER, album INTEGER, title TEXT, genre INTEGER, year INTEGER, uri INTEGER, mediatype INTEGER, length INTEGER, bitrate INTEGER, usertags TEXT, playcount INTEGER, rating INTEGER, lastplayTime DATETIME, addTime DATETIME);";
	//TODO: Is genre not used?
	private static const string STMT_CREATE_VERSION = 
		"CREATE TABLE version (major INTEGER, minor INTEGER);";
	private static const string STMT_GET_VERSION = 
		"SELECT major FROM version;";

	//FIND TABLE	
	private static const string STMT_FIND_TABLE = 
		"SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;";
									
	public DbCreator() {
        this.db = get_db();
		check_tables();
	}

	private static Database? get_db () {
		// there was more luck on creating the db on first start, when using a static function
		//TODO: Version check with drop table
		Database database;
		File home_dir = File.new_for_path(Environment.get_home_dir());
		File xnoise_home = home_dir.get_child(SETTINGS_FOLDER);
		xnoisedb = xnoise_home.get_child(DATABASE_NAME);
		if (!xnoise_home.query_exists(null)) {
			try {
				File current_dir = xnoise_home;
				File[] directory_list = {};
				while(current_dir != null) {
				    if (current_dir.query_exists (null)) break;
					directory_list += current_dir;
				    current_dir = current_dir.get_parent();
				}
				foreach(File dir in directory_list) {
				    print("Creating config path %s\n", dir.get_path());
				    dir.make_directory(null);
				}
			} 
			catch (Error e) {
				stderr.printf("Error with create directory: %s", e.message);
				return null;
			}
		}
		Database.open_v2(xnoisedb.get_path(), 
		                 out database, 
		                 Sqlite.OPEN_CREATE|Sqlite.OPEN_READWRITE, 
		                 null) ;

		return database;
	}
	
	private bool exec_stmnt_string(string statement) {
		string errormsg;
		if(db.exec(statement, null, out errormsg)!= Sqlite.OK) {
			stderr.printf("exec_stmnt_string error: %s", errormsg);
			return false;
		}
		return true;
	}

	private void check_tables() {
		if(xnoisedb.query_exists(null) && db!=null) {
			bool db_table_exists = false;
			int nrow,ncolumn;
			weak string[] resultArray;
			string errmsg;

			//Check for Table existance
			if(db.get_table(STMT_FIND_TABLE, out resultArray, out nrow, out ncolumn, out errmsg) != Sqlite.OK) { 
				stderr.printf("SQL error: %s\n", errmsg);
				return;
			}

			//search version table
			for(int offset = 1; offset < nrow + 1 && db_table_exists == false;offset++) {
				for(int j = offset*ncolumn; j<(offset+1)*ncolumn; j++) {
					if(resultArray[j]=="version") {
						db_table_exists = true; //assume that if version is existing all other tables also exist
						break;
					}
				}
			}
			if(db_table_exists == true) {
				if(db.get_table(STMT_GET_VERSION, out resultArray, out nrow, out ncolumn, out errmsg) != Sqlite.OK) { 
					stderr.printf("SQL error: %s\n", errmsg);
					return;
				}
				//newly create db if major version is devating
				string major = resultArray[1];
				if(major!=("%d".printf(DB_VERSION_MAJOR))) {
					print("Wrong major db version\n"); //TODO: Drop tables and create new
					db = null;
					try {
						xnoisedb.delete(null);
					}
					catch(Error e) {
						print("%s\n", e.message);
					}
				}
			}
			else {
			//create Tables if not existant
				if(!exec_stmnt_string(STMT_CREATE_LASTUSED)     ) return;
				if(!exec_stmnt_string(STMT_CREATE_MEDIAFOLDERS) ) return;
				if(!exec_stmnt_string(STMT_CREATE_MEDIAFILES)   ) return;
				if(!exec_stmnt_string(STMT_CREATE_RADIO)        ) return;
				if(!exec_stmnt_string(STMT_CREATE_ARTISTS)      ) return;
				if(!exec_stmnt_string(STMT_CREATE_ALBUMS)       ) return;
				if(!exec_stmnt_string(STMT_CREATE_URIS)         ) return;
				if(!exec_stmnt_string(STMT_CREATE_ITEMS)        ) return;
				if(!exec_stmnt_string(STMT_CREATE_GENRES)       ) return;
				if(!exec_stmnt_string(STMT_CREATE_VERSION)      ) return;
				//Set database version
				exec_stmnt_string("INSERT INTO version (major, minor) VALUES (%d, %d);".printf(DB_VERSION_MAJOR, DB_VERSION_MINOR));
			}
		}
		else {
			print("Could not create or open database.\n");
		}
	}
}
