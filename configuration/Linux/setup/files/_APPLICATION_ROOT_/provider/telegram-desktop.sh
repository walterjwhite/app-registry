#!/bin/sh
case $APP_PLATFORM_PLATFORM in
Linux | FreeBSD)
  provider_path=~/.local/share/TelegramDesktop
  provider_path_is_dir=1
  provider_exclude="tdata/dictionaries tdata/emoji log.txt tdata/countries tdata/user_data tdata/shortcuts-default.json usertag"
  provider_no_root_user=1
  ;;
esac
