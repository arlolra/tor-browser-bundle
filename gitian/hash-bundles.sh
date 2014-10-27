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
fi

echo
echo "If this is an official build, you should now sign your result with: "
echo "  make sign"
echo
echo "In either case, you can check against any official builds with: "
echo "  make match"
