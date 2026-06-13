#!/bin/sh
_has_updates() {
  unset SYSTEM_UPDATES
  for _UPDATE_TYPE in $conf_system_maintenance_patch_types; do
    _HAS_${_UPDATE_TYPE}_UPDATES && {
      _system_updates="$_system_updates $_UPDATE_TYPE"
    }
  done
  [ -z "$_system_updates" ] && return 1
  return 0
}
_has_freebsd_updates() {
  pager=cat
  exec_wrap freebsd-update $_freebsd_update_options --not-running-from-cron fetch
  warn_on_error=1 exec_wrap freebsd-update $_freebsd_update_options updatesready
  [ $? -eq 2 ] && return 1
  return 0
}
_has_freebsd_upgrade_updates() {
  local fbsd_architecture=$(uname -p)
  validation_require "$fbsd_architecture" fbsd_architecture
  local fbsd_current_version=$(uname -r | grep -E -o '[[:digit:],\.]{4,}')
  validation_require "$fbsd_current_version" fbsd_current_version
  local fbsd_current_integer_version=$(printf '%s' "$fbsd_current_version" | sed s/[.]//)
  local fbsd_url="https://download.freebsd.org/releases/$fbsd_architecture/"
  local fbsd_lines=$(curl $curl_flags --silent $fbsd_url)
  if [ $? -ne 0 ]; then
    log_warn "exit_with_error downloading release page"
    return 1
  fi
  local fbsd_versions=$(printf '%s' "$fbsd_lines" | grep -o -E '[[:digit:]]{2}\.[[:digit:]]{1}-[[:alpha:]]{4,}' | grep -v 'BETA$' | sort -u)
  local fbsd_version
  for fbsd_version in $(printf '%s' "$fbsd_versions"); do
    local fbsd_integer_version=$(echo "$fbsd_version" | sed s/[[:alpha:],.-]//g)
    [ "$fbsd_integer_version" -gt "$fbsd_current_integer_version" ] && {
      log_detail "available version: $fbsd_version"
      return 0
    }
  done
  local latest_version=$(curl $curl_flags -s https://download.freebsd.org/releases/amd64/ | awk '{print $3}' | grep RELEASE | tr -d '"' | tr -d '/' | cut -f2 -d'=' | sort | tail -1)
  local system_version=$(freebsd-version | /usr/local/bin/ggrep -Po '[\d\.]{1,}(-RELEASE)')
  [ "$latest_version" == "$system_version" ] && return 1
  local version_shortname=$(printf '%s' "$latest_version" | sed -e 's/-RELEASE.*$/R/')
  curl $curl_flags -f "https://www.freebsd.org/releases/$version_shortname/announce.asc" >/dev/null 2>&1
  [ $? -eq 22 ] && {
    log_warn "release $latest_version is not yet ready"
    return 1
  }
  return 0
}
_has_userland_updates() {
  exec_wrap pkg $_pkg_update_options update
  warn_on_error=1 exec_wrap pkg $_pkg_update_options upgrade -n
  [ $? -eq 0 ] && return 1
  exec_wrap pkg $_pkg_update_options upgrade -Fy
  return 0
}
_has_kernel_updates() {
  cd /usr/src
  local kernel_git_branch=$(git branch --no-color --show-current)
  validation_require "$kernel_git_branch" kernel_git_branch
  local _latest_remote_version=$(git ls-remote $(git remote -v | head -1 | awk {'print$2'}) | grep $kernel_git_branch | cut -f1)
  local _latest_local_version=$(git rev-parse HEAD)
  [ "$_latest_remote_version" = "$_latest_local_version" ] && return 1
  return 0
}
_has_noop_updates() {
  [ -n "$_OPTN_SYSTEM_MAINTENANCE_NOOP_UPDATES" ] && return 0
  return 1
}
