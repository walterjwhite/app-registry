#!/bin/sh
_agent_run() {
  opencode run <$worker_agent_prompt
}
_agent_add_path() {
  :
}
_agent_is_rate_limit_error() {
  tail -100 $log_logfile | grep -cqm1 'rate limit'
}
_agent_cmd() {
  _AGENT_CMD="opencode run"
}
