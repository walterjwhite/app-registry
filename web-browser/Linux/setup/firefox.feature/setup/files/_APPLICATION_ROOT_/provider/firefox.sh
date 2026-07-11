#!/bin/sh
_github_latest_release() {
  [ -z "$4" ] && {
    get_latest_${1}_version
    return
  }
  local _field=${4#.}
  curl $conf_curl_flags -sL https://api.github.com/repos/$2/$3/releases/latest | grep -m1 "\"$_field\"" | sed 's/.*"[^"]*": *"\([^"]*\)".*/\1/'
}
_github_fetch() {
  local download_url=$(curl $conf_curl_flags -s https://api.github.com/repos/$1/$2/releases/latest | jq -r "$3")
  [ -z "$download_url" ] && {
    log_warn "no matching artifact found"
    return 1
  }
  _download_fetch "$download_url" $4-$5
}
_github_install_latest() {
  local function_name=$(printf '%s' $1 | tr '-' '_')
  local latest_version=$(_github_latest_release "$function_name" "$2" "$3" "$4")
  local installed_version=$(get_installed_${function_name}_version)
  [ "$installed_version" = "$latest_version" ] && {
    log_detail "$1 is already installed and up-to-date"
    return
  }
  if [ -z "$installed_version" ]; then
    log_detail "installing $1"
  else
    log_detail "updating $1"
  fi
  _github_fetch "$2" "$3" "$5" "$6" "$latest_version" || return
  [ -z "$7" ] && {
    log_info "calling install_$function_name"
    install_$function_name
    return
  }
  _install_file_chmod=755 _download_install_file "$TARGET_APP_PLATFORM_BIN_PATH/$7"
}
_provider_run_all() {
  _provider_run_wrapper _provider_run_all_callback "$@"
}
_provider_run_wrapper() {
  [ $provider_import_path ] || provider_import_path=$APP_PATH/provider
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
    provider_status=$?
  else
    [ -n "$1" ] && $1
    [ -n "$2" ] && $2
  fi
  exec_call ${application_name_prefix}_after_each
  log_remove_context
  unset provider_name provider_function_name provider_status
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
  [ $provider_import_path ] || provider_import_path=$APP_PATH/provider
  local provider_file=$(find $provider_import_path -type f -name "$_provider_name.sh" | head -1)
  _include_optional "$provider_file" || exit_with_error "unable to load $provider_file | $provider_import_path"
}
_download_fetch() {
  mkdir -p "$TARGET_APP_PLATFORM_CACHE_PATH"
  local _cached_filename
  if [ $# -gt 1 ]; then
    _cached_filename="$2"
  else
    _cached_filename=$(basename "$1" | sed -e 's/?.*$//')
  fi
  download_file="$TARGET_APP_PLATFORM_CACHE_PATH/$_cached_filename"
  [ -z "$no_cache" ] && {
    [ -s "$download_file" ] && {
      log_detail "$1 already downloaded to: $download_file"
      return
    }
  }
  if [ -z "$download_disabled" ]; then
    log_info "downloading $1 -> $download_file"
    curl $conf_curl_flags -f -o "$download_file" -sL "$1"
    local _curl_status=$?
    if [ "$_curl_status" -ne 0 ]; then
      rm -f "$download_file"
      log_warn "failed to download ($_curl_status): $1"
      return $_curl_status
    fi
  else
    _stdin_continue_if "Please manually download: $1 and place it in $download_file" "Y/n"
  fi
}
_download_install_file() {
  warn_on_error=1 validation_require "$1" "1 (_download_install_file) target filename" || return 1
  warn_on_error=1 validation_require "$download_file" "download_file" || return 1
  : ${_install_file_chmod:=444}
  log_info "installing $download_file -> $1"
  if [ "${INSTALL_TARGET:-USER}" = "SYSTEM" ]; then
    sudo_run mkdir -p $(dirname $1)
    sudo_run cp "$download_file" $1
    sudo_run chmod $_install_file_chmod $1
  else
    mkdir -p $(dirname $1)
    cp "$download_file" $1
    chmod $_install_file_chmod $1
  fi
  unset download_file
  [ -e $1 ] || {
    log_warn "failed to install file to: $1"
    return 1
  }
  _install_record_path "$1"
}
_download_verify() {
  shasum -a 512 -c $1 >/dev/null 2>&1
}
readonly BROWSER_CMD=firefox
browser_new_instance() {
  log_info "copying profile to $instance_directory"
  mkdir -p $instance_directory
  tar cp - -C $HOME/ .mozilla | tar xp - -C $instance_directory
  log_info "updating conf to use new instance dir"
  find $instance_directory -type f ! -name '*.sqlite' -exec $GNU_SED -i "s|$HOME|$instance_directory|g" {} +
  _QUERY="SELECT url,ROUND(last_visit_date / 1000000) FROM moz_places WHERE VISIT_COUNT > 0 ORDER BY last_visit_date DESC"
  firefox_install_extensions
}
_history_file() {
  _SQLITE_DATABASE=$(find $instance_directory -type f -name 'places.sqlite')
  [ $_SQLITE_DATABASE ] || exit_with_error "error locating places database"
}
_browser_remote_debug() {
  if [ $_WEB_BROWSER_REMOTElog_debug -gt 0 ]; then
    _browser_add_args --remote-debugging-port=$web_browser_remote_debug
  else
    _browser_add_args --remote-debugging-port
  fi
  [ "$_WEB_BROWSER_HEADLESS" ] && _browser_add_args --headless
}
_browser_private_window() {
  _browser_add_args --private-window
  _browser_add_args "--new-instance"
}
browser_http_proxy() {
  http_proxy=$web_browser_http_proxy
  https_proxy=$web_browser_http_proxy
  _browser_add_args "--new-instance"
}
_browser_socks_proxy() {
  user_pref_file=$(find $instance_directory -type f -name prefs.js -print -quit)
  file_require $user_pref_file 'Firefox user pref.js'
  socks_host="${_WEB_BROWSER_SOCKS_PROXY%%:*}"
  socks_port="${_WEB_BROWSER_SOCKS_PROXY#*:}"
  printf 'user_pref("network.proxy.socks", "%s");\n' "$socks_host" >>$user_pref_file
  printf 'user_pref("network.proxy.socks_port", %s);\n' "$socks_port" >>$user_pref_file
  printf 'user_pref("network.proxy.type", 1);\n' >>$user_pref_file
  _browser_add_args "--new-instance"
}
firefox_install_extensions() {
  _FIREFOX_EXTENSION_PATH=$(find $instance_directory/.mozilla/firefox -mindepth 1 -maxdepth 1 -type d -print -quit)/extensions
  rm -rf $_FIREFOX_EXTENSION_PATH && mkdir -p $_FIREFOX_EXTENSION_PATH
  log_info "installing extensions to: $_FIREFOX_EXTENSION_PATH"
  provider_name
  for provider_name in $(cat $instance_directory/.mozilla/extensions 2>/dev/null); do
    firefox_install_extension $provider_name
  done
}
firefox_install_extension() {
  case $1 in
  browserpass@maximbaz.com)
    firefox_extension_load $1 https://addons.mozilla.org/firefox/downloads/file/4187654/browserpass_ce-3.8.0.xpi
    ;;
  firefox@ghostery.com)
    firefox_extension_load $1 https://addons.mozilla.org/firefox/downloads/file/4207768/ghostery-8.12.5.xpi
    ;;
  passff@invicem.pro)
    firefox_extension_load $1 https://addons.mozilla.org/firefox/downloads/file/4202971/passff-1.16.xpi
    ;;
  uBlock0@raymondhill.net)
    firefox_extension_load $1 https://addons.mozilla.org/firefox/downloads/file/4198829/ublock_origin-1.57.2.xpi
    ;;
  jid1-ZAdIEUB7XOzOJw@jetpack)
    firefox_extension_load $1 https://addons.mozilla.org/firefox/downloads/file/4205925/duckduckgo_for_firefox-2023.12.6.xpi
    ;;
  *)
    log_warn "unsupported extension: $1"
    continue
    ;;
  esac
}
firefox_extension_load() {
  _download_fetch $2
  log_detail "copying $download_file -> $_FIREFOX_EXTENSION_PATH/$1.xpi"
  cp $download_file $_FIREFOX_EXTENSION_PATH/$1.xpi
}
