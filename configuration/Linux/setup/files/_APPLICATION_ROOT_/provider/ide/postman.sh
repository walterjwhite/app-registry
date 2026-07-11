#!/bin/sh
case $APP_PLATFORM_PLATFORM in
Windows)
  provider_path=${alt_path}$HOME/AppData/Roaming/Postman
  provider_path_is_dir=1
  provider_exclude="logs|GPUCache|Code Cache"
  provider_no_root_user=1
  ;;
esac
