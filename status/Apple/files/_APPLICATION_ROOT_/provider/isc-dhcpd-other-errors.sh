#!/bin/sh
_APPLICATION_NAME=status
if [ ! -e /var/log/dhcpd ]; then
	_FEATURE_ISC_DHCPD_OTHER_ERRORS_DISABLED=1
fi
_ISC_DHCPD_LOG_FILE=/var/log/dhcpd/log.0.zst
