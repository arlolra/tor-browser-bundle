###
### A simple Makefile to automate building the RelativeLink program
### Copyright 2008 Jacob Appelbaum <jacob@appelbaum.net>
### See LICENSE for licensing information
###

APPNAME = StartTorBrowserBundle.exe
OBJECTS = RelativeLink-res.rc.o RelativeLink.o
CFLAGS = -Wall -mwindows -static
CC = gcc

all: RelativeLink

RelativeLink: $(OBJECTS) 
	$(CC) $(OBJECTS) $(CFLAGS) -o $(APPNAME)
	strip $(APPNAME)

RelativeLink.o: RelativeLink.c
	$(CC) $(CFLAGS) -c RelativeLink.c -o RelativeLink.o

RelativeLink-res.rc.o: RelativeLink-res.rc
	windres.exe RelativeLink-res.rc RelativeLink-res.rc.o

clean:
	rm -rf *.exe
	rm -rf *.o
