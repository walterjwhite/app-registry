#!/bin/sh
_APPLICATION_NAME=dev
_include
: ${_CONF_DEV_FORMAT_PARALLEL:=10}
: ${_CONF_DEV_SSH_KEYTYPE:=ed25519}
: ${_CONF_DEV_LOMBOK_SLF4J_LOGGER_NAME:=LOGGER}
: ${_CONF_DEV_VSCODE_IDE:=/usr/local/bin/vscode}
_NO_EXEC=1
if [ "$#" -eq 0 ]; then
	SHELL_PATH=.
else
	SHELL_PATH="$*"
fi
shell_find | xargs -P$_CONF_DEV_FORMAT_PARALLEL -I _F sh-app-fmt _F
