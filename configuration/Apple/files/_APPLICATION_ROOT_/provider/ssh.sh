#!/bin/sh
_APPLICATION_NAME=configuration
_PLUGIN_CONFIGURATION_PATH=~/.ssh
_PLUGIN_CONFIGURATION_PATH_IS_DIR=1
_PLUGIN_EXCLUDE="socket"
_CONFIGURE_SSH_CLEAR() {
	_WARN "Not clearing ssh"
}
_CONFIGURE_SSH_RESTORE_PRE() {
	if [ -n "$_BACKUP_SSH" ] && [ -e ~/.ssh ]; then
		_WARN "_BACKUP_SSH was set, backing up ssh config"
		mv ~/.ssh ~/.ssh.original
	fi
}
_CONFIGURE_SSH_RESTORE_POST() {
	mkdir -p ~/.ssh/socket
	find ~/.ssh -type d -exec chmod 700 {} +
	find ~/.ssh -type f -exec chmod 600 {} +
	if [ -n "$_BACKUP_SSH" ]; then
		_WARN "_BACKUP_SSH was set, restoring ssh/config"
		mv ~/.ssh ~/.ssh.restore
		mv ~/.ssh.original ~/.ssh
		chmod 600 ~/.ssh/config
	fi
}
