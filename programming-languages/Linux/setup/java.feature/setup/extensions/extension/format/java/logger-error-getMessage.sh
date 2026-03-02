#!/bin/sh
_extension_find_default -exec $GNU_SED -i '/log.*.error.*getMessage()/Id' {} +
