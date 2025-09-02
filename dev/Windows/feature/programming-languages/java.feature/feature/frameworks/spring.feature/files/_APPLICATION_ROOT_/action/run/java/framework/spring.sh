#!/bin/sh
set -a
_APPLICATION_NAME=dev
_java_is_running() {
  /bin/sh -c "printf '$$\n'; exec tail -f $_LOG_FILE" | {
    IFS= read _TAIL_PID
    grep -q -m 1 -- "Started Application in"
    kill -s PIPE $_TAIL_PID
  }
  unset _TAIL_PID
}
_java_spring_enable_query_logging() {
  _JAVA_ARGS="$_JAVA_ARGS -Dlogging.level.org.hibernate.SQL=DEBUG"
  _JAVA_ARGS="$_JAVA_ARGS -Dlogging.level.org.hibernate.stat=DEBUG"
  _JAVA_ARGS="$_JAVA_ARGS -Dlogging.level.org.hibernate.type.descriptor.sql.BasicBinder=TRACE"
  _JAVA_ARGS="$_JAVA_ARGS -Dlogging.level.org.springframework.data.jpa=DEBUG"
  _JAVA_ARGS="$_JAVA_ARGS -Dlogging.level.org.springframework.jdbc.core.JdbcTemplate=DEBUG"
  _JAVA_ARGS="$_JAVA_ARGS -Dlogging.level.org.springframework.jdbc.core.StatementCreatorUtils=TRACE"
  _JAVA_ARGS="$_JAVA_ARGS -Dlogging.level.org.springframework.jdbc.core.TRACE"
  _JAVA_ARGS="$_JAVA_ARGS -Dspring.jpa.properties.hibernate.generate_statistics=true"
}
for _ARG in "$@"; do
  case $_ARG in
  -query-logging)
    _java_spring_enable_query_logging
    ;;
  esac
done
if [ $_CONF_DEV_JAVA_SPRING_QUERY_LOGGING -eq 1 ]; then
  _java_spring_enable_query_logging
fi
