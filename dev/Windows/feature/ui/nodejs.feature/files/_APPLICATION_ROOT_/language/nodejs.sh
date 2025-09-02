#!/bin/sh
set -a
_APPLICATION_NAME=dev
_nodejs_find() {
  shift
  find . -type d -name node_modules \
    ! -path '*/target/*' \
    ! -path '*/.idea/*' \
    ! -path '*/.git/*' $@
}
