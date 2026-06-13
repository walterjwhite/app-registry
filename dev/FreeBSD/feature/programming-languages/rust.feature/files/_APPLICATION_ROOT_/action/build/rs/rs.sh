#!/bin/sh
_APPLICATION_NAME=dev
_NO_EXEC=1
if [ "$#" -eq "0" ]; then
	find . -type f -name '*.rs' -exec rustc {} \;
else
	for _RUST_SOURCE_FILE in "$@"; do
		rustc $_RUST_SOURCE_FILE
	done
fi
