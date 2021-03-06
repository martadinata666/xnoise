/* xnoise-mpris.vala
 *
 * Copyright (C) 2011 Jörn Magens
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
 * Jörn Magens
 */

using Gtk;
using Lastfm;

using Xnoise;
using Xnoise.Services;
using Xnoise.PluginModule;


public class Xnoise.Lfm : GLib.Object, IPlugin, IAlbumCoverImageProvider {
	public Main xn { get; set; }
	private unowned PluginModule.Container _owner;
	private Session session;
	private uint scrobble_source = 0;
	private uint now_play_source = 0;
	private int WAIT_TIME_BEFORE_SCROBBLE = 25;
	private int WAIT_TIME_BEFORE_NOW_PLAYING = 5;
	
	private ulong c = 0;
	private ulong d = 0;
	
	public PluginModule.Container owner {
		get {
			return _owner;
		}
		set {
			_owner = value;
		}
	}
	
	public string name { get { return "lastfm"; } }
	
	public signal void login_state_change();
	
	public bool init() {
		owner.sign_deactivated.connect(clean_up);
		
		session = new Lastfm.Session(
		   Lastfm.Session.AuthenticationType.MOBILE,   // session authentication type
		   "a39db9ab0d1fb9a18fabab96e20b0a34",         // xnoise api_key for noncomercial use
		   "55993a9f95470890c6806271085159a3",         // secret
		   null//"de"                                  // language TODO
		);
		c = session.notify["logged-in"].connect( () => {
			Idle.add( () => {
				login_state_change();
				return false;
			});
		});
		d = session.login_successful.connect( (sender, un) => {
			print("Lastfm plugin logged in %s successfully\n", un); // TODO: real feedback needed
		});
		string username = Xnoise.Params.get_string_value("lfm_user");
		string password = Xnoise.Params.get_string_value("lfm_pass");
		if(username != "" && password != "")
			this.login(username, password);
		
		global.notify["current-title"].connect(on_current_track_changed);
		global.notify["current-artist"].connect(on_current_track_changed);
		global.uri_changed.connect(on_current_uri_changed);
		global.player_in_shutdown.connect( () => { clean_up(); });
		return true;
	}
	
	public void uninit() {
		clean_up();
	}

	private void clean_up() {
		if(session != null) {
			session.abort();
			session.disconnect(c);
			session.disconnect(d);
			session = null;
		}
		scrobble_track = null;
		now_play_track = null;
	}
	
	~Lfm() {
	}

	public Gtk.Widget? get_settings_widget() {
		var w = new LfmWidget(this);
		return w;
	}

	public bool has_settings_widget() {
		return true;
	}
	
	public void login(string username, string password) {
		Idle.add( () => {
			session.login(username, password);
			return false;
		});
	}
	
	public bool logged_in() {
		return this.session.logged_in;
	}
	
	private Track scrobble_track;
	private Track now_play_track;
	
	private struct ScrobbleData {
		public string? uri;
		public string? artist;
		public string? album;
		public string? title;
		public int64 playtime;
	}
	
	private ScrobbleData sd_last;
	
	private void on_current_uri_changed(GLib.Object sender, string? p) {
		//scrobble
		if(sd_last.title != null && sd_last.artist != null) {
			if(session == null || !session.logged_in)
				return;
			if(scrobble_source != 0)
				Source.remove(scrobble_source);
			scrobble_source = Timeout.add(500, () => {
				var dt = new DateTime.now_utc();
				int64 pt = dt.to_unix();
				if((pt - sd_last.playtime) < WAIT_TIME_BEFORE_SCROBBLE)
					return false;
				// Use session's 'factory method to get Track
				scrobble_track = session.factory_make_track(sd_last.artist, sd_last.album, sd_last.title);
				
				// SCROBBLE TRACK
				scrobble_track.scrobble(sd_last.playtime);
				scrobble_source = 0;
				return false;
			});
		}
	}
	
	private void on_current_track_changed(GLib.Object sender, ParamSpec p) {
		if(global.current_title != null && global.current_artist != null) {
			if(session == null || !session.logged_in)
				return;
			//updateNowPlaying
			if(now_play_source != 0) 
				Source.remove(now_play_source);
			now_play_source = Timeout.add_seconds(WAIT_TIME_BEFORE_NOW_PLAYING, () => {
				// Use session's 'factory method to get Track
				if(global.current_title == null || global.current_artist == null) {
					now_play_source = 0;
					return false;
				}
				now_play_track = session.factory_make_track(global.current_artist, global.current_album, global.current_title);
				sd_last = ScrobbleData();
				sd_last.uri    = global.current_uri;
				sd_last.artist = global.current_artist;
				sd_last.album  = global.current_album;
				sd_last.title  = global.current_title;
				var dt = new DateTime.now_utc();
				sd_last.playtime = dt.to_unix();
				// UPDATE NOW PLAYING TRACK
				now_play_track.updateNowPlaying();
				now_play_source = 0;
				return false;
			});
		}
	}
	
