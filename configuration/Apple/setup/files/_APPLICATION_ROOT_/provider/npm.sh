#!/bin/sh
provider_path=${alt_path}$HOME/.npmrc
_configuration_npm_backup_post() {
  command -v npm >/dev/null 2>&1 || return
  npm list -g --depth=0 |
    sed 1d |
    sed -e 's/^.* //' -e 's/@.*$//' >$provider_data_path/modules
}
_configuration_npm_restore_post() {
  ! [ -e $provider_data_path/modules ] && return
  local npm_module
  for npm_module in $(cat $provider_data_path/modules); do
    npm install -g $npm_module
  done
}
