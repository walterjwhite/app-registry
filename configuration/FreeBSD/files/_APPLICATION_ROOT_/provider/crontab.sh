#!/bin/sh
set -a
_APPLICATION_NAME=configuration
case $_PLATFORM in
Linux | FreeBSD | Apple)
  _PLUGIN_CONFIGURATION_PATH=~/.config
  _PLUGIN_CONFIGURATION_PATH_IS_DIR=1
  _PLUGIN_CONFIGURATION_PATH_IS_SKIP_PREPARE=1
  ;;
esac
_configure_crontab_backup() {
  crontab -l >$_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME/data
  return 0
}
_configure_crontab_restore() {
  if [ $(wc -l $_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME/data | awk {'print$1'}) -gt 0 ]; then
    EDITOR=crontab-editor CRONTAB=$_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME/data crontab -e >/dev/null 2>&1
  else
    _warn 'No crontab'
  fi
  return 0
}
_configure_crontab_clear() {
  crontab -rf
  return 0
}
