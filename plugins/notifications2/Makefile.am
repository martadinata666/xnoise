NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
    $(NULL)

INCLUDES = \
    $(XNOISE_CFLAGS) \
    -DUIDIR=\"$(datadir)/xnoise/ui/\" \
    -DPACKAGE_DATADIR=\""$(pkgdatadir)"\" \
    -DDATADIR='"$(datadir)"' \
    -DLOCALE_DIR=\"${datarootdir}/locale\" \
    -include $(CONFIG_HEADER) \
    -I$(top_srcdir)/libxnoise \
    $(LIBNOTIFY_CFLAGS) \
    $(NULL)

libnotificationsdir = $(libdir)/xnoise

libnotifications_LTLIBRARIES = libnotifications.la

libnotifications_la_SOURCES = \
    xnoise-notifications.vala \
    xnoise-notifications-registration.vala \
    $(NULL)

libnotifications_la_VALAFLAGS = \
    --thread \
    --basedir $(top_srcdir)/plugins/notifications2 \
    --vapidir $(top_srcdir)/libxnoise \
    --vapidir $(top_srcdir)/vapi \
    --pkg xnoise-1.0 \
    --pkg libnotify \
    @XNOISE_PACKAGES@ \
    $(NULL)

libnotifications_la_LDFLAGS = \
    $(PLUGIN_LIBTOOL_FLAGS) \
    -module -avoid-version

libnotifications_la_LIBADD = \
    $(XNOISE_LIBS) \
    $(LIBNOTIFY_LIBS) \
    $(NULL)

#notificationsinformation_DATA = notifications.xnplugin
#notificationsinformationdir = $(libdir)/xnoise
plugindir = $(libdir)/xnoise
plugin_in_files = notifications.xnplugin.desktop.in

%.xnplugin: %.xnplugin.desktop.in $(INTLTOOL_MERGE) $(wildcard $(top_srcdir)/po/*po) ; $(INTLTOOL_MERGE) $(top_srcdir)/po $< $@ -d -u -c $(top_builddir)/po/.intltool-merge-cache

plugin_DATA = $(plugin_in_files:.xnplugin.desktop.in=.xnplugin)

EXTRA_DIST = \
    $(plugin_in_files) \
    $(libnotifications_DATA) \
    $(libnotifications_la_SOURCES) \
    $(NULL)

DISTCLEANFILES = \
    *.xnplugin \
    *.c \
    libnotifications_la_vala.stamp \
    Makefile.in \
    $(NULL)

