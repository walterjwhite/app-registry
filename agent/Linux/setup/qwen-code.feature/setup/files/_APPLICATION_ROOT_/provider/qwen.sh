#!/bin/sh
_agent_run() {
  qwen -y $qwen_agent_options <$worker_agent_prompt
}
_agent_add_path() {
  qwen_agent_options="$qwen_agent_options --include-directories $1"
}
_agent_is_rate_limit_error() {
  tail -100 $log_logfile | grep -cqm1 'rate limit'
}
_agent_cmd() {
  _AGENT_CMD="qwen -y"
}
