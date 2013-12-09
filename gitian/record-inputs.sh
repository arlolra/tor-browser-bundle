#!/bin/bash

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

INPUTS_DIR=$WRAPPER_DIR/../../gitian-builder/inputs

cd $INPUTS_DIR

rm -f bundle.inputs

sha256sum $OSXSDK_PACKAGE >> bundle.inputs
sha256sum $TOOLCHAIN4_PACKAGE >> bundle.inputs
sha256sum mingw-w64-svn-snapshot.zip >> bundle.inputs
echo >> bundle.inputs
sha256sum noscript@noscript.net.xpi >> bundle.inputs
echo >> bundle.inputs

if [ "z$VERIFY_TAGS" = "z1" ];
then
  # If we're verifying tags, be explicit to gitian that we
  # want to build from tags.
  NSIS_TAG=refs/tags/$NSIS_TAG
  GITIAN_TAG=refs/tags/$GITIAN_TAG
  TORLAUNCHER_TAG=refs/tags/$TORLAUNCHER_TAG
  TORBROWSER_TAG=refs/tags/$TORBROWSER_TAG
  TORBUTTON_TAG=refs/tags/$TORBUTTON_TAG
  TOR_TAG=refs/tags/$TOR_TAG
  HTTPSE_TAG=refs/tags/$HTTPSE_TAG
  ZLIB_TAG=refs/tags/$ZLIB_TAG
  LIBEVENT_TAG=refs/tags/$LIBEVENT_TAG
  OPENSSL_TAG=refs/tags/$OPENSSL_TAG
fi

echo "`cd zlib && git log --format=%H -1 $ZLIB_TAG` zlib.git" >> bundle.inputs
echo "`cd tor && git log --format=%H -1 $TOR_TAG` tor.git" >> bundle.inputs
echo "`cd tor-browser && git log --format=%H -1 $TORBROWSER_TAG` tor-browser.git" >> bundle.inputs
echo "`cd torbutton && git log --format=%H -1 $TORBUTTON_TAG` torbutton.git" >> bundle.inputs
echo "`cd tor-launcher && git log --format=%H -1 $TORLAUNCHER_TAG` tor-launcher.git" >> bundle.inputs
echo "`cd https-everywhere && git log --format=%H -1 $HTTPSE_TAG` https-everywhere.git" >> bundle.inputs
echo "`cd tbb-windows-installer && git log --format=%H -1 $NSIS_TAG` tbb-windows-installer.git" >> bundle.inputs
echo "`cd openssl && git log --format=%H -1 $OPENSSL_TAG` openssl.git" >> bundle.inputs
echo "`cd $INPUTS_DIR && git log --format=%H -1` gitian-builder.git" >> bundle.inputs
echo "`cd $WRAPPER_DIR && git log --format=%H -1` tor-browser-bundle.git" >> bundle.inputs

