#!/bin/sh
_test_failure() {
  test_function_failed_asserts=$(($test_function_failed_asserts + 1))
  log_logfile="" _print_log 2 FLL "$conf_log_c_ERR" "$conf_log_beep_WRN" "$1 $2"
  cat "$TEST_TEMP_FILE" >&2
  printf '\n\n' >&2
}
_test_passed() {
  test_function_passed_asserts=$(($test_function_passed_asserts + 1))
  log_logfile="" _print_log 2 PSS "$conf_log_c_scs" "$conf_log_beep_scs" "$1 $2"
}
call_test_function() {
  _setup_test_logging
  "$@"
  local test_function_status=$?
  _stop_test_logging
  return $test_function_status
}
_setup_test_logging() {
  truncate -s 0 "$TEST_TEMP_FILE"
  exec 3>&1
  exec 4>&2
  exec >"$TEST_TEMP_FILE"
  exec 2>&1
  TEST_LOGGING_SETUP=1
}
_stop_test_logging() {
  [ -z "$TEST_LOGGING_SETUP" ] && return 0
  unset log_logfile
  exec 1>&3
  exec 2>&4
  exec 3>&-
  exec 4>&-
  unset TEST_LOGGING_SETUP
}
_reset_test_logs() {
  truncate -s 0 "$TEST_TEMP_FILE"
}
