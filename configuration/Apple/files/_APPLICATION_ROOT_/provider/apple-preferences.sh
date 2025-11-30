#!/bin/sh
_APPLICATION_NAME=configuration
_PLUGIN_CONFIGURATION_PATH=~/Library/Preferences
_PLUGIN_CONFIGURATION_PATH_IS_DIR=1
_PLUGIN_INCLUDE="com.apple.Accessibility com.apple.AppleMultitouchTrackpad com.apple.HIToolbox com.apple.Kerberos com.apple.MCX com.apple.Preferences com.apple.ServicesMenu.Services com.apple.TTY com.apple.amp.mediasharingd com.apple.controlcenter com.apple.driver.AppleBluetoothMultitouch.mouse com.apple.driver.AppleHIDMouse com.apple.finder"
_CONFIGURE_APPLE_CLEAR() {
	_sudo rm -rf "$_PLUGIN_CONFIGURATION_PATH"/Caches
	_sudo rm -rf "$_PLUGIN_CONFIGURATION_PATH"/Preferences
	return 0
}
_CONFIGURE_APPLE_BACKUP_POST() {
	_plutil_wrapper $_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME plist xml1 xml _xmlformat
}
_xmlformat() {
	xmllint --format $1.xml -o $1.xml.formatted
	mv $1.xml.formatted $1.xml
}
_CONFIGURE_APPLE_RESTORE_POST() {
	_plutil_wrapper "$_PLUGIN_CONFIGURATION_PATH" xml binary1 plist
}
_plutil_wrapper() {
	local plist_file
	for plist_file in $(find $1 -type f -name "*.$2"); do
		local plist_base_name=$(printf '%s\n' "$plist_file" | sed -e "s/\.$2$//")
		plutil -convert $3 -o $plist_base_name.$4 $plist_file
		[ -n "$5" ] && $5 $plist_base_name
		rm -f $plist_file
	done
}
