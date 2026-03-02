#!/bin/sh
_SECRET_KEY=$(. /usr/local/walterjwhite/secrets/provider/$_CONF_SECRETS_PROVIDER/find.sh | head -1)
pass show $_SECRET_KEY >/dev/null 2>&1
