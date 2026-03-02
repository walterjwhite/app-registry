#!/bin/sh
_wireguard_private_key() {
  wg genkey
}
_wireguard_public_key() {
  cat - | wg pubkey
}
_wireguard_new_server() {
  sudo_run mkdir -p $conf_vpn_wireguard_conf_dir
  local _wg_server_private_key=$(_wireguard_private_key)
  local _wg_server_public_key=$(_wireguard_public_key "$_wg_server_private_key")
  printf '%s' "$_wg_server_private_key" | _write $conf_vpn_wireguard_conf_dir/privatekey
  printf '%s' "$_wg_server_public_key" | _write $conf_vpn_wireguard_conf_dir/publickey
  printf '
    [Interface]
    PrivateKey = %s
    Address = %s
    ListenPort = %s
    ' "$_wg_server_private_key" "$conf_vpn_wireguard_server_address" $conf_vpn_wireguard_listen_port |
    _write $conf_vpn_wireguard_conf_dir/$conf_vpn_wireguard_interface.conf
}
_wireguard_add_peer() {
  printf '
    [Peer]
    PublicKey = %s
    AllowedIPs = %s
    ' "$1" "$2" $3 |
    _write_append $conf_vpn_wireguard_conf_dir/$conf_vpn_wireguard_interface.conf
}
_wireguard_new_client() {
  local _wg_client_private_key=$(_wireguard_private_key)
  local _wg_client_public_key=$(_wireguard_public_key "$_wg_client_private_key")
  _wg_server_public_key=$(head -1 $conf_vpn_wireguard_conf_dir/publickey)
  _wireguard_add_peer "$_WG_CLIENT_NAME" "$_wg_client_public_key" "$_WG_CLIENT_IP_CIDR"
  printf '
    [Interface]
    Address = %s
    PrivateKey = %s
    [Peer]
    AllowedIPs = 0.0.0.0/0
    Endpoint = %s:%s
    PersistentKeepalive = %s
    PublicKey = %s
    ' "$_WG_CLIENT_IP_CIDR" "$_wg_client_private_key" \
    "TO-BE-PROVIDED" $conf_vpn_wireguard_listen_port $conf_vpn_wireguard_persistent_keep_alive \
    "$_wg_server_public_key"
}
