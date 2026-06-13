#!/bin/sh
_APPLICATION_NAME=secrets
mkdir -p $(dirname $1)
printf '%s' $_SECRET_VALUE | openssl enc -aes-256-cbc -salt -pbkdf2 -in /dev/stdin -out $1.enc -kfile $_CONF_SECRETS_OPENSSL_KEY
git add $1.enc
git commit -am "add - $1"
git push
