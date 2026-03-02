#!/bin/sh
_ETC_ETHERS_FILE=/etc/ethers
if [ ! -e $_ETC_ETHERS_FILE ]; then
  _FEATURE_WIFI_HANDSHAKE_DISABLED=1
fi
_WIFI_HANDSHAKE_LOG_FILE=$(find /var/log/messages -type f -name '*.zst' -mtime -1 | tail -1)
_wifi_handshake() {
  local message
  local device
  local instance
  for device in $(zstdgrep 'hostapd' $_WIFI_HANDSHAKE_LOG_FILE | $_CONF_GNU_GREP -P \
    '(AP-STA-CONNECTED|AP-STA-DISCONNECTED|EAPOL-4WAY-HS-COMPLETED|STA|STA-OPMODE-N_SS-CHANGED|STA-OPMODE-SMPS-MODE-CHANGED|Prune)' |
    $_CONF_GNU_GREP -Po '[a-f0-9]{2}\:[a-f0-9]{2}\:[a-f0-9]{2}\:[a-f0-9]{2}\:[a-f0-9]{2}\:[a-f0-9]{2}' | sort -u); do
    grep -cq "$device" $_ETC_ETHERS_FILE && continue
    instance=$(zstdgrep $device $_WIFI_HANDSHAKE_LOG_FILE | grep hostapd | awk {'printf "%-30s %s %s %s [%s]\n", $8, $1, $2, $3, $5'} | sed -e s/^/$device\ /)
    if [ -n "$message" ]; then
      message="$message\n$instance"
    else
      message="$instance"
    fi
  done
  [ "$message" ] && {
    _STATUS_MESSAGE="$_STATUS_MESSAGE\n\nWifi - Handshake (unregistered devices)\n$message\n"
    return 1
  }
  return 0
}
