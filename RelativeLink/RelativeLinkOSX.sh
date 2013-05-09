#!/bin/sh
#
# Mac OS does not really require something like RelativeLink.c
# However, we do want to have the same look and feel with similar features.
# In the future, we may want this to be a C binary with a custom icon but at the moment
# it's quite simple to just use a shell script
#
# To run in debug mode, simply pass -debug or --debug on the command line.
#
# WARNING: In debug mode, this script may cause dyld to write to the system
#          log file.
#
# Copyright 2010 The Tor Project.  See LICENSE for licensing information.

DEBUG_TBB=0

if [ "x$1" = "x--debug" -o "x$1" = "x-debug" ]; then
	DEBUG_TBB=1
	printf "\nDebug enabled.\n\n"
fi

# If the user hasn't requested 'debug mode', close whichever of stdout
# and stderr are not ttys, to keep Vidalia and the stuff loaded by/for
# it (including the system's shared-library loader) from printing
# messages to be logged in /var/log/system.log .  (Users wouldn't have
# seen messages there anyway.)
#
# If the user has requested 'debug mode', don't muck with the FDs.
if [ "$DEBUG_TBB" -ne 1 ]; then
  if [ '!' -t 1 ]; then
    # stdout is not a tty
    exec >/dev/null
  fi
  if [ '!' -t 2 ]; then
    # stderr is not a tty
    exec 2>/dev/null
  fi
fi

HOME="${0%%Contents/MacOS/TorBrowserBundle}"
export HOME

DYLD_LIBRARY_PATH=${HOME}/Contents/Frameworks
export LDPATH
export DYLD_LIBRARY_PATH

if [ "$DEBUG_TBB" -eq 1 ]; then
	DYLD_PRINT_LIBRARIES=1
	export DYLD_PRINT_LIBRARIES
fi

if [ "$DEBUG_TBB" -eq 1 ]; then
	printf "\nStarting Vidalia now\n"
	cd "${HOME}"
	printf "\nLaunching Vidalia from: `pwd`\n"
	./Contents/MacOS/Vidalia.app/Contents/MacOS/Vidalia --loglevel debug --logfile vidalia-debug-log \
	--datadir ./Contents/Resources/Data/Vidalia/
	printf "\nVidalia exited with the following return code: $?\n"
	exit
fi

# not in debug mode, run proceed normally
printf "\nLaunching Tor Browser Bundle for OS X in ${HOME}\n"
cd "${HOME}"
open "$HOME/Contents/MacOS/Vidalia.app"
