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
