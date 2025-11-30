#!/bin/sh
_APPLICATION_NAME=web-browser
_sed_safe() {
	printf '%s' $1 | sed -e "s/\//\\\\\//g"
}
BROWSER_CMD=librewolf
_BROWSER_NEW_INSTANCE() {
	_INFO "Copying profile to $_INSTANCE_DIRECTORY"
	mkdir -p $_INSTANCE_DIRECTORY
	tar cp - -C ~/ --exclude bookmarkbackups --exclude datareporting --exclude security_state --exclude sessionstore-backups --exclude settings/data.safe.bin --exclude storage --exclude weave --exclude .parentlock --exclude favicons.sqlite --exclude formhistory.sqlite --exclude key4.db --exclude lock --exclude permissions.sqlite --exclude places.sqlite .mozilla | tar xp - -C $_INSTANCE_DIRECTORY
	_INFO "Updating conf to use new instance dir"
	local home_directory_sed_safe=$(_sed_safe $HOME)
	local instance_dir_sed_safe=$(_sed_safe $_INSTANCE_DIRECTORY)
	find $_INSTANCE_DIRECTORY -type f ! -name '*.sqlite' -exec $_CONF_GNU_SED -i "s/$home_directory_sed_safe/$instance_dir_sed_safe/g" {} +
	_QUERY="SELECT url,ROUND(last_visit_date / 1000000) FROM moz_places WHERE VISIT_COUNT > 0 ORDER BY last_visit_date DESC"
}
_BROWSER_HTTP_PROXY() {
	http_proxy=$_WEB_BROWSER_HTTP_PROXY
	https_proxy=$_WEB_BROWSER_HTTP_PROXY
	_browser_add_args "--new-instance"
}
