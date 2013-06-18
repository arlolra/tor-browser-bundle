#!/bin/bash

. ./versions

WRAPPER_DIR=$PWD

if [ -n $1 ]; then
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
sha256sum relativelink-src.zip >> bundle.inputs
sha256sum *-langpacks.zip >> bundle.inputs
sha256sum noscript@noscript.net.xpi >> bundle.inputs
sha256sum uriloader@pdf.js.xpi >> bundle.inputs
sha256sum openssl-*gz >> bundle.inputs
echo >> bundle.inputs
echo "`cd zlib && git log --format=%H -1` zlib.git" >> bundle.inputs
echo "`cd tor && git log --format=%H -1` tor.git" >> bundle.inputs
echo "`cd torbutton && git log --format=%H -1` torbutton.git" >> bundle.inputs
echo "`cd tor-launcher && git log --format=%H -1` tor-launcher.git" >> bundle.inputs
echo "`cd https-everywhere && git log --format=%H -1` https-everywhere.git" >> bundle.inputs
echo "`cd tbb-windows-installer && git log --format=%H -1` tbb-windows-installer.git" >> bundle.inputs
echo "`cd $WRAPPER_DIR && git log --format=%H -1` tor-browser-bundle.git" >> bundle.inputs
echo "`cd $INPUTS_DIR && git log --format=%H -1` gitian-builder.git" >> bundle.inputs

