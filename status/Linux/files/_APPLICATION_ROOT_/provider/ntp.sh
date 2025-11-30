#!/bin/sh
_APPLICATION_NAME=status
which ntpq >/dev/null 2>&1 || _FEATURE_NTP_DISABLED=1
ntp() {
	ntpq -pn 2>/dev/null | grep '^\*' >/dev/null 2>&1 && {
		_STATUS_MESSAGE="NTP is synchronized"
		return
	}
	_STATUS_MESSAGE="NTP is not synchronized"
}
