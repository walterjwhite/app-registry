#!/bin/sh
_APPLICATION_NAME=dev
java_is_running() {
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
java_new_instance_walterjwhite() {
	cp -R target/lib $_RUN_INSTANCE_DIR
}
