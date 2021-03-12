#!@bash@/bin/bash

# USAGE: flashium_lndir.sh PATH_FROM_CHROMIUM
export PATH='@coreutils@/bin'
src="$(realpath "$1")"
trg="$(echo "$1" | @gnused@/bin/sed -e "s#^\.#$PWD#" -e 's#@newchrom@/##' -e 's#chromium#flashium#')"
[ "${trg:0:1}" == / ] || trg="$(realpath "$out/$trg" )"
echo "$src -> $trg"
mkdir -p "$out/$(dirname "$trg")"
ln -s "$src" "$out/$trg"
