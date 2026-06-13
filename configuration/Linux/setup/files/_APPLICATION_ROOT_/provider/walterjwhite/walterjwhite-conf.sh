#!/bin/sh
provider_path=${alt_path}$HOME/.config/walterjwhite
provider_path_is_dir=1
_configuration_walterjwhite_conf_restore_post() {
  _configuration_walterjwhite_xdg_defaults
  _configuration_walterjwhite_scripts
}
_configuration_walterjwhite_xdg_defaults() {
  case $APP_PLATFORM_PLATFORM in
  FreeBSD | Linux) ;;
  *)
    return 1
    ;;
  esac
  [ ! -e ${alt_path}$HOME/.config/walterjwhite/shell/xdg-open-defaults ] && return 2
  local application
  local filetype
  for application in $(ls ${alt_path}$HOME/.config/walterjwhite/shell/xdg-open-defaults); do
    log_info "setting defaults for $application"
    while read filetype; do
      log_info "setting default: $application -> $filetype"
      xdg-mime default $application $filetype
    done <${alt_path}$HOME/.config/walterjwhite/shell/xdg-open-defaults/$application
  done
}
_configuration_walterjwhite_scripts() {
  local script
  for script in $(find ${alt_path}$HOME/.config/walterjwhite/shell/scripts -type f 2>/dev/null); do
    log_info "running script $(basename $script)"
    . $script
  done
}
