#!/bin/sh
case $APP_PLATFORM_PLATFORM in
Linux | FreeBSD)
  provider_path=${alt_path}$HOME/.config/Antigravity
  ;;
Apple)
  provider_path="${alt_path}$HOME/Library/Application Support/Antigravity"
  ;;
Windows)
  provider_path="${alt_path}$HOME/AppData/Roaming/Antigravity"
  ;;
esac
provider_path_is_dir=1
provider_include="User/settings.json User/keybindings.json"
provider_no_root_user=1
_configuration_google_antigravity_export_post() {
  configuration_export_remove_home_refs
}
