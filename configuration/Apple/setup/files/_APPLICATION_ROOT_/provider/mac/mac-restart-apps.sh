#!/bin/sh
provider_path=${alt_path}$HOME/.config/mac/restart-apps
_configuration_mac_restart_apps_restore() {
  if [ ! -e $provider_data_path/restart-apps ]; then
    return
  fi
  local restart_app
  while read restart_app; do
    pkill -1 -lf $restart_app
  done <$provider_data_path/restart-apps
}
