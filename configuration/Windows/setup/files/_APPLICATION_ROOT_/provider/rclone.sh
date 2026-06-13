#!/bin/sh
case $APP_PLATFORM_PLATFORM in
Linux | FreeBSD)
  provider_path=${alt_path}$HOME/.config/rclone
  provider_path_is_dir=1
  provider_include="rclone.conf"
  ;;
esac
