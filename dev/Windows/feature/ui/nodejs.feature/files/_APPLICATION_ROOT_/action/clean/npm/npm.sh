#!/bin/sh
_APPLICATION_NAME=dev
if [ "$#" -gt 0 ]; then
	paths="$@"
else
	paths="."
fi
find $paths \( -type f -or -type d -name \) -and \( 'package-lock.json' -or -name 'node_modules' \) -exec rm -rf {} \;
_NO_EXEC=1
