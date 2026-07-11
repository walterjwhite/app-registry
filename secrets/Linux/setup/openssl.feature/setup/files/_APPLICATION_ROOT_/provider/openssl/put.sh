#!/bin/sh
secrets_put "$@"
mkdir -p $(dirname $1)
printf '%s' "$secret_value" | openssl enc -aes-256-cbc -salt -pbkdf2 -out $1.enc -kfile $conf_secrets_openssl_key || exit_with_error "failed to encrypt secret: $1"
git add $1.enc
git commit -am "add - $1"
git push || exit_with_error "secret saved locally but failed to push to remote: $1"
