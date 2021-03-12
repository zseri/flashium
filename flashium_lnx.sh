#!@bash@/bin/bash

# USAGE: flashium_lndir.sh PATH_FROM_CHROMIUM
export PATH=''
src="$(@coreutils@/bin/realpath "$1")"
trg="$(echo "$src" | '@gnused@/bin/sed' -e "s#@newchrom@#$out#" -e 's#chromium#flashium#')"
echo "$src -> $trg"
@coreutils@/bin/mkdir -p "$(@coreutils@/bin/dirname "$trg")"
@coreutils@/bin/ln -s "$src" "$trg"
