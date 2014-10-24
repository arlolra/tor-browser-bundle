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

if [ ! -f $TORBROWSER_VERSION/sha256sums.txt.asc ];
then
  pushd $TORBROWSER_VERSION && gpg -abs sha256sums.txt 
  popd
fi

if [ -f $TORBROWSER_VERSION/sha256sums.incrementals.txt ] \
    && [ ! -f $TORBROWSER_VERSION/sha256sums.incrementals.txt.asc ]
then
  pushd $TORBROWSER_VERSION && gpg -abs sha256sums.incrementals.txt
  popd
fi


ssh $HOST "mkdir -p $BASE_DIR/$TORBROWSER_VERSION" 
scp $TORBROWSER_VERSION/sha256sums*.txt* $HOST:$BASE_DIR/$TORBROWSER_VERSION/ 
ssh $HOST "chmod 755 $BASE_DIR/$TORBROWSER_VERSION && chmod 644 $BASE_DIR/$TORBROWSER_VERSION/*"
