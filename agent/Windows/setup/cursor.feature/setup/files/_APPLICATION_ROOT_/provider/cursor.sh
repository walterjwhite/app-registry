#!/bin/sh
_agent_run() {
  cursor-agent --model auto -f <$worker_agent_prompt >>$log_logfile 2>&1
}
_agent_add_path() {
  :
}
_agent_is_rate_limit_error() {
  tail -100 $log_logfile | grep -cqm1 "You've hit your usage limit Get Cursor Pro for more Agent usage, unlimited Tab, and more."
}
_agent_rate_limit_wait() {
  case $APP_PLATFORM_PLATFORM in
  Linux)
    date -d "$(date +%Y-%m-01) +1 month" +%s
    ;;
  FreeBSD | Apple)
    date -j -f "%Y-%m-%d %H:%M:%S" "$(date -v+1m +%Y-%m-01) 00:00:00" +%s
    ;;
  *)
    log_warn "unsupported"
    ;;
  esac
}
_agent_cmd() {
  _AGENT_CMD="cursor-agent --model auto -f -p"
}
