#!/bin/sh
_wireguard_client_run() {
  log_info "setting up wireguard client connection: $conf_vpn_wireguard_interface"
  sudo_run wg-quick up $conf_vpn_wireguard_interface || exit_with_error "failed to start $conf_vpn_wireguard_interface"
  exit_defer _wireguard_client_cleanup
  log_add_context "while"
  while :; do
    log_detail "monitoring wireguard client connection: $conf_vpn_wireguard_interface"
    sudo_run wg | grep -cqm1 "interface: $conf_vpn_wireguard_interface" || exit_with_error "$conf_vpn_wireguard_interface is no longer up"
    sleep $conf_vpn_wireguard_client_check_interval
  done
  log_remove_context
}
_wireguard_client_cleanup() {
  sudo_run wg-quick down $conf_vpn_wireguard_interface
}
