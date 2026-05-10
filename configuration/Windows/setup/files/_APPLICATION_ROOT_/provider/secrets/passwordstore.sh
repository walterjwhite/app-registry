#!/bin/sh
provider_path=~/.password-store
provider_path_is_dir=1
provider_path_is_skip_prepare=1
provider_no_root_user=1
_configuration_passwordstore_backup() {
  if [ $(git -C "$provider_path" remote -v | wc -l) -eq 0 ]; then
    log_warn "no git remotes exist"
    return 1
  fi
  rm -rf "$APP_DATA_PATH/$provider_name"
  mkdir -p $APP_DATA_PATH/$provider_name
  git -C "$provider_path" remote -v >$APP_DATA_PATH/$provider_name/git
}
_configuration_passwordstore_restore() {
  [ ! -e $APP_DATA_PATH/$provider_name/git ] && return 1
  [ -e "$provider_path" ] && {
    local opwd=$PWD
    cd $provider_path
    git pull
    cd $opwd
    return
  }
  git clone $(head -1 $APP_DATA_PATH/$provider_name/git | awk {'print$2'}) "$provider_path" >/dev/null 2>&1
}
