#!/bin/sh
_APPLICATION_NAME=dev
_INFO "Starting godocs @ $_CONF_DEV_GODOC_PORT"
godoc -http=localhost:$_CONF_DEV_GODOC_PORT
