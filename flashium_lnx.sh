#!@bash@/bin/bash

# USAGE: flashium_lndir.sh PATH_FROM_CHROMIUM
export PATH=''
trg="$(echo "$1" | '@gnused@/bin/sed' -e "s#@newchrom@#$out#" -e 's#chromium#flashium#')"
if [ "$1" == "$trg" ]; then
  echo "skip $*"
  exit 0
fi
echo "$1 -> $trg"
@coreutils@/bin/mkdir -p "$(@coreutils@/bin/dirname "$trg")"
@coreutils@/bin/ln -s "$1" "$trg"
