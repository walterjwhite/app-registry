#!/bin/sh
_SECRETS_GET_STDOUT() {
  pass show $_PASS_OPTIONS $_SECRET_KEY
}
_SECRETS_GET_FIND() {
  [ $# -eq 0 ] && return 1
  local matched=$(. /usr/local/walterjwhite/secrets/provider/$_CONF_SECRETS_PROVIDER/find.sh)
  local matches=$(printf '%s\n' $matched | wc -l)
  [ -z "$matched" ] && _ERROR "No secrets found matching: $*"
  case $_SECRETS_OUTPUT_FUNCTION in
  wifi)
    _SECRET_KEY=$1
    ;;
  *)
    [ $matches -ne 1 ] && _ERROR "Expecting exactly 1 secret to match, instead found: $matches"
    _SECRET_KEY=$matched
    ;;
  esac
}
_SECRETS_GET_CLIPBOARD() {
  _PASS_OPTIONS=--clip _SECRETS_GET_STDOUT "$@"
}
