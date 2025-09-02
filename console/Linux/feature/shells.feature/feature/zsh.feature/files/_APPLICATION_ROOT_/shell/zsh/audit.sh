#!/bin/sh
set -a
_APPLICATION_NAME=console
_console_context() {
	_info "Refreshing console context"
	if [ ! -e $_CONF_APPLICATION_DATA_PATH/active ]; then
		_warn "Using default context"
		_CONSOLE_CONTEXT_ID=default
		_CONSOLE_CONTEXT_DESCRIPTION=default
		_console_context_write
	fi
	_console_read_context
}
_console_read_context() {
	_CONSOLE_CONTEXT_EXPIRATION=$(($_CURRENT_TIME + $_CONF_CONSOLE_CONTEXT_TIMEOUT))
	_CONSOLE_CONTEXT_DIRECTORY=$_CONF_APPLICATION_DATA_PATH/active
	_CONSOLE_CONTEXT_FILE=$_CONSOLE_CONTEXT_DIRECTORY/context
	_CONSOLE_CONTEXT_ID=$(head -1 $_CONSOLE_CONTEXT_FILE)
	_context_id_is_valid "$_CONSOLE_CONTEXT_ID"
	_CONSOLE_CONTEXT_DESCRIPTION=$(sed -n 2p $_CONSOLE_CONTEXT_FILE)
	export _CONSOLE_CONTEXT_ID _CONSOLE_CONTEXT_DESCRIPTION
	local i=0
	while read _LINE; do
		if [ $i -gt 1 ]; then
			if [ -n "$_LINE" ]; then
				export $_LINE
			fi
		fi
		i=$(($i + 1))
	done <$_CONSOLE_CONTEXT_FILE
}
_console_is_refresh_context() {
	if [ -z "$_CONSOLE_CONTEXT_EXPIRATION" ]; then
		return 0
	fi
	if [ $_CONSOLE_CONTEXT_EXPIRATION -lt $_CURRENT_TIME ]; then
		return 0
	fi
	local _read_id=$(basename $(readlink $_CONF_APPLICATION_DATA_PATH/active))
	if [ "$_read_id" != "$_CONSOLE_CONTEXT_ID" ]; then
		return 0
	fi
	return 1
}
_console_context_write() {
	local opwd=$PWD
	cd $_CONF_APPLICATION_DATA_PATH
	mkdir -p $_CONSOLE_CONTEXT_ID
	local is_new=0
	if [ ! -e $_CONSOLE_CONTEXT_ID/context ]; then
		printf '%s\n' "$_CONSOLE_CONTEXT_ID" >$_CONSOLE_CONTEXT_ID/context
		is_new=1
	fi
	if [ -n "$_CONSOLE_CONTEXT_DESCRIPTION" ]; then
		if [ $is_new -eq 1 ]; then
			printf '%s\n' "$_CONSOLE_CONTEXT_DESCRIPTION" >>$_CONSOLE_CONTEXT_ID/context
		else
			$_CONF_GNU_SED -i '2d' $_CONSOLE_CONTEXT_ID/context
			$_CONF_GNU_SED -i "1a $_CONSOLE_CONTEXT_DESCRIPTION" $_CONSOLE_CONTEXT_ID/context
		fi
	fi
	if [ $# -gt 0 ]; then
		for _ARG in "$@"; do
			printf '%s\n' "$_ARG" >>$_CONSOLE_CONTEXT_ID/context
		done
	fi
	rm -f active
	ln -s $_CONSOLE_CONTEXT_ID active
	git add active $_CONSOLE_CONTEXT_ID
	git commit -am "set-context - $_CONSOLE_CONTEXT_ID"
	git push
	cd $opwd
}
_context_id_is_valid() {
	printf '%s' "$1" | $_CONF_GNU_GREP -Pq '^[a-zA-Z0-9_+-]+$' || _error "Context ID *MUST* only contain alphanumeric characters and +-: '^[a-zA-Z0-9_+-]+$' | ($1)"
}
_call() {
	local _function_name=$1
	shift
	type $_function_name >/dev/null 2>&1 || {
		_debug "${_function_name} does not exist"
		return 255
	}
	$_function_name "$@"
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
_on_exit() {
	[ $_EXIT ] && return 1
	_EXIT=0
	[ -z "$_EXIT_STATUS" ] && _success "completed successfully"
	if [ -n "$_DEFERS" ]; then
		local defer
		for defer in $_DEFERS; do
			_call $defer
		done
		unset _DEFERS
	fi
	return $_EXIT
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
_git_save() {
	local _message="$1"
	shift
	if [ -n "$_PROJECT_PATH" ]; then
		cd $_PROJECT_PATH
	fi
	git add $@ 2>/dev/null
	git commit $@ -m "$_message"
	_has_remotes=$(git remote | wc -l)
	if [ "$_has_remotes" -gt "0" ]; then
		git push
	fi
}
_git_init() {
	local project_identifier=$_APPLICATION_NAME
	[ -n "$1" ] && project_identifier=$1
	_PROJECT_PATH=$_CONF_DATA_PATH/$project_identifier
	_SYSTEM=$(head -1 /usr/local/etc/walterjwhite/system 2>/dev/null)
	if [ -n "$_SYSTEM" ]; then
		_PROJECT=data/$_SYSTEM/$USER/$project_identifier
	else
		_PROJECT=data-$project_identifier
	fi
	if [ ! -e $_PROJECT_PATH/.git ]; then
		_detail "initializing git @ $_PROJECT_PATH"
		_timeout $_CONF_GIT_CLONE_TIMEOUT _git_init git clone "$_CONF_GIT_MIRROR/$_PROJECT" $_PROJECT_PATH || {
			[ -z "$_WARN" ] && _error "Unable to initialize project"
			_warn "Initialized empty project"
			git init $_PROJECT_PATH
		}
	fi
	cd $_PROJECT_PATH
}
_include() {
	local include_file
	for include_file in "$@"; do
		[ -f $HOME/.config/walterjwhite/$include_file ] && . $HOME/.config/walterjwhite/$include_file
	done
}
_init_logging() {
	[ -n "$_LOGFILE" ] && _set_logfile "$_LOGFILE"
	case $_CONF_LOG_LOG_LEVEL in
	0)
		local logfile=$(_mktemp debug)
		_warn "Writing debug contents to: $logfile"
		_set_logfile "$logfile"
		set -x
		;;
	esac
}
_set_logfile() {
	[ -z "$1" ] && return 1
	_LOGFILE=$1
	mkdir -p $(dirname $1)
	_reset_indent
	[ -n "$_CHILD_LOG" ] || exec 3>&1 4>&2
	exec >>$_LOGFILE 2>&1
	[ -z "$_PRESERVE_LOG" ] && [ -z "$_CHILD_LOG" ] && truncate -s 0 $1 >/dev/null 2>&1
}
_reset_logging() {
	[ !-t 3 ] && return
	[ -n "$_CHILD_LOG" ] && return
	exec 1>&3
	exec 2>&4
	exec 3>&-
	exec 4>&-
}
_warn() {
	_print_log 3 WRN "$_CONF_LOG_C_WRN" "$_CONF_LOG_BEEP_WRN" "$1"
}
_info() {
	_print_log 2 INF "$_CONF_LOG_C_INFO" "$_CONF_LOG_BEEP_INFO" "$1"
}
_detail() {
	_print_log 2 DTL "$_CONF_LOG_C_DETAIL" "$_CONF_LOG_BEEP_DETAIL" "$1"
}
_debug() {
	_print_log 1 DBG "$_CONF_LOG_C_DEBUG" "$_CONF_LOG_BEEP_DEBUG" "($$) $1"
}
_log() {
	:
}
_colorize_text() {
	printf '\033[%s%s\033[0m' "$1" "$2"
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
	[ $1 -lt $_CONF_LOG_LOG_LEVEL ] && return
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
_add_logging_context() {
	[ -z "$1" ] && return 1
	if [ -z "$_LOGGING_CONTEXT" ]; then
		_LOGGING_CONTEXT="$1"
		return
	fi
	_LOGGING_CONTEXT="$_LOGGING_CONTEXT.$1"
}
_remove_logging_context() {
	[ -z "$_LOGGING_CONTEXT" ] && return 1
	case $_LOGGING_CONTEXT in
	*.*)
		_LOGGING_CONTEXT=$(printf '%s' "$_LOGGING_CONTEXT" | sed 's/\.[a-z0-9 _-]*$//')
		;;
	*)
		unset _LOGGING_CONTEXT
		;;
	esac
}
_increase_indent() {
	_LOG_INDENT="$_LOG_INDENT${_CONF_LOG_INDENT}"
}
_decrease_indent() {
	_LOG_INDENT=$(printf '%s' "$_LOG_INDENT" | sed -e "s/${_CONF_LOG_INDENT}$//")
	[ ${#_LOG_INDENT} -eq 0 ] && _reset_indent
}
_reset_indent() {
	unset _LOG_INDENT
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
_interactive_alert_if() {
	_is_interactive_alert_enabled && _interactive_alert "$@"
}
_is_interactive_alert_enabled() {
	grep -cq '^_OPTN_INSTALL_INTERACTIVE_ALERT=1$' $_CONF_APPLICATION_CONFIG_PATH 2>/dev/null
}
_read_ifs() {
	stty -echo
	_read_if "$@"
	stty echo
}
_continue_if() {
	_read_if "$1" _PROCEED "$2"
	local proceed="$_PROCEED"
	unset _PROCEED
	if [ -z "$proceed" ]; then
		_DEFAULT=$(printf '%s' $2 | awk -F'/' {'print$1'})
		proceed=$_DEFAULT
	fi
	local proceed=$(printf '%s' "$proceed" | tr '[:lower:]' '[:upper:]')
	if [ $proceed = "N" ]; then
		return 1
	fi
	return 0
}
_read_if() {
	if [ $(env | grep -c "^$2=.*") -eq 1 ]; then
		_debug "$2 is already set"
		return 1
	fi
	[ -z "$INTERACTIVE" ] && _error "Running in non-interactive mode and user input was requested: $@" 10
	_print_log 9 STDI "$_CONF_LOG_C_STDIN" "$_CONF_LOG_BEEP_STDIN" "$1 $3"
	_interactive_alert_if $1 $3
	read -r $2
}
_git_in_project_base_path() {
	_in_path $_PROJECT_BASE_PATH
}
_git_in_user_home() {
	_in_path $HOME
}
_git_in_working_directory() {
	git status >/dev/null 2>&1
}
_git_relative_path() {
	_HOME_SED_SAFE=$(_sed_safe $(_readlink $HOME))
	_PROJECT_RELATIVE_PATH=$(pwd | sed -e "s/$_HOME_SED_SAFE\///")
}
_time_seconds_to_human_readable() {
	_HUMAN_READABLE_TIME=$(printf '%02d:%02d:%02d' $(($1 / 3600)) $(($1 % 3600 / 60)) $(($1 % 60)))
}
_time_human_readable_to_seconds() {
	case $1 in
	*w)
		_TIME_IN_SECONDS=${1%%w}
		_TIME_IN_SECONDS=$(($_TIME_IN_SECONDS * 3600 * 8 * 5))
		;;
	*d)
		_TIME_IN_SECONDS=${1%%d}
		_TIME_IN_SECONDS=$(($_TIME_IN_SECONDS * 3600 * 8))
		;;
	*h)
		_TIME_IN_SECONDS=${1%%h}
		_TIME_IN_SECONDS=$(($_TIME_IN_SECONDS * 3600))
		;;
	*m)
		_TIME_IN_SECONDS=${1%%m}
		_TIME_IN_SECONDS=$(($_TIME_IN_SECONDS * 60))
		;;
	*s)
		_TIME_IN_SECONDS=${1%%s}
		;;
	*)
		_error "$1 was not understood"
		;;
	esac
}
_time_decade() {
	local year=$(date +%Y)
	local _end_year=$(printf '%s' $year | head -c 4 | tail -c 1)
	local _event_decade_prefix=$(printf '%s' "$year" | $_CONF_GNU_GREP -Po "[0-9]{3}")
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
_current_time() {
	date +$_CONF_LOG_DATE_TIME_FORMAT
}
_current_time_unix_epoch() {
	date +%s
}
_timeout() {
	local timeout=$1
	shift
	local message=$1
	shift
	local timeout_units='s'
	if [ $(printf '%s' "$timeout" | grep -c '[smhd]{1}') -gt 0 ]; then
		unset timeout_units
	fi
	local timeout_level=error
	[ $_WARN ] && timeout_level=warn
	local sudo
	[ -n "$_SUDO_REQUIRED" ] || [ -n "$_SUDO_USER" ] && sudo=_sudo
	$sudo timeout $_OPTIONS $timeout "$@" || {
		local error_status=$?
		local error_message="Other error"
		if [ $error_status -eq 124 ]; then
			error_message="Timed Out"
		fi
		[ $_TIMEOUT_ERR_FUNCTION ] && $_TIMEOUT_ERR_FUNCTION
		_$timeout_level "_timeout: $error_message: ${timeout}${timeout_units} - $message ($error_status): $sudo timeout $_OPTIONS $timeout $* ($USER)"
		return $error_status
	}
}
_require_file() {
	_require "$1" filename _require_file
	local level=error
	[ -n "$_WARN" ] && level=warn
	if [ ! -e $1 ]; then
		_$level "File: $1 does not exist | $2"
		return 1
	fi
}
_readlink() {
	if [ $# -lt 1 ] || [ -z "$1" ]; then
		return 1
	fi
	if [ "$1" = "/" ]; then
		printf '%s\n' "$1"
		return
	fi
	if [ ! -e $1 ]; then
		if [ -z $_MKDIR ] || [ $_MKDIR -eq 1 ]; then
			_sudo mkdir -p $1 >/dev/null 2>&1
		fi
	fi
	readlink -f $1
}
_has_contents() {
	_require_file "$1" "_has_contents:$1"
	[ $(_sudo wc -l $1 | awk {'print$1'}) -gt 0 ] && return 0
	return 1
}
_in_path() {
	_require "$1" _in_path
	local test_path=$(readlink -f $1)
	readlink -f $PWD | grep -c "^$test_path" >/dev/null 2>&1
}
_in_application_data_path() {
	_in_path $_CONF_APPLICATION_DATA_PATH
}
_in_data_path() {
	_in_path $_CONF_DATA_PATH
}
_remove_empty_directories() {
	find $1 -type d -empty -exec rm -rf {} +
}
_sed_safe() {
	printf '%s' $1 | sed -e "s/\//\\\\\//g"
}
_time_seconds_to_human_readable() {
	_HUMAN_READABLE_TIME=$(printf '%02d:%02d:%02d' $(($1 / 3600)) $(($1 % 3600 / 60)) $(($1 % 60)))
}
_time_human_readable_to_seconds() {
	case $1 in
	*w)
		_TIME_IN_SECONDS=${1%%w}
		_TIME_IN_SECONDS=$(($_TIME_IN_SECONDS * 3600 * 8 * 5))
		;;
	*d)
		_TIME_IN_SECONDS=${1%%d}
		_TIME_IN_SECONDS=$(($_TIME_IN_SECONDS * 3600 * 8))
		;;
	*h)
		_TIME_IN_SECONDS=${1%%h}
		_TIME_IN_SECONDS=$(($_TIME_IN_SECONDS * 3600))
		;;
	*m)
		_TIME_IN_SECONDS=${1%%m}
		_TIME_IN_SECONDS=$(($_TIME_IN_SECONDS * 60))
		;;
	*s)
		_TIME_IN_SECONDS=${1%%s}
		;;
	*)
		_error "$1 was not understood"
		;;
	esac
}
_time_decade() {
	local year=$(date +%Y)
	local _end_year=$(printf '%s' $year | head -c 4 | tail -c 1)
	local _event_decade_prefix=$(printf '%s' "$year" | $_CONF_GNU_GREP -Po "[0-9]{3}")
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
_current_time() {
	date +$_CONF_LOG_DATE_TIME_FORMAT
}
_current_time_unix_epoch() {
	date +%s
}
_timeout() {
	local timeout=$1
	shift
	local message=$1
	shift
	local timeout_units='s'
	if [ $(printf '%s' "$timeout" | grep -c '[smhd]{1}') -gt 0 ]; then
		unset timeout_units
	fi
	local timeout_level=error
	[ $_WARN ] && timeout_level=warn
	local sudo
	[ -n "$_SUDO_REQUIRED" ] || [ -n "$_SUDO_USER" ] && sudo=_sudo
	$sudo timeout $_OPTIONS $timeout "$@" || {
		local error_status=$?
		local error_message="Other error"
		if [ $error_status -eq 124 ]; then
			error_message="Timed Out"
		fi
		[ $_TIMEOUT_ERR_FUNCTION ] && $_TIMEOUT_ERR_FUNCTION
		_$timeout_level "_timeout: $error_message: ${timeout}${timeout_units} - $message ($error_status): $sudo timeout $_OPTIONS $timeout $* ($USER)"
		return $error_status
	}
}
_include .
_include context
_include defaults
_include feature:.
_include git
_include logging
_include paths
: ${_CONF_CONSOLE_AUDIT_COLOR:=34}
: ${_CONF_CONSOLE_SCRIPT_TIMEOUT:=5}
: ${_CONF_CONSOLE_CONTEXT_TIMEOUT:=300}
: ${_CONF_INSTALL_CONTEXT:=$_CONSOLE_CONTEXT_ID}
: ${_CONF_INSTALL_CONTEXT:=default}
_PLATFORM="Linux"
: ${_CONF_GNU_GREP:=grep}
: ${_CONF_GNU_SED:=sed}
_ARCHITECTURE=$(uname -m)
_SUDO_CMD="sudo"
_PLATFORM_PACKAGES="git expect curl shfmt"
_NPM_PACKAGE="node"
_RUST_PACKAGE="rust"
_PYPI_PACKAGE="python"
_GO_PACKAGE="go"
: ${_CONF_LOG_SUDO_BEEP_TONE:=L32aL8fL32c}
: ${_CONF_INSTALL_STAT_ARGUMENTS:='-f %OLp'}
: ${_CONF_CONSOLE_ZSH_HISTORY_SIZE:=1000}
: ${_CONF_GIT_SYSTEM_TEMPLATE_PATH:=/usr/share/git/templates}
: ${_CONF_GIT_CLONE_TIMEOUT:=30}
: ${_CONF_GIT_COMPRESSION_FORMAT:=xz}
: ${_CONF_GIT_COMPRESSION_CMD:="xz -z"}
: ${_CONF_GIT_SQUASH_COMMITS:=2}
: ${_CONF_GIT_BACKUP_DATE_TIME_FORMAT:=%Y.%m.%d-%H.%M.%S}
: ${_CONF_GIT_DELETE_PERIOD_IN_DAYS:=365}
: ${_CONF_GIT_DELETE_DRYRUN:=0}
_PROJECT_BASE_PATH=$HOME/projects
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
: ${_CONF_LOG_LOG_LEVEL:=2}
: ${_CONF_LOG_INDENT:="  "}
: ${_CONF_LOG_CONF_VALIDATION_FUNCTION:=_warn}
: ${_CONF_LOG_WAITER_LEVEL:=_debug}
: ${_CONF_LOG_FEATURE_TIMEOUT_ERROR_LEVEL:=warn}
: ${_CONF_LOG_LONG_RUNNING_CMD:=30}
: ${_CONF_LOG_LONG_RUNNING_CMD_LINES:=1000}
[ -t 0 ] && INTERACTIVE=1
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
_current_time_epoch() {
  date +%s
}
_save_console_history() {
  if [ ! -e $HISTFILE ]; then
    return 1
  fi
  if [ $(wc -l $HISTFILE | awk {'print$1'}) -eq 0 ]; then
    return 2
  fi
  local opwd=$PWD
  cd $_PROJECT_PATH
  _console_data_has_changes && _git_save "$(date +'%Y/%m/%d %H:%M:%S')" $_CONSOLE_CONTEXT_ID/activity
  cd $opwd
}
_console_data_has_changes() {
  if [ $(git status --porcelain 2>/dev/null | wc -l) -gt 0 ]; then
    return 0
  fi
  return 1
}
_console_date() {
  date +"$_CONF_LOG_DATE_FORMAT"
}
_console_log() {
  local message="$1"
  [ "$_CONSOLE_CONTEXT_ID" ] && message="[$_CONSOLE_CONTEXT_ID] $message"
  printf '\e[1;3;%sm### %s - %s ###\e[0m\n' "$_CONF_CONSOLE_AUDIT_COLOR" "$message" "$(_console_date)"
}
_after() {
  local -i cmd_status=$?
  [ -z "$_CURRENT_TIME" ] && return
  _console_log 'After '
  local now=$(_current_time_epoch)
  if [ $now -gt $_TIMEOUT ]; then
    local cmd_status_description=completed
    if [ $cmd_status -gt 0 ]; then
      cmd_status_description=failed
    fi
    cmd_status=$cmd_status _interactive_alert_if "$_COMMAND $cmd_status_description"
  fi
  unset _CURRENT_TIME
}
_before() {
  _CURRENT_TIME=$(_current_time_epoch)
  _COMMAND=$1
  _TIMEOUT=$(($_CURRENT_TIME + $_CONF_CONSOLE_SCRIPT_TIMEOUT))
  _console_is_refresh_context $1 && _console_context
  _console_log Before
}
[ -z "$INTERACTIVE" ] && exit
_PROJECT_PATH=$_CONF_DATA_PATH/$_APPLICATION_NAME
_WARN=1 _git_init
cd $OLDPWD
HISTSIZE=$_CONF_CONSOLE_ZSH_HISTORY_SIZE
SAVEHIST=$_CONF_CONSOLE_ZSH_HISTORY_SIZE
_defer _save_console_history
trap _on_exit EXIT
_console_context
HISTFILE=$_CONSOLE_CONTEXT_DIRECTORY/activity/$(date +%Y/%m/%d)
mkdir -p $(dirname $HISTFILE)
autoload -U add-zsh-hook
add-zsh-hook precmd _after
add-zsh-hook preexec _before
add-zsh-hook zshexit _save_console_history
