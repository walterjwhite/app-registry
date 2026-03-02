#!/bin/sh
_APPLICATION_NAME=dev
_go_build_all() {
	local error_count=0
	for _ELEMENT in $@; do
		_go_build || error_count=$(($error_count + 1))
	done
	return $error_count
}
_go_build() {
	_COMMAND_DIRECTORY=$(readlink -f $_ELEMENT)
	_HAS_FILES=$(find $_COMMAND_DIRECTORY -maxdepth 1 -type f -name "*.go" -print -quit | wc -l)
	[ "$_HAS_FILES" -eq "0" ] && return
	cd $_COMMAND_DIRECTORY
	_INFO "Building $(basename $_COMMAND_DIRECTORY)"
	local error_count=0
	for _BUILD_EXECUTOR in $(find $_CONF_APPLICATION_LIBRARY_PATH/action/build/go/lib -type f | sort -u); do
		. $_BUILD_EXECUTOR || {
			_WARN "$_BUILD_EXECUTOR produced error(s) - $?"
			error_count=$(($error_count + 1))
		}
	done
	cd $_PWD
	return $error_count
}
_go_build_packages() {
	find . -type d \( ! -path '*/.*/*' ! -name '.*' ! -path '*/*.secret/*' ! -name '*.secret' ! -path '*/*.archived/*' \) -or -name . | sort -V
}
_go_build_cleanup() {
	find /tmp -maxdepth 1 -mindepth 1 \
		-name 'go-build*' -or -name 'cgo*' -or -name 'cc*' -or -name 'golangci*' \
		-exec rm -rf {} + 2>/dev/null
}
_PWD=$PWD
_defer _go_build_cleanup
_NO_EXEC=1
unset GOPATH
if [ "$#" -eq "0" ]; then
	_go_build_all $(_go_build_packages)
else
	_go_build_all $@
fi
