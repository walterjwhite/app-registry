#!/bin/sh
_APPLICATION_NAME=configuration
_conf_intellij_get_directory() {
	case $_ACTION in
	backup)
		_PLUGIN_CONFIGURATION_PATH=$(find "$1" -maxdepth 1 -type d -name '*Idea*' 2>/dev/null)
		if [ $? -gt 0 ]; then
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
	_PLUGIN_INCLUDE="keymaps options idea.key"
	_PLUGIN_NO_ROOT_USER=1
}
case $_PLATFORM in
Windows)
	_conf_intellij_get_directory ~/AppData/IntelliJ
	;;
Apple)
	_conf_intellij_get_directory ~/Library/"Application Support"/JetBrains
	;;
Linux | FreeBSD)
	_conf_intellij_get_directory ~/.config/JetBrains
	;;
esac
