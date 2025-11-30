#!/bin/sh
_APPLICATION_NAME=web-browser
_git_github_latest_release() {
	curl -sL https://api.github.com/repos/$1/$2/releases/latest | grep tag_name | awk {'print$2'} | tr -d '"' | tr -d ','
}
_git_github_fetch_latest_artifact() {
	local github_organization_name=$1
	local github_repository_name=$2
	local artifact_name=$3
	local artifact_suffix=$4
	shift 4
	local latest_version=$(_git_github_latest_release $github_organization_name $github_repository_name)
	[ -z "$artifact_url_function" ] && artifact_url_function=_git_github_artifact_url
	$artifact_url_function $github_organization_name $github_repository_name $latest_version $artifact_name $artifact_suffix
	_download $_GITHUB_ARTIFACT_URL "$@"
	unset _GITHUB_ARTIFACT_URL
}
_git_github_artifact_url() {
	_GITHUB_ARTIFACT_URL=https://github.com/$1/$2/releases/download/${3}/${4}${3}${5}
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
_sed_safe() {
	printf '%s' $1 | sed -e "s/\//\\\\\//g"
}
BROWSER_CMD=$_CONF_WEB_BROWSER_CHROMIUM_CMD
case $_PLATFORM in
Linux | FreeBSD)
	_CONFIGURATION_DIRECTORY=~/.config/chromium
	;;
*)
	error "Unsupported platform: $_PLATFORM"
	;;
esac
_CONFIGURATION_DIRECTORY=~/.config/chromium
_BROWSER_NEW_INSTANCE() {
	local chromium_instance_dir=$_INSTANCE_DIRECTORY/.config/chromium
	mkdir -p $chromium_instance_dir/Default
	[ ! -e $_CONFIGURATION_DIRECTORY/Default/Preferences ] && error "$_CONFIGURATION_DIRECTORY/Default/Preferences does not exist"
	cp -R $_CONFIGURATION_DIRECTORY/Default/Preferences "$chromium_instance_dir/Default/"
	cp -R $_CONFIGURATION_DIRECTORY/Default/Extensions "$chromium_instance_dir/Default/" 2>/dev/null
	_INFO "Updating conf to use new instance dir"
	local home_directory_sed_safe=$(_sed_safe $HOME)
	local instance_dir_sed_safe=$(_sed_safe $chromium_instance_dir)
	find $_INSTANCE_DIRECTORY -type f ! -name '*.sqlite' -exec $_CONF_GNU_SED -i "s/$home_directory_sed_safe/$instance_dir_sed_safe/g" {} +
	mkdir -p $_INSTANCE_DIRECTORY/Downloads
	_SQLITE_DATABASE=$chromium_instance_dir/Default/History
	_QUERY="SELECT url,ROUND(LAST_VISIT_TIME/1000000) FROM urls WHERE url NOT LIKE 'chrome-extension://%' ORDER BY last_visit_time DESC"
	_browser_extensions
	[ -n "$_BROWSER_EXTENSIONS" ] && _browser_add_args "--load-extension=$_BROWSER_EXTENSIONS"
}
_BROWSER_HTTP_PROXY() {
	_browser_add_args "--proxy-server=http://${_WEB_BROWSER_HTTP_PROXY}"
}
_browser_extensions() {
	local extension_config extension_name extension_version
	for extension_config in $(cat $_CONFIGURATION_DIRECTORY/extensions); do
		_browser_extension $extension_config
	done
}
_browser_extension() {
	extension_name=$1
	case $extension_name in
	ublock-origin)
		_git_github_fetch_latest_artifact gorhill uBlock uBlock0_ .chromium.zip
		;;
	Browserpass)
		_git_github_fetch_latest_artifact browserpass browserpass-extension browserpass-github- .crx
		;;
	Ghostery)
		artifact_url_function=_ghostery_artifact_url _git_github_fetch_latest_artifact ghostery ghostery-extension ghostery-chromium- .zip
		;;
	*)
		_WARN "Unsupported extension: $extension_name"
		continue
		;;
	esac
}
_ghostery_artifact_url() {
	local version_without_v=$(printf '%s\n' "$3" | sed -e 's/^v//')
	_GITHUB_ARTIFACT_URL=https://github.com/$1/$2/releases/download/${3}/${4}${version_without_v}${5}
}
