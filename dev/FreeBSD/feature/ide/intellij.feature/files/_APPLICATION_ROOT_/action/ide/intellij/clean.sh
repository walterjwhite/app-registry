#!/bin/sh
_APPLICATION_NAME=dev
find . -mindepth 1 -maxdepth 1 -type d -name '.idea' -exec rm -rf {} +
find . -type f -name '*.iml' -exec rm -f {} +
