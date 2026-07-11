#!/bin/sh
[ -n "$optn_configuration_work_dir_name" ] && {
  provider_path=${alt_path}$HOME/.config/${optn_configuration_work_dir_name}
  provider_path_is_dir=1
  provider_no_root_user=1
}
