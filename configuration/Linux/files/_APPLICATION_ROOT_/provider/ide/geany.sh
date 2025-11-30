#!/bin/sh
_APPLICATION_NAME=configuration
_PLUGIN_CONFIGURATION_PATH=~/.config/geany
_PLUGIN_CONFIGURATION_PATH_IS_DIR=1
_PLUGIN_EXCLUDE="templates tags filedefs geany_socket*"
_PLUGIN_NO_ROOT_USER=1
_CONFIGURE_GEANY_BACKUP_POST() {
	local geany_conf=$(find "$_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME" -type f -name geany.conf)
	if [ -z "$geany_conf" ]; then
		return 1
	fi
	$_CONF_GNU_SED -i '/msgwindow_position=.*/d' $geany_conf
	$_CONF_GNU_SED -i '/geometry=.*/d' $geany_conf
	$_CONF_GNU_SED -i '/recent_files=.*/d' $geany_conf
	$_CONF_GNU_SED -i '/recent_projects=.*/d' $geany_conf
	$_CONF_GNU_SED -i '/position_find_x=.*/d' $geany_conf
	$_CONF_GNU_SED -i '/position_find_y=.*/d' $geany_conf
	$_CONF_GNU_SED -i '/position_replace_x=.*/d' $geany_conf
	$_CONF_GNU_SED -i '/position_replace_y=.*/d' $geany_conf
	$_CONF_GNU_SED -i '/current_page=.*/d' $geany_conf
	$_CONF_GNU_SED -i '/FILE_NAME_.*=.*/d' $geany_conf
	$_CONF_GNU_SED -i '/^#.*/d' $geany_conf
}
