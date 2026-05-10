#!/bin/sh
case $APP_PLATFORM_PLATFORM in
Linux | FreeBSD)
  provider_path=~/.config/chromium
  ;;
Apple)
  provider_path=~/Library/"Application Support"/Google/Chrome
  ;;
Windows)
  provider_path="~/AppData/Local/Google/Chrome/User Data"
  ;;
esac
provider_path_is_dir=1
provider_include="Default/Preferences Default/Bookmarks"
provider_no_root_user=1
_configuration_chromium_backup_post() {
  local preferences_file=$(find $APP_DATA_PATH/$provider_name -type f -path '*/Default/Preferences' -print -quit)
  if [ -z "$preferences_file" ] || [ ! -e "$preferences_file" ]; then
    log_warn "chromium conf does not exist"
    return
  fi
  cat $preferences_file | jq -MS '{
    accessibility: { captions: { headless_caption_enabled: .accessibility.captions.headless_caption_enabled } },
    autofill: { credit_card_enabled: .autofill.credit_card_enabled },
    default_search_provider: .default_search_provider,
    default_search_provider_data: (.default_search_provider_data | map_values(del(.last_modified, .last_visited, .synced_guid, .date_created)))
  }' >$preferences_file.formatted
  mv $preferences_file.formatted $preferences_file
  if [ -e "$provider_path/extensions" ]; then
    cp "$provider_path/extensions" $APP_DATA_PATH/$provider_name
  else
    local provider_manifest
    rm -f $APP_DATA_PATH/$provider_name/extensions
    find "$provider_path" -type f -path '*/Default/Extensions/*/manifest.json' | while read provider_manifest; do
      grep name "$provider_manifest" | grep -v version_name | sort -u | tail -1 | awk {'print$2'} |
        tr -d '"' | tr -d ',' >>$APP_DATA_PATH/$provider_name/extensions
    done
  fi
}
_configuration_chromium_restore_post() {
  local preferences_file=$(find "$provider_path" -type f -path '*/Default/Preferences' -print -quit)
  [ -z "$preferences_file" ] && return
  cat $preferences_file | tr -d '\n' | tr -d ' ' >$preferences_file.formatted
  mv $preferences_file.formatted $preferences_file
  _configuration_chromium_restore_extensions
}
_configuration_chromium_restore_extensions() {
  cp $APP_DATA_PATH/$provider_name/extensions "$provider_path"
}
_configuration_chromium_export_post() {
  rm -rf $configuration_tmpdir/$provider_name/Default/Bookmarks
}
