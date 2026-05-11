#!/bin/sh
: ${conf_secrets_openssl_key:=~/.config/walterjwhite/secrets.openssl.key}
[ ! -e ~/.openssl-store ] && {
  git init ~/.openssl-store
}
cd ~/.openssl-store
