#!/bin/bash

# XXX: Args?
HOST=people.torproject.org
BASE_DIR=public_html/builds/
USERS="linus mikeperry erinn gk"

set -e
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

VALID=""
VALID_incrementals=""

for u in $USERS
do
  cd $WRAPPER_DIR

  # XXX: Is there a better way to store these and rename them?
  mkdir -p $TORBROWSER_VERSION/$u
  cd $TORBROWSER_VERSION/$u

  wget -U "" -N https://$HOST/~$u/builds/$TORBROWSER_VERSION/sha256sums.txt || continue
  wget -U "" -N https://$HOST/~$u/builds/$TORBROWSER_VERSION/sha256sums.txt.asc || continue

  keyring="../../gpg/$u.gpg"

  # XXX: Remove this dir
  gpghome=$(mktemp -d)
  GNUPGHOME="$gpghome" gpg --import "$keyring"
  GNUPGHOME="$gpghome" gpg sha256sums.txt.asc || exit 1

  diff -u ../sha256sums.txt sha256sums.txt || exit 1

  VALID="$u $VALID"
done
cd ../..

# XXX: We should refactor this code into a shared function
if [ -f $TORBROWSER_VERSION/sha256sums.incrementals.txt ]
then
  for u in $USERS
  do
    cd $WRAPPER_DIR

    # XXX: Is there a better way to store these and rename them?
    mkdir -p $TORBROWSER_VERSION/$u
    cd $TORBROWSER_VERSION/$u

    wget -U "" -N https://$HOST/~$u/builds/$TORBROWSER_VERSION/sha256sums.incrementals.txt || continue
    wget -U "" -N https://$HOST/~$u/builds/$TORBROWSER_VERSION/sha256sums.incrementals.txt.asc || continue

    keyring="../../gpg/$u.gpg"

    # XXX: Remove this dir
    gpghome=$(mktemp -d)
    GNUPGHOME="$gpghome" gpg --import "$keyring"
    GNUPGHOME="$gpghome" gpg sha256sums.incrementals.txt.asc || exit 1

    diff -u ../sha256sums.incrementals.txt sha256sums.incrementals.txt || exit 1

    VALID_incrementals="$u $VALID_incrementals"
  done
fi
cd ../..

exit_val=0
if [ -z "$VALID" ];
then
  echo "No bundle hashes or sigs published for $TORBROWSER_VERSION."
  echo
  exit_val=1
else
  echo "Matching bundles exist from the following users: $VALID"
fi

if [ -f $TORBROWSER_VERSION/sha256sums.incrementals.txt ]
then
  if [ -z "$VALID_incrementals" ]
  then
    echo "No incremental mars hashes or sigs published for $TORBROWSER_VERSION."
    exit_val=1
  else
    echo "Matching incremental mars exist from the following users: $VALID_incrementals"
  fi
fi

exit $exit_val
