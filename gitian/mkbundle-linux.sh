#!/bin/bash
#
# This is a simple wrapper script to call out to gitian and assemble
# a bundle based on gitian's output.

. ./versions

TORBROWSER_VERSION=3.0-alpha-1

WRAPPER_DIR=$PWD
GITIAN_DIR=$PWD/../../gitian-builder.git
DESCRIPTOR_DIR=$PWD/descriptors/
BUNDLE_DIR=$PWD/bundle-linux/

if [ ! -f $GITIAN_DIR/bin/gbuild ];
then
  echo "Gitian not found. You need a Gitian checkout in $GITIAN_DIR"
  exit 1
fi

# Set up the bundle dir skeleton
if [ ! -d $BUNDLE_DIR ];
then
  mkdir -p $BUNDLE_DIR/32/App/Firefox
  mkdir -p $BUNDLE_DIR/32/Lib/libz
  mkdir -p $BUNDLE_DIR/32/Data/profile/extensions
  mkdir -p $BUNDLE_DIR/32/Data/Tor
  mkdir -p $BUNDLE_DIR/32/Docs

  mkdir -p $BUNDLE_DIR/64/App/Firefox
  mkdir -p $BUNDLE_DIR/64/Lib/libz
  mkdir -p $BUNDLE_DIR/64/Data/profile/extensions
  mkdir -p $BUNDLE_DIR/64/Data/Tor
  mkdir -p $BUNDLE_DIR/64/Docs
fi

mkdir -p $WRAPPER_DIR/../Bundle-Data/linux/profile/extensions/

cd $GITIAN_DIR
export PATH=$PATH:$PWD/libexec

# TODO: Make a super-fresh option that kills the base vms
if [ ! -f ./base-lucid-amd64.qcow2 -a ! -f ./base-lucid-amd64.qcow2 ];
then
  ./bin/make-base-vm --arch i386

  if [ $? -ne 0 ];
  then
      echo "i386 VM creation failed"
      exit 1
  fi
  stop-target

  ./bin/make-base-vm --arch amd64
  if [ $? -ne 0 ];
  then
      echo "i386 VM creation failed"
      exit 1
  fi
  stop-target
fi

# XXX: Check args for sanity and extract tags -> git hashes

if [ ! -d $GITIAN_DIR/inputs ];
then
  mkdir -p $GITIAN_DIR/inputs
fi

torsocks $DESCRIPTOR_DIR/../fetch-inputs.sh $GITIAN_DIR/inputs

echo "pref(\"torbrowser.version\", \"$TORBROWSER_VERSION\");" > $GITIAN_DIR/inputs/torbrowser.version 

# XXX: Set these tags from args
./bin/gbuild --commit tor-launcher=master,tor-browser=tor-browser-17.0.5esr-2 $DESCRIPTOR_DIR/linux/gitian-firefox.yml
while [ $? -ne 0 ];
do
  mv var/build.log ./firefox-fail.log.`date +%Y%m%d%H%M%S`
  ./bin/gbuild --commit tor-launcher=master,tor-browser=tor-browser-17.0.5esr-2 $DESCRIPTOR_DIR/linux/gitian-firefox.yml
done

cp -a build/out/bin/32/firefox/* $BUNDLE_DIR/32/App/Firefox/
cp -a build/out/bin/64/firefox/* $BUNDLE_DIR/64/App/Firefox/
cp -a build/out/bin/torlauncher*.xpi $WRAPPER_DIR/../Bundle-Data/linux/profile/extensions/torlauncher@torproject.org.xpi

# TODO: There goes FIPS-140.. We could upload these somewhere unique and
# subsequent builds could test to see if they've been uploaded before...
# But let's find out if it actually matters first..
rm $BUNDLE_DIR/32/App/Firefox/*.chk
rm $BUNDLE_DIR/64/App/Firefox/*.chk

./bin/gbuild --commit tor=tor-0.2.4.12-alpha $DESCRIPTOR_DIR/linux/gitian-tor.yml
while [ $? -ne 0 ];
do
  mv var/build.log ./tor-fail.log.`date +%Y%m%d%H%M%S`
  ./bin/gbuild --commit tor=tor-0.2.4.12-alpha $DESCRIPTOR_DIR/linux/gitian-tor.yml
done

cp -a build/out/bin/32/tor $BUNDLE_DIR/32/App/
cp -a build/out/bin/64/tor $BUNDLE_DIR/64/App/

cp -a build/out/lib/32/lib* $BUNDLE_DIR/32/Lib/
cp -a build/out/lib/64/lib* $BUNDLE_DIR/64/Lib/


# XXX: Alpha vs non-alpha xpis??
# XXX: NoScript versioning??
# XXX: tor-launcher+torbutton from git?
cp -a $GITIAN_DIR/inputs/$NOSCRIPT_PACKAGE $WRAPPER_DIR/../Bundle-Data/linux/profile/extensions/noscript@noscript.net.xpi
cp -a $GITIAN_DIR/inputs/$TORBUTTON_PACKAGE $WRAPPER_DIR/../Bundle-Data/linux/profile/extensions/torbutton@torproject.org.xpi
cp -a $GITIAN_DIR/inputs/$HTTPSE_PACKAGE $WRAPPER_DIR/../Bundle-Data/linux/profile/extensions/https-everywhere@eff.org.xpi
cp -a $GITIAN_DIR/inputs/$NOSCRIPT_PACKAGE $WRAPPER_DIR/../Bundle-Data/linux/profile/extensions/\{73a6fe31-595d-460b-a920-fcc0f8843232\}.xpi
cp -a $GITIAN_DIR/inputs/$PDFJS_PACKAGE $WRAPPER_DIR/../Bundle-Data/linux/profile/extensions/uriloader@pdf.js.xpi

cp -a $WRAPPER_DIR/../Bundle-Data/linux/* $BUNDLE_DIR/32/Data/
cp -a $WRAPPER_DIR/../Bundle-Data/linux/* $BUNDLE_DIR/64/Data/

cp -a $WRAPPER_DIR/../RelativeLink/RelativeLink.sh $BUNDLE_DIR/32/start-tor-browser
cp -a $WRAPPER_DIR/../RelativeLink/RelativeLink.sh $BUNDLE_DIR/64/start-tor-browser

# XXX: Fix this path juggling nonsense
cd $BUNDLE_DIR
cp -a 64 tor-browser_en-US
find tor-browser_en-US | xargs touch --date="2013-01-01 00:00:00"
tar -cvf ../tor-browser-gnu-linux-x86_64-$VERSION-en-US.tar --owner=root --group=root tor-browser_en-US
rm -rf tor-browser_en-US 
cd ..
gzip -n tor-browser-gnu-linux-x86_64-$VERSION-en-US.tar

cp -a 32 tor-browser_en-US
find tor-browser_en-US | xargs touch --date="2013-01-01 00:00:00"
tar -cvf ../tor-browser-gnu-linux-x86-$VERSION-en-US.tar --owner=root --group=root tor-browser_en-US
rm -rf tor-browser_en-US
cd ..
gzip -n tor-browser-gnu-linux-x86_64-$VERSION-en-US.tar

# FIXME: localization

# FIXME: docs

