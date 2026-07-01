#!/bin/sh
case $APP_PLATFORM_PLATFORM in
Linux | FreeBSD)
  provider_path=${alt_path}$HOME/.config/chromium
  ;;
Apple)
  provider_path=${alt_path}$HOME/Library/"Application Support"/Google/Chrome
  ;;
Windows)
  provider_path="${alt_path}$HOME/AppData/Local/Google/Chrome/User Data"
  ;;
esac
provider_path_is_dir=1
provider_include="Default/Preferences Default/Bookmarks"
provider_no_root_user=1
_configuration_chromium_backup_post() {
  local preferences_file=$(find "$provider_data_path" -type f -path '*/Default/Preferences' -print -quit)
  if [ -z "$preferences_file" ] || [ ! -e "$preferences_file" ]; then
    log_warn "chromium conf does not exist"
    return
  fi
  _configuration_chromium_remove_keys >"$preferences_file.formatted"
  mv "$preferences_file.formatted" "$preferences_file"
  if [ -e "$provider_path/extensions" ]; then
    cp "$provider_path/extensions" "$provider_data_path"
  else
    local provider_manifest
    rm -f "$provider_data_path/extensions"
    find "$provider_path" -type f -path '*/Default/Extensions/*/manifest.json' | while read provider_manifest; do
      grep name "$provider_manifest" | grep -v version_name | sort -u | tail -1 | awk {'print$2'} |
        tr -d '"' | tr -d ',' >>"$provider_data_path/extensions"
    done
  fi
}
_configuration_chromium_restore_post() {
  local preferences_file=$(find "$provider_path" -type f -path '*/Default/Preferences' -print -quit)
  [ -z "$preferences_file" ] && return
  cat "$preferences_file" | tr -d '\n' | tr -d ' ' >"$preferences_file.formatted"
  mv "$preferences_file.formatted" "$preferences_file"
  _configuration_chromium_restore_extensions
}
_configuration_chromium_restore_extensions() {
  cp "$provider_data_path/extensions" "$provider_path"
}
_configuration_chromium_export_post() {
  rm -rf "$configuration_tmpdir/$provider_name/Default/Bookmarks"
}
_configuration_chromium_remove_keys() {
  command -v jq >/dev/null 2>&1 || {
    _configuration_chromium_remove_keys_alt
    return
  }
  cat "$preferences_file" | jq -MS '{
    accessibility: { captions: { headless_caption_enabled: .accessibility.captions.headless_caption_enabled } },
    autofill: { credit_card_enabled: .autofill.credit_card_enabled },
    default_search_provider: .default_search_provider,
    default_search_provider_data: (.default_search_provider_data | map_values(del(.last_modified, .last_visited, .synced_guid, .date_created)))
  }'
}
_configuration_chromium_remove_keys_alt() {
  node -e "
  const fs = require('fs');
  const data = JSON.parse(fs.readFileSync(process.env.preferences_file, 'utf8'));
  // Clean up default_search_provider_data if it exists
  if (data.default_search_provider_data) {
    for (const key in data.default_search_provider_data) {
      delete data.default_search_provider_data[key].last_modified;
      delete data.default_search_provider_data[key].last_visited;
      delete data.default_search_provider_data[key].synced_guid;
      delete data.default_search_provider_data[key].date_created;
    }
  }
  // Construct the filtered object
  const result = {
    accessibility: { 
      captions: { 
        headless_caption_enabled: data.accessibility?.captions?.headless_caption_enabled 
      } 
    },
    autofill: { 
      credit_card_enabled: data.autofill?.credit_card_enabled 
    },
    default_search_provider: data.default_search_provider,
    default_search_provider_data: data.default_search_provider_data
  };
  // Write out sorted keys and 2-space indentation (matches jq -M and jq -S)
  const stringifyAndSort = (obj) => {
    if (obj === null || typeof obj !== 'object') return obj;
    if (Array.isArray(obj)) return obj.map(stringifyAndSort);
    return Object.keys(obj).sort().reduce((acc, key) => {
      acc[key] = stringifyAndSort(obj[key]);
      return acc;
    }, {});
  };
  fs.writeFileSync(process.env.preferences_file + '.formatted', JSON.stringify(stringifyAndSort(result), null, 2));
"
}
