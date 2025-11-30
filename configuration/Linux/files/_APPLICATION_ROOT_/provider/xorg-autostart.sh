#!/bin/sh
_APPLICATION_NAME=configuration
case $_PLATFORM in
Linux | FreeBSD)
	_PLUGIN_CONFIGURATION_PATH=~/.config/autostart
	_PLUGIN_CONFIGURATION_PATH_IS_DIR=1
	;;
esac
_PLUGIN_NO_ROOT_USER=1
