#!/bin/sh
# Crappy deterministic zip wrapper
export LC_ALL=C

ZIPFILE=$1
shift

[ -n "$REFERENCE_DATETIME" ] && \
	find $@ -exec touch --date="$REFERENCE_DATETIME" {} \;

find $@ -executable -exec chmod 700 {} \;
find $@ ! -executable -exec chmod 600 {} \;

find $@ | sort | zip $ZIPOPTS -X -@ "$ZIPFILE"
