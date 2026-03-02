#!/bin/sh
_conf_datagrip_get_directory() {
  case $_ACTION in
  backup)
    provider_path=$(find "$1" -maxdepth 1 -type d -name 'DataGrip*' 2>/dev/null)
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
  provider_include="keymaps workspace options"
}
case $APP_PLATFORM_PLATFORM in
Windows)
  _conf_datagrip_get_directory ~/AppData
  ;;
Apple)
  _conf_datagrip_get_directory ~/Library/"Application Support"/JetBrains
  ;;
Linux | FreeBSD)
  _conf_datagrip_get_directory ~/.config/JetBrains
  ;;
esac
provider_no_root_user=1
