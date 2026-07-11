#!/bin/sh
_APPLICATION_NAME=secrets
_SECRETS_GET_STDOUT() {
	pass show $_PASS_OPTIONS $_SECRET_KEY
}
_SECRETS_GET_FIND() {
	[ $# -eq 0 ] && return 1
	local matched=$(. $_CONF_APPLICATION_LIBRARY_PATH/provider/$_CONF_SECRETS_PROVIDER/find.sh)
	local matches=$(printf '%s\n' $matched | wc -l)
	[ -z "$matched" ] && _ERROR "No secrets found matching: $*"
	[ $matches -ne 1 ] && _ERROR "Expecting exactly 1 secret to match, instead found: $matches"
	_SECRET_KEY=$matched
}
_SECRETS_GET_CLIPBOARD() {
	_PASS_OPTIONS=--clip _SECRETS_GET_STDOUT "$@"
}
