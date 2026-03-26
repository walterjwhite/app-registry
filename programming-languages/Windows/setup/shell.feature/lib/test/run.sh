#!/bin/sh
_run_tests() {
  local test_count=0
  local pass_count=0
  local fail_count=0
  log_add_context "_run_tests"
  _load_libraries .
  log_info "running tests"
  for test_file in ./*_test.sh; do
    if [ -f "$test_file" ]; then
      test_count=$((test_count + 1))
      if _run_test_file "$test_file"; then
        pass_count=$((pass_count + 1))
      else
        fail_count=$((fail_count + 1))
      fi
    fi
  done
  log_detail "test summary ==="
  log_detail "total: $test_count, passed: $pass_count, failed: $fail_count"
  log_remove_context
  [ "$fail_count" -eq 0 ]
}
_load_libraries() {
  log_info "loading libraries"
  for library_file in $(find "$1" -name "*.sh" -not -name "*_test.sh"); do
    . "$library_file"
  done
}
_run_test_file() {
  local test_file="$1"
  local test_name
  test_name=$(basename "$test_file" .sh)
  log_add_context $test_name
  log_info "running"
  (
    TEST_TEMP_FILE=$(_mktemp_mktemp)
    trap 'rm -f "$TEST_TEMP_FILE"' EXIT
    . "$test_file"
    exec_call setup
    for TEST_FUNCTION in $(grep -E '^test_[a-zA-Z0-9_]+ *\(' "$test_file" | cut -d'(' -f1); do
      if [ "$(type "$TEST_FUNCTION" 2>/dev/null | head -1)" = "$TEST_FUNCTION is a function" ]; then
        log_add_context $TEST_FUNCTION
        log_detail "running"
        local test_function_passed_asserts=0
        local test_function_failed_asserts=0
        if (
          $TEST_FUNCTION
          [ $test_function_failed_asserts -eq 0 ] && TEST_FUNCTION_STATUS=passed || TEST_FUNCTION_STATUS=failed
          log_detail "test $TEST_FUNCTION_STATUS | passed: $test_function_passed_asserts | failed: $test_function_failed_asserts"
          printf '\n\n'
          return $test_function_failed_asserts
        ); then
          :
        else
          :
        fi
        log_remove_context
        _reset_test_logs
      fi
    done
    exec_call _teardown
  )
  log_remove_context
}
