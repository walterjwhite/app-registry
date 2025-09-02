#!/bin/sh
set -a
_APPLICATION_NAME=dev
_java_is_running() {
  _java_is_running_helper "CommandLineApplicationInstance - doRun(null)"
}
_java_is_running_helper() {
  /bin/sh -c "printf '$$\n'; exec tail -f $_LOG_FILE" | {
    IFS= read _TAIL_PID
    grep -q -m 1 -- "$1"
    kill -s PIPE $_TAIL_PID
  }
  unset _TAIL_PID
}
_java_new_instance_qsy7() {
  cp -R target/lib $_RUN_INSTANCE_DIR
}
_run_java_locate_application() {
  if [ -z "$_APPLICATION" ]; then
    _APPLICATION=$(find target -maxdepth 1 -type f ! -name '*.javadoc' ! -name '*.sources' ! -name '*.jar.original' ! -name '*shaded*' -name '*.jar')
  fi
}
