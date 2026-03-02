#!/bin/sh
case $APP_PLATFORM_PLATFORM in
Linux | FreeBSD)
  provider_path=~/.thunderbird
  provider_path_is_dir=1
  provider_no_root_user=1
  provider_exclude="calendar-data datareporting Mail security_state settings storage .parentlock abook* formhistory.sqlite lock global-messages-db.sqlite"
  provider_include="installs.ini profiles.ini"
  thunderbird_profile_files="containers.json \
		encrypted-openpgp-passphrase.txt extension-preferences.json extensions.json \
		key4.db logins.json mailViews.dat openpgp.sqlite permissions.sqlite pkcs11.txt \
		prefs.js session.json sessionCheckpoints.json SiteSecurityServiceState.txt \
		xulstore.json"
  if [ -e "$provider_path" ] && [ -e ~/.thunderbird/installs.ini ]; then
    thunderbird_instance_path=$(grep Default ~/.thunderbird/installs.ini | sed -e 's/^.*=//')
    thunderbird_message_filters=$(find "$provider_path"/$thunderbird_instance_path -type f -name msgFilterRules.dat | sed -e "s/^.*$thunderbird_instance_path/$thunderbird_instance_path/" | tr '\n' ' ')
    provider_include="$provider_include $thunderbird_message_filters"
    for thunderbird_file in $thunderbird_profile_files; do
      provider_include="$provider_include $thunderbird_instance_path/$thunderbird_file"
    done
  fi
  ;;
esac
_configuration_thunderbird_backup_post() {
  local thunderbird_prefs=$(find $APP_DATA_PATH/$provider_name -type f -name prefs.js -print -quit)
  [ $? -gt 0 ] && return 0
  cat $thunderbird_prefs | sort >$thunderbird_prefs.sorted
  mv $thunderbird_prefs.sorted $thunderbird_prefs
  rm -f $APP_DATA_PATH/$provider_name/extensions
  [ ! -e "$provider_path"/extensions ] && return
  cp "$provider_path"/extensions $APP_DATA_PATH/$provider_name 2>/dev/null
  if [ $(wc -l <$APP_DATA_PATH/$provider_name/extensions) -eq 0 ]; then
    basename $(find "$provider_path" -type f -path '*/extensions/*.xpi') 2>/dev/null |
      sed -e 's/\.xpi$//' | sort -u >>$APP_DATA_PATH/$provider_name/extensions
  fi
}
_configuration_thunderbird_restore_post() {
  [ ! -e $APP_DATA_PATH/$provider_name/extensions ] && return
  cp $APP_DATA_PATH/$provider_name/extensions "$provider_path"
}
_thunderbird_extensions() {
  thunderbird_provider_path=$(find $_INSTANCE_DIRECTORY/.thunderbird -maxdepth 1 -mindepth 1 -type d -print -quit)/extensions
  [ -z "$thunderbird_provider_path" ] && return
  rm -rf $thunderbird_provider_path && mkdir -p $thunderbird_provider_path
  log_info "installing extensions to: $thunderbird_provider_path"
  local thunderbird_provider_name
  for thunderbird_provider_name in $(cat $APP_DATA_PATH/$provider_name/extensions 2>/dev/null); do
    _thunderbird_extension $thunderbird_provider_name
  done
}
_thunderbird_extension() {
  case $1 in
  sendlater3@kamens.us)
    _thunderbird_provider_load $1 'https://addons.thunderbird.net/thunderbird/downloads/latest/send-later-3/addon-195275-latest.xpi'
    ;;
  {a62ef8ec-5fdc-40c2-873c-223b8a6925cc})
    _thunderbird_provider_load $1 'https://addons.thunderbird.net/thunderbird/downloads/latest/provider-for-google-calendar/addon-4631-latest.xpi'
    ;;
  *)
    log_warn "unsupported extension: $1"
    continue
    ;;
  esac
}
_thunderbird_provider_load() {
  _download_fetch $2
  log_detail "copying $downloaded_file -> $thunderbird_provider_path/$1.xpi"
  cp $downloaded_file $thunderbird_provider_path/$1.xpi
}
