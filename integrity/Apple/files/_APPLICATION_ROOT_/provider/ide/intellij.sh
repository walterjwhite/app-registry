#!/bin/sh
set -a
_APPLICATION_NAME=integrity
_beep() {
	say $_OPTN_INSTALL_APPLE_SAY_OPTIONS $_CONF_INSTALL_APPLE_BEEP_MESSAGE
}
_sudo_precmd() {
	say $_OPTN_INSTALL_APPLE_SAY_OPTIONS $_CONF_INSTALL_APPLE_SUDO_PRECMD_MESSAGE
}
_environment_filter() {
	$_CONF_GNU_GREP -P "(^_CONF_|^_OPTN_|^_INSTALL_|^${_TARGET_APPLICATION_NAME}_)"
}
_environment_dump() {
	[ -z "$_APPLICATION_PIPE_DIR" ] && return
	[ -z "$_ENVIRONMENT_FILE" ] && _ENVIRONMENT_FILE=$_APPLICATION_PIPE_DIR/environment
	mkdir -p $(dirname $_ENVIRONMENT_FILE)
	env | _environment_filter | sort -u | grep -v '^$' | sed -e 's/=/="/' -e 's/$/"/' >>$_ENVIRONMENT_FILE
}
_() {
	if [ -n "$_EXEC_ATTEMPTS" ]; then
		local attempt=1
		while [ $attempt -le $_EXEC_ATTEMPTS ]; do
			_WARN_ON_ERROR=1 _do_exec "$@" && return
			attempt=$(($attempt + 1))
		done
		_error "Failed after $attempt attempts: $*"
	fi
	_do_exec "$@"
}
_do_exec() {
	local _successfulExitStatus=0
	if [ -n "$_SUCCESSFUL_EXIT_STATUS" ]; then
		_successfulExitStatus=$_SUCCESSFUL_EXIT_STATUS
		unset _SUCCESSFUL_EXIT_STATUS
	fi
	_info "## $*"
	if [ -z "$_DRY_RUN" ]; then
		if [ -n "$_CMD_LOGFILE" ]; then
			_exec_to_file "$_CMD_LOGFILE" "$@"
		else
			if [ -z "$_LOGFILE" ]; then
				"$@"
			else
				_exec_to_file "$_LOGFILE" "$@"
			fi
		fi
		local _exit_status=$?
		if [ $_exit_status -ne $_successfulExitStatus ]; then
			if [ -n "$_ON_FAILURE" ]; then
				$_ON_FAILURE
				return
			fi
			if [ -z "$_WARN_ON_ERROR" ]; then
				_error "Previous cmd failed: $* - $_exit_status"
			else
				unset _WARN_ON_ERROR
				_warn "Previous cmd failed: $* - $_exit_status"
				_ENVIRONMENT_FILE=$(_mktemp error) _environment_dump
				return $_exit_status
			fi
		fi
	fi
}
_exec_to_file() {
	local logfile=$1
	shift
	mkdir -p $(dirname $logfile)
	type $_function_name >/dev/null 2>&1 || {
		"$@" >>$logfile 2>>$logfile
		return $?
	}
	"$@"
}
_error() {
	if [ $# -ge 2 ]; then
		_EXIT_STATUS=$2
	else
		_EXIT_STATUS=1
	fi
	_EXIT_LOG_LEVEL=4
	_EXIT_STATUS_CODE="ERR"
	_EXIT_COLOR_CODE="$_CONF_LOG_C_ERR"
	_EXIT_MESSAGE="$1 ($_EXIT_STATUS)"
	_EXIT_BEEP=$_CONF_LOG_BEEP_ERR
	_defer _environment_dump
	_defer _log_app_exit
	exit $_EXIT_STATUS
}
_success() {
	_EXIT_STATUS=0
	_EXIT_LOG_LEVEL=1
	_EXIT_STATUS_CODE="SCS"
	_EXIT_COLOR_CODE="$_CONF_LOG_C_SCS"
	_EXIT_MESSAGE="$1"
	_EXIT_BEEP=$_CONF_LOG_BEEP_SCS
	_defer _long_running_cmd
	_defer _log_app_exit
	[ -z "$_EXIT" ] && exit 0
}
_defer() {
	if [ -n "$_DEFERS" ]; then
		local defer
		for defer in $_DEFERS; do
			[ "$defer" = "$1" ] && {
				_debug "not deferring: $1 as it was already deferred"
				return
			}
		done
	fi
	_debug "deferring: $1"
	_DEFERS="$1 $_DEFERS"
}
_log_app_exit() {
	[ "$_EXIT_MESSAGE" ] && {
		local current_time=$(date +%s)
		local timeout=$(($_APPLICATION_START_TIME + $_CONF_LOG_BEEP_TIMEOUT))
		[ $current_time -le $timeout ] && unset _EXIT_BEEP
		_print_log $_EXIT_LOG_LEVEL "$_EXIT_STATUS_CODE" "$_EXIT_COLOR_CODE" "$_EXIT_BEEP" "$_EXIT_MESSAGE"
	}
	_log_app exit
	[ -n "$_LOGFILE" ] && [ -n "$_OPTN_LOG_EXIT_CMD" ] && {
		$_OPTN_LOG_EXIT_CMD -file $_LOGFILE
	}
}
_include() {
	local include_file
	for include_file in "$@"; do
		[ -f $HOME/.config/walterjwhite/$include_file ] && . $HOME/.config/walterjwhite/$include_file
	done
}
_warn() {
	_print_log 3 WRN "$_CONF_LOG_C_WRN" "$_CONF_LOG_BEEP_WRN" "$1"
}
_info() {
	_print_log 2 INF "$_CONF_LOG_C_INFO" "$_CONF_LOG_BEEP_INFO" "$1"
}
_debug() {
	_print_log 1 DBG "$_CONF_LOG_C_DEBUG" "$_CONF_LOG_BEEP_DEBUG" "($$) $1"
}
_log() {
	:
}
_sed_remove_nonprintable_characters() {
	sed -e 's/[^[:print:]]//g'
}
_print_log() {
	if [ -z "$5" ]; then
		if test ! -t 0; then
			local _line
			cat - | _sed_remove_nonprintable_characters |
				while read _line; do
					_print_log $1 $2 $3 $4 "$_line"
				done
			return
		fi
		return
	fi
	local message="$5"
	[ $1 -lt $_CONF_LOG_LEVEL ] && return
	[ -n "$_LOGGING_CONTEXT" ] && message="$_LOGGING_CONTEXT - $message"
	local _message_date_time=$(date +"$_CONF_LOG_DATE_FORMAT")
	if [ $_BACKGROUNDED ] && [ $_OPTN_INSTALL_BACKGROUND_NOTIFICATION_METHOD ]; then
		$_OPTN_INSTALL_BACKGROUND_NOTIFICATION_METHOD "$2" "$_message" &
	fi
	[ -n "$4" ] && _beep "$4"
	_log_to_file "$2" "$_message_date_time" "${_LOG_INDENT}$message"
	_log_to_console "$3" "$2" "$_message_date_time" "${_LOG_INDENT}$message"
	[ -z "$INTERACTIVE" ] && _syslog "$message"
	return 0
}
_log_to_file() {
	[ -z "$_LOGFILE" ] && return
	if [ $_CONF_LOG_AUDIT -gt 0 ]; then
		printf '%s %s %s\n' "$1" "$2" "$3" >>$_LOGFILE
		return
	fi
	printf '%s\n' "$3" >>$_LOGFILE
}
_log_to_console() {
	local stderr=2
	[ ! -t $stderr ] && stderr=4
	[ ! -t $stderr ] && return
	if [ $_CONF_LOG_AUDIT -gt 0 ]; then
		printf >&$stderr '\033[%s%s \033[0m%s %s\n' "$1" "$2" "$3" "$4"
		return
	fi
	printf >&$stderr '\033[%s%s \033[0m\n' "$1" "$4"
}
_log_app() {
	_debug "$_APPLICATION_NAME:$_APPLICATION_CMD - $1 ($$)"
}
_mktemp() {
	local suffix=$1
	[ -n "$suffix" ] && suffix=".$suffix"
	local sudo_prefix
	[ -n "$_SUDO_USER" ] && sudo_prefix=_sudo
	$sudo_prefix mktemp -${_MKTEMP_OPTIONS}t ${_APPLICATION_NAME}.${_APPLICATION_CMD}${suffix}
}
_kill_all() {
	_do_kill_all $_APPLICATION_PIPE_DIR
}
_kill_all_group() {
	_do_kill_all $_APPLICATION_CONTEXT_GROUP
}
_do_kill_all() {
	for _EXISTING_APPLICATION_PIPE in $(find $1 -type p -not -name $$); do
		_kill $(basename $_EXISTING_APPLICATION_PIPE)
	done
}
_kill() {
	_warn "Killing $1"
	kill -TERM $1
}
_list() {
	_list_pid_infos $_APPLICATION_PIPE_DIR
}
_list_group() {
	_list_pid_infos $_APPLICATION_CONTEXT_GROUP
}
_list_pid_infos() {
	_info "Running processes:"
	_EXECUTABLE_NAME_SED_SAFE=$(_sed_safe $0)
	for _EXISTING_APPLICATION_PIPE in $(find $1 -type p -not -name $$); do
		_list_pid_info
	done
}
_parent_processes_pgrep() {
	pgrep -P $1
}
_list_pid_info() {
	_TARGET_PID=$(basename $_EXISTING_APPLICATION_PIPE)
	_TARGET_PS_DTL=$(ps -o command -p $_TARGET_PID | sed 1d | sed -e "s/^.*$_EXECUTABLE_NAME_SED_SAFE/$_EXECUTABLE_NAME_SED_SAFE/")
	_info " $_TARGET_PID - $_TARGET_PS_DTL"
}
_syslog() {
	logger -i -t "$_APPLICATION_NAME.$_APPLICATION_CMD" "$1"
}
_sudo() {
	[ $# -eq 0 ] && _error 'No arguments were provided to _sudo'
	_require "$_SUDO_CMD" _SUDO_CMD
	[ -n "$_SUDO_USER" ] && sudo_options="$sudo_options -u $_SUDO_USER"
	[ "$USER" = "root" ] && [ -z "$sudo_options" ] && {
		"$@"
		return
	}
	if [ -n "$INTERACTIVE" ]; then
		$_SUDO_CMD -n ls >/dev/null 2>&1 || _sudo_precmd "$@"
	fi
	$_SUDO_CMD $sudo_options "$@"
	unset sudo_options
}
_require() {
	local level=error
	if [ -z "$1" ]; then
		[ -n "$_WARN" ] && level=warn
		_$level "$2 required $_REQUIRE_DETAILED_MESSAGE" $3
		return 1
	fi
	unset _REQUIRE_DETAILED_MESSAGE
}
_mail() {
	if [ $# -lt 3 ]; then
		_warn "recipients[0], subject[1], message[2] is required - $# arguments provided"
		return 1
	fi
	local recipients=$(printf '%s' "$1" | tr '|' ' ')
	shift
	local subject="$1"
	shift
	local message="$1"
	shift
	printf "$message" | mail -s "$subject" $recipients
}
_alert() {
	_print_log 5 ALRT "$_CONF_LOG_C_ALRT" "$_CONF_LOG_BEEP_ALRT" "$1"
	local recipients="$_OPTN_LOG_ALERT_RECIPIENTS"
	local subject="Alert: $0 - $1"
	if [ -z "$recipients" ]; then
		_warn "recipients is empty, aborting"
		return 1
	fi
	_mail "$recipients" "$subject" "$2"
}
_long_running_cmd() {
	[ -n "$_OPTN_DISABLE_LONG_RUNNING_CMD_NOTIFICATION" ] && return
	_APPLICATION_END_TIME=$(date +%s)
	_APPLICATION_RUNTIME=$(($_APPLICATION_END_TIME - $_APPLICATION_START_TIME))
	[ $_APPLICATION_RUNTIME -lt $_CONF_LOG_LONG_RUNNING_CMD ] && return
	local subject="[$_APPLICATION_NAME] - $_EXIT_MESSAGE - ($_EXIT_STATUS)"
	local message=""
	if [ -n "$_LOGFILE" ]; then
		message=$(tail -$_CONF_LOG_LONG_RUNNING_CMD_LINES $_LOGFILE)
	fi
	_alert "$subject" "$message"
}
_include beep context integrity logging net paths platform wait
: ${_CONF_LOG_HEADER:="##################################################"}
: ${_CONF_LOG_C_ALRT:="1;31m"}
: ${_CONF_LOG_C_ERR:="1;31m"}
: ${_CONF_LOG_C_SCS:="1;32m"}
: ${_CONF_LOG_C_WRN:="1;33m"}
: ${_CONF_LOG_C_INFO:="1;36m"}
: ${_CONF_LOG_C_DETAIL:="1;0;36m"}
: ${_CONF_LOG_C_DEBUG:="1;35m"}
: ${_CONF_LOG_C_STDIN:="1;34m"}
: ${_CONF_LOG_DATE_FORMAT:="%Y/%m/%d|%H:%M:%S"}
: ${_CONF_LOG_DATE_TIME_FORMAT:="%Y/%m/%d %H:%M:%S"}
: ${_CONF_LOG_AUDIT:=0}
: ${_CONF_LOG_LEVEL:=2}
: ${_CONF_LOG_INDENT:="  "}
: ${_CONF_LOG_CONF_VALIDATION_FUNCTION:=_warn}
: ${_CONF_LOG_WAITER_LEVEL:=_debug}
: ${_CONF_LOG_FEATURE_TIMEOUT_ERROR_LEVEL:=warn}
: ${_CONF_LOG_LONG_RUNNING_CMD:=30}
: ${_CONF_LOG_LONG_RUNNING_CMD_LINES:=1000}
[ -t 0 ] && INTERACTIVE=1
: ${LIB:="beep.sh context.sh environment.sh exec.sh exit.sh help.sh include.sh logging.sh mktemp.sh platform.sh processes.sh stdin.sh syslog.sh sudo.sh wait.sh validation.sh net/mail.sh alert.sh"}
: ${CFG:="logging platform context wait beep paths net"}
: ${SUPPORTED_PLATFORMS:="Apple FreeBSD Linux Windows"}
: ${BUILD_PLATFORMS:="FreeBSD Linux Apple Windows"}
which pgrep >/dev/null 2>&1 && _PARENT_PROCESSES_FUNCTION=_parent_processes_pgrep
_DETECTED_PLATFORM=$(uname)
case $_DETECTED_PLATFORM in
Darwin)
	_DETECTED_PLATFORM=Apple
	;;
MINGW64_NT-*)
	_DETECTED_PLATFORM=Windows
	;;
esac
: ${_CONF_INSTALL_CONTEXT:=$_CONSOLE_CONTEXT_ID}
: ${_CONF_INSTALL_CONTEXT:=default}
: ${_CONF_WAIT_INTERVAL:=30}
: ${RSRC_BEEP:=/tmp/beep}
: ${_CONF_LOG_BEEP_TIMEOUT:=5}
: ${_CONF_LOG_BEEP_ERR:=''}
: ${_CONF_LOG_BEEP_ALRT:=''}
: ${_CONF_LOG_BEEP_SCS:=''}
: ${_CONF_LOG_BEEP_WRN:=''}
: ${_CONF_LOG_BEEP_INFO:=''}
: ${_CONF_LOG_BEEP_DETAIL:=''}
: ${_CONF_LOG_BEEP_DEBUG:=''}
: ${_CONF_LOG_BEEP_STDIN:=''}
: ${_CONF_LOG_SUDO_BEEP_TONE:=''}
[ "$HOME" = "/" ] && HOME=/root
: ${_CONF_LIBRARY_PATH:=/usr/local/walterjwhite}
: ${_CONF_BIN_PATH:=/usr/local/bin}
_CONF_DATA_PATH=$HOME/.data
_CONF_CACHE_PATH=$_CONF_DATA_PATH/.cache
_CONF_CONFIG_PATH=$HOME/.config/walterjwhite
_CONF_RUN_PATH=/tmp/$USER/walterjwhite/app
_CONF_DATA_ARTIFACTS_PATH=$_CONF_DATA_PATH/install-v2/artifacts
_CONF_DATA_REGISTRY_PATH=$_CONF_DATA_PATH/install-v2/registry
_CONF_APPLICATION_DATA_PATH=$_CONF_DATA_PATH/$_APPLICATION_NAME
_CONF_APPLICATION_CONFIG_PATH=$_CONF_CONFIG_PATH/$_APPLICATION_NAME
_CONF_APPLICATION_LIBRARY_PATH=$_CONF_LIBRARY_PATH/$_APPLICATION_NAME
: ${_CONF_NETWORK_TEST_TIMEOUT:=5}
: ${_CONF_NETWORK_TEST_TARGETS:="http://connectivity-check.ubuntu.com http://example.org http://www.google.com http://telehack.com http://lxer.com"}
_EXTENSION_PATHS="~/Library/Application Support/JetBrains ~/Library/Caches/JetBrains"
_EXTENSION_OPTIONS="-ipath '*/Intellij*/*'"
