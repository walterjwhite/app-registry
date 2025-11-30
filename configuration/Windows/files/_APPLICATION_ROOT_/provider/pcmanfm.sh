#!/bin/sh
_APPLICATION_NAME=configuration
case $_PLATFORM in
Linux | FreeBSD)
	_PLUGIN_CONFIGURATION_PATH=~/.config/pcmanfm
	_PLUGIN_CONFIGURATION_PATH_IS_DIR=1
	_PLUGIN_INCLUDE="default/pcmanfm.conf"
	_PLUGIN_NO_ROOT_USER=1
	;;
esac
_CONFIGURE_PCMANFM_BACKUP_POST() {
	local pcmanfm_conf=$(find "$_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME" -type f -name pcmanfm.conf)
	if [ -z "$pcmanfm_conf" ]; then
		return 1
	fi
	$_CONF_GNU_SED -i '/win_width=.*/d' $pcmanfm_conf
	$_CONF_GNU_SED -i '/win_height=.*/d' $pcmanfm_conf
	$_CONF_GNU_SED -i '/splitter_pos=.*/d' $pcmanfm_conf
}
