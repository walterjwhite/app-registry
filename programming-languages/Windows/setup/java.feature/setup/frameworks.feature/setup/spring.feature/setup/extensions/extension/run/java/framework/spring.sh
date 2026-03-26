#!/bin/sh
_run_notify_running() {
  /bin/sh -c "printf '$$\n'; exec tail -f $log_logfile" | {
    IFS= read _NOTIFY_RUNNING_TAIL_PID
    grep -q -m 1 -- "Started Application in"
    kill -s PIPE $_NOTIFY_RUNNING_TAIL_PID
  }
  unset _NOTIFY_RUNNING_TAIL_PID
}
_java_spring_enable_query_logging() {
  local java_args="$java_args -Dlogging.level.org.hibernate.SQL=DEBUG"
  local java_args="$java_args -Dlogging.level.org.hibernate.stat=DEBUG"
  local java_args="$java_args -Dlogging.level.org.hibernate.type.descriptor.sql.BasicBinder=TRACE"
  local java_args="$java_args -Dlogging.level.org.springframework.data.jpa=DEBUG"
  local java_args="$java_args -Dlogging.level.org.springframework.jdbc.core.JdbcTemplate=DEBUG"
  local java_args="$java_args -Dlogging.level.org.springframework.jdbc.core.StatementCreatorUtils=TRACE"
  local java_args="$java_args -Dlogging.level.org.springframework.jdbc.core.TRACE"
  local java_args="$java_args -Dspring.jpa.properties.hibernate.generate_statistics=true"
}
java_cleanup() {
  [ -n "$_SPRING_BOOT_H2_CLEANUP" ] && rm -rf /tmp/h2*
  [ -n "$_SPRING_BOOT_TOMCAT_CLEANUP" ] && rm -rf /tmp/tomcat*
}
_application_init() {
  local app_data_dir app_data_file
  rm -f target/classes/data.sql && mkdir -p target/classes
  for app_data_dir in $(find . -maxdepth 1 -mindepth 1 -type d -name 'data.sql*' | sort -V); do
    for app_data_file in $(find $app_dir_dir -type f | sort -V); do
      log_detail "appending $app_data_file to target/classes/data.sql"
      printf '-- %\n' $app_data_file >>target/classes/data.sql
      cat $app_data_file >>target/classes/data.sql
    done
  done
  for app_data_file in $(find . -maxdepth 1 -mindepth 1 -type f -name 'data.sql*' | sort -V); do
    log_detail "appending $app_data_file to target/classes/data.sql"
    printf '%s %s\n' '--' "$app_data_file" >>target/classes/data.sql
    cat $app_data_file >>target/classes/data.sql
  done
}
if [ -n "$_DEV_QUERY_LOGGING" ]; then
  _java_spring_enable_query_logging
fi
