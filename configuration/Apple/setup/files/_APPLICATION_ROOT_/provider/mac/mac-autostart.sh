#!/bin/sh
provider_path=${alt_path}$HOME/.config/mac/autostart
_configuration_mac_autostart_restore() {
  if [ ! -e $provider_data_path/autostart ]; then
    return
  fi
  local autostart_app
  while read autostart_app; do
    osascript -e "tell application \"$autostart_app\" to activate"
  done <$provider_data_path/autostart
}
