#!/bin/sh
_SHELL_IS_RUNNABLE() {
  _SHELL_FIND -print -quit | grep -cqm1 '.'
}
_SHELL_FIND() {
  find . -type f -and \( -name "*.sh" -or -path '*/bin/*' \) \
    ! -path '*/*.archived/*' \
    ! -path '*/*.secret/*' \
    ! -path '*/node_modules/*' \
    ! -path '*/target/*' \
    ! -path '*/.idea/*' \
    ! -path '*/.git/*' "$@"
}
