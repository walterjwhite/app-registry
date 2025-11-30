#!/bin/sh
_APPLICATION_NAME=console
_context_id_is_valid() {
	printf '%s' "$1" | $_CONF_GNU_GREP -Pq '^[a-zA-Z0-9_+-]+$' || _ERROR "Context ID *MUST* only contain alphanumeric characters and +-: '^[a-zA-Z0-9_+-]+$' | ($1)"
}
_call() {
	local function_name=$1
	type $function_name >/dev/null 2>&1 || {
		_DEBUG "${function_name} does not exist"
		return 255
	}
	[ $# -gt 1 ] && {
		shift
		$function_name "$@"
		return $?
	}
	$function_name
}
_() {
	_reset_indent
	if [ -n "$_EXEC_ATTEMPTS" ]; then
		local attempt=1
		while [ $attempt -le $_EXEC_ATTEMPTS ]; do
			_WARN_ON_ERROR=1 _do_exec "$@" && return
			attempt=$(($attempt + 1))
		done
		_ERROR "Failed after $attempt attempts: $*"
	fi
	_do_exec "$@"
}
_do_exec() {
	local successful_exit_status=0
	if [ -n "$_SUCCESSFUL_EXIT_STATUS" ]; then
		successful_exit_status=$_SUCCESSFUL_EXIT_STATUS
		unset _SUCCESSFUL_EXIT_STATUS
	fi
	_INFO "## $*"
	local exit_status
	if [ -z "$_DRY_RUN" ]; then
		"$@"
		exit_status=$?
	else
		_WARN "using dry run status: $_DRY_RUN"
		exit_status=$_DRY_RUN
	fi
	if [ $exit_status -ne $successful_exit_status ]; then
		if [ -n "$_ON_FAILURE" ]; then
			$_ON_FAILURE
			return
		fi
		if [ -z "$_WARN_ON_ERROR" ]; then
			_ERROR "Previous cmd failed: $* - $exit_status"
		else
			unset _WARN_ON_ERROR
			_WARN "Previous cmd failed: $* - $exit_status"
			_ENVIRONMENT_FILE=$(_mktemp error) _environment_dump
			return $exit_status
		fi
	fi
}
_ERROR() {
	if [ $# -ge 2 ]; then
		_EXIT_STATUS=$2
	else
		_EXIT_STATUS=1
	fi
	_EXIT_LOG_LEVEL=4
	_EXIT_STATUS_CODE="ERR"
	_EXIT_COLOR_CODE="$_CONF_LOG_C_ERR"
	_EXIT_MESSAGE="$1 ($_EXIT_STATUS)"
	_EXIT_BEEP="$_CONF_LOG_BEEP_ERR"
	_defer _environment_dump
	_defer _log_app_exit
	_run_defers
	exit $_EXIT_STATUS
}
_defer() {
	if [ -n "$_DEFERS" ]; then
		local defer
		for defer in $_DEFERS; do
			[ "$defer" = "$1" ] && {
				_DEBUG "not deferring: $1 as it was already deferred"
				return
			}
		done
	fi
	_DEBUG "deferring: $1"
	_DEFERS="$1 $_DEFERS"
}
_run_defers() {
	[ -z "$_DEFERS" ] && return 1
	local defer
	for defer in $_DEFERS; do
		_call $defer
	done
	unset _DEFERS
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
_console_context() {
	_INFO "Refreshing console context"
	if [ ! -e $_CONF_APPLICATION_DATA_PATH/active ]; then
		_WARN "Using default context"
		_CONSOLE_CONTEXT_ID=default
		_CONSOLE_CONTEXT_DESCRIPTION=default
		_console_context_write
	fi
	_console_read_context
	_console_pull_is_running || {
		_console_pull_print_output
		_console_pull &
		CONSOLE_PULL_PID=$?
	}
}
_console_read_context() {
	_CONSOLE_CONTEXT_EXPIRATION=$(($_CURRENT_TIME + $_CONF_CONSOLE_CONTEXT_TIMEOUT))
	_CONSOLE_CONTEXT_DIRECTORY=$_CONF_APPLICATION_DATA_PATH/active
	_CONSOLE_CONTEXT_FILE=$_CONSOLE_CONTEXT_DIRECTORY/context
	_CONSOLE_CONTEXT_ID=$(head -1 $_CONSOLE_CONTEXT_FILE)
	_context_id_is_valid "$_CONSOLE_CONTEXT_ID"
	_CONSOLE_CONTEXT_DESCRIPTION=$(sed -n 2p $_CONSOLE_CONTEXT_FILE)
	export _CONSOLE_CONTEXT_ID _CONSOLE_CONTEXT_DESCRIPTION
	local index=0
	while read _LINE; do
		if [ $index -gt 1 ]; then
			if [ -n "$_LINE" ]; then
				export $_LINE
			fi
		fi
		index=$(($index + 1))
	done <$_CONSOLE_CONTEXT_FILE
}
_console_is_refresh_context() {
	[ -z "$_CONSOLE_CONTEXT_EXPIRATION" ] && return 0
	[ $_CONSOLE_CONTEXT_EXPIRATION -lt $_CURRENT_TIME ] && return 0
	local _read_id=$(basename $(readlink $_CONF_APPLICATION_DATA_PATH/active))
	[ "$_read_id" != "$_CONSOLE_CONTEXT_ID" ] && return 0
	return 1
}
_console_context_write() {
	local opwd=$PWD
	cd $_CONF_APPLICATION_DATA_PATH
	git pull
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
_console_pull_is_running() {
	[ -z "$CONSOLE_PULL_PID" ] && return 1
	ps -p $_CONSOLE_PULL_PID >/dev/null 2>&1 && return 0
	unset CONSOLE_PULL_PID
	return 1
}
_console_pull_print_output() {
	[ -z "$_CONSOLE_PULL_OUT" ] && _CONSOLE_PULL_OUT=$(_mktemp)
	[ ! -e $_CONSOLE_PULL_OUT ] && return 1
	[ $(wc -l <$_CONSOLE_PULL_OUT) -gt 0 ] && {
		_INFO "previous pull logs"
		cat $_CONSOLE_PULL_OUT
	}
	rm -f $_CONSOLE_PULL_OUT
}
_console_pull() {
	cd $_CONSOLE_CONTEXT_DIRECTORY
	git pull >$_CONSOLE_PULL_OUT 2>&1
}
_after() {
	local -i cmd_status=$?
	[ -z "$_CURRENT_TIME" ] && return
	local now=$(_current_time_epoch)
	local cmd_runtime=$(($now - $_CURRENT_TIME))
	if [ $cmd_runtime -gt 0 ]; then
		_console_log 'After ' " - ${cmd_runtime}s"
	else
		_console_log 'After '
	fi
	if [ $now -gt $_TIMEOUT ]; then
		local cmd_status_description=completed
		[ $cmd_status -gt 0 ] && cmd_status_description=failed
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
_set_histfile() {
	HISTFILE_PATH=$(_hostname)/activity
	HISTFILE_REL_PATH=$_CONSOLE_CONTEXT_ID/$HISTFILE_PATH
	HISTFILE=$_CONSOLE_CONTEXT_DIRECTORY/$HISTFILE_PATH/$(date +%Y/%m/%d)
	mkdir -p $(dirname $HISTFILE)
}
_current_time_epoch() {
	date +%s
}
_save_console_history() {
	[ ! -e $HISTFILE ] && return 1
	[ $(wc -l <$HISTFILE) -eq 0 ] && return 2
	local opwd=$PWD
	cd $_PROJECT_PATH
	_console_data_has_changes && _git_save "$(date +'%Y/%m/%d %H:%M:%S')" $HISTFILE_REL_PATH
	cd $opwd
}
_console_data_has_changes() {
	[ $(git status --porcelain 2>/dev/null | wc -l) -gt 0 ]
}
_console_date() {
	date +"$_CONF_LOG_DATE_FORMAT"
}
_console_log() {
	local message="$1"
	[ "$_CONSOLE_CONTEXT_ID" ] && message="[$_CONSOLE_CONTEXT_ID] $message"
	printf '\e[1;3;%sm### %s - %s ###\e[0m\n' "$_CONF_CONSOLE_AUDIT_COLOR" "$message" "$(_console_date)$2"
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
		_DETAIL "initializing git @ $_PROJECT_PATH"
		_timeout $_CONF_GIT_CLONE_TIMEOUT _git_init git clone "$_CONF_GIT_MIRROR/$_PROJECT" $_PROJECT_PATH || {
			[ -z "$_WARN_ON_ERROR" ] && _ERROR "Unable to initialize project"
			_WARN "Initialized empty project"
			git init $_PROJECT_PATH
		}
	fi
	cd $_PROJECT_PATH
}
_include() {
	local include_file
	for include_file in "$@"; do
		[ -f $HOME/.config/walterjwhite/shell/$include_file ] && . $HOME/.config/walterjwhite/shell/$include_file
	done
}
_WARN() {
	_print_log 3 WRN "$_CONF_LOG_C_WRN" "$_CONF_LOG_BEEP_WRN" "$1"
}
_INFO() {
	_print_log 2 INF "$_CONF_LOG_C_INFO" "$_CONF_LOG_BEEP_INFO" "$1"
}
_DETAIL() {
	_print_log 2 DTL "$_CONF_LOG_C_DETAIL" "$_CONF_LOG_BEEP_DETAIL" "$1"
}
_DEBUG() {
	_print_log 1 DBG "$_CONF_LOG_C_DEBUG" "$_CONF_LOG_BEEP_DEBUG" "($$) $1"
}
_sed_remove_nonprintable_characters() {
	sed -e 's/[^[:print:]]//g'
}
_print_log() {
	if [ -z "$5" ]; then
		if test ! -t 0; then
			local log_line
			cat - | _sed_remove_nonprintable_characters |
				while read log_line; do
					_print_log $1 $2 $3 $4 "$log_line"
				done
			return
		fi
		return
	fi
	local message="$5"
	[ $1 -lt $_CONF_LOG_LEVEL ] && return
	[ -n "$_LOGGING_CONTEXT" ] && message="$_LOGGING_CONTEXT - $message"
	if [ $_BACKGROUNDED ] && [ $_OPTN_INSTALL_BACKGROUND_NOTIFICATION_METHOD ]; then
		$_OPTN_INSTALL_BACKGROUND_NOTIFICATION_METHOD "$2" "$_message" &
	fi
	[ -n "$4" ] && _beep "$4"
	_log_to_file "$2" "${_LOG_INDENT}$message"
	_log_to_console "$3" "${_LOG_INDENT}$message"
	[ -z "$INTERACTIVE" ] && _syslog "$message"
	return 0
}
_reset_indent() {
	unset _LOG_INDENT
}
_log_to_file() {
	[ -z "$_LOGFILE" ] && return
	printf '%s\n' "$2" >>$_LOGFILE
}
_log_to_console() {
	[ -z "$_CONF_LOG_CONSOLE" ] && return
	printf >&$_CONF_LOG_CONSOLE '\033[%s%s \033[0m\n' "$1" "$2"
}
_log_app() {
	_DEBUG "$_APPLICATION_NAME:$_APPLICATION_CMD - $1 ($$)"
}
_mktemp() {
	local suffix=$1
	[ -n "$suffix" ] && suffix=".$suffix"
	local sudo_prefix
	[ -n "$_SUDO_USER" ] && sudo_prefix=_sudo
	$sudo_prefix mktemp -${_MKTEMP_OPTIONS}t ${_APPLICATION_NAME}.${_APPLICATION_CMD}${suffix}.XXXXXXXX
}
_hostname() {
	hostname
}
_interactive_alert_if() {
	_is_interactive_alert_enabled && _interactive_alert "$@"
}
_is_interactive_alert_enabled() {
	grep -cq '^_OPTN_LOG_INTERACTIVE_ALERT=1$' $_CONF_APPLICATION_CONFIG_PATH 2>/dev/null
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
	local timeout_level=_ERROR
	[ $_WARN ] && timeout_level=_WARN
	local sudo
	[ -n "$_SUDO_REQUIRED" ] || [ -n "$_SUDO_USER" ] && sudo=_sudo
	$sudo timeout $_OPTIONS $timeout "$@" || {
		local error_status=$?
		local error_message="Other error"
		if [ $error_status -eq 124 ]; then
			error_message="Timed Out"
		fi
		[ $_TIMEOUT_ERR_FUNCTION ] && $_TIMEOUT_ERR_FUNCTION
		$timeout_level "_timeout: $error_message: ${timeout}${timeout_units} - $message ($error_status): $sudo timeout $_OPTIONS $timeout $* ($USER)"
		return $error_status
	}
}
_require_file() {
	_require "$1" filename _require_file
	local level=_ERROR
	[ -n "$_WARN_ON_ERROR" ] && level=_WARN
	if [ ! -e $1 ]; then
		$level "File: $1 does not exist | $2"
		return 1
	fi
}
_in_path() {
	_require "$1" _in_path
	local test_path=$(readlink -f $1)
	readlink -f $PWD | grep -c "^$test_path" >/dev/null 2>&1
}
_include context git logging paths platform
: ${_CONF_CONSOLE_AUDIT_COLOR:=34}
: ${_CONF_CONSOLE_SCRIPT_TIMEOUT:=5}
: ${_CONF_CONSOLE_CONTEXT_TIMEOUT:=300}
: ${_CONF_INSTALL_CONTEXT:=$_CONSOLE_CONTEXT_ID}
: ${_CONF_INSTALL_CONTEXT:=default}
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
: ${_CONF_LOG_LEVEL:=2}
: ${_CONF_LOG_INDENT:="  "}
: ${_CONF_LOG_CONF_VALIDATION_FUNCTION:=warn}
: ${_CONF_LOG_WAITER_LEVEL:=debug}
: ${_CONF_LOG_FEATURE_TIMEOUT_ERROR_LEVEL:=warn}
: ${_CONF_LOG_LONG_RUNNING_CMD:=30}
: ${_CONF_LOG_LONG_RUNNING_CMD_LINES:=1000}
[ -t 0 ] && INTERACTIVE=1
: ${_CONF_LOG_CONSOLE:=2}
[ "$HOME" = "/" ] && HOME=/root
: ${_CONF_LIBRARY_PATH:=/usr/local/walterjwhite}
: ${_CONF_BIN_PATH:=/usr/local/bin}
_CONF_DATA_PATH=$HOME/.data
_CONF_CACHE_PATH=$HOME/.cache
_CONF_CONFIG_PATH=$HOME/.config/walterjwhite/shell
_CONF_RUN_PATH=/tmp/$USER/walterjwhite/app
_CONF_DATA_ARTIFACTS_PATH=$_CONF_DATA_PATH/install-v2/artifacts
_CONF_DATA_REGISTRY_PATH=$_CONF_DATA_PATH/install-v2/registry
_CONF_APPLICATION_DATA_PATH=$_CONF_DATA_PATH/$_APPLICATION_NAME
_CONF_APPLICATION_CONFIG_PATH=$_CONF_CONFIG_PATH/$_APPLICATION_NAME
_CONF_APPLICATION_LIBRARY_PATH=$_CONF_LIBRARY_PATH/$_APPLICATION_NAME
: ${LIB:="beep.sh context.sh environment.sh exec.sh exit.sh help.sh include.sh logging.sh mktemp.sh platform.sh processes.sh stdin.sh syslog.sh sudo.sh time.sh wait.sh validation.sh net/mail.sh alert.sh"}
: ${CFG:="logging platform context wait beep paths net"}
: ${SUPPORTED_PLATFORMS:="Apple FreeBSD Linux Windows"}
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
_PLATFORM="Linux"
: ${_CONF_GNU_GREP:=grep}
: ${_CONF_GNU_SED:=sed}
_ARCHITECTURE=$(uname -m)
[ -z "$INTERACTIVE" ] && exit
_APPLICATION_NAME=console
_PROJECT_PATH=$_CONF_DATA_PATH/$_APPLICATION_NAME
_WARN=1 _git_init
cd $OLDPWD
HISTSIZE=$_CONF_CONSOLE_ZSH_HISTORY_SIZE
SAVEHIST=$_CONF_CONSOLE_ZSH_HISTORY_SIZE
_console_context
_set_histfile
autoload -U add-zsh-hook
add-zsh-hook precmd _after
add-zsh-hook preexec _before
add-zsh-hook zshexit _save_console_history
