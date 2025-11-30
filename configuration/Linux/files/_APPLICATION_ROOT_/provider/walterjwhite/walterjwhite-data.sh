#!/bin/sh
_APPLICATION_NAME=configuration
_git_has_uncommitted_work() {
	[ -n "$(git status --porcelain)" ] && return 1
	return 0
}
_git_synced_with_remote() {
	local branch_name=$1
	local remote_hash=$(_git_remote_hash $branch_name)
	local local_hash=$(git-head)
	[ "$local_hash" = "$remote_hash" ] && return 0
	return 1
}
_git_remote_hash() {
	[ -z "$git_type" ] && git_type=heads
	git ls-remote $(git remote -v | head -1 | awk {'print$2'}) | grep "refs/$git_type/${1}$" | cut -f1
}
_PLUGIN_CONFIGURATION_PATH=~/.data
_PLUGIN_CONFIGURATION_PATH_IS_DIR=1
_PLUGIN_CONFIGURATION_PATH_IS_SKIP_PREPARE=1
_CONFIGURE_WALTERJWHITE_DATA_CLEAR() {
	local opwd=$PWD
	local data_project is_clean
	for data_project in $(find "$_PLUGIN_CONFIGURATION_PATH" -mindepth 2 -maxdepth 2 -type d -name .git | sed -e 's/\/.git//' -e 's/\.\///' | sort -u); do
		cd $data_project
		_git_has_uncommitted_work || {
			_WARN "$data_project is dirty"
			is_clean=1
		}
		local branch_name=$(gcb)
		[ -z "$branch_name" ] && branch_name=master
		_git_synced_with_remote $branch_name || {
			_WARN "$data_project is not synced with remote"
			is_clean=1
		}
		cd "$_PLUGIN_CONFIGURATION_PATH"
	done
	find ~/.data -mindepth 1 -maxdepth 1 -type d ! -name configuration ! -name console -exec rm -rf {} +
}
_CONFIGURE_WALTERJWHITE_DATA_RESTORE() {
	[ ! -e $_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME/applications ] && return 1
	local data_application
	while read data_application; do
		if [ -e ~/.data/$data_application ]; then
			_WARN "Data Application: $data_application already exists"
			continue
		fi
		gclone data/$_SYSTEM/$USER/$data_application
	done <$_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME/applications
}
_CONFIGURE_WALTERJWHITE_DATA_BACKUP() {
	rm -f $_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME/applications
	local opwd=$PWD
	cd "$_PLUGIN_CONFIGURATION_PATH"
	local data_project
	for data_project in $(find "$_PLUGIN_CONFIGURATION_PATH" -mindepth 2 -maxdepth 2 -type d -name .git ! -path '*/configuration*' | sed -e 's/\/.git//' -e 's/\.\///' | sort -u); do
		printf '%s\n' "$data_project" | sed -e 's/^.*\.data\///' >>$_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME/applications
		cd $data_project
		_git_has_uncommitted_work || _WARN "$data_project is dirty"
		local branch_name=$(gcb)
		[ -z "$branch_name" ] && branch_name=master
		_git_synced_with_remote $branch_name || _WARN "$data_project is not synced with remote"
		cd "$_PLUGIN_CONFIGURATION_PATH"
	done
	cd $opwd
}
