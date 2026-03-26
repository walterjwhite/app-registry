#!/bin/sh
_npm_clean_all() {
  for NPM_MODULE in "$@"; do
    rm -rf $NPM_MODULE/node_modules $NPM_MODULE/package-lock.json
  done
}
_npm_clean_all $(extension_find_dirs_containing)
