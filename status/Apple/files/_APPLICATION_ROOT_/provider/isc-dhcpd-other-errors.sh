#!/bin/sh
set -a
_APPLICATION_NAME=status
if [ ! -e /var/log/dhcpd ]; then
  _FEATURE_ISC_DHCPD_OTHER_ERRORS_DISABLED=1
fi
_ISC_DHCPD_LOG_FILE=/var/log/dhcpd/log.0.zst
_isc_dhcpd_other_errors() {
  _isc_dhcpd_has_other_errors || return 0
  local message
  local dhcp_error
  for dhcp_error in $(zstdgrep -i err $_ISC_DHCPD_LOG_FILE | $_CONF_GNU_GREP -Pv '(DHCPDISCOVER|last message repeated)' |
    sed -e 's/.*\://' | sed -e 's/^ //' | sort -u); do
    instance=$(zstdgrep "$dhcp_error" $_ISC_DHCPD_LOG_FILE | sed -e 's/^.*.zst://' | awk {'printf "$dhcp_error %s %s %s\n", $1, $2, $3'})
    if [ -n "$message" ]; then
      message="$message\n$instance"
    else
      message="$instance"
    fi
  done
  [ "$message" ] && _STATUS_MESSAGE="$_STATUS_MESSAGE\n\nISC DHCPd - other errors\n$message"
  return 1
}
_isc_dhcpd_has_other_errors() {
  zstdgrep -i err $_ISC_DHCPD_LOG_FILE | $_CONF_GNU_GREP -Pv '(DHCPDISCOVER|last message repeated)' >/dev/null 2>&1
}
