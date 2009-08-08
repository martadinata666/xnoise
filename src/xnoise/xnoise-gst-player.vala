/* xnoise-gst-player.vala
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

using Gst;

public class Xnoise.GstPlayer : GLib.Object {
	private bool _current_has_video;
	private uint timeout;
	private int64 length_time;
	private string _Uri = "";
	private TagList _taglist;
	public VideoScreen videoscreen;
	public dynamic Element playbin;
	public bool seeking  { get; set; } //TODO
	public bool current_has_video { 
		get {
			return _current_has_video;
		} 
		set {
			_current_has_video = value;
			if(!_current_has_video) {
				//TODO: This should only be triggered if logo is not already there.
				//Otherwise there is a flickering
				Gdk.EventExpose e = Gdk.EventExpose();
				e.type = Gdk.EventType.EXPOSE;
				e.window = videoscreen.window;
				var rect = Gdk.Rectangle();
				rect.x = 0;
				rect.y = 0;
				rect.width = videoscreen.allocation.width;
				rect.height = videoscreen.allocation.height;
				e.area = rect;
				Gdk.Region region = Gdk.Region.rectangle(rect);
				e.region = region;
				e.count = 0;
				e.send_event = (char)1;
				videoscreen.expose_event(e);
			}
		}
	}
	
	public double volume { 
		get {
			double val;
			this.playbin.get("volume", out val);
			return val;
		} 
		set {
			sign_volume_changed(value); 
			this.playbin.set("volume", value);
		}
	}
	   
	public bool   playing  { get; set; }
	public bool   paused   { get; set; }
	
	public string currentartist { get; private set; }
	public string currentalbum  { get; private set; }
	public string currenttitle  { get; private set; }

	public TagList taglist { 
		get { 
			return _taglist; 
		}
		private set {
			if (value != null) {
				_taglist = value.copy ();
			} else
				_taglist = null;
		}
	}
	
	public string Uri { 
		get {
			return _Uri;
		}
		set {
			print("set_uri\n");
			_Uri = value;
			this.current_has_video = false;
			taglist = null;
			this.playbin.set("uri", value);
			sign_song_position_changed((uint)0, (uint)0); //immediately reset song progressbar
		}
	}
	
	public double gst_position {
		set {
			if(seeking == false) {
				playbin.seek(1.0, Gst.Format.TIME, Gst.SeekFlags.FLUSH | Gst.SeekFlags.ACCURATE, 
					Gst.SeekType.SET, (int64)(value * length_time), Gst.SeekType.NONE, -1);
			}
		}
	}

	public signal void sign_song_position_changed(uint msecs, uint ms_total);
	public signal void sign_stopped();
	public signal void sign_eos();
	public signal void sign_tag_changed(string newuri);
	public signal void sign_video_playing();
	//public signal void sign_state_changed(int state);
	public signal void sign_paused();
	public signal void sign_playing();
	public signal void sign_volume_changed(double volume);

	public GstPlayer() {
		videoscreen = new VideoScreen();
		create_elements();
		timeout = GLib.Timeout.add_seconds(1, on_cyclic_send_song_position); //once per second is enough?
		this.notify += (s, p) => {
			switch(p.name) {
				case "Uri": {
					this.currentartist = "unknown artist";
					this.currentalbum = "unknown album";
					this.currenttitle = "unknown title";
					break;
				}
				case "currentartist": {
					this.sign_tag_changed(this.Uri);
					break;
				}
				case "currentalbum": {
					this.sign_tag_changed(this.Uri);
					break;
				}
				case "currenttitle": {
					this.sign_tag_changed(this.Uri);
					break;
				}
				case "taglist": {
					if(this.taglist == null) return;
					taglist.foreach(foreachtag);
					break;
				}
				default: break;
			}
		};
	}
	
	private void create_elements() {
		playbin = ElementFactory.make("playbin", "playbin");
        taglist = null;
		var bus = new Bus ();
		bus = playbin.get_bus();
		bus.add_signal_watch();
		bus.message += this.on_message;
		bus.enable_sync_message_emission();
		bus.sync_message += this.on_sync_message;
	}

	private void get_stream_info() {
		weak GLib.List <dynamic GLib.Object> stream_info = null;
		stream_info = this.playbin.stream_info;
		if(stream_info==null) return;
		for(int i=0;i<stream_info.length();i++) {
			dynamic GLib.Object info = stream_info.nth_data(i);
			if (info == null) {
				continue;
			}
			get_audiovideo_info(info);
		}
	}

	private void get_audiovideo_info(dynamic GLib.Object info) {
		Pad pad = (Pad)info.object;
		if(pad==null) return;
		Gst.Caps caps = pad.get_negotiated_caps();
		if(caps==null) return;
		weak Structure structure = caps.get_structure(0);
		if (structure == null) return;
		StreamType streamtype = info.type;
		if(streamtype==StreamType.VIDEO) {
			this.current_has_video = true;
			sign_video_playing();
		}
	}
	
	private void on_message(Gst.Message msg) {
		switch(msg.type) {
			case Gst.MessageType.STATE_CHANGED: {
				State newstate;
				State oldstate;
				msg.parse_state_changed (out oldstate, out newstate, null);
				if((newstate==State.PLAYING)&&((oldstate==State.PAUSED)||(oldstate==State.READY))) {
				    this.get_stream_info();
		        }
				break;
			}			
			case Gst.MessageType.ERROR: {
				Error err;
				string debug;
				msg.parse_error(out err, out debug);
				stdout.printf("Error: %s\n", err.message);
				this.sign_eos(); //this is used to go to the next track
				break;
			}
			case Gst.MessageType.EOS: {
				this.sign_eos();
				break;
			}
			case Gst.MessageType.TAG: {
				TagList tag_list;			
				msg.parse_tag(out tag_list);
				if (taglist == null && tag_list != null) {
					taglist = tag_list;
				}
				else {
					taglist.merge(tag_list, TagMergeMode.REPLACE);
				}
				break;
			}
			default: break;
		}			
	}

	private void on_sync_message(Gst.Message msg) {
		if(msg.structure==null)
			return;
		string message_name = msg.structure.get_name();
		if(message_name=="prepare-xwindow-id") {
			var imagesink = (XOverlay)msg.src;
			imagesink.set_property("force-aspect-ratio", true);
			imagesink.set_xwindow_id(Gdk.x11_drawable_get_xid(videoscreen.window));
		}
	}
	
	private void foreachtag(TagList list, string tag) {
		string val = null;
		switch (tag) {
		case "artist":
			if(list.get_string(tag, out val)) 
				if(val!=this.currentartist) this.currentartist = val;
			break;
		case "album":
			if(list.get_string(tag, out val)) 
				if(val!=this.currentalbum) this.currentalbum = val;
			break;
		case "title":
			if(list.get_string(tag, out val)) 
				if(val!=this.currenttitle) this.currenttitle = val;
			break;
		default:
			break;
		}
	}

	private bool on_cyclic_send_song_position() {
		Gst.Format fmt = Gst.Format.TIME;
		int64 pos, len;
		if ((playbin.current_state == State.PLAYING)&&(playing == false)) {
			playing = true; 
			paused  = false;
		}
		if ((playbin.current_state == State.PAUSED)&&(paused == false)) {
			paused = true; 
			playing = false; 
		}
		if (playing == false) return true; 
		if(seeking == false) {
			playbin.query_position(ref fmt, out pos);
			playbin.query_duration(ref fmt, out len);
			length_time = (int64)len;
			sign_song_position_changed((uint)(pos/1000000), (uint)(len/1000000));
		}
//		print("current:%s \n",playbin.current_state.to_string());
		return true;
	}

	private void wait() {
		State stateOld, stateNew; 
		playbin.get_state(out stateOld, out stateNew, (Gst.ClockTime)50000000); 
	}

	public void play() {
		playbin.set_state(State.PLAYING);
		wait();
		playing = true;
		paused = false;
		sign_playing();
	}

	public void pause() {
		playbin.set_state(State.PAUSED);
		wait();
		playing = false;
		paused = true;
		sign_paused();
	}

	public void stop() {
		playbin.set_state(State.READY);
		wait();
		playing = false;
		paused = false;
		sign_stopped();
	}

	//this is a pause-play action to take over the new uri for the playbin
	public void playSong(bool force_play = false) { 
		print("playsong\n");
		if(playing) print("playing=true\n");
		if(force_play) print("force_play=true\n");
		bool buf_playing = (playing|force_play)&&(!paused);
		playbin.set_state(State.READY);
		if (buf_playing == true) {
			playbin.set_state(State.PLAYING);
			wait();
			playing = true;
		}
		playbin.set("volume", volume);
	}
}

