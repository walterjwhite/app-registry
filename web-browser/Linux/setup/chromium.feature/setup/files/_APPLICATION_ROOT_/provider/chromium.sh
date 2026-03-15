#!/bin/sh
_extract_extract() {
	if [ $# -lt 2 ]; then
		log_warn "expecting 2 arguments, source file, and target to extract to"
		return 1
	fi
	log_info "extracting $1"
	[ -n "$clean" ] && {
		rm -rf $2
		mkdir -p $2
	}
	case $1 in
	*.tar.gz | *.tgz | *.tar.bz2 | *.tbz2 | *.tar.xz)
		tar xf $1 -C $2
		;;
	*.zip)
		unzip -q $1 -d $2
		;;
	*)
		log_warn "extension unsupported - $1"
		return 2
		;;
	esac
}
_chromium_install_extensions() {
	for provider_name in $(cat $_CONFIGURATION_DIRECTORY/extensions); do
		_chromium_install_extension
	done
}
_chromium_install_extension() {
	case $provider_name in
	ublock-origin)
		_github_fetch_latest_artifact gorhill uBlock uBlock0_ .chromium.zip
		;;
	Browserpass)
		_github_fetch_latest_artifact browserpass browserpass-extension browserpass-github- .crx
		;;
	Ghostery)
		artifact_url_function=_ghostery_artifact_url _github_fetch_latest_artifact ghostery ghostery-extension ghostery-chromium- .zip
		;;
	*)
		log_warn "unsupported extension: $provider_name"
		continue
		;;
	esac
}
_chromium_extension_load() {
	_chromium_extension_download_extract $1 $2 $3 || {
		browser_extension_delete=1 _chromium_extension_download_extract $1 $2 $3 || return 1
	}
	if [ -z "$registered_extensions" ]; then
		registered_extensions="$instance_directory/unpacked-extensions/$provider_name"
	else
		registered_extensions="$registered_extensions,$instance_directory/unpacked-extensions/$provider_name"
	fi
}
_chromium_extension_download_extract() {
	[ "$browser_extension_delete" ] && rm -f $conf_install_CACHE_PATH/$provider_name-$extension_version.crx.zip
	_download_fetch $1 ${2}-$3.crx.zip
	_extract_extract $conf_install_CACHE_PATH/$provider_name-$extension_version.crx.zip $instance_directory/unpacked-extensions/$provider_name
}
_ghostery_artifact_url() {
	version_without_v=$(printf '%s\n' "$3" | sed -e 's/^v//')
	git_github_artifact_url=https://github.com/$1/$2/releases/download/${3}/${4}${version_without_v}${5}
}
_github_latest_release() {
	curl -sL https://api.github.com/repos/$1/$2/releases/latest | jq -r ".tag_name"
}
_github_fetch_latest_artifact() {
	local _github_organization_name=$1
	local _github_repository_name=$2
	local _artifact_name=$3
	local _artifact_suffix=$4
	shift 4
	local _latest_version=$(_github_latest_release $_github_organization_name $_github_repository_name)
	[ -z "$git_artifact_url_function" ] && git_artifact_url_function=_github_artifact_url
	$git_artifact_url_function $_github_organization_name $_github_repository_name $_latest_version $_artifact_name $_artifact_suffix
	_download_fetch $git_github_artifact_url "$@"
	unset git_github_artifact_url
}
_github_artifact_url() {
	git_github_artifact_url=https://github.com/$1/$2/releases/download/${3}/${4}${3}${5}
}
_github_artifact_url_static() {
	git_github_artifact_url=https://github.com/$1/$2/releases/download/${3}/${4}
}
download_file=""
_download_fetch() {
	mkdir -p $APP_PLATFORM_CACHE_PATH
	local _cached_filename
	if [ $# -gt 1 ]; then
		_cached_filename="$2"
	else
		_cached_filename=$(basename $1 | sed -e 's/?.*$//')
	fi
	download_file=$APP_PLATFORM_CACHE_PATH/$_cached_filename
	[ -z "$no_cache" ] && {
		[ -e $download_file ] && {
			log_detail "$1 already downloaded to: $download_file"
			return
		}
	}
	if [ -z "$download_disabled" ]; then
		log_info "downloading $1 -> $download_file"
		curl $curl_options -o $download_file -s -L "$1"
	else
		_stdin_continue_if "Please manually download: $1 and place it in $download_file" "Y/n"
	fi
}
_download_install_file() {
	warn_on_error=1 validation_require "$1" "1 (_download_install_file) target filename" || return 1
	: ${_install_file_chmod:=444}
	log_info "installing $download_file -> $1"
	mkdir -p $(dirname $1)
	cp $download_file $1
	chmod $_install_file_chmod $1
	unset download_file
	[ -e $1 ] || log_warn "failed to install file to: $1"
}
_download_verify() {
	local _hash_algorithm
	_hash_algorithm=512
	shasum -a $_hash_algorithm -c $1 >/dev/null 2>&1
}
_provider_run_all() {
	_provider_run_wrapper _provider_run_all_callback "$@"
}
_provider_run_wrapper() {
	[ $provider_import_path ] || provider_import_path=$APP_LIBRARY_PATH/provider
	[ ! -e $provider_import_path ] && return 1
	local callback_function=$1
	shift
	application_name_prefix=$(printf '%s' $APPLICATION_NAME | tr '-' '_' | tr '.' '_')
	log_add_context $application_name_prefix
	$callback_function "$@"
	log_remove_context
}
_provider_run_all_callback() {
	for provider in $(find $provider_import_path -type f | sort -V); do
		_provider_run "$@"
	done
}
_provider_run() {
	provider_name=$(basename $provider | sed -e 's/\.sh$//')
	provider_function_name=$(printf '%s' $provider_name | tr '-' '_' | tr '.' '_')
	log_add_context $provider_name
	exec_call ${application_name_prefix}_before_each
	. $provider
	if [ "$#" -eq 0 ]; then
		${application_name_prefix}_${provider_function_name}${provider_function_suffix}
	else
		[ -n "$1" ] && $1
		[ -n "$2" ] && $2
	fi
	exec_call ${application_name_prefix}_after_each
	log_remove_context
	unset provider_name provider_function_name
}
_provider_run_all_named() {
	local callback_function=$1
	shift
	for provider_name in "$@"; do
		_provider_run_named $callback_function $provider_name
	done
}
_provider_run_named() {
	_provider_run_wrapper _provider_run_named_callback "$@"
}
_provider_run_named_callback() {
	provider=$(find $provider_import_path -type f -name "$2.sh" -print -quit)
	file_require "$provider" "provider"
	_provider_run "$1"
}
_provider_load() {
	[ $# -lt 1 ] && exit_with_error "provider name is required, ie. firefox"
	local _provider_name=$1
	shift
	[ $provider_import_path ] || provider_import_path=$APP_LIBRARY_PATH/provider
	local provider_file=$(find $provider_import_path -type f -name "$_provider_name.sh" | head -1)
	_include_optional $provider_file || exit_with_error "unable to load $provider_file | $provider_import_path"
}
case $APP_PLATFORM_PLATFORM in
Linux | FreeBSD)
	_CONFIGURATION_DIRECTORY=~/.config/chromium
	;;
*)
	exit_with_error "unsupported platform: $APP_PLATFORM_PLATFORM"
	;;
