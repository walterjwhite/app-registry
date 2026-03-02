#!/bin/sh
_agent_run() {
  gemini $gemini_agent_options -y <$worker_agent_prompt
}
_agent_add_path() {
  gemini_agent_options="$gemini_agent_options --include-directories $1"
}
_agent_is_rate_limit_error() {
  tail -100 $log_logfile | grep -cqm1 'rate limit'
}
