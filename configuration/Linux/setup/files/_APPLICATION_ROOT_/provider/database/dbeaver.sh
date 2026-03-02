#!/bin/sh
case $APP_PLATFORM_PLATFORM in
Windows)
  provider_path=$APPDATA/DBeaverData
  ;;
Apple)
  provider_path=~/Library/DBeaverData
  ;;
Linux | FreeBSD)
  if [ -n "$XDG_DATA_HOME" ]; then
    provider_path=$XDG_DATA_HOME/DBeaverData
  else
    provider_path=~/.local/share/DBeaverData
  fi
  ;;
esac
provider_path_is_dir=1
provider_no_root_user=1
_dbeaver_init_include() {
  if [ ! -e "$provider_path" ]; then
    return 1
  fi
  if [ "$_ACTION" = "backup" ]; then
    local opwd=$PWD
    cd "$provider_path"
    provider_include=$(find . -type f -path '*/.settings/*' -or -name 'data-sources.json' -or -name 'credentials-config.json' -or -name 'project-metadata.json' | tr '\n' ' ')
    cd $opwd
  fi
}
_configuration_dbeaver_backup_post() {
  find "$APP_DATA_PATH/$provider_name" -type f -exec $GNU_SED -i '/SQLEditor.resultSet.ratio=.*/d' {} +
  find "$APP_DATA_PATH/$provider_name" -type f -exec $GNU_SED -i '/ui.auto.update.check.time=.*/d' {} +
}
_dbeaver_decrypt() {
  local credentials_file
  credentials_file=$provider_path/workspace6/General/.dbeaver/credentials-config.json
  openssl aes-128-cbc -d -K babb4a9f774ab853c96c2d653dfe544a -iv 00000000000000000000000000000000 -in \
    $credentials_file | dd bs=1 skip=16 2>/dev/null
}
_dbeaver_init_include
