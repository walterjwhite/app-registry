#!/bin/sh
: ${_OPTN_DEV_SHFMT_OPTIONS:="-i 2"}
shell_find -exec shfmt $_OPTN_DEV_SHFMT_OPTIONS -w {} +
