#!/bin/sh
case $APP_PLATFORM_PLATFORM in
Linux | FreeBSD)
  provider_path=${alt_path}$HOME/.config/Windsurf
  ;;
Apple)
  provider_path="${alt_path}$HOME/Library/Application Support/Windsurf"
  ;;
Windows)
  provider_path="${alt_path}$HOME/AppData/Roaming/Windsurf"
  ;;
esac
provider_path_is_dir=1
provider_include="User/keybindings.json User/settings.json"
provider_no_root_user=1
_configuration_windsurf_export_post() {
  configuration_export_remove_home_refs
}
