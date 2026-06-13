#!/bin/sh
_update_reboot() {
  if [ -n "$_reboot_required" ]; then
    system=$_logging_context _system_alert "reboot is required" "$_reboot_required"
    if [ -n "$_first_boot" ]; then
      exec_wrap reboot
    else
      log_warn "not rebooting - $conf_system_maintenance_reboot"
      exit_with_success "please reboot to install updates [$_reboot_required]"
    fi
  fi
  unset _reboot_required
}
_create_be() {
  [ -n "$_on_jail" ] && {
    _create_be_jail "$1"
    return
  }
  _create_be_physical "$1"
}
_create_be_jail() {
  target_jail_snapshot=$_jail_volume@$1
  latest_jail_snapshot=$(zfs list -H -t snapshot $_jail_volume | tail -1 | awk {'print$1'})
  if [ "$latest_jail_snapshot" = "$target_jail_snapshot" ]; then
    log_info "jail snapshot ($target_jail_snapshot) already exists"
    return
  fi
  exec_wrap zfs snapshot $target_jail_snapshot
  if [ -n "$_first_boot" ]; then
    log_warn "initializing patch sequence: $_last_sequence_file"
    printf 'create-be\n' >$_last_sequence_file
    printf '%s\n' "$(date)" >>$_last_sequence_file
  fi
  for JAIL_UPDATE in $_system_updates; do
    _PATCH_${JAIL_UPDATE}
    [ -n "$_check_restart" ] && _patch_checkrestart
    unset _check_restart
  done
  date >>$_last_sequence_file
  _update_reboot
}
_create_be_physical() {
  if [ $(beadm list -H | awk {'print$1'} | grep -c $1) -lt 1 ]; then
    if [ -n "$_first_boot" ]; then
      log_warn "initializing patch sequence: $_last_sequence_file"
      printf 'create-be\n' >$_last_sequence_file
      printf '%s\n' "$(date)" >>$_last_sequence_file
      _reboot_required="First Boot, create BE"
    else
      _reboot_required="$_system_updates updates available"
    fi
    local securelevel=$(sysrc kern_securelevel_enable | awk {'print$2'})
    if [ "$securelevel" = "YES" ]; then
      sysrc kern_securelevel_enable=NO
      log_warn "todo: Please run sysrc kern_securelevel_enable=YES to re-enable securelevel"
    fi
    _update_host $1
    _update_reboot
  else
    log_warn "bE: $1 already exists."
  fi
}
_update_host() {
  exec_wrap beadm create $1
  exec_wrap beadm mount $1
  be_mount_point=$(mount | grep $1 | head -1 | awk {'print$3'})
  exec_wrap mount -t nullfs /usr/src $be_mount_point/usr/src
  $APP_PATH/apply_patches.expect $1 $_last_sequence_file "$_system_updates" $conf_system_maintenance_apply_patch_timeout
  warn_on_error=1 exec_wrap umount -f $be_mount_point/usr/src
  warn_on_error=1 exec_wrap beadm umount -f $1
  exec_wrap beadm activate $1
}