esac
_CONFIGURATION_DIRECTORY=~/.config/chromium
: ${conf_web_browser_chromium_cmd:=chromium}
browser_new_instance() {
  _BROWSER_CMD=$conf_web_browser_chromium_cmd
  chromium_instance_dir=$instance_directory/.config/chromium
  mkdir -p $chromium_instance_dir/Default
  [ ! -e $_CONFIGURATION_DIRECTORY/Default/Preferences ] && exit_with_error "preferences file does not exist: $_CONFIGURATION_DIRECTORY/Default/Preferences"
  cp -R $_CONFIGURATION_DIRECTORY/Default/Preferences "$chromium_instance_dir/Default/"
  cp -R $_CONFIGURATION_DIRECTORY/Default/Extensions "$chromium_instance_dir/Default/" 2>/dev/null
  log_info "updating conf to use new instance dir"
  find $instance_directory -type f ! -name '*.sqlite' -exec $GNU_SED -i "s|$HOME|$chromium_instance_dir|g" {} +
  mkdir -p $instance_directory/Downloads
  _SQLITE_DATABASE=$chromium_instance_dir/Default/History
  _QUERY="SELECT url,ROUND(LAST_VISIT_TIME/1000000) FROM urls WHERE url NOT LIKE 'chrome-extension://%' ORDER BY last_visit_time DESC"
  _chromium_install_extensions
  [ -n "$registered_extensions" ] && _browser_add_args "--load-extension=$registered_extensions"
}
_browser_remote_debug() {
  remotedebug
  if [ $_WEB_BROWSER_REMOTElog_debug -gt 0 ]; then
    remotedebug="=$web_browser_remote_debug"
  fi
  _browser_add_args "--remote-debugging-port${remotedebug}"
  [ "$_WEB_BROWSER_HEADLESS" ] && _browser_add_args --headless
}
_browser_private_window() {
  _browser_add_args --incognito
}
browser_http_proxy() {
  _browser_add_args "--proxy-server=http://${web_browser_http_proxy}"
}
_browser_socks_proxy() {
  _browser_add_args "--proxy-server=socks${conf_web_browser_socks_proxy_version}://$_WEB_BROWSER_SOCKS_PROXY"
}
_browser_cleanup() {
  rm -rf /tmp/.org,chromium.*
}
readonly REQUIRED_APP_CONF="conf_install_CACHE_PATH"
