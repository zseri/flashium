#!@bash@/bin/bash

# USAGE: flashium_lndir.sh PATH_FROM_CHROMIUM
export PATH='@coreutils@/bin'
src="$(realpath "$1")"
trg="$(echo "$1" | @gnused@/bin/sed -e 's#chromium#flashium#')"
echo "trgi[0]: $trg"
trg="$(echo "$trg" | @gnused@/bin/sed -e "s#^\.#$PWD#")"
echo "trgi[1]: $trg"
trg="$(echo "$trg" | @gnused@/bin/sed -e 's#@newchrom@/##')"
echo "trgi[2]: $trg"
trg="$out/$trg"
echo "$1 -> $src -> $trg"
mkdir -p "$(dirname "$trg")"
ln -s "$src" "$trg"
