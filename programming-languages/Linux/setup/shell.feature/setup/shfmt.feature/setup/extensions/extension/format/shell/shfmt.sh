#!/bin/sh
: ${conf_dev_shfmt_options:="-i 2"}
shell_find -exec shfmt $conf_dev_shfmt_options -w {} +
