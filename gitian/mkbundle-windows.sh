#!/bin/bash
#
# This is a simple wrapper script to call out to gitian and assemble
# a bundle based on gitian's output.

. ./versions

WRAPPER_DIR=$PWD
GITIAN_DIR=$PWD/../../gitian-builder
DESCRIPTOR_DIR=$PWD/descriptors/

if [ ! -f $GITIAN_DIR/bin/gbuild ];
then
  echo "Gitian not found. You need a Gitian checkout in $GITIAN_DIR"
  exit 1
fi

cd $GITIAN_DIR
export PATH=$PATH:$PWD/libexec

# TODO: Make a super-fresh option that kills the base vms
if [ ! -f base-precise-i386.qcow2 ];
then
  if [ "z$USE_LXC" = "z1" ];
  then
    ./bin/make-base-vm --lxc --suite precise --arch i386
  else
    ./bin/make-base-vm --suite precise --arch i386
  fi

  if [ $? -ne 0 ];
  then
      echo "i386 VM creation failed"
      exit 1
  fi
  stop-target
fi

echo "pref(\"torbrowser.version\", \"$TORBROWSER_VERSION\");" > $GITIAN_DIR/inputs/torbrowser.version 

cd $WRAPPER_DIR/..
zip -rX $GITIAN_DIR/inputs/relativelink-src.zip ./RelativeLink/ 

cd ./Bundle-Data/windows
zip -rX $GITIAN_DIR/inputs/windows-skeleton.zip ./

cd $GITIAN_DIR

if [ ! -f $GITIAN_DIR/inputs/tor-win32-gbuilt.zip ];
then
  ./bin/gbuild --commit tor=$TOR_TAG $DESCRIPTOR_DIR/windows/gitian-tor.yml
  while [ $? -ne 0 ];
  do
    mv var/build.log ./tor-fail-win32.log.`date +%Y%m%d%H%M%S`
    ./bin/gbuild --commit tor=$TOR_TAG $DESCRIPTOR_DIR/windows/gitian-tor.yml
  done
  
  cp -a build/out/tor-win32-gbuilt.zip $GITIAN_DIR/inputs/
fi

if [ ! -f $GITIAN_DIR/inputs/tor-browser-win32-gbuilt.zip ];
then
  ./bin/gbuild --commit tor-launcher=$TORLAUNCHER_TAG,tor-browser=$TORBROWSER_TAG $DESCRIPTOR_DIR/windows/gitian-firefox.yml
  while [ $? -ne 0 ];
  do
    mv var/build.log ./firefox-fail-win32.log.`date +%Y%m%d%H%M%S`
    ./bin/gbuild --commit tor-launcher=$TORLAUNCHER_TAG,tor-browser=$TORBROWSER_TAG $DESCRIPTOR_DIR/windows/gitian-firefox.yml
  done

  cp -a build/out/tor-browser-win32-gbuilt.zip $GITIAN_DIR/inputs/
fi

./bin/gbuild --commit tbb-windows-installer=$NSIS_TAG $DESCRIPTOR_DIR/windows/gitian-bundle.yml
while [ $? -ne 0 ];
do
  mv var/build.log ./bundle-fail-win32.log.`date +%Y%m%d%H%M%S`
  ./bin/gbuild --commit tbb-windows-installer=$NSIS_TAG $DESCRIPTOR_DIR/windows/gitian-bundle.yml
done

cp -a build/out/*.exe $WRAPPER_DIR

# FIXME: localization
# FIXME: docs

