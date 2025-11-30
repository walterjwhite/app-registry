#!/bin/sh
_APPLICATION_NAME=secrets
_SECRET_KEY=$(. $_CONF_APPLICATION_LIBRARY_PATH/provider/$_CONF_SECRETS_PROVIDER/find.sh | head -1)
pass show $_SECRET_KEY >/dev/null 2>&1