	public Xnoise.IAlbumCoverImage from_tags(string artist, string album) {
		return new LastFmCovers(artist, album, this.session);
	}
}



/**
 * The LastFmCovers class tries to find cover images on 
 * lastFm.
 * The images are downloaded to a local folder below ~/.xnoise
 * The download folder is returned via a signal together with
 * the artist name and the album name for identification.
 * 
 * This class should be called from a closure to work with full
 * mainloop integration. No threads needed!
 * Copying is also done asynchonously.
 */
public class Xnoise.LastFmCovers : GLib.Object, IAlbumCoverImage {
	private const int SECONDS_FOR_TIMEOUT = 12;
	// Maybe add this key as a construct only property. Then it can be an individual key for each user
//	private const string lastfmKey = "b25b959554ed76058ac220b7b2e0a026";
	
	private const string INIFOLDER = ".xnoise";
//	private SessionAsync session;
	private string artist;
	private string album;
	private File f = null;
	private string image_path;
	private string[] sizes;
	private File[] image_sources;
	private uint timeout;
	private bool timeout_done;
	private unowned Lastfm.Session session;
	private Lastfm.Album alb;
	
	public LastFmCovers(string _artist, string _album, Lastfm.Session session) {
		this.artist = _artist;
		this.album  = _album;
		this.session = session;
		
		image_path = GLib.Path.build_filename(data_folder(),
		                                      "album_images",
		                                      null
		                                      );
		image_sources = {};
		sizes = {"medium", "extralarge"}; //Two are enough
		timeout = 0;
		timeout_done = false;
		alb = this.session.factory_make_album(artist, album);
		alb.received_info.connect( (sender, al) => {
			print("got album info: %s , %s\n", sender.artist_name, al);
			//print("image extralarge: %s\n", sender.image_uris.lookup("extralarge"));
			string default_size = "medium";
			string uri_image;
			foreach(string s in sizes) {
				f = get_albumimage_for_artistalbum(artist, album, s);
				if(default_size == s) uri_image = f.get_path();
				
				string pth = "";
				File f_path = f.get_parent();
				if(!f_path.query_exists(null)) {
					try {
						f_path.make_directory_with_parents(null);
					}
					catch(GLib.Error e) {
						print("Error with create image directory: %s\npath: %s", e.message, pth);
						remove_timeout();
						this.unref();
						return;
					}
				}
				
				if(!f.query_exists(null)) {
					var remote_file = File.new_for_uri(sender.image_uris.lookup(s));
					image_sources += remote_file;
				}
				else {
					//print("Local file already exists\n");
					continue; //Local file exists
				}
			}
			this.copy_covers_async(sender.reply_artist.down(), sender.reply_album.down());
		});
	}
	
	~LastFmCovers() {
		if(timeout != 0)
			Source.remove(timeout);
	}

	private void remove_timeout() {
		if(timeout != 0)
			Source.remove(timeout);
	}
	
	public void find_image() {
		//print("find_lastfm_image to %s - %s\n", artist, album);
		if((artist=="unknown artist")||
		   (album=="unknown album")) {
			sign_image_fetched(artist, album, "");
			this.unref();
			return;
		}
		
		alb.get_info(); // no login required
		//Add timeout for response
		timeout = Timeout.add_seconds(SECONDS_FOR_TIMEOUT, timeout_elapsed);
	}
	
	private bool timeout_elapsed() {
		this.timeout_done = true;
		this.unref();
		return false;
	}
	

	private async void copy_covers_async(string _reply_artist, string _reply_album) {
		File destination;
		bool buf = false;
		string default_path = "";
		int i = 0;
		string reply_artist = _reply_artist;
		string reply_album = _reply_album;
		
		foreach(File f in image_sources) {
			var s = sizes[i];
			destination = get_albumimage_for_artistalbum(reply_artist, reply_album, s);
			try {
				if(f.query_exists(null)) { //remote file exist
					
					buf = yield f.copy_async(destination,
					                         FileCopyFlags.OVERWRITE,
					                         Priority.DEFAULT,
					                         null,
					                         null);
				}
				else {
					continue;
				}
				if(sizes[i] == "medium") default_path = destination.get_path();
				i++;
			}
			catch(GLib.Error e) {
				print("Error: %s\n", e.message);
				i++;
				continue;
			}
		}
		// signal finish with artist, album in order to identify the sent image
		sign_image_fetched(reply_artist, reply_album, default_path);
		
		remove_timeout();
		
		if(!this.timeout_done) {
			this.unref(); // After this point LastFmCovers downloader can safely be removed
		}
		return;
	}
}


