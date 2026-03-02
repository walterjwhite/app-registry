#!/bin/sh
_console_fish_hook_after() {
	local -i cmd_status=$?
	[ -z "$console_current_time" ] && return
	local now=$(_time_time_current_time_unix_epoch)
	local cmd_runtime=$(($now - $console_current_time))
	if [ $cmd_runtime -gt 0 ]; then
		_console_log 'After ' " - ${cmd_runtime}s"
	else
		_console_log 'After '
	fi
	unset console_current_time
}
_console_fish_hook_before() {
	console_current_time=$(_time_time_current_time_unix_epoch)
	_command=$1
	_console_context_refresh_timeout=$(($console_current_time + $conf_console_script_timeout))
	_console_log Before
}
_time_time_current_time_unix_epoch() {
	date +%s
}
_console_date() {
	date +"$conf_log_date_format"
}
_console_log() {
	local message="$1"
	[ "$_CONSOLE_CONTEXT_ID" ] && message="[$_CONSOLE_CONTEXT_ID] $message"
	printf '\e[1;3;%sm### %s - %s ###\e[0m\n' "$conf_console_audit_color" "$message" "$(_console_date)$2"
}
readonly APP_PLATFORM_ARCHITECTURE=$(uname -m)
readonly APP_PLATFORM_OS_NAME=$(uname)
case "$APP_PLATFORM_OS_NAME" in
Darwin)
	readonly APP_PLATFORM_PLATFORM="Apple"
	;;
MINGW64_NT-*)
	readonly APP_PLATFORM_PLATFORM="Windows"
	;;
*)
	readonly APP_PLATFORM_PLATFORM="$APP_PLATFORM_OS_NAME"
	;;
esac
if [ -z "$APP_PLATFORM_ROOT" ]; then
	APP_PLATFORM_ROOT=/
else
	APP_PLATFORM_ROOT=$(_file_readlink $APP_PLATFORM_ROOT)
fi
readonly CACHE_PATH=$HOME/.cache
readonly CONFIG_PATH=$HOME/.config/walterjwhite/shell
readonly DATA_PATH=$HOME/.data
readonly RUN_PATH=/tmp/$USER/walterjwhite/app
readonly APP_CONTEXT="default"
readonly APPLICATION_CONTEXT_GROUP=$RUN_PATH/$APP_CONTEXT
readonly APPLICATION_CMD_DIR=$APPLICATION_CONTEXT_GROUP/$APPLICATION_NAME/$APPLICATION_CMD
readonly APPLICATION_PIPE=$APPLICATION_CMD_DIR/$$
readonly APPLICATION_PIPE_DIR=$(dirname $APPLICATION_PIPE)
readonly GNU_GREP=grep
readonly GNU_SED=sed
readonly _SUDO_CMD="sudo"
readonly PLATFORM_SYSTEM_ID_PATH=/usr/local/etc/walterjwhite/system
readonly EMERGE_FLAGS="-q --quiet-build --quiet-fail"
readonly IO_STAT_ARGS='-c %a'
readonly APP_PLATFORM_SUB_PLATFORM=$($GNU_GREP -Ph "^NAME=" $APP_PLATFORM_ROOT/etc/os-release 2>/dev/null | sed -e 's/^NAME=//' -e 's/ Linux//' -e 's/"//g')
readonly LIBRARY_PATH=/usr/local/walterjwhite
readonly BIN_PATH=/usr/local/bin
case $APP_PLATFORM_SUB_PLATFORM in
Arch | CachyOS)
	linux_package_manager=pacman
	case $APP_PLATFORM_SUB_PLATFORM in
	CachyOS)
		readonly APP_PLATFORM_DERIVED_SUB_PLATFORM=Arch
		;;
	esac
	readonly PLATFORM_PACKAGES="bc beep curl expect git shellcheck sudo shfmt"
	readonly NPM_PACKAGE="npm"
	readonly RUST_PACKAGE="rust"
	readonly PYPI_PACKAGE="python"
	readonly GO_PACKAGE="go"
	readonly EXPECT_PACKAGE="expect"
	: ${pacman_silent_install:=1}
	: ${pacman_auto_install:=1}
	;;
