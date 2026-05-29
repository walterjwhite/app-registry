#!/bin/sh
_APPLICATION_NAME=status
_ETC_ETHERS_FILE=/etc/ethers
if [ ! -e $_ETC_ETHERS_FILE ]; then
	_FEATURE_WIFI_HANDSHAKE_DISABLED=1
fi
_WIFI_HANDSHAKE_LOG_FILE=$(find /var/log/messages -type f -name '*.zst' -mtime -1 | tail -1)
