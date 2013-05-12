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
if [ ! -f ./base-lucid-amd64.qcow2 -a ! -f ./base-lucid-amd64.qcow2 ];
then
  if [ "z$USE_LXC" = "z1" ];
  then
    ./bin/make-base-vm --lxc --arch i386
    sudo ifconfig lxcbr0 10.0.2.2
  else
    ./bin/make-base-vm --arch i386
  fi

  if [ $? -ne 0 ];
  then
      echo "i386 VM creation failed"
      exit 1
  fi
  stop-target

  if [ "z$USE_LXC" = "z1" ];
  then
    ./bin/make-base-vm --lxc --arch amd64
    sudo ifconfig lxcbr0 10.0.2.2
  else
    ./bin/make-base-vm --arch amd64
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
rm -f $GITIAN_DIR/inputs/relativelink-src.zip
zip -rX $GITIAN_DIR/inputs/relativelink-src.zip ./RelativeLink/ 

cd ./Bundle-Data/linux
rm -f $GITIAN_DIR/inputs/linux-skeleton.zip
zip -rX $GITIAN_DIR/inputs/linux-skeleton.zip ./

cd $GITIAN_DIR

if [ ! -f $GITIAN_DIR/inputs/tor-linux32-gbuilt.zip -o ! -f $GITIAN_DIR/inputs/tor-linux64-gbuilt.zip ];
then
  ./bin/gbuild --commit tor=$TOR_TAG $DESCRIPTOR_DIR/linux/gitian-tor.yml
  if [ $? -ne 0 ];
  then
    mv var/build.log ./tor-fail-linux.log.`date +%Y%m%d%H%M%S`
    exit 1
  fi
  
  cp -a build/out/tor-linux*-gbuilt.zip $GITIAN_DIR/inputs/
fi

if [ ! -f $GITIAN_DIR/inputs/tor-browser-linux32-gbuilt.zip -o ! -f $GITIAN_DIR/inputs/tor-browser-linux64-gbuilt.zip ];
then
  ./bin/gbuild --commit tor-browser=$TORBROWSER_TAG $DESCRIPTOR_DIR/linux/gitian-firefox.yml
  if [ $? -ne 0 ];
  then
    mv var/build.log ./firefox-fail-linux.log.`date +%Y%m%d%H%M%S`
    exit 1
  fi

  cp -a build/out/tor-browser-linux*-gbuilt.zip $GITIAN_DIR/inputs/
fi

./bin/gbuild --commit tor-launcher=$TORLAUNCHER_TAG $DESCRIPTOR_DIR/linux/gitian-bundle.yml
if [ $? -ne 0 ];
then
  mv var/build.log ./bundle-fail-linux.log.`date +%Y%m%d%H%M%S`
  exit 1
fi

cp -a build/out/tor-browser-linux*7z* $WRAPPER_DIR

