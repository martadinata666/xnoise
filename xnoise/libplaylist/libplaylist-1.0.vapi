/* libplaylist-1.0.vapi generated by valac 0.9.6, do not modify. */

[CCode (cprefix = "Pl", lower_case_cprefix = "pl_")]
namespace Pl {
	[CCode (cprefix = "PlAsx", lower_case_cprefix = "pl_asx_")]
	namespace Asx {
	}
	[CCode (cprefix = "PlM3u", lower_case_cprefix = "pl_m3u_")]
	namespace M3u {
	}
	[CCode (cprefix = "PlPls", lower_case_cprefix = "pl_pls_")]
	namespace Pls {
	}
	[CCode (cprefix = "PlWpl", lower_case_cprefix = "pl_wpl_")]
	namespace Wpl {
	}
	[CCode (cprefix = "PlXspf", lower_case_cprefix = "pl_xspf_")]
	namespace Xspf {
	}
	[CCode (ref_function = "pl_item_ref", unref_function = "pl_item_unref", cheader_filename = "libplaylist.h")]
	public class Item {
		[CCode (cprefix = "PL_ITEM_FIELD_", cheader_filename = "libplaylist.h")]
		public enum Field {
			URI,
			TITLE,
			AUTHOR,
			GENRE,
			ALBUM,
			COPYRIGHT,
			DURATION,
			PARAM_NAME,
			PARAM_VALUE,
			IS_REMOTE,
			IS_PLAYLIST
		}
		public Item ();
		public void add_field (Pl.Item.Field field, string val);
		public string? get_abs_path ();
		public string? get_album ();
		public string? get_author ();
		public Pl.Item.Field[] get_contained_fields ();
		public string? get_copyright ();
		public long get_duration ();
		public string? get_duration_string ();
		public string get_field (Pl.Item.Field field);
		public string? get_genre ();
		public string? get_param_name ();
		public string? get_param_value ();
		public string? get_rel_path ();
		public string? get_title ();
		public string? get_uri ();
		public bool is_playlist ();
		public bool is_remote ();
		public string? base_path { get; set; }
		public Pl.TargetType target_type { get; set; }
	}
	[CCode (ref_function = "pl_item_collection_ref", unref_function = "pl_item_collection_unref", cheader_filename = "libplaylist.h")]
	public class ItemCollection {
		[CCode (ref_function = "pl_item_collection_iterator_ref", unref_function = "pl_item_collection_iterator_unref", cheader_filename = "libplaylist.h")]
		public class Iterator {
			public Iterator (Pl.ItemCollection dc);
			public void append (Pl.Item item);
			public bool first ();
			public Pl.Item @get ();
			public bool has_previous ();
			public int index ();
			public void insert (Pl.Item item);
			public bool next ();
			public bool previous ();
			public void remove ();
			public void @set (Pl.Item item);
		}
		public ItemCollection ();
		public bool append (Pl.Item item);
		public void clear ();
		public bool contains (Pl.Item d);
		public bool contains_field (Pl.Item.Field field, string value);
		public bool data_available ();
		public Pl.Item @get (int index);
		public string? get_album_for_uri (ref string uri_needle);
		public string? get_author_for_uri (ref string uri_needle);
		public Pl.Item.Field[] get_contained_fields_for_idx (int idx);
		public Pl.Item.Field[] get_contained_fields_for_uri (ref string uri);
		public string? get_copyright_for_uri (ref string uri_needle);
		public long get_duration_for_uri (ref string uri_needle);
		public string? get_duration_string_for_uri (ref string uri_needle);
		public string[] get_found_uris ();
		public string? get_genre_for_uri (ref string uri_needle);
		public bool get_is_playlist_for_uri (ref string uri_needle);
		public bool get_is_remote_for_uri (ref string uri_needle);
		public int get_number_of_entries ();
		public string? get_param_name_for_uri (ref string uri_needle);
		public string? get_param_value_for_uri (ref string uri_needle);
		public int get_size ();
		public string? get_title_for_uri (ref string uri_needle);
		public int index_of (Pl.Item d);
		public void insert (int index, Pl.Item item);
		public Pl.ItemCollection.Iterator iterator ();
		public void merge (Pl.ItemCollection data_collection);
		public bool remove (Pl.Item item);
		public Pl.Item remove_at (int index);
		public void @set (int index, Pl.Item item);
	}
	[CCode (cheader_filename = "libplaylist.h")]
	public class Reader : GLib.Object {
		public Reader ();
		public bool data_available ();
		public string? get_album_for_uri (ref string uri_needle);
		public string? get_author_for_uri (ref string uri_needle);
		public string? get_copyright_for_uri (ref string uri_needle);
		public long get_duration_for_uri (ref string uri_needle);
		public string? get_duration_string_for_uri (ref string uri_needle);
		public string[] get_found_uris ();
		public string? get_genre_for_uri (ref string uri_needle);
		public bool get_is_playlist_for_uri (ref string uri_needle);
		public bool get_is_remote_for_uri (ref string uri_needle);
		public int get_number_of_entries ();
		public string? get_title_for_uri (ref string uri_needle);
		public Pl.Result read (string list_uri, GLib.Cancellable? cancellable = null) throws Pl.ReaderError;
		public async Pl.Result read_asyn (string list_uri, GLib.Cancellable? cancellable = null) throws Pl.ReaderError;
		public Pl.ItemCollection data_collection { get; }
		public string playlist_uri { get; }
		public Pl.ListType ptype { get; }
		public signal void finished (string playlist_uri);
		public signal void started (string playlist_uri);
	}
	[CCode (cheader_filename = "libplaylist.h")]
	public class Writer : GLib.Object {
		public Writer (Pl.ListType ptype, bool overwrite = true);
		public Pl.Result write (Pl.ItemCollection data_collection, string playlist_uri, GLib.Cancellable? cancellable = null) throws Pl.WriterError;
		public async Pl.Result write_asyn (Pl.ItemCollection data_collection, string playlist_uri, GLib.Cancellable? cancellable = null) throws Pl.WriterError;
		public bool overwrite_if_exists { get; }
		public string? uri { get; }
	}
	[CCode (cprefix = "PL_LIST_TYPE_", cheader_filename = "libplaylist.h")]
	public enum ListType {
		UNKNOWN,
		IGNORED,
		M3U,
		PLS,
		ASX,
		XSPF,
		WPL
	}
	[CCode (cprefix = "PL_RESULT_", cheader_filename = "libplaylist.h")]
	public enum Result {
		UNHANDLED,
		ERROR,
		IGNORED,
		SUCCESS,
		EMPTY,
		DOUBLE_WRITE
	}
	[CCode (cprefix = "PL_TARGET_TYPE_", cheader_filename = "libplaylist.h")]
	public enum TargetType {
		URI,
		REL_PATH,
		ABS_PATH
	}
	[CCode (cprefix = "PL_READER_ERROR_", cheader_filename = "libplaylist.h")]
	public errordomain ReaderError {
		UNKNOWN_TYPE,
		SOMETHING_ELSE,
	}
	[CCode (cprefix = "PL_WRITER_ERROR_", cheader_filename = "libplaylist.h")]
	public errordomain WriterError {
		UNKNOWN_TYPE,
		NO_DATA,
		NO_DEST_URI,
		DEST_REMOTE,
	}
	[CCode (cheader_filename = "libplaylist.h")]
	public static bool debug;
	[CCode (cheader_filename = "libplaylist.h")]
	public const string[] remote_schemes;
	[CCode (cheader_filename = "libplaylist.h")]
	public static long get_duration_from_string (ref string? duration_string);
	[CCode (cheader_filename = "libplaylist.h")]
	public static GLib.File get_file_for_location (string adr, ref string base_path = "", out Pl.TargetType tt);
	[CCode (cheader_filename = "libplaylist.h")]
	public static Pl.ListType get_playlist_type_for_uri (ref string uri_);
	[CCode (cheader_filename = "libplaylist.h")]
	public static Pl.ListType get_type_by_data (ref string uri_);
	[CCode (cheader_filename = "libplaylist.h")]
	public static Pl.ListType get_type_by_extension (ref string uri_);
}
[CCode (cprefix = "SimpleXml", lower_case_cprefix = "simple_xml_")]
namespace SimpleXml {
	[CCode (ref_function = "simple_xml_node_ref", unref_function = "simple_xml_node_unref", cheader_filename = "libplaylist.h")]
	public class Node {
		[CCode (ref_function = "simple_xml_node_iterator_ref", unref_function = "simple_xml_node_iterator_unref", cheader_filename = "libplaylist.h")]
		public class Iterator {
			public Iterator (SimpleXml.Node parent_node);
			public unowned SimpleXml.Node @get ();
			public bool next ();
			public void @set (SimpleXml.Node node);
		}
		public GLib.HashTable<string,string> attributes;
		public Node (string? name);
		public void append_child (SimpleXml.Node node);
		public void clear ();
		public unowned SimpleXml.Node? @get (int idx);
		public unowned SimpleXml.Node? get_child_by_name (string childname);
		public SimpleXml.Node[] get_children_by_name (string childname);
		public int get_idx_of_child (SimpleXml.Node node);
		public bool has_attributes ();
		public bool has_children ();
		public bool has_text ();
		public void insert_child (int pos, SimpleXml.Node node);
		public SimpleXml.Node.Iterator iterator ();
		public void prepend_child (SimpleXml.Node node);
		public bool remove_child (SimpleXml.Node node);
		public bool remove_child_at_idx (int idx);
		public void @set (int idx, SimpleXml.Node node);
		public int children_count { get; }
		public string? name { get; }
		public SimpleXml.Node? next { get; }
		public SimpleXml.Node? parent { get; }
		public SimpleXml.Node? previous { get; }
		public string? text { get; set; }
	}
	[CCode (cheader_filename = "libplaylist.h")]
	public class Reader : GLib.Object {
		public SimpleXml.Node root;
		public Reader (GLib.File file);
		public Reader.from_string (string? xml_string);
		public void read (bool case_sensitive = true, GLib.Cancellable? cancellable = null);
		public async void read_asyn (bool case_sensitive = true, GLib.Cancellable? cancellable = null);
		public signal void finished ();
		public signal void started ();
	}
	[CCode (cheader_filename = "libplaylist.h")]
	public class Writer : GLib.Object {
		public Writer (SimpleXml.Node root, string header_string = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
		public void write (string filename);
	}
	[CCode (cheader_filename = "libplaylist.h")]
	public const string AMPERSAND_ESCAPED;
	[CCode (cheader_filename = "libplaylist.h")]
	public const string APOSTROPH_ESCAPED;
	[CCode (cheader_filename = "libplaylist.h")]
	public const string GREATER_THAN_ESCAPED;
	[CCode (cheader_filename = "libplaylist.h")]
	public const string LOWER_THAN_ESCAPED;
	[CCode (cheader_filename = "libplaylist.h")]
	public const string QUOTE_ESCAPED;
}
