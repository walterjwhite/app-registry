#!/bin/sh
set -a
_APPLICATION_NAME=console
_beep() {
	[ -n "$SSH_CLIENT" ] && {
		warn "remote connection detected, not beeping"
		return 1
	}
	say $_OPTN_INSTALL_APPLE_SAY_OPTIONS $_CONF_INSTALL_APPLE_BEEP_MESSAGE
}
_sudo_precmd() {
	[ -n "$SSH_CLIENT" ] && {
		warn "remote connection detected, not beeping"
		return 1
	}
	say $_OPTN_INSTALL_APPLE_SAY_OPTIONS $_CONF_INSTALL_APPLE_SUDO_PRECMD_MESSAGE
}
_context_id_is_valid() {
	printf '%s' "$1" | $_CONF_GNU_GREP -Pq '^[a-zA-Z0-9_+-]+$' || error "Context ID *MUST* only contain alphanumeric characters and +-: '^[a-zA-Z0-9_+-]+$' | ($1)"
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
_call() {
	local _function_name=$1
	type $_function_name >/dev/null 2>&1 || {
		debug "${_function_name} does not exist"
		return 255
	}
	[ $# -gt 1 ] && {
		shift
		$_function_name "$@"
		return $?
	}
	$_function_name
}
_() {
	if [ -n "$_EXEC_ATTEMPTS" ]; then
		local attempt=1
		while [ $attempt -le $_EXEC_ATTEMPTS ]; do
			_WARN_ON_ERROR=1 _do_exec "$@" && return
			attempt=$(($attempt + 1))
		done
		error "Failed after $attempt attempts: $*"
	fi
	_do_exec "$@"
}
_do_exec() {
	local _successfulExitStatus=0
	if [ -n "$_SUCCESSFUL_EXIT_STATUS" ]; then
		_successfulExitStatus=$_SUCCESSFUL_EXIT_STATUS
		unset _SUCCESSFUL_EXIT_STATUS
	fi
	info "## $*"
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
				error "Previous cmd failed: $* - $_exit_status"
			else
				unset _WARN_ON_ERROR
				warn "Previous cmd failed: $* - $_exit_status"
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
error() {
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
				debug "not deferring: $1 as it was already deferred"
				return
			}
		done
	fi
	debug "deferring: $1"
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
warn() {
	_print_log 3 WRN "$_CONF_LOG_C_WRN" "$_CONF_LOG_BEEP_WRN" "$1"
}
info() {
	_print_log 2 INF "$_CONF_LOG_C_INFO" "$_CONF_LOG_BEEP_INFO" "$1"
}
detail() {
	_print_log 2 DTL "$_CONF_LOG_C_DETAIL" "$_CONF_LOG_BEEP_DETAIL" "$1"
}
debug() {
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
	debug "$_APPLICATION_NAME:$_APPLICATION_CMD - $1 ($$)"
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
	warn "Killing $1"
	kill -TERM $1
}
_list() {
	_list_pidinfos $_APPLICATION_PIPE_DIR
}
_list_group() {
	_list_pidinfos $_APPLICATION_CONTEXT_GROUP
}
_list_pidinfos() {
	info "Running processes:"
	_EXECUTABLE_NAME_SED_SAFE=$(_sed_safe $0)
	for _EXISTING_APPLICATION_PIPE in $(find $1 -type p -not -name $$); do
		_list_pidinfo
	done
}
_parent_processes_pgrep() {
	pgrep -P $1
}
_list_pidinfo() {
	_TARGET_PID=$(basename $_EXISTING_APPLICATION_PIPE)
	_TARGET_PS_DTL=$(ps -o command -p $_TARGET_PID | sed 1d | sed -e "s/^.*$_EXECUTABLE_NAME_SED_SAFE/$_EXECUTABLE_NAME_SED_SAFE/")
	info " $_TARGET_PID - $_TARGET_PS_DTL"
}
_interactive_alert_if() {
	_is_interactive_alert_enabled && _interactive_alert "$@"
}
_is_interactive_alert_enabled() {
	grep -cq '^_OPTN_INSTALL_INTERACTIVE_ALERT=1$' $_CONF_APPLICATION_CONFIG_PATH 2>/dev/null
}
_syslog() {
	logger -i -t "$_APPLICATION_NAME.$_APPLICATION_CMD" "$1"
}
_sudo() {
	[ $# -eq 0 ] && error 'No arguments were provided to _sudo'
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
		$level "$2 required $_REQUIRE_DETAILED_MESSAGE" $3
		return 1
	fi
	unset _REQUIRE_DETAILED_MESSAGE
}
_mail() {
	if [ $# -lt 3 ]; then
		warn "recipients[0], subject[1], message[2] is required - $# arguments provided"
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
		warn "recipients is empty, aborting"
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
_console_context() {
	info "Refreshing console context"
	if [ ! -e $_CONF_APPLICATION_DATA_PATH/active ]; then
		warn "Using default context"
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
		info "previous pull logs"
		cat $_CONSOLE_PULL_OUT
	}
	rm -f $_CONSOLE_PULL_OUT
}
_console_pull() {
	cd $_CONSOLE_CONTEXT_DIRECTORY
	git pull >$_CONSOLE_PULL_OUT 2>&1
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
		detail "initializing git @ $_PROJECT_PATH"
		_timeout $_CONF_GIT_CLONE_TIMEOUT _git_init git clone "$_CONF_GIT_MIRROR/$_PROJECT" $_PROJECT_PATH || {
			[ -z "$_WARN" ] && error "Unable to initialize project"
			warn "Initialized empty project"
			git init $_PROJECT_PATH
		}
	fi
	cd $_PROJECT_PATH
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
		$timeout_level "_timeout: $error_message: ${timeout}${timeout_units} - $message ($error_status): $sudo timeout $_OPTIONS $timeout $* ($USER)"
		return $error_status
	}
}
_require_file() {
	_require "$1" filename _require_file
	local level=error
	[ -n "$_WARN" ] && level=warn
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
_sed_safe() {
	printf '%s' $1 | sed -e "s/\//\\\\\//g"
}
_include beep console context logging net paths platform wait
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
: ${_CONF_LOG_CONF_VALIDATION_FUNCTION:=warn}
: ${_CONF_LOG_WAITER_LEVEL:=debug}
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
_include . context defaults feature:. git logging paths
: ${_CONF_CONSOLE_AUDIT_COLOR:=34}
: ${_CONF_CONSOLE_SCRIPT_TIMEOUT:=5}
: ${_CONF_CONSOLE_CONTEXT_TIMEOUT:=300}
_PLATFORM="Apple"
_TAR_ARGS=" -f - "
_SUDO_CMD="sudo"
_ARCHITECTURE=$(uname -m)
: ${_CONF_GNU_SED:=/opt/homebrew/bin/gsed}
: ${_CONF_GNU_GREP:=/opt/homebrew/opt/grep/libexec/gnubin/grep}
_PLATFORM_PACKAGES="git coreutils gnu-sed grep expect mas-cli/tap/mas"
_NPM_PACKAGE="node"
_RUST_PACKAGE="rust"
_PYPI_PACKAGE="python"
_GO_PACKAGE="go"
: ${_CONF_INSTALL_APPLE_BEEP_MESSAGE:=beep}
: ${_CONF_INSTALL_APPLE_SUDO_PRECMD_MESSAGE:=Please enter your sudo credentials}
: ${_CONF_INSTALL_HOMEBREW_CMD:=/opt/homebrew/bin/brew}
_CONF_INSTALL_STAT_ARGUMENTS='-f %OLp'
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
_current_time_epoch() {
  date +%s
}
_save_console_history() {
  if [ ! -e $HISTFILE ]; then
    return 1
  fi
  if [ $(wc -l <$HISTFILE) -eq 0 ]; then
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
