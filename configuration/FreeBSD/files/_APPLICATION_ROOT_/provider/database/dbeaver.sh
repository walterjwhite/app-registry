#!/bin/sh
_APPLICATION_NAME=configuration
case $_PLATFORM in
Windows)
	_PLUGIN_CONFIGURATION_PATH=$APPDATA/DBeaverData
	;;
Apple)
	_PLUGIN_CONFIGURATION_PATH=~/Library/DBeaverData
	;;
Linux | FreeBSD)
	if [ -n "$XDG_DATA_HOME" ]; then
		_PLUGIN_CONFIGURATION_PATH=$XDG_DATA_HOME/DBeaverData
	else
		_PLUGIN_CONFIGURATION_PATH=~/.local/share/DBeaverData
	fi
	;;
esac
_PLUGIN_CONFIGURATION_PATH_IS_DIR=1
_PLUGIN_NO_ROOT_USER=1
_dbeaver_init_include() {
	if [ ! -e "$_PLUGIN_CONFIGURATION_PATH" ]; then
		return 1
	fi
	if [ "$_ACTION" = "backup" ]; then
		local opwd=$PWD
		cd "$_PLUGIN_CONFIGURATION_PATH"
		_PLUGIN_INCLUDE=$(find . -type f -path '*/.settings/*' -or -name 'data-sources.json' -or -name 'credentials-config.json' -or -name 'project-metadata.json' | tr '\n' ' ')
		cd $opwd
	fi
}
_CONFIGURE_DBEAVER_BACKUP_POST() {
	find "$_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME" -type f -exec $_CONF_GNU_SED -i '/SQLEditor.resultSet.ratio=.*/d' {} +
	find "$_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME" -type f -exec $_CONF_GNU_SED -i '/ui.auto.update.check.time=.*/d' {} +
}
_dbeaver_init_include
