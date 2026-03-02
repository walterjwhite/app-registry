#!/bin/sh
_extension_find_default -exec $GNU_SED -i "/log.*.$conf_dev_incorrect_logger_level_remove/Id" {} +
