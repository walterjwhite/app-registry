#!/bin/sh
case $APP_PLATFORM_PLATFORM in
Linux | FreeBSD)
  provider_path=${alt_path}$HOME
  ;;
Apple)
  provider_path="${alt_path}$HOME/Library/Application Support/Devin"
  ;;
Windows)
  provider_path="${alt_path}$HOME/AppData/Roaming/Devin"
  ;;
esac
provider_path_is_dir=1
provider_include=".config/devin/config.json .local/share/devin/cli/trusted_workspaces.json .local/share/devin/credentials.toml"
provider_no_root_user=1
