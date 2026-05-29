#!/bin/sh
. $LIBRARY_PATH/$APPLICATION_NAME/provider/$conf_secrets_provider/init.sh
find . -type f ! -path '*/.git/*' -name '*.enc' |
  sort -u |
  sed -e "s/^.*\///" -e 's/\.enc$//' |
  xargs -L1 -P$conf_secrets_check_parallelization_count _secrets_check
