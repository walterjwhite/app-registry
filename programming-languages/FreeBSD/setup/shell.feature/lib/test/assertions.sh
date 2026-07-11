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
