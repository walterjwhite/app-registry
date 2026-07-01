#!/bin/sh
if command -v npx >/dev/null 2>&1; then
  npx prettier --write . "**/*.jsx"
else
  npm prettier --write . "**/*.jsx"
fi
