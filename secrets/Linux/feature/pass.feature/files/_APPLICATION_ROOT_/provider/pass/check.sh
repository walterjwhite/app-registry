#!/bin/sh
_APPLICATION_NAME=secrets
cd ~/.password-store
find ~/.password-store -type f ! -path '*/.git/*' -name '*.gpg' |
	sort -u |
	sed -e "s/$_SECRETS_PASS_PATH_SED_SAFE\///" -e 's/\.gpg$//' |
	xargs -L1 -P$_CONF_SECRETS_CHECK_PARALLELIZATION_COUNT _secrets_check
