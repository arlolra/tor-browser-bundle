#!/bin/bash
#
# fetch-inputs.sh - Fetch our inputs from the source mirror
#

MIRROR_URL=https://people.torproject.org/~mikeperry/mirrors/sources/
MIRROR_URL_DCF=https://people.torproject.org/~dcf/mirrors/sources/
MIRROR_URL_ASN=https://people.torproject.org/~asn/mirrors/sources/
set -e
set -u
umask 0022

if ! [ -e ./versions ]; then
  echo >&2 "Error: ./versions file does not exist"
  exit 1
fi

WRAPPER_DIR=$(dirname "$0")
WRAPPER_DIR=$(readlink -f "$WRAPPER_DIR")

if [ "$#" = 1 ]; then
  INPUTS_DIR="$1"
  VERSIONS_FILE=./versions
elif [ "$#" = 2 ]; then
  INPUTS_DIR="$1"
  VERSIONS_FILE=$2
else
  echo >&2 "Usage: $0 [<inputsdir> <versions>]"
  exit 1
fi

if ! [ -e $VERSIONS_FILE ]; then
  echo >&2 "Error: $VERSIONS_FILE file does not exist"
  exit 1
fi

. $VERSIONS_FILE

mkdir -p "$INPUTS_DIR"
cd "$INPUTS_DIR"


##############################################################################
CLEANUP=$(tempfile)
trap "bash '$CLEANUP'; rm -f '$CLEANUP'" EXIT

# FIXME: This code is copied to verify-tags.sh.. Should we make a bash
# function library?
verify() {
  local file="$1"; shift
  local keyring="$1"; shift
  local suffix="$1"; shift

  local f
  for f in "$file" "$file.$suffix" "$keyring"; do
    if ! [ -e "$f" ]; then
      echo >&2 "Error: Required file $f does not exist."; exit 1
    fi
  done

  local tmpfile=$(tempfile)
  echo "rm -f '$tmpfile'" >> "$CLEANUP"
  local gpghome=$(mktemp -d)
  echo "rm -rf '$gpghome'" >> "$CLEANUP"
  exec 3> "$tmpfile"

  GNUPGHOME="$gpghome" gpg --no-options --no-default-keyring --trust-model=always --keyring="$keyring" --status-fd=3 --verify "$file.$suffix" "$file" >/dev/null 2>&1
  if grep -q '^\[GNUPG:\] GOODSIG ' "$tmpfile"; then
    return 0
  else
    return 1
  fi
}

get() {
  local file="$1"; shift
  local url="$1"; shift

  if ! wget -U "" -N "$url"; then
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
    (cd "$dir" && git remote set-url origin $url && git fetch --prune origin && git fetch --prune --tags origin)
  else
    if ! git clone "$url" "$dir"; then
      echo >&2 "Error: Cloning $url failed"
      exit 1
    fi
  fi

  if [ -n "$tag" ]; then
    (cd "$dir" && git checkout "$tag")
  fi

  # If we're not verifying tags, then some of the tags
  # may actually be branch names that require an update
  if [ $VERIFY_TAGS -eq 0 -a -n "$tag" ];
  then
    (cd "$dir" && git pull || true )
  fi
}

##############################################################################
# Get+verify sigs that exist
for i in OPENSSL BINUTILS GCC PYCRYPTO PYTHON_MSI GMP
do
  PACKAGE="${i}_PACKAGE"
  URL="${i}_URL"
  if [ "${i}" == "PYCRYPTO" -o "${i}" == "PYTHON_MSI" -o "${i}" == "OPENSSL" ]; then
    SUFFIX="asc"
  else
    SUFFIX="sig"
  fi
  get "${!PACKAGE}" "${!URL}"
  get "${!PACKAGE}.$SUFFIX" "${!URL}.$SUFFIX"

  if ! verify "${!PACKAGE}" "$WRAPPER_DIR/gpg/$i.gpg" $SUFFIX; then
    echo "$i: GPG signature is broken for ${!URL}"
    mv "${!PACKAGE}" "${!PACKAGE}.badgpg"
    exit 1
  fi
done

for i in TOOLCHAIN4 TOOLCHAIN4_OLD OSXSDK OSXSDK_OLD MSVCR100
do
  PACKAGE="${i}_PACKAGE"
  URL="${MIRROR_URL}${!PACKAGE}"
  get "${!PACKAGE}" "${MIRROR_URL}${!PACKAGE}"
