#!/bin/sh
cd ~/.openssl-store
find ~/.openssl-store -type f ! -path '*/.git/*' -name '*.enc' |
  sort -u |
  sed -e "s/^.*\/.openssl-store\///" -e 's/\.enc$//' |
  xargs -L1 -P$conf_secrets_check_parallelization_count _secrets_check
