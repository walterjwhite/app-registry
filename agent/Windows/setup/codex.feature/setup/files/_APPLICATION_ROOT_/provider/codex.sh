#!/bin/sh
_date_human_readable_to_unix_epoch() {
	date -d "$1" +%s
}
_agent_run() {
  codex $codex_agent_options --full-auto exec <$worker_agent_prompt
}
_agent_add_path() {
  codex_agent_options="$codex_agent_options --add-dir $1"
}
_agent_is_rate_limit_error() {
  tail -100 $log_logfile | grep -cqm1 "You've hit your usage limit."
}
_agent_rate_limit_wait() {
  local human_readable_date_time=$(tail -100 $log_logfile | grep "You've hit your usage limit." | sed -e 's/^.* or try again at //' | sed 's/\([0-9]\+\)\(st\|nd\|rd\|th\)/\1/')
  _date_human_readable_to_unix_epoch "$human_readable_date_time"
}
_agent_cmd() {
  _AGENT_CMD="codex $codex_agent_options --full-auto exec"
}
