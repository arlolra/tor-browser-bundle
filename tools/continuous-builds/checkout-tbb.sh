#! /bin/sh

# Checkout branch $2 (default=master) in directory $1 and update it.
# Exit 0 if HEAD changed due to the update.
# Exit 1 if HEAD has not changed.
# Proposed use:
# $ checkout-tbb.sh && build-tbb.sh

BUILDDIR=$HOME/usr/src/tor-browser-bundle/gitian
[ -n "$1" ] && BUILDDIR="$1"
BRANCH=master
[ -n "$2" ] && BRANCH=$2

cd "$BUILDDIR" || exit 2

HEAD=$(git rev-parse $BRANCH)
git checkout -q $BRANCH
git pull -q
[ $HEAD != $(git rev-parse $BRANCH) ]
