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
_GO_NEW_INSTANCE() {
	_ERROR "not implemented"
}
_RUN_GO_INIT() {
	_DEV_NOTAIL=1
}
_RUN_GO() {
	_GO_CMD_NAME=$(basename $PWD)
	~/go/bin/$_GO_CMD_NAME "$@"
}
