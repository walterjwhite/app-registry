#!/bin/sh
_APPLICATION_NAME=dev
_JAVA_IS_RUNNING() {
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
if [ -n "$_DEV_QUERY_LOGGING" ]; then
	_java_spring_enable_query_logging
fi
