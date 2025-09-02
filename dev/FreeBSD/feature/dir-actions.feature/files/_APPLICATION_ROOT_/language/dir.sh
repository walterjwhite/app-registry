#!/bin/sh
set -a
_APPLICATION_NAME=dev
_dir_find() {
  shift
  find . -mindepth 0 -maxdepth 0 -type d "$@"
}
