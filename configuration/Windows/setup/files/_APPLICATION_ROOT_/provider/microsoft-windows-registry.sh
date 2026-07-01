#!/bin/sh
provider_path="${alt_path}$HOME/AppData/Local/walterjwhite/shell/registry"
provider_path_is_dir=1
provider_no_root_user=1
_registry_ps_dir="$APP_PLATFORM_PATH/microsoft/windows/registry"
_configuration_microsoft_windows_registry_backup() {
  rm -rf "$provider_data_path"
  mkdir -p "$provider_data_path"
  powershell.exe -NoLogo -NoProfile -NonInteractive -File \
    "$APP_PATH/microsoft/windows/registry/backup.ps" \
    -DestDir "$(cygpath -w "$provider_data_path")" \
    -Keys "$microsoft_windows_registry_keys" >/dev/null
}
_configuration_microsoft_windows_registry_restore() {
  [ ! -d "$provider_data_path" ] && return 1
  powershell.exe -NoLogo -NoProfile -NonInteractive -File \
    "$APP_PATH/microsoft/windows/registry/restore.ps" \
    -SrcDir "$(cygpath -w "$provider_data_path")" >/dev/null
}
_configuration_microsoft_windows_registry_compare() {
  local tmp_dir=$(_mktemp_options=d _mktemp_mktemp)
  exit_defer rm -rf "$tmp_dir"
  powershell.exe -NoLogo -NoProfile -NonInteractive -File \
    "$APP_PATH/microsoft/windows/registry/backup.ps" \
    -DestDir "$(cygpath -w "$tmp_dir")" \
    -Keys "$conf_configuration_microsoft_windows_registry_keys" >/dev/null
  $conf_configuration_comparison_tool_cmdline "$provider_data_path" "$tmp_dir"
}
