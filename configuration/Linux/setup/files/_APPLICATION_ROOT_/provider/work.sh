#!/bin/sh
[ -n "$work_dir" ] && {
  provider_path=${alt_path}$HOME/.config/${work_dir}
  provider_path_is_dir=1
  provider_no_root_user=1
}
