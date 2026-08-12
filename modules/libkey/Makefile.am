## Process this file with automake to produce Makefile.in

#AUTOMAKE_OPTIONS = no-dependencies foreign

lib_LTLIBRARIES = libkey.la

libkey_la_SOURCES = libkey.c
libkey_la_CFLAGS = $(COMMON_CFLAGS) $(SDL_CFLAGS) -I$(BGD_PATH)/include -I../libvideo -I../libgrbase
libkey_la_LDFLAGS = -s -no-undefined -avoid-version
libkey_la_LIBADD = $(COMMON_LDFLAGS) $(SDL_LIBS) -L$(BGD_PATH)/bgdrtm/src/.libs -lbgdrtm -L../libvideo/.libs -lvideo -L../libgrbase/.libs -lgrbase

## Make sure these will be cleaned even when they're not built by
## default.
CLEANFILES = libkey.la

