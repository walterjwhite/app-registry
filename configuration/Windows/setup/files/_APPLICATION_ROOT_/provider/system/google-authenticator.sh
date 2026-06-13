#!/bin/sh
case $APP_PLATFORM_PLATFORM in
Linux | FreeBSD)
  provider_path=${alt_path}$HOME/.google_authenticator
  provider_no_root_user=1
  ;;
esac
