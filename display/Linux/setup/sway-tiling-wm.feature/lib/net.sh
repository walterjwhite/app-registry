#!/bin/sh
_get_non_local_ips() {
  ip -4 -br addr show | sed -e '1d' -e 's/ $//' | awk {'print$1" "$2" "$3'} | tr '\n' ' '
}
