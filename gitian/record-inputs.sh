#!/bin/bash

. ./versions

WRAPPER_DIR=$PWD

if [ -z "$1" ]; then
  INPUTS_DIR=$PWD/../../gitian-builder/inputs
else
  INPUTS_DIR=$1
fi

cd $INPUTS_DIR

rm -f bundle.inputs

sha256sum apple* >> bundle.inputs
sha256sum multiarch-darwin* >> bundle.inputs
sha256sum mingw*.zip >> bundle.inputs
echo >> bundle.inputs
#sha256sum relativelink-src.zip >> bundle.inputs
#sha256sum *-langpacks.zip >> bundle.inputs
sha256sum noscript@noscript.net.xpi >> bundle.inputs
sha256sum uriloader@pdf.js.xpi >> bundle.inputs
sha256sum openssl-*gz >> bundle.inputs
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
fi

echo "`cd zlib && git log --format=%H -1 $ZLIB_TAG` zlib.git" >> bundle.inputs
echo "`cd tor && git log --format=%H -1 $TOR_TAG` tor.git" >> bundle.inputs
echo "`cd torbutton && git log --format=%H -1 $TORBUTTON_TAG` torbutton.git" >> bundle.inputs
echo "`cd tor-launcher && git log --format=%H -1 $TORLAUNCHER_TAG` tor-launcher.git" >> bundle.inputs
echo "`cd https-everywhere && git log --format=%H -1 $HTTPSE_TAG` https-everywhere.git" >> bundle.inputs
echo "`cd tbb-windows-installer && git log --format=%H -1 $NSIS_TAG` tbb-windows-installer.git" >> bundle.inputs
echo "`cd $INPUTS_DIR && git log --format=%H -1` gitian-builder.git" >> bundle.inputs
echo "`cd $WRAPPER_DIR && git log --format=%H -1` tor-browser-bundle.git" >> bundle.inputs

