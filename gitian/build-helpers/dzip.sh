#!/bin/sh
# Crappy deterministic zip wrapper
export LC_ALL=C

ZIPFILE=$1
shift

find $@ | sort | zip $ZIPOPTS -X -@ $ZIPFILE
