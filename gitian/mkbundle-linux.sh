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

echo "pref(\"torbrowser.version\", \"$TORBROWSER_VERSION-Linux\");" > $GITIAN_DIR/inputs/torbrowser.version 
echo "$TORBROWSER_VERSION" > $GITIAN_DIR/inputs/bare-version

cd $WRAPPER_DIR/..
rm -f $GITIAN_DIR/inputs/relativelink-src.zip
zip -rX $GITIAN_DIR/inputs/relativelink-src.zip ./RelativeLink/ 

cd ./Bundle-Data/linux
rm -f $GITIAN_DIR/inputs/linux-skeleton.zip
zip -rX $GITIAN_DIR/inputs/linux-skeleton.zip ./

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
  TORBUTTON_TAG=refs/tags/$TORBUTTON_TAG
  TOR_TAG=refs/tags/$TOR_TAG
  HTTPSE_TAG=refs/tags/$HTTPSE_TAG
  ZLIB_TAG=refs/tags/$ZLIB_TAG
  LIBEVENT_TAG=refs/tags/$LIBEVENT_TAG
fi

cd $GITIAN_DIR

if [ ! -f $GITIAN_DIR/inputs/tor-linux32-gbuilt.zip -o ! -f $GITIAN_DIR/inputs/tor-linux64-gbuilt.zip ];
then
  echo 
  echo "****** Starting Tor Component of Linux Bundle (1/3 for Linux) ******"
  echo 

  ./bin/gbuild --commit zlib=$ZLIB_TAG,libevent=$LIBEVENT_TAG,tor=$TOR_TAG $DESCRIPTOR_DIR/linux/gitian-tor.yml
  if [ $? -ne 0 ];
  then
    mv var/build.log ./tor-fail-linux.log.`date +%Y%m%d%H%M%S`
    exit 1
  fi
  
  cp -a build/out/tor-linux*-gbuilt.zip $GITIAN_DIR/inputs/
  cp -a result/tor-linux-res.yml $GITIAN_DIR/inputs/
else
  echo 
  echo "****** SKIPPING already built Tor Component of Linux Bundle (1/3 for Linux) ******"
  echo 

fi


if [ ! -f $GITIAN_DIR/inputs/tor-browser-linux32-gbuilt.zip -o ! -f $GITIAN_DIR/inputs/tor-browser-linux64-gbuilt.zip ];
then
  echo 
  echo "****** Starting TorBrowser Component of Linux Bundle (2/3 for Linux) ******"
  echo 

  ./bin/gbuild --commit tor-browser=$TORBROWSER_TAG $DESCRIPTOR_DIR/linux/gitian-firefox.yml
  if [ $? -ne 0 ];
  then
    mv var/build.log ./firefox-fail-linux.log.`date +%Y%m%d%H%M%S`
    exit 1
  fi

  cp -a build/out/tor-browser-linux*-gbuilt.zip $GITIAN_DIR/inputs/
  cp -a result/torbrowser-linux-res.yml $GITIAN_DIR/inputs/
else
  echo 
  echo "****** SKIPPING already built TorBrowser Component of Linux Bundle (2/3 for Linux) ******"
  echo 
fi

if [ ! -f $GITIAN_DIR/inputs/bundle-linux.gbuilt ];
then 
  echo 
  echo "****** Starting Bundling+Localization of Linux Bundle (3/3 for Linux) ******"
  echo 
  
  cp -a $WRAPPER_DIR/versions $GITIAN_DIR/inputs/
  cd $WRAPPER_DIR && ./record-inputs.sh && cd $GITIAN_DIR
  
  ./bin/gbuild --commit https-everywhere=$HTTPSE_TAG,tor-launcher=$TORLAUNCHER_TAG,torbutton=$TORBUTTON_TAG $DESCRIPTOR_DIR/linux/gitian-bundle.yml
  if [ $? -ne 0 ];
  then
    mv var/build.log ./bundle-fail-linux.log.`date +%Y%m%d%H%M%S`
    exit 1
  fi
  
  cp -a build/out/tor-browser-linux*xz* $WRAPPER_DIR || exit 1
  touch $GITIAN_DIR/inputs/bundle-linux.gbuilt
else
  echo 
  echo "****** SKIPPING already built Bundling+Localization of Linux Bundle (3/3 for Linux) ******"
  echo 
fi 

echo 
echo "****** Linux Bundle complete ******"
echo

