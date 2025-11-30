#!/bin/sh
_APPLICATION_NAME=configuration
_PLUGIN_CONFIGURATION_PATH=~/.mozilla
_PLUGIN_CONFIGURATION_PATH_IS_DIR=1
_PLUGIN_INCLUDE="firefox/installs.ini firefox/profiles.ini native-messaging-hosts"
_PLUGIN_NO_ROOT_USER=1
_CONFIGURE_FIREFOX_COMPARE() {
	$_CONF_CONFIGURE_COMPARISON_TOOL_CMDLINE "$_PLUGIN_CONFIGURATION_PATH" $_CONF_APPLICATION_DATA_PATH/firefox
}
_CONFIGURE_FIREFOX_BACKUP_PRE() {
	local prefsjs_dir=$(dirname $(find "$_PLUGIN_CONFIGURATION_PATH"/firefox -type f -name prefs.js -print -quit | sed -e 's/^.*\/\.mozilla\///'))
	_PLUGIN_INCLUDE="$_PLUGIN_INCLUDE $prefsjs_dir/addons.json $prefsjs_dir/extension-preferences.json $prefsjs_dir/extension-settings.json $prefsjs_dir/extensions.json $prefsjs_dir/prefs.json $prefsjs_dir/search.json.mozlz4"
}
_CONFIGURE_FIREFOX_BACKUP_POST() {
	local extension_manifest
	rm -f $_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME/extensions
	cp "$_PLUGIN_CONFIGURATION_PATH"/extensions $_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME 2>/dev/null
	if [ $(wc -l <$_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME/extensions) -eq 0 ]; then
		basename $(find "$_PLUGIN_CONFIGURATION_PATH"/firefox -type f -path '*/extensions/*.xpi') 2>/dev/null |
			sed -e 's/\.xpi$//' | sort -u >>$_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME/extensions
	fi
	local prefsjs=$(find $_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME -type f -name prefs.js -print -quit)
	[ -z "$prefsjs" ] && return
	$_CONF_GNU_SED -i '/app.update.lastUpdateTime/d' $prefsjs
	$_CONF_GNU_SED -i '/extensions.webextensions/d' $prefsjs
	$_CONF_GNU_SED -i '/last_check/d' $prefsjs
	$_CONF_GNU_SED -i '/checked/d' $prefsjs
}
_CONFIGURE_FIREFOX_RESTORE_POST() {
	cp $_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME/extensions "$_PLUGIN_CONFIGURATION_PATH"
}
