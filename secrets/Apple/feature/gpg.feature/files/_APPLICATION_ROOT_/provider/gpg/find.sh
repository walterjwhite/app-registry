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
for _SEARCH_ARG in "$@"; do
	case $_SEARCH_ARG in
	*/*)
		_ERROR "Search arguments cannot contain '/': $_SEARCH_ARG"
		;;
	esac
	if [ -z "$_AWK_PATTERN" ]; then
		_AWK_PATTERN="/$_SEARCH_ARG/"
	else
		_AWK_PATTERN="$_AWK_PATTERN && /$_SEARCH_ARG/"
	fi
done
if [ -z "$_AWK_PATTERN" ]; then
	_AWK_PATTERN="//"
fi
[ ! -e $_SECRETS_GPG_PATH ] && _ERROR 'No secrets exist'
find $_SECRETS_GPG_PATH -type f ! -path '*/.git/*' -name '*.gpg' |
	awk "$_AWK_PATTERN" | sort -u
