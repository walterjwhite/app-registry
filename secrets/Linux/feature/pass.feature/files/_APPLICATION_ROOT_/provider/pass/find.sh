#!/bin/sh
_APPLICATION_NAME=secrets
cd ~/.password-store
_GREP_KEYWORDS=$(printf '%s' "$*" | tr ' ' '|')
set -f
find . -type f ! -path '*/.git/*' -name '*.gpg' $(printf '%s\n' "$@" | tr ' ' '\n' | sed -e 's/^/-ipath \*/' -e 's/$/\* /' | tr '\n' ' ' | sed -e 's/ $/\n/') |
	sed -e 's/^\.\///' -e 's/\.gpg$//' | sort -u | $_CONF_GNU_GREP -P --color "($_GREP_KEYWORDS)"
set +f
