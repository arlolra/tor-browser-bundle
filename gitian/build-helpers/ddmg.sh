#!/bin/sh
# Crappy deterministic dmg wrapper
export LC_ALL=C

DMGFILE=$1
shift

if [ "z$DATA_OUTSIDE_APP_DIR" = "z1" ]; then
  EXE_MODE=0755
  OTHER_MODE=0644
else
  EXE_MODE=0750
  OTHER_MODE=0640
fi
find $@ -executable -exec chmod $EXE_MODE {} \;
find $@ ! -executable -exec chmod $OTHER_MODE {} \;

[ -n "$REFERENCE_DATETIME" ] && \
        find $@ -exec touch --date="$REFERENCE_DATETIME" {} \;

cd $@
find . -type f | sed -e 's/^\.\///' | sort | xargs -i echo "{}={}" > ~/build/filelist.txt
find . -type l | sed -e 's/^\.\///' | sort | xargs -i echo "{}={}" >> ~/build/filelist.txt

genisoimage -D -V "Tor Browser" -no-pad -R -apple -o ~/build/tbb-uncompressed.dmg -path-list ~/build/filelist.txt -graft-points -gid 20 -dir-mode $EXE_MODE -new-dir-mode $EXE_MODE

cd ~/build

~/build/libdmg-hfsplus/dmg/dmg dmg tbb-uncompressed.dmg $DMGFILE
rm tbb-uncompressed.dmg
rm ~/build/filelist.txt
