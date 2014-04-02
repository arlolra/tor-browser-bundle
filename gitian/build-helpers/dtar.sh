#!/bin/sh
# Crappy deterministic tar wrapper
export LC_ALL=C

TARFILE=$1
shift

# No need to execute chmod on (possibly) dangling symlinks.
find $@ ! -type l -executable -exec chmod 700 {} \;
find $@ ! -type l ! -executable -exec chmod 600 {} \;

find $@ | sort | tar --no-recursion -Jcvf $TARFILE -T -
