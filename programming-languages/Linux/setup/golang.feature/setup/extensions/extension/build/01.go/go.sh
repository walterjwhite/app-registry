#!/bin/sh
go_dependencies() {
	go get -u
}
go_mod_tidy() {
	go mod tidy
}
go_build_do() {
	[ $(grep "package main" *.go -n 2>/dev/null | wc -l) -eq 0 ] && {
		_go_build_lib
		return
	}
	log_detail 'building cmd'
	_go_build_cmd
}
_go_build_lib() {
	go build -a -race $go_build_options
}
_go_build_cmd() {
	_go_walterjwhite_conf $PWD
	local error_count=0
	(
		env CGO_ENABLED=1 go install -a -race -ldflags "$go_build_options"
	) || error_count=1
	unset _app_name_flag _app_version_flag _scm_id_flag _build_date_flag _go_version_flag _os_architecture_flag go_build_options
	return $error_count
}
go_fix() {
	go fix
}
go_lint() {
	golangci-lint run --fix ./
}
go_vet() {
	go vet
}
go_test() {
	find . -maxdepth 1 -type f -name "*_test.go" -print -quit | grep -cqm1 '.' || {
		return 0
	}
	go test -test.bench=".*"
}
go_bootstrap() {
	_go_set_proxy
	_go_bootstrap_is_go_available || {
		_package_install_new_only $GO_PACKAGE
		_go_bootstrap_is_go_available || go_disabled=1
	}
}
_go_set_proxy() {
	[ -z "$http_proxy" ] && return
	git config --global http.proxy $http_proxy
	git config --global https.proxy $https_proxy
	exit_defer _go_clear_proxy
}
_go_clear_proxy() {
	git config --global --unset http.proxy
	git config --global --unset https.proxy
}
_go_bootstrap_is_go_available() {
	which go >/dev/null 2>&1
}
_go_walterjwhite_conf() {
	[ -e ./.build/go ] && . ./.build/go
	local _app_name=$(basename $1 | sed -e 's/@.*//')
	local _build_date=$(date +"%Y/%m/%d-%H:%M:%S")
	local _version=$(git branch --no-color --show-current)
	local _scm_id=$(git rev-parse HEAD)
	local _go_version=$(go version | awk {'print$3'})
	local _os_architecture=$(go version | awk {'print$4'})
	local _app_name_flag="github.com/walterjwhite/go-code/lib/application.ApplicationName=$_app_name"
	local _app_version_flag="github.com/walterjwhite/go-code/lib/application.ApplicationVersion=$_version"
	local _scm_version_id_flag="github.com/walterjwhite/go-code/lib/application.SCMId=$_scm_id"
	local _build_date_flag="github.com/walterjwhite/go-code/lib/application.BuildDate=$_build_date"
	local _go_version_flag="github.com/walterjwhite/go-code/lib/application.GoVersion=$_go_version"
	local _os_architecture_flag="github.com/walterjwhite/go-code/lib/application.OSArchitecture=$_os_architecture"
	go_build_options="-X $_app_name_flag -X $_app_version_flag -X $_scm_version_id_flag -X $_build_date_flag -X $_go_version_flag -X $_os_architecture_flag"
	log_debug "build flags:"
	log_debug "$_app_name_flag"
	log_debug "$_app_version_flag"
	log_debug "$_scm_version_id_flag"
	log_debug "$_build_date_flag"
	log_debug "$_go_version_flag"
	log_debug "$_os_architecture_flag"
}
_go_install_do() {
	_go_is_installed $1 && {
		log_detail "$1 is already installed"
		return 0
	}
	case $1 in
	*github.com/walterjwhite/*)
		_go_walterjwhite_conf "$1"
		;;
	*)
		log_debug "using standard go properties"
		;;
	esac
	(
		if [ -n "$go_build_options" ]; then
			env GOPATH="$conf_install_go_path" CGO_ENABLED=1 go install -a -race -ldflags "$go_build_options" "$1"
		else
			env GOPATH="$conf_install_go_path" CGO_ENABLED=1 go install -a -race "$1"
		fi
	) || {
		log_warn "go install failed: env GOPATH='$conf_install_go_path' CGO_ENABLED=1 go install -a -race '$go_build_options' $1"
		log_warn "http_proxy: $http_proxy"
		log_warn "git  proxy: $(git config --global http.proxy)"
	}
}
_go_uninstall_do() {
	go uninstall "$@"
}
_go_is_installed() {
	local cmd_name=$(basename $(printf '%s\n' "$1" | sed 's/@.*//; s/\/v[0-9]*$//'))
	[ -e "$conf_install_go_path/bin/$cmd_name" ]
}
_go_build_all() {
  local error_count=0
  for _ELEMENT in "$@"; do
    _go_build || error_count=$(($error_count + 1))
  done
  return $error_count
}
_go_build() {
  local command_directory=$(readlink -f $_ELEMENT)
  local app_name=$(basename $command_directory)
  cd $command_directory
  log_info "building $app_name"
  go_build_errors=0
  _go_exec dependencies mod_tidy build_do fix lint vet test
  cd $ORIGINAL_PWD
  return $go_build_errors
}
_go_exec() {
  for go_function in "$@"; do
    go_$go_function || {
      log_warn "function $go_function produced error(s) - $?"
      go_build_errors=$(($go_build_errors + 1))
    }
  done
}
_go_build_cleanup() {
  find /tmp -maxdepth 1 -mindepth 1 \
    -name 'go-build*' -or -name 'cgo*' -or -name 'cc*' -or -name 'golangci*' \
    -exec rm -rf {} + 2>/dev/null
}
readonly ORIGINAL_PWD=$PWD
exit_defer _go_build_cleanup
unset GOPATH
if [ "$#" -eq "0" ]; then
  _go_build_all $(extension_find_dirs_containing)
else
  _go_build_all "$@"
fi
