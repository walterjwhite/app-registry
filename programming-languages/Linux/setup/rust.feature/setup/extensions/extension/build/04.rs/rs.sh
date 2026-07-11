#!/bin/sh
if [ "$#" -eq "0" ]; then
  _extension_find_default -exec rustc {} \;
else
  for _RUST_SOURCE_FILE in "$@"; do
    rustc $_RUST_SOURCE_FILE
  done
fi
