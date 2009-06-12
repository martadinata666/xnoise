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

internal class Xnoise.GstPlayer : GLib.Object {
	private uint _timeout;
	private int64 length_time;
	private string _Uri = "";
	public Element playbin;
//	public bool   paused_last_state;
	public bool   seeking  { get; set; } //TODO
	public double volume   { get; set; }   
	public bool   playing  { get; set; }
	public bool   paused   { get; set; }
	
	public string currentartist { get; set; }
	public string currentalbum  { get; set; }
	public string currenttitle  { get; set; }

	public string Uri { 
		get {
			return _Uri;
		}
		set {
			_Uri = value;
			this.playbin.set("uri", value);
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
//	public signal void sign_state_changed(int state);

	public GstPlayer() {
		string[] args = null;
		Gst.init (ref args);
		create_elements();
		_timeout = GLib.Timeout.add (500, on_cyclic_send_song_position);
		this.notify += (s, p) => {
			switch(p.name) {
				case "Uri": {
					this.currentartist = null;
					this.currentalbum = null;
					this.currenttitle = null;
					break;
				}
				case "currentartist": {
					this.sign_tag_changed(s.Uri);
					break;
				}
				case "currentalbum": {
					this.sign_tag_changed(s.Uri);
					break;
				}
				case "currenttitle": {
					this.sign_tag_changed(s.Uri);
					break;
				}
				default: break;
//				case "paused": {
//					if(this.paused!=this.paused_last_state) {
//						sign_paused_changed(s.paused);
//					}
//					this.paused_last_state = this.paused;
//				}
			}
		};
	}

	private void create_elements() {
		playbin = ElementFactory.make("playbin", "playbin");
		var bus = new Bus ();
		bus = playbin.get_bus();
		bus.add_signal_watch();
		bus.message += (bus, msg) => {
			//	print("Message: %d\n", msg.type);
			switch(msg.type) {
				case MessageType.ERROR: {
					Error err;
					string debug;
					msg.parse_error(out err, out debug);
					stdout.printf("Error: %s\n", err.message);
					this.sign_eos(); //this is used to go to the next track
					break;
				}
				case MessageType.EOS: {
					this.sign_eos();
					break;
				}
				case MessageType.TAG: {
					TagList tag_list;			
					msg.parse_tag(out tag_list);
					tag_list.foreach(foreachtag);					
				}
				default: break;
			}			
		};				
	}

	private void foreachtag(TagList list, string tag) {
		string val = null;
		switch (tag) {
		case "artist":
			if(list.get_string(tag, out val)) 
				this.currentartist = val;
			else 
				this.currentartist = "unknown artist";
			break;
		case "album":
			if(list.get_string(tag, out val)) 
				this.currentalbum = val;
			else 
				this.currentalbum = "unknown album";
			break;
		case "title":
			if(list.get_string(tag, out val)) 
				this.currenttitle = val;
			else 
				this.currenttitle = "unknown title";
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

	public void play () {
		playbin.set_state(State.PLAYING);
		wait();
		playing = true;
		paused = false;
	}

	public void pause () {
		playbin.set_state(State.PAUSED);
		wait();
		playing = false;
		paused = true;
	}

	public void stop () {
		playbin.set_state(State.READY);
		wait();
		playing = false;
		sign_stopped();
	}

	public void playSong () { 
		bool buf_playing = playing;
		playbin.set_state(State.READY);
		playbin.set("uri", Uri);
		if (buf_playing == true) {
			playbin.set_state(State.PLAYING);
			wait();
			playing = true;
		}
		playbin.set("volume", volume);
	}
}

