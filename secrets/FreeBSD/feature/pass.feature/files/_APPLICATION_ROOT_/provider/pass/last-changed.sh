#!/bin/sh
set -a
_APPLICATION_NAME=secrets
_secrets_pass_last_changed() {
  printf '%75s %s\n' "$1" $(git log --format=%as --max-count=1 $_PASS_OPTIONS $1.gpg)
}
cd ~/.password-store
for _SECRET_KEY in $(secrets find "$@"); do
  _secrets_pass_last_changed $_SECRET_KEY
done | sort -k2
