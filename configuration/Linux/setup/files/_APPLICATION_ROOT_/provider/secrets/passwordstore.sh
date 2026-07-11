#!/bin/sh
provider_path=${alt_path}$HOME/.password-store
provider_path_is_dir=1
provider_path_is_skip_prepare=1
provider_no_root_user=1
_configuration_passwordstore_backup() {
  if [ $(git -C "$provider_path" remote -v | wc -l) -eq 0 ]; then
    log_warn "no git remotes exist"
    return 1
  fi
  rm -rf "$provider_data_path"
  mkdir -p $provider_data_path
  git -C "$provider_path" remote -v >$provider_data_path/git
}
_configuration_passwordstore_restore() {
  [ ! -e $provider_data_path/git ] && return 1
  [ -e "$provider_path" ] && {
    local opwd=$PWD
    cd "$provider_path" || exit_with_error "unable to enter provider_path: $provider_path"
    git pull
    cd "$opwd" || exit_with_error "unable to return to: $opwd"
    return
  }
  git clone $(head -1 $provider_data_path/git | awk {'print$2'}) "$provider_path" >/dev/null 2>&1
}
