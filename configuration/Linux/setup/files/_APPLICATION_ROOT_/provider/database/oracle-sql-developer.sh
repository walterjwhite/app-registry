#!/bin/sh
case $APP_PLATFORM_PLATFORM in
Windows)
  provider_path="${alt_path}$HOME/AppData/Roaming/SQL Developer"
  ;;
Apple)
  provider_path="${alt_path}$HOME/Library/Application Support/SQL Developer"
  ;;
Linux | FreeBSD)
  if [ -n "$XDG_CONFIG_HOME" ]; then
    provider_path="${alt_path}$XDG_CONFIG_HOME/SQL Developer"
  else
    provider_path="${alt_path}$HOME/.config/SQL Developer"
  fi
  if [ -z "$provider_path" ]; then
    provider_path="${alt_path}$HOME/.sqldeveloper"
  fi
  ;;
esac
provider_no_root_user=1
provider_path_is_dir=1
if [ "$action" = "backup" ]; then
  log_warn "generating include:"
  if [ ! -e "$provider_path" ]; then
    log_warn "provider path does not exist: $provider_path"
    return 1
  fi
  local opwd=$PWD
  cd "$provider_path" || exit_with_error "unable to enter provider_path: $provider_path"
  provider_include=$(find . -type f \( \
    -name "connections*" -o \
    -name "*preferences*" -o \
    -name "ide.properties" -o \
    -name "ide-extension-prefs*" \
    \) | tr '\n' ' ')
  cd "$opwd"
fi
