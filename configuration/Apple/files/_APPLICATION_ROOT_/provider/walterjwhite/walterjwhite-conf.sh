#!/bin/sh
set -a
_APPLICATION_NAME=configuration
_PLUGIN_CONFIGURATION_PATH=~/.config/walterjwhite
_PLUGIN_CONFIGURATION_PATH_IS_DIR=1
_configure_walterjwhite_conf_restore_post() {
  _configure_walterjwhite_xdg_defaults
  _configure_walterjwhite_scripts
}
_configure_walterjwhite_xdg_defaults() {
  case $_PLATFORM in
  FreeBSD | Linux) ;;
  *)
    return 1
    ;;
  esac
  if [ ! -e ~/.config/walterjwhite/xdg-open-defaults ]; then
    return 2
  fi
  local application
  local filetype
  for application in $(ls ~/.config/walterjwhite/xdg-open-defaults); do
    _info "Setting defaults for $application"
    while read filetype; do
      _info "setting default: $application -> $filetype"
      xdg-mime default $application $filetype
    done <~/.config/walterjwhite/xdg-open-defaults/$application
  done
}
_configure_walterjwhite_scripts() {
  local script
  for script in $(find ~/.config/walterjwhite/scripts -type f 2>/dev/null); do
    _info "Running script $(basename $script)"
    . $script
  done
}
