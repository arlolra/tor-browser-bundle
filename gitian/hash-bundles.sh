#!/bin/bash
#

if [ -z "$1" ];
then
  VERSIONS_FILE=./versions
else
  VERSIONS_FILE=$1
fi

if ! [ -e $VERSIONS_FILE ]; then
  echo >&2 "Error: $VERSIONS_FILE file does not exist"
  exit 1
fi

. $VERSIONS_FILE
eval $(./get-tb-version $TORBROWSER_VERSION_TYPE)

export LC_ALL=C

cd $TORBROWSER_BUILDDIR
rm -f sha256sums.txt sha256sums.incrementals.txt
sha256sum `ls -1 | grep -v '\.incremental\.mar$' | sort` > sha256sums.txt
if ls -1 | grep -q '\.incremental\.mar$'
then
    sha256sum `ls -1 | grep '\.incremental\.mar$' | sort` > sha256sums.incrementals.txt
    echo
    echo "If this is an official build, you should now sign your result with: "
    echo "  make sign"
    echo
    echo "In either case, you can check against any official builds with: "
    echo "  make match"
else
    echo
    echo "It appears that this build did not generate any incremental update (.mar) files"
    echo
    echo "If your goal is to reproduce the entire release, you still need to download"
    echo "the mar files from the previous release from the appropriate directory in: "
    echo "  https://archive.torproject.org/tor-package-archive/torbrowser/"
    echo
    echo "After that, you will need to make the incremental updates with: "
    echo "  make incrementals && make hash"
fi


