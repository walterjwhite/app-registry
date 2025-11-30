#!/bin/sh
_APPLICATION_NAME=configuration
case $_PLATFORM in
Linux | FreeBSD)
	_PLUGIN_CONFIGURATION_PATH=~/.config/"Code"
	_PLUGIN_CONFIGURATION_PATH_IS_DIR=1
	_PLUGIN_INCLUDE="User/keybindings.json User/settings.json"
	;;
Apple)
	_PLUGIN_CONFIGURATION_PATH="$HOME/Library/Application Support/Code"
	_PLUGIN_CONFIGURATION_PATH_IS_DIR=1
	_PLUGIN_INCLUDE="User/keybindings.json User/settings.json"
	;;
esac
_PLUGIN_NO_ROOT_USER=1
