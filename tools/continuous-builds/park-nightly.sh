#! /bin/sh                                                                      
# usage: park-nightly.sh [DESTDIR]

V=0                             # Verbose.
if [ "$1" = "-v" ]; then
  V=1
  shift
fi

DESTDIR=~/public_html/builds
if [ -n "$1" ]; then
    DESTDIR=$1
    shift
fi

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

# Create a staging directory and cd there.
STAGINGDIR=.staging.$(date -u +%s)
[ -z "$V" ] || echo "Temporary staging dir is $STAGINGDIR"
[ -d $STAGINGDIR ] || mkdir $STAGINGDIR
chmod 700 $STAGINGDIR; cd $STAGINGDIR || exit 7

# Untar incoming data.
[ -z "$V" ] || echo "Saving files to disk"
TAROPT=x
[ -z "$V" ] || TAROPT=${TAROPT}v
tar $TAROPT -f - || exit 6

# Tar file should contain exactly one directory.
INCOMING=$(ls | head -1)
[ -z "$V" ] || echo "Aiming to fill up $DESTDIR/$INCOMING"

# Stamp the directory.
touch $INCOMING/park-nightly.stamp

# Verify checksums.
do_check $INCOMING || exit 2

# Clean up destination directory iff it has a stamp file.
[ -d $DESTDIR/$INCOMING ] && [ -e $DESTDIR/$INCOMING/park-nightly.stamp ] && \
    rm -rf $DESTDIR/$INCOMING

# Move incoming data to destination directory.
[ -d $DESTDIR ] || mkdir $DESTDIR
[ -z "$V" ] || echo "Moving $INCOMING to $DESTDIR/"
mv $INCOMING $DESTDIR/ || exit 1
[ -z "$V" ] || echo "All good, all good"

# Clean up staging directory and remove old builds.
cd ..; rmdir $STAGINGDIR
if [ -x ~/usr/bin/prune-old-builds ]; then
    ~/usr/bin/prune-old-builds --prefix=tbb-nightly- $DESTDIR
    ~/usr/bin/prune-old-builds --prefix=tbb-nightly-hardened- $DESTDIR
fi
