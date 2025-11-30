#!/bin/sh
_APPLICATION_NAME=configuration
_PLUGIN_CONFIGURATION_PATH=~/.config/walterjwhite
_PLUGIN_CONFIGURATION_PATH_IS_DIR=1
_CONFIGURE_WALTERJWHITE_CONF_RESTORE_POST() {
	_CONFIGURE_WALTERJWHITE_XDG_DEFAULTS
	_CONFIGURE_WALTERJWHITE_SCRIPTS
}
_CONFIGURE_WALTERJWHITE_XDG_DEFAULTS() {
	case $_PLATFORM in
	FreeBSD | Linux) ;;
	*)
		return 1
		;;
	esac
	[ ! -e ~/.config/walterjwhite/shell/xdg-open-defaults ] && return 2
	local application
	local filetype
	for application in $(ls ~/.config/walterjwhite/shell/xdg-open-defaults); do
		_INFO "Setting defaults for $application"
		while read filetype; do
			_INFO "setting default: $application -> $filetype"
			xdg-mime default $application $filetype
		done <~/.config/walterjwhite/shell/xdg-open-defaults/$application
	done
}
_CONFIGURE_WALTERJWHITE_SCRIPTS() {
	local script
	for script in $(find ~/.config/walterjwhite/shell/scripts -type f 2>/dev/null); do
		_INFO "Running script $(basename $script)"
		. $script
	done
}
