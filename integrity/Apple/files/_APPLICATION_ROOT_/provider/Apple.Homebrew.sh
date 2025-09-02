#!/bin/sh
set -a
_APPLICATION_NAME=integrity
_integrity_Apple_Homebrew() {
  $_CONF_GNU_GREP -P ': /opt/homebrew' $_INTEGRITY_RAW_DATA_FILE >>$_INTEGRITY_PLUGIN_DATA_PATH
  printf '\n' >>$_INTEGRITY_PLUGIN_DATA_PATH
}
