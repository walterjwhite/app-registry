#!/bin/sh
set -a
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
_git_github_artifact_url_static() {
	_GITHUB_ARTIFACT_URL=https://github.com/$1/$2/releases/download/${3}/${4}
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
	if [ -e $_DOWNLOADED_FILE ]; then
		_detail "$1 already downloaded to: $_DOWNLOADED_FILE"
		return
	fi
	if [ -z "$_DOWNLOAD_DISABLED" ]; then
		_info "Downloading $1 -> $_DOWNLOADED_FILE"
		curl $_CURL_OPTIONS -o $_DOWNLOADED_FILE -s -L "$1"
	else
		_continue_if "Please manually download: $1 and place it in $_DOWNLOADED_FILE" "Y/n"
	fi
}
_download_install_file() {
	_require "$1" "1 (_download_install_file) target filename"
	_info "Installing $_DOWNLOADED_FILE -> $1"
	_sudo mkdir -p $(dirname $1)
	_sudo cp $_DOWNLOADED_FILE $1
	_sudo chmod 444 $1
	unset _DOWNLOADED_FILE
	[ ! -e $1 ] && return 1
	return 0
}
_verify() {
	[ -z "$_HASH_ALGORITHM" ] && _HASH_ALGORITHM=512
	shasum -a $_HASH_ALGORITHM -c $1 >/dev/null 2>&1
}
BROWSER_CMD=firefox
_browser_new_instance() {
  _info "Copying profile to $_INSTANCE_DIRECTORY"
  mkdir -p $_INSTANCE_DIRECTORY
  tar cp - -C ~/ .mozilla | tar xp - -C $_INSTANCE_DIRECTORY
  _info "Updating conf to use new instance dir"
  local home_directory_sed_safe=$(_sed_safe $HOME)
  local instance_dir_sed_safe=$(_sed_safe $_INSTANCE_DIRECTORY)
  find $_INSTANCE_DIRECTORY -type f ! -name '*.sqlite' -exec $_CONF_GNU_SED -i "s/$home_directory_sed_safe/$instance_dir_sed_safe/g" {} +
  _QUERY="SELECT url,ROUND(last_visit_date / 1000000) FROM moz_places WHERE VISIT_COUNT > 0 ORDER BY last_visit_date DESC"
  _browser_extensions
}
_history_file() {
  _SQLITE_DATABASE=$(find $_INSTANCE_DIRECTORY -type f -name 'places.sqlite')
  [ $_SQLITE_DATABASE ] || _error "Error locating places database"
}
_browser_remote_debug() {
  if [ $_WEB_BROWSER_REMOTE_DEBUG -gt 0 ]; then
    _browser_add_args --remote-debugging-port=$_WEB_BROWSER_REMOTE_DEBUG
  else
    _browser_add_args --remote-debugging-port
  fi
  [ "$_WEB_BROWSER_HEADLESS" ] && _browser_add_args --headless
}
_browser_private_window() {
  _browser_add_args --private-window
  _browser_add_args "--new-instance"
}
_browser_http_proxy() {
  http_proxy=$_WEB_BROWSER_HTTP_PROXY
  https_proxy=$_WEB_BROWSER_HTTP_PROXY
  _browser_add_args "--new-instance"
}
_browser_socks_proxy() {
  local user_pref_file=$(find $_INSTANCE_DIRECTORY -type f -name prefs.js -print -quit)
  _require_file $user_pref_file 'Firefox user pref.js'
  local socks_host="${_WEB_BROWSER_SOCKS_PROXY%%:*}"
  local socks_port="${_WEB_BROWSER_SOCKS_PROXY#*:}"
  printf 'user_pref("network.proxy.socks", "%s");\n' "$socks_host" >>$user_pref_file
  printf 'user_pref("network.proxy.socks_port", %s);\n' "$socks_port" >>$user_pref_file
  printf 'user_pref("network.proxy.type", 1);\n' >>$user_pref_file
  _browser_add_args "--new-instance"
}
_browser_extensions() {
  _FIREFOX_EXTENSION_PATH=$(find $_INSTANCE_DIRECTORY/.mozilla/firefox -mindepth 1 -maxdepth 1 -type d -print -quit)/extensions
  rm -rf $_FIREFOX_EXTENSION_PATH && mkdir -p $_FIREFOX_EXTENSION_PATH
  _info "Installing extensions to: $_FIREFOX_EXTENSION_PATH"
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
    _warn "Unsupported extension: $1"
    continue
    ;;
  esac
}
_browser_extension_load() {
  _download $2
  _detail "Copying $_DOWNLOADED_FILE -> $_FIREFOX_EXTENSION_PATH/$1.xpi"
  cp $_DOWNLOADED_FILE $_FIREFOX_EXTENSION_PATH/$1.xpi
}
