/* xnoise-gst-player.vala
 *
 * Copyright (C) 2009 - 2011 Jörn Magens
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

using Gst;

public class Xnoise.GstPlayer : GLib.Object {
	private bool _current_has_video;
	private bool _current_has_subtitles;
	
	private uint cycle_time_source;
	private uint update_tags_source;
//	private uint check_for_video_source;
//	private uint check_for_subtitles_source;
	
	private enum SelectableType {
		NONE = 0,
		AUDIO,
		VIDEO,
		TEXT
	}
	
	private string? _uri = null;
	private Gst.TagList _taglist;
	private int64 _length_time;
	public VideoScreen videoscreen;
	private GLib.List<Gst.Message> missing_plugins = new GLib.List<Gst.Message>();
	private dynamic Element playbin;
	
	public bool current_has_video { // TODO: Determine this elsewhere
		get {
			return _current_has_video;
		}
	}

	public bool current_has_subtitles { 
		get {
			return _current_has_subtitles;
		}
	}

	public double volume {
		get {
			double val;
			val = this.playbin.volume;
			return val;
		}
		set {
			double val;
			val = this.playbin.volume;
			if(val!=value) {
				this.playbin.volume = value;
				
				//signal is used in mainwindow to update volume slider
				sign_volume_changed(value); 
			}
		}
	}

	public bool playing           { get; set; }
	public bool paused            { get; set; }
	public bool seeking           { get; set; }
	public bool is_stream         { get; private set; default = false; }
	public bool buffering         { get; private set; default = false; }
	
	public int64 length_time { 
		get {
			return _length_time;
		} 
		set {
			_length_time = value;
		}
	}

	private Gst.TagList taglist {
		get {
			return _taglist;
		}
		private set {
			if (value != null) {
				_taglist = value.copy();
			} else
				_taglist = null;
		}
	}

	public string? uri {
		get {
			return _uri;
		}
		set {
			is_stream = false; //reset
			_uri = value;
			if((value == "")||(value == null)) {
				playbin.set_state(State.NULL); //stop
				//print("uri = null or '' -> set to stop\n");
				playing = false;
				paused = false;
			}
			this._current_has_video = false;
			videoscreen.trigger_expose();

			//reset
			taglist = null;
			length_time = 0;
			this.playbin.uri = (value == null ? "" : value);
			if(value != null) {
				File file = File.new_for_commandline_arg(value);
				if(file.get_uri_scheme() in global.remote_schemes)
					is_stream = true;
			}
			sign_song_position_changed((uint)0, (uint)0); //immediately reset song progressbar
		}
	}

	public string? suburi {
		get {
			return playbin.suburi;
		}
		set {
			playbin.suburi = value;
		}
	}

	public int current_text {
		get {
			return playbin.current_text;
		}
		set {
			playbin.current_text = value;
		}
	}

	public int n_text {
		get {
			return playbin.n_text;
		}
	}

	public double gst_position {
		get {
			int64 pos;
			Gst.Format format = Gst.Format.TIME;
			if(!playbin.query_position(ref format, out pos))
					return 0.0;
			return (double)pos/(double)_length_time;
		}
		set {
			if(seeking == false) {
				playbin.seek(1.0, Gst.Format.TIME,
				             Gst.SeekFlags.FLUSH|Gst.SeekFlags.ACCURATE,
				             Gst.SeekType.SET, (int64)(value * _length_time),
				             Gst.SeekType.NONE, -1);
			}
		}
	}

	public signal void sign_song_position_changed(uint msecs, uint ms_total);
	public signal void sign_playing();
	public signal void sign_paused();
	public signal void sign_stopped();
	
	public signal void sign_video_playing();
	public signal void sign_subtitles_playing();
	
	public signal void sign_buffering(int percent);
	public signal void sign_volume_changed(double volume);

	private signal void sign_missing_plugins();

	public GstPlayer() {
		videoscreen = new VideoScreen();
		create_elements();
		cycle_time_source = GLib.Timeout.add_seconds(1, on_cyclic_send_song_position);
		update_tags_source = 0;
//		check_for_video_source = 0;

		global.uri_changed.connect( () => {
			this.request_location(global.current_uri);
		});

		global.player_state_changed.connect( () => {
			if(global.player_state == PlayerState.PLAYING)
				this.play();
			else if(global.player_state == PlayerState.PAUSED)
				this.pause();
			else if(global.player_state == PlayerState.STOPPED)
				this.stop();
		});
		
		global.sign_restart_song.connect( () => {
			playbin.seek(1.0, Gst.Format.TIME,
			             Gst.SeekFlags.FLUSH|Gst.SeekFlags.ACCURATE,
			             Gst.SeekType.SET, (int64)(0.0 * _length_time),
			             Gst.SeekType.NONE, -1);
			this.playSong();
		});
		sign_missing_plugins.connect(on_sign_missing_plugins); 
	}

	private void request_location(string? xuri) {
		bool playing_buf = playing;
		playbin.set_state(State.READY);
		
		this.uri = xuri;

		if(playing_buf)
			playbin.set_state(State.PLAYING);
	}

	private void handle_eos_via_idle() {
		Idle.add ( () => { 
			global.handle_eos();
			return false;
		});
	}
	
	private void on_about_to_finish(Gst.Element sender) {
		handle_eos_via_idle();
	}

	private void create_elements() {
		taglist = null;
		playbin = ElementFactory.make("playbin2", "playbin");
		
		playbin.text_changed.connect( () => {
			print("playbin2 got text-changed signal. number of texts = %d\n", playbin.n_text);
			foreach(string s in get_available_languages(SelectableType.TEXT))
				print("found language %s\n", s);
			Idle.add( () => {
				int n_text = 0;
				n_text = playbin.n_text;
				if(n_text > 0) {
					this._current_has_subtitles = true;
					sign_subtitles_playing();
				}
				else {
					this._current_has_subtitles = false;
				}
				return false;
			});
		});
		
		playbin.video_changed.connect( () => {
			Idle.add( () => {
				int n_video = 0;
				n_video = playbin.n_video;
				if(n_video > 0) {
					this._current_has_video = true;
					sign_video_playing();
				}
				else {
					this._current_has_video = false;
					videoscreen.trigger_expose();
				}
				return false;
			});
		});
		
		playbin.about_to_finish.connect(on_about_to_finish);
		playbin.audio_tags_changed.connect(on_audio_tags_changed);
		
		var bus = new Gst.Bus ();
		bus = playbin.get_bus();
		bus.add_signal_watch();
		bus.message.connect(this.on_bus_message);
		bus.enable_sync_message_emission();
		bus.sync_message.connect(this.on_sync_message);
	}
	
	private void on_audio_tags_changed(Gst.Element sender, int stream_number) {
		TagList tags = null;
		Signal.emit_by_name(playbin, "get-audio-tags", stream_number, ref tags);
		if(taglist == null && tags != null) {
			taglist = tags;
		}
		else if(tags != null){
			taglist.merge(tags, TagMergeMode.REPLACE);
		}
		
		if(this.taglist == null) 
			return;
		
		if(update_tags_source != 0)
			Source.remove(update_tags_source);
		
		update_tags_source = Idle.add(update_tags);
	}

	private bool update_tags() {
		if(taglist == null)
			return false;
		taglist.@foreach(foreachtag);
		return false;
	}

	private void on_bus_message(Gst.Message msg) {
		if((msg == null)||(msg.get_structure() == null)) 
			return;
		switch(msg.type) {
			case Gst.MessageType.ELEMENT: {
				string type = null;
				string source;

				source = msg.src.get_name();
				type   = msg.get_structure().get_name();

				if(type == null)
					break;

				if(type == "missing-plugin") {
					//print("missing plugins msg for element\n");
					//print("src_name: %s; type_name: %s\n", source, type);
					missing_plugins.prepend(msg);
					return;
				}
				break;
			}
			case Gst.MessageType.ERROR: {
				Error err;
				string debug;
				msg.parse_error(out err, out debug);
				print("GstError parsed: %s\n", err.message);
				//print("Debug: %s\n", debug);
				if(!is_missing_plugins_error(msg)) {
					//print("Error is not missing plugin error\n");
					handle_eos_via_idle(); //this is used to go to the next track
				}
				break;
			}
			case Gst.MessageType.EOS: {
				handle_eos_via_idle();
				break;
			}
			default: break;
		}
	}

	private bool is_missing_plugins_error(Gst.Message msg) {
		//print("in is_missing_plugins_error?\n");
		bool retval = false;
		Error err = null;
		string debug;
		
		if(missing_plugins == null) {
			//print("messages is null and therefore no missing_plugin message\n");
			return false;
		}
		msg.parse_error(out err, out debug);
		
		//print("err.code: %d\n", (int)err.code);
		
		if(err is Gst.CoreError && ((int)(err.code) == (int)(Gst.StreamError.CODEC_NOT_FOUND))) {
			//print("is missing plgins error \n");
			Idle.add( () => {
				userinfo.popup(UserInfo.RemovalType.CLOSE_BUTTON,
				               UserInfo.ContentClass.WARNING,
				               "Missing plugins error",
				               true,
				               5,
				               null);
				return false;
			});
			sign_missing_plugins();
		} 
		return retval;
	}
	
	private void on_sign_missing_plugins() {
		//print("sign_missing_plugins!!!!\n");
		stop();
		return;
	}
	
	private GLib.List<string>? get_available_languages(SelectableType selected) {
		GLib.List<string>? result = null;
		int stream_number = 1;
		int n = 0;
		
		switch(selected) {
			case SelectableType.AUDIO: {
				if((n = playbin.n_audio) == 0)
					return null;
				
				for(int i = 0; i < n; i++) {
					TagList tags = null;
					Signal.emit_by_name(playbin, "get-audio-tags", i, ref tags);
					
					if(tags != null) {
						string language_code = null, codec = null;
						tags.get_string(Gst.TAG_LANGUAGE_CODE, out language_code);
						tags.get_string(Gst.TAG_CODEC, out codec);
						
						if(language_code != null) {
							if(result == null) 
								result = new GLib.List<string>();
							result.prepend(language_code);
						}
						else if(codec != null) {
							if(result == null) 
								result = new GLib.List<string>();
							result.prepend(codec);
						}
						else {
							if(result == null) 
								result = new GLib.List<string>();
							result.prepend("%s%d".printf(_("Audio Track #"), stream_number++));
						}
					}
					else {
						if(result == null) 
							result = new GLib.List<string>();
						result.prepend("%s%d".printf(_("Audio Track #"), stream_number++));
					}
				}
				break;
			}
			case SelectableType.TEXT: {
				if((n = playbin.n_text) == 0)
					return null;
				
				for(int i = 0; i < n; i++) {
					TagList tags = null;
					Signal.emit_by_name(playbin, "get-audio-tags", i, ref tags);
					
					if(tags != null) {
						string language_code = null, codec = null;
						tags.get_string(Gst.TAG_LANGUAGE_CODE, out language_code);
						tags.get_string(Gst.TAG_CODEC, out codec);
						
						if(language_code != null) {
							if(result == null) 
								result = new GLib.List<string>();
							result.prepend(language_code);
						}
						else if(codec != null) {
							if(result == null) 
								result = new GLib.List<string>();
							result.prepend(codec);
						}
						else {
							if(result == null) 
								result = new GLib.List<string>();
							result.prepend("%s%d".printf(_("Subtitle #"), stream_number++));
						}
					}
					else {
						if(result == null) 
							result = new GLib.List<string>();
						result.prepend("%s%d".printf(_("Subtitle #"), stream_number++));
					}
				}
				break;
			}
			default: {
				print("Invalid selection %s\n", selected.to_string());
				return null;
			}
		}
		return result;
	}

	/**
	 * For video synchronization and activation of video screen
	 */
	private void on_sync_message(Gst.Message msg) {
		if((msg == null)||(msg.get_structure() == null)) 
			return;
		string message_name = msg.get_structure().get_name();
		//print("%s\n", message_name);
		if(message_name=="prepare-xwindow-id") {
			var imagesink = (XOverlay)(msg.src);
			imagesink.set_property("force-aspect-ratio", true);
			imagesink.set_xwindow_id(Gdk.x11_drawable_get_xid(videoscreen.get_window()));
		}
	}

	private void foreachtag(TagList list, string tag) {
		if(list == null)
			return;
		string val = null;
		//print("tag: %s\n", tag);
		switch(tag) {
		case "artist":
			if(list.get_string(tag, out val))
				if(val != global.current_artist) global.current_artist = val;
			break;
		case "album":
			if(list.get_string(tag, out val))
				if(val != global.current_album) global.current_album = val;
			break;
		case "title":
			if(list.get_string(tag, out val))
				if(val != global.current_title) global.current_title = val;
			break;
		case "location":
			if(list.get_string(tag, out val))
				if(val != global.current_location) global.current_location = val;
			break;
		case "genre":
			if(list.get_string(tag, out val))
				if(val != global.current_genre) global.current_genre = val;
			break;
		case "organization":
			if(list.get_string(tag, out val))
				if(val != global.current_organization) global.current_organization = val;
			break;
		default:
			break;
		}
	}

	private bool on_cyclic_send_song_position() {
		if(!is_stream) {
			Gst.Format fmt = Gst.Format.TIME;
			int64 pos, len;
			if((playbin.current_state == State.PLAYING)&&(playing == false)) {
				playing = true;
				paused  = false;
			}
			if((playbin.current_state == State.PAUSED)&&(paused == false)) {
				paused = true;
				playing = false;
			}
			if(seeking == false) {
				playbin.query_duration(ref fmt, out len);
				length_time = (int64)len;
				if(playing == false) return true;
				if(!playbin.query_position(ref fmt, out pos))
					return true;
				sign_song_position_changed((uint)(pos/1000000), (uint)(len/1000000));
			}
	//		print("current:%s \n",playbin.current_state.to_string());
		}
		//print("flags: %d\n", (int)playbin.flags);
		return true;
	}

	public void play() {
		playbin.set_state(Gst.State.PLAYING);
		playing = true;
		paused = false;
		sign_playing();
	}

	public void pause() {
		playbin.set_state(State.PAUSED);
		playing = false;
		paused = true;
		sign_paused();
	}

	public void stop() {
		playbin.set_state(State.NULL); //READY
		playing = false;
		paused = false;
		sign_stopped();
	}

	// This is a pause-play action to take over the new uri for the playbin
	// It recovers the original state or can be forced to play
	public void playSong(bool force_play = false) {
		bool buf_playing = ((global.player_state == PlayerState.PLAYING)||force_play);
		playbin.set_state(State.READY);
		if(buf_playing == true) {
			Idle.add( () => {
				play();
				return false;
			});
		}
		else {
			sign_paused();
		}
		playbin.volume = volume; // TODO: Volume should have a global representation
	}
	
	public void request_time_offset_seconds(int seconds) {
		if(playing == false && paused == false)
			return;
		if(!is_stream) {
			if(seeking == false) {
				Gst.Format fmt = Gst.Format.TIME;
				int64 pos, new_pos;
				if(!playbin.query_position(ref fmt, out pos))
					return;
				new_pos = pos + (int64)((int64)seconds * (int64)1000000000);
				//print("%lli %lli %lli %lli\n", pos, new_pos, _length_time, (int64)((int64)seconds * (int64)1000000000));
			
				if(new_pos > _length_time) new_pos = _length_time;
				if(new_pos < 0)            new_pos = 0;
				
				playbin.seek(1.0, Gst.Format.TIME,
				             Gst.SeekFlags.FLUSH|Gst.SeekFlags.ACCURATE,
				             Gst.SeekType.SET, new_pos,
				             Gst.SeekType.NONE, -1);
				sign_song_position_changed((uint)(new_pos/1000000), (uint)(_length_time/1000000));
			}
		}
	}
}

