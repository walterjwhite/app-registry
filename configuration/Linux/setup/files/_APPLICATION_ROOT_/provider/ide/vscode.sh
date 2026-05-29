#!/bin/sh
case $APP_PLATFORM_PLATFORM in
Linux | FreeBSD)
  provider_path=${alt_path}$HOME/.config/"Code"
  ;;
Apple)
  provider_path="${alt_path}$HOME/Library/Application Support/Code"
  ;;
Windows)
  provider_path="${alt_path}$HOME/AppData/Roaming/Code"
  ;;
esac
provider_path_is_dir=1
provider_include="User/keybindings.json User/settings.json"
provider_no_root_user=1
_configuration_vscode_export_post() {
  configuration_export_remove_home_refs
}
