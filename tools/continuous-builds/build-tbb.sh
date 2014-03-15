#! /bin/sh
# usage:
# build-tbb.sh [TARGET [PUBLISH-HOST [PUBLISH-KEY [BUILDDIR [DESTDIR [N]]]]]]
#
# Build TARGET in BUILDDIR, which will end up in DESTDIR
# Try doing it N times.
# Upload result to PUBLISH-HOST using SSH key PUBLISH-KEY.

# TODO:
# - if there's no new commits, don't build but make sure there's a symlink on perdulce

TARGET=$1; [ -z "$TARGET" ] && TARGET=nightly
PUBLISH_HOST=$2; [ -z "$PUBLISH_HOST" ] && PUBLISH_HOST=perdulce.torproject.org
PUBLISH_KEY=$3; [ -z "$PUBLISH_KEY" ] && PUBLISH_KEY=~/.ssh/perdulce-upload
BUILDDIR=$4; [ -z "$BUILDDIR" ] && BUILDDIR=~/usr/src/tor-browser-bundle/gitian
DESTDIR=$5; [ -z "$DESTDIR" ] && DESTDIR=$BUILDDIR/tbb-$TARGET
N=$6; [ -z "$N" ] && N=16

logfile=$(date -u +%s).log

. ~/setup-gitian-build-env.sh
cd $BUILDDIR || exit 1
status=init
n=0
while [ $status != done ]; do
  n=$(expr $n + 1)
  printf "%s: Starting build number %d. target=$TARGET.\n" $0 $n | tee -a $logfile
  date | tee -a $logfile
  killall qemu-system-i386 qemu-system-x86_64
  make $TARGET > build-$(date -u +%s).log && status=done
  printf "%s: Tried building $TARGET %d times. Status: %s.\n" $0 $n $status | tee -a $logfile
  TARGET=build-nightly
  [ $n -ge $N ] && break
done

if [ $status = done ]; then
  NEWDESTDIR=$DESTDIR-$(date +%F)
  echo "$0: renaming $DESTDIR -> $NEWDESTDIR" | tee -a $logfile
  mv $DESTDIR $NEWDESTDIR
  cd $NEWDESTDIR || exit 3
  sha256sum *.tar.xz *.zip *.exe > sha256sums.txt
  gpg -a --clearsign --local-user 0x984496E7 sha256sums.txt || exit 2
  cd ..
  D=$(basename $NEWDESTDIR)
  tar cf - $D/sha256sums* $D/*.tar.xz $D/*.zip $D/*.exe | ssh -i $PUBLISH_KEY $PUBLISH_HOST | tee -a $logfile
else
  echo "$0: giving up after $n tries" | tee -a $logfile
fi
