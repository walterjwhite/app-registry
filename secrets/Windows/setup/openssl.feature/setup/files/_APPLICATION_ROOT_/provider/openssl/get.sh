#!/bin/sh
cd ~/.openssl-store
secrets_get_stdout() {
  openssl enc -d -aes-256-cbc -salt -pbkdf2 -in $secret_key.enc -out /dev/stdout -kfile $conf_secrets_openssl_key
}
secrets_get_find() {
  [ $# -eq 0 ] && return 1
  local matched=$(. /usr/local/walterjwhite/secrets/provider/$conf_secrets_provider/find.sh)
  local matches=$(printf '%s\n' $matched | wc -l)
  [ -z "$matched" ] && exit_with_error "no secrets found matching: $*"
  [ $matches -ne 1 ] && exit_with_error "expecting exactly 1 secret to match, instead found: $matches"
  local secret_key=$matched
}
secrets_get_clipboard() {
  secrets_get_stdout "$@" | _clipboard_put
}
secrets_get "$@"
