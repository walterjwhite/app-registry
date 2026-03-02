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
_runner_init() {
  local dev_notail=1
}
_runner_run() {
  local go_cmd_name=$(basename $PWD)
  ~/go/bin/$go_cmd_name "$@"
}
