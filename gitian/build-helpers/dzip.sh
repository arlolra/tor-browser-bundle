#!/bin/sh
# Crappy determistic zip wrapper

find $2 | sort | zip $ZIPOPTS -X -@ $1
