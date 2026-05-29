#!/bin/sh
cd ~/.openssl-store
find ~/.openssl-store -type f ! -path '*/.git/*' -name '*.enc' |
  sort -u |
  sed -e "s/^.*\/.openssl-store\///" -e 's/\.enc$//' |
  xargs -L1 -P$_CONF_SECRETS_CHECK_PARALLELIZATION_COUNT _secrets_check
