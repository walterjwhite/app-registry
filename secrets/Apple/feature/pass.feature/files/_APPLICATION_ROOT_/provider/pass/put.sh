#!/bin/sh
_APPLICATION_NAME=secrets
[ "$_CONF_SECRETS_OVERWRITE_EXISTING" ] && _PASS_OPTIONS="$_PASS_OPTIONS -f"
yes "$_SECRET_VALUE" | pass insert $1 && pass git push
