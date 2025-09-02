#!/bin/sh
set -a
_APPLICATION_NAME=dev
_info "Starting godocs @ $_CONF_DEV_GODOC_PORT"
godoc -http=localhost:$_CONF_DEV_GODOC_PORT