done

# XXX: Omit googlecode.com packages because Google won't allow wget -N
# and because the download seems to 404 about 50% of the time.
for i in ARGPARSE
do
  PACKAGE="${i}_PACKAGE"
  URL="${MIRROR_URL_DCF}${!PACKAGE}"
  get "${!PACKAGE}" "${MIRROR_URL_DCF}${!PACKAGE}"
done

for i in PYYAML
do
  PACKAGE="${i}_PACKAGE"
  URL="${MIRROR_URL_ASN}${!PACKAGE}"
  get "${!PACKAGE}" "${MIRROR_URL_ASN}${!PACKAGE}"
done

for i in ZOPEINTERFACE TWISTED PY2EXE SETUPTOOLS PARSLEY GO NOTOCJKFONT STIXMATHFONT
do
  URL="${i}_URL"
  PACKAGE="${i}_PACKAGE"
  get "${!PACKAGE}" "${!URL}"
done

# NoScript is magikal and special:
wget -U "" -N ${NOSCRIPT_URL}

# Verify packages with weak or no signatures via direct sha256 check
# (OpenSSL is signed with MD5, and OSXSDK + OSXSDK_OLD are not signed at all)
for i in OSXSDK OSXSDK_OLD TOOLCHAIN4 TOOLCHAIN4_OLD NOSCRIPT MSVCR100 PYCRYPTO ARGPARSE PYYAML ZOPEINTERFACE TWISTED SETUPTOOLS OPENSSL GMP PARSLEY GO GCC NOTOCJKFONT STIXMATHFONT
do
   PACKAGE="${i}_PACKAGE"
   HASH="${i}_HASH"
   if ! echo "${!HASH}  ${!PACKAGE}" | sha256sum -c -; then
     echo "Package hash for ${!PACKAGE} differs from our locally stored sha256!"
     exit 1
   fi
done

# Fetch the common langpacks first, then the platform specific ones if any.
mkdir -p langpacks-$FIREFOX_LANG_VER/linux-langpacks
mkdir -p langpacks-$FIREFOX_LANG_VER/win32-langpacks
mkdir -p langpacks-$FIREFOX_LANG_VER/mac-langpacks

cd langpacks-$FIREFOX_LANG_VER

for i in $BUNDLE_LOCALES
do
  cd linux-langpacks
  wget -U "" -N "https://ftp.mozilla.org/pub/mozilla.org/firefox/candidates/${FIREFOX_LANG_VER}-candidates/${FIREFOX_LANG_BUILD}/linux-i686/xpi/$i.xpi"
  cd ..
  cd win32-langpacks
  wget -U "" -N "https://ftp.mozilla.org/pub/mozilla.org/firefox/candidates/${FIREFOX_LANG_VER}-candidates/${FIREFOX_LANG_BUILD}/win32/xpi/$i.xpi"
  cd ..
  cd mac-langpacks
  wget -U "" -N "https://ftp.mozilla.org/pub/mozilla.org/firefox/candidates/${FIREFOX_LANG_VER}-candidates/${FIREFOX_LANG_BUILD}/mac/xpi/$i.xpi"
  cd ..
done

for i in $BUNDLE_LOCALES_LINUX
do
  cd linux-langpacks
  wget -U "" -N "https://ftp.mozilla.org/pub/mozilla.org/firefox/candidates/${FIREFOX_LANG_VER}-candidates/${FIREFOX_LANG_BUILD}/linux-i686/xpi/$i.xpi"
  cd ..
done
for i in $BUNDLE_LOCALES_WIN32
do
  cd win32-langpacks
  wget -U "" -N "https://ftp.mozilla.org/pub/mozilla.org/firefox/candidates/${FIREFOX_LANG_VER}-candidates/${FIREFOX_LANG_BUILD}/win32/xpi/$i.xpi"
  cd ..
done
for i in $BUNDLE_LOCALES_MAC
do
  cd mac-langpacks
  wget -U "" -N "https://ftp.mozilla.org/pub/mozilla.org/firefox/candidates/${FIREFOX_LANG_VER}-candidates/${FIREFOX_LANG_BUILD}/mac/xpi/$i.xpi"
  cd ..
done

