#!/bin/sh
# Crappy determistic zip wrapper

ZIPFILE=$1
shift

find $@ | sort | zip $ZIPOPTS -X -@ $ZIPFILE
