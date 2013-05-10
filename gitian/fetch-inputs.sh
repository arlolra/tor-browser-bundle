#!/bin/bash
#
# fetch-inputs.sh - Fetch our inputs from the source mirror
#

. ./versions

if [ -d $1 ]; then
  cd $1
fi

MIRROR_URL=https://people.torproject.org/~mikeperry/mirrors/sources/

# Get package files from mirror
for i in OPENSSL LIBPNG LIBEVENT TORBUTTON HTTPSE HTTPSE_DEV OBFSPROXY ZLIB
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

# Noscript and PDF.JS are magikal and special:
wget -N https://addons.mozilla.org/firefox/downloads/latest/722/addon-722-latest.xpi
wget -N https://addons.mozilla.org/firefox/downloads/latest/352704/addon-352704-latest.xpi

# So is mingw:
if [ ! -f mingw-w64-svn-snapshot-r5830.zip ];
then
  svn co -r 5830 https://mingw-w64.svn.sourceforge.net/svnroot/mingw-w64/trunk mingw-w64-svn
  zip -x*/.svn/* -rX mingw-w64-svn-snapshot-r5830.zip mingw-w64-svn
fi

# Get+verify sigs that exist
# XXX: This doesn't cover everything. See #8525
for i in TORBUTTON LIBEVENT OBFSPROXY OPENSSL
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

exit 0

