#!/bin/sh
_agent_run() {
  gemini $gemini_agent_options -y <$worker_agent_prompt
}
_agent_add_path() {
  gemini_agent_options="$gemini_agent_options --include-directories $1"
}
_agent_is_rate_limit_error() {
  tail -100 $log_logfile | grep -cqm1 'You have exhausted your capacity on this model'
}
_agent_rate_limit_wait() {
  local timeout_in_seconds=$(tail -100 $log_logfile | grep 'You have exhausted your capacity on this model.' |
    sed -e 's/^.*Your quota will reset after//' -e 's/s\.\..*$//' | sed -e 's/^.* or try again at //' | sed 's/\([0-9]\+\)\(st\|nd\|rd\|th\)/\1/')
  local current_time=$(date +%s)
  local future_epoch=$(($current_time + $timeout_in_seconds))
  printf '%s\n' "$future_epoch"
}
_agent_cmd() {
  _AGENT_CMD="gemini -y"
}
