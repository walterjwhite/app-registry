#!/bin/sh
_APPLICATION_NAME=configuration
case $_PLATFORM in
Linux | FreeBSD)
	_PLUGIN_CONFIGURATION_PATH=~/.config/chromium
	;;
Apple)
	_PLUGIN_CONFIGURATION_PATH=~/Library/"Application Support"/Google/Chrome
	;;
Windows)
	_PLUGIN_CONFIGURATION_PATH="~/AppData/Local/Google/Chrome/User Data"
	;;
esac
_PLUGIN_CONFIGURATION_PATH_IS_DIR=1
_PLUGIN_INCLUDE="Default/Preferences Default/Bookmarks"
_PLUGIN_NO_ROOT_USER=1
_CONFIGURE_CHROMIUM_BACKUP_POST() {
	local preferences_file=$(find $_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME -type f -path '*/Default/Preferences' -print -quit)
	if [ -z "$preferences_file" ] || [ ! -e "$preferences_file" ]; then
		_WARN "Chromium conf does not exist"
		return
	fi
	cat $preferences_file | jq -MS 'del(.announcement_notification_service_first_run_time, .dips_timer_last_update, .google.services.signin_scoped_device_id, .last_engagement_time, .history_clusters, .sessions, .profile.content_settings.exceptions.client_hints, .profile.content_settings.exceptions.media_engagement, .profile.content_settings.last_engagement_time, .profile.content_settings.exceptions.site_engagement, .profile.content_settings.exceptions.app_banner, .extensions, .gaia_cookie, .protection.macs.extensions, .protection.macs.google, .updateclientdata, .web_apps, .zerosuggest, .account_tracker_service_last_update, .domain_diversity, .download, .browser.window_placement, .download_bubble, .ntp, .default_search_provider_data.last_visited, .default_search_provider_data.last_modified, .profile.content_settings.exceptions.cookie_controls_metadata, .optimization_guide.predictionmodelfetcher, .profile.last_engagement_time, .profile.last_time_obsolete_http_credentials_removed, .profile.last_time_password_store_metrics_reported)' >$preferences_file.formatted
	mv $preferences_file.formatted $preferences_file
	if [ -e "$_PLUGIN_CONFIGURATION_PATH/extensions" ]; then
		cp "$_PLUGIN_CONFIGURATION_PATH/extensions" $_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME
	else
		local extension_manifest
		rm -f $_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME/extensions
		find "$_PLUGIN_CONFIGURATION_PATH" -type f -path '*/Default/Extensions/*/manifest.json' | while read extension_manifest; do
			grep name "$extension_manifest" | grep -v version_name | sort -u | tail -1 | awk {'print$2'} |
				tr -d '"' | tr -d ',' >>$_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME/extensions
		done
	fi
}
_CONFIGURE_CHROMIUM_RESTORE_POST() {
	local preferences_file=$(find "$_PLUGIN_CONFIGURATION_PATH" -type f -path '*/Default/Preferences' -print -quit)
	cat $preferences_file | tr -d '\n' | tr -d ' ' >$preferences_file.formatted
	mv $preferences_file.formatted $preferences_file
	_CONFIGURE_CHROMIUM_RESTORE_EXTENSIONS
}
_CONFIGURE_CHROMIUM_RESTORE_EXTENSIONS() {
	cp $_CONF_APPLICATION_DATA_PATH/$_EXTENSION_NAME/extensions "$_PLUGIN_CONFIGURATION_PATH"
}
