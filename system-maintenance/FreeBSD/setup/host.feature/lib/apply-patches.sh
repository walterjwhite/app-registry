#!/bin/sh
_patch_freebsd() {
  exec_wrap freebsd-update $_freebsd_update_options install
  if [ $? -eq 2 ]; then
    log_warn "no updates available, fetch first"
    return
  fi
  _reboot_required="FreeBSD updated"
  _check_restart=1
}
_patch_freebsd_upgrade() {
  _patch_freebsd_upgrade_do upgrade install
}
_patch_freebsd_upgrade_install() {
  _patch_freebsd_upgrade_do install kernel
}
_patch_freebsd_upgrade_kernel() {
  _patch_kernel
}
_patch_freebsd_upgrade_do() {
  validation_require "$_PATCH_ARGUMENTS" _PATCH_ARGUMENTS
  exec_wrap freebsd-update $_freebsd_update_options $1 -r $_PATCH_ARGUMENTS
  if [ $? -eq 2 ]; then
    log_warn "no upgrades available"
    return
  fi
  _reboot_required="FreeBSD Upgrade ${1}ed"
  _check_restart=0
  _patch_be
}
_patch_userland() {
  exec_wrap pkg $_pkg_update_options upgrade -y
  _check_restart=1
}
_patch_kernel() {
  if [ -n "$_on_jail" ]; then
    exit_with_error "cannot update kernel for jail - $_jail_name"
  fi
  cd /usr/src
  exec_wrap git reset --hard HEAD
  rm -f $(git status | grep '^??' | grep -v sys/conf/amd64/custom)
  local system_version=$(uname -r | sed -e 's/-RELEASE.*//')
  exec_wrap git checkout releng/$system_version
  exec_wrap git pull
  kernconf=custom
  exec_wrap make buildkernel && make installkernel
  log_info "rebuilt kernel, please reboot to use patched kernel"
  _reboot_required="Kernel updated"
}
_patch_noop() {
  log_warn "this is a noop patch for test purposes"
  [ -n "$_SYSTEM_MAINTENANCE_FAIL" ] && {
    exit_with_error "previous cmd failed: _SYSTEM_MAINTENANCE_FAIL was set to true"
  }
  [ -n "$_SYSTEM_MAINTENANCE_NOOP_RUNTIME" ] && {
    sleep $_SYSTEM_MAINTENANCE_NOOP_RUNTIME
  }
  log_warn "please reboot to install updates"
}
