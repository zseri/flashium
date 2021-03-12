#!@bash@/bin/bash

# USAGE: flashium_lndir.sh PATH_FROM_CHROMIUM
export PATH='@coreutils@/bin'
src="$(realpath "$1")"
trg="$out/$(echo "$1" | @gnused@/bin/sed -e 's#chromium#flashium#' -e "s#^\.#$PWD#" -e 's#@newchrom@/##')"
echo "$1 -> $src -> $trg"
mkdir -p "$(dirname "$trg")"
ln -s "$src" "$trg"
