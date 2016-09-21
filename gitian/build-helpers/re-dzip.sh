#!/bin/sh -e
# Crappy deterministic zip repackager
export LC_ALL=C

ZIPFILE_BASENAME=$(basename -- "${1:?}")
TEMPDIR=tmp-re-dzip-$$
RE_DZIP=$(readlink -f -- "$(which -- "$0")")
PATH=$PATH:$(dirname "$RE_DZIP")

mkdir "$TEMPDIR"
unzip $UNZIPOPTS -d "$TEMPDIR" -- "$1"
(cd "$TEMPDIR"; dzip.sh ./"$ZIPFILE_BASENAME" .)
mv -- "$TEMPDIR"/"$ZIPFILE_BASENAME" "$1"
rm -rf "$TEMPDIR"
