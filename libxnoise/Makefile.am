NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
    $(NULL)

INCLUDES = \
    -include $(CONFIG_HEADER) \
    $(XNOISE_CFLAGS) \
    -DDATADIR=\"$(datadir)/xnoise/\" \
    -DUIDIR=\"$(datadir)/xnoise/ui/\" \
    -DPLUGINSDIR=\"$(libdir)/xnoise\" \
    -DLICENSEDIR=\"$(datadir)/xnoise/license/\" \
    -DLOCALE_DIR=\"${datarootdir}/locale\" \
    $(NULL)

libxnoise_hdir = $(includedir)/xnoise
libxnoise_h_HEADERS = xnoise-1.0.h

BUILT_SOURCES = \
    xnoise-1.0.vapi \
    xnoise-1.0.h \
    $(NULL)
    
libxnoisedir = $(libdir)/xnoise

libxnoise_LTLIBRARIES = libxnoise.la

libxnoise_la_SOURCES = \
    xnoise-main.vala \
    AlbumImages/xnoise-album-image.vala \
    AlbumImages/xnoise-album-image-loader.vala \
    AlbumImages/xnoise-i-album-cover-image.vala \
    AlbumImages/xnoise-i-album-cover-image-provider.vala \
    ItemHandlers/AddAllToTracklist/xnoise-handler-add-all-to-tracklist.vala \
    ItemHandlers/AddToTracklist/xnoise-handler-add-to-tracklist.vala \
    ItemHandlers/EditTags/xnoise-handler-edit-tags.vala \
    ItemHandlers/EditTags/xnoise-tag-artistalbum-editor.vala \
    ItemHandlers/EditTags/xnoise-tag-title-editor.vala \
    ItemHandlers/PlayItem/xnoise-handler-play-item.vala \
    ItemHandlers/RemoveTrack/xnoise-handler-remove-track.vala \
    ItemHandlers/xnoise-item.vala \
    ItemHandlers/xnoise-item-converter.vala \
    ItemHandlers/xnoise-item-handler.vala \
    ItemHandlers/xnoise-item-handler-manager.vala \
    Database/xnoise-db-browser.vala \
    Database/xnoise-db-creator.vala \
    Database/xnoise-db-writer.vala \
    Lyrics/xnoise-i-lyrics.vala \
    Lyrics/xnoise-i-lyrics-provider.vala \
    Lyrics/xnoise-lyrics-loader.vala \
    Lyrics/xnoise-lyrics-view.vala \
    MediaBrowser/xnoise-media-browser.vala \
    MediaBrowser/xnoise-media-browser-model.vala \
    Parameter/xnoise-i-params.vala \
    Parameter/xnoise-parameter.vala \
    Player/xnoise-gst-player.vala \
    PlaylistReader/xnoise-playlist-abstract-file-reader.vala \
    PlaylistReader/xnoise-playlist-general.vala \
    PlaylistReader/xnoise-playlist-entry.vala \
    PlaylistReader/xnoise-playlist-entry-collection.vala \
    PlaylistReader/xnoise-playlist-reader.vala \
    PlaylistReader/ASX/xnoise-playlist-asx-file-reader.vala \
    PlaylistReader/WPL/xnoise-playlist-wpl-file-reader.vala \
    PlaylistReader/M3U/xnoise-playlist-m3u-file-reader.vala \
    PlaylistReader/PLS/xnoise-playlist-pls-file-reader.vala \
    PlaylistReader/XSPF/xnoise-playlist-xspf-file-reader.vala \
    PluginModule/xnoise-plugin.vala \
    PluginModule/xnoise-plugin-loader.vala \
    PluginModule/xnoise-plugin-information.vala \
    PluginModule/xnoise-plugin-interface.vala \
    Services/xnoise-services.vala \
    Settings/xnoise-plugin-manager-tree.vala \
    Settings/xnoise-settings-dialog.vala \
    SimpleMarkup/xnoise-markup-node.vala \
    SimpleMarkup/xnoise-markup-reader.vala \
    SimpleMarkup/xnoise-markup-writer.vala \
    TagAccess/xnoise-tag-reader.vala \
    TagAccess/xnoise-tag-writer.vala \
    TrackList/xnoise-text-column.vala \
    TrackList/xnoise-tracklist.vala \
    TrackList/xnoise-tracklist-column.vala \
    TrackList/xnoise-tracklist-model.vala \
    TrayIcon/xnoise-tray-icon.vala \
    Utils/xnoise-app-starter.vala \
    Utils/xnoise-global-access.vala \
    Utils/xnoise-local-schemes.vala \
    Utils/xnoise-media-extensions.vala \
    Utils/xnoise-media-importer.vala \
    Utils/xnoise-misc.vala \
    Utils/xnoise-remote-schemes.vala \
    Utils/xnoise-screensaver-manager.vala \
    Utils/xnoise-track-data.vala \
    Utils/xnoise-user-info.vala \
    Utils/xnoise-worker.vala \
    Widgets/xnoise-about.vala \
    Widgets/xnoise-add-media-dialog.vala \
    Widgets/xnoise-control-button.vala \
    Widgets/xnoise-fullscreen-toolbar.vala \
    Widgets/xnoise-info-bar.vala \
    Widgets/xnoise-main-window.vala \
    Widgets/xnoise-play-pause-button.vala \
    Widgets/xnoise-trackinfo-bar.vala \
    Widgets/xnoise-track-progressbar.vala \
    Widgets/xnoise-videoscreen.vala \
    Widgets/xnoise-volume-slider-button.vala \
    $(NULL)

libxnoise_la_VALAFLAGS = \
    --library libxnoise-1.0 \
    --header=xnoise-1.0.h \
    --vapi=xnoise-1.0.vapi \
    --thread \
    --pkg gio-2.0 \
    --vapidir $(top_srcdir)/vapi \
    --basedir $(top_srcdir)/libxnoise \
    @XNOISE_PACKAGES@ \
    $(NULL)

libxnoise_la_LDFLAGS = \
    $(PLUGIN_LIBTOOL_FLAGS) \
    -export-dynamic \
    $(NULL)

libxnoise_la_LIBADD = \
    $(XNOISE_LIBS) \
    -lgstpbutils-0.10 \
    $(NULL)

VAPI_FILES = xnoise-1.0.vapi
DEPS_FILES = xnoise-1.0.deps

vapidir = $(VAPIDIR)
vapi_DATA = $(VAPI_FILES) $(DEPS_FILES)

EXTRA_DIST = \
    $(VAPI_FILES) \
    $(DEPS_FILES) \
    $(BUILT_SOURCES) \
    $(libxnoise_DATA) \
    $(libxnoise_la_SOURCES) \
    $(NULL)

DISTCLEANFILES = \
    *.c \
    libxnoise_la_vala.stamp \
    Makefile.in \
    AlbumImages/*.c \
    Database/*.c \
    ItemHandlers/*.c \
    ItemHandlers/AddAllToTracklist/*.c \
    ItemHandlers/AddToTracklist/*.c \
    ItemHandlers/EditTags/*.c \
    ItemHandlers/PlayItem/*.c \
    ItemHandlers/RemoveTrack/*.c \
    Lyrics/*.c \
    MediaBrowser/*.c \
    Parameter/*.c \
    Player/*.c \
    PlaylistReader/*.c \
    PluginModule/*.c \
    Services/*.c \
    Settings/*.c \
    SimpleMarkup/*.c \
    TagAccess/*.c \
    TrackList/*.c \
    TrayIcon/*.c \
    Utils/*.c \
    Widgets/*.c \
    $(NULL)

