#!/bin/sh
_APPLICATION_NAME=dev
_go_build_all() {
	for _ELEMENT in $@; do
		_go_build
	done
}
_go_build() {
	_COMMAND_DIRECTORY=$(readlink -f $_ELEMENT)
	_HAS_FILES=$(find $_COMMAND_DIRECTORY -maxdepth 1 -type f -name "*.go" -print -quit | wc -l)
	if [ "$_HAS_FILES" -eq "0" ]; then
		return
	fi
	cd $_COMMAND_DIRECTORY
	_INFO "Building $(basename $_COMMAND_DIRECTORY)"
	for _BUILD_EXECUTOR in $(find $_CONF_APPLICATION_LIBRARY_PATH/action/build/go/lib -type f | sort -u); do
		. $_BUILD_EXECUTOR
	done
	cd $_PWD
}
_go_build_packages() {
	find . -type d \( ! -path '*/.*/*' ! -name '.*' ! -path '*/*.secret/*' ! -name '*.secret' ! -path '*/*.archived/*' \) -or -name . | sort -V
}
_go_build_cleanup() {
	find /tmp -maxdepth 1 -mindepth 1 \
		-name 'go-build*' -or -name 'cgo*' -or -name 'cc*' -or -name 'golangci*' |
		xargs -I {} rm -rf {} 2>/dev/null
}
_PWD=$PWD
_defer _go_build_cleanup
unset GOPATH
if [ "$#" -eq "0" ]; then
	_go_build_all $(_go_build_packages)
else
	_go_build_all $@
fi
_NO_EXEC=1
