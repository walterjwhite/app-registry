#!/bin/sh
_gsettings_exist() {
	gsettings list-recursively "$1" >/dev/null 2>&1
}
_gsettings_dump() {
	local schema=$1
	_gsettings_exist "$schema" || {
		log_warn "gsettings do not exist for $schema"
		return 0
	}
	mkdir -p $APP_DATA_PATH/$provider_name
	gsettings list-recursively "$schema" 2>&1 | sed -e "s/^$schema //" >$APP_DATA_PATH/$provider_name/gsettings.conf
	return 0
}
_gsettings_restore() {
	local schema=$1
	[ ! -e "$APP_DATA_PATH/$provider_name/gsettings.conf" ] && {
		log_warn "unable to restore gsettings for $APP_DATA_PATH/$provider_name/gsettings.conf [$schema]"
		return 0
	}
	local _gsettings_line
	local _gsettings_key _gsettings_value
	while read _gsettings_line; do
		_gsettings_key=$(printf '%s' "$_gsettings_line" | sed -e 's/ .*//')
		_gsettings_value=$(printf '%s' "$_gsettings_line" | sed -e 's/[[:alnum:]-]* //')
		gsettings set $schema "$_gsettings_key" "$_gsettings_value"
	done <"$APP_DATA_PATH/$provider_name/gsettings.conf"
	return 0
}
which meld >/dev/null 2>&1 || {
  return
}
provider_path=~/.config
provider_path_is_dir=1
provider_path_is_skip_prepare=1
provider_no_root_user=1
_configuration_meld_backup() {
  _gsettings_dump org.gnome.meld
}
_configuration_meld_restore() {
  _gsettings_restore org.gnome.meld 2>/dev/null
}
_configuration_meld_clear() {
  :
}
