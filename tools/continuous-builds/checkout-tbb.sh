#! /bin/sh

BUILDDIR=$1
[ -z "$BUILDDIR" ] && BUILDDIR=~/usr/src/tor-browser-bundle/gitian

cd $BUILDDIR || exit 1
git checkout master
git pull
