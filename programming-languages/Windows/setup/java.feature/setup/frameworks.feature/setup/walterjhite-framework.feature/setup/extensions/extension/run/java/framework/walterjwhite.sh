#!/bin/sh
_run_notify_running() {
  if [ -z "$_WALTERJWHITE_APP_IS_DAEMON" ]; then
    _java_is_running_helper "CommandLineApplicationInstance - doRun(null)"
  else
    _java_is_running_helper "DaemonCommandLineHandler - run"
  fi
}
_java_is_running_helper() {
  /bin/sh -c "printf '$$\n'; exec tail -f $log_logfile" | {
    IFS= read _NOTIFY_RUNNING_TAIL_PID
    grep -q -m 1 -- "$1"
    kill -s PIPE $_NOTIFY_RUNNING_TAIL_PID
  }
  unset _NOTIFY_RUNNING_TAIL_PID
}
_run_java_locate_application() {
  if [ -z "$application" ]; then
    local application=$(find target -maxdepth 1 -type f ! -name '*.javadoc' ! -name '*.sources' ! -name '*.jar.original' ! -name '*shaded*' -name '*.jar')
  fi
}
java_cleanup() {
  :
}
_application_init() {
  :
}
