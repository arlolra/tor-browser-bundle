#!/bin/bash

. ./versions

WRAPPER_DIR=$PWD

if [ -n $1 ]; then
  INPUTS_DIR=../../gitian-builder/inputs
else
  INPUTS_DIR=$1
fi

cd $INPUTS_DIR

rm -f bundle.inputs

sha256sum relativelink-src.zip >> bundle.inputs
sha256sum *-langpacks.zip >> bundle.inputs
sha256sum noscript@noscript.net.xpi >> bundle.inputs
sha256sum uriloader@pdf.js.xpi >> bundle.inputs

echo "`cd torbutton && git log --format=%H -1` torbutton.git" >> bundle.inputs
echo "`cd tor-launcher && git log --format=%H -1` tor-launcher.git" >> bundle.inputs
echo "`cd https-everywhere && git log --format=%H -1` https-everywhere.git" >> bundle.inputs
echo "`cd $WRAPPER_DIR && git log --format=%H -1` tor-browser-bundle.git" >> bundle.inputs

