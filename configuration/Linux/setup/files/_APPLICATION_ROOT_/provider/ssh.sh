#!/bin/sh
provider_path=~/.ssh
provider_path_is_dir=1
provider_exclude="socket"
_configuration_ssh_clear() {
  log_warn "not clearing ssh"
}
_configuration_ssh_restore_pre() {
  if [ -n "$backup_ssh" ] && [ -e ~/.ssh ]; then
    log_warn "backup_ssh was set, backing up ssh config"
    rm -rf ~/.ssh.original
    mv ~/.ssh ~/.ssh.original
  fi
  mkdir -p ~/.ssh
}
_configuration_ssh_restore_post() {
  mkdir -p ~/.ssh/socket
  find ~/.ssh -type d -exec chmod 700 {} +
  find ~/.ssh -type f -exec chmod 600 {} +
  if [ -n "$backup_ssh" ]; then
    log_warn "backup_ssh was set, restoring ssh/config"
    rm -rf ~/.ssh.restore
    mv ~/.ssh ~/.ssh.restore
    mv ~/.ssh.original ~/.ssh
    chmod 600 ~/.ssh/config
  fi
}
