#!/bin/sh
_APPLICATION_NAME=web-browser
_sed_safe() {
	printf '%s' $1 | sed -e "s/\//\\\\\//g"
}
_download() {
	mkdir -p $_CONF_CACHE_PATH
	local _cached_filename
	if [ $# -gt 1 ]; then
		_cached_filename="$2"
	else
		_cached_filename=$(basename $1 | sed -e 's/?.*$//')
	fi
	_DOWNLOADED_FILE=$_CONF_CACHE_PATH/$_cached_filename
	[ -z "$_NO_CACHE" ] && {
		[ -e $_DOWNLOADED_FILE ] && {
			_DETAIL "$1 already downloaded to: $_DOWNLOADED_FILE"
			return
		}
	}
	if [ -z "$_DOWNLOAD_DISABLED" ]; then
		_INFO "Downloading $1 -> $_DOWNLOADED_FILE"
		curl $_CURL_OPTIONS -o $_DOWNLOADED_FILE -s -L "$1"
	else
		_continue_if "Please manually download: $1 and place it in $_DOWNLOADED_FILE" "Y/n"
	fi
}
_download_install_file() {
	_WARN_ON_ERROR=1 _require "$1" "1 (_download_install_file) target filename" || return 1
	_INFO "Installing $_DOWNLOADED_FILE -> $1"
	_sudo mkdir -p $(dirname $1)
	_sudo cp $_DOWNLOADED_FILE $1
	_sudo chmod 444 $1
	unset _DOWNLOADED_FILE
	[ -e $1 ] || _WARN "failed to install file to: $1"
}
BROWSER_CMD=firefox
_BROWSER_NEW_INSTANCE() {
	_INFO "Copying profile to $_INSTANCE_DIRECTORY"
	mkdir -p $_INSTANCE_DIRECTORY
	tar cp - -C ~/ .mozilla | tar xp - -C $_INSTANCE_DIRECTORY
	_INFO "Updating conf to use new instance dir"
	local home_directory_sed_safe=$(_sed_safe $HOME)
	local instance_dir_sed_safe=$(_sed_safe $_INSTANCE_DIRECTORY)
	find $_INSTANCE_DIRECTORY -type f ! -name '*.sqlite' -exec $_CONF_GNU_SED -i "s/$home_directory_sed_safe/$instance_dir_sed_safe/g" {} +
	_QUERY="SELECT url,ROUND(last_visit_date / 1000000) FROM moz_places WHERE VISIT_COUNT > 0 ORDER BY last_visit_date DESC"
	_browser_extensions
}
_BROWSER_HTTP_PROXY() {
	http_proxy=$_WEB_BROWSER_HTTP_PROXY
	https_proxy=$_WEB_BROWSER_HTTP_PROXY
	_browser_add_args "--new-instance"
}
_browser_extensions() {
	_FIREFOX_EXTENSION_PATH=$(find $_INSTANCE_DIRECTORY/.mozilla/firefox -mindepth 1 -maxdepth 1 -type d -print -quit)/extensions
	rm -rf $_FIREFOX_EXTENSION_PATH && mkdir -p $_FIREFOX_EXTENSION_PATH
	_INFO "Installing extensions to: $_FIREFOX_EXTENSION_PATH"
	local extension_name
	for extension_name in $(cat $_INSTANCE_DIRECTORY/.mozilla/extensions 2>/dev/null); do
		_browser_extension $extension_name
	done
}
_browser_extension() {
	case $1 in
	browserpass@maximbaz.com)
		_browser_extension_load $1 https://addons.mozilla.org/firefox/downloads/file/4187654/browserpass_ce-3.8.0.xpi
		;;
	firefox@ghostery.com)
		_browser_extension_load $1 https://addons.mozilla.org/firefox/downloads/file/4207768/ghostery-8.12.5.xpi
		;;
	passff@invicem.pro)
		_browser_extension_load $1 https://addons.mozilla.org/firefox/downloads/file/4202971/passff-1.16.xpi
		;;
	uBlock0@raymondhill.net)
		_browser_extension_load $1 https://addons.mozilla.org/firefox/downloads/file/4198829/ublock_origin-1.57.2.xpi
		;;
	jid1-ZAdIEUB7XOzOJw@jetpack)
		_browser_extension_load $1 https://addons.mozilla.org/firefox/downloads/file/4205925/duckduckgo_for_firefox-2023.12.6.xpi
		;;
	*)
		_WARN "Unsupported extension: $1"
		continue
		;;
	esac
}
_browser_extension_load() {
	_download $2
	_DETAIL "Copying $_DOWNLOADED_FILE -> $_FIREFOX_EXTENSION_PATH/$1.xpi"
	cp $_DOWNLOADED_FILE $_FIREFOX_EXTENSION_PATH/$1.xpi
}
