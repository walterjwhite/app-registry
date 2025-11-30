#!/bin/sh
_APPLICATION_NAME=configuration
_conf_datagrip_get_directory() {
	case $_ACTION in
	backup)
		_PLUGIN_CONFIGURATION_PATH=$(find "$1" -maxdepth 1 -type d -name 'DataGrip*' 2>/dev/null)
		if [ -z "$_PLUGIN_CONFIGURATION_PATH" ]; then
			unset _PLUGIN_CONFIGURATION_PATH
			return
		fi
		printf '%s\n' "$_PLUGIN_CONFIGURATION_PATH" >$_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME/.version
		;;
	restore)
		_PLUGIN_CONFIGURATION_PATH=$(head -1 $_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME/.version 2>/dev/null)
		;;
	esac
	_PLUGIN_CONFIGURATION_PATH_IS_DIR=1
	_PLUGIN_INCLUDE="keymaps workspace options"
}
case $_PLATFORM in
Windows)
	_conf_datagrip_get_directory ~/AppData
	;;
Apple)
	_conf_datagrip_get_directory ~/Library/"Application Support"/JetBrains
	;;
Linux | FreeBSD)
	_conf_datagrip_get_directory ~/.config/JetBrains
	;;
esac
_PLUGIN_NO_ROOT_USER=1
