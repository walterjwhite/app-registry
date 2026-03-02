#!/bin/sh
secrets_put "$@"
mkdir -p $(dirname $1)
printf '%s' $secret_value | openssl enc -aes-256-cbc -salt -pbkdf2 -in /dev/stdin -out $1.enc -kfile $conf_secrets_openssl_key
git add $1.enc
git commit -am "add - $1"
git push
