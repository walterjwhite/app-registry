#!/bin/sh
_APPLICATION_NAME=secrets
cd ~/.password-store
set -f
find . -type f ! -path '*/.git/*' -name '*.gpg' $(printf '%s\n' "$@" | tr ' ' '\n' | sed -e 's/^/-ipath \*/' -e 's/$/\* /' | tr '\n' ' ' | sed -e 's/ $/\n/') |
	sed -e 's/^\.\///' -e 's/\.gpg$//' | sort -u
set +f
