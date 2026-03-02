#!/bin/sh
_APPLICATION_NAME=dev
_require_file() {
	_require "$1" filename _require_file
	local level=_ERROR
	[ -n "$_WARN_ON_ERROR" ] && level=_WARN
	if [ ! -e $1 ]; then
		$level "File: $1 does not exist | $2"
		return 1
	fi
}
_include
: ${_CONF_DEV_JAVA_FORMATTER:=google}
: ${_DEV_SUSPEND_JVM:=n}
: ${_DEV_DEBUG_PORT:=5005}
_javadebug() {
	_DEBUG_ARGS="-agentlib:jdwp=transport=dt_socket,server=y,suspend=$_DEV_SUSPEND_JVM,address=$_DEV_DEBUG_PORT"
}
_JAVA_NEW_INSTANCE() {
	_ORIGINAL_APPLICATION=$_APPLICATION
	cp $_APPLICATION $_RUN_INSTANCE_DIR
	_APPLICATION=$_RUN_INSTANCE_DIR/$(basename $_APPLICATION)
	_JAVA_FRAMEWORK_NAME=$(printf '%s' $_JAVA_FRAMEWORK | tr '[:lower:]' '[:upper:]')
	_call _JAVA_NEW_INSTANCE_$_JAVA_FRAMEWORK_NAME
}
_run_java_locate_application() {
	if [ -z "$_APPLICATION" ]; then
		_APPLICATION=$(find target -maxdepth 1 -type f ! -name '*.javadoc' ! -name '*.sources' ! -name '*.jar.original' -name '*.jar')
	fi
}
_RUN_JAVA_INIT() {
	[ -n "$_JAVA_FRAMEWORK" ] && {
		_require_file $_CONF_APPLICATION_LIBRARY_PATH/action/run/java/framework/${_JAVA_FRAMEWORK}.sh
		_include $_CONF_APPLICATION_LIBRARY_PATH/action/run/java/framework/${_JAVA_FRAMEWORK}.sh
	}
	_run_java_locate_application
	[ -z "$_APPLICATION" ] && _ERROR "_APPLICATION is not defined, unable to run application"
	[ $_DEV_SUSPEND ] && {
		_DEV_DEBUG=1
		_DEV_SUSPEND_JVM="y"
	}
	[ $_DEV_DEBUG ] && _javadebug
}
_RUN_JAVA() {
	if [ -n "$_DEV_AGENT" ]; then
		_require_file "$_DEV_AGENT" _DEV_AGENT
		_AGENT_ARGS="${_AGENT_ARGS} -javaagent:$_DEV_AGENT"
	fi
	java $_AGENT_ARGS $_DEBUG_ARGS $_DEV_ARGS -jar $_APPLICATION "$@" >>$_RUN_LOG_FILE 2>&1 &
	_RUN_PID=$!
}
