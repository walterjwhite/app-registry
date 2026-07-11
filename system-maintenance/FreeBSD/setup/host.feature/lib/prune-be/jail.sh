#!/bin/sh
_zfs_get_property() {
  zfs get -H $1 $2 | awk {'print$3'}
}
_zfs_snapshot_details() {
  zfs_snapshot_cr_dt=$(zfs get -H -p creation $jail_zfs_snapshot | awk {'print$3'})
  zfs_snapshot_age=$(($current_epoch_time - $zfs_snapshot_cr_dt))
  _time_seconds_to_human_readable $zfs_snapshot_age
  zfs_snapshot_age_human=$human_readable_time
  unset human_readable_time
}
_zfs_is_volume_jailed() {
  local zfs_mount_point=$(zfs list -H $zfs_volume | awk {'print$5'})
  if [ ! -e $zfs_mount_point ]; then
    log_warn "$zfs_volume appears to be jailed, skipping - $(zfs get -H jailed $zfs_volume | awk {'print$3'}))"
    return 0
  fi
  return 1
}
_zfs_system_pool() {
  zfs list -H | awk {'print$1'} | grep ROOT$ | sed -e 's/\/ROOT//'
}
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
_prune_jail_snapshot_destroy() {
  log_warn "destroying Jail Snapshot $_JAIL_ZFS_SNAPSHOT - created $_ZFS_SNAPSHOT_CR_DT ($_ZFS_SNAPSHOT_AGE_HUMAN)"
  zfs destroy $_JAIL_ZFS_SNAPSHOT
}
_prune_jail_snapshot_by_age() {
  log_info "pruning jail snapshots by age"
  for _JAIL_PATH in $(_get_jail_paths); do
    _jail_volume=$(_get_jail_volume $_JAIL_PATH)
    log_info "pruning jail snapshots for: $_jail_volume"
    for _JAIL_ZFS_SNAPSHOT in $(zfs list -H -t snapshot -o name $_jail_volume); do
      _zfs_snapshot_details
      if [ $_ZFS_SNAPSHOT_AGE -gt $conf_system_maintenance_jail_SNAPSHOT_EXPIRATION_PERIOD ]; then
        _prune_jail_snapshot_destroy
      else
        log_debug "retaining snapshot: $_JAIL_ZFS_SNAPSHOT $_ZFS_SNAPSHOT_CR_DT $_ZFS_SNAPSHOT_AGE_HUMAN"
      fi
      _jail_snapshot_cleanup
    done
  done
}
_prune_jail_snapshot_by_number() {
  if [ -z "$conf_system_maintenance_max_jail_snapshot_to_keep" ]; then
    return 1
  fi
  log_info "pruning jail snapshots by count"
  for _JAIL_PATH in $(_get_jail_paths); do
    _jail_volume=$(_get_jail_volume $_JAIL_PATH)
    log_info "pruning jail snapshots for: $_jail_volume"
    for _JAIL_ZFS_SNAPSHOT in $(zfs list -H -t snapshot -o name $_jail_volume | tail -r | tail -n +$conf_system_maintenance_max_jail_snapshot_to_keep | tail -r); do
      _zfs_snapshot_details
      _prune_jail_snapshot_destroy
      _jail_snapshot_cleanup
    done
  done
}
_jail_snapshot_cleanup() {
  unset _JAIL_ZFS_SNAPSHOT _ZFS_SNAPSHOT_CR_DT _ZFS_SNAPSHOT_AGE _ZFS_SNAPSHOT_AGE_HUMAN
}
