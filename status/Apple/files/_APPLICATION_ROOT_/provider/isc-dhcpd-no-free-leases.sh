#!/bin/sh
set -a
_APPLICATION_NAME=status
if [ ! -e /var/log/dhcpd ]; then
  _FEATURE_ISC_DHCPD_NO_FREE_LEASES_DISABLED=1
fi
_ISC_DHCPD_LOG_FILE=/var/log/dhcpd/log.0.zst
_isc_dhcpd_no_free_leases() {
  _isc_dhcpd_has_no_free_leases || return 0
  local message
  local dhcp_device
  local instance
  for dhcp_device in $(zstdgrep 'no free leases' $_ISC_DHCPD_LOG_FILE | awk {'print$9'} | sort -u); do
    instance=$(zstdgrep $dhcp_device $_ISC_DHCPD_LOG_FILE | awk {'printf "%-12s %-17s %s %s %s\n", $7, $9, $1, $2, $3'} | sed -e s/^$dhcp_device\ //)
    if [ -n "$message" ]; then
      message="$message\n$instance"
    else
      message="$instance"
    fi
  done
  [ "$message" ] && {
    _STATUS_MESSAGE="$_STATUS_MESSAGE\n\nISC DHCPd - no free leases\n$message"
    return 1
  }
}
_isc_dhcpd_has_no_free_leases() {
  zstdgrep 'no free leases' $_ISC_DHCPD_LOG_FILE >/dev/null 2>&1
}
