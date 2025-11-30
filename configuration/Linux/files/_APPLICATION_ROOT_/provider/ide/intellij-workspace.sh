#!/bin/sh
_APPLICATION_NAME=configuration
_sed_safe() {
	printf '%s' $1 | sed -e "s/\//\\\\\//g"
}
if [ -n "$_CONF_CONFIGURATION_INTELLIJ_WORKSPACE_BASE_DIRECTORY" ]; then
	_PLUGIN_CONFIGURATION_PATH="$_CONF_CONFIGURATION_INTELLIJ_WORKSPACE_BASE_DIRECTORY"
	_PLUGIN_NO_ROOT_USER=1
else
	_WARN "_CONF_CONFIGURATION_INTELLIJ_WORKSPACE_BASE_DIRECTORY is unset"
fi
_CONFIGURE_INTELLIJ_WORKSPACE_RESTORE() {
	local workspace_backup_path=$(_sed_safe "$_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME")
	local intellij_idea
	for intellij_idea in $(find $_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME -type d -name '.idea'); do
		local intellij_idea_target=$(printf '%s\n' "$intellij_idea" | sed -e "s/$workspace_backup_path//")
		_DETAIL "Restoring $intellij_idea_target"
		rm -rf $_CONF_CONFIGURATION_INTELLIJ_WORKSPACE_BASE_DIRECTORY/$intellij_idea_target
		cp -Rp $_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME/$intellij_idea_target $_CONF_CONFIGURATION_INTELLIJ_WORKSPACE_BASE_DIRECTORY/$intellij_idea_target
	done
}
_CONFIGURE_INTELLIJ_WORKSPACE_BACKUP() {
	rm -rf $_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME
	mkdir -p $_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME
	local workspace_base_path_sed_safe=$(_sed_safe "$_CONF_CONFIGURATION_INTELLIJ_WORKSPACE_BASE_DIRECTORY")
	local intellij_idea
	for intellij_idea in $(find $_CONF_CONFIGURATION_INTELLIJ_WORKSPACE_BASE_DIRECTORY -type d -name '.idea'); do
		local intellij_idea_target=$(printf '%s\n' "$intellij_idea" | sed -e "s/$workspace_base_path_sed_safe//")
		mkdir -p $(dirname $_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME/$intellij_idea_target)
		_DETAIL "Backing up $intellij_idea_target"
		cp -Rp $intellij_idea $_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME/$intellij_idea_target
	done
}
