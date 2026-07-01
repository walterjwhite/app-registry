#!/bin/sh
secrets_put "$@"
[ "$conf_secrets_overwrite_existing" ] && pass_options="$pass_options -f"
yes "$secret_value" | pass insert $1 && pass git push
