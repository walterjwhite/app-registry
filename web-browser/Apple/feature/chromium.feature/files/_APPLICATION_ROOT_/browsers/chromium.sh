#!/bin/sh
set -a
_APPLICATION_NAME=web-browser
_beep() {
	[ -n "$SSH_CLIENT" ] && {
		_WARN "remote connection detected, not beeping"
		return 1
	}
	say $_OPTN_INSTALL_APPLE_SAY_OPTIONS $_CONF_INSTALL_APPLE_BEEP_MESSAGE
}
_sudo_precmd() {
	[ -n "$SSH_CLIENT" ] && {
		_WARN "remote connection detected, not beeping"
		return 1
	}
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
	local _successfulExitStatus=0
	if [ -n "$_SUCCESSFUL_EXIT_STATUS" ]; then
		_successfulExitStatus=$_SUCCESSFUL_EXIT_STATUS
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
	if [ $exit_status -ne $_successfulExitStatus ]; then
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
	$sudo_prefix mktemp -${_MKTEMP_OPTIONS}t ${_APPLICATION_NAME}.${_APPLICATION_CMD}${suffix}
}
_parent_processes_pgrep() {
	pgrep -P $1
}
_interactive_alert_if() {
	_is_interactive_alert_enabled && _interactive_alert "$@"
}
_is_interactive_alert_enabled() {
	grep -cq '^_OPTN_LOG_INTERACTIVE_ALERT=1$' $_CONF_APPLICATION_CONFIG_PATH 2>/dev/null
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
		_DEBUG "$2 is already set"
		return 1
	fi
	[ -z "$INTERACTIVE" ] && _ERROR "Running in non-interactive mode and user input was requested: $@" 10
	_print_log 9 STDI "$_CONF_LOG_C_STDIN" "$_CONF_LOG_BEEP_STDIN" "$1 $3"
	_interactive_alert_if $1 $3
	read -r $2
}
_syslog() {
	logger -i -t "$_APPLICATION_NAME.$_APPLICATION_CMD" "$1"
}
_sudo() {
	[ $# -eq 0 ] && _ERROR 'No arguments were provided to _sudo'
	_sudo_is_required || {
		"$@"
		return
	}
	_require "$_SUDO_CMD" "_SUDO_CMD - $*"
	[ -n "$INTERACTIVE" ] && {
		$_SUDO_CMD -n ls >/dev/null 2>&1 || _sudo_precmd "$@"
	}
	$_SUDO_CMD $sudo_options "$@"
	unset sudo_options
}
_sudo_is_required() {
	[ -n "$_SUDO_USER" ] && {
		[ "$_SUDO_USER" = "$USER" ] && return 1
		sudo_options="$sudo_options -u $_SUDO_USER"
		return 0
	}
	[ "$USER" = "root" ] && return 1
	return 0
}
_require() {
	local level=_ERROR
	if [ -z "$1" ]; then
		[ -n "$_WARN_ON_ERROR" ] && level=_WARN
		$level "$2 required $_REQUIRE_DETAILED_MESSAGE" $3
		return 1
	fi
	unset _REQUIRE_DETAILED_MESSAGE
}
_git_github_latest_release() {
	curl -sL https://api.github.com/repos/$1/$2/releases/latest | grep tag_name | awk {'print$2'} | tr -d '"' | tr -d ','
}
_git_github_fetch_latest_artifact() {
	local github_organization_name=$1
	local github_repository_name=$2
	local artifact_name=$3
	local artifact_suffix=$4
	shift 4
	local latest_version=$(_git_github_latest_release $github_organization_name $github_repository_name)
	[ -z "$artifact_url_function" ] && artifact_url_function=_git_github_artifact_url
	$artifact_url_function $github_organization_name $github_repository_name $latest_version $artifact_name $artifact_suffix
	_download $_GITHUB_ARTIFACT_URL "$@"
	unset _GITHUB_ARTIFACT_URL
}
_git_github_artifact_url() {
	_GITHUB_ARTIFACT_URL=https://github.com/$1/$2/releases/download/${3}/${4}${3}${5}
}
_download() {
	mkdir -p $_CONF_CACHE_PATH
	local _cached_filename
	if [ $# -gt 1 ]; then
		_cached_filename="$2"
	else
		_cached_filename=$(basename $1 | sed -e 's/?.*$//')
	fi
	_DOWNLOADED_FILE=$_CONF_CACHE_PATH/$_cached_filename
	[ -z "$_NO_CACHE" ] && {
		[ -e $_DOWNLOADED_FILE ] && {
			_DETAIL "$1 already downloaded to: $_DOWNLOADED_FILE"
			return
		}
	}
	if [ -z "$_DOWNLOAD_DISABLED" ]; then
		_INFO "Downloading $1 -> $_DOWNLOADED_FILE"
		curl $_CURL_OPTIONS -o $_DOWNLOADED_FILE -s -L "$1"
	else
		_continue_if "Please manually download: $1 and place it in $_DOWNLOADED_FILE" "Y/n"
	fi
}
_download_install_file() {
	_WARN_ON_ERROR=1 _require "$1" "1 (_download_install_file) target filename" && return 1
	_INFO "Installing $_DOWNLOADED_FILE -> $1"
	_sudo mkdir -p $(dirname $1)
	_sudo cp $_DOWNLOADED_FILE $1
	_sudo chmod 444 $1
	unset _DOWNLOADED_FILE
	[ ! -e $1 ] && return 1
	return 0
}
_sed_safe() {
	printf '%s' $1 | sed -e "s/\//\\\\\//g"
}
_include logging platform context wait beep paths net web-browser
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
: ${LIB:="beep.sh context.sh environment.sh exec.sh exit.sh help.sh include.sh logging.sh mktemp.sh platform.sh processes.sh stdin.sh syslog.sh sudo.sh wait.sh validation.sh net/mail.sh alert.sh"}
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
_PLATFORM="Apple"
_TAR_ARGS=" -f - "
_SUDO_CMD="sudo"
_ARCHITECTURE=$(uname -m)
: ${_CONF_GNU_SED:=/opt/homebrew/bin/gsed}
: ${_CONF_GNU_GREP:=/opt/homebrew/opt/grep/libexec/gnubin/grep}
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
_CONF_CONFIG_PATH=$HOME/.config/walterjwhite/shell
_CONF_RUN_PATH=/tmp/$USER/walterjwhite/app
_CONF_DATA_ARTIFACTS_PATH=$_CONF_DATA_PATH/install-v2/artifacts
_CONF_DATA_REGISTRY_PATH=$_CONF_DATA_PATH/install-v2/registry
_CONF_APPLICATION_DATA_PATH=$_CONF_DATA_PATH/$_APPLICATION_NAME
_CONF_APPLICATION_CONFIG_PATH=$_CONF_CONFIG_PATH/$_APPLICATION_NAME
_CONF_APPLICATION_LIBRARY_PATH=$_CONF_LIBRARY_PATH/$_APPLICATION_NAME
: ${_CONF_NETWORK_TEST_TIMEOUT:=5}
: ${_CONF_NETWORK_TEST_TARGETS:="http://connectivity-check.ubuntu.com http://example.org http://www.google.com http://telehack.com http://lxer.com"}
: ${_CONF_WEB_BROWSER_EXPORT_HISTORY:=1}
: ${_CONF_WEB_BROWSER_SAVE_BROWSER_HISTORY_WITH_PROXY:=0}
: ${_CONF_WEB_BROWSER_SOCKS_PROXY_VERSION:=5}
BROWSER_CMD=$_CONF_WEB_BROWSER_CHROMIUM_CMD
case $_PLATFORM in
Linux | FreeBSD)
  _CONFIGURATION_DIRECTORY=~/.config/chromium
  ;;
*)
  error "Unsupported platform: $_PLATFORM"
  ;;
