#!/bin/sh
_APPLICATION_NAME=status
[ ! -e /var/log/dnsmasq ] && _FEATURE_DNSMASQ_NO_ADDRESS_AVAILABLE_DISABLED=1
_DNSMASQ_NO_ADDRESS_AVAILABLE_LOG_FILE=$(find /var/log/dnsmasq -type f -name 'log-*.zst' -mtime -1)
