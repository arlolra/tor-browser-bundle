#!/bin/bash
#
# fetch-inputs.sh - Fetch our inputs from the source mirror
#

. ./versions

gpg --import ./gpg/*


if [ -n $1 ]; then
  INPUTS_DIR=../../gitian-builder/inputs
else
  INPUTS_DIR=$1
fi

if [ -n $INPUTS_DIR -a ! -d $INPUTS_DIR ];
then
  mkdir $INPUTS_DIR
fi

if [ -n $INPUTS_DIR -a -d $INPUTS_DIR ]; then
  cd $INPUTS_DIR
fi

MIRROR_URL=https://people.torproject.org/~mikeperry/mirrors/sources/

# Get package files from mirror
for i in OPENSSL TOOLCHAIN4 OSXSDK # OBFSPROXY
do
  PACKAGE=${i}"_PACKAGE"
  URL=${MIRROR_URL}${!PACKAGE}
  wget -N ${URL} #>& /dev/null
  if [ $? -ne 0 ]; then
    echo "$i url ${URL} is broken!"
    mv ${!PACKAGE} ${!PACKAGE}".removed"
    exit 1
  fi
done

# Get+verify sigs that exist
# XXX: This doesn't cover everything. See #8525
for i in OPENSSL # OBFSPROXY
do
  PACKAGE=${i}"_PACKAGE"
  URL=${MIRROR_URL}${!PACKAGE}
  if [ ! -f ${!PACKAGE}".asc" ]; then
    wget -N ${URL}".asc" >& /dev/null
    if [ $? -ne 0 ]; then
      echo "$i GPG sig url ${URL} is broken!"
      mv ${!PACKAGE} ${!PACKAGE}".nogpg"
      exit 1
    fi
  fi
  gpg ${!PACKAGE}".asc" >& /dev/null
  if [ $? -ne 0 ]; then
    echo "$i GPG signature is broken for ${URL}"
    mv ${!PACKAGE} ${!PACKAGE}".badgpg"
    exit 1
  fi
done

# Verify packages with weak or no signatures via multipath downloads
# (OpenSSL is signed with MD5, and OSXSDK is not signed at all)
mkdir -p verify
cd verify
for i in OPENSSL OSXSDK
do
  URL=${i}"_URL"
  PACKAGE=${i}"_PACKAGE"
  wget -N --no-remove-listing ${!URL} >& /dev/null
  if [ $? -ne 0 ]; then
    echo "$i url ${!URL} is broken!"
    mv ${!PACKAGE} ${!PACKAGE}".removed"
    exit 1
  fi
done
# XXX: Google won't allow wget -N.. We need to re-download the whole
# TOOLCHAIN4 each time :/
rm -f $TOOLCHAIN4_PACKAGE
wget $TOOLCHAIN4_URL
for i in OPENSSL OSXSDK TOOLCHAIN4
do
   PACKAGE=${i}"_PACKAGE"
   diff ${!PACKAGE} ../${!PACKAGE}
   if [ $? -ne 0 ]; then
     echo "Package ${!PACKAGE} differs from our mirror's version!"
     exit 1
   fi
done
cd ..

# Noscript and PDF.JS are magikal and special:
wget -N https://addons.mozilla.org/firefox/downloads/latest/722/addon-722-latest.xpi
wget -N https://addons.mozilla.org/firefox/downloads/latest/352704/addon-352704-latest.xpi

# So is mingw:
if [ ! -f mingw-w64-svn-snapshot-r5830.zip ];
then
  svn co -r 5830 https://mingw-w64.svn.sourceforge.net/svnroot/mingw-w64/trunk mingw-w64-svn || exit 1
  zip -x*/.svn/* -rX mingw-w64-svn-snapshot-r5830.zip mingw-w64-svn
fi

mkdir -p linux-langpacks
mkdir -p win32-langpacks
mkdir -p mac-langpacks

for i in $BUNDLE_LOCALES
do
  cd linux-langpacks
  wget -N https://ftp.mozilla.org/pub/mozilla.org/firefox/releases/$FIREFOX_LANG_VER/linux-i686/xpi/$i.xpi
  cd ..
  cd win32-langpacks
  wget -N https://ftp.mozilla.org/pub/mozilla.org/firefox/releases/$FIREFOX_LANG_VER/win32/xpi/$i.xpi
  cd ..
  cd mac-langpacks
  wget -N https://ftp.mozilla.org/pub/mozilla.org/firefox/releases/$FIREFOX_LANG_VER/mac/xpi/$i.xpi
  cd ..
done

zip -rX win32-langpacks.zip win32-langpacks
zip -rX linux-langpacks.zip linux-langpacks
zip -rX mac-langpacks.zip mac-langpacks

ln -sf $NOSCRIPT_PACKAGE noscript@noscript.net.xpi
ln -sf $PDFJS_PACKAGE uriloader@pdf.js.xpi
ln -sf $OPENSSL_PACKAGE openssl.tar.gz

if [ -d tbb-windows-installer/.git ];
then
  cd tbb-windows-installer
  git fetch origin
  git fetch --tags origin
  cd ..
else
  git clone https://github.com/moba/tbb-windows-installer.git || exit 1
fi

if [ -d zlib/.git ];
then
  cd zlib
  git fetch origin
  git fetch --tags origin
  cd ..
else
  git clone https://github.com/madler/zlib.git || exit 1
fi

if [ -d libevent/.git ];
then
  cd libevent
  git fetch origin
  git fetch --tags origin
  cd ..
else
  git clone https://github.com/libevent/libevent.git || exit 1
fi

if [ -d tor-launcher/.git ];
then
  cd tor-launcher
  git fetch origin
  git fetch --tags origin
  cd ..
else
  git clone https://git.torproject.org/tor-launcher.git || exit 1
fi

if [ -d tor/.git ];
then
  cd tor
  git fetch origin
  git fetch --tags origin
  cd ..
else
  git clone https://git.torproject.org/tor.git || exit 1
fi

if [ -d torbutton/.git ];
then
  cd torbutton
  git fetch origin
  git fetch --tags origin
  cd ..
else
  git clone https://git.torproject.org/torbutton.git || exit 1
fi

if [ -d https-everywhere/.git ];
then
  cd https-everywhere
  git fetch origin
  git fetch --tags origin
  cd ..
else
  git clone https://git.torproject.org/https-everywhere.git || exit 1
fi

if [ -d tor-browser/.git ];
then
  cd tor-browser
  git fetch origin
  git fetch --tags origin
  git checkout $TORBROWSER_TAG
  cd ..
else
  git clone https://git.torproject.org/tor-browser.git || exit 1
  cd tor-browser
  git checkout $TORBROWSER_TAG
  cd ..
fi

exit 0

