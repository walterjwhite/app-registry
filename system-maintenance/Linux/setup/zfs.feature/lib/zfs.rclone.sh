#!/bin/sh
_zfs_rclone() {
  for _ZFS_VOLUME in $(zfs list -H | awk {'print$1'}); do
    _rclone_target=$(_zfs_get_property rclone:target $_ZFS_VOLUME)
    [ "$_rclone_target" = "-" ] && continue
    log_info "rclone - [$_rclone_target]"
    log_detail "rclone - $_rclone_target:$_ZFS_VOLUME - $1 - start"
    zfs_rclone_$1
    log_detail "rclone - $_rclone_target:$_ZFS_VOLUME - $1 - end [$?]"
  done
}
