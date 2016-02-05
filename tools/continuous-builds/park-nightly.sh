#! /bin/sh                                                                      
# usage: park-nightly.sh [DIR]

V=1	#debug is enabled by default for now

if [ "$1" = "-v" ]; then
  V=1
  shift
fi

DIR=$1
[ -z "$DIR" ] && DIR=~/public_html/builds

DSTDIR=tbb-nightly-$(date -u +%F) # Must be the same as at source.
[ -z "$V" ] || echo "Aiming to fill up $DIR/$DSTDIR"

do_check() {
    SAVEDPWD=$PWD
    [ -z "$1" ] || cd $1 || exit 5
    [ -z "$V" ] || echo "Verifying sha256sums-unsigned-build.txt"
    gpg -q --verify sha256sums-unsigned-build.txt.asc \
        sha256sums-unsigned-build.txt > /dev/null || exit 3
    [ -z "$V" ] || echo "Checking sha256sums-unsigned-build.txt"
    sha256sum --strict --quiet -c sha256sums-unsigned-build.txt || exit 4
    cd $SAVEDPWD
}

if [ -d $DIR/$DSTDIR ] && [ -e $DIR/$DSTDIR/tbb-nightly.stamp ]; then
    [ -z "$V" ] || echo "Files already here, just doing the checking"
    do_check $DIR/$DSTDIR
    exit
fi

STAGINGDIR=.staging.$(date -u +%s)
[ -z "$V" ] || echo "Temporary staging dir is $STAGINGDIR"
[ -d $STAGINGDIR ] || mkdir $STAGINGDIR
chmod 700 $STAGINGDIR; cd $STAGINGDIR || exit 7

[ -z "$V" ] || echo "Saving files to disk"
TAROPT=x
[ -z "$V" ] || TAROPT=${TAROPT}v
tar $TAROPT -f - || exit 6
touch $DSTDIR/tbb-nightly.stamp

do_check $DSTDIR || exit 2
[ -d $DIR/$DSTDIR ] && [ -e $DIR/$DSTDIR/tbb-nightly.stamp ] && \
    rm -rf $DIR/$DSTDIR
[ -z "$V" ] || echo "Moving $DSTDIR to $DIR/"
mv $DSTDIR $DIR/ || exit 1
[ -z "$V" ] || echo "All good, all good"

cd ..; rmdir $STAGINGDIR
[ -x ~/usr/bin/prune-old-builds ] && ~/usr/bin/prune-old-builds $DIR
