#!/bin/sh
_APPLICATION_NAME=secrets
cd ~/.openssl-store
set -f
find . -type f ! -path '*/.git/*' -name '*.enc' $(printf '%s\n' "$@" | tr ' ' '\n' | sed -e 's/^/-ipath \*/' -e 's/$/\* /' | tr '\n' ' ' | sed -e 's/ $/\n/') |
	sed -e 's/^\.\///' -e 's/\.enc$//' | sort -u
set +f
