#!/bin/sh
_patch_checkrestart() {
  log_info "checkrestart - start"
  exec_wrap checkrestart -H $_checkrestart_options
  local service_options
  if [ -n "$_jail_name" ]; then
    service_options="-j $_jail_name"
  fi
  local check_restart_service
  for check_restart_service in $(checkrestart -H $_checkrestart_options | awk {'print$4'} | sort -u); do
    if [ -e /etc/rc.d/$check_restart_service ] || [ -e /usr/local/etc/rc.d/$check_restart_service ]; then
      log_warn "restarting $check_restart_service"
      service $service_options $check_restart_service restart
    else
      log_warn "$check_restart_service is not a service, but a cmd, manually restart"
    fi
  done
  if [ $(checkrestart -H $_checkrestart_options | wc -l) -gt 0 ]; then
    log_warn "checkrestart - restart system / services *REQUIRED*"
    _reboot_required=$(printf 'checkrestart - restart system / services *REQUIRED*\n%s\n%s\n' "checkrestart -H $_checkrestart_options" "$(checkrestart -H $_checkrestart_options)")
    _update_reboot
  fi
}
_patch_be() {
  log_info "updates available: $_system_updates"
  if [ -z "$_last_sequence" ]; then
    _last_sequence=$(seq -w 0 1 $conf_system_maintenance_max_patches | head -1)
  else
    _last_sequence=$(seq -w $_last_sequence 1 $conf_system_maintenance_max_patches | sed 1d | head -1)
  fi
  _system_be_with_sequence="$_system_be.$_last_sequence"
  _last_sequence_file=$_JAIL_PATH/usr/local/etc/walterjwhite/patches/$_last_sequence
  if [ -n "$_DRY_RUN" ]; then
    log_info "printf '%s\n' \"$_system_updates\" > $_last_sequence_file"
  else
    printf '%s\n' "$_system_updates" >$_last_sequence_file
  fi
  _create_be $_system_be_with_sequence
}
_update_patch() {
  log_detail "$conf_log_header"
  log_detail "inspecting"
  _be_init
  _wait_network
  log_info "checking if additional updates are available"
  _has_updates || {
    log_info "no updates available"
    printf '\n\n'
    return
  }
  log_warn "updates detected: [$_system_updates]"
  _patch_be
  log_info "completed patching"
  printf '\n\n'
}
