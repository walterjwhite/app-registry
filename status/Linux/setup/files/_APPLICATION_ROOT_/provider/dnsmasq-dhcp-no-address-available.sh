#!/bin/sh
status_dnsmasq_dhcp_no_address_available() {
  [ ! -e /var/log/dnsmasq ] && {
    return 1
  }
  readonly DNSMASQ_NO_ADDRESS_AVAILABLE_LOG_FILE=$(find /var/log/dnsmasq -type f -name 'log-*.zst' -mtime -1)
  _dnsmasq_dhcp_has_no_address_available || return 0
  local dhcp_device
  local instance
  for dhcp_device in $(zstdgrep 'no address available' $DNSMASQ_NO_ADDRESS_AVAILABLE_LOG_FILE | awk {'print$7'} | sort -u); do
    instance=$(zstdgrep $dhcp_device $DNSMASQ_NO_ADDRESS_AVAILABLE_LOG_FILE | awk {'printf "%-12s %s %s %s\n", $7, $1, $2, $3'})
    if [ -n "$_status_message" ]; then
      _status_message="$_status_message\n$instance"
    else
      _status_message="$instance"
    fi
  done
  [ "$_status_message" ] && {
    return 2
  }
}
_dnsmasq_dhcp_has_no_address_available() {
  zstdgrep -cqm1 'no address available' $DNSMASQ_NO_ADDRESS_AVAILABLE_LOG_FILE >/dev/null 2>&1
}
