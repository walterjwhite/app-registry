#!/bin/sh
readonly BROWSER_CMD=librewolf
browser_new_instance() {
  log_info "copying profile to $instance_directory"
  mkdir -p $instance_directory
  tar cp - -C ~/ --exclude bookmarkbackups --exclude datareporting --exclude security_state --exclude sessionstore-backups --exclude settings/data.safe.bin --exclude storage --exclude weave --exclude .parentlock --exclude favicons.sqlite --exclude formhistory.sqlite --exclude key4.db --exclude lock --exclude permissions.sqlite --exclude places.sqlite .mozilla | tar xp - -C $instance_directory
  log_info "updating conf to use new instance dir"
  find $instance_directory -type f ! -name '*.sqlite' -exec $GNU_SED -i "s|$HOME|$instance_directory|g" {} +
  _QUERY="SELECT url,ROUND(last_visit_date / 1000000) FROM moz_places WHERE VISIT_COUNT > 0 ORDER BY last_visit_date DESC"
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
  file_require $user_pref_file 'Librewolf user pref.js'
  socks_host="${_WEB_BROWSER_SOCKS_PROXY%%:*}"
  socks_port="${_WEB_BROWSER_SOCKS_PROXY#*:}"
  printf 'user_pref("network.proxy.socks", "%s");\n' "$socks_host" >>$user_pref_file
  printf 'user_pref("network.proxy.socks_port", %s);\n' "$socks_port" >>$user_pref_file
  printf 'user_pref("network.proxy.type", 1);\n' >>$user_pref_file
  _browser_add_args "--new-instance"
}
