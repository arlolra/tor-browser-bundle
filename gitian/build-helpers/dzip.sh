#!/bin/sh -e
# Crappy deterministic zip wrapper
export LC_ALL=C

ZIPFILE=${1:?}
shift

if [ -n "$REFERENCE_DATETIME" ]; then
	find "$@" -exec touch --date="$REFERENCE_DATETIME" -- {} +
fi
find "$@"   -executable -exec chmod 700 {} +
find "$@" ! -executable -exec chmod 600 {} +
find "$@" | sort | zip $ZIPOPTS -X -@ "$ZIPFILE"
