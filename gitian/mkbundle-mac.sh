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
    sudo ifconfig lxcbr0 10.0.2.2
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

echo "pref(\"torbrowser.version\", \"$TORBROWSER_VERSION-MacOS\");" > $GITIAN_DIR/inputs/torbrowser.version 
echo "$TORBROWSER_VERSION" > $GITIAN_DIR/inputs/bare-version

cd $WRAPPER_DIR/..
rm -f $GITIAN_DIR/inputs/relativelink-src.zip
zip -rX $GITIAN_DIR/inputs/relativelink-src.zip ./RelativeLink/ 

# XXX: Need skeleton
#cd ./Bundle-Data/mac
#rm -f $GITIAN_DIR/inputs/mac-skeleton.zip
#zip -rX $GITIAN_DIR/inputs/mac-skeleton.zip ./

cd $WRAPPER_DIR

if [ "z$VERIFY_TAGS" = "z1" ];
then
  ./verify-tags.sh $GITIAN_DIR/inputs || exit 1
  # If we're verifying tags, be explicit to gitian that we
  # want to build from tags.
  # XXX: Some things still have no tags
  # TORBROWSER_TAG=refs/tags/$TORBROWSER_TAG
  # NSIS_TAG=refs/tags/$NSIS_TAG
  # TORLAUNCHER_TAG=refs/tags/$TORLAUNCHER_TAG
  # TORBUTTON_TAG=refs/tags/$TORBUTTON_TAG
  TOR_TAG=refs/tags/$TOR_TAG
  HTTPSE_TAG=refs/tags/$HTTPSE_TAG
  ZLIB_TAG=refs/tags/$ZLIB_TAG
  LIBEVENT_TAG=refs/tags/$LIBEVENT_TAG
fi

cd $GITIAN_DIR

if [ ! -f $GITIAN_DIR/inputs/tor-mac32-gbuilt.zip ];
then
  ./bin/gbuild --commit zlib=$ZLIB_TAG,libevent=$LIBEVENT_TAG,tor=$TOR_TAG $DESCRIPTOR_DIR/mac/gitian-tor.yml
  if [ $? -ne 0 ];
  then
    mv var/build.log ./tor-fail-mac.log.`date +%Y%m%d%H%M%S`
    exit 1
  fi
  
  cp -a build/out/tor-mac*-gbuilt.zip $GITIAN_DIR/inputs/
fi

if [ ! -f $GITIAN_DIR/inputs/tor-browser-mac32-gbuilt.zip ];
then
  ./bin/gbuild --commit tor-browser=3857a01c551e796b14d9cda183726113b472fd32 $DESCRIPTOR_DIR/mac/gitian-firefox.yml
  #./bin/gbuild --commit tor-browser=$TORBROWSER_TAG $DESCRIPTOR_DIR/mac/gitian-firefox.yml
  if [ $? -ne 0 ];
  then
    mv var/build.log ./firefox-fail-mac.log.`date +%Y%m%d%H%M%S`
    exit 1
  fi

  cp -a build/out/tor-browser-mac*-gbuilt.zip $GITIAN_DIR/inputs/
fi

./bin/gbuild --commit https-everywhere=$HTTPSE_TAG,torbutton=$TORBUTTON_TAG,tor-launcher=$TORLAUNCHER_TAG $DESCRIPTOR_DIR/mac/gitian-bundle.yml
if [ $? -ne 0 ];
then
  mv var/build.log ./bundle-fail-mac.log.`date +%Y%m%d%H%M%S`
  exit 1
fi

cp -a build/out/*.dmg $WRAPPER_DIR
cp -a build/out/*.zip $WRAPPER_DIR

# FIXME: docs

