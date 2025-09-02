#!/bin/sh
set -a
_APPLICATION_NAME=secrets
cd ~/.openssl-store
_secrets_get_stdout() {
  openssl enc -d -aes-256-cbc -salt -pbkdf2 -in $_SECRET_KEY.enc -out /dev/stdout -kfile $_CONF_SECRETS_OPENSSL_KEY
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
  _secrets_get_stdout "$@" | _clipboard_put
}
