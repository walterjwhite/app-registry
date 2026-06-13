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
status_zap() {
  which zfs >/dev/null 2>&1 || return 1
  local message
  for _ZFS_VOLUME in $(zfs list -H | awk {'print$1'}); do
    local zap_managed=$(_zfs_get_property zap:snap $_ZFS_VOLUME | grep -c on)
    if [ "$zap_managed" -gt 0 ]; then
      local _zap_backup_schedule=$(_zfs_get_property zap:backup $_ZFS_VOLUME)
      local snapshot_age
      case $_zap_backup_schedule in
      daily)
        snapshot_age=$((1 * 60 * 60 * 24))
        snapshot_age=$(($snapshot_age + 8 * 60 * 60))
        ;;
      weekly)
        snapshot_age=$((7 * 60 * 60 * 24))
        snapshot_age=$(($snapshot_age + 1 * 60 * 60 * 24))
        ;;
      monthly)
        snapshot_age=$((30 * 60 * 60 * 24))
        snapshot_age=$(($snapshot_age + 3 * 60 * 60 * 24))
        ;;
      *)
        continue
        ;;
      esac
      local latest_snapshot=$(zfs list -t snapshot $_ZFS_VOLUME | tail -1 | awk {'print$1'})
      local latest_snapshot_date=$(printf '%s' "$latest_snapshot" | cut -f2 -d'@' | sed -e 's/.*_//' -e 's/--.*//' -e 's/-[[:digit:]]\{4\}//')
      local latest_snapshot_date_epoch=$(date -j -f '%Y-%m-%dT%H:%M:%S' "$latest_snapshot_date" +%s)
      local latest_snapshot_expiration=$(($latest_snapshot_date_epoch + $snapshot_age))
      local latest_snapshot_expiration_friendly=$(date -j -f '%s' $latest_snapshot_expiration "+$conf_install_DATE_FORMAT")
      local now=$(date +%s)
      if [ $latest_snapshot_expiration -lt $now ]; then
        message="$message\nLatest snapshot ($latest_snapshot) [$_zap_backup_schedule] > ($latest_snapshot_expiration_friendly)"
      fi
    fi
  done
  if [ -n "$message" ]; then
    _status_message="$message"
    return 1
  fi
}
