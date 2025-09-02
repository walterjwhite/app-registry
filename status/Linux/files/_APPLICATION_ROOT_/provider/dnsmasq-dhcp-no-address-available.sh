#!/bin/sh
set -a
_APPLICATION_NAME=status
[ ! -e /var/log/dnsmasq ] && _FEATURE_DNSMASQ_NO_ADDRESS_AVAILABLE_DISABLED=1
_DNSMASQ_NO_ADDRESS_AVAILABLE_LOG_FILE=$(find /var/log/dnsmasq -type f -name 'log-*.zst' -mtime -1)
_dnsmasq_dhcp_no_address_available() {
  _dnsmasq_dhcp_has_no_address_available || return 0
  local message
  local dhcp_device
  local instance
  for dhcp_device in $(zstdgrep 'no address available' $_DNSMASQ_NO_ADDRESS_AVAILABLE_LOG_FILE | awk {'print$7'} | sort -u); do
    instance=$(zstdgrep $dhcp_device $_DNSMASQ_NO_ADDRESS_AVAILABLE_LOG_FILE | awk {'printf "%-12s %s %s %s\n", $7, $1, $2, $3'})
    if [ -n "$message" ]; then
      message="$message\n$instance"
    else
      message="$instance"
    fi
  done
  [ "$message" ] && {
    _STATUS_MESSAGE="$_STATUS_MESSAGE\n\nDnsmasq - no address available\n$message"
    return 1
  }
}
_dnsmasq_dhcp_has_no_address_available() {
  zstdgrep 'no address available' $_DNSMASQ_NO_ADDRESS_AVAILABLE_LOG_FILE >/dev/null 2>&1
}
