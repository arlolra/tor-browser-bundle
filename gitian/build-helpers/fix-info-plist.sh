#!/bin/bash
# We cannot use set -e in this script because read returns a non-zero value.
export LC_ALL=C

usage()
{
  echo "usage: $0 TORBROWSER_VERSION < Info.plist > FixedInfo.plist" 1>&2
  exit 2
}

if [ $# -ne 1 ]; then
  usage;
fi

TORBROWSER_VERSION="$1"; shift

# Replace version numbers.
# Add NSHumanReadableCopyright

YEAR=2014
COPYRIGHT="Tor Browser $TORBROWSER_VERSION Copyright $YEAR The Tor Project"
read -r -d "" SED_SCRIPT <<END
\#<key>CFBundleGetInfoString</key>#,\#</string>\$#{
  \#</string>\$#s#>.*<#>TorBrowser $TORBROWSER_VERSION<#
}
\#<key>CFBundleShortVersionString</key>#,\#</string>\$#{
  \#</string>\$#s#>.*<#>$TORBROWSER_VERSION<#
  \#</string>\$#a\	<key>NSHumanReadableCopyright</key>\n	<string>$COPYRIGHT</string>
  
}
END

sed -e "$SED_SCRIPT"
