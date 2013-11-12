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

export LC_ALL=C

cd $TORBROWSER_VERSION
rm -f sha256sums.txt
sha256sum `ls -1 | sort` > sha256sums.txt

echo
echo "If this is an official build, you should now sign your result with: "
echo "  cd $TORBROWSER_VERSION && gpg -abs sha256sums.txt"
