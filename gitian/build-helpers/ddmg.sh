#!/bin/sh
# Crappy deterministic dmg wrapper
export LC_ALL=C

DMGFILE=$1
shift

find $@ -executable -exec chmod 700 {} \;
find $@ ! -executable -exec chmod 600 {} \;

cd $@
find . -type f | sed -e 's/^\.\///' | sort | xargs -i echo "{}={}" > ~/build/filelist.txt
find . -type l | sed -e 's/^\.\///' | sort | xargs -i echo "{}={}" >> ~/build/filelist.txt

mkisofs -D -V "Tor Browser" -no-pad -R -apple -o ~/build/tbb-uncompressed.dmg -path-list ~/build/filelist.txt -graft-points -dir-mode 0700 -new-dir-mode 0700

cd ~/build

~/build/libdmg-hfsplus/dmg/dmg dmg tbb-uncompressed.dmg $DMGFILE
rm tbb-uncompressed.dmg
rm ~/build/filelist.txt
