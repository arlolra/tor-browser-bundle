#!/bin/bash
#

. ./versions

if [ -n $1 -a ! -d $1 ];
then
  mkdir $1
fi

if [ -d $1 ]; then
  cd $1
fi

# XXX: Not tagged yet
# cd ttb-windows-installer
# git tag -v $NSIS_TAG || exit 1
# cd ..
# 
# cd tor-launcher
# git tag -v $TORLAUNCHER_TAG || exit 1
# cd ..
# 
# cd tor-browser
# git tag -v $TORBROWSER_TAG || exit 1
# cd ..
#
# cd torbutton
# git tag -v $TORBUTTON_TAG || exit 1
# cd ..

cd zlib
git tag -v $ZLIB_TAG || exit 1
cd ..

cd libevent
git tag -v $LIBEVENT_TAG || exit 1
cd ..

cd tor
git tag -v $TOR_TAG || exit 1
cd ..


cd https-everywhere
git tag -v $HTTPSE_TAG || exit 1
cd ..


exit 0

