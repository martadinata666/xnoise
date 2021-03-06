/* modified by shuerhaaken. */

[CCode (cprefix = "Indicate", lower_case_cprefix = "indicate_")]
namespace Indicate {
	[CCode (cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h")]
	public class Indicator : GLib.Object {
		public weak GLib.Object parent;
		[CCode (has_construct_function = false)]
		public Indicator ();
		public bool get_displayed ();
		public uint get_id ();
		public virtual GLib.Value get_property (string key);
		public GLib.Value get_property_value (string key);
		public Indicate.Server get_server ();
		public bool is_visible ();
		public GLib.GenericArray<string> list_properties ();
		public void set_displayed (bool displayed);
		public virtual void set_property (string key, GLib.Value data);
		public void set_property_bool (string key, bool value);
		public void set_property_int (string key, int value);
		public void set_property_time (string key, GLib.TimeVal time);
		public void set_property_value (string key, GLib.Value value);
		public void set_server (Indicate.Server server);
		[CCode (has_construct_function = false)]
		public Indicator.with_server (Indicate.Server server);
		public signal void displayed (bool object);
		[HasEmitter]
		public signal void hide ();
		public signal void modified (string object);
		[HasEmitter]
		public signal void show ();
		[HasEmitter]
		public signal void user_display (uint object);
	}
	[CCode (cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h")]
	public class Listener : GLib.Object {
		public weak GLib.Object parent;
		[CCode (has_construct_function = false)]
		public Listener ();
		public void display (Indicate.ListenerServer server, Indicate.ListenerIndicator indicator, uint timestamp);
		public void displayed (Indicate.ListenerServer server, Indicate.ListenerIndicator indicator, bool displayed);
		public void get_property (Indicate.ListenerServer server, Indicate.ListenerIndicator indicator, owned string property, Indicate.listener_get_property_cb callback);
		public void get_property_bool (Indicate.ListenerServer server, Indicate.ListenerIndicator indicator, owned string property, Indicate.listener_get_property_bool_cb callback);
		public void get_property_int (Indicate.ListenerServer server, Indicate.ListenerIndicator indicator, owned string property, Indicate.listener_get_property_int_cb callback);
		public void get_property_time (Indicate.ListenerServer server, Indicate.ListenerIndicator indicator, owned string property, Indicate.listener_get_property_time_cb callback);
		public void get_property_value (Indicate.ListenerServer server, Indicate.ListenerIndicator indicator, owned string property, Indicate.listener_get_property_value_cb callback);
		public static GLib.Type indicator_get_gtype ();
		public static Indicate.Listener ref_default ();
		public bool server_check_interest (Indicate.ListenerServer server, Indicate.Interests interest);
		public void server_get_count (Indicate.ListenerServer server, [CCode (delegate_target_pos = 2.1)] Indicate.listener_get_server_uint_property_cb callback);
		public void server_get_desktop (Indicate.ListenerServer server, [CCode (delegate_target_pos = 2.1)] Indicate.listener_get_server_property_cb callback);
		public static GLib.Type server_get_gtype ();
		public void server_get_menu (Indicate.ListenerServer server, [CCode (delegate_target_pos = 2.1)] Indicate.listener_get_server_property_cb callback);
		public static void server_get_type (Indicate.Listener listener, Indicate.ListenerServer server, [CCode (delegate_target_pos = 3.1)] Indicate.listener_get_server_property_cb callback);
		public void server_remove_interest (Indicate.ListenerServer server, Indicate.Interests interest);
		public void server_show_interest (Indicate.ListenerServer server, Indicate.Interests interest);
		public void set_default_max_indicators (int max);
		public void set_server_max_indicators (Indicate.ListenerServer server, int max);
		public signal void indicator_added (Indicate.ListenerServer object, Indicate.ListenerIndicator p0);
		public signal void indicator_modified (Indicate.ListenerServer object, Indicate.ListenerIndicator p0, string p1);
		public signal void indicator_removed (Indicate.ListenerServer object, Indicate.ListenerIndicator p0);
		public signal void indicator_servers_report ();
		public signal void server_added (Indicate.ListenerServer object, string p0);
		public signal void server_count_changed (Indicate.ListenerServer object, uint p0);
		public signal void server_removed (Indicate.ListenerServer object, string p0);
	}
	[CCode (cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h")]
	public class Server : GLib.Object {
		public weak GLib.Object parent;
		public void add_indicator (Indicate.Indicator indicator);
		public virtual bool check_interest (Indicate.Interests interest);
		public virtual bool get_indicator_count (out uint count) throws GLib.Error;
		public virtual bool get_indicator_property (uint id, owned string property, GLib.Value value) throws GLib.Error;
		public int get_max_indicators ();
		public virtual uint get_next_id ();
		public void hide ();
		public virtual void indicator_added (uint id);
		public virtual bool indicator_displayed (owned string sender, uint id, bool displayed) throws GLib.Error;
		public virtual void indicator_removed (uint id);
		public virtual int max_indicators_get ();
		public virtual bool max_indicators_set (owned string sender, int max);
		public static Indicate.Server ref_default ();
		public void remove_indicator (Indicate.Indicator indicator);
		public virtual bool remove_interest (owned string sender, Indicate.Interests interest);
		public void set_count (uint count);
		public static void set_dbus_object (string obj);
		public void set_default ();
		public void set_desktop_file (string path);
//		public void set_menu (Dbusmenu.Server menu);
		public void set_type (string type);
		public void show ();
		public virtual bool show_indicator_to_user (uint id, uint timestamp) throws GLib.Error;
		public virtual bool show_interest (owned string sender, Indicate.Interests interest);
		public uint count { get; set; }
		public string desktop { get; set; }
		public string type { get; set; }
		public signal void indicator_delete (uint object);
		public signal void indicator_modified (uint object, string p0);
		public signal void indicator_new (uint object);
		public signal void interest_added (uint object);
		public signal void interest_removed (uint object);
		public signal void max_indicators_changed (int object);
		public signal void server_count_changed (uint object);
		public signal void server_display (uint object);
		public signal void server_hide (string object);
		public signal void server_show (string object);
	}
	[CCode (type_id = "INDICATE_TYPE_LISTENER_INDICATOR", cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h")]
	public struct ListenerIndicator {
		public uint get_id ();
	}
	[CCode (type_id = "INDICATE_TYPE_LISTENER_SERVER", cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h")]
	public struct ListenerServer {
		public unowned string get_dbusname ();
	}
	[CCode (cprefix = "INDICATE_INTEREST_", cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h")]
	public enum Interests {
		NONE,
		SERVER_DISPLAY,
		SERVER_SIGNAL,
		INDICATOR_DISPLAY,
		INDICATOR_SIGNAL,
		INDICATOR_COUNT,
		LAST
	}
	[CCode (cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h", has_target = false)]
	public delegate GLib.GenericArray<string> indicator_list_properties_slot_t (Indicate.Indicator indicator);
	[CCode (cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h", has_target = false)]
	public delegate void listener_get_property_bool_cb (Indicate.Listener listener, Indicate.ListenerServer server, Indicate.ListenerIndicator indicator, owned string property, bool propertydata, void* data);
	[CCode (cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h", has_target = false)]
	public delegate void listener_get_property_cb (Indicate.Listener listener, Indicate.ListenerServer server, Indicate.ListenerIndicator indicator, owned string property, string propertydata, void* data);
	[CCode (cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h", has_target = false)]
	public delegate void listener_get_property_int_cb (Indicate.Listener listener, Indicate.ListenerServer server, Indicate.ListenerIndicator indicator, owned string property, int propertydata, void* data);
	[CCode (cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h", has_target = false)]
	public delegate void listener_get_property_time_cb (Indicate.Listener listener, Indicate.ListenerServer server, Indicate.ListenerIndicator indicator, owned string property, GLib.TimeVal propertydata, void* data);
	[CCode (cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h", has_target = false)]
	public delegate void listener_get_property_value_cb (Indicate.Listener listener, Indicate.ListenerServer server, Indicate.ListenerIndicator indicator, owned string property, GLib.Value propertydata, void* data);
	[CCode (cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h", has_target = false)]
	public delegate void listener_get_server_property_cb (Indicate.Listener listener, Indicate.ListenerServer server, owned string value, void* data);
	[CCode (cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h", has_target = false)]
	public delegate void listener_get_server_uint_property_cb (Indicate.Listener listener, Indicate.ListenerServer server, uint value, void* data);
	[CCode (cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h", has_target = false)]
	public delegate bool server_get_indicator_list_slot_t (Indicate.Server server, out GLib.Array<weak Indicate.Indicator> indicators);
	[CCode (cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h", has_target = false)]
	public delegate bool server_get_indicator_properties_slot_t (Indicate.Server server, uint id, [CCode (array_length = false)] out string[] properties);
	[CCode (cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h", has_target = false)]
	public delegate bool server_get_indicator_property_group_slot_t (Indicate.Server server, uint id, GLib.GenericArray<weak string> properties, [CCode (array_length = false)] out string[] value);
	[CCode (cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h")]
	public const int INDICATOR_H_INCLUDED__;
	[CCode (cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h")]
	public const int INDICATOR_MESSAGES_H_INCLUDED__;
	[CCode (cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h")]
	public const string INDICATOR_MESSAGES_PROP_ATTENTION;
	[CCode (cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h")]
	public const string INDICATOR_MESSAGES_PROP_COUNT;
	[CCode (cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h")]
	public const string INDICATOR_MESSAGES_PROP_ICON;
	[CCode (cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h")]
	public const string INDICATOR_MESSAGES_PROP_NAME;
	[CCode (cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h")]
	public const string INDICATOR_MESSAGES_PROP_TIME;
	[CCode (cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h")]
	public const string INDICATOR_MESSAGES_SERVER_TYPE;
	[CCode (cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h")]
	public const string INDICATOR_SIGNAL_DISPLAY;
	[CCode (cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h")]
	public const string INDICATOR_SIGNAL_DISPLAYED;
	[CCode (cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h")]
	public const string INDICATOR_SIGNAL_HIDE;
	[CCode (cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h")]
	public const string INDICATOR_SIGNAL_MODIFIED;
	[CCode (cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h")]
	public const string INDICATOR_SIGNAL_SHOW;
	[CCode (cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h")]
	public const string INDICATOR_VALUE_FALSE;
	[CCode (cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h")]
	public const string INDICATOR_VALUE_TRUE;
	[CCode (cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h")]
	public const int INTERESTS_H_INCLUDED__;
	[CCode (cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h")]
	public const int LISTENER_H_INCLUDED__;
	[CCode (cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h")]
	public const string LISTENER_SIGNAL_INDICATOR_ADDED;
	[CCode (cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h")]
	public const string LISTENER_SIGNAL_INDICATOR_MODIFIED;
	[CCode (cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h")]
	public const string LISTENER_SIGNAL_INDICATOR_REMOVED;
	[CCode (cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h")]
	public const string LISTENER_SIGNAL_SERVER_ADDED;
	[CCode (cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h")]
	public const string LISTENER_SIGNAL_SERVER_COUNT_CHANGED;
	[CCode (cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h")]
	public const string LISTENER_SIGNAL_SERVER_REMOVED;
	[CCode (cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h")]
	public const int SERVER_H_INCLUDED__;
	[CCode (cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h")]
	public const int SERVER_INDICATOR_NULL;
	[CCode (cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h")]
	public const string SERVER_SIGNAL_INDICATOR_ADDED;
	[CCode (cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h")]
	public const string SERVER_SIGNAL_INDICATOR_MODIFIED;
	[CCode (cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h")]
	public const string SERVER_SIGNAL_INDICATOR_REMOVED;
	[CCode (cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h")]
	public const string SERVER_SIGNAL_INTEREST_ADDED;
	[CCode (cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h")]
	public const string SERVER_SIGNAL_INTEREST_REMOVED;
	[CCode (cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h")]
	public const string SERVER_SIGNAL_MAX_INDICATORS_CHANGED;
	[CCode (cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h")]
	public const string SERVER_SIGNAL_SERVER_COUNT_CHANGED;
	[CCode (cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h")]
	public const string SERVER_SIGNAL_SERVER_DISPLAY;
	[CCode (cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h")]
	public const string SERVER_SIGNAL_SERVER_HIDE;
	[CCode (cheader_filename = "libindicate/indicator-messages.h,libindicate/indicator.h,libindicate/interests.h,libindicate/listener.h,libindicate/server.h")]
	public const string SERVER_SIGNAL_SERVER_SHOW;
}
