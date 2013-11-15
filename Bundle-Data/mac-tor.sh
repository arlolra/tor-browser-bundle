#!/bin/sh
# Set the current working directory to the directory containing this executable,
# so that pluggable transport executables can be given with relative paths. This
# works around a change in OS X 10.9, where the current working directory is
# otherwise set to "/" when an application bundle is started from Finder.
# https://trac.torproject.org/projects/tor/ticket/10030
cd "$(dirname "$0")"
exec ./tor.real "$@"
