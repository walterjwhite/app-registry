#!/bin/sh
case $APP_PLATFORM_PLATFORM in
Linux | FreeBSD)
  provider_path=${alt_path}$HOME/.config/Kiro
  ;;
Apple)
  provider_path="${alt_path}$HOME/Library/Application Support/Kiro"
  ;;
Windows)
  provider_path="${alt_path}$HOME/AppData/Roaming/Kiro"
  ;;
esac
provider_path_is_dir=1
provider_include="User/keybindings.json User/settings.json"
provider_no_root_user=1
_configuration_kiro_export_post() {
  configuration_export_remove_home_refs
}
