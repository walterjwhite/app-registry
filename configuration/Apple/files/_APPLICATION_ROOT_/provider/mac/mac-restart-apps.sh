#!/bin/sh
_APPLICATION_NAME=configuration
_PLUGIN_CONFIGURATION_PATH=~/.config/mac/restart-apps
_CONFIGURE_MAC_RESTART_APPS_RESTORE() {
	if [ ! -e $_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME/restart-apps ]; then
		return
	fi
	local restart_app
	while read restart_app; do
		pkill -1 -lf $restart_app
	done <$_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME/restart-apps
}
