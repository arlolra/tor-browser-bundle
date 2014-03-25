#! /bin/sh                                                                      
# usage: park-nightly.sh [DIR]

V=1	#debug is enabled by default for now

if [ "$1" = "-v" ]; then
  V=1
  shift
fi

DIR=$1
[ -z "$DIR" ] && DIR=~/public_html/builds

DSTDIR=tbb-nightly-$(date +%F)
[ -z "$V" ] || echo "Aiming to fill up $DSTDIR"

do_check() {
    [ -z "$1" ] || cd $1 || exit 5
    [ -z "$V" ] || echo "Verifying sha256sums.txt"
    gpg -q --verify sha256sums.txt.asc > /dev/null || exit 3
    [ -z "$V" ] || echo "Checking sha256sums.txt"
    sha256sum --strict --quiet -c sha256sums.txt || exit 4
}

if [ -d $DIR/$DSTDIR ] && [ -e $DIR/$DSTDIR/tbb-nightly.stamp ]; then
    [ -z "$V" ] || echo "Files already here, just doing the checking"
    do_check $DIR/$DSTDIR
    exit
fi

[ -d .staging ] || mkdir .staging
chmod 700 .staging; cd .staging
[ -z "$V" ] || echo "Saving files to disk"
TAROPT=x
[ -z "$V" ] || TAROPT=${TAROPT}v
tar $TAROPT -f - || exit 6
touch $DSTDIR/tbb-nightly.stamp

do_check $DSTDIR || exit 2
[ -d $DIR/$DSTDIR ] && [ -e $DIR/$DSTDIR/tbb-nightly.stamp ] && rm -rf $DIR/$DSTDIR
cd ..; mv $DSTDIR $DIR/ || exit 1
[ -z "$V" ] || echo "All good, all good"

[ -x ~/usr/bin/prune-old-builds ] && ~/usr/bin/prune-old-builds ~/public_html/builds
