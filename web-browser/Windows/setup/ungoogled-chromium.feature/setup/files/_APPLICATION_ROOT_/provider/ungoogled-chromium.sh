#!/bin/sh
readonly BROWSER_CMD=ungoogled-chromium
case $APP_PLATFORM_PLATFORM in
Linux | FreeBSD)
  readonly CONFIGURATION_DIRECTORY=~/.config/ungoogled-chromium
  ;;
*)
  exit_with_error "unsupported platform: $APP_PLATFORM_PLATFORM"
  ;;
esac
readonly CONFIGURATION_DIRECTORY=~/.config/ungoogled-chromium
browser_new_instance() {
  chromium_instance_dir=$instance_directory/.config/ungoogled-chromium
  mkdir -p $chromium_instance_dir/Default
  if [ ! -e $_CONFIGURATION_DIRECTORY/Default/Preferences ]; then
    exit_with_error "preferences file does not exist: $_CONFIGURATION_DIRECTORY/Default/Preferences" 1
  fi
  cp -R $_CONFIGURATION_DIRECTORY/Default/Preferences "$chromium_instance_dir/Default/"
  cp -R $_CONFIGURATION_DIRECTORY/Default/Extensions "$chromium_instance_dir/Default/" 2>/dev/null
  log_info "updating conf to use new instance dir"
  find $instance_directory -type f ! -name '*.sqlite' -exec $GNU_SED -i "s|$HOME|$chromium_instance_dir|g" {} +
  mkdir -p $instance_directory/Downloads
  _SQLITE_DATABASE=$chromium_instance_dir/Default/History
  _QUERY="SELECT url,ROUND(LAST_VISIT_TIME/1000000) FROM urls WHERE url NOT LIKE 'chrome-extension://%' ORDER BY last_visit_time DESC"
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
