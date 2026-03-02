#!/bin/sh
secrets_cp() {
  :
}
_load_media_install_secrets() {
  [ -e "$_LOAD_MEDIA_SOURCE_DIRECTORY/.secrets" ] || return
  log_info "copying secrets"
  local secret_base_path="$conf_load_media_mount_point/$conf_load_media_target_path/$_TARGET_DIRECTORY_NAME"
  local password_store_path="$conf_load_media_mount_point/$conf_load_media_target_path/$_TARGET_DIRECTORY_NAME/.password-store"
  local secret_to_copy
  while read -r secret_to_copy; do
    local secret_directory=$(dirname "$secret_to_copy")
    if [ ! -d "~/.password-store/$secret_to_copy" ]; then
      secret_to_copy="$secret_to_copy.gpg"
    fi
    sudo_run mkdir -p "$password_store_path/$secret_directory"
    sudo_run cp -R "~/.password-store/$secret_to_copy" "$password_store_path/$secret_to_copy"
  done <"$_LOAD_MEDIA_SOURCE_DIRECTORY/.secrets"
  _load_media_install_password_store "$secret_base_path" "$password_store_path"
}
_load_media_install_password_store() {
  sudo_run cp ~/.password-store/.gpg-id "$2"
  sudo_run cp -R ~/.gnupg "$1"
}
