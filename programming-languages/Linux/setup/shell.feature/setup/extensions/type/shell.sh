#!/bin/sh
shell_is_runnable() {
  shell_find -print -quit | grep -cqm1 '.'
}
shell_find() {
  find . -type f -and \( -name "*.sh" -or -path '*/bin/*' \) \
    ! -path '*/*.archived/*' \
    ! -path '*/*.secret/*' \
    ! -path '*/node_modules/*' \
    ! -path '*/target/*' \
    ! -path '*/.idea/*' \
    ! -path '*/.git/*' "$@"
}
