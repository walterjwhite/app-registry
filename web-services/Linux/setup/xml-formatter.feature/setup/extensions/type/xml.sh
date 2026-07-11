#!/bin/sh
xml_is_runnable() {
  xml_find -print -quit | grep -cqm1 '.'
}
xml_find() {
  find . -type f -and \( -name '*.xml' -or -name '*.html' -or -name '*.xhtml' -or -name '*.atom' -or -name '*.xhtml' -or -name '*.rss' -or -name '*.svg' \) \
    ! -path '*/*.archived/*' \
    ! -path '*/*.secret/*' \
    ! -path '*/node_modules/*' \
    ! -path '*/target/*' \
    ! -path '*/.idea/*' \
    ! -path '*/.git/*' "$@"
}
