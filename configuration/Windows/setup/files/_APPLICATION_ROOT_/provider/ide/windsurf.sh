#!/bin/sh
case $APP_PLATFORM_PLATFORM in
Linux | FreeBSD)
  provider_path=~/.config/Windsurf
  provider_path_is_dir=1
  provider_include="User/keybindings.json User/settings.json"
  ;;
Apple)
  provider_path="$HOME/Library/Application Support/Windsurf"
  provider_path_is_dir=1
  provider_include="User/keybindings.json User/settings.json"
  ;;
esac
provider_no_root_user=1
_configuration_windsurf_export_post() {
  configuration_export_remove_home_refs
}
