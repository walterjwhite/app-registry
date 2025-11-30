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
_SECRETS_GPG_GET() {
	[ -z "$_SECRET_KEY_PATH" ] && {
		case $_SECRET_KEY in
		*.gpg)
			_SECRET_KEY_PATH=$_SECRET_KEY
			;;
		*)
			_SECRET_KEY_PATH=$_SECRET_KEY.gpg
			;;
		esac
	}
	gpg -d $_SECRET_KEY_PATH 2>/dev/null
}
_SECRETS_GET_STDOUT() {
	_SECRETS_GPG_GET
}
_SECRETS_GET_FIND() {
	[ $# -eq 0 ] && return 1
	local matched=$(. $_CONF_APPLICATION_LIBRARY_PATH/provider/$_CONF_SECRETS_PROVIDER/find.sh)
	local matches=$(printf '%s\n' $matched | wc -l)
	[ -z "$matched" ] && _ERROR "No secrets found matching: $*"
	[ $matches -ne 1 ] && _ERROR "Expecting exactly 1 secret to match, instead found: $matches"
	_SECRET_KEY_PATH=$matched
}
_SECRETS_GET_CLIPBOARD() {
	_SECRETS_GPG_GET | _clipboard_put
}
