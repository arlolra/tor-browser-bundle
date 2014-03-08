#!/bin/sh
# Crappy deterministic dmg wrapper
export LC_ALL=C

DMGFILE=$1
shift

# We need group readability for some Macs to be able to handle /Applications
# installation. Still unclear exactly why this is -- it is not dependent on
# OSX version...
find $@ -executable -exec chmod 750 {} \;
find $@ ! -executable -exec chmod 640 {} \;

cd $@
find . -type f | sed -e 's/^\.\///' | sort | xargs -i echo "{}={}" > ~/build/filelist.txt
find . -type l | sed -e 's/^\.\///' | sort | xargs -i echo "{}={}" >> ~/build/filelist.txt

mkisofs -D -V "Tor Browser" -no-pad -R -apple -o ~/build/tbb-uncompressed.dmg -path-list ~/build/filelist.txt -graft-points -gid 20 -dir-mode 0750 -new-dir-mode 0750

cd ~/build

~/build/libdmg-hfsplus/dmg/dmg dmg tbb-uncompressed.dmg $DMGFILE
rm tbb-uncompressed.dmg
rm ~/build/filelist.txt
