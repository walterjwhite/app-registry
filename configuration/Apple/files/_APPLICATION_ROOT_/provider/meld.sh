#!/bin/sh
_APPLICATION_NAME=configuration
_gsettings_exist() {
	gsettings list-recursively "$1" >/dev/null 2>&1
}
_gsettings_dump() {
	_gsettings_exist "$1" || {
		_WARN "gsettings do not exist for $1"
		return 0
	}
	mkdir -p $_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME
	gsettings list-recursively "$1" 2>&1 | sed -e "s/^$1 //" >$_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME/gsettings.conf
	return 0
}
_gsettings_restore() {
	[ ! -e "$_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME/gsettings.conf" ] && {
		_WARN "Unable to restore gsettings for $_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME/gsettings.conf [$1]"
		return 0
	}
	local _gsettings_line
	local _gsettings_key _gsettings_value
	while read _gsettings_line; do
		_gsettings_key=$(printf '%s' "$_gsettings_line" | sed -e 's/ .*//')
		_gsettings_value=$(printf '%s' "$_gsettings_line" | sed -e 's/[[:alnum:]-]* //')
		gsettings set $1 "$_gsettings_key" "$_gsettings_value"
	done <"$_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME/gsettings.conf"
	return 0
}
_PLUGIN_CONFIGURATION_PATH=~/.config
_PLUGIN_CONFIGURATION_PATH_IS_DIR=1
_PLUGIN_CONFIGURATION_PATH_IS_SKIP_PREPARE=1
_PLUGIN_NO_ROOT_USER=1
_GSETTINGS_MELD_KEY=org.gnome.meld
case $_PLATFORM in
Apple)
	unset _PLUGIN_CONFIGURATION_PATH _PLUGIN_CONFIGURATION_PATH_IS_DIR _PLUGIN_CONFIGURATION_PATH_IS_SKIP_PREPARE
	;;
esac
_CONFIGURE_MELD_BACKUP() {
	_gsettings_dump $_GSETTINGS_MELD_KEY
}
_CONFIGURE_MELD_RESTORE() {
	_gsettings_restore $_GSETTINGS_MELD_KEY
}
_CONFIGURE_MELD_CLEAR() {
	:
}
