#!/bin/sh
. /usr/local/walterjwhite/secrets/provider/$conf_secrets_provider/init.sh
secrets_last_changed "." enc "$@"
