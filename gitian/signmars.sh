#!/bin/bash
#
#
# You may set NSS_DB_DIR and/or NSS_CERTNAME before invoking this script.

set -e
set -u

WRAPPER_DIR=$(dirname "$0")
WRAPPER_DIR=$(readlink -e "$WRAPPER_DIR")

if [ -z "${NSS_DB_DIR+x}" ]; then
  NSS_DB_DIR=$WRAPPER_DIR/nssdb
fi

if [ -z "${NSS_CERTNAME+x}" ]; then
  NSS_CERTNAME=marsigner
fi

# Incorporate definitions from the versions file.
if [ -z "$1" ]; then
  VERSIONS_FILE=$WRAPPER_DIR/versions
else
  VERSIONS_FILE=$1
fi

if ! [ -e $VERSIONS_FILE ]; then
  echo >&2 "Error: $VERSIONS_FILE file does not exist"
  exit 1
fi

. $VERSIONS_FILE

export LC_ALL=C

# Check some prerequisites.
if [ ! -r "$NSS_DB_DIR/cert8.db" ]; then
  >&2 echo "Please create and populate the $NSS_DB_DIR directory"
  exit 2
fi

OSNAME=""
ARCH="$(uname -s)-$(uname -m)"
case $ARCH in
  Linux-x86_64)
    OSNAME="linux64"
    ;;
  Linux-i*86)
    OSNAME="linux32"
    ;;
  *)
    >&2 echo "Unsupported architecture $ARCH"
    exit 2
esac

# Extract the MAR tools so we can use the signmar program.
MARTOOLS_TMP_DIR=$(mktemp -d)
trap "rm -rf $MARTOOLS_TMP_DIR" EXIT
MARTOOLS_ZIP="$WRAPPER_DIR/../../gitian-builder/inputs/mar-tools-${OSNAME}.zip"
cd $MARTOOLS_TMP_DIR
unzip -q "$MARTOOLS_ZIP"
cd $WRAPPER_DIR
export PATH="$MARTOOLS_TMP_DIR/mar-tools:$PATH"
if [ -z "${LD_LIBRARY_PATH+x}" ]; then
  export LD_LIBRARY_PATH="$MARTOOLS_TMP_DIR/mar-tools"
else
  export LD_LIBRARY_PATH="$MARTOOLS_TMP_DIR/mar-tools:$LD_LIBRARY_PATH"
fi

# Prompt for the NSS password.
# TODO: Test that the entered NSS password is correct.  But how?  Unfortunately,
# both certutil and signmar keep trying to read a new password when they are
# given an incorrect one.
read -s -p "NSS password:" NSSPASS
echo ""

# Sign each MAR file.
#
# Our strategy is to first move all .mar files out of the TORBROWSER_VERSION
# directory into a TORBROWSER_VERSION-unsigned/ directory.  Details:
#   If a file has not been signed, we move it to the -unsigned/ directory.
#   If a file has already been signed and a file with the same name exists in
#     the -unsigned/ directory, we just delete the signed file.
#   If a file has already been signed but no corresponding file exists in
#     the -unsigned/ directory, we report an error and exit.
#
# Once the above is done,  the -unsigned/ directory contains a set of .mar
# files that need to be signed, so we go ahead and sign them one-by-one.
SIGNED_DIR="$WRAPPER_DIR/$TORBROWSER_VERSION"
UNSIGNED_DIR="$WRAPPER_DIR/${TORBROWSER_VERSION}-unsigned"
mkdir -p "$UNSIGNED_DIR"
cd "$SIGNED_DIR"
for marfile in *.mar; do
  if [ ! -f "$marfile" ]; then
    continue;
  fi

  # First, we check for an existing signature.  The signmar -T output will
  # include a line like "Signature block found with N signatures".
  SIGINFO_PREFIX="Signature block found with "
  SIGINFO=$(signmar -T "$marfile" | grep "^${SIGINFO_PREFIX}")
  SIGCOUNT=0
  if [ ! -z "$SIGINFO" ]; then
    SIGCOUNT=$(echo $SIGINFO | sed -e "s/${SIGINFO_PREFIX}//" -e 's/\([0-9]*\).*$/\1/')
  fi
  if [ $SIGCOUNT -eq 0 ]; then
    # No signature; move this .mar file to the -unsigned/ directory.
    mv "$marfile" "$UNSIGNED_DIR/"
  elif [ -e "$UNSIGNED_DIR/$marfile" ]; then
    # We have an -unsigned/ copy; discard this file.
    rm "$marfile"
  else
    >&2 echo "Error: $SIGNED_DIR/$marfile is already signed but $UNSIGNED_DIR/$marfile is missing"
    # TODO: Try to remove the existing signature(s) from marfile?
    exit 1
  fi
done

# Use signmar to sign each .mar file that is now in the -unsigned directory.
TMPMAR="$SIGNED_DIR/tmp.mar"
trap "rm -f $TMPMAR" EXIT
cd "$UNSIGNED_DIR"
COUNT=0
for marfile in *.mar; do
  if [ ! -f "$marfile" ]; then
    continue;
  fi
  echo "$NSSPASS" | signmar -d "$NSS_DB_DIR" -n "$NSS_CERTNAME" -s \
      "$marfile" "$TMPMAR"
  mv "$TMPMAR" "$SIGNED_DIR/$marfile"
  COUNT=$((COUNT + 1))
done

echo "The $COUNT MAR files located in $SIGNED_DIR/ have been signed."
echo "The unsigned (original) MAR files are in $UNSIGNED_DIR/"
