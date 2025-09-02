#!/bin/sh
set -a
_APPLICATION_NAME=configuration
_PLUGIN_CONFIGURATION_PATH=~/.saferc
_PLUGIN_NO_ROOT_USER=1
_configure_vault_clear() {
  rm -f ~/.saferc ~/.svtoken
}
