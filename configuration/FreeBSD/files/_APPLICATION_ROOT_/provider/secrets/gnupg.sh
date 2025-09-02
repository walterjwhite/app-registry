#!/bin/sh
set -a
_APPLICATION_NAME=configuration
_PLUGIN_CONFIGURATION_PATH=~/.gnupg
_PLUGIN_CONFIGURATION_PATH_IS_DIR=1
_PLUGIN_EXCLUDE="random_seed .#*"
_PLUGIN_NO_ROOT_USER=1
_configure_gnupg_restore_post() {
  chmod 700 "$_PLUGIN_CONFIGURATION_PATH"
}
