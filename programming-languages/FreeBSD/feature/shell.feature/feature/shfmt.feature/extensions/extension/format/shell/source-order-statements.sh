#!/bin/sh
set -a
_APPLICATION_NAME=programming-languages
_APPLICATION_START_TIME=$(date +%s)
_APPLICATION_CMD=$(basename $0)
_include
: ${_OPTN_DEV_SHFMT_OPTIONS:="-i 2"}
: ${_CONF_DEV_FORMAT_PARALLEL:=10}
_SHELL_FIND | xargs -P$_CONF_DEV_FORMAT_PARALLEL -I _F sh-app-fmt _F
