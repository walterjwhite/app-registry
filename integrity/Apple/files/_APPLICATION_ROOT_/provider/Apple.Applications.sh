#!/bin/sh
set -a
_APPLICATION_NAME=integrity
_integrity_Apple_Applications() {
  local application_name
  $_CONF_GNU_GREP -P ': /Applications/.*\.app' $_INTEGRITY_RAW_DATA_FILE |
    sed -e 's/\.app.*$/\.app/' -e 's/^.*: \/Applications\///' |
    sort -u |
    while read application_name; do
      printf ' %s\n' "$application_name" >>$_INTEGRITY_PLUGIN_DATA_PATH
      $_CONF_GNU_GREP -P ": /Applications/$application_name" $_INTEGRITY_RAW_DATA_FILE >>$_INTEGRITY_PLUGIN_DATA_PATH
      printf '\n' >>$_INTEGRITY_PLUGIN_DATA_PATH
    done
}
