#!@bash@/bin/bash

# USAGE: flashium_lndir.sh PATH_FROM_CHROMIUM
export PATH='@coreutils@/bin'
src="$(realpath --relative-base="@newchrom@" "$1")"
trg="$(echo "$src" | @gnused@/bin/sed -e 's#chromium#flashium#')"
[ "${trg:0:1}" == / ] || trg="$(realpath "$out/$trg" )"
echo "$src -> $trg"
mkdir -p "$out/$(dirname "$trg")"
ln -s "$src" "$out/$trg"
