#!/bin/sh
provider_path=~/.config/geany
provider_path_is_dir=1
provider_exclude="templates tags filedefs geany_socket*"
provider_no_root_user=1
_configuration_geany_backup_post() {
  local geany_conf=$(find "$APP_DATA_PATH/$provider_name" -type f -name geany.conf)
  if [ -z "$geany_conf" ]; then
    return 1
  fi
  $GNU_SED -i '/msgwindow_position=.*/d' $geany_conf
  $GNU_SED -i '/geometry=.*/d' $geany_conf
  $GNU_SED -i '/recent_files=.*/d' $geany_conf
  $GNU_SED -i '/recent_projects=.*/d' $geany_conf
  $GNU_SED -i '/position_find_x=.*/d' $geany_conf
  $GNU_SED -i '/position_find_y=.*/d' $geany_conf
  $GNU_SED -i '/position_replace_x=.*/d' $geany_conf
  $GNU_SED -i '/position_replace_y=.*/d' $geany_conf
  $GNU_SED -i '/current_page=.*/d' $geany_conf
  $GNU_SED -i '/FILE_NAME_.*=.*/d' $geany_conf
  $GNU_SED -i '/^#.*/d' $geany_conf
}
