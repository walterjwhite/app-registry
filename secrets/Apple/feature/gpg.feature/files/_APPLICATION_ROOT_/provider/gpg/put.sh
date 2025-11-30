#!/bin/sh
_APPLICATION_NAME=secrets
_SECRETS_GPG_PATH=$_CONF_APPLICATION_DATA_PATH/gpg
_SECRETS_GPG_PATH_SED_SAFE=$(_sed_safe $_SECRETS_GPG_PATH)
mkdir -p $_SECRETS_GPG_PATH
cd $_SECRETS_GPG_PATH
[ ! -e .git ] && {
	git init
	_WARN 'Add a remote to sync secrets'
}
_sed_safe() {
	printf '%s' $1 | sed -e "s/\//\\\\\//g"
}
[ "$_CONF_SECRETS_OVERWRITE_EXISTING" ] && [ -e $1.gpg ] && rm -f $1.gpg
mkdir -p $(dirname $1)
_PLAINTEXT=$(_mktemp)
printf '%s\n' "$_SECRET_VALUE" >>$_PLAINTEXT
gpg --output $1.gpg --encrypt --recipient $_FEATURE_GPG_USER_EMAIL $_PLAINTEXT
rm -f $_PLAINTEXT
unset _PLAINTEXT
git add $1.gpg
git commit $1.gpg -m "$1"
git push
