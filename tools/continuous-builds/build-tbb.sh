#! /bin/sh
# usage:
# build-tbb.sh [TARGET [PUBLISH-HOST [PUBLISH-SSH-KEY [BUILDDIR [DESTDIR [N]]]]]]
#
# Build TARGET in BUILDDIR, which will end up in DESTDIR
# Try building $TARGET one time and if that fails, try "build-$TARGET"
# up to N-1 times.
# Upload result to PUBLISH-HOST using SSH key PUBLISH-KEY.

# TODO:
# - if there's no new commits, don't build but make sure there's a symlink on perdulce
# - copy build logs to publish-host, at least when failing the build

TARGET=$1; [ -z "$TARGET" ] && TARGET=nightly
PUBLISH_HOST=$2; [ -z "$PUBLISH_HOST" ] && PUBLISH_HOST=perdulce.torproject.org
PUBLISH_SSH_KEY=$3; [ -z "$PUBLISH_SSH_KEY" ] && PUBLISH_SSH_KEY=~/.ssh/perdulce-upload
BUILDDIR=$4; [ -z "$BUILDDIR" ] && BUILDDIR=~/usr/src/tor-browser-bundle/gitian
DESTDIR=$5; [ -z "$DESTDIR" ] && DESTDIR=$BUILDDIR/tbb-$TARGET
N=$6; [ -z "$N" ] && N=16

# Set PGPKEYID="--local-user KEY-ID" to override default PGP key used
# for signing.
[ -z "$PGPKEYID" ] && PGPKEYID=""

# mail(1) from Debian package bsd-mailx lost `-f envelope-sender' in
# DSA-3104-1. Install package heirloom-mailx and set
# MAILX=/usr/bin/heirloom-mailx in order to override envelope sender
# using `-r' in LOGSENDER.
[ -z "$MAILX" ] && MAILX=""

# Name of log file.
logfile=build-logs/$(date -u +%s).log

# LOGRECIPIENTS is a space separated list of email addresses or an
# empty string.
[ -z "$LOGRECIPIENTS" ] && LOGRECIPIENTS=""

# Set LOGSENDER to "-r user@domain" to override envelope sender. If
# empty the default envelope sender is used.
[ -z "$LOGSENDER" ] && LOGSENDER=""

[ -f ~/setup-gitian-build-env.sh ] && . ~/setup-gitian-build-env.sh

cd $BUILDDIR || exit 1
status=init
[ -n "$BUILD_TBB_FAKE_STATUS" ] && status=$BUILD_TBB_FAKE_STATUS
n=0
MAKE_TARGET=$TARGET
while [ $status != done ]; do
  n=$(expr $n + 1)
  printf "%s: Starting build number %d. target=$TARGET.\n" $0 $n | tee -a $logfile
  date -u | tee -a $logfile
  killall qemu-system-i386 qemu-system-x86_64
  make $MAKE_TARGET > build-logs/build-$(date -u +%s).log && status=done
  printf "%s: Tried building $MAKE_TARGET %d times. Status: %s.\n" $0 $n $status | tee -a $logfile
  MAKE_TARGET=build-$TARGET
  [ $n -ge $N ] && break
done

if [ $status = done ]; then
  NEWDESTDIR=$DESTDIR-$(date -u +%F)
  echo "$0: renaming $DESTDIR -> $NEWDESTDIR" | tee -a $logfile
  mv $DESTDIR $NEWDESTDIR
  cd $NEWDESTDIR || exit 3
  sha256sum *.tar.xz *.zip *.dmg *.exe > sha256sums-unsigned-build.txt
  gpg $PGPKEYID -abs sha256sums-unsigned-build.txt || exit 2
  cd ..
  D=$(basename $NEWDESTDIR)
  tar cf - $D/sha256sums* $D/*.tar.xz $D/*.zip $D/*.exe $D/*.dmg | ssh -i $PUBLISH_SSH_KEY $PUBLISH_HOST | tee -a $logfile
else
  echo "$0: giving up after $n tries" | tee -a $logfile
  if [ -n "$LOGRECIPIENTS" ]; then
      FILES="$logfile"
      [ -r ../../gitian-builder/var/build.log ] && FILES="$FILES ../../gitian-builder/var/build.log"
      [ -r ../../gitian-builder/var/target.log ] && FILES="$FILES ../../gitian-builder/var/target.log"
      tail -n 50 $FILES | $MAILX -E -s "Nightly build failure -- $(date -u +%F)" \
                                 $LOGSENDER $LOGRECIPIENTS
  fi
fi
