#!/bin/sh
: ${_optn_dev_shfmt_options:="-i 2"}
shell_find -exec shfmt $_optn_dev_shfmt_options -w {} +
