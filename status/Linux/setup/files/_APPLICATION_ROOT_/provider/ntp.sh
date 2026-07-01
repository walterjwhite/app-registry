#!/bin/sh
status_ntp() {
  local ntp_status
  case $conf_status_ntp_provider in
  systemd-timedatectl)
    _systemd_timedatectl_status
    ntp_status=$?
    ;;
  ntpq)
    _ntpq_status
    ntp_status=$?
    ;;
  disabled)
    return 1
    ;;
  *)
    log_warn "unknown provider: $conf_status_ntp_provider"
    return 1
    ;;
  esac
  case $ntp_status in
  0)
    _status_message="NTP synchronized"
    ;;
  1)
    _status_message="NTP is disabled"
    ;;
  2)
    _status_message="NTP NOT synchronized"
    ;;
  esac
}
_systemd_timedatectl_status() {
  timedatectl |
    grep 'System clock synchronized: yes' -A10 -B10 |
    grep -cqm1 'NTP service: active'
}
_ntpq_status() {
  command -v ntpq >/dev/null 2>&1 || return 1
  ntpq -pn 2>/dev/null | grep '^\*' >/dev/null 2>&1 && {
    return 0
  }
  return 2
}
_chronyc_status() {
  :
}
