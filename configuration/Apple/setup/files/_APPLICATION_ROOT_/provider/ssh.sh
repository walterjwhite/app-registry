#!/bin/sh
provider_path=${alt_path}$HOME/.ssh
provider_path_is_dir=1
provider_exclude="socket"
_configuration_ssh_clear() {
  log_warn "not clearing ssh"
}
_configuration_ssh_restore_pre() {
  if [ -n "$backup_ssh" ] && [ -e $HOME/.ssh ]; then
    log_warn "backup_ssh was set, backing up ssh config"
    rm -rf $HOME/.ssh.original
    mv $HOME/.ssh $HOME/.ssh.original
  fi
  mkdir -p $HOME/.ssh
}
_configuration_ssh_restore_post() {
  mkdir -p $HOME/.ssh/socket
  find $HOME/.ssh -type d -exec chmod 700 {} +
  find $HOME/.ssh -type f -exec chmod 600 {} +
  if [ -n "$backup_ssh" ]; then
    log_warn "backup_ssh was set, restoring ssh/config"
    rm -rf $HOME/.ssh.restore
    mv $HOME/.ssh $HOME/.ssh.restore
    mv $HOME/.ssh.original $HOME/.ssh
    chmod 600 $HOME/.ssh/config
  fi
}
