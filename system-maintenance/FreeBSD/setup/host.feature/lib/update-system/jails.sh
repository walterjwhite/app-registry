#!/bin/sh
_jail_get_jail_paths() {
  grep 'path = ' /etc/jail.conf /etc/jail.conf.d -rh 2>/dev/null | awk -F'=' '{print$2}' | tr -d ' ;"' | sort -u
}
_jail_get_jail_volume() {
  zfs list -H | grep "${1}$" | awk '{print$1}'
}
_jail_in_jail() {
  [ "$(sysctl -n security.jail.jailed)" -eq 1 ] && return 0
  return 1
}
_patch_jails() {
  _logging_context=jail
  log_info "inspecting"
  _on_jail=1
  for _JAIL_PATH in $(_get_jail_paths); do
    _jail_volume=$(_get_jail_volume $_JAIL_PATH)
    _jail_name=$(basename $_jail_volume)
    _logging_context=jail.$_jail_name
    _freebsd_update_options="-j $_jail_name"
    _pkg_update_options="-j $_jail_name"
    _checkrestart_options="-j $_jail_name"
    conf_system_maintenance_patch_types="FREEBSD_UPGRADE USERLAND FREEBSD"
    _update_patch
  done
}
