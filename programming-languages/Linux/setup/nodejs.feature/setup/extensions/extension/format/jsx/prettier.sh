#!/bin/sh
if which npx >/dev/null 2>&1; then
  npx prettier --write . "**/*.jsx"
else
  npm prettier --write . "**/*.jsx"
fi
