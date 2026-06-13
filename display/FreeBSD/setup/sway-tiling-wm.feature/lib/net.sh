#!/bin/sh
_get_non_local_ips() {
  ifconfig | awk '/inet / && !/127.0.0.1/ {print $2}'
}
