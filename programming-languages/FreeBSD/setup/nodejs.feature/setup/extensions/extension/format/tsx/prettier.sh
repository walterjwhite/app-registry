#!/bin/sh
if command -v npx >/dev/null 2>&1; then
  npx prettier --write . "**/*.tsx"
else
  npm prettier --write . "**/*.tsx"
fi
