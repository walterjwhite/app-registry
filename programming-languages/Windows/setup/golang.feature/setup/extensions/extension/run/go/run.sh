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
  $HOME/go/bin/$go_cmd_name "$@"
}
