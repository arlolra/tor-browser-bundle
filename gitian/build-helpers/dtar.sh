#!/bin/sh
# Crappy deterministic tar wrapper
export LC_ALL=C

TARFILE=$1
shift

find $@ -executable -exec chmod 700 {} \;
find $@ ! -executable -exec chmod 600 {} \;

tar --no-recursion -Jcvf $TARFILE `find $@ | sort`
