#!/bin/sh
_APPLICATION_NAME=configuration
case $_PLATFORM in
Linux | FreeBSD)
	_PLUGIN_CONFIGURATION_PATH=~/.config/rclone
	_PLUGIN_CONFIGURATION_PATH_IS_DIR=1
	_PLUGIN_INCLUDE="rclone.conf"
	;;
esac
