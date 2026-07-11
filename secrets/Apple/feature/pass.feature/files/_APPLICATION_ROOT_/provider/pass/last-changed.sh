#!/bin/sh
_APPLICATION_NAME=secrets
_SECRETS_LAST_CHANGED() {
	printf '%75s %s\n' "$1" $(git log --format=%as --max-count=1 $_PASS_OPTIONS $1.gpg)
}
cd ~/.password-store
for _SECRET_KEY in $(secrets find "$@"); do
	_SECRETS_LAST_CHANGED $_SECRET_KEY
done | sort -k2
