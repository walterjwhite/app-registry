#!/bin/sh
which ghostty >/dev/null 2>&1 || {
  return
}
_PLUGIN_CONFIGURATION_PATH=~/.config/ghostty/config
_PLUGIN_NO_ROOT_USER=1
