#!/bin/sh
#!/bin/sh
assert_empty() {
	if [ -n "$1" ]; then
		_test_failure "assert_empty: '$1' is not empty" "$3"
		return 1
	fi
	_test_passed "assert_empty: '$1' is empty" "$3"
}
assert_equal() {
	if [ "$1" != "$2" ]; then
		_test_failure "assert_equal: '$1' != '$2'" "$3"
		return 1
	fi
	_test_passed "assert_equal: '$1' == '$2'" "$3"
}
assert_not_equal() {
	if [ "$1" = "$2" ]; then
		_test_failure "assert_not_equal: '$1' == '$2'" "$3"
		return 1
	fi
	_test_passed "assert_not_equal: '$1' != '$2'" "$3"
}
assert_success() {
	if ! "$@"; then
		_test_failure "assert_success: $*" "$3"
		return 1
	fi
	_test_passed "assert_success: $*" "$3"
}
assert_failure() {
	if "$@"; then
		_test_failure "assert_failure: $*" "$3"
		return 1
	fi
	_test_passed "assert_failure: $*" "$3"
}
assert_file_exists() {
	if [ ! -f "$1" ]; then
		_test_failure "assert_file_exists: '$1' does not exist" "$2"
		return 1
	fi
	_test_passed "assert_file_exists: '$1' exists" "$2"
}
assert_file_is_empty() {
	[ -s "$1" ] && {
		_test_failure "assert_file_is_empty: '$1' is not empty" "$2"
		return 1
	}
	_test_passed "assert_file_is_empty: '$1' is empty" "$2"
}
assert_file_contains() {
	local file="$1"
	local expected="$2"
	if grep -qF "$expected" "$file"; then
		_test_passed "assert_file_contains: '$file' contains '$expected'"
		return 0
	fi
	_test_failure "assert_file_contains: '$1' does not contain '$expected'"
	return 1
}
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
if [ $# -eq 0 ]; then
  _run_tests
else
  _load_libraries $(dirname "$1")
  for test_file_arg in "$@"; do
    _run_test_file "$test_file_arg"
  done
fi
