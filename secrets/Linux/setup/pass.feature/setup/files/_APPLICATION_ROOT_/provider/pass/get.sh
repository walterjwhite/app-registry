#!/bin/sh
secrets_get_find() {
  [ $# -eq 0 ] && return 1
  local matched=$(. /usr/local/walterjwhite/secrets/provider/$conf_secrets_provider/find.sh)
  local matches=$(printf '%s\n' $matched | wc -l)
  [ -z "$matched" ] && exit_with_error "no secrets found matching: $*"
  case $secrets_output_function in
  wifi)
    secret_key=$1
    ;;
  *)
    [ $matches -ne 1 ] && exit_with_error "expecting exactly 1 secret to match, instead found: $matches"
    secret_key=$matched
    ;;
  esac
}
secrets_get_stdout() {
  case $secret_key in
    */otp)
      log_detail "fetching OTP"
      pass otp $secret_key
      ;;
    *)
      pass show $secret_key
      ;;
  esac
}
secrets_get_clipboard() {
  case $secret_key in
    */otp)
      log_detail "fetching OTP"
      pass otp -c $secret_key
      ;;
    *)
      pass show --clip $secret_key
      ;;
  esac
}
secrets_get "$@"
