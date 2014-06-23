#!/usr/bin/env python

# Changes an OS X bundle property list file (plist file) so that the bundle
# starts up without a dock icon. Specifically, this program unsets the key
# LSUIElement (if present), and sets LSBackgroundOnly=true.
#
# This program is meant to help create a headless copy of an existing bundle. It
# exists specifically to enable the meek-http-helper browser extension to run in
# the background without creating a second Tor Browser icon.
# https://trac.torproject.org/projects/tor/ticket/11429

import getopt
import plistlib
import sys

_, args = getopt.gnu_getopt(sys.argv[1:], "")

if len(args) != 1:
    print >> sys.stderr, "Need a file name argument."
    sys.exit(1)

filename = args[0]
plist = plistlib.readPlist(filename)

try:
    del plist["LSUIElement"]
except KeyError:
    pass
plist["LSBackgroundOnly"] = True

plistlib.writePlist(plist, sys.stdout)
