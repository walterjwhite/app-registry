#!/bin/sh
set -a
_APPLICATION_NAME=secrets
_secrets_get_stdout() {
  pass show $_PASS_OPTIONS $_SECRET_KEY
}
_secrets_get_find() {
  [ $# -eq 0 ] && return 1
  local matched=$(. $_CONF_APPLICATION_LIBRARY_PATH/provider/$_CONF_SECRETS_PROVIDER/find.sh)
  local matches=$(printf '%s\n' $matched | wc -l)
  [ -z "$matched" ] && _error "No secrets found matching: $*"
  [ $matches -ne 1 ] && _error "Expecting exactly 1 secret to match, instead found: $matches"
  _SECRET_KEY=$matched
}
_secrets_get_clipboard() {
  _PASS_OPTIONS=--clip _secrets_get_stdout "$@"
}
