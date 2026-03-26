#!/bin/sh
_project_directory_get_project_directory() {
	git_project_path=$(git rev-parse --show-toplevel 2>/dev/null)
	local _status=$?
	if [ $_status -gt 0 ]; then
		unset git_project_path
		return $_status
	fi
	git_project_name=$(basename $git_project_path)
	return 0
}
_stdin_interactive_alert_if() {
	_stdin_is_interactive_alert_enabled && _interactive_alert "$@"
}
_stdin_is_interactive_alert_enabled() {
	grep -cq '^optn_log_interactive_alert=1$' $APP_CONFIG_PATH 2>/dev/null
}
_stdin_read_ifs() {
	stty -echo
	_stdin_read_if "$@"
	stty echo
}
_stdin_continue_if() {
	unset _proceed
	_stdin_read_if "$1" _proceed "$2"
	if [ -z "$_proceed" ]; then
		_default=$(printf '%s' $2 | awk -F'/' {'print$1'})
		_proceed=$_default
	fi
	printf '%s' "$_proceed" | tr '[:lower:]' '[:upper:]' | $GNU_GREP -Pcqm1 '^Y$'
}
_stdin_read_if() {
	if [ $(set | grep -c "^$2=.*") -eq 1 ]; then
		log_debug "$2 is already set"
		return 1
	fi
	[ -z "$interactive" ] && exit_with_error "running in non-interactive mode and user input was requested: $@" 10
	log_print_log 9 STDI "$conf_log_c_stdin" "$conf_log_beep_stdin" "$1 $3"
	_stdin_interactive_alert_if $1 $3
	read -r $2
}
_git_in_project_base_path() {
	_path_in_path $GIT_PROJECT_BASE_PATH
}
_git_in_user_home() {
	_path_in_path $HOME
}
_git_in_working_directory() {
	git status >/dev/null 2>&1
}
_git_relative_path() {
	git_project_relative_path=$(pwd | sed -e "s|^$HOME/||")
}
_git_relative_path_in_worktree() {
	git_worktree_path=$(git rev-parse --show-toplevel)
	git_relative_path_in_worktree=$(pwd | sed -e "s|^$git_worktree_path/||")
}
file_require() {
	local _filename=$1
	local _message=$2
	validation_require "$_filename" "filename file_require"
	[ -e "$_filename" ] && return
	[ -z "$warn_on_error" ] && exit_with_error "file: $_filename does not exist | $_message"
	log_warn "file: $_filename does not exist | $_message"
	return 1
}
_file_readlink() {
	local _path=$1
	if [ $# -lt 1 ] || [ -z "$_path" ]; then
		return 1
	fi
	if [ "$_path" = "/" ]; then
		printf '%s\n' "$_path"
		return
	fi
	if [ ! -e "$_path" ]; then
		if [ -z $mkdir ] || [ $mkdir -eq 1 ]; then
			mkdir -p "$_path" >/dev/null 2>&1
		fi
	fi
	readlink -f "$_path"
}
_file_has_contents() {
	local _filename=$1
	file_require "$_filename" "_file_has_contents:$_filename"
	[ $(wc -l <"$_filename") -gt 0 ]
}
_path_in_path() {
	local _check_path=$1
	validation_require "$_check_path" _path_in_path
	local test_path=$(readlink -f "$_check_path")
	readlink -f "$PWD" | grep -c "^$test_path" >/dev/null 2>&1
}
_path_in_application_data_path() {
	_path_in_path "$APP_DATA_PATH"
}
_path_in_data_path() {
	_path_in_path "$DATA_PATH"
}
_path_remove_empty_directories() {
	local _directory=$1
	find "$_directory" -type d -empty -exec rm -rf {} +
}
_time_seconds_to_human_readable() {
	local _human_readable_time
	_human_readable_time=$(printf '%02d:%02d:%02d' $(($1 / 3600)) $(($1 % 3600 / 60)) $(($1 % 60)))
}
_time_human_readable_to_seconds() {
	local _time_in_seconds
	case $1 in
	*w)
		_time_in_seconds=${1%%w}
		_time_in_seconds=$(($_time_in_seconds * 3600 * 8 * 5))
		;;
	*d)
		_time_in_seconds=${1%%d}
		_time_in_seconds=$(($_time_in_seconds * 3600 * 8))
		;;
	*h)
		_time_in_seconds=${1%%h}
		_time_in_seconds=$(($_time_in_seconds * 3600))
		;;
	*m)
		_time_in_seconds=${1%%m}
		_time_in_seconds=$(($_time_in_seconds * 60))
		;;
	*s)
		_time_in_seconds=${1%%s}
		;;
	*)
		exit_with_error "$1 was not understood"
		;;
	esac
}
_time_decade() {
	local _year
	local _end_year
	local _event_decade_prefix
	local _event_decade_start
	local _event_decade_end
	_year=$(date +%Y)
	_end_year=$(printf '%s' $_year | head -c 4 | tail -c 1)
	_event_decade_prefix=$(printf '%s' "$_year" | $GNU_GREP -Po "[0-9]{3}")
	if [ "$_end_year" -eq "0" ]; then
		_event_decade_start=${_event_decade_prefix}
		_event_decade_start=$(printf '%s\n' "$_event_decade_start-1" | bc)
		_event_decade_end=${_event_decade_prefix}0
	else
		_event_decade_start=$_event_decade_prefix
		_event_decade_end=$_event_decade_prefix
		_event_decade_end=$(printf '%s\n' "$_event_decade_end+1" | bc)
		_event_decade_end="${_event_decade_end}0"
	fi
	_event_decade_start=${_event_decade_start}1
	printf '%s-%s' "$_event_decade_start" "$_event_decade_end"
}
_time_current_time() {
	date +$conf_log_date_time_format
}
_time_current_time_unix_epoch() {
	date +%s
}
time_timeout() {
	local _timeout=$1
	shift
	local _message=$1
	shift
	local _timeout_units='s'
	if [ $(printf '%s' "$_timeout" | grep -c '[smhd]{1}') -gt 0 ]; then
		unset _timeout_units
	fi
	local _sudo
	[ -n "$sudo_required" ] || [ -n "$sudo_user" ] && _sudo=sudo_run
	$_sudo timeout $options $_timeout "$@" || {
		local _error_status=$?
		local _error_message="Other error"
		if [ $_error_status -eq 124 ]; then
			_error_message="Timed Out"
		fi
		[ $timeout_err_function ] && $timeout_err_function
		local timeout_error_msg="time_timeout: $_error_message: ${_timeout}${_timeout_units} - $_message ($_error_status): $_sudo timeout $options $_timeout $* ($USER)"
		[ $warn_on_error ] && {
			log_warn "$timeout_error_msg"
			return $_error_status
		}
		exit_with_error "$timeout_error_msg"
	}
}
_scan_new() {
  _woke_scan $report_path && return
  cat "$report_path"
  _woke_review
}
_scan_delta() {
  _woke_scan $report_path.new && return
  diff "$report_path.new" "$report_path" && {
    rm $report_path.new
    return
  }
  _woke_review
  mv $report_path.new $report_path
}
_woke_scan() {
  local woke_out_file=$1
  woke -o json | jq -s 'sort_by(.Filename)[]' >"$woke_out_file"
  [ ! -s "$woke_out_file" ] && {
    log_info "woke found no issues"
    rm -f $woke_out_file
    return
  }
  log_warn "woke findings"
  return 1
}
_woke_review() {
  _stdin_continue_if "woke - Do you accept the findings above? (y/n)" || exit_with_error "woke - user aborted"
  log_info "woke - user accepted scan findings"
}
_scan_run woke
