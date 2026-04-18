#!/bin/sh
_agent_run() {
  cursor-agent --model auto -f -p
}
_agent_add_path() {
  :
}
_agent_is_rate_limit_error() {
  tail -100 $log_logfile | grep -cqm1 'hit a rate limit that restricts the number of Copilot model requests you can make within a specific time period.'
}
_agent_cmd() {
  _AGENT_CMD="cursor-agent --model auto -f -p"
}
