#!/bin/sh
if which npx >/dev/null 2>&1; then
  npx prettier --write . "**/*.ts"
else
  npm prettier --write . "**/*.ts"
fi
