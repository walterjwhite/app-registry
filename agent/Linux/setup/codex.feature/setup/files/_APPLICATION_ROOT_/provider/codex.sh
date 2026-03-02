#!/bin/sh
_agent_run() {
  codex $codex_agent_options --full-auto exec <$worker_agent_prompt
}
_agent_add_path() {
  codex_agent_options="$codex_agent_options --add-dir $1"
}
_agent_is_rate_limit_error() {
  tail -100 $log_logfile | grep -cqm1 'rate limit'
}
