#!/bin/sh
_be_init() {
  unset _system_configuration_file _patches _system_branch _system_hash _system_be _system_be_with_sequence _active_be _last_sequence_file _last_sequence
  _system_configuration_file=$_JAIL_PATH${APP_PLATFORM_ROOT}${PLATFORM_SYSTEM_ID_PATH}
  _patches=$_JAIL_PATH/usr/local/etc/walterjwhite/patches
  _system_branch=$(head -1 $_system_configuration_file | tr '/' '_')
  _system_hash=$(head -4 $_system_configuration_file | tail -1 | cut -c 1-8)
  _system_be=${_system_hash}.${_system_branch}
  _system_be_with_sequence=$_system_be
  if [ -n "$_jail_name" ]; then
    _active_be=$(zfs list -H -t snapshot $_JAIL_PATH | tail -1 | awk {'print$1'})
  else
    _active_be=$(beadm list -H | grep NR | awk {'print$1'})
  fi
  if [ -z "$_jail_name" ]; then
    if [ -z "$_active_be" ]; then
      system=$_logging_context _system_alert "reboot into latest BE: $_system_be"
      exit_with_error "reboot into latest BE: $_system_be"
    fi
  fi
  mkdir -p /usr/local/etc/walterjwhite/patches $_JAIL_PATH/usr/local/etc/walterjwhite/patches
  _last_sequence_file=$(find $_JAIL_PATH/usr/local/etc/walterjwhite/patches -type f | sort -n | tail -1)
  if [ -n "$_last_sequence_file" ]; then
    _last_sequence=$(basename $_last_sequence_file)
    _system_be_with_sequence="$_system_be.$_last_sequence"
  else
    _last_sequence=000
    _last_sequence_file=$_JAIL_PATH/usr/local/etc/walterjwhite/patches/$_last_sequence
    _system_be_with_sequence="$_system_be.$_last_sequence"
    _first_boot=1 _create_be $_system_be_with_sequence
  fi
}
