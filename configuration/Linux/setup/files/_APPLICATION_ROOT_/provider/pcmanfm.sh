#!/bin/sh
case $APP_PLATFORM_PLATFORM in
Linux | FreeBSD)
  provider_path=${alt_path}$HOME/.config/pcmanfm
  provider_path_is_dir=1
  provider_include="default/pcmanfm.conf"
  provider_no_root_user=1
  ;;
esac
_configuration_pcmanfm_backup_post() {
  local pcmanfm_conf=$(find "$provider_data_path" -type f -name pcmanfm.conf)
  if [ -z "$pcmanfm_conf" ]; then
    return 1
  fi
  $GNU_SED -i '/columns=.*/d' $pcmanfm_conf
  $GNU_SED -i '/show_hidden=.*/d' $pcmanfm_conf
  $GNU_SED -i '/splitter_pos=.*/d' $pcmanfm_conf
  $GNU_SED -i '/win_height=.*/d' $pcmanfm_conf
  $GNU_SED -i '/win_width=.*/d' $pcmanfm_conf
}
