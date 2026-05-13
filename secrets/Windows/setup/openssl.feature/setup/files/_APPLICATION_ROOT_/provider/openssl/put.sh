#!/bin/sh
. $LIBRARY_PATH/$APPLICATION_NAME/provider/$conf_secrets_provider/init.sh
secrets_put "$@"
mkdir -p $(dirname $1)
printf '%s' $secret_value | openssl enc -aes-256-cbc -salt -pbkdf2 -out $1.enc -kfile $conf_secrets_openssl_key
git add $1.enc
git commit -am "add - $1"
git push
