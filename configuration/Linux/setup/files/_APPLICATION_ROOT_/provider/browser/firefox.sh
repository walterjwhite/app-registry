#!/bin/sh
provider_path=~/.mozilla
provider_path_is_dir=1
provider_include="firefox/installs.ini firefox/profiles.ini native-messaging-hosts"
provider_no_root_user=1
_configuration_firefox_compare() {
  $conf_configuration_comparison_tool_cmdline "$provider_path" $APP_DATA_PATH/firefox
}
_configuration_firefox_backup_pre() {
  local prefsjs_path=$(find "$provider_path"/firefox -type f -name prefs.js -print -quit | sed -e 's/^.*\/\.mozilla\///')
  [ -z "$prefsjs_path" ] && return
  local firefox_profile_dir=$(dirname "$prefsjs_path")
  provider_include="$provider_include $firefox_profile_dir/addons.json $firefox_profile_dir/extension-preferences.json $firefox_profile_dir/extension-settings.json $firefox_profile_dir/extensions.json $firefox_profile_dir/prefs.js $firefox_profile_dir/search.json.mozlz4"
}
_configuration_firefox_backup_post() {
  local provider_manifest
  rm -f $APP_DATA_PATH/$provider_name/extensions
  cp "$provider_path"/extensions $APP_DATA_PATH/$provider_name 2>/dev/null
  if [ $(wc -l <$APP_DATA_PATH/$provider_name/extensions) -eq 0 ]; then
    basename $(find "$provider_path"/firefox -type f -path '*/extensions/*.xpi') 2>/dev/null |
      sed -e 's/\.xpi$//' | sort -u >>$APP_DATA_PATH/$provider_name/extensions
  fi
  local prefsjs=$(find $APP_DATA_PATH/$provider_name -type f -name prefs.js -print -quit)
  [ -z "$prefsjs" ] && return
  $GNU_SED -i '/app.update.lastUpdateTime/d' $prefsjs
  $GNU_SED -i '/extensions.webextensions/d' $prefsjs
  $GNU_SED -i '/last_check/d' $prefsjs
  $GNU_SED -i '/checked/d' $prefsjs
}
_configuration_firefox_restore_post() {
  [ -e $APP_DATA_PATH/$provider_name/extensions ] && {
    cp $APP_DATA_PATH/$provider_name/extensions "$provider_path"
  }
}
