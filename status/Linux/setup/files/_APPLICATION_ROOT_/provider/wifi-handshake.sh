#!/bin/sh
status_wifi_handshake() {
  [ ! -e /etc/ethers ] && return 1
  readonly WIFI_HANDSHAKE_LOG_FILE=$(find /var/log/messages -type f -name '*.zst' -mtime -1 | tail -1)
  local device
  local instance
  for device in $(zstdgrep 'hostapd' $WIFI_HANDSHAKE_LOG_FILE | $GNU_GREP -P \
    '(AP-STA-CONNECTED|AP-STA-DISCONNECTED|EAPOL-4WAY-HS-COMPLETED|STA|STA-OPMODE-N_SS-CHANGED|STA-OPMODE-SMPS-MODE-CHANGED|Prune)' |
    $GNU_GREP -Po '[a-f0-9]{2}\:[a-f0-9]{2}\:[a-f0-9]{2}\:[a-f0-9]{2}\:[a-f0-9]{2}\:[a-f0-9]{2}' | sort -u); do
    grep -cq "$device" /etc/ethers && continue
    instance=$(zstdgrep $device $WIFI_HANDSHAKE_LOG_FILE | grep hostapd | awk {'printf "%-30s %s %s %s [%s]\n", $8, $1, $2, $3, $5'} | sed -e s/^/$device\ /)
    if [ -n "$_status_message" ]; then
      _status_message="$_status_message\n$instance"
    else
      _status_message="$instance"
    fi
  done
  [ "$_status_message" ] && {
    return 2
  }
  return 0
}
