#!/bin/sh
_conf_mongodb_compass_get_directory() {
  case $_ACTION in
  backup)
    provider_path=$(find "$1" -maxdepth 1 -type d -name 'MongoDB*' 2>/dev/null | head -1)
    if [ -z "$provider_path" ]; then
      provider_path=$(find "$1" -maxdepth 1 -type d -name '*compass*' 2>/dev/null | head -1)
    fi
    if [ -z "$provider_path" ]; then
      unset provider_path
      return
    fi
    printf '%s\n' "$provider_path" >$provider_data_path/.version
    ;;
  restore)
    provider_path=$(head -1 $provider_data_path/.version 2>/dev/null)
    ;;
  esac
  provider_path_is_dir=1
  provider_include="Storage Preferences"
}
case $APP_PLATFORM_PLATFORM in
Windows)
  _conf_mongodb_compass_get_directory ${alt_path}$HOME/AppData/Roaming
  ;;
Apple)
  _conf_mongodb_compass_get_directory ${alt_path}$HOME/Library/"Application Support"
  ;;
Linux | FreeBSD)
  if [ -n "$XDG_CONFIG_HOME" ]; then
    _conf_mongodb_compass_get_directory "${alt_path}$XDG_CONFIG_HOME"
  else
    _conf_mongodb_compass_get_directory ${alt_path}$HOME/.config
  fi
  ;;
esac
provider_no_root_user=1
_configuration_mongodb_compass_backup_post() {
  find "$provider_data_path" -type f -name "*.log" -delete 2>/dev/null || true
  find "$provider_data_path" -type f -name "*.tmp" -delete 2>/dev/null || true
  find "$provider_data_path" -type f -name "session*" -delete 2>/dev/null || true
  find "$provider_data_path" -type d -name "Cache" -exec rm -rf {} + 2>/dev/null || true
  find "$provider_data_path" -type d -name "CachedData" -exec rm -rf {} + 2>/dev/null || true
}
