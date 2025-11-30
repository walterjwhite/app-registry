#!/bin/sh
_APPLICATION_NAME=secrets
[ "$_CONF_SECRETS_FORCE_DELETE" ] && _PASS_OPTIONS="$_PASS_OPTIONS -f"
pass rm -r $_PASS_OPTIONS $1 && pass git push
