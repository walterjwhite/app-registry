#!/bin/sh
case $APP_PLATFORM_PLATFORM in
Linux | FreeBSD)
  provider_path=~/.google_authenticator
  provider_no_root_user=1
  ;;
esac
