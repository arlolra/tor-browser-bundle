#!/bin/bash -e
#
# This is a simple wrapper script to call out to gitian and assemble
# a bundle based on gitian's output.

if [ -z "$1" ];
then
  VERSIONS_FILE=./versions
else
  VERSIONS_FILE=$1
fi

if ! [ -e $VERSIONS_FILE ]; then
  echo >&2 "Error: $VERSIONS_FILE file does not exist"
  exit 1
fi

. $VERSIONS_FILE

WRAPPER_DIR=$PWD
GITIAN_DIR=$PWD/../../gitian-builder
DESCRIPTOR_DIR=$PWD/descriptors/

if [ ! -f $GITIAN_DIR/bin/gbuild ];
then
  echo "Gitian not found. You need a Gitian checkout in $GITIAN_DIR"
  exit 1
fi

if [ -z "$NUM_PROCS" ];
then
  export NUM_PROCS=2
fi

./make-vms.sh

cd $GITIAN_DIR
export PATH=$PATH:$PWD/libexec

echo "pref(\"torbrowser.version\", \"$TORBROWSER_VERSION-MacOS\");" > $GITIAN_DIR/inputs/torbrowser.version 
echo "$TORBROWSER_VERSION" > $GITIAN_DIR/inputs/bare-version
cp -a $WRAPPER_DIR/$VERSIONS_FILE $GITIAN_DIR/inputs/versions

cp -r $WRAPPER_DIR/build-helpers/* $GITIAN_DIR/inputs/
cp $WRAPPER_DIR/patches/* $GITIAN_DIR/inputs/

cd $WRAPPER_DIR/..
rm -f $GITIAN_DIR/inputs/relativelink-src.zip
$WRAPPER_DIR/build-helpers/dzip.sh $GITIAN_DIR/inputs/relativelink-src.zip ./RelativeLink/ 

cd ./Bundle-Data/
rm -f $GITIAN_DIR/inputs/tbb-docs.zip
$WRAPPER_DIR/build-helpers/dzip.sh $GITIAN_DIR/inputs/tbb-docs.zip ./Docs/
cp beta/mac/torrc-defaults-appendix $GITIAN_DIR/inputs/torrc-defaults-appendix-mac
cp mac-tor.sh $GITIAN_DIR/inputs/

cd mac
rm -f $GITIAN_DIR/inputs/mac-skeleton.zip
$WRAPPER_DIR/build-helpers/dzip.sh $GITIAN_DIR/inputs/mac-skeleton.zip .

cd $WRAPPER_DIR

if [ "z$VERIFY_TAGS" = "z1" ];
then
  ./verify-tags.sh $GITIAN_DIR/inputs $VERSIONS_FILE || exit 1
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

cd $GITIAN_DIR

if [ ! -f $GITIAN_DIR/inputs/tor-mac32-gbuilt.zip ];
then
  echo 
  echo "****** Starting Tor Component of Mac Bundle (1/4 for Mac) ******"
  echo 

  ./bin/gbuild -j $NUM_PROCS --commit zlib=$ZLIB_TAG,libevent=$LIBEVENT_TAG,tor=$TOR_TAG $DESCRIPTOR_DIR/mac/gitian-tor.yml
  if [ $? -ne 0 ];
  then
    #mv var/build.log ./tor-fail-mac.log.`date +%Y%m%d%H%M%S`
    exit 1
  fi
  
  cp -a build/out/tor-mac*-gbuilt.zip $GITIAN_DIR/inputs/
  #cp -a result/tor-mac-res.yml $GITIAN_DIR/inputs/
else
  echo 
  echo "****** SKIPPING already built Tor Component of Mac Bundle (1/4 for Mac) ******"
  echo 
fi

if [ ! -f $GITIAN_DIR/inputs/tor-browser-mac32-gbuilt.zip ];
then
  echo 
  echo "****** Starting TorBrowser Component of Mac Bundle (2/4 for Mac) ******"
  echo 

  ./bin/gbuild -j $NUM_PROCS --commit tor-browser=$TORBROWSER_TAG $DESCRIPTOR_DIR/mac/gitian-firefox.yml
  if [ $? -ne 0 ];
  then
    #mv var/build.log ./firefox-fail-mac.log.`date +%Y%m%d%H%M%S`
    exit 1
  fi

  cp -a build/out/tor-browser-mac*-gbuilt.zip $GITIAN_DIR/inputs/
  #cp -a result/torbrowser-mac-res.yml $GITIAN_DIR/inputs/
else
  echo 
  echo "****** SKIPPING already built TorBrowser Component of Mac Bundle (2/4 for Mac) ******"
  echo 
fi

if [ ! -f $GITIAN_DIR/inputs/pluggable-transports-mac32-gbuilt.zip ];
then
  echo 
  echo "****** Starting Pluggable Transports Component of Mac Bundle (3/4 for Mac) ******"
  echo 

  ./bin/gbuild -j $NUM_PROCS --commit pyptlib=$PYPTLIB_TAG,obfsproxy=$OBFSPROXY_TAG,flashproxy=$FLASHPROXY_TAG $DESCRIPTOR_DIR/mac/gitian-pluggable-transports.yml
  if [ $? -ne 0 ];
  then
    #mv var/build.log ./firefox-fail-mac.log.`date +%Y%m%d%H%M%S`
    exit 1
  fi

  cp -a build/out/pluggable-transports-mac*-gbuilt.zip $GITIAN_DIR/inputs/
  #cp -a result/pluggable-transports-mac-res.yml $GITIAN_DIR/inputs/
else
  echo 
  echo "****** SKIPPING already built Pluggable Transports Component of Mac Bundle (3/4 for Mac) ******"
  echo 
fi


if [ ! -f $GITIAN_DIR/inputs/bundle-mac.gbuilt ];
then 
  echo 
  echo "****** Starting Bundling+Localization Component of Mac Bundle (4/4 for Mac) ******"
  echo 
  
  cd $WRAPPER_DIR && ./record-inputs.sh $VERSIONS_FILE && cd $GITIAN_DIR
  
  ./bin/gbuild -j $NUM_PROCS --commit https-everywhere=$HTTPSE_TAG,torbutton=$TORBUTTON_TAG,tor-launcher=$TORLAUNCHER_TAG $DESCRIPTOR_DIR/mac/gitian-bundle.yml
  if [ $? -ne 0 ];
  then
    #mv var/build.log ./bundle-fail-mac.log.`date +%Y%m%d%H%M%S`
    exit 1
  fi
  
  #cp -a build/out/*.dmg $WRAPPER_DIR
  mkdir -p $WRAPPER_DIR/$TORBROWSER_VERSION/
  cp -a build/out/*.zip $WRAPPER_DIR/$TORBROWSER_VERSION/ || exit 1
  touch $GITIAN_DIR/inputs/bundle-mac.gbuilt
else
  echo 
  echo "****** SKIPPING already built Bundling+Localization Component of Mac Bundle (4/4 for Mac) ******"
  echo 
fi

echo 
echo "****** Mac Bundle complete ******"
echo 


# FIXME: docs

