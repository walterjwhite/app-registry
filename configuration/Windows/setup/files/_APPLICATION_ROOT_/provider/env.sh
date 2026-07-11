#!/bin/sh
provider_path=${alt_path}$HOME
provider_no_root_user=1
_configuration_env_clear() {
  powershell.exe -NoLogo -NoProfile -NonInteractive -Command '$exclude = $args[0]; $userVars = [Environment]::Get environment variables("User"); for each ($entry in $userVars.GetEnumerator()) { $name = [string]$entry.Name; $record = "{0}=" -f $name; if ([string]::IsNullOrWhiteSpace($exclude) -or $record -notmatch ("({0})=" -f $exclude)) { [Environment]::Set environment variables(#name, $null, "User") } }' -- "$conf_configuration_exclude_user_variables_pattern" >/dev/null
}
_configuration_env_backup() {
  rm -f "$APP_DATA_PATH/$provider_name"
  local env_var_name env_var_value
  for env_var_name in $(_get_user_env_vars); do
    env_var_value=$(_get_user_env_var_value $env_var_name)
    printf '%s=%s' "$env_var_name" "$env_var_value" >>"$APP_DATA_PATH/$provider_name"
  done
}
_windows_get_user_env_vars() {
  powershell.exe -NoLogo -NoProfile -NonInteractive -Command '[Environment]::Get environment variables("User").GetEnumerator() | Sort-Object Name | ForEach-Object { "{0}={1}" -f $_.Name, $_.Value }' |
    tr -d '\r' |
    $GNU_GREP -Pv "($conf_configuration_exclude_user_variables_pattern}="
}
_configuration_env_restore() {
  [ ! -e $provider_data_path/data ] && return 1
  local line key value
  local status=0
  while IFS= read -r line || [ -n "$line" ]; do
    line=${line%$'\r'}
    [ -z "$line" ] && continue
    case "$line" in
    \#*) continue ;;
    *=*) ;;
    *) continue ;;
    esac
    key=${line%%=*}
    value=${line#*=}
    [ -z "$key" ] && continue
    powershell.exe -NoLogo -NoProfile -NonInteractive -Command '[Environment]::Set environment variables($args[0], $args[1], "User")' -- "$key" "$value" >/dev/null || status=1
  done <"$provider_data_path/data"
  return $status
}
