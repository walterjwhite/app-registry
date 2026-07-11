#!/bin/sh
_agent_run() {
  devin $devin_agent_options -p "$(cat $worker_agent_prompt)" >>$log_logfile 2>&1
}
_agent_add_path() {
}
_agent_is_rate_limit_error() {
  tail -100 $log_logfile | grep -cqm1 'hit a rate limit that restricts the number of Devin requests you can make within a specific time period.'
}
_agent_cmd() {
  _AGENT_CMD="devin"
}
