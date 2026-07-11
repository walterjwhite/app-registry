#!/bin/sh
if command -v npx >/dev/null 2>&1; then
  npx prettier --write . "**/*.js"
else
  npm prettier --write . "**/*.js"
fi
