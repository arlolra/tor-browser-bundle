#!/bin/bash
#
# fetch-inputs.sh - Fetch our inputs from the source mirror
#

MIRROR_URL=https://people.torproject.org/~mikeperry/mirrors/sources/
set -e
set -u
umask 0022

if ! [ -e ./versions ]; then
  echo >&2 "Error: ./versions file does not exist"
  exit 1
fi

. ./versions

WRAPPER_DIR=$(dirname "$0")
WRAPPER_DIR=$(readlink -f "$WRAPPER_DIR")

if [ "$#" -gt 1 ]; then
  echo >&2 "Usage: $0 [<inputsdir>]"
  exit 1
elif [ "$#" = 1 ]; then
  INPUTS_DIR="$1"
else
  INPUTS_DIR="$PWD/../../gitian-builder/inputs"
fi

mkdir -p "$INPUTS_DIR"
cd "$INPUTS_DIR"


##############################################################################
CLEANUP=$(tempfile)
trap "bash '$CLEANUP'; rm -f '$CLEANUP'" EXIT

verify() {
  local file="$1"; shift
  local keyring="$1"; shift

  local f
  for f in "$file" "$file.asc" "$keyring"; do
    if ! [ -e "$f" ]; then
      echo >&2 "Error: Required file $f does not exist."; exit 1
    fi
  done

  local tmpfile=$(tempfile)
  echo "rm -f '$tmpfile'" >> "$CLEANUP"
  local gpghome=$(mktemp -d)
  echo "rm -rf '$gpghome'" >> "$CLEANUP"
  exec 3> "$tmpfile"

  GNUPGHOME="$gpghome" gpg --no-options --no-default-keyring --trust-model=always --keyring="$keyring" --status-fd=3 --verify "$file.asc" "$file" >/dev/null 2>&1
  if grep -q '^\[GNUPG:\] GOODSIG ' "$tmpfile"; then
    return 0
  else
    return 1
  fi
}

get() {
  local file="$1"; shift
  local url="$1"; shift

  if ! wget -N "$url"; then
    echo >&2 "Error: Cannot download $url"
    mv "${file}" "${file}.DLFAILED"
    exit 1
  fi
}

update_git() {
  local dir="$1"; shift
  local url="$1"; shift
  local tag="${1:-}"

  if [ -d "$dir/.git" ];
  then
    (cd "$dir" && git fetch origin && git fetch --tags origin)
  else
    if ! git clone "$url"; then
      echo >&2 "Error: Cloning $url failed"
      exit 1
    fi
  fi

  if [ -n "$tag" ]; then
    (cd "$dir" && git checkout "$tag")
  fi
}

##############################################################################
# Get package files from mirror

# Get+verify sigs that exist
for i in OPENSSL # OBFSPROXY
do
  PACKAGE="${i}_PACKAGE"
  URL="${MIRROR_URL}${!PACKAGE}"
  get "${!PACKAGE}" "$URL"
  get "${!PACKAGE}.asc" "$URL.asc"

  if ! verify "${!PACKAGE}" "$WRAPPER_DIR/gpg/$i.gpg"; then
    echo "$i: GPG signature is broken for ${URL}"
    mv "${!PACKAGE}" "${!PACKAGE}.badgpg"
    exit 1
  fi
done

for i in TOOLCHAIN4 OSXSDK MSVCR100
do
  PACKAGE="${i}_PACKAGE"
  URL="${MIRROR_URL}${!PACKAGE}"
  get "${!PACKAGE}" "${MIRROR_URL}${!PACKAGE}"
done

# Verify packages with weak or no signatures via multipath downloads
# (OpenSSL is signed with MD5, and OSXSDK is not signed at all)
# XXX: Google won't allow wget -N.. We need to re-download the whole
# TOOLCHAIN4 each time. Rely only on SHA256 for now..
mkdir -p verify
cd verify
for i in OPENSSL OSXSDK
do
  URL="${i}_URL"
  PACKAGE="${i}_PACKAGE"
  if ! wget -N --no-remove-listing "${!URL}"; then
    echo "$i url ${!URL} is broken!"
    mv "${!PACKAGE}" "${!PACKAGE}.removed"
    exit 1
  fi
  if ! diff "${!PACKAGE}" "../${!PACKAGE}"; then
    echo "Package ${!PACKAGE} differs from our mirror's version!"
    exit 1
  fi
