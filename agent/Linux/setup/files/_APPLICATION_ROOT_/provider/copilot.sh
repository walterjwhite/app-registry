#!/bin/sh
_agent_run() {
  local copilot_tmp_dir=$(mktemp_options=d _mktemp_mktemp)
  export TMPDIR="$copilot_tmp_dir"
  exit_defer rm -rf "$copilot_tmp_dir"
  copilot $copilot_agent_options --allow-all-tools <$worker_agent_prompt
  rm -rf "$copilot_tmp_dir"
  unset TMPDIR
}
_agent_add_path() {
  copilot_agent_options="$copilot_agent_options --add-dir $1"
}
_agent_is_rate_limit_error() {
  tail -100 $log_logfile | grep -cqm1 'hit a rate limit that restricts the number of Copilot model requests you can make within a specific time period.'
}
