#!/bin/sh
_conf_oracle_sql_developer_get_directory() {
  case $_ACTION in
  backup)
    provider_path=$(find "$1" -maxdepth 1 -type d -name 'SQLDeveloper*' 2>/dev/null | head -1)
    if [ -z "$provider_path" ]; then
      provider_path=$(find "$1" -maxdepth 1 -type d -name '*sqldeveloper*' 2>/dev/null | head -1)
    fi
    if [ -z "$provider_path" ]; then
      provider_path=$(find "$1" -maxdepth 2 -type d -name 'sqldeveloper' 2>/dev/null | head -1)
    fi
    if [ -z "$provider_path" ]; then
      unset provider_path
      return
    fi
    printf '%s\n' "$provider_path" >$APP_DATA_PATH/$provider_name/.version
    ;;
  restore)
    provider_path=$(head -1 $APP_DATA_PATH/$provider_name/.version 2>/dev/null)
    ;;
  esac
  provider_path_is_dir=1
  provider_include="product.conf connections.xml preferences.xml"
}
case $APP_PLATFORM_PLATFORM in
Windows)
  _conf_oracle_sql_developer_get_directory ~/AppData/Roaming
  ;;
Apple)
  _conf_oracle_sql_developer_get_directory ~/Library/"Application Support"
  ;;
Linux | FreeBSD)
  if [ -n "$XDG_CONFIG_HOME" ]; then
    _conf_oracle_sql_developer_get_directory "$XDG_CONFIG_HOME"
  else
    _conf_oracle_sql_developer_get_directory ~/.config
  fi
  if [ -z "$provider_path" ]; then
    _conf_oracle_sql_developer_get_directory ~/.sqldeveloper
  fi
  ;;
esac
provider_no_root_user=1
_configuration_oracle_sql_developer_backup_post() {
  find "$APP_DATA_PATH/$provider_name" -type f -name "*.log" -delete 2>/dev/null || true
  find "$APP_DATA_PATH/$provider_name" -type f -name "*.tmp" -delete 2>/dev/null || true
  find "$APP_DATA_PATH/$provider_name" -type f -name "session*" -delete 2>/dev/null || true
  find "$APP_DATA_PATH/$provider_name" -type d -name "Cache" -exec rm -rf {} + 2>/dev/null || true
  find "$APP_DATA_PATH/$provider_name" -type d -name "CachedData" -exec rm -rf {} + 2>/dev/null || true
  find "$APP_DATA_PATH/$provider_name" -type d -name "cache" -exec rm -rf {} + 2>/dev/null || true
  find "$APP_DATA_PATH/$provider_name" -type d -name "system*" -exec rm -rf {} + 2>/dev/null || true
  find "$APP_DATA_PATH/$provider_name" -type d -name "jre" -exec rm -rf {} + 2>/dev/null || true
  find "$APP_DATA_PATH/$provider_name" -type d -name "drop" -exec rm -rf {} + 2>/dev/null || true
  find "$APP_DATA_PATH/$provider_name" -type f -name "*.class" -delete 2>/dev/null || true
  find "$APP_DATA_PATH/$provider_name" -type f -name "*.jar" -delete 2>/dev/null || true
  find "$APP_DATA_PATH/$provider_name" -type f -name "*.idx" -delete 2>/dev/null || true
  find "$APP_DATA_PATH/$provider_name" -type d -name "SecureStorage" -exec rm -rf {} + 2>/dev/null || true
  find "$APP_DATA_PATH/$provider_name" -type f -name "connections.xml" -delete 2>/dev/null || true
}
