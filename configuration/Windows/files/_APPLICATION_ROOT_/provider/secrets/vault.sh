#!/bin/sh
_APPLICATION_NAME=configuration
_PLUGIN_CONFIGURATION_PATH=~/.saferc
_PLUGIN_NO_ROOT_USER=1
_CONFIGURE_VAULT_CLEAR() {
	rm -f ~/.saferc ~/.svtoken
}
