#!/bin/sh
case $APP_PLATFORM_PLATFORM in
Linux | FreeBSD)
  provider_path=~/.config/autostart
  provider_path_is_dir=1
  ;;
esac
provider_no_root_user=1
