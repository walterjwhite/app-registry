#!/bin/sh
kotlin_is_runnable() {
  kotlin_find -print -quit | grep -cqm1 '.'
}
kotlin_find() {
  find . -type f -and \( -name "*.kt" \) \
    ! -path '*/*.archived/*' \
    ! -path '*/*.secret/*' \
    ! -path '*/node_modules/*' \
    ! -path '*/target/*' \
    ! -path '*/.idea/*' \
    ! -path '*/.git/*' "$@"
}
