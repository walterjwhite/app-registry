#!/bin/sh
. $LIBRARY_PATH/$APPLICATION_NAME/provider/$conf_secrets_provider/init.sh
git rm -rf $1 && git commit $1 -m "remove - $1" && git push
