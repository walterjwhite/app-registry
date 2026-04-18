#!/bin/sh
[ -n "$force" ] && export force=1
_extension_find_default -exec build-tex {} \;
