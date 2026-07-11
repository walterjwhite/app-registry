#!/bin/sh
status_isc_dhcpd_other_errors() {
  [ ! -e /var/log/dhcpd ] && return 1
  readonly ISC_DHCPD_LOG_FILE=/var/log/dhcpd/log.0.zst
  _isc_dhcpd_has_other_errors || return 0
  local message
  local dhcp_error
  for dhcp_error in $(zstdgrep -i err $ISC_DHCPD_LOG_FILE | $GNU_GREP -Pv '(DHCPDISCOVER|last message repeated)' |
    sed -e 's/.*\://' | sed -e 's/^ //' | sort -u); do
    instance=$(zstdgrep "$dhcp_error" $ISC_DHCPD_LOG_FILE | sed -e 's/^.*.zst://' | awk -v err="$dhcp_error" '{printf "%s %s %s %s\n", err, $1, $2, $3}')
    if [ -n "$message" ]; then
      message="$message\n$instance"
    else
      message="$instance"
    fi
  done
  [ "$message" ] && _status_message="$_status_message\n\nISC DHCPd - other errors\n$message"
  return 1
}
_isc_dhcpd_has_other_errors() {
  zstdgrep -i err $ISC_DHCPD_LOG_FILE | $GNU_GREP -Pv '(DHCPDISCOVER|last message repeated)' >/dev/null 2>&1
}
