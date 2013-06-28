#!/bin/sh
# Crappy deterministic zip repackager
export LC_ALL=C

ZIPFILE=`basename $1`

mkdir tmp_dzip
cd tmp_dzip
unzip ../$1
find . -type f -exec chmod 644 {} \;
find . -type d -exec chmod 755 {} \;
find . | sort | zip $ZIPOPTS -X -@ $ZIPFILE
mv $ZIPFILE ../$1
cd ..
rm -rf tmp_dzip
