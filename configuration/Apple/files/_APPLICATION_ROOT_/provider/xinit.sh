#!/bin/sh
_APPLICATION_NAME=configuration
case $_PLATFORM in
Linux | FreeBSD)
	_PLUGIN_CONFIGURATION_PATH=~/.xinitrc
	_PLUGIN_NO_ROOT_USER=1
	;;
esac
