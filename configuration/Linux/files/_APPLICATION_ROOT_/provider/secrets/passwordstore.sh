#!/bin/sh
set -a
_APPLICATION_NAME=configuration
_PLUGIN_CONFIGURATION_PATH=~/.password-store
_PLUGIN_CONFIGURATION_PATH_IS_DIR=1
_PLUGIN_NO_ROOT_USER=1
_configure_passwordstore_backup() {
  if [ $(git -C "$_PLUGIN_CONFIGURATION_PATH" remote -v | wc -l) -eq 0 ]; then
    _warn "No git remotes exist"
    return 1
  fi
  rm -rf "$_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME"
  mkdir -p $_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME
  git -C "$_PLUGIN_CONFIGURATION_PATH" remote -v >$_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME/git
}
_configure_passwordstore_restore() {
  if [ ! -e $_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME/git ]; then
    return 1
  fi
  rm -rf "$_PLUGIN_CONFIGURATION_PATH"
  git clone $(head -1 $_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME/git | awk {'print$2'}) "$_PLUGIN_CONFIGURATION_PATH" >/dev/null 2>&1
}
