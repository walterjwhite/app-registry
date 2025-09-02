#!/bin/sh
set -a
_APPLICATION_NAME=dev
_capture_env() {
	_RUN_LOG_FILE=.log/$(date +%Y.%m.%d.%H.%M.%S)
	mkdir -p $(dirname $_RUN_LOG_FILE)
	if [ -n "$_LOG_FILE" ]; then
		printf '@see: %s\n' "$_LOG_FILE" >$_RUN_LOG_FILE
		return
	fi
	_LOG_FILE=$_RUN_LOG_FILE
	printf '# run: %s:%s\n' "$(date)" "$PWD" >$_RUN_LOG_FILE
	printf '# git: %s:%s\n' "$(gcb)" "$(git-head)" >>$_RUN_LOG_FILE
	printf '# cmdline: %s\n' "$@" >>$_RUN_LOG_FILE
	printf '# env - start\n' >>$_RUN_LOG_FILE
	env | _sed_remove_nonprintable_characters >>$_RUN_LOG_FILE
	printf '# env - end\n' >>$_RUN_LOG_FILE
}
_open_log() {
	[ -n "$_OPEN_LOG" ] && less +G $_RUN_LOG_FILE
}
_tail() {
	[ -z "$_TAIL" ] && return 1
	_colored_tail &
	_TAIL_PIDS=$!
	_TAIL_PIDS="$_TAIL_PIDS $(_parent_processes $_TAIL_PIDS | tr '\n' ' ')"
}
_wait_for() {
	ps -p $_RUN_PID >/dev/null 2>&1
	wait $_RUN_PID
}
_run_cleanup() {
	_info "Run Cleaning up"
	kill -9 $_RUN_PID $_TAIL_PIDS $_NOTIFY_PID 2>/dev/null
	[ -e $_RUN_INSTANCE_DIR ] && rm -rf $_RUN_INSTANCE_DIR
}
_notify_running() {
	[ -z "$_NOTIFY" ] && return 1
	_call _${_LANGUAGE}_is_running
	_notify "$_CONTEXT $(basename $PWD)" "Application Started ($$)" "$_APPLICATION" &
	printf '%s\n' "started" >$_APPLICATION_PIPE &
	_NOTIFY_PID=$!
}
_run_new_instance() {
	[ -z "$_NEW_INSTANCE" ] && return 1
	_RUN_INSTANCE_DIR=$(_MKTEMP_OPTIONS=d _mktemp)
	_info "Creating new instance in $_RUN_INSTANCE_DIR"
	_call _${_LANGUAGE}_new_instance
}
_run() {
	_defer _run_cleanup
	_call _run_${_LANGUAGE}_init "$@"
	_run_new_instance
	_capture_env "$@"
	_call _run_${_LANGUAGE} "$@"
	_tail
	_notify_running
	_wait_for
	_open_log
}
_run_init_secrets() {
	if [ -e .secrets ]; then
		_info "Copying secrets -> $_RUN_INSTANCE_DIR"
		cp -R .secrets/* $_RUN_INSTANCE_DIR
	fi
}
_find_secrets() {
	[ ! -e .secrets ] && return 1
	local find_secret_patterns=$(cat .secrets | sed -e "s/^/\-iname \"/" -e 's/$/"/' | tr '\n' ' ')
	find . \(! -path '*/.git/*' ! -path '*/target/*' ! -path '*/.log/*' ! -path '*/*.secret/*' ! -name '*.secret' ! -name '*.iml' \) -and \( $find_secret_patterns \)
	local grep_secret_patterns=$(cat .secrets | tr '\n' '|' | sed -e 's/|$//')
	find . -type f \(! -path '*/.git/*' ! -path '*/target/*' ! -path '*/.log/*' ! -path '*/*.secret/*' ! -name '*.secret' ! -name '*.iml'\) \
		-exec $_CONF_GNU_GREP -i "($grep_secret_patterns)" {} +
}
_colored_tail() {
	_ESC=$(printf '\033')
	tail -f $_LOG_FILE |
		sed -u -e "s, TRACE ,${_ESC}[34m&${_ESC}[0m," \
			-e "s, DEBUG ,${_ESC}[35m&${_ESC}[0m," \
			-e "s, INFO ,${_ESC}[36m&${_ESC}[0m," \
			-e "s, WARN ,${_ESC}[33m&${_ESC}[0m," \
			-e "s, ERROR ,${_ESC}[31m&${_ESC}[0m,"
}
_sed_safe() {
	printf '%s' $1 | sed -e "s/\//\\\\\//g"
}
: ${_DEV_SUSPEND_JVM:=n}
_java_debug() {
  _DEBUG_ARGS="-agentlib:jdwp=transport=dt_socket,server=y,suspend=$_SUSPEND_JVM,address=$_CONF_DEV_DEBUG_PORT"
}
_java_new_instance() {
  _ORIGINAL_APPLICATION=$_APPLICATION
  cp $_APPLICATION $_RUN_INSTANCE_DIR
  _APPLICATION=$_RUN_INSTANCE_DIR/$(basename $_APPLICATION)
  _call _java_new_instance_$_JAVA_FRAMEWORK
}
_run_java_locate_application() {
  if [ -z "$_APPLICATION" ]; then
    _APPLICATION=$(find target -maxdepth 1 -type f ! -name '*.javadoc' ! -name '*.sources' ! -name '*.jar.original' -name '*.jar')
  fi
}
_run_java_init() {
  [ -n "$_JAVA_FRAMEWORK" ] && {
    _require_file $_CONF_APPLICATION_LIBRARY_PATH/action/run/java/framework/${_JAVA_FRAMEWORK}.sh
    _include $_CONF_APPLICATION_LIBRARY_PATH/action/run/java/framework/${_JAVA_FRAMEWORK}.sh
  }
  _run_java_locate_application
  [ -z "$_APPLICATION" ] && _error "_APPLICATION is not defined, unable to run application"
  [ $_DEV_SUSPEND ] && {
    _DEV_DEBUG=1
    _DEV_SUSPEND_JVM="y"
  }
  [ $_DEV_DEBUG ] && _java_debug
}
_run_java() {
  if [ -n "$_DEV_AGENT" ]; then
    _require_file "$_DEV_AGENT" _DEV_AGENT
    _AGENT_ARGS="${_AGENT_ARGS} -javaagent:$_DEV_AGENT"
  fi
  java $_AGENT_ARGS $_DEBUG_ARGS $_DEV_ARGS -jar $_APPLICATION "$@" >>$_LOG_FILE 2>&1 &
  _RUN_PID=$!
}
