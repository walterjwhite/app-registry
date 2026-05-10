#!/bin/sh
provider_path=~/.config/Antigravity
provider_path_is_dir=1
provider_include="User/settings.json User/keybindings.json"
provider_no_root_user=1
_configuration_google_antigravity_export_post() {
  configuration_export_remove_home_refs
}