public class Xnoise.LfmWidget: Gtk.VBox {
	private unowned Main xn;
	private unowned Xnoise.Lfm lfm;
	private Entry user_entry;
	private Entry pass_entry;
	private Label feedback_label;
	private Button b;
	private string username_last;
	private string password_last;
	
	
	public LfmWidget(Xnoise.Lfm lfm) {
		GLib.Object(homogeneous:false, spacing:10);
		this.lfm = lfm;
		this.xn = Main.instance;
		setup_widgets();
		
		this.lfm.login_state_change.connect(do_user_feedback);
		
		user_entry.text = Xnoise.Params.get_string_value("lfm_user");
		pass_entry.text = Xnoise.Params.get_string_value("lfm_pass");
		b.clicked.connect(on_entry_changed);
	}

	//show if user is logged in
	private void do_user_feedback() {
		//print("do_user_feedback\n");
		if(this.lfm.logged_in()) {
			feedback_label.set_markup("<b><i>%s</i></b>".printf(_("User logged in!")));
			feedback_label.set_use_markup(true);
		}
		else {
			feedback_label.set_markup("<b><i>%s</i></b>".printf(_("User not logged in!")));
			feedback_label.set_use_markup(true);
		}
	}
	
	private void on_entry_changed() {
		//print("take over entry\n");
		string username = "", password = "";
		if(user_entry.text != null)
			username = user_entry.text.strip();
		if(pass_entry.text != null)
			password = pass_entry.text.strip();
		if(username_last == user_entry.text.strip() && password_last == pass_entry.text.strip())
			return; // no need to spam!
		if(username != "" && password != "") {
			//print("got login data\n");
			Xnoise.Params.set_string_value("lfm_user", username);
			Xnoise.Params.set_string_value("lfm_pass", password);
			username_last = username;
			password_last = password;
			Idle.add( () => {
				Xnoise.Params.write_all_parameters_to_file();
				return false;
			});
			do_user_feedback();
			lfm.login(username, password);
		}
	}
	
	private void setup_widgets() {
		var title_label = new Label("<b>%s</b>".printf(_("Please enter your lastfm username and password.")));
		title_label.set_use_markup(true);
		title_label.set_single_line_mode(true);
		title_label.set_alignment(0.5f, 0.5f);
		title_label.set_ellipsize(Pango.EllipsizeMode.END);
		title_label.ypad = 10;
		this.pack_start(title_label, false, false, 0);
		
		var hbox1 = new HBox(false, 2);
		var user_label = new Label("%s".printf(_("Username:")));
		hbox1.pack_start(user_label, false, false, 0);
		user_entry = new Entry();
		hbox1.pack_start(user_entry, true, true, 0);
		
		var hbox2 = new HBox(false, 2);
		var pass_label = new Label("%s".printf(_("Password:")));
		hbox2.pack_start(pass_label, false, false, 0);
		pass_entry = new Entry();
		pass_entry.set_visibility(false);
		
		hbox2.pack_start(pass_entry, true, true, 0);
		
		var sizegroup = new Gtk.SizeGroup(SizeGroupMode.HORIZONTAL);
		sizegroup.add_widget(user_label);
		sizegroup.add_widget(pass_label);
		
		this.pack_start(hbox1, false, false, 4);
		this.pack_start(hbox2, false, false, 4);
		
		//feedback
		feedback_label = new Label("<b><i>%s</i></b>".printf(_("User not logged in!")));
		if(this.lfm.logged_in()) {
			feedback_label.set_markup("<b><i>%s</i></b>".printf(_("User logged in!")));
		}
		else {
			feedback_label.set_markup("<b><i>%s</i></b>".printf(_("User not logged in!")));
		}
		feedback_label.set_use_markup(true);
		feedback_label.set_single_line_mode(true);
		feedback_label.set_alignment(0.5f, 0.5f);
		feedback_label.ypad = 20;
		this.pack_start(feedback_label, false, false, 0);
		
		b = new Button();
		b.set_label(_("Apply"));
		this.pack_start(b, true, true, 0);
		this.border_width = 4;
	}
}

