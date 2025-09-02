#!/bin/sh
set -a
_APPLICATION_NAME=dev
. $_CONF_APPLICATION_LIBRARY_PATH/run/java/framework/qsy7.sh
_java_is_running() {
  _java_is_running_helper "DaemonCommandLineHandler - run"
}
