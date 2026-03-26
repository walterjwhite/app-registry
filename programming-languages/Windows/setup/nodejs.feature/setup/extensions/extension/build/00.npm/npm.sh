#!/bin/sh
_npm_build_all() {
  for NPM_MODULE in "$@"; do
    cd $NPM_MODULE
    npm install --silent
    npm update --silent
    ncu | grep -cqm1 'Run ncu -u to upgrade package.json' && {
      log_warn 'updates detected for npm'
      if [ -z "$_NO_NODEJS_AUTOUPDATE" ]; then
        log_warn "automatically updating npm, to disable pass -no-nodejs-autoupdate or set _NO_NODEJS_AUTOUPDATE"
        ncu -u
        npm install --silent
      else
        log_warn "auto updates are disabled"
      fi
    }
    npm run build --silent
    cd $ORIGINAL_PWD
  done
}
readonly ORIGINAL_PWD=$PWD
_npm_build_all $(extension_find_dirs_containing)
