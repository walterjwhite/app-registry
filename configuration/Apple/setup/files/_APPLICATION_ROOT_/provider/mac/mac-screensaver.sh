#!/bin/sh
provider_path=${alt_path}$HOME/.config/mac/screensaver
_configuration_mac_screensaver_restore() {
  if [ ! -e $provider_data_path/screensaver ]; then
    return
  fi
  . $provider_data_path/screensaver
  _SCREENSAVER_NAME="tell application \"System Events\" to set current screen saver to screen saver \"$conf_mac_screensaver_name\""
  _SCREENSAVER_TIMEOUT="tell application \"System Events\" to set delay interval of screen saver preferences to $conf_mac_screensaver_timeout -- Number In Seconds"
  osascript -e "$_SCREENSAVER_NAME" -e "$_SCREENSAVER_TIMEOUT"
}
