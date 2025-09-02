#!/bin/sh
set -a
_APPLICATION_NAME=configuration
_PLUGIN_CONFIGURATION_PATH=~/.config/mac/autostart
_configure_mac_autostart_restore() {
  if [ ! -e $_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME/autostart ]; then
    return
  fi
  local autostart_app
  while read autostart_app; do
    osascript -e "tell application \"$autostart_app\" to activate"
  done <$_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME/autostart
}
