#!/bin/sh
_APPLICATION_NAME=configuration
case $_PLATFORM in
Linux | FreeBSD)
	_PLUGIN_CONFIGURATION_PATH=~/.thunderbird
	_PLUGIN_CONFIGURATION_PATH_IS_DIR=1
	_PLUGIN_NO_ROOT_USER=1
	_PLUGIN_EXCLUDE="calendar-data datareporting Mail security_state settings storage .parentlock abook* formhistory.sqlite lock global-messages-db.sqlite"
	_PLUGIN_INCLUDE="installs.ini profiles.ini"
	_THUNDERBIRD_PROFILE_FILES="containers.json \
		encrypted-openpgp-passphrase.txt extension-preferences.json extensions.json \
		key4.db logins.json mailViews.dat openpgp.sqlite permissions.sqlite pkcs11.txt \
		prefs.js session.json sessionCheckpoints.json SiteSecurityServiceState.txt \
		xulstore.json"
	if [ -e "$_PLUGIN_CONFIGURATION_PATH" ]; then
		_THUNDERBIRD_INSTANCE_PATH=$(basename $(find "$_PLUGIN_CONFIGURATION_PATH" -mindepth 1 -maxdepth 1 -type d ! -name .thunderbird))
		_THUNDERBIRD_MESSAGE_FILTERS=$(find "$_PLUGIN_CONFIGURATION_PATH"/$_THUNDERBIRD_INSTANCE_PATH -type f -name msgFilterRules.dat | sed -e "s/^.*$_THUNDERBIRD_INSTANCE_PATH/$_THUNDERBIRD_INSTANCE_PATH/" | tr '\n' ' ')
		_PLUGIN_INCLUDE="$_PLUGIN_INCLUDE $_THUNDERBIRD_MESSAGE_FILTERS"
		for _THUNDERBIRD_FILE in $_THUNDERBIRD_PROFILE_FILES; do
			_PLUGIN_INCLUDE="$_PLUGIN_INCLUDE $_THUNDERBIRD_INSTANCE_PATH/$_THUNDERBIRD_FILE"
		done
	fi
	;;
esac
_CONFIGURE_THUNDERBIRD_BACKUP_POST() {
	local thunderbird_prefs=$(find $_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME -type f -name prefs.js -print -quit)
	cat $thunderbird_prefs | sort >$thunderbird_prefs.sorted
	mv $thunderbird_prefs.sorted $thunderbird_prefs
	rm -f $_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME/extensions
	[ ! -e "$_PLUGIN_CONFIGURATION_PATH"/extensions ] && return
	cp "$_PLUGIN_CONFIGURATION_PATH"/extensions $_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME 2>/dev/null
	if [ $(wc -l <$_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME/extensions) -eq 0 ]; then
		basename $(find "$_PLUGIN_CONFIGURATION_PATH" -type f -path '*/extensions/*.xpi') 2>/dev/null |
			sed -e 's/\.xpi$//' | sort -u >>$_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME/extensions
	fi
}
_CONFIGURE_THUNDERBIRD_RESTORE_POST() {
	[ ! -e $_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME/extensions ] && return
	cp $_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME/extensions "$_PLUGIN_CONFIGURATION_PATH"
}