"$WRAPPER_DIR/build-helpers/dzip.sh" ../win32-langpacks.zip win32-langpacks
"$WRAPPER_DIR/build-helpers/dzip.sh" ../linux-langpacks.zip linux-langpacks
"$WRAPPER_DIR/build-helpers/dzip.sh" ../mac-langpacks.zip mac-langpacks

cd ..

ln -sf "$NOSCRIPT_PACKAGE" noscript@noscript.net.xpi
ln -sf "$OPENSSL_PACKAGE" openssl.tar.gz
ln -sf "$BINUTILS_PACKAGE" binutils.tar.bz2
ln -sf "$GCC_PACKAGE" gcc.tar.bz2
ln -sf "$PYTHON_MSI_PACKAGE" python.msi
ln -sf "$PYCRYPTO_PACKAGE" pycrypto.tar.gz
ln -sf "$ARGPARSE_PACKAGE" argparse.tar.gz
ln -sf "$PYYAML_PACKAGE" pyyaml.tar.gz
ln -sf "$ZOPEINTERFACE_PACKAGE" zope.interface.zip
ln -sf "$TWISTED_PACKAGE" twisted.tar.bz2
ln -sf "$PY2EXE_PACKAGE" py2exe.exe
ln -sf "$SETUPTOOLS_PACKAGE" setuptools.tar.gz
ln -sf "$GMP_PACKAGE" gmp.tar.bz2
ln -sf "$PARSLEY_PACKAGE" parsley.tar.gz
ln -sf "$GO_PACKAGE" go.tar.gz

# Fetch latest gitian-builder itself
# XXX - this is broken if a non-standard inputs dir is selected using the command line flag.
cd ..
git remote set-url origin https://git.torproject.org/builders/gitian-builder.git
git fetch origin
git fetch --tags origin # XXX - why do we fetch tags specifically?
git checkout tor-browser-builder-3
git merge origin/tor-browser-builder-3
cd inputs

while read dir url tag; do
  update_git "$dir" "$url" "$tag"
done << EOF
tbb-windows-installer https://github.com/moba/tbb-windows-installer.git $NSIS_TAG
zlib                  https://github.com/madler/zlib.git       $ZLIB_TAG
libevent              https://github.com/libevent/libevent.git $LIBEVENT_TAG
tor                   https://git.torproject.org/tor.git              $TOR_TAG
https-everywhere      https://git.torproject.org/https-everywhere.git $HTTPSE_TAG
torbutton             https://git.torproject.org/torbutton.git            $TORBUTTON_TAG
tor-launcher          https://git.torproject.org/tor-launcher.git         $TORLAUNCHER_TAG
tor-browser           https://git.torproject.org/tor-browser.git          $TORBROWSER_TAG
mingw-w64-git         http://git.code.sf.net/p/mingw-w64/mingw-w64        $MINGW_TAG
pyptlib               https://git.torproject.org/pluggable-transports/pyptlib.git $PYPTLIB_TAG
obfsproxy https://git.torproject.org/pluggable-transports/obfsproxy.git $OBFSPROXY_TAG
libfte                https://github.com/kpdyer/libfte.git $LIBFTE_TAG
fteproxy              https://github.com/kpdyer/fteproxy.git $FTEPROXY_TAG
libdmg-hfsplus        https://github.com/vasi/libdmg-hfsplus.git $LIBDMG_TAG
txsocksx              https://github.com/habnabit/txsocksx.git $TXSOCKSX_TAG
goptlib               https://git.torproject.org/pluggable-transports/goptlib.git $GOPTLIB_TAG
meek                  https://git.torproject.org/pluggable-transports/meek.git $MEEK_TAG
faketime              https://github.com/wolfcw/libfaketime $FAKETIME_TAG
ed25519               https://github.com/agl/ed25519.git $GOED25519_TAG
siphash               https://github.com/dchest/siphash.git $GOSIPHASH_TAG
goxcrypto             https://go.googlesource.com/crypto  $GO_X_CRYPTO_TAG
goxnet                https://go.googlesource.com/net  $GO_X_NET_TAG
obfs4                 https://git.torproject.org/pluggable-transports/obfs4.git $OBFS4_TAG
noto-fonts            https://github.com/googlei18n/noto-fonts $NOTOFONTS_TAG
EOF

# HTTPS-Everywhere is special, too. We need to initialize the git submodules and
# update them here. Otherwise it would happen during the build.
cd https-everywhere
git submodule init
git submodule update
cd ..

exit 0