esac
_CONFIGURATION_DIRECTORY=~/.config/chromium
_BROWSER_NEW_INSTANCE() {
  local chromium_instance_dir=$_INSTANCE_DIRECTORY/.config/chromium
  mkdir -p $chromium_instance_dir/Default
  [ ! -e $_CONFIGURATION_DIRECTORY/Default/Preferences ] && error "$_CONFIGURATION_DIRECTORY/Default/Preferences does not exist"
  cp -R $_CONFIGURATION_DIRECTORY/Default/Preferences "$chromium_instance_dir/Default/"
  cp -R $_CONFIGURATION_DIRECTORY/Default/Extensions "$chromium_instance_dir/Default/" 2>/dev/null
  _INFO "Updating conf to use new instance dir"
  local home_directory_sed_safe=$(_sed_safe $HOME)
  local instance_dir_sed_safe=$(_sed_safe $chromium_instance_dir)
  find $_INSTANCE_DIRECTORY -type f ! -name '*.sqlite' -exec $_CONF_GNU_SED -i "s/$home_directory_sed_safe/$instance_dir_sed_safe/g" {} +
  mkdir -p $_INSTANCE_DIRECTORY/Downloads
  _SQLITE_DATABASE=$chromium_instance_dir/Default/History
  _QUERY="SELECT url,ROUND(LAST_VISIT_TIME/1000000) FROM urls WHERE url NOT LIKE 'chrome-extension://%' ORDER BY last_visit_time DESC"
  _browser_extensions
  [ -n "$_BROWSER_EXTENSIONS" ] && _browser_add_args "--load-extension=$_BROWSER_EXTENSIONS"
}
_BROWSER_HTTP_PROXY() {
  _browser_add_args "--proxy-server=http://${_WEB_BROWSER_HTTP_PROXY}"
}
_browser_extensions() {
  local extension_config extension_name extension_version
  for extension_config in $(cat $_CONFIGURATION_DIRECTORY/extensions); do
    _browser_extension $extension_config
  done
}
_browser_extension() {
  extension_name=$1
  case $extension_name in
  ublock-origin)
    _git_github_fetch_latest_artifact gorhill uBlock uBlock0_ .chromium.zip
    ;;
  Browserpass)
    _git_github_fetch_latest_artifact browserpass browserpass-extension browserpass-github- .crx
    ;;
  Ghostery)
    artifact_url_function=_ghostery_artifact_url _git_github_fetch_latest_artifact ghostery ghostery-extension ghostery-chromium- .zip
    ;;
  *)
    _WARN "Unsupported extension: $extension_name"
    continue
    ;;
  esac
}
_ghostery_artifact_url() {
  local version_without_v=$(printf '%s\n' "$3" | sed -e 's/^v//')
  _GITHUB_ARTIFACT_URL=https://github.com/$1/$2/releases/download/${3}/${4}${version_without_v}${5}
}