Gentoo)
	linux_package_manager=emerge
	readonly PLATFORM_PACKAGES="dev-vcs/git dev-tcltk/expect net-misc/curl dev-util/sh app-admin/sudo app-misc/beep app-portage/gentoolkit"
	readonly PLATFORM_PACKAGES_ACCEPT_KEYWORDS="dev-util/sh ~amd64"
	readonly NPM_PACKAGE="net-libs/nodejs"
	readonly RUST_PACKAGE="dev-lang/rust"
	readonly PYPI_PACKAGE="dev-lang/python"
	readonly GO_PACKAGE="dev-lang/go"
	readonly EXPECT_PACKAGE="dev-tcltk/expect"
	;;
*)
	exit_with_error "supported distributions: Gentoo (emerge), Arch/CachyOS (pacman)"
	;;
esac
readonly APP_PLATFORM_BIN_PATH=$(printf '%s' $APP_PLATFORM_ROOT/$BIN_PATH | tr -s /)
readonly APP_PLATFORM_CACHE_PATH=$(printf '%s' $APP_PLATFORM_ROOT/$CACHE_PATH | tr -s /)
readonly APP_PLATFORM_CONFIG_PATH=$(printf '%s' $APP_PLATFORM_ROOT/$CONFIG_PATH | tr -s /)
readonly APP_PLATFORM_DATA_PATH=$(printf '%s' $APP_PLATFORM_ROOT/$DATA_PATH | tr -s /)
readonly APP_PLATFORM_LIBRARY_PATH=$(printf '%s' $APP_PLATFORM_ROOT/$LIBRARY_PATH | tr -s /)
readonly APP_CONFIG_PATH=$APP_PLATFORM_CONFIG_PATH/$APPLICATION_NAME
readonly APP_DATA_PATH=$APP_PLATFORM_DATA_PATH/$APPLICATION_NAME
readonly APP_LIBRARY_PATH=$APP_PLATFORM_LIBRARY_PATH/$APPLICATION_NAME
[ "$HOME" = "/" ] || [ -z "$HOME" ] && HOME=/root
: ${conf_console_audit_color:=34}
: ${conf_console_script_timeout:=5}
: ${conf_console_context_timeout:=300}
: ${conf_log_date_format:="%Y/%m/%d|%H:%M:%S"}
: ${APP_CONTEXT:=$_CONSOLE_CONTEXT_ID}
: ${APP_CONTEXT:=default}
: ${conf_console_fish_session_history_size:=1000}
: ${conf_console_fish_disk_history_size:=1000}
: ${conf_console_shell_cmd:=/usr/bin/fish}
CONF_LOG_HEADER="##################################################"
: ${conf_log_c_err:="1;31m"}
: ${conf_log_c_scs:="1;32m"}
: ${conf_log_c_wrn:="1;33m"}
: ${conf_log_c_info:="1;36m"}
: ${conf_log_c_detail:="1;0;36m"}
: ${conf_log_c_debug:="1;35m"}
: ${conf_log_c_stdin:="1;34m"}
: ${conf_log_date_format:="%y/%m/%d|%h:%m:%s"}
: ${conf_log_date_time_format:="%y/%m/%d %h:%m:%s"}
: ${conf_log_level:=2}
: ${conf_log_indent:="  "}
: ${conf_log_validation_function:=warn}
: ${conf_log_waiter_level:=debug}
: ${conf_log_feature_timeout_error_level:=warn}
: ${conf_log_long_running_cmd:=30}
: ${conf_log_long_running_cmd_lines:=1000}
which mail >/dev/null 2>&1 || conf_log_mail_disabled=1
[ -t 0 ] && interactive=1
: ${conf_log_console:=2}
: ${emerge_portage_refresh_period:=3600}
: ${pacman_refresh_period:=3600}
: ${pacman_bootstrap_install:=}
set -g HISTSIZE $conf_console_zsh_session_history_size
set -g SAVEHIST $conf_console_zsh_disk_history_size
function _console_fish_hook_after --on-event fish_prompt
end
function _console_fish_hook_before --on-event fish_preexec
end
