#!/bin/sh
: ${conf_dev_format_parallel:=10}
shell_find | xargs -P$conf_dev_format_parallel -I % sh-app-fmt %
