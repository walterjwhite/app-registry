#!/bin/sh
case $APP_PLATFORM_PLATFORM in
Linux | FreeBSD)
  provider_path=~/.config/sway
  provider_path_is_dir=1
  provider_no_root_user=1
  ;;
esac
