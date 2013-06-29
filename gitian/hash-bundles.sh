#!/bin/bash
#

. ./versions

export LC_ALL=C

cd $TORBROWSER_VERSION
rm -f sha256sums.txt
sha256sum `ls -1 | sort` > sha256sums.txt

echo
echo "If this is an official build, you should now sign your result with: "
echo "  cd $TORBROWSER_VERSION && gpg -abs sha256sums.txt"
