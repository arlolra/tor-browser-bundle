#!/bin/sh
# Crappy deterministic dmg wrapper
export LC_ALL=C

DMGFILE=$1
shift

# Attempt to normalize inode ordering..
# XXX: the genisoimage -path-list argument seems broken
mkdir -p ~/build/tmp/dmg
cd $@
for i in `find . | sort`
do
  if [ -d $i ];
  then
    mkdir -p ~/build/tmp/dmg/$i
  else
    cp --parents -d --preserve=all $i ~/build/tmp/dmg/
  fi
done

find ~/build/tmp/dmg -executable -exec chmod 700 {} \;
find ~/build/tmp/dmg ! -executable -exec chmod 600 {} \;

genisoimage -D -V "Tor Browser" -no-pad -R -apple -o tbb-uncompressed.dmg ~/build/tmp/dmg/
~/build/libdmg-hfsplus/dmg/dmg dmg tbb-uncompressed.dmg $DMGFILE
rm tbb-uncompressed.dmg
rm -rf ~/build/tmp/dmg/
