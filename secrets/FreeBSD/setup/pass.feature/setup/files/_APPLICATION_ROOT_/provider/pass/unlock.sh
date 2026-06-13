#!/bin/sh
secret_key=$(. $APP_PLATFORM_PATH/apps/$APPLICATION_NAME/provider/$conf_secrets_provider/find.sh | head -1)
pass show $secret_key >/dev/null 2>&1
