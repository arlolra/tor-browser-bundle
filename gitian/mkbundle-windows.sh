#!/bin/bash
#
# This is a simple wrapper script to call out to gitian and assemble
# a bundle based on gitian's output.

. ./versions

WRAPPER_DIR=$PWD
GITIAN_DIR=$PWD/../../gitian-builder.git
DESCRIPTOR_DIR=$PWD/descriptors/
BUNDLE_DIR=$PWD/bundle-win32/

if [ ! -f $GITIAN_DIR/bin/gbuild ];
then
  echo "Gitian not found. You need a Gitian checkout in $GITIAN_DIR"
  exit 1
fi

# Set up the bundle dir skeleton
if [ ! -d $BUNDLE_DIR ];
then
  mkdir -p $BUNDLE_DIR/32/FirefoxPortable/App/Firefox
  mkdir -p $BUNDLE_DIR/32/FirefoxPortable/Data/profile/extensions
  mkdir -p $BUNDLE_DIR/32/App
  mkdir -p $BUNDLE_DIR/32/Data/Tor
  mkdir -p $BUNDLE_DIR/32/Docs
fi

mkdir -p $WRAPPER_DIR/../Bundle-Data/windows/FirefoxPortable/Data/profile/extensions/

cd $GITIAN_DIR
export PATH=$PATH:$PWD/libexec

# TODO: Make a super-fresh option that kills the base vms
if [ ! -f base-precise-i386.qcow2 ];
then
  ./bin/make-base-vm --suite precise --arch i386

  if [ $? -ne 0 ];
  then
      echo "i386 VM creation failed"
      exit 1
  fi
  stop-target
fi

if [ ! -d $GITIAN_DIR/inputs ];
then
  mkdir -p $GITIAN_DIR/inputs
fi

#torsocks $DESCRIPTOR_DIR/../fetch-inputs.sh $GITIAN_DIR/inputs

echo "pref(\"torbrowser.version\", \"$TORBROWSER_VERSION\");" > $GITIAN_DIR/inputs/torbrowser.version 

./bin/gbuild --commit tor-launcher=$TORLAUNCHER_TAG,tor-browser=$TORBROWSER_TAG $DESCRIPTOR_DIR/windows/gitian-firefox.yml
while [ $? -ne 0 ];
do
  mv var/build.log ./firefox-fail-win32.log.`date +%Y%m%d%H%M%S`
  ./bin/gbuild --commit tor-launcher=$TORLAUNCHER_TAG,tor-browser=$TORBROWSER_TAG $DESCRIPTOR_DIR/windows/gitian-firefox.yml
done

cp -a build/out/bin/32/firefox/* $BUNDLE_DIR/32/FirefoxPortable/App/Firefox/

cp -a build/out/bin/torlauncher*.xpi $WRAPPER_DIR/../Bundle-Data/windows/FirefoxPortable/Data/profile/extensions/torlauncher@torproject.org.xpi

./bin/gbuild --commit tor=$TOR_TAG $DESCRIPTOR_DIR/windows/gitian-tor.yml
while [ $? -ne 0 ];
do
  mv var/build.log ./tor-fail-win32.log.`date +%Y%m%d%H%M%S`
  ./bin/gbuild --commit tor=$TOR_TAG $DESCRIPTOR_DIR/windows/gitian-tor.yml
done

cp -a build/out/bin/32/tor $BUNDLE_DIR/32/App/
cp -a build/out/lib/32/lib* $BUNDLE_DIR/32/App/

# FIXME: Alpha vs non-alpha xpis??
# FIXME: NoScript versioning??
cp -a $GITIAN_DIR/inputs/$NOSCRIPT_PACKAGE $WRAPPER_DIR/../Bundle-Data/windows/FirefoxPortable/Data/profile/extensions/noscript@noscript.net.xpi
cp -a $GITIAN_DIR/inputs/$TORBUTTON_PACKAGE $WRAPPER_DIR/../Bundle-Data/windows/FirefoxPortable/Data/profile/extensions/torbutton@torproject.org.xpi
cp -a $GITIAN_DIR/inputs/$HTTPSE_PACKAGE $WRAPPER_DIR/../Bundle-Data/windows/FirefoxPortable/Data/profile/extensions/https-everywhere@eff.org.xpi
cp -a $GITIAN_DIR/inputs/$PDFJS_PACKAGE $WRAPPER_DIR/../Bundle-Data/windows/FirefoxPortable/Data/profile/extensions/uriloader@pdf.js.xpi

cp -a $WRAPPER_DIR/../Bundle-Data/windows/* $BUNDLE_DIR/32/

# XXX: Compile relativelink.exe
#cp -a $WRAPPER_DIR/../RelativeLink/ $BUNDLE_DIR/32/start-tor-browser

# FIXME: Fix this path juggling nonsense

cd $BUNDLE_DIR
# XXX: 7zip?? NSIS?? Should this be done in its own gitian descriptor?
cp -a 32 tor-browser_en-US
find tor-browser_en-US | xargs touch --date="2013-01-01 00:00:00"
zip -rX tor-browser-$TORBROWSER_VERSION-en_US.zip tor-browser_en-US
rm -rf tor-browser_en-US
cd ..


# FIXME: localization

# FIXME: docs

