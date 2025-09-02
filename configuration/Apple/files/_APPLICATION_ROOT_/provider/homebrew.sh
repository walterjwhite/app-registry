#!/bin/sh
set -a
_APPLICATION_NAME=configuration
_PLUGIN_CONFIGURATION_PATH=/opt/homebrew
_PLUGIN_CONFIGURATION_PATH_IS_DIR=1
_configure_homebrew_restore() {
  if [ ! -e $_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME/homebrew ]; then
    return
  fi
  brew install $(cat $_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME/homebrew)
  return 0
}
_configure_homebrew_backup() {
  rm -f $_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME/homebrew
  brew bundle dump --file=$_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME/homebrew
  return 0
}
