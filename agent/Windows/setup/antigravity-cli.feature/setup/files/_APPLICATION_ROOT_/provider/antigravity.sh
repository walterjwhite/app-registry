#!/bin/sh
_agent_run() {
  antigravity-cli <$worker_agent_prompt >>$log_logfile 2>&1
}
_agent_add_path() {
  antigravity_agent_options="$antigravity_agent_options --add-dir $1"
}
_agent_is_rate_limit_error() {
  :
}
_agent_rate_limit_wait() {
  :
}
_agent_cmd() {
  _AGENT_CMD="antigravity-cli $antigravity_agent_options"
}
