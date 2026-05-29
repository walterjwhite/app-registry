#!/bin/sh
_APPLICATION_NAME=status
_zfs_get_property() {
	zfs get -H $1 $2 | awk {'print$3'}
}
which zfs >/dev/null 2>&1 || _FEATURE_ZAP_DISABLED=1
zap() {
	local message
	for _ZFS_VOLUME in $(zfs list -H | awk {'print$1'}); do
		local zap_managed=$(_zfs_get_property zap:snap $_ZFS_VOLUME | grep -c on)
		if [ "$zap_managed" -gt 0 ]; then
			_ZAP_BACKUP_SCHEDULE=$(_zfs_get_property zap:backup $_ZFS_VOLUME)
			local snapshot_age
			case $_ZAP_BACKUP_SCHEDULE in
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
			local latest_snapshot_expiration_friendly=$(date -j -f '%s' $latest_snapshot_expiration "+$_CONF_INSTALL_DATE_FORMAT")
			local now=$(date +%s)
			if [ $latest_snapshot_expiration -lt $now ]; then
				message="$message\nLatest snapshot ($latest_snapshot) [$_ZAP_BACKUP_SCHEDULE] > ($latest_snapshot_expiration_friendly)"
			fi
		fi
	done
	if [ -n "$message" ]; then
		_STATUS_MESSAGE="$message"
		return 1
	fi
}
