#!/bin/sh
platform_is_supported() {
  local _supported_platforms="$1"
  local _platform
  [ -z "$_supported_platforms" ] && return 0
  for _platform in $_supported_platforms; do
    [ "$APP_PLATFORM_PLATFORM" = "$_platform" ] && return 0
  done
  exit_with_error "platform '$APP_PLATFORM_PLATFORM' is not supported; supported: $_supported_platforms"
}
_get_install_target() {
  local cmd_path=$(command -v $1) || exit_with_error "missing $1"
  case $cmd_path in
  *${HOME}*)
    install_target=USER
    ;;
  *)
    install_target=SYSTEM
    ;;
  esac
}
provider_path=${alt_path}$HOME/.config/walterjwhite
provider_path_is_dir=1
_configuration_walterjwhite_init_backup() {
  _get_install_target app-install
  _configuration_walterjwhite_init_write_restore_sh
  _configuration_walterjwhite_init_backup_apps
  _configuration_walterjwhite_init_backup_app_install
  _configuration_walterjwhite_init_backup_conf
  return 0
}
_configuration_walterjwhite_init_write_restore_sh() {
  case "$install_target" in
  SYSTEM) sudo_prefix="$SUDO_CMD " ;;
  *) sudo_prefix="" ;;
  esac
  export install_target SUDO_CMD sudo_prefix
  {
    printf '%s\n' '#!/bin/sh' 'set -eu' ''
    local escaped_app_path=$(printf '%q' "$APP_PATH")
    local escaped_app_platform_bin_path=$(printf '%q' "$APP_PLATFORM_BIN_PATH")
    printf '# restore configuration directories\n'
    printf '# NOTE: if alt_path is set, contents will be extracted into that path\n'
    printf ': ${alt_path:=""}\n'
    printf '%srm -rf -- ${alt_path}%s\n' "$sudo_prefix" "$escaped_app_path"
    printf '%smkdir -p -- ${alt_path}%s\n' "$sudo_prefix" "$escaped_app_path"
    printf '\n'
    printf '# restore app-install\n'
    printf '%scp ./walterjwhite-init/app-install ${alt_path}%s\n' "$sudo_prefix" "$escaped_app_platform_bin_path"
    printf '# restore configuration app dir (providers)\n'
    printf 'tar -cpf - -C ./walterjwhite-init/configuration . | %star -xp -C ${alt_path}%s\n' \
      "$sudo_prefix" "$escaped_app_path"
    printf '\n'
    printf '# restore conf\n'
    printf './walterjwhite-init/conf restore\n'
    printf '\n'
    printf '%s./walterjwhite-init/app-install init\n' "$sudo_prefix"
    printf '# install system apps\n'
    printf '[ -f ./walterjwhite-init/apps.system ] && {\n'
    printf '  %sapp-install $(cat ./walterjwhite-init/apps.system)\n' "$sudo_prefix"
    printf '}\n\n'
    printf '# install user apps\n'
    printf '[ -f ./walterjwhite-init/apps.user ] && {\n'
    printf '  app-install $(cat ./walterjwhite-init/apps.system)\n'
    printf '}\n\n'
  } >"$provider_data_path/restore.sh"
}
_configuration_walterjwhite_init_backup_apps() {
  case $APP_PLATFORM_PATH in
  *${HOME}*)
    ;;
  *)
    find $APP_PLATFORM_PATH/apps -maxdepth 1 -mindepth 1 -type d ! -name init -exec basename {} \; | sort -uV | tr '\n' ' ' >"$provider_data_path"/apps.system
    ;;
  esac
  find $APP_PLATFORM_ROOT/$HOME/.local/walterjwhite/apps -maxdepth 1 -mindepth 1 -type d ! -name init -exec basename {} \; | sort -uV | tr '\n' ' ' >"$provider_data_path"/apps.user
}
_configuration_walterjwhite_init_backup_app_install() {
  printf 'install_target=%s\n' "$install_target" >"$provider_data_path/.install-target"
  cp $(command -v app-install) "$provider_data_path"/app-install
}
_configuration_walterjwhite_init_backup_conf() {
  cp $(command -v conf) "$provider_data_path"/conf
  mkdir -p "$provider_data_path/configuration"
  tar -cp $tar_args -C $APP_PATH . | tar -xp $tar_args -C "$provider_data_path/configuration"
}
_configuration_walterjwhite_init_restore() {
  :
}
