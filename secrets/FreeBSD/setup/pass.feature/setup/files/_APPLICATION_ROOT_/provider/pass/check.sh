#!/bin/sh
cd $HOME/.password-store
find $HOME/.password-store -type f ! -path '*/.git/*' -name '*.gpg' |
  sort -u |
  sed -e "s/^.*\/.password-store\///" -e 's/\.gpg$//' |
  xargs -L1 -P$conf_secrets_check_parallelization_count _secrets_check
