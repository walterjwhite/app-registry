#!/bin/sh
_agent_run() {
  cursor-agent --model auto -f -p
}
_agent_add_path() {
  :
}
_agent_is_rate_limit_error() {
  tail -100 $log_logfile | grep -cqm1 "You've hit your usage limit Get Cursor Pro for more Agent usage, unlimited Tab, and more."
}
_agent_cmd() {
  _AGENT_CMD="cursor-agent --model auto -f -p"
}
