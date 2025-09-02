#!/bin/sh
set -a
_APPLICATION_NAME=secrets
_SECRETS_GPG_PATH=$_CONF_APPLICATION_DATA_PATH/gpg
_SECRETS_GPG_PATH_SED_SAFE=$(_sed_safe $_SECRETS_GPG_PATH)
mkdir -p $_SECRETS_GPG_PATH
cd $_SECRETS_GPG_PATH
[ ! -e .git ] && {
	git init
	_warn 'Add a remote to sync secrets'
}
_sed_safe() {
	printf '%s' $1 | sed -e "s/\//\\\\\//g"
}
_secrets_gpg_get() {
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
_secrets_get_stdout() {
  _secrets_gpg_get
}
_secrets_get_find() {
  [ $# -eq 0 ] && return 1
  local matched=$(. $_CONF_APPLICATION_LIBRARY_PATH/provider/$_CONF_SECRETS_PROVIDER/find.sh)
  local matches=$(printf '%s\n' $matched | wc -l)
  [ -z "$matched" ] && _error "No secrets found matching: $*"
  [ $matches -ne 1 ] && _error "Expecting exactly 1 secret to match, instead found: $matches"
  _SECRET_KEY_PATH=$matched
}
_secrets_get_clipboard() {
  _secrets_gpg_get | _clipboard_put
}
