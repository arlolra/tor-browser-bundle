#!/bin/bash

HOST=people.torproject.org
BASE_DIR=public_html/builds/

set -u

WRAPPER_DIR=$(dirname "$0")
WRAPPER_DIR=$(readlink -f "$WRAPPER_DIR")

if [ -z "$1" ];
then
  VERSIONS_FILE=$WRAPPER_DIR/versions
else
  VERSIONS_FILE=$1
fi

if ! [ -e $VERSIONS_FILE ]; then
  echo >&2 "Error: $VERSIONS_FILE file does not exist"
  exit 1
fi

. $VERSIONS_FILE
eval $(./get-tb-version $TORBROWSER_VERSION_TYPE)

if [ ! -f $TORBROWSER_BUILDDIR/sha256sums-unsigned-build.txt.asc ];
then
  pushd $TORBROWSER_BUILDDIR && gpg -abs sha256sums-unsigned-build.txt
  popd
fi

if [ -f $TORBROWSER_BUILDDIR/sha256sums-unsigned-build.incrementals.txt ] \
    && [ ! -f $TORBROWSER_BUILDDIR/sha256sums-unsigned-build.incrementals.txt.asc ]
then
  pushd $TORBROWSER_BUILDDIR && gpg -abs sha256sums-unsigned-build.incrementals.txt
  popd
fi


ssh $HOST "mkdir -p $BASE_DIR/$TORBROWSER_BUILDDIR" 
scp $TORBROWSER_BUILDDIR/.htaccess $TORBROWSER_BUILDDIR/sha256sums-unsigned-build*.txt* $HOST:$BASE_DIR/$TORBROWSER_BUILDDIR/
ssh $HOST "chmod 755 $BASE_DIR/$TORBROWSER_BUILDDIR && chmod 644 $BASE_DIR/$TORBROWSER_BUILDDIR/*"
