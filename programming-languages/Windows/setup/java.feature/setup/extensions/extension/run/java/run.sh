#!/bin/sh
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
_java_debug() {
  debug_args="-agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=$debug_port"
}
_runner_init() {
  [ -n "$java_framework" ] && {
    . /usr/local/walterjwhite/install/extensions/extension/$extension_action/$extension_run_type/framework/${java_framework}.sh
  }
  _run_java_locate_application
  [ -z "$application" ] && exit_with_error "application is not defined, unable to run application"
  [ $debug ] && _java_debug
}
_run_java_locate_application() {
  [ -z "$application" ] && application=$(find target -maxdepth 1 -type f ! -name '*.javadoc' ! -name '*.sources' ! -name '*.jar.original' -name '*.jar')
}
_runner_run() {
  if [ -n "$_AGENT" ]; then
    file_require "$_AGENT" _AGENT
    local agent_args="${agent_args} -javaagent:$_AGENT"
  fi
  java $agent_args $debug_args $java_args -jar $application "$@" &
  run_pid=$!
}
