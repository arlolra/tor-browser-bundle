#!/bin/bash
#

set -e
set -u

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

cd "$INPUTS_DIR"

CLEANUP=$(tempfile)
trap "bash '$CLEANUP'; rm -f '$CLEANUP'" EXIT

verify_git() {
  local dir="$1"; shift
  local keyring="$1"; shift
  local tag="$1"; shift

  local gpghome=$(mktemp -d)
  echo "rm -rf '$gpghome'" >> "$CLEANUP"
  GNUPGHOME="$gpghome" gpg --import "$keyring"

  pushd .
  cd "$dir"
  if ! GNUPGHOME="$gpghome" git tag -v "$tag"; then
    echo >&2 "$dir: verification of tag $tag against $keyring failed!"
    exit 1
  fi
  popd
}

# FIXME: This code is copied from fetch-inputs.sh.. Should we make a bash
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

check_git_hash() {
  local dir="$1"; shift
  local commit="${1:-}"

  if [ -n "$commit" ]; then
    (cd "$dir" && git checkout "$commit")
  fi
}


while read dir keyring tag; do
  verify_git "$dir" "$WRAPPER_DIR/gpg/$keyring" "$tag"
done << EOF
tbb-windows-installer tbb-windows-installer.gpg $NSIS_TAG
tor-launcher          torbutton.gpg             $TORLAUNCHER_TAG
tor-browser           torbutton.gpg             $TORBROWSER_TAG
torbutton             torbutton.gpg             $TORBUTTON_TAG
zlib                  zlib.gpg                  $ZLIB_TAG
libevent              libevent.gpg              $LIBEVENT_TAG
tor                   tor.gpg                   $TOR_TAG
https-everywhere      https-everywhere.gpg      $HTTPSE_TAG
pyptlib               pyptlib.gpg               $PYPTLIB_TAG
obfsproxy             obfsproxy.gpg             $OBFSPROXY_TAG
flashproxy            flashproxy.gpg            $FLASHPROXY_TAG
EOF

while read dir commit; do
  check_git_hash "$dir" "$commit"
done << EOF
libdmg-hfsplus          $LIBDMG_TAG
libfte                  $LIBFTE_TAG
fteproxy                $FTEPROXY_TAG
txsocksx                $TXSOCKSX_TAG
EOF

# Verify signatures on signed packages
for i in BINUTILS GCC PYTHON PYCRYPTO M2CRYPTO PYTHON_MSI GMP LXML
do
  PACKAGE="${i}_PACKAGE"
  URL="${i}_URL"
  if [ "${i}" == "PYTHON" -o "${i}" == "PYCRYPTO" -o "${i}" == "M2CRYPTO" -o \
       "${i}" == "PYTHON_MSI" -o "${i}" == "LXML" ]; then
    SUFFIX="asc"
  else
    SUFFIX="sig"
  fi

  if ! verify "${!PACKAGE}" "$WRAPPER_DIR/gpg/$i.gpg" $SUFFIX; then
    echo "$i: GPG signature is broken for ${!URL}"
    mv "${!PACKAGE}" "${!PACKAGE}.badgpg"
    exit 1
  fi
done

# Verify packages with weak or no signatures via direct sha256 check
# (OpenSSL is signed with MD5, and OSXSDK is not signed at all)
for i in OSXSDK TOOLCHAIN4 TOOLCHAIN4_OLD NOSCRIPT MINGW MSVCR100 PYCRYPTO ARGPARSE PYYAML ZOPEINTERFACE TWISTED M2CRYPTO SETUPTOOLS OPENSSL GMP PARSLEY
do
   PACKAGE="${i}_PACKAGE"
   HASH="${i}_HASH"
   if ! echo "${!HASH}  ${!PACKAGE}" | sha256sum -c -; then
     echo "Package hash for ${!PACKAGE} differs from our locally stored sha256!"
     exit 1
   fi
done


cd "$INPUTS_DIR"
verify_git "." "$WRAPPER_DIR/gpg/torbutton.gpg" "$GITIAN_TAG"
git checkout "$GITIAN_TAG"