done
cd ..

# Noscript and PDF.JS are magikal and special:
wget -N https://addons.mozilla.org/firefox/downloads/latest/722/addon-722-latest.xpi
wget -N https://addons.mozilla.org/firefox/downloads/latest/352704/addon-352704-latest.xpi

# So is mingw:
if [ ! -f mingw-w64-svn-snapshot.zip ];
then
  svn co -r $MINGW_REV https://mingw-w64.svn.sourceforge.net/svnroot/mingw-w64/trunk mingw-w64-svn || exit 1
  # XXX: Path
  ZIPOPTS="-x*/.svn/*" faketime -f "2000-01-01 00:00:00" "$WRAPPER_DIR/build-helpers/dzip.sh" mingw-w64-svn-snapshot.zip mingw-w64-svn
fi

# Verify packages with weak or no signatures via direct sha256 check
# (OpenSSL is signed with MD5, and OSXSDK is not signed at all)
for i in OPENSSL OSXSDK TOOLCHAIN4 NOSCRIPT PDFJS MINGW MSVCR100
do
   PACKAGE="${i}_PACKAGE"
   HASH="${i}_HASH"
   if ! echo "${!HASH}  ${!PACKAGE}" | sha256sum -c -; then
     echo "Package hash for ${!PACKAGE} differs from our locally stored sha256!"
     exit 1
   fi
done

mkdir -p linux-langpacks
mkdir -p win32-langpacks
mkdir -p mac-langpacks

for i in $BUNDLE_LOCALES
do
  cd linux-langpacks
  wget -N "https://ftp.mozilla.org/pub/mozilla.org/firefox/releases/$FIREFOX_LANG_VER/linux-i686/xpi/$i.xpi"
  cd ..
  cd win32-langpacks
  wget -N "https://ftp.mozilla.org/pub/mozilla.org/firefox/releases/$FIREFOX_LANG_VER/win32/xpi/$i.xpi"
  cd ..
  cd mac-langpacks
  wget -N "https://ftp.mozilla.org/pub/mozilla.org/firefox/releases/$FIREFOX_LANG_VER/mac/xpi/$i.xpi"
  cd ..
done

"$WRAPPER_DIR/build-helpers/dzip.sh" win32-langpacks.zip win32-langpacks
"$WRAPPER_DIR/build-helpers/dzip.sh" linux-langpacks.zip linux-langpacks
"$WRAPPER_DIR/build-helpers/dzip.sh" mac-langpacks.zip mac-langpacks

ln -sf "$NOSCRIPT_PACKAGE" noscript@noscript.net.xpi
ln -sf "$PDFJS_PACKAGE" uriloader@pdf.js.xpi
ln -sf "$OPENSSL_PACKAGE" openssl.tar.gz

# Fetch latest gitian-builder itself
# XXX - this is broken if a non-standard inputs dir is selected using the command line flag.
cd ..
git remote set-url origin https://git.torproject.org/builders/gitian-builder.git
git fetch origin
git fetch --tags origin
git checkout tor-browser-builder-2
cd inputs

while read dir url tag; do
  update_git "$dir" "$url" "$tag"
done << EOF
tbb-windows-installer https://github.com/moba/tbb-windows-installer.git
zlib                  https://github.com/madler/zlib.git
libevent              https://github.com/libevent/libevent.git
tor-launcher          https://git.torproject.org/tor-launcher.git
tor                   https://git.torproject.org/tor.git
torbutton             https://git.torproject.org/torbutton.git
https-everywhere      https://git.torproject.org/https-everywhere.git
tor-browser           https://git.torproject.org/tor-browser.git          $TORBROWSER_TAG
EOF

exit 0

