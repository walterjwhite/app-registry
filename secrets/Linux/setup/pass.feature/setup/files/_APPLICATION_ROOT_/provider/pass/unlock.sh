#!/bin/sh
secret_key=$(. $LIBRARY_PATH/$APPLICATION_NAME/provider/$conf_secrets_provider/find.sh | head -1)
pass show $secret_key >/dev/null 2>&1
