#!/bin/sh
_agent_run() {
  claude $claude_agent_options --allow-dangerously-skip-permissions -p "$worker_agent_prompt"
}
_agent_add_path() {
  claude_agent_options="$claude_agent_options --add-dir $1"
}
_agent_is_rate_limit_error() {
  tail -100 $log_logfile | grep -cqm1 'rate limit'
}
